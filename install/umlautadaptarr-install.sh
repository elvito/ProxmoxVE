#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: [YourUserName]
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: [SOURCE_URL]

# Import Functions und Setup
source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Installing Dependencies
msg_info "Installing Dependencies"
$STD apt update 
$STD apt upgrade -y
$STD wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
$STD dpkg -i packages-microsoft-prod.deb
$STD apt-get update
$STD apt-get install -y \
  curl \
  unzip \
  git \
  dotnet-sdk-8.0 \
  aspnetcore-runtime-8.0
  msg_ok "Installed Dependencies"
  
# Building & Installing UA
msg_info "Building & Installing Umlautadaptarr"
$STD git clone https://github.com/PCJones/UmlautAdaptarr.git /opt/
$STD cd /opt/UmlautAdaptarr
$STD dotnet restore
$STD dotnet build --configuration Release
msg_ok "Installation completed"
# Configure appsettings.json
msg_info "Creating appsettings.json"
cat <<EOF >/opt/UmlautAdaptarr/appsettings.json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    },
    "Console": {
      "TimestampFormat": "yyyy-MM-dd HH:mm:ss::"
    }
  },
  "AllowedHosts": "*",
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://[::]:5005"
      }
    }
  },
  "Settings": {
    "UserAgent": "UmlautAdaptarr/1.0",
    "UmlautAdaptarrApiHost": "https://umlautadaptarr.pcjones.de/api/v1",
    "IndexerRequestsCacheDurationInMinutes": 12
  },
  "Sonarr": [
    {
      "Enabled": false,
      "Name": "Sonarr",
      "Host": "http://192.168.1.100:8989",
      "ApiKey": "dein_sonarr_api_key"
    }
  ],
  "Radarr": [
    {
      "Enabled": false,
      "Name": "Radarr",
      "Host": "http://192.168.1.101:7878",
      "ApiKey": "dein_radarr_api_key"
    }
  ],
  "Lidarr": [
  {
    "Enabled": false,
    "Host": "http://192.168.1.102:8686",
    "ApiKey": "dein_lidarr_api_key"
  },
 ],
  "Readarr": [
  {
    "Enabled": false,
    "Host": "http://192.168.1.103:8787",
    "ApiKey": "dein_readarr_api_key"
  },
 ],
  "IpLeakTest": {
    "Enabled": false
  }
}
EOF
msg_ok "appsettings.json created"

# Set up systemd service for UmlautAdaptarr
msg_info "Creating systemd Service"   
cat <<EOF >/etc/systemd/system/umlautadaptarr.service
[Unit]
Description=UmlautAdaptarr Service
After=network.target

[Service]
Type=Core
WorkingDirectory=/opt/UmlautAdaptarr
ExecStart=/usr/bin/dotnet /opt/UmlautAdaptarr/bin/Release/net8.0/UmlautAdaptarr.dll --urls=http://0.0.0.0:5005
Restart=always
User=root
Group=root
Environment=ASPNETCORE_ENVIRONMENT=Production

[Install]
WantedBy=multi-user.target
EOF
$STD systemctl daemon-reload
$STD systemctl enable umlautadaptarr.service
$STD systemctl start umlautadaptarr
msg_ok "Created systemd Service"

motd_ssh
customize

# Cleanup
msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
