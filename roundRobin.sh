#!/bin/bash

# Description: produce same results as run.sh, but each model is calculated 
# by training on all datasets except X and testing on X. Datasets must use 
# only the 7 time independent attributes and must be split by the 4 chosen 
# temporal thresholds.

startTime=`date +%s`

# Don't include combined, because `combined`'s train sets put together make 
# up the `combined` dataset itself, which is the test set.
datasets="camel cloudstack cocoon deeplearning hadoop hive kafka node ofbiz qpid"

mkdir -p out/roundRobin
rm out/roundRobin/*
summaryFile="out/roundRobin/summary.txt"

echo "This file contains summary statistics (precision, recall, f1, ROC) for the generated models." > $summaryFile
echo "Each section contains the ten (pd pf F1 ROC) stats calculated for each fold in 10-fold cross validation, with the dataset being cross-validated listed at the top of the section." >> $summaryFile
echo >> $summaryFile

# Divide datasets into temporal splits
echo "Dividing datasets into temporal splits..."
bash classify.sh timeIndependent
echo "...done"
echo

# Do a round-robin train/test with 9/10 entire datasets used to train J48 and the other 1/10 dataset.
for dataset in $datasets; do
    for threshold in 1 7 14 30 90; do
        testSet="${dataset}before${threshold}"
        echo
        echo "Starting run for test set $testSet"
        spaceDelimited=$(ls data/beforeclass/*before$threshold.arff | grep -v "combined" | grep -v "$testSet" )
        trains=$(tr ' ' ',' <<< $spaceDelimited) # Delimit the filenames by "," for input to J48TrainTest

        # test & train on chosen dataset 
        echo "Building model for dataset: $testSet"
        out=$(java -Xmx2048m -cp .:weka.jar J48TrainTest -r $trains -e data/beforeclass/$testSet.arff -c last)
        numbers=$(echo "$out" | grep -A 5 "Detailed" | grep "Weighted" -B 2 | grep "  0$" | awk '{print $3,$4,$2,$5,$6}')
        outFile="out/roundRobin/${dataset}before${threshold}.txt"
        echo "$out" > $outFile
        echo >> $summaryFile
        echo "$testSet" >> $summaryFile
        echo "prec  pd    pf    F1    ROC" >> $summaryFile
        echo "$numbers" >> $summaryFile

    done
done

echo
python summarizeModelPerformance.py $summaryFile
echo

endTime=`date +%s`
runtime=$((endTime-startTime))
echo "This script took $runtime seconds to run"
