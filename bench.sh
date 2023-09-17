#!/bin/bash


SCRIPTPATH=`pwd`

#get block device or a file for test
read -p "please Enter 1 or 2 (1 block device and 2 file path , defualt: 1): " DISKTYPE
DISKTYPE=${DISKTYPE:-'1'}

if [[ "$DISKTYPE" == '1' ]]; then
    read -p "Enter your back device (ex: /dev/sdb , default: /dev/sdb): " BLOCKDEVICE
    BLOCKDEVICE=${BLOCKDEVICE:-'/dev/sdb'}

elif [[ "$DISKTYPE" == '2' ]]; then
    read -p "Enter your file path (ex: /tmp/fio.tmp , default: /tmp/fio.tmp): " BLOCKDEVICE
    BLOCKDEVICE=${BLOCKDEVICE:-'/tmp/fio.tmp'}

    read -p "Enter your file size (ex: 10g , default: 20g): " SIZE
    SIZE=${SIZE:-"20g"}
    echo $SIZE

else 
    echo "invalid input ..... try again (enter 1 or 2)"
    exit 0
fi 


#Get block size
read -p "Enter your block size (Seq) (ex: 4k,8k,4m,... , defualt: 4m): " BLOCKSIZESEQ
BLOCKSIZESEQ=${BLOCKSIZESEQ:-'4m'}

read -p "Enter your block size (Rand) (ex: 4k,8k,4m,... , default: 4k): " BLOCKSIZERAND
BLOCKSIZERAND=${BLOCKSIZERAND:-'4k'}

#Get number of jobs
read -p "Enter number of jobs (default: 2): " NUMJOBS
NUMJOBS=${NUMJOBS:-'2'}


#Get iodepth
read -p "Enter iodepth (default: 256): " IODEPTH 
IODEPTH=${IODEPTH:-'256'}

# Prepare table header
# https://stackoverflow.com/questions/12768907/how-can-i-align-the-columns-of-tables-in-bash#answer-49180405
source $SCRIPTPATH/print-table.sh
echo -e "Description, Bandwidth (MB),IOPS,Latency (us)" > $SCRIPTPATH/results.csv

#FIO SEQ Read
echo "Sequential read ....."
if [[ "$DISKTYPE" == '1' ]]; then
    echo "fio --filename=$BLOCKDEVICE  --direct=1 --rw=read --bs=$BLOCKSIZESEQ --ioengine=libaio --iodepth=$IODEPTH --runtime=60 --ramp_time=30 --numjobs=$NUMJOBS --time_based --group_reporting --name=iops-test-job --eta-newline=1 --output-format=json"
    FIOSEQREADOUTPUT=`fio --filename=$BLOCKDEVICE  --direct=1 --rw=read --bs=$BLOCKSIZESEQ --ioengine=libaio --iodepth=$IODEPTH --runtime=60 --ramp_time=30 --numjobs=$NUMJOBS --time_based --group_reporting --name=iops-test-job --eta-newline=1 --output-format=json`    
else 
    echo "fio --filename=$BLOCKDEVICE --size=$SIZE  --direct=1 --rw=read --bs=$BLOCKSIZESEQ --ioengine=libaio --iodepth=$IODEPTH --runtime=60 --ramp_time=30 --numjobs=$NUMJOBS --time_based --group_reporting --name=iops-test-job --eta-newline=1 --output-format=json"
    FIOSEQREADOUTPUT=`fio --filename=$BLOCKDEVICE --size=$SIZE  --direct=1 --rw=read --bs=$BLOCKSIZESEQ --ioengine=libaio --iodepth=$IODEPTH --runtime=60 --ramp_time=30 --numjobs=$NUMJOBS --time_based --group_reporting --name=iops-test-job --eta-newline=1 --output-format=json`
    
