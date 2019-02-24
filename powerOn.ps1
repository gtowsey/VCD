<#
.SYNOPSIS
    Powers on Virtual Machines in a vCloud environment
.DESCRIPTION
    Powers on Virtual Machines in a vCloud environment asynchronously. if it fails it sends an email to the end user with the error message.
.NOTES
    File Name  : powerOn.ps1
    Author     : Glen Towsey - Datacom
    Date       : 21/02/2019
.LINK
    https://github.com/gtowsey/VCD
#>

### secton for handling passwords. password is encrypted using the generateEncryptedPassword.ps1. only the account that encrypts can use.
$username = ''
$password_file = $PSScriptRoot + "\Password.txt"

### log location for erros
$log_location = $PSScriptRoot + "\PowerOnLog.txt"

### csv location for VM's to use
$csv_location = $PSScriptRoot + "\vmList.csv"

### modify depending on location you wish to connect to
$vCloud_server_name = ""

### enter organisation you wish to connect to
$vCloud_organisation = ''

### smtp settings
[string]$smtprelay = ""
[string]$smtpfrom = ""
[string]$smtpto = ""
[string]$smtpsubject = ""	


function send-email ($body){
    try{
        Send-MailMessage -From $smtpfrom -To $smtpto -Subject $smtpsubject -smtpServer $smtprelay -body $body
    }
    catch{
        add-content $log_location "$(get-date) unable to send email wiuth the following error"
        add-content $log_location $_.Exception.message
    }
}

###Check if teh log csv exists elseattempt to create the csv.fail if user doesnt have rights etc.
if (!(test-path $log_location)) {

    try {
        out-file $log_location
    }
    catch {
        #add-content $log_location "$(get-date) unable to create log file in selected path"
        send-email "$(get-date) unable to create log file"
        exit
    }
}

###attempt to import csv data. fail wcript if not found
try {
    $csv = import-csv $csv_location
}
catch {
    add-content $log_location "$(get-date) unable to import csv"
    send-email "$(get-date) unable to import csv"
    exit
}

###download powerCLI module of at least version 5.0.1 from the VMWare website
###confirm module exists
Try {
    import-module vmware.vimautomation.cloud
}
catch {
    add-content $log_location "$(get-date) unable to import vmware module"
    send-email "$(get-date) unable to import vCloud module"
    exit
}

###attempt to import password file
try {
    $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, (Get-Content $password_file | ConvertTo-SecureString)
}
catch {
    add-content $log_location "$(get-date) unable to open password file"
    send-email "$(get-date) unable to open password file"
    exit
}

#attempt to connect to vCloud server. exit if failed
try {
    connect-Ciserver $vCloud_server_name -credential $credential -org $vCloud_organisation | out-null
}
catch {
    add-content $log_location "$(get-date) organisation or credentials incorrect"
    send-email "$(get-date) organisation or credentials incorrect"
    exit
}

#blank arrays for handlign responses
$results = @()
$errors = @()

###loop through each VM and atatmept to power on. errors are captured and stored.
###Commands are filed async rather than waiting to speed up
foreach ($line in $csv) {

    try {
        $ErrorActionPreference = "Stop"
        $results += Get-CIVM -name $line.vm | Start-CIVM -confirm:$false -RunAsync
    }
    catch {
        $errors += [PSCustomObject]@{
            VM    = $line.vm
            error = $_.Exception.message
        }
    }

}

#blank arrays for handlign responses
$FailedTasks = @()

###loop through async tasks and confirm all have finished. add any errored 
foreach ($result in $results) {

    while (!((get-task -id $result.id).FinishTime)) {
        start-sleep -seconds 5
    }

    $CompletedTask = get-task -id $result.id
    if ($CompletedTask.state -eq 'error') {
        $FailedTasks += $CompletedTask
    }
    
}

###loop through the emails to build up a somewhat valid email
$body += "The following VM's failed to start pre start task:"
$body += $($errors  | out-string -width 300)
$body += "The followinng VM's failed post start task: `n"
foreach ($failedtask in $FailedTasks) {
    $body += $FailedTasks.description + "`n"
    $body += $FailedTasks.extensiondata.error.message + "`n"
}


### send email with any errors
if ($errors) {
    add-content $log_location $($errors  | out-string -width 300)
    send-email $body
}

### disconnect from vcloud server
Disconnect-CIServer -confirm:$false

### cleanly exit
exit