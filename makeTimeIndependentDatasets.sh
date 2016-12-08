#!/bin/bash

# Filters datasets in data/*.arff to only contain time-independent attributes
#
# Input: datasets in data/*.arff
#
# Output: datasets in data/timeIndependent/, filtered to include no time-dependent features


rm data/timeIndependent/*

for file in data/*.arff; do
    datasetName=$(head $file -n 1 | awk '{print $2}')
    timeIndependentFeatures="1,6,8,10,11,12,13,last"
    # Put only time independent features in data/timeIndependent/
    java -cp weka.jar weka.filters.unsupervised.attribute.Remove -V -R $timeIndependentFeatures -i $file -o data/timeIndependent/$datasetName.arff -c last
    echo "$datasetName filtered with only time independent features in data/timeIndependent/$datasetName.arff"
done
