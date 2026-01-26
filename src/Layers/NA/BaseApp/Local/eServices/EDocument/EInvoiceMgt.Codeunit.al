// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Utilities;
using System;
using System.Email;
using System.IO;
using System.Reflection;
using System.Security.Encryption;
using System.Utilities;
using System.Xml;

codeunit 10145 "E-Invoice Mgt."
{
    Permissions = TableData "Sales Shipment Header" = rimd,
                  TableData "Sales Invoice Header" = rimd,
                  TableData "Sales Cr.Memo Header" = rimd,
                  TableData "Transfer Shipment Header" = rimd;

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        SourceCodeSetup: Record "Source Code Setup";
        EInvoiceCommunication: Codeunit "EInvoice Communication";
        DocNameSpace: Text;
        Text000: Label 'Dear customer, please find invoice number %1 in the attachment.';
        PaymentAttachmentMsg: Label 'Dear customer, please find payment number %1 in the attachment.', Comment = '%1=The payment number.';
        Text001: Label 'E-Document %1 has been sent.';
        Text002: Label 'One or more invoices have already been sent.\Do you want to continue?';
        PaymentsAlreadySentQst: Label 'One or more payments have already been sent.\Do you want to continue?';
        Text004: Label 'Dear customer, please find credit memo number %1 in the attachment.';
        Text005: Label 'Invoice no. %1.';
        Text006: Label 'Credit memo no. %1.';
        Export: Boolean;
        PaymentNoMsg: Label 'Payment no. %1.', Comment = '%1=The payment number.';
        Text007: Label 'You cannot perform this action on a deleted document.';
        EInvoiceSendActionsTxt: Label '&Request Stamp,&Send,Request Stamp &and Send';
        Text009: Label 'Cannot find a valid PAC web service for the action %1.\You must specify web service details for the combination of the %1 action and the %2 and %3 that you have selected in the %4 window.';
        Text010: Label 'You cannot choose the action %1 when the document status is %2.';
        EDocAction: Option "Request Stamp",Send,Cancel,CancelRequest,MarkAsCanceled,ResetCancelRequest;
        Text011: Label 'There is no electronic stamp for document no. %1.\Do you want to continue?';
        CancelAction: Option ,CancelRequest,GetResponse,MarkAsCanceled,ResetCancelRequest;
        MethodTypeRef: Option "Request Stamp",Cancel,CancelRequest;
        Text012: Label 'Cannot contact the PAC. You must specify a value for the %1 field in the %2 window for the PAC that you selected in the %3 window.', Comment = '%1=Certificate;%2=PACWebService table caption;%3=GLSetup table caption';
        Text013: Label 'Request Stamp,Send,Cancel,Cancel Request,Mark as Canceled,Reset Cancellation Request';
        Text014: Label 'CFDI feature is not enabled. Open the General Ledger Setup page, toggle the Enabled checkbox and specify the PAC Environment under the Electronic Invoice FastTab.';
        Text015: Label 'Do you want to cancel the electronic document?';
        ResetCancellationRequestQst: Label 'Do you want to reset the cancellation request to the error status?';
        FileDialogTxt: Label 'Import electronic invoice';
        ImportFailedErr: Label 'The import failed. The XML document is not a valid electronic invoice.';
        StampErr: Label 'You have chosen the document type %1. You can only request and send documents if the document type is Payment.', Comment = '%1=Document Type';
        UnableToStampErr: Label 'An existing payment is applied to the invoice that has not been stamped. That payment must be stamped before you can request a stamp for any additional payments.';
        UnableToStampAppliedErr: Label 'The prepayment invoice %1 has not been stamped. That invoice must be stamped before you can request a stamp for this applied invoice.', Comment = '%1=The invoice number.';
        CurrencyDecimalPlaces: Integer;
        MXElectronicInvoicingLbl: Label 'Electronic Invoice Setup for Mexico';
        SATNotValidErr: Label 'The SAT certificate is not valid.';
        NoRelationDocumentsExistErr: Label 'No relation documents specified for the replacement of previous CFDIs.';
        GLSetupRead: Boolean;
        RoundingModel: Option "Model1-Recalculate","Model2-Recalc-NoDiscountRounding","Model3-NoRecalculation","Model4-DecimalBased";
        FileFilterTxt: Label 'XML Files(*.xml)|*.xml|All Files(*.*)|*.*', Locked = true;
        ExtensionFilterTxt: Label 'xml', Locked = true;
        EmptySATCatalogErr: Label 'Catalog %1 is empty.', Comment = '%1 - table name.';
        PACDetailDoesNotExistErr: Label 'Record %1 does not exist for %2, %3, %4.', Comment = '%1 - table name, %2 - PAC Code, %3 - PAC environment, %4 - type. ';
        WrongFieldValueErr: Label 'Wrong value %1 in field %2 of table %3.', Comment = '%1 - field value, %2 - field caption, %3 - table caption.';
        CombinationCannotBeUsedErr: Label '%1 %2 cannot be used with %3 %4.', Comment = '%1 - field 1, %2 - value of field 1, %3 - field 2, %4 - value of field 2.';
        ValueIsNotDefinedErr: Label 'Value %1 is not defined in %2.', Comment = '%1 - value, %2 - table caption.';
        NumeroPedimentoFormatTxt: Label '%1  %2  %3  %4', Comment = '%1 year; %2 - customs office; %3 patent number; %4 progressive number.';
        // fault model labels
        MXElectronicInvoicingTok: Label 'MXElectronicInvoicingTelemetryCategoryTok', Locked = true;
        SATCertificateNotValidErr: Label 'The SAT certificate is not valid: %1', Comment = '%1 - last error.', Locked = true;
        StampReqMsg: Label 'Sending stamp request for document: %1', Locked = true;
        StampReqSuccessMsg: Label 'Stamp request successful for document: %1', Locked = true;
        InvokeMethodMsg: Label 'Sending request for action: %1', Locked = true;
        InvokeMethodSuccessMsg: Label 'Successful request for action: %1', Locked = true;
        NullParameterErr: Label 'The %1 cannot be empty', Locked = true;
        ProcessResponseErr: Label 'Cannot process response for document %1. %2', Locked = true;
        ResetCancellationRequestErr: Label 'Reset cancellation request for document %1.', Locked = true;
        SendDocMsg: Label 'Sending document: %1', Locked = true;
        SendDocSuccessMsg: Label 'Document %1 successfully sent', Locked = true;
        SendEmailErr: Label 'Cannot send email. %1', Locked = true;
        CancelDocMsg: Label 'Cancelling document: %1', Locked = true;
        CancelDocSuccessMsg: Label 'Document %1 canceled successfully', Locked = true;
        PaymentStampReqMsg: Label 'Sending payment stamp request', Locked = true;
        PaymentStampReqSuccessMsg: Label 'Payment stamp request successful', Locked = true;
        ProcessPaymentErr: Label 'Cannot process payment %2', Locked = true;
        SendPaymentMsg: Label 'Sending payment', Locked = true;
        SendPaymentSuccessMsg: Label 'Payment successfully sent', Locked = true;
        SpecialCharsTxt: Label 'áéíñóúüÁÉÍÑÓÚÜ', Locked = true;
        SchemaLocation1xsdTxt: Label '%1  %2', Comment = '%1 - namespase; %2 - xsd location.';
        SchemaLocation2xsdTxt: Label '%1  %2  %3  %4', Comment = '%1 - namespase1; %2 - xsd location1; %3 - namespase2; %4 - xsd location2.';
        SchemaLocation3xsdTxt: Label '%1  %2  %3  %4 %5 %6', Comment = '%1 - namespase1; %2 - xsd location1; %3 - namespase2; %4 - xsd location2; %5 - namespase3; %6 - xsd location3.';
        XSINamespaceTxt: Label 'http://www.w3.org/2001/XMLSchema-instance', Locked = true;
        CFDINamespaceTxt: Label 'http://www.sat.gob.mx/cfd/4', Locked = true;
        CartaPorteNamespaceTxt: Label 'http://www.sat.gob.mx/CartaPorte31', Locked = true;
        CFDIXSDLocationTxt: Label 'http://www.sat.gob.mx/sitio_internet/cfd/4/cfdv40.xsd', Locked = true;
        CFDIComercioExteriorNamespaceTxt: Label 'http://www.sat.gob.mx/ComercioExterior20', Locked = true;
        CFDIComercioExteriorSchemaLocationTxt: Label 'http://www.sat.gob.mx/sitio_internet/cfd/ComercioExterior20/ComercioExterior20.xsd', Locked = true;
        CartaPorteSchemaLocationTxt: Label 'http://www.sat.gob.mx/sitio_internet/cfd/CartaPorte/CartaPorte31.xsd', Locked = true;
        CancelSelectionMenuQst: Label 'Cancel Request,Get Response,Mark as Canceled,Reset Cancellation Request';

    procedure RequestStampDocument(var RecRef: RecordRef; Prepayment: Boolean)
    var
        Selection: Integer;
        ElectronicDocumentStatus: Option;
    begin
        // Called from Send Action
        Export := false;
        GetCompanyInfo();
        GetGLSetupOnce();
        SourceCodeSetup.Get();

        if RecRef.Number in [DATABASE::"Sales Shipment Header", DATABASE::"Transfer Shipment Header"] then
            Selection := 1
        else
            Selection := StrMenu(EInvoiceSendActionsTxt, 3);

        ElectronicDocumentStatus := RecRef.Field(10030).Value();

        case Selection of
            1:// Request Stamp
                begin
                    EDocActionValidation(EDocAction::"Request Stamp", ElectronicDocumentStatus);
                    RequestStamp(RecRef, Prepayment, false);
                    RequestStampOnRoundingError(RecRef, Prepayment, false, RoundingModel::"Model2-Recalc-NoDiscountRounding");
                    RequestStampOnRoundingError(RecRef, Prepayment, false, RoundingModel::"Model3-NoRecalculation");
                    RequestStampOnRoundingError(RecRef, Prepayment, false, RoundingModel::"Model4-DecimalBased");
                end;
            2:// Send
                begin
                    EDocActionValidation(EDocAction::Send, ElectronicDocumentStatus);
                    Send(RecRef, false);
                end;
            3:// Request Stamp and Send
                begin
                    EDocActionValidation(EDocAction::"Request Stamp", ElectronicDocumentStatus);
                    RequestStamp(RecRef, Prepayment, false);
                    RequestStampOnRoundingError(RecRef, Prepayment, false, RoundingModel::"Model2-Recalc-NoDiscountRounding");
                    RequestStampOnRoundingError(RecRef, Prepayment, false, RoundingModel::"Model3-NoRecalculation");
                    RequestStampOnRoundingError(RecRef, Prepayment, false, RoundingModel::"Model4-DecimalBased");
                    Commit();
                    ElectronicDocumentStatus := RecRef.Field(10030).Value();
                    EDocActionValidation(EDocAction::Send, ElectronicDocumentStatus);
                    Send(RecRef, false);
                end;
        end;
    end;

    procedure CancelDocument(var RecRef: RecordRef)
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesShipmentHeader: Record "Sales Shipment Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        Selection: Integer;
        ElectronicDocumentStatus: Option;
    begin
        Export := false;
        GetCheckCompanyInfo();
        GetGLSetup();
        SourceCodeSetup.Get();

        Selection := CancelAction;
        if GuiAllowed and (Selection = 0) then begin
            Selection := StrMenu(CancelSelectionMenuQst, 1);
            case Selection of
                CancelAction::CancelRequest, CancelAction::MarkAsCanceled:
                    if not Confirm(Text015, false) then
                        Selection := 0;
                CancelAction::ResetCancelRequest:
                    if not Confirm(ResetCancellationRequestQst, false) then
                        Selection := 0;
            end;
        end;
        if Selection = 0 then
            exit;

        ElectronicDocumentStatus := RecRef.Field(10030).Value();
        case Selection of
            CancelAction::MarkAsCanceled:
                begin
                    EDocActionValidation(EDocAction::MarkAsCanceled, ElectronicDocumentStatus);
                    CancelDocumentManual(RecRef, true);
                    exit;
                end;
            CancelAction::ResetCancelRequest:
                begin
                    EDocActionValidation(EDocAction::ResetCancelRequest, ElectronicDocumentStatus);
                    ResetCancellationRequest(RecRef);
                    exit;
                end;
        end;

        case RecRef.Number of
            DATABASE::"Sales Invoice Header":
                begin
                    RecRef.SetTable(SalesInvHeader);
                    case Selection of
                        CancelAction::CancelRequest:
                            begin
                                EDocActionValidation(EDocAction::Cancel, SalesInvHeader."Electronic Document Status");
                                CancelESalesInvoice(SalesInvHeader, MethodTypeRef::Cancel);
                            end;
                        CancelAction::GetResponse:
                            begin
                                SalesInvHeader.TestField("CFDI Cancellation ID");
                                if SalesInvHeader."Electronic Document Status" in
                                    [SalesInvHeader."Electronic Document Status"::"Cancel In Progress", SalesInvHeader."Electronic Document Status"::"Cancel Error"]
                                then
                                    CancelESalesInvoice(SalesInvHeader, MethodTypeRef::CancelRequest);
                            end;
                    end;
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    RecRef.SetTable(SalesCrMemoHeader);
                    case Selection of
                        CancelAction::CancelRequest:
                            begin
                                EDocActionValidation(EDocAction::Cancel, SalesCrMemoHeader."Electronic Document Status");
                                CancelESalesCrMemo(SalesCrMemoHeader, MethodTypeRef::Cancel);
                            end;
                        CancelAction::GetResponse:
                            begin
                                EDocActionValidation(EDocAction::CancelRequest, SalesInvHeader."Electronic Document Status");
                                SalesCrMemoHeader.TestField("CFDI Cancellation ID");
                                if SalesCrMemoHeader."Electronic Document Status" in
                                    [SalesCrMemoHeader."Electronic Document Status"::"Cancel In Progress", SalesCrMemoHeader."Electronic Document Status"::"Cancel Error"]
                                then
                                    CancelESalesCrMemo(SalesCrMemoHeader, MethodTypeRef::CancelRequest);
                            end;
                    end;
                end;
            DATABASE::"Service Invoice Header":
                begin
                    RecRef.SetTable(ServiceInvHeader);
                    case Selection of
                        CancelAction::CancelRequest:
                            begin
                                EDocActionValidation(EDocAction::Cancel, ServiceInvHeader."Electronic Document Status");
                                CancelEServiceInvoice(ServiceInvHeader, MethodTypeRef::Cancel);
                            end;
                        CancelAction::GetResponse:
                            begin
                                ServiceInvHeader.TestField("CFDI Cancellation ID");
                                if ServiceInvHeader."Electronic Document Status" in
                                    [ServiceInvHeader."Electronic Document Status"::"Cancel In Progress", ServiceInvHeader."Electronic Document Status"::"Cancel Error"]
                                then
                                    CancelEServiceInvoice(ServiceInvHeader, MethodTypeRef::CancelRequest);
                            end;
                    end;
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    RecRef.SetTable(ServiceCrMemoHeader);
                    case Selection of
                        CancelAction::CancelRequest:
                            begin
                                EDocActionValidation(EDocAction::Cancel, ServiceCrMemoHeader."Electronic Document Status");
                                CancelEServiceCrMemo(ServiceCrMemoHeader, MethodTypeRef::Cancel);
                            end;
                        CancelAction::GetResponse:
                            begin
                                ServiceCrMemoHeader.TestField("CFDI Cancellation ID");
                                if ServiceCrMemoHeader."Electronic Document Status" in
                                    [ServiceCrMemoHeader."Electronic Document Status"::"Cancel In Progress", ServiceCrMemoHeader."Electronic Document Status"::"Cancel Error"]
                                then
                                    CancelEServiceCrMemo(ServiceCrMemoHeader, MethodTypeRef::CancelRequest);
                            end;
                    end;
                end;
            DATABASE::"Cust. Ledger Entry":
                begin
                    RecRef.SetTable(CustLedgerEntry);
                    case Selection of
                        CancelAction::CancelRequest:
                            begin
                                EDocActionValidation(EDocAction::Cancel, CustLedgerEntry."Electronic Document Status");
                                CancelEPayment(CustLedgerEntry, MethodTypeRef::Cancel);
                            end;
                        CancelAction::GetResponse:
                            begin
                                CustLedgerEntry.TestField("CFDI Cancellation ID");
                                if CustLedgerEntry."Electronic Document Status" in
                                    [CustLedgerEntry."Electronic Document Status"::"Cancel In Progress", CustLedgerEntry."Electronic Document Status"::"Cancel Error"]
                                then
                                    CancelEPayment(CustLedgerEntry, MethodTypeRef::CancelRequest);
                            end;
                    end;
                end;
            DATABASE::"Sales Shipment Header":
                begin
                    RecRef.SetTable(SalesShipmentHeader);
                    case Selection of
                        CancelAction::CancelRequest:
                            begin
                                EDocActionValidation(EDocAction::Cancel, SalesShipmentHeader."Electronic Document Status");
                                CancelESalesShipment(SalesShipmentHeader, MethodTypeRef::Cancel);
                            end;
                        CancelAction::GetResponse:
                            begin
                                SalesShipmentHeader.TestField("CFDI Cancellation ID");
                                if SalesShipmentHeader."Electronic Document Status" in
                                    [SalesShipmentHeader."Electronic Document Status"::"Cancel In Progress", SalesShipmentHeader."Electronic Document Status"::"Cancel Error"]
                                then
                                    CancelESalesShipment(SalesShipmentHeader, MethodTypeRef::CancelRequest);
                            end;
                    end;
                end;
            DATABASE::"Transfer Shipment Header":
                begin
                    RecRef.SetTable(TransferShipmentHeader);
                    case Selection of
                        CancelAction::CancelRequest:
                            begin
                                EDocActionValidation(EDocAction::Cancel, TransferShipmentHeader."Electronic Document Status");
                                CancelETransferShipment(TransferShipmentHeader, MethodTypeRef::Cancel);
                            end;
                        CancelAction::GetResponse:
                            begin
                                TransferShipmentHeader.TestField("CFDI Cancellation ID");
                                if TransferShipmentHeader."Electronic Document Status" in
                                    [TransferShipmentHeader."Electronic Document Status"::"Cancel In Progress", TransferShipmentHeader."Electronic Document Status"::"Cancel Error"]
                                then
                                    CancelETransferShipment(TransferShipmentHeader, MethodTypeRef::CancelRequest);
                            end;
                    end;
                end;
        end;
    end;

    procedure CancelDocumentRequestStatus(var RecRef: RecordRef)
    begin
        CancelAction := CancelAction::GetResponse;
        CancelDocument(RecRef);
    end;

    procedure SetCancelManual(var RecRef: RecordRef)
    begin
        CancelAction := CancelAction::MarkAsCanceled;
        CancelDocumentManual(RecRef, false);
    end;

    procedure EDocActionValidation("Action": Option "Request Stamp",Send,Cancel; Status: Option " ","Stamp Received",Sent,Canceled,"Stamp Request Error","Cancel Error") Selection: Integer
    var
        TempSalesInvoiceHeader: Record "Sales Invoice Header" temporary;
        DocStatus: Option " ","Stamp Received",Sent,Canceled,"Stamp Request Error","Cancel Error","Cancel In Progress";
    begin
        TempSalesInvoiceHeader."Electronic Document Status" := Status;

        if Action = Action::"Request Stamp" then
            if Status in [Status::"Stamp Received", Status::Sent, Status::"Cancel Error", Status::Canceled, DocStatus::"Cancel In Progress"] then
                Error(Text010, SelectStr(Action + 1, Text013), TempSalesInvoiceHeader."Electronic Document Status");

        if Action = Action::Send then
            if Status in [Status::" ", Status::Canceled, Status::"Cancel Error", Status::"Stamp Request Error", DocStatus::"Cancel In Progress"]
            then
                Error(Text010, SelectStr(Action + 1, Text013), TempSalesInvoiceHeader."Electronic Document Status");

        if Action = Action::Cancel then
            if Status in [Status::" ", Status::Canceled, Status::"Stamp Request Error", DocStatus::"Cancel In Progress"] then
                Error(Text010, SelectStr(Action + 1, Text013), TempSalesInvoiceHeader."Electronic Document Status");

        if Action in [EDocAction::CancelRequest, EDocAction::MarkAsCanceled] then
            if not (Status in [DocStatus::"Cancel Error", DocStatus::"Cancel In Progress"]) then
                Error(Text010, SelectStr(Action + 1, Text013), TempSalesInvoiceHeader."Electronic Document Status");

        if Action = EDocAction::ResetCancelRequest then
            if Status <> DocStatus::"Cancel In Progress" then
                Error(Text010, SelectStr(Action + 1, Text013), TempSalesInvoiceHeader."Electronic Document Status");
    end;

    procedure EDocPrintValidation(EDocStatus: Option " ","Stamp Received",Sent,Canceled,"Stamp Request Error","Cancel Error"; DocNo: Code[20])
    begin
        GetGLSetupOnce();
        if IsPACEnvironmentEnabled() and
           (EDocStatus in [EDocStatus::" ", EDocStatus::Canceled, EDocStatus::"Cancel Error", EDocStatus::"Stamp Request Error"])
        then
            if not Confirm(StrSubstNo(Text011, DocNo)) then
                Error('');
    end;

    local procedure RequestStamp(var DocumentHeaderRecordRef: RecordRef; Prepayment: Boolean; Reverse: Boolean)
    var
        TempDocumentHeader: Record "Document Header" temporary;
        TempDocumentLine: Record "Document Line" temporary;
        TempDocumentLineRetention: Record "Document Line" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        CFDIDocuments: Record "CFDI Documents";
        TempCFDIRelationDocument: Record "CFDI Relation Document" temporary;
        TempBlobOriginalString: Codeunit "Temp Blob";
        TempBlobDigitalStamp: Codeunit "Temp Blob";
        XMLDOMManagement: Codeunit "XML DOM Management";
        TypeHelper: Codeunit "Type Helper";
        RecordRef: RecordRef;
        OutStrOriginalDoc: OutStream;
        OutStrSignedDoc: OutStream;
        InStream: InStream;
        XMLDoc: DotNet XmlDocument;
        XMLDocResult: DotNet XmlDocument;
        SystemEnvironment: DotNet SystemEnvironment;
        OriginalString: Text;
        SignedString: Text;
        Certificate: Text;
        Response: Text;
        DateTimeFirstReqSent: Text[50];
        CertificateSerialNo: Text[250];
        UUID: Text[50];
        AdvanceSettle: Boolean;
        AdvanceAmount: Decimal;
        SalesInvoiceNumber: Code[20];
        SATCertificateCode: Code[20];
        SubTotal: Decimal;
        TotalTax: Decimal;
        TotalRetention: Decimal;
        TotalDiscount: Decimal;
        IsTransfer: Boolean;
    begin
        Export := true;

        case DocumentHeaderRecordRef.Number of
            DATABASE::"Sales Invoice Header":
                begin
                    DocumentHeaderRecordRef.SetTable(SalesInvoiceHeader);
                    if not Reverse then // If reverse, AdvanceSettle must be false else you fall into an infinite loop
                        AdvanceSettle := IsInvoicePrepaymentSettle(SalesInvoiceHeader."No.", AdvanceAmount);
                    if AdvanceSettle then
                        if GetUUIDFromOriginalPrepayment(SalesInvoiceHeader, SalesInvoiceNumber) = '' then
                            Error(UnableToStampAppliedErr, SalesInvoiceNumber);
                    CreateTempDocument(
                      SalesInvoiceHeader, TempDocumentHeader, TempDocumentLine, TempDocumentLineRetention, TempVATAmountLine,
                      SubTotal, TotalTax, TotalRetention, TotalDiscount, AdvanceSettle);
                    if not Reverse and not AdvanceSettle then
                        GetRelationDocumentsInvoice(TempCFDIRelationDocument, TempDocumentHeader, DATABASE::"Sales Invoice Header");
                    CheckSalesDocument(
                      SalesInvoiceHeader, TempDocumentHeader, TempDocumentLine, TempCFDIRelationDocument, SalesInvoiceHeader."Source Code", Prepayment);
                    DateTimeFirstReqSent := GetDateTimeOfFirstReqSalesInv(SalesInvoiceHeader);
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    DocumentHeaderRecordRef.SetTable(SalesCrMemoHeader);
                    CreateTempDocument(
                      SalesCrMemoHeader, TempDocumentHeader, TempDocumentLine, TempDocumentLineRetention, TempVATAmountLine,
                      SubTotal, TotalTax, TotalRetention, TotalDiscount, false);
                    GetRelationDocumentsCreditMemo(
                      TempCFDIRelationDocument, TempDocumentHeader, SalesCrMemoHeader."No.", DATABASE::"Sales Cr.Memo Header");
                    CheckSalesDocument(
                      SalesCrMemoHeader, TempDocumentHeader, TempDocumentLine, TempCFDIRelationDocument, SalesCrMemoHeader."Source Code", false);
                    DateTimeFirstReqSent := GetDateTimeOfFirstReqSalesCr(SalesCrMemoHeader);
                end;
            DATABASE::"Service Invoice Header":
                begin
                    DocumentHeaderRecordRef.SetTable(ServiceInvoiceHeader);
                    CreateTempDocument(
                      ServiceInvoiceHeader, TempDocumentHeader, TempDocumentLine, TempDocumentLineRetention, TempVATAmountLine,
                      SubTotal, TotalTax, TotalRetention, TotalDiscount, false);
                    if not Reverse and not AdvanceSettle then
                        GetRelationDocumentsInvoice(TempCFDIRelationDocument, TempDocumentHeader, DATABASE::"Service Invoice Header");
                    CheckSalesDocument(
                      ServiceInvoiceHeader, TempDocumentHeader, TempDocumentLine, TempCFDIRelationDocument, ServiceInvoiceHeader."Source Code", false);
                    DateTimeFirstReqSent := GetDateTimeOfFirstReqServInv(ServiceInvoiceHeader);
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    DocumentHeaderRecordRef.SetTable(ServiceCrMemoHeader);
                    CreateTempDocument(
                      ServiceCrMemoHeader, TempDocumentHeader, TempDocumentLine, TempDocumentLineRetention, TempVATAmountLine,
                      SubTotal, TotalTax, TotalRetention, TotalDiscount, false);
                    GetRelationDocumentsCreditMemo(
                      TempCFDIRelationDocument, TempDocumentHeader, ServiceCrMemoHeader."No.", DATABASE::"Service Cr.Memo Header");
                    CheckSalesDocument(
                      ServiceCrMemoHeader, TempDocumentHeader, TempDocumentLine, TempCFDIRelationDocument, ServiceCrMemoHeader."Source Code", false);
                    DateTimeFirstReqSent := GetDateTimeOfFirstReqServCr(ServiceCrMemoHeader);
                end;
            DATABASE::"Sales Shipment Header":
                begin
                    IsTransfer := true;
                    DocumentHeaderRecordRef.SetTable(SalesShipmentHeader);
                    CreateTempDocumentTransfer(SalesShipmentHeader, TempDocumentHeader, TempDocumentLine);
                    CheckTransferDocument(SalesShipmentHeader, TempDocumentHeader, TempDocumentLine);
                    if SalesShipmentHeader."Date/Time First Req. Sent" = '' then
                        SalesShipmentHeader."Date/Time First Req. Sent" :=
                          FormatAsDateTime(SalesShipmentHeader."Document Date", Time, GetTimeZoneFromDocument(SalesShipmentHeader));
                    DateTimeFirstReqSent := SalesShipmentHeader."Date/Time First Req. Sent";
                    SalesShipmentHeader."Identifier IdCCP" := TempDocumentHeader."Identifier IdCCP";
                end;
            DATABASE::"Transfer Shipment Header":
                begin
                    IsTransfer := true;
                    DocumentHeaderRecordRef.SetTable(TransferShipmentHeader);
                    CreateTempDocumentTransfer(TransferShipmentHeader, TempDocumentHeader, TempDocumentLine);
                    CheckTransferDocument(
                      TransferShipmentHeader, TempDocumentHeader, TempDocumentLine);
                    if TransferShipmentHeader."Date/Time First Req. Sent" = '' then
                        TransferShipmentHeader."Date/Time First Req. Sent" :=
                          FormatAsDateTime(TransferShipmentHeader."Posting Date", Time, GetTimeZoneFromDocument(TransferShipmentHeader));
                    DateTimeFirstReqSent := TransferShipmentHeader."Date/Time First Req. Sent";
                    TransferShipmentHeader."Identifier IdCCP" := TempDocumentHeader."Identifier IdCCP";
                end;
        end;

        Session.LogMessage(
            '0000C72', StrSubstNo(StampReqMsg, GetDocTypeTextFromDatabaseId(DocumentHeaderRecordRef.Number)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
        CurrencyDecimalPlaces := GetCurrencyDecimalPlaces(TempDocumentHeader."Currency Code");

        // Create Digital Stamp
        if IsTransfer then
            CreateOriginalStr33Transfer(TempDocumentHeader, TempDocumentLine, DateTimeFirstReqSent, TempBlobOriginalString)
        else
            if Reverse then begin
                UUID := SalesInvoiceHeader."Fiscal Invoice Number PAC";
                AdvanceAmount := GetAdvanceAmountFromSettledInvoice(SalesInvoiceHeader);
                CreateOriginalStr33AdvanceReverse(
                  TempDocumentHeader, DateTimeFirstReqSent, TempBlobOriginalString, UUID, AdvanceAmount);
            end else
                if Prepayment then
                    CreateOriginalStr33AdvancePayment(
                      TempDocumentHeader, TempDocumentLine, DateTimeFirstReqSent, SubTotal, TotalTax + TotalRetention,
                      TempBlobOriginalString)
                else
                    if not AdvanceSettle then
                        CreateOriginalStr33Document(
                          TempDocumentHeader, TempDocumentLine, TempDocumentLineRetention, TempCFDIRelationDocument, TempVATAmountLine,
                          DateTimeFirstReqSent,
                          DocumentHeaderRecordRef.Number in [DATABASE::"Sales Cr.Memo Header", DATABASE::"Service Cr.Memo Header"],
                          TempBlobOriginalString,
                          SubTotal, TotalTax, TotalRetention, TotalDiscount)
                    else begin
                        UUID := GetUUIDFromOriginalPrepayment(SalesInvoiceHeader, SalesInvoiceNumber);
                        CreateOriginalStr33AdvanceSettleDetailed(
                          TempDocumentHeader, TempDocumentLine, TempDocumentLineRetention, TempVATAmountLine,
                          DateTimeFirstReqSent, TempBlobOriginalString, UUID,
                          SubTotal, TotalTax, TotalRetention, TotalDiscount);
                    end;

        TempBlobOriginalString.CreateInStream(InStream);
        SystemEnvironment := SystemEnvironment.SystemEnvironment();
        OriginalString := TypeHelper.ReadAsTextWithSeparator(InStream, SystemEnvironment.NewLine());
        SATCertificateCode := GetSATCertificateCodeForDocument(DocumentHeaderRecordRef);
        CreateDigitalSignature(OriginalString, SATCertificateCode, SignedString, CertificateSerialNo, Certificate);
        TempBlobDigitalStamp.CreateOutStream(OutStrSignedDoc);
        OutStrSignedDoc.WriteText(SignedString);

        // Create Original XML
        if IsTransfer then
            CreateXMLDocument33Transfer(
              TempDocumentHeader, TempDocumentLine, DateTimeFirstReqSent, SignedString, Certificate, CertificateSerialNo, XMLDoc)
        else
            if Reverse then
                CreateXMLDocument33AdvanceReverse(
                  TempDocumentHeader, DateTimeFirstReqSent, SignedString,
                  Certificate, CertificateSerialNo, XMLDoc, UUID, AdvanceAmount)
            else
                if Prepayment then
                    CreateXMLDocument33AdvancePayment(
                      TempDocumentHeader, TempDocumentLine, DateTimeFirstReqSent, SignedString, Certificate, CertificateSerialNo,
                      XMLDoc, SubTotal, TotalTax + TotalRetention)
                else
                    if not AdvanceSettle then
                        CreateXMLDocument33(
                          TempDocumentHeader, TempDocumentLine, TempDocumentLineRetention, TempCFDIRelationDocument, TempVATAmountLine,
                          DateTimeFirstReqSent, SignedString, Certificate, CertificateSerialNo,
                          DocumentHeaderRecordRef.Number in [DATABASE::"Sales Cr.Memo Header", DATABASE::"Service Cr.Memo Header"], XMLDoc,
                          SubTotal, TotalTax, TotalRetention, TotalDiscount)
                    else
                        CreateXMLDocument33AdvanceSettle(
                          TempDocumentHeader, TempDocumentLine, TempDocumentLineRetention, TempVATAmountLine,
                          DateTimeFirstReqSent, SignedString, Certificate, CertificateSerialNo, XMLDoc, UUID,
                          SubTotal, TotalTax, TotalRetention, TotalDiscount);

        case DocumentHeaderRecordRef.Number of
            DATABASE::"Sales Invoice Header":
                if not Reverse then begin
                    RecordRef.GetTable(SalesInvoiceHeader);
                    TempBlobOriginalString.ToRecordRef(RecordRef, SalesInvoiceHeader.FieldNo("Original String"));
                    TempBlobDigitalStamp.ToRecordRef(RecordRef, SalesInvoiceHeader.FieldNo("Digital Stamp SAT"));
                    RecordRef.SetTable(SalesInvoiceHeader);
                    SalesInvoiceHeader."Certificate Serial No." := CertificateSerialNo;
                    SalesInvoiceHeader."Original Document XML".CreateOutStream(OutStrOriginalDoc);
                    SalesInvoiceHeader."Signed Document XML".CreateOutStream(OutStrSignedDoc);
                    XMLDoc.Save(OutStrOriginalDoc);
                    SalesInvoiceHeader.Modify();
                end else begin
                    if not CFDIDocuments.Get(SalesInvoiceHeader."No.", DATABASE::"Sales Invoice Header", true, true) then begin
                        CFDIDocuments.Init();
                        CFDIDocuments."No." := SalesInvoiceHeader."No.";
                        CFDIDocuments."Document Table ID" := DATABASE::"Sales Invoice Header";
                        CFDIDocuments.Prepayment := true;
                        CFDIDocuments.Reversal := true;
                        CFDIDocuments.Insert();
                    end;
                    RecordRef.GetTable(CFDIDocuments);
                    TempBlobOriginalString.ToRecordRef(RecordRef, SalesInvoiceHeader.FieldNo("Original String"));
                    TempBlobDigitalStamp.ToRecordRef(RecordRef, SalesInvoiceHeader.FieldNo("Digital Stamp SAT"));
                    RecordRef.SetTable(CFDIDocuments);
                    CFDIDocuments."Certificate Serial No." := CertificateSerialNo;
                    CFDIDocuments."Original Document XML".CreateOutStream(OutStrOriginalDoc);
                    CFDIDocuments."Signed Document XML".CreateOutStream(OutStrSignedDoc);
                    XMLDoc.Save(OutStrOriginalDoc);
                    SalesInvoiceHeader.Modify();
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    RecordRef.GetTable(SalesCrMemoHeader);
                    TempBlobOriginalString.ToRecordRef(RecordRef, SalesCrMemoHeader.FieldNo("Original String"));
                    TempBlobDigitalStamp.ToRecordRef(RecordRef, SalesCrMemoHeader.FieldNo("Digital Stamp SAT"));
                    RecordRef.SetTable(SalesCrMemoHeader);
                    SalesCrMemoHeader."Certificate Serial No." := CertificateSerialNo;
                    SalesCrMemoHeader."Original Document XML".CreateOutStream(OutStrOriginalDoc);
                    SalesCrMemoHeader."Signed Document XML".CreateOutStream(OutStrSignedDoc);
                    XMLDoc.Save(OutStrOriginalDoc);
                    SalesCrMemoHeader.Modify();
                end;
            DATABASE::"Service Invoice Header":
                begin
                    RecordRef.GetTable(ServiceInvoiceHeader);
                    TempBlobOriginalString.ToRecordRef(RecordRef, ServiceInvoiceHeader.FieldNo("Original String"));
                    TempBlobDigitalStamp.ToRecordRef(RecordRef, ServiceInvoiceHeader.FieldNo("Digital Stamp SAT"));
                    RecordRef.SetTable(ServiceInvoiceHeader);
                    ServiceInvoiceHeader."Certificate Serial No." := CertificateSerialNo;
                    ServiceInvoiceHeader."Original Document XML".CreateOutStream(OutStrOriginalDoc);
                    ServiceInvoiceHeader."Signed Document XML".CreateOutStream(OutStrSignedDoc);
                    XMLDoc.Save(OutStrOriginalDoc);
                    ServiceInvoiceHeader.Modify();
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    RecordRef.GetTable(ServiceCrMemoHeader);
                    TempBlobOriginalString.ToRecordRef(RecordRef, ServiceCrMemoHeader.FieldNo("Original String"));
                    TempBlobDigitalStamp.ToRecordRef(RecordRef, ServiceCrMemoHeader.FieldNo("Digital Stamp SAT"));
                    RecordRef.SetTable(ServiceCrMemoHeader);
                    ServiceCrMemoHeader."Certificate Serial No." := CertificateSerialNo;
                    ServiceCrMemoHeader."Original Document XML".CreateOutStream(OutStrOriginalDoc);
                    ServiceCrMemoHeader."Signed Document XML".CreateOutStream(OutStrSignedDoc);
                    XMLDoc.Save(OutStrOriginalDoc);
                    ServiceCrMemoHeader.Modify();
                end;
            DATABASE::"Sales Shipment Header":
                begin
                    RecordRef.GetTable(SalesShipmentHeader);
                    TempBlobOriginalString.ToRecordRef(RecordRef, SalesShipmentHeader.FieldNo("Original String"));
                    TempBlobDigitalStamp.ToRecordRef(RecordRef, SalesShipmentHeader.FieldNo("Digital Stamp SAT"));
                    RecordRef.SetTable(SalesShipmentHeader);
                    SalesShipmentHeader."Certificate Serial No." := CertificateSerialNo;
                    SalesShipmentHeader."Original Document XML".CreateOutStream(OutStrOriginalDoc);
                    SalesShipmentHeader."Signed Document XML".CreateOutStream(OutStrSignedDoc);
                    XMLDoc.Save(OutStrOriginalDoc);
                    SalesShipmentHeader.Modify();
                end;
            DATABASE::"Transfer Shipment Header":
                begin
                    RecordRef.GetTable(TransferShipmentHeader);
                    TempBlobOriginalString.ToRecordRef(RecordRef, TransferShipmentHeader.FieldNo("Original String"));
                    TempBlobDigitalStamp.ToRecordRef(RecordRef, TransferShipmentHeader.FieldNo("Digital Stamp SAT"));
                    RecordRef.SetTable(TransferShipmentHeader);
                    TransferShipmentHeader."Certificate Serial No." := CertificateSerialNo;
                    TransferShipmentHeader."Original Document XML".CreateOutStream(OutStrOriginalDoc);
                    TransferShipmentHeader."Signed Document XML".CreateOutStream(OutStrSignedDoc);
                    XMLDoc.Save(OutStrOriginalDoc);
                    TransferShipmentHeader.Modify();
                end;
        end;

        Commit();

        Response := InvokeMethod(XMLDoc, MethodTypeRef::"Request Stamp");

        // For Test Mocking
        if not GLSetup."Sim. Request Stamp" then begin
            if Reverse then begin
                XMLDOMManagement.LoadXMLDocumentFromText(Response, XMLDocResult);
                XMLDocResult.Save(OutStrSignedDoc);
                CFDIDocuments.Modify();
            end;
            if not Reverse then begin
                XMLDOMManagement.LoadXMLDocumentFromText(Response, XMLDocResult);
                XMLDocResult.Save(OutStrSignedDoc);
            end;
        end;

        case DocumentHeaderRecordRef.Number of
            DATABASE::"Sales Invoice Header":
                begin
                    ProcessResponseESalesInvoice(SalesInvoiceHeader, EDocAction::"Request Stamp", Reverse);
                    SalesInvoiceHeader.Modify();
                    DocumentHeaderRecordRef.GetTable(SalesInvoiceHeader);
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    ProcessResponseESalesCrMemo(SalesCrMemoHeader, EDocAction::"Request Stamp");
                    SalesCrMemoHeader.Modify();
                    DocumentHeaderRecordRef.GetTable(SalesCrMemoHeader);
                end;
            DATABASE::"Service Invoice Header":
                begin
                    ProcessResponseEServiceInvoice(ServiceInvoiceHeader, EDocAction::"Request Stamp", TempDocumentHeader."Amount Including VAT");
                    ServiceInvoiceHeader.Modify();
                    DocumentHeaderRecordRef.GetTable(ServiceInvoiceHeader);
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    ProcessResponseEServiceCrMemo(ServiceCrMemoHeader, EDocAction::"Request Stamp", TempDocumentHeader."Amount Including VAT");
                    ServiceCrMemoHeader.Modify();
                    DocumentHeaderRecordRef.GetTable(ServiceCrMemoHeader);
                end;
            DATABASE::"Sales Shipment Header":
                begin
                    ProcessResponseESalesShipment(SalesShipmentHeader, EDocAction::"Request Stamp");
                    SalesShipmentHeader.Modify();
                    DocumentHeaderRecordRef.GetTable(SalesShipmentHeader);
                end;
            DATABASE::"Transfer Shipment Header":
                begin
                    ProcessResponseETransferShipment(TransferShipmentHeader, EDocAction::"Request Stamp");
                    TransferShipmentHeader.Modify();
                    DocumentHeaderRecordRef.GetTable(TransferShipmentHeader);
                end;
        end;

        Session.LogMessage(
            '0000C73', StrSubstNo(StampReqSuccessMsg, GetDocTypeTextFromDatabaseId(DocumentHeaderRecordRef.Number)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);

        // If Advance Settle, and everything went well, then need to create CFDI document for Advance reverse.
        if AdvanceSettle then
            if SalesInvoiceHeader."Electronic Document Status" = SalesInvoiceHeader."Electronic Document Status"::"Stamp Received" then
                RequestStamp(DocumentHeaderRecordRef, true, true);

        OnAfterRequestStamp(DocumentHeaderRecordRef);
    end;

    [Scope('OnPrem')]
    procedure Send(var DocumentHeaderRecordRef: RecordRef; Reverse: Boolean)
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        case DocumentHeaderRecordRef.Number of
            DATABASE::"Sales Invoice Header":
                begin
                    DocumentHeaderRecordRef.SetTable(SalesInvHeader);
                    SendESalesInvoice(SalesInvHeader, Reverse);
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    DocumentHeaderRecordRef.SetTable(SalesCrMemoHeader);
                    SendESalesCrMemo(SalesCrMemoHeader);
                end;
            DATABASE::"Service Invoice Header":
                begin
                    DocumentHeaderRecordRef.SetTable(ServiceInvHeader);
                    SendEServiceInvoice(ServiceInvHeader);
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    DocumentHeaderRecordRef.SetTable(ServiceCrMemoHeader);
                    SendEServiceCrMemo(ServiceCrMemoHeader);
                end;
        end;
    end;

    local procedure SendESalesInvoice(var SalesInvHeader: Record "Sales Invoice Header"; Reverse: Boolean)
    var
        Customer: Record Customer;
        CFDIDocuments: Record "CFDI Documents";
        CFDIDocumentsLoc: Record "CFDI Documents";
        ReportSelection: Record "Report Selections";
        SalesInvHeaderLoc: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
        TempBlobPDF: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        DocumentHeaderRef: RecordRef;
        XMLInstream: InStream;
        FileNameEdoc: Text;
        FileNamePDF: Text;
    begin
        if Reverse then
            CFDIDocuments.Get(SalesInvHeader."No.", DATABASE::"Sales Invoice Header", true, true);

        GetCustomer(Customer, SalesInvHeader."Bill-to Customer No.", true);
        if not Reverse then
            if SalesInvHeader."No. of E-Documents Sent" <> 0 then
                if not Confirm(Text002) then
                    Error('');
        if Reverse then
            if CFDIDocuments."No. of E-Documents Sent" <> 0 then
                if not Confirm(PaymentsAlreadySentQst) then
                    Error('');

        Session.LogMessage(
            '0000C74', StrSubstNo(SendDocMsg, GetDocTypeTextFromDatabaseId(Database::"Sales Invoice Header")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);

        // Export XML
        if not Reverse then begin
            SalesInvHeader.CalcFields("Signed Document XML");
            TempBlob.FromRecord(SalesInvHeader, SalesInvHeader.FieldNo("Signed Document XML"));
            TempBlob.CreateInStream(XMLInstream);
            FileNameEdoc := SalesInvHeader."No." + '.xml';
        end else begin
            CFDIDocuments.CalcFields("Signed Document XML");
            TempBlob.FromRecord(CFDIDocuments, CFDIDocuments.FieldNo("Signed Document XML"));
            TempBlob.CreateInStream(XMLInstream);
            FileNameEdoc := CFDIDocuments."No." + '.xml';
            RecordRef.GetTable(CFDIDocumentsLoc);
            TempBlob.ToRecordRef(RecordRef, CFDIDocumentsLoc.FieldNo("Signed Document XML"));
            RecordRef.SetTable(CFDIDocumentsLoc);
        end;

        if GLSetup."Send PDF Report" then begin
            DocumentHeaderRef.GetTable(SalesInvHeader);
            ReportSelection.SetRange(Usage, ReportSelection.Usage::"S.Invoice");
            FileNamePDF := SaveAsPDFOnServer(TempBlobPDF, DocumentHeaderRef, GetReportNo(ReportSelection));
        end;

        // Reset No. Printed
        if not Reverse then begin
            SalesInvHeaderLoc.Get(SalesInvHeader."No.");
            SalesInvHeaderLoc."No. Printed" := SalesInvHeader."No. Printed";
            SalesInvHeaderLoc.Modify();
        end;

        // Send Email with Attachments
        SendEmail(TempBlobPDF, Customer."E-Mail", StrSubstNo(Text005, SalesInvHeader."No."),
          StrSubstNo(Text000, SalesInvHeader."No."), FileNameEdoc, FileNamePDF, XMLInstream);

        if not Reverse then begin
            SalesInvHeaderLoc.Get(SalesInvHeader."No.");
            SalesInvHeaderLoc."No. of E-Documents Sent" := SalesInvHeaderLoc."No. of E-Documents Sent" + 1;
            if not SalesInvHeaderLoc."Electronic Document Sent" then
                SalesInvHeaderLoc."Electronic Document Sent" := true;
            SalesInvHeaderLoc."Electronic Document Status" := SalesInvHeaderLoc."Electronic Document Status"::Sent;
            SalesInvHeaderLoc."Date/Time Sent" :=
              FormatDateTime(ConvertCurrentDateTimeToTimeZone(GetTimeZoneFromDocument(SalesInvHeader)));
            SalesInvHeaderLoc.Modify();
        end else begin
            CFDIDocumentsLoc.Get(SalesInvHeader."No.", DATABASE::"Sales Invoice Header", true, true);
            CFDIDocumentsLoc."No. of E-Documents Sent" := CFDIDocumentsLoc."No. of E-Documents Sent" + 1;
            if not CFDIDocumentsLoc."Electronic Document Sent" then
                CFDIDocumentsLoc."Electronic Document Sent" := true;
            CFDIDocumentsLoc."Electronic Document Status" := CFDIDocumentsLoc."Electronic Document Status"::Sent;
            CFDIDocumentsLoc."Date/Time Sent" :=
              FormatDateTime(ConvertCurrentDateTimeToTimeZone(GetTimeZoneFromDocument(SalesInvHeader)));
            CFDIDocumentsLoc.Modify();
        end;

        Message(Text001, SalesInvHeader."No.");
        Session.LogMessage(
            '0000C75', StrSubstNo(SendDocSuccessMsg, GetDocTypeTextFromDatabaseId(Database::"Sales Invoice Header")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
    end;

    local procedure SendESalesCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        Customer: Record Customer;
        ReportSelection: Record "Report Selections";
        SalesCrMemoHeaderLoc: Record "Sales Cr.Memo Header";
        TempBlobPDF: Codeunit "Temp Blob";
        DocumentHeaderRef: RecordRef;
        XMLInstream: InStream;
        FileNameEdoc: Text;
        FileNamePDF: Text;
    begin
        GetCustomer(Customer, SalesCrMemoHeader."Bill-to Customer No.", true);
        if SalesCrMemoHeader."No. of E-Documents Sent" <> 0 then
            if not Confirm(Text002) then
                Error('');

        Session.LogMessage(
            '0000C74', StrSubstNo(SendDocMsg, GetDocTypeTextFromDatabaseId(Database::"Sales Cr.Memo Header")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);

        // Export XML
        SalesCrMemoHeader.CalcFields("Signed Document XML");
        SalesCrMemoHeader."Signed Document XML".CreateInStream(XMLInstream);
        FileNameEdoc := SalesCrMemoHeader."No." + '.xml';

        if GLSetup."Send PDF Report" then begin
            DocumentHeaderRef.GetTable(SalesCrMemoHeader);
            ReportSelection.SetRange(Usage, ReportSelection.Usage::"S.Cr.Memo");
            FileNamePDF := SaveAsPDFOnServer(TempBlobPDF, DocumentHeaderRef, GetReportNo(ReportSelection));
        end;

        // Reset No. Printed
        SalesCrMemoHeaderLoc.Get(SalesCrMemoHeader."No.");
        SalesCrMemoHeaderLoc."No. Printed" := SalesCrMemoHeader."No. Printed";
        SalesCrMemoHeaderLoc.Modify();

        // Send Email with Attachments
        SendEmail(TempBlobPDF, Customer."E-Mail", StrSubstNo(Text006, SalesCrMemoHeader."No."),
            StrSubstNo(Text004, SalesCrMemoHeader."No."), FileNameEdoc, FileNamePDF, XMLInstream);

        SalesCrMemoHeaderLoc.Get(SalesCrMemoHeader."No.");
        SalesCrMemoHeaderLoc."No. of E-Documents Sent" := SalesCrMemoHeaderLoc."No. of E-Documents Sent" + 1;
        if not SalesCrMemoHeaderLoc."Electronic Document Sent" then
            SalesCrMemoHeaderLoc."Electronic Document Sent" := true;
        SalesCrMemoHeaderLoc."Electronic Document Status" := SalesCrMemoHeaderLoc."Electronic Document Status"::Sent;
        SalesCrMemoHeaderLoc."Date/Time Sent" :=
          FormatDateTime(ConvertCurrentDateTimeToTimeZone(GetTimeZoneFromDocument(SalesCrMemoHeader)));
        SalesCrMemoHeaderLoc.Modify();

        Message(Text001, SalesCrMemoHeader."No.");
        Session.LogMessage(
            '0000C75', StrSubstNo(SendDocSuccessMsg, GetDocTypeTextFromDatabaseId(Database::"Sales Cr.Memo Header")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
    end;

    local procedure SendEServiceInvoice(var ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        Customer: Record Customer;
        ReportSelection: Record "Report Selections";
        ServiceInvoiceHeaderLoc: Record "Service Invoice Header";
        TempBlobPDF: Codeunit "Temp Blob";
        DocumentHeaderRef: RecordRef;
        XMLInstream: InStream;
        FileNameEdoc: Text;
        FileNamePDF: Text;
    begin
        GetCustomer(Customer, ServiceInvoiceHeader."Bill-to Customer No.", true);
        if ServiceInvoiceHeader."No. of E-Documents Sent" <> 0 then
            if not Confirm(Text002) then
                Error('');

        Session.LogMessage(
            '0000C74', StrSubstNo(SendDocMsg, GetDocTypeTextFromDatabaseId(Database::"Service Invoice Header")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);

        // Export XML
        ServiceInvoiceHeader.CalcFields("Signed Document XML");
        ServiceInvoiceHeader."Signed Document XML".CreateInStream(XMLInstream);
        FileNameEdoc := ServiceInvoiceHeader."No." + '.xml';

        if GLSetup."Send PDF Report" then begin
            DocumentHeaderRef.GetTable(ServiceInvoiceHeader);
            ReportSelection.SetRange(Usage, ReportSelection.Usage::"SM.Invoice");
            FileNamePDF := SaveAsPDFOnServer(TempBlobPDF, DocumentHeaderRef, GetReportNo(ReportSelection));
        end;

        // Reset No. Printed
        ServiceInvoiceHeaderLoc.Get(ServiceInvoiceHeader."No.");
        ServiceInvoiceHeaderLoc."No. Printed" := ServiceInvoiceHeader."No. Printed";
        ServiceInvoiceHeaderLoc.Modify();

        // Send Email with Attachments
        SendEmail(TempBlobPDF, Customer."E-Mail", StrSubstNo(Text005, ServiceInvoiceHeader."No."),
            StrSubstNo(Text000, ServiceInvoiceHeader."No."), FileNameEdoc, FileNamePDF, XMLInstream);

        ServiceInvoiceHeaderLoc.Get(ServiceInvoiceHeader."No.");
        ServiceInvoiceHeaderLoc."No. of E-Documents Sent" := ServiceInvoiceHeaderLoc."No. of E-Documents Sent" + 1;
        if not ServiceInvoiceHeaderLoc."Electronic Document Sent" then
            ServiceInvoiceHeaderLoc."Electronic Document Sent" := true;
        ServiceInvoiceHeaderLoc."Electronic Document Status" := ServiceInvoiceHeaderLoc."Electronic Document Status"::Sent;
        ServiceInvoiceHeaderLoc."Date/Time Sent" :=
          FormatDateTime(ConvertCurrentDateTimeToTimeZone(GetTimeZoneFromDocument(ServiceInvoiceHeader)));
        ServiceInvoiceHeaderLoc.Modify();

        Message(Text001, ServiceInvoiceHeader."No.");
        Session.LogMessage(
            '0000C75', StrSubstNo(SendDocSuccessMsg, GetDocTypeTextFromDatabaseId(Database::"Service Invoice Header")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
    end;

    local procedure SendEServiceCrMemo(var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        Customer: Record Customer;
        ReportSelection: Record "Report Selections";
        ServiceCrMemoHeaderLoc: Record "Service Cr.Memo Header";
        TempBlobPDF: Codeunit "Temp Blob";
        DocumentHeaderRef: RecordRef;
        XMLInstream: InStream;
        FileNameEdoc: Text;
        FileNamePDF: Text;
    begin
        GetCustomer(Customer, ServiceCrMemoHeader."Bill-to Customer No.", true);
        if ServiceCrMemoHeader."No. of E-Documents Sent" <> 0 then
            if not Confirm(Text002) then
                Error('');

        Session.LogMessage(
            '0000C74', StrSubstNo(SendDocMsg, GetDocTypeTextFromDatabaseId(Database::"Service Cr.Memo Header")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);

        // Export XML
        ServiceCrMemoHeader.CalcFields("Signed Document XML");
        ServiceCrMemoHeader."Signed Document XML".CreateInStream(XMLInstream);
        FileNameEdoc := ServiceCrMemoHeader."No." + '.xml';

        if GLSetup."Send PDF Report" then begin
            DocumentHeaderRef.GetTable(ServiceCrMemoHeader);
            ReportSelection.SetRange(Usage, ReportSelection.Usage::"SM.Credit Memo");
            FileNamePDF := SaveAsPDFOnServer(TempBlobPDF, DocumentHeaderRef, GetReportNo(ReportSelection));
        end;

        // Reset No. Printed
        ServiceCrMemoHeaderLoc.Get(ServiceCrMemoHeader."No.");
        ServiceCrMemoHeaderLoc."No. Printed" := ServiceCrMemoHeader."No. Printed";
        ServiceCrMemoHeaderLoc.Modify();

        // Send Email with Attachments
        SendEmail(TempBlobPDF, Customer."E-Mail", StrSubstNo(Text006, ServiceCrMemoHeader."No."),
          StrSubstNo(Text004, ServiceCrMemoHeader."No."), FileNameEdoc, FileNamePDF, XMLInstream);

        ServiceCrMemoHeaderLoc.Get(ServiceCrMemoHeader."No.");
        ServiceCrMemoHeaderLoc."No. of E-Documents Sent" := ServiceCrMemoHeaderLoc."No. of E-Documents Sent" + 1;
        if not ServiceCrMemoHeaderLoc."Electronic Document Sent" then
            ServiceCrMemoHeaderLoc."Electronic Document Sent" := true;
        ServiceCrMemoHeaderLoc."Electronic Document Status" := ServiceCrMemoHeaderLoc."Electronic Document Status"::Sent;
        ServiceCrMemoHeaderLoc."Date/Time Sent" :=
          FormatDateTime(ConvertCurrentDateTimeToTimeZone(GetTimeZoneFromDocument(ServiceCrMemoHeader)));
        ServiceCrMemoHeaderLoc.Modify();

        Message(Text001, ServiceCrMemoHeader."No.");
        Session.LogMessage(
            '0000C75', StrSubstNo(SendDocSuccessMsg, GetDocTypeTextFromDatabaseId(Database::"Service Cr.Memo Header")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
    end;

    local procedure CancelESalesInvoice(var SalesInvHeader: Record "Sales Invoice Header"; MethodType: Option)
    var
        SalesInvoiceHeaderSubst: Record "Sales Invoice Header";
        DocumentRef: RecordRef;
        XMLDoc: DotNet XmlDocument;
        Response: Text;
        OutStr: OutStream;
    begin
        if SalesInvHeader."Source Code" = SourceCodeSetup."Deleted Document" then
            Error(Text007);

        Session.LogMessage(
            '0000C7C', StrSubstNo(CancelDocMsg, GetDocTypeTextFromDatabaseId(Database::"Sales Invoice Header")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);

        SalesInvHeader.TestField("CFDI Cancellation Reason Code");
        if CancellationReasonRequired(SalesInvHeader."CFDI Cancellation Reason Code") then
            SalesInvoiceHeaderSubst.Get(SalesInvHeader."Substitution Document No.");

        SalesInvHeader."Date/Time Cancel Sent" := ConvertCurrentDateTimeToTimeZone(GetTimeZoneFromDocument(SalesInvHeader));

        if GLSetup."Cancel on Time Expiration" and (SalesInvHeader."Date/Time Stamp Received" > GetDateTime24HoursAgo()) then begin
            DocumentRef.GetTable(SalesInvHeader);
            CancelDocumentManual(DocumentRef, false);
        end else begin
            SalesInvHeader."Original Document XML".CreateOutStream(OutStr);
            case MethodType of
                MethodTypeRef::Cancel:
                    CancelXMLDocument(
                      XMLDoc, OutStr,
                      FormatDateTime(SalesInvHeader."Date/Time Cancel Sent"), SalesInvHeader."Date/Time Stamped", SalesInvHeader."Fiscal Invoice Number PAC",
                      SalesInvHeader."CFDI Cancellation Reason Code", SalesInvoiceHeaderSubst."Fiscal Invoice Number PAC");
                MethodTypeRef::CancelRequest:
                    CancelStatusRequestXMLDocument(XMLDoc, OutStr, SalesInvHeader."CFDI Cancellation ID");
            end;
            Response := InvokeMethod(XMLDoc, MethodType);

            // For Test Mocking
            if not GLSetup."Sim. Request Stamp" then begin
                SalesInvHeader."Signed Document XML".CreateOutStream(OutStr);
                OutStr.WriteText(Response);
            end;

            SalesInvHeader.Modify();
            case MethodType of
                MethodTypeRef::Cancel:
                    ProcessResponseESalesInvoice(SalesInvHeader, EDocAction::Cancel, false);
                MethodTypeRef::CancelRequest:
                    ProcessResponseESalesInvoice(SalesInvHeader, EDocAction::CancelRequest, false);
            end;
            SalesInvHeader.Modify();
        end;

        Session.LogMessage(
            '0000C7D', StrSubstNo(CancelDocSuccessMsg, GetDocTypeTextFromDatabaseId(Database::"Sales Invoice Header")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
    end;

    local procedure CancelESalesCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; MethodType: Option)
    var
        SalesCrMemoHeaderSubst: Record "Sales Cr.Memo Header";
        DocumentRef: RecordRef;
        XMLDoc: DotNet XmlDocument;
        Response: Text;
        OutStr: OutStream;
    begin
        if SalesCrMemoHeader."Source Code" = SourceCodeSetup."Deleted Document" then
            Error(Text007);

        Session.LogMessage(
            '0000C7C', StrSubstNo(CancelDocMsg, GetDocTypeTextFromDatabaseId(Database::"Sales Cr.Memo Header")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);

        SalesCrMemoHeader.TestField("CFDI Cancellation Reason Code");
        if CancellationReasonRequired(SalesCrMemoHeader."CFDI Cancellation Reason Code") then
            SalesCrMemoHeaderSubst.Get(SalesCrMemoHeader."Substitution Document No.");

        SalesCrMemoHeader."Date/Time Cancel Sent" := ConvertCurrentDateTimeToTimeZone(GetTimeZoneFromDocument(SalesCrMemoHeader));

        if GLSetup."Cancel on Time Expiration" and (SalesCrMemoHeader."Date/Time Stamp Received" > GetDateTime24HoursAgo()) then begin
            DocumentRef.GetTable(SalesCrMemoHeader);
            CancelDocumentManual(DocumentRef, false);
        end else begin
            SalesCrMemoHeader."Original Document XML".CreateOutStream(OutStr);

            case MethodType of
                MethodTypeRef::Cancel:
                    CancelXMLDocument(
                      XMLDoc, OutStr,
                      FormatDateTime(SalesCrMemoHeader."Date/Time Cancel Sent"), SalesCrMemoHeader."Date/Time Stamped", SalesCrMemoHeader."Fiscal Invoice Number PAC",
                      SalesCrMemoHeader."CFDI Cancellation Reason Code", SalesCrMemoHeaderSubst."Fiscal Invoice Number PAC");
                MethodTypeRef::CancelRequest:
                    CancelStatusRequestXMLDocument(XMLDoc, OutStr, SalesCrMemoHeader."CFDI Cancellation ID");
            end;
            Response := InvokeMethod(XMLDoc, MethodType);

            // For Test Mocking
            if not GLSetup."Sim. Request Stamp" then begin
                SalesCrMemoHeader."Signed Document XML".CreateOutStream(OutStr);
                OutStr.WriteText(Response);
            end;

            SalesCrMemoHeader.Modify();
            case MethodType of
                MethodTypeRef::Cancel:
                    ProcessResponseESalesCrMemo(SalesCrMemoHeader, EDocAction::Cancel);
                MethodTypeRef::CancelRequest:
                    ProcessResponseESalesCrMemo(SalesCrMemoHeader, EDocAction::CancelRequest);
            end;
            SalesCrMemoHeader.Modify();
        end;

        Session.LogMessage(
            '0000C7D', StrSubstNo(CancelDocSuccessMsg, GetDocTypeTextFromDatabaseId(Database::"Sales Cr.Memo Header")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
    end;

    local procedure CancelEServiceInvoice(var ServiceInvHeader: Record "Service Invoice Header"; MethodType: Option)
    var
        ServiceInvoiceHeaderSubst: Record "Service Invoice Header";
        DocumentRef: RecordRef;
        XMLDoc: DotNet XmlDocument;
        Response: Text;
        OutStr: OutStream;
    begin
        if ServiceInvHeader."Source Code" = SourceCodeSetup."Deleted Document" then
            Error(Text007);

        Session.LogMessage(
            '0000C7C', StrSubstNo(CancelDocMsg, GetDocTypeTextFromDatabaseId(Database::"Service Invoice Header")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);

        ServiceInvHeader.TestField("CFDI Cancellation Reason Code");
        if CancellationReasonRequired(ServiceInvHeader."CFDI Cancellation Reason Code") then
            ServiceInvoiceHeaderSubst.Get(ServiceInvHeader."Substitution Document No.");

        ServiceInvHeader."Date/Time Cancel Sent" := ConvertCurrentDateTimeToTimeZone(GetTimeZoneFromDocument(ServiceInvHeader));

        if GLSetup."Cancel on Time Expiration" and (ServiceInvHeader."Date/Time Stamp Received" > GetDateTime24HoursAgo()) then begin
            DocumentRef.GetTable(ServiceInvHeader);
            CancelDocumentManual(DocumentRef, false);
        end else begin
            ServiceInvHeader."Original Document XML".CreateOutStream(OutStr);
            case MethodType of
                MethodTypeRef::Cancel:
                    CancelXMLDocument(
                      XMLDoc, OutStr,
                      FormatDateTime(ServiceInvHeader."Date/Time Cancel Sent"), ServiceInvHeader."Date/Time Stamped", ServiceInvHeader."Fiscal Invoice Number PAC",
                      ServiceInvHeader."CFDI Cancellation Reason Code", ServiceInvoiceHeaderSubst."Substitution Document No.");
                MethodTypeRef::CancelRequest:
                    CancelStatusRequestXMLDocument(XMLDoc, OutStr, ServiceInvHeader."CFDI Cancellation ID");
            end;
            Response := InvokeMethod(XMLDoc, MethodType);

            // For Test Mocking
            if not GLSetup."Sim. Request Stamp" then begin
                ServiceInvHeader."Signed Document XML".CreateOutStream(OutStr);
                OutStr.WriteText(Response);
            end;

            ServiceInvHeader.Modify();
            case MethodType of
                MethodTypeRef::Cancel:
                    ProcessResponseEServiceInvoice(ServiceInvHeader, EDocAction::Cancel, 0);
                MethodTypeRef::CancelRequest:
                    ProcessResponseEServiceInvoice(ServiceInvHeader, EDocAction::CancelRequest, 0);
            end;
            ServiceInvHeader.Modify();
        end;

        Session.LogMessage(
            '0000C7D', StrSubstNo(CancelDocSuccessMsg, GetDocTypeTextFromDatabaseId(Database::"Service Invoice Header")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
    end;

    local procedure CancelEServiceCrMemo(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; MethodType: Option)
    var
        ServiceCrMemoHeaderSubst: Record "Service Cr.Memo Header";
        DocumentRef: RecordRef;
        XMLDoc: DotNet XmlDocument;
        Response: Text;
        OutStr: OutStream;
    begin
        if ServiceCrMemoHeader."Source Code" = SourceCodeSetup."Deleted Document" then
            Error(Text007);

        Session.LogMessage(
            '0000C7C', StrSubstNo(CancelDocMsg, GetDocTypeTextFromDatabaseId(Database::"Service Cr.Memo Header")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);

        ServiceCrMemoHeader.TestField("CFDI Cancellation Reason Code");
        if CancellationReasonRequired(ServiceCrMemoHeader."CFDI Cancellation Reason Code") then
            ServiceCrMemoHeaderSubst.Get(ServiceCrMemoHeader."Substitution Document No.");

        ServiceCrMemoHeader."Date/Time Cancel Sent" := ConvertCurrentDateTimeToTimeZone(GetTimeZoneFromDocument(ServiceCrMemoHeader));

        if GLSetup."Cancel on Time Expiration" and (ServiceCrMemoHeader."Date/Time Stamp Received" > GetDateTime24HoursAgo()) then begin
            DocumentRef.GetTable(ServiceCrMemoHeader);
            CancelDocumentManual(DocumentRef, false);
        end else begin
            ServiceCrMemoHeader."Original Document XML".CreateOutStream(OutStr);
            case MethodType of
                MethodTypeRef::Cancel:
                    CancelXMLDocument(
                      XMLDoc, OutStr,
                      FormatDateTime(ServiceCrMemoHeader."Date/Time Cancel Sent"), ServiceCrMemoHeader."Date/Time Stamped", ServiceCrMemoHeader."Fiscal Invoice Number PAC",
                      ServiceCrMemoHeader."CFDI Cancellation Reason Code", ServiceCrMemoHeaderSubst."Fiscal Invoice Number PAC");
                MethodTypeRef::CancelRequest:
                    CancelStatusRequestXMLDocument(XMLDoc, OutStr, ServiceCrMemoHeader."CFDI Cancellation ID");
            end;
            Response := InvokeMethod(XMLDoc, MethodType);

            // For Test Mocking
            if not GLSetup."Sim. Request Stamp" then begin
                ServiceCrMemoHeader."Signed Document XML".CreateOutStream(OutStr);
                OutStr.WriteText(Response);
            end;

            ServiceCrMemoHeader.Modify();
            case MethodType of
                MethodTypeRef::Cancel:
                    ProcessResponseEServiceCrMemo(ServiceCrMemoHeader, EDocAction::Cancel, 0);
                MethodTypeRef::CancelRequest:
                    ProcessResponseEServiceCrMemo(ServiceCrMemoHeader, EDocAction::CancelRequest, 0);
            end;
            ServiceCrMemoHeader.Modify();
        end;

        Session.LogMessage(
            '0000C7D', StrSubstNo(CancelDocSuccessMsg, GetDocTypeTextFromDatabaseId(Database::"Service Cr.Memo Header")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
    end;

    local procedure CancelESalesShipment(var SalesShipmentHeader: Record "Sales Shipment Header"; MethodType: Option)
    var
        SalesShipmentHeaderSubst: Record "Sales Shipment Header";
        DocumentRef: RecordRef;
        XMLDoc: DotNet XmlDocument;
        Response: Text;
        OutStr: OutStream;
    begin
        SalesShipmentHeader.TestField("CFDI Cancellation Reason Code");
        if CancellationReasonRequired(SalesShipmentHeader."CFDI Cancellation Reason Code") then
            SalesShipmentHeaderSubst.Get(SalesShipmentHeader."Substitution Document No.");

        SalesShipmentHeader."Date/Time Cancel Sent" := ConvertCurrentDateTimeToTimeZone(GetTimeZoneFromDocument(SalesShipmentHeader));

        if GLSetup."Cancel on Time Expiration" and (SalesShipmentHeader."Date/Time Stamp Received" > GetDateTime24HoursAgo()) then begin
            DocumentRef.GetTable(SalesShipmentHeader);
            CancelDocumentManual(DocumentRef, false);
        end else begin
            SalesShipmentHeader."Original Document XML".CreateOutStream(OutStr);
            case MethodType of
                MethodTypeRef::Cancel:
                    CancelXMLDocument(
                      XMLDoc, OutStr,
                      FormatDateTime(SalesShipmentHeader."Date/Time Cancel Sent"), SalesShipmentHeader."Date/Time Stamped", SalesShipmentHeader."Fiscal Invoice Number PAC",
                      SalesShipmentHeader."CFDI Cancellation Reason Code", SalesShipmentHeader."Fiscal Invoice Number PAC");
                MethodTypeRef::CancelRequest:
                    CancelStatusRequestXMLDocument(XMLDoc, OutStr, SalesShipmentHeader."CFDI Cancellation ID");
            end;
            Response := InvokeMethod(XMLDoc, MethodType);

            // For Test Mocking
            if not GLSetup."Sim. Request Stamp" then begin
                SalesShipmentHeader."Signed Document XML".CreateOutStream(OutStr, TextEncoding::UTF8);
                OutStr.WriteText(Response);
            end;

            SalesShipmentHeader.Modify();
            case MethodType of
                MethodTypeRef::Cancel:
                    ProcessResponseESalesShipment(SalesShipmentHeader, EDocAction::Cancel);
                MethodTypeRef::CancelRequest:
                    ProcessResponseESalesShipment(SalesShipmentHeader, EDocAction::CancelRequest);
            end;
            SalesShipmentHeader.Modify();
        end;
    end;

    local procedure CancelETransferShipment(var TransferShipmentHeader: Record "Transfer Shipment Header"; MethodType: Option)
    var
        TransferShipmentHeaderSubst: Record "Transfer Shipment Header";
        DocumentRef: RecordRef;
        XMLDoc: DotNet XmlDocument;
        Response: Text;
        OutStr: OutStream;
    begin
        TransferShipmentHeader.TestField("CFDI Cancellation Reason Code");
        if CancellationReasonRequired(TransferShipmentHeader."CFDI Cancellation Reason Code") then
            TransferShipmentHeaderSubst.Get(TransferShipmentHeader."Substitution Document No.");

        TransferShipmentHeader."Date/Time Cancel Sent" := ConvertCurrentDateTimeToTimeZone(GetTimeZoneFromDocument(TransferShipmentHeader));

        if GLSetup."Cancel on Time Expiration" and (TransferShipmentHeader."Date/Time Stamp Received" > GetDateTime24HoursAgo()) then begin
            DocumentRef.GetTable(TransferShipmentHeader);
            CancelDocumentManual(DocumentRef, false);
        end else begin
            TransferShipmentHeader."Original Document XML".CreateOutStream(OutStr);
            case MethodType of
                MethodTypeRef::Cancel:
                    CancelXMLDocument(
                      XMLDoc, OutStr,
                       FormatDateTime(TransferShipmentHeader."Date/Time Cancel Sent"), TransferShipmentHeader."Date/Time Stamped", TransferShipmentHeader."Fiscal Invoice Number PAC",
                      TransferShipmentHeader."CFDI Cancellation Reason Code", TransferShipmentHeader."Fiscal Invoice Number PAC");
                MethodTypeRef::CancelRequest:
                    CancelStatusRequestXMLDocument(XMLDoc, OutStr, TransferShipmentHeader."CFDI Cancellation ID");
            end;
            Response := InvokeMethod(XMLDoc, MethodType);

            // For Test Mocking
            if not GLSetup."Sim. Request Stamp" then begin
                TransferShipmentHeader."Signed Document XML".CreateOutStream(OutStr, TextEncoding::UTF8);
                OutStr.WriteText(Response);
            end;

            TransferShipmentHeader.Modify();
            case MethodType of
                MethodTypeRef::Cancel:
                    ProcessResponseETransferShipment(TransferShipmentHeader, EDocAction::Cancel);
                MethodTypeRef::CancelRequest:
                    ProcessResponseETransferShipment(TransferShipmentHeader, EDocAction::CancelRequest);
            end;
            TransferShipmentHeader.Modify();
        end;
    end;

    local procedure CancelEPayment(var CustLedgerEntry: Record "Cust. Ledger Entry"; MethodType: Option)
    var
        CustLedgerEntrySubst: Record "Cust. Ledger Entry";
        DocumentRef: RecordRef;
        OutStr: OutStream;
        XMLDoc: DotNet XmlDocument;
        Response: Text;
    begin
        Session.LogMessage(
            '0000C7C', StrSubstNo(CancelDocMsg, GetDocTypeTextFromDatabaseId(Database::"Cust. Ledger Entry")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);

        CustLedgerEntry.TestField("CFDI Cancellation Reason Code");
        if CancellationReasonRequired(CustLedgerEntry."CFDI Cancellation Reason Code") then
            CustLedgerEntrySubst.Get(CustLedgerEntry."Substitution Entry No.");

        CustLedgerEntry."Date/Time Cancel Sent" := ConvertCurrentDateTimeToTimeZone(GetTimeZoneFromCustomer(CustLedgerEntry."Customer No."));

        if GLSetup."Cancel on time expiration" and (CustLedgerEntry."Date/Time Stamp Received" > GetDateTime24HoursAgo()) then begin
            DocumentRef.GetTable(CustLedgerEntry);
            CancelDocumentManual(DocumentRef, false);
        end else begin
            CustLedgerEntry."Original Document XML".CreateOutStream(OutStr);
            case MethodType of
                MethodTypeRef::Cancel:
                    CancelXMLDocument(
                      XMLDoc, OutStr,
                      FormatDateTime(CustLedgerEntry."Date/Time Cancel Sent"), CustLedgerEntry."Date/Time Stamped", CustLedgerEntry."Fiscal Invoice Number PAC",
                      CustLedgerEntry."CFDI Cancellation Reason Code", CustLedgerEntrySubst."Fiscal Invoice Number PAC");
                MethodTypeRef::CancelRequest:
                    CancelStatusRequestXMLDocument(XMLDoc, OutStr, CustLedgerEntry."CFDI Cancellation ID");
            end;
            Response := InvokeMethod(XMLDoc, MethodType);

            // For Test Mocking
            if not GLSetup."Sim. Request Stamp" then begin
                CustLedgerEntry."Signed Document XML".CreateOutStream(OutStr);
                OutStr.WriteText(Response);
            end;

            CustLedgerEntry.Modify();
            case MethodType of
                MethodTypeRef::Cancel:
                    ProcessResponseEPayment(CustLedgerEntry, EDocAction::Cancel);
                MethodTypeRef::CancelRequest:
                    ProcessResponseEPayment(CustLedgerEntry, EDocAction::CancelRequest);
            end;
            CustLedgerEntry.Modify();
        end;

        Session.LogMessage(
            '0000C7D', StrSubstNo(CancelDocSuccessMsg, GetDocTypeTextFromDatabaseId(Database::"Cust. Ledger Entry")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
    end;

    local procedure CancelDocumentManual(var RecRef: RecordRef; MarkAsCanceled: Boolean)
    var
        FieldRef: FieldRef;
        Status: Option " ","Stamp Received",Sent,Canceled,"Stamp Request Error","Cancel Error","Cancel In Progress";
        DateTimeCancelSent: DateTime;
    begin
        FieldRef := RecRef.Field(GetFieldIDElectronicDocumentStatus()); // "Electronic Document Status" (Option)
        FieldRef.Value := Status::Canceled;
        DateTimeCancelSent := ConvertCurrentDateTimeToTimeZone(GetTimeZoneFromDocument(RecRef));
        FieldRef := RecRef.Field(GetFieldIDDateTimeCancelSent()); // "Date/Time Cancel Sent" (DateTime)
        FieldRef.Value := DateTimeCancelSent;
        FieldRef := RecRef.Field(GetFieldIDDateTimeCancelled()); // "Date/Time Canceled" (Text)
        FieldRef.Value := FormatDateTime(DateTimeCancelSent);
        if MarkAsCanceled then begin
            FieldRef := RecRef.Field(GetFieldIDMarkedAsCanceled()); // "Marked as Canceled" (Boolean)
            FieldRef.Value := true;
        end;
        RecRef.Modify();
    end;

    local procedure ResetCancellationRequest(var RecRef: RecordRef)
    var
        FieldRef: FieldRef;
        Status: Option " ","Stamp Received",Sent,Canceled,"Stamp Request Error","Cancel Error","Cancel In Progress";
    begin
        FieldRef := RecRef.Field(GetFieldIDElectronicDocumentStatus());
        FieldRef.Value := Status::"Cancel Error";
        FieldRef := RecRef.Field(GetFieldIDDateTimeCancelSent());
        FieldRef.Value := 0DT;
        FieldRef := RecRef.Field(GetFieldIDDateTimeCanceled());
        FieldRef.Value := '';
        RecRef.Modify();

        Session.LogMessage(
            '0000M81', StrSubstNo(ResetCancellationRequestErr, GetDocTypeTextFromDatabaseId(RecRef.Number)), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
    end;

    local procedure CancelXMLDocument(var XMLDoc: DotNet XmlDocument; var OutStr: OutStream; CancelDateTime: Text[50]; DateTimeStamped: Text; FiscalinvoiceNumberPAC: Text; CancellationReason: Text; SubstitutionDocumentUUID: Text)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLCurrNode: DotNet XmlNode;
        XMLNewChild: DotNet XmlNode;
    begin
        // Create instance
        if IsNull(XMLDoc) then
            XMLDoc := XMLDoc.XmlDocument();

        DocNameSpace := 'http://www.sat.gob.mx/sitio_internet/cfd';
        XMLDOMManagement.LoadXMLDocumentFromText('<?xml version="1.0" encoding="UTF-8" ?> <CancelaCFD /> ', XMLDoc);
        XMLCurrNode := XMLDoc.DocumentElement;
        AddElement(XMLCurrNode, 'Cancelacion', '', '', XMLNewChild);
        XMLCurrNode := XMLNewChild;

        AddAttribute(XMLDoc, XMLCurrNode, 'Fecha', CancelDateTime);
        AddAttribute(XMLDoc, XMLCurrNode, 'RfcEmisor', CompanyInfo."RFC Number");
        AddElement(XMLCurrNode, 'Folios', '', '', XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddElement(XMLCurrNode, 'Folio', '', '', XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddAttribute(XMLDoc, XMLCurrNode, 'FechaTimbrado', DateTimeStamped);
        AddAttribute(XMLDoc, XMLCurrNode, 'UUID', FiscalinvoiceNumberPAC);
        AddAttribute(XMLDoc, XMLCurrNode, 'MotivoCancelacion', CancellationReason);
        AddAttribute(XMLDoc, XMLCurrNode, 'FolioSustitucion', SubstitutionDocumentUUID);
        XMLDoc.Save(OutStr);
    end;

    local procedure CancelStatusRequestXMLDocument(var XMLDoc: DotNet XmlDocument; var OutStr: OutStream; CFDICancellationID: Text)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLCurrNode: DotNet XmlNode;
    begin
        // Create instance
        if IsNull(XMLDoc) then
            XMLDoc := XMLDoc.XmlDocument();

        DocNameSpace := 'http://www.sat.gob.mx/sitio_internet/cfd';
        XMLDOMManagement.LoadXMLDocumentFromText('<?xml version="1.0" encoding="UTF-8" ?> <ConsultaCancelacion /> ', XMLDoc);
        XMLCurrNode := XMLDoc.DocumentElement;
        AddAttribute(XMLDoc, XMLCurrNode, 'RfcEmisor', CompanyInfo."RFC Number");
        AddAttribute(XMLDoc, XMLCurrNode, 'ConsultaCancelacionId', CFDICancellationID);
        XMLDoc.Save(OutStr);
    end;

    local procedure ProcessResponseESalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; "Action": Option; Reverse: Boolean)
    var
        Customer: Record Customer;
        CFDIDocuments: Record "CFDI Documents";
        PACWebService: Record "PAC Web Service";
        TempBlob: Codeunit "Temp Blob";
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLDoc: DotNet XmlDocument;
        XMLDocResult: DotNet XmlDocument;
        XMLCurrNode: DotNet XmlNode;
        XMLDOMNamedNodeMap: DotNet XmlNamedNodeMap;
        XMLDOMNodeList: DotNet XmlNodeList;
        NamespaceManager: DotNet XmlNamespaceManager;
        RecordRef: RecordRef;
        OutStr: OutStream;
        InStr: InStream;
        NodeCount: Integer;
        Counter: Integer;
        QRCodeInput: Text;
        ErrorDescription: Text;
        TelemetryError: Text;
        CancelStatus: Option InProgress,Rejected,Cancelled;
        CancelResult: Text[250];
        DocumentStatus: Option " ","Stamp Received",Sent,Canceled,"Stamp Request Error","Cancel Error","Cancel In Progress";
        DateTimeCancelled: Text[50];
    begin
        GetGLSetup();
        GetCompanyInfo();
        GetCustomer(Customer, SalesInvoiceHeader."Bill-to Customer No.", false);

        // Process Response and Load back to header the Signed XML if you get one...
        if IsNull(XMLDocResult) then
            XMLDocResult := XMLDocResult.XmlDocument();

        if not Reverse then begin
            SalesInvoiceHeader.CalcFields("Signed Document XML");
            SalesInvoiceHeader."Signed Document XML".CreateInStream(InStr);
            XMLDOMManagement.LoadXMLDocumentFromInStream(InStr, XMLDocResult);
            Clear(SalesInvoiceHeader."Signed Document XML");
        end else begin
            CFDIDocuments.Get(SalesInvoiceHeader."No.", DATABASE::"Sales Invoice Header", true, true);
            CFDIDocuments.CalcFields("Signed Document XML");
            CFDIDocuments."Signed Document XML".CreateInStream(InStr);
            XMLDOMManagement.LoadXMLDocumentFromInStream(InStr, XMLDocResult);
            Clear(CFDIDocuments."Signed Document XML");
        end;

        XMLCurrNode := XMLDocResult.SelectSingleNode('Resultado');

        XMLDOMNamedNodeMap := XMLCurrNode.Attributes;
        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('IdRespuesta');

        PACWebService.Get(GLSetup."PAC Code");

        if not Reverse then
            SalesInvoiceHeader."PAC Web Service Name" := PACWebService.Name
        else
            CFDIDocuments."PAC Web Service Name" := PACWebService.Name;

        if XMLCurrNode.Value <> '1' then begin // Error encountered
            if not Reverse then begin
                SalesInvoiceHeader."Error Code" := XMLCurrNode.Value();
                XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('Descripcion');
                ErrorDescription := XMLCurrNode.Value();
                XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('Detalle');
                if not IsNull(XMLCurrNode) then
                    ErrorDescription := ErrorDescription + ': ' + XMLCurrNode.Value();
                TelemetryError := ErrorDescription;
                if StrLen(ErrorDescription) > 250 then
                    ErrorDescription := CopyStr(ErrorDescription, 1, 247) + '...';
                SalesInvoiceHeader."Error Description" := CopyStr(ErrorDescription, 1, 250);
                case Action of
                    EDocAction::"Request Stamp":
                        SalesInvoiceHeader."Electronic Document Status" :=
                          SalesInvoiceHeader."Electronic Document Status"::"Stamp Request Error";
                    EDocAction::Cancel:
                        begin
                            SalesInvoiceHeader."Electronic Document Status" :=
                              SalesInvoiceHeader."Electronic Document Status"::"Cancel Error";
                            SalesInvoiceHeader."Date/Time Canceled" := '';
                        end;
                end;
            end else begin
                CFDIDocuments."Error Code" := XMLCurrNode.Value();
                XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('Descripcion');
                ErrorDescription := XMLCurrNode.Value();
                XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('Detalle');
                if not IsNull(XMLCurrNode) then
                    ErrorDescription := ErrorDescription + ': ' + XMLCurrNode.Value();
                TelemetryError := ErrorDescription;
                if StrLen(ErrorDescription) > 250 then
                    ErrorDescription := CopyStr(ErrorDescription, 1, 247) + '...';
                CFDIDocuments."Error Description" := CopyStr(ErrorDescription, 1, 250);
                case Action of
                    EDocAction::"Request Stamp":
                        CFDIDocuments."Electronic Document Status" := CFDIDocuments."Electronic Document Status"::"Stamp Request Error";
                end;
                CFDIDocuments.Modify();
            end;

            Session.LogMessage(
                '0000C7M', StrSubstNo(ProcessResponseErr, GetDocTypeTextFromDatabaseId(Database::"Sales Invoice Header"), TelemetryError), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);

            exit;
        end;

        if not Reverse then begin
            SalesInvoiceHeader."Error Code" := '';
            SalesInvoiceHeader."Error Description" := '';
            if Action = EDocAction::Cancel then begin
                SalesInvoiceHeader."Electronic Document Status" := SalesInvoiceHeader."Electronic Document Status"::"Cancel In Progress";
                SalesInvoiceHeader."CFDI Cancellation ID" := GetResponseValueCancellationID(XMLCurrNode, XMLDOMNamedNodeMap);
                exit;
            end;
            if Action = EDocAction::CancelRequest then begin
                ProcessCancelResponse(XMLDocResult, XMLCurrNode, XMLDOMNamedNodeMap, CancelStatus, CancelResult, DateTimeCancelled);
                GetDocumentStatusFromCancelStatus(DocumentStatus, CancelStatus);
                SalesInvoiceHeader."Electronic Document Status" := DocumentStatus;
                SalesInvoiceHeader."Error Description" := CancelResult;
                SalesInvoiceHeader."Date/Time Canceled" := DateTimeCancelled;
                exit;
            end;
        end else begin
            CFDIDocuments."Error Code" := '';
            CFDIDocuments."Error Description" := '';
        end;

        XMLCurrNode := XMLDocResult.SelectSingleNode('Resultado');
        XMLDOMNodeList := XMLCurrNode.ChildNodes;
        NodeCount := XMLDOMNodeList.Count();

        Clear(XMLDoc);
        XMLDoc := XMLDoc.XmlDocument();
        for Counter := 0 to (NodeCount - 1) do begin
            XMLCurrNode := XMLDOMNodeList.Item(Counter);
            XMLDoc.AppendChild(XMLDoc.ImportNode(XMLCurrNode, true));
        end;

        if not Reverse then
            SalesInvoiceHeader."Signed Document XML".CreateOutStream(OutStr)
        else
            CFDIDocuments."Signed Document XML".CreateOutStream(OutStr);

        XMLDoc.Save(OutStr);

        NamespaceManager := NamespaceManager.XmlNamespaceManager(XMLDoc.NameTable);
        NamespaceManager.AddNamespace('cfdi', 'http://www.sat.gob.mx/cfd/4');
        NamespaceManager.AddNamespace('tfd', 'http://www.sat.gob.mx/TimbreFiscalDigital');
        XMLCurrNode := XMLDoc.SelectSingleNode('cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital', NamespaceManager);
        XMLDOMNamedNodeMap := XMLCurrNode.Attributes;

        if not Reverse then begin
            XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('FechaTimbrado');
            SalesInvoiceHeader."Date/Time Stamped" := XMLCurrNode.Value();
            SalesInvoiceHeader."Date/Time Stamp Received" := ConvertStingToDateTime(SalesInvoiceHeader."Date/Time Stamped");

            XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('UUID');
            SalesInvoiceHeader."Fiscal Invoice Number PAC" := XMLCurrNode.Value();

            XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('NoCertificadoSAT');
            SalesInvoiceHeader."Certificate Serial No." := XMLCurrNode.Value();
        end else begin
            XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('FechaTimbrado');
            CFDIDocuments."Date/Time Stamped" := XMLCurrNode.Value();
            CFDIDocuments."Date/Time Stamp Received" := ConvertStingToDateTime(CFDIDocuments."Date/Time Stamped");

            XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('UUID');
            CFDIDocuments."Fiscal Invoice Number PAC" := XMLCurrNode.Value();

            XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('NoCertificadoSAT');
            CFDIDocuments."Certificate Serial No." := XMLCurrNode.Value();
        end;

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('SelloSAT');

        Clear(OutStr);
        if not Reverse then begin
            SalesInvoiceHeader."Digital Stamp PAC".CreateOutStream(OutStr);
            OutStr.WriteText(XMLCurrNode.Value);
            // Certificate Serial
            SalesInvoiceHeader."Electronic Document Status" := SalesInvoiceHeader."Electronic Document Status"::"Stamp Received";
        end else begin
            CFDIDocuments."Digital Stamp PAC".CreateOutStream(OutStr);
            OutStr.WriteText(XMLCurrNode.Value);
            // Certificate Serial
            CFDIDocuments."Electronic Document Status" := CFDIDocuments."Electronic Document Status"::"Stamp Received";
        end;

        // Create QRCode
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        if not Reverse then begin
            QRCodeInput := CreateQRCodeInput(CompanyInfo."RFC Number", Customer."RFC No.", SalesInvoiceHeader."Amount Including VAT",
                Format(SalesInvoiceHeader."Fiscal Invoice Number PAC"));
            CreateQRCode(QRCodeInput, TempBlob);
            RecordRef.GetTable(SalesInvoiceHeader);
            TempBlob.ToRecordRef(RecordRef, SalesInvoiceHeader.FieldNo("QR Code"));
            RecordRef.SetTable(SalesInvoiceHeader);
        end else begin
            QRCodeInput := CreateQRCodeInput(CompanyInfo."RFC Number", Customer."RFC No.", SalesInvoiceHeader."Amount Including VAT",
                Format(CFDIDocuments."Fiscal Invoice Number PAC"));
            CreateQRCode(QRCodeInput, TempBlob);
            RecordRef.GetTable(CFDIDocuments);
            TempBlob.ToRecordRef(RecordRef, CFDIDocuments.FieldNo("QR Code"));
            RecordRef.Modify();
        end;
    end;

    local procedure ProcessResponseESalesCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; "Action": Option)
    var
        Customer: Record Customer;
        PACWebService: Record "PAC Web Service";
        TempBlob: Codeunit "Temp Blob";
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLDoc: DotNet XmlDocument;
        XMLCurrNode: DotNet XmlNode;
        XMLDOMNamedNodeMap: DotNet XmlNamedNodeMap;
        XMLDOMNodeList: DotNet XmlNodeList;
        NamespaceManager: DotNet XmlNamespaceManager;
        RecordRef: RecordRef;
        OutStr: OutStream;
        InStr: InStream;
        NodeCount: Integer;
        Counter: Integer;
        QRCodeInput: Text;
        ErrorDescription: Text;
        TelemetryError: Text;
        CancelStatus: Option InProgress,Rejected,Cancelled;
        CancelResult: Text[250];
        DocumentStatus: Option " ","Stamp Received",Sent,Canceled,"Stamp Request Error","Cancel Error","Cancel In Progress";
        DateTimeCancelled: Text[50];
    begin
        GetGLSetup();
        GetCompanyInfo();
        GetCustomer(Customer, SalesCrMemoHeader."Bill-to Customer No.", false);

        // Process Response and Load back to header the Signed XML if you get one...
        if IsNull(XMLDoc) then
            XMLDoc := XMLDoc.XmlDocument();

        SalesCrMemoHeader.CalcFields("Signed Document XML");
        SalesCrMemoHeader."Signed Document XML".CreateInStream(InStr);
        XMLDOMManagement.LoadXMLDocumentFromInStream(InStr, XMLDoc);
        Clear(SalesCrMemoHeader."Signed Document XML");
        XMLCurrNode := XMLDoc.SelectSingleNode('Resultado');

        XMLDOMNamedNodeMap := XMLCurrNode.Attributes;
        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('IdRespuesta');

        PACWebService.Get(GLSetup."PAC Code");
        SalesCrMemoHeader."PAC Web Service Name" := PACWebService.Name;

        if XMLCurrNode.Value <> '1' then begin
            SalesCrMemoHeader."Error Code" := XMLCurrNode.Value();
            XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('Descripcion');
            ErrorDescription := XMLCurrNode.Value();
            XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('Detalle');
            if not IsNull(XMLCurrNode) then
                ErrorDescription := ErrorDescription + ': ' + XMLCurrNode.Value();
            TelemetryError := ErrorDescription;
            if StrLen(ErrorDescription) > 250 then
                ErrorDescription := CopyStr(ErrorDescription, 1, 247) + '...';
            SalesCrMemoHeader."Error Description" := CopyStr(ErrorDescription, 1, 250);

            case Action of
                EDocAction::"Request Stamp":
                    SalesCrMemoHeader."Electronic Document Status" := SalesCrMemoHeader."Electronic Document Status"::"Stamp Request Error";
                EDocAction::Cancel:
                    begin
                        SalesCrMemoHeader."Electronic Document Status" := SalesCrMemoHeader."Electronic Document Status"::"Cancel Error";
                        SalesCrMemoHeader."Date/Time Canceled" := '';
                    end;
            end;

            Session.LogMessage(
                '0000C7M', StrSubstNo(ProcessResponseErr, GetDocTypeTextFromDatabaseId(Database::"Sales Cr.Memo Header"), TelemetryError), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);

            exit;
        end;

        SalesCrMemoHeader."Error Code" := '';
        SalesCrMemoHeader."Error Description" := '';
        if Action = EDocAction::Cancel then begin
            SalesCrMemoHeader."Electronic Document Status" := SalesCrMemoHeader."Electronic Document Status"::"Cancel In Progress";
            SalesCrMemoHeader."CFDI Cancellation ID" := GetResponseValueCancellationID(XMLCurrNode, XMLDOMNamedNodeMap);
            exit;
        end;
        if Action = EDocAction::CancelRequest then begin
            ProcessCancelResponse(XMLDoc, XMLCurrNode, XMLDOMNamedNodeMap, CancelStatus, CancelResult, DateTimeCancelled);
            GetDocumentStatusFromCancelStatus(DocumentStatus, CancelStatus);
            SalesCrMemoHeader."Electronic Document Status" := DocumentStatus;
            SalesCrMemoHeader."Error Description" := CancelResult;
            SalesCrMemoHeader."Date/Time Canceled" := DateTimeCancelled;
            exit;
        end;

        XMLCurrNode := XMLDoc.SelectSingleNode('Resultado');
        XMLDOMNodeList := XMLCurrNode.ChildNodes;
        NodeCount := XMLDOMNodeList.Count();
        Clear(XMLDoc);
        XMLDoc := XMLDoc.XmlDocument();

        for Counter := 0 to (NodeCount - 1) do begin
            XMLCurrNode := XMLDOMNodeList.Item(Counter);
            XMLDoc.AppendChild(XMLDoc.ImportNode(XMLCurrNode, true));
        end;

        SalesCrMemoHeader."Signed Document XML".CreateOutStream(OutStr);
        XMLDoc.Save(OutStr);

        NamespaceManager := NamespaceManager.XmlNamespaceManager(XMLDoc.NameTable);
        NamespaceManager.AddNamespace('cfdi', 'http://www.sat.gob.mx/cfd/4');
        NamespaceManager.AddNamespace('tfd', 'http://www.sat.gob.mx/TimbreFiscalDigital');
        XMLCurrNode := XMLDoc.SelectSingleNode('cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital', NamespaceManager);
        XMLDOMNamedNodeMap := XMLCurrNode.Attributes;

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('FechaTimbrado');
        SalesCrMemoHeader."Date/Time Stamped" := XMLCurrNode.Value();
        SalesCrMemoHeader."Date/Time Stamp Received" := ConvertStingToDateTime(SalesCrMemoHeader."Date/Time Stamped");

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('UUID');
        SalesCrMemoHeader."Fiscal Invoice Number PAC" := XMLCurrNode.Value();

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('NoCertificadoSAT');
        SalesCrMemoHeader."Certificate Serial No." := XMLCurrNode.Value();

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('SelloSAT');

        Clear(OutStr);
        SalesCrMemoHeader."Digital Stamp PAC".CreateOutStream(OutStr);
        OutStr.WriteText(XMLCurrNode.Value);
        // Certificate Serial
        SalesCrMemoHeader."Electronic Document Status" := SalesCrMemoHeader."Electronic Document Status"::"Stamp Received";

        // Create QRCode
        SalesCrMemoHeader.CalcFields("Amount Including VAT");
        QRCodeInput := CreateQRCodeInput(CompanyInfo."RFC Number", Customer."RFC No.", SalesCrMemoHeader."Amount Including VAT",
            Format(SalesCrMemoHeader."Fiscal Invoice Number PAC"));
        CreateQRCode(QRCodeInput, TempBlob);
        RecordRef.GetTable(SalesCrMemoHeader);
        TempBlob.ToRecordRef(RecordRef, SalesCrMemoHeader.FieldNo("QR Code"));
        RecordRef.SetTable(SalesCrMemoHeader);
    end;

    local procedure ProcessResponseEServiceInvoice(var ServInvoiceHeader: Record "Service Invoice Header"; "Action": Option; AmountInclVAT: Decimal)
    var
        Customer: Record Customer;
        PACWebService: Record "PAC Web Service";
        XMLDOMManagement: Codeunit "XML DOM Management";
        TempBlob: Codeunit "Temp Blob";
        XMLDoc: DotNet XmlDocument;
        XMLCurrNode: DotNet XmlNode;
        XMLDOMNamedNodeMap: DotNet XmlNamedNodeMap;
        XMLDOMNodeList: DotNet XmlNodeList;
        NamespaceManager: DotNet XmlNamespaceManager;
        RecordRef: RecordRef;
        OutStr: OutStream;
        InStr: InStream;
        NodeCount: Integer;
        Counter: Integer;
        QRCodeInput: Text;
        ErrorDescription: Text;
        TelemetryError: Text;
        CancelStatus: Option InProgress,Rejected,Cancelled;
        CancelResult: Text[250];
        DocumentStatus: Option " ","Stamp Received",Sent,Canceled,"Stamp Request Error","Cancel Error","Cancel In Progress";
        DateTimeCancelled: Text[50];
    begin
        GetGLSetup();
        GetCompanyInfo();
        GetCustomer(Customer, ServInvoiceHeader."Bill-to Customer No.", false);

        // Process Response and Load back to header the Signed XML if you get one...
        if IsNull(XMLDoc) then
            XMLDoc := XMLDoc.XmlDocument();

        ServInvoiceHeader.CalcFields("Signed Document XML");
        ServInvoiceHeader."Signed Document XML".CreateInStream(InStr);
        XMLDOMManagement.LoadXMLDocumentFromInStream(InStr, XMLDoc);
        Clear(ServInvoiceHeader."Signed Document XML");
        XMLCurrNode := XMLDoc.SelectSingleNode('Resultado');

        XMLDOMNamedNodeMap := XMLCurrNode.Attributes;
        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('IdRespuesta');

        PACWebService.Get(GLSetup."PAC Code");
        ServInvoiceHeader."PAC Web Service Name" := PACWebService.Name;

        if XMLCurrNode.Value <> '1' then begin
            ServInvoiceHeader."Error Code" := XMLCurrNode.Value();
            XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('Descripcion');
            ErrorDescription := XMLCurrNode.Value();
            XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('Detalle');
            if not IsNull(XMLCurrNode) then
                ErrorDescription := ErrorDescription + ': ' + XMLCurrNode.Value();
            TelemetryError := ErrorDescription;
            if StrLen(ErrorDescription) > 250 then
                ErrorDescription := CopyStr(ErrorDescription, 1, 247) + '...';
            ServInvoiceHeader."Error Description" := CopyStr(ErrorDescription, 1, 250);

            case Action of
                EDocAction::"Request Stamp":
                    ServInvoiceHeader."Electronic Document Status" := ServInvoiceHeader."Electronic Document Status"::"Stamp Request Error";
                EDocAction::Cancel:
                    begin
                        ServInvoiceHeader."Electronic Document Status" := ServInvoiceHeader."Electronic Document Status"::"Cancel Error";
                        ServInvoiceHeader."Date/Time Canceled" := '';
                    end;
            end;

            Session.LogMessage(
                '0000C7M', StrSubstNo(ProcessResponseErr, GetDocTypeTextFromDatabaseId(Database::"Service Invoice Header"), TelemetryError), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);

            exit;
        end;

        ServInvoiceHeader."Error Code" := '';
        ServInvoiceHeader."Error Description" := '';
        if Action = EDocAction::Cancel then begin
            ServInvoiceHeader."Electronic Document Status" := ServInvoiceHeader."Electronic Document Status"::"Cancel In Progress";
            ServInvoiceHeader."CFDI Cancellation ID" := GetResponseValueCancellationID(XMLCurrNode, XMLDOMNamedNodeMap);
            exit;
        end;
        if Action = EDocAction::CancelRequest then begin
            ProcessCancelResponse(XMLDoc, XMLCurrNode, XMLDOMNamedNodeMap, CancelStatus, CancelResult, DateTimeCancelled);
            GetDocumentStatusFromCancelStatus(DocumentStatus, CancelStatus);
            ServInvoiceHeader."Electronic Document Status" := DocumentStatus;
            ServInvoiceHeader."Error Description" := CancelResult;
            ServInvoiceHeader."Date/Time Canceled" := DateTimeCancelled;
            exit;
        end;

        XMLCurrNode := XMLDoc.SelectSingleNode('Resultado');
        XMLDOMNodeList := XMLCurrNode.ChildNodes;
        NodeCount := XMLDOMNodeList.Count();
        Clear(XMLDoc);
        XMLDoc := XMLDoc.XmlDocument();

        for Counter := 0 to (NodeCount - 1) do begin
            XMLCurrNode := XMLDOMNodeList.Item(Counter);
            XMLDoc.AppendChild(XMLDoc.ImportNode(XMLCurrNode, true));
        end;

        ServInvoiceHeader."Signed Document XML".CreateOutStream(OutStr);
        XMLDoc.Save(OutStr);

        NamespaceManager := NamespaceManager.XmlNamespaceManager(XMLDoc.NameTable);
        NamespaceManager.AddNamespace('cfdi', 'http://www.sat.gob.mx/cfd/4');
        NamespaceManager.AddNamespace('tfd', 'http://www.sat.gob.mx/TimbreFiscalDigital');
        XMLCurrNode := XMLDoc.SelectSingleNode('cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital', NamespaceManager);
        XMLDOMNamedNodeMap := XMLCurrNode.Attributes;

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('FechaTimbrado');
        ServInvoiceHeader."Date/Time Stamped" := XMLCurrNode.Value();
        ServInvoiceHeader."Date/Time Stamp Received" := ConvertStingToDateTime(ServInvoiceHeader."Date/Time Stamped");

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('UUID');
        ServInvoiceHeader."Fiscal Invoice Number PAC" := XMLCurrNode.Value();

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('NoCertificadoSAT');
        ServInvoiceHeader."Certificate Serial No." := XMLCurrNode.Value();

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('SelloSAT');

        Clear(OutStr);
        ServInvoiceHeader."Digital Stamp PAC".CreateOutStream(OutStr);
        OutStr.WriteText(XMLCurrNode.Value);
        // Certiificate Serial
        ServInvoiceHeader."Electronic Document Status" := ServInvoiceHeader."Electronic Document Status"::"Stamp Received";

        // Create QRCode
        QRCodeInput := CreateQRCodeInput(CompanyInfo."RFC Number", Customer."RFC No.", AmountInclVAT,
            Format(ServInvoiceHeader."Fiscal Invoice Number PAC"));
        CreateQRCode(QRCodeInput, TempBlob);
        RecordRef.GetTable(ServInvoiceHeader);
        TempBlob.ToRecordRef(RecordRef, ServInvoiceHeader.FieldNo("QR Code"));
        RecordRef.SetTable(ServInvoiceHeader);
    end;

    local procedure ProcessResponseEServiceCrMemo(var ServCrMemoHeader: Record "Service Cr.Memo Header"; "Action": Option; AmountInclVAT: Decimal)
    var
        Customer: Record Customer;
        PACWebService: Record "PAC Web Service";
        TempBlob: Codeunit "Temp Blob";
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLDoc: DotNet XmlDocument;
        XMLCurrNode: DotNet XmlNode;
        XMLDOMNamedNodeMap: DotNet XmlNamedNodeMap;
        XMLDOMNodeList: DotNet XmlNodeList;
        NamespaceManager: DotNet XmlNamespaceManager;
        RecordRef: RecordRef;
        OutStr: OutStream;
        InStr: InStream;
        NodeCount: Integer;
        Counter: Integer;
        QRCodeInput: Text;
        ErrorDescription: Text;
        TelemetryError: Text;
        CancelStatus: Option InProgress,Rejected,Cancelled;
        CancelResult: Text[250];
        DocumentStatus: Option " ","Stamp Received",Sent,Canceled,"Stamp Request Error","Cancel Error","Cancel In Progress";
        DateTimeCancelled: Text[50];
    begin
        GetGLSetup();
        GetCompanyInfo();
        GetCustomer(Customer, ServCrMemoHeader."Bill-to Customer No.", false);

        // Process Response and Load back to header the Signed XML if you get one...
        if IsNull(XMLDoc) then
            XMLDoc := XMLDoc.XmlDocument();

        ServCrMemoHeader.CalcFields("Signed Document XML");
        ServCrMemoHeader."Signed Document XML".CreateInStream(InStr);
        XMLDOMManagement.LoadXMLDocumentFromInStream(InStr, XMLDoc);
        Clear(ServCrMemoHeader."Signed Document XML");
        XMLCurrNode := XMLDoc.SelectSingleNode('Resultado');

        XMLDOMNamedNodeMap := XMLCurrNode.Attributes;
        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('IdRespuesta');

        PACWebService.Get(GLSetup."PAC Code");
        ServCrMemoHeader."PAC Web Service Name" := PACWebService.Name;

        if XMLCurrNode.Value <> '1' then begin
            ServCrMemoHeader."Error Code" := XMLCurrNode.Value();
            XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('Descripcion');
            ErrorDescription := XMLCurrNode.Value();
            XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('Detalle');
            if not IsNull(XMLCurrNode) then
                ErrorDescription := ErrorDescription + ': ' + XMLCurrNode.Value();
            TelemetryError := ErrorDescription;
            if StrLen(ErrorDescription) > 250 then
                ErrorDescription := CopyStr(ErrorDescription, 1, 247) + '...';
            ServCrMemoHeader."Error Description" := CopyStr(ErrorDescription, 1, 250);

            case Action of
                EDocAction::"Request Stamp":
                    ServCrMemoHeader."Electronic Document Status" := ServCrMemoHeader."Electronic Document Status"::"Stamp Request Error";
                EDocAction::Cancel:
                    begin
                        ServCrMemoHeader."Electronic Document Status" := ServCrMemoHeader."Electronic Document Status"::"Cancel Error";
                        ServCrMemoHeader."Date/Time Canceled" := '';
                    end;
            end;

            Session.LogMessage(
                '0000C7M', StrSubstNo(ProcessResponseErr, GetDocTypeTextFromDatabaseId(Database::"Service Cr.Memo Header"), TelemetryError), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);

            exit;
        end;

        ServCrMemoHeader."Error Code" := '';
        ServCrMemoHeader."Error Description" := '';
        if Action = EDocAction::Cancel then begin
            ServCrMemoHeader."Electronic Document Status" := ServCrMemoHeader."Electronic Document Status"::"Cancel In Progress";
            ServCrMemoHeader."CFDI Cancellation ID" := GetResponseValueCancellationID(XMLCurrNode, XMLDOMNamedNodeMap);
            exit;
        end;
        if Action = EDocAction::CancelRequest then begin
            ProcessCancelResponse(XMLDoc, XMLCurrNode, XMLDOMNamedNodeMap, CancelStatus, CancelResult, DateTimeCancelled);
            GetDocumentStatusFromCancelStatus(DocumentStatus, CancelStatus);
            ServCrMemoHeader."Electronic Document Status" := DocumentStatus;
            ServCrMemoHeader."Error Description" := CancelResult;
            ServCrMemoHeader."Date/Time Canceled" := DateTimeCancelled;
            exit;
        end;

        XMLCurrNode := XMLDoc.SelectSingleNode('Resultado');
        XMLDOMNodeList := XMLCurrNode.ChildNodes;
        NodeCount := XMLDOMNodeList.Count();
        Clear(XMLDoc);
        XMLDoc := XMLDoc.XmlDocument();

        for Counter := 0 to (NodeCount - 1) do begin
            XMLCurrNode := XMLDOMNodeList.Item(Counter);
            XMLDoc.AppendChild(XMLDoc.ImportNode(XMLCurrNode, true));
        end;

        ServCrMemoHeader."Signed Document XML".CreateOutStream(OutStr);
        XMLDoc.Save(OutStr);

        NamespaceManager := NamespaceManager.XmlNamespaceManager(XMLDoc.NameTable);
        NamespaceManager.AddNamespace('cfdi', 'http://www.sat.gob.mx/cfd/4');
        NamespaceManager.AddNamespace('tfd', 'http://www.sat.gob.mx/TimbreFiscalDigital');
        XMLCurrNode := XMLDoc.SelectSingleNode('cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital', NamespaceManager);
        XMLDOMNamedNodeMap := XMLCurrNode.Attributes;

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('FechaTimbrado');
        ServCrMemoHeader."Date/Time Stamped" := XMLCurrNode.Value();
        ServCrMemoHeader."Date/Time Stamp Received" := ConvertStingToDateTime(ServCrMemoHeader."Date/Time Stamped");

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('UUID');
        ServCrMemoHeader."Fiscal Invoice Number PAC" := XMLCurrNode.Value();

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('NoCertificadoSAT');
        ServCrMemoHeader."Certificate Serial No." := XMLCurrNode.Value();

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('SelloSAT');

        Clear(OutStr);
        ServCrMemoHeader."Digital Stamp PAC".CreateOutStream(OutStr);
        OutStr.WriteText(XMLCurrNode.Value);
        // Certificate Serial
        ServCrMemoHeader."Electronic Document Status" := ServCrMemoHeader."Electronic Document Status"::"Stamp Received";

        // Create QRCode
        QRCodeInput := CreateQRCodeInput(CompanyInfo."RFC Number", Customer."RFC No.", AmountInclVAT,
            Format(ServCrMemoHeader."Fiscal Invoice Number PAC"));
        CreateQRCode(QRCodeInput, TempBlob);
        RecordRef.GetTable(ServCrMemoHeader);
        TempBlob.ToRecordRef(RecordRef, ServCrMemoHeader.FieldNo("QR Code"));
        RecordRef.SetTable(ServCrMemoHeader);
    end;

    local procedure ProcessResponseESalesShipment(var SalesShipmentHeader: Record "Sales Shipment Header"; "Action": Option)
    var
        PACWebService: Record "PAC Web Service";
        TempBlob: Codeunit "Temp Blob";
        XMLDOMManagement: Codeunit "XML DOM Management";
        RecordRef: RecordRef;
        XMLDoc: DotNet XmlDocument;
        XMLCurrNode: DotNet XmlNode;
        XMLDOMNamedNodeMap: DotNet XmlNamedNodeMap;
        XMLDOMNodeList: DotNet XmlNodeList;
        NamespaceManager: DotNet XmlNamespaceManager;
        OutStr: OutStream;
        InStr: InStream;
        NodeCount: Integer;
        Counter: Integer;
        QRCodeInput: Text;
        ErrorDescription: Text;
        TelemetryError: Text;
        CancelStatus: Option InProgress,Rejected,Cancelled;
        CancelResult: Text[250];
        DocumentStatus: Option " ","Stamp Received",Sent,Canceled,"Stamp Request Error","Cancel Error","Cancel In Progress";
        DateTimeCancelled: Text[50];
    begin
        GetGLSetup();
        GetCompanyInfo();

        // Process Response and Load back to header the Signed XML if you get one...
        if IsNull(XMLDoc) then
            XMLDoc := XMLDoc.XmlDocument();

        SalesShipmentHeader.CalcFields("Signed Document XML");
        SalesShipmentHeader."Signed Document XML".CreateInStream(InStr);
        XMLDOMManagement.LoadXMLDocumentFromInStream(InStr, XMLDoc);
        Clear(SalesShipmentHeader."Signed Document XML");
        XMLCurrNode := XMLDoc.SelectSingleNode('Resultado');

        XMLDOMNamedNodeMap := XMLCurrNode.Attributes;
        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('IdRespuesta');

        PACWebService.Get(GLSetup."PAC Code");
        SalesShipmentHeader."PAC Web Service Name" := PACWebService.Name;

        if XMLCurrNode.Value <> '1' then begin
            SalesShipmentHeader."Error Code" := XMLCurrNode.Value();
            XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('Descripcion');
            ErrorDescription := XMLCurrNode.Value();
            XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('Detalle');
            if not IsNull(XMLCurrNode) then
                ErrorDescription := ErrorDescription + ': ' + XMLCurrNode.Value();
            TelemetryError := ErrorDescription;
            if StrLen(ErrorDescription) > 250 then
                ErrorDescription := CopyStr(ErrorDescription, 1, 247) + '...';
            SalesShipmentHeader."Error Description" := CopyStr(ErrorDescription, 1, 250);
            case Action of
                EDocAction::"Request Stamp":
                    SalesShipmentHeader."Electronic Document Status" :=
                      SalesShipmentHeader."Electronic Document Status"::"Stamp Request Error";
                EDocAction::Cancel:
                    begin
                        SalesShipmentHeader."Electronic Document Status" :=
                          SalesShipmentHeader."Electronic Document Status"::"Cancel Error";
                        SalesShipmentHeader."Date/Time Canceled" := '';
                    end;
            end;

            Session.LogMessage(
                '0000MF2', StrSubstNo(ProcessResponseErr, GetDocTypeTextFromDatabaseId(Database::"Sales Shipment Header"), TelemetryError), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);

            exit;
        end;

        SalesShipmentHeader."Error Code" := '';
        SalesShipmentHeader."Error Description" := '';
        if Action = EDocAction::Cancel then begin
            SalesShipmentHeader."Electronic Document Status" := SalesShipmentHeader."Electronic Document Status"::"Cancel In Progress";
            SalesShipmentHeader."CFDI Cancellation ID" := GetResponseValueCancellationID(XMLCurrNode, XMLDOMNamedNodeMap);
            exit;
        end;
        if Action = EDocAction::CancelRequest then begin
            ProcessCancelResponse(XMLDoc, XMLCurrNode, XMLDOMNamedNodeMap, CancelStatus, CancelResult, DateTimeCancelled);
            GetDocumentStatusFromCancelStatus(DocumentStatus, CancelStatus);
            SalesShipmentHeader."Electronic Document Status" := DocumentStatus;
            SalesShipmentHeader."Error Description" := CancelResult;
            SalesShipmentHeader."Date/Time Canceled" := DateTimeCancelled;
            exit;
        end;
        XMLCurrNode := XMLDoc.SelectSingleNode('Resultado');
        XMLDOMNodeList := XMLCurrNode.ChildNodes;
        NodeCount := XMLDOMNodeList.Count();
        Clear(XMLDoc);
        XMLDoc := XMLDoc.XmlDocument();

        for Counter := 0 to (NodeCount - 1) do begin
            XMLCurrNode := XMLDOMNodeList.Item(Counter);
            XMLDoc.AppendChild(XMLDoc.ImportNode(XMLCurrNode, true));
        end;

        SalesShipmentHeader."Signed Document XML".CreateOutStream(OutStr);
        XMLDoc.Save(OutStr);

        NamespaceManager := NamespaceManager.XmlNamespaceManager(XMLDoc.NameTable);
        NamespaceManager.AddNamespace('cfdi', 'http://www.sat.gob.mx/cfd/4');
        NamespaceManager.AddNamespace('tfd', 'http://www.sat.gob.mx/TimbreFiscalDigital');
        XMLCurrNode := XMLDoc.SelectSingleNode('cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital', NamespaceManager);
        XMLDOMNamedNodeMap := XMLCurrNode.Attributes;

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('FechaTimbrado');
        SalesShipmentHeader."Date/Time Stamped" := XMLCurrNode.Value();
        SalesShipmentHeader."Date/Time Stamp Received" := ConvertStingToDateTime(SalesShipmentHeader."Date/Time Stamped");

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('UUID');
        SalesShipmentHeader."Fiscal Invoice Number PAC" := XMLCurrNode.Value();

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('NoCertificadoSAT');
        SalesShipmentHeader."Certificate Serial No." := XMLCurrNode.Value();

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('SelloSAT');

        Clear(OutStr);
        SalesShipmentHeader."Digital Stamp PAC".CreateOutStream(OutStr);
        OutStr.WriteText(XMLCurrNode.Value);
        // Certificate Serial
        SalesShipmentHeader."Electronic Document Status" := SalesShipmentHeader."Electronic Document Status"::"Stamp Received";

        // Create QRCode
        QRCodeInput :=
            CreateQRCodeInput(CompanyInfo."RFC Number", CompanyInfo."RFC Number", 0, Format(SalesShipmentHeader."Fiscal Invoice Number PAC"));
        CreateQRCode(QRCodeInput, TempBlob);
        RecordRef.GetTable(SalesShipmentHeader);
        TempBlob.ToRecordRef(RecordRef, SalesShipmentHeader.FieldNo("QR Code"));
        RecordRef.SetTable(SalesShipmentHeader);
    end;

    local procedure ProcessResponseETransferShipment(var TransferShipmentHeader: Record "Transfer Shipment Header"; "Action": Option)
    var
        PACWebService: Record "PAC Web Service";
        TempBlob: Codeunit "Temp Blob";
        XMLDOMManagement: Codeunit "XML DOM Management";
        RecordRef: RecordRef;
        XMLDoc: DotNet XmlDocument;
        XMLCurrNode: DotNet XmlNode;
        XMLDOMNamedNodeMap: DotNet XmlNamedNodeMap;
        XMLDOMNodeList: DotNet XmlNodeList;
        NamespaceManager: DotNet XmlNamespaceManager;
        OutStr: OutStream;
        InStr: InStream;
        NodeCount: Integer;
        Counter: Integer;
        QRCodeInput: Text;
        ErrorDescription: Text;
        TelemetryError: Text;
        CancelStatus: Option InProgress,Rejected,Cancelled;
        CancelResult: Text[250];
        DocumentStatus: Option " ","Stamp Received",Sent,Canceled,"Stamp Request Error","Cancel Error","Cancel In Progress";
        DateTimeCancelled: Text[50];
    begin
        GetGLSetup();
        GetCompanyInfo();

        // Process Response and Load back to header the Signed XML if you get one...
        if IsNull(XMLDoc) then
            XMLDoc := XMLDoc.XmlDocument();

        TransferShipmentHeader.CalcFields("Signed Document XML");
        TransferShipmentHeader."Signed Document XML".CreateInStream(InStr);
        XMLDOMManagement.LoadXMLDocumentFromInStream(InStr, XMLDoc);
        Clear(TransferShipmentHeader."Signed Document XML");
        XMLCurrNode := XMLDoc.SelectSingleNode('Resultado');

        XMLDOMNamedNodeMap := XMLCurrNode.Attributes;
        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('IdRespuesta');

        PACWebService.Get(GLSetup."PAC Code");
        TransferShipmentHeader."PAC Web Service Name" := PACWebService.Name;

        if XMLCurrNode.Value <> '1' then begin
            TransferShipmentHeader."Error Code" := XMLCurrNode.Value();
            XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('Descripcion');
            ErrorDescription := XMLCurrNode.Value();
            XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('Detalle');
            if not IsNull(XMLCurrNode) then
                ErrorDescription := ErrorDescription + ': ' + XMLCurrNode.Value();
            TelemetryError := ErrorDescription;
            if StrLen(ErrorDescription) > 250 then
                ErrorDescription := CopyStr(ErrorDescription, 1, 247) + '...';
            TransferShipmentHeader."Error Description" := CopyStr(ErrorDescription, 1, 250);
            case Action of
                EDocAction::"Request Stamp":
                    TransferShipmentHeader."Electronic Document Status" :=
                      TransferShipmentHeader."Electronic Document Status"::"Stamp Request Error";
                EDocAction::Cancel:
                    begin
                        TransferShipmentHeader."Electronic Document Status" :=
                          TransferShipmentHeader."Electronic Document Status"::"Cancel Error";
                        TransferShipmentHeader."Date/Time Canceled" := '';
                    end;
            end;

            Session.LogMessage(
                '0000MF3', StrSubstNo(ProcessResponseErr, GetDocTypeTextFromDatabaseId(Database::"Transfer Shipment Header"), TelemetryError), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);

            exit;
        end;

        TransferShipmentHeader."Error Code" := '';
        TransferShipmentHeader."Error Description" := '';
        if Action = EDocAction::Cancel then begin
            TransferShipmentHeader."Electronic Document Status" :=
              TransferShipmentHeader."Electronic Document Status"::"Cancel In Progress";
            TransferShipmentHeader."CFDI Cancellation ID" := GetResponseValueCancellationID(XMLCurrNode, XMLDOMNamedNodeMap);
            exit;
        end;
        if Action = EDocAction::CancelRequest then begin
            ProcessCancelResponse(XMLDoc, XMLCurrNode, XMLDOMNamedNodeMap, CancelStatus, CancelResult, DateTimeCancelled);
            GetDocumentStatusFromCancelStatus(DocumentStatus, CancelStatus);
            TransferShipmentHeader."Electronic Document Status" := DocumentStatus;
            TransferShipmentHeader."Error Description" := CancelResult;
            TransferShipmentHeader."Date/Time Canceled" := DateTimeCancelled;
            exit;
        end;
        XMLCurrNode := XMLDoc.SelectSingleNode('Resultado');
        XMLDOMNodeList := XMLCurrNode.ChildNodes;
        NodeCount := XMLDOMNodeList.Count();
        Clear(XMLDoc);
        XMLDoc := XMLDoc.XmlDocument();

        for Counter := 0 to (NodeCount - 1) do begin
            XMLCurrNode := XMLDOMNodeList.Item(Counter);
            XMLDoc.AppendChild(XMLDoc.ImportNode(XMLCurrNode, true));
        end;

        TransferShipmentHeader."Signed Document XML".CreateOutStream(OutStr);
        XMLDoc.Save(OutStr);

        NamespaceManager := NamespaceManager.XmlNamespaceManager(XMLDoc.NameTable);
        NamespaceManager.AddNamespace('cfdi', 'http://www.sat.gob.mx/cfd/4');
        NamespaceManager.AddNamespace('tfd', 'http://www.sat.gob.mx/TimbreFiscalDigital');
        XMLCurrNode := XMLDoc.SelectSingleNode('cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital', NamespaceManager);
        XMLDOMNamedNodeMap := XMLCurrNode.Attributes;

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('FechaTimbrado');
        TransferShipmentHeader."Date/Time Stamped" := XMLCurrNode.Value();
        TransferShipmentHeader."Date/Time Stamp Received" := ConvertStingToDateTime(TransferShipmentHeader."Date/Time Stamped");

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('UUID');
        TransferShipmentHeader."Fiscal Invoice Number PAC" := XMLCurrNode.Value();

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('NoCertificadoSAT');
        TransferShipmentHeader."Certificate Serial No." := XMLCurrNode.Value();

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('SelloSAT');

        Clear(OutStr);
        TransferShipmentHeader."Digital Stamp PAC".CreateOutStream(OutStr);
        OutStr.WriteText(XMLCurrNode.Value);
        // Certificate Serial
        TransferShipmentHeader."Electronic Document Status" := TransferShipmentHeader."Electronic Document Status"::"Stamp Received";

        // Create QRCode
        QRCodeInput :=
            CreateQRCodeInput(CompanyInfo."RFC Number", CompanyInfo."RFC Number", 0, Format(TransferShipmentHeader."Fiscal Invoice Number PAC"));
        CreateQRCode(QRCodeInput, TempBlob);
        RecordRef.GetTable(TransferShipmentHeader);
        TempBlob.ToRecordRef(RecordRef, TransferShipmentHeader.FieldNo("QR Code"));
        RecordRef.SetTable(TransferShipmentHeader);
    end;

    local procedure ProcessCancelResponse(XmlDoc: DotNet XmlDocument; XMLCurrNode: DotNet XmlNode; XMLDOMNamedNodeMap: DotNet XmlNamedNodeMap; var CancelStatus: Option InProgress,Rejected,Cancelled; var CancelResult: Text[250]; var DateTimeCancelled: Text[50])
    var
        XMLCurrNodeEvent: DotNet XmlNode;
        StatusTxt: Text[10];
    begin
        DateTimeCancelled := '';
        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('Estatus');
        StatusTxt := XMLCurrNode.Value();
        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('Resultado');
        CancelResult := XMLCurrNode.Value();
        case StatusTxt of
            'EnProceso':
                CancelStatus := CancelStatus::InProgress;
            'Rechazado':
                CancelStatus := CancelStatus::Rejected;
            'Cancelado':
                begin
                    CancelStatus := CancelStatus::Cancelled;
                    CancelResult := '';
                    XMLCurrNodeEvent := XMLDoc.DocumentElement.SelectNodes('Evento').Item(0);
                    DateTimeCancelled := XMLCurrNodeEvent.Attributes.GetNamedItem('Fecha').Value;
                end;
        end;
    end;

    local procedure GetDocumentStatusFromCancelStatus(var DocumentStatus: Option " ","Stamp Received",Sent,Canceled,"Stamp Request Error","Cancel Error","Cancel In Progress"; CancelStatus: Option InProgress,Rejected,Cancelled)
    begin
        case CancelStatus of
            CancelStatus::InProgress:
                DocumentStatus := DocumentStatus::"Cancel In Progress";
            CancelStatus::Rejected:
                DocumentStatus := DocumentStatus::"Cancel Error";
            CancelStatus::Cancelled:
                DocumentStatus := DocumentStatus::Canceled;
            else
                DocumentStatus := DocumentStatus::"Cancel Error";
        end;
    end;

    local procedure GetResponseValueCancellationID(XMLCurrNode: DotNet XmlNode; XMLDOMNamedNodeMap: DotNet XmlNamedNodeMap): Text[50]
    begin
        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('ConsultaCancelacionId');
        exit(XMLCurrNode.Value);
    end;

    local procedure GetFieldIDElectronicDocumentStatus(): Integer
    var
        DummySalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        exit(DummySalesInvoiceHeader.FieldNo("Electronic Document Status"));
    end;

    local procedure GetFieldIDDateTimeCancelled(): Integer
    var
        DummySalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        exit(DummySalesInvoiceHeader.FieldNo("Date/Time Canceled"));
    end;

    local procedure GetFieldIDMarkedAsCanceled(): Integer
    var
        DummySalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        exit(DummySalesInvoiceHeader.FieldNo("Marked as Canceled"));
    end;

    local procedure GetFieldIDDateTimeCancelSent(): Integer
    var
        DummySalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        exit(DummySalesInvoiceHeader.FieldNo("Date/Time Cancel Sent"));
    end;

    local procedure GetFieldIDDateTimeCanceled(): Integer
    var
        DummySalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        exit(DummySalesInvoiceHeader.FieldNo("Date/Time Canceled"));
    end;

    local procedure CreateXMLDocument33(var TempDocumentHeader: Record "Document Header" temporary; var TempDocumentLine: Record "Document Line" temporary; var TempDocumentLineRetention: Record "Document Line" temporary; var TempCFDIRelationDocument: Record "CFDI Relation Document" temporary; var TempVATAmountLine: Record "VAT Amount Line" temporary; DateTimeFirstReqSent: Text[50]; SignedString: Text; Certificate: Text; CertificateSerialNo: Text[250]; IsCredit: Boolean; var XMLDoc: DotNet XmlDocument; SubTotal: Decimal; TotalTax: Decimal; TotalRetention: Decimal; TotalDiscount: Decimal)
    var
        Customer: Record Customer;
        TempDocumentLineCCE: Record "Document Line" temporary;
        SATUtilities: Codeunit "SAT Utilities";
        XMLCurrNode: DotNet XmlNode;
        XMLNewChild: DotNet XmlNode;
        NumeroPedimento: Text;
    begin
        InitXML(XMLDoc, XMLCurrNode, TempDocumentHeader."Foreign Trade");
        GetCustomer(Customer, TempDocumentHeader."Bill-to/Pay-To No.", false);
        AddAttribute(XMLDoc, XMLCurrNode, 'Version', '4.0');
        AddAttribute(XMLDoc, XMLCurrNode, 'Folio', TempDocumentHeader."No.");
        AddAttribute(XMLDoc, XMLCurrNode, 'Fecha', DateTimeFirstReqSent);
        AddAttribute(XMLDoc, XMLCurrNode, 'Sello', SignedString);
        AddAttribute(XMLDoc, XMLCurrNode, 'FormaPago', SATUtilities.GetSATPaymentMethod(TempDocumentHeader."Payment Method Code"));
        AddAttribute(XMLDoc, XMLCurrNode, 'NoCertificado', CertificateSerialNo);
        AddAttribute(XMLDoc, XMLCurrNode, 'Certificado', Certificate);
        AddAttribute(XMLDoc, XMLCurrNode, 'SubTotal', FormatAmount(SubTotal));
        AddAttribute(XMLDoc, XMLCurrNode, 'Descuento', FormatAmount(TotalDiscount));

        if TempDocumentHeader."Currency Code" <> '' then begin
            AddAttribute(XMLDoc, XMLCurrNode, 'Moneda', TempDocumentHeader."Currency Code");
            if (TempDocumentHeader."Currency Code" <> 'MXN') and (TempDocumentHeader."Currency Code" <> 'XXX') then
                AddAttribute(XMLDoc, XMLCurrNode, 'TipoCambio', FormatDecimal(1 / TempDocumentHeader."Currency Factor", 6));
        end;

        AddAttribute(XMLDoc, XMLCurrNode, 'Total', FormatAmount(TempDocumentHeader."Amount Including VAT"));
        if IsCredit then
            AddAttribute(XMLDoc, XMLCurrNode, 'TipoDeComprobante', 'E')
        // Egreso
        else
            AddAttribute(XMLDoc, XMLCurrNode, 'TipoDeComprobante', 'I');
        // Ingreso
        AddAttribute(XMLDoc, XMLCurrNode, 'Exportacion', TempDocumentHeader."CFDI Export Code");
        AddAttribute(XMLDoc, XMLCurrNode, 'MetodoPago', SATUtilities.GetSATPaymentTerm(TempDocumentHeader."Payment Terms Code"));
        AddAttribute(XMLDoc, XMLCurrNode, 'LugarExpedicion', CompanyInfo."SAT Postal Code");
        // InformacioGlobal
        if Customer."CFDI General Public" then begin
            AddElementCFDI(XMLCurrNode, 'InformacionGlobal', '', DocNameSpace, XMLNewChild);
            XMLCurrNode := XMLNewChild;
            AddAttribute(XMLDoc, XMLCurrNode, 'Año', Format(Date2DMY(TempDocumentHeader."Document Date", 3)));
            AddAttribute(XMLDoc, XMLCurrNode, 'Meses', FormatMonth(Format(Date2DMY(TempDocumentHeader."Document Date", 2))));
            AddAttribute(XMLDoc, XMLCurrNode, 'Periodicidad', FormatPeriod(TempDocumentHeader."CFDI Period"));
            XMLCurrNode := XMLCurrNode.ParentNode;
        end;

        AddNodeRelacionado(XMLDoc, XMLCurrNode, XMLNewChild, TempCFDIRelationDocument);
        // CfdiRelacionados
        // Emisor
        AddNodeCompanyInfo(XMLDoc, XMLCurrNode);
        // Receptor
        AddNodeReceptor(
              XMLDoc, XMLCurrNode, Customer, Customer."CFDI Customer Name", TempDocumentHeader."Bill-to/Pay-To Post Code", TempDocumentHeader."CFDI Purpose");

        // Conceptos
        AddElementCFDI(XMLCurrNode, 'Conceptos', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        // Conceptos->Concepto
        TotalDiscount := 0;
        FilterDocumentLines(TempDocumentLine, TempDocumentHeader."No.");
        if TempDocumentLine.FindSet() then
            repeat
                AddElementCFDI(XMLCurrNode, 'Concepto', '', DocNameSpace, XMLNewChild);
                XMLCurrNode := XMLNewChild;
                AddAttribute(
                  XMLDoc, XMLCurrNode, 'ClaveProdServ', SATUtilities.GetSATClassification(TempDocumentLine.Type, TempDocumentLine."No."));
                AddAttribute(XMLDoc, XMLCurrNode, 'NoIdentificacion', TempDocumentLine."No.");
                AddAttribute(XMLDoc, XMLCurrNode, 'Cantidad', Format(TempDocumentLine.Quantity, 0, 9));
                AddAttribute(XMLDoc, XMLCurrNode, 'ClaveUnidad', SATUtilities.GetSATUnitofMeasure(TempDocumentLine."Unit of Measure Code"));
                AddAttribute(XMLDoc, XMLCurrNode, 'Unidad', TempDocumentLine."Unit of Measure Code");
                AddAttribute(XMLDoc, XMLCurrNode, 'Descripcion', EncodeString(TempDocumentLine.Description));
                AddAttribute(XMLDoc, XMLCurrNode, 'ValorUnitario', FormatDecimal(TempDocumentLine."Unit Price/Direct Unit Cost", 6));
                AddAttribute(
                  XMLDoc, XMLCurrNode, 'Importe', FormatDecimal(GetReportedLineAmount(TempDocumentLine), 6));
                // might not need the following nodes, took out of original string....
                AddAttribute(XMLDoc, XMLCurrNode, 'Descuento', FormatDecimal(TempDocumentLine."Line Discount Amount", 6));
                AddAttribute(XMLDoc, XMLCurrNode, 'ObjetoImp', GetSubjectToTaxCode(TempDocumentLine));
                // Impuestos per line
                AddNodeImpuestoPerLine(TempDocumentLine, TempDocumentLineRetention, XMLDoc, XMLCurrNode, XMLNewChild);

                NumeroPedimento := FormatNumeroPedimento(TempDocumentLine);
                if NumeroPedimento <> '' then begin
                    AddElementCFDI(XMLCurrNode, 'InformacionAduanera', '', DocNameSpace, XMLNewChild);
                    XMLCurrNode := XMLNewChild;
                    AddAttributeSimple(XMLDoc, XMLCurrNode, 'NumeroPedimento', NumeroPedimento);
                    XMLCurrNode := XMLCurrNode.ParentNode;
                end;

                XMLCurrNode := XMLCurrNode.ParentNode;

                CalcComercioExteriorLine(TempDocumentLineCCE, TempDocumentLine, TempDocumentHeader."Foreign Trade", false);
            until TempDocumentLine.Next() = 0;
        XMLCurrNode := XMLCurrNode.ParentNode;

        // cfdi:Impuestos
        CreateXMLDocument33TaxAmountLines(
          TempVATAmountLine, XMLDoc, XMLCurrNode, XMLNewChild, TotalTax, TotalRetention);

        if TempDocumentHeader."Foreign Trade" then begin
            // Complemento
            AddElementCFDI(XMLCurrNode, 'Complemento', '', DocNameSpace, XMLNewChild);
            XMLCurrNode := XMLNewChild;
            // ComercioExterior
            AddNodeComercioExterior(TempDocumentLineCCE, TempDocumentHeader, XMLDoc, XMLCurrNode, XMLNewChild);
            XMLCurrNode := XMLCurrNode.ParentNode; // Complemento
        end;
    end;

    local procedure CreateXMLDocument33AdvanceSettle(var TempDocumentHeader: Record "Document Header" temporary; var TempDocumentLine: Record "Document Line" temporary; var TempDocumentLineRetention: Record "Document Line" temporary; var TempVATAmountLine: Record "VAT Amount Line" temporary; DateTimeFirstReqSent: Text[50]; SignedString: Text; Certificate: Text; CertificateSerialNo: Text[250]; var XMLDoc: DotNet XmlDocument; UUID: Text[50]; SubTotal: Decimal; TotalTax: Decimal; TotalRetention: Decimal; TotalDiscount: Decimal)
    var
        Customer: Record Customer;
        TempCFDIRelationDocument: Record "CFDI Relation Document" temporary;
        SATUtilities: Codeunit "SAT Utilities";
        XMLCurrNode: DotNet XmlNode;
        XMLNewChild: DotNet XmlNode;
    begin
        InitXML(XMLDoc, XMLCurrNode, TempDocumentHeader."Foreign Trade");
        GetCustomer(Customer, TempDocumentHeader."Bill-to/Pay-To No.", false);
        AddAttribute(XMLDoc, XMLCurrNode, 'Version', '4.0');
        AddAttribute(XMLDoc, XMLCurrNode, 'Folio', TempDocumentHeader."No.");
        AddAttribute(XMLDoc, XMLCurrNode, 'Fecha', DateTimeFirstReqSent);
        AddAttribute(XMLDoc, XMLCurrNode, 'Sello', SignedString);
        AddAttribute(XMLDoc, XMLCurrNode, 'FormaPago', '30');
        // Hardcoded for Advance Settle
        AddAttribute(XMLDoc, XMLCurrNode, 'NoCertificado', CertificateSerialNo);
        AddAttribute(XMLDoc, XMLCurrNode, 'Certificado', Certificate);
        AddAttribute(XMLDoc, XMLCurrNode, 'SubTotal', FormatAmount(SubTotal));
        AddAttribute(XMLDoc, XMLCurrNode, 'Descuento', FormatAmount(TotalDiscount));

        if TempDocumentHeader."Currency Code" <> '' then begin
            AddAttribute(XMLDoc, XMLCurrNode, 'Moneda', TempDocumentHeader."Currency Code");
            if (TempDocumentHeader."Currency Code" <> 'MXN') and (TempDocumentHeader."Currency Code" <> 'XXX') then
                AddAttribute(XMLDoc, XMLCurrNode, 'TipoCambio', FormatDecimal(1 / TempDocumentHeader."Currency Factor", 6));
        end;

        AddAttribute(XMLDoc, XMLCurrNode, 'Total', FormatAmount(SubTotal - TotalDiscount + TotalTax - TotalRetention));
        AddAttribute(XMLDoc, XMLCurrNode, 'TipoDeComprobante', 'I');
        // Ingreso
        AddAttribute(XMLDoc, XMLCurrNode, 'Exportacion', TempDocumentHeader."CFDI Export Code");

        AddAttribute(XMLDoc, XMLCurrNode, 'MetodoPago', SATUtilities.GetSATPaymentTerm(TempDocumentHeader."Payment Terms Code"));
        AddAttribute(XMLDoc, XMLCurrNode, 'LugarExpedicion', CompanyInfo."SAT Postal Code");

        InitCFDIRelatedDocuments(TempCFDIRelationDocument, UUID, GetAdvanceCFDIRelation(TempDocumentHeader."CFDI Relation"));
        AddNodeRelacionado(XMLDoc, XMLCurrNode, XMLNewChild, TempCFDIRelationDocument);
        // CfdiRelacionados
        // Emisor
        AddNodeCompanyInfo(XMLDoc, XMLCurrNode);
        // Receptor
        AddNodeReceptor(
              XMLDoc, XMLCurrNode, Customer, Customer."CFDI Customer Name", TempDocumentHeader."Bill-to/Pay-To Post Code", TempDocumentHeader."CFDI Purpose");

        // Conceptos
        AddElementCFDI(XMLCurrNode, 'Conceptos', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        // Conceptos->Concepto
        TotalDiscount := 0;
        FilterDocumentLines(TempDocumentLine, TempDocumentHeader."No.");
        if TempDocumentLine.FindSet() then
            repeat
                AddElementCFDI(XMLCurrNode, 'Concepto', '', DocNameSpace, XMLNewChild);
                XMLCurrNode := XMLNewChild;
                AddAttribute(
                  XMLDoc, XMLCurrNode, 'ClaveProdServ', SATUtilities.GetSATClassification(TempDocumentLine.Type, TempDocumentLine."No."));
                AddAttribute(XMLDoc, XMLCurrNode, 'NoIdentificacion', TempDocumentLine."No.");
                AddAttribute(XMLDoc, XMLCurrNode, 'Cantidad', Format(TempDocumentLine.Quantity, 0, 9));
                AddAttribute(XMLDoc, XMLCurrNode, 'ClaveUnidad', SATUtilities.GetSATUnitofMeasure(TempDocumentLine."Unit of Measure Code"));
                AddAttribute(XMLDoc, XMLCurrNode, 'Unidad', TempDocumentLine."Unit of Measure Code");
                AddAttribute(XMLDoc, XMLCurrNode, 'Descripcion', EncodeString(TempDocumentLine.Description));
                AddAttribute(XMLDoc, XMLCurrNode, 'ValorUnitario', FormatDecimal(TempDocumentLine."Unit Price/Direct Unit Cost", 6));
                AddAttribute(
                  XMLDoc, XMLCurrNode, 'Importe', FormatDecimal(GetReportedLineAmount(TempDocumentLine), 6));
                // might not need the following nodes, took out of original string....
                AddAttribute(XMLDoc, XMLCurrNode, 'Descuento', FormatDecimal(TempDocumentLine."Line Discount Amount", 6));
                AddAttribute(XMLDoc, XMLCurrNode, 'ObjetoImp', GetSubjectToTaxCode(TempDocumentLine));
                TotalDiscount := TotalDiscount + TempDocumentLine."Line Discount Amount";
                // Impuestos per line
                AddNodeImpuestoPerLine(TempDocumentLine, TempDocumentLineRetention, XMLDoc, XMLCurrNode, XMLNewChild);

                XMLCurrNode := XMLCurrNode.ParentNode;
            until TempDocumentLine.Next() = 0;
        XMLCurrNode := XMLCurrNode.ParentNode;

        CreateXMLDocument33TaxAmountLines(
          TempVATAmountLine, XMLDoc, XMLCurrNode, XMLNewChild, TotalTax, TotalRetention);

        if TempDocumentHeader."Foreign Trade" then begin
            // Complemento
            AddElementCFDI(XMLCurrNode, 'Complemento', '', DocNameSpace, XMLNewChild);
            XMLCurrNode := XMLNewChild;
            // ComercioExterior
            AddNodeComercioExterior(TempDocumentLine, TempDocumentHeader, XMLDoc, XMLCurrNode, XMLNewChild);
            XMLCurrNode := XMLCurrNode.ParentNode; // Complemento
        end;
    end;

    local procedure CreateXMLDocument33AdvancePayment(var TempDocumentHeader: Record "Document Header" temporary; var TempDocumentLine: Record "Document Line" temporary; DateTimeFirstReqSent: Text[50]; SignedString: Text; Certificate: Text; CertificateSerialNo: Text[250]; var XMLDoc: DotNet XmlDocument; SubTotal: Decimal; RetainAmt: Decimal)
    var
        Customer: Record Customer;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        SATUtilities: Codeunit "SAT Utilities";
        XMLCurrNode: DotNet XmlNode;
        XMLNewChild: DotNet XmlNode;
    begin
        InitXMLAdvancePayment(XMLDoc, XMLCurrNode);
        GetCustomer(Customer, TempDocumentHeader."Bill-to/Pay-To No.", false);
        AddAttribute(XMLDoc, XMLCurrNode, 'Version', '4.0');
        AddAttribute(XMLDoc, XMLCurrNode, 'Folio', TempDocumentHeader."No.");
        AddAttribute(XMLDoc, XMLCurrNode, 'Fecha', DateTimeFirstReqSent);
        AddAttribute(XMLDoc, XMLCurrNode, 'Sello', SignedString);
        AddAttribute(XMLDoc, XMLCurrNode, 'FormaPago', SATUtilities.GetSATPaymentMethod(TempDocumentHeader."Payment Method Code"));
        AddAttribute(XMLDoc, XMLCurrNode, 'NoCertificado', CertificateSerialNo);
        AddAttribute(XMLDoc, XMLCurrNode, 'Certificado', Certificate);
        AddAttribute(XMLDoc, XMLCurrNode, 'SubTotal', FormatAmount(SubTotal));

        AddAttribute(XMLDoc, XMLCurrNode, 'Moneda', ConvertCurrency(TempDocumentHeader."Currency Code"));
        if ConvertCurrency(TempDocumentHeader."Currency Code") <> GLSetup."LCY Code" then
            AddAttribute(XMLDoc, XMLCurrNode, 'TipoCambio', FormatDecimal(1 / TempDocumentHeader."Currency Factor", 6));

        AddAttribute(XMLDoc, XMLCurrNode, 'Total', FormatAmount(SubTotal + RetainAmt));
        AddAttribute(XMLDoc, XMLCurrNode, 'TipoDeComprobante', 'I'); // Ingreso
        AddAttribute(XMLDoc, XMLCurrNode, 'Exportacion', TempDocumentHeader."CFDI Export Code");

        AddAttribute(XMLDoc, XMLCurrNode, 'MetodoPago', 'PUE');
        AddAttribute(XMLDoc, XMLCurrNode, 'LugarExpedicion', CompanyInfo."SAT Postal Code");

        // Emisor
        AddNodeCompanyInfo(XMLDoc, XMLCurrNode);

        // Receptor
        AddNodeReceptor(
              XMLDoc, XMLCurrNode, Customer, Customer."CFDI Customer Name", TempDocumentHeader."Bill-to/Pay-To Post Code", TempDocumentHeader."CFDI Purpose");

        // Conceptos
        AddElementCFDI(XMLCurrNode, 'Conceptos', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;

        // Conceptos->Concepto
        // Just ONE concept
        AddElementCFDI(XMLCurrNode, 'Concepto', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddAttribute(XMLDoc, XMLCurrNode, 'ClaveProdServ', '84111506'); // 84111506 “Servicios de facturación”
        AddAttribute(XMLDoc, XMLCurrNode, 'Cantidad', Format(1));
        AddAttribute(XMLDoc, XMLCurrNode, 'ClaveUnidad', 'ACT');
        AddAttribute(XMLDoc, XMLCurrNode, 'Descripcion', 'Anticipo bien o servicio');

        AddAttribute(XMLDoc, XMLCurrNode, 'ValorUnitario', FormatAmount(SubTotal));
        AddAttribute(XMLDoc, XMLCurrNode, 'Importe', FormatAmount(SubTotal));

        FilterDocumentLines(TempDocumentLine, TempDocumentHeader."No.");
        if TempDocumentLine.FindFirst() then begin
            AddAttribute(XMLDoc, XMLCurrNode, 'ObjetoImp', GetSubjectToTaxCode(TempDocumentLine));
            AddNodeImpuestoPerLine(TempDocumentLine, TempDocumentLine, XMLDoc, XMLCurrNode, XMLNewChild);
            InsertTempVATAmountLine(TempVATAmountLine, TempDocumentLine);
        end;
        XMLCurrNode := XMLCurrNode.ParentNode; // Concepto
        XMLCurrNode := XMLCurrNode.ParentNode; // Conceptos

        CreateXMLDocument33TaxAmountLines(
            TempVATAmountLine, XMLDoc, XMLCurrNode, XMLNewChild, TempDocumentLine."Amount Including VAT" - TempDocumentLine.Amount, 0);
    end;

    local procedure CreateXMLDocument33AdvanceReverse(var TempDocumentHeader: Record "Document Header" temporary; DateTimeReqSent: Text[50]; SignedString: Text; Certificate: Text; CertificateSerialNo: Text[250]; var XMLDoc: DotNet XmlDocument; UUID: Text[50]; AdvanceAmount: Decimal)
    var
        Customer: Record Customer;
        TempCFDIRelationDocument: Record "CFDI Relation Document" temporary;
        XMLCurrNode: DotNet XmlNode;
        XMLNewChild: DotNet XmlNode;
    begin
        InitXMLAdvancePayment(XMLDoc, XMLCurrNode);
        GetCustomer(Customer, TempDocumentHeader."Bill-to/Pay-To No.", false);
        AddAttribute(XMLDoc, XMLCurrNode, 'Version', '4.0');
        AddAttribute(XMLDoc, XMLCurrNode, 'Folio', TempDocumentHeader."No.");
        AddAttribute(XMLDoc, XMLCurrNode, 'Fecha', DateTimeReqSent);
        AddAttribute(XMLDoc, XMLCurrNode, 'Sello', SignedString);
        AddAttribute(XMLDoc, XMLCurrNode, 'FormaPago', '30');
        AddAttribute(XMLDoc, XMLCurrNode, 'NoCertificado', CertificateSerialNo);
        AddAttribute(XMLDoc, XMLCurrNode, 'Certificado', Certificate);
        AddAttribute(XMLDoc, XMLCurrNode, 'SubTotal', FormatDecimal(Round(AdvanceAmount, 1, '='), 0));
        AddAttribute(XMLDoc, XMLCurrNode, 'Moneda', 'XXX');

        AddAttribute(XMLDoc, XMLCurrNode, 'Total', FormatDecimal(Round(AdvanceAmount, 1, '='), 0));
        AddAttribute(XMLDoc, XMLCurrNode, 'TipoDeComprobante', 'E');
        // Egreso
        AddAttribute(XMLDoc, XMLCurrNode, 'Exportacion', TempDocumentHeader."CFDI Export Code");

        AddAttribute(XMLDoc, XMLCurrNode, 'MetodoPago', 'PUE');
        AddAttribute(XMLDoc, XMLCurrNode, 'LugarExpedicion', CompanyInfo."SAT Postal Code");

        InitCFDIRelatedDocuments(TempCFDIRelationDocument, UUID, GetAdvanceCFDIRelation(TempDocumentHeader."CFDI Relation"));
        AddNodeRelacionado(XMLDoc, XMLCurrNode, XMLNewChild, TempCFDIRelationDocument);
        // CfdiRelacionados
        // Emisor
        AddNodeCompanyInfo(XMLDoc, XMLCurrNode);
        // Receptor
        AddNodeReceptor(
              XMLDoc, XMLCurrNode, Customer, Customer."CFDI Customer Name", TempDocumentHeader."Bill-to/Pay-To Post Code", 'P01');

        // Conceptos
        AddElementCFDI(XMLCurrNode, 'Conceptos', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        // Conceptos->Concepto
        // Just ONE concept
        AddElementCFDI(XMLCurrNode, 'Concepto', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddAttribute(XMLDoc, XMLCurrNode, 'ClaveProdServ', '84111506');
        AddAttribute(XMLDoc, XMLCurrNode, 'Cantidad', Format(1));
        AddAttribute(XMLDoc, XMLCurrNode, 'ClaveUnidad', 'ACT');
        AddAttribute(XMLDoc, XMLCurrNode, 'Descripcion', 'Aplicacion de anticipo');

        AddAttribute(XMLDoc, XMLCurrNode, 'ValorUnitario', FormatDecimal(Round(AdvanceAmount, 1, '='), 0));
        AddAttribute(XMLDoc, XMLCurrNode, 'Importe', FormatDecimal(Round(AdvanceAmount, 1, '='), 0));

        AddAttribute(XMLDoc, XMLCurrNode, 'Descuento', FormatDecimal(0, 0));
    end;

    local procedure CreateXMLDocument33Transfer(var TempDocumentHeader: Record "Document Header" temporary; var TempDocumentLine: Record "Document Line" temporary; DateTimeFirstReqSent: Text[50]; SignedString: Text; Certificate: Text; CertificateSerialNo: Text[250]; var XMLDoc: DotNet XmlDocument)
    var
        Customer: Record Customer;
        Location: Record Location;
        FixedAsset: Record "Fixed Asset";
        Employee: Record Employee;
        Item: Record Item;
        CFDITransportOperator: Record "CFDI Transport Operator";
        TempDocumentLineCCE: Record "Document Line" temporary;
        SATUtilities: Codeunit "SAT Utilities";
        XMLCurrNode: DotNet XmlNode;
        XMLNewChild: DotNet XmlNode;
        NumeroPedimento: Text;
        HazardousMatExists: Boolean;
        SATClassificationCode: Code[10];
        DestinationRFCNo: Code[30];
        ForeignRegId: Code[30];
        FiscalResidence: Code[10];
    begin
        InitXMLCartaPorte(XMLDoc, XMLCurrNode, TempDocumentHeader."Foreign Trade");
        GetCustomer(Customer, TempDocumentHeader."Bill-to/Pay-To No.", false);
        AddAttribute(XMLDoc, XMLCurrNode, 'Version', '4.0');
        AddAttribute(XMLDoc, XMLCurrNode, 'Folio', TempDocumentHeader."No.");
        AddAttribute(XMLDoc, XMLCurrNode, 'Fecha', DateTimeFirstReqSent);
        AddAttribute(XMLDoc, XMLCurrNode, 'Sello', SignedString);
        AddAttribute(XMLDoc, XMLCurrNode, 'NoCertificado', CertificateSerialNo);
        AddAttribute(XMLDoc, XMLCurrNode, 'Certificado', Certificate);
        AddAttribute(XMLDoc, XMLCurrNode, 'SubTotal', '0');
        AddAttribute(XMLDoc, XMLCurrNode, 'Moneda', 'XXX');
        AddAttribute(XMLDoc, XMLCurrNode, 'Total', '0');
        AddAttribute(XMLDoc, XMLCurrNode, 'TipoDeComprobante', 'T'); // Traslado
        AddAttribute(XMLDoc, XMLCurrNode, 'Exportacion', TempDocumentHeader."CFDI Export Code");
        AddAttribute(XMLDoc, XMLCurrNode, 'LugarExpedicion', CompanyInfo."SAT Postal Code");

        // Emisor
        AddNodeCompanyInfo(XMLDoc, XMLCurrNode);

        // Receptor
        AddElementCFDI(XMLCurrNode, 'Receptor', '', CFDINamespaceTxt, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddAttribute(XMLDoc, XMLCurrNode, 'Rfc', CompanyInfo."RFC Number");
        AddAttribute(XMLDoc, XMLCurrNode, 'Nombre', RemoveInvalidChars(CompanyInfo.Name));
        AddAttribute(XMLDoc, XMLCurrNode, 'UsoCFDI', TempDocumentHeader."CFDI Purpose");
        AddAttribute(XMLDoc, XMLCurrNode, 'DomicilioFiscalReceptor', CompanyInfo."SAT Postal Code");
        AddAttribute(XMLDoc, XMLCurrNode, 'RegimenFiscalReceptor', CompanyInfo."SAT Tax Regime Classification");

        // Conceptos
        XMLCurrNode := XMLCurrNode.ParentNode;
        AddElementCFDI(XMLCurrNode, 'Conceptos', '', CFDINamespaceTxt, XMLNewChild);
        XMLCurrNode := XMLNewChild;

        // Conceptos->Concepto
        FilterDocumentLines(TempDocumentLine, TempDocumentHeader."No.");
        if TempDocumentLine.FindSet() then
            repeat
                AddElementCFDI(XMLCurrNode, 'Concepto', '', CFDINamespaceTxt, XMLNewChild);
                XMLCurrNode := XMLNewChild;
                AddAttribute(
                  XMLDoc, XMLCurrNode, 'ClaveProdServ', SATUtilities.GetSATClassification(TempDocumentLine.Type, TempDocumentLine."No."));
                AddAttribute(XMLDoc, XMLCurrNode, 'NoIdentificacion', TempDocumentLine."No.");
                AddAttribute(XMLDoc, XMLCurrNode, 'Cantidad', Format(TempDocumentLine.Quantity, 0, 9));
                AddAttribute(XMLDoc, XMLCurrNode, 'ClaveUnidad', SATUtilities.GetSATUnitofMeasure(TempDocumentLine."Unit of Measure Code"));
                AddAttribute(XMLDoc, XMLCurrNode, 'Unidad', TempDocumentLine."Unit of Measure Code");
                AddAttribute(XMLDoc, XMLCurrNode, 'Descripcion', EncodeString(TempDocumentLine.Description));
                AddAttribute(XMLDoc, XMLCurrNode, 'ValorUnitario', '0');
                AddAttribute(XMLDoc, XMLCurrNode, 'Importe', '0');
                AddAttribute(XMLDoc, XMLCurrNode, 'ObjetoImp', '01');

                if not TempDocumentHeader."Foreign Trade" then begin
                    NumeroPedimento := FormatNumeroPedimento(TempDocumentLine);
                    if NumeroPedimento <> '' then begin
                        AddElementCFDI(XMLCurrNode, 'InformacionAduanera', '', CFDINamespaceTxt, XMLNewChild);
                        XMLCurrNode := XMLNewChild;
                        AddAttributeSimple(XMLDoc, XMLCurrNode, 'NumeroPedimento', NumeroPedimento);
                        XMLCurrNode := XMLCurrNode.ParentNode;
                    end;
                end;
                XMLCurrNode := XMLCurrNode.ParentNode; // Concepto
                CalcComercioExteriorLine(TempDocumentLineCCE, TempDocumentLine, TempDocumentHeader."Foreign Trade", true);
            until TempDocumentLine.Next() = 0;
        XMLCurrNode := XMLCurrNode.ParentNode;

        // Complemento
        AddElementCFDI(XMLCurrNode, 'Complemento', '', CFDINamespaceTxt, XMLNewChild);
        XMLCurrNode := XMLNewChild;

        // ComercioExterior
        AddNodeComercioExterior(TempDocumentLineCCE, TempDocumentHeader, XMLDoc, XMLCurrNode, XMLNewChild);

        // CartaPorte
        AddElementCartaPorte(XMLCurrNode, 'CartaPorte', '', CartaPorteNamespaceTxt, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddAttribute(XMLDoc, XMLCurrNode, 'Version', '3.1');
        AddAttribute(XMLDoc, XMLCurrNode, 'IdCCP', TempDocumentHeader."Identifier IdCCP");
        if TempDocumentHeader."Foreign Trade" then begin
            AddAttribute(XMLDoc, XMLCurrNode, 'TranspInternac', 'Sí');
            AddAttribute(XMLDoc, XMLCurrNode, 'EntradaSalidaMerc', 'Salida');
            AddAttribute(XMLDoc, XMLCurrNode, 'PaisOrigenDestino', SATUtilities.GetSATCountryCode(TempDocumentHeader."Ship-to/Buy-from Country Code"));
            AddAttribute(XMLDoc, XMLCurrNode, 'ViaEntradaSalida', '01');
        end else
            AddAttribute(XMLDoc, XMLCurrNode, 'TranspInternac', 'No');
        AddAttribute(XMLDoc, XMLCurrNode, 'TotalDistRec', FormatDecimal(TempDocumentHeader."Transit Distance", 6));

        if TempDocumentHeader."Foreign Trade" then begin
            // CartaPorte/RegimenesAduaneros
            // CartaPorte/RegimenesAduaneros/RegimenAduanero
            AddElementCartaPorte(XMLCurrNode, 'RegimenesAduaneros', '', CartaPorteNamespaceTxt, XMLNewChild);
            XMLCurrNode := XMLNewChild;
            AddElementCartaPorte(XMLCurrNode, 'RegimenAduaneroCCP', '', CartaPorteNamespaceTxt, XMLNewChild);
            XMLCurrNode := XMLNewChild;
            AddAttribute(XMLDoc, XMLCurrNode, 'RegimenAduanero', TempDocumentHeader."SAT Customs Regime");
            XMLCurrNode := XMLCurrNode.ParentNode; // RegimenAduaneroCCP
            XMLCurrNode := XMLCurrNode.ParentNode; // RegimenesAduaneros
        end;

        // CartaPorte/Ubicaciones
        // CartaPorte/Ubicaciones/Origen
        AddElementCartaPorte(XMLCurrNode, 'Ubicaciones', '', CartaPorteNamespaceTxt, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        Location.Get(TempDocumentHeader."Transit-from Location");
        AddNodeCartaPorteUbicacion(
          'Origen', Location, 'OR', CompanyInfo."RFC Number", '', '',
          FormatDateTime(TempDocumentHeader."Transit-from Date/Time"), '',
          XMLDoc, XMLCurrNode, XMLNewChild);
        // CartaPorte/Ubicaciones/Destino
        GetTransferDestinationData(Location, DestinationRFCNo, ForeignRegId, FiscalResidence, TempDocumentHeader, Customer);
        AddNodeCartaPorteUbicacion(
          'Destino', Location, 'DE', DestinationRFCNo, ForeignRegId, FiscalResidence,
          FormatDateTime(TempDocumentHeader."Transit-from Date/Time" + TempDocumentHeader."Transit Hours" * 1000 * 60 * 60),
          FormatDecimal(TempDocumentHeader."Transit Distance", 6),
          XMLDoc, XMLCurrNode, XMLNewChild);
        XMLCurrNode := XMLCurrNode.ParentNode; // Ubicaciones

        // CartaPorte/Mercancias
        AddElementCartaPorte(XMLCurrNode, 'Mercancias', '', CartaPorteNamespaceTxt, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        TempDocumentLine.SetRange("Document No.", TempDocumentHeader."No.");
        TempDocumentLine.CalcSums("Gross Weight");
        AddAttribute(XMLDoc, XMLCurrNode, 'UnidadPeso', TempDocumentHeader."SAT Weight Unit Of Measure");
        AddAttribute(XMLDoc, XMLCurrNode, 'NumTotalMercancias', FormatDecimal(TempDocumentLine.Count, 0));
        AddAttribute(XMLDoc, XMLCurrNode, 'PesoBrutoTotal', FormatDecimal(TempDocumentLine."Gross Weight", 3));
        if TempDocumentLine.FindSet() then
            repeat
                if TempDocumentLine.Type = TempDocumentLine.Type::Item then
                    Item.Get(TempDocumentLine."No.")
                else
                    Item.Init();
                SATClassificationCode := SATUtilities.GetSATClassification(TempDocumentLine.Type, TempDocumentLine."No.");
                AddElementCartaPorte(XMLCurrNode, 'Mercancia', '', CartaPorteNamespaceTxt, XMLNewChild);
                XMLCurrNode := XMLNewChild;
                AddAttribute(XMLDoc, XMLCurrNode, 'BienesTransp', SATClassificationCode);
                AddAttribute(XMLDoc, XMLCurrNode, 'Descripcion', EncodeString(TempDocumentLine.Description));
                AddAttribute(XMLDoc, XMLCurrNode, 'Cantidad', Format(TempDocumentLine.Quantity, 0, 9));
                AddAttribute(XMLDoc, XMLCurrNode, 'ClaveUnidad', SATUtilities.GetSATUnitofMeasure(TempDocumentLine."Unit of Measure Code"));
                if Item."SAT Hazardous Material" <> '' then begin
                    HazardousMatExists := true;
                    AddAttribute(XMLDoc, XMLCurrNode, 'MaterialPeligroso', 'Sí');
                    AddAttribute(XMLDoc, XMLCurrNode, 'CveMaterialPeligroso', Item."SAT Hazardous Material");
                    AddAttribute(XMLDoc, XMLCurrNode, 'Embalaje', Item."SAT Packaging Type");
                end else
                    if IsHazardousMaterialMandatory(SATClassificationCode) then
                        AddAttribute(XMLDoc, XMLCurrNode, 'MaterialPeligroso', 'No');
                AddAttribute(XMLDoc, XMLCurrNode, 'PesoEnKg', FormatDecimal(TempDocumentLine."Gross Weight", 3));
                AddAttribute(XMLDoc, XMLCurrNode, 'ValorMercancia', '0');
                AddAttribute(XMLDoc, XMLCurrNode, 'Moneda', 'MXN');
                if TempDocumentHeader."Foreign Trade" then begin
                    AddAttribute(XMLDoc, XMLCurrNode, 'FraccionArancelaria', DelChr(Item."Tariff No."));
                    AddAttribute(XMLDoc, XMLCurrNode, 'UUIDComercioExt', '00000000-0000-0000-0000-000000000000');
                    AddAttribute(XMLDoc, XMLCurrNode, 'TipoMateria', Item."SAT Material Type");
                end;

                if TempDocumentHeader."Foreign Trade" and (TempDocumentLine."SAT Customs Document Type" <> '') then begin
                    AddElementCartaPorte(XMLCurrNode, 'DocumentacionAduanera', '', CartaPorteNamespaceTxt, XMLNewChild);
                    XMLCurrNode := XMLNewChild;
                    AddAttributeSimple(XMLDoc, XMLCurrNode, 'TipoDocumento', TempDocumentLine."SAT Customs Document Type");
                    AddAttributeSimple(XMLDoc, XMLCurrNode, 'IdentDocAduanero', 'identifier');
                    XMLCurrNode := XMLCurrNode.ParentNode;
                end;

                XMLCurrNode := XMLCurrNode.ParentNode; // Mercancia
            until TempDocumentLine.Next() = 0;

        // CartaPorte/Mercancias/Autotransporte 
        FixedAsset.Get(TempDocumentHeader."Vehicle Code");
        AddElementCartaPorte(XMLCurrNode, 'Autotransporte', '', CartaPorteNamespaceTxt, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddAttribute(XMLDoc, XMLCurrNode, 'PermSCT', FixedAsset."SCT Permission Type");
        AddAttribute(XMLDoc, XMLCurrNode, 'NumPermisoSCT', FixedAsset."SCT Permission No.");
        AddElementCartaPorte(XMLCurrNode, 'IdentificacionVehicular', '', CartaPorteNamespaceTxt, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddAttribute(XMLDoc, XMLCurrNode, 'ConfigVehicular', FixedAsset."SAT Federal Autotransport");
        AddAttribute(XMLDoc, XMLCurrNode, 'PesoBrutoVehicular', FormatDecimal(FixedAsset."Vehicle Gross Weight", 2));
        AddAttribute(XMLDoc, XMLCurrNode, 'PlacaVM', FixedAsset."Vehicle Licence Plate");
        AddAttribute(XMLDoc, XMLCurrNode, 'AnioModeloVM', Format(FixedAsset."Vehicle Year"));
        XMLCurrNode := XMLCurrNode.ParentNode; // IdentificacionVehicular

        // Seguros
        AddElementCartaPorte(XMLCurrNode, 'Seguros', '', CartaPorteNamespaceTxt, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddAttribute(XMLDoc, XMLCurrNode, 'AseguraRespCivil', TempDocumentHeader."Insurer Name");
        AddAttribute(XMLDoc, XMLCurrNode, 'PolizaRespCivil', TempDocumentHeader."Insurer Policy Number");
        if HazardousMatExists then begin
            AddAttribute(XMLDoc, XMLCurrNode, 'AseguraMedAmbiente', TempDocumentHeader."Medical Insurer Name");
            AddAttribute(XMLDoc, XMLCurrNode, 'PolizaMedAmbiente', TempDocumentHeader."Medical Ins. Policy Number");
        end;
        XMLCurrNode := XMLCurrNode.ParentNode; // Seguros

        if (TempDocumentHeader."Trailer 1" <> '') or (TempDocumentHeader."Trailer 2" <> '') then begin
            AddElementCartaPorte(XMLCurrNode, 'Remolques', '', CartaPorteNamespaceTxt, XMLNewChild);
            XMLCurrNode := XMLNewChild;
            if FixedAsset.Get(TempDocumentHeader."Trailer 1") then begin
                AddElementCartaPorte(XMLCurrNode, 'Remolque', '', CartaPorteNamespaceTxt, XMLNewChild);
                XMLCurrNode := XMLNewChild;
                AddAttribute(XMLDoc, XMLCurrNode, 'SubTipoRem', FixedAsset."SAT Trailer Type");
                AddAttribute(XMLDoc, XMLCurrNode, 'Placa', FixedAsset."Vehicle Licence Plate");
                XMLCurrNode := XMLCurrNode.ParentNode; // Remolque
            end;
            if FixedAsset.Get(TempDocumentHeader."Trailer 2") then begin
                AddElementCartaPorte(XMLCurrNode, 'Remolque', '', CartaPorteNamespaceTxt, XMLNewChild);
                XMLCurrNode := XMLNewChild;
                AddAttribute(XMLDoc, XMLCurrNode, 'SubTipoRem', FixedAsset."SAT Trailer Type");
                AddAttribute(XMLDoc, XMLCurrNode, 'Placa', FixedAsset."Vehicle Licence Plate");
                XMLCurrNode := XMLCurrNode.ParentNode; // Remolque
            end;
            XMLCurrNode := XMLCurrNode.ParentNode; // Remolques
        end;
        XMLCurrNode := XMLCurrNode.ParentNode; // Autotransporte
        XMLCurrNode := XMLCurrNode.ParentNode; // Mercancias

        // CartaPorte/FiguraTransporte
        AddElementCartaPorte(XMLCurrNode, 'FiguraTransporte', '', CartaPorteNamespaceTxt, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        CFDITransportOperator.SetRange("Document Table ID", TempDocumentHeader."Document Table ID");
        CFDITransportOperator.SetRange("Document No.", TempDocumentHeader."No.");
        if CFDITransportOperator.FindSet() then
            repeat
                AddElementCartaPorte(XMLCurrNode, 'TiposFigura', '', CartaPorteNamespaceTxt, XMLNewChild);
                XMLCurrNode := XMLNewChild;
                Employee.Get(CFDITransportOperator."Operator Code");
                AddAttribute(XMLDoc, XMLCurrNode, 'TipoFigura', '01'); // 01 - Autotransporte Federal
                AddAttribute(XMLDoc, XMLCurrNode, 'RFCFigura', Employee."RFC No.");
                AddAttribute(XMLDoc, XMLCurrNode, 'NumLicencia', Employee."License No.");
                AddAttribute(XMLDoc, XMLCurrNode, 'NombreFigura', EncodeString(Employee.FullName()));
                XMLCurrNode := XMLCurrNode.ParentNode; // TiposFigura
            until CFDITransportOperator.Next() = 0;
        XMLCurrNode := XMLCurrNode.ParentNode; // FiguraTransporte

        XMLCurrNode := XMLCurrNode.ParentNode; // CartaPorte

        XMLCurrNode := XMLCurrNode.ParentNode; // Complemento
    end;

    local procedure CreateXMLDocument33TaxAmountLines(var TempVATAmountLine: Record "VAT Amount Line" temporary; var XMLDoc: DotNet XmlDocument; var XMLCurrNode: DotNet XmlNode; var XMLNewChild: DotNet XmlNode; TotalTax: Decimal; TotalRetention: Decimal)
    begin
        TempVATAmountLine.Reset();
        if TempVATAmountLine.IsEmpty() then
            exit;

        // Impuestos
        AddElementCFDI(XMLCurrNode, 'Impuestos', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;

        TempVATAmountLine.SetRange(Positive, false);
        if TempVATAmountLine.FindSet() then begin
            // Impuestos->Retenciones
            AddElementCFDI(XMLCurrNode, 'Retenciones', '', DocNameSpace, XMLNewChild);
            XMLCurrNode := XMLNewChild;
            repeat
                AddElementCFDI(XMLCurrNode, 'Retencion', '', DocNameSpace, XMLNewChild);
                XMLCurrNode := XMLNewChild;
                AddAttribute(XMLDoc, XMLCurrNode, 'Impuesto', GetTaxCode(TempVATAmountLine."VAT %", TempVATAmountLine."VAT Amount"));
                AddAttribute(XMLDoc, XMLCurrNode, 'Importe', FormatAmount(TempVATAmountLine."VAT Amount"));
                XMLCurrNode := XMLCurrNode.ParentNode;
            until TempVATAmountLine.Next() = 0;
            XMLCurrNode := XMLCurrNode.ParentNode; // Retenciones
            AddAttribute(XMLDoc, XMLCurrNode, 'TotalImpuestosRetenidos', FormatAmount(TotalRetention)); // TotalImpuestosRetenidos
        end;

        TempVATAmountLine.SetRange(Positive, true);
        if TempVATAmountLine.FindSet() then begin
            // Impuestos->Traslados
            AddElementCFDI(XMLCurrNode, 'Traslados', '', DocNameSpace, XMLNewChild);
            XMLCurrNode := XMLNewChild;
            repeat
                AddElementCFDI(XMLCurrNode, 'Traslado', '', DocNameSpace, XMLNewChild);
                XMLCurrNode := XMLNewChild;

                if TempVATAmountLine."Tax Category" = GetTaxCategoryExempt() then begin
                    AddAttribute(XMLDoc, XMLCurrNode, 'Base', FormatAmount(TempVATAmountLine."VAT Base"));
                    AddAttribute(XMLDoc, XMLCurrNode, 'Impuesto', GetTaxCode(TempVATAmountLine."VAT %", TempVATAmountLine."VAT Amount"));
                    AddAttribute(XMLDoc, XMLCurrNode, 'TipoFactor', 'Exento');
                end else begin
                    AddAttribute(XMLDoc, XMLCurrNode, 'Base', FormatAmount(TempVATAmountLine."VAT Base"));
                    AddAttribute(XMLDoc, XMLCurrNode, 'Impuesto', GetTaxCode(TempVATAmountLine."VAT %", TempVATAmountLine."VAT Amount"));
                    AddAttribute(XMLDoc, XMLCurrNode, 'TipoFactor', 'Tasa');
                    AddAttribute(XMLDoc, XMLCurrNode, 'TasaOCuota', PadStr(FormatAmount(TempVATAmountLine."VAT %" / 100), 8, '0'));
                    AddAttribute(XMLDoc, XMLCurrNode, 'Importe', FormatAmount(TempVATAmountLine."VAT Amount"));
                end;

                XMLCurrNode := XMLCurrNode.ParentNode;
            until TempVATAmountLine.Next() = 0;
            XMLCurrNode := XMLCurrNode.ParentNode; // Traslados
            AddAttribute(XMLDoc, XMLCurrNode, 'TotalImpuestosTrasladados', FormatAmount(TotalTax)); // TotalImpuestosTrasladados
        end;

        XMLCurrNode := XMLCurrNode.ParentNode; // Impuestos
    end;

    procedure CreateOriginalStr33(var TempDocumentHeader: Record "Document Header" temporary; var TempDocumentLine: Record "Document Line" temporary; DateTimeFirstReqSent: Text; SubTotal: Decimal; RetainAmt: Decimal; IsCredit: Boolean; var TempBlob: Codeunit "Temp Blob")
    var
        TempDocumentLineRetention: Record "Document Line" temporary;
        TempCFDIRelationDocument: Record "CFDI Relation Document" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TotalTax: Decimal;
        TotalRetention: Decimal;
        TotalDiscount: Decimal;
    begin
        SubTotal := 0;
        RetainAmt := 0;
        TotalTax := 0;
        TotalRetention := 0;
        TotalDiscount := 0;
        CreateOriginalStr33Document(
          TempDocumentHeader, TempDocumentLine, TempDocumentLineRetention, TempCFDIRelationDocument, TempVATAmountLine,
          DateTimeFirstReqSent, IsCredit, TempBlob,
          SubTotal, TotalTax, TotalRetention, TotalDiscount);
    end;

    procedure CreateOriginalStr33WithUUID(var TempDocumentHeader: Record "Document Header" temporary; var TempDocumentLine: Record "Document Line" temporary; DateTimeFirstReqSent: Text; SubTotal: Decimal; RetainAmt: Decimal; IsCredit: Boolean; var TempBlob: Codeunit "Temp Blob"; UUID: Text[50])
    var
        TempDocumentLineRetention: Record "Document Line" temporary;
        TempCFDIRelationDocument: Record "CFDI Relation Document" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TotalTax: Decimal;
        TotalRetention: Decimal;
        TotalDiscount: Decimal;
    begin
        InitCFDIRelatedDocuments(TempCFDIRelationDocument, UUID, TempDocumentHeader."CFDI Relation");
        SubTotal := 0;
        RetainAmt := 0;
        TotalTax := 0;
        TotalRetention := 0;
        TotalDiscount := 0;
        CreateOriginalStr33Document(
          TempDocumentHeader, TempDocumentLine, TempDocumentLineRetention, TempCFDIRelationDocument, TempVATAmountLine,
          DateTimeFirstReqSent, IsCredit, TempBlob,
          SubTotal, TotalTax, TotalRetention, TotalDiscount);
    end;

    local procedure CreateOriginalStr33Document(var TempDocumentHeader: Record "Document Header" temporary; var TempDocumentLine: Record "Document Line" temporary; var TempDocumentLineRetention: Record "Document Line" temporary; var TempCFDIRelationDocument: Record "CFDI Relation Document" temporary; var TempVATAmountLine: Record "VAT Amount Line" temporary; DateTimeFirstReqSent: Text; IsCredit: Boolean; var TempBlob: Codeunit "Temp Blob"; SubTotal: Decimal; TotalTax: Decimal; TotalRetention: Decimal; TotalDiscount: Decimal)
    var
        Customer: Record Customer;
        TempDocumentLineCCE: Record "Document Line" temporary;
        SATUtilities: Codeunit "SAT Utilities";
        OutStream: OutStream;
        SATCertificateCode: Code[20];
    begin
        if not Export then
            GetCompanyInfo();
        GetCustomer(Customer, TempDocumentHeader."Bill-to/Pay-To No.", false);
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream);
        WriteOutStr(OutStream, '||4.0|');
        // Version
        WriteOutStr(OutStream, RemoveInvalidChars(TempDocumentHeader."No.") + '|');
        // Folio
        WriteOutStr(OutStream, DateTimeFirstReqSent + '|');
        // Fecha
        WriteOutStr(OutStream, SATUtilities.GetSATPaymentMethod(TempDocumentHeader."Payment Method Code") + '|');
        // FormaPago
        SATCertificateCode := GetSATCertificateCodeForDocument(TempDocumentHeader);
        WriteOutStr(OutStream, GetCertificateSerialNo(SATCertificateCode) + '|');
        // NoCertificado
        WriteOutStr(OutStream, FormatAmount(SubTotal) + '|');
        // SubTotal
        WriteOutStr(OutStream, FormatAmount(TotalDiscount) + '|');
        // Descuento
        if TempDocumentHeader."Currency Code" <> '' then begin
            WriteOutStr(OutStream, TempDocumentHeader."Currency Code" + '|');
            // Moneda
            if (TempDocumentHeader."Currency Code" <> 'MXN') and (TempDocumentHeader."Currency Code" <> 'XXX') then
                WriteOutStr(OutStream, FormatDecimal(1 / TempDocumentHeader."Currency Factor", 6) + '|');
            // TipoCambio
        end;

        WriteOutStr(OutStream, FormatAmount(TempDocumentHeader."Amount Including VAT") + '|');
        // Total
        if IsCredit then
            WriteOutStr(OutStream, Format('E') + '|')
        // Egreso
        else
            WriteOutStr(OutStream, Format('I') + '|');
        // Ingreso
        WriteOutStr(OutStream, TempDocumentHeader."CFDI Export Code" + '|');
        // Exportacion
        WriteOutStr(OutStream, SATUtilities.GetSATPaymentTerm(TempDocumentHeader."Payment Terms Code") + '|');
        // MetodoPago
        WriteOutStr(OutStream, RemoveInvalidChars(CompanyInfo."SAT Postal Code") + '|');
        // LugarExpedicion
        if Customer."CFDI General Public" then begin
            // InformacionGlobal
            WriteOutStr(OutStream, FormatPeriod(TempDocumentHeader."CFDI Period") + '|');
            // Periodicidad
            WriteOutStr(OutStream, FormatMonth(Format(Date2DMY(TempDocumentHeader."Document Date", 2))) + '|');
            // Meses
            WriteOutStr(OutStream, Format(Date2DMY(TempDocumentHeader."Document Date", 3)) + '|');
            // Año
        end;

        AddStrRelacionado(TempCFDIRelationDocument, OutStream);
        // CfdiRelacionados
        // Company Information (Emisor)
        AddStrCompanyInfo(OutStream);
        // Customer information (Receptor)
        AddStrReceptor(
              OutStream, Customer, Customer."CFDI Customer Name", TempDocumentHeader."Bill-to/Pay-To Post Code", TempDocumentHeader."CFDI Purpose");

        FilterDocumentLines(TempDocumentLine, TempDocumentHeader."No.");
        if TempDocumentLine.FindSet() then
            repeat
                WriteOutStr(OutStream, SATUtilities.GetSATClassification(TempDocumentLine.Type, TempDocumentLine."No.") + '|');
                // ClaveProdServ
                WriteOutStr(OutStream, TempDocumentLine."No." + '|');
                // NoIdentificacion
                WriteOutStr(OutStream, Format(TempDocumentLine.Quantity, 0, 9) + '|');
                // Cantidad
                WriteOutStr(OutStream, SATUtilities.GetSATUnitofMeasure(TempDocumentLine."Unit of Measure Code") + '|');
                // ClaveUnidad
                WriteOutStr(OutStream, TempDocumentLine."Unit of Measure Code" + '|');
                // Unidad
                WriteOutStr(OutStream, EncodeString(TempDocumentLine.Description) + '|');
                // Descripcion
                WriteOutStr(OutStream, FormatDecimal(TempDocumentLine."Unit Price/Direct Unit Cost", 6) + '|');
                // ValorUnitario
                WriteOutStr(OutStream, FormatDecimal(GetReportedLineAmount(TempDocumentLine), 6) + '|');
                // Importe
                WriteOutStr(OutStream, FormatDecimal(TempDocumentLine."Line Discount Amount", 6) + '|');
                // Descuento
                WriteOutStr(OutStream, GetSubjectToTaxCode(TempDocumentLine) + '|');
                // ObjetoImp
                AddStrImpuestoPerLine(TempDocumentLine, TempDocumentLineRetention, OutStream);

                WriteOutStr(OutStream, RemoveInvalidChars(FormatNumeroPedimento(TempDocumentLine)) + '|');
                // NumeroPedimento
                CalcComercioExteriorLine(TempDocumentLineCCE, TempDocumentLine, TempDocumentHeader."Foreign Trade", false);
            until TempDocumentLine.Next() = 0;

        CreateOriginalStr33TaxAmountLines(
          TempVATAmountLine, OutStream, TotalTax, TotalRetention);
        // ComercioExterior
        AddStrComercioExterior(TempDocumentLineCCE, TempDocumentHeader, OutStream);

        WriteOutStrAllowOneCharacter(OutStream, '|');
    end;

    procedure CreateOriginalStr33AdvanceSettleDetailed(var TempDocumentHeader: Record "Document Header" temporary; var TempDocumentLine: Record "Document Line" temporary; var TempDocumentLineRetention: Record "Document Line" temporary; var TempVATAmountLine: Record "VAT Amount Line" temporary; DateTimeFirstReqSent: Text; var TempBlob: Codeunit "Temp Blob"; UUID: Text[50]; SubTotal: Decimal; TotalTax: Decimal; TotalRetention: Decimal; TotalDiscount: Decimal)
    var
        Customer: Record Customer;
        TempCFDIRelationDocument: Record "CFDI Relation Document" temporary;
        SATUtilities: Codeunit "SAT Utilities";
        OutStream: OutStream;
        SATCertificateCode: Code[20];
    begin
        if not Export then
            GetCompanyInfo();
        GetCustomer(Customer, TempDocumentHeader."Bill-to/Pay-To No.", false);
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream);
        WriteOutStr(OutStream, '||4.0|');
        // Version
        WriteOutStr(OutStream, RemoveInvalidChars(TempDocumentHeader."No.") + '|');
        // Folio
        WriteOutStr(OutStream, DateTimeFirstReqSent + '|');
        // Fecha
        WriteOutStr(OutStream, '30|');
        // FormaPago
        SATCertificateCode := GetSATCertificateCodeForDocument(TempDocumentHeader);
        WriteOutStr(OutStream, GetCertificateSerialNo(SATCertificateCode) + '|');
        // NoCertificado
        if TempDocumentHeader."Currency Code" <> '' then begin
            WriteOutStr(OutStream, TempDocumentHeader."Currency Code" + '|');
            // Moneda
            if (TempDocumentHeader."Currency Code" <> 'MXN') and (TempDocumentHeader."Currency Code" <> 'XXX') then
                WriteOutStr(OutStream, FormatDecimal(1 / TempDocumentHeader."Currency Factor", 6) + '|');
            // TipoCambio
        end;

        WriteOutStr(OutStream, FormatAmount(SubTotal - TotalDiscount + TotalTax - TotalRetention) + '|');
        // Total
        // OutStream.WRITETEXT(FormatAmount("Amount Including VAT" + TotalDiscount + AdvanceAmount) + '|'); // Total
        WriteOutStr(OutStream, Format('I') + '|');
        // Ingreso -- TipoDeComprante
        WriteOutStr(OutStream, TempDocumentHeader."CFDI Export Code" + '|');
        // Exportacion
        WriteOutStr(OutStream, SATUtilities.GetSATPaymentTerm(TempDocumentHeader."Payment Terms Code") + '|');
        // MetodoPago
        WriteOutStr(OutStream, RemoveInvalidChars(CompanyInfo."SAT Postal Code") + '|');
        // LugarExpedicion
        // Related documents
        InitCFDIRelatedDocuments(TempCFDIRelationDocument, UUID, TempDocumentHeader."CFDI Relation");
        AddStrRelacionado(TempCFDIRelationDocument, OutStream);
        // CfdiRelacionados
        // Company Information (Emisor)
        AddStrCompanyInfo(OutStream);
        // Customer information (Receptor)
        AddStrReceptor(
              OutStream, Customer, Customer."CFDI Customer Name", TempDocumentHeader."Bill-to/Pay-To Post Code", TempDocumentHeader."CFDI Purpose");

        FilterDocumentLines(TempDocumentLine, TempDocumentHeader."No.");

        if TempDocumentLine.FindSet() then
            repeat
                WriteOutStr(OutStream, SATUtilities.GetSATClassification(TempDocumentLine.Type, TempDocumentLine."No.") + '|');
                // ClaveProdServ
                WriteOutStr(OutStream, TempDocumentLine."No." + '|');
                // NoIdentificacion
                WriteOutStr(OutStream, Format(TempDocumentLine.Quantity, 0, 9) + '|');
                // Cantidad
                WriteOutStr(OutStream, SATUtilities.GetSATUnitofMeasure(TempDocumentLine."Unit of Measure Code") + '|');
                // ClaveUnidad
                WriteOutStr(OutStream, TempDocumentLine."Unit of Measure Code" + '|');
                // Unidad
                WriteOutStr(OutStream, EncodeString(TempDocumentLine.Description) + '|');
                // Descripcion
                WriteOutStr(OutStream, FormatDecimal(TempDocumentLine."Unit Price/Direct Unit Cost", 6) + '|');
                // ValorUnitario
                WriteOutStr(OutStream, FormatDecimal(GetReportedLineAmount(TempDocumentLine), 6) + '|');
                // Importe
                WriteOutStr(OutStream, FormatDecimal(TempDocumentLine."Line Discount Amount", 6) + '|');
                // Descuento
                WriteOutStr(OutStream, GetSubjectToTaxCode(TempDocumentLine) + '|');
                // ObjetoImp
                TotalDiscount := TotalDiscount + TempDocumentLine."Line Discount Amount";

                AddStrImpuestoPerLine(TempDocumentLine, TempDocumentLineRetention, OutStream);
            until TempDocumentLine.Next() = 0;

        CreateOriginalStr33TaxAmountLines(
          TempVATAmountLine, OutStream, TotalTax, TotalRetention);
        // ComercioExterior
        AddStrComercioExterior(TempDocumentLine, TempDocumentHeader, OutStream);

        WriteOutStrAllowOneCharacter(OutStream, '|');
    end;

    procedure CreateOriginalStr33AdvancePayment(var TempDocumentHeader: Record "Document Header" temporary; var TempDocumentLine: Record "Document Line" temporary; DateTimeFirstReqSent: Text; SubTotal: Decimal; RetainAmt: Decimal; var TempBlob: Codeunit "Temp Blob")
    var
        Customer: Record Customer;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        SATUtilities: Codeunit "SAT Utilities";
        OutStream: OutStream;
        SATCertificateCode: Code[20];
    begin
        if not Export then
            GetCompanyInfo();
        GetCustomer(Customer, TempDocumentHeader."Bill-to/Pay-To No.", false);
        SATCertificateCode := GetSATCertificateCodeForDocument(TempDocumentHeader);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream);
        WriteOutStr(OutStream, '||4.0|'); // Version
        WriteOutStr(OutStream, RemoveInvalidChars(TempDocumentHeader."No.") + '|'); // Folio
        WriteOutStr(OutStream, DateTimeFirstReqSent + '|'); // Fecha
        WriteOutStr(OutStream, SATUtilities.GetSATPaymentMethod(TempDocumentHeader."Payment Method Code") + '|'); // FormaPago
        WriteOutStr(OutStream, GetCertificateSerialNo(SATCertificateCode) + '|'); // NoCertificado
        WriteOutStr(OutStream, FormatAmount(SubTotal) + '|'); // SubTotal

        WriteOutStr(OutStream, ConvertCurrency(TempDocumentHeader."Currency Code") + '|'); // Moneda
        if ConvertCurrency(TempDocumentHeader."Currency Code") <> GLSetup."LCY Code" then
            WriteOutStr(OutStream, FormatDecimal(1 / TempDocumentHeader."Currency Factor", 6) + '|'); // TipoCambio

        WriteOutStr(OutStream, FormatAmount(SubTotal + RetainAmt) + '|'); // Total
        WriteOutStr(OutStream, Format('I') + '|'); // TipoDeComprobante
        WriteOutStr(OutStream, TempDocumentHeader."CFDI Export Code" + '|'); // Exportacion

        WriteOutStr(OutStream, 'PUE|'); // MetodoPago
        WriteOutStr(OutStream, RemoveInvalidChars(CompanyInfo."SAT Postal Code") + '|'); // LugarExpedicion

        // Company Information (Emisor)
        AddStrCompanyInfo(OutStream);

        // Customer information (Receptor)
        AddStrReceptor(
              OutStream, Customer, Customer."CFDI Customer Name", TempDocumentHeader."Bill-to/Pay-To Post Code", TempDocumentHeader."CFDI Purpose");

        // Write the one line
        WriteOutStr(OutStream, '84111506|'); // ClaveProdServ // 84111506 “Servicios de facturación”
        WriteOutStr(OutStream, Format(1) + '|'); // Cantidad
        WriteOutStr(OutStream, 'ACT|'); // ClaveUnidad
        WriteOutStr(OutStream, 'Anticipo bien o servicio|'); // Descripcion
        WriteOutStr(OutStream, FormatAmount(SubTotal) + '|'); // ValorUnitario
        WriteOutStr(OutStream, FormatAmount(SubTotal) + '|'); // Importe

        FilterDocumentLines(TempDocumentLine, TempDocumentHeader."No.");
        if TempDocumentLine.FindFirst() then begin
            WriteOutStr(outstream, GetSubjectToTaxCode(TempDocumentLine) + '|'); // ObjetoImp
            AddStrImpuestoPerLine(TempDocumentLine, TempDocumentLine, OutStream);
            InsertTempVATAmountLine(TempVATAmountLine, TempDocumentLine);
        end;

        CreateOriginalStr33TaxAmountLines(TempVATAmountLine, OutStream, TempDocumentLine."Amount Including VAT" - TempDocumentLine.Amount, 0);
        WriteOutStrAllowOneCharacter(OutStream, '|');
    end;

    procedure CreateOriginalStr33AdvanceReverse(var TempDocumentHeader: Record "Document Header" temporary; DateTimeReqSent: Text; var TempBlob: Codeunit "Temp Blob"; UUID: Text[50]; AdvanceAmount: Decimal)
    var
        Customer: Record Customer;
        OutStream: OutStream;
        SATCertificateCode: Code[20];
    begin
        if not Export then
            GetCompanyInfo();
        GetCustomer(Customer, TempDocumentHeader."Bill-to/Pay-To No.", false);
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream);
        WriteOutStr(OutStream, '||4.0|');
        // Version
        WriteOutStr(OutStream, RemoveInvalidChars(TempDocumentHeader."No.") + '|');
        // Folio
        WriteOutStr(OutStream, DateTimeReqSent + '|');
        // Fecha
        WriteOutStr(OutStream, '30|');
        // FormaPago
        SATCertificateCode := GetSATCertificateCodeForDocument(TempDocumentHeader);
        WriteOutStr(OutStream, GetCertificateSerialNo(SATCertificateCode) + '|');
        // NoCertificado
        WriteOutStr(OutStream, FormatDecimal(Round(AdvanceAmount, 1, '='), 0) + '|');
        // SubTotal
        WriteOutStr(OutStream, 'XXX|');
        // Moneda
        WriteOutStr(OutStream, FormatDecimal(Round(AdvanceAmount, 1, '='), 0) + '|');
        // Total
        WriteOutStr(OutStream, Format('E') + '|');
        // TipoDeComprobante
        WriteOutStr(OutStream, TempDocumentHeader."CFDI Export Code" + '|');
        // Exportacion
        WriteOutStr(OutStream, 'PUE|');
        // MetodoPago
        WriteOutStr(OutStream, RemoveInvalidChars(CompanyInfo."SAT Postal Code") + '|');
        // LugarExpedicion
        // Related documents
        WriteOutStr(OutStream, GetAdvanceCFDIRelation(TempDocumentHeader."CFDI Relation") + '|');
        // TipoRelacion
        WriteOutStr(OutStream, UUID + '|');
        // UUID
        // Company Information (Emisor)
        AddStrCompanyInfo(OutStream);
        // Customer information (Receptor)	    
        AddStrReceptor(
              OutStream, Customer, Customer."CFDI Customer Name", TempDocumentHeader."Bill-to/Pay-To Post Code", 'P01');

        WriteOutStr(OutStream, '84111506|');
        // ClaveProdServ
        WriteOutStr(OutStream, Format(1) + '|');
        // Cantidad
        WriteOutStr(OutStream, 'ACT|');
        // ClaveUnidad
        WriteOutStr(OutStream, 'Aplicacion de anticipo|');
        // Descripcion
        WriteOutStr(OutStream, FormatDecimal(Round(AdvanceAmount, 1, '='), 0) + '|');
        // ValorUnitario
        WriteOutStr(OutStream, FormatDecimal(Round(AdvanceAmount, 1, '='), 0) + '|');
        // Importe
        WriteOutStr(OutStream, FormatDecimal(0, 0) + '||'); // Descuento
    end;

    local procedure CreateOriginalStr33Transfer(var TempDocumentHeader: Record "Document Header" temporary; var TempDocumentLine: Record "Document Line" temporary; DateTimeFirstReqSent: Text; var TempBlob: Codeunit "Temp Blob")
    var
        Customer: Record Customer;
        Location: Record Location;
        FixedAsset: Record "Fixed Asset";
        Employee: Record Employee;
        Item: Record Item;
        CFDITransportOperator: Record "CFDI Transport Operator";
        TempDocumentLineCCE: Record "Document Line" temporary;
        SATUtilities: Codeunit "SAT Utilities";
        OutStream: OutStream;
        HazardousMatExists: Boolean;
        SATClassificationCode: Code[10];
        DestinationRFCNo: Code[30];
        ForeignRegId: Code[30];
        FiscalResidence: Code[10];
        SATCertificateCode: Code[20];
    begin
        GetCustomer(Customer, TempDocumentHeader."Bill-to/Pay-To No.", false);
        SATCertificateCode := GetSATCertificateCodeForDocument(TempDocumentHeader);
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream);
        WriteOutStr(OutStream, '||4.0|'); // Version

        WriteOutStr(OutStream, RemoveInvalidChars(TempDocumentHeader."No.") + '|'); // Folio
        WriteOutStr(OutStream, DateTimeFirstReqSent + '|'); // Fecha
        WriteOutStr(OutStream, GetCertificateSerialNo(SATCertificateCode) + '|'); // NoCertificado
        WriteOutStr(OutStream, '0|'); // SubTotal
        WriteOutStr(OutStream, 'XXX|'); // Moneda
        WriteOutStr(OutStream, '0|'); // Total
        WriteOutStr(OutStream, 'T|'); // Traslado
        WriteOutStr(OutStream, TempDocumentHeader."CFDI Export Code" + '|'); // Exportacion
        WriteOutStr(OutStream, RemoveInvalidChars(CompanyInfo."SAT Postal Code") + '|'); // LugarExpedicion

        // Company Information (Emisor)
        AddStrCompanyInfo(OutStream);

        // Customer information (Receptor)
        WriteOutStr(OutStream, CompanyInfo."RFC Number" + '|'); // Rfc
        WriteOutStr(OutStream, RemoveInvalidChars(CompanyInfo.Name) + '|'); // Nombre
        WriteOutStr(OutStream, CompanyInfo."SAT Postal Code" + '|'); // DomicilioFiscalReceptor
        WriteOutStr(OutStream, CompanyInfo."SAT Tax Regime Classification" + '|'); // RegimenFiscalReceptor
        WriteOutStr(OutStream, RemoveInvalidChars(TempDocumentHeader."CFDI Purpose") + '|'); // UsoCFDI

        FilterDocumentLines(TempDocumentLine, TempDocumentHeader."No.");
        if TempDocumentLine.FindSet() then
            repeat
                WriteOutStr(OutStream, SATUtilities.GetSATClassification(TempDocumentLine.Type, TempDocumentLine."No.") + '|'); // ClaveProdServ
                WriteOutStr(OutStream, TempDocumentLine."No." + '|'); // NoIdentificacion
                WriteOutStr(OutStream, Format(TempDocumentLine.Quantity, 0, 9) + '|'); // Cantidad
                WriteOutStr(OutStream, SATUtilities.GetSATUnitofMeasure(TempDocumentLine."Unit of Measure Code") + '|'); // ClaveUnidad
                WriteOutStr(OutStream, TempDocumentLine."Unit of Measure Code" + '|'); // Unidad
                WriteOutStr(OutStream, EncodeString(TempDocumentLine.Description) + '|'); // Descripcion
                WriteOutStr(OutStream, '0|'); // ValorUnitario
                WriteOutStr(OutStream, '0|'); // Importe
                WriteOutStr(OutStream, '01|'); // ObjetoImp

                if not TempDocumentHeader."Foreign Trade" then
                    WriteOutStr(OutStream, RemoveInvalidChars(FormatNumeroPedimento(TempDocumentLine)) + '|'); // NumeroPedimento

                CalcComercioExteriorLine(TempDocumentLineCCE, TempDocumentLine, TempDocumentHeader."Foreign Trade", true);
            until TempDocumentLine.Next() = 0;

        // ComercioExterior
        AddStrComercioExterior(TempDocumentLineCCE, TempDocumentHeader, OutStream);

        // CartaPorte/Ubicaciones
        WriteOutStr(OutStream, '3.1|'); // Version
        WriteOutStr(OutStream, TempDocumentHeader."Identifier IdCCP" + '|'); // IdCartaPorte
        if TempDocumentHeader."Foreign Trade" then begin
            WriteOutStr(OutStream, 'Sí' + '|'); // TranspInternac 
            WriteOutStr(OutStream, 'Salida|'); // EntradaSalidaMerc
            WriteOutStr(OutStream, SATUtilities.GetSATCountryCode(TempDocumentHeader."Ship-to/Buy-from Country Code") + '|'); // PaisOrigenDestino
            WriteOutStr(OutStream, '01|'); // ViaEntradaSalida
        end else
            WriteOutStr(OutStream, 'No|'); // TranspInternac

        WriteOutStr(OutStream, FormatDecimal(TempDocumentHeader."Transit Distance", 6) + '|'); // TotalDistRec

        // CartaPorte/RegimenesAduaneros
        if TempDocumentHeader."Foreign Trade" then
            WriteOutStr(OutStream, TempDocumentHeader."SAT Customs Regime" + '|'); // RegimenAduanero

        // CartaPorte/Ubicaciones
        // CartaPorte/Ubicacion/Origen
        Location.Get(TempDocumentHeader."Transit-from Location");
        AddStrCartaPorteUbicacion(
          'Origen', Location, 'OR', CompanyInfo."RFC Number", '', '',
          FormatDateTime(TempDocumentHeader."Transit-from Date/Time"), '',
          OutStream);
        // CartaPorte/Ubicacion/Destino
        GetTransferDestinationData(Location, DestinationRFCNo, ForeignRegId, FiscalResidence, TempDocumentHeader, Customer);
        AddStrCartaPorteUbicacion(
          'Destino', Location, 'DE', DestinationRFCNo, ForeignRegId, FiscalResidence,
          FormatDateTime(TempDocumentHeader."Transit-from Date/Time" + TempDocumentHeader."Transit Hours" * 1000 * 60 * 60),
          FormatDecimal(TempDocumentHeader."Transit Distance", 6),
          OutStream);

        // CartaPorte/Mercancias
        TempDocumentLine.SetRange("Document No.", TempDocumentHeader."No.");
        TempDocumentLine.CalcSums("Gross Weight");
        WriteOutStr(OutStream, FormatDecimal(TempDocumentLine."Gross Weight", 3) + '|'); // PesoBrutoTotal
        WriteOutStr(OutStream, TempDocumentHeader."SAT Weight Unit Of Measure" + '|'); // UnidadPeso
        WriteOutStr(OutStream, FormatDecimal(TempDocumentLine.Count, 0) + '|'); // NumTotalMercancias
        if TempDocumentLine.FindSet() then
            repeat
                if TempDocumentLine.Type = TempDocumentLine.Type::Item then
                    Item.Get(TempDocumentLine."No.")
                else
                    Item.Init();
                SATClassificationCode := SATUtilities.GetSATClassification(TempDocumentLine.Type, TempDocumentLine."No.");
                WriteOutStr(OutStream, SATClassificationCode + '|'); // BienesTransp
                WriteOutStr(OutStream, EncodeString(TempDocumentLine.Description) + '|'); // Descripcion
                WriteOutStr(OutStream, Format(TempDocumentLine.Quantity, 0, 9) + '|'); // Cantidad
                WriteOutStr(OutStream, SATUtilities.GetSATUnitofMeasure(TempDocumentLine."Unit of Measure Code") + '|'); // ClaveUnidad
                if Item."SAT Hazardous Material" <> '' then begin
                    HazardousMatExists := true;
                    WriteOutStr(OutStream, 'Sí|'); // MaterialPeligroso
                    WriteOutStr(OutStream, Item."SAT Hazardous Material" + '|'); // CveMaterialPeligroso
                    WriteOutStr(OutStream, Item."SAT Packaging Type" + '|'); // Embalaje
                end else
                    if IsHazardousMaterialMandatory(SATClassificationCode) then
                        WriteOutStr(OutStream, 'No|');

                WriteOutStr(OutStream, FormatDecimal(TempDocumentLine."Gross Weight", 3) + '|'); // PesoEnKg
                WriteOutStr(OutStream, '0|'); // ValorMercancia
                WriteOutStr(OutStream, 'MXN|'); // Moneda
                if TempDocumentHeader."Foreign Trade" then begin
                    WriteOutStr(OutStream, DelChr(Item."Tariff No.") + '|'); // FraccionArancelaria                    
                    WriteOutStr(OutStream, '00000000-0000-0000-0000-000000000000' + '|'); // UUIDComercioExt
                    WriteOutStr(OutStream, Item."SAT Material Type" + '|'); // TipoMateria
                end;

                if TempDocumentHeader."Foreign Trade" and (TempDocumentLine."SAT Customs Document Type" <> '') then begin
                    WriteOutStr(OutStream, TempDocumentLine."SAT Customs Document Type" + '|'); // TipoDocumento
                    WriteOutStr(OutStream, 'identifier|'); // IdentDocAduanero
                end;

            until TempDocumentLine.Next() = 0;

        // CartaPorte/Mercancias/Autotransporte 
        FixedAsset.Get(TempDocumentHeader."Vehicle Code");
        WriteOutStr(OutStream, FixedAsset."SCT Permission Type" + '|'); // PermSCT
        WriteOutStr(OutStream, FixedAsset."SCT Permission No." + '|'); // NumPermisoSCT
        WriteOutStr(OutStream, FixedAsset."SAT Federal Autotransport" + '|'); // ConfigVehicular
        WriteOutStr(OutStream, FormatDecimal(FixedAsset."Vehicle Gross Weight", 2) + '|'); // PesoBrutoVehicular
        WriteOutStr(OutStream, FixedAsset."Vehicle Licence Plate" + '|'); // PlacaVM
        WriteOutStr(OutStream, Format(FixedAsset."Vehicle Year") + '|'); // AnioModeloVM

        // Seguros
        WriteOutStr(OutStream, TempDocumentHeader."Insurer Name" + '|'); // AseguraRespCivil
        WriteOutStr(OutStream, TempDocumentHeader."Insurer Policy Number" + '|'); // PolizaRespCivil
        if HazardousMatExists then begin
            WriteOutStr(OutStream, TempDocumentHeader."Medical Insurer Name" + '|'); // AseguraMedAmbiente
            WriteOutStr(OutStream, TempDocumentHeader."Medical Ins. Policy Number" + '|'); // PolizaMedAmbiente
        end;

        if (TempDocumentHeader."Trailer 1" <> '') or (TempDocumentHeader."Trailer 2" <> '') then begin
            if FixedAsset.Get(TempDocumentHeader."Trailer 1") then begin
                WriteOutStr(OutStream, FixedAsset."SAT Trailer Type" + '|'); // SubTipoRem
                WriteOutStr(OutStream, FixedAsset."Vehicle Licence Plate" + '|'); // Placa
            end;
            if FixedAsset.Get(TempDocumentHeader."Trailer 2") then begin
                WriteOutStr(OutStream, FixedAsset."SAT Trailer Type" + '|'); // SubTipoRem
                WriteOutStr(OutStream, FixedAsset."Vehicle Licence Plate" + '|'); // Placa
            end;
        end;

        // CartaPorte/FiguraTransporte
        CFDITransportOperator.SetRange("Document Table ID", TempDocumentHeader."Document Table ID");
        CFDITransportOperator.SetRange("Document No.", TempDocumentHeader."No.");
        if CFDITransportOperator.FindSet() then
            repeat
                Employee.Get(CFDITransportOperator."Operator Code");
                WriteOutStr(OutStream, '01|'); // TipoFigura
                WriteOutStr(OutStream, Employee."RFC No." + '|'); // RFCFigura
                WriteOutStr(OutStream, Employee."License No." + '|'); // NumLicencia
                WriteOutStr(OutStream, EncodeString(Employee.FullName()) + '|'); // NombreFigura
            until CFDITransportOperator.Next() = 0;

        WriteOutStrAllowOneCharacter(OutStream, '|');
    end;

    local procedure CreateOriginalStr33TaxAmountLines(var TempVATAmountLine: Record "VAT Amount Line" temporary; var OutStream: OutStream; TotalTax: Decimal; TotalRetention: Decimal)
    begin
        TempVATAmountLine.Reset();
        if TempVATAmountLine.IsEmpty() then
            exit;

        TempVATAmountLine.SetRange(Positive, false);
        if TempVATAmountLine.FindSet() then begin
            repeat
                WriteOutStr(OutStream, GetTaxCode(TempVATAmountLine."VAT %", TempVATAmountLine."VAT Amount") + '|'); // Impuesto
                WriteOutStr(OutStream, FormatAmount(TempVATAmountLine."VAT Amount") + '|'); // Importe
            until TempVATAmountLine.Next() = 0;
            WriteOutStr(OutStream, FormatAmount(TotalRetention) + '|'); // TotalImpuestosRetenidos
        end;

        TempVATAmountLine.SetRange(Positive, true);
        if TempVATAmountLine.FindSet() then begin
            repeat
                if TempVATAmountLine."Tax Category" = GetTaxCategoryExempt() then begin
                    WriteOutStr(OutStream, FormatAmount(TempVATAmountLine."VAT Base") + '|'); // Base
                    WriteOutStr(OutStream, GetTaxCode(TempVATAmountLine."VAT %", TempVATAmountLine."VAT Amount") + '|'); // Impuesto
                    WriteOutStr(OutStream, 'Exento' + '|'); // TipoFactor
                end else begin
                    WriteOutStr(OutStream, FormatAmount(TempVATAmountLine."VAT Base") + '|'); // Base
                    WriteOutStr(OutStream, GetTaxCode(TempVATAmountLine."VAT %", TempVATAmountLine."VAT Amount") + '|'); // Impuesto
                    WriteOutStr(OutStream, 'Tasa' + '|'); // TipoFactor
                    WriteOutStr(OutStream, PadStr(FormatAmount(TempVATAmountLine."VAT %" / 100), 8, '0') + '|'); // TasaOCuota
                    WriteOutStr(OutStream, FormatAmount(TempVATAmountLine."VAT Amount") + '|'); // Importe
                end;
            until TempVATAmountLine.Next() = 0;
            WriteOutStr(OutStream, FormatAmount(TotalTax) + '|'); // TotalImpuestosTrasladados
        end;
    end;

    local procedure CreateDigitalSignature(OriginalString: Text; var SignedString: Text; var SerialNoOfCertificateUsed: Text[250]; var CertificateString: Text)
    begin
        GetGLSetup();
        CreateDigitalSignature(OriginalString, GLSetup."SAT Certificate", SignedString, SerialNoOfCertificateUsed, CertificateString);
    end;

    local procedure CreateDigitalSignature(OriginalString: Text; SATCertificateCode: Code[20]; var SignedString: Text; var SerialNoOfCertificateUsed: Text[250]; var CertificateString: Text)
    var
        IsolatedCertificate: Record "Isolated Certificate";
        CertificateManagement: Codeunit "Certificate Management";
    begin
        GetGLSetupOnce();
        if not GLSetup."Sim. Signature" then begin
            IsolatedCertificate.Get(SATCertificateCode);

            if not SignDataWithCert(SignedString,
                 OriginalString, CertificateManagement.GetCertAsBase64String(IsolatedCertificate), CertificateManagement.GetPasswordAsSecret(IsolatedCertificate))
            then begin
                Session.LogMessage(
                    '0000C7Q', StrSubstNo(SATCertificateNotValidErr, GetLastErrorText()),
                    Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
                Error(SATNotValidErr);
            end;

            CertificateString := EInvoiceCommunication.LastUsedCertificate();
            SerialNoOfCertificateUsed := CopyStr(EInvoiceCommunication.LastUsedCertificateSerialNo(), 1, MaxStrLen(SerialNoOfCertificateUsed));
        end else begin
            SignedString := OriginalString;
            CertificateString := '';
            SerialNoOfCertificateUsed := '';
        end;
    end;

    local procedure SaveAsPDFOnServer(var TempBlobPDF: codeunit "Temp Blob"; DocumentHeaderRef: RecordRef; ReportNo: Integer) PDFFileName: Text
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        FileManagement: Codeunit "File Management";
        DestinationFilePath: Text;
    begin
        DestinationFilePath := FileManagement.GetDirectoryName(FileManagement.ServerTempFileName(''));
        DestinationFilePath := DelChr(DestinationFilePath, '>', '\');
        DestinationFilePath += '\';
        case DocumentHeaderRef.Number of
            DATABASE::"Sales Invoice Header":
                begin
                    DocumentHeaderRef.SetTable(SalesInvoiceHeader);
                    SalesInvoiceHeader.SetRecFilter();
                    PDFFileName := SalesInvoiceHeader."No." + '.pdf';
                    DestinationFilePath += PDFFileName;
                    REPORT.SaveAsPdf(ReportNo, DestinationFilePath, SalesInvoiceHeader);
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    DocumentHeaderRef.SetTable(SalesCrMemoHeader);
                    SalesCrMemoHeader.SetRecFilter();
                    PDFFileName := SalesCrMemoHeader."No." + '.pdf';
                    DestinationFilePath += PDFFileName;
                    REPORT.SaveAsPdf(ReportNo, DestinationFilePath, SalesCrMemoHeader);
                end;
            DATABASE::"Service Invoice Header":
                begin
                    DocumentHeaderRef.SetTable(ServiceInvoiceHeader);
                    ServiceInvoiceHeader.SetRecFilter();
                    PDFFileName := ServiceInvoiceHeader."No." + '.pdf';
                    DestinationFilePath += PDFFileName;
                    REPORT.SaveAsPdf(ReportNo, DestinationFilePath, ServiceInvoiceHeader);
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    DocumentHeaderRef.SetTable(ServiceCrMemoHeader);
                    ServiceCrMemoHeader.SetRecFilter();
                    PDFFileName := ServiceCrMemoHeader."No." + '.pdf';
                    DestinationFilePath += PDFFileName;
                    REPORT.SaveAsPdf(ReportNo, DestinationFilePath, ServiceCrMemoHeader);
                end;
        end;
        if DestinationFilePath <> '' then begin
            FileManagement.BLOBImportFromServerFile(TempBlobPDF, DestinationFilePath);
            FileManagement.DeleteServerFile(DestinationFilePath);
        end;
    end;

    local procedure SendEmail(var TempBlobPDF: codeunit "Temp Blob"; SendToAddress: Text; Subject: Text; MessageBody: Text; FilePathEDoc: Text; FileNamePDF: Text; XMLInstream: InStream)
    var
        EmailAccount: Record "Email Account";
        Email: Codeunit Email;
        Message: Codeunit "Email Message";
        EmailScenario: Codeunit "Email Scenario";
        Recipients: List of [Text];
        SendOK: Boolean;
        PDFInStream: InStream;
    begin
        GetGLSetup();
        if GLSetup."Sim. Send" then
            exit;

        Recipients.Add(SendToAddress);

        Message.Create(Recipients, Subject, MessageBody, true);
        Message.AddAttachment(CopyStr(FilePathEDoc, 1, 250), 'Document', XMLInstream);
        if FileNamePDF <> '' then begin
            TempBlobPDF.CreateInStream(PDFInStream);
            Message.AddAttachment(CopyStr(FileNamePDF, 1, 250), 'PDF', PDFInStream);
        end;
        EmailScenario.GetEmailAccount(Enum::"Email Scenario"::Default, EmailAccount);
        ClearLastError();
        SendOK := Email.Send(Message, EmailAccount."Account Id", EmailAccount.Connector);

        if not SendOK then begin
            Session.LogMessage('0000C7R', StrSubstNo(SendEmailErr, GetLastErrorText()), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
            Error(SendEmailErr, GetLastErrorText());
        end;
    end;

    procedure ImportElectronicInvoice(var PurchaseHeader: Record "Purchase Header")
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        ServerFileName: Text;
        UUID: Text[50];
    begin
        ServerFileName := FileManagement.ServerTempFileName('xml');
        FileManagement.BLOBImportWithFilter(TempBlob, FileDialogTxt, '', FileFilterTxt, ExtensionFilterTxt);
        if not TempBlob.HasValue() then
            exit;
        FileManagement.BLOBExportToServerFile(TempBlob, ServerFileName);

        // Import UUID
        UUID := ImportUUIDFromXML(ServerFileName, 'http://www.sat.gob.mx/cfd/4');
        if UUID = '' then
            UUID := ImportUUIDFromXML(ServerFileName, 'http://www.sat.gob.mx/cfd/3');

        if UUID <> '' then begin
            PurchaseHeader.Validate("Fiscal Invoice Number PAC", UUID);
            PurchaseHeader.Modify(true);
        end else
            Error(ImportFailedErr);
    end;

    local procedure ImportUUIDFromXML(ServerFileName: Text; CFDINamespace: Text): Text[50]
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLDoc: DotNet XmlDocument;
        Node: DotNet XmlNode;
        NodeList: DotNet XmlNodeList;
        NamespaceManager: DotNet XmlNamespaceManager;
    begin
        XMLDOMManagement.LoadXMLDocumentFromFile(ServerFileName, XMLDoc);

        NamespaceManager := NamespaceManager.XmlNamespaceManager(XMLDoc.NameTable);
        NamespaceManager.AddNamespace('cfdi', CFDINamespace);
        NamespaceManager.AddNamespace('tfd', 'http://www.sat.gob.mx/TimbreFiscalDigital');

        // Read UUID
        NodeList := XMLDoc.DocumentElement.SelectNodes('//cfdi:Complemento/tfd:TimbreFiscalDigital', NamespaceManager);
        if NodeList.Count <> 0 then begin
            Node := NodeList.Item(0);
            exit(
                CopyStr(Node.Attributes.GetNamedItem('UUID').Value, 1, 50));
        end;
        exit('');
    end;

    local procedure InitXML(var XMLDoc: DotNet XmlDocument; var XMLCurrNode: DotNet XmlNode; IsForeignTrade: Boolean)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        RootXMLNode: DotNet XmlNode;
    begin
        // Create instance
        if IsNull(XMLDoc) then
            XMLDoc := XMLDoc.XmlDocument();

        RootXMLNode := XMLDoc.DocumentElement;
        XMLDOMManagement.AddRootElementWithPrefix(XMLDoc, 'Comprobante', 'cfdi', CFDINamespaceTxt, RootXMLNode);
        XMLDOMManagement.AddDeclaration(XMLDoc, '1.0', 'UTF-8', '');
        XMLDOMManagement.AddAttribute(RootXMLNode, 'xmlns:cfdi', CFDINamespaceTxt);
        XMLDOMManagement.AddAttribute(RootXMLNode, 'xmlns:xsi', XSINamespaceTxt);
        if IsForeignTrade then
            XMLDOMManagement.AddAttribute(RootXMLNode, 'xmlns:cce20', CFDIComercioExteriorNamespaceTxt);
        if IsForeignTrade then
            XMLDOMManagement.AddAttributeWithPrefix(
              RootXMLNode, 'schemaLocation', 'xsi', XSINamespaceTxt,
              StrSubstNo(
                SchemaLocation2xsdTxt,
                CFDINamespaceTxt, CFDIXSDLocationTxt, CFDIComercioExteriorNamespaceTxt, CFDIComercioExteriorSchemaLocationTxt))
        else
            XMLDOMManagement.AddAttributeWithPrefix(
              RootXMLNode, 'schemaLocation', 'xsi', XSINamespaceTxt,
              StrSubstNo(SchemaLocation1xsdTxt, CFDINamespaceTxt, CFDIXSDLocationTxt));

        DocNameSpace := 'http://www.sat.gob.mx/cfd/4';
        XMLCurrNode := XMLDoc.DocumentElement;
    end;

    local procedure InitXMLAdvancePayment(var XMLDoc: DotNet XmlDocument; var XMLCurrNode: DotNet XmlNode)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        RootXMLNode: DotNet XmlNode;
    begin
        // Create instance
        if IsNull(XMLDoc) then
            XMLDoc := XMLDoc.XmlDocument();

        // Root element

        RootXMLNode := XMLDoc.DocumentElement;
        XMLDOMManagement.AddRootElementWithPrefix(XMLDoc, 'Comprobante', 'cfdi', CFDINamespaceTxt, RootXMLNode);
        XMLDOMManagement.AddDeclaration(XMLDoc, '1.0', 'UTF-8', '');
        XMLDOMManagement.AddAttribute(RootXMLNode, 'xmlns:cfdi', CFDINamespaceTxt);
        XMLDOMManagement.AddAttribute(RootXMLNode, 'xmlns:xsi', XSINamespaceTxt);
        XMLDOMManagement.AddAttributeWithPrefix(
          RootXMLNode, 'schemaLocation', 'xsi', XSINamespaceTxt,
          StrSubstNo(SchemaLocation1xsdTxt, CFDINamespaceTxt, CFDIXSDLocationTxt));

        DocNameSpace := 'http://www.sat.gob.mx/cfd/4';
        XMLCurrNode := XMLDoc.DocumentElement;
    end;

    local procedure InitXMLCartaPorte(var XMLDoc: DotNet XmlDocument; var XMLCurrNode: DotNet XmlNode; IsForeignTrade: Boolean)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        RootXMLNode: DotNet XmlNode;
    begin
        // Create instance
        if IsNull(XMLDoc) then
            XMLDoc := XMLDoc.XmlDocument();

        RootXMLNode := XMLDoc.DocumentElement;
        XMLDOMManagement.AddRootElementWithPrefix(XMLDoc, 'Comprobante', 'cfdi', CFDINamespaceTxt, RootXMLNode);
        XMLDOMManagement.AddDeclaration(XMLDoc, '1.0', 'UTF-8', '');
        XMLDOMManagement.AddAttribute(RootXMLNode, 'xmlns:cfdi', CFDINamespaceTxt);
        XMLDOMManagement.AddAttribute(RootXMLNode, 'xmlns:cartaporte31', CartaPorteNamespaceTxt);
        XMLDOMManagement.AddAttribute(RootXMLNode, 'xmlns:xsi', XSINamespaceTxt);
        if IsForeignTrade then
            XMLDOMManagement.AddAttribute(RootXMLNode, 'xmlns:cce20', CFDIComercioExteriorNamespaceTxt);
        if IsForeignTrade then
            XMLDOMManagement.AddAttributeWithPrefix(
              RootXMLNode, 'schemaLocation', 'xsi', XSINamespaceTxt,
              StrSubstNo(
                SchemaLocation3xsdTxt,
                CFDINamespaceTxt, CFDIXSDLocationTxt,
                CFDIComercioExteriorNamespaceTxt, CFDIComercioExteriorSchemaLocationTxt,
                CartaPorteNamespaceTxt, CartaPorteSchemaLocationTxt))
        else
            XMLDOMManagement.AddAttributeWithPrefix(
              RootXMLNode, 'schemaLocation', 'xsi', XSINamespaceTxt,
              StrSubstNo(SchemaLocation2xsdTxt, CFDINamespaceTxt, CFDIXSDLocationTxt, CartaPorteNamespaceTxt, CartaPorteSchemaLocationTxt));

        XMLCurrNode := XMLDoc.DocumentElement;
    end;

    local procedure AddElementCFDI(var XMLNode: DotNet XmlNode; NodeName: Text; NodeText: Text; NameSpace: Text; var CreatedXMLNode: DotNet XmlNode): Boolean
    var
        NewChildNode: DotNet XmlNode;
    begin
        NodeName := 'cfdi:' + NodeName;
        NewChildNode := XMLNode.OwnerDocument.CreateNode('element', NodeName, NameSpace);
        if IsNull(NewChildNode) then
            exit(false);

        if NodeText <> '' then
            NewChildNode.Value := RemoveInvalidChars(NodeText);
        XMLNode.AppendChild(NewChildNode);
        CreatedXMLNode := NewChildNode;
        exit(true);
    end;

    local procedure AddElement(var XMLNode: DotNet XmlNode; NodeName: Text; NodeText: Text; NameSpace: Text; var CreatedXMLNode: DotNet XmlNode): Boolean
    var
        NewChildNode: DotNet XmlNode;
    begin
        NewChildNode := XMLNode.OwnerDocument.CreateNode('element', NodeName, NameSpace);
        if IsNull(NewChildNode) then
            exit(false);

        if NodeText <> '' then
            NewChildNode.Value := RemoveInvalidChars(NodeText);
        XMLNode.AppendChild(NewChildNode);
        CreatedXMLNode := NewChildNode;
        exit(true);
    end;

    local procedure AddAttribute(var XMLDomDocParam: DotNet XmlDocument; var XMLDomNode: DotNet XmlNode; AttribName: Text; AttribValue: Text): Boolean
    begin
        AddAttributeSimple(
          XMLDomDocParam, XMLDomNode, AttribName, RemoveInvalidChars(AttribValue));
    end;

    local procedure AddAttributeSimple(var XMLDomDocParam: DotNet XmlDocument; var XMLDomNode: DotNet XmlNode; AttribName: Text; AttribValue: Text): Boolean
    var
        XMLDomAttribute: DotNet XmlAttribute;
    begin
        XMLDomAttribute := XMLDomDocParam.CreateAttribute(AttribName);
        if IsNull(XMLDomAttribute) then
            exit(false);

        if AttribValue <> '' then begin
            XMLDomAttribute.Value := AttribValue;
            XMLDomNode.Attributes.SetNamedItem(XMLDomAttribute);
        end;
        Clear(XMLDomAttribute);
        exit(true);
    end;

    local procedure EncodeString(InputText: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
        DotNetRegex: DotNet Regex;
    begin
        InputText := DelChr(InputText, '<>');
        InputText := DotNetRegex.Replace(InputText, '\s+', ' ');
        exit(TypeHelper.HtmlEncode(InputText));
    end;

    local procedure FormatAmount(InAmount: Decimal): Text
    begin
        exit(Format(Abs(InAmount), 0, '<Precision,' + Format(CurrencyDecimalPlaces) + ':' +
            Format(CurrencyDecimalPlaces) + '><Standard Format,1>'));
    end;

    local procedure FormatDecimal(InAmount: Decimal; DecimalPlaces: Integer): Text
    begin
        exit(
          FormatDecimalRange(InAmount, DecimalPlaces, DecimalPlaces));
    end;

    local procedure FormatDecimalRange(InAmount: Decimal; DecimalPlacesFrom: Integer; DecimalPlacesTo: Integer): Text
    begin
        exit(
          Format(Abs(InAmount), 0, '<Precision,' + Format(DecimalPlacesFrom) + ':' + Format(DecimalPlacesTo) + '><Standard Format,1>'));
    end;

    local procedure FormatPeriod(Period: Option "Diario","Semanal","Quincenal","Mensual"): Text
    begin
        case Period of
            Period::Diario:
                exit('01');
            Period::Semanal:
                exit('02');
            Period::Quincenal:
                exit('03');
            Period::Mensual:
                exit('04');
        end;
    end;

    local procedure FormatMonth(Month: Text): Text
    begin
        if StrLen(Month) = 2 then
            exit(Month);
        exit('0' + Month);
    end;

    local procedure FormatEquivalenciaDR(ExchangeRate: Decimal; DocsCount: Integer): Text
    begin
        if ExchangeRate = 1 then
            if DocsCount = 1 then
                exit('1')
            else
                exit('1.0000000000'); // 10 decimal places
        exit(FormatDecimal(ExchangeRate, 10));
    end;

    local procedure FilterDocumentLines(var TempDocumentLine: Record "Document Line" temporary; DocumentNo: Code[20])
    begin
        TempDocumentLine.Reset();
        TempDocumentLine.SetRange("Document No.", DocumentNo);
        TempDocumentLine.SetFilter(Type, '<>%1', TempDocumentLine.Type::" ");
        TempDocumentLine.SetRange("Retention Attached to Line No.", 0);
    end;

    local procedure FilterSalesInvoiceLines(var SalesInvoiceLine: Record "Sales Invoice Line"; DocumentNo: Code[20])
    begin
        SalesInvoiceLine.Reset();
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetFilter(Type, '<>%1', SalesInvoiceLine.Type::" ");
        SalesInvoiceLine.SetFilter(Quantity, '<>0');
    end;

    local procedure FilterSalesCrMemoLines(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; DocumentNo: Code[20])
    begin
        SalesCrMemoLine.Reset();
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
        SalesCrMemoLine.SetFilter(Quantity, '<>0');
    end;

    local procedure FilterServiceInvoiceLines(var ServiceInvoiceLine: Record "Service Invoice Line"; DocumentNo: Code[20])
    begin
        ServiceInvoiceLine.Reset();
        ServiceInvoiceLine.SetRange("Document No.", DocumentNo);
        ServiceInvoiceLine.SetFilter(Type, '<>%1', ServiceInvoiceLine.Type::" ");
        ServiceInvoiceLine.SetFilter(Quantity, '<>0');
    end;

    local procedure FilterServiceCrMemoLines(var ServiceCrMemoLine: Record "Service Cr.Memo Line"; DocumentNo: Code[20])
    begin
        ServiceCrMemoLine.Reset();
        ServiceCrMemoLine.SetRange("Document No.", DocumentNo);
        ServiceCrMemoLine.SetFilter(Type, '<>%1', ServiceCrMemoLine.Type::" ");
        ServiceCrMemoLine.SetFilter(Quantity, '<>0');
    end;

    local procedure RemoveInvalidChars(PassedStr: Text): Text
    begin
        PassedStr := DelChr(PassedStr, '=', '|');
        PassedStr := RemoveExtraWhiteSpaces(PassedStr);
        exit(PassedStr);
    end;

    local procedure GetReportNo(var ReportSelection: Record "Report Selections"): Integer
    begin
        ReportSelection.SetFilter("Report ID", '<>0');
        ReportSelection.SetRange("Use for Email Attachment", true);
        if ReportSelection.FindFirst() then
            exit(ReportSelection."Report ID");
        exit(0);
    end;

    local procedure GetDateTime24HoursAgo(): DateTime
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(TypeHelper.GetCurrentDateTimeInUserTimeZone() - 24 * 3600 * 1000);
    end;

    local procedure ConvertDateTimeToTimeZone(InputDateTime: DateTime; TimeZone: Text): DateTime
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        InputDateTime := TypeHelper.GetInputDateTimeInUserTimeZone(InputDateTime);
        exit(TypeHelper.ConvertDateTimeFromUTCToTimeZone(InputDateTime, TimeZone));
    end;

    local procedure ConvertCurrentDateTimeToTimeZone(TimeZone: Text): DateTime
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(
            TypeHelper.ConvertDateTimeFromUTCToTimeZone(
                TypeHelper.GetCurrentDateTimeInUserTimeZone(), TimeZone));
    end;

    local procedure ConvertStingToDateTime(InputDateTime: Text) OutDateTime: DateTime
    var
        TypeHelper: Codeunit "Type Helper";
        VarDateTime: Variant;
    begin
        // 2022-10-25T10:09:32
        if InputDateTime = '' then
            exit(0DT);

        VarDateTime := OutDateTime;
        if TypeHelper.Evaluate(VarDateTime, InputDateTime, '', '') then
            exit(VarDateTime);
        exit(0DT);
    end;

    local procedure ConvertCurrency(CurrencyCode: Code[10]): Code[10]
    begin
        if CurrencyCode in ['', 'XXX', 'MXN'] then
            exit(GLSetup."LCY Code");
        exit(CurrencyCode);
    end;

    local procedure FormatDateTime(DateTime: DateTime): Text[50]
    begin
        exit(Format(DateTime, 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>'));
    end;

    local procedure FormatAsDateTime(DocDate: Date; DocTime: Time; TimeZone: Text): Text[50]
    begin
        exit(
          FormatDateTime(
            ConvertDateTimeToTimeZone(CreateDateTime(DocDate, DocTime), TimeZone)));
    end;

    local procedure GetGLSetup()
    begin
        GetGLSetupOnce();
        GLSetup.TestField("SAT Certificate");
    end;

    local procedure GetGLSetupOnce()
    begin
        if GLSetupRead then
            exit;

        GLSetup.Get();
        GLSetupRead := true;
    end;

    local procedure GetCompanyInfo()
    begin
        CompanyInfo.Get();
    end;

    local procedure GetCheckCompanyInfo()
    begin
        GetCompanyInfo();
        CompanyInfo.TestField(Name);
        CompanyInfo.TestField("RFC Number");
        CompanyInfo.TestField(Address);
        CompanyInfo.TestField(City);
        CompanyInfo.TestField("Country/Region Code");
        CompanyInfo.TestField("Post Code");
        CompanyInfo.TestField("E-Mail");
        CompanyInfo.TestField("Tax Scheme");
    end;

    local procedure GetCustomer(var Customer: Record Customer; CustomerNo: Code[20]; CheckSend: Boolean)
    begin
        if not Customer.Get(CustomerNo) then
            exit;
        Customer.TestField("RFC No.");
        Customer.TestField("Country/Region Code");
        if CheckSend then
            Customer.TestField("E-Mail");
    end;

    local procedure GetAdvanceCFDIRelation(CFDIRelation: Code[10]): Code[10]
    begin
        if CFDIRelation = '' then
            exit('07'); // Hardcoded for Advance Settle
        // 01 = Credit memo, 06 = Invoice
        exit(CFDIRelation);
    end;

    local procedure IsNonTaxableVATLine(DocumentLine: Record "Document Line"): Boolean
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if not VATPostingSetup.Get(DocumentLine."VAT Bus. Posting Group", DocumentLine."VAT Prod. Posting Group") then
            exit(false);

        exit(VATPostingSetup."CFDI Non-Taxable");
    end;

    local procedure IsVATExemptLine(DocumentLine: Record "Document Line"): Boolean
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if not VATPostingSetup.Get(DocumentLine."VAT Bus. Posting Group", DocumentLine."VAT Prod. Posting Group") then
            exit(false);

        exit(VATPostingSetup."CFDI VAT Exemption");
    end;

    local procedure RemoveExtraWhiteSpaces(StrParam: Text) StrReturn: Text
    var
        Cntr1: Integer;
        Cntr2: Integer;
        WhiteSpaceFound: Boolean;
    begin
        StrParam := DelChr(StrParam, '<>', ' ');
        WhiteSpaceFound := false;
        Cntr2 := 1;
        for Cntr1 := 1 to StrLen(StrParam) do
            if StrParam[Cntr1] <> ' ' then begin
                WhiteSpaceFound := false;
                StrReturn[Cntr2] := StrParam[Cntr1];
                Cntr2 += 1;
            end else
                if not WhiteSpaceFound then begin
                    WhiteSpaceFound := true;
                    StrReturn[Cntr2] := StrParam[Cntr1];
                    Cntr2 += 1;
                end;
    end;

    [NonDebuggable]
    local procedure InvokeMethod(var XMLDoc: DotNet XmlDocument; MethodType: Option "Request Stamp",Cancel,CancelRequest): Text
    var
        PACWebService: Record "PAC Web Service";
        PACWebServiceDetail: Record "PAC Web Service Detail";
        IsolatedCertificate: Record "Isolated Certificate";
        MXElectronicInvoicingSetup: Record "MX Electronic Invoicing Setup";
        TempBlob: Codeunit "Temp Blob";
        CertificateManagement: Codeunit "Certificate Management";
        Response: Text;
        DocOutStream: OutStream;
        DocInStream: InStream;
        DocFileName: text;
    begin
        GetGLSetup();
        if GLSetup."Sim. Request Stamp" then
            exit;
        if not IsPACEnvironmentEnabled() then
            Error(Text014);

        if MXElectronicInvoicingSetup.Get() then
            if MXElectronicInvoicingSetup."Download XML with Requests" then begin
                TempBlob.CreateOutStream(DocOutStream);
                XMLDoc.Save(DocOutStream);
                TempBlob.CreateInStream(DocInStream);

                DocFileName := 'ElectronicInvoice.xml';
                DownloadFromStream(DocInStream, '', '', '', DocFileName);
            end;

        // Depending on the chosen service provider, this section needs to be modified.
        // The parameters for the invoked method need to be added in the correct order.
        case MethodType of
            MethodTypeRef::"Request Stamp":
                begin
                    if not PACWebServiceDetail.Get(GLSetup."PAC Code", GLSetup."PAC Environment", PACWebServiceDetail.Type::"Request Stamp") then begin
                        PACWebServiceDetail.Type := PACWebServiceDetail.Type::"Request Stamp";
                        Error(Text009, PACWebServiceDetail.Type, GLSetup.FieldCaption("PAC Code"),
                          GLSetup.FieldCaption("PAC Environment"), GLSetup.TableCaption());
                    end;

                    EInvoiceCommunication.AddParameters(XMLDoc.InnerXml);
                    EInvoiceCommunication.AddParameters(false);
                end;
            MethodTypeRef::Cancel:
                begin
                    if not PACWebServiceDetail.Get(GLSetup."PAC Code", GLSetup."PAC Environment", PACWebServiceDetail.Type::Cancel) then begin
                        PACWebServiceDetail.Type := PACWebServiceDetail.Type::Cancel;
                        Error(Text009, PACWebServiceDetail.Type, GLSetup.FieldCaption("PAC Code"),
                          GLSetup.FieldCaption("PAC Environment"), GLSetup.TableCaption);
                    end;
                    EInvoiceCommunication.AddParameters(XMLDoc.InnerXml);
                end;
            MethodTypeRef::CancelRequest:
                begin
                    if not PACWebServiceDetail.Get(GLSetup."PAC Code", GLSetup."PAC Environment", PACWebServiceDetail.Type::CancelRequest) then begin
                        PACWebServiceDetail.Type := PACWebServiceDetail.Type::CancelRequest;
                        Error(Text009, PACWebServiceDetail.Type, GLSetup.FieldCaption("PAC Code"),
                          GLSetup.FieldCaption("PAC Environment"), GLSetup.TableCaption());
                    end;
                    EInvoiceCommunication.AddParameters(XMLDoc.InnerXml);
                end;
        end;

        PACWebService.Get(GLSetup."PAC Code");
        if PACWebService.Certificate = '' then
            Error(Text012, PACWebService.FieldCaption(Certificate), PACWebService.TableCaption(), GLSetup.TableCaption());

        IsolatedCertificate.Get(PACWebService.Certificate);

        if PACWebServiceDetail.Address = '' then
            Session.LogMessage('0000C7S', StrSubstNo(NullParameterErr, 'address'), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
        if PACWebServiceDetail."Method Name" = '' then
            Session.LogMessage('0000C7S', StrSubstNo(NullParameterErr, 'method name'), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
        if CertificateManagement.GetCertAsBase64String(IsolatedCertificate) = '' then
            Session.LogMessage('0000C7S', StrSubstNo(NullParameterErr, 'certificate isentifier'), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);

        Session.LogMessage('0000C7V', StrSubstNo(InvokeMethodMsg, MethodType), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);

        Response := EInvoiceCommunication.InvokeMethodWithCertificate(PACWebServiceDetail.Address,
            PACWebServiceDetail."Method Name", CertificateManagement.GetCertAsBase64String(IsolatedCertificate), CertificateManagement.GetPasswordAsSecret(IsolatedCertificate));
        Session.LogMessage('0000C7W', StrSubstNo(InvokeMethodSuccessMsg, MethodType), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
        if MethodType in [MethodType::Cancel, MethodType::CancelRequest] then
            Response := DelChr(Response, '=', SpecialCharsTxt);
        exit(Response)
    end;

    local procedure CreateQRCodeInput(IssuerRFC: Text; CustomerRFC: Text; Amount: Decimal; UUID: Text) QRCodeInput: Text
    begin
        QRCodeInput :=
            'https://verificacfdi.facturaelectronica.sat.gob.mx/default.aspx' +
            '?re=' +
            CopyStr(IssuerRFC, 1, 13) +
            '&rr=' +
            CopyStr(CustomerRFC, 1, 13) +
            '&tt=' +
            ConvertStr(Format(Amount, 0, '<Integer,10><Filler Character,0><Decimals,7>'), ',', '.') +
            '&id=' +
            CopyStr(Format(UUID), 1, 36);
    end;

    local procedure GetDateTimeOfFirstReqSalesInv(var SalesInvoiceHeader: Record "Sales Invoice Header"): Text[50]
    begin
        if SalesInvoiceHeader."Date/Time First Req. Sent" <> '' then
            exit(SalesInvoiceHeader."Date/Time First Req. Sent");

        SalesInvoiceHeader."Date/Time First Req. Sent" :=
          FormatAsDateTime(SalesInvoiceHeader."Document Date", Time, GetTimeZoneFromDocument(SalesInvoiceHeader));
        exit(SalesInvoiceHeader."Date/Time First Req. Sent");
    end;

    local procedure GetDateTimeOfFirstReqSalesCr(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Text[50]
    begin
        if SalesCrMemoHeader."Date/Time First Req. Sent" <> '' then
            exit(SalesCrMemoHeader."Date/Time First Req. Sent");

        SalesCrMemoHeader."Date/Time First Req. Sent" :=
          FormatAsDateTime(SalesCrMemoHeader."Document Date", Time, GetTimeZoneFromDocument(SalesCrMemoHeader));
        exit(SalesCrMemoHeader."Date/Time First Req. Sent");
    end;

    local procedure GetDateTimeOfFirstReqServInv(var ServiceInvoiceHeader: Record "Service Invoice Header"): Text[50]
    begin
        if ServiceInvoiceHeader."Date/Time First Req. Sent" <> '' then
            exit(ServiceInvoiceHeader."Date/Time First Req. Sent");

        ServiceInvoiceHeader."Date/Time First Req. Sent" :=
          FormatAsDateTime(ServiceInvoiceHeader."Document Date", Time, GetTimeZoneFromDocument(ServiceInvoiceHeader));
        exit(ServiceInvoiceHeader."Date/Time First Req. Sent");
    end;

    local procedure GetDateTimeOfFirstReqServCr(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"): Text[50]
    begin
        if ServiceCrMemoHeader."Date/Time First Req. Sent" <> '' then
            exit(ServiceCrMemoHeader."Date/Time First Req. Sent");

        ServiceCrMemoHeader."Date/Time First Req. Sent" :=
          FormatAsDateTime(ServiceCrMemoHeader."Document Date", Time, GetTimeZoneFromDocument(ServiceCrMemoHeader));
        exit(ServiceCrMemoHeader."Date/Time First Req. Sent");
    end;

    local procedure GetDateTimeOfFirstReqPayment(var CustLedgerEntry: Record "Cust. Ledger Entry"): Text[50]
    begin
        if CustLedgerEntry."Date/Time First Req. Sent" <> '' then
            exit(CustLedgerEntry."Date/Time First Req. Sent");

        CustLedgerEntry."Date/Time First Req. Sent" :=
          FormatAsDateTime(CustLedgerEntry."Document Date", Time, GetTimeZoneFromCustomer(CustLedgerEntry."Customer No."));
        exit(CustLedgerEntry."Date/Time First Req. Sent");
    end;

    local procedure GetTimeZoneFromDocument(DocumentHeaderVariant: Variant): Text
    var
        DocumentHeader: Record "Document Header";
        PostCode: Record "Post Code";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        Location: Record Location;
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
    begin
        DataTypeManagement.GetRecordRef(DocumentHeaderVariant, RecRef);
        if RecRef.Number = DATABASE::"Transfer Shipment Header" then begin
            RecRef.SetTable(TransferShipmentHeader);
            if PostCode.Get(TransferShipmentHeader."Transfer-from Post Code", TransferShipmentHeader."Transfer-from City") then
                exit(PostCode."Time Zone");
            exit(GetTimeZoneFromCompany());
        end;
        if RecRef.Number = DATABASE::"Cust. Ledger Entry" then begin
            RecRef.SetTable(CustomerLedgerEntry);
            exit(GetTimeZoneFromCustomer(CustomerLedgerEntry."Customer No."));
        end;

        DocumentHeader.TransferFields(DocumentHeaderVariant);
        Location.SetLoadFields("Post Code", City);
        if Location.Get(DocumentHeader."Location Code") then
            if PostCode.Get(Location."Post Code", Location.City) then
                exit(PostCode."Time Zone");

        exit(GetTimeZoneFromCompany());
    end;

    local procedure GetSATCertificateCodeForDocument(DocumentRecRef: RecordRef): Code[20]
    var
        Location: Record Location;
        DummyDocumentHeader: Record "Document Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        LocationFldRef: FieldRef;
        LocationCode: Code[10];
    begin
        GetGLSetupOnce();
        if not GLSetup."Multiple SAT Certificates" then
            exit(GLSetup."SAT Certificate");

        Location.SetLoadFields("SAT Certificate");
        if DocumentRecRef.Number = Database::"Transfer Shipment Header" then begin
            DocumentRecRef.SetTable(TransferShipmentHeader);
            LocationCode := TransferShipmentHeader."Transfer-from Code";
        end else begin
            LocationFldRef := DocumentRecRef.Field(DummyDocumentHeader.FieldNo("Location Code"));
            LocationCode := LocationFldRef.Value;
        end;

        if Location.Get(LocationCode) then
            if Location."SAT Certificate" <> '' then
                exit(Location."SAT Certificate");

        exit(GLSetup."SAT Certificate");
    end;

    local procedure GetSATCertificateCodeForDocument(var TempDocumentHeader: Record "Document Header" temporary): Code[20]
    var
        Location: Record Location;
        LocationCode: Code[10];
    begin
        GetGLSetupOnce();
        if not GLSetup."Multiple SAT Certificates" then
            exit(GLSetup."SAT Certificate");

        Location.SetLoadFields("SAT Certificate");
        if TempDocumentHeader."Document Table ID" = Database::"Transfer Shipment Header" then
            LocationCode := TempDocumentHeader."Transit-from Location"
        else
            LocationCode := TempDocumentHeader."Location Code";

        if Location.Get(LocationCode) then
            if Location."SAT Certificate" <> '' then
                exit(Location."SAT Certificate");

        exit(GLSetup."SAT Certificate");
    end;

    local procedure GetSATCertificateSourceForDocument(DocumentRecRef: RecordRef) SourceRecRef: RecordRef
    var
        Location: Record Location;
        DummyDocumentHeader: Record "Document Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        LocationFldRef: FieldRef;
        LocationCode: Code[10];
    begin
        GetGLSetupOnce();
        if not GLSetup."Multiple SAT Certificates" then begin
            SourceRecRef.GetTable(GLSetup);
            exit;
        end;

        Location.SetLoadFields("SAT Certificate");
        if DocumentRecRef.Number = Database::"Transfer Shipment Header" then begin
            DocumentRecRef.SetTable(TransferShipmentHeader);
            LocationCode := TransferShipmentHeader."Transfer-from Code";
        end else begin
            LocationFldRef := DocumentRecRef.Field(DummyDocumentHeader.FieldNo("Location Code"));
            LocationCode := LocationFldRef.Value;
        end;

        if Location.Get(LocationCode) then
            if Location."SAT Certificate" <> '' then begin
                SourceRecRef.GetTable(Location);
                exit;
            end;

        SourceRecRef.GetTable(GLSetup);
    end;

    procedure GetSATCertificateInfoForDocument(DocumentRecRef: RecordRef; var SATCertificateCode: Text; var SATCertificateName: Text; var SATCertificateSource: Text)
    var
        IsolatedCertificate: Record "Isolated Certificate";
        Location: Record Location;
        SourceRecRef: RecordRef;
    begin
        SATCertificateCode := '';
        SATCertificateName := '';
        SATCertificateSource := '';

        if not IsolatedCertificate.ReadPermission() then
            exit;

        SATCertificateCode := GetSATCertificateCodeForDocument(DocumentRecRef);
        if not IsolatedCertificate.Get(SATCertificateCode) then
            exit;

        SATCertificateName := IsolatedCertificate.Name;

        SourceRecRef := GetSATCertificateSourceForDocument(DocumentRecRef);
        case SourceRecRef.Number of
            Database::"General Ledger Setup":
                SATCertificateSource := SourceRecRef.Caption;
            Database::"Location":
                begin
                    SourceRecRef.SetTable(Location);
                    SATCertificateSource := StrSubstNo('%1 %2', Location.TableCaption, Location.Code);
                end;
        end;
    end;

    procedure DrillDownSATCertificate(SATCertificateCode: Text)
    var
        IsolatedCertificate: Record "Isolated Certificate";
        CertificateCard: Page "Certificate";
    begin
        if not IsolatedCertificate.Get(SATCertificateCode) then
            exit;

        IsolatedCertificate.SetRecFilter();
        CertificateCard.SetRecord(IsolatedCertificate);
        CertificateCard.SetTableView(IsolatedCertificate);
        CertificateCard.Editable(false);
        CertificateCard.RunModal();
    end;

    local procedure GetTimeZoneFromCustomer(CustomerNo: Code[20]): Text
    var
        Customer: Record Customer;
        PostCode: Record "Post Code";
    begin
        Customer.Get(CustomerNo);
        if PostCode.Get(Customer."Post Code", Customer.City) then
            exit(PostCode."Time Zone");
        exit('');
    end;

    local procedure GetTimeZoneFromCompany(): Text
    var
        PostCode: Record "Post Code";
    begin
        GetCompanyInfo();
        if PostCode.Get(CompanyInfo."Post Code", CompanyInfo.City) then
            exit(PostCode."Time Zone");
        exit('');
    end;

    local procedure CreateQRCode(QRCodeInput: Text; var TempBLOB: Codeunit "Temp Blob")
    var
        QRCodeProvider: DotNet QRCodeProvider;
        BlobOutStr: OutStream;
    begin
        Clear(TempBLOB);

        QRCodeProvider := QRCodeProvider.QRCodeProvider();
        TempBLOB.CreateOutStream(BlobOutStr);
        QRCodeProvider.GetBarcodeStream(QRCodeInput, BlobOutStr);
    end;

    procedure CreateTempDocument(DocumentHeaderVariant: Variant; var TempDocumentHeader: Record "Document Header" temporary; var TempDocumentLine: Record "Document Line" temporary; var TempDocumentLineRetention: Record "Document Line" temporary; var TempVATAmountLine: Record "VAT Amount Line" temporary; var SubTotal: Decimal; var TotalTax: Decimal; var TotalRetention: Decimal; var TotalDiscount: Decimal; AdvanceSettle: Boolean)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
    begin
        DataTypeManagement.GetRecordRef(DocumentHeaderVariant, RecRef);
        case RecRef.Number of
            DATABASE::"Sales Invoice Header":
                begin
                    RecRef.SetTable(SalesInvoiceHeader);
                    TempDocumentHeader.TransferFields(SalesInvoiceHeader);
                    if SalesInvoiceHeader."Ship-to Address" <> '' then
                        TempDocumentHeader."Bill-to/Pay-To Address" := SalesInvoiceHeader."Ship-to Address";
                    TempDocumentHeader."Document Table ID" := RecRef.Number;
                    UpdateAbstractDocument(TempDocumentHeader);
                    SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
                    TempDocumentHeader.Amount := SalesInvoiceHeader.Amount;
                    TempDocumentHeader."Amount Including VAT" := SalesInvoiceHeader."Amount Including VAT";
                    TempDocumentHeader.Insert();

                    FilterSalesInvoiceLines(SalesInvoiceLine, SalesInvoiceHeader."No.");
                    if AdvanceSettle then
                        SalesInvoiceLine.SetFilter("Prepayment Line", '=0');

                    if SalesInvoiceLine.FindSet() then begin
                        repeat
                            TempDocumentLine.TransferFields(SalesInvoiceLine);
                            CalcDocumentTotalAmounts(TempDocumentLine, SubTotal, TotalTax, TotalRetention);
                            CalcDocumentLineAmounts(
                              TempDocumentLine, SalesInvoiceLine."Inv. Discount Amount",
                              SalesInvoiceHeader."Currency Code", SalesInvoiceHeader."Prices Including VAT", SalesInvoiceLine."Line Discount %");
                            UpdateDocumentLine(TempDocumentLine);
                            TempDocumentLine.Insert();
                            InsertTempVATAmountLine(TempVATAmountLine, TempDocumentLine);
                            InsertTempDocRetentionLine(TempDocumentLineRetention, TempDocumentLine);
                            TotalDiscount += TempDocumentLine."Line Discount Amount";
                        until SalesInvoiceLine.Next() = 0;
                        SubTotal += TotalDiscount;
                    end;
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    RecRef.SetTable(SalesCrMemoHeader);
                    TempDocumentHeader.TransferFields(SalesCrMemoHeader);
                    if SalesCrMemoHeader."Ship-to Address" <> '' then
                        TempDocumentHeader."Bill-to/Pay-To Address" := SalesInvoiceHeader."Ship-to Address";
                    TempDocumentHeader."Document Table ID" := RecRef.Number;
                    UpdateAbstractDocument(TempDocumentHeader);
                    SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT");
                    TempDocumentHeader.Amount := SalesCrMemoHeader.Amount;
                    TempDocumentHeader."Amount Including VAT" := SalesCrMemoHeader."Amount Including VAT";
                    TempDocumentHeader.Insert();

                    FilterSalesCrMemoLines(SalesCrMemoLine, SalesCrMemoHeader."No.");
                    if SalesCrMemoLine.FindSet() then begin
                        repeat
                            TempDocumentLine.TransferFields(SalesCrMemoLine);
                            CalcDocumentTotalAmounts(TempDocumentLine, SubTotal, TotalTax, TotalRetention);
                            CalcDocumentLineAmounts(
                              TempDocumentLine, SalesCrMemoLine."Inv. Discount Amount",
                              SalesCrMemoHeader."Currency Code", SalesCrMemoHeader."Prices Including VAT", SalesCrMemoLine."Line Discount %");
                            UpdateDocumentLine(TempDocumentLine);
                            TempDocumentLine.Insert();
                            InsertTempVATAmountLine(TempVATAmountLine, TempDocumentLine);
                            InsertTempDocRetentionLine(TempDocumentLineRetention, TempDocumentLine);
                            TotalDiscount += TempDocumentLine."Line Discount Amount";
                        until SalesCrMemoLine.Next() = 0;
                        SubTotal += TotalDiscount;
                    end;
                end;
            DATABASE::"Service Invoice Header":
                begin
                    RecRef.SetTable(ServiceInvoiceHeader);
                    TempDocumentHeader.TransferFields(ServiceInvoiceHeader);
                    TempDocumentHeader."Document Table ID" := RecRef.Number;
                    UpdateAbstractDocument(TempDocumentHeader);
                    ServiceInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
                    TempDocumentHeader.Amount := ServiceInvoiceHeader.Amount;
                    TempDocumentHeader."Amount Including VAT" := ServiceInvoiceHeader."Amount Including VAT";
                    TempDocumentHeader.Insert();

                    FilterServiceInvoiceLines(ServiceInvoiceLine, ServiceInvoiceHeader."No.");
                    if ServiceInvoiceLine.FindSet() then begin
                        repeat
                            TempDocumentLine.TransferFields(ServiceInvoiceLine);
                            TempDocumentLine.Type := MapServiceTypeToTempDocType(ServiceInvoiceLine.Type);
                            VATPostingSetup.Get(TempDocumentLine."VAT Bus. Posting Group", TempDocumentLine."VAT Prod. Posting Group");
                            TempDocumentLine."VAT %" := VATPostingSetup."VAT %";
                            CalcDocumentTotalAmounts(TempDocumentLine, SubTotal, TotalTax, TotalRetention);
                            CalcDocumentLineAmounts(
                              TempDocumentLine, ServiceInvoiceLine."Inv. Discount Amount",
                              ServiceInvoiceHeader."Currency Code", ServiceInvoiceHeader."Prices Including VAT", ServiceInvoiceLine."Line Discount %");
                            UpdateDocumentLine(TempDocumentLine);
                            TempDocumentLine.Insert();
                            InsertTempVATAmountLine(TempVATAmountLine, TempDocumentLine);
                            InsertTempDocRetentionLine(TempDocumentLineRetention, TempDocumentLine);
                            TotalDiscount += TempDocumentLine."Line Discount Amount";
                        until ServiceInvoiceLine.Next() = 0;
                        SubTotal += TotalDiscount;
                    end;
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    RecRef.SetTable(ServiceCrMemoHeader);
                    TempDocumentHeader.TransferFields(ServiceCrMemoHeader);
                    TempDocumentHeader."Document Table ID" := RecRef.Number;
                    UpdateAbstractDocument(TempDocumentHeader);
                    ServiceCrMemoHeader.CalcFields(Amount, "Amount Including VAT");
                    TempDocumentHeader.Amount := ServiceCrMemoHeader.Amount;
                    TempDocumentHeader."Amount Including VAT" := ServiceCrMemoHeader."Amount Including VAT";
                    TempDocumentHeader.Insert();

                    FilterServiceCrMemoLines(ServiceCrMemoLine, ServiceCrMemoHeader."No.");
                    if ServiceCrMemoLine.FindSet() then begin
                        repeat
                            TempDocumentLine.TransferFields(ServiceCrMemoLine);
                            TempDocumentLine.Type := MapServiceTypeToTempDocType(ServiceCrMemoLine.Type);
                            VATPostingSetup.Get(TempDocumentLine."VAT Bus. Posting Group", TempDocumentLine."VAT Prod. Posting Group");
                            TempDocumentLine."VAT %" := VATPostingSetup."VAT %";
                            CalcDocumentTotalAmounts(TempDocumentLine, SubTotal, TotalTax, TotalRetention);
                            CalcDocumentLineAmounts(
                              TempDocumentLine, ServiceCrMemoLine."Inv. Discount Amount",
                              ServiceCrMemoHeader."Currency Code", ServiceCrMemoHeader."Prices Including VAT", ServiceCrMemoLine."Line Discount %");
                            UpdateDocumentLine(TempDocumentLine);
                            TempDocumentLine.Insert();
                            InsertTempVATAmountLine(TempVATAmountLine, TempDocumentLine);
                            InsertTempDocRetentionLine(TempDocumentLineRetention, TempDocumentLine);
                            TotalDiscount += TempDocumentLine."Line Discount Amount";
                        until ServiceCrMemoLine.Next() = 0;
                        SubTotal += TotalDiscount;
                    end;
                end;
        end;
    end;

    procedure CreateTempDocumentTransfer(DocumentHeaderVariant: Variant; var TempDocumentHeader: Record "Document Header" temporary; var TempDocumentLine: Record "Document Line" temporary)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
        Location: Record Location;
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
    begin
        DataTypeManagement.GetRecordRef(DocumentHeaderVariant, RecRef);
        case RecRef.Number of
            DATABASE::"Sales Shipment Header":
                begin
                    RecRef.SetTable(SalesShipmentHeader);
                    TempDocumentHeader.TransferFields(SalesShipmentHeader);
                    TempDocumentHeader."Document Table ID" := RecRef.Number;
                    TempDocumentHeader."CFDI Purpose" := 'S01';
                    TempDocumentHeader."Transit-from Location" := SalesShipmentHeader."Location Code";
                    UpdateAbstractDocument(TempDocumentHeader);
                    TempDocumentHeader.Insert();
                    SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
                    SalesShipmentLine.SetFilter(Type, '<>%1', SalesShipmentLine.Type::" ");
                    if SalesShipmentLine.FindSet() then
                        repeat
                            TempDocumentLine.TransferFields(SalesShipmentLine);
                            TempDocumentLine."Gross Weight" := SalesShipmentLine."Gross Weight" * SalesShipmentLine.Quantity;
                            TempDocumentLine.Insert();
                            if TempDocumentHeader."Location Code" = '' then
                                TempDocumentHeader."Location Code" := TempDocumentLine."Location Code";
                        until SalesShipmentLine.Next() = 0;
                end;
            DATABASE::"Transfer Shipment Header":
                begin
                    RecRef.SetTable(TransferShipmentHeader);
                    TempDocumentHeader.Init();
                    TempDocumentHeader."No." := TransferShipmentHeader."No.";
                    TempDocumentHeader."Posting Date" := TransferShipmentHeader."Posting Date";
                    TempDocumentHeader."Document Date" := TransferShipmentHeader."Transfer Order Date";
                    TempDocumentHeader."Bill-to/Pay-To Address" := TransferShipmentHeader."Transfer-to Address";
                    TempDocumentHeader."Ship-to/Buy-from Country Code" := TransferShipmentHeader."Trsf.-to Country/Region Code";
                    TempDocumentHeader."Ship-to/Buy-from Post Code" := TransferShipmentHeader."Transfer-from Post Code";
                    TempDocumentHeader."Ship-to/Buy-from City" := TransferShipmentHeader."Transfer-from City";
                    TempDocumentHeader."Transit-from Date/Time" := TransferShipmentHeader."Transit-from Date/Time";
                    TempDocumentHeader."Transit Hours" := TransferShipmentHeader."Transit Hours";
                    TempDocumentHeader."Transit Distance" := TransferShipmentHeader."Transit Distance";
                    TempDocumentHeader."Insurer Name" := TransferShipmentHeader."Insurer Name";
                    TempDocumentHeader."Insurer Policy Number" := TransferShipmentHeader."Insurer Policy Number";
                    TempDocumentHeader."Foreign Trade" := TransferShipmentHeader."Foreign Trade";
                    TempDocumentHeader."Vehicle Code" := TransferShipmentHeader."Vehicle Code";
                    TempDocumentHeader."Trailer 1" := TransferShipmentHeader."Trailer 1";
                    TempDocumentHeader."Trailer 2" := TransferShipmentHeader."Trailer 2";
                    TempDocumentHeader."CFDI Purpose" := 'S01';
                    TempDocumentHeader."CFDI Export Code" := TransferShipmentHeader."CFDI Export Code";
                    TempDocumentHeader."Transit-from Location" := TransferShipmentHeader."Transfer-from Code";
                    TempDocumentHeader."Transit-to Location" := TransferShipmentHeader."Transfer-to Code";
                    TempDocumentHeader."Location Code" := TempDocumentHeader."Transit-to Location";
                    TempDocumentHeader."Medical Insurer Name" := TransferShipmentHeader."Medical Insurer Name";
                    TempDocumentHeader."Medical Ins. Policy Number" := TransferShipmentHeader."Medical Ins. Policy Number";
                    TempDocumentHeader."SAT Weight Unit Of Measure" := TransferShipmentHeader."SAT Weight Unit Of Measure";
                    TempDocumentHeader."SAT Transfer Reason" := TransferShipmentHeader."SAT Transfer Reason";
                    TempDocumentHeader."SAT Customs Regime" := TransferShipmentHeader."SAT Customs Regime";
                    TempDocumentHeader."SAT International Trade Term" := TransferShipmentHeader."SAT International Trade Term";
                    TempDocumentHeader."Exchange Rate USD" := TransferShipmentHeader."Exchange Rate USD";
                    if Location.Get(TransferShipmentHeader."Transfer-to Code") then
                        TempDocumentHeader."SAT Address ID" := Location."SAT Address ID";
                    TempDocumentHeader."Document Table ID" := RecRef.Number;
                    UpdateAbstractDocument(TempDocumentHeader);
                    TempDocumentHeader.Insert();
                    TransferShipmentLine.SetRange("Document No.", TransferShipmentHeader."No.");
                    if TransferShipmentLine.FindSet() then
                        repeat
                            TempDocumentLine.Init();
                            TempDocumentLine."Document No." := TransferShipmentLine."Document No.";
                            TempDocumentLine."Line No." := TransferShipmentLine."Line No.";
                            TempDocumentLine.Type := TempDocumentLine.Type::Item;
                            TempDocumentLine."No." := TransferShipmentLine."Item No.";
                            TempDocumentLine.Description := TransferShipmentLine.Description;
                            TempDocumentLine."Unit of Measure Code" := TransferShipmentLine."Unit of Measure Code";
                            TempDocumentLine.Quantity := TransferShipmentLine.Quantity;
                            TempDocumentLine."Gross Weight" := TransferShipmentLine."Gross Weight" * TransferShipmentLine.Quantity;
                            TempDocumentLine."Location Code" := TempDocumentHeader."Location Code";
                            TempDocumentLine."Custom Transit Number" := TransferShipmentLine."Custom Transit Number";
                            TempDocumentLine."SAT Customs Document Type" := TransferShipmentLine."SAT Customs Document Type";
                            TempDocumentLine.Insert();
                            if TempDocumentHeader."Location Code" = '' then
                                TempDocumentHeader."Location Code" := TempDocumentLine."Location Code";
                        until TransferShipmentLine.Next() = 0;
                end;
        end;
        TempDocumentHeader.Modify();
    end;

    local procedure UpdateAbstractDocument(var TempDocumentHeader: Record "Document Header" temporary)
    begin
        if TempDocumentHeader."Currency Code" = '' then begin
            TempDocumentHeader."Currency Code" := GLSetup."LCY Code";
            TempDocumentHeader."Currency Factor" := 1.0;
        end;
        if IsTransferDocument(TempDocumentHeader."Document Table ID") then
            if TempDocumentHeader."Identifier IdCCP" = '' then
                TempDocumentHeader."Identifier IdCCP" := 'CCC' + CopyStr(DelChr(Format(CreateGuid()), '=', '{}'), 4);
    end;

    local procedure UpdateDocumentLine(var TempDocumentLine: Record "Document Line" temporary)
    var
        SATUtilities: Codeunit "SAT Utilities";
    begin
        if TempDocumentLine."Unit of Measure Code" <> '' then
            exit;
        case TempDocumentLine.Type of
            TempDocumentLine.Type::"G/L Account":
                TempDocumentLine."Unit of Measure Code" := SATUtilities.GetSATUnitOfMeasureGLAccount();
            TempDocumentLine.Type::"Fixed Asset":
                TempDocumentLine."Unit of Measure Code" := SATUtilities.GetSATUnitOfMeasureFixedAsset();
        end;
    end;

    local procedure CalcDocumentLineAmounts(var DocumentLine: Record "Document Line"; InvDiscountAmount: Decimal; CurrencyCode: Code[10]; PricesInclVAT: Boolean; LineDiscountPct: Decimal)
    var
        Currency: Record Currency;
        VATFactor: Decimal;
    begin
        if DocumentLine."VAT %" = 0 then begin
            DocumentLine."Line Discount Amount" += InvDiscountAmount;
            exit;
        end;

        VATFactor := 1 + DocumentLine."VAT %" / 100;
        if RoundingModel <> RoundingModel::"Model3-NoRecalculation" then begin
            if LineDiscountPct <> 0 then
                DocumentLine."Line Discount Amount" :=
                    DocumentLine."Unit Price/Direct Unit Cost" * DocumentLine.Quantity * LineDiscountPct / 100;
            DocumentLine."Amount Including VAT" := DocumentLine.Amount * VATFactor;
        end;
        DocumentLine."Line Discount Amount" += InvDiscountAmount;

        if PricesInclVAT then begin
            DocumentLine."Unit Price/Direct Unit Cost" := DocumentLine."Unit Price/Direct Unit Cost" / VATFactor;
            DocumentLine."Line Discount Amount" := DocumentLine."Line Discount Amount" / VATFactor;
        end;

        Currency.Initialize(CurrencyCode);
        if RoundingModel <> RoundingModel::"Model2-Recalc-NoDiscountRounding" then
            DocumentLine."Line Discount Amount" := Round(DocumentLine."Line Discount Amount", Currency."Amount Rounding Precision");

        CalcDocumentLineDecimalBased(DocumentLine);
    end;

    local procedure CalcDocumentLineDecimalBased(var DocumentLine: Record "Document Line")
    var
        DecimalsQty: Integer;
        DecimalsUnitPrice: Integer;
        MinValue: Decimal;
        MaxValue: Decimal;
        InRange: Boolean;
        RoundingPrecision: Decimal;
        Amount: Decimal;
        TestAmount: Decimal;
    begin
        if RoundingModel <> RoundingModel::"Model4-DecimalBased" then
            exit;

        DecimalsQty := StrLen(Format(DocumentLine.Quantity mod 1)) - 2;
        if DecimalsQty < 2 then
            DecimalsQty := 2;
        DecimalsUnitPrice := 6;
        MinValue :=
          (DocumentLine.Quantity - Power(10, -DecimalsQty) / 2) *
          (DocumentLine."Unit Price/Direct Unit Cost" - Power(10, -DecimalsUnitPrice) / 2);
        MinValue := Round(MinValue, 0.000001, '<');
        MaxValue :=
          (DocumentLine.Quantity + Power(10, -DecimalsQty) / 2 - Power(10, -12)) *
          (DocumentLine."Unit Price/Direct Unit Cost" + Power(10, -DecimalsUnitPrice) / 2 - Power(10, -12));
        MaxValue := Round(MaxValue, 0.000001, '>');

        InRange := (DocumentLine.Amount > MinValue) and (DocumentLine.Amount <= MaxValue);
        if InRange then
            exit;

        Amount := DocumentLine.Quantity * DocumentLine."Unit Price/Direct Unit Cost";
        RoundingPrecision := 0.01;
        InRange := false;
        repeat
            TestAmount := Round(Amount, RoundingPrecision, '<');
            InRange := (TestAmount > MinValue) and (TestAmount <= MaxValue);
            RoundingPrecision := RoundingPrecision / 10;
        until InRange or (RoundingPrecision = 0.000001);

        DocumentLine."Line Discount Amount" := Round(DocumentLine."Line Discount Amount", 0.000001);
        if InRange then
            DocumentLine.Amount := TestAmount - DocumentLine."Line Discount Amount";
        DocumentLine."Amount Including VAT" :=
          Round(DocumentLine.Amount * (1 + DocumentLine."VAT %" / 100), 0.000001);
    end;

    local procedure CalcDocumentTotalAmounts(TempDocumentLine: Record "Document Line" temporary; var SubTotal: Decimal; var TotalTax: Decimal; var TotalRetention: Decimal)
    begin
        if TempDocumentLine."Retention Attached to Line No." = 0 then begin
            SubTotal += TempDocumentLine.Amount;
            TotalTax += TempDocumentLine."Amount Including VAT" - TempDocumentLine.Amount;
        end else
            TotalRetention += TempDocumentLine."Amount Including VAT";
    end;

    local procedure GetReportedLineAmount(DocumentLine: Record "Document Line"): Decimal
    begin
        if RoundingModel in [RoundingModel::"Model3-NoRecalculation", RoundingModel::"Model4-DecimalBased"] then
            exit(DocumentLine.Amount + DocumentLine."Line Discount Amount");

        exit(DocumentLine.Quantity * DocumentLine."Unit Price/Direct Unit Cost");
    end;

    local procedure GetCertificateSerialNo(): Text
    begin
        GetGLSetup();
        exit(GetCertificateSerialNo(GLSetup."SAT Certificate"));
    end;

    [NonDebuggable]
    local procedure GetCertificateSerialNo(SATCertificateCode: Code[20]): Text
    var
        IsolatedCertificate: Record "Isolated Certificate";
        CertificateManagement: Codeunit "Certificate Management";
        SerialNo: Text;
        CertificateString: Text;
        SignedString: Text;
    begin
        GetGLSetupOnce();
        if not GLSetup."Sim. Signature" then begin
            IsolatedCertificate.Get(SATCertificateCode);
            CertificateString := CertificateManagement.GetCertAsBase64String(IsolatedCertificate);

            if not SignDataWithCert(SignedString, 'DummyString', CertificateString, CertificateManagement.GetPasswordAsSecret(IsolatedCertificate))
            then begin
                Session.LogMessage(
                    '0000C7Q', StrSubstNo(SATCertificateNotValidErr, GetLastErrorText()),
                    Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
                Error(SATNotValidErr);
            end;

            SerialNo := EInvoiceCommunication.LastUsedCertificateSerialNo();
            exit(SerialNo);
        end;
        exit('');
    end;

    local procedure TaxCodeFromTaxRate(TaxRate: Decimal; TaxType: Option Translado,Retencion): Code[10]
    begin
        if (TaxType = TaxType::Translado) and (TaxRate in [0.16, 0.08]) then
            exit('002'); // IVA

        if (TaxType = TaxType::Retencion) and (TaxRate = 0.1) then
            exit('001');

        if (TaxType = TaxType::Retencion) and (TaxRate in [0.1 .. 0.11]) then
            exit('002');

        if (TaxType = TaxType::Retencion) and ((TaxRate >= 0.0) and (TaxRate <= 0.16)) then
            exit('002'); // IVA

        if (TaxType = TaxType::Retencion) and ((TaxRate >= 0.0) and (TaxRate <= 0.35)) then
            exit('001'); // ISR

        case TaxRate of
            0.265, 0.3, 0.53, 0.5, 1.6, 0.304, 0.25, 0.09, 0.08, 0.07, 0.06, 0.03:
                if (TaxRate = 0.03) and (TaxType <> TaxType::Retencion) then
                    exit('003'); // IEPS
        end;

        if (TaxRate >= 0.0) and (TaxRate <= 43.77) then
            exit('003'); // IEPS
    end;

    procedure RequestPaymentStampDocument(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        SourceCodeSetup: Record "Source Code Setup";
        Selection: Integer;
        ElectronicDocumentStatus: Option;
    begin
        if CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::Payment then
            Error(StampErr, CustLedgerEntry."Document Type");

        // Called from Send Action
        Export := false;
        GetCompanyInfo();
        GetGLSetup();
        SourceCodeSetup.Get();
        Selection := StrMenu(EInvoiceSendActionsTxt, 3);

        ElectronicDocumentStatus := CustLedgerEntry."Electronic Document Status";
        case Selection of
            1:// Request Stamp
                begin
                    EDocActionValidation(EDocAction::"Request Stamp", ElectronicDocumentStatus);
                    RequestPaymentStamp(CustLedgerEntry);
                end;
            2:// Send
                begin
                    EDocActionValidation(EDocAction::Send, ElectronicDocumentStatus);
                    SendPayment(CustLedgerEntry);
                end;
            3:// Request Stamp and Send
                begin
                    EDocActionValidation(EDocAction::"Request Stamp", ElectronicDocumentStatus);
                    RequestPaymentStamp(CustLedgerEntry);
                    Commit();
                    EDocActionValidation(EDocAction::Send, ElectronicDocumentStatus);
                    SendPayment(CustLedgerEntry);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure RequestPaymentStamp(CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        Customer: Record Customer;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        TempDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary;
        TempBlobOriginalString: Codeunit "Temp Blob";
        TempBlobDigitalStamp: Codeunit "Temp Blob";
        XMLDOMManagement: Codeunit "XML DOM Management";
        TypeHelper: Codeunit "Type Helper";
        OutStrOriginalDoc: OutStream;
        OutStrSignedDoc: OutStream;
        XMLDoc: DotNet XmlDocument;
        XMLDocResult: DotNet XmlDocument;
        SystemEnvironment: DotNet SystemEnvironment;
        RecordRef: RecordRef;
        InStream: InStream;
        OriginalString: Text;
        SignedString: Text;
        Certificate: Text;
        Response: Text;
        DateTimeFirstReqSent: Text[50];
        CertificateSerialNo: Text[250];
    begin
        Export := true;
        Customer.Get(CustLedgerEntry."Customer No.");
        CustLedgerEntry.TestField("Payment Method Code");
        Session.LogMessage('0000C7Y', PaymentStampReqMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);

        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Applied Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.SetFilter("Initial Document Type", '=%1|=%2',
          DetailedCustLedgEntry."Initial Document Type"::Invoice,
          DetailedCustLedgEntry."Initial Document Type"::"Credit Memo");
        DetailedCustLedgEntry.SetRange(Unapplied, false);
        if DetailedCustLedgEntry.FindSet() then
            repeat
                Clear(TempDetailedCustLedgEntry);
                TempDetailedCustLedgEntry.TransferFields(DetailedCustLedgEntry, true);
                TempDetailedCustLedgEntry.Insert();
            until DetailedCustLedgEntry.Next() = 0;
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.SetRange("Applied Cust. Ledger Entry No.");
        DetailedCustLedgEntry.SetRange("Initial Document Type", DetailedCustLedgEntry."Initial Document Type"::Payment);
        DetailedCustLedgEntry.SetFilter("Document Type", '=%1|=%2',
          DetailedCustLedgEntry."Initial Document Type"::Invoice,
          DetailedCustLedgEntry."Initial Document Type"::"Credit Memo");
        if DetailedCustLedgEntry.FindSet() then
            repeat
                Clear(TempDetailedCustLedgEntry);
                TempDetailedCustLedgEntry.TransferFields(DetailedCustLedgEntry, true);
                TempDetailedCustLedgEntry.Amount := -Abs(TempDetailedCustLedgEntry.Amount);
                TempDetailedCustLedgEntry.Insert();
            until DetailedCustLedgEntry.Next() = 0;
        if not CheckPaymentStamp(CustLedgerEntry, TempDetailedCustLedgEntry) then
            Error(UnableToStampErr);

        DateTimeFirstReqSent := GetDateTimeOfFirstReqPayment(CustLedgerEntry);
        CurrencyDecimalPlaces := GetCurrencyDecimalPlaces(CustLedgerEntry."Currency Code");

        CalcPaymentData(TempDetailedCustLedgEntry, CustLedgerEntry."Entry No.", CurrencyDecimalPlaces);

        // Create Payment Digital Stamp
        CreateOriginalPaymentStr33(
            Customer, CustLedgerEntry, TempDetailedCustLedgEntry, DateTimeFirstReqSent, TempBlobOriginalString);

        TempBlobOriginalString.CreateInStream(InStream);
        SystemEnvironment := SystemEnvironment.SystemEnvironment();
        OriginalString := TypeHelper.ReadAsTextWithSeparator(InStream, SystemEnvironment.NewLine());
        CreateDigitalSignature(OriginalString, SignedString, CertificateSerialNo, Certificate);
        TempBlobDigitalStamp.CreateOutStream(OutStrSignedDoc);
        OutStrSignedDoc.WriteText(SignedString);

        // Create Payment Original XML
        CreateXMLPayment33(
          Customer, CustLedgerEntry, TempDetailedCustLedgEntry, DateTimeFirstReqSent, SignedString,
          Certificate, CertificateSerialNo, XMLDoc);

        RecordRef.GetTable(CustLedgerEntry);
        TempBlobOriginalString.ToRecordRef(RecordRef, CustLedgerEntry.FieldNo("Original String"));
        TempBlobDigitalStamp.ToRecordRef(RecordRef, CustLedgerEntry.FieldNo("Digital Stamp SAT"));
        RecordRef.SetTable(CustLedgerEntry);
        CustLedgerEntry."Certificate Serial No." := CertificateSerialNo;
        CustLedgerEntry."Original Document XML".CreateOutStream(OutStrOriginalDoc);
        CustLedgerEntry."Signed Document XML".CreateOutStream(OutStrSignedDoc);
        XMLDoc.Save(OutStrOriginalDoc);
        CustLedgerEntry.Modify();

        Commit();

        Response := InvokeMethod(XMLDoc, MethodTypeRef::"Request Stamp");

        // For Test Mocking
        if not GLSetup."Sim. Request Stamp" then begin
            XMLDOMManagement.LoadXMLDocumentFromText(Response, XMLDocResult);
            XMLDocResult.Save(OutStrSignedDoc);
        end;

        ProcessResponseEPayment(CustLedgerEntry, EDocAction::"Request Stamp");
        CustLedgerEntry.Modify();

        Session.LogMessage('0000C7Z', PaymentStampReqSuccessMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
    end;

    local procedure CheckPaymentStamp(CustLedgerEntry: Record "Cust. Ledger Entry"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"): Boolean
    var
        CustLedgerEntryLoc: Record "Cust. Ledger Entry";
        CustLedgerEntryLoc2: Record "Cust. Ledger Entry";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceSourceCode: Code[10];
    begin
        if DetailedCustLedgEntry.FindFirst() then begin
            if DetailedCustLedgEntry."Document Type" = DetailedCustLedgEntry."Document Type"::Payment then
                CustLedgerEntryLoc.SETRANGE("Entry No.", DetailedCustLedgEntry."Cust. Ledger Entry No.")
            else
                CustLedgerEntryLoc.SETRANGE("Entry No.", DetailedCustLedgEntry."Applied Cust. Ledger Entry No.");
            if CustLedgerEntryLoc.FindFirst() then begin
                CustLedgerEntryLoc2.SetRange("Closed by Entry No.", CustLedgerEntryLoc."Entry No.");
                CustLedgerEntryLoc2.SetRange("Date/Time Stamped", '');
                CustLedgerEntryLoc2.SetCurrentKey("Entry No.");
                if CustLedgerEntryLoc2.FindSet() then
                    repeat
                        if CustLedgerEntryLoc2."Entry No." < CustLedgerEntry."Entry No." then
                            // Before we throw warning, check to see if this is a credit memo
                            if CustLedgerEntryLoc2."Document Type" = CustLedgerEntryLoc2."Document Type"::"Credit Memo" then begin
                                // Find the corresponding record
                                SourceCodeSetup.Get();
                                if SourceCodeSetup."Service Management" <> '' then
                                    ServiceSourceCode := SourceCodeSetup."Service Management";
                                if CustLedgerEntryLoc2."Source Code" = ServiceSourceCode then
                                    if ServiceCrMemoHeader.Get(CustLedgerEntryLoc2."Document No.") then
                                        if ServiceCrMemoHeader."Fiscal Invoice Number PAC" <> '' then
                                    exit(true);
                                if SalesCrMemoHeader.Get(CustLedgerEntryLoc2."Document No.") then
                                    if SalesCrMemoHeader."Fiscal Invoice Number PAC" <> '' then
                                        exit(true);
                                exit(false);
                            end;
                        if DetailedCustLedgEntry."Document Type" = DetailedCustLedgEntry."Document Type"::Payment then
                            if CustLedgerEntryLoc2."Entry No." = CustLedgerEntry."Entry No." then
                                exit(true);
                        if DetailedCustLedgEntry."Document Type" = DetailedCustLedgEntry."Document Type"::Invoice then
                            exit(true);
                    until CustLedgerEntryLoc2.Next() = 0
                else
                    exit(true);
            end;
        end;
    end;

    local procedure SumStampedPayments(CustLedgerEntry: Record "Cust. Ledger Entry"; var StampedAmount: Decimal; var PaymentNo: Integer)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustLedgerEntryLoc: Record "Cust. Ledger Entry";
    begin
        StampedAmount := 0;
        PaymentNo := 1;
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.SetFilter("Entry Type", '<>%1', DetailedCustLedgEntry."Entry Type"::"Initial Entry");
        DetailedCustLedgEntry.SetRange(Unapplied, false);
        if DetailedCustLedgEntry.FindSet() then
            repeat
                if CustLedgerEntryLoc.Get(DetailedCustLedgEntry."Applied Cust. Ledger Entry No.") then
                    if CustLedgerEntryLoc."Fiscal Invoice Number PAC" <> '' then begin
                        StampedAmount += DetailedCustLedgEntry.Amount;
                        PaymentNo += 1;
                    end;
            until DetailedCustLedgEntry.Next() = 0;
    end;

    local procedure SendPayment(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        SendEPayment(CustLedgerEntry);
    end;

    local procedure SendEPayment(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        Customer: Record Customer;
        CustLedgerEntryLoc: Record "Cust. Ledger Entry";
        CustLedgerEntryLoc2: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        DummyTempBlobPDF: Codeunit "Temp Blob";
        LedgerEntryRef: RecordRef;
        RecordRef: RecordRef;
        XMLInstream: InStream;
        FileNameEdoc: Text;
    begin
        GetCustomer(Customer, CustLedgerEntry."Customer No.", true);
        if CustLedgerEntry."No. of E-Documents Sent" <> 0 then
            if not Confirm(PaymentsAlreadySentQst) then
                Error('');

        Session.LogMessage('0000C80', SendPaymentMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);

        // Export XML
        CustLedgerEntry.CalcFields("Signed Document XML");
        TempBlob.FromRecord(CustLedgerEntry, CustLedgerEntry.FieldNo("Signed Document XML"));
        TempBlob.CreateInStream(XMLInstream);
        FileNameEdoc := CustLedgerEntry."Document No." + '.xml';
        RecordRef.GetTable(CustLedgerEntryLoc2);
        TempBlob.ToRecordRef(RecordRef, CustLedgerEntryLoc2.FieldNo("Signed Document XML"));
        RecordRef.SetTable(CustLedgerEntryLoc2);

        // Send Email with Attachments
        LedgerEntryRef.GetTable(CustLedgerEntry);
        SendEmail(DummyTempBlobPDF, Customer."E-Mail", StrSubstNo(PaymentNoMsg, CustLedgerEntry."Document No."),
          StrSubstNo(PaymentAttachmentMsg, CustLedgerEntry."Document No."), FileNameEdoc, '', XMLInstream);

        CustLedgerEntryLoc.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntryLoc."No. of E-Documents Sent" := CustLedgerEntryLoc."No. of E-Documents Sent" + 1;
        if not CustLedgerEntryLoc."Electronic Document Sent" then
            CustLedgerEntryLoc."Electronic Document Sent" := true;
        CustLedgerEntryLoc."Electronic Document Status" := CustLedgerEntryLoc."Electronic Document Status"::Sent;
        CustLedgerEntryLoc."Date/Time Sent" :=
          FormatDateTime(ConvertCurrentDateTimeToTimeZone(GetTimeZoneFromCustomer(CustLedgerEntry."Customer No.")));
        CustLedgerEntryLoc.Modify();

        Message(Text001, CustLedgerEntry."Document No.");

        Session.LogMessage('0000C81', SendPaymentSuccessMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
    end;

    local procedure ProcessResponseEPayment(var CustLedgerEntry: Record "Cust. Ledger Entry"; "Action": Option)
    var
        Customer: Record Customer;
        PACWebService: Record "PAC Web Service";
        TempBlob: Codeunit "Temp Blob";
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLDoc: DotNet XmlDocument;
        XMLDocResult: DotNet XmlDocument;
        XMLCurrNode: DotNet XmlNode;
        XMLDOMNamedNodeMap: DotNet XmlNamedNodeMap;
        XMLDOMNodeList: DotNet XmlNodeList;
        NamespaceManager: DotNet XmlNamespaceManager;
        RecordRef: RecordRef;
        OutStr: OutStream;
        InStr: InStream;
        NodeCount: Integer;
        Counter: Integer;
        QRCodeInput: Text;
        ErrorDescription: Text;
        TelemetryError: Text;
        CancelStatus: Option InProgress,Rejected,Cancelled;
        CancelResult: Text[250];
        DocumentStatus: Option " ","Stamp Received",Sent,Canceled,"Stamp Request Error","Cancel Error","Cancel In Progress";
        DateTimeCancelled: Text[50];
    begin
        GetGLSetup();
        GetCheckCompanyInfo();
        // Switch from sales hdr Bill-toCustomerNo. to just Customer no.
        GetCustomer(Customer, CustLedgerEntry."Customer No.", false);

        // Process Response and Load back to header the Signed XML if you get one...
        if IsNull(XMLDocResult) then
            XMLDocResult := XMLDocResult.XmlDocument();

        CustLedgerEntry.CalcFields("Signed Document XML");
        CustLedgerEntry."Signed Document XML".CreateInStream(InStr);
        XMLDOMManagement.LoadXMLDocumentFromInStream(InStr, XMLDocResult);
        Clear(CustLedgerEntry."Signed Document XML");
        XMLCurrNode := XMLDocResult.SelectSingleNode('Resultado');

        XMLDOMNamedNodeMap := XMLCurrNode.Attributes;
        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('IdRespuesta');

        PACWebService.Get(GLSetup."PAC Code");
        CustLedgerEntry."PAC Web Service Name" := PACWebService.Name;

        if XMLCurrNode.Value <> '1' then begin
            CustLedgerEntry."Error Code" := XMLCurrNode.Value();
            XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('Descripcion');
            ErrorDescription := XMLCurrNode.Value();
            XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('Detalle');
            if not IsNull(XMLCurrNode) then
                ErrorDescription := ErrorDescription + ': ' + XMLCurrNode.Value();
            TelemetryError := ErrorDescription;
            if StrLen(ErrorDescription) > 250 then
                ErrorDescription := CopyStr(ErrorDescription, 1, 247) + '...';
            CustLedgerEntry."Error Description" := CopyStr(ErrorDescription, 1, 250);
            case Action of
                EDocAction::"Request Stamp":
                    CustLedgerEntry."Electronic Document Status" := CustLedgerEntry."Electronic Document Status"::"Stamp Request Error";
                EDocAction::Cancel:
                    begin
                        CustLedgerEntry."Electronic Document Status" := CustLedgerEntry."Electronic Document Status"::"Cancel Error";
                        CustLedgerEntry."Date/Time Canceled" := '';
                    end;
            end;

            Session.LogMessage('0000C82', StrSubstNo(ProcessPaymentErr, TelemetryError), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);

            exit;
        end;

        CustLedgerEntry."Error Code" := '';
        CustLedgerEntry."Error Description" := '';
        if Action = EDocAction::Cancel then begin
            CustLedgerEntry."Electronic Document Status" := CustLedgerEntry."Electronic Document Status"::"Cancel In Progress";
            CustLedgerEntry."CFDI Cancellation ID" := GetResponseValueCancellationID(XMLCurrNode, XMLDOMNamedNodeMap);
            exit;
        end;
        if Action = EDocAction::CancelRequest then begin
            ProcessCancelResponse(XMLDocResult, XMLCurrNode, XMLDOMNamedNodeMap, CancelStatus, CancelResult, DateTimeCancelled);
            GetDocumentStatusFromCancelStatus(DocumentStatus, CancelStatus);
            CustLedgerEntry."Electronic Document Status" := DocumentStatus;
            CustLedgerEntry."Error Description" := CancelResult;
            CustLedgerEntry."Date/Time Canceled" := DateTimeCancelled;
            exit;
        end;

        XMLCurrNode := XMLDocResult.SelectSingleNode('Resultado');
        XMLDOMNodeList := XMLCurrNode.ChildNodes;
        NodeCount := XMLDOMNodeList.Count();

        Clear(XMLDoc);
        XMLDoc := XMLDoc.XmlDocument();
        for Counter := 0 to (NodeCount - 1) do begin
            XMLCurrNode := XMLDOMNodeList.Item(Counter);
            XMLDoc.AppendChild(XMLDoc.ImportNode(XMLCurrNode, true));
        end;

        CustLedgerEntry."Signed Document XML".CreateOutStream(OutStr);

        XMLDoc.Save(OutStr);
        // *****Does any of this need to change for Payments?
        NamespaceManager := NamespaceManager.XmlNamespaceManager(XMLDoc.NameTable);
        NamespaceManager.AddNamespace('cfdi', 'http://www.sat.gob.mx/cfd/4');
        NamespaceManager.AddNamespace('pago20', 'http://www.sat.gob.mx/Pagos20');
        NamespaceManager.AddNamespace('tfd', 'http://www.sat.gob.mx/TimbreFiscalDigital');
        XMLCurrNode := XMLDoc.SelectSingleNode('cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital', NamespaceManager);
        XMLDOMNamedNodeMap := XMLCurrNode.Attributes;

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('FechaTimbrado');
        CustLedgerEntry."Date/Time Stamped" := XMLCurrNode.Value();
        CustLedgerEntry."Date/Time Stamp Received" := ConvertStingToDateTime(CustLedgerEntry."Date/Time Stamped");

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('UUID');
        CustLedgerEntry."Fiscal Invoice Number PAC" := XMLCurrNode.Value();

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('NoCertificadoSAT');
        CustLedgerEntry."Certificate Serial No." := XMLCurrNode.Value();

        XMLCurrNode := XMLDOMNamedNodeMap.GetNamedItem('SelloSAT');

        Clear(OutStr);
        CustLedgerEntry."Digital Stamp PAC".CreateOutStream(OutStr);
        OutStr.WriteText(XMLCurrNode.Value);
        // Certificate Serial
        CustLedgerEntry."Electronic Document Status" := CustLedgerEntry."Electronic Document Status"::"Stamp Received";

        // Create QRCode
        CustLedgerEntry.CalcFields(Amount);
        QRCodeInput := CreateQRCodeInput(CompanyInfo."RFC Number", Customer."RFC No.", CustLedgerEntry.Amount,
            Format(CustLedgerEntry."Fiscal Invoice Number PAC"));
        CreateQRCode(QRCodeInput, TempBlob);
        RecordRef.GetTable(CustLedgerEntry);
        TempBlob.ToRecordRef(RecordRef, CustLedgerEntry.FieldNo("QR Code"));
        RecordRef.SetTable(CustLedgerEntry);
    end;

    local procedure CreateXMLPayment33(var TempCustomer: Record Customer temporary; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; var TempDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary; DateTimeFirstReqSent: Text[50]; SignedString: Text; Certificate: Text; CertificateSerialNo: Text[250]; var XMLDoc: DotNet XmlDocument)
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        CustomerBankAccount: Record "Customer Bank Account";
        TempVATAmountLine: record "VAT Amount Line" temporary;
        TempVATAmountLinePmt: Record "VAT Amount Line" temporary;
        TempVATAmountLineTotal: Record "VAT Amount Line" temporary;
        DetailedCustLedgEntryPmt: Record "Detailed Cust. Ledg. Entry";
        SATUtilities: Codeunit "SAT Utilities";
        XMLCurrNode: DotNet XmlNode;
        XMLNewChild: DotNet XmlNode;
        SumOfStamped: Decimal;
        UUID: Text[50];
        PaymentNo: Integer;
        AmountInclVAT: Decimal;
        PaymentAmount: Decimal;
        PaymentAmountLCY: Decimal;
        SATPostalCode: Code[20];
        SubjectToTax: Text;
        TipoCambioP: Decimal;
        CurrencyFactorPayment: Decimal;
        EquivalenciaDR: Decimal;
    begin
        InitPaymentXML(XMLDoc, XMLCurrNode);
        AddAttribute(XMLDoc, XMLCurrNode, 'Version', '4.0');
        AddAttribute(XMLDoc, XMLCurrNode, 'Folio', TempCustLedgerEntry."Document No.");
        AddAttribute(XMLDoc, XMLCurrNode, 'Fecha', DateTimeFirstReqSent);
        AddAttribute(XMLDoc, XMLCurrNode, 'Sello', SignedString);
        AddAttribute(XMLDoc, XMLCurrNode, 'NoCertificado', CertificateSerialNo);
        AddAttribute(XMLDoc, XMLCurrNode, 'Certificado', Certificate);
        AddAttribute(XMLDoc, XMLCurrNode, 'SubTotal', '0');
        AddAttribute(XMLDoc, XMLCurrNode, 'Moneda', 'XXX');
        AddAttribute(XMLDoc, XMLCurrNode, 'Total', '0');
        AddAttribute(XMLDoc, XMLCurrNode, 'TipoDeComprobante', 'P');// Pago
        AddAttribute(XMLDoc, XMLCurrNode, 'Exportacion', TempCustomer."CFDI Export Code");
        AddAttribute(XMLDoc, XMLCurrNode, 'LugarExpedicion', CompanyInfo."SAT Postal Code");
        // Emisor
        AddNodeCompanyInfo(XMLDoc, XMLCurrNode);

        TempDetailedCustLedgEntry.FindFirst();
        GetPmtDataFromFirstDoc(TempDetailedCustLedgEntry, SATPostalCode);
        // Receptor
        AddNodeReceptor(XMLDoc, XMLCurrNode, TempCustomer, TempCustomer."CFDI Customer Name", SATPostalCode, 'CP01');
        // Conceptos
        AddElementCFDI(XMLCurrNode, 'Conceptos', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        // Conceptos->Concepto
        AddElementCFDI(XMLCurrNode, 'Concepto', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddAttribute(XMLDoc, XMLCurrNode, 'ClaveProdServ', '84111506');
        AddAttribute(XMLDoc, XMLCurrNode, 'NoIdentificacion', '');
        AddAttribute(XMLDoc, XMLCurrNode, 'Cantidad', '1');
        AddAttribute(XMLDoc, XMLCurrNode, 'ClaveUnidad', 'ACT');
        AddAttribute(XMLDoc, XMLCurrNode, 'Unidad', '');
        AddAttribute(XMLDoc, XMLCurrNode, 'Descripcion', 'Pago');
        AddAttribute(XMLDoc, XMLCurrNode, 'ValorUnitario', '0');
        AddAttribute(XMLDoc, XMLCurrNode, 'Importe', '0');
        AddAttribute(XMLDoc, XMLCurrNode, 'ObjetoImp', '01');

        XMLCurrNode := XMLCurrNode.ParentNode;
        XMLCurrNode := XMLCurrNode.ParentNode;
        // Complemento
        AddElementCFDI(XMLCurrNode, 'Complemento', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        // Pagos
        DocNameSpace := 'http://www.sat.gob.mx/Pagos20';
        AddElementPago(XMLCurrNode, 'Pagos', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddAttribute(XMLDoc, XMLCurrNode, 'xmlns:pago20', 'http://www.sat.gob.mx/Pagos20');
        AddAttribute(XMLDoc, XMLCurrNode, 'Version', '2.0');
        // Pagos->Pago
        CurrencyFactorPayment := TempCustLedgerEntry."Original Currency Factor";
        GetPaymentData(
          TempDetailedCustLedgEntry, DetailedCustLedgEntryPmt, TempVATAmountLine, TempVATAmountLinePmt, TempVATAmountLineTotal,
          PaymentAmount, PaymentAmountLCY, CurrencyFactorPayment, TempCustLedgerEntry."Entry No.");

        AddElementPago(XMLCurrNode, 'Totales', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;

        AddNodePagoTotales(XMLDoc, XMLCurrNode, TempVATAmountLineTotal);
        AddAttribute(XMLDoc, XMLCurrNode, 'MontoTotalPagos', FormatAmount(PaymentAmountLCY));
        XMLCurrNode := XMLCurrNode.ParentNode;

        AddElementPago(XMLCurrNode, 'Pago', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddAttribute(XMLDoc, XMLCurrNode, 'FechaPago', FormatAsDateTime(TempCustLedgerEntry."Posting Date", 120000T, ''));
        AddAttribute(XMLDoc, XMLCurrNode, 'FormaDePagoP', SATUtilities.GetSATPaymentMethod(TempCustLedgerEntry."Payment Method Code"));
        AddAttribute(XMLDoc, XMLCurrNode, 'MonedaP', ConvertCurrency(TempCustLedgerEntry."Currency Code"));
        TipoCambioP := Round(PaymentAmountLCY / PaymentAmount, 0.000001);
        if ConvertCurrency(TempCustLedgerEntry."Currency Code") <> GLSetup."LCY Code" then
            AddAttribute(XMLDoc, XMLCurrNode, 'TipoCambioP', FormatDecimal(TipoCambioP, 6))
        else
            AddAttribute(XMLDoc, XMLCurrNode, 'TipoCambioP', '1');

        AddAttribute(XMLDoc, XMLCurrNode, 'Monto', FormatAmount(PaymentAmount));
        if (TempCustomer."Currency Code" <> 'MXN') and (TempCustomer."Currency Code" <> 'XXX') then
            if TempCustomer."Preferred Bank Account Code" <> '' then
                AddAttribute(XMLDoc, XMLCurrNode, 'NomBancoOrdExt', TempCustomer."Preferred Bank Account Code")
            else begin
                CustomerBankAccount.Reset();
                CustomerBankAccount.SetRange("Customer No.", TempCustomer."No.");
                if CustomerBankAccount.FindFirst() then
                    // Find the first one...
                    AddAttribute(XMLDoc, XMLCurrNode, 'NomBancoOrdExt', CustomerBankAccount."Bank Account No.")
                else
                    // Put in a blank number
                    AddAttribute(XMLDoc, XMLCurrNode, 'NomBancoOrdExt', '');
            end;

        if TempDetailedCustLedgEntry.FindSet() then
            repeat
                // DoctoRelacionado
                AddElementPago(XMLCurrNode, 'DoctoRelacionado', '', DocNameSpace, XMLNewChild);
                XMLCurrNode := XMLNewChild;
                if TempDetailedCustLedgEntry."Document Type" = TempDetailedCustLedgEntry."Document Type"::Payment then
                    CustLedgerEntry2.GET(TempDetailedCustLedgEntry."Cust. Ledger Entry No.")
                else
                    CustLedgerEntry2.GET(TempDetailedCustLedgEntry."Applied Cust. Ledger Entry No.");

                GetRelatedDocumentData(
                  TempDetailedCustLedgEntry, CustLedgerEntry2."Document No.", CustLedgerEntry2."Source Code",
                  TempVATAmountLine, UUID, AmountInclVAT, SubjectToTax);

                UpdatePartialPaymentAmounts(TempDetailedCustLedgEntry, CustLedgerEntry2, TempVATAmountLine);

                AddAttribute(XMLDoc, XMLCurrNode, 'IdDocumento', UUID);// this needs to be changed
                AddAttribute(XMLDoc, XMLCurrNode, 'Folio', CustLedgerEntry2."Document No.");
                AddAttribute(XMLDoc, XMLCurrNode, 'MonedaDR', ConvertCurrency(CustLedgerEntry2."Currency Code"));

                EquivalenciaDR := TempDetailedCustLedgEntry."Remaining Pmt. Disc. Possible";
                AddAttribute(XMLDoc, XMLCurrNode, 'EquivalenciaDR', FormatEquivalenciaDR(EquivalenciaDR, TempDetailedCustLedgEntry.Count()));

                SumStampedPayments(CustLedgerEntry2, SumOfStamped, PaymentNo);
                AddAttribute(XMLDoc, XMLCurrNode, 'NumParcialidad', Format(PaymentNo));
                AddAttribute(
                  XMLDoc, XMLCurrNode, 'ImpSaldoAnt', FormatAmount(AmountInclVAT + SumOfStamped));
                AddAttribute(XMLDoc, XMLCurrNode, 'ImpPagado', FormatAmount(TempDetailedCustLedgEntry.Amount));
                AddAttribute(XMLDoc, XMLCurrNode, 'ImpSaldoInsoluto',
                  FormatAmount(AmountInclVAT + (TempDetailedCustLedgEntry.Amount + SumOfStamped)));

                AddAttribute(XMLDoc, XMLCurrNode, 'ObjetoImpDR', SubjectToTax);

                AddNodePagoImpuestosDR(TempVATAmountLine, XMLDoc, XMLCurrNode, XMLNewChild);

                XMLCurrNode := XMLCurrNode.ParentNode; // DoctoRelacionado
            until TempDetailedCustLedgEntry.Next() = 0;
        // ImpuestosP
        AddNodePagoImpuestosP(XMLDoc, XMLCurrNode, XMLNewChild, TempVATAmountLinePmt);

        XMLCurrNode := XMLCurrNode.ParentNode;
        // Pago
        XMLCurrNode := XMLCurrNode.ParentNode; // Pagos
    end;

    procedure CreateOriginalPaymentStr33(var TempCustomer: Record Customer temporary; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; var TempDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary; DateTimeFirstReqSent: Text; var TempBlob: Codeunit "Temp Blob")
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        CustomerBankAccount: Record "Customer Bank Account";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLinePmt: Record "VAT Amount Line" temporary;
        TempVATAmountLineTotal: Record "VAT Amount Line" temporary;
        DetailedCustLedgEntryPmt: Record "Detailed Cust. Ledg. Entry";
        SATUtilities: Codeunit "SAT Utilities";
        OutStream: OutStream;
        SumOfStamped: Decimal;
        UUID: Text[50];
        PaymentNo: Integer;
        AmountInclVAT: Decimal;
        PaymentAmount: Decimal;
        PaymentAmountLCY: Decimal;
        SATPostalCode: Code[20];
        SubjectToTax: Text;
        TipoCambioP: Decimal;
        CurrencyFactorPayment: Decimal;
        EquivalenciaDR: Decimal;
    begin
        GetCompanyInfo();
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream);
        WriteOutStr(OutStream, '||4.0|');
        // Version
        WriteOutStr(OutStream, TempCustLedgerEntry."Document No." + '|');// Folio...PaymentNo.
        WriteOutStr(OutStream, DateTimeFirstReqSent + '|');
        // Fecha
        WriteOutStr(OutStream, GetCertificateSerialNo() + '|');
        // NoCertificado
        WriteOutStr(OutStream, '0|');// Subtotal
        WriteOutStr(OutStream, 'XXX|');// Monenda***notWritingOptional
        WriteOutStr(OutStream, '0|');// Total
        WriteOutStr(OutStream, 'P|');// TipoDeComprobante
        WriteOutStr(OutStream, TempCustomer."CFDI Export Code" + '|');// Exportacion
        WriteOutStr(OutStream, RemoveInvalidChars(CompanyInfo."SAT Postal Code") + '|');// LugarExpedicion
                                                                                        // Emisor
        AddStrCompanyInfo(OutStream);

        TempDetailedCustLedgEntry.FindFirst();
        GetPmtDataFromFirstDoc(TempDetailedCustLedgEntry, SATPostalCode);
        // Receptor
        AddStrReceptor(OutStream, TempCustomer, TempCustomer."CFDI Customer Name", SATPostalCode, 'CP01');
        // Conceptos->Concepto
        WriteOutStr(OutStream, '84111506' + '|');// ClaveProdServ
        WriteOutStr(OutStream, '1' + '|');// Cantidad
        WriteOutStr(OutStream, 'ACT' + '|');// ClaveUnidad
        WriteOutStr(OutStream, 'Pago' + '|');// Descripcion
        WriteOutStr(OutStream, '0' + '|');// ValorUnitario
        WriteOutStr(OutStream, '0' + '|');// Importe
        WriteOutStr(OutStream, '01' + '|');// ObjetoImp
                                           // Pagos
        WriteOutStr(OutStream, '2.0' + '|');// VersionForPagoHCto1.0
        CurrencyFactorPayment := TempCustLedgerEntry."Original Currency Factor";
        GetPaymentData(
          TempDetailedCustLedgEntry, DetailedCustLedgEntryPmt, TempVATAmountLine, TempVATAmountLinePmt, TempVATAmountLineTotal,
          PaymentAmount, PaymentAmountLCY, CurrencyFactorPayment, TempCustLedgerEntry."Entry No.");
        // Pagos->Pago
        // Totales
        AddStrPagoTotales(TempVATAmountLineTotal, OutStream);
        WriteOutStr(OutStream, FormatAmount(PaymentAmountLCY) + '|');// Totales/MontoTotalPagos
        WriteOutStr(OutStream, FormatAsDateTime(TempCustLedgerEntry."Posting Date", 120000T, '') + '|');// FechaPagoSetToPD
        WriteOutStr(OutStream, SATUtilities.GetSATPaymentMethod(TempCustLedgerEntry."Payment Method Code") + '|');// FormaDePagoP
        WriteOutStr(OutStream, ConvertCurrency(TempCustLedgerEntry."Currency Code") + '|');// MonedaP
        TipoCambioP := Round(PaymentAmountLCY / PaymentAmount, 0.000001);

        if ConvertCurrency(TempCustLedgerEntry."Currency Code") <> GLSetup."LCY Code" then
            WriteOutStr(OutStream, FormatDecimal(TipoCambioP, 6) + '|')
        // TipoCambioP
        else
            WriteOutStr(OutStream, '1|');

        WriteOutStr(OutStream, FormatAmount(PaymentAmount) + '|');
        // Monto
        if (TempCustomer."Currency Code" <> 'MXN') and (TempCustomer."Currency Code" <> 'XXX') then
            if TempCustomer."Preferred Bank Account Code" <> '' then
                WriteOutStr(OutStream, TempCustomer."Preferred Bank Account Code" + '|')
            else begin
                CustomerBankAccount.Reset();
                CustomerBankAccount.SetRange("Customer No.", TempCustomer."No.");
                if CustomerBankAccount.FindFirst() then
                    // Find the first one...
                    WriteOutStr(OutStream, CustomerBankAccount."Bank Account No." + '|')
                else
                    WriteOutStr(OutStream, '' + '|');
            end;

        if TempDetailedCustLedgEntry.FindSet() then
            repeat
                // DoctoRelacionado
                if TempDetailedCustLedgEntry."Document Type" = TempDetailedCustLedgEntry."Document Type"::Payment then
                    CustLedgerEntry2.GET(TempDetailedCustLedgEntry."Cust. Ledger Entry No.")
                else
                    CustLedgerEntry2.GET(TempDetailedCustLedgEntry."Applied Cust. Ledger Entry No.");

                GetRelatedDocumentData(
                  TempDetailedCustLedgEntry, CustLedgerEntry2."Document No.", CustLedgerEntry2."Source Code",
                  TempVATAmountLine, UUID, AmountInclVAT, SubjectToTax);

                UpdatePartialPaymentAmounts(TempDetailedCustLedgEntry, CustLedgerEntry2, TempVATAmountLine);

                WriteOutStr(OutStream, UUID + '|');// IdDocumento
                WriteOutStr(OutStream, CustLedgerEntry2."Document No." + '|');// Folio
                WriteOutStr(OutStream, ConvertCurrency(CustLedgerEntry2."Currency Code") + '|');
                // MonedaDR
                EquivalenciaDR := TempDetailedCustLedgEntry."Remaining Pmt. Disc. Possible";
                WriteOutStr(OutStream, FormatEquivalenciaDR(EquivalenciaDR, TempDetailedCustLedgEntry.Count()) + '|');

                SumStampedPayments(CustLedgerEntry2, SumOfStamped, PaymentNo);
                WriteOutStr(OutStream, Format(PaymentNo) + '|');// NumParcialidad
                WriteOutStr(OutStream, FormatAmount(AmountInclVAT + SumOfStamped) + '|');// ImpSaldoAnt
                WriteOutStr(OutStream, FormatAmount(TempDetailedCustLedgEntry.Amount) + '|');
                // ImpPagado
                WriteOutStr(OutStream,
                  FormatAmount(AmountInclVAT + (TempDetailedCustLedgEntry.Amount + SumOfStamped)) + '|');// ImpSaldoInsoluto
                WriteOutStr(OutStream, SubjectToTax + '|');
                // ObjetoImpDR
                AddStrPagoImpuestosDR(TempVATAmountLine, OutStream);
            until TempDetailedCustLedgEntry.Next() = 0;
        // ImpuestosP
        AddStrPagoImpuestosP(TempVATAmountLinePmt, OutStream);
        // Need one more pipe character at end of built string...
        WriteOutStrAllowOneCharacter(OutStream, '|');
    end;

    local procedure InitPaymentXML(var XMLDoc: DotNet XmlDocument; var XMLCurrNode: DotNet XmlNode)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
    begin
        // Create instance
        if IsNull(XMLDoc) then
            XMLDoc := XMLDoc.XmlDocument();

        // Root element
        DocNameSpace := 'http://www.sat.gob.mx/cfd/4';
        XMLDOMManagement.LoadXMLDocumentFromText('<?xml version="1.0" encoding="UTF-8" ?> ' +
          '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" xmlns="" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' +
          'xsi:schemaLocation="http://www.sat.gob.mx/cfd/4 http://www.sat.gob.mx/sitio_internet/cfd/4/cfdv40.xsd' +
          ' http://www.sat.gob.mx/Pagos20 http://www.sat.gob.mx/sitio_internet/cfd/Pagos/Pagos20.xsd" ' +
          'xmlns:pago20="http://www.sat.gob.mx/Pagos20"></cfdi:Comprobante>',
          XMLDoc);

        XMLCurrNode := XMLDoc.DocumentElement;
    end;

    local procedure InitCFDIRelatedDocuments(var TempCFDIRelationDocument: Record "CFDI Relation Document" temporary; UUID: Text[50]; RelationType: Code[10])
    begin
        if UUID = '' then
            exit;
        TempCFDIRelationDocument.Init();
        TempCFDIRelationDocument."SAT Relation Type" := RelationType;
        TempCFDIRelationDocument."Fiscal Invoice Number PAC" := UUID;
        TempCFDIRelationDocument.Insert();
    end;

    local procedure CalcPaymentData(var TempDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary; PaymentEntryNo: Integer; CurrencyDecimals: Integer)
    var
        DetailedCustLedgEntryPmt: Record "Detailed Cust. Ledg. Entry";
        CustLedgerEntryPmt: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        CurrencyFactorInvoice: Decimal;
        EquivalenciaDR: Decimal;
        PaymentAmount: Decimal;
        CurrencyFactorPayment: Decimal;
        Monto: Decimal;
    begin
        GetPmtCustDtldEntry(DetailedCustLedgEntryPmt, PaymentEntryNo);
        DetailedCustLedgEntryPmt.CalcSums(Amount, "Amount (LCY)");
        PaymentAmount := Abs(DetailedCustLedgEntryPmt.Amount);
        CustLedgerEntryPmt.Get(PaymentEntryNo);

        CurrencyFactorPayment := DetailedCustLedgEntryPmt.Amount / DetailedCustLedgEntryPmt."Amount (LCY)";
        if TempDetailedCustLedgEntry.FindSet(true) then
            repeat
                if TempDetailedCustLedgEntry."Document Type" = TempDetailedCustLedgEntry."Document Type"::Payment then
                    CustLedgerEntry2.Get(TempDetailedCustLedgEntry."Cust. Ledger Entry No.")
                else
                    CustLedgerEntry2.Get(TempDetailedCustLedgEntry."Applied Cust. Ledger Entry No.");

                CurrencyFactorInvoice := TempDetailedCustLedgEntry.Amount / TempDetailedCustLedgEntry."Amount (LCY)";

                if GLSetup."Disable CFDI Payment Details" then
                    EquivalenciaDR := CustLedgerEntry2."Original Currency Factor" / CustLedgerEntryPmt."Original Currency Factor"
                else
                    if ConvertCurrency(DetailedCustLedgEntryPmt."Currency Code") = ConvertCurrency(CustLedgerEntry2."Currency Code") then
                        EquivalenciaDR := 1
                    else
                        EquivalenciaDR := Round(CurrencyFactorInvoice / CurrencyFactorPayment, 0.0000000001);

                TempDetailedCustLedgEntry."Remaining Pmt. Disc. Possible" := EquivalenciaDR;
                TempDetailedCustLedgEntry.Modify();

                Monto += Abs(TempDetailedCustLedgEntry.Amount) / EquivalenciaDR;
            until TempDetailedCustLedgEntry.Next() = 0;

        if GLSetup."Disable CFDI Payment Details" then
            exit;

        Monto := Round(Monto, Power(0.1, CurrencyDecimals));
        if Monto <= Round(PaymentAmount, Power(0.1, CurrencyDecimals)) then
            exit;

        if TempDetailedCustLedgEntry.FindSet(true) then
            repeat
                if TempDetailedCustLedgEntry."Remaining Pmt. Disc. Possible" <> 1 then begin // EquivalenciaDR
                    TempDetailedCustLedgEntry."Remaining Pmt. Disc. Possible" += 0.0000000001;
                    TempDetailedCustLedgEntry.Modify();
                end;
            until TempDetailedCustLedgEntry.Next() = 0;
    end;

    local procedure GetPaymentData(var TempDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary; var DetailedCustLedgEntryPmt: Record "Detailed Cust. Ledg. Entry"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLinePmt: Record "VAT Amount Line" temporary; var TempVATAmountLineTotal: Record "VAT Amount Line" temporary; var PaymentAmount: Decimal; var PaymentAmountLCY: Decimal; var CurrencyFactorPayment: Decimal; PaymentEntryNo: Integer)
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        EquivalenciaDR: Decimal;
        UUID: Text[50];
        DocAmountInclVAT: Decimal;
        SubjectToTax: Text;
    begin
        GetPmtCustDtldEntry(DetailedCustLedgEntryPmt, PaymentEntryNo);
        DetailedCustLedgEntryPmt.CalcSums(Amount, "Amount (LCY)");
        PaymentAmount := Abs(DetailedCustLedgEntryPmt.Amount);
        PaymentAmountLCY := Abs(DetailedCustLedgEntryPmt."Amount (LCY)");
        if GLSetup."Disable CFDI Payment Details" then
            exit;

        CurrencyFactorPayment := DetailedCustLedgEntryPmt.Amount / DetailedCustLedgEntryPmt."Amount (LCY)";
        if TempDetailedCustLedgEntry.FindSet() then
            repeat
                if TempDetailedCustLedgEntry."Document Type" = TempDetailedCustLedgEntry."Document Type"::Payment then
                    CustLedgerEntry2.Get(TempDetailedCustLedgEntry."Cust. Ledger Entry No.")
                else
                    CustLedgerEntry2.Get(TempDetailedCustLedgEntry."Applied Cust. Ledger Entry No.");
                GetRelatedDocumentData(
                  TempDetailedCustLedgEntry, CustLedgerEntry2."Document No.", CustLedgerEntry2."Source Code",
                  TempVATAmountLine, UUID, DocAmountInclVAT, SubjectToTax);
                UpdatePartialPaymentAmounts(TempDetailedCustLedgEntry, CustLedgerEntry2, TempVATAmountLine);

                EquivalenciaDR := TempDetailedCustLedgEntry."Remaining Pmt. Disc. Possible";

                InsertTempVATAmountLinePmt(TempVATAmountLinePmt, TempVATAmountLine, EquivalenciaDR);
            until TempDetailedCustLedgEntry.Next() = 0;

        InsertTempVATAmountLinePmtTotals(
          TempVATAmountLineTotal, TempVATAmountLinePmt,
          DetailedCustLedgEntryPmt."Currency Code", CurrencyFactorPayment);
    end;

    local procedure GetPmtDataFromFirstDoc(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var SATPostalCode: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(DetailedCustLedgEntry."Customer No.");
        SATPostalCode := Customer."Post Code";
    end;

    local procedure GetPmtCustDtldEntry(var DetailedCustLedgEntryPmt: Record "Detailed Cust. Ledg. Entry"; EntryNo: Integer)
    begin
        DetailedCustLedgEntryPmt.SetFilter(
            "Entry Type", '%1|%2|%3|%4',
            DetailedCustLedgEntryPmt."Entry Type"::Application,
            DetailedCustLedgEntryPmt."Entry Type"::"Realized Gain",
            DetailedCustLedgEntryPmt."Entry Type"::"Realized Loss",
            DetailedCustLedgEntryPmt."Entry Type"::"Correction of Remaining Amount");
        DetailedCustLedgEntryPmt.SetRange("Cust. Ledger Entry No.", EntryNo);
        DetailedCustLedgEntryPmt.SetRange("Initial Document Type", DetailedCustLedgEntryPmt."Initial Document Type"::Payment);
        if DetailedCustLedgEntryPmt.FindFirst() then;
    end;

    local procedure GetRelatedDocumentTableID(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; EntrySourceCode: Code[10]): Integer;
    var
        ServiceDoc: Boolean;
        InvoiceDoc: Boolean;
    begin
        SourceCodeSetup.Get();
        if (SourceCodeSetup."Service Management" <> '') and (EntrySourceCode = SourceCodeSetup."Service Management") then
            ServiceDoc := true;

        if DetailedCustLedgEntry."Initial Document Type" = DetailedCustLedgEntry."Initial Document Type"::Invoice then
            InvoiceDoc := true
        else
            if DetailedCustLedgEntry."Initial Document Type" = DetailedCustLedgEntry."Initial Document Type"::Payment then
                if DetailedCustLedgEntry."Document Type" = DetailedCustLedgEntry."Document Type"::Invoice then
                    InvoiceDoc := true;

        if ServiceDoc then begin
            if InvoiceDoc then
                exit(DATABASE::"Service Invoice Header");
            exit(DATABASE::"Service Cr.Memo Header");
        end;

        if InvoiceDoc then
            exit(DATABASE::"Sales Invoice Header");
        exit(DATABASE::"Sales Cr.Memo Header");
    end;

    local procedure GetRelatedDocumentData(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DocumentNo: Code[20]; EntrySourceCode: Code[10]; var TempVATAmountLine: Record "VAT Amount Line" temporary; var FiscalInvoiceNumberPAC: Text[50]; var DocAmountInclVAT: Decimal; var SubjectToTax: Text);
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempDocumentLine: Record "Document Line" temporary;
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        DetailedCustLedgEntryDoc: Record "Detailed Cust. Ledg. Entry";
        TableId: Integer;
    begin
        TableId := GetRelatedDocumentTableID(DetailedCustLedgEntry, EntrySourceCode);
        TempVATAmountLine.DeleteAll();

        DetailedCustLedgEntryDoc.SetRange("Cust. Ledger Entry No.", DetailedCustLedgEntry."Cust. Ledger Entry No.");
        DetailedCustLedgEntryDoc.SetFilter("Document Type", '<>%1', DetailedCustLedgEntry."Document Type"::Payment);
        DetailedCustLedgEntryDoc.CalcSums(Amount);
        DocAmountInclVAT := DetailedCustLedgEntryDoc.Amount;

        case TableId of
            DATABASE::"Sales Invoice Header":
                begin
                    SalesInvoiceHeader.Get(DocumentNo);
                    FilterSalesInvoiceLines(SalesInvoiceLine, SalesInvoiceHeader."No.");
                    SalesInvoiceLine.SetRange("Retention Attached to Line No.", 0);
                    SalesInvoiceLine.FindSet();
                    repeat
                        TempDocumentLine.TransferFields(SalesInvoiceLine);
                        InsertTempVATAmountLine(TempVATAmountLine, TempDocumentLine);
                    until SalesInvoiceLine.Next() = 0;
                    FiscalInvoiceNumberPAC := SalesInvoiceHeader."Fiscal Invoice Number PAC";
                    SubjectToTax := GetSubjectToTaxFromDocument(DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.");
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoHeader.Get(DocumentNo);
                    FilterSalesCrMemoLines(SalesCrMemoLine, SalesCrMemoHeader."No.");
                    SalesCrMemoLine.SetRange("Retention Attached to Line No.", 0);
                    SalesCrMemoLine.FindSet();
                    repeat
                        TempDocumentLine.TransferFields(SalesCrMemoLine);
                        InsertTempVATAmountLine(TempVATAmountLine, TempDocumentLine);
                    until SalesCrMemoLine.Next() = 0;
                    FiscalInvoiceNumberPAC := SalesCrMemoHeader."Fiscal Invoice Number PAC";
                    SubjectToTax := GetSubjectToTaxFromDocument(DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.");
                end;
            DATABASE::"Service Invoice Header":
                begin
                    ServiceInvoiceHeader.Get(DocumentNo);
                    FilterServiceInvoiceLines(ServiceInvoiceLine, ServiceInvoiceHeader."No.");
                    ServiceInvoiceLine.FindSet();
                    repeat
                        TempDocumentLine.TransferFields(ServiceInvoiceLine);
                        InsertTempVATAmountLine(TempVATAmountLine, TempDocumentLine);
                    until ServiceInvoiceLine.Next() = 0;
                    FiscalInvoiceNumberPAC := ServiceInvoiceHeader."Fiscal Invoice Number PAC";
                    SubjectToTax := GetSubjectToTaxFromDocument(DATABASE::"Service Invoice Header", ServiceInvoiceHeader."No.");
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    ServiceCrMemoHeader.Get(DocumentNo);
                    FilterServiceCrMemoLines(ServiceCrMemoLine, ServiceCrMemoHeader."No.");
                    ServiceCrMemoLine.FindSet();
                    repeat
                        TempDocumentLine.TransferFields(ServiceCrMemoLine);
                        InsertTempVATAmountLine(TempVATAmountLine, TempDocumentLine);
                    until ServiceCrMemoLine.Next() = 0;
                    FiscalInvoiceNumberPAC := ServiceCrMemoHeader."Fiscal Invoice Number PAC";
                    SubjectToTax := GetSubjectToTaxFromDocument(DATABASE::"Service Cr.Memo Header", ServiceCrMemoHeader."No.");
                end;
        end;

        if TempVATAmountLine.FindSet() then
            repeat
                TempVATAmountLine."Amount Including VAT" := Round(TempDocumentLine."Amount Including VAT", 0.01);
                TempVATAmountLine."VAT Amount" := Round(TempDocumentLine."Amount Including VAT" - TempDocumentLine.Amount, 0.01);
                TempVATAmountLine."VAT Base" := Round(TempDocumentLine.Amount, 0.01);
            until TempVATAmountLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetUUIDFromOriginalPrepayment(SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesInvoiceNumber: Code[20]): Text[50]
    var
        SalesInvoiceHeader2: Record "Sales Invoice Header";
    begin
        // First, get the common sales order number
        SalesInvoiceNumber := '';
        if SalesInvoiceHeader."Order No." = '' then
            exit('');

        SalesInvoiceHeader2.Reset();
        SalesInvoiceHeader2.SetFilter("Prepayment Order No.", '=%1', SalesInvoiceHeader."Order No.");
        if SalesInvoiceHeader2.FindFirst() then begin // We have the prepayment invoice
            SalesInvoiceNumber := SalesInvoiceHeader2."No.";
            exit(SalesInvoiceHeader2."Fiscal Invoice Number PAC");
        end;
        exit('');
    end;

    local procedure GetRelationDocumentsInvoice(var CFDIRelationDocument: Record "CFDI Relation Document"; DocumentHeader: Record "Document Header"; DocumentTableID: Integer)
    var
        CFDIRelationDocumentFrom: Record "CFDI Relation Document";
    begin
        CFDIRelationDocumentFrom.SetRange("Document Table ID", DocumentTableID);
        CFDIRelationDocumentFrom.SetRange("Document Type", 0);
        CFDIRelationDocumentFrom.SetRange("Document No.", DocumentHeader."No.");
        CFDIRelationDocumentFrom.SetRange("Customer No.", DocumentHeader."Bill-to/Pay-To No.");

        if CFDIRelationDocumentFrom.FindSet() then
            repeat
                CFDIRelationDocument := CFDIRelationDocumentFrom;
                if CFDIRelationDocument."SAT Relation Type" = '' then
                    CFDIRelationDocument."SAT Relation Type" := DocumentHeader."CFDI Relation";
                CFDIRelationDocument.Insert();
            until CFDIRelationDocumentFrom.Next() = 0;
    end;

    local procedure GetRelationDocumentsCreditMemo(var CFDIRelationDocument: Record "CFDI Relation Document"; DocumentHeader: Record "Document Header"; DocumentNo: Code[20]; TableID: Integer)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        GetRelationDocumentsInvoice(CFDIRelationDocument, DocumentHeader, TableID);

        DetailedCustLedgEntry.SetCurrentKey("Document No.", "Document Type", "Posting Date");
        DetailedCustLedgEntry.SetRange("Document Type", DetailedCustLedgEntry."Document Type"::"Credit Memo");
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Initial Entry");
        DetailedCustLedgEntry.FindFirst();
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Applied Cust. Ledger Entry No.", DetailedCustLedgEntry."Cust. Ledger Entry No.");
        DetailedCustLedgEntry.SetRange("Initial Document Type", DetailedCustLedgEntry."Initial Document Type"::Invoice);
        DetailedCustLedgEntry.SetRange(Unapplied, false);
        if DetailedCustLedgEntry.FindSet() then
            repeat
                CustLedgerEntry.Get(DetailedCustLedgEntry."Cust. Ledger Entry No.");
                case TableID of
                    DATABASE::"Sales Cr.Memo Header":
                        if SalesInvoiceHeader.Get(CustLedgerEntry."Document No.") then
                            InsertAppliedRelationDocument(
                              CFDIRelationDocument, DocumentNo, SalesInvoiceHeader."No.", SalesInvoiceHeader."CFDI Relation", SalesInvoiceHeader."Fiscal Invoice Number PAC");
                    DATABASE::"Service Cr.Memo Header":
                        if ServiceInvoiceHeader.Get(CustLedgerEntry."Document No.") then
                            InsertAppliedRelationDocument(
                              CFDIRelationDocument, DocumentNo, ServiceInvoiceHeader."No.", ServiceInvoiceHeader."CFDI Relation", ServiceInvoiceHeader."Fiscal Invoice Number PAC");
                end;
            until DetailedCustLedgEntry.Next() = 0;
    end;

    local procedure InsertAppliedRelationDocument(var CFDIRelationDocument: Record "CFDI Relation Document"; DocumentNo: Code[20]; RelatedDocumentNo: Code[20]; RelationType: Code[10]; FiscalInvoiceNumberPAC: Text[50])
    begin
        CFDIRelationDocument.SetRange("Fiscal Invoice Number PAC", FiscalInvoiceNumberPAC);
        if not CFDIRelationDocument.FindFirst() then begin
            CFDIRelationDocument.Init();
            CFDIRelationDocument."Document No." := DocumentNo;
            CFDIRelationDocument."Related Doc. Type" := CFDIRelationDocument."Related Doc. Type"::Invoice;
            CFDIRelationDocument."Related Doc. No." := RelatedDocumentNo;
            CFDIRelationDocument."SAT Relation Type" := RelationType;
            CFDIRelationDocument."Fiscal Invoice Number PAC" := FiscalInvoiceNumberPAC;
            CFDIRelationDocument.Insert();
        end;
        CFDIRelationDocument.SetRange("Fiscal Invoice Number PAC");
    end;

    local procedure AddElementPago(var XMLNode: DotNet XmlNode; NodeName: Text; NodeText: Text; NameSpace: Text; var CreatedXMLNode: DotNet XmlNode): Boolean
    var
        NewChildNode: DotNet XmlNode;
    begin
        NodeName := 'pago20:' + NodeName;
        NewChildNode := XMLNode.OwnerDocument.CreateNode('element', NodeName, NameSpace);
        if IsNull(NewChildNode) then
            exit(false);

        if NodeText <> '' then
            NewChildNode.Value := RemoveInvalidChars(NodeText);
        XMLNode.AppendChild(NewChildNode);
        CreatedXMLNode := NewChildNode;
        exit(true);
    end;

    local procedure AddElementCartaPorte(var XMLNode: DotNet XmlNode; NodeName: Text; NodeText: Text; NameSpace: Text; var CreatedXMLNode: DotNet XmlNode): Boolean
    var
        NewChildNode: DotNet XmlNode;
    begin
        NodeName := 'cartaporte31:' + NodeName;
        NewChildNode := XMLNode.OwnerDocument.CreateNode('element', NodeName, NameSpace);
        if IsNull(NewChildNode) then
            exit(false);

        if NodeText <> '' then
            NewChildNode.Value := RemoveInvalidChars(NodeText);
        XMLNode.AppendChild(NewChildNode);
        CreatedXMLNode := NewChildNode;
        exit(true);
    end;

    local procedure AddElementCCE(var XMLNode: DotNet XmlNode; NodeName: Text; NodeText: Text; NameSpace: Text; var CreatedXMLNode: DotNet XmlNode): Boolean
    var
        NewChildNode: DotNet XmlNode;
    begin
        NodeName := 'cce20:' + NodeName;
        NewChildNode := XMLNode.OwnerDocument.CreateNode('element', NodeName, NameSpace);
        if IsNull(NewChildNode) then
            exit(false);

        if NodeText <> '' then
            NewChildNode.Value := RemoveInvalidChars(NodeText);
        XMLNode.AppendChild(NewChildNode);
        CreatedXMLNode := NewChildNode;
        exit(true);
    end;

    local procedure AddNodeCompanyInfo(var XMLDoc: DotNet XmlDocument; var XMLCurrNode: DotNet XmlNode)
    var
        XMLNewChild: DotNet XmlNode;
    begin
        // Emisor
        AddElementCFDI(XMLCurrNode, 'Emisor', '', CFDINamespaceTxt, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddAttribute(XMLDoc, XMLCurrNode, 'Rfc', CompanyInfo."RFC Number");
        AddAttribute(XMLDoc, XMLCurrNode, 'Nombre', RemoveInvalidChars(CompanyInfo.Name));
        AddAttribute(XMLDoc, XMLCurrNode, 'RegimenFiscal', CompanyInfo."SAT Tax Regime Classification");
        XMLCurrNode := XMLCurrNode.ParentNode;
    end;

    local procedure AddStrCompanyInfo(var OutStr: OutStream)
    begin
        WriteOutStr(OutStr, CompanyInfo."RFC Number" + '|'); // Rfc
        WriteOutStr(OutStr, RemoveInvalidChars(CompanyInfo.Name) + '|'); // Nombre
        WriteOutStr(OutStr, CompanyInfo."SAT Tax Regime Classification" + '|'); // RegimenFiscal
    end;

    local procedure AddNodeReceptor(var XMLDoc: DotNet XmlDocument; var XMLCurrNode: DotNet XmlNode; Customer: Record Customer; ReceptorName: Text[300]; SATPostalCode: Code[20]; UsoCFDI: Code[10])
    var
        SATUtilities: Codeunit "SAT Utilities";
        XMLNewChild: DotNet XmlNode;
    begin
        AddElementCFDI(XMLCurrNode, 'Receptor', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddAttribute(XMLDoc, XMLCurrNode, 'Rfc', Customer."RFC No.");
        AddAttribute(XMLDoc, XMLCurrNode, 'Nombre', RemoveInvalidChars(ReceptorName));
        AddAttribute(XMLDoc, XMLCurrNode, 'DomicilioFiscalReceptor', SATPostalCode);
        if SATUtilities.GetSATCountryCode(Customer."Country/Region Code") <> 'MEX' then begin
            AddAttribute(XMLDoc, XMLCurrNode, 'ResidenciaFiscal', SATUtilities.GetSATCountryCode(Customer."Country/Region Code"));
            AddAttribute(XMLDoc, XMLCurrNode, 'NumRegIdTrib', Customer."VAT Registration No.");
        end;
        AddAttribute(XMLDoc, XMLCurrNode, 'RegimenFiscalReceptor', Customer."SAT Tax Regime Classification");
        AddAttribute(XMLDoc, XMLCurrNode, 'UsoCFDI', UsoCFDI);
        XMLCurrNode := XMLCurrNode.ParentNode;
    end;

    local procedure AddStrReceptor(var OutStr: OutStream; Customer: Record Customer; ReceptorName: Text[300]; SATPostalCode: Code[20]; UsoCFDI: Code[10])
    var
        SATUtilities: Codeunit "SAT Utilities";
    begin
        WriteOutStr(OutStr, Customer."RFC No." + '|'); // Rfc
        WriteOutStr(OutStr, RemoveInvalidChars(ReceptorName) + '|'); // Nombre
        WriteOutStr(OutStr, SATPostalCode + '|'); // DomicilioFiscalReceptor
        if SATUtilities.GetSATCountryCode(Customer."Country/Region Code") <> 'MEX' then begin
            WriteOutStr(OutStr, SATUtilities.GetSATCountryCode(Customer."Country/Region Code") + '|'); // ResidenciaFiscal
            WriteOutStr(OutStr, RemoveInvalidChars(Customer."VAT Registration No.") + '|'); // NumRegIDTrib
        end;
        WriteOutStr(OutStr, Customer."SAT Tax Regime Classification" + '|'); // RegimenFiscalReceptor
        WriteOutStr(OutStr, UsoCFDI + '|'); // UsoCFDI
    end;

    local procedure AddNodeRelacionado(var XMLDoc: DotNet XmlDocument; var XMLCurrNode: DotNet XmlNode; var XMLNewChild: DotNet XmlNode; var TempCFDIRelationDocument: Record "CFDI Relation Document" temporary)
    var
        SATRelationshipType: Record "SAT Relationship Type";
    begin
        if TempCFDIRelationDocument.IsEmpty() then
            exit;

        if SATRelationshipType.FindSet() then
            repeat
                TempCFDIRelationDocument.SetRange("SAT Relation Type", SATRelationshipType."SAT Relationship Type");

                if TempCFDIRelationDocument.FindSet() then begin
                    AddElementCFDI(XMLCurrNode, 'CfdiRelacionados', '', DocNameSpace, XMLNewChild);
                    XMLCurrNode := XMLNewChild;
                    AddAttribute(XMLDoc, XMLCurrNode, 'TipoRelacion', SATRelationshipType."SAT Relationship Type");

                    repeat
                        AddElementCFDI(XMLCurrNode, 'CfdiRelacionado', '', DocNameSpace, XMLNewChild);
                        XMLCurrNode := XMLNewChild;
                        AddAttribute(XMLDoc, XMLCurrNode, 'UUID', TempCFDIRelationDocument."Fiscal Invoice Number PAC");
                        XMLCurrNode := XMLCurrNode.ParentNode;
                    until TempCFDIRelationDocument.Next() = 0;

                    XMLCurrNode := XMLCurrNode.ParentNode;
                end;
            until SATRelationshipType.Next() = 0;

        TempCFDIRelationDocument.SetRange("SAT Relation Type");
    end;

    local procedure AddStrRelacionado(var TempCFDIRelationDocument: Record "CFDI Relation Document" temporary; var OutStr: OutStream)
    var
        SATRelationshipType: Record "SAT Relationship Type";
    begin
        if TempCFDIRelationDocument.IsEmpty() then
            exit;

        if SATRelationshipType.FindSet() then
            repeat
                TempCFDIRelationDocument.SetRange("SAT Relation Type", SATRelationshipType."SAT Relationship Type");

                if TempCFDIRelationDocument.FindSet() then begin
                    WriteOutStr(OutStr, RemoveInvalidChars(SATRelationshipType."SAT Relationship Type") + '|');
                    repeat
                        WriteOutStr(OutStr, RemoveInvalidChars(TempCFDIRelationDocument."Fiscal Invoice Number PAC") + '|');
                    until TempCFDIRelationDocument.Next() = 0;
                end;
            until SATRelationshipType.Next() = 0;

        TempCFDIRelationDocument.SetRange("SAT Relation Type");
    end;

    local procedure AddNodeImpuestoPerLine(TempDocumentLine: Record "Document Line" temporary; var TempDocumentLineRetention: Record "Document Line" temporary; var XMLDoc: DotNet XmlDocument; XMLCurrNode: DotNet XmlNode; XMLNewChild: DotNet XmlNode)
    begin
        if GetSubjectToTaxCode(TempDocumentLine) <> '02' then
            exit;
        if IsNonTaxableVATLine(TempDocumentLine) then
            exit;

        // Impuestos->Traslados/Retenciones
        AddElementCFDI(XMLCurrNode, 'Impuestos', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;

        AddElementCFDI(XMLCurrNode, 'Traslados', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddElementCFDI(XMLCurrNode, 'Traslado', '', DocNameSpace, XMLNewChild);
        AddNodeTrasladoRetentionPerLine(
            XMLDoc, XMLCurrNode, XMLNewChild,
            TempDocumentLine.Amount, TempDocumentLine."VAT %", TempDocumentLine."Amount Including VAT" - TempDocumentLine.Amount,
            IsVATExemptLine(TempDocumentLine));
        XMLCurrNode := XMLCurrNode.ParentNode; // Traslados

        TempDocumentLineRetention.SetRange("Retention Attached to Line No.", TempDocumentLine."Line No.");
        if TempDocumentLineRetention.FindSet() then begin
            AddElementCFDI(XMLCurrNode, 'Retenciones', '', DocNameSpace, XMLNewChild);
            XMLCurrNode := XMLNewChild;
            repeat
                AddElementCFDI(XMLCurrNode, 'Retencion', '', DocNameSpace, XMLNewChild);
                AddNodeTrasladoRetentionPerLine(
                    XMLDoc, XMLCurrNode, XMLNewChild,
                    TempDocumentLine.Amount, TempDocumentLineRetention."Retention VAT %",
                    TempDocumentLineRetention."Unit Price/Direct Unit Cost" * TempDocumentLineRetention.Quantity,
                    IsVATExemptLine(TempDocumentLineRetention));
            until TempDocumentLineRetention.Next() = 0;
            XMLCurrNode := XMLCurrNode.ParentNode; // Retenciones
        end;

        XMLCurrNode := XMLCurrNode.ParentNode; // Impuestos
    end;

    local procedure AddNodeTrasladoRetentionPerLine(XMLDoc: DotNet XmlDocument; XMLCurrNode: DotNet XmlNode; XMLNewChild: DotNet XmlNode; BaseAmount: Decimal; VATPct: Decimal; VATAmount: Decimal; IsVATExempt: Boolean)
    begin
        XMLCurrNode := XMLNewChild;

        AddAttribute(XMLDoc, XMLCurrNode, 'Base', FormatDecimal(BaseAmount, 6));
        AddAttribute(XMLDoc, XMLCurrNode, 'Impuesto', GetTaxCode(VATPct, VATAmount)); // Used to be IVA
        if not IsVATExempt then begin // When Sales Tax code is % then Tasa, else Exento
            AddAttribute(XMLDoc, XMLCurrNode, 'TipoFactor', 'Tasa');
            AddAttribute(XMLDoc, XMLCurrNode, 'TasaOCuota', PadStr(FormatDecimal(VATPct / 100, 6), 8, '0'));
            AddAttribute(XMLDoc, XMLCurrNode, 'Importe', FormatDecimal(VATAmount, 6))
        end else
            AddAttribute(XMLDoc, XMLCurrNode, 'TipoFactor', 'Exento');

        XMLCurrNode := XMLCurrNode.ParentNode;
    end;

    local procedure AddStrImpuestoPerLine(TempDocumentLine: Record "Document Line" temporary; var TempDocumentLineRetention: Record "Document Line" temporary; var OutStr: OutStream)
    begin
        if GetSubjectToTaxCode(TempDocumentLine) <> '02' then
            exit;
        if IsNonTaxableVATLine(TempDocumentLine) then
            exit;

        AddStrTrasladoRetentionPerLine(
          OutStr,
          TempDocumentLine.Amount, TempDocumentLine."VAT %", TempDocumentLine."Amount Including VAT" - TempDocumentLine.Amount,
          IsVATExemptLine(TempDocumentLine));

        TempDocumentLineRetention.SetRange("Retention Attached to Line No.", TempDocumentLine."Line No.");
        if TempDocumentLineRetention.FindSet() then
            repeat
                AddStrTrasladoRetentionPerLine(
                  OutStr,
                  TempDocumentLine.Amount, TempDocumentLineRetention."Retention VAT %",
                  TempDocumentLineRetention."Unit Price/Direct Unit Cost" * TempDocumentLineRetention.Quantity,
                  IsVATExemptLine(TempDocumentLineRetention));
            until TempDocumentLineRetention.Next() = 0;
    end;

    local procedure AddStrTrasladoRetentionPerLine(var OutStr: OutStream; BaseAmount: Decimal; VATPct: Decimal; VATAmount: Decimal; IsVATExempt: Boolean)
    begin
        WriteOutStr(OutStr, FormatDecimal(BaseAmount, 6) + '|'); // Base
        WriteOutStr(OutStr, GetTaxCode(VATPct, VATAmount) + '|'); // Impuesto
        if not IsVATExempt then begin // When Sales Tax code is % then Tasa, else Exento
            WriteOutStr(OutStr, 'Tasa' + '|'); // TipoFactor
            WriteOutStr(OutStr, PadStr(FormatDecimal(VATPct / 100, 6), 8, '0') + '|'); // TasaOCuota
            WriteOutStr(OutStr, FormatDecimal(VATAmount, 6) + '|') // Importe
        end else
            WriteOutStr(OutStr, 'Exento' + '|'); // TipoFactor
    end;

    local procedure AddNodeComercioExterior(var TempDocumentLineCCE: Record "Document Line" temporary; DocumentHeader: Record "Document Header"; var XMLDoc: DotNet XmlDocument; XMLCurrNode: DotNet XmlNode; XMLNewChild: DotNet XmlNode)
    var
        Customer: Record Customer;
        Location: Record Location;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        SATUtilities: Codeunit "SAT Utilities";
        CurrencyFactor: Decimal;
        LineCount: Integer;
        LineNo: Integer;
        SumAmountUSD: Decimal;
    begin
        if not DocumentHeader."Foreign Trade" then
            exit;

        GetCustomer(Customer, DocumentHeader."Bill-to/Pay-To No.", false);

        // ComercioExterior
        AddElementCCE(XMLCurrNode, 'ComercioExterior', '', CFDIComercioExteriorNamespaceTxt, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddAttribute(XMLDoc, XMLCurrNode, 'Version', '2.0');
        if IsTransferDocument(DocumentHeader."Document Table ID") then
            AddAttribute(XMLDoc, XMLCurrNode, 'MotivoTraslado', DocumentHeader."SAT Transfer Reason");
        AddAttribute(XMLDoc, XMLCurrNode, 'ClaveDePedimento', 'A1');

        if DocumentHeader."CFDI Certificate of Origin No." <> '' then begin
            AddAttribute(XMLDoc, XMLCurrNode, 'CertificadoOrigen', '1');
            AddAttribute(XMLDoc, XMLCurrNode, 'NumCertificadoOrigen', DelChr(DocumentHeader."CFDI Certificate of Origin No.", '<>'));
        end else
            AddAttribute(XMLDoc, XMLCurrNode, 'CertificadoOrigen', '0');

        AddAttribute(XMLDoc, XMLCurrNode, 'Incoterm', DocumentHeader."SAT International Trade Term");

        CurrencyFactor :=
          Round(1 / DocumentHeader."Currency Factor", 0.000001) / DocumentHeader."Exchange Rate USD";
        AddAttribute(XMLDoc, XMLCurrNode, 'TipoCambioUSD', FormatDecimal(DocumentHeader."Exchange Rate USD", 6));
        AddAttribute(XMLDoc, XMLCurrNode, 'TotalUSD', FormatDecimal(DocumentHeader.Amount * CurrencyFactor, 2));

        AddElementCCE(XMLCurrNode, 'Emisor', '', CFDIComercioExteriorNamespaceTxt, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddElementCCE(XMLCurrNode, 'Domicilio', '', CFDIComercioExteriorNamespaceTxt, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        Location.Get(DocumentHeader."Location Code");
        AddNodeDomicilio(Location."SAT Address ID", Location.Address, XMLDoc, XMLCurrNode);
        XMLCurrNode := XMLCurrNode.ParentNode; // Domicilio
        XMLCurrNode := XMLCurrNode.ParentNode; // Emisor

        AddElementCCE(XMLCurrNode, 'Receptor', '', CFDIComercioExteriorNamespaceTxt, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        if (SATUtilities.GetSATCountryCode(Customer."Country/Region Code") <> 'MEX') and (Customer."RFC No." = GetForeignRFCNo()) then
            AddAttribute(XMLDoc, XMLCurrNode, 'NumRegIdTrib', Customer."VAT Registration No.");
        AddElementCCE(XMLCurrNode, 'Domicilio', '', CFDIComercioExteriorNamespaceTxt, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddNodeDomicilio(DocumentHeader."SAT Address ID", DocumentHeader."Bill-to/Pay-To Address", XMLDoc, XMLCurrNode);
        XMLCurrNode := XMLCurrNode.ParentNode; // Domicilio
        XMLCurrNode := XMLCurrNode.ParentNode; // Receptor

        // Mercancias
        AddElementCCE(XMLCurrNode, 'Mercancias', '', CFDIComercioExteriorNamespaceTxt, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        LineCount := TempDocumentLineCCE.Count();
        TempDocumentLineCCE.FindSet();
        repeat
            LineNo += 1;
            AddElementCCE(XMLCurrNode, 'Mercancia', '', CFDIComercioExteriorNamespaceTxt, XMLNewChild);
            XMLCurrNode := XMLNewChild;
            AddAttribute(XMLDoc, XMLCurrNode, 'NoIdentificacion', TempDocumentLineCCE."No.");
            if not IsTransferDocument(DocumentHeader."Document Table ID") then
                if Item.Get(TempDocumentLineCCE."No.") and (Item."Tariff No." <> '') then
                    AddAttribute(XMLDoc, XMLCurrNode, 'FraccionArancelaria', DelChr(Item."Tariff No."));
            AddAttribute(XMLDoc, XMLCurrNode, 'CantidadAduana', Format(TempDocumentLineCCE.Quantity, 0, 9));
            UnitOfMeasure.Get(TempDocumentLineCCE."Unit of Measure Code");
            AddAttribute(XMLDoc, XMLCurrNode, 'UnidadAduana', UnitOfMeasure."SAT Customs Unit");
            AddAttribute(
              XMLDoc, XMLCurrNode, 'ValorUnitarioAduana',
              FormatDecimal(Round(TempDocumentLineCCE.Amount / TempDocumentLineCCE.Quantity * CurrencyFactor, 0.000001, '<'), 6));
            if LineNo <> LineCount then begin
                AddAttribute(
                  XMLDoc, XMLCurrNode, 'ValorDolares',
                  FormatDecimal(Round(TempDocumentLineCCE.Amount * CurrencyFactor, 0.0001), 4));
                SumAmountUSD += Round(TempDocumentLineCCE.Amount * CurrencyFactor, 0.0001);
            end else
                AddAttribute(
                  XMLDoc, XMLCurrNode, 'ValorDolares',
                  FormatDecimal(Round(DocumentHeader.Amount * CurrencyFactor, 0.0001) - SumAmountUSD, 4));
            XMLCurrNode := XMLCurrNode.ParentNode; // Mercancia
        until TempDocumentLineCCE.Next() = 0;
        XMLCurrNode := XMLCurrNode.ParentNode; // Mercancias

        XMLCurrNode := XMLCurrNode.ParentNode; // ComercioExterior
    end;

    local procedure AddStrComercioExterior(var TempDocumentLineCCE: Record "Document Line" temporary; DocumentHeader: Record "Document Header"; var OutStr: OutStream)
    var
        Customer: Record Customer;
        Location: Record Location;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        SATUtilities: Codeunit "SAT Utilities";
        CurrencyFactor: Decimal;
        LineCount: Integer;
        LineNo: Integer;
        SumAmountUSD: Decimal;
    begin
        if not DocumentHeader."Foreign Trade" then
            exit;

        GetCustomer(Customer, DocumentHeader."Bill-to/Pay-To No.", false);
        // ComercioExterior
        WriteOutStr(OutStr, '2.0|'); // Version
        if IsTransferDocument(DocumentHeader."Document Table ID") then
            WriteOutStr(OutStr, DocumentHeader."SAT Transfer Reason" + '|'); // MotivoTraslado
        //WriteOutStr(OutStr, '2|'); // TipoOperacion
        WriteOutStr(OutStr, 'A1|'); // ClaveDePedimento
        WriteOutStr(OutStr, '0|'); // CertificadoOrigen
        WriteOutStr(OutStr, DocumentHeader."SAT International Trade Term" + '|'); // Incoterm
        //WriteOutStr(OutStr, '0|'); // Subdivision

        CurrencyFactor :=
          Round(1 / DocumentHeader."Currency Factor", 0.000001) / DocumentHeader."Exchange Rate USD";
        WriteOutStr(OutStr, FormatDecimal(DocumentHeader."Exchange Rate USD", 6) + '|'); // TipoCambioUSD
        WriteOutStr(OutStr, FormatDecimal(DocumentHeader.Amount * CurrencyFactor, 2) + '|'); // TotalUSD

        // Emisor/Domicilio
        Location.Get(DocumentHeader."Location Code");
        AddStrDomicilio(Location."SAT Address ID", Location.Address, OutStr);

        // Receptor/Domicilio
        if (SATUtilities.GetSATCountryCode(Customer."Country/Region Code") <> 'MEX') and (Customer."RFC No." = GetForeignRFCNo()) then
            WriteOutStr(OutStr, Customer."VAT Registration No." + '|'); // NumRegIdTrib
        AddStrDomicilio(DocumentHeader."SAT Address ID", DocumentHeader."Bill-to/Pay-To Address", OutStr);

        // Mercancias
        LineCount := TempDocumentLineCCE.Count();
        TempDocumentLineCCE.FindSet();
        repeat
            LineNo += 1;
            WriteOutStr(OutStr, TempDocumentLineCCE."No." + '|'); // NoIdentificacion
            if not IsTransferDocument(DocumentHeader."Document Table ID") then
                if Item.Get(TempDocumentLineCCE."No.") and (Item."Tariff No." <> '') then
                    WriteOutStr(OutStr, DelChr(Item."Tariff No.") + '|'); // FraccionArancelaria
            WriteOutStr(OutStr, Format(TempDocumentLineCCE.Quantity, 0, 9) + '|'); // CantidadAduana
            UnitOfMeasure.Get(TempDocumentLineCCE."Unit of Measure Code");
            WriteOutStr(OutStr, UnitOfMeasure."SAT Customs Unit" + '|'); // UnidadAduana
            WriteOutStr(OutStr,
              FormatDecimal(
                Round(TempDocumentLineCCE.Amount / TempDocumentLineCCE.Quantity * CurrencyFactor, 0.000001, '<'), 6) + '|'); // ValorUnitarioAduana
            if LineNo <> LineCount then begin
                WriteOutStr(OutStr,
                  FormatDecimal(Round(TempDocumentLineCCE.Amount * CurrencyFactor, 0.0001), 4) + '|'); // ValorDolares
                SumAmountUSD += Round(TempDocumentLineCCE.Amount * CurrencyFactor, 0.0001);
            end else
                WriteOutStr(OutStr,
                    FormatDecimal(Round(DocumentHeader.Amount * CurrencyFactor, 0.0001) - SumAmountUSD, 4) + '|'); // ValorDolares
        until TempDocumentLineCCE.Next() = 0;
    end;

    local procedure AddNodeCartaPorteUbicacion(TipoUbicacion: Text; Location: Record Location; LocationPrefix: Text[2]; RFCNo: Text; ForeignRegId: Text; ResidenciaFiscal: Text; FechaHoraSalidaLlegada: Text; DistanciaRecorrida: Text; var XMLDoc: DotNet XmlDocument; XMLCurrNode: DotNet XmlNode; XMLNewChild: DotNet XmlNode)
    begin
        AddElementCartaPorte(XMLCurrNode, 'Ubicacion', '', CartaPorteNamespaceTxt, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddAttribute(XMLDoc, XMLCurrNode, 'TipoUbicacion', TipoUbicacion);
        if Location."ID Ubicacion" <> 0 then
            AddAttribute(XMLDoc, XMLCurrNode, 'IDUbicacion', LocationPrefix + Format(Location."ID Ubicacion"));
        AddAttribute(XMLDoc, XMLCurrNode, 'RFCRemitenteDestinatario', RFCNo);
        if ForeignRegId <> '' then begin
            AddAttribute(XMLDoc, XMLCurrNode, 'NumRegIdTrib', ForeignRegId);
            AddAttribute(XMLDoc, XMLCurrNode, 'ResidenciaFiscal', ResidenciaFiscal);
        end;
        AddAttribute(XMLDoc, XMLCurrNode, 'FechaHoraSalidaLlegada', FechaHoraSalidaLlegada);
        if DistanciaRecorrida <> '' then
            AddAttribute(XMLDoc, XMLCurrNode, 'DistanciaRecorrida', DistanciaRecorrida);

        AddElementCartaPorte(XMLCurrNode, 'Domicilio', '', CartaPorteNamespaceTxt, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddNodeDomicilio(Location."SAT Address ID", Location.Address, XMLDoc, XMLCurrNode);
        XMLCurrNode := XMLCurrNode.ParentNode; // Domicilio

        XMLCurrNode := XMLCurrNode.ParentNode; // Ubicacion
    end;

    local procedure AddStrCartaPorteUbicacion(TipoUbicacion: Text; Location: Record Location; LocationPrefix: Text[2]; RFCNo: Text; ForeignRegId: Text; ResidenciaFiscal: Text; FechaHoraSalidaLlegada: Text; DistanciaRecorrida: Text; var OutStr: OutStream)
    begin
        WriteOutStr(OutStr, TipoUbicacion + '|'); // TipoUbicacion
        if Location."ID Ubicacion" <> 0 then
            WriteOutStr(OutStr, LocationPrefix + Format(Location."ID Ubicacion") + '|'); // IDUbicacion
        WriteOutStr(OutStr, RFCNo + '|'); // RFCRemitenteDestinatario
        if ForeignRegId <> '' then begin
            WriteOutStr(OutStr, ForeignRegId + '|'); // NumRegIdTrib
            WriteOutStr(OutStr, ResidenciaFiscal + '|'); // ResidenciaFiscal 
        end;
        WriteOutStr(OutStr, FechaHoraSalidaLlegada + '|'); // FechaHoraSalidaLlegada
        if DistanciaRecorrida <> '' then
            WriteOutStr(OutStr, DistanciaRecorrida + '|'); // DistanciaRecorrida

        AddStrDomicilio(Location."SAT Address ID", Location.Address, OutStr);
    end;

    local procedure AddNodeDomicilio(SATAddressID: Integer; Address: Text[100]; var XMLDoc: DotNet XmlDocument; XMLCurrNode: DotNet XmlNode)
    var
        SATAddress: Record "SAT Address";
        SATSuburb: Record "SAT Suburb";
        SATUtilities: Codeunit "SAT Utilities";
    begin
        SATAddress.Get(SATAddressID);
        SATSuburb.Get(SATAddress."SAT Suburb ID");
        if Address <> '' then
            AddAttribute(XMLDoc, XMLCurrNode, 'Calle', Address);
        AddAttribute(XMLDoc, XMLCurrNode, 'Colonia', SATSuburb."Suburb Code");
        if SATAddress."SAT Locality Code" <> '' then
            AddAttribute(XMLDoc, XMLCurrNode, 'Localidad', SATAddress."SAT Locality Code");
        if SATAddress."SAT Municipality Code" <> '' then
            AddAttribute(XMLDoc, XMLCurrNode, 'Municipio', SATAddress."SAT Municipality Code");
        AddAttribute(XMLDoc, XMLCurrNode, 'Estado', SATAddress."SAT State Code");
        AddAttribute(XMLDoc, XMLCurrNode, 'Pais', SATUtilities.GetSATCountryCode(SATAddress."Country/Region Code"));
        AddAttribute(XMLDoc, XMLCurrNode, 'CodigoPostal', SATSuburb."Postal Code");
    end;

    local procedure AddStrDomicilio(SATAddressID: Integer; Address: Text[100]; var OutStr: OutStream)
    var
        SATAddress: Record "SAT Address";
        SATSuburb: Record "SAT Suburb";
        SATUtilities: Codeunit "SAT Utilities";
    begin
        SATAddress.Get(SATAddressID);
        SATSuburb.Get(SATAddress."SAT Suburb ID");
        if Address <> '' then
            WriteOutStr(OutStr, Address + '|'); // Calle
        WriteOutStr(OutStr, SATSuburb."Suburb Code" + '|'); // Colonia
        if SATAddress."SAT Locality Code" <> '' then
            WriteOutStr(OutStr, SATAddress."SAT Locality Code" + '|'); // Localidad
        if SATAddress."SAT Municipality Code" <> '' then
            WriteOutStr(OutStr, SATAddress."SAT Municipality Code" + '|'); // Municipio
        WriteOutStr(OutStr, SATAddress."SAT State Code" + '|'); // Estado
        WriteOutStr(OutStr, SATUtilities.GetSATCountryCode(SATAddress."Country/Region Code") + '|'); // Pais
        WriteOutStr(OutStr, SATSuburb."Postal Code" + '|'); // CodigoPostal
    end;

    local procedure AddNodePagoImpuestosDR(var TempVATAmountLine: Record "VAT Amount Line" temporary; var XMLDoc: DotNet XmlDocument; XMLCurrNode: DotNet XmlNode;
                                                                                                                      XMLNewChild: DotNet XmlNode)
    begin
        if TempVATAmountLine.IsEmpty then
            exit;

        AddElementPago(XMLCurrNode, 'ImpuestosDR', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddElementPago(XMLCurrNode, 'TrasladosDR', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;

        if TempVATAmountLine.FindFirst() then
            repeat
                AddElementPago(XMLCurrNode, 'TrasladoDR', '', DocNameSpace, XMLNewChild);
                XMLCurrNode := XMLNewChild;
                if TempVATAmountLine."Tax Category" = GetTaxCategoryExempt() then begin
                    AddAttribute(XMLDoc, XMLCurrNode, 'BaseDR', FormatDecimal(TempVATAmountLine."VAT Base", 2));
                    AddAttribute(XMLDoc, XMLCurrNode, 'ImpuestoDR', GetTaxCode(TempVATAmountLine."VAT %", TempVATAmountLine."VAT Amount"));
                    AddAttribute(XMLDoc, XMLCurrNode, 'TipoFactorDR', 'Exento');
                end else begin
                    AddAttribute(XMLDoc, XMLCurrNode, 'BaseDR', FormatDecimal(TempVATAmountLine."VAT Base", 2));
                    AddAttribute(XMLDoc, XMLCurrNode, 'ImpuestoDR', GetTaxCode(TempVATAmountLine."VAT %", TempVATAmountLine."VAT Amount"));
                    AddAttribute(XMLDoc, XMLCurrNode, 'TipoFactorDR', 'Tasa');
                    AddAttribute(XMLDoc, XMLCurrNode, 'TasaOCuotaDR', PadStr(FormatAmount(TempVATAmountLine."VAT %" / 100), 8, '0'));
                    AddAttribute(XMLDoc, XMLCurrNode, 'ImporteDR', FormatDecimal(TempVATAmountLine."VAT Amount", 2));
                end;
                XMLCurrNode := XMLCurrNode.ParentNode;
            until TempVATAmountLine.Next() = 0;

        XMLCurrNode := XMLCurrNode.ParentNode;
        XMLCurrNode := XMLCurrNode.ParentNode;
    end;

    local procedure AddStrPagoImpuestosDR(var TempVATAmountLine: Record "VAT Amount Line" temporary; var OutStr: OutStream);
    begin
        if TempVATAmountLine.IsEmpty then
            exit;

        if TempVATAmountLine.FindSet() then
            repeat
                if TempVATAmountLine."Tax Category" = GetTaxCategoryExempt() then begin
                    WriteOutStr(OutStr, FormatDecimal(TempVATAmountLine."VAT Base", 2) + '|'); // BaseDR
                    WriteOutStr(OutStr, GetTaxCode(TempVATAmountLine."VAT %", TempVATAmountLine."VAT Amount") + '|'); // ImpuestoDR
                    WriteOutStr(OutStr, 'Exento' + '|'); // TipoFactorDR
                end else begin
                    WriteOutStr(OutStr, FormatDecimal(TempVATAmountLine."VAT Base", 2) + '|'); // BaseDR
                    WriteOutStr(OutStr, GetTaxCode(TempVATAmountLine."VAT %", TempVATAmountLine."VAT Amount") + '|'); // ImpuestoDR
                    WriteOutStr(OutStr, 'Tasa' + '|'); // TipoFactorDR
                    WriteOutStr(OutStr, PADSTR(FormatAmount(TempVATAmountLine."VAT %" / 100), 8, '0') + '|'); // TasaOCuota
                    WriteOutStr(OutStr, FormatDecimal(TempVATAmountLine."VAT Amount", 2) + '|'); // Importe
                end;
            until TempVATAmountLine.Next() = 0;
    end;

    local procedure AddNodePagoImpuestosP(var XMLDoc: DotNet XmlDocument; XMLCurrNode: DotNet XmlNode; XMLNewChild: DotNet XmlNode; var TempVATAmountLinePmt: Record "VAT Amount Line" temporary)
    begin
        if TempVATAmountLinePmt.IsEmpty() then
            exit;

        AddElementPago(XMLCurrNode, 'ImpuestosP', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddElementPago(XMLCurrNode, 'TrasladosP', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;

        if TempVATAmountLinePmt.FindSet() then
            repeat
                AddElementPago(XMLCurrNode, 'TrasladoP', '', DocNameSpace, XMLNewChild);
                XMLCurrNode := XMLNewChild;

                if TempVATAmountLinePmt."Tax Category" = GetTaxCategoryExempt() then begin
                    AddAttribute(XMLDoc, XMLCurrNode, 'BaseP', FormatDecimal(Round(TempVATAmountLinePmt."VAT Base", 0.000001, '<'), 6));
                    AddAttribute(XMLDoc, XMLCurrNode, 'ImpuestoP', GetTaxCode(TempVATAmountLinePmt."VAT %", TempVATAmountLinePmt."VAT Amount"));
                    AddAttribute(XMLDoc, XMLCurrNode, 'TipoFactorP', 'Exento');
                end else begin
                    AddAttribute(XMLDoc, XMLCurrNode, 'BaseP', FormatDecimal(Round(TempVATAmountLinePmt."VAT Base", 0.000001, '<'), 6));
                    AddAttribute(XMLDoc, XMLCurrNode, 'ImpuestoP', GetTaxCode(TempVATAmountLinePmt."VAT %", TempVATAmountLinePmt."VAT Amount"));
                    AddAttribute(XMLDoc, XMLCurrNode, 'TipoFactorP', 'Tasa');
                    AddAttribute(XMLDoc, XMLCurrNode, 'TasaOCuotaP', PadStr(FormatAmount(TempVATAmountLinePmt."VAT %" / 100), 8, '0'));
                    AddAttribute(
                      XMLDoc, XMLCurrNode, 'ImporteP', FormatDecimal(Round(TempVATAmountLinePmt."VAT Amount", 0.000001, '<'), 6));
                end;
                XMLCurrNode := XMLCurrNode.ParentNode;
            until TempVATAmountLinePmt.Next() = 0;

        XMLCurrNode := XMLCurrNode.ParentNode;
        XMLCurrNode := XMLCurrNode.ParentNode;
    end;

    local procedure AddStrPagoImpuestosP(var TempVATAmountLinePmt: Record "VAT Amount Line" temporary; var OutStr: OutStream)
    begin
        if TempVATAmountLinePmt.IsEmpty() then
            exit;

        if TempVATAmountLinePmt.FindSet() then
            repeat
                if TempVATAmountLinePmt."Tax Category" = GetTaxCategoryExempt() then begin
                    WriteOutStr(OutStr, FormatDecimal(Round(TempVATAmountLinePmt."VAT Base", 0.000001, '<'), 6) + '|'); // BaseP
                    WriteOutStr(OutStr, GetTaxCode(TempVATAmountLinePmt."VAT %", TempVATAmountLinePmt."VAT Amount") + '|'); // ImpuestoP
                    WriteOutStr(OutStr, 'Exento' + '|'); // TipoFactorP
                end else begin
                    WriteOutStr(OutStr, FormatDecimal(Round(TempVATAmountLinePmt."VAT Base", 0.000001, '<'), 6) + '|'); // BaseP
                    WriteOutStr(OutStr, GetTaxCode(TempVATAmountLinePmt."VAT %", TempVATAmountLinePmt."VAT Amount") + '|'); // ImpuestoP
                    WriteOutStr(OutStr, 'Tasa' + '|'); // TipoFactorP
                    WriteOutStr(OutStr, PadStr(FormatAmount(TempVATAmountLinePmt."VAT %" / 100), 8, '0') + '|'); // TasaOCuota
                    WriteOutStr(OutStr, FormatDecimal(Round(TempVATAmountLinePmt."VAT Amount", 0.000001, '<'), 6) + '|'); // ImporteP
                end;
            until TempVATAmountLinePmt.Next() = 0;
    end;

    local procedure AddNodePagoTotales(var XMLDoc: DotNet XmlDocument; XMLCurrNode: DotNet XmlNode; var TempVATAmountLineTotal: Record "VAT Amount Line" temporary)
    begin
        if TempVATAmountLineTotal.FindSet() then
            repeat
                if TempVATAmountLineTotal.Positive and (TempVATAmountLineTotal."VAT %" = 16) then begin
                    AddAttribute(XMLDoc, XMLCurrNode, 'TotalTrasladosBaseIVA16', FormatDecimal(TempVATAmountLineTotal."VAT Base", 2));
                    AddAttribute(XMLDoc, XMLCurrNode, 'TotalTrasladosImpuestoIVA16', FormatDecimal(TempVATAmountLineTotal."VAT Amount", 2));
                end;
                if TempVATAmountLineTotal.Positive and (TempVATAmountLineTotal."VAT %" = 8) then begin
                    AddAttribute(XMLDoc, XMLCurrNode, 'TotalTrasladosBaseIVA8', FormatDecimal(TempVATAmountLineTotal."VAT Base", 2));
                    AddAttribute(XMLDoc, XMLCurrNode, 'TotalTrasladosImpuestoIVA8', FormatDecimal(TempVATAmountLineTotal."VAT Amount", 2));
                end;
                if TempVATAmountLineTotal.Positive and (TempVATAmountLineTotal."VAT %" = 0) then
                    if TempVATAmountLineTotal."Tax Category" = GetTaxCategoryExempt() then
                        AddAttribute(XMLDoc, XMLCurrNode, 'TotalTrasladosBaseIVAExento', FormatDecimal(TempVATAmountLineTotal."VAT Base", 2))
                    else begin
                        AddAttribute(XMLDoc, XMLCurrNode, 'TotalTrasladosBaseIVA0', FormatDecimal(TempVATAmountLineTotal."VAT Base", 2));
                        AddAttribute(XMLDoc, XMLCurrNode, 'TotalTrasladosImpuestoIVA0', FormatDecimal(TempVATAmountLineTotal."VAT Amount", 2));
                    end;
            until TempVATAmountLineTotal.Next() = 0;
    end;

    local procedure AddStrPagoTotales(var TempVATAmountLineTotal: Record "VAT Amount Line" temporary; var OutStr: OutStream)
    begin
        if TempVATAmountLineTotal.IsEmpty() then
            exit;

        TempVATAmountLineTotal.SetRange(Positive, true);
        TempVATAmountLineTotal.SetRange("VAT %", 16);
        if TempVATAmountLineTotal.FindFirst() then begin
            WriteOutStr(OutStr, FormatDecimal(TempVATAmountLineTotal."VAT Base", 2) + '|'); // TotalTrasladosBaseIVA16
            WriteOutStr(OutStr, FormatDecimal(TempVATAmountLineTotal."VAT Amount", 2) + '|'); // TotalTrasladosImpuestoIVA16
        end;
        TempVATAmountLineTotal.SetRange("VAT %", 8);
        if TempVATAmountLineTotal.FindFirst() then begin
            WriteOutStr(OutStr, FormatDecimal(TempVATAmountLineTotal."VAT Base", 2) + '|'); // TotalTrasladosBaseIVA8
            WriteOutStr(OutStr, FormatDecimal(TempVATAmountLineTotal."VAT Amount", 2) + '|'); // TotalTrasladosImpuestoIVA8
        end;
        TempVATAmountLineTotal.SetRange("VAT %", 0);
        TempVATAmountLineTotal.SetRange("Tax Category", '');
        if TempVATAmountLineTotal.FindFirst() then begin
            WriteOutStr(OutStr, FormatDecimal(TempVATAmountLineTotal."VAT Base", 2) + '|'); // TotalTrasladosBaseIVA0
            WriteOutStr(OutStr, FormatDecimal(TempVATAmountLineTotal."VAT Amount", 2) + '|'); // TotalTrasladosImpuestoIVA0
        end;
        TempVATAmountLineTotal.SetRange("Tax Category", GetTaxCategoryExempt());
        if TempVATAmountLineTotal.FindFirst() then
            WriteOutStr(OutStr, FormatDecimal(TempVATAmountLineTotal."VAT Base", 2) + '|'); // Exento
        TempVATAmountLineTotal.Reset();
    end;

    local procedure IsInvoicePrepaymentSettle(InvoiceNumber: Code[20]; var AdvanceAmount: Decimal): Boolean
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.Reset();
        SalesInvoiceLine.SetFilter("Document No.", '=%1', InvoiceNumber);
        if SalesInvoiceLine.FindSet() then
            repeat
                if SalesInvoiceLine."Prepayment Line" then begin
                    AdvanceAmount := SalesInvoiceLine."Amount Including VAT";
                    exit(true);
                end;
            until SalesInvoiceLine.Next() = 0;
        exit(false);
    end;

    local procedure MapServiceTypeToTempDocType(Type: Enum "Service Line Type") LineType: Enum "Sales Line Type"
    begin
        case Type of
            Type::Item:
                exit(LineType::Item);
            Type::Resource:
                exit(LineType::Resource);
            Type::"G/L Account":
                exit(LineType::"G/L Account");
            else
                exit(LineType::" ");
        end;
    end;

    local procedure GetAdvanceAmountFromSettledInvoice(SalesInvoiceHeader: Record "Sales Invoice Header"): Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.Reset();
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetFilter("Prepayment Line", '=1');
        if SalesInvoiceLine.FindFirst() then
            exit(Abs(SalesInvoiceLine."Amount Including VAT"));
    end;

    local procedure GetCurrencyDecimalPlaces(CurrencyCode: Code[10]): Integer
    begin
        case CurrencyCode of
            'CLF':
                exit(4);
            'BHD', 'IQD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND':
                exit(3);
            'BIF', 'BYR', 'CLP', 'DJF', 'GNF', 'ISK', 'JPY', 'KMF', 'KRW', 'PYG', 'RWF',
          'UGX', 'UYI', 'VND', 'VUV', 'XAF', 'XAG', 'XAU', 'XBA', 'XBB', 'XBC', 'XBD',
          'XDR', 'XOF', 'XPD', 'XPF', 'XPT', 'XSU', 'XTS', 'XUA', 'XXX':
                exit(0);
            else
                exit(2);
        end;
    end;

    local procedure GetTransferDestinationData(var Location: Record Location; var DestinationRFCNo: Code[30]; var ForeignRegId: Code[30]; var FiscalResidence: Code[10]; TempDocumentHeader: Record "Document Header" temporary; Customer: Record Customer)
    var
        SATUtilities: Codeunit "SAT Utilities";
    begin
        if not Location.Get(TempDocumentHeader."Transit-to Location") then begin
            Location."SAT Address Id" := TempDocumentHeader."SAT Address ID";
            Location."ID Ubicacion" := 0;
            Location.Address := TempDocumentHeader."Bill-to/Pay-To Address";
        end;

        if TempDocumentHeader."Foreign Trade" then begin
            DestinationRFCNo := GetForeignRFCNo();
            ForeignRegId := Customer."VAT Registration No.";
            if ForeignRegId = '' then
                ForeignRegId := CompanyInfo."VAT Registration No.";
            FiscalResidence := SATUtilities.GetSATCountryCode(TempDocumentHeader."Ship-to/Buy-from Country Code");
        end else begin
            DestinationRFCNo := Customer."RFC No.";
            if DestinationRFCNo = '' then
                DestinationRFCNo := CompanyInfo."RFC Number";
            ForeignRegId := '';
            FiscalResidence := '';
        end;

        OnAfterGetCartaPorteDistinationData(DestinationRFCNo, ForeignRegId, FiscalResidence, TempDocumentHeader);
    end;

    local procedure GetTaxCode(VATPct: Decimal; VATAmount: Decimal) TaxCode: Code[10]
    var
        TaxType: Option Translado,Retencion;
    begin
        TaxCode := '002';
        if VATPct <> 0 then
            if VATAmount >= 0 then
                TaxCode := TaxCodeFromTaxRate(VATPct / 100, TaxType::Translado)
            else
                TaxCode := TaxCodeFromTaxRate(VATPct / 100, TaxType::Retencion);
    end;

    local procedure GetSubjectToTaxFromDocument(TableID: Integer; DocumentNo: Code[20]): Text
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        DocumentLine: Record "Document Line";
    begin
        case TableID of
            DATABASE::"Sales Invoice Header":
                begin
                    FilterSalesInvoiceLines(SalesInvoiceLine, DocumentNo);
                    SalesInvoiceLine.FindFirst();
                    DocumentLine.TransferFields(SalesInvoiceLine);
                    exit(GetSubjectToTaxCode(DocumentLine));
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    FilterSalesCrMemoLines(SalesCrMemoLine, DocumentNo);
                    SalesCrMemoLine.FindFirst();
                    DocumentLine.TransferFields(SalesCrMemoLine);
                    exit(GetSubjectToTaxCode(DocumentLine));
                end;
            DATABASE::"Service Invoice Header":
                begin
                    FilterServiceInvoiceLines(ServiceInvoiceLine, DocumentNo);
                    ServiceInvoiceLine.FindFirst();
                    DocumentLine.TransferFields(ServiceInvoiceLine);
                    exit(GetSubjectToTaxCode(DocumentLine));
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    FilterServiceCrMemoLines(ServiceCrMemoLine, DocumentNo);
                    ServiceCrMemoLine.FindFirst();
                    DocumentLine.TransferFields(ServiceCrMemoLine);
                    exit(GetSubjectToTaxCode(DocumentLine));
                end;
        end;
    end;

    local procedure GetSubjectToTaxCode(DocumentLine: Record "Document Line"): Text
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if not VATPostingSetup.Get(DocumentLine."VAT Bus. Posting Group", DocumentLine."VAT Prod. Posting Group") then
            exit('01');

        if VATPostingSetup."CFDI Subject to Tax" <> '' then
            exit(VATPostingSetup."CFDI Subject to Tax");

        if VATPostingSetup."CFDI Non-Taxable" or VATPostingSetup."CFDI VAT Exemption" then
            exit('01');

        exit('02');
    end;

    local procedure GetForeignRFCNo(): Code[13]
    begin
        exit('XEXX010101000');
    end;

    local procedure GetTaxCategoryExempt(): Code[10]
    begin
        exit('E');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Connection", 'OnRegisterServiceConnection', '', false, false)]
    local procedure HandleMXElectronicInvoicingRegisterServiceConnection(var ServiceConnection: Record "Service Connection")
    var
        MXElectronicInvoicingSetup: Record "MX Electronic Invoicing Setup";
        RecRef: RecordRef;
    begin
        CompanyInfo.Get();
        if CompanyInfo."Country/Region Code" <> 'MX' then
            exit;
        SetupService();
        MXElectronicInvoicingSetup.FindFirst();

        RecRef.GetTable(MXElectronicInvoicingSetup);

        if MXElectronicInvoicingSetup.Enabled then
            ServiceConnection.Status := ServiceConnection.Status::Enabled
        else
            ServiceConnection.Status := ServiceConnection.Status::Disabled;

        ServiceConnection.InsertServiceConnection(
              ServiceConnection, RecRef.RecordId, MXElectronicInvoicingLbl, '', PAGE::"MX Electronic Invoice Setup");
    end;

    [Scope('OnPrem')]
    procedure SetupService()
    var
        MXElectronicInvoicingSetup: Record "MX Electronic Invoicing Setup";
    begin
        if not MXElectronicInvoicingSetup.FindFirst() then
            InitServiceSetup();
    end;

    local procedure InitServiceSetup()
    var
        MXElectronicInvoicingSetup: Record "MX Electronic Invoicing Setup";
    begin
        MXElectronicInvoicingSetup.Init();
        MXElectronicInvoicingSetup.Enabled := false;
        MXElectronicInvoicingSetup.Insert(true);
    end;

    [TryFunction]
    local procedure SignDataWithCert(var SignedString: Text; OriginalString: Text; Certificate: Text; Password: SecretText)
    begin
        SignedString := EInvoiceCommunication.SignDataWithCertificate(OriginalString, Certificate, Password);
    end;

    [Scope('OnPrem')]
    procedure OpenAssistedSetup(MissingSMTPNotification: Notification)
    begin
        PAGE.Run(PAGE::"Email Accounts");
    end;

    [Scope('OnPrem')]
    procedure IsPACEnvironmentEnabled(): Boolean
    begin
        GetGLSetupOnce();
        exit((GLSetup."PAC Environment" <> GLSetup."PAC Environment"::Disabled) and GLSetup."CFDI Enabled");
    end;

    procedure IsHazardousMaterialMandatory(SATClassificationCode: Code[10]): Boolean
    var
        SATClassification: Record "SAT Classification";
    begin
        if not SATClassification.Get(SATClassificationCode) then
            exit(false);
        exit(SATClassification."Hazardous Material Mandatory");
    end;

    local procedure IsTransferDocument(DatabaseId: Integer): Boolean
    begin
        exit(
            DatabaseId in [Database::"Sales Shipment Header", Database::"Transfer Shipment Header"]);
    end;

    local procedure WriteOutStr(var OutStr: OutStream; TextParam: Text[1024])
    begin
        if StrLen(TextParam) > 1 then
            OutStr.WriteText(TextParam, StrLen(TextParam));
    end;

    local procedure WriteOutStrAllowOneCharacter(var OutStr: OutStream; TextParam: Text[1024])
    begin
        if StrLen(TextParam) > 0 then
            OutStr.WriteText(TextParam, StrLen(TextParam));
    end;

    [Scope('OnPrem')]
    procedure InsertSalesInvoiceCFDIRelations(SalesHeader: Record "Sales Header"; DocumentNo: Code[20])
    begin
        InsertSalesCFDIRelations(SalesHeader, DocumentNo, DATABASE::"Sales Invoice Header");
    end;

    [Scope('OnPrem')]
    procedure InsertSalesCreditMemoCFDIRelations(SalesHeader: Record "Sales Header"; DocumentNo: Code[20])
    begin
        InsertSalesCFDIRelations(SalesHeader, DocumentNo, DATABASE::"Sales Cr.Memo Header");
    end;

    [Scope('OnPrem')]
    procedure InsertSalesShipmentCFDITransportOperators(SalesHeader: Record "Sales Header"; DocumentNo: Code[20])
    begin
        CopyInsertCFDITransportOperators(
          DATABASE::"Sales Header", SalesHeader."Document Type".AsInteger(), SalesHeader."No.",
          DATABASE::"Sales Shipment Header", DocumentNo);
    end;

    [Scope('OnPrem')]
    procedure InsertTransferShipmentCFDITransportOperators(TransferHeader: Record "Transfer Header"; DocumentNo: Code[20])
    begin
        CopyInsertCFDITransportOperators(
          DATABASE::"Transfer Header", 0, TransferHeader."No.",
          DATABASE::"Transfer Shipment Header", DocumentNo);
    end;

    local procedure InsertSalesCFDIRelations(SalesHeader: Record "Sales Header"; DocumentNo: Code[20]; TableID: Integer)
    begin
        CopyInsertCFDIRelations(
          DATABASE::"Sales Header", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", TableID, DocumentNo, false);
    end;

    [Scope('OnPrem')]
    procedure DeleteCFDIRelationsAfterPosting(SalesHeader: Record "Sales Header")
    var
        CFDIRelationDocument: Record "CFDI Relation Document";
    begin
        CFDIRelationDocument.SetRange("Document Table ID", DATABASE::"Sales Header");
        CFDIRelationDocument.SetRange("Document Type", SalesHeader."Document Type");
        CFDIRelationDocument.SetRange("Document No.", SalesHeader."No.");
        CFDIRelationDocument.SetRange("Customer No.", SalesHeader."Bill-to Customer No.");
        CFDIRelationDocument.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure DeleteCFDITransportOperatorsAfterPosting(DocumentTableID: Integer; DocumentType: Integer; DocumentNo: Code[20])
    var
        CFDITransportOperator: Record "CFDI Transport Operator";
    begin
        CFDITransportOperator.SetRange("Document Table ID", DocumentTableID);
        CFDITransportOperator.SetRange("Document Type", DocumentType);
        CFDITransportOperator.SetRange("Document No.", DocumentNo);
        CFDITransportOperator.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure InsertServiceInvoiceCFDIRelations(ServiceHeader: Record "Service Header"; DocumentNo: Code[20])
    begin
        InsertServiceCFDIRelations(ServiceHeader, DocumentNo, DATABASE::"Service Invoice Header");
    end;

    [Scope('OnPrem')]
    procedure InsertServiceCreditMemoCFDIRelations(ServiceHeader: Record "Service Header"; DocumentNo: Code[20])
    begin
        InsertServiceCFDIRelations(ServiceHeader, DocumentNo, DATABASE::"Service Cr.Memo Header");
    end;

    [Scope('OnPrem')]
    procedure InsertServiceCFDIRelations(ServiceHeader: Record "Service Header"; DocumentNo: Code[20]; TableID: Integer)
    begin
        CopyInsertCFDIRelations(
          DATABASE::"Service Header", ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", TableID, DocumentNo, true);
    end;

    local procedure InsertTempVATAmountLine(var TempVATAmountLine: Record "VAT Amount Line" temporary; TempDocumentLine: Record "Document Line" temporary)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATIdentifier: Code[20];
    begin
        if TempDocumentLine.Type = TempDocumentLine.Type::" " then
            exit;

        VATPostingSetup.Get(TempDocumentLine."VAT Bus. Posting Group", TempDocumentLine."VAT Prod. Posting Group");
        if GetSubjectToTaxCode(TempDocumentLine) <> '02' then
            exit;

        if TempDocumentLine."Retention Attached to Line No." = 0 then
            VATIdentifier := CopyStr(Format(TempDocumentLine."VAT %"), 1, MaxStrLen(TempVATAmountLine."VAT Identifier"))
        else
            VATIdentifier := CopyStr(Format(TempDocumentLine."Retention VAT %"), 1, MaxStrLen(TempVATAmountLine."VAT Identifier"));
        if not TempVATAmountLine.Get(
             VATIdentifier, VATPostingSetup."VAT Calculation Type", '', '', false, TempDocumentLine.Amount > 0)
        then begin
            TempVATAmountLine.Init();
            TempVATAmountLine."VAT Identifier" := VATIdentifier;
            TempVATAmountLine."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
            TempVATAmountLine.Positive := TempDocumentLine.Amount >= 0;
            TempVATAmountLine.Insert();
        end;

        if VATPostingSetup."CFDI VAT Exemption" then
            TempVATAmountLine."Tax Category" := GetTaxCategoryExempt();
        if TempDocumentLine."Retention Attached to Line No." = 0 then begin
            TempVATAmountLine."Amount Including VAT" += TempDocumentLine."Amount Including VAT";
            TempVATAmountLine."VAT %" := TempDocumentLine."VAT %";
            TempVATAmountLine."VAT Amount" += TempDocumentLine."Amount Including VAT" - TempDocumentLine.Amount;
            TempVATAmountLine."VAT Base" += TempDocumentLine.Amount;
            TempVATAmountLine.Modify();
        end else begin
            TempVATAmountLine."VAT %" := TempDocumentLine."Retention VAT %";
            TempVATAmountLine."VAT Amount" += TempDocumentLine.Amount;
            TempVATAmountLine.Modify();
        end;
    end;

    local procedure InsertTempVATAmountLinePmt(var TempVATAmountLinePmt: Record "VAT Amount Line" temporary; var TempVATAmountLine: Record "VAT Amount Line" temporary; CurrencyFactor: Decimal)
    begin
        if not TempVATAmountLine.FindSet() then
            exit;

        repeat
            if not TempVATAmountLinePmt.Get(
                 TempVATAmountLine."VAT Identifier", TempVATAmountLine."VAT Calculation Type",
                 TempVATAmountLine."Tax Group Code", TempVATAmountLine."Tax Group Code",
                 TempVATAmountLine."Use Tax", TempVATAmountLine.Positive)
            then begin
                TempVATAmountLinePmt := TempVATAmountLine;
                TempVATAmountLinePmt."VAT Base" := 0;
                TempVATAmountLinePmt."VAT Amount" := 0;
                TempVATAmountLinePmt."Amount Including VAT" := 0;
                TempVATAmountLinePmt.Insert();
            end;
            TempVATAmountLinePmt."VAT Base" += Round(TempVATAmountLine."VAT Base") / CurrencyFactor;
            TempVATAmountLinePmt."VAT Amount" += Round(TempVATAmountLine."VAT Amount") / CurrencyFactor;
            TempVATAmountLinePmt."Amount Including VAT" += Round(TempVATAmountLine."Amount Including VAT") / CurrencyFactor;
            TempVATAmountLinePmt.Modify();
        until TempVATAmountLine.Next() = 0;
    end;

    local procedure InsertTempVATAmountLinePmtTotals(var TempVATAmountLineTotal: Record "VAT Amount Line" temporary; var TempVATAmountLine: Record "VAT Amount Line" temporary; CurrencyCode: Code[10]; CurrencyFactor: Decimal)
    var
        Currency: Record Currency;
        RoundingPrecision: Decimal;
    begin
        if not TempVATAmountLine.FindSet() then
            exit;

        CurrencyFactor := Round(1 / CurrencyFactor, 0.000001);
        Currency.Initialize(CurrencyCode);
        if ConvertCurrency(CurrencyCode) = GLSetup."LCY Code" then
            RoundingPrecision := 0.01
        else
            RoundingPrecision := 0.000001;
        repeat
            if not TempVATAmountLineTotal.Get(
                 TempVATAmountLine."VAT Identifier", TempVATAmountLine."VAT Calculation Type",
                 TempVATAmountLine."Tax Group Code", TempVATAmountLine."Tax Group Code",
                 TempVATAmountLine."Use Tax", TempVATAmountLine.Positive)
            then begin
                TempVATAmountLineTotal := TempVATAmountLine;
                TempVATAmountLineTotal."VAT Base" := 0;
                TempVATAmountLineTotal."VAT Amount" := 0;
                TempVATAmountLineTotal."Amount Including VAT" := 0;
                TempVATAmountLineTotal.Insert();
            end;
            TempVATAmountLineTotal."VAT Base" +=
              Round(TempVATAmountLine."VAT Base", RoundingPrecision) * CurrencyFactor;
            TempVATAmountLineTotal."VAT Amount" +=
              Round(TempVATAmountLine."VAT Amount", RoundingPrecision) * CurrencyFactor;
            TempVATAmountLineTotal."Amount Including VAT" +=
              Round(TempVATAmountLine."Amount Including VAT", RoundingPrecision) * CurrencyFactor;
            TempVATAmountLineTotal.Modify();
        until TempVATAmountLine.Next() = 0;
    end;

    local procedure InsertTempDocRetentionLine(var TempDocumentLineRetention: Record "Document Line" temporary; TempDocumentLine: Record "Document Line" temporary)
    begin
        if TempDocumentLine.Type = TempDocumentLine.Type::" " then
            exit;

        if TempDocumentLine."Retention Attached to Line No." = 0 then
            exit;

        TempDocumentLineRetention := TempDocumentLine;
        TempDocumentLineRetention.Insert();
    end;

    local procedure CopyInsertCFDIRelations(FromTableID: Integer; FromDocumentType: Integer; FromDocumentNo: Code[20]; ToTableID: Integer; ToDocumentNo: Code[20]; DeleteRelations: Boolean)
    var
        CFDIRelationDocumentFrom: Record "CFDI Relation Document";
        CFDIRelationDocument: Record "CFDI Relation Document";
    begin
        if ToDocumentNo = '' then
            exit;

        CFDIRelationDocumentFrom.SetRange("Document Table ID", FromTableID);
        CFDIRelationDocumentFrom.SetRange("Document Type", FromDocumentType);
        CFDIRelationDocumentFrom.SetRange("Document No.", FromDocumentNo);
        if not CFDIRelationDocumentFrom.FindSet() then
            exit;

        repeat
            CFDIRelationDocument := CFDIRelationDocumentFrom;
            CFDIRelationDocument."Document Table ID" := ToTableID;
            CFDIRelationDocument."Document Type" := 0;
            CFDIRelationDocument."Document No." := ToDocumentNo;
            CFDIRelationDocument.Insert();
        until CFDIRelationDocumentFrom.Next() = 0;

        if DeleteRelations then
            CFDIRelationDocumentFrom.DeleteAll();
    end;

    local procedure CopyInsertCFDITransportOperators(FromTableID: Integer; FromDocumentType: Option; FromDocumentNo: Code[20]; ToTableID: Integer; ToDocumentNo: Code[20])
    var
        CFDITransportOperatorFrom: Record "CFDI Transport Operator";
        CFDITransportOperator: Record "CFDI Transport Operator";
    begin
        if ToDocumentNo = '' then
            exit;

        CFDITransportOperatorFrom.SetRange("Document Table ID", FromTableID);
        CFDITransportOperatorFrom.SetRange("Document Type", FromDocumentType);
        CFDITransportOperatorFrom.SetRange("Document No.", FromDocumentNo);
        if not CFDITransportOperatorFrom.FindSet() then
            exit;

        repeat
            CFDITransportOperator := CFDITransportOperatorFrom;
            CFDITransportOperator."Document Table ID" := ToTableID;
            CFDITransportOperator."Document Type" := 0;
            CFDITransportOperator."Document No." := ToDocumentNo;
            CFDITransportOperator.Insert();
        until CFDITransportOperatorFrom.Next() = 0;
    end;

    local procedure CheckSalesDocument(DocumentVariant: Variant; TempDocumentHeader: Record "Document Header" temporary; var TempDocumentLine: Record "Document Line" temporary; var TempCFDIRelationDocument: Record "CFDI Relation Document" temporary; SourceCode: Code[10]; IsPrepayment: Boolean)
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        ClearLastError();
        CheckGLSetup(TempErrorMessage);
        CheckCompanyInfo(TempErrorMessage);
        CheckSATCatalogs(TempErrorMessage);
        CheckCertificates(TempErrorMessage, TempDocumentHeader);
        CheckCustomer(TempErrorMessage, TempDocumentHeader."Bill-to/Pay-To No.");
        CheckDocumentHeader(TempErrorMessage, DocumentVariant, TempDocumentHeader, SourceCode);
        CheckDocumentLine(TempErrorMessage, DocumentVariant, TempDocumentLine, TempDocumentHeader."Foreign Trade", IsPrepayment);
        CheckCFDIRelations(TempErrorMessage, TempCFDIRelationDocument, TempDocumentHeader, DocumentVariant);

        if TempErrorMessage.HasErrors(false) then
            if TempErrorMessage.ShowErrors() then
                Error('');
    end;

    local procedure CheckTransferDocument(DocumentVariant: Variant; TempDocumentHeader: Record "Document Header" temporary; var TempDocumentLine: Record "Document Line" temporary)
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        ClearLastError();

        CheckGLSetup(TempErrorMessage);
        CheckCompanyInfo(TempErrorMessage);
        CheckSATCatalogs(TempErrorMessage);
        CheckSATCatalogsCartaPorte(TempErrorMessage);
        CheckCertificates(TempErrorMessage, TempDocumentHeader);
        CheckDocumentHeaderCartaPorte(TempErrorMessage, DocumentVariant, TempDocumentHeader);
        CheckDocumentLineCartaPorte(TempErrorMessage, DocumentVariant, TempDocumentLine);

        if TempErrorMessage.HasErrors(false) then
            if TempErrorMessage.ShowErrors() then
                Error('');
    end;

    local procedure CheckGLSetup(var TempErrorMessage: Record "Error Message" temporary)
    begin
        GetGLSetupOnce();
        TempErrorMessage.LogIfEmpty(GLSetup, GLSetup.FieldNo("SAT Certificate"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(GLSetup, GLSetup.FieldNo("PAC Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(GLSetup, GLSetup.FieldNo("PAC Environment"), TempErrorMessage."Message Type"::Error);
    end;

    local procedure CheckCompanyInfo(var TempErrorMessage: Record "Error Message" temporary)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo(Name), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo(Address), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo(City), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo("Country/Region Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo("Post Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo("E-Mail"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo("Tax Scheme"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo("RFC Number"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo("SAT Tax Regime Classification"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo("SAT Postal Code"), TempErrorMessage."Message Type"::Error);
    end;

    local procedure CheckCustomer(var TempErrorMessage: Record "Error Message" temporary; CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("RFC No."), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("Country/Region Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("SAT Tax Regime Classification"), TempErrorMessage."Message Type"::Error);
    end;

    local procedure CheckDocumentHeader(var TempErrorMessage: Record "Error Message" temporary; DocumentVariant: Variant; DocumentHeader: Record "Document Header"; SourceCode: Code[10])
    var
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        SATPaymentTerm: Record "SAT Payment Term";
        SATPaymentMethod: Record "SAT Payment Method";
    begin
        TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("No."), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("Document Date"), TempErrorMessage."Message Type"::Error);

        TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("Payment Terms Code"), TempErrorMessage."Message Type"::Error);
        if PaymentTerms.Get(DocumentHeader."Payment Terms Code") then
            TempErrorMessage.LogIfEmpty(PaymentTerms, PaymentTerms.FieldNo("SAT Payment Term"), TempErrorMessage."Message Type"::Error);
        if (PaymentTerms."SAT Payment Term" <> '') and not SATPaymentTerm.Get(PaymentTerms."SAT Payment Term") then
            TempErrorMessage.LogMessage(
              PaymentTerms, PaymentTerms.FieldNo("SAT Payment Term"), TempErrorMessage."Message Type"::Error,
              StrSubstNo(
                WrongFieldValueErr,
                PaymentTerms."SAT Payment Term", PaymentTerms.FieldCaption("SAT Payment Term"), PaymentTerms.TableCaption()));
        TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("Payment Method Code"), TempErrorMessage."Message Type"::Error);

        if PaymentMethod.Get(DocumentHeader."Payment Method Code") then
            TempErrorMessage.LogIfEmpty(PaymentMethod, PaymentMethod.FieldNo("SAT Method of Payment"), TempErrorMessage."Message Type"::Error);
        if (PaymentMethod."SAT Method of Payment" <> '') and not SATPaymentMethod.Get(PaymentMethod."SAT Method of Payment") then
            TempErrorMessage.LogMessage(
              PaymentMethod, PaymentMethod.FieldNo("SAT Method of Payment"), TempErrorMessage."Message Type"::Error,
              StrSubstNo(
                WrongFieldValueErr,
                PaymentMethod."SAT Method of Payment", PaymentMethod.FieldCaption("SAT Method of Payment"), PaymentMethod.TableCaption()));
        TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("Bill-to/Pay-To Address"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("Bill-to/Pay-To Post Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("CFDI Purpose"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("CFDI Export Code"), TempErrorMessage."Message Type"::Error);
        if SourceCode = SourceCodeSetup."Deleted Document" then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, Text007);
        if (DocumentHeader."CFDI Purpose" = 'PPD') and (DocumentHeader."CFDI Relation" = '03') then
            TempErrorMessage.LogMessage(
              DocumentHeader, DocumentHeader.FieldNo("CFDI Purpose"), TempErrorMessage."Message Type"::Error,
              StrSubstNo(
                CombinationCannotBeUsedErr, DocumentHeader.FieldCaption("CFDI Purpose"), DocumentHeader."CFDI Purpose",
                DocumentHeader.FieldCaption("CFDI Relation"), DocumentHeader."CFDI Relation"));
        if DocumentHeader."Foreign Trade" then begin
            TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("SAT Address ID"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("SAT International Trade Term"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("Exchange Rate USD"), TempErrorMessage."Message Type"::Error);

            CheckLocation(TempErrorMessage, DocumentVariant, DocumentHeader."Location Code", 28);
        end;
    end;

    local procedure CheckDocumentHeaderCartaPorte(var TempErrorMessage: Record "Error Message" temporary; DocumentVariant: Variant; DocumentHeader: Record "Document Header")
    var
        CFDITransportOperator: Record "CFDI Transport Operator";
        Employee: Record Employee;
    begin
        TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("No."), TempErrorMessage."Message Type"::Error);
        case DocumentHeader."Document Table ID" of
            DATABASE::"Sales Shipment Header":
                TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("Document Date"), TempErrorMessage."Message Type"::Error);
            DATABASE::"Transfer Shipment Header":
                TempErrorMessage.LogIfEmpty(DocumentVariant, 20, TempErrorMessage."Message Type"::Error);
        end;
        TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("Transit-from Date/Time"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("Transit Hours"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("Transit Distance"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("Insurer Name"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("Insurer Policy Number"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("Vehicle Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("SAT Weight Unit Of Measure"), TempErrorMessage."Message Type"::Error);
        if DocumentHeader."Foreign Trade" then begin
            TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("SAT International Trade Term"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("SAT Customs Regime"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("SAT Transfer Reason"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("Exchange Rate USD"), TempErrorMessage."Message Type"::Error);
        end;
        CFDITransportOperator.SetRange("Document Table ID", DocumentHeader."Document Table ID");
        CFDITransportOperator.SetRange("Document No.", DocumentHeader."No.");
        if not CFDITransportOperator.FindSet() then
            TempErrorMessage.LogIfEmpty(DocumentVariant, DocumentHeader.FieldNo("Transport Operators"), TempErrorMessage."Message Type"::Error)
        else
            repeat
                Employee.Get(CFDITransportOperator."Operator Code");
                TempErrorMessage.LogIfEmpty(Employee, Employee.FieldNo("RFC No."), TempErrorMessage."Message Type"::Error);
                TempErrorMessage.LogIfEmpty(Employee, Employee.FieldNo("License No."), TempErrorMessage."Message Type"::Error);
                if Employee.FullName() = '' then
                    TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(ValueIsNotDefinedErr, 'Full Name', Employee.RecordId));
            until CFDITransportOperator.Next() = 0;
        CheckAutotransport(TempErrorMessage, DocumentHeader."Vehicle Code", false);
        CheckAutotransport(TempErrorMessage, DocumentHeader."Trailer 1", true);
        CheckAutotransport(TempErrorMessage, DocumentHeader."Trailer 2", true);
        case DocumentHeader."Document Table ID" of
            DATABASE::"Sales Shipment Header":
                begin
                    CheckLocation(TempErrorMessage, DocumentVariant, DocumentHeader."Transit-from Location", 28);
                    CheckSATAddress(TempErrorMessage, DocumentHeader."SAT Address ID");
                end;
            DATABASE::"Transfer Shipment Header":
                begin
                    CheckLocation(TempErrorMessage, DocumentVariant, DocumentHeader."Transit-from Location", 2);
                    CheckLocation(TempErrorMessage, DocumentVariant, DocumentHeader."Transit-to Location", 11);
                end;
        end;
    end;

    local procedure CheckDocumentLine(var TempErrorMessage: Record "Error Message" temporary; DocumentVariant: Variant; var DocumentLine: Record "Document Line"; ForeignTrade: Boolean; IsPrepayment: Boolean)
    var
        Item: Record Item;
        GLAccount: Record "G/L Account";
        ItemCharge: Record "Item Charge";
        FixedAsset: Record "Fixed Asset";
        UnitOfMeasure: Record "Unit of Measure";
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
        LineVariant: Variant;
        LineTableCaption: Text;
    begin
        DataTypeManagement.GetRecordRef(DocumentVariant, RecRef);
        DocumentLine.FindSet();
        repeat
            GetLineVarFromDocumentLine(LineVariant, LineTableCaption, RecRef.Number, DocumentLine);
            TempErrorMessage.LogIfEmpty(LineVariant, DocumentLine.FieldNo(Description), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(LineVariant, DocumentLine.FieldNo("Unit Price/Direct Unit Cost"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(LineVariant, DocumentLine.FieldNo("Amount Including VAT"), TempErrorMessage."Message Type"::Error);
            if not (DocumentLine.Type in [DocumentLine.Type::"G/L Account", DocumentLine.Type::"Fixed Asset"]) then
                TempErrorMessage.LogIfEmpty(LineVariant, DocumentLine.FieldNo("Unit of Measure Code"), TempErrorMessage."Message Type"::Error);

            if (DocumentLine.Type = DocumentLine.Type::Item) and Item.Get(DocumentLine."No.") then
                TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("SAT Item Classification"), TempErrorMessage."Message Type"::Error);
            if not IsPrepayment then
                if (DocumentLine.Type = DocumentLine.Type::"G/L Account") and GLAccount.Get(DocumentLine."No.") then
                    TempErrorMessage.LogIfEmpty(GLAccount, GLAccount.FieldNo("SAT Classification Code"), TempErrorMessage."Message Type"::Error);
            if (DocumentLine.Type = DocumentLine.Type::"Charge (Item)") and ItemCharge.Get(DocumentLine."No.") then
                TempErrorMessage.LogIfEmpty(ItemCharge, ItemCharge.FieldNo("SAT Classification Code"), TempErrorMessage."Message Type"::Error);
            if (DocumentLine.Type = DocumentLine.Type::"Fixed Asset") and FixedAsset.Get(DocumentLine."No.") then
                TempErrorMessage.LogIfEmpty(FixedAsset, FixedAsset.FieldNo("SAT Classification Code"), TempErrorMessage."Message Type"::Error);
            if UnitOfMeasure.Get(DocumentLine."Unit of Measure Code") then
                TempErrorMessage.LogIfEmpty(UnitOfMeasure, UnitOfMeasure.FieldNo("SAT UofM Classification"), TempErrorMessage."Message Type"::Error);

            if (DocumentLine."Retention Attached to Line No." = 0) and (DocumentLine.Quantity < 0) then
                TempErrorMessage.LogIfLessThan(DocumentLine, DocumentLine.FieldNo(Quantity), TempErrorMessage."Message Type"::Warning, 0);
            if (DocumentLine."Retention Attached to Line No." <> 0) and (DocumentLine."Retention VAT %" = 0) then
                TempErrorMessage.LogIfEmpty(DocumentLine, DocumentLine.FieldNo("Retention VAT %"), TempErrorMessage."Message Type"::Warning);
            if ForeignTrade then begin
                if (DocumentLine.Type = DocumentLine.Type::Item) and Item.Get(DocumentLine."No.") then
                    TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("Tariff No."), TempErrorMessage."Message Type"::Error);
                if UnitOfMeasure.Get(DocumentLine."Unit of Measure Code") then
                    TempErrorMessage.LogIfEmpty(UnitOfMeasure, UnitOfMeasure.FieldNo("SAT Customs Unit"), TempErrorMessage."Message Type"::Error);
            end;
        until DocumentLine.Next() = 0;
    end;

    local procedure CheckDocumentLineCartaPorte(var TempErrorMessage: Record "Error Message" temporary; DocumentVariant: Variant; var DocumentLine: Record "Document Line")
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
        LineVariant: Variant;
        LineTableCaption: Text;
    begin
        DataTypeManagement.GetRecordRef(DocumentVariant, RecRef);
        DocumentLine.FindSet();
        repeat
            GetLineVarFromDocumentLine(LineVariant, LineTableCaption, RecRef.Number, DocumentLine);
            TempErrorMessage.LogIfEmpty(LineVariant, DocumentLine.FieldNo(Description), TempErrorMessage."Message Type"::Error);
            if RecRef.Number = DATABASE::"Transfer Shipment Header" then begin
                TempErrorMessage.LogIfEmpty(LineVariant, 15, TempErrorMessage."Message Type"::Error);
                TempErrorMessage.LogIfEmpty(LineVariant, 16, TempErrorMessage."Message Type"::Error);
            end else begin
                TempErrorMessage.LogIfEmpty(LineVariant, DocumentLine.FieldNo("Unit of Measure Code"), TempErrorMessage."Message Type"::Error);
                TempErrorMessage.LogIfEmpty(LineVariant, DocumentLine.FieldNo("Gross Weight"), TempErrorMessage."Message Type"::Error);
            end;
            if DocumentLine.Type <> DocumentLine.Type::Item then
                TempErrorMessage.LogMessage(
                  LineVariant, DocumentLine.FieldNo(Type), TempErrorMessage."Message Type"::Error,
                  StrSubstNo(WrongFieldValueErr, DocumentLine.Type, DocumentLine.FieldCaption(Type), LineTableCaption));
            if (DocumentLine.Type = DocumentLine.Type::Item) and Item.Get(DocumentLine."No.") then
                TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("SAT Item Classification"), TempErrorMessage."Message Type"::Error);
            if UnitOfMeasure.Get(DocumentLine."Unit of Measure Code") then
                TempErrorMessage.LogIfEmpty(UnitOfMeasure, UnitOfMeasure.FieldNo("SAT UofM Classification"), TempErrorMessage."Message Type"::Error);
            if Item."SAT Hazardous Material" <> '' then
                TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("SAT Packaging Type"), TempErrorMessage."Message Type"::Error);
        until DocumentLine.Next() = 0;
    end;

    local procedure CheckCFDIRelations(var TempErrorMessage: Record "Error Message" temporary; var TempCFDIRelationDocument: Record "CFDI Relation Document" temporary; DocumentHeader: Record "Document Header"; RecVariant: Variant)
    begin
        if TempCFDIRelationDocument.FindSet() then begin
            TempErrorMessage.LogIfEmpty(RecVariant, DocumentHeader.FieldNo("CFDI Relation"), TempErrorMessage."Message Type"::Error);
            repeat
                TempErrorMessage.LogIfEmpty(TempCFDIRelationDocument, TempCFDIRelationDocument.FieldNo("Fiscal Invoice Number PAC"), TempErrorMessage."Message Type"::Error);
            until TempCFDIRelationDocument.Next() = 0;
        end else
            if DocumentHeader."CFDI Relation" = '04' then
                TempErrorMessage.LogMessage(RecVariant, DocumentHeader.FieldNo("CFDI Relation"), TempErrorMessage."Message Type"::Error, NoRelationDocumentsExistErr);
    end;

    local procedure CheckSATCatalogs(var TempErrorMessage: Record "Error Message" temporary)
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
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATClassification.TableCaption()));
        if SATRelationshipType.IsEmpty() then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATRelationshipType.TableCaption()));
        if SATUseCode.IsEmpty() then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATUseCode.TableCaption()));
        if SATUnitOfMeasure.IsEmpty() then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATUnitOfMeasure.TableCaption()));
        if SATCountryCode.IsEmpty() then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATCountryCode.TableCaption()));
        if SATTaxScheme.IsEmpty() then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATTaxScheme.TableCaption()));
        if SATPaymentTerm.IsEmpty() then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATPaymentTerm.TableCaption()));
        if SATPaymentMethod.IsEmpty() then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATPaymentMethod.TableCaption()));
        if SATMaterialType.IsEmpty() then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATMaterialType.TableCaption()));
    end;

    local procedure CheckSATCatalogsCartaPorte(var TempErrorMessage: Record "Error Message" temporary)
    var
        SATFederalMotorTransport: Record "SAT Federal Motor Transport";
        SATTrailerType: Record "SAT Trailer Type";
        SATPermissionType: Record "SAT Permission Type";
        SATHazardousMaterial: Record "SAT Hazardous Material";
        SATPackagingType: Record "SAT Packaging Type";
        SATMaterialType: Record "SAT Material Type";
        SATState: Record "SAT State";
        SATMunicipality: Record "SAT Municipality";
        SATLocality: Record "SAT Locality";
        SATSuburb: Record "SAT Suburb";
        SATCustomsDocumentType: Record "SAT Customs Document Type";
        SATCustomsRegime: Record "SAT Customs Regime";
        SATTransferReason: Record "SAT Transfer Reason";
    begin
        if SATFederalMotorTransport.IsEmpty() then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATFederalMotorTransport.TableCaption()));
        if SATTrailerType.IsEmpty() then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATTrailerType.TableCaption()));
        if SATPermissionType.IsEmpty() then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATPermissionType.TableCaption()));
        if SATHazardousMaterial.IsEmpty() then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATHazardousMaterial.TableCaption()));
        if SATPackagingType.IsEmpty() then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATPackagingType.TableCaption()));
        if SATMaterialType.IsEmpty() then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATMaterialType.TableCaption()));
        if SATState.IsEmpty() then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATState.TableCaption()));
        if SATMunicipality.IsEmpty() then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATMunicipality.TableCaption()));
        if SATLocality.IsEmpty() then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATLocality.TableCaption()));
        if SATSuburb.IsEmpty() then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATSuburb.TableCaption()));
        if SATCustomsDocumentType.IsEmpty() then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATCustomsDocumentType.TableCaption()));
        if SATCustomsRegime.IsEmpty() then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATCustomsRegime.TableCaption()));
        if SATTransferReason.IsEmpty() then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, StrSubstNo(EmptySATCatalogErr, SATTransferReason.TableCaption()));
    end;

    local procedure CheckCertificates(var TempErrorMessage: Record "Error Message" temporary; var TempDocumentHeader: Record "Document Header" temporary)
    var
        IsolatedCertificate: Record "Isolated Certificate";
        PACWebService: Record "PAC Web Service";
        PACWebServiceDetail: Record "PAC Web Service Detail";
        Location: Record Location;
        LocationCode: Code[10];
    begin
        GetGLSetupOnce();
        if IsolatedCertificate.Get(GLSetup."SAT Certificate") then
            TempErrorMessage.LogIfEmpty(IsolatedCertificate, IsolatedCertificate.FieldNo(ThumbPrint), TempErrorMessage."Message Type"::Error);

        if GLSetup."Multiple SAT Certificates" then begin
            Location.SetLoadFields("SAT Certificate");
            if TempDocumentHeader."Document Table ID" = Database::"Transfer Shipment Header" then
                LocationCode := TempDocumentHeader."Transit-from Location"
            else
                LocationCode := TempDocumentHeader."Location Code";

            if Location.Get(LocationCode) then
                if Location."SAT Certificate" <> '' then
                    if IsolatedCertificate.Get(Location."SAT Certificate") then
                        TempErrorMessage.LogIfEmpty(IsolatedCertificate, IsolatedCertificate.FieldNo(ThumbPrint), TempErrorMessage."Message Type"::Error);
        end;

        if PACWebService.Get(GLSetup."PAC Code") then begin
            TempErrorMessage.LogIfEmpty(PACWebService, PACWebService.FieldNo(Certificate), TempErrorMessage."Message Type"::Error);
            if PACWebServiceDetail.Get(PACWebService.Code, GLSetup."PAC Environment", PACWebServiceDetail.Type::"Request Stamp") then
                TempErrorMessage.LogIfEmpty(PACWebServiceDetail, PACWebServiceDetail.FieldNo(Address), TempErrorMessage."Message Type"::Error)
            else
                TempErrorMessage.LogMessage(
                  PACWebServiceDetail, PACWebService.FieldNo(Code), TempErrorMessage."Message Type"::Error,
                  StrSubstNo(
                    PACDetailDoesNotExistErr, PACWebServiceDetail.TableCaption(),
                    PACWebService.Code, GLSetup."PAC Environment", PACWebServiceDetail.Type::"Request Stamp"));
            if PACWebServiceDetail.Get(PACWebService.Code, GLSetup."PAC Environment", PACWebServiceDetail.Type::Cancel) then
                TempErrorMessage.LogIfEmpty(PACWebServiceDetail, PACWebServiceDetail.FieldNo(Address), TempErrorMessage."Message Type"::Error)
            else
                TempErrorMessage.LogMessage(
                  PACWebServiceDetail, PACWebService.FieldNo(Code), TempErrorMessage."Message Type"::Error,
                  StrSubstNo(
                    PACDetailDoesNotExistErr, PACWebServiceDetail.TableCaption(),
                    PACWebService.Code, GLSetup."PAC Environment", PACWebServiceDetail.Type::Cancel));
        end;
    end;

    local procedure CheckAutotransport(var TempErrorMessage: Record "Error Message" temporary; VehicleCode: Code[20]; IsTrailer: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
    begin
        if VehicleCode = '' then
            exit;

        FixedAsset.Get(VehicleCode);
        TempErrorMessage.LogIfEmpty(FixedAsset, FixedAsset.FieldNo("Vehicle Licence Plate"), TempErrorMessage."Message Type"::Error);
        if IsTrailer then
            TempErrorMessage.LogIfEmpty(FixedAsset, FixedAsset.FieldNo("SAT Trailer Type"), TempErrorMessage."Message Type"::Error)
        else begin
            TempErrorMessage.LogIfEmpty(FixedAsset, FixedAsset.FieldNo("Vehicle Year"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(FixedAsset, FixedAsset.FieldNo("Vehicle Gross Weight"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(FixedAsset, FixedAsset.FieldNo("SAT Federal Autotransport"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(FixedAsset, FixedAsset.FieldNo("SCT Permission Type"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(FixedAsset, FixedAsset.FieldNo("SCT Permission No."), TempErrorMessage."Message Type"::Error);
        end;
    end;

    local procedure CheckLocation(var TempErrorMessage: Record "Error Message" temporary; DocumentVariant: Variant; LocationCode: Code[10]; LocationFieldID: Integer)
    var
        Location: Record Location;
    begin
        TempErrorMessage.LogIfEmpty(DocumentVariant, LocationFieldID, TempErrorMessage."Message Type"::Error);
        if LocationCode = '' then
            exit;
        Location.Get(LocationCode);
        TempErrorMessage.LogIfEmpty(Location, Location.FieldNo("SAT Address ID"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(Location, Location.FieldNo(Address), TempErrorMessage."Message Type"::Warning);

        CheckSATAddress(TempErrorMessage, Location."SAT Address ID");
    end;

    local procedure CheckSATAddress(var TempErrorMessage: Record "Error Message" temporary; SATAddressID: Integer)
    var
        SATAddress: Record "SAT Address";
    begin
        if SATAddressID = 0 then
            exit;

        if SATAddress.Get(SATAddressID) then begin
            TempErrorMessage.LogIfEmpty(SATAddress, SATAddress.FieldNo("Country/Region Code"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(SATAddress, SATAddress.FieldNo("SAT State Code"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(SATAddress, SATAddress.FieldNo("SAT Suburb ID"), TempErrorMessage."Message Type"::Error);
        end;
    end;

    local procedure CalcComercioExteriorLine(var TempDocumentLineCCE: Record "Document Line" temporary; TempDocumentLine: Record "Document Line" temporary; IsForeignTrade: Boolean; IsTransfer: Boolean)
    begin
        if not IsForeignTrade then
            exit;

        TempDocumentLineCCE.SetRange("Document No.", TempDocumentLine."Document No.");
        TempDocumentLineCCE.SetRange("No.", TempDocumentLine."No.");
        if not TempDocumentLineCCE.FindFirst() then begin
            TempDocumentLineCCE := TempDocumentLine;
            TempDocumentLineCCE.Insert();
        end else begin
            TempDocumentLineCCE.Quantity += TempDocumentLine.Quantity;
            if not IsTransfer then
                TempDocumentLineCCE.Amount += TempDocumentLine.Amount;
            TempDocumentLineCCE.Modify();
        end;
        TempDocumentLineCCE.SetRange("No.");
    end;

    local procedure CancellationReasonRequired(ReasonCode: Code[10]): Boolean
    var
        CFDICancellationReason: Record "CFDI Cancellation Reason";
    begin
        if not CFDICancellationReason.Get(ReasonCode) then
            exit(false);
        exit(CFDICancellationReason."Substitution Number Required");
    end;

    local procedure GetLineVarFromDocumentLine(var LineVariant: Variant; var TableCaption: Text; TableID: Integer; DocumentLine: Record "Document Line")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
        case TableID of
            DATABASE::"Sales Invoice Header":
                begin
                    SalesInvoiceLine.Get(DocumentLine."Document No.", DocumentLine."Line No.");
                    LineVariant := SalesInvoiceLine;
                    TableCaption := SalesInvoiceLine.TableCaption();
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoLine.Get(DocumentLine."Document No.", DocumentLine."Line No.");
                    LineVariant := SalesCrMemoLine;
                    TableCaption := SalesCrMemoLine.TableCaption();
                end;
            DATABASE::"Service Invoice Header":
                begin
                    ServiceInvoiceLine.Get(DocumentLine."Document No.", DocumentLine."Line No.");
                    LineVariant := ServiceInvoiceLine;
                    TableCaption := ServiceInvoiceLine.TableCaption();
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    ServiceCrMemoLine.Get(DocumentLine."Document No.", DocumentLine."Line No.");
                    LineVariant := ServiceCrMemoLine;
                    TableCaption := ServiceCrMemoLine.TableCaption();
                end;
            DATABASE::"Sales Shipment Header":
                begin
                    SalesShipmentLine.Get(DocumentLine."Document No.", DocumentLine."Line No.");
                    LineVariant := SalesShipmentLine;
                    TableCaption := SalesShipmentLine.TableCaption();
                end;
            DATABASE::"Transfer Shipment Header":
                begin
                    TransferShipmentLine.Get(DocumentLine."Document No.", DocumentLine."Line No.");
                    LineVariant := TransferShipmentLine;
                    TableCaption := TransferShipmentLine.TableCaption();
                end;
        end;
    end;

    local procedure GetDocTypeTextFromDatabaseId(DatabeseId: Integer): Text
    begin
        case DatabeseId of
            Database::"Sales Invoice Header":
                exit('Sales Invoice');
            Database::"Sales Cr.Memo Header":
                exit('Sales Cr.Memo');
            Database::"Service Invoice Header":
                exit('Service Invoice');
            Database::"Service Cr.Memo Header":
                exit('Service Cr.Memo');
            Database::"Sales Shipment Header":
                exit('Sales Shipment');
            Database::"Transfer Shipment Header":
                exit('Transfer Shipment');
            Database::"Cust. Ledger Entry":
                exit('payment');
        end;
    end;

    local procedure GetNumeroPedimento(TempDocumentLine: Record "Document Line" temporary) NumeroPedimento: Text
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetNumeroPedimento(TempDocumentLine, NumeroPedimento, IsHandled);
        if IsHandled then
            exit(NumeroPedimento);

        exit(TempDocumentLine."Custom Transit Number");
    end;

    local procedure FormatNumeroPedimento(TempDocumentLine: Record "Document Line" temporary): Text
    var
        NumeroPedimento: Text;
    begin
        NumeroPedimento := DelChr(GetNumeroPedimento(TempDocumentLine));
        if NumeroPedimento = '' then
            exit('');

        NumeroPedimento :=
          StrSubstNo(NumeroPedimentoFormatTxt,
            CopyStr(NumeroPedimento, 1, 2), CopyStr(NumeroPedimento, 3, 2), CopyStr(NumeroPedimento, 5, 4), CopyStr(NumeroPedimento, 9, 7));
        exit(NumeroPedimento);
    end;

    local procedure RequestStampOnRoundingError(var DocumentHeaderRecordRef: RecordRef; Prepayment: Boolean; Reverse: Boolean; NewRoundingModel: Option)
    var
        ErrorCode: Code[10];
    begin
        ErrorCode := DocumentHeaderRecordRef.Field(10035).Value();
        // CFDI40108 – El TipoDeComprobante es I,E o N, el importe registrado en el campo no es igual a la suma de los importes de los conceptos registrados.
        // CFDI40110 – El valor registrado en el campo Descuento no es menor o igual que el campo Subtotal.
        // CFDI40111 – El TipoDeComprobante NO es I,E o N, y un concepto incluye el campo descuento.
        // CFDI40119 – El campo Total no corresponde con la suma del subtotal, menos los descuentos aplicables, más las contribuciones recibidas 
        // (impuestos trasladados – federales o locales, derechos, productos, aprovechamientos, aportaciones de seguridad social, contribuciones de mejoras) menos los impuestos retenidos.
        if not (ErrorCode in ['CFDI40108', 'CFDI40110', 'CFDI40111', 'CFDI40119', 'CFDI40167']) then
            exit;

        RoundingModel := NewRoundingModel;
        RequestStamp(DocumentHeaderRecordRef, Prepayment, Reverse);
    end;

    local procedure UpdatePartialPaymentAmounts(var TempDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary; var CustLedgerEntry: Record "Cust. Ledger Entry"; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    var
        PartialPaymentMultiplifier: Decimal;
    begin
        CustLedgerEntry.CalcFields(Amount);
        if CustLedgerEntry.Amount <> 0 then
            PartialPaymentMultiplifier := Abs(TempDetailedCustLedgEntry.Amount / CustLedgerEntry.Amount)
        else
            PartialPaymentMultiplifier := 1;
        if PartialPaymentMultiplifier <> 1 then
            if TempVATAmountLine.FindSet() then
                repeat
                    TempVATAmountLine."VAT Base" *= PartialPaymentMultiplifier;
                    TempVATAmountLine."VAT Amount" *= PartialPaymentMultiplifier;
                    TempVATAmountLine."Amount Including VAT" *= PartialPaymentMultiplifier;
                    TempVATAmountLine.Modify();
                until TempVATAmountLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Shipment Header", 'OnAfterCopyFromTransferHeader', '', false, false)]
    local procedure TransferShipmentHeaderfterCopyFromTransferHeader(var TransferShipmentHeader: Record "Transfer Shipment Header"; TransferHeader: Record "Transfer Header")
    begin
        TransferShipmentHeader."Transit-from Date/Time" := TransferHeader."Transit-from Date/Time";
        TransferShipmentHeader."Transit Hours" := TransferHeader."Transit Hours";
        TransferShipmentHeader."Transit Distance" := TransferHeader."Transit Distance";
        TransferShipmentHeader."Insurer Name" := TransferHeader."Insurer Name";
        TransferShipmentHeader."Insurer Policy Number" := TransferHeader."Insurer Policy Number";
        TransferShipmentHeader."Foreign Trade" := TransferHeader."Foreign Trade";
        TransferShipmentHeader."Vehicle Code" := TransferHeader."Vehicle Code";
        TransferShipmentHeader."Trailer 1" := TransferHeader."Trailer 1";
        TransferShipmentHeader."Trailer 2" := TransferHeader."Trailer 2";
        TransferShipmentHeader."Medical Insurer Name" := TransferHeader."Medical Insurer Name";
        TransferShipmentHeader."Medical Ins. Policy Number" := TransferHeader."Medical Ins. Policy Number";
        TransferShipmentHeader."SAT Weight Unit Of Measure" := TransferHeader."SAT Weight Unit Of Measure";
        TransferShipmentHeader."CFDI Export Code" := TransferHeader."CFDI Export Code";
        TransferShipmentHeader."SAT International Trade Term" := TransferHeader."SAT International Trade Term";
        TransferShipmentHeader."Exchange Rate USD" := TransferHeader."Exchange Rate USD";
        TransferShipmentHeader."SAT Customs Regime" := TransferHeader."SAT Customs Regime";
        TransferShipmentHeader."SAT Transfer Reason" := TransferHeader."SAT Transfer Reason";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Shipment Line", 'OnAfterCopyFromTransferLine', '', false, false)]
    local procedure TransferShipmentLineAfterCopyFromTransferLine(var TransferShipmentLine: Record "Transfer Shipment Line"; TransferLine: Record "Transfer Line")
    begin
        TransferShipmentLine."Custom Transit Number" := TransferLine."Custom Transit Number";
        TransferShipmentLine."SAT Customs Document Type" := TransferLine."SAT Customs Document Type";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnAfterInsertTransShptHeader', '', false, false)]
    local procedure TransferShipmentHeaserInsertCFDIOperators(var TransferHeader: Record "Transfer Header"; var TransferShipmentHeader: Record "Transfer Shipment Header")
    begin
        InsertTransferShipmentCFDITransportOperators(TransferHeader, TransferShipmentHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, 103, 'OnBeforeCustLedgEntryModify', '', false, false)]
    local procedure UpdateCustomerLedgerEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; FromCustLedgEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgEntry.Validate("CFDI Cancellation Reason Code", FromCustLedgEntry."CFDI Cancellation Reason Code");
        CustLedgEntry.Validate("Substitution Entry No.", FromCustLedgEntry."Substitution Entry No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"Sales Inv. Header - Edit", 'OnOnRunOnBeforeTestFieldNo', '', false, false)]
    local procedure UpdateSalesInvHeader(var SalesInvoiceHeader: Record "Sales Invoice Header"; SalesInvoiceHeaderRec: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader."CFDI Cancellation Reason Code" := SalesInvoiceHeaderRec."CFDI Cancellation Reason Code";
        SalesInvoiceHeader."Substitution Document No." := SalesInvoiceHeaderRec."Substitution Document No.";
        SalesInvoiceHeader."Fiscal Invoice Number PAC" := SalesInvoiceHeaderRec."Fiscal Invoice Number PAC";
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"Sales Credit Memo Hdr. - Edit", 'OnBeforeSalesCrMemoHeaderModify', '', false, false)]
    local procedure UpdateSalesCrMemoHeader(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        SalesCrMemoHeader."CFDI Cancellation Reason Code" := FromSalesCrMemoHeader."CFDI Cancellation Reason Code";
        SalesCrMemoHeader."Substitution Document No." := FromSalesCrMemoHeader."Substitution Document No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"Service Inv. Header - Edit", 'OnOnRunOnBeforeTestFieldNo', '', false, false)]
    local procedure UpdateServiceInvHeader(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceInvoiceHeaderRec: Record "Service Invoice Header")
    begin
        ServiceInvoiceHeader."CFDI Cancellation Reason Code" := ServiceInvoiceHeaderRec."CFDI Cancellation Reason Code";
        ServiceInvoiceHeader."Substitution Document No." := ServiceInvoiceHeaderRec."Substitution Document No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"Shipment Header - Edit", 'OnBeforeSalesShptHeaderModify', '', false, false)]
    local procedure UpdateSalesShipmentHeader(var SalesShptHeader: Record "Sales Shipment Header"; FromSalesShptHeader: Record "Sales Shipment Header")
    begin
        SalesShptHeader."CFDI Cancellation Reason Code" := FromSalesShptHeader."CFDI Cancellation Reason Code";
        SalesShptHeader."Substitution Document No." := FromSalesShptHeader."Substitution Document No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterCopyShipToCustomerAddressFieldsFromShipToAddr', '', false, false)]
    local procedure UpdateSATAddressFromShipToAddress(var SalesHeader: Record "Sales Header"; ShipToAddress: Record "Ship-to Address"; xSalesHeader: Record "Sales Header")
    begin
        SalesHeader."SAT Address ID" := ShipToAddress."SAT Address ID";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterCopyShipToCustomerAddressFieldsFromCustomer', '', false, false)]
    local procedure UpdateSATAddressFromCustomer(var SalesHeader: Record "Sales Header"; SellToCustomer: Record Customer; xSalesHeader: Record "Sales Header")
    begin
        SalesHeader."SAT Address ID" := 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNumeroPedimento(TempDocumentLine: Record "Document Line" temporary; var NumberPedimento: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCartaPorteDistinationData(var RFCRemitenteDestinatario: Code[30]; var NumRegIdTrib: Code[30]; var ResidenciaFiscal: Code[10]; DocumentHeader: Record "Document Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRequestStamp(var DocumentHeaderRecordRef: RecordRef)
    begin
    end;
}
