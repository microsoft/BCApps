// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Purchases.Vendor;

codeunit 46933 "BC14 Vend. Bank Acct. Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Vendor Bank Account";

    trigger OnRun()
    begin
        MigrateVendorBankAccount(Rec);
    end;

    var
        MigratorNameLbl: Label 'Vendor Bank Account Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Vendor Bank Account", Database::"BC14 Vendor Bank Account");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14VendorBankAccount: Record "BC14 Vendor Bank Account";
    begin
        exit(not BC14VendorBankAccount.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14VendorBankAccount: Record "BC14 Vendor Bank Account";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14VendorBankAccount;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Vend. Bank Acct. Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14VendorBankAccount: Record "BC14 Vendor Bank Account";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Vendor Bank Account", BC14VendorBankAccount.Count()));
    end;

    internal procedure MigrateVendorBankAccount(BC14VendorBankAccount: Record "BC14 Vendor Bank Account")
    var
        VendorBankAccount: Record "Vendor Bank Account";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateVendorBankAccount(BC14VendorBankAccount, IsMigrated);
        if IsMigrated then
            exit;

        if VendorBankAccount.Get(BC14VendorBankAccount."Vendor No.", BC14VendorBankAccount.Code) then begin
            TransferFields(BC14VendorBankAccount, VendorBankAccount);
            VendorBankAccount.Modify();
        end else begin
            VendorBankAccount.Init();
            TransferFields(BC14VendorBankAccount, VendorBankAccount);
            VendorBankAccount.Insert();
        end;

        OnAfterMigrateVendorBankAccount(BC14VendorBankAccount, VendorBankAccount);
    end;

    local procedure TransferFields(BC14VendorBankAccount: Record "BC14 Vendor Bank Account"; var VendorBankAccount: Record "Vendor Bank Account")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        VendorBankAccount."Vendor No." := BC14VendorBankAccount."Vendor No.";
        VendorBankAccount.Code := BC14VendorBankAccount.Code;

        // Use Validate so any OnValidate business logic runs.
        VendorBankAccount.Validate(Name, BC14VendorBankAccount.Name);
        VendorBankAccount.Validate(Address, BC14VendorBankAccount.Address);
        VendorBankAccount.Validate("Address 2", BC14VendorBankAccount."Address 2");
        VendorBankAccount.Validate("Country/Region Code", BC14VendorBankAccount."Country/Region Code");
        VendorBankAccount.Validate("Post Code", BC14VendorBankAccount."Post Code");
        VendorBankAccount.Validate(City, BC14VendorBankAccount.City);
        VendorBankAccount.Validate(Contact, BC14VendorBankAccount.Contact);
        VendorBankAccount.Validate("Phone No.", BC14VendorBankAccount."Phone No.");
        VendorBankAccount.Validate("Bank Branch No.", BC14VendorBankAccount."Bank Branch No.");
        VendorBankAccount.Validate("Bank Account No.", BC14VendorBankAccount."Bank Account No.");
        VendorBankAccount.Validate("Transit No.", BC14VendorBankAccount."Transit No.");
        VendorBankAccount.Validate("Currency Code", BC14VendorBankAccount."Currency Code");
        VendorBankAccount.Validate("E-Mail", BC14VendorBankAccount."E-Mail");
        VendorBankAccount.Validate("Home Page", BC14VendorBankAccount."Home Page");
        VendorBankAccount.Validate(IBAN, BC14VendorBankAccount.IBAN);
        VendorBankAccount.Validate("SWIFT Code", BC14VendorBankAccount."SWIFT Code");

        OnTransferVendorBankAccountCustomFields(BC14VendorBankAccount, VendorBankAccount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateVendorBankAccount(BC14VendorBankAccount: Record "BC14 Vendor Bank Account"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateVendorBankAccount(BC14VendorBankAccount: Record "BC14 Vendor Bank Account"; var VendorBankAccount: Record "Vendor Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferVendorBankAccountCustomFields(BC14VendorBankAccount: Record "BC14 Vendor Bank Account"; var VendorBankAccount: Record "Vendor Bank Account")
    begin
    end;
}

