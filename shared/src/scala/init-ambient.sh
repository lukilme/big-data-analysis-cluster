

apt-get install -y curl gnupg software-properties-common

curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x99E82A75642AC823" | gpg --dearmor > /usr/share/keyrings/sbt-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/sbt-keyring.gpg] https://repo.scala-sbt.org/scalasbt/debian all main" > /etc/apt/sources.list.d/sbt.list
echo "deb [signed-by=/usr/share/keyrings/sbt-keyring.gpg] https://repo.scala-sbt.org/scalasbt/debian /" >> /etc/apt/sources.list.d/sbt.list

apt-get update
apt-get install -y scala sbt