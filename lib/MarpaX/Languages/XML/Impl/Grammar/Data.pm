package MarpaX::Languages::XML::Impl::Grammar::Data;
#
# A little bit painful: Data::Section does not work well with Moops
# so I put that in a separator and old-style package
#
use strict;
use diagnostics;
use warnings FATAL => 'all';
use Data::Section -setup;

sub sectionData {
  my ($class, $sectionName) = @_;
  return __PACKAGE__->section_data($sectionName);
}

1;

__DATA__
__[ xml10 ]__
inaccessible is ok by default
:default ::= action => [values]
lexeme default = action => [start,length,value,name] forgiving => 1

# start                         ::= document | extParsedEnt | extSubset
start                         ::= $START
MiscAny                       ::= Misc*
# Note: end_document is when either we abandoned parsing or reached the end of input of the 'document' grammar
document                      ::= prolog element MiscAny
Name                          ::= NAME
Names                         ::= Name+ separator => SPACE proper => 1
Nmtoken                       ::= NMTOKENMANY
Nmtokens                      ::= Nmtoken+ separator => SPACE proper => 1

EntityValue                   ::= DQUOTE EntityValueInteriorDquote DQUOTE
                                | SQUOTE EntityValueInteriorSquote SQUOTE
EntityValueInteriorDquoteUnit ::= ENTITYVALUEINTERIORDQUOTEUNIT
PEReferenceMany               ::= PEReference+
EntityValueInteriorDquoteUnit ::= PEReferenceMany
ReferenceMany                 ::= Reference+
EntityValueInteriorDquoteUnit ::= ReferenceMany
EntityValueInteriorDquote     ::= EntityValueInteriorDquoteUnit*
EntityValueInteriorSquoteUnit ::= ENTITYVALUEINTERIORSQUOTEUNIT
EntityValueInteriorSquoteUnit ::= ReferenceMany
EntityValueInteriorSquoteUnit ::= PEReferenceMany
EntityValueInteriorSquote     ::= EntityValueInteriorSquoteUnit*

AttValue                      ::=  DQUOTE AttValueInteriorDquote DQUOTE
                                |  SQUOTE AttValueInteriorSquote SQUOTE
AttValueInteriorDquoteUnit    ::= ATTVALUEINTERIORDQUOTEUNIT
AttValueInteriorDquoteUnit    ::= ReferenceMany
AttValueInteriorDquote        ::= AttValueInteriorDquoteUnit*
AttValueInteriorSquoteUnit    ::= ATTVALUEINTERIORSQUOTEUNIT
AttValueInteriorSquoteUnit    ::= ReferenceMany
AttValueInteriorSquote        ::= AttValueInteriorSquoteUnit*

SystemLiteral                 ::= DQUOTE NOT_DQUOTEMANY DQUOTE
                                | DQUOTE                DQUOTE
                                | SQUOTE NOT_SQUOTEMANY SQUOTE
                                | SQUOTE                SQUOTE
PubidCharDquoteMany           ::= PUBIDCHARDQUOTEMANY
PubidCharSquoteMany           ::= PUBIDCHARSQUOTEMANY
PubidLiteral                  ::= DQUOTE PubidCharDquoteMany DQUOTE
                                | DQUOTE                     DQUOTE
                                | SQUOTE PubidCharSquoteMany SQUOTE
                                | SQUOTE                     SQUOTE

CharData                      ::= CHARDATAMANY

CommentCharAny                ::= COMMENTCHARMANY
CommentCharAny                ::=
Comment                       ::= COMMENT_START CommentCharAny COMMENT_END

PI                            ::= PI_START PITarget S PICHARDATAMANY PI_END
                                | PI_START PITarget S                PI_END
                                | PI_START PITarget                  PI_END

