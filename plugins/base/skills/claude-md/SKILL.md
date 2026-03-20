---
name: claude-md
description: Writes, improves, or restructures CLAUDE.md project memory files. Use when the user asks to create, update, enrich, or fix CLAUDE.md, add project context, improve project understanding, or replace /init or /memory with a better result.
---

# CLAUDE.md writer

Write CLAUDE.md files that help Claude understand a project and work effectively in it.

Prioritize business context, repository structure, conventions, and sensitive areas. Keep technical stack details secondary and relevant.

## Use this skill for

Use this skill when the user wants to:

- Create a new `CLAUDE.md`.
- Improve or clean up an existing `CLAUDE.md`.
- Add project knowledge to `CLAUDE.md`.
- Replace or refine output that would otherwise come from `/init` or `/memory`.
- Create multiple `CLAUDE.md` files for a large repo or monorepo.

Do not use this skill for:

- Auto-memory files such as `MEMORY.md`.
- Generic documentation edits unrelated to `CLAUDE.md`.

## Principles

### Business before technology

Start with what the project does, who uses it, and the important workflows.

Do not use the tech stack as the project overview.

Bad:
```md
This is a Next.js 15 app built with React 19 and Tailwind CSS.
```

Better:

```md
This project is a platform for X to manage Y and perform Z. Main users are A and B.
```

### Ask when the code cannot tell you

Code can reveal structure and implementation. It rarely reveals domain intent, user roles, hidden conventions, or operational constraints.

When that information is missing or uncertain, ask the user. Do not guess.

Ask the fewest questions needed to produce a high-quality `CLAUDE.md`. Prefer targeted follow-up questions over broad questionnaires.

### Keep it concise and useful

Every section must help Claude work better.

Remove filler, avoid repetition, and prefer concrete instructions over generic statements.

Target concise files. If a file becomes too broad, split it.

Use concise prose for context and architecture. Use short lists only when they improve scannability, such as commands, sensitive areas, or conventions.

If the draft becomes too large to stay clear and maintainable, propose splitting it into a root `CLAUDE.md`, subproject `CLAUDE.md` files, or targeted `.claude/rules/` files before finalizing.

### Fit the repository shape

Do not force one `CLAUDE.md` for every project.

A small repo may need one file.
A large repo may need one root file plus subproject files.

### Complement existing docs

Reuse existing documentation where it helps.

Prefer references such as `@README.md` over copying large blocks of content.

Do not copy setup, installation, or workflow sections from existing docs unless summarizing them adds clear value.

## Workflow

### 1. Inspect the repository

Review the repository structure and identify:

* Build files such as `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`.
* Major directories such as `apps/`, `packages/`, `client/`, `server/`, `services/`, `libs/`.
* Existing `CLAUDE.md`, `README.md`, and `.claude/rules/` files.
* Test setup, CI/CD files, container files, and environment-related docs.

Determine:

* Single app, library, monorepo, or multi-stack repo.
* Whether there is already a `CLAUDE.md`.
* Whether distinct subprojects need separate files.

If a subdirectory has its own build file, commands, and conventions, treat it as a separate subproject candidate.

### 2. Decide the file strategy

Choose the smallest structure that matches the repo.

Typical patterns:

**Single app or library**

```text
CLAUDE.md
```

**Monorepo or multi-stack repo**

```text
CLAUDE.md
client/CLAUDE.md
server/CLAUDE.md
```

Use separate `CLAUDE.md` files when a directory has its own build system or clearly separate conventions.

Do not mix unrelated stacks in one file. For example, frontend commands and backend conventions should not be merged into the same local project memory file when they belong to different subprojects.

Ensure the scope of each file is internally consistent. A local `CLAUDE.md` should describe only the subproject it belongs to, not the entire repository.

Before drafting, state the proposed file strategy briefly.

### 3. Gather missing context

Before writing, ask only for the information that cannot be inferred reliably.

Use this decision rule:

* If the essential business context is already clear from the repository, existing docs, or prior user messages, draft directly and mark any assumptions explicitly.
* If the essential business context is missing or uncertain, ask targeted questions first, then draft after the answers.

Essential questions when unknown:

* What does the project do in business terms?
* Who are the main users?
* What are the critical workflows or features?

Useful follow-up questions when relevant:

* Which parts of the codebase are sensitive or easy to break?
* Are there important conventions not obvious from the code?
* What should Claude avoid doing in this project?
* Are there important external systems or integrations?

Do not dump unnecessary questions. Ask the minimum needed to produce a good result.

If some context appears inferable, state the inference briefly and ask the user to confirm or correct it.

### 4. Draft the file

Use only sections that add value.

Suggested structure:

```md
# Project name

Short business-first summary.

## Business context
What the project does, who uses it, the core workflows, and the important business rules.

## Architecture
Main parts of the system, how they interact, and important external integrations.

## Development
Run, build, and test commands, plus setup notes if needed.

## Conventions
Naming or structure rules that matter, plus project-specific workflow expectations.

## Sensitive areas
Risky files, directories, flows, operations, and known pitfalls.
```

Writing rules:

* Prefer logical structure to file tree dumps.
* Do not restate the same fact in multiple sections.
* Keep stack details brief and relevant.
* Use `@path` imports when existing docs already explain something well.
* In subproject files, include only local context. Shared context belongs in the root file.

### 5. Review before saving

Before writing to disk:

* Show the draft or summarize the proposed changes.
* For updates, clearly highlight what will change in the existing file.
* Point out any assumptions.
* Flag missing information that would materially improve the file.
* Suggest `.claude/rules/` only when path-specific rules would clearly help.

Then apply the approved changes.

## Updating an existing CLAUDE.md

When improving an existing file:

1. Read it fully.
2. Identify the real issues such as repetition, weak overview, missing business context, mixed scopes, or stale sections.
3. Preserve good content.
4. Propose the specific changes before applying them. Summarize what will be removed, rewritten, moved, or added.
5. Ask about uncertain sections before finalizing.
6. After approval, apply the changes.

## Quality checks

Before finalizing, verify that the result:

* Explains the project before listing tools and frameworks.
* Matches the actual repository structure.
* Does not mix separate subproject scopes.
* Avoids repetition.
* Uses concrete, project-specific guidance.
* Avoids unsupported assumptions.
* Stays concise enough to remain useful.

## Anti-patterns

Avoid:

* Tech stack presented as business overview.
* Large file tree dumps.
* Repeated commands or duplicated sections.
* Generic filler.
* Guessing domain context.
* Oversized all-in-one files for large repos.
* Mixing frontend and backend local instructions in one subproject file.
* Drafting before collecting missing business context.

## Example

Bad:

```md
## Project Overview

This is a Next.js 15 application built with React 19, TypeScript, and Tailwind CSS.
```

Better:

```md
## Project overview

This platform helps restaurant owners manage menus, track orders, and monitor daily sales.
Main users are restaurant staff and delivery partners.

## Architecture
- Next.js frontend.
- Backend API.
- Authentication provider.
- Core flows: menu updates, order tracking, sales reporting.
```
