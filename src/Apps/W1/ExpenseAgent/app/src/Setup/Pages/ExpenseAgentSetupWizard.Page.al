// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using System.Agents;
using System.AI;
using System.Email;
using System.Environment;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Telemetry;
using System.Utilities;
#pragma warning disable AS0031
#pragma warning disable AA0073
page 6991 "Expense Agent Setup Wizard"
{
    PageType = ConfigurationDialog;
    Extensible = false;
    ApplicationArea = Basic, Suite;
    IsPreview = true;
    Caption = 'Configure Expense Agent';
    InstructionalText = 'Choose how the agent handles employee travel expenses and receipt processing.';
    SourceTable = "Expense Agent Setup";
    SourceTableTemporary = true;
    RefreshOnActivate = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            part(AgentSetupPart; "Agent Setup Part")
            {
                ApplicationArea = All;
                UpdatePropagation = Both;
            }
            group(AccessAndSubmission)
            {
                Caption = 'Access and submission';
                InstructionalText = 'Choose how expenses reach the agent and who can work with it.';

                group(SubmissionChannels)
                {
                    Caption = 'Submission channels';

                    group(WebAppAccessSection)
                    {
                        Caption = 'Enable access via web';
                        field(EnableWebAppAccess; true)
                        {
                            ShowCaption = false;
                            ToolTip = 'Specifies whether registered users can submit and review expenses through the Expense app.';
                            Editable = false;
                        }
                        field(ExpenseDashboardLink; ExpenseDashboardLinkTxt)
                        {
                            ShowCaption = false;
                            Editable = false;
                            Visible = ShowExpenseDashboardLink;
                            ToolTip = 'Opens the Expense app in a new browser tab so registered users can submit and review their expenses.';

                            trigger OnDrillDown()
                            begin
                                if ExpenseDashboardUrl <> '' then
                                    Hyperlink(ExpenseDashboardUrl);
                            end;
                        }
                    }
                    group(EmailWithReceiptsSection)
                    {
                        Caption = 'Enable sending email with receipts';
                        field("Enable Email with Receipts"; Rec."Enable Email with Receipts")
                        {
                            ShowCaption = false;
                            ToolTip = 'Specifies whether the agent reads its mailbox and processes incoming emails containing expense receipts. Receipts are only processed when a mailbox is configured.';

                            trigger OnValidate()
                            begin
                                EnableMailboxChanged := true;
                                ConfigUpdated();
                            end;
                        }
                        group(ReceiveMailGroup)
                        {
                            ShowCaption = false;
                            Enabled = Rec."Enable Email with Receipts";

                            field(Mailbox; Rec."Email Address")
                            {
                                Caption = 'Account';
                                ToolTip = 'Specifies the email account that the agent uses for receipts and notifications. You need permission to the mailbox to activate the agent.';
                                Editable = false;
                                ShowMandatory = true;

                                trigger OnAssistEdit()
                                begin
                                    OnAssistEditMailbox();
                                end;

                                trigger OnValidate()
                                begin
                                    ConfigUpdated();
                                end;
                            }
                        }
                    }
                }
                group(AccessControlGroup)
                {
                    Caption = 'Who can access';
                    group(Users)
                    {
                        ShowCaption = false;
                        field(UsersCtrl; Rec.GetRegisteredUsersText())
                        {
                            Caption = 'Submit expenses';
                            ToolTip = 'Specifies who can submit expenses. Click assist-edit to change who has access.';
                            Editable = false;

                            trigger OnAssistEdit()
                            var
                                CreateExpenseNoSeries: Codeunit "Create Expense No. Series";
                            begin
                                CreateExpenseNoSeries.InsertExpenseUserNoSeries();
                                Commit();
                                Page.RunModal(Page::"Expense Users");
                                ConfigUpdated();
                                CurrPage.Update(false);
                            end;
                        }
                        field(DefaultApprover; Rec."Default Approver Name")
                        {
                            DrillDown = false;

                            trigger OnAssistEdit()
                            var
                                ExpenseUser: Record "Expense User";
                                ExpenseUsers: Page "Expense Users";
                            begin
                                if ExpenseUser.IsEmpty() then
                                    Error(NoExpenseUsersErr);
                                ExpenseUser."No." := Rec."Default Approver No.";
                                if ExpenseUser."No." <> '' then
                                    ExpenseUsers.SetRecord(ExpenseUser);
                                ExpenseUser.SetFilter("E-mail", '<>%1', '');
                                ExpenseUser.SetRange("Is a System User", true);
                                ExpenseUsers.SetTableView(ExpenseUser);
                                if ExpenseUser.IsEmpty then
                                    Error(NoSystemUsersErr);
                                ExpenseUsers.LookupMode(true);
                                if ExpenseUsers.RunModal() = Action::LookupOK then begin
                                    ExpenseUsers.GetRecord(ExpenseUser);
                                    if ExpenseUser."No." <> Rec."Default Approver No." then begin
                                        if not ExpenseUser."Can Approve" then begin
                                            ExpenseUser.ReadIsolation(IsolationLevel::UpdLock);
                                            ExpenseUser.Get(ExpenseUser."No.");
                                            ExpenseUser.Validate("Can Approve", true);
                                            ExpenseUser.Modify();
                                            Commit(); // because we ask a question in the validate trigger later
                                        end;
                                        Rec.Validate("Default Approver No.", ExpenseUser."No.");
                                        ConfigUpdated();
                                        CurrPage.Update(true);
                                    end;
                                end;
                            end;
                        }
                    }
                }
            }
            group(AccountingDefaultsGroup)
            {
                Caption = 'Use accounting defaults';
                InstructionalText = 'Apply default ledger settings for expense processing. Once applied, added data must be updated manually if changes are needed.';

                group(NumberSeriesSection)
                {
                    Caption = 'Number series';

                    field(ApplyNoSeries; ApplyNoSeries)
                    {
                        ShowCaption = false;
                        ToolTip = 'Specifies whether to create the default number series for expenses, expense users, expense reports, and posted expense reports when you save the setup. Once applied, this option is disabled.';
                        Enabled = not NoSeriesLocked;

                        trigger OnValidate()
                        begin
                            ConfigUpdated();
                        end;
                    }
                    field(NoSeriesLink; NoSeriesLinkTxt)
                    {
                        ShowCaption = false;
                        Editable = false;
                        Visible = not NoSeriesLocked;
                        ToolTip = 'Specifies a link that previews the default number series that will be created.';

                        trigger OnDrillDown()
                        var
                            ExpNoSeriesPreview: Page "Exp. No. Series Preview";
                        begin
                            ExpNoSeriesPreview.RunModal();
                        end;
                    }
                    field(NoSeriesAppliedLink; NoSeriesAppliedLinkTxt)
                    {
                        ShowCaption = false;
                        Editable = false;
                        Visible = NoSeriesLocked;
                        ToolTip = 'Specifies a link that opens the existing expense-related number series.';

                        trigger OnDrillDown()
                        var
                            NoSeries: Record "No. Series";
                            CreateExpenseNoSeries: Codeunit "Create Expense No. Series";
                            NoSeriesList: Page "No. Series";
                        begin
                            NoSeries.SetFilter(Code, CreateExpenseNoSeries.GetExpenseNoSeriesFilter());
                            NoSeriesList.SetTableView(NoSeries);
                            NoSeriesList.Editable(false);
                            NoSeriesList.RunModal();
                        end;
                    }
                }
                group(PaymentMethodsSection)
                {
                    Caption = 'Payment methods';

                    field(ApplyPaymentMethods; ApplyPaymentMethods)
                    {
                        ShowCaption = false;
                        ToolTip = 'Specifies whether to create the default expense payment methods like Card, Cash and Bank when you save the setup. Once applied, this option is disabled.';
                        Enabled = not PaymentMethodsLocked;

                        trigger OnValidate()
                        begin
                            ConfigUpdated();
                        end;
                    }
                    field(PaymentMethodsLink; PaymentMethodsLinkTxt)
                    {
                        ShowCaption = false;
                        Editable = false;
                        Visible = not PaymentMethodsLocked;
                        ToolTip = 'Specifies a link that previews the default expense payment methods that will be created.';

                        trigger OnDrillDown()
                        var
                            ExpPaymentMethodsPreview: Page "Exp. Payment Methods Preview";
                        begin
                            ExpPaymentMethodsPreview.RunModal();
                        end;
                    }
                    field(PaymentMethodsAppliedLink; PaymentMethodsAppliedLinkTxt)
                    {
                        ShowCaption = false;
                        Editable = false;
                        Visible = PaymentMethodsLocked;
                        ToolTip = 'Specifies a link that opens the existing expense payment methods list.';

                        trigger OnDrillDown()
                        var
                            ExpensePaymentMethods: Page "Expense Payment Methods";
                        begin
                            ExpensePaymentMethods.Editable(false);
                            ExpensePaymentMethods.RunModal();
                        end;
                    }
                }
                group(PostingGroupsSection)
                {
                    Caption = 'Expense posting groups';

                    field(ApplyPostingGroups; ApplyPostingGroups)
                    {
                        ShowCaption = false;
                        ToolTip = 'Specifies whether to create the default expense posting groups (including the employee posting group) and starter values for mileage and per diem when you save the setup. Once applied, this option is disabled.';
                        Enabled = not PostingGroupsLocked;

                        trigger OnValidate()
                        begin
                            if not ApplyPostingGroups then
                                IncludeExpCategories := false;
                            ConfigUpdated();
                            CurrPage.Update(false);
                        end;
                    }
                    field(PostingGroupsLink; PostingGroupsLinkTxt)
                    {
                        ShowCaption = false;
                        Editable = false;
                        Visible = not PostingGroupsLocked;
                        ToolTip = 'Specifies a link that previews the default expense posting groups that will be created.';

                        trigger OnDrillDown()
                        var
                            ExpPostingGroupsPreview: Page "Exp. Posting Groups Preview";
                        begin
                            ExpPostingGroupsPreview.RunModal();
                        end;
                    }
                    field(PostingGroupsAppliedLink; PostingGroupsAppliedLinkTxt)
                    {
                        ShowCaption = false;
                        Editable = false;
                        Visible = PostingGroupsLocked;
                        ToolTip = 'Specifies a link that opens the existing expense posting groups list.';

                        trigger OnDrillDown()
                        var
                            ExpensePostingGroups: Page "Expense Posting Groups";
                        begin
                            ExpensePostingGroups.Editable(false);
                            ExpensePostingGroups.RunModal();
                        end;
                    }
                    group(ExpenseCategoriesSection)
                    {
                        Caption = 'Include expense categories';
                        field(IncludeExpCategories; IncludeExpCategories)
                        {
                            Caption = 'Include default expense categories and subcategories';
                            ShowCaption = false;
                            ToolTip = 'Specifies whether to create the default expense categories and subcategories when you save the setup. Categories require expense posting groups. Once applied, this option is disabled.';
                            Enabled = (not ExpCategoriesLocked) and (ApplyPostingGroups or not PostingGroupsLocked);

                            trigger OnValidate()
                            begin
                                if IncludeExpCategories and not ApplyPostingGroups and not PostingGroupsLocked then
                                    ApplyPostingGroups := true;
                                ConfigUpdated();
                                CurrPage.Update(false);
                            end;
                        }
                        field(CategoriesLink; CategoriesLinkTxt)
                        {
                            ShowCaption = false;
                            Editable = false;
                            Visible = not ExpCategoriesLocked;
                            ToolTip = 'Specifies a link that previews the default expense categories and subcategories that will be created along with existing ones.';

                            trigger OnDrillDown()
                            var
                                ExpCategoriesPreview: Page "Exp. Categories Preview";
                            begin
                                ExpCategoriesPreview.RunModal();
                            end;
                        }
                        field(CategoriesAppliedLink; CategoriesAppliedLinkTxt)
                        {
                            ShowCaption = false;
                            Editable = false;
                            Visible = ExpCategoriesLocked;
                            ToolTip = 'Specifies a link that opens the existing expense categories list.';

                            trigger OnDrillDown()
                            var
                                ExpenseCategories: Page "Expense Categories";
                            begin
                                ExpenseCategories.Editable(false);
                                ExpenseCategories.RunModal();
                            end;
                        }
                    }
                }
            }
            group(ManagementDefaultsGroup)
            {
                Caption = 'Use management defaults';
                InstructionalText = 'Apply default location-based policies and management rules that govern expense approval. Once applied, added data must be updated manually if changes are needed.';

                group(LocationsSection)
                {
                    Caption = 'Expense locations';

                    field(ApplyExpLocations; ApplyExpLocations)
                    {
                        ShowCaption = false;
                        ToolTip = 'Specifies whether to create the default expense locations when you save the setup. Once applied, this option is disabled.';
                        Enabled = not ExpLocationsLocked;

                        trigger OnValidate()
                        begin
                            if not ApplyExpLocations then
                                IncludeManagementRules := false;
                            ConfigUpdated();
                            CurrPage.Update(false);
                        end;
                    }
                    field(LocationsLink; LocationsLinkTxt)
                    {
                        ShowCaption = false;
                        Editable = false;
                        Visible = not ExpLocationsLocked;
                        ToolTip = 'Specifies a link that previews the default expense locations that will be created.';

                        trigger OnDrillDown()
                        var
                            ExpLocationsPreview: Page "Exp. Locations Preview";
                        begin
                            ExpLocationsPreview.RunModal();
                        end;
                    }
                    field(LocationsAppliedLink; LocationsAppliedLinkTxt)
                    {
                        ShowCaption = false;
                        Editable = false;
                        Visible = ExpLocationsLocked;
                        ToolTip = 'Specifies a link that opens the existing expense locations list.';

                        trigger OnDrillDown()
                        var
                            ExpenseLocations: Page "Expense Locations";
                        begin
                            ExpenseLocations.Editable(false);
                            ExpenseLocations.RunModal();
                        end;
                    }
                    group(ManagementRulesSection)
                    {
                        Caption = 'Include management rules';
                        field(IncludeManagementRules; IncludeManagementRules)
                        {
                            Caption = 'Include default management rules';
                            ShowCaption = false;
                            ToolTip = 'Specifies whether to create the default management rules when you save the setup. Management rules require expense locations. Once applied, this option is disabled.';
                            Enabled = (not ManagementRulesLocked) and (ApplyExpLocations or not ExpLocationsLocked);

                            trigger OnValidate()
                            begin
                                if IncludeManagementRules and not ApplyExpLocations and not ExpLocationsLocked then
                                    ApplyExpLocations := true;
                                ConfigUpdated();
                                CurrPage.Update(false);
                            end;
                        }
                        field(RulesLink; RulesLinkTxt)
                        {
                            ShowCaption = false;
                            Editable = false;
                            Visible = not ManagementRulesLocked;
                            ToolTip = 'Specifies a link that previews the default management rules and their conditions that will be created along with existing ones.';

                            trigger OnDrillDown()
                            var
                                ExpRulesPreview: Page "Exp. Rules Preview";
                            begin
                                ExpRulesPreview.RunModal();
                            end;
                        }
                        field(RulesAppliedLink; RulesAppliedLinkTxt)
                        {
                            ShowCaption = false;
                            Editable = false;
                            Visible = ManagementRulesLocked;
                            ToolTip = 'Specifies a link that opens the existing expense management rules list.';

                            trigger OnDrillDown()
                            var
                                ExpenseManagementRules: Page "Expense Management Rules";
                            begin
                                ExpenseManagementRules.Editable(false);
                                ExpenseManagementRules.RunModal();
                            end;
                        }
                    }
                }
            }
            group(RulesAndControls)
            {
                Caption = 'Rules and controls';

                group(RulesSection)
                {
                    Caption = 'Enforce management rules';
                    InstructionalText = 'Activates the expense policies defined under Management Rules, such as per diem rates and maximum amounts.';
                    field("Use Rules"; Rec."Use Rules")
                    {
                        ShowCaption = false;

                        ToolTip = 'Specifies whether configured expense management rules are applied when expenses are processed.';

                        trigger OnValidate()
                        begin
                            ConfigUpdated();
                        end;
                    }
                }
                group(DetectOutdatedExpenseSection)
                {
                    ShowCaption = false;
                    Visible = false;

                    field("Do Not Allow Exp. Older Than"; Rec."Do Not Allow Exp. Older Than")
                    {
                        Caption = 'Allowed max. age (days)';
                        ToolTip = 'Specifies a date formula; expenses older than the resulting date are not allowed.';

                        trigger OnValidate()
                        begin
                            ConfigUpdated();
                        end;
                    }
                    field("If Exp. Is Older Than Allowed"; Rec."If Exp. Is Older Than Allowed")
                    {
                        Caption = 'When age exceeded';
                        ToolTip = 'Specifies how the system handles expenses older than the allowed date: warn, require justification, or block submission.';

                        trigger OnValidate()
                        begin
                            ConfigUpdated();
                        end;
                    }
                }
                group(AntiCorruptionSection)
                {
                    Caption = 'Display anti-corruption attestation';
                    InstructionalText = 'Require users to confirm an anti-corruption attestation before submitting expenses.';
                    field("Enable Anti-Corp. Statement"; Rec."Enable Anti-Corp. Statement")
                    {
                        ShowCaption = false;
                        ToolTip = 'Specifies whether users must confirm an anti-corruption attestation before submitting expenses.';

                        trigger OnValidate()
                        begin
                            ConfigUpdated();
                        end;
                    }
                }
                group(ExpenseReportingRulesSection)
                {
                    Caption = 'Expense reporting';
                    InstructionalText = 'Configure how transactions are grouped into expense reports, and which expense details are required when users submit them.';

                    field("Receipt No. Mandatory"; Rec."Receipt No. Mandatory")
                    {
                        Caption = 'Require receipt number';
                        ToolTip = 'Specifies whether a receipt number is mandatory for expenses.';

                        trigger OnValidate()
                        begin
                            ConfigUpdated();
                        end;
                    }
                    field("Merchant Name Mandatory"; Rec."Merchant Name Mandatory")
                    {
                        Caption = 'Require merchant name';
                        ToolTip = 'Specifies whether a merchant name is mandatory for expenses.';

                        trigger OnValidate()
                        begin
                            ConfigUpdated();
                        end;
                    }
                }

            }
            group(EvaluatePoliciesTab)
            {
                Caption = 'Policy compliance';

                group(EvaluatePoliciesSection)
                {
                    Caption = 'Evaluate compliance with AI';
                    InstructionalText = 'Use AI to evaluate compliance according to organization guidelines.';
                    field("Evaluate Policies"; Rec."Evaluate Policies")
                    {
                        ShowCaption = false;
                        ToolTip = 'Specifies whether the agent evaluates expenses against the configured policies. Rules are evaluated by code, while policies are evaluated by AI, so enabling this consumes additional AI credits.';

                        trigger OnValidate()
                        begin
                            if Rec."Evaluate Policies" and (not xRec."Evaluate Policies") then
                                if not Confirm(ActivatePolicyEvalQst, false) then
                                    Error('');
                            ConfigUpdated();
                        end;
                    }
                    field(ExpensePoliciesLink; ExpensePoliciesLinkTxt)
                    {
                        ShowCaption = false;
                        Editable = false;
                        ToolTip = 'Specifies a link that opens the expense policies.';

                        trigger OnDrillDown()
                        var
                            ExpensePoliciesPage: Page "Expense Policies";
                        begin
                            ExpensePoliciesPage.Editable(true);
                            ExpensePoliciesPage.RunModal();
                        end;
                    }
                    group(SubmitterRunEvaluationSection)
                    {
                        Caption = 'Enable pre-submission evaluation';
                        InstructionalText = 'Let submitters run a compliance evaluation of the expense reports.';
                        Enabled = Rec."Evaluate Policies";

                        field("Submitter-run Evaluation"; Rec."Submitter-run Evaluation")
                        {
                            ShowCaption = false;
                            ToolTip = 'Specifies whether submitters can run an AI evaluation to check expense reports for compliance before submitting them.';

                            trigger OnValidate()
                            begin
                                ConfigUpdated();
                            end;
                        }
                    }
                }
            }
            group(CommunicationGroup)
            {
                Caption = 'Communication';
                InstructionalText = 'Define how users are notified about unsubmitted expenses, approval events and welcome emails.';

                field("Enable Communication"; Rec."Enable Communication")
                {
                    ShowCaption = false;
                    ToolTip = 'Specifies whether the agent sends outgoing emails to users: welcome emails, reimbursement notifications, approval updates, and unsubmitted-report reminders. Turn this off to stop all outgoing emails.';

                    trigger OnValidate()
                    begin
                        EnableMailboxChanged := true;
                        ConfigUpdated();
                    end;
                }

                group(SendMailGroup)
                {
                    Caption = 'Send mail';
                    Enabled = Rec."Enable Communication";

                    field("Noreply Email Address"; Rec."Noreply Email Address")
                    {
                        Caption = 'Account';
                        ToolTip = 'Specifies the email account used for all outgoing Expense Agent messages: welcome emails to new expense users, pending-approval requests sent to approvers, approved/rejected notifications sent to submitters, reimbursement notifications, and the optional open report reminders. This account is required for outgoing emails.';
                        Editable = false;
                        ShowMandatory = true;

                        trigger OnAssistEdit()
                        begin
                            OnAssistEditNoreplyMailbox();
                        end;
                    }
                }
                group(OpenReportNotifGroup)
                {
                    Caption = 'Notify users about unsubmitted reports';
                    Enabled = Rec."Enable Communication";

                    field("Enable Open Report Notif."; Rec."Enable Open Report Notif.")
                    {
                        ShowCaption = false;
                        ToolTip = 'Specifies whether the system sends periodic notifications for open expense reports. Notifications are only sent when an email account is configured.';

                        trigger OnValidate()
                        begin
                            EnableMailboxChanged := true;
                            ConfigUpdated();
                        end;
                    }
                    field("Open Report Notif. Freq."; Rec."Open Report Notif. Freq.")
                    {
                        Caption = 'Notification frequency';
                        ToolTip = 'Specifies how often the system should send notifications for open expense reports.';
                        Enabled = Rec."Enable Open Report Notif.";

                        trigger OnValidate()
                        begin
                            ConfigUpdated();
                        end;
                    }
                }
                group(ApprovalNotifGroup)
                {
                    Caption = 'Notify users about approval updates';
                    InstructionalText = 'Sent when reports are submitted, approved, and rejected.';
                    Enabled = Rec."Enable Communication";

                    field("Enable Approval Notif."; Rec."Enable Approval Notif.")
                    {
                        ShowCaption = false;
                        ToolTip = 'Specifies whether the system sends email notifications when expense reports are submitted, approved, or rejected.';

                        trigger OnValidate()
                        begin
                            ConfigUpdated();
                        end;
                    }
                }
            }

            group(MileageExpensesGroup)
            {
                Caption = 'Mileage expenses';
                InstructionalText = 'Let users log travel distances on expense reports and calculate reimbursement.';

                field("Standard Rate of Mileage"; Rec."Standard Rate of Mileage")
                {
                    Caption = 'Rate per unit';
                    ToolTip = 'Specifies the reimbursement amount per unit of distance used to calculate mileage expenses.';

                    trigger OnValidate()
                    begin
                        ConfigUpdated();
                    end;
                }
                field("Default Mileage UOM"; Rec."Default Mileage UOM")
                {
                    Caption = 'Default unit of distance';
                    ToolTip = 'Specifies the default unit of measure used when recording mileage, such as miles or kilometers.';
                    Lookup = false;

                    trigger OnAssistEdit()
                    var
                        UnitOfMeasure: Record "Unit of Measure";
                        CreateExpenseAgentSetup: Codeunit "Create Expense Agent Setup";
                        UnitsOfMeasure: Page "Units of Measure";
                    begin
                        UnitOfMeasure.SetFilter("International Standard Code", CreateExpenseAgentSetup.GetMileageUOMStandardCodeFilter());
                        UnitsOfMeasure.SetTableView(UnitOfMeasure);
                        UnitsOfMeasure.LookupMode(true);
                        if UnitsOfMeasure.RunModal() = Action::LookupOK then begin
                            UnitsOfMeasure.GetRecord(UnitOfMeasure);
                            Rec."Default Mileage UOM" := UnitOfMeasure.Code;
                            ConfigUpdated();
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        ConfigUpdated();
                    end;
                }
                field(MileageRateSetupLink; MileageRateSetupLinkTxt)
                {
                    ShowCaption = false;
                    Editable = false;
                    ToolTip = 'Specifies where to configure mileage rates by vehicle type.';

                    trigger OnDrillDown()
                    var
                        MileageRateSetup: Page "Mileage Rate Setup";
                    begin
                        MileageRateSetup.RunModal();
                    end;
                }
            }
            group(ProjectGroup)
            {
                Caption = 'Project tracking';
                InstructionalText = 'Allow submitters to associate expenses with projects and project tasks defined in Business Central.';

                field("Enable Project Fields"; Rec."Enable Project Fields")
                {
                    ShowCaption = false;

                    trigger OnValidate()
                    begin
                        ConfigUpdated();
                    end;
                }
                field("Project Visibility"; Rec."Project Visibility")
                {
                    Enabled = Rec."Enable Project Fields";

                    trigger OnValidate()
                    begin
                        ConfigUpdated();
                    end;
                }
            }
            group(PerDiemExpensesGroup)
            {
                Caption = 'Per diem expenses';
                InstructionalText = 'Allow users to claim daily allowances for meals, lodging, and incidentals when traveling for work.';

                field("Full Per-Diem Calculation"; Rec."Full Per-Diem Calculation")
                {
                    Caption = 'Per diem calculation';
                    ToolTip = 'Specifies the rule used to calculate full per diem, for example by calendar day or by hours.';

                    trigger OnValidate()
                    begin
                        ConfigUpdated();
                        RefreshPerDiemSummaries();
                    end;
                }
                field("Minimum Hours for Per Diem"; Rec."Minimum Hours for Per Diem")
                {
                    Caption = 'Minimum hours';
                    ToolTip = 'Specifies the minimum number of hours required to qualify for per diem.';
                    Enabled = (Rec."Full Per-Diem Calculation" = Rec."Full Per-Diem Calculation"::"24-hour Rolling Period") or (Rec."Full Per-Diem Calculation" = Rec."Full Per-Diem Calculation"::"Overnight Stay");

                    trigger OnValidate()
                    begin
                        ConfigUpdated();
                    end;
                }
                group(PartialDaySection)
                {
                    Caption = 'Partial day';
                    InstructionalText = 'Adjust percentage values applied to partial days and meal-specific reductions.';

                    field(PartialDayRuleSummary; PartialDayRuleSummary)
                    {
                        Caption = 'Rule';
                        ToolTip = 'Specifies how per diem for partial days is determined. Use the assist edit to change the rule.';
                        Editable = false;
                        Enabled = PartialDayRuleEnabled;

                        trigger OnAssistEdit()
                        begin
                            EditPerDiemPartialSettings();
                        end;
                    }
                    field(MealReductionsSummary; MealReductionsSummary)
                    {
                        Caption = 'Meal reductions (%)';
                        ToolTip = 'Specifies the percentages deducted from the per diem when breakfast, lunch, or dinner is provided. Use the assist edit to change the values.';
                        Editable = false;
                        Enabled = PartialDayRuleEnabled;

                        trigger OnAssistEdit()
                        begin
                            EditPerDiemPartialSettings();
                        end;
                    }
                }
            }
            group(CanaryGroup)
            {
                Caption = 'Canary';
                InstructionalText = 'Route this environment''s Expense Agent service calls through the canary endpoint.';
                Visible = CanaryToggleVisible;

                field(UseCanaryEndpoint; UseCanaryEndpoint)
                {
                    Caption = 'Canary';
                    ShowCaption = false;
                    ToolTip = 'Specifies whether Expense Agent service calls from this environment are routed to the canary endpoint.';

                    trigger OnValidate()
                    begin
                        // Changing the endpoint only takes effect for service calls after this point; it does not automatically re-register the ERP configuration.
                        Rec."Use Canary Endpoint" := UseCanaryEndpoint;
                        Rec.Modify();
                        ConfigUpdated();
                    end;
                }
            }
        }
    }

    actions
    {
        area(SystemActions)
        {
            systemaction(OK)
            {
                Caption = 'Update';
                Enabled = IsConfigUpdated;
                ToolTip = 'Apply the changes to the agent setup.';
            }
            systemaction(Cancel)
            {
                Caption = 'Cancel';
                ToolTip = 'Discards the changes and closes the setup page.';
            }
        }
    }

    trigger OnOpenPage()
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AgentSystemPermissions: Codeunit "Agent System Permissions";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        EAHttpClient: Codeunit "EA Http Client";
        AgentUserSecurityID: Guid;
    begin
        if not AgentSystemPermissions.CurrentUserHasCanManageAllAgentsPermission() then
            Error(NotAuthorizedToViewSetupErr);
        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Expense Agent") then
            Error(CapabilityDisabledErr, Enum::"Copilot Capability"::"Expense Agent");

        FeatureTelemetry.LogUptake('0000UBU', Rec.GetFeatureName(), Enum::"Feature Uptake Status"::Discovered);

        IsConfigUpdated := false;
        LoadSetup();
        ExpenseDashboardUrl := GetExpenseDashboardUrl();
        ShowExpenseDashboardLink := ExpenseDashboardUrl <> '';
        CanaryToggleVisible := Rec."Use Canary Endpoint" or EAHttpClient.IsTenantOnCanaryAllowlist();

        AgentUserSecurityID := ResolveAgentUserSecurityID();
        CurrPage.AgentSetupPart.Page.Initialize(AgentUserSecurityID, "Agent Metadata Provider"::"Expense Agent", AgentUserName(), AgentDisplayNameLbl, AgentSummaryLbl);
        UpdateAgentSetupBuffer();

        InitialState := AgentSetupBuffer.State;
        UpdateControls();
    end;

    trigger OnAfterGetCurrRecord()
    var
        CreateExpenseAgentSetup: Codeunit "Create Expense Agent Setup";
    begin
        UpdateAgentSetupBuffer();
        IsConfigUpdated := IsConfigUpdated or AgentSetup.GetChangesMade(AgentSetupBuffer);
        EnableSendingEmailWithReceipts := EnableSendingEmailWithReceipts or (Rec."Email Address" <> '');
        if Rec."Default Mileage UOM" = '' then
            Rec."Default Mileage UOM" := CreateExpenseAgentSetup.GetDefaultMileageUOM();
        RefreshPerDiemSummaries();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = CloseAction::Cancel then
            exit(true);

        if not ValidateManagementRulesDependencies() then
            exit(false);

        UpdateAgentSetupBuffer();

        if AgentBeingEnabled() then
            if not ConfirmMissingAccountWarnings() then
                exit(false);

        VerifySchedulingMailboxAccess();

        if AgentBeingEnabled() and StateChanged() then
            if not ActivateAgent() then
                exit(false);

        if AgentBeingDisabled() and StateChanged() then
            if not DeactivateAgent() then
                exit(false);

        PersistAgentState();
        ApplyScheduleChange();

        exit(true);
    end;

    var
        AgentSetupBuffer: Record "Agent Setup Buffer";
        AgentSetup: Codeunit "Agent Setup";
        InitialState: Option;
        EnableMailboxChanged: Boolean;
        IsConfigUpdated: Boolean;
        EnableSendingEmailWithReceipts: Boolean;
        PaymentMethodsLocked: Boolean;
        PostingGroupsLocked: Boolean;
        ExpCategoriesLocked: Boolean;
        ExpLocationsLocked: Boolean;
        ManagementRulesLocked: Boolean;
        NoSeriesLocked: Boolean;
        ApplyPaymentMethods: Boolean;
        ApplyPostingGroups: Boolean;
        IncludeExpCategories: Boolean;
        ApplyExpLocations: Boolean;
        IncludeManagementRules: Boolean;
        ApplyNoSeries: Boolean;
        ShowExpenseDashboardLink: Boolean;
        ExpenseDashboardUrl: Text;
        PartialDayRuleSummary: Text;
        MealReductionsSummary: Text;
        PartialDayRuleEnabled: Boolean;
        UseCanaryEndpoint: Boolean;
        CanaryToggleVisible: Boolean;
        PaymentMethodsLinkTxt: Label 'Preview the default payment methods that will be added';
        PaymentMethodsAppliedLinkTxt: Label 'View payment methods including new defaults';
        PostingGroupsLinkTxt: Label 'Preview the default expense posting groups that will be added';
        PostingGroupsAppliedLinkTxt: Label 'View expense posting groups including new defaults';
        CategoriesLinkTxt: Label 'Preview the default expense categories that will be added';
        CategoriesAppliedLinkTxt: Label 'View expense categories including new defaults';
        LocationsLinkTxt: Label 'Preview the default expense locations that will be added';
        LocationsAppliedLinkTxt: Label 'View expense locations including new defaults';
        RulesLinkTxt: Label 'Preview the default management rules that will be added';
        RulesAppliedLinkTxt: Label 'View management rules including new defaults';
        ExpensePoliciesLinkTxt: Label 'View expense policies';
        NoSeriesLinkTxt: Label 'Preview the default number series that will be added';
        NoSeriesAppliedLinkTxt: Label 'View number series including new defaults';
        MileageRateSetupLinkTxt: Label 'Configure mileage rates by vehicle type';
        ExpenseDashboardLinkTxt: Label 'Go to Expense app (opens in new window)';
        ExpenseDashboardUrlOnPremTxt: Label 'http://localhost:5173/', Locked = true;
        ExpenseDashboardUrlProdTxt: Label 'https://go.microsoft.com/fwlink/?LinkId=2365219', Locked = true;
        ExpenseDashboardUrlTieTxt: Label 'https://go.microsoft.com/fwlink/?LinkId=2365220', Locked = true;
        CapabilityDisabledQst: Label 'The "%1" capability is disabled in the "%2" page. The Agent will not work unless you enable the capability.\\Do you want to open the "%2" page now?', Comment = '%1=A copilot capability such as Expense Agent; %2=A page caption, such as Copilot & Agent Capabilities.';
        CapabilityDisabledErr: Label 'You must enable the "%1" capability to use the Agent.', Comment = '%1=A copilot capability such as Expense Agent.';
        NoMailboxWarningQst: Label 'Email submission is turned on, but no mailbox is configured. The agent will not process emailed receipts until you configure a mailbox for this submission channel. Do you want to continue?';
        NoNoreplyWarningQst: Label 'Communication is turned on, but no account is configured under send mail. The agent will not send welcome or notification emails until you set the send mail account. Do you want to continue?';
        IncludeCategoriesForRulesQst: Label 'Default management rules require default expense categories. Do you want to add them to the configuration?';
        IncludeCategoriesAndPostingGroupsForRulesQst: Label 'Default management rules require default expense categories and posting groups. Do you want to add them to the configuration?';
        PrivacyNoticeNotAcceptedMsg: Label 'To use the Expense Agent, you must first accept the privacy notice. Please accept the privacy notice and try again.';
        ExpenseAgentPermissionSetLbl: Label 'Expense Agent', Locked = true;
        NoExpenseUsersErr: Label 'You must first specify who can access.';
        NoSystemUsersErr: Label 'You must first specify a user in Business Central as expense user.';
        NotAuthorizedToViewSetupErr: Label 'You do not have permission to view the Expense Agent setup. Contact your administrator to be granted agent management rights.';
        ApprovalWorkflowConflictErr: Label 'You must turn off "%1" in Expense Agent Setup to enable Expense Agent.', Comment = '%1 = Field Caption';
        ActivatePolicyEvalQst: Label 'You are about to activate automated policy evaluation. By doing this, you acknowledge that this feature will consume additional AI credits. Continue?';
        AgentUserNameLbl: Label 'Expense Agent', Locked = true;
        AgentDisplayNameLbl: Label 'Expense Agent', MaxLength = 80;
        AgentSummaryLbl: Label 'Processes employee expense reports by extracting receipt data, validating against company policies, and routing for approval.';

    local procedure LoadSetup()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        IsFirstTimeSetup: Boolean;
    begin
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Insert(true);
            IsFirstTimeSetup := true;
        end else
            IsFirstTimeSetup := IsNullGuid(ExpenseAgentSetup."User Security ID");

        Rec := ExpenseAgentSetup;
        Rec.Insert();
        PaymentMethodsLocked := Rec."Payment Methods Applied";
        PostingGroupsLocked := Rec."Posting Groups Applied";
        ExpCategoriesLocked := Rec."Exp. Categories Applied";
        ExpLocationsLocked := Rec."Exp. Locations Applied";
        ManagementRulesLocked := Rec."Management Rules Applied";
        NoSeriesLocked := Rec."No. Series Applied";
        ApplyPaymentMethods := Rec."Payment Methods Applied";
        ApplyPostingGroups := Rec."Posting Groups Applied";
        IncludeExpCategories := Rec."Exp. Categories Applied";
        ApplyExpLocations := Rec."Exp. Locations Applied";
        IncludeManagementRules := Rec."Management Rules Applied";
        ApplyNoSeries := Rec."No. Series Applied";
        UseCanaryEndpoint := Rec."Use Canary Endpoint";

        if IsFirstTimeSetup then begin
            Rec."Enable Email with Receipts" := true;
            Rec."Enable Communication" := true;
            Rec."Use Rules" := true;
            ApplyAccountingDefaultsSelection(true);
            ApplyManagementDefaultsSelection(true);
            Rec.Modify();
        end;
    end;

    local procedure ApplyAccountingDefaultsSelection(IsEnabled: Boolean)
    begin
        if IsEnabled then begin
            if not NoSeriesLocked then
                ApplyNoSeries := IsNoSeriesDataEmpty();
            if not PaymentMethodsLocked then
                ApplyPaymentMethods := IsPaymentMethodsDataEmpty();
            if not PostingGroupsLocked then
                ApplyPostingGroups := IsPostingGroupsDataEmpty();
            if not ExpCategoriesLocked then begin
                IncludeExpCategories := IsExpenseCategoriesDataEmpty();
                if IncludeExpCategories and not PostingGroupsLocked and IsPostingGroupsDataEmpty() then
                    ApplyPostingGroups := true;
            end;
            exit;
        end;

        if not NoSeriesLocked then
            ApplyNoSeries := false;
        if not PaymentMethodsLocked then
            ApplyPaymentMethods := false;
        if not PostingGroupsLocked then
            ApplyPostingGroups := false;
        if not ExpCategoriesLocked then
            IncludeExpCategories := false;
    end;

    local procedure ApplyManagementDefaultsSelection(IsEnabled: Boolean)
    begin
        if IsEnabled then begin
            if not ExpLocationsLocked then
                ApplyExpLocations := IsExpenseLocationsDataEmpty();
            if not ManagementRulesLocked then begin
                IncludeManagementRules := IsManagementRulesDataEmpty();
                if IncludeManagementRules and not ExpLocationsLocked and IsExpenseLocationsDataEmpty() then
                    ApplyExpLocations := true;
                if IncludeManagementRules then
                    Rec."Use Rules" := true;
            end;
            exit;
        end;

        if not ExpLocationsLocked then
            ApplyExpLocations := false;
        if not ManagementRulesLocked then
            IncludeManagementRules := false;
    end;

    local procedure IsNoSeriesDataEmpty(): Boolean
    var
        NoSeries: Record "No. Series";
        CreateExpenseNoSeries: Codeunit "Create Expense No. Series";
    begin
        NoSeries.SetFilter(Code, CreateExpenseNoSeries.GetExpenseNoSeriesFilter());
        exit(NoSeries.IsEmpty());
    end;

    local procedure IsPaymentMethodsDataEmpty(): Boolean
    var
        ExpensePaymentMethod: Record "Expense Payment Method";
    begin
        exit(ExpensePaymentMethod.IsEmpty());
    end;

    local procedure IsPostingGroupsDataEmpty(): Boolean
    var
        ExpensePostingGroup: Record "Expense Posting Group";
    begin
        exit(ExpensePostingGroup.IsEmpty());
    end;

    local procedure IsExpenseCategoriesDataEmpty(): Boolean
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseSubcategory: Record "Expense Subcategory";
    begin
        exit(ExpenseCategory.IsEmpty() and ExpenseSubcategory.IsEmpty());
    end;

    local procedure IsExpenseLocationsDataEmpty(): Boolean
    var
        ExpenseLocation: Record "Expense Location";
    begin
        exit(ExpenseLocation.IsEmpty());
    end;

    local procedure IsManagementRulesDataEmpty(): Boolean
    var
        ExpenseRuleHeader: Record "Expense Rule Header";
    begin
        exit(ExpenseRuleHeader.IsEmpty());
    end;

    local procedure SaveSetup()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        if not ExpenseAgentSetup.Get() then
            ExpenseAgentSetup.Insert(true);
        ExpenseAgentSetup.TransferFields(Rec, false);
        if not IsNullGuid(AgentSetupBuffer."User Security ID") then
            ExpenseAgentSetup."User Security ID" := AgentSetupBuffer."User Security ID";
        ExpenseAgentSetup.Modify(true);
    end;

    local procedure ResolveAgentUserSecurityID(): Guid
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        Agent: Record Agent;
        AgentUserSecurityID: Guid;
    begin
        if ExpenseAgentSetup.Get() then
            AgentUserSecurityID := ExpenseAgentSetup."User Security ID";

        if not IsNullGuid(AgentUserSecurityID) then
            if Agent.Get(AgentUserSecurityID) then
                exit(AgentUserSecurityID);

        // The per-company Setup pointer is missing or stale, but the Agent table is
        // system-wide and this company may already have an agent (e.g. the pointer was
        // lost, or a concurrent setup created one). Recover it so a save reuses that
        // agent instead of provisioning a duplicate.
        exit(FindCompanyAgentUserSecurityID());
    end;

    local procedure FindCompanyAgentUserSecurityID(): Guid
    var
        Agent: Record Agent;
        TempUserSettings: Record "User Settings" temporary;
        AgentCU: Codeunit Agent;
    begin
        // Only reuse the agent this company provisioned; the agent's originating company
        // is stored in its user settings, never another company's Expense Agent.
        Agent.SetRange("Agent Metadata Provider", "Agent Metadata Provider"::"Expense Agent");
        if Agent.FindSet() then
            repeat
                Clear(TempUserSettings);
                AgentCU.GetUserSettings(Agent."User Security ID", TempUserSettings);
                if TempUserSettings.Company = CopyStr(CompanyName(), 1, MaxStrLen(TempUserSettings.Company)) then
                    exit(Agent."User Security ID");
            until Agent.Next() = 0;
    end;

    local procedure AgentUserName(): Code[50]
    begin
        exit(CopyStr(AgentUserNameLbl + ' - ' + CompanyName(), 1, 50));
    end;

    local procedure ValidateManagementRulesDependencies(): Boolean
    var
        NeedsPostingGroups: Boolean;
        ConfirmQst: Text;
    begin
        if not IncludeManagementRules then
            exit(true);
        if ExpCategoriesLocked or IncludeExpCategories then
            exit(true);

        NeedsPostingGroups := (not PostingGroupsLocked) and (not ApplyPostingGroups);
        if NeedsPostingGroups then
            ConfirmQst := IncludeCategoriesAndPostingGroupsForRulesQst
        else
            ConfirmQst := IncludeCategoriesForRulesQst;

        if not Confirm(ConfirmQst, true) then
            exit(false);

        IncludeExpCategories := true;
        if NeedsPostingGroups then
            ApplyPostingGroups := true;
        ConfigUpdated();
        CurrPage.Update(false);
        exit(true);
    end;

    local procedure ApplyDefaultsIfRequested()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        if not ExpenseAgentSetup.Get() then
            exit;

        if ApplyNoSeries and not NoSeriesLocked then
            ExpenseAgentSetup.CreateNoSeriesDefaults();

        if ApplyPaymentMethods and not PaymentMethodsLocked then
            ExpenseAgentSetup.CreatePaymentMethodsDefaults();

        if ApplyPostingGroups and not PostingGroupsLocked then
            ExpenseAgentSetup.CreatePostingGroupsDefaults();

        if IncludeExpCategories and not ExpCategoriesLocked then
            ExpenseAgentSetup.CreateExpenseCategoriesDefaults();

        if ApplyExpLocations and not ExpLocationsLocked then
            ExpenseAgentSetup.CreateExpenseLocationsDefaults();

        if IncludeManagementRules and not ManagementRulesLocked then
            ExpenseAgentSetup.CreateManagementRulesDefaults();
    end;

    local procedure UpdateAgentSetupBuffer()
    begin
        CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(AgentSetupBuffer);
    end;

    local procedure EditPerDiemPartialSettings()
    var
        TempExpenseAgentSetup: Record "Expense Agent Setup" temporary;
        PerDiemPartialSettings: Page "Exp. Per Diem Partial Settings";
    begin
        PerDiemPartialSettings.Set(Rec);
        PerDiemPartialSettings.Editable := true;
        if PerDiemPartialSettings.RunModal() <> Action::OK then
            exit;

        PerDiemPartialSettings.Get(TempExpenseAgentSetup);
        Rec."Partial Day Rules" := TempExpenseAgentSetup."Partial Day Rules";
        Rec."Min Hours for Partial Per Diem" := TempExpenseAgentSetup."Min Hours for Partial Per Diem";
        Rec."Percentage For Partial Day" := TempExpenseAgentSetup."Percentage For Partial Day";
        Rec."Reduction for Breakfast %" := TempExpenseAgentSetup."Reduction for Breakfast %";
        Rec."Reduction for Lunch %" := TempExpenseAgentSetup."Reduction for Lunch %";
        Rec."Reduction for Dinner %" := TempExpenseAgentSetup."Reduction for Dinner %";
        Rec.Modify();
        ConfigUpdated();
        RefreshPerDiemSummaries();
    end;

    local procedure RefreshPerDiemSummaries()
    begin
        PartialDayRuleSummary := GetPartialDayRuleSummary();
        MealReductionsSummary := GetMealReductionsSummary();
        PartialDayRuleEnabled := Rec."Full Per-Diem Calculation" <> Rec."Full Per-Diem Calculation"::None;
    end;

    local procedure GetPartialDayRuleSummary(): Text
    var
        FlatRateSummaryLbl: Label 'Flat %1% of full rate', Comment = '%1 = percentage';
        EligibleHoursSummaryLbl: Label 'Min. %1 hours, %2% of eligible hours', Comment = '%1 = minimum hours, %2 = percentage';
        NotApplicableLbl: Label 'Not applicable';
    begin
        if Rec."Full Per-Diem Calculation" = Rec."Full Per-Diem Calculation"::None then
            exit(NotApplicableLbl);

        case Rec."Partial Day Rules" of
            Rec."Partial Day Rules"::"Flat Percentage Of Full Rate":
                exit(StrSubstNo(FlatRateSummaryLbl, FormatPercentage(Rec."Percentage For Partial Day")));
            Rec."Partial Day Rules"::"Based On Eligible Hours":
                exit(StrSubstNo(EligibleHoursSummaryLbl, FormatHours(Rec."Min Hours for Partial Per Diem"), FormatPercentage(Rec."Percentage For Partial Day")));
        end;
        exit('');
    end;

    local procedure GetMealReductionsSummary(): Text
    var
        MealReductionsLbl: Label '%1, %2, %3', Comment = '%1 = breakfast %, %2 = lunch %, %3 = dinner %';
        NotApplicableLbl: Label 'Not applicable';
    begin
        if Rec."Full Per-Diem Calculation" = Rec."Full Per-Diem Calculation"::None then
            exit(NotApplicableLbl);

        exit(StrSubstNo(MealReductionsLbl,
            FormatPercentage(Rec."Reduction for Breakfast %"),
            FormatPercentage(Rec."Reduction for Lunch %"),
            FormatPercentage(Rec."Reduction for Dinner %")));
    end;

    local procedure FormatPercentage(Value: Decimal): Text
    begin
        exit(Format(Value, 0, '<Precision,2:2><Standard Format,0>'));
    end;

    local procedure FormatHours(Value: Decimal): Text
    begin
        exit(Format(Value, 0, '<Precision,0:2><Standard Format,0>'));
    end;

    local procedure UpdateControls()
    begin
        ValidateSelectedMailboxExists();
    end;

    local procedure ConfigUpdated()
    begin
        IsConfigUpdated := true;
    end;

    local procedure StateChanged(): Boolean
    begin
        exit(AgentSetupBuffer.State <> InitialState);
    end;

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
        EAAgentScheduler.ScheduleAgent(Rec);
    end;

    local procedure CancelAllTasks()
    var
        EAAgentScheduler: Codeunit "EA Agent Scheduler";
    begin
        EAAgentScheduler.RemoveAgentTasks();
    end;

    local procedure ValidatePrivacyNoticeApproval()
    var
        ExpPrivacyNoticeReg: Codeunit "Exp. Privacy Notice Reg.";
    begin
        if ExpPrivacyNoticeReg.IsPrivacyNoticeApproved() then
            exit;

        if not ExpPrivacyNoticeReg.ConfirmPrivacyNoticeApproval() then
            Error(PrivacyNoticeNotAcceptedMsg);
    end;

    local procedure ConfirmMissingAccountWarnings(): Boolean
    begin
        // Inbound: receipts on but no mailbox configured -> warn.
        if Rec."Enable Email with Receipts" and IsNullGuid(Rec."Email Account ID") then
            if not Confirm(NoMailboxWarningQst, false) then
                exit(false);

        // Outbound: communication on but no no-reply account configured -> warn.
        if Rec."Enable Communication" and IsNullGuid(Rec."Noreply Email Account ID") then
            if not Confirm(NoNoreplyWarningQst, false) then
                exit(false);

        exit(true);
    end;

    local procedure AgentBeingEnabled(): Boolean
    begin
        exit(AgentSetupBuffer.State = AgentSetupBuffer.State::Enabled);
    end;

    local procedure AgentBeingDisabled(): Boolean
    begin
        exit(AgentSetupBuffer.State = AgentSetupBuffer.State::Disabled);
    end;

    local procedure ScheduleAffectingChange(): Boolean
    begin
        exit(StateChanged() or EnableMailboxChanged);
    end;

    local procedure VerifySchedulingMailboxAccess()
    begin
        // The scheduled task runs under the current user, so confirm mailbox access before we
        // (re)schedule. Runs before any DB write, while the transaction is still clean, because
        // the mailbox probe uses Codeunit.Run (which cannot start once the DB has been written).
        if ScheduleAffectingChange() and Rec.ShouldScheduleAgentTask(AgentBeingEnabled()) then
            Rec.CheckSchedulingMailboxAccessOrError();
    end;

    local procedure ActivateAgent(): Boolean
    begin
        ValidatePrivacyNoticeApproval();
        ValidateCapabilityIsEnabled();

        if Rec."Enable Approval Workflow" then
            Error(ApprovalWorkflowConflictErr, Rec.FieldCaption("Enable Approval Workflow"));

        EnsureCurrentUserHasAccess();
        EnableAadApplication();
        Commit();
        if not RegisterErpConfiguration() then
            exit(false);
        Rec.LogAgentEnabledTelemetry();
        exit(true);
    end;

    local procedure DeactivateAgent(): Boolean
    begin
        if not Rec.ShowDeactivationAccessWarning() then
            exit(false);
        if not UnregisterErpConfiguration() then
            exit(false);
        Rec.LogAgentDisabledTelemetry();
        exit(true);
    end;

    local procedure PersistAgentState()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        Rec."Enable Agent" := AgentBeingEnabled();

        // Serialize concurrent wizard saves: take an update lock on the per-company setup and
        // re-resolve the agent so a second save reuses the agent the first committed rather than
        // creating a duplicate through the platform CreateAgent branch.
        ExpenseAgentSetup.ReadIsolation := IsolationLevel::UpdLock;
        if ExpenseAgentSetup.Get() then;
        if IsNullGuid(AgentSetupBuffer."User Security ID") then
            AgentSetupBuffer."User Security ID" := ResolveAgentUserSecurityID();

        AgentSetup.SaveChanges(AgentSetupBuffer);
        SaveSetup();
        ApplyDefaultsIfRequested();
    end;

    local procedure ApplyScheduleChange()
    begin
        if not ScheduleAffectingChange() then
            exit;
        if Rec.ShouldScheduleAgentTask(AgentBeingEnabled()) then
            ScheduleAllTasks()
        else
            CancelAllTasks();
    end;

    local procedure EnsureCurrentUserHasAccess()
    var
        ExpenseAgentAccessControl: Record "Expense Agent Access Control";
    begin
        ExpenseAgentAccessControl.SetRange("User Security ID", UserSecurityId());
        if not ExpenseAgentAccessControl.IsEmpty() then
            exit;

        ExpenseAgentAccessControl.Init();
        ExpenseAgentAccessControl."User Security ID" := UserSecurityId();
        ExpenseAgentAccessControl."Can Configure Agent" := true;
        ExpenseAgentAccessControl.Validate("Can Work on Behalf", true);
        ExpenseAgentAccessControl.Insert(true);
    end;

    local procedure ValidateCapabilityIsEnabled()
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        CopilotAiCapabilities: Page "Copilot AI Capabilities";
    begin
        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Expense Agent", true) then
            if Confirm(CapabilityDisabledQst, false, Enum::"Copilot Capability"::"Expense Agent", CopilotAiCapabilities.Caption) then
                if CopilotAiCapabilities.RunModal() in [Action::OK] then;

        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Expense Agent", true) then
            Error(CapabilityDisabledErr, Enum::"Copilot Capability"::"Expense Agent");
    end;

    local procedure EnableAadApplication()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentApiValidation: Codeunit "Expense Agent API Validation";
    begin
        AadApplication.SetRange("Client Id", ExpenseAgentApiValidation.GetAadAppId());
        if not AadApplication.FindFirst() then
            exit;

        // We need to enable the AAD application first because enabling creates the user record.
        // Once the user exists, we disable it, add the permission set, and re-enable it.
        if AadApplication.State <> AadApplication.State::Enabled then begin
            AadApplication.Validate(State, AadApplication.State::Enabled);
            AadApplication.Modify(true);
        end;

        if HasExpenseAgentPermissionSet(AadApplication) then
            exit;

        AadApplication.Validate(State, AadApplication.State::Disabled);
        AadApplication.Modify(true);

        AddExpenseAgentPermissionSet(AadApplication);

        AadApplication.Validate(State, AadApplication.State::Enabled);
        AadApplication.Modify(true);
    end;

    local procedure HasExpenseAgentPermissionSet(AadApplication: Record "AAD Application"): Boolean
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", AadApplication."User ID");
        AccessControl.SetRange("Role ID", ExpenseAgentPermissionSetLbl);
        exit(not AccessControl.IsEmpty());
    end;

    local procedure AddExpenseAgentPermissionSet(AadApplication: Record "AAD Application")
    var
        AccessControl: Record "Access Control";
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        AggregatePermissionSet.SetRange("Role ID", ExpenseAgentPermissionSetLbl);
        if not AggregatePermissionSet.FindFirst() then
            exit;

        AccessControl.Init();
        AccessControl.Validate("User Security ID", AadApplication."User ID");
        AccessControl.Validate("Role ID", ExpenseAgentPermissionSetLbl);
        AccessControl.Validate("App ID", AggregatePermissionSet."App ID");
        AccessControl.Validate("Company Name", CompanyName());
        AccessControl.Insert(true);
    end;

    local procedure OnAssistEditMailbox()
    var
        PrevEmailAddress: Text[250];
    begin
        PrevEmailAddress := Rec."Email Address";
        Rec.AssistEditMailbox();
        if Rec."Email Address" <> PrevEmailAddress then begin
            EnableMailboxChanged := true;
            ConfigUpdated();
        end;
    end;

    local procedure OnAssistEditNoreplyMailbox()
    var
        PrevNoreplyAddress: Text[250];
    begin
        PrevNoreplyAddress := Rec."Noreply Email Address";
        Rec.AssistEditNoreplyMailbox();
        if Rec."Noreply Email Address" <> PrevNoreplyAddress then begin
            EnableMailboxChanged := true;
            ConfigUpdated();
        end;
    end;

    local procedure RegisterErpConfiguration(): Boolean
    var
        EAHttpClient: Codeunit "EA Http Client";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        // The Agent service is only reachable on SaaS. Skip ERP registration when running locally to allow testing of the agent without requiring the service.
        if not EnvironmentInfo.IsSaaSInfrastructure() then
            exit(true);
        exit(EAHttpClient.RegisterErpConfiguration());
    end;

    local procedure UnregisterErpConfiguration(): Boolean
    var
        EAHttpClient: Codeunit "EA Http Client";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if not EnvironmentInfo.IsSaaSInfrastructure() then
            exit(true);
        exit(EAHttpClient.UnregisterErpConfiguration());
    end;

    local procedure GetExpenseDashboardUrl(): Text
    var
        EnvironmentInfo: Codeunit "Environment Information";
        URLHelper: Codeunit "URL Helper";
    begin
        if EnvironmentInfo.IsOnPrem() then
            exit(ExpenseDashboardUrlOnPremTxt);

        if not EnvironmentInfo.IsSaaSInfrastructure() then
            exit('');

        if URLHelper.IsTIE() or URLHelper.IsPPE() then
            exit(ExpenseDashboardUrlTieTxt);

        if EnvironmentInfo.IsSaaSInfrastructure() then
            exit(ExpenseDashboardUrlProdTxt);

        exit('');
    end;
}
#pragma warning restore AS0031
