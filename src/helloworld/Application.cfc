<cfcomponent><cfset this.name = "Textus Hello World"> <cfset this.clientManagement = true> <cfset this.sessionManagement = true> <cfset this.sessionTimeout = createTimeSpan(0,0,30,0)> <cfset this.setClientCookies = true><cfset this.loginStorage = "session">		<cffunction name="onApplicationStart" returnType="boolean" output="false"> 	<cfreturn true> </cffunction> <cffunction name="onApplicationEnd" returnType="void"  output="false"> 	<cfargument name="applicationScope" required="true"></cffunction><cffunction name="onRequestStart" returnType="boolean" output="false">	<cfargument name="thePage" type="string" required="true">	<cfreturn  true></cffunction><cffunction name="onRequest" returnType="void">	<cfargument name="thePage" type="string" required="true">	<cfinclude template="#arguments.thePage#">		</cffunction><cffunction name="onRequestEnd" returnType="void" output="false">	<cfargument name="thePage" type="string" required="true"></cffunction>	<cffunction name="onSessionStart" returnType="void" output="false"> </cffunction> <cffunction name="onSessionEnd" returnType="void" output="false"> 	<cfargument name="sessionScope" type="struct" required="true"> 	<cfargument name="appScope" type="struct" required="false"> </cffunction>  </cfcomponent>