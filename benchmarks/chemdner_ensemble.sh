#!/bin/sh
set -x
LOGLEVEL=${1:-WARNING}


# import external dev and eval results to IBEnt format
python src/classification/results.py import chemdner2017_dev --results results/ibelight_chebi_dev -i results/ChEBI_training_set_annots.tsv --model ibelight_chebi_chemical --log $LOGLEVEL
python src/classification/results.py import chemdner2017_dev --results results/ibelight_drugbank_dev -i results/DrugBank_training_set_annots.tsv --model ibelight_drugbank_chemical --log $LOGLEVEL
python src/classification/results.py import chemdner2017_dev --results results/ibelight_chembl_dev -i results/ChEMBL_training_set_annots.tsv --model ibelight_chembl_chemical --log $LOGLEVEL
python src/classification/results.py import chemdner2017_dev --results results/ibelight_hmdb_dev -i results/HMDB_training_set_annots.tsv --model ibelight_hmdb_chemical --log $LOGLEVEL

# merge into one file
python src/evaluate.py combine chemdner2017_dev --results results/chemical_train_on_dev_crfsuite \
                                                          results/chemical_train_on_dev_stanford \
                                                          results/ibelight_chebi_dev \
                                                          results/ibelight_drugbank_dev \
                                                          results/ibelight_chembl_dev \
                                                          results/ibelight_hmdb_dev \
                                                          --models results/ensemble_chemdner_dev --entitytype chemical --log $LOGLEVEL

# normalize dev and eval to get mapping and ssm scores
python src/normalize.py chebi chemdner2017_dev --results results/ensemble_chemdner_dev --models results/ensemble_chemdner_dev --entitytype chemical --log $LOGLEVEL
python src/normalize.py ssm chemdner2017_dev --measure simui --results results/ensemble_chemdner_dev --models results/ensemble_chemdner_dev --entitytype chemical --log $LOGLEVEL
python src/normalize.py ssm chemdner2017_dev --measure simui_hindex --results results/ensemble_chemdner_dev --models results/ensemble_chemdner_dev --entitytype chemical --log $LOGLEVEL
python src/normalize.py ssm chemdner2017_dev --measure resnik --results results/ensemble_chemdner_dev --models results/ensemble_chemdner_dev --entitytype chemical --log $LOGLEVEL
python src/normalize.py ssm chemdner2017_dev --measure simgic --results results/ensemble_chemdner_dev --models results/ensemble_chemdner_dev --entitytype chemical --log $LOGLEVEL
python src/normalize.py ssm chemdner2017_dev --measure simgic_hindex --results results/ensemble_chemdner_dev --models results/ensemble_chemdner_dev --entitytype chemical --log $LOGLEVEL


python src/evaluate.py savetocorpus chemdner2017_dev --results results/ensemble_chemdner_dev --output data/chemdner_dev_ensemble

# train classifier based on dev results, mapping and ssm scores
python src/main.py train --goldstd chemdner2017_dev_ensemble --crf ensemble --entitytype chemical --models chemdner_ensemble

#python src/classification/results.py import chemdner2017_eval --results results/ibelight_chebi_eval -i results/ChEBI_training_set_annots.tsv --model ibelight_chebi_chemical --log info

# generate test set
#python src/evaluate.py combine chemdner2017_eval --results results/chemical_train_on_eval_crfsuite results/chemical_train_on_eval_stanford results/ibelight_chebi_eval --models results/ensemble_chemdner_eval --entitytype chemical
#python src/normalize.py chebi chemdner2017_eval --results results/ensemble_chemdner_eval --models results/ensemble_chemdner_eval --entitytype chemical --log $LOGLEVEL
#python src/normalize.py ssm chemdner2017_eval --results results/ensemble_chemdner_eval --models results/ensemble_chemdner_eval --entitytype chemical --log $LOGLEVEL
#python src/evaluate.py savetocorpus chemdner2017_eval --results results/ensemble_chemdner_eval --output data/chemdner_eval_ensemble

# test on eval set
#python src/main.py test --goldstd chemdner2017_eval --log $LOGLEVEL --entitytype chemical --models chemdner_ensemble -o pickle results/chemical_dev_on_eval_ensemble  --crf ensemble
#python src/evaluate.py evaluate chemdner2017_eval --results results/chemical_dev_on_eval_ensemble --models chemdner_ensemble --entitytype chemical --log $LOGLEVEL --external
