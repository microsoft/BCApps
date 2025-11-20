// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

page 465 "Tax Area Line"
{
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Tax Area Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Tax Jurisdiction Code"; Rec."Tax Jurisdiction Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a tax jurisdiction code.';
                }
                field("Jurisdiction Description"; Rec."Jurisdiction Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description from the tax jurisdiction table when you enter the tax jurisdiction code.';
                }
                field("Calculation Order"; Rec."Calculation Order")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an integer to determine the sequence the program must use when tax is calculated.';
                }
            }
        }
    }

    actions
    {
    }
}

