<!-----------------------------------------------------------------------
********************************************************************************
Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldbox.org | www.luismajano.com | www.ortussolutions.com
********************************************************************************

Author 	 :	Luis Majano
Date     :	September 23, 2005
Description :
	This is ColdBox's Renderer plugin.
----------------------------------------------------------------------->
<cfcomponent hint="This service renders layouts, views, framework includes, etc."
			 extends="coldbox.system.Plugin"
			 output="false"
			 cache="false">

<!------------------------------------------- CONSTRUCTOR ------------------------------------------->

	<cffunction name="init" access="public" returntype="Renderer" output="false" hint="Constructor">
		<!--- ************************************************************* --->
		<cfargument name="controller" type="any" required="true">
		<!--- ************************************************************* --->
		<cfscript>
			super.init(arguments.controller);
				
			// Set Conventions
			instance.layoutsConvention = controller.getSetting("layoutsConvention",true);
			instance.viewsConvention = controller.getSetting("viewsConvention",true);
			instance.appMapping = controller.getSetting("AppMapping");
			instance.viewsExternalLocation = controller.getSetting('ViewsExternalLocation');
			instance.layoutsExternalLocation = controller.getSetting('LayoutsExternalLocation');
			
			// Set event scope, we are not caching, so it is threadsafe.
			event = getRequestContext();
			// Create View Scopes
			rc = event.getCollection();
			prc = event.getCollection(private=true);
		
			// Inject UDF For Views/Layouts
			if(Len(Trim(controller.getSetting("UDFLibraryFile")))){
				includeUDF(controller.getSetting("UDFLibraryFile"));
			}
			
			return this;
		</cfscript>
	</cffunction>

