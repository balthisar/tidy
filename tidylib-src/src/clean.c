/*
  clean.c -- clean up misuse of presentation markup

  (c) 1998-2002 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.

  CVS Info :

    $Author: creitzel $ 
    $Date: 2003/02/16 19:33:10 $ 
    $Revision: 1.20 $ 

  Filters from other formats such as Microsoft Word
  often make excessive use of presentation markup such
  as font tags, B, I, and the align attribute. By applying
  a set of production rules, it is straight forward to
  transform this to use CSS.

  Some rules replace some of the children of an element by
  style properties on the element, e.g.

  <p><b>...</b></p> -> <p style="font-weight: bold">...</p>

  Such rules are applied to the element's content and then
  to the element itself until none of the rules more apply.
  Having applied all the rules to an element, it will have
  a style attribute with one or more properties. 

  Other rules strip the element they apply to, replacing
  it by style properties on the contents, e.g.
  
  <dir><li><p>...</li></dir> -> <p style="margin-left 1em">...
      
  These rules are applied to an element before processing
  its content and replace the current element by the first
  element in the exposed content.

  After applying both sets of rules, you can replace the
  style attribute by a class value and style rule in the
  document head. To support this, an association of styles
  and class names is built.

  A naive approach is to rely on string matching to test
  when two property lists are the same. A better approach
  would be to first sort the properties before matching.

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "tidy-int.h"
#include "clean.h"
#include "lexer.h"
#include "parser.h"
#include "attrs.h"
#include "message.h"
#include "tmbstr.h"
#include "utf8.h"

void RenameElem( Node* node, TidyTagId tid )
{
    const Dict* dict = LookupTagDef( tid );
    MemFree( node->element );
    node->element = tmbstrdup( dict->name );
    node->tag = dict;
}

static void FreeStyleProps(StyleProp *props)
{
    StyleProp *next;

    while (props)
    {
        next = props->next;
        MemFree(props->name);
        MemFree(props->value);
        MemFree(props);
        props = next;
    }
}

static StyleProp *InsertProperty( StyleProp* props, ctmbstr name, ctmbstr value )
{
    StyleProp *first, *prev, *prop;
    int cmp;

    prev = null;
    first = props;

    while (props)
    {
        cmp = tmbstrcmp(props->name, name);

        if (cmp == 0)
        {
            /* this property is already defined, ignore new value */
            return first;
        }

        if (cmp > 0)
        {
            /* insert before this */

            prop = (StyleProp *)MemAlloc(sizeof(StyleProp));
            prop->name = tmbstrdup(name);
            prop->value = tmbstrdup(value);
            prop->next = props;

            if (prev)
                prev->next = prop;
            else
                first = prop;

            return first;
        }

        prev = props;
        props = props->next;
    }

    prop = (StyleProp *)MemAlloc(sizeof(StyleProp));
    prop->name = tmbstrdup(name);
    prop->value = tmbstrdup(value);
    prop->next = null;

    if (prev)
        prev->next = prop;
    else
        first = prop;

    return first;
}

/*
 Create sorted linked list of properties from style string
 It temporarily places nulls in place of ':' and ';' to
 delimit the strings for the property name and value.
 Some systems don't allow you to null literal strings,
 so to avoid this, a copy is made first.
*/
static StyleProp* CreateProps( StyleProp* prop, ctmbstr style )
{
    tmbstr name, value = null, name_end, value_end, line;
    Bool more;

    line = tmbstrdup(style);
    name = line;

    while (*name)
    {
        while (*name == ' ')
            ++name;

        name_end = name;

        while (*name_end)
        {
            if (*name_end == ':')
            {
                value = name_end + 1;
                break;
            }

            ++name_end;
        }

        if (*name_end != ':')
            break;

        while ( value && *value == ' ')
            ++value;

        value_end = value;
        more = no;

        while (*value_end)
        {
            if (*value_end == ';')
            {
                more = yes;
                break;
            }

            ++value_end;
        }

        *name_end = '\0';
        *value_end = '\0';

        prop = InsertProperty(prop, name, value);
        *name_end = ':';

        if (more)
        {
            *value_end = ';';
            name = value_end + 1;
            continue;
        }

        break;
    }

    MemFree(line);  /* free temporary copy */
    return prop;
}

static tmbstr CreatePropString(StyleProp *props)
{
    tmbstr style, p, s;
    int len;
    StyleProp *prop;

    /* compute length */

    for (len = 0, prop = props; prop; prop = prop->next)
    {
        len += tmbstrlen(prop->name) + 2;
        if (prop->value)
            len += tmbstrlen(prop->value) + 2;
    }

    style = (tmbstr) MemAlloc(len+1);

    for (p = style, prop = props; prop; prop = prop->next)
    {
        s = prop->name;

        while((*p++ = *s++));

        if (prop->value)
        {
            *--p = ':';
            *++p = ' ';
            ++p;

            s = prop->value;
            while((*p++ = *s++));
        }
        if (prop->next == null)
            break;

        *--p = ';';
        *++p = ' ';
        ++p;
    }

    return style;
}

/*
  create string with merged properties
static tmbstr AddProperty( ctmbstr style, ctmbstr property )
{
    tmbstr line;
    StyleProp *prop;

    prop = CreateProps(null, style);
    prop = CreateProps(prop, property);
    line = CreatePropString(prop);
    FreeStyleProps(prop);
    return line;
}
*/

void FreeStyles( TidyDocImpl* doc )
{
    Lexer* lexer = doc->lexer;
    if ( lexer )
    {
        Style *style, *next;
        for ( style = lexer->styles; style; style = next )
        {
            next = style->next;
            MemFree( style->tag );
            MemFree( style->tag_class );
            MemFree( style->properties );
            MemFree( style );
        }
    }
}

static tmbstr GensymClass( TidyDocImpl* doc )
{
    tmbchar buf[512];  /* CSSPrefix is limited to 256 characters */
    ctmbstr pfx = cfgStr(doc, TidyCSSPrefix);
    if ( pfx == null || *pfx == 0 )
      pfx = "c";

    sprintf( buf, "%s%d", pfx, ++doc->nClassId );
    return tmbstrdup(buf);
}

static ctmbstr FindStyle( TidyDocImpl* doc, ctmbstr tag, ctmbstr properties )
{
    Lexer* lexer = doc->lexer;
    Style* style;

    for (style = lexer->styles; style; style=style->next)
    {
        if (tmbstrcmp(style->tag, tag) == 0 &&
            tmbstrcmp(style->properties, properties) == 0)
            return style->tag_class;
    }

    style = (Style *)MemAlloc( sizeof(Style) );
    style->tag = tmbstrdup(tag);
    style->tag_class = GensymClass( doc );
    style->properties = tmbstrdup( properties );
    style->next = lexer->styles;
    lexer->styles = style;
    return style->tag_class;
}

/*
 Add class="foo" to node
*/
void AddClass( TidyDocImpl* doc, Node* node, ctmbstr classname )
{
    AttVal *classattr = GetAttrByName(node, "class");

    /*
     if there already is a class attribute
     then append class name after an underscore.
    */
    if (classattr)
    {
        int len = tmbstrlen(classattr->value) +
                  tmbstrlen(classname) + 2;
        tmbstr s = (tmbstr) MemAlloc( len );
        tmbstrcpy( s, classattr->value );
        tmbstrcat( s, "_" );
        tmbstrcat( s, classname );
        MemFree( classattr->value );
        classattr->value = s;
    }
    else /* create new class attribute */
        AddAttribute( doc, node, "class", classname );
}


