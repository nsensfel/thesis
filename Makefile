################################################################################
## Document Parameters #########################################################
################################################################################
# Name of the main file, without the .tex extension.
DOCUMENT_FILENAME ?= main

################################################################################
## Binaries ####################################################################
################################################################################
BIBTEX ?= bibtex
PDFLATEX ?= pdflatex
#INKSCAPE ?= inkscape

################################################################################
## Sub-Directories #############################################################
################################################################################
TEX_LIBRARIES ?= $(wildcard ${CURDIR}/include/library/*)
################################################################################
## Deducing Main Target ########################################################
################################################################################
ifeq ($(strip $(PDFVIEWER)),)
main_target: compile

else
main_target: view

endif

################################################################################
## Basic Makefile Shenanigans ##################################################
################################################################################
CLASSPATHIFY = $(subst $(eval) ,:,$(wildcard $1))
COMMA =,

################################################################################
## Localising Relevant Files ###################################################
################################################################################
TEXINPUTS := ".:$(subst $(eval) ,:,$(wildcard $(TEX_LIBRARIES))):"
TEX_FILES = $(shell find ${CURDIR} -iname \*.tex)
SVG_FILES = $(shell find ${CURDIR} -type f -iname \*.svg)
#### Handling Bibliography #####################################################
BIBLIO_LINE = $(shell grep -o -h -r "^\\\\bibliography{.*}" $(TEX_FILES))

ifeq ($(strip $(BIBLIO_LINE)),)
BIBLIO_FILES =
BIBLIO_CMD = echo 'Bibtex: No biblio, skipping...'
else
BIBLIO_LIST = $(patsubst \bibliography{%},%$(COMMA),$(BIBLIO_LINE))
BIBLIO_FILES = $(subst $(COMMA),.bib ,$(BIBLIO_LIST))
BIBLIO_CMD = $(BIBTEX) $(DOCUMENT_FILENAME)
endif

################################################################################
## Managing SVG to PDF Conversion ##############################################
################################################################################
PDF_IMG_FILES = $(patsubst %.svg,%.pdf,$(SVG_FILES))

ifeq ($(shell which $(INKSCAPE)),)
$(PDF_IMG_FILES): %.pdf: %.svg
	$(warning $@ is outdated, but $(INKSCAPE) is not available to re-create it)
else ifeq ($(shell $(INKSCAPE) --version | egrep "Inkscape 1"),)
$(PDF_IMG_FILES): %.pdf: %.svg
	$(INKSCAPE) --file=$< --export-area-drawing --without-gui --export-pdf=$@
else
$(PDF_IMG_FILES): %.pdf: %.svg
	$(INKSCAPE) -D --export-filename=$@ $<
endif

################################################################################
## Making the Actual PDF #######################################################
################################################################################
$(DOCUMENT_FILENAME).pdf: $(PDF_IMG_FILES) $(TEX_FILES) $(BIBLIO_FILES) Makefile
	TEXINPUTS=$(TEXINPUTS) $(PDFLATEX) $(DOCUMENT_FILENAME).tex
	$(BIBLIO_CMD)
	TEXINPUTS=$(TEXINPUTS) $(PDFLATEX) $(DOCUMENT_FILENAME).tex
	TEXINPUTS=$(TEXINPUTS) $(PDFLATEX) $(DOCUMENT_FILENAME).tex
#	grep -i "\\(Reference\\|Citation\\).*undefined" $(DOCUMENT_FILENAME).log || true
	grep -i "\\(Reference\\|Citation\\).*undef" $(DOCUMENT_FILENAME).log || true

################################################################################
## Secondary Targets ###########################################################
################################################################################

view: compile
	$(PDFVIEWER) $(DOCUMENT_FILENAME).pdf

compile: $(DOCUMENT_FILENAME).pdf
	$(MAKE) clean_mess

edit:
	$(EDITOR) $(TEX_FILES)

clean:
	rm -f $(filter-out $(DOCUMENT_FILENAME).tex,$(wildcard $(DOCUMENT_FILENAME).*))
	rm -f $(shell find ${CURDIR}/src -iname \*.aux)
	rm -f $(wildcard ${CURDIR}/include/*.aux)

upload: compile
	scp $(DOCUMENT_FILENAME).pdf dreamhost:~/noot-noot/

################################################################################
clean_mess:
	rm -f \
		$(filter-out $(DOCUMENT_FILENAME).tex, \
			$(filter-out $(DOCUMENT_FILENAME).pdf, \
				$(wildcard $(DOCUMENT_FILENAME)\.*) \
			) \
		)
	rm -f $(shell find ${CURDIR}/src -iname \*.aux)
	rm -f $(wildcard ${CURDIR}/include/*.aux)
