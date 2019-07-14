
# Setup remote session, must use the admin creds
$so = New-PSSessionOption -SkipCACheck -SkipCNCheck
$s = New-PSSession -ComputerName (Read-Host 'Enter the VM public IP address') -Port 5986 -SessionOption $so -UseSSL

Enter-PSSession -Session $s

### ... continue setup remotely, TODO to fill this in...
