cd ~/dotfiles

# 1. Tulis ulang install.sh yang sudah include py, python 3.13, timezone WIB, & auto PATH
cat > install.sh << 'EOF'
#!/bin/bash
set -e

# 1. Set Zona Waktu WIB (Asia/Jakarta)
sudo ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# 2. Install Build Dependencies
sudo apt-get update
sudo apt-get install -y wget curl git build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev libncurses-dev xz-utils \
  tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

# 3. Setup pyenv & Install Python 3.13.2
if [ ! -d "$HOME/.pyenv" ]; then
  curl -fsSL https://pyenv.run | bash
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"

export MAKEFLAGS="-j$(nproc)"
pyenv install -s 3.13.2
pyenv global 3.13.2
pyenv rehash

# 4. Upgrade pip & Buat Shortcut `py`
python -m pip install --upgrade pip

mkdir -p "$HOME/bin"
cat > "$HOME/bin/py" << 'INNER_EOF'
#!/bin/bash
exec python "$@"
INNER_EOF
chmod +x "$HOME/bin/py"

# 5. Daftarkan Permanen di .bashrc & .zshrc
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  touch "$rc"
  if ! grep -q 'PYENV_ROOT' "$rc" 2>/dev/null; then
    cat >> "$rc" << 'INNER_EOF'

# --- pyenv + Python 3.13 + shortcut py ---
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$HOME/bin:$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init - bash)"
fi
INNER_EOF
  fi
done

export PATH="$HOME/bin:$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
eval "$(pyenv init - bash)"

# 6. Auto Install requirements.txt (jika ada di workspace)
REQ="$(find /workspaces -maxdepth 2 -name requirements.txt 2>/dev/null | head -n 1 || true)"
if [ -n "$REQ" ] && [ -f "$REQ" ]; then
  echo "Installing requirements from: $REQ"
  python -m pip install -r "$REQ"
fi

echo "=== Setup Dotfiles Selesai! ==="
EOF

chmod +x install.sh

# 2. Sambungkan ke Repository GitHub Anda dan Push
git remote set-url origin https://github.com/yuniherima2-droid/dotfiles.git
git add install.sh
git commit -m "Fix install.sh for automatic codespace bootstrap"
git push -u origin main
