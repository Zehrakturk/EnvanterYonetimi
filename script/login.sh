#!/bin/bash

LOG_FILE="/home/btu59049/envanter_yonetimi/logs/log.csv"
admin_file="/home/btu59049/envanter_yonetimi/user/managers.csv"
user_file="/home/btu59049/envanter_yonetimi/user/users.csv"
LOCKED_FILE="/home/btu59049/envanter_yonetimi/logs/logs.csv"

[ ! -f "$LOG_FILE" ] && echo "timestamp,username,attempt_count,status,ip_address" > "$LOG_FILE"
[ ! -f "$LOCKED_FILE" ] && echo "username,locked_time,unlock_time" > "$LOCKED_FILE"

check_locked() {
    local username="$1"
    if grep -q "^$username," "$LOCKED_FILE"; then
        local unlock_time=$(grep "^$username," "$LOCKED_FILE" | cut -d',' -f3)
        if [ $(date +%s) -lt "$unlock_time" ]; then
            zenity --error --text="Your account is locked. Please try again later."
            return 1
        else
            sed -i "/^$username,/d" "$LOCKED_FILE"
        fi
    fi
    return 0
}

log_attempt() {
    local username="$1"
    local status="$2"
    local ip=$(hostname -I | awk '{print $1}')
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$timestamp,$username,$attempt_count,$status,$ip" >> "$LOG_FILE"
}

attempt_count=0
while [ $attempt_count -lt 3 ]; do
    user_input=$(zenity --forms \
        --title="Login" \
        --text="Please enter your details: (Remaining attempts: $((3-attempt_count)))" \
        --add-entry="Username" \
        --add-password="Password" \
        --width=500 --height=300 \
        --ok-label="Login" \
        --cancel-label="Cancel")
    
    [ $? -ne 0 ] && exit 0
    
    username=$(echo "$user_input" | cut -d'|' -f1)
    password=$(echo "$user_input" | cut -d'|' -f2)
    
    check_locked "$username" || exit 1
    
    admin_login=false
    user_login=false
    
    while IFS=, read -r name surname user pass email; do
        if [[ "$username" == "$user" && "$password" == "$pass" ]]; then
            admin_login=true
            break
        fi
    done < "$admin_file"
    
    if [ "$admin_login" = false ]; then
        while IFS=, read -r name surname user pass email; do
            if [[ "$username" == "$user" && "$password" == "$pass" ]]; then
                user_login=true
                break
            fi
        done < "$user_file"
    fi
    
    if [ "$admin_login" = true ]; then
        log_attempt "$username" "success_admin"
        zenity --info --text="Login Successful! Welcome Administrator: $username."
        exec /home/btu59049/envanter_yonetimi/script/main_menu.sh 1
    elif [ "$user_login" = true ]; then
        log_attempt "$username" "success_user"
        zenity --info --text="Login Successful! Welcome User: $username."
        exec /home/btu59049/envanter_yonetimi/script/main_menu.sh 0
    else
        ((attempt_count++))
        log_attempt "$username" "failed"
        
        if [ $attempt_count -eq 3 ]; then
            lock_time=$(date +%s)
            unlock_time=$((lock_time + 3600)) # 1 hour lock
            echo "$username,$lock_time,$unlock_time" >> "$LOCKED_FILE"
            zenity --error --text="Your account has been locked. Please try again in 1 hour."
            exit 1
        else
            zenity --error --text="Login Failed! Remaining attempts: $((3-attempt_count))"
        fi
    fi
done

