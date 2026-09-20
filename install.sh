#!/bin/bash
set -e

# ============================================================
# 1. Zona waktu WIB (dari dotfiles lama)
# ============================================================
sudo ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# ============================================================
# 2. Tools (wget dari dotfiles lama + deps build untuk pyenv)
# ============================================================
sudo apt-get update
sudo apt-get install -y wget curl git build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev xz-utils \
  tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

# ============================================================
# 3. pyenv + Python 3.13
# ============================================================
if [ ! -d "$HOME/.pyenv" ]; then
  curl -fsSL https://pyenv.run | bash
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

pyenv install -s 3.13.9
pyenv global 3.13.9
pyenv rehash

# ============================================================
# 4. Upgrade pip (dari dotfiles lama — sekarang di Python 3.13)
# ============================================================
python -m pip install --upgrade pip

# ============================================================
# 5. Shortcut `py` → Python 3.13
# ============================================================
mkdir -p "$HOME/bin"
cat > "$HOME/bin/py" << 'EOF'
#!/bin/bash
# py bot.py  ==  python 3.13 bot.py
exec python "$@"
EOF
chmod +x "$HOME/bin/py"

# ============================================================
# 6. Persist pyenv + ~/bin di bash/zsh
# ============================================================
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  touch "$rc"
  if ! grep -q 'PYENV_ROOT' "$rc" 2>/dev/null; then
    cat >> "$rc" << 'EOF'

# --- pyenv + Python 3.13 + shortcut py ---
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$HOME/bin:$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi
EOF
  fi
done

export PATH="$HOME/bin:$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# ============================================================
# 7. Install requirements.txt pakai Python 3.13
# ============================================================
# Cari requirements di workspace Codespace (repo yang di-clone)
REQ=""
if [ -n "${CODESPACE_VSCODE_FOLDER:-}" ] && [ -f "${CODESPACE_VSCODE_FOLDER}/requirements.txt" ]; then
  REQ="${CODESPACE_VSCODE_FOLDER}/requirements.txt"
elif [ -f "/workspaces/loketsecuredbunchookie/requirements.txt" ]; then
  REQ="/workspaces/loketsecuredbunchookie/requirements.txt"
else
  # fallback: requirements.txt pertama di /workspaces/*
  REQ="$(find /workspaces -maxdepth 2 -name requirements.txt 2>/dev/null | head -n 1 || true)"
fi

if [ -n "$REQ" ] && [ -f "$REQ" ]; then
  echo "Installing requirements from: $REQ"
  python -m pip install -r "$REQ"
else
  echo "WARNING: requirements.txt tidak ditemukan — skip pip install -r"
fi

# ============================================================
# 8. Verifikasi
# ============================================================
echo "=== setup selesai ==="
echo "python : $(python --version 2>&1) @ $(which python)"
echo "py     : $(py --version 2>&1) @ $(which py)"
echo "pip    : $(python -m pip --version 2>&1)"