/*
 Find style attribute in node, and replace it
 by corresponding class attribute. Search for
 class in style dictionary otherwise gensym
 new class and add to dictionary.

 Assumes that node doesn't have a class attribute
*/
static void Style2Rule( TidyDocImpl* doc, Node *node)
{
    Lexer *lexer = doc->lexer;
    AttVal *styleattr, *classattr;
    ctmbstr classname;

    styleattr = GetAttrByName(node, "style");

    if (styleattr)
    {
        classname = FindStyle( doc, node->element, styleattr->value );
        classattr = GetAttrByName(node, "class");

        /*
         if there already is a class attribute
         then append class name after an underscore
        */
        if (classattr)
        {
            int len = tmbstrlen(classattr->value) +
                      tmbstrlen(classname) + 2;
            tmbstr s = (tmbstr) MemAlloc( len );
            tmbstrcpy(s, classattr->value);
            tmbstrcat(s, "_");
            tmbstrcat(s, classname);
            MemFree(classattr->value);
            classattr->value = s;
            RemoveAttribute( node, styleattr);
        }
        else /* reuse style attribute for class attribute */
        {
            MemFree(styleattr->attribute);
            MemFree(styleattr->value);
            styleattr->attribute = tmbstrdup("class");
            styleattr->value = tmbstrdup(classname);
        }
    }
}

static void AddColorRule( Lexer* lexer, ctmbstr selector, ctmbstr color )
{
    if ( selector && color )
    {
        AddStringLiteral(lexer, selector);
        AddStringLiteral(lexer, " { color: ");
        AddStringLiteral(lexer, color);
        AddStringLiteral(lexer, " }\n");
    }
}

/*
 move presentation attribs from body to style element

 background="foo" ->  body { background-image: url(foo) }
 bgcolor="foo"    ->  body { background-color: foo }
 text="foo"       ->  body { color: foo }
 link="foo"       ->  :link { color: foo }
 vlink="foo"      ->  :visited { color: foo }
 alink="foo"      ->  :active { color: foo }
*/
static void CleanBodyAttrs( TidyDocImpl* doc, Node* body )
{
    Lexer* lexer  = doc->lexer;
    tmbstr bgurl   = null;
    tmbstr bgcolor = null;
    tmbstr color   = null;
    AttVal* attr;
    
    if ( attr = GetAttrByName(body, "background") )
    {
        bgurl = attr->value;
        attr->value = null;
        RemoveAttribute( body, attr );
    }

    if ( attr = GetAttrByName(body, "bgcolor") )
    {
        bgcolor = attr->value;
        attr->value = null;
        RemoveAttribute( body, attr );
    }

    if ( attr = GetAttrByName(body, "text") )
    {
        color = attr->value;
        attr->value = null;
        RemoveAttribute(body, attr);
    }

    if ( bgurl || bgcolor || color )
    {
        AddStringLiteral(lexer, " body {\n");
        if (bgurl)
        {
            AddStringLiteral(lexer, "  background-image: url(");
            AddStringLiteral(lexer, bgurl);
            AddStringLiteral(lexer, ");\n");
            MemFree(bgurl);
        }
        if (bgcolor)
        {
            AddStringLiteral(lexer, "  background-color: ");
            AddStringLiteral(lexer, bgcolor);
            AddStringLiteral(lexer, ";\n");
            MemFree(bgcolor);
        }
        if (color)
        {
            AddStringLiteral(lexer, "  color: ");
            AddStringLiteral(lexer, color);
            AddStringLiteral(lexer, ";\n");
            MemFree(color);
        }

        AddStringLiteral(lexer, " }\n");
    }

    if ( attr = GetAttrByName(body, "link") )
    {
        AddColorRule(lexer, " :link", attr->value);
        RemoveAttribute(body, attr);
    }

    if ( attr = GetAttrByName(body, "vlink") )
    {
        AddColorRule(lexer, " :visited", attr->value);
        RemoveAttribute(body, attr);
    }

    if ( attr = GetAttrByName(body, "alink") )
    {
        AddColorRule(lexer, " :active", attr->value);
        RemoveAttribute(body, attr);
    }
}

static Bool NiceBody( TidyDocImpl* doc )
{
    Node* body = FindBody( doc );
    if ( body )
    {
        if ( GetAttrByName(body, "background") ||
             GetAttrByName(body, "bgcolor") ||
             GetAttrByName(body, "text") ||
             GetAttrByName(body, "link") ||
             GetAttrByName(body, "vlink") ||
             GetAttrByName(body, "alink")
           )
        {
            doc->badLayout |= USING_BODY;
            return no;
        }
    }

    return yes;
}

/* create style element using rules from dictionary */
static void CreateStyleElement( TidyDocImpl* doc )
{
    Lexer* lexer = doc->lexer;
    Node *node, *head, *body;
    Style *style;
    AttVal *av;

    if ( lexer->styles == null && NiceBody(doc) )
        return;

    node = NewNode( lexer );
    node->type = StartTag;
    node->implicit = yes;
    node->element = tmbstrdup("style");
    FindTag( doc, node );

    /* insert type attribute */
    av = NewAttribute();
    av->attribute = tmbstrdup("type");
    av->value = tmbstrdup("text/css");
    av->delim = '"';
    av->dict = FindAttribute( doc, av );
    node->attributes = av;

    body = FindBody( doc );
    lexer->txtstart = lexer->lexsize;
    if ( body )
        CleanBodyAttrs( doc, body );

    for (style = lexer->styles; style; style = style->next)
    {
        AddCharToLexer(lexer, ' ');
        AddStringLiteral(lexer, style->tag);
        AddCharToLexer(lexer, '.');
        AddStringLiteral(lexer, style->tag_class);
        AddCharToLexer(lexer, ' ');
        AddCharToLexer(lexer, '{');
        AddStringLiteral(lexer, style->properties);
        AddCharToLexer(lexer, '}');
        AddCharToLexer(lexer, '\n');
    }

    lexer->txtend = lexer->lexsize;

    InsertNodeAtEnd( node, TextToken(lexer) );

    /*
     now insert style element into document head

     doc is root node. search its children for html node
     the head node should be first child of html node
    */
    if ( head = FindHEAD( doc ) )
        InsertNodeAtEnd( head, node );
}


/* ensure bidirectional links are consistent */
static void FixNodeLinks(Node *node)
{
    Node *child;

    if (node->prev)
        node->prev->next = node;
    else
        node->parent->content = node;

    if (node->next)
        node->next->prev = node;
    else
        node->parent->last = node;

    for (child = node->content; child; child = child->next)
        child->parent = node;
}

/*
 used to strip child of node when
 the node has one and only one child
*/
static void StripOnlyChild(TidyDocImpl* doc, Node *node)
{
    Node *child;

    child = node->content;
    node->content = child->content;
    node->last = child->last;
    child->content = null;
    FreeNode(doc, child);

    for (child = node->content; child; child = child->next)
        child->parent = node;
}

