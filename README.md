# 一键安装 v2ray + websocket + TLS 和 Shadowsocks 科学上网

### 准备

- 国外服务器
- 域名

### 开始

> 将服务器公网`IP`地址解析到准备的域名，然后利用`root`用户登录服务器

> CentOS
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/athlonreg/one-key-vmess/master/okv-centos.sh)"
```

> Debian
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/athlonreg/one-key-vmess/master/okv-debian.sh)"
```

根据提示进行交互安装即可。

### 本项目可以做什么

:white_check_mark:`v2ray`

:white_check_mark:`websocket(nginx)`

:white_check_mark:`TLS`

:white_check_mark:`shadowsocks`

:white_check_mark:`SS`多端口

:white_check_mark:`SS` 多协议定制

:white_check_mark:`vmess`端口定制​

:white_check_mark:`TLS`加密

:white_check_mark:站点伪装​

### 感谢

[v2ray](https://github.com/v2ray)

[shadowsocks](https://github.com/shadowsocks)

[nginx]( https://nginx.org/ )