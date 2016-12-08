import weka.classifiers.trees.J48;
import weka.core.Attribute;
import weka.core.Instance;
import weka.core.Instances;
import weka.core.converters.ConverterUtils.DataSource;
import weka.core.Utils;
import weka.classifiers.Classifier;
import weka.classifiers.Evaluation;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Random;

/**
 * Performs a single run of cross-validation.
 *
 * Command-line parameters:
 * <ul>
 *    <li>-r filename - the tRain dataset(s), separated by ","</li>
 *    <li>-e filename - the tEst dataset</li>
 *    <li>-s int - the seed for the random number generator</li>
 *    <li>-c int - the class index, "first" and "last" are accepted as well;
 *    "last" is used by default</li>
 *    <li>-W classifier - classname and options, enclosed by double quotes; 
 *    the classifier to cross-validate</li>
 * </ul>
 *
 * Example command-line:
 * <pre>
 * java J48TrainTest -r train1.arff,train2.arff -e test.arff -c last -W "weka.classifiers.trees.J48 -C 0.25"
 * </pre>
 *
 * @author reesjones (mwreesjo at NCSU dot edu)
 */
public class J48TrainTest {

    private static List<Instances> getTrainSets(String[] args) throws Exception {
        List<String> filenames = Arrays.asList(Utils.getOption("r", args).split(","));
        if(filenames.size() == 0) {
            throw new IllegalArgumentException("Must provide at least one train set");
        }
        List<Instances> trains = new ArrayList<>(filenames.size());
        for(String ds : filenames) {
            trains.add(DataSource.read(ds));
        }
        int classIndex = getClassIndex(args, trains.get(0).numAttributes());
        for(Instances set : trains) {
            set.setClassIndex(classIndex);
        }
        return trains;
    }

    private static Instances getTestSet(String[] args) throws Exception {
        String filename = Utils.getOption("e", args);
        Instances test = DataSource.read(filename);
        test.setClassIndex(getClassIndex(args, test.numAttributes()));
        return test;
    }

    private static int getClassIndex(String[] args, int numAttributes) throws Exception {
        String classIndexString = Utils.getOption("c", args);
        int classIndex;
        if(classIndexString == null) {
            classIndex = numAttributes - 1;
        } else if(classIndexString.equals("first")) {
            classIndex = 0;
        } else if(classIndexString.equals("last")) {
            classIndex = numAttributes - 1;
        } else {
            try {
                classIndex = Integer.parseInt(classIndexString) - 1;
            } catch(NumberFormatException e) {
                classIndex = numAttributes - 1;
            }
        }
        return classIndex;
    }

    /**
     * Performs the cross-validation. See Javadoc of class for information
     * on command-line parameters.
     *
     * @param args        the command-line parameters
     * @throws Exception if something goes wrong
    */
    public static void main(String[] args) throws Exception {
        // loads data
        Instances test = getTestSet(args);
        List<Instances> trains = getTrainSets(args);

        Evaluation eval = new Evaluation(test);

        // Build big train set
        Instances bigTrain = trains.get(0);
        if (trains.size() > 1) {
            for(int i = 1; i < trains.size(); i++) {
                Instances set = trains.get(i);
                DataSource ds = new DataSource(set);
                while(ds.hasMoreElements(set)) {
                    bigTrain.add(ds.nextElement(set));
                }
            }
        }
        // Build classifier
        J48 j48 = new J48();
        int mval = bigTrain.numInstances()/25;
        String[] options = {"-C 0.25", "-x 10"};
        j48.setOptions(options);
        j48.setMinNumObj(mval);
        j48.buildClassifier(bigTrain);
        eval.evaluateModel(j48, bigTrain);

        // output evaluation
        System.out.println("=== Setup ===");
        System.out.println("Classifier: " + j48.getClass().getName() + " " + Utils.joinOptions(j48.getOptions()));
        System.out.println("Testing Dataset: " + test.relationName());
        System.out.println();
        System.out.println(j48.toString());
        System.out.println();
        System.out.println(eval.toSummaryString("=== Evaluation summary string ===", false));
        System.out.println();
        System.out.println(eval.toClassDetailsString());
    }
}

