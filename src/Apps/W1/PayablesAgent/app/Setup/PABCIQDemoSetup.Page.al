// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

page 3327 "PA BC IQ Demo Setup"
{
    PageType = Card;
    Caption = 'BC IQ Payables Agent Demo Setup';
    ApplicationArea = All;
    UsageCategory = Administration;
    AdditionalSearchTerms = 'Business Central IQ, Payables Agent, GB demo';
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'GB demo company setup';
                InstructionalText = 'Creates a controlled baseline and BC IQ policy setup for the four GB Payables Agent scenarios in CRONUS W1. Cleanup restores captured defaults and removes only unchanged, unused, unposted records created by this page.';

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
                field(BusinessCentralIQMode; BusinessCentralIQModeText)
                {
                    Caption = 'Payables Agent BC IQ Mode';
                    ToolTip = 'Specifies whether Payables Agent currently uses Business Central IQ skills.';
                    Editable = false;
                }
                field(HistoryInvoices; HistoryInvoiceStatusText)
                {
                    Caption = 'Scenario 4 History';
                    ToolTip = 'Specifies how many of the four unposted June through September comparison invoices are available.';
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
                ToolTip = 'Create the baseline mappings, policy-specific accounts and VAT groups, four unposted history invoices, and four Business Central IQ skills required by the GB comparison demo.';
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
            action(EnableBusinessCentralIQ)
            {
                Caption = 'Enable BC IQ';
                ToolTip = 'Let Payables Agent use the four active Business Central IQ skills for the policy comparison run.';
                Image = Approve;
                Enabled = SetupConfigured and not BusinessCentralIQEnabled;

                trigger OnAction()
                begin
                    DemoSetupMgt.SetBusinessCentralIQEnabled(true);
                    RefreshStatus();
                    Message(BusinessCentralIQEnabledMsg);
                end;
            }
            action(DisableBusinessCentralIQ)
            {
                Caption = 'Disable BC IQ';
                ToolTip = 'Run Payables Agent using standard mappings and defaults without applying Business Central IQ skills.';
                Image = Cancel;
                Enabled = SetupConfigured and BusinessCentralIQEnabled;

                trigger OnAction()
                begin
                    DemoSetupMgt.SetBusinessCentralIQEnabled(false);
                    RefreshStatus();
                    Message(BusinessCentralIQDisabledMsg);
                end;
            }
            action(CleanupCompany)
            {
                Caption = 'Clean Up';
                ToolTip = 'Restore captured defaults and remove only unchanged, unused, unposted records and exact Business Central IQ skill IDs created by setup.';
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
            actionref(EnableBusinessCentralIQPromoted; EnableBusinessCentralIQ)
            {
            }
            actionref(DisableBusinessCentralIQPromoted; DisableBusinessCentralIQ)
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
        BusinessCentralIQEnabled := SetupConfigured and DemoSetupMgt.IsBusinessCentralIQEnabled();
        StatusText := DemoSetupMgt.GetStatusText();
        if not SetupConfigured then begin
            BusinessCentralIQModeText := NotAvailableLbl;
            HistoryInvoiceStatusText := NotAvailableLbl;
        end else begin
            if BusinessCentralIQEnabled then
                BusinessCentralIQModeText := EnabledLbl
            else
                BusinessCentralIQModeText := DisabledLbl;
            HistoryInvoiceStatusText := StrSubstNo(HistoryInvoiceStatusLbl, DemoSetupMgt.GetHistoryInvoiceCount());
        end;
        CurrPage.Update(false);
    end;

    var
        DemoSetupMgt: Codeunit "PA BC IQ Demo Mgt.";
        CurrentCompanyName: Text[30];
        StatusText: Text;
        BusinessCentralIQModeText: Text;
        HistoryInvoiceStatusText: Text;
        SetupConfigured: Boolean;
        UpgradeRequired: Boolean;
        BusinessCentralIQEnabled: Boolean;
        SetupCompletedMsg: Label 'The GB Payables Agent comparison setup is ready with Business Central IQ disabled.';
        UpgradeCompletedMsg: Label 'The GB Payables Agent demo was upgraded to the comparison setup with Business Central IQ disabled.';
        CleanupCompletedMsg: Label 'The GB Payables Agent demo setup was removed and the captured vendor fields were restored.';
        BusinessCentralIQEnabledMsg: Label 'Business Central IQ is enabled for new Payables Agent tasks.';
        BusinessCentralIQDisabledMsg: Label 'Business Central IQ is disabled for new Payables Agent tasks.';
        CleanupQst: Label 'Clean up the GB Payables Agent demo setup? Cleanup stops without deleting anything if a demo record was edited, used, or posted.';
        EnabledLbl: Label 'Enabled - run policy comparison tasks';
        DisabledLbl: Label 'Disabled - run baseline tasks';
        NotAvailableLbl: Label 'Not available';
        HistoryInvoiceStatusLbl: Label '%1 of 4 unposted invoices available', Comment = '%1 = invoice count';
}
