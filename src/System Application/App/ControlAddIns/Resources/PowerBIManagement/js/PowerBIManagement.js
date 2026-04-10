/*! Copyright (C) Microsoft Corporation. All rights reserved. */
"use strict";

/*!-----------------------------------------------------------------------------------------------------------
|    This addin uses the PowerBI SDK to create an embedded experience of Power BI within Business Central.   |
|    Package: https://github.com/microsoft/PowerBI-JavaScript                                                |
|    Docs:    https://docs.microsoft.com/en-us/javascript/api/powerbi/powerbi-client/                        |
------------------------------------------------------------------------------------------------------------*/

var embed = null;
var activePage = null;
var legacySettingsObject = null;
var models = null;
var pbiAuthToken = null;
// Settings:
var _showBookmarkSelection = false;
var _showFilters = false;
var _showPageSelection = false;
var _showZoomBar = true;
var _forceTransparentBackground = false;
var _forceFitToPage = false;
var _addBottomPadding = false;
var _localeSettings = {};

function Initialize() {
    models = window['powerbi-client'].models;

    RaiseAddInReady();
}

// Addin Callbacks

function RaiseAddInReady() {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlAddInReady', null);
}

function RaiseErrorOccurred(operation, errorMessage) {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ErrorOccurred', [operation, errorMessage]);
}

function RaiseReportPageChanged(newpagename, newpagefilters) {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ReportPageChanged', [newpagename, newpagefilters]);
}

function RaiseReportLoaded(reportfilters, activepagename, activepagefilters, correlationId) {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ReportLoaded', [reportfilters, activepagename, activepagefilters, correlationId]);
}

function RaiseDashboardLoaded(correlationId) {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('DashboardLoaded', [correlationId]);
}

function RaiseDashboardTileLoaded(correlationId) {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('DashboardTileLoaded', [correlationId]);
}

function RaiseReportVisualLoaded(correlationId) {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ReportVisualLoaded', [correlationId]);
}

// Obsolete Functions

function InitializeReport(reportLink, reportId, authToken, powerBIEnv) {
    // OBSOLETE
    EmbedReport(reportLink, reportId, authToken, '');
}

function EmbedReportWithOptions(reportLink, reportId, authToken, pageName, showPanes) {
    // OBSOLETE
    EmbedReport(reportLink, reportId, authToken, pageName)
}

function EmbedReport(reportLink, reportId, authToken, pageName) {
    // OBSOLETE
    pbiAuthToken = authToken;
    EmbedPowerBIReport(reportLink, reportId, pageName);
}

function EmbedDashboard(dashboardLink, dashboardId, authToken) {
    // OBSOLETE
    pbiAuthToken = authToken;
    EmbedPowerBIDashboard(dashboardLink, dashboardId);
}

function EmbedDashboardTile(dashboardTileLink, dashboardId, tileId, authToken) {
    // OBSOLETE
    pbiAuthToken = authToken;
    EmbedPowerBIDashboardTile(dashboardTileLink, dashboardId, tileId);
}

function EmbedReportVisual(reportVisualLink, reportId, pageName, visualName, authToken) {
    // OBSOLETE
    pbiAuthToken = authToken;
    EmbedPowerBIReportVisual(reportVisualLink, reportId, pageName, visualName);
}

function ViewMode() {
    // OBSOLETE
    embed.switchMode('View').catch(function (error) {
        ProcessError('ViewMode', error);
    });
}

function EditMode() {
    // OBSOLETE
    embed.switchMode('Edit').catch(function (error) {
        ProcessError('EditMode', error);
    });
}

function InitializeFrame(fullpage, ratio) {
    // OBSOLETE
    legacySettingsObject = {
        panes: {
            bookmarks: {
                visible: false
            },
            fields: {
                visible: fullpage,
                expanded: false
            },
            filters: {
                visible: fullpage,
                expanded: fullpage
            },
            pageNavigation: {
                visible: fullpage
            },
            selection: {
                visible: fullpage
            },
            syncSlicers: {
                visible: fullpage
            },
            visualizations: {
                visible: fullpage,
                expanded: false
            }
        },

        background: models.BackgroundType.Transparent,

        layoutType: models.LayoutType.Custom,
        customLayout: {
            displayOption: models.DisplayOption.FitToPage
        }
    }
}

