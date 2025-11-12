namespace Microsoft.API.Upgrade;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Shipping;
using Microsoft.Integration.Graph;
using Microsoft.Integration.Entity;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Upgrade;
using System.Environment;
using System.Upgrade;
using Microsoft.Sales.Customer;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;
using Microsoft.HumanResources.Employee;

codeunit 9994 "API Data Upgrade"
{

    Permissions = TableData "Sales Shipment Header" = rm,
                  TableData "Sales Shipment Line" = rm,
                  TableData "Purch. Rcpt. Header" = r,
                  TableData "Purch. Rcpt. Line" = rm;

    trigger OnRun()
    var
        APIDataUpgrade: Record "API Data Upgrade";
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        GraphMgtCustomer: Codeunit "Graph Mgt - Customer";
        GraphMgtCustomerPayments: Codeunit "Graph Mgt - Customer Payments";
        GraphMgtJournalLines: Codeunit "Graph Mgt - Journal Lines";
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
        GraphMgtSalesHeader: Codeunit "Graph Mgt - Sales Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        GraphMgtSalesOrderBuffer: Codeunit "Graph Mgt - Sales Order Buffer";
        GraphMgtSalesQuoteBuffer: Codeunit "Graph Mgt - Sales Quote Buffer";
        GraphMgtVendor: Codeunit "Graph Mgt - Vendor";
        GraphMgtVendorPayments: Codeunit "Graph Mgt - Vendor Payments";
        GraphMgtPurchOrderBuffer: Codeunit "Graph Mgt - Purch Order Buffer";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        APIDataUpgrade.SetRange(Status, APIDataUpgrade.Status::Scheduled);
        if APIDataUpgrade.FindSet() then
            repeat
                case APIDataUpgrade."Upgrade Tag" of
                    'ITEMS':
                        begin
                            GraphCollectionMgtItem.UpdateIds(true);
                            UpgradeItemPostingGroups(false);
                            SetStatus(APIDataUpgrade, APIDataUpgrade.Status::Completed);
                        end;
                    'CUSTOMERS':
                        begin
                            GraphMgtCustomer.UpdateIds(true);
                            SetStatus(APIDataUpgrade, APIDataUpgrade.Status::Completed);
                        end;
                    'CUSTOMER PAYMENTS':
                        begin
                            GraphMgtCustomerPayments.UpdateIds(true);
                            SetStatus(APIDataUpgrade, APIDataUpgrade.Status::Completed);
                        end;
                    'JOURNALS':
                        begin
                            GraphMgtJournalLines.UpdateIds(true);
                            SetStatus(APIDataUpgrade, APIDataUpgrade.Status::Completed);
                        end;
                    'PURCHASE INVOICES':
                        begin
                            PurchInvAggregator.UpdateAggregateTableRecords();
                            PurchInvAggregator.FixInvoicesCreatedFromOrders();
                            UpgradePurchInvoiceShortcutDimension(false);
                            SetStatus(APIDataUpgrade, APIDataUpgrade.Status::Completed);
                        end;
                    'SALES CREDIT MEMOS':
                        begin
                            GraphMgtSalCrMemoBuf.UpdateBufferTableRecords();
                            UpgradeSalesCrMemoShortcutDimension(false);
                            UpgradeSalesCreditMemoReasonCode(false);
                            UpgradeSalesCrMemoShipmentMethod();
                            SetStatus(APIDataUpgrade, APIDataUpgrade.Status::Completed);
                        end;
                    'SALES INVOICES':
                        begin
                            SalesInvoiceAggregator.UpdateAggregateTableRecords();
                            GraphMgtSalesHeader.UpdateIds(true);
                            SalesInvoiceAggregator.FixInvoicesCreatedFromOrders();
                            UpgradeSalesInvoiceShortcutDimension(false);
                            SetStatus(APIDataUpgrade, APIDataUpgrade.Status::Completed);
                        end;
                    'SALES ORDERS':
                        begin
                            GraphMgtSalesOrderBuffer.UpdateBufferTableRecords();
                            GraphMgtSalesOrderBuffer.DeleteOrphanedRecords();
                            UpgradeSalesOrderShortcutDimension(false);
                            UpgradeSalesOrderShipmentMethod();
                            SetStatus(APIDataUpgrade, APIDataUpgrade.Status::Completed);
                        end;
                    'SALES QUOTES':
                        begin
                            GraphMgtSalesQuoteBuffer.UpdateBufferTableRecords();
                            UpgradeSalesQuoteShortcutDimension(false);
                            SetStatus(APIDataUpgrade, APIDataUpgrade.Status::Completed);
                        end;
                    'VENDORS':
                        begin
                            GraphMgtVendor.UpdateIds(true);
                            SetStatus(APIDataUpgrade, APIDataUpgrade.Status::Completed);
                        end;
                    'VENDOR PAYMENTS':
                        begin
                            GraphMgtVendorPayments.UpdateIds(true);
                            SetStatus(APIDataUpgrade, APIDataUpgrade.Status::Completed);
                        end;
                    'SALES SHIPMENTS':
                        begin
                            UpgradeSalesShipmentLineDocumentId(false);
                            UpgradeSalesShipmentCustomerId();
                            SetStatus(APIDataUpgrade, APIDataUpgrade.Status::Completed);
                        end;
                    'PURCHASE ORDERS':
                        begin
                            GraphMgtPurchOrderBuffer.UpdateBufferTableRecords();
                            GraphMgtPurchOrderBuffer.DeleteOrphanedRecords();
                            UpgradePurchaseOrderShortcutDimension(false);
                            SetStatus(APIDataUpgrade, APIDataUpgrade.Status::Completed);
                        end;
                    'ITEM VARIANTS':
                        begin
                            UpdateItemVariants();
                            SetStatus(APIDataUpgrade, APIDataUpgrade.Status::Completed);
                        end;
                    'DEFAULT DIMENSIONS':
                        begin
                            UpgradeDefaultDimensions();
                            SetStatus(APIDataUpgrade, APIDataUpgrade.Status::Completed);
                        end;
                    'DIMENSION VALUES':
                        begin
                            UpgradeDimensionValues();
                            SetStatus(APIDataUpgrade, APIDataUpgrade.Status::Completed);
                        end;
                    'ACCOUNTS':
                        begin
                            UpgradeGLAccountAPIType();
                            SetStatus(APIDataUpgrade, APIDataUpgrade.Status::Completed);
                        end;
                    'PURCHASE RECEIPTS':
                        begin
                            UpgradePurchRcptLineDocumentId(false);
                            SetStatus(APIDataUpgrade, APIDataUpgrade.Status::Completed);
                        end;
                    'PURCHASE CREDIT MEMOS':
                        begin
                            UpgradePurchaseCreditMemoBuffer();
                            UpgradePurchaseCreditMemoVendorCrMemoNo();
                            SetStatus(APIDataUpgrade, APIDataUpgrade.Status::Completed);
                        end;
                    'FIXED ASSETS':
                        begin
                            UpgradeFixedAssetLocationId();
                            UpgradeFixedAssetResponsibleEmployeeId();
                            SetStatus(APIDataUpgrade, APIDataUpgrade.Status::Completed);
                        end;
                    else
                        OnAPIDataUpgrade(APIDataUpgrade."Upgrade Tag");
                end;
            until APIDataUpgrade.Next() = 0;

        APIDataUpgrade.SetFilter(Status, '<>%1', APIDataUpgrade.Status::Completed);
        if APIDataUpgrade.IsEmpty() then
            UpgradeTag.SetSkippedUpgrade(GetDisableAPIDataUpgradesTag(), false);
    end;

    var
        UpgradeSkippedDueToManyRecordsLbl: Label 'Upgrade procedure %1 skipped due to %2 number of %3 records.', Comment = '%1 = Procedure name, %2 = Number of records, %3 = Table name', Locked = true;

    procedure UpgradeSalesCreditMemoReasonCode(CheckRecordCount: Boolean)
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        EnvironmentInformation: Codeunit "Environment Information";
        RecordCount: Integer;
    begin
        if CheckRecordCount then
            if EnvironmentInformation.IsSaaS() then
                if SalesCrMemoEntityBuffer.Count() > GetSafeRecordCountForSaaSUpgrade() then
                    exit;

        SalesCrMemoEntityBuffer.SetLoadFields(SalesCrMemoEntityBuffer.Id);
        if SalesCrMemoEntityBuffer.FindSet(true) then begin
            repeat
                if SalesCrMemoEntityBuffer.Posted then begin
                    SalesCrMemoHeader.SetLoadFields(SalesCrMemoHeader."Reason Code");
                    if SalesCrMemoHeader.GetBySystemId(SalesCrMemoEntityBuffer.Id) then begin
                        UpdateSalesCreditMemoReasonCodeFields(SalesCrMemoHeader."Reason Code", SalesCrMemoEntityBuffer);
                        CountRecordsAndCommit(RecordCount);
                    end;
                end else begin
                    SalesHeader.SetLoadFields(SalesHeader."Reason Code");
                    if SalesHeader.GetBySystemId(SalesCrMemoEntityBuffer.Id) then begin
                        UpdateSalesCreditMemoReasonCodeFields(SalesHeader."Reason Code", SalesCrMemoEntityBuffer);
                        CountRecordsAndCommit(RecordCount);
                    end;
                end;
            until SalesCrMemoEntityBuffer.Next() = 0;

            Commit();
        end;
    end;

    procedure UpgradeSalesInvoiceShortcutDimension(CheckRecordCount: Boolean)
    var
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        EnvironmentInformation: Codeunit "Environment Information";
        Modified: Boolean;
        RecordCount: Integer;
    begin
        SalesInvoiceEntityAggregate.SetLoadFields(Id, "No.", Posted, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if SalesInvoiceEntityAggregate.FindSet(true) then begin
            if CheckRecordCount then
                if EnvironmentInformation.IsSaaS() then
                    if SalesInvoiceEntityAggregate.Count() > GetSafeRecordCountForSaaSUpgrade() then begin
                        Session.LogMessage('0000GAQ', StrSubstNo(UpgradeSkippedDueToManyRecordsLbl, 'UpgradeSalesInvoiceShortcutDimension', SalesInvoiceEntityAggregate.TableName(), SalesInvoiceEntityAggregate.Count()), Verbosity::Warning,
                        DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');
                        exit;
                    end;
            repeat
                if SalesInvoiceEntityAggregate.Posted then begin
                    SalesInvoiceHeader.SetLoadFields("No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                    if SalesInvoiceHeader.Get(SalesInvoiceEntityAggregate."No.") then begin
                        if SalesInvoiceHeader."Shortcut Dimension 1 Code" <> '' then
                            if SalesInvoiceHeader."Shortcut Dimension 1 Code" <> SalesInvoiceEntityAggregate."Shortcut Dimension 1 Code" then begin
                                SalesInvoiceEntityAggregate."Shortcut Dimension 1 Code" := SalesInvoiceHeader."Shortcut Dimension 1 Code";
                                Modified := true;
                            end;
                        if SalesInvoiceHeader."Shortcut Dimension 2 Code" <> '' then
                            if SalesInvoiceHeader."Shortcut Dimension 2 Code" <> SalesInvoiceEntityAggregate."Shortcut Dimension 2 Code" then begin
                                SalesInvoiceEntityAggregate."Shortcut Dimension 2 Code" := SalesInvoiceHeader."Shortcut Dimension 2 Code";
                                Modified := true;
                            end;
                        if Modified then begin
                            SalesInvoiceEntityAggregate.Modify();
                            CountRecordsAndCommit(RecordCount);
                        end;
                    end;
                end else begin
                    SalesHeader.SetLoadFields("No.", "Document Type", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                    if SalesHeader.Get(SalesHeader."Document Type"::Invoice, SalesInvoiceEntityAggregate."No.") then begin
                        if SalesHeader."Shortcut Dimension 1 Code" <> '' then
                            if SalesHeader."Shortcut Dimension 1 Code" <> SalesInvoiceEntityAggregate."Shortcut Dimension 1 Code" then begin
                                SalesInvoiceEntityAggregate."Shortcut Dimension 1 Code" := SalesHeader."Shortcut Dimension 1 Code";
                                Modified := true;
                            end;
                        if SalesHeader."Shortcut Dimension 2 Code" <> '' then
                            if SalesHeader."Shortcut Dimension 2 Code" <> SalesInvoiceEntityAggregate."Shortcut Dimension 2 Code" then begin
                                SalesInvoiceEntityAggregate."Shortcut Dimension 2 Code" := SalesHeader."Shortcut Dimension 2 Code";
                                Modified := true;
                            end;
                        if Modified then begin
                            SalesInvoiceEntityAggregate.Modify();
                            CountRecordsAndCommit(RecordCount);
                        end;
                    end;
                end;
            until SalesInvoiceEntityAggregate.Next() = 0;

            Commit();
        end;
    end;

    procedure UpgradePurchInvoiceShortcutDimension(CheckRecordCount: Boolean)
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        EnvironmentInformation: Codeunit "Environment Information";
        Modified: Boolean;
        RecordCount: Integer;
    begin
        PurchInvEntityAggregate.SetLoadFields(Id, "No.", Posted, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if PurchInvEntityAggregate.FindSet(true) then begin
            if CheckRecordCount then
                if EnvironmentInformation.IsSaaS() then
                    if PurchInvEntityAggregate.Count() > GetSafeRecordCountForSaaSUpgrade() then begin
                        Session.LogMessage('0000GAR', StrSubstNo(UpgradeSkippedDueToManyRecordsLbl, 'UpgradePurchInvoiceShortcutDimension', PurchInvEntityAggregate.TableName(), PurchInvEntityAggregate.Count()), Verbosity::Warning,
                        DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');
                        exit;
                    end;
            repeat
                if PurchInvEntityAggregate.Posted then begin
                    PurchInvHeader.SetLoadFields("No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                    if PurchInvHeader.Get(PurchInvEntityAggregate."No.") then begin
                        if PurchInvHeader."Shortcut Dimension 1 Code" <> '' then
                            if PurchInvHeader."Shortcut Dimension 1 Code" <> PurchInvEntityAggregate."Shortcut Dimension 1 Code" then begin
                                PurchInvEntityAggregate."Shortcut Dimension 1 Code" := PurchInvHeader."Shortcut Dimension 1 Code";
                                Modified := true;
                            end;
                        if PurchInvHeader."Shortcut Dimension 2 Code" <> '' then
                            if PurchInvHeader."Shortcut Dimension 2 Code" <> PurchInvEntityAggregate."Shortcut Dimension 2 Code" then begin
                                PurchInvEntityAggregate."Shortcut Dimension 2 Code" := PurchInvHeader."Shortcut Dimension 2 Code";
                                Modified := true;
                            end;
                        if Modified then begin
                            PurchInvEntityAggregate.Modify();
                            CountRecordsAndCommit(RecordCount);
                        end;
                    end;
                end else begin
                    PurchaseHeader.SetLoadFields("No.", "Document Type", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                    if PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, PurchInvEntityAggregate."No.") then begin
                        if PurchaseHeader."Shortcut Dimension 1 Code" <> '' then
                            if PurchaseHeader."Shortcut Dimension 1 Code" <> PurchInvEntityAggregate."Shortcut Dimension 1 Code" then begin
                                PurchInvEntityAggregate."Shortcut Dimension 1 Code" := PurchaseHeader."Shortcut Dimension 1 Code";
                                Modified := true;
                            end;
                        if PurchaseHeader."Shortcut Dimension 2 Code" <> '' then
                            if PurchaseHeader."Shortcut Dimension 2 Code" <> PurchInvEntityAggregate."Shortcut Dimension 2 Code" then begin
                                PurchInvEntityAggregate."Shortcut Dimension 2 Code" := PurchaseHeader."Shortcut Dimension 2 Code";
                                Modified := true;
                            end;
                        if Modified then begin
                            PurchInvEntityAggregate.Modify();
                            CountRecordsAndCommit(RecordCount);
                        end;
                    end;
                end;
            until PurchInvEntityAggregate.Next() = 0;

            Commit();
        end;
    end;

    procedure UpgradePurchaseOrderShortcutDimension(CheckRecordCount: Boolean)
    var
        PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
        PurchaseHeader: Record "Purchase Header";
        EnvironmentInformation: Codeunit "Environment Information";
        Modified: Boolean;
        RecordCount: Integer;
    begin
        PurchaseOrderEntityBuffer.SetLoadFields(Id, "No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if PurchaseOrderEntityBuffer.FindSet(true) then begin
            if CheckRecordCount then
                if EnvironmentInformation.IsSaaS() then
                    if PurchaseOrderEntityBuffer.Count() > GetSafeRecordCountForSaaSUpgrade() then begin
                        Session.LogMessage('0000GAS', StrSubstNo(UpgradeSkippedDueToManyRecordsLbl, 'UpgradePurchaseOrderShortcutDimension', PurchaseOrderEntityBuffer.TableName(), PurchaseOrderEntityBuffer.Count()), Verbosity::Warning,
                        DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');
                        exit;
                    end;
            repeat
                PurchaseHeader.SetLoadFields("No.", "Document Type", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseOrderEntityBuffer."No.") then begin
                    if PurchaseHeader."Shortcut Dimension 1 Code" <> '' then
                        if PurchaseHeader."Shortcut Dimension 1 Code" <> PurchaseOrderEntityBuffer."Shortcut Dimension 1 Code" then begin
                            PurchaseOrderEntityBuffer."Shortcut Dimension 1 Code" := PurchaseHeader."Shortcut Dimension 1 Code";
                            Modified := true;
                        end;
                    if PurchaseHeader."Shortcut Dimension 2 Code" <> '' then
                        if PurchaseHeader."Shortcut Dimension 2 Code" <> PurchaseOrderEntityBuffer."Shortcut Dimension 2 Code" then begin
                            PurchaseOrderEntityBuffer."Shortcut Dimension 2 Code" := PurchaseHeader."Shortcut Dimension 2 Code";
                            Modified := true;
                        end;
                    if Modified then begin
                        PurchaseOrderEntityBuffer.Modify();
                        CountRecordsAndCommit(RecordCount);
                    end;
                end;
            until PurchaseOrderEntityBuffer.Next() = 0;

            Commit();
        end;
    end;

    procedure UpgradeSalesOrderShortcutDimension(CheckRecordCount: Boolean)
    var
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        SalesHeader: Record "Sales Header";
        EnvironmentInformation: Codeunit "Environment Information";
        Modified: Boolean;
        RecordCount: Integer;
    begin
        SalesOrderEntityBuffer.SetLoadFields(Id, "No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if SalesOrderEntityBuffer.FindSet(true) then begin
            if CheckRecordCount then
                if EnvironmentInformation.IsSaaS() then
                    if SalesOrderEntityBuffer.Count() > GetSafeRecordCountForSaaSUpgrade() then begin
                        Session.LogMessage('0000GAT', StrSubstNo(UpgradeSkippedDueToManyRecordsLbl, 'UpgradeSalesOrderShortcutDimension', SalesOrderEntityBuffer.TableName(), SalesOrderEntityBuffer.Count()), Verbosity::Warning,
                        DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');
                        exit;
                    end;
            repeat
                SalesHeader.SetLoadFields("No.", "Document Type", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                if SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderEntityBuffer."No.") then begin
                    if SalesHeader."Shortcut Dimension 1 Code" <> '' then
                        if SalesHeader."Shortcut Dimension 1 Code" <> SalesOrderEntityBuffer."Shortcut Dimension 1 Code" then begin
                            SalesOrderEntityBuffer."Shortcut Dimension 1 Code" := SalesHeader."Shortcut Dimension 1 Code";
                            Modified := true;
                        end;
                    if SalesHeader."Shortcut Dimension 2 Code" <> '' then
                        if SalesHeader."Shortcut Dimension 2 Code" <> SalesOrderEntityBuffer."Shortcut Dimension 2 Code" then begin
                            SalesOrderEntityBuffer."Shortcut Dimension 2 Code" := SalesHeader."Shortcut Dimension 2 Code";
                            Modified := true;
                        end;
                    if Modified then begin
                        SalesOrderEntityBuffer.Modify();
                        CountRecordsAndCommit(RecordCount);
                    end;
                end;
            until SalesOrderEntityBuffer.Next() = 0;

            Commit();
        end;
    end;

    procedure UpgradeSalesQuoteShortcutDimension(CheckRecordCount: Boolean)
    var
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        SalesHeader: Record "Sales Header";
        EnvironmentInformation: Codeunit "Environment Information";
        Modified: Boolean;
        RecordCount: Integer;
    begin
        SalesQuoteEntityBuffer.SetLoadFields(Id, "No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if SalesQuoteEntityBuffer.FindSet(true) then begin
            if CheckRecordCount then
                if EnvironmentInformation.IsSaaS() then
                    if SalesQuoteEntityBuffer.Count() > GetSafeRecordCountForSaaSUpgrade() then begin
                        Session.LogMessage('0000GAU', StrSubstNo(UpgradeSkippedDueToManyRecordsLbl, 'UpgradeSalesQuoteShortcutDimension', SalesQuoteEntityBuffer.TableName(), SalesQuoteEntityBuffer.Count()), Verbosity::Warning,
                        DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');
                        exit;
                    end;
            repeat
                SalesHeader.SetLoadFields("No.", "Document Type", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                if SalesHeader.Get(SalesHeader."Document Type"::Quote, SalesQuoteEntityBuffer."No.") then begin
                    if SalesHeader."Shortcut Dimension 1 Code" <> '' then
                        if SalesHeader."Shortcut Dimension 1 Code" <> SalesQuoteEntityBuffer."Shortcut Dimension 1 Code" then begin
                            SalesQuoteEntityBuffer."Shortcut Dimension 1 Code" := SalesHeader."Shortcut Dimension 1 Code";
                            Modified := true;
                        end;
                    if SalesHeader."Shortcut Dimension 2 Code" <> '' then
                        if SalesHeader."Shortcut Dimension 2 Code" <> SalesQuoteEntityBuffer."Shortcut Dimension 2 Code" then begin
                            SalesQuoteEntityBuffer."Shortcut Dimension 2 Code" := SalesHeader."Shortcut Dimension 2 Code";
                            Modified := true;
                        end;
                    if Modified then begin
                        SalesQuoteEntityBuffer.Modify();
                        CountRecordsAndCommit(RecordCount);
                    end;
                end;
            until SalesQuoteEntityBuffer.Next() = 0;

            Commit();
        end;
    end;

    procedure UpgradeSalesCrMemoShortcutDimension(CheckRecordCount: Boolean)
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        EnvironmentInformation: Codeunit "Environment Information";
        Modified: Boolean;
        RecordCount: Integer;
    begin
        SalesCrMemoEntityBuffer.SetLoadFields(Id, "No.", Posted, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if SalesCrMemoEntityBuffer.FindSet(true) then begin
            if CheckRecordCount then
                if EnvironmentInformation.IsSaaS() then
                    if SalesCrMemoEntityBuffer.Count() > GetSafeRecordCountForSaaSUpgrade() then begin
                        Session.LogMessage('0000GAV', StrSubstNo(UpgradeSkippedDueToManyRecordsLbl, 'UpgradeSalesCrMemoShortcutDimension', SalesCrMemoEntityBuffer.TableName(), SalesCrMemoEntityBuffer.Count()), Verbosity::Warning,
                        DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');
                        exit;
                    end;
            repeat
                if SalesCrMemoEntityBuffer.Posted then begin
                    SalesCrMemoHeader.SetLoadFields("No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                    if SalesCrMemoHeader.Get(SalesCrMemoEntityBuffer."No.") then begin
                        if SalesCrMemoHeader."Shortcut Dimension 1 Code" <> '' then
                            if SalesCrMemoHeader."Shortcut Dimension 1 Code" <> SalesCrMemoEntityBuffer."Shortcut Dimension 1 Code" then begin
                                SalesCrMemoEntityBuffer."Shortcut Dimension 1 Code" := SalesCrMemoHeader."Shortcut Dimension 1 Code";
                                Modified := true;
                            end;
                        if SalesCrMemoHeader."Shortcut Dimension 2 Code" <> '' then
                            if SalesCrMemoHeader."Shortcut Dimension 2 Code" <> SalesCrMemoEntityBuffer."Shortcut Dimension 2 Code" then begin
                                SalesCrMemoEntityBuffer."Shortcut Dimension 2 Code" := SalesCrMemoHeader."Shortcut Dimension 2 Code";
                                Modified := true;
                            end;
                        if Modified then begin
                            SalesCrMemoEntityBuffer.Modify();
                            CountRecordsAndCommit(RecordCount);
                        end;
                    end;
                end else begin
                    SalesHeader.SetLoadFields("No.", "Document Type", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                    if SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", SalesCrMemoEntityBuffer."No.") then begin
                        if SalesHeader."Shortcut Dimension 1 Code" <> '' then
                            if SalesHeader."Shortcut Dimension 1 Code" <> SalesCrMemoEntityBuffer."Shortcut Dimension 1 Code" then begin
                                SalesCrMemoEntityBuffer."Shortcut Dimension 1 Code" := SalesHeader."Shortcut Dimension 1 Code";
                                Modified := true;
                            end;
                        if SalesHeader."Shortcut Dimension 2 Code" <> '' then
                            if SalesHeader."Shortcut Dimension 2 Code" <> SalesCrMemoEntityBuffer."Shortcut Dimension 2 Code" then begin
                                SalesCrMemoEntityBuffer."Shortcut Dimension 2 Code" := SalesHeader."Shortcut Dimension 2 Code";
                                Modified := true;
                            end;
                        if Modified then begin
                            SalesCrMemoEntityBuffer.Modify();
                            CountRecordsAndCommit(RecordCount);
                        end;
                    end;
                end;
            until SalesCrMemoEntityBuffer.Next() = 0;

            Commit();
        end;
    end;

    procedure UpgradeItemPostingGroups(CheckRecordCount: Boolean)
    var
        Item: Record "Item";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        InventoryPostingGroup: Record "Inventory Posting Group";
        EnvironmentInformation: Codeunit "Environment Information";
        ItemModified: Boolean;
        RecordCount: Integer;
    begin
        Item.SetLoadFields("Gen. Prod. Posting Group", "Inventory Posting Group");
        if Item.FindSet() then begin
            if CheckRecordCount then
                if EnvironmentInformation.IsSaaS() then
                    if Item.Count() > GetSafeRecordCountForSaaSUpgrade() then begin
                        Session.LogMessage('0000GWC', StrSubstNo(UpgradeSkippedDueToManyRecordsLbl, 'GenItemPostingGroups', Item.TableName(), Item.Count()), Verbosity::Warning,
                        DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');
                        exit;
                    end;
            repeat
                ItemModified := false;
                if Item."Gen. Prod. Posting Group" <> '' then
                    if GenProdPostingGroup.Get(Item."Gen. Prod. Posting Group") then begin
                        Item."Gen. Prod. Posting Group Id" := GenProdPostingGroup.SystemId;
                        ItemModified := true;
                    end;
                if Item."Inventory Posting Group" <> '' then
                    if InventoryPostingGroup.Get(Item."Inventory Posting Group") then begin
                        Item."Inventory Posting Group Id" := InventoryPostingGroup.SystemId;
                        ItemModified := true;
                    end;
                if ItemModified then begin
                    Item.Modify(false);
                    CountRecordsAndCommit(RecordCount);
                end;
            until Item.Next() = 0;

            Commit();
        end;
    end;

    local procedure UpdateSalesCreditMemoReasonCodeFields(SourceReasonCode: Code[10]; var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer"): Boolean
    var
        ReasonCode: Record "Reason Code";
        NewReasonCodeId: Guid;
        EmptyGuid: Guid;
        Changed: Boolean;
    begin
        if SalesCrMemoEntityBuffer."Reason Code" <> SourceReasonCode then begin
            SalesCrMemoEntityBuffer."Reason Code" := SourceReasonCode;
            Changed := true;
        end;

        if SalesCrMemoEntityBuffer."Reason Code" <> '' then begin
            if ReasonCode.Get(SalesCrMemoEntityBuffer."Reason Code") then
                NewReasonCodeId := ReasonCode.SystemId
            else
                NewReasonCodeId := EmptyGuid;
        end else
            NewReasonCodeId := EmptyGuid;

        if SalesCrMemoEntityBuffer."Reason Code Id" <> NewReasonCodeId then begin
            SalesCrMemoEntityBuffer."Reason Code Id" := NewReasonCodeId;
            Changed := true;
        end;

        if Changed then
            exit(SalesCrMemoEntityBuffer.Modify());
    end;

    procedure UpgradeSalesShipmentLineDocumentId(CheckRecordCount: Boolean)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        EnvironmentInformation: codeunit "Environment Information";
        RecordCount: Integer;
    begin
        if CheckRecordCount then
            if EnvironmentInformation.IsSaaS() then
                if SalesShipmentLine.Count() > GetSafeRecordCountForSaaSUpgrade() then
                    exit;

        SalesShipmentHeader.SetLoadFields(SalesShipmentHeader."No.", SalesShipmentHeader.SystemId);
        if SalesShipmentHeader.FindSet() then begin
            repeat
                SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
                SalesShipmentLine.ModifyAll("Document Id", SalesShipmentHeader.SystemId);
                CountRecordsAndCommit(RecordCount);
            until SalesShipmentHeader.Next() = 0;

            Commit();
        end;
    end;

    procedure UpgradeSalesShipmentCustomerId()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentHeader2: Record "Sales Shipment Header";
        Customer: Record Customer;
        Modified: Boolean;
        RecordCount: Integer;
    begin
        SalesShipmentHeader.SetLoadFields("Sell-to Customer No.", "Bill-to Customer No.", "Customer Id", "Bill-to Customer Id");
        Customer.SetLoadFields("No.", SystemId);
        if SalesShipmentHeader.FindSet() then
            repeat
                if Customer.Get(SalesShipmentHeader."Sell-to Customer No.") then
                    if SalesShipmentHeader."Customer Id" <> Customer.SystemId then begin
                        SalesShipmentHeader2 := SalesShipmentHeader;
                        SalesShipmentHeader2."Customer Id" := Customer.SystemId;
                        Modified := true;
                    end;
                if Customer.Get(SalesShipmentHeader."Bill-to Customer No.") then
                    if SalesShipmentHeader."Bill-to Customer Id" <> Customer.SystemId then begin
                        if not Modified then
                            SalesShipmentHeader2 := SalesShipmentHeader;
                        SalesShipmentHeader2."Bill-to Customer Id" := Customer.SystemId;
                        Modified := true;
                    end;
                if Modified then begin
                    SalesShipmentHeader2.Modify();
                    CountRecordsAndCommit(RecordCount);
                    Modified := false;
                end;
            until SalesShipmentHeader.Next() = 0;
    end;

    procedure UpgradeFixedAssetLocationId()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FALocation: Record "FA Location";
        RecordCount: Integer;
    begin
        FixedAsset.SetLoadFields("FA Location Code", "FA Location Id");
        FALocation.SetLoadFields(Code, SystemId);
        if FixedAsset.FindSet() then
            repeat
                if FALocation.Get(FixedAsset."FA Location Code") then
                    if FixedAsset."FA Location Id" <> FALocation.SystemId then begin
                        FixedAsset2 := FixedAsset;
                        FixedAsset2."FA Location Id" := FALocation.SystemId;
                        FixedAsset2.Modify();
                        CountRecordsAndCommit(RecordCount);
                    end;
            until FixedAsset.Next() = 0;
    end;

    procedure UpgradeFixedAssetResponsibleEmployeeId()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        Employee: Record Employee;
        RecordCount: Integer;
    begin
        FixedAsset.SetLoadFields("Responsible Employee", "Responsible Employee Id");
        Employee.SetLoadFields("No.", SystemId);
        if FixedAsset.FindSet() then
            repeat
                if Employee.Get(FixedAsset."Responsible Employee") then
                    if FixedAsset."Responsible Employee Id" <> Employee.SystemId then begin
                        FixedAsset2 := FixedAsset;
                        FixedAsset2."Responsible Employee Id" := Employee.SystemId;
                        FixedAsset2.Modify();
                        CountRecordsAndCommit(RecordCount);
                    end;
            until FixedAsset.Next() = 0;
    end;

    procedure UpdateItemVariants()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
        RecordCount: Integer;
    begin
        ItemVariant.SetLoadFields("Item No.", "Item Id");
        ItemVariant2.SetLoadFields("Item No.", "Item Id");
        if ItemVariant.FindSet() then begin
            repeat
                if Item.Get(ItemVariant."Item No.") then
                    if ItemVariant."Item Id" <> Item.SystemId then begin
                        ItemVariant2 := ItemVariant;
                        ItemVariant2."Item Id" := Item.SystemId;
                        ItemVariant2.Modify();
                        CountRecordsAndCommit(RecordCount);
                    end;
            until ItemVariant.Next() = 0;

            Commit();
        end;
    end;

    procedure UpgradeDefaultDimensions()
    var
        DefaultDimension: Record "Default Dimension";
        RecordCount: Integer;
    begin
        if DefaultDimension.FindSet() then
            repeat
                DefaultDimension.UpdateReferencedIds();
                CountRecordsAndCommit(RecordCount);
            until DefaultDimension.Next() = 0;
    end;

    procedure UpgradeDimensionValues()
    var
        Dimension: Record "Dimension";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        RecordCount: Integer;
    begin
        if DimensionValue.FindSet() then begin
            repeat
                if Dimension.Get(DimensionValue."Dimension Code") then
                    if DimensionValue."Dimension Id" <> Dimension.SystemId then begin
                        DimensionValue2 := DimensionValue;
                        DimensionValue2."Dimension Id" := Dimension.SystemId;
                        DimensionValue2.Modify();
                        CountRecordsAndCommit(RecordCount);
                    end;
            until DimensionValue.Next() = 0;

            Commit();
        end;
    end;

    procedure UpgradeGLAccountAPIType()
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.ModifyAll("API Account Type", GLAccount."API Account Type"::Posting);

        GLAccount.Reset();
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Heading);
        GLAccount.ModifyAll("API Account Type", GLAccount."API Account Type"::Heading);

        GLAccount.Reset();
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Total);
        GLAccount.ModifyAll("API Account Type", GLAccount."API Account Type"::Total);

        GLAccount.Reset();
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::"Begin-Total");
        GLAccount.ModifyAll("API Account Type", GLAccount."API Account Type"::"Begin-Total");

        GLAccount.Reset();
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::"End-Total");
        GLAccount.ModifyAll("API Account Type", GLAccount."API Account Type"::"End-Total");

        Commit();
    end;

    procedure UpgradePurchRcptLineDocumentId(CheckRecordCount: Boolean)
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        EnvironmentInformation: codeunit "Environment Information";
        RecordCount: Integer;
    begin
        if CheckRecordCount then
            if EnvironmentInformation.IsSaaS() then
                if PurchRcptLine.Count() > GetSafeRecordCountForSaaSUpgrade() then
                    exit;

        PurchRcptHeader.SetLoadFields(PurchRcptHeader."No.", PurchRcptHeader.SystemId);
        if PurchRcptHeader.FindSet() then begin
            repeat
                PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
                PurchRcptLine.ModifyAll("Document Id", PurchRcptHeader.SystemId);
                CountRecordsAndCommit(RecordCount);
            until PurchRcptHeader.Next() = 0;

            Commit();
        end;
    end;

    local procedure UpgradePurchaseCreditMemoBuffer()
    var
        GraphMgtPurchCrMemo: Codeunit "Graph Mgt - Purch. Cr. Memo";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        GraphMgtPurchCrMemo.UpdateBufferTableRecords();

        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPurchaseCreditMemoUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetPurchaseCreditMemoUpgradeTag());
    end;

    internal procedure UpgradePurchaseCreditMemoVendorCrMemoNo()
    var
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        RecordCount: Integer;
    begin
        if PurchCrMemoEntityBuffer.FindSet() then
            repeat
                if PurchCrMemoEntityBuffer.Posted then begin
                    PurchCrMemoHeader.SetLoadFields("No.", "Vendor Cr. Memo No.");
                    if PurchCrMemoHeader.Get(PurchCrMemoEntityBuffer."No.") then
                        if PurchCrMemoHeader."Vendor Cr. Memo No." <> '' then
                            if PurchCrMemoHeader."Vendor Cr. Memo No." <> PurchCrMemoEntityBuffer."Vendor Cr. Memo No." then begin
                                PurchCrMemoEntityBuffer."Vendor Cr. Memo No." := PurchCrMemoHeader."Vendor Cr. Memo No.";
                                PurchCrMemoEntityBuffer.Modify();
                                CountRecordsAndCommit(RecordCount);
                            end;
                end else begin
                    PurchaseHeader.SetLoadFields("No.", "Document Type", "Vendor Cr. Memo No.");
                    if PurchaseHeader.Get(PurchaseHeader."Document Type"::"Credit Memo", PurchCrMemoEntityBuffer."No.") then
                        if PurchaseHeader."Vendor Cr. Memo No." <> '' then
                            if PurchaseHeader."Vendor Cr. Memo No." <> PurchCrMemoEntityBuffer."Vendor Cr. Memo No." then begin
                                PurchCrMemoEntityBuffer."Vendor Cr. Memo No." := PurchaseHeader."Vendor Cr. Memo No.";
                                PurchCrMemoEntityBuffer.Modify();
                                CountRecordsAndCommit(RecordCount);
                            end;
                end;
            until PurchCrMemoEntityBuffer.Next() = 0;
    end;

    internal procedure UpgradeSalesOrderShipmentMethod()
    var
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        SalesHeader: Record "Sales Header";
        SourceRecordRef: RecordRef;
        TargetRecordRef: RecordRef;
        RecordCount: Integer;
    begin
        if SalesOrderEntityBuffer.FindSet() then
            repeat
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                SalesHeader.SetRange(SystemId, SalesOrderEntityBuffer.Id);
                if SalesHeader.FindFirst() then begin
                    SourceRecordRef.GetTable(SalesHeader);
                    TargetRecordRef.GetTable(SalesOrderEntityBuffer);
                    UpdateSalesDocumentShipmentMethodFields(SourceRecordRef, TargetRecordRef);
                end;
                CountRecordsAndCommit(RecordCount);
            until SalesOrderEntityBuffer.Next() = 0;
    end;

    internal procedure UpgradeSalesCrMemoShipmentMethod()
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SourceRecordRef: RecordRef;
        TargetRecordRef: RecordRef;
        RecordCount: Integer;
    begin
        if SalesCrMemoEntityBuffer.FindSet() then
            repeat
                if SalesCrMemoEntityBuffer.Posted then begin
                    SalesCrMemoHeader.SetRange(SystemId, SalesCrMemoEntityBuffer.Id);
                    if SalesCrMemoHeader.FindFirst() then begin
                        SourceRecordRef.GetTable(SalesCrMemoHeader);
                        TargetRecordRef.GetTable(SalesCrMemoEntityBuffer);
                        UpdateSalesDocumentShipmentMethodFields(SourceRecordRef, TargetRecordRef);
                    end;
                end else begin
                    SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
                    SalesHeader.SetRange(SystemId, SalesCrMemoEntityBuffer.Id);
                    if SalesHeader.FindFirst() then begin
                        SourceRecordRef.GetTable(SalesHeader);
                        TargetRecordRef.GetTable(SalesCrMemoEntityBuffer);
                        UpdateSalesDocumentShipmentMethodFields(SourceRecordRef, TargetRecordRef);
                    end;
                end;
                CountRecordsAndCommit(RecordCount);
            until SalesCrMemoEntityBuffer.Next() = 0;
    end;

    local procedure UpdateSalesDocumentShipmentMethodFields(var SourceRecordRef: RecordRef; var TargetRecordRef: RecordRef)
    var
        SalesHeader: Record "Sales Header";
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        ShipmentMethod: Record "Shipment Method";
        CodeFieldRef: FieldRef;
        IdFieldRef: FieldRef;
        EmptyGuid: Guid;
        OldId: Guid;
        NewId: Guid;
        Changed: Boolean;
        ShipmentMethodCode: Code[10];
    begin
        if CopyFieldValue(SourceRecordRef, TargetRecordRef, SalesHeader.FieldNo("Shipment Method Code")) then
            Changed := true;
        CodeFieldRef := TargetRecordRef.Field(SalesOrderEntityBuffer.FieldNo("Shipment Method Code"));
        IdFieldRef := TargetRecordRef.Field(SalesOrderEntityBuffer.FieldNo("Shipment Method Id"));
        OldId := IdFieldRef.Value();
        ShipmentMethodCode := CodeFieldRef.Value();
        if ShipmentMethod.Get(ShipmentMethodCode) then
            NewId := ShipmentMethod.SystemId
        else
            NewId := EmptyGuid;
        if OldId <> NewId then begin
            IdFieldRef.Value := NewId;
            Changed := true;
        end;
        if Changed then
            TargetRecordRef.Modify();
    end;

    local procedure CopyFieldValue(var SourceRecordRef: RecordRef; var TargetRecordRef: RecordRef; FieldNo: Integer): Boolean
    var
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
    begin
        SourceFieldRef := SourceRecordRef.Field(FieldNo);
        TargetFieldRef := TargetRecordRef.Field(FieldNo);
        if TargetFieldRef.Value <> SourceFieldRef.Value then begin
            TargetFieldRef.Value := SourceFieldRef.Value();
            exit(true);
        end;
        exit(false);
    end;

    local procedure GetSafeRecordCountForSaaSUpgrade(): Integer
    begin
        exit(300000);
    end;

    procedure GetAPIUpgradeTags(var APIUpgradeTags: Dictionary of [Code[250], Text[250]])
    begin
        OnGetAPIUpgradeTags(APIUpgradeTags);
    end;

    procedure SetStatus(var APIDataUpgrade: Record "API Data Upgrade"; Status: Option)
    begin
        APIDataUpgrade.Status := Status;
        APIDataUpgrade.Modify();
    end;

    procedure GetAPIDataUpgradeEntities(var APIDataUpgradeEntities: Dictionary of [Code[250], Text[250]])
    begin
        APIDataUpgradeEntities.Add('Items', 'items');
        APIDataUpgradeEntities.Add('Customers', 'customers');
        APIDataUpgradeEntities.Add('Customer Payments', 'customerPayments');
        APIDataUpgradeEntities.Add('Journals', 'journals, journalLines');
        APIDataUpgradeEntities.Add('Purchase Invoices', 'purchaseInvoices, purchaseInvoiceLines');
        APIDataUpgradeEntities.Add('Sales Credit Memos', 'salesCreditMemos, salesCreditMemoLines');
        APIDataUpgradeEntities.Add('Sales Invoices', 'salesInvoices, salesInvoiceLines');
        APIDataUpgradeEntities.Add('Sales Orders', 'salesOrders, salesOrderLines');
        APIDataUpgradeEntities.Add('Sales Quotes', 'salesQuotes, salesQuoteLines');
        APIDataUpgradeEntities.Add('Vendors', 'vendors');
        APIDataUpgradeEntities.Add('Vendor Payments', 'vendorPayments');
        APIDataUpgradeEntities.Add('Sales Shipments', 'salesShipments');
        APIDataUpgradeEntities.Add('Purchase Orders', 'purchaseOrders');
        APIDataUpgradeEntities.Add('Item Variants', 'itemVariants');
        APIDataUpgradeEntities.Add('Default Dimensions', 'defaultDimensions');
        APIDataUpgradeEntities.Add('Dimension Values', 'dimensionValues');
        APIDataUpgradeEntities.Add('Accounts', 'accounts');
        APIDataUpgradeEntities.Add('Purchase Receipts', 'purchaseReceipts');
        APIDataUpgradeEntities.Add('Purchase Credit Memos', 'purchaseCreditMemos');
        APIDataUpgradeEntities.Add('Fixed Assets', 'fixedAssets');

        OnGetAPIDataUpgradeEntities(APIDataUpgradeEntities)
    end;

    procedure CountRecordsAndCommit(var RecordCount: Integer)
    begin
        RecordCount += 1;
        if RecordCount = 500 then begin
            Commit();
            RecordCount := 0;
        end;
    end;

    internal procedure GetDisableAPIDataUpgradesTag(): Code[250]
    begin
        exit('MS-469217-DisableAPIDataUpgrade-20230411');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAPIUpgradeTags(var APIUpgradeTags: Dictionary of [Code[250], Text[250]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAPIDataUpgradeEntities(var APIDataUpgradeEntities: Dictionary of [Code[250], Text[250]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAPIDataUpgrade(APIUpgradeTag: Code[250])
    begin
    end;
}
