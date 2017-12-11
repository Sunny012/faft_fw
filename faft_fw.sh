#!/bin/bash

declare -i index=0
declare -i argu_types_nums=0
declare -i total_argunums=0
declare -i DATE_YMD
declare -i DATE_HMS

#declare an array to receive all arguements
declare -a argu
declare -a nums_flag

#declare five arraies,each array represents a combination of the operation command
declare -a argu1
declare -a argu2
declare -a argu3
declare -a argu4
declare -a argu5

# declare default board and ip
BOARD=coral
DEFAULT_IP=192.168.1.123
############################################################
#                                                          #  
#    Sort the Input parameters                             #
#	                                                       #
#                                                          #
#														   #
############################################################

#get and sort out all of arguments
function sort_argu(){
	total_argunums=$#
	for arg in $@
	do
		if [ "$arg" == "-b" -o "$arg" == "-f" -o "$arg" == "-r" ];then	
			nums_flag[argu_types_nums]=$index;
			argu_types_nums+=1;
		fi
		argu[index]=$arg
		index+=1;
	done
}

#seprate arguments to array
function separ_argu(){
	declare -i argu_types=0;
	if [[ $argu_types < $argu_types_nums ]];then
		if [[ argu_types+1 -eq $argu_types_nums ]];then
			argu1=(${argu[*]})
			argu_types+=1
		else
			argu1=(${argu[*]:${nums_flag[0]}:${nums_flag[1]}-${nums_flag[0]}})	
			argu_types+=1
		fi
	fi
	
	if [[ $argu_types < $argu_types_nums ]];then
		if [[ argu_types+1 -eq $argu_types_nums ]];then
			argu2=(${argu[*]:${nums_flag[1]}:$total_argunums-${nums_flag[1]}})
			argu_types+=1
		else
			argu2=(${argu[*]:${nums_flag[1]}:${nums_flag[2]}-${nums_flag[1]}})	
			argu_types+=1
		fi
	fi
	
	if [[ $argu_types < $argu_types_nums ]];then
		if [[ argu_types+1 -eq $argu_types_nums ]];then
			argu3=(${argu[*]:${nums_flag[2]}:$total_argunums-${nums_flag[2]}})
			argu_types+=1
		else
			argu3=(${argu[*]:${nums_flag[2]}:${nums_flag[3]}-${nums_flag[2]}})	
			argu_types+=1
		fi
	fi
	
	if [[ $argu_types < $argu_types_nums ]];then
		if [[ argu_types+1 -eq $argu_types_nums ]];then
			argu4=(${argu[*]:${nums_flag[3]}:$total_argunums-${nums_flag[3]}})
			argu_types+=1
		else
			argu4=(${argu[*]:${nums_flag[3]}:${nums_flag[4]}-${nums_flag[3]}})	
			argu_types+=1
		fi
	fi
	
	if [[ $argu_types < $argu_types_nums ]];then
		if [[ argu_types+1 -eq $argu_types_nums ]];then
			argu5=(${argu[*]:${nums_flag[4]}:$total_argunums-${nums_flag[4]}})
			argu_types+=1
		else
			argu5=(${argu[*]:${nums_flag[4]}:${nums_flag[5]}-${nums_flag[4]}})	
			argu_types+=1
		fi
	fi
}



############################################################
#                                                          #  
#    check                                                 #
#	                                                       #
#                                                          #
#														   #
############################################################

# check whether in chroot environment or not
function check_in_chroot()
{
	filepath=~/trunk/src/scripts/
    	if [ ! -d "$filepath" ]; then
        echo -e "\033[41;37;5m Please enter the emvironment first! using 'cros_sdk --no-ns-pid' to do it! \033[0m";
    	exit 1;
  	fi
	return 0
}

# check servod is run
function check_is_servod_run()
{
	ps -fe |grep servod | grep -v grep
    if [ $? -ne 0 ]; then
		sudo pkill servod -x $BOARD
  		sudo servod -b $BOARD &
    	sleep 3
    fi
	echo -e "\033[44;37;5m servod is running ...\033[0m"
}

