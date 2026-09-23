// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6937 "Expense Locations"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    RefreshOnActivate = true;
    SourceTable = "Expense Location";
    CardPageID = "Expense Location Card";
    Editable = false;
    AdditionalSearchTerms = 'Per-Diem Location, Rate Location, Allowance Location, Expense Zone, Allowance Zone, Travel Location, Travel Destination, Location';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the location number.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the location description.';
                }
            }
        }
    }
}