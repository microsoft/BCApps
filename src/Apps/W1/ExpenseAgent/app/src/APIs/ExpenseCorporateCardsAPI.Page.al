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
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    SourceTable = "EA Corp Card";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DataAccessIntent = ReadOnly;
    Permissions = tabledata "EA Corp Card" = r;

    layout
    {
        area(Content)
        {
            repeater(Cards)
            {
                field(id; Rec.SystemId) { Caption = 'Id'; Editable = false; }
                field(corporateCardId; Rec."Card Id") { Caption = 'Corporate Card Id'; }
                field(expenseUserNumber; Rec."Expense User No.") { Caption = 'Expense User Number'; }
                field(lastFourDigits; Rec.GetLastFourDigits()) { Caption = 'Last Four Digits'; ToolTip = 'Specifies the last four digits used to identify the corporate card.'; }
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
        if not GetLinkedExpenseUserNo(ExpenseUserNo) then
            Error(GetExpenseUserFilterRequiredError());
        Rec.FilterGroup(2);
        Rec.SetRange("Expense User No.", ExpenseUserNo);
        Rec.SetRange(Blocked, false);
        Rec.FilterGroup(0);
    end;

    // expenseUsers({id})/corporateCards passes the expense user through the subpage link, which is set in filter group 4.
    local procedure GetLinkedExpenseUserNo(var ExpenseUserNo: Code[20]): Boolean
    var
        OriginalFilterGroup: Integer;
    begin
        OriginalFilterGroup := Rec.FilterGroup();
        Rec.FilterGroup(4);
        if Rec.GetFilter("Expense User No.") <> '' then
            ExpenseUserNo := Rec.GetRangeMin("Expense User No.");
        Rec.FilterGroup(OriginalFilterGroup);
        exit(ExpenseUserNo <> '');
    end;

    local procedure GetExpenseUserFilterRequiredError(): ErrorInfo
    var
        ExpenseUserFilterError: ErrorInfo;
    begin
        ExpenseUserFilterError.Title := ExpenseUserFilterRequiredTitleErr;
        ExpenseUserFilterError.Message := ExpenseUserFilterRequiredErr;
        ExpenseUserFilterError.ErrorType := ErrorType::Client;
        ExpenseUserFilterError.DataClassification := DataClassification::SystemMetadata;
        exit(ExpenseUserFilterError);
    end;

    var
        ExpenseUserFilterRequiredTitleErr: Label 'Expense user filter required';
        ExpenseUserFilterRequiredErr: Label 'Read corporate cards through a single expense user. Retry the request with expenseUsers(<expense-user-id>)/corporateCards.', Comment = 'expenseUsers and corporateCards are OData API identifiers; <expense-user-id> is a placeholder for an expense user ID.';
}