PITarget                      ::= PITARGET
CDSect                        ::= CDStart CData CDEnd
CDStart                       ::= CDATA_START
CData                         ::= CDATAMANY
CData                         ::=
CDEnd                         ::= CDATA_END
prolog                        ::= (internal_event_for_immediate_pause) XMLDecl MiscAny
prolog                        ::= (internal_event_for_immediate_pause)         MiscAny
prolog                        ::= (internal_event_for_immediate_pause) XMLDecl MiscAny doctypedecl MiscAny
prolog                        ::= (internal_event_for_immediate_pause)         MiscAny doctypedecl MiscAny
XMLDecl                       ::= XMLDECL_START VersionInfo EncodingDecl SDDecl S XMLDECL_END
XMLDecl                       ::= XMLDECL_START VersionInfo EncodingDecl SDDecl   XMLDECL_END
XMLDecl                       ::= XMLDECL_START VersionInfo EncodingDecl        S XMLDECL_END
XMLDecl                       ::= XMLDECL_START VersionInfo EncodingDecl          XMLDECL_END
XMLDecl                       ::= XMLDECL_START VersionInfo              SDDecl S XMLDECL_END
XMLDecl                       ::= XMLDECL_START VersionInfo              SDDecl   XMLDECL_END
XMLDecl                       ::= XMLDECL_START VersionInfo                     S XMLDECL_END
XMLDecl                       ::= XMLDECL_START VersionInfo                       XMLDECL_END
VersionInfo                   ::= S VERSION Eq SQUOTE VersionNum SQUOTE
VersionInfo                   ::= S VERSION Eq DQUOTE VersionNum DQUOTE
Eq                            ::= S EQUAL S
Eq                            ::= S EQUAL
Eq                            ::=   EQUAL S
Eq                            ::=   EQUAL
VersionNum                    ::= VERSIONNUM
Misc                          ::= Comment | PI | S
doctypedecl                   ::= DOCTYPE_START S Name              S LBRACKET intSubset RBRACKET S DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl                   ::= DOCTYPE_START S Name              S LBRACKET intSubset RBRACKET   DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl                   ::= DOCTYPE_START S Name                LBRACKET intSubset RBRACKET S DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl                   ::= DOCTYPE_START S Name                LBRACKET intSubset RBRACKET   DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl                   ::= DOCTYPE_START S Name              S                               DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl                   ::= DOCTYPE_START S Name                                              DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl                   ::= DOCTYPE_START S Name S ExternalID S LBRACKET intSubset RBRACKET S DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl                   ::= DOCTYPE_START S Name S ExternalID S LBRACKET intSubset RBRACKET   DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl                   ::= DOCTYPE_START S Name S ExternalID   LBRACKET intSubset RBRACKET S DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl                   ::= DOCTYPE_START S Name S ExternalID   LBRACKET intSubset RBRACKET   DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl                   ::= DOCTYPE_START S Name S ExternalID S                               DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl                   ::= DOCTYPE_START S Name S ExternalID                                 DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
DeclSep                       ::= PEReference   # [WFC: PE Between Declarations]
                                | S
intSubsetUnit                 ::= markupdecl | DeclSep
intSubset                     ::= intSubsetUnit*
markupdecl                    ::= elementdecl  # [VC: Proper Declaration/PE Nesting] [WFC: PEs in Internal Subset]
                                | AttlistDecl  # [VC: Proper Declaration/PE Nesting] [WFC: PEs in Internal Subset]
                                | EntityDecl   # [VC: Proper Declaration/PE Nesting] [WFC: PEs in Internal Subset]
                                | NotationDecl # [VC: Proper Declaration/PE Nesting] [WFC: PEs in Internal Subset]
                                | PI           # [VC: Proper Declaration/PE Nesting] [WFC: PEs in Internal Subset]
                                | Comment      # [VC: Proper Declaration/PE Nesting] [WFC: PEs in Internal Subset]
extSubset                     ::= TextDecl extSubsetDecl
extSubset                     ::=          extSubsetDecl
extSubsetDeclUnit             ::= markupdecl | conditionalSect | DeclSep
extSubsetDecl                 ::= extSubsetDeclUnit*
SDDecl                        ::= S STANDALONE Eq SQUOTE YES SQUOTE # [VC: Standalone Document Declaration]
                                | S STANDALONE Eq SQUOTE  NO SQUOTE  # [VC: Standalone Document Declaration]
                                | S STANDALONE Eq DQUOTE YES DQUOTE  # [VC: Standalone Document Declaration]
                                | S STANDALONE Eq DQUOTE  NO DQUOTE  # [VC: Standalone Document Declaration]
element                       ::= (internal_event_for_immediate_pause) EmptyElemTag (start_element) (end_element)
                                | (internal_event_for_immediate_pause) STag (start_element) content ETag (end_element) # [WFC: Element Type Match] [VC: Element Valid]
STagUnit                      ::= S Attribute
STagUnitAny                   ::= STagUnit*
STagName                      ::= Name
STag                          ::= ELEMENT_START STagName STagUnitAny S ELEMENT_END # [WFC: Unique Att Spec]
STag                          ::= ELEMENT_START STagName STagUnitAny   ELEMENT_END # [WFC: Unique Att Spec]
AttributeName                 ::= Name
Attribute                     ::= AttributeName Eq AttValue  # [VC: Attribute Value Type] [WFC: No External Entity References] [WFC: No < in Attribute Values]
ETag                          ::= ETAG_START Name S ETAG_END
ETag                          ::= ETAG_START Name   ETAG_END
contentUnit                   ::= element CharData
                                | element
                                | Reference CharData
                                | Reference
                                | CDSect CharData
                                | CDSect
                                | PI CharData
                                | PI
                                | Comment CharData
                                | Comment
