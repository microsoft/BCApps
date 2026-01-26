// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

pageextension 11307 SourceCodeSetupBE extends "Source Code Setup"
{
    layout
    {
        modify("Financially Voided Check")
        {
            Visible = false;
        }
        addafter("Cash Flow Worksheet")
        {
            field("Financial Journal"; Rec."Financial Journal")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the source code linked to entries that are posted from a journal of the Financial type.';
            }
            field("Domiciliation Journal"; Rec."Domiciliation Journal")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the source code linked to entries that are posted from a domiciliation journal.';
            }
        }
    }
}