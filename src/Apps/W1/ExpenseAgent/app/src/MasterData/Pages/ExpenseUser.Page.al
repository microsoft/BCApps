// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Projects.Resources.Resource;

page 6949 "Expense User"
{
    PageType = Card;
    SourceTable = "Expense User";
    ApplicationArea = Basic, Suite;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number for this expense user.';
                    Visible = NoFieldVisible;

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEdit();
                    end;
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the value of the Employee No. field.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = additional;
                    ToolTip = 'Specifies the resource linked to the employee.';

                    trigger OnDrillDown()
                    var
                        Resource: Record Resource;
                    begin
                        Rec.CalcFields("Resource No.");
                        if Rec."Resource No." = '' then
                            exit;
                        if Resource.Get(Rec."Resource No.") then
                            Page.Run(Page::"Resource Card", Resource);
                    end;
                }
                field("Name"; Rec."Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec."Employee No." = '';
                    ToolTip = 'Specifies the expense user name.';
                }
                field("E-mail"; Rec."E-mail")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec."Employee No." = '';
                    ToolTip = 'Specifies the expense user''s email address.';
                }
                field("Job Title"; Rec."Job Title")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec."Employee No." = '';
                    ToolTip = 'Specifies the expense user''s job title.';
                }
                field("Expense Team Code"; Rec."Expense Team Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expense team code the expense user belongs to.';
                }
                field("Team Manager"; Rec."Team Manager")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the team manager for this expense user.';
                }
                field("Can Approve"; Rec."Can Approve")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(ApproverNo; Rec."Approver No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the approver for this expense user.';
                    Visible = false;
                }
                field(ApproverName; Rec."Approver Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the approver for this expense user.';

                    trigger OnAssistEdit()
                    var
                        ExpenseUser: Record "Expense User";
                        ExpenseApprovalSetup: Record "Expense Approval Setup";
                        ExpenseUsers: Page "Expense Users";
                    begin
                        ExpenseUser."No." := Rec."Approver No.";
                        if ExpenseUser."No." <> '' then
                            ExpenseUsers.SetRecord(ExpenseUser);
                        ExpenseUser.SetFilter("E-mail", '<>%1', '');
                        ExpenseUser.SetRange("Is a System User", true);
                        ExpenseUser.SetRange("Can Approve", true);
                        ExpenseUsers.SetTableView(ExpenseUser);
                        ExpenseUsers.LookupMode(true);
                        if ExpenseUsers.RunModal() = Action::LookupOK then begin
                            ExpenseUsers.GetRecord(ExpenseUser);
                            if ExpenseUser."No." <> Rec."Approver No." then begin
                                ExpenseApprovalSetup.ReadIsolation(IsolationLevel::UpdLock);
                                if ExpenseApprovalSetup.Get(Rec."No.") then begin
                                    ExpenseApprovalSetup.Validate("Approver No.", ExpenseUser."No.");
                                    ExpenseApprovalSetup.Modify(true);
                                end else begin
                                    ExpenseApprovalSetup.Init();
                                    ExpenseApprovalSetup."Expense User No." := Rec."No.";
                                    ExpenseApprovalSetup.Validate("Approver No.", ExpenseUser."No.");
                                    if ExpenseApprovalSetup.Insert() then; // safeguard agains race conditions
                                end;
                                CurrPage.Update(false);
                            end;
                        end;
                    end;

                }
                field("Welcome Email Status"; Rec."Welcome Email Status")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies whether a welcome email has been queued, sent, or failed for the expense user.';
                }
            }
            part(ExpenseApprovalSetup; "Expense Approval Setups Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Can approve for these Expense Users';
                Visible = Rec."Can Approve";
                SubPageLink = "Approver No." = field("No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
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
                ToolTip = 'Sends a welcome email to the expense user.';

                trigger OnAction()
                var
                    ExpenseUser: Record "Expense User";
                begin
                    Rec.TestField("E-mail");

                    CurrPage.SetSelectionFilter(ExpenseUser);
                    Rec.SendWelcomeEmail(ExpenseUser);
                end;
            }
        }

        area(Navigation)
        {
            action(ApprovalSetup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Approval Setup';
                ToolTip = 'Opens the Expense Approval Setup page for this expense user.';
                Image = Approvals;

                trigger OnAction()
                var
                    ExpenseApprovalMgmt: Codeunit "Expense Approval Helper";
                begin
                    ExpenseApprovalMgmt.OpenApprovalSetupPage(Rec);
                end;
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                group(Category_Approval)
                {
                    Caption = 'Approval';
                    ShowAs = Standard;

                    actionref(ApprovalSetup_Promoted; ApprovalSetup)
                    {
                    }
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

    trigger OnDeleteRecord(): Boolean
    begin
        exit(Rec.ConfirmApproverReassignment());
    end;

    trigger OnOpenPage()
    begin
        SetCodeFieldVisible();
        SetControlAppearance();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetControlAppearance();
    end;

    var
        NoFieldVisible: Boolean;
        IsCreateEmployeeVisible: Boolean;

    local procedure SetCodeFieldVisible()
    var
        DocumentNoVisibility: Codeunit "Expense Doc No Visibility";
    begin
        NoFieldVisible := DocumentNoVisibility.ExpenseUserNoIsVisible();
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