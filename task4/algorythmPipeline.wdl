version 1.0

workflow algorythmPipeline {
	input {
		File reference
		File file
		File parse_scrypt
	}
	
	call fastqcTask { input: reads_file = file }
	call minimap2Task { input: ref_file = reference, reads_file = file }
	call samtoolsTask1 { input: aln = minimap2Task.out }
	call samtoolsTask2 { input: aln = samtoolsTask1.alnBam }
	call parseFlagstatTask { input: rating = samtoolsTask2.flagstat, scrypt = parse_scrypt }
	if (parseFlagstatTask.out < 90.0) {
		call echoTaskNOT_OK
	} 
	if (parseFlagstatTask.out >= 90.0) {
		call echoTaskOK
		call samtoolsSortTask { input: aln = samtoolsTask1.alnBam }
		call freeBayesTask { input: aln = samtoolsSortTask.out, reference = reference }
	}
	
}

task echoTaskOK {
	command {
		echo "OK"
	}

	output {
		File out = stdout()
	}
}

task echoTaskNOT_OK {
	command {
		echo "NOT OK"
	}

	output {
		File out = stdout()
	}
}

task fastqcTask {
	input {
		File reads_file
	}	

	command {
		fastqc ${reads_file}
	}
}


task minimap2Task {
	input {
		File ref_file
		File reads_file
	}	
	
	command {
		minimap2 -d ref.mmi ${ref_file}
		minimap2 -a "ref.mmi" ${reads_file} > aln.sam
	}
	
	output {
		File out = "aln.sam"
	}
}

task samtoolsTask1 {
	input {
		File aln
	}	
	
	command {
		samtools view -bS ${aln} > aln.bam
	}
	
	output {
		File alnBam = "aln.bam"
	}
}

task samtoolsTask2 {
	input {
		File aln
	}	
	
	command {
		samtools flagstat ${aln} > rating.txt
	}
	
	output {
		File flagstat = "rating.txt"
	}
}

task parseFlagstatTask {
	input {
		File rating
		File scrypt
	}
	
	command {
		${scrypt} < ${rating}
	}
	
	output {
		Float out = read_string(stdout())
	}
}

task samtoolsSortTask {
	input {
		File aln
	}	
	
	command {
		samtools sort ${aln} -o aln_sorted.bam
	}
	
	output {
		File out = "./aln_sorted.bam"
	}
}

task freeBayesTask {
	input {
		File reference
		File aln
	}	
	
	command {
		freebayes -f ${reference} ${aln} > freebayes.vcf
	}
	
	output {
		File out = "./freebayes.vcf"
	}
}

