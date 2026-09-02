#!/bin/bash

# 1. Mengatur Zona Waktu otomatis ke WIB (Asia/Jakarta)
sudo ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# 2. Memastikan wget dan tools penting lainnya terinstall
sudo apt-get update && sudo apt-get install -y wget

# 3. Update pip dan package Python bawaan jika diperlukan
pip install --upgrade pip