fi
SEQREADBAND=`echo $FIOSEQREADOUTPUT | jq '.jobs[0].read.bw'`
SEQREADBAND=`echo $SEQREADBAND/1000 | bc`
#SEQREADIOPS=`echo $FIOSEQREADOUTPUT | jq '.jobs[0].read.io_kbytes'`
SEQREADIOPS=`echo $FIOSEQREADOUTPUT | jq '.jobs[0].read.iops'`
SEQREADLATE=`echo $FIOSEQREADOUTPUT | jq '.jobs[0].read.lat_ns.mean'`
SEQREADLATE=`echo $SEQREADLATE/1000 | bc`
DESCRIPTION="SEQUENTIAL READ"
echo -e "${DESCRIPTION},${SEQREADBAND},${SEQREADIOPS},${SEQREADLATE}" >> $SCRIPTPATH/results.csv


# #FIO SEQ Write
echo "Sequential write ....."
if [[ "$DISKTYPE" == '1' ]]; then
    echo "fio --filename=$BLOCKDEVICE --direct=1 --rw=write --bs=$BLOCKSIZESEQ --ioengine=libaio --iodepth=$IODEPTH --runtime=60 --ramp_time=30 --numjobs=$NUMJOBS --time_based --group_reporting --name=iops-test-job --eta-newline=1 --output-format=json"
    FIOSEQWRITEOUTPUT=`fio --filename=$BLOCKDEVICE --direct=1 --rw=write --bs=$BLOCKSIZESEQ --ioengine=libaio --iodepth=$IODEPTH --runtime=60 --ramp_time=30 --numjobs=$NUMJOBS --time_based --group_reporting --name=iops-test-job --eta-newline=1 --output-format=json`
else 
    echo "fio --filename=$BLOCKDEVICE --size=$SIZE --direct=1 --rw=write --bs=$BLOCKSIZESEQ --ioengine=libaio --iodepth=$IODEPTH --runtime=60 --ramp_time=30 --numjobs=$NUMJOBS --time_based --group_reporting --name=iops-test-job --eta-newline=1 --output-format=json"
    FIOSEQWRITEOUTPUT=`fio --filename=$BLOCKDEVICE --size=$SIZE --direct=1 --rw=write --bs=$BLOCKSIZESEQ --ioengine=libaio --iodepth=$IODEPTH --runtime=60 --ramp_time=30 --numjobs=$NUMJOBS --time_based --group_reporting --name=iops-test-job --eta-newline=1 --output-format=json`
fi
SEQWRITEBAND=`echo $FIOSEQWRITEOUTPUT | jq '.jobs[0].write.bw'`
SEQWRITEBAND=`echo $SEQWRITEBAND/1000 | bc`
#SEQWRITEIOPS=`echo $FIOSEQWRITEOUTPUT | jq '.jobs[0].write.io_kbytes'`
SEQWRITEIOPS=`echo $FIOSEQWRITEOUTPUT | jq '.jobs[0].write.iops'`
SEQWIRTELATE=`echo $FIOSEQWRITEOUTPUT | jq '.jobs[0].write.lat_ns.mean'`
SEQWIRTELATE=`echo $SEQWIRTELATE/1000 | bc`
DESCRIPTION="SEQUENTIAL WRITE"
echo -e "${DESCRIPTION},${SEQWRITEBAND},${SEQWRITEIOPS},${SEQWIRTELATE}" >> $SCRIPTPATH/results.csv

#FIO Rand Read
echo "Random read ....."
if [[ "$DISKTYPE" == '1' ]]; then
    echo "fio --filename=$BLOCKDEVICE --direct=1 --rw=randread --bs=$BLOCKSIZERAND --ioengine=libaio --iodepth=$IODEPTH --runtime=60 --ramp_time=30 --numjobs=$NUMJOBS --time_based --group_reporting --name=iops-test-job --eta-newline=1 --output-format=json"
    FIORANDREADOUTPUT=`fio --filename=$BLOCKDEVICE --direct=1 --rw=randread --bs=$BLOCKSIZERAND --ioengine=libaio --iodepth=$IODEPTH --runtime=60 --ramp_time=30 --numjobs=$NUMJOBS --time_based --group_reporting --name=iops-test-job --eta-newline=1 --output-format=json`
