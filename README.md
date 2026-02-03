# Cron backups

Automate backup of cron jobs to a private repo.

## Compatibility

- macOS (Tahoe)
- GNU/Linux

## Requirements:

- a private repo.
- full access to the repo via SSH keys.
- a cron entry to backup cron!

### Sample cron entry

```
@hourly sleep ${RANDOM:0:1} && ~/git/cron/backup.bash &>/dev/null
```

### Roadmap

- backup script based on zsh
- backup script based on fish
