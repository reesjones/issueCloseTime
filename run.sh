#!/bin/bash

############################
# EXPERIMENTAL CONFIGURATION
# Change the following variables to set up the experiment.

# Specify if CFS subset selection should be performed
doCfs=true
# Number of runs of cross validation
runs=1
# Number of folds of cross validation
xvalFolds=10

# doSmote=false and smoteAll=<anything> will smote none
# doSmote=true and smoteAll=true will smote everything
# doSmote=true and smoteAll=false will smote conditionally
doSMOTE=false
smoteAll=false

# END EXPERIMENTAL CONFIGURATION
################################

startTime=`date +%s`

mkdir -p tmp data/featuresSelected data/timeIndependent out out/CFS out/noCFS
rm data/featuresSelected/*

# Print some experimental setup info
if [ $doCfs = true ]; then
    echo "Will do CFS subset selection"
else
    echo "Will **NOT** do CFS subset selection"
fi
if [ $doSMOTE = true ]; then
    echo "Will do SMOTE"
else
    echo "Will **NOT** do SMOTE"
fi

echo "Will build trees with $runs runs and $xvalFolds folds of cross-validation"

# The directory name of the output (out/{CFS or noCFS})
categoryFolder=$([ $doCfs = true ] && echo "CFS" || echo "noCFS")
# summaryFile contains model perf for each run and each fold of cross-validation
summaryFile=out/${categoryFolder}/summary.txt
# resultsFile contains the ascii results table
resultsFile=out/${categoryFolder}/results.txt
# Remove any previous results
rm out/$categoryFolder/*

echo "This file contains summary statistics (precision, recall, pf, f1, ROC) for the generated models." > $summaryFile
echo "Each section contains the ten (prec pd pf F1 ROC) stats calculated for each fold in 10-fold cross validation, with the dataset being cross-validated listed at the top of the section." >> $summaryFile
echo >> $summaryFile

# 1. Take each dataset in data/timeIndependent and either filter it with CFS and move it to data/featuresSelected, or skip CFS and move it to data/featuresSelected (depending on config at the top of this script)
for file in data/timeIndependent/*.arff; do
    datasetName=$(head $file -n 1 | awk '{print $2}' | cut -d- -f1 | cut -d\' -f2)
    if [ $doCfs = true ]; then
        featuresToKeep=$(java -cp weka.jar -Xmx2048m weka.attributeSelection.CfsSubsetEval -i $file -s weka.attributeSelection.BestFirst -c last | grep "Selected attributes" | awk '{print $3}')
        featuresToKeep="$featuresToKeep,last" # The `last` feature is timeopen, keep it
        echo "dataset $datasetName: Keeping features $featuresToKeep"

        # Remove the useless attributes and put in data/featuresSelected/camel.arff
        # -V says "keep instead of remove those features"
        #echo "Removing attributes from $datasetName that CFS found unuseful"
        java -cp weka.jar weka.filters.unsupervised.attribute.Remove -R $featuresToKeep -V -i $file -o data/featuresSelected/$datasetName.arff -c last
    else
        echo "copying $file to data/featuresSelected/$datasetName.arff"
        cp $file data/featuresSelected/$datasetName.arff
    fi
done

# This splits datasets up into before/after thresholds:
# for(dataset in data/featuresSelected):
#     make 5 new datasets for classifying an issue as closing before 1, 7, 14, 30, and 90 days
#     Transform each instance in the dataset by replacing the timeopen value with `0` if the issue closes before N days (n=1, 7, 14, 30, or 90) and `N` if it closes at or after N days
echo "Splitting datasets into binary time classes (in data/beforeclass/*before*.arff)"
bash classify.sh featuresSelected

# For each before/after prediction, build a model to make the prediction
for file in data/beforeclass/*.arff; do
    nLinesInFile=$(wc -l < $file)
    echo "Running $file with $nLinesInFile lines through preprocessors"

    datasetName=$(echo $file | cut -d/ -f3 | cut -d. -f1)
    # number of attributes
    nAttributes=$(cat $file | grep "@attribute" | wc -l)
    # number of lines in file before the actual data
    nHeaderLines=$(expr $nAttributes + 6)
    # Number of instances in dataset
	nInstancesInFile=$((nLinesInFile-nHeaderLines))
    # Pruning parameter for J48
    MVAL=$((nInstancesInFile/25))
    # Results file to put weka J48 output
	outfile=${file%.arff}
	outfile=${outfile##*/}
    outfile=out/${categoryFolder}/${outfile}.txt

    # Number of issues closing before the time threshold
    beforeInstances=$(cat $file | grep ",0$" | wc -l)
    # Number of issues closing at or after the time threshold
    afterInstances=$(expr $nInstancesInFile - $beforeInstances)
    beforeIsMinorityClass=$(($beforeInstances < $afterInstances))
    minorityInstances=$([ "$beforeIsMinorityClass" = 1 ] && echo "$beforeInstances" || echo "$afterInstances")
    majorityInstances=$([ "$beforeIsMinorityClass" = 1 ] && echo "$afterInstances" || echo "$beforeInstances")
    ratio=$(bc <<< "scale=5; $minorityInstances/$nInstancesInFile")
    # We defined balanced as minority : majority ratio to be no less than 1/4
    classesAreBalanced=$(bc <<< "$ratio>0.25")

    # This either SMOTEs the dataset and puts it in tmp/smoted.arff, or skips SMOTEing and moves it to tmp/smoted.arff
    if [ $doSMOTE = true ]; then
        # Only run SMOTE when classes are unbalanced or config specifies to SMOTE everything
        if [ "$classesAreBalanced" -eq "0" ] || [ "$smoteAll" = true ]; then
            smoteRate=$(bc <<< "scale=5; 100*$majorityInstances/(4*$minorityInstances) - 1")
            if [ $(bc <<< "$smoteRate <= 0") -eq 1 ]; then 
                smoteRate="100.0"
            fi
            # useLegacyMergeSort is required because of a bug in either Weka or openjdk8
	        java -cp weka.jar -Djava.util.Arrays.useLegacyMergeSort=true -Xmx1024m weka.filters.supervised.instance.SMOTE -C 0 -K 5 -P $smoteRate -S 1 -c last -i $file -o tmp/smoted.arff
	        echo "SMOTEd $file - oversampled minority class by $smoteRate%"
            # Update values dependent on nInstancesInFile
            nLinesInFile=`wc -l < tmp/smoted.arff`
            nInstancesInFile=$((nLinesInFile-nHeaderLines))
            beforeInstances=$(cat tmp/smoted.arff | grep ",0$" | wc -l)
            afterInstances=$(expr $nInstancesInFile - $beforeInstances)
            minorityInstances=$([ "$beforeIsMinorityClass" = 1 ] && echo "$beforeInstances" || echo "$afterInstances")
            majorityInstances=$([ "$beforeIsMinorityClass" = 1 ] && echo "$afterInstances" || echo "$beforeInstances")
        else
            echo "Didn't SMOTE on $file because classes are balanced"
            # So the next step in the pipeline can find its input
            cp $file tmp/smoted.arff
        fi
    else
        echo "Skipping SMOTE"
        cp $file tmp/smoted.arff
    fi

	echo "Decision tree pruning parameter M = $MVAL"

    # First, build the model and write it to the outfile
	java -cp weka.jar -Xmx1024m weka.classifiers.trees.J48 -t tmp/smoted.arff -C 0.25 -M $MVAL -x 10 > ${outfile}
    # Then, do 10-fold crossval and append the results of the crossval to the outfile and summaryfile
    crossval="$(java -cp ".:weka.jar" CrossValidationMultipleRuns -t $file -c last -r $runs -x $xvalFolds -s 1 -W "weka.classifiers.trees.J48 -C 0.25 -M $MVAL")"
    numbers=$(echo "$crossval" | grep "Weighted" -B 2 | grep "  0$" | awk '{print $3,$4,$2,$5,$6}')
    echo >> ${outfile}
    echo "=== Cross validation results ===" >> ${outfile}
    echo >> ${outfile}
    echo "prec  pd    pf    F1    ROC" >> ${outfile}
    echo "$numbers" >> ${outfile}
	printf "$datasetName\nprec  pd    pf    F1    ROC\n$numbers\n\n" >> $summaryFile
	echo "Done with $datasetName"
	echo ""
done

echo "Summarizing model performance:"
echo
results=$(python summarizeModelPerformance.py $summaryFile)
echo "$results"
echo "$results" > $resultsFile
echo

endTime=`date +%s`
runtime=$((endTime-startTime))
echo "This script took $runtime seconds to run"

echo "ALL DONE"