# check servod is run
function check_ip(){
	IP_Add=$1
	echo $IP_Add | grep -e "^[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}$" > /dev/null
	if [ $? -ne 0 ];then
		echo -e "\033[41;37;5m the dut_IP is incorrect! \033[0m";
		exit 1
	fi
	a=`echo $IP_Add|awk -F . '{print $1}'` 
    b=`echo $IP_Add|awk -F . '{print $2}'`
    c=`echo $IP_Add|awk -F . '{print $3}'`
    d=`echo $IP_Add|awk -F . '{print $4}'`
    for num in $a $b $c $d
    do 
   		if [ $num -gt 255 ];then 
      		echo -e "\033[41;37;5m the dut_IP is incorrect! \033[0m";
	   		exit 1
    	fi 
    done 
	return 0;
}


############################################################
#                                                          #  
#    build bios and ec file        						   #
#	 build environment which inclue autotest and hdctools  #
#	 mv bios and ec file to ~trunk/firmware/coral folder   #
#                                                          #
#														   #
############################################################

# clear the build directory and files
function clear_buildfile()
{
    if [ -d ~/trunk/chroot/build/coral/firmware ]; then
        cd ~/trunk/chroot/build/coral/firmware
        shopt -s extglob
        sudo rm -rf *
        #sudo rm -rf !(coreboot-private)
    fi
    return 0
}

# move bios&ec file
function mv_file_fun(){
    file_path=~/trunk/chroot/build/$BOARD/firmware
    if [ ! -d $file_path ];then
        echo -e "\033[41;37;5m bios or ec's path doesn't exist!!! \033[0m";
        exit 1;
    fi
# start copy bios&ec file
    cp $file_path/image-coral.bin ~/trunk/firmware/$BOARD
    mv_flag_bios=$?
    cp $file_path/robo360/ec.bin  ~/trunk/firmware/$BOARD
    mv_flag_ec=$?

    if [ $mv_flag_bios -ne 0 -o $mv_flag_ec -ne 0 ];then
        echo -e "\033[41;37;5m move failed,please retry!! \033[0m";
        exit 1;
    fi
    if [ ! -f ~/trunk/firmware/$BOARD/image-coral.bin ];then
        echo -e "\033[41;37;5m bios.bin doesn't exist \033[0m";
        exit 1;
    fi
    mv ~/trunk/firmware/$BOARD/image-coral.bin ~/trunk/firmware/$BOARD/bios.bin 
    if [ $? -ne 0  ];then
        echo -e "\033[41;37;5m bios and ec mv faily!!! \033[0m";s
        exit 1
    else
        echo -e "\033[44;37;5m bios and ec mv sucessfully!! \033[0m";
    fi
	return 0
}

# build local bios and ec code
function build_fw_fun()
{
# clear build_files in local
	clear_buildfile
# build mrc first
    emerge-$BOARD chromeos-mrc --getbinpkg --binpkg-respect-use=n

# build the need files
    emerge-$BOARD coreboot-private-files
    emerge-$BOARD coreboot-private-files-baseboard-coral
    emerge-$BOARD nhlt-blobs

# start that we need build
    cros_workon-$BOARD start chromeos-ec libpayload depthcharge coreboot 


# start building....
    emerge-$BOARD chromeos-firmware-ps8751 chromeos-firmware-anx3429 chromeos-ec chromeos-seabios libpayload depthcharge coreboot chromeos-bootimage
# stop all
    cros_workon-$BOARD --all stop 
    mv_file_fun
    return 0;
}

