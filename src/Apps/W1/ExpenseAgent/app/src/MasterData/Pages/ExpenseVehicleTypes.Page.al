// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7130 "Expense Vehicle Types"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = "Expense Vehicle Type";
    Caption = 'Vehicle Types';
    DelayedInsert = true;
    AdditionalSearchTerms = 'Vehicle Type, Car, Motorcycle, Van, Truck';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Code"; Rec."Code")
                {
                }
                field("Description"; Rec."Description")
                {
                }
            }
        }
    }
}
