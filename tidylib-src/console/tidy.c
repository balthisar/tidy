/*
  cmmdline.c - HTML Tidy command line driver

  Copyright (c) 1998-2002 World Wide Web Consortium
  (Massachusetts Institute of Technology, Institut National de
  Recherche en Informatique et en Automatique, Keio University).
  All Rights Reserved.

  CVS Info :

    $Author: creitzel $ 
    $Date: 2002/11/02 20:10:47 $ 
    $Revision: 1.1.2.7 $ 
*/

#include "tidy.h"

uint  contentErrors = 0;
uint  contentWarnings = 0;
uint  optionErrors = 0;
uint  accessWarnings = 0;

FILE* errout = null;  /* set to stderr or stdout */

void help( TidyDoc tdoc, ctmbstr prog )
{
    printf( "%s [option...] [file...]\n", prog );
    printf( "Utility to clean up and pretty print HTML/XHTML/XML\n");
    printf( "see http://tidy.sourgeforge.net/\n");
    printf( "\n");

#ifdef PLATFORM_NAME
    printf( "Options for HTML Tidy for %s released on %s:\n",
             PLATFORM_NAME, tidyReleaseDate() );
#else
    printf( "Options for HTML Tidy released on %s:\n", tidyReleaseDate() );
#endif
    printf( "\n");

    printf( "Processing directives\n");
    printf( "---------------------\n");
    printf( "  -indent  or -i    to indent element content\n");
    printf( "  -omit    or -o    to omit optional end tags\n");
    printf( "  -wrap <column>    to wrap text at the specified <column> (default is 68)\n");
    printf( "  -upper   or -u    to force tags to upper case (default is lower case)\n");
    printf( "  -clean   or -c    to replace FONT, NOBR and CENTER tags by CSS\n");
    printf( "  -bare    or -b    to strip out smart quotes and em dashes, etc.\n");
    printf( "  -numeric or -n    to output numeric rather than named entities\n");
    printf( "  -errors  or -e    to only show errors\n");
    printf( "  -quiet   or -q    to suppress nonessential output\n");
    printf( "  -xml              to specify the input is well formed XML\n");
    printf( "  -asxml            to convert HTML to well formed XHTML\n");
    printf( "  -asxhtml          to convert HTML to well formed XHTML\n");
    printf( "  -ashtml           to force XHTML to well formed HTML\n");

/* TRT */
#if SUPPORT_ACCESSIBILITY_CHECKS
    printf( "  -access <level>   to do additional accessibility checks (<level> = 1, 2, 3)\n");
#endif

    printf( "\n");

    printf( "Character encodings\n");
    printf( "-------------------\n");
    printf( "  -raw              to output values above 127 without conversion to entities\n");
    printf( "  -ascii            to use US-ASCII for output, ISO-8859-1 for input\n");
    printf( "  -latin1           to use ISO-8859-1 for both input and output\n");
    printf( "  -iso2022          to use ISO-2022 for both input and output\n");
    printf( "  -utf8             to use UTF-8 for both input and output\n");
    printf( "  -mac              to use MacRoman for input, US-ASCII for output\n");

#if SUPPORT_UTF16_ENCODINGS
    printf( "  -utf16le          to use UTF-16LE for both input and output\n");
    printf( "  -utf16be          to use UTF-16BE for both input and output\n");
    printf( "  -utf16            to use UTF-16 for both input and output\n");
#endif

    printf( "  -win1252          to use Windows-1252 for input, US-ASCII for output\n");

#if SUPPORT_ASIAN_ENCODINGS
    printf( "  -big5             to use Big5 for both input and output\n"); /* #431953 - RJ */
    printf( "  -shiftjis         to use Shift_JIS for both input and output\n"); /* #431953 - RJ */
    printf( "  -language <lang>  to set the two-letter language code <lang> (for future use)\n"); /* #431953 - RJ */
#endif
    printf( "\n");

    printf( "File manipulation\n");
    printf( "-----------------\n");
    printf( "  -config <file>    to set configuration options from the specified <file>\n");
    printf( "  -f      <file>    to write errors to the specified <file>\n");
    printf( "  -modify or -m     to modify the original input files\n");
    printf( "\n");

    printf( "Miscellaneous\n");
    printf( "-------------\n");
    printf( "  -version  or -v   to show the version of Tidy\n");
    printf( "  -help, -h or -?   to list the command line options\n");
    printf( "  -help-config      to list all configuration options\n");
    printf( "  -show-config      to list the current configuration settings\n");
    printf( "\n");
    printf( "Use --blah blarg for any configuration option \"blah\" with argument \"blarg\"\n");
    printf( "\n");

    printf( "Input/Output default to stdin/stdout respectively\n");
    printf( "Single letter options apart from -f may be combined\n");
    printf( "as in:  tidy -f errs.txt -imu foo.html\n");
    printf( "For further info on HTML see http://www.w3.org/MarkUp\n");
    printf( "\n");
}

