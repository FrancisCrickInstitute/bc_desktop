#!/bin/bash

ml fluxbox
ml Firefox

export LD_LIBRARY_PATH=/usr/lib64/xorg/modules/drivers:/usr/lib64/xorg/modules/extensions:$LD_LIBRARY_PATH
export PATH=/camp/apps/eb/software/fluxbox/1.3.7-GCCcore-8.2.0/bin:$PATH
echo $DISPLAY

if [ -n $SLURM_X11 ]
then
  echo "Start X server option is selected"
  if [[ $(hostname -s) == *"g"* ]]
  then
    echo "Setting VGL display on a GPU node"

    count=`/usr/bin/nvidia-smi --query-gpu=count --format=csv,noheader,nounits`
    if [ "x${count}" != "x1" ]
    then
        echo "For the time being X setup is only provided for jobs requiring one GPU: --gres=gpu:1."
        exit 1
    fi

    device=`/usr/bin/nvidia-smi --query-gpu=pci.bus_id --format=csv,noheader,nounits`
    if [[ "${device}" =~ "01" ]]
    then
        config="xorg-1.conf"
        display=":11"
    elif [[ "${device}" =~ "41" ]]
    then
        config="xorg-2.conf"
        display=":12"
    elif [[ "${device}" =~ "81" ]]
    then
        config="xorg-3.conf"
        display=":13"
    elif [[ "${device}" =~ "C1" ]]
    then
        config="xorg-4.conf"
        display=":14"
    else
        echo "GPU not recognized..."
        exit 1
    fi

    #echo -e "\n\nYour X display is ${display}\n\n"
    echo ${display}

    Xorg ${display} -config ${config} > /dev/null 2>&1 &

    export VGL_DISPLAY=${display}.0
  fi
  unset SLURM_EXPORT_ENV
fi

(
until fluxbox -display "${DISPLAY}.0" -rc "<%= session.staged_root.join("fluxbox.rc") %>"; do
    echo "Fluxbox crashed with exit code $?. Respawning..." >&2
    sleep 2
  done
)

