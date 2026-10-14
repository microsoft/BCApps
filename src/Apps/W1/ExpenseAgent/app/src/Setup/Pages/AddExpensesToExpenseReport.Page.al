// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6960 "Add Expenses To Expense Report"
{
    PageType = StandardDialog;
    Caption = 'Add Expenses To Expense Report';
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            group("Add To")
            {
                ShowCaption = false;
                field(AddExpenseTo; AddExpenseTo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'How do you want to add expenses?';
                    OptionCaption = 'New Expense Report,Existing Expense Report';
                    ToolTip = 'Specifies whether a new expense report is created when adding expenses.';

                    trigger OnValidate()
                    begin
                        if AddExpenseTo = AddExpenseTo::"New Expense Report" then
                            ExpenseReportNo := '';
                    end;
                }
                group(ExpenseReport)
                {
                    ShowCaption = false;
                    Visible = (AddExpenseTo = AddExpenseTo::"Existing Expense Report");
                    field(ExpenseReportNo; ExpenseReportNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Expense Report No.';
                        ToolTip = 'Specifies the expense report number to which expenses will be added.';
                        Lookup = true;
                        LookupPageId = "Expense Reports";

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            ExpenseReportHeader: Record "Expense Report Header";
                        begin
                            ExpenseReportHeader.SetRange(Status, ExpenseReportHeader.Status::Open);
                            ExpenseReportHeader.SetRange("Expense User No.", Expense."Expense User No.");

                            if Page.RunModal(Page::"Expense Report List", ExpenseReportHeader) = Action::LookupOK then
                                ExpenseReportNo := ExpenseReportHeader."No.";
                        end;
                    }
                }
            }
        }
    }

    var
        Expense: Record Expense;
        AddExpenseTo: Option "New Expense Report","Existing Expense Report";
        ExpenseReportNo: Code[20];
        MustSelectExpenseReportErr: Label 'You must select either New Expense Report or Existing Expense Report.';

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [CloseAction::OK, CloseAction::LookupOK] then
            if (AddExpenseTo = AddExpenseTo::"Existing Expense Report") and (ExpenseReportNo = '') then
                Error(MustSelectExpenseReportErr);
    end;

#pragma warning disable AL0749
    procedure SetExpenseRecord(NewExpense: Record Expense)
#pragma warning restore AL0749
    begin
        Expense := NewExpense;
    end;

    procedure GetExpenseReportNo(): Code[20]
    begin
        exit(ExpenseReportNo);
    end;
}