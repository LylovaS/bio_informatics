#!/bin/bash
# Usage example:
# ./algorythm hg38.fa ERR12497130.fastq

ref_file=$1
ref_name=${ref_file%.fa*}
file=$2
name=${file%.fastq*}

echo "Generate fastQC report"
fastqc $file
echo "--------------------------"

echo "Indexing reference"
minimap2 -d "$ref_name.mmi" $ref_file
echo "--------------------------"        

echo "Calculate alignment"
minimap2 -a "$ref_name.mmi" $file > "$name.sam"
echo "--------------------------"

echo "Convert SAM to BAM"
samtools view -bS "$name.sam" > "$name.bam"
echo "--------------------------"

echo "Generate rating of alignment"
samtools flagstat "$name.bam" > "$name"_rating.txt
echo "--------------------------"

echo "Analyze "$name"_rating.txt"
res=$(./parsing_scrypt.sh < "$name"_rating.txt)
res=${res%.*}
re='^9[0-9]+|100'
if [[ $res =~ $re ]] ; then
    echo "OK"
else
    echo "not OK"
    exit
fi
echo "--------------------------"

echo "Generate sorted BAM"
samtools sort "$name.bam" > "$name.sorted.bam"
echo "--------------------------"

echo "Generate colling genetic variants of FreeBayes"
freebayes -f $ref_file "$name.sorted.bam" > "$name.vcf"
echo "--------------------------"
