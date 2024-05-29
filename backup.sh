#!/bin/bash

source /usr/local/bin/env.sh

send_telegram_message() {
    local message=$1
    local bot_token="$TG_BOT_TOKEN"
    local chat_id="$TG_CHAT_ID"
    
    curl -s -X POST https://api.telegram.org/bot$bot_token/sendMessage \
      -d chat_id=$chat_id \
      -d text="[$APP_NAME] $message"
}


# Current date
DATE=$(date +%Y_%m_%d_%H_%M_%S)

# Backup directory
BACKUP_FILE="$BACKUP_DIR/$APP_NAME/backup_$DATE.tar.gz"

# Temporary files
SCHEMA_FILE="$BACKUP_DIR/$APP_NAME/tmp/schema_$DATE.sql"
DATA_FILE="$BACKUP_DIR/$APP_NAME/tmp/data_$DATE.sql"

# Log file
LOG_FILE="$BACKUP_DIR/$APP_NAME/logs/backup_$DATE.log"

# Start logging
echo "[$(date +%Y-%m-%d_%H:%M:%S)] Starting backup at $DATE"| tee -a $LOG_FILE
send_telegram_message "Starting backup at $DATE"

# Export MySQL password
export MYSQL_PWD="$MYSQL_PASSWORD"

# Dump the schema
echo "[$(date +%Y-%m-%d_%H:%M:%S)] Dumping schema for $MYSQL_DATABASE on $MYSQL_HOST ..." | tee -a $LOG_FILE
mysqldump -u$MYSQL_USER -h$MYSQL_HOST --no-data $MYSQL_DATABASE > $SCHEMA_FILE
if [ $? -eq 0 ]; then
    echo "Schema dump completed successfully." | tee -a $LOG_FILE
else
    echo "[$(date +%Y-%m-%d_%H:%M:%S)] Schema dump failed." | tee -a $LOG_FILE
    send_telegram_message "Schema dump failed."
    exit 1
fi

# Dump the data
echo "[$(date +%Y-%m-%d_%H:%M:%S)] Dumping data..." | tee -a $LOG_FILE
mysqldump -u$MYSQL_USER -h$MYSQL_HOST --no-create-info $MYSQL_DATABASE > $DATA_FILE
if [ $? -eq 0 ]; then
    echo "Data dump completed successfully." | tee -a $LOG_FILE
else
    echo "[$(date +%Y-%m-%d_%H:%M:%S)] Data dump failed." | tee -a $LOG_FILE
    send_telegram_message "Data dump failed."
    exit 1
fi

# Archive the dumps
echo "[$(date +%Y-%m-%d_%H:%M:%S)] Archiving dumps..." | tee -a $LOG_FILE
tar -czvf $BACKUP_FILE -C $BACKUP_DIR/$APP_NAME/tmp/ $(basename $SCHEMA_FILE) $(basename $DATA_FILE)
if [ $? -eq 0 ]; then
    echo "[$(date +%Y-%m-%d_%H:%M:%S)] Archive created successfully." | tee -a $LOG_FILE
else
    echo "[$(date +%Y-%m-%d_%H:%M:%S)] Failed to create archive." | tee -a $LOG_FILE
    send_telegram_message "Failed to create archive."
fi

# Clean up temporary files
echo "[$(date +%Y-%m-%d_%H:%M:%S)] Cleaning up temporary files..." | tee -a $LOG_FILE
ls -l 
rm -rf $BACKUP_DIR/$APP_NAME/tmp/*.sql
if [ $? -eq 0 ]; then
    echo "[$(date +%Y-%m-%d_%H:%M:%S)] Temporary files removed successfully." | tee -a $LOG_FILE
else
    echo "[$(date +%Y-%m-%d_%H:%M:%S)] Failed to remove temporary files." | tee -a $LOG_FILE
    send_telegram_message "Failed to remove temporary files."
fi

echo "[$(date +%Y-%m-%d_%H:%M:%S)] Backup completed" | tee -a $LOG_FILE

send_telegram_message "Backup completed successfully!"