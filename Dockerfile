FROM amd64/debian:stable-slim

LABEL maintainer="admin@umod.org"

# misc prerequisites
RUN apt-get update && apt-get install -y --no-install-recommends wine && \
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
RUN apt-get update && apt-get install -y --no-install-recommends curl wget libarchive-tools && \
    mkdir -p /opt/wix/bin && \
    curl -kSL https://github.com/wixtoolset/wix3/releases/download/wix3112rtm/wix311-binaries.zip | \
    bsdtar -C /opt/wix/bin -xf - && sh /tmp/exelink.sh /opt/wix/bin && rm -f /tmp/exelink.sh && \
    apt-get purge -y --auto-remove --purge bsdtar && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc/* /usr/share/X11/locale
    
# dotnet
RUN wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    sudo dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y apt-transport-https && \
    apt-get update && \
    apt-get install -y dotnet-sdk-6.0

# create user and mount point
RUN useradd -m -s /bin/bash wix && mkdir /work && chown wix:wix -R /work
VOLUME /work

# prep wine and install .NET Framework 4.0
ENV WINEDEBUG=-all WD=/
RUN apt-get update && apt-get install -y --no-install-recommends curl procps && \
    echo insecure > /home/wix/.curlrc && \
    su -c "wine wineboot --init && waiton wineserver && winetricks --unattended --force dotnet40 && waiton wineserver" wix && \
    apt-get purge -y --auto-remove --purge procps && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc/* /usr/share/X11/locale \
    /home/wix/.wine/drive_c/users/wix/Temp/* /usr/local/bin/waiton /usr/local/bin/winetricks

ARG finaluser=wix
USER $finaluser
ENTRYPOINT ["pwrap"]
