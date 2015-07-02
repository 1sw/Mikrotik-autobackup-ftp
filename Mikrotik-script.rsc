# Enable FTP service only from addresses 194.228.196.5
# Enter the IP address of your own machine
/ip service
set ftp address=194.228.196.5/32
enable ftp 

# NTP Client for time synchronization
/system ntp client
set enabled=yes primary-ntp=195.113.144.201 secondary-ntp=195.113.144.238

# Setting the time zone, adjust it according to your location
/system clock
set time-zone-name=Europe/Prague

# Adding a user backup with limited rights only for FTP.
/user group
add name=backup policy="ftp,sensitive,!local,!telnet,!ssh,!reboot,!read,!write,!poli\
    cy,!test,!winbox,!password,!web,!sniff,!api"

# Limit backup user to access only from address 194.228.196.5.
# Enter the IP address of your own machine
# Set a secure password.
/user
add address=194.228.196.5/32 group=backup name=backup
set backup password=12345

# Creating scripts for creating backups.
/system script
add name=backup2 policy=ftp,reboot,read,write,policy,test,password,sniff source=\
    "/export file=zaloha.rsc"
add name=backup policy=ftp,reboot,read,write,policy,test,password,sniff source=\
    "/system backup save name=zaloha.backup"

# Set automatic execution of scripts.
/system scheduler
add interval=1w name="System Backup" on-event=backup policy=read,write,test \
    start-date=jul/20/2009 start-time=23:00:00
add interval=1w name="System Backup 2" on-event=backup2 policy=read,write,test \
    start-date=jul/20/2009 start-time=23:15:00