<!------------------------------------------- PUBLIC ------------------------------------------->

	<!--- Render the View --->
	<cffunction name="renderView"	access="Public" hint="Renders the current view." output="false" returntype="Any">
		<!--- ************************************************************* --->
		<cfargument name="view" 					required="false" type="string"  default=""		hint="If not passed in, the value in the currentView in the current RequestContext will be used.">
		<cfargument name="cache" 					required="false" type="boolean" default="false" hint="True if you want to cache the view.">
		<cfargument name="cacheTimeout" 			required="false" type="string"  default=""		hint="The cache timeout">
		<cfargument name="cacheLastAccessTimeout" 	required="false" type="string"  default="" 		hint="The last access timeout">
		<cfargument name="cacheSuffix" 				required="false" type="string"  default=""      hint="Add a cache suffix to the view cache entry. Great for multi-domain caching or i18n caching."/>
		<!--- ************************************************************* --->
		<cfset var cbox_RenderedView = "">
		<cfset var cbox_viewpath = "">
		<cfset var cbox_viewHelperPath = "">
		<!--- Cache Entries --->
		<cfset var cbox_cacheKey = "">
		<cfset var cbox_cacheEntry = "">
		<cfset var timerHash = 0>
		<cfset var interceptData = arguments>
		
		<!--- Test Default View --->
		<cfif NOT len(arguments.view)>
			<cfset arguments.view = event.getCurrentView()>
		</cfif>
		
		<!--- Test if we have a view to render --->
		<cfif len(trim(arguments.view)) eq 0>
			<cfthrow type="Renderer.ViewNotSetException" 
				     message="The ""currentview"" variable has not been set, therefore there is no view to render." 
					 detail="Please remember to use the 'setView()' method in your handler or pass in a view to render.">
		</cfif>
		
		<!--- preViewRender interception point --->
		<cfset announceInterception("preViewRender",interceptData)>
		
		<!--- Setup the cache key --->
		<cfset cbox_cacheKey = getColdboxOCM().VIEW_CACHEKEY_PREFIX & arguments.view & arguments.cacheSuffix>
		
		<!--- Do we have a cached view?? --->
		<cfif getColdboxOCM().lookup(cbox_cacheKey)>
			<!--- Render The View --->
			<cfset timerHash = controller.getDebuggerService().timerStart("rendering Cached View [#arguments.view#.cfm]")>
			<cfset cbox_RenderedView = controller.getColdBoxOCM().get(cbox_cacheKey)>
			<cfset controller.getDebuggerService().timerEnd(timerHash)>
			
			<!--- postViewRender --->
			<cfset interceptData.renderedView = cbox_RenderedView>
			<cfset announceInterception("postViewRender",interceptData)>
			
			<cfreturn interceptData.renderedView>
		</cfif>
		
		<!--- Locate the view to render --->
		<cfset cbox_viewPath = locateView(arguments.view)>
		<!--- Check for helper convention? --->
		<cfif fileExists(expandPath(cbox_viewPath & "Helper.cfm"))>
			<cfset cbox_viewHelperPath = cbox_viewPath & "Helper.cfm">
		</cfif>
		
		<!--- Render The View & Its Helper --->
		<cfset timerHash = controller.getDebuggerService().timerStart("rendering View [#arguments.view#.cfm]")>
		<cfsavecontent variable="cbox_RenderedView"><cfif len(cbox_viewHelperPath)><cfoutput><cfinclude template="#cbox_viewHelperPath#"></cfoutput></cfif><cfoutput><cfinclude template="#cbox_viewpath#.cfm"></cfoutput></cfsavecontent>
		<cfset controller.getDebuggerService().timerEnd(timerHash)>
		
		<!--- postViewRender --->
		<cfset interceptData.renderedView = cbox_RenderedView>
		<cfset announceInterception("postViewRender",interceptData)>
		
		<!--- Is this view cacheable by setting, and if its the view we need to cache. --->
		<cfif event.isViewCacheable() and (arguments.view eq event.getViewCacheableEntry().view)>
			<!--- Cache it baby!! --->
			<cfset cbox_cacheEntry = event.getViewCacheableEntry()>
			<cfset getColdboxOCM().set(getColdboxOCM().VIEW_CACHEKEY_PREFIX & cbox_cacheEntry.view & cbox_cacheEntry.cacheSuffix,
									   interceptData.renderedView,
									   cbox_cacheEntry.timeout,
									   cbox_cacheEntry.lastAccessTimeout)>
		<!--- Are we caching explicitly --->
		<cfelseif arguments.cache>
			<cfset getColdboxOCM().set(cbox_cacheKey,
									   interceptData.renderedView,
									   arguments.cacheTimeout,
									   arguments.cacheLastAccessTimeout)>
		</cfif>
		
		<!--- Return cached, or rendered view --->
		<cfreturn interceptData.renderedView>
	</cffunction>

	<!--- Render an external View --->
	<cffunction name="renderExternalView"	access="Public" hint="Renders an external view." output="false" returntype="Any">
		<!--- ************************************************************* --->
		<cfargument name="view" 					required="true"  type="string" hint="The full path to the view. This can be an expanded path or relative. Include extension.">
		<cfargument name="cache" 					required="false" type="boolean" default="false" hint="True if you want to cache the view.">
		<cfargument name="cacheTimeout" 			required="false" type="string"  default=""		hint="The cache timeout">
		<cfargument name="cacheLastAccessTimeout" 	required="false" type="string"  default="" 		hint="The last access timeout">
		<cfargument name="cacheSuffix" 				required="false" type="string"  default=""      hint="Add a cache suffix to the view cache entry. Great for multi-domain caching or i18n caching."/>
		<!--- ************************************************************* --->
		<cfset var cbox_RenderedView = "">
		<!--- Cache Entries --->
		<cfset var cbox_cacheKey = "">
		<cfset var cbox_cacheEntry = "">
		
		<!--- Setup the cache key --->
		<cfset cbox_cacheKey = getColdboxOCM().VIEW_CACHEKEY_PREFIX & "external-" & arguments.view & arguments.cacheSuffix>
		
		<!--- Do we have a cached view?? --->
		<cfif getColdboxOCM().lookup(cbox_cacheKey)>
			<!--- Render The View --->
			<cfset timerHash = controller.getDebuggerService().timerStart("rendering Cached External View [#arguments.view#.cfm]")>
				<cfset cbox_RenderedView = getColdBoxOCM().get(cbox_cacheKey)>
			<cfset controller.getDebuggerService().timerEnd(timerHash)>
			<cfreturn cbox_RenderedView>
		</cfif>	
		
		<cfset timerHash = controller.getDebuggerService().timerStart("rendering External View [#arguments.view#.cfm]")>
			<cftry>
				<!--- Render the View --->
				<cfsavecontent variable="cbox_RenderedView"><cfoutput><cfinclude template="#arguments.view#.cfm"></cfoutput></cfsavecontent>
				<!--- Catches --->
				<cfcatch type="missinginclude">
					<cfthrow type="Renderer.RenderExternalViewNotFoundException" message="The external view: #arguments.view# cannot be found. Please check your paths." >
				</cfcatch>
				<cfcatch type="any">
					<cfrethrow />
				</cfcatch>
			</cftry>
		<cfset controller.getDebuggerService().timerEnd(timerHash)>
		
		<!--- Are we caching explicitly --->
		<cfif arguments.cache>
			<cfset getColdboxOCM().set(cbox_cacheKey,cbox_RenderedView,arguments.cacheTimeout,arguments.cacheLastAccessTimeout)>
		</cfif>

		<cfreturn cbox_RenderedView>
	</cffunction>

	<!--- Render the layout --->
	<cffunction name="renderLayout" access="Public" hint="Renders the current layout + view Combinations if declared." output="false" returntype="any">
		<cfargument name="layout" type="any" required="false" hint="The explicit layout to use in rendering."/>
		<cfargument name="view"   type="any" required="false" default="" hint="The name of the view to passthrough as an argument so you can refer to it as arguments.view"/>
		<!--- Get Current Set Layout From Request Collection --->
		<cfset var cbox_currentLayout = implicitViewChecks()>
		<!--- Content Variables --->
		<cfset var cbox_RederedLayout = "">
		<cfset var cbox_timerhash = "">
		
		<!--- Check explicit layout rendering --->
		<cfif structKeyExists(arguments,"layout")>
			<cfset cbox_currentLayout = arguments.layout & ".cfm">
		</cfif>
		
		<!--- Start Timer --->
		<cfset cbox_timerhash = controller.getDebuggerService().timerStart("rendering Layout [#cbox_currentLayout#]")>
			
		<!--- If Layout is blank, then just delegate to the view --->
		<cfif len(cbox_currentLayout) eq 0>
			<cfset cbox_RederedLayout = renderView()>
		<cfelse>			
			<!--- RenderLayout --->
			<cfsavecontent variable="cbox_RederedLayout"><cfoutput><cfinclude template="#locateLayout(cbox_currentLayout)#"></cfoutput></cfsavecontent>
		</cfif>
		
		<!--- Stop Timer --->
		<cfset controller.getDebuggerService().timerEnd(cbox_timerhash)>
		
		<!--- Return Rendered Layout --->
		<cfreturn cbox_RederedLayout>
	</cffunction>
	
