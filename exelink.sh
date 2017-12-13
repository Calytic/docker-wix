#!/bin/bash
binlst=/usr/local/etc/wixbins.lst
if [ -d "$1" ] ; then
    touch $binlst
    find "$1" -name "*.exe" -type f -exec sh $0 "{}" \;
elif [ -f "$1" ] ; then
    bn=/usr/local/bin/`basename $1 .exe`
    ( echo '#!/bin/sh"; echo "exec wine "'$1'" "$@"' ) > "$bn"
    echo -n " \"`basename $1 .exe`\"" >> $binlst
    chmod +x $bn
fi
