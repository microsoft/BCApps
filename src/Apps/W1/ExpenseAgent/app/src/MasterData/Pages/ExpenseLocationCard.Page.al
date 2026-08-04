// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6920 "Expense Location Card"
{
    PageType = Card;
    ApplicationArea = Basic, Suite;
    SourceTable = "Expense Location";
    Caption = 'Expense Location Card';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the location number.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the expense location. Used for per-diem calculations.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ToolTip = 'Specifies the country/region code for the expense location.';
                }
                field(City; Rec.City)
                {
                    ToolTip = 'Specifies the city for the expense location. This field is optional and used only when multiple locations exist in the same country/region.';
                }
                field(County; Rec.County)
                {
                    ToolTip = 'Specifies the county for the expense location. This field is optional and used this field to further identify or categorize the location within the country/region.';
                }
            }
        }
    }
}