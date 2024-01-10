/*! Copyright (C) Microsoft Corporation. All rights reserved. */
"use strict";

/*!-----------------------------------------------------------------------------------------------------------
|    This addin uses the PowerBI SDK to create an embedded experience of Power BI within Business Central.   |
|    Package: https://github.com/microsoft/PowerBI-JavaScript                                                |
|    Docs:    https://docs.microsoft.com/en-us/javascript/api/powerbi/powerbi-client/                        |
------------------------------------------------------------------------------------------------------------*/

var embed = null;
var activePage = null;
var fullPageMode = false;

var models = null;
var embedWidth = null;
var embedHeight = null;
var manifestWidth = null;
var manifestHeight = null;

function Initialize() {
    models = window['powerbi-client'].models;

    var controlAddInElement = document.getElementById('controlAddIn');
    manifestWidth = controlAddInElement.offsetWidth;
    manifestHeight = controlAddInElement.offsetHeight;
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

// Exposed Functions

function InitializeReport(reportLink, reportId, authToken, powerBIEnv) {
    // OBSOLETE
    EmbedReport(reportLink, reportId, authToken, '');
}

function EmbedReport(reportLink, reportId, authToken, pageName) {
     // OBSOLETE
     EmbedReportWithOptions(reportLink, reportId, authToken, pageName, false)
}

function EmbedReportWithOptions(reportLink, reportId, authToken, pageName, showPanes) {
    ClearEmbedGlobals();

    var embedConfiguration = InitializeEmbedConfig(authToken, showPanes);
    embedConfiguration.type = 'report';
    embedConfiguration.id = SanitizeId(reportId);
    embedConfiguration.embedUrl = reportLink;
    if (pageName && (pageName != '')){
        embedConfiguration.pageName = pageName;
    }
    DisplayEmbed(embedConfiguration);

    RegisterCommonEmbedEvents();

    embed.off("loaded");
    embed.on('loaded', function (event) {
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

function EmbedDashboard(dashboardLink, dashboardId, authToken) {
    ClearEmbedGlobals();
    
    var embedConfiguration = InitializeEmbedConfig(authToken, false);
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

function EmbedDashboardTile(dashboardTileLink, dashboardId, tileId, authToken) {
    ClearEmbedGlobals();
    
    var embedConfiguration = InitializeEmbedConfig(authToken, false);
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

function EmbedReportVisual(reportVisualLink, reportId, pageName, visualName, authToken) {
    ClearEmbedGlobals();

    var embedConfiguration = InitializeEmbedConfig(authToken, false);
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

function ViewMode() {
    embed.switchMode('View').catch(function (error) {
        ProcessError('ViewMode', error);
    });
}

function EditMode() {
    embed.switchMode('Edit').catch(function (error) {
        ProcessError('EditMode', error);
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

function InitializeFrame(fullpage, ratio){
    fullPageMode = fullpage;
    if (!ratio) ratio = '16:9'; // Default according to Power BI documentation

    var iframe = window.frameElement;

    var maximumAllowedHeight = manifestHeight;
    var maximumAllowedWidth = manifestWidth;
    if (fullPageMode) {
        // When opening a report fullscreen, maximize the real estate instead
        iframe.style.removeProperty('max-height');
        iframe.style.removeProperty('max-width');
        maximumAllowedHeight = 720;
        maximumAllowedWidth = 1280;
    }

    var arr = ratio.split(":");
    var ratioWidth = arr[0];
    var ratioHeight = arr[1];

    var computedWidth = (maximumAllowedHeight / ratioHeight) * ratioWidth;
    var computedHeight = (maximumAllowedWidth / ratioWidth) * ratioHeight;

    if (computedWidth <= maximumAllowedWidth) {
        // Fit to width
        embedWidth = computedWidth;
        embedHeight = maximumAllowedHeight;
    }
    else {
        // Fit to height instead
        embedWidth = maximumAllowedWidth;
        embedHeight = computedHeight;
    }

    iframe.style.height = Math.floor(embedHeight).toString() + 'px';
    iframe.style.width = Math.floor(embedWidth).toString() + 'px';
}

// Internal functions

function ClearEmbedGlobals() {
    embed = null;
    activePage = null;
}

function InitializeEmbedConfig(authToken, showPanes) {
    var embedConfiguration = {
        tokenType: models.TokenType.Aad,
        accessToken: authToken,

        viewMode: models.ViewMode.View,
        permissions: models.Permissions.All,
        settings: {
            panes: {
                bookmarks: {
                    visible: false
                },
                fields: {
                    visible: fullPageMode && showPanes,
                    expanded: false
                },
                filters: {
                    visible: fullPageMode && showPanes,
                    expanded: fullPageMode && showPanes
                },
                pageNavigation: {
                    visible: showPanes
                },
                selection: {
                    visible: fullPageMode && showPanes
                },
                syncSlicers: {
                    visible: fullPageMode && showPanes
                },
                visualizations: {
                    visible: fullPageMode && showPanes,
                    expanded: false
                }
            },

            background: models.BackgroundType.Transparent,

            layoutType: models.LayoutType.Custom,
            customLayout: {
                displayOption: models.DisplayOption.FitToPage
            }
        }
    };

    return embedConfiguration;
}

function DisplayEmbed(embedConfiguration) {
    var reportContainer = document.getElementById('controlAddIn');

    powerbi.reset(reportContainer);

    // NOTE: Bootstrap is here to work around an issue with how the powerbi.js library handles ScoreCards.
    // ScoreCards are classified as Reports, but have different URL structure. If we call powerbi.embed directly on a ScoreCard, the library
    // tries to load non-existing ScoreCard resources. Bootstrapping without the final URL forces the library to load the correct Report resources.
    powerbi.bootstrap(reportContainer, { type: embedConfiguration.type, hostname: GetHost(embedConfiguration.embedUrl) });

    embed = powerbi.embed(reportContainer, embedConfiguration);
}

function RegisterCommonEmbedEvents(){
    embed.off("error");
    embed.on("error", function (event) {
        ProcessError('OnError', event);
    });
}

function ReduceByNameFunction(accumulator, current) {
    accumulator.push(current.name);
    return accumulator;
}

function SanitizeId(id){
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

function GetErrorMessage(error){
    if (error && error.message){
        return error.message;
    }

    if (error && error.detail && error.detail.message){
        return error.detail.message;
    }

    return '';
}