contentUnitAny                ::= contentUnit*
content                       ::= CharData contentUnitAny
content                       ::=          contentUnitAny
EmptyElemTagUnit              ::= S Attribute
EmptyElemTagUnitAny           ::= EmptyElemTagUnit*
EmptyElemTag                  ::= ELEMENT_START Name EmptyElemTagUnitAny S EMPTYELEM_END   # [WFC: Unique Att Spec]
EmptyElemTag                  ::= ELEMENT_START Name EmptyElemTagUnitAny   EMPTYELEM_END   # [WFC: Unique Att Spec]
elementdecl                   ::= ELEMENTDECL_START S Name S contentspec S ELEMENTDECL_END # [VC: Unique Element Type Declaration]
elementdecl                   ::= ELEMENTDECL_START S Name S contentspec   ELEMENTDECL_END # [VC: Unique Element Type Declaration]
contentspec                   ::= EMPTY | ANY | Mixed | children
ChoiceOrSeq                   ::= choice | seq
children                      ::= ChoiceOrSeq
                                | ChoiceOrSeq QUESTIONMARK
                                | ChoiceOrSeq STAR
                                | ChoiceOrSeq PLUS
#
# Writen like this for the merged of XML+NS
#
NameOrChoiceOrSeq             ::= Name
NameOrChoiceOrSeq             ::= choice
NameOrChoiceOrSeq             ::= seq
cp                            ::= NameOrChoiceOrSeq
                                | NameOrChoiceOrSeq QUESTIONMARK
                                | NameOrChoiceOrSeq STAR
                                | NameOrChoiceOrSeq PLUS
choiceUnit                    ::= S OR S cp
choiceUnit                    ::= S OR   cp
choiceUnit                    ::=   OR S cp
choiceUnit                    ::=   OR   cp
choiceUnitMany                ::= choiceUnit+
choice                        ::= CHOICE_START S cp choiceUnitMany S CHOICE_END # [VC: Proper Group/PE Nesting]
choice                        ::= CHOICE_START S cp choiceUnitMany   CHOICE_END # [VC: Proper Group/PE Nesting]
choice                        ::= CHOICE_START   cp choiceUnitMany S CHOICE_END # [VC: Proper Group/PE Nesting]
choice                        ::= CHOICE_START   cp choiceUnitMany   CHOICE_END # [VC: Proper Group/PE Nesting]
seqUnit                       ::= S COMMA S cp
seqUnit                       ::= S COMMA   cp
seqUnit                       ::=   COMMA S cp
seqUnit                       ::=   COMMA   cp
seqUnitAny                    ::= seqUnit*
seq                           ::= SEQ_START S cp seqUnitAny S SEQ_END # [VC: Proper Group/PE Nesting]
seq                           ::= SEQ_START S cp seqUnitAny   SEQ_END # [VC: Proper Group/PE Nesting]
seq                           ::= SEQ_START   cp seqUnitAny S SEQ_END # [VC: Proper Group/PE Nesting]
seq                           ::= SEQ_START   cp seqUnitAny   SEQ_END # [VC: Proper Group/PE Nesting]
MixedUnit                     ::= S OR S Name
MixedUnit                     ::= S OR   Name
MixedUnit                     ::=   OR S Name
MixedUnit                     ::=   OR   Name
MixedUnitAny                  ::= MixedUnit*
Mixed                         ::= MIXED_START S PCDATA MixedUnitAny S MIXED_END1 # [VC: Proper Group/PE Nesting] [VC: No Duplicate Types]
                                | MIXED_START S PCDATA MixedUnitAny   MIXED_END1 # [VC: Proper Group/PE Nesting] [VC: No Duplicate Types]
                                | MIXED_START   PCDATA MixedUnitAny S MIXED_END1 # [VC: Proper Group/PE Nesting] [VC: No Duplicate Types]
                                | MIXED_START   PCDATA MixedUnitAny   MIXED_END1 # [VC: Proper Group/PE Nesting] [VC: No Duplicate Types]
                                | MIXED_START S PCDATA              S MIXED_END2 # [VC: Proper Group/PE Nesting] [VC: No Duplicate Types]
                                | MIXED_START S PCDATA                MIXED_END2 # [VC: Proper Group/PE Nesting] [VC: No Duplicate Types]
                                | MIXED_START   PCDATA              S MIXED_END2 # [VC: Proper Group/PE Nesting] [VC: No Duplicate Types]
                                | MIXED_START   PCDATA                MIXED_END2 # [VC: Proper Group/PE Nesting] [VC: No Duplicate Types]
AttlistDecl                   ::= ATTLIST_START S Name AttDefAny S ATTLIST_END
AttlistDecl                   ::= ATTLIST_START S Name AttDefAny   ATTLIST_END
AttDefAny                     ::= AttDef*
AttDef                        ::= S Name S AttType S DefaultDecl
AttType                       ::= StringType | TokenizedType | EnumeratedType
StringType                    ::= CDATA
TokenizedType                 ::= ID                 # [VC: ID] [VC: One ID per Element Type] [VC: ID Attribute Default]
                                | IDREF              # [VC: IDREF]
                                | IDREFS             # [VC: IDREF]
                                | ENTITY             # [VC: Entity Name]
                                | ENTITIES           # [VC: Entity Name]
                                | NMTOKEN            # [VC: Name Token]
                                | NMTOKENS           # [VC: Name Token]
