#!/bin/bash

USERS_FILE="/home/btu59049/envanter_yonetimi/user/users.csv"
ADMIN_FILE="/home/btu59049/envanter_yonetimi/user/managers.csv"
LOG_FILE="/home/btu59049/envanter_yonetimi/logs/log.csv"
LOCKED_FILE="/home/btu59049/envanter_yonetimi/logs/logs.csv"
TEMP_FILE="/tmp/users_temp.csv"
CURRENT_USER_ID="$2"
IS_ADMIN="$1"



init_db() {
    if [ ! -f "$USERS_FILE" ]; then
        echo "user_id,name,surname,password" > "$USERS_FILE"
    fi
    if [ ! -f "$ADMIN_FILE" ]; then
        echo "admin_id,name,surname,password" > "$ADMIN_FILE"
    fi
    if [ ! -f "$LOG_FILE" ]; then
        echo "error_id,timestamp,user_id,action,error_message" > "$LOG_FILE"
    fi
    if [ ! -f "$LOCKED_FILE" ]; then
        echo "username,locked_time,unlock_time" > "$LOCKED_FILE"
    fi
}



log_error() {
    local error_id=$(date +%s)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$error_id,$timestamp,$CURRENT_USER_ID,$1,$2" >> "$LOG_FILE"
}

check_duplicate_name() {
    local name="$1"
    local id="$2"
    local is_admin="$3"
    local check_file
    
    if [ "$is_admin" == "1" ]; then
        check_file="$ADMIN_FILE"
    else
        check_file="$USERS_FILE"
    fi
    
    if awk -F',' -v name="$name" -v uid="$id" \
        '$2 == name && $1 != uid {exit 1}' "$check_file"; then
        return 0
    else
        return 1
    fi
}

generate_id() {
    local file="$1"
    local last_id=$(tail -n +2 "$file" 2>/dev/null | cut -d',' -f1 | sort -n | tail -n 1)
    if [ -z "$last_id" ]; then
        echo "1"
    else
        echo $((last_id + 1))
    fi
}

hash_password() {
    echo -n "$1" | md5sum | cut -d' ' -f1
}

validate_input() {
    local input="$1"
    local field="$2"
    if [ -z "$input" ]; then
        zenity --error --title="Error" --text="$field cannot be empty!"
        log_error "VALIDATION_ERROR" "$field cannot be empty"
        return 1
    fi
    return 0
}

add_user() {
    if [ "$IS_ADMIN" != "1" ]; then
        zenity --error --title="Error" --text="Only administrators can add new users!"
        log_error "PERMISSION_ERROR" "Non-admin tried to add user"
        return 1
    fi

    local role=$(zenity --list --title="Select Role" --text="Select User Role:" \
        --column="Role" --column="Description" \
        1 "Administrator" \
        0 "Regular User")
    if [ -z "$role" ]; then
        zenity --error --title="Error" --text="Role must be selected!"
        log_error "VALIDATION_ERROR" "No role selected"
        return 1
    fi

    local name=$(zenity --entry --title="Add User" --text="Enter Name:")
    if ! validate_input "$name" "Name"; then return 1; fi

    if ! check_duplicate_name "$name" "" "$role"; then
        zenity --error --title="Error" --text="User with this name already exists!"
        log_error "DUPLICATE_NAME" "Name '$name' already exists"
        return 1
    fi

    local surname=$(zenity --entry --title="Add User" --text="Enter Surname:")
    if ! validate_input "$surname" "Surname"; then return 1; fi

    local password=$(zenity --password --title="Set Password")
    if ! validate_input "$password" "Password"; then return 1; fi
    
    local hashed_password=$(hash_password "$password")
    
    if [ "$role" == "1" ]; then
        local admin_id=$(generate_id "$ADMIN_FILE")
        echo "$admin_id,$name,$surname,$hashed_password" >> "$ADMIN_FILE"
    else
        local user_id=$(generate_id "$USERS_FILE")
        echo "$user_id,$name,$surname,$hashed_password" >> "$USERS_FILE"
    fi

    zenity --info --title="İnformation" --text="User added successfully!"
}

