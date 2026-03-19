// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.DataMigration;
using Microsoft.Sales.Customer;

page 50160 "BC14 Migration Configuration"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "BC14CompanyMigrationSettings";
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

                field("Migration State"; Rec."Migration State")
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

                field("Failed Migrator Name"; Rec."Failed Migrator Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the migrator that failed (when paused).';
                    Editable = false;
                    Visible = IsMigrationPaused;
                }

                field("Migration Paused At"; Rec."Migration Paused At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the migration was paused due to an error.';
                    Editable = false;
                    Visible = IsMigrationPaused;
                }
            }

            group(UpgradeSettings)
            {
                Caption = 'Upgrade Settings';

                field(OneStepUpgrade; BC14GlobalSettings."One Step Upgrade")
                {
                    ApplicationArea = All;
                    Caption = 'Run upgrade after replication';
                    ToolTip = 'Specifies whether to run the upgrade automatically after replication completes. Disable this if you want to manually trigger the upgrade.';

                    trigger OnValidate()
                    begin
                        BC14GlobalSettings.Modify();
                    end;
                }

                field(OneStepUpgradeDelay; BC14GlobalSettings."One Step Upgrade Delay")
                {
                    ApplicationArea = All;
                    Caption = 'Upgrade delay after replication';
                    ToolTip = 'Specifies the delay before starting the upgrade after replication completes.';

                    trigger OnValidate()
                    begin
                        BC14GlobalSettings.Modify();
                    end;
                }

                field(DataUpgradeStarted; BC14GlobalSettings."Data Upgrade Started")
                {
                    ApplicationArea = All;
                    Caption = 'Data Upgrade Started';
                    ToolTip = 'Specifies when the data upgrade was started.';
                    Editable = false;
                }

                field(ReplicationCompleted; BC14GlobalSettings."Replication Completed")
                {
                    ApplicationArea = All;
                    Caption = 'Replication Completed';
                    ToolTip = 'Specifies when the replication was completed.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ContinueMigration)
            {
                ApplicationArea = All;
                Caption = 'Continue Migration';
                ToolTip = 'Continue the paused migration from where it stopped. Use this after fixing errors when Stop On First Error is enabled.';
                Image = Continue;
                Enabled = IsMigrationPaused;

                trigger OnAction()
                var
                    BC14MigrationRunner: Codeunit "BC14 Migration Runner";
                begin
                    if not Confirm(ContinueMigrationQst, false, Rec."Failed Migrator Name") then
                        exit;

                    BC14MigrationRunner.ContinueMigration();
                    CurrPage.Update(false);
                end;
            }



            // ============ TEMPORARY TEST ACTIONS - DELETE BEFORE SHIPPING ============

            action(TestResetUpgradeStatus)
            {
                ApplicationArea = All;
                Caption = '[TEST] Reset Upgrade Status';
                ToolTip = 'TESTING ONLY: Reset HybridCompanyStatus to Pending to allow re-running upgrade.';
                Image = TestFile;

                trigger OnAction()
                var
                    HybridCompanyStatus: Record "Hybrid Company Status";
                begin
                    if not Confirm('Reset upgrade status to Pending for company %1?', false, CompanyName()) then
                        exit;

                    if HybridCompanyStatus.Get(CompanyName()) then begin
                        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Pending;
                        HybridCompanyStatus.Modify();
                    end;

                    Rec.ResetMigrationProgress();
                    Rec."Data Migration Started" := false;
                    Rec."Data Migration Started At" := 0DT;
                    Rec.Modify();

                    CurrPage.Update(false);
                    Message('Reset complete. Upgrade Status = Pending. You can now re-run upgrade.');
                end;
            }

            action(TestCorruptBufferData)
            {
                ApplicationArea = All;
                Caption = '[TEST] Corrupt Buffer Data';
                ToolTip = 'TESTING ONLY: Corrupt BC14 Customer and Item buffer data to trigger migration errors.';
                Image = TestFile;

                trigger OnAction()
                var
                    BC14Customer: Record "BC14 Customer";
                    BC14Item: Record "BC14 Item";
                    CorruptedCount: Integer;
                    ResultMsg: Text;
                begin
                    if not Confirm('This will corrupt BC14 Customer and Item records to trigger migration errors.\Continue?') then
                        exit;

                    CorruptedCount := 0;
                    ResultMsg := '';

                    // Corrupt Customer
                    if BC14Customer.FindFirst() then begin
                        BC14Customer."Customer Posting Group" := 'INVALID-TEST';
                        BC14Customer."Gen. Bus. Posting Group" := 'INVALID-GBP';
                        BC14Customer."Payment Terms Code" := 'INVALID-PT';
                        BC14Customer."Currency Code" := 'XXX';
                        BC14Customer."Country/Region Code" := 'ZZZ';
                        BC14Customer."Language Code" := 'ZZZ';
                        BC14Customer.Modify();
                        CorruptedCount += 1;
                        ResultMsg += 'Customer ' + BC14Customer."No." + ': Posting Group, Gen Bus, Payment Terms, Currency, Country, Language\';
                    end;

                    // Corrupt Item
                    if BC14Item.FindFirst() then begin
                        BC14Item."Inventory Posting Group" := 'INVALID-IPG';
                        BC14Item."Gen. Prod. Posting Group" := 'INVALID-GPG';
                        BC14Item."Base Unit of Measure" := 'INVALID';
                        BC14Item."Item Tracking Code" := 'INVALID';
                        BC14Item."Vendor No." := 'INVALID-VEND';
                        BC14Item.Modify();
                        CorruptedCount += 1;
                        ResultMsg += 'Item ' + BC14Item."No." + ': Inventory Posting, Gen Prod, Base UoM, Item Tracking, Vendor\';
                    end;

                    if CorruptedCount > 0 then
                        Message('Corrupted %1 record(s):\%2\Run upgrade to generate errors.', CorruptedCount, ResultMsg)
                    else
                        Message('No BC14 Customer or Item records found to corrupt.');
                end;
            }

            action(TestCreateFakeError)
            {
                ApplicationArea = All;
                Caption = '[TEST] Create Fake Error';
                ToolTip = 'TESTING ONLY: Create a fake error record in BC14 Migration Errors for UI testing.';
                Image = TestFile;

                trigger OnAction()
                var
                    BC14MigrationErrors: Record "BC14 Migration Errors";
                    BC14Customer: Record "BC14 Customer";
                begin
                    if BC14Customer.FindFirst() then begin
                        BC14MigrationErrors.Init();
                        BC14MigrationErrors."Migration Type" := 'Customer Migrator';
                        BC14MigrationErrors."Source Table ID" := Database::"BC14 Customer";
                        BC14MigrationErrors."Source Table Name" := 'BC14 Customer';
                        BC14MigrationErrors."Source Record Key" := BC14Customer."No.";
                        BC14MigrationErrors."Destination Table ID" := Database::Customer;
                        BC14MigrationErrors."Company Name" := CopyStr(CompanyName(), 1, 30);
                        BC14MigrationErrors."Error Message" := 'Test error - Customer Posting Group not found';
                        BC14MigrationErrors."Created On" := CurrentDateTime();
                        BC14MigrationErrors."Record Id" := BC14Customer.RecordId;
                        BC14MigrationErrors."Scheduled For Retry" := false;
                        BC14MigrationErrors."Resolved" := false;
                        BC14MigrationErrors.Insert(true);
                        Message('Created fake error for customer: %1\Go to Migration Errors to test.', BC14Customer."No.");
                    end else
                        Message('No BC14 Customer records found. Cannot create fake error.');
                end;
            }

            action(TestRunCustomerMigrator)
            {
                ApplicationArea = All;
                Caption = '[TEST] Run Customer Migrator';
                ToolTip = 'TESTING ONLY: Directly run Customer Migrator to see if errors occur.';
                Image = TestFile;

                trigger OnAction()
                var
                    BC14Customer: Record "BC14 Customer";
                    BC14MigrationErrors: Record "BC14 Migration Errors";
                    BC14MigrationRecordStatus: Record "BC14 Migration Record Status";
                    BC14CustomerMigrator: Codeunit "BC14 Customer Migrator";
                    BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
                    SourceRecordRef: RecordRef;
                    CustomerCount: Integer;
                    ErrorCountBefore: Integer;
                    ErrorCountAfter: Integer;
                    MigratedCount: Integer;
                    SkippedCount: Integer;
                    IsEnabledValue: Boolean;
                    Success: Boolean;
                    RecordKey: Text[250];
                    SourceTableId: Integer;
                begin
                    CustomerCount := BC14Customer.Count();
                    IsEnabledValue := BC14CustomerMigrator.IsEnabled();

                    BC14MigrationErrors.SetRange("Company Name", CompanyName());
                    BC14MigrationErrors.SetRange("Source Table ID", Database::"BC14 Customer");
                    ErrorCountBefore := BC14MigrationErrors.Count();

                    if CustomerCount = 0 then begin
                        Message('BC14 Customer table is EMPTY!\No records to migrate.');
                        exit;
                    end;

                    if not IsEnabledValue then begin
                        Message('Customer Migrator is DISABLED!\Enable "Migrate Receivables Module" first.\BC14 Customer count: %1', CustomerCount);
                        exit;
                    end;

                    // Show first customer data
                    if BC14Customer.FindFirst() then
                        Message('First BC14 Customer:\No: %1\Name: %2\Customer Posting Group: %3\Gen Bus Posting Group: %4',
                            BC14Customer."No.", BC14Customer.Name,
                            BC14Customer."Customer Posting Group", BC14Customer."Gen. Bus. Posting Group");

                    // Runner-driven migration test
                    Success := true;
                    MigratedCount := 0;
                    SkippedCount := 0;
                    SourceTableId := BC14CustomerMigrator.GetSourceTableId();
                    SourceRecordRef.Open(SourceTableId);
                    BC14CustomerMigrator.InitializeSourceRecords(SourceRecordRef);

                    if SourceRecordRef.FindSet() then
                        repeat
                            RecordKey := BC14CustomerMigrator.GetSourceRecordKey(SourceRecordRef);
                            if BC14MigrationRecordStatus.IsMigrated(SourceTableId, RecordKey) then
                                SkippedCount += 1
                            else
                                if BC14CustomerMigrator.MigrateRecord(SourceRecordRef) then begin
                                    BC14MigrationRecordStatus.MarkAsMigrated(SourceTableId, RecordKey);
                                    MigratedCount += 1;
                                end else begin
                                    BC14MigrationErrorHandler.LogError(BC14CustomerMigrator.GetName(), Database::"BC14 Customer", 'BC14 Customer', RecordKey, Database::Customer, GetLastErrorText(), SourceRecordRef.RecordId);
                                    Success := false;
                                    ClearLastError();
                                end;
                        until SourceRecordRef.Next() = 0;
                    SourceRecordRef.Close();

                    BC14MigrationErrors.Reset();
                    BC14MigrationErrors.SetRange("Company Name", CompanyName());
                    BC14MigrationErrors.SetRange("Source Table ID", Database::"BC14 Customer");
                    ErrorCountAfter := BC14MigrationErrors.Count();

                    Message('Migration Result:\Success: %1\BC14 Customer count: %2\Migrated: %3\Skipped (already done): %4\Errors before: %5\Errors after: %6\New errors: %7',
                        Success, CustomerCount, MigratedCount, SkippedCount, ErrorCountBefore, ErrorCountAfter, ErrorCountAfter - ErrorCountBefore);
                end;
            }

            action(TestShowBufferData)
            {
                ApplicationArea = All;
                Caption = '[TEST] Show Buffer Data';
                ToolTip = 'TESTING ONLY: Show first BC14 Customer and Item data.';
                Image = TestFile;

                trigger OnAction()
                var
                    BC14Customer: Record "BC14 Customer";
                    BC14Item: Record "BC14 Item";
                    Msg: Text;
                begin
                    Msg := 'Buffer Data Summary:\';
                    Msg += 'BC14 Customer count: ' + Format(BC14Customer.Count()) + '\';
                    Msg += 'BC14 Item count: ' + Format(BC14Item.Count()) + '\';

                    if BC14Customer.FindFirst() then
                        Msg += '\First Customer:\' +
                            'No: ' + BC14Customer."No." + '\' +
                            'Name: ' + BC14Customer.Name + '\' +
                            'Cust Posting Grp: ' + BC14Customer."Customer Posting Group" + '\' +
                            'Gen Bus Posting Grp: ' + BC14Customer."Gen. Bus. Posting Group" + '\';

                    if BC14Item.FindFirst() then
                        Msg += '\First Item:\' +
                            'No: ' + BC14Item."No." + '\' +
                            'Desc: ' + BC14Item.Description + '\' +
                            'Inv Posting Grp: ' + BC14Item."Inventory Posting Group" + '\' +
                            'Gen Prod Posting Grp: ' + BC14Item."Gen. Prod. Posting Group";

                    Message(Msg);
                end;
            }

            // ============ END TEMPORARY TEST ACTIONS ============
        }
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
        area(Promoted)
        {
            actionref(ContinueMigrationRef; ContinueMigration) { }

            group(TestActions)
            {
                Caption = '[TEST]';
                actionref(TestResetUpgradeStatusRef; TestResetUpgradeStatus) { }
                actionref(TestCorruptBufferDataRef; TestCorruptBufferData) { }
                actionref(TestCreateFakeErrorRef; TestCreateFakeError) { }
                actionref(TestRunCustomerMigratorRef; TestRunCustomerMigrator) { }
                actionref(TestShowBufferDataRef; TestShowBufferData) { }
            }
        }
    }

    var
        BC14GlobalSettings: Record "BC14 Global Migration Settings";

        ContinueMigrationQst: Label 'The migration was paused due to an error in %1.\Have you fixed the error? Do you want to continue migration?', Comment = '%1 = Failed Migrator Name';
        IsMigrationPaused: Boolean;
        MigrationStateStyle: Text;

    trigger OnOpenPage()
    begin
        if not Rec.Get(CompanyName()) then begin
            Rec.Init();
            Rec.Name := CopyStr(CompanyName(), 1, 30);
            Rec.Insert();
        end;

        BC14GlobalSettings.GetOrInsertGlobalSettings(BC14GlobalSettings);
    end;

    trigger OnAfterGetRecord()
    begin
        IsMigrationPaused := Rec."Migration State" = "BC14 Migration State"::Paused;

        case Rec."Migration State" of
            "BC14 Migration State"::Paused:
                MigrationStateStyle := 'Unfavorable';
            "BC14 Migration State"::Completed:
                MigrationStateStyle := 'Favorable';
            "BC14 Migration State"::NotStarted:
                MigrationStateStyle := 'Standard';
            else
                MigrationStateStyle := 'Ambiguous';
        end;
    end;
}
