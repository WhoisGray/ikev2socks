#!/bin/bash

function up_ip_sec() {
    # Success flag
    local success=0
    # Iterate through all conn entries
    while IFS= read -r line; do

        # conn name
        local conn_name=$(echo "$line" | awk '{print $2}')

        echo "IPSec starting connection $conn_name (timeout $TIMEOUT seconds)"

        # Connect VPN
        ipsec up "$conn_name" &

        # Timer
        local timer=0
        # Check IPSec connection status
        while true; do
            # Use status command to check connection
            if ipsec status | grep -q "ESTABLISHED"; then
                echo "IPSec connection $conn_name succeeded!"
                success=1
                break
            fi
            echo "IPSec connecting $conn_name, $timer seconds elapsed"
            # Exit loop if timeout
            if [ $timer -ge $TIMEOUT ]; then
                echo "IPSec connection $conn_name timed out!"
                ipsec down "$conn_name"
                break
            fi
            # Wait one second before next check
            sleep 1
            # Increment timer
            ((timer++))
        done

        # Break loop if connection succeeded
        if [ $success -eq 1 ]; then
            break
        fi
    done < <(grep '^conn' "/etc/ipsec.conf")
    # Return result
    return $success
}

function health_check() {
    # Continuously check status
    while true; do
        if ipsec status | grep -q "ESTABLISHED"; then
            echo "IPSec connection is healthy!"
            # Connection exists, wait 10 seconds before next check
            sleep 10
        else
            echo "IPSec connection lost!"
            # Reconnect
            up_ip_sec
        fi
    done
}


# Copy system CA certificates so strongSwan can verify the server's pubkey (rightauth=pubkey)
mkdir -p /etc/ipsec.d/cacerts
cp -r /etc/ssl/certs/* /etc/ipsec.d/cacerts/ 2>/dev/null || true

# Start IPSec in the background. --nofork avoids starting a new process, logs to current process
ipsec start --nofork &

# Wait 10 seconds for IPSec to start successfully
sleep 10

# Connect IPSec
up_ip_sec
# Success flag
success=$?

if [ $success -eq 0 ]; then
    # Connection failed
    exit 1
fi

# Connection succeeded, start health check
health_check &

echo "Starting Gost socks5"
# با network_mode: host پورت روی خود host باز است (پیش‌فرض 10809 برای سازگاری با قبل)
exec gost -L "socks5://:${SOCKS5_PORT:-1080}"