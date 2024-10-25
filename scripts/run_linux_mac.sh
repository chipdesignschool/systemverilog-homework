#!/bin/sh

#-----------------------------------------------------------------------------

waveform_viewer="gtkwave"
# waveform_viewer="surfer"
#-----------------------------------------------------------------------------

simulate_rtl()
{
    if ! command -v iverilog > /dev/null 2>&1
    then
        printf "%s\n"                                                \
               "ERROR: Icarus Verilog (iverilog) is not in the path" \
               "or cannot be run."                                   \
               "See README.md file in the package directory"         \
               "for the instructions how to install Icarus."         \
               "Press enter"

        read -r enter
        exit 1
    fi

    rm -f dump.vcd
    rm -f log.txt

    if [ -d testbenches ]
    then
        if [ -n "$GENSEED" ]; then
            iverilog -g2005-sv        \
                    -o sim.out       \
                    -I testbenches   \
                    testbenches/*.sv \
                    black_boxes/*.sv \
                    ./*.sv           \
                    >> log.txt 2>&1  \
                    && vvp sim.out   \
                    >> log.txt 2>&1  \
                    +SEED=$GENSEED
        else
            iverilog -g2005-sv        \
                    -o sim.out       \
                    -I testbenches   \
                    testbenches/*.sv \
                    black_boxes/*.sv \
                    ./*.sv           \
                    >> log.txt 2>&1  \
                    && vvp sim.out   \
                    >> log.txt 2>&1
        fi
        rm -f sim.out
    elif [ -f tb.sv ]
    then
        if [ -n "$GENSEED" ]; then
            iverilog -g2005-sv       \
                    -o sim.out      \
                    ./*sv           \
                    >> log.txt 2>&1 \
                    && vvp sim.out  \
                    >> log.txt 2>&1 \
                    +SEED=$GENSEED
        else
            iverilog -g2005-sv       \
                    -o sim.out      \
                    ./*sv           \
                    >> log.txt 2>&1 \
                    && vvp sim.out  \
                    >> log.txt 2>&1 
        fi
        rm -f sim.out
    else
        for d in */
        do
            if [ ! -d "$d"testbenches ]
            then
                if [ -n "$GENSEED" ]; then
                    iverilog -g2005-sv          \
                            -o "$d"sim.out     \
                            "$d"*.sv           \
                            >> log.txt 2>&1    \
                            && vvp "$d"sim.out \
                            >> log.txt 2>&1    \
                            +SEED=$GENSEED
                else
                    iverilog -g2005-sv          \
                            -o "$d"sim.out     \
                            "$d"*.sv           \
                            >> log.txt 2>&1    \
                            && vvp "$d"sim.out \
                            >> log.txt 2>&1
                fi
                rm -f "$d"sim.out
            fi
        done
    fi


    # Don't print iverilog warning about not supporting constant selects
    sed -i '/sorry: constant selects/d' log.txt
    # Don't print $finish calls to make log cleaner
    sed -i '/finish called/d' log.txt
}

#-----------------------------------------------------------------------------

lint_code()
{
    lint_rules_path="../.lint_rules.vlt"

    if command -v verilator > /dev/null 2>&1
    then
        i=0

        while [ "$i" -lt 3 ]
        do
            [ -f $lint_rules_path ] && break
            lint_rules_path=../$lint_rules_path
            i=$((i + 1))
        done

        if ! [ -f $lint_rules_path ]
        then
            printf "%s\n"                                             \
                   "ERROR: Config file for Verilator cannot be found" \
                   "Press enter"

            read -r enter
            exit 1
        else
            rm -f lint.txt

            if [ -d testbenches ]
            then
                verilator --lint-only      \
                          -Wall            \
                          --timing         \
                          $lint_rules_path \
                          -Itestbenches    \
                          -Iblack_boxes    \
                          testbenches/*.sv \
                          ./*.sv           \
                          -top tb          \
                          >> lint.txt 2>&1

            elif [ -f tb.sv ]
            then
                verilator --lint-only      \
                          -Wall            \
                          --timing         \
                          $lint_rules_path \
                          ./*.sv           \
                          -top tb          \
                          >> lint.txt 2>&1
            else
                for d in */
                do
                    if [ ! -d "$d"testbenches ]
                    then
                        {
                            printf "==============================================================\n"
                            printf "Task: %s\n" "$d"
                            printf "==============================================================\n\n"
                        } >> lint.txt

                        verilator --lint-only      \
                                  -Wall            \
                                  --timing         \
                                  $lint_rules_path \
                                  "$d"*.sv         \
                                  -top testbench   \
                                  >> lint.txt 2>&1
                    fi
                done
            fi

            sed -i '/- Verilator:/d' lint.txt
            sed -i '/- V e r i l a t i o n/d' lint.txt
        fi
    else
        printf "%s\n"                                                             \
               "ERROR [-l | --lint]: Verilator is not in the path"                \
               "or cannot be run."                                                \
               "See README.md file in the package directory for the instructions" \
               "how to install Verilator."                                        \
               "Press enter"

        read -r enter
        exit 1
    fi
}

