# Global preferences

## Git commits

- Never add a `Co-Authored-By` trailer to commit messages.
- Write all commit messages and code comments in English, regardless of the language used in conversation.

## Pull requests and issues

- Write PR titles, PR descriptions, issue titles, issue bodies, and review/issue comments in English, regardless of the language used in conversation.
- Chat replies stay in the language of the conversation; only the text published to the repository is English.

## Disk space and cleanup

- When a task is done, check free disk space (`df -h` on the volumes you
  used) and remove what you created during the task and no longer need,
  before reporting back:
  - build artifacts you produced that can be regenerated (for example
    `cargo clean` for a Rust `target/` you built, temporary build directories),
  - debug logs, dumps and scratch files you wrote,
  - Docker images, containers and volumes you created for the task.
- Delete only what you created in this session, or caches that are clearly
  regenerable. Ask before deleting anything else: user data, build outputs
  that existed before the task, Docker volumes that may hold data.
- In the final report, say what you removed and roughly how much space it
  freed. If free space is low for other reasons, report it instead of
  deleting.
