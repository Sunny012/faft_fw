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
BOARD=octopus
DEFAULT_IP=192.168.1.121

############################################################
#                                                          #  
#    Sort the Input parameters                             #
#	                                                       #
#                                                          #
#														   #
############################################################

#get and sort out all of arguments
function sort_argu(){

	if [ "$1" != "-b" -a "$1" != "-f" -a "$1" != "-r" -a "$1" != "-m" ];then
		echo -e "\033[41;37;5m Input Wrong! Please check it!!\033[0m";
		exit 1
	fi
	total_argunums=$#
	for arg in $@
	do
		if [ "$arg" == "-b" -o "$arg" == "-f" -o "$arg" == "-r" -o "$arg" == "-m" ];then	
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
        case $BOARD in
            "coral")
		        sudo pkill servod -x $BOARD
          		sudo servod -b $BOARD &
            ;;
            "octopus")
                #sudo pkill servod -x $BOARD
                sudo servod -b "$BOARD_npcx" &
            ;;
        esac
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
      		echo -e "\033[44;37;5m the dut_IP is incorrect! \033[0m";
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
    if [ -d ~/trunk/chroot/build/$BOARD/firmware ]; then
        cd ~/trunk/chroot/build/$BOARD/firmware
        shopt -s extglob
        sudo rm -rf *
    	echo -e "\033[44;37;5m the old file has been deleted! \033[0m";
    fi
    return 0
}

# move bios&ec file
function mv_bios(){
    file_path=~/trunk/chroot/build/$BOARD/firmware
    if [ ! -d $file_path ];then
        echo -e "\033[41;37;5m bios path doesn't exist!!! \033[0m";
        exit 1;
    fi
    if [ ! -d ~/trunk/firmware/$BOARD ];then
    	mkdir -p ~/trunk/firmware/$BOARD
    fi    
    case $BOARD in 
        "octopus")
            file_name=image-phaser.serial.bin
            cp $file_path/$file_name ~/trunk/firmware/$BOARD
        ;;
        "*")
            file_name=image-$BOARD.serial.bin
            cp $file_path/$file_name ~/trunk/firmware/$BOARD
        ;;
    esac
    if [ $? -ne 0 ];then
        echo -e "\033[41;37;5m move bios failed,please retry!! \033[0m";
        exit 1;
    fi
    mv ~/trunk/firmware/$BOARD/$file_name ~/trunk/firmware/$BOARD/bios.bin
    if [ $? -ne 0  ];then
        echo -e "\033[41;37;5m bios mv faily!!! \033[0m";
        exit 1
    else
        echo -e "\033[44;37;5m bios mv sucessfully!! \033[0m";
    fi
    return 0;
}

function mv_ec(){
    file_path=~/trunk/chroot/build/$BOARD/firmware
    if [ ! -d $file_path ];then
        echo -e "\033[41;37;5m ec's path doesn't exist!!! \033[0m";
        exit 1;
    fi
# start copy ec file
    cp $file_path/robo360/ec.bin  ~/trunk/firmware/$BOARD
    mv_flag_ec=$?
    if [ $mv_flag_ec -ne 0 ];then
        echo -e "\033[41;37;5m move ec failed,please retry!! \033[0m";
        exit 1;
    fi
    if [ ! -f ~/trunk/firmware/$BOARD/ec.bin ];then
        echo -e "\033[41;37;5m ec.bin doesn't exist \033[0m";
        exit 1;
    fi
    return 0;
}
function mv_file_fun(){
    mv_bios
    mv_ec
}

# build mrc function
function build_mrc()
{
    case $BOARD in
        "coral")
        # clear build files in local    
            clear_buildfile
        # build mrc
            emerge-$BOARD chromeos-mrc --getbinpkg --binpkg-respect-use=n
        ;;
        "*")
            echo -e "\033[41;37;5m The Boaid id input isn't supporting by this script!! \033[0m";
        ;;
    esac
}

