# Cron backups

Automate backup of cron jobs to a private repo or just backup locally.

## For local backups

Just execute local-backup.fish via cron schedule.

```
# take a backup at the end of the day.
59 23 * * * ~/git/cron/local-backup.fish >/dev/null
```

## For backup via version control using a private repo

### Compatibility

- macOS (Tahoe)
- GNU/Linux

### Requirements:

- a private repo.
- full access to the repo via SSH keys.

### How it works

- fork this repo into a **private** repo.
- clone it into your machine / server.
- run backup.bash script manually.
- if no errors occurred, run it regularly via cron. See sample below.

#### Sample cron entry

```
@hourly sleep ${RANDOM:0:1} && ~/git/cron-private/backup.bash &>/dev/null
```

### Roadmap

- backup script based on zsh
- backup script based on fish
