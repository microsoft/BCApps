// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

page 10697 "VAT Specifications"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Specifications';
    PageType = List;
    SourceTable = "VAT Specification";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code.';
                }
                field("VAT Report Value"; Rec."VAT Report Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a values that will be used for the electronic VAT return submission.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description.';
                }
            }
        }
    }
}