# build local bios and ec code
function build_bios(){
# clear build_files in locala
    #clear_buildfile
    case $BOARD in
        "coral")
        # build mrc first
            emerge-$BOARD chromeos-mrc --getbinpkg --binpkg-respect-use=n
        # workon board
            cros_workon-$BOARD start libpayload depthcharge coreboot 
        # start building....
            emerge-$BOARD chromeos-ec chromeos-seabios libpayload depthcharge coreboot chromeos-bootimage
        # stop all
            cros_workon-$BOARD --all stop 
        ;;
        "octopus")
        # workon board
            cros_workon-$BOARD start coreboot 
        # start building....
            emerge-$BOARD coreboot chromeos-bootimage
        # stop all
            cros_workon-$BOARD --all stop 
        ;;
        "*")
            echo -e "\033[41;37;5m The Boaid id input isn't supporting by this script!! \033[0m";
        ;;
    esac 
}

function build_ec(){
# clear_buildfile in local
    #clear_buildfile
# start to build ec
    cros_workon-$BOARD start chromeos-ec
    emerge-$BOARD chromeos-ec
    cros_workon-$BOARD stop chromeos-ec
}

function build_fw_fun()
{
# clear build_files in local
    case $BOARD in
        "coral")
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
        ;;
        "octopus") 
        # workon board
            cros_workon-$BOARD start coreboot 
        # start building....
            emerge-$BOARD chromeos-ec coreboot chromeos-bootimage
        # stop all
            cros_workon-$BOARD --all stop 
        ;;
        "*")
            echo -e "\033[41;37;5m The Boaid id input isn't supporting by this script!! \033[0m";
        ;;
    esac
    return 0;
}

# build environment
function build_hdctool(){
# build hdctools
    cros_workon --host start hdctools
    sudo emerge hdctools
    if [ $? -ne 0 ];then
       echo "\033[41;37;5m build hdctools failed!! \033[0m"
    exit 1;
    fi 
    echo -e "\033[44;37;5m build hdctools successfully!! \033[0m"
    cros_workon --host stop hdctools
    return 0;
}

