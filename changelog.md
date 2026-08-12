# Changelog

## 2026-01-23

**v3.0.0**

Major structural expansion: four new report tables, a large genomics/AMR/public-health-action vocabulary expansion, and cleanup of several long-stale duplicate rows. Diffed against `v2.2.3` (the previous tagged release) via the real checked-out `dictionary-tables/*.csv` content at both tags, not the `firstReleased`/`lastUpdated` metadata columns alone — see the note on `iso6392B`/`iso6393`/`iso6396` below for why that distinction matters.

- **Schema changes**

  **Added tables**
  - `accessions` — links genetic sequences and other external data to repositories like ENA, GenBank, and SRA
  - `calculations` — records the calculations or data treatments applied to raw measurement values
  - `phActions` (Public Health Actions) — records public health interventions (e.g. travel advisories, mask mandates) tied to a measure or measure set
  - `polygonRelationships` — describes relationships (overlap, co-location, etc.) between polygon/sample-shed areas

  Each new table has a corresponding `attributes` table-membership triplet in `parts` (`<table>`/`<table>Required`/`<table>Order`) and a short name (`ac`, `cl`, `pha`, `por` respectively).

  **`wideNames` table**
  - Added a `Tag` column (not previously present)

- **Variable changes (breaking changes — partID renames, confirmed via exact-label match within this release)**
  - `flow` → `flowClass`
  - `time` → `timeClass`
  - `actiOn` → `actiCaseOn`
  - `gcD100` → `gcDay100k`
  - `normanNote` → `normanNotes`
  - `bacteria` → `bactFung` (label also updated: "Bacteria Class" → "Bacteria and Fungus Class")

- **Removed stale duplicate rows** (not renames — the operative partIDs below were already live well before this release)
  - `h5hema` removed, superseded by `fluH5hema` (live since v2.2.0)
  - `iavM` removed, superseded by `fluIAVm` (live since v2.2.0)
  - `n1neur` removed, superseded by `fluN1neur` (live since v2.2.0)
  - `sGene` removed, superseded by `covS` (live since v2.0.0)

- **Deprecations**
  - `outbreak` class — migrated from `measures`-based reporting into the new `phActions` table
  - `mutation` — collapsed into the `pcr`/`sequencing` classes
  - `su` (shortName), `collNumPer` (belongs in `wideNames`, not `parts`), `ntcFlag` (duplicated `ntcAmp`)
  - `iso6392B`/`iso6393`/`iso6396` formally depreciated as `parts` entries in this release — but this documents an older change, it isn't new in 3.0.0: the actual `ODM_languages.csv` header dropped these columns at **v2.2.0** (see that entry below). This release only finalizes the `parts`-table bookkeeping for a schema change that happened roughly a year and a half earlier.

- **Reactivations** (previously `depreciated`/`development` → `active`)
  - `neighborLevel`, `countryLevel`, `countyLevel`, `admRegLevel`, `stateProvLevel`, `municipalLevel` — reclassified as organization-level/sector categorical inputs rather than attributes
  - `date` — new Date data type (the previous depreciated date-related part was renamed `dateDep` to avoid colliding with it)
  - `wideSpecimenSet`, `tempSet`, `wideCompartmentSet`, `wideFractionSet`, `mutationPanel`, `Calprotectin`, `windSpeedUnitSet`, `bactMisc`, `samVol` — previously-staged parts activated in this release

- **Dictionary expansion** — 722 new partIDs, 685 new `ODM_sets.csv` membership rows (net of 21 removed)

