#!/bin/bash

# Path to the log file
log_file="/var/log/csr-approval-prereqs.log"
csr_approval_script="csr-approval.sh"
csr_approval_destination="/usr/local/bin/csr-approval.sh"

# Log function to write messages to the log file with timestamps
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> $log_file
}

# Function to install prerequisites
install_prerequisites() {
    log "Checking for and installing prerequisites: jq, openssl, mailx, cronie"

    for package in jq openssl mailx cronie; do
        if ! command -v $package &> /dev/null; then
            log "Installing $package"
            if command -v yum &> /dev/null; then
                sudo yum install -y $package
            elif command -v apt-get &> /dev/null; then
                sudo apt-get update
                sudo apt-get install -y $package
            else
                log "Unsupported package manager for $package. Install $package manually."
                echo "Unsupported package manager for $package. Install $package manually."
                exit 1
            fi
            log "$package installed successfully."
        else
            log "$package is already installed."
        fi
    done
    log "All prerequisites are installed."
}

# Function to check the operating system
check_os() {
    log "Checking operating system compatibility"
    os_name=$(uname -s)
    if [[ "$os_name" != "Linux" ]]; then
        log "Unsupported operating system: $os_name"
        echo "Unsupported operating system: $os_name"
        exit 1
    fi
    log "Operating system is compatible."
}

# Function to ensure csr-approval script is available
check_csr_approval_script() {
    if [[ ! -f ./$csr_approval_script ]]; then
        log "csr-approval script not found in the current directory."
        echo "csr-approval script not found in the current directory."
        exit 1
    fi
    log "csr-approval script found."
}

# Function to validate email format
validate_email() {
    if ! [[ "$1" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        log "Invalid email format: $1"
        echo "Invalid email format: $1"
        exit 1
    fi
}

# Function to validate SMTP details format
validate_smtp_details() {
    if ! [[ "$1" =~ ^[a-zA-Z0-9.-]+$ ]]; then
        log "Invalid SMTP server format: $1"
        echo "Invalid SMTP server format: $1"
        exit 1
    fi

    if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        log "Invalid SMTP port format: $2"
        echo "Invalid SMTP port format: $2"
        exit 1
    fi

    if ! [[ "$3" =~ ^(tls|ssl)$ ]]; then
        log "Invalid SMTP security format: $3"
        echo "Invalid SMTP security format: $3"
        exit 1
    fi
}

# Function to gather input from the user
gather_inputs() {
    read -p "Enter the email address to send alerts to: " email
    validate_email $email

    while true; do
        read -s -p "Enter the email password: " email_password
        echo
        read -s -p "Confirm the email password: " email_password_confirm
        echo
        [ "$email_password" = "$email_password_confirm" ] && break
        echo "Passwords do not match. Please try again."
    done

    read -p "Enter the SMTP server address: " smtp_server
    read -p "Enter the SMTP server port: " smtp_port
    read -p "Enter the SMTP server security (tls/ssl): " smtp_security

    validate_smtp_details $smtp_server $smtp_port $smtp_security

    log "User inputs gathered and validated."
}

# Function to send a test email
send_test_email() {
    log "Sending test email to $email"
    echo "This is a test email from the CSR approval script." | mailx -s "Test Email" -S smtp="smtp://$smtp_server:$smtp_port" -S smtp-use-starttls -S smtp-auth=login -S smtp-auth-user="$email" -S smtp-auth-password="$email_password" -S ssl-verify=ignore "$email"

    if [ $? -eq 0 ]; then
        log "Test email sent successfully."
        echo "Test email sent successfully."
    else
        log "Failed to send test email."
        echo "Failed to send test email."
        exit 1
    fi
}

# Function to set up email configuration
setup_email_configuration() {
    log "Setting up email configuration"
    if command -v postfix &> /dev/null; then
        sudo postconf -e "relayhost = [$smtp_server]:$smtp_port"
        sudo postconf -e "smtp_tls_security_level = $smtp_security"
        sudo postconf -e "smtp_sasl_auth_enable = yes"
        sudo postconf -e "smtp_sasl_password_maps = static:$email:$email_password"
        sudo postconf -e "smtp_sasl_security_options = noanonymous"
        sudo systemctl restart postfix
    elif command -v sendmail &> /dev/null; then
        echo "AuthInfo:[$smtp_server]:$smtp_port \"U:$email\" \"P:$email_password\" \"M:LOGIN\"" > /etc/mail/authinfo
        sudo makemap hash /etc/mail/authinfo < /etc/mail/authinfo
        sudo sed -i "/define(\`SMART_HOST', \`[$smtp_server]:$smtp_port')dnl/ a define(\`confAUTH_OPTIONS', \`A p')dnl" /etc/mail/sendmail.mc
        sudo sed -i "/FEATURE(\`authinfo', \`hash -o /etc/mail/authinfo.db')dnl/ a define(\`confAUTH_MECHANISMS', \`EXTERNAL GSSAPI DIGEST-MD5 CRAM-MD5 LOGIN PLAIN')dnl" /etc/mail/sendmail.mc
        sudo m4 /etc/mail/sendmail.mc > /etc/mail/sendmail.cf
        sudo systemctl restart sendmail
    else
        log "Unsupported email package. Install and configure postfix or sendmail manually."
        echo "Unsupported email package. Install and configure postfix or sendmail manually."
        exit 1
    fi
    log "Email configuration set up successfully."
}

# Function to configure log rotation
configure_log_rotation() {
    log "Configuring log rotation"
    echo "/var/log/csr-approval-prereqs.log {
        rotate 7
        daily
        compress
        missingok
        notifempty
    }

    /var/log/csr-approval.log {
        rotate 7
        daily
        compress
        missingok
        notifempty
    }" | sudo tee /etc/logrotate.d/csr-approval
    log "Log rotation configured."
}

# Function to configure crontab
configure_crontab() {
    log "Configuring crontab for CSR approval script"

    cron_job="*/5 * * * * $csr_approval_destination >> /var/log/csr-approval.log 2>&1"
    (crontab -l 2>/dev/null; echo "$cron_job") | crontab -

    log "Crontab configured to run CSR approval script every 5 minutes."
}

# Progress bar function
progress_bar() {
    local duration=$1
    already_done() { for ((done=0; done<$elapsed; done++)); do printf "#"; done }
    remaining() { for ((remain=$elapsed; remain<$duration; remain++)); do printf "."; done }
    percentage() { printf "| %s%%" $(( (($elapsed)*100)/($duration)*100/100 )); }

    for (( elapsed=1; elapsed<=$duration; elapsed++ )); do
        already_done; remaining; percentage
        printf "\r"
        sleep 1
    done
    printf "\n"
}

# Main script execution
log "Starting prerequisites deployment"
check_os
check_csr_approval_script
install_prerequisites
gather_inputs
send_test_email
setup_email_configuration
configure_log_rotation
configure_crontab

# Copy and make the csr-approval script executable
sudo cp ./$csr_approval_script $csr_approval_destination
sudo chmod +x $csr_approval_destination

progress_bar 20
log "Prerequisites deployment completed successfully."
echo "Prerequisites deployment completed successfully."
