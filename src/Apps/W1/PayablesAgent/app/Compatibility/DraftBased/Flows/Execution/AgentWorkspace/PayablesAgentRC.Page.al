// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN27
#pragma warning disable AS0050
#endif

namespace Microsoft.Agent.PayablesAgent;

page 3303 "Payables Agent RC"
{
    Extensible = false;
    PageType = RoleCenter;
    Caption = 'Payables Agent', Locked = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    actions
    {
        area(Processing)
        {
            action(OpenEDocumentToProcess)
            {
                ApplicationArea = All;
                Caption = 'Open E-Document to Process';
                ToolTip = 'Open the E-Document to process.';
                RunObject = codeunit "PA Open Current E-Document";
            }
        }
    }
}
#if not CLEAN27
#pragma warning restore AS0050
#endif