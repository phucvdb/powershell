#$vCenterIP = Read-Host "Please type vCenter/vSphere IP or HostName"
#$Username = Read-Host "Enter your admin account"
#$Password = Read-Host -assecurestring "Enter your password"
$vCenterIP = ""
$Username = "administrator"
$Password = ""
$vmconverted = "Ubuntu_aws"
$export2folder = "E:\scripts"

#AWS Credential
$aws_acckey = ""
$aws_secretkey = ""
$aws_profile = ""
$aws_dfregiron = "ap-southeast-1"
$aws_bucketName = "vm-lift-ship"
$aws_RoleName = "vmimport"
$aws_PolicyName = "vmimport"
$aws_Disk_Format = "VMDK"
$aws_ClientToken = "CustomUbuntu_VMLS_" + (Get-Date)
$aws_Platform ="Linux"

#Azure Information
$az_storageacc = ""
$az_container = "vhds"
$az_platform = "Linux"