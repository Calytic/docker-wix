FROM amd64/debian:stable-slim

LABEL maintainer="admin@umod.org"

# misc prerequisites
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends wine32 && \
    apt-get purge -y --auto-remove --purge tzdata && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy resources
ADD exelink.sh /tmp/
ADD pwrap waiton mkhostwrappers /usr/local/bin/

# winetricks
RUN apt-get update && apt-get install -y --no-install-recommends curl && \
    curl -kSL https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
    > /usr/local/bin/winetricks && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc/* /usr/share/X11/locale && \
    chmod +x /usr/local/bin/*

# wix
RUN apt-get update && apt-get install -y --no-install-recommends curl wget ca-certificates gpg apt-transport-https libarchive-tools && \
    mkdir -p /opt/wix/bin && \
    curl -kSL https://github.com/wixtoolset/wix3/releases/download/wix3112rtm/wix311-binaries.zip | \
    bsdtar -C /opt/wix/bin -xf - && sh /tmp/exelink.sh /opt/wix/bin && rm -f /tmp/exelink.sh && \
    apt-get purge -y --auto-remove --purge libarchive-tools && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc/* /usr/share/X11/locale
    
# dotnet
RUN wget -O - https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o microsoft.asc.gpg && \
    mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/ && \
    wget https://packages.microsoft.com/config/debian/11/prod.list && \
    mv prod.list /etc/apt/sources.list.d/microsoft-prod.list && \
    apt-get update && \
    apt-get install -y dotnet-sdk-6.0

# create user and mount point
RUN useradd -m -s /bin/bash wix && mkdir /work && chown wix:wix -R /work
VOLUME /work

# prep wine and install .NET Framework 4.0
ENV WINEDEBUG=-all WD=/ WINEARCH=win32
RUN apt-get update && apt-get install -y --no-install-recommends procps && \
    su -c "wine wineboot --init && waiton wineserver && winetricks --unattended --force dotnet40 && waiton wineserver" wix && \
    apt-get purge -y --auto-remove --purge wget ca-certificates gpg apt-transport-https procps && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc/* /usr/share/X11/locale \
    /home/wix/.wine/drive_c/users/wix/Temp/* /usr/local/bin/waiton /usr/local/bin/winetricks

ARG finaluser=wix
USER $finaluser
ENTRYPOINT ["pwrap"]
