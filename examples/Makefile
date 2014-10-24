.PHONY: clean clear init

LEFT=graph://cae
CORR=graph://correspondence
RIGHT=graph://hmi

all: clear init run

run: clean

init: 
	mkdir -p traces/manual/declarative traces/manual/declarative traces/manual/class2table \
		traces/operational/forward traces/operational/backward traces/operational/declarative

clean: clean-correspondence clean-left clean-right
	
clean-left:
	update --desc dataset.ttl "CLEAR GRAPH <${LEFT}>"
	
clean-right:
	update --desc dataset.ttl "CLEAR GRAPH <${RIGHT}>"

clean-correspondence:
	update --desc dataset.ttl "CLEAR GRAPH <${CORR}>"

clear:
	rm -f *_generated.*
	rm -fR traces/*
	rm -fR DB

load-left: models/cae_example1.ttl
	tdbloader --tdb dataset.ttl --graph "${LEFT}" $<

load-right: models/hmi_example1.ttl
	tdbloader --tdb dataset.ttl --graph "${RIGHT}" $<


diagrams: models/cae_example1.ttl.png models/cae_meta.ttl.png

%_meta.%.png: %_meta.%
	rdfUmlDiagram.py --rdfs -o $@ $<

%.png: %
	rdfUmlDiagram.py -o $@ $<



