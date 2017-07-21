# Clears all event logs on a system
Get-EventLog -LogName * | ForEach { Clear-EventLog $_.Log }
