#!/bin/bash

# File paths
BASE_DIR="/home/btu59049/envanter_yonetimi"
LOG_FILE="$BASE_DIR/logs/log.csv"
USERS_FILE="$BASE_DIR/user/users.csv"
MANAGERS_FILE="$BASE_DIR/user/managers.csv"
PRODUCTS_FILE="$BASE_DIR/product/products.csv"
BACKUP_DIR="$BASE_DIR/backups"

# Check and create the backup directory
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR" 2>/dev/null || {
        zenity --error \
            --title="Error" \
            --text="Could not create backup directory: $BACKUP_DIR\nPlease check directory permissions."
        exit 1
    }
fi

# Show disk usage
show_disk_usage() {
    # Calculate the size of all files
    local log_size=$(du -h "$LOG_FILE" 2>/dev/null | cut -f1)
    local users_size=$(du -h "$USERS_FILE" 2>/dev/null | cut -f1)
    local managers_size=$(du -h "$MANAGERS_FILE" 2>/dev/null | cut -f1)
    local products_size=$(du -h "$PRODUCTS_FILE" 2>/dev/null | cut -f1)
    
    # Calculate total size (in bytes)
    local total_size=$(du -bc "$LOG_FILE" "$USERS_FILE" "$MANAGERS_FILE" "$PRODUCTS_FILE" 2>/dev/null | tail -n1 | cut -f1)
    local total_size_human=$(numfmt --to=iec-i --suffix=B $total_size)

    # Show results
    (echo "File|Size"
     echo "--------------------------|------------"
     echo "Log File|$log_size"
     echo "Users File|$users_size"
     echo "Managers File|$managers_size"
     echo "Products File|$products_size"
     echo "--------------------------|------------"
     echo "Total Size|$total_size_human") | \
    column -t -s '|' | \
    zenity --text-info \
        --title="Disk Usage" \
        --width=400 \
        --height=300
}

# Backup files
backup_files() {
    # Check if the files exist
    local missing_files=""
    for file in "$USERS_FILE" "$MANAGERS_FILE" "$PRODUCTS_FILE"; do
        if [ ! -f "$file" ]; then
            missing_files="$missing_files\n$(basename "$file")"
        fi
    done

    if [ -n "$missing_files" ]; then
        zenity --error \
            --title="Backup Error" \
            --text="The following files were not found:$missing_files"
        return 1
    fi

    # Generate timestamp for backup file
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/backup_$timestamp.tar.gz"
    
    # Create a temporary directory
    local temp_dir=$(mktemp -d)
    
    # Copy files to the temporary directory
    cp "$USERS_FILE" "$MANAGERS_FILE" "$PRODUCTS_FILE" "$temp_dir/" 2>/dev/null
    
    # Create a backup from the temporary directory
    if cd "$temp_dir" && tar -czf "$backup_file" * 2>/dev/null; then
        # If backup is successful, show success message
        zenity --info \
            --title="Backup Successful" \
            --text="Files were successfully backed up:\n$backup_file"
            
        # Log the backup
        echo "$(date '+%Y-%m-%d %H:%M:%S'),SYSTEM,BACKUP,SUCCESS,Files backed up to $backup_file" >> "$LOG_FILE"
    else
        # On error, show error message
        zenity --error \
            --title="Backup Error" \
            --text="An error occurred during backup!\nPlease check directory permissions and disk space."
            
        # Log the error
        echo "$(date '+%Y-%m-%d %H:%M:%S'),SYSTEM,BACKUP,ERROR,Backup failed" >> "$LOG_FILE"
    fi
    
    # Clean up the temporary directory
    rm -rf "$temp_dir"
}

# Show error logs
show_error_logs() {
    if [ ! -f "$LOG_FILE" ]; then
        zenity --error \
            --title="Error" \
            --text="Log file not found: $LOG_FILE" \
            --width=300
        return 1
    fi

    cat "$LOG_FILE" | \
    zenity --text-info \
        --title="Error Logs" \
        --width=800 \
        --height=400
}

menu(){
while true; do
    choice=$(zenity --list \
        --title="Program Management" \
        --text="Please select an action:" \
        --column="Option" --column="Description" \
        1 "Show Disk Usage" \
        2 "Backup to Disk" \
        3 "Show Error Logs" \
        4 "Exit" \
        --width=400 --height=300)
    
    case $choice in
        1)
            show_disk_usage
            ;;
        2)
            backup_files
            ;;
        3)
            show_error_logs
            ;;
        4|"")
        	/home/btu59049/envanter_yonetimi/script/main_menu.sh 1
            exit 0
            ;;
    esac
done
}

menu

