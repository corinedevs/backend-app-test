#!/bin/bash

# Update and install Nginx
sudo yum update -y
sudo amazon-linux-extras enable nginx1
sudo yum install -y nginx

# Enable and start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Replace default index.html with Hello World
cat <<EOF | sudo tee /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Hello World</title>
</head>
<body>
    <h1>Corine Test</h1>
</body>
</html>
EOF
