// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.Sales.Customer;

codeunit 50165 "BC14 Customer Migrator" implements "IMasterMigrator"
{
    var
        MigratorNameLbl: Label 'Customer Migrator';

    procedure GetName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CompanySettings: Record BC14CompanyMigrationSettings;
    begin
        BC14CompanySettings.GetSingleInstance();
        exit(BC14CompanySettings.GetReceivablesModuleEnabled());
    end;

    procedure GetSourceTableId(): Integer
    begin
        exit(Database::"BC14 Customer");
    end;

    procedure InitializeSourceRecords(var SourceRecordRef: RecordRef)
    begin
        // No special filters needed for Customer migration
    end;

    procedure MigrateRecord(var SourceRecordRef: RecordRef): Boolean
    var
        BC14Customer: Record "BC14 Customer";
    begin
        SourceRecordRef.SetTable(BC14Customer);
        exit(TryMigrateCustomer(BC14Customer));
    end;

    procedure GetSourceRecordKey(var SourceRecordRef: RecordRef): Text[250]
    var
        NoFieldRef: FieldRef;
    begin
        NoFieldRef := SourceRecordRef.Field(1); // No. field
        exit(Format(NoFieldRef.Value()));
    end;

    procedure GetRecordCount(): Integer
    var
        BC14Customer: Record "BC14 Customer";
    begin
        exit(BC14Customer.Count());
    end;

    [TryFunction]
    local procedure TryMigrateCustomer(BC14Customer: Record "BC14 Customer")
    begin
        MigrateCustomer(BC14Customer);
    end;

    internal procedure MigrateCustomer(BC14Customer: Record "BC14 Customer")
    var
        Customer: Record Customer;
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        IsNew: Boolean;
    begin
        IsNew := not Customer.Get(BC14Customer."No.");
        if IsNew then begin
            Customer.Init();
            Customer."No." := BC14Customer."No.";
        end;

        // Populate all fields before Insert/Modify to prevent zombie records
        // (Insert succeeds but subsequent Modify fails leaving incomplete data)
        Customer.Name := BC14Customer.Name;
        Customer.Address := BC14Customer.Address;
        Customer."Address 2" := BC14Customer."Address 2";
        Customer.City := BC14Customer.City;
        Customer."Post Code" := BC14Customer."Post Code";
        Customer.Validate("Country/Region Code", BC14Customer."Country/Region Code");
        Customer."Phone No." := BC14Customer."Phone No.";
        Customer."E-Mail" := BC14Customer."E-Mail";
        Customer."Home Page" := BC14Customer."Home Page";
        Customer.Validate("Customer Posting Group", BC14Customer."Customer Posting Group");
        Customer.Validate("Gen. Bus. Posting Group", BC14Customer."Gen. Bus. Posting Group");
        Customer.Validate("Payment Terms Code", BC14Customer."Payment Terms Code");
        Customer.Validate("Currency Code", BC14HelperFunctions.ResolveCurrencyCode(BC14Customer."Currency Code"));

        Customer.Validate("Language Code", BC14Customer."Language Code");
        Customer."Credit Limit (LCY)" := BC14Customer."Credit Limit (LCY)";
        Customer.Blocked := BC14Customer.Blocked;

        OnTransferCustomerCustomFields(BC14Customer, Customer);

        if IsNew then
            Customer.Insert(true)
        else
            Customer.Modify(true);
    end;

    /// <summary>
    /// Integration event raised during customer migration to allow mapping of custom fields.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnTransferCustomerCustomFields(BC14Customer: Record "BC14 Customer"; var Customer: Record Customer)
    begin
    end;
}
