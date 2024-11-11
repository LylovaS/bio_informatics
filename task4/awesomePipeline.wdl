version 1.0

workflow awesomePipeline {
	input {
		File reference
		File reads
		File checkFlagstat
	}
	
	call renameReads { input: inp = reads }
	call renameRef { input: inp = reference }
	
	call fastqcTask { input: reads = renameReads.out }
	call minimap2Task { input: ref = renameRef.out, reads = renameReads.out }
	call samtoolsTask { input: aln = bwaTask.out }
	call checkFlagstatTask { input: inp = checkFlagstat } 
	call samtoolsSortTask { input: aln = samtoolsTask.alnBam }
	call freeBayesTask { input: aln = samtoolsSortTask.out }
	
	#output {
	#	String output = checkFlagstatTask.out
	#}
}

task renameReads {	
	input {
		File inp
	}
	
	command {
		mv ${inp} reads.fastq
		#rm -f ${inp}
	}
	
	output {
		File out = "./reads.fastq"
	}
}

task renameRef {	
	input {
		File inp
	}
	
	command {
		mv ${inp} ref.fa
		#rm -f ${inp}
	}
	
	output {
		File out = "./ref.fa"
	}
}

task fastqcTask {
	input {
		File reads
	}	

	command {
		mkdir fastqc_res
		/home/karina/bioinformatics/fastqc/fastqc --extract --outdir=/home/karina/bioinformatics/fastqc_res $(reads)
	}
}

task bwaTask {
	input {
		File ref
		File reads
	}	
	
	command {
		/home/karina/bioinformatics/bwa/bwa index ${ref}
		/home/karina/bioinformatics/bwa/bwa mem -t 8 ${ref} ${reads} > ./aln.sam
#		rm ref.fa.amb ref.fa.ann ref.fa.bwt ref.fa.pac ref.fa.sa
	}
	
	output {
		File out = "./aln.sam"
	}
}

task samtoolsTask {
	input {
		File aln
	}	
	
	command {
		/home/karina/bioinformatics/samtools/bin/samtools view -b -S -h ${aln} > ./aln.bam
		/home/karina/bioinformatics/samtools/bin/samtools flagstat ./aln.bam > ./flagstat.txt
	}
	
	output {
		File alnBam = "./aln.bam"
		File flagstat = "./flagstat.txt"
	}
}

task checkFlagstatTask {
	input {
		File inp
	}
	
	command {
		mv ${inp} parseFlagstat.java
		javac parseFlagstat.java
		java parseFlagstat
	}
	
	output {
		String out = read_string(stdout())
	}
}

task samtoolsSortTask {
	input {
		File aln
	}	
	
	command {
		/home/karina/bioinformatics/samtools/bin/samtools sort ${aln} -o aln_sorted.bam
	}
	
	output {
		File out = "./aln_sorted.bam"
	}
}

task freeBayesTask {
	input {
		File aln
	}	
	
	command {
		freebayes -f ref.fa ${aln} > freebayes.vcf
	}
	
	output {
		File out = "./freebayes.vcf"
	}
}

