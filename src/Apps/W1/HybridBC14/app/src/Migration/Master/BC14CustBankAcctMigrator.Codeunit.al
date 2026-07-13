// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Sales.Customer;

codeunit 46932 "BC14 Cust. Bank Acct. Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Customer Bank Account";

    trigger OnRun()
    begin
        MigrateCustomerBankAccount(Rec);
    end;

    var
        MigratorNameLbl: Label 'Customer Bank Account Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Customer Bank Account", Database::"BC14 Customer Bank Account");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CustomerBankAccount: Record "BC14 Customer Bank Account";
    begin
        exit(not BC14CustomerBankAccount.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14CustomerBankAccount: Record "BC14 Customer Bank Account";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14CustomerBankAccount;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Cust. Bank Acct. Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14CustomerBankAccount: Record "BC14 Customer Bank Account";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Customer Bank Account", BC14CustomerBankAccount.Count()));
    end;

    internal procedure MigrateCustomerBankAccount(BC14CustomerBankAccount: Record "BC14 Customer Bank Account")
    var
        CustomerBankAccount: Record "Customer Bank Account";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateCustomerBankAccount(BC14CustomerBankAccount, IsMigrated);
        if IsMigrated then
            exit;

        if CustomerBankAccount.Get(BC14CustomerBankAccount."Customer No.", BC14CustomerBankAccount.Code) then begin
            TransferFields(BC14CustomerBankAccount, CustomerBankAccount);
            CustomerBankAccount.Modify();
        end else begin
            CustomerBankAccount.Init();
            TransferFields(BC14CustomerBankAccount, CustomerBankAccount);
            CustomerBankAccount.Insert();
        end;

        OnAfterMigrateCustomerBankAccount(BC14CustomerBankAccount, CustomerBankAccount);
    end;

    local procedure TransferFields(BC14CustomerBankAccount: Record "BC14 Customer Bank Account"; var CustomerBankAccount: Record "Customer Bank Account")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        CustomerBankAccount."Customer No." := BC14CustomerBankAccount."Customer No.";
        CustomerBankAccount.Code := BC14CustomerBankAccount.Code;

        // Use Validate so any OnValidate business logic runs.
        CustomerBankAccount.Validate(Name, BC14CustomerBankAccount.Name);
        CustomerBankAccount.Validate(Address, BC14CustomerBankAccount.Address);
        CustomerBankAccount.Validate("Address 2", BC14CustomerBankAccount."Address 2");
        CustomerBankAccount.Validate("Country/Region Code", BC14CustomerBankAccount."Country/Region Code");
        CustomerBankAccount.Validate("Post Code", BC14CustomerBankAccount."Post Code");
        CustomerBankAccount.Validate(City, BC14CustomerBankAccount.City);
        CustomerBankAccount.Validate(Contact, BC14CustomerBankAccount.Contact);
        CustomerBankAccount.Validate("Phone No.", BC14CustomerBankAccount."Phone No.");
        CustomerBankAccount.Validate("Bank Branch No.", BC14CustomerBankAccount."Bank Branch No.");
        CustomerBankAccount.Validate("Bank Account No.", BC14CustomerBankAccount."Bank Account No.");
        CustomerBankAccount.Validate("Transit No.", BC14CustomerBankAccount."Transit No.");
        CustomerBankAccount.Validate("Currency Code", BC14CustomerBankAccount."Currency Code");
        CustomerBankAccount.Validate("E-Mail", BC14CustomerBankAccount."E-Mail");
        CustomerBankAccount.Validate("Home Page", BC14CustomerBankAccount."Home Page");
        CustomerBankAccount.Validate(IBAN, BC14CustomerBankAccount.IBAN);
        CustomerBankAccount.Validate("SWIFT Code", BC14CustomerBankAccount."SWIFT Code");

        OnTransferCustomerBankAccountCustomFields(BC14CustomerBankAccount, CustomerBankAccount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateCustomerBankAccount(BC14CustomerBankAccount: Record "BC14 Customer Bank Account"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateCustomerBankAccount(BC14CustomerBankAccount: Record "BC14 Customer Bank Account"; var CustomerBankAccount: Record "Customer Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferCustomerBankAccountCustomFields(BC14CustomerBankAccount: Record "BC14 Customer Bank Account"; var CustomerBankAccount: Record "Customer Bank Account")
    begin
    end;
}

