// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

using Microsoft.FixedAssets.Depreciation;

pageextension 13400 SourceCodeSetupFI extends "Source Code Setup"
{
    layout
    {
        addafter("Insurance Journal")
        {
#if not CLEAN30
#pragma warning disable AL0432
            field("Depr. Difference"; Rec."Depr. Difference")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the source code for posting differences in accumulated depreciation.';
                Visible = LegacyDepreciationDifferencesVisible;
                ObsoleteState = Pending;
                ObsoleteTag = '30.0';
                ObsoleteReason = 'Moved to Depreciation Differences FI app.';
            }
#pragma warning restore AL0432
#endif
        }
    }

    trigger OnOpenPage()
    var
        DepreciationDifferencesFIFeature: Codeunit "FI Depreciation Diff. Feature";
    begin
        LegacyDepreciationDifferencesVisible := not DepreciationDifferencesFIFeature.IsEnabled();
    end;

    var
        LegacyDepreciationDifferencesVisible: Boolean;
}