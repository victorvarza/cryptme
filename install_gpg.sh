#!/usr/bin/env bash

#set -e

CD=$(pwd)
DOWNLOAD_FOLDER="${HOME}/Downloads/gpg-install"
APP_FOLDER="/tmp/dumps/gnupg2"

export CPPFLAGS="-I${APP_FOLDER}/include"
export LDFLAGS="-L${APP_FOLDER}/lib/"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${APP_FOLDER}/lib"
export LIBRARY_PATH="${LIBRARY_PATH}:${APP_FOLDER}/lib"
export CPATH="${CPATH}:${APP_FOLDER}/include"
export PATH="${PATH}:${APP_FOLDER}/bin"



GNUPG="2.1.21"
LIBGPG_ERROR="1.27"
LIBGCRYPT="1.7.8"
LIBKSBA="1.3.5"
LIBASSUAN="2.4.3"
NTBTLS="0.1.1"
NPTH="1.5"
NCURSES="6.0"
PINENTRY="1.0.0"
GPGME="1.9.0"


[[ ! -d $DOWNLOAD_FOLDER ]] && mkdir $DOWNLOAD_FOLDER
[[ ! -d $APP_FOLDER ]] && sudo mkdir $APP_FOLDER

sudo chown $USER:$USER $APP_FOLDER -R
cd $DOWNLOAD_FOLDER

wget -c https://www.gnupg.org/ftp/gcrypt/gnupg/gnupg-${GNUPG}.tar.bz2
wget -c https://www.gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-${LIBGPG_ERROR}.tar.bz2
wget -c https://www.gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-${LIBGCRYPT}.tar.bz2
wget -c https://www.gnupg.org/ftp/gcrypt/libassuan/libassuan-${LIBASSUAN}.tar.bz2
wget -c https://www.gnupg.org/ftp/gcrypt/libksba/libksba-${LIBKSBA}.tar.bz2
wget -c https://www.gnupg.org/ftp/gcrypt/npth/npth-${NPTH}.tar.bz2
wget -c https://www.gnupg.org/ftp/gcrypt/ntbtls/ntbtls-${NTBTLS}.tar.bz2
wget -c ftp://ftp.gnu.org/gnu/ncurses/ncurses-${NCURSES}.tar.gz
wget -c https://www.gnupg.org/ftp/gcrypt/pinentry/pinentry-${PINENTRY}.tar.bz2
wget -c https://www.gnupg.org/ftp/gcrypt/gpgme/gpgme-${GPGME}.tar.bz2


tar -xjf gnupg-${GNUPG}.tar.bz2
tar -xjf libgpg-error-${LIBGPG_ERROR}.tar.bz2
tar -xjf libgcrypt-${LIBGCRYPT}.tar.bz2
tar -xjf libassuan-${LIBASSUAN}.tar.bz2
tar -xjf libksba-${LIBKSBA}.tar.bz2
tar -xjf npth-${NPTH}.tar.bz2
tar -xjf ntbtls-${NTBTLS}.tar.bz2
tar -zxf ncurses-${NCURSES}.tar.gz
tar -xjf pinentry-${PINENTRY}.tar.bz2
tar -xjf gpgme-${GPGME}.tar.bz2


cd libgpg-error-${LIBGPG_ERROR}
./configure --prefix=$APP_FOLDER
make
make install
cd ../

cd libgcrypt-${LIBGCRYPT}
./configure --prefix=$APP_FOLDER
make
make install
cd ../

cd libassuan-${LIBASSUAN}
./configure --prefix=$APP_FOLDER
make
make install
cd ../

cd libksba-${LIBKSBA}
./configure --prefix=$APP_FOLDER
make
make install
cd ../

cd npth-${NPTH}
./configure --prefix=$APP_FOLDER
make
make install
cd ../

cd ntbtls-${NTBTLS}
./configure --prefix=$APP_FOLDER
make
make install
cd ../

cd ncurses-${NCURSES}
./configure --prefix=$APP_FOLDER
make
make install
cd ../

cd pinentry-${PINENTRY}
./configure --prefix=$APP_FOLDER --enable-pinentry-curses --disable-pinentry-qt4
make
make install
cd ../

cd gpgme-${GPGME}
./configure --prefix=$APP_FOLDER
make
make install
cd ../

cd gnupg-${GNUPG}
./configure --prefix=$APP_FOLDER
make
make install
cd ../

echo "$APP_FOLDER/lib" > /etc/ld.so.conf.d/gpg2.conf
ldconfig -v

cd $CD

# Without the line below, gpg2 might fail to create / import secret keys !!!
if [ -d ~/.gnugp ]
then
	rm -ri ~/.gnugp
fi
gpgconf --kill gpg-agent

echo "Complete !!!"