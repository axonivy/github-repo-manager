FROM maven:3.8.5-eclipse-temurin-11

RUN addgroup --gid 1000 build && adduser --uid 1000 --gid 1000 --disabled-password --gecos "" build && \
    apt-get update && \
    apt-get install git gettext-base wget unzip -y
