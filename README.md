# Booth Demos

Reusable scaffold for creating repeatable tradeshow booth demos.

## How it works

1. Run the `/booth-demo-generator` skill in Claude Code
2. Provide the front matter for your product (name, use case, APIs, key messages, CTA)
3. The skill generates a complete demo folder with README, scripts, and presentation

## Folder layout

```
booth-demos/
  .claude/skills/booth-demo-generator/   # the generator skill
  templates/demo/                        # README template
  demos/
    <demo-slug>/
      frontmatter.yaml                   # unique per demo
      README.md                          # generated from template + frontmatter
      presentation/                      # slide deck
      scripts/
        setup.sh                         # run before demoing
        teardown.sh                      # run after to reset
```

## Running a demo

```bash
cd demos/<demo-slug>
./scripts/setup.sh     # validates prereqs, opens presentation
# ... run the demo ...
./scripts/teardown.sh  # cleans up for the next run
```

## Front matter fields

Each demo provides a `frontmatter.yaml` with:

```yaml
product:              # the product being demoed
name:                 # human-readable demo title
use_case:             # one-sentence problem statement
primary_api:          # API endpoint(s) or repo
key_messages:         # what the attendee should walk away knowing
cta:                  # call-to-action links or install commands
demo_length:          # target duration (default: 10m)
presentation_title:   # title for the slide deck
brand_style:          # design-sync or manual
```

The generator skill enforces everything else — structure, sections, rules, and presentation format.
