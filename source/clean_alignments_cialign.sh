#!/bin/bash
version=0.2
# Version Log
# Added --crop_divergent

print_message () {
  echo '
###################################
Clean Alignments with CIAlign '$version'

Created by Guilherme Azevedo 2021 
###################################

This program runs CIAlign over all aligned fasta files in a folder.
It requires CIAlign to be installed in your system. Please see https://github.com/KatyBrown/CIAlign and cite CIAlign:

Tumescheit C, Firth AE, Brown K. 2022. CIAlign: A highly customisable command line tool to clean, interpret and visualise multiple sequence alignments. PeerJ 10:e12983 https://doi.org/10.7717/peerj.12983

Usage:
clean_alignments_cialign.sh -I input_folder [-d min_diver -o output_folder -i min_insertion] 

      -A input_folder               The folder containing the fasta files 
                                       with aligned sequences.
      -d min_diver                  The threshold for the
                                       divergence below which the sequence
                                       is removed from alignment.
                                       (Default: 0.65)
      -o output_folder              The name of the output folder. 
                                      (Default: input_folder_CIAlign)
      -i min_insertion              Remove insertions which are present in
                                      less than this proportion of
                                      sequences.(Default:0.25)
      -l min_perc_length            Remove sequences which length is
                                      smaller than this percentage of
                                      total alignment length. It is a 
                                      modification of the CIAlign
                                      --remove_min_length to account for
                                      each alignment length. It should be
                                      an integer between 0 and 100. 
                                      A value of 10 will remove sequences
                                      that are 20 bases long (excluding 
                                      gaps) in an alignment of length 
                                      200b, and 100b in a alignment of 
                                      1000b. (Default:10)
      -j n_jobs                  Number of jobs to be parallelized.(Default:1)
                                       Note that j*n should not exceed total cores.	
      -h                            Print this message and exit.
'
exit
}



#Set variables and default values
input_folder=""
output_folder=""
min_diver=0.65
min_insertion=0.25
min_perc_length=10
n_jobs=1


while getopts "A:d:o:i:l:j:h" flag; do
    case "${flag}" in
            A)  input_folder=${OPTARG};;
            d)  min_diver=${OPTARG};;
            o)  output_folder=${OPTARG};;
			i)  min_insertion=${OPTARG};;
			l)  min_perc_length=${OPTARG};;
            j)  n_jobs=${OPTARG};;
            h)  print_message;;
            ?)  print_message;;
    esac
done

if [ "$input_folder" == "" ]
  then
     echo "The input folder with aligned fasta sequences needs to be specified with the flag -A"
     echo
     print_message
     exit
  else
     input_folder=$(realpath $input_folder)
	 echo "Input folder "$input_folder""
fi


if [ "$output_folder" == "" ]
  then
     output_folder=$input_folder"_CIAlign"
	 [ -d $output_folder ] && echo "A folder with cleaned alignments already exists in the output directory" && exit
	 mkdir $output_folder
	 output_folder=$(realpath $output_folder)
	 echo "Output folder "$output_folder""
  else
	 [ -d $output_folder ] && echo "A folder with cleaned alignments already exists in the output directory" && exit
	 mkdir $output_folder
	 output_folder=$(realpath $output_folder)
	 echo "Output folder "$output_folder""
fi

mkdir -p logs
logs_path=$(realpath logs)

echo '
###################################
Clean Alignments with CIAlign '$version'

Created by Guilherme Azevedo 2021 
###################################

This program runs CIAlign over all aligned fasta files in a folder.
cite CIAlign:

Tumescheit C, Firth AE, Brown K. 2022. CIAlign: A highly customisable command line tool to clean, interpret and visualise multiple sequence alignments. PeerJ 10:e12983 https://doi.org/10.7717/peerj.12983

----------------------------------------------------------------------
'$(date)'

Start CIAlign:
CIAlign --remove_divergent --remove_divergent_minperc '$min_diver' --remove_insertions --insertion_min_perc '$min_insertion' --crop_ends --remove_short --remove_min_length '$min_length' --crop_divergent --visualise

Input folder '$input_folder'
Output folder '$output_folder'

' >> $logs_path/progress.txt

file_list=$(ls $input_folder)

for file in $file_list
    do
	  echo "Cleaning alignment "$file"" >> $logs_path/progress.txt
	  seq_len=$(bioawk -c fastx '{ print length($seq) }' < $input_folder/$file | head -n 1)
	  min_length=$(expr $seq_len \* $min_perc_length / 100)
      sem --id cleaning --jobs $n_jobs /home/azevedo/azevedo/progs/CIAlign/CIAlign/CIAlign.py --infile $input_folder/$file --outfile_stem $output_folder/$file --remove_divergent --remove_divergent_minperc $min_diver --remove_insertions --insertion_min_perc $min_insertion --crop_ends  --crop_divergent --crop_divergent_min_prop_ident 0.95 --crop_divergent_min_prop_nongap 0.95 --remove_short --remove_min_length $min_length --visualise
    done	  
sem --wait --id cleaning
  
#mkdir $output_folder"_consensus"
#mv $output_folder/*_consensus.fasta $output_folder"_consensus"/
#rm $output_folder"_consensus"/*.fasta_with_consensus.fasta
#at $output_folder"_consensus"/*_consensus.fasta >> $output_folder"_consensus"/pseudo_reference.fasta
#rm $output_folder"_consensus"/*_consensus.fasta

mkdir $output_folder"_images"
mv $output_folder/*.png $output_folder"_images"/

cat $output_folder/*_log.txt >> $logs_path/CIAlign_logs.txt

rm $output_folder/*.txt

rename .fasta_cleaned.fasta .fasta $output_folder/*.*
rename .fa_cleaned.fasta .fasta $output_folder/*.*
rename .faa_cleaned.fasta .fasta $output_folder/*.*
rename .fan_cleaned.fasta .fasta $output_folder/*.*

echo 'Finished cleaning alignments.

'$(date)'
----------------------------------------------------------------------
######################################################################

' >> $logs_path/progress.txt



