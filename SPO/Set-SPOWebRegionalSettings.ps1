# Script: 
#
# Description: Gets all sites under the supplied site and changes its regional and culture settings to the supplied values
#
# Time Zone IDs - You can locate the timezone ID at # https://msdn.microsoft.com/library/microsoft.sharepoint.spregionalsettings.timezones.aspx
# 19 is adelaide
#
# IMPORTANT: This is recursive and will change them all!
# 
# Created by Daniel Brown - http://www.danielbrown.id.au
# Thanks to Ivan Yankulov for his Get-SPOAllWebs cmdlet - http://www.sptrenches.com/2015/04/script-to-get-all-webs-in-sharepoint.html

[CmdletBinding()]
Param(
    [parameter(Mandatory=$true)]
    [string]$SiteUrl,
    [parameter(Mandatory=$true)]
    [string]$UserName,
    [parameter(Mandatory=$true)]
    [string]$PassWord,
    [parameter(Mandatory=$true)]
    [string]$NewCulture,
    [parameter(Mandatory=$true)]
    [int]$NewTimeZoneID

)
BEGIN{
    function Set-SPOWebRegionalSettings
    {
        Param(
        [Microsoft.SharePoint.Client.ClientContext]$Context,
        [Microsoft.SharePoint.Client.Web]$RootWeb,
        [string]$NewCulture,
        [int]$NewTimeZoneID
        )

        $Webs = $RootWeb.Webs
        $Context.Load($Webs)
        $Context.ExecuteQuery()

        # set parents webs as well
        SetRegionalSettings $RootWeb $NewCulture $NewTimeZoneID
        ForEach ($sWeb in $Webs)
        {
            # Added by DB, Change regional Settings
            SetRegionalSettings $sWeb $NewCulture $NewTimeZoneID
            Set-SPOWebRegionalSettings -RootWeb $sWeb -Context $Context -NewCulture $NewCulture -NewTimeZoneID $NewTimeZoneID
        }
    }
    Add-Type -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll" | Out-Null
    Add-Type -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" | Out-Null


    function SetRegionalSettings
    {
        Param(
            [Microsoft.SharePoint.Client.Web]$sWeb,
            [string]$NewCulture,
            [int]$NewTimeZoneID
            
        )

        $ctx.Load($sWeb.RegionalSettings);
        $ctx.Load($sWeb.RegionalSettings.TimeZone);
        $ctx.ExecuteQuery();

        Write-Host "========================================"
        Write-Output "Regional Settings for Site: $($sWeb.Title)"
        Write-Host "Current Settings:"
        $oldtzid = $sWeb.RegionalSettings.TimeZone.Id
        $oldLCID = $sWeb.RegionalSettings.LocaleId
        Write-Output "* Current TimeZone: $($sWeb.RegionalSettings.TimeZone.Description)" 
        Write-Output "* Current LocaleId: $($sWeb.RegionalSettings.LocaleId)" 

        # update site settings
        # =====================================================================

        # load the new time zone
        $tz = $sWeb.RegionalSettings.TimeZones.GetById($NewTimeZoneID)
        $ctx.Load($tz);
        $ctx.ExecuteQuery();
       
        #set the time zone
        $sWeb.RegionalSettings.TimeZone = $tz

        #set the culture
        $culture=[System.Globalization.CultureInfo]::CreateSpecificCulture($NewCulture)
        $sWeb.RegionalSettings.LocaleId=$culture.LCID

        #update web
        $sWeb.RegionalSettings.Update()
        $sWeb.Update();
        $ctx.ExecuteQuery();

        #refresh
        $ctx.Load($sWeb);
        $ctx.Load($sWeb.RegionalSettings);
        $ctx.Load($sWeb.RegionalSettings.TimeZone);
        $ctx.ExecuteQuery();
        $newtzid = $sWeb.RegionalSettings.TimeZone.Id
        $newLCID = $sWeb.RegionalSettings.LocaleId

        if ($newtzid -ne $oldtzid)
        {
            Write-Host "-Timezone change detected!" -foreground red
            $updated = $true
        }

        if( $newLCID -ne $oldLCID)
        {
            Write-Host "-Locale change detected!"  -foreground red
            $updated = $true
        }

        #output
        if($updated -eq $true)
        {
            Write-Host "Updated Settings"
            Write-Host "- New TimeZone:" $sWeb.RegionalSettings.TimeZone.Description
            $c1 = [System.Globalization.CultureInfo]::GetCultureInfo([int]$sWeb.RegionalSettings.LocaleId)
            Write-Host "- New Locale:" $c1.DisplayName
            Write-Host "- New LocaleId:" $sWeb.RegionalSettings.LocaleId
        }
    }
}
PROCESS{
    $securePassword = ConvertTo-SecureString $PassWord -AsPlainText -Force
    $spoCred = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $securePassword)
    $ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteUrl)
    $ctx.Credentials = $spoCred

    $Web = $ctx.Web
    $ctx.Load($ctx.Web)
    $ctx.Load($Web)
    $ctx.ExecuteQuery()

    Set-SPOWebRegionalSettings -RootWeb $Web -Context $ctx -NewCulture $NewCulture -NewTimeZoneID $NewTimeZoneID
}
