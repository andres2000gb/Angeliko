#!/bin/bash
#775750, Espinosa Gonzalo, Angel, T, 2, A
#777638, Gilgado Barrachina, Andres Maria, T, 2, A
comando2="$UID"
if [ "$comando2" != "0" ]
then
	echo "Este script necesita privilegios de administracion"
	exit 1
fi
if [ $# -ne 3 ]
then
	echo "Numero incorrecto de parametros"
	exit 1
fi
if [ "$1" != "-a" ] && [ "$1" != "-s" ];
then
	echo "Opcion invalida"
	exit 1
fi
contador=0
while read line
    conexion=$(ssh -i '~/.ssh/id_as_ed25519' "as@$line")
    if [ $conexion -eq 1]
    then
        echo "$line no es accesible"
    else
        if [ "$1" == "-a" ]
        then
            while read line
            do
                userL=$(echo "${line##*,}")
                line2=$(echo "${line%,*}")
                passwd=$(echo "${line2##*,}")
                user=$(echo "${line2%,*}")
                if [ "$userL" == "" ] || [ "$user" == "" ] || [ "$passwd" == "" ];
                then
                    echo "Campo invalido"
                    exit 1
                fi
                com=$(ssh -i "as@$line" cat '/etc/passwd' | grep -e "^$user")
                if [ $? -eq 0 ]
                then
                    echo "El usuario $user ya existe"
                else
                    ssh -i '~/.ssh/id_as_ed25519' "as@$line" useradd -c "$userL" -k /etc/skel -K UID_MIN=1815 -m -U "$user"
                    ssh -i '~/.ssh/id_as_ed25519' "as@$line" usermod -f 30 "$user"
                    echo "$user:$passwd" | chpasswd
                    echo "$userL ha sido creado"
                fi
            done < $2
        else
            ssh -i '~/.ssh/id_as_ed25519' "as@$line" mkdir -p "/extra/backup"
            while read line
            do
                usuario="${line%%,*}"
                comando=$(ssh -i '~/.ssh/id_as_ed25519' "as@$line" cat '/etc/passwd' | grep -e "^$usuario:")
                if [ $? -eq 0 ]
                then
                    com6="${comando#*/}"
                    rutaf="${com6%:*}"
                    ssh -i '~/.ssh/id_as_ed25519' "as@$line" tar fcP /extra/backup/"$usuario".tar /"$rutaf"
                    if [ $? -eq 0 ]
                    then
                            ssh -i '~/.ssh/id_as_ed25519' "as@$line" userdel -rf "$usuario"
                    fi
                fi
            
            done < $2
        fi
    fi
done < $3
