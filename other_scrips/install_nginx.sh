#!/bin/bash

# Nginx 源码自动化安装脚本
# 兼容 sh 的版本

set -e

echo "开始安装 Nginx..."

# 检查是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
    echo "请使用 root 用户运行此脚本"
    exit 1
fi

log_info() {
    echo "[INFO] $1"
}

log_warn() {
    echo "[WARN] $1"
}

log_error() {
    echo "[ERROR] $1"
}

# 安装依赖
log_info "安装编译依赖..."
apt-get update
apt-get install -y libpcre3 libpcre3-dev zlib1g-dev openssl libssl-dev build-essential

# 创建 nginx 用户和组
if id "nginx" >/dev/null 2>&1; then
    log_info "nginx 用户已存在"
else
    log_info "创建 nginx 用户..."
    useradd -s /sbin/nologin -M nginx
fi

# 创建必要的目录
log_info "创建必要的目录..."
mkdir -p /var/cache/nginx
mkdir -p /var/log/nginx/
mkdir -p /var/lib/nginx/body
mkdir -p /var/lib/nginx/fastcgi
mkdir -p /var/lib/nginx/proxy
mkdir -p /var/lib/nginx/scgi
mkdir -p /var/lib/nginx/uwsgi
mkdir -p /usr/lib/nginx/modules
mkdir -p /run
mkdir -p /usr/share/nginx/html

# 配置和编译安装
log_info "配置 Nginx..."
./configure \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-client-body-temp-path=/var/lib/nginx/body \
    --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
    --http-log-path=/var/log/nginx/access.log \
    --http-proxy-temp-path=/var/lib/nginx/proxy \
    --http-scgi-temp-path=/var/lib/nginx/scgi \
    --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
    --lock-path=/var/lock/nginx.lock \
    --modules-path=/usr/lib/nginx/modules \
    --pid-path=/run/nginx.pid \
    --prefix=/usr/share/nginx \
    --sbin-path=/usr/sbin/nginx \
    --user=nginx \
    --group=nginx \
    --with-compat \
    --with-file-aio \
    --with-debug \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-ld-opt='-Wl,-Bsymbolic-functions -flto=auto -Wl,-z,relro -Wl,-z,now -fPIC' \
    --with-pcre-jit \
    --with-mail \
    --with-mail_ssl_module \
    --with-stream \
    --with-stream_realip_module \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-threads

log_info "编译和安装 Nginx..."
make -j$(nproc)
make install

