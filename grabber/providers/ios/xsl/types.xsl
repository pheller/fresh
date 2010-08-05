<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:str="http://exslt.org/strings"
 xmlns:func="http://exslt.org/functions"
 xmlns:cfggrab="localhost"
 extension-element-prefixes="str func">

<xsl:template match="interface" mode="logical">
  <unit>
    <xsl:variable name="name" select="@name"/>
    <xsl:variable
      name="runint"
      select="$shrun/interface[@name=$name]"/>

    <!-- Interface attributes. -->
    <xsl:attribute name="name">
      <xsl:value-of select="@name" />
    </xsl:attribute>

    <!-- Interface description. -->
    <xsl:if test="description">
      <description>
        <xsl:value-of select="description"/>
      </description>
    </xsl:if>

    <!-- IPv4 addresses. -->
    <xsl:variable
      name="addresses"
      select="$runint/ip-address | $runint/ipv4-address"/>
    <xsl:if test="$addresses/@address">
      <ipv4-address-list>
        <xsl:for-each select="$addresses">
          <xsl:if test="@address">
            <ipv4-address>
              <xsl:attribute name="address">
                <xsl:value-of select="@address" />
              </xsl:attribute>
              <xsl:attribute name="mask">
                <xsl:value-of select="@mask" />
              </xsl:attribute>
            </ipv4-address>
          </xsl:if>
        </xsl:for-each>
      </ipv4-address-list>
    </xsl:if>

    <!-- Service policy bindings. -->
    <xsl:for-each select="$runint/service-policy">
      <policy>
        <xsl:attribute name="direction">
          <xsl:value-of select="@direction" />
        </xsl:attribute>
        <xsl:value-of select="@name"/>
      </policy>
    </xsl:for-each>
  </unit>
</xsl:template>

<xsl:template match="interface" mode="physical">
  <interface>
    <xsl:variable name="name" select="cfggrab:getInterfaceName(@name)"/>

    <!-- Interface attributes. -->
    <xsl:attribute name="name">
      <xsl:value-of select="$name" />
    </xsl:attribute>

    <!-- Interface description. -->
    <xsl:if test="description">
      <description>
        <xsl:value-of select="description"/>
      </description>
    </xsl:if>

    <!-- Layer 2 protocol status. -->
    <l2-status>
      <xsl:choose>
        <xsl:when test="protocol = 'up' or starts-with(protocol, 'up ')">
          <xsl:text>active</xsl:text>
        </xsl:when>
        <xsl:when test="protocol = 'down' or starts-with(protocol, 'down ')">
          <xsl:text>inactive</xsl:text>
        </xsl:when>
        <xsl:when test="protocol = 'administratively down'">
          <xsl:text>inactive</xsl:text>
        </xsl:when>
        <!--
        Unfortunately, the parent controller of channelized interfaces
        does not show up in 'show interface', so in these cases we won't
        find any info on the status.
        TODO: Parse 'show controller' (or something else) to find the
        status.
        -->
        <xsl:when test="not(protocol) or protocol = 'not ready'">
          <xsl:text>unknown</xsl:text>
        </xsl:when>
      </xsl:choose>
    </l2-status>
  </interface>
</xsl:template>

</xsl:stylesheet>