/* used to strip font start and end tags */
static void DiscardContainer( TidyDocImpl* doc, Node *element, Node **pnode)
{
    Node *node, *parent = element->parent;

    if (element->content)
    {
        element->last->next = element->next;

        if (element->next)
        {
            element->next->prev = element->last;
            element->last->next = element->next;
        }
        else
            parent->last = element->last;

        if (element->prev)
        {
            element->content->prev = element->prev;
            element->prev->next = element->content;
        }
        else
            parent->content = element->content;

        for (node = element->content; node; node = node->next)
            node->parent = parent;

        *pnode = element->content;
    }
    else
    {
        if (element->next)
            element->next->prev = element->prev;
        else
            parent->last = element->prev;

        if (element->prev)
            element->prev->next = element->next;
        else
            parent->content = element->next;

        *pnode = element->next;
    }

    element->next = element->content = null;
    FreeNode(doc, element);
}

/*
  Create new string that consists of the
  combined style properties in s1 and s2

  To merge property lists, we build a linked
  list of property/values and insert properties
  into the list in order, merging values for
  the same property name.
*/
static tmbstr MergeProperties( ctmbstr s1, ctmbstr s2 )
{
    tmbstr s;
    StyleProp *prop;

    prop = CreateProps(null, s1);
    prop = CreateProps(prop, s2);
    s = CreatePropString(prop);
    FreeStyleProps(prop);
    return s;
}

/*
 Add style property to element, creating style
 attribute as needed and adding ; delimiter
*/
static void AddStyleProperty(TidyDocImpl* doc, Node *node, ctmbstr property )
{
    AttVal *av = GetAttrByName( node, "style" );


    /* if style attribute already exists then insert property */

    if ( av )
    {
        tmbstr s = MergeProperties( av->value, property );
        MemFree( av->value );
        av->value = s;
    }
    else /* else create new style attribute */
    {
        av = NewAttribute();
        av->attribute = tmbstrdup("style");
        av->value = tmbstrdup(property);
        av->delim = '"';
        av->dict = FindAttribute( doc, av );
        av->next = node->attributes;
        node->attributes = av;
    }
}

static void MergeClasses(TidyDocImpl* doc, Node *node, Node *child)
{
    AttVal *av;
    tmbstr s1, s2, names;

    for (s2 = null, av = child->attributes; av; av = av->next)
    {
        if (tmbstrcmp(av->attribute, "class") == 0)
        {
            s2 = av->value;
            break;
        }
    }

    for (s1 = null, av = node->attributes; av; av = av->next)
    {
        if (tmbstrcmp(av->attribute, "class") == 0)
        {
            s1 = av->value;
            break;
        }
    }

    if (s1)
    {
        if (s2)  /* merge class names from both */
        {
            int l1, l2;
            l1 = tmbstrlen(s1);
            l2 = tmbstrlen(s2);
            names = (tmbstr) MemAlloc(l1 + l2 + 2);
            tmbstrcpy(names, s1);
            names[l1] = ' ';
            tmbstrcpy(names+l1+1, s2);
            MemFree(av->value);
            av->value = names;
        }
    }
    else if (s2)  /* copy class names from child */
    {
        av = NewAttribute();
        av->attribute = tmbstrdup("class");
        av->value = tmbstrdup(s2);
        av->delim = '"';
        av->dict = FindAttribute(doc, av);
        av->next = node->attributes;
        node->attributes = av;
    }
}

static void MergeStyles(TidyDocImpl* doc, Node *node, Node *child)
{
    AttVal *av;
    tmbstr s1, s2, style;

    /*
       the child may have a class attribute used
       for attaching styles, if so the class name
       needs to be copied to node's class
    */
    MergeClasses(doc, node, child);

    for (s2 = null, av = child->attributes; av; av = av->next)
    {
        if (tmbstrcmp(av->attribute, "style") == 0)
        {
            s2 = av->value;
            break;
        }
    }

    for (s1 = null, av = node->attributes; av; av = av->next)
    {
        if (tmbstrcmp(av->attribute, "style") == 0)
        {
            s1 = av->value;
            break;
        }
    }

    if (s1)
    {
        if (s2)  /* merge styles from both */
        {
            style = MergeProperties(s1, s2);
            MemFree(av->value);
            av->value = style;
        }
    }
    else if (s2)  /* copy style of child */
    {
        av = NewAttribute();
        av->attribute = tmbstrdup("style");
        av->value = tmbstrdup(s2);
        av->delim = '"';
        av->dict = FindAttribute(doc, av);
        av->next = node->attributes;
        node->attributes = av;
    }
}

static ctmbstr FontSize2Name( ctmbstr size, tmbstr buf )
{
    static const ctmbstr sizes[7] =
    {
        "60%", "70%", "80%", null,
        "120%", "150%", "200%"
    };

    if ('0' <= size[0] && size[0] <= '6')
    {
        int n = size[0] - '0';
        return sizes[n];
    }

    if (size[0] == '-')
    {
        if ('0' <= size[1] && size[1] <= '6')
        {
            int n = size[1] - '0';
            double x;

            for (x = 1; n > 0; --n)
                x *= 0.8;

            x *= 100;
            sprintf(buf, "%d%%", (int)(x));
            return buf;
        }
        return "smaller"; /*"70%"; */
    }

    if ('0' <= size[1] && size[1] <= '6')
    {
        int n = size[1] - '0';
        double x;

        for (x = 1; n > 0; --n)
            x *= 1.2;

        x *= 100;
        sprintf(buf, "%d%%", (int)(x));
        return buf;
    }

    return "larger"; /* "140%" */
}

static void AddFontFace( TidyDocImpl* doc, Node *node, ctmbstr face )
{
    tmbchar buf[256];
    sprintf( buf, "font-family: %s", face );
    AddStyleProperty( doc, node, buf );
}

static void AddFontSize( TidyDocImpl* doc, Node* node, ctmbstr size )
{
    tmbchar work[ 32 ] = {0};
    ctmbstr value = null;

    if ( nodeIsP(node) )
    {
        if ( tmbstrcmp(size, "6") == 0 )
            value = "h1";
        else if (tmbstrcmp(size, "5") == 0 )
            value = "h2";
        else if (tmbstrcmp(size, "4") == 0 )
            value = "h3";

        if ( value )
        {
            MemFree( node->element );
            node->element = tmbstrdup( value );
            FindTag( doc, node );
        }
    }
    else if ( value = FontSize2Name(size, work) )
    {
        tmbchar buf[64];
        sprintf(buf, "font-size: %s", value);
        AddStyleProperty( doc, node, buf );
    }
}

static void AddFontColor( TidyDocImpl* doc, Node *node, ctmbstr color)
{
    tmbchar buf[128];
    sprintf(buf, "color: %s", color);
    AddStyleProperty( doc, node, buf );
}

/* force alignment value to lower case */
static void AddAlign( TidyDocImpl* doc, Node *node, ctmbstr align )
{
    tmbchar buf[128], *p;

    tmbstrcpy( buf, "text-align: " );
    for ( p = buf + 12; *p++ = (tmbchar)ToLower(*align++); /**/ )
      /**/;
    AddStyleProperty( doc, node, buf );
}

/*
 add style properties to node corresponding to
 the font face, size and color attributes
*/
static void AddFontStyles( TidyDocImpl* doc, Node *node, AttVal *av)
{
    while (av)
    {
        if (tmbstrcmp(av->attribute, "face") == 0)
            AddFontFace( doc, node, av->value );
        else if (tmbstrcmp(av->attribute, "size") == 0)
            AddFontSize( doc, node, av->value );
        else if (tmbstrcmp(av->attribute, "color") == 0)
            AddFontColor( doc, node, av->value );

        av = av->next;
    }
}

