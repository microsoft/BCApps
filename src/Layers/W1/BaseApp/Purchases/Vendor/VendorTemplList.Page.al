// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

page 1385 "Vendor Templ. List"
{
    Caption = 'Vendor Templates';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Vendor Templ.";
    CardPageId = "Vendor Templ. Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the template.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the template.';
                }
                field("Contact Type"; Rec."Contact Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of contact that will be used to create a vendor with the template.';
                }
            }
        }
    }
}
