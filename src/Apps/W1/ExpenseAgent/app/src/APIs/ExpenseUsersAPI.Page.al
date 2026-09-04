// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6918 "Expense Users API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense User';
    EntitySetCaption = 'Expense Users';
    EntityName = 'expenseUser';
    EntitySetName = 'expenseUsers';
    PageType = API;
    ODataKeyFields = SystemId;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataAccessIntent = ReadOnly;
    SourceTable = "Expense User";
    AboutText = 'Lists details about users that can use the expense functionalities (for example, as submitters or approvers of expenses).';

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
                field(number; Rec."No.")
                {
                    Caption = 'Number';
                }
                field(employeeNumber; Rec."Employee No.")
                {
                    Caption = 'Employee Number';
                }
                field(name; Rec.Name)
                {
                    Caption = 'Name';
                }
                field(eMail; Rec."E-mail")
                {
                    Caption = 'Email';
                }
                field(jobTitle; Rec."Job Title")
                {
                    Caption = 'Job Title';
                }
                field(canApprove; Rec."Can Approve")
                {
                    Caption = 'Can Approve';
                }
                field(employeeStatus; Rec."Employee Status")
                {
                    Caption = 'Employee Status';
                }

                part(employees; "Employees API")
                {
                    EntityName = 'employee';
                    EntitySetName = 'employees';
                }

                part(expenses; "Expenses API")
                {
                    EntityName = 'expense';
                    EntitySetName = 'expenses';
                    SubPageLink = "Expense User No." = field("No.");
                }

                part(expenseReports; "Expense Reports API")
                {
                    EntityName = 'expenseReport';
                    EntitySetName = 'expenseReports';
                    SubPageLink = "Expense User No." = field("No.");
                }

                part(travelRequests; "Travel Requests API")
                {
                    EntityName = 'travelRequest';
                    EntitySetName = 'travelRequests';
                    SubPageLink = "Requested By" = field("Employee No.");
                }

                part(activityHistory; "Expense Activity Log API")
                {
                    EntityName = 'expenseActivityLogEntry';
                    EntitySetName = 'expenseActivityLogEntries';
                    SubPageLink = "History Actor Table ID Filter" = const(Database::"Expense User"),
                                  "History Actor System ID Filter" = field(SystemId);
                }

                part(approverView; "Approver View API")
                {
                    EntityName = 'approverView';
                    EntitySetName = 'approverViews';
                    SubPageLink = "No." = field("No."),
                                  "Can Approve" = const(true);
                    Multiplicity = ZeroOrOne;
                }

                part(expenseApprovalSetup; "Expense Approval Setup API")
                {
                    EntityName = 'expenseApprovalSetup';
                    EntitySetName = 'expenseApprovalSetups';
                    SubPageLink = "Expense User No." = field("No.");
                    Multiplicity = ZeroOrOne;
                }

                part(projects; "Expense Projects API")
                {
                    EntityName = 'expenseProject';
                    EntitySetName = 'expenseProjects';
                    SubPageLink = "Expense User SystemId" = field(SystemId);
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

    trigger OnOpenPage()
    var
        OriginalFilterGroup: Integer;
    begin
        // Expense Users without a linked Employee No. cannot post expenses
        // (validation fails at submission), so don't surface them to the agent
        // gateway. The gateway treats an absent user as "not in this environment"
        // and blocks sign-in there. Apply the constraint in FilterGroup 2 so it
        // AND-combines with any caller-supplied $filter on Employee No., rather
        // than replacing it in the default FilterGroup 0.
        OriginalFilterGroup := Rec.FilterGroup();
        Rec.FilterGroup(2);
        Rec.SetFilter("Employee No.", '<>%1', '');
        Rec.FilterGroup(OriginalFilterGroup);
    end;
}