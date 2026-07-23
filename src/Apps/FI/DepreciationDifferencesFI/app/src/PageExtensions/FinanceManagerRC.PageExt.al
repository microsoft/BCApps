// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.RoleCenters;

using Microsoft.FixedAssets.Depreciation;

pageextension 13476 "Finance Mgr. RC DeprDiff FI" extends "Finance Manager Role Center"
{
    actions
    {
        addafter("Insurance...")
        {
            action("Calc. and Post Depr. Difference")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Calc. and Post Depr. Difference';
                RunObject = report "Calc. and Post Depr. Diff.";
            }
        }
    }
}
