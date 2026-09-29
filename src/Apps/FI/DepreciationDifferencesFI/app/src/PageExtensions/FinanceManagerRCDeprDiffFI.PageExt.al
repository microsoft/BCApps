// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.RoleCenters;

#if CLEAN30
using Microsoft.FixedAssets.Depreciation;
#endif

pageextension 13480 "Finance Manager RC DeprDiff FI" extends "Finance Manager Role Center"
{
    actions
    {
        addafter("Insurance...")
        {
#if CLEAN30
            action("Calc. and Post Depr. Difference")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Calc. and Post Depr. Difference';
                RunObject = report "Calc. and Post Depr. Diff. FI";
                ToolTip = 'Calculate and post the difference in accumulated depreciation between two depreciation books for each fixed asset.';
            }
#endif
        }
    }
}
