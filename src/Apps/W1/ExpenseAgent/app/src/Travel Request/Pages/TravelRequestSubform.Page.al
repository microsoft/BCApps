// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;

page 7137 "Travel Request Subform"
{
    Caption = 'Lines';
    PageType = ListPart;
    ApplicationArea = Basic, Suite;
    SourceTable = "Spend Request Detail";
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Line No."; Rec."Line No.")
                {
                    Visible = false;
                    ToolTip = 'Specifies the line number of the travel request line.';
                }
                field(Type; Rec.Type)
                {
                    ToolTip = 'Specifies whether the line covers a specific expense category or a lump sum amount.';
                }
                field("Expense Category Code"; Rec."Expense Category Code")
                {
                    ToolTip = 'Specifies the expense category for the line. Available only when Type is Category.';
                    Editable = Rec.Type = Rec.Type::Category;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a description of the travel request line.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ToolTip = 'Specifies the currency used for estimation. The currency amount will automatically be converted into Expected Amount (LCY).';
                }
                field(Amount; Rec."Expected Amount")
                {
                    ToolTip = 'Specifies the expected amount of the travel request line.';
                }
                field(AmountLCY; Rec."Expected Amount (LCY)")
                {
                    ToolTip = 'Specifies the expected amount of the travel request line in local currency.';
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ToolTip = 'Specifies the G/L account that the expenses will be posted to.';
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        SpendRequest: Record "Spend Request";
    begin
        if Rec."Spend Request No." = '' then
            exit;
        SpendRequest.Get(Rec."Spend Request No.");
        if SpendRequest.Status = SpendRequest.Status::Open then
            Rec.Validate("Currency Code", SpendRequest."Currency Code");
    end;
}
