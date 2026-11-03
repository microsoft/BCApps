// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7451 "Expense Corporate Cards API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityName = 'corporateCard';
    EntitySetName = 'corporateCards';
    EntityCaption = 'Corporate Card';
    EntitySetCaption = 'Corporate Cards';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "EA Corp Card";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DataAccessIntent = ReadOnly;

    layout
    {
        area(Content)
        {
            repeater(Cards)
            {
                field(id; Rec.SystemId) { Caption = 'Id'; }
                field(corporateCardId; Rec."Card Id") { Caption = 'Corporate Card Id'; }
                field(expenseUserNumber; Rec."Expense User No.") { Caption = 'Expense User Number'; }
                field(lastFourDigits; Rec.GetLastFourDigits()) { Caption = 'Last Four Digits'; }
                field(providerCode; Rec."Provider Code") { Caption = 'Provider Code'; }
                field(providerShortName; Rec."Provider Short Name") { Caption = 'Provider Short Name'; }
                field(currencyCode; Rec."Currency Code") { Caption = 'Currency Code'; }
                field(validFrom; Rec."Valid From") { Caption = 'Valid From'; }
                field(validTo; Rec."Valid To") { Caption = 'Valid To'; }
            }
        }
    }

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;

    trigger OnOpenPage()
    var
        ExpenseUserNo: Code[20];
    begin
        if Rec.GetFilter("Expense User No.") = '' then
            Error(ExpenseUserFilterRequiredErr);
        ExpenseUserNo := Rec.GetRangeMin("Expense User No.");
        if (ExpenseUserNo = '') or (ExpenseUserNo <> Rec.GetRangeMax("Expense User No.")) then
            Error(ExpenseUserFilterRequiredErr);
        Rec.FilterGroup(2);
        Rec.SetRange("Expense User No.", ExpenseUserNo);
        Rec.SetRange(Blocked, false);
        Rec.FilterGroup(0);
    end;

    var
        ExpenseUserFilterRequiredErr: Label 'Filter corporate cards by a single expenseUserNumber.';
}
