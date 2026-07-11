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
#if not CLEAN29
#pragma warning disable AL0432
            field("Depr. Difference"; Rec."Depr. Difference")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the source code for posting differences in accumulated depreciation.';
                ObsoleteState = Pending;
                ObsoleteTag = '29.0';
                ObsoleteReason = 'Moved to Depreciation Differences FI app.';
            }
#pragma warning restore AL0432
#endif
        }
    }
}