#-----------------------------------------------------------------------------

run_assembly()
{
    rars_jar=rars1_6.jar

    #  nc                              - Copyright notice will not be displayed
    #  a                               - assembly only, do not simulate
    #  ae<n>                           - terminate RARS with integer exit code if an assemble error occurs
    #  dump .text HexText program.hex  - dump segment .text to program.hex file in HexText format

    rars_args="nc a ae1 dump .text HexText program.hex"

    if command -v rars > /dev/null 2>&1
    then
        rars_cmd=rars
    else
        if ! command -v java > /dev/null 2>&1
        then
            printf "%s\n"                                             \
                   "ERROR: java is not in the path or cannot be run." \
                   "java is needed to run RARS,"                      \
                   "a RISC-V instruction set simulator."              \
                   "You can install it using"                         \
                   "'sudo apt-get install default-jre'"               \
                   "Press enter"

            read -r enter
            exit 1
        fi

        rars_cmd="java -jar ../../bin/$rars_jar"
    fi

    if ! $rars_cmd $rars_args program.s >> log.txt 2>&1
    then
        printf "ERROR: assembly failed. See log.txt.\n"
        grep Error log.txt
        printf "Press enter\n"
        read -r enter
        exit 1
    fi
}

#-----------------------------------------------------------------------------

open_waveform()
{
    if [ -f dump.vcd ]
    then

        if [ "$waveform_viewer" = "gtkwave" ]
        then
            if [ -f gtkwave.tcl ]
            then
                gtkwave dump.vcd --script gtkwave.tcl &
            else
                gtkwave dump.vcd &
            fi
        elif [ "$waveform_viewer" = "surfer" ]
        then
            if [ -f state.ron ]
            then
                surfer dump.vcd --state-file state.ron &
            else
                surfer dump.vcd &
            fi
        fi

    else
        printf "No dump.vcd file found\n"
        printf "Check that it's generated in testbench for this exercise\n\n"
    fi
}

#-----------------------------------------------------------------------------

if [ -f program.s ] ; then
    run_assembly
fi


RUN_LINT=false
OPEN_WAVE=false
GENERATE_RANDOM=false

# Parse options and set flags
while getopts ":lw-:" opt; do
    case $opt in
        -)
            case $OPTARG in
                lint)
                    RUN_LINT=true;;
                wave)
                    OPEN_WAVE=true;;
                random)
                    GENERATE_RANDOM=true;;
                seed=*)
                    SEED_VALUE="${OPTARG#*=}";;
                *)
                    printf "ERROR: Unknown option\n"
                    printf "Press enter\n"
                    read -r enter
                    exit 1;;
            esac;;
        l)
            RUN_LINT=true;;
        w)
            OPEN_WAVE=true;;
        r)
            GENERATE_RANDOM=true;;
        ?)
            printf "ERROR: Unknown option\n"
            printf "Press enter\n"
            read -r enter
            exit 1;;
    esac
done

# Set seed if `--seed` is specified; if `--random` is also set, `--seed` takes precedence
if [ -n "$SEED_VALUE" ]; then
    GENSEED=$SEED_VALUE
    echo "Using seed value $GENSEED"
elif [ "$GENERATE_RANDOM" = true ]; then
    GENSEED=$RANDOM
    echo "Using seed value $GENSEED"
fi

# Run the main simulation
simulate_rtl

# Run post-simulation actions
if [ "$RUN_LINT" = true ]; then
    lint_code
fi

if [ "$OPEN_WAVE" = true ]; then
    open_waveform
fi

#-----------------------------------------------------------------------------

grep -e PASS -e FAIL -e ERROR -e Error -e error -e Timeout -e "++" log.txt | \
sed -e 's/PASS/\x1b[0;32m&\x1b[0m/g' \
    -e 's/FAIL/\x1b[0;31m&\x1b[0m/g' \
    -e 's/ERROR/\x1b[0;31m&\x1b[0m/g' \
    -e 's/Error/\x1b[0;31m&\x1b[0m/g' \
    -e 's/error/\x1b[0;31m&\x1b[0m/g' \
    -e 's/Timeout/\x1b[0;33m&\x1b[0m/g' \
    -e 's/++/\x1b[0;34m&\x1b[0m/g'
