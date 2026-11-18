# Global rules for coding agents

<!--
Shared by the coding agents on this machine: ~/.claude/CLAUDE.md imports it,
and ~/.codex/AGENTS.md is generated from it by chezmoi. The source is
home/dot_config/agents/AGENTS.md in the dotfiles repository.
-->

## Git commits

- Never add a `Co-Authored-By` trailer to commit messages.
- Write all commit messages and code comments in English, regardless of the language used in conversation.

## Pull requests and issues

- Write PR titles, PR descriptions, issue titles, issue bodies, and review/issue comments in English, regardless of the language used in conversation.
- Chat replies stay in the language of the conversation; only the text published to the repository is English.

## Disk space and cleanup

- Before reporting that the user's request is finished, remove the throwaway
  files the work created, so they do not pile up on disk. "Finished" means the
  whole request, not each turn of an ongoing edit-build-test loop. Subagents
  leave cleanup to the main session.
- Remove only what you created in this session and what is not part of the
  result:
  - temporary build directories, and build outputs of one-off checks (for
    example a Rust `target/` you created from scratch just to try something:
    `cargo clean`);
  - debug logs, dumps and scratch files, unless the report points to them;
  - Docker containers you started, and images you built, for a one-off check.
- Never delete without asking: anything the user asked for (built binaries,
  generated files), anything that existed before the task (including a
  project's existing `target/` or `node_modules`), shared caches (`~/.cargo`,
  `~/.npm`, the Go module cache, `~/Library/Caches`), Docker volumes, and
  Docker images other projects may use. If such files are large, mention
  their size instead.
- When the work produced large files, or disk space looks low, check with
  `df -h` and report it if free space is below about 10%.
- In the final report, list what you removed and roughly how much space it
  freed.
