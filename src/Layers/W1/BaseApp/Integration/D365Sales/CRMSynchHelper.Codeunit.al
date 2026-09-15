// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Outlook;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.SyncEngine;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;
using System;
using System.IO;
using System.Reflection;

codeunit 5342 "CRM Synch. Helper"
{
    Permissions = TableData "Sales Invoice Header" = m;

    trigger OnRun()
    begin
    end;

    var
        TempCRMPricelevel: Record "CRM Pricelevel" temporary;
        TempCRMTransactioncurrency: Record "CRM Transactioncurrency" temporary;
        TempCRMUom: Record "CRM Uom" temporary;
        TempCRMUomschedule: Record "CRM Uomschedule" temporary;
        CRMProductName: Codeunit "CRM Product Name";
        CRMBaseCurrencyNotFoundInNAVErr: Label 'The currency with the ISO code ''%1'' cannot be found. Therefore, the exchange rate between ''%2'' and ''%3'' cannot be calculated.', Comment = '%1,%2,%3=the ISO code of a currency (example: DKK);';
        DynamicsCRMTransactionCurrencyRecordNotFoundErr: Label 'Cannot find the currency with the value ''%1'' in Dataverse.', Comment = '%1=the currency code';
        DynamicsCRMUoMNotFoundInGroupErr: Label 'Cannot find any unit of measure inside the unit group ''%1'' in %2.', Comment = '%1=Unit Group Name, %2 = Dataverse service name';
        DynamicsCRMUoMFoundMultipleInGroupErr: Label 'Multiple units of measure were found in the unit group ''%1'' in %2.', Comment = '%1=Unit Group Name, %2 = Dataverse service name';
        IncorrectCRMUoMNameErr: Label 'The unit of measure in the unit group ''%1'' has an incorrect name: expected name ''%2'', found name ''%3''.', Comment = '%1=Unit Group name (ex: NAV PIECE), %2=Expected name (ex: PIECE), %3=Actual name (ex: BOX)';
        IncorrectCRMUoMQuantityErr: Label 'The quantity on the unit of measure ''%1'' should be 1.', Comment = '%1=unit of measure name (ex: PIECE).';
        DynamicsCRMUomscheduleNotFoundErr: Label 'Cannot find the unit group ''%1'' in %2.', Comment = '%1 = unit group name, %2 = Dataverse service name';
        IncorrectCRMUoMStatusErr: Label 'The unit of measure ''%1'' is not the base unit of measure of the unit group ''%2''.', Comment = '%1=value of the unit of measure, %2=value of the unit group';
        InvalidDestinationRecordNoErr: Label 'Invalid destination record number.';
        NavTxt: Label 'NAV', Locked = true;
        RecordMustBeCoupledErr: Label '%1 %2 must be coupled to a %3 record.', Comment = '%1 = table caption, %2 = primary key value, %3 = CRM Table caption';
        UnitOfMeasureMustBeCoupledErr: Label '%1 Unit of Measure (%2, %3) must be coupled to a %4 record.', Comment = '%1 = table caption, %2 = primary key value, %3 = primary key value, %4 = CRM Table caption';
        RecordNotFoundErr: Label '%1 could not be found in %2.', Comment = '%1=value;%2=table name in which the value was searched';
        CanOnlyUseSystemUserOwnerTypeErr: Label 'Only %1 Owner of Type SystemUser can be mapped to Salespeople.', Comment = 'Dataverse entity owner property can be of type team or systemuser. Only the type systemuser is supported. %1 = Dataverse service name';
        DefaultNAVPriceListNameTxt: Label '%1 Default Price List', Comment = '%1 - product name';
        BaseCurrencyIsNullErr: Label 'The base currency is not defined. Disable and enable CRM connection to initialize setup properly.';
        CurrencyPriceListNameTxt: Label 'Price List in %1', Comment = '%1 - currency code';
        UnableToFindPageForRecordErr: Label 'Unable to find a page for record %1.', Comment = '%1 ID of the record';
        MappingMustBeSetForGUIDFieldErr: Label 'Table %1 must be mapped to table %2 to transfer value between fields %3 and %4.', Comment = '%1 and %2 are table captions, %3 and %4 are field captions.';
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        SetContactParentCompanyTxt: Label 'Setting contact parent company.', Locked = true;
        SetContactParentCompanySuccessfulTxt: Label 'Set contact parent company successfuly. Company No.: %1', Locked = true, Comment = '%1 = parent company no.';
        ContactBusinessRelationOptionalTxt: Label 'Contact business relation is optional.', Locked = true;
        ContactTypeCheckIgnoredTxt: Label 'Contact type check is ignored.', Locked = true;
        ItemUnitGroupNotFoundErr: Label 'Item Unit Group for Item %1 is not found.', Comment = '%1 - item number';
        ResourceUnitGroupNotFoundErr: Label 'Resource Unit Group for Resource %1 is not found.', Comment = '%1 - resource number';
        CRMUnitGroupNotFoundErr: Label 'CRM Unit Group %1 does not exist.', Comment = '%1 - unit group name';
        BaseUnitOfMeasureCannotBeEmptyErr: Label 'Base Unit of Measure must have a value in %1. It cannot be zero or empty.', Comment = '%1 - record';
        RecordMustBeCoupledExtErr: Label '%1 %2 must be coupled to a %3 row.', Comment = '%1 = BC table caption, %2 = primary key value, %3 - Dataverse table caption';
        CannotUseSameUnitGroupErr: Label 'Unit group %1 is assigned to multiple products. You cannot use the same unit group for multiple products.', Comment = '%1 - Unit group name';
        UnitOfMeasureDoesNotExistErr: Label 'Unit of measure %1 does not exist.', Comment = '%1 - unit of measure code';
        IncorrectFormatOrTypeErr: Label 'The value that you are trying to convert is in incorrect format.';
        OrderPriceListLbl: Label 'Business Central Order %1 Price List', Locked = true, Comment = '%1 - Order No.';

    procedure ClearCache()
    begin
        TempCRMPricelevel.Reset();
        TempCRMPricelevel.DeleteAll();
        Clear(TempCRMPricelevel);

        TempCRMTransactioncurrency.Reset();
        TempCRMTransactioncurrency.DeleteAll();
        Clear(TempCRMTransactioncurrency);

        TempCRMUom.Reset();
        TempCRMUom.DeleteAll();
        Clear(TempCRMUom);

        TempCRMUomschedule.Reset();
        TempCRMUomschedule.DeleteAll();
        Clear(TempCRMUomschedule);
    end;

    procedure GetDefaultPriceListName(): Text[100]
    begin
        exit(StrSubstNo(DefaultNAVPriceListNameTxt, PRODUCTNAME.Short()));
    end;

    local procedure GetDefaultPriceListNameWithLCY(): Text[100]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(StrSubstNo(DefaultNAVPriceListNameTxt, PRODUCTNAME.Short() + ' ' + GeneralLedgerSetup."LCY Code"));
    end;

    local procedure CreateCRMDefaultPriceList(var CRMPricelevel: Record "CRM Pricelevel")
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        FindNAVLocalCurrencyInCRM(CRMTransactioncurrency);
        CRMPricelevel.Reset();
        CRMPricelevel.SetRange(Name, GetDefaultPriceListName());

        if CRMPricelevel.FindFirst() then begin
            if CRMPricelevel.TransactionCurrencyId = CRMTransactioncurrency.TransactionCurrencyId then begin
                AddToCacheCRMPriceLevel(CRMPricelevel);
                exit;
            end;
            Clear(CRMPriceLevel);
            CRMPricelevel.Name := GetDefaultPriceListNameWithLCY();
            CRMPricelevel.TransactionCurrencyId := CRMTransactioncurrency.TransactionCurrencyId;
            CRMPricelevel.Insert();
            AddToCacheCRMPriceLevel(CRMPricelevel);
            exit;
        end;

        CRMPriceLevel.Init();
        CRMPricelevel.Name := GetDefaultPriceListName();
        CRMPricelevel.TransactionCurrencyId := CRMTransactioncurrency.TransactionCurrencyId;
        CRMPricelevel.Insert();
        AddToCacheCRMPriceLevel(CRMPricelevel);
    end;

    procedure CreateCRMPricelevelInCurrency(var CRMPricelevel: Record "CRM Pricelevel"; CurrencyCode: Code[10]; NewExchangeRate: Decimal)
    var
        CRMOrganization: Record "CRM Organization";
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        CRMOrganization.FindFirst();
        FindCurrencyCRMIntegrationRecord(CRMIntegrationRecord, CurrencyCode);

        CRMPricelevel.Init();
        CRMPricelevel.PriceLevelId := Format(CreateGuid());
        CRMPricelevel.OrganizationId := CRMOrganization.OrganizationId;
        CRMPricelevel.Name :=
          CopyStr(StrSubstNo(CurrencyPriceListNameTxt, CurrencyCode), 1, MaxStrLen(CRMPricelevel.Name));
        CRMPricelevel.TransactionCurrencyId := CRMIntegrationRecord."CRM ID";
        CRMPricelevel.ExchangeRate := NewExchangeRate;
        CRMPricelevel.Insert();
    end;

    procedure CreateCRMPriceList(SalesHeader: Record "Sales Header"; var CRMPricelevel: Record "CRM Pricelevel")
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Resource: Record Resource;
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMProduct: Record "CRM Product";
        CRMUom: Record "CRM Uom";
        CRMId: Guid;
    begin
        CRMPricelevel.Init();
        CRMPricelevel.Name := StrSubstNo(OrderPriceListLbl, SalesHeader."No.");
        if SalesHeader."Currency Code" = '' then begin
            FindNAVLocalCurrencyInCRM(CRMTransactioncurrency);
            CRMPricelevel.TransactionCurrencyId := CRMTransactioncurrency.TransactionCurrencyId;
        end else begin
            FindCurrencyCRMIntegrationRecord(CRMIntegrationRecord, SalesHeader."Currency Code");
            CRMPricelevel.TransactionCurrencyId := CRMIntegrationRecord."CRM ID";
        end;
        CRMPricelevel.Insert();

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                case SalesLine.Type of
                    SalesLine.Type::Item:
                        begin
                            Item.Get(SalesLine."No.");
                            if CRMIntegrationRecord.FindIDFromRecordID(Item.RecordId, CRMId) then
                                if CRMProduct.Get(CRMId) then begin
                                    CRMUom.SetRange(UoMScheduleId, CRMProduct.DefaultUoMScheduleId);
                                    if CRMUom.FindSet() then
                                        repeat
                                            CreateCRMProductpricelevelForProductAndUom(CRMProduct, CRMPricelevel.PriceLevelId, CRMUom);
                                        until CRMUom.Next() = 0;
                                end;
                        end;
                    SalesLine.Type::Resource:
                        begin
                            Resource.Get(SalesLine."No.");
                            if CRMIntegrationRecord.FindIDFromRecordID(Resource.RecordId, CRMId) then
                                if CRMProduct.Get(CRMId) then begin
                                    CRMUom.SetRange(UoMScheduleId, CRMProduct.DefaultUoMScheduleId);
                                    if CRMUom.FindSet() then
                                        repeat
                                            CreateCRMProductpricelevelForProductAndUom(CRMProduct, CRMPricelevel.PriceLevelId, CRMUom);
                                        until CRMUom.Next() = 0;
                                end;
                        end;
                end;
            until SalesLine.Next() = 0;
    end;

    procedure UpdateCRMPriceList(SalesHeader: Record "Sales Header"; CRMPricelevelId: Guid)
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Resource: Record Resource;
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMProduct: Record "CRM Product";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        CRMUom: Record "CRM Uom";
        CRMId: Guid;
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                case SalesLine.Type of
                    SalesLine.Type::Item:
                        begin
                            Item.Get(SalesLine."No.");
                            if CRMIntegrationRecord.FindIDFromRecordID(Item.RecordId, CRMId) then begin
                                CRMProductpricelevel.SetRange(PriceLevelId, CRMPricelevelId);
                                CRMProductpricelevel.SetRange(ProductId, CRMId);
                                if CRMProductpricelevel.IsEmpty() then
                                    if CRMProduct.Get(CRMId) then begin
                                        CRMUom.SetRange(UoMScheduleId, CRMProduct.DefaultUoMScheduleId);
                                        if CRMUom.FindSet() then
                                            repeat
                                                CreateCRMProductpricelevelForProductAndUom(CRMProduct, CRMPricelevelId, CRMUom);
                                            until CRMUom.Next() = 0;
                                    end;
                            end;
                        end;
                    SalesLine.Type::Resource:
                        begin
                            Resource.Get(SalesLine."No.");
                            if CRMIntegrationRecord.FindIDFromRecordID(Resource.RecordId, CRMId) then begin
                                CRMProductpricelevel.SetRange(PriceLevelId, CRMPricelevelId);
                                CRMProductpricelevel.SetRange(ProductId, CRMId);
                                if CRMProductpricelevel.IsEmpty() then
                                    if CRMProduct.Get(CRMId) then begin
                                        CRMUom.SetRange(UoMScheduleId, CRMProduct.DefaultUoMScheduleId);
                                        if CRMUom.FindSet() then
                                            repeat
                                                CreateCRMProductpricelevelForProductAndUom(CRMProduct, CRMPricelevelId, CRMUom);
                                            until CRMUom.Next() = 0;
                                    end;
                            end;
                        end;
                end;
            until SalesLine.Next() = 0;
    end;

    local procedure CreateCRMProductpricelevelForProduct(CRMProduct: Record "CRM Product"; NewPriceLevelId: Guid)
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
    begin
        CRMProductpricelevel.Init();
        CRMProductpricelevel.PriceLevelId := NewPriceLevelId;
        CRMProductpricelevel.UoMId := CRMProduct.DefaultUoMId;
        CRMProductpricelevel.UoMScheduleId := CRMProduct.DefaultUoMScheduleId;
        CRMProductpricelevel.ProductId := CRMProduct.ProductId;
        CRMProductpricelevel.Amount := CRMProduct.Price;
        CRMProductpricelevel.TransactionCurrencyId := CRMProduct.TransactionCurrencyId;
        CRMProductpricelevel.ProductNumber := CRMProduct.ProductNumber;
        CRMProductpricelevel.Insert();
    end;

    procedure CreateCRMProductpricelevelForProductAndUom(CRMProduct: Record "CRM Product"; NewPriceLevelId: Guid; CRMUom: Record "CRM Uom")
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
    begin
        CRMProductpricelevel.Init();
        CRMProductpricelevel.PriceLevelId := NewPriceLevelId;
        CRMProductpricelevel.UoMId := CRMUom.UoMId;
        CRMProductpricelevel.UoMScheduleId := CRMProduct.DefaultUoMScheduleId;
        CRMProductpricelevel.ProductId := CRMProduct.ProductId;
        CRMProductpricelevel.Amount := CRMProduct.Price * CRMUom.Quantity;
        CRMProductpricelevel.ProductNumber := CRMProduct.ProductNumber;
        CRMProductpricelevel.Insert();
    end;

    procedure CreateCRMProductpriceIfAbsent(CRMInvoicedetail: Record "CRM Invoicedetail")
    var
        CRMInvoice: Record "CRM Invoice";
    begin
        if not IsNullGuid(CRMInvoicedetail.ProductId) then begin
            CRMInvoice.Get(CRMInvoicedetail.InvoiceId);
            if not IsNullGuid(CRMInvoice.PriceLevelId) then
                if not FindCRMProductPriceFromCRMInvoicedetailAndCRMInvoice(CRMInvoicedetail, CRMInvoice) then
                    CreateCRMProductpriceFromCRMInvoiceDetail(CRMInvoicedetail);
        end;
    end;

    local procedure CreateCRMProductpriceFromCRMInvoiceDetail(CRMInvoicedetail: Record "CRM Invoicedetail")
    var
        CRMInvoice: Record "CRM Invoice";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        CRMUom: Record "CRM Uom";
    begin
        if CRMInvoicedetail.PricePerUnit <= 0 then
            exit;
        CRMInvoice.Get(CRMInvoicedetail.InvoiceId);
        CRMUom.Get(CRMInvoicedetail.UoMId);
        CRMProductpricelevel.Init();
        CRMProductpricelevel.PriceLevelId := CRMInvoice.PriceLevelId;
        CRMProductpricelevel.ProductId := CRMInvoicedetail.ProductId;
        CRMProductpricelevel.UoMId := CRMInvoicedetail.UoMId;
        CRMProductpricelevel.UoMScheduleId := CRMUom.UoMScheduleId;
        CRMProductpricelevel.Amount := CRMInvoicedetail.PricePerUnit;
        CRMProductpricelevel.Insert();
    end;

    local procedure CreateCRMTransactioncurrency(var CRMTransactioncurrency: Record "CRM Transactioncurrency"; CurrencyCode: Code[10])
    begin
        CRMTransactioncurrency.Init();
        CRMTransactioncurrency.ISOCurrencyCode := CopyStr(CurrencyCode, 1, MaxStrLen(CRMTransactioncurrency.ISOCurrencyCode));
        CRMTransactioncurrency.CurrencyName := CRMTransactioncurrency.ISOCurrencyCode;
        CRMTransactioncurrency.CurrencySymbol := CRMTransactioncurrency.ISOCurrencyCode;
        CRMTransactioncurrency.CurrencyPrecision := GetCRMCurrencyDefaultPrecision();
        CRMTransactioncurrency.ExchangeRate := GetCRMLCYToFCYExchangeRate(CRMTransactioncurrency.ISOCurrencyCode);
        CRMTransactioncurrency.Insert();
    end;

    procedure FindCRMDefaultPriceList(var CRMPricelevel: Record "CRM Pricelevel")
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        CRMConnectionSetup.Get();
        if not FindCRMPriceList(CRMPricelevel, CRMConnectionSetup."Default CRM Price List ID") then begin
            CreateCRMDefaultPriceList(CRMPricelevel);
            CRMConnectionSetup.Validate("Default CRM Price List ID", CRMPricelevel.PriceLevelId);
            CRMConnectionSetup.Modify();
        end;
    end;

    local procedure FindCRMPriceList(var CRMPricelevel: Record "CRM Pricelevel"; PriceListId: Guid): Boolean
    begin
        if not IsNullGuid(PriceListId) then begin
            CRMPricelevel.Reset();
            CRMPricelevel.SetRange(PriceLevelId, PriceListId);
            exit(FindCachedCRMPriceLevel(CRMPricelevel));
        end;
    end;

    procedure FindCRMPriceListByCurrencyCode(var CRMPricelevel: Record "CRM Pricelevel"; CurrencyCode: Code[10]): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if CurrencyCode = '' then begin
            FindCRMDefaultPriceList(CRMPricelevel);
            exit(true);
        end;

        FindCurrencyCRMIntegrationRecord(CRMIntegrationRecord, CurrencyCode);
        CRMPricelevel.Reset();
        CRMPricelevel.SetRange(Name, CopyStr(StrSubstNo(CurrencyPriceListNameTxt, CurrencyCode), 1, MaxStrLen(CRMPricelevel.Name)));
        CRMPricelevel.SetRange(TransactionCurrencyId, CRMIntegrationRecord."CRM ID");
        exit(FindCachedCRMPriceLevel(CRMPricelevel));
    end;

    procedure FindCRMProductPriceFromCRMInvoicedetail(CRMInvoicedetail: Record "CRM Invoicedetail"): Boolean
    var
        CRMInvoice: Record "CRM Invoice";
        CRMProductpricelevel: Record "CRM Productpricelevel";
    begin
        CRMInvoice.Get(CRMInvoicedetail.InvoiceId);
        CRMProductpricelevel.SetRange(PriceLevelId, CRMInvoice.PriceLevelId);
        CRMProductpricelevel.SetRange(ProductId, CRMInvoicedetail.ProductId);
        CRMProductpricelevel.SetRange(UoMId, CRMInvoicedetail.UoMId);
        exit(not CRMProductpricelevel.IsEmpty());
    end;

    local procedure FindCRMProductPriceFromCRMInvoicedetailAndCRMInvoice(CRMInvoicedetail: Record "CRM Invoicedetail"; CRMInvoice: Record "CRM Invoice"): Boolean
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
    begin
        CRMProductpricelevel.SetRange(PriceLevelId, CRMInvoice.PriceLevelId);
        CRMProductpricelevel.SetRange(ProductId, CRMInvoicedetail.ProductId);
        CRMProductpricelevel.SetRange(UoMId, CRMInvoicedetail.UoMId);
        exit(not CRMProductpricelevel.IsEmpty());
    end;

    local procedure FindCurrencyCRMIntegrationRecord(var CRMIntegrationRecord: Record "CRM Integration Record"; CurrencyCode: Code[10])
    var
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        Currency.Get(CurrencyCode);
        if not CRMIntegrationRecord.FindByRecordID(Currency.RecordId()) then
            Error(RecordMustBeCoupledErr, Currency.TableCaption(), CurrencyCode, CRMTransactioncurrency.TableCaption());
    end;

    local procedure FindContactByAccountId(var Contact: Record Contact; AccountId: Guid; var OutOfMapFilter: Boolean): Boolean
    var
        IsVendorsSyncEnabled: Boolean;
        CustomerOutOfMapFilter: Boolean;
        VendorOutOfMapFilter: Boolean;
    begin
        if FindCustomersContactByAccountId(Contact, AccountId, CustomerOutOfMapFilter) then
            exit(true);

        OnGetVendorSyncEnabled(IsVendorsSyncEnabled);
        if IsVendorsSyncEnabled then
            if FindVendorsContactByAccountId(Contact, AccountId, VendorOutOfMapFilter) then
                exit(true);

        OutOfMapFilter := CustomerOutOfMapFilter or VendorOutOfMapFilter;
        exit(false);
    end;

    local procedure FindCustomersContactByAccountId(var Contact: Record Contact; AccountId: Guid; var OutOfMapFilter: Boolean): Boolean
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: Record Customer;
        CustomerRecordID: RecordID;
        IsHandled: Boolean;
    begin
        if IsNullGuid(AccountId) then
            exit(false);

        OnFindAndSynchRecordIDFromIntegrationSystemId(AccountId, Database::Customer, CustomerRecordID, IsHandled);
        if not IsHandled then
            if not CRMIntegrationRecord.FindRecordIDFromID(AccountId, Database::Customer, CustomerRecordID) then
                if SynchRecordIfMappingExists(Database::Customer, Database::"CRM Account", AccountId, OutOfMapFilter) then begin
                    if not CRMIntegrationRecord.FindRecordIDFromID(AccountId, Database::Customer, CustomerRecordID) then
                        exit(false);
                end else
                    if OutOfMapFilter then
                        exit(false);

        if Customer.Get(CustomerRecordID) then begin
            ContactBusinessRelation.SetCurrentKey("Link to Table", "No.");
            ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
            ContactBusinessRelation.SetRange("No.", Customer."No.");
            if ContactBusinessRelation.FindFirst() then
                exit(Contact.Get(ContactBusinessRelation."Contact No."));
        end;

        exit(false);
    end;

    local procedure FindVendorsContactByAccountId(var Contact: Record Contact; AccountId: Guid; var OutOfMapFilter: Boolean): Boolean
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Vendor: Record Vendor;
        VendorRecordID: RecordID;
        IsHandled: Boolean;
    begin
        if IsNullGuid(AccountId) then
            exit(false);

        OnFindAndSynchRecordIDFromIntegrationSystemId(AccountId, Database::Vendor, VendorRecordID, IsHandled);
        if not IsHandled then
            if not CRMIntegrationRecord.FindRecordIDFromID(AccountId, Database::Vendor, VendorRecordID) then
                if SynchRecordIfMappingExists(Database::Vendor, Database::"CRM Account", AccountId, OutOfMapFilter) then begin
                    if not CRMIntegrationRecord.FindRecordIDFromID(AccountId, Database::Vendor, VendorRecordID) then
                        exit(false);
                end else
                    if OutOfMapFilter then
                        exit(false);

        if Vendor.Get(VendorRecordID) then begin
            ContactBusinessRelation.SetCurrentKey("Link to Table", "No.");
            ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
            ContactBusinessRelation.SetRange("No.", Vendor."No.");
            if ContactBusinessRelation.FindFirst() then
                exit(Contact.Get(ContactBusinessRelation."Contact No."));
        end;

        exit(false);
    end;

    procedure FindNAVLocalCurrencyInCRM(var CRMTransactioncurrency: Record "CRM Transactioncurrency"): Guid
    var
        NAVLCYCode: Code[10];
    begin
        NAVLCYCode := GetNavLCYCode();
        CRMTransactioncurrency.SetRange(ISOCurrencyCode, NAVLCYCode);
        if not FindCachedCRMTransactionCurrency(CRMTransactioncurrency) then begin
            CreateCRMTransactioncurrency(CRMTransactioncurrency, NAVLCYCode);
            AddToCacheCRMTransactionCurrency(CRMTransactioncurrency);
        end;
        exit(CRMTransactioncurrency.TransactionCurrencyId);
    end;

    procedure GetBaseCurrencyPrecision() DecimalPrecision: Decimal
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        BaseCurrencyPrecision: integer;
        handled: Boolean;
    begin
        DecimalPrecision := 1;
        OnGetCDSBaseCurrencyPrecision(BaseCurrencyPrecision, handled);

        if not handled then begin
            CRMConnectionSetup.Get();
            BaseCurrencyPrecision := CRMConnectionSetup.BaseCurrencyPrecision;
        end;

        if BaseCurrencyPrecision > 0 then
            DecimalPrecision := Power(10, -BaseCurrencyPrecision);
    end;

    procedure GetCRMCurrencyDefaultPrecision(): Integer
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CurrencyDecimalPrecision: Integer;
        handled: Boolean;
    begin
        OnGetCDSCurrencyDecimalPrecision(CurrencyDecimalPrecision, handled);

        if handled then
            exit(CurrencyDecimalPrecision);

        CRMConnectionSetup.Get();
        exit(CRMConnectionSetup.CurrencyDecimalPrecision);
    end;

    local procedure GetCRMBaseCurrencyId(): Guid
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        BaseCurrencyId: Guid;
        handled: Boolean;
    begin
        OnGetCDSBaseCurrencyId(BaseCurrencyId, handled);

        if handled then
            exit(BaseCurrencyId);

        CRMConnectionSetup.Get();
        exit(CRMConnectionSetup.BaseCurrencyId);
    end;

    local procedure GetCRMBaseCurrencySymbol(): Text[5]
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        BaseCurrencySymbol: Text[5];
        handled: Boolean;
    begin
        OnGetCDSBaseCurrencySymbol(BaseCurrencySymbol, handled);

        if handled then
            exit(BaseCurrencySymbol);

        CRMConnectionSetup.Get();
        exit(CRMConnectionSetup.BaseCurrencySymbol);
    end;

    local procedure GetCRMExchangeRateRoundingPrecision(): Decimal
    begin
        exit(0.0000000001);
    end;

    procedure GetCRMLCYToFCYExchangeRate(ToCurrencyISOCode: Text[10]): Decimal
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        BaseCurrencyId: Guid;
        BaseCurrencySymbol: Text[5];
    begin
        BaseCurrencyId := GetCRMBaseCurrencyId();
        BaseCurrencySymbol := GetCRMBaseCurrencySymbol();
        if IsNullGuid(BaseCurrencyId) then
            Error(BaseCurrencyIsNullErr);
        if ToCurrencyISOCode = DelChr(BaseCurrencySymbol) then
            exit(1.0);

        CRMTransactioncurrency.SetRange(TransactionCurrencyId, BaseCurrencyId);
        if not FindCachedCRMTransactionCurrency(CRMTransactioncurrency) then
            Error(DynamicsCRMTransactionCurrencyRecordNotFoundErr, BaseCurrencySymbol);
        exit(GetFCYtoFCYExchangeRate(CRMTransactioncurrency.ISOCurrencyCode, ToCurrencyISOCode));
    end;

    procedure GetFCYtoFCYExchangeRate(FromFCY: Code[10]; ToFCY: Code[10]): Decimal
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CalculatedExchangeRate: Decimal;
        NavLCYCode: Code[10];
    begin
        FromFCY := DelChr(FromFCY);
        ToFCY := DelChr(ToFCY);
        if (FromFCY = '') or (ToFCY = '') then
            Error(CRMBaseCurrencyNotFoundInNAVErr, '', ToFCY, FromFCY);

        if ToFCY = FromFCY then
            exit(1.0);

        NavLCYCode := GetNavLCYCode();
        if ToFCY = NavLCYCode then
            ToFCY := '';

        if FromFCY = NavLCYCode then
            exit(CurrencyExchangeRate.GetCurrentCurrencyFactor(ToFCY));

        if not Currency.Get(FromFCY) then
            Error(CRMBaseCurrencyNotFoundInNAVErr, FromFCY, ToFCY, FromFCY);

        // In CRM exchange rate is inverted, so ExchangeAmtFCYToFCY takes (ToFCY,FromFCY) instead of (FromFCY,ToFCY)
        CalculatedExchangeRate := CurrencyExchangeRate.ExchangeAmtFCYToFCY(WorkDate(), ToFCY, FromFCY, 1);
        CalculatedExchangeRate := Round(CalculatedExchangeRate, GetCRMExchangeRateRoundingPrecision(), '=');
        exit(CalculatedExchangeRate);
    end;

    local procedure GetNavLCYCode(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("LCY Code");
        exit(GeneralLedgerSetup."LCY Code");
    end;

    procedure GetUnitGroupName(UnitOfMeasureCode: Text): Text[200]
    begin
        exit(CopyStr(StrSubstNo('%1 %2', NavTxt, UnitOfMeasureCode), 1, 200));
    end;

    procedure GetUnitOfMeasureName(UnitOfMeasureRecordRef: RecordRef): Text[100]
    var
        UnitOfMeasure: Record "Unit of Measure";
        UnitOfMeasureCodeFieldRef: FieldRef;
    begin
        UnitOfMeasureCodeFieldRef := UnitOfMeasureRecordRef.Field(UnitOfMeasure.FieldNo(Code));
        exit(CopyStr(Format(UnitOfMeasureCodeFieldRef.Value()), 1, 100));
    end;

    procedure SetCRMDecimalsSupportedValue(var CRMProduct: Record "CRM Product")
    var
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
    begin
        CRMProduct.QuantityDecimal := CRMSetupDefaults.GetProductQuantityPrecision();
    end;

    procedure SetCRMDefaultPriceListOnProduct(var CRMProduct: Record "CRM Product") AdditionalFieldsWereModified: Boolean
    var
        CRMPricelevel: Record "CRM Pricelevel";
    begin
        FindCRMDefaultPriceList(CRMPricelevel);

        if CRMProduct.PriceLevelId <> CRMPricelevel.PriceLevelId then begin
            CRMProduct.PriceLevelId := CRMPricelevel.PriceLevelId;
            AdditionalFieldsWereModified := true;
        end;
    end;

    procedure SetCRMProductStateToActive(var CRMProduct: Record "CRM Product")
    begin
        CRMProduct.StateCode := CRMProduct.StateCode::Active;
        CRMProduct.StatusCode := CRMProduct.StatusCode::Active;
    end;

    procedure SetCRMProductStateToRetired(var CRMProduct: Record "CRM Product")
    begin
        CRMProduct.StateCode := CRMProduct.StateCode::Retired;
        CRMProduct.StatusCode := CRMProduct.StatusCode::Retired;
    end;

    procedure SetContactParentCompany(AccountID: Guid; DestinationContactRecordRef: RecordRef): Boolean
    var
        Contact: Record Contact;
        CompanyContact: Record Contact;
        Result: Boolean;
        OutOfMapFilter: Boolean;
    begin
        Session.LogMessage('0000ECD', SetContactParentCompanyTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        if DestinationContactRecordRef.Number() <> DATABASE::Contact then
            Error(InvalidDestinationRecordNoErr);

        Result := FindContactByAccountId(CompanyContact, AccountID, OutOfMapFilter);

        if not Result then
            OnFailedFindContactByAccountId(DestinationContactRecordRef, CompanyContact, AccountID, OutOfMapFilter, Result);

        DestinationContactRecordRef.SetTable(Contact);
        Contact."Company No." := CompanyContact."No.";
        Contact."Company Name" := CompanyContact.Name;
        Contact.UpdateBusinessRelation();
        DestinationContactRecordRef.GetTable(Contact);

        Session.LogMessage('0000ECI', StrSubstNo(SetContactParentCompanySuccessfulTxt, CompanyContact."No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        exit(Result or OutOfMapFilter);
    end;

    [Scope('Cloud')]
    procedure SynchRecordIfMappingExists(TableNo: Integer; IntegrationTableNo: Integer; PrimaryKey: Variant): Boolean
    var
        OutOfMapFilter: Boolean;
    begin
        exit(SynchRecordIfMappingExists(TableNo, IntegrationTableNo, PrimaryKey, OutOfMapFilter));
    end;

    [Scope('Cloud')]
    procedure SynchRecordIfMappingExists(TableNo: Integer; IntegrationTableNo: Integer; PrimaryKey: Variant; var OutOfMapFilter: Boolean): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        NewJobEntryId: Guid;
    begin
        if IntegrationTableMapping.FindMapping(TableNo, IntegrationTableNo) then begin
            NewJobEntryId := CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, PrimaryKey, true, false);
            OutOfMapFilter := CRMIntegrationTableSynch.GetOutOfMapFilter();
        end;

        if IsNullGuid(NewJobEntryId) then
            exit(false);
        if IntegrationSynchJob.Get(NewJobEntryId) then
            exit(
              (IntegrationSynchJob.Inserted > 0) or
              (IntegrationSynchJob.Modified > 0) or
              (IntegrationSynchJob.Unchanged > 0));
    end;

    procedure UpdateCRMCurrencyIdIfChanged(CurrencyCode: Text; var DestinationCurrencyIDFieldRef: FieldRef): Boolean
    begin
        // Given a source NAV currency code, find a currency with the same ISO code in CRM and update the target CRM currency value if needed
        exit(UpdateFieldRefValueIfChanged(DestinationCurrencyIDFieldRef, GetCRMTransactioncurrency(CurrencyCode)));
    end;

    procedure UpdateCRMInvoiceStatus(var CRMInvoice: Record "CRM Invoice"; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        if CustLedgerEntry.FindFirst() then
            UpdateCRMInvoiceStatusFromEntry(CRMInvoice, CustLedgerEntry);
    end;

    internal procedure CancelCRMInvoice(var CRMInvoice: Record "CRM Invoice"): Integer
    var
        NewCRMInvoice: Record "CRM Invoice";
        ChangeNeeded: Boolean;
    begin
        NewCRMInvoice.StateCode := NewCRMInvoice.StateCode::Canceled;
        NewCRMInvoice.StatusCode := NewCRMInvoice.StatusCode::Canceled;
        ChangeNeeded := false;
        OnCancelCRMInvoiceOnBeforeCheckFieldsChanged(CRMInvoice, NewCRMInvoice, ChangeNeeded);
        if ChangeNeeded or (NewCRMInvoice.StateCode <> CRMInvoice.StateCode) or (NewCRMInvoice.StatusCode <> CRMInvoice.StatusCode) then begin
            ActivateInvoiceForFurtherUpdate(CRMInvoice);
            CRMInvoice.StateCode := NewCRMInvoice.StateCode;
            CRMInvoice.StatusCode := NewCRMInvoice.StatusCode;
            OnCancelCRMInvoiceOnBeforeModifyCRMInvoice(CRMInvoice, NewCRMInvoice);
            CRMInvoice.Modify();
            exit(1);
        end;
    end;

    procedure UpdateCRMInvoiceStatusFromEntry(var CRMInvoice: Record "CRM Invoice"; CustLedgerEntry: Record "Cust. Ledger Entry"): Integer
    var
        NewCRMInvoice: Record "CRM Invoice";
        ChangeNeeded: Boolean;
    begin
        CalculateActualStatusCode(CustLedgerEntry, NewCRMInvoice);
        ChangeNeeded := false;
        OnUpdateCRMInvoiceStatusFromEntryOnBeforeCheckFieldsChanged(CRMInvoice, NewCRMInvoice, CustLedgerEntry, ChangeNeeded);
        if ChangeNeeded or (NewCRMInvoice.StateCode <> CRMInvoice.StateCode) or (NewCRMInvoice.StatusCode <> CRMInvoice.StatusCode) then begin
            ActivateInvoiceForFurtherUpdate(CRMInvoice);
            CRMInvoice.StateCode := NewCRMInvoice.StateCode;
            CRMInvoice.StatusCode := NewCRMInvoice.StatusCode;
            OnUpdateCRMInvoiceStatusFromEntryOnBeforeModify(CRMInvoice, NewCRMInvoice, CustLedgerEntry);
            CRMInvoice.Modify();
            exit(1);
        end;
    end;

    local procedure CalculateActualStatusCode(CustLedgerEntry: Record "Cust. Ledger Entry"; var CRMInvoice: Record "CRM Invoice")
    var
        IsHandled: Boolean;
    begin
        CustLedgerEntry.CalcFields("Remaining Amount", Amount);

        IsHandled := false;
        OnBeforeCalculateActualStatusCode(CustLedgerEntry, CRMInvoice, IsHandled);
        if IsHandled then
            exit;

        if CustLedgerEntry."Remaining Amount" = 0 then begin
            CRMInvoice.StateCode := CRMInvoice.StateCode::Paid;
            CRMInvoice.StatusCode := CRMInvoice.StatusCode::Complete;
        end else
            if CustLedgerEntry."Remaining Amount" <> CustLedgerEntry.Amount then begin
                CRMInvoice.StateCode := CRMInvoice.StateCode::Paid;
                CRMInvoice.StatusCode := CRMInvoice.StatusCode::Partial;
            end else begin
                CRMInvoice.StateCode := CRMInvoice.StateCode::Active;
                CRMInvoice.StatusCode := CRMInvoice.StatusCode::Billed;
            end;
    end;

    local procedure ActivateInvoiceForFurtherUpdate(var CRMInvoice: Record "CRM Invoice")
    begin
        if CRMInvoice.StateCode <> CRMInvoice.StateCode::Active then begin
            CRMInvoice.StateCode := CRMInvoice.StateCode::Active;
            CRMInvoice.StatusCode := CRMInvoice.StatusCode::Billed;
            CRMInvoice.Modify();
        end;
    end;

    procedure UpdateCRMPriceListItem(var CRMProduct: Record "CRM Product") AdditionalFieldsWereModified: Boolean
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
    begin
        if IsNullGuid(CRMProduct.ProductId) then
            exit(false);

        AdditionalFieldsWereModified := SetCRMDefaultPriceListOnProduct(CRMProduct);
        CRMProductpricelevel.SetRange(ProductId, CRMProduct.ProductId);
        CRMProductpricelevel.SetRange(PriceLevelId, CRMProduct.PriceLevelId);
        if CRMProductpricelevel.FindFirst() then
            exit(UpdateCRMProductpricelevel(CRMProductpricelevel, CRMProduct) or AdditionalFieldsWereModified);

        CreateCRMProductpricelevelForProduct(CRMProduct, CRMProduct.PriceLevelId);
        exit(true);
    end;

    procedure UpdateCRMPriceListItems(var CRMProduct: Record "CRM Product") AdditionalFieldsWereModified: Boolean
    var
        CRMUom: Record "CRM Uom";
    begin
        if IsNullGuid(CRMProduct.ProductId) then
            exit(false);

        AdditionalFieldsWereModified := SetCRMDefaultPriceListOnProduct(CRMProduct);
        CRMUom.SetRange(UoMScheduleId, CRMProduct.DefaultUoMScheduleId);
        if CRMUom.FindSet() then
            repeat
                if UpdateOrCreateCRMProductprivelevelForUom(CRMProduct, CRMUom) then
                    AdditionalFieldsWereModified := true;
            until CRMUom.Next() = 0;
        exit(AdditionalFieldsWereModified);
    end;

    procedure UpdateCRMPriceListItemForUom(var CRMProduct: Record "CRM Product"; CRMUom: Record "CRM Uom") AdditionalFieldsWereModified: Boolean
    begin
        if IsNullGuid(CRMProduct.ProductId) or IsNullGuid(CRMUom.UoMId) then
            exit(false);

        AdditionalFieldsWereModified := SetCRMDefaultPriceListOnProduct(CRMProduct);

        if UpdateOrCreateCRMProductprivelevelForUom(CRMProduct, CRMUom) then
            AdditionalFieldsWereModified := true;

        exit(AdditionalFieldsWereModified);
    end;

    local procedure UpdateOrCreateCRMProductprivelevelForUom(var CRMProduct: Record "CRM Product"; CRMUom: Record "CRM Uom"): Boolean
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
    begin
        CRMProductpricelevel.SetRange(ProductId, CRMProduct.ProductId);
        CRMProductpricelevel.SetRange(PriceLevelId, CRMProduct.PriceLevelId);
        CRMProductpricelevel.SetRange(UoMScheduleId, CRMProduct.DefaultUoMScheduleId);
        CRMProductpricelevel.SetRange(UoMId, CRMUom.UoMId);
        if CRMProductpricelevel.FindFirst() then begin
            if UpdateCRMProductpricelevelWithUom(CRMProductpricelevel, CRMProduct, CRMUom) then
                exit(true);
        end else begin
            CreateCRMProductpricelevelForProductAndUom(CRMProduct, CRMProduct.PriceLevelId, CRMUom);
            exit(true);
        end;
    end;

    procedure UpdateCRMProductPriceIfNegative(var CRMProduct: Record "CRM Product"): Boolean
    begin
        // CRM doesn't allow negative prices. Update the price to zero, if negative (this preserves the behavior of the old CRM Connector)
        if CRMProduct.Price < 0 then begin
            CRMProduct.Price := 0;
            exit(true);
        end;

        exit(false);
    end;

    procedure UpdateCRMProductQuantityOnHandIfNegative(var CRMProduct: Record "CRM Product"): Boolean
    begin
        // Update to zero, if negative (this preserves the behavior of the old CRM Connector)
        if CRMProduct.QuantityOnHand < 0 then begin
            CRMProduct.QuantityOnHand := 0;
            exit(true);
        end;

        exit(false);
    end;

    local procedure UpdateCRMProductpricelevel(var CRMProductpricelevel: Record "CRM Productpricelevel"; CRMProduct: Record "CRM Product") AdditionalFieldsWereModified: Boolean
    begin
        if CRMProductpricelevel.PriceLevelId <> CRMProduct.PriceLevelId then begin
            CRMProductpricelevel.PriceLevelId := CRMProduct.PriceLevelId;
            AdditionalFieldsWereModified := true;
        end;

        if CRMProductpricelevel.UoMId <> CRMProduct.DefaultUoMId then begin
            CRMProductpricelevel.UoMId := CRMProduct.DefaultUoMId;
            AdditionalFieldsWereModified := true;
        end;

        if CRMProductpricelevel.UoMScheduleId <> CRMProduct.DefaultUoMScheduleId then begin
            CRMProductpricelevel.UoMScheduleId := CRMProduct.DefaultUoMScheduleId;
            AdditionalFieldsWereModified := true;
        end;

        if CRMProductpricelevel.Amount <> CRMProduct.Price then begin
            CRMProductpricelevel.Amount := CRMProduct.Price;
            AdditionalFieldsWereModified := true;
        end;

        if CRMProductpricelevel.TransactionCurrencyId <> CRMProduct.TransactionCurrencyId then begin
            CRMProductpricelevel.TransactionCurrencyId := CRMProduct.TransactionCurrencyId;
            AdditionalFieldsWereModified := true;
        end;

        if CRMProductpricelevel.ProductNumber <> CRMProduct.ProductNumber then begin
            CRMProductpricelevel.ProductNumber := CRMProduct.ProductNumber;
            AdditionalFieldsWereModified := true;
        end;

        if AdditionalFieldsWereModified then
            CRMProductpricelevel.Modify();
    end;

    local procedure UpdateCRMProductpricelevelWithUom(var CRMProductpricelevel: Record "CRM Productpricelevel"; CRMProduct: Record "CRM Product"; CRMUom: Record "CRM Uom") AdditionalFieldsWereModified: Boolean
    begin
        if CRMProductpricelevel.PriceLevelId <> CRMProduct.PriceLevelId then begin
            CRMProductpricelevel.PriceLevelId := CRMProduct.PriceLevelId;
            AdditionalFieldsWereModified := true;
        end;

        if CRMProductpricelevel.UoMId <> CRMUom.UoMId then begin
            CRMProductpricelevel.UoMId := CRMUom.UoMId;
            AdditionalFieldsWereModified := true;
        end;

        if CRMProductpricelevel.UoMScheduleId <> CRMProduct.DefaultUoMScheduleId then begin
            CRMProductpricelevel.UoMScheduleId := CRMProduct.DefaultUoMScheduleId;
            AdditionalFieldsWereModified := true;
        end;

        if CRMProductpricelevel.Amount <> CRMProduct.Price * CRMUom.Quantity then begin
            CRMProductpricelevel.Amount := CRMProduct.Price * CRMUom.Quantity;
            AdditionalFieldsWereModified := true;
        end;

        if CRMProductpricelevel.TransactionCurrencyId <> CRMProduct.TransactionCurrencyId then begin
            CRMProductpricelevel.TransactionCurrencyId := CRMProduct.TransactionCurrencyId;
            AdditionalFieldsWereModified := true;
        end;

        if CRMProductpricelevel.ProductNumber <> CRMProduct.ProductNumber then begin
            CRMProductpricelevel.ProductNumber := CRMProduct.ProductNumber;
            AdditionalFieldsWereModified := true;
        end;

        if AdditionalFieldsWereModified then
            CRMProductpricelevel.Modify();
    end;

    procedure UpdateCRMProductTypeCodeIfChanged(var CRMProduct: Record "CRM Product"; NewProductTypeCode: Integer): Boolean
    begin
        // We use ProductTypeCode::SalesInventory and ProductTypeCode::Services to trace back later,
        // where this CRM product originated from: a NAV Item, or a NAV Resource
        if CRMProduct.ProductTypeCode <> NewProductTypeCode then begin
            CRMProduct.ProductTypeCode := NewProductTypeCode;
            exit(true);
        end;

        exit(false);
    end;

    procedure UpdateCRMProductStateCodeIfChanged(var CRMProduct: Record "CRM Product"; NewBlocked: Boolean): Boolean
    var
        NewStateCode: Option;
    begin
        if NewBlocked then
            NewStateCode := CRMProduct.StateCode::Retired
        else
            NewStateCode := CRMProduct.StateCode::Active;

        if NewStateCode <> CRMProduct.StateCode then begin
            if NewBlocked then
                SetCRMProductStateToRetired(CRMProduct)
            else
                SetCRMProductStateToActive(CRMProduct);
            exit(true);
        end;

        exit(false);
    end;

    procedure UpdateItemBlockedIfChanged(var Item: Record Item; NewBlocked: Boolean): Boolean
    begin
        if Item.Blocked <> NewBlocked then begin
            Item.Blocked := NewBlocked;
            exit(true);
        end;
    end;

    procedure UpdateResourceBlockedIfChanged(var Resource: Record Resource; NewBlocked: Boolean): Boolean
    begin
        if Resource.Blocked <> NewBlocked then begin
            Resource.Blocked := NewBlocked;
            exit(true);
        end;
    end;

    procedure UpdateCRMProductUoMFieldsIfChanged(var CRMProduct: Record "CRM Product"; UnitOfMeasureCode: Code[10]): Boolean
    var
        CRMUom: Record "CRM Uom";
        CRMUomschedule: Record "CRM Uomschedule";
        AdditionalFieldsWereModified: Boolean;
    begin
        // Get the unit of measure ID used in this product
        // On that unit of measure ID, get the UoMName, UomscheduleID, UomscheduleName and update them in the product if needed

        GetValidCRMUnitOfMeasureRecords(CRMUom, CRMUomschedule, UnitOfMeasureCode);

        // Update UoM ID if changed
        if CRMProduct.DefaultUoMId <> CRMUom.UoMId then begin
            CRMProduct.DefaultUoMId := CRMUom.UoMId;
            AdditionalFieldsWereModified := true;
        end;

        // Update the Uomschedule ID if changed
        if CRMProduct.DefaultUoMScheduleId <> CRMUomschedule.UoMScheduleId then begin
            CRMProduct.DefaultUoMScheduleId := CRMUomschedule.UoMScheduleId;
            AdditionalFieldsWereModified := true;
        end;

        exit(AdditionalFieldsWereModified);
    end;

    procedure UpdateCRMProductUomscheduleId(var CRMProduct: Record "CRM Product"; SourceRecordRef: RecordRef): Boolean
    var
        Item: Record Item;
        Resource: Record Resource;
        UnitGroup: Record "Unit Group";
        CRMUomschedule: Record "CRM Uomschedule";
        AdditionalFieldsWereModified: Boolean;
    begin
        if SourceRecordRef.Number() = Database::Item then begin
            SourceRecordRef.SetTable(Item);
            if not UnitGroup.Get(UnitGroup."Source Type"::Item, Item.SystemId) then
                Error(ItemUnitGroupNotFoundErr, Item."No.");
        end;

        if SourceRecordRef.Number() = Database::Resource then begin
            SourceRecordRef.SetTable(Resource);
            if not UnitGroup.Get(UnitGroup."Source Type"::Resource, Resource.SystemId) then
                Error(ResourceUnitGroupNotFoundErr, Resource."No.");
        end;

        CRMUomschedule.SetRange(Name, UnitGroup.GetCode());
        if not CRMUomschedule.FindFirst() then
            Error(CRMUnitGroupNotFoundErr, UnitGroup.GetCode());

        if CRMProduct.DefaultUoMScheduleId <> CRMUomschedule.UoMScheduleId then begin
            CRMProduct.DefaultUoMScheduleId := CRMUomschedule.UoMScheduleId;
            AdditionalFieldsWereModified := true;
        end;

        exit(AdditionalFieldsWereModified);
    end;

    procedure UpdateCRMProductVendorNameIfChanged(var CRMProduct: Record "CRM Product"): Boolean
    var
        Vendor: Record Vendor;
    begin
        if not Vendor.Get(CopyStr(CRMProduct.VendorID, 1, MaxStrLen(Vendor."No."))) then
            exit(false);

        if CRMProduct.VendorName <> Vendor.Name then begin
            CRMProduct.VendorName := Vendor.Name;
            exit(true);
        end;

        exit(false);
    end;

    procedure UpdateOwnerIfChanged(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef; SourceSalespersonCodeFieldNo: Integer; DestinationOwnerFieldNo: Integer; DestinationOwnerTypeFieldNo: Integer; DestinationOwnerTypeValue: Option): Boolean
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalespersonCodeFieldRef: FieldRef;
        OwnerFieldRef: FieldRef;
        OwnerTypeFieldRef: FieldRef;
        OwnerGuid: Guid;
        CurrentOwnerGuid: Guid;
    begin
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Table ID", DATABASE::"Salesperson/Purchaser");
        IntegrationTableMapping.SetRange("Integration Table ID", DATABASE::"CRM Systemuser");
        if not IntegrationTableMapping.FindFirst() then
            exit(false); // There are no mapping for salepeople to SystemUsers

        SalespersonCodeFieldRef := SourceRecordRef.Field(SourceSalespersonCodeFieldNo);

        // Ignore empty salesperson code.
        if Format(SalespersonCodeFieldRef.Value()) = '' then
            exit(false);

        SalespersonPurchaser.SetFilter(Code, Format(SalespersonCodeFieldRef.Value()));
        if not SalespersonPurchaser.FindFirst() then
            Error(RecordNotFoundErr, SalespersonCodeFieldRef.Value(), SalespersonPurchaser.TableCaption());

        if not CRMIntegrationRecord.FindIDFromRecordID(SalespersonPurchaser.RecordId(), OwnerGuid) then
            Error(
              RecordMustBeCoupledErr, SalespersonPurchaser.TableCaption(), SalespersonCodeFieldRef.Value(),
              IntegrationTableMapping.GetExtendedIntegrationTableCaption());

        OwnerFieldRef := DestinationRecordRef.Field(DestinationOwnerFieldNo);
        CurrentOwnerGuid := OwnerFieldRef.Value();
        if CurrentOwnerGuid <> OwnerGuid then begin
            OwnerFieldRef.Value := OwnerGuid;
            OwnerTypeFieldRef := DestinationRecordRef.Field(DestinationOwnerTypeFieldNo);
            OwnerTypeFieldRef.Value := DestinationOwnerTypeValue;
            exit(true);
        end;

        exit(false);
    end;

    procedure UpdateContactOnModifyCustomer(RecRef: RecordRef)
    var
        Customer: Record Customer;
        CustContUpdate: Codeunit "CustCont-Update";
    begin
        if RecRef.Number() = DATABASE::Customer then begin
            RecRef.SetTable(Customer);
            CustContUpdate.OnModify(Customer);
        end;
    end;

    procedure UpdateContactOnModifyVendor(RecRef: RecordRef)
    var
        Vendor: Record Vendor;
        VendContUpdate: Codeunit "VendCont-Update";
    begin
        if RecRef.Number() = DATABASE::Vendor then begin
            RecRef.SetTable(Vendor);
            VendContUpdate.OnModify(Vendor);
        end;
    end;

    internal procedure FindOpportunityRelatedCustomer(SourceRecordRef: RecordRef; var ContactBusinessRelation: Record "Contact Business Relation"): Boolean
    var
        Opportunity: Record Opportunity;
        ContactCompanyNo: Code[20];
    begin
        ContactCompanyNo := SourceRecordRef.Field(Opportunity.FieldNo("Contact Company No.")).Value();
        exit(FindContactCompanyRelatedCustomer(ContactCompanyNo, ContactBusinessRelation));
    end;

    procedure FindContactRelatedCustomer(SourceRecordRef: RecordRef; var ContactBusinessRelation: Record "Contact Business Relation"): Boolean
    var
        Contact: Record Contact;
        ContactCompanyNo: Code[20];
    begin
        ContactCompanyNo := SourceRecordRef.Field(Contact.FieldNo("Company No.")).Value();
        exit(FindContactCompanyRelatedCustomer(ContactCompanyNo, ContactBusinessRelation));
    end;

    local procedure FindContactCompanyRelatedCustomer(ContactCompanyNo: Code[20]; var ContactBusinessRelation: Record "Contact Business Relation"): Boolean
    var
        Contact: Record Contact;
        MarketingSetup: Record "Marketing Setup";
    begin
        if not Contact.Get(ContactCompanyNo) then
            exit(false);

        MarketingSetup.Get();
        ContactBusinessRelation.SetFilter("Business Relation Code", MarketingSetup."Bus. Rel. Code for Customers");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetFilter("Contact No.", Contact."No.");
        exit(ContactBusinessRelation.FindFirst());
    end;

    procedure FindContactRelatedVendor(SourceRecordRef: RecordRef; var ContactBusinessRelation: Record "Contact Business Relation"): Boolean
    var
        Vendor: Record Contact;
        MarketingSetup: Record "Marketing Setup";
        CompanyNoFieldRef: FieldRef;
    begin
        // Tranfer the parent company id to the ParentCustomerId
        CompanyNoFieldRef := SourceRecordRef.Field(Vendor.FieldNo("Company No."));
        if not Vendor.Get(Format(CompanyNoFieldRef.Value())) then
            exit(false);

        MarketingSetup.Get();
        ContactBusinessRelation.SetFilter("Business Relation Code", MarketingSetup."Bus. Rel. Code for Vendors");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        ContactBusinessRelation.SetFilter("Contact No.", Vendor."No.");
        exit(ContactBusinessRelation.FindFirst());
    end;

    procedure UpdateSalesPersonCodeIfChanged(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; SourceOwnerIDFieldNo: Integer; SourceOwnerTypeFieldNo: Integer; AllowedOwnerTypeValue: Option; DestinationSalesPersonCodeFieldNo: Integer): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        IntegrationTableMapping: Record "Integration Table Mapping";
        OutlookSynchTypeConv: Codeunit "Outlook Synch. Type Conv";
        SalesPersonRecordID: RecordID;
        SourceFieldRef: FieldRef;
        DestinationFieldRef: FieldRef;
        CRMSystemUserID: Guid;
        CurrentOptionValue: Integer;
    begin
        if not IntegrationTableMapping.FindMapping(Database::"Salesperson/Purchaser", Database::"CRM Systemuser") then
            exit(false); // There are no mapping for salepeople to SystemUsers

        SourceFieldRef := SourceRecordRef.Field(SourceOwnerTypeFieldNo);
        CurrentOptionValue := OutlookSynchTypeConv.TextToOptionValue(Format(SourceFieldRef.Value()), SourceFieldRef.OptionMembers());
        // Allow 0 as it is the default value for CRM options.
        if (CurrentOptionValue <> 0) and (CurrentOptionValue <> AllowedOwnerTypeValue) then
            Error(CanOnlyUseSystemUserOwnerTypeErr, CRMProductName.CDSServiceName());

        SourceFieldRef := SourceRecordRef.Field(SourceOwnerIDFieldNo);
        CRMSystemUserID := SourceFieldRef.Value();

        if IsNullGuid(CRMSystemUserID) then
            exit(false);

        DestinationFieldRef := DestinationRecordRef.Field(DestinationSalesPersonCodeFieldNo);

        if not CRMIntegrationRecord.FindRecordIDFromID(CRMSystemUserID, Database::"Salesperson/Purchaser", SalesPersonRecordID) then begin
            if not SynchRecordIfMappingExists(Database::"Salesperson/Purchaser", Database::"CRM Systemuser", CRMSystemUserID) then
                exit(false);
            if not CRMIntegrationRecord.FindRecordIDFromID(CRMSystemUserID, Database::"Salesperson/Purchaser", SalesPersonRecordID) then
                exit(false);
        end;

        if not SalespersonPurchaser.Get(SalesPersonRecordID) then
            exit(false);

        exit(UpdateFieldRefValueIfChanged(DestinationFieldRef, SalespersonPurchaser.Code));
    end;

    procedure UpdateFieldRefValueIfChanged(var DestinationFieldRef: FieldRef; NewFieldValue: Text): Boolean
    begin
        // Compare and updates the fieldref value, if different
        if Format(DestinationFieldRef.Value()) = NewFieldValue then
            exit(false);

        // Return TRUE if the value was changed
        DestinationFieldRef.Value := NewFieldValue;
        exit(true);
    end;

    procedure GetValidCRMUnitOfMeasureRecords(var CRMUom: Record "CRM Uom"; var CRMUomschedule: Record "CRM Uomschedule"; UnitOfMeasureCode: Code[10])
    var
        CRMUnitGroupName: Text;
    begin
        // This function checks that the CRM Unit of Measure and its parent group exist in CRM, and that the user didn't change their properties from
        // the expected ones

        // Attempt to get the Uomschedule with the expected name = 'NAV ' + UnitOfMeasureCode
        CRMUnitGroupName := GetUnitGroupName(UnitOfMeasureCode);
        CRMUomschedule.SetRange(Name, CRMUnitGroupName);

        // CRM Unit Group - Not found
        if not FindCachedCRMUomschedule(CRMUomschedule) then
            Error(DynamicsCRMUomscheduleNotFoundErr, CRMUnitGroupName, CRMProductName.CDSServiceName());

        // CRM Unit Group  - Multiple found
        if CountCRMUomschedule(CRMUomschedule) > 1 then
            Error(DynamicsCRMUoMFoundMultipleInGroupErr, CRMUnitGroupName, CRMProductName.CDSServiceName());

        // CRM Unit Group - One found - check its child unit of measure, should be just one
        CRMUom.SetRange(UoMScheduleId, CRMUomschedule.UoMScheduleId);

        // CRM Unit of Measure - not found
        if not FindCachedCRMUom(CRMUom) then
            Error(DynamicsCRMUoMNotFoundInGroupErr, CRMUomschedule.Name, CRMProductName.CDSServiceName());

        // CRM Unit of Measure - multiple found
        if CountCRMUom(CRMUom) > 1 then
            Error(DynamicsCRMUoMFoundMultipleInGroupErr, CRMUomschedule.Name, CRMProductName.CDSServiceName());

        // CRM Unit of Measure - one found, does it have the correct name?
        if CRMUom.Name <> UnitOfMeasureCode then
            Error(IncorrectCRMUoMNameErr, CRMUomschedule.Name, UnitOfMeasureCode, CRMUom.Name);

        // CRM Unit of Measure should be the base
        if not CRMUom.IsScheduleBaseUoM then
            Error(IncorrectCRMUoMStatusErr, CRMUom.Name, CRMUomschedule.Name);

        // CRM Unit of Measure should have the conversion rate of 1
        if CRMUom.Quantity <> 1 then
            Error(IncorrectCRMUoMQuantityErr, CRMUom.Name);

        // All checks passed. We're good to go
    end;

    procedure GetNavCurrencyCode(TransactionCurrencyId: Guid): Code[10]
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Currency: Record Currency;
        NAVLCYCode: Code[10];
        CRMCurrencyCode: Code[10];
    begin
        if IsNullGuid(TransactionCurrencyId) then
            exit('');
        NAVLCYCode := GetNavLCYCode();
        CRMTransactioncurrency.SetRange(TransactionCurrencyId, TransactionCurrencyId);
        if not FindCachedCRMTransactionCurrency(CRMTransactioncurrency) then
            Error(DynamicsCRMTransactionCurrencyRecordNotFoundErr, TransactionCurrencyId);
        CRMCurrencyCode := DelChr(CRMTransactioncurrency.ISOCurrencyCode);
        if CRMCurrencyCode = NAVLCYCode then
            exit('');

        Currency.Get(CRMCurrencyCode);
        exit(Currency.Code);
    end;

    procedure GetCRMTransactioncurrency(CurrencyCode: Text): Guid
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        NAVLCYCode: Code[10];
    begin
        // In NAV, an empty currency means local currency (LCY)
        NAVLCYCode := GetNavLCYCode();
        if DelChr(CurrencyCode) = '' then
            CurrencyCode := NAVLCYCode;

        if CurrencyCode = NAVLCYCode then
            FindNAVLocalCurrencyInCRM(CRMTransactioncurrency)
        else begin
            CRMTransactioncurrency.SetRange(ISOCurrencyCode, CurrencyCode);
            if not FindCachedCRMTransactionCurrency(CRMTransactioncurrency) then
                Error(DynamicsCRMTransactionCurrencyRecordNotFoundErr, CurrencyCode);
        end;
        exit(CRMTransactioncurrency.TransactionCurrencyId)
    end;

    local procedure AddToCacheCRMPriceLevel(CRMPricelevel: Record "CRM Pricelevel")
    begin
        if TempCRMPricelevel.Get(CRMPricelevel.PriceLevelId) then begin
            TempCRMPricelevel := CRMPricelevel;
            TempCRMPricelevel.Modify();
        end else begin
            TempCRMPricelevel := CRMPricelevel;
            TempCRMPricelevel.Insert();
        end;
    end;

    local procedure CacheCRMPriceLevel(): Boolean
    var
        CRMPricelevel: Record "CRM Pricelevel";
    begin
        TempCRMPricelevel.Reset();
        if TempCRMPricelevel.IsEmpty() then
            if CRMPricelevel.FindSet() then
                repeat
                    AddToCacheCRMPriceLevel(CRMPricelevel)
                until CRMPricelevel.Next() = 0;
        exit(not TempCRMPricelevel.IsEmpty());
    end;

    local procedure FindCachedCRMPriceLevel(var CRMPricelevel: Record "CRM Pricelevel"): Boolean
    begin
        if not CacheCRMPriceLevel() then
            exit(false);
        TempCRMPricelevel.Copy(CRMPricelevel);
        if TempCRMPricelevel.FindFirst() then begin
            CRMPricelevel.Copy(TempCRMPricelevel);
            exit(true);
        end;
    end;

    local procedure AddToCacheCRMTransactionCurrency(CRMTransactioncurrency: Record "CRM Transactioncurrency")
    begin
        TempCRMTransactioncurrency := CRMTransactioncurrency;
        TempCRMTransactioncurrency.Insert();
    end;

    local procedure CacheCRMTransactionCurrency(): Boolean
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        TempCRMTransactioncurrency.Reset();
        if TempCRMTransactioncurrency.IsEmpty() then
            if CRMTransactioncurrency.FindSet() then
                repeat
                    AddToCacheCRMTransactionCurrency(CRMTransactioncurrency)
                until CRMTransactioncurrency.Next() = 0;
        exit(not TempCRMTransactioncurrency.IsEmpty());
    end;

    local procedure FindCachedCRMTransactionCurrency(var CRMTransactioncurrency: Record "CRM Transactioncurrency"): Boolean
    begin
        if not CacheCRMTransactionCurrency() then
            exit(false);
        TempCRMTransactioncurrency.Copy(CRMTransactioncurrency);
        if TempCRMTransactioncurrency.FindFirst() then begin
            CRMTransactioncurrency.Copy(TempCRMTransactioncurrency);
            exit(true);
        end;
    end;

    local procedure AddToCacheCRMUom(CRMUom: Record "CRM Uom")
    begin
        TempCRMUom := CRMUom;
        TempCRMUom.Insert();
    end;

    local procedure CacheCRMUom(): Boolean
    var
        CRMUom: Record "CRM Uom";
    begin
        TempCRMUom.Reset();
        if TempCRMUom.IsEmpty() then
            if CRMUom.FindSet() then
                repeat
                    AddToCacheCRMUom(CRMUom)
                until CRMUom.Next() = 0;
        exit(not TempCRMUom.IsEmpty());
    end;

    local procedure CountCRMUom(var CRMUom: Record "CRM Uom"): Integer
    begin
        TempCRMUom.Copy(CRMUom);
        exit(TempCRMUom.Count());
    end;

    local procedure FindCachedCRMUom(var CRMUom: Record "CRM Uom"): Boolean
    begin
        if not CacheCRMUom() then
            exit(false);
        TempCRMUom.Copy(CRMUom);
        if TempCRMUom.FindFirst() then begin
            CRMUom.Copy(TempCRMUom);
            exit(true);
        end;
    end;

    local procedure AddToCacheCRMUomschedule(CRMUomschedule: Record "CRM Uomschedule")
    begin
        TempCRMUomschedule := CRMUomschedule;
        TempCRMUomschedule.Insert();
    end;

    local procedure CacheCRMUomschedule(): Boolean
    var
        CRMUomschedule: Record "CRM Uomschedule";
    begin
        TempCRMUomschedule.Reset();
        if TempCRMUomschedule.IsEmpty() then
            if CRMUomschedule.FindSet() then
                repeat
                    AddToCacheCRMUomschedule(CRMUomschedule)
                until CRMUomschedule.Next() = 0;
        exit(not TempCRMUomschedule.IsEmpty());
    end;

    local procedure CountCRMUomschedule(var CRMUomschedule: Record "CRM Uomschedule"): Integer
    begin
        TempCRMUomschedule.Copy(CRMUomschedule);
        exit(TempCRMUomschedule.Count());
    end;

    local procedure FindCachedCRMUomschedule(var CRMUomschedule: Record "CRM Uomschedule"): Boolean
    begin
        if not CacheCRMUomschedule() then
            exit(false);
        TempCRMUomschedule.Copy(CRMUomschedule);
        if TempCRMUomschedule.FindFirst() then begin
            CRMUomschedule.Copy(TempCRMUomschedule);
            exit(true);
        end;
    end;

    procedure ShowPage(RecordID: RecordID)
    var
        TableMetadata: Record "Table Metadata";
        PageManagement: Codeunit "Page Management";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CrmId: Guid;
        CrmIdText: Text;
    begin
        if RecordID.TableNo() = 0 then
            exit;
        if not TableMetadata.Get(RecordID.TableNo()) then
            exit;

        if not TableMetadata.DataIsExternal then begin
            PageManagement.PageRun(RecordID);
            exit;
        end;

        if TableMetadata.TableType = TableMetadata.TableType::CRM then begin
            CrmIdText := Format(RecordID);
            CrmIdText := CopyStr(CrmIdText, StrPos(CrmIdText, ':') + 1);
            Evaluate(CrmId, CrmIdText);
            HyperLink(CRMIntegrationManagement.GetCRMEntityUrlFromCRMID(RecordID.TableNo(), CrmId));
            exit;
        end;

        Error(UnableToFindPageForRecordErr, Format(RecordID, 0, 1));
    end;

    procedure FindNewValueForSpecialMapping(SourceFieldRef: FieldRef; var NewValue: Variant) IsValueFound: Boolean
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMID: Guid;
    begin
        case SourceFieldRef.Relation() of
            DATABASE::Currency: // special handling of Local currency
                if Format(SourceFieldRef.Value()) = '' then begin
                    FindNAVLocalCurrencyInCRM(CRMTransactioncurrency);
                    NewValue := CRMTransactioncurrency.TransactionCurrencyId;
                    IsValueFound := true;
                end;
            DATABASE::"CRM Transactioncurrency": // special handling of Local currency
                begin
                    CRMID := SourceFieldRef.Value();
                    if GetNavCurrencyCode(CRMID) = '' then begin
                        NewValue := '';
                        IsValueFound := true;
                    end;
                end;
        end;
    end;

    procedure FindPKByRecordID(RecID: RecordID; var PrimaryKey: Variant) Found: Boolean
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        KeyRef: KeyRef;
    begin
        if RecID.TableNo() = 0 then
            exit;
        Found := RecordRef.Get(RecID);
        KeyRef := RecordRef.KeyIndex(1);
        FieldRef := KeyRef.FieldIndex(1);
        PrimaryKey := FieldRef.Value();
    end;

    procedure FindRecordIDByPK(TableID: Integer; PrimaryKey: Variant; var RecID: RecordID) Found: Boolean
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        KeyRef: KeyRef;
    begin
        RecordRef.Open(TableID);
        KeyRef := RecordRef.KeyIndex(1);
        FieldRef := KeyRef.FieldIndex(1);
        FieldRef.SetRange(PrimaryKey);
        Found := RecordRef.FindFirst();
        RecID := RecordRef.RecordId();
        RecordRef.Close();
    end;

    procedure FindSourceIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef): Boolean
    var
        SourceRecRef: RecordRef;
        DestinationRecRef: RecordRef;
    begin
        SourceRecRef := SourceFieldRef.Record();
        DestinationRecRef := DestinationFieldRef.Record();
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Table ID", SourceRecRef.Number());
        IntegrationTableMapping.SetRange("Integration Table ID", DestinationRecRef.Number());
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        exit(IntegrationTableMapping.FindFirst());
    end;

    procedure IsClearValueOnFailedSync(SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        if FindSourceIntegrationTableMapping(IntegrationTableMapping, SourceFieldRef, DestinationFieldRef) then begin
            IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
            IntegrationFieldMapping.SetRange("Field No.", SourceFieldRef.Number());
            IntegrationFieldMapping.SetRange("Integration Table Field No.", DestinationFieldRef.Number());
            IntegrationFieldMapping.FindFirst();
            exit(IntegrationFieldMapping."Clear Value on Failed Sync");
        end;
        exit(false);
    end;

    procedure AreFieldsRelatedToMappedTables(SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    var
        SourceTableID: Integer;
        DestinationTableID: Integer;
        Direction: Integer;
        SourceTableName: Text;
        DestinationTableName: Text;
    begin
        SourceTableID := GetFieldRelation(SourceFieldRef, SourceTableName);
        DestinationTableID := GetFieldRelation(DestinationFieldRef, DestinationTableName);
        if (SourceTableID <> 0) and (DestinationTableID <> 0) then begin
            if DestinationFieldRef.Type() = FieldType::GUID then begin
                IntegrationTableMapping.SetRange("Table ID", SourceTableID);
                IntegrationTableMapping.SetRange("Integration Table ID", DestinationTableID);
                Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
            end else begin
                IntegrationTableMapping.SetRange("Table ID", DestinationTableID);
                IntegrationTableMapping.SetRange("Integration Table ID", SourceTableID);
                Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
            end;
            IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
            IntegrationTableMapping.SetRange("Delete After Synchronization", false);
            if IntegrationTableMapping.FindFirst() then begin
                IntegrationTableMapping.Direction := Direction;
                exit(true);
            end;
            Error(
                MappingMustBeSetForGUIDFieldErr,
                SourceTableName, DestinationTableName, SourceFieldRef.Name(), DestinationFieldRef.Name());
        end;
    end;

    procedure GetCoupledCDSUserId(SourceRecordRef: RecordRef): Guid
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        SalesHeader: Record "Sales Header";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalesPersonPurchaser: Record "Salesperson/Purchaser";
        SalesPersonPurchaserFieldRef: FieldRef;
        SalesPersonPurchaserCode: Code[20];
        CDSUserId: Guid;
    begin
        case SourceRecordRef.Number() of
            Database::Customer:
                SalesPersonPurchaserFieldRef := SourceRecordRef.Field(Customer.FieldNo(Customer."Salesperson Code"));
            Database::Vendor:
                SalesPersonPurchaserFieldRef := SourceRecordRef.Field(Vendor.FieldNo(Vendor."Purchaser Code"));
            Database::Contact:
                SalesPersonPurchaserFieldRef := SourceRecordRef.Field(Contact.FieldNo(Contact."Salesperson Code"));
            Database::"Sales Header":
                SalesPersonPurchaserFieldRef := SourceRecordRef.Field(SalesHeader.FieldNo(SalesHeader."Salesperson Code"));
            else
                exit(CDSUserId);
        end;

        Evaluate(SalesPersonPurchaserCode, Format(SalesPersonPurchaserFieldRef.Value()));
        if not SalesPersonPurchaser.Get(SalesPersonPurchaserCode) then
            exit(CDSUserId);

        if not CRMIntegrationRecord.FindIDFromRecordID(SalesPersonPurchaser.RecordId(), CDSUserId) then
            Error(
              RecordMustBeCoupledExtErr, SalesPersonPurchaser.TableCaption(), SalesPersonPurchaserFieldRef.Value(),
              IntegrationTableMapping.GetExtendedIntegrationTableCaption());

        exit(CDSUserId);
    end;

    procedure ConvertBaseUnitOfMeasureToUomId(SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var NewValue: Variant)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Item: Record Item;
        Resource: Record Resource;
        PriceListLine: Record "Price List Line";
        SourceRecordCode: Code[20];
    begin
        if Format(SourceFieldRef.Value()) = '' then
            Error(BaseUnitOfMeasureCannotBeEmptyErr, SourceFieldRef.Record().RecordId)
        else begin
            case SourceFieldRef.Record().Number() of
                Database::Item:
                    begin
                        SourceFieldRef.Record().SetTable(Item);
                        SourceRecordCode := Item."No.";
                        if ItemUnitOfMeasure.Get(SourceRecordCode, Format(SourceFieldRef.Value())) then
                            if CRMIntegrationRecord.FindIDFromRecordID(ItemUnitOfMeasure.RecordId, NewValue) then
                                exit
                            else begin
                                CoupleAndSyncItemUoM(DestinationFieldRef, ItemUnitOfMeasure);
                                if CRMIntegrationRecord.FindIDFromRecordID(ItemUnitOfMeasure.RecordId, NewValue) then
                                    exit;
                            end;
                    end;
                Database::Resource:
                    begin
                        SourceFieldRef.Record().SetTable(Resource);
                        SourceRecordCode := Resource."No.";
                        if ResourceUnitOfMeasure.Get(SourceRecordCode, Format(SourceFieldRef.Value())) then
                            if CRMIntegrationRecord.FindIDFromRecordID(ResourceUnitOfMeasure.RecordId, NewValue) then
                                exit
                            else begin
                                CoupleAndSyncResourceUoM(DestinationFieldRef, ResourceUnitOfMeasure);
                                if CRMIntegrationRecord.FindIDFromRecordID(ResourceUnitOfMeasure.RecordId, NewValue) then
                                    exit;
                            end;
                    end;
                Database::"Price List Line":
                    begin
                        SourceFieldRef.Record().SetTable(PriceListLine);
                        case PriceListLine."Asset Type" of
                            PriceListLine."Asset Type"::Item:
                                if ItemUnitOfMeasure.Get(PriceListLine."Asset No.", Format(SourceFieldRef.Value())) then
                                    if CRMIntegrationRecord.FindIDFromRecordID(ItemUnitOfMeasure.RecordId, NewValue) then
                                        exit;
                            PriceListLine."Asset Type"::Resource:
                                if ResourceUnitOfMeasure.Get(PriceListLine."Asset No.", Format(SourceFieldRef.Value())) then
                                    if CRMIntegrationRecord.FindIDFromRecordID(ResourceUnitOfMeasure.RecordId, NewValue) then
                                        exit;
                        end;
                    end;
            end;

            Error(UnitOfMeasureMustBeCoupledErr, SourceFieldRef.Record().Name, SourceRecordCode, SourceFieldRef.Value(), CRMProductName.Short());
        end;
    end;

    local procedure CoupleAndSyncItemUoM(DestinationFieldRef: FieldRef; ItemUnitOfMeasure: Record "Item Unit of Measure")
    var
        CRMProduct: Record "CRM Product";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        UnitOfMeasureRecRef: RecordRef;
    begin
        DestinationFieldRef.Record().SetTable(CRMProduct);
        if IsNullGuid(CRMProduct.ProductId) then begin // CRM product is not created
            IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
            IntegrationTableMapping.SetRange("Table ID", Database::"Unit Group");
            IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Uomschedule");
            if IntegrationTableMapping.FindFirst() then
                if not IntegrationTableMapping."Synch. Only Coupled Records" then begin
                    IntegrationTableMapping.SetRange("Table ID", Database::"Item Unit of Measure");
                    IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Uom");
                    if IntegrationTableMapping.FindFirst() then
                        if not IntegrationTableMapping."Synch. Only Coupled Records" then begin
                            ItemUnitOfMeasure.SetRange(SystemId, ItemUnitOfMeasure.SystemId);
                            UnitOfMeasureRecRef.GetTable(ItemUnitOfMeasure);
                            CRMIntegrationTableSynch.SynchRecordsToIntegrationTable(UnitOfMeasureRecRef, false, true);
                        end;
                end;
        end;
    end;

    local procedure CoupleAndSyncResourceUoM(DestinationFieldRef: FieldRef; ResourceUnitOfMeasure: Record "Resource Unit of Measure")
    var
        CRMProduct: Record "CRM Product";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        UnitOfMeasureRecRef: RecordRef;
    begin
        DestinationFieldRef.Record().SetTable(CRMProduct);
        if IsNullGuid(CRMProduct.ProductId) then begin // CRM product is not created
            IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
            IntegrationTableMapping.SetRange("Table ID", Database::"Unit Group");
            IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Uomschedule");
            if IntegrationTableMapping.FindFirst() then
                if not IntegrationTableMapping."Synch. Only Coupled Records" then begin
                    IntegrationTableMapping.SetRange("Table ID", Database::"Resource Unit of Measure");
                    IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Uom");
                    if IntegrationTableMapping.FindFirst() then
                        if not IntegrationTableMapping."Synch. Only Coupled Records" then begin
                            ResourceUnitOfMeasure.SetRange(SystemId, ResourceUnitOfMeasure.SystemId);
                            UnitOfMeasureRecRef.GetTable(ResourceUnitOfMeasure);
                            CRMIntegrationTableSynch.SynchRecordsToIntegrationTable(UnitOfMeasureRecRef, false, true);
                        end;
                end;
        end;
    end;

    procedure ConvertUomIdToBaseUnitOfMeasure(SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var NewValue: Variant)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
        UnitOfMeasure: Record "Unit of Measure";
        CRMUom: Record "CRM Uom";
        RecId: RecordId;
        DefaultUoMCode: Code[10];
        CRMId: Guid;
    begin
        CRMID := SourceFieldRef.Value();
        if IsNullGuid(CRMId) then begin
            NewValue := '';
            exit;
        end else begin
            case DestinationFieldRef.Record().Number() of
                Database::Item:
                    if CRMIntegrationRecord.FindRecordIDFromID(CRMId, Database::"Item Unit of Measure", RecId) then begin
                        ItemUnitOfMeasure.Get(RecId);
                        NewValue := ItemUnitOfMeasure.Code;
                        exit;
                    end else begin
                        DestinationFieldRef.Record().SetTable(Item);
                        if IsNullGuid(Item.SystemId) then begin // Item is not created
                            IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
                            IntegrationTableMapping.SetRange("Table ID", Database::"Unit Group");
                            IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Uomschedule");
                            if IntegrationTableMapping.FindFirst() then
                                if not IntegrationTableMapping."Synch. Only Coupled Records" then begin
                                    IntegrationTableMapping.SetRange("Table ID", Database::"Item Unit of Measure");
                                    IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Uom");
                                    if IntegrationTableMapping.FindFirst() then
                                        if not IntegrationTableMapping."Synch. Only Coupled Records" then begin
                                            CRMProduct.SetRange(DefaultUoMScheduleId, SourceFieldRef.Record().Field(CRMProduct.FieldNo(DefaultUoMScheduleId)).Value);
                                            if CRMProduct.Count > 1 then
                                                Error(CannotUseSameUnitGroupErr, SourceFieldRef.Value);

                                            CRMUom.Get(CRMID);
                                            Evaluate(DefaultUoMCode, CRMUom.Name);
                                            if not UnitOfMeasure.Get(DefaultUoMCode) then
                                                Error(UnitOfMeasureDoesNotExistErr, CRMProduct.DefaultUoMIdName);
                                            NewValue := UnitOfMeasure.Code;
                                            exit;
                                        end;
                                end;
                        end;
                    end;
                Database::Resource:
                    if CRMIntegrationRecord.FindRecordIDFromID(CRMId, Database::"Resource Unit of Measure", RecId) then begin
                        ResourceUnitOfMeasure.Get(RecId);
                        NewValue := ResourceUnitOfMeasure.Code;
                        exit;
                    end else begin
                        DestinationFieldRef.Record().SetTable(Resource);
                        if IsNullGuid(Resource.SystemId) then begin // Resource is not created
                            IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
                            IntegrationTableMapping.SetRange("Table ID", Database::"Unit Group");
                            IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Uomschedule");
                            if IntegrationTableMapping.FindFirst() then
                                if not IntegrationTableMapping."Synch. Only Coupled Records" then begin
                                    IntegrationTableMapping.SetRange("Table ID", Database::"Resource Unit of Measure");
                                    IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Uom");
                                    if IntegrationTableMapping.FindFirst() then
                                        if not IntegrationTableMapping."Synch. Only Coupled Records" then begin
                                            CRMProduct.SetRange(DefaultUoMScheduleId, SourceFieldRef.Record().Field(CRMProduct.FieldNo(DefaultUoMScheduleId)).Value);
                                            if CRMProduct.Count > 1 then
                                                Error(CannotUseSameUnitGroupErr, SourceFieldRef.Value);

                                            CRMUom.Get(CRMID);
                                            Evaluate(DefaultUoMCode, CRMUom.Name);
                                            if not UnitOfMeasure.Get(DefaultUoMCode) then
                                                Error(UnitOfMeasureDoesNotExistErr, CRMProduct.DefaultUoMIdName);
                                            NewValue := UnitOfMeasure.Code;
                                            exit;
                                        end;
                                end;
                        end;
                    end;
            end;

            Error(RecordMustBeCoupledErr, SourceFieldRef.Caption(), CRMID, CRMProductName.Short());
        end;
    end;

    procedure PrefixUnitGroupCode(SourceFieldRef: FieldRef; var NewValue: Variant)
    var
        UnitGroup: Record "Unit Group";
    begin
        SourceFieldRef.Record().SetTable(UnitGroup);
        NewValue := UnitGroup.GetCode();
    end;

    local procedure GetFieldRelation(FldRef: FieldRef; var TableName: Text) TableID: Integer
    var
        PriceListLine: Record "Price List Line";
        RecRef: RecordRef;
    begin
        TableID := FldRef.Relation();
        if TableID = 0 then begin
            RecRef := FldRef.Record();
            case RecRef.Number of
                Database::"Price List Line":
                    begin
                        RecRef.SetTable(PriceListLine);
                        TableID := GetFieldRelation(PriceListLine, FldRef.Number);
                        RecRef.Close();
                    end;
            end;
            OnAfterGetFieldRelation(RecRef, FldRef, TableID);
            RecRef.Close();
        end;
        if TableID <> 0 then begin
            RecRef.Open(TableID);
            TableName := RecRef.Name;
            RecRef.Close();
        end;
    end;

    local procedure GetFieldRelation(PriceListLine: Record "Price List Line"; FieldId: Integer) TableID: Integer;
    var
        PriceAsset: Record "Price Asset";
    begin
        case FieldId of
            PriceListLine.FieldNo("Asset No."):
                if PriceListLine."Asset No." <> '' then begin
                    PriceAsset.Validate("Asset Type", PriceListLine."Asset Type");
                    PriceAsset.Validate("Asset No.", PriceListLine."Asset No.");
                    TableID := PriceAsset."Table Id";
                end;
            PriceListLine.FieldNo("Unit of Measure Code"):
                TableID := Database::"Unit of Measure";
        end;
    end;

    procedure ConvertTableToOption(SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var OptionValue: Integer) TableIsMapped: Boolean
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        RecID: RecordID;
    begin
        TableIsMapped := false;
        OptionValue := 0;
        if IsTableMappedToCRMOption(SourceFieldRef, DestinationFieldRef) then begin
            TableIsMapped := true;
            if FindRecordIDByPK(SourceFieldRef.Relation(), SourceFieldRef.Value(), RecID) then begin
                CRMOptionMapping.SetRange("Record ID", RecID);
                if CRMOptionMapping.FindFirst() then
                    OptionValue := CRMOptionMapping."Option Value"
                else
                    Error(RecordMustBeCoupledErr, SourceFieldRef.Caption(), SourceFieldRef.Value(), CRMProductName.CDSServiceName());
            end;
        end;
        exit(TableIsMapped);
    end;

    procedure ConvertOptionToTable(SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var TableValue: Text) TableIsMapped: Boolean
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        CRMAccount: Record "CRM Account";
        CRMSalesorder: Record "CRM Salesorder";
        PrimaryKey: Variant;
        IsHandled: Boolean;
    begin
        TableIsMapped := false;
        if IsTableMappedToCRMOption(DestinationFieldRef, SourceFieldRef) then begin
            TableIsMapped := true;

            if Format(SourceFieldRef.Value()) = ' ' then
                exit;

            CRMOptionMapping.SetRange("Option Value Caption", SourceFieldRef.Value());
            CRMOptionMapping.SetRange("Table ID", DestinationFieldRef.Relation());

            IsHandled := false;
            OnConvertOptionToTableOnBeforeSetRangeForIntegrationFieldID(CRMOptionMapping, SourceFieldRef, IsHandled);
            if not IsHandled then
                if SourceFieldRef.Record().Number = Database::"CRM Salesorder" then
                    case SourceFieldRef.Number of
                        CRMsalesorder.FieldNo(PaymentTermsCodeEnum):
                            CRMOptionMapping.SetRange("Integration Field ID", CRMAccount.FieldNo(PaymentTermsCodeEnum));
                        CRMsalesorder.FieldNo(ShippingMethodCodeEnum):
                            CRMOptionMapping.SetRange("Integration Field ID", CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum));
                        CRMsalesorder.FieldNo(FreightTermsCodeEnum):
                            CRMOptionMapping.SetRange("Integration Field ID", CRMAccount.FieldNo(Address1_FreightTermsCodeEnum));
                    end
                else
                    CRMOptionMapping.SetRange("Integration Field ID", SourceFieldRef.Number());

            if CRMOptionMapping.FindFirst() then begin
                FindPKByRecordID(CRMOptionMapping."Record ID", PrimaryKey);
                Evaluate(TableValue, PrimaryKey);
            end else begin
                CRMOptionMapping.SetRange("Option Value Caption");
                CRMOptionMapping.SetRange("Option Value", SourceFieldRef.Value());
                if CRMOptionMapping.FindFirst() then begin
                    FindPKByRecordID(CRMOptionMapping."Record ID", PrimaryKey);
                    Evaluate(TableValue, PrimaryKey);
                end else
                    Error(RecordMustBeCoupledErr, SourceFieldRef.Caption(), SourceFieldRef.Value(), CRMProductName.CDSServiceName());
            end;
        end;
        exit(TableIsMapped);
    end;

    procedure UpdateCDSOptionMapping(OldRecId: RecordId; NewRecId: RecordId)
    var
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        CRMOptionMapping.SetRange("Record ID", OldRecId);
        if CRMOptionMapping.FindFirst() then
            CRMOptionMapping.Rename(NewRecId);
    end;

    internal procedure FindNewValueForSpecialMapping(SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var NewValue: Variant) IsValueFound: Boolean
    var
        TempOpportunity: Record Opportunity temporary;
        TempCRMOpportunity: Record "CRM Opportunity" temporary;
    begin
        if SourceFieldRef.Number() = TempOpportunity.FieldNo("Contact Company No.") then
            if DestinationFieldRef.Number() = TempCRMOpportunity.FieldNo(ParentAccountId) then
                if SourceFieldRef.Record().Number() = Database::Opportunity then
                    if DestinationFieldRef.Record().Number() = Database::"CRM Opportunity" then begin
                        NewValue := FindParentCRMAccountForOpportunity(SourceFieldRef.Record());
                        IsValueFound := true;
                        exit;
                    end;
    end;

    local procedure FindParentCRMAccountForOpportunity(SourceRecordRef: RecordRef) AccountId: Guid
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        Customer: Record Customer;
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if not FindOpportunityRelatedCustomer(SourceRecordRef, ContactBusinessRelation) then
            exit;

        if not Customer.Get(ContactBusinessRelation."No.") then
            Error(RecordNotFoundErr, Customer.TableCaption(), ContactBusinessRelation."No.");

        CRMIntegrationRecord.FindIDFromRecordID(Customer.RecordId(), AccountId);
    end;

    local procedure IsTableMappedToCRMOption(NAVFieldRef: FieldRef; CRMFieldRef: FieldRef): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if CRMFieldRef.Type() = CRMFieldRef.Type::Option then begin
            IntegrationTableMapping.SetRange("Table ID", NAVFieldRef.Relation());
            IntegrationTableMapping.SetRange("Delete After Synchronization", false);
            exit(not IntegrationTableMapping.IsEmpty());
        end;
        exit(false);
    end;

    internal procedure IsContactBusinessRelationOptional(): Boolean
    var
        Optional: Boolean;
    begin
        OnGetIsContactBusinessRelationOptional(Optional);
        if Optional then
            Session.LogMessage('0000F1J', ContactBusinessRelationOptionalTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        exit(Optional);
    end;

    internal procedure IsContactTypeCheckIgnored(): Boolean
    var
        Ignored: Boolean;
    begin
        OnGetIsContactTypeCheckIgnored(Ignored);
        if Ignored then
            Session.LogMessage('0000F2F', ContactTypeCheckIgnoredTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        exit(Ignored);
    end;

    procedure TransformValue(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef; TransformationRule: Record "Transformation Rule"; SourceFieldNo: Integer; DestinationFieldNo: Integer)
    var
        SourceFieldRef: FieldRef;
        DestinationFieldRef: FieldRef;
        TransformedValue: Text;
    begin
        SourceFieldRef := SourceRecordRef.Field(SourceFieldNo);
        DestinationFieldRef := DestinationRecordRef.Field(DestinationFieldNo);
        TransformedValue := TransformationRule.TransformText(SourceFieldRef.Value());

        case DestinationFieldRef.Type() of
            FieldType::Date, FieldType::DateTime:
                SetDateField(TransformedValue, SourceFieldRef, DestinationFieldRef);
            else
                SourceFieldRef.Value := TransformedValue;
        end;
    end;

    local procedure SetDateField(ValueText: Text; var SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef)
    var
        TypeHelper: Codeunit "Type Helper";
        Value: Variant;
    begin
        Value := DestinationFieldRef.Value();

        if not TypeHelper.Evaluate(Value, ValueText, '', '')
        then
            Error(IncorrectFormatOrTypeErr);

        SourceFieldRef.Value := Value;
    end;

    internal procedure FulfillSalesOrder(SalesOrderId: Guid)
    var
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CrmHelper: Dotnet CrmHelper;
    begin
        OnBeforeFulfillSalesOrder(SalesOrderId);
        if IsNullGuid(SalesOrderId) then
            exit;

        if CDSIntegrationImpl.InitializeConnection(CrmHelper) then
            CrmHelper.FulfillSalesOrder(SalesOrderId);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetFieldRelation(RecRef: RecordRef; FldRef: FieldRef; var TableID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCDSBaseCurrencyId(var BaseCurrencyId: Guid; var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnGetCDSOwnershipModel(var OwnershipModel: Option; var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCDSBaseCurrencySymbol(var BaseCurrencySymbol: Text[5]; var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCDSBaseCurrencyPrecision(var BaseCurrencyPrecision: Integer; var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCDSCurrencyDecimalPrecision(var CurrencyDecimalPrecision: Integer; var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetVendorSyncEnabled(var Enabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetIsContactBusinessRelationOptional(var Optional: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetIsContactTypeCheckIgnored(var Ignored: Boolean)
    begin
    end;

#pragma warning disable AS0077
    [IntegrationEvent(false, false)]
    local procedure OnFindAndSynchRecordIDFromIntegrationSystemId(IntegrationSystemId: Guid; TableId: Integer; var LocalRecordID: RecordID; var IsHandled: Boolean)
    begin
    end;
#pragma warning restore AS0077

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCRMInvoiceStatusFromEntryOnBeforeModify(var CRMInvoice: Record "CRM Invoice"; var NewCRMInvoice: Record "CRM Invoice"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCRMInvoiceStatusFromEntryOnBeforeCheckFieldsChanged(var CRMInvoice: Record "CRM Invoice"; var NewCRMInvoice: Record "CRM Invoice"; CustLedgerEntry: Record "Cust. Ledger Entry"; var ChangeNeeded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateActualStatusCode(CustLedgerEntry: Record "Cust. Ledger Entry"; var CRMInvoice: Record "CRM Invoice"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnConvertOptionToTableOnBeforeSetRangeForIntegrationFieldID(var CRMOptionMapping: Record "CRM Option Mapping"; SourceFieldRef: FieldRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCancelCRMInvoiceOnBeforeModifyCRMInvoice(var CRMInvoice: Record "CRM Invoice"; var NewCRMInvoice: Record "CRM Invoice")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCancelCRMInvoiceOnBeforeCheckFieldsChanged(var CRMInvoice: Record "CRM Invoice"; var NewCRMInvoice: Record "CRM Invoice"; var ChangeNeeded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFulfillSalesOrder(var SalesOrderId: Guid)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFailedFindContactByAccountId(DestinationContactRecordRef: RecordRef; var CompanyContact: Record Contact; AccountID: Guid; var OutOfMapFilter: Boolean; var Result: Boolean)
    begin
    end;
}
