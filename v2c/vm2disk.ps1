#----------------------------------
#       vm2disk.ps1
#       Created by Philip Van
#       Mar 28 2016
#----------------------------------
#       Loads the PowerCLI Module
#       And prompts to connect to
#           the vCenter server to export your VMs
#----------------------------------
  
try{
    #Import the PowerCLI module
    Add-PSSnapin VMware.VimAutomation.Core
 
    #Update the title bar
    $host.ui.rawui.WindowTitle="Export your vmware virtual machine"
    
    #Importing your credential for Vmware and other
    $invocation = (Get-Variable MyInvocation).Value
    $directorypath = Split-Path $invocation.MyCommand.Path
    . $directorypath\credentials.ps1

    #Ask the user if we should connect to the vCenter server
    $ans = Read-Host "Do you want connect to a vCenter/vSphere Server $vCenterIP [Y/N]"
    if ($ans -eq "Y" -or $ans -eq "y"){
 
        #It takes some time to connect, let the user know they should expect a delay
        "Connecting, please wait.."
 
        Connect-VIServer -Server $vCenterIP -Protocol https -Username $Username -Password $Password
        if ($error.Count -eq 0) {
            Write-Host "Connect successful to $vCenterIP"
            
            $VMStatus = (Get-VM -Name $vmconverted).PowerState
            if ($VMStatus -ne "PoweredOff") {
                Write-Host "Please shutdown $vmconverted"
                exit
            }
            if ((Get-VM -Name $vmconverted  | Get-CDDrive | Where { $_.IsoPath.Length -gt 0 -OR $_.HostDevice.Length -gt 0 -or $_.RemoteDevice.Length -gt 0}).Uid -gt "") {
                $ans = Read-Host "Your $vmconverted is connecting to a CD/DVD Drive, do you want to disconnect them to continue? (Y/N)"
                if ($ans -ne "Y" -and $ans -ne "y") {exit}
            }
            Get-VM -Name $vmconverted  | get-cddrive | Where-Object {$_.IsoPath -or $_.HostDevice -or $_.RemoteDevice } |Set-CDDrive -NoMedia -Confirm:$false
            write-host "CD/DVD Drive are disconnected to your media"
            
            Write-Host "Exporting $vmconverted virtual machine to $export2folder"
            Get-VM -Name $vmconverted | Export-VApp -Destination $export2folder -Format OVF -CreateSeparateFolder
            if ($error.Count -gt 0) {
                $error.GetType()
                Write-Host "Fail to export $vmconverted"
                exit
            }
            
            Write "Export Complete..."
        }
        else{
            $error.GetType()
            Write-Host "Fail to connect to $vCenterIP"
            exit
        }
    }else{
 
        #Display the connection syntax to help the user connect manually in the future
        "Use Connect-VIServer [server] to connect when ready"
    }
}
catch {
    #Something failed. Opps
    "Failed to export your VM, Please check again your credentials"
}
