# !/bin/bash

#read mac 
##############
read -p "Please input a MAC[0x00 0xFD 0x45 0xFF 0x15 0xB0]:" MAC_STD
echo "$MAC_STD">MAC_STD.txt
echo "$MAC_STD" |awk  '{print ($1$2$3$4$5$6)}' >>MAC_STD.txt
mac0=`echo "$MAC_STD" |awk '{print ($1$2$3$4$5$6)}'|awk -F"0x" '{print ($2$3$4$5$6$7)}' |awk '{print toupper($0)}'` 
echo "$mac0">>MAC_STD.txt
echo -e "\033[33mMAC_STD:\033[0m"
echo $MAC_STD

#mac hex_add_1
##################
hex_add_1(){
local mac_curr=$1
local mac_curr_rev=`echo $mac_curr | rev`
local flag=1
local result=""

for i in {0..11}
do
	i=${mac_curr_rev:$i:1}
	if [ $flag -eq 1 ]
	then 
		case $i in  
		#why show red. [0-8]) let i++ so,mv it to *)
		[0-8])	let i++	;;
		9)	i=A	;;
		a|A)	i=B	;;
		b|B)	i=C	;;
		c|C)	i=D	;;
		d|D)	i=E	;;
		e|E)	i=F	;;
		f|F)	i=0;flag=1;;
		esac
		[[ $i !=  0 ]]&&flag=0
	fi
	result=$i$result
done
echo $result

}

#get mac0.1.2.3.4.5
#############
for i in {0..4}
do
	mac[0]=$mac0
	temp=${mac[$i]}
	let j=$i+1
	mac[$j]=`eval "hex_add_1 $temp"`
done
echo
echo -e "\033[33m6 mac: \033[0m"
echo ${mac[*]}
echo "${mac[0]} ${mac[1]}"

#convert bmc_eep stand input
############################
echo
echo -e "\033[33mbmc_eep stand input: \033[0m"
MAC[0]=`echo "0x${mac[0]:0:2} 0x${mac[0]:2:2} 0x${mac[0]:4:2} 0x${mac[0]:6:2} 0x${mac[0]:8:2} 0x${mac[0]:10:2}"`
echo "${MAC[0]}"

MAC[1]=`echo "0x${mac[1]:0:2} 0x${mac[1]:2:2} 0x${mac[1]:4:2} 0x${mac[1]:6:2} 0x${mac[1]:8:2} 0x${mac[1]:10:2}"`
echo "${MAC[1]}"


./fake_bmc_eep.sh
#flash mac
########
./bmc_eep -f romac0 = ${mac[0]} -w
./bmc_eep -f romac0 = ${mac[1]} -w

#reboot
###############
./bmc_eep -BMCBOOT
sleep 30
[ $? -eq 1 ]&&echo "reboot Error"&&exit

#grep&compare
#############
./bmc_eep -d |awk '/primary MAC/{print ($2$3$4$5$6$7)}'>a.txt

MAC_BMC[0]=`echo a.txt`
MAC_BMC[0]=echo ${MAC_BMC[0]}|awk '{print toupper($0)}'
[[ MAC_BMC[0] == mac[0] ]]&& echo -e "MAC0 flash \033[32m pass \033[0m!"

./bmc_eep -d |awk '/second MAC/{print ($2$3$4$5$6$7)}'>a.txt
MAC_BMC[1]=`echo a.txt`
MAC_BMC[1]=echo ${MAC_BMC[1]}|awk '{print toupper($0)}'
[[ MAC_BMC[1] == mac[1] ]]&& echo -e "MAC1 flash \033[32m pass \033[0m!"


