# Cron backups

Automate backup of cron jobs to a private repo.

## Compatibility

- macOS (Tahoe)
- GNU/Linux

## Requirements:

- a private repo.
- full access to the repo via SSH keys.
- a cron entry to backup cron!

## How it works

- fork this repo into a private repo.
- clone it into your machine / server.
- run backup.bash script manually.
- if no errors occurred, run it regularly via cron. See sample below.

### Sample cron entry

```
@hourly sleep ${RANDOM:0:1} && ~/git/cron/backup.bash &>/dev/null
```

### Roadmap

- backup script based on zsh
- backup script based on fish