function SetSettings(showBookmarkSelection, showFilters, showPageSelection, showZoomBar, forceTransparentBackground, forceFitToPage, addBottomPadding) {
    // OBSOLETE
    _showBookmarkSelection = showBookmarkSelection;
    _showFilters = showFilters;
    _showPageSelection = showPageSelection;
    _showZoomBar = showZoomBar;
    _forceTransparentBackground = forceTransparentBackground;
    _addBottomPadding = addBottomPadding;
    _forceFitToPage = forceFitToPage;
}

// Exposed Functions

function EmbedPowerBIReport(reportLink, reportId, pageName) {
    ClearEmbedGlobals();
    ValidatePowerBIHost(reportLink);

    var embedConfiguration = InitializeEmbedConfig();
    embedConfiguration.type = 'report';
    embedConfiguration.id = SanitizeId(reportId);
    embedConfiguration.embedUrl = reportLink;
    if (pageName && (pageName != '')) {
        embedConfiguration.pageName = pageName;
    }
    DisplayEmbed(embedConfiguration);

    RegisterCommonEmbedEvents();

    embed.off("rendered");
    embed.on('rendered', function (event) {
        var reportPages = null;
        var reportFilters = null;
        var pageFilters = null;
        var embedCorrelationId = null;

        var promises =
            [
                embed.getCorrelationId().then(function (correlationId) {
                    embedCorrelationId = correlationId;
                }),

                embed.getPages().then(function (pages) {
                    var pagesArray = pages.reduce(ReduceByNameFunction, []);
                    reportPages = JSON.stringify(pagesArray);
                }),

                embed.getFilters().then(function (filters) {
                    reportFilters = JSON.stringify(filters);
                }),

                embed.getActivePage().then(function (page) {
                    activePage = page;
                    return page.getFilters().then(function (filters) {
                        pageFilters = JSON.stringify(filters);
                    });
                })
            ]

        Promise.all(promises).then(
            function (values) {
                embed.off("rendered");
                RaiseReportLoaded(reportFilters, reportPages, pageFilters, embedCorrelationId);
            },
            function (error) {
                ProcessError('LoadReportDetails', error);
            });
    });

    embed.off("pageChanged");
    embed.on('pageChanged', function (event) {
        activePage = event.detail.newPage;
        activePage.getFilters().then(function (filters) {
            RaiseReportPageChanged(activePage.name, JSON.stringify(filters));
        },
            function (error) {
                ProcessError('LoadPageFilters', error);
            });
    });
}

function EmbedPowerBIDashboard(dashboardLink, dashboardId) {
    ClearEmbedGlobals();
    ValidatePowerBIHost(dashboardLink);

    var embedConfiguration = InitializeEmbedConfig();
    embedConfiguration.type = 'dashboard';
    embedConfiguration.id = SanitizeId(dashboardId);
    embedConfiguration.embedUrl = dashboardLink;
    DisplayEmbed(embedConfiguration);

    RegisterCommonEmbedEvents();

    embed.off("loaded");
    embed.on('loaded', function (event) {
        embed.getCorrelationId().then(function (correlationId) {
            RaiseDashboardLoaded(correlationId);
        },
            function (error) {
                ProcessError('LoadDashboardCorrelationId', error);
            });
    });
}

