// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration;

controladdin BusinessChart
{
    RequestedHeight = 320;
    MinimumHeight = 180;
    RequestedWidth = 300;
    MinimumWidth = 200;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts = 'Resources\BusinessChart\js\BusinessChartAddIn.js',
              'https://ajax.aspnetcdn.com/ajax/jQuery/jquery-3.5.1.min.js',
              'https://code.highcharts.com/9.1.1/highcharts.js',
              'https://code.highcharts.com/9.1.1/highcharts-more.js',
              'https://code.highcharts.com/9.1.1/modules/accessibility.js',
              'https://code.highcharts.com/9.1.1/modules/funnel.js';
    StartupScript = 'Resources\BusinessChart\js\Startup.js';
    RecreateScript = 'Resources\BusinessChart\js\Recreate.js';
    RefreshScript = 'Resources\BusinessChart\js\Refresh.js';
    StyleSheets = 'Resources\BusinessChart\stylesheets\BusinessChartAddIn.css';

    /// <summary>
    /// Event raised when a data point has been clicked.
    /// </summary>
    event DataPointClicked(Point: JsonObject);

    /// <summary>
    /// Event raised when a data point has been double clicked.
    /// </summary>
    event DataPointDoubleClicked(Point: JsonObject);

    /// <summary>
    /// Event will be fired when the control add-in is ready for communication.
    /// </summary>
    event AddInReady();

    /// <summary>
    /// Event will be fired when the control add-in should be refreshed.
    /// </summary>
    event Refresh();

    /// <summary>
    /// Initialize and updates the chart. This method must be called before any controls will work.
    /// </summary>
    /// <param name="ChartData">The full set of data needed for initializing the chart.</param>
    procedure Update(ChartData: JsonObject);
}