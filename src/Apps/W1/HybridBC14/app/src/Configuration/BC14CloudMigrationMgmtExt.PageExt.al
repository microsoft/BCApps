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
        addlast(Processing)
        {
            action(BC14MigrationSettings)
            {
                ApplicationArea = All;
                Caption = 'Configure Business Central 14 Migration';
                ToolTip = 'Configure default migration settings (modules, posting, error handling). Per-company overrides, upgrade timing, and migration errors are reachable from inside.';
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
        }

        addlast(Category_Process)
        {
            actionref(BC14MigrationSettings_Promoted; BC14MigrationSettings)
            {
            }
            actionref(BC14MigrationErrors_Promoted; BC14MigrationErrors)
            {
            }
        }
    }

    trigger OnOpenPage()
    var
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        BC14MigrationEnabled := BC14Wizard.GetBC14MigrationEnabled();
        if BC14MigrationEnabled then
            UpdateCompanyUpgradeStatus();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if BC14MigrationEnabled then begin
            UpdateCompanyUpgradeStatus();
            UpdateUpgradeErrorDetails();
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
        HasFailedCompanies: Boolean;
        HasUpgradeErrorDetails: Boolean;
        CompanyUpgradeStatusText: Text;
        UpgradeErrorDetailsText: Text;
        PendingLbl: Label 'Pending: %1', Comment = '%1 = Count';
        StartedLbl: Label 'Started: %1', Comment = '%1 = Count';
        CompletedLbl: Label 'Completed: %1', Comment = '%1 = Count';
        FailedLbl: Label 'Failed: %1', Comment = '%1 = Count';
        NoCompaniesLbl: Label 'No companies';
}