// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

page 50160 "BC14 Migration Configuration"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "BC14CompanyAdditionalSettings";
    Caption = 'BC14 Migration Configuration';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the company name.';
                    Editable = false;
                }
            }

            group(Modules)
            {
                Caption = 'Modules to Migrate';

                field("Migrate GL Module"; Rec."Migrate GL Module")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to migrate General Ledger data.';
                }

                field("Migrate Receivables Module"; Rec."Migrate Receivables Module")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to migrate Customer data.';
                }

                field("Migrate Payables Module"; Rec."Migrate Payables Module")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to migrate Vendor data.';
                }

                field("Migrate Inventory Module"; Rec."Migrate Inventory Module")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to migrate Item data.';
                }
            }

            group(Transactions)
            {
                Caption = 'Transaction Migration';

                field("Skip Posting Journal Batches"; Rec."Skip Posting Journal Batches")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to skip automatic posting of migration journal batches. Enable this if you want to review and post journals manually.';
                }

                field("Stop On First Transformation Error"; Rec."Stop On First Error")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether migration should stop immediately when a transformation error is found. Disable to continue and collect all errors in the log.';
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
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ResetMigrationStatus)
            {
                ApplicationArea = All;
                Caption = 'Reset Migration Status';
                ToolTip = 'Reset the migration status to allow replication again. Use this if you need to re-run replication for this company.';
                Image = ResetStatus;

                trigger OnAction()
                begin
                    if not Confirm(ResetMigrationStatusQst, false, Rec.Name) then
                        exit;

                    Rec."Data Migration Started" := false;
                    Rec."Data Migration Started At" := 0DT;
                    Rec.Modify();
                    Message(MigrationStatusResetMsg, Rec.Name);
                end;
            }

            action(ResetAllCompanies)
            {
                ApplicationArea = All;
                Caption = 'Reset All Companies';
                ToolTip = 'Reset the migration status for all companies to allow replication again.';
                Image = Restore;

                trigger OnAction()
                var
                    BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
                    Count: Integer;
                begin
                    if not Confirm(ResetAllCompaniesQst, false) then
                        exit;

                    BC14CompanyAdditionalSettings.ModifyAll("Data Migration Started", false);
                    BC14CompanyAdditionalSettings.ModifyAll("Data Migration Started At", 0DT);
                    Count := BC14CompanyAdditionalSettings.Count();
                    Message(MigrationStatusResetAllMsg, Count);
                end;
            }
        }
        area(Navigation)
        {
            action(UpgradeSettings)
            {
                ApplicationArea = All;
                Caption = 'Upgrade Settings';
                ToolTip = 'Open upgrade settings.';
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
            actionref(ResetMigrationStatusRef; ResetMigrationStatus) { }
            actionref(ResetAllCompaniesRef; ResetAllCompanies) { }
        }
    }

    var
        ResetMigrationStatusQst: Label 'Are you sure you want to reset the migration status for company %1?\This will allow replication to run again.', Comment = '%1 = Company Name';
        ResetAllCompaniesQst: Label 'Are you sure you want to reset the migration status for ALL companies?\This will allow replication to run again for all companies.';
        MigrationStatusResetMsg: Label 'Migration status has been reset for company %1. You can now run replication again.', Comment = '%1 = Company Name';
        MigrationStatusResetAllMsg: Label 'Migration status has been reset for %1 companies. You can now run replication again.', Comment = '%1 = Count';

    trigger OnOpenPage()
    begin
        if not Rec.Get(CompanyName()) then begin
            Rec.Init();
            Rec.Name := CopyStr(CompanyName(), 1, 30);
            Rec.Insert();
        end;
    end;
}
