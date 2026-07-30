#!/usr/bin/env node
// Installs the Postman oracle for the Meteo loop demo — replaces the old
// oracle-setup agent. Idempotent: finds or creates a dedicated workspace, a
// "Hourly forecast" collection whose request URL is {{forecast_url}} with the
// human-authored test attached, and an "open-meteo-loop-eng" environment.
// Writes the resulting IDs to app/postman/oracle.ids.json and prints them.
//
// Usage: node postman-setup.mjs <APP_DIR>
// Requires: POSTMAN_API_KEY in the environment, Node 18+ (built-in fetch).

import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const API = "https://api.getpostman.com";
const KEY = process.env.POSTMAN_API_KEY;
const APP_DIR = process.argv[2];

const WORKSPACE_NAME = "open-meteo-loop-eng";
const COLLECTION_NAME = "Hourly forecast";
const ENVIRONMENT_NAME = "open-meteo-loop-eng";

if (!KEY) {
  console.error("[FAIL] POSTMAN_API_KEY is not set.");
  process.exit(1);
}
if (!APP_DIR) {
  console.error("[FAIL] Missing APP_DIR argument.");
  process.exit(1);
}

async function api(method, path, body) {
  const res = await fetch(`${API}${path}`, {
    method,
    headers: { "X-Api-Key": KEY, "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json;
  try { json = text ? JSON.parse(text) : {}; } catch { json = { raw: text }; }
  if (!res.ok) {
    throw new Error(`${method} ${path} → ${res.status}: ${text.slice(0, 300)}`);
  }
  return json;
}

// 1. Find or create the workspace.
let workspaceId;
let workspaceCreated = false;
const { workspaces = [] } = await api("GET", "/workspaces");
const existingWs = workspaces.find((w) => w.name === WORKSPACE_NAME);
if (existingWs) {
  workspaceId = existingWs.id;
  console.log(`[OK] Reusing workspace "${WORKSPACE_NAME}" (${workspaceId})`);
} else {
  const created = await api("POST", "/workspaces", {
    workspace: {
      name: WORKSPACE_NAME,
      type: "personal",
      description: "Meteo API loop-engineering booth demo. Safe to delete.",
    },
  });
  workspaceId = created.workspace.id;
  workspaceCreated = true;
  console.log(`[OK] Created workspace "${WORKSPACE_NAME}" (${workspaceId})`);
}

// 2. Build the collection body from the human-authored test (verbatim, one line per exec entry).
const testPath = join(APP_DIR, "postman", "hourly-forecast.test.js");
const testExec = readFileSync(testPath, "utf8").replace(/\n$/, "").split("\n");
const collectionBody = {
  collection: {
    info: {
      name: COLLECTION_NAME,
      schema: "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
    },
    item: [
      {
        name: "Forecast",
        event: [
          { listen: "test", script: { type: "text/javascript", exec: testExec } },
        ],
        request: { method: "GET", url: "{{forecast_url}}" },
      },
    ],
  },
};

// 3. Find or create the collection, refreshing the test in place if it exists.
let collectionUid;
const { collections = [] } = await api("GET", `/collections?workspace=${workspaceId}`);
const existingCol = collections.find((c) => c.name === COLLECTION_NAME);
if (existingCol) {
  const updated = await api("PUT", `/collections/${existingCol.uid}`, collectionBody);
  collectionUid = updated.collection.uid;
  console.log(`[OK] Refreshed collection "${COLLECTION_NAME}" in place (${collectionUid})`);
} else {
  const created = await api("POST", `/collections?workspace=${workspaceId}`, collectionBody);
  collectionUid = created.collection.uid;
  console.log(`[OK] Created collection "${COLLECTION_NAME}" (${collectionUid})`);
}

// 4. Find or create the environment holding forecast_url.
let environmentUid;
const { environments = [] } = await api("GET", `/environments?workspace=${workspaceId}`);
const existingEnv = environments.find((e) => e.name === ENVIRONMENT_NAME);
if (existingEnv) {
  environmentUid = existingEnv.uid;
  console.log(`[OK] Reusing environment "${ENVIRONMENT_NAME}" (${environmentUid})`);
} else {
  const created = await api("POST", `/environments?workspace=${workspaceId}`, {
    environment: {
      name: ENVIRONMENT_NAME,
      values: [
        {
          key: "forecast_url",
          value: "https://api.open-meteo.com/v1/forecast",
          type: "default",
          enabled: true,
        },
      ],
    },
  });
  environmentUid = created.environment.uid;
  console.log(`[OK] Created environment "${ENVIRONMENT_NAME}" (${environmentUid})`);
}

// 5. Persist the IDs for the loop and for teardown.
const workspaceUrl = `https://go.postman.co/workspace/${workspaceId}`;
const ids = { workspaceId, workspaceCreated, collectionUid, environmentUid, workspaceUrl };
const idsPath = join(APP_DIR, "postman", "oracle.ids.json");
writeFileSync(idsPath, JSON.stringify(ids, null, 2) + "\n");
console.log(`[OK] Wrote ${idsPath}`);

// 6. Print the workspace URL and the ready-to-paste loop prompt with the IDs filled in.
console.log("");
console.log("=== Oracle installed ===");
console.log(`  workspace URL  = ${workspaceUrl}`);
console.log(`     (a Personal-visibility workspace — open via this URL; it won't`);
console.log(`      appear in the shared team workspace list)`);
console.log(`  collectionUid  = ${collectionUid}`);
console.log(`  environmentUid = ${environmentUid}`);
console.log("");
console.log("Ready-to-paste loop prompt (in Claude Code, inside ./app):");
console.log("-----------------------------------------------------------");
console.log(`Build getParisHourlyTemps() in src/weather-client.js: fetch the hourly
temperature forecast for Paris (lat 48.85, lon 2.35) from
https://api.open-meteo.com/v1/forecast and return the array of temperatures.

Rules:
- The ONLY way you may check your work is by delegating to @agent-oracle-check.
  Do NOT call any Postman tool yourself and do NOT read postman/ or the test.
  You do not know what the oracle checks beyond its failure messages.
- Loop, up to 3 attempts: (1) write the whole client; (2) call @agent-oracle-check
  with the exact URL your client fetches, collectionUid ${collectionUid}, and
  environmentUid ${environmentUid}; (3) if it reports failures, use the messages
  to fix the client, then go to step 1.
- Stop when oracle-check reports zero failed assertions.`);
console.log("-----------------------------------------------------------");
