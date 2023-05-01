#A script to create linked clones
#Created by Tanner Weinacker
#Last Edited 2/27/23
#Defining vcenter name 


#Check to see if vcenter is already connected
function checkconnection{
$vcenter = "vcenter.tanner.local"
if($global:defaultviservers.name -contains $vcenter){
	#If the connection is already established, the output will be the connection
	#$global:defaultviserver | where{$_.Name -eq $vcenter}
	Write-Output "You are already Connected to:" $global:defaultviserver.name
	pause
	gatherinformation

}
else
{
	#If the connection is not established, it will connect
	selectserver
	Connect-VIServer -Server $vcenter
	gatherinformation
	#Write-Output "Start a new connection"
}
}


# Select a vCenter Host you would like to connect to
function selectserver{
$vcenter = Read-Host -Prompt "Enter in the vcenter host or IP you would like to manage:(default is vcenter.tanner.local)"
if($vcenter -ne ""){
	Write-Output "You have selected" $vcenter
	Connect-VIServer -Server $vcenter
	gatherinformation
}
else{
	$vcenter="vcenter.tanner.local"
	checkconnection
}
}



# Gather information for this particular lab
function gatherinformation{
$vmhost=Get-VMHost -Name "192.168.7.20"
$ds = Get-DataStore -Name "DataStore1-Super1"
showvm
}



#Show VM will list all of the VM and check if the datastore is listed correctly
function showvm{

Write-Output "List of VMs:"

Get-VM 
#| Select-Object -ExpandProperty Name | Select-Object PowerState, NumCpu, MemoryGB

$vmlist = Get-VM | Select-Object -ExpandProperty Name
#Expand property is needed here because there is more than on object in the Get-VM function. 

Write-Output "Datastore:"
Get-Variable -Name ds -ValueOnly | Select-Object name
if($ds -notlike "DataStore1-Super1"){
	Write-Output "Datastore is not listed properly. Trying again."
	gatherinformation
}
else{
	createnewcheck
}
}


#Get the information of what Host you would want to create the new VM on

# Select a vCenter Host you would like to connect to
function selecthost{
$vmhost = Read-Host -Prompt "Enter in the vcenter host or IP you would like to manage:(default is 192.168.7.20)"
if($vmhost -ne ""){
	Write-Output "You have selected" $vmhost
}
else{
	$vmhost="192.168.7.20"
	Write-Output "You have selected" $vmhost
}
}

#Get the information of what Datastore you would want to host your VM on 

function selectdatastore{
$ds = Read-Host -Prompt "Enter in where you want to store the VM: (default is DataStore1-Super1)"
if($ds -ne ""){
	Write-Output "You have selected" $ds
}
else{
	$ds = Get-DataStore -Name "DataStore1-Super1"
	Write-Output "You have selected" $ds
}
}
<#
#Select the folder you want to store the VM in
function selectfolder{
$folderlist = Get-Folder -Type vm
Write-Host $folderlist
$folder = Read-Host "What folder would you like to store your VM in"
if($folderlist -contains $folder){
	Write-Host "You have selected" $folder
	Pause
}
else{
	Write-Host "The folder you have selected" $folder "is invalid. Try Again"
	Pause
	folder
}
}
#>

#Createnewcheck will check to see if the VM provided is apart of the list to choose from
function createnewcheck{
$vmname = Read-host -Prompt "What is the VM you are picking"
if($vmlist -contains $vmname){
	createnew
}
else{
	cls
	Write-Output "The name "$vmname" is not valid. Please try again"
	showvm
}
}



#User Will decide if they are creating a linked or full clone
function userdecision{
$userselection = Read-Host "Would you like to create a [l]inked for [f]ull clone?"
if($userselection -like "F*" -or $userselection -like "f*"){
	Write-Host "You have selected Full Clone"
	createfull
}
elseif($userselection -like "L*" -or $userselection -like "l*"){
	Write-Host "You have selected Linked clone"
	createlinked
}
else{
	Write-Host "You have selected neither a Linked for Full Clone. Please Try again."
	createnew
}
}



#Createnew will create a new vm
function createnew{
$vm = Get-VM -Name $vmname
$snapshotlist = Get-Snapshot -VM $vm | Select-Object -ExpandProperty name
Write-Output $snapshotlist
$snapshot = Read-Host "What snapshot would you like to use"
if ($snapshotlist -contains $snapshot){
	Write-Output "Moving on to creation selection"
	userdecision
}
else{
	Write-Output "The name "$snapshot" is not listed, please list a valid snapshot name"
	pause
	#Get-Snapshot -VM $vm | Select-Object name
	createnew
}
}



# Creating a linked clone
function createlinked{
selecthost
selectdatastore
#selectfolder
$newvmname = Read-host -Prompt "What is the new VM name"
$linkedclone = "{0}.linked" -f $vm.name
$linkedvm = New-VM -LinkedClone -Name $linkedclone -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds
#-Location $folder would go on to this to specify a folder
Get-VM
Write-Output "Moving on to creating New VM"
}


#Creating a full clone
function createfull{
selecthost
selectdatastore
#selectfolder
$linkedclone = "{0}.linked" -f $vm.name
$linkedvm = New-VM -LinkedClone -Name $linkedclone -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds	
Get-VM
Write-Output "Moving on to creating Full VM"

$newvmname = Read-host -Prompt "What is the new VM name"
$newvm = New-VM -Name $newvmname -VM $linkedvm -VMHost $vmhost -Datastore $ds
$newvm | New-Snapshot -Name "base"
Get-VM
pause
Write-Output "Removing LinkedVM now"
$linkedvm | Remove-VM
Get-VM
}

cls
checkconnection