list_users() {
    if [ "$IS_ADMIN" == "1" ]; then
        (
            echo "Administrators:"
            echo "---------------"
            awk -F',' 'NR>1 {
                printf "Name: %s\nSurname: %s\nPassword: %s\n-------------------\n", $2, $3, $4
            }' "$ADMIN_FILE"
            
            echo -e "\nRegular Users:"
            echo "---------------"
            awk -F',' 'NR>1 {
                printf "Name: %s\nSurname: %s\nPassword: %s\n-------------------\n", $2, $3, $4
            }' "$USERS_FILE"
        ) | zenity --text-info --title="All Users" --width=400 --height=500
    else
        USER_NAME=$(awk '
            $4 == "success_user" { 
                user=$2
            } 
            END { if (user) print user }
        ' "$LOG_FILE")
        
        if [ -n "$USER_NAME" ]; then
            user_info=$(awk -F',' -v user_name="$USER_NAME" '
                $3 == user_name {
                    printf "Name: %s\nSurname: %s\nUsername: %s\nPassword: %s\n", $2, $3, $4, $5
                }
            ' "$USERS_FILE")
            
            if [ -n "$user_info" ]; then
                echo "$user_info" | zenity --text-info --title="User Information" --width=400 --height=300
            else
                zenity --error --title="Error" --text="User not found in the database." --width=300
            fi
        else
            zenity --error --title="Error" --text="No valid user found in the log." --width=300
        fi
    fi
}

list_locked_users() {
    if [ ! -s "$LOCKED_FILE" ]; then
        zenity --info --title="Information" --text="There are no locked users at the moment."
        return 0
    fi

    local current_time=$(date +%s)
    (echo "Username|Lock Time|Unlock Time|Status"
    while IFS=, read -r username locked_time unlock_time; do
        [ "$username" = "username" ] && continue
        locked_time_human=$(date -d "@$locked_time" '+%Y-%m-%d %H:%M:%S')
        unlock_time_human=$(date -d "@$unlock_time" '+%Y-%m-%d %H:%M:%S')
        if [ $current_time -lt $unlock_time ]; then
            status="Locked"
        else
            status="Lock Expired"
        fi
        echo "$username|$locked_time_human|$unlock_time_human|$status"
    done < "$LOCKED_FILE") | column -t -s '|' | \
    zenity --text-info --title="Locked Users" --width=600 --height=400
}


unlock_user() {
    # Check if the locked users file exists and has data
    if [ ! -s "$LOCKED_FILE" ] || [ $(wc -l < "$LOCKED_FILE") -le 1 ]; then
        zenity --error --title="Error" --text="There are no locked users at the moment."
        return 0
    fi

    # Create a list of locked users
    local users_list=$(awk -F',' 'NR>1 {print $1}' "$LOCKED_FILE")

    if [ -z "$users_list" ]; then
        zenity --error --title="Error" --text="No locked users found."
        return 1
    fi

    # Display a selection list for choosing a user
    local username=$(echo "$users_list" | zenity --list \
        --title="Unlock User" \
        --text="Select the user whose lock you want to remove:" \
        --column="Username")

    if [ -z "$username" ]; then
        return 1
    fi

    # Unlock the selected user
    if grep -q "^$username," "$LOCKED_FILE"; then
        if zenity --question \
            --title="Confirmation" \
            --text="Are you sure you want to unlock the user $username?"; then
            sed -i "/^$username,/d" "$LOCKED_FILE"
            zenity --info --title="Info" --text="The lock for $username has been successfully removed."
            log_error "UNLOCK_USER" "Admin unlocked user: $username"
        fi
    else
        zenity --error --title="Error" --text="$username is not locked or could not be found."
    fi
}


update_user() {
    local user_name
    local file_to_use
    local is_admin_user

    if [ "$IS_ADMIN" == "1" ]; then
        local user_type=$(zenity --list --title="Select User Type" --text="Select user type to update:" \
            --column="Type" "Administrator" "Regular User")

        if [ "$user_type" == "Administrator" ]; then
            file_to_use="$ADMIN_FILE"
            is_admin_user="1"
        else
            file_to_use="$USERS_FILE"
            is_admin_user="0"
        fi

        user_name=$(zenity --entry --title="Update User" --text="Enter User Name:")
        if ! grep -q "^[^,]*,$user_name," "$file_to_use"; then
            zenity --error --title="Error" --text="User not found!"
            return 1
        fi

        local new_name=$(zenity --entry --title="Update User" --text="Enter New Name:")
        if ! validate_input "$new_name" "New Name"; then return 1; fi

        local new_surname=$(zenity --entry --title="Update User" --text="Enter New Surname:")
        if ! validate_input "$new_surname" "New Surname"; then return 1; fi

        local new_password=$(zenity --password --title="Update User Password" --text="Enter New Password:")
        if ! validate_input "$new_password" "New Password"; then return 1; fi
        local hashed_password=$(hash_password "$new_password")

        # Update the user's record
        sed -i "/^[^,]*,$user_name,/c\\$user_name,$new_name,$new_surname,$hashed_password" "$file_to_use"
        zenity --info --title="Update Success" --text="User updated successfully!"
        log_error "USER_UPDATED" "Updated user $user_name"
    else
        zenity --error --title="Error" --text="Only administrators can update user information!"
        log_error "PERMISSION_ERROR" "Non-admin tried to update user"
        return 1
    fi
}

delete_user() {
    if [ "$IS_ADMIN" != "1" ]; then
        zenity --error --text="Only administrators can delete users!"
        log_error "PERMISSION_ERROR" "Non-admin tried to delete user"
        return 1
    fi

    local user_type=$(zenity --list --title="Select User Type" --text="Select user type to delete:" \
        --column="Type" "Administrator" "Regular User")
    
    if [ "$user_type" == "Administrator" ]; then
        file_to_use="$ADMIN_FILE"
    else
        file_to_use="$USERS_FILE"
    fi

    # Dosya var mı kontrol et
    if [ ! -f "$file_to_use" ]; then
        zenity --error --text="User database not found!"
        log_error "DELETE_ERROR" "User file not found"
        return 1
    fi

    local user_id=$(zenity --entry --title="Delete User" --text="Enter User ID to delete:")
    if [ -z "$user_id" ]; then
        zenity --error --text="User ID cannot be empty!"
        log_error "DELETE_ERROR" "Empty user ID"
        return 1
    fi

    if ! grep -q "^$user_id," "$file_to_use"; then
        zenity --error --text="User not found!"
        log_error "DELETE_ERROR" "User ID $user_id not found"
        return 1
    fi

    if [ "$user_id" == "$CURRENT_USER_ID" ] && [ "$file_to_use" == "$ADMIN_FILE" ]; then
        zenity --error --text="You cannot delete your own account!"
        log_error "DELETE_ERROR" "Attempted to delete own account"
        return 1
    fi

    if zenity --question --text="Are you sure you want to delete this user?"; then
        # Geçici dosya oluşturuluyor
        TEMP_FILE=$(mktemp)

        # Kullanıcıyı silme işlemi
        grep -v "^$user_id," "$file_to_use" > "$TEMP_FILE" && mv "$TEMP_FILE" "$file_to_use"
        
        zenity --info --title="Information" --text="User deleted successfully!"
    fi
}


show_menu() {
    local menu_options
    if [ "$IS_ADMIN" == "1" ]; then
        menu_options=$(zenity --list --title="User Management" --text="Select Operation:" \
            --column="Option" --column="Description" \
            1 "Add New User" \
            2 "List Users" \
            3 "Update User" \
            4 "Delete User" \
            5 "List Blocked Users" \
            6 "Exit" \
            --height=400)
    else
        menu_options=$(zenity --list --title="User Management" --text="Select Operation:" \
            --column="Option" --column="Description" \
            1 "View My Information" \
            2 "Update My Information" \
            3 "Exit" \
            --height=200)
    fi

    # Menü seçeneklerinin işlenmesi
    case "$menu_options" in
        1)
            if [ "$IS_ADMIN" == "1" ]; then
                add_user
            else
                list_users
            fi
            ;;
        2)
            if [ "$IS_ADMIN" == "1" ]; then
                list_users
            else
                update_user
            fi
            ;;
        3)
            if [ "$IS_ADMIN" == "1" ]; then
                update_user
            else
                exit 0
            fi
            ;;
        4)
            if [ "$IS_ADMIN" == "1" ]; then
                delete_user
            fi
            ;;
        5)
            if [ "$IS_ADMIN" == "1" ]; then
                unlock_user
            fi
            ;;
        6)            
        	/home/btu59049/envanter_yonetimi/script/main_menu.sh "$IS_ADMIN"
            exit 0

            ;;
        *)
            zenity --error --text="Invalid option selected!"
            ;;
    esac

    # Menü tekrar gösteriliyor
    show_menu
}

init_db
show_menu


