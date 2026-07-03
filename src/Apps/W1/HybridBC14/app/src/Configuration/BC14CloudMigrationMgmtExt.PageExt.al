// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.DataMigration;

pageextension 46870 "BC14 Cloud Migration Mgmt Ext" extends "Cloud Migration Management"
{
    layout
    {
        modify(CompaniesStatusText)
        {
            Caption = 'Companies Replication status';
        }
        addlast(OveralInformation)
        {
            field(BC14CompanyUpgradeStatus; CompanyUpgradeStatusText)
            {
                ApplicationArea = All;
                Caption = 'Companies Upgrade status';
                ToolTip = 'Specifies the upgrade-phase status summary for all companies (separate from the replication-phase Companies Replication status above). Format: Pending: X, Started: Y, Completed: Z, Failed: W. Drill down to see per-company status.';
                Editable = false;
                Visible = BC14MigrationEnabled;
                Style = Attention;
                StyleExpr = HasFailedCompanies;

                trigger OnDrillDown()
                begin
                    Page.RunModal(Page::"BC14 Company Upgrade Status");
                end;
            }
            field(BC14UpgradeErrorDetails; UpgradeErrorDetailsText)
            {
                ApplicationArea = All;
                Caption = 'Upgrade Error Details';
                ToolTip = 'Specifies the accumulated error messages and call stacks captured for failed companies during the Business Central 14 upgrade.';
                Editable = false;
                MultiLine = true;
                Visible = BC14MigrationEnabled and HasUpgradeErrorDetails;
                Style = Unfavorable;
                StyleExpr = HasUpgradeErrorDetails;
            }
        }
    }

    actions
    {
        modify(RunDataUpgrade)
        {
            Visible = not BC14MigrationEnabled or not BC14UpgradeStarted;
        }

        addlast(Processing)
        {
            action(BC14MigrationSettings)
            {
                ApplicationArea = All;
                Caption = 'Configure BC14 Re-implementation';
                ToolTip = 'Configure default re-implementation settings (modules, posting, error handling). Per-company overrides, upgrade timing, and re-implementation errors are reachable from inside.';
                Image = Setup;
                Enabled = BC14MigrationEnabled;

                trigger OnAction()
                begin
                    Page.Run(Page::"BC14 Migration Configuration");
                end;
            }
            action(BC14MigrationErrors)
            {
                ApplicationArea = All;
                Caption = 'BC14 Migration Errors';
                ToolTip = 'View the BC14 migration errors collected across all companies and migrators.';
                Image = ErrorLog;
                Enabled = BC14MigrationEnabled;
                RunObject = page "BC14 Migration Error Overview";
            }
            action(ResumeBC14Upgrade)
            {
                ApplicationArea = All;
                Caption = 'Resume Business Central 14 Upgrade';
                ToolTip = 'Continue the Business Central 14 upgrade after a failure or interruption. If any company is Pending, the next one is dispatched. If only Failed companies remain, you are prompted to reset them to Pending and retry.';
                Image = Continue;
                Visible = BC14MigrationEnabled and BC14UpgradeStarted;
                Enabled = BC14HasPendingUpgradeWork or BC14HasFailedUpgradeWork;

                trigger OnAction()
                begin
                    ResumeBC14UpgradeAction();
                end;
            }
        }

        addlast(Category_Process)
        {
            actionref(BC14MigrationSettings_Promoted; BC14MigrationSettings)
            {
            }
            actionref(BC14MigrationErrors_Promoted; BC14MigrationErrors)
            {
            }
            actionref(ResumeBC14Upgrade_Promoted; ResumeBC14Upgrade)
            {
            }
        }
    }

    trigger OnOpenPage()
    var
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        BC14MigrationEnabled := BC14Wizard.GetBC14MigrationEnabled();
        if BC14MigrationEnabled then begin
            UpdateCompanyUpgradeStatus();
            UpdateUpgradeProgressFlags();
        end;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if BC14MigrationEnabled then begin
            UpdateCompanyUpgradeStatus();
            UpdateUpgradeErrorDetails();
            UpdateUpgradeProgressFlags();
        end;
    end;

    local procedure UpdateCompanyUpgradeStatus()
    var
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
        PendingCount: Integer;
        StartedCount: Integer;
        CompletedCount: Integer;
        FailedCount: Integer;
        Parts: List of [Text];
    begin
        BC14StatusMgr.GetCompanyStatusCounts(PendingCount, StartedCount, CompletedCount, FailedCount);

        HasFailedCompanies := FailedCount > 0;

        if PendingCount > 0 then
            Parts.Add(StrSubstNo(PendingLbl, PendingCount));
        if StartedCount > 0 then
            Parts.Add(StrSubstNo(StartedLbl, StartedCount));
        if CompletedCount > 0 then
            Parts.Add(StrSubstNo(CompletedLbl, CompletedCount));
        if FailedCount > 0 then
            Parts.Add(StrSubstNo(FailedLbl, FailedCount));

        CompanyUpgradeStatusText := JoinText(Parts, ', ');
        if CompanyUpgradeStatusText = '' then
            CompanyUpgradeStatusText := NoCompaniesLbl;
    end;

    local procedure UpdateUpgradeProgressFlags()
    var
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
        PendingCount: Integer;
        StartedCount: Integer;
        CompletedCount: Integer;
        FailedCount: Integer;
    begin
        BC14UpgradeStarted := false;
        BC14HasPendingUpgradeWork := false;
        BC14HasFailedUpgradeWork := false;

        if BC14GlobalSettings.Get() then
            BC14UpgradeStarted := BC14GlobalSettings."Data Upgrade Started" <> 0DT;

        BC14StatusMgr.GetCompanyStatusCounts(PendingCount, StartedCount, CompletedCount, FailedCount);
        BC14HasPendingUpgradeWork := PendingCount > 0;
        BC14HasFailedUpgradeWork := FailedCount > 0;
    end;

    local procedure ResumeBC14UpgradeAction()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
        PendingCount: Integer;
        StartedCount: Integer;
        CompletedCount: Integer;
        FailedCount: Integer;
    begin
        if not BC14MigrationOrchestrator.FindLatestReplicationSummary(HybridReplicationSummary) then
            Error(NoReplicationSummaryToResumeErr);

        BC14StatusMgr.GetCompanyStatusCounts(PendingCount, StartedCount, CompletedCount, FailedCount);

        if (PendingCount = 0) and (FailedCount = 0) then
            Error(NothingToResumeErr);

        if FailedCount > 0 then begin
            if not Confirm(StrSubstNo(ResetFailedQst, FailedCount), false) then
                exit;
            RerunFailedCompanies();
        end;

        if PendingCount > 0 then begin
            if (FailedCount = 0) and (not Confirm(ResumeUpgradeQst, false)) then
                exit;
            BC14MigrationOrchestrator.DispatchNextReadyCompany(HybridReplicationSummary);
        end;

        UpdateCompanyUpgradeStatus();
        UpdateUpgradeProgressFlags();
        UpdateUpgradeErrorDetails();
        CurrPage.Update(false);

        Message(ResumeUpgradeScheduledMsg);
    end;

    local procedure RerunFailedCompanies()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
        FailedCompanyNames: List of [Text[30]];
        CompanyNameText: Text[30];
    begin
        BC14StatusMgr.FilterFailedCompanies(HybridCompanyStatus);
        if HybridCompanyStatus.FindSet() then
            repeat
                FailedCompanyNames.Add(CopyStr(HybridCompanyStatus.Name, 1, 30));
            until HybridCompanyStatus.Next() = 0;

        foreach CompanyNameText in FailedCompanyNames do
            BC14MigrationRunner.ContinueMigrationForCompany(CompanyNameText);
    end;

    local procedure JoinText(Parts: List of [Text]; Separator: Text): Text
    var
        Part: Text;
        Result: Text;
    begin
        foreach Part in Parts do begin
            if Result <> '' then
                Result += Separator;
            Result += Part;
        end;
        exit(Result);
    end;

    local procedure UpdateUpgradeErrorDetails()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
        DetailsInStream: InStream;
        DetailsText: Text;
    begin
        UpgradeErrorDetailsText := '';
        HasUpgradeErrorDetails := false;

        if not BC14MigrationOrchestrator.FindLatestReplicationSummary(HybridReplicationSummary) then
            exit;
        if HybridReplicationSummary.Status <> HybridReplicationSummary.Status::UpgradeFailed then
            exit;

        HybridReplicationSummary.CalcFields(Details);
        if not HybridReplicationSummary.Details.HasValue() then
            exit;

        HybridReplicationSummary.Details.CreateInStream(DetailsInStream);
        DetailsInStream.Read(DetailsText);
        if DetailsText = '' then
            exit;

        UpgradeErrorDetailsText := DetailsText;
        HasUpgradeErrorDetails := true;
    end;

    var
        BC14MigrationEnabled: Boolean;
        BC14UpgradeStarted: Boolean;
        BC14HasPendingUpgradeWork: Boolean;
        BC14HasFailedUpgradeWork: Boolean;
        HasFailedCompanies: Boolean;
        HasUpgradeErrorDetails: Boolean;
        CompanyUpgradeStatusText: Text;
        UpgradeErrorDetailsText: Text;
        PendingLbl: Label 'Pending: %1', Comment = '%1 = Count';
        StartedLbl: Label 'Started: %1', Comment = '%1 = Count';
        CompletedLbl: Label 'Completed: %1', Comment = '%1 = Count';
        FailedLbl: Label 'Failed: %1', Comment = '%1 = Count';
        NoCompaniesLbl: Label 'No companies';
        NoReplicationSummaryToResumeErr: Label 'No replication summary was found to resume the upgrade from.';
        NothingToResumeErr: Label 'There are no Pending or Failed companies to resume.';
        ResumeUpgradeQst: Label 'Resume the Business Central 14 upgrade and dispatch the next Pending company?';
        ResetFailedQst: Label 'No Pending companies remain. Reset %1 Failed companies to Pending and resume the upgrade?', Comment = '%1 = Count';
        ResumeUpgradeScheduledMsg: Label 'The Business Central 14 upgrade has been resumed. The next Pending company will start shortly.';
}