EnumeratedType                ::= NotationType | Enumeration
NotationTypeUnit              ::= S OR S Name
NotationTypeUnit              ::= S OR   Name
NotationTypeUnit              ::=   OR S Name
NotationTypeUnit              ::=   OR   Name
NotationTypeUnitAny           ::= NotationTypeUnit*
NotationType                  ::= NOTATION S NOTATION_START S Name NotationTypeUnitAny S NOTATION_END # [VC: Notation Attributes] [VC: One Notation Per Element Type] [VC: No Notation on Empty Element] [VC: No Duplicate Tokens]
NotationType                  ::= NOTATION S NOTATION_START S Name NotationTypeUnitAny   NOTATION_END # [VC: Notation Attributes] [VC: One Notation Per Element Type] [VC: No Notation on Empty Element] [VC: No Duplicate Tokens]
NotationType                  ::= NOTATION S NOTATION_START   Name NotationTypeUnitAny S NOTATION_END # [VC: Notation Attributes] [VC: One Notation Per Element Type] [VC: No Notation on Empty Element] [VC: No Duplicate Tokens]
NotationType                  ::= NOTATION S NOTATION_START   Name NotationTypeUnitAny   NOTATION_END # [VC: Notation Attributes] [VC: One Notation Per Element Type] [VC: No Notation on Empty Element] [VC: No Duplicate Tokens]
EnumerationUnit               ::= S OR S Nmtoken
EnumerationUnit               ::= S OR   Nmtoken
EnumerationUnit               ::=   OR S Nmtoken
EnumerationUnit               ::=   OR   Nmtoken
EnumerationUnitAny            ::= EnumerationUnit*
Enumeration                   ::= ENUMERATION_START S Nmtoken EnumerationUnitAny S ENUMERATION_END # [VC: Enumeration] [VC: No Duplicate Tokens]
Enumeration                   ::= ENUMERATION_START S Nmtoken EnumerationUnitAny   ENUMERATION_END # [VC: Enumeration] [VC: No Duplicate Tokens]
Enumeration                   ::= ENUMERATION_START   Nmtoken EnumerationUnitAny S ENUMERATION_END # [VC: Enumeration] [VC: No Duplicate Tokens]
Enumeration                   ::= ENUMERATION_START   Nmtoken EnumerationUnitAny   ENUMERATION_END # [VC: Enumeration] [VC: No Duplicate Tokens]
DefaultDecl                   ::= REQUIRED | IMPLIED
                                |            AttValue                              # [VC: Required Attribute] [VC: Attribute Default Value Syntactically Correct] [WFC: No < in Attribute Values] [VC: Fixed Attribute Default] [WFC: No External Entity References]
                                | FIXED S AttValue                              # [VC: Required Attribute] [VC: Attribute Default Value Syntactically Correct] [WFC: No < in Attribute Values] [VC: Fixed Attribute Default] [WFC: No External Entity References]
conditionalSect               ::= includeSect | ignoreSect
includeSect                   ::= INCLUDESECT_START S INCLUDE S LBRACKET extSubsetDecl          INCLUDESECT_END # [VC: Proper Conditional Section/PE Nesting]
includeSect                   ::= INCLUDESECT_START S INCLUDE   LBRACKET extSubsetDecl          INCLUDESECT_END # [VC: Proper Conditional Section/PE Nesting]
includeSect                   ::= INCLUDESECT_START   INCLUDE S LBRACKET extSubsetDecl          INCLUDESECT_END # [VC: Proper Conditional Section/PE Nesting]
includeSect                   ::= INCLUDESECT_START   INCLUDE   LBRACKET extSubsetDecl          INCLUDESECT_END # [VC: Proper Conditional Section/PE Nesting]
ignoreSect                    ::= IGNORESECT_START S  IGNORE  S LBRACKET ignoreSectContentsAny  IGNORESECT_END
                                | IGNORESECT_START S  IGNORE    LBRACKET ignoreSectContentsAny  IGNORESECT_END
                                | IGNORESECT_START    IGNORE  S LBRACKET ignoreSectContentsAny  IGNORESECT_END
                                | IGNORESECT_START    IGNORE    LBRACKET ignoreSectContentsAny  IGNORESECT_END
                                | IGNORESECT_START S  IGNORE  S LBRACKET                        IGNORESECT_END # [VC: Proper Conditional Section/PE Nesting]
                                | IGNORESECT_START S  IGNORE    LBRACKET                        IGNORESECT_END # [VC: Proper Conditional Section/PE Nesting]
                                | IGNORESECT_START    IGNORE  S LBRACKET                        IGNORESECT_END # [VC: Proper Conditional Section/PE Nesting]
                                | IGNORESECT_START    IGNORE    LBRACKET                        IGNORESECT_END # [VC: Proper Conditional Section/PE Nesting]