function build_autotest(){
# build autotest
    cros_workon-$BOARD start autotest-chrome autotest-deps autotest-tests autotest
    emerge-$BOARD autotest-chrome autotest-deps autotest-tests autotest
    if [ $? -ne 0 ];then
        echo "\033[41;37;5m build autotest failed!! \033[0m"
        exit 1;
    fi
    echo -e "\033[44;37;5m build autotest successfully!! \033[0m"
    cros_workon-$BOARD stop autotest-chrome autotest-deps autotest-tests autotest
    return 0
}
function build_env_fun(){
    build_hdctool;
    build_autotest;
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
    case $BOARD in
        "corad")
            dut-control spi2_buf_en:on spi2_buf_on_flex_en:on spi2_vref:pp3300 cold_reset:on
            sudo flashrom -V -p ft2232_spi:type=servo-v2 -w $filename
            flash_result=$?
            dut-control spi2_buf_en:off spi2_buf_on_flex_en:off spi2_vref:off cold_reset:off
            ;;
        "octopus")
            dut-control spi2_buf_en:on spi2_buf_on_flex_en:on spi2_vref:pp1800 cold_reset:on   
	    echo $filename       
            sudo flashrom -V -p ft2232_spi:type=servo-v2 -w $filename
            flash_result=$?
            dut-control spi2_buf_en:on spi2_buf_on_flex_en:on spi2_vref:pp1800 cold_reset:off
        ;;
        "*")
            echo -e "\033[41;37;5m The Boaid id input isn't supporting by this script!! \033[0m";
            exit 1

        ;;
    esac
    if [ $flash_result -ne 0  ];then
        echo -e "\033[41;37;5m flash BIOS failed!!!\033[0m";
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
    case $BOARD in
        "coral")
            ~/trunk/src/platform/ec/util/flash_ec --board=$BOARD --image=$filename
        ;;
        "octopus")
            ~/trunk/src/platform/ec/util/flash_ec --board=phaser --image=$filename
        ;;
        "*")
            echo -e "\033[41;37;5m The Boaid id input isn't supporting by this script!! \033[0m";
            exit 1
        ;;
    esac
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
    	echo -e "\033[41;37;5m the test image file is not exist!! \033[0m"
   		exit 1
 	fi
	ping -c 2 $IP_Add
	ping_result=$?
 	while [ $ping_result -ne 0 ]
	do
   		ping -c 2 $IP_Add
   		ping_result=$?
		timeout=$[timeout+1]
   		if [ $timeout -gt 50 ];then
			echo -e "\033[41;37;5m Connected failed!Please retry! \033[0m"
			exit 1;   			
   		fi
	done
    case $BOARD in
        "coral")
            /usr/bin/test_that --board=coral $IP_Add --args="image=$os_image_filepath" platform_InstallTestImage
        ;;
        "*")
            echo -e "\033[41;37;5m The BOARD_ID is wrong! pls checnk it!! \033[0m"
            exit 1
        ;;
    esac
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
	DATE_HMS=`date +%-H%M%S`
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
		echo -e "\033[41;37;5m Signle Item Input wrong,please check it!! \033[0m";
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
		echo -e "\033[41;37;5m [Faft_Special_MulTests_Item.txt] doesn't exist,please creat it!!! \033[0m";
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
	/usr/bin/test_that --board=$BOARD $IP_Add $Test_Item
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
	mv $file_path/test_report.log $file_path/ec.log
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
	echo -e "   \033[44;37;5m | -HELP                                                            | \033[0m";
	echo -e "   \033[44;37;5m | 	--help                                                         | \033[0m";
	echo -e "   \033[44;37;5m | 	--EC_FaftItems                                                 | \033[0m";
	echo -e "   \033[44;37;5m | 	--BIOS_FaftItems                                               | \033[0m";	
	echo -e "   \033[44;37;5m +------------------------------------------------------------------+ \033[0m";		
	echo -e "   \033[44;37;5m | -MOV                                                               | \033[0m";
	echo -e "   \033[44;37;5m | 	-m bios                                                         | \033[0m";
	echo -e "   \033[44;37;5m | 	-m ec                                                        | \033[0m";
	echo -e "   \033[44;37;5m | 	-m fw                                                       | \033[0m";
	echo -e "   \033[44;37;5m +------------------------------------------------------------------+ \033[0m";		
	echo -e "   \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "   \033[44;37;5m | -BUILD FILE                                                      | \033[0m";
	echo -e "   \033[44;37;5m |     -b mrc                                                       | \033[0m";
	echo -e "   \033[44;37;5m | 	-b bios                                                        | \033[0m";
	echo -e "   \033[44;37;5m | 	-b ec                                                        | \033[0m";
    echo -e "   \033[44;37;5m | 	-b fw(bios+ec)                                                       | \033[0m";
    echo -e "   \033[44;37;5m | 	-b hdctool                                                        | \033[0m";
	echo -e "   \033[44;37;5m | 	-b autotest                                                       | \033[0m";
    echo -e "   \033[44;37;5m | 	-b env (hdctool+autotest                                           | \033[0m";
	echo -e "   \033[44;37;5m | 	-b packages                                                    | \033[0m";
	echo -e "   \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "   \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "   \033[44;37;5m | -FLASH FILE                                                      | \033[0m";
	echo -e "   \033[44;37;5m | 	-f ec                                                          | \033[0m";
	echo -e "   \033[44;37;5m | 	-f bios                                                        | \033[0m";
	echo -e "   \033[44;37;5m | 	-f fw 　(ec+bios)                                              | \033[0m";
	echo -e "   \033[44;37;5m | 	-f image [ip_address]                                          | \033[0m";
	echo -e "   \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "   \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "   \033[44;37;5m | -RUN FAFT                                                        | \033[0m";
	echo -e "   \033[44;37;5m | 	-r firmware_…… [ip_address]                                    | \033[0m";
	echo -e "   \033[44;37;5m | 	-r Mul_Items [ip_address]                                      | \033[0m";
	echo -e "   \033[44;37;5m | 	-r ec [ip_address]                                             | \033[0m";
	echo -e "   \033[44;37;5m | 	-r bios [ip_address]                                           | \033[0m";
	echo -e "   \033[44;37;5m | 	-r fw　[ip_address]　    (ec+bios)                             | \033[0m";
	echo -e "   \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "   \033[44;37;5m +------------------------------------------------------------------+ \033[0m";
}

function Help_EC_FaftItems(){
	echo -e "   \033[0;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "   \033[0;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "   \033[0;37;5m +                     EC Single Itmes List                         + \033[0m";
	echo -e "   \033[0;37;5m +------------------------------------------------------------------+ \033[0m";
	while read ec_item
	do 
		if [ "$ec_item" != "" ];then
			echo -e "   \033[0;37;5m | 	$ec_item                                                     \033[0m";		
		fi	
	done < ~/trunk/faft_fw/FW_FaftItmes/ec_single_list.txt
	echo -e "   \033[0;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "   \033[0;37;5m +------------------------------------------------------------------+ \033[0m";
}

function Help_BIOS_FaftItems(){
	echo -e "   \033[0;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "   \033[0;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "   \033[0;37;5m +                     BIOS Single Itmes List                         + \033[0m";
	echo -e "   \033[0;37;5m +------------------------------------------------------------------+ \033[0m";
	while read ec_item
	do 
		if [ "$ec_item" != "" ];then
			echo -e "   \033[0;37;5m | 	$ec_item                                                     \033[0m";		
		fi	
	done < ~/trunk/faft_fw/FW_FaftItmes/bios_single_list.txt
	echo -e "   \033[0;37;5m +------------------------------------------------------------------+ \033[0m";
	echo -e "   \033[0;37;5m +------------------------------------------------------------------+ \033[0m";
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
        "mrc")
            build_mrc
        ;;    
        "bios")
            build_bios
        ;;
        "ec")
            build_ec
        ;;
		"fw")
			build_fw_fun
		;;
        "hdctool")
            build_hdctool
        ;;
        "autotest")
            build_autotest
        ;;
		"env")
			build_env_fun
		;;
		"packages")
			~/trunk/src/scripts/build_packages --board=$BOARD
		;;
		"")
			echo -e "\033[41;37;5m Please input option paramenter \033[0m";
			exit 1;
		;;
		*)
			echo -e "\033[41;37;5m Input wrong,please check it! \033[0m";
			exit 1
		;;
		esac
        ;;
    "-m")
		check_is_servod_run
		case "${argu[1]}" in
        "bios")
            mv_bios
        ;;
        "ec")
            mv_ec
        ;;
        "*")
			echo -e "\033[41;37;5m Input wrong,please check it! \033[0m";
            exit 1;
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
		"")
			echo -e "\033[41;37;5m Please input option paramenter \033[0m";
			exit 1;
		;;
		*)
			echo -e "\033[41;37;5m Input wrong,please check it! \033[0m";
			exit 1
		;;
		esac
		;;		
	"-r")		
		check_is_servod_run
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

		"")
			echo -e "\033[41;37;5m Please input option paramenter \033[0m";
			exit 1;
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
		esac
	;;
    esac
}

function main(){
	
# show help information
	if [ "$1" == "--help" -o "$1" == "" ];then
		help_fun
		return 0 
	fi
	if [ "$1" == "--EC_FaftItems" ];then
		Help_EC_FaftItems
		return 0
	fi
	if [ "$1" == "--BIOS_FaftItems" ];then
		Help_BIOS_FaftItems
		return 0
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