function EmbedPowerBIDashboardTile(dashboardTileLink, dashboardId, tileId) {
    ClearEmbedGlobals();
    ValidatePowerBIHost(dashboardTileLink);

    var embedConfiguration = InitializeEmbedConfig();
    embedConfiguration.type = 'tile';
    embedConfiguration.id = SanitizeId(tileId);
    embedConfiguration.dashboardId = SanitizeId(dashboardId);
    embedConfiguration.embedUrl = dashboardTileLink;
    DisplayEmbed(embedConfiguration);

    RegisterCommonEmbedEvents();

    embed.off("loaded");
    embed.on('loaded', function (event) {
        embed.getCorrelationId().then(function (correlationId) {
            RaiseDashboardTileLoaded(correlationId);
        },
            function (error) {
                ProcessError('LoadDashboardTileCorrelationId', error);
            });
    });
}

function EmbedPowerBIReportVisual(reportVisualLink, reportId, pageName, visualName) {
    ClearEmbedGlobals();
    ValidatePowerBIHost(reportVisualLink);

    var embedConfiguration = InitializeEmbedConfig();
    embedConfiguration.type = 'visual';
    embedConfiguration.id = SanitizeId(reportId);
    embedConfiguration.pageName = SanitizeId(pageName);
    embedConfiguration.visualName = SanitizeId(visualName);
    embedConfiguration.embedUrl = reportVisualLink;
    DisplayEmbed(embedConfiguration);

    RegisterCommonEmbedEvents();

    embed.off("loaded");
    embed.on('loaded', function (event) {
        embed.getCorrelationId().then(function (correlationId) {
            RaiseReportVisualLoaded(correlationId);
        },
            function (error) {
                ProcessError('LoadReportVisualCorrelationId', error);
            });
    });
}

function FullScreen() {
    embed.fullscreen();
}

function UpdateReportFilters(filters) {
    var newFilters = null;
    try {
        newFilters = JSON.parse(filters);
    } catch (err) {
        ProcessError('ParseReportFilters', err);
    }

    embed.updateFilters(models.FiltersOperations.Replace, newFilters).catch(function (error) {
        ProcessError('UpdateReportFilters', error);
    });
}

function RemoveReportFilters() {
    embed.removeFilters().catch(function (error) {
        ProcessError('RemoveReportFilters', error);
    });
}

function UpdatePageFilters(filters) {
    var newFilters = null;
    try {
        newFilters = JSON.parse(filters);
    } catch (err) {
        ProcessError('ParsePageFilters', err);
    }

    activePage.updateFilters(models.FiltersOperations.Replace, newFilters).catch(function (error) {
        ProcessError('UpdatePageFilters', error);
    });
}

function RemovePageFilters() {
    activePage.removeFilters().catch(function (error) {
        ProcessError('RemovePageFilters', error);
    });
}

function SetPage(pageName) {
    report.setPage(pageName).catch(function (error) {
        ProcessError('SetPage', error);
    });
}

function SetLocale(newLocale) {
    _localeSettings = {
        language: newLocale
    }
}

function SetToken(authToken) {
    pbiAuthToken = authToken;
}

function SetBookmarksVisible(visible) {
    _showBookmarkSelection = visible;
}

function SetFiltersVisible(visible) {
    _showFilters = visible;
}

function SetPageSelectionVisible(visible) {
    _showPageSelection = visible;
}

function SetTransparentBackground(transparent) {
    _forceTransparentBackground = transparent;
}

function AddBottomPadding(addPadding) {
    _addBottomPadding = addPadding;
}

// Internal functions

function CompileSettings() {
    if (legacySettingsObject) {
        // Already initialized. This case is only used for backwards compatibility.
        return legacySettingsObject;
    }

    if (_addBottomPadding) {
        var iframe = window.frameElement;
        iframe.style.paddingBottom = '42px';
    }
    else {
        var iframe = window.frameElement;
        iframe.style.removeProperty('paddingBottom');
    }

    var settingsObject = {
        panes: {
            bookmarks: {
                visible: _showBookmarkSelection
            },
            filters: {
                visible: _showFilters,
                expanded: false
            },
            pageNavigation: {
                visible: _showPageSelection
            },
            fields: { // In edit mode, allows selecting fields to add to the report
                visible: false
            },
            selection: { // In edit mode, allows selecting visuals from a list instead of clicking in the UI
                visible: false
            },
            syncSlicers: { // In edit mode, allows syncing slicers through pages
                visible: false
            },
            visualizations: { // In edit mode, allows adding new visualizations
                visible: false
            }
        },

        bars: {
            statusBar: {
                visible: _showZoomBar
            }
        },

        localeSettings: _localeSettings
    }

    if (_forceTransparentBackground) {
        settingsObject.background = models.BackgroundType.Transparent;
    }

    if (_forceFitToPage) {
        settingsObject.layoutType = models.LayoutType.Custom;
        settingsObject.customLayout = {
            displayOption: models.DisplayOption.FitToPage
        }
    }

    return settingsObject;
}

