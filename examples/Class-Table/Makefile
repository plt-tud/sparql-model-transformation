.PHONY: run clear forward backward correspondence info
.SECONDARY: %.spin.ttl

info:
	@echo "This makefile performs model transformation on a class-table example"


all: init run

clear:
	rm -f operational/*/*
	rm -f dump.*
	rm -fR DB


init:
	mkdir -p operational/forward operational/backward operational/correspondence

run: clear forward backward correspondence
	@echo "Performed Transformations"


rules = 01_Class2Table.spin.rq 02_AttributesWithPrimitiveDatatype.spin.rq

forward = $(addprefix operational/forward/, $(rules))
backward = $(addprefix operational/backward/, $(rules))
correspondence = $(addprefix operational/correspondence/, $(rules))

forward:  $(forward)
	@echo $<

backward:  $(backward)
	@echo $<

correspondence: $(correspondence)



transform/step0/%: declarative/%
	update --desc dataset.ttl "CLEAR ALL"
	tdbloader --tdb dataset.ttl  $<

transform/step1/forward/%: transform/step0/%
	update --desc dataset.ttl --update decR2opR_01_move_forward.rq

transform/step1/backward/%: transform/step0/%
	update --desc dataset.ttl --update decR2opR_01_move_backward.rq
	
transform/step1/correspondence/%: transform/step0/%
	update --desc dataset.ttl --update decR2opR_01_move_forward.rq
	update --desc dataset.ttl --update decR2opR_01_move_backward.rq

transform/step2/%:  transform/step1/%
	update --desc dataset.ttl --update decR2opR_02a_copy_start.rq
	update --desc dataset.ttl --update decR2opR_02b_copy_markAll.rq
	update --desc dataset.ttl --update decR2opR_02c_copy_copy.rq
	update --desc dataset.ttl --update decR2opR_02d_copy_connect.rq
	update --desc dataset.ttl --update decR2opR_02e_copy_literals.rq
	update --desc dataset.ttl --update decR2opR_02f_copy_insert.rq
	update --desc dataset.ttl --update decR2opR_02g_copy_clear.rq
	update --desc dataset.ttl --update decR2opR_03_convert_blank_nodes.rq

operational/%.spin.n3: transform/step2/%.spin.ttl
	tdbdump --desc dataset.ttl > $@


dump: dataset.ttl
	tdbdump --desc dataset.ttl > dump.n3
	rapper -g dump.n3 -o turtle > dump.`date +'%Y-%m-%dT%H-%M-%S'`.ttl

selectAll: dataset.ttl
	arq --desc dataset.ttl "SELECT * WHERE {?s ?p ?o.} ORDER BY ?s ?p ?o"


%.ttl: %.n3
	rapper -g $< -o turtle > $@

%.spin.rq: %.spin.ttl
	spin2sparql.sh $< > $@

%.spin.ttl: %.rq
	spin2sparql.sh $< > $@

%.png: %
	rdfObjectDiagram.py -o $@ $<
