# datahoarder-website-to-markdown

### Description
This bash script takes cookies and a list of forum/webpage indexes as input, then it scrapes all urls from the indexes and download the associated pages as html. All html files are converted to markdown pages, then they are trimmed (awk/grep parameters for trimming must be edited because they are different from website to website) and saved in folders called as the name associated with the index. All the scraped content are uploaded to a remote git repository (you can store the git credentials and make the full process automatic). 
- Forums with "click Like to show the thread" are supported by this script
- If there is a connection error or the website blocks the scraping, the script can be resumed without losing the previously scraped files
- The script must be edited in order to be correctly executed

### Dependences
- [html2md](https://github.com/suntong/html2md)
- [crawley](https://github.com/s0rg/crawley)
- curl
- rsync
- git