/*
    Symptom: <p align=center>
    Action: <p style="text-align: center">
*/
static void TextAlign( TidyDocImpl* doc, Node* node )
{
    AttVal *av, *prev;

    prev = null;

    for (av = node->attributes; av; av = av->next)
    {
        if (tmbstrcmp(av->attribute, "align") == 0)
        {
            if (prev)
                prev->next = av->next;
            else
                node->attributes = av->next;

            MemFree(av->attribute);

            if (av->value)
            {
                AddAlign( doc, node, av->value );
                MemFree(av->value);
            }

            MemFree(av);
            break;
        }

        prev = av;
    }
}

/*
   The clean up rules use the pnode argument to return the
   next node when the original node has been deleted
*/

/*
    Symptom: <dir> <li> where <li> is only child
    Action: coerce <dir> <li> to <div> with indent.
*/

static Bool Dir2Div( TidyDocImpl* doc, Node *node, Node **pnode)
{
    Node *child;

    if ( nodeIsDIR(node) || nodeIsUL(node) || nodeIsOL(node) )
    {
        child = node->content;

        if (child == null)
            return no;

        /* check child has no peers */

        if (child->next)
            return no;

        if ( !nodeIsLI(child) )
            return no;

        if ( !child->implicit )
            return no;

        /* coerce dir to div */
        node->tag = LookupTagDef( TidyTag_DIV );
        MemFree( node->element );
        node->element = tmbstrdup("div");
        AddStyleProperty( doc, node, "margin-left: 2em" );
        StripOnlyChild( doc, node );
        return yes;
    }

    return no;
}

/*
    Symptom: <center>
    Action: replace <center> by <div style="text-align: center">
*/

static Bool Center2Div( TidyDocImpl* doc, Node *node, Node **pnode)
{
    Lexer *lexer = doc->lexer;

    if ( nodeIsCENTER(node) )
    {
        if ( cfgBool(doc, TidyDropFontTags) )
        {
            if (node->content)
            {
                Node *last = node->last, *parent = node->parent;
                DiscardContainer( doc, node, pnode );
                node = InferredTag( doc, "br" );

                if (last->next)
                    last->next->prev = node;

                node->next = last->next;
                last->next = node;
                node->prev = last;

                if (parent->last == last)
                    parent->last = node;

                node->parent = parent;
            }
            else
            {
                Node *prev = node->prev, *next = node->next, *parent = node->parent;
                DiscardContainer( doc, node, pnode );

                node = InferredTag( doc, "br" );
                node->next = next;
                node->prev = prev;
                node->parent = parent;

                if (next)
                    next->prev = node;
                else
                    parent->last = node;

                if (prev)
                    prev->next = node;
                else
                    parent->content = node;
            }

            return yes;
        }

        RenameElem( node, TidyTag_DIV );
        AddStyleProperty( doc, node, "text-align: center" );
        return yes;
    }

    return no;
}

/*
    Symptom <div><div>...</div></div>
    Action: merge the two divs

  This is useful after nested <dir>s used by Word
  for indenting have been converted to <div>s
*/
static Bool MergeDivs( TidyDocImpl* doc, Node *node, Node **pnode)
{
    Node *child;

    if ( !nodeIsDIV(node) )
        return no;

    child = node->content;

    if (!child)
        return no;

    if ( !nodeIsDIV(child) )
        return no;

    if (child->next != null)
        return no;

    MergeStyles( doc, node, child );
    StripOnlyChild( doc, node );
    return yes;
}

/*
    Symptom: <ul><li><ul>...</ul></li></ul>
    Action: discard outer list
*/

static Bool NestedList( TidyDocImpl* doc, Node *node, Node **pnode )
{
    Node *child, *list;

    if ( nodeIsUL(node) || nodeIsOL(node) )
    {
        child = node->content;

        if (child == null)
            return no;

        /* check child has no peers */

        if (child->next)
            return no;

        list = child->content;

        if (!list)
            return no;

        if (list->tag != node->tag)
            return no;

        *pnode = list;  /* Set node to resume iteration */

        /* move inner list node into position of outer node */
        list->prev = node->prev;
        list->next = node->next;
        list->parent = node->parent;
        FixNodeLinks(list);

        /* get rid of outer ul and its li */
        /* XXX: Are we leaking the child node? -creitzel 7 Jun, 01 */
        child->content = null;
        node->content = null;
        node->next = null;
        FreeNode( doc, node );
        node = null;

        /*
          If prev node was a list the chances are this node
          should be appended to that list. Word has no way of
          recognizing nested lists and just uses indents
        */

        if (list->prev)
        {
            if ( nodeIsUL(list->prev) || nodeIsOL(list->prev) )
            {
                node = list;
                list = node->prev;
                list->next = node->next;

                if (list->next)
                    list->next->prev = list;

                child = list->last;  /* <li> */

                node->parent = child;
                node->next = null;
                node->prev = child->last;
                FixNodeLinks(node);
                CleanNode( doc, node );
            }
        }

        return yes;
    }

    return no;
}

/*
  Symptom: the only child of a block-level element is a
  presentation element such as B, I or FONT

  Action: add style "font-weight: bold" to the block and
  strip the <b> element, leaving its children.

  example:

    <p>
      <b><font face="Arial" size="6">Draft Recommended Practice</font></b>
    </p>

  becomes:

      <p style="font-weight: bold; font-family: Arial; font-size: 6">
        Draft Recommended Practice
      </p>

  This code also replaces the align attribute by a style attribute.
  However, to avoid CSS problems with Navigator 4, this isn't done
  for the elements: caption, tr and table
*/
static Bool BlockStyle( TidyDocImpl* doc, Node *node, Node **pnode )
{
    Node *child;

    if (node->tag->model & (CM_BLOCK | CM_LIST | CM_DEFLIST | CM_TABLE))
    {
        if ( !nodeIsTABLE(node) && !nodeIsTR(node) && !nodeIsLI(node) )
        {
            /* check for align attribute */
            if ( !nodeIsCAPTION(node) )
                TextAlign( doc, node );

            child = node->content;
            if (child == null)
                return no;

            /* check child has no peers */
            if (child->next)
                return no;

            if ( nodeIsB(child) )
            {
                MergeStyles( doc, node, child );
                AddStyleProperty( doc, node, "font-weight: bold" );
                StripOnlyChild( doc, node );
                return yes;
            }

            if ( nodeIsI(child) )
            {
                MergeStyles( doc, node, child );
                AddStyleProperty( doc, node, "font-style: italic" );
                StripOnlyChild( doc, node );
                return yes;
            }

            if ( nodeIsFONT(child) )
            {
                MergeStyles( doc, node, child );
                AddFontStyles( doc, node, child->attributes );
                StripOnlyChild( doc, node );
                return yes;
            }
        }
    }

    return no;
}

/* the only child of table cell or an inline element such as em */
static Bool InlineStyle( TidyDocImpl* doc, Node *node, Node **pnode )
{
    Node *child;

    if ( !nodeIsFONT(node) && nodeHasCM(node, CM_INLINE|CM_ROW) )
    {
        child = node->content;

        if (child == null)
            return no;

        /* check child has no peers */

        if (child->next)
            return no;

        if ( nodeIsB(child) && cfgBool(doc, TidyLogicalEmphasis) )
        {
            MergeStyles( doc, node, child );
            AddStyleProperty( doc, node, "font-weight: bold" );
            StripOnlyChild( doc, node );
            return yes;
        }

        if ( nodeIsI(child) && cfgBool(doc, TidyLogicalEmphasis) )
        {
            MergeStyles( doc, node, child );
            AddStyleProperty( doc, node, "font-style: italic" );
            StripOnlyChild( doc, node );
            return yes;
        }

        if ( nodeIsFONT(child) )
        {
            MergeStyles( doc, node, child );
            AddFontStyles( doc, node, child->attributes );
            StripOnlyChild( doc, node );
            return yes;
        }
    }

    return no;
}

