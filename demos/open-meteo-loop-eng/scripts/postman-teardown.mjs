#!/usr/bin/env node
// Removes the Postman oracle created by postman-setup.mjs. Deletes the
// collection and environment, and deletes the workspace only if setup created
// it (recorded in oracle.ids.json). Safe to run repeatedly.
//
// Usage: node postman-teardown.mjs <APP_DIR>
// Requires: POSTMAN_API_KEY in the environment, Node 18+ (built-in fetch).

import { existsSync, readFileSync, rmSync } from "node:fs";
import { join } from "node:path";

const API = "https://api.getpostman.com";
const KEY = process.env.POSTMAN_API_KEY;
const APP_DIR = process.argv[2];

if (!KEY) {
  console.error("[WARN] POSTMAN_API_KEY is not set — skipping Postman cloud cleanup.");
  process.exit(0);
}
if (!APP_DIR) {
  console.error("[FAIL] Missing APP_DIR argument.");
  process.exit(1);
}

const idsPath = join(APP_DIR, "postman", "oracle.ids.json");
if (!existsSync(idsPath)) {
  console.log("[OK] No oracle.ids.json — nothing to remove in Postman.");
  process.exit(0);
}

const { workspaceId, workspaceCreated, collectionUid, environmentUid } = JSON.parse(
  readFileSync(idsPath, "utf8"),
);

async function del(path, label) {
  const res = await fetch(`${API}${path}`, {
    method: "DELETE",
    headers: { "X-Api-Key": KEY },
  });
  if (res.ok || res.status === 404) {
    console.log(`[OK] Removed ${label}`);
  } else {
    const text = await res.text();
    console.log(`[WARN] Could not remove ${label} (${res.status}): ${text.slice(0, 200)}`);
  }
}

if (collectionUid) await del(`/collections/${collectionUid}`, `collection ${collectionUid}`);
if (environmentUid) await del(`/environments/${environmentUid}`, `environment ${environmentUid}`);

if (workspaceCreated && workspaceId) {
  await del(`/workspaces/${workspaceId}`, `workspace ${workspaceId}`);
} else if (workspaceId) {
  console.log(`[SKIP] Workspace ${workspaceId} pre-existed setup — leaving it in place.`);
}

// Remove the local ID cache so the next setup provisions fresh.
rmSync(idsPath, { force: true });
console.log(`[OK] Removed ${idsPath}`);