### categories (458 new)
- `16rgs` — 16S Ribosomal Gene Sequencing
- `abricate` — ABRicate Software
- `abyss` — ABySS
- `accelNGS2Splus` — Accel-NGS 2S Plus DNA Library Kit
- `adapterRemoval` — AdapterRemoval
- `aerTank` — Aeration tank
- `aft` — Afternoon
- `afterQC` — AfterQC
- `agri` — Agricultural activity
- `agt` — Antimicrobial gradient test
- `aliView` — AliView
- `allpathsLG` — AllPaths-LG
- `amrClass` — Antimicrobial resistance (AMR) classification
- `amrFinderPlus` — AMRFinderPlus Software
- `apolloPrepX` — Apollo PrepX Library Preparation Kits
- `arachne` — ARACHNE
- `ardb` — Antibiotic Resistance Genes Database (ARDB)
- `aRegLevel` — A-Tier Region-level Aggregation at Site
- `argAnnotSoft` — ARG-ANNOT Annotation Tool
- `ariba` — ARIBA
- `articV1` — Artic V1 Primer Set
- `articV2` — Artic V2 Primer Set
- `articV41` — Artic V4.1 Primer Set
- `articV500` — Artic V5 Primer Set
- `articV510` — Artic V5.1 Primer Set
- `articV520bp1200` — Artic V5.2 Primer Set, 1200bp
- `articV520bp400` — Artic V5.2 Primer Set, 400bp
- `articV532` — Artic V5.3.2 Primer Set
- `atm` — Amies Transport Medium
- `atropos` — Atropos
- `autoInst` — Autosamplers
- `bacCul` — Bacterial culture
- `bacMet` — BacMet Database
- `bagFilt` — Bag Mediated Filtration
- `bamQC` — BamQC (from Qualimap)
- `bamUtil` — bamUtil Dedup
- `barScreen` — Bar screen
- `bayesHammer` — BayesHammer (from SPAdes)
- `bayesSmooth` — Bayesian Smoothing applied
- `bbduk` — BBDuk (from BBTools)
- `bbmap` — BBMap
- `bbmapReform` — BBMap Reformat
- `bbmapSuite` — BBMap Suite
- `bcfTools` — Bcftools
- `beast` — Bayesian Evolutionary Analysis by Sampling Trees (BEAST) Software
- `bigsdb` — BIGSdb (Bacterial Isolate Genome Sequence Database)
- `bioanalys` — Fragment analyzers or bioanalyzers
- `bioEdit` — BioEdit
- `biooSci` — Bioo Scientific NEXTflex Rapid DNA-Seq Kit
- `bioRep` — Biological replicate
- `blasr` — BLASR (Basic Local Alignment with Successive Refinement)
- `bmtagger` — BMTagger
- `borderClos` — Border closure
- `bow` — Body of water
- `bowtie2` — Bowtie2
- `bowtie2XSam` — Host Subtraction with Bowtie2 & SAMtools
- `bpw` — Buffered Peptone Water
- `bracken` — Bracken
- `bRegLevel` — B-Tier Region-level Aggregation at Site
- `builLev` — Building-level Surveillance
- `bwa` — BWA (Burrows-Wheeler Aligner)
- `bwaHost` — BWA for Host Filtering
- `bwaMEM` — BWA-MEM with Duplicate Marking
- `canal` — Canal
- `canu` — Canu
- `capFin` — CapsuleFinder
- `cardDtbase` — Comprehensive Antibiotic Resistance Database (CARD)
- `cardRGI` — CARD Resistance Gene Identifier (RGI)
- `caSmooth` — Central average smoothing applied
- `cbtm` — Cary-Blair Transport Medium
- `cdHIT` — CD-HIT
- `celera` — Celera Assembler
- `census` — Population census
- `centriInst` — Centrifuges
- `cesspit` — Cesspit
- `chemSurv` — Chemical contaminant surveillance
- `chewBBACA` — ChewBBACA
- `clark` — CLARK
- `cleanPlex` — CleanPlex DNA Library Prep Kit
- `clermonTyp` — ClermonTyping
- `clinic` — Clinic
- `clonalFrameML` — ClonalFrameML Software
- `clumpify` — BBMap’s Clumpify
- `clustalO` — Clustal Omega
- `communitLev` — Community-level Surveillance
- `communitor` — Communitor
- `contam` — Contamination
- `contMeasImp` — Control measure implementation
- `control` — Control sample
- `count` — Population count
- `countLevel` — Country-level Aggregation at Site
- `covarisTruXTRAC` — Covaris truXTRAC FFPE DNA Library Kit
- `cpp` — Critical priority pathogen
- `crassStand` — Crassphage Standarized
- `ctFinder` — CTFinder
- `cufflinks` — Cufflinks (with TopHat integration)
- `cutadapt` — Cutadapt
- `dada2` — DADA2
- `day7Smooth` — 7-day smoothing of values
- `ddbj` — DNA Data Bank of Japan (DDBJ)
- `deconSeq` — DeconSeq
- `decontaMiner` — DecontaMiner
- `decSurv` — Decreased surveillance
- `deepARG` — DeepARG Software
- `derivedSamp` — Derived sample
- `dev` — De-escalated variant
- `discovar` — DISCOVAR de novo
- `dnaPrep` — Nextera DNA Flex/DNA Prep Library Prep Kit
- `dnaRNAshield` — DNA/RNA Shield
- `domSurv` — Domestic travel hub surveillance
- `dPCRinst` — Digital PCR (dPCR) intruments
- `dra` — DDBJ sequence Read Archive (DRA)
- `drugSurv` — Drug surveillance
- `eager` — EAGER
- `easySeqNGS` — EasySeq NGS Targeted Capture Kit
- `edenV1` — Eden V1 Primer Set
- `edFac` — Educational facility
- `embossCons` — Emboss Cons
- `emergSurv` — Emergency targetted surveillance program
- `ena` — European Nucleotide Archive (ENA)
- `enaForm` — ENA Format
- `enterobase` — Enterobase archives
- `enviroInst` — Temperature and pH probes
- `estimate` — Estimated data
- `eve` — Evening
- `faFlow` — Fast-flowing
- `farm` — Farm
- `fastMLST` — FastMLST
- `fastp` — FASTP
- `fastQC` — FastQC
- `fastqScreen` — FASTQ Screen
- `fastUniq` — FastUniq
- `fastXTools` — FASTX Toolkit
- `fecContam` — Fecal-contamination
- `filtInst` — Filtration units
- `floc` — Flocculation
- `flowInst` — Flow meters
- `flowStand` — Flow Standarized
- `flye` — Flye
- `fnmiLevel` — First Nation Territory/Métis Settlement-level Aggregation at Site
- `fqtrim` — Fqtrim
- `frcBam` — FRCbam
- `gauss` — Gaussian distribution stanrdized/Normalized
- `gemMapper` — GEM Mapper
- `genBank` — GenBank Archives
- `geneious` — Geneious
- `genoTyphi` — GenoTyphi
- `gisaid` — Global Initiative on Sharing All Influenza Data (GISAID) archives
- `github` — GitHub
- `glycerol10` — 10% Glycerol Solution
- `gmap` — GMAP
- `grabInst` — Grab samplers
- `gramSt` — Gram stain
- `graphmap` — GraphMap
- `gritCham` — Grit chamber
- `growBroth` — Growth in enrichment broth
- `grWa` — Ground water
- `gsa` — Genome Sequence Archive (GSA)
- `gsnap` — GSNAP
- `gt` — Guanidine Thiocyanate
- `handHygAdv` — Hand hygiene advisory
- `hbss` — Hank's Balanced Salt Solution (HBSS)
- `hcAct` — Healthcare activity
- `hcf` — Healthcare facility
- `hisat2` — HISAT2
- `homeOrder` — Stay-at-home order
- `hpp` — High priority pathogen
- `husb` — Animal husbandry
- `hySel` — Hybrid Selection Method
- `idbaUD` — IDBA-UD
- `illuminaDNAprep` — Illumina DNA Prep with Enrichment
- `incSurv` — Increased surveillance
- `indPl` — Industrial plant
- `indus` — Industrial activity
- `infPump` — Influent pump station
- `insdc` — International Nucleotide Sequence Database Collaboration (INSDC) Archives
- `instituLev` — Institution-level Surveillance
- `internalRef` — Internal reference
- `internatSurv` — International travel hub surveillance
- `iqTree` — IQ-TREE Software
- `iVar` — iVar
- `kapaHyperPrep` — KAPA HyperPrep Kit
- `kaptive` — Kaptive
- `kneadData` — KneadData
- `kraken2` — Kraken2
- `last` — LAST (Large-Scale Alignment and Search Tool)
- `less10` — <10 people
- `less100` — 10 - 100 people
- `less100k` — 10,000 - 100,000 people
- `less10k` — 1,000 - 10,000 people
- `less1k` — 100 - 1,000 people
- `less1mil` — 100,000 -  1,000,000 people
- `libPrepInst` — Library preparation instruments
- `ligaseDep` — Ligase-Dependent Library Prep Kits
- `lineage` — LINEAGE Software
- `liquidMat` — Liquid
- `lockdown` — Lockdown
- `longSurv` — Longitudinal, repeat sampling surveillance program
- `lrs` — Lactated Ringer’s Solution
- `mafft` — MAFFT
- `magBead` — Magnetic nanobead binding
- `magInst` — Magnetic separation racks
- `mall` — Shopping mall
- `mapSplice` — MapSplice
- `mash` — mash Software
- `maskMand` — Mask mandate
- `maskRec` — Mask recommendation
- `masurca` — Maryland Super Read Celera Assembler (MaSuRCA)
- `meatPl` — Meat processing plant
- `mega` — Molecular Evolutionary Genetics Analysis (MEGA)
- `megahit` — MEGAHIT
- `megares` — MEGARes database
- `metAMOS` — MetAMOS
- `metaPhIAn` — MetaPhlAn Software
- `mgiEasy` — MGIEasy DNA Library Prep Kit
- `midnightBCCDCv1` — Midnight and BC-CDC V1 Primer Set
- `midnightBCCDCv2` — Midnight and BC-CDC V2 Primer Set
- `midnightBCCDCv3` — Midnight and BC-CDC V3 Primer Set
- `midnightBCCDCv4` — Midnight and BC-CDC V4 Primer Set
- `midnightV1` — Midnight scheme V1 Primer Set
- `midnightV2` — Midnight scheme V2 Primer Set
- `midnightV3` — Midnight scheme V3 Primer Set
- `miniasm` — Miniasm
- `minimap2` — Minimap2
- `mitoZ` — MitoZ Deduplication
- `mlst` — MLST (Center for Genomic Epidemiology)
- `more1mil` — 1,000,000+ people
- `morn` — Morning
- `mpp` — Medium priority pathogen
- `mrBayes` — MrBayes Software
- `multiComLev` — Multi-Community-level Surveillance
- `multiQC` — MultiQC
- `muniLevel` — Municipality-level Aggregation at Site
- `mykrobe` — Mykrobe
- `nac` — No amplification control
- `nanoPlot` — NanoPlot
- `ncbiForm` — NCBI Format
- `ncbiPDIB` — NCBI’s Pathogen Detection Isolates Browser
- `ncovtools` — ncov-tools
- `ndaro` — National Database of Antibiotic Resistant Organisms (NDARO)
- `nebnextUltraII` — NEBNext Ultra II DNA Library Prep Kit
- `nebVarSkipV1aLong` — New England Biolabs VarSKip V1a Long Primer Set
- `nebVarSkipV1aShort` — New England Biolabs VarSKip V1a short Primer Set
- `nebVarSkipV2a` — New England Biolabs VarSKip V2a Primer Set
- `nebVarSkipV2b` — New England Biolabs VarSKip V2b Primer Set
- `negCon` — Negative experimental control
- `neighbour` — Neighbouring relationship
- `neighLevel` — Neighbourhood-level Aggregation at Site
- `nexteraXT` — Nextera XT DNA Library Preparation Kit
- `nextstrain` — Nextstrain Software
- `ngmlr` — NGMLR (Next-Generation Mapping and Long-Read Alignment)
- `ngsInst` — Next-Generation Sequencing (NGS) platforms or intruments
- `night` — Night
- `none` — No sample storage medium used
- `norm` — Purpose is normalization
- `normalization` — Normalization Calculation Type
- `normanForm` — Norman Format
- `novoalign` — Novoalign
- `novoPlasty` — NovoPlasty
- `nrt` — MinusRT
- `ntc` — Non-template control
- `ntp` — No target present
- `nwssForm` — US-CDC NWSS Format
- `ocu` — Odour Control Unit
- `office` — Office
- `opt` — Optical calibrator sample
- `opWa` — Surface water
- `orthoFinder` — OrthoFinder Software
- `osf` — Open Science Foundation (OSF)
- `otherForm` — Other (or proprietary) Format
- `overlap` — Overlapping relationship
- `pangolinSoft` — Pangolin Software
- `pathogenwatch` — Pathogenwatch
- `patricRast` — PATRIC/RAST Database
- `pbfinder` — PBPfinder
- `pbs` — Phosphate Buffered Saline (PBS)
- `pehaplo` — PEHaplo
- `pgap` — PGAP (Prokaryotic Genome Annotation Pipeline)
- `pha4geForm` — PHA4GE Format
- `phAdvise` — Public health advisory
- `phandango` — Phandango
- `pharmPl` — Pharmaceutical manufacturing plant
- `phEmerg` — Public health emergency (outbreak)
- `phesODMFormV1` — PHES-ODM Version 1 Format
- `phesODMFormV2` — PHES-ODM Version 2 Format
- `phesODMFormV3` — PHES-ODM Version 3 Format
- `phyloPhIAn` — PhyloPhlAn Software
- `phyloSuite` — PhyloSuite Software
- `phyML` — PhyML Software
- `picard` — Picard MarkDuplicates
- `piqmie` — PIQMIe
- `piSeqQC` — PiSeqQC
- `platanus` — Platanus
- `pluDra` — Plumbing drain
- `pmmovStand` — PMMoV Standarized
- `porechop` — Porechop
- `posCon` — Positive experimental control
- `prec` — Precipitation (from solution)
- `predicted` — Predicted data
- `predictiveModels` — Predictive Modeling Calculation Type
- `preQC` — preQC (from Meraculous)
- `primClar` — Primary clarifer
- `prinseq` — PRINSEQ
- `prinseqLite` — Prinseq-lite
- `profil` — Environmental survey or profiling
- `prokka` — Prokka (with serotyping integration)
- `prokkaRoary` — Prokka + Roary Pipeline (Nextflow)
- `provLevel` — Province-level Aggregation at Site
- `pubAdm` — Public Administration
- `pubAuth` — Public Authority
- `pubMLST` — PubMLST
- `pwWg` — Peptone Water with Glycerol
- `qc3` — QC3
- `qiaSeqFX` — QIAseq FX DNA Library Kit
- `qPCRinst` — qPCR instruments (quantitative PCR)
- `qProfiler2` — qProfiler2
- `quarRec` — Quarantine recommendation
- `randomSurv` — Random sampling surveillance program
- `raw` — Raw data
- `raxML` — RaxML Software
- `redundans` — Redundans
- `refCamp` — Refugee camp
- `relNR` — Relationship Not Reported
- `res` — Reservoir
- `researchPurp` — Research purposes
- `resFinderDtbase` — ResFinder Database
- `resFinderSoft` — ResFinder Tool
- `restaurant` — Restaurant
- `rev` — Review of records
- `rnaDepl` — rRNA Depletion Method
- `rnaLater` — RNAlater
- `road` — Road
- `roadside` — Roadside
- `routSurv` — Routine surveillance
- `rsi` — Resistant strain identified
- `rtqPCRinst` — RT-qPCR intruments
- `rural` — Rural
- `salTypeFin` — SalmonellaTypeFinder
- `sampleEvent` — Sampling Event
- `samRmdup` — SAMtools rmdup
- `samTools` — SAMtools
- `schoolClos` — School closure
- `sDryer` — Sludge dryer
- `sDWwST` — Sterile Distilled Water with Sodium Thiosulfate
- `secClar` — Secondary clarifer
- `semSol` — Semi-solid
- `seqKitRmdup` — SeqKit rmdup
- `seqKitStats` — SeqKit stats
- `seqManPro` — SeqMan Pro (Lasergene)
- `seqSero2` — SeqSero2
- `seqtk` — seqtk
- `seqTyping` — SeqTyping
- `serotypeFin` — SerotypeFinder
- `shasta` — Shasta
- `shortBRED` — ShortBRED Software
- `sickle` — Sickle
- `sistr` — Salmonella In Silico Typing Resource (SISTR)
- `skewer` — Skewer
- `slFlow` — Slow-flowing
- `slur` — Slurry
- `smalt` — SMALT
- `smarterThruPLEX` — SMARTer ThruPLEX Plasma-seq Kit
- `smgm` — Skim Milk–Glycerol Medium
- `smoothing` — Smoothing Calculation Type
- `snap` — Snap
- `snapp` — SNAPP Software
- `soap2` — Soap2
- `soap3` — Soap3
- `soapDenovo` — SOAPdenovo
- `socialDist` — Social distancing measures
- `solDry` — Solid Fraction (Dry)
- `solidMat` — Solid
- `solWet` — Solid fraction (Wet)
- `sortMeRNA` — SortMeRNA
- `spades` — SPAdes
- `spectroFluoro` — Spectrophotometers or fluorometers
- `spg` — Sucrose Phosphate Glutamate (SPG) Buffer
- `spr` — Spring
- `sra` — Sequence Read Archive (SRA)
- `srst2` — SRST2 Software
- `ssake` — SSAKE
- `SSI` — Streptococcus Serotyping Tool (SSI)
- `stag` — Stagnant
- `stamp` — Statistical Analysis of Metagenomic Profiles (STAMP) Software
- `standardization` — Standardization Calculation Type
- `star` — STAR (Spliced Transcripts Alignment to a Reference)
- `starAMR` — StarAMR Software
- `std` — Standard sample
- `stormy` — Stormy Weather
- `str` — Stream
- `strainPhIAb` — StrainPhlAn Software
- `sts` — Sodium Thiosulfate Solution
- `subread` — Subread
- `subSamp` — Subsample (General)
- `suburban` — Suburban
- `sureSelectXThs2` — SureSelect XT HS2 DNA Library Preparation Kit
- `survAlert` — Surveillance alert
- `swift2STurbo` — Swift 2S Turbo DNA Library Kit
- `targetSurv` — Targeted surveillance program
- `targSurv` — Targetted surveillance initiated
- `taxonium` — Taxonium Software
- `techRep` — Technical replicate
- `thermCyc` — Thermal cyclers
- `threatDes` — Threat designation
- `thruPLEX` — ThruPLEX DNA-seq Kit
- `timeStand` — Time standardized
- `tophat` — TopHat
- `tradSero` — Traditional Serotyping methods
- `travBa` — Travel ban
- `travelSurv` — Travel hub surveillance - general
- `travWa` — Travel warning
- `treat` — Treated
- `treeTime` — TreeTime Software
- `trimGalore` — TrimGalore!
- `trimmomatic` — Trimmomatic
- `trinity` — Trinity
- `trisEDTA` — TE Buffer (Tris-EDTA)
- `truSeqDNA` — TruSeq DNA PCR-Free Library Prep Kit
- `tsb` — Tryptic Soy Broth (TSB)
- `uGene` — Ugene
- `ultraCentInst` — Ultracentrifuges
- `umiTag` — Unique Molecular Identifier (UMI) Tagging
- `umiTools` — UMI-tools
- `unicycler` — Unicycler
- `unkn` — Unknown sample
- `untreat` — Untreated
- `urban` — Urban
- `usher` — Ultrafast Sample placement on Existing tRees (UShER) Software
- `utm` — Universal Transport Medium (UTM)
- `vaxSched` — Change to Vaccine Schedule
- `velvet` — Velvet
- `viralPass` — Viral passage experiment
- `voc` — Variant of concern
- `voi` — Variant of interest
- `vtm` — Viral Transport Medium (VTM)
- `vum` — variant under monitoring
- `well` — Well
- `wms` — Whole Metagenome Sequencing
- `wSphereForm` — wSphere Format
- `wta` — Wastewater Treatment Agency
- `wtdbg2` — WTDBG (aka wtdbg2)
- `wtpo` — Wastewater Treatment Plant Operator
- `wvs` — Whole Virome Sequencing
- `wwAerDigest` — Wastewater aerobic digestion
- `wwAnaerDigest` — Wastewater anaerobic digestion
- `wwCominuated` — wastewater comminution process
- `wwDesludge` — Wastewater sludge removal
- `wwDewater` — Wastewater sludge dewatering
- `wwDry` — Wastewater sludge drying
- `wwFilt` — Wastewater filtration
- `wwGrit` — Wastewater grit removal
- `wwMic` — Wastewater microbial treatment
- `wwPriSed` — Wastewtaer primary sedimentation
- `wwScreen` — Wastewater screening process
- `wwSecSed` — Wastewater secondary sedimentation
- `wwtpAssess` — Wastewater treatment efficiency assessment
- `wwTrt` — Wastewater treatment
- `zenodo` — Zenodo

