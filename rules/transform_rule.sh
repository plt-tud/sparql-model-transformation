#!/bin/bash

# First parameter is the transformation rule as SPARQL query file
INPUT=$1
[[ -z  $INPUT  ]] && INPUT=../examples/Class-Table/rules/declarative/01_Class2Table.rq

# second parameter is the output file name
OUTPUT=$2
[[ -z  $OUTPUT  ]] && OUTPUT="query.test"

echo "Input argument: $INPUT"
echo "Output argument: $OUTPUT"

#export FUSEKI_HOME=/home/mgraube/Dokumente/Projekte/LinkedData/applications/Backend/Jena/apache-jena-fuseki

# Make sure that a fuseki server is running
# $FUSEKI_HOME/fuseki-server --mem /transformation &
DS_URI=http://localhost:3030/transformation
GRAPH_TGG=http://tgg.plt.tu-dresden.de


#######################################
## FUSEKI Functions                  ##
#######################################

function fput {
    $FUSEKI_HOME/bin/s-put $1 $2 $3
}
function fget {
    $FUSEKI_HOME/bin/s-get $1 $2
}
function fupdate {
    DS_URI=$1
    QUERY=$2
    $FUSEKI_HOME/bin/s-update --service=$DS_URI/update "$QUERY"
}
function fgupdate {
    DS_URI=$1
    GRAPH=$2
    QUERY=$3
    fupdate $DS_URI "`cat prefixes.rq` WITH <$GRAPH> $QUERY"
}

#######################################
## SPIN2SPARQL Functions             ##
#######################################

function spin2sparql {
    java -cp ../../spin2sparql/target/spin2sparql-0.3.0-jar-with-dependencies.jar de.tud.plt.spin2sparql.Spin2Sparql $1
}

function sparql2spin {
    java -cp ../../spin2sparql/target/spin2sparql-0.3.0-jar-with-dependencies.jar de.tud.plt.spin2sparql.Sparql2Spin $1
}


#######################################
## Transformation Functions          ##
#######################################

function loadDeclarativeQueryIntoTripestore {
    SPARQL_QUERY=$1
    GRAPH=$2
    echo "Reading Query from $INPUT and store into graph <$GRAPH>"
    #sparql2spin  $SPARQL_QUERY > $SPARQL_QUERY.ttl
    fput $DS_URI $GRAPH $SPARQL_QUERY.ttl
    fupdate $DS_URI "CREATE GRAPH <$GRAPH_TGG>"
    fupdate $DS_URI "`cat prefixes.rq` INSERT DATA { GRAPH <$GRAPH_TGG> {
                        <$GRAPH> a tgg:OperationalRule;
                        rdfs:label \"$(basename $SPARQL_QUERY .rq)\";
                        tgg:query \"\"\"`cat $SPARQL_QUERY`\"\"\".
                    }}"
}



function performTransformation {
    GRAPH=$1
    fgupdate $DS_URI $GRAPH "`cat decR2opR_02a_copy_start.rq`"
    fgupdate $DS_URI $GRAPH "`cat decR2opR_02b_copy_markAll.rq`"
    fgupdate $DS_URI $GRAPH "`cat decR2opR_02c_copy_copy.rq`"
    fgupdate $DS_URI $GRAPH "`cat decR2opR_02d_copy_connect.rq`"
    fgupdate $DS_URI $GRAPH "`cat decR2opR_02e_copy_literals.rq`"
    fgupdate $DS_URI $GRAPH "`cat decR2opR_02f_copy_insert.rq`"
    fgupdate $DS_URI $GRAPH "`cat decR2opR_02g_copy_clear.rq`"

    fgupdate $DS_URI $GRAPH "`cat decR2opR_03_convert_blank_nodes.rq`"
}

function transformForward {
    DECLARATIVE=$1
    OPERATIONAL=$DECLARATIVE/forward
    echo "Do forward transformation for graph <$DECLARATIVE> in graph <$OPERATIONAL>"

    fupdate $DS_URI "COPY GRAPH <$DECLARATIVE> TO GRAPH <$OPERATIONAL>"

    fgupdate $DS_URI $OPERATIONAL "`cat decR2opR_01_move_forward.rq`"

    performTransformation $OPERATIONAL

    fget $DS_URI $OPERATIONAL > $OUTPUT.forward.ttl
    spin2sparql   $OUTPUT.forward.ttl > $OUTPUT.forward.rq
    fupdate $DS_URI "`cat prefixes.rq` INSERT DATA { GRAPH <$GRAPH_TGG> {
                                    <$DECLARATIVE> tgg:hasForwardRule <$OPERATIONAL>.
                                    <$OPERATIONAL> a tgg:OperationalRule;
                                            tgg:query \"\"\"`cat $OUTPUT.forward.rq`\"\"\".
                                }}"
    echo "Saved to $OUTPUT.forward.rq"
}

function transformBackward {
    DECLARATIVE=$1
    OPERATIONAL=$DECLARATIVE/backward
    echo "Do backward transformation for graph <$DECLARATIVE> in graph <$OPERATIONAL>"

    fupdate $DS_URI "COPY GRAPH <$DECLARATIVE> TO GRAPH <$OPERATIONAL>"

    fgupdate $DS_URI $OPERATIONAL "`cat decR2opR_01_move_backward.rq`"

    performTransformation $OPERATIONAL

    fget $DS_URI $OPERATIONAL > $OUTPUT.backward.ttl
    spin2sparql   $OUTPUT.backward.ttl > $OUTPUT.backward.rq
    fupdate $DS_URI "`cat prefixes.rq` INSERT DATA { GRAPH <$GRAPH_TGG> {
                                    <$DECLARATIVE> tgg:hasBackwardRule <$OPERATIONAL>.
                                    <$OPERATIONAL> a tgg:OperationalRule;
                                            tgg:query \"\"\"`cat $OUTPUT.backward.rq`\"\"\".
                                }}"
    echo "Saved to $OUTPUT.backward.rq"
}

function transformCorrespondence {
    DECLARATIVE=$1
    OPERATIONAL=$DECLARATIVE/correspondence
    echo "Do correspondence transformation for graph <$DECLARATIVE> in graph <$OPERATIONAL>"

    fupdate $DS_URI "COPY GRAPH <$DECLARATIVE> TO GRAPH <$OPERATIONAL>"

    fgupdate $DS_URI $OPERATIONAL "`cat decR2opR_01_move_forward.rq`"
    fgupdate $DS_URI $OPERATIONAL "`cat decR2opR_01_move_backward.rq`"

    performTransformation $OPERATIONAL

    fget $DS_URI $OPERATIONAL > $OUTPUT.correspondence.ttl
    spin2sparql   $OUTPUT.correspondence.ttl > $OUTPUT.correspondence.rq
    fupdate $DS_URI "`cat prefixes.rq` INSERT DATA { GRAPH <$GRAPH_TGG> {
                                    <$DECLARATIVE> tgg:hasCorrespondenceRule <$OPERATIONAL>.
                                    <$OPERATIONAL> a tgg:OperationalRule;
                                            tgg:query \"\"\"`cat $OUTPUT.correspondence.rq`\"\"\".
                                }}"
    echo "Saved to $OUTPUT.correspondence.rq"
}



#######################################
## Main                              ##
#######################################
DECLARATIVE_1=http://tgg.plt.tu-dresden.de/rule/$(basename $INPUT .rq)

loadDeclarativeQueryIntoTripestore $INPUT $DECLARATIVE_1

transformForward $DECLARATIVE_1
transformBackward $DECLARATIVE_1
transformCorrespondence $DECLARATIVE_1

echo "Finished"
