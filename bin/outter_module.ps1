$logFilePath = ".\Main_Log\Log_001.txt"
$pathToPCList = ".\bin\pcList.txt"
$pathToIpOutput = ".\bin\ToPing.txt"
$innerModuleScriptPath = ".\bin\inner_module.ps1"
$manualListHosts = ".\From_Hosts\List_Of_Manual\Manual_List.txt"

"==================================================" | Add-Content $logFilePath
(" $(Get-Date) [] [ START OF LOG - INFO ] Start of Log: " + [string](Get-Date)) | Out-File $logFilePath 
"==================================================" | Add-Content $logFilePath

$ErrorActionPreference = "Stop"
try {
    "[INFO] $(Get-Date) [] Loading List of Hosts from $($pathToPCList)....." | Add-Content $logFilePath
    $hostnames = Get-Content $pathToPCList
    "[INFO] $(Get-Date) [] Loaded Host Successfully from $($pathToPCList)."  | Add-Content $logFilePath
    "==================================================" | Add-Content $logFilePath
}
catch {
    "[ERROR] $(Get-Date) [] !!!!!"  | Add-Content $logFilePath
    "[ERROR] $(Get-Date) [] Couldn't Read Hosts from $($pathToPCList)." | Add-Content $logFilePath
    "[ERROR] $(Get-Date) [] Make sure that Path is readable by the user account running the script: '$($env:USERNAME)@$($env:USERDOMAIN)'"  | Add-Content $logFilePath
    "==================================================" | Add-Content $logFilePath
}
$ErrorActionPreference = "Continue"

$hostnames = Get-Content $pathToPCList


Clear-Content $pathToIpOutput

foreach($hostname in $hostnames){

    $ip = (Resolve-DnsName -Type A $hostname -ErrorAction SilentlyContinue).IPAddress
    $ip | Add-Content $pathToIpOutput
}

$toPingList = Get-Content $pathToIpOutput

"[INFO] $(Get-Date) [] Converting List of Hosts from $($pathToPCList) to IPv4....." | Add-Content $logFilePath
    $hostnames = Get-Content $pathToPCList
    "[INFO] $(Get-Date) [] Converted Successfully from $($pathToPCList) to file: $($pathToIpOutput)."  | Add-Content $logFilePath
"==================================================" | Add-Content $logFilePath

$iCount = 1

foreach ($ipAddy in $toPingList){
    "[COUNTER] $(Get-Date) [] Run #$($iCount)" | Add-Content $logFilePath
    if(Test-Connection $ipAddy -Quiet -Count 1){
        "[INFO] $(Get-Date) [] $(([System.Net.Dns]::GetHostByAddress($ipAddy).HostName).split(".")[0]) @ $($ipAddy) is Alive !" | Add-Content $logFilePath

        "[INFO] $(Get-Date) [] Copying the Inner Module to the Host......." | Add-Content $logFilePath

        $ErrorActionPreference = "Stop"
        try {
            Copy-Item $innerModuleScriptPath ("\\$($ipAddy)\c$\Teva\")
            ("[INFO] $(Get-Date) [] Inner Module has copied OK to Host: " + ([System.Net.Dns]::GetHostByAddress($ipAddy).HostName).split(".")[0] + " @ " +$ipAddy) | Add-Content $logFilePath
        }
        catch {
            "[ERROR] $(Get-Date) [] !!!!!"  | Add-Content $logFilePath
            "[ERROR] $(Get-Date) [] Couldn't Copy the Inner Module to the Host: $(([System.Net.Dns]::GetHostByAddress($ipAddy).HostName).split(".")[0] + " @ " +$ipAddy)"  | Add-Content $logFilePath
        }
        $ErrorActionPreference = "Continue"

        "[INFO] $(Get-Date) [] Setting Execution Policy to the remote Host...."  | Add-Content $logFilePath
        .\bin\PsExec.exe \\$ipAddy powershell Set-ExecutionPolicy Unrestricted 
        "[INFO] $(Get-Date) [] DONE!"  | Add-Content $logFilePath
        "[INFO] $(Get-Date) [] Executing Inner Module on the remote Host...."  | Add-Content $logFilePath
        .\bin\PsExec.exe \\$ipAddy powershell -file c:\teva\inner_module.ps1

        $ErrorActionPreference = "Stop"
        try {
            $CurrentHostLoopLog = Get-Content ("\\$($ipAddy)\c$\Teva\Current_Time_From_Host_" + ([System.Net.Dns]::GetHostByAddress($ipAddy).HostName).split(".")[0] + ".txt")
            $CurrentHostLoopLog | Out-File (".\From_Hosts\Current_Time_From_Host_" + ([System.Net.Dns]::GetHostByAddress($ipAddy).HostName).split(".")[0] + ".txt")
            ("[INFO] $(Get-Date) [] Reading the Log from the Host:" + ([System.Net.Dns]::GetHostByAddress($ipAddy).HostName).split(".")[0] + " @ " + $ipAddy + "... -> OK. Log Saved at 'From Hosts' Folder.") | Add-Content $logFilePath
            "[INFO] $(Get-Date) [] Inner Module is Finished. Checking if the host is synced to the correct time......" | Add-Content $logFilePath
        }
        catch {
            "[ERROR] $(Get-Date) [] !!!!!"  | Add-Content $logFilePath
            "[ERROR] $(Get-Date) [] Couldn't Run the Inner Module at the Host: $(([System.Net.Dns]::GetHostByAddress($ipAddy).HostName).split(".")[0] + " @ " +$ipAddy)"  | Add-Content $logFilePath
        }
        $ErrorActionPreference = "Continue"

        if([int]$CurrentHostLoopLog[2] -ge 0){
            if($CurrentHostLoopLog[2] -eq (Get-Date).Hour){
                "[INFO] $(Get-Date) [] $(([System.Net.Dns]::GetHostByAddress($ipAddy).HostName).split(".")[0]) Moved OK to the relevant Time-Zone." | Add-Content $logFilePath
                "==================================================" | Add-Content $logFilePath
            }else{
                "[WARNING] $(Get-Date) [] $(([System.Net.Dns]::GetHostByAddress($ipAddy).HostName).split(".")[0]) Didn't move on it own, will require to be added to automation script." | Add-Content $logFilePath
                $(([System.Net.Dns]::GetHostByAddress($ipAddy).HostName).split(".")[0]) | Add-Content $manualListHosts
                "[INFO] $(Get-Date) [] Added Host $(([System.Net.Dns]::GetHostByAddress($ipAddy).HostName).split(".")[0]) to Manual_List.txt OK !" | Add-Content $logFilePath
                "==================================================" | Add-Content $logFilePath
            }
        }else{
            "[ERROR] $(Get-Date) [] !!!!!"  | Add-Content $logFilePath
            "[ERROR] $(Get-Date) [] Couldn't Read the Inner_Module.ps1's Output Log at the Host: $(([System.Net.Dns]::GetHostByAddress($ipAddy).HostName).split(".")[0] + " @ " +$ipAddy), Script can't determine if the host moved or not."  | Add-Content $logFilePath
            "==================================================" | Add-Content $logFilePath
        }
    }else{
        "[WARNING] $(Get-Date) [] $(([System.Net.Dns]::GetHostByAddress($ipAddy).HostName).split(".")[0]) @ $($ipAddy) is DEAD XXXXXXX" | Add-Content $logFilePath
        "==================================================" | Add-Content $logFilePath
    }

    $iCount++
    $CurrentHostLoopLog = 0;
}