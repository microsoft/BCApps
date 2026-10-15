// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

page 3327 "PA Business Skills Demo Setup"
{
    PageType = Card;
    Caption = 'Business Skills Payables Agent Demo Setup';
    ApplicationArea = All;
    UsageCategory = Administration;
    AdditionalSearchTerms = 'Business Skills, Payables Agent, GB demo';
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'GB demo company setup';
                InstructionalText = 'Creates a controlled baseline and Business Skills policy setup for the four GB Payables Agent scenarios in CRONUS W1. Cleanup restores captured defaults and removes only unchanged, unused, unposted records created by this page.';

                field(CurrentCompany; CurrentCompanyName)
                {
                    Caption = 'Current Company';
                    ToolTip = 'Specifies the company in which setup or cleanup will run.';
                    Editable = false;
                }
                field(Status; StatusText)
                {
                    Caption = 'Status';
                    ToolTip = 'Specifies whether the GB demo setup is currently configured.';
                    Editable = false;
                    MultiLine = true;
                }
                field(HistoryInvoices; HistoryInvoiceStatusText)
                {
                    Caption = 'Scenario 4 History';
                    ToolTip = 'Specifies how many of the four unposted June through September comparison invoices are available.';
                    Editable = false;
                }
            }
            group(TestingTools)
            {
                Caption = 'Invoice testing tools';
                InstructionalText = 'Submit the eight packaged scenario PDFs as one batch. Stop all tasks from the Agent side panel before cleaning the submitted batch.';

                field(BatchCount; BatchCountText)
                {
                    Caption = 'Submitted Invoices';
                    ToolTip = 'Specifies how many of the eight scenario invoices were submitted.';
                    Editable = false;
                }
                field(BatchSubmittedAt; BatchSubmittedAt)
                {
                    Caption = 'Submitted At';
                    ToolTip = 'Specifies when the active demo invoice batch was submitted.';
                    Editable = false;
                }
                field(BatchTaskStatus; BatchTaskStatusText)
                {
                    Caption = 'Task Status';
                    ToolTip = 'Summarizes active, completed, stopped, and missing Agent Tasks in the submitted batch.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetupCompany)
            {
                Caption = 'Setup Company';
                ToolTip = 'Create the baseline mappings, policy-specific accounts and VAT groups, four unposted history invoices, and four Business Skill records required by the GB comparison demo.';
                Image = Setup;
                Enabled = not SetupConfigured and not UpgradeRequired;

                trigger OnAction()
                begin
                    DemoSetupMgt.SetupCompany();
                    RefreshStatus();
                    Message(SetupCompletedMsg);
                end;
            }
            action(UpgradeCompany)
            {
                Caption = 'Upgrade Company';
                ToolTip = 'Safely replace the previous GB demo setup with the expanded before-and-after comparison setup.';
                Image = Refresh;
                Enabled = UpgradeRequired;

                trigger OnAction()
                begin
                    DemoSetupMgt.UpgradeCompany();
                    RefreshStatus();
                    Message(UpgradeCompletedMsg);
                end;
            }
            action(RefreshBusinessSkills)
            {
                Caption = 'Refresh Business Skills';
                ToolTip = 'Replace the previous demo skills with the latest searchable titles, descriptions, and instructions after verifying that the existing skills were not edited.';
                Image = Refresh;
                Enabled = SetupConfigured and BusinessSkillsNeedRefresh;

                trigger OnAction()
                begin
                    DemoSetupMgt.RefreshBusinessSkills();
                    RefreshStatus();
                    Message(BusinessSkillsRefreshedMsg);
                end;
            }
            action(SubmitInvoices)
            {
                Caption = 'Submit Invoices';
                ToolTip = 'Create one Payables Agent task for each of the eight packaged GB scenario PDFs in the configured order.';
                Image = SendTo;
                Enabled = SetupConfigured and not BatchExists;

                trigger OnAction()
                begin
                    DemoBatchMgt.SubmitInvoices();
                    RefreshStatus();
                    Message(InvoicesSubmittedMsg);
                end;
            }
            action(CleanSubmittedInvoices)
            {
                Caption = 'Clean Submitted Invoices';
                ToolTip = 'Delete the exact stopped or completed demo tasks, E-Documents, PDF blobs, drafts, and unposted purchase invoices from the active batch.';
                Image = ClearLog;
                Enabled = BatchExists;

                trigger OnAction()
                begin
                    if not Confirm(CleanSubmittedInvoicesQst, false) then
                        exit;
                    DemoBatchMgt.CleanupSubmittedInvoices();
                    RefreshStatus();
                    Message(SubmittedInvoicesCleanedMsg);
                end;
            }
            action(CleanupCompany)
            {
                Caption = 'Clean Up';
                ToolTip = 'Restore captured defaults and remove only unchanged, unused, unposted records and exact Business Skill IDs created by setup.';
                Image = Delete;
                Enabled = SetupConfigured or UpgradeRequired;

                trigger OnAction()
                begin
                    if not Confirm(CleanupQst, false) then
                        exit;
                    DemoSetupMgt.CleanupCompany();
                    RefreshStatus();
                    Message(CleanupCompletedMsg);
                end;
            }
        }
        area(Promoted)
        {
            actionref(SetupCompanyPromoted; SetupCompany)
            {
            }
            actionref(UpgradeCompanyPromoted; UpgradeCompany)
            {
            }
            actionref(RefreshBusinessSkillsPromoted; RefreshBusinessSkills)
            {
            }
            actionref(SubmitInvoicesPromoted; SubmitInvoices)
            {
            }
            actionref(CleanSubmittedInvoicesPromoted; CleanSubmittedInvoices)
            {
            }
            actionref(CleanupCompanyPromoted; CleanupCompany)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        RefreshStatus();
    end;

    local procedure RefreshStatus()
    begin
        CurrentCompanyName := CompanyName();
        SetupConfigured := DemoSetupMgt.IsConfigured();
        UpgradeRequired := DemoSetupMgt.NeedsUpgrade();
        BusinessSkillsNeedRefresh := SetupConfigured and DemoSetupMgt.BusinessSkillsNeedRefresh();
        BatchExists := DemoBatchMgt.HasBatch();
        StatusText := DemoSetupMgt.GetStatusText();
        if not SetupConfigured then
            HistoryInvoiceStatusText := NotAvailableLbl
        else
            HistoryInvoiceStatusText := StrSubstNo(HistoryInvoiceStatusLbl, DemoSetupMgt.GetHistoryInvoiceCount());
        BatchCountText := DemoBatchMgt.GetBatchCountText();
        BatchSubmittedAt := DemoBatchMgt.GetBatchSubmittedAt();
        BatchTaskStatusText := DemoBatchMgt.GetTaskStatusText();
        CurrPage.Update(false);
    end;

    var
        DemoSetupMgt: Codeunit "PA Business Skills Demo Mgt.";
        DemoBatchMgt: Codeunit "PA Bus. Skills Demo Batch Mgt.";
        CurrentCompanyName: Text[30];
        StatusText: Text;
        HistoryInvoiceStatusText: Text;
        BatchCountText: Text;
        BatchTaskStatusText: Text;
        BatchSubmittedAt: DateTime;
        SetupConfigured: Boolean;
        UpgradeRequired: Boolean;
        BusinessSkillsNeedRefresh: Boolean;
        BatchExists: Boolean;
        SetupCompletedMsg: Label 'The GB Payables Agent comparison setup is ready.';
        UpgradeCompletedMsg: Label 'The GB Payables Agent demo was upgraded to the comparison setup.';
        CleanupCompletedMsg: Label 'The GB Payables Agent demo setup was removed and the captured vendor fields were restored.';
        BusinessSkillsRefreshedMsg: Label 'The four demo Business Skill records were refreshed with the latest retrieval and accounting guidance.';
        InvoicesSubmittedMsg: Label 'The eight GB scenario invoices were submitted to Payables Agent.';
        SubmittedInvoicesCleanedMsg: Label 'The submitted demo invoice batch was cleaned.';
        CleanSubmittedInvoicesQst: Label 'Clean the submitted demo invoice batch? All tracked tasks must already be stopped or completed, and generated purchase invoices must remain unposted.';
        CleanupQst: Label 'Clean up the GB Payables Agent demo setup? Cleanup stops without deleting anything if a demo record was edited, used, or posted.';
        NotAvailableLbl: Label 'Not available';
        HistoryInvoiceStatusLbl: Label '%1 of 4 unposted invoices available', Comment = '%1 = invoice count';
}