### measurements (79 new)
- `alkaline` — Alkalinity
- `ambigNs` — The number of ambiguous bases (Ns) normalized
- `ampSize` — Amplicon Size
- `c2811t` — C28311T Omicron N1 Point Mutation
- `cbod` — Carbonaceous Biochemical Oxygen Demand
- `conGenLen` — consensus genome length
- `covM` — SARS-CoV-2 M Gene target
- `covUTR5` — SARS-COV-2 5' UTR Gene target
- `depCovThresh` — depth of coverage threshold
- `detLinClade` — Detected Lineage or Clade Name
- `dissOxy` — Dissolved oxygen
- `dnaFragLen` — DNA Fragment Length
- `exoNnsp14` — SARS-CoV-2 exoN gene (nsp14)
- `extractRecov` — Extraction Recovery Percent
- `fecalCol` — Fecal coliform count
- `genComplete` — genome completeness
- `hel` — SARS-CoV-2 hel gene (nsp13)
- `kp311V` — KP.3.1.1 Variant
- `kp3V` — KP.3 Variant
- `lachno3` — Lachnospiraceae (Lachno3)
- `lb1V` — LB.1 Variant
- `lob` — Limit of Blank (LOB)
- `lp81V` — LP.8.1 Variant
- `matChar` — Sample Material Characteristics
- `mCF` — Concentration Factor
- `mESV` — Effective Sample Size/Volume
- `minPTLength` — minimum post-trimming read length
- `n50` — N50
- `nb181V` — NB.1.8.1 variant (Nimbus)
- `nBPSeq` — number of base-pairs sequenced
- `nContig` — number of contigs
- `nh3nh4` — Ammonia and Ammonium as Nitrogen
- `nsp1` — SARS-CoV-2 nsp1 Gene target
- `nsp10` — SARS-CoV-2 nsp10 Gene target
- `nsp11` — SARS-CoV-2 nsp11 Gene target
- `nsp15` — SARS-CoV-2 nsp15 Gene target
- `nsp16` — SARS-CoV-2 nsp16 Gene target
- `nsp2` — SARS-CoV-2 nsp2 Gene target
- `nsp3` — SARS-CoV-2 nsp3 Gene target
- `nsp4` — SARS-CoV-2 nsp4 Gene target
- `nsp5` — SARS-CoV-2 nsp5 Gene target
- `nsp6` — SARS-CoV-2 nsp6 Gene target
- `nsp7` — SARS-CoV-2 nsp7 Gene target
- `nsp8` — SARS-CoV-2 nsp8 Gene target
- `nsp9` — SARS-CoV-2 nsp9 Gene target
- `nTotRead` — number of total reads
- `nUniRead` — number of unique reads
- `orf10` — SARS-CoV-2 orf10 Gene target
- `orf14` — SARS-CoV-2 orf14 Gene target
- `orf3a` — SARS-CoV-2 orf3a Gene target
- `orf3b` — SARS-CoV-2 orf3b Gene target
- `orf6` — SARS-CoV-2 orf6 (ns6) Gene target
- `orf7a` — SARS-CoV-2 orf7a Gene target
- `orf7b` — SARS-CoV-2 orf7b (ns7b) Gene target
- `orf8` — SARS-CoV-2 orf8 (ns8) Gene target
- `orf9b` — SARS-CoV-2 orf9b Gene target
- `orf9c` — SARS-CoV-2 orf9c Gene target
- `orp` — Oxidation reduction potential (ORP)
- `percContam` — percent read contamination
- `percNLength` — percent Ns across total genome length
- `phagetype` — Phagetyping Results
- `popAreaType` — Populated area type
- `popDensity` — Population density
- `popServRange` — Population Served - Interval
- `precip` — Precipitation - general
- `presampAct` — presampling activity
- `preSampWeath` — Pre-sampling weather
- `rainPerc` — dPCR Rain Percentage
- `recomb` — Recombinant Lineage Variant
- `salinity` — Salinity
- `seqAssLen` — sequence assembly length
- `serovar` — Serological Variant (Serovar)
- `spikeGene` — SARS-CoV-2 Spike gene (orf2)
- `stercobilin` — Stercobilin
- `strainID` — Strain ID
- `survLevel` — Surveillance Level
- `tds` — Total Dissolved Solids (TDS)
- `urobilin` — Urobilin or urochrome
- `xecV` — XEC Variant

### units (54 new)
- `actiCaseOn` — Number of active cases by Onset date
- `bps` — Base-pairs
- `cfu100` — CFU per 100 ml
- `cfugTS` — Colony forming units per grams total solids
- `cfumL` — Colony forming units per milliliter
- `cpWell` — Gene copies per well
- `ctcq` — Cycle threshold per quantification cycle
- `fah` — Degree Fahrenheit
- `fnu` — Formazin nephelometric unit
- `foot` — Feet
- `gcDay` — Gene copies per day
- `gcDay100k` — gene copies per day per 100,000 people
- `gcMl100k` — Gene copies per millilitre per 100,000 people
- `gcRx` — Gene copies per Reaction
- `gkg` — Gram per kilogram
- `gL` — Gram per liter
- `gNgTS` — Nitrogen per total solids
- `gPergTS` — Grams per total solids
- `gPO43gTS` — Orthophosphate per total solids
- `gPO4PgTS` — Orthophosphate as phosphorus per total solids
- `inch` — Inch
- `kgm3` — Kilogram per cubic meter
- `lday` — Litres per day
- `lhour` — Liter per hour
- `lmin` — Liter per minute
- `log10gc100mL` — Log10 gene copies per 100 milliliter
- `log10gcngDNA` — Log10 gene copies per nanogram total DNA
- `lsec` — Liter per second
- `m3min` — Cubic meter per minute
- `megaB` — Mega-bases or Mega-base-pairs
- `meqL` — Milliequivalent per liter
- `meter` — Meter
- `mgLCaCO3` — Milligram per liter of calcium carbonate
- `mgPO43L` — Milligrams orthophosphate per liter
- `mgPO4PL` — Milligrams orthophosphate as phosphorus per liter
- `mmhocm` — Millimho per centimeter
- `mpn100mL` — Most probable number per 100 milliliters
- `mpnmL` — Most probable number per milliliter
- `mScm` — MilliSiemen per centimeter
- `mvolt` — MilliVolt
- `ngL` — Nanograms per liter
- `nPerKbp` — Number per 100 kilo-base-pairs
- `pcrCycles` — PCR Quanitification Cycles
- `peeps` — Number of people
- `personPerKm` — Persons for square kilometre
- `personPerMile` — Persons per square mile
- `ppt` — parts per thousand
- `psu` — Practical salinity unit
- `resPerKm` — Residents per square kilometre
- `resPerMile` — Residents per square mile
- `sm` — Siemens per meter
- `umhocm` — Micromho per centimeter
- `weeks` — Weeks
- `ww` — Weight for weight

### mmaSets (35 new)
- `actionTypeSet` — Public Health Action Type Value Set
- `allActionsSet` — All Public Health Actions Set
- `allStandardSet` — Data Adjustment Standard Value Set
- `amrClassSet` — Antimicrobial Resistance (AMR) Classification Value Set
- `amrSoftSet` — AMR Software Set
- `bactMethSet` — Bacterial testing method set
- `calcTypeSet` — Calculation type set
- `cladeAnSet` — Lineage- or Clade-analysis Software Set
- `collAppxSet` — Collection Approximate Time Period Set
- `conSeqSoftSet` — Consensus Sequence Software Set
- `contMeasImpSet` — Control Measure Implementation Value Set
- `dataRepoSet` — Data Repository Set
- `dedupSet` — Deduplication Method Set
- `dehostSet` — Dehosting Method Set
- `gteSet` — Genomic Target Enrichment Methods Set
- `libraryKitSet` — Library Preparation Kit Set
- `matCharSet` — Sample Material Characteristics Set
- `ogFormSet` — Original Data Format Set
- `phAdviseSet` — Public Health Advisory Value Set
- `polyRelSet` — Polygon Relationship Set
- `popAreaSet` — Populated area type set
- `popIntSet` — Population Interval Set
- `popMetSet` — Population assessment method set
- `presampSet` — Presampling activity category set
- `rawSeqProcSet` — Raw Sequence Data Processing Method Set
- `readMapperSet` — Sequencing read mapping software set
- `seqAssSet` — Sequence Assembly Software Set
- `seqQCSet` — Sequencing QC Pipeline Set
- `seroMethSet` — Serotyping Method Set
- `siteLevelSet` — Site Level Category Set
- `stoMedSet` — Sample Storage Medium Set
- `survAlertSet` — Surveillance Alert Value Set
- `survLevelSet` — Surveillance Level Set
- `threatDesSet` — Threat designation Value Set
- `valTreatSet` — Value treatment value set

### attributes (34 new)
- `accessIndexID` — Accessions Index ID
- `accessNum` — Accession Number in Repository
- `action` — Public health action
- `actionDT` — Public health action datetime
- `actionGrpID` — Public Health Action Group ID
- `actionType` — Public health action type
- `calcType` — Calculation Type
- `calculationID` — Calculation ID
- `collAppxT` — Collection Approximate Time Period
- `collDate` — Collection Date (time not included)
- `dataHost` — Host Data Repository or Bank
- `dateDep` — Date
- `epiWeek` — EpiWeek Number
- `epiWeekStart` — EpiWeek Start Date
- `epiYear` — Year of the EpiWeek
- `equation` — Equation
- `hostVersion` — Version of Data Hosting Platform/Repository
- `normanNotes` — NORMAN - notes
- `order` — Sequence Order
- `originalFormat` — Original Data Format
- `phActionID` — Public Health Action ID
- `pipelineID` — Pipeline ID
- `poLic` — Polygon License
- `polygonIDObject` — Polygon ID Object
- `polygonIDSubject` — Polgygon ID Subject
- `polygonRelID` — Polygon relationship ID
- `relDateEnd` — Measure relevance end date
- `relDateStart` — Measure relevance start date
- `siteLevel` — Level of Aggregation of a Sampling Site
- `sourceCode` — Source Code
- `standard` — Standard for Data Adjustment
- `threatTarget` — Public health threat targeted by action
- `treatmentID` — Treatment ID
- `valTreat` — Value Treatment

