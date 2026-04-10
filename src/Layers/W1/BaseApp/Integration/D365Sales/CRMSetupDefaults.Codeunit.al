// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Environment.Configuration;
using System.Reflection;
using System.Threading;

codeunit 5334 "CRM Setup Defaults"
{

    trigger OnRun()
    begin
    end;

    var
        CRMProductName: Codeunit "CRM Product Name";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";

        IntegrationTablePrefixTok: Label 'Dataverse', Comment = 'Product name', Locked = true;
        CustomStatisticsSynchJobDescTxt: Label 'Customer Statistics - %1 synchronization job', Comment = '%1 = CRM product name';
        ItemAvailabilitySynchJobDescTxt: Label 'Item Availability - %1 synchronization job', Comment = '%1 = CRM product name';
        CustomSalesOrderSynchJobDescTxt: Label 'Sales Order Status - %1 synchronization job', Comment = '%1 = CRM product name';
        CustomSalesOrderNotesSynchJobDescTxt: Label 'Sales Order Notes - %1 synchronization job', Comment = '%1 = CRM product name';
        ArchivedSalesOrdersSynchJobDescTxt: Label 'Archived Sales Orders - %1 synchronization job', Comment = '%1 = CRM product name';
        AutoCreateSalesOrdersTxt: Label 'Automatically create sales orders from sales orders that are submitted in %1.', Comment = '%1 = CRM product name';
        AutoProcessQuotesTxt: Label 'Automatically process sales quotes from sales quotes that are activated in %1.', Comment = '%1 = CRM product name';
        OrTok: Label '%1|%2', Locked = true, Comment = '%1 and %2 - some filters';

    procedure ResetConfiguration(CRMConnectionSetup: Record "CRM Connection Setup")
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
        EnqueueJobQueEntries: Boolean;
        IsHandled: Boolean;
        IsTeamOwnershipModel: Boolean;
    begin
        IsHandled := false;
        OnBeforeResetConfiguration(CRMConnectionSetup, IsHandled);
        if IsHandled then
            exit;

        EnqueueJobQueEntries := CRMConnectionSetup.DoReadCRMData();
        IsTeamOwnershipModel := CDSIntegrationMgt.IsTeamOwnershipModelSelected();

        if CRMIntegrationManagement.IsUnitGroupMappingEnabled() then begin
            ResetUnitGroupUoMScheduleMapping('UNIT GROUP', EnqueueJobQueEntries);
            ResetItemUnitOfMeasureUoMMapping('ITEM UOM', EnqueueJobQueEntries);
            ResetResourceUnitOfMeasureUoMMapping('RESOURCE UOM', EnqueueJobQueEntries);
        end else
            ResetUnitOfMeasureUoMScheduleMapping('UNIT OF MEASURE', EnqueueJobQueEntries);
        ResetItemProductMapping('ITEM-PRODUCT', EnqueueJobQueEntries);
        ResetResourceProductMapping('RESOURCE-PRODUCT', EnqueueJobQueEntries);
        if PriceCalculationMgt.IsExtendedPriceCalculationEnabled() then begin
            ResetPriceListHeaderPricelevelMapping('PLHEADER-PRICE', EnqueueJobQueEntries);
            ResetPriceListLineProductPricelevelMapping('PLLINE-PRODPRICE', EnqueueJobQueEntries);
        end else begin
            ResetCustomerPriceGroupPricelevelMapping('CUSTPRCGRP-PRICE', EnqueueJobQueEntries);
            ResetSalesPriceProductPricelevelMapping('SALESPRC-PRODPRICE', EnqueueJobQueEntries);
        end;
        ResetSalesInvoiceHeaderInvoiceMapping('POSTEDSALESINV-INV', IsTeamOwnershipModel, EnqueueJobQueEntries);
        ResetSalesInvoiceLineInvoiceMapping('POSTEDSALESLINE-INV');
        ResetOpportunityMapping('OPPORTUNITY', IsTeamOwnershipModel);
        if CRMConnectionSetup."Is S.Order Integration Enabled" then begin
            ResetSalesOrderMapping('SALESORDER-ORDER', IsTeamOwnershipModel, EnqueueJobQueEntries);
            RecreateSalesOrderStatusJobQueueEntry(EnqueueJobQueEntries);
            RecreateSalesOrderNotesJobQueueEntry(EnqueueJobQueEntries);
            CODEUNIT.Run(CODEUNIT::"CRM Enable Posts");
        end;
        if CRMConnectionSetup."Bidirectional Sales Order Int." then begin
            ResetBidirectionalSalesOrderMapping('SALESORDER-ORDER', IsTeamOwnershipModel, EnqueueJobQueEntries);
            ResetBidirectionalSalesOrderLineMapping('SOLINE-ORDERDETAIL');
            RecreateSalesOrderNotesJobQueueEntry(EnqueueJobQueEntries);
            RecreateArchivedSalesOrdersJobQueueEntry(EnqueueJobQueEntries);
        end;

        RecreateStatisticsJobQueueEntry(EnqueueJobQueEntries);
        if CRMConnectionSetup."Auto Create Sales Orders" then
            RecreateAutoCreateSalesOrdersJobQueueEntry(EnqueueJobQueEntries);
        if CRMConnectionSetup."Auto Process Sales Quotes" then
            RecreateAutoProcessSalesQuotesJobQueueEntry(EnqueueJobQueEntries);
        if CRMConnectionSetup."Item Availability Enabled" then
            RecreateItemAvailabilityJobQueueEntry(EnqueueJobQueEntries);

        if CRMIntegrationManagement.IsCRMSolutionInstalled() then
            ResetCRMNAVConnectionData();

        ResetDefaultCRMPricelevel(CRMConnectionSetup);

        SetCustomIntegrationsTableMappings(CRMConnectionSetup);

        CDSSetupDefaults.AddExtraIntegrationFieldMappings();
    end;

    procedure ResetExtendedPriceListConfiguration()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        EnqueueJobQueEntries: Boolean;
    begin
        if not CRMConnectionSetup.Get() then
            exit;
        EnqueueJobQueEntries := CRMConnectionSetup.DoReadCRMData();

        ResetPriceListHeaderPricelevelMapping('PLHEADER-PRICE', EnqueueJobQueEntries);
        ResetPriceListLineProductPricelevelMapping('PLLINE-PRODPRICE', EnqueueJobQueEntries);
    end;

    procedure ResetUnitGroupMappingConfiguration()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        EnqueueJobQueEntries: Boolean;
    begin
        if not CRMConnectionSetup.Get() then
            exit;
        EnqueueJobQueEntries := CRMConnectionSetup.DoReadCRMData();

        ResetUnitGroupUoMScheduleMapping('UNIT GROUP', EnqueueJobQueEntries);
        ResetItemUnitOfMeasureUoMMapping('ITEM UOM', EnqueueJobQueEntries);
        ResetResourceUnitOfMeasureUoMMapping('RESOURCE UOM', EnqueueJobQueEntries);

        ResetItemProductUnitGroupMapping();
        ResetResourceProductUnitGroupMapping();
        ResetPriceListLineProductPricelevelUnitGroupMapping();
    end;

    local procedure ResetItemProductUnitGroupMapping()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
    begin
        if IntegrationTableMapping.Get('ITEM-PRODUCT') then begin
            IntegrationTableMapping."Dependency Filter" := 'ITEM UOM';
            IntegrationTableMapping.Modify();

            InsertIntegrationFieldMapping(
              'ITEM-PRODUCT',
              Item.FieldNo("Base Unit of Measure"),
              CRMProduct.FieldNo(DefaultUoMId),
              IntegrationFieldMapping.Direction::Bidirectional,
              '', true, false);
        end;

        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", 'ITEM-PRODUCT');
        IntegrationFieldMapping.SetRange("Field No.", Item.FieldNo("Base Unit of Measure"));
        IntegrationFieldMapping.SetRange("Integration Table Field No.", CRMProduct.FieldNo(DefaultUoMScheduleId));
        if IntegrationFieldMapping.FindFirst() then
            IntegrationFieldMapping.Delete();
    end;

    local procedure ResetResourceProductUnitGroupMapping()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
    begin
        if IntegrationTableMapping.Get('RESOURCE-PRODUCT') then begin
            IntegrationTableMapping."Dependency Filter" := 'RESOURCE UOM';
            IntegrationTableMapping.Modify();

            // Base Unit of Measure > DefaultUoMId
            InsertIntegrationFieldMapping(
              'RESOURCE-PRODUCT',
              Resource.FieldNo("Base Unit of Measure"),
              CRMProduct.FieldNo(DefaultUoMId),
              IntegrationTableMapping.Direction::ToIntegrationTable,
              '', true, false);
        end;

        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", 'RESOURCE-PRODUCT');
        IntegrationFieldMapping.SetRange("Field No.", Resource.FieldNo("Base Unit of Measure"));
        IntegrationFieldMapping.SetRange("Integration Table Field No.", CRMProduct.FieldNo(DefaultUoMScheduleId));
        if IntegrationFieldMapping.FindFirst() then
            IntegrationFieldMapping.Delete();
    end;

    local procedure ResetPriceListLineProductPricelevelUnitGroupMapping()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        PriceListLine: Record "Price List Line";
        CRMProductpricelevel: Record "CRM Productpricelevel";
    begin
        if IntegrationTableMapping.Get('PLLINE-PRODPRICE') then
            // Unit of Measure > UoMId
            InsertIntegrationFieldMapping(
              IntegrationTableMapping.Name,
              PriceListLine.FieldNo("Unit of Measure Code"),
              CRMProductpricelevel.FieldNo(UoMId),
              IntegrationFieldMapping.Direction::ToIntegrationTable,
              '', true, false);

        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", 'PLLINE-PRODPRICE');
        IntegrationFieldMapping.SetRange("Field No.", PriceListLine.FieldNo("Unit of Measure Code"));
        IntegrationFieldMapping.SetRange("Integration Table Field No.", CRMProductpricelevel.FieldNo(UoMScheduleId));
        if IntegrationFieldMapping.FindFirst() then
            IntegrationFieldMapping.Delete();
    end;

    [Scope('OnPrem')]
    procedure ResetItemProductMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        IsHandled: Boolean;
    begin
        OnBeforeResetItemProductMapping(IntegrationTableMappingName, EnqueueJobQueEntry, IsHandled);
        if IsHandled then
            exit;
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::Item, DATABASE::"CRM Product",
          CRMProduct.FieldNo(ProductId), CRMProduct.FieldNo(ModifiedOn),
          '', '', true);

        Item.SetRange(Blocked, false);
        IntegrationTableMapping.SetTableFilter(GetTableFilterFromView(DATABASE::Item, Item.TableCaption(), Item.GetView()));

        if CRMIntegrationManagement.IsUnitGroupMappingEnabled() then
            IntegrationTableMapping."Dependency Filter" := 'ITEM UOM'
        else
            IntegrationTableMapping."Dependency Filter" := 'UNIT OF MEASURE';
        SetIntegrationTableFilterForCRMProduct(IntegrationTableMapping, CRMProduct, CRMProduct.ProductTypeCode::SalesInventory);

        // "No." > ProductNumber
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("No."),
          CRMProduct.FieldNo(ProductNumber),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Description > Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo(Description),
          CRMProduct.FieldNo(Name),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Unit Price > Price
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Unit Price"),
          CRMProduct.FieldNo(Price),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Unit Cost > Standard Cost
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Unit Cost"),
          CRMProduct.FieldNo(StandardCost),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Unit Cost > Current Cost
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Unit Cost"),
          CRMProduct.FieldNo(CurrentCost),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Unit Volume > Stock Volume
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Unit Volume"),
          CRMProduct.FieldNo(StockVolume),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Gross Weight > Stock Weight
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Gross Weight"),
          CRMProduct.FieldNo(StockWeight),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Vendor No. > Vendor ID
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Vendor No."),
          CRMProduct.FieldNo(VendorID),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Vendor Item No. > Vendor part number
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo("Vendor Item No."),
          CRMProduct.FieldNo(VendorPartNumber),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Inventory > Quantity on Hand. If less then zero, it will later be set to zero
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Item.FieldNo(Inventory),
          CRMProduct.FieldNo(QuantityOnHand),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        if CRMIntegrationManagement.IsUnitGroupMappingEnabled() then
            // Base Unit of Measure > DefaultUoMId
            InsertIntegrationFieldMapping(
              IntegrationTableMappingName,
              Item.FieldNo("Base Unit of Measure"),
              CRMProduct.FieldNo(DefaultUoMId),
              IntegrationFieldMapping.Direction::Bidirectional,
              '', true, false)
        else
            // Base Unit of Measure > DefaultUoMScheduleId
            InsertIntegrationFieldMapping(
              IntegrationTableMappingName,
              Item.FieldNo("Base Unit of Measure"),
              CRMProduct.FieldNo(DefaultUoMScheduleId),
              IntegrationFieldMapping.Direction::Bidirectional,
              '', true, false);

        OnResetItemProductMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName);
        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 1440);
    end;

    [Scope('OnPrem')]
    procedure ResetResourceProductMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
        IsHandled: Boolean;
    begin
        OnBeforeResetResourceProductMapping(IntegrationTableMappingName, EnqueueJobQueEntry, IsHandled);
        if IsHandled then
            exit;

        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::Resource, DATABASE::"CRM Product",
          CRMProduct.FieldNo(ProductId), CRMProduct.FieldNo(ModifiedOn),
          '', '', true);

        Resource.SetRange(Blocked, false);
        IntegrationTableMapping.SetTableFilter(GetTableFilterFromView(DATABASE::Resource, Resource.TableCaption(), Resource.GetView()));

        if CRMIntegrationManagement.IsUnitGroupMappingEnabled() then
            IntegrationTableMapping."Dependency Filter" := 'RESOURCE UOM'
        else
            IntegrationTableMapping."Dependency Filter" := 'UNIT OF MEASURE';

        SetIntegrationTableFilterForCRMProduct(IntegrationTableMapping, CRMProduct, CRMProduct.ProductTypeCode::Services);

        // "No." > ProductNumber
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Resource.FieldNo("No."),
          CRMProduct.FieldNo(ProductNumber),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Name > Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Resource.FieldNo(Name),
          CRMProduct.FieldNo(Name),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Unit Price > Price
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Resource.FieldNo("Unit Price"),
          CRMProduct.FieldNo(Price),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Unit Cost > Standard Cost
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Resource.FieldNo("Unit Cost"),
          CRMProduct.FieldNo(StandardCost),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Unit Cost > Current Cost
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Resource.FieldNo("Unit Cost"),
          CRMProduct.FieldNo(CurrentCost),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Vendor No. > Vendor ID
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Resource.FieldNo("Vendor No."),
          CRMProduct.FieldNo(VendorID),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Capacity > Quantity on Hand. If less then zero, it will later be set to zero
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Resource.FieldNo(Capacity),
          CRMProduct.FieldNo(QuantityOnHand),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        if CRMIntegrationManagement.IsUnitGroupMappingEnabled() then
            // Base Unit of Measure > DefaultUoMId
            InsertIntegrationFieldMapping(
              IntegrationTableMappingName,
              Resource.FieldNo("Base Unit of Measure"),
              CRMProduct.FieldNo(DefaultUoMId),
              IntegrationTableMapping.Direction::ToIntegrationTable,
              '', true, false);

        OnResetResourceProductMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName);
        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 720);
    end;

    [Scope('OnPrem')]
    procedure ResetSalesInvoiceHeaderInvoiceMapping(IntegrationTableMappingName: Code[20]; IsTeamOwnershipModel: Boolean; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CRMInvoice: Record "CRM Invoice";
        CDSCompany: Record "CDS Company";
        EmptyGuid: Guid;
        IsHandled: Boolean;
    begin
        OnBeforeResetSalesInvoiceHeaderInvoiceMapping(IntegrationTableMappingName, EnqueueJobQueEntry, IsHandled);
        if IsHandled then
            exit;
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Sales Invoice Header", DATABASE::"CRM Invoice",
          CRMInvoice.FieldNo(InvoiceId), CRMInvoice.FieldNo(ModifiedOn),
          '', '', true);
        IntegrationTableMapping."Dependency Filter" := 'ITEM-PRODUCT|RESOURCE-PRODUCT|OPPORTUNITY';
        IntegrationTableMapping.Modify();

        if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then begin
            CRMInvoice.SetFilter(CompanyId, StrSubstno(OrTok, CDSCompany.CompanyId, EmptyGuid));
            IntegrationTableMapping.SetIntegrationTableFilter(
              GetTableFilterFromView(DATABASE::"CRM Invoice", CRMInvoice.TableCaption(), CRMInvoice.GetView()));
            IntegrationTableMapping.Modify();
        end;

        // "No." > InvoiceNumber
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("No."),
          CRMInvoice.FieldNo(InvoiceNumber),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        if not IsTeamOwnershipModel then begin
            // OwnerId = systemuser
            InsertIntegrationFieldMapping(
              IntegrationTableMappingName,
              0, CRMInvoice.FieldNo(OwnerIdType),
              IntegrationFieldMapping.Direction::ToIntegrationTable,
              Format(CRMInvoice.OwnerIdType::systemuser), false, false);

            // Salesperson Code > OwnerId
            InsertIntegrationFieldMapping(
              IntegrationTableMappingName,
              SalesInvoiceHeader.FieldNo("Salesperson Code"),
              CRMInvoice.FieldNo(OwnerId),
              IntegrationFieldMapping.Direction::ToIntegrationTable,
              '', true, false);
            SetIntegrationFieldMappingNotNull();
        end;

        // "Currency Code" > TransactionCurrencyId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Currency Code"),
          CRMInvoice.FieldNo(TransactionCurrencyId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Due Date" > DueDate
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Due Date"),
          CRMInvoice.FieldNo(DueDate),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Ship-to Name"),
          CRMInvoice.FieldNo(ShipTo_Name),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to Address
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Ship-to Address"),
          CRMInvoice.FieldNo(ShipTo_Line1),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to Address 2
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Ship-to Address 2"),
          CRMInvoice.FieldNo(ShipTo_Line2),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to City
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Ship-to City"),
          CRMInvoice.FieldNo(ShipTo_City),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Ship-to Country/Region Code"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Ship-to Country/Region Code"),
          CRMInvoice.FieldNo(ShipTo_Country),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Ship-to Post Code"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Ship-to Post Code"),
          CRMInvoice.FieldNo(ShipTo_PostalCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Ship-to County"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Ship-to County"),
          CRMInvoice.FieldNo(ShipTo_StateOrProvince),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Shipment Date"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Shipment Date"),
          CRMInvoice.FieldNo(DateDelivered),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Bill-to Name"),
          CRMInvoice.FieldNo(BillTo_Name),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Address
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Bill-to Address"),
          CRMInvoice.FieldNo(BillTo_Line1),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Address 2
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Bill-to Address 2"),
          CRMInvoice.FieldNo(BillTo_Line2),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to City
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Bill-to City"),
          CRMInvoice.FieldNo(BillTo_City),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Country/Region Code
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Bill-to Country/Region Code"),
          CRMInvoice.FieldNo(BillTo_Country),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Bill-to Post Code"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Bill-to Post Code"),
          CRMInvoice.FieldNo(BillTo_PostalCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Bill-to County"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Bill-to County"),
          CRMInvoice.FieldNo(BillTo_StateOrProvince),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Amount > TotalAmountLessFreight
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo(Amount),
          CRMInvoice.FieldNo(TotalAmountLessFreight),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Amount Including VAT" > TotalAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Amount Including VAT"),
          CRMInvoice.FieldNo(TotalAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Invoice Discount Amount" > DiscountAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Invoice Discount Amount"),
          CRMInvoice.FieldNo(DiscountAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Shipping Agent Code > address1_shippingmethodcode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Shipping Agent Code"),
          CRMInvoice.FieldNo(ShippingMethodCodeEnum),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Payment Terms Code > paymenttermscode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Payment Terms Code"),
          CRMInvoice.FieldNo(PaymentTermsCodeEnum),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Work description" <-> Description
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceHeader.FieldNo("Work Description"),
          CRMInvoice.FieldNo(Description),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', false, false);

        OnResetSalesInvoiceHeaderInvoiceMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 1440);
    end;

    [Scope('OnPrem')]
    procedure ResetSalesInvoiceLineInvoiceMapping(IntegrationTableMappingName: Code[20])
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        SalesInvoiceLine: Record "Sales Invoice Line";
        CRMInvoicedetail: Record "CRM Invoicedetail";
        IsHandled: Boolean;
    begin
        OnBeforeResetSalesInvoiceLineInvoiceMapping(IntegrationTableMappingName, IsHandled);
        if IsHandled then
            exit;

        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Sales Invoice Line", DATABASE::"CRM Invoicedetail",
          CRMInvoicedetail.FieldNo(InvoiceDetailId), CRMInvoicedetail.FieldNo(ModifiedOn),
          '', '', false);
        IntegrationTableMapping."Dependency Filter" := 'POSTEDSALESINV-INV';
        IntegrationTableMapping.Modify();

        // Quantity -> Quantity
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceLine.FieldNo(Quantity),
          CRMInvoicedetail.FieldNo(Quantity),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Line Discount Amount" -> "Manual Discount Amount"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceLine.FieldNo("Line Discount Amount"),
          CRMInvoicedetail.FieldNo(ManualDiscountAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Unit Price" > PricePerUnit
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceLine.FieldNo("Unit Price"),
          CRMInvoicedetail.FieldNo(PricePerUnit),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // TRUE > IsPriceOverridden
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          0,
          CRMInvoicedetail.FieldNo(IsPriceOverridden),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '1', true, false);

        // Amount -> BaseAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceLine.FieldNo(Amount),
          CRMInvoicedetail.FieldNo(BaseAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Amount Including VAT" -> ExtendedAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesInvoiceLine.FieldNo("Amount Including VAT"),
          CRMInvoicedetail.FieldNo(ExtendedAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        OnResetSalesInvoiceLineInvoiceMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName);
    end;

    [Scope('OnPrem')]
    procedure ResetSalesOrderMapping(IntegrationTableMappingName: Code[20]; IsTeamOwnershipModel: Boolean; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        SalesHeader: Record "Sales Header";
        CRMSalesorder: Record "CRM Salesorder";
        CDSCompany: Record "CDS Company";
        EmptyGuid: Guid;
        IsHandled: Boolean;
    begin
        OnBeforeResetSalesOrderMapping(IntegrationTableMappingName, EnqueueJobQueEntry, IsHandled);
        if IsHandled then
            exit;
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Sales Header", DATABASE::"CRM Salesorder",
          CRMSalesorder.FieldNo(SalesOrderId), CRMSalesorder.FieldNo(ModifiedOn),
          '', '', true);
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        IntegrationTableMapping.SetTableFilter(
          GetTableFilterFromView(DATABASE::"Sales Header", SalesHeader.TableCaption(), SalesHeader.GetView()));
        IntegrationTableMapping."Dependency Filter" := 'ITEM-PRODUCT|RESOURCE-PRODUCT|OPPORTUNITY';
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
        IntegrationTableMapping.Modify();

        if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then begin
            CRMSalesorder.SetFilter(CompanyId, StrSubstno(OrTok, CDSCompany.CompanyId, EmptyGuid));
            IntegrationTableMapping.SetIntegrationTableFilter(
              GetTableFilterFromView(DATABASE::"CRM Salesorder", CRMSalesorder.TableCaption(), CRMSalesorder.GetView()));
            IntegrationTableMapping.Modify();
        end;

        // "No." > OrderNumber
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("No."),
          CRMSalesorder.FieldNo(OrderNumber),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        if not IsTeamOwnershipModel then begin
            // OwnerId = systemuser
            InsertIntegrationFieldMapping(
              IntegrationTableMappingName,
              0, CRMSalesorder.FieldNo(OwnerIdType),
              IntegrationFieldMapping.Direction::ToIntegrationTable,
              Format(CRMSalesorder.OwnerIdType::systemuser), false, false);

            // Salesperson Code > OwnerId
            InsertIntegrationFieldMapping(
              IntegrationTableMappingName,
              SalesHeader.FieldNo("Salesperson Code"),
              CRMSalesorder.FieldNo(OwnerId),
              IntegrationFieldMapping.Direction::ToIntegrationTable,
              '', true, false);
            SetIntegrationFieldMappingNotNull();
        end;

        // "Currency Code" > TransactionCurrencyId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Currency Code"),
          CRMSalesorder.FieldNo(TransactionCurrencyId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to Name"),
          CRMSalesorder.FieldNo(ShipTo_Name),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to Address
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to Address"),
          CRMSalesorder.FieldNo(ShipTo_Line1),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to Address 2
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to Address 2"),
          CRMSalesorder.FieldNo(ShipTo_Line2),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Ship-to City
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to City"),
          CRMSalesorder.FieldNo(ShipTo_City),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Ship-to Country/Region Code"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to Country/Region Code"),
          CRMSalesorder.FieldNo(ShipTo_Country),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Ship-to Post Code"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to Post Code"),
          CRMSalesorder.FieldNo(ShipTo_PostalCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Ship-to County"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to County"),
          CRMSalesorder.FieldNo(ShipTo_StateOrProvince),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Shipment Date"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Last Shipment Date"),
          CRMSalesorder.FieldNo(DateFulfilled),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to Name"),
          CRMSalesorder.FieldNo(BillTo_Name),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Address
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to Address"),
          CRMSalesorder.FieldNo(BillTo_Line1),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Address 2
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to Address 2"),
          CRMSalesorder.FieldNo(BillTo_Line2),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to City
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to City"),
          CRMSalesorder.FieldNo(BillTo_City),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Country/Region Code
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to Country/Region Code"),
          CRMSalesorder.FieldNo(BillTo_Country),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Bill-to Post Code"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to Post Code"),
          CRMSalesorder.FieldNo(BillTo_PostalCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Bill-to County"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to County"),
          CRMSalesorder.FieldNo(BillTo_StateOrProvince),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Amount > TotalAmountLessFreight
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo(Amount),
          CRMSalesorder.FieldNo(TotalAmountLessFreight),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Amount Including VAT" > TotalAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Amount Including VAT"),
          CRMSalesorder.FieldNo(TotalAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Invoice Discount Amount" > DiscountAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Invoice Discount Amount"),
          CRMSalesorder.FieldNo(DiscountAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Shipping Agent Code > address1_shippingmethodcode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Shipping Agent Code"),
          CRMSalesorder.FieldNo(ShippingMethodCodeEnum),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Payment Terms Code > paymenttermscode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Payment Terms Code"),
          CRMSalesorder.FieldNo(PaymentTermsCodeEnum),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Requested Delivery Date" -> RequestDeliveryBy
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Requested Delivery Date"),
          CRMSalesorder.FieldNo(RequestDeliveryBy),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        OnResetSalesOrderMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 720);
    end;

    [Scope('OnPrem')]
    procedure ResetBidirectionalSalesOrderMapping(IntegrationTableMappingName: Code[20]; IsTeamOwnershipModel: Boolean; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        SalesHeader: Record "Sales Header";
        CRMSalesorder: Record "CRM Salesorder";
        CDSCompany: Record "CDS Company";
        EmptyGuid: Guid;
        IsHandled: Boolean;
    begin
        OnBeforeResetBidirectionalSalesOrderMapping(IntegrationTableMappingName, EnqueueJobQueEntry, IsHandled);
        if IsHandled then
            exit;
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          Database::"Sales Header", Database::"CRM Salesorder",
          CRMSalesorder.FieldNo(SalesOrderId), CRMSalesorder.FieldNo(ModifiedOn),
          '', '', true);
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        IntegrationTableMapping.SetTableFilter(
          GetTableFilterFromView(Database::"Sales Header", SalesHeader.TableCaption, SalesHeader.GetView()));

        IntegrationTableMapping."Dependency Filter" := 'CUSTOMER|ITEM-PRODUCT|RESOURCE-PRODUCT|OPPORTUNITY';
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::Bidirectional;

        CRMSalesorder.Reset();
        if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then
            CRMSalesorder.SetFilter(CompanyId, StrSubstno(OrTok, CDSCompany.CompanyId, EmptyGuid));
        CRMSalesorder.SetRange(StateCode, CRMSalesorder.StateCode::Submitted);
        IntegrationTableMapping.SetIntegrationTableFilter(
                      GetTableFilterFromView(Database::"CRM Salesorder", CRMSalesorder.TableCaption, CRMSalesorder.GetView()));
        IntegrationTableMapping.Modify();

        if not IsTeamOwnershipModel then begin
            // OwnerId = systemuser
            InsertIntegrationFieldMapping(
              IntegrationTableMappingName,
              0, CRMSalesorder.FieldNo(OwnerIdType),
              IntegrationFieldMapping.Direction::ToIntegrationTable,
              Format(CRMSalesorder.OwnerIdType::systemuser), false, false);

            // Salesperson Code > OwnerId
            InsertIntegrationFieldMapping(
              IntegrationTableMappingName,
              SalesHeader.FieldNo("Salesperson Code"),
              CRMSalesorder.FieldNo(OwnerId),
              IntegrationFieldMapping.Direction::ToIntegrationTable,
              '', true, false);
            SetIntegrationFieldMappingNotNull();
        end;

        // Type
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Document Type"), 0,
          IntegrationFieldMapping.Direction::FromIntegrationTable,
          Format(SalesHeader."Document Type"::Order), true, false);

        // "No." > BusinessCentralOrderNumber
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("No."),
          CRMSalesorder.FieldNo(BusinessCentralOrderNumber),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Your Reference" > OrderNumber
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Your Reference"),
          CRMSalesorder.FieldNo(OrderNumber),
          IntegrationFieldMapping.Direction::FromIntegrationTable,
          '', true, false);

        // CustomerIdType
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          0, CRMSalesorder.FieldNo(CustomerIdType),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          Format(CRMSalesorder.CustomerIdType::account), false, false);

        // "Sell-to Customer No." > CustomerId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Sell-to Customer No."),
          CRMSalesorder.FieldNo(CustomerId),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Currency Code" > TransactionCurrencyId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Currency Code"),
          CRMSalesorder.FieldNo(TransactionCurrencyId),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Ship-to Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to Name"),
          CRMSalesorder.FieldNo(ShipTo_Name),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Ship-to Address
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to Address"),
          CRMSalesorder.FieldNo(ShipTo_Line1),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Ship-to Address 2
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to Address 2"),
          CRMSalesorder.FieldNo(ShipTo_Line2),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Ship-to Post Code"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to Post Code"),
          CRMSalesorder.FieldNo(ShipTo_PostalCode),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Ship-to City
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to City"),
          CRMSalesorder.FieldNo(ShipTo_City),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Ship-to Country/Region Code"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to Country/Region Code"),
          CRMSalesorder.FieldNo(ShipTo_Country),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Ship-to County"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Ship-to County"),
          CRMSalesorder.FieldNo(ShipTo_StateOrProvince),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Shipment Date"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Last Shipment Date"),
          CRMSalesorder.FieldNo(DateFulfilled),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Bill-to Address
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to Address"),
          CRMSalesorder.FieldNo(BillTo_Line1),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Bill-to Address 2
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to Address 2"),
          CRMSalesorder.FieldNo(BillTo_Line2),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Bill-to Post Code"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to Post Code"),
          CRMSalesorder.FieldNo(BillTo_PostalCode),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Bill-to City
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to City"),
          CRMSalesorder.FieldNo(BillTo_City),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Bill-to Country/Region Code
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to Country/Region Code"),
          CRMSalesorder.FieldNo(BillTo_Country),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Bill-to County"
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Bill-to County"),
          CRMSalesorder.FieldNo(BillTo_StateOrProvince),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Invoice Discount Amount" > DiscountAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Invoice Discount Amount"),
          CRMSalesorder.FieldNo(DiscountAmount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Shipping Agent Code > address1_shippingmethodcode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Shipping Agent Code"),
          CRMSalesorder.FieldNo(ShippingMethodCodeEnum),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Payment Terms Code > paymenttermscode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Payment Terms Code"),
          CRMSalesorder.FieldNo(PaymentTermsCodeEnum),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Shipment Method Code > FreightTermsCodeEnum
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Shipment Method Code"),
          CRMSalesorder.FieldNo(FreightTermsCodeEnum),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Requested Delivery Date" -> RequestDeliveryBy
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Requested Delivery Date"),
          CRMSalesorder.FieldNo(RequestDeliveryBy),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Payment Discount %" > DiscountPercentage
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Payment Discount %"),
          CRMSalesorder.FieldNo(DiscountPercentage),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Work description" <-> Description
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesHeader.FieldNo("Work Description"),
          CRMSalesorder.FieldNo(Description),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', false, false);

        OnResetBidirectionalSalesOrderMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 720);
    end;

    procedure ResetBidirectionalSalesOrderLineMapping(IntegrationTableMappingName: Code[20])
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        SalesLine: Record "Sales Line";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        IsHandled: Boolean;
    begin
        OnBeforeResetBidirectionalSalesOrderLineMapping(IntegrationTableMappingName, IsHandled);
        if IsHandled then
            exit;
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          Database::"Sales Line", Database::"CRM Salesorderdetail",
          CRMSalesorderdetail.FieldNo(SalesOrderDetailId), CRMSalesorderdetail.FieldNo(ModifiedOn),
          '', '', false);

        SalesLine.Reset();
        SalesLine.SetFilter("Type", OrTok, SalesLine."Type"::Item, SalesLine."Type"::Resource);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        IntegrationTableMapping.SetTableFilter(
          GetTableFilterFromView(DATABASE::"Sales Line", SalesLine.TableCaption, SalesLine.GetView()));

        IntegrationTableMapping."Dependency Filter" := 'SALESORDER-ORDER';
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::Bidirectional;
        IntegrationTableMapping."Deletion-Conflict Resolution" := IntegrationTableMapping."Deletion-Conflict Resolution"::"Remove Coupling";
        IntegrationTableMapping.Modify();

        // Document Type
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesLine.FieldNo("Document Type"),
          0,
          IntegrationFieldMapping.Direction::FromIntegrationTable,
          Format(SalesLine."Document Type"::Order), true, false);

        // ProductTypeCode
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          0,
          CRMSalesorderdetail.FieldNo(ProductTypeCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          Format(CRMSalesorderdetail.ProductTypeCode::Product), false, false);

        // "No." > ProductId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesLine.FieldNo("No."),
          CRMSalesorderdetail.FieldNo(ProductId),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Line No." > BusinessCentralLineNumber
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesLine.FieldNo("Line No."),
          CRMSalesorderdetail.FieldNo(BusinessCentralLineNumber),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // Quantity > Quantity
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesLine.FieldNo(Quantity),
          CRMSalesorderdetail.FieldNo(Quantity),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Quantity Shipped" > QuantityShipped
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesLine.FieldNo("Quantity Shipped"),
          CRMSalesorderdetail.FieldNo(QuantityShipped),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // TRUE > IsPriceOverridden
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          0,
          CRMSalesorderdetail.FieldNo(IsPriceOverridden),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '1', true, false);

        // "Unit Price" > PricePerUnit
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesLine.FieldNo("Unit Price"),
          CRMSalesorderdetail.FieldNo(PricePerUnit),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Currency Code" > TransactionCurrencyId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesLine.FieldNo("Currency Code"),
          CRMSalesorderdetail.FieldNo(TransactionCurrencyId),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Amount" > Amount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesLine.FieldNo("Amount"),
          CRMSalesorderdetail.FieldNo(BaseAmount),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Amount Including VAT" > ExtendedAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesLine.FieldNo("Amount Including VAT"),
          CRMSalesorderdetail.FieldNo(ExtendedAmount),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Requested Delivery Date" -> RequestDeliveryBy
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesLine.FieldNo("Requested Delivery Date"),
          CRMSalesorderdetail.FieldNo(RequestDeliveryBy),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        OnResetBidirectionalSalesOrderLineMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName);
    end;

    [Scope('OnPrem')]
    procedure ResetSalesOrderMappingConfiguration(CRMConnectionSetup: Record "CRM Connection Setup")
    var
        JobQueueEntry: Record "Job Queue Entry";
        IntegrationTableMapping: Record "Integration Table Mapping";
        EnqueueJobQueueEntries: Boolean;
        IsTeamOwnershipModel: Boolean;
    begin
        EnqueueJobQueueEntries := CRMConnectionSetup.DoReadCRMData();
        IsTeamOwnershipModel := CDSIntegrationMgt.IsTeamOwnershipModelSelected();
        if CRMConnectionSetup."Bidirectional Sales Order Int." then begin
            ResetBidirectionalSalesOrderMapping('SALESORDER-ORDER', IsTeamOwnershipModel, EnqueueJobQueueEntries);
            ResetBidirectionalSalesOrderLineMapping('SOLINE-ORDERDETAIL');
            JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
            JobQueueEntry.SetFilter("Object ID to Run", '%1|%2|%3', Codeunit::"Auto Create Sales Orders", Codeunit::"CRM Order Status Update Job", Codeunit::"CRM Notes Synch Job");
            JobQueueEntry.DeleteAll();
            RecreateSalesOrderNotesJobQueueEntry(EnqueueJobQueueEntries);
            RecreateArchivedSalesOrdersJobQueueEntry(EnqueueJobQueueEntries);
        end;
        if CRMConnectionSetup."Is S.Order Integration Enabled" then begin
            ResetSalesOrderMapping('SALESORDER-ORDER', IsTeamOwnershipModel, EnqueueJobQueueEntries);
            if IntegrationTableMapping.Get('SOLINE-ORDERDETAIL') then begin
                JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
                JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
                JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId);
                JobQueueEntry.DeleteAll();
                IntegrationTableMapping.Delete()
            end;
            RecreateSalesOrderStatusJobQueueEntry(EnqueueJobQueueEntries);
            RecreateSalesOrderNotesJobQueueEntry(EnqueueJobQueueEntries);
            CODEUNIT.Run(CODEUNIT::"CRM Enable Posts");
        end;
    end;

    [Scope('OnPrem')]
    procedure ResetCustomerPriceGroupPricelevelMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CustomerPriceGroup: Record "Customer Price Group";
        CRMPricelevel: Record "CRM Pricelevel";
        CDSCompany: Record "CDS Company";
        EmptyGuid: Guid;
        IsHandled: Boolean;
    begin
        if IsHandled then
            exit;

        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Customer Price Group", DATABASE::"CRM Pricelevel",
          CRMPricelevel.FieldNo(PriceLevelId), CRMPricelevel.FieldNo(ModifiedOn),
          '', '', true);
        IntegrationTableMapping."Dependency Filter" := 'CURRENCY|ITEM-PRODUCT';
        IntegrationTableMapping.Modify();

        if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then begin
            CRMPricelevel.SetFilter(CompanyId, StrSubstno(OrTok, CDSCompany.CompanyId, EmptyGuid));
            IntegrationTableMapping.SetIntegrationTableFilter(
              GetTableFilterFromView(DATABASE::"CRM Pricelevel", CRMPricelevel.TableCaption(), CRMPricelevel.GetView()));
            IntegrationTableMapping.Modify();
        end;

        // Code > Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          CustomerPriceGroup.FieldNo(Code),
          CRMPricelevel.FieldNo(Name),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        OnResetCustomerPriceGroupPricelevelMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 1440);
    end;

    local procedure ResetSalesPriceProductPricelevelMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        SalesPrice: Record "Sales Price";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        IsHandled: Boolean;
    begin
        if IsHandled then
            exit;
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Sales Price", DATABASE::"CRM Productpricelevel",
          CRMProductpricelevel.FieldNo(ProductPriceLevelId), CRMProductpricelevel.FieldNo(ModifiedOn),
          '', '', false);

        SalesPrice.Reset();
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::"Customer Price Group");
        SalesPrice.SetFilter("Sales Code", '<>''''');
        IntegrationTableMapping.SetTableFilter(
          GetTableFilterFromView(DATABASE::"Sales Price", SalesPrice.TableCaption(), SalesPrice.GetView()));

        IntegrationTableMapping."Dependency Filter" := 'CUSTPRCGRP-PRICE|ITEM-PRODUCT';
        IntegrationTableMapping.Modify();

        // "Sales Code" > PriceLevelId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesPrice.FieldNo("Sales Code"),
          CRMProductpricelevel.FieldNo(PriceLevelId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Item No." > ProductId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesPrice.FieldNo("Item No."),
          CRMProductpricelevel.FieldNo(ProductId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Item No." > ProductNumber
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesPrice.FieldNo("Item No."),
          CRMProductpricelevel.FieldNo(ProductNumber),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Currency Code" > TransactionCurrencyId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesPrice.FieldNo("Currency Code"),
          CRMProductpricelevel.FieldNo(TransactionCurrencyId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // >> PricingMethodCode = CurrencyAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          0, CRMProductpricelevel.FieldNo(PricingMethodCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          Format(CRMProductpricelevel.PricingMethodCode::CurrencyAmount), false, false);

        // "Unit Price" > Amount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          SalesPrice.FieldNo("Unit Price"),
          CRMProductpricelevel.FieldNo(Amount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        OnResetSalesPriceProductPricelevelMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 1440);
    end;

    procedure ResetPriceListHeaderPricelevelMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        PriceListHeader: Record "Price List Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CRMPricelevel: Record "CRM Pricelevel";
        CDSCompany: Record "CDS Company";
        EmptyGuid: Guid;
        IsHandled: Boolean;
    begin
        OnBeforeResetPriceListHeaderPricelevelMapping(IntegrationTableMappingName, EnqueueJobQueEntry, IsHandled);
        if IsHandled then
            exit;

        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Price List Header", DATABASE::"CRM Pricelevel",
          CRMPricelevel.FieldNo(PriceLevelId), CRMPricelevel.FieldNo(ModifiedOn),
          '', '', true);

        PriceListHeader.Reset();
        PriceListHeader.SetRange("Price Type", PriceListHeader."Price Type"::Sale);
        PriceListHeader.SetRange("Amount Type", PriceListHeader."Amount Type"::Price);
        if SalesReceivablesSetup.Get() then
            if SalesReceivablesSetup."Default Price List Code" <> '' then
                PriceListHeader.SetRange("Allow Updating Defaults", true)
            else
                PriceListHeader.SetRange("Allow Updating Defaults", false);
        IntegrationTableMapping.SetTableFilter(
            GetTableFilterFromView(DATABASE::"Price List Header", PriceListHeader.TableCaption(), PriceListHeader.GetView()));
        IntegrationTableMapping."Dependency Filter" := 'CURRENCY|ITEM-PRODUCT';
        IntegrationTableMapping.Modify();

        if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then begin
            CRMPricelevel.SetFilter(CompanyId, StrSubstno(OrTok, CDSCompany.CompanyId, EmptyGuid));
            IntegrationTableMapping.SetIntegrationTableFilter(
                GetTableFilterFromView(DATABASE::"CRM Pricelevel", CRMPricelevel.TableCaption(), CRMPricelevel.GetView()));
            IntegrationTableMapping.Modify();
        end;

        // Code > Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          PriceListHeader.FieldNo(Code),
          CRMPricelevel.FieldNo(Name),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // Description > Description
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          PriceListHeader.FieldNo(Description),
          CRMPricelevel.FieldNo(Description),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Currency Code" > TransactionCurrencyId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          PriceListHeader.FieldNo("Currency Code"),
          CRMPricelevel.FieldNo(TransactionCurrencyId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Starting Date" > BeginDate
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          PriceListHeader.FieldNo("Starting Date"),
          CRMPricelevel.FieldNo(BeginDate),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Ending Date" > EndDate
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          PriceListHeader.FieldNo("Ending Date"),
          CRMPricelevel.FieldNo(EndDate),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        OnResetPriceListHeaderPricelevelMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 1440);
    end;

    local procedure ResetPriceListLineProductPricelevelMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        PriceListLine: Record "Price List Line";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        IsHandled: Boolean;
    begin
        OnBeforeResetPriceListLineProductPricelevelMapping(IntegrationTableMappingName, EnqueueJobQueEntry, IsHandled);
        if IsHandled then
            exit;
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Price List Line", DATABASE::"CRM Productpricelevel",
          CRMProductpricelevel.FieldNo(ProductPriceLevelId), CRMProductpricelevel.FieldNo(ModifiedOn),
          '', '', false);

        PriceListLine.Reset();
        PriceListLine.SetRange("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.SetRange("Amount Type", PriceListLine."Amount Type"::Price);
        PriceListLine.SetFilter("Asset Type", OrTok, PriceListLine."Asset Type"::Item, PriceListLine."Asset Type"::Resource);
        PriceListLine.SetRange("Minimum Quantity", 0);
        IntegrationTableMapping.SetTableFilter(
          GetTableFilterFromView(DATABASE::"Price List Line", PriceListLine.TableCaption(), PriceListLine.GetView()));

        IntegrationTableMapping."Dependency Filter" := 'PLHEADER-PRICE|ITEM-PRODUCT';
        IntegrationTableMapping.Modify();

        // "Price List Code" > PriceLevelId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          PriceListLine.FieldNo("Price List Code"),
          CRMProductpricelevel.FieldNo(PriceLevelId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Asset No." > ProductId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          PriceListLine.FieldNo("Asset No."),
          CRMProductpricelevel.FieldNo(ProductId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Asset No." > ProductNumber
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          PriceListLine.FieldNo("Asset No."),
          CRMProductpricelevel.FieldNo(ProductNumber),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Currency Code" > TransactionCurrencyId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          PriceListLine.FieldNo("Currency Code"),
          CRMProductpricelevel.FieldNo(TransactionCurrencyId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // >> PricingMethodCode = CurrencyAmount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          0, CRMProductpricelevel.FieldNo(PricingMethodCode),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          Format(CRMProductpricelevel.PricingMethodCode::CurrencyAmount), false, false);

        if CRMIntegrationManagement.IsUnitGroupMappingEnabled() then
            // Unit of Measure > UoMId
            InsertIntegrationFieldMapping(
              IntegrationTableMappingName,
              PriceListLine.FieldNo("Unit of Measure Code"),
              CRMProductpricelevel.FieldNo(UoMId),
              IntegrationFieldMapping.Direction::ToIntegrationTable,
              '', true, false)
        else
            // "Unit Of Measure" > UoMScheduleId
            InsertIntegrationFieldMapping(
              IntegrationTableMappingName,
              PriceListLine.FieldNo("Unit of Measure Code"),
              CRMProductpricelevel.FieldNo(UoMScheduleId),
              IntegrationFieldMapping.Direction::ToIntegrationTable,
              '', true, false);

        // "Unit Price" > Amount
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          PriceListLine.FieldNo("Unit Price"),
          CRMProductpricelevel.FieldNo(Amount),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        OnResetPriceListLineProductPricelevelMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 1440);
    end;

    [Scope('OnPrem')]
    procedure ResetUnitOfMeasureUoMScheduleMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        UnitOfMeasure: Record "Unit of Measure";
        CRMUomschedule: Record "CRM Uomschedule";
        IsHandled: Boolean;
    begin
        OnBeforeResetUnitOfMeasureUoMScheduleMapping(IntegrationTableMappingName, EnqueueJobQueEntry, IsHandled);
        if IsHandled then
            exit;
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::"Unit of Measure", DATABASE::"CRM Uomschedule",
          CRMUomschedule.FieldNo(UoMScheduleId), CRMUomschedule.FieldNo(ModifiedOn),
          '', '', true);

        // Code > BaseUoM Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          UnitOfMeasure.FieldNo(Code),
          CRMUomschedule.FieldNo(BaseUoMName),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueEntry, 720);
    end;

    [Scope('OnPrem')]
    procedure ResetUnitGroupUoMScheduleMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        UnitGroup: Record "Unit Group";
        CRMUomschedule: Record "CRM Uomschedule";
        IsHandled: Boolean;
    begin
        OnBeforeResetUnitGroupUoMScheduleMapping(IntegrationTableMappingName, EnqueueJobQueueEntry, IsHandled);
        if IsHandled then
            exit;

        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          Database::"Unit Group", Database::"CRM Uomschedule",
          CRMUomschedule.FieldNo(UoMScheduleId), CRMUomschedule.FieldNo(ModifiedOn),
          '', '', true);

        IntegrationTableMapping."Synch. After Bulk Coupling" := true;
        IntegrationTableMapping."Create New in Case of No Match" := true;
        IntegrationTableMapping.Modify();

        // "Source No." > Name - we prefix this in CRMIntTableSubscriber OnTransferFieldData
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          UnitGroup.FieldNo("Source No."),
          CRMUomschedule.FieldNo(Name),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        IntegrationFieldMapping.FindFirst();
        IntegrationFieldMapping."Use For Match-Based Coupling" := true;
        IntegrationFieldMapping.Modify();

        // "Source No." > BaseUoM Name - we prefix this in CRMIntTableSubscriber OnTransferFieldData
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          UnitGroup.FieldNo("Source No."),
          CRMUomschedule.FieldNo(BaseUoMName),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueueEntry, 720);
    end;

    [Scope('OnPrem')]
    procedure ResetItemUnitOfMeasureUoMMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        CRMUom: Record "CRM Uom";
        IsHandled: Boolean;
    begin
        OnBeforeResetItemUnitOfMeasureUoMMapping(IntegrationTableMappingName, EnqueueJobQueueEntry, IsHandled);
        if IsHandled then
            exit;

        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          Database::"Item Unit of Measure", Database::"CRM Uom",
          CRMUom.FieldNo(UoMId), CRMUom.FieldNo(ModifiedOn),
          '', '', true);

        IntegrationTableMapping."Synch. After Bulk Coupling" := true;
        IntegrationTableMapping."Create New in Case of No Match" := true;

        IntegrationTableMapping."Dependency Filter" := 'UNIT GROUP';
        IntegrationTableMapping.Modify();

        // Code > UoM Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          ItemUnitOfMeasure.FieldNo("Code"),
          CRMUom.FieldNo(Name),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        IntegrationFieldMapping.FindFirst();
        IntegrationFieldMapping."Use For Match-Based Coupling" := true;
        IntegrationFieldMapping.Modify();

        // Quantity > UoM Quantity
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          ItemUnitOfMeasure.FieldNo("Qty. per Unit of Measure"),
          CRMUom.FieldNo(Quantity),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueueEntry, 720);
    end;

    [Scope('OnPrem')]
    procedure ResetResourceUnitOfMeasureUoMMapping(IntegrationTableMappingName: Code[20]; EnqueueJobQueueEntry: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        CRMUom: Record "CRM Uom";
        IsHandled: Boolean;
    begin
        OnBeforeResetResourceUnitOfMeasureUoMMapping(IntegrationTableMappingName, EnqueueJobQueueEntry, IsHandled);
        if IsHandled then
            exit;

        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          Database::"Resource Unit of Measure", Database::"CRM Uom",
          CRMUom.FieldNo(UoMId), CRMUom.FieldNo(ModifiedOn),
          '', '', true);

        IntegrationTableMapping."Synch. After Bulk Coupling" := true;
        IntegrationTableMapping."Create New in Case of No Match" := true;

        IntegrationTableMapping."Dependency Filter" := 'UNIT GROUP';
        IntegrationTableMapping.Modify();

        // Code > UoM Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          ResourceUnitOfMeasure.FieldNo("Code"),
          CRMUom.FieldNo(Name),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        IntegrationFieldMapping.FindFirst();
        IntegrationFieldMapping."Use For Match-Based Coupling" := true;
        IntegrationFieldMapping.Modify();

        // Quantity > UoM Quantity
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          ResourceUnitOfMeasure.FieldNo("Qty. per Unit of Measure"),
          CRMUom.FieldNo(Quantity),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, 30, EnqueueJobQueueEntry, 720);
    end;

    [Scope('OnPrem')]
    procedure ResetOpportunityMapping(IntegrationTableMappingName: Code[20]; IsTeamOwnershipModel: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Opportunity: Record Opportunity;
        CRMOpportunity: Record "CRM Opportunity";
        CDSCompany: Record "CDS Company";
        EmptyGuid: Guid;
        IsHandled: Boolean;
    begin
        OnBeforeResetOpportunityMapping(IntegrationTableMappingName, IsHandled);
        if IsHandled then
            exit;
        InsertIntegrationTableMapping(
          IntegrationTableMapping, IntegrationTableMappingName,
          DATABASE::Opportunity, DATABASE::"CRM Opportunity",
          CRMOpportunity.FieldNo(OpportunityId), CRMOpportunity.FieldNo(ModifiedOn),
          '', '', false);

        Opportunity.SetFilter(Status, '%1|%2', Opportunity.Status::"Not Started", Opportunity.Status::"In Progress");
        IntegrationTableMapping.SetTableFilter(GetTableFilterFromView(DATABASE::Opportunity, Opportunity.TableCaption(), Opportunity.GetView()));
        IntegrationTableMapping."Dependency Filter" := 'CONTACT';
        IntegrationTableMapping.Modify();

        if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then begin
            CRMOpportunity.SetFilter(CompanyId, StrSubstno(OrTok, CDSCompany.CompanyId, EmptyGuid));
            IntegrationTableMapping.SetIntegrationTableFilter(
              GetTableFilterFromView(DATABASE::"CRM Opportunity", CRMOpportunity.TableCaption(), CRMOpportunity.GetView()));
            IntegrationTableMapping.Modify();
        end;

        // Description > Name
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Opportunity.FieldNo(Description),
          CRMOpportunity.FieldNo(Name),
          IntegrationFieldMapping.Direction::Bidirectional,
          '', true, false);

        // "Contact No." > ParentContactId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Opportunity.FieldNo("Contact No."),
          CRMOpportunity.FieldNo(ParentContactId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Contact Company No." > ParentAccountId
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Opportunity.FieldNo("Contact Company No."),
          CRMOpportunity.FieldNo(ParentAccountId),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        if not IsTeamOwnershipModel then begin
            // OwnerId = systemuser
            InsertIntegrationFieldMapping(
              IntegrationTableMappingName,
              0, CRMOpportunity.FieldNo(OwnerIdType),
              IntegrationFieldMapping.Direction::ToIntegrationTable,
              Format(CRMOpportunity.OwnerIdType::systemuser), false, false);

            // Salesperson Code > OwnerId
            InsertIntegrationFieldMapping(
              IntegrationTableMappingName,
              Opportunity.FieldNo("Salesperson Code"),
              CRMOpportunity.FieldNo(OwnerId),
              IntegrationFieldMapping.Direction::ToIntegrationTable,
              '', true, false);
            SetIntegrationFieldMappingNotNull();
        end;

        // "Estimated Value (LCY)" > EstimatedValue
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Opportunity.FieldNo("Estimated Value (LCY)"),
          CRMOpportunity.FieldNo(EstimatedValue),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        // "Estimated Closing Date" > EstimatedCloseDate
        InsertIntegrationFieldMapping(
          IntegrationTableMappingName,
          Opportunity.FieldNo("Estimated Closing Date"),
          CRMOpportunity.FieldNo(EstimatedCloseDate),
          IntegrationFieldMapping.Direction::ToIntegrationTable,
          '', true, false);

        OnResetOpportunityMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName);
    end;

    procedure InsertIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; MappingName: Code[20]; TableNo: Integer; IntegrationTableNo: Integer; IntegrationTableUIDFieldNo: Integer; IntegrationTableModifiedFieldNo: Integer; TableConfigTemplateCode: Code[10]; IntegrationTableConfigTemplateCode: Code[10]; SynchOnlyCoupledRecords: Boolean)
    var
        IsHandled: Boolean;
        UncoupleCodeunitId: Integer;
        Direction: Integer;
    begin
        OnBeforeInsertIntegrationTableMapping(IntegrationTableMapping, MappingName, TableNo, IntegrationTableNo, IntegrationTableUIDFieldNo,
          IntegrationTableModifiedFieldNo, TableConfigTemplateCode, IntegrationTableConfigTemplateCode,
        SynchOnlyCoupledRecords, IsHandled);

        if IsHandled then
            exit;

        Direction := GetDefaultDirection(TableNo);
        if Direction in [IntegrationTableMapping.Direction::ToIntegrationTable, IntegrationTableMapping.Direction::Bidirectional] then
            if CDSIntegrationMgt.HasCompanyIdField(IntegrationTableNo) then
                UncoupleCodeunitId := Codeunit::"CDS Int. Table Uncouple";

        IntegrationTableMapping.CreateRecord(MappingName, TableNo, IntegrationTableNo, IntegrationTableUIDFieldNo,
          IntegrationTableModifiedFieldNo, TableConfigTemplateCode, IntegrationTableConfigTemplateCode,
          SynchOnlyCoupledRecords, Direction, IntegrationTablePrefixTok,
          Codeunit::"CRM Integration Table Synch.", UncoupleCodeunitId);
    end;

    procedure InsertIntegrationFieldMapping(IntegrationTableMappingName: Code[20]; TableFieldNo: Integer; IntegrationTableFieldNo: Integer; SynchDirection: Option; ConstValue: Text; ValidateField: Boolean; ValidateIntegrationTableField: Boolean)
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        IsHandled: Boolean;
    begin
        OnBeforeInsertIntegrationFieldMapping(IntegrationTableMappingName, TableFieldNo, IntegrationTableFieldNo, SynchDirection, ConstValue,
          ValidateField, ValidateIntegrationTableField, IsHandled);

        if IsHandled then
            exit;

        IntegrationFieldMapping.CreateRecord(IntegrationTableMappingName, TableFieldNo, IntegrationTableFieldNo, SynchDirection,
          ConstValue, ValidateField, ValidateIntegrationTableField);
    end;

    procedure SetIntegrationFieldMappingClearValueOnFailedSync()
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.FindLast();
        IntegrationFieldMapping."Clear Value on Failed Sync" := true;
        IntegrationFieldMapping.Modify();
    end;

    procedure SetIntegrationFieldMappingNotNull()
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.FindLast();
        IntegrationFieldMapping."Not Null" := true;
        IntegrationFieldMapping.Modify();
    end;

    procedure CreateJobQueueEntry(IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    var
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
    begin
        exit(CDSSetupDefaults.CreateJobQueueEntry(IntegrationTableMapping, CRMProductName.SHORT()));
    end;

    local procedure RecreateStatisticsJobQueueEntry(EnqueueJobQueEntry: Boolean)
    begin
        RecreateJobQueueEntry(
          EnqueueJobQueEntry,
          CODEUNIT::"CRM Statistics Job",
          30,
          StrSubstNo(CustomStatisticsSynchJobDescTxt, CRMProductName.SHORT()),
          false);
    end;

    procedure RecreateItemAvailabilityJobQueueEntry(EnqueueJobQueEntry: Boolean)
    begin
        RecreateJobQueueEntry(
          EnqueueJobQueEntry,
          Codeunit::"CRM Item Availability Job",
          30,
          StrSubstNo(ItemAvailabilitySynchJobDescTxt, CRMProductName.SHORT()),
          false);
    end;

    procedure DeleteItemAvailabilityJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"CRM Item Availability Job");
        JobQueueEntry.DeleteTasks();
    end;

    [Scope('OnPrem')]
    procedure RecreateSalesOrderStatusJobQueueEntry(EnqueueJobQueEntry: Boolean)
    begin
        RecreateJobQueueEntry(
          EnqueueJobQueEntry,
          CODEUNIT::"CRM Order Status Update Job",
          7,
          StrSubstNo(CustomSalesOrderSynchJobDescTxt, CRMProductName.SHORT()),
          false);
    end;

    [Scope('OnPrem')]
    procedure RecreateSalesOrderNotesJobQueueEntry(EnqueueJobQueEntry: Boolean)
    begin
        RecreateJobQueueEntry(
          EnqueueJobQueEntry,
          CODEUNIT::"CRM Notes Synch Job",
          5,
          StrSubstNo(CustomSalesOrderNotesSynchJobDescTxt, CRMProductName.SHORT()),
          false);
    end;

    [Scope('OnPrem')]
    procedure RecreateArchivedSalesOrdersJobQueueEntry(EnqueueJobQueEntry: Boolean)
    begin
        RecreateJobQueueEntry(
          EnqueueJobQueEntry,
          Codeunit::"CRM Archived Sales Orders Job",
          30,
          StrSubstNo(ArchivedSalesOrdersSynchJobDescTxt, CRMProductName.SHORT()),
          false);
    end;

    procedure RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping: Record "Integration Table Mapping"; IntervalInMinutes: Integer; ShouldRecreateJobQueueEntry: Boolean; InactivityTimeoutPeriod: Integer)
    var
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
    begin
        CDSSetupDefaults.RecreateJobQueueEntryFromIntTableMapping(IntegrationTableMapping, IntervalInMinutes, ShouldRecreateJobQueueEntry, InactivityTimeoutPeriod, CRMProductName.SHORT(), false);
    end;

    procedure ResetCRMNAVConnectionData()
    begin
        CRMIntegrationManagement.SetCRMNAVConnectionUrl(GetUrl(CLIENTTYPE::Web));
    end;

    procedure RecreateAutoCreateSalesOrdersJobQueueEntry(EnqueueJobQueEntry: Boolean)
    begin
        RecreateJobQueueEntry(
          EnqueueJobQueEntry,
          CODEUNIT::"Auto Create Sales Orders",
          30,
          StrSubstNo(AutoCreateSalesOrdersTxt, CRMProductName.SHORT()),
          false);
    end;

    procedure RecreateAutoProcessSalesQuotesJobQueueEntry(EnqueueJobQueEntry: Boolean)
    begin
        RecreateJobQueueEntry(
          EnqueueJobQueEntry,
          CODEUNIT::"Auto Process Sales Quotes",
          30,
          StrSubstNo(AutoProcessQuotesTxt, CRMProductName.SHORT()),
          false);
    end;

    procedure RecreateJobQueueEntry(EnqueueJobQueEntry: Boolean; CodeunitId: Integer; MinutesBetweenRun: Integer; EntryDescription: Text; StatusReady: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CodeunitId);
        JobQueueEntry.DeleteTasks();

        JobQueueEntry.InitRecurringJob(MinutesBetweenRun);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CodeunitId;
        JobQueueEntry.Description := CopyStr(EntryDescription, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Maximum No. of Attempts to Run" := 2;
        if StatusReady then
            JobQueueEntry.Status := JobQueueEntry.Status::Ready
        else begin
            JobQueueEntry.Status := JobQueueEntry.Status::"On Hold with Inactivity Timeout";
            JobQueueEntry."Inactivity Timeout Period" := MinutesBetweenRun;
        end;
        JobQueueEntry."Rerun Delay (sec.)" := 30;
        if EnqueueJobQueEntry then
            CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry)
        else
            JobQueueEntry.Insert(true);
    end;

    procedure DeleteAutoCreateSalesOrdersJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Auto Create Sales Orders");
        JobQueueEntry.DeleteTasks();
    end;

    procedure DeleteAutoProcessSalesQuotesJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Auto Process Sales Quotes");
        JobQueueEntry.DeleteTasks();
    end;

    procedure GetAddPostedSalesDocumentToCRMAccountWallConfig(): Boolean
    begin
        exit(true);
    end;

    procedure GetAllowNonSecureConnections(): Boolean
    begin
        // Most OnPrem solutions uses http if running in a private domain. CRM Server only demands https if the system has been
        // configured with internet connectivity, which is not the default. NAV Should not contrain the connection to CRM if the system
        // admin has configured the CRM service to be on a private domain only.
        exit(true);
    end;

    procedure GetCRMTableNo(NAVTableID: Integer): Integer
    var
        CDSTableNo: Integer;
        handled: Boolean;
    begin
        OnGetCDSTableNo(NavTableId, CDSTableNo, handled);
        if handled then
            exit(CDSTableNo);

        case NAVTableID of
            DATABASE::Contact:
                exit(DATABASE::"CRM Contact");
            DATABASE::Currency:
                exit(DATABASE::"CRM Transactioncurrency");
            DATABASE::Customer:
                exit(DATABASE::"CRM Account");
            DATABASE::"Price List Header",
            DATABASE::"Customer Price Group":
                exit(DATABASE::"CRM Pricelevel");
            DATABASE::Item,
            DATABASE::Resource:
                exit(DATABASE::"CRM Product");
            DATABASE::"Sales Invoice Header":
                exit(DATABASE::"CRM Invoice");
            DATABASE::"Sales Invoice Line":
                exit(DATABASE::"CRM Invoicedetail");
            DATABASE::"Sales Price",
            DATABASE::"Price List Line":
                exit(DATABASE::"CRM Productpricelevel");
            DATABASE::"Salesperson/Purchaser":
                exit(DATABASE::"CRM Systemuser");
            DATABASE::"Unit of Measure":
                exit(DATABASE::"CRM Uomschedule");
            Database::"Unit Group":
                exit(Database::"CRM Uomschedule");
            Database::"Item Unit Of Measure",
                Database::"Resource Unit Of Measure":
                exit(Database::"CRM Uom");
            DATABASE::Opportunity:
                exit(DATABASE::"CRM Opportunity");
            DATABASE::"Sales Header":
                exit(DATABASE::"CRM Salesorder");
            DATABASE::"Record Link":
                exit(DATABASE::"CRM Annotation");
        end;
    end;

    procedure GetDefaultDirection(NAVTableID: Integer): Integer
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IsHandled: Boolean;
    begin
        OnBeforeGetDefaultDirection(NAVTableID, IntegrationTableMapping.Direction, IsHandled);
        if IsHandled then
            exit(IntegrationTableMapping.Direction);

        case NAVTableID of
            DATABASE::Contact,
          DATABASE::Customer,
          DATABASE::Item,
          DATABASE::Resource,
          DATABASE::Opportunity:
                exit(IntegrationTableMapping.Direction::Bidirectional);
            DATABASE::Currency,
          DATABASE::"Customer Price Group",
          DATABASE::"Price List Header",
          DATABASE::"Price List Line",
          DATABASE::"Sales Invoice Header",
          DATABASE::"Sales Invoice Line",
          DATABASE::"Sales Price",
          DATABASE::"Unit of Measure",
          DATABASE::"Unit Group",
          DATABASE::"Item Unit of Measure",
          DATABASE::"Resource Unit of Measure":
                exit(IntegrationTableMapping.Direction::ToIntegrationTable);
            DATABASE::"Payment Terms",
          DATABASE::"Shipment Method",
          DATABASE::"Shipping Agent",
          DATABASE::"Salesperson/Purchaser":
                exit(IntegrationTableMapping.Direction::FromIntegrationTable);
        end;
    end;

    procedure GetProductQuantityPrecision(): Integer
    begin
        exit(2);
    end;

    procedure GetNameFieldNo(TableID: Integer): Integer
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CustomerPriceGroup: Record "Customer Price Group";
        CRMPricelevel: Record "CRM Pricelevel";
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        UnitOfMeasure: Record "Unit of Measure";
        CRMUomschedule: Record "CRM Uomschedule";
        Opportunity: Record Opportunity;
        CRMOpportunity: Record "CRM Opportunity";
        UnitGroup: Record "Unit Group";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        CRMUom: Record "CRM Uom";
        PaymentTerms: Record "Payment Terms";
        ShipmentMethod: Record "Shipment Method";
        ShippingAgent: Record "Shipping Agent";
        CRMPaymentTerms: Record "CRM Payment Terms";
        CRMFreightTerms: Record "CRM Freight Terms";
        CRMShippingMethod: Record "CRM Shipping Method";
        SalesHeader: Record "Sales Header";
        CRMSalesorder: Record "CRM Salesorder";
        FieldNo: Integer;
    begin
        OnBeforeGetNameFieldNo(TableID, FieldNo);
        if FieldNo <> 0 then
            exit(FieldNo);
        case TableID of
            DATABASE::Contact:
                exit(Contact.FieldNo(Name));
            DATABASE::"CRM Contact":
                exit(CRMContact.FieldNo(FullName));
            DATABASE::Currency:
                exit(Currency.FieldNo(Code));
            DATABASE::"CRM Transactioncurrency":
                exit(CRMTransactioncurrency.FieldNo(ISOCurrencyCode));
            DATABASE::Customer:
                exit(Customer.FieldNo(Name));
            DATABASE::"CRM Account":
                exit(CRMAccount.FieldNo(Name));
            DATABASE::"Customer Price Group":
                exit(CustomerPriceGroup.FieldNo(Code));
            DATABASE::"CRM Pricelevel":
                exit(CRMPricelevel.FieldNo(Name));
            DATABASE::Item:
                exit(Item.FieldNo("No."));
            DATABASE::"Price List Header":
                exit(PriceListHeader.FieldNo(Code));
            DATABASE::Resource:
                exit(Resource.FieldNo("No."));
            DATABASE::"CRM Product":
                exit(CRMProduct.FieldNo(ProductNumber));
            DATABASE::"Salesperson/Purchaser":
                exit(SalespersonPurchaser.FieldNo(Name));
            DATABASE::"CRM Systemuser":
                exit(CRMSystemuser.FieldNo(FullName));
            DATABASE::"Unit of Measure":
                exit(UnitOfMeasure.FieldNo(Code));
            DATABASE::"CRM Uomschedule":
                exit(CRMUomschedule.FieldNo(Name));
            DATABASE::Opportunity:
                exit(Opportunity.FieldNo(Description));
            DATABASE::"CRM Opportunity":
                exit(CRMOpportunity.FieldNo(Name));
            DATABASE::"Unit Group":
                exit(UnitGroup.FieldNo("Source No."));
            DATABASE::"Item Unit of Measure":
                exit(ItemUnitOfMeasure.FieldNo(Code));
            DATABASE::"Resource Unit of Measure":
                exit(ResourceUnitOfMeasure.FieldNo(Code));
            DATABASE::"CRM Uom":
                exit(CRMUom.FieldNo(Name));
            DATABASE::"Payment Terms":
                exit(PaymentTerms.FieldNo("Code"));
            DATABASE::"Shipment Method":
                exit(ShipmentMethod.FieldNo("Code"));
            DATABASE::"Shipping Agent":
                exit(ShippingAgent.FieldNo("Code"));
            DATABASE::"CRM Payment Terms":
                exit(CRMPaymentTerms.FieldNo("Code"));
            DATABASE::"CRM Freight Terms":
                exit(CRMFreightTerms.FieldNo("Code"));
            DATABASE::"CRM Shipping Method":
                exit(CRMShippingMethod.FieldNo("Code"));
            DATABASE::"Sales Header":
                exit(SalesHeader.FieldNo("No."));
            DATABASE::"CRM Salesorder":
                exit(CRMSalesorder.FieldNo(Name));
        end;
    end;

    procedure GetTableFilterFromView(TableID: Integer; Caption: Text; View: Text): Text
    var
        FilterBuilder: FilterPageBuilder;
    begin
        FilterBuilder.AddTable(Caption, TableID);
        FilterBuilder.SetView(Caption, View);
        exit(FilterBuilder.GetView(Caption, false));
    end;

    procedure GetPrioritizedMappingList(var NameValueBuffer: Record "Name/Value Buffer")
    var
        "Field": Record "Field";
        IntegrationTableMapping: Record "Integration Table Mapping";
        NextPriority: Integer;
    begin
        NextPriority := 1;

        // 1) From CRM Systemusers
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, 0, DATABASE::"CRM Systemuser");
        // 2) From Currency
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Currency, 0);
        // 3) From Unit of measure
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::"Unit of Measure", 0);
        // 4) To/From Customers/CRM Accounts
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Customer, DATABASE::"CRM Account");
        // 5) To/From Contacts/CRM Contacts
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Contact, DATABASE::"CRM Contact");
        // 6) From Items to CRM Products
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Item, DATABASE::"CRM Product");
        // 7) From Resources to CRM Products
        AddPrioritizedMappingsToList(NameValueBuffer, NextPriority, DATABASE::Resource, DATABASE::"CRM Product");

        IntegrationTableMapping.Reset();
        IntegrationTableMapping.SetFilter("Parent Name", '=''''');
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Int. Table UID Field Type", Field.Type::GUID);
        IntegrationTableMapping.SetFilter("Table ID", '<>113');
        if IntegrationTableMapping.FindSet() then
            repeat
                AddPrioritizedMappingToList(NameValueBuffer, NextPriority, IntegrationTableMapping.Name);
            until IntegrationTableMapping.Next() = 0;
    end;

    local procedure AddPrioritizedMappingsToList(var NameValueBuffer: Record "Name/Value Buffer"; var Priority: Integer; TableID: Integer; IntegrationTableID: Integer)
    var
        "Field": Record "Field";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.Reset();
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        if TableID > 0 then
            IntegrationTableMapping.SetRange("Table ID", TableID);
        if IntegrationTableID > 0 then
            IntegrationTableMapping.SetRange("Integration Table ID", IntegrationTableID);
        IntegrationTableMapping.SetRange("Int. Table UID Field Type", Field.Type::GUID);
        if IntegrationTableMapping.FindSet() then
            repeat
                AddPrioritizedMappingToList(NameValueBuffer, Priority, IntegrationTableMapping.Name);
            until IntegrationTableMapping.Next() = 0;
    end;

    local procedure AddPrioritizedMappingToList(var NameValueBuffer: Record "Name/Value Buffer"; var Priority: Integer; MappingName: Code[20])
    begin
        NameValueBuffer.SetRange(Value, MappingName);

        if not NameValueBuffer.FindFirst() then begin
            NameValueBuffer.Init();
            NameValueBuffer.ID := Priority;
            NameValueBuffer.Name := Format(Priority);
            NameValueBuffer.Value := MappingName;
            NameValueBuffer.Insert();
            Priority := Priority + 1;
        end;

        NameValueBuffer.Reset();
    end;

    procedure GetTableIDCRMEntityNameMapping(var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        TempNameValueBuffer.Reset();
        TempNameValueBuffer.DeleteAll();

        AddEntityTableMapping('systemuser', DATABASE::"Salesperson/Purchaser", TempNameValueBuffer);
        AddEntityTableMapping('systemuser', DATABASE::"CRM Systemuser", TempNameValueBuffer);

        AddEntityTableMapping('account', DATABASE::Customer, TempNameValueBuffer);
        AddEntityTableMapping('account', DATABASE::"CRM Account", TempNameValueBuffer);

        AddEntityTableMapping('contact', DATABASE::Contact, TempNameValueBuffer);
        AddEntityTableMapping('contact', DATABASE::"CRM Contact", TempNameValueBuffer);

        AddEntityTableMapping('product', DATABASE::Item, TempNameValueBuffer);
        AddEntityTableMapping('product', DATABASE::"CRM Product", TempNameValueBuffer);
        AddEntityTableMapping('product', DATABASE::Resource, TempNameValueBuffer);

        AddEntityTableMapping('salesorder', DATABASE::"Sales Header", TempNameValueBuffer);
        AddEntityTableMapping('salesorder', DATABASE::"CRM Salesorder", TempNameValueBuffer);

        AddEntityTableMapping('invoice', DATABASE::"Sales Invoice Header", TempNameValueBuffer);
        AddEntityTableMapping('invoice', DATABASE::"CRM Invoice", TempNameValueBuffer);

        AddEntityTableMapping('opportunity', DATABASE::Opportunity, TempNameValueBuffer);
        AddEntityTableMapping('opportunity', DATABASE::"CRM Opportunity", TempNameValueBuffer);

        // Only NAV
        if PriceCalculationMgt.IsExtendedPriceCalculationEnabled() then begin
            AddEntityTableMapping('pricelevel', DATABASE::"Price List Header", TempNameValueBuffer);
            AddEntityTableMapping('productpricelevel', DATABASE::"Price List Line", TempNameValueBuffer);
            AddEntityTableMapping('pricelevel', DATABASE::"CRM Pricelevel", TempNameValueBuffer);
            AddEntityTableMapping('productpricelevel', DATABASE::"CRM Productpricelevel", TempNameValueBuffer)
        end else
            AddEntityTableMapping('pricelevel', DATABASE::"Customer Price Group", TempNameValueBuffer);
        AddEntityTableMapping('transactioncurrency', DATABASE::Currency, TempNameValueBuffer);
        if CRMIntegrationManagement.IsUnitGroupMappingEnabled() then begin
            AddEntityTableMapping('uomschedule', DATABASE::"Unit Group", TempNameValueBuffer);
            AddEntityTableMapping('uom', DATABASE::"Item Unit of Measure", TempNameValueBuffer);
            AddEntityTableMapping('uom', DATABASE::"Resource Unit of Measure", TempNameValueBuffer);
        end else
            AddEntityTableMapping('uomschedule', DATABASE::"Unit of Measure", TempNameValueBuffer);


        // Only CRM
        AddEntityTableMapping('incident', DATABASE::"CRM Incident", TempNameValueBuffer);
        AddEntityTableMapping('quote', DATABASE::"CRM Quote", TempNameValueBuffer);
        AddEntityTableMapping('team', DATABASE::"CRM Team", TempNameValueBuffer);

        // Virtual Tables
        AddEntityTableMapping('msdyn_businesscentralvirtualentity', DATABASE::"CRM BC Virtual Table Config.", TempNameValueBuffer);

        OnAddEntityTableMapping(TempNameValueBuffer);
    end;

    procedure AddEntityTableMapping(CRMEntityTypeName: Text; TableID: Integer; var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
        OnBeforeAddEntityTableMapping(CRMEntityTypeName, TableID, TempNameValueBuffer);
        TempNameValueBuffer.Init();
        TempNameValueBuffer.ID := GetLastNameValueBuffer(TempNameValueBuffer);
        TempNameValueBuffer.Name := CopyStr(CRMEntityTypeName, 1, MaxStrLen(TempNameValueBuffer.Name));
        TempNameValueBuffer.Value := Format(TableID);
        TempNameValueBuffer.Insert();
    end;

    local procedure GetLastNameValueBuffer(var TempNameValueBuffer: Record "Name/Value Buffer" temporary): Integer
    begin
        if TempNameValueBuffer.FindLast() then
            exit(TempNameValueBuffer.ID + 1)
        else
            exit(1);
    end;

    local procedure ResetDefaultCRMPricelevel(CRMConnectionSetup: Record "CRM Connection Setup")
    begin
        CRMConnectionSetup.Find();
        Clear(CRMConnectionSetup."Default CRM Price List ID");
        CRMConnectionSetup.Modify();
    end;

    local procedure SetIntegrationTableFilterForCRMProduct(var IntegrationTableMapping: Record "Integration Table Mapping"; CRMProduct: Record "CRM Product"; ProductTypeCode: Option)
    var
        CDSCompany: Record "CDS Company";
        EmptyGuid: Guid;
    begin
        if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then
            CRMProduct.SetFilter(CompanyId, StrSubstno(OrTok, CDSCompany.CompanyId, EmptyGuid));
        CRMProduct.SetRange(ProductTypeCode, ProductTypeCode);
        CRMProduct.SetRange(StateCode, CRMProduct.StateCode::Active);
        IntegrationTableMapping.SetIntegrationTableFilter(
          GetTableFilterFromView(DATABASE::"CRM Product", CRMProduct.TableCaption(), CRMProduct.GetView()));
        IntegrationTableMapping.Modify();
    end;

    procedure CreateInventoryQuantityFieldMapping()
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
    begin
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", 'ITEM-PRODUCT');
        IntegrationFieldMapping.SetRange("Field No.", Item.FieldNo(Inventory));
        IntegrationFieldMapping.SetRange("Integration Table Field No.", CRMProduct.FieldNo(QuantityOnHand));
        if IntegrationFieldMapping.IsEmpty() then
            InsertIntegrationFieldMapping(
              'ITEM-PRODUCT',
              Item.FieldNo(Inventory),
              CRMProduct.FieldNo(QuantityOnHand),
              IntegrationFieldMapping.Direction::ToIntegrationTable,
              '', true, false);
    end;

    [Scope('OnPrem')]
    procedure SetCustomIntegrationsTableMappings(CRMConnectionSetup: Record "CRM Connection Setup")
    begin
        OnAfterResetConfiguration(CRMConnectionSetup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetConfiguration(CRMConnectionSetup: Record "CRM Connection Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCDSTableNo(BCTableNo: Integer; var CDSTableNo: Integer; var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddEntityTableMapping(var TempNameValueBuffer: Record "Name/Value Buffer" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetItemProductMapping(var IntegrationTableMappingName: Code[20]; var EnqueueJobQueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetResourceProductMapping(var IntegrationTableMappingName: Code[20]; var EnqueueJobQueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetSalesInvoiceHeaderInvoiceMapping(var IntegrationTableMappingName: Code[20]; var EnqueueJobQueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetSalesInvoiceLineInvoiceMapping(var IntegrationTableMappingName: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetSalesOrderMapping(var IntegrationTableMappingName: Code[20]; var EnqueueJobQueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetBidirectionalSalesOrderMapping(var IntegrationTableMappingName: Code[20]; var EnqueueJobQueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetBidirectionalSalesOrderLineMapping(var IntegrationTableMappingName: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetPriceListHeaderPricelevelMapping(var IntegrationTableMappingName: Code[20]; var EnqueueJobQueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetPriceListLineProductPricelevelMapping(var IntegrationTableMappingName: Code[20]; var EnqueueJobQueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetUnitOfMeasureUoMScheduleMapping(var IntegrationTableMappingName: Code[20]; var EnqueueJobQueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetUnitGroupUoMScheduleMapping(var IntegrationTableMappingName: Code[20]; var EnqueueJobQueueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetItemUnitOfMeasureUoMMapping(var IntegrationTableMappingName: Code[20]; var EnqueueJobQueueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetResourceUnitOfMeasureUoMMapping(var IntegrationTableMappingName: Code[20]; var EnqueueJobQueueEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetOpportunityMapping(var IntegrationTableMappingName: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; var MappingName: Code[20]; var TableNo: Integer; var IntegrationTableNo: Integer; var IntegrationTableUIDFieldNo: Integer; var IntegrationTableModifiedFieldNo: Integer; var TableConfigTemplateCode: Code[10]; var IntegrationTableConfigTemplateCode: Code[10]; var SynchOnlyCoupledRecords: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertIntegrationFieldMapping(var IntegrationTableMappingName: Code[20]; var TableFieldNo: Integer; var IntegrationTableFieldNo: Integer; var SynchDirection: Option; var ConstValue: Text; var ValidateField: Boolean; var ValidateIntegrationTableField: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultDirection(NAVTableId: Integer; var DefaultDirection: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNameFieldNo(TableId: Integer; var FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddEntityTableMapping(var CRMEntityTypeName: Text; var TableID: Integer; var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetConfiguration(var CRMConnectionSetup: Record "CRM Connection Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResetCustomerPriceGroupPricelevelMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName: Code[20])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnResetItemProductMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResetOpportunityMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResetPriceListHeaderPricelevelMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResetPriceListLineProductPricelevelMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResetResourceProductMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResetSalesInvoiceHeaderInvoiceMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResetSalesInvoiceLineInvoiceMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResetSalesOrderMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResetBidirectionalSalesOrderMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResetBidirectionalSalesOrderLineMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName: Code[20])
    begin
    end;

#if not CLEAN27
    [Obsolete('This event is never raised.', '27.0')]
    [IntegrationEvent(true, false)]
    local procedure OnGetTableIDCRMEntityNameMappingOnAfterAddFSEntityTableMapping(var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnResetSalesPriceProductPricelevelMappingOnAfterInsertFieldsMapping(IntegrationTableMappingName: Code[20])
    begin
    end;
}
