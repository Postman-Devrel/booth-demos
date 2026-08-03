#!/usr/bin/env node
'use strict';

/**
 * offline-docs-mcp
 *
 * A real, dependency-free MCP server (JSON-RPC 2.0 over stdio) that serves a
 * *cached snapshot* of documentation. It exists so a live demo survives bad
 * conference wifi: the handshake and the tool call are genuine, only the corpus
 * is local. Every response is explicitly labelled as an offline snapshot.
 *
 * Protocol rules that must never be broken:
 *   - stdout carries newline-delimited JSON-RPC messages and NOTHING else.
 *   - all human-readable logging goes to stderr.
 *   - notifications (messages without an `id`) are never replied to.
 *
 * Corpus: ../fixtures/corpus/elevenlabs/*.md, resolved relative to THIS file
 * (not the cwd — the server is launched by an MCP client from anywhere).
 * Each corpus file's first line is expected to be:
 *   <!-- source: https://... -->
 */

const fs = require('node:fs');
const path = require('node:path');

const SERVER_NAME = 'offline-docs-mcp';
const SERVER_VERSION = '1.0.0';
const DEFAULT_PROTOCOL_VERSION = '2025-06-18';

const CORPUS_DIR = path.resolve(__dirname, '..', 'fixtures', 'corpus', 'elevenlabs');
const REFRESH_HINT = './scripts/refresh-fixtures.sh';
const SNAPSHOT_BANNER = '[offline snapshot — cached corpus, not live docs]';

// set OFFLINE_DOCS_DEBUG=1 to see per-document scores on stderr (never stdout)
const DEBUG = process.env.OFFLINE_DOCS_DEBUG === '1';

const MAX_RESULTS = 3;
const WINDOW_CHARS = 800;
const HARD_LINE_CAP = 1600; // a single monster line (huge table row) still gets capped

// ---------------------------------------------------------------------------
// logging (stderr only — a stray stdout write corrupts the protocol)
// ---------------------------------------------------------------------------

function log(...args) {
  try {
    process.stderr.write(`[${SERVER_NAME}] ${args.join(' ')}\n`);
  } catch (_) {
    /* never let logging kill the server */
  }
}

// ---------------------------------------------------------------------------
// corpus loading
// ---------------------------------------------------------------------------

const SOURCE_COMMENT_RE = /^<!--\s*source:\s*(\S+)\s*-->\s*$/i;
const HEADING_RE = /^#{1,6}\s+/;
const TITLE_RE = /^#\s+(.+?)\s*$/;

/** @type {{docs: Array<object>, signature: string}|null} */
let corpusCache = null;

/**
 * Cheap fingerprint of the corpus directory so a refresh that happens *after*
 * the server started (e.g. the presenter runs refresh-fixtures.sh mid-demo) is
 * picked up without a restart.
 */
function corpusSignature() {
  try {
    const entries = fs
      .readdirSync(CORPUS_DIR, { withFileTypes: true })
      .filter((e) => e.isFile() && e.name.toLowerCase().endsWith('.md'))
      .map((e) => e.name)
      .sort();
    const parts = entries.map((name) => {
      try {
        const st = fs.statSync(path.join(CORPUS_DIR, name));
        return `${name}:${st.size}:${st.mtimeMs}`;
      } catch (_) {
        return `${name}:?`;
      }
    });
    return parts.join('|');
  } catch (_) {
    return '<missing>';
  }
}

function parseDoc(filename, raw) {
  const text = raw.replace(/\r\n/g, '\n');
  const lines = text.split('\n');

  let url = null;
  let bodyLines = lines;
  const first = lines[0] !== undefined ? lines[0].trim() : '';
  const m = SOURCE_COMMENT_RE.exec(first);
  if (m) {
    url = m[1];
    bodyLines = lines.slice(1);
  } else {
    url = filename; // documented fallback: no source comment => use the filename
  }

  // drop leading blank lines left behind by the source comment
  while (bodyLines.length && bodyLines[0].trim() === '') bodyLines.shift();

  let title = null;
  for (const line of bodyLines) {
    const t = TITLE_RE.exec(line);
    if (t) {
      title = t[1].trim();
      break;
    }
  }
  if (!title) title = filename;

  return {
    filename,
    url,
    title,
    lines: bodyLines,
    lowerLines: bodyLines.map((l) => l.toLowerCase()),
    isHeading: bodyLines.map((l) => HEADING_RE.test(l)),
    lowerTitle: title.toLowerCase(),
  };
}