### methods (16 new)
- `amrSoft` — AMR Analysis Software
- `bactMeth` — Bacterial testing method
- `cladeAn` — Lineage- or Clade-analysis Software
- `conSeqSoft` — Consensus Sequence Software
- `dedup` — Deduplication Method
- `dehost` — Dehosting Method
- `gte` — Genomic Target Enrichment
- `libraryKit` — Library Preparation Kit
- `popAs` — Population assessment method
- `qcMethod` — Quality Control Method
- `rawSeqProc` — Raw Sequence Data Processing Method
- `readMapper` — Sequencing read mapping software name
- `seqAss` — Sequence Assembly Software
- `seqQC` — Sequencing QC Pipeline
- `seroMeth` — Serotyping Method
- `stoMed` — Sample Storage Medium

### qualityIndicators (8 new)
- `ampliArtifact` — Sequence Amplification Artifacts
- `lAGC` — Low Average Genome Coverage
- `lowCovMut` — Low Coverage of Characteristic Mutations
- `lowQualSeq` — Low-quality Sequence
- `lowSNRatio` — Low Signal-to-Noise Ratio
- `lPGC` — Low Percent of Genome Captured
- `seqContam` — Sequence Contaminated
- `shortRead` — Read Lengths Shorter Than Expected

### tableSupport (8 new)
- `accessionsOrder` — Accessions table column order
- `accessionsRequired` — Accessions table required headers
- `calculationsOrder` — Calculations table column order
- `calculationsRequired` — Calculations table required headers
- `phActionsOrder` — Public health actions table column order
- `phActionsRequired` — Public health actions table required headers
- `polygonRelationshipsOrder` — Polygon relationships table column order
- `polygonRelationshipsRequired` — Polygon relationships table required headers

### classes (6 new)
- `bactFung` — Bacteria and Fungus Class
- `database` — Database and Data Repository Class
- `flowClass` — Flow class
- `popClass` — Population Class
- `software` — Software Class
- `timeClass` — Time class

### unitSets (6 new)
- `alkalinitySet` — Alkalinity unit set
- `basePairSet` — Base-pair unit set
- `electricPotentSet` — Electrical potential unit set
- `percentUnitSet` — Percent unit set
- `popDensUnitSet` — Population density unit set
- `salinityUnitSet` — Salinity unit set

### tables (4 new)
- `accessions` — accessions Table
- `calculations` — Calculations Table
- `phActions` — Public Health Actions Report Table
- `polygonRelationships` — Polygon Relationships Table

### shortName (4 new)
- `ac` — Accessions report table Shorthand
- `cl` — Calculations Table Short Name
- `pha` — Public Health Actions Report Table Shortname
- `por` — Polygon Relationships Table Short Name

### specimenSets (3 new)
- `polySiSpecimenSet` — Polygon or site specimen set
- `polySpecimenSet` — Polygon specimen set
- `poPolySpecimenSet` — Population or polygon specimen set

### missingness (3 new)
- `dnc` — Data Not Collected
- `miss` — Missing data
- `restrict` — Restricted data

### partType (1 new)
- `shortSets` — Shorthand or Short Name Set Type

### aggregations (1 new)
- `epiMean` — EpiWeek Mean

### specimens (1 new)
- `poly` — Polygon

### groups (1 new)
- `nimbusGrp` — SARS-CoV-2 Nimbus Variant Group

## 2024-10-29

**v2.2.3**

Patch release: reverts the `v2.2.2` `parts.partLabel` → `label` rename back to `partLabel`, triggers a full mechanical regeneration of `ODM_sets.csv`, and cleans up a batch of Mpox/Chlamydia/Shigella-related partID typos and shorthand collisions.

- **Schema changes**
  - `ODM_parts.csv`: `label` column reverted back to `partLabel` — the `v2.2.2` rename was undone one patch release later
  - `ODM_sets.csv`: +735 rows added, -696 rows removed net of the same rows — reads as a full mechanical regeneration of the table (likely downstream of the `partLabel`/`label` flip-flop above) rather than a curated set of new memberships

- **Variable changes (partID renames/typo fixes, confirmed via exact-label match within this release)**
  - `Calprotectin ` (trailing space in the partID itself) → `Calprotectin`
  - `b6r` → `mpxB6R`, `c3l` → `mpxC3L`, `e9lNVAR` → `mpxe9lNVAR`, `e9lOPX3` → `mpxe9lOPX3`, `g2rG` → `mpxG2RG`, `g2rWA` → `mpxG2RWA`, `gtmolMPox` → `mpxGTmol` — Mpox gene-target partIDs normalized under a consistent `mpx`-prefixed naming scheme
  - `mpxCldIGrp` → `mpoxCldIGrp`, `mpxCldIIGrp` → `mpoxCldIIGrp` — spelled out "mpox" consistently (was inconsistent with the gene-target renames above, which kept `mpx`)
  - `chalydiaGrp` → `chlamydiaGrp`, `precipation` → `precipitation` — plain typo fixes
  - `shigellaGroup` → `shigellaGrp` — naming-convention consistency fix
  - `dictSet` → `dictSets` — aligned with the `partType`-plural naming convention used elsewhere
  - `pt` → `pro`, `sm` → `sas`, `sr` → `sar` — shorthand-code collisions resolved (all three were `shortName` entries)

- **Variable changes (non-breaking)**
  - `gcD100` label corrected: "gene copies per day per 100,000" → "gene copies per day per 100,000 people"

- **Dictionary expansion** — 65 new partIDs

### categories (25 new)
- `autoComp` — Automatic composite sampling
- `autoSeq` — Automatic sequential sampling
- `bus` — Bus
- `busStat` — Bus Station
- `ccbync40` — CC BY-NC 4.0 license
- `ccbyncsa40` — CC BY-NC-SA 4.0 license
- `compToi` — Composting toilet
- `cone` — Cone-shaped sampling
- `core` — Core sampling 
- `drain` — Sewer (drain)
- `effluNS` — Wastewater Effluent - non-specified
- `horGrb` — Horizontal grab sampling
- `landTH` — Land-based Transit Hub
- `latrine` — Latrine
- `port` — Port or Harbour
- `sludgeNS` — Wastewater Sludge - non-specified
- `tHub` — Transport hub - General
- `train` — Train
- `transp` — Transportation vehicle - general
- `trap` — Passive (trap) sampling
- `triturator` — Wastewater Triturator
- `trStat` — Train Station
- `vac` — Vacuum sludge sampling
- `vertGrb` — Vertical grab sampling
- `waterTH` — Water-based Transit Hub

### measurements (24 new)
- `Calprotectin` — Calprotectin 
- `covS` — SARS-CoV-2 S Gene Target
- `den1` — Dengue Virus Type 1
- `den2` — Dengue Virus Type 2
- `den3` — Dengue Virus Type 3
- `den4` — Dengue Virus Type 4
- `dnvE` — Dengue Virus E Gene
- `dnvNS5` — Dengue Virus NS5 Gene
- `dnvprM` — Dengue Virus prM Gene
- `fColiphage` — Male-specific (F+) coliphage - general
- `fluH5hema` — Influenza A H5 hemagglutinin gene 
- `fluIAVm` — Influenza A M gene
- `fluN1neur` — Influenza A N1 neuraminidase gene
- `mpxB6R` — Mpox B6R Gene Target
- `mpxC3L` — Clade I Mpox C3L Gene Target
- `mpxClI` — Mpox Clade I
- `mpxClII` — Mpox Clade II
- `mpxe9lNVAR` — Mpox & Orthopox E9L-NVAR Gene Target
- `mpxe9lOPX3` — Mpox & Orthopox E9L-OPX3 Gene Target
- `mpxF3L` — Mpox Clade I F3L Gene Target
- `mpxG2RG` — Mpox G2R-G Gene Target
- `mpxG2RNML` — Mpox G2R-NML Gene Target
- `mpxG2RWA` — Clade II Mpox G2R-WA Gene Target
- `mpxGTmol` — Mpox GT Molecular Gene Target

### groups (5 new)
- `chlamydiaGrp` — Chlamydia Group
- `fluGrp` — Influenza Virus General Group
- `mpoxCldIGrp` — MPox Clade I Group
- `mpoxCldIIGrp` — MPox Clade II Group
- `shigellaGrp` — Shigella Group

### shortName (3 new)
- `pro` — Protocols table Shorthand
- `sar` — Sample relationships table Shorthand
- `sas` — Sample report table Shorthand

### partType (3 new)
- `dictSets` — Dictionary set type
- `partSupport` — Part Support
- `tableSupport` — Table Support

### qualityIndicators (2 new)
- `belowLOQ` — Measured levels below LOQ
- `delayArriv` — Delayed Arrival or Prolonged Transit

### classes (1 new)
- `precipitation` — Precipitation class

### mmaSets (1 new)
- `relSet` — General Relationship Set

### nomenclatures (1 new)
- `ncbiNom` — Nomenclaturre from the NCBI

## 2024-08-01

**v2.2.2**

Patch release: temporarily renames `parts.partLabel` to `label`, drops the `shortName` column from `parts`, and introduces `ODM_sets.csv`'s `setCompID` column (populating it for the first time across all existing rows). Also cleans up a placeholder string that had ended up as a real partID.

- **Schema changes**
  - `ODM_parts.csv`: `partLabel` column renamed to `label` (reverted in `v2.2.3`, see above); `shortName` column removed
  - `ODM_sets.csv`: `setCompID` column added and backfilled for all 696 then-existing rows

- **Variable changes (renames/cleanup, confirmed via exact-label match within this release)**
  - A row whose partID literally read `"Maybe not something we're even reporting, so.. no include?"` (label: "Control-plate Flag - NTCs") was cleaned up into `ntcFlag` — clearly a maintainer's placeholder note that had been left in the `partID` column rather than a real identifier
  - `ena` → `enaMap`
  - A garbled-encoding duplicate of `ddcovN` (a corrupted non-breaking-space character in the partID, first introduced at `v2.2.0`) was cleaned up back to the plain `ddcovN` — see the `v2.2.0` and `v2.2.1` entries for the fuller trail of this recurring encoding artifact

- **Unmatched removals** (no replacement identified)
  - `popDateTypeSet`, `qualitySetID`, `setValue`

- **Variable changes (non-breaking — several `shortName` labels corrected from apparently mismatched/placeholder text)**
  - `mmaSet`: "Measure, method, or attribute" → "Measure, Method, or Attribute Set Header"
  - `po`: "Population" → "Polygon table Shorthand"
  - `si`: "Site" → "Sites table Shorthand"
  - `se`: "Standard Error" → "Sets look-up table Shorthand"
  - `ms`: "Metres per second" → "Measure set report table Shorthand"
  - `pa`: "polymerase activation" → "Parts Look-up table Shorthand"
  - `ebv`: further character-encoding corruption of "Epstein–Barr virus (EBV)" (worth a dedicated encoding cleanup pass, not fixed here)

- **Dictionary expansion** — 37 new partIDs

