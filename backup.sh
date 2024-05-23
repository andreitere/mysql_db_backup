#!/bin/bash

send_telegram_message() {
    local message=$1
    local bot_token="$TG_BOT_TOKEN"
    local chat_id="$TG_CHAT_ID"
    
    curl -s -X POST https://api.telegram.org/bot$bot_token/sendMessage \
      -d chat_id=$chat_id \
      -d text="$message"
}

# Current date
DATE=$(date +%Y%m%d%H%M%S)

# Backup directory
BACKUP_FILE="$BACKUP_DIR/$APP_NAME/backup_$DATE.tar.gz"

# Temporary files
SCHEMA_FILE="$BACKUP_DIR/tmp/schema_$DATE.sql"
DATA_FILE="$BACKUP_DIR/tmp/data_$DATE.sql"

# Log file
LOG_FILE="$BACKUP_DIR/backup_$DATE.log"

# Start logging
echo "Starting backup at $DATE" >> $LOG_FILE
send_telegram_message "Starting backup at $DATE"
# Export MySQL password
export MYSQL_PWD=$MYSQL_PASSWORD

# Dump the schema
echo "Dumping schema..." >> $LOG_FILE
mysqldump -u$MYSQL_USER -h$MYSQL_HOST --no-data $MYSQL_DATABASE > $SCHEMA_FILE 2>> $LOG_FILE
if [ $? -eq 0 ]; then
    echo "Schema dump completed successfully." >> $LOG_FILE
else
    echo "Schema dump failed." >> $LOG_FILE
    send_telegram_message "Schema dump failed."
fi

# Dump the data
echo "Dumping data..." >> $LOG_FILE
mysqldump -u$MYSQL_USER -h$MYSQL_HOST --no-create-info $MYSQL_DATABASE > $DATA_FILE 2>> $LOG_FILE
if [ $? -eq 0 ]; then
    echo "Data dump completed successfully." >> $LOG_FILE
else
    echo "Data dump failed." >> $LOG_FILE
    send_telegram_message "Data dump failed."
fi

# Archive the dumps
echo "Archiving dumps..." >> $LOG_FILE
tar -czvf $BACKUP_FILE -C $BACKUP_DIR $(basename $SCHEMA_FILE) $(basename $DATA_FILE) >> $LOG_FILE 2>&1
if [ $? -eq 0 ]; then
    echo "Archive created successfully." >> $LOG_FILE
else
    echo "Failed to create archive." >> $LOG_FILE
    send_telegram_message "Failed to create archive."
fi

# Clean up temporary files
echo "Cleaning up temporary files..." >> $LOG_FILE
rm $SCHEMA_FILE $DATA_FILE
if [ $? -eq 0 ]; then
    echo "Temporary files removed successfully." >> $LOG_FILE
else
    echo "Failed to remove temporary files." >> $LOG_FILE
    send_telegram_message "Failed to remove temporary files."
fi

echo "Backup completed at $(date +%Y%m%d%H%M%S)" >> $LOG_FILE

send_telegram_message "Backup completed successfully at $(date +%Y%m%d%H%M%S)"