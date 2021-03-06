# This Makefile ensures that the build is made out of source in a
# subdirectory called 'build' If it doesn't exist, it is created.
#
# This Makefile also contains delegation of the most common make commands
#
# If you have cmake installed you should be able to do:
#
#	make
#	make test
#	make install
#	make package
#
# That should build Cgreen in the build directory, run some tests,
# install it locally and generate a distributable package.

all: build
	cd build; make

.PHONY:debug
debug: build
	cd build; cmake -DCMAKE_BUILD_TYPE:string=Debug ..; make

32bit: build
	-rm -rf build; mkdir build; cd build; cmake -DCMAKE_C_FLAGS="-m32" -DCMAKE_CXX_FLAGS="-m32" ..; make

# TODO: verify that we're not already on CygwinXX, in that case "make" should suffice
.PHONY:cygwin32
cygwin32: build
	cd build; cmake -DCMAKE_C_COMPILER=i686-pc-cygwin-gcc -DCMAKE_CXX_COMPILER=i686-pc-cygwin-g++ -DCMAKE_INSTALL_BINDIR:string=bin32 -DCMAKE_INSTALL_LIBDIR:string=lib32 ..; make

.PHONY:cygwin64
cygwin64: build
	cd build; cmake -DCMAKE_C_COMPILER=i686-pc-cygwin-gcc -DCMAKE_CXX_COMPILER=i686-pc-cygwin-g++ ..; make

.PHONY:test
test: build
	cd build; make check

.PHONY:clean
clean: build
	cd build; make clean

.PHONY:package
package: build
	cd build; make package

.PHONY:install
install:
	cd build; make install


# This is kind of a hack to get a quicker and clearer feedback when
# developing Cgreen by using 'make unit'. Should be updated when new
# test libraries or output comparisons are added.

# Find out if 'uname -o' works, if it does - use it, otherwise use 'uname -s'
UNAMEOEXISTS=$(shell uname -o 1>&2 2>/dev/null; echo $$?)
ifeq ($(UNAMEOEXISTS),0)
  OS=$(shell uname -o)
else
  OS=$(shell uname -s)
endif
ifeq ($(OS),Darwin)
	PREFIX=lib
	SUFFIX=.dylib
else ifeq ($(OS),Cygwin)
	PREFIX=cyg
	SUFFIX=.dll
else
	PREFIX=lib
	SUFFIX=.so
endif

OUTPUT_DIFF=../../tools/cgreen_runner_output_diff
OUTPUT_DIFF_ARGUMENTS = $(1)_tests \
	../../tests \
	$(1)_tests.expected

unit: build-it
	# Ensure the dynamic libraries can be found even on DLL-platforms without altering
	# user process PATH
	export PATH=$$PWD/build/src:"$$PATH" ; \
	SOURCEDIR=$$PWD/tests/ ; \
	cd build ; \
	tools/cgreen-runner -c `find tests -name $(PREFIX)cgreen_c_tests$(SUFFIX)` ; \
	r=$$((r + $$?)) ; \
	tools/cgreen-runner -c `find tests -name $(PREFIX)cgreen_cpp_tests$(SUFFIX)` ; \
	r=$$((r + $$?)) ; \
	tools/cgreen-runner -c `find tools/tests -name $(PREFIX)cgreen_runner_tests$(SUFFIX)` ; \
	r=$$((r + $$?)) ; \
	cd tests ; \
	../../tools/cgreen_xml_output_diff $(call OUTPUT_DIFF_ARGUMENTS,xml_output) ; \
	r=$$((r + $$?)) ; \
	$(OUTPUT_DIFF) $(call OUTPUT_DIFF_ARGUMENTS,mock_messages) ; \
	r=$$((r + $$?)) ; \
	$(OUTPUT_DIFF) $(call OUTPUT_DIFF_ARGUMENTS,constraint_messages) ; \
	r=$$((r + $$?)) ; \
	$(OUTPUT_DIFF) $(call OUTPUT_DIFF_ARGUMENTS,assertion_messages) ; \
	r=$$((r + $$?)) ; \
	$(OUTPUT_DIFF) $(call OUTPUT_DIFF_ARGUMENTS,ignore_messages) ; \
	r=$$((r + $$?)) ; \
	CGREEN_PER_TEST_TIMEOUT=1 $(OUTPUT_DIFF) $(call OUTPUT_DIFF_ARGUMENTS,failure_messages) ; \
	r=$$((r + $$?)) ; \
	exit $$r

.PHONY: doc
doc: build
	cd build; cmake -DCGREEN_WITH_HTML_DOCS:bool=TRUE ..; make; cmake -DCGREEN_WITH_HTML_DOCS:bool=False ..; echo open $(PWD)/build/doc/cgreen-guide-en.html

pdf: build
	cd build; cmake -DCGREEN_WITH_PDF_DOCS:bool=TRUE ..; make; cmake -DCGREEN_WITH_PDF_DOCS:bool=False ..; echo open $(PWD)/build/doc/cgreen-guide-en.pdf



############# Internal

ifeq ($(OS),Darwin)
ARCHS=-DCMAKE_OSX_ARCHITECTURES:string="x86_64;i386"
endif


build-it: build
	cd build
	make

build:
	mkdir build
	cd build; cmake $(ARCHS) ..

.SILENT:
