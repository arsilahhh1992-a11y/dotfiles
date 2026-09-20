#!/bin/bash
set -e

echo "=== Starting Codespace Setup ==="

# 1. Set Zona Waktu WIB (Asia/Jakarta)
echo "[1/5] Setting Timezone to Asia/Jakarta (WIB)..."
sudo ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# 2. Install Build Dependencies untuk Python
echo "[2/5] Installing build dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq wget curl git build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev libncurses-dev xz-utils \
  tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev > /dev/null

# 3. Setup pyenv & Install Python 3.13.2
echo "[3/5] Setting up pyenv and Python 3.13.2..."
if [ ! -d "$HOME/.pyenv" ]; then
  curl -fsSL https://pyenv.run | bash
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
eval "$(pyenv init - bash)"

export MAKEFLAGS="-j$(nproc)"
pyenv install -s 3.13.2
pyenv global 3.13.2
pyenv rehash

# 4. Buat Executable Shortcut 'py' (Menghindari pyenv shim conflict)
echo "[4/5] Creating executable shortcut 'py'..."
mkdir -p "$HOME/bin"
cat << 'EOF' > "$HOME/bin/py"
#!/bin/bash
exec python "$@"
EOF
chmod +x "$HOME/bin/py"

# Daftarkan variabel lingkungan ke .bashrc dan .zshrc
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  touch "$rc"
  if ! grep -q 'PYENV_ROOT' "$rc" 2>/dev/null; then
    cat >> "$rc" << 'EOF'

# --- pyenv & custom bin setup ---
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$HOME/bin:$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init - bash)"
fi
EOF
  fi
done

export PATH="$HOME/bin:$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

# 5. Upgrade pip & Auto-install requirements.txt
echo "[5/5] Installing Python packages..."
python -m pip install --upgrade pip --quiet

REQ="$(find /workspaces -maxdepth 2 -name requirements.txt 2>/dev/null | head -n 1 || true)"
if [ -n "$REQ" ] && [ -f "$REQ" ]; then
  echo "Installing requirements from: $REQ"
  python -m pip install -r "$REQ"
fi

echo "=== Setup Completed Successfully! ==="
