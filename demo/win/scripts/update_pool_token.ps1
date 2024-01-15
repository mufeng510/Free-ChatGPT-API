$api_url = "http://127.0.0.1:8181/xxxxxxxxx"

$unique_name = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 10 | % {[char]$_})
$expires_in = 0
$current_dir = Split-Path -Path $MyInvocation.MyCommand.Path
$credentials_file = Join-Path -Path $current_dir -ChildPath 'credentials.txt'
$pool_token_file = Join-Path -Path $current_dir -ChildPath 'pool_token.txt'
$tokens_file = Join-Path -Path $current_dir -ChildPath '../tokens.json'

function Run {
    $currentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "-----------------------$currentDateTime-----------------------"

    $credentials = Read-Credentials -FilePath $credentials_file

    $access_token_keys = @()
    $share_token_keys = @()
    $count = 0

    foreach ($credential in $credentials) {
        # Interface rate limited.
        $sleep_seconds = 5
        Start-Sleep -Seconds $sleep_seconds

        $username = $credential[0].Trim()
        $password = $credential[1].Trim()

        Write-Host "Login begin: $username, $($count+1)/$($credentials.Count)"

        $access_token = Get-AccessToken -ApiUrl $api_url -Username $username -Password $password
        if ($access_token) {
            $access_token_keys += $access_token
            $share_token = Get-ShareToken -ApiUrl $api_url -UniqueName $unique_name -AccessToken $access_token -ExpiresIn $expires_in
            if ($share_token) {
                $share_token_keys += $share_token
            }
        }
    }

    $pool_token = Read-PoolToken -PoolTokenFile $pool_token_file
    Update-PoolToken -ApiUrl $api_url -ShareTokenKeys $share_token_keys -PoolToken $pool_token -PoolTokenFile $pool_token_file
    # Save-Tokens -TokensFile $tokens_file -AccessTokenKeys $access_token_keys
}

function Read-Credentials {
    param (
        [string]$FilePath
    )
    $credentials = Get-Content -Path $FilePath | Where-Object {$_ -match ','} | ForEach-Object {$_ -split ','}
    $credentialPairs = @()
    for ($i = 0; $i -lt $credentials.Length; $i += 2) {
        $credentialPairs += ,@($credentials[$i], $credentials[$i + 1])
    }
    return ,$credentialPairs
}


function Get-AccessToken {
    param (
        [string]$ApiUrl,
        [string]$Username,
        [string]$Password
    )
    $payload = @{
        username = $Username
        password = $Password
    }
    try {
        $resp = Invoke-RestMethod -Uri ($ApiUrl + '/api/auth/login') -Method Post -Body $payload
        if ($resp.access_token) {
            Write-Host "Login success"
            return $resp.access_token
        }
    }
    catch {
        Write-Host "Login failed:" $_.Exception.Message.ToString().Replace("`n", "").Replace("`r", "").Trim()
        return $null
    }
}

function Get-ShareToken {
    param (
        [string]$ApiUrl,
        [string]$UniqueName,
        [string]$AccessToken,
        [int]$ExpiresIn
    )
    $data = @{
        unique_name = $UniqueName
        access_token = $AccessToken
        expires_in = $ExpiresIn
    }
    try {
        $resp = Invoke-RestMethod -Uri ($ApiUrl + '/api/token/register') -Method Post -Body $data
        if ($resp.token_key) {
            $share_token = $resp.token_key
            Write-Host "share token: $share_token"
            return $share_token
        }
    }
    catch {
        $err_str = $_.Exception.Message.ToString().ToString().Replace("`n", "").Replace("`r", "").Trim()
        Write-Host "share token failed: $err_str"
        return $null
    }
}

function Read-PoolToken {
    param (
        [string]$PoolTokenFile
    )
    if (Test-Path $PoolTokenFile) {
        $pool_token = Get-Content -Path $PoolTokenFile
        if ($pool_token -match 'pk-[0-9a-zA-Z_\-]{43}') {
            Write-Host "Already exists: pool token: $pool_token"
            return $pool_token
        } else {
            return ""
        }
    }else {
        return ""
    }
}

function Update-PoolToken {
    param (
        [string]$ApiUrl,
        [string[]]$ShareTokenKeys,
        [string]$PoolToken,
        [string]$PoolTokenFile
    )
    $filtered_tokens = $ShareTokenKeys -match 'fk-[0-9a-zA-Z_\-]{43}'
    if (-not $filtered_tokens) {
        Write-Host "No available accounts, please check and try again"
        return
    }

    $data = @{
        share_tokens = $filtered_tokens -join "`n"
        pool_token = $PoolToken
    }
    try {
        $resp = Invoke-RestMethod -Uri ($ApiUrl + '/api/pool/update') -Method Post -Body $data
        if ($resp.pool_token) {
            $result = $resp | ConvertTo-Json
            Write-Host "$result"
            Write-Host "pool token update result: count:$($result.count) pool_token:$($result.pool_token)"
            Set-Content -Path $PoolTokenFile -Value $result.pool_token
        }
    }
    catch {
        $err_str = $_.Exception.Message.ToString().ToString().Replace("`n", "").Replace("`r", "").Trim()
        Write-Host "pool token update failed: $err_str"
    }
}

function Save-Tokens {
    param (
        [string]$TokensFile,
        [string[]]$AccessTokenKeys
    )
    $tokens_data = @{}
    for ($i=0; $i -lt $AccessTokenKeys.Count; $i++) {
        $tokens_data["user-$($i+1)"] = @{
            token = $AccessTokenKeys[$i]
            shared = $true
            show_user_info = $false
        }
    }
    $tokens_data | ConvertTo-Json | Set-Content -Path $TokensFile
}
Run
