#if not CLEAN25
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Automation;

controladdin FlowIntegration
{
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';
    ObsoleteReason = 'This add-in is deprecated. There is no replacement. Power Automate is supported natively without add-ins.';
    RequestedHeight = 600;
    MinimumHeight = 600;
    RequestedWidth = 320;
    MinimumWidth = 320;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts = 'Resources\FlowIntegration\js\msflowsdk-1.1.1.144.min.js',
              'Resources\FlowIntegration\js\FlowIntegration.js';
    StartupScript = 'Resources\FlowIntegration\js\Startup.js';
    RecreateScript = 'Resources\FlowIntegration\js\Recreate.js';
    RefreshScript = 'Resources\FlowIntegration\js\Refresh.js';

    /// <summary>
    /// Event raised when addin is done loading
    /// </summary>
    event ControlAddInReady();

    /// <summary>
    /// Event raised when error occurs
    /// </summary>
    /// <param name="Error">Error name</param>
    /// <param name="Description">Description of the error.</param>
    event ErrorOccurred(Error: Text; Description: Text);

    /// <summary>
    /// Event will be fired when the control add-in should be refreshed.
    /// </summary>
    event Refresh();

    /// <summary>
    /// Function that initializes the Flow API
    /// </summary>
    /// <param name="HostName">Flow service url needed by Flow API.</param>
    /// <param name="Locale">Four-letter language and region code.</param>
    /// <param name="FlowServiceToken">Microsoft Flow Service Access Token.</param>
    procedure Initialize(HostName: Text; Locale: Text; FlowServiceToken: Text);

    /// <summary>
    /// Function that loads the embedded Flow into a container on a webpage
    /// </summary>        
    /// <param name="EnvironmentId">Flow Environmnet ID</param>  
    procedure LoadFlows(EnvironmentId: Text);

    /// <summary>
    /// Function that loads embedded Flow templates into a container on a webpage
    /// </summary>
    /// <param name="EnvironmentId">Flow Environmnet ID</param>
    /// <param name="SearchTerm">Filters templates matching the search term</param>
    /// <param name="PageSize">Number of templates to be displayed in the container</param>
    /// <param name="Destination">Determines page that opens when one selects a template</param>
    procedure LoadTemplates(EnvironmentId: Text; SearchTerm: Text; PageSize: Text; Destination: Text);
}
#endif
