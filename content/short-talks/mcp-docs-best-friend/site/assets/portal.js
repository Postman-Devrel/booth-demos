/* MyHealthcare API Portal — v1
 *
 * Single-page application. Everything a reader sees — the overview, the
 * platform notes, every endpoint, every schema — is constructed here at
 * runtime and injected into #root. The served HTML document contains an empty
 * div.
 *
 * The "Try it" panel is fully offline: requests are never sent. Responses are
 * synthesised from the spec's own examples and schemas, so the portal behaves
 * identically on booth wifi and on no wifi at all.
 */
(function () {
  "use strict";

  var DATA = window.__PORTAL_DATA__ || [];
  var METHODS = ["get", "post", "put", "patch", "delete"];
  var ORDER = { get: 0, post: 1, patch: 2, put: 3, delete: 4 };

  /* ------------------------------------------------------------- helpers */

  function esc(s) {
    return String(s == null ? "" : s)
      .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function slug(s) {
    return String(s).toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
  }

  /* Resolve a local $ref against its own document. All refs in these specs are
     `#/components/...`, so a simple pointer walk is enough. */
  function deref(spec, node, seen) {
    seen = seen || 0;
    while (node && node.$ref && seen < 20) {
      var parts = node.$ref.replace(/^#\//, "").split("/");
      var cur = spec;
      for (var i = 0; i < parts.length && cur; i++) {
        cur = cur[parts[i].replace(/~1/g, "/").replace(/~0/g, "~")];
      }
      node = cur;
      seen++;
    }
    return node || {};
  }

  /* Build a representative value for a schema — used to prefill request
     bodies and to synthesise "Try it" responses. */
  function sample(spec, schema, depth) {
    depth = depth || 0;
    schema = deref(spec, schema);
    if (!schema || depth > 6) return null;

    if (schema.example !== undefined) return schema.example;
    if (schema.examples && schema.examples.length) return schema.examples[0];
    if (schema.default !== undefined && schema.type !== "object") return schema.default;
    if (schema.enum && schema.enum.length) return schema.enum[0];

    var of = schema.allOf || schema.oneOf || schema.anyOf;
    if (of && of.length) {
      if (schema.allOf) {
        var merged = {};
        for (var a = 0; a < of.length; a++) {
          var part = sample(spec, of[a], depth + 1);
          if (part && typeof part === "object") {
            for (var pk in part) merged[pk] = part[pk];
          }
        }
        return merged;
      }
      return sample(spec, of[0], depth + 1);
    }

    var type = schema.type;
    if (Array.isArray(type)) type = type[0];
    if (!type && schema.properties) type = "object";

    if (type === "object") {
      var out = {};
      var props = schema.properties || {};
      for (var k in props) out[k] = sample(spec, props[k], depth + 1);
      return out;
    }
    if (type === "array") return [sample(spec, schema.items || {}, depth + 1)].filter(function (v) {
      return v !== null && v !== undefined;
    });
    if (type === "integer" || type === "number") return 0;
    if (type === "boolean") return true;
    if (type === "null") return null;

    if (schema.format === "date-time") return "2026-08-20T09:15:00Z";
    if (schema.format === "date") return "2026-08-20";
    return "string";
  }

  /* --------------------------------------------------------- mini markdown */
  /* The specs are written in Markdown. Render the subset they actually use:
     headings, paragraphs, lists, tables, blockquotes, fences, inline code,
     bold, italics and links. */

  function inline(s) {
    return esc(s)
      .replace(/`([^`]+)`/g, '<code class="inl">$1</code>')
      .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
      .replace(/(^|[\s(])\*([^*\n]+)\*/g, "$1<em>$2</em>")
      .replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, '<a href="$2" rel="noopener">$1</a>');
  }

  function md(src) {
    if (!src) return "";
    var lines = String(src).replace(/\r/g, "").split("\n");
    var out = [], para = [], list = null, i;

    function flushPara() {
      if (para.length) { out.push("<p>" + inline(para.join(" ")) + "</p>"); para = []; }
    }
    function flushList() {
      if (list) { out.push("<ul>" + list.join("") + "</ul>"); list = null; }
    }
    function flush() { flushPara(); flushList(); }

    for (i = 0; i < lines.length; i++) {
      var ln = lines[i];

      if (/^```/.test(ln)) {
        flush();
        var buf = [];
        for (i++; i < lines.length && !/^```/.test(lines[i]); i++) buf.push(lines[i]);
        out.push('<pre class="code">' + esc(buf.join("\n")) + "</pre>");
        continue;
      }

      /* Table: a header row followed by a |---|---| separator. */
      if (/^\s*\|/.test(ln) && i + 1 < lines.length && /^\s*\|[\s:|-]+\|\s*$/.test(lines[i + 1])) {
        flush();
        var cells = function (row) {
          return row.trim().replace(/^\||\|$/g, "").split("|").map(function (c) { return c.trim(); });
        };
        var head = cells(ln);
        var body = [];
        for (i += 2; i < lines.length && /^\s*\|/.test(lines[i]); i++) body.push(cells(lines[i]));
        i--;
        var th = head.map(function (c) { return "<th>" + inline(c) + "</th>"; }).join("");
        var tr = body.map(function (r) {
          return "<tr>" + r.map(function (c) { return "<td>" + inline(c) + "</td>"; }).join("") + "</tr>";
        }).join("");
        out.push('<table class="t"><thead><tr>' + th + "</tr></thead><tbody>" + tr + "</tbody></table>");
        continue;
      }

      if (/^\s*>/.test(ln)) {
        flush();
        var q = [];
        for (; i < lines.length && /^\s*>/.test(lines[i]); i++) q.push(lines[i].replace(/^\s*>\s?/, ""));
        i--;
        out.push("<blockquote>" + md(q.join("\n")) + "</blockquote>");
        continue;
      }

      var h = ln.match(/^(#{1,6})\s+(.*)$/);
      if (h) { flush(); var lv = Math.min(h[1].length + 2, 6); out.push("<h" + lv + ">" + inline(h[2]) + "</h" + lv + ">"); continue; }

      var li = ln.match(/^\s*[-*]\s+(.*)$/);
      if (li) { flushPara(); list = list || []; list.push("<li>" + inline(li[1]) + "</li>"); continue; }

      if (!ln.trim()) { flush(); continue; }
      flushList();
      para.push(ln.trim());
    }
    flush();
    return out.join("");
  }

  /* --------------------------------------------------------------- syntax */

  function hlJson(value) {
    var json = typeof value === "string" ? value : JSON.stringify(value, null, 2);
    return esc(json)
      .replace(/(&quot;(?:[^&]|&(?!quot;))*?&quot;)(\s*:)/g, '<span class="k">$1</span>$2')
      .replace(/:\s(&quot;(?:[^&]|&(?!quot;))*?&quot;)/g, ': <span class="s">$1</span>')
      .replace(/:\s(-?\d+\.?\d*)/g, ': <span class="n">$1</span>')
      .replace(/:\s(true|false|null)/g, ': <span class="b">$1</span>');
  }

  function hlShell(text) {
    return esc(text)
      .replace(/^(curl)/gm, '<span class="k">$1</span>')
      .replace(/(--?[a-zA-Z-]+)/g, '<span class="n">$1</span>')
      .replace(/(&#39;[^&]*?&#39;)/g, '<span class="s">$1</span>');
  }

  /* ---------------------------------------------------------------- model */
  /* Flatten the three specs into one list of services and operations. */

  function buildModel() {
    return DATA.map(function (entry) {
      var spec = entry.spec;
      var info = spec.info || {};
      var ops = [];

      Object.keys(spec.paths || {}).forEach(function (path) {
        var item = spec.paths[path];
        var shared = item.parameters || [];
        METHODS.forEach(function (method) {
          var op = item[method];
          if (!op) return;
          ops.push({
            id: op.operationId || slug(method + "-" + path),
            method: method,
            path: path,
            summary: op.summary || "",
            description: op.description || "",
            tag: (op.tags && op.tags[0]) || "Default",
            deprecated: !!op.deprecated,
            secured: op.security ? op.security.length > 0 : !!(spec.security || []).length,
            params: shared.concat(op.parameters || []).map(function (p) { return deref(spec, p); }),
            requestBody: op.requestBody ? deref(spec, op.requestBody) : null,
            responses: op.responses || {}
          });
        });
      });

      /* Group by tag, in the order the spec declares its tags. */
      var tagOrder = (spec.tags || []).map(function (t) { return t.name; });
      var groups = [];
      ops.forEach(function (op) {
        var g = groups.filter(function (x) { return x.name === op.tag; })[0];
        if (!g) { g = { name: op.tag, ops: [] }; groups.push(g); }
        g.ops.push(op);
      });
      groups.sort(function (a, b) {
        var ai = tagOrder.indexOf(a.name), bi = tagOrder.indexOf(b.name);
        return (ai < 0 ? 99 : ai) - (bi < 0 ? 99 : bi);
      });
      groups.forEach(function (g) {
        g.ops.sort(function (a, b) { return ORDER[a.method] - ORDER[b.method]; });
        var t = (spec.tags || []).filter(function (x) { return x.name === g.name; })[0];
        g.description = t ? t.description : "";
      });

      return {
        key: entry.key,
        spec: spec,
        title: info.title || entry.key,
        version: info.version || "",
        summary: info.summary || "",
        description: info.description || "",
        servers: spec.servers || [],
        groups: groups,
        ops: ops
      };
    });
  }

  var SERVICES = buildModel();

  function findOp(serviceKey, opId) {
    var svc = SERVICES.filter(function (s) { return s.key === serviceKey; })[0];
    if (!svc) return null;
    var op = svc.ops.filter(function (o) { return o.id === opId; })[0];
    return op ? { svc: svc, op: op } : null;
  }

  function baseUrl(svc) {
    var local = svc.servers.filter(function (s) { return /localhost/.test(s.url); })[0];
    return (local || svc.servers[0] || { url: "https://myhealthcare.dev" }).url;
  }

  /* ------------------------------------------------------------- rendering */

  function pill(method) {
    return '<span class="m-pill m-' + method + '">' + method.toUpperCase() + "</span>";
  }

  function pathHtml(path) {
    return esc(path).replace(/\{([^}]+)\}/g, '<span class="pv">{$1}</span>');
  }

  var CHEV = '<svg class="op-chev" width="12" height="12" viewBox="0 0 12 12" fill="none">' +
    '<path d="M4 2.5L7.5 6L4 9.5" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg>';

  var LOCK = '<svg class="op-lock" width="12" height="12" viewBox="0 0 12 12" fill="none">' +
    '<rect x="2.5" y="5.2" width="7" height="5.3" rx="1.2" stroke="currentColor" stroke-width="1.3"/>' +
    '<path d="M4.2 5.2V3.9a1.8 1.8 0 013.6 0v1.3" stroke="currentColor" stroke-width="1.3"/></svg>';

  function paramsTable(svc, params, where) {
    var rows = params.filter(function (p) { return p.in === where; });
    if (!rows.length) return "";
    var label = { path: "Path parameters", query: "Query parameters", header: "Header parameters" }[where];
    return "<h4>" + label + "</h4><table class=\"t\"><thead><tr><th>Name</th><th>Description</th></tr></thead><tbody>" +
      rows.map(function (p) {
        var sc = deref(svc.spec, p.schema || {});
        var type = sc.type || "string";
        if (sc.format) type += " · " + sc.format;
        if (sc.default !== undefined) type += " · default " + JSON.stringify(sc.default);
        return "<tr><td><code>" + esc(p.name) + "</code>" +
          (p.required ? '<span class="req">*</span>' : "") +
          '<span class="ptype">' + esc(type) + "</span></td><td>" +
          md(p.description || "") + "</td></tr>";
      }).join("") + "</tbody></table>";
  }

  function firstJson(content) {
    if (!content) return null;
    return content["application/json"] || content[Object.keys(content)[0]] || null;
  }

  /* The example a response should show: an explicit `example`, the first named
     `examples` entry, or a value synthesised from the schema. */
  function responseExample(svc, media) {
    if (!media) return null;
    if (media.example !== undefined) return media.example;
    if (media.examples) {
      var first = media.examples[Object.keys(media.examples)[0]];
      if (first && first.value !== undefined) return first.value;
    }
    if (media.schema) return sample(svc.spec, media.schema);
    return null;
  }

  function responsesBlock(svc, op) {
    var codes = Object.keys(op.responses);
    if (!codes.length) return "";
    var html = "<h4>Responses</h4>";
    html += '<table class="t"><thead><tr><th>Code</th><th>Description</th></tr></thead><tbody>';
    codes.forEach(function (code) {
      var r = deref(svc.spec, op.responses[code]);
      var cls = code[0] === "2" ? "c2xx" : code[0] === "5" ? "c5xx" : "c4xx";
      html += "<tr><td><span class=\"code-pill " + cls + '">' + esc(code) + "</span></td><td>" +
        md(r.description || "") + "</td></tr>";
    });
    html += "</tbody></table>";

    var ok = codes.filter(function (c) { return c[0] === "2"; })[0];
    if (ok) {
      var media = firstJson(deref(svc.spec, op.responses[ok]).content);
      var ex = responseExample(svc, media);
      if (ex !== null && ex !== undefined) {
        html += "<h4>Example response · " + esc(ok) + '</h4><pre class="code">' + hlJson(ex) + "</pre>";
      }
    }
    return html;
  }

  function curlFor(svc, op) {
    var url = baseUrl(svc) + op.path.replace(/\{([^}]+)\}/g, function (_, n) {
      var p = op.params.filter(function (x) { return x.name === n; })[0];
      return p && p.example !== undefined ? p.example : "1";
    });
    var lines = ["curl -X " + op.method.toUpperCase() + " '" + url + "' \\"];
    if (op.secured) lines.push("  -H 'Authorization: Bearer $MYHEALTHCARE_TOKEN' \\");
    if (op.requestBody) {
      lines.push("  -H 'Content-Type: application/json' \\");
      var media = firstJson(op.requestBody.content);
      var body = media ? sample(svc.spec, media.schema) : {};
      lines.push("  -d '" + JSON.stringify(body) + "'");
    } else {
      lines[lines.length - 1] = lines[lines.length - 1].replace(/ \\$/, "");
    }
    return lines.join("\n");
  }

  function tryPanel(svc, op) {
    var fields = "";
    op.params.forEach(function (p) {
      var sc = deref(svc.spec, p.schema || {});
      var val = p.example !== undefined ? p.example : (sc.default !== undefined ? sc.default : "");
      fields += '<div class="field"><label><code>' + esc(p.name) + "</code>" +
        (p.required ? '<span class="req">*</span>' : "") +
        " <span style=\"font-weight:400;color:var(--ink-3)\">in " + esc(p.in) + "</span></label>" +
        '<input data-pname="' + esc(p.name) + '" value="' + esc(val) + '" ' +
        'placeholder="' + esc(sc.type || "string") + '" /></div>';
    });

    if (op.requestBody) {
      var media = firstJson(op.requestBody.content);
      var body = media ? sample(svc.spec, media.schema) : {};
      fields += '<div class="field"><label>Request body <span style="font-weight:400;color:var(--ink-3)">application/json</span></label>' +
        "<textarea data-body>" + esc(JSON.stringify(body, null, 2)) + "</textarea></div>";
    }

    return '<div class="try" data-svc="' + esc(svc.key) + '" data-op="' + esc(op.id) + '">' +
      '<div class="try-head"><strong>Try it</strong>' +
      '<span class="hint">Sandbox — responses come from the published examples</span></div>' +
      '<div class="try-form">' + fields +
      '<div class="try-actions"><button class="btn btn-primary btn-sm" data-exec>Execute</button>' +
      '<span class="spin" data-status></span></div>' +
      '<div class="resp" data-resp></div></div>' +
      '<div class="try-actions" data-toggle-wrap><button class="btn btn-ghost btn-sm" data-try-toggle>Try it out</button></div>' +
      "</div>";
  }

  function opBlock(svc, op) {
    var anchor = svc.key + "-" + op.id;
    return '<div class="op" id="' + esc(anchor) + '" data-search="' +
      esc((op.method + " " + op.path + " " + op.summary).toLowerCase()) + '">' +
      '<button class="op-row" data-op-toggle>' + pill(op.method) +
      '<span class="op-path">' + pathHtml(op.path) + "</span>" +
      (op.secured ? LOCK : "") +
      '<span class="op-sum">' + esc(op.summary) + "</span>" + CHEV + "</button>" +
      '<div class="op-body">' +
      '<div class="op-desc">' + md(op.description) + "</div>" +
      paramsTable(svc, op.params, "path") +
      paramsTable(svc, op.params, "query") +
      paramsTable(svc, op.params, "header") +
      (op.requestBody ? "<h4>Request body</h4>" + md(op.requestBody.description || "") +
        (function () {
          var media = firstJson(op.requestBody.content);
          return media ? '<pre class="code">' + hlJson(sample(svc.spec, media.schema)) + "</pre>" : "";
        })() : "") +
      responsesBlock(svc, op) +
      "<h4>Request sample</h4>" +
      '<pre class="code">' + hlShell(curlFor(svc, op)) + "</pre>" +
      tryPanel(svc, op) +
      "</div></div>";
  }

  function schemasBlock(svc) {
    var schemas = (svc.spec.components || {}).schemas || {};
    var names = Object.keys(schemas);
    if (!names.length) return "";
    return "<h3>Schemas</h3>" + names.map(function (name) {
      var sc = schemas[name];
      return '<div class="schema"><button class="schema-row" data-schema-toggle>' +
        '<span class="nm">' + esc(name) + "</span>" +
        '<span class="ty">' + esc(sc.type || "object") + "</span>" + CHEV + "</button>" +
        '<div class="schema-body">' + md(sc.description || "") +
        (sc.properties ? '<table class="t"><thead><tr><th>Property</th><th>Description</th></tr></thead><tbody>' +
          Object.keys(sc.properties).map(function (p) {
            var ps = deref(svc.spec, sc.properties[p]);
            var t = ps.type || (ps.$ref ? "object" : "any");
            if (ps.format) t += " · " + ps.format;
            if (ps.readOnly) t += " · read-only";
            var required = (sc.required || []).indexOf(p) >= 0;
            return "<tr><td><code>" + esc(p) + "</code>" + (required ? '<span class="req">*</span>' : "") +
              '<span class="ptype">' + esc(t) + "</span></td><td>" + md(ps.description || "") + "</td></tr>";
          }).join("") + "</tbody></table>" : "") +
        '<h4>Example</h4><pre class="code">' + hlJson(sample(svc.spec, sc)) + "</pre>" +
        "</div></div>";
    }).join("");
  }

  function serviceBlock(svc) {
    var html = '<div class="svc" id="svc-' + esc(svc.key) + '">' +
      "<h2>" + esc(svc.title) + '<span class="ver">v' + esc(svc.version) + "</span></h2>" +
      "<p>" + esc(svc.summary) + "</p>" +
      '<div class="base">' + svc.servers.map(function (s) {
        return "<div><b>" + esc(s.description || "Server") + "</b> · " + esc(s.url) + "</div>";
      }).join("") + "</div></div>";

    html += '<div class="op-desc" style="margin-top:20px">' + md(svc.description) + "</div>";

    svc.groups.forEach(function (g) {
      html += '<div class="tag-head"><h3>' + esc(g.name) + "</h3>" +
        (g.description ? "<p>" + esc(g.description) + "</p>" : "") + "</div>";
      g.ops.forEach(function (op) { html += opBlock(svc, op); });
    });

    html += schemasBlock(svc);
    return html;
  }

  /* --------------------------------------------------------- static pages */
  /* Narrative content for the platform this portal documents. */

  function overviewSection() {
    return '<section class="sec" id="overview"><div class="wrap">' +
      '<h2>Platform overview</h2>' +
      "<p class=\"lede\"><strong>MyHealthcare</strong> models a hospital group's software estate the way one " +
      "actually looks: 101 independently-deployable services across fourteen business domains, talking over " +
      "HTTP and Kafka, each owning its own database, plus event-driven integration into an external ERP owned " +
      "by a different organization.</p>" +
      '<div class="stats">' +
      '<div class="stat"><b>101</b><span>Services, independently deployable</span></div>' +
      '<div class="stat"><b>14</b><span>Business domains</span></div>' +
      '<div class="stat"><b>285</b><span>HTTP dependency edges</span></div>' +
      '<div class="stat"><b>25</b><span>Kafka topics</span></div>' +
      '<div class="stat"><b>107</b><span>Event subscription edges</span></div>' +
      '<div class="stat"><b>15</b><span>Postgres databases, one per domain</span></div>' +
      "</div>" +
      '<div class="note"><strong>This portal documents three of the 101 services.</strong> ' +
      "The appointments domain (<code class=\"inl\">86xx</code>) and the pharmacy domain " +
      "(<code class=\"inl\">85xx</code>) are the two with published, hand-written contracts. " +
      "The remaining 98 services are Flask apps that emit no specification at all.</div>" +

      "<h2>Business domains</h2>" +
      "<p>Services are numbered by domain. The port block tells you where a service sits before you know " +
      "anything else about it — <code class=\"inl\">85xx</code> is pharmacy, <code class=\"inl\">87xx</code> " +
      "is revenue cycle.</p>" +
      '<table class="t"><thead><tr><th>Ports</th><th>Domain</th><th>Services</th><th>What it handles</th></tr></thead><tbody>' +
      [
        ["80xx", "Platform", 10, "Identity, auth, authorization, config, secrets, feature flags, tenancy, audit, service registry"],
        ["81xx", "Patients", 10, "System of record for demographics, consent, preferences, relationships, timeline, search, merge"],
        ["82xx", "Providers", 9, "Clinician records, credentialing, licensing, specialties, schedules, on-call rotas, performance"],
        ["83xx", "Clinical / EHR", 15, "Encounters, notes, problem lists, medication reconciliation, allergies, vitals, CPOE, care plans"],
        ["84xx", "Diagnostics", 8, "Lab and imaging orders and results, pathology, radiology worklist, specimen tracking"],
        ["85xx", "Pharmacy", 7, "Prescriptions, refills, drug interactions, formulary, inventory, dispensing"],
        ["86xx", "Scheduling", 5, "Appointments, slots, reminders, waitlist, room booking"],
        ["87xx", "Billing / RCM", 10, "Charge capture, coding, claims submission and adjudication, denials, invoicing, payments"],
        ["88xx", "Insurance", 6, "Eligibility, prior authorization, coverage verification, payer directory, EDI connect"],
        ["89xx", "Devices / IoT", 5, "Device registry and fleet, telemetry ingest, threshold alerting, remote monitoring"],
        ["90xx", "Communications", 5, "Notification orchestration plus SMS, email, push, and secure messaging gateways"],
        ["91xx", "AI / Analytics", 5, "Agent definitions, invocation records, analytics events, reporting, model registry"],
        ["92xx", "Facility / Ops", 5, "Facilities, wards and beds, equipment, sterile supply, maintenance"],
        ["93xx", "Integration", 1, "erp-bridge-service — the seam to the external ERP"]
      ].map(function (r) {
        return "<tr><td><code>" + r[0] + "</code></td><td><strong>" + r[1] + "</strong></td><td>" +
          r[2] + "</td><td>" + esc(r[3]) + "</td></tr>";
      }).join("") + "</tbody></table>" +

      "<h2>How records are shaped</h2>" +
      "<p>Every service stores records as a fixed envelope — <code class=\"inl\">id</code>, " +
      "<code class=\"inl\">status</code>, <code class=\"inl\">created_at</code>, " +
      "<code class=\"inl\">updated_at</code> — wrapped around a free-form JSONB " +
      "<code class=\"inl\">data</code> document. Responses flatten the two: envelope fields sit alongside " +
      "your own keys at the top level of the object. That is why the resource schemas allow additional " +
      "properties.</p>" +
      "<p>Cross-domain reads are HTTP calls; cross-domain writes are events. No service reads another " +
      "domain's database. Where a service needs fast local access to a peer's data it subscribes to that " +
      "peer's events and keeps its own snapshot.</p>" +

      "<h2>Events</h2>" +
      "<p>Twenty-five Kafka topics carry the platform's domain events. The ones the services on this page " +
      "publish and consume:</p>" +
      '<table class="t"><thead><tr><th>Topic</th><th>Published by</th><th>Consumed by</th></tr></thead><tbody>' +
      [
        ["appointment.booked", "appointments-service", "appointment-slots-service, reminders, room-booking, provider-schedule"],
        ["appointment.cancelled", "appointments-service", "appointment-slots-service, waitlist-service"],
        ["prescription.issued", "prescriptions-service", "dispensing-service, pharmacy-inventory, erp-bridge"],
        ["prescription.refill_requested", "prescriptions-service", "refills-service"],
        ["audit.event", "every service", "audit-log-service (24 partitions)"]
      ].map(function (r) {
        return "<tr><td><code>" + r[0] + "</code></td><td>" + esc(r[1]) + "</td><td>" + esc(r[2]) + "</td></tr>";
      }).join("") + "</tbody></table>" +
      "</div></section>";
  }

  function gettingStartedSection() {
    return '<section class="sec" id="getting-started"><div class="wrap">' +
      "<h2>Getting started</h2>" +
      "<h3>1. Get a token</h3>" +
      "<p>Every resource route is guarded by an HS256 JWT issued by <code class=\"inl\">auth-service</code>, " +
      "sent as <code class=\"inl\">Authorization: Bearer &lt;token&gt;</code>. The token must carry " +
      "<code class=\"inl\">sub</code> and <code class=\"inl\">exp</code> claims and a " +
      "<code class=\"inl\">scopes</code> array. Scopes are per-domain and per-verb — " +
      "<code class=\"inl\">appointments.read</code>, <code class=\"inl\">appointments.write</code>, " +
      "<code class=\"inl\">prescriptions.read</code>, <code class=\"inl\">prescriptions.write</code>. " +
      "A token with <code class=\"inl\">scopes: [\"*\"]</code> satisfies any requirement.</p>" +
      '<div class="note warn"><strong>Local development.</strong> Setting ' +
      "<code class=\"inl\">AUTH_DISABLED=1</code> on a service bypasses verification entirely and injects a " +
      "<code class=\"inl\">dev-user</code> principal. The shipped <code class=\"inl\">.env.example</code> " +
      "enables it, so the default local experience does not exercise the auth path.</div>" +

      "<h3>2. Make your first call</h3>" +
      '<pre class="code">' + hlShell(
        "curl -X GET 'http://localhost:8600/api/appointments/?limit=25' \\\n" +
        "  -H 'Authorization: Bearer $MYHEALTHCARE_TOKEN'"
      ) + "</pre>" +

      "<h3>3. Watch the event land</h3>" +
      "<p>Every mutating endpoint publishes a Kafka domain event, and <em>every</em> endpoint — reads " +
      "included — publishes an <code class=\"inl\">audit.event</code>. Booking an appointment emits " +
      "<code class=\"inl\">appointment.booked</code>, which " +
      "<code class=\"inl\">appointment-slots-service</code> consumes to flip the referenced slot to " +
      "<code class=\"inl\">booked</code>.</p>" +

      "<h3>Conventions</h3>" +
      '<div class="cards">' +
      '<div class="card"><h3>Correlation ids</h3><p>Send <code class="inl">X-Request-ID</code> and it is ' +
      "propagated across HTTP hops and onto published events. Omit it and the service generates one. It is " +
      "echoed on every response.</p></div>" +
      '<div class="card"><h3>Pagination</h3><p>List endpoints take <code class="inl">limit</code> and ' +
      "<code class=\"inl\">offset</code>. Page size defaults to 50; values above 500 are silently clamped " +
      "rather than rejected.</p></div>" +
      '<div class="card"><h3>Ad-hoc filtering</h3><p>Any query parameter other than the documented ones is ' +
      "compiled to a JSON field filter. Multiple filters are ANDed. The set of keys is open-ended, so it " +
      "cannot be enumerated here.</p></div>" +
      '<div class="card"><h3>Soft deletes</h3><p><code class="inl">DELETE</code> sets ' +
      "<code class=\"inl\">status</code> to <code class=\"inl\">inactive</code> and returns the record. " +
      "Nothing is removed from the database.</p></div>" +
      "</div></div></section>";
  }

  function supportSection() {
    return '<section class="sec" id="support"><div class="wrap">' +
      "<h2>Support</h2>" +
      "<p>Questions about the API go to the platform team. Include the " +
      "<code class=\"inl\">X-Request-ID</code> from the response you are asking about — it is the " +
      "correlation id across every hop and every event, and it is the fastest way for us to find your call " +
      "in the audit stream.</p>" +
      '<div class="cards">' +
      '<div class="card"><h3>Platform team</h3><p>#healthcare-platform on Slack. Business hours, ' +
      "Copenhagen time.</p></div>" +
      '<div class="card"><h3>Status</h3><p>Per-service liveness and readiness probes are documented ' +
      "under each service's Health section.</p></div>" +
      '<div class="card"><h3>Change log</h3><p>Contract changes are announced in #healthcare-platform ' +
      "before they ship. Subscribe if you integrate.</p></div>" +
      "</div></div></section>";
  }

  /* ---------------------------------------------------------------- shell */

  function sidebar() {
    var html = '<nav class="side">';
    html += '<div class="side-group"><div class="side-title">Documentation</div>' +
      '<a href="#overview">Platform overview</a>' +
      '<a href="#getting-started">Getting started</a>' +
      '<a href="#api">API reference</a>' +
      '<a href="#support">Support</a></div>';

    SERVICES.forEach(function (svc) {
      html += '<div class="side-group"><div class="side-title">' + esc(svc.title.replace("-service", "")) + "</div>";
      html += '<div class="side-svc"><a href="#svc-' + esc(svc.key) + '" style="padding-left:8px">Overview</a></div>';
      svc.groups.forEach(function (g) {
        g.ops.forEach(function (op) {
          html += '<a class="side-op" href="#' + esc(svc.key + "-" + op.id) + '" ' +
            'data-search="' + esc((op.method + " " + op.path + " " + op.summary).toLowerCase()) + '">' +
            '<span class="m" data-m="' + op.method + '">' + op.method.toUpperCase() + "</span>" +
            '<span class="t">' + esc(op.summary) + "</span></a>";
        });
      });
      html += "</div>";
    });
    return html + "</nav>";
  }

  function header() {
    return '<header class="hdr">' +
      '<a class="brand" href="#top">' +
      '<span class="brand-mark"><svg width="17" height="17" viewBox="0 0 24 24" fill="none">' +
      '<path d="M3 12h4l2.5-6L14 18l2.5-6H21" stroke="white" stroke-width="2.1" ' +
      'stroke-linecap="round" stroke-linejoin="round"/></svg></span>' +
      '<span class="brand-name">MyHealthcare</span>' +
      '<span class="brand-sub">API Portal</span></a>' +
      '<nav class="hdr-nav">' +
      '<a href="#overview">Docs</a>' +
      '<a href="#api">API reference</a>' +
      '<a href="#getting-started">Guides</a>' +
      '<a href="#support">Support</a></nav>' +
      '<div class="hdr-right">' +
      '<input class="hdr-search" id="q" type="search" placeholder="Search endpoints\u2026" ' +
      'autocomplete="off" spellcheck="false" />' +
      '<a class="hdr-cta" href="#getting-started">Get a token</a></div></header>';
  }

  function hero() {
    return '<section class="hero" id="top"><div class="wrap">' +
      '<div class="eyebrow">Developer documentation</div>' +
      "<h1>MyHealthcare API Portal</h1>" +
      '<p class="lede">Book appointments, manage slot inventory, and issue prescriptions against the ' +
      "healthcare-org platform. Three services, twenty-four endpoints, one bearer token.</p>" +
      '<div class="hero-actions">' +
      '<a class="btn btn-primary" href="#getting-started">Get started</a>' +
      '<a class="btn btn-ghost" href="#api">Browse the API reference</a>' +
      "</div></div></section>";
  }

  function apiSection() {
    return '<section class="sec" id="api"><div class="wrap">' +
      "<h2>API reference</h2>" +
      "<p class=\"lede\">Expand an endpoint for its parameters, schemas, and worked examples, then use " +
      "<strong>Try it out</strong> to send a request without leaving the page.</p>" +
      SERVICES.map(serviceBlock).join("") +
      "</div></section>";
  }

  function footer() {
    return '<footer class="foot">' +
      '<div class="foot-links">' +
      '<a href="#overview">Documentation</a><a href="#api">API reference</a>' +
      '<a href="#getting-started">Getting started</a><a href="#support">Support</a></div>' +
      "<div>MyHealthcare API Portal · healthcare-org platform team · v1.4.2</div>" +
      "</footer>";
  }

  /* ----------------------------------------------------------- interaction */

  function mockResponse(root) {
    var svcKey = root.getAttribute("data-svc");
    var opId = root.getAttribute("data-op");
    var found = findOp(svcKey, opId);
    if (!found) return null;
    var svc = found.svc, op = found.op;

    var codes = Object.keys(op.responses);
    var code = codes.filter(function (c) { return c[0] === "2"; })[0] || codes[0] || "200";
    var media = firstJson(deref(svc.spec, op.responses[code]).content);
    var body = responseExample(svc, media);

    /* Echo the values the reader typed back into the response, so the panel
       feels connected to the form rather than canned. */
    var inputs = root.querySelectorAll("[data-pname]");
    var qs = [];
    for (var i = 0; i < inputs.length; i++) {
      var name = inputs[i].getAttribute("data-pname");
      var val = inputs[i].value;
      var p = op.params.filter(function (x) { return x.name === name; })[0];
      if (!p || val === "") continue;
      if (p.in === "query") qs.push(encodeURIComponent(name) + "=" + encodeURIComponent(val));
      if (p.in === "path" && body && typeof body === "object" && "id" in body) {
        var n = parseInt(val, 10);
        if (!isNaN(n)) body.id = n;
      }
    }

    var bodyEl = root.querySelector("[data-body]");
    if (bodyEl && body && typeof body === "object" && !Array.isArray(body)) {
      try {
        var sent = JSON.parse(bodyEl.value);
        for (var k in sent) if (!(k in body) || body[k] === null) body[k] = sent[k];
      } catch (e) { /* leave the example alone if the JSON is invalid */ }
    }

    var url = baseUrl(svc) + op.path.replace(/\{([^}]+)\}/g, function (_, n) {
      var el = root.querySelector('[data-pname="' + n + '"]');
      return el && el.value ? el.value : "1";
    }) + (qs.length ? "?" + qs.join("&") : "");

    return { code: code, body: body, url: url, method: op.method.toUpperCase() };
  }

  function requestId() {
    var hex = "0123456789abcdef", out = "";
    for (var i = 0; i < 32; i++) out += hex[Math.floor(Math.random() * 16)];
    return out;
  }

  function execute(root) {
    var status = root.querySelector("[data-status]");
    var out = root.querySelector("[data-resp]");
    status.textContent = "Sending\u2026";
    out.innerHTML = "";

    var started = Date.now();
    setTimeout(function () {
      var res = mockResponse(root);
      status.textContent = "";
      if (!res) { out.innerHTML = '<div class="note warn">Could not build a response for this operation.</div>'; return; }
      var cls = res.code[0] === "2" ? "c2xx" : res.code[0] === "5" ? "c5xx" : "c4xx";
      out.innerHTML =
        '<div class="resp-line"><span class="code-pill ' + cls + '">' + esc(res.code) + "</span>" +
        "<span>" + esc(res.method) + " " + esc(res.url) + "</span>" +
        "<span style=\"margin-left:auto\">" + (Date.now() - started) + " ms</span></div>" +
        "<h4>Response headers</h4>" +
        '<pre class="code">' + esc(
          "content-type: application/json\nx-request-id: " + requestId()
        ) + "</pre>" +
        "<h4>Response body</h4>" +
        '<pre class="code">' + hlJson(res.body === null || res.body === undefined ? {} : res.body) + "</pre>";
    }, 260 + Math.floor(Math.random() * 280));
  }

  function filter(term) {
    term = term.trim().toLowerCase();
    var ops = document.querySelectorAll(".op[data-search], .side-op[data-search]");
    for (var i = 0; i < ops.length; i++) {
      var hit = !term || ops[i].getAttribute("data-search").indexOf(term) >= 0;
      ops[i].style.display = hit ? "" : "none";
    }
  }

  function wire() {
    document.addEventListener("click", function (ev) {
      var t = ev.target;

      var opBtn = t.closest ? t.closest("[data-op-toggle]") : null;
      if (opBtn) { opBtn.parentNode.classList.toggle("open"); return; }

      var scBtn = t.closest ? t.closest("[data-schema-toggle]") : null;
      if (scBtn) { scBtn.parentNode.classList.toggle("open"); return; }

      var tryBtn = t.closest ? t.closest("[data-try-toggle]") : null;
      if (tryBtn) {
        var panel = tryBtn.closest(".try");
        panel.classList.toggle("on");
        tryBtn.textContent = panel.classList.contains("on") ? "Cancel" : "Try it out";
        return;
      }

      var execBtn = t.closest ? t.closest("[data-exec]") : null;
      if (execBtn) { ev.preventDefault(); execute(execBtn.closest(".try")); return; }
    });

    var q = document.getElementById("q");
    if (q) q.addEventListener("input", function () { filter(q.value); });

    /* Open the operation a deep link points at. */
    function openHash() {
      var id = location.hash.replace(/^#/, "");
      if (!id) return;
      var el = document.getElementById(id);
      if (el && el.classList.contains("op")) el.classList.add("open");
      var links = document.querySelectorAll(".side a, .hdr-nav a");
      for (var i = 0; i < links.length; i++) {
        links[i].classList.toggle("on", links[i].getAttribute("href") === "#" + id);
      }
    }
    window.addEventListener("hashchange", openHash);
    openHash();
  }

  /* ------------------------------------------------------------------ boot */

  function boot() {
    if (!DATA.length) {
      document.getElementById("root").innerHTML =
        '<div class="noscript"><h2>Documentation unavailable</h2>' +
        "<p>The API catalog failed to load. Refresh the page, or contact the platform team.</p></div>";
      return;
    }
    document.getElementById("root").innerHTML =
      header() + '<div class="shell">' + sidebar() +
      '<main class="main">' + hero() + overviewSection() + gettingStartedSection() +
      apiSection() + supportSection() + footer() + "</main></div>";
    wire();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot);
  } else {
    boot();
  }
})();
