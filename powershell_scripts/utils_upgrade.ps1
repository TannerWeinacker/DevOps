function vcenterconnection{
    $vcenter = "vcenter.tanner.local"
    $connection = $global:defaultviservers
    if ($connection){
        Write-Host -ForegroundColor "Green" "You are connected to" $connection
    }
    else{
        try {
            $connection = Connect-VIServer -Server $vcenter
        }
        catch [Exception]{
            $exception = $_.Exception
            Write-Host $exception
        }
    }
}

function gatherinformation{
$vmhost=Get-VMHost -Name "192.168.7.20"
$ds = Get-DataStore -Name "DataStore1-Super1"
}

#
function main_menu{
  Write-Host "==================" -ForegroundColor "Green"
  Write-Host "
  1: Power On/Off VM
  2: Change Network For VM
  3: Create New Virtual Switch
  4: Create Virtual Port Group
  5: Create Linked Clone
  6: Create Full Clone
  7: Get IP
  8: Set Static Windows IP
  9: Exit
  " -ForegroundColor "Green"
  Write-Host "==================" -ForegroundColor "Green"

    $selection = Read-Host "Enter one of the options above"
    switch($selection){
        '1'{ 
            vmpowerstate
        }
        '2'{
            changenetwork
        }
        '3'{
            networkswitch
        }
        '4'{
            portgroup
        }
        '5'{
            createlinked
        }
        '6'{
            createfull
        }
        '7'{
            Get-IP
        }
        '8'{
            windows_static
        }
        '9'{
            Disconnect-VIServer -server *
            Exit
        }


    }
}

function vmpowerstate{
    Clear-Host
    $vmlist = @(Get-VM | Select-Object -ExpandProperty Name)
    Get-VM
    $Selected_VM = Read-Host "Select the VM you would like to Turn On/Off"
    while ($vmlist -notcontains $Selected_VM) {
        Write-Host $Selected_VM "is invalid, please try again"
        $Selected_VM = Read-Host "Select the VM you would like to Turn On/Off"
    }
    $powerstate = Read-Host "Would you like to turn the VM On or Off?"

    if($powerstate -like "on"-or $powerstate -like 'On'){
        Start-VM -VM $Selected_VM
        sleep 2
        Clear-Host
        Get-VM $Selected_VM | Select-Object Name,powerstate
    }
    elseif($powerstate -like "off" -or $powerstate -like 'Off'){
        Stop-VM -VM $Selected_VM
        sleep 2
        Clear-Host
        Get-VM $Selected_VM | Select-Object Name,Powerstate
        
    }
    else {
        Write-Host "Invalid Input, please try again:"
        vmpowerstate
    }   
    main_menu
}
function addnetworkadapter{
    New-NetworkAdapter -VM $vmName -NetworkName $networkSelection -StartConnected -Confirm:$false
    Write-Host "Moving onto Changing network adapter settings" -ForegroundColor "Red"
}

function changenetwork{
    Clear-Host
    $vmlist = @(Get-VM | Select-Object -ExpandProperty Name)
   <#
    Get-VM
    $Selected_VM = Read-Host "Select the VM you like to change the network on"
    while ($vmlist -notcontains $Selected_VM) {
        Write-Host $Selected_VM "is invalid, please try again"
        $Selected_VM = Read-Host "Select the VM you like to change the network on"
    }
    #>
    Get-VM
    $vmList = Get-VM
    $vmName = Read-Host "What VM would you like the IP address for"
    foreach ($vm in $vmList) {
    if ($vm.Name -eq $vmName) {
        # VM is found, write message and end loop
        Write-Host "The VM '$vmName' has been found."
        break
    }
}
    if ($vm.Name -ne $vmName) {
        Write-Host "Name for VM is not valid"
        $vmName = Read-Host "What VM would you like the IP address for"
    }
    
    write-host -ForegroundColor Red "Available Networks `n=================="
    $networklist = Get-VirtualNetwork | Select-Object Name
    Get-VirtualNetwork | Select-Object Name
    write-host -ForegroundColor Red "=================="
    $networkSelection = Read-Host "Choose your network"
    foreach($network in $networklist){
        if ($network.Name -eq $networklist){
            Write-Host "The Network '$networkSelection' has been found"
            break
        }
    }
    if ($network.Name -eq $networklist) {
        Write-Host "Invalid Network"
        $networkSelection = Read-Host "Choose your network" 
    }

    Get-NetworkAdapter -VM $vmName | Select-Object -ExpandProperty Name
    $newnetworkadapter = Read-Host "Would you like to Add a new network Adapter?"
    if ($newnetworkadapter -like "yes"){
        addnetworkadapter

    }
    elseif($newnetworkadapter -like "no"){
        
        Write-Host "================== `nMoving onto Changing network adapter settings `n==================" -ForegroundColor "Red"
        
    }
    else{
        Write-Host "Invalid Reponse. Please input (Y/N Or Yes/No)"
      $newnetworkadapter = Read-Host "Would you like to Add a new network Adapter?"  
    }

    $networkadapterlist = Get-NetworkAdapter -VM $vmName | Select-Object -ExpandProperty Name
    Get-NetworkAdapter -VM $vmName | Select-Object -ExpandProperty Name
    $networkadapter = Read-Host "Select a network adapter"
    foreach($adapter in $networkadapterlist){
        if($networkadapter -eq $networkadapterlist){
            Write-Host "The Network Adapter'$networkadapter' has been found"
            break
        }
    }

    Get-VM $vmName | Get-NetworkAdapter -Name $networkadapter | Set-NetworkAdapter -NetworkName $networkSelection
    main_menu
}