ignoreSectContentsAny         ::= ignoreSectContents*
ignoreSectContentsUnit        ::= IGNORESECTCONTENTSUNIT_START ignoreSectContents IGNORESECTCONTENTSUNIT_END Ignore
ignoreSectContentsUnit        ::= IGNORESECTCONTENTSUNIT_START                    IGNORESECTCONTENTSUNIT_END Ignore
ignoreSectContentsUnitAny     ::= ignoreSectContentsUnit*
ignoreSectContents            ::= Ignore ignoreSectContentsUnitAny
Ignore                        ::= IGNOREMANY
CharRef                       ::= CHARREF_START1 DIGITMANY CHARREF_END1
                                | CHARREF_START2 ALPHAMANY CHARREF_END2 # [WFC: Legal Character]
Reference                     ::= EntityRef | CharRef
EntityRef                     ::= ENTITYREF_START Name ENTITYREF_END # [WFC: Entity Declared] [VC: Entity Declared] [WFC: Parsed Entity] [WFC: No Recursion]
PEReference                   ::= PEREFERENCE_START Name PEREFERENCE_END # [VC: Entity Declared] [WFC: No Recursion] [WFC: In DTD]
EntityDecl                    ::= GEDecl | PEDecl
GEDecl                        ::= ENTITY_START S           Name S EntityDef S ENTITY_END
GEDecl                        ::= ENTITY_START S           Name S EntityDef   ENTITY_END
PEDecl                        ::= ENTITY_START S PERCENT S Name S PEDef     S ENTITY_END
PEDecl                        ::= ENTITY_START S PERCENT S Name S PEDef       ENTITY_END
EntityDef                     ::= EntityValue
                                | ExternalID
                                | ExternalID NDataDecl
PEDef                         ::= EntityValue
                                | ExternalID
ExternalID                    ::= SYSTEM S                SystemLiteral
                                | PUBLIC S PubidLiteral S SystemLiteral
NDataDecl                     ::= S NDATA S Name  # [VC: Notation Declared]
TextDecl                      ::= TEXTDECL_START VersionInfo EncodingDecl S TEXTDECL_END
TextDecl                      ::= TEXTDECL_START VersionInfo EncodingDecl   TEXTDECL_END
TextDecl                      ::= TEXTDECL_START             EncodingDecl S TEXTDECL_END
TextDecl                      ::= TEXTDECL_START             EncodingDecl   TEXTDECL_END
extParsedEnt                  ::= TextDecl content
extParsedEnt                  ::=          content
EncodingDecl                  ::= S ENCODING Eq DQUOTE EncName DQUOTE
EncodingDecl                  ::= S ENCODING Eq SQUOTE EncName SQUOTE
EncName                       ::= ENCNAME
NotationDecl                  ::= NOTATIONDECL_START S Name S ExternalID S NOTATIONDECL_END # [VC: Unique Notation Name]
NotationDecl                  ::= NOTATIONDECL_START S Name S ExternalID   NOTATIONDECL_END # [VC: Unique Notation Name]
NotationDecl                  ::= NOTATIONDECL_START S Name S   PublicID S NOTATIONDECL_END # [VC: Unique Notation Name]
NotationDecl                  ::= NOTATIONDECL_START S Name S   PublicID   NOTATIONDECL_END # [VC: Unique Notation Name]
PublicID                      ::= PUBLIC S PubidLiteral