/*
  Replace font elements by span elements, deleting
  the font element's attributes and replacing them
  by a single style attribute.
*/
static Bool Font2Span( TidyDocImpl* doc, Node *node, Node **pnode )
{
    AttVal *av, *style, *next;

    if ( nodeIsFONT(node) )
    {
        if ( cfgBool(doc, TidyDropFontTags) )
        {
            DiscardContainer( doc, node, pnode );
            return no;
        }

        /* if FONT is only child of parent element then leave alone */
        if ( node->parent->content == node && node->next == null )
            return no;

        AddFontStyles( doc, node, node->attributes );

        /* extract style attribute and free the rest */
        av = node->attributes;
        style = null;

        while (av)
        {
            next = av->next;

            if ( tmbstrcmp(av->attribute, "style") == 0 )
            {
                av->next = null;
                style = av;
            }
            else
            {
                FreeAttribute( av );
            }
            av = next;
        }

        node->attributes = style;
        RenameElem( node, TidyTag_SPAN );
        return yes;
    }

    return no;
}

static Bool IsElement(Node *node)
{
    return (node->type == StartTag || node->type == StartEndTag ? yes : no);
}

/*
  Applies all matching rules to a node.
*/
Node* CleanNode( TidyDocImpl* doc, Node *node )
{
    Node *next = null;

    for (next = node; node && IsElement(node); node = next)
    {
        if ( Dir2Div(doc, node, &next) )
            continue;

        /* Special case: true result means
        ** that arg node and its parent no longer exist.
        ** So we must jump back up the CreateStyleProperties()
        ** call stack until we have a valid node reference.
        */
        if ( NestedList(doc, node, &next) )
            return next;

        if ( Center2Div(doc, node, &next) )
            continue;

        if ( MergeDivs(doc, node, &next) )
            continue;

        if ( BlockStyle(doc, node, &next) )
            continue;

        if ( InlineStyle(doc, node, &next) )
            continue;

        if ( Font2Span(doc, node, &next) )
            continue;

        break;
    }

    return next;
}

/* Special case: if the current node is destroyed by
** CleanNode() lower in the tree, this node and its parent
** no longer exist.  So we must jump back up the CleanTree()
** call stack until we have a valid node reference.
*/

static Node* CleanTree( TidyDocImpl* doc, Node *node, Node** prepl)
{
    if (node->content)
    {
        Node *child, *repl = node;
        for (child = node->content; child != null; child = child->next)
        {
            child = CleanTree( doc, child, &repl );
            if ( repl != node ) 
                return repl;
            if ( !child )
                break;
        }
    }

    return CleanNode( doc, node );
}

static void DefineStyleRules( TidyDocImpl* doc, Node *node )
{
    Node *child;

    if (node->content)
    {
        for (child = node->content;
                child != null; child = child->next)
        {
            DefineStyleRules( doc, child );
        }
    }

    Style2Rule( doc, node );
}

void CleanDocument( TidyDocImpl* doc )
{
    /* placeholder.  CleanTree()/CleanNode() will not
    ** zap root element 
    */
    Node* repl = doc->root;  
    CleanTree( doc, doc->root, &repl );

    if ( cfgBool(doc, TidyMakeClean) )
    {
        DefineStyleRules( doc, doc->root );
        CreateStyleElement( doc );
    }
}

/* simplifies <b><b> ... </b> ...</b> etc. */
void NestedEmphasis( TidyDocImpl* doc, Node* node )
{
    Node *next;

    while (node)
    {
        next = node->next;

        if ( (nodeIsB(node) || nodeIsI(node))
             && node->parent && node->parent->tag == node->tag)
        {
            /* strip redundant inner element */
            DiscardContainer( doc, node, &next );
            node = next;
            continue;
        }

        if ( node->content )
            NestedEmphasis( doc, node->content );

        node = next;
    }
}



/* replace i by em and b by strong */
void EmFromI( TidyDocImpl* doc, Node* node )
{
    while (node)
    {
        if ( nodeIsI(node) )
            RenameElem( node, TidyTag_EM );
        else if ( nodeIsB(node) )
            RenameElem( node, TidyTag_STRONG );

        if ( node->content )
            EmFromI( doc, node->content );

        node = node->next;
    }
}

static Bool HasOneChild(Node *node)
{
    return (node->content && node->content->next == null);
}

/*
 Some people use dir or ul without an li
 to indent the content. The pattern to
 look for is a list with a single implicit
 li. This is recursively replaced by an
 implicit blockquote.
*/
void List2BQ( TidyDocImpl* doc, Node* node )
{
    while (node)
    {
        if (node->content)
            List2BQ( doc, node->content );

        if ( node->tag && node->tag->parser == ParseList &&
             HasOneChild(node) && node->content->implicit )
        {
            StripOnlyChild( doc, node );
            RenameElem( node, TidyTag_BLOCKQUOTE );
            node->implicit = yes;
        }

        node = node->next;
    }
}


/*
 Replace implicit blockquote by div with an indent
 taking care to reduce nested blockquotes to a single
 div with the indent set to match the nesting depth
*/
void BQ2Div( TidyDocImpl* doc, Node *node )
{
    tmbchar indent_buf[ 32 ];
    int indent;
    size_t len;
    AttVal *attval;

    while (node)
    {
        if ( nodeIsBLOCKQUOTE(node) && node->implicit )
        {
            indent = 1;

            while( HasOneChild(node) &&
                   nodeIsBLOCKQUOTE(node->content) &&
                   node->implicit)
            {
                ++indent;
                StripOnlyChild( doc, node );
            }

            if (node->content)
                BQ2Div( doc, node->content );

            len = sprintf(indent_buf, "margin-left: %dem", 2*indent);

            RenameElem( node, TidyTag_DIV );

            attval = GetAttrByName( node, "style" );
            if (attval)
            {
                tmbstr s = (tmbstr) MemAlloc(len + 3 + tmbstrlen(attval->value));
                tmbstrcpy(s, indent_buf);
                tmbstrcat(s, "; ");
                tmbstrcat(s, attval->value);

                MemFree(attval->value);
                attval->value = s;
            }
            else
            {
                AddAttribute( doc, node, "style", indent_buf );
            }
        }
        else if (node->content)
            BQ2Div( doc, node->content );

        node = node->next;
    }
}


Node* FindEnclosingCell( TidyDocImpl* doc, Node *node)
{
    Node *check;

    for ( check=node; check; check = check->parent )
    {
      if ( nodeIsTD(check) )
        return check;
    }
    return null;
}

/* node is <![if ...]> prune up to <![endif]> */
static Node* PruneSection( TidyDocImpl* doc, Node *node )
{
    Lexer* lexer = doc->lexer;

    for (;;)
    {
        ctmbstr lexbuf = lexer->lexbuf + node->start;
        if ( tmbstrncmp(lexbuf, "if !supportEmptyParas", 21) == 0 )
        {
          Node* cell = FindEnclosingCell( doc, node );
          if ( cell )
          {
            /* Need to put &nbsp; into cell so it doesn't look weird
            */
            Node* nbsp = NewLiteralTextNode( lexer, "\240" );
            assert( (byte)'\240' == (byte)160 );
            InsertNodeBeforeElement( node, nbsp );
          }
        }

        /* discard node and returns next */
        node = DiscardElement( doc, node );

        if (node == null)
            return null;
        
        if (node->type == SectionTag)
        {
            if (tmbstrncmp(lexer->lexbuf + node->start, "if", 2) == 0)
            {
                node = PruneSection( doc, node );
                continue;
            }

            if (tmbstrncmp(lexer->lexbuf + node->start, "endif", 5) == 0)
            {
                node = DiscardElement( doc, node );
                break;
            }
        }
    }

    return node;
}

