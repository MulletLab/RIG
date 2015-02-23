#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
import HTSeq
import numpy
from collections import defaultdict
import scipy.stats as sp
import numpy as np
from simpleodspy.sodsspreadsheet import SodsSpreadSheet
from simpleodspy.sodsods import SodsOds

LILI_TABLE = []

def usage():
    sys.stderr.write("\tvcfToRqtl.py input.vcf parent1 parent2 genInterval GQthreshold MissingnessThreshold --[keepSDCO,removeSDCO]\n")
    sys.stderr.write("\tExample usage: vcfToRqtl.py variants.vcf BTx623 Tx7000 30 0.75 --removeSDCO\n")
    sys.exit()

try:
    bool_keepSDCO = True
    str_vcfName = sys.argv[1]
    parent1 = sys.argv[2]
    parent2 = sys.argv[3]
    GENOTYPEQUALITYTHRESHOLD = float(sys.argv[4])
    MISSINGNESSTHRESHOLD = float(sys.argv[5])
    sys.stderr.write("\tvcfToRqtl\n\tMissingness threshold: %s\n" % MISSINGNESSTHRESHOLD)
    sys.stderr.write("\tGenotype Quality threshold: %s\n" % GENOTYPEQUALITYTHRESHOLD)
    vcfFile = HTSeq.VCF_Reader(str_vcfName)
    if sys.argv[6] == "--removeSDCO":
        sys.stderr.write("\tWill remove short range double crossovers\n")
        bool_keepSDCO = False
    elif sys.argv[6] == "--keepSDCO":
        sys.stderr.write("\tWill keep short range double crossovers\n")
        bool_keepSDCO = True
    else:
        usage()
except IndexError:  # Check if arguments were given
    sys.stderr.write("Insufficient arguments received. Please check your input:\n")
    usage()
except IOError:  # Check if file is unabled to be opened.
    sys.stderr.write("Cannot open target file. Please check your input:\n")
    usage()

def getColumnName(int_columnNumber):
    int_dividend = int_columnNumber
    str_columnName = ""
    int_modulo = 0
    while (int_dividend > 0):
        int_modulo = (int_dividend - 1) % 26
        str_columnName = chr(65 + int_modulo) + str_columnName
        int_dividend = (int_dividend - int_modulo) / 26
    return str_columnName

def getGenotypeFromString(genotype):
    if ((genotype[0] == "1" and genotype[2] == "0") or (genotype[0] == "0" and genotype[2] == "1")):   #Heterozygous
        return "het"
    elif genotype[0] == "0" and genotype[2] == "0":    #Homozygous Ref
        return "homoR"
    elif genotype[0] == "1" and genotype[2] == "1":    #Homozygous Alt
        return "homoA"
    elif genotype[0] == "." and genotype[2] == ".":
        return "missing"

def checkParentalGenotypes(genotypeP1, genotypeP2):
    if ((genotypeP1 == "homoR" and genotypeP2 == "homoA")
        or genotypeP1 == "homoA" and genotypeP2 == "homoR"):
        return "PASS"
    else:
        return "FAIL"

