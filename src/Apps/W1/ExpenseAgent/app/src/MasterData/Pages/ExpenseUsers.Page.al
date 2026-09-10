// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6951 "Expense Users"
{
    Caption = 'Expense Users';
    PageType = List;
    ApplicationArea = Basic, Suite;
    CardPageID = "Expense User";
    UsageCategory = Lists;
    RefreshOnActivate = true;
    SourceTable = "Expense User";
    AboutTitle = 'About expense users';
    AboutText = 'Manage records for employees who submit expenses, including the personal and job details required to process them. Expense users are managed separately from standard employees, and only individuals with an expense user record can submit expenses.';
    AdditionalSearchTerms = 'Expense Employees, Submitters, Claimants';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the number assigned to the expense user.';
                    Editable = Rec."No." = '';
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ToolTip = 'Specifies the employee selected from the employee table.';
                    Editable = Rec."Employee No." = '';
                }
                field("Name"; Rec."Name")
                {
                    ToolTip = 'Specifies the expense user''s name. If an employee number is selected, the name is filled automatically using the first and last name from the employee table.';
                    Editable = false;
                }
                field(CanApprove; Rec."Can Approve")
                {
                    Editable = false;
                }
                field("Job Title"; Rec."Job Title")
                {
                    ToolTip = 'Specifies the expense user''s job title. If an employee number is selected, it is filled automatically from the employee table.';
                    Editable = false;
                }
                field("E-mail"; Rec."E-mail")
                {
                    ToolTip = 'Specifies the expense user''s company email address. If an employee number is selected, it is filled automatically from the company email on the employee table.';
                    Editable = false;
                }
                field(ApproverName; Rec."Approver Name")
                {
                    DrillDown = false;
                    Editable = false;
                }
                field("Welcome Email Status"; Rec."Welcome Email Status")
                {
                    ToolTip = 'Specifies whether a welcome email has been queued, sent, or failed for the expense user.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddExistingEmployees)
            {
                Caption = 'Add all employees';
                ApplicationArea = All;
                Image = Copy;
                ToolTip = 'Adds active employees from this company as expense users.';

                trigger OnAction()
                begin
                    SuggestAutomaticCreation(true);
                    CurrPage.Update(false);
                end;
            }
            action(ImportExpenseUsers)
            {
                Caption = 'Import Expense Users';
                ApplicationArea = All;
                Image = Import;
                ToolTip = 'Imports employees from your organization as expense users.';

                trigger OnAction()
                var
                    ImportExpenseUser: Codeunit "Import Expense User";
                begin
                    ImportExpenseUser.ImportExpenseUsers();
                    CurrPage.Update();
                end;
            }
            action(CreateEmployee)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create Employee';
                Image = Create;
                ToolTip = 'Checks for an existing employee by email and creates an employee if no match exists.';
                Visible = IsCreateEmployeeVisible;

                trigger OnAction()
                begin
                    Rec.CreateEmployeeFromExpenseUser();
                end;
            }
            action("Send Welcome Email")
            {
                Caption = 'Send Welcome Email';
                ApplicationArea = Basic, Suite;
                Image = Email;
                ToolTip = 'Sends a welcome email to the selected expense user.';

                trigger OnAction()
                var
                    ExpenseUser: Record "Expense User";
                begin
                    CurrPage.SetSelectionFilter(ExpenseUser);
                    Rec.SendWelcomeEmail(ExpenseUser);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Create Expense Users';

                actionref(AddExistingEmployees_Promo; AddExistingEmployees)
                {
                }
                actionref(ImportExpenseUsers_Promo; ImportExpenseUsers)
                {
                }
                actionref(CreateEmployee_Promoted; CreateEmployee)
                {
                }
                actionref(SendWelcomeEmail_Promoted; "Send Welcome Email")
                {
                }
            }
        }
    }
    var
        IsCreateEmployeeVisible: Boolean;
        NoUsersQst: Label 'There are no registered expense users. Do you want to automatically create them for all employees?';

    trigger OnDeleteRecord(): Boolean
    begin
        exit(Rec.ConfirmApproverReassignment());
    end;

    trigger OnOpenPage()
    var
        ExpenseUser: Record "Expense User";
    begin
        SetControlAppearance();
        if ExpenseUser.IsEmpty() then  // Rec may be filtered from the opening code
            if Confirm(NoUsersQst) then
                SuggestAutomaticCreation(false);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetControlAppearance();
    end;

    local procedure SuggestAutomaticCreation(AskFirst: Boolean)
    var
        ImportExpenseUser: Codeunit "Import Expense User";
    begin
        ImportExpenseUser.AddExistingEmployees(AskFirst);
    end;

    local procedure SetControlAppearance()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.SetLoadFields("Create Emp. for Expense Users");
        ExpenseAgentSetup.GetRecordOnce();

        IsCreateEmployeeVisible := ExpenseAgentSetup."Create Emp. for Expense Users";
    end;
}