# build environment
function build_env_fun(){
# build hdctools
	cros_workon --host start hdctools
	sudo emerge hdctools
	if [ $? -ne 0 ];then
		echo "\033[41;37;5m build hdctools failed!! \033[0m"
		exit 1;
	fi 
	echo -e "\033[44;37;5m build hdctools successfully!! \033[0m"
	cros_workon --host stop hdctools

# build autotest
	cros_workon-$BOARD start autotest-chrome autotest-deps autotest-tests autotest
	emerge-$BOARD autotest-chrome autotest-deps autotest-tests autotest 
	cros_workon-$BOARD stop autotest-chrome autotest-deps autotest-tests autotest
	if [ $? -ne 0 ];then
		echo "\033[41;37;5m build autotest failed!! \033[0m"
		exit 1;
	fi 
	echo -e "\033[44;37;5m build autotest successfully!! \033[0m"
	return 0
}

# build packages
function build_packages_fun(){
	./build_packages --board=$BOARD
}

############################################################
#                                                          #  
#    flash bios,ec file and image                          # 
#	                                                       #
#                                                          #
#														   #
############################################################

#　flash bios to board
function flash_bios_fun(){
    filename=~/trunk/firmware/$BOARD/bios.bin
    if [ ! -f $filename  ];then
        echo -e "\033[41;37;5m The bios file of $BOARD doesn't exist \033[0m"
        exit 1
    fi
    dut-control spi2_buf_en:on spi2_buf_on_flex_en:on spi2_vref:pp3300 cold_reset:on
    echo -e "\033[44;37;5m start flash bios \033[0m"
    sudo flashrom -V -p ft2232_spi:type=servo-v2 -w $filename
    if [ $? -ne 0  ];then
        echo -e "\033[41;37;5m flash BIOS failed!!!\033[0m";
        exit 1
    fi
    dut-control spi2_buf_en:off spi2_buf_on_flex_en:off spi2_vref:off cold_reset:off
    if [ $? -ne 0 ];then
        echo -e "\033[41;37;5m  turn off all pins failed!!!\033[0m";
        exit 1
    fi
    echo -e "\033[44;37;5m flash BIOS and turn off all pins successfully!!!\033[0m";
	return 0
}

#　flash ec to board
function flash_ec_fun(){
    filename=~/trunk/firmware/$BOARD/ec.bin
    if [ ! -f "$filename" ];then
       echo -e "\033[41;37;5m The ec file doesn't exist \033[0m";
        exit 1;
    fi
    echo -e "\033[44;37;5m start flash ec \033[0m"
    ~/trunk/src/platform/ec/util/flash_ec --board=$BOARD --image=$filename

    if [ $? -ne 0  ];then
        echo -e "\033[41;37;5m flash ec failed!! \033[0m"
        exit 1
    fi
    echo -e "\033[44;37;5m flash ec sucessfully!! \033[0m"
	return 0
}

#　flash image to board
function flash_image_fun(){
	local -i timeout=0
	IP_Add=$1
	check_ip $IP_Add
	os_image_filepath=~/trunk/image/chromiumos_test_image.bin
	if [ ! -f $os_image_filepath ]; then
    	echo "the test image file is not exist!!"
   		exit 1
 	fi
	ping -c 2 $IP_Add
 	while [ $? -ne 0 ]
	do
   		ping -c 2 $IP_Add
		timeout+=1
   		if [ timeout -gt 50 ];then
			echo -e "\033[44;37;5m Connected failed!Please retry! \033[0m"
			exit 1;   			
   		fi
	done
    /usr/bin/test_that --board=coral $IP_Add --args="image=$os_image_filepath" platform_InstallTestImage
	if [ $? -ne 0 ];then
		echo -e "\033[41;37;5m flash OS_Image failed!! \033[0m"
		exit 1
	fi
	echo -e "\033[44;37;5m flash OS_Image successfully!! \033[0m"
	return 0
}

############################################################
#                                                          #  
#    RUN Faft                                              # 
#	                                                       #
#                                                          #
#														   #
############################################################

function print_space(){
	echo -e "\033[44;37;5m                      \033[0m"
	echo -e "\033[44;37;5m                      \033[0m"
	echo -e "\033[44;37;5m                      \033[0m"
	echo -e "\033[44;37;5m                      \033[0m"
	echo -e "\033[44;37;5m                      \033[0m"
	echo -e "\033[44;37;5m                      \033[0m"
}

