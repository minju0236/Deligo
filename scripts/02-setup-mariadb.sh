#!/usr/bin/env bash
set -e
sudo service mariadb start
sudo mysql <<'SQL'
DROP DATABASE IF EXISTS deligo_db;
CREATE DATABASE deligo_db CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS 'testuser'@'localhost' IDENTIFIED BY '1234';
GRANT ALL PRIVILEGES ON deligo_db.* TO 'testuser'@'localhost';
FLUSH PRIVILEGES;
SQL
mysql -u testuser -p1234 -e "SHOW DATABASES LIKE 'deligo_db';"
echo "MariaDB reset complete: deligo_db / testuser / 1234"
