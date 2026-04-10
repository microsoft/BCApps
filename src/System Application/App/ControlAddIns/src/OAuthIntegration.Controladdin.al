// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.Authentication;

controladdin OAuthIntegration
{
    RequestedHeight = 30;
    RequestedWidth = 200;
    MinimumHeight = 20;
    MinimumWidth = 200;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts = 'Resources\OAuthIntegration\js\OAuthIntegration.js';
    StyleSheets = 'Resources\OAuthIntegration\stylesheets\OAuthIntegration.css';
    StartupScript = 'Resources\OAuthIntegration\js\Startup.js';

    /// <summary>
    /// Starts the authorization process.
    /// </summary>
    /// <param name="Url">The authentication request AuthRequestUrl.</param>
    procedure StartAuthorization(AuthRequestUrl: Text);

    /// <summary>
    /// Creates link to start the authorization process
    /// </summary>
    procedure Authorize(Url: Text; LinkName: Text; LinkToolTip: Text);

    /// <summary>
    /// Event triggered when an authorization code is retreieved.
    /// </summary>
    /// <param name="AuthCode">The authorization code retrieved as part of the authentication process.</param>
    event AuthorizationCodeRetrieved(AuthCode: Text);

    /// <summary>
    /// Event triggered when the authorization process has failed.
    /// </summary>
    /// <param name="AuthError">The authorization error message received.</param>
    /// <param name="AuthErrorDescription">A description of the authorization error received.</param>
    event AuthorizationErrorOccurred(AuthError: Text; AuthErrorDescription: Text);

    /// <summary>
    /// Event triggered when the Add-In is loaded and ready to use.
    /// </summary>
    event ControlAddInReady();
}