#
# Generic internal token matching anything
#
__ANYTHING ~ [\s\S]
_NAME ~ __ANYTHING
_NMTOKENMANY ~ __ANYTHING
_ENTITYVALUEINTERIORDQUOTEUNIT ~ __ANYTHING
_ENTITYVALUEINTERIORSQUOTEUNIT ~ __ANYTHING
_ATTVALUEINTERIORDQUOTEUNIT ~ __ANYTHING
_ATTVALUEINTERIORSQUOTEUNIT ~ __ANYTHING
_NOT_DQUOTEMANY ~ __ANYTHING
_NOT_SQUOTEMANY ~ __ANYTHING
_CHARDATAMANY ~ __ANYTHING
_COMMENTCHARMANY ~ __ANYTHING
_PITARGET ~ __ANYTHING
_CDATAMANY ~ __ANYTHING
_PICHARDATAMANY ~ __ANYTHING
_IGNOREMANY ~ __ANYTHING
_DIGITMANY ~ __ANYTHING
_ALPHAMANY ~ __ANYTHING
_ENCNAME ~ __ANYTHING
_S ~ __ANYTHING
_NCNAME ~ __ANYTHING
_PUBIDCHARDQUOTEMANY ~ __ANYTHING
_PUBIDCHARSQUOTEMANY ~ __ANYTHING
_SPACE ~ __ANYTHING
_DQUOTE ~ __ANYTHING
_SQUOTE ~ __ANYTHING
_COMMENT_START ~ __ANYTHING
_COMMENT_END ~ __ANYTHING
_PI_START ~ __ANYTHING
_PI_END ~ __ANYTHING
_CDATA_START ~ __ANYTHING
_CDATA_END ~ __ANYTHING
_XMLDECL_START ~ __ANYTHING
_XMLDECL_END ~ __ANYTHING
_VERSION ~ __ANYTHING
_EQUAL ~ __ANYTHING
_VERSIONNUM ~ __ANYTHING
_DOCTYPE_START ~ __ANYTHING
_DOCTYPE_END ~ __ANYTHING
_LBRACKET ~ __ANYTHING
_RBRACKET ~ __ANYTHING
_STANDALONE ~ __ANYTHING
_YES ~ __ANYTHING
_NO ~ __ANYTHING
_ELEMENT_START ~ __ANYTHING
_ELEMENT_END ~ __ANYTHING
_ETAG_START ~ __ANYTHING
_ETAG_END ~ __ANYTHING
_EMPTYELEM_END ~ __ANYTHING
_ELEMENTDECL_START ~ __ANYTHING
_ELEMENTDECL_END ~ __ANYTHING
_EMPTY ~ __ANYTHING
_ANY ~ __ANYTHING
_QUESTIONMARK ~ __ANYTHING
_STAR ~ __ANYTHING
_PLUS ~ __ANYTHING
_OR ~ __ANYTHING
_CHOICE_START ~ __ANYTHING
_CHOICE_END ~ __ANYTHING
_SEQ_START ~ __ANYTHING
_SEQ_END ~ __ANYTHING
_MIXED_START ~ __ANYTHING
_MIXED_END1 ~ __ANYTHING
_MIXED_END2 ~ __ANYTHING
_COMMA ~ __ANYTHING
_PCDATA ~ __ANYTHING
_ATTLIST_START ~ __ANYTHING
_ATTLIST_END ~ __ANYTHING
_CDATA ~ __ANYTHING
_ID ~ __ANYTHING
_IDREF ~ __ANYTHING
_IDREFS ~ __ANYTHING
_ENTITY ~ __ANYTHING
_ENTITIES ~ __ANYTHING
_NMTOKEN ~ __ANYTHING
_NMTOKENS ~ __ANYTHING
_NOTATION ~ __ANYTHING
_NOTATION_START ~ __ANYTHING
_NOTATION_END ~ __ANYTHING
_ENUMERATION_START ~ __ANYTHING
_ENUMERATION_END ~ __ANYTHING
_REQUIRED ~ __ANYTHING
_IMPLIED ~ __ANYTHING
_FIXED ~ __ANYTHING
_INCLUDE ~ __ANYTHING
_IGNORE ~ __ANYTHING
_INCLUDESECT_START ~ __ANYTHING
_INCLUDESECT_END ~ __ANYTHING
_IGNORESECT_START ~ __ANYTHING
_IGNORESECT_END ~ __ANYTHING
_IGNORESECTCONTENTSUNIT_START ~ __ANYTHING
_IGNORESECTCONTENTSUNIT_END ~ __ANYTHING
_CHARREF_START1 ~ __ANYTHING
_CHARREF_END1 ~ __ANYTHING
_CHARREF_START2 ~ __ANYTHING
_CHARREF_END2 ~ __ANYTHING
_ENTITYREF_START ~ __ANYTHING
_ENTITYREF_END ~ __ANYTHING
_PEREFERENCE_START ~ __ANYTHING
_PEREFERENCE_END ~ __ANYTHING
_ENTITY_START ~ __ANYTHING
_ENTITY_END ~ __ANYTHING
_PERCENT ~ __ANYTHING
_SYSTEM ~ __ANYTHING
_PUBLIC ~ __ANYTHING
_NDATA ~ __ANYTHING
_TEXTDECL_START ~ __ANYTHING
_TEXTDECL_END ~ __ANYTHING
_ENCODING ~ __ANYTHING
_NOTATIONDECL_START ~ __ANYTHING
_NOTATIONDECL_END ~ __ANYTHING
# :lexeme ~ <_XMLNSCOLON> priority => 1         # C.f. in Parser.pm
_XMLNSCOLON ~ __ANYTHING
# :lexeme ~ <_XMLNS> priority => 1              # C.f. in Parser.pm
_XMLNS ~ __ANYTHING
_COLON ~ __ANYTHING

