workflow regem_wf {

	File inputfile
	String exposure_names
	String? int_covar_names
	String? output_style = "meta"
	Int? memory = 5
	Int? cpu = 1
	Int? disk = 10
	Int? preemptible = 0

	call run_regem {
		input:
			inputfile = inputfile,
			exposure_names = exposure_names,
			int_covar_names = int_covar_names,
			output_style = output_style,
			memory = memory,
			cpu = cpu,
			disk = disk,
			preemptible = preemptible
	}

	output {
		File output_sumstats = run_regem.out
	}

	parameter_meta {
		inputfile: "Tabular output file containing summary statistics from a GEM run (must have been run using --output-style 'full')."
		exposure_names: "Name(s) of the exposures to be tested for interaction (space-delimited)."
		int_covar_names: "Name(s) of any covariates for which genotype interactions should be adjusted (space-delimited)."
		output_style: "Optional string specifying the output columns to include: minimum (marginal and GxE estimates), meta (minimum plus main G and GxCovariate terms), or full (meta plus additionals fields necessary for re-analysis based on summary statistics alone). Default is 'minimum'."
		memory: "Requested memory (in GB)."
		cpu: "Minimum number of requested cores."
		disk: "Requested disk space (in GB)."
		preemptible: "Optional number of attempts using a preemptible machine from Google Cloud prior to falling back to a standard machine (default = 0, i.e., don't use preemptible)."
	}

}

task run_regem {

	File inputfile
	String exposure_names
	String? int_covar_names
	String? output_style
	Int? memory
	Int? cpu
	Int? disk
	Int? preemptible

	command {
		dstat -c -d -m --nocolor > system_resource_usage.log &
		atop -x -P PRM | grep '(REGEM)' > process_resource_usage.log &

		/REGEM/REGEM \
			--input-file ${inputfile} \
			--exposure-names ${exposure_names} \
			${"--int-covar-names " + int_covar_names} \
			--output-style ${output_style} \
			--out regem_res
	}

	runtime {
		docker: "quay.io/large-scale-gxe-methods/regem-workflow:latest"
		memory: "${memory} GB"
		cpu: "${cpu}"
		disks: "local-disk ${disk} HDD"
		preemptible: "${preemptible}"
		gpu: false
		dx_timeout: "7D0H00M"
	}

	output {
		File out = "regem_res"
		File system_resource_usage = "system_resource_usage.log"
		File process_resource_usage = "process_resource_usage.log"
	}
}

