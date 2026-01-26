// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

pageextension 13400 SourceCodeSetupFI extends "Source Code Setup"
{
    layout
    {
        addafter("Insurance Journal")
        {
            field("Depr. Difference"; Rec."Depr. Difference")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the source code for posting differences in accumulated depreciation.';
            }
        }
    }
}