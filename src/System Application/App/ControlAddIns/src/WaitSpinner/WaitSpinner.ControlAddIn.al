// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Apps;

controladdin WaitSpinner
{
    RequestedHeight = 350;
    RequestedWidth = 350;
    HorizontalStretch = true;
    VerticalStretch = true;
    Scripts = 'https://cdnjs.cloudflare.com/ajax/libs/knockout/3.4.2/knockout-debug.js',
              'src\WaitSpinner\js\WaitSpinner.js';
    StartupScript = 'src\WaitSpinner\js\WaitSpinner.js';
    StyleSheets = 'src\WaitSpinner\stylesheets\spinner.css';
    Images = 'src\WaitSpinner\images\spinner.gif';

    procedure Wait(SecondsToWait: Integer);
    event Ready();
    event Callback();
}