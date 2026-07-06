// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

page 3313 "PA Known Senders"
{
    Caption = 'Payables Agent Known Senders', Comment = 'Payables Agent is a term, and should not be translated.';
    PageType = List;
    SourceTable = "PA Known Sender";
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Email; Rec.Email)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the email address of a sender whose e-documents have been processed by the Payables Agent.';
                }
            }
        }
    }
}
