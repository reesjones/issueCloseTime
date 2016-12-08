#!/bin/bash

# Reclassify the datasets in data/ into datasets with only "before n" timeclass and
# "after n" time class.
# Does not modify/delete data/<dataset name>.arff

# A file containing the timeclass frequency data for each dataset.
# The script populates this as the <dataset>before<i>.arff files are generated

cd data
rm beforeclass/*.arff

for file in $(ls $1/*.arff); do
    datasetName=$(head $file -n 1 | awk '{print $2}' | cut -d- -f1 | cut -d\' -f2)
	for i in 1 7 14 30 90; do
        # filename of the generated beforeclass
        beforeClassFile="beforeclass/"$datasetName"before"${i}".arff"
		python ../reclass.py $file $beforeClassFile $i
	done
done
