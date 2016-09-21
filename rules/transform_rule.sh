#!/bin/bash

# First parameter is the transformation rule as SPARQL query file
INPUT=$1
[[ -z  $INPUT  ]] && INPUT=../examples/Class-Table/rules/declarative/01_Class2Table.rq

OUTPUT=$2
[[ -z  $OUTPUT  ]] && OUTPUT="query.test"

echo $INPUT
echo $OUTPUT

#export FUSEKI_HOME=/home/mgraube/Dokumente/Projekte/LinkedData/applications/Backend/Jena/apache-jena-fuseki

# Make sure that a fuseki server is running
# $FUSEKI_HOME/fuseki-server --mem /transformation &

echo "Reading Query from $INPUT"
spin2sparql.sh  $INPUT > query.ttl

DS_URI=http://localhost:3030/transformation

function fput {
    $FUSEKI_HOME/bin/s-put $1 $2 $3
}
function fget {
    $FUSEKI_HOME/bin/s-get $1 $2
}
function fupdate {
    $FUSEKI_HOME/bin/s-update --service=$1/update "`cat prefixes.rq` WITH <$GRAPH> $2"
}




function performTransformation {
    fupdate $DS_URI "`cat decR2opR_02a_copy_start.rq`"
    fupdate $DS_URI "`cat decR2opR_02b_copy_markAll.rq`"
    fupdate $DS_URI "`cat decR2opR_02c_copy_copy.rq`"
    fupdate $DS_URI "`cat decR2opR_02d_copy_connect.rq`"
    fupdate $DS_URI "`cat decR2opR_02e_copy_literals.rq`"
    fupdate $DS_URI "`cat decR2opR_02f_copy_insert.rq`"
    fupdate $DS_URI "`cat decR2opR_02g_copy_clear.rq`"

    fupdate $DS_URI "`cat decR2opR_03_convert_blank_nodes.rq`"
}

function transformForward {
    GRAPH=urn:tag:forward
    echo "Do forward transformation in graph <$GRAPH>"

    fput $DS_URI $GRAPH query.ttl

    fupdate $DS_URI "`cat decR2opR_01_move_forward.rq`"

    performTransformation

    fget $DS_URI $GRAPH > $OUTPUT.forward.ttl
    spin2sparql.sh   $OUTPUT.forward.ttl > $OUTPUT.forward.rq
    echo "Saved to $OUTPUT.forward.rq"
}

function transformBackward {
    GRAPH=urn:tag:backward
    echo "Do backward transformation in graph <$GRAPH>"

    fput $DS_URI $GRAPH query.ttl

    fupdate $DS_URI "`cat decR2opR_01_move_backward.rq`"

    performTransformation $GRAPH

    fget $DS_URI $GRAPH > $OUTPUT.backward.ttl
    spin2sparql.sh   $OUTPUT.backward.ttl > $OUTPUT.backward.rq
    echo "Saved to $OUTPUT.backward.rq"
}

function transformCorrespondence {
    GRAPH=urn:tag:correspondence
    echo "Do correspondence transformation in graph <$GRAPH>"

    fput $DS_URI $GRAPH query.ttl

    fupdate $DS_URI "`cat decR2opR_01_move_forward.rq`"
    fupdate $DS_URI "`cat decR2opR_01_move_backward.rq`"

    performTransformation $GRAPH

    fget $DS_URI $GRAPH > $OUTPUT.correspondence.ttl
    spin2sparql.sh   $OUTPUT.correspondence.ttl > $OUTPUT.correspondence.rq
    echo "Saved to $OUTPUT.correspondence.rq"
}


transformForward
transformBackward
transformCorrespondence

echo "Finished"
