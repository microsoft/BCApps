#if not CLEAN24
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AA0247
controladdin "Microsoft.Dynamics.Nav.Client.PowerBIManagement"
{
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';
    ObsoleteReason = 'Replaced with PowerBIManagement addin.';
    RequestedHeight = 320;
    MinimumHeight = 180;
    RequestedWidth = 300;
    MinimumWidth = 200;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts = 'Resources\PowerBIManagement\js\PowerBIManagement.js',
              // The powerbi.js file comes from the nuget package: Microsoft.PowerBI.Javascript version: 2.22.2
              // https://github.com/microsoft/PowerBI-JavaScript/blob/master/dist/powerbi.js
              // The file below should point to the nuget package when the AL infrastructure supports it.
              'Resources\PowerBIManagement\js\powerbi.js';
    StartupScript = 'Resources\PowerBIManagement\js\Startup.js';
    StyleSheets = 'Resources\PowerBIManagement\stylesheets\PowerBIManagement.css';

    /// <summary>
    /// Event that will be fired when the AddIn is ready for communication through its API
    /// </summary>
    event ControlAddInReady();

    /// <summary>
    /// Event that will be fired when an error occurs in the add-in
    /// </summary>
    event ErrorOccurred(Operation: Text; ErrorText: Text);

    /// <summary>
    /// Event that will be fired when the page of the embedded report changes
    /// </summary>
    event ReportPageChanged(NewPage: Text; NewPageFilters: Text);

    /// <summary>
    /// Event that will be fired when the embedded report finishes loading
    /// </summary>
    event ReportLoaded(ReportFilters: Text; ActivePageName: Text; ActivePageFilters: Text; CorrelationId: Text);

    /// <summary>
    /// Event that will be fired when the embedded dashboard finishes loading
    /// </summary>
    event DashboardLoaded(CorrelationId: Text);

    /// <summary>
    /// Event that will be fired when the embedded dashboard tile finishes loading
    /// </summary>
    event DashboardTileLoaded(CorrelationId: Text);

    /// <summary>
    /// Event that will be fired when the embedded report visual finishes loading
    /// </summary>
    event ReportVisualLoaded(CorrelationId: Text);

    /// <summary>
    /// Initializes the Power BI Embed into the page
    /// </summary>
    [Obsolete('This method is deprecated. Please use EmbedReport instead.', '24.0')]
    procedure InitializeReport(ReportLink: Text; ReportId: Text; AuthToken: Text; PowerBIApi: Text);

    /// <summary>
    /// Initializes the Power BI embed Report into the page
    /// </summary>
    procedure EmbedReport(ReportLink: Text; ReportId: Text; AuthToken: Text; PageName: Text);

    /// <summary>
    /// Initializes the Power BI embed Report into the page, with additional options
    /// </summary>
    procedure EmbedReportWithOptions(ReportLink: Text; ReportId: Text; AuthToken: Text; PageName: Text; ShowPanes: Boolean);

    /// <summary>
    /// Initializes the Power BI embed Dashboard into the page
    /// </summary>
    procedure EmbedDashboard(DashboardLink: Text; DashboardId: Text; AuthToken: Text);

    /// <summary>
    /// Initializes the Power BI embed Dashboard Tile into the page
    /// </summary>
    procedure EmbedDashboardTile(DashboardTileLink: Text; DashboardId: Text; TileId: Text; AuthToken: Text);

    /// <summary>
    /// Initializes the Power BI embed Report Visual into the page
    /// </summary>
    procedure EmbedReportVisual(ReportVisualLink: Text; ReportId: Text; PageName: Text; VisualName: Text; AuthToken: Text);

    /// <summary>
    /// Changes the current mode into View
    /// </summary>
    procedure ViewMode();

    /// <summary>
    /// Changes the current mode into Edit
    /// </summary>
    procedure EditMode();

    /// <summary>
    /// Enters full screen mode for the current embed
    /// </summary>
    procedure FullScreen();

    /// <summary>
    /// Updates the report filters with the provided new filters
    /// </summary>
    /// <param name="filters">A serialized JSON array of filters</param>
    /// <remarks>
    /// The new filters will replace any existing report filter for the same table columns
    /// </remarks>
    procedure UpdateReportFilters(Filters: Text);

    /// <summary>
    /// Removes the current report level filters
    /// </summary>
    procedure RemoveReportFilters();

    /// <summary>
    /// Updates the page filters with the provided new filters
    /// </summary>
    /// <param name="filters">A serialized JSON array of filters</param>
    /// <remarks>
    /// The new filters will replace any existing page filter for the same table columns
    /// </remarks>
    procedure UpdatePageFilters(Filters: Text);

    /// <summary>
    /// Removes the current page level filters
    /// </summary>
    procedure RemovePageFilters();

    /// <summary>
    /// Changes the active page of the report
    /// </summary>
    /// <param name="pageName">The name of the new page to set as active</param>
    procedure SetPage(PageName: Text);

    /// <summary>
    /// Sets the properties for the browser frame containing the embed
    /// </summary>
    procedure InitializeFrame(FullPage: Boolean; Ratio: Text);
}
#pragma warning restore AA0247
#endif