#if not CLEAN24
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AA0247
controladdin "Microsoft.Dynamics.Nav.Client.PageReady"
{
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';
    ObsoleteReason = 'Replaced with PageReady addin.';
    Scripts = 'Resources\PageReady\js\PageReady.js';
    StyleSheets = 'Resources\PageReady\stylesheets\PageReady.css';
    RequestedWidth = 0;
    RequestedHeight = 0;
    HorizontalStretch = false;
    VerticalStretch = false;

    event AddInReady();
}
#pragma warning restore AA0247
#endif