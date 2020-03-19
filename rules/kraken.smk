# ==================================================
# KRAKEN ANALYSIS
# ==================================================

configfile: "config.yaml"

# --------------------------------------------------
# Kraken, kmer based taxonomic id
# --------------------------------------------------

rule kraken2:
    conda:
        "../envs/environment.yaml"
    input:
        "results/rereplicated/{library}/{sample}_rerep.fasta"
    output:
        kraken_outputs = "results/kraken/outputs/{library}/{sample}.tsv",
        kraken_reports = "results/kraken/reports/{library}/{sample}.txt"
    threads:
        6
    params:
        confidence = "0.0",
        kraken_db = directory(config["kraken_db"]) # This is specified but not called in the shell command - Mike
    shell:
        "kraken2 \
        --db {params.kraken_db} {input} \
        --memory-mapping \
        --threads {threads} \
        --confidence {params.confidence} \
        --output {output.kraken_outputs} \
        --report {output.kraken_reports} \
        "

# could use --report-zero-counts if against small database
    # will add this t the config file - Mike

# #-----------------------------------------------------
# # reformat kraken output for krona
# #-----------------------------------------------------
#
# rule kraken2_reformat:
#     input:
#         "results/kraken/outputs/{library}/{sample}.tsv"
#     output:
#         "results/kraken/krona_inputs/{library}/{sample}.tsv"
#     shell:
#         "cut -f3,5 {input} > {output}"
#
#
# #-----------------------------------------------------
# # Krona, interactive html graphics of taxonomic diversity
# #-----------------------------------------------------
# # see here: https://www.gitmemory.com/issue/DerrickWood/kraken2/114/524767339
# rule kraken_to_krona:
#     conda:
#         "../envs/environment.yaml"
#     input:
#         "results/kraken/krona_inputs/{library}/{sample}.tsv"
#     output:
#         "reports/krona/kraken/{library}/{sample}.html"
#     shell:
#         "ktImportTaxonomy {input} -o {output} -t 2 -m 1 -tax data/databases/krona/"


#-----------------------------------------------------
#Krona, interactive html graphics of taxonomic diversity
#-----------------------------------------------------

rule kraken_to_krona: # see here: https://github.com/marbl/Krona/issues/117
    conda:
        "../envs/environment.yaml"
    input:
        tsv = "results/kraken/outputs/{library}/{sample}.tsv"
    output:
        "reports/krona/kraken/{library}/{sample}.html"
    params:
        db = "data/databases/krona/"
    shell:
        "ktImportTaxonomy -q 2 -t 3 {input.tsv} -o {output} -tax {params.db}"

#
#-----------------------------------------------------
# Kraken output to BIOM format
#-----------------------------------------------------

rule kraken_to_biom:
    conda:
        "../envs/environment.yaml"
    input:
        expand("results/kraken/reports/{sample.library}/{sample.sample}.txt", sample=sample.reset_index().itertuples())
    output:
        "results/kraken/{my_experiment}.biom" #my_experiment=config["my_experiment"])
    params:
        "results/kraken/reports/*/*.txt"
    shell:
        "kraken-biom \
        --max F \
        -o {output} \
        {params} \
        "


#---------------------------------------------------
# Biom convert, BIOM to tsv
#---------------------------------------------------

rule biom_convert:
    conda:
        "../envs/environment.yaml"
    input:
        expand("results/kraken/{my_experiment}.biom", my_experiment=config["my_experiment"])
    output:
        expand("results/kraken/{my_experiment}.tsv", my_experiment=config["my_experiment"])
    threads:
        6
    shell:
        "biom convert -i {input} -o {output} --to-tsv --header-key taxonomy"


#-------------------------------------------------
# biom taxonomy transformation
#-------------------------------------------------

# rule transform_biomtsv:
#     input:
#         "results/kraken/{my_experiment}.tsv"
#     output:
#         "results/kraken/{my_experiment}.trans.tsv"
#     run:
#         "
