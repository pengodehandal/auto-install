#!/bin/bash

# Fungsi untuk mencetak header
print_header() {
    echo "============================================================"
    echo "                  $1"
    echo "============================================================"
    echo ""
}

# Simpan waktu mulai
start_time=$(date +%s)

# Set noninteractive mode untuk semua apt commands
export DEBIAN_FRONTEND=noninteractive

# Display a message about what the script is doing
print_header "Starting System Update and Node.js Installation"

# Update package lists dengan menghindari semua konfirmasi
echo "🔄 Updating package lists..."
sudo apt-get update -y -qq

# Upgrade packages dengan option untuk menghindari semua konfirmasi
echo "🔄 Upgrading packages..."
sudo apt-get upgrade -y -qq -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef"

# Install Node.js and npm tanpa konfirmasi
echo "🔄 Installing Node.js and npm..."
sudo apt-get install -y -qq nodejs npm

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

# Install required npm modules dengan --yes flag untuk menghindari konfirmasi
echo "🔄 Installing npm modules: hpack, socks, colors, node-fetch@2, axios, http2-wrapper..."
npm_output=$(npm install --yes hpack socks colors node-fetch@2 axios http2-wrapper 2>&1)

# Periksa apakah modul berhasil diinstall
if [ $? -eq 0 ]; then
    modules_status="✅ Semua modul berhasil diinstall"
else
    echo "❌ Failed to install npm modules. Exiting..."
    exit 1
fi

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
echo "📝 Status: $modules_status"
echo ""
print_header "SISTEM SIAP DIGUNAKAN"
