#!/bin/bash

# Path to the log file
log_file="/var/log/csr-approval.log"

# Load configurations
source /etc/csr-approval-config
email_password=$(echo $EMAIL_PASSWORD | openssl enc -aes-256-cbc -d -a)

# Log function to write messages to the log file with timestamps
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> $log_file
}

# Send email function
send_email() {
    echo "$1" | mailx -s "CSR Approval Script Alert" -S smtp="smtp://$SMTP_SERVER:$SMTP_PORT" -S smtp-use-starttls -S smtp-auth=login -S smtp-auth-user="$EMAIL" -S smtp-auth-password="$email_password" -S ssl-verify=ignore "$EMAIL"
}

# List pending CSRs
csrs=$(oc get csr -o json | jq -r '.items[] | select(.status.conditions == null) | .metadata.name')

success_counter=0
failure_counter=0

for csr in $csrs; do
  # Inspect the CSR details
  csr_details=$(oc get csr $csr -o json | jq -r '.spec.request' | base64 --decode | openssl req -noout -text)

  # Extract requesting server details
  server_dns=$(oc get csr $csr -o json | jq -r '.spec.username')
  server_ip=$(oc get csr $csr -o json | jq -r '.status.certificate' | base64 --decode | openssl x509 -noout -text | grep -oP '(?<=IP Address:)[^,]*')

  # Implement your verification logic here
  valid=true  # Replace with actual verification logic

  if [ "$valid" = true ]; then
    oc adm certificate approve $csr
    if [ $? -eq 0 ]; then
      log "Approved CSR: $csr from $server_dns ($server_ip) at $(date)"
      success_counter=$((success_counter+1))
    else
      log "Failed to approve CSR: $csr from $server_dns ($server_ip) at $(date)"
      send_email "Failed to approve CSR: $csr from $server_dns ($server_ip) at $(date)"
      failure_counter=$((failure_counter+1))
    fi
  else
    log "CSR $csr is not valid: $csr_details from $server_dns ($server_ip) at $(date)"
    send_email "CSR $csr is not valid: $csr_details from $server_dns ($server_ip) at $(date)"
    failure_counter=$((failure_counter+1))
  fi
done

log "CSR approval script run completed at $(date) with $success_counter successes and $failure_counter failures."
