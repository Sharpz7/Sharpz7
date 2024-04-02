####
# SET-INTERNETPROXY
#
# DESCRIPTION
#   This function will set the proxy server and (optional) Automatic configuration script.
#
# SYNTAX
#   Set-InternetProxy [-Proxy] <string[]> [[-acs] <string[]>]  [<CommonParameters>]
#
# EXAMPLES
#        Set-InternetProxy -proxy "http=127.0.0.1:8080"
#        Set-InternetProxy -proxy "https=127.0.0.1:8080"
#        Set-InternetProxy -proxy "ftp=127.0.0.1:8080"
#        Set-InternetProxy -proxy "socks=127.0.0.1:8080"
#   Setting proxy information and (optinal) Automatic Configuration Script:
#       Set-InternetProxy -proxy "proxy:7890" -acs "http://proxy:7892"
#
# SOURCE
#   https://gallery.technet.microsoft.com/scriptcenter/PowerShell-function-Get-cba2abf5
####

Function Set-InternetProxy
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [String[]]$Proxy,

        [Parameter(Mandatory=$False,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [AllowEmptyString()]
        [String[]]$acs,

        [Parameter(Mandatory=$False)]
        [Switch]$Disable
    )

    Begin
    {
        $regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    }

    Process
    {
        if($Disable)
        {
            Set-ItemProperty -Path $regKey -Name ProxyEnable -Value 0
            Remove-ItemProperty -Path $regKey -Name ProxyServer -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $regKey -Name AutoConfigURL -ErrorAction SilentlyContinue
        }
        else
        {
            Set-ItemProperty -Path $regKey -Name ProxyEnable -Value 1
            Set-ItemProperty -Path $regKey -Name ProxyServer -Value $Proxy
            Set-ItemProperty -Path $regKey -Name ProxyOverride -Value "<local>"

            if($acs)
            {
                Set-ItemProperty -Path $regKey -Name AutoConfigURL -Value $acs
            }
        }
    }

    End
    {
        if($Disable)
        {
            Write-Output "Proxy is now disabled"
        }
        else
        {
            Write-Output "Proxy is now enabled"
            Write-Output "Proxy Server : $Proxy"
            if ($acs)
            {
                Write-Output "Automatic Configuration Script : $acs"
            }
            else
            {
                Write-Output "Automatic Configuration Script : Not Defined"
            }
        }
    }
}


# Keep this line and make sure there is an empty line below this one