#define kMaxValFieldWidth 40
static const char* fmt = "%-27.27s %-9.9s  %-40.40s\n";
static const char* valfmt = "%-27.27s %-9.9s %-1.1s%-39.39s\n";
static const char* ul 
        = "=================================================================";

void optionhelp( TidyDoc tdoc, ctmbstr prog )
{
    TidyIterator pos = tidyGetOptionList( tdoc );

    printf( "\nConfiguration File Settings:\n\n" );
    printf( fmt, "Name", "Type", "Allowable values" );
    printf( fmt, ul, ul, ul );

    while ( pos )
    {
        TidyOption topt = tidyGetNextOption( tdoc, &pos );
        TidyOptionId optId = tidyOptGetId( topt );
        TidyOptionType optTyp = tidyOptGetType( topt );

        tmbstr name = (tmbstr) tidyOptGetName( topt );
        tmbstr type = "String";
        tmbchar tempvals[80] = {0};
        tmbstr vals = &tempvals[0];

        if ( tidyOptIsReadOnly(topt) )
            continue;

        /* Handle special cases first.
        */
        switch ( optId )
        {
        case TidyIndentContent:
        case TidyOutputBOM:
            type = "AutoBool";
            vals = "auto, y/n, yes/no, t/f, true/false, 1/0";
            break;

        case TidyDuplicateAttrs:
            type = "enum";
            vals = "keep-first, keep-last";
            break;

        case TidyDoctype:
            type = "DocType";
            vals = "auto, omit, strict, loose, transitional,";
            printf( fmt, name, type, vals );
            name = "";
            type = "";
            vals = "user specified fpi (string)";
            break;

        case TidyCSSPrefix:
            type = "Name";
            vals = "CSS1 selector";
            break;

        case TidyInlineTags:
        case TidyBlockTags:
        case TidyEmptyTags:
        case TidyPreTags:
            type = "Tag names";
            vals = "tagX, tagY, ...";
            break;

        case TidyCharEncoding:
        case TidyInCharEncoding:
        case TidyOutCharEncoding:
            type = "Encoding";
            vals = "ascii, latin1, raw, utf8, iso2022, mac,";
            printf( fmt, name, type, vals );
            name = "";
            type = "";

#if SUPPORT_UTF16_ENCODINGS
            vals = "utf16le, utf16be, utf16,";
            printf( fmt, name, type, vals );
#endif
#if SUPPORT_ASIAN_ENCODINGS
            vals = "win1252, big5, shiftjis";
#else
            vals = "win1252";
#endif
            break;

        /* General case will handle remaining */
        default:
            switch ( optTyp )
            {
            case TidyBoolean:
                type = "Boolean";
                vals = "y/n, yes/no, t/f, true/false, 1/0";
                break;

            case TidyInteger:
                type = "Integer";
                if ( optId == TidyWrapLen )
                    vals = "0 (no wrapping), 1, 2, ...";
                else
                    vals = "0, 1, 2, ...";
                break;

            case TidyString:
                type = "String";
                vals = "-";
                break;
            }
        }

        if ( *name || *type || *vals )
            printf( fmt, name, type, vals );
    }
}

void optionvalues( TidyDoc tdoc, ctmbstr prog )
{
    TidyIterator pos = tidyGetOptionList( tdoc );

    printf( "\nConfiguration File Settings:\n\n" );
    printf( fmt, "Name", "Type", "Current Value" );
    printf( fmt, ul, ul, ul );

    while ( pos )
    {
        TidyOption topt = tidyGetNextOption( tdoc, &pos );
        TidyOptionId optId = tidyOptGetId( topt );
        TidyOptionType optTyp = tidyOptGetType( topt );
        Bool isReadOnly = tidyOptIsReadOnly( topt );

        Bool bval = no;
        ctmbstr sval = null;
        uint ival = 0;

        tmbstr name = (tmbstr) tidyOptGetName( topt );
        tmbstr type = "String";
        tmbchar tempvals[80] = {0};
        tmbstr vals = &tempvals[0];
        tmbstr ro   = ( isReadOnly ? "*" : "" );

        /* Handle special cases first.
        */
        switch ( optId )
        {
        case TidyIndentContent:
        case TidyOutputBOM:
            type = "AutoBool";
            vals = (tmbstr) tidyOptGetCurrPick( tdoc, optId );
            break;

        case TidyDuplicateAttrs:
            type = "enum";
            vals = (tmbstr) tidyOptGetCurrPick( tdoc, optId );
            break;

        case TidyDoctype:
            sval = (tmbstr) tidyOptGetCurrPick( tdoc, TidyDoctypeMode );
            type = "DocType";
            if ( !sval || *sval == '*' )
                sval = (tmbstr) tidyOptGetValue( tdoc, TidyDoctype );
            vals = (tmbstr) sval;
            break;

        case TidyCSSPrefix:
            type = "Name";
            vals = (tmbstr) tidyOptGetValue( tdoc, TidyCSSPrefix );
            break;

        case TidyInlineTags:
        case TidyBlockTags:
        case TidyEmptyTags:
        case TidyPreTags:
            {
                TidyIterator pos = tidyOptGetDeclTagList( tdoc );
                type = "Tag names";
                while ( pos )
                {
                    vals = (tmbstr) tidyOptGetNextDeclTag(tdoc, optId, &pos);
                    if ( pos )
                    {
                        if ( *name )
                            printf( valfmt, name, type, ro, vals );
                        else
                            printf( fmt, name, type, vals );
                        name = "";
                        type = "";
                    }
                }
            }
            break;

        case TidyCharEncoding:
        case TidyInCharEncoding:
        case TidyOutCharEncoding:
            type = "Encoding";
            sval = tidyOptGetEncName( tdoc, optId );
            vals = (tmbstr) sval;
            break;

        /* General case will handle remaining */
        default:
            switch ( optTyp )
            {
            case TidyBoolean:
                type = "Boolean";   /* curr pick handles inverse */
                vals = (tmbstr) tidyOptGetCurrPick( tdoc, optId );
                break;

            case TidyInteger:
                type = "Integer";
                ival = tidyOptGetInt( tdoc, optId );
                sprintf( tempvals, "%d", ival );
                break;

            case TidyString:
                type = "String";
                vals = (tmbstr) tidyOptGetValue( tdoc, optId );
                break;
            }
        }

        if ( *name || *type || *vals )
        {
            if ( ! vals )
                vals = "";
            if ( *name )
                printf( valfmt, name, type, ro, vals );
            else
                printf( fmt, name, type, vals );
        }
    }

    printf( "\n\nValues marked with an *asterisk are calculated \n"
            "internally by HTML Tidy\n\n" );
}

void version( TidyDoc tdoc, ctmbstr prog )
{
#ifdef PLATFORM_NAME
    printf( "HTML Tidy for %s released on %s\n",
             PLATFORM_NAME, tidyReleaseDate() );
#else
    printf( "HTML Tidy released on %s\n", tidyReleaseDate() );
#endif
}

void unknownOption( TidyDoc tdoc, uint c )
{
    fprintf( errout, "HTML Tidy: unknown option: %c\n", c );
}