else 
    echo "fio --filename=$BLOCKDEVICE --size=$SIZE --direct=1 --rw=randread --bs=$BLOCKSIZERAND --ioengine=libaio --iodepth=$IODEPTH --runtime=60 --ramp_time=30 --numjobs=$NUMJOBS --time_based --group_reporting --name=iops-test-job --eta-newline=1 --output-format=json"
    FIORANDREADOUTPUT=`fio --filename=$BLOCKDEVICE --size=$SIZE --direct=1 --rw=randread --bs=$BLOCKSIZERAND --ioengine=libaio --iodepth=$IODEPTH --runtime=60 --ramp_time=30 --numjobs=$NUMJOBS --time_based --group_reporting --name=iops-test-job --eta-newline=1 --output-format=json`
fi
RANDREADBAND=`echo $FIORANDREADOUTPUT | jq '.jobs[0].read.bw'`
RANDREADBAND=`echo $RANDREADBAND/1000 | bc`
#RANDREADIOPS=`echo $FIORANDREADOUTPUT | jq '.jobs[0].read.io_kbytes'`
RANDREADIOPS=`echo $FIORANDREADOUTPUT | jq '.jobs[0].read.iops'`
RANDREADLATE=`echo $FIORANDREADOUTPUT | jq '.jobs[0].read.lat_ns.mean'`
RANDREADLATE=`echo $RANDREADLATE/1000 | bc`
DESCRIPTION="RANDOM READ"
echo -e "${DESCRIPTION},${RANDREADBAND},${RANDREADIOPS},${RANDREADLATE}" >> $SCRIPTPATH/results.csv

# #FIO Rand Write
echo "Random write ....."
if [[ "$DISKTYPE" == '1' ]]; then
    echo "fio --filename=$BLOCKDEVICE --direct=1 --rw=randwrite --bs=$BLOCKSIZERAND --ioengine=libaio --iodepth=$IODEPTH --runtime=60 --ramp_time=30 --numjobs=$NUMJOBS --time_based --group_reporting --name=iops-test-job --eta-newline=1 --output-format=json"
    FIORANDWRITEOUTPUT=`fio --filename=$BLOCKDEVICE --direct=1 --rw=randwrite --bs=$BLOCKSIZERAND --ioengine=libaio --iodepth=$IODEPTH --runtime=60 --ramp_time=30 --numjobs=$NUMJOBS --time_based --group_reporting --name=iops-test-job --eta-newline=1 --output-format=json`
else
    echo "fio --filename=$BLOCKDEVICE --size=$SIZE --direct=1 --rw=randwrite --bs=$BLOCKSIZERAND --ioengine=libaio --iodepth=$IODEPTH --runtime=60 --ramp_time=30 --numjobs=$NUMJOBS --time_based --group_reporting --name=iops-test-job --eta-newline=1 --output-format=json"
    FIORANDWRITEOUTPUT=`fio --filename=$BLOCKDEVICE --size=$SIZE --direct=1 --rw=randwrite --bs=$BLOCKSIZERAND --ioengine=libaio --iodepth=$IODEPTH --runtime=60 --ramp_time=30 --numjobs=$NUMJOBS --time_based --group_reporting --name=iops-test-job --eta-newline=1 --output-format=json`
fi
RANDWRITEBAND=`echo $FIORANDWRITEOUTPUT | jq '.jobs[0].write.bw'`
RANDWRITEBAND=`echo $RANDWRITEBAND/1000 | bc`
#RANDWRITEIOPS=`echo $FIORANDWRITEOUTPUT | jq '.jobs[0].write.io_kbytes'`
RANDWRITEIOPS=`echo $FIORANDWRITEOUTPUT | jq '.jobs[0].write.iops'`
RANDWRITELATE=`echo $FIORANDWRITEOUTPUT | jq '.jobs[0].write.lat_ns.mean'`
RANDWRITELATE=`echo $RANDWRITELATE/1000 | bc`
DESCRIPTION="RANDOM WRITE"
echo -e "${DESCRIPTION},${RANDWRITEBAND},${RANDWRITEIOPS},${RANDWRITELATE}" >> $SCRIPTPATH/results.csv

#Show results in a Table
printTable ',' "$(cat results.csv)"