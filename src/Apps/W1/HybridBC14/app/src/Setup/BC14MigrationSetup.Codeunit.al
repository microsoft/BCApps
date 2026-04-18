// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.DataMigration;

codeunit 50151 "BC14 Migration Setup"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Sets up replication table mappings for Master Data, Transaction, and Historical tables.
    /// These are the main data tables that are replicated during the cloud migration.
    /// </summary>
    procedure SetupReplicationTableMappings()
    var
        HybridCompany: Record "Hybrid Company";
    begin
        HybridCompany.SetRange(Replicate, true);
        if HybridCompany.FindSet() then
            repeat
                // 1. Master Data tables - copy to buffer tables for transformation
                InsertPerCompanyMapping(HybridCompany.Name, ItemLbl, ItemBC14Lbl, true);
                InsertPerCompanyMapping(HybridCompany.Name, CustomerLbl, CustomerBC14Lbl, true);
                InsertPerCompanyMapping(HybridCompany.Name, VendorLbl, VendorBC14Lbl, true);
                InsertPerCompanyMapping(HybridCompany.Name, GLAccountLbl, GLAccountBC14Lbl, true);

                // 2. Transaction tables - copy to buffer tables for journal creation
                InsertPerCompanyMapping(HybridCompany.Name, GLEntryLbl, BC14GLEntryLbl, true);

                // 3. Historical data - Posted documents archived for read-only access
                InsertPerCompanyMapping(HybridCompany.Name, SalesInvoiceHeaderLbl, BC14PostedSalesInvHeaderLbl, true);
                InsertPerCompanyMapping(HybridCompany.Name, SalesInvoiceLineLbl, BC14PostedSalesInvLineLbl, true);

                OnAfterSetupReplicationMappings(HybridCompany.Name);
            until HybridCompany.Next() = 0;

        // Per-database mappings
        InsertPerDatabaseSetupRecord(TenantMediaLbl, TenantMediaLbl);

        OnAfterSetupReplicationTableMapping();
    end;

    /// <summary>
    /// Sets up migration setup table mappings for Setup/Configuration tables.
    /// These are the foundational configuration tables needed before migrating master data.
    /// </summary>
    procedure SetupMigrationSetupTableMappings()
    var
        HybridCompany: Record "Hybrid Company";
    begin
        HybridCompany.SetRange(Replicate, true);
        if HybridCompany.FindSet() then
            repeat
                // Setup tables - copy to buffer tables for controlled migration
                InsertPerCompanyMapping(HybridCompany.Name, DimensionLbl, DimensionBC14Lbl, true);
                InsertPerCompanyMapping(HybridCompany.Name, DimensionValueLbl, DimensionValueBC14Lbl, true);
                InsertPerCompanyMapping(HybridCompany.Name, PaymentTermsLbl, PaymentTermsBC14Lbl, true);
                InsertPerCompanyMapping(HybridCompany.Name, PaymentMethodLbl, PaymentMethodBC14Lbl, true);
                InsertPerCompanyMapping(HybridCompany.Name, CurrencyLbl, CurrencyBC14Lbl, true);
                InsertPerCompanyMapping(HybridCompany.Name, CurrencyExchangeRateLbl, CurrencyExchangeRateBC14Lbl, true);
                InsertPerCompanyMapping(HybridCompany.Name, AccountingPeriodLbl, AccountingPeriodBC14Lbl, true);

                OnAfterSetupMigrationSetupMappings(HybridCompany.Name);
            until HybridCompany.Next() = 0;

        OnAfterSetupMigrationSetupTableMapping();
    end;

    local procedure InsertPerCompanyMapping(CompanyName: Text; SourceTableName: Text[128]; DestinationTableName: Text[128]; IsExtensionTable: Boolean)
    var
        ExistingReplicationMapping: Record "Replication Table Mapping";
        ReplicationMapping: Record "Replication Table Mapping";
        BC14MigrationProvider: Codeunit "BC14 Migration Provider";
        DestinationSqlName: Text;
        AppIdSuffix: Text[50];
    begin
        ReplicationMapping."Source Sql Table Name" := CopyStr(ConvertStr(CompanyName + '$' + SourceTableName, InvalidSqlCharactersTok, ValidSqlReplacementTok), 1, MaxStrLen(ReplicationMapping."Source Sql Table Name"));

        // Both extension tables and base app tables need App ID suffix in BC Online
        // Extension tables use this app's ID, base app tables use Microsoft Base Application ID
        if IsExtensionTable then
            AppIdSuffix := CopyStr(Format(BC14MigrationProvider.GetAppId()).TrimEnd('}').TrimStart('{').ToLower(), 1, MaxStrLen(AppIdSuffix))
        else
            AppIdSuffix := BaseAppIdTok; // Microsoft Base Application ID

        DestinationSqlName := CompanyName + '$' + DestinationTableName + '$' + AppIdSuffix;
        ReplicationMapping."Destination Sql Table Name" := CopyStr(ConvertStr(DestinationSqlName, InvalidSqlCharactersTok, ValidSqlReplacementTok), 1, MaxStrLen(ReplicationMapping."Destination Sql Table Name"));
        ReplicationMapping."Company Name" := CopyStr(CompanyName, 1, MaxStrLen(ReplicationMapping."Company Name"));
        ReplicationMapping."Table Name" := DestinationTableName;
        ReplicationMapping."Preserve Cloud Data" := false;
        if ExistingReplicationMapping.Get(ReplicationMapping.RecordId) then
            exit;

        ReplicationMapping.Insert(true);
    end;

    local procedure InsertPerDatabaseSetupRecord(SourceTableName: Text[128]; DestinationTableName: Text[128])
    var
        ExistingReplicationMapping: Record "Replication Table Mapping";
        ReplicationMapping: Record "Replication Table Mapping";
    begin
        ReplicationMapping."Source Sql Table Name" := SourceTableName;
        ReplicationMapping."Destination Sql Table Name" := DestinationTableName;
        ReplicationMapping."Company Name" := '';
        ReplicationMapping."Table Name" := DestinationTableName;
        ReplicationMapping."Preserve Cloud Data" := true;
        if ExistingReplicationMapping.Get(ReplicationMapping.RecordId) then
            exit;

        ReplicationMapping.Insert(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupReplicationTableMapping()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupReplicationMappings(CompanyName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupMigrationSetupTableMapping()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupMigrationSetupMappings(CompanyName: Text)
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"Intelligent Cloud Management", 'OnOpenNewUI', '', false, false)]
    local procedure HandleOnOpenNewUI(var OpenNewUI: Boolean)
    var
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        if BC14Wizard.GetBC14MigrationEnabled() then
            OpenNewUI := true;
    end;

    var
        // Setup tables (source table names)
        DimensionLbl: Label 'Dimension', Locked = true;
        DimensionValueLbl: Label 'Dimension Value', Locked = true;
        PaymentTermsLbl: Label 'Payment Terms', Locked = true;
        PaymentMethodLbl: Label 'Payment Method', Locked = true;
        CurrencyLbl: Label 'Currency', Locked = true;
        CurrencyExchangeRateLbl: Label 'Currency Exchange Rate', Locked = true;
        AccountingPeriodLbl: Label 'Accounting Period', Locked = true;
        // Master data tables
        CustomerLbl: Label 'Customer', Locked = true;
        ItemLbl: Label 'Item', Locked = true;
        VendorLbl: Label 'Vendor', Locked = true;
        GLAccountLbl: Label 'G/L Account', Locked = true;
        GLEntryLbl: Label 'G/L Entry', Locked = true;
        // Historical data tables (source table names)
        SalesInvoiceHeaderLbl: Label 'Sales Invoice Header', Locked = true;
        SalesInvoiceLineLbl: Label 'Sales Invoice Line', Locked = true;
        // Buffer table names - Setup
        DimensionBC14Lbl: Label 'BC14 Dimension', Locked = true;
        DimensionValueBC14Lbl: Label 'BC14 Dimension Value', Locked = true;
        PaymentTermsBC14Lbl: Label 'BC14 Payment Terms', Locked = true;
        PaymentMethodBC14Lbl: Label 'BC14 Payment Method', Locked = true;
        CurrencyBC14Lbl: Label 'BC14 Currency', Locked = true;
        CurrencyExchangeRateBC14Lbl: Label 'BC14 Currency Exchange Rate', Locked = true;
        AccountingPeriodBC14Lbl: Label 'BC14 Accounting Period', Locked = true;
        // Buffer table names - Master Data
        CustomerBC14Lbl: Label 'BC14 Customer', Locked = true;
        ItemBC14Lbl: Label 'BC14 Item', Locked = true;
        VendorBC14Lbl: Label 'BC14 Vendor', Locked = true;
        GLAccountBC14Lbl: Label 'BC14 G/L Account', Locked = true;
        BC14GLEntryLbl: Label 'BC14 G/L Entry', Locked = true;
        // Buffer table names - Historical Data
        BC14PostedSalesInvHeaderLbl: Label 'BC14 Posted Sales Inv Header', Locked = true;
        BC14PostedSalesInvLineLbl: Label 'BC14 Posted Sales Inv Line', Locked = true;
        // Other
        TenantMediaLbl: Label 'Tenant Media', Locked = true;
        InvalidSqlCharactersTok: Label '.\/', Locked = true;
        ValidSqlReplacementTok: Label '___', Locked = true;
        // Microsoft Base Application ID - used for system table destinations in BC Online
        BaseAppIdTok: Label '437dbf0e-84ff-417a-965d-ed2bb9650972', Locked = true;
}