function get_time_fun(){  #add two following functions
	DATE_YMD=`date +%y%m%d`
	DATE_HMS=`date +%H%M%S`
}

function creat_log_file(){
	Option=$1
	get_time_fun
	file_path=~/trunk/faft_fw
	if [ ! -d "$file_path/FAFT_LOG"  ];then
		sudo mkdir -m 777 $file_path/FAFT_LOG;
	fi
	if [ ! -d "$file_path/Log_$DATE_YMD"  ];then
		sudo mkdir -m 777 -p $file_path/FAFT_LOG/Log_$DATE_YMD
	fi
	case $Option in 
	"fw")
		if [ ! -d $file_path/FAFT_LOG/Log_$DATE_YMD/FWLog_$DATE_HMS ];then
			sudo mkdir -m 777 -p $file_path/FAFT_LOG/Log_$DATE_YMD/FWLog_$DATE_HMS
		fi 
	;;
	"ec")
		if [ ! -d $file_path/FAFT_LOG/Log_$DATE_YMD/ECLog_$DATE_HMS ];then
			sudo mkdir -m 777 -p $file_path/FAFT_LOG/Log_$DATE_YMD/ECLog_$DATE_HMS
		fi 
	;;
	"bios")
		if [ ! -d $file_path/FAFT_LOG/Log_$DATE_YMD/BIOSLog_$DATE_HMS ];then
			sudo mkdir -m 777 v $file_path/FAFT_LOG/Log_$DATE_YMD/BIOSLog_$DATE_HMS
		fi 
	;;
	"special")
		if [ ! -d $file_path/FAFT_LOG/Log_$DATE_YMD/Special_ItemsLog ];then
			sudo mkdir -m 777 -p $file_path/FAFT_LOG/Log_$DATE_YMD/Special_ItemsLog
		fi 
	;;
	*)
		echo -e "\033[41;37;Creat folder parameter input wrong!! \033[0m";
		exit 1;
	;;
	esac
}

function Check_SingleItem(){
	Special_SignleItem=$1;
	echo $Special_SignleItem | grep "^firmware_" > /dev/null 
	if [ $? -ne 0 ];then
		echo -e "\033[41;37;5m Signle Item Input wrong!! \033[0m";
		exit 1;
	fi
	return 0
}

function run_MulItems_fun(){
	IP_Add=$1
	check_ip $IP_Add
	creat_log_file special
	file_path=~/trunk/faft_fw/FAFT_LOG/Log_$DATE_YMD/Special_ItemsLog
	if [ ! -f $file_path/Special_Items.log ];then
		echo "#####　　　　Log File For Mul_Items FaFt-Test　　　　#####" >> $file_path/Special_Items.log
	fi
	
	# check items input file
	InputFile_path=~/trunk/faft_fw
	if [ ! -f $InputFile_path/Faft_Special_MulTests_Item.txt ];then
		echo -e "\033[41;37;5m Input Files doesn't exist,please check it!!! \033[0m";
		exit 1;
	fi  
	if [ ! -s $InputFile_path/Faft_Special_MulTests_Item.txt ];then
		echo -e "\033[41;37;5m Input File is empty,please input test-items!! \033[0m";
		exit 1;
	fi
	
	echo "******************************************" >> $file_path/Special_Items.log
	date >> $file_path/Special_Items.log
	while read test_item
	do 
	if [ "$test_item" != "" ];then
		/usr/bin/test_that --board=$BOARD $IP_Add $test_item
		if [ $? -ne 0 ];then
			print_space
			echo ""$test_item"  [FAILED]" >> $file_path/Special_Items.log
		else
			echo ""$test_item"  [SUCCESS]" >> $file_path/Special_Items.log
		fi
	fi			
	done < ~/trunk/faft_fw/Faft_Special_MulTests_Item.txt
	echo "******************************************" >> $file_path/Special_Items.log
	echo -e "\n" >>  $file_path/Special_Items.log
	return 0
}

