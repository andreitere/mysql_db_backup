#!/bin/bash

cat <<EOL > /usr/local/bin/env.sh
TG_BOT_TOKEN="$TG_BOT_TOKEN"
TG_CHAT_ID="$TG_CHAT_ID"
MYSQL_USER="$MYSQL_USER"
MYSQL_PASSWORD="$MYSQLSWORD"
MYSQL_DB="$MYSQLES_DB"
MYSQL_HOST="$MYSQL_HOST"
BACKUP_DIR="$BACKUP_DIR"
APP_NAME="$APP_NAME"
CRON_SCHEDULE="$CRON_SCHEDULE"
EOL

echo "Setting up cron job with schedule: $CRON_SCHEDULE"

# Create a cron job file
echo "$CRON_SCHEDULE /usr/local/bin/backup.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/backup-cron

# Give execution rights on the cron job
chmod 0644 /etc/cron.d/backup-cron

# Apply cron job
crontab /etc/cron.d/backup-cron

# Start cron and tail log file
cron && tail -f /var/log/cron.log
