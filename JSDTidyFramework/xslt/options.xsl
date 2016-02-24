<?xml version="1.0"?>
<!--
    This stylesheet is suitable for generating string assignments for use
    in JSDTidyFramework's `Localizable.strings` file, using as input the
    output of `tidy -xml-options-strings` (HTML Tidy 5.1.40 and newer).
    
    Note that these strings should be used as a starting point only! for
    stylistic and other reasons, _Balthisar Tidy_ changes the wording of
    some of these.
    
    We're going to replace HTML in the `string` with RTF for Tidy to use:
    - unescape entities
    - replace <br/> with \\par
    - replace <strong> with {\\b xxx}
    - replace <em> with {\\b xxx} (same as strong)
    - replace <code> with {\\f0 xxx}
    - replace <var> with {\\f0\\b xxx}
    - replace <a href> with {\\f0 href}
    
    This is an XSLT2.0 stylesheet! To use with saxon, try:
    saxon -s:source -xsl:options.xsl -o:output
 
    Written by Jim Derry, 2016-February-17.
-->

<xsl:stylesheet version="2.0"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
                

<xsl:output method="text" indent="no" />


<!-- Capture the longest name for padding. We will add 14
     characters to allow for surrounding quotes and prefix. -->
<xsl:variable name="maxLength">
    <xsl:for-each select="options_strings/option/name">
        <xsl:sort select="string-length(.)" data-type="number" />
        <xsl:if test="position() = last()">
            <xsl:value-of select="string-length(.)+14" />
        </xsl:if>
    </xsl:for-each>
</xsl:variable>


<!-- Our MAIN template -->
<xsl:template match="/">

    <xsl:for-each select="options_strings/option">
        <xsl:sort select="name" />

        <!-- Capture name and surround it with quotes and
             prefix prior to padding it. -->
        <xsl:variable name="name">
            <xsl:text>"description-</xsl:text>
            <xsl:value-of select="name" />
            <xsl:text>"</xsl:text>
        </xsl:variable>

        <!-- Escape quotes in the string prior
             to surrounding it with quotes. -->
        <xsl:variable name="string1">
            <xsl:call-template name="escapeQuote">
                <xsl:with-param name="pText" select="string" />
            </xsl:call-template>
        </xsl:variable>
    
        <!-- Replace HTML with RTF -->
        <xsl:variable name="string2">
            <xsl:value-of select="replace($string1, '&lt;strong>(.*?)&lt;/strong>', '{\\\\b $1}')"/>
        </xsl:variable>
        <xsl:variable name="string3">
            <xsl:value-of select="replace($string2, '&lt;em>(.*?)&lt;/em>', '{\\\\b $1}')"/>
        </xsl:variable>
        <xsl:variable name="string4">
            <xsl:value-of select="replace($string3, '&lt;code>(.*?)&lt;/code>', '{\\\\f0 $1}')"/>
        </xsl:variable>
        <xsl:variable name="string5">
            <xsl:value-of select="replace($string4, '&lt;var>(.*?)&lt;/var>', '{\\\\f0\\\\b $1}')"/>
        </xsl:variable>
        <xsl:variable name="string6">
            <!-- We've escaped the quote above, so search for escaped quotes. -->
            <xsl:value-of select="replace($string5, '&lt;a.*?href=\\&quot;(.*?)\\&quot;>.*?&lt;/a>', '{\\\\f0 $1}')"/>
        </xsl:variable>
        <xsl:variable name="string7">
            <!-- Similar to above, but single quotes. -->
            <xsl:value-of select="replace($string6, '&lt;a.*?href=''(.*?)''>.*?&lt;/a>', '{\\\\f0 $1}')"/>
        </xsl:variable>

        <xsl:variable name="string">
            <xsl:value-of select="normalize-space(replace($string7, '\s*&lt;br/>', '\\\\par '))"/>
        </xsl:variable>
    
    
        <!-- Pad the name using a fixed length. -->
        <xsl:call-template name="pad">
            <xsl:with-param name="padChar" select="' '" />
            <xsl:with-param name="padVar" select="$name" />
            <xsl:with-param name="length" select="$maxLength" />
        </xsl:call-template>
    
        <!-- Output the string part with needed surroundings. -->
        <!-- The preceding asterisk indicates to Tidy that there is RTF. -->
        <xsl:text> = "*</xsl:text>
            <xsl:choose>
                <xsl:when test="$string = 'NULL'">
                    <xsl:value-of select="''" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$string" disable-output-escaping="yes" />
                </xsl:otherwise>
            </xsl:choose>
        <xsl:text>";&#10;</xsl:text>
        
    </xsl:for-each>
    
</xsl:template>


<!-- We're generating C strings, which are quoted, so we have to escape
     any current quotes. -->
<xsl:template name="escapeQuote">
    <xsl:param name="pText" select="."/>

    <xsl:if test="string-length($pText) >0">
        <xsl:value-of select="substring-before(concat($pText, '&quot;'), '&quot;')"/>

        <xsl:if test="contains($pText, '&quot;')">
            <xsl:text>\"</xsl:text>

            <xsl:call-template name="escapeQuote">
                <xsl:with-param name="pText" select="substring-after($pText, '&quot;')"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:if>
</xsl:template>


<!-- Pad the left side so that our source code lines up nice and neatly. -->
<xsl:template name="pad">    
    <xsl:param name="padChar"> </xsl:param>
    <xsl:param name="padVar"/>
    <xsl:param name="length"/>
    <xsl:choose>
        <xsl:when test="string-length($padVar) &lt; $length">
            <xsl:call-template name="pad">
                <xsl:with-param name="padChar" select="$padChar"/>
                <xsl:with-param name="padVar" select="concat($padVar,$padChar)"/>
                <xsl:with-param name="length" select="$length"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="substring($padVar,1,$length)"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
  
  
</xsl:stylesheet>