void DropSections( TidyDocImpl* doc, Node* node )
{
    Lexer* lexer = doc->lexer;
    while (node)
    {
        if (node->type == SectionTag)
        {
            /* prune up to matching endif */
            if ((tmbstrncmp(lexer->lexbuf + node->start, "if", 2) == 0) &&
                (tmbstrncmp(lexer->lexbuf + node->start, "if !vml", 7) != 0)) /* #444394 - fix 13 Sep 01 */
            {
                node = PruneSection( doc, node );
                continue;
            }

            /* discard others as well */
            node = DiscardElement( doc, node );
            continue;
        }

        if (node->content)
            DropSections( doc, node->content );

        node = node->next;
    }
}

static void PurgeWord2000Attributes( TidyDocImpl* doc, Node* node )
{
    AttVal *attr, *next, *prev = null;

    for ( attr = node->attributes; attr; attr = next )
    {
        next = attr->next;

        /* special check for class="Code" denoting pre text */
        /* Pass thru user defined styles as HTML class names */
        if (tmbstrcmp(attr->attribute, "class") == 0)
        {
            if ( tmbstrcmp(attr->value, "Code") == 0 ||
                 tmbstrncmp(attr->value, "Mso", 3) != 0 )
            {
                prev = attr;
                continue;
            }
        }

        if ( tmbstrcmp(attr->attribute, "class") == 0 ||
             tmbstrcmp(attr->attribute, "style") == 0 ||
             tmbstrcmp(attr->attribute, "lang") == 0 ||
             tmbstrncmp(attr->attribute, "x:", 2) == 0 ||
             ( ( tmbstrcmp(attr->attribute, "height") == 0 ||
                 tmbstrcmp(attr->attribute, "width") == 0 ) &&
               ( nodeIsTD(node) || nodeIsTR(node) || nodeIsTH(node) )
             )
           )
        {
            if (prev)
                prev->next = next;
            else
                node->attributes = next;

            FreeAttribute( attr );
        }
        else
            prev = attr;
    }
}

/* Word2000 uses span excessively, so we strip span out */
static Node* StripSpan( TidyDocImpl* doc, Node* span )
{
    Node *node, *prev = null, *content;

    /*
     deal with span elements that have content
     by splicing the content in place of the span
     after having processed it
    */

    CleanWord2000( doc, span->content );
    content = span->content;

    if (span->prev)
        prev = span->prev;
    else if (content)
    {
        node = content;
        content = content->next;
        RemoveNode(node);
        InsertNodeBeforeElement(span, node);
        prev = node;
    }

    while (content)
    {
        node = content;
        content = content->next;
        RemoveNode(node);
        InsertNodeAfterElement(prev, node);
        prev = node;
    }

    if (span->next == null)
        span->parent->last = prev;

    node = span->next;
    span->content = null;
    DiscardElement( doc, span );
    return node;
}

/* map non-breaking spaces to regular spaces */
static void NormalizeSpaces( Lexer *lexer, Node *node )
{
    while ( node )
    {
        if ( node->content )
            NormalizeSpaces( lexer, node->content );

        if (node->type == TextNode)
        {
            uint i, c;
            tmbstr p = lexer->lexbuf + node->start;

            for (i = node->start; i < node->end; ++i)
            {
                c = (byte) lexer->lexbuf[i];

                /* look for UTF-8 multibyte character */
                if ( c > 0x7F )
                    i += GetUTF8( lexer->lexbuf + i, &c );

                if ( c == 160 )
                    c = ' ';

                p = PutUTF8(p, c);
            }
        }

        node = node->next;
    }
}

/* used to hunt for hidden preformatted sections */
Bool NoMargins(Node *node)
{
    AttVal *attval = GetAttrByName(node, "style");

    if ( !AttrHasValue(attval) )
        return no;

    /* search for substring "margin-top: 0" */
    if (!tmbsubstr(attval->value, "margin-top: 0"))
        return no;

    /* search for substring "margin-bottom: 0" */
    if (!tmbsubstr(attval->value, "margin-bottom: 0"))
        return no;

    return yes;
}

/* does element have a single space as its content? */
Bool SingleSpace( Lexer* lexer, Node* node )
{
    if ( node->content )
    {
        node = node->content;

        if ( node->next != null )
            return no;

        if ( node->type != TextNode )
            return no;

        if ( (node->end - node->start) == 1 &&
             lexer->lexbuf[node->start] == ' ' )
            return yes;

        if ( (node->end - node->start) == 2 )
        {
            uint c = 0;
            GetUTF8( lexer->lexbuf + node->start, &c );
            if ( c == 160 )
                return yes;
        }
    }

    return no;
}

