# Generated automatically from Makefile.in by configure.
# Makefile.in generated automatically by automake 1.0 from Makefile.am

# Copyright (C) 1994, 1995, 1996 Free Software Foundation, Inc.
# This Makefile.in is free software; the Free Software Foundation
# gives unlimited permission to copy, distribute and modify it.


SHELL = /bin/sh

srcdir = .
top_srcdir = .
prefix = /usr/local
exec_prefix = ${prefix}

bindir = ${exec_prefix}/bin
sbindir = ${exec_prefix}/sbin
libexecdir = ${exec_prefix}/libexec
datadir = ${prefix}/share
sysconfdir = ${prefix}/etc
sharedstatedir = ${prefix}/com
localstatedir = ${prefix}/var
libdir = ${exec_prefix}/lib
infodir = ${prefix}/info
mandir = ${prefix}/man
includedir = ${prefix}/include
oldincludedir = /usr/include

pkgdatadir = $(datadir)/fping
pkglibdir = $(libdir)/fping
pkgincludedir = $(includedir)/fping

top_builddir = .

INSTALL = /usr/bin/install -c
INSTALL_PROGRAM = ${INSTALL}
INSTALL_DATA = ${INSTALL} -m 644
INSTALL_SCRIPT = @INSTALL_SCRIPT@
transform = s,x,x,

sbin_PROGRAMS = fping
fping_SOURCES = fping.c options.h linux.h
man_MANS = fping.8
AUTOMAKE_OPTIONS=foreign
ACCONFIG = acconfig.h
CONFIG_HEADER_IN = config.h.in
mkinstalldirs = $(top_srcdir)/mkinstalldirs
CONFIG_HEADER = ./config.h
PROGRAMS = $(sbin_PROGRAMS)


CC = gcc
LEX = @LEX@
YACC = @YACC@

DEFS = -DHAVE_CONFIG_H -I. -I$(srcdir) -I.
CPPFLAGS = 
CFLAGS = -g -O2
LDFLAGS = 
LIBS = 

COMPILE = $(CC) -c $(DEFS) $(INCLUDES) $(CPPFLAGS) $(CFLAGS)
LINK = $(CC) $(LDFLAGS) -o $@
fping_OBJECTS = fping.o
EXTRA_fping_SOURCES =
fping_LDADD = $(LDADD)
MANS = fping.8

NROFF = nroff
DIST_COMMON = README COPYING ChangeLog INSTALL Makefile.am Makefile.in \
README acconfig.h config.h.in configure configure.in install-sh \
mkinstalldirs stamp-h.in


PACKAGE = fping
VERSION = 2.2b1

DISTFILES = $(DIST_COMMON) $(SOURCES) $(BUILT_SOURCES) $(HEADERS) \
	$(TEXINFOS) $(INFOS) $(MANS) $(EXTRA_DIST) $(DATA)
DEP_DISTFILES = $(DIST_COMMON) $(SOURCES) $(BUILT_SOURCES) $(HEADERS) \
	$(TEXINFOS) $(INFO_DEPS) $(MANS) $(EXTRA_DIST) $(DATA)

TAR = tar
SOURCES = $(fping_SOURCES)
OBJECTS = $(fping_OBJECTS)

default: all


$(srcdir)/Makefile.in: Makefile.am configure.in
	cd $(srcdir) && automake Makefile

# For an explanation of the following Makefile rules, see node
# `Automatic Remaking' in GNU Autoconf documentation.
Makefile: Makefile.in config.status
	CONFIG_FILES=$@ CONFIG_HEADERS= ./config.status
config.status: configure
	./config.status --recheck
$(srcdir)/configure: configure.in $(ACLOCAL) $(CONFIGURE_DEPENDENCIES)
	cd $(srcdir) && autoconf

$(CONFIG_HEADER): stamp-h
stamp-h: $(CONFIG_HEADER_IN) config.status
	CONFIG_FILES= CONFIG_HEADERS=$(CONFIG_HEADER) ./config.status
	@echo timestamp > stamp-h
$(srcdir)/$(CONFIG_HEADER_IN): stamp-h.in
$(srcdir)/stamp-h.in: configure.in $(ACLOCAL) $(ACCONFIG) $(CONFIG_TOP) $(CONFIG_BOT)
	cd $(srcdir) && autoheader
	echo timestamp > $(srcdir)/stamp-h.in

mostlyclean-sbinPROGRAMS:

clean-sbinPROGRAMS:
	rm -f $(sbin_PROGRAMS)

distclean-sbinPROGRAMS:

maintainer-clean-sbinPROGRAMS:

install-sbinPROGRAMS: $(sbin_PROGRAMS)
	$(mkinstalldirs) $(sbindir)
	list="$(sbin_PROGRAMS)"; for p in $$list; do \
	  if test -f $$p; then \
	    $(INSTALL_PROGRAM) $$p $(sbindir)/`echo $$p|sed '$(transform)'`; \
	  else :; fi; \
	done

uninstall-sbinPROGRAMS:
	list="$(sbin_PROGRAMS)"; for p in $$list; do \
	  rm -f $(sbindir)/`echo $$p|sed '$(transform)'`; \
	done

.c.o:
	$(COMPILE) $<

mostlyclean-compile:
	rm -f *.o core

clean-compile:

distclean-compile:
	rm -f *.tab.c

maintainer-clean-compile:
$(fping_OBJECTS): ./config.h

fping: $(fping_OBJECTS) $(fping_DEPENDENCIES)
	$(LINK) $(fping_OBJECTS) $(fping_LDADD) $(LIBS)
install-man: $(MANS)
	$(mkinstalldirs) $(mandir)/man8
	@sect=8;				\
	inst=`echo "fping" | sed '$(transform)'`.8; \
	echo installing fping.8 as $(mandir)/man$$sect/$$inst; \
	$(INSTALL_DATA) $(srcdir)/fping.8 $(mandir)/man$$sect/$$inst

uninstall-man:
	inst=`echo "fping" | sed '$(transform)'`.8; \
	rm -f $(mandir)/man8/$$inst


ID: $(HEADERS) $(SOURCES)
	here=`pwd` && cd $(srcdir) && mkid -f$$here/ID $(SOURCES) $(HEADERS)

tags: TAGS

TAGS: $(HEADERS) $(SOURCES) $(TAGS_DEPENDENCIES)
	here=`pwd` && cd $(srcdir) && etags $(ETAGS_ARGS) $(SOURCES) $(HEADERS) -o $$here/TAGS

mostlyclean-tags:

clean-tags:

distclean-tags:
	rm -f TAGS ID

maintainer-clean-tags:

distdir = $(PACKAGE)-$(VERSION)
# This target untars the dist file and tries a VPATH configuration.  Then
# it guarantees that the distribution is self-contained by making another
# tarfile.
distcheck: dist
	rm -rf $(distdir)
	$(TAR) zxf $(distdir).tar.gz
	mkdir $(distdir)/=build
	mkdir $(distdir)/=inst
	dc_install_base=`cd $(distdir)/=inst && pwd`; \
	cd $(distdir)/=build \
	  && ../configure --srcdir=.. --prefix=$$dc_install_base \
	  && $(MAKE) \
	  && $(MAKE) check \
	  && $(MAKE) install \
	  && $(MAKE) installcheck \
	  && $(MAKE) dist
	rm -rf $(distdir)
	@echo "========================"; \
	echo "$(distdir).tar.gz is ready for distribution"; \
	echo "========================"
dist: distdir
	chmod -R a+r $(distdir)
	$(TAR) chozf $(distdir).tar.gz $(distdir)
	rm -rf $(distdir)
distdir: $(DEP_DISTFILES)
	rm -rf $(distdir)
	mkdir $(distdir)
	chmod 777 $(distdir)
	@for file in `cd $(srcdir) && echo $(DISTFILES)`; do \
	  test -f $(distdir)/$$file \
	  || ln $(srcdir)/$$file $(distdir)/$$file 2> /dev/null \
	  || cp -p $(srcdir)/$$file $(distdir)/$$file; \
	done
fping.o: fping.c options.h

info:

dvi:

check: all

installcheck:

install-exec: install-sbinPROGRAMS

install-data: install-man

install: install-exec install-data all
	@:

uninstall: uninstall-sbinPROGRAMS uninstall-man

all: $(PROGRAMS) $(MANS) Makefile config.h

install-strip:
	$(MAKE) INSTALL_PROGRAM='$(INSTALL_PROGRAM) -s' install
installdirs:
	$(mkinstalldirs)  $(sbindir) $(mandir)/man8


mostlyclean-generic:
	test -z "$(MOSTLYCLEANFILES)" || rm -f $(MOSTLYCLEANFILES)

clean-generic:
	test -z "$(CLEANFILES)" || rm -f $(CLEANFILES)

distclean-generic:
	rm -f Makefile $(DISTCLEANFILES)
	rm -f config.cache config.log $(CONFIG_HEADER) stamp-h

maintainer-clean-generic:
	test -z "$(MAINTAINERCLEANFILES)" || rm -f $(MAINTAINERCLEANFILES)
	test -z "$(BUILT_SOURCES)" || rm -f $(BUILT_SOURCES)
mostlyclean:  mostlyclean-sbinPROGRAMS mostlyclean-compile \
		mostlyclean-tags mostlyclean-generic

clean:  clean-sbinPROGRAMS clean-compile clean-tags clean-generic \
		mostlyclean 

distclean:  distclean-sbinPROGRAMS distclean-compile distclean-tags \
		distclean-generic clean 
	rm -f config.status

maintainer-clean:  maintainer-clean-sbinPROGRAMS \
		maintainer-clean-compile maintainer-clean-tags \
		maintainer-clean-generic distclean 
	@echo "This command is intended for maintainers to use;"
	@echo "it deletes files that may require special tools to rebuild."
	rm -f config.status

.PHONY: default mostlyclean-sbinPROGRAMS distclean-sbinPROGRAMS \
clean-sbinPROGRAMS maintainer-clean-sbinPROGRAMS uninstall-sbinPROGRAMS \
install-sbinPROGRAMS mostlyclean-compile distclean-compile \
clean-compile maintainer-clean-compile install-man uninstall-man tags \
mostlyclean-tags distclean-tags clean-tags maintainer-clean-tags \
distdir info dvi check installcheck install-exec install-data install \
uninstall all installdirs mostlyclean-generic distclean-generic \
clean-generic maintainer-clean-generic clean mostlyclean distclean \
maintainer-clean

.SUFFIXES:
.SUFFIXES: .c .o

# Tell versions [3.59,3.63) of GNU make to not export all variables.
# Otherwise a system limit (for SysV at least) may be exceeded.
.NOEXPORT:
