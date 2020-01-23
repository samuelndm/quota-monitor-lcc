#!/bin/bash

########################## FUNCTIONS ########################################################################################################


verifica_status() {
	# Função criada para verificar o status atual da variavel $? e sair do script se for igual a 1
	
	case $? in
		1) deletar_arquivo_antigo; exit 1 & $aviso_usuario_path ;;
	esac

}



deletar_arquivo_antigo() {
	# Função criada para deletar o arquivo .txt que salva as o caminho das pastas, caso ela já exista
	
	if [[ -s $arquivos_analisados ]] || [[ -s $arquivos_ordenados ]] || [[ -s $dir_files_home ]]; then
		rm $arquivos_analisados $arquivos_ordenados $dir_files_home;
	else
		touch $arquivos_analisados $arquivos_ordenados;
		chmod 777 $arquivos_analisados $arquivos_ordenados $dir_files_home;
	fi

}



analisar_apenas_home () {
	# Analisa a home do usuário
	ls -A "$home_user/" | grep -vE "Downloads|Documentos|Imagens|Vídeos|.cache|.config|.email_aluno|.infoCotaUser" | tee -a $dir_files_home
		
	texto_home="Home"
	
	$( while read i; do

		du -sh "$home_user/$i" 2>/dev/null | tee -a $arquivos_analisados;
		
		done < $dir_files_home ) | zenity --progress \
			--text="Pode demorar alguns minutos...\n\nVerificando Arquivos e Pastas em  --  $texto_home  --" \
			--pulsate \
			--auto-close \
			--width 500
	
	#cat $arquivos_analisados | sort -hr | nl > $arquivos_ordenados  ## Essa parte é feita em analisar_pastas() -^^-
	
	rm -f $dir_files_home
	verifica_status

}



analisar_pastas() {
	# Função criada para calcular o tamanho das pastas que recebe como paramentro e salvar em um arquivo.txt
	
	textos_msg=( "Downloads" "Documentos" "Imagens" "Vídeos" "Lixeira" "Cache" "Configurações" )
	
	for ((i = 0; i < ${#textos_msg[*]}; i++)); do
		
		if [[ "$1" = *".cache"* || "$1" = *"Trash"* ]]; then
			dir_received="$1*"
		else
			dir_received="$1/*"
		fi
		
		$( du -sh $dir_received 2>/dev/null | tee -a $arquivos_analisados ) | zenity --progress \
				--text="Pode demorar alguns minutos...\n\nVerificando Arquivos e Pastas em  --  ${textos_msg[$i]}  --" \
				--pulsate \
				--auto-close \
				--width 500
				
		verifica_status
		shift
	done
	
	# Ordena os arquivos pelo tamanho e atribui linhas a cada um deles
	cat $arquivos_analisados | sort -hr | nl > $arquivos_ordenados
	verifica_status
	
}



mostrar_arquivos_pastas() {
	# Função criada para exibir os arquivos e pastas analisados
	
	while true; do
	
		chosen_file=$(cat $arquivos_ordenados | zenity  --list \
				--title "Arquivos/Pastas" \
				--text "<big><b>- Selecione o(s) arquivo(s) ou pasta(s) que deseja excluir</b></big>\n" \
				--width 640 \
				--height 580 \
				--cancel-label "Voltar" \
				--ok-label "Excluir" \
				--column "    #  -  Tamanho  -  Arquivos/Pastas" \
				--separator " /home")
		
		case $? in
			0) confirmacao=$(confirmar_exclusao_arquivos) ;;
			
			1) deletar_arquivo_antigo; exit 1 & $aviso_usuario_path; exit 1;;
		esac
	
		if [[ "$confirmacao" == "true" ]]; then
			excluir_arquivo $chosen_file
		fi
	done

}



confirmar_exclusao_arquivos() {
	# Função criada para confirmar se o usuario quer mesmo excluir o arquivo
	
	zenity --question \
		--title="Aviso" \
		--text="Tem certeza que desejar excluir?" \
		--no-wrap \
		--default-cancel \
		--cancel-label "Não" \
		--ok-label "Sim"
			
	case $? in
		0) echo "true" ;;
	esac
	
}



excluir_arquivo() {
	# Função criada para escluir o arquivo recebido
	
	line_file=$1 # Primeiro Parametro recebido é a linha do arquivo a ser deletado
	shift; shift; # Remove o primeiro e segundo parametros que são a linha e tamanho do arquivos
	file_received="$*" # Atribui dos os parametros recebidos na variavel
	
	$(if [[ -d $file_received ]]; then
		empty_dir=$(mktemp -d) ;
		rsync -r --delete $empty_dir/ "$file_received" ;
	else
		rm -f ./"$file_received" ;
	fi 
	
	sed -i "${line_file}s/.*/------- DELETADO -------/" $arquivos_ordenados) | zenity \
		--progress \
		--text="Excluindo Arquivo/Pasta..." \
		--pulsate \
		--auto-close \
			
	verifica_status

}



main_lista_arquivos() {
	# Função Main do script
	
	deletar_arquivo_antigo
	analisar_apenas_home
	analisar_pastas "$downloads_user" "$documentos_user" "$imagens_user" "$xvideos_user" "$lixeira_user" "$cache_user" "$config_user"
	mostrar_arquivos_pastas

}

########################## END FUNCTIONS ########################################################################################################

#######################################################################################################################################

# Declaração de variaveis globais do script
user=$(whoami)
path_atual=$(dirname $0)
aviso_usuario_path="$path_atual/aviso_usuario.sh"
home_user="/home/$user"
home_user_all=$(ls -A $home_user/ | grep -vE "|Área de Trabalho|Downloads|Documentos|Imagens|Vídeos|.cache|.config|.email_aluno|.infoCotaUser")
area_trab_user="$home_user/Área\de\Trabalho"
downloads_user="$home_user/Downloads"
documentos_user="$home_user/Documentos"
imagens_user="$home_user/Imagens"
xvideos_user="$home_user/Vídeos"
lixeira_user="$home_user/.local/share/Trash/files"
cache_user="$home_user/.cache"
config_user="$home_user/.config"

arquivos_analisados="/tmp/arquivosCarregados.txt"
arquivos_ordenados="/tmp/arquivosOrdenados.txt"
dir_files_home="/tmp/pastas_arquivos_home.txt"
