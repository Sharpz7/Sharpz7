# Setup

In an admin shell

```powershell
mkdir C:\Users\adamm\Documents\WindowsPowerShell\
echo $null >> C:\Users\adamm\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
mkdir C:\Users\adamm\Documents\Scripts\
Set-ExecutionPolicy bypass
```

Save in

```powershell
Get-ChildItem C:\Users\adamm\Documents\Scripts\*.ps1 | %{. $_ }
```

Now save all scripts to `C:\Users\adamm\Documents\Scripts\`

# ProxyServer

# Aliases

```powershell
# Start
Start-Process -FilePath "ssh" -ArgumentList "adam@compute-us-1.mcaq.me -p 4790 -N -D 127.0.0.1:4000" -NoNewWindow
Set-InternetProxy -proxy "socks=127.0.0.1:4000"

# Stop
Set-InternetProxy -Disable -proxy null
Get-Process | Where-Object {$_.ProcessName -eq "ssh"} | Select-Object -First 1 | Stop-Process

# Debugging
Get-Process | Where-Object {$_.ProcessName -eq "ssh"}
```