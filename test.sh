#! /bin/bash 
### desciption: this script is used to schedule the gpgpu-sim and report cycle of the programs
### author: shawe date: 2012.10.18

declare -i sys_sm_num=20  #assume there are 20 in total
declare -i sys_sm_num_occ=0 #the sms which are already occupied
declare -i tot_prog_num
declare -i prog_num
declare -i total_cycle=0
declare -i flag=1 
declare -i nextcycle=0
declare -i max_sim_cycle=0
declare -a prog_path
declare -a prog_come_cycle
declare -a prog_sm_min
declare -a prog_sm_opti 
declare -a prog_sm_cur  #current sm number of each program 
declare -a prog_finish_cycle
declare -a inst_count #if inst_count[i] < 0 then the program has already finished
declare -a prog_isrunning
declare -a weight


#declare function
function remap(){      #remap the sm distribution when an application comes or terminates
	#for test
	file="out.txt"
    #$2".txt"
	if [ $1 != "init" ];then
	eval $(awk 'BEGIN{getline;print "total_cycle=$total_cycle+"$1}\
	{num=$1;inst_count=$2;if( inst_count == "-1" ) {print "prog_num=$prog_num-1"};\
	 print "inst_count["num"]="inst_count}' $file) #read from out.txt to update the status	

 	#total_cycle needs to plus overhead from l2 cache
	#use for to calculate the finish_cycle of each inst=-1 program

#	else
#		echo "initiating the gpgpu_sim"
	fi
	
	reschedule

	if [ "$prog_num" != "0" ];then
		flag=1
	else
		flag=0
	fi
}

function echo_status(){
	cat in.txt
}

function report_cycle(){
	#echo "report cycle"
	eval $(awk 'BEGIN{getline;print "total_cycle=$total_cycle+"$1}\
	{num=$1;inst_count=$2;if( inst_count == "-1" ) {print "prog_num=$prog_num-1"};\
	 print "inst_count["num"]="inst_count}' $file) #read from out.txt to update the status	

    for ((i=0;i<tot_prog_num;i=i+1)) 
	do
			echo "$i ${prog_path[i]} ${prog_sm_cur[i]} ${inst_count[i]}" 
	done
}

function update_weight(){
	local num=$1
	let tmp=${prog_sm_opti[$num]}-${prog_sm_cur[$num]} 
	let weight[$num]=`echo "$tmp*100 / ${prog_sm_opti[$num]}" | bc`
#	echo "PROG:"$num"'s weight is "${weight[$num]} 
}

function chose_minweight(){
	tmp=100
	for i in ${!weight[@]}
	do
		if [ ${weight[$i]} -lt $tmp -a ${prog_sm_cur[$i]} -gt ${prog_sm_min[$i]} ];then
			tmp=${weight[$i]}
			result=$i
		fi	
	done
	echo $result
}

