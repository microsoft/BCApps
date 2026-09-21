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
        CheckSATCatalogs();

        case SourceDocumentHeader.Number of
            Database::"Sales Header":
                begin
                    SourceDocumentHeader.SetTable(SalesHeader);
                    if not (SalesHeader."Document Type" in [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::"Return Order", SalesHeader."Document Type"::"Credit Memo"]) then
                        Error(SourceDocumentNotSupportedErr, SourceDocumentHeader.Caption());

                    SourceDocumentTableId := Database::"Sales Header";
                    SourceDocumentType := SalesHeader."Document Type".AsInteger();
                    SalesHeader.TestField("No.");
                    SalesHeader.TestField("Document Date");
                    SalesHeader.TestField("Payment Method Code");
                    SalesHeader.TestField("Payment Terms Code");
                    SalesHeader.TestField("Bill-to Customer No.");
                    SalesHeader.TestField("Bill-to Address");
                    SalesHeader.TestField("Bill-to Post Code");
                    SalesHeader.TestField("CFDI Purpose");
                    SalesHeader.TestField("CFDI Export Code");
                    CheckCFDIPurposeAndRelation(SalesHeader."CFDI Purpose", SalesHeader."CFDI Relation");
                    ForeignTrade := SalesHeader."Foreign Trade";
                    if ForeignTrade then begin
                        SalesHeader.TestField("SAT Address ID");
                        SalesHeader.TestField("SAT International Trade Term");
                        SalesHeader.TestField("Exchange Rate USD");
                    end;
                    if SalesHeader."Currency Code" <> '' then
                        SalesHeader.TestField("Currency Factor");
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
                    SalesInvoiceHeader.TestField("No.");
                    SalesInvoiceHeader.TestField("Document Date");
                    SalesInvoiceHeader.TestField("Payment Method Code");
                    SalesInvoiceHeader.TestField("Payment Terms Code");
                    SalesInvoiceHeader.TestField("Bill-to Customer No.");
                    SalesInvoiceHeader.TestField("Bill-to Address");
                    SalesInvoiceHeader.TestField("Bill-to Post Code");
                    SalesInvoiceHeader.TestField("CFDI Purpose");
                    SalesInvoiceHeader.TestField("CFDI Export Code");
                    CheckCFDIPurposeAndRelation(SalesInvoiceHeader."CFDI Purpose", SalesInvoiceHeader."CFDI Relation");
                    SourceCode := SalesInvoiceHeader."Source Code";
                    ForeignTrade := SalesInvoiceHeader."Foreign Trade";
                    if ForeignTrade then begin
                        SalesInvoiceHeader.TestField("SAT Address ID");
                        SalesInvoiceHeader.TestField("SAT International Trade Term");
                        SalesInvoiceHeader.TestField("Exchange Rate USD");
                    end;
                    if SalesInvoiceHeader."Currency Code" <> '' then
                        SalesInvoiceHeader.TestField("Currency Factor");
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
                    SalesCrMemoHeader.TestField("No.");
                    SalesCrMemoHeader.TestField("Document Date");
                    SalesCrMemoHeader.TestField("Payment Method Code");
                    SalesCrMemoHeader.TestField("Payment Terms Code");
                    SalesCrMemoHeader.TestField("Bill-to Customer No.");
                    SalesCrMemoHeader.TestField("Bill-to Address");
                    SalesCrMemoHeader.TestField("Bill-to Post Code");
                    SalesCrMemoHeader.TestField("CFDI Purpose");
                    SalesCrMemoHeader.TestField("CFDI Export Code");
                    CheckCFDIPurposeAndRelation(SalesCrMemoHeader."CFDI Purpose", SalesCrMemoHeader."CFDI Relation");
                    SourceCode := SalesCrMemoHeader."Source Code";
                    ForeignTrade := SalesCrMemoHeader."Foreign Trade";
                    if ForeignTrade then begin
                        SalesCrMemoHeader.TestField("SAT Address ID");
                        SalesCrMemoHeader.TestField("SAT International Trade Term");
                        SalesCrMemoHeader.TestField("Exchange Rate USD");
                    end;
                    if SalesCrMemoHeader."Currency Code" <> '' then
                        SalesCrMemoHeader.TestField("Currency Factor");
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
        CheckSATCatalogs();

        case SourceDocumentHeader.Number of
            Database::"Service Header":
                begin
                    SourceDocumentHeader.SetTable(ServiceHeader);
                    if not (ServiceHeader."Document Type" in [ServiceHeader."Document Type"::Order, ServiceHeader."Document Type"::Invoice, ServiceHeader."Document Type"::"Credit Memo"]) then
                        Error(SourceDocumentNotSupportedErr, SourceDocumentHeader.Caption());

                    SourceDocumentTableId := Database::"Service Header";
                    SourceDocumentType := ServiceHeader."Document Type".AsInteger();
                    ServiceHeader.TestField("No.");
                    ServiceHeader.TestField("Document Date");
                    ServiceHeader.TestField("Customer No.");
                    ServiceHeader.TestField("Payment Method Code");
                    ServiceHeader.TestField("Payment Terms Code");
                    ServiceHeader.TestField("Bill-to Address");
                    ServiceHeader.TestField("Bill-to Post Code");
                    ServiceHeader.TestField("CFDI Purpose");
                    ServiceHeader.TestField("CFDI Export Code");
                    CheckCFDIPurposeAndRelation(ServiceHeader."CFDI Purpose", ServiceHeader."CFDI Relation");
                    ForeignTrade := ServiceHeader."Foreign Trade";
                    if ForeignTrade then begin
                        ServiceHeader.TestField("SAT Address ID");
                        ServiceHeader.TestField("SAT International Trade Term");
                        ServiceHeader.TestField("Exchange Rate USD");
                    end;
                    if ServiceHeader."Currency Code" <> '' then
                        ServiceHeader.TestField("Currency Factor");
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
                    ServiceInvoiceHeader.TestField("No.");
                    ServiceInvoiceHeader.TestField("Document Date");
                    ServiceInvoiceHeader.TestField("Customer No.");
                    ServiceInvoiceHeader.TestField("Payment Method Code");
                    ServiceInvoiceHeader.TestField("Payment Terms Code");
                    ServiceInvoiceHeader.TestField("Bill-to Address");
                    ServiceInvoiceHeader.TestField("Bill-to Post Code");
                    ServiceInvoiceHeader.TestField("CFDI Purpose");
                    ServiceInvoiceHeader.TestField("CFDI Export Code");
                    CheckCFDIPurposeAndRelation(ServiceInvoiceHeader."CFDI Purpose", ServiceInvoiceHeader."CFDI Relation");
                    SourceCode := ServiceInvoiceHeader."Source Code";
                    ForeignTrade := ServiceInvoiceHeader."Foreign Trade";
                    if ForeignTrade then begin
                        ServiceInvoiceHeader.TestField("SAT Address ID");
                        ServiceInvoiceHeader.TestField("SAT International Trade Term");
                        ServiceInvoiceHeader.TestField("Exchange Rate USD");
                    end;
                    if ServiceInvoiceHeader."Currency Code" <> '' then
                        ServiceInvoiceHeader.TestField("Currency Factor");
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
                    ServiceCrMemoHeader.TestField("No.");
                    ServiceCrMemoHeader.TestField("Document Date");
                    ServiceCrMemoHeader.TestField("Customer No.");
                    ServiceCrMemoHeader.TestField("Payment Method Code");
                    ServiceCrMemoHeader.TestField("Payment Terms Code");
                    ServiceCrMemoHeader.TestField("Bill-to Address");
                    ServiceCrMemoHeader.TestField("Bill-to Post Code");
                    ServiceCrMemoHeader.TestField("CFDI Purpose");
                    ServiceCrMemoHeader.TestField("CFDI Export Code");
                    CheckCFDIPurposeAndRelation(ServiceCrMemoHeader."CFDI Purpose", ServiceCrMemoHeader."CFDI Relation");
                    SourceCode := ServiceCrMemoHeader."Source Code";
                    ForeignTrade := ServiceCrMemoHeader."Foreign Trade";
                    if ForeignTrade then begin
                        ServiceCrMemoHeader.TestField("SAT Address ID");
                        ServiceCrMemoHeader.TestField("SAT International Trade Term");
                        ServiceCrMemoHeader.TestField("Exchange Rate USD");
                    end;
                    if ServiceCrMemoHeader."Currency Code" <> '' then
                        ServiceCrMemoHeader.TestField("Currency Factor");
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
                                Item.TestField("Tariff No.");
                            if UnitOfMeasure.Get(SalesLine."Unit of Measure Code") then
                                UnitOfMeasure.TestField("SAT Customs Unit");
                        until SalesLine.Next() = 0;
                end;
            Database::"Sales Invoice Header":
                begin
                    SalesInvoiceLine.SetRange("Document No.", DocumentNo);
                    if SalesInvoiceLine.FindSet() then
                        repeat
                            if (SalesInvoiceLine.Type = SalesInvoiceLine.Type::Item) and Item.Get(SalesInvoiceLine."No.") then
                                Item.TestField("Tariff No.");
                            if UnitOfMeasure.Get(SalesInvoiceLine."Unit of Measure Code") then
                                UnitOfMeasure.TestField("SAT Customs Unit");
                        until SalesInvoiceLine.Next() = 0;
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoLine.SetRange("Document No.", DocumentNo);
                    if SalesCrMemoLine.FindSet() then
                        repeat
                            if (SalesCrMemoLine.Type = SalesCrMemoLine.Type::Item) and Item.Get(SalesCrMemoLine."No.") then
                                Item.TestField("Tariff No.");
                            if UnitOfMeasure.Get(SalesCrMemoLine."Unit of Measure Code") then
                                UnitOfMeasure.TestField("SAT Customs Unit");
                        until SalesCrMemoLine.Next() = 0;
                end;
            Database::"Service Header":
                begin
                    ServiceLine.SetRange("Document Type", DocumentType);
                    ServiceLine.SetRange("Document No.", DocumentNo);
                    if ServiceLine.FindSet() then
                        repeat
                            if (ServiceLine.Type = ServiceLine.Type::Item) and Item.Get(ServiceLine."No.") then
                                Item.TestField("Tariff No.");
                            if UnitOfMeasure.Get(ServiceLine."Unit of Measure Code") then
                                UnitOfMeasure.TestField("SAT Customs Unit");
                        until ServiceLine.Next() = 0;
                end;
            Database::"Service Invoice Header":
                begin
                    ServiceInvoiceLine.SetRange("Document No.", DocumentNo);
                    if ServiceInvoiceLine.FindSet() then
                        repeat
                            if (ServiceInvoiceLine.Type = ServiceInvoiceLine.Type::Item) and Item.Get(ServiceInvoiceLine."No.") then
                                Item.TestField("Tariff No.");
                            if UnitOfMeasure.Get(ServiceInvoiceLine."Unit of Measure Code") then
                                UnitOfMeasure.TestField("SAT Customs Unit");
                        until ServiceInvoiceLine.Next() = 0;
                end;
            Database::"Service Cr.Memo Header":
                begin
                    ServiceCrMemoLine.SetRange("Document No.", DocumentNo);
                    if ServiceCrMemoLine.FindSet() then
                        repeat
                            if (ServiceCrMemoLine.Type = ServiceCrMemoLine.Type::Item) and Item.Get(ServiceCrMemoLine."No.") then
                                Item.TestField("Tariff No.");
                            if UnitOfMeasure.Get(ServiceCrMemoLine."Unit of Measure Code") then
                                UnitOfMeasure.TestField("SAT Customs Unit");
                        until ServiceCrMemoLine.Next() = 0;
                end;
        end;
    end;

    local procedure CheckCFDIPurposeAndRelation(CFDIPurpose: Code[10]; CFDIRelation: Code[10])
    begin
        if (CFDIPurpose = 'PPD') and (CFDIRelation = '03') then
            Error(CombinationCannotBeUsedErr, CFDIPurpose, CFDIRelation);
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
            Error(DeletedDocumentSourceCodeErr, SourceCode);
    end;

    procedure CheckPaymentDocument(var SourceDocumentHeader: RecordRef)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if SourceDocumentHeader.Number <> Database::"Cust. Ledger Entry" then
            Error(SourceDocumentNotSupportedErr, SourceDocumentHeader.Caption());

        SourceDocumentHeader.SetTable(CustLedgerEntry);

        if CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::Payment then
            Error(PaymentDocumentTypeErr, CustLedgerEntry."Document Type");

        CustLedgerEntry.TestField("Posting Date");
        CustLedgerEntry.TestField("Customer No.");
        CheckPaymentCustomerFields(CustLedgerEntry."Customer No.");
        CustLedgerEntry.TestField("Payment Method Code");
        CheckPaymentMethodMapping(CustLedgerEntry."Payment Method Code");
        CustLedgerEntry.TestField("Currency Code");

        GeneralLedgerSetup.Get();
        if CustLedgerEntry."Currency Code" <> GeneralLedgerSetup."LCY Code" then
            CustLedgerEntry.TestField("Original Currency Factor");

        CheckPaymentDetailedEntries(CustLedgerEntry);

        CheckPaymentAppliedDocuments(CustLedgerEntry);
    end;

    procedure CheckCompanyInfo()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.TestField(Name);
        CompanyInformation.TestField(Address);
        CompanyInformation.TestField(City);
        CompanyInformation.TestField("Country/Region Code");
        CompanyInformation.TestField("Post Code");
        CompanyInformation.TestField("E-Mail");
        CompanyInformation.TestField("RFC Number");
        CompanyInformation.TestField("Tax Scheme");
        CompanyInformation.TestField("SAT Tax Regime Classification");
        CompanyInformation.TestField("SAT Postal Code");
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
                                SalesLine.TestField(Description);
                                SalesLine.TestField("Unit Price");
                                UnitOfMeasureCode := SalesLine."Unit of Measure Code";
                                case SalesLine.Type of
                                    SalesLine.Type::Item:
                                        if Item.Get(SalesLine."No.") then
                                            Item.TestField("SAT Item Classification");
                                    SalesLine.Type::"G/L Account":
                                        if GLAccount.Get(SalesLine."No.") then
                                            GLAccount.TestField("SAT Classification Code");
                                    SalesLine.Type::"Charge (Item)":
                                        if ItemCharge.Get(SalesLine."No.") then
                                            ItemCharge.TestField("SAT Classification Code");
                                    SalesLine.Type::"Fixed Asset":
                                        if FixedAsset.Get(SalesLine."No.") then
                                            FixedAsset.TestField("SAT Classification Code");
                                end;
                                RequireUnitOfMeasure := not (SalesLine.Type in [SalesLine.Type::"G/L Account", SalesLine.Type::"Fixed Asset"]);
                                if RequireUnitOfMeasure then
                                    SalesLine.TestField("Unit of Measure Code");
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
                                SalesInvoiceLine.TestField(Description);
                                SalesInvoiceLine.TestField("Unit Price");
                                SalesInvoiceLine.TestField("Amount Including VAT");
                                UnitOfMeasureCode := SalesInvoiceLine."Unit of Measure Code";

                                case SalesInvoiceLine.Type of
                                    SalesInvoiceLine.Type::Item:
                                        if Item.Get(SalesInvoiceLine."No.") then
                                            Item.TestField("SAT Item Classification");
                                    SalesInvoiceLine.Type::"G/L Account":
                                        if not SalesInvoiceLine."Prepayment Line" and GLAccount.Get(SalesInvoiceLine."No.") then
                                            GLAccount.TestField("SAT Classification Code");
                                    SalesInvoiceLine.Type::"Charge (Item)":
                                        if ItemCharge.Get(SalesInvoiceLine."No.") then
                                            ItemCharge.TestField("SAT Classification Code");
                                    SalesInvoiceLine.Type::"Fixed Asset":
                                        if FixedAsset.Get(SalesInvoiceLine."No.") then
                                            FixedAsset.TestField("SAT Classification Code");
                                end;
                                RequireUnitOfMeasure := not (SalesInvoiceLine.Type in [SalesInvoiceLine.Type::"G/L Account", SalesInvoiceLine.Type::"Fixed Asset"]);
                                if RequireUnitOfMeasure then
                                    SalesInvoiceLine.TestField("Unit of Measure Code");
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
                                SalesCrMemoLine.TestField(Description);
                                SalesCrMemoLine.TestField("Unit Price");
                                SalesCrMemoLine.TestField("Amount Including VAT");
                                UnitOfMeasureCode := SalesCrMemoLine."Unit of Measure Code";

                                case SalesCrMemoLine.Type of
                                    SalesCrMemoLine.Type::Item:
                                        if Item.Get(SalesCrMemoLine."No.") then
                                            Item.TestField("SAT Item Classification");
                                    SalesCrMemoLine.Type::"G/L Account":
                                        if GLAccount.Get(SalesCrMemoLine."No.") then
                                            GLAccount.TestField("SAT Classification Code");
                                    SalesCrMemoLine.Type::"Charge (Item)":
                                        if ItemCharge.Get(SalesCrMemoLine."No.") then
                                            ItemCharge.TestField("SAT Classification Code");
                                    SalesCrMemoLine.Type::"Fixed Asset":
                                        if FixedAsset.Get(SalesCrMemoLine."No.") then
                                            FixedAsset.TestField("SAT Classification Code");
                                end;
                                RequireUnitOfMeasure := not (SalesCrMemoLine.Type in [SalesCrMemoLine.Type::"G/L Account", SalesCrMemoLine.Type::"Fixed Asset"]);
                                if RequireUnitOfMeasure then
                                    SalesCrMemoLine.TestField("Unit of Measure Code");
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
                                ServiceLine.TestField(Description);
                                ServiceLine.TestField("Unit Price");
                                UnitOfMeasureCode := ServiceLine."Unit of Measure Code";
                                case ServiceLine.Type of
                                    ServiceLine.Type::Item:
                                        if Item.Get(ServiceLine."No.") then
                                            Item.TestField("SAT Item Classification");
                                    ServiceLine.Type::"G/L Account":
                                        if GLAccount.Get(ServiceLine."No.") then
                                            GLAccount.TestField("SAT Classification Code");
                                end;
                                RequireUnitOfMeasure := ServiceLine.Type <> ServiceLine.Type::"G/L Account";
                                if RequireUnitOfMeasure then
                                    ServiceLine.TestField("Unit of Measure Code");
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
                                ServiceInvoiceLine.TestField(Description);
                                ServiceInvoiceLine.TestField("Unit Price");
                                ServiceInvoiceLine.TestField("Amount Including VAT");
                                UnitOfMeasureCode := ServiceInvoiceLine."Unit of Measure Code";

                                case ServiceInvoiceLine.Type of
                                    ServiceInvoiceLine.Type::Item:
                                        if Item.Get(ServiceInvoiceLine."No.") then
                                            Item.TestField("SAT Item Classification");
                                    ServiceInvoiceLine.Type::"G/L Account":
                                        if GLAccount.Get(ServiceInvoiceLine."No.") then
                                            GLAccount.TestField("SAT Classification Code");
                                end;
                                RequireUnitOfMeasure := ServiceInvoiceLine.Type <> ServiceInvoiceLine.Type::"G/L Account";
                                if RequireUnitOfMeasure then
                                    ServiceInvoiceLine.TestField("Unit of Measure Code");
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
                                ServiceCrMemoLine.TestField(Description);
                                ServiceCrMemoLine.TestField("Unit Price");
                                ServiceCrMemoLine.TestField("Amount Including VAT");
                                UnitOfMeasureCode := ServiceCrMemoLine."Unit of Measure Code";

                                case ServiceCrMemoLine.Type of
                                    ServiceCrMemoLine.Type::Item:
                                        if Item.Get(ServiceCrMemoLine."No.") then
                                            Item.TestField("SAT Item Classification");
                                    ServiceCrMemoLine.Type::"G/L Account":
                                        if GLAccount.Get(ServiceCrMemoLine."No.") then
                                            GLAccount.TestField("SAT Classification Code");
                                end;
                                RequireUnitOfMeasure := ServiceCrMemoLine.Type <> ServiceCrMemoLine.Type::"G/L Account";
                                if RequireUnitOfMeasure then
                                    ServiceCrMemoLine.TestField("Unit of Measure Code");
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
        Customer.Get(CustomerNo);

        Customer.TestField("RFC No.");
        Customer.TestField("Country/Region Code");
        Customer.TestField("SAT Tax Regime Classification");
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
                Error(CFDIRelationHeaderMissingErr, DocumentNo);

            repeat
                CFDIRelationDocument.TestField("Fiscal Invoice Number PAC");
            until CFDIRelationDocument.Next() = 0;
        end else
            if CFDIRelation = '04' then
                Error(CFDIRelationDocsMissingErr, CFDIRelation, DocumentNo);
    end;

    local procedure CheckPaymentTermsAndMethodMapping(PaymentTermsCode: Code[10]; PaymentMethodCode: Code[10])
    var
        PaymentTerms: Record "Payment Terms";
        SATPaymentTerm: Record "SAT Payment Term";
    begin
        PaymentTerms.Get(PaymentTermsCode);
        PaymentTerms.TestField("SAT Payment Term");
        SATPaymentTerm.Get(PaymentTerms."SAT Payment Term");

        CheckPaymentMethodMapping(PaymentMethodCode);
    end;

    local procedure CheckPaymentMethodMapping(PaymentMethodCode: Code[10])
    var
        PaymentMethod: Record "Payment Method";
        SATPaymentMethod: Record "SAT Payment Method";
    begin
        PaymentMethod.Get(PaymentMethodCode);
        PaymentMethod.TestField("SAT Method of Payment");
        SATPaymentMethod.Get(PaymentMethod."SAT Method of Payment");
    end;

    local procedure CheckPaymentCustomerFields(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        CheckCustomerFields(CustomerNo);

        Customer.Get(CustomerNo);

        Customer.TestField("CFDI Customer Name");
        Customer.TestField("CFDI Export Code");
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
        if not DetailedCustLedgEntry.FindSet() then
            Error(PaymentAppliedDocumentMissingErr, CustLedgerEntry."Entry No.");

        HasAppliedDocuments := false;

        repeat
            if not AppliedCustLedgerEntry.Get(DetailedCustLedgEntry."Applied Cust. Ledger Entry No.") then
                continue;

            HasAppliedDocuments := true;
            DetailedCustLedgEntry.TestField(Amount);
            AppliedCustLedgerEntry.TestField("Currency Code");
            if AppliedCustLedgerEntry."Currency Code" <> CustLedgerEntry."Currency Code" then
                DetailedCustLedgEntry.TestField("Remaining Pmt. Disc. Possible");

            case AppliedCustLedgerEntry."Document Type" of
                AppliedCustLedgerEntry."Document Type"::Invoice:
                    begin
                        if SalesInvoiceHeader.Get(AppliedCustLedgerEntry."Document No.") then begin
                            CheckAppliedDocumentIsStamped(SalesInvoiceHeader.RecordId());
                            SalesInvoiceHeader.TestField("Bill-to Post Code");
                        end else
                            if ServiceInvoiceHeader.Get(AppliedCustLedgerEntry."Document No.") then begin
                                CheckAppliedDocumentIsStamped(ServiceInvoiceHeader.RecordId());
                                ServiceInvoiceHeader.TestField("Bill-to Post Code");
                            end else
                                Error(PaymentAppliedHeaderMissingErr, AppliedCustLedgerEntry."Document No.");
                    end;
                AppliedCustLedgerEntry."Document Type"::"Credit Memo":
                    begin
                        if SalesCrMemoHeader.Get(AppliedCustLedgerEntry."Document No.") then begin
                            CheckAppliedDocumentIsStamped(SalesCrMemoHeader.RecordId());
                            SalesCrMemoHeader.TestField("Bill-to Post Code");
                        end else
                            if ServiceCrMemoHeader.Get(AppliedCustLedgerEntry."Document No.") then begin
                                CheckAppliedDocumentIsStamped(ServiceCrMemoHeader.RecordId());
                                ServiceCrMemoHeader.TestField("Bill-to Post Code");
                            end else
                                Error(PaymentAppliedHeaderMissingErr, AppliedCustLedgerEntry."Document No.");
                    end;
            end;
        until DetailedCustLedgEntry.Next() = 0;

        if not HasAppliedDocuments then
            Error(PaymentAppliedDocumentMissingErr, CustLedgerEntry."Entry No.");
    end;

    local procedure CheckAppliedDocumentIsStamped(DocumentRecordId: RecordId)
    var
        CFDIWriteBackMX: Codeunit "CFDI Write-Back MX";
    begin
        if not CFDIWriteBackMX.IsDocumentStamped(DocumentRecordId) then
            Error(DocumentNotStampedErr, Format(DocumentRecordId));
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

        if not DetailedCustLedgEntry.FindFirst() then
            Error(PaymentEntryDetailsMissingErr, CustLedgerEntry."Entry No.");

        DetailedCustLedgEntry.TestField(Amount);
        DetailedCustLedgEntry.TestField("Amount (LCY)");
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
            Error(EmptySATCatalogErr, SATClassification.TableCaption());
        if SATRelationshipType.IsEmpty() then
            Error(EmptySATCatalogErr, SATRelationshipType.TableCaption());
        if SATUseCode.IsEmpty() then
            Error(EmptySATCatalogErr, SATUseCode.TableCaption());
        if SATUnitOfMeasure.IsEmpty() then
            Error(EmptySATCatalogErr, SATUnitOfMeasure.TableCaption());
        if SATCountryCode.IsEmpty() then
            Error(EmptySATCatalogErr, SATCountryCode.TableCaption());
        if SATTaxScheme.IsEmpty() then
            Error(EmptySATCatalogErr, SATTaxScheme.TableCaption());
        if SATPaymentTerm.IsEmpty() then
            Error(EmptySATCatalogErr, SATPaymentTerm.TableCaption());
        if SATPaymentMethod.IsEmpty() then
            Error(EmptySATCatalogErr, SATPaymentMethod.TableCaption());
        if SATMaterialType.IsEmpty() then
            Error(EmptySATCatalogErr, SATMaterialType.TableCaption());
    end;

    local procedure CheckLine(UnitOfMeasureCode: Code[10])
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if (UnitOfMeasureCode <> '') and UnitOfMeasure.Get(UnitOfMeasureCode) then
            UnitOfMeasure.TestField("SAT UofM Classification");
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