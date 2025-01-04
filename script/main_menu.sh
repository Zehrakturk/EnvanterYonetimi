#!/bin/bash

# Check if the user is an admin or regular user, and set variables accordingly
is_admin=$1 # 1: Admin, 0: User

# Define main menu options
if [ "$is_admin" -eq 1 ]; then
    menu_choice=$(zenity --list \
        --title="Admin Main Menu" \
        --text="Please select an option:" \
        --column="Operation" \
        "List Products" \
        "Add Product" \
        "Delete Product" \
        "Update Product" \
        "Generate Report" \
        "User Management" \
        "Program Management" \
        "Exit" \
        --width=500 \
        --height=400)
else
    menu_choice=$(zenity --list \
        --title="User Main Menu" \
        --text="Please select an operation:" \
        --column="Operation" \
        "List Products" \
        "User Operations" \
        "Exit" \
        --width=400 \
        --height=300)
fi

# Exit if no option is selected
if [ -z "$menu_choice" ]; then
    zenity --info --title="Information" --text="No operation selected. Exiting." --width=300
    exit 0
fi

# Execute the operation based on the selected option
case "$menu_choice" in
    "List Products")
        zenity --info --title="Information" --text="Product listing operation selected." --width=300
        /home/btu59049/envanter_yonetimi/script/productscrud.sh 3 "$is_admin"
        ;;
    "Add Product")
        zenity --info --title="Information" --text="Product addition operation selected." --width=300
        /home/btu59049/envanter_yonetimi/script/productscrud.sh 0 "$is_admin"
        ;;
    "Delete Product")
        zenity --info --title="Information" --text="Product deletion operation selected." --width=300
        /home/btu59049/envanter_yonetimi/script/productscrud.sh 2 "$is_admin"
        ;;
    "Update Product")
        zenity --info --title="Information" --text="Product update operation selected." --width=300
        /home/btu59049/envanter_yonetimi/script/productscrud.sh 1 "$is_admin"
        ;;
    "Generate Report")
        zenity --info --title="Information" --text="Report generation operation selected." --width=300
        /home/btu59049/envanter_yonetimi/script/report.sh
        ;;
    "User Management")
        zenity --info --title="Information" --text="User management operation selected." --width=300  
        /home/btu59049/envanter_yonetimi/script/usersoperations.sh "$is_admin"
        ;;
    "Program Management")
        zenity --info --title="Information" --text="Program management operation selected." --width=300
        /home/btu59049/envanter_yonetimi/script/programmanagement.sh

        ;;
    "User Operations")
        zenity --info --title="Information" --text="User operations selected." --width=300
        /home/btu59049/envanter_yonetimi/script/usersoperations.sh "$is_admin"
        ;;
    "Exit")
        zenity --info --title="Information" --text="Exiting the program." --width=300
        exit 0
        ;;
    *)
        zenity --error --title="Error" --text="An unknown operation was selected!" --width=300
        ;;
esac