# 复制默认的 HTML 文件
if [ ! -d "/usr/share/nginx/html" ] || [ -z "$(ls -A /usr/share/nginx/html)" ]; then
    log_info "复制默认 HTML 文件..."
    cp -R html/* /usr/share/nginx/html/ 2>/dev/null || true
fi

# 创建 init.d 服务脚本
log_info "创建 init.d 服务脚本..."
cat > /etc/init.d/nginx << 'EOF'
#!/bin/sh

### BEGIN INIT INFO
# Provides:	  nginx
# Required-Start:    $local_fs $remote_fs $network $syslog $named
# Required-Stop:     $local_fs $remote_fs $network $syslog $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the nginx web server
# Description:       starts nginx using start-stop-daemon
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/sbin/nginx
NAME=nginx
DESC=nginx

# Include nginx defaults if available
if [ -r /etc/default/nginx ]; then
	. /etc/default/nginx
fi

STOP_SCHEDULE="${STOP_SCHEDULE:-QUIT/5/TERM/5/KILL/5}"

test -x $DAEMON || exit 0

. /lib/init/vars.sh
. /lib/lsb/init-functions

# Try to extract nginx pidfile
PID=$(cat /etc/nginx/nginx.conf | grep -Ev '^\s*#' | awk 'BEGIN { RS="[;{}]" } { if ($1 == "pid") print $2 }' | head -n1)
if [ -z "$PID" ]; then
	PID=/run/nginx.pid
fi

if [ -n "$ULIMIT" ]; then
	# Set ulimit if it is set in /etc/default/nginx
	ulimit $ULIMIT
fi

start_nginx() {
	# Start the daemon/service
	#
	# Returns:
	#   0 if daemon has been started
	#   1 if daemon was already running
	#   2 if daemon could not be started
	start-stop-daemon --start --quiet --pidfile $PID --exec $DAEMON --test > /dev/null \
		|| return 1
	start-stop-daemon --start --quiet --pidfile $PID --exec $DAEMON -- \
		$DAEMON_OPTS 2>/dev/null \
		|| return 2
}

test_config() {
	# Test the nginx configuration
	$DAEMON -t $DAEMON_OPTS >/dev/null 2>&1
}

stop_nginx() {
	# Stops the daemon/service
	#
	# Return
	#   0 if daemon has been stopped
	#   1 if daemon was already stopped
	#   2 if daemon could not be stopped
	#   other if a failure occurred
	start-stop-daemon --stop --quiet --retry=$STOP_SCHEDULE --pidfile $PID --name $NAME
	RETVAL="$?"
	sleep 1
	return "$RETVAL"
}

reload_nginx() {
	# Function that sends a SIGHUP to the daemon/service
	start-stop-daemon --stop --signal HUP --quiet --pidfile $PID --name $NAME
	return 0
}

rotate_logs() {
	# Rotate log files
	start-stop-daemon --stop --signal USR1 --quiet --pidfile $PID --name $NAME
	return 0
}

upgrade_nginx() {
	# Online upgrade nginx executable
	# http://nginx.org/en/docs/control.html
	#
	# Return
	#   0 if nginx has been successfully upgraded
	#   1 if nginx is not running
	#   2 if the pid files were not created on time
	#   3 if the old master could not be killed
	if start-stop-daemon --stop --signal USR2 --quiet --pidfile $PID --name $NAME; then
		# Wait for both old and new master to write their pid file
		cnt=0
		while [ ! -s "${PID}.oldbin" ] || [ ! -s "${PID}" ]; do
			cnt=$(expr $cnt + 1)
			if [ $cnt -gt 10 ]; then
				return 2
			fi
			sleep 1
		done
		# Everything is ready, gracefully stop the old master
		if start-stop-daemon --stop --signal QUIT --quiet --pidfile "${PID}.oldbin" --name $NAME; then
			return 0
		else
			return 3
		fi
	else
		return 1
	fi
}

case "$1" in
	start)
		log_daemon_msg "Starting $DESC" "$NAME"
		start_nginx
		case "$?" in
			0|1) log_end_msg 0 ;;
			2)   log_end_msg 1 ;;
		esac
		;;
	stop)
		log_daemon_msg "Stopping $DESC" "$NAME"
		stop_nginx
		case "$?" in
			0|1) log_end_msg 0 ;;
			2)   log_end_msg 1 ;;
		esac
		;;
	restart)
		log_daemon_msg "Restarting $DESC" "$NAME"

		# Check configuration before stopping nginx
		if ! test_config; then
			log_end_msg 1 # Configuration error
			exit $?
		fi

		stop_nginx
		case "$?" in
			0|1)
				start_nginx
				case "$?" in
					0) log_end_msg 0 ;;
					1) log_end_msg 1 ;; # Old process is still running
					*) log_end_msg 1 ;; # Failed to start
				esac
				;;
			*)
				# Failed to stop
				log_end_msg 1
				;;
		esac
		;;
	reload|force-reload)
		log_daemon_msg "Reloading $DESC configuration" "$NAME"

		# Check configuration before stopping nginx
		#
		# This is not entirely correct since the on-disk nginx binary
		# may differ from the in-memory one, but that's not common.
		# We prefer to check the configuration and return an error
		# to the administrator.
		if ! test_config; then
			log_end_msg 1 # Configuration error
			exit $?
		fi

		reload_nginx
		log_end_msg $?
		;;
	configtest|testconfig)
		log_daemon_msg "Testing $DESC configuration"
		test_config
		log_end_msg $?
		;;
	status)
		status_of_proc -p $PID "$DAEMON" "$NAME" && exit 0 || exit $?
		;;
	upgrade)
		log_daemon_msg "Upgrading binary" "$NAME"
		upgrade_nginx
		log_end_msg $?
		;;
	rotate)
		log_daemon_msg "Re-opening $DESC log files" "$NAME"
		rotate_logs
		log_end_msg $?
		;;
	*)
		echo "Usage: $NAME {start|stop|restart|reload|force-reload|status|configtest|rotate|upgrade}" >&2
		exit 3
		;;
esac
EOF

chmod +x /etc/init.d/nginx

# 创建 systemd 服务文件
log_info "创建 systemd 服务文件..."
mkdir -p /lib/systemd/system
cat > /lib/systemd/system/nginx.service << 'EOF'
[Unit]
Description=A high performance web server and a reverse proxy server
Documentation=man:nginx(8)
After=network.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/nginx -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx.pid
TimeoutStopSec=5
KillMode=mixed
LimitNOFILE=65535
LimitNPROC=65535

[Install]
WantedBy=multi-user.target
EOF

# 配置系统限制
log_info "配置系统文件限制..."
if ! grep -q "nginx soft nproc" /etc/security/limits.conf; then
    cat >> /etc/security/limits.conf << 'EOF'

# Nginx limits
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535

root soft nproc 65535
root hard nproc 65535
root soft nofile 65535
root hard nofile 65535
EOF
fi

# 创建默认 nginx 配置文件
log_info "创建 Nginx 配置文件..."
mkdir -p /etc/nginx/conf.d
cat > /etc/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;

error_log  /var/log/nginx/error.log warn;
pid        /run/nginx.pid;

include /usr/lib/nginx/modules/*.conf;

events {
    worker_connections 65535;
    multi_accept on;
    use epoll;
}

http {
    server_tokens off;
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    charset UTF-8;

    server_names_hash_bucket_size 128;
    client_header_buffer_size 2k;
    large_client_header_buffers 4 4k;
    client_max_body_size 4096m;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for" $request_time';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    keepalive_timeout  300;

    gzip on;
    gzip_min_length 1k;
    gzip_buffers 4 32k;
    gzip_http_version 1.1;
    gzip_comp_level 5;
    gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/javascript;
    gzip_vary on;
    gzip_proxied any;
    gzip_disable "MSIE [1-6]\.";
    map $http_upgrade $connection_upgrade {
           default upgrade;
           ''      close;
    }

    include /etc/nginx/conf.d/*.conf;
}

stream {
    upstream apiserver {
        server 127.0.0.1:8088 max_fails=3 fail_timeout=30s;
    }

    server {
        listen 0.0.0.0:18088;
        proxy_connect_timeout 2s;
        proxy_timeout 900s;
        proxy_pass apiserver;
    }
    log_format proxy '$remote_addr [$time_local]'
                '$status $bytes_sent'
                '"$upstream_addr" '
                '"$upstream_bytes_sent" "$upstream_bytes_received" "$upstream_connect_time"';
    access_log /var/log/nginx/tcp-access.log proxy;
    error_log  /var/log/nginx/tcp-error.log warn;
}
EOF

# 设置目录权限
log_info "设置目录权限..."
if id "nginx" >/dev/null 2>&1; then
    log_info "使用 nginx 用户设置权限"
    chown -R nginx:nginx /var/log/nginx/ || true
    chown -R nginx:nginx /var/lib/nginx/ || true
    chown -R nginx:nginx /var/cache/nginx/ || true
else
    log_warn "nginx 用户不存在，使用 nobody 用户"
    chown -R nobody:nogroup /var/log/nginx/ || true
    chown -R nobody:nogroup /var/lib/nginx/ || true
    chown -R nobody:nogroup /var/cache/nginx/ || true
fi

# 设置目录权限
chmod -R 755 /var/log/nginx/ || true
chmod -R 755 /var/lib/nginx/ || true
chmod -R 755 /var/cache/nginx/ || true

# 重新加载 systemd 并启动服务
log_info "重新加载 systemd 配置..."
systemctl daemon-reload

log_info "测试 Nginx 配置..."
if /usr/sbin/nginx -t; then
    log_info "启动 Nginx 服务..."
    systemctl start nginx
    systemctl enable nginx

    log_info "检查 Nginx 服务状态..."
    systemctl status nginx --no-pager

    log_info "Nginx 安装完成！"
    echo "安装信息："
    echo "- 配置文件: /etc/nginx/nginx.conf"
    echo "- 日志文件: /var/log/nginx/"
    echo "- 服务管理: systemctl {start|stop|restart|reload} nginx"
    echo "- 二进制文件: /usr/sbin/nginx"
else
    log_error "Nginx 配置测试失败，请检查配置"
    exit 1
fi

