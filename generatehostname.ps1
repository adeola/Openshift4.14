

param (
    [string]$IPAddress,
    [string]$ClientId,
    [string]$ScopeId
)

function GenerateCustomHostname {
    param (
        [string]$ipAddress
    )
    $hostname = "ocp" + ($ipAddress -replace '\.', '')
    return $hostname
}

function UpdateDNS {
    param (
        [string]$hostname,
        [string]$ipAddress,
        [string]$zone
    )

    $dnsServer = "your.dns.server"  # Replace with your DNS server
    $ttl = "3600"                   # Time to live for the DNS record

    $update = @"
server $dnsServer
zone $zone
update delete $hostname.$zone A
update add $hostname.$zone $ttl A $ipAddress
send
"@

    $update | nsupdate -k /path/to/your/keyfile
}

function SetDhcpReservation {
    param (
        [string]$scopeId,
        [string]$ipAddress,
        [string]$clientId,
        [string]$hostname
    )

    $existingReservation = Get-DhcpServerv4Reservation -ScopeId $scopeId -IPAddress $ipAddress -ErrorAction SilentlyContinue

    if ($existingReservation) {
        Set-DhcpServerv4Reservation -ScopeId $scopeId -IPAddress $ipAddress -ClientId $ClientId -Description $hostname -Name $hostname
    } else {
        Add-DhcpServerv4Reservation -ScopeId $scopeId -IPAddress $ipAddress -ClientId $ClientId -Description $hostname -Name $hostname
    }
}

function ConfigureLogRotation {
    $logrotateConfig = @"
/var/log/csr-approval.log {
    rotate 12
    weekly
    size 10M
    missingok
    notifempty
    compress
    delaycompress
    postrotate
        systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}
"@

    $logrotateConfigPath = "/etc/logrotate.d/csr-approval"
    $logrotateConfig | Out-File -FilePath $logrotateConfigPath -Force
}

# Main logic
$hostname = GenerateCustomHostname -ipAddress $IPAddress
$zone = "yourdomain.com"  # Replace with your DNS zone

# Set DHCP reservation
SetDhcpReservation -scopeId $ScopeId -ipAddress $IPAddress -clientId $ClientId -hostname $hostname

# Update DNS
UpdateDNS -hostname $hostname -ipAddress $IPAddress -zone $zone

# Configure log rotation
ConfigureLogRotation

# Log the action
$logFile = "C:\path\to\your\logfile.txt"
$message = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Generated hostname: $hostname for IP: $IPAddress"
$message | Out-File -Append -FilePath $logFile
