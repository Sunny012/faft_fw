# faft_fw
The first script from wwz which can help some users to resolve the problem of  building,flash and running faft-test !

/********************************************************
@ brief:   Help users to flash fw&image, build code&environment and run FAFT test! 
@ version: V1.1
@ auther:  wwz
@ Time  :  2017/12/1
********************************************************/
Fixed problems:
1.fixed a problem that failed to store log when failed to run FAFT test

Modified files:
1.faft_fw.sh


/********************************************************
@ brief:   Help users to flash fw&image, build code&environment and run FAFT test! 
@ version: V1.0
@ auther:  wwz
@ Time  :  2017/11/1
********************************************************/

[Descriptions]
The Script documenttation is for:
	build BIOS and EC code
	burning EC and BIOS files
	running FAFT test items

You can use the help command to see how to use it!
You must edit the <config.txt> file to ensure the configuration information is correct!

if you change the board or IP,you need to modify the contents of the configuration document!	
	[BOARD]---Currently used board!
	[IP]------The IP address of the machine which is flashing image and running FAFT!


	
		 



