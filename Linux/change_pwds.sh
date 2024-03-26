#!/bin/sh
# Changes passwords for all users with an interactive shell
# Works on all linux and bsd platforms due to /bin/sh compatibility
bsd=0

# Check if a bsd machine
cat /etc/os-release | grep -i "bsd" > /dev/null
if [ $? -eq 0 ]; then
  bsd=1
fi

# Get list of users to not change passwords for
read -p "Enter list of protected users space delimited: " special
echo

# Get a string that contains the names of all interactive shells on the system
valid_shells=$(cat /etc/shells | grep -v "^#" | awk -F/ '{print $NF}' | tr '\n' '|')
valid_shells="${valid_shells%|}"

if [ $bsd -eq 1 ]; then
  # Iterate through users with valid shells
  while IFS=: read -r user _ _ _ _ _ shell; do
    shell_filename=$(basename "$shell")
    if echo "$shell_filename" | grep -E "$valid_shells" > /dev/null; then
     
      # Check if user is contained in the special string and check return code
      echo $special | grep "$user " > /dev/null || echo $special | grep "$user\$" > /dev/null
      if [ $? -ne 0 ]; then
        # Use base64 to create complex password
        new_password=$(openssl rand -base64 16 | tr -d '\n' | tr -d '/')
        encoded_password=$(echo -n "$new_password" | openssl passwd -6 -stdin)
        chpass -p $encoded_password $user >/dev/null 2>&1

        if [ $? -eq 0 ]; then
          echo "$user,$new_password"
        else
          echo "Failed to change password for $user"
        fi
      fi
    fi
  done < /etc/passwd
else
  # Iterate through users with valid shells
  while IFS=: read -r user _ _ _ _ _ shell; do
    shell_filename=$(basename "$shell")                      
    if echo "$shell_filename" | grep -E "$valid_shells" > /dev/null; then

      # Check if user is contained in the special string and check return code
      echo $special | grep "$user " > /dev/null || echo $special | grep "$user\$" > /dev/null
      if [ $? -ne 0 ]; then
        # Generate a random password for each user
        pword=$(head -c 200 /dev/urandom | tr -dc 'a-zA-Z0-9@$%&!?:+-=' | cut -c1-16)

        # Change password and echo to std output for use in csv file
        echo "$user:$pword" | chpasswd > /dev/null
        echo "$user,$pword"
      fi
    fi
  done < /etc/passwd
fi
echo 
echo "Passwords successfully changed."
