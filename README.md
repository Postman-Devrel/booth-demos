# Postman DevRel Content

One repo for the talks, demos, and workshops the team delivers — so the same material can be
given in more than one format, by more than one person, without being rebuilt each time.

Every piece of content follows the same pattern regardless of length: **front matter** that
declares what it is, a **README** that is the single source of truth for the presenter, a
**self-contained deck**, and **`setup.sh` / `teardown.sh`** that make it repeatable.

## Formats

Every piece of content declares a format. The format sets the act plan, the deck size, the
extra assets, and the pacing rules — the definitions are in [templates/formats/](templates/formats/)
and the generator follows them.

| Format | Length | Think of it as | Folder | Definition |
|---|---|---|---|---|
| `lightning-talk` | ~10 min | an NBA quarter | [content/lightning-talks/](content/lightning-talks/) | [lightning-talk.md](templates/formats/lightning-talk.md) |
| `short-talk` | 25–30 min | a handball half | [content/short-talks/](content/short-talks/) | [short-talk.md](templates/formats/short-talk.md) |
| `standard-talk` | 40–45 min | a football half | [content/standard-talks/](content/standard-talks/) | [standard-talk.md](templates/formats/standard-talk.md) |
| `bootcamp` | 50 min+, set by the topic | no clock — it ends when the room can do the thing | [content/bootcamps/](content/bootcamps/) | [bootcamp.md](templates/formats/bootcamp.md) |

Booth demos are lightning talks delivered at a booth — the `venues` field in the front matter
records where a piece of content has been given, the format records how long it runs.

The same material can exist in several formats. When it does, the shorter one sets
`derived_from` in its front matter so the relationship is explicit instead of folklore.

## Catalog

| Content | Format | Length | Product | Status |
|---|---|---|---|---|
| [Fern — Docs, SDKs, and a CLI for your API](content/lightning-talks/fern/) | lightning-talk | 10m | Fern | ready |
| [Claude Code + Postman](content/lightning-talks/claude-code-postman-plugin/) | lightning-talk | 10m | Postman Claude Code Plugin | ready |
| [Stop Prompting. Start Looping.](content/lightning-talks/open-meteo-loop-eng/) | lightning-talk | 10m | Postman CLI | ready |
| [Make MCPs Your Documentation Best Friend](content/short-talks/mcp-docs-best-friend/) | short-talk | 25–30m | Fern | draft |

## Adding new content

1. Run `/content-generator` in Claude Code.
2. Answer the first question — **which format** — then supply the front matter.
3. The skill scaffolds `content/<format>/<slug>/` from [templates/](templates/), sized to that
   format.
4. Run `./scripts/validate-content.sh` and add your row to the catalog above.

To do it by hand, copy [templates/content/](templates/content/) into the right format folder
and read the format definition before writing the act plan.

## Delivering content

```bash
cd content/<format>/<slug>
./scripts/setup.sh      # validates prereqs, prepares state, opens the deck
# ... deliver it ...
./scripts/teardown.sh   # resets everything for the next run
```

The README in that folder is written to be read top to bottom before you present. It has the
verbatim talk track, the click track, the pre-flight checklist, and the troubleshooting table.

## Repo layout

```
.claude/skills/content-generator/    # the scaffolding skill
scripts/validate-content.sh          # checks every folder against the pattern
templates/
  formats/                           # the four format definitions — act plans, budgets, rules
  content/                           # the shared skeleton: README, frontmatter, scripts
content/
  lightning-talks/<slug>/
  short-talks/<slug>/
  standard-talks/<slug>/
  bootcamps/<slug>/
```

## Validation

```bash
./scripts/validate-content.sh                       # everything
./scripts/validate-content.sh mcp-docs-best-friend  # one piece
```

Fails when a folder is missing required files, when front matter is missing a required field,
or when a piece of content declares a format that does not match the directory it lives in.
Warns on missing `owner` / `status` / `audience` / `venues` and on anything absent from the
catalog above.

## Front matter

Required on every piece of content: `format`, `length`, `product`, `name`, `use_case`,
`key_messages`, `cta`, `presentation_title`.

Recommended: `owner`, `status`, `audience`, `venues`, `primary_api`, `brand_style`.

The annotated reference is [templates/content/frontmatter.yaml](templates/content/frontmatter.yaml).
