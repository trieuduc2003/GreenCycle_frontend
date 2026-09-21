$ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Wi-Fi | Select-Object -ExpandProperty IPAddress)
if (-not $ip) {
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch "Loopback|vEthernet|WSL" } | Select-Object -First 1 -ExpandProperty IPAddress)
}

if ($ip) {
    Write-Host "Tim thay IP: $ip" -ForegroundColor Green
    $file = "lib\core\constants\api_endpoints.dart"
    
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        $content = $content -replace "https://[0-9\.]+:7031", "https://${ip}:7031"
        Set-Content -Path $file -Value $content
        Write-Host "Da cap nhat IP vao $file thanh cong!" -ForegroundColor Cyan
    } else {
        Write-Host "Khong tim thay file $file" -ForegroundColor Red
    }
} else {
    Write-Host "Khong the tim thay dia chi IP cua may tinh!" -ForegroundColor Red
}
