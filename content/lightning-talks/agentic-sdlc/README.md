# Agentic SDLC with Context Graph and API Simulations

> Lightning talk, target length **10m**. This README is the single source of truth.
> Read it top to bottom before you present; everything you need is here.

An agent can write an endpoint in minutes. The slow part is everything around it: the contract, the dependencies, the tests, and leaving a setup the next person or agent can use. This talk shows two skills from the Postman plugin that cover that gap, **api-discovery** (which includes Context Graph) and **api-simulation**, and then plays a recording of two agents working consecutive tasks on a healthcare claims feature, with a Postman workspace carrying the API assets from one to the other.

---

## 1. Product summary

- **Product:** Postman plugin: api-discovery (with Context Graph) and api-simulation
- **Use case:** Give an agent the context to change an API safely, a runnable environment to develop against its dependencies, and a way to hand the work to the next agent.
- **Format:** lightning-talk (10m), see [templates/formats/lightning-talk.md](../../../templates/formats/lightning-talk.md)
- **Audience:** Engineers who already use coding agents on a multi-service codebase and have seen a change break something downstream.

**The story (the narrative arc):**

> Agents write code fast but break what they cannot see. Context Graph tells the agent which APIs and relationships matter before it edits (the library catalog, not a walk down every aisle). API simulation turns those dependencies into one runnable setup so the agent can build and test without bringing up real services. Publish the simulation and collection to a workspace and a second agent can pull them, rerun the checks, and extend the work.

**CTA:**

- Try all the skills: https://github.com/postmanlabs/postman-plugin/tree/main/skills
- Install the plugin: `claude plugin install github:Postman-Devrel/postman-claude-code-plugin`

**Total time: ~10 min, in practice a little over.** Slides 1 to 5 are about 8 minutes spoken (about 1,130 words of notes at 140 wpm) and the recording on slide 6 is 95 seconds, so use the cut list in section 4 if the slot is strict. Everything runs offline: the demo is a recording, not a live run.

**Deck.** The deck is a PowerPoint file, not the HTML deck the other talks use: [presentation/Agentic_SDLC_Conference_Talk.pptx](presentation/Agentic_SDLC_Conference_Talk.pptx). [presentation/index.html](presentation/index.html) is a landing page that links to it. The speaker notes in the deck are the talk track below.

---

## 2. Pre-requisites

| Requirement | How to get it |
|---|---|
| PowerPoint or Keynote | Either opens the .pptx; present in presenter view so the notes show. Check that the slide 6 video plays and the build animations run in the app you will present from. |
| Nothing else for the talk | The demo is a recording embedded in slide 6. No network, login or running services. |
| Optional, to try the skills yourself | Claude Code and the Postman plugin: `claude plugin install github:Postman-Devrel/postman-claude-code-plugin`. Context Graph needs a Postman team that has it enabled. |

---

## 3. Setup

```bash
cd content/lightning-talks/agentic-sdlc
./scripts/setup.sh
```

`setup.sh` will:

1. Check the .pptx is present and a valid archive.
2. Check the demo recording is embedded in it.
3. Open the deck.

### Authentication

None required.

### Pre-flight checklist

- [ ] Deck open in presenter view, on slide 1
- [ ] Slide 6 recording played once so it is not cold, volume checked
- [ ] Build animations run on slides 2 to 5 in the app you will present from

---

## 4. Talk track & click track

**Total time: ~10 min, in practice a little over.** The talk track is the speaker notes from the deck. Act 2 is longer than the format's 1 minute budget, see the cut list at the end of this section.

---

### Act 1: The hook (~1 min)

#### Talk track

*Slide 1*

> Show of hands: Raise your hands if you’ve used coding agents to do any type of engineering work. Now keep your hand raised if the agent did exactly what you wanted with zero mistakes and didn’t break any existing functionality. LIARS.
>
> So what usually ends up happening is that your agents can write code but then those changes end up breaking other downstream dependencies. That’s the part nobody talks about. The agent is doing the engineering work, but I’m the one keeping track of everything around it: the context, the dependencies, what’s been verified. So this talk is about how I’ve been handling that, starting with the Postman plugin.

