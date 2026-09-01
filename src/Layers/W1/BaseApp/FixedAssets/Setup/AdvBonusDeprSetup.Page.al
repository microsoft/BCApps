// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Setup;

page 5614 "Adv. Bonus Depr. Setup"
{
    ApplicationArea = FixedAssets;
    Caption = 'Advanced Bonus Depreciation Setup';
    PageType = List;
    SourceTable = "Adv. Bonus Depreciation Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Effective Date"; Rec."Effective Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date when this bonus depreciation percentage becomes effective.';
                }
                field("FA Class Code"; Rec."FA Class Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the fixed asset class this bonus depreciation percentage applies to. If blank, it applies to all classes.';
                }
                field("Bonus Depreciation %"; Rec."Bonus Depreciation %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the percentage of bonus depreciation for the given effective date and asset class.';
                }
            }
        }
    }
}
