#!/bin/bash

trap ctrl_c INT

function ctrl_c() {
        echo "** WARNING HIT CTRL^C MAKE LOSS YOUR pass.enc File **"
}


file="pass.txt"
filenc="pass.enc"
if [ ! -f "$filenc" ];then

echo "file pass.enc not found"
echo "please create password for db pass.enc"
echo "" | openssl aes-256-cbc -a -salt > pass.enc

fi

echo "please enter password for db pass.enc"
cat pass.enc | openssl aes-256-cbc -a -d > $file
if [ "$?" == "0" ];then

#echo -e "This text is ${RED}red${NONE} and ${GREEN}green${NONE} and ${BOLD}bold${NONE} and ${UNDERLINE}underlined${NONE}."


echo "-------------------------------";
echo "Password utilities with OpenSSL";
echo "-------------------------------";
echo "1. Add Entry.		     ";
echo "2. See Entry		     ";
echo "3. Delete Entry		     ";
echo "4. Quit			     ";
echo "-------------------------------";
echo -n "Choose Menu (1/2/3/4): "
read menu

NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'
BOLD='\033[1m'
UNDERLINE='\033[4m'

until [ "$menu" == "4" ];
do

file="pass.txt"
count=`wc -l $file | awk '{print $1}'`
num=`expr $count + 1`

	cat $file | awk -F \. '{print $1}' | grep $num > /dev/null

        until [ "$?" == "1" ];
        do
		num=`expr $num + 1`
		cat $file | awk -F \. '{print $1}' | grep $num > /dev/null
        done


if [ "$menu" == "1" ];
then
echo -n "Entry Name: "
read entry
echo -n "Username: "
read username
echo -n "Pass: "
read pass

echo -n "$num. $entry:" >> $file

echo "$username:$pass" | openssl aes-256-cbc -a -salt >> $file

cat $file | grep $num > /dev/null

	if [ "$?" == "0" ];then

	echo -e "${GREEN}New entry was added${NONE}";
	else

	echo -e "${RED}New entry can't added${NONE}";

	fi


fi

if [ "$menu" == "2" ];
then
cat $file | awk -F \: '{print $1}'
echo "-----------------";
echo -n "Choose entry number: ";
read numkey
	cat pass.txt | grep $numkey > /dev/null
	if [ "$?" == "0" ];then
	numkey=`grep -w "${numkey}\." pass.txt -n | cut -d \: -f 1`
	tail -n+$numkey $file | head -n1 | cut -d \: -f 2 | openssl aes-256-cbc -a -d

		if [ "$?" == "1" ];then
		echo "Wrong Password";
		fi

	else

	echo -e "${RED}Entry number that you select does not exist${NONE}"

	fi
fi

if [ "$menu" == "3" ];
then
cat $file | awk -F \: '{print $1}'
echo "-----------------";
echo -n "Choose entry number: ";
read numkey

	cat pass.txt | grep $numkey > /dev/null
        if [ "$?" == "0" ];then

	
	numkey=`grep -w "${numkey}\." pass.txt -n | cut -d \: -f 1`
	tail -n+$numkey $file | head -n1 | cut -d \: -f 2 | openssl aes-256-cbc -a -d
	
		if [ "$?" == "0" ];then
		sed "${numkey}d" $file > .tmpass.txt && mv -f .tmpass.txt $file
		echo -e "${GREEN}Deleted.${NONE}";
		else
		echo -e "${RED}Wrong Password ${NONE}";
		fi

	else
	echo -e "${RED}Entry number that you select does not exist${NONE}"

	fi

fi



file="pass.txt"

echo "-------------------------------";
echo "Password utilities with OpenSSL";
echo "-------------------------------";
echo "1. Add Entry.               ";
echo "2. See Entry                 ";
echo "3. Delete Entry                 ";
echo "4. Quit                        ";
echo "-------------------------------";
echo -n "Choose Menu (1/2/3/4): "
read menu

NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'
BOLD='\033[1m'
UNDERLINE='\033[4m'

done

echo "Enter password for db pass.enc file";
cat pass.txt | openssl aes-256-cbc -a -salt > pass.enc


        until [ "$?" == "0" ];
        do
		echo "Enter password for db pass.enc file";
		cat pass.txt | openssl aes-256-cbc -a -salt > pass.enc
        done

rm -rf pass.txt
echo "---best of password storage is the brain of your head given by God Almighty--"
else

echo "Wrong password for db pass.enc file";
rm -rf pass.txt;

fi
