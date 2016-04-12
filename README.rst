ngetopt.awk
===========

:subtitle: AWK-Library for command line parsing
:Version: 0.1
:Manual section: 2
:Manual group: gawk library
:author: joepvd
:copyright: GNU


.. image:: https://travis-ci.org/joepvd/ngetopt.awk.svg?branch=master
    :target: https://travis-ci.org/joepvd/ngetopt.awk


SYNOPSIS
--------

A command line option parsing library for `gawk4` written in `gawk4`.  Abolish the need to write shell command line parsers for the small programs.  Typical use looks like this: 

.. code-block::

    #!/usr/bin/gawk -E
    @include "ngetopt"
    BEGIN {
        regopt(opstring)
        parseopt()
        usage()
    }

A line-by-line breakdown: 

#!/usr/bin/gawk -E
    The `-E`-switch tells `gawk` to disable its own command line processing, so we have the line all to ourselves. 

@include "ngetopt"
    Attempts to find `ngetopt` or `ngetopt.awk` the awk library path. See `FILES` for more information. 

After setup, the following user accessible functions are available: 

regopt()
    A convenience function to add a new entry to the globally available `opt`-array. 

parseopt()
    Parses the command line, making use of array `opt`. Will set configuration as needed. 

usage()
    With the function `usage()`, a help message is generated from the defined options.


DESCRIPTION
-----------

Central to `ngetopt.awk` is the array `opt`. 

The `opt`-array needs to have all information of the options.  There is a numeric index for each option, for which a few properties shall be defined. 

.. code-block:: 

    opt[1]["short"]="F"
    opt[1]["long"]="field-separator"
    opt[1]["flag"]="FS"
    opt[1]["description"]="Sets the field separator."

Properties of the `opt`-array that have special meaning are the following: 

short
    The short option. Will fail if it is more than one character. 

long
    The long option. Will be parsed with ``--`` before it.
    
A registered option requires one short option, one long option, or a long option and a short option. 

has_arg
    *Required* Defines the type of option. Required. Accepted values: 
    ``0`` or ``no``: Option does not require an argument
    ``1`` or ``yes``: Option requires an argument
    ``2`` or ``maybe``: Not implemented. 
    Required.

flag
    The variable that will contain whatever has been specified on the command line. This is what your program will need. Required. 

desc
    Description. Used when displaying the ``usage()``-function. Optional. 

default
    The value ``flag`` will assume if specified.  As `optional arguments` are as of yet not supported, use is limited to shortcuts. 

vals
    This defines the permissable values of the option.  A ``|``-separated string serves as a definition of possibly values.  

regopt()
++++++++

In stead of constructing the `opt`-array manually, the utility function `regopt` can be used.  For each call, it adds a new option to the `opt`-array.  An example: 

.. code-block::

    regopt("short=F;long=field-separator;has_arg=yes;desc=Define the Field Separator")

`regopt` accepts one `;`-separated string of `=`-separated key-value pairs.  Permissable keys are listed in the previous section. 


FILES
-----

`gawk` version 4 should be available.  The library has been tested with the current stable release, `gawk 4.1.1`. 
Put `nregopt.awk` in `$AWKPATH`.  If you did not set `$AWKPATH` as an environment variable in your shell startup scripts, you can establish the location like this::

    % gawk 'BEGIN{print ENVIRON["AWKPATH"]}' 
    .:/usr/share/awk

On my system, `gawk` will first look in the current directory for a file to include, then in `/usr/share/awk`.

EXAMPLES
--------

See the ``test/``-directory for some examples.  Also see table_ for a real world application. 

.. _table: https://github.com/joepvd/table

BUGS
----

Probably.  Send a pull request or open an issue on https://github.com/joepvd/ngetopt.awk

SEE ALSO
--------

`getopt(3)`, `gawk(1)`

