// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7420 "EA Card Expense Matches API"
{
    PageType = API;
    APIPublisher = 'microsoft';
    APIGroup = 'expense';
    APIVersion = 'beta';
    EntityName = 'cardExpenseMatch';
    EntitySetName = 'cardExpenseMatches';
    EntityCaption = 'Card Expense Match';
    EntitySetCaption = 'Card Expense Matches';
    SourceTable = "EA Card Expense Match Buffer";
    SourceTableTemporary = true;
    ODataKeyFields = Id;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutTitle = 'Card Expense Matches';
    AboutText = 'Finds the corporate card expense that a receipt belongs to. POST the extracted receipt data through expenseUsers({id})/cardExpenseMatches; expenseId returns the matching card-created expense that still needs a receipt, or an empty GUID when there is no match. Nothing is written.';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.Id)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(expenseDate; Rec."Expense Date")
                {
                    Caption = 'Expense Date';
                }
                field(amount; Rec.Amount)
                {
                    Caption = 'Amount';
                }
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                }
                field(merchantName; Rec."Merchant Name")
                {
                    Caption = 'Merchant Name';
                }
                field(expenseId; Rec."Expense SystemId")
                {
                    Caption = 'Expense Id';
                    Editable = false;
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
        ReceiptExpenseMatch: Codeunit "EA Receipt Expense Match";
    begin
        Rec.Id := CreateGuid();
        Rec."Expense User SystemId" := GetScopedExpenseUserSystemId();
        Rec."Expense SystemId" := ReceiptExpenseMatch.FindMatchingExpense(
            Rec."Expense User SystemId", Rec."Expense Date", Rec.Amount, Rec."Currency Code", Rec."Merchant Name");
        Rec.Insert();
        exit(false);
    end;

    // The expense user comes only from the expenseUsers({id}) navigation link, never from the request body.
    local procedure GetScopedExpenseUserSystemId() ExpenseUserSystemId: Guid
    var
        UserFilter: Text;
        OriginalFilterGroup: Integer;
    begin
        if not IsNullGuid(Rec."Expense User SystemId") then
            exit(Rec."Expense User SystemId");

        OriginalFilterGroup := Rec.FilterGroup();
        Rec.FilterGroup(4);
        UserFilter := Rec.GetFilter("Expense User SystemId");
        Rec.FilterGroup(OriginalFilterGroup);
        if UserFilter <> '' then
            if Evaluate(ExpenseUserSystemId, UserFilter) then;
    end;
}