### categories (22 new)
- `ad` — Address table Shorthand
- `cK` — Composite Key
- `co` — Contact table Shorthand
- `cu` — Countries look-up tables Shorthand
- `ds` — Dataset table Shorthand
- `in` — Instrument table Shorthand
- `la` — Language Look-up table Shorthand
- `mes` — Measures Part-type Shorthand
- `met` — Methods part-type Shorthand
- `mr` — Measure report table Shorthand
- `or` — Organization table Shorthand
- `pAct` — polymerase activation
- `pr` — Protocol relationships table Shorthand
- `ps` — Protocol steps table Shorthand
- `pt` — Protocols table Shorthand
- `qr` — Quality reports table Shorthand
- `sm` — Sample report table Shorthand
- `sr` — Sample relationships table Shorthand
- `su` — Summary worksheet Shorthand
- `tr` — Translation look-up table Shorthand
- `wn` — Wide name table Shorthand
- `zo` — Zones look-up table Shorthand

### attributes (6 new)
- `compartmentSet` — Compartment Set Header
- `enaMap` — European Nucleotide Association
- `missingnessSet` — Missingness Set
- `qualityIndSet` — Quality Indicator Set Header
- `setCompID` — Composite Set ID
- `specimenSet` — Specimen Set Header

### specimens (2 new)
- `pop` — Population
- `sit` — Site

### measurements (2 new)
- `ddcovN` — ddcov_n sars-cov-2 gene target
- `ntcFlag` — Control-plate Flag - NTCs

### units (1 new)
- `mps` — Metres per second

### mmaSets (1 new)
- `shrtNameSet` — Short Name Set

### aggregations (1 new)
- `stEr` — Standard Error

### partType (1 new)
- `exceptions` — Exception Part Type

### dictSets (1 new)
- `templateSheetSet` — Template Sheet Set

## 2024-07-19

**v2.2.1**

Small patch release: disambiguates two similarly-named F-RNA phage measurements and continues the `ddcovN` encoding saga.

- **Variable changes (renames, confirmed via exact-label match within this release)**
  - `fRNA` ("F+ RNA coliphage") → `fRNAColi`
  - `frna` ("F-Specific RNA bacteriophages") → `fRNABact`
  - `ddcovN`'s corrupted non-breaking-space variant from `v2.2.0` reappears here under a *different* garbled encoding of the same character — the underlying data-quality issue (a stray non-ASCII byte in this partID, likely from repeated Excel open/save round-trips) is not actually fixed at this point, just re-mangled; see `v2.2.2` for where it's finally cleaned up

- **Variable changes (non-breaking)**
  - `ebv` label picks up a character-encoding corruption here: "Epstein–Barr virus (EBV)" → a mangled multi-byte variant (see `v2.2.2` for further drift)

- **Dictionary expansion** — 7 new partIDs

### measurements (5 new)
- `ddcovN¬†` — ddcov_n sars-cov-2 gene target
- `fRNABact` — F-Specific RNA bacteriophages
- `fRNAColi` — F+ RNA coliphage
- `hiaa5` — 5-hydroxyindoleacetic acid (5-HIAA)
- `para` — Paraxanthine (PARA)

### categories (1 new)
- `samConc` — Sample concentrate

### attributes (1 new)
- `coPhone` — Contact phone

## 2024-05-29

**v2.2.0**

The largest release in this backfilled range: introduces the `countries`, `zones`, and `wideNames` lookup tables, removes three columns from `ODM_languages.csv`, and adds the `translationID`/`label`/`enumeration` columns that later dictionary tooling (including several skills in this repo) assumes exist. A large AMR-surveillance and expanded-pathogen-reporting vocabulary lands alongside these schema changes.

