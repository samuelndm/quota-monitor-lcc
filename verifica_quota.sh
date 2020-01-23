#!/bin/bash


if [[ -z $DISPLAY ]]; then
	exit 1;
fi


########################## FUNCTIONS ########################################################################################################

get_percent() {
	
	if [ -e $file_user ]; then
		sed -i '2,$d' $file_user # apaga todas as linhas de informações, exceto o limite que precisa atingir, para que o usuario seja avisado 
	else
		echo $limit_default > $file_user # caso o arquivo que armazena as informações não seja encontrado, será criado um novo 
	fi
	
	quota_user=$(quota -s -u $user | tail -1 | tr -s " ")
	usado_m=$(echo $quota_user | cut -d " " -f1) # variável que armazena a quantidade de cota utilizada com a letra M ( megabytes )
	total_m=$(echo $quota_user | cut -d " " -f2) # variável que armazena a quantidade de cota total do usuario com a letra M ( megabytes )
 	
 	lenght_usado=${#usado_m}
	lenght_total=${#total_m}
 	
 	isFull=$(echo $usado_m | grep "*") # se a cota não estiver em 100% ou mais, a variável fica vazia
 	
 	if [[ -n $isFull ]]; then
		usado_m=${usado_m:0:$lenght_usado}	
		percent=100	
	else	
		usado=${usado_m:0:$lenght_usado - 1}
		total=${total_m:0:$lenght_total - 1}
		
		percent=$(echo "scale=2; ($usado / $total) * 100" | bc | cut -d "." -f1)	
	fi
	
	
	arquivos_ordenados="/tmp/arquivosOrdenados.txt"
	
	qtd_maiores_arquivos=4
	
	du -sh $home_user/* $home_user/.??* | sort -hr | head -$qtd_maiores_arquivos > $arquivos_ordenados
	
	number_list=""
	name_list=""
	total_maiores=0
	
	for (( i = 1; i <= $(cat $arquivos_ordenados | wc -l); i++ )); do
		
		line=$(sed -n "$i"p $arquivos_ordenados)
		
		number_with_M=$(echo $line | awk -v user="$(whoami)" -F "/home/$user/" '{print $1}')
		lenght_number_with_M=${#number_with_M}
		number=${number_with_M:0:$lenght_number_with_M - 2}
		
		name=$(echo $line | awk -v user="$(whoami)" -F "/home/$user" '{print $2}')
		lenght_name=${#name}
		
		if [[ $lenght_name -gt 10 ]]; then
			name=${name:0:$lenght_name -5}
			name+="..."
		fi
		
		
		if [[ $i -eq 1 ]]; then
			number_list+="$number"
			name_list+="$name - $number MB"
		else
			number_list+=",$number"
			name_list+=",$name - $number MB"
		fi
		
		total_maiores=$((total_maiores + $number))
	done
	
	espaco_livre=$(echo "scale=2; $total - $usado" | bc)
	outros=$(echo "scale=2; $espaco_livre - $total_maiores" | bc)
	
	number_list+=",$espaco_livre"
	name_list+=",Espaco Livre - $espaco_livre MB"
	
	number_list+=",$outros"
	name_list+=",Outros - $outros MB"
	
	echo $usado_m >> $file_user
	echo $total_m >> $file_user
	echo $percent >> $file_user
	
	echo $number_list >> $file_user
	echo $name_list >> $file_user
	
}


check_quota_on_login() {
	# verifica se a cota usada do usuário ultrapassou o limite imposto
	
	path_atual=$(dirname $0)
	path_aviso_usuario="$path_atual/aviso_usuario.sh"
	
	get_percent

	limit=$(sed -n 1p $file_user) #--> linha 1 - limite de cota utilizada 
	usado_m=$(sed -n 2p $file_user) #--> linha 2 - cota usada
	total_m=$(sed -n 3p $file_user) #--> linha 3 - cota total
	percent=$(sed -n 4p $file_user) #--> linha 4 - porcentagem da cota utilizada

	if [[ $percent -ge $limit ]]; then
		sleep 7s; $path_aviso_usuario
	fi

}

########################## END FUNCTIONS ########################################################################################################



user=$(whoami)
home_user="/home/$user"
limit_default=70


file_user="/home/$user/.infoCotaUser" # -----|
# Informações do arquivo:					 |
#--> linha 1 - limite de cota utilizada 	 |
#--> linha 2 - cota usada					 |
#--> linha 3 - cota total					 |
#--> linha 4 - porcentagem da cota utilizada |				
#------------------------------------------- |
 
case $1 in 
	"-p") get_percent ;;
	
	"-l") check_quota_on_login ;;
	
	*) echo "Opcao invalida" ;;
esac




