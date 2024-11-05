#!/bin/bash

# usage: 
# call this script with a category id as argument, eg. 
# ./get_all_workshop_attendees.sh 23

base_url="https://forum.swib.org/"

# id of category
# which contains topics with events
category_id=$1

echo "$(date) : Start curling ${base_url}/c/${category_id}.json"

# get all ids of topics
# tagged with "ws-"
# from category page
topic_ids=$(curl -sL ${base_url}/c/${category_id}.json | jq -r '.topic_list.topics[] | select(.tags[] | startswith("ws-")).id' | uniq)

all_workshop_attendees=()

for topic_id in ${topic_ids[@]}
do
	# get all user names whose status == going
	users=$(curl -sL ${base_url}/t/${topic_id}.json | jq -r '.post_stream.posts[0].event.sample_invitees[] | select(.status == "going").user.username')
	
	for user in ${users[@]}
	do
		all_workshop_attendees+=( "$user going $topic_id" )
	done
done

# print output to file
printf '%s\n' "${all_workshop_attendees[@]}" | sort -k1 > all_workshop_attendees.csv

# print duplicates only
awk -F' ' '$1 in first{print first[$1] $0; first[$1]=""; next} {first[$1]=$0 ORS}' all_workshop_attendees.csv > multiple_workshops_attendees.csv

# print markdown including links
awk -v var="$base_url" '{$1 = "["$1"]("var"u/"$1")"; $3 = "["$3"]("var"t/"$3")";  print}' multiple_workshops_attendees.csv > multiple_workshops_attendees.md

echo "$(date) : Finished!"