def filterGenotypes(HTSeqVar):
    intSamples = len(HTSeqVar.samples) - 2   #Subtract 2 to account for parents

    if len(HTSeqVar.alt) != 1:  #Variant is not biallelic; do not use
        return "FAIL"


    try:
        p1genotype = getGenotypeFromString(HTSeqVar.samples[parent1]['GT'])
        p2genotype = getGenotypeFromString(HTSeqVar.samples[parent2]['GT'])

        if checkParentalGenotypes(p1genotype, p2genotype) == "FAIL":   #Variant is not AA/BB marker; do not use
            return "FAIL"
        if (float(HTSeqVar.samples[parent1]['GQ']) < GENOTYPEQUALITYTHRESHOLD or   # Ensure parents pass genotyping quality threshold
            float(HTSeqVar.samples[parent2]['GQ']) < GENOTYPEQUALITYTHRESHOLD):
            return"FAIL"
    except KeyError:
        print "Parent GQ error: ", HTSeqVar
        sys.exit()

    intNumMissing = 0
    intSumGenotypes = 0

    dict_Genos = defaultdict(list)
    dict_Genos["homoR"] = 0
    dict_Genos["homoA"] = 0
    dict_Genos["het"] = 0
    dict_Genos["missing"] = 0

    HTSeqVar.samples.pop(parent1, None)   #Exclude parents to count the progeny
    HTSeqVar.samples.pop(parent2, None)   #Exclude parents to count the progeny

    #Count the number of each genotype across each sample for a given variant
    sampleList = []
    for key in sorted(variant.samples):
        sampleList.append(key)
    genotypeList = []
    genotypeList.append("aa")   # Parent 1 already determined to be homozygous
    genotypeList.append("bb")   # Parent 2 already determined to be homozygous
    for sample in sampleList:
        try:
            genotype = getGenotypeFromString(HTSeqVar.samples[sample]['GT'])
            if genotype == "missing":
                genotypeList.append("-")
                intNumMissing = intNumMissing + 1
            elif int(HTSeqVar.samples[sample]['GQ']) < GENOTYPEQUALITYTHRESHOLD:   #Ensure sample passes quality threshold; otherwise output as missing
                genotypeList.append("-")
                intNumMissing = intNumMissing + 1
            elif genotype == p1genotype:
                genotypeList.append("aa")
            elif genotype == p2genotype:
                genotypeList.append("bb")
            elif genotype == "het":
                genotypeList.append("ab")
        except KeyError:
            print "Sample GQ or GT error:", sample, HTSeqVar
            sys.exit()

    if float(intNumMissing) > (1 - float(MISSINGNESSTHRESHOLD)) * float(intSamples):   # Not genotyped in sufficient number of individuals; do not use
        return "FAIL"


    contigName = HTSeqVar.chrom.split("_")   #Deal with super contigs
    if contigName[0] == "chromosome":   # This only works assuming chromosomes are written as: "chromsome_1"
        strChromosome = contigName[1]
    else :
        strChromosome = HTSeqVar.chrom

    #Determine if SNP or Indel:
    variantType = "NULL"
    refAllele = HTSeqVar.ref
    altAllele = HTSeqVar.alt

    if len(altAllele) > 1:
        variantType = "MNV"
    if len(refAllele) > 1 or len(altAllele[0]) > 1:
        variantType = "indel"
    if len(refAllele) == 1 and len(altAllele[0]) == 1:
        variantType = "SNP"

    markerList = [strChromosome + "_" + str(HTSeqVar.pos.start) + "_" + variantType] + [strChromosome] + [str(HTSeqVar.pos.start)] + genotypeList
    LILI_TABLE.append(markerList)  #These markers and genotypes are of sufficient qualities
    return "PASS"

#End def filterGenotypes


###########
###########
###########
#Begin main

vcfFile.parse_meta()
vcfFile.make_info_dict()

boolInitialize = True

qualVariantDict = defaultdict(list)

for variant in vcfFile:
    if boolInitialize == True:
        if parent1 not in variant.samples or parent2 not in variant.samples:
            sys.stderr.write("Parent samples not identified; aborting.\n")
            sys.exit()
        header = [ "Chr_Pos(bp)", "Chromosome", "Pos(Change_to_0)" ]
        header.append(parent1)
        header.append(parent2)
        for key in sorted(variant.samples):
            if key == parent1 or key == parent2:
                    continue
            header.append(key)
        LILI_TABLE.append(header)
        boolInitialize = False

    if variant.filter != "PASS" and variant.filter != ".":
        continue
    variant.unpack_info(vcfFile.infodict)
    QualityFlag = filterGenotypes(variant)  #LILI_TABLE is modified here

