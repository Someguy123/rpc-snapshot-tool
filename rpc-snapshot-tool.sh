#!/usr/bin/env zsh
#####################################################
#                                                   #
#         Someguy's Easy RPC Snapshot Tool          #
#                 by @someguy123                    #
#                                                   #
#     github.com/Someguy123/rpc-snapshot-tool       #
#                                                   #
#                 MIT/X11 License                   #
#                                                   #
#####################################################
#
# Depends on various things from my someguy-scripts repo ( https://github.com/Someguy123/someguy-scripts )
# 
# If someguy-scripts can't be found globally, it'll download it locally within this repo folder.
#
# For easiest usage, add to your .zshrc / .bashrc:
#
#   DEFAULT_VG="nvraid"         # Set this to the VG containing your RPC nodes' data/shm volumes
#   BASE_RPC_DIR="${HOME}/rpc"  # Set this to the folder containing Privex/hive-rpcs-docker
#
#   rpc-snapshot() {
#       /root/rpc-snapshot-tool/rpc-snapshot-tool.sh "$@" 
#   }
#
#

_SDIR=${(%):-%N}
DIR="$( cd "$( dirname "${_SDIR}" )" && pwd )"

# The default LVM volume group to be used, which contains your RPC nodes' data/shm volumes
: ${DEFAULT_VG="nvraid"}

# Folder containing docker-compose RPC setup ( see https://github.com/Privex/hive-rpcs-docker/ )
: ${BASE_RPC_DIR="${HOME}/rpc"}

if [[ -d "/etc/zsh_files" ]]; then
    ZFILE_DIR="/etc/zsh_files"
elif [[ -d "${HOME}/.zsh_files" ]]; then
    ZFILE_DIR="${HOME}/.zsh_files"
elif [[ -d "${DIR}/someguy-scripts/zsh_files" ]]; then
    ZFILE_DIR="${DIR}/someguy-scripts/zsh_files"
else
    echo -e "\n [!!!] Could not find someguy-scripts zsh_files. Downloading from Git...\n"
    cd "$DIR"
    git clone https://github.com/Someguy123/someguy-scripts.git someguy-scripts
    ZFILE_DIR="${DIR}/someguy-scripts/zsh_files"
    echo -e "\n [+++] Downloaded someguy-scripts into ${DIR} - Using zsh_files at ${ZFILE_DIR}\n"
fi

source "${ZFILE_DIR}/colors.zsh"
source "${ZFILE_DIR}/common.zsh"
source "${ZFILE_DIR}/lvsnapshot.zsh"