function networkswitch{
    gatherinformation
    $newswitch = Read-Host "What would you like to name the new switch?"
    $currentswitches = Get-VirtualSwitch
    #Check to see if the Switch Exists
    while ($currentswitches){
        if($currentswitches -contains $newswitch){
                Write-host "A virtual switch with the name '$newswitch' already exists. Please enter a new name:"
                $currentswitches = $false
        }
        else{
            try{
                New-VirtualSwitch -VMHost $vmhost -Name $newswitch
                break
            }
            catch [VMware.VimAutomation.ViCore.Validation.ValidationException]{
                Write-Error "Error: $($_.Exception.Message)"
        }
        }
    }
           main_menu

    }
 
function portgroup{
    $newportgroup = Read-Host "What would you like to name the new port group?"
    $currentportgroups = Get-VirtualPortGroup
    while ($currentportgroups -contains $newportgroup){
        $newportgroup = Read-Host "A virtual Port Group with the name '$newportgroup' already exists. Please enter a new name:"
        $currentportgroups = Get-VirtualPortGroup -Name $newportgroup -ErrorAction SilentlyContinue
    }
    Get-VirtualSwitch
    $switch = Read-Host "What Virtual Switch would you like to make the port group for"

    New-VirtualPortGroup -VirtualSwitch $switch -Name $newportgroup

    main_menu
}

function Get-IP{
    Clear-Host
    Get-VM
    $vmList = Get-VM
    $vmName = Read-Host "What VM would you like the IP address for"
    foreach ($vm in $vmList) {
    if ($vm.Name -eq $vmName) {
        # VM is found, write message and end loop
        Write-Host "The VM '$vmName' has been found."
        break
    }
}
    $IpAddress = Get-VM $vmName -ErrorAction SilentlyContinue | Select-Object @{N="IP Address";E={@($_.Guest.IPAddress[0])}} | Select-Object -ExpandProperty "IP Address"
    $Mac = Get-VM $vmName -ErrorAction SilentlyContinue | Get-NetworkAdapter -Name "Network adapter 1" | Select-Object -ExpandProperty MacAddress

    $msg = "{0} hostname={1} mac={2}" -f $IpAddress,$vmName,$Mac

    Write-Host $msg
    # If the loop completes and the VM is not found, prompt the user to try again
    if ($vm.Name -ne $vmName) {
        Read-Host "The VM '$vmName' was not found. Press Enter to try again."
    }   
main_menu
}

# Linked Clone
function createlinked{
    $vmhost=Get-VMHost -Name "192.168.7.20"
    $ds = Get-DataStore -Name "DataStore1-Super1"
    Get-VM | Select-Object -ExpandProperty Name
    $vmList = Get-VM
    $vmName = Read-Host "What VM would you like to pick"
    foreach ($vm in $vmList) {
    if ($vm.Name -eq $vmName) {
        # VM is found, write message and end loop
        Write-Host "The VM '$vmName' has been found."
        break
    }
    }
    if ($vm.Name -ne $vmName){
        write-Host "Invalid Request"
        $vmName = Read-Host "What VM would you like to pick"
    }
    $snapshot = Get-Snapshot -VM $vmName -Name "Base"
    #selectfolder
    $newvmname = Read-host -Prompt "What is the new VM name"
    $linkedclone = "{0}.linked" -f $vm.name
    $linkedvm = New-VM -LinkedClone -Name $newvmname -VM $vmName -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds
    #-Location $folder would go on to this to specify a folder
    Get-VM
    Write-Output "Moving on to creating New VM"
    main_menu
}

function createfull{
    $vmhost=Get-VMHost -Name "192.168.7.20"
    $ds = Get-DataStore -Name "DataStore1-Super1"
    Get-VM
    $vmList = Get-VM
    $vmName = Read-Host "What VM would you like to pick"
    foreach ($vm in $vmList) {
    if ($vm.Name -eq $vmName) {
        # VM is found, write message and end loop
        Write-Host "The VM '$vmName' has been found."
        break
    }
    }
    if ($vm.Name -ne $vmName){
        write-Host "Invalid Request"
        $vmName = Read-Host "What VM would you like to pick"
    }
    #selectfolder
    $snapshot = Get-Snapshot -VM $vm -Name "Base"
    $linkedclone = "{0}.linked" -f $vm.name
    $linkedvm = New-VM -LinkedClone -Name $linkedclone -VM $vmName -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds	
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
    main_menu
}

function windows_static{
    Clear-Host
    Get-VM
    $vmList = Get-VM
    $vmName = Read-Host "What VM would you like to assign an IP for"
    foreach ($vm in $vmList) {
    if ($vm.Name -eq $vmName) {
        # VM is found, write message and end loop
        Write-Host "The VM '$vmName' has been found."
        break
    }
} 
if ($vm.Name -ne $vmName) {
        Read-Host "The VM '$vmName' was not found. Press Enter to try again."
    } 
$Guest_Username = "Administrator"
$Credential = Read-Host -Prompt 'What is the password for the account' -AsSecureString
# Set the VMs IP
Invoke-VMScript -VM $vmName -ScriptText "netsh interface ip set address 'Ethernet0' static 10.0.5.6 255.255.255.0 10.0.5.2" -GuestUser $Guest_Username -GuestPassword $Credential
# Set the VMs DNS
Invoke-VMScript -VM $vmName -GuestUser $Guest_Username -GuestPassword $Credential -ScriptText "netsh interface ipv4 add dns 'Ethernet0' 10.0.5.2 index=1"
#Check Config
Invoke-VMScript -VM $vmName -GuestUser $Guest_Username -GuestPassword $Credential -ScriptText "ipconfig /all"
}

# Full Clone
Clear-Host
vcenterconnection
main_menu 
