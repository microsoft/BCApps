// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

page 46869 "BC14 Company Migration Status"
{
    PageType = Card;
    SourceTable = BC14CompanyMigrationInfo;
    SourceTableView = where(Name = filter(<> ''));
    Caption = 'Company Migration Status';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(SettingsLockedInfo)
            {
                ShowCaption = false;
                Visible = not SettingsEditable;
                label(SettingsLockedMessage)
                {
                    ApplicationArea = All;
                    Style = Ambiguous;

                    Caption = 'Migration has started for this company. Module and transaction settings can no longer be changed because data that has already been migrated cannot be reverted, and a module whose phase has already run will not be triggered again.';
                }
            }

            group(General)
            {
                Caption = 'General';

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the company name.';
                    Editable = false;
                }

                field("Stop On First Transformation Error"; Rec."Stop On First Error")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether migration should stop immediately when a transformation error is found for this company. Disable to continue and collect all errors in the log.';
                    Editable = SettingsEditable;
                }
            }

            group(Modules)
            {
                Caption = 'Modules to Migrate';
                Editable = SettingsEditable;

                field("Migrate GL Module"; Rec."Migrate GL Module")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to migrate General Ledger data. Locked after migration has started.';
                    Editable = SettingsEditable;
                }

                field("Migrate Receivables Module"; Rec."Migrate Receivables Module")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to migrate Customer data. Locked after migration has started.';
                    Editable = SettingsEditable;
                }

                field("Migrate Payables Module"; Rec."Migrate Payables Module")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to migrate Vendor data. Locked after migration has started.';
                    Editable = SettingsEditable;
                }

                field("Migrate Inventory Module"; Rec."Migrate Inventory Module")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to migrate Item data. Locked after migration has started.';
                    Editable = SettingsEditable;
                }

                field("Migrate Historical Records"; Rec."Migrate Historical Records")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to migrate historical records (Posted Sales Invoice, Old G/L Entry archive) for this company. Disable to skip the Historical phase entirely. Locked after migration has started.';
                    Editable = SettingsEditable;
                }
            }

            group(Transactions)
            {
                Caption = 'Transaction Migration';
                Editable = SettingsEditable;

                field("Skip Posting Journal Batches"; Rec."Skip Posting Journal Batches")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to skip automatic posting of migration journal batches. Enable this if you want to review and post journals manually. Locked after migration has started.';
                    Editable = SettingsEditable;
                }
            }

            group(Status)
            {
                Caption = 'Status';

                field("Data Migration Started"; Rec."Data Migration Started")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether data migration has started for this company. Once started, additional replication is blocked.';
                    Editable = false;
                }

                field("Data Migration Started At"; Rec."Data Migration Started At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when data migration was started for this company.';
                    Editable = false;
                }

                field("Migration State"; Rec."Current Migration Step")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current state of the migration process.';
                    Editable = false;
                    StyleExpr = MigrationStateStyle;
                }

                field("Last Completed Phase"; Rec."Last Completed Phase")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the last migration phase that was completed successfully.';
                    Editable = false;
                }

                field(PhaseProgress; PhaseProgressText)
                {
                    ApplicationArea = All;
                    Caption = 'Phase Progress';
                    ToolTip = 'Specifies the progress of the currently running migration phase (Setup / Master / Transactional). Updated as each migrator inside the phase finishes. Historical Data is tracked independently below because it runs asynchronously.';
                    Editable = false;
                    Visible = PhaseProgressVisible;
                }

                field(PostingStatus; PostingStatusText)
                {
                    ApplicationArea = All;
                    Caption = 'Posting Status';
                    ToolTip = 'Specifies whether the journal posting step has completed. Posting runs after the transformation phases and is tracked independently of the phase chain.';
                    Editable = false;
                    StyleExpr = PostingStatusStyle;
                }

                field(HistoricalStatus; HistoricalStatusText)
                {
                    ApplicationArea = All;
                    Caption = 'Historical Data Status';
                    ToolTip = 'Specifies whether the historical data migration has completed. It runs asynchronously after posting and is tracked independently of the phase chain. When failed, the reason is shown.';
                    Editable = false;
                    StyleExpr = HistoricalStatusStyle;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(MigrationErrors)
            {
                ApplicationArea = All;
                Caption = 'Migration Errors';
                ToolTip = 'View migration errors.';
                Image = ErrorLog;
                RunObject = page "BC14 Migration Error Overview";
            }
        }
    }

    var
        MigrationStateStyle: Text;
        PhaseProgressText: Text;
        PhaseProgressVisible: Boolean;
        PostingStatusText: Text;
        PostingStatusStyle: Text;
        HistoricalStatusText: Text;
        HistoricalStatusStyle: Text;
        SettingsEditable: Boolean;
        PostingPendingLbl: Label 'Pending';
        PostingCompletedLbl: Label 'Completed';
        HistoricalPendingLbl: Label 'Pending';
        HistoricalRunningLbl: Label 'Running';
        HistoricalRunningProgressLbl: Label 'Running (%1 / %2, %3%)', Comment = '%1 = completed migrators, %2 = total migrators, %3 = percentage';
        HistoricalCompletedLbl: Label 'Completed';
        HistoricalFailedLbl: Label 'Failed: %1', Comment = '%1 = failure reason';
        HistoricalFailedNoReasonLbl: Label 'Failed';
        PhaseProgressLbl: Label '%1 / %2 (%3%)', Comment = '%1 = completed migrators, %2 = total migrators, %3 = percentage';
        DirectOpenNotAllowedErr: Label 'This page cannot be opened directly. Open it from the BC14 Re-implementation Configuration page.';

    trigger OnOpenPage()
    begin
        if Rec.Name = '' then
            Error(DirectOpenNotAllowedErr);
        PhaseProgressVisible := Rec."Phase Migrators Total" > 0;
    end;

    trigger OnAfterGetRecord()
    begin
        SettingsEditable := not Rec."Data Migration Started";

        case Rec."Current Migration Step" of
            "BC14 Migration Step"::Completed:
                MigrationStateStyle := Format(PageStyle::Favorable);
            "BC14 Migration Step"::NotStarted:
                MigrationStateStyle := Format(PageStyle::Standard);
            else
                MigrationStateStyle := Format(PageStyle::Ambiguous);
        end;

        PhaseProgressVisible := Rec."Phase Migrators Total" > 0;
        if PhaseProgressVisible then
            PhaseProgressText := StrSubstNo(
                PhaseProgressLbl,
                Rec."Phase Migrators Completed",
                Rec."Phase Migrators Total",
                Round(Rec."Phase Migrators Completed" / Rec."Phase Migrators Total" * 100, 1))
        else
            PhaseProgressText := '';

        if Rec."Posting Completed" then begin
            PostingStatusText := PostingCompletedLbl;
            PostingStatusStyle := Format(PageStyle::Favorable);
        end else begin
            PostingStatusText := PostingPendingLbl;
            PostingStatusStyle := Format(PageStyle::Ambiguous);
        end;

        if Rec."Historical Failed" then begin
            if Rec."Historical Failure Reason" <> '' then
                HistoricalStatusText := StrSubstNo(HistoricalFailedLbl, Rec."Historical Failure Reason")
            else
                HistoricalStatusText := HistoricalFailedNoReasonLbl;
            HistoricalStatusStyle := Format(PageStyle::Unfavorable);
        end else
            if Rec."Historical Completed" then begin
                HistoricalStatusText := HistoricalCompletedLbl;
                HistoricalStatusStyle := Format(PageStyle::Favorable);
            end else
                if Rec."Historical Dispatched" then begin
                    if Rec."Phase Migrators Total" > 0 then
                        HistoricalStatusText := StrSubstNo(
                            HistoricalRunningProgressLbl,
                            Rec."Phase Migrators Completed",
                            Rec."Phase Migrators Total",
                            Round(Rec."Phase Migrators Completed" / Rec."Phase Migrators Total" * 100, 1))
                    else
                        HistoricalStatusText := HistoricalRunningLbl;
                    HistoricalStatusStyle := Format(PageStyle::Attention);
                end else begin
                    HistoricalStatusText := HistoricalPendingLbl;
                    HistoricalStatusStyle := Format(PageStyle::Ambiguous);
                end;
    end;
}