int main( int argc, char** argv )
{
    ctmbstr prog = argv[0];
    ctmbstr cfgfil = null, errfil = null, htmlfil = null;
    TidyDoc tdoc = tidyCreate();
    int status = 0;

    errout = stderr;  /* initialize to stderr */

    /* look for env var "HTML_TIDY" */
    /* then for ~/.tidyrc (on platforms defining $HOME) */

    if ( cfgfil = getenv("HTML_TIDY") )
        tidyLoadConfig( tdoc, cfgfil );
#ifdef SUPPORT_GETPWNAM
    else
        tidyLoadConfig( tdoc, "~/.tidyrc" );
#endif /* SUPPORT_GETPWNAM */

    /* read command line */
    while ( argc > 0 )
    {
        if (argc > 1 && argv[1][0] == '-')
        {
            /* support -foo and --foo */
            ctmbstr arg = argv[1] + 1;

            if ( strcasecmp(arg, "xml") == 0)
                tidyOptSetBool( tdoc, TidyXmlTags, yes );

            else if ( strcasecmp(arg,   "asxml") == 0 ||
                      strcasecmp(arg, "asxhtml") == 0 )
            {
                tidyOptSetBool( tdoc, TidyXhtmlOut, yes );
            }
            else if ( strcasecmp(arg,   "ashtml") == 0 )
                tidyOptSetBool( tdoc, TidyHtmlOut, yes );

            else if ( strcasecmp(arg, "indent") == 0 )
            {
                tidyOptSetInt( tdoc, TidyIndentContent, TidyAutoState );
            }
            else if ( strcasecmp(arg, "omit") == 0 )
                tidyOptSetBool( tdoc, TidyHideEndTags, yes );

            else if ( strcasecmp(arg, "upper") == 0 )
                tidyOptSetBool( tdoc, TidyUpperCaseTags, yes );

            else if ( strcasecmp(arg, "clean") == 0 )
                tidyOptSetBool( tdoc, TidyMakeClean, yes );

            else if ( strcasecmp(arg, "bare") == 0 )
                tidyOptSetBool( tdoc, TidyMakeBare, yes );

            else if ( strcasecmp(arg, "raw") == 0     ||
                      strcasecmp(arg, "ascii") == 0   ||
                      strcasecmp(arg, "latin1") == 0  ||
                      strcasecmp(arg, "utf8") == 0    ||
                      strcasecmp(arg, "iso2022") == 0 ||
#if SUPPORT_UTF16_ENCODINGS
                      strcasecmp(arg, "utf16le") == 0 ||
                      strcasecmp(arg, "utf16be") == 0 ||
                      strcasecmp(arg, "utf16") == 0   ||
#endif
#if SUPPORT_ASIAN_ENCODINGS
                      strcasecmp(arg, "shiftjis") == 0 ||
                      strcasecmp(arg, "big5") == 0     ||
#endif
                      strcasecmp(arg, "mac") == 0     ||
                      strcasecmp(arg, "win1252") == 0 )
            {
                tidySetCharEncoding( tdoc, arg );
            }
            else if ( strcasecmp(arg, "numeric") == 0 )
                tidyOptSetBool( tdoc, TidyNumEntities, yes );

            else if ( strcasecmp(arg, "modify") == 0 ||
                      strcasecmp(arg, "change") == 0 ||  /* obsolete */
                      strcasecmp(arg, "update") == 0 )   /* obsolete */
            {
                tidyOptSetBool( tdoc, TidyWriteBack, yes );
            }
            else if ( strcasecmp(arg, "errors") == 0 )
                tidyOptSetBool( tdoc, TidyShowMarkup, no );

            else if ( strcasecmp(arg, "quiet") == 0 )
                tidyOptSetBool( tdoc, TidyQuiet, yes );

            else if ( strcasecmp(arg, "help") == 0 ||
                      strcasecmp(arg,    "h") == 0 || *arg == '?' )
            {
                help( tdoc, prog );
                tidyRelease( tdoc );
                return 0; /* success */
            }
            else if ( strcasecmp(arg, "help-config") == 0 )
            {
                optionhelp( tdoc, prog );
                tidyRelease( tdoc );
                return 0; /* success */
            }
            else if ( strcasecmp(arg, "show-config") == 0 )
            {
                optionvalues( tdoc, prog );
                tidyRelease( tdoc );
                return 0; /* success */
            }
            else if ( strcasecmp(arg, "config") == 0 )
            {
                if ( argc >= 3 )
                {
                    tidyLoadConfig( tdoc, argv[2] );
                    --argc;
                    ++argv;
                }
            }

#if SUPPORT_ASIAN_ENCODINGS
            else if ( strcasecmp(arg, "language") == 0 ||
                      strcasecmp(arg,     "lang") == 0 )
            {
                if ( argc >= 3 )
                {
                    tidyOptSetValue( tdoc, TidyLanguage, argv[2] );
                    --argc;
                    ++argv;
                }
            }
#endif

            else if ( strcasecmp(arg,  "file") == 0 ||
                      strcasecmp(arg, "-file") == 0 ||
                      strcasecmp(arg,     "f") == 0 )
            {
                if ( argc >= 3 )
                {
                    errfil = argv[2];
                    errout = tidySetErrorFile( tdoc, errfil );
                    --argc;
                    ++argv;
                }
            }
            else if ( strcasecmp(arg,  "wrap") == 0 ||
                      strcasecmp(arg, "-wrap") == 0 ||
                      strcasecmp(arg,     "w") == 0 )
            {
                if ( argc >= 3 )
                {
                    uint wraplen = 0;
                    sscanf( argv[2], "%d", &wraplen );
                    tidyOptSetInt( tdoc, TidyWrapLen, wraplen );
                    --argc;
                    ++argv;
                }
            }
            else if ( strcasecmp(arg,  "version") == 0 ||
                      strcasecmp(arg, "-version") == 0 ||
                      strcasecmp(arg,        "v") == 0 )
            {
                version( tdoc, prog );
                tidyRelease( tdoc );
                return 0;  /* success */

            }
            else if ( strncmp(argv[1], "--", 2 ) == 0)
            {
                if ( tidyOptParseValue(tdoc, argv[1]+2, argv[2]) )
                {
                    ++argv;
                    --argc;
                }
            }

#if SUPPORT_ACCESSIBILITY_CHECKS
            else if ( strcasecmp(arg, "access") == 0 )
            {
                if ( argc >= 3 )
                {
                    uint acclvl = 0;
                    sscanf( argv[2], "%d", &acclvl );
                    tidyOptSetInt( tdoc, TidyAccessibilityCheckLevel, acclvl );
                    --argc;
                    ++argv;
                }
            }
#endif

            else
            {
                uint c;
                ctmbstr s = argv[1];

                while ( c = *++s )
                {
                    switch ( c )
                    {
                    case 'i':
                        tidyOptSetInt(tdoc, TidyIndentContent, TidyAutoState);
                        break;

                    case 'o':
                        tidyOptSetBool( tdoc, TidyHideEndTags, yes );
                        break;

                    case 'u':
                        tidyOptSetBool( tdoc, TidyUpperCaseTags, yes );
                        break;

                    case 'c':
                        tidyOptSetBool( tdoc, TidyMakeClean, yes );
                        break;

                    case 'b':
                        tidyOptSetBool( tdoc, TidyMakeBare, yes );
                        break;

                    case 'n':
                        tidyOptSetBool( tdoc, TidyNumEntities, yes );
                        break;

                    case 'm':
                        tidyOptSetBool( tdoc, TidyWriteBack, yes );
                        break;

                    case 'e':
                        tidyOptSetBool( tdoc, TidyShowMarkup, no );
                        break;

                    case 'q':
                        tidyOptSetBool( tdoc, TidyQuiet, yes );
                        break;

                    default:
                        unknownOption( tdoc, c );
                        break;
                    }
                }
            }

            --argc;
            ++argv;
            continue;
        }

        if ( argc > 1 )
        {
            htmlfil = argv[1];
            status = tidyParseFile( tdoc, htmlfil );
        }
        else
        {
            htmlfil = "stdin";
            status = tidyParseStdin( tdoc );
        }

        if ( status >= 0 )
            status = tidyCleanAndRepair( tdoc );

        if ( status >= 0 )
            status = tidyRunDiagnostics( tdoc );

        if ( status >= 0 )
        {
            if ( tidyOptGetBool(tdoc, TidyWriteBack) )
                status = tidySaveFile( tdoc, htmlfil );
            else
                status = tidySaveStdout( tdoc );

        }

        contentErrors   += tidyErrorCount( tdoc );
        contentWarnings += tidyWarningCount( tdoc );
        accessWarnings  += tidyAccessWarningCount( tdoc );

        --argc;
        ++argv;

        if ( argc <= 1 )
            break;
    }

    if ( contentErrors + contentWarnings > 0 && 
         !tidyOptGetBool(tdoc, TidyQuiet) )
    {
        tidyErrorSummary( tdoc );
        tidyGeneralInfo( tdoc );
    }

    /* called to free hash tables etc. */
    tidyRelease( tdoc );

    /* return status can be used by scripts */
    if ( contentErrors > 0 )
        return 2;

    if ( contentWarnings > 0 )
        return 1;

    /* 0 signifies all is ok */
    return 0;
}

