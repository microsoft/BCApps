// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Utilities;

controladdin PageReady
{
    Scripts = 'Resources\PageReady\js\PageReady.js';
    StyleSheets = 'Resources\PageReady\stylesheets\PageReady.css';
    RequestedWidth = 0;
    RequestedHeight = 0;
    HorizontalStretch = false;
    VerticalStretch = false;

    event AddInReady();
}