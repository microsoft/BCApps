---
name: prd-design
description: Generate a design document (PRD) through guided questions with deep codebase research
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(*)
argument-hint: "feature description"
---

# Rule: Generating a Design Document

> **Usage**: Invoke this skill to create a PRD. Performs deep codebase research, asks clarifying questions, then generates the document.

## Prerequisites

**MANDATORY PRE-FLIGHT - STOP and complete ALL steps before proceeding:**

- [ ] Read `.github/copilot/project-config.md` for feature toggles (ADO, GitHub Projects)
- [ ] Enter plan mode
- [ ] Read ALL key source files relevant to the feature being designed (not just directory listings)
- [ ] Write a visible "Codebase findings" summary (see Process step 2) before asking any questions

**If any step is skipped, the design output will be rejected.**

Feature toggles affect:

- **Azure DevOps Integration**: If ON, PRD may reference ADO work items
- **GitHub Projects**: If ON, PRD may reference GitHub issues

## Goal

Guide the creation of a detailed design document in Markdown format, based on an initial user prompt. The design document should combine product requirements with architectural decisions, and be clear, actionable, and suitable for a junior developer to understand and implement the feature.

## Process

1. **Receive Initial Prompt:** The user provides a brief description or request for a new feature or functionality.
2. **Deep Codebase Research (if existing codebase):** If an existing codebase is present, perform deep research to understand it before designing. Skip this step only if the feature is for a greenfield project with no existing code. **Do NOT rely on memory from earlier in the conversation - read the actual files.**

    **Run the following research tasks in parallel using the Task tool (or parallel tool calls):**

    - **Existing documentation** - Read project documentation following `.github/copilot/documentation-organization.md` structure: `/docs/architecture.md`, `/docs/features.md`, component-level docs (`/backend/docs/`, `/frontend/docs/`), and memory-bank files (`.github/memory-bank/`) if present. This provides high-level context before diving into code.
    - **Architecture & project structure** - Map out the top-level directory structure, key entry points, and how the project is organized (e.g., monorepo, layered, modular).
    - **Technology stack & dependencies** - Identify frameworks, libraries, languages, and build tools in use (e.g., package.json, requirements.txt, .csproj, Dockerfile).
    - **Existing patterns & conventions** - Read actual source files (not just directory listings) to find coding patterns, naming conventions, component structure, and architectural patterns already established.
    - **Domain model & data layer** - Understand the core domain models, database schemas, API contracts, and data flow by reading schema and route files directly.
    - **Related features & integration points** - Read the files of existing features or modules that the new feature will interact with, extend, or depend on.

    **After research completes**, you MUST write a visible "Codebase findings" summary to the user BEFORE asking any clarifying questions. This summary must cover:

    - Key files read and what was learned from each
    - Key architectural decisions already made
    - Patterns the new feature should follow for consistency
    - Integration points and constraints the design must account for
    - Any technical debt or limitations that may affect the design

    **If you ask clarifying questions without first showing this summary, the output will be rejected.**

3. **Ask Clarifying Questions:** After posting the codebase findings summary, ask clarifying questions to gather sufficient detail. The goal is to understand the "what" and "why" of the feature, not necessarily the "how" (which the developer will figure out). Questions must be informed by the codebase research - reference specific files, components, or patterns discovered during research rather than asking generic questions.
4. **Generate Design Document:** Based on the initial prompt, codebase research findings, and the user's answers to the clarifying questions, draft the design document content in the plan file using the structure outlined below.
5. **Exit Plan Mode and Save:** Once the design content is finalized in the plan file, exit plan mode. After exiting, write the design document as `design.md` inside the `/docs/features/[feature-name]/` directory. Create the feature directory if it doesn't exist. **You MUST exit plan mode before writing the file -- plan mode is read-only.**

## Clarifying Questions (Examples)

The AI should adapt its questions based on the prompt, but here are some common areas to explore:

- **Problem/Goal:** "What problem does this feature solve for the user?" or "What is the main goal we want to achieve with this feature?"
- **Target User:** "Who is the primary user of this feature?"
- **Core Functionality:** "Can you describe the key actions a user should be able to perform with this feature?"
- **User Stories:** "Could you provide a few user stories? (e.g., As a [type of user], I want to [perform an action] so that [benefit].)"
- **Acceptance Criteria:** "How will we know when this feature is successfully implemented? What are the key success criteria?"
- **Scope/Boundaries:** "Are there any specific things this feature *should not* do (non-goals)?"
- **Data Requirements:** "What kind of data does this feature need to display or manipulate?"
- **Design/UI:** "Are there any existing design mockups or UI guidelines to follow?" or "Can you describe the desired look and feel?"
- **Edge Cases:** "Are there any potential edge cases or error conditions we should consider?"

## Design Document Structure

The generated design document should include the following sections:

1. **Introduction/Overview:** Briefly describe the feature and the problem it solves. State the goal.
2. **Goals:** List the specific, measurable objectives for this feature.
3. **User Stories:** Detail the user narratives describing feature usage and benefits.
4. **Functional Requirements:** List the specific functionalities the feature must have. Use clear, concise language (e.g., "The system must allow users to upload a profile picture."). Number these requirements.
5. **Non-Goals (Out of Scope):** Clearly state what this feature will *not* include to manage scope.
6. **Design Considerations (Optional):** Link to mockups, describe UI/UX requirements, or mention relevant components/styles if applicable.
7. **Technical Considerations (Optional):** Mention any known technical constraints, dependencies, or suggestions (e.g., "Should integrate with the existing Auth module").
8. **Success Metrics:** How will the success of this feature be measured? (e.g., "Increase user engagement by 10%", "Reduce support tickets related to X").
9. **Open Questions:** List any remaining questions or areas needing further clarification.

## Target Audience

Assume the primary reader of the design document is a **junior developer**. Therefore, requirements should be explicit, unambiguous, and avoid jargon where possible. Provide enough detail for them to understand the feature's purpose and core logic.

**Interaction Style:** Ask clarifying questions one at a time, then move to the next. Refine the design document based on user feedback.

## Output

- **Format:** Markdown (`.md`)
- **Location:** `/docs/features/[feature-name]/`
- **Filename:** `design.md`

**Note:** Per `.github/copilot/task-workflow.md`, this design.md file must be updated during implementation when architecture decisions are made. Add "Last Updated" timestamps to modified sections.

## Final Instructions

1. Do NOT start implementing the PRD
2. Complete the mandatory pre-flight checklist at the top of this file
3. If an existing codebase is present, read key source files directly (not just listings) and post a visible codebase findings summary
4. Ask clarifying questions - they must reference specific files/components found during research
5. Draft the PRD content in the plan file based on answers
6. Refine based on user feedback
7. Exit plan mode (ExitPlanMode) once the design is approved
8. **After exiting plan mode**, write the design.md file to `/docs/features/[feature-name]/design.md`

## Next Step

Once the PRD is complete, use `/prd tasks` (or read `plugins/workflow/skills/prd/prd-tasks.md`) to create the implementation task list.
