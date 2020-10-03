#!/usr/bin/env bash
set -eu

function writelog {
     _dt=$(date +"%F %T,%3N")
     echo $_dt : $1
    }

echo "checking backups in ${1:?missed backups path parameter}"
BACKUPS_PATH=$1

set +e
# forward "No such file or directory" errors to /dev/null
BACKUPS=$(ls $BACKUPS_PATH/*.{vma.gz,vma.lzo,tar.gz} 2>/dev/null)
set -e
if [ "$BACKUPS" != "" ]; then
    for BACKUP in $BACKUPS; do
        RESULT=""
        writelog "Working on $BACKUP file..."
        BACKUP_EXT=${BACKUP##*.}
        case "$BACKUP_EXT" in
            "gz")
                BACKUP_FILENAME=${BACKUP%.*}
                BACKUP_EXT2=${BACKUP_FILENAME##*.}
                case "$BACKUP_EXT2" in
                    "vma")
                        zcat "$BACKUP" | vma verify -v - 2>&1 | tee "$BACKUP.test"
                        set +e
                        RESULT=$(grep -c "ERROR" "$BACKUP.test")
                        set -e
                        ;;
                    "tar")
                        set +e
                        tar tf "$BACKUP" > /dev/null
                        RESULT=$?
                        set -e
                        ;;
                    *) writelog "ERROR: wrong 2nd extension on $BACKUP"
                ;;
                esac
                ;;
            "lzo")
                lzop -d -c "$BACKUP" | vma verify -v - 2>&1 | tee "$BACKUP.test"
                set +e
                RESULT=$(grep -c "ERROR" "$BACKUP.test")
                set -e
                ;;
            *)
                writelog "ERROR: wrong extension on $BACKUP"
                ;;
        esac

        if [ "$RESULT" == "0" ]; then
            writelog "OK   : $BACKUP" >> "$0.log"
        else
            writelog "ERROR: $BACKUP" >> "$0.log"
        fi
    done
fi

