// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument;
using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using System.Utilities;

codeunit 3363 "EDoc CFDI Validation MX"
{
    procedure CheckSalesDocument(SourceDocumentHeader: RecordRef)
    var
        CFDIRelation: Code[10];
        DocumentNo: Code[20];
        ForeignTrade: Boolean;
        SourceCode: Code[10];
        SourceDocumentTableId: Integer;
        SourceDocumentType: Integer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustomerNo: Code[20];
        PaymentTermsCode: Code[10];
        PaymentMethodCode: Code[10];
    begin
        Clear(TempErrorMessage);
        CheckSATCatalogs();

        case SourceDocumentHeader.Number of
            Database::"Sales Header":
                begin
                    SourceDocumentHeader.SetTable(SalesHeader);
                    if not (SalesHeader."Document Type" in [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::"Return Order", SalesHeader."Document Type"::"Credit Memo"]) then
                        Error(SourceDocumentNotSupportedErr, SourceDocumentHeader.Caption());

                    SourceDocumentTableId := Database::"Sales Header";
                    SourceDocumentType := SalesHeader."Document Type".AsInteger();
                    TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("No."), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("Document Date"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("Payment Method Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("Payment Terms Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("Bill-to Customer No."), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("Bill-to Address"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("Bill-to Post Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("CFDI Purpose"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("CFDI Export Code"), TempErrorMessage."Message Type"::Error);
                    CheckCFDIPurposeAndRelation(SalesHeader, 0, SalesHeader."CFDI Purpose", SalesHeader."CFDI Relation");
                    ForeignTrade := SalesHeader."Foreign Trade";
                    if ForeignTrade then begin
                        TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("SAT Address ID"), TempErrorMessage."Message Type"::Error);
                        TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("SAT International Trade Term"), TempErrorMessage."Message Type"::Error);
                        TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("Exchange Rate USD"), TempErrorMessage."Message Type"::Error);
                    end;
                    if SalesHeader."Currency Code" <> '' then
                        TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("Currency Factor"), TempErrorMessage."Message Type"::Error);
                    DocumentNo := SalesHeader."No.";
                    CustomerNo := SalesHeader."Bill-to Customer No.";
                    PaymentTermsCode := SalesHeader."Payment Terms Code";
                    PaymentMethodCode := SalesHeader."Payment Method Code";
                    CFDIRelation := SalesHeader."CFDI Relation";
                    CheckCFDIRelations(Database::"Sales Header", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", CFDIRelation);
                end;
            Database::"Sales Invoice Header":
                begin
                    SourceDocumentHeader.SetTable(SalesInvoiceHeader);
                    SourceDocumentTableId := Database::"Sales Invoice Header";
                    SourceDocumentType := 0;
                    TempErrorMessage.LogIfEmpty(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("No."), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Document Date"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Payment Method Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Payment Terms Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Bill-to Customer No."), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Bill-to Address"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Bill-to Post Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("CFDI Purpose"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("CFDI Export Code"), TempErrorMessage."Message Type"::Error);
                    CheckCFDIPurposeAndRelation(SalesInvoiceHeader, 0, SalesInvoiceHeader."CFDI Purpose", SalesInvoiceHeader."CFDI Relation");
                    SourceCode := SalesInvoiceHeader."Source Code";
                    ForeignTrade := SalesInvoiceHeader."Foreign Trade";
                    if ForeignTrade then begin
                        TempErrorMessage.LogIfEmpty(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("SAT Address ID"), TempErrorMessage."Message Type"::Error);
                        TempErrorMessage.LogIfEmpty(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("SAT International Trade Term"), TempErrorMessage."Message Type"::Error);
                        TempErrorMessage.LogIfEmpty(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Exchange Rate USD"), TempErrorMessage."Message Type"::Error);
                    end;
                    if SalesInvoiceHeader."Currency Code" <> '' then
                        TempErrorMessage.LogIfEmpty(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Currency Factor"), TempErrorMessage."Message Type"::Error);
                    DocumentNo := SalesInvoiceHeader."No.";
                    CustomerNo := SalesInvoiceHeader."Bill-to Customer No.";
                    PaymentTermsCode := SalesInvoiceHeader."Payment Terms Code";
                    PaymentMethodCode := SalesInvoiceHeader."Payment Method Code";
                    CFDIRelation := SalesInvoiceHeader."CFDI Relation";
                    CheckCFDIRelations(Database::"Sales Invoice Header", 0, SalesInvoiceHeader."No.", CFDIRelation);
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    SourceDocumentHeader.SetTable(SalesCrMemoHeader);
                    SourceDocumentTableId := Database::"Sales Cr.Memo Header";
                    SourceDocumentType := 0;
                    TempErrorMessage.LogIfEmpty(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("No."), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Document Date"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Payment Method Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Payment Terms Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Bill-to Customer No."), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Bill-to Address"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Bill-to Post Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("CFDI Purpose"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("CFDI Export Code"), TempErrorMessage."Message Type"::Error);
                    CheckCFDIPurposeAndRelation(SalesCrMemoHeader, 0, SalesCrMemoHeader."CFDI Purpose", SalesCrMemoHeader."CFDI Relation");
                    SourceCode := SalesCrMemoHeader."Source Code";
                    ForeignTrade := SalesCrMemoHeader."Foreign Trade";
                    if ForeignTrade then begin
                        TempErrorMessage.LogIfEmpty(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("SAT Address ID"), TempErrorMessage."Message Type"::Error);
                        TempErrorMessage.LogIfEmpty(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("SAT International Trade Term"), TempErrorMessage."Message Type"::Error);
                        TempErrorMessage.LogIfEmpty(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Exchange Rate USD"), TempErrorMessage."Message Type"::Error);
                    end;
                    if SalesCrMemoHeader."Currency Code" <> '' then
                        TempErrorMessage.LogIfEmpty(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Currency Factor"), TempErrorMessage."Message Type"::Error);
                    DocumentNo := SalesCrMemoHeader."No.";
                    CustomerNo := SalesCrMemoHeader."Bill-to Customer No.";
                    PaymentTermsCode := SalesCrMemoHeader."Payment Terms Code";
                    PaymentMethodCode := SalesCrMemoHeader."Payment Method Code";
                    CFDIRelation := SalesCrMemoHeader."CFDI Relation";
                    CheckCFDIRelations(Database::"Sales Cr.Memo Header", 0, SalesCrMemoHeader."No.", CFDIRelation);
                end;
            else
                Error(SourceDocumentNotSupportedErr, SourceDocumentHeader.Caption());
        end;

        CheckSourceCodeForDeletedDocument(SourceCode);
        CheckPostedDocumentLines(SourceDocumentTableId, SourceDocumentType, DocumentNo, ForeignTrade);
        CheckCustomerFields(CustomerNo);
        CheckPaymentTermsAndMethodMapping(PaymentTermsCode, PaymentMethodCode);
        ThrowErrors();
    end;

    procedure CheckServiceDocument(SourceDocumentHeader: RecordRef)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        DocumentNo: Code[20];
        ForeignTrade: Boolean;
        SourceCode: Code[10];
        SourceDocumentTableId: Integer;
        SourceDocumentType: Integer;
        CustomerNo: Code[20];
        PaymentTermsCode: Code[10];
        PaymentMethodCode: Code[10];
        ServiceHeader: Record "Service Header";
    begin
        Clear(TempErrorMessage);
        CheckSATCatalogs();

        case SourceDocumentHeader.Number of
            Database::"Service Header":
                begin
                    SourceDocumentHeader.SetTable(ServiceHeader);
                    if not (ServiceHeader."Document Type" in [ServiceHeader."Document Type"::Order, ServiceHeader."Document Type"::Invoice, ServiceHeader."Document Type"::"Credit Memo"]) then
                        Error(SourceDocumentNotSupportedErr, SourceDocumentHeader.Caption());

                    SourceDocumentTableId := Database::"Service Header";
                    SourceDocumentType := ServiceHeader."Document Type".AsInteger();
                    TempErrorMessage.LogIfEmpty(ServiceHeader, ServiceHeader.FieldNo("No."), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceHeader, ServiceHeader.FieldNo("Document Date"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceHeader, ServiceHeader.FieldNo("Customer No."), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceHeader, ServiceHeader.FieldNo("Payment Method Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceHeader, ServiceHeader.FieldNo("Payment Terms Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceHeader, ServiceHeader.FieldNo("Bill-to Address"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceHeader, ServiceHeader.FieldNo("Bill-to Post Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceHeader, ServiceHeader.FieldNo("CFDI Purpose"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceHeader, ServiceHeader.FieldNo("CFDI Export Code"), TempErrorMessage."Message Type"::Error);
                    CheckCFDIPurposeAndRelation(ServiceHeader, 0, ServiceHeader."CFDI Purpose", ServiceHeader."CFDI Relation");
                    ForeignTrade := ServiceHeader."Foreign Trade";
                    if ForeignTrade then begin
                        TempErrorMessage.LogIfEmpty(ServiceHeader, ServiceHeader.FieldNo("SAT Address ID"), TempErrorMessage."Message Type"::Error);
                        TempErrorMessage.LogIfEmpty(ServiceHeader, ServiceHeader.FieldNo("SAT International Trade Term"), TempErrorMessage."Message Type"::Error);
                        TempErrorMessage.LogIfEmpty(ServiceHeader, ServiceHeader.FieldNo("Exchange Rate USD"), TempErrorMessage."Message Type"::Error);
                    end;
                    if ServiceHeader."Currency Code" <> '' then
                        TempErrorMessage.LogIfEmpty(ServiceHeader, ServiceHeader.FieldNo("Currency Factor"), TempErrorMessage."Message Type"::Error);
                    DocumentNo := ServiceHeader."No.";
                    CustomerNo := ServiceHeader."Customer No.";
                    PaymentTermsCode := ServiceHeader."Payment Terms Code";
                    PaymentMethodCode := ServiceHeader."Payment Method Code";
                    CheckCFDIRelations(Database::"Service Header", ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", ServiceHeader."CFDI Relation");
                end;
            Database::"Service Invoice Header":
                begin
                    SourceDocumentHeader.SetTable(ServiceInvoiceHeader);
                    SourceDocumentTableId := Database::"Service Invoice Header";
                    SourceDocumentType := 0;
                    TempErrorMessage.LogIfEmpty(ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("No."), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("Document Date"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("Customer No."), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("Payment Method Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("Payment Terms Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("Bill-to Address"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("Bill-to Post Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("CFDI Purpose"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("CFDI Export Code"), TempErrorMessage."Message Type"::Error);
                    CheckCFDIPurposeAndRelation(ServiceInvoiceHeader, 0, ServiceInvoiceHeader."CFDI Purpose", ServiceInvoiceHeader."CFDI Relation");
                    SourceCode := ServiceInvoiceHeader."Source Code";
                    ForeignTrade := ServiceInvoiceHeader."Foreign Trade";
                    if ForeignTrade then begin
                        TempErrorMessage.LogIfEmpty(ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("SAT Address ID"), TempErrorMessage."Message Type"::Error);
                        TempErrorMessage.LogIfEmpty(ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("SAT International Trade Term"), TempErrorMessage."Message Type"::Error);
                        TempErrorMessage.LogIfEmpty(ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("Exchange Rate USD"), TempErrorMessage."Message Type"::Error);
                    end;
                    if ServiceInvoiceHeader."Currency Code" <> '' then
                        TempErrorMessage.LogIfEmpty(ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("Currency Factor"), TempErrorMessage."Message Type"::Error);
                    DocumentNo := ServiceInvoiceHeader."No.";
                    CustomerNo := ServiceInvoiceHeader."Customer No.";
                    PaymentTermsCode := ServiceInvoiceHeader."Payment Terms Code";
                    PaymentMethodCode := ServiceInvoiceHeader."Payment Method Code";
                    CheckCFDIRelations(Database::"Service Invoice Header", 0, ServiceInvoiceHeader."No.", ServiceInvoiceHeader."CFDI Relation");
                end;
            Database::"Service Cr.Memo Header":
                begin
                    SourceDocumentHeader.SetTable(ServiceCrMemoHeader);
                    SourceDocumentTableId := Database::"Service Cr.Memo Header";
                    SourceDocumentType := 0;
                    TempErrorMessage.LogIfEmpty(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("No."), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("Document Date"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("Customer No."), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("Payment Method Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("Payment Terms Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("Bill-to Address"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("Bill-to Post Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("CFDI Purpose"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("CFDI Export Code"), TempErrorMessage."Message Type"::Error);
                    CheckCFDIPurposeAndRelation(ServiceCrMemoHeader, 0, ServiceCrMemoHeader."CFDI Purpose", ServiceCrMemoHeader."CFDI Relation");
                    SourceCode := ServiceCrMemoHeader."Source Code";
                    ForeignTrade := ServiceCrMemoHeader."Foreign Trade";
                    if ForeignTrade then begin
                        TempErrorMessage.LogIfEmpty(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("SAT Address ID"), TempErrorMessage."Message Type"::Error);
                        TempErrorMessage.LogIfEmpty(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("SAT International Trade Term"), TempErrorMessage."Message Type"::Error);
                        TempErrorMessage.LogIfEmpty(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("Exchange Rate USD"), TempErrorMessage."Message Type"::Error);
                    end;
                    if ServiceCrMemoHeader."Currency Code" <> '' then
                        TempErrorMessage.LogIfEmpty(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("Currency Factor"), TempErrorMessage."Message Type"::Error);
                    DocumentNo := ServiceCrMemoHeader."No.";
                    CustomerNo := ServiceCrMemoHeader."Customer No.";
                    PaymentTermsCode := ServiceCrMemoHeader."Payment Terms Code";
                    PaymentMethodCode := ServiceCrMemoHeader."Payment Method Code";
                    CheckCFDIRelations(Database::"Service Cr.Memo Header", 0, ServiceCrMemoHeader."No.", ServiceCrMemoHeader."CFDI Relation");
                end;
            else
                Error(SourceDocumentNotSupportedErr, SourceDocumentHeader.Caption());
        end;

        CheckSourceCodeForDeletedDocument(SourceCode);
        CheckPostedDocumentLines(SourceDocumentTableId, SourceDocumentType, DocumentNo, ForeignTrade);
        CheckCustomerFields(CustomerNo);
        CheckPaymentTermsAndMethodMapping(PaymentTermsCode, PaymentMethodCode);
        ThrowErrors();
    end;

    local procedure CheckPostedDocumentLines(DocumentTableId: Integer; DocumentType: Integer; DocumentNo: Code[20]; ForeignTrade: Boolean)
    var
        SourceDocumentLines: RecordRef;
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ServiceLine: Record "Service Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        case DocumentTableId of
            Database::"Sales Header":
                begin
                    SalesLine.SetRange("Document Type", DocumentType);
                    SalesLine.SetRange("Document No.", DocumentNo);
                    SourceDocumentLines.GetTable(SalesLine);
                end;
            Database::"Sales Invoice Header":
                begin
                    SalesInvoiceLine.SetRange("Document No.", DocumentNo);
                    SourceDocumentLines.GetTable(SalesInvoiceLine);
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoLine.SetRange("Document No.", DocumentNo);
                    SourceDocumentLines.GetTable(SalesCrMemoLine);
                end;
            Database::"Service Header":
                begin
                    ServiceLine.SetRange("Document Type", DocumentType);
                    ServiceLine.SetRange("Document No.", DocumentNo);
                    SourceDocumentLines.GetTable(ServiceLine);
                end;
            Database::"Service Invoice Header":
                begin
                    ServiceInvoiceLine.SetRange("Document No.", DocumentNo);
                    SourceDocumentLines.GetTable(ServiceInvoiceLine);
                end;
            Database::"Service Cr.Memo Header":
                begin
                    ServiceCrMemoLine.SetRange("Document No.", DocumentNo);
                    SourceDocumentLines.GetTable(ServiceCrMemoLine);
                end;
            else
                exit;
        end;

        CheckSalesDocumentLines(SourceDocumentLines);
        if ForeignTrade then
            CheckForeignTradeLineFields(DocumentTableId, DocumentType, DocumentNo);
    end;

    local procedure CheckForeignTradeLineFields(DocumentTableId: Integer; DocumentType: Integer; DocumentNo: Code[20])
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ServiceLine: Record "Service Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        case DocumentTableId of
            Database::"Sales Header":
                begin
                    SalesLine.SetRange("Document Type", DocumentType);
                    SalesLine.SetRange("Document No.", DocumentNo);
                    if SalesLine.FindSet() then
                        repeat
                            if (SalesLine.Type = SalesLine.Type::Item) and Item.Get(SalesLine."No.") then
                                TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("Tariff No."), TempErrorMessage."Message Type"::Error);
                            if UnitOfMeasure.Get(SalesLine."Unit of Measure Code") then
                                TempErrorMessage.LogIfEmpty(UnitOfMeasure, UnitOfMeasure.FieldNo("SAT Customs Unit"), TempErrorMessage."Message Type"::Error);
                        until SalesLine.Next() = 0;
                end;
            Database::"Sales Invoice Header":
                begin
                    SalesInvoiceLine.SetRange("Document No.", DocumentNo);
                    if SalesInvoiceLine.FindSet() then
                        repeat
                            if (SalesInvoiceLine.Type = SalesInvoiceLine.Type::Item) and Item.Get(SalesInvoiceLine."No.") then
                                TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("Tariff No."), TempErrorMessage."Message Type"::Error);
                            if UnitOfMeasure.Get(SalesInvoiceLine."Unit of Measure Code") then
                                TempErrorMessage.LogIfEmpty(UnitOfMeasure, UnitOfMeasure.FieldNo("SAT Customs Unit"), TempErrorMessage."Message Type"::Error);
                        until SalesInvoiceLine.Next() = 0;
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoLine.SetRange("Document No.", DocumentNo);
                    if SalesCrMemoLine.FindSet() then
                        repeat
                            if (SalesCrMemoLine.Type = SalesCrMemoLine.Type::Item) and Item.Get(SalesCrMemoLine."No.") then
                                TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("Tariff No."), TempErrorMessage."Message Type"::Error);
                            if UnitOfMeasure.Get(SalesCrMemoLine."Unit of Measure Code") then
                                TempErrorMessage.LogIfEmpty(UnitOfMeasure, UnitOfMeasure.FieldNo("SAT Customs Unit"), TempErrorMessage."Message Type"::Error);
                        until SalesCrMemoLine.Next() = 0;
                end;
            Database::"Service Header":
                begin
                    ServiceLine.SetRange("Document Type", DocumentType);
                    ServiceLine.SetRange("Document No.", DocumentNo);
                    if ServiceLine.FindSet() then
                        repeat
                            if (ServiceLine.Type = ServiceLine.Type::Item) and Item.Get(ServiceLine."No.") then
                                TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("Tariff No."), TempErrorMessage."Message Type"::Error);
                            if UnitOfMeasure.Get(ServiceLine."Unit of Measure Code") then
                                TempErrorMessage.LogIfEmpty(UnitOfMeasure, UnitOfMeasure.FieldNo("SAT Customs Unit"), TempErrorMessage."Message Type"::Error);
                        until ServiceLine.Next() = 0;
                end;
            Database::"Service Invoice Header":
                begin
                    ServiceInvoiceLine.SetRange("Document No.", DocumentNo);
                    if ServiceInvoiceLine.FindSet() then
                        repeat
                            if (ServiceInvoiceLine.Type = ServiceInvoiceLine.Type::Item) and Item.Get(ServiceInvoiceLine."No.") then
                                TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("Tariff No."), TempErrorMessage."Message Type"::Error);
                            if UnitOfMeasure.Get(ServiceInvoiceLine."Unit of Measure Code") then
                                TempErrorMessage.LogIfEmpty(UnitOfMeasure, UnitOfMeasure.FieldNo("SAT Customs Unit"), TempErrorMessage."Message Type"::Error);
                        until ServiceInvoiceLine.Next() = 0;
                end;
            Database::"Service Cr.Memo Header":
                begin
                    ServiceCrMemoLine.SetRange("Document No.", DocumentNo);
                    if ServiceCrMemoLine.FindSet() then
                        repeat
                            if (ServiceCrMemoLine.Type = ServiceCrMemoLine.Type::Item) and Item.Get(ServiceCrMemoLine."No.") then
                                TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("Tariff No."), TempErrorMessage."Message Type"::Error);
                            if UnitOfMeasure.Get(ServiceCrMemoLine."Unit of Measure Code") then
                                TempErrorMessage.LogIfEmpty(UnitOfMeasure, UnitOfMeasure.FieldNo("SAT Customs Unit"), TempErrorMessage."Message Type"::Error);
                        until ServiceCrMemoLine.Next() = 0;
                end;
        end;
    end;

    local procedure CheckCFDIPurposeAndRelation(RelatedRecord: Variant; FieldNo: Integer; CFDIPurpose: Code[10]; CFDIRelation: Code[10])
    begin
        if (CFDIPurpose = 'PPD') and (CFDIRelation = '03') then
            TempErrorMessage.LogMessage(RelatedRecord, FieldNo, TempErrorMessage."Message Type"::Error, StrSubstNo(CombinationCannotBeUsedErr, CFDIPurpose, CFDIRelation));
    end;

    local procedure CheckSourceCodeForDeletedDocument(SourceCode: Code[10])
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        if SourceCode = '' then
            exit;

        if not SourceCodeSetup.Get() then
            exit;

        if SourceCode = SourceCodeSetup."Deleted Document" then
            TempErrorMessage.LogMessage(SourceCodeSetup, 0, TempErrorMessage."Message Type"::Error, StrSubstNo(DeletedDocumentSourceCodeErr, SourceCode));
    end;

    procedure CheckPaymentDocument(var SourceDocumentHeader: RecordRef)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        Clear(TempErrorMessage);

        if SourceDocumentHeader.Number <> Database::"Cust. Ledger Entry" then
            Error(SourceDocumentNotSupportedErr, SourceDocumentHeader.Caption());

        SourceDocumentHeader.SetTable(CustLedgerEntry);

        if CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::Payment then
            Error(PaymentDocumentTypeErr, CustLedgerEntry."Document Type");

        TempErrorMessage.LogIfEmpty(CustLedgerEntry, CustLedgerEntry.FieldNo("Posting Date"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(CustLedgerEntry, CustLedgerEntry.FieldNo("Customer No."), TempErrorMessage."Message Type"::Error);
        CheckPaymentCustomerFields(CustLedgerEntry."Customer No.");
        TempErrorMessage.LogIfEmpty(CustLedgerEntry, CustLedgerEntry.FieldNo("Payment Method Code"), TempErrorMessage."Message Type"::Error);
        CheckPaymentMethodMapping(CustLedgerEntry."Payment Method Code");
        TempErrorMessage.LogIfEmpty(CustLedgerEntry, CustLedgerEntry.FieldNo("Currency Code"), TempErrorMessage."Message Type"::Error);

        GeneralLedgerSetup.Get();
        if CustLedgerEntry."Currency Code" <> GeneralLedgerSetup."LCY Code" then
            TempErrorMessage.LogIfEmpty(CustLedgerEntry, CustLedgerEntry.FieldNo("Original Currency Factor"), TempErrorMessage."Message Type"::Error);

        CheckPaymentDetailedEntries(CustLedgerEntry);
        CheckPaymentAppliedDocuments(CustLedgerEntry);
        ThrowErrors();
    end;

    procedure CheckCompanyInfo()
    var
        CompanyInformation: Record "Company Information";
    begin
        Clear(TempErrorMessage);
        CompanyInformation.Get();
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo(Name), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo(Address), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo(City), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo("Country/Region Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo("Post Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo("E-Mail"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo("RFC Number"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo("Tax Scheme"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo("SAT Tax Regime Classification"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo("SAT Postal Code"), TempErrorMessage."Message Type"::Error);
        ThrowErrors();
    end;

    procedure CheckCertificate(EDocService: Record "E-Document Service")
    var
        MXConnectionSetup: Record "MX Connection Setup";
    begin
        if EDocService."Service Integration V2" <> EDocService."Service Integration V2"::"Interfactura Service" then
            exit;

        if not MXConnectionSetup.Get() then
            Error(MXConnectionSetupMissingErr);

        MXConnectionSetup.TestField(Enabled, true);
        MXConnectionSetup.TestField("PAC Certificate");
        MXConnectionSetup.TestField("SAT Certificate");

        MXConnectionSetup.ValidatePrerequisites();
    end;

    procedure CheckSalesDocumentLines(var SourceDocumentLines: RecordRef)
    var
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ServiceLine: Record "Service Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        Item: Record Item;
        GLAccount: Record "G/L Account";
        ItemCharge: Record "Item Charge";
        FixedAsset: Record "Fixed Asset";
        UnitOfMeasureCode: Code[10];
        RequireUnitOfMeasure: Boolean;
    begin
        case SourceDocumentLines.Number of
            Database::"Sales Line":
                begin
                    SourceDocumentLines.SetTable(SalesLine);
                    if SalesLine.FindSet() then
                        repeat
                            if SalesLine.Type <> SalesLine.Type::" " then begin
                                TempErrorMessage.LogIfEmpty(SalesLine, SalesLine.FieldNo(Description), TempErrorMessage."Message Type"::Error);
                                TempErrorMessage.LogIfEmpty(SalesLine, SalesLine.FieldNo("Unit Price"), TempErrorMessage."Message Type"::Error);
                                UnitOfMeasureCode := SalesLine."Unit of Measure Code";
                                case SalesLine.Type of
                                    SalesLine.Type::Item:
                                        if Item.Get(SalesLine."No.") then
                                            TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("SAT Item Classification"), TempErrorMessage."Message Type"::Error);
                                    SalesLine.Type::"G/L Account":
                                        if GLAccount.Get(SalesLine."No.") then
                                            TempErrorMessage.LogIfEmpty(GLAccount, GLAccount.FieldNo("SAT Classification Code"), TempErrorMessage."Message Type"::Error);
                                    SalesLine.Type::"Charge (Item)":
                                        if ItemCharge.Get(SalesLine."No.") then
                                            TempErrorMessage.LogIfEmpty(ItemCharge, ItemCharge.FieldNo("SAT Classification Code"), TempErrorMessage."Message Type"::Error);
                                    SalesLine.Type::"Fixed Asset":
                                        if FixedAsset.Get(SalesLine."No.") then
                                            TempErrorMessage.LogIfEmpty(FixedAsset, FixedAsset.FieldNo("SAT Classification Code"), TempErrorMessage."Message Type"::Error);
                                end;
                                RequireUnitOfMeasure := not (SalesLine.Type in [SalesLine.Type::"G/L Account", SalesLine.Type::"Fixed Asset"]);
                                if RequireUnitOfMeasure then
                                    TempErrorMessage.LogIfEmpty(SalesLine, SalesLine.FieldNo("Unit of Measure Code"), TempErrorMessage."Message Type"::Error);
                                CheckLine(UnitOfMeasureCode);
                                LogRetentionWarnings(SalesLine.TableCaption(), SalesLine."Document No.", SalesLine."Line No.", SalesLine."Retention Attached to Line No.", SalesLine.Quantity, SalesLine."Retention VAT %");
                            end;
                        until SalesLine.Next() = 0;
                end;
            Database::"Sales Invoice Line":
                begin
                    SourceDocumentLines.SetTable(SalesInvoiceLine);
                    if SalesInvoiceLine.FindSet() then
                        repeat
                            if SalesInvoiceLine.Type <> SalesInvoiceLine.Type::" " then begin
                                TempErrorMessage.LogIfEmpty(SalesInvoiceLine, SalesInvoiceLine.FieldNo(Description), TempErrorMessage."Message Type"::Error);
                                TempErrorMessage.LogIfEmpty(SalesInvoiceLine, SalesInvoiceLine.FieldNo("Unit Price"), TempErrorMessage."Message Type"::Error);
                                TempErrorMessage.LogIfEmpty(SalesInvoiceLine, SalesInvoiceLine.FieldNo("Amount Including VAT"), TempErrorMessage."Message Type"::Error);
                                UnitOfMeasureCode := SalesInvoiceLine."Unit of Measure Code";
                                case SalesInvoiceLine.Type of
                                    SalesInvoiceLine.Type::Item:
                                        if Item.Get(SalesInvoiceLine."No.") then
                                            TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("SAT Item Classification"), TempErrorMessage."Message Type"::Error);
                                    SalesInvoiceLine.Type::"G/L Account":
                                        if not SalesInvoiceLine."Prepayment Line" and GLAccount.Get(SalesInvoiceLine."No.") then
                                            TempErrorMessage.LogIfEmpty(GLAccount, GLAccount.FieldNo("SAT Classification Code"), TempErrorMessage."Message Type"::Error);
                                    SalesInvoiceLine.Type::"Charge (Item)":
                                        if ItemCharge.Get(SalesInvoiceLine."No.") then
                                            TempErrorMessage.LogIfEmpty(ItemCharge, ItemCharge.FieldNo("SAT Classification Code"), TempErrorMessage."Message Type"::Error);
                                    SalesInvoiceLine.Type::"Fixed Asset":
                                        if FixedAsset.Get(SalesInvoiceLine."No.") then
                                            TempErrorMessage.LogIfEmpty(FixedAsset, FixedAsset.FieldNo("SAT Classification Code"), TempErrorMessage."Message Type"::Error);
                                end;
                                RequireUnitOfMeasure := not (SalesInvoiceLine.Type in [SalesInvoiceLine.Type::"G/L Account", SalesInvoiceLine.Type::"Fixed Asset"]);
                                if RequireUnitOfMeasure then
                                    TempErrorMessage.LogIfEmpty(SalesInvoiceLine, SalesInvoiceLine.FieldNo("Unit of Measure Code"), TempErrorMessage."Message Type"::Error);
                                CheckLine(UnitOfMeasureCode);
                                LogRetentionWarnings(SalesInvoiceLine.TableCaption(), SalesInvoiceLine."Document No.", SalesInvoiceLine."Line No.", SalesInvoiceLine."Retention Attached to Line No.", SalesInvoiceLine.Quantity, SalesInvoiceLine."Retention VAT %");
                            end;
                        until SalesInvoiceLine.Next() = 0;
                end;
            Database::"Sales Cr.Memo Line":
                begin
                    SourceDocumentLines.SetTable(SalesCrMemoLine);
                    if SalesCrMemoLine.FindSet() then
                        repeat
                            if SalesCrMemoLine.Type <> SalesCrMemoLine.Type::" " then begin
                                TempErrorMessage.LogIfEmpty(SalesCrMemoLine, SalesCrMemoLine.FieldNo(Description), TempErrorMessage."Message Type"::Error);
                                TempErrorMessage.LogIfEmpty(SalesCrMemoLine, SalesCrMemoLine.FieldNo("Unit Price"), TempErrorMessage."Message Type"::Error);
                                TempErrorMessage.LogIfEmpty(SalesCrMemoLine, SalesCrMemoLine.FieldNo("Amount Including VAT"), TempErrorMessage."Message Type"::Error);
                                UnitOfMeasureCode := SalesCrMemoLine."Unit of Measure Code";
                                case SalesCrMemoLine.Type of
                                    SalesCrMemoLine.Type::Item:
                                        if Item.Get(SalesCrMemoLine."No.") then
                                            TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("SAT Item Classification"), TempErrorMessage."Message Type"::Error);
                                    SalesCrMemoLine.Type::"G/L Account":
                                        if GLAccount.Get(SalesCrMemoLine."No.") then
                                            TempErrorMessage.LogIfEmpty(GLAccount, GLAccount.FieldNo("SAT Classification Code"), TempErrorMessage."Message Type"::Error);
                                    SalesCrMemoLine.Type::"Charge (Item)":
                                        if ItemCharge.Get(SalesCrMemoLine."No.") then
                                            TempErrorMessage.LogIfEmpty(ItemCharge, ItemCharge.FieldNo("SAT Classification Code"), TempErrorMessage."Message Type"::Error);
                                    SalesCrMemoLine.Type::"Fixed Asset":
                                        if FixedAsset.Get(SalesCrMemoLine."No.") then
                                            TempErrorMessage.LogIfEmpty(FixedAsset, FixedAsset.FieldNo("SAT Classification Code"), TempErrorMessage."Message Type"::Error);
                                end;
                                RequireUnitOfMeasure := not (SalesCrMemoLine.Type in [SalesCrMemoLine.Type::"G/L Account", SalesCrMemoLine.Type::"Fixed Asset"]);
                                if RequireUnitOfMeasure then
                                    TempErrorMessage.LogIfEmpty(SalesCrMemoLine, SalesCrMemoLine.FieldNo("Unit of Measure Code"), TempErrorMessage."Message Type"::Error);
                                CheckLine(UnitOfMeasureCode);
                                LogRetentionWarnings(SalesCrMemoLine.TableCaption(), SalesCrMemoLine."Document No.", SalesCrMemoLine."Line No.", SalesCrMemoLine."Retention Attached to Line No.", SalesCrMemoLine.Quantity, SalesCrMemoLine."Retention VAT %");
                            end;
                        until SalesCrMemoLine.Next() = 0;
                end;
            Database::"Service Line":
                begin
                    SourceDocumentLines.SetTable(ServiceLine);
                    if ServiceLine.FindSet() then
                        repeat
                            if ServiceLine.Type <> ServiceLine.Type::" " then begin
                                TempErrorMessage.LogIfEmpty(ServiceLine, ServiceLine.FieldNo(Description), TempErrorMessage."Message Type"::Error);
                                TempErrorMessage.LogIfEmpty(ServiceLine, ServiceLine.FieldNo("Unit Price"), TempErrorMessage."Message Type"::Error);
                                UnitOfMeasureCode := ServiceLine."Unit of Measure Code";
                                case ServiceLine.Type of
                                    ServiceLine.Type::Item:
                                        if Item.Get(ServiceLine."No.") then
                                            TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("SAT Item Classification"), TempErrorMessage."Message Type"::Error);
                                    ServiceLine.Type::"G/L Account":
                                        if GLAccount.Get(ServiceLine."No.") then
                                            TempErrorMessage.LogIfEmpty(GLAccount, GLAccount.FieldNo("SAT Classification Code"), TempErrorMessage."Message Type"::Error);
                                end;
                                RequireUnitOfMeasure := ServiceLine.Type <> ServiceLine.Type::"G/L Account";
                                if RequireUnitOfMeasure then
                                    TempErrorMessage.LogIfEmpty(ServiceLine, ServiceLine.FieldNo("Unit of Measure Code"), TempErrorMessage."Message Type"::Error);
                                CheckLine(UnitOfMeasureCode);
                            end;
                        until ServiceLine.Next() = 0;
                end;
            Database::"Service Invoice Line":
                begin
                    SourceDocumentLines.SetTable(ServiceInvoiceLine);
                    if ServiceInvoiceLine.FindSet() then
                        repeat
                            if ServiceInvoiceLine.Type <> ServiceInvoiceLine.Type::" " then begin
                                TempErrorMessage.LogIfEmpty(ServiceInvoiceLine, ServiceInvoiceLine.FieldNo(Description), TempErrorMessage."Message Type"::Error);
                                TempErrorMessage.LogIfEmpty(ServiceInvoiceLine, ServiceInvoiceLine.FieldNo("Unit Price"), TempErrorMessage."Message Type"::Error);
                                TempErrorMessage.LogIfEmpty(ServiceInvoiceLine, ServiceInvoiceLine.FieldNo("Amount Including VAT"), TempErrorMessage."Message Type"::Error);
                                UnitOfMeasureCode := ServiceInvoiceLine."Unit of Measure Code";
                                case ServiceInvoiceLine.Type of
                                    ServiceInvoiceLine.Type::Item:
                                        if Item.Get(ServiceInvoiceLine."No.") then
                                            TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("SAT Item Classification"), TempErrorMessage."Message Type"::Error);
                                    ServiceInvoiceLine.Type::"G/L Account":
                                        if GLAccount.Get(ServiceInvoiceLine."No.") then
                                            TempErrorMessage.LogIfEmpty(GLAccount, GLAccount.FieldNo("SAT Classification Code"), TempErrorMessage."Message Type"::Error);
                                end;
                                RequireUnitOfMeasure := ServiceInvoiceLine.Type <> ServiceInvoiceLine.Type::"G/L Account";
                                if RequireUnitOfMeasure then
                                    TempErrorMessage.LogIfEmpty(ServiceInvoiceLine, ServiceInvoiceLine.FieldNo("Unit of Measure Code"), TempErrorMessage."Message Type"::Error);
                                CheckLine(UnitOfMeasureCode);
                            end;
                        until ServiceInvoiceLine.Next() = 0;
                end;
            Database::"Service Cr.Memo Line":
                begin
                    SourceDocumentLines.SetTable(ServiceCrMemoLine);
                    if ServiceCrMemoLine.FindSet() then
                        repeat
                            if ServiceCrMemoLine.Type <> ServiceCrMemoLine.Type::" " then begin
                                TempErrorMessage.LogIfEmpty(ServiceCrMemoLine, ServiceCrMemoLine.FieldNo(Description), TempErrorMessage."Message Type"::Error);
                                TempErrorMessage.LogIfEmpty(ServiceCrMemoLine, ServiceCrMemoLine.FieldNo("Unit Price"), TempErrorMessage."Message Type"::Error);
                                TempErrorMessage.LogIfEmpty(ServiceCrMemoLine, ServiceCrMemoLine.FieldNo("Amount Including VAT"), TempErrorMessage."Message Type"::Error);
                                UnitOfMeasureCode := ServiceCrMemoLine."Unit of Measure Code";
                                case ServiceCrMemoLine.Type of
                                    ServiceCrMemoLine.Type::Item:
                                        if Item.Get(ServiceCrMemoLine."No.") then
                                            TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("SAT Item Classification"), TempErrorMessage."Message Type"::Error);
                                    ServiceCrMemoLine.Type::"G/L Account":
                                        if GLAccount.Get(ServiceCrMemoLine."No.") then
                                            TempErrorMessage.LogIfEmpty(GLAccount, GLAccount.FieldNo("SAT Classification Code"), TempErrorMessage."Message Type"::Error);
                                end;
                                RequireUnitOfMeasure := ServiceCrMemoLine.Type <> ServiceCrMemoLine.Type::"G/L Account";
                                if RequireUnitOfMeasure then
                                    TempErrorMessage.LogIfEmpty(ServiceCrMemoLine, ServiceCrMemoLine.FieldNo("Unit of Measure Code"), TempErrorMessage."Message Type"::Error);
                                CheckLine(UnitOfMeasureCode);
                            end;
                        until ServiceCrMemoLine.Next() = 0;
                end;
        end;
    end;

    local procedure CheckCustomerFields(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        if CustomerNo = '' then
            exit;
        Customer.Get(CustomerNo);
        TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("RFC No."), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("Country/Region Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("SAT Tax Regime Classification"), TempErrorMessage."Message Type"::Error);
    end;

    local procedure CheckCFDIRelations(DocumentTableId: Integer; DocumentType: Integer; DocumentNo: Code[20]; CFDIRelation: Code[10])
    var
        CFDIRelationDocument: Record "CFDI Relation Document";
    begin
        CFDIRelationDocument.SetRange("Document Table ID", DocumentTableId);
        CFDIRelationDocument.SetRange("Document Type", DocumentType);
        CFDIRelationDocument.SetRange("Document No.", DocumentNo);

        if CFDIRelationDocument.FindSet() then begin
            if CFDIRelation = '' then
                TempErrorMessage.LogMessage(CFDIRelationDocument, 0, TempErrorMessage."Message Type"::Error, StrSubstNo(CFDIRelationHeaderMissingErr, DocumentNo));

            repeat
                TempErrorMessage.LogIfEmpty(CFDIRelationDocument, CFDIRelationDocument.FieldNo("Fiscal Invoice Number PAC"), TempErrorMessage."Message Type"::Error);
            until CFDIRelationDocument.Next() = 0;
        end else
            if CFDIRelation = '04' then
                TempErrorMessage.LogMessage(CFDIRelationDocument, 0, TempErrorMessage."Message Type"::Error, StrSubstNo(CFDIRelationDocsMissingErr, CFDIRelation, DocumentNo));
    end;

    local procedure CheckPaymentTermsAndMethodMapping(PaymentTermsCode: Code[10]; PaymentMethodCode: Code[10])
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if PaymentTermsCode = '' then
            exit;
        if not PaymentTerms.Get(PaymentTermsCode) then
            exit;
        TempErrorMessage.LogIfEmpty(PaymentTerms, PaymentTerms.FieldNo("SAT Payment Term"), TempErrorMessage."Message Type"::Error);
        CheckPaymentMethodMapping(PaymentMethodCode);
    end;

    local procedure CheckPaymentMethodMapping(PaymentMethodCode: Code[10])
    var
        PaymentMethod: Record "Payment Method";
    begin
        if PaymentMethodCode = '' then
            exit;
        if not PaymentMethod.Get(PaymentMethodCode) then
            exit;
        TempErrorMessage.LogIfEmpty(PaymentMethod, PaymentMethod.FieldNo("SAT Method of Payment"), TempErrorMessage."Message Type"::Error);
    end;

    local procedure CheckPaymentCustomerFields(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        CheckCustomerFields(CustomerNo);
        if CustomerNo = '' then
            exit;
        Customer.Get(CustomerNo);
        TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("CFDI Customer Name"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("CFDI Export Code"), TempErrorMessage."Message Type"::Error);
    end;

    local procedure CheckPaymentAppliedDocuments(CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        AppliedCustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        HasAppliedDocuments: Boolean;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetFilter("Applied Cust. Ledger Entry No.", '<>%1', CustLedgerEntry."Entry No.");
        if not DetailedCustLedgEntry.FindSet() then begin
            TempErrorMessage.LogMessage(CustLedgerEntry, 0, TempErrorMessage."Message Type"::Error, StrSubstNo(PaymentAppliedDocumentMissingErr, CustLedgerEntry."Entry No."));
            exit;
        end;

        HasAppliedDocuments := false;

        repeat
            if not AppliedCustLedgerEntry.Get(DetailedCustLedgEntry."Applied Cust. Ledger Entry No.") then
                continue;

            HasAppliedDocuments := true;
            TempErrorMessage.LogIfEmpty(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo(Amount), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(AppliedCustLedgerEntry, AppliedCustLedgerEntry.FieldNo("Currency Code"), TempErrorMessage."Message Type"::Error);
            if AppliedCustLedgerEntry."Currency Code" <> CustLedgerEntry."Currency Code" then
                TempErrorMessage.LogIfEmpty(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Remaining Pmt. Disc. Possible"), TempErrorMessage."Message Type"::Error);

            case AppliedCustLedgerEntry."Document Type" of
                AppliedCustLedgerEntry."Document Type"::Invoice:
                    begin
                        if SalesInvoiceHeader.Get(AppliedCustLedgerEntry."Document No.") then begin
                            CheckAppliedDocumentIsStamped(SalesInvoiceHeader.RecordId());
                            TempErrorMessage.LogIfEmpty(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Bill-to Post Code"), TempErrorMessage."Message Type"::Error);
                        end else
                            if ServiceInvoiceHeader.Get(AppliedCustLedgerEntry."Document No.") then begin
                                CheckAppliedDocumentIsStamped(ServiceInvoiceHeader.RecordId());
                                TempErrorMessage.LogIfEmpty(ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("Bill-to Post Code"), TempErrorMessage."Message Type"::Error);
                            end else
                                TempErrorMessage.LogMessage(AppliedCustLedgerEntry, 0, TempErrorMessage."Message Type"::Error, StrSubstNo(PaymentAppliedHeaderMissingErr, AppliedCustLedgerEntry."Document No."));
                    end;
                AppliedCustLedgerEntry."Document Type"::"Credit Memo":
                    begin
                        if SalesCrMemoHeader.Get(AppliedCustLedgerEntry."Document No.") then begin
                            CheckAppliedDocumentIsStamped(SalesCrMemoHeader.RecordId());
                            TempErrorMessage.LogIfEmpty(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Bill-to Post Code"), TempErrorMessage."Message Type"::Error);
                        end else
                            if ServiceCrMemoHeader.Get(AppliedCustLedgerEntry."Document No.") then begin
                                CheckAppliedDocumentIsStamped(ServiceCrMemoHeader.RecordId());
                                TempErrorMessage.LogIfEmpty(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("Bill-to Post Code"), TempErrorMessage."Message Type"::Error);
                            end else
                                TempErrorMessage.LogMessage(AppliedCustLedgerEntry, 0, TempErrorMessage."Message Type"::Error, StrSubstNo(PaymentAppliedHeaderMissingErr, AppliedCustLedgerEntry."Document No."));
                    end;
            end;
        until DetailedCustLedgEntry.Next() = 0;

        if not HasAppliedDocuments then
            TempErrorMessage.LogMessage(CustLedgerEntry, 0, TempErrorMessage."Message Type"::Error, StrSubstNo(PaymentAppliedDocumentMissingErr, CustLedgerEntry."Entry No."));
    end;

    local procedure CheckAppliedDocumentIsStamped(DocumentRecordId: RecordId)
    var
        CFDIWriteBackMX: Codeunit "CFDI Write-Back MX";
        DummyRecord: Record "Cust. Ledger Entry";
    begin
        if not CFDIWriteBackMX.IsDocumentStamped(DocumentRecordId) then
            TempErrorMessage.LogMessage(DummyRecord, 0, TempErrorMessage."Message Type"::Error, StrSubstNo(DocumentNotStampedErr, Format(DocumentRecordId)));
    end;

    local procedure CheckPaymentDetailedEntries(CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetFilter(
            "Entry Type", '%1|%2|%3|%4',
            DetailedCustLedgEntry."Entry Type"::Application,
            DetailedCustLedgEntry."Entry Type"::"Realized Gain",
            DetailedCustLedgEntry."Entry Type"::"Realized Loss",
            DetailedCustLedgEntry."Entry Type"::"Correction of Remaining Amount");
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.SetRange("Initial Document Type", DetailedCustLedgEntry."Initial Document Type"::Payment);

        if not DetailedCustLedgEntry.FindFirst() then begin
            TempErrorMessage.LogMessage(CustLedgerEntry, 0, TempErrorMessage."Message Type"::Error, StrSubstNo(PaymentEntryDetailsMissingErr, CustLedgerEntry."Entry No."));
            exit;
        end;

        TempErrorMessage.LogIfEmpty(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo(Amount), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Amount (LCY)"), TempErrorMessage."Message Type"::Error);
    end;

    local procedure CheckSATCatalogs()
    var
        SATClassification: Record "SAT Classification";
        SATRelationshipType: Record "SAT Relationship Type";
        SATUseCode: Record "SAT Use Code";
        SATUnitOfMeasure: Record "SAT Unit of Measure";
        SATCountryCode: Record "SAT Country Code";
        SATTaxScheme: Record "SAT Tax Scheme";
        SATPaymentTerm: Record "SAT Payment Term";
        SATPaymentMethod: Record "SAT Payment Method";
        SATMaterialType: Record "SAT Material Type";
    begin
        if SATClassification.IsEmpty() then
            TempErrorMessage.LogMessage(SATClassification, 0, TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATClassification.TableCaption()));
        if SATRelationshipType.IsEmpty() then
            TempErrorMessage.LogMessage(SATRelationshipType, 0, TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATRelationshipType.TableCaption()));
        if SATUseCode.IsEmpty() then
            TempErrorMessage.LogMessage(SATUseCode, 0, TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATUseCode.TableCaption()));
        if SATUnitOfMeasure.IsEmpty() then
            TempErrorMessage.LogMessage(SATUnitOfMeasure, 0, TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATUnitOfMeasure.TableCaption()));
        if SATCountryCode.IsEmpty() then
            TempErrorMessage.LogMessage(SATCountryCode, 0, TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATCountryCode.TableCaption()));
        if SATTaxScheme.IsEmpty() then
            TempErrorMessage.LogMessage(SATTaxScheme, 0, TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATTaxScheme.TableCaption()));
        if SATPaymentTerm.IsEmpty() then
            TempErrorMessage.LogMessage(SATPaymentTerm, 0, TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATPaymentTerm.TableCaption()));
        if SATPaymentMethod.IsEmpty() then
            TempErrorMessage.LogMessage(SATPaymentMethod, 0, TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATPaymentMethod.TableCaption()));
        if SATMaterialType.IsEmpty() then
            TempErrorMessage.LogMessage(SATMaterialType, 0, TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATMaterialType.TableCaption()));
    end;

    local procedure CheckLine(UnitOfMeasureCode: Code[10])
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if (UnitOfMeasureCode <> '') and UnitOfMeasure.Get(UnitOfMeasureCode) then
            TempErrorMessage.LogIfEmpty(UnitOfMeasure, UnitOfMeasure.FieldNo("SAT UofM Classification"), TempErrorMessage."Message Type"::Error);
    end;

    local procedure ThrowErrors()
    begin
        if TempErrorMessage.HasErrors(false) then
            if TempErrorMessage.ShowErrors() then
                Error('');
    end;

    local procedure LogRetentionWarnings(LineTableCaption: Text; DocumentNo: Code[20]; LineNo: Integer; RetentionAttachedToLineNo: Integer; Quantity: Decimal; RetentionVATPercent: Decimal)
    begin
        if (RetentionAttachedToLineNo = 0) and (Quantity < 0) then
            Session.LogMessage(
              '0000QX4', StrSubstNo(NegativeQuantityWithoutRetentionTelemetryMsg, LineTableCaption, DocumentNo, LineNo),
              Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CFDIValidationTelemetryCategoryTxt);

        if (RetentionAttachedToLineNo <> 0) and (RetentionVATPercent = 0) then
            Session.LogMessage(
              '0000QX5', StrSubstNo(MissingRetentionVATTelemetryMsg, LineTableCaption, DocumentNo, LineNo),
              Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CFDIValidationTelemetryCategoryTxt);
    end;

    var
        TempErrorMessage: Record "Error Message" temporary;
        CFDIValidationTelemetryCategoryTxt: Label 'E-Document CFDI MX Validation', Locked = true;
        NegativeQuantityWithoutRetentionTelemetryMsg: Label '%1 %2 line %3 has negative quantity and is not attached to a retention line.', Locked = true;
        MissingRetentionVATTelemetryMsg: Label '%1 %2 line %3 is attached to a retention line but Retention VAT %% is zero.', Locked = true;
        SourceDocumentNotSupportedErr: Label 'The source document %1 is not supported for CFDI MX.', Comment = '%1 = source document caption';
        CombinationCannotBeUsedErr: Label 'The combination CFDI Purpose %1 and CFDI Relation %2 cannot be used.', Comment = '%1 = CFDI Purpose, %2 = CFDI Relation';
        DeletedDocumentSourceCodeErr: Label 'Source Code %1 corresponds to Deleted Document and cannot be stamped.', Comment = '%1 = Source Code';
        PaymentDocumentTypeErr: Label 'You can only stamp payment documents. Document type %1 is not supported.', Comment = '%1 = Document Type';
        PaymentEntryDetailsMissingErr: Label 'Payment entry %1 does not have detailed payment entries required to build payment complement amounts.', Comment = '%1 = Cust. Ledger Entry No.';
        PaymentAppliedDocumentMissingErr: Label 'Payment entry %1 does not have related applied documents for DoctoRelacionado.', Comment = '%1 = Cust. Ledger Entry No.';
        PaymentAppliedHeaderMissingErr: Label 'Applied document header %1 was not found in posted sales/service headers.', Comment = '%1 = Document No.';
        MXConnectionSetupMissingErr: Label 'Interfactura Connection Setup must be configured before sending CFDI documents.';
        CFDIRelationHeaderMissingErr: Label 'CFDI relation documents exist for document %1, but CFDI Relation on the header is empty.', Comment = '%1 = Document No.';
        CFDIRelationDocsMissingErr: Label 'CFDI Relation %1 on document %2 requires one or more related CFDI documents.', Comment = '%1 = CFDI Relation, %2 = Document No.';
        DocumentNotStampedErr: Label 'Document %1 has not been stamped (no cleared E-Document found). It cannot be used in a payment complement.', Comment = '%1 = Document RecordId';
        EmptySATCatalogErr: Label 'The %1 catalog is empty. Please import the SAT catalogs.', Comment = '%1 = table caption';
}