/*
 This is a major clean up to strip out all the extra stuff you get
 when you save as web page from Word 2000. It doesn't yet know what
 to do with VML tags, but these will appear as errors unless you
 declare them as new tags, such as o:p which needs to be declared
 as inline.
*/
void CleanWord2000( TidyDocImpl* doc, Node *node)
{
    /* used to a list from a sequence of bulletted p's */
    Lexer* lexer = doc->lexer;
    Node* list = null;

    while ( node )
    {
        /* get rid of Word's xmlns attributes */
        if ( nodeIsHTML(node) )
        {
            /* check that it's a Word 2000 document */
            if ( !GetAttrByName(node, "xmlns:o") &&
                 !cfgBool(doc, TidyMakeBare) )
                return;

            FreeAttrs( doc, node );
        }

        /* fix up preformatted sections by looking for a
        ** sequence of paragraphs with zero top/bottom margin
        */
        if ( nodeIsP(node) )
        {
            if (NoMargins(node))
            {
                Node *pre, *next;
                CoerceNode( doc, node, TidyTag_PRE );

                PurgeWord2000Attributes( doc, node );

                if (node->content)
                    CleanWord2000( doc, node->content );

                pre = node;
                node = node->next;

                /* continue to strip p's */

                while ( nodeIsP(node) && NoMargins(node) )
                {
                    next = node->next;
                    RemoveNode(node);
                    InsertNodeAtEnd(pre, NewLineNode(lexer));
                    InsertNodeAtEnd(pre, node);
                    StripSpan( doc, node );
                    node = next;
                }

                if (node == null)
                    break;
            }
        }

        if (node->tag && (node->tag->model & CM_BLOCK)
            && SingleSpace(lexer, node))
        {
            node = StripSpan( doc, node );
            continue;
        }
        /* discard Word's style verbiage */
        if ( nodeIsSTYLE(node) || nodeIsMETA(node) ||
             node->type == CommentTag )
        {
            node = DiscardElement( doc, node );
            continue;
        }

        /* strip out all span and font tags Word scatters so liberally! */
        if ( nodeIsSPAN(node) || nodeIsFONT(node) )
        {
            node = StripSpan( doc, node );
            continue;
        }

        if ( nodeIsLINK(node) )
        {
            AttVal *attr = GetAttrByName(node, "rel");

            if (attr && tmbstrcmp(attr->value, "File-List") == 0)
            {
                node = DiscardElement( doc, node );
                continue;
            }
        }

        /* discard empty paragraphs */

        if ( node->content == null && nodeIsP(node) )
        {
            /*  Use the existing function to ensure consistency */
            node = TrimEmptyElement( doc, node );
            continue;
        }

        if ( nodeIsP(node) )
        {
            AttVal *attr, *atrStyle;
            
            attr = GetAttrByName(node, "class");
            atrStyle = GetAttrByName(node, "style");
            /*
               (JES) Sometimes Word marks a list item with the following hokie syntax
               <p class="MsoNormal" style="...;mso-list:l1 level1 lfo1;
                translate these into <li>
            */
            /* map sequence of <p class="MsoListBullet"> to <ul>...</ul> */
            /* map <p class="MsoListNumber"> to <ol>...</ol> */
            if ( AttrMatches(attr, "MsoListBullet") ||
                 AttrMatches(attr, "MsoListNumber") ||
                 AttrContains(atrStyle, "mso-list:") )
            {
                TidyTagId listType = TidyTag_UL;
                if ( attr && tmbstrcmp(attr->value, "MsoListNumber") == 0 )
                    listType = TidyTag_OL;

                CoerceNode( doc, node, TidyTag_LI );

                if ( !list || TagId(list) != listType )
                {
                    const Dict* tag = LookupTagDef( listType );
                    list = InferredTag( doc, tag->name );
                    InsertNodeBeforeElement(node, list);
                }

                PurgeWord2000Attributes( doc, node );

                if ( node->content )
                    CleanWord2000( doc, node->content );

                /* remove node and append to contents of list */
                RemoveNode(node);
                InsertNodeAtEnd(list, node);
                node = list;
            }
            /* map sequence of <p class="Code"> to <pre>...</pre> */
            else if (attr && tmbstrcmp(attr->value, "Code") == 0)
            {
                Node *br = NewLineNode(lexer);
                NormalizeSpaces(lexer, node);

                if ( !list || TagId(list) != TidyTag_PRE )
                {
                    list = InferredTag( doc, "pre" );
                    InsertNodeBeforeElement(node, list);
                }

                /* remove node and append to contents of list */
                RemoveNode(node);
                InsertNodeAtEnd(list, node);
                StripSpan( doc, node );
                InsertNodeAtEnd(list, br);
                node = list->next;
            }
            else
                list = null;
        }
        else
            list = null;

        /* strip out style and class attributes */
        if (node->type == StartTag || node->type == StartEndTag)
            PurgeWord2000Attributes( doc, node );

        if (node->content)
            CleanWord2000( doc, node->content );

        node = node->next;
    }
}

Bool IsWord2000( TidyDocImpl* doc )
{
    AttVal *attval;
    Node *node, *head;
    Node *html = FindHTML( doc );

    if (html && GetAttrByName(html, "xmlns:o"))
        return yes;
    
    /* search for <meta name="GENERATOR" content="Microsoft ..."> */
    head = FindHEAD( doc );

    if (head)
    {
        for (node = head->content; node; node = node->next)
        {
            if ( !nodeIsMETA(node) )
                continue;

            attval = AttrGetById( node, TidyAttr_NAME );

            if ( !AttrMatches(attval, "generator") )
                continue;

            attval =  AttrGetById( node, TidyAttr_CONTENT );

            if ( AttrContains(attval, "Microsoft") )
                return yes;
        }
    }

    return no;
}

/* where appropriate move object elements from head to body */
void BumpObject( TidyDocImpl* doc, Node *html )
{
    Node *node, *next, *head = null, *body = null;

    if (!html)
        return;

    for ( node = html->content; node != null; node = node->next )
    {
        if ( nodeIsHEAD(node) )
            head = node;

        if ( nodeIsBODY(node) )
            body = node;
    }

    if ( head != null && body != null )
    {
        for (node = head->content; node != null; node = next)
        {
            next = node->next;

            if ( nodeIsOBJECT(node) )
            {
                Node *child;
                Bool bump = no;

                for (child = node->content; child != null; child = child->next)
                {
                    /* bump to body unless content is param */
                    if ( (child->type == TextNode && !IsBlank(doc->lexer, node))
                         || !nodeIsPARAM(child) )
                    {
                            bump = yes;
                            break;
                    }
                }

                if ( bump )
                {
                    RemoveNode( node );
                    InsertNodeAtStart( body, node );
                }
            }
        }
    }
}

void FixBrakes( TidyDocImpl* pDoc, Node *pParent )
{
    Node *pNode;
    Bool bBRDeleted = no;

    if (NULL == pParent)
        return;

    /*  First, check the status of All My Children  */
    for ( pNode = pParent->content; NULL != pNode; pNode = pNode->next )
    {
        FixBrakes( pDoc, pNode );
    }

    /*  As long as my last child is a <br />, move it to my last peer  */
    if ( nodeCMIsBlock( pParent ))
    { 
        for ( pNode = pParent->last; 
              NULL != pNode && nodeIsBR( pNode ); 
              pNode = pParent->last ) 
        {
            if ( NULL == pNode->attributes && no == bBRDeleted )
            {
                DiscardElement( pDoc, pNode );
                bBRDeleted = yes;
            }
            else
            {
                RemoveNode( pNode );
                InsertNodeAfterElement( pParent, pNode );
            }
        }
        TrimEmptyElement( pDoc, pParent );
    }
}

