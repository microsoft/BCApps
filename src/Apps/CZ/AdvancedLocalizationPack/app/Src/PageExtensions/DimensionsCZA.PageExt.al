// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

pageextension 31292 "Dimensions CZA" extends "Dimensions"
{
    actions
    {
        addlast("&Dimension")
        {
            action(AutoCreateDefaultDimSetupCZA)
            {
                ApplicationArea = Dimensions;
                Caption = 'Auto-Create Default Dimension Setup';
                ToolTip = 'Opens the setup of automatic default dimension creation.';
                Image = Dimensions;
                RunObject = page "Auto. Create Default Dim. CZA";
                RunPageLink = "Dimension Code" = field(Code);
            }
        }
        addlast(Category_Category4)
        {
            actionref(AutoCreateDefaultDimSetupCZA_promoted; AutoCreateDefaultDimSetupCZA)
            {
            }
        }
    }
}
