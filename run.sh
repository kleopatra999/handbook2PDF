#!/bin/bash

# move to current directory
ABSPATH=$(cd "$(dirname "$0")"; pwd)
echo $ABSPATH
cd $ABSPATH

WKHTML=./wkhtmltox/bin/wkhtmltopdf

LANGUAGES=( en af de ar be bg ca cs da et el es eo fa eu fr gl ko sr hr id it he lt hu nl ja nb pl pt-br pt-pt ro ru sk sl fi sv vi tr uk zh-hans zh-hant )
NID=36546

LANGUAGE_COUNT=${#LANGUAGES[@]}
INDEX=0


# instal ssh key
openssl aes-256-cbc -K $encrypted_00bb55250e56_key -iv $encrypted_00bb55250e56_iv -in resources/osuosl_nighlies_rsa.enc -out resources/osuosl_nighlies_rsa -d
# Make ssh dir
mkdir $HOME/.ssh/
# Copy over private key, and set permissions
cp resources/osuosl_nighlies_rsa $HOME/.ssh/osuosl_nighlies_rsa
# set permission
chmod 600 $HOME/.ssh/osuosl_nighlies_rsa
# Create known_hosts
touch $HOME/.ssh/known_hosts
# Add osuosl key to known host
ssh-keyscan ftp-osl.osuosl.org >> $HOME/.ssh/known_hosts

eval "$(ssh-agent -s)"
expect << EOF
  spawn ssh-add $HOME/.ssh/osuosl_nighlies_rsa
  expect "Enter passphrase"
  send "${OSUOSL_NIGHTLY_PASSPHRASE}\r"
  expect eof
EOF
SSH_INDENTITY=$HOME/.ssh/osuosl_nighlies_rsa

while [ "$INDEX" -lt "$LANGUAGE_COUNT" ]
do
    LANGUAGE=${LANGUAGES[$INDEX]}
    echo "update handbook $LANGUAGE"
    PDFILE=MuseScore-${LANGUAGE}.pdf
    TIME=$(date +%s)
    #echo "https://musescore.org/${LANGUAGE}/print/book/export/html/${NID}?pdf&no-cache=${TIME}"
    $WKHTML --footer-center '[page]' --footer-spacing 2 --title "MuseScore 2.0 handbook" cover https://musescore.org/${LANGUAGE}/handbook-cover toc --xsl-style-sheet custom.xslt "https://musescore.org/${LANGUAGE}/print/book/export/html/${NID}?pdf=1&no-cache=${TIME}" $PDFILE > /dev/null 2>&1
    scp -C -i $SSH_INDENTITY $PDFILE musescore-nightlies@ftp-osl.osuosl.org:~/ftp/handbook/MuseScore-2.0/
    rm $PDFILE
    ((INDEX++))
done

# trigger distribution
ssh -i $SSH_INDENTITY musescore-nightlies@ftp-osl.osuosl.org "~/trigger-musescore-nightlies"
