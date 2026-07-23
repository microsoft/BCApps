// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

pageextension 13479 "Source Code Setup DeprDiff Pg" extends "Source Code Setup"
{
    layout
    {
        addafter("Insurance Journal")
        {
            field("Depreciation Difference Code"; Rec."Depreciation Difference Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the source code for posting differences in accumulated depreciation.';
            }
        }
    }
}
