#!/bin/bash

# usage: 
# call this script with a category id as argument, eg. 
# ./get_workshop_attendees_per_slot.sh 23

# Maybe relevant for future use cases:
# Instead of starting with a category page
# we could also fetch all tags from https://forum.swib.org/tags.json

base_url="https://forum.swib.org"

# id of category
# which contains topics with events
category_id=$1

echo "$(date) : Start curling ${base_url}/c/${category_id}.json"

# get all tags starting with "ws-slot-"
slot_names=$(curl -sL ${base_url}/c/${category_id}.json | jq -r '.topic_list.topics[].tags[]' | sort -u | grep -E '^ws-slot-')

for slot_name in ${slot_names[@]}
do
	echo $slot_name

	topic_ids=$(curl -sL ${base_url}/tag/${slot_name}.json | jq -r '.topic_list.topics[].id')

	workshop_attendees=()

	for topic_id in ${topic_ids[@]}
	do
		echo $topic_id
		
		# get all user names whose status == going
		users=$(curl -sL ${base_url}/t/${topic_id}.json | jq -r '.post_stream.posts[0].event.sample_invitees[] | select(.status == "going").user.username')
		
		for user in ${users[@]}
		do
			workshop_attendees+=( "$user going $topic_id in $slot_name" )
		done
	done

	# print output to file
	printf '%s\n' "${workshop_attendees[@]}" | sort -k1 > workshop_attendees_$slot_name.csv

	# print duplicates only
	awk -F' ' '$1 in first{print first[$1] $0; first[$1]=""; next} {first[$1]=$0 ORS}' workshop_attendees_$slot_name.csv > multiple_workshops_attendees_$slot_name.csv
	
	# print markdown including links
	awk -v var="$base_url" '{$1 = "["$1"]("var"/u/"$1")"; $3 = "["$3"]("var"/t/"$3")";  print}' multiple_workshops_attendees_$slot_name.csv > multiple_workshops_attendees_$slot_name.md

done

echo "$(date) : Finished!"