void VerifyHTTPEquiv( TidyDocImpl* pDoc, Node *pHead )
{
    if (!nodeIsHEAD( pHead ))
        pHead = FindHEAD( pDoc );
    if (NULL != pHead)
    {
        /*  Find any meta tag which has an http-equiv tag 
            where value is content-type  */
        Node *pNode;

        for (pNode = pHead->content; NULL != pNode; pNode = pNode->next)
        {
            if (nodeIsMETA( pNode ))
            {
                AttVal *pAttVal;
                if (NULL != (pAttVal = GetAttrByName( pNode, "http-equiv" )))
                {
                    if (0 != tmbstrcasecmp( pAttVal->value, "CONTENT-TYPE" ))
                        continue;
                    if (NULL != (pAttVal = GetAttrByName( pNode, "content" )))
                    {
                        StyleProp *pFirstProp = null, *pLastProp = null, *prop = null;
                        tmbstr s, pszBegin, pszEnd;

                        pszBegin = s = tmbstrdup( pAttVal->value );
                        while ('\0' != *pszBegin)
                        {
                            while (isspace( *pszBegin ))
                                pszBegin++;
                            pszEnd = pszBegin;
                            while ('\0' != *pszEnd && ';' != *pszEnd)
                                pszEnd++;
                            if (';' == *pszEnd )
                                *(pszEnd++) = '\0';
                            if (pszEnd > pszBegin)
                            {
                                prop = (StyleProp *)MemAlloc(sizeof(StyleProp));
                                prop->name = tmbstrdup( pszBegin );
                                prop->value = null;
                                prop->next = null;

                                if (null != pLastProp)
                                    pLastProp->next = prop;
                                else
                                    pFirstProp = prop;
                                pLastProp = prop;
                                pszBegin = pszEnd;
                            }
                        }
                        MemFree( s );

                        /*  find the charset property */
                        for (prop = pFirstProp; null != prop; prop = prop->next)
                        {
                            if (0 == tmbstrncasecmp( prop->name, "charset", 7 ))
                            {
                                ctmbstr enc = null;

                                MemFree( prop->name );
                                prop->name = MemAlloc( 32 );
                                switch ( cfg( pDoc, TidyOutCharEncoding) )
                                {
                                    case RAW:       enc = "raw";          break;
                                    case ASCII:     enc = "us-ascii";     break;
                                    case LATIN1:    enc = "iso-8859-1";   break;
                                    case UTF8:      enc = "UTF8";         break;
                                    case ISO2022:   enc = "iso-2022";     break;
                                    case MACROMAN:  enc = "mac";          break;
                                    case WIN1252:   enc = "windows-1252"; break;
#if SUPPORT_UTF16_ENCODINGS
                                    case UTF16LE:   enc = "UTF-16LE";     break;
                                    case UTF16BE:   enc = "UTF-16BE";     break;
                                    case UTF16:     enc = "UTF-16";       break;
#endif
#if SUPPORT_ASIAN_ENCODINGS
                                    case BIG5:      enc = "big5";         break;
                                    case SHIFTJIS:  enc = "shiftjis";     break;
#endif
                                }
                                sprintf( prop->name, "charset=%s", enc );
                                s = CreatePropString( pFirstProp );
                                MemFree( pAttVal->value );
                                pAttVal->value = s;
                                FreeStyleProps(prop);
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
}

#define MissingVersion(ver, verWanted)  (!(ver & verWanted) && !(ver & VERS_PROPRIETARY))

static Bool AttrCompliance( TidyDocImpl* doc, Node* node, uint versWanted )
{
    Bool compliant = yes;
    AttVal* attr = node->attributes;
    for ( /**/; attr; attr = attr->next )
    {
        uint attrVer = AttrVersions( attr );
        if ( MissingVersion(attrVer, versWanted) )
        {
            ReportNonCompliantAttr( doc, node, attr, versWanted );
            compliant = no;
        }

        /* No align, except on: <col>, <colgroup>, <tbody>, <td>,
        ** <tfoot>, <th>, <thead>, <tr>
        */
        if ( attrIsALIGN(attr) && VERS_HTML40_STRICT==versWanted )
        {
            switch ( TagId(node) )
            {
            case TidyTag_COL:
            case TidyTag_COLGROUP:
            case TidyTag_TBODY:
            case TidyTag_TD:
            case TidyTag_TFOOT:
            case TidyTag_TH:
            case TidyTag_THEAD:
            case TidyTag_TR:
                break;

            default:
                ReportNonCompliantAttr( doc, node, attr, versWanted );
                compliant = no;
                break;
            }
        }
    }
    return compliant;
}

static Bool NodeCompliance( TidyDocImpl* doc, Node* node, uint versWanted )
{
    Bool compliant = yes;
    Bool checkCM = no;

    if ( !node )
      return no;

    switch ( node->type )
    {
#if 0
    case TidyNode_Root:        /* Root */
    case TidyNode_DocType:     /* DOCTYPE */
    case TidyNode_Comment:     /* Comment */
    case TidyNode_ProcIns:     /* Processing Instruction */
        break;
#endif

    case TidyNode_Text:        /* Text */
        checkCM = yes;
        break;

    case TidyNode_Start:       /* Start Tag */
    case TidyNode_StartEnd:    /* Start/End (empty) Tag */
        checkCM = !nodeCMIsBlock( node );
        compliant = AttrCompliance( doc, node, versWanted );
        if ( compliant )
        {
            uint nodeVer = node->tag->versions;
            if ( MissingVersion(nodeVer, versWanted) )
            {
                ReportNonCompliantNode( doc, node,
                                        OBSOLETE_ELEMENT, versWanted );
                compliant = no;
            }
        }
        if ( compliant && VERS_HTML40_STRICT == versWanted )
        {
            AttVal* attr = null;
            switch ( TagId(node) )
            {
            case TidyTag_BR: /* no clear */
                attr = AttrGetById( node, TidyAttr_CLEAR );
                break;

            case TidyTag_HR: /* no size, shade */
                attr = AttrGetById( node, TidyAttr_SIZE );
                if ( !attr )
                    attr = AttrGetById( node, TidyAttr_NOSHADE );
                break;

            case TidyTag_IMG: /* no border */
                attr = AttrGetById( node, TidyAttr_BORDER );
                break;

            case TidyTag_LI: /* no value, type */
                attr = AttrGetById( node, TidyAttr_TYPE );
                if ( !attr )
                    attr = AttrGetById( node, TidyAttr_VALUE );
                break;

            case TidyTag_OL: /* no start, type */
                attr = AttrGetById( node, TidyAttr_TYPE );
                if ( !attr )
                    attr = AttrGetById( node, TidyAttr_START );
                break;

            case TidyTag_PRE: /* no width */
                attr = AttrGetById( node, TidyAttr_WIDTH );
                break;

            case TidyTag_SCRIPT: /* no language */
                attr = AttrGetById( node, TidyAttr_LANGUAGE );
                break;

            case TidyTag_TD: /* no width, height */
            case TidyTag_TH:
                attr = AttrGetById( node, TidyAttr_WIDTH );
                if ( !attr )
                    attr = AttrGetById( node, TidyAttr_HEIGHT );
                break;

            case TidyTag_UL: /* no type */
                attr = AttrGetById( node, TidyAttr_TYPE );
                break;
            }
            if ( attr )
            {
              ReportNonCompliantAttr( doc, node, attr, versWanted );
              compliant = no;
            }
        }
        break;

#if 0
    case TidyNode_End:         /* End Tag */
    case TidyNode_CDATA:       /* Unparsed Text */
    case TidyNode_Section:     /* XML Section */
    case TidyNode_Asp:         /* ASP Source */
    case TidyNode_Jste:        /* JSTE Source */
    case TidyNode_Php:         /* PHP Source */
    case TidyNode_XmlDecl:     /* XML Declaration */
        break;
#endif
    }

    /* Check inline elements and text nodes
    ** not a child of %block content model.
    */
    if ( compliant && checkCM )
    {
        Node* parent = node->parent;
        if ( nodeIsBODY(parent)       ||
             nodeIsMAP(parent)        ||
             nodeIsBLOCKQUOTE(parent) ||
             nodeIsFORM(parent)       ||
             nodeIsNOSCRIPT(parent) )
        {
            ReportNonCompliantNode( doc, parent,
                                    MIXED_CONTENT_IN_BLOCK, versWanted );
        }
    }

    /* Scan all child nodes */
    for ( node=node->content; node; node = node->next )
    {
        Bool comply = NodeCompliance( doc, node, versWanted );
        if ( compliant && !comply )
            compliant = no;
    }

    return compliant;
}

Bool  HTMLVersionCompliance( TidyDocImpl* doc )
{
    Bool compliant = no;
    uint versWanted = VERS_HTML32;
    uint dtmode = cfg( doc, TidyDoctypeMode );
    uint  contver = (uint) doc->lexer->versions;
    uint  dtver = (uint) doc->lexer->doctype;

    if ( TidyDoctypeStrict == dtmode || VERS_HTML40_STRICT == dtver )
        versWanted = VERS_HTML40_STRICT;
    else if ( TidyDoctypeLoose == dtmode || VERS_HTML40_LOOSE == dtver )
        versWanted = VERS_HTML40_LOOSE;

    compliant = ( (versWanted & contver) != 0 );
    if ( !compliant )
        NodeCompliance( doc, doc->root, versWanted );
    return compliant;
}

