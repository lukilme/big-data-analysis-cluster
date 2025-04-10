FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    python3-dev \
    python3-venv \
    libkrb5-dev \
    libmysqlclient-dev \
    libssl-dev \
    libldap2-dev \
    libsasl2-dev \
    libxml2-dev \
    libxslt-dev \
    libsqlite3-dev \
    libffi-dev \
    libjpeg-dev \
    zlib1g-dev \
    libpq-dev \
    nodejs \
    npm \
    libbz2-dev \
    libreadline-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxmlsec1-dev \
    liblzma-dev \
    openjdk-11-jdk \
    wget \
    curl \
    unzip \
    apt-transport-https \
    software-properties-common \
    ssh \
    rsync \
    python3 \
    python3-pip \
    mysql-server \
    libmariadb-java \
    vim \
    net-tools \
    git \
    gcc \
    g++ \
    make \
    && apt-get clean

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$PATH:$JAVA_HOME/bin

RUN useradd -m -s /bin/bash hadoop
RUN echo "hadoop:hadoop" | chpasswd
RUN adduser hadoop sudo

RUN mkdir -p /home/hadoop/.ssh
RUN ssh-keygen -t rsa -P '' -f /home/hadoop/.ssh/id_rsa
RUN cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys
RUN chmod 0600 /home/hadoop/.ssh/authorized_keys
RUN chown -R hadoop:hadoop /home/hadoop/.ssh

ENV HADOOP_VERSION=3.3.5
ENV HADOOP_HOME=/opt/hadoop
RUN wget https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz && \
    mv hadoop-${HADOOP_VERSION} ${HADOOP_HOME} && \
    rm hadoop-${HADOOP_VERSION}.tar.gz

ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

COPY shared/config/core-site.xml $HADOOP_CONF_DIR/
COPY shared/config/hdfs-site.xml $HADOOP_CONF_DIR/
COPY shared/config/mapred-site.xml $HADOOP_CONF_DIR/
COPY shared/config/yarn-site.xml $HADOOP_CONF_DIR/

ENV HIVE_VERSION=4.0.1
ENV HIVE_HOME=/opt/hive
RUN wget https://downloads.apache.org/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz && \
    tar -xzf apache-hive-${HIVE_VERSION}-bin.tar.gz && \
    mv apache-hive-${HIVE_VERSION}-bin ${HIVE_HOME} && \
    rm apache-hive-${HIVE_VERSION}-bin.tar.gz

ENV PATH=$PATH:$HIVE_HOME/bin
ENV HIVE_CONF_DIR=${HIVE_HOME}/conf

RUN ln -s /usr/share/java/mysql-connector-java.jar ${HIVE_HOME}/lib/

COPY shared/config/hive-site.xml $HIVE_CONF_DIR/

ENV SPARK_VERSION=3.4.4
ENV SPARK_HOME=/opt/spark
RUN wget https://downloads.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz && \
    tar -xzf spark-${SPARK_VERSION}-bin-hadoop3.tgz && \
    mv spark-${SPARK_VERSION}-bin-hadoop3 ${SPARK_HOME} && \
    rm spark-${SPARK_VERSION}-bin-hadoop3.tgz

ENV PATH=$PATH:$SPARK_HOME/bin
ENV SPARK_CONF_DIR=${SPARK_HOME}/conf

COPY shared/config/spark-defaults.conf $SPARK_CONF_DIR/

ENV SQOOP_VERSION=1.4.7
ENV SQOOP_HOME=/opt/sqoop
RUN wget https://archive.apache.org/dist/sqoop/1.4.7/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz && \
    tar -xzf sqoop-${SQOOP_VERSION}.bin__hadoop-2.6.0.tar.gz && \
    mv sqoop-${SQOOP_VERSION}.bin__hadoop-2.6.0 ${SQOOP_HOME} && \
    rm sqoop-${SQOOP_VERSION}.bin__hadoop-2.6.0.tar.gz

ENV PATH=$PATH:$SQOOP_HOME/bin
ENV SQOOP_CONF_DIR=${SQOOP_HOME}/conf

RUN ln -s /usr/share/java/mysql-connector-java.jar ${SQOOP_HOME}/lib/

ENV HUE_VERSION=4.11.0
RUN wget https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz && \
    tar xvf Python-2.7.18.tgz && \
    cd Python-2.7.18 && \
    ./configure \
        --enable-optimizations \
        --with-ensurepip=install \
        --enable-unicode=ucs4 \
        --with-system-ffi \
        --with-openssl=/usr/include/openssl \
        LDFLAGS="-L/usr/lib/x86_64-linux-gnu" && \
    make -j$(nproc) && \
    make altinstall && \
    cd .. && \
    rm -rf Python-2.7.18*

RUN python2.7 --version

ENV MYSQL_CONNECTOR_VERSION=8.0.33

RUN wget https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/${MYSQL_CONNECTOR_VERSION}/mysql-connector-j-${MYSQL_CONNECTOR_VERSION}.jar -O /usr/share/java/mysql-connector-java.jar

RUN wget https://github.com/cloudera/hue/archive/refs/tags/release-${HUE_VERSION}.tar.gz && \
    tar -xzf release-${HUE_VERSION}.tar.gz && \
    mv hue-release-${HUE_VERSION} /opt/hue && \
    rm release-${HUE_VERSION}.tar.gz

RUN pip3 install --upgrade pip

WORKDIR /opt/hue

COPY shared/config/hue.ini /opt/hue/desktop/conf/

RUN chown -R hadoop:hadoop /opt/hadoop /opt/hive /opt/spark /opt/sqoop /opt/hue

RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld

RUN service mysql start && \
    mysql -uroot -e " \
        CREATE DATABASE metastore; \
        CREATE DATABASE hue; \
        CREATE USER 'hive'@'localhost' IDENTIFIED BY 'hivepw'; \
        GRANT ALL PRIVILEGES ON *.* TO 'hive'@'localhost'; \
        CREATE USER 'hue'@'localhost' IDENTIFIED BY 'huepw'; \
        GRANT ALL PRIVILEGES ON *.* TO 'hue'@'localhost'; \
        FLUSH PRIVILEGES; \
    "
COPY start-services.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-services.sh

WORKDIR /

EXPOSE 8088 9870 8080 8888 3306 10000 4040

CMD ["/bin/bash"]