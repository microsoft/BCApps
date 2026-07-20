// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.DataMigration;

page 46859 "BC14 Company Upgrade Status"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Hybrid Company Status";
    SourceTableView = where(Name = filter(<> ''));
    Caption = 'Upgrading Companies';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    LinksAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Companies)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the company name. Click to open the per-company migration settings card.';

                    trigger OnDrillDown()
                    var
                        BC14CompanySettings: Record BC14CompanyMigrationInfo;
                    begin
                        if Rec.Name = '' then
                            exit;
                        BC14CompanySettings.GetForCompany(Rec.Name);
                        Page.Run(Page::"BC14 Company Migration Status", BC14CompanySettings);
                    end;
                }
                field("Upgrade Status"; UpgradeStatusText)
                {
                    ApplicationArea = All;
                    Caption = 'Upgrade Status';
                    ToolTip = 'Specifies the per-company upgrade phase status. A company actively running a migration phase shows In Progress.';
                    StyleExpr = StatusStyle;
                }
                field(CurrentPhase; CurrentPhaseText)
                {
                    ApplicationArea = All;
                    Caption = 'Current Phase';
                    ToolTip = 'Specifies the migration phase currently executing for this company (Setup, Master, Transaction, Posting, Historical, Completed).';
                    Editable = false;
                }
                field(PhaseProgress; PhaseProgressText)
                {
                    ApplicationArea = All;
                    Caption = 'Progress';
                    ToolTip = 'Specifies migrators completed vs. total for the phase currently shown in Current Phase. Switches between main phase progress (Setup/Master/Transaction) and Historical phase progress as the migration advances.';
                    Editable = false;
                }
                field(LastCompletedMigrator; LastCompletedMigratorText)
                {
                    ApplicationArea = All;
                    Caption = 'Last Completed Migrator';
                    ToolTip = 'Specifies the most recently completed individual migrator.';
                    Editable = false;
                }
                field(StatusMessage; StatusMessageText)
                {
                    ApplicationArea = All;
                    Caption = 'Status Message';
                    ToolTip = 'Specifies the most recent status or failure message captured for this company.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowErrors)
            {
                ApplicationArea = All;
                Caption = 'Show Errors';
                ToolTip = 'Opens the migration errors captured for the selected company.';
                Image = ErrorLog;

                trigger OnAction()
                var
                    BC14MigrationErrorOverview: Page "BC14 Migration Error Overview";
                begin
                    if Rec.Name = '' then
                        exit;
                    BC14MigrationErrorOverview.SetCompanyFilter(CopyStr(Rec.Name, 1, 30));
                    BC14MigrationErrorOverview.Run();
                end;
            }
            action(ContinueMigration)
            {
                ApplicationArea = All;
                Caption = 'Continue Migration';
                ToolTip = 'Continues (reruns) the migration for the selected company from where it stopped. Available only for companies whose migration has failed.';
                Image = Continue;
                Enabled = CanContinueMigration;

                trigger OnAction()
                var
                    BC14MigrationRunner: Codeunit "BC14 Migration Runner";
                begin
                    if Rec.Name = '' then
                        exit;
                    if Rec."Upgrade Status" <> Rec."Upgrade Status"::Failed then
                        exit;
                    if not Confirm(StrSubstNo(ContinueMigrationQst, Rec.Name), false) then
                        exit;

                    BC14MigrationRunner.ContinueMigrationForCompany(CopyStr(Rec.Name, 1, 30));
                    Message(ContinueMigrationScheduledMsg, Rec.Name);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ShowErrors_Promoted; ShowErrors) { }
                actionref(ContinueMigration_Promoted; ContinueMigration) { }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        StatusMessageInStream: InStream;
        HasCompanySettings: Boolean;
    begin
        StatusMessageText := '';
        Rec.CalcFields("Upgrade Failure Message");
        if Rec."Upgrade Failure Message".HasValue() then begin
            Rec."Upgrade Failure Message".CreateInStream(StatusMessageInStream);
            StatusMessageInStream.Read(StatusMessageText);
        end;

        CurrentPhaseText := '';
        PhaseProgressText := '';
        LastCompletedMigratorText := '';
        HasCompanySettings := BC14CompanySettings.Get(Rec.Name);
        if HasCompanySettings then begin
            CurrentPhaseText := Format(BC14CompanySettings."Current Migration Step");
            PhaseProgressText := StrSubstNo(ProgressFmtTxt, BC14CompanySettings."Phase Migrators Completed", BC14CompanySettings."Phase Migrators Total");
            LastCompletedMigratorText := BC14CompanySettings."Last Completed Migrator";
        end;

        UpgradeStatusText := Format(Rec."Upgrade Status");
        CanContinueMigration := Rec."Upgrade Status" = Rec."Upgrade Status"::Failed;
        case Rec."Upgrade Status" of
            Rec."Upgrade Status"::Failed:
                StatusStyle := 'Unfavorable';
            Rec."Upgrade Status"::Completed:
                StatusStyle := 'Favorable';
            Rec."Upgrade Status"::Started:
                if HasCompanySettings and IsActivelyMigrating(BC14CompanySettings."Current Migration Step") then begin
                    UpgradeStatusText := InProgressLbl;
                    StatusStyle := 'Strong';
                end else
                    StatusStyle := 'Standard';
            else
                StatusStyle := 'Standard';
        end;
    end;

    local procedure IsActivelyMigrating(MigrationStep: Enum "BC14 Migration Step"): Boolean
    begin
        // A company whose status is Started is actively migrating during every phase except the
        // NotStarted bookend (status just flipped, no phase entered yet) and the Completed bookend
        // (all phases done, about to flip to the Completed status).
        exit(not (MigrationStep in [
            MigrationStep::NotStarted,
            MigrationStep::Completed]));
    end;

    var
        StatusStyle: Text;
        StatusMessageText: Text;
        UpgradeStatusText: Text;
        CurrentPhaseText: Text;
        PhaseProgressText: Text;
        LastCompletedMigratorText: Text;
        CanContinueMigration: Boolean;
        ProgressFmtTxt: Label '%1 / %2', Comment = '%1 = completed count, %2 = total count';
        InProgressLbl: Label 'In Progress';
        ContinueMigrationQst: Label 'Continue migration for company %1?', Comment = '%1 = Company Name';
        ContinueMigrationScheduledMsg: Label 'Migration continuation has been scheduled for company %1.', Comment = '%1 = Company Name';
}
