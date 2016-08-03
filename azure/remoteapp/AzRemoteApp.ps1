#----------------------------------
#       AzRemoteApp.ps1
#       Created by Philip Van
#       Aug 03 2016
#----------------------------------
#       Creating a RemoteApp Collection on Azure
#      
#----------------------------------


try{
    #Update the title bar
    $host.ui.rawui.WindowTitle="Creating a PoC of Azure RemoteApp"
    Write-host "Demo env will be starting with a paid subscription at least 15$ per user / Month"
    Write-host "Please reference the Azure website for detail information"
    Set-ExecutionPolicy RemoteSigned
    
    #Importing the bootstrap
    $invocation = (Get-Variable MyInvocation).Value
    $directorypath = Split-Path $invocation.MyCommand.Path
    . $directorypath\bootstrap.ps1
        
    #Authen your account with Azure Cloud
    Add-AzureAccount
    
    # Getting the administrative privillige of your domain
    $cred = Get-Credential $admin_acc

    #creating a Remoteapp collection
    Write-host "creating a Azure Remoteapp Collection"
    New-AzureRemoteAppCollection –CollectionName $Colname –ImageName $ImageName –Plan Basic -VNetName $VNetName -SubnetName $SubnetName –Domain $Domain –Credential $cred -Description "PoC integrated with your domain (on-premise)"
    Write-host "Your Azure Remoteapp Collection is created"

    #Publish an application to Azure remoteapp Collection
    #Publish-AzureRemoteAppProgram -CollectionName $Colname -FileVirtualPath "" [-CommandLine <String> ] -DisplayName "" 
}
catch {
    #Something failed. Opps
    "Failed to create Azure RemoteApp PoC ENV"
    write-host "$error.GetType()"
}
