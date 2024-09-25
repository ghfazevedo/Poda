#!/bin/bash
version=0.1
# Version Log

print_message () {
  echo '
############################################
Remove Paralogs Using TreeShrink '$version'

Created by Guilherme Azevedo 2022
############################################

This program prepares the input files to run TreeShrink and remove possible paralogs from alignments and outputs a folder with alignments with paralog sequences removed.
It requires IQTREE and TreeShrink to be installed in your system. Please see http://www.iqtree.org/ and https://uym2.github.io/TreeShrink/ and cite both programs.

It takes as input a folder with alinments. gene trees will be estimated for each alignment using a GTR+F+G model. 


remove_paralogs_treeshrink.sh -I folder_with_alignments [-q TreeShrink_q -k TreeShrink_k -s TreeShrink_s  -t n_threads] 

      -I folder_with_alignments     The folder containing the aligned 
                                       fasta files.
      -q TreeShrink_q               The -q argument for TreeShrink.
                                        Default: 0.05
      -k TreeShrink_k               The -k argument for TreeShrink.
	                                    Default: none (auto-select).
	  -s TreeShrink_s       	    The -s argument for TreeShrink.
	                                    Default: '5,2' 
      -t n_threads                  Number of threads to be 
                                       used (Default:12).
      -j n_jobs               Number of jobs to be parallelized.(Default:1)
                                 Note that j*n should not exceed total number of cores.
      -h                            Print this message and exit.
'
exit
}

#Set variables and default values
folder_with_alignments=""
n_threads=12
TreeShrink_q=0.05
TreeShrink_k="" 
TreeShrink_s=""
n_jobs=1

while getopts "I:q:k:s:t:j:h" flag; do
    case "${flag}" in
            I)  folder_with_alignments=${OPTARG};;
            q)  TreeShrink_q=${OPTARG};;
            k)  TreeShrink_k=${OPTARG};;
			s)  TreeShrink_S=${OPTARG};;
			t)  n_threads=${OPTARG};;
            j)  n_jobs=${OPTARG};;			
            h)  print_message;;
            ?)  print_message;;
    esac
done

if [ "$folder_with_alignments" == "" ]
  then
     echo "The input folder with aligned fasta files needs to be specified with the flag -I"
     echo
     print_message
     exit
  else
     folder_with_alignments=$(realpath $folder_with_alignments)
	 echo "Input folder "$folder_with_alignments""
fi


if [ "$TreeShrink_k" == "" ]
  then
     echo "Using automatic selection of K"
  else
     TreeShrink_k=$(echo "-k "$TreeShrink_k)
fi

if [ "$TreeShrink_s" == "" ]
  then
     echo "Using default s or not using (if K is given)"
  else
     TreeShrink_s=$(echo "-s "$TreeShrink_s)
fi



	 [ -d $folder_with_alignments"_TreeShrink" ] && echo "A folder with TreeShrink results already exists in the output directory" && exit


mkdir -p logs
logs_path=$(realpath logs)


echo '
############################################
Remove Paralogs Using TreeShrink '$version'

Created by Guilherme Azevedo 2022
############################################

This program prepares the input files to run TreeShrink and remove possible paralogs from alignments and outputs a folder with alignments with paralog sequences removed.
It requires IQTREE and TreeShrink to be installed in your system. Please see http://www.iqtree.org/ and https://uym2.github.io/TreeShrink/ and cite both programs.

----------------------------------------------------------------------
'$(date)'

Start removing paralogs.
Gene trees will be estimated with IQTREE using a GTR+F+G substitution model.

TreeShrink will be ran with options: 
-q '$TreeShrink_q' '$TreeShrink_k' '$TreeShrink_s'

Input folder '$folder_with_alignments'


' | tee -a $logs_path/progress.txt



    cp -r $folder_with_alignments $folder_with_alignments"_TreeShrink"
    cd $folder_with_alignments"_TreeShrink"
    genelist=$(ls | cut -d. -f1)


    for i in $genelist;
      do
         mkdir $i
         fastafile=$(echo $i".fasta")
         sem --id moving --jobs $n_jobs mv $fastafile ./$i/alignment.fasta
      done
    sem --wait --id moving
    for i in $genelist;
      do
         sem --id gentreeinfer --jobs $n_jobs iqtree -s $i/alignment.fasta -m GTR+F+G -T $n_threads
      done
    sem --wait --id gentreeinfer

    cd ..
	
	run_treeshrink.py -i $folder_with_alignments"_TreeShrink" -t alignment.fasta.treefile -a alignment.fasta -q $TreeShrink_q -m per-gene $TreeShrink_k $TreeShrink_s
	
	touch shrunk_alignment_list.txt
	touch notshrunk_alignment_list.txt
	
	mkdir $folder_with_alignments"_shrunk"
    cd $folder_with_alignments"_TreeShrink"
    
	
    for i in $genelist;
      do
         cd $i
         filename=$(echo $i".fasta")
         cp output.fasta $folder_with_alignments"_shrunk"/$filename
		 shrunk=$(cat output.txt) 
		 if [ "$shrunk" != "" ]
            then
               echo $filename >> ../../shrunk_alignment_list.txt
            else
               echo $filename >> ../../notshrunk_alignment_list.txt
          fi
          
         cd ..
      done;

    cd ..

# Creating file with number of species removed per gene

echo alignment,tips_removed,total_tips,percent,remaining > treeshrink_summary_list.csv
for i in $genelist
   do
     removed=$(cat $folder_with_alignments"_TreeShrink"/$i/output.txt | wc -w)
	 total=$(grep -c ">"  $folder_with_alignments"_TreeShrink"/$i/alignment.fasta)
	 percent=$(echo "scale=4; $removed / $total" | bc)
	 remaining=$(echo "scale=4;  $total - $removed" | bc)
	 echo $i,$removed,$total,$percent,$remaining >> treeshrink_summary_list.csv
done


cd $folder_with_alignments"_TreeShrink"
touch tree_before_after.tre
touch tree_loci_map.txt
count=1
for i in $(ls -d */)
  do
    cd $i
    cat alignment.fasta.treefile output.treefile >> ../tree_before_after.tre
	echo $i,$count >> ../tree_loci_map.txt
	count=$(expr $count + 1)
    cd ..
  done
cd ..

echo "TreeShrink finished" | tee -a $logs_path/progress.txt