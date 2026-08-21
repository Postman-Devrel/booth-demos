# {{name}}

> {{Format}} — target length **{{length}}**. This README is the single source of truth.
> Read it top to bottom before you present; everything you need is here.

{{story — one paragraph describing the narrative arc}}

---

## 1. Product summary

- **Product:** {{product}}
- **Use case:** {{use_case}}
- **Format:** {{format}} ({{length}}) — see [templates/formats/{{format}}.md](../../../templates/formats/{{format}}.md)
- **Audience:** {{audience}}

**The story (the narrative arc):**

> {{One paragraph the presenter could say out loud as a summary of the whole thing.}}

**CTA:**

- {{cta}}

**Total time: ~{{length}}.** {{Which parts stand alone, which need network, what can be dropped.}}

---

## 2. Pre-requisites

| Requirement | How to get it |
|---|---|
| {{tool/account}} | {{install link, version minimum, or setup steps}} |

### {{Product}}-specific setup

{{Any workspace, environment, or account prep that must happen before the day.}}

---

## 3. Setup

```bash
cd content/{{format-folder}}/{{slug}}
./scripts/setup.sh
```

`setup.sh` will:

1. {{list exactly what it validates and prepares}}

### Authentication

{{API key, OAuth, or "none required". Include exact commands.}}

### Pre-flight checklist

- [ ] Terminal open in this directory, font size bumped for the room
- [ ] Presentation open and fullscreened
- [ ] {{Environment is clean — no leftover artifacts from prior runs}}
- [ ] {{Offline fallback verified, if the venue wifi is unknown}}

---

## 4. Talk track & click track

**Total time: ~{{length}}**

<!--
  Acts and their budgets come from the format definition in templates/formats/.
  Bootcamps use modules instead of acts — see templates/formats/bootcamp.md.
  Every act carries BOTH tracks: what you say, and what you do, interleaved.
-->

---

### Act 1: {{Title}} ({{duration}})

#### Talk track

> "{{The exact words. Verbatim sentences, not bullet points — a presenter should be able
> to read this as-is if the room goes cold.}}"

#### Click track

**Show:** {{what is on screen — browser tab, terminal, editor pane}}

**Do:** {{the exact action — the literal command, the button, the URL, the full prompt}}

**Show (payoff):** {{switch to where the result landed and show the real artifact}}

---

### Act N: The close ({{duration}})

#### Talk track

> "{{Closing statement and CTA.}}"

#### Click track

**Show:** {{CTA slide}}

---

## 5. Tear down / reset

```bash
./scripts/teardown.sh
```

The script:

- {{list what it cleans up}}

{{Manual steps, if any — deleting cloud resources, revoking keys, resetting a workspace.}}

### Full reset between sessions

```bash
./scripts/teardown.sh
./scripts/setup.sh
```

---

## 6. Troubleshooting

| Issue | Fix |
|---|---|
| {{common problem}} | {{how to fix it, live, in under 30 seconds}} |

---

## 7. Additional resources

| Resource | Link |
|---|---|
| {{resource name}} | {{url}} |
