#!/bin/bash

DB_FILE="/home/btu59049/envanter_yonetimi/product/products.csv"
LOG_FILE="/home/btu59049/envanter_yonetimi/logs/log.csv"
TEMP_FILE="/tmp/inventory_temp.csv"
USER_ID="$3"

init_db() {
    if [ ! -f "$DB_FILE" ]; then
        echo "id,name,description,price,stock,category,created_at,updated_at" > "$DB_FILE"
    fi
    if [ ! -f "$LOG_FILE" ]; then
        echo "log_id,timestamp,user_id,action,product_name,log_message" > "$LOG_FILE"
    fi
}

log_message() {
    local log_id=$(date +%s)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$log_id,$timestamp,$USER_ID,$1,$2,$3" >> "$LOG_FILE"
}

validate_price() {
    if [[ ! $1 =~ ^[0-9]+(\.[0-9]{1,2})?$ ]]; then
        log_message "PRICE_VALIDATION-error" "$2" "Invalid price format"
        return 1
    fi
    return 0
}

validate_stock() {
    if [[ ! $1 =~ ^[0-9]+$ ]]; then
        log_message "STOCK_VALIDATION-error" "$2" "Invalid stock quantity"
        return 1
    fi
    return 0
}

create_product() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    local name=$(zenity --entry --title="Add Product" --text="Enter product name:")
    if [ -z "$name" ]; then
        log_message "CREATE-error" "$name" "Empty product name"
        return 1
    fi
    if [[ "$name" =~ \  ]]; then
        log_message "CREATE-warning" "$name" "Product name contains spaces"
        zenity --error --text="Product name cannot contain spaces!"
        return 1
    fi

    if grep -q "^[^,]*,[^,]*$name," "$DB_FILE"; then
        log_message "CREATE-error" "$name" "Duplicate product name"
        zenity --error --title="Error" --text="A product with this name already exists. Please use a different name."
        return 1
    fi

    local price=$(zenity --entry --title="Add Product" --text="Enter price (Format: XX.XX):")
    if ! [[ "$price" =~ ^[0-9]+(\.[0-9]{1,2})?$ ]] || (( $(echo "$price < 0" | bc -l) )); then
        log_message "CREATE-error" "$name" "Invalid price format or negative value"
        zenity --error --title="Error" --text="Price must be a non-negative number in the format XX.XX!"
        return 1
    fi

    local stock=$(zenity --entry --title="Add Product" --text="Enter stock quantity:")
    if ! [[ "$stock" =~ ^[0-9]+$ ]]; then
        log_message "CREATE-error" "$name" "Invalid stock quantity"
        zenity --error --title="Error" --text="Stock quantity must be a non-negative integer!"
        return 1
    fi

    local category=$(zenity --list --title="Select Category" --column="Category" \
        "Electronics" "Clothing" "Books" "Home" "Other")
    if [ -z "$category" ]; then
        log_message "CREATE-warning" "$name" "No category selected"
        return 1
    fi

    local id=$(tail -n +2 "$DB_FILE" | wc -l)
    id=$((id + 1))

    echo "$id,$name,, $price,$stock,$category,$timestamp,$timestamp" >> "$DB_FILE"
    log_message "CREATE-info" "$name" "Product created successfully"
    zenity --info --title="Information" --text="Product added successfully!"
}

update_product() {
    local name=$(zenity --entry --title="Update Product" --text="Enter product name:")
    if [ -z "$name" ]; then
        log_message "UPDATE-error" "" "Empty product name"
        return 1
    fi

    if ! grep -q "^[^,]*,$name," "$DB_FILE"; then
        log_message "UPDATE-warning" "$name" "Product not found"
        zenity --error --text="Product not found!"
        return 1
    fi

    local update_type=$(zenity --list --title="Update Type" --text="What do you want to update?" \
        --column="Option" "Price" "Stock" "Both")

    local price="" stock=""
    case "$update_type" in
        "Price"|"Both")
            price=$(zenity --entry --title="Update Price" --text="Enter new price:")
            if ! validate_price "$price" "$name"; then
                zenity --error --title="Error" --text="Invalid price format!"
                return 1
            fi
            ;;
    esac

    case "$update_type" in
        "Stock"|"Both")
            stock=$(zenity --entry --title="Update Stock" --text="Enter new stock quantity:")
            if ! validate_stock "$stock" "$name"; then
                zenity --error --title="Error" --text="Invalid stock quantity!"
                return 1
            fi
            ;;
    esac

    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    awk -F',' -v name="$name" -v price="$price" -v stock="$stock" -v ts="$timestamp" \
        'BEGIN {OFS=","}
        $2==name {
            if (price != "") $4=price
            if (stock != "") $5=stock
            $8=ts
        }
        {print}' "$DB_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$DB_FILE"

    log_message "UPDATE-info" "$name" "Product updated successfully"
    zenity --info --title="Information" --text="Product updated successfully!"
}

delete_product() {
    local name=$(zenity --entry --title="Delete Product" --text="Enter product name to delete:")
    if [ -z "$name" ]; then
        log_message "DELETE-error" "" "Empty product name"
        return 1
    fi

    if ! grep -q "^[^,]*,$name," "$DB_FILE"; then
        log_message "DELETE-warning" "$name" "Product not found"
        zenity --error --title="Error" --text="Product not found!"
        return 1
    fi

    if zenity --question --text="Are you sure you want to delete $name?"; then
        grep -v "^[^,]*,$name," "$DB_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$DB_FILE"
        log_message "DELETE-info" "$name" "Product deleted successfully"
        zenity --info --title="Information" --text="Product deleted successfully!"
    else
        log_message "DELETE-warning" "$name" "Delete operation cancelled by user"
    fi
}
view_products() {
    local filter=$(zenity --list --title="View Products" --text="Select Filter:" \
        --column="Option" "All Products" "Low Stock" "By Category")
    
    case "$filter" in
        "Low Stock")
            # Changed to use proper field comparison for numbers and format output
            awk -F',' '
                BEGIN { printf "Low Stock Products (Less than 10 units):\n\n" }
                NR>1 && $5+0 < 10 {
                    printf "Name: %s\nCategory: %s\nStock: %s\nPrice: %.2f\n-------------------\n", 
                    $2, $6, $5, $4
                }
            ' "$DB_FILE" | zenity --text-info --title="Low Stock Products" --width=600 --height=400
            ;;
        "By Category")
            local cat=$(zenity --list --title="Select Category" --column="Category" \
                "Electronics" "Clothing" "Books" "Home" "Other")
            if [ -z "$cat" ]; then
                log_error "VIEW" "" "No category selected"
                return 1
            fi
            # Added proper string comparison and improved formatting
            awk -F',' -v cat="$cat" '
                BEGIN { printf "Products in category: %s\n\n", cat }
                NR>1 && $6 == cat {
                    printf "Name: %s\nCategory: %s\nStock: %s\nPrice: %.2f\n-------------------\n", 
                    $2, $6, $5, $4
                }
            ' "$DB_FILE" | zenity --text-info --title="Products by Category" --width=600 --height=400
            ;;
        *)
            # Improved formatting for all products view
            awk -F',' '
                BEGIN { printf "All Products:\n\n" }
                NR>1 {
                    printf "Name: %s\nCategory: %s\nStock: %s\nPrice: %.2f\n-------------------\n", 
                    $2, $6, $5, $4
                }
            ' "$DB_FILE" | zenity --text-info --title="All Products" --width=600 --height=400
            ;;
    esac
}
exit_program() {
    if zenity --question --title="Confirmation" --text="Are you sure you want to exit?"; then
        log_error "EXIT" "" "User exited program"
        exit 0
    fi
}

init_db

case "$1" in
    0) create_product ;;
    1) update_product ;;
    2) delete_product ;;
    3) view_products ;;
    4) exit_program ;;
    *) 
        log_error "INVALID_OPERATION" "" "Invalid operation"
        zenity --error --text="Invalid operation!"
        ;;
esac

if [ "$2" -eq 1 ]; then
    bash /home/btu59049/envanter_yonetimi/script/main_menu.sh 1
else
    bash /home/btu59049/envanter_yonetimi/script/main_menu.sh 0
fi
