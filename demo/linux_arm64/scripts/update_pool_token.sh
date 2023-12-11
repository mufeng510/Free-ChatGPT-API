#!/bin/bash

api_url="http://127.0.0.1:8181/qqrr123123"
unique_name=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 10)
expires_in=0
current_dir=$(dirname "$(readlink -f "\$0")")
credentials_file="$current_dir/credentials.txt"
pool_token_file="$current_dir/pool_token.txt"
tokens_file="$current_dir/../tokens.json"

read_credentials() {
    credentials=()
    while IFS=, read -r username password || [[ -n $username ]]; do
        credentials+=("$username" "$password")
    done < "$credentials_file"
}

get_access_token() {
    local payload="username=$username&password=$password"
    local resp=$(curl -s -X POST -d "$payload" "$api_url/api/auth/login")
    if [[ $resp == *"access_token"* ]]; then
        access_token=$(echo "$resp" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
        echo "$access_token"
    else
        err_str=$(echo "$resp" | tr -d '\n\r' | sed 's/^[ \t]*//;s/[ \t]*$//')
        echo "Login failed: $username, $err_str"
    fi
}

get_share_token() {
    local data="unique_name=$unique_name&access_token=$access_token&expires_in=$expires_in"
    local resp=$(curl -s -X POST -d "$data" "$api_url/api/token/register")
    if [[ $resp == *"token_key"* ]]; then
        share_token=$(echo "$resp" | grep -o '"token_key":"[^"]*' | cut -d'"' -f4)
        echo "$share_token"
    else
        err_str=$(echo "$resp" | tr -d '\n\r' | sed 's/^[ \t]*//;s/[ \t]*$//')
        echo "share token failed: $err_str"
    fi
}

read_pool_token() {
    if [[ -f $pool_token_file ]]; then
        pool_token=$(<"$pool_token_file")
        if [[ $pool_token =~ pk-[0-9a-zA-Z_\-]{43} ]]; then
            echo "已存在: pool token: $pool_token"
        else
            echo "pool token: 格式不正确，将重新生成"
            pool_token=""
        fi
    else
        pool_token=""
    fi
}

update_pool_token() {
    local filtered_tokens=()
    for token in "${share_token_keys[@]}"; do
        if [[ $token =~ fk-[0-9a-zA-Z_\-]{43} ]]; then
            filtered_tokens+=("$token")
        fi
    done

    if [[ ${#filtered_tokens[@]} -eq 0 ]]; then
        echo "无可用账号，请检查后重试"
        return
    fi

    local data="share_tokens=$(printf "%s\n" "${filtered_tokens[@]}")&pool_token=$pool_token"
    local resp=$(curl -s -X POST -d "$data" "$api_url/api/pool/update")
    if [[ $resp == *"pool_token"* ]]; then
        count=$(echo "$resp" | grep -o '"count":[0-9]*' | cut -d':' -f2)
        new_pool_token=$(echo "$resp" | grep -o '"pool_token":"[^"]*' | cut -d'"' -f4)
        echo "pool token 更新结果: count: $count pool_token: $new_pool_token"
        echo "$new_pool_token" > "$pool_token_file"
    else
        echo "pool token 更新失败"
    fi
}

save_tokens() {
    local access_token_keys=("$@")
    tokens_data="{"
    for ((i=0; i<${#access_token_keys[@]}; i++)); do
        tokens_data+="\"user-$(($i+1))\": {\"token\": \"${access_token_keys[$i]}\", \"shared\": true, \"show_user_info\": false}"
        if [[ $i -lt $((${#access_token_keys[@]}-1)) ]]; then
            tokens_data+=", "
        fi
    done
    tokens_data+="}"

    echo "$tokens_data" > "$tokens_file"
}

generate_random_string() {
    cat /dev/urandom | tr -dc 'a-zA-Z' | fold -w "\$1" | head -n 1
}

run() {
    read_credentials
    declare -a access_token_keys
    declare -a share_token_keys
    local count=0

    for ((i=0; i<${#credentials[@]}; i+=2)); do
        username=${credentials[$i]}
        password=${credentials[$i+1]}
        sleep_seconds=1
        echo "开始休眠 $sleep_seconds 秒..."
        sleep $sleep_seconds
        echo "休眠结束，继续执行后续代码."
        echo "Login begin: $username, $((i/2+1))/$((${#credentials[@]}/2))"
        access_token=$(get_access_token "$username" "$password")
        if [[ -n $access_token && $access_token != *failed* ]]; then
            echo "Login success."
            access_token_keys+=("$access_token")
            share_token=$(get_share_token "$access_token")
            echo "$share_token"
            if [[ -n $share_token && $share_token != *failed* ]]; then
                share_token_keys+=("$share_token")
            else
                echo "Share token retrieval failed."
            fi
        else
            echo "Login failed or access token retrieval failed."
        fi
    done

    read_pool_token
    update_pool_token
    # save_tokens "${access_token_keys[@]}"
}

run
