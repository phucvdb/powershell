#----------------------------------
#       move2aws.ps1
#       Created by Philip Van
#       Mar 27 2016
#----------------------------------
#       Move your vm's disk to AWS S3 and register them with EC2
#      
#----------------------------------
  
try{
    #Update the title bar
    $host.ui.rawui.WindowTitle="Move your VMs to AWS"
    
    #Importing your credential
    $invocation = (Get-Variable MyInvocation).Value
    $directorypath = Split-Path $invocation.MyCommand.Path
    . $directorypath\credentials.ps1

    ## Setup your profile to connect to AWS
    Set-AWSCredentials -AccessKey $aws_acckey -SecretKey $aws_secretkey -StoreAs $aws_profile
    Initialize-AWSDefaults -ProfileName $aws_profile -Region $aws_dfregiron

    #Upload your disk to S3 Bucket
    #check bucket is existing, if not the script will create a new bucket
    write-host "Checking your bucket $aws_bucketName and upload your disk to AWS S3 Bucket"
    if ((Get-S3Bucket -ProfileName $aws_profile -BucketName $aws_bucketName).BucketName -ne $aws_bucketName) {
        write-host "Your bucket $aws_bucketName is not existing, Please create one and run again this script"
        exit
    }
    $fileDirectory = "$directorypath\$vmconverted"
    $parse_results = New-Object System.Collections.ArrayList
    foreach($file in Get-ChildItem $fileDirectory) {
        $file_ext = [IO.Path]::GetExtension($file)
        $file_count = 0
        if ($file_ext -eq ".vmdk" -or $file_ext -eq ".vhd" -or $file_ext -eq ".ova") {
            #Write-S3Object -ProfileName $aws_profile -BucketName $aws_bucketName -File "$directorypath\$vmconverted\$file"
            $file_count = $file_count + 1
            $aws_osdisk = $file
            Write-Host "$aws_osdisk"
        }
    }
    if ($file_count -eq 0) {
        write-host "You have not any disk on the folder $fileDirectory, Please check again!"
        exit
    }
    elseif ($file_count -gt 1) {
        $aws_osdisk = Read-host "You have greater than 1 disk, please enter your OS Disk's name"
    }

    #Configuring IAMRoles
    write-host "Seting up your IAMRole for importing your VMs"
    $importPolicyDocument = @"
    {
        "Version":"2012-10-17",
        "Statement":[
        {
            "Sid":"",
            "Effect":"Allow",
            "Principal":{
                "Service":"vmie.amazonaws.com"
            },
            "Action":"sts:AssumeRole",
            "Condition":{
                "StringEquals":{
                    "sts:ExternalId":"vmimport"
                }
            }
        }
        ]
    }
"@
    write-host "$importPolicyDocument"
    #Checking rolename
    if ((Get-IAMRoles -ProfileName $aws_profile).RoleName -eq $aws_RoleName) {
        $ans = Read-host "$aws_RoleName Rolename is existing, do you want to continue? [Y/N]"
        if ($ans -eq "N" -or $ans -eq "n"){
            exit
        }
    }
    else {
        New-IAMRole -RoleName $aws_RoleName -AssumeRolePolicyDocument $importPolicyDocument
    }
    $rolePolicyDocument = @"
    {
        "Version":"2012-10-17",
        "Statement":[
        {
            "Effect":"Allow",
            "Action":[
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource":[
                "arn:aws:s3:::$aws_bucketName"
            ]
        },
        {
            "Effect":"Allow",
            "Action":[
                "s3:GetObject"
            ],
            "Resource":[
                "arn:aws:s3:::$aws_bucketName/*"
            ]
        },
        {
            "Effect":"Allow",
            "Action":[
                "ec2:ModifySnapshotAttribute",
                "ec2:CopySnapshot",
                "ec2:RegisterImage",
                "ec2:Describe*"
            ],
            "Resource":"*"
        }
    ]
    }
"@
    write-host "$rolePolicyDocument"
    if ((Get-IAMRolePolicies -ProfileName $aws_profile -RoleName $aws_RoleName).Contains($aws_PolicyName)) {
        $ans = Read-host "$aws_PolicyName Plolicy is existing in $aws_RoleName Rolename , do you want to continue? [Y/N]"
        if ($ans -eq "N" -or $ans -eq "n"){
            exit
        }
    }
    else {
       Write-IAMRolePolicy -RoleName $aws_RoleName -PolicyName $aws_PolicyName -PolicyDocument $rolePolicyDocument 
    }

    #configure your disk on AWS
    write-host "Configuring your Disk to import to EC2"
    $params = @"
    { \"Description\":\"Demo for VM Lift and Ship to AWS\", \"UserBucket\":{ \"S3Bucket\":\"$aws_bucketName\", \"S3Key\":\"$aws_osdisk\" } }
"@
    write-host "$params"
    #Import-EC2Image --description "Ubuntu 14.04 Thin-provisioning" --disk-container $params    
    aws ec2 import-image --description "Ubuntu 14.04 Thin-provisioning" --disk-container $params
    Get-EC2ImportImageTask
    write-host "Plase wait on the minutes for completion and check status again with Get-EC2ImportImageTask cli"
}
catch {
    #Something failed. Opps
    "Failed to move your disks to AWS, Please check again your information"
}
