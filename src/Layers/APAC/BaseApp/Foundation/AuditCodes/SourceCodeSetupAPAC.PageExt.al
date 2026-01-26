// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

pageextension 28040 SourceCodeSetupAPAC extends "Source Code Setup"
{
    layout
    {
        addafter("VAT Settlement")
        {
            field("WHT Settlement"; Rec."WHT Settlement")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies that another source code is added for WHT settlement transactions.';
            }
        }
    }
}