#!/bin/bash

version=3.4

# changelog
# 3.4
#   - date: 2025-12-31
#   - create ~/git/cron directory on first run.
# 3.3
#   - date: 2025-08-10
#   - update docs
# 3.2
#   - date: 2024-11-24
#   - create the routine when committing for the first time.
# 3.1
#   - date: 2023-03-03
#   - suppress output from diff command
#   - fix issue identifying macOS
# 3.0
#   - date: 2023-02-27
#   - introduce command line arguments
# 2.2
#   - date: 2023-02-14
#   - export PATH
# 2.1
#   - date: 2022-02-25
#   - minor tweaks

export PATH=~/bin:~/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# logging everything
[ -d ~/log ] || mkdir ~/log
log_file=~/log/cron-backup.log
exec > >(tee -a ${log_file})
exec 2> >(tee -a ${log_file} >&2)

# today=$(date +%F)
script_name=$(basename "$0")

echo; echo "Script: $script_name"
echo "Date & Time: $(date +%c)"

### ------------------------------ Check for OS ------------------------------ ###

if ! (type 'codename' 2>/dev/null | grep -q 'function')
then
    codename() {
        local codename=
        if [ "$(uname)" == "Linux" ]; then
            if command -v lsb_release >/dev/null ; then
                codename=$(lsb_release -cs)
            else
                codename=$(awk -F = '/VERSION_CODENAME/{print $2}' /etc/os-release)
            fi
        elif [ "$(uname)" == "Darwin" ]; then
            codename="macOS"
        else
            echo >&2 "Unknown OS"
        fi
        echo "$codename"
    }
    codename=$(codename)
fi

# echo "Codename: $codename"; exit

# variables used later
gitdir=
unique_file_name=
success_alert=
custom_email=
msg=
alertEmail=

print_help() {
    printf '%s\n\n' "Take a backup of user cron"

    printf 'Usage: %s [-d <git-dir>] [-e <email-address>] [-s] [-v] [-h] unique-file-name\n\n' "$script_name"

    printf '\t%s\t%s\n' "-d, --dir" "Name of the git dir where cron repo is stored. (default: ~/git/cron)"
    printf '\t%s\t%s\n' "-e, --email" "Email to send success/failures alerts (default: root@localhost)"
    printf '\t%s\t%s\n' "-s, --success" "Alert on successful execution too (default: alert only on failures)"
    printf '\t%s\t%s\n' "-v, --version" "Prints the version info"
    printf '\t%s\t%s\n' "-h, --help" "Prints help"

    printf "\nFor more info, changelog and documentation... https://git-codecommit.ap-south-1.amazonaws.com/v1/repos/cron\n\n"
}

# https://stackoverflow.com/a/62616466/1004587
# Convenience functions.
EOL=$(printf '\1\3\3\7')
opt=
usage_error () { echo >&2 "$(basename $0):  $1"; exit 2; }
assert_argument () { test "$1" != "$EOL" || usage_error "$2 requires an argument"; }

# One loop, nothing more.
if [ "$#" != 0 ]; then
  set -- "$@" "$EOL"
  while [ "$1" != "$EOL" ]; do
    opt="$1"; shift
    case "$opt" in

      # Your options go here.
      -v|--version) echo -e "Version: $version\n"; exit 0;;
      -V) echo -e "Version: $version\n"; exit 0;;
      -h|--help) print_help; exit 0;;
      -e|--email) assert_argument "$1" "$opt"; custom_email="$1"; shift;;
      -s|--success) success_alert=1;;
      -d|--dir) assert_argument "$1" "$opt"; gitdir="$1"; shift;;

      # Arguments processing. You may remove any unneeded line after the 1st.
      -|''|[!-]*) set -- "$@" "$opt";;                                          # positional argument, rotate to the end
      --*=*)      set -- "${opt%%=*}" "${opt#*=}" "$@";;                        # convert '--name=arg' to '--name' 'arg'
      -[!-]?*)    set -- $(echo "${opt#-}" | sed 's/\(.\)/ -\1/g') "$@";;       # convert '-abc' to '-a' '-b' '-c'
      --)         while [ "$1" != "$EOL" ]; do set -- "$@" "$1"; shift; done;;  # process remaining arguments as positional
      -*)         usage_error "unknown option: '$opt'";;                        # catch misspelled options
      *)          usage_error "this should NEVER happen ($opt)";;               # sanity test for previous patterns

    esac
  done
  shift  # $EOL
fi

# Do something cool with "$@"... \o/
if [ "$#" -gt 0 ]; then
    unique_file_name=$1
    shift
fi

# If there are still arguments, then it is an incorrect syntax
if [ "$#" -gt 0 ]; then
    print_help
    exit 1
fi

alertEmail=${custom_email:-${BACKUP_ADMIN_EMAIL:-${ADMIN_EMAIL:-"root@localhost"}}}

[ ! "$gitdir" ] && gitdir=~/git/cron

if [ ! -d "$gitdir" ]; then
    echo "Version: $version"
    printf "\nUsage: %s -d /path/to/git/repo [\$hostname-OS-\$USER]\n\n" "$script_name"
    exit 1
fi

if [ -z "$unique_file_name" ]
then
    unique_file_name=$(hostname)-$(codename)-$USER
    echo "Using auto-generated unique File Name: $unique_file_name"
fi

# echo "Cron User: $unique_file_name"; exit

# take a (temporary) backup of the existing cron
[ -d ~/tmp ] || mkdir ~/tmp
crontab -l > ~/tmp/crontab
current_cron=~/tmp/crontab

cd "$gitdir" || exit 1
echo "Pulling changes..."
if ! git pull --quiet; then
    msg="Error while pulling changes!"
    printf "\n%s\n\n" "$msg"
    echo "$msg" | mail -s 'Cron Backup Info' "$alertEmail"
fi

# first if: true only for a new OS.
# second if: true if there is any change in cron
# if [[ ! -f "$gitdir/$unique_file_name" || ! diff "$current_cron" "$gitdir/$unique_file_name" >/dev/null ]]; then
# if ! diff "$current_cron" "$gitdir/$unique_file_name" >/dev/null ; then
if [ ! -f "$gitdir/$unique_file_name" ] ; then
    cp "$current_cron" "$gitdir/$unique_file_name"
    git add .
    if git commit -m "Auto commit for $unique_file_name by $0" --quiet ; then
        echo "Pushing changes..."
        if git push --quiet >/dev/null; then
            msg="Successfully pushed changes!"
            [ "$success_alert" ] && echo "$msg" | mail -s 'Cron Backup Info' "$alertEmail"
        else
            msg="Error while pushing changes!"
            echo "$msg" | mail -s 'Cron Backup Info' "$alertEmail"
        fi
        printf "\n%s\n\n" "$msg"
    fi
else
    if ! diff "$current_cron" "$gitdir/$unique_file_name" >/dev/null ; then
        cp "$current_cron" "$gitdir/$unique_file_name"
        git add .
        if git commit -m "Auto commit for $unique_file_name by $0" --quiet ; then
            echo "Pushing changes..."
            if git push --quiet >/dev/null; then
                msg="Successfully pushed changes!"
                [ "$success_alert" ] && echo "$msg" | mail -s 'Cron Backup Info' "$alertEmail"
            else
                msg="Error while pushing changes!"
                echo "$msg" | mail -s 'Cron Backup Info' "$alertEmail"
            fi
            printf "\n%s\n\n" "$msg"
        fi
    else
        echo "No local changes since last backup!"
    fi
fi

# remove the temporary file
rm $current_cron

printf "All done.\n\n"
