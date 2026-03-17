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
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        BC14CompanyAdditionalSettings.GetSingleInstance();
        exit(BC14CompanyAdditionalSettings.GetReceivablesModuleEnabled());
    end;

    procedure Migrate(StopOnFirstError: Boolean): Boolean
    var
        BC14Customer: Record "BC14 Customer";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        Success: Boolean;
    begin
        Success := true;
        if not IsEnabled() then
            exit(true);

        if BC14Customer.FindSet() then
            repeat
                if not TryMigrateCustomer(BC14Customer) then begin
                    BC14MigrationErrorHandler.LogError(GetName(), Database::"BC14 Customer", 'BC14 Customer', BC14Customer."No.", Database::Customer, GetLastErrorText(), BC14Customer.RecordId);
                    Success := false;
                    if StopOnFirstError then
                        exit(false);
                    ClearLastError();
                end;
            until BC14Customer.Next() = 0;

        exit(Success);
    end;

    [TryFunction]
    local procedure TryMigrateCustomer(BC14Customer: Record "BC14 Customer")
    begin
        MigrateCustomer(BC14Customer);
    end;

    internal procedure MigrateCustomer(BC14Customer: Record "BC14 Customer")
    var
        Customer: Record Customer;
    begin
        if not Customer.Get(BC14Customer."No.") then begin
            Customer.Init();
            Customer."No." := BC14Customer."No.";
            Customer.Insert(true);
        end;

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
        Customer.Validate("Currency Code", BC14Customer."Currency Code");
        Customer.Validate("Language Code", BC14Customer."Language Code");
        Customer."Credit Limit (LCY)" := BC14Customer."Credit Limit (LCY)";
        Customer.Blocked := BC14Customer.Blocked;

        OnTransferCustomerCustomFields(BC14Customer, Customer);

        Customer.Modify(true);
    end;

    /// <summary>
    /// Integration event raised during customer migration to allow mapping of custom fields.
    /// Subscribe to this event to transfer TableExtension fields from BC14 Customer to Customer.
    /// </summary>
    /// <param name="BC14Customer">The source BC14 Customer record.</param>
    /// <param name="Customer">The target Customer record (modifiable).</param>
    [IntegrationEvent(false, false)]
    local procedure OnTransferCustomerCustomFields(BC14Customer: Record "BC14 Customer"; var Customer: Record Customer)
    begin
    end;

    procedure RetryFailedRecords(StopOnFirstError: Boolean): Boolean
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14Customer: Record "BC14 Customer";
        Success: Boolean;
    begin
        Success := true;
        BC14MigrationErrors.SetRange("Source Table ID", Database::"BC14 Customer");
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        BC14MigrationErrors.SetRange("Scheduled For Retry", true);
        BC14MigrationErrors.SetRange("Resolved", false);

        if BC14MigrationErrors.FindSet() then
            repeat
                if BC14Customer.Get(BC14MigrationErrors."Source Record Key") then
                    if TryMigrateCustomer(BC14Customer) then
                        BC14MigrationErrors.MarkAsResolved('Migrated successfully on retry')
                    else begin
                        BC14MigrationErrors."Retry Count" += 1;
                        BC14MigrationErrors."Last Retry On" := CurrentDateTime();
                        BC14MigrationErrors."Error Message" := CopyStr(GetLastErrorText(), 1, 250);
                        BC14MigrationErrors.Modify();
                        Success := false;
                        if StopOnFirstError then
                            exit(false);
                        ClearLastError();
                    end;
            until BC14MigrationErrors.Next() = 0;

        exit(Success);
    end;

    procedure GetRecordCount(): Integer
    var
        BC14Customer: Record "BC14 Customer";
    begin
        exit(BC14Customer.Count());
    end;
}