- **Schema changes**

  **Added tables**
  - `countries` and `zones` — standardized country/subnational-zone lookup tables. Note: `ODM_countries.csv` was first committed in March 2023 with a message referencing "v2.1.0," but the actual `v2.1.0` tag's tree does not contain the file — it only appears starting at this tag. GitHub's own release notes for `v2.1.0` claim these tables shipped there; the real tagged content disagrees, so this backfill credits them to `v2.2.0` instead.
  - `wideNames` — lookup table for wide-format column-naming conventions

  **`ODM_parts.csv`**
  - Added table-membership triplets for the three new tables: `countries`/`countriesRequired`/`countriesOrder`, `zones`/`zonesRequired`/`zonesOrder`, `wideNames`/`wideNamesRequired`/`wideNamesOrder`

  **`ODM_sets.csv`**
  - `partLabel` column (and one further unnamed/blank column) removed; `label` and `enumeration` columns added — this is the origin of the `label`/`enumeration` convention this repo's `add-odm-set` skill relies on

  **`ODM_languages.csv`**
  - `iso6392B`, `iso6393`, `iso6396` columns removed ("removed from languages table to avoid duplication of identical values across columns," per the `parts`-table note eventually attached to these three column-definition entries — though that note wasn't actually stamped until `v3.0.0`, a year and a half after the real removal happened here)

  **`ODM_translations.csv`**
  - `translationID` column added — the origin of the `<lang><partID>` composite-key convention (`eng16rgs`, `fra16rgs`, etc.) this repo's `translate-odm-parts` skill depends on

- **Variable changes (breaking changes — partID renames, confirmed via exact-label match within this release)**
  - `mesureLic` → `measureLic` (typo fix)
  - `qualityID` → `qualityReportID`
  - `rsv` → `rsvMe`
  - `wMeasureID` → `wideMeasure`
  - `partLabel` → `label` — the `parts`-table row *describing* the renamed `ODM_sets.csv` column (above) was renamed to match, in the same release
  - `ddcovN` → a corrupted variant containing a non-breaking-space character — first appearance of a recurring encoding artifact that persists (and re-mangles) through `v2.2.1`, finally cleaned up at `v2.2.2`

- **Unmatched removals** (no replacement identified)
  - `conCase`, `conTest`, `meaureSetRepID`, `sampleRelID`

- **Status changes**
  - Deprecated: `countyLevel`, `countryLevel`, `stepProvenanceID`, `virusMisc`, `municipalLevel`, `stateProvLevel`, `neighborLevel`, `admRegLevel`, `uSiteMeasureID`, `aDate`, `labID`
  - Reactivated: `wat`, `uSCm`, `protein`

- **Dictionary expansion** — 472 new partIDs (largely an AMR-surveillance and expanded-pathogen/variant vocabulary — Delta/Omicron mutation gene targets, vaccine-dose categories, sequencing/bioinformatics groups)

### measurements (164 new)
- `a67vDel69Del70` — Omicron Variant a67v del69 and del70 mutations
- `acinetobacter` — Acinetobacter
- `adenovirusF40` — Adenovirus (F40/41)
- `adv40` — Adenovirus 40
- `adv41` — Adenovirus 41
- `advF41Fibre` — Adenovirus F41 Fibre Gene Target
- `alod` — Assay Limit of Detection (LOD)
- `aPhagocytophilum` — Anaplasma phagocytophilum
- `astrovirus` — Astrovirus
- `b6r` — Mpox B6R Gene Target
- `babesia` — Babesia
- `bBurgdorferi` — Borrelia burgdorferi
- `blaCMY` — Cephamycin Beta-Lactamase-Resistance gene target
- `blaCTXM1` — CTX-M Beta-Lactamase-Resistance gene target
- `blaIMP` — Impenemase (IMP) Beta-Lactamase-Resistance gene target
- `blaKPC` — Klebsiella pneumoniae Carbapenam (KPC) Beta-Lactamase-Resistance gene target
- `blaNDM` — New-Delhi Metallo- (NDM) Beta-Lactamase-Resistance gene target
- `blaOXA48` — OXA-type Beta-Lactamase-Resistance gene target
- `blaSHV` — SHV Beta-Lactamase-Resistance gene target
- `blaTEM` — TEM Beta-Lactamase-Resistance gene target
- `blaVIM` — Verone Integron-Encoded Metallo- (VIM) Beta-Lactamase-Resistance-resistance gene target
- `brucella` — Brucella
- `c3l` — Clade I Mpox C3L Gene Target
- `caff` — Caffeine
- `Calprotectin ` — Calprotectin 
- `camp` — Campylobacter
- `cAuris` — Candida auris
- `cbp` — Carbapenemase-encoding genes
- `cDiff` — Clostridium difficile
- `cDip` — Corynebacterium diphtheriae
- `centSpeed` — Centrifugation speed
- `chikv` — Chikungunya virus (CHIKV)
- `chlamydia` — Chlamydia
- `cJejuni` — Campylobacter jejuni bacteria
- `col2Frdg` — Time from collection to storage
- `colis` — Colistin resistance
- `concVol` — Sample volume after concentration
- `covN200` — SARS-CoV-2-N200
- `cPerfrigens` — Clostridium perfringens
- `crea` — Creatinine
- `cryptosporidium` — Cryptosporidium
- `cVDPV2` — Circulating vaccine-derived poliovirus type 2
- `cyNum` — Number of cycles
- `d339h` — D339H Mutation
- `ddcovN ` — ddcov_n sars-cov-2 gene target
- `del142144` — Omicron Variant 142-144 Deletion
- `del156157` — Delta Variant 156-157 Deletion
- `del3133` — Omicron Variant 142-14431-33 Deletion
- `dengue` — Dengue
- `duration` — Duration time of a method
- `e9lNVAR` — Mpox & Orthopox E9L-NVAR Gene Target
- `e9lOPX3` — Mpox & Orthopox E9L-OPX3 Gene Target
- `eaec` — Enteroaggregative Escherichia coli (EAEC)
- `ebv` — Epstein–Barr virus (EBV)
- `ehec` — Enterohemorrhagic Escherichia coli (EHEC)
- `eiec` — Enteroinvasive Escherichia coli (EIEC)
- `enterovirus` — Enterovirus
- `epec` — Enteropathogenic Escherichia coli (EPEC)
- `esbl` — ESBL-encoding genes
- `etec` — Enterotoxigenic Escherichia coli (ETEC)
- `expec` — Extraintestinal pathogenic Escherichia coli (ExPEC)
- `f456l` — F456L Mutation
- `fDNA` — F+ DNA coliphage
- `finVol` — Final volume
- `flirtV` — FLiRT Variants
- `fluA` — Influenza A virus
- `fluA1A2c` — Influenza virus A1 and A2 combined
- `fRNA` — F+ RNA coliphage
- `fTularensis` — Francisella tularensis
- `g2rG` — Mpox G2R-G Gene Target
- `g2rWA` — Clade II Mpox G2R-WA Gene Target
- `gtmolMPox` — Mpox GT Molecular Gene Target
- `h5hema` — Influenza A H5 hemagglutinin gene
- `h5n1` — H5N1 avian influenza A virus (IAV)
- `hDucreyi` — Haemophilus ducreyi
- `hepA` — Hepatitis A
- `hepB` — Hepatitis B
- `hepC` — Hepatitis C
- `hepE` — Hepatitis E
- `hf183` — HF183 Bacteriodes 16S
- `hInfluenzae` — Haemophilus influenzae
- `hiv` — Human Immunodeficiency Virus (HIV)
- `hMe` — See Header for Measure
- `hmpv` — Human Metapneumovirus (HMPV) 
- `hpiv` — Human Parainfluenza Virus (HPIV)
- `hpv` — Human Papiloma Virus (HPV)
- `hrv` — Human Rhinovirus (HRV)
- `hrvA` — Human Rhinovirus (HRV) A
- `hrvB` — Human Rhinovirus (HRV) B
- `hrvC` — Human Rhinovirus (HRV) C
- `hsv` — Herpes Simplex Virus
- `iavM` — Influenza A M gene
- `ibu` — Ibuprofen
- `indusIn` — Industrial input
- `influEqui` — Influent equilibration
- `ins214epe` — Omicron Variant ins214epe Insertion
- `integraseCl1` — Integrase Class I gene target
- `jn17V` — JN.1.7 Variant
- `jn1V` — JN.1 Variant
- `klebsiellaPneu` — Klebsiella pneumoniae
- `kp11V` — KP.1.1 Variant
- `kp1V` — KP.1 Variant
- `kp2V` — KP.2 Variant
- `l24s` — Omicron Variant l24s mutation
- `l455s` — L455S Mutation
- `legionella` — Legionella
- `listeria` — Listeria
- `lppa24s` — Omicron Variant LPPA24S mutation
- `mcr11` — MCR-1.1 Colistin-resistence gene target
- `measles` — Measles
- `mGenitalus` — Mycoplasma genitalus
- `mlod` — Method Limit of Detection (LOD)
- `mpox` — Mpox
- `mrsa` — Methicillin-resistant Staphylococcus aureus (MRSA)
- `mTuberculosis` — Mycobacterium tuberculosis
- `mumps` — Mumps
- `n1neur` — Influenza A N1 neuraminidase gene
- `nGonorrhoeae` — Neisseria gonorrhoeae
- `noro` — Norovirus
- `numNTC` — Number of NTCs per Run
- `p13L` — Omicron Variant p13l mutation
- `plasmodium` — Plasmodium
- `preConcTemp` — Storage temperature prior to concentration
- `preConcTime` — Storage time prior to concentration
- `preExtractTemp` — Storage temperature prior to extraction
- `preExtractTime` — Storage time prior to extraction
- `pseudomonas` — Pseudomonas
- `pv2` — Poliovirus type 2
- `r346t` — R346T Mutation
- `rickettsia` — Rickettsia
- `rnaseP` — Ribonuclease P (RNase P)
- `rotavirus` — Rotavirus
- `rsvAB` — Respiratory syncytial virus A and B combined
- `rsvAMe` — Respiratory syncytial virus A
- `rsvB` — Respiratory syncytial virus B
- `rsvMe` — Respiratory syncytial virus
- `rsvN` — RSV N-gene
- `rubella` — Rubella
- `salmonella` — Salmonella
- `samVol` — Sample volume
- `sapovirus` — Sapovirus
- `sewEq` — Sewage equivalent
- `sewTrTi` — Sewage travel time
- `shaker` — Shaker aggitation speed
- `shigella` — Shigella
- `slod` — Sample Limit of Detection (LOD)
- `spikeConc` — Spike Concentration
- `stec` — Shiga-toxin-producing Escheria coli (STEC)
- `strepPneu` — Streptococcus pneumoniae
- `suc` — Sucralose
- `tetW` — TetW Tetracycline-resistance gene target
- `tPallidum` — Treponema pallidum
- `tVaginalis` — Trichomonas vaginalis
- `ureaplasma` — Ureaplasma
- `v1104l` — V1104L Mutation
- `vanAA` — VanA-A Vancomycin-resistance gene target
- `vanc` — Vancomycin resistance
- `varicella` — Varicella
- `vibrio` — Vibrio
- `vtec` — Verotoxin-producing Escherichia coli (VTEC)
- `westNile` — West Nile
- `wt214` — Delta Variant wt214 gene target
- `yEnterocolitica` — Yersinia enterocolitica
- `zika` — Zika

### categories (105 new)
- `afl30` — Academic Free License v3.0
- `agpl30` — GNU Affero General Public License v3.0
- `anneal` — annealing/extension
- `apache20` — Apache license 2.0
- `artistic20` — Artistic license 2.0
- `bact16sABIFor` — Bacteroides 16S forward primer (HF183) (ABI)
- `bact16sABIProbe` — Bacteroides 16S probe (BacP234) (ABI)
- `bact16sABIRev` — Bacteroides 16S reverse primer (BacR287) (ABI)
- `bcovGen` — bcov spike target (unspecified)
- `bsd0` — BSD Zero-Clause license
- `bsd2Clause` — BSD 2-clause "Simplified" license
- `bsd3Clause` — BSD 3-clause "New" or "Revised" license
- `bsd3ClauseClear` — BSD 3-clause Clear license
- `bsd4Clause` — BSD 4-clause "Original" or "Old" license
- `bsl10` — Boost Software License 1.0
- `cc010` — Creative Commons Zero v1.0 Universal
- `ccby40` — Creative Commons Attribution 4.0
- `ccbysa40` — Creative Commons Attribution ShareAlike 4.0
- `cdcCovEIDTFor` — Sarbeco_E forward primer (IDT)
- `cdcCovEIDTProbe` — Sarbeco_E probe (IDT)
- `cdcCovEIDTRev` — Sarbeco_E reverse primer (IDT)
- `cdcCovN1IDTFor` — 2019-nCoV_N1 forward primer (IDT)
- `cdcCovN1IDTProbe` — 2019-nCoV_N1 probe (IDT)
- `cdcCovN1IDTRev` — 2019-nCoV_N1 reverse primer (IDT)
- `cdcCovN2IDTFor` — 2019-nCoV_N2 forward primer (IDT)
- `cdcCovN2IDTProbe` — 2019-nCoV_N2 probe (IDT)
- `cdcCovN2IDTRev` — 2019-nCoV_N2 reverse primer (IDT)
- `cdcCovN3IDTFor` — 2019-nCoV_N3 forward primer (IDT)
- `cdcCovN3IDTProbe` — 2019-nCoV_N3 probe (IDT)
- `cdcCovN3IDTRev` — 2019-nCoV_N3 reverse primer (IDT)
- `cecill21` — CeCILL Free Software License Agreement v2.1
- `commFacOth` — Commercial facility - not specified
- `dataColl` — Data collection sector or organization
- `ddpcr` — Digital Droplet PCR (ddPCR)
- `denat` — denaturation
- `dna` — DNA Template
- `dpcr` — Digital PCR (dPCR)
- `ecl20` — Educational Community License v2.0
- `eluate` — Eluate/Resuspended filter material retained
- `elutionBuff` — Elution buffer
- `epl10` — Eclipse Public License 1.0
- `epl20` — Eclipse Public License 2.0
- `esp` — exclusions based sample preparation (ESP)
- `eupl11` — European Union Public License 1.1
- `eupl12` — European Union Public License 1.2
- `gfdl13` — GNU Free Documentation License v1.3
- `gpl20` — GNU General Public License v2.0
- `gpl30` — GNU General Public License v3.0
- `hFr` — See Header for Fraction Analyzed
- `isc` — ISC
- `lgpl21` — GNU Lesser General Public License v2.1
- `lgpl30` — GNU Lesser General Public License v3.0
- `liquid` — Liquid/Supernatant retained
- `lppl13c` — LaTeX Project Public License v1.3c
- `luminWWExtract` — luminultra wastewater extraction kit
- `manComp` — Manual Composite Sample
- `memMgCl3` — membrane filtration with addition of mgcl3
- `mhvSpike` — murine hepatitis virus (MHV) spike target
- `mit` — MIT
- `mit0` — MIT No Attribution
- `monarchRNA` — monarch total RNA miniprep kit (new england biolabs) + onestep PCR inhibitor removal kit (zymo)
- `mpl20` — Mozilla Public License 2.0
- `mspl` — Microsoft Public License
- `mulanPSL20` — Mulan Permissive Software License, Version 2
- `ncsa` — University of Illinois/NCSA Open Source License
- `noRain` — No rain
- `noSep` — No Seperation or Concentration
- `nucKingfish` — nucleomag (ref. 744220.4) using kingfisher automated instrument
- `ofl11` — SIL Open Font License 1.1
- `open` — Open license not otherwise described
- `osl30` — Open Software License 3.0
- `pa` — polymerase activation
- `parapoxSpike` — Parapoxvirus Orf Virus Spike Target
- `passiveGen` — Passive Sample - General
- `pmmvABIFor` — PMMV forward primer (ABI)
- `pmmvABIProbe` — PMMV probe (ABI)
- `pmmvABIRev` — PMMV reverse primer (ABI)
- `policy` — Policy and political sector or organization
- `postgreSQL` — PostgreSQL License
- `private` — Private data - not for disemination
- `promegaLVTNA` — promega wastewater large volume tna capture kit
- `qiAllprep` — qiagen allprep dna/rna kit
- `qiampDSP` — qiagen qiaamp dsp viral rna mini kit
- `research` — Research sector or organization
- `rna` — RNA Template
- `rt` — reverse transcription
- `sciencellRNA` — sciencell viral rna isolation kit
- `serDil` — serial dillution
- `sinProbeOne` — Singleplex, probe-based, one-step RT-qPCR
- `solid` — Solids/Pellet retained
- `thermMagmax` — thermo magmax viral/pathogen nucleic acid isolation kit
- `trizolEtOH` — trizol, garnet bead beating, alcohol precipitation
- `trizolRNA` — trizol and RNA purification kit
- `unlicense` — The Unlicense
- `utilities` — Utilities sector or organization
- `vsv` — Vesicular stomatitis virus (VSV) target
- `vsvABIFor` — VSV forward primer (ABI)
- `vsvABIProbe` — VSV probe (ABI)
- `vsvABIRev` — VSV reverse primer (ABI)
- `watConcBuff` — water concentrating buffer (R2042-1)
- `wtfpl` — Do What The F*ck You Want To Public License
- `zlib` — zLib License
- `zymo1035` — zymo quick-rna viral kit #r1035
- `zymo1041` — zymo quick-rna viral 96 kit #r1041
- `zymoWatRNA` — zymo environ water rna kit/ zymo environ water rna kit (cat. r2042)

### groups (78 new)
- `acinetobacterGrp` — Acinetobacter Group
- `adenovirusGrp` — Adenovirus Group
- `amrGrp` — Anti-microbial resistance Group
- `anaplasmaGrp` — Anaplasma Group
- `astrovirusGrp` — Astrovirus Group
- `babesiaGrp` — Babesia or Nuttallia Group
- `bacteroidesGrp` — Bacteroides Group
- `betaCoronaGrp` — Beta Coronavirus Group
- `bLacAMRGrp` — Beta-Lactamase Anti-microbial resistance Group
- `borreliaGrp` — Borrelia burgdorferi or Lyme Disease Group
- `brucellaGrp` — Brucella Group
- `campGrp` — Campylobacter Group
- `cAurisGrp` — Candida auris Group
- `chalydiaGrp` — Chlamydia Group
- `chikungunyaGrp` — Chikungunya Group
- `clostridiumGrp` — Clostridium Group
- `colAMRGrp` — Colistin Anti-microbial resistance group
- `cryptosporidiumGrp` — Cryptosporidium Group
- `deltaGrp` — SARS-CoV-2 Delta Variant Group
- `diptheriaGrp` — Diphtheria Group
- `ecoliGrp` — Escherichia coli group
- `enterovirusGrp` — Enterovirus Group
- `flavivirusGrp` — Flavivirus (West Nile, Dengue, Zika) Group
- `flirtSLipGrp` — FLiRT/SLip Variant Group
- `fluAGrp` — Influenza A Virus Group
- `fluBGrp` — Influenza B Virus Group
- `gonococcusGrp` — Gonococcus Group
- `haemophilusGrp` — Haemophilus Group
- `hepGrp` — Hepatitis Group
- `herpesGrp` — Herpes Virus Group
- `hivGrp` — HIV Group
- `hrvGrp` — Rhinovirus Group
- `intAMRGrp` — Integrase Anti-microbial resistance Group
- `klebsiellaGrp` — Klebsiella Group
- `legionellaGrp` — Legionella Group
- `lentiGrp` — Lentivirus Group
- `listeriaGrp` — Listeria Group
- `malariaGrp` — Plasmodium or Malaria Group
- `measlesGrp` — Measles Group
- `metaboliteGrp` — Metabolite Group
- `mpoxGrp` — MPox Group
- `mpvGrp` — Metapneumovirus Group
- `mpxCldIGrp` — MPox Clade I Group
- `mpxCldIIGrp` — MPox Clade II Group
- `mumpsGrp` — Mumps Group
- `mycoplasmaGrp` — Mycoplasma Group
- `noroGIGrp` — Norovirus GI Group
- `noroGIIGrp` — Norovirus GII Group
- `noroGrp` — Norovirus Group
- `omicronGrp` — SARS-CoV-2 Omicron Variant Group
- `orthoGrp` — Orthopox Virus Group
- `papilomavirusGrp` — Papilomavirus Group
- `parafluGrp` — Parainfluenza Group
- `phageGrp` — Bacteriophage Group
- `pmmovGrp` — PMMoV Group
- `polioGrp` — Poliovirus Group
- `pseudomonasGrp` — Pseudomonas Group
- `rickettsiaGrp` — Rickettsia Group
- `rotavirusGrp` — Rotavirus Group
- `rsvGrp` — Respiratory syncytial virus (RSV) Group
- `rubellaGrp` — Rubella Group
- `salmonellaGrp` — Salmonella Group
- `sapovirusGrp` — Sapovirus Group
- `shigellaGroup` — Shigella Group
- `staphGrp` — Staphylococcus Group
- `strepGrp` — Streptococcus Group
- `tetAMRGrp` — Tetracycline Anti-microbial resistance Group
- `treponemaGrp` — Treponema Group
- `trichomonasGrp` — Trichomonas Group
- `tuberculosisGrp` — Tuberculosis Group
- `tularemiaGrp` — Francisella tularensis (tularemia) Group
- `ureaplasmaGrp` — Ureaplasma
- `vanAMRGrp` — Vancomycin Anti-microbial resistance Group
- `varicellaGrp` — Varicella Group
- `vibrioGrp` — Vibrio Group
- `vsvGrp` — Vesicular Stomatitis Virus (VSV) Group
- `waterQualityGrp` — Water Quality Group
- `yersiniaGrp` — Yersinia Group

### attributes (52 new)
- `aggregationInput` — Aggregation input (wide table)
- `aggregationName` — Aggregation name (wide table)
- `attributeInput` — Attribute input (wide table)
- `attributeName` — Attribute name (wide table)
- `capitalEndonym` — Capital city endonym
- `capitalExonym` — Capital city exonym
- `charLength` — character length
- `compartmentInput` — Compartment input (wide table)
- `compartmentName` — Compartment name (wide table)
- `countryEndonym` — Country endonym
- `countryExonym` — Country exonym
- `enumeration` — Enumeration for set values
- `fractionInput` — Fraction input (wide table)
- `fractionName` — Fraction name (wide table)
- `healthRegion` — Health Region for a Site
- `isoCode` — ISO 3166-1 alpha-2 country code
- `isoCodeX` — ISO 3166-1 alpha-3 country code
- `isoZone` — ISO 3166-2 code for country sub-domain
- `langScript` — National language script
- `measureInput` — Measure input (wide table)
- `measureLic` — Measure license
- `measureName` — Measure name (wide table)
- `measureSetRepID` — Measure set report set ID
- `methodInput` — Method input (wide table)
- `methodName` — Method name (wide table)
- `nameEngl` — English name for countries
- `nameOfficial` — Official state name
- `numCode` — ISO 3166-1 numeric country code
- `partTypeInput` — Part type input (wide table)
- `partTypeName` — Part type name (wide table)
- `protocolRelationshipsID` — Synthetic ID for the protocolRelationships table
- `qualityReportID` — Quality report ID
- `relationshipID` — Relationship between entities
- `reportTableInput` — Report table input (wide table)
- `reportTableName` — Report table name (wide table)
- `sampleRelationshipsID` — Synthetic ID for the sampleRelationships table
- `source` — Wide name source
- `sovereignty` — Sovereign status of a country
- `specimenInput` — Specimen input (wide table)
- `specimenName` — Specimen name (wide table)
- `tld` — Country code top-level domain
- `translationID` — Synthetic ID for the translations table
- `unitInput` — Unit input (wide table)
- `unitName` — Unit name (wide table)
- `utc` — Coordinated universal time (UTC) zone
- `utcDST` — Coordinated universal time (UTC) zone in daylight savings
- `wideAttribute` — Specified attribute (wide table)
- `wideMeasure` — Measure identification (wide table)
- `wideName` — Wide Name
- `wideNameType` — Wide name type
- `wideProtocol` — Specified protocol (wide table)
- `zoneName` — English name of country sub-domains

### units (34 new)
- `actiEp` — Number of active cases by episode date
- `actiOn` — Number of active cases by Onset date
- `actiRep` — Number of active cases by Report date
- `actiTest` — Number of active cases by test date
- `caseEpDate` — Episode date of confirmed cases 
- `caseOnDate` — Onset date of confirmed cases 
- `caseRepDate` — Report date of confirmed cases 
- `caseTestDate` — Test date of confirmed cases 
- `confRep` — Number of confirmed cases by report date
- `confTest` — Number of confirmed cases test date
- `gc` — Gene copies
- `hUn` — See Header for Unit
- `log10cpG` — log10 gene copies per g
- `log10cpL` — log10 gene copies per L
- `log10cpml` — log10 gene copies per mL
- `log10ugG` — log10 micrograms per g
- `log10ugL` — log10 micrograms per L
- `nM` — Nano-molar
- `rpm` — Revolutions per minute (RPM)
- `seconds` — Seconds
- `ugG` — Micrograms per gram
- `ugL` — Micrograms per litre
- `ugmg` — Micrograms per milligram
- `uL` — Micro-litres
- `vax1p` — Proportion of population with 1+ vaccine dose(s)
- `vax1plus` — Population with 1+ dose(s) of vaccine
- `vax2p` — Proportion of population with 2+ vaccine doses
- `vax2plus` — Population with 2+ or more doses of vaccine
- `vax3p` — Proportion of population with 3+ vaccine doses
- `vax3plus` — Population with 3+ or more doses of vaccine
- `vax4` — Population with 4 or more doses of vaccine
- `vax4p` — Proportion of population with 4+ vaccine doses
- `vax4plus` — Population with 4+ or more doses of vaccine
- `xg` — Relative Centrifugal Force (RCF) or x g units

### methods (7 new)
- `extBlank` — Extraction Blank - Control
- `pasteur` — Pasteurized sample
- `pcrAct` — PCR Action/Activity
- `resuspension` — Resuspension method
- `retainedElement` — Retained Element
- `stdCurveMet` — Standard Curve Calculation Method
- `tempType` — Nucelic Acid Template Type

### mmaSets (7 new)
- `licSet` — Data license set
- `pcrActSet` — PCR action/activity set
- `resusSet` — Resuspension method set
- `retElSet` — Retained Element Set
- `stdCurveSet` — Standard Curve Calculation Set
- `tempSet` — Template Set
- `wideFractionSet` — Fraction set for wide names

### tableSupport (6 new)
- `countriesOrder` — Countries table column order
- `countriesRequired` — Counries table required headers
- `wideNamesOrder` — Wide name table order
- `wideNamesRequired` — Wide name table required
- `zonesOrder` — Zones table column order
- `zonesRequired` — Zones table required headers

### aggregations (4 new)
- `hAg` — See Header for Aggregation
- `se` — Standard Error
- `sum14` — Rolling sum of previous 14 days
- `total` — Total amount or count - the sum

### qualityIndicators (4 new)
- `beLOD` — Below LOD
- `ntcAmp` — NTC Amplification Detected
- `oor` — Value out of range
- `out` — Value is an outlier

### tables (2 new)
- `countries` — Countries look-up tables
- `zones` — Zones look-up table

### dictSets (1 new)
- `airportSheetSet` — Airport Sheets Set

### compartments (1 new)
- `hCo` — See Header for Compartment 

### compartmentSets (1 new)
- `wideCompartmentSet` — Compartment set for wide names

### partSupport (1 new)
- `label` — Label

### specimens (1 new)
- `hSp` — See Header for Specimen

### classes (1 new)
- `organism` — Organism

### dictionarySupport (1 new)
- `airportTemplate` — Airport Surveillance Template

### unitSets (1 new)
- `speedUnitSet` — Speed Unit Set

### specimenSets (1 new)
- `wideSpecimenSet` — Speciment set for wide names

## 2023-05-31

**v2.1.0**

No dictionary content changes — confirmed via a direct `git diff` of `dictionary-tables/` between `v2.0.0` and `v2.1.0` (zero lines differ). This tag's changes are documentation/ERD housekeeping only: regenerated the release PDF, bumped the version string in `README.md`, and added the `v2.0.0` ERD image.

Note: GitHub's release notes for this tag claim new `countries`/`zones` lookup tables were added here. The actual tagged tree doesn't support that — `ODM_countries.csv`/`ODM_zones.csv` don't exist at this tag at all. See the `v2.2.0` entry below for where those tables actually land.

## 2021-09-15

**v2.0**

Addresses issues: [#172](https://github.com/Big-Life-Lab/ODM/issues/172), [#120](https://github.com/Big-Life-Lab/ODM/issues/120)

- **Schema changes**

  **Removed tables**
  - The `WWMeasure`, `SiteMeasure`and `CovidPublicHealthData`tables are . The values they contained are migrating to the new `Value`table (see below).

  **Added tables**
  - The `Value` table is added to store values stemming from a `measure`s.
  - The `Measure` table store metadata that fully classify and define a measurement type. This new table is supported by satellite tables that carry further information about the classification of measure and its properties:
    - The `Domain` table stores domain classifications for measures (Biological chemical, physical)
    - The `Specimen` table defines all possible `measure` to parent system relationships (measure in wastewater sample, measure from site, measure from polygon, etc.)
    - The `MeasureGroup` lists names given to groups of measure related to a common substance of interest (e.g., covid-19).
    - The `MeasureClass` list types of measures performed via similar protocols (e.g., allele counts, or nitrogen concentration).
    - The `Units` table stores all possible units used to report measurement values.
    - The `Scale` table stores the different cardinalities that can be assigned to units (quantitative, qualitative, etc.)
    - The `Aggregation` table stores the different types of aggregations that could be applied to a measurement before reporting. 
  - The `Assay` table describes unique experimental procedures that yield measure values.

  - The many-to-many relationship tables `AssayHasInstrument`, `MeasureClassHasUnits`, and `UnitHasAggregtation` have also been added.

  **Removed variables**
  
  The following variables were removed from the schema. Users are encourages to store default values in a configuration file
  - `Sample` Table
    - `sampleTypeOtherDefault`
    - `sampleCollectionDefault`
    - `sampleCollectOtherDefault`
    - `sampleStorageTempCDefault`
    - `measureFractionAnalyzedDefault`
  - `Reporter` Table
    - `siteIDDefault`
    - `labIDDefault
  - `Lab` Table
    - assayMethodIDDefault

  

## 2021-08-09 (update this date when merging to main)

\*\*v1....

**Variable changes (non-breaking changes)**

- `index`: Change type from integer to string. Allows greter flexiblity for naming indexes.


## 2021-02-18

**v1.1.0**

Addresses issues: #59, #84, #90, #92, #93, #96, #97, #99, #101, #102, #103, #104, #106, #112, #113, #114, #116.

- **Variable name changes (breaking changes :bangbang:)**

  - `extractionVolMl`: Change from `sampleSizeL`. Description of the variable was also changed.
  - `sampleTypeDefault`: Change from `SampleTypeDefault`. Now consistent use of lowercase first letter.
  - `sampleTypeOtherDefault`: Change from `SampleTypeOtherDefault`.
  - `sampleCollectionDefault`: Change from `SampleCollectionDefault`.
  - `sampleCollectOtherDefault`: Change from `SampleCollectOtherDefault`.
  - `sampleStorageTempCDefault`: Change from `SampleStorageTempCDefault`.
  - `measureFractionAnalyzedDefault`: Change from `MeasureFractionAnalyzedDefault`.

- **New variables**

- Reporter

  - `organization`: Organization of reporter. Issue [#97](https://github.com/Big-Life-Lab/covid-19-wastewater/issues/97)

- Sample

  - `reporterID`: Reporter ID. Currently, reporterID is `WWmeasure` table but reporter for samples can be different. Issue [#93](https://github.com/Big-Life-Lab/covid-19-wastewater/issues/93)
  - `index`: Index number in case the sample was taken multiple times. Issue [#103](https://github.com/Big-Life-Lab/covid-19-wastewater/issues/103)
  - `InstrumentID`: Links with the Instrument table to describe the instrument used for sampling. Issue [#104](https://github.com/Big-Life-Lab/covid-19-wastewater/issues/104)

- Site

  - `publicHealthDepartment`: Public health department or region. The public health department or region where the site or institute is located. See also `healthRegion` if there is a separate regional health care delivery authority. Issue [#116](https://github.com/Big-Life-Lab/covid-19-wastewater/issues/116)
  - `healthRegion`: Health planning region. The health planning authority where is site or insititute is located. See also `publicHealthDepartment`. Issue [#116](https://github.com/Big-Life-Lab/covid-19-wastewater/issues/116)

- SiteMeasure
  - `SampleID`: Makes sure that samples can easily be linked back to the site measurements, without the need for comparing dates. In case that multiple samples need to be linked to the same site measurement, create a comma separated list of sample IDs.
- **Deleted variable categories (breaking changes :bangbang:)**

  - `SiteMeasure` table, `aggregation` variable, all of the options that included normalization
    - `sdNr`,"Standard deviation, normalized",L'�cart type normalis�
    - `geoMnNr`,"Geometric mean, normalized",Moyenne g�om�trique normalis�e.
    - `meanNr`,"Arithmetic mean, normalized",Moyenne arithm�tique normalis�e.

- **New variable categories**

  - Categories added to allow variant reporting. See `WWMeasure` table, `type` variable:

    - `varB117`: Variant B.1.1.7
    - `varB1351`: Variant B.1.351
    - `varP1`: Variant P.1

  - Updated description of `WWMeasure` table, `unit` measure. These descriptions now reference gene or variant copies.
  - New `detected`: Gene copies or variant detected in the sampleGene or variant copies. Detected = 1. Gene or variant copiesNot detected = 0.
  - New `propVar`: Proportion of variant in sample.
  - `SiteMeasure` table, `type` variable
    - `wwBOD5t`, 5 day total biochemical oxygen demand
    - `wwBOD5c`, 5 day carbonaceous biochemical oxygen demand
    - `wwPtot`, Total phosphates
    - `wwPP`, Total phosphorous
    - ,
  - New `dailyAvg`: Average value taken over a 24h period, in the `SiteMeasure` table, `aggregation` variable
  - The `SiteMeasure` table now has a categorical `unit` variable with the following options

    - `°C`, Degrees Celcius
    - `mm`, Millimeters
    - `m3/h`, Cubic meters per hour
    - `m3/d`, Cubic meters per day
    - `mg/L`, Milligrams per liter
    - `pH`, pH units
    - `uS/cm`, Micro-siemens per centimeter

- **Migrate .md files for tables**

  - Variable and variable categories to CSV files. Please modify the appropriate CSV file for future updates. `metadata.md` is now automatically generated from the CSV files.

    - `Tables.csv`: list of tables.
    - `Variables.csv`: list of variables.
    - `VariableCategories`: list of categories for variables.

- **Other**
  - Missing values for the `value` field in the different tables should be reported using the following notation 'NA', and ideally follow with a note that explains why the value is missing. An example: Every day a daily average flow measurement is generated, yet because of fouling the instrument stopped functioning for one day which makes that this data is missing.
  - SQL template updated to reflect v1.1.0 (and also v1.0.0). These files are now automatically generated from the metadata tables (above). The SQL tables are in SQLite format.
  - Several small grammatical errors corrected in the English variable descriptions.

## 2021-02-15

Metadata migrated to:

- `Tables.csv`: List of all tables.
- `Variables.csv`: List of all variables.
- `VariableCategory.csv`: List of all cteogies within variables.

Modify these tables for future additions and changes. `metadata.md` is automatically generated from `metadata_template.md`.

## 2021-01-26

**v1.0.0 - Many additions and breaking changes. This version is recommended for widespread use.**

- Naming conventions were further developed. Category names shortened to 7 digits to allow wide variable names up to 31 characters.

- Three NEW tables

  - [SiteMeasure](metadata.md#sitemeasure): The site of wastewater sampling, including several defaults that can be used to populate new samples upon creation. SiteMeasure complements the [WWMeasure](metadata.md#wwmeasure) table. It includes measures that are commonly collected by staff at wastewater treatment facilities and field sample locations. Whereas WWMeasure includes measures that are commonly generated by wastewater testing laboratories.
  - [Inststrument](metadata.md#instrument): Instruments that are used for measurements in SiteMeasure and WWMeasure. Note that the assay method itself for viral measurement is described in [AssayMethod](metadata.md#assaymethod).
  - [Lookup](metadata.md#lookup): Reference for categorical variables.

- Names of variables were updated according to the extended naming conventions. Note that these changes are NOT listed here!

- Examples are provided on how to generate wide and long variables and category names.

- Information on how to collaborate is updated.

- Measurement metadata

  - `aggregation` - Following the existing options, one more option was added to the list `geoMeanNormal`.

- [SiteMeasure](metadata.md#sitemeasure) variables:

  - `ID`: (NEW) Unique identifier for each contextual measurement.
  - `SiteID`: (NEW) Links with the Site table to describe the location of measurement.
  - `dateTime`: (NEW) The date and time the measurement was performed.
  - `type`: (NEW) The type of measurement that was performed.
  - `typeOther`: (NEW) Description of the measurement in case it is not listed in type.
  - `typeDescription`: (NEW) Additional information on the performed measurement.
  - `name`: (NEW) Name of the instrument used to perform the measurement.
  - `type`: (NEW) Type of instrument used to perform the measurement.
  - `typeOther`: (NEW) Description of the instrument in case it is not listed in instrumentType.
  - `aggregation`: (NEW) When reporting an aggregate measurement, this field describes the method used.
  - `aggregationOther`: (NEW) Description for other type of aggregation not listed in aggregation.
  - `aggregationDescription`: (NEW) Information on OR reference to which measurements that were included to calculate the aggregated measurement that is being reported.
  - `value`: (NEW) The actual value that is being reported for this measurement.
  - `unit`: (NEW) The engineering unit of the measurement.
  - `qualityFlag`: (NEW) Does the reporter suspect quality issues with the value of this measurement? (Boolean)
  - `notes`: (NEW) Any additional notes.

- [Sample](metadata.md#sample) variables

  - `samplingTempC`: (NEW) Temperature that the sample is stored at while it is being sampled. This field is mainly relevant for composite samples which are either kept at ambient temperature or refrigerated while being sampled.
  - `mailedOnIce`: (NEW) Was the sample kept cool while being sent to the lab? (Boolean)
  - `category` - A distinction is now made between SARS-CoV-2 gene measurements `covid` and the measurement of water quality parameters on the sample `wq`.

- [Site](metadata.md#site) variables

  - `type` - Additional site types were added `airplane`, `correctionalFacility`, `elementarySchool`, `hospital`, `longTermCareFacility`, `sewageTruck`, `universityCampus`, `WWTP`
  - `accessType`: (NEW) Access point of where the sample was collected at the site.
  - `measurement.fractionAnalyzedDefault`: (NEW) Used as default when a new measurement is created for this site. See `fractionAnalyzed` in `Measurement` table.

- [AssayMethod](metadata.md#assaymethod): New variables were introduced to replace `assayDesc`, those are

  - `methodConcentration`: (NEW) Description of the method used to concentrate the sample
  - `methodExtraction`: (NEW) Description of the method used to extract the sample
  - `methodPcr`: (NEW) Description of the PCR method used
  - `qualityAssuranceQC`: (NEW) Description of the quality control steps taken
  - `inhibition`: (NEW) Description of the inhibition parameters.
  - `surrogateRecovery`: (NEW) Description of the surrogate recovery for this method.
  - `description`: (NEW) Description of the assay.
  - `referenceLink`: (NEW) Link to standard operating procedure (assay reference method)

- [CovidPublicHealthData](metadata.md#covidpublichealthdata)

  - `valueType`: (NEW) A categorical variable that replaces the individual variables, instead it provides listed options: `confirmed`, `active`, `tests`, `positiveTests`, `percentPositivityRate`, `hospitalCensus`, `hospitalAdmit`.

## 2021-01-08

- All variable names were updated according to the name convention.

## 2020-11-25

- Change date formatting on `wastewater_virus.csv` to YYYY-MM-DD.

## 2020-11-25

**v0.1.1 - Additions to metadata. No breaking changes.**

- Measurement metadata

  - Add categories `measurementType`:

    - `geoMean`: GeoMean of results
    - `rangeLowestValue`: Lowest value in a range of values
    - `rangeHighestValue`: Highest value in a range of values
    - `singleton`: This value is not an aggregate measurement in any way, and thus is not a `mean`, `median`, `geomean` or other

  - Add `measureValueDetected`: Boolean Value if True then covid-19 was detected.

  - Add `reportDate`: Note use of `reportDate` when historic results are updated for new reporting standards.

- AssayMethod metadata

  - Add `sampleSizeL`: Size of the sample that is analysed in liters
  - Add `loq`: Limit of Quantification for this method if one exists
  - Add `lod`: Limit of detection for this method if one exists
  - Add `inhibition`: Text decription of the inhibition
  - Add `surrogateRecovery`: Text description of the Surrogate Recovery for this method

- Other small corrections to metadata category labels.

- CovidPublicHealthData

  - `dateType`: Type of date used.

- Updated `wastewater_virus.csv` to reflect metadata v0.1.1.

## 2020-11-17

v0.1.0 - Breaking changes to metadata.

- Assay method database added.
- Change test results to be represented as key:values. Each test result has a measurement type (`measureType`) with a corresponding value (`measureValue`). For example a measureType is `mean` and the corresponding `measureValue` has the mean value.

## 2020-11-16

- `wastewater_virus.csv` dataset updated to remove adjustment for percent viral recovery from solids. The adjustment allign reporting with other laboratories. The adjustment reduces N1 and N2 values a maginitude of 10 (approximately).

## 2020-10-29

- Replace invalid values (such as \#DIV/0) with `NA`.

## 2020-10-27

V0.0.2 - Breaking changes to metadata.

- Change `locationID` to `siteID`.
- Change `locationName` to `siteName`.

## 2020-10-16

- All Ottawa data points prior to Oct 2nd have been slightly modified to normalize data for a new centrifuge that is being used to collect wastewater samples at the Ottawa site.

## 2020-10-09

V0.0.1 - Initial variable names and labels.
