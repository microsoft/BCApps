// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7142 "Expense Spend Limits"
{
    Caption = 'Expense Spend Limits';
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    DelayedInsert = true;
    SourceTable = "Expense Spend Limit";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    Editable = false;
                }
                field("Period Type"; Rec."Period Type")
                {
                }
                field("Start Date"; Rec."Start Date")
                {
                    ShowMandatory = true;
                }
                field("End Date"; Rec."End Date")
                {
                    Editable = false;
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                }
                field("Spend Limit Type"; Rec."Spend Limit Type")
                {
                }
                field("Limit For"; Rec."Limit For")
                {
                    Editable = Rec."Spend Limit Type" <> Rec."Spend Limit Type"::Company;
                    ShowMandatory = Rec."Spend Limit Type" <> Rec."Spend Limit Type"::Company;
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ShowMandatory = true;
                }
            }
        }
    }
}