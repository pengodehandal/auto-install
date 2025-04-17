#!/bin/bash

# Fungsi untuk mencetak header
print_header() {
    echo "============================================================"
    echo "                  $1"
    echo "============================================================"
    echo ""
}

# Fungsi untuk menunggu dan melepaskan lock apt
release_apt_lock() {
    echo "🔄 Checking for apt lock..."
    for i in {1..5}; do
        if sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
            echo "   - Apt lock detected, waiting... (Attempt $i/5)"
            sleep 5
        else
            echo "   - No apt lock detected, proceeding..."
            return 0
        fi
    done
    echo "❌ Apt lock still held. Attempting to kill locking process..."
    sudo kill -9 $(sudo fuser /var/lib/apt/lists/lock 2>/dev/null) 2>/dev/null
    sudo kill -9 $(sudo fuser /var/lib/dpkg/lock-frontend 2>/dev/null) 2>/dev/null
    sudo dpkg --configure -a
    sudo rm -f /var/lib/apt/lists/lock /var/lib/dpkg/lock-frontend
    echo "   - Lock released, proceeding..."
}

# Simpan waktu mulai
start_time=$(date +%s)

# Display a message about what the script is doing
print_header "Starting System Update and Node.js Installation"

# LANGKAH 1: Konfigurasi untuk menghindari semua prompt

# Set noninteractive mode untuk semua apt commands
export DEBIAN_FRONTEND=noninteractive

# Pre-seed debconf agar tidak meminta input
echo 'libc6 libraries/restart-without-asking boolean true' | sudo debconf-set-selections
echo 'libssl1.1 libraries/restart-without-asking boolean true' | sudo debconf-set-selections
echo 'libssl3 libraries/restart-without-asking boolean true' | sudo debconf-set-selections

# Konfigurasi needrestart untuk auto-restart tanpa prompt
sudo mkdir -p /etc/needrestart/conf.d
sudo tee /etc/needrestart/conf.d/no-prompt.conf > /dev/null << 'EOF'
$nrconf{restart} = 'a';
EOF

# Tambahkan opsi ke apt.conf untuk mencegah prompt konfigurasi
sudo tee /etc/apt/apt.conf.d/99custom-settings > /dev/null << 'EOF'
APT::Get::Assume-Yes "true";
APT::Get::allow-downgrades "true";
APT::Get::allow-remove-essential "true";
APT::Get::allow-change-held-packages "true";
DPkg::Options {"--force-confdef";"--force-confold";"--force-overwrite";"--force-unsafe-io"};
DPkg::Lock::Timeout "60";
APT::Install-Recommends "false";
APT::Install-Suggests "false";
APT::Get::Fix-Missing "true";
APT::Get::Fix-Broken "true";
Dpkg::Pre-Install-Pkgs {""};
Dpkg::Pre-Invoke {""};
Dpkg::Post-Invoke {""};
Dpkg::Post-Install-Pkgs {""};
Dir::Etc::SourceList "";
quiet "1";
EOF

# LANGKAH 2: Tambahkan repository NodeSource untuk Node.js
echo "🔄 Setting up NodeSource repository..."
release_apt_lock
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - || {
    echo "❌ Failed to set up NodeSource repository. Exiting..."
    exit 1
}

# LANGKAH 3: Update dan Upgrade sistem
echo "🔄 Updating package lists..."
release_apt_lock
for i in {1..3}; do
    sudo apt-get update -y -qq && break
    echo "   - Failed to update package lists (Attempt $i/3). Retrying..."
    sleep 2
done
if [ $? -ne 0 ]; then
    echo "❌ Failed to update package lists after retries. Exiting..."
    exit 1
fi

echo "🔄 Upgrading packages..."
yes | sudo DEBIAN_PRIORITY=critical apt-get -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade

# LANGKAH 4: Install Node.js dan npm
echo "🔄 Installing Node.js and npm..."
release_apt_lock
sudo apt-get install -qq -y nodejs || {
    echo "❌ Failed to install Node.js. Exiting..."
    exit 1
}

# Periksa apakah Node.js dan npm berhasil diinstall
if command -v node &> /dev/null && command -v npm &> /dev/null; then
    node_version=$(node -v)
    npm_version=$(npm -v)
    node_status="✅ Berhasil diinstall (versi $node_version)"
    npm_status="✅ Berhasil diinstall (versi $npm_version)"
else
    echo "❌ Failed to install Node.js and npm. Exiting..."
    exit 1
fi

# LANGKAH 5: Install required npm modules
echo "🔄 Installing npm modules: hpack, socks, colors, node-fetch@2, axios, http2-wrapper..."
npm config set yes true
npm_output=$(npm install hpack socks colors node-fetch@2 axios http2-wrapper 2>&1)

# Periksa apakah modul berhasil diinstall
if [ $? -eq 0 ]; then
    modules_status="✅ Semua modul berhasil diinstall"
else
    echo "❌ Failed to install npm modules. Exiting..."
    echo "Error details: $npm_output"
    exit 1
fi

# LANGKAH 6: Download script dari GitHub
echo "🔄 Downloading scripts from GitHub..."

# Download script-script dari repository langsung ke direktori saat ini
echo "   - Downloading RAW.js..."
wget -q https://raw.githubusercontent.com/pengodehandal/auto-install/refs/heads/main/RAW.js

echo "   - Downloading TLS.js..."
wget -q https://raw.githubusercontent.com/pengodehandal/auto-install/refs/heads/main/TLS.js

echo "   - Downloading bypass.js..."
wget -q https://raw.githubusercontent.com/pengodehandal/auto-install/refs/heads/main/bypass.js

echo "   - Downloading flash.js..."
wget -q https://raw.githubusercontent.com/pengodehandal/auto-install/refs/heads/main/flash.js

echo "   - Downloading pez.js..."
wget -q https://raw.githubusercontent.com/pengodehandal/auto-install/refs/heads/main/pez.js

# Periksa apakah file berhasil didownload
if [ -f "RAW.js" ] && [ -f "TLS.js" ] && [ -f "bypass.js" ] && [ -f "flash.js" ] && [ -f "pez.js" ]; then
    scripts_status="✅ Semua script berhasil didownload ke direktori saat ini"
else
    scripts_status="⚠️ Beberapa script gagal didownload"
fi

# LANGKAH 7: Cleanup setelah instalasi
echo "🔄 Cleaning up..."
sudo apt-get clean -qq

# Reset konfigurasi apt.conf dan needrestart
sudo rm -f /etc/apt/apt.conf.d/99custom-settings
sudo rm -f /etc/needrestart/conf.d/no-prompt.conf

# Hitung waktu yang diperlukan
end_time=$(date +%s)
duration=$((end_time - start_time))
minutes=$((duration / 60))
seconds=$((duration % 60))

# Clear console
clear

# Tampilkan ringkasan instalasi
print_header "INSTALASI SELESAI"
echo "⏱️ Waktu instalasi: $minutes menit $seconds detik"
echo ""
echo "📦 Paket yang diinstall:"
echo "   - Node.js: $node_status"
echo "   - npm: $npm_status"
echo ""
echo "📚 Modul npm yang diinstall:"
echo "   - hpack"
echo "   - socks"
echo "   - colors"
echo "   - node-fetch (versi 2)"
echo "   - axios"
echo "   - http2-wrapper"
echo ""
echo "📝 Status Modul: $modules_status"
echo ""
echo "📜 Download Script:"
echo "   - RAW.js"
echo "   - TLS.js"
echo "   - bypass.js"
echo "   - flash.js"
echo "   - pez.js"
echo ""
echo "📝 Status Scripts: $scripts_status"
echo ""
echo "📁 Lokasi script: $(pwd)/"
echo ""
print_header "SISTEM SIAP DIGUNAKAN"
