// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.UOM;
using System.Agents;
using System.Email;
using System.Telemetry;
#pragma warning disable AS0031
#pragma warning disable AA0073
page 6996 "Expense Agent Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Expense Agent Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    UsageCategory = Administration;
    SourceTable = "Expense Agent Setup";

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Enable Agent"; Rec."Enable Agent")
                {
                    Editable = false;
                    ToolTip = 'Specifies whether the agent is active in this company. Use the Configure Expense Agent wizard from the agent avatar to activate or deactivate the agent; this page only reflects the current state.';
                }
                field(Mailbox; Rec."Email Address")
                {
                    Caption = 'Mailbox Account';
                    ToolTip = 'Specifies the email account that the agent monitors. You need permission to the mailbox to activate the agent.';
                    Editable = false;
                    ShowMandatory = true;

                    trigger OnAssistEdit()
                    var
                        OldEmailAddress: Text[250];
                    begin
                        OldEmailAddress := Rec."Email Address";
                        Rec.AssistEditMailbox();
                        if OldEmailAddress <> Rec."Email Address" then
                            ScheduleAllTasks();
                    end;
                }
                field("Enable Email with Receipts"; Rec."Enable Email with Receipts")
                {
                }
                field("Exchange Rate for Expenses"; Rec."Exchange Rate for Expenses")
                {
                }
                field("Allow Prepayment-Cash Advance"; Rec."Allow Prepayment-Cash Advance")
                {
                }
                field("Allow Grp. of Trans. in Report"; Rec."Allow Grp. of Trans. in Report")
                {
                }
                field("Allow VAT Reclaim"; Rec."Allow VAT Reclaim")
                {
                }
                field("Expense Report Grouping"; Rec."Expense Report Grouping")
                {
                    Visible = false;
                }
#if not CLEAN29
                field("Exp. Report Rounding Precision"; Rec."Exp. Report Rounding Precision")
                {
                    ObsoleteState = Pending;
                    ObsoleteTag = '29.0';
                    ObsoleteReason = 'This field is no longer required and will be removed in a future release.';
                }
                field("Expense Report Rounding Type"; Rec."Expense Report Rounding Type")
                {
                    ObsoleteState = Pending;
                    ObsoleteTag = '29.0';
                    ObsoleteReason = 'This field is no longer required and will be removed in a future release.';
                }
