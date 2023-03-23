# VARIABLES
cookies="key1=value1;key=value2;"
declare -A indexes["url_index_1"]="https://www.website-to-scrape.com/forum/index.php?topic=1" \
	   indexes["url_index_2"]="https://www.website-to-scrape.com/forum/index.php?topic=2" \
CYAN='\033[1;36m'
RED='\033[1;31m'
NC='\033[0m'

# CREATE DESTINATION FOLDER
mkdir -p website-backup-temp
cd website-backup-temp
# CLEAN FILES WITH ZERO SIZE (PREVIOUS SCRAPING WAS BLOCKED BY THE SITE OR CONNECTION ISSUES)
find . -maxdepth 1 -type f -size 0 -delete


for i in "${!indexes[@]}"
do
	echo -e "${RED}Parsing all indexes of ${i}${NC}\n"
	
	# CREATE SUBFOLDER
	mkdir -p "$i";cd "$i"
	
	# LOOP FOR ALL INDEXES OF THE CURRENT LIST
	lists=${indexes[$i]};lists=(${lists//;/ })
	for url_list in "${lists[@]}";do
		
		# SCRAPE ALL URLS FROM THE CURRENT LIST
		echo -e "${RED}Scraping the index: ${url_list}${NC}\n"
		crawley -depth 1 -headless -cookie "$cookies" "$url_list" | grep -E 'https\:\/\/www\.website\-to\-scrape\.com\/forum\/index\.php\?topic\=[0-9]+$' > "../${i}.txt"
		# DOWNLOAD THE CURRENT THREAD OF THE CURRENT LIST
		while read line; do
		
			# BUILD THE TITLE OF THE CURRENT THREAD
			filename=$(curl -L -b "$cookies" "$line" | grep '<title>' | sed -e "s/<title>//"| sed -e "s/<\/title>//" | sed 's/^[ \t]*//;s/[ \t]*$//' | sed -r 's/\//\\/g'| sed -r 's/\://g');filename=${filename::-1}
			echo -e "${CYAN}Scraping ${filename}..${NC}"

			# JUMP FILES ALREADY DOWNLOADED IN THE PAST
			if [ -f "${filename}_trimmed.md" ]; then
    				echo -e "${CYAN}File previously downloaded, jumping..${NC}"
    				continue
			fi
			
			# CHECK IF THE LIKE BUTTON NEEDS TO BE CLICKED (IF THE FORUM HAS A LIKE BUTTON)
			echo -e "${CYAN}Checking \"Thanks\" button..${NC}"
			thanksbutton=$(curl -L -b "$cookies" "$line" | grep "action=thank" | grep "refresh"| sed -r 's/.*\<a href\=\"(.+)\" class\=\"thank_you_button_link\".*/\1/')
			if [ -z "$thanksbutton" ]
			then
				echo -e "${CYAN}Button is already clicked!${NC}"
			else
				echo -e "${CYAN}Clicking button [$thanksbutton]..${NC}"
				curl -b "$cookies" "$thanksbutton"
			fi
	  
			# DOWNLOAD HTML
			echo -e "${CYAN}Donwloading $line..${NC}"
			curl -L -b "$cookies" "$line" -o "${filename}.html"
			
			# CONVERT HTML TO MARKDOWN
			echo -e "${CYAN}Converting "${filename}.html" to markdown..${NC}"
			html2md -i "${filename}.html" > "${filename}.md"
			
			# TRIM MARKDOWN CODE
			echo -e "${CYAN}Trimming markdown code..${NC}"
			sed '/clean the beginning of the document from HERE/,/to HERE/d' "${filename}.md" | tail -n +5 | sed '/clean the ending of the document from HERE/,/to HERE/d' | head -n -3 > "${filename}_trimmed.md"
			
			# CLEAN LEFTOVERS
			echo -e "${CYAN}Cleaning leftovers..${NC}"
			gio trash "${filename}.html"
			gio trash "${filename}.md"
		done < "../${i}.txt"
		
		# REMOVING TEXT FILE
		echo -e "${CYAN}Cleaning ${i}.txt..${NC}"
		gio trash "../${i}.txt"
		
	done
	cd ..
done

cd ..
# MOVING FILES TO THE LOCAL REPOSITORY (./website-backup)
rsync -aAX --exclude="*.Trash-1000" --exclude=".*/" "./website-backup-temp/" "./website-backup/"
# REMOVE OLD FOLDER
gio trash ./website-backup-temp/

# UPLOAD MARKDOWN FILES TO GITEA REPOSITORY
echo -e "${RED}Uploading files to gitea.. $line${NC}"

cd website-backup
today=$(date +%F)
git add .
git commit -m "scheduled snapshot ${today}"
git push "https://github.com/XXXX/XXXX.git"
