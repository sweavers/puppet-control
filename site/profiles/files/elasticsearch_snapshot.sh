#! /bin/bash
# Bakcup script for elastic search instances

# Creates (backup) repo if required
# Creates new snapshots
# Tidy up old snapshots
ESHOST=$1
USAGE=`basename $0`" [ELASTICSERCH HOST] e.g. localhost:9200"
SNAPSHOT_TIMESTAMP=$(date +%d%m%y-%H%M)
RETENTION=30 # Retention period in days

# Purely cosmetic function to prettify output
# Set OUTPUT_LABEL to change the label
# Supports ERROR, SUCCESS, and WARN as arguments
function output() {
  local label=${OUTPUT_LABEL:-$0}
  local timestamp=$(date +%d/%m/%Y\ %H:%M)
  local colour='\033[34m' # Blue
  local reset='\033[0m'
  case $1 in
    ERROR) local colour='\033[31m' ;; # Red
    SUCCESS) local colour='\033[32m' ;; # Green
    WARN) local colour='\033[33m' ;; # Yellow
  esac
  while read line; do
    echo -e "${colour}${label} [${timestamp}]${reset} ${line}"
  done
}

# Check that a elastic search host has been specified
[ -z "$ESHOST" ] && echo -e "ERROR - You must specify an elastic search host! \n Usage: ${USAGE}" | output ERROR && exit 1

# Check if  a (backup) repo is already registered - register if not
if [[ $(curl -s -XGET "http://${ESHOST}/_snapshot") == '{}' ]]; then
  OUTPUT=$(curl -s -XPUT "http://${ESHOST}/_snapshot/backups?wait_for_completion=true" -d '{
    "type": "fs",
    "settings": {
      "location": "/backups",
      "compress": true
    }
  }')
  if [[ $OUTPUT == '{"acknowledged":true}' ]]; then
    echo "Sucsessfully registered repository" | output SUCCESS
  else
    echo -e "Error registering repository\n${OUTPUT}" | output ERROR && exit 1
  fi
else
  echo "Repository already registered" | output SUCCESS
fi

# # Tidy up old snapshots
# Get snapshot info
JSON=$(curl -s -XGET "http://${ESHOST}/_snapshot/backups/_all")
# return only snapshot name and end time
JSON=$(echo $JSON | jq '.snapshots[] | "\(.snapshot) \(.end_time)"' | sed 's/"//g')
# pair snapshot and timestamp
JSON=$(echo $JSON | awk '{for (i=1; i<=NF; i+=2) printf "%s,%s\n", $i, $(i+1) }')
for PAIR in $JSON; do
  SNAPSHOT=$(echo $PAIR | cut -f 1 -d ',')
  TIMESTAMP=$(echo $PAIR | cut -f 2 -d ',')
  DAYS_SINCE=$(((`date -d "$TIMESTAMP" +%s` - `date +%s`)/86400))
  # debug only
  #echo " snapshot = ${SNAPSHOT} timstamp = ${TIMESTAMP} ${DAYS_SINCE} days old"
  if [[ $DAYS_SINCE -gt $RETENTION ]]; then
    echo "Deleting old snapshot ${SNAPSHOT}" | output WARN
    OUTPUT=$(curl -s -XDELETE "http://${ESHOST}/_snapshot/backups/${SNAPSHOT}")
    if [[ $OUTPUT == '{"acknowledged":true}' ]]; then
      echo "Sucsessfully deleted old snapshot ${SNAPSHOT}" | output SUCCESS
    else
      echo -e "Error deleting old snapshot ${SNAPSHOT}" | output ERROR
    fi
  else
    echo "No snapshots older then ${RETENTION} days - nothing to tidy up" | output SUCCESS
  fi
done

# Check if a snapshot has already been created for today
# Get snapshot info
JSON=$(curl -s -XGET "http://${ESHOST}/_snapshot/backups/_all")
# debug only
#echo -e "Output of snapshot info\n${JSON}"
# return only snapshot end time
JSON=$(echo $JSON | jq '.snapshots[] | "\(.end_time)"' | sed 's/"//g')
# debug only
#echo -e "Output of jq\n${JSON}"
for LINE in $JSON; do
  DATE=$(echo $LINE | cut -f 1 -d 'T')
  # debug only
  #echo "Time stamp(s) for existing snapshots ${DATE}"
  if [[ $(date +%Y-%m-%d) == $DATE ]]; then
    echo "Snapshot for ${DATE} already exists - nothing to do" | output SUCCESS && exit 0
  fi
done

# Create new snapshot
OUTPUT=$(curl -s -XPUT "http://${ESHOST}/_snapshot/backups/${SNAPSHOT_TIMESTAMP}?wait_for_completion=true")
if [[ `echo $OUTPUT | grep -o SUCCESS | wc -l` -ge 1 ]]; then
  echo "Sucsessfully created snapshot ${SNAPSHOT_TIMESTAMP}" | output SUCCESS
else
  echo -e "Error creating snapshot ${SNAPSHOT_TIMESTAMP}\n${OUTPUT}" | output ERROR
fi
