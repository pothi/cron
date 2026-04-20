#!/usr/bin/env fish

set ver 1.1

# variables
set backup_location ~/.config/cron/
set backup_file latest

set log_file ~/log/(status basename | awk -F. '{print $1}').log

set tmp_cron_file $(mktemp)
trap 'rm "$tmp_cron_file"' EXIT INT TERM

echo "Timestamp: $(date +%c)"

#: Main func {{{
function local-cron-backup --description 'Take a backup of crontab upon changes'
    argparse 'v/version' 'h/help' -- $argv
    # or return

    if set -ql _flag_v
        echo Version: $ver
        return 0
    end

    if set -ql _flag_h
        __print_help
        return 0
    end

    __backup_cron_locally
end
#: }}}

function __backup_cron_locally
    test -d $backup_location; or mkdir -p $backup_location
    test -d {$backup_location}archive; or mkdir -p {$backup_location}archive
    # exit if no crontab
    crontab -l &>/dev/null
    if test $status -ne 0
        echo No cron entries.
        return
    end

    # this is run only once, when taking first cron backup.
    if not test -f $backup_location$backup_file
        crontab -l > $backup_location$backup_file
        cp $backup_location$backup_file {$backup_location}archive/$(date +%F)
        echo Taking cron backup for the first time.
        echo Latest backup is available at $backup_location$backup_file
        echo Datewise backups are available at {$backup_location}archive
        return
    end

    crontab -l > $tmp_cron_file

    # check for changes and take a backup.
    diff $tmp_cron_file $backup_location$backup_file &>/dev/null
    if test $status -eq 0
        echo No changes since last backup.
    else
        cp $tmp_cron_file $backup_location$backup_file
        cp $tmp_cron_file {$backup_location}archive/$(date +%F)
        echo Latest backup is available at $backup_location$backup_file
        echo Datewise backups are available at {$backup_location}archive
    end

    echo
end

#: print_help {{{
function __print_help
    printf '%s\n\n' "Take a backup of user cron"

    printf 'Usage: %s [-v] [-h]\n\n' (status basename)

    printf '\t%s\t%s\n' "-v, --version" "Prints the version info"
    printf '\t%s\t%s\n' "-h, --help" "Prints help"

    echo; echo Invoking without any arguments will take a backup of cron into $backup_location$backup_file

    printf "\nFor more info, changelog and documentation... https://github.com/pothi/cron\n"
end
#: }}}

local-cron-backup $argv 2>&1 | tee -a $log_file

# vim:fileencoding=utf-8:foldmethod=marker
