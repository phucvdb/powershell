#----------------------------------
#       move2az.ps1
#       Created by Philip Van
#       Mar 27 2016
#----------------------------------
#       Loads the PowerCLI Module and move your disk to Azure Storage Account
#
#----------------------------------
  
try{
    #Update the title bar
    $host.ui.rawui.WindowTitle="Move your VMs to Azure Storage Account"
    Write-host "Loading Microsoft virtual machine convertor Module"
    Import-Module "C:\Program Files\Microsoft Virtual Machine Converter\MvmcCmdlet.psd1"
    Set-ExecutionPolicy RemoteSigned

    #Importing your credential
    $invocation = (Get-Variable MyInvocation).Value
    $directorypath = Split-Path $invocation.MyCommand.Path
    . $directorypath\credentials.ps1
    
    #Authen your account with Azure Cloud
    Add-AzureAccount

    #Convert your vmdk disk to vhd format
    Write "Converting your Vmware vmdk Disk to vhd"
    if (!(Test-AzureName -Storage $az_storageacc)) {
        write-host "Your Storage Account $az_storageacc isn't existing, Please register one and try again!"
        exit
    }
    $fileDirectory = "$directorypath\$vmconverted"
    $parse_results = New-Object System.Collections.ArrayList
    $file_count = 0
    foreach($file in Get-ChildItem $fileDirectory) {
        $file_ext = [IO.Path]::GetExtension($file)
        if ($file_ext -eq ".vmdk") { 
            ConvertTo-MvmcVirtualHardDisk -SourceLiteralPath "$directorypath\$vmconverted\$file" -DestinationLiteralPath "$directorypath\$vmconverted\" -VhdType DynamicHardDisk -VhdFormat Vhd           
            $file_count = $file_count + 1
            $az_osdisk = $file
            Write-Host "$az_osdisk"
        }
    }
    if (!(test-path -path "$directorypath\$vmconverted\*.vhd")) {
        write-host "You have not any disk on the folder $fileDirectory, Please check again!"
        exit
    }
    if ($file_count -gt 1) {
        $az_osdisk = Read-host "You have greater than 1 disk, please enter your OS Disk's name"
    }

    #Upload your vhd to Azure Storage Account
    
    foreach($file in Get-ChildItem $fileDirectory) {
        $file_ext = [IO.Path]::GetExtension($file)
        if ($file_ext -eq ".vhd") { 
            Add-AzureVhd -Destination "https://$az_storageacc.blob.core.windows.net/$az_container/$file" -LocalFilePath "$directorypath\$vmconverted\$file"
            #Register VHD to Azure Virtual machine
            if ($az_osdisk -eq $file) {
                Add-AzureDisk -DiskName 'myosdisk' -MediaLocation "https://$az_storageacc.blob.core.windows.net/$az_container/$file" -Label 'myosdisk' -OS $az_platform
            }
            else {
                Add-AzureDisk -DiskName 'mydatadisk' -MediaLocation "https://$az_storageacc.blob.core.windows.net/$az_container/$file" -Label 'mydatadisk'
            }
            Write-Host "$file is uploading"
        }
    }
    
    #Creating a VM from Uploaded VHDs


}
catch {
    #Something failed. Opps
    "Failed to move your disks to AWS, Please check again your information"
    write-host "$error.GetType()"
}