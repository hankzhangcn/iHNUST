# 获取用户文档目录路径
$documentsPath = [System.Environment]::GetFolderPath("MyDocuments")
$credentialsFile = Join-Path -Path $documentsPath -ChildPath "Hnust_login_credentials.json"

# 检查文件是否存在
if (Test-Path $credentialsFile) {
    # 从文件中读取 JSON 数据并解析
    $savedCredentials = Get-Content $credentialsFile | ConvertFrom-Json
    $username = $savedCredentials.Username
    $user_password = $savedCredentials.Password
    $user_account_suffix = $savedCredentials.Suffix

    Write-Output "读取的用户名是: $username"
    # Write-Output "读取的密码是: $user_password"
    Write-Output "读取的运营商是: $user_account_suffix"

} else {
    # 文件不存在，提示用户输入用户名和密码
    $username =  Read-Host "请输入用户名"
    $user_password = Read-Host "请输入密码" -AsSecureString
    $user_password = [System.Net.NetworkCredential]::new('', $user_password).Password
    $user_account_suffix = Read-Host "请输入运营商
    校园网  直接回车
    移动    cmcc
    联通    unicom
    电信    telecom"
    $user_account_suffix = "@${user_account_suffix}"
    
    

    # 创建一个包含用户名和密码的对象
    $credentials = @{
        Username = $username
        Password = $user_password
        Suffix = $user_account_suffix
    }

    # 将对象转换为 JSON 并保存到文件中
    $credentials | ConvertTo-Json | Out-File $credentialsFile

    Write-Output "保存的用户名是: $username"
    # Write-Output "保存的密码是: $user_password"
    Write-Output "保存的运营商是: $user_account_suffix"


}






# 定义变量
$callback = "dr1003"
$login_method = "1"
$user_account_prefix = "%2C1%2C"
$wlan_user_ipv6 = ""
$wlan_user_mac = "000000000000"
$wlan_ac_ip = ""
$wlan_ac_name = ""
$jsVersion = "4.2.1"
$terminal_type = "2"
$lang = "zh-cn"
$v = Get-Random -Minimum 1001 -Maximum 8274

# 获取设备的IP地址
#$wlan_user_ip = (Invoke-RestMethod -Uri "http://ipinfo.io/ip").Trim()

# 获取10开头的设备的本地IP地址
$wlan_user_ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch 'Loopback|Teredo|ISATAP|Container' -and $_.IPAddress -like '10.*' }).IPAddress

#$wlan_user_ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch #'Loopback|Teredo|ISATAP|Container' }).IPAddress

# echo $wlan_user_ip

# 如果有多个IP地址，选择第一个
if ($wlan_user_ip.Count -gt 1) {
    $wlan_user_ip = $wlan_user_ip[0]
}

# 构建 登录 请求的 URL
$login_url = "http://login.hnust.cn:801/eportal/portal/login?callback=$callback&login_method=$login_method&user_account=$user_account_prefix$username$user_account_suffix&user_password=$user_password&wlan_user_ip=$wlan_user_ip&wlan_user_ipv6=$wlan_user_ipv6&wlan_user_mac=$wlan_user_mac&wlan_ac_ip=$wlan_ac_ip&wlan_ac_name=$wlan_ac_name&jsVersion=$jsVersion&terminal_type=$terminal_type&lang=$lang&v=$v"

# 构建 登出 请求的 URL
$logout_url= "http://login.hnust.cn:801/eportal/portal/mac/unbind?callback=$callback&user_account=$username&wlan_user_mac=$wlan_user_mac&wlan_user_ip=$wlan_user_ip&jsVersion=$jsVersion&v=$v&lang=$lang"

# ----------------

echo "脚本由瀚可联合光盘头通力撰写，版本20240723。"
#尝试访问apple，能就问是否登出。
$apple_response = Invoke-WebRequest -Uri "http://captive.apple.com" -Method Get
if ($apple_response.Content -like "<HTML><HEAD><TITLE>Success</TITLE></HEAD><BODY>Success</BODY></HTML>") {
    $userInput = Read-Host "你已在线，是否登出[y/N]"
    if ($userInput -eq "y" -or $userInput -eq "Y") {
        # 发起 GET 请求进行登出
        $response = Invoke-WebRequest -Uri $logout_url -Method Get
        # echo $response
        $responseContent = $response.Content
        # 提取 JSON 数据部分
        $jsonData = $responseContent -replace "^.*\(", "" -replace "\);$", ""
        # 将 JSON 数据转换为 PowerShell 对象
        $data = $jsonData | ConvertFrom-Json
        if ($data.result -eq 1) {
            Write-Output "登出成功，再见。"
            Read-Host "按下回车来退出"
        } else {
            Write-Output "出问题了，登出失败。检查账户密码。"
            Read-Host "按下回车来退出"
        }
    } else {
        Write-Output "保持在线，随时奉陪。o(^▽^)o"
        Read-Host "按下回车来退出"

    }
} else {
    # 如果不在线
    # 发起 GET 请求进行登录
    $response = Invoke-WebRequest -Uri $login_url -Method Get
    # echo $response
    $apple_response = Invoke-WebRequest -Uri "http://captive.apple.com" -Method Get
    if ($apple_response.Content -like "<HTML><HEAD><TITLE>Success</TITLE></HEAD><BODY>Success</BODY></HTML>") {
        Write-Output "登录成功,你可以访问互联网了。"
        $userInput = Read-Host "需要修改/清空填写的账号密码吗？[y/N]"
        if ($userInput -eq "y" -or $userInput -eq "Y") {
            Remove-Item $credentialsFile -Force
            Read-Host "账号密码记录已清空，重新打开脚本以添加新的账号密码"
        } else {
            Read-Host "按下回车来退出"
        }
    } else {
        Write-Output "出问题了。 先检查一下账号密码，然后重试。如果还是行不通，就从网页登录吧。 https://login.hnust.cn/"
        $userInput = Read-Host "清空填写的账号密码？[y/N]"
        if ($userInput -eq "y" -or $userInput -eq "Y") {
            Remove-Item $credentialsFile -Force
            Read-Host "账号密码记录已清空，重新打开脚本以添加新的账号密码"
        } else {
            Read-Host "按下回车来退出"
        }
    }
}