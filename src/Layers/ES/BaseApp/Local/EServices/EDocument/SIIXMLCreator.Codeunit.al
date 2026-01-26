// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System;
using System.Reflection;
using System.Utilities;
using System.Xml;

codeunit 10750 "SII XML Creator"
{
    Permissions = TableData "Sales Invoice Header" = r,
                  TableData "Sales Cr.Memo Header" = r,
                  TableData "Purch. Inv. Header" = r,
                  TableData "Purch. Cr. Memo Hdr." = r;

    trigger OnRun()
    begin
    end;

    var
        CompanyInformation: Record "Company Information";
        SIISetup: Record "SII Setup";
        SIIManagement: Codeunit "SII Management";
        XMLDOMManagement: Codeunit "XML DOM Management";
        SoapenvTxt: Label 'http://schemas.xmlsoap.org/soap/envelope/', Locked = true;
        CompanyInformationMissingErr: Label 'Your company is not properly set up. Go to company information and complete your setup.';
        DataTypeManagement: Codeunit "Data Type Management";
        LastXMLNode: DotNet XmlNode;
        ErrorMsg: Text;
        DetailedLedgerEntryShouldBePaymentOrRefundErr: Label 'Expected the detailed ledger entry to have a Payment or Refund document type, but got %1 instead.', Comment = '%1 is the actual value of the Detailed Ledger Entry document type';
        RegistroDelPrimerSemestreTxt: Label 'Registro del primer semestre';
        IsInitialized: Boolean;
        RetryAccepted: Boolean;
        SIISetupInitialized: Boolean;
        UploadTypeGlb: Option Regular,Intracommunity,RetryAccepted,"Collection In Cash";
        LCLbl: Label 'LC', Locked = true;
        SIIVersion: Option "1.1","1.0","1.1bis";
        SiiTxt: Text;
        SiiLRTxt: Text;

    [Scope('OnPrem')]
    procedure GenerateXml(LedgerEntry: Variant; var XMLDocOut: DotNet XmlDocument; UploadType: Option; IsCreditMemoRemoval: Boolean) ResultValue: Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        RecRef: RecordRef;
        XmlDocumentOut: XmlDocument;
        IsHandled: Boolean;
    begin
        IsHandled := false;

        if not IsInitialized then
            XMLDocOut := XMLDocOut.XmlDocument();

        OnBeforeGenerateXmlDocument(LedgerEntry, XmlDocumentOut, UploadType, IsCreditMemoRemoval, ResultValue, IsHandled, RetryAccepted, SIIVersion);
        if IsHandled then begin
            ALXMLDocumentToDotNet(XmlDocumentOut, XMLDocOut);
            exit(ResultValue);
        end;

        GetSIISetup();
        SiiTxt := SIISetup."SuministroInformacion Schema";
        SiiLRTxt := SIISetup."SuministroLR Schema";

        RecRef.GetTable(LedgerEntry);
        case RecRef.Number of
            DATABASE::"Cust. Ledger Entry":
                begin
                    RecRef.SetTable(CustLedgerEntry);
                    if UploadType = UploadTypeGlb::"Collection In Cash" then
                        ResultValue := CreateCollectionInCashXml(XMLDocOut, CustLedgerEntry, UploadType)
                    else
                        ResultValue := CreateInvoicesIssuedLedgerXml(CustLedgerEntry, XMLDocOut, UploadType, IsCreditMemoRemoval);
                end;
            DATABASE::"Vendor Ledger Entry":
                begin
                    RecRef.SetTable(VendorLedgerEntry);
                    ResultValue := CreateInvoicesReceivedLedgerXml(VendorLedgerEntry, XMLDocOut, UploadType, IsCreditMemoRemoval);
                end;
            DATABASE::"Detailed Cust. Ledg. Entry":
                begin
                    RecRef.SetTable(DetailedCustLedgEntry);
                    if not (DetailedCustLedgEntry."Document Type" in
                            [DetailedCustLedgEntry."Document Type"::Payment, DetailedCustLedgEntry."Document Type"::Refund])
                    then
                        ErrorMsg := StrSubstNo(DetailedLedgerEntryShouldBePaymentOrRefundErr, Format(DetailedCustLedgEntry."Document Type"));
                    CustLedgerEntry.Get(DetailedCustLedgEntry."Cust. Ledger Entry No.");
                    ResultValue := CreateReceivedPaymentsXml(CustLedgerEntry, XMLDocOut);
                end;
            DATABASE::"Detailed Vendor Ledg. Entry":
                begin
                    RecRef.SetTable(DetailedVendorLedgEntry);
                    if not (DetailedVendorLedgEntry."Document Type" in
                            [DetailedVendorLedgEntry."Document Type"::Payment, DetailedVendorLedgEntry."Document Type"::Refund])
                    then
                        ErrorMsg := StrSubstNo(DetailedLedgerEntryShouldBePaymentOrRefundErr, Format(DetailedVendorLedgEntry."Document Type"));
                    VendorLedgerEntry.Get(DetailedVendorLedgEntry."Vendor Ledger Entry No.");
                    ResultValue := CreateEmittedPaymentsXml(VendorLedgerEntry, XMLDocOut);
                end
            else
                ResultValue := false;
        end;

        DotNetXMLDocumentToAL(XMLDocOut, XmlDocumentOut);
        IsHandled := false;
        OnAfterGenerateXmlDocument(LedgerEntry, XmlDocumentOut, UploadType, IsCreditMemoRemoval, ResultValue, RetryAccepted, SIIVersion, isHandled);
        if IsHandled then
            ALXMLDocumentToDotNet(XmlDocumentOut, XMLDocOut);
    end;

    local procedure ALXMLDocumentToDotNet(var XmlDocumentAl: XmlDocument; var XmlDocumentDotNet: DotNet XmlDocument)
    var
        XmlDocTempBlob: Codeunit "Temp Blob";
        XmlDocOutStream: OutStream;
        XmlDocInStream: InStream;
    begin
        XmlDocTempBlob.CreateOutStream(XmlDocOutStream);
        XmlDocumentAl.WriteTo(XmlDocOutStream);

        XmlDocTempBlob.CreateInStream(XmlDocInStream);
        XmlDocumentDotNet.Load(XmlDocInStream);
    end;

    local procedure DotNetXMLDocumentToAL(var XmlDocumentDotNet: DotNet XmlDocument; var XmlDocumentAl: XmlDocument)
    var
        XmlDocTempBlob: Codeunit "Temp Blob";
        TempXmlDocumentDotNet: DotNet XmlDocument;
        XmlDocOutStream: OutStream;
        XmlDocInStream: InStream;
    begin
        TempXmlDocumentDotNet := XmlDocumentDotNet;
        XmlDocTempBlob.CreateOutStream(XmlDocOutStream);
        TempXmlDocumentDotNet.Save(XmlDocOutStream);

        XmlDocTempBlob.CreateInStream(XmlDocInStream);
        XmlDocument.ReadFrom(XmlDocInStream, XmlDocumentAl);
    end;

    local procedure CreateEmittedPaymentsXml(PurchaseVendorLedgerEntry: Record "Vendor Ledger Entry"; var XMLDocOut: DotNet XmlDocument): Boolean
    var
        Vendor: Record Vendor;
        SIIDocUploadState: Record "SII Doc. Upload State";
        TempXMLNode: DotNet XmlNode;
        XMLNode: DotNet XmlNode;
        PurchaseVendorLedgerEntryRecRef: RecordRef;
        DocumentType: Option Sales,Purchase,"Intra Community","Payment Received","Payment Sent","Collection In Cash";
        HeaderName: Text;
        HeaderVATNo: Text;
    begin
        if not CompanyInformation.Get() then begin
            ErrorMsg := CompanyInformationMissingErr;
            exit;
        end;
        HeaderName := CompanyInformation.Name;
        HeaderVATNo := CompanyInformation."VAT Registration No.";

        SIIDocUploadState.GetSIIDocUploadStateByVendLedgEntry(PurchaseVendorLedgerEntry);
        PopulateXmlPrerequisites(
          XMLDocOut, XMLNode, DocumentType::"Payment Sent", HeaderName, HeaderVATNo, false, UploadTypeGlb::Regular);

        Vendor.Get(PurchaseVendorLedgerEntry."Vendor No.");
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'RegistroLRPagos', '', 'siiLR', SiiLRTxt, XMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'IDFactura', '', 'siiLR', SiiLRTxt, XMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'IDEmisorFactura', '', 'sii', SiiTxt, XMLNode);

        FillThirdPartyId(
          XMLNode,
          Vendor."Country/Region Code",
          Vendor.Name,
          Vendor."VAT Registration No.",
          Vendor."No.",
          true,
          SIIManagement.VendorIsIntraCommunity(Vendor."No."),
          false, SIIDocUploadState.IDType,
          SIIDocUploadState);

        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'NumSerieFacturaEmisor', PurchaseVendorLedgerEntry."External Document No.", 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'FechaExpedicionFacturaEmisor', FormatDate(PurchaseVendorLedgerEntry."Document Date"), 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);

        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'Pagos', '', 'siiLR', SiiLRTxt, XMLNode);

        PurchaseVendorLedgerEntryRecRef.GetTable(PurchaseVendorLedgerEntry);
        AddEmittedPayments(XMLNode, PurchaseVendorLedgerEntryRecRef);
        exit(true);
    end;

    local procedure CreateReceivedPaymentsXml(CustLedgerEntry: Record "Cust. Ledger Entry"; var XMLDocOut: DotNet XmlDocument): Boolean
    var
        TempXMLNode: DotNet XmlNode;
        XMLNode: DotNet XmlNode;
        SalesCustLedgerEntryRecRef: RecordRef;
        DocumentType: Option Sales,Purchase,"Intra Community","Payment Received","Payment Sent","Collection In Cash";
        HeaderName: Text;
        HeaderVATNo: Text;
    begin
        if not CompanyInformation.Get() then begin
            ErrorMsg := CompanyInformationMissingErr;
            exit;
        end;
        HeaderName := CompanyInformation.Name;
        HeaderVATNo := CompanyInformation."VAT Registration No.";

        PopulateXmlPrerequisites(
          XMLDocOut, XMLNode, DocumentType::"Payment Received", HeaderName, HeaderVATNo, false, UploadTypeGlb::Regular);

        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'RegistroLRCobros', '', 'siiLR', SiiLRTxt, XMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'IDFactura', '', 'siiLR', SiiLRTxt, XMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'IDEmisorFactura', '', 'sii', SiiTxt, XMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'NIF', CompanyInformation."VAT Registration No.", 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);

        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'NumSerieFacturaEmisor', CustLedgerEntry."Document No.", 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'FechaExpedicionFacturaEmisor', GetSalesExpeditionDate(CustLedgerEntry), 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);

        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'Cobros', '', 'siiLR', SiiLRTxt, XMLNode);

        SalesCustLedgerEntryRecRef.GetTable(CustLedgerEntry);
        AddReceivedPayments(XMLNode, SalesCustLedgerEntryRecRef);
        exit(true);
    end;

    local procedure AddEmittedPayments(var XMLNode: DotNet XmlNode; PurchaseVendorLedgerEntryRecRef: RecordRef)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        if SIIManagement.IsLedgerCashFlowBased(PurchaseVendorLedgerEntryRecRef) then begin
            PurchaseVendorLedgerEntryRecRef.SetTable(VendorLedgerEntry);
            VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type");
            VendorLedgerEntry.SetRange("Document No.", VendorLedgerEntry."Document No.");
            if VendorLedgerEntry.FindSet() then
                repeat
                    if SIIManagement.FindPaymentDetailedVendorLedgerEntries(PaymentDetailedVendorLedgEntry, VendorLedgerEntry) then
                        repeat
                            AddPayment(
                              XMLNode, 'Pago', PaymentDetailedVendorLedgEntry."Posting Date",
                              PaymentDetailedVendorLedgEntry.Amount, VendorLedgerEntry."Payment Method Code",
                              1, VendorLedgerEntry."Document Type" = VendorLedgerEntry."Document Type"::Refund);
                        until PaymentDetailedVendorLedgEntry.Next() = 0;
                until VendorLedgerEntry.Next() = 0;
        end;
    end;

    local procedure AddReceivedPayments(var XMLNode: DotNet XmlNode; SalesCustLedgerEntryRecRef: RecordRef)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        if SIIManagement.IsLedgerCashFlowBased(SalesCustLedgerEntryRecRef) then begin
            SalesCustLedgerEntryRecRef.SetTable(CustLedgerEntry);
            CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type");
            CustLedgerEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
            if CustLedgerEntry.FindSet() then
                repeat
                    if SIIManagement.FindPaymentDetailedCustomerLedgerEntries(PaymentDetailedCustLedgEntry, CustLedgerEntry) then
                        repeat
                            AddPayment(
                              XMLNode, 'Cobro', PaymentDetailedCustLedgEntry."Posting Date",
                              PaymentDetailedCustLedgEntry.Amount, CustLedgerEntry."Payment Method Code",
                              -1, CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Refund);
                        until PaymentDetailedCustLedgEntry.Next() = 0;
                until CustLedgerEntry.Next() = 0;
        end;
    end;

    local procedure AddPayment(var XMLNode: DotNet XmlNode; PmtHeaderTxt: Text; PostingDate: Date; Amount: Decimal; PaymentMethodCode: Code[10]; EntryTypeSign: Integer; Refund: Boolean)
    var
        TempXMLNode: DotNet XmlNode;
        BaseXMLNode: DotNet XmlNode;
        DocTypeSign: Integer;
    begin
        BaseXMLNode := XMLNode;
        XMLDOMManagement.AddElementWithPrefix(XMLNode, PmtHeaderTxt, '', 'sii', SiiTxt, XMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'Fecha', FormatDate(PostingDate), 'sii', SiiTxt, TempXMLNode);
        if Refund then
            DocTypeSign := -1
        else
            DocTypeSign := 1;
        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'Importe', FormatNumber(EntryTypeSign * DocTypeSign * Amount), 'sii', SiiTxt, TempXMLNode);
        InsertMedioNode(XMLNode, PaymentMethodCode);
        XMLNode := BaseXMLNode;
    end;

    local procedure CalculateNonExemptVATEntries(var TempVATEntryOut: Record "VAT Entry" temporary; TempVATEntry: Record "VAT Entry" temporary; SplitByEUService: Boolean; VATAmount: Decimal)
    begin
        if TempVATEntry."Ignore In SII" then
            exit;
        TempVATEntryOut.SetRange("VAT %", TempVATEntry."VAT %");
        TempVATEntryOut.SetRange("EC %", TempVATEntry."EC %");
        if SplitByEUService then
            TempVATEntryOut.SetRange("EU Service", TempVATEntry."EU Service");
        OnCalculateNonExemptVATEntriesOnAfterTempVATEntryOutSetFilters(TempVATEntryOut, TempVATEntry, SplitByEUService, VATAmount);
        if TempVATEntryOut.FindFirst() then begin
            TempVATEntryOut.Amount += VATAmount;
            TempVATEntryOut.Base += TempVATEntry.Base + TempVATEntry."Unrealized Base" + TempVATEntry."Non-Deductible VAT Base";
            TempVATEntryOut.Modify();
        end else begin
            TempVATEntryOut.Init();
            TempVATEntryOut.Copy(TempVATEntry);
            TempVATEntryOut.Amount := VATAmount;
            TempVATEntryOut.Base := TempVATEntryOut.Base + TempVATEntryOut."Unrealized Base" + TempVATEntry."Non-Deductible VAT Base";
            TempVATEntryOut.Insert();
        end;
        TempVATEntryOut.SetRange("VAT %");
        TempVATEntryOut.SetRange("EC %");
        TempVATEntryOut.SetRange("EU Service");

        OnAfterCalculateNonExemptVATEntries(TempVATEntryOut);
    end;

    local procedure CreateInvoicesIssuedLedgerXml(CustLedgerEntry: Record "Cust. Ledger Entry"; var XMLDocOut: DotNet XmlDocument; UploadType: Option; IsCreditMemoRemoval: Boolean): Boolean
    var
        XMLNode: DotNet XmlNode;
        DocumentType: Option Sales,Purchase,"Intra Community","Payment Received","Payment Sent","Collection In Cash";
    begin
        if not CompanyInformation.Get() then begin
            ErrorMsg := CompanyInformationMissingErr;
            exit(false);
        end;

        PopulateXmlPrerequisites(
          XMLDocOut, XMLNode, DocumentType::Sales, CompanyInformation.Name, CompanyInformation."VAT Registration No.",
          IsCreditMemoRemoval, UploadType);

        LastXMLNode := XMLNode;
        exit(PopulateXMLWithSalesInvoice(XMLNode, CustLedgerEntry));
    end;

    local procedure CreateInvoicesReceivedLedgerXml(VendorLedgerEntry: Record "Vendor Ledger Entry"; var XMLDocOut: DotNet XmlDocument; UploadType: Option; IsCreditMemoRemoval: Boolean): Boolean
    var
        XMLNode: DotNet XmlNode;
        DocumentType: Option Sales,Purchase,"Intra Community","Payment Received","Payment Sent","Collection In Cash";
    begin
        if not CompanyInformation.Get() then begin
            ErrorMsg := CompanyInformationMissingErr;
            exit(false);
        end;

        PopulateXmlPrerequisites(
          XMLDocOut, XMLNode, DocumentType::Purchase, CompanyInformation.Name, CompanyInformation."VAT Registration No.",
          IsCreditMemoRemoval, UploadType);

        LastXMLNode := XMLNode;
        exit(PopulateXMLWithPurchInvoice(XMLNode, VendorLedgerEntry));
    end;

    local procedure CreateCollectionInCashXml(var XMLDocOut: DotNet XmlDocument; CustLedgEntry: Record "Cust. Ledger Entry"; UploadType: Option): Boolean
    var
        XMLNode: DotNet XmlNode;
        DocumentType: Option Sales,Purchase,"Intra Community","Payment Received","Payment Sent","Collection In Cash";
    begin
        if not CompanyInformation.Get() then begin
            ErrorMsg := CompanyInformationMissingErr;
            exit(false);
        end;

        PopulateXmlPrerequisites(
          XMLDocOut, XMLNode, DocumentType::"Collection In Cash", CompanyInformation.Name, CompanyInformation."VAT Registration No.",
          false, UploadType);

        LastXMLNode := XMLNode;
        exit(PopulateXMLWithCollectionInCash(XMLNode, CustLedgEntry));
    end;

    local procedure FindCustLedgerEntryOfRefDocument(CustLedgerEntry: Record "Cust. Ledger Entry"; var OldCustLedgerEntry: Record "Cust. Ledger Entry"; CorrectedInvoiceNo: Code[20]): Boolean
    begin
        if CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::"Credit Memo" then
            exit(false);
        if CorrectedInvoiceNo = '' then
            exit(false);
        OldCustLedgerEntry.SetRange("Document No.", CorrectedInvoiceNo);
        OldCustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        exit(OldCustLedgerEntry.FindFirst())
    end;

    local procedure FindVendorLedgerEntryOfRefDocument(VendorLedgerEntry: Record "Vendor Ledger Entry"; var OldVendorLedgerEntry: Record "Vendor Ledger Entry"; CorrectedInvoiceNo: Code[20]): Boolean
    begin
        if VendorLedgerEntry."Document Type" <> VendorLedgerEntry."Document Type"::"Credit Memo" then
            exit(false);
        if CorrectedInvoiceNo = '' then
            exit(false);
        OldVendorLedgerEntry.SetRange("Document No.", CorrectedInvoiceNo);
        OldVendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        exit(OldVendorLedgerEntry.FindFirst())
    end;

    local procedure PopulateXmlPrerequisites(var XMLDoc: DotNet XmlDocument; var XMLNode: DotNet XmlNode; DocumentType: Option Sales,Purchase,"Intra Community","Payment Received","Payment Sent","Collection In Cash"; Name: Text; VATRegistrationNo: Text; IsCreditMemoRemoval: Boolean; UploadType: Option)
    var
        RootXMLNode: DotNet XmlNode;
        CurrentXMlNode: DotNet XmlNode;
        XMLNamespaceManager: DotNet XmlNamespaceManager;
    begin
        if IsInitialized then begin
            XMLNode := LastXMLNode;
            exit;
        end;
        IsInitialized := true;

        XMLDOMManagement.AddRootElementWithPrefix(XMLDoc, 'Envelope', 'soapenv', SoapenvTxt, RootXMLNode);
        XMLDOMManagement.AddAttribute(RootXMLNode, 'xmlns:sii', SiiTxt);
        XMLDOMManagement.AddAttribute(RootXMLNode, 'xmlns:siiLR', SiiLRTxt);
        XMLDOMManagement.AddDeclaration(XMLDoc, '1.0', 'UTF-8', '');
        XMLNamespaceManager := XMLNamespaceManager.XmlNamespaceManager(RootXMLNode.OwnerDocument.NameTable);
        XMLNamespaceManager.AddNamespace('siiLR', SiiLRTxt);
        XMLNamespaceManager.AddNamespace('sii', SiiTxt);

        XMLDOMManagement.AddElementWithPrefix(RootXMLNode, 'Header', '', 'soapenv', SoapenvTxt, CurrentXMlNode);
        XMLDOMManagement.AddElementWithPrefix(RootXMLNode, 'Body', '', 'soapenv', SoapenvTxt, CurrentXMlNode);
        case DocumentType of
            DocumentType::Sales:
                if IsCreditMemoRemoval then
                    XMLDOMManagement.AddElementWithPrefix(CurrentXMlNode, 'BajaLRFacturasEmitidas', '', 'siiLR', SiiLRTxt, CurrentXMlNode)
                else
                    XMLDOMManagement.AddElementWithPrefix(CurrentXMlNode, 'SuministroLRFacturasEmitidas', '', 'siiLR', SiiLRTxt, CurrentXMlNode);
            DocumentType::Purchase:
                if IsCreditMemoRemoval then
                    XMLDOMManagement.AddElementWithPrefix(CurrentXMlNode, 'BajaLRFacturasRecibidas', '', 'siiLR', SiiLRTxt, CurrentXMlNode)
                else
                    XMLDOMManagement.AddElementWithPrefix(CurrentXMlNode, 'SuministroLRFacturasRecibidas', '', 'siiLR', SiiLRTxt, CurrentXMlNode);
            DocumentType::"Intra Community":
                XMLDOMManagement.AddElementWithPrefix(
                  CurrentXMlNode, 'SuministroLRDetOperacionIntracomunitaria', '', 'siiLR', SiiLRTxt, CurrentXMlNode);
            DocumentType::"Payment Received":
                XMLDOMManagement.AddElementWithPrefix(CurrentXMlNode, 'SuministroLRCobrosEmitidas', '', 'siiLR', SiiLRTxt, CurrentXMlNode);
            DocumentType::"Payment Sent":
                XMLDOMManagement.AddElementWithPrefix(CurrentXMlNode, 'SuministroLRPagosRecibidas', '', 'siiLR', SiiLRTxt, CurrentXMlNode);
            DocumentType::"Collection In Cash":
                XMLDOMManagement.AddElementWithPrefix(CurrentXMlNode, 'SuministroLRCobrosMetalico', '', 'siiLR', SiiLRTxt, CurrentXMlNode);
        end;
        XMLDOMManagement.AddElementWithPrefix(CurrentXMlNode, 'Cabecera', '', 'sii', SiiTxt, CurrentXMlNode);
        XMLDOMManagement.AddElementWithPrefix(CurrentXMlNode, 'IDVersionSii', CopyStr(Format(SIIVersion), 1, 3), 'sii', SiiTxt, XMLNode); // API version
        XMLDOMManagement.AddElementWithPrefix(CurrentXMlNode, 'Titular', '', 'sii', SiiTxt, CurrentXMlNode);
        FillCompanyInfo(CurrentXMlNode, Name, VATRegistrationNo);
        XMLDOMManagement.FindNode(CurrentXMlNode, '..', CurrentXMlNode);

        if not (DocumentType in [DocumentType::"Payment Received", DocumentType::"Payment Sent"]) and not IsCreditMemoRemoval then
            if (UploadType = UploadTypeGlb::RetryAccepted) or RetryAccepted then
                XMLDOMManagement.AddElementWithPrefix(CurrentXMlNode, 'TipoComunicacion', 'A1', 'sii', SiiTxt, XMLNode)
            else
                XMLDOMManagement.AddElementWithPrefix(CurrentXMlNode, 'TipoComunicacion', 'A0', 'sii', SiiTxt, XMLNode);

        XMLDOMManagement.FindNode(CurrentXMlNode, '..', CurrentXMlNode);
        XMLNode := CurrentXMlNode;
    end;

    local procedure GetCustomerByGLSetup(var Customer: Record Customer; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        Customer.Get(SIIManagement.GetCustFromLedgEntryByGLSetup(CustLedgerEntry));
        OnAfterGetCustomerByGLSetup(Customer, CustLedgerEntry);
    end;

    local procedure PopulateXMLWithSalesInvoice(XMLNode: DotNet XmlNode; CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        Customer: Record Customer;
        TempServVATEntryCalcNonExempt: Record "VAT Entry" temporary;
        TempGoodsVATEntryCalcNonExempt: Record "VAT Entry" temporary;
        TempXMLNode: DotNet XmlNode;
        DesgloseFacturaXMLNode: DotNet XmlNode;
        DesgloseTipoOperacionXMLNode: DotNet XmlNode;
        DomesticXMLNode: DotNet XmlNode;
        EUServiceXMLNode: DotNet XmlNode;
        NonEUServiceXMLNode: DotNet XmlNode;
        CustLedgerEntryRecRef: RecordRef;
        NonExemptTransactionType: array[2] of Option S1,S2,S3,Initial;
        ExemptionCausePresent: array[2, 10] of Boolean;
        ExemptExists: array[2] of Boolean;
        AddNodeForTotals: Boolean;
        ExemptionBaseAmounts: array[2, 10] of Decimal;
        TotalBase: Decimal;
        TotalNonExemptBase: Decimal;
        TotalVATAmount: Decimal;
        TotalAmount: Decimal;
        TotalNDBase: Decimal;
        TotalNDAmount: Decimal;
        InvoiceType: Text;
        DomesticCustomer: Boolean;
        RegimeCodes: array[3] of Code[2];
        IsHandled: Boolean;
        ValueRefExternal: Text;
    begin
        GetCustomerByGLSetup(Customer, CustLedgerEntry);
        DomesticCustomer := SIIManagement.IsDomesticCustomer(Customer);

        SIIDocUploadState.GetSIIDocUploadStateByCustLedgEntry(CustLedgerEntry);
        if IsSalesInvoice(InvoiceType, SIIDocUploadState) then begin
            OnPopulateXMLWithSalesInvoiceOnBeforeInitializeSalesXmlBody(CustLedgerEntry);
            InitializeSalesXmlBody(XMLNode, CustLedgerEntry."VAT Reporting Date");
            if SIIDocUploadState."First Summary Doc. No." = '' then
                XMLDOMManagement.AddElementWithPrefix(
                  XMLNode, 'NumSerieFacturaEmisor', FORMAT(CustLedgerEntry."Document No."), 'sii', SiiTxt, TempXMLNode)
            else begin
                XMLDOMManagement.AddElementWithPrefix(
                  XMLNode, 'NumSerieFacturaEmisor', SIIDocUploadState."First Summary Doc. No.", 'sii', SiiTxt, TempXMLNode);
                XMLDOMManagement.AddElementWithPrefix(
                  XMLNode, 'NumSerieFacturaEmisorResumenFin', SIIDocUploadState."Last Summary Doc. No.", 'sii', SiiTxt, TempXMLNode);
            end;
            XMLDOMManagement.AddElementWithPrefix(
              XMLNode, 'FechaExpedicionFacturaEmisor', GetSalesExpeditionDate(CustLedgerEntry), 'sii', SiiTxt, TempXMLNode);
            XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);
            XMLDOMManagement.AddElementWithPrefix(XMLNode, 'FacturaExpedida', '', 'siiLR', SiiLRTxt, XMLNode);

            if InvoiceType = '' then
                XMLDOMManagement.AddElementWithPrefix(XMLNode, 'TipoFactura', 'F1', 'sii', SiiTxt, TempXMLNode)
            else
                XMLDOMManagement.AddElementWithPrefix(
                  XMLNode, 'TipoFactura', InvoiceType, 'sii', SiiTxt, TempXMLNode);

            GetClaveRegimenNodeSales(RegimeCodes, SIIDocUploadState, CustLedgerEntry, Customer);
            GenerateNodeForFechaOperacionSales(XMLNode, CustLedgerEntry, RegimeCodes);
            GenerateClaveRegimenNode(XMLNode, RegimeCodes);

            // 0) We may have both Services and Goods parts in the same document
            // 1) Build node for Services
            // 2) Build node for Goods
            if not DomesticCustomer then
                GetSourceForServiceOrGoods(
                  TempServVATEntryCalcNonExempt, ExemptionCausePresent[1], ExemptionBaseAmounts[1],
                  NonExemptTransactionType[1], ExemptExists[1], CustLedgerEntry, true, DomesticCustomer);
            GetSourceForServiceOrGoods(
              TempGoodsVATEntryCalcNonExempt, ExemptionCausePresent[2], ExemptionBaseAmounts[2],
              NonExemptTransactionType[2], ExemptExists[2], CustLedgerEntry, false, DomesticCustomer);

            AddNodeForTotals :=
              IncludeImporteTotalNode() and
              ((InvoiceType in [GetF2InvoiceType(), 'F4']) and
               (TempServVATEntryCalcNonExempt.Count + TempGoodsVATEntryCalcNonExempt.Count = 1)) or
              (SIIDocUploadState."Sales Special Scheme Code" in [SIIDocUploadState."Sales Special Scheme Code"::"03 Special System",
                                                                 SIIDocUploadState."Sales Special Scheme Code"::"05 Travel Agencies",
                                                                 SIIDocUploadState."Sales Special Scheme Code"::"09 Travel Agency Services"]);
            DataTypeManagement.GetRecordRef(CustLedgerEntry, CustLedgerEntryRecRef);
            CalculateTotalVatAndBaseAmounts(CustLedgerEntryRecRef, TotalBase, TotalNonExemptBase, TotalVATAmount, TotalNDBase, TotalNDAmount);

            OnPopulateXMLWithSalesInvoiceOnBeforeAddNodeForTotals(AddNodeForTotals, CustLedgerEntry, TotalBase, TotalNonExemptBase, TotalVATAmount);

            if AddNodeForTotals then begin
                TotalAmount := -TotalBase - TotalVATAmount;
                XMLDOMManagement.AddElementWithPrefix(
                  XMLNode, 'ImporteTotal', FormatNumber(TotalAmount), 'sii', SiiTxt, TempXMLNode);
            end;
            FillBaseImponibleACosteNode(XMLNode, RegimeCodes, -TotalNonExemptBase);

            FillOperationDescription(
              XMLNode, GetOperationDescriptionFromDocument(true, CustLedgerEntry."Document No."),
              CustLedgerEntry."Posting Date", CustLedgerEntry.Description);
            ValueRefExternal := Format(SIIDocUploadState."Entry No");
            OnPopulateXMLWithSalesInvoiceOnBeforeFillRefExternaNode(SIIDocUploadState, ValueRefExternal);
            FillRefExternaNode(XMLNode, ValueRefExternal);
            FillSucceededCompanyInfo(XMLNode, SIIDocUploadState);
            if AddNodeForTotals then
                FillMacrodatoNode(XMLNode, TotalAmount);

            if SIIDocUploadState."Issued By Third Party" then
                XMLDOMManagement.AddElementWithPrefix(XMLNode, 'EmitidaPorTercerosODestinatario', 'S', 'sii', SiiTxt, TempXMLNode);

            OnBeforeContraparteNode(XMLNode, CustLedgerEntry);
            if IncludeContraparteNodeBySalesInvType(InvoiceType) then begin
                XMLDOMManagement.AddElementWithPrefix(XMLNode, 'Contraparte', '', 'sii', SiiTxt, XMLNode);
                FillThirdPartyId(
                  XMLNode, Customer."Country/Region Code", Customer.Name, Customer."VAT Registration No.", Customer."No.", true,
                  SIIManagement.CustomerIsIntraCommunity(Customer."No."), Customer."Not in AEAT", SIIDocUploadState.IDType, SIIDocUploadState);
            end;
            IsHandled := false;
            OnPopulateXMLWithSalesInvoiceOnAfterContraparteNode(
                XMLNode, DesgloseFacturaXMLNode, DomesticXMLNode, DesgloseTipoOperacionXMLNode, false, DomesticCustomer, CustLedgerEntry, SiiTxt, IsHandled);
            if IsHandled then
                exit(true);

            XMLDOMManagement.AddElementWithPrefix(XMLNode, 'TipoDesglose', '', 'sii', SiiTxt, XMLNode);
            if DomesticCustomer then
                GenerateNodeForServicesOrGoodsDomesticCustomer(
                  TempGoodsVATEntryCalcNonExempt, TempServVATEntryCalcNonExempt, XMLNode, DesgloseFacturaXMLNode, DomesticXMLNode,
                  DesgloseTipoOperacionXMLNode, EUServiceXMLNode, NonEUServiceXMLNode, ExemptionCausePresent, ExemptionBaseAmounts,
                  NonExemptTransactionType, ExemptExists, CustLedgerEntry, DomesticCustomer, RegimeCodes)
            else
                GenerateNodeForServicesOrGoodsForeignCustomer(
                  TempGoodsVATEntryCalcNonExempt, TempServVATEntryCalcNonExempt, XMLNode, DesgloseFacturaXMLNode, DomesticXMLNode,
                  DesgloseTipoOperacionXMLNode, EUServiceXMLNode, NonEUServiceXMLNode, ExemptionCausePresent, ExemptionBaseAmounts,
                  NonExemptTransactionType, ExemptExists, CustLedgerEntry, DomesticCustomer, RegimeCodes);
            exit(true);
        end;

        exit(HandleCorrectiveInvoiceSales(XMLNode, SIIDocUploadState, CustLedgerEntry, Customer));
    end;

    local procedure PopulateXMLWithPurchInvoice(XMLNode: DotNet XmlNode; VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        TempVATEntryNormalCalculated: Record "VAT Entry" temporary;
        TempVATEntryReverseChargeCalculated: Record "VAT Entry" temporary;
        VATEntry: Record "VAT Entry";
        Vendor: Record Vendor;
        TempXMLNode: DotNet XmlNode;
        VendorLedgerEntryRecRef: RecordRef;
        AddNodeForTotals: Boolean;
        ECVATEntryExists: Boolean;
        CuotaDeducibleValue: Decimal;
        TotalBase: Decimal;
        TotalNonExemptBase: Decimal;
        TotalVATAmount: Decimal;
        TotalAmount: Decimal;
        TotalNDBase: Decimal;
        TotalNDAmount: Decimal;
        InvoiceType: Text;
        RegimeCodes: array[3] of Code[2];
        VendNo: Code[20];
        IsHandled: Boolean;
        ValueRefExternal: Text;
    begin
        Vendor.Get(VendorLedgerEntry."Vendor No.");
        DataTypeManagement.GetRecordRef(VendorLedgerEntry, VendorLedgerEntryRecRef);

        SIIDocUploadState.GetSIIDocUploadStateByVendLedgEntry(VendorLedgerEntry);
        if IsPurchInvoice(InvoiceType, SIIDocUploadState) then begin
            VendNo := SIIManagement.GetVendFromLedgEntryByGLSetup(VendorLedgerEntry);
            InitializePurchXmlBody(
              XMLNode, VendNo, VendorLedgerEntry, SIIDocUploadState.IDType, SIIDocUploadState);

            XMLDOMManagement.AddElementWithPrefix(
              XMLNode, 'NumSerieFacturaEmisor', Format(VendorLedgerEntry."External Document No."), 'sii', SiiTxt, TempXMLNode);
            XMLDOMManagement.AddElementWithPrefix(
              XMLNode, 'FechaExpedicionFacturaEmisor', FormatDate(VendorLedgerEntry."Document Date"), 'sii', SiiTxt, TempXMLNode);
            XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);
            XMLDOMManagement.AddElementWithPrefix(XMLNode, 'FacturaRecibida', '', 'siiLR', SiiLRTxt, XMLNode);

            if InvoiceType = '' then
                XMLDOMManagement.AddElementWithPrefix(XMLNode, 'TipoFactura', 'F1', 'sii', SiiTxt, TempXMLNode)
            else
                XMLDOMManagement.AddElementWithPrefix(
                  XMLNode, 'TipoFactura', InvoiceType, 'sii', SiiTxt, TempXMLNode);

            GenerateNodeForFechaOperacionPurch(XMLNode, VendorLedgerEntry);
            GetClaveRegimenNodePurchases(RegimeCodes, SIIDocUploadState, VendorLedgerEntry, Vendor);
            GenerateClaveRegimenNode(XMLNode, RegimeCodes);
            if SIIManagement.FindVatEntriesFromLedger(VendorLedgerEntryRecRef, VATEntry) then
                repeat
                    CalculatePurchVATEntries(
                      TempVATEntryNormalCalculated, TempVATEntryReverseChargeCalculated,
                      CuotaDeducibleValue, VATEntry,
                      VendNo, VendorLedgerEntry."Posting Date", InvoiceType);
                    ECVATEntryExists := ECVATEntryExists or (VATEntry."EC %" <> 0);
                until VATEntry.Next() = 0;

            AddNodeForTotals :=
              IncludeImporteTotalNode() and
              ((InvoiceType in [GetF2InvoiceType(), 'F4']) and
               (TempVATEntryNormalCalculated.Count + TempVATEntryReverseChargeCalculated.Count = 1)) or
              (SIIDocUploadState."Purch. Special Scheme Code" in [SIIDocUploadState."Purch. Special Scheme Code"::"03 Special System",
                                                                  SIIDocUploadState."Purch. Special Scheme Code"::"05 Travel Agencies"]);
            CalculateTotalVatAndBaseAmounts(VendorLedgerEntryRecRef, TotalBase, TotalNonExemptBase, TotalVATAmount, TotalNDBase, TotalNDAmount);

            OnPopulateXMLWithPurchInvoiceOnBeforeAddNodeForTotals(AddNodeForTotals, VendorLedgerEntry, TotalBase, TotalNonExemptBase, TotalVATAmount);

            if AddNodeForTotals then begin
                TotalAmount := TotalBase + TotalNDBase + TotalVATAmount + TotalNDAmount;
                XMLDOMManagement.AddElementWithPrefix(
                  XMLNode, 'ImporteTotal', FormatNumber(TotalAmount), 'sii', SiiTxt, TempXMLNode);
            end;
            FillBaseImponibleACosteNode(XMLNode, RegimeCodes, TotalNonExemptBase + TotalNDBase);

            FillOperationDescription(
              XMLNode, GetOperationDescriptionFromDocument(false, VendorLedgerEntry."Document No."),
              VendorLedgerEntry."Posting Date", VendorLedgerEntry.Description);
            ValueRefExternal := Format(SIIDocUploadState."Entry No");
            OnPopulateXMLWithPurchInvoiceOnBeforeFillRefExternaNode(SIIDocUploadState, ValueRefExternal);
            FillRefExternaNode(XMLNode, ValueRefExternal);

            FillSucceededCompanyInfo(XMLNode, SIIDocUploadState);
            if AddNodeForTotals then
                FillMacrodatoNode(XMLNode, TotalAmount);

            XMLDOMManagement.AddElementWithPrefix(XMLNode, 'DesgloseFactura', '', 'sii', SiiTxt, XMLNode);

            IsHandled := false;
            OnPopulateXMLWithPurchInvoiceOnBeforeDesgloseFacturaNode(
                XMLNode, TempVATEntryNormalCalculated, 'DesgloseIVA', RegimeCodes, VendorLedgerEntry, SiiTxt, IsHandled, TempVATEntryNormalCalculated, TempVATEntryReverseChargeCalculated);
            if not IsHandled then begin
                AddPurchVATEntriesWithElement(XMLNode, TempVATEntryReverseChargeCalculated, 'InversionSujetoPasivo', RegimeCodes);
                FillNoTaxableVATEntriesPurch(TempVATEntryNormalCalculated, VendorLedgerEntry);
                AddPurchVATEntriesWithElement(XMLNode, TempVATEntryNormalCalculated, 'DesgloseIVA', RegimeCodes);
            end;

            XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);

            AddPurchTail(
              XMLNode, VendorLedgerEntry."Posting Date", GetRequestDateOfSIIHistoryByVendLedgEntry(VendorLedgerEntry),
              VendNo, CuotaDeducibleValue, SIIDocUploadState.IDType, RegimeCodes, ECVATEntryExists, InvoiceType,
              not TempVATEntryReverseChargeCalculated.IsEmpty(), SIIDocUploadState);

            OnAfterAddPurchTail(XMLNode, VendorLedgerEntry);

            exit(true);
        end;

        // corrective invoice
        exit(HandleCorrectiveInvoicePurchases(XMLNode, SIIDocUploadState, VendorLedgerEntry, Vendor));
    end;

    local procedure PopulateXMLWithCollectionInCash(XMLNode: DotNet XmlNode; CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    var
        Customer: Record Customer;
        SIIDocUploadState: Record "SII Doc. Upload State";
        TempXMLNode: DotNet XmlNode;
    begin
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'RegistroLRCobrosMetalico', '', 'siiLR', SiiLRTxt, XMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, FillDocHeaderNode(), '', 'sii', SiiTxt, XMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'Ejercicio', GetYear(CustLedgerEntry."VAT Reporting Date"), 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'Periodo', '0A', 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);

        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'Contraparte', '', 'siiLR', SiiLRTxt, XMLNode);
        GetCustomerByGLSetup(Customer, CustLedgerEntry);
        SIIDocUploadState.GetSIIDocUploadStateByCustLedgEntry(CustLedgerEntry);
        FillThirdPartyId(
          XMLNode, Customer."Country/Region Code", Customer.Name, Customer."VAT Registration No.", Customer."No.", true,
          SIIManagement.CustomerIsIntraCommunity(Customer."No."), Customer."Not in AEAT", SIIDocUploadState.IDType, SIIDocUploadState);

        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'ImporteTotal', FormatNumber(CustLedgerEntry."Sales (LCY)"), 'siiLR', SiiLRTxt, TempXMLNode);
        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);
        exit(true);
    end;

    local procedure AddPurchVATEntriesWithElement(var XMLNode: DotNet XmlNode; var TempVATEntryCalculated: Record "VAT Entry" temporary; XMLNodeName: Text; RegimeCodes: array[3] of Code[2])
    begin
        if TempVATEntryCalculated.IsEmpty() then
            exit;
        XMLDOMManagement.AddElementWithPrefix(XMLNode, XMLNodeName, '', 'sii', SiiTxt, XMLNode);
        AddPurchVATEntries(XMLNode, TempVATEntryCalculated, RegimeCodes);
    end;

    [Scope('OnPrem')]
    procedure FormatDate(Value: Date): Text
    begin
        exit(Format(Value, 0, '<Day,2>-<Month,2>-<Year4>'));
    end;

    [Scope('OnPrem')]
    procedure FormatNumber(Number: Decimal): Text
    begin
        exit(Format(Number, 0, '<Precision,2:2><Standard Format,9>'));
    end;

    local procedure GetYear(Value: Date): Text
    begin
        exit(Format(Date2DMY(Value, 3)));
    end;

    local procedure InitializeCorrectiveRemovalXmlBody(var XMLNode: DotNet XmlNode; NewPostingDate: Date; IsSales: Boolean; SIIDocUploadState: Record "SII Doc. Upload State"; Name: Text; VATNo: Code[20]; CountryCode: Code[20]; ThirdPartyId: Code[20]; NotInAEAT: Boolean)
    var
        TempXMLNode: DotNet XmlNode;
        IssuerName: Text;
        IssuerVATNo: Code[20];
        IssuerCountryCode: Code[20];
        IssuerBackupVatNo: Code[20];
        IsIssuerIntraCommunity: Boolean;
    begin
        if IsSales then
            XMLDOMManagement.AddElementWithPrefix(XMLNode, 'RegistroLRBajaExpedidas', '', 'siiLR', SiiLRTxt, XMLNode)
        else
            XMLDOMManagement.AddElementWithPrefix(XMLNode, 'RegistroLRBajaRecibidas', '', 'siiLR', SiiLRTxt, XMLNode);

        XMLDOMManagement.AddElementWithPrefix(XMLNode, FillDocHeaderNode(), '', 'sii', SiiTxt, XMLNode);
        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'Ejercicio', GetYear(NewPostingDate), 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'Periodo', SIIManagement.GetTaxPeriod(NewPostingDate), 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'IDFactura', '', 'siiLR', SiiLRTxt, XMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'IDEmisorFactura', '', 'sii', SiiTxt, XMLNode);

        if IsSales then begin
            IssuerName := CompanyInformation.Name;
            IssuerVATNo := CompanyInformation."VAT Registration No.";
            IssuerCountryCode := CompanyInformation."Country/Region Code";
            IssuerBackupVatNo := CompanyInformation."VAT Registration No.";
            IsIssuerIntraCommunity := false;
        end else begin
            IssuerName := Name;
            IssuerVATNo := VATNo;
            IssuerCountryCode := CountryCode;
            IssuerBackupVatNo := ThirdPartyId;
            IsIssuerIntraCommunity := false;
        end;

        FillThirdPartyId(
          XMLNode,
          IssuerCountryCode,
          IssuerName,
          IssuerVATNo,
          IssuerBackupVatNo,
          not IsSales,
          IsIssuerIntraCommunity,
          NotInAEAT, SIIDocUploadState.IDType,
          SIIDocUploadState);

        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'NumSerieFacturaEmisor', Format(SIIDocUploadState."Corrected Doc. No."), 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'FechaExpedicionFacturaEmisor', FormatDate(SIIDocUploadState."Corr. Posting Date"), 'sii', SiiTxt, TempXMLNode);
    end;

    local procedure InitializeSalesXmlBody(var XMLNode: DotNet XmlNode; PostingDate: Date)
    var
        TempXMLNode: DotNet XmlNode;
    begin
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'RegistroLRFacturasEmitidas', '', 'siiLR', SiiLRTxt, XMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, FillDocHeaderNode(), '', 'sii', SiiTxt, XMLNode);
        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'Ejercicio', GetYear(PostingDate), 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'Periodo', SIIManagement.GetTaxPeriod(PostingDate), 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'IDFactura', '', 'siiLR', SiiLRTxt, XMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'IDEmisorFactura', '', 'sii', SiiTxt, XMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'NIF', CompanyInformation."VAT Registration No.", 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);
    end;

    local procedure InitializePurchXmlBody(var XMLNode: DotNet XmlNode; VendorNo: Code[20]; VendorLedgerEntry: Record "Vendor Ledger Entry"; IDType: Enum "SII ID Type"; SIIDocUploadState: Record "SII Doc. Upload State")
    var
        Vendor: Record Vendor;
        TempXMLNode: DotNet XmlNode;
        XmlNodeInnerXml: Text;
        IsHandled: Boolean;
    begin
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'RegistroLRFacturasRecibidas', '', 'siiLR', SiiLRTxt, XMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, FillDocHeaderNode(), '', 'sii', SiiTxt, XMLNode);

        OnInitializePurchXmlBodyOnBeforeAssignExerciseAndPeriod(XMLNode, VendorLedgerEntry, IsHandled);
        if not IsHandled then begin
            XMLDOMManagement.AddElementWithPrefix(
            XMLNode, 'Ejercicio', GetYear(VendorLedgerEntry."VAT Reporting Date"), 'sii', SiiTxt, TempXMLNode);
            XMLDOMManagement.AddElementWithPrefix(
            XMLNode, 'Periodo', SIIManagement.GetTaxPeriod(VendorLedgerEntry."VAT Reporting Date"), 'sii', SiiTxt, TempXMLNode);
        end;
        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'IDFactura', '', 'siiLR', SiiLRTxt, XMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'IDEmisorFactura', '', 'sii', SiiTxt, XMLNode);
        Vendor.Get(VendorNo);
        FillThirdPartyId(
          XMLNode, Vendor."Country/Region Code", Vendor.Name, Vendor."VAT Registration No.", Vendor."No.", false,
          SIIManagement.VendorIsIntraCommunity(Vendor."No."), false, IDType, SIIDocUploadState);

        XmlNodeInnerXml := XMLNode.InnerXml();
        OnAfterInitializePurchXmlBody(XmlNodeInnerXml, VendorLedgerEntry);
        XMLNode.InnerXml(XmlNodeInnerXml);
    end;

    local procedure AddPurchVATEntries(var XMLNode: DotNet XmlNode; var TempVATEntry: Record "VAT Entry" temporary; RegimeCodes: array[3] of Code[2])
    begin
        TempVATEntry.Reset();
        TempVATEntry.SetCurrentKey("VAT %", "EC %");
        TempVATEntry.SetRange("Ignore In SII", false);
        if TempVATEntry.FindSet() then
            repeat
                FillDetalleIVANode(XMLNode, TempVATEntry, true, 1, true, 0, RegimeCodes, 'CuotaSoportada');
            until TempVATEntry.Next() = 0;
        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);
    end;

    local procedure AddPurchTail(var XMLNode: DotNet XmlNode; PostingDate: Date; RequestDate: Date; BuyFromVendorNo: Code[20]; CuotaDeducibleValue: Decimal; IDType: Enum "SII ID Type"; RegimeCodes: array[3] of Code[2]; ECVATEntryExists: Boolean; InvoiceType: Text; HasReverseChargeEntry: Boolean; SIIDocUploadState: Record "SII Doc. Upload State")
    var
        Vendor: Record Vendor;
        TempXMLNode: DotNet XmlNode;
    begin
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'Contraparte', '', 'sii', SiiTxt, XMLNode);
        Vendor.Get(BuyFromVendorNo);
        FillThirdPartyId(
          XMLNode, Vendor."Country/Region Code", Vendor.Name, Vendor."VAT Registration No.", Vendor."No.",
          true, SIIManagement.VendorIsIntraCommunity(Vendor."No."), false, IDType, SIIDocUploadState);

        FillFechaRegContable(XMLNode, PostingDate, RequestDate);
        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'CuotaDeducible',
          FormatNumber(CalcCuotaDeducible(PostingDate, RegimeCodes, IDType, ECVATEntryExists, InvoiceType,
              HasReverseChargeEntry, CuotaDeducibleValue)),
          'sii', SiiTxt, TempXMLNode);
    end;

    local procedure FillThirdPartyId(var XMLNode: DotNet XmlNode; CountryCode: Code[20]; Name: Text; VatNo: Code[20]; BackupVatId: Code[20]; NeedNombreRazon: Boolean; IsIntraCommunity: Boolean; IsNotInAEAT: Boolean; IDTypeInt: Enum "SII ID Type"; SIIDocUploadState: Record "SII Doc. Upload State")
    var
        TempXMLNode: DotNet XmlNode;
        IDType: Text[30];
    begin
        OnFillThirdPartyIdOnBeforeAssignValues(SIIDocUploadState, CountryCode, Name, VatNo, IsIntraCommunity);

        if VatNo = '' then
            VatNo := BackupVatId;
        IDType := GetIDTypeToExport(IDTypeInt);

        OnFillThirdPartyIdOnBeforeCheckCountryAndVATRegNo(CountryCode);

        if SIIManagement.CountryAndVATRegNoAreLocal(CountryCode, VatNo) then begin
            if NeedNombreRazon then
                XMLDOMManagement.AddElementWithPrefix(XMLNode, 'NombreRazon', Name, 'sii', SiiTxt, TempXMLNode);
            if IsNotInAEAT then begin
                XMLDOMManagement.AddElementWithPrefix(XMLNode, 'IDOtro', '', 'sii', SiiTxt, XMLNode);
                // In case of self employment, we use '07' means "Unregistered"
                XMLDOMManagement.AddElementWithPrefix(XMLNode, 'CodigoPais', CountryCode, 'sii', SiiTxt, TempXMLNode);
                XMLDOMManagement.AddElementWithPrefix(XMLNode, 'IDType', IDType, 'sii', SiiTxt, TempXMLNode);
                XMLDOMManagement.AddElementWithPrefix(XMLNode, 'ID', VatNo, 'sii', SiiTxt, TempXMLNode);
                XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);
            end else
                XMLDOMManagement.AddElementWithPrefix(XMLNode, 'NIF', VatNo, 'sii', SiiTxt, TempXMLNode);
        end else begin
            if NeedNombreRazon then
                XMLDOMManagement.AddElementWithPrefix(XMLNode, 'NombreRazon', Name, 'sii', SiiTxt, TempXMLNode);
            XMLDOMManagement.AddElementWithPrefix(XMLNode, 'IDOtro', '', 'sii', SiiTxt, XMLNode);
            if not SIIManagement.CountryIsNorthernIreland(CountryCode) then
                XMLDOMManagement.AddElementWithPrefix(XMLNode, 'CodigoPais', CountryCode, 'sii', SiiTxt, TempXMLNode);

            if IsIntraCommunity then
                XMLDOMManagement.AddElementWithPrefix(XMLNode, 'IDType', IDType, 'sii', SiiTxt, TempXMLNode)
            else
                if IsNotInAEAT then
                    // In case of self employment, we use '07' means "Unregistered"
                    XMLDOMManagement.AddElementWithPrefix(XMLNode, 'IDType', IDType, 'sii', SiiTxt, TempXMLNode)
                else
                    XMLDOMManagement.AddElementWithPrefix(XMLNode, 'IDType', IDType, 'sii', SiiTxt, TempXMLNode);
            XMLDOMManagement.AddElementWithPrefix(XMLNode, 'ID', VatNo, 'sii', SiiTxt, TempXMLNode);
            XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);
        end;
        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);
    end;

    local procedure AddTipoDesgloseDetailHeader(var TipoDesgloseXMLNode: DotNet XmlNode; var DesgloseFacturaXMLNode: DotNet XmlNode; var DomesticXMLNode: DotNet XmlNode; var DesgloseTipoOperacionXMLNode: DotNet XmlNode; var EUXMLNode: DotNet XmlNode; var VATXMLNode: DotNet XmlNode; EUService: Boolean; DomesticCustomer: Boolean; NoTaxableVAT: Boolean)
    var
        VATNodeName: Text;
    begin
        VATNodeName := GetVATNodeName(NoTaxableVAT);
        if DomesticCustomer then begin
            if IsNull(DesgloseFacturaXMLNode) then
                XMLDOMManagement.AddElementWithPrefix(TipoDesgloseXMLNode, 'DesgloseFactura', '', 'sii', SiiTxt, DesgloseFacturaXMLNode);
            if IsNull(DomesticXMLNode) then
                XMLDOMManagement.AddElementWithPrefix(DesgloseFacturaXMLNode, VATNodeName, '', 'sii', SiiTxt, DomesticXMLNode);
            VATXMLNode := DomesticXMLNode;
        end else begin
            if IsNull(DesgloseTipoOperacionXMLNode) then
                XMLDOMManagement.AddElementWithPrefix(
                  TipoDesgloseXMLNode, 'DesgloseTipoOperacion', '', 'sii', SiiTxt, DesgloseTipoOperacionXMLNode);
            if EUService then
                AddVATXMLNodeUnderParentNode(EUXMLNode, VATXMLNode, DesgloseTipoOperacionXMLNode, 'PrestacionServicios', VATNodeName)
            else
                AddVATXMLNodeUnderParentNode(EUXMLNode, VATXMLNode, DesgloseTipoOperacionXMLNode, 'Entrega', VATNodeName);
        end;
    end;

    local procedure AddVATXMLNodeUnderParentNode(var EUXMLNode: DotNet XmlNode; var VATXMLNode: DotNet XmlNode; DesgloseTipoOperacionXMLNode: DotNet XmlNode; ParentVATNodeName: Text; VATNodeName: Text)
    begin
        if IsNull(EUXMLNode) then
            XMLDOMManagement.AddElementWithPrefix(DesgloseTipoOperacionXMLNode, ParentVATNodeName, '', 'sii', SiiTxt, EUXMLNode);
        if IsNull(VATXMLNode) then
            XMLDOMManagement.AddElementWithPrefix(EUXMLNode, VATNodeName, '', 'sii', SiiTxt, VATXMLNode);
    end;

    local procedure FillSucceededCompanyInfo(var XMLNode: DotNet XmlNode; SIIDocUploadState: Record "SII Doc. Upload State")
    begin
        if (not IncludeChangesVersion11()) or (SIIDocUploadState."Succeeded Company Name" = '') then
            exit;

        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'EntidadSucedida', '', 'sii', SiiTxt, XMLNode);
        FillCompanyInfo(XMLNode, SIIDocUploadState."Succeeded Company Name", SIIDocUploadState."Succeeded VAT Registration No.");
        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);
    end;

    local procedure FillCompanyInfo(var XMLNode: DotNet XmlNode; Name: Text; VATRegistrationNo: Text)
    var
        TempXMLNode: DotNet XmlNode;
    begin
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'NombreRazon', Name, 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'NIF', VATRegistrationNo, 'sii', SiiTxt, TempXMLNode);
    end;

    local procedure CalculateECAmount(Base: Decimal; ECPercentage: Decimal): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(Round(Base * ECPercentage / 100, GeneralLedgerSetup."Amount Rounding Precision"));
    end;

    local procedure CalculateNonTaxableAmountVendor(VendLedgEntry: Record "Vendor Ledger Entry"): Decimal
    var
        NoTaxableEntry: Record "No Taxable Entry";
    begin
        if SIIManagement.NoTaxableEntriesExistPurchase(
             NoTaxableEntry,
             SIIManagement.GetVendFromLedgEntryByGLSetup(VendLedgEntry), VendLedgEntry."Document Type".AsInteger(),
             VendLedgEntry."Document No.", VendLedgEntry."Posting Date", false)
        then begin
            NoTaxableEntry.CalcSums("Amount (LCY)");
            exit(NoTaxableEntry."Amount (LCY)");
        end;
        exit(0);
    end;

    local procedure CalcNonExemptVATEntriesWithCuotaDeducible(var TempVATEntry: Record "VAT Entry" temporary; var CuotaDeducible: Decimal; VendorLedgerEntry: Record "Vendor Ledger Entry"; Sign: Integer)
    var
        VATEntry: Record "VAT Entry";
        VendorLedgerEntryRecRef: RecordRef;
        VATAmount: Decimal;
    begin
        DataTypeManagement.GetRecordRef(VendorLedgerEntry, VendorLedgerEntryRecRef);
        if SIIManagement.FindVatEntriesFromLedger(VendorLedgerEntryRecRef, VATEntry) then
            repeat
                VATAmount := CalcVATAmountExclEC(VATEntry) + VATEntry."Non-Deductible VAT Amount";
                CuotaDeducible += Sign * VATAmount;
                CalculateNonExemptVATEntries(TempVATEntry, VATEntry, true, VATAmount);
            until VATEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetLastErrorMsg(): Text
    begin
        exit(ErrorMsg);
    end;

    local procedure GetSourceForServiceOrGoods(var TempVATEntryCalculatedNonExempt: Record "VAT Entry" temporary; var ExemptionCausePresent: array[10] of Boolean; var ExemptionBaseAmounts: array[10] of Decimal; var NonExemptTransactionType: Option S1,S2,S3,Initial; var ExemptExists: Boolean; CustLedgerEntry: Record "Cust. Ledger Entry"; IsService: Boolean; DomesticCustomer: Boolean)
    var
        VATEntry: Record "VAT Entry";
        DataTypeManagement: Codeunit "Data Type Management";
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
        RecRef: RecordRef;
        ExemptionCode: Enum "SII Exemption Code";
    begin
        DataTypeManagement.GetRecordRef(CustLedgerEntry, RecRef);
        SIIManagement.FindVatEntriesFromLedger(RecRef, VATEntry);
        if not DomesticCustomer then
            VATEntry.SetRange("EU Service", IsService);
        VATEntry.SetRange("Ignore In SII", false);
        if VATEntry.FindSet() then begin
            if SIIInitialDocUpload.DateWithinInitialUploadPeriod(CustLedgerEntry."Posting Date") then
                NonExemptTransactionType := NonExemptTransactionType::S1
            else
                NonExemptTransactionType := NonExemptTransactionType::Initial;
            repeat
                BuildVATEntrySource(
                  ExemptExists, ExemptionCausePresent, ExemptionCode, ExemptionBaseAmounts,
                  TempVATEntryCalculatedNonExempt, NonExemptTransactionType, VATEntry, CustLedgerEntry."Posting Date", true);
            until VATEntry.Next() = 0;
        end;
    end;

    local procedure GenerateNodeForServicesOrGoodsDomesticCustomer(var TempGoodsVATEntryCalcNonExempt: Record "VAT Entry" temporary; var TempServVATEntryCalcNonExempt: Record "VAT Entry" temporary; var XMLNode: DotNet XmlNode; var DesgloseFacturaXMLNode: DotNet XmlNode; var DomesticXMLNode: DotNet XmlNode; var DesgloseTipoOperacionXMLNode: DotNet XmlNode; var EUServiceXMLNode: DotNet XmlNode; var NonEUServiceXMLNode: DotNet XmlNode; ExemptionCausePresent: array[2, 10] of Boolean; ExemptionBaseAmounts: array[2, 10] of Decimal; NonExemptTransactionType: array[2] of Option S1,S2,S3,Initial; ExemptExists: array[2] of Boolean; CustLedgerEntry: Record "Cust. Ledger Entry"; DomesticCustomer: Boolean; RegimeCodes: array[3] of Code[2])
    begin
        GenerateNodeForServicesOrGoods(
          TempGoodsVATEntryCalcNonExempt, XMLNode, DesgloseFacturaXMLNode, DomesticXMLNode, DesgloseTipoOperacionXMLNode,
          EUServiceXMLNode, NonEUServiceXMLNode, ExemptionCausePresent[2], ExemptionBaseAmounts[2],
          NonExemptTransactionType[2], ExemptExists[2], CustLedgerEntry, false, DomesticCustomer, RegimeCodes);
        GenerateNodeForServicesOrGoods(
          TempServVATEntryCalcNonExempt, XMLNode, DesgloseFacturaXMLNode, DomesticXMLNode, DesgloseTipoOperacionXMLNode,
          EUServiceXMLNode, NonEUServiceXMLNode, ExemptionCausePresent[1], ExemptionBaseAmounts[1],
          NonExemptTransactionType[1], ExemptExists[1], CustLedgerEntry, true, DomesticCustomer, RegimeCodes);
    end;

    local procedure GenerateNodeForServicesOrGoodsForeignCustomer(var TempGoodsVATEntryCalcNonExempt: Record "VAT Entry" temporary; var TempServVATEntryCalcNonExempt: Record "VAT Entry" temporary; var XMLNode: DotNet XmlNode; var DesgloseFacturaXMLNode: DotNet XmlNode; var DomesticXMLNode: DotNet XmlNode; var DesgloseTipoOperacionXMLNode: DotNet XmlNode; var EUServiceXMLNode: DotNet XmlNode; var NonEUServiceXMLNode: DotNet XmlNode; ExemptionCausePresent: array[2, 10] of Boolean; ExemptionBaseAmounts: array[2, 10] of Decimal; NonExemptTransactionType: array[2] of Option S1,S2,S3,Initial; ExemptExists: array[2] of Boolean; CustLedgerEntry: Record "Cust. Ledger Entry"; DomesticCustomer: Boolean; RegimeCodes: array[3] of Code[2])
    begin
        GenerateNodeForServicesOrGoods(
          TempServVATEntryCalcNonExempt, XMLNode, DesgloseFacturaXMLNode, DomesticXMLNode, DesgloseTipoOperacionXMLNode,
          EUServiceXMLNode, NonEUServiceXMLNode, ExemptionCausePresent[1], ExemptionBaseAmounts[1],
          NonExemptTransactionType[1], ExemptExists[1], CustLedgerEntry, true, DomesticCustomer, RegimeCodes);
        GenerateNodeForServicesOrGoods(
          TempGoodsVATEntryCalcNonExempt, XMLNode, DesgloseFacturaXMLNode, DomesticXMLNode, DesgloseTipoOperacionXMLNode,
          EUServiceXMLNode, NonEUServiceXMLNode, ExemptionCausePresent[2], ExemptionBaseAmounts[2],
          NonExemptTransactionType[2], ExemptExists[2], CustLedgerEntry, false, DomesticCustomer, RegimeCodes);
    end;

    local procedure GenerateNodeForServicesOrGoods(var TempVATEntryCalculatedNonExempt: Record "VAT Entry" temporary; var TipoDesgloseXMLNode: DotNet XmlNode; var DesgloseFacturaXMLNode: DotNet XmlNode; var DomesticXMLNode: DotNet XmlNode; var DesgloseTipoOperacionXMLNode: DotNet XmlNode; var EUServiceXMLNode: DotNet XmlNode; var NonEUServiceXMLNode: DotNet XmlNode; ExemptionCausePresent: array[10] of Boolean; ExemptionBaseAmounts: array[10] of Decimal; NonExemptTransactionType: Option S1,S2,S3,Initial; ExemptExists: Boolean; CustLedgerEntry: Record "Cust. Ledger Entry"; IsService: Boolean; DomesticCustomer: Boolean; RegimeCodes: array[3] of Code[2])
    var
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
        TempXmlNode: DotNet XmlNode;
        BaseNode: DotNet XmlNode;
        VATXMLNode: DotNet XmlNode;
        EUXMLNode: DotNet XmlNode;
        NonTaxHandled: Boolean;
    begin
        BaseNode := TipoDesgloseXMLNode;

        if SIIInitialDocUpload.DateWithinInitialUploadPeriod(CustLedgerEntry."Posting Date") then begin
            MoveNonTaxableEntriesToTempVATEntryBuffer(TempVATEntryCalculatedNonExempt, CustLedgerEntry, IsService);
            NonTaxHandled := true;
        end;

        if ExemptExists then begin
            AddTipoDesgloseDetailHeader(
              TipoDesgloseXMLNode, DesgloseFacturaXMLNode, DomesticXMLNode, DesgloseTipoOperacionXMLNode, EUXMLNode,
              VATXMLNode, IsService, DomesticCustomer, false);
            HandleExemptEntries(VATXMLNode, ExemptionCausePresent, ExemptionBaseAmounts);
        end;

        // Generating XML node for NonExempt part
        TempVATEntryCalculatedNonExempt.Reset();
        TempVATEntryCalculatedNonExempt.SetCurrentKey("VAT %", "EC %");
        TempVATEntryCalculatedNonExempt.SetRange("One Stop Shop Reporting", false);
        if TempVATEntryCalculatedNonExempt.FindSet() then begin
            AddTipoDesgloseDetailHeader(
              TipoDesgloseXMLNode, DesgloseFacturaXMLNode, DomesticXMLNode, DesgloseTipoOperacionXMLNode,
              EUXMLNode, VATXMLNode, IsService, DomesticCustomer, false);
            XMLDOMManagement.AddElementWithPrefix(VATXMLNode, 'NoExenta', '', 'sii', SiiTxt, VATXMLNode);
            XMLDOMManagement.AddElementWithPrefix(VATXMLNode, 'TipoNoExenta', Format(NonExemptTransactionType), 'sii', SiiTxt, TempXmlNode);
            XMLDOMManagement.AddElementWithPrefix(VATXMLNode, 'DesgloseIVA', '', 'sii', SiiTxt, VATXMLNode);
            repeat
                FillDetalleIVANode(
                  VATXMLNode, TempVATEntryCalculatedNonExempt, true, -1, not IsService, NonExemptTransactionType, RegimeCodes, 'CuotaRepercutida');
            until TempVATEntryCalculatedNonExempt.Next() = 0;
        end;
        TempVATEntryCalculatedNonExempt.SetRange("One Stop Shop Reporting");

        if not NonTaxHandled then begin
            Clear(DomesticXMLNode);
            Clear(EUServiceXMLNode);
            Clear(NonEUServiceXMLNode);
            HandleNonTaxableVATEntries(
              TempVATEntryCalculatedNonExempt, CustLedgerEntry,
              TipoDesgloseXMLNode, DesgloseFacturaXMLNode, DomesticXMLNode, DesgloseTipoOperacionXMLNode,
              EUXMLNode, IsService, DomesticCustomer, RegimeCodes);
            Clear(DomesticXMLNode);
        end;

        TipoDesgloseXMLNode := BaseNode;
    end;

    local procedure GenerateNodeForNonTaxableVAT(NonTaxableAmount: Decimal; var XMLNode: DotNet XmlNode; XMLNodeName: Text)
    var
        BaseNode: DotNet XmlNode;
    begin
        BaseNode := XMLNode;

        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, XMLNodeName, FormatNumber(NonTaxableAmount), 'sii', SiiTxt, XMLNode);

        XMLNode := BaseNode;
    end;

    local procedure FillNoTaxableVATEntriesPurch(var TempVATEntryCalculated: Record "VAT Entry" temporary; VendLedgEntry: Record "Vendor Ledger Entry")
    var
        NonTaxableAmount: Decimal;
    begin
        NonTaxableAmount := CalculateNonTaxableAmountVendor(VendLedgEntry);
        if NonTaxableAmount = 0 then
            exit;
        SIISetup.Get();
        if SIISetup."Do Not Export Negative Lines" then
            if ((VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Invoice) and (NonTaxableAmount < 0)) or
               ((VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::"Credit Memo") and (NonTaxableAmount > 0))
            then
                exit;

        TempVATEntryCalculated.Reset();
        if TempVATEntryCalculated.FindLast() then;

        TempVATEntryCalculated.Init();
        TempVATEntryCalculated."Entry No." += 1;
        TempVATEntryCalculated.Base := NonTaxableAmount;
        TempVATEntryCalculated.Type := TempVATEntryCalculated.Type::Purchase;
        // assign non-blank value to distinguish between the normal VAT entry from non-taxable one
        TempVATEntryCalculated."No Taxable Type" := TempVATEntryCalculated."No Taxable Type"::"Non Taxable Art 7-14 and others";
        TempVATEntryCalculated.Insert();
    end;

    local procedure GetExemptionCode(VATEntry: Record "VAT Entry"; var ExemptionCode: Enum "SII Exemption Code"): Boolean
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATClause: Record "VAT Clause";
    begin
        VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
        if VATPostingSetup."VAT Clause Code" <> '' then begin
            VATClause.Get(VATPostingSetup."VAT Clause Code");
            if VATClause."SII Exemption Code" = VATClause."SII Exemption Code"::" " then
                exit(false);
            ExemptionCode := VATClause."SII Exemption Code";
            exit(true);
        end
    end;

    local procedure CalculateExemptVATEntries(var ExemptionCausesPresent: array[10] of Boolean; var ExemptionBaseAmounts: array[10] of Decimal; TempVATEntry: Record "VAT Entry" temporary; ExemptionCode: Enum "SII Exemption Code")
    begin
        // We have 7 exemption codes: first is empty, the remaining are E1-E6.;
        // Options enumerated from 0, arrays - from 1.
        // We do not process "empty" exemption code here, thus no index modifications required.
        if ExemptionCausesPresent[ExemptionCode.AsInteger()] then
            ExemptionBaseAmounts[ExemptionCode.AsInteger()] += TempVATEntry.Base
        else begin
            ExemptionCausesPresent[ExemptionCode.AsInteger()] := true;
            ExemptionBaseAmounts[ExemptionCode.AsInteger()] := TempVATEntry.Base;
        end;
    end;

    local procedure CalculatePurchVATEntries(var TempVATEntryNormalCalculated: Record "VAT Entry" temporary; var TempVATEntryReverseChargeCalculated: Record "VAT Entry" temporary; var CuotaDeducibleValue: Decimal; VATEntry: Record "VAT Entry"; VendorNo: Code[20]; PostingDate: Date; InvoiceType: Text)
    var
        VATAmount: Decimal;
    begin
        if VATEntry."Ignore In SII" then
            exit;
        VATAmount := VATEntry.Amount + VATEntry."Unrealized Amount";
        CuotaDeducibleValue += VATAmount;
        VATAmount += VATEntry."Non-Deductible VAT Amount";
        OnAfterCalculateCuotaDeducibleValue(CuotaDeducibleValue, VATAmount, VATEntry);

        if UseReverseChargeNotIntracommunity(VATEntry."VAT Calculation Type", VendorNo, PostingDate, InvoiceType) then
            CalculateNonExemptVATEntries(TempVATEntryReverseChargeCalculated, VATEntry, true, VATAmount)
        else
            CalculateNonExemptVATEntries(TempVATEntryNormalCalculated, VATEntry, true, VATAmount);
    end;

    local procedure BuildNonExemptTransactionType(VATEntry: Record "VAT Entry"; var TransactionType: Option S1,S2,S3,Initial)
    begin
        // "Reverse Charge VAT" means S2
        if VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Reverse Charge VAT" then begin
            if TransactionType = TransactionType::Initial then
                TransactionType := TransactionType::S2
            else
                if TransactionType = TransactionType::S1 then
                    TransactionType := TransactionType::S3;
        end else
            if TransactionType = TransactionType::Initial then
                TransactionType := TransactionType::S1
            else
                if TransactionType = TransactionType::S2 then
                    TransactionType := TransactionType::S3;
        OnAfterBuildNonExemptTransactionType(VATEntry, TransactionType);
    end;

    local procedure BuildExemptionCodeString(ExemptionIndex: Integer): Text
    begin
        case ExemptionIndex of
            1:
                exit('E1');
            2:
                exit('E2');
            3:
                exit('E3');
            4:
                exit('E4');
            5:
                exit('E5');
            6:
                exit('E6');
        end;
    end;

    local procedure HandleCorrectiveInvoiceSales(var XMLNode: DotNet XmlNode; SIIDocUploadState: Record "SII Doc. Upload State"; CustLedgerEntry: Record "Cust. Ledger Entry"; Customer: Record Customer): Boolean
    var
        OldCustLedgerEntry: Record "Cust. Ledger Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLNode: DotNet XmlNode;
        CustLedgerEntryRecRef: RecordRef;
        TotalBase: Decimal;
        TotalNonExemptBase: Decimal;
        TotalVATAmount: Decimal;
        TotalNDBase: Decimal;
        TotalNDAmount: Decimal;
        CorrectedInvoiceNo: Code[20];
        CorrectionType: Option;
    begin
        if CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::Invoice then begin
            GetCorrectionInfoFromDocument(
              true, CustLedgerEntry."Document No.", CorrectedInvoiceNo, CorrectionType,
              CustLedgerEntry."Correction Type", CustLedgerEntry."Corrected Invoice No.");
            if FindCustLedgerEntryOfRefDocument(CustLedgerEntry, OldCustLedgerEntry, CorrectedInvoiceNo) then
                if CorrectionType = SalesCrMemoHeader."Correction Type"::Removal then begin
                    InitializeCorrectiveRemovalXmlBody(
                      XMLNode, CustLedgerEntry."VAT Reporting Date", true, SIIDocUploadState,
                      Customer.Name, Customer."VAT Registration No.", Customer."Country/Region Code", Customer."No.", Customer."Not in AEAT");
                    exit(true);
                end;
        end;
        InitializeSalesXmlBody(XMLNode, CustLedgerEntry."VAT Reporting Date");

        // calculate totals for current doc
        DataTypeManagement.GetRecordRef(CustLedgerEntry, CustLedgerEntryRecRef);
        CalculateTotalVatAndBaseAmounts(CustLedgerEntryRecRef, TotalBase, TotalNonExemptBase, TotalVATAmount, TotalNDBase, TotalNDAmount);

        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'NumSerieFacturaEmisor', Format(CustLedgerEntry."Document No."), 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'FechaExpedicionFacturaEmisor', GetSalesExpeditionDate(CustLedgerEntry), 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'FacturaExpedida', '', 'siiLR', SiiLRTxt, XMLNode);
        XMLDOMManagement.AddElementWithPrefix(
            XMLNode, 'TipoFactura', GetInvCrMemoTypeFromCustLedgEntry(SIIDocUploadState, CustLedgerEntry),
             'sii', SiiTxt, TempXMLNode);
        if (CorrectionType = SalesCrMemoHeader."Correction Type"::Replacement) or
           (CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Invoice)
        then
            HandleReplacementSalesCorrectiveInvoice(
              XMLNode, SIIDocUploadState, OldCustLedgerEntry, CustLedgerEntry, Customer, TotalBase, TotalNonExemptBase, TotalVATAmount)
        else
            CorrectiveInvoiceSalesDifference(
              XMLNode, SIIDocUploadState, OldCustLedgerEntry, CustLedgerEntry, Customer, TotalBase, TotalNonExemptBase, TotalVATAmount);

        exit(true);
    end;

    local procedure CorrectiveInvoiceSalesDifference(var XMLNode: DotNet XmlNode; SIIDocUploadState: Record "SII Doc. Upload State"; OldCustLedgerEntry: Record "Cust. Ledger Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; Customer: Record Customer; TotalBase: Decimal; TotalNonExemptBase: Decimal; TotalVATAmount: Decimal)
    var
        TempVATEntryPerPercent: Record "VAT Entry" temporary;
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
        TempXMLNode: DotNet XmlNode;
        TipoDesgloseXMLNode: DotNet XmlNode;
        DesgloseFacturaXMLNode: DotNet XmlNode;
        DomesticXMLNode: DotNet XmlNode;
        DesgloseTipoOperacionXMLNode: DotNet XmlNode;
        EUServiceXMLNode: DotNet XmlNode;
        NonEUServiceXMLNode: DotNet XmlNode;
        EUXMLNode: DotNet XmlNode;
        VATXMLNode: DotNet XmlNode;
        TotalAmount: Decimal;
        EUService: Boolean;
        EntriesFound: Boolean;
        DomesticCustomer: Boolean;
        NonTaxHandled: Boolean;
        RegimeCodes: array[3] of Code[2];
        NonExemptTransactionType: Option S1,S2,S3,Initial;
        ExemptExists: Boolean;
        ExemptionCausePresent: array[10] of Boolean;
        ExemptionBaseAmounts: array[10] of Decimal;
        ValueRefExternal: Text;
    begin
        DomesticCustomer := SIIManagement.IsDomesticCustomer(Customer);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'TipoRectificativa', 'I', 'sii', SiiTxt, TempXMLNode);
        GenerateFacturasRectificadasNode(XMLNode, OldCustLedgerEntry."Document No.", OldCustLedgerEntry."Posting Date");
        GetClaveRegimenNodeSales(RegimeCodes, SIIDocUploadState, CustLedgerEntry, Customer);
        GenerateNodeForFechaOperacionSales(XMLNode, CustLedgerEntry, RegimeCodes);
        GenerateClaveRegimenNode(XMLNode, RegimeCodes);

        TotalAmount := -TotalBase - TotalVATAmount;
        if IncludeImporteTotalNode() then
            XMLDOMManagement.AddElementWithPrefix(XMLNode, 'ImporteTotal', FormatNumber(TotalAmount), 'sii', SiiTxt, TempXMLNode);
        FillBaseImponibleACosteNode(XMLNode, RegimeCodes, -TotalNonExemptBase);
        FillOperationDescription(
          XMLNode, GetOperationDescriptionFromDocument(true, CustLedgerEntry."Document No."),
          CustLedgerEntry."Posting Date", CustLedgerEntry.Description);
        ValueRefExternal := Format(SIIDocUploadState."Entry No");
        OnCorrectiveInvoiceSalesDifferenceOnBeforeFillRefExternaNode(SIIDocUploadState, ValueRefExternal);
        FillRefExternaNode(XMLNode, ValueRefExternal);
        FillSucceededCompanyInfo(XMLNode, SIIDocUploadState);
        FillMacrodatoNode(XMLNode, TotalAmount);

        if SIIDocUploadState."Issued By Third Party" then
            XMLDOMManagement.AddElementWithPrefix(XMLNode, 'EmitidaPorTercerosODestinatario', 'S', 'sii', SiiTxt, TempXMLNode);

        CorrectiveInvoiceSalesDifferenceOnBeforeContraparteNode(XMLNode, CustLedgerEntry);
        if IncludeContraparteNodeByCrMemoType(SIIDocUploadState."Sales Cr. Memo Type") then begin
            XMLDOMManagement.AddElementWithPrefix(XMLNode, 'Contraparte', '', 'sii', SiiTxt, XMLNode);
            FillThirdPartyId(
              XMLNode, Customer."Country/Region Code", Customer.Name, Customer."VAT Registration No.", Customer."No.", true,
              SIIManagement.CustomerIsIntraCommunity(Customer."No."), Customer."Not in AEAT", SIIDocUploadState.IDType, SIIDocUploadState);
        end;

        if SIIInitialDocUpload.DateWithinInitialUploadPeriod(CustLedgerEntry."Posting Date") then begin
            MoveNonTaxableEntriesToTempVATEntryBuffer(TempVATEntryPerPercent, CustLedgerEntry, false);
            NonTaxHandled := true;
        end;

        if DomesticCustomer then
            GetSourceForServiceOrGoods(
              TempVATEntryPerPercent, ExemptionCausePresent, ExemptionBaseAmounts,
              NonExemptTransactionType, ExemptExists, CustLedgerEntry, EUService, DomesticCustomer);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'TipoDesglose', '', 'sii', SiiTxt, TipoDesgloseXMLNode);
        for EUService := true downto false do begin
            if not DomesticCustomer then
                GetSourceForServiceOrGoods(
                  TempVATEntryPerPercent, ExemptionCausePresent, ExemptionBaseAmounts,
                  NonExemptTransactionType, ExemptExists, CustLedgerEntry, EUService, DomesticCustomer);
            TempVATEntryPerPercent.SetCurrentKey("VAT %", "EC %");
            if not DomesticCustomer then
                TempVATEntryPerPercent.SetRange("EU Service", EUService);
            TempVATEntryPerPercent.SetRange("One Stop Shop Reporting", false);
            EntriesFound := TempVATEntryPerPercent.FindSet();
            if not EntriesFound then
                TempVATEntryPerPercent.Init();
            if EntriesFound or ExemptExists then begin
                AddTipoDesgloseDetailHeader(
                  TipoDesgloseXMLNode, DesgloseFacturaXMLNode, DomesticXMLNode, DesgloseTipoOperacionXMLNode,
                  EUXMLNode, VATXMLNode, EUService, DomesticCustomer, false);
                if ExemptExists then begin
                    HandleExemptEntries(VATXMLNode, ExemptionCausePresent, ExemptionBaseAmounts);
                    ExemptExists := false;
                end;
                if EntriesFound then begin
                    XMLDOMManagement.AddElementWithPrefix(VATXMLNode, 'NoExenta', '', 'sii', SiiTxt, VATXMLNode);
                    XMLDOMManagement.AddElementWithPrefix(VATXMLNode, 'TipoNoExenta', Format(NonExemptTransactionType), 'sii', SiiTxt, TempXMLNode);
                    XMLDOMManagement.AddElementWithPrefix(VATXMLNode, 'DesgloseIVA', '', 'sii', SiiTxt, VATXMLNode);
                    repeat
                        FillDetalleIVANode(
                          VATXMLNode, TempVATEntryPerPercent, true, -1, true, NonExemptTransactionType, RegimeCodes, 'CuotaRepercutida');
                    until TempVATEntryPerPercent.Next() = 0;
                end;
            end;
            TempVATEntryPerPercent.SetRange("One Stop Shop Reporting");
            if not NonTaxHandled then begin
                Clear(DomesticXMLNode);
                Clear(EUServiceXMLNode);
                Clear(NonEUServiceXMLNode);
                HandleNonTaxableVATEntries(
                  TempVATEntryPerPercent, CustLedgerEntry,
                  TipoDesgloseXMLNode, DesgloseFacturaXMLNode, DomesticXMLNode, DesgloseTipoOperacionXMLNode,
                  EUXMLNode, EUService, DomesticCustomer, RegimeCodes);
                Clear(DomesticXMLNode);
            end;
            Clear(EUXMLNode);
            Clear(VATXMLNode);
            TempVATEntryPerPercent.DeleteAll();
        end;
    end;

    local procedure HandleCorrectiveInvoicePurchases(var XMLNode: DotNet XmlNode; SIIDocUploadState: Record "SII Doc. Upload State"; VendorLedgerEntry: Record "Vendor Ledger Entry"; Vendor: Record Vendor): Boolean
    var
        OldVendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VendorLedgerEntryRecRef: RecordRef;
        TotalBase: Decimal;
        TotalNonExemptBase: Decimal;
        TotalVATAmount: Decimal;
        TotalNDBase: Decimal;
        TotalNDAmount: Decimal;
        CorrectedInvoiceNo: Code[20];
        CorrectionType: Option;
        VendNo: Code[20];
    begin
        if VendorLedgerEntry."Document Type" <> VendorLedgerEntry."Document Type"::Invoice then begin
            GetCorrectionInfoFromDocument(
              false, VendorLedgerEntry."Document No.", CorrectedInvoiceNo, CorrectionType,
              VendorLedgerEntry."Correction Type", VendorLedgerEntry."Corrected Invoice No.");
            if FindVendorLedgerEntryOfRefDocument(VendorLedgerEntry, OldVendorLedgerEntry, CorrectedInvoiceNo) then
                if CorrectionType = PurchCrMemoHdr."Correction Type"::Removal then begin
                    InitializeCorrectiveRemovalXmlBody(XMLNode,
                      VendorLedgerEntry."VAT Reporting Date", false, SIIDocUploadState,
                      Vendor.Name, Vendor."VAT Registration No.", Vendor."Country/Region Code", Vendor."No.", false);
                    exit(true);
                end;
        end;
        VendNo := SIIManagement.GetVendFromLedgEntryByGLSetup(VendorLedgerEntry);
        InitializePurchXmlBody(XMLNode, VendNo, VendorLedgerEntry, SIIDocUploadState.IDType, SIIDocUploadState);

        // calculate totals for current doc
        DataTypeManagement.GetRecordRef(VendorLedgerEntry, VendorLedgerEntryRecRef);
        CalculateTotalVatAndBaseAmounts(VendorLedgerEntryRecRef, TotalBase, TotalNonExemptBase, TotalVATAmount, TotalNDBase, TotalNDAmount);

        if (CorrectionType = PurchCrMemoHdr."Correction Type"::Replacement) or
           (VendorLedgerEntry."Document Type" = VendorLedgerEntry."Document Type"::Invoice)
        then
            HandleReplacementPurchCorrectiveInvoice(
              XMLNode, Vendor, SIIDocUploadState, OldVendorLedgerEntry, VendorLedgerEntry, TotalBase, TotalNonExemptBase, TotalVATAmount)
        else
            HandleNormalPurchCorrectiveInvoice(
              XMLNode, Vendor, SIIDocUploadState, OldVendorLedgerEntry, VendorLedgerEntry, TotalBase + TotalNDBase, TotalNonExemptBase, TotalVATAmount + TotalNDAmount);
        exit(true);
    end;

    local procedure HandleReplacementPurchCorrectiveInvoice(var XMLNode: DotNet XmlNode; Vendor: Record Vendor; SIIDocUploadState: Record "SII Doc. Upload State"; OldVendorLedgerEntry: Record "Vendor Ledger Entry"; VendorLedgerEntry: Record "Vendor Ledger Entry"; TotalBase: Decimal; TotalNonExemptBase: Decimal; TotalVATAmount: Decimal)
    var
        TempVATEntryPerPercent: Record "VAT Entry" temporary;
        TempOldVATEntryPerPercent: Record "VAT Entry" temporary;
        TempXMLNode: DotNet XmlNode;
        OldVendorLedgerEntryRecRef: RecordRef;
        OldTotalBase: Decimal;
        OldTotalNonExemptBase: Decimal;
        OldTotalVATAmount: Decimal;
        BaseAmountDiff: Decimal;
        VATAmountDiff: Decimal;
        ECPercentDiff: Decimal;
        ECAmountDiff: Decimal;
        CuotaDeducibleDecValue: Decimal;
        TotalAmount: Decimal;
        TotalNDBase: Decimal;
        TotalNDAmount: Decimal;
        RegimeCodes: array[3] of Code[2];
        ECVATEntryExists: Boolean;
        InvoiceType: Text;
        ValueRefExternal: Text;
    begin
        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'NumSerieFacturaEmisor', Format(VendorLedgerEntry."External Document No."), 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'FechaExpedicionFacturaEmisor', FormatDate(VendorLedgerEntry."Document Date"), 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode); // exit ID factura node

        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'FacturaRecibida', '', 'siiLR', SiiLRTxt, XMLNode);

        UpdatePurchCrMemoTypeFromCorrInvType(SIIDocUploadState);
        if SIIDocUploadState."Purch. Cr. Memo Type" = SIIDocUploadState."Purch. Cr. Memo Type"::" " then
            XMLDOMManagement.AddElementWithPrefix(XMLNode, 'TipoFactura', 'R1', 'sii', SiiTxt, TempXMLNode)
        else
            XMLDOMManagement.AddElementWithPrefix(
              XMLNode, 'TipoFactura', CopyStr(Format(SIIDocUploadState."Purch. Cr. Memo Type"), 1, 2), 'sii', SiiTxt, TempXMLNode);

        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'TipoRectificativa', 'S', 'sii', SiiTxt, TempXMLNode);
        if VendorLedgerEntry."Document Type" <> VendorLedgerEntry."Document Type"::Invoice then begin
            GenerateFacturasRectificadasNode(XMLNode, OldVendorLedgerEntry."External Document No.", OldVendorLedgerEntry."Posting Date");
            // calculate totals for old doc
            DataTypeManagement.GetRecordRef(OldVendorLedgerEntry, OldVendorLedgerEntryRecRef);
            CalculateTotalVatAndBaseAmounts(OldVendorLedgerEntryRecRef, OldTotalBase, OldTotalNonExemptBase, OldTotalVATAmount, TotalNDBase, TotalNDAmount);
        end;

        // write totals amounts in XML
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'ImporteRectificacion', '', 'sii', SiiTxt, XMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'BaseRectificada', FormatNumber(Abs(OldTotalBase)), 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'CuotaRectificada', FormatNumber(Abs(OldTotalVATAmount)), 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);

        GetClaveRegimenNodePurchases(RegimeCodes, SIIDocUploadState, VendorLedgerEntry, Vendor);
        GenerateClaveRegimenNode(XMLNode, RegimeCodes);

        TotalAmount := OldTotalBase + OldTotalVATAmount + TotalBase + TotalVATAmount;
        if IncludeImporteTotalNode() then
            XMLDOMManagement.AddElementWithPrefix(
              XMLNode, 'ImporteTotal', FormatNumber(TotalAmount), 'sii', SiiTxt,
              TempXMLNode);
        FillBaseImponibleACosteNode(XMLNode, RegimeCodes, OldTotalNonExemptBase + TotalNonExemptBase);
        FillOperationDescription(
          XMLNode, GetOperationDescriptionFromDocument(false, VendorLedgerEntry."Document No."),
          VendorLedgerEntry."Posting Date", VendorLedgerEntry.Description);
        ValueRefExternal := Format(SIIDocUploadState."Entry No");
        OnHandleReplacementPurchCorrectiveInvoiceOnBeforeFillRefExternaNode(SIIDocUploadState, ValueRefExternal);
        FillRefExternaNode(XMLNode, ValueRefExternal);
        FillSucceededCompanyInfo(XMLNode, SIIDocUploadState);
        FillMacrodatoNode(XMLNode, TotalAmount);

        // calculate Credit memo differences grouped by VAT %
        FillNoTaxableVATEntriesPurch(TempVATEntryPerPercent, VendorLedgerEntry);
        CalcNonExemptVATEntriesWithCuotaDeducible(TempVATEntryPerPercent, CuotaDeducibleDecValue, VendorLedgerEntry, 1);
        CuotaDeducibleDecValue := Abs(CuotaDeducibleDecValue);

        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'DesgloseFactura', '', 'sii', SiiTxt, XMLNode);

        // calculate old and new VAT totals grouped by VAT %
        FillNoTaxableVATEntriesPurch(TempOldVATEntryPerPercent, OldVendorLedgerEntry);
        CalcNonExemptVATEntriesWithCuotaDeducible(TempOldVATEntryPerPercent, CuotaDeducibleDecValue, OldVendorLedgerEntry, -1);
        CuotaDeducibleDecValue := Abs(CuotaDeducibleDecValue);

        // loop over and fill diffs
        TempVATEntryPerPercent.Reset();
        TempVATEntryPerPercent.SetCurrentKey("VAT %", "EC %");
        if TempVATEntryPerPercent.FindSet() then begin
            XMLDOMManagement.AddElementWithPrefix(XMLNode, 'DesgloseIVA', '', 'sii', SiiTxt, XMLNode);
            repeat
                CalcTotalDiffAmounts(
                  BaseAmountDiff, VATAmountDiff, ECPercentDiff, ECAmountDiff, TempOldVATEntryPerPercent, TempVATEntryPerPercent);

                // fill XML
                OnHandleReplacementPurchCorrectiveInvoiceOnBeforeAddElementDetalleIVA(XMLNode, VendorLedgerEntry);
                XMLDOMManagement.AddElementWithPrefix(XMLNode, 'DetalleIVA', '', 'sii', SiiTxt, XMLNode);
                XMLDOMManagement.AddElementWithPrefix(
                  XMLNode, 'TipoImpositivo', FormatNumber(TempVATEntryPerPercent."VAT %"), 'sii', SiiTxt, TempXMLNode);
                XMLDOMManagement.AddElementWithPrefix(XMLNode, 'BaseImponible', FormatNumber(BaseAmountDiff), 'sii', SiiTxt, TempXMLNode);
                OnBeforeAddVATAmountPurchDiffElement(TempVATEntryPerPercent, VATAmountDiff);
                XMLDOMManagement.AddElementWithPrefix(XMLNode, 'CuotaSoportada', FormatNumber(VATAmountDiff), 'sii', SiiTxt, TempXMLNode);

                GenerateRecargoEquivalenciaNodes(XMLNode, ECPercentDiff, ECAmountDiff);

                OnHandleReplacementPurchCorrectiveInvoiceOnAfterGenerateRecargoEquivalenciaNodes(XMLNode, TempVATEntryPerPercent);

                XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);
                ECVATEntryExists := ECVATEntryExists or (ECPercentDiff <> 0);
            until TempVATEntryPerPercent.Next() = 0;
            XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);
        end;
        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);

        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'Contraparte', '', 'sii', SiiTxt, XMLNode);
        FillThirdPartyId(
          XMLNode, Vendor."Country/Region Code", Vendor.Name, Vendor."VAT Registration No.", Vendor."No.", true,
          SIIManagement.VendorIsIntraCommunity(Vendor."No."), false, SIIDocUploadState.IDType, SIIDocUploadState);
        FillFechaRegContable(XMLNode, VendorLedgerEntry."Posting Date", GetRequestDateOfSIIHistoryByVendLedgEntry(VendorLedgerEntry));
        OnHandleReplacementPurchCorrectiveInvoiceOnBeforeAddCuotaDeducibleElement(VendorLedgerEntry, CuotaDeducibleDecValue, BaseAmountDiff);
        if CuotaDeducibleDecValue = 0 then
            XMLDOMManagement.AddElementWithPrefix(XMLNode, 'CuotaDeducible', FormatNumber(0), 'sii', SiiTxt, TempXMLNode)
        else begin
            IsPurchInvoice(InvoiceType, SIIDocUploadState);
            CuotaDeducibleDecValue :=
              CalcCuotaDeducible(
                VendorLedgerEntry."Posting Date", RegimeCodes, SIIDocUploadState.IDType,
                ECVATEntryExists, InvoiceType, true, CuotaDeducibleDecValue);
            XMLDOMManagement.AddElementWithPrefix(
              XMLNode, 'CuotaDeducible', FormatNumber(CuotaDeducibleDecValue), 'sii', SiiTxt, TempXMLNode);

            OnHandleReplacementPurchCorrectiveInvoiceOnAfterCuotaDeducible(XMLNode, VendorLedgerEntry);
        end;
    end;

    local procedure HandleNormalPurchCorrectiveInvoice(var XMLNode: DotNet XmlNode; Vendor: Record Vendor; SIIDocUploadState: Record "SII Doc. Upload State"; OldVendorLedgerEntry: Record "Vendor Ledger Entry"; VendorLedgerEntry: Record "Vendor Ledger Entry"; TotalBase: Decimal; TotalNonExemptBase: Decimal; TotalVATAmount: Decimal)
    var
        TempVATEntryNormalCalculated: Record "VAT Entry" temporary;
        TempVATEntryReverseChargeCalculated: Record "VAT Entry" temporary;
        VATEntry: Record "VAT Entry";
        TempXMLNode: DotNet XmlNode;
        VendorLedgerEntryRecRef: RecordRef;
        VATEntriesFound: Boolean;
        ECVATEntryExists: Boolean;
        CuotaDeducibleDecValue: Decimal;
        TotalAmount: Decimal;
        RegimeCodes: array[3] of Code[2];
        VendNo: Code[20];
        InvoiceType: Text;
        ValueRefExternal: Text;
    begin
        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'NumSerieFacturaEmisor', Format(VendorLedgerEntry."External Document No."), 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'FechaExpedicionFacturaEmisor', FormatDate(VendorLedgerEntry."Document Date"), 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode); // exit ID factura node

        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'FacturaRecibida', '', 'siiLR', SiiLRTxt, XMLNode);
        if SIIDocUploadState."Purch. Cr. Memo Type" = SIIDocUploadState."Purch. Cr. Memo Type"::" " then
            XMLDOMManagement.AddElementWithPrefix(XMLNode, 'TipoFactura', 'R1', 'sii', SiiTxt, TempXMLNode)
        else
            XMLDOMManagement.AddElementWithPrefix(
              XMLNode, 'TipoFactura', CopyStr(Format(SIIDocUploadState."Purch. Cr. Memo Type"), 1, 2), 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'TipoRectificativa', 'I', 'sii', SiiTxt, TempXMLNode);
        GenerateFacturasRectificadasNode(XMLNode, OldVendorLedgerEntry."External Document No.", OldVendorLedgerEntry."Posting Date");
        SIIDocUploadState.GetSIIDocUploadStateByVendLedgEntry(VendorLedgerEntry);
        GetClaveRegimenNodePurchases(RegimeCodes, SIIDocUploadState, VendorLedgerEntry, Vendor);
        GenerateClaveRegimenNode(XMLNode, RegimeCodes);
        VendNo := SIIManagement.GetVendFromLedgEntryByGLSetup(VendorLedgerEntry);

        if not TempVATEntryNormalCalculated.IsEmpty() then
            TotalBase -= Abs(TempVATEntryNormalCalculated.Base);
        TotalAmount := TotalBase + TotalVATAmount;
        FillNoTaxableVATEntriesPurch(TempVATEntryNormalCalculated, VendorLedgerEntry);
        if IncludeImporteTotalNode() then
            XMLDOMManagement.AddElementWithPrefix(
              XMLNode, 'ImporteTotal', FormatNumber(TotalAmount), 'sii', SiiTxt, TempXMLNode);
        FillBaseImponibleACosteNode(XMLNode, RegimeCodes, TotalNonExemptBase);
        FillOperationDescription(
          XMLNode, GetOperationDescriptionFromDocument(false, VendorLedgerEntry."Document No."),
          VendorLedgerEntry."Posting Date", VendorLedgerEntry.Description);
        ValueRefExternal := Format(SIIDocUploadState."Entry No");
        OnHandleNormalPurchCorrectiveInvoiceOnBeforeFillRefExternaNode(SIIDocUploadState, ValueRefExternal);
        FillRefExternaNode(XMLNode, ValueRefExternal);
        FillSucceededCompanyInfo(XMLNode, SIIDocUploadState);
        FillMacrodatoNode(XMLNode, TotalAmount);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'DesgloseFactura', '', 'sii', SiiTxt, XMLNode);

        DataTypeManagement.GetRecordRef(VendorLedgerEntry, VendorLedgerEntryRecRef);
        VATEntriesFound := SIIManagement.FindVatEntriesFromLedger(VendorLedgerEntryRecRef, VATEntry);
        if VATEntriesFound or not TempVATEntryNormalCalculated.IsEmpty
        then begin
            if VATEntriesFound then
                repeat
                    CalculatePurchVATEntries(
                      TempVATEntryNormalCalculated, TempVATEntryReverseChargeCalculated, CuotaDeducibleDecValue,
                      VATEntry, VendNo, VendorLedgerEntry."Posting Date", InvoiceType);
                    ECVATEntryExists := ECVATEntryExists or (VATEntry."EC %" <> 0);
                until VATEntry.Next() = 0;
            AddPurchVATEntriesWithElement(
              XMLNode, TempVATEntryReverseChargeCalculated, 'InversionSujetoPasivo', RegimeCodes);
            AddPurchVATEntriesWithElement(
              XMLNode, TempVATEntryNormalCalculated, 'DesgloseIVA', RegimeCodes);
            XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);
            IsPurchInvoice(InvoiceType, SIIDocUploadState);
            AddPurchTail(
              XMLNode, VendorLedgerEntry."Posting Date", GetRequestDateOfSIIHistoryByVendLedgEntry(VendorLedgerEntry),
              VendNo, CuotaDeducibleDecValue, SIIDocUploadState.IDType, RegimeCodes, ECVATEntryExists, InvoiceType,
              not TempVATEntryReverseChargeCalculated.IsEmpty(), SIIDocUploadState);
        end;
        XMLDOMManagement.FindNode(XMLNode, '../..', XMLNode);
    end;

    local procedure HandleReplacementSalesCorrectiveInvoice(var XMLNode: DotNet XmlNode; SIIDocUploadState: Record "SII Doc. Upload State"; OldCustLedgerEntry: Record "Cust. Ledger Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; Customer: Record Customer; TotalBase: Decimal; TotalNonExemptBase: Decimal; TotalVATAmount: Decimal)
    var
        TempOldVATEntryPerPercent: Record "VAT Entry" temporary;
        OldVATEntry: Record "VAT Entry";
        NewVATEntry: Record "VAT Entry";
        TempVATEntryPerPercent: Record "VAT Entry" temporary;
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
        TempXMLNode: DotNet XmlNode;
        TipoDesgloseXMLNode: DotNet XmlNode;
        DesgloseFacturaXMLNode: DotNet XmlNode;
        DomesticXMLNode: DotNet XmlNode;
        DesgloseTipoOperacionXMLNode: DotNet XmlNode;
        EUXMLNode: DotNet XmlNode;
        VATXMLNode: DotNet XmlNode;
        OldCustLedgerEntryRecRef: RecordRef;
        CustLedgerEntryRecRef: RecordRef;
        RegimeCodes: array[3] of Code[2];
        ExemptionCode: Enum "SII Exemption Code";
        OldTotalBase: Decimal;
        OldTotalNonExemptBase: Decimal;
        OldTotalVATAmount: Decimal;
        TotalAmount: Decimal;
        BaseAmountDiff: Decimal;
        VATAmountDiff: Decimal;
        ECPercentDiff: Decimal;
        ECAmountDiff: Decimal;
        TotalNDBase: Decimal;
        TotalNDAmount: Decimal;
        DomesticCustomer: Boolean;
        NormalVATEntriesFound: Boolean;
        i: Integer;
        NonExemptTransactionType: Option S1,S2,S3,Initial;
        ExemptExists: Boolean;
        ExemptionCausePresent: array[10] of Boolean;
        ExemptionBaseAmounts: array[10] of Decimal;
        ValueRefExternal: Text;
    begin
        DomesticCustomer := SIIManagement.IsDomesticCustomer(Customer);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'TipoRectificativa', 'S', 'sii', SiiTxt, TempXMLNode);
        if CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::Invoice then begin
            GenerateFacturasRectificadasNode(XMLNode, OldCustLedgerEntry."Document No.", OldCustLedgerEntry."Posting Date");
            // calculate totals for old doc
            DataTypeManagement.GetRecordRef(OldCustLedgerEntry, OldCustLedgerEntryRecRef);
            CalculateTotalVatAndBaseAmounts(OldCustLedgerEntryRecRef, OldTotalBase, OldTotalNonExemptBase, OldTotalVATAmount, TotalNDBase, TotalNDAmount);
        end;

        // write totals amounts in XML
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'ImporteRectificacion', '', 'sii', SiiTxt, XMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'BaseRectificada', FormatNumber(Abs(OldTotalBase)), 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'CuotaRectificada', FormatNumber(Abs(OldTotalVATAmount)), 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);

        GetClaveRegimenNodeSales(RegimeCodes, SIIDocUploadState, CustLedgerEntry, Customer);
        GenerateClaveRegimenNode(XMLNode, RegimeCodes);

        TotalAmount := Abs(OldTotalBase + OldTotalVATAmount) - Abs(TotalBase + TotalVATAmount);
        if CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Invoice then
            if not (CopyStr(Format(SIIDocUploadState."Sales Invoice Type"), 1, 2) in ['R1', 'R2', 'R3', 'R4', 'R5']) then
                TotalAmount := -TotalAmount;

        if IncludeImporteTotalNode() then
            XMLDOMManagement.AddElementWithPrefix(
              XMLNode, 'ImporteTotal', FormatNumber(TotalAmount), 'sii', SiiTxt,
              TempXMLNode);

        FillBaseImponibleACosteNode(XMLNode, RegimeCodes, Abs(OldTotalNonExemptBase) - Abs(TotalNonExemptBase));
        FillOperationDescription(
          XMLNode, GetOperationDescriptionFromDocument(true, CustLedgerEntry."Document No."),
          CustLedgerEntry."Posting Date", CustLedgerEntry.Description);
        ValueRefExternal := Format(SIIDocUploadState."Entry No");
        OnHandleReplacementSalesCorrectiveInvoiceOnBeforeFillRefExternaNode(SIIDocUploadState, ValueRefExternal);
        FillRefExternaNode(XMLNode, ValueRefExternal);
        FillSucceededCompanyInfo(XMLNode, SIIDocUploadState);
        FillMacrodatoNode(XMLNode, TotalAmount);
        UpdateSalesCrMemoTypeFromCorrInvType(SIIDocUploadState);

        if SIIDocUploadState."Issued By Third Party" then
            XMLDOMManagement.AddElementWithPrefix(XMLNode, 'EmitidaPorTercerosODestinatario', 'S', 'sii', SiiTxt, TempXMLNode);

        HandleReplacementSalesCorrectiveInvoiceOnBeforeContraparteNode(XMLNode, CustLedgerEntry);
        if IncludeContraparteNodeByCrMemoType(SIIDocUploadState."Sales Cr. Memo Type") then begin
            XMLDOMManagement.AddElementWithPrefix(XMLNode, 'Contraparte', '', 'sii', SiiTxt, XMLNode);
            FillThirdPartyId(
              XMLNode, Customer."Country/Region Code", Customer.Name, Customer."VAT Registration No.", Customer."No.", true,
              SIIManagement.CustomerIsIntraCommunity(Customer."No."), Customer."Not in AEAT", SIIDocUploadState.IDType, SIIDocUploadState);
        end;

        DataTypeManagement.GetRecordRef(CustLedgerEntry, CustLedgerEntryRecRef);
        if SIIInitialDocUpload.DateWithinInitialUploadPeriod(CustLedgerEntry."Posting Date") then
            NonExemptTransactionType := NonExemptTransactionType::S1
        else
            NonExemptTransactionType := NonExemptTransactionType::Initial;
        if SIIManagement.FindVatEntriesFromLedger(CustLedgerEntryRecRef, NewVATEntry) then
            repeat
                BuildVATEntrySource(
                    ExemptExists, ExemptionCausePresent, ExemptionCode, ExemptionBaseAmounts,
                    TempVATEntryPerPercent, NonExemptTransactionType, NewVATEntry, CustLedgerEntry."Posting Date", not DomesticCustomer);
            until NewVATEntry.Next() = 0;

        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'TipoDesglose', '', 'sii', SiiTxt, XMLNode);
        TipoDesgloseXMLNode := XMLNode;
        TempVATEntryPerPercent.Reset();
        TempVATEntryPerPercent.SetCurrentKey("VAT %", "EC %");
        TempVATEntryPerPercent.SetRange("One Stop Shop Reporting", false);
        NormalVATEntriesFound := TempVATEntryPerPercent.FindSet();
        if NormalVATEntriesFound or ExemptExists then
            AddTipoDesgloseDetailHeader(
              TipoDesgloseXMLNode, DesgloseFacturaXMLNode, DomesticXMLNode, DesgloseTipoOperacionXMLNode,
              EUXMLNode, VATXMLNode, false, DomesticCustomer, false);

        if ExemptExists then begin
            for i := 1 to ArrayLen(ExemptionBaseAmounts) do
                ExemptionBaseAmounts[i] := -ExemptionBaseAmounts[i]; // reverse sign for replacement credit memo
            HandleExemptEntries(VATXMLNode, ExemptionCausePresent, ExemptionBaseAmounts);
        end;

        // calculate old VAT totals grouped by VAT %
        DataTypeManagement.GetRecordRef(OldCustLedgerEntry, OldCustLedgerEntryRecRef);
        if SIIManagement.FindVatEntriesFromLedger(OldCustLedgerEntryRecRef, OldVATEntry) then
            repeat
                if not GetExemptionCode(OldVATEntry, ExemptionCode) then
                    CalculateNonExemptVATEntries(TempOldVATEntryPerPercent, OldVATEntry, true, CalcVATAmountExclEC(OldVATEntry));
            until OldVATEntry.Next() = 0;

        // loop over and fill diffs
        if NormalVATEntriesFound then begin
            XMLDOMManagement.AddElementWithPrefix(VATXMLNode, 'NoExenta', '', 'sii', SiiTxt, VATXMLNode);
            XMLDOMManagement.AddElementWithPrefix(VATXMLNode, 'TipoNoExenta', Format(NonExemptTransactionType), 'sii', SiiTxt, TempXMLNode);
            XMLDOMManagement.AddElementWithPrefix(VATXMLNode, 'DesgloseIVA', '', 'sii', SiiTxt, VATXMLNode);
            repeat
                CalcTotalDiffAmounts(
                  BaseAmountDiff, VATAmountDiff, ECPercentDiff, ECAmountDiff, TempOldVATEntryPerPercent, TempVATEntryPerPercent);

                XMLDOMManagement.AddElementWithPrefix(VATXMLNode, 'DetalleIVA', '', 'sii', SiiTxt, VATXMLNode);
                XMLDOMManagement.AddElementWithPrefix(
                  VATXMLNode, 'TipoImpositivo',
                  FormatNumber(CalcTipoImpositivo(NonExemptTransactionType, RegimeCodes, BaseAmountDiff, TempVATEntryPerPercent."VAT %")),
                  'sii', SiiTxt, TempXMLNode);
                XMLDOMManagement.AddElementWithPrefix(
                  VATXMLNode, 'BaseImponible', FormatNumber(Abs(BaseAmountDiff)), 'sii', SiiTxt, TempXMLNode);

                XMLDOMManagement.AddElementWithPrefix(
                  VATXMLNode, 'CuotaRepercutida', FormatNumber(Abs(VATAmountDiff) - Abs(ECAmountDiff)), 'sii', SiiTxt, TempXMLNode);

                GenerateRecargoEquivalenciaNodes(VATXMLNode, ECPercentDiff, ECAmountDiff);
                XMLDOMManagement.FindNode(VATXMLNode, '..', VATXMLNode);
            until TempVATEntryPerPercent.Next() = 0;
        end;
        TempVATEntryPerPercent.SetRange("One Stop Shop Reporting");

        HandleReplacementNonTaxableVATEntries(
          TempVATEntryPerPercent, CustLedgerEntry, OldCustLedgerEntry,
          TipoDesgloseXMLNode, DesgloseFacturaXMLNode, DomesticXMLNode, DesgloseTipoOperacionXMLNode,
          EUXMLNode, false, DomesticCustomer, RegimeCodes);
    end;

    local procedure CalculateTotalVatAndBaseAmounts(LedgerEntryRecRef: RecordRef; var TotalBaseAmount: Decimal; var TotalNonExemptVATBaseAmount: Decimal; var TotalVATAmount: Decimal; var TotalNDBase: Decimal; var TotalNDAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
        NoTaxableEntry: Record "No Taxable Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateTotalVatAndBaseAmounts(LedgerEntryRecRef, TotalBaseAmount, TotalNonExemptVATBaseAmount, TotalVATAmount, IsHandled);
        if IsHandled then
            exit;

        TotalBaseAmount := 0;
        TotalVATAmount := 0;
        TotalNDBase := 0;
        TotalNDAmount := 0;

        if SIIManagement.FindVatEntriesFromLedger(LedgerEntryRecRef, VATEntry) then
            repeat
                OnCalculateTotalVatAndBaseAmountsOnBeforeAssignTotalBaseAmount(LedgerEntryRecRef, VATEntry);
                TotalBaseAmount += VATEntry.Base + VATEntry."Unrealized Base";
                if VATEntry."VAT %" <> 0 then
                    TotalNonExemptVATBaseAmount += VATEntry.Base + VATEntry."Unrealized Base";
                if VATEntry."VAT Calculation Type" <> VATEntry."VAT Calculation Type"::"Reverse Charge VAT" then
                    TotalVATAmount += VATEntry.Amount + VATEntry."Unrealized Amount";
                TotalNDBase += VATEntry."Non-Deductible VAT Base";
                TotalNDAmount += VATEntry."Non-Deductible VAT Amount";
            until VATEntry.Next() = 0;

        SIIManagement.FindNoTaxableEntriesFromLedger(LedgerEntryRecRef, NoTaxableEntry);
        NoTaxableEntry.CalcSums(NoTaxableEntry."Base (LCY)");
        TotalBaseAmount += NoTaxableEntry."Base (LCY)";
    end;

    local procedure GenerateFacturasRectificadasNode(var XMLNode: DotNet XmlNode; DocNo: Code[35]; PostingDate: Date)
    var
        TempXMLNode: DotNet XmlNode;
    begin
        if DocNo = '' then
            exit;

        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'FacturasRectificadas', '', 'sii', SiiTxt, XMLNode);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'IDFacturaRectificada', '', 'sii', SiiTxt, XMLNode);
        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'NumSerieFacturaEmisor', DocNo, 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'FechaExpedicionFacturaEmisor', FormatDate(PostingDate), 'sii', SiiTxt, TempXMLNode);
        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);
        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);
    end;

    local procedure GetClaveRegimenNodeSales(var RegimeCodes: array[3] of Code[2]; SIIDocUploadState: Record "SII Doc. Upload State"; CustLedgerEntry: Record "Cust. Ledger Entry"; Customer: Record Customer)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
        CustLedgerEntryRecRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetClaveRegimenNodeSales(SIIDocUploadState, CustLedgerEntry, Customer, RegimeCodes[1], IsHandled);
        if IsHandled then
            exit;

        GeneralLedgerSetup.Get();
        if SIIInitialDocUpload.DateWithinInitialUploadPeriod(CustLedgerEntry."Posting Date") then begin
            RegimeCodes[1] := '16';
            exit;
        end;
        DataTypeManagement.GetRecordRef(CustLedgerEntry, CustLedgerEntryRecRef);
        if (SIIManagement.IsLedgerCashFlowBased(CustLedgerEntryRecRef)) and (GeneralLedgerSetup."VAT Cash Regime") then begin
            RegimeCodes[1] := '07';
            exit;
        end;
        if SIIDocUploadState."Sales Special Scheme Code" <> "SII Sales Upload Scheme Code"::" " then begin
            SIIDocUploadState.GetSpecialSchemeCodes(RegimeCodes);
            exit;
        end;
        if SIIManagement.CountryIsLocal(Customer."Country/Region Code") then begin
            RegimeCodes[1] := '01';
            exit;
        end;
        RegimeCodes[1] := '02';
    end;

    local procedure GetClaveRegimenNodePurchases(var RegimeCodes: array[3] of Code[2]; SIIDocUploadState: Record "SII Doc. Upload State"; VendorLedgerEntry: Record "Vendor Ledger Entry"; Vendor: Record Vendor)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetClaveRegimenNodePurchases(SIIDocUploadState, VendorLedgerEntry, Vendor, RegimeCodes[1], IsHandled);
        if IsHandled then
            exit;

        GeneralLedgerSetup.Get();
        if SIIInitialDocUpload.DateWithinInitialUploadPeriod(VendorLedgerEntry."Posting Date") then begin
            RegimeCodes[1] := '14';
            exit;
        end;
        if SIIDocUploadState."Purch. Special Scheme Code" <> "SII Purch. Upload Scheme Code"::" " then begin
            SIIDocUploadState.GetSpecialSchemeCodes(RegimeCodes);
            exit;
        end;
        if SIIManagement.VendorIsIntraCommunity(Vendor."No.") then begin
            RegimeCodes[1] := '09';
            exit;
        end;
        RegimeCodes[1] := '01';
    end;

    local procedure GenerateClaveRegimenNode(var XMLNode: DotNet XmlNode; RegimeCodes: array[3] of Code[2])
    var
        TempXMLNode: DotNet XmlNode;
        i: Integer;
    begin
        if RegimeCodes[1] <> '' then
            XMLDOMManagement.AddElementWithPrefix(XMLNode, 'ClaveRegimenEspecialOTrascendencia', RegimeCodes[1], 'sii', SiiTxt, TempXMLNode);
        for i := 2 to ArrayLen(RegimeCodes) do
            if RegimeCodes[i] <> '' then
                XMLDOMManagement.AddElementWithPrefix(
                  XMLNode, 'ClaveRegimenEspecialOTrascendenciaAdicional' + Format(i - 1), RegimeCodes[i], 'sii', SiiTxt, TempXMLNode);
    end;

    local procedure GenerateNodeForFechaOperacionSales(var XMLNode: DotNet XmlNode; CustLedgerEntry: Record "Cust. Ledger Entry"; RegimeCodes: array[3] of Code[2])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        ReturnReceiptLine: Record "Return Receipt Line";
        LastShipDate: Date;
        PostingDate: Date;
        DocDate: Date;
        VATDate: Date;
    begin
        GetSIISetup();
        case CustLedgerEntry."Document Type" of
            CustLedgerEntry."Document Type"::Invoice:
                if SalesInvoiceHeader.Get(CustLedgerEntry."Document No.") then begin
                    PostingDate := SalesInvoiceHeader."Posting Date";
                    DocDate := SalesInvoiceHeader."Document Date";
                    VATDate := SalesInvoiceHeader."VAT Reporting Date";
                    SalesInvoiceLine.SetRange("Document No.", CustLedgerEntry."Document No.");
                    SalesInvoiceLine.SetFilter(Quantity, '>%1', 0);
                    if SalesInvoiceLine.FindSet() then
                        repeat
                            if SalesInvoiceLine."Shipment No." = '' then begin
                                if SalesInvoiceLine."Shipment Date" <> 0D then
                                    if (SalesInvoiceLine."Shipment Date" > LastShipDate) and (Date2DMY(SalesInvoiceLine."Shipment Date", 3) = Date2DMY(PostingDate, 3))
                                    then
                                        LastShipDate := SalesInvoiceLine."Shipment Date";
                            end else
                                if SalesShipmentLine.Get(SalesInvoiceLine."Shipment No.", SalesInvoiceLine."Shipment Line No.") then
                                    if (SalesShipmentLine."Posting Date" > LastShipDate) and
                                       (Date2DMY(SalesShipmentLine."Posting Date", 3) = Date2DMY(PostingDate, 3))
                                    then
                                        LastShipDate := SalesShipmentLine."Posting Date";
                        until SalesInvoiceLine.Next() = 0;
                    OnGenerateNodeForFechaOperacionSalesOnBeforeFillFechaOperacion(LastShipDate, SalesInvoiceHeader);
                end else
                    if SIISetup."Operation Date" in [SIISetup."Operation Date"::"Document Date", SIISetup."Operation Date"::"VAT Reporting Date"] then begin
                        PostingDate := CustLedgerEntry."Posting Date";
                        DocDate := CustLedgerEntry."Document Date";
                        VATDate := CustLedgerEntry."VAT Reporting Date";
                    end;
            CustLedgerEntry."Document Type"::"Credit Memo":
                if SalesCrMemoHeader.Get(CustLedgerEntry."Document No.") then begin
                    PostingDate := SalesCrMemoHeader."Posting Date";
                    DocDate := SalesCrMemoHeader."Document Date";
                    VATDate := SalesCrMemoHeader."VAT Reporting Date";
                    SalesCrMemoLine.SetRange("Document No.", CustLedgerEntry."Document No.");
                    SalesCrMemoLine.SetFilter(Quantity, '>%1', 0);
                    if SalesCrMemoLine.FindSet() then
                        repeat
                            if SalesCrMemoLine."Return Receipt No." = '' then begin
                                if SalesCrMemoLine."Shipment Date" <> 0D then
                                    if (SalesCrMemoLine."Shipment Date" > LastShipDate) and (Date2DMY(SalesCrMemoLine."Shipment Date", 3) = Date2DMY(PostingDate, 3))
                                    then
                                        LastShipDate := SalesCrMemoLine."Shipment Date";
                            end else
                                if ReturnReceiptLine.Get(SalesCrMemoLine."Return Receipt No.", SalesCrMemoLine."Return Receipt Line No.") then
                                    if (ReturnReceiptLine."Posting Date" > LastShipDate) and
                                       (Date2DMY(ReturnReceiptLine."Posting Date", 3) = Date2DMY(PostingDate, 3))
                                    then
                                        LastShipDate := ReturnReceiptLine."Posting Date";
                        until SalesCrMemoLine.Next() = 0;
                    OnGenerateNodeForFechaOperacionSalesCrMemoHeaderOnBeforeFillFechaOperacion(LastShipDate, SalesCrMemoHeader);
                end else
                    if SIISetup."Operation Date" in [SIISetup."Operation Date"::"Document Date", SIISetup."Operation Date"::"VAT Reporting Date"] then begin
                        PostingDate := CustLedgerEntry."Posting Date";
                        DocDate := CustLedgerEntry."Document Date";
                        VATDate := CustLedgerEntry."VAT Reporting Date";
                    end;
        end;
        if PostingDate <> 0D then
            FillFechaOperacion(XMLNode, LastShipDate, PostingDate, DocDate, VATDate, true, RegimeCodes);
    end;

    local procedure GenerateNodeForFechaOperacionPurch(var XMLNode: DotNet XmlNode; VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        LastRcptDate: Date;
        PostingDate: Date;
        DocDate: Date;
        VATDate: Date;
        DummyRegimeCodes: array[3] of Code[2];
    begin
        if VendorLedgerEntry."Document Type" = VendorLedgerEntry."Document Type"::Invoice then begin
            if PurchInvHeader.Get(VendorLedgerEntry."Document No.") then begin
                PostingDate := PurchInvHeader."Posting Date";
                DocDate := PurchInvHeader."Document Date";
                VATDate := PurchInvHeader."VAT Reporting Date";
                PurchInvLine.SetRange("Document No.", VendorLedgerEntry."Document No.");
                if PurchInvLine.FindSet() then
                    repeat
                        if PurchInvLine."Receipt No." <> '' then
                            if PurchRcptLine.Get(PurchInvLine."Receipt No.", PurchInvLine."Receipt Line No.") then
                                if PurchRcptLine."Posting Date" > LastRcptDate then
                                    LastRcptDate := PurchRcptLine."Posting Date"
                    until PurchInvLine.Next() = 0;
            end else begin
                PostingDate := VendorLedgerEntry."Posting Date";
                DocDate := VendorLedgerEntry."Document Date";
                VATDate := VendorLedgerEntry."VAT Reporting Date";
            end;
            FillFechaOperacion(XMLNode, LastRcptDate, PostingDate, DocDate, VATDate, false, DummyRegimeCodes);
        end;
    end;

    local procedure GenerateRecargoEquivalenciaNodes(var XMLNode: DotNet XmlNode; ECPercent: Decimal; ECAmount: Decimal)
    var
        TempXMLNode: DotNet XmlNode;
    begin
        if ECPercent <> 0 then begin
            XMLDOMManagement.AddElementWithPrefix(
              XMLNode, 'TipoRecargoEquivalencia', FormatNumber(ECPercent), 'sii', SiiTxt, TempXMLNode);
            XMLDOMManagement.AddElementWithPrefix(
              XMLNode, 'CuotaRecargoEquivalencia', FormatNumber(ECAmount), 'sii', SiiTxt,
              TempXMLNode);
        end;
    end;

    local procedure GetOperationDescriptionFromDocument(IsSales: Boolean; DocumentNo: Code[35]): Text
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        OperationDescription: Text;
        ShouldExit: Boolean;
    begin
        if IsSales then begin
            if SalesInvoiceHeader.Get(DocumentNo) then
                exit(SalesInvoiceHeader."Operation Description" + SalesInvoiceHeader."Operation Description 2");
            if SalesCrMemoHeader.Get(DocumentNo) then
                exit(SalesCrMemoHeader."Operation Description" + SalesCrMemoHeader."Operation Description 2");
            OperationDescription := '';
            ShouldExit := false;
            OnGetOperationDescriptionFromDocument(DocumentNo, OperationDescription, ShouldExit);
            if ShouldExit then
                exit(OperationDescription);
        end else begin
            if PurchInvHeader.Get(DocumentNo) then
                exit(PurchInvHeader."Operation Description" + PurchInvHeader."Operation Description 2");
            if PurchCrMemoHdr.Get(DocumentNo) then
                exit(PurchCrMemoHdr."Operation Description" + PurchCrMemoHdr."Operation Description 2");
        end;
    end;

    local procedure GetCorrectionInfoFromDocument(IsSales: Boolean; DocumentNo: Code[20]; var CorrectedInvoiceNo: Code[20]; var CorrectionType: Option; EntryCorrType: Option; EntryCorrInvNo: Code[20])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IsHandled: Boolean;
    begin
        if IsSales then begin
            case true of
                SalesCrMemoHeader.Get(DocumentNo):
                    begin
                        CorrectedInvoiceNo := SalesCrMemoHeader."Corrected Invoice No.";
                        CorrectionType := SalesCrMemoHeader."Correction Type";
                    end;
                else begin
                    IsHandled := false;
                    OnGetCorrectionInfoFromDocument(DocumentNo, CorrectedInvoiceNo, CorrectionType, IsHandled);
                    if not IsHandled then begin
                        CorrectedInvoiceNo := EntryCorrInvNo;
                        CorrectionType := EntryCorrType;
                    end;
                end;
            end;
            exit;
        end;
        if PurchCrMemoHdr.Get(DocumentNo) then begin
            CorrectedInvoiceNo := PurchCrMemoHdr."Corrected Invoice No.";
            CorrectionType := PurchCrMemoHdr."Correction Type";
        end else begin
            CorrectedInvoiceNo := EntryCorrInvNo;
            CorrectionType := EntryCorrType;
        end;
    end;

    local procedure GetRequestDateOfSIIHistoryByVendLedgEntry(VendorLedgerEntry: Record "Vendor Ledger Entry"): Date
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
    begin
        SIIDocUploadState.GetSIIDocUploadStateByVendLedgEntry(VendorLedgerEntry);
        SIIHistory.SetRange("Document State Id", SIIDocUploadState.Id);
        SIIHistory.FindLast();
        exit(DT2Date(SIIHistory."Request Date"));
    end;

    local procedure GetSIISetup()
    begin
        if SIISetupInitialized then
            exit;

        SIISetup.Get();
        SIISetup.TestField("Invoice Amount Threshold");
        SIISetup.TestField("SuministroInformacion Schema");
        SIISetup.TestField("SuministroLR Schema");
        SIISetupInitialized := true;
    end;

    local procedure GetIDTypeToExport(IDType: Enum "SII ID Type"): Text[30]
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        case IDType of
            SIIDocUploadState.IDType::"02-VAT Registration No.":
                exit('02');
            SIIDocUploadState.IDType::"03-Passport":
                exit('03');
            SIIDocUploadState.IDType::"04-ID Document":
                exit('04');
            SIIDocUploadState.IDType::"05-Certificate Of Residence":
                exit('05');
            SIIDocUploadState.IDType::"06-Other Probative Document":
                exit('06');
            SIIDocUploadState.IDType::"07-Not On The Census":
                exit('07');
        end;
    end;

    local procedure GetVATNodeName(NoTaxableVAT: Boolean): Text
    begin
        if NoTaxableVAT then
            exit('NoSujeta');
        exit('Sujeta');
    end;

    [Scope('OnPrem')]
    procedure SetIsRetryAccepted(NewRetryAccepted: Boolean)
    begin
        RetryAccepted := NewRetryAccepted;
    end;

    [Scope('OnPrem')]
    procedure SetSIIVersionNo(NewSIIVersion: Option)
    begin
        SIIVersion := NewSIIVersion;
    end;

    local procedure IsREAGYPSpecialSchemeCode(VATEntry: Record "VAT Entry"; RegimeCodes: array[3] of Code[2]): Boolean
    begin
        exit((VATEntry.Type = VATEntry.Type::Purchase) and RegimeCodesContainsValue(RegimeCodes, SecondSpecialRegimeCode()));
    end;

    local procedure ExportTaxInformation(VATEntry: Record "VAT Entry"; RegimeCodes: array[3] of Code[2]): Boolean
    begin
        if VATEntry.Type <> VATEntry.Type::Purchase then
            exit(true);

        exit((VATEntry."No Taxable Type" = 0) or (not RegimeCodesContainsValue(RegimeCodes, EighthSpecialRegimeCode())));
    end;

    local procedure ExportTipoImpositivo(VATEntry: Record "VAT Entry"; RegimeCodes: array[3] of Code[2]): Boolean
    begin
        if IsREAGYPSpecialSchemeCode(VATEntry, RegimeCodes) then
            exit(false);

        exit(ExportTaxInformation(VATEntry, RegimeCodes));
    end;

    local procedure SecondSpecialRegimeCode(): Code[2]
    begin
        exit('02');
    end;

    local procedure EighthSpecialRegimeCode(): Code[2]
    begin
        exit('08');
    end;

    local procedure BuildVATEntrySource(var ExemptExists: Boolean; var ExemptionCausePresent: array[10] of Boolean; var ExemptionCode: Enum "SII Exemption Code"; var ExemptionBaseAmounts: array[10] of Decimal; var VATEntryPerPercent: Record "VAT Entry"; var NonExemptTransactionType: Option S1,S2,S3,Initial; var VATEntry: Record "VAT Entry"; PostingDate: Date; SplitByEUService: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
    begin
        VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
        if VATPostingSetup."No Taxable Type" <> 0 then
            exit;

        if VATPostingSetup."Ignore In SII" then
            exit;

        if GetExemptionCode(VATEntry, ExemptionCode) then begin
            CalculateExemptVATEntries(ExemptionCausePresent, ExemptionBaseAmounts, VATEntry, ExemptionCode);
            if SIIInitialDocUpload.DateWithinInitialUploadPeriod(PostingDate) then
                MoveExemptEntriesToTempVATEntryBuffer(VATEntryPerPercent, ExemptionCausePresent, ExemptionBaseAmounts)
            else
                ExemptExists := true;
        end else begin
            CalculateNonExemptVATEntries(VATEntryPerPercent, VATEntry, SplitByEUService, VATEntry.Amount + VATEntry."Unrealized Amount");
            BuildNonExemptTransactionType(VATEntry, NonExemptTransactionType);
        end
    end;

    local procedure HandleExemptEntries(var XMLNode: DotNet XmlNode; ExemptionCausePresent: array[10] of Boolean; ExemptionBaseAmounts: array[10] of Decimal)
    var
        TempXmlNode: DotNet XmlNode;
        StopExemptLoop: Boolean;
        BaseAmount: Decimal;
        ExemptionEntryIndex: Integer;
        ExentaExported: Boolean;
    begin
        for ExemptionEntryIndex := 1 to ArrayLen(ExemptionCausePresent) do
            if ExemptionCausePresent[ExemptionEntryIndex] and (not StopExemptLoop) then begin
                StopExemptLoop := false;

                if not ExentaExported then begin
                    XMLDOMManagement.AddElementWithPrefix(XMLNode, 'Exenta', '', 'sii', SiiTxt, XMLNode);
                    ExentaExported := true;
                end;
                if IncludeChangesVersion11() then
                    XMLDOMManagement.AddElementWithPrefix(XMLNode, 'DetalleExenta', '', 'sii', SiiTxt, XMLNode);

                // The first exemption does not have specific cause, it's because of zero VAT %
                XMLDOMManagement.AddElementWithPrefix(
                  XMLNode,
                  'CausaExencion',
                  BuildExemptionCodeString(ExemptionEntryIndex),
                  'sii',
                  SiiTxt,
                  TempXmlNode);
                BaseAmount := -ExemptionBaseAmounts[ExemptionEntryIndex];
                XMLDOMManagement.AddElementWithPrefix(
                  XMLNode,
                  'BaseImponible',
                  FormatNumber(BaseAmount),
                  'sii',
                  SiiTxt, TempXmlNode);
                XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);
            end;
        if ExentaExported then
            XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);
    end;

    local procedure CalcTotalDiffAmounts(var TotalBaseAmountDiff: Decimal; var TotalVATAmountDiff: Decimal; var TotalECPercentDiff: Decimal; var TotalECAmountDiff: Decimal; var TempOldVATEntryPerPercent: Record "VAT Entry" temporary; var TempVATEntryPerPercent: Record "VAT Entry" temporary)
    var
        BaseAmountDiff: Decimal;
        VATAmountDiff: Decimal;
        ECPercentDiff: Decimal;
        ECAmountDiff: Decimal;
    begin
        TotalBaseAmountDiff := 0;
        TotalVATAmountDiff := 0;
        TotalECPercentDiff := 0;
        TotalECAmountDiff := 0;
        TempVATEntryPerPercent.SetRange("VAT %", TempVATEntryPerPercent."VAT %");
        TempVATEntryPerPercent.SetRange("EC %", TempVATEntryPerPercent."EC %");
        repeat
            CalcDiffAmounts(BaseAmountDiff, VATAmountDiff, ECPercentDiff, ECAmountDiff, TempOldVATEntryPerPercent, TempVATEntryPerPercent);
            TotalBaseAmountDiff += BaseAmountDiff;
            TotalVATAmountDiff += VATAmountDiff;
            TotalECPercentDiff += ECPercentDiff;
            TotalECAmountDiff += ECAmountDiff;
        until TempVATEntryPerPercent.Next() = 0;
        TempVATEntryPerPercent.SetRange("VAT %");
        TempVATEntryPerPercent.SetRange("EC %");
    end;

    local procedure CalcDiffAmounts(var BaseAmountDiff: Decimal; var VATAmountDiff: Decimal; var ECPercentDiff: Decimal; var ECAmountDiff: Decimal; var TempOldVATEntryPerPercent: Record "VAT Entry" temporary; TempVATEntryPerPercent: Record "VAT Entry" temporary)
    begin
        TempOldVATEntryPerPercent.SetRange("VAT %", TempVATEntryPerPercent."VAT %");
        TempOldVATEntryPerPercent.SetRange("EC %", TempVATEntryPerPercent."EC %");
        if TempOldVATEntryPerPercent.FindFirst() then begin
            BaseAmountDiff := TempVATEntryPerPercent.Base + TempOldVATEntryPerPercent.Base;
            VATAmountDiff := TempVATEntryPerPercent.Amount + TempOldVATEntryPerPercent.Amount;
            ECPercentDiff := TempVATEntryPerPercent."EC %" - TempOldVATEntryPerPercent."EC %";
            ECAmountDiff := CalculateECAmount(TempVATEntryPerPercent.Base, TempVATEntryPerPercent."EC %") +
              CalculateECAmount(TempOldVATEntryPerPercent.Base, TempOldVATEntryPerPercent."EC %");
        end else begin
            BaseAmountDiff := TempVATEntryPerPercent.Base;
            VATAmountDiff := TempVATEntryPerPercent.Amount;
            ECPercentDiff := TempVATEntryPerPercent."EC %";
            ECAmountDiff := CalculateECAmount(TempVATEntryPerPercent.Base, TempVATEntryPerPercent."EC %");
        end;
    end;

    local procedure CalcVATAmountExclEC(VATEntry: Record "VAT Entry"): Decimal
    var
        VATEntryAmount: Decimal;
        VATEntryBase: Decimal;
    begin
        if VATEntry.Amount = 0 then
            VATEntryAmount := VATEntry."Unrealized Amount"
        else
            VATEntryAmount := VATEntry.Amount;
        if VATEntry."EC %" = 0 then
            exit(VATEntryAmount);
        if VATEntry.Base = 0 then
            VATEntryBase := VATEntry."Unrealized Base"
        else
            VATEntryBase := VATEntry.Base;
        exit(VATEntryAmount - CalculateECAmount(VATEntryBase, VATEntry."EC %"));
    end;

    local procedure CalcTipoImpositivo(NonExemptTransactionType: Option S1,S2,S3,Initial; RegimeCodes: array[3] of Code[2]; VATAmount: Decimal; Amount: Decimal): Decimal
    var
        i: Integer;
        SpecialRegimeCodes: Boolean;
    begin
        for i := 1 to ArrayLen(RegimeCodes) do
            SpecialRegimeCodes := SpecialRegimeCodes or (RegimeCodes[i] in ['03', '05', '09']);
        if (Format(NonExemptTransactionType) = 'S1') and SpecialRegimeCodes and (VATAmount = 0) then
            exit(0);
        exit(Amount);
    end;

    local procedure CalcCuotaDeducible(PostingDate: Date; RegimeCodes: array[3] of Code[2]; IDType: Enum "SII ID Type"; ECVATEntryExists: Boolean; InvoiceType: Text; HasReverseChargeEntry: Boolean; Amount: Decimal): Decimal
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
    begin
        if IncludeChangesVersion11bis() then
            if ECVATEntryExists or
               ((IDType in [SIIDocUploadState.IDType::"03-Passport", SIIDocUploadState.IDType::"04-ID Document",
                            SIIDocUploadState.IDType::"05-Certificate Of Residence",
                            SIIDocUploadState.IDType::"06-Other Probative Document"]) or
                (InvoiceType = GetF2InvoiceType())) and
               (not HasReverseChargeEntry)
            then
                exit(0);
        if SIIInitialDocUpload.DateWithinInitialUploadPeriod(PostingDate) or RegimeCodesContainsValue(RegimeCodes, '13') then
            exit(0);
        exit(Amount);
    end;

    local procedure UseReverseChargeNotIntracommunity(VATCalcType: Enum "Tax Calculation Type"; VendNo: Code[20]; PostingDate: Date; InvoiceType: Text): Boolean
    var
        VATEntry: Record "VAT Entry";
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
    begin
        exit(
          (VATCalcType = VATEntry."VAT Calculation Type"::"Reverse Charge VAT") and
          (not SIIManagement.VendorIsIntraCommunity(VendNo)) and
          (InvoiceType <> GetF5InvoiceType()) and
          (not SIIInitialDocUpload.DateWithinInitialUploadPeriod(PostingDate)));
    end;

    local procedure HandleNonTaxableVATEntries(var TempVATEntry: Record "VAT Entry" temporary; CustLedgerEntry: Record "Cust. Ledger Entry"; var TipoDesgloseXMLNode: DotNet XmlNode; var DesgloseFacturaXMLNode: DotNet XmlNode; var DomesticXMLNode: DotNet XmlNode; var DesgloseTipoOperacionXMLNode: DotNet XmlNode; var EUXMLNode: DotNet XmlNode; IsService: Boolean; DomesticCustomer: Boolean; RegimeCodes: array[3] of Code[2])
    var
        CustNo: Code[20];
        Amount: array[2] of Decimal;
        HasEntries: array[2] of Boolean;
        IsLocalRule: Boolean;
        i: Integer;
    begin
        CustNo := SIIManagement.GetCustFromLedgEntryByGLSetup(CustLedgerEntry);
        for IsLocalRule := false to true do begin
            i += 1;
            HasEntries[i] :=
              SIIManagement.GetNoTaxableSalesAmount(
                Amount[i], CustNo, CustLedgerEntry."Document Type".AsInteger(), CustLedgerEntry."Document No.",
                CustLedgerEntry."Posting Date", IsService, true, IsLocalRule, false);
        end;
        UpdateAmountBufferWithOneStopShop(HasEntries, Amount, TempVATEntry);
        ExportNonTaxableVATEntries(
          TipoDesgloseXMLNode, DesgloseFacturaXMLNode, DomesticXMLNode,
          DesgloseTipoOperacionXMLNode, EUXMLNode, IsService, DomesticCustomer, HasEntries, RegimeCodes, Amount);
    end;

    local procedure HandleReplacementNonTaxableVATEntries(var TempVATEntry: Record "VAT Entry" temporary; CustLedgerEntry: Record "Cust. Ledger Entry"; OldCustLedgerEntry: Record "Cust. Ledger Entry"; var TipoDesgloseXMLNode: DotNet XmlNode; var DesgloseFacturaXMLNode: DotNet XmlNode; var DomesticXMLNode: DotNet XmlNode; var DesgloseTipoOperacionXMLNode: DotNet XmlNode; var EUXMLNode: DotNet XmlNode; IsService: Boolean; DomesticCustomer: Boolean; RegimeCodes: array[3] of Code[2])
    var
        CustNo: Code[20];
        OldAmount: Decimal;
        Amount: Decimal;
        ReplacementAmount: array[2] of Decimal;
        HasEntries: array[2] of Boolean;
        IsLocalRule: Boolean;
        i: Integer;
    begin
        CustNo := SIIManagement.GetCustFromLedgEntryByGLSetup(CustLedgerEntry);
        for IsLocalRule := false to true do begin
            i += 1;
            HasEntries[i] :=
              SIIManagement.GetNoTaxableSalesAmount(
                OldAmount, CustNo, CustLedgerEntry."Document Type".AsInteger(), CustLedgerEntry."Document No.",
                CustLedgerEntry."Posting Date", IsService, true, IsLocalRule) or
              SIIManagement.GetNoTaxableSalesAmount(
                Amount, CustNo, OldCustLedgerEntry."Document Type".AsInteger(), OldCustLedgerEntry."Document No.",
                OldCustLedgerEntry."Posting Date", IsService, true, IsLocalRule);
            ReplacementAmount[i] := Abs(OldAmount + Amount);
        end;
        UpdateAmountBufferWithOneStopShop(HasEntries, ReplacementAmount, TempVATEntry);
        ExportNonTaxableVATEntries(
          TipoDesgloseXMLNode, DesgloseFacturaXMLNode, DomesticXMLNode, DesgloseTipoOperacionXMLNode, EUXMLNode, IsService, DomesticCustomer,
          HasEntries, RegimeCodes, ReplacementAmount);
    end;

    local procedure UpdateAmountBufferWithOneStopShop(var HasEntries: array[2] of Boolean; var Amount: array[2] of Decimal; var TempVATEntry: Record "VAT Entry" temporary)
    begin
        TempVATEntry.SetRange("One Stop Shop Reporting", true);
        TempVATEntry.CalcSums(Base);
        TempVATEntry.SetRange("One Stop Shop Reporting");
        if TempVATEntry.Base = 0 then
            exit;
        HasEntries[2] := true;
        Amount[2] += Abs(TempVATEntry.Base);
    end;

    local procedure ExportNonTaxableVATEntries(var TipoDesgloseXMLNode: DotNet XmlNode; var DesgloseFacturaXMLNode: DotNet XmlNode; var DomesticXMLNode: DotNet XmlNode; var DesgloseTipoOperacionXMLNode: DotNet XmlNode; var EUXMLNode: DotNet XmlNode; IsService: Boolean; DomesticCustomer: Boolean; HasEntries: array[2] of Boolean; RegimeCodes: array[3] of Code[2]; Amount: array[2] of Decimal)
    var
        VATXMLNode: DotNet XmlNode;
        NoTaxableNodeName: Text;
    begin
        if RegimeCodesContainsValue(RegimeCodes, EighthSpecialRegimeCode()) then
            NoTaxableNodeName := 'ImporteTAIReglasLocalizacion'
        else
            NoTaxableNodeName := 'ImportePorArticulos7_14_Otros';

        if HasEntries[1] then
            InsertNoTaxableNode(
              TipoDesgloseXMLNode, DesgloseFacturaXMLNode, DomesticXMLNode, DesgloseTipoOperacionXMLNode,
              EUXMLNode, VATXMLNode, IsService, DomesticCustomer,
              NoTaxableNodeName, Amount[1]);

        if HasEntries[2] then
            InsertNoTaxableNode(
              TipoDesgloseXMLNode, DesgloseFacturaXMLNode, DomesticXMLNode, DesgloseTipoOperacionXMLNode,
              EUXMLNode, VATXMLNode, IsService, DomesticCustomer,
              'ImporteTAIReglasLocalizacion', Amount[2]);
    end;

    local procedure MoveExemptEntriesToTempVATEntryBuffer(var TempVATEntryPerPercent: Record "VAT Entry" temporary; ExemptionCausePresent: array[10] of Boolean; ExemptionBaseAmounts: array[10] of Decimal)
    var
        VATEntry: Record "VAT Entry";
        StopExemptLoop: Boolean;
        ExemptionEntryIndex: Integer;
        EntryNo: Integer;
    begin
        VATEntry.FindLast();
        EntryNo := VATEntry."Entry No." + +2000000; // Choose Entry No. to avoid conflict with real VAT Entries
        for ExemptionEntryIndex := 1 to ArrayLen(ExemptionCausePresent) do
            if not StopExemptLoop and ExemptionCausePresent[ExemptionEntryIndex] then begin
                StopExemptLoop := false;
                EntryNo += 1;
                TempVATEntryPerPercent."Entry No." := EntryNo;
                TempVATEntryPerPercent.Base := ExemptionBaseAmounts[ExemptionEntryIndex];
                TempVATEntryPerPercent.Insert();
            end;
        Clear(ExemptionCausePresent);
        Clear(ExemptionBaseAmounts);
    end;

    local procedure MoveNonTaxableEntriesToTempVATEntryBuffer(var TempVATEntryCalculatedNonExempt: Record "VAT Entry" temporary; CustLedgerEntry: Record "Cust. Ledger Entry"; IsService: Boolean)
    var
        NoTaxableEntry: Record "No Taxable Entry";
        VATEntry: Record "VAT Entry";
        EntryNo: Integer;
    begin
        VATEntry.FindLast();
        EntryNo := VATEntry."Entry No." + 3000000;
        if SIIManagement.NoTaxableEntriesExistSales(
             NoTaxableEntry,
             SIIManagement.GetCustFromLedgEntryByGLSetup(CustLedgerEntry), CustLedgerEntry."Document Type".AsInteger(), CustLedgerEntry."Document No.",
             CustLedgerEntry."Posting Date", IsService, false, false, false)
        then
            if NoTaxableEntry.FindSet() then
                repeat
                    EntryNo += 1;
                    TempVATEntryCalculatedNonExempt.TransferFields(NoTaxableEntry);
                    TempVATEntryCalculatedNonExempt."Entry No." := EntryNo;
                    TempVATEntryCalculatedNonExempt.Amount := 0;
                    TempVATEntryCalculatedNonExempt.Insert();
                until NoTaxableEntry.Next() = 0;
    end;

    local procedure IsPurchInvoice(var InvoiceType: Text; SIIDocUploadState: Record "SII Doc. Upload State") IsInvoice: Boolean
    begin
        IsInvoice := false;
        case SIIDocUploadState."Document Type" of
            SIIDocUploadState."Document Type"::Invoice:
                begin
                    IsInvoice :=
                      IsPurchInvType(SIIDocUploadState."Purch. Invoice Type");
                    if SIIDocUploadState."Purch. Invoice Type" =
                       SIIDocUploadState."Purch. Invoice Type"::"Customs - Complementary Liquidation"
                    then
                        InvoiceType := LCLbl
                    else
                        InvoiceType := CopyStr(Format(SIIDocUploadState."Purch. Invoice Type"), 1, 2);
                end;
            SIIDocUploadState."Document Type"::"Credit Memo":
                begin
                    IsInvoice :=
                      SIIDocUploadState."Purch. Cr. Memo Type" in [SIIDocUploadState."Purch. Cr. Memo Type"::"F1 Invoice",
                                                                   SIIDocUploadState."Purch. Cr. Memo Type"::"F2 Simplified Invoice"];
                    if IsInvoice then
                        InvoiceType := CopyStr(Format(SIIDocUploadState."Purch. Cr. Memo Type"), 1, 2);
                end;
        end;
        exit(IsInvoice);
    end;

    local procedure IsPurchInvType(InvType: Enum "SII Purch. Invoice Type"): Boolean
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        exit(
          InvType in [SIIDocUploadState."Purch. Invoice Type"::"F1 Invoice",
                      SIIDocUploadState."Purch. Invoice Type"::"F2 Simplified Invoice",
                      SIIDocUploadState."Purch. Invoice Type"::"F3 Invoice issued to replace simplified invoices",
                      SIIDocUploadState."Purch. Invoice Type"::"F4 Invoice summary entry",
                      SIIDocUploadState."Purch. Invoice Type"::"F5 Imports (DUA)",
                      SIIDocUploadState."Purch. Invoice Type"::"F6 Accounting support material",
                      SIIDocUploadState."Purch. Invoice Type"::"Customs - Complementary Liquidation"]);
    end;

    local procedure IsSalesInvoice(var InvoiceType: Text; SIIDocUploadState: Record "SII Doc. Upload State") IsInvoice: Boolean
    begin
        IsInvoice := false;
        case SIIDocUploadState."Document Type" of
            SIIDocUploadState."Document Type"::Invoice:
                begin
                    IsInvoice := IsSalesInvType(SIIDocUploadState."Sales Invoice Type");
                    InvoiceType := CopyStr(Format(SIIDocUploadState."Sales Invoice Type"), 1, 2);
                end;
            SIIDocUploadState."Document Type"::"Credit Memo":
                begin
                    IsInvoice := CrMemoTypeIsInvType(SIIDocUploadState."Sales Cr. Memo Type");
                    if IsInvoice then
                        InvoiceType := CopyStr(Format(SIIDocUploadState."Sales Cr. Memo Type"), 1, 2);
                end;
        end;
        exit(IsInvoice);
    end;

    local procedure IsSalesInvType(InvType: Enum "SII Sales Invoice Type"): Boolean
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        exit(
          InvType in [SIIDocUploadState."Sales Invoice Type"::"F1 Invoice",
                      SIIDocUploadState."Sales Invoice Type"::"F2 Simplified Invoice",
                      SIIDocUploadState."Sales Invoice Type"::"F3 Invoice issued to replace simplified invoices",
                      SIIDocUploadState."Sales Invoice Type"::"F4 Invoice summary entry"]);
    end;

    local procedure CrMemoTypeIsInvType(CrMemoType: Enum "SII Sales Upload Credit Memo Type"): Boolean
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        exit(
          CrMemoType in [SIIDocUploadState."Sales Cr. Memo Type"::"F1 Invoice",
                         SIIDocUploadState."Sales Cr. Memo Type"::"F2 Simplified Invoice",
                         SIIDocUploadState."Sales Cr. Memo Type"::"F3 Invoice issued to replace simplified invoices",
                         SIIDocUploadState."Sales Cr. Memo Type"::"F4 Invoice summary entry"]);
    end;

    local procedure InsertNoTaxableNode(var TipoDesgloseXMLNode: DotNet XmlNode; var DesgloseFacturaXMLNode: DotNet XmlNode; var DomesticXMLNode: DotNet XmlNode; var DesgloseTipoOperacionXMLNode: DotNet XmlNode; var EUXMLNode: DotNet XmlNode; var VATXMLNode: DotNet XmlNode; EUService: Boolean; DomesticCustomer: Boolean; NodeName: Text; NonTaxableAmount: Decimal)
    begin
        AddTipoDesgloseDetailHeader(
          TipoDesgloseXMLNode, DesgloseFacturaXMLNode, DomesticXMLNode, DesgloseTipoOperacionXMLNode,
          EUXMLNode, VATXMLNode, EUService, DomesticCustomer, true);
        GenerateNodeForNonTaxableVAT(NonTaxableAmount, VATXMLNode, NodeName);
    end;

    local procedure InsertMedioNode(var XMLNode: DotNet XmlNode; PaymentMethodCode: Code[10])
    var
        PaymentMethod: Record "Payment Method";
        TempXMLNode: DotNet XmlNode;
        MedioValue: Text;
    begin
        MedioValue := '04';
        if PaymentMethodCode <> '' then begin
            PaymentMethod.Get(PaymentMethodCode);
            if PaymentMethod."SII Payment Method Code" <> 0 then
                MedioValue := Format(PaymentMethod."SII Payment Method Code");
        end;
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'Medio', MedioValue, 'sii', SiiTxt, TempXMLNode);
    end;

    local procedure FillDetalleIVANode(var XMLNode: DotNet XmlNode; var TempVATEntry: Record "VAT Entry" temporary; UseSign: Boolean; Sign: Integer; FillEUServiceNodes: Boolean; NonExemptTransactionType: Option S1,S2,S3,Initial; RegimeCodes: array[3] of Code[2]; AmountNodeName: Text)
    var
        TempXmlNode: DotNet XmlNode;
        Base: Decimal;
        Amount: Decimal;
        ECPercent: Decimal;
        ECAmount: Decimal;
        VATPctText: Text;
        XmlNodeInnerXml: Text;
        IsHandled: Boolean;
    begin
        TempVATEntry.SetRange("VAT %", TempVATEntry."VAT %");
        TempVATEntry.SetRange("EC %", TempVATEntry."EC %");
        OnFillDetalleIVANodeOnAfterTempVATEntrySetFilters(TempVATEntry);
        repeat
            if UseSign then begin
                Base += TempVATEntry.Base * Sign;
                Amount += TempVATEntry.Amount * Sign;
            end else begin
                Base += Abs(TempVATEntry.Base);
                Amount += Abs(TempVATEntry.Amount);
            end;
        until TempVATEntry.Next() = 0;
        if TempVATEntry."EC %" <> 0 then begin
            ECPercent := TempVATEntry."EC %";
            ECAmount += CalculateECAmount(Base, TempVATEntry."EC %");
            Amount := Amount - ECAmount;
        end;

        TempVATEntry.SetRange("VAT %");
        TempVATEntry.SetRange("EC %");
        OnFillDetalleIVANodeOnAfterTempVATEntryClearFilters(TempVATEntry);

        VATPctText :=
          FormatNumber(CalcTipoImpositivo(NonExemptTransactionType, RegimeCodes, Base, TempVATEntry."VAT %"));

        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'DetalleIVA', '', 'sii', SiiTxt, XMLNode);
        OnFillDetalleIVANodeOnBeforeExportTipoImpositivo(XMLNode, TempVATEntry);
        if ExportTipoImpositivo(TempVATEntry, RegimeCodes) then
            XMLDOMManagement.AddElementWithPrefix(XMLNode, 'TipoImpositivo', VATPctText, 'sii', SiiTxt, TempXmlNode);
        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'BaseImponible', FormatNumber(Base), 'sii', SiiTxt, TempXmlNode);
        if IsREAGYPSpecialSchemeCode(TempVATEntry, RegimeCodes) then begin
            XMLDOMManagement.AddElementWithPrefix(XMLNode, 'PorcentCompensacionREAGYP', VATPctText, 'sii', SiiTxt, TempXmlNode);
            AmountNodeName := 'ImporteCompensacionREAGYP';
        end;
        OnBeforeAddLineAmountElement(TempVATEntry, AmountNodeName, Amount);
        if ExportTaxInformation(TempVATEntry, RegimeCodes) then
            XMLDOMManagement.AddElementWithPrefix(XMLNode, AmountNodeName, FormatNumber(Amount), 'sii', SiiTxt, TempXmlNode);
        if (ECPercent <> 0) and FillEUServiceNodes then
            GenerateRecargoEquivalenciaNodes(XMLNode, ECPercent, ECAmount);

        OnFillDetalleIVANodeOnAfterGenerateRecargoEquivalenciaNodes(XMLNode, TempVATEntry);

        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);

        XmlNodeInnerXml := XMLNode.InnerXml();
        OnAfterFillDetalleIVANode(XmlNodeInnerXml, TempVATEntry, UseSign, Sign, FillEUServiceNodes, NonExemptTransactionType, RegimeCodes, AmountNodeName, IsHandled);
        if IsHandled then
            XMLNode.InnerXml(XmlNodeInnerXml);
    end;

    local procedure FillOperationDescription(var XMLNode: DotNet XmlNode; OperationDescription: Text; PostingDate: Date; LedgerEntryDescription: Text)
    var
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
        TempXMLNode: DotNet XmlNode;
    begin
        if OperationDescription <> '' then
            XMLDOMManagement.AddElementWithPrefix(
              XMLNode, 'DescripcionOperacion', OperationDescription, 'sii', SiiTxt, TempXMLNode)
        else
            if SIIInitialDocUpload.DateWithinInitialUploadPeriod(PostingDate) then
                XMLDOMManagement.AddElementWithPrefix(XMLNode, 'DescripcionOperacion', RegistroDelPrimerSemestreTxt, 'sii', SiiTxt, TempXMLNode)
            else
                XMLDOMManagement.AddElementWithPrefix(XMLNode, 'DescripcionOperacion', LedgerEntryDescription, 'sii', SiiTxt, TempXMLNode);
    end;

    local procedure FillFechaRegContable(var XMLNode: DotNet XmlNode; PostingDate: Date; RequestDate: Date)
    var
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
        TempXMLNode: DotNet XmlNode;
        NodePostingDate: Date;
    begin
        if SIIInitialDocUpload.DateWithinInitialUploadPeriod(PostingDate) then
            NodePostingDate := WorkDate()
        else
            NodePostingDate := RequestDate;
        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'FechaRegContable', FormatDate(NodePostingDate), 'sii', SiiTxt, TempXMLNode);
    end;

    local procedure FillFechaOperacion(var XMLNode: DotNet XmlNode; LastShptRcptDate: Date; PostingDate: Date; DocumentDate: Date; VATDate: Date; IsSales: Boolean; RegimeCodes: array[3] of Code[2])
    var
        TempXMLNode: DotNet XmlNode;
    begin
        GetSIISetup();
        case SIISetup."Operation Date" of
            SIISetup."Operation Date"::"Posting Date":
                begin
                    if ((LastShptRcptDate = 0D) or (LastShptRcptDate = PostingDate)) and
                    not (IsSales and RegimeCodesContainsValue(RegimeCodes, '14'))
                    then
                        exit;

                    if LastShptRcptDate > WorkDate() then
                        LastShptRcptDate := PostingDate;
                    if IsSales then begin
                        if not IncludeFechaOperationForSales(PostingDate, LastShptRcptDate, RegimeCodes) then
                            exit;
                        if IsShptDateMustBeAfterPostingDate(RegimeCodes) then
                            LastShptRcptDate := PostingDate + 1;
                    end;
                end;
            SIISetup."Operation Date"::"Document Date":
                begin
                    if PostingDate = DocumentDate then
                        exit;
                    LastShptRcptDate := DocumentDate;
                end;
            SIISetup."Operation Date"::"VAT Reporting Date":
                begin
                    if PostingDate = VATDate then
                        exit;
                    LastShptRcptDate := VATDate;
                end;
        end;

        OnFillFechaOperacionOnBeforeAddElementWithPrefix(LastShptRcptDate, PostingDate);
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'FechaOperacion', FormatDate(LastShptRcptDate), 'sii', SiiTxt, TempXMLNode);
    end;

    local procedure FillMacrodatoNode(var XMLNode: DotNet XmlNode; TotalAmount: Decimal)
    var
        TempXMLNode: DotNet XmlNode;
        Value: Text;
    begin
        if not IncludeChangesVersion11() then
            exit;
        if Abs(TotalAmount) > SIISetup."Invoice Amount Threshold" then
            Value := 'S'
        else
            Value := 'N';
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'Macrodato', Value, 'sii', SiiTxt, TempXMLNode);
    end;

    local procedure FillDocHeaderNode(): Text
    begin
        if IncludeChangesVersion11() then
            exit('PeriodoLiquidacion');
        exit('PeriodoImpositivo');
    end;

    local procedure FillRefExternaNode(var XMLNode: DotNet XmlNode; Value: Text)
    var
        TempXMLNode: DotNet XmlNode;
    begin
        if not IncludeChangesVersion11() then
            exit;
        XMLDOMManagement.AddElementWithPrefix(XMLNode, 'RefExterna', Value, 'sii', SiiTxt, TempXMLNode);
    end;

    local procedure FillBaseImponibleACosteNode(var XMLNode: DotNet XmlNode; RegimeCodes: array[3] of Code[2]; TotalBase: Decimal)
    var
        TempXMLNode: DotNet XmlNode;
    begin
        if not RegimeCodesContainsValue(RegimeCodes, SIIManagement.GetBaseImponibleACosteRegimeCode()) then
            exit;

        XMLDOMManagement.AddElementWithPrefix(
          XMLNode, 'BaseImponibleACoste', FormatNumber(TotalBase), 'sii', SiiTxt, TempXMLNode);
    end;

    local procedure IncludeContraparteNodeBySalesInvType(InvoiceType: Text): Boolean
    begin
        if IncludeChangesVersion11bis() then
            exit(InvoiceType in ['F1', 'F3']);
        exit(InvoiceType in ['F1', 'F3', 'F4']);
    end;

    local procedure IncludeContraparteNodeByCrMemoType(CrMemoType: Enum "SII Sales Credit Memo Type"): Boolean
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        exit(
          CrMemoType in [SIIDocUploadState."Sales Cr. Memo Type"::"R1 Corrected Invoice",
                         SIIDocUploadState."Sales Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)",
                         SIIDocUploadState."Sales Cr. Memo Type"::"R3 Corrected Invoice (Art. 80.4)",
                         SIIDocUploadState."Sales Cr. Memo Type"::"R4 Corrected Invoice (Other)"]);
    end;

    local procedure IncludeFechaOperationForSales(PostingDate: Date; LastShptRcptDate: Date; RegimeCodes: array[3] of Code[2]): Boolean
    var
        SpecialRegimeCodes: Boolean;
        i: Integer;
    begin
        if not IncludeChangesVersion11bis() then
            exit(true);
        for i := 1 to ArrayLen(RegimeCodes) do
            SpecialRegimeCodes := SpecialRegimeCodes or (RegimeCodes[i] in ['14', '15']);
        if SpecialRegimeCodes then
            exit(true);
        exit(PostingDate >= LastShptRcptDate);
    end;

    local procedure IsShptDateMustBeAfterPostingDate(RegimeCodes: array[3] of Code[2]): Boolean
    begin
        if not IncludeChangesVersion11bis() then
            exit(false);
        exit(RegimeCodesContainsValue(RegimeCodes, '14'));
    end;

    local procedure RegimeCodesContainsValue(RegimeCodes: array[3] of Code[2]; Value: Text) RegimeCodeFound: Boolean
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(RegimeCodes) do
            RegimeCodeFound := RegimeCodeFound or (RegimeCodes[i] = Value);
    end;

    local procedure IncludeChangesVersion11(): Boolean
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        exit((SIIVersion = SIIDocUploadState."Version No."::"1.1") or IncludeChangesVersion11bis());
    end;

    local procedure IncludeChangesVersion11bis(): Boolean
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        exit(SIIVersion >= SIIDocUploadState."Version No."::"2.1");
    end;

    local procedure IncludeImporteTotalNode(): Boolean
    begin
        if not IncludeChangesVersion11bis() then
            exit(true);
        exit(SIISetup."Include ImporteTotal");
    end;

    local procedure GetF2InvoiceType(): Text[2]
    begin
        exit('F2');
    end;

    local procedure GetF5InvoiceType(): Text[2]
    begin
        exit('F5');
    end;

    local procedure UpdateSalesCrMemoTypeFromCorrInvType(var SIIDocUploadState: Record "SII Doc. Upload State")
    begin
        if SIIDocUploadState."Document Type" <> SIIDocUploadState."Document Type"::Invoice then
            exit;

        case SIIDocUploadState."Sales Invoice Type" of
            SIIDocUploadState."Sales Invoice Type"::"R1 Corrected Invoice":
                SIIDocUploadState."Sales Cr. Memo Type" := SIIDocUploadState."Sales Cr. Memo Type"::"R1 Corrected Invoice";
            SIIDocUploadState."Sales Invoice Type"::"R2 Corrected Invoice (Art. 80.3)":
                SIIDocUploadState."Sales Cr. Memo Type" := SIIDocUploadState."Sales Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)";
            SIIDocUploadState."Sales Invoice Type"::"R3 Corrected Invoice (Art. 80.4)":
                SIIDocUploadState."Sales Cr. Memo Type" := SIIDocUploadState."Sales Cr. Memo Type"::"R3 Corrected Invoice (Art. 80.4)";
            SIIDocUploadState."Sales Invoice Type"::"R4 Corrected Invoice (Other)":
                SIIDocUploadState."Sales Cr. Memo Type" := SIIDocUploadState."Sales Cr. Memo Type"::"R4 Corrected Invoice (Other)";
            SIIDocUploadState."Sales Invoice Type"::"R5 Corrected Invoice in Simplified Invoices":
                SIIDocUploadState."Sales Cr. Memo Type" :=
                  SIIDocUploadState."Sales Cr. Memo Type"::"R5 Corrected Invoice in Simplified Invoices";
        end;
    end;

    local procedure UpdatePurchCrMemoTypeFromCorrInvType(var SIIDocUploadState: Record "SII Doc. Upload State")
    begin
        if SIIDocUploadState."Document Type" <> SIIDocUploadState."Document Type"::Invoice then
            exit;

        case SIIDocUploadState."Purch. Invoice Type" of
            SIIDocUploadState."Purch. Invoice Type"::"R1 Corrected Invoice":
                SIIDocUploadState."Purch. Cr. Memo Type" := SIIDocUploadState."Purch. Cr. Memo Type"::"R1 Corrected Invoice";
            SIIDocUploadState."Purch. Invoice Type"::"R2 Corrected Invoice (Art. 80.3)":
                SIIDocUploadState."Purch. Cr. Memo Type" := SIIDocUploadState."Purch. Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)";
            SIIDocUploadState."Purch. Invoice Type"::"R3 Corrected Invoice (Art. 80.4)":
                SIIDocUploadState."Purch. Cr. Memo Type" := SIIDocUploadState."Purch. Cr. Memo Type"::"R3 Corrected Invoice (Art. 80.4)";
            SIIDocUploadState."Purch. Invoice Type"::"R4 Corrected Invoice (Other)":
                SIIDocUploadState."Purch. Cr. Memo Type" := SIIDocUploadState."Purch. Cr. Memo Type"::"R4 Corrected Invoice (Other)";
            SIIDocUploadState."Purch. Invoice Type"::"R5 Corrected Invoice in Simplified Invoices":
                SIIDocUploadState."Purch. Cr. Memo Type" :=
                  SIIDocUploadState."Purch. Cr. Memo Type"::"R5 Corrected Invoice in Simplified Invoices";
        end;
    end;

    local procedure GetSalesExpeditionDate(CustLedgerEntry: Record "Cust. Ledger Entry"): Text
    var
        PostingDate: Date;
    begin
        PostingDate := CustLedgerEntry."Posting Date";
        OnAfterGetSalesExpeditionDate(CustLedgerEntry, PostingDate);
        exit(FormatDate(PostingDate));
    end;

    local procedure GetInvCrMemoTypeFromCustLedgEntry(SIIDocUploadState: Record "SII Doc. Upload State"; CustLedgerEntry: Record "Cust. Ledger Entry"): Text
    begin
        if CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Invoice then begin
            if SIIDocUploadState."Sales Invoice Type" = SIIDocUploadState."Sales Invoice Type"::" " then
                exit('F1');
            exit(CopyStr(Format(SIIDocUploadState."Sales Invoice Type"), 1, 2));
        end;
        if SIIDocUploadState."Sales Cr. Memo Type" = SIIDocUploadState."Sales Cr. Memo Type"::" " then
            exit('R1');
        exit(CopyStr(Format(SIIDocUploadState."Sales Cr. Memo Type"), 1, 2));
    end;

    [Scope('OnPrem')]
    procedure Reset()
    begin
        IsInitialized := false;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBuildNonExemptTransactionType(VATEntry: Record "VAT Entry"; var TransactionType: Option S1,S2,S3,Initial)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateCuotaDeducibleValue(var CuotaDeducibleValue: Decimal; var VATAmount: Decimal; var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateNonExemptVATEntries(var TempVATEntryOut: Record "VAT Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillDetalleIVANode(var XmlNodeInnerXml: Text; TempVATEntry: Record "VAT Entry" temporary; UseSign: Boolean; Sign: Integer; FillEUServiceNodes: Boolean; NonExemptTransactionType: Option S1,S2,S3,Initial; RegimeCodes: array[3] of Code[2]; AmountNodeName: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCustomerByGLSetup(var Customer: Record Customer; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesExpeditionDate(CustLedgerEntry: Record "Cust. Ledger Entry"; var PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGenerateXmlDocument(LedgerEntry: Variant; var XMLDocOut: XmlDocument; UploadType: Option; IsCreditMemoRemoval: Boolean; var ResultValue: Boolean; RetryAccepted: Boolean; SIIVersion: Option; var isHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializePurchXmlBody(var XmlNodeInnerXml: Text; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddLineAmountElement(var TempVATEntry: Record "VAT Entry" temporary; AmountNodeName: Text; var Amount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddVATAmountPurchDiffElement(var TempVATEntry: Record "VAT Entry" temporary; var VATAmountDiff: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeContraparteNode(var XMLNode: DotNet XmlNode; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenerateXmlDocument(LedgerEntry: Variant; var XMLDocOut: XmlDocument; UploadType: Option; IsCreditMemoRemoval: Boolean; var ResultValue: Boolean; var IsHandled: Boolean; RetryAccepted: Boolean; SIIVersion: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetClaveRegimenNodePurchases(SIIDocUploadState: Record "SII Doc. Upload State"; VendLedgerEntry: Record "Vendor Ledger Entry"; Vendor: Record Vendor; var RegimeCode: Code[2]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetClaveRegimenNodeSales(SIIDocUploadState: Record "SII Doc. Upload State"; CustLedgerEntry: Record "Cust. Ledger Entry"; Customer: Record Customer; var RegimeCode: Code[2]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateNonExemptVATEntriesOnAfterTempVATEntryOutSetFilters(var TempVATEntryOut: Record "VAT Entry" temporary; TempVATEntry: Record "VAT Entry" temporary; SplitByEUService: Boolean; VATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateTotalVatAndBaseAmountsOnBeforeAssignTotalBaseAmount(LedgerEntryRecRef: RecordRef; var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillFechaOperacionOnBeforeAddElementWithPrefix(var LastShptRcptDate: Date; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillDetalleIVANodeOnAfterTempVATEntryClearFilters(var TempVATEntry: Record "VAT Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillDetalleIVANodeOnAfterTempVATEntrySetFilters(var TempVATEntry: Record "VAT Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillDetalleIVANodeOnBeforeExportTipoImpositivo(var XMLNode: DotNet XmlNode; var TempVATEntry: Record "VAT Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateNodeForFechaOperacionSalesOnBeforeFillFechaOperacion(var LastShipDate: Date; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleReplacementPurchCorrectiveInvoiceOnBeforeAddElementDetalleIVA(var XMLNode: DotNet XmlNode; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleReplacementPurchCorrectiveInvoiceOnBeforeAddCuotaDeducibleElement(VendorLedgerEntry: Record "Vendor Ledger Entry"; var CuotaDeducibleDecValue: Decimal; var BaseAmountDiff: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPopulateXMLWithSalesInvoiceOnAfterContraparteNode(var TipoDesgloseXMLNode: DotNet XmlNode; var DesgloseFacturaXMLNode: DotNet XmlNode; var DomesticXMLNode: DotNet XmlNode; var DesgloseTipoOperacionXMLNode: DotNet XmlNode; IsService: Boolean; DomesticCustomer: Boolean; CustLedgerEntry: Record "Cust. Ledger Entry"; SiiTxt: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPopulateXMLWithPurchInvoiceOnBeforeDesgloseFacturaNode(var XMLNode: DotNet XmlNode; var TempVATEntryCalculated: Record "VAT Entry" temporary; XMLNodeName: Text; RegimeCodes: array[3] of Code[2]; VendorLedgerEntry: Record "Vendor Ledger Entry"; SiiTxt: Text; var IsHandled: Boolean; TempVATEntryNormalCalculated: Record "VAT Entry" temporary; TempVATEntryReverseChargeCalculated: Record "VAT Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateNodeForFechaOperacionSalesCrMemoHeaderOnBeforeFillFechaOperacion(var LastShipDate: Date; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure CorrectiveInvoiceSalesDifferenceOnBeforeContraparteNode(var XMLNode: DotNet XmlNode; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure HandleReplacementSalesCorrectiveInvoiceOnBeforeContraparteNode(var XMLNode: DotNet XmlNode; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddPurchTail(var XMLNode: DotNet XmlNode; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitializePurchXmlBodyOnBeforeAssignExerciseAndPeriod(var XMLNode: DotNet XmlNode; VendorLedgerEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillThirdPartyIdOnBeforeCheckCountryAndVATRegNo(var CountryCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleReplacementPurchCorrectiveInvoiceOnAfterGenerateRecargoEquivalenciaNodes(var XMLNode: DotNet XmlNode; TempVATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillDetalleIVANodeOnAfterGenerateRecargoEquivalenciaNodes(var XMLNode: DotNet XmlNode; TempVATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleReplacementPurchCorrectiveInvoiceOnAfterCuotaDeducible(var XMLNode: DotNet XmlNode; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillThirdPartyIdOnBeforeAssignValues(SIIDocUploadState: Record "SII Doc. Upload State"; var CountryCode: Code[20]; var Name: Text; var VatNo: Code[20]; IsIntraCommunity: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateTotalVatAndBaseAmounts(LedgerEntryRecRef: RecordRef; var TotalBaseAmount: Decimal; var TotalNonExemptVATBaseAmount: Decimal; var TotalVATAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPopulateXMLWithPurchInvoiceOnBeforeAddNodeForTotals(var AddNodeForTotals: Boolean; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var TotalBase: Decimal; var TotalNonExemptBase: Decimal; var TotalVATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPopulateXMLWithSalesInvoiceOnBeforeAddNodeForTotals(var AddNodeForTotals: Boolean; var CustLedgerEntry: Record "Cust. Ledger Entry"; var TotalBase: Decimal; var TotalNonExemptBase: Decimal; var TotalVATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPopulateXMLWithSalesInvoiceOnBeforeFillRefExternaNode(var SIIDocUploadState: Record "SII Doc. Upload State"; var ValueRefExternal: Text);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPopulateXMLWithSalesInvoiceOnBeforeInitializeSalesXmlBody(var CustLedgerEntry: Record "Cust. Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCorrectionInfoFromDocument(DocumentNo: Code[20]; var CorrectedInvoiceNo: Code[20]; var CorrectionType: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetOperationDescriptionFromDocument(DocumentNo: Code[35]; var OperationDescription: Text; var ShouldExit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPopulateXMLWithPurchInvoiceOnBeforeFillRefExternaNode(var SIIDocUploadState: Record "SII Doc. Upload State"; var ValueRefExternal: Text);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCorrectiveInvoiceSalesDifferenceOnBeforeFillRefExternaNode(var SIIDocUploadState: Record "SII Doc. Upload State"; var ValueRefExternal: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleReplacementSalesCorrectiveInvoiceOnBeforeFillRefExternaNode(var SIIDocUploadState: Record "SII Doc. Upload State"; var ValueRefExternal: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleNormalPurchCorrectiveInvoiceOnBeforeFillRefExternaNode(var SIIDocUploadState: Record "SII Doc. Upload State"; var ValueRefExternal: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleReplacementPurchCorrectiveInvoiceOnBeforeFillRefExternaNode(var SIIDocUploadState: Record "SII Doc. Upload State"; var ValueRefExternal: Text)
    begin
    end;
}

