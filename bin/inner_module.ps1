$hostnameThis = hostname

$(
    ("Host: " + $hostnameThis)
    "==========="
    (Get-Date).Hour
    "==========="
    "Current Date and Time:"
    Get-Date 
    "==========="
    "Current Time Zone Set:"
    Get-TimeZone
    "==========="
    "Available Timezones:"
    Get-TimeZone -ListAvailable 
    ) *>&1 > (("\\$($hostnameThis)\c$\Teva\Current_Time_From_Host_" + $hostnameThis + ".txt"))
