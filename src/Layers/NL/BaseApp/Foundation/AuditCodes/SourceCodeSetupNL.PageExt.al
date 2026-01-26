// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

pageextension 11400 SourceCodeSetupNL extends "Source Code Setup"
{
    layout
    {
        addafter("Cash Flow Worksheet")
        {
            field("Cash Journal"; Rec."Cash Journal")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the source code that is linked to entries that are posted from a cash journal.';
            }
            field("Bank Journal"; Rec."Bank Journal")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the source code that is linked to entries that are posted from a bank journal.';
            }
        }
    }
}