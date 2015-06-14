# Library for option parsing with gawk programs. Original program
# needs to be started with the `-E` option, which disables all the
# option processing of gawk itself. 
#
# See README.rst, or, on a properly configured system, `man 2 ngetopt'. 
#
# Released under GPL2, see LICENSE for details. 
#
# By joepvd, 2015
# https://github.com/joepvd/ngetopt.awk


function regopt(str,        n, pairs, keyval, i, j, o, key, val, s, v, k, pv) {
    # Convenience function to register option parameters into the globally
    # available `opt`-array. Takes a string as argument that is colon separated 
    # list of key-value pairs. Keys and values are separated with a `=`-sign. 

    # TODO: Commentify the variable reservation in the function declaration. 

    if (1 in opt) {} # Now, opt is an array, even if it did not exist before. 
    n=length(opt)+1  # Index of the soon-to-be registered option.

    split(str, pairs, "[[:space:]]*;[[:space:]]*")
    for (o in pairs) {
        split(pairs[o], keyval, "=")
        key = keyval[1]
        val = keyval[2]
        if (key == "has_arg") {
            if (val ~ /^(yes|Y|y|YES|0)$/)
                opt[n]["has_arg"] = "0"
            else
                opt[n]["has_arg"] = "1" 
        } 
        else if (key == "vals") {
            split(val, pv, "|")
            for (k in pv) {
                #print "k", k
                opt[n]["vals"][pv[k]]
            }
        }
        else opt[n][key] = val
    }
    # Registered the input.
    # Check if the obligatory stuff is available: 
    if ( ! "long" in opt[n] && ! "short" in opt[n] ) {
        printf "noptparse: Neither long nor short option " >"/dev/stderr"
        printf "detected. Terminating.\n" >"/dev/stderr"
        _assert_exit = 1
        exit 1
    } else if ( ! "dest" in opt[n] ) {
        printf("No destination for the command line option.\n")>"/dev/stderr"
        _assert_exit = 1
        exit 1
    } else if ( ! "has_arg" in opt[n] ) {
        printf("Specify `has_arg` for option.\n")>"/dev/stderr"
        _assert_exit = 1
        exit 1
    }
    # Apparently, all is fine now. 
    # For those interested, what exactly has been achieved? 
    if ( opt_debug == "y") {
        for ( key in opt[n] ) {
            s = sprintf("ngetopt: regopt: opt[\"%s\"][\"%s\"] = ", n, key)
            if ( isarray(opt[n][key]) ) {
                for (v=1;v<=length(opt[n][key]);v++) {
                    printf "%s\"%s\"\n", s, opt[n][key][v] >"/dev/stderr"
                }
            } else {
                printf "%s\"%s\"\n", s, opt[n][key] >"/dev/stderr"
            }
        }
    }
}

function parseopt(opt,          i, nextopt, opt_flag, argind, shopt, argopt, 
                                optstring, f, c, out) {
    # TODO: Commentify the variable reservation in the function declaration. 
    if (opt_debug == "y") {
        printf("ngetopt: parseopt: Processing command line: ARGV[%s]=\"%s\"",
               0, ARGV[0]) >"/dev/stderr"
        for (i=1;i<=ARGC-1;i++) {
            printf "; ARGV[%s]=\"%s\"", i, ARGV[i] >"/dev/stderr"
        }
        printf ".\n" >"/dev/stderr"
    }
    argind=1
    if (1 in config) {} # Is an array now...
                        # This is a globally available array for debugging/
                        # testing purposes.
    while (argind in ARGV) {
        #printf "argind: %s ARGV[argind] = %s\n", argind, ARGV[argind]>"/dev/stderr"
        argopt="n"      # registers whether the argument comes from `argind+1`.
        if (opt_debug == "y") {
            printf("ngetopt: parseopt: ARGV[%s]=\"%s\": ",
                   argind, ARGV[argind]) >"/dev/stderr"
        }
        if (ARGV[argind] ~ /^(--|[^-].*)$/) {
            if (opt_debug == "y") {
                printf("No option. The rest left as file.\n",
                       ARGV[argind]) >"/dev/stderr"
            }
            if (ARGV[argind] == "--") {
                delete ARGV[argind]
            }
            break
        } else if (ARGV[argind] ~ /^-[[:alpha:]]/) {
            # A short option! Some juggling with concatenated short options. 
            optstring=substr(ARGV[argind], 2, length(ARGV[argind]))
            while (length(optstring)>0) {
                # Looping over the chars in optstring, using "shopt"
                # (short option) as index.
                shopt = substr(optstring, 1, 1)
                if (length(optstring)==1) {
                    nextopt = "--"
                    # Overriding previous assignment if necessary:
                    if (argind+1 in ARGV) {
                        nextopt = ARGV[argind+1]
                        argopt="y"
                    }
                } else {
                    # If argument is needed, it will come from the rest of the
                    # current shell word.
                    nextopt = substr(optstring, 2, length(optstring))
                }
                opt_flag = getopt(shopt, nextopt)
                if (opt_flag == "file") {
                    printf("ngetopt: parseopt: Unknown option %s, exiting.\n",
                           shopt) >"/dev/stderr"
                    _assert_exit = 1
                    exit 1
                } else if (opt_flag == "opt_noarg") {
                    if (nextopt == "--" || length(optstring)==1) {
                        if (argind in ARGV){
                            delete ARGV[argind]
                            argind++
                        }
                        break
                    } else {
                        optstring = nextopt
                    }
                } else if (opt_flag == "opt_arg") {
                    delete ARGV[argind]
                    argind+=1
                    optstring=""
                    if (argopt == "y") {
                        # The argument came from the next `ARGV`. 
                        delete ARGV[argind]
                        argind+=1
                    }
                    break
                } else {
                    # We really should not be here. 
                    printf("Illegal state. Exiting\n") >"/dev/stderr"
                    _assert_exit = 1
                    exit 1
                }
            }
        } else {
            # A long option. 
            if (argind+1 in ARGV) {
                nextopt = ARGV[argind+1]
            } else {
                nextopt = "--"
            }
            opt_flag = getopt(ARGV[argind], nextopt)
            if (opt_flag == "file") {
                if (opt_debug == "y") {
                    printf("No option. The rest left as file.\n",
                           ARGV[argind]) >"/dev/stderr"
                }
                break
            }
            else if (opt_flag == "opt_noarg") {
                delete ARGV[argind]
                argind+=1
            }
            else if (opt_flag == "opt_arg") {
                delete ARGV[argind]
                delete ARGV[argind+1]
                argind+=2
            }
        continue
        }
    }

    # Done processing. Tricking the gawk syntax parser into picking
    # up possible changes to user modifiable variables that awk 
    # explicitly needs to be aware of: 

    BINMODE = SYMTAB["BINMODE"]
    CONVFMT = SYMTAB["CONVFMT"]
    FIELDWIDTHS = SYMTAB["FIELDWIDTHS"]
    FPAT = SYMTAB["FPAT"]
    FS = SYMTAB["FS"]
    IGNORECASE = SYMTAB["IGNORECASE"]
    LINT = SYMTAB["LINT"]
    OFMT = SYMTAB["OFMT"]
    OFS = SYMTAB["OFS"]
    ORS = SYMTAB["ORS"]
    PREC = SYMTAB["PREC"]
    ROUNDMODE = SYMTAB["ROUNDMODE"]
    RS = SYMTAB["RS"]
    SUBSEP = SYMTAB["SUBSEP"]
    TEXTDOMAIN = SYMTAB["TEXTDOMAIN"]
    
    # Printing a summary if desired: 
    if (opt_debug ~ /^(y|t)$/) {
        if (opt_debug == "t") { out = "/dev/stdout" }
        else { out = "/dev/stderr" }
        for (c in config) {
            printf("ngetopt: parseopt: result: option: %s = \"%s\"\n",
                    c, SYMTAB[c]) >out
        }
        for (f in ARGV) {
            if (f>0) {
                printf("ngetopt: parseopt: result: file: \x27%s\x27\n",
                       ARGV[f]) >out
            }
        }
        if (length(ARGV)=="1") {
            printf("ngetopt: parseopt: result: file: <NONE>\n")>out
        }
    }
}