#endif
                field("Receipt No. Mandatory"; Rec."Receipt No. Mandatory")
                {
                }
                field("Merchant Name Mandatory"; Rec."Merchant Name Mandatory")
                {
                }
                field("Payment Methods Applied"; Rec."Payment Methods Applied")
                {
                    Importance = Additional;
                }
                field("Posting Groups Applied"; Rec."Posting Groups Applied")
                {
                    Importance = Additional;
                }
                field("No. Series Applied"; Rec."No. Series Applied")
                {
                    Importance = Additional;
                }
                field("Exp. Categories Applied"; Rec."Exp. Categories Applied")
                {
                    Importance = Additional;
                }
                field("Exp. Locations Applied"; Rec."Exp. Locations Applied")
                {
                    Importance = Additional;
                }
                field("Management Rules Applied"; Rec."Management Rules Applied")
                {
                    Importance = Additional;
                }
                field("Create Emp. for Expense Users"; Rec."Create Emp. for Expense Users")
                {
                }
                field("Default VAT Bus. Posting Group"; Rec."Default VAT Bus. Posting Group")
                {
                    Importance = Additional;
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                InstructionalText = 'Define how users are notified about unsubmitted expenses and approval events.';

                group(OutgoingEmail)
                {
                    Caption = 'Send mail';

                    field("Noreply Email Address"; Rec."Noreply Email Address")
                    {
                        Caption = 'Account';
                        ToolTip = 'Specifies the email account used for all outgoing Expense Agent messages: pending-approval requests sent to approvers, approved/rejected notifications sent to submitters, reimbursement notifications, and the optional open report reminders. If empty, the main mailbox account is used instead. When no email account is registered, the messages fail silently after the configured number of retries.';
                        Editable = false;

                        trigger OnAssistEdit()
                        begin
                            Rec.AssistEditNoreplyMailbox();
                        end;
                    }
                }
                group(OpenReportReminders)
                {
                    Caption = 'Notify users about unsubmitted reports';

                    field("Enable Open Report Notif."; Rec."Enable Open Report Notif.")
                    {
                        ShowCaption = false;

                        trigger OnValidate()
                        begin
                            CurrPage.Update(false);
                        end;
                    }
                    field("Open Report Notif. Freq."; Rec."Open Report Notif. Freq.")
                    {
                        Caption = 'Notification frequency';
                        Enabled = Rec."Enable Open Report Notif.";
                    }
                    field("Notif. Day of Week"; Rec."Notif. Day of Week")
                    {
                        Enabled = Rec."Enable Open Report Notif." and (Rec."Open Report Notif. Freq." = Rec."Open Report Notif. Freq."::Weekly);
                    }
                    field("Notif. Day In A Month"; Rec."Notif. Day In A Month")
                    {
                        Enabled = Rec."Enable Open Report Notif." and (Rec."Open Report Notif. Freq." = Rec."Open Report Notif. Freq."::Monthly);
                    }
                    field("Custom Notif. Formula"; Rec."Custom Notif. Formula")
                    {
                        Enabled = Rec."Enable Open Report Notif." and (Rec."Open Report Notif. Freq." = Rec."Open Report Notif. Freq."::Custom);
                    }
                }
                group(ApprovalNotifications)
                {
                    Caption = 'Notify users about approval updates';
                    InstructionalText = 'Sent when reports are submitted, approved, and rejected.';

                    field("Enable Approval Notif."; Rec."Enable Approval Notif.")
                    {
                        ShowCaption = false;
                        ToolTip = 'Specifies whether the system sends email notifications when expense reports are submitted, approved, or rejected.';
                    }
                }
            }
            group("Rule & Controls")
            {
                field("Use Rules"; Rec."Use Rules")
                {
                }
                field("Evaluate Policies"; Rec."Evaluate Policies")
                {
                    ToolTip = 'Specifies whether the agent evaluates expenses against the configured policies. Rules are evaluated by code, while policies are evaluated by AI, so enabling this consumes additional AI credits.';

                    trigger OnValidate()
                    var
                        ExpensePoliciesPage: Page "Expense Policies";
                    begin
                        if Rec."Evaluate Policies" and (not xRec."Evaluate Policies") then begin
                            if not Confirm(ActivatePolicyEvalQst, false) then
                                Error('');
                            ExpensePoliciesPage.Editable(true);
                            ExpensePoliciesPage.Run();
                        end;
                    end;
                }
                field("Submitter-run Evaluation"; Rec."Submitter-run Evaluation")
                {
                }
                field("Do Not Allow Expenses Older Than"; Rec."Do Not Allow Exp. Older Than")
                {
                }
                field("If Exp. Is Older Than Allowed"; Rec."If Exp. Is Older Than Allowed")
                {
                    Visible = false;
                }
                field("Check Category/Subcategory Usage"; Rec."Check Category/SubCat. Usage")
                {
                }
                field("Display Anti-Corruption attestation"; Rec."Enable Anti-Corp. Statement")
                {
                }
                field("Enable Approval Workflow"; Rec."Enable Approval Workflow")
                {
                }
                field(DefaultApprover; Rec."Default Approver Name")
                {
                    DrillDown = false;

                    trigger OnAssistEdit()
                    var
                        ExpenseUser: Record "Expense User";
                        ExpenseUsers: Page "Expense Users";
                    begin
                        ExpenseUser."No." := Rec."Default Approver No.";
                        if ExpenseUser."No." <> '' then
                            ExpenseUsers.SetRecord(ExpenseUser);
                        ExpenseUser.SetFilter("E-mail", '<>%1', '');
                        ExpenseUser.SetRange("Is a System User", true);
                        ExpenseUsers.SetTableView(ExpenseUser);
                        ExpenseUsers.LookupMode(true);
                        if ExpenseUsers.RunModal() = Action::LookupOK then begin
                            ExpenseUsers.GetRecord(ExpenseUser);
                            if ExpenseUser."No." <> Rec."Default Approver No." then begin
                                if not ExpenseUser."Can Approve" then begin
                                    ExpenseUser.Validate("Can Approve", true);
                                    ExpenseUser.Modify();
                                end;
                                Rec.Validate("Default Approver No.", ExpenseUser."No.");
                                CurrPage.Update(true);
                            end;
                        end;
                    end;
                }
            }
            group(Projects)
            {
                Caption = 'Projects';
                field("Enable Project Fields"; Rec."Enable Project Fields")
                {
                }
                field("Project Visibility"; Rec."Project Visibility")
                {
                    Enabled = Rec."Enable Project Fields";
                }
            }
            group("Number Series")
            {
                field("Expense User Nos."; Rec."Expense User Nos.")
                {
                }
                field("Expense Reports Nos."; Rec."Expense Reports Nos.")
                {
                }
                field("Posted Expense Reports Nos."; Rec."Posted Expense Reports Nos.")
                {
                }
                field("Expense Nos."; Rec."Expense Nos.")
                {
                }
                field("Expense Vendor Nos."; Rec."Expense Vendor Nos.")
                {
                }
            }
            group("Allowance")
            {
                field("Standard Rate of Mileage"; Rec."Standard Rate of Mileage")
                {
                }
                field("Full Per-Diem Calculation"; Rec."Full Per-Diem Calculation")
                {
                }
#if not CLEAN29
                field("Per Diem Rounding Precision"; Rec."Per Diem Rounding Precision")
                {
                    ObsoleteState = Pending;
                    ObsoleteTag = '29.0';
                    ObsoleteReason = 'This field is no longer required and will be removed in a future release.';
                }
#endif
                field("Minimum Hours for Per Diem"; Rec."Minimum Hours for Per Diem")
                {
                    Editable = (Rec."Full Per-Diem Calculation" = Rec."Full Per-Diem Calculation"::"24-hour Rolling Period") or (Rec."Full Per-Diem Calculation" = Rec."Full Per-Diem Calculation"::"Overnight Stay");
                }
                field("Partial Day Rules"; Rec."Partial Day Rules")
                {
                    Enabled = Rec."Full Per-Diem Calculation" <> Rec."Full Per-Diem Calculation"::None;
                }
                field("Min Hours for Partial Per Diem"; Rec."Min Hours for Partial Per Diem")
                {
                }
                field("Percentage For Partial Day"; Rec."Percentage For Partial Day")
                {
                }
                field("Reduction for Breakfast %"; Rec."Reduction for Breakfast %")
                {
                }
                field("Reduction for Lunch %"; Rec."Reduction for Lunch %")
                {
                }
                field("Reduction for Dinner %"; Rec."Reduction for Dinner %")
                {
                }
                field("Default Mileage UOM"; Rec."Default Mileage UOM")
                {
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        UnitOfMeasure: Record "Unit of Measure";
                        CreateExpenseAgentSetup: Codeunit "Create Expense Agent Setup";
                        UnitsOfMeasure: Page "Units of Measure";
                    begin
                        UnitOfMeasure.SetFilter("International Standard Code", CreateExpenseAgentSetup.GetMileageUOMStandardCodeFilter());
                        UnitsOfMeasure.SetTableView(UnitOfMeasure);
                        UnitsOfMeasure.LookupMode(true);
                        if UnitsOfMeasure.RunModal() <> Action::LookupOK then
                            exit(false);

                        UnitsOfMeasure.GetRecord(UnitOfMeasure);
                        Text := UnitOfMeasure.Code;
                        exit(true);
                    end;
                }
                field("Only Shortest Route"; Rec."Only Shortest Route")
                {
                }
            }
            part(AgentAccessControl; "Expense Agent Access Ctrl")
            {
                Caption = 'Agent Access Control';
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Setup)
            {
                Caption = 'Setup';
                action("Expense Categories")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expense Categories';
                    Image = Category;
                    RunObject = Page "Expense Categories";
                    ToolTip = 'Opens the page to set up expense categories.';
                }
                action("Expense Users")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expense Users';
                    Image = Employee;
                    RunObject = Page "Expense Users";
                    ToolTip = 'Opens the page to set up expense users.';
                }
                action("Expense Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expense Posting Groups';
                    Image = GeneralPostingSetup;
                    RunObject = Page "Expense Posting Groups";
                    ToolTip = 'Opens the page to set up expense posting groups.';
                }
                action("Expense VAT Posting Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expense VAT Posting Setup';
                    Image = VATPostingSetup;
                    RunObject = Page "VAT Posting Setup";
                    ToolTip = 'Opens the page to define reduced VAT rates for expense management.';
                }
                action("Mileage Rate Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Mileage Rate Setup';
                    Image = CalculateConsumption;
                    RunObject = Page "Mileage Rate Setup";
                    ToolTip = 'Opens the page to set up time-valid mileage rates that apply based on the transaction date.';
                }
                action("Apply Default Settings")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply default settings';
                    Image = SetupPayment;
                    ToolTip = 'Applies all default settings (number series, payment methods, posting groups, expense categories and subcategories, expense locations, and management rules) for the expense agent. Defaults that have already been applied are skipped.';
                    Enabled = not (Rec."No. Series Applied" and Rec."Posting Groups Applied" and Rec."Exp. Categories Applied" and Rec."Exp. Locations Applied" and Rec."Management Rules Applied");

                    trigger OnAction()
                    begin
                        Rec.CreateDefaultSettings();
                    end;
                }
            }
            action("Agent Consumption")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View agent consumption';
                Image = BankAccountLedger;
                RunObject = Page "EA Billing Overview";
                ToolTip = 'View consumption details for the Expense Agent.';
            }
        }

        area(Promoted)
        {
            actionref("Expense Users_Promoted"; "Expense Users")
            {
            }
            actionref("Expense Categories_Promoted"; "Expense Categories")
            {
            }
            actionref("Expense Posting Groups_Promoted"; "Expense Posting Groups")
            {
            }
            actionref("Expense VAT Posting Setup_Promoted"; "Expense VAT Posting Setup")
            {
            }
        }
    }

    trigger OnOpenPage()
    var
        AgentSystemPermissions: Codeunit "Agent System Permissions";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if not AgentSystemPermissions.CurrentUserHasCanManageAllAgentsPermission() then
            Error(NotAuthorizedToViewSetupErr);

        FeatureTelemetry.LogUptake('0000UBT', Rec.GetFeatureName(), Enum::"Feature Uptake Status"::Discovered);

        if not Rec.Get() then begin
            Rec.Insert(true);
            CurrPage.Update(false);
        end;

        ValidateSelectedMailboxExists();
        ValidateNoreplyMailboxExists();
    end;

    var
        NotAuthorizedToViewSetupErr: Label 'You do not have permission to view the Expense Agent setup. Contact your administrator to be granted agent management rights.';
        ActivatePolicyEvalQst: Label 'You are about to activate automated policy evaluation. By doing this, you acknowledge that this feature will consume additional AI credits. Continue?';

    local procedure ValidateSelectedMailboxExists()
    var
        EmailAccount: Record "Email Account";
        EmailAccountCU: Codeunit "Email Account";
    begin
        if IsNullGuid(Rec."Email Account ID") then
            exit;

        EmailAccountCU.GetAllAccounts(false, EmailAccount);
        EmailAccount.SetRange("Account Id", Rec."Email Account ID");
        EmailAccount.SetRange(Connector, Rec."Email Connector");
        if not EmailAccount.IsEmpty() then
            exit;

        Rec.ClearMailboxAndDependents();
        if Rec."Enable Agent" then
            Rec.Validate("Enable Agent", false);
        Rec.Modify();
    end;

    local procedure ScheduleAllTasks()
    var
        EAAgentScheduler: Codeunit "EA Agent Scheduler";
    begin
        if Rec."Enable Agent" then
            EAAgentScheduler.ScheduleAgent(Rec);
    end;

    local procedure ValidateNoreplyMailboxExists()
    var
        EmailAccount: Record "Email Account";
        EmailAccountCU: Codeunit "Email Account";
    begin
        if IsNullGuid(Rec."Noreply Email Account ID") then
            exit;

        EmailAccountCU.GetAllAccounts(false, EmailAccount);
        EmailAccount.SetRange("Account Id", Rec."Noreply Email Account ID");
        EmailAccount.SetRange(Connector, Rec."Noreply Email Connector");
        if not EmailAccount.IsEmpty() then
            exit;

        Rec."Noreply Email Address" := '';
        Clear(Rec."Noreply Email Account ID");
        Clear(Rec."Noreply Email Connector");
        Rec.Modify();
    end;
}