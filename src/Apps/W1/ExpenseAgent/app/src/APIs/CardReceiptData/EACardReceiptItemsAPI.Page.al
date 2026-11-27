// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7423 "EA Card Receipt Items API"
{
    PageType = API;
    APIPublisher = 'microsoft';
    APIGroup = 'expense';
    APIVersion = 'beta';
    EntityName = 'cardReceiptItem';
    EntitySetName = 'cardReceiptItems';
    EntityCaption = 'Card Receipt Item';
    EntitySetCaption = 'Card Receipt Items';
    SourceTable = "EA Card Receipt Item";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(expenseSubcategoryCode; Rec."Expense Subcategory Code")
                {
                    Caption = 'Expense Subcategory Code';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(startDate; Rec."Start Date")
                {
                    Caption = 'Start Date';
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                }
                field(dailyRate; Rec."Daily Rate")
                {
                    Caption = 'Daily Rate';
                }
            }
        }
    }

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        CardReceiptData: Record "EA Card Receipt Data";
        CardReceiptItem: Record "EA Card Receipt Item";
        ReceiptDataFilter: Text;
        OriginalFilterGroup: Integer;
    begin
        if IsNullGuid(Rec."Receipt Data Id") then begin
            OriginalFilterGroup := Rec.FilterGroup();
            Rec.FilterGroup(4);
            ReceiptDataFilter := Rec.GetFilter("Receipt Data Id");
            Rec.FilterGroup(OriginalFilterGroup);
            if ReceiptDataFilter <> '' then
                if Evaluate(Rec."Receipt Data Id", ReceiptDataFilter) then;
        end;
        CardReceiptData.Get(Rec."Receipt Data Id");
        if Rec."Line No." = 0 then begin
            CardReceiptItem.SetRange("Receipt Data Id", Rec."Receipt Data Id");
            if CardReceiptItem.FindLast() then;
            Rec."Line No." := CardReceiptItem."Line No." + 10000;
        end;
        exit(true);
    end;
}
