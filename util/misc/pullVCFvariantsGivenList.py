#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
from collections import defaultdict

def usage():
    sys.stderr.write("\tpullVCFvariantsGivenList.py vcfFile.vcf variantFile.tsv\n")
    sys.stderr.write("\tExample usage: pullVCFvariantsGivenList.py variants.vcf markerList.tsv 2\n")
    sys.stderr.write("\tThis assumes chromosome and super contig IDs of the format \"chromosome_\" and \"super\" in the first column of a tsv.")
    sys.exit()

try:
    li_tsv = [line.strip() for line in open(sys.argv[2])]
    li_tsv = [element.split() for element in li_tsv]
    str_vcf = sys.argv[1]
except IndexError:  # Check if arguments were given
    sys.stderr.write("No arguments received. Please check your input:\n")
    usage()
except IOError:  # Check if file is unabled to be opened.
    sys.stderr.write("Cannot open target file. Please check your input:\n")
    usage()

def pullVariants():
    dict_chrPos = defaultdict(list)

    for i in range(len(li_tsv)):
        if i == 0:   #Skipping the header line
            continue
        try:
            li_contigPos = li_tsv[i][0].split("_")
            if li_contigPos[0] == "super":
                contig = "super_" + li_contigPos[1]
                position = li_contigPos[2]
            else:
                contig = "chromosome_" + li_contigPos[0]
                position = li_contigPos[1]
            coordKey = contig + "_" + position
            dict_chrPos[coordKey].append(1)
        except ValueError:
            sys.stderr.write("Value error\n")
    #print dict_chrPos

    file_vcf = open(str_vcf, 'r')
    for line in file_vcf:
        if line[0] == "#":
            sys.stdout.write(line)
        else:
            li_variantInfo = line.split("\t")
            str_variantInfo = li_variantInfo[0] + "_" + li_variantInfo[1]
            if str_variantInfo in dict_chrPos:
                sys.stdout.write(line)

#begin main
pullVariants()