function loadCorpus() {
  const signature = corpusSignature();
  if (corpusCache && corpusCache.signature === signature) return corpusCache.docs;

  const docs = [];
  let names = [];
  try {
    names = fs
      .readdirSync(CORPUS_DIR, { withFileTypes: true })
      .filter((e) => e.isFile() && e.name.toLowerCase().endsWith('.md'))
      .map((e) => e.name)
      .sort();
  } catch (err) {
    log(`corpus directory unavailable (${CORPUS_DIR}): ${err && err.message}`);
    corpusCache = { docs: [], signature };
    return corpusCache.docs;
  }

  for (const name of names) {
    try {
      const raw = fs.readFileSync(path.join(CORPUS_DIR, name), 'utf8');
      docs.push(parseDoc(name, raw));
    } catch (err) {
      log(`skipping ${name}: ${err && err.message}`);
    }
  }

  corpusCache = { docs, signature };
  log(`corpus loaded: ${docs.length} page(s) from ${CORPUS_DIR}`);
  return docs;
}

// ---------------------------------------------------------------------------
// search
// ---------------------------------------------------------------------------

const STOPWORDS = new Set([
  'the', 'and', 'for', 'are', 'but', 'not', 'you', 'your', 'yours', 'with', 'was', 'were',
  'this', 'that', 'these', 'those', 'from', 'have', 'has', 'had', 'how', 'what', 'when',
  'where', 'which', 'who', 'whom', 'why', 'can', 'will', 'would', 'should', 'could', 'does',
  'did', 'doing', 'done', 'its', 'it', 'they', 'them', 'their', 'there', 'then', 'than',
  'about', 'into', 'onto', 'over', 'under', 'out', 'off', 'all', 'any', 'each', 'more',
  'most', 'some', 'such', 'only', 'own', 'same', 'too', 'very', 'just', 'also', 'get',
  'got', 'use', 'used', 'using', 'via', 'per', 'our', 'ours', 'his', 'her', 'hers', 'him',
  'she', 'let', 'may', 'might', 'must', 'need', 'want', 'like', 'been', 'being', 'both',
  'here', 'were', 'while', 'because', 'between', 'during', 'after', 'before', 'above',
  'below', 'again', 'once', 'other', 'few', 'nor', 'yet', 'lot', 'lots', 'know', 'tell',
  'show', 'give', 'make', 'made', 'does', 'doc', 'docs', 'documentation',
]);

