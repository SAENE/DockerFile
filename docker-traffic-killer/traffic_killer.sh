#!/bin/bash

# ================= Docker 兼容配置区域 =================
# 利用 bash 的 := 语法：如果环境变量有值则优先使用环境变量，否则使用后面的默认值
URL=${URL:=https://img.mcloud.139.com/material_prod/material_media/20221128/1669626861087.png}
THREADS=${THREADS:=4}          

# 单线程下载速度限制（例如：2m 代表 2MB/s，500k 代表 500KB/s，0 为不限速）
# 此时的总速度上限 = THREADS × SPEED_LIMIT
SPEED_LIMIT=${SPEED_LIMIT:=2m}   

# 日志模式设置: "INFO" (只看总速度) 或 "DEBUG" (看各线程速度+总速度)
LOG_MODE=${LOG_MODE:=INFO}

# 允许的最大连续失败次数，超过此限制脚本自动退出
MAX_CONTINUOUS_FAILURES=${MAX_CONTINUOUS_FAILURES:=20}
# ====================================================

if ! command -v bc &> /dev/null; then
    echo "[错误] 脚本需要 bc 计算器，请先安装。 (Ubuntu: apt install bc / CentOS: yum install bc)"
    exit 1
fi

echo "正在验证网络并获取测试文件大小..."
# 增加超时防线，防止启动时由于极端网络导致获取文件大小卡死
FILE_SIZE=$(curl -sIf --connect-timeout 5 --max-time 10 "$URL" | grep -i Content-Length | awk '{print $2}' | tr -d '\r')

if [ -z "$FILE_SIZE" ] || [ "$FILE_SIZE" -eq 0 ]; then
    echo "[❌ 错误] 脚本启动时即无法访问该链接，请检查网络或URL！"
    exit 1
fi

# 创建命名管道并安全初始化描述符
PIPE=$(mktemp -u)
mkfifo "$PIPE"
exec 3<>"$PIPE"

echo "=========================================="
echo " 流量脚本已启动 | 模式: $LOG_MODE | 线程数: $THREADS"
echo " 单线限速: $SPEED_LIMIT (0为不限)"
echo " 稳定性增强：已启用低速断线剔除守护"
echo "=========================================="

TOTAL_DOWNLOADS=0
CONTINUOUS_FAILURES=0 
START_TIME=$(date +%s) 
LAST_REPORT_TIME=$START_TIME
LAST_REPORT_COUNT=0
PIDS=()

# 跨版本安全的清理机制
cleanup() {
    local sig=$1
    trap - INT TERM EXIT 
    echo -e "\n\n[!] 正在终止所有后台下载线程并清理环境..."
    
    # 优雅强杀：先使用 disown 剥离管辖权，彻底抹除终端的 "Killed download_worker" 杂音
    for pid in "${PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            disown "$pid" 2>/dev/null
            kill -9 "$pid" 2>/dev/null
        fi
    done
    
    exec 3>&-  
    rm -f "$PIPE" 2>/dev/null
    echo "[+] 所有资源已安全释放，脚本退出成功！"
    
    # 根据进入清理的原因，决定如何安全退出系统
    if [ -n "$sig" ]; then
        kill -s "$sig" "$$"
    else
        exit 0
    fi
}
# 分别安全捕获，防止 Bash 4.x 下的 EXIT 递归死循环
trap 'cleanup INT' INT
trap 'cleanup TERM' TERM
trap 'cleanup' EXIT

# 内存保留管道描述符后，立即安全抹除磁盘节点，防止非授权串扰
rm -f "$PIPE" 2>/dev/null

# 预填初始令牌
for ((i=0; i<THREADS*2; i++)); do echo >&3; done

# 下载工作线程
download_worker() {
    local thread_id=$1
    local limit_arg=""
    [ "$SPEED_LIMIT" != "0" ] && limit_arg="--limit-rate $SPEED_LIMIT"

    while true; do
        local t_start=$(date +%s%N)
        
        # 增加低速断线剔除机制：若 5 秒内速度低于 1KB/s，立刻视为断网并报错重试
        # 配合 max-time 15 彻底解决多线程在物理断网、重度丢包时的“永久卡死/假死”隐患
        curl -s -f -L --connect-timeout 3 --max-time 15 $limit_arg \
             --speed-limit 1000 --speed-time 5 -o /dev/null "$URL"
        
        if [ $? -eq 0 ]; then
            local t_end=$(date +%s%N)
            local t_diff=$((t_end - t_start))
            [ $t_diff -le 0 ] && t_diff=1
            
            if [ "$LOG_MODE" = "DEBUG" ]; then
                local t_ms=$((t_diff / 1000000))
                [ $t_ms -le 0 ] && t_ms=1
                local thread_speed_int=$(( (FILE_SIZE * 1000) / (t_ms * 1048576) ))
                local thread_speed_dec=$(( ((FILE_SIZE * 1000) % (t_ms * 1048576)) * 100 / (t_ms * 1048576) ))
                [ $thread_speed_dec -lt 10 ] && thread_speed_dec="0$thread_speed_dec"
                
                echo "[线程 #$thread_id] 成功 | 耗时: $((t_ms))ms | 速度: ${thread_speed_int}.${thread_speed_dec} MB/s"
            fi
            echo "1" >&3
        else
            if [ "$LOG_MODE" = "DEBUG" ]; then
                echo "[线程 #$thread_id] 下载失败或因低速断开..."
            fi
            sleep 2
            echo "0" >&3
        fi
    done
}

# 启动后台工作线程
for ((i=1; i<=THREADS; i++)); do
    download_worker "$i" &
    PIDS+=($!)
done

# 主循环
while read -r signal <&3; do
    if [ "$signal" = "1" ]; then
        ((TOTAL_DOWNLOADS++))
        CONTINUOUS_FAILURES=0 
    else
        ((CONTINUOUS_FAILURES++)) 
        if [ "$CONTINUOUS_FAILURES" -ge "$MAX_CONTINUOUS_FAILURES" ]; then
            echo -e "\n\n[❌ 熔断触发] 检测到连续失败次数达到 ${CONTINUOUS_FAILURES} 次，自动退出。"
            cleanup 
        fi
    fi
    
    NOW=$(date +%s)
    INTERVAL=$((NOW - LAST_REPORT_TIME))
    
    if [ $INTERVAL -ge 1 ]; then
        COUNT_THIS_SEC=$((TOTAL_DOWNLOADS - LAST_REPORT_COUNT))
        BYTES_THIS_SEC=$((COUNT_THIS_SEC * FILE_SIZE))
        TOTAL_BYTES=$(echo "$TOTAL_DOWNLOADS * $FILE_SIZE" | bc 2>/dev/null)
        
        # 整体大盘每秒仅执行一次，继续保留 bc 保证绝对的大数据精度与跨平台兼容
        SPEED_MB=$(echo "scale=2; $BYTES_THIS_SEC / 1048576 / $INTERVAL" | bc 2>/dev/null)
        TOTAL_GB=$(echo "scale=2; $TOTAL_BYTES / 1073741824" | bc 2>/dev/null)
        RUN_TIME=$((NOW - START_TIME))
        
        [ -z "$SPEED_MB" ] && SPEED_MB="0.00"
        [ -z "$TOTAL_GB" ] && TOTAL_GB="0.00"
        [[ "$SPEED_MB" == .* ]] && SPEED_MB="0$SPEED_MB"
        [[ "$TOTAL_GB" == .* ]] && TOTAL_GB="0$TOTAL_GB"
        
        if [ "$LOG_MODE" = "INFO" ]; then
            # INFO 模式：原地单行干净刷新
            printf "\r[INFO] 已运行: %ds | 整体总速度: \033[1;32m%s MB/s\033[0m | 累计流量: \033[1;36m%s GB\033[0m" "$RUN_TIME" "$SPEED_MB" "$TOTAL_GB"
        elif [ "$LOG_MODE" = "DEBUG" ]; then
            # DEBUG 模式：混态瀑布流输出
            echo -e "\n--- [DEBUG 总计] 时间: ${RUN_TIME}s | 整体总速度: \033[1;32m${SPEED_MB} MB/s\033[0m | 总流量: ${TOTAL_GB} GB | 连续失败: ${CONTINUOUS_FAILURES} ---\n"
        fi
        
        LAST_REPORT_TIME=$NOW
        LAST_REPORT_COUNT=$TOTAL_DOWNLOADS
    fi
done