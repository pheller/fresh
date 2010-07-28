<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:str="http://exslt.org/strings"
 xmlns:func="http://exslt.org/functions"
 xmlns:cfggrab="localhost"
 extension-element-prefixes="str func">
<xsl:import href="functions.xsl"/>
<xsl:import href="types.xsl"/>
<xsl:output method="xml" indent="yes" encoding="iso-8859-1" />

<xsl:variable name="shrun" select="xml"/>
<xsl:variable
 name="ver"
 select="document('show_version.xml', .)/xml"/>
<xsl:variable
 name="diag"
 select="document('show_diag.xml', .)/xml"/>
<xsl:variable
 name="shint"
 select="document('show_interface.xml', .)/xml"/>

<xsl:variable name="interfaces" select="$shint/interface"/>

<xsl:template match="card | subslot">
  <card>
    <!-- General card specific fields. -->
    <xsl:variable name="slotName" select="cfggrab:getSlotNameFromCard(.)"/>
    <xsl:attribute name="slot">
      <xsl:value-of select="$slotName"/>
    </xsl:attribute>
    <name>
      <xsl:value-of select="description"/>
    </name>
    <type>
      <xsl:choose>
        <xsl:when test="partno">
            <xsl:value-of select="partno"/>
        </xsl:when>
        <xsl:when test="top-assy-partno">
            <xsl:value-of select="top-assy-partno"/>
        </xsl:when>
      </xsl:choose>
    </type>
    <part-number>
      <xsl:choose>
        <xsl:when test="partno">
            <xsl:value-of select="partno"/>
        </xsl:when>
        <xsl:when test="top-assy-partno">
            <xsl:value-of select="top-assy-partno"/>
        </xsl:when>
      </xsl:choose>
    </part-number>
    <serial-number>
      <xsl:value-of select="serialno"/>
    </serial-number>

    <!-- Submodules. -->
    <xsl:apply-templates select="subslot"/>

    <!-- Physical interfaces on this card. -->
    <xsl:variable name="card" select="."/>

    <xsl:for-each select="$interfaces">
      <xsl:variable name="physical"   select="cfggrab:getInterfaceName(@name)"/>
      <xsl:variable name="isphysical" select="@name = $physical"/>
      <xsl:if test="$isphysical and cfggrab:onSlot($card, $physical)">
        <xsl:apply-templates mode="physical" select="."/>
      </xsl:if>
    </xsl:for-each>
  </card>
</xsl:template>

<xsl:template match="/xml">
  <host
   xmlns=""
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   xsi:noNamespaceSchemaLocation="model.xsd">
    <!-- General host specific fields. -->
    <xsl:attribute name="name">
      <xsl:value-of select="normalize-space(hostname)" />
    </xsl:attribute>
    <xsl:attribute name="domain">
      <xsl:value-of select="normalize-space(options/ip/domain)" />
    </xsl:attribute>
    <os>
      <system><xsl:text>IOS</xsl:text></system>
      <version><xsl:value-of select="$ver/version"/></version>
    </os>
    <model>
      <xsl:value-of select="$ver/model"/>
    </model>

    <!-- Chassis. -->
    <chassis>
      <xsl:attribute name="name">
        <xsl:value-of select="$ver/model"/>
      </xsl:attribute>
      <os>
        <system><xsl:text>IOS</xsl:text></system>
        <version><xsl:value-of select="$ver/version"/></version>
      </os>
      <model>
        <xsl:value-of select="$ver/model"/>
      </model>

      <equipment>
        <!-- Cards inserted directly into the chassis. -->
        <xsl:apply-templates select="$diag/card"/>

        <!-- Interfaces inserted directly into the chassis. -->
        <xsl:if test="not($diag/card)">
          <xsl:for-each select="$interfaces">
            <xsl:variable name="physical"   select="cfggrab:getInterfaceName(@name)"/>
            <xsl:variable name="isphysical" select="@name = $physical"/>
            <xsl:if test="$isphysical">
              <xsl:apply-templates mode="physical" select="."/>
            </xsl:if>
          </xsl:for-each>
        </xsl:if>
      </equipment>
    </chassis>

    <!-- Logical interface units. -->
    <unit-list>
      <xsl:apply-templates select="$interfaces" mode="logical"/>
    </unit-list>
  </host>
</xsl:template>

</xsl:stylesheet>
