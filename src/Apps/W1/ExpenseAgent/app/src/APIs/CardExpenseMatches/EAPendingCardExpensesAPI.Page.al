// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7421 "EA Pending Card Expenses API"
{
    PageType = API;
    APIPublisher = 'microsoft';
    APIGroup = 'expense';
    APIVersion = 'beta';
    EntityName = 'pendingCardExpense';
    EntitySetName = 'pendingCardExpenses';
    EntityCaption = 'Pending Card Expense';
    EntitySetCaption = 'Pending Card Expenses';
    SourceTable = Expense;
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    DataAccessIntent = ReadOnly;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutTitle = 'Pending Card Expenses';
    AboutText = 'Lists the expenses of an expense user that were created from corporate card transactions and are still waiting for a receipt and an expense report.';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                }
                field(number; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(expenseDate; Rec."Expense Date")
                {
                    Caption = 'Expense Date';
                }
                field(amount; Rec.Amount)
                {
                    Caption = 'Amount';
                }
                field(currencyCode; CurrencyCodeDisplay)
                {
                    Caption = 'Currency Code';
                }
                field(merchantName; Rec."Merchant Name")
                {
                    Caption = 'Merchant Name';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(expenseCategory; Rec."Expense Category")
                {
                    Caption = 'Expense Category';
                }
                field(corporateCardId; Rec."Corporate Card Id")
                {
                    Caption = 'Corporate Card Id';
                }
            }
        }
    }

    var
        CurrencyHelper: Codeunit "Expense API Currency Helper";
        CurrencyCodeDisplay: Code[10];
        ScopeRequiredErr: Label 'Pending card expenses must be requested for an expense user through expenseUsers({id})/pendingCardExpenses.';

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;

    trigger OnOpenPage()
    var
        ReceiptExpenseMatch: Codeunit "EA Receipt Expense Match";
    begin
        Rec.FilterGroup(2);
        ReceiptExpenseMatch.SetPendingCardExpenseFilters(Rec);
        Rec.FilterGroup(0);
        Rec.AddLoadFields("Currency Code");
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if not HasExpenseUserScope() then
            Error(ScopeRequiredErr);
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    begin
        CurrencyCodeDisplay := CurrencyHelper.GetCurrencyCodeForAPI(Rec."Currency Code");
    end;

    local procedure HasExpenseUserScope(): Boolean
    var
        OriginalFilterGroup: Integer;
        UserFilter: Text;
    begin
        if Rec.GetFilter("Expense User No.") <> '' then
            exit(true);

        OriginalFilterGroup := Rec.FilterGroup();
        Rec.FilterGroup(4);
        UserFilter := Rec.GetFilter("Expense User No.");
        Rec.FilterGroup(OriginalFilterGroup);
        exit(UserFilter <> '');
    end;
}
