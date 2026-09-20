#!/bin/bash
set -uo pipefail
exec > >(tee -a "$HOME/dotfiles-install.log") 2>&1
echo "[dotfiles] start $(date -Is)"

sudo ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime || true

sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  wget curl git build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev \
  xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

# --- Python: coba deadsnakes dulu (cepat), fallback pyenv ---
if ! command -v python3.13 >/dev/null 2>&1; then
  sudo apt-get install -y software-properties-common || true
  sudo add-apt-repository -y ppa:deadsnakes/ppa || true
  sudo apt-get update -y || true
  sudo apt-get install -y python3.13 python3.13-venv python3.13-dev python3-pip || true
fi

if command -v python3.13 >/dev/null 2>&1; then
  PYTHON=python3.13
else
  # fallback pyenv
  if [ ! -d "$HOME/.pyenv" ]; then
    curl -fsSL https://pyenv.run | bash || true
  fi
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)" || true
  pyenv install -s 3.13.9 || pyenv install -s 3.12.8 || true
  pyenv global 3.13.9 2>/dev/null || pyenv global 3.12.8 2>/dev/null || true
  PYTHON=python
fi

$PYTHON -m pip install --upgrade pip || true

# shortcut py
mkdir -p "$HOME/bin"
cat > "$HOME/bin/py" << 'EOF'
#!/bin/bash
exec python3.13 "$@" 2>/dev/null || exec python "$@"
EOF
chmod +x "$HOME/bin/py"

# PATH persist
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  touch "$rc"
  grep -q 'PYENV_ROOT\|HOME/bin' "$rc" 2>/dev/null || cat >> "$rc" << 'EOF'
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$HOME/bin:$PYENV_ROOT/bin:$PATH"
command -v pyenv >/dev/null && eval "$(pyenv init -)"
EOF
done
export PATH="$HOME/bin:${PYENV_ROOT:-$HOME/.pyenv}/bin:$PATH"

# requirements
REQ=""
[ -n "${CODESPACE_VSCODE_FOLDER:-}" ] && [ -f "$CODESPACE_VSCODE_FOLDER/requirements.txt" ] && REQ="$CODESPACE_VSCODE_FOLDER/requirements.txt"
[ -z "$REQ" ] && [ -n "${RepositoryName:-}" ] && [ -f "/workspaces/$RepositoryName/requirements.txt" ] && REQ="/workspaces/$RepositoryName/requirements.txt"
[ -z "$REQ" ] && REQ="$(find /workspaces -maxdepth 2 -name requirements.txt 2>/dev/null | head -n 1 || true)"
if [ -n "$REQ" ] && [ -f "$REQ" ]; then
  echo "Installing: $REQ"
  $PYTHON -m pip install -r "$REQ" || true
else
  echo "WARNING: requirements.txt tidak ditemukan"
fi

echo "=== selesai ==="
$PYTHON --version; which $PYTHON; which py || true