NAME ::= _NAME
NMTOKENMANY ::= _NMTOKENMANY
ENTITYVALUEINTERIORDQUOTEUNIT ::= _ENTITYVALUEINTERIORDQUOTEUNIT
ENTITYVALUEINTERIORSQUOTEUNIT ::= _ENTITYVALUEINTERIORSQUOTEUNIT
ATTVALUEINTERIORDQUOTEUNIT ::= _ATTVALUEINTERIORDQUOTEUNIT
ATTVALUEINTERIORSQUOTEUNIT ::= _ATTVALUEINTERIORSQUOTEUNIT
NOT_DQUOTEMANY ::= _NOT_DQUOTEMANY
NOT_SQUOTEMANY ::= _NOT_SQUOTEMANY
CHARDATAMANY ::= _CHARDATAMANY
COMMENTCHARMANY ::= _COMMENTCHARMANY
PITARGET ::= _PITARGET
CDATAMANY ::= _CDATAMANY
PICHARDATAMANY ::= _PICHARDATAMANY
IGNOREMANY ::= _IGNOREMANY
DIGITMANY ::= _DIGITMANY
ALPHAMANY ::= _ALPHAMANY
ENCNAME ::= _ENCNAME
S ::= _S
NCNAME ::= _NCNAME
PUBIDCHARDQUOTEMANY ::= _PUBIDCHARDQUOTEMANY
PUBIDCHARSQUOTEMANY ::= _PUBIDCHARSQUOTEMANY
SPACE ::= _SPACE
DQUOTE ::= _DQUOTE
SQUOTE ::= _SQUOTE
COMMENT_START ::= _COMMENT_START
COMMENT_END ::= _COMMENT_END
PI_START ::= _PI_START
PI_END ::= _PI_END
CDATA_START ::= _CDATA_START
CDATA_END ::= _CDATA_END
XMLDECL_START ::= _XMLDECL_START
XMLDECL_END ::= _XMLDECL_END
VERSION ::= _VERSION
EQUAL ::= _EQUAL
VERSIONNUM ::= _VERSIONNUM
DOCTYPE_START ::= _DOCTYPE_START
DOCTYPE_END ::= _DOCTYPE_END
LBRACKET ::= _LBRACKET
RBRACKET ::= _RBRACKET
STANDALONE ::= _STANDALONE
YES ::= _YES
NO ::= _NO
ELEMENT_START ::= _ELEMENT_START
ELEMENT_END ::= _ELEMENT_END
ETAG_START ::= _ETAG_START
ETAG_END ::= _ETAG_END
EMPTYELEM_END ::= _EMPTYELEM_END
ELEMENTDECL_START ::= _ELEMENTDECL_START
ELEMENTDECL_END ::= _ELEMENTDECL_END
EMPTY ::= _EMPTY
ANY ::= _ANY
QUESTIONMARK ::= _QUESTIONMARK
STAR ::= _STAR
PLUS ::= _PLUS
OR ::= _OR
CHOICE_START ::= _CHOICE_START
CHOICE_END ::= _CHOICE_END
SEQ_START ::= _SEQ_START
SEQ_END ::= _SEQ_END
MIXED_START ::= _MIXED_START
MIXED_END1 ::= _MIXED_END1
MIXED_END2 ::= _MIXED_END2
COMMA ::= _COMMA
PCDATA ::= _PCDATA
ATTLIST_START ::= _ATTLIST_START
ATTLIST_END ::= _ATTLIST_END
CDATA ::= _CDATA
ID ::= _ID
IDREF ::= _IDREF
IDREFS ::= _IDREFS
ENTITY ::= _ENTITY
ENTITIES ::= _ENTITIES
NMTOKEN ::= _NMTOKEN
NMTOKENS ::= _NMTOKENS
NOTATION ::= _NOTATION
NOTATION_START ::= _NOTATION_START
NOTATION_END ::= _NOTATION_END
ENUMERATION_START ::= _ENUMERATION_START
ENUMERATION_END ::= _ENUMERATION_END
REQUIRED ::= _REQUIRED
IMPLIED ::= _IMPLIED
FIXED ::= _FIXED
INCLUDE ::= _INCLUDE
IGNORE ::= _IGNORE
INCLUDESECT_START ::= _INCLUDESECT_START
INCLUDESECT_END ::= _INCLUDESECT_END
IGNORESECT_START ::= _IGNORESECT_START
IGNORESECT_END ::= _IGNORESECT_END
IGNORESECTCONTENTSUNIT_START ::= _IGNORESECTCONTENTSUNIT_START
IGNORESECTCONTENTSUNIT_END ::= _IGNORESECTCONTENTSUNIT_END
CHARREF_START1 ::= _CHARREF_START1
CHARREF_END1 ::= _CHARREF_END1
CHARREF_START2 ::= _CHARREF_START2
CHARREF_END2 ::= _CHARREF_END2
ENTITYREF_START ::= _ENTITYREF_START
ENTITYREF_END ::= _ENTITYREF_END
PEREFERENCE_START ::= _PEREFERENCE_START
PEREFERENCE_END ::= _PEREFERENCE_END
ENTITY_START ::= _ENTITY_START
ENTITY_END ::= _ENTITY_END
PERCENT ::= _PERCENT
SYSTEM ::= _SYSTEM
PUBLIC ::= _PUBLIC
NDATA ::= _NDATA
TEXTDECL_START ::= _TEXTDECL_START
TEXTDECL_END ::= _TEXTDECL_END
ENCODING ::= _ENCODING
NOTATIONDECL_START ::= _NOTATIONDECL_START
NOTATIONDECL_END ::= _NOTATIONDECL_END
XMLNSCOLON ::= _XMLNSCOLON
XMLNS ::= _XMLNS
COLON ::= _COLON
#
# Internal nullable rule to force the recognizer to stop immeidately,
# before reading any lexeme
#
event '!internal_event_for_immediate_pause' = nulled <internal_event_for_immediate_pause>
internal_event_for_immediate_pause ::= ;
#
# Nullable rules
#
start_element       ::= ;
end_element         ::= ;
#
# Events can be added on-the-fly at grammar generation
#
__[ xmlns10:add ]__
NSAttName	   ::= PrefixedAttName (prefixed_attname)
                     | DefaultAttName (default_attname)
