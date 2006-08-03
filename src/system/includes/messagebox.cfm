<cfsetting enablecfoutputonly=true><!-----------------------------------------------------------------------Template :  messagebox.cfm Author 	 :	Luis MajanoDate     :	October 10, 2005Description : 				This is the display of the frameworks messagebox. 	You can customize this as you want.				Modification History:		01/16/2006	- Added support for child apps.06/09/2006 - Updated for coldbox. Style declaration modified.-----------------------------------------------------------------------><!--- ************************************************************* ---><!--- Child App Distance ---><cfset distanceString = getSetting("DistanceString",1)><!--- Get image to display ---><cfif CompareNocase(msgStruct.type, "error") eq 0>	<cfset img = "#distanceString#system/includes/images/emsg.gif"><cfelseif CompareNocase(msgStruct.type, "warning") eq 0>	<cfset img = "#distanceString#system/includes/images/wmsg.gif"><cfelse>	<cfset img = "#distanceString#system/includes/images/cmsg.gif"></cfif><!--- Set the css class ---><cfif getSetting("MessageboxStyleClass") eq "">	<cfset msgClass = "fw_messageboxTable"><cfelse>	<cfset msgClass = getSetting("MessageboxStyleClass")></cfif><cfoutput><!--- Style Declaration ---><style>.fw_messageboxTable{	border:1px dotted ##999999;	background: ##FFFFE0;	width: 100%;	padding: 3px 3px 3px 3px;	font-family: Arial, Helvetica, sans-serif;	font-size: 11px;	font-weight: bold;}</style><!--- Message Box ---><cfif len(msgStruct.message) gt 130>	<cfset style = "overflow: auto; height:40px;"><cfelse>	<cfset style = "overflow: auto;"></cfif><table align="center" cellpadding="0" cellspacing="5" class="#msgClass#">  <tr>    <td width="30" align="center" valign="top"><img src="#img#"></td>    <td>#msgStruct.message#</td>  </tr></table></cfoutput><cfsetting enablecfoutputonly="false">