function reschedule(){
	#write back the scheduler info into in.txt
	#nextcycle
	for i in ${!prog_come_cycle[@]}
	do
		if [ ${inst_count[$i]} -ge 0 -a ${prog_come_cycle[$i]} -le $total_cycle ]; then
			prog_isrunning[$i]=1
		elif [ ${inst_count[$i]} = -1 ];then
			prog_isrunning[$i]=-1
		else
			prog_isrunning[$i]=0
		fi

		if [ $nextcycle -lt ${prog_come_cycle[$i]} ];then
			nextcycle=${prog_come_cycle[$i]}
		break
		fi
	done

	if [ $nextcycle -gt $total_cycle ];then
        #Added by jkm
        let nextsimcycle=$nextcycle-$total_cycle

		echo "$nextsimcycle" > in.txt
	else 
        let nextcycle=$max_sim_cycle
        let nextsimcycle=$nextcycle-$total_cycle
		echo "$nextsimcycle" > in.txt #if -1 then all the applications have done their job
	fi
	
	#echo "next cycle is "$nextcycle
	#remap the sm cores
	declare -i sm_aval
    declare -i n_running_prog=0
	for i in ${!prog_isrunning[@]}
	do
		if [ ${prog_isrunning[$i]} = 1 ]; then
			#echo "program "$i" is now in running status" 
            let n_running_prog=$n_running_prog+1
			let sm_aval=$sys_sm_num-$sys_sm_num_occ  #sm available
			if [ ${prog_sm_cur[$i]} != 0 ];then
				while [ $sm_aval != 0 -a ${prog_sm_cur[$i]} -lt ${prog_sm_opti[$i]} ]
				do
					#chose maxweight weight[k]
					#prog_sm_cur[k]-1
					let prog_sm_cur[$i]=${prog_sm_cur[$i]}+1
					#updateweight k
					update_weight $i
					sm_aval=$sm_aval-1
					sys_sm_num_occ=$sys_sm_num_occ+1
				done

			else  #the app has not been allocated yet
				if [ ${prog_sm_opti[$i]} -lt  $sm_aval ];then
					sys_sm_num_occ=${prog_sm_opti[$i]}+$sys_sm_num_occ
					prog_sm_cur[i]=${prog_sm_opti[$i]}
					update_weight $i
				else  #the available sm is not enough for optimum // regardless of user priority
					if [ ${prog_sm_min[$i]} -lt $sm_aval ];then #enough for min
						sys_sm_num_occ=${prog_sm_min[$i]}+$sys_sm_num_occ
						prog_sm_cur[$i]=${prog_sm_min[$i]}
						update_weight $i
					else # not enough for min // should remap by weight
						prog_sm_cur[$i]=$sm_aval
						sm_aval=0
						sys_sm_num_occ=$sys_sm_num
						while [ ${prog_sm_cur[$i]} -lt ${prog_sm_min[$i]} ]
						do
							k=`chose_minweight`
							#echo "chosed $k"	
						let	prog_sm_cur[$k]=${prog_sm_cur[$k]}-1
						let	prog_sm_cur[$i]=${prog_sm_cur[$i]}+1
							update_weight $k
						done
						update_weight $i
					fi 
				fi	
			fi			
		elif [ ${prog_isrunning[$i]} = -1 ];then
			#echo "program "$i" has finished "
			let sys_sm_num_occ-=${prog_sm_cur[$i]}
			prog_sm_cur[$i]=0
		fi
	done
    
    echo "${n_running_prog}" >> in.txt

	#write back to in.txt
	for i in ${!prog_isrunning[@]}
	do
		if [ ${prog_isrunning[i]} = 1 ]; then
			echo "$i ${prog_path[i]} ${prog_sm_cur[i]} ${inst_count[i]}" >> in.txt
		fi
	done
	#echo "The remap has already done, the simulation will continue..."
	
}

#MAIN---------------------------------------------------------
#-------------------------------------------------------------
#initiate variables from testcase file
 eval $(awk 'BEGIN{getline;print "max_sim_cycle="$0;getline;print "prog_num="$0;i=0;}\
{print "prog_path["i"]="$1;print "prog_sm_min["i"]="$2;\
print "inst_count["i"]=0";print "prog_sm_opti["i"]="$3;\
print "prog_come_cycle["i"]="$4;print "prog_sm_cur["i"]=0";i++}' testcase) 

let tot_prog_num=$prog_num

#execute the gpgpusim
remap init #first map
#ruby sim2.rb > "out.txt" 
#if [ "$nextcycle" == "$max_sim_cycle" ]; then
#    break
#fi

#remap noninit

while [ "$flag" == "1" ]
do
    ruby sim2.rb > "out.txt" 
    if [ "$nextcycle" == "$max_sim_cycle" ]; then
        break
    fi
    #echo "The gpgpu_sim is doing the simulation..."
    #echo_status
    remap noninit
done

#echo -e "All the program have be tested. the cycle will be reported\n....."
report_cycle