PrefixedAttName    ::= XMLNSCOLON NCName # [NSC: Reserved Prefixes and Namespace Names]
DefaultAttName     ::= XMLNS
NCName             ::= NCNAME            # Name - (Char* ':' Char*) /* An XML Name, minus the ":" */
QName              ::= PrefixedName (prefixed_name)
                     | UnprefixedName (unprefixed_name)
PrefixedName       ::= Prefix COLON LocalPart
UnprefixedName     ::= LocalPart
Prefix             ::= NCName
LocalPart          ::= NCName

__[ xmlns10:replace_or_add ]__
STag               ::= ELEMENT_START QName STagUnitAny S ELEMENT_END           # [NSC: Prefix Declared]
STag               ::= ELEMENT_START QName STagUnitAny   ELEMENT_END           # [NSC: Prefix Declared]
ETag               ::= ETAG_START QName S ETAG_END                             # [NSC: Prefix Declared]
ETag               ::= ETAG_START QName   ETAG_END                             # [NSC: Prefix Declared]
EmptyElemTag       ::= ELEMENT_START QName EmptyElemTagUnitAny S EMPTYELEM_END # [NSC: Prefix Declared]
EmptyElemTag       ::= ELEMENT_START QName EmptyElemTagUnitAny   EMPTYELEM_END # [NSC: Prefix Declared]
Attribute          ::= NSAttName (xmlns_attribute) Eq AttValue
Attribute          ::= QName (normal_attribute) Eq AttValue                                            # [NSC: Prefix Declared][NSC: No Prefix Undeclaring][NSC: Attributes Unique]
doctypedeclUnit    ::= markupdecl | PEReference | S
doctypedeclUnitAny ::= doctypedeclUnit*
doctypedecl        ::= DOCTYPE_START S QName              S LBRACKET doctypedeclUnitAny RBRACKET S DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl        ::= DOCTYPE_START S QName              S LBRACKET doctypedeclUnitAny RBRACKET   DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl        ::= DOCTYPE_START S QName                LBRACKET doctypedeclUnitAny RBRACKET S DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl        ::= DOCTYPE_START S QName                LBRACKET doctypedeclUnitAny RBRACKET   DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl        ::= DOCTYPE_START S QName              S                                        DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl        ::= DOCTYPE_START S QName                                                       DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl        ::= DOCTYPE_START S QName S ExternalID S LBRACKET doctypedeclUnitAny RBRACKET S DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl        ::= DOCTYPE_START S QName S ExternalID S LBRACKET doctypedeclUnitAny RBRACKET   DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl        ::= DOCTYPE_START S QName S ExternalID   LBRACKET doctypedeclUnitAny RBRACKET S DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl        ::= DOCTYPE_START S QName S ExternalID   LBRACKET doctypedeclUnitAny RBRACKET   DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl        ::= DOCTYPE_START S QName S ExternalID S                                        DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
doctypedecl        ::= DOCTYPE_START S QName S ExternalID                                          DOCTYPE_END # [VC: Root Element Type] [WFC: External Subset]
elementdecl        ::= ELEMENTDECL_START S QName S contentspec S ELEMENTDECL_END
elementdecl        ::= ELEMENTDECL_START S QName S contentspec   ELEMENTDECL_END
NameOrChoiceOrSeq  ::= QName
NameOrChoiceOrSeq  ::= choice
NameOrChoiceOrSeq  ::= seq
MixedUnit          ::= S OR S QName
MixedUnit          ::= S OR   QName
MixedUnit          ::=   OR S QName
MixedUnit          ::=   OR   QName
AttlistDecl        ::= ATTLIST_START S QName AttDefAny S ATTLIST_END
AttlistDecl        ::= ATTLIST_START S QName AttDefAny   ATTLIST_END
AttDef             ::= S QName     S AttType S DefaultDecl
AttDef             ::= S NSAttName S AttType S DefaultDecl

xmlns_attribute    ::= ;
normal_attribute   ::= ;
prefixed_attname   ::= ;
default_attname    ::= ;
prefixed_name      ::= ;
unprefixed_name    ::= ;
