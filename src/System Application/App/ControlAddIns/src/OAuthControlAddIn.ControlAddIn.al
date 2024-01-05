#if not CLEAN24
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.Authentication;

controladdin OAuthControlAddIn
{
    Scripts = 'Resources\OAuthIntegration\js\OAuthIntegration.js';
    StartupScript = 'Resources\OAuthIntegration\js\Startup.js';
    RequestedWidth = 0;
    RequestedHeight = 0;
    HorizontalStretch = false;
    VerticalStretch = false;
    ObsoleteState = Pending;
    ObsoleteReason = 'This control add-in is replaced by OAuthIntegration.';
    ObsoleteTag = '24.0';


    /// <summary>
    /// Starts the authorization process.
    /// </summary>
    /// <param name="Url">The authentication request AuthRequestUrl.</param>
    procedure StartAuthorization(AuthRequestUrl: Text);

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
#endif