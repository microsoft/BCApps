// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.DataMigration;

page 46860 "BC14 Migration Configuration"
{
    PageType = Card;
    SourceTable = BC14CompanyMigrationInfo;
    SourceTableView = where(Name = filter(= ''));
    Caption = 'BC14 Re-implementation Configuration';
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = true;

    layout
    {
        area(Content)
        {
            label(Intro)
            {
                ApplicationArea = All;
                Caption = 'Use this page to configure the default re-implementation settings applied to all companies. Per-company overrides can be set from the Company Re-implementation Settings worksheet.';
            }

            group(Modules)
            {
                Caption = 'Modules';
                InstructionalText = 'Select the modules you would like migrated.';

                field("Migrate GL Module"; Rec."Migrate GL Module")
                {
                    ApplicationArea = All;
                    Caption = 'General Ledger';
                    ToolTip = 'Specifies whether to migrate the General Ledger module for all companies.';

                    trigger OnValidate()
                    begin
                        FanOutField(Rec.FieldNo("Migrate GL Module"), Rec."Migrate GL Module");
                    end;
                }
                field("Migrate Receivables Module"; Rec."Migrate Receivables Module")
                {
                    ApplicationArea = All;
                    Caption = 'Receivables';
                    ToolTip = 'Specifies whether to migrate the Receivables (Customer) module for all companies.';

                    trigger OnValidate()
                    begin
                        FanOutField(Rec.FieldNo("Migrate Receivables Module"), Rec."Migrate Receivables Module");
                    end;
                }
                field("Migrate Payables Module"; Rec."Migrate Payables Module")
                {
                    ApplicationArea = All;
                    Caption = 'Payables';
                    ToolTip = 'Specifies whether to migrate the Payables (Vendor) module for all companies.';

                    trigger OnValidate()
                    begin
                        FanOutField(Rec.FieldNo("Migrate Payables Module"), Rec."Migrate Payables Module");
                    end;
                }
                field("Migrate Inventory Module"; Rec."Migrate Inventory Module")
                {
                    ApplicationArea = All;
                    Caption = 'Inventory';
                    ToolTip = 'Specifies whether to migrate the Inventory (Item) module for all companies.';

                    trigger OnValidate()
                    begin
                        FanOutField(Rec.FieldNo("Migrate Inventory Module"), Rec."Migrate Inventory Module");
                    end;
                }
            }

            group(Posting)
            {
                Caption = 'Disable Auto Posting';
                InstructionalText = 'Select whether migrated transactions should be posted automatically during the migration process. Disabling auto posting allows you to review and adjust transactions in Business Central before posting.';

                field("Skip Posting Journal Batches"; Rec."Skip Posting Journal Batches")
                {
                    ApplicationArea = All;
                    Caption = 'Skip Posting Journal Batches';
                    ToolTip = 'Specifies whether to skip automatic posting of migration journal batches for all companies.';

                    trigger OnValidate()
                    begin
                        FanOutField(Rec.FieldNo("Skip Posting Journal Batches"), Rec."Skip Posting Journal Batches");
                    end;
                }
            }

            group(ErrorHandling)
            {
                Caption = 'Error Handling';

                field("Stop On First Error"; Rec."Stop On First Error")
                {
                    ApplicationArea = All;
                    Caption = 'Stop On First Transformation Error';
                    ToolTip = 'Specifies whether migration should stop immediately when a transformation error is found. Disable to continue and collect all errors in the log.';

                    trigger OnValidate()
                    begin
                        FanOutField(Rec.FieldNo("Stop On First Error"), Rec."Stop On First Error");
                    end;
                }
            }

            group(Historical)
            {
                Caption = 'Historical';
                InstructionalText = 'Configure how historical G/L entries are split between the live ledger and the read-only archive.';

                field("Migrate Historical Records"; Rec."Migrate Historical Records")
                {
                    ApplicationArea = All;
                    Caption = 'Migrate Historical Records';
                    ToolTip = 'Specifies whether to migrate historical records (Posted Sales Invoice, Old G/L Entry archive) for all companies. Disable to skip the Historical phase entirely.';

                    trigger OnValidate()
                    begin
                        FanOutField(Rec.FieldNo("Migrate Historical Records"), Rec."Migrate Historical Records");
                    end;
                }
                field("Historical Cutoff Date"; Rec."Historical Cutoff Date")
                {
                    ApplicationArea = All;
                    Caption = 'Historical cutoff date';
                    ToolTip = 'Specifies the cutoff date for G/L entries between the live ledger and the read-only historical archive. Entries on or after this date are re-posted into the live G/L Entry table; entries before it are moved only to the BC14 Old G/L Entry archive and cannot be edited. Leave blank to re-post all entries into the live ledger (no archive is produced).';
                    Enabled = Rec."Migrate Historical Records";
                }
            }

            group(SettingsList)
            {
                Caption = 'Per Company';

                part(CompanyList; "BC14 Co. Migration Settings")
                {
                    ApplicationArea = All;
                    Caption = 'Configure individual company settings';
                    ShowFilter = true;
                    UpdatePropagation = Both;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ResetAllAction)
            {
                ApplicationArea = All;
                Caption = 'Apply Defaults to All Companies';
                ToolTip = 'Push the current default values to every per-company row, overwriting any per-company customizations.';
                Image = Setup;

                trigger OnAction()
                begin
                    if Confirm(ResetAllQst) then
                        ResetAll();
                end;
            }
        }
        area(Navigation)
        {
            action(UpgradeSettings)
            {
                ApplicationArea = All;
                Caption = 'Upgrade settings';
                ToolTip = 'Change the global upgrade-time settings for the Business Central 14 migration (one-step toggle, delays, max setup wait time).';
                Image = Setup;
                RunObject = page "BC14 Upgrade Settings";
            }
            action(MigrationErrors)
            {
                ApplicationArea = All;
                Caption = 'Migration Errors';
                ToolTip = 'View migration errors.';
                Image = ErrorLog;
                RunObject = page "BC14 Migration Error Overview";
            }
        }
        area(Promoted)
        {
            actionref(ResetAllAction_Promoted; ResetAllAction)
            {
            }
            actionref(UpgradeSettings_Promoted; UpgradeSettings)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetOrInsertTemplate(Rec);
        EnsurePerCompanyRows();
    end;

    local procedure FanOutField(FieldId: Integer; NewValue: Variant)
    var
        CompanyRow: Record BC14CompanyMigrationInfo;
        TargetRecRef: RecordRef;
        TargetFieldRef: FieldRef;
    begin
        CompanyRow.SetFilter(Name, '<>%1', '');
        if not CompanyRow.FindSet(true) then
            exit;
        repeat
            TargetRecRef.GetTable(CompanyRow);
            TargetFieldRef := TargetRecRef.Field(FieldId);
            TargetFieldRef.Validate(NewValue);
            TargetRecRef.Modify();
        until CompanyRow.Next() = 0;
    end;

    local procedure ResetAll()
    var
        CompanyRow: Record BC14CompanyMigrationInfo;
    begin
        CompanyRow.SetFilter(Name, '<>%1', '');
        if not CompanyRow.FindSet(true) then
            exit;
        repeat
            CompanyRow."Migrate GL Module" := Rec."Migrate GL Module";
            CompanyRow."Migrate Receivables Module" := Rec."Migrate Receivables Module";
            CompanyRow."Migrate Payables Module" := Rec."Migrate Payables Module";
            CompanyRow."Migrate Inventory Module" := Rec."Migrate Inventory Module";
            CompanyRow."Skip Posting Journal Batches" := Rec."Skip Posting Journal Batches";
            CompanyRow."Stop On First Error" := Rec."Stop On First Error";
            CompanyRow.Modify();
        until CompanyRow.Next() = 0;
    end;

    local procedure EnsurePerCompanyRows()
    var
        HybridCompany: Record "Hybrid Company";
        CompanyRow: Record BC14CompanyMigrationInfo;
    begin
        HybridCompany.SetFilter(Name, '<>%1', '');
        if not HybridCompany.FindSet() then
            exit;
        repeat
            if not CompanyRow.Get(HybridCompany.Name) then begin
                CompanyRow.Init();
                CompanyRow.Name := CopyStr(HybridCompany.Name, 1, MaxStrLen(CompanyRow.Name));
                CompanyRow."Migrate GL Module" := Rec."Migrate GL Module";
                CompanyRow."Migrate Receivables Module" := Rec."Migrate Receivables Module";
                CompanyRow."Migrate Payables Module" := Rec."Migrate Payables Module";
                CompanyRow."Migrate Inventory Module" := Rec."Migrate Inventory Module";
                CompanyRow."Skip Posting Journal Batches" := Rec."Skip Posting Journal Batches";
                CompanyRow."Stop On First Error" := Rec."Stop On First Error";
                CompanyRow.Insert();
            end;
        until HybridCompany.Next() = 0;
    end;

    var
        ResetAllQst: Label 'This will overwrite the per-company settings for all companies with the current default values. Continue?';
}