function run_SingleItem_fun(){
	Test_Item=$1
	IP_Add=$2
	check_ip $IP_Add	
	creat_log_file special
	file_path=~/trunk/faft_fw/FAFT_LOG/Log_$DATE_YMD/Special_ItemsLog
	if [ ! -f $file_path/Special_Items.log ];then
		sudo echo "#####　　　　Log File For Special_Items FaFt-Test　　　　#####" >> $file_path/Special_Items.log
	fi
	echo "******************************************" >> $file_path/Special_Items.log
	date >> $file_path/Special_Items.log
#	/usr/bin/test_that --board=$BOARD $IP_Add $Test_Item
	if [ $? -ne 0 ];then
		print_space
		sudo echo ""$test_item"  [FAILED]" >> $file_path/Special_Items.log
	else
		echo ""$test_item"  [SUCCESS]" >> $file_path/Special_Items.log
	fi		
	echo "******************************************" >> $file_path/Special_Items.log
	echo -e "\n" >>  $file_path/Special_Items.log
	return 0
}

function run_ecfaft_fun(){
	IP_Add=$1
	check_ip $IP_Add
	creat_log_file ec
	file_path=~/trunk/faft_fw/FAFT_LOG/Log_$DATE_YMD/ECLog_$DATE_HMS
	/usr/bin/test_that --board=coral $IP_Add suite:faft_ec
	if [ $? -ne 0 ];then
		echo -e "\033[41;37;5m ec faft runs failed!! \033[0m";
		#Copy result log files to FAFT_LOG folder and deleted latest results
		cp -r ~/trunk/chroot/tmp/test_that_latest/* $file_path
		mv $file_path/test_report.log $file_path/ec.log
		sudo rm -r ~/trunk/chroot/tmp/test_*	
		exit 1
	fi	
	echo -e "\033[44;37;5m ec faft runs sucessfully!! \033[0m";
	#Copy result log files to FAFT_LOG folder and deleted latest results
	cp -r ~/trunk/chroot/tmp/test_that_latest/* $file_path
	mv $file_path/test_report.log $file_path/bios.log
	sudo rm -r ~/trunk/chroot/tmp/test_*	
	return 0
}

function run_biosfaft_fun(){
	IP_Add=$1
	check_ip $IP_Add
	creat_log_file bios
	file_path=~/trunk/faft_fw/FAFT_LOG/Log_$DATE_YMD/BIOSLog_$DATE_HMS
	/usr/bin/test_that --board=coral $IP_Add suite:faft_bios    
	if [ $? -ne 0 ];then
		echo -e "\033[41;37;5m bios faft runs failed!! \033[0m";
		#Copy result log files to FAFT_LOG folder and deleted latest results
		cp -r ~/trunk/chroot/tmp/test_that_latest/* $file_path
		mv $file_path/test_report.log $file_path/bios.log
		sudo rm -r ~/trunk/chroot/tmp/test_*	
		exit 1
	fi		
	echo -e "\033[44;37;5m bios faft runs sucessfully!! \033[0m";
	#Copy result log files to FAFT_LOG folder and deleted latest results
	cp -r ~/trunk/chroot/tmp/test_that_latest/* $file_path
	mv $file_path/test_report.log $file_path/bios.log
	sudo rm -r ~/trunk/chroot/tmp/test_*	
	return 0
}

function run_allfaft_fun(){
	IP_Add=$1
	check_ip $IP_Add
	creat_log_file fw
	file_path=~/trunk/faft_fw/FAFT_LOG/Log_$DATE_YMD/FWLog_$DATE_HMS

#run all ec faft-test part#
	if [ ! -d  $file_path/EC_Log ];then
		sudo mkdir -m 777 -p $file_path/EC_Log
	fi
	/usr/bin/test_that --board=coral $IP_Add suite:faft_ec
	if [ $? -ne 0 ];then
		echo -e "\033[41;37;5m ec faft runs failed!! \033[0m";
		#Copy result log files to FAFT_LOG folder and deleted latest results
		cp -r ~/trunk/chroot/tmp/test_that_latest/* $file_path/EC_Log
		mv $file_path/test_report.log $file_path/EC_Log/ec.log
		sudo rm -r ~/trunk/chroot/tmp/test_*	
		exit 1
	fi	
	echo -e "\033[44;37;5m ec faft runs sucessfully!! \033[0m";
	#Copy result log files to FAFT_LOG folder and deleted latest results
	cp -r ~/trunk/chroot/tmp/test_that_latest/* $file_path/EC_Log
	mv $file_path/EC_Log/test_report.log $file_path/EC_Log/ec.log
	sudo rm -r ~/trunk/chroot/tmp/test_*	
	echo "$file_path"
	
 #run all bios faft-test part#
	if [ ! -d  $file_path/BIOS_Log ];then
		echo "111111"
		sudo mkdir -m 777 -p $file_path/BIOS_Log
	fi
	/usr/bin/test_that --board=coral $IP_Add suite:faft_bios    
	if [ $? -ne 0 ];then
		echo -e "\033[41;37;5m bios faft runs failed!! \033[0m";
		#Copy result log files to FAFT_LOG folder and deleted latest results
		cp -r ~/trunk/chroot/tmp/test_that_latest/* $file_path/BIOS_Log
		mv $file_path/test_report.log $file_path/BIOS_Log/bios.log
		sudo rm -r ~/trunk/chroot/tmp/test_*	
		exit 1
	fi		
	echo -e "\033[44;37;5m bios faft runs sucessfully!! \033[0m";	
	#Copy result log files to FAFT_LOG folder and deleted latest results
	cp -r ~/trunk/chroot/tmp/test_that_latest/* $file_path/BIOS_Log
	mv $file_path/BIOS_Log/test_report.log $file_path/BIOS_Log/bios.log
	sudo rm -r ~/trunk/chroot/tmp/test_*	
	return 0 
}

############################################################
#                                                          #  
#    Help Information                                      # 
#	                                                       #
#                                                          #
#														   #
############################################################

function help_fun ()
{
	echo -e "   \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "   \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "   \033[44;37;5m |                        HELP INFORMATION                          | \033[0m";
	echo -e "   \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "   \033[44;37;5m |    ip_address is optional.if not written will use the default add| \033[0m"; 
	echo -e "   \033[44;37;5m |-ress;and please pay attention the order of comand!               | \033[0m";
	echo -e "   \033[44;37;5m +------------------------------------------------------------------+ \033[0m";		
	echo -e "   \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "   \033[44;37;5m | -BUILD FILE                                                      | \033[0m";
	echo -e "   \033[44;37;5m | 	-b fw                                                          | \033[0m";
	echo -e "   \033[44;37;5m | 	-b env                                                         | \033[0m";
	echo -e "   \033[44;37;5m | 	-b all　　　(fw+env)                                           | \033[0m";
	echo -e "   \033[44;37;5m | 	-b packages                                                    | \033[0m";
	echo -e "   \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "   \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "   \033[44;37;5m | -FLASH FILE                                                      | \033[0m";
	echo -e "   \033[44;37;5m | 	-f [ec]                                                        | \033[0m";
	echo -e "   \033[44;37;5m | 	-f [bios]                                                      | \033[0m";
	echo -e "   \033[44;37;5m | 	-f [fw] 　(ec+bios)                                            | \033[0m";
	echo -e "   \033[44;37;5m | 	-f [image] [ip_address]                                        | \033[0m";
	echo -e "   \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "   \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "   \033[44;37;5m | -RUN FAFT                                                        | \033[0m";
	echo -e "   \033[44;37;5m | 	-r [Signle_Item] [ip_address]                                  | \033[0m";
	echo -e "   \033[44;37;5m | 	-r [Mul_Item] [ip_address]                                     | \033[0m";
	echo -e "   \033[44;37;5m | 	-r [ec] [ip_address]                                           | \033[0m";
	echo -e "   \033[44;37;5m | 	-r [bios] [ip_address]                                         | \033[0m";
	echo -e "   \033[44;37;5m | 	-r [fw] [ip_address]　   (ec+bios)                             | \033[0m";
	echo -e "   \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "   \033[44;37;5m +------------------------------------------------------------------+ \033[0m";

}


function display_fun(){	
	temp=$*
	declare -a argu
	declare -i index=0
# check wheather is in chroot environment
	check_in_chroot
# Calculate the number of parameters
	for a in ${temp[*]}
	do
		argu[index]=$a
		index+=1
	done
# display function
	case ${argu[0]} in
	"-b")	
		case "${argu[1]}" in
		"fw")
			build_fw_fun
		;;
		"env")
			build_env_fun				
		;;
		"all")
			build_env_fun
			build_fw_fun
		;;
		"packages")
			~/trunk/src/scripts/build_packages --board=$BOARD
		;;
		"")
		;;
		*)
			echo "input is wrong ,please retry it"
			exit 1
		;;
		esac
	;;
	"-f")
		check_is_servod_run
		case "${argu[1]}" in
		"ec")
			flash_ec_fun
		;;
		"bios")
			flash_bios_fun 								
		;;
		"fw")
			flash_ec_fun
			flash_bios_fun
		;;
		"image")
			case "${argu[2]}" in
			"")
				flash_image_fun $DEFAULT_IP
			;;
			*)
				flash_image_fun ${argu[2]}
			;;
			esac
			;;
		"fw+image")
			case "${argu[2]}" in
			"")
				flash_ec_fun
				flash_bios_fun
				flash_image_fun $DEFAULT_IP
			;;
			*)
				flash_ec_fun
				flash_bios_fun
				flash_image_fun ${argu[2]}
			;;
			esac
		;;
		esac
		;;		
	"-r")		
		#check_is_servod_run
		case "${argu[1]}" in
		"ec")
			case "${argu[2]}" in
			"")
				run_ecfaft_fun $DEFAULT_IP
			;;
			*)
				run_ecfaft_fun ${argu[2]}
			;;
			esac
		;;
		"bios")
			case "${argu[2]}" in
			"")
				run_biosfaft_fun $DEFAULT_IP
			;;
			*)
				run_biosfaft_fun ${argu[2]}
			;;
			esac
		;;
		"fw")
			case "${argu[2]}" in
			"")
				run_allfaft_fun $DEFAULT_IP
			;;
			*)
				run_allfaft_fun ${argu[2]}
			;;
			esac
		;;
		"Mul_Items")
			case "${argu[2]}" in 
			"")
				run_MulItems_fun $DEFAULT_IP
			;;
			*)
				run_MulItems_fun ${argu[2]}				
			;;
			esac
		;;
		*)
			Check_SingleItem ${argu[1]}
			case "${argu[2]}" in
			"")		
				run_SingleItem_fun ${argu[1]} $DEFAULT_IP

			;;
			*)
				run_SingleItem_fun ${argu[1]} ${argu[2]}　
			;;
			esac
		;;
		"")
			return 0
		;;
		*)
			echo "input is wrong ,please retry it"
			exit 1
		;;
		esac
	;;
	"")
		return 0
	;;	
	esac
}

function main(){
	
# show help information
	if [ "$1" == "--help" -o "$1" == "" ];then
		help_fun $1
	fi
#sort and seprate all arguments
	sort_argu $*
	separ_argu
#executive function
	display_fun ${argu1[*]}
	display_fun ${argu2[*]}
	display_fun ${argu3[*]}
	display_fun ${argu4[*]}
	display_fun ${argu5[*]}
}

######  START HERE  ######
main $*



