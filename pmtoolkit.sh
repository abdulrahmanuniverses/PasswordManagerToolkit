#!/bin/bash

# Default variable
DPATH="$HOME" # your home directory

# Color Variables
BANNER_COLOR='\e[32m'
END_COLOR='\e[0m'
OPTI_COLOR='\e[31m'

# Function to generate passwords
password_generator() {
    echo "###########################################################"
    echo ""
    echo "                 RANDOM PASSWORD GENERATOR                 " 
    echo ""
    echo "###########################################################"
    read -p "Enter the value of the password length: " PASS_LEN
    read -p "How many passwords do you want to create: " PL
    echo -e "\nGenerated Passwords:\n"
    for P in $(seq "$PL"); do 
        PASSWORD=$(openssl rand -base64 48 | cut -c1-"$PASS_LEN")
        echo "PASSWORD $P: $PASSWORD"
    done
}

# Function for password manager
PASSWORD_MANAGER() {
    while true; do
        echo "PM Toolkit encrypted password manager"
        echo -e "${OPTI_COLOR}IF YOU GENERATED A PASSWORD LIST BEFORE, BE CAREFUL TO AVOID OVERWRITING THE EXISTING FILE${END_COLOR}"
        echo ""
        echo "Choose an option:"
        echo -e "1. Create new password list\n2. Explore Your Lists\n3. Add username and password\n4. View stored passwords\n5. Go back"
        read -p "Choose an option (1 - 5): " PASSLIST_O

        case $PASSLIST_O in
            1)
                echo -e "Please enter the file name ${OPTI_COLOR}!!no symbols!!${END_COLOR}"
                read -p "Enter the file name: " FILENAME
                if [ -f "$DPATH/$FILENAME.gpg" ]; then
                    echo "File already exists! Exiting to prevent overwrite."
                    continue
                fi
                touch "$DPATH/$FILENAME.txt"
                read -s -p "Enter the file new password: " PCARROT
                echo ""
                gpg --symmetric --batch --yes --passphrase "$PCARROT" -o "$DPATH/$FILENAME.gpg" "$DPATH/$FILENAME.txt" && rm "$DPATH/$FILENAME.txt"
                echo "Encrypted password file created at: $DPATH/$FILENAME.gpg"
                ;;
            2)
                echo "Listing your saved password files:"
                ls "$DPATH"/*.gpg 2>/dev/null || echo "No saved password files found."
                ;;
            3)
                echo "Add new username and password"
                read -p "Enter the file name (without .gpg): " FILENAME
                if [ ! -f "$DPATH/$FILENAME.gpg" ]; then
                    echo "File not found!"
                    continue
                fi
                read -s -p "Enter the file password: " PCARROT
                echo ""
                read -p "Enter the username: " NEWUSERNAME
                read -s -p "Enter the password: " NEWPASSWORD
                echo ""
                gpg --decrypt --batch --passphrase "$PCARROT" "$DPATH/$FILENAME.gpg" > "$DPATH/temp_passwords.txt" 2>/dev/null
                if [ $? -ne 0 ]; then
                    echo "Decryption failed! Wrong password?"
                    rm -f "$DPATH/temp_passwords.txt"
                    continue
                fi
                echo "username: $NEWUSERNAME" >> "$DPATH/temp_passwords.txt"
                echo "password: $NEWPASSWORD" >> "$DPATH/temp_passwords.txt"
                gpg --symmetric --batch --yes --passphrase "$PCARROT" -o "$DPATH/$FILENAME.gpg" "$DPATH/temp_passwords.txt"
                rm "$DPATH/temp_passwords.txt"
                echo "Password added successfully."
                ;;
            4)
                echo "View stored passwords"
                read -p "Enter the file name (without .gpg): " FILENAME
                if [ ! -f "$DPATH/$FILENAME.gpg" ]; then
                    echo "File not found!"
                    continue
                fi
                read -s -p "Enter the file password: " PCARROT
                echo ""
                echo "----------------------------------"
                gpg --decrypt --batch --passphrase "$PCARROT" "$DPATH/$FILENAME.gpg" 2>/dev/null || echo "Decryption failed! Wrong password?"
                echo "----------------------------------"
                ;;
            5)
                break ;;
            *)
                echo "Invalid option selected." ;;
        esac
    done
}

# Function to check if a password was leaked
check_password_leak() {
    read -sp "Enter your password: " PASSWORD
    echo
    PASSWORD_HASH=$(echo -n "$PASSWORD" | shasum -a 1 | awk '{print $1}')
    PREFIX=${PASSWORD_HASH:0:5}
    SUFFIX=${PASSWORD_HASH:5}
    RESPONSE=$(curl -s "https://api.pwnedpasswords.com/range/$PREFIX")
    if echo "$RESPONSE" | grep -iq "$SUFFIX"; then
        echo "⚠️ Your password has been leaked!"
    else
        echo "✅ Your password was NOT found in known leaks."
    fi
}

# Main program loop
while true; do
    clear
    echo -e "${BANNER_COLOR}$(figlet "PM Toolkit")${END_COLOR}"
    echo "Welcome to the password manager toolkit"
    echo ""
    echo "Please choose an option... :)"
    echo ""
    echo "#########"
    echo -e "${OPTI_COLOR}1. Generate Password\n2. Your Saved Passwords\n3. Check if this password leaked\n4. Exit${END_COLOR}"
    read -p "Select Number (1 - 4): " UOPTION

    case $UOPTION in
        1)
            password_generator
            ;;
        2)
            PASSWORD_MANAGER
            ;;
        3)
            check_password_leak
            ;;
        4)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid selection."
            ;;
    esac

    echo ""
    read -p "Do you want to do another function? (y/n): " AGAIN
    if [[ ! "$AGAIN" =~ ^[Yy]$ ]]; then
        echo "Goodbye!"
        exit 0
    fi
done
