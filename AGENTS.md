# SILAM agent instructions

These rules apply to this project and its agents. Follow the user's current
instructions when they differ from these rules.

## Documentation and communication

- Use Simplified Chinese for user-facing explanations unless another language
  is requested. Give the result first. Keep terms and sentences clear.
- This file defines execution rules. `README.md` gives project, build, and run
  entry points. `doc/dev/` contains the detailed development guides.
- Keep long-term technical conclusions in the relevant development guide.
  Do not create task logs or MEMORY files. Do not require log IDs or commit
  trailers. Use Git history to trace changes.
- Inspect current code, configuration, and relevant documents before asking
  factual questions. Separate verified facts, interpretations, and uncertainty.
- Use the task's authoritative sources. If documents, code, or results conflict,
  report the mismatch. Ask before changing an agreed scientific interpretation.

## Decisions and scope

- Carry out clear, local, reversible work within the user's authorized scope.
  Analysis, review, and discussion requests remain read-only until the user
  authorizes implementation. Respect explicit run and checkpoint boundaries.
- Ask only about unresolved choices that materially affect the objective,
  scope, architecture, interfaces, data definitions, or execution cost. Group
  independent questions and give a recommendation with its main trade-off.
- Do not repeat settled questions. If a material premise changes, explain it
  and ask only about the changed decision.
- Make the smallest clear change that meets the request. Reuse existing code
  and tools. Preserve behavior and interfaces outside the agreed scope.
- Preserve unrelated working-tree changes and user data. Include only the
  intended changes in a commit.

## Branches and Git approval

- Develop on `main` by default. Keep the primary working tree on `main`.
- Before editing, inspect the impact and verification needs. A small task has
  one clear goal, a bounded change, stable shared interfaces and module roles,
  and checks that fit the existing verification process. A local change with
  its matching tests can still be small.
- For a larger task, ask whether to create a branch and use a worktree before
  the first edit. Explain the scope, the reason for isolation, and the proposed
  branch and path. Ask when any of these conditions applies:
  - A complete plan has several implementation stages or acceptance goals.
  - Several functional modules need coordinated changes to interfaces, shared
    data, or call flow.
  - Module roles, public interfaces, data formats, toolchains, or dependencies
    change.
  - Scientific formulas, units, key numerical methods, precision, or parallel
    computation behavior change.
  - Verification expands substantially, or test acceptance criteria or numeric
    reference results change.
- File and line counts are supporting information. They do not decide task
  size on their own. Inspect an unclear scope before asking the user.
- Create a branch or worktree only when the user requests it or agrees to the
  proposed isolation. If the user chooses `main`, continue there for the agreed
  task. Ask again only if the scope changes materially.
- Agents may decide when to make local commits. No fixed commit count is
  required for a task.
- After isolated work is complete, report its changes, checks, and limits.
  Wait for the user's explicit approval before merging it into `main`.
- A push always requires the user's explicit approval. Approval to create a
  branch, create a worktree, or commit does not authorize a merge or push.

## Worktrees

- Put worktrees under `.worktree/<task-or-branch-name>/` in the project root.
  Keep `/.worktree/` ignored by the primary working tree.
- Use a separate worktree for each independent task that needs isolation.
  Agents on the same task can share one worktree with separate file ownership.
- Base new task branches on committed `main` unless the user specifies another
  base. An existing branch keeps its history when attached to a worktree.
- Uncommitted, untracked, and ignored files do not transfer to a new worktree.
  Check its local build configuration before compiling.
- Keep build configuration, generated files, executables, object files, and
  run outputs local to that worktree. If `TMPDIR` is set, point it to that
  worktree's task temporary directory. Do not share writable build outputs.
- The main agent coordinates Git writes and integration. Keep the worktree
  while its completed changes await merge approval.
- After integration, check modified, untracked, and ignored files for work or
  results that must be kept. Preserve deliverables before cleanup. Remove a
  completed worktree with `git worktree remove`, then delete its merged task
  branch. Do not force removal or discard unmerged work without authorization.

## Implementation

- Keep SILAM's existing `source/`, `build/`, `kpp/`, and `ini/` structure and
  build system. Read the relevant guides in `doc/dev/` before changing them.
- Do not define custom classes or return their instances from functions.
- Treat parameter values supplied directly by the user as valid. Do not add
  validation for them. When changing the affected code, remove that validation
  and tests that only check it. Preserve other required behavior and checks.
- Prefer simple logic, then fewer modules, functions, branches, and parameters.
  Reduce line count last. Do not join unrelated statements to shorten code.
- Do not add Pydantic or a new CLI unless the user requests it. Avoid unneeded
  features, abstractions, dependencies, and configuration.
- Load the local `r-for-data-science` skill before writing or changing R code
  when it is available. Use other applicable language skills as required.

## Verification and environment

- Match checks to the changed behavior and risk. Use relevant existing checks.
  Add or change tests when needed to verify behavior. Keep costly experiments
  and output regeneration within the authorized scope.
- Distinguish environment checks, compilation, case execution, and numerical
  regression. Each result applies only to what that check establishes.
- For numerical regression, define the inputs, reference outputs, variables,
  units, metrics, and tolerances. Record the relevant code version, build
  configuration, and runtime settings with the result.
- Report failures and skipped or unavailable checks as such. A check that was
  not completed is NOT VERIFIED. Do not present case execution or file creation
  as proof of numerical agreement.
- Record relevant compiler, dependency, and build-option changes in the build
  documentation and configuration. Keep the existing Make and platform
  workflows. A container is required only if the user adopts that workflow.
- After checks pass, repeat or broaden them only when a change, failure, or
  unresolved concern requires it.

## Temporary files

- Use the active working-tree root. Create one task directory under
  `.tmp/<task-name>-<YYYYMMDD-HHMMSS>/` only when temporary files are needed.
  Add a suffix if that name exists.
- Put temporary scripts, logs, downloads, caches, and intermediate results in
  that directory. Configure tools to use it when supported. Do not commit it.
- Keep maintained tests, deliverables, and user data in their required project
  locations. Move required results out before deleting the task directory.
- At completion, confirm the full temporary path is inside this working tree's
  `.tmp/`. Delete only this task's directory and confirm it no longer exists.
  Keep `.tmp/` itself and other tasks' content. Report any cleanup that failed.
- Keep `/.tmp/` ignored in the working tree.

## Subagents and delivery

- Delegate when useful. Give each agent one bounded objective and a clear
  output. Use ASD-STE100 Simplified Technical English for subagent instructions
  and reports. Run independent work in parallel and dependent work in order.
- The main agent owns scope, architecture, interfaces, integration, and final
  checks. For substantial parallel work, define boundaries, data flow, and
  acceptance criteria before delegation. Add interface scaffolding only when
  coordination needs it. Do not assign concurrent edits to the same file.
- Scale exploration, execution, and independent review to the task. Small
  local changes do not require a full agent team. Resolve review findings and
  verify the fixes.
- Check that deliverables exist. Report what changed, what was verified,
  material unverified limits, and any remaining cleanup items.