function escapeRegExp(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/**
 * Very light stemming so a plural query term still matches singular prose
 * ("websockets" -> "websocket", "policies" -> "polic"). Matching is done as a
 * word-prefix, so stemming only needs to shorten, never to normalise fully.
 */
function stem(term) {
  if (term.length > 4 && term.endsWith('ies')) return term.slice(0, -3);
  if (term.length > 4 && term.endsWith('es') && !term.endsWith('ses')) return term.slice(0, -2);
  if (term.length > 3 && term.endsWith('s') && !term.endsWith('ss')) return term.slice(0, -1);
  return term;
}

/**
 * Build the query model: individual terms plus adjacent-word phrases.
 *
 * Phrases matter more than they look. A bag of words cannot tell
 * "text to speech" from "speech to text" — both tokenize to {text, speech}.
 * Pairing adjacent content words (allowing one filler word between them) and
 * matching them as `text[-\s]to[-\s]speech` restores that ordering signal.
 */
function buildQuery(query) {
  const raw = String(query || '')
    .toLowerCase()
    .match(/[a-z0-9][a-z0-9_-]*/g) || [];
  const words = raw.map((t) => t.replace(/^[-_]+|[-_]+$/g, ''));

  const seen = new Set();
  const terms = [];
  const contentIdx = [];

  words.forEach((word, i) => {
    if (word.length < 3 || STOPWORDS.has(word)) return;
    contentIdx.push(i);
    const term = stem(word);
    if (seen.has(term)) return;
    seen.add(term);
    terms.push(term);
  });

  const phrases = [];
  const seenPhrase = new Set();
  for (let k = 0; k + 1 < contentIdx.length; k++) {
    const i = contentIdx[k];
    const j = contentIdx[k + 1];
    if (j - i > 2) continue; // allow at most one filler word between the pair
    const a = stem(words[i]);
    const b = stem(words[j]);
    const key = `${a}~${b}`;
    if (seenPhrase.has(key)) continue;
    seenPhrase.add(key);
    // separator: punctuation/space, optionally spanning one short filler word,
    // so "text to speech" also matches "text-to-speech" and "text speech".
    const sep = '[^a-z0-9]{1,3}(?:[a-z]{1,4}[^a-z0-9]{1,3})?';
    phrases.push(
      new RegExp('\\b' + escapeRegExp(a) + '[a-z0-9]*' + sep + escapeRegExp(b), 'g')
    );
  }

  return { terms, phrases };
}

function countMatches(haystack, re) {
  re.lastIndex = 0;
  let n = 0;
  let m;
  while ((m = re.exec(haystack)) !== null) {
    n++;
    if (m.index === re.lastIndex) re.lastIndex++; // paranoia against zero-length loops
  }
  return n;
}

/**
 * Score a document against the query.
 * - term frequency in the body (log-damped, so repetition alone can't win)
 * - strong bonus when a term appears in a markdown heading
 * - coverage bonus: matching several distinct terms beats hammering one
 * - phrase bonus: adjacent query words found adjacent in the doc
 */
function scoreDoc(doc, terms, phrases) {
  const perLineHits = new Array(doc.lines.length).fill(0);
  let score = 0;
  let distinct = 0;

  for (const term of terms) {
    const re = new RegExp('\\b' + escapeRegExp(term), 'g');
    let bodyHits = 0;
    let headingHits = 0;

    for (let i = 0; i < doc.lowerLines.length; i++) {
      const hits = countMatches(doc.lowerLines[i], re);
      if (!hits) continue;
      bodyHits += hits;
      if (doc.isHeading[i]) {
        headingHits += hits;
        perLineHits[i] += hits * 4; // headings anchor the passage window too
      } else {
        perLineHits[i] += hits;
      }
    }

    const titleHits = countMatches(doc.lowerTitle, re);

    if (bodyHits > 0 || titleHits > 0) distinct++;
    score += 3 * Math.log(1 + bodyHits);
    score += 8 * headingHits;
    // the page title is the single strongest relevance signal in docs search
    score += 25 * titleHits;
  }

  if (distinct === 0) return null;
  // coverage beats repetition
  score *= 1 + 0.75 * (distinct - 1);

  // Phrase bonus: restores the word-order signal a bag of words throws away,
  // which is what separates "text to speech" from "speech to text".
  let distinctPhrases = 0;
  for (const re of phrases) {
    let bodyHits = 0;
    let headingHits = 0;

    for (let i = 0; i < doc.lowerLines.length; i++) {
      const hits = countMatches(doc.lowerLines[i], re);
      if (!hits) continue;
      bodyHits += hits;
      if (doc.isHeading[i]) {
        headingHits += hits;
        perLineHits[i] += hits * 6;
      } else {
        perLineHits[i] += hits * 3;
      }
    }

    const titleHits = countMatches(doc.lowerTitle, re);
    if (bodyHits > 0 || titleHits > 0) distinctPhrases++;

    score += 12 * Math.log(1 + bodyHits);
    score += 15 * headingHits;
    score += 40 * titleHits;
  }

  return { score, distinct, distinctPhrases, perLineHits };
}

/**
 * Pick the densest ~WINDOW_CHARS window of lines, snapped outward to line
 * boundaries so tables and list rows are never sliced mid-row.
 */
function bestPassage(doc, perLineHits) {
  const lines = doc.lines;
  if (lines.length === 0) return '';

  const lineCost = lines.map((l) => l.length + 1);

  let best = { sum: -1, start: 0, end: 0 };
  let start = 0;
  let chars = 0;
  let sum = 0;

  for (let end = 0; end < lines.length; end++) {
    chars += lineCost[end];
    sum += perLineHits[end];
    while (start < end && chars > WINDOW_CHARS) {
      chars -= lineCost[start];
      sum -= perLineHits[start];
      start++;
    }
    if (sum > best.sum) best = { sum, start, end };
  }

  let { start: s, end: e } = best;
  if (best.sum <= 0) {
    // no in-body hits (title-only match): fall back to the opening of the page
    s = 0;
    e = 0;
    let c = 0;
    while (e < lines.length - 1 && c + lineCost[e + 1] <= WINDOW_CHARS) {
      c += lineCost[e];
      e++;
    }
  }

  // trim blank padding at the edges
  while (s < e && lines[s].trim() === '') s++;
  while (e > s && lines[e].trim() === '') e--;

  let passage = lines.slice(s, e + 1).join('\n');
  if (passage.length > HARD_LINE_CAP) passage = passage.slice(0, HARD_LINE_CAP) + '…';
  return passage.trim();
}

function searchDocs(query) {
  const docs = loadCorpus();

  if (docs.length === 0) {
    return (
      `${SNAPSHOT_BANNER}\n\n` +
      `The cached documentation corpus is empty (expected markdown files in ${CORPUS_DIR}).\n` +
      `Run \`${REFRESH_HINT}\` to populate it, then retry this search.`
    );
  }

  const { terms, phrases } = buildQuery(query);
  if (terms.length === 0) {
    return (
      `${SNAPSHOT_BANNER}\n\n` +
      `No searchable terms in the query (terms shorter than 3 characters and common ` +
      `stopwords are ignored). Try a more specific query.\n\n` +
      availableTitles(docs)
    );
  }

  const scored = [];
  for (const doc of docs) {
    const result = scoreDoc(doc, terms, phrases);
    if (result) scored.push({ doc, ...result });
  }

  if (scored.length === 0) {
    return (
      `${SNAPSHOT_BANNER}\n\n` +
      `No cached page matched: ${terms.join(', ')}.\n` +
      `This snapshot may simply not cover that topic.\n\n` +
      availableTitles(docs)
    );
  }

  scored.sort((a, b) => b.score - a.score || a.doc.filename.localeCompare(b.doc.filename));

  if (DEBUG) {
    log(`terms=[${terms.join(',')}] phrases=${phrases.length}`);
    for (const s of scored.slice(0, 6)) {
      log(
        `  ${s.score.toFixed(1)}  ${s.doc.title} ` +
          `(terms=${s.distinct}, phrases=${s.distinctPhrases}, lines=${s.doc.lines.length})`
      );
    }
  }

  const blocks = scored.slice(0, MAX_RESULTS).map(({ doc, perLineHits }) => {
    const passage = bestPassage(doc, perLineHits);
    return `## ${doc.title}\nSource: ${doc.url}\n\n${passage}`;
  });

  return `${SNAPSHOT_BANNER}\n\n` + blocks.join('\n\n---\n\n');
}

function availableTitles(docs) {
  const sample = docs.slice(0, 8).map((d) => `- ${d.title} (${d.url})`);
  const more = docs.length > sample.length ? `\n…and ${docs.length - sample.length} more page(s).` : '';
  return `Pages available in this snapshot:\n${sample.join('\n')}${more}`;
}

// ---------------------------------------------------------------------------
// JSON-RPC plumbing
// ---------------------------------------------------------------------------

function send(message) {
  try {
    process.stdout.write(JSON.stringify(message) + '\n');
  } catch (err) {
    log(`failed to write response: ${err && err.message}`);
  }
}

function sendResult(id, result) {
  send({ jsonrpc: '2.0', id, result });
}

function sendError(id, code, message, data) {
  const error = { code, message };
  if (data !== undefined) error.data = data;
  send({ jsonrpc: '2.0', id, error });
}

const TOOLS = [
  {
    name: 'searchDocs',
    description: 'Search the cached documentation corpus. Returns relevant passages with source URLs.',
    inputSchema: {
      type: 'object',
      properties: {
        query: {
          type: 'string',
          description: 'Natural-language or keyword search query.',
        },
      },
      required: ['query'],
      additionalProperties: false,
    },
  },
];

function handleMessage(msg) {
  const isRequest = Object.prototype.hasOwnProperty.call(msg, 'id') && msg.id !== null;
  const id = isRequest ? msg.id : null;
  const method = msg.method;

  if (typeof method !== 'string') {
    if (isRequest) sendError(id, -32600, 'Invalid Request: missing method');
    return;
  }

  switch (method) {
    case 'initialize': {
      if (!isRequest) return;
      const requested =
        msg.params && typeof msg.params.protocolVersion === 'string'
          ? msg.params.protocolVersion
          : DEFAULT_PROTOCOL_VERSION;
      const clientName =
        msg.params && msg.params.clientInfo && msg.params.clientInfo.name
          ? msg.params.clientInfo.name
          : 'unknown-client';
      log(`initialize from ${clientName} (protocolVersion=${requested})`);
      sendResult(id, {
        protocolVersion: requested,
        capabilities: { tools: {} },
        serverInfo: { name: SERVER_NAME, version: SERVER_VERSION },
      });
      return;
    }

    case 'notifications/initialized':
    case 'initialized':
      // notification: acknowledge only on stderr, never on stdout
      log('client initialized');
      return;

    case 'ping': {
      if (!isRequest) return;
      sendResult(id, {});
      return;
    }

    case 'tools/list': {
      if (!isRequest) return;
      sendResult(id, { tools: TOOLS });
      return;
    }

    case 'tools/call': {
      if (!isRequest) return;
      const params = msg.params || {};
      const name = params.name;
      const args = params.arguments || {};

      if (name !== 'searchDocs') {
        sendError(id, -32602, `Unknown tool: ${String(name)}`);
        return;
      }

      const query = typeof args.query === 'string' ? args.query : '';
      log(`searchDocs query=${JSON.stringify(query)}`);
      const text = searchDocs(query);
      sendResult(id, { content: [{ type: 'text', text }] });
      return;
    }

    default: {
      if (!isRequest) {
        log(`ignoring unknown notification: ${method}`);
        return;
      }
      sendError(id, -32601, `Method not found: ${method}`);
    }
  }
}

function handleLine(line) {
  const trimmed = line.trim();
  if (!trimmed) return;

  let msg;
  try {
    msg = JSON.parse(trimmed);
  } catch (err) {
    log(`parse error: ${err && err.message}`);
    sendError(null, -32700, 'Parse error');
    return;
  }

  if (msg === null || typeof msg !== 'object' || Array.isArray(msg)) {
    log('ignoring non-object JSON-RPC payload');
    return;
  }

  const hasId = Object.prototype.hasOwnProperty.call(msg, 'id') && msg.id !== null;
  try {
    handleMessage(msg);
  } catch (err) {
    log(`internal error handling ${msg.method}: ${(err && err.stack) || err}`);
    if (hasId) sendError(msg.id, -32603, 'Internal error', String((err && err.message) || err));
  }
}

// ---------------------------------------------------------------------------
// stdio transport: buffer until newline so chunked stdin is handled correctly
// ---------------------------------------------------------------------------

function main() {
  process.stdin.setEncoding('utf8');

  let buffer = '';
  process.stdin.on('data', (chunk) => {
    buffer += chunk;
    let index;
    while ((index = buffer.indexOf('\n')) !== -1) {
      const line = buffer.slice(0, index);
      buffer = buffer.slice(index + 1);
      handleLine(line);
    }
  });

  process.stdin.on('end', () => {
    if (buffer.trim()) handleLine(buffer); // tolerate a final line without a newline
    buffer = '';
    log('stdin closed, exiting');
    process.exit(0);
  });

  process.stdin.on('error', (err) => {
    log(`stdin error: ${err && err.message}`);
    process.exit(0);
  });

  process.stdout.on('error', (err) => {
    // EPIPE when the client goes away; nothing useful left to do
    log(`stdout error: ${err && err.message}`);
    process.exit(0);
  });

  process.on('uncaughtException', (err) => {
    log(`uncaught exception: ${(err && err.stack) || err}`);
  });

  const docs = loadCorpus();
  if (docs.length === 0) {
    log(`no cached pages found — run ${REFRESH_HINT} to populate ${CORPUS_DIR}`);
  }
  log('ready (stdio, JSON-RPC 2.0)');
}

main();
