#!/bin/bash

NAME=$1
TYPE="none"
DEV_PATH=`udevadm info -q all -n /dev/$NAME | grep DEVPATH | awk -F '=' '{print $2}'`

function sas_mp_name()
{
    PHY=`cat /sys${DEV_PATH}/../../../../sas_device/end_device-*/phy_identifier`
    ADDR=`cat /sys${DEV_PATH}/../../../../sas_device/end_device-*/enclosure_identifier`
    EXP_ADDR=${ADDR:2:14}
    declare -A JBODSAS3_40
    declare -A JBODSAS3_36
    declare -A JBODSAS2_36
    declare -A JBODSAS4U24
    declare -A JBODSAS2U12
    JBODSAS2_36=(["type"]="SAS2X36" ["SlotCount"]=20 ["fb"]="b" ["startId"]=28 ["startSolt"]=16)
    JBODSAS3_40=(['type']="SAS3x40" ["SlotCount"]=24 ["fb"]="f" ["startId"]=28 ["startSolt"]=12)
    JBODSAS3_36=(["type"]="SAS3x36" ["SlotCount"]=20 ["fb"]="b" ["startId"]=28 ["startSolt"]=16)
    JBODSAS4U24=(['type']="4U24" ["SlotCount"]=24 ["fb"]="f" ["startId"]=28 ["startSolt"]=12)
    JBODSAS2U12=(["type"]="2U12" ["SlotCount"]=12 ["fb"]="b" ["startId"]=28 ["startSolt"]=16)
    FOB="f"
    SAS3_40="SAS3x40"
    SAS3_36="SAS3x36"
    SAS2_36="SAS2X36"
    SAS4U24="4U24"
    SAS2U12="2U12"
    #echo $PHY
    #echo $ADDR
    #echo $EXP_ADDR
    
    SGS=`lsscsi -g | grep enclosu | awk '{print $4,$7}'`
    
    array=(${SGS// / })
    COUNT=${#array[@]}
    
    for ((i=0;i<${COUNT};i+=2))
    do
        SWITCH=`sg_ses --page 0x07 ${array[i+1]} | grep ${EXP_ADDR}`
        if [ -n "${SWITCH}" ]
        then
            if [ "${array[i]}" == "${SAS3_40}" ]
               then
                 FOB=${JBODSAS3_40["fb"]}
            elif [ "${array[i]}" == "${SAS3_36}" ]
               then
                 FOB=${JBODSAS3_36["fb"]}
            elif [ "${array[i]}" == "${SAS4U24}" ]
               then
                 FOB=${JBODSAS4U24["fb"]}
            elif [ "${array[i]}" == "${SAS2U12}" ]
               then
                 FOB=${JBODSAS2U12["fb"]}
            elif [ "${array[i]}" == "${SAS2_36}" ];then
               SLOT=`sg_ses --page 0x07 ${array[i+1]} | grep 'Slot 24'`
                if [ $? == 0 ]
                then
                    FOB="f"
                else
                    FOB="b"
                fi
          
            else
                a=1
                
            fi

        fi
    done
    echo "JBOD_${EXP_ADDR}_${FOB}_phy${PHY}"
    exit 0
}

function iscsi_mp_name()
{
    TAG_PATH=`udevadm info -q all -n /dev/$NAME | grep ID_PATH_TAG`
    if [ $? -ne 0 ]
    then
        exit 1
    fi
    TMP=`echo $TAG_PATH | grep 'surfslocal_surmd'`
    if [ $? -ne 0 ]
    then
        exit 2
    fi
    NAME=`echo $TAG_PATH | awk -F '_surfslocal_' '{print $2}' | awk -F '-lun-' '{print $1}'`
    echo "mp_$NAME"
    exit 0
}

function md_mp_name()
{
    MD_NAME=`udevadm info -q all -n /dev/$NAME | grep MD_DEVNAME`
    if [ $? -ne 0 ]
    then
        exit 1
    fi
    TMP=`echo $MD_NAME | grep 'surmd'`
    if [ $? -ne 0 ]
    then
        exit 2
    fi
    NAME=`echo $MD_NAME | awk -F '=' '{print $2}'`
    echo "mp_$NAME"
    exit 0
}


TMP=`echo $DEV_PATH | grep expander`
if [ $? -eq 0 ]
then
    sas_mp_name
fi

exit 1

#TMP=`echo $DEV_PATH | grep session`
#if [ $? -eq 0 ]
#then
#    iscsi_mp_name
#fi

#TMP=`echo $DEV_PATH | grep 'virtual/block/md'`
#if [ $? -eq 0 ]
#then
#    md_mp_name
#fi
