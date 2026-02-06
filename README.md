# IKEv2 → SOCKS5 (ikev2socks)

Turn any **IKEv2 VPN** into a local **SOCKS5 proxy** using Docker.\
This project establishes an IKEv2 tunnel with **strongSwan** and exposes
it locally via **gost** as a SOCKS5 proxy.

------------------------------------------------------------------------

## ✨ Features

-   🔐 Connect to IKEv2 VPN servers using strongSwan
-   🌐 Expose VPN traffic as a local SOCKS5 proxy
-   🐳 Simple Docker-based deployment
-   ⚙️ Supports multiple IKEv2 connections
-   🧩 Easy integration with crawlers, browsers, and automation tools

------------------------------------------------------------------------

## 🧠 How It Works

1.  **strongSwan** establishes the IKEv2 VPN connection.
2.  **gost** starts a local SOCKS5 server.
3.  All SOCKS5 traffic is routed through the VPN tunnel.

Architecture:

Local App → SOCKS5 → gost → strongSwan → IKEv2 VPN → Internet

------------------------------------------------------------------------

## 🚀 Quick Start

Run the container:

``` bash
docker run -d   --cap-add=NET_ADMIN   -e TIMEOUT=120   -p 1080:1080   -v <your ipsec.conf>:/etc/ipsec.conf   -v <your ipsec.secrets>:/etc/ipsec.secrets   --name ikev2socks   chenfeicqq/ikev2socks:latest
```

### Environment Variables

  -----------------------------------------------------------------------
  Variable                            Description
  ----------------------------------- -----------------------------------
  `TIMEOUT`                           Connection timeout in seconds. When
                                      multiple `conn` profiles exist,
                                      this applies to each connection.

  -----------------------------------------------------------------------

Default SOCKS5 endpoint:

    socks5://127.0.0.1:1080

------------------------------------------------------------------------

## ⚙️ Configuration

You must provide two files:

-   `ipsec.conf`
-   `ipsec.secrets`

Mount them into the container.

------------------------------------------------------------------------

### ipsec.conf Example

``` conf
config setup
    charondebug="ike 2, knl 2, cfg 2, net 2, esp 2, dmn 2, mgr 2"

conn vpn
    left=%config
    leftsourceip=%config
    leftauth=eap-gtc
    right=<remote server>
    rightsubnet=0.0.0.0/0
    rightid=<remote id>
    rightauth=pubkey
    eap_identity=<username>
    auto=add
```

Notes:

-   You can declare **multiple `conn` profiles**
-   `<remote server>` → VPN server address
-   `<remote id>` → VPN remote ID (usually domain)
-   `<username>` → VPN username

------------------------------------------------------------------------

### ipsec.secrets Example

``` conf
<username> : EAP <password>
```

------------------------------------------------------------------------

## 🔌 Usage Examples

### Use with curl

``` bash
curl --socks5 127.0.0.1:1080 https://ifconfig.me
```

### Use with Node.js

``` js
import axios from "axios";
import { SocksProxyAgent } from "socks-proxy-agent";

const agent = new SocksProxyAgent("socks5://127.0.0.1:1080");

const res = await axios.get("https://ipinfo.io", { httpAgent: agent, httpsAgent: agent });
console.log(res.data);
```

------------------------------------------------------------------------

## 🧪 Common Use Cases

-   Web scraping through IKEv2 VPN
-   Testing geo‑restricted services
-   Privacy & traffic routing
-   Proxying automation tools and bots

------------------------------------------------------------------------

## ⚠️ Notes

-   Container requires `NET_ADMIN` capability.
-   Ensure your VPN provider supports **IKEv2 EAP authentication**.
-   Multiple connections may increase startup time.

------------------------------------------------------------------------

## 📜 License

This project is based on the original image by **chenfeicqq** and is
provided for educational and research purposes.

------------------------------------------------------------------------

## ⭐ Support

If this project helps you, consider giving it a ⭐ on GitHub!
