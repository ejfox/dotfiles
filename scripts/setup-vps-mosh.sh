#!/bin/bash
# Auto-install mosh server on VPS (run this on successful SSH connection)

echo "🚀 Setting up mosh server on VPS..."

# Check if already installed
if command -v mosh-server &> /dev/null; then
    echo "✓ Mosh server already installed"
    mosh-server -V
    exit 0
fi

# Install mosh
echo "📦 Installing mosh server..."
if command -v apt-get &> /dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y mosh
elif command -v yum &> /dev/null; then
    sudo yum install -y mosh
elif command -v pacman &> /dev/null; then
    sudo pacman -S --noconfirm mosh
else
    echo "❌ Unknown package manager. Install mosh manually:"
    echo "   Debian/Ubuntu: sudo apt-get install mosh"
    echo "   RedHat/CentOS: sudo yum install mosh"
    exit 1
fi

# Verify installation
if command -v mosh-server &> /dev/null; then
    echo "✓ Mosh server installed successfully"
    mosh-server -V

    # Open firewall if ufw is active
    if command -v ufw &> /dev/null && sudo ufw status | grep -q "Status: active"; then
        echo "🔓 Opening mosh ports in firewall..."
        sudo ufw allow 60000:61000/udp
        echo "✓ Firewall configured"
    fi
else
    echo "❌ Installation failed"
    exit 1
fi

echo ""
echo "✓ VPS is now mosh-ready!"
echo "   Connect from Mac with: vps"
