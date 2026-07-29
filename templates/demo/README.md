# {{name}}

{{story — one paragraph describing the narrative arc of the demo}}

## Product summary

- **Product:** {{product}}
- **Use case:** {{use_case}}
- **Duration:** {{demo_length}}
- **CTA:** {{cta}}

## Pre-requisites

| Requirement | How to get it |
|---|---|
| {{tool/account}} | {{install link or setup steps}} |

### {{Product}}-specific setup

Any workspace, environment, or account prep that must happen before demo day.

## Setup

Run the setup script before each demo session:

```bash
./scripts/setup.sh
```

The script checks:
- {{list what setup.sh validates and prepares}}

### Authentication

{{Describe auth options — API key, OAuth, etc. Include exact commands.}}

### Pre-demo checklist

- [ ] {{Terminal open in this directory}}
- [ ] {{Font size large enough for booth audience}}
- [ ] {{Presentation open on booth monitor}}
- [ ] {{Environment is clean — no leftover artifacts from prior runs}}

---

## Talk Track & Click Track

**Total time: ~{{demo_length}}**

---

### Act 1: {{Title}} ({{duration}})

#### Talk Track

> "{{Exact words the presenter says.}}"

#### Click Track

**Show:** {{What to display on screen}}

**Do:** {{Exact action — command to type, button to click, URL to open}}

---

### Act N: The Close (30 sec)

#### Talk Track

> "{{Closing statement and CTA}}"

#### Click Track

**Show:** {{CTA slide or URL}}

---

## Tear Down / Reset

Run the teardown script after each demo:

```bash
./scripts/teardown.sh
```

The script:
- {{list what teardown.sh cleans up}}

### Full reset between demo days

```bash
./scripts/teardown.sh
./scripts/setup.sh
```

## Troubleshooting

| Issue | Fix |
|---|---|
| {{common problem}} | {{how to fix it}} |

## Additional Resources

| Resource | Link |
|---|---|
| {{resource name}} | {{url}} |