rpc-snapshot() {
    local rpc_name rpc_data rpc_shm mount_data mount_shm
    local rpc_container rpc_dir container_list

    export DEFAULT_VG

    _check_rpcname() {
        case "$rpc_name" in
            core*|CORE*|full*|FULL*)
                rpc_name="core" rpc_data="hive1" rpc_shm="hiveshm1" mount_data="/hive/rpc1" mount_shm="/shmhive/rpc1"
                rpc_container="rpc-${rpc_name}" rpc_dir="${BASE_RPC_DIR}/${rpc_name}"
                msg green "\n -> You've selected 'core' - the RPC full node\n"
                return 0
                ;;
            acch*|ACCH*|low*|LOW*)
                rpc_name="acchist" rpc_data="hive2" rpc_shm="hiveshm2" mount_data="/hive/rpc2" mount_shm="/shmhive/rpc2"
                rpc_container="rpc-${rpc_name}" rpc_dir="${BASE_RPC_DIR}/${rpc_name}"
                msg green "\n -> You've selected 'acchist' - the RPC account history low memory node\n"
                return 0
                ;;
            *)
                msg bold red "\nPlease enter 'core' or 'acchist'\n"
                return 1
                ;;
        esac
    }
    if (( $# < 1 )); then
		while true; do
            msg green "\n\nSomeguy123's Easy RPC Snapshot Tool™\n"
            msg green "Please select an RPC to snapshot / restore\n"
            msg cyan "      core       - RPC Full Node (hive1/rpc1)"
            msg cyan "      acchist    - RPC Low memory account history node (hive2/rpc2)\n"
			rpc_name=""
            vared -p "${YELLOW}Enter the RPC name here (core / acchist):${RESET} " -c rpc_name
            if _check_rpcname; then
                break
            else
                sleep 2
                continue
            fi
		done
    else
        rpc_name="$1"
        if ! _check_rpcname; then
            msg red "Re-run $0 with a valid node selection"
            return 1
        fi
    fi


    msg magenta "\n >>> name: $rpc_name | data: $rpc_data | shm: $rpc_shm | datamount: $mount_data | shm_mount: $mount_shm \n"

    if ! yesno "${YELLOW}Is this correct?"; then
        msg red "Let's try this again ...\n"
        rpc_name=""
        rpc-snapshot
        return $?
    fi


    local snapshot_online=0

    msg yellow " [...] Checking if ${rpc_container} is running ..."

    container_list=$(docker ps -f "name=${rpc_container}" | wc -l)
    container_list=$((container_list))

    if (( container_list >= 2 )); then
        msg bold yellow "Container ${rpc_container} appears to be running."
        msg bold yellow "For safety, it's recommended to stop the container before making a snapshot."

        if yesno "${RED}Do you want to stop the container now?"; then
            cd "$rpc_dir"
            ./run.sh stop
        else
            msg yellow "\nSnapshots taken while the container is running are generally unusable\n"
            msg yellow "However if you really want to... you can take a snapshot anyway.\n"

            if yesno "${RED}Do you want to take a snapshot anyway?"; then
                msg green "\n >> Okay. Will try to take an online snapshot"
                snapshot_online=1
            else
                msg red "No snapshot to be taken. Exiting."
                return 1
            fi
        fi
    else
        msg bold green " [+++] Container ${rpc_container} doesn't appear to be running. Looks like we're safe to do an offline snapshot :)\n"
    fi

    if (( snapshot_online == 1 )); then
        msg bold magenta "\n =================================================================== \n"
        msg bold magenta " >>> Snapshotting data volume $rpc_data (online - no unmounting)"
        msg bold magenta "\n =================================================================== \n"
        snapshot "$rpc_data"
        msg bold magenta "\n =================================================================== \n"
        msg bold magenta " >>> Snapshotting shm/rocksdb volume $rpc_shm (online - no unmounting)"
        msg bold magenta "\n =================================================================== \n"
        snapshot "$rpc_shm"
    else
        msg bold magenta "\n =================================================================================== \n"
        msg bold magenta " >>> Snapshotting RPC node data + shm $rpc_name (offline - unmount + remount)"
        msg bold magenta "\n =================================================================================== \n"

        msg green "\n >>> Unmounting $mount_data ...\n"
        umount -v "$mount_data"

        msg green "\n >>> Unmounting $mount_shm ...\n"
        umount -v "$mount_shm"

        msg green "\n >>> Snapshotting $rpc_data ...\n"
        snapshot "$rpc_data"

        msg green "\n >>> Snapshotting $rpc_shm ...\n"
        snapshot "$rpc_shm"

        msg green "\n >>> Re-mounting $mount_data ...\n"
        mount -v "$mount_data"

        msg green "\n >>> Re-mounting $mount_shm ...\n"
        mount -v "$mount_shm"

        msg green "\n >>> Starting container $rpc_container ...\n"
        cd "$BASE_RPC_DIR"
        docker-compose up -d "$rpc_container"
    fi


    msg bold green "\n =================================================================== \n"
    msg bold green "              +++ Finished snapshot for RPC '${rpc_name}' +++            "
    msg bold green "\n =================================================================== \n"


}

rpc-snapshot "$@"

