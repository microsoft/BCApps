// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Sales.Customer;

codeunit 46904 "BC14 Cust. Post. Grp. Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Customer Posting Group";

    trigger OnRun()
    begin
        MigrateCustomerPostingGroup(Rec);
    end;

    var
        MigratorNameLbl: Label 'Customer Posting Group Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Customer Posting Group", Database::"BC14 Customer Posting Group");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CustomerPostingGroup: Record "BC14 Customer Posting Group";
    begin
        exit(not BC14CustomerPostingGroup.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14CustomerPostingGroup: Record "BC14 Customer Posting Group";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14CustomerPostingGroup;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Cust. Post. Grp. Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14CustomerPostingGroup: Record "BC14 Customer Posting Group";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Customer Posting Group", BC14CustomerPostingGroup.Count()));
    end;

    internal procedure MigrateCustomerPostingGroup(BC14CustomerPostingGroup: Record "BC14 Customer Posting Group")
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateCustomerPostingGroup(BC14CustomerPostingGroup, IsMigrated);
        if IsMigrated then
            exit;

        if CustomerPostingGroup.Get(BC14CustomerPostingGroup.Code) then begin
            TransferFields(BC14CustomerPostingGroup, CustomerPostingGroup);
            CustomerPostingGroup.Modify();
        end else begin
            CustomerPostingGroup.Init();
            TransferFields(BC14CustomerPostingGroup, CustomerPostingGroup);
            CustomerPostingGroup.Insert();
        end;

        OnAfterMigrateCustomerPostingGroup(BC14CustomerPostingGroup, CustomerPostingGroup);
    end;

    local procedure TransferFields(BC14CustomerPostingGroup: Record "BC14 Customer Posting Group"; var CustomerPostingGroup: Record "Customer Posting Group")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        CustomerPostingGroup.Code := BC14CustomerPostingGroup.Code;

        // G/L Account FK fields: direct assignment. Customer Posting Group runs in the Setup phase,
        // before G/L Account is migrated in the Master phase, so Validate's TableRelation check would
        // always fail on a freshly-created target company. Accounts are verified lazily when posted.
        CustomerPostingGroup."Receivables Account" := BC14CustomerPostingGroup."Receivables Account";
        CustomerPostingGroup."Service Charge Acc." := BC14CustomerPostingGroup."Service Charge Acc.";
        CustomerPostingGroup."Payment Disc. Debit Acc." := BC14CustomerPostingGroup."Payment Disc. Debit Acc.";
        CustomerPostingGroup."Invoice Rounding Account" := BC14CustomerPostingGroup."Invoice Rounding Account";
        CustomerPostingGroup."Additional Fee Account" := BC14CustomerPostingGroup."Additional Fee Account";
        CustomerPostingGroup."Interest Account" := BC14CustomerPostingGroup."Interest Account";
        CustomerPostingGroup."Debit Curr. Appln. Rndg. Acc." := BC14CustomerPostingGroup."Debit Curr. Appln. Rndg. Acc.";
        CustomerPostingGroup."Credit Curr. Appln. Rndg. Acc." := BC14CustomerPostingGroup."Credit Curr. Appln. Rndg. Acc.";
        CustomerPostingGroup."Debit Rounding Account" := BC14CustomerPostingGroup."Debit Rounding Account";
        CustomerPostingGroup."Credit Rounding Account" := BC14CustomerPostingGroup."Credit Rounding Account";
        CustomerPostingGroup."Payment Disc. Credit Acc." := BC14CustomerPostingGroup."Payment Disc. Credit Acc.";
        CustomerPostingGroup."Payment Tolerance Debit Acc." := BC14CustomerPostingGroup."Payment Tolerance Debit Acc.";
        CustomerPostingGroup."Payment Tolerance Credit Acc." := BC14CustomerPostingGroup."Payment Tolerance Credit Acc.";
        CustomerPostingGroup."Add. Fee per Line Account" := BC14CustomerPostingGroup."Add. Fee per Line Account";
        CustomerPostingGroup.Validate(Description, BC14CustomerPostingGroup.Description);

        OnTransferCustomerPostingGroupCustomFields(BC14CustomerPostingGroup, CustomerPostingGroup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateCustomerPostingGroup(BC14CustomerPostingGroup: Record "BC14 Customer Posting Group"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateCustomerPostingGroup(BC14CustomerPostingGroup: Record "BC14 Customer Posting Group"; var CustomerPostingGroup: Record "Customer Posting Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferCustomerPostingGroupCustomFields(BC14CustomerPostingGroup: Record "BC14 Customer Posting Group"; var CustomerPostingGroup: Record "Customer Posting Group")
    begin
    end;
}

