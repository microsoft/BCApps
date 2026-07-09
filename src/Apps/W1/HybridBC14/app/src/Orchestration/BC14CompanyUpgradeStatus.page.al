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
                field("Upgrade Status"; Rec."Upgrade Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the per-company upgrade phase status (Pending, Started, Completed, Failed).';
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

    trigger OnAfterGetRecord()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        StatusMessageInStream: InStream;
    begin
        StatusMessageText := '';
        Rec.CalcFields("Upgrade Failure Message");
        if Rec."Upgrade Failure Message".HasValue() then begin
            Rec."Upgrade Failure Message".CreateInStream(StatusMessageInStream);
            StatusMessageInStream.Read(StatusMessageText);
        end;

        case Rec."Upgrade Status" of
            Rec."Upgrade Status"::Failed:
                StatusStyle := 'Unfavorable';
            Rec."Upgrade Status"::Completed:
                StatusStyle := 'Favorable';
            Rec."Upgrade Status"::Started:
                StatusStyle := 'Attention';
            else
                StatusStyle := 'Standard';
        end;

        CurrentPhaseText := '';
        PhaseProgressText := '';
        LastCompletedMigratorText := '';
        if BC14CompanySettings.Get(Rec.Name) then begin
            CurrentPhaseText := Format(BC14CompanySettings."Current Migration Step");
            PhaseProgressText := StrSubstNo(ProgressFmtTxt, BC14CompanySettings."Phase Migrators Completed", BC14CompanySettings."Phase Migrators Total");
            LastCompletedMigratorText := BC14CompanySettings."Last Completed Migrator";
        end;
    end;

    var
        StatusStyle: Text;
        StatusMessageText: Text;
        CurrentPhaseText: Text;
        PhaseProgressText: Text;
        LastCompletedMigratorText: Text;
        ProgressFmtTxt: Label '%1 / %2', Comment = '%1 = completed count, %2 = total count';
}
