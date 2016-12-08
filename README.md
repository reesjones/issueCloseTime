# Issue close time: datasets + prediction classifiers
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.197111.svg)](https://doi.org/10.5281/zenodo.197111)

*Authors*: [Matt Martin](https://github.com/mjmartin23), [Mitch Rees-Jones](https://github.com/reesjones/)

This repository contains data science experiments for predicting time required to close issue reports ("issue close time").

# Datasets
There are 10 issue lifetime datasets located in `data/`. They were extracted from 10 large open source software projects by [Matt Martin](https://github.com/mjmartin23) and used to build prediction classifiers. This project uses the time-independent features from Kikas, Dumas, and Pfahl's [2016 paper](http://doi.acm.org/10.1145/2901739.2901751) on predicting issue close time, as described in the following table:

| Feature name                  | Feature Description |
|-------------------------------|---------------------|
|issueCleanedBodyLen            | The number of words in the issue title and description. For JIRA issues, this is the number of words in the issue description and summary |
| nCommitsByCreator             | Number of commits made by the creator of the issue in the 3 months before the issue was created |
| nCommitsInProject             | Number of commits made in the project in the 3 months before the issue was created |
| nIssuesByCreator              | Number of issues opened by the issue creator in the 3 months before the issue was opened |
| nIssuesByCreatorClosed        | Number of issues opened by the issue creator that were closed in the 3 months before the issue was opened |
| nIssuesCreatedInProject       | Number of issues opened in the project in the 3 months before the issue was opened |
| nIssuesCreatedInProjectClosed | Number of issues in the project opened and closed in the 3 months before the issue was opened |
| timeOpen {1,7,14,30, 90,180,365,1000} | Close time of the issue. For example, $14$ indicates the issue closed in at least 7 days and less then 14 days. |

## To run the cross-validation experiment:
Compile the Java classes:

```
$ make     (or "make compile-java")
```
Configure the experimental setup by changing the variables at the top of `run.sh`

Run the experiment:

```
$ bash run.sh
```

Results can be found in the `out/` directory.

## To run the round robin experiment:
Compile the Java classes:

```
$ make     (or "make compile-java")
```
2. Run the round robin experiment:

```
$ bash roundRobin.sh
```
Results can be found in the `out/roundRobin` directory.