function getopt(option, nextopt,            o, flag, opt_flag, val, failstr, i, pval) {
    opt_flag="file"
    for ( o in opt ) {
        if (option != "-"opt[o]["short"] && \
            option != "--"opt[o]["long"] && \
            option != opt[o]["short"]) {
                continue
        }
        if (opt[o]["has_arg"] == "1") {
            # Option has no argument
            flag = opt[o]["flag"]
            val = opt[o]["val"]==""?"yes":opt[o]["val"]
            SYMTAB[flag] = val
            if (opt_debug ~ /^(y|t)$/) { config[flag]=1 }
            if (opt_debug == "y") {
                printf("%s = \"%s\"\n",
                       flag, SYMTAB[flag]) >"/dev/stderr"
            }
            opt_flag="opt_noarg"
            break
        } else if (opt[o]["has_arg"] == "0") {
            # Option needs argument, verify it has one. 
            flag = opt[o]["flag"]
            if (nextopt ~ /^(|--)$/) {
                printf("Expecting argument to `%s`, none received. Exiting.\n", 
                       option) >"/dev/stderr"
                _assert_exit = 1
                exit 1
            }
            if ("vals" in opt[o]){
                # Only some values are allowed. 
                # Check if the provided value is one of the possible ones. 
                pval = 1
                for (i in opt[o]["vals"]) {
                    failstr=sprintf("%s%s", failstr==""?"":failstr", ", "«"i"»")
                    if (nextopt == i) {
                        pval = 0
                        continue
                    }
                }
                if (pval == 1) {
                    printf("Argument «%s» expects one of the following values: %s. ",
                           option, failstr)>"/dev/stderr"
                    printf("Received: «%s». Exiting.\n", nextopt) >"/dev/stderr"
                    _assert_exit = 1
                    exit 1
                }
            }
            SYMTAB[flag] = nextopt
            if (opt_debug ~ /^(y|t)$/) { config[flag]=1 }
            opt_flag="opt_arg"
            if (opt_debug == "y") {
                printf("%s = \"%s\"\n", flag, SYMTAB[flag]) >"/dev/stderr"
            }
            break
        } 
    }
    return opt_flag
}

function usage(         helpstr,p,n,o,len) {
    # TODO: Some nice formatting with columns...
    # TODO: Generate Usage according to GNU-specs. 
    for (o in opt) {
        if ("long" in opt[o] && length(opt[o]["long"]) > len)
            len = length(opt[o]["long"])
    }
    len = len + 2
    split(ENVIRON["_"], p, "/")
    helpstr = sprintf("\nUsage of %s:\n\n", p[length(p)])
    for (n in opt) {
        helpstr = sprintf("%s    %-*s %s  # %s\n",
                helpstr,
                len - opt[n]["long"],
                "long" in opt[n] ? "--"opt[n]["long"] : "",
                "short" in opt[n] ? "-"opt[n]["short"] : "  ",
                opt[n]["desc"])
    }
    return helpstr
}

END {
    # Need an END{}-block, as the exit in an included file does not get
    # propagated to the program, and the program will be waiting for input.
    if (_assert_exit)
        exit _assert_exit
}

