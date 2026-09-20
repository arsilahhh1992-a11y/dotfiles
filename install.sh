cat > ~/dotfiles/install.sh << 'EOF'
#!/bin/bash
set -e

echo "=== 1. Setting Timezone ke Asia/Jakarta ==="
sudo ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

echo "=== 2. Update System & Install Dependencies pyenv ==="
sudo apt-get update
sudo apt-get install -y wget curl git build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev libncurses-dev xz-utils \
  tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

echo "=== 3. Setup pyenv & Install Python 3.13.2 ==="
if [ ! -d "$HOME/.pyenv" ]; then
  curl -fsSL https://pyenv.run | bash
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"

# Gunakan semua core CPU agar proses kompilasi cepat
export MAKEFLAGS="-j$(nproc)"

pyenv install -s 3.13.2
pyenv global 3.13.2
pyenv rehash

echo "=== 4. Upgrade Pip ==="
python -m pip install --upgrade pip

echo "=== 5. Buat Shortcut `py` -> `python 3.13` ==="
mkdir -p "$HOME/bin"
cat > "$HOME/bin/py" << 'INNER_EOF'
#!/bin/bash
exec python "$@"
INNER_EOF
chmod +x "$HOME/bin/py"

echo "=== 6. Konfigurasi Permanen di Shell (.bashrc & .zshrc) ==="
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  touch "$rc"
  if ! grep -q 'PYENV_ROOT' "$rc" 2>/dev/null; then
    cat >> "$rc" << 'INNER_EOF'

# --- pyenv + Python 3.13 + shortcut py ---
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$HOME/bin:$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init - bash)"
fi
INNER_EOF
  fi
done

export PATH="$HOME/bin:$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"

echo "=== 7. Auto Install requirements.txt ==="
REQ=""
if [ -n "${CODESPACE_VSCODE_FOLDER:-}" ] && [ -f "${CODESPACE_VSCODE_FOLDER}/requirements.txt" ]; then
  REQ="${CODESPACE_VSCODE_FOLDER}/requirements.txt"
elif [ -f "/workspaces/loketsecuredbunchookie/requirements.txt" ]; then
  REQ="/workspaces/loketsecuredbunchookie/requirements.txt"
else
  REQ="$(find /workspaces -maxdepth 2 -name requirements.txt 2>/dev/null | head -n 1 || true)"
fi

if [ -n "$REQ" ] && [ -f "$REQ" ]; then
  echo "Installing requirements from: $REQ"
  python -m pip install -r "$REQ"
else
  echo "WARNING: requirements.txt tidak ditemukan — skip pip install -r"
fi

echo "=== 8. Verifikasi Instalasi ==="
echo "Timezone : $(date)"
echo "python   : $(python --version 2>&1) @$(which python)"
echo "py       : $(py --version 2>&1) @$(which py)"
echo "pip      : $(python -m pip --version 2>&1)"
echo "=== Setup Selesai! ==="
EOF

chmod +x ~/dotfiles/install.sh
