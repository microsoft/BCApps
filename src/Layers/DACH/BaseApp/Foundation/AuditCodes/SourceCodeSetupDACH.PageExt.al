// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

pageextension 5005270 SourceCodeSetupDACH extends "Source Code Setup"
{
    layout
    {
        addafter("Compress Vend. Ledger")
        {
            field("Delivery Reminder"; Rec."Delivery Reminder")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the source code linked to entries that are posted from a Delivery Reminder Header.';
            }
        }
    }
}