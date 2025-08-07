sudo apt update -y
sudo apt install git -y
sudo apt install openjdk-17-jdk -y
java -version
sudo snap install ngrok

sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update -y
sudo apt install jenkins -y
sudo systemctl start jenkins
sudo systemctl enable jenkins

sudo groupadd tomcat
sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat
cd /tmp
wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.67/bin/apache-tomcat-9.0.67.tar.gz
sudo mkdir -p /opt/tomcat
sudo tar xzvf apache-tomcat-9.0.67.tar.gz -C /opt/tomcat --strip-components=1
sudo chown -R tomcat:tomcat /opt/tomcat

sudo tee /etc/systemd/system/tomcat.service <<EOL
[Unit]
Description=Apache Tomcat 9
After=network.target
[Service]
Type=forking
User=tomcat
Group=tomcat
Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk-arm64"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_BASE=/opt/tomcat"
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
[Install]
WantedBy=multi-user.target
EOL

sudo sed -i  's/Connector port="8080"/Connector port="8090"/' /opt/tomcat/conf/server.xml

sudo sed -i '72i \
    <Connector port="9090" protocol="HTTP/1.1"\
               connectionTimeout="20000"\
               redirectPort="8445" />' /opt/tomcat/conf/server.xml

sudo sed -i '56i\
  <role rolename="manager-gui"/>\
  <role rolename="manager-script"/>\
  <user username="tomcat" password="tomcat" roles="manager-gui,manager-script"/>' /opt/tomcat/conf/tomcat-users.xml 

sudo sed -i '22i\\tallow="^.*$" />' /opt/tomcat/webapps/manager/META-INF/context.xml
sudo sed -i '23d' /opt/tomcat/webapps/manager/META-INF/context.xml

sudo systemctl daemon-reload
sudo systemctl start tomcat
sudo systemctl enable tomcat

cd /tmp
wget https://archive.apache.org/dist/maven/maven-3/3.8.8/binaries/apache-maven-3.8.8-bin.tar.gz
sudo tar xf apache-maven-3.8.8-bin.tar.gz -C /opt
sudo ln -s /opt/apache-maven-3.8.8 /opt/maven

sudo tee /etc/profile.d/maven.sh <<EOL
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-arm64
export M2_HOME=/opt/maven
export MAVEN_HOME=/opt/maven
#export PATH=${M2_HOME}/bin:${PATH}
export PATH=$PATH:/opt/maven/bin
EOL

sudo chmod +x /etc/profile.d/maven.sh

sudo timedatectl set-timezone Asia/Kolkata
