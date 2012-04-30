What is kal-shlib-shunit ?
--------------------------

It provides a shell unit simple framework. This is meant to right simple tests
and see them prettily reported.

this source::

  assert_list <<EOF

  ### Dumb tests

  ##
  ## -- '/etc/passwd' contains a root user
  ##

  cat /etc/passwd | grep ^root:

  ##
  ## -- 2 + 2 == 4
  ##

  a=2
  b=2
  echo \$a + \$b | bc

  EOF

outputs::

  Dumb tests:
  - '/etc/passwd' contains a root user         [  OK  ] T
  - 2 + 2 == 4                                 [  OK  ] T


This is part of ``kal-shlib-*`` package, you should see `documentation`_ of
``kal-shlib-core`` for more general information.

.. _documentation: https://github.com/vaab/kal-shlib-core/blob/master/README.rst


How can install it ?
--------------------

From source
'''''''''''

Consider this release as Very Alpha. Use at your own risk. It may or may not
upgrade to a more user friendly version in future, depending on my spare time.

Nethertheless, this package support GNU install quite well so a simple::

  # autogen.sh && ./configure && make && make install

Should work (and has been tested and is currently used).

.. note:: you can specify a prefix thanks to ``--prefix=/your/location`` as
  ``configure`` argument.

From debian package
'''''''''''''''''''

A debian package repository is available at::

  deb http://deb.kalysto.org no-dist kal-alpha

you should include this repository to your apt system and then::

  apt-get update && apt-get install kal-shlib-shunit


What are dependencies for this package ?
----------------------------------------

You will need to install::

  kal-shlib-core
  kal-shlib-common
  kal-shlib-pretty

before using this package. Note that if you choose the debian package
installation, dependencies will be installed automatically.


What do this package contains ?
-------------------------------

Libraries which are files called ``lib*.sh`` installed in
``$prefix/lib/shlib/``

The debian package version will install directly to this location (knowing that
prefix is ``/usr``)


What these libraries provide ?
------------------------------

Hands on
''''''''

It provides a quick way to make shell unit tests through:

assert
""""""

    SYNOPSIS

      ``assert [OPTION] {description} {command line}``

    DESCRIPTION

      for one-shot, single line assertions.

    ARGUMENTS

      ``description``

        Will be displayed in standard output report as header of the test.

    OPTIONS

      ``-r`` (for retry mode)

        Retry the given test as up to \$max_retries times (defaults to 10).

        Will sleep $sleep_time seconds between each retry (defaults to 1).

        Stops at first success and return True. Return False if no retries gave
        a success.

      ``-q`` (for quiet mode)

        No output at all if no errors.

    EXAMPLE::

       assert "read access to /tmp/passwd" cat /tmp/passwd

assert_list
"""""""""""

    SYNOPSIS

      ``assert_list [OPTION] {description}``

    DESCRIPTION

      for multiple assertion given through standard input in a special format,
      allowing multiple line shell script tests.

    ARGUMENTS

      ``description``

        Will be displayed in standard output report as title the test(s).

    OPTIONS

      ``-q`` (for quiet mode)

        No output at all if no errors.

    EXAMPLE::

        assert_list <<EOF

        ### This text will appears as a Section (thanks to the 3 '\#' in front of this line)

        ##
        ## -- this text will be displayed as title of the test ('##' and '--' are required.)
        ##

        # normal comment. Not displayed anywhere. (single \# is important)
        # a mutliline test:
        a=2
        b=2
        echo \$a + \$b | bc

        # only the last errorlevel will be used as result of the test.

        ##
        ## -R- This is a retry test (thanks to the 'R' between the both '-' at beginning of line)
        ##

        ping -c 1 -w 1 www.google.fr

        EOF


testbench
"""""""""

  SYNOPSIS

    ``testbench NAME``

  DESCRIPTION

    fetches all ``test_NAME_*`` function declaration, and run them.


Generic test file
'''''''''''''''''

A sample test file could look like this 'sample' shell script::

  #!/bin/bash

  function test_foo() {

      ## .. and setup ..

      assert "write access to current dir" touch a

  }

  ## or

  function test_bar() {

      assert_list <<EOF

              ## -- this text will be displayed as title of the test ('##' and '--' are required.)

  EOF
  }

  testbench "$@"

this allows to call the script::

  sample foo

to test only foo, or::

  sample

to laucnh all detected test.
