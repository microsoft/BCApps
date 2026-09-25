// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

using Microsoft.FixedAssets.Depreciation;

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
                Visible = DepreciationDifferencesEnabled;
            }
        }
    }

    trigger OnOpenPage()
    var
        DepreciationDifferencesFIFeature: Codeunit "FI Depreciation Diff. Feature";
    begin
        DepreciationDifferencesEnabled := DepreciationDifferencesFIFeature.IsEnabled();
    end;

    var
        DepreciationDifferencesEnabled: Boolean;
}
