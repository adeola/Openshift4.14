Read me DHCP File
Step-by-Step Deployment Guide

    Prepare the PowerShell Script:

    Create a PowerShell script named GenerateHostname.ps1 with the script provided:

    Configure Task Scheduler:

    Open Task Scheduler:
    Open Task Scheduler on your Windows DHCP server.

    Create a New Task:
    In the right-hand Actions pane, click on "Create Task."

    General Tab:
        Name: DHCP Dynamic Hostname Assignment
        Description: Assigns dynamic hostnames to DHCP clients based on IP addresses.
        Security Options: Ensure the task is set to run with highest privileges.

    Triggers Tab:
        Click "New."
        Begin the task: "On an event."
        Log: Microsoft-Windows-DHCP Server Events
        Source: Microsoft-Windows-DHCP-Server
        Event ID: 10 (This event ID is typically used for lease granted events, but ensure this matches your environment’s logs.)

    Actions Tab:
        Click "New."
        Action: Start a program.
        Program/script: powershell.exe
        Add arguments: -File "C:\path\to\GenerateHostname.ps1" -IPAddress $(DhcpServerv4LeaseIPAddress) -ClientId $(DhcpServerv4LeaseClientID) -ScopeId $(DhcpServerv4ScopeId)

    Conditions and Settings Tabs:
    Configure according to your preferences.

    Save the Task:

	Grant Permissions:

	Ensure that the user account running the Task Scheduler task has sufficient permissions to run the PowerShell script and modify DHCP reservations. Typically, this account needs administrative privileges on the DHCP server.

Deploy the Script:

    Save the GenerateHostname.ps1 script to C:\path\to\GenerateHostname.ps1 (ensure the directory exists and is accessible by the task).
    Ensure that PowerShell script execution is allowed on the server by running:

    powershell

    Set-ExecutionPolicy RemoteSigned

Verify the Script:

    Run a test by manually executing the script with sample parameters to ensure it works correctly.
    Example command to test:

    powershell

    .\GenerateHostname.ps1 -IPAddress "192.168.1.100" -ClientId "00-11-22-33-44-55" -ScopeId "192.168.1.0"

Monitor Logs:

    Check the log file at C:\path\to\your\logfile.txt for entries to verify the script is running and generating hostnames correctly.
    Ensure log rotation is configured to manage the log file size.



2. DNS Dynamic Updates

Microsoft DHCP servers can be configured to perform dynamic updates to DNS records. This ensures that each DHCP client's hostname is registered in DNS.

    Enable DNS Dynamic Updates:
        Open the DHCP management console.
        Right-click on the DHCP server or scope and select "Properties."
        Go to the "DNS" tab.
        Check "Enable DNS dynamic updates according to the settings below."
        Select "Always dynamically update DNS A and PTR records."

    Configure DHCP to update DNS:
        Ensure that the DHCP server has permissions to update DNS records.
        In an Active Directory environment, this is usually configured by default.