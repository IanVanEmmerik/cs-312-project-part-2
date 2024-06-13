#!/bin/bash
# Install java and download the server
sudo yum install -y java-21-amazon-corretto-headless
mkdir /home/ec2-user/minecraft-server
cd /home/ec2-user/minecraft-server
wget https://piston-data.mojang.com/v1/objects/145ff0858209bcfc164859ba735d4199aafa1eea/server.jar

# Start the server
echo '#!/bin/bash' > start
echo 'java -Xmx1300M -Xms1300M -jar /home/ec2-user/minecraft-server/server.jar nogui' >> start
chmod +x start
echo "eula=true" | sudo tee /home/ec2-user/minecraft-server/eula.txt
sudo ./start &

# Set up service to start server after reboot
sudo tee /etc/systemd/system/minecraft.service > /dev/null << 'EOF'
[Unit]
Description=Start server after reboot
Wants=network-online.target
[Service]
WorkingDirectory=/home/ec2-user/minecraft-server
ExecStart=/home/ec2-user/minecraft-server/start
ExecStop=/usr/bin/pkill -f "java -Xmx1300M -Xms1300M -jar /home/ec2-user/minecraft-server/server.jar nogui"
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable minecraft.service
sudo systemctl start minecraft.service