#####
#####
#### Converting short range DCOs to missing
if bool_keepSDCO == False:
    INDEX_CHR = 1
    INDEX_POS = 2
    INDEX_STARTSAMPLECOL = 3
    INDEX_STARTMARKERROW = 1
    INT_DCOSIZE = 2000
    currentChr = "NULL"

    sys.stderr.write("\tConverting short DCOs to missing (less than %s bp)\n" % INT_DCOSIZE)

    for index_sample in range(INDEX_STARTSAMPLECOL, len(LILI_TABLE[INDEX_STARTMARKERROW])):
        #sys.stderr.write(LILI_TABLE[0][index_sample] + "\n")
        currentChr = "NULL"
        for index_marker in range(INDEX_STARTMARKERROW, len(LILI_TABLE)):
            if LILI_TABLE[index_marker][INDEX_CHR] != currentChr:
                #sys.stderr.write("Chr of current marker != current chr\n")
                currentChr = LILI_TABLE[index_marker][INDEX_CHR]
                continue

            #Get the previous non-missing genotype
            previousGenotype = LILI_TABLE[index_marker - 1][index_sample]
            i = 2  #Previous marker counter for missing genotypes; start at the next previous marker
            while previousGenotype == "-":
                if index_marker - i <= 0:   # Don't go out of range of the list
                    previousGenotype = "NULL"
                previousGenotype = LILI_TABLE[index_marker - i][index_sample]
                i = i + 1

            #Get the current non-missing genotype
            currentGenotype = LILI_TABLE[index_marker][index_sample]
            if currentGenotype == "-":
                continue

            #Compare the previous and current genotypes
            if previousGenotype != currentGenotype:   #Single crossover found
                #sys.stderr.write("No match; previous and current: " + previousGenotype + " " + currentGenotype + "\n")
                i = 1   #Forward marker counter
                markerDistance = 0
                bool_secondXO = False
                currentPos = LILI_TABLE[index_marker][INDEX_POS]
                while bool_secondXO == False and markerDistance <= INT_DCOSIZE:   #While a second crossover isn't found and the markers are sufficiently close
                    if index_marker + i >= len(LILI_TABLE):
                        break
                    try:
                        nextGenotype = LILI_TABLE[index_marker + i][index_sample]
                    except IndexError:
                        sys.stdout.write("Index warning on sample: " + LILI_TABLE[0][index_sample] + " at row " + str(index_marker) + "\n")
                        sys.stdout.write("Length of table is: " + str(len(LILI_TABLE)) + " and i is: " + str(i) + "\n")
                    if LILI_TABLE[index_marker + i][INDEX_CHR] != currentChr:
                        #sys.stderr.write("Found new chromosome. Breaking\n")
                        break
                    while nextGenotype == "-":   #Get the next non-missing genotype
                        i = i + 1
                        try:
                            nextGenotype = LILI_TABLE[index_marker + i][index_sample]
                        except IndexError:   #The end of the genotypes have been reached; don't consider it a DCO.
                            sys.stdout.write("Index warning on sample: " + LILI_TABLE[0][index_sample] + " at row " + str(index_marker) + "\n")
                            sys.stdout.write("Length of table is: " + str(len(LILI_TABLE)) + " and i is: " + str(i) + "\n")
                            nextGenotype = currentGenotype
                    try:
                        nextPos = LILI_TABLE[index_marker + i][INDEX_POS]
                        markerDistance = int(nextPos) - int(currentPos)
                    except IndexError:
                        markerDistance = 0  #The end of the genotypes have been reached; set marker distance to 0
                    #sys.stderr.write("Current and Next Genotype: " + currentGenotype + " " + nextGenotype + "\n")
                    if currentGenotype != nextGenotype:
                        #sys.stderr.write("Found Double Crossover Within Size Range; setting current to missing\n")
                        LILI_TABLE[index_marker][index_sample] = "-"
                        bool_secondXO = True
                    i = i + 1


#####
#####
#Write to .ods:
#Adapted from http://stackoverflow.com/questions/181596/how-to-convert-a-column-number-eg-127-into-an-excel-column-eg-aa
def GetColumnName(int_columnNumber):
    int_dividend = int_columnNumber
    str_columnName = ""
    int_modulo = 0
    while (int_dividend > 0):
        int_modulo = (int_dividend - 1) % 26
        str_columnName = chr(65 + int_modulo) + str_columnName
        int_dividend = (int_dividend - int_modulo) / 26
    return str_columnName

Sods_table = SodsSpreadSheet(len(LILI_TABLE) + 1, len(LILI_TABLE[0]) + 1)

rowsOutput = 0
for rowIndex in range(len(LILI_TABLE)):
    rowsOutput = rowsOutput + 1
    for colIndex in range(len(LILI_TABLE[rowIndex])):
        str_coordinate = GetColumnName(colIndex + 1) + str(rowIndex + 1)   #Spreadsheet is not 0 based.
        Sods_table.setValue(str_coordinate, str(LILI_TABLE[rowIndex][colIndex]))
        if LILI_TABLE[rowIndex][colIndex] == "aa":
            Sods_table.setStyle(str_coordinate, background_color= "#33ff33")
        elif LILI_TABLE[rowIndex][colIndex] == "bb":
            Sods_table.setStyle(str_coordinate, background_color= "#3399ff")
        elif LILI_TABLE[rowIndex][colIndex] == "ab":
            Sods_table.setStyle(str_coordinate, background_color= "#00ffff")

if bool_keepSDCO == False:
    str_outFile = (str_vcfName.split(".")[0]) + "_noSDCO.ods"
else:
    str_outFile = (str_vcfName.split(".")[0]) + ".ods"

sys.stderr.write("Outputting %s markers to .ods\n" % str(rowsOutput - 1))
Sods_ods = SodsOds(Sods_table)
Sods_ods.save(str_outFile)
