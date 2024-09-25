#!/bin/bash

screen_for_long_branches () {
    output="$1""_check_alignments.txt"
    [ -f "$output" ] && echo "Output file exists" && exit
    touch "$output"
    out_path=$(realpath "$output")
    echo "Checking trees for long branches" | tee -a logs/progress.txt
    folders=$(ls -d "$1"/*)
    for i in $folders
       do
         if [ "$(find_long_branches.py -t $i/output.treefile -p 0.5)" == "Check" ]
            then 
              echo $i | cut -f2 -d"/" >> $out_path
         fi
    done
    
	folder_with_alignments_to_check="$2""_to_check"
	mkdir $folder_with_alignments_to_check
	
	while read -r line
	    do
		  sem --id copyjob --jobs +0 cp "$2"/$line".fasta" $folder_with_alignments_to_check/$line".fasta"
	    done < $out_path
	sem --wait --id copyjob

    cp -r "$2" "$2""_OK"
	while read -r line
	    do
		  sem --id removejob --jobs +0 rm "$2""_OK"/$line".fasta"
	    done < $out_path
	sem --wait --id removejob
}

screen_for_long_branches "$1" "$2"

#"$1" is the folder with the tree shrink outputs
#"$2" is the folder with the shrunk alignments





