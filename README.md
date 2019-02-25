PAYG Power Cycle Script
=======================

Purpose
-------

The purpose of the PAYG Power Cycle script is to provide an automated way for
clients to power cycle VM’s.

The script is intended to be used with a scheduled job and configured to power
off and on at set times each day.

Pre-Requisites
--------------

The following are required in order for the script to work.

-   A Windows 2008 R2 server or later

-   PowerShell version 5 or later (visit this link for instructions:
    <https://docs.microsoft.com/en-us/powershell/scripting/install/installing-windows-powershell?view=powershell-6>
    )

-   The server has access to the  vCloud servers.
  

-   An account with the “Organisation Administrator” role to the organisation
    containing the VM’s

-   The latest version of VMWare PowerCLI ensuring that the vCloud plugins are
    installed.

-   An SMTP server accessible from the server the script is running on

-   An account on the windows server with the ability to create scheduled tasks,
    execute scripts and use the SMTP server. Note this can be the same as the
    service account to connect to vCloud but this isn’t a requirement.

-   If the graceful shutdown option is used the VM must have VMWare tools
    running on the VM.

Deployment
----------

The following section outlines deploying the script

### Download

The latest version of the script and required components can be downloaded from
<https://github.com/gtowsey/VCD>


Click on the clone or download button and download to zip


Once downloaded extract the contents to a folder.

### Encrypt Password

Right click the GenerateEncryptedPassword.ps1 file form the extracted folder and
click run with PowerShell

Once the script starts, it will ask for the user’s credentials.

IMPORTANT!!!

Note that these credentials are for the user or service account that will be
connecting to vCloud director. Note that the encrypted file can only be
de-crypted by the user that encrypts it. This is important as whatever account
encrypts the password must be used to execute the script. In the event that a
service account will be used, that service account must log in to encrypt the
password.

A new file will appear in the folder called password.txt. This is encrypted and
is used to connect to the vCloud servers.

### Update VM List

In the unzipped folder is a file called vmList.csv. This file contains the list
of VM’s that will be turned on or turned off. Update this list to contain the
VM’s that need to be power cycled.

The GracefulShutdown option dictates whether the VM should be hard powered off
(i.e. the equivalent of killing the power to the VM) or shutdown gracefully
(i.e. by issuing a shutdown command at the OS level)

IMPORTANT!!!

The script will work with only one location and one organisation at a time. If
multiple organisations are required, the folder can be copied to a new location
and the VM list and script updated to cater for this.

Ensure the file looks like this at the end of any modification


### Update Configuration Settings

Each script has a settings section that needs to be updated before the script is
run. This is located at the top of the script.


The variables that need to be updated are listed below:

| Variable              | Description                                                                                                                                                       |
|-----------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| \$username            | The username of the account to connect to vCloud Director with                                                                                                    |
| \$vCloud_server_name  | The server address to connect to 
                      |
| \$vCloud_organisation | The organisation to connect to.
                      |  
| \$smtprelay           | The ip address or dns name of the smtp server                                                                                                                     |
| \$smtpfrom            | The sender of any email addresses                                                                                                                                 |
| \$smtpto              | The receiver of the email address                                                                                                                                 |
| \$smtpsubject         | The subject of the email address                                                                                                                                  |

### Testing

At this point, the script is ready to be ran.

In order to confirm all settings are working either run against a test VM in
vCloud or alternatively perform the opposite action against a VM (if a VM
is turned off attempt to turn off, if its turned on attempt to turn on.)

If the second option is completed an email should be sent outlining that the
action cannot be performed due to the state of the VM.

### Setting up the scheduled task

Open the task scheduler and click on create task.


Click on change user to choose the account that is going to run the script. Note
this must be the account that encrypted the vCloud director credentials.

Ensure the run whether user is logged on or not and run with highest privileges
is ticked.

Click on the actions tab and click on new

In the Program/script box enter "PowerShell."

In the Add arguments (optional) box enter the value .\\pwerOn.ps1 for the
powerOn scheduled task and powerOff for the power off task.

Then, in the Start in (optional) box, add the location of the folder that
contains your PowerShell script. In this example, the script is in a folder
C:\\Users\\gtowsey\\vCloud\\CustomerExamples

On the triggers page we set up the schedule of the script.

For a job configured to run at 8am Monday to Friday the below settings will
work.

Finally give the script a name and click ok.

The job can now be run either manually or will be configured at 8am each day.

Repeat the steps to configure the power off script.

If multiple organisations are required

Troubleshooting
---------------

In the event of an error the script is designed to both add to the log file
found in the script folder as well as send an email to the configured end user.

In the event that the email server is unable to be found or cannot send emails,
only the log will contain an error.

### SMTP server not found

If the smtp server is not found the logs will contain a record similar to the
below


Ensure that the smtp server is reachable from the script execution server

### Log file cannot be created

An email will be received saying “unable to create log file”

Ensure the account executing the script has write access to the folder it’s
being executed from.

### CSV cannot be imported

If the csv containing the VM’s cannot be imported an email and a log record will
be created saying “unable to import csv”

Ensure the csv exists in the folder and is in the correct csv format

### vCloud Module is not installed

If the vCloud module is not installed on the local VM an email and log record
will be created with the following error “unable to import vCloud module.”

Ensure the VMWare PowerCLI module is installed and the vCloud plugins have been
included.

### Password file missing

In the event the password file is missing an error will be returned stating
“unable to open password file”

Ensure the password.txt file exits in the folder. If it’s not found use the
GenerateEncryptedPassword.ps1 to regenerate.

### Unable to connect to vCloud Director

In the event that the vCloud server cannot be contacted, an error message will
be generated stating “organisation or credentials incorrect”

Ensure the vCloud server name is correct in the settings of the script and is
reachable from the server. Also, ensure the account provided can log in to the
vCloud server.

### Unable to find VM

In the event a VM cannot be found in the organisation. The script will continue
to action all other requests but take note of the failed VM.

In this case an email will be received similar to the below example:

To resolve ensure the VM belongs in the organisation and the user account.

### VM is not running

In the event a VM is currently turned off and the script attempts to turn the VM
of again the following error will be created.

### VMWare Tools not running

In the event the garcefulShutdown option is used the VM must have VMWare tools
running on the VM.

If tools is not running, the VM will not be shut down and the following error
will be generated.