#### Click track

**Show:** Slide 1 (title).

**Do:** Ask for a show of hands, then the second ask with the hand still raised.

---

### Act 2: The setup (~7 min)

Two skills, one idea each. Slides 2 to 5.

#### Talk track

*Slide 2*

> An agent can write an endpoint quickly. The engineering work around that endpoint is usually what takes longer: understanding the contract, finding the dependencies, testing the behavior, and leaving the next person or agent a setup they can use.
>
> That’s the part of the agentic SDLC I want to talk about: how an agent gets the context to make a change, verifies it, and passes useful work into the next task.
>
> The Postman plugin gives the agent skills for API engineering. Each skill contains instructions it can read for a task: which tools to use, which files to work with, and how to check the result. The broader plugin covers development, testing, documentation, CI, and monitoring.
>
> Today we’re focusing on two skills: api-discovery, which includes Context Graph, and api-simulation. One helps the agent understand the APIs and relationships involved. The other gives it an environment where it can develop against those dependencies.
>
> We’ll follow two agents working on consecutive tasks, with a Postman workspace carrying the API assets between them.
>
> So let's start with the first skill, api-discovery. Before an agent changes anything, it needs to know what that change touches, and that's where Context Graph comes in.

*Slide 3*

> Imagine you walk into a library and ask the librarian to find everything about chess. There is no computer catalog, so the only way to answer is on foot. The librarian can walk through the building, search every shelf, and inspect individual books. A more experienced librarian might do that faster and notice more, but they are still searching the entire building from scratch.
>
> Now give the librarian access to the library's computer catalog. Instead of starting with the first shelf and working aisle by aisle, they can search once and get a list of relevant books with their exact shelf locations. The catalog tells them where to begin, which books to pull, and which sections deserve a closer look.
>
> It can also point them to a chapter inside a book with an unrelated title, a book stored at another location, or a resource that is not on a physical shelf at all, like an audiobook. The librarian can then open the available books and verify that they contain what you need.
>
> In this analogy, the librarian is the model, the shelves are the checked-out repositories, and the catalog is the Context Graph API. The Context Graph API tells the model which services, APIs, endpoints, and relationships are likely to matter and where to focus its search. Instead of exploring hundreds of repositories one by one, the model can start with a specific set of candidates and verify those leads in the code wherever possible.
>
> The catalog is also updated every night as books are added, removed, or moved. In the same way, the Context Graph refreshes nightly from your connected data, so it continues to reflect new services, changed endpoints, and updated relationships.
>
> A better model is like a faster, more experienced librarian. It can search the shelves more efficiently, but it still cannot find something that is not on those shelves.
>
> In the Postman plugin, that Context Graph query is part of the api-discovery skill. It gives the agent a starting point: which APIs are relevant to the task, where to find them, and which relationships to verify.
>
> Once we know which dependencies matter, we still need a way to develop against them. Knowing where an API lives doesn’t mean its service is available to run locally. That’s where the second skill, api-simulation, comes in: it turns the dependencies we’ve identified into a runnable environment.

*Slide 4*

> The Context Graph gives us a way to find the right starting points. Let me make that concrete with the feature we’re building for the rest of this talk.
>
> We have this healthcare app which is the backend for a hospital. Inside it are a bunch of services, one of which is a patients service which will store a patient’s insurance ID.
>
> There’s two tasks that we are giving two separate agents. Agent A needs to build an API to view insurance claims. To do that, it will use the context graph to find dependencies of the patients service. Once we get the answer, Agent A can build the claims view, with insurance ID, name, and amount, knowing where each field comes from.
>
> Then Agent B will take the insurance info, either approve or deny it, and send the decision to the billing service.
>
> This leaves us a practical problem. To exercise these two APIs, I’d need myhealthcare.dev, the patient service, and the billing service all running on my machine. Knowing where an API lives doesn’t mean I can run it. And every service the agent has to bring up costs time and tokens.
>
> What I want instead is for the agent to run only the insurance code and talk to stand-ins for everything else. That’s what api-simulation does, and it’s next.

*Slide 5*

> Suppose my service calls four other APIs. To develop it locally, I need a way to exercise those calls, including their responses and failures, without bringing up all four real services.
>
> An API simulation groups the dependency mocks into a runnable setup. Each mock represents an API; the simulation defines how to reach them together. Its basically a group of mocks. My actual service runs locally and sends its dependency calls to that setup.
>
> That gives me a repeatable environment. I can run requests through my code and inspect the calls the simulated dependencies receive. Where needed, the simulation can apply delays, errors, or rate limits to exercise failure handling.
>
> Now save the requests and assertions as a Postman collection and publish the simulation and collection to a workspace. Another agent can retrieve them, start the same dependency setup, and rerun the existing checks before changing anything.
>
> That’s how the agents work together in this demo. They work in separate sessions, and the second uses the API assets the first published. The workspace gives them a place to share those assets without passing a conversation transcript around.
>
> Let’s walk through the recording, starting with the dependencies Agent A discovers for the claims-review feature.

#### Click track

**Show:** Slide 2 (the Postman plugin), then slides 3 and 4 (api-discovery and Context Graph), then slide 5 (api-simulation).

**Do:** Click through the build on each slide as you reach it. Slide 4 is a picture of the healthcare app and the two tasks.

---

### Act 3: The demo (~1.5 min, the recording)

#### Talk track

The slide 6 recording has no speaker notes in the deck. Slide 5 ends with "Let's walk through the recording, starting with the dependencies Agent A discovers for the claims-review feature." Narrate over the 95-second recording or let it play; the beats on screen are Agent A discovering the dependencies and building and testing the claims-review feature, then Agent B pulling the workspace and adding payer filtering.

#### Click track

**Show:** Slide 6 (embedded recording, `copilot-api-simulation.mp4`, 95 s, recorded with GitHub Copilot).

**Do:** Play the video.

**Show (payoff):** The finished workspace, with the simulation and the collection of saved requests in it.

---

### Act 4: The close (under 1 min)

#### Talk track

Slides 7 ("Try all the skills") and 8 (thank you) have no speaker notes in the deck yet, so this is a placeholder. Say one sentence of meaning and point at the CTA:

> The agent did the engineering work; the plugin keeps track of the context, the dependencies and what has been verified. Try all the skills at github.com/postmanlabs/postman-plugin.

#### Click track

**Show:** Slide 7, then slide 8.

---

### If you are over time

Cut in this order:

1. Slide 3's closing paragraphs (the faster-librarian point and the nightly refresh), the longest notes in the deck (about 400 words).
2. Slide 4's walkthrough: say the two tasks in one sentence each.
3. Never cut the recording or the CTA.

---

## 5. Tear down / reset

```bash
./scripts/teardown.sh
```

Setup creates no state, so there is nothing to reset. Close the deck without saving. If you edited it while rehearsing: `git checkout -- presentation/Agentic_SDLC_Conference_Talk.pptx`.

---

## 6. Troubleshooting

| Issue | Fix |
|---|---|
| Slide 6 video does not play | Open the .pptx in PowerPoint instead of Keynote (or the reverse). If both fail, play the recording from the deck's media folder: `unzip -j presentation/Agentic_SDLC_Conference_Talk.pptx 'ppt/media/*.mp4' -d /tmp/talk` |
| Animations or fonts look different | The deck was exported from Keynote. Re-check every slide in the app you will present from before the day. |
| Notes missing in presenter view | They are in the README, section 4. |
| `setup.sh` says the deck is not a valid archive | The file was not fully checked out. `git checkout -- presentation/` |

---

## 7. Additional resources

| Resource | Link |
|---|---|
| Postman plugin skills | https://github.com/postmanlabs/postman-plugin/tree/main/skills |
| Postman Claude Code plugin | https://github.com/Postman-Devrel/postman-claude-code-plugin |
| Context Graph booth demo (same product, benchmark numbers) | [content/lightning-talks/context-graph](../context-graph/) |
