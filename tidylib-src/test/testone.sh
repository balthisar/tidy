#! /bin/sh

#
# testone.sh - execute a single testcase
#
# (c) 1998-2001 (W3C) MIT, INRIA, Keio University
# See tidy.c for the copyright notice.
#
# <URL:http://tidy.sourceforge.net/>
#
# CVS Info:
#
#    $Author: creitzel $
#    $Date: 2002/07/09 21:06:09 $
#    $Revision: 1.5.2.1 $
#
# set -x

VERSION='$Id'

echo Testing $1

set +f

TIDY=../bin/tidy
INFILES=./input/in_$1.*ml
CFGFILE=./input/cfg_$1.txt
OUTFILE=./output/out_$1.html

TIDYFILE=./tmp/out_$1.html
MSGFILE=./tmp/msg_$1.txt
DIFFOUT=./tmp/diff_$1.txt

unset HTML_TIDY

REPORTWARN=$2
shift
if [ $REPORTWARN ]
then
  shift
fi

# Remove any pre-exising test outputs
for INFIL in $MSGFILE $TIDYFILE $DIFFOUT
do
  if [ -f $INFIL ]
  then
    rm $INFIL
  fi
done

for INFILE in $INFILES
do
    if [ -r $INFILE ]
    then
      break
    fi
done

# If no test specific config file, use default.
if [ ! -f $CFGFILE ]
then
  CFGFILE=./input/cfg_default.txt
fi

$TIDY -f $MSGFILE -config $CFGFILE "$@" --tidy-mark no $INFILE > $TIDYFILE
STATUS=$?

if [ $STATUS -gt 1 ]
then
  cat $MSGFILE
  exit $STATUS
fi

if [ $REPORTWARN ] 
then
  if [ $STATUS -gt 0 ]
  then
    cat $MSGFILE
    exit $STATUS
  fi
fi


if [ ! -s $TIDYFILE ]
then
  cat $MSGFILE
  exit 1
fi

if [ -f $OUTFILE ]
then
  diff $TIDYFILE $OUTFILE > $DIFFOUT

  # Not a valid shell test
  if [ -s diff.txt ]
  then
    cat $MSGFILE
    cat $DIFFOUT
    exit 1
  fi
fi

exit 0