function ExtractBootstrapConfiguration(embedConfiguration) {
    return {
        type: embedConfiguration.type,
        hostname: GetHost(embedConfiguration.embedUrl),
        settings: {
            localeSettings: embedConfiguration.settings.localeSettings
        }
    };
}

function ClearEmbedGlobals() {
    embed = null;
    activePage = null;
}

function InitializeEmbedConfig() {
    if (!pbiAuthToken || (pbiAuthToken == '')) {
        RaiseErrorOccurred('Initialize Config', 'No token was provided');
    }

    var embedConfiguration = {
        tokenType: models.TokenType.Aad,
        accessToken: pbiAuthToken,

        viewMode: models.ViewMode.View,
        permissions: models.Permissions.All,
        settings: CompileSettings()
    };

    return embedConfiguration;
}

function DisplayEmbed(embedConfiguration) {
    var reportContainer = document.getElementById('controlAddIn');

    powerbi.reset(reportContainer);


    // NOTE: Bootstrap is here to work around an issue with how the powerbi.js library handles ScoreCards.
    // ScoreCards are classified as Reports, but have different URL structure. If we call powerbi.embed directly on a ScoreCard, the library
    // tries to load non-existing ScoreCard resources. Bootstrapping without the final URL forces the library to load the correct Report resources.
    var bootstrapConfiguration = ExtractBootstrapConfiguration(embedConfiguration);
    powerbi.bootstrap(reportContainer, bootstrapConfiguration);

    embed = powerbi.embed(reportContainer, embedConfiguration);
}

function RegisterCommonEmbedEvents() {
    embed.off("error");
    embed.on("error", function (event) {
        ProcessError('OnError', event);
    });
}

function ReduceByNameFunction(accumulator, current) {
    accumulator.push(current.name);
    return accumulator;
}

function SanitizeId(id) {
    // From: {79a5e047-a665-4c83-900b-f5ccf19e01c7}
    // To:    79a5e047-a665-4c83-900b-f5ccf19e01c7
    return id.replace(/[{}]/g, "");
}

function GetHost(url) {
    var urlObject = new URL(url);
    return urlObject.protocol.concat('//').concat(urlObject.host)
}

function ProcessError(operation, error) {
    LogErrorToConsole(operation, error);

    var errorMessage = GetErrorMessage(error);
    RaiseErrorOccurred(operation, errorMessage);
}

function LogErrorToConsole(operation, error) {
    console.error('Error occurred (' + operation + '). See the detailed error in the following message.');
    console.error(error);
}

function GetErrorMessage(error) {
    if (error && error.detail && error.detail.detailedMessage) {
        return error.detail.detailedMessage;
    }

    if (error && error.detail && error.detail.message) {
        return error.detail.message;
    }

    if (error && error.message) {
        return error.message;
    }

    return error.toString();
}

function ValidatePowerBIHost(embedUrl) {
    var urlHost = GetHost(embedUrl);
    if (!urlHost.endsWith(".powerbi.com") && !urlHost.endsWith('.analysis-df.windows.net')) {
        var errorMsg = 'The host "' + urlHost + '" is not a valid Power BI host.';
        ProcessError('InvalidHost', errorMsg);
        throw new Error(errorMsg);
    }
}
