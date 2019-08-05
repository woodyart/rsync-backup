#!/bin/bash
# The script transfer local dir to remote host

function help() {
  echo "
Use script with next options:

OPTIONS
  -s or --backupdir </path/to/source/dir>
          Specify absolute path to source directory

  -h or --host <hostname>
          Hostname or IP of remote server. Add ':<port>' if remote ssh port
          different than 22, or use ssh config to keep information about host.

  -u or --user <username>
          Username of the remote server

  -s or --sshkey </path/to/private/ssh_key>
          Path to ssh private key

  -d or --destdir </path/to/save/backup>
          Path on the remote server to

  -k or --keepdays <num_days>
          Number of days to store backups on the remote server

EXAPMLE
  $0 -s /var/backup -u rembak -h mybackup.local -s /home/joe/.ssh/id_rsa -d /var/backups/myserver -k 30

  $0 -s /var/backup -h backupserver -d /var/backups/myserver -k 30"
}

if [[ "$#" -eq 0 ]]; then
  echo "ERROR
  Parameters not set"; help
  exit 1
fi

while [[ "$#" -gt 0 ]]; do case $1 in
  -s|--backupdir) BACKUP_DIR="$2"; shift;;
  -u|--user)      REMOTE_USER="$2"; shift;;
  -h|--host)      REMOTE_HOST="$2"; shift;;
  -s|--sshkey)    REMOTE_KEY="$2"; shift;;
  -d|--destdir)   REMOTE_DIR="$2"; shift;;
  -k|--keepdays)  REMOTE_KEEP_DAYS="$2"; shift;;
  *) echo "ERROR
  Unknown parameter passed: $1"; help; exit 1;;
esac; shift; done

if [[ -z $BACKUP_DIR || -z $REMOTE_HOST || -z $REMOTE_DIR || -z $REMOTE_KEEP_DAYS ]]; then
  echo "ERROR
  Parameters not set completely"; help
  exit 1
fi

# Copy files to remote host
rsync -avz -e \
  "ssh -i "$REMOTE_KEY" "$SSH_OPT"" \
  "$BACKUP_DIR"/ \
  "$REMOTE_USER@$REMOTE_HOST":"$REMOTE_DIR"
[ $? != 0 ] && logger -s "$0 - rsync job failed"

# Remove old files on remote host
ssh -i "$REMOTE_KEY" "$SSH_OPT" \
  "$REMOTE_USER@$REMOTE_HOST" \
  'find "$REMOTE_DIR" -type -f -mtime +"$REMOTE_KEEP_DAYS" -delete'
[ $? != 0 ] && logger -s "$0 - failed remove old files on $REMOTE_HOST"
