<?xml version="1.0"?>
<!--
    This stylesheet is suitable for generating string assignments for use
    in JSDTidyFramework's `Localizable.strings` file, using as input the
    output of `tidy -xml-error-strings` (HTML Tidy 5.1.40 and newer).
    
    Note that null strings are preserved; this means that Tidy doesn't have
    an assigned string for the error, and means that Tidy needs to be cleaned
    up!

    Written by Jim Derry, 2016-February-17.
-->

<xsl:stylesheet version="1.0"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
                
<xsl:output method="text" indent="no" />


<!-- Capture the longest name for padding. We will add
     two characters to allow for surrounding quotes. -->
<xsl:variable name="maxLength">
    <xsl:for-each select="error_strings/error_string/name">
        <xsl:sort select="string-length(.)" data-type="number" />
        <xsl:if test="position() = last()">
            <xsl:value-of select="string-length(.)+2" />
        </xsl:if>
    </xsl:for-each>
</xsl:variable>


<!-- Our MAIN template -->
<xsl:template match="error_strings/error_string">

    <!-- Capture name and surround it with quotes
         prior to padding it. -->
    <xsl:variable name="name">
        <xsl:text>"</xsl:text>
        <xsl:value-of select="name" />
        <xsl:text>"</xsl:text>
    </xsl:variable>

    <!-- Escape quotes in the string prior
         to surrounding it with quotes. -->
    <xsl:variable name="string">
        <xsl:call-template name="escapeQuote">
            <xsl:with-param name="pText" select="string" />
        </xsl:call-template>
    </xsl:variable>

    <!-- Pad the name using a fixed length. -->
    <xsl:call-template name="pad">
        <xsl:with-param name="padChar" select="' '" />
        <xsl:with-param name="padVar" select="$name" />
        <xsl:with-param name="length" select="$maxLength" />
    </xsl:call-template>
    
    <!-- Output the string part with needed surroundings. -->
    <xsl:text> = "</xsl:text>
        <xsl:choose>
            <xsl:when test="$string = 'NULL'">
                <xsl:value-of select="''" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$string" />
            </xsl:otherwise>
        </xsl:choose>
    <xsl:text>";</xsl:text>

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


