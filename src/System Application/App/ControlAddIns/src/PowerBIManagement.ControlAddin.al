// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.PowerBI;

controladdin PowerBIManagement
{
    RequestedHeight = 320;
    MinimumHeight = 180;
    VerticalStretch = true;
    VerticalShrink = true;

    RequestedWidth = 300;
    MinimumWidth = 200;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts = 'Resources\PowerBIManagement\js\PowerBIManagement.js',
              // The powerbi.js file comes from the nuget package: Microsoft.PowerBI.Javascript version: 2.23.1
              // https://github.com/microsoft/PowerBI-JavaScript/blob/release_2.23.1/dist/powerbi.js
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
    /// Initializes the token to be used when embedding Power BI content
    /// </summary>
    procedure SetToken(AuthToken: Text);

    /// <summary>
    /// Initializes the Power BI embed Report into the page
    /// </summary>
    procedure EmbedPowerBIReport(ReportLink: Text; ReportId: Text; PageName: Text);

    /// <summary>
    /// Initializes the Power BI embed Dashboard into the page
    /// </summary>
    procedure EmbedPowerBIDashboard(DashboardLink: Text; DashboardId: Text);

    /// <summary>
    /// Initializes the Power BI embed Dashboard Tile into the page
    /// </summary>
    procedure EmbedPowerBIDashboardTile(DashboardTileLink: Text; DashboardId: Text; TileId: Text);

    /// <summary>
    /// Initializes the Power BI embed Report Visual into the page
    /// </summary>
    procedure EmbedPowerBIReportVisual(ReportVisualLink: Text; ReportId: Text; PageName: Text; VisualName: Text);

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
    /// Sets the properties for the embed experience
    /// </summary>
    ///<param name="ShowBookmarkSelection">Shows the bookmark selection pane.</param>
    ///<param name="ShowFilterSelection">Shows the filter pane to filter embed.</param>
    ///<param name="ShowPageSelection">Shows the pane to select the report page.</param>
    ///<param name="ShowZoomSelection">Shows the bar that allows manual zoom in and zoom out for the embed.</param>
    ///<param name="ForceTransparentBackground">Forces a transparent background to the embed.</param>
    ///<param name="ForceFitToPage">Forces the Fit To Page behaviour for the embed.</param>
    ///<param name="AddBottomPadding">Controls whether a padding is needed on the bottom of the page (useful in case the embed is the only element displayed on the page).</param>
    procedure SetSettings(ShowBookmarkSelection: Boolean; ShowFilters: Boolean; ShowPageSelection: Boolean; ShowZoomBar: Boolean; ForceTransparentBackground: Boolean; ForceFitToPage: Boolean; AddBottomPadding: Boolean);

#if not CLEAN25
    /// <summary>
    /// Sets the properties for the browser frame containing the embed
    /// </summary>
    [Obsolete('Use SetSettings, SetToken and then EmbedReport instead.', '25.0')]
    procedure InitializeFrame(FullPage: Boolean; Ratio: Text);

    /// <summary>
    /// Initializes the Power BI Embed into the page
    /// </summary>
    [Obsolete('Use SetSettings, SetToken and then EmbedReport instead.', '24.0')]
    procedure InitializeReport(ReportLink: Text; ReportId: Text; AuthToken: Text; PowerBIApi: Text);

    /// <summary>
    /// Initializes the Power BI embed Report into the page, with additional options
    /// </summary>
    [Obsolete('Use SetSettings, SetToken and then EmbedReport instead.', '25.0')]
    procedure EmbedReportWithOptions(ReportLink: Text; ReportId: Text; AuthToken: Text; PageName: Text; ShowPanes: Boolean);

    /// <summary>
    /// Changes the current mode into View
    /// </summary>
    [Obsolete('Switching between edit more and view mode is no longer supported. Only view mode will be supported going forward.', '25.0')]
    procedure ViewMode();

    /// <summary>
    /// Changes the current mode into Edit
    /// </summary>
    [Obsolete('Switching between edit more and view mode is no longer supported. Only view mode will be supported going forward.', '25.0')]
    procedure EditMode();

    /// <summary>
    /// Initializes the Power BI embed Report into the page
    /// </summary>
    [Obsolete('Call the procedure SetToken, and then use EmbedPowerBIReport instead.', '25.0')]
    procedure EmbedReport(ReportLink: Text; ReportId: Text; AuthToken: Text; PageName: Text);

    /// <summary>
    /// Initializes the Power BI embed Dashboard into the page
    /// </summary>
    [Obsolete('Call the procedure SetToken, and then use EmbedPowerBIDashboard instead.', '25.0')]
    procedure EmbedDashboard(DashboardLink: Text; DashboardId: Text; AuthToken: Text);

    /// <summary>
    /// Initializes the Power BI embed Dashboard Tile into the page
    /// </summary>
    [Obsolete('Call the procedure SetToken, and then use the EmbedPowerBIDashboardTile instead.', '25.0')]
    procedure EmbedDashboardTile(DashboardTileLink: Text; DashboardId: Text; TileId: Text; AuthToken: Text);

    /// <summary>
    /// Initializes the Power BI embed Report Visual into the page
    /// </summary>
    [Obsolete('Call the procedure SetToken, and then use EmbedPowerBIReportVisual instead.', '25.0')]
    procedure EmbedReportVisual(ReportVisualLink: Text; ReportId: Text; PageName: Text; VisualName: Text; AuthToken: Text);
#endif
}
