#!/bin/sh

VERSION=$(fgrep "our \$VERSION" /usr/local/slimserver/slimserver.pl 2>/dev/null | cut -d"'" -f2 || echo '0.0.0')
REVISION=$(head -n 1 slimserver/revision.txt 2>/dev/null || echo '0000000000')

UPDATE_TMP="/tmp/slimUpdate"
BUILD_DIR="$GITHUB_WORKSPACE"

case $RELEASE in
	release) LATEST="http://downloads.slimdevices.com/releases/latest.xml";;
	stable) LATEST="http://downloads.slimdevices.com/releases/nightly/stable.xml";;
	devel) LATEST="http://downloads.slimdevices.com/releases/nightly/dev.xml";;
	*) LATEST="http://downloads.slimdevices.com/releases/latest.xml";;
esac

tmp=$(mktemp)
wget -q $LATEST -O $tmp
	
# Add linefeeds after elements for parsing
sed -E -i 's/>/>\n/g' $tmp

while read line
do
    echo $line | grep -q nocpan
    if [ $? -eq 0 ]
    then
	    NOCPAN=$(echo $line)
	fi
done < $tmp
rm -f $tmp

if [ "$NOCPAN" != "" ]
then
    NEW_REVISION=$(echo $NOCPAN | awk -F'revision=' '{print $2}' | cut -d' ' -f1 | sed 's|/>||' | sed 's|"||g')
    NEW_URL=$(echo $NOCPAN | awk -F'url=' '{print $2}' | cut -d' ' -f1 | sed 's|/>||' | sed 's|"||g')
    NEW_VERSION=$(echo $NOCPAN | awk -F'version=' '{print $2}' | cut -d' ' -f1 | sed 's|/>||' | sed 's|"||g')
    UPD_FILE=${NEW_URL##*/}
else
	echo "No update information returned from slimdevices.com. There may not be current packages for the"
	echo "release branch selected"
	exit 1
fi

if [ "$NEW_REVISION" -eq "$REVISION" ]
then
	echo "Already latest version, nothing todo."
	exit 0
fi

echo "Downloading update from ${NEW_URL}"
mkdir -p $UPDATE_TMP $BUILD_DIR
rm -f $UPDATE_TMP/*.tgz
#rm -rfv $BUILD_DIR/*
wget -P $UPDATE_TMP $NEW_URL || exit 1

tar -zxvf ${UPDATE_TMP}/${UPD_FILE} \
    -C $BUILD_DIR --strip-components=1

rm -rfv $BUILD_DIR/CPAN/Font
rm -rfv $BUILD_DIR/CPAN/arch
rm -rfv $BUILD_DIR/lib/Audio
rm -rfv $BUILD_DIR/Bin/*
rm -fv $BUILD_DIR/License.*.txt
rm -fv $BUILD_DIR/Changelog.html
rm -fv $BUILD_DIR/Changelog1.html
rm -fv $BUILD_DIR/Changelog2.html
rm -fv $BUILD_DIR/Changelog3.html
rm -fv $BUILD_DIR/Changelog4.html
rm -fv $BUILD_DIR/Changelog5.html
rm -fv $BUILD_DIR/Changelog6.html
rm -fv $BUILD_DIR/Changelog7.html
rm -fv $BUILD_DIR/icudt46*
rm -fv $BUILD_DIR/icudt58b.dat

#51.9M
du -h $BUILD_DIR