<!------------------------------------------- PRIVATE ------------------------------------------->

	<!--- implicitViewChecks --->
	<cffunction name="implicitViewChecks" output="false" access="private" returntype="any" hint="Does implicit view rendering checks">
		<cfset var cbox_currentLayout = event.getcurrentLayout()>
		
		<!--- Check if no view has been set in the Request Collection --->
		<cfif NOT len(event.getCurrentView())>
			<!--- Implicit Views according to event --->
			<cfset event.setView(lcase(replace(event.getCurrentEvent(),".","/","all")))>
			<!--- Check if default view set, if yes, then set it. --->
			<cfif len(event.getDefaultView())>
				<!--- Set the Default View --->
				<cfset event.setView(event.getDefaultView())>
			</cfif>
			<!--- Reset the layout again, as we set views for rendering implicitly --->
			<cfset cbox_CurrentLayout = event.getcurrentLayout()>
		</cfif>
		
		<cfreturn cbox_currentLayout>
	</cffunction>

	<!--- locateLayout --->
	<cffunction name="locateLayout" output="false" access="private" returntype="any" hint="Locate the layout to render">
		<cfargument name="layout" type="any" required="true" hint="The layout name"/>
		<cfset var cbox_layoutPath = "/#instance.appMapping#/#instance.layoutsConvention#/#arguments.layout#">
		
		<!--- Check if layout does not exists in Conventions --->
		<cfif not fileExists(expandPath(cbox_layoutPath))>
			<!--- Set the Path to be the External Location --->
			<cfset cbox_layoutPath = "#instance.layoutsExternalLocation#/#arguments.layout#">
			
			<!--- Verify the External Location now --->
			<cfif not fileExists(expandPath(cbox_layoutPath))>
				<cfthrow message="Layout not located" 
						 detail="The layout: #arguments.layout# could not be located in the conventions folder or in the external location. Please verify the layout name" 
						 type="Renderer.LayoutNotFoundException">
			</cfif>
		</cfif>
		
		<cfreturn cbox_layoutPath>
	</cffunction>
	
	<!--- locateView --->
	<cffunction name="locateView" output="false" access="private" returntype="any" hint="Locate the view to render">
		<cfargument name="view" type="any" required="true" hint="The view name"/>
		<cfset var cbox_viewPath = "/#instance.appMapping#/#instance.viewsConvention#/#arguments.view#">
		
		<!--- Check if layout does not exists in Conventions --->
		<cfif not fileExists(expandPath(cbox_viewPath & ".cfm"))>
			<!--- Set the Path to be the External Location --->
			<cfset cbox_viewPath = "#instance.viewsExternalLocation#/#arguments.view#">
			
			<!--- Verify the External Location now --->
			<cfif not fileExists(expandPath(cbox_viewPath & ".cfm"))>
				<cfthrow message="View not located" 
						 detail="The view: #arguments.view#.cfm could not be located in the conventions folder or in the external location. Please verify the view name and location" 
						 type="Renderer.ViewNotFoundException">
			</cfif>
		</cfif>
		
		<cfreturn cbox_viewPath>
	</cffunction>

	<!--- Get Layouts Convention --->
	<cffunction name="getLayoutsConvention" access="private" output="false" returntype="string" hint="Get layoutsConvention">
		<cfreturn instance.layoutsConvention/>
	</cffunction>
	
	<!--- Get Views Convention --->
	<cffunction name="getViewsConvention" access="private" output="false" returntype="string" hint="Get viewsConvention">
		<cfreturn instance.viewsConvention/>
	</cffunction>
	
	<!--- Get App Mapping --->	
	<cffunction name="getAppMapping" access="private" output="false" returntype="string" hint="Get appMapping">
		<cfreturn instance.appMapping/>
	</cffunction>	
	
</cfcomponent>