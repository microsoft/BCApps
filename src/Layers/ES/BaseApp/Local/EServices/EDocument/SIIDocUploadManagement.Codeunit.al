// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;
using System;
using System.IO;
using System.Security.Encryption;
using System.Utilities;

codeunit 10752 "SII Doc. Upload Management"
{

    trigger OnRun()
    begin
    end;

    var
        SIISetup: Record "SII Setup";
        SIIXMLCreator: Codeunit "SII XML Creator";
        RequestType: Option InvoiceIssuedRegistration,InvoiceReceivedRegistration,PaymentSentRegistration,PaymentReceivedRegistration,CollectionInCashRegistration;
        NoCertificateErr: Label 'Could not get certificate.';
        NoConnectionErr: Label 'Could not establish connection.';
        NoResponseErr: Label 'Could not get response.';
        NoCustLedgerEntryErr: Label 'Customer Ledger Entry could not be found.';
        NoDetailedCustLedgerEntryErr: Label 'Detailed Customer Ledger Entry could not be found.';
        NoVendLedgerEntryErr: Label 'Vendor Ledger Entry could not be found.';
        NoDetailedVendLedgerEntryErr: Label 'Detailed Vendor Ledger Entry could not be found.';
        CommunicationErr: Label 'Communication error: %1.', Comment = '@1 is the error message.';
        ParseMatchDocumentErr: Label 'Parse error: couldn''t match the documents.';
        CertificateUsedInSIISetupQst: Label 'A certificate is used in the SII Setup. Do you really want to delete the certificate?';
        // fault model labels
        VATSIITok: Label 'VATSIITelemetryCategoryTok', Locked = true;
        BatchSoapRequestMsg: Label 'Sending batch soap request of type %1', Locked = true;
        BatchSoapRequestSuccMsg: Label 'Batch soap request of type %1 successfully executed', Locked = true;
        GeneratingXmlMsg: Label 'Generating xml for document type %1', Locked = true;
        GeneratingXmlSuccMsg: Label 'Xml successfully generated for document type %1', Locked = true;
        GeneratingXmlErrMsg: Label 'Cannot generate xml: %1', Locked = true;
        CannotDownloadRequestXmlErr: Label 'Not possible to download request XML for selected documents because of the following error: %1.', Comment = '%1 = error message';

    local procedure InvokeBatchSoapRequest(SIISession: Record "SII Session"; var TempSIIHistoryBuffer: Record "SII History" temporary; RequestText: Text; RequestType: Option InvoiceIssuedRegistration,InvoiceReceivedRegistration,PaymentSentRegistration,PaymentReceivedRegistration,CollectionInCashRegistration; var ResponseText: Text): Boolean
    var
        CertificateEnabled: Boolean;
        Cert: DotNet X509Certificate2;
        WebRequest: DotNet WebRequest;
        HttpWebRequest: DotNet HttpWebRequest;
        RequestStream: DotNet Stream;
        Encoding: DotNet Encoding;
        ByteArray: DotNet Array;
        Uri: DotNet Uri;
        HttpWebResponse: DotNet HttpWebResponse;
        StatusCode: DotNet HttpStatusCode;
        WebServiceUrl: Text;
        StatusDescription: Text[250];
    begin
        Session.LogMessage('0000CNO', StrSubstNo(BatchSoapRequestMsg, RequestType), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', VATSIITok);

        CertificateEnabled := GetIsolatedCertificate(Cert);
        if not CertificateEnabled then begin
            Session.LogMessage('0000CNP', NoCertificateErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', VATSIITok);
            ProcessBatchResponseCommunicationError(TempSIIHistoryBuffer, NoCertificateErr);
            exit(false);
        end;

        case RequestType of
            RequestType::InvoiceIssuedRegistration:
                WebServiceUrl := SIISetup.InvoicesIssuedEndpointUrl;
            RequestType::InvoiceReceivedRegistration:
                WebServiceUrl := SIISetup.InvoicesReceivedEndpointUrl;
            RequestType::PaymentReceivedRegistration:
                WebServiceUrl := SIISetup.PaymentsReceivedEndpointUrl;
            RequestType::PaymentSentRegistration:
                WebServiceUrl := SIISetup.PaymentsIssuedEndpointUrl;
            RequestType::CollectionInCashRegistration:
                WebServiceUrl := SIISetup.CollectionInCashEndpointUrl;
        end;

        OnInvokeBatchSoapRequestOnBeforeStoreRequestXML(RequestText, RequestType, WebServiceUrl);

        SIISession.StoreRequestXml(RequestText);
        Commit();

        HttpWebRequest := WebRequest.Create(Uri.Uri(WebServiceUrl));
        HttpWebRequest.ClientCertificates.Add(Cert);
        HttpWebRequest.Method := 'POST';
        HttpWebRequest.ContentType := 'application/xml';

        ByteArray := Encoding.UTF8.GetBytes(RequestText);
        HttpWebRequest.ContentLength := ByteArray.Length;
        if not TryCreateRequestStream(HttpWebRequest, RequestStream) then begin
            Session.LogMessage('0000CNQ', NoConnectionErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', VATSIITok);
            ProcessBatchResponseCommunicationError(TempSIIHistoryBuffer, NoConnectionErr);
            exit(false);
        end;

        RequestStream.Write(ByteArray, 0, ByteArray.Length);

        if not TryGetWebResponse(HttpWebRequest, HttpWebResponse) then begin
            Session.LogMessage('0000CNR', NoResponseErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', VATSIITok);
            ProcessBatchResponseCommunicationError(TempSIIHistoryBuffer, NoResponseErr);
            exit(false);
        end;

        StatusCode := HttpWebResponse.StatusCode;
        StatusDescription := HttpWebResponse.StatusDescription;
        ResponseText := ReadHttpResponseAsText(HttpWebResponse);
        OnInvokeBatchSoapRequestOnBeforeStoreResponseXML(ResponseText);
        SIISession.StoreResponseXml(ResponseText);
        OnInvokeBatchSoapRequestOnAfterStoreResponseXML(ResponseText);
        if not StatusCode.Equals(StatusCode.Accepted) and not StatusCode.Equals(StatusCode.OK) then begin
            Session.LogMessage('0000CNS', StrSubstNo(CommunicationErr, StatusDescription), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', VATSIITok);
            ProcessBatchResponseCommunicationError(
              TempSIIHistoryBuffer, StrSubstNo(CommunicationErr, StatusDescription));
            exit(false);
        end;

        Session.LogMessage('0000CNT', StrSubstNo(BatchSoapRequestSuccMsg, RequestType), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', VATSIITok);
        exit(true);
    end;

    [TryFunction]
    local procedure TryCreateRequestStream(HttpWebRequest: DotNet HttpWebRequest; var RequestStream: DotNet Stream)
    begin
        RequestStream := HttpWebRequest.GetRequestStream();
    end;

    [TryFunction]
    local procedure TryGetWebResponse(HttpWebRequest: DotNet HttpWebRequest; var HttpWebResponse: DotNet HttpWebResponse)
    var
        Task: DotNet Task1;
    begin
        Task := HttpWebRequest.GetResponseAsync();
        HttpWebResponse := Task.Result;
    end;

    [NonDebuggable]
    local procedure GetIsolatedCertificate(var Cert: DotNet X509Certificate2): Boolean
    var
        IsolatedCertificate: Record "Isolated Certificate";
        CertificateManagement: Codeunit "Certificate Management";
        DotNet_SecureString: Codeunit DotNet_SecureString;
        DotNet_Array: Codeunit DotNet_Array;
        DotNet_X509KeyStorageFlags: Codeunit DotNet_X509KeyStorageFlags;
        DotNet_X509Certificate2: Codeunit DotNet_X509Certificate2;
        Convert: DotNet Convert;
    begin
        if not IsolatedCertificate.Get(SIISetup."Certificate Code") then
            exit(false);
        CertificateManagement.GetPasswordAsSecureString(DotNet_SecureString, IsolatedCertificate);
        DotNet_Array.SetArray(
            Convert.FromBase64String(CertificateManagement.GetCertAsBase64String(IsolatedCertificate)));
        DotNet_X509KeyStorageFlags.Exportable();
        DotNet_X509Certificate2.X509Certificate2(DotNet_Array, DotNet_SecureString, DotNet_X509KeyStorageFlags);
        DotNet_X509Certificate2.GetX509Certificate2(Cert);
        exit(true);
    end;

    local procedure ReadHttpResponseAsText(HttpWebResponse: DotNet HttpWebResponse) ResponseText: Text
    var
        StreamReader: DotNet StreamReader;
    begin
        StreamReader := StreamReader.StreamReader(HttpWebResponse.GetResponseStream());
        ResponseText := StreamReader.ReadToEnd();
    end;

    procedure DownloadRequestForMultipleDocuments(var SIIHistory: Record "SII History")
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIISession: Record "SII Session";
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        XMLDoc: DotNet XmlDocument;
        OutStream: OutStream;
        IsSupported: Boolean;
        Message: Text;
        FileName: Text;
    begin
        if not SIIHistory.FindSet() then
            exit;

        repeat
            SIIDocUploadState.Get(SIIHistory."Document State Id");
            if not TryGenerateXml(SIIDocUploadState, SIIHistory, XMLDoc, IsSupported, Message) then
                Error(CannotDownloadRequestXmlErr, Message);
        until SIIHistory.Next() = 0;
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(SIISession.XMLTextIndent((XMLDoc.OuterXml)));
        FileName := FileManagement.ServerTempFileName('xml');
        FileManagement.BLOBExportWithEncoding(TempBlob, FileName, true, TEXTENCODING::UTF8);
    end;

    local procedure ExecutePendingRequests(var SIIDocUploadState: Record "SII Doc. Upload State"; var TempSIIHistoryBuffer: Record "SII History" temporary; BatchSubmissions: Boolean)
    var
        SIISession: Record "SII Session";
        XMLDoc: DotNet XmlDocument;
        IsInvokeSoapRequest: Boolean;
    begin
        SIIDocUploadState.FindSet(true);
        PreExecutePendingRequests(SIISession, IsInvokeSoapRequest, not BatchSubmissions);
        repeat
            PreExecutePendingRequests(SIISession, IsInvokeSoapRequest, BatchSubmissions);
            ExecutePendingRequestsPerDocument(SIIDocUploadState, TempSIIHistoryBuffer, XMLDoc, IsInvokeSoapRequest, SIISession.Id);
            PostExecutePendingRequests(SIIDocUploadState, TempSIIHistoryBuffer, SIISession, XMLDoc, IsInvokeSoapRequest, BatchSubmissions);
        until SIIDocUploadState.Next() = 0;
        PostExecutePendingRequests(SIIDocUploadState, TempSIIHistoryBuffer, SIISession, XMLDoc, IsInvokeSoapRequest, not BatchSubmissions);
    end;

    local procedure ExecutePendingRequestsPerDocument(var SIIDocUploadState: Record "SII Doc. Upload State"; var TempSIIHistoryBuffer: Record "SII History" temporary; var XMLDoc: DotNet XmlDocument; var IsInvokeSoapRequest: Boolean; SIISessionId: Integer)
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
        IsSupported: Boolean;
        Message: Text;
    begin
        OnBeforeExecutePendingRequestsPerDocument(SIIDocUploadState, TempSIIHistoryBuffer, XMLDoc, IsInvokeSoapRequest, SIISessionId);
        TempSIIHistoryBuffer.SetRange("Document State Id", SIIDocUploadState.Id);
        if TempSIIHistoryBuffer.FindSet() then
            repeat
                TempSIIHistoryBuffer."Session Id" := SIISessionId;
                if not TryGenerateXml(SIIDocUploadState, TempSIIHistoryBuffer, XMLDoc, IsSupported, Message) then begin
                    DotNetExceptionHandler.Collect();
                    TempSIIHistoryBuffer.Status := TempSIIHistoryBuffer.Status::Failed;
                    TempSIIHistoryBuffer."Error Message" :=
                      CopyStr(DotNetExceptionHandler.GetMessage(), 1, MaxStrLen(TempSIIHistoryBuffer."Error Message"));
                    SIIDocUploadState.Status := SIIDocUploadState.Status::Failed;
                    SIIDocUploadState.Modify();
                end else
                    if not IsSupported then begin
                        TempSIIHistoryBuffer.Status := TempSIIHistoryBuffer.Status::"Not Supported";
                        SIIDocUploadState.Status := SIIDocUploadState.Status::"Not Supported";
                        TempSIIHistoryBuffer."Error Message" := CopyStr(Message, 1, MaxStrLen(TempSIIHistoryBuffer."Error Message"));
                        SIIDocUploadState.Modify();
                    end else
                        IsInvokeSoapRequest := true or IsInvokeSoapRequest;
                TempSIIHistoryBuffer.Modify();
            until TempSIIHistoryBuffer.Next() = 0;
        OnAfterExecutePendingRequestsPerDocument(SIIDocUploadState, TempSIIHistoryBuffer, XMLDoc, IsInvokeSoapRequest, SIISessionId);
    end;

    local procedure PreExecutePendingRequests(var SIISession: Record "SII Session"; var IsInvokeSoapRequest: Boolean; SkipPrePost: Boolean)
    begin
        if SkipPrePost then
            exit;

        SIIXMLCreator.Reset();
        CreateNewSessionRecord(SIISession);
        IsInvokeSoapRequest := false;
    end;

    local procedure PostExecutePendingRequests(var SIIDocUploadState: Record "SII Doc. Upload State"; var TempSIIHistoryBuffer: Record "SII History" temporary; SIISession: Record "SII Session"; XMLDoc: DotNet XmlDocument; IsInvokeSoapRequest: Boolean; SkipPrePost: Boolean)
    var
        ResponseText: Text;
        IsHandled: Boolean;
    begin
        if IsNull(XMLDoc) then
            exit;
        OnBeforePostExecutePendingRequests(SIIDocUploadState, TempSIIHistoryBuffer, SIISession, XMLDoc.OuterXML, IsInvokeSoapRequest, SkipPrePost, IsHandled);
        if IsHandled then
            exit;

        if SkipPrePost then
            exit;

        TempSIIHistoryBuffer.SetRange("Document State Id");
        TempSIIHistoryBuffer.SetRange("Session Id", SIISession.Id);
        TempSIIHistoryBuffer.SetRange(Status, TempSIIHistoryBuffer.Status::Pending);
        if IsInvokeSoapRequest then
            if InvokeBatchSoapRequest(SIISession, TempSIIHistoryBuffer, XMLDoc.OuterXml, RequestType, ResponseText) then
                ParseBatchResponse(SIIDocUploadState, TempSIIHistoryBuffer, ResponseText);

        TempSIIHistoryBuffer.SetRange("Session Id");
        TempSIIHistoryBuffer.SetRange(Status);
    end;

    [Scope('OnPrem')]
    procedure UploadPendingDocuments()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        if not GetAndCheckSetup() then
            exit;

        if SIISetup."Enable Batch Submissions" and (SIISetup."Job Batch Submission Threshold" > 0) then begin
            SetDocStateFilters(SIIDocUploadState, false);
            if SIIDocUploadState.Count < SIISetup."Job Batch Submission Threshold" then
                exit;
        end;

        // Process only automatically-created documents
        UploadDocuments(false);
    end;

    procedure UploadManualDocument()
    begin
        if not GetAndCheckSetup() then
            exit;

        // Process only manually-created documents
        UploadDocuments(true);
    end;

    local procedure UploadDocuments(IsManual: Boolean)
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        TempSIIHistoryBuffer: Record "SII History" temporary;
    begin
        SetDocStateFilters(SIIDocUploadState, IsManual);
        if not SIIDocUploadState.IsEmpty() then begin
            CreateHistoryPendingBuffer(TempSIIHistoryBuffer, IsManual);
            // Customer Invoice
            UploadDocumentsPerTransactionFilter(
              SIIDocUploadState, TempSIIHistoryBuffer, SIIDocUploadState."Document Source"::"Customer Ledger", SIIDocUploadState."Document Type"::Invoice, '');
            // Customer Credit Memo
            UploadDocumentsPerTransactionFilter(
              SIIDocUploadState, TempSIIHistoryBuffer, SIIDocUploadState."Document Source"::"Customer Ledger", SIIDocUploadState."Document Type"::"Credit Memo", '0');
            // Customer Credit Memo Removal
            UploadDocumentsPerTransactionFilter(
              SIIDocUploadState, TempSIIHistoryBuffer, SIIDocUploadState."Document Source"::"Customer Ledger", SIIDocUploadState."Document Type"::"Credit Memo", '1');
            // Customer Payment
            UploadDocumentsPerTransactionFilter(
              SIIDocUploadState, TempSIIHistoryBuffer, SIIDocUploadState."Document Source"::"Detailed Customer Ledger", SIIDocUploadState."Document Type"::Payment, '');
            // Customer Refund
            UploadDocumentsPerTransactionFilter(
              SIIDocUploadState, TempSIIHistoryBuffer, SIIDocUploadState."Document Source"::"Detailed Customer Ledger", SIIDocUploadState."Document Type"::Refund, '');
            // Vendor Invoice
            UploadDocumentsPerTransactionFilter(
              SIIDocUploadState, TempSIIHistoryBuffer, SIIDocUploadState."Document Source"::"Vendor Ledger", SIIDocUploadState."Document Type"::Invoice, '');
            // Vendor Credit Memo
            UploadDocumentsPerTransactionFilter(
              SIIDocUploadState, TempSIIHistoryBuffer, SIIDocUploadState."Document Source"::"Vendor Ledger", SIIDocUploadState."Document Type"::"Credit Memo", '0');
            // Vendor Credit Memo Removal
            UploadDocumentsPerTransactionFilter(
              SIIDocUploadState, TempSIIHistoryBuffer, SIIDocUploadState."Document Source"::"Vendor Ledger", SIIDocUploadState."Document Type"::"Credit Memo", '1');
            // Vendor Payment
            UploadDocumentsPerTransactionFilter(
              SIIDocUploadState, TempSIIHistoryBuffer, SIIDocUploadState."Document Source"::"Detailed Vendor Ledger", SIIDocUploadState."Document Type"::Payment, '');
            // Vendor Refund
            UploadDocumentsPerTransactionFilter(
              SIIDocUploadState, TempSIIHistoryBuffer, SIIDocUploadState."Document Source"::"Detailed Vendor Ledger", SIIDocUploadState."Document Type"::Refund, '');

            SIIDocUploadState.Reset();
            SetDocStateFilters(SIIDocUploadState, IsManual);
            // Collection in cash
            UploadDocumentsPerFilter(SIIDocUploadState, TempSIIHistoryBuffer, SIIDocUploadState."Transaction Type"::"Collection In Cash", false);
            UploadDocumentsPerFilter(SIIDocUploadState, TempSIIHistoryBuffer, SIIDocUploadState."Transaction Type"::"Collection In Cash", true);

            SaveHistoryPendingBuffer(TempSIIHistoryBuffer, IsManual);
        end;
    end;

    local procedure UploadDocumentsPerTransactionFilter(var SIIDocUploadState: Record "SII Doc. Upload State"; var TempSIIHistoryBuffer: Record "SII History" temporary; DocumentSource: Enum "SII Doc. Upload State Document Source"; DocumentType: Enum "SII Doc. Upload State Document Type"; IsCreditMemoRemovalFilter: Text)
    begin
        SIIDocUploadState.SetRange("Document Source", DocumentSource);
        SIIDocUploadState.SetRange("Document Type", DocumentType);
        SIIDocUploadState.SetFilter("Is Credit Memo Removal", IsCreditMemoRemovalFilter);
        UploadDocumentsPerFilter(SIIDocUploadState, TempSIIHistoryBuffer, SIIDocUploadState."Transaction Type"::Regular, false);
        UploadDocumentsPerFilter(SIIDocUploadState, TempSIIHistoryBuffer, SIIDocUploadState."Transaction Type"::Regular, true);
        UploadDocumentsPerFilter(SIIDocUploadState, TempSIIHistoryBuffer, SIIDocUploadState."Transaction Type"::RetryAccepted, false);
        UploadDocumentsPerFilter(SIIDocUploadState, TempSIIHistoryBuffer, SIIDocUploadState."Transaction Type"::RetryAccepted, true);
    end;

    local procedure UploadDocumentsPerFilter(var SIIDocUploadState: Record "SII Doc. Upload State"; var TempSIIHistoryBuffer: Record "SII History" temporary; TransactionType: Option; RetryAccepted: Boolean)
    begin
        SIIDocUploadState.SetRange("Transaction Type", TransactionType);
        SIIDocUploadState.SetRange("Retry Accepted", RetryAccepted);
        if not SIIDocUploadState.IsEmpty() then
            ExecutePendingRequests(
              SIIDocUploadState, TempSIIHistoryBuffer, SIISetup."Enable Batch Submissions");
    end;

    [TryFunction]
    local procedure TryGenerateXml(SIIDocUploadState: Record "SII Doc. Upload State"; SIIHistory: Record "SII History"; var XMLDoc: DotNet XmlDocument; var IsSupported: Boolean; var Message: Text)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        OnBeforeTryGenerateXml(SIIDocUploadState, SIIHistory);

        Session.LogMessage('0000CNU', StrSubstNo(GeneratingXmlMsg, SIIDocUploadState."Document Source"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', VATSIITok);

        SIIXMLCreator.SetSIIVersionNo(SIIDocUploadState."Version No.");
        SIIXMLCreator.SetIsRetryAccepted(SIIDocUploadState."Retry Accepted");
        case SIIDocUploadState."Document Source" of
            SIIDocUploadState."Document Source"::"Customer Ledger":
                begin
                    if SIIDocUploadState."Transaction Type" = SIIDocUploadState."Transaction Type"::"Collection In Cash" then begin
                        CustLedgerEntry.Init();
                        CustLedgerEntry."Customer No." := SIIDocUploadState."CV No.";
                        CustLedgerEntry."Posting Date" := SIIDocUploadState."Posting Date";
                        CustLedgerEntry."Sales (LCY)" := SIIDocUploadState."Total Amount In Cash";
                        RequestType := RequestType::CollectionInCashRegistration;
                    end else begin
                        CustLedgerEntry.SetRange("Entry No.", SIIDocUploadState."Entry No");
                        if not CustLedgerEntry.FindFirst() then begin
                            Session.LogMessage('0000CNV', StrSubstNo(GeneratingXmlErrMsg, NoCustLedgerEntryErr), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', VATSIITok);
                            Error(NoCustLedgerEntryErr);
                        end;
                        RequestType := RequestType::InvoiceIssuedRegistration;
                    end;
                    IsSupported :=
                      SIIXMLCreator.GenerateXml(
                        CustLedgerEntry, XMLDoc, SIIHistory."Upload Type", SIIDocUploadState."Is Credit Memo Removal");
                end;
            SIIDocUploadState."Document Source"::"Vendor Ledger":
                begin
                    VendorLedgerEntry.SetRange("Entry No.", SIIDocUploadState."Entry No");
                    if VendorLedgerEntry.FindFirst() then begin
                        RequestType := RequestType::InvoiceReceivedRegistration;
                        IsSupported :=
                          SIIXMLCreator.GenerateXml(
                            VendorLedgerEntry, XMLDoc, SIIHistory."Upload Type", SIIDocUploadState."Is Credit Memo Removal");
                    end else begin
                        Session.LogMessage('0000CNV', StrSubstNo(GeneratingXmlErrMsg, NoVendLedgerEntryErr), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', VATSIITok);
                        Error(NoVendLedgerEntryErr);
                    end;
                end;
            SIIDocUploadState."Document Source"::"Detailed Customer Ledger":
                begin
                    DetailedCustLedgEntry.SetRange("Entry No.", SIIDocUploadState."Entry No");
                    if DetailedCustLedgEntry.FindFirst() then begin
                        RequestType := RequestType::PaymentReceivedRegistration;
                        IsSupported :=
                          SIIXMLCreator.GenerateXml(
                            DetailedCustLedgEntry, XMLDoc, SIIHistory."Upload Type", SIIDocUploadState."Is Credit Memo Removal");
                    end else begin
                        Session.LogMessage('0000CNV', StrSubstNo(GeneratingXmlErrMsg, NoDetailedCustLedgerEntryErr), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', VATSIITok);
                        Error(NoDetailedCustLedgerEntryErr);
                    end;
                end;
            SIIDocUploadState."Document Source"::"Detailed Vendor Ledger":
                begin
                    DetailedVendorLedgEntry.SetRange("Entry No.", SIIDocUploadState."Entry No");
                    if DetailedVendorLedgEntry.FindFirst() then begin
                        RequestType := RequestType::PaymentSentRegistration;
                        IsSupported :=
                          SIIXMLCreator.GenerateXml(
                            DetailedVendorLedgEntry, XMLDoc, SIIHistory."Upload Type", SIIDocUploadState."Is Credit Memo Removal");
                    end else begin
                        Session.LogMessage('0000CNV', StrSubstNo(GeneratingXmlErrMsg, NoDetailedVendLedgerEntryErr), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', VATSIITok);
                        Error(NoDetailedVendLedgerEntryErr);
                    end;
                end;
        end;

        if not IsSupported then begin
            Message := SIIXMLCreator.GetLastErrorMsg();
            Session.LogMessage('0000CNZ', StrSubstNo(GeneratingXmlErrMsg, SIIXMLCreator.GetLastErrorMsg()), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', VATSIITok);
        end else
            Session.LogMessage('0000CO0', StrSubstNo(GeneratingXmlSuccMsg, SIIDocUploadState."Document Source"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', VATSIITok);

    end;

    local procedure CreateHistoryPendingBuffer(var TempSIIHistoryBuffer: Record "SII History" temporary; IsManual: Boolean)
    var
        SIIHistory: Record "SII History";
    begin
        SIIHistory.SetCurrentKey(Status, "Is Manual");
        SetHistoryFilters(SIIHistory, IsManual);
        if SIIHistory.FindSet() then
            repeat
                TempSIIHistoryBuffer := SIIHistory;
                TempSIIHistoryBuffer.Insert();
            until SIIHistory.Next() = 0;
    end;

    local procedure SaveHistoryPendingBuffer(var TempSIIHistoryBuffer: Record "SII History" temporary; IsManual: Boolean)
    var
        SIIHistory: Record "SII History";
    begin
        TempSIIHistoryBuffer.Reset();
        if TempSIIHistoryBuffer.FindSet() then begin
            SetHistoryFilters(SIIHistory, IsManual);
            if SIIHistory.FindSet(true) then
                repeat
                    SIIHistory := TempSIIHistoryBuffer;
                    SIIHistory.Modify();
                until (SIIHistory.Next() = 0) or (TempSIIHistoryBuffer.Next() = 0);
        end;
    end;

    local procedure SetHistoryFilters(var SIIHistory: Record "SII History"; IsManual: Boolean)
    begin
        SIIHistory.SetRange(Status, SIIHistory.Status::Pending);
        SIIHistory.SetRange("Is Manual", IsManual);
    end;

    local procedure SetDocStateFilters(var SIIDocUploadState: Record "SII Doc. Upload State"; IsManual: Boolean)
    begin
        SIIDocUploadState.SetCurrentKey(Status, "Is Manual");
        SIIDocUploadState.SetRange(Status, SIIDocUploadState.Status::Pending);
        SIIDocUploadState.SetRange("Is Manual", IsManual);

        OnAfterSetDocStateFilters(SIIDocUploadState);
    end;

    local procedure CreateNewSessionRecord(var SIISession: Record "SII Session")
    begin
        Clear(SIISession);
        SIISession.Insert();
    end;

    local procedure ProcessBatchResponseCommunicationError(var TempSIIHistoryBuffer: Record "SII History" temporary; ErrorMessage: Text[250])
    begin
        if TempSIIHistoryBuffer.FindSet() then
            repeat
                TempSIIHistoryBuffer.ProcessResponseCommunicationError(ErrorMessage);
            until TempSIIHistoryBuffer.Next() = 0;
    end;

    local procedure ProcessBatchResponse(var TempSIIHistoryBuffer: Record "SII History" temporary)
    begin
        if TempSIIHistoryBuffer.FindSet() then
            repeat
                TempSIIHistoryBuffer.ProcessResponse();
            until TempSIIHistoryBuffer.Next() = 0;
    end;

    local procedure ParseBatchResponse(var SIIDocUploadState: Record "SII Doc. Upload State"; var TempSIIHistoryBuffer: Record "SII History" temporary; ResponseText: Text)
    var
        TempXMLBuffer: array[2] of Record "XML Buffer" temporary;
        TempSIIHistory: Record "SII History" temporary;
    begin
        TempXMLBuffer[1].LoadFromText(ResponseText);
        TempXMLBuffer[1].SetFilter(Name, 'CSV');
        if TempXMLBuffer[1].FindFirst() then
            TempSIIHistoryBuffer.ModifyAll("CSV Response", TempXMLBuffer[1].Value);
        TempXMLBuffer[1].SetFilter(Name, 'RespuestaLinea');
        if TempXMLBuffer[1].FindSet() then
            repeat
                if SIIDocUploadState."Transaction Type" = SIIDocUploadState."Transaction Type"::"Collection In Cash" then
                    ProcessResponseCollectionInCash(SIIDocUploadState, TempSIIHistoryBuffer, TempXMLBuffer[2], TempXMLBuffer[1]."Entry No.")
                else
                    ProcessResponseDocNo(SIIDocUploadState, TempSIIHistoryBuffer, TempXMLBuffer[2], TempXMLBuffer[1]."Entry No.");
            until TempXMLBuffer[1].Next() = 0
        else begin
            XMLParseErrorCode(TempXMLBuffer[2], TempSIIHistory);
            TempSIIHistoryBuffer.ModifyAll("Error Message", TempSIIHistory."Error Message");
            TempSIIHistoryBuffer.ModifyAll(Status, TempSIIHistory.Status);
            TempSIIHistoryBuffer.SetRange(Status, TempSIIHistory.Status);
            ProcessBatchResponse(TempSIIHistoryBuffer);
        end;
        TempSIIHistoryBuffer.SetRange("Document State Id");

        // update remaining Pending (not matched within XML)
        TempSIIHistoryBuffer.SetRange(Status, TempSIIHistory.Status::Pending);
        if not TempSIIHistoryBuffer.IsEmpty() then begin
            TempSIIHistoryBuffer.ModifyAll("Error Message", ParseMatchDocumentErr);
            TempSIIHistoryBuffer.ModifyAll(Status, TempSIIHistory.Status::Failed);
            ProcessBatchResponse(TempSIIHistoryBuffer);
        end;
    end;

    local procedure ProcessResponseDocNo(var SIIDocUploadState: Record "SII Doc. Upload State"; var TempSIIHistoryBuffer: Record "SII History" temporary; var TempXMLBuffer: Record "XML Buffer" temporary; ParentEntryNo: Integer)
    var
        DocumentNo: Text[35];
        LastDocumentNo: Text[35];
        Found: Boolean;
    begin
        // Use TempXMLBuffer[2] to point the same temporary buffer and not to break TempXMLBuffer[1] cursor position
        DocumentNo := XMLParseDocumentNo(TempXMLBuffer, ParentEntryNo);
        LastDocumentNo := XMLParseLastDocumentNo(TempXMLBuffer, ParentEntryNo);
        if DocumentNo <> '' then begin
            if LastDocumentNo = '' then begin
                if SIIDocUploadState."Document Source" = SIIDocUploadState."Document Source"::"Vendor Ledger" then
                    SIIDocUploadState.SETRANGE("External Document No.", DocumentNo)
                else
                    SIIDocUploadState.SETRANGE("Document No.", DocumentNo);
            end else begin
                SIIDocUploadState.SETRANGE("First Summary Doc. No.", DocumentNo);
                SIIDocUploadState.SETRANGE("Last Summary Doc. No.", LastDocumentNo);
            end;
            Found := SIIDocUploadState.FindFirst();
            if (not Found) and
               (SIIDocUploadState."Document Source" in [SIIDocUploadState."Document Source"::"Customer Ledger",
                                                        SIIDocUploadState."Document Source"::"Vendor Ledger"]) and
                                                       (LastDocumentNo = '')
            then begin
                SIIDocUploadState.SetRange("External Document No.");
                SIIDocUploadState.SetRange("Document No.");
                SIIDocUploadState.SetRange("Corrected Doc. No.", DocumentNo);
                Found := SIIDocUploadState.FindFirst();
            end;
            if Found then begin
                TempSIIHistoryBuffer.SetRange("Document State Id", SIIDocUploadState.Id);
                if TempSIIHistoryBuffer.FindFirst() then begin
                    XMLParseDocumentResponse(TempXMLBuffer, TempSIIHistoryBuffer, ParentEntryNo);
                    TempSIIHistoryBuffer.ProcessResponse();
                end;
            end;
            SIIDocUploadState.SetRange("External Document No.");
            SIIDocUploadState.SetRange("Document No.");
            SIIDocUploadState.SetRange("First Summary Doc. No.");
            SIIDocUploadState.SetRange("Last Summary Doc. No.");
        end;
    end;

    local procedure ProcessResponseCollectionInCash(var SIIDocUploadState: Record "SII Doc. Upload State"; var TempSIIHistoryBuffer: Record "SII History" temporary; var TempXMLBuffer: Record "XML Buffer" temporary; ParentEntryNo: Integer)
    begin
        if XMLParseCustData(TempXMLBuffer, SIIDocUploadState, ParentEntryNo) then begin
            TempSIIHistoryBuffer.SetRange("Document State Id", SIIDocUploadState.Id);
            if TempSIIHistoryBuffer.FindFirst() then begin
                XMLParseDocumentResponse(TempXMLBuffer, TempSIIHistoryBuffer, ParentEntryNo);
                TempSIIHistoryBuffer.ProcessResponse();
            end;
            SIIDocUploadState.SetRange("Posting Date");
            SIIDocUploadState.SetRange("VAT Registration No.");
            SIIDocUploadState.SetRange("CV Name");
        end;
    end;

    local procedure XMLParseDocumentNo(var XMLBuffer: Record "XML Buffer"; ParentEntryNo: Integer): Text[35]
    begin
        XMLBuffer.SetRange("Parent Entry No.", ParentEntryNo);
        XMLBuffer.SetRange(Name, 'IDFactura');
        if XMLBuffer.FindFirst() then begin
            XMLBuffer.SetRange("Parent Entry No.", XMLBuffer."Entry No.");
            XMLBuffer.SetRange(Name, 'NumSerieFacturaEmisor');
            if XMLBuffer.FindFirst() then
                exit(CopyStr(XMLBuffer.Value, 1, 35));
        end;
    end;

    local procedure XMLParseLastDocumentNo(var XMLBuffer: Record "XML Buffer"; ParentEntryNo: Integer): Text[35]
    begin
        XMLBuffer.SetRange("Parent Entry No.", ParentEntryNo);
        XMLBuffer.SetRange(Name, 'IDFactura');
        if XMLBuffer.FindFirst() then begin
            XMLBuffer.SetRange("Parent Entry No.", XMLBuffer."Entry No.");
            XMLBuffer.SetRange(Name, 'NumSerieFacturaEmisorResumenFin');
            if XMLBuffer.FindFirst() then
                exit(COPYSTR(XMLBuffer.Value, 1, 35));
        end;
    end;

    local procedure XMLParseDocumentResponse(var XMLBuffer: Record "XML Buffer"; var SIIHistory: Record "SII History"; ParentEntryNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeXMLParseDocumentResponse(XMLBuffer, SIIHistory, ParentEntryNo, IsHandled);
        if IsHandled then
            exit;

        XMLBuffer.SetRange("Parent Entry No.", ParentEntryNo);
        XMLBuffer.SetFilter(Name, 'EstadoRegistro');
        if XMLBuffer.FindFirst() then
            case XMLBuffer.Value of
                'Incorrecto':
                    begin
                        SIIHistory.Status := SIIHistory.Status::Incorrect;
                        XMLBuffer.SetFilter(Name, 'DescripcionErrorRegistro');
                        if XMLBuffer.FindFirst() then
                            SIIHistory."Error Message" := CopyStr(XMLBuffer.Value, 1, MaxStrLen(SIIHistory."Error Message"));
                    end;
                'Correcto':
                    SIIHistory.Status := SIIHistory.Status::Accepted;
                'AceptadoConErrores':
                    begin
                        SIIHistory.Status := SIIHistory.Status::"Accepted With Errors";
                        XMLBuffer.SetFilter(Name, 'DescripcionErrorRegistro');
                        if XMLBuffer.FindFirst() then
                            SIIHistory."Error Message" := CopyStr(XMLBuffer.Value, 1, MaxStrLen(SIIHistory."Error Message"));
                    end;
                else
                    // something is wrong with the response
                    SIIHistory.Status := SIIHistory.Status::Failed;
            end
        else
            XMLParseErrorCode(XMLBuffer, SIIHistory);
    end;

    local procedure XMLParseCustData(var XMLBuffer: Record "XML Buffer"; var SIIDocUploadState: Record "SII Doc. Upload State"; ParentEntryNo: Integer): Boolean
    var
        Year: Integer;
        VATRegistrationNo: Text;
        CountryRegionCode: Text;
    begin
        if FindXMLBufferByParentEntryAndName(XMLBuffer, ParentEntryNo, 'PeriodoLiquidacion') then begin
            if not FindXMLBufferByParentEntryAndName(XMLBuffer, XMLBuffer."Entry No.", 'Ejercicio') then
                exit(false);
            Evaluate(Year, CopyStr(XMLBuffer.Value, 1, 20));
            SIIDocUploadState.SetRange("Posting Date", DMY2Date(1, 1, Year));
        end;
        if FindXMLBufferByParentEntryAndName(XMLBuffer, ParentEntryNo, 'Contraparte') then begin
            ParentEntryNo := XMLBuffer."Entry No.";
            if FindXMLBufferByParentEntryAndName(XMLBuffer, ParentEntryNo, 'NIF') then begin
                VATRegistrationNo := XMLBuffer.Value;
                if not FindXMLBufferByParentEntryAndName(XMLBuffer, ParentEntryNo, 'NombreRazon') then
                    exit(false);
                SIIDocUploadState.SetRange("VAT Registration No.", VATRegistrationNo);
                SIIDocUploadState.SetRange("CV Name", XMLBuffer.Value);
                exit(SIIDocUploadState.FindFirst())
            end;
            if not FindXMLBufferByParentEntryAndName(XMLBuffer, XMLBuffer."Entry No.", 'IDOtro') then
                exit(false);
            ParentEntryNo := XMLBuffer."Entry No.";
            if not FindXMLBufferByParentEntryAndName(XMLBuffer, ParentEntryNo, 'CodigoPais') then
                exit(false);
            CountryRegionCode := XMLBuffer.Value;
            if not FindXMLBufferByParentEntryAndName(XMLBuffer, ParentEntryNo, 'ID') then
                exit(false);
            SIIDocUploadState.SetRange("VAT Registration No.", XMLBuffer.Value);
            SIIDocUploadState.SetRange("Country/Region Code", CountryRegionCode);
            exit(SIIDocUploadState.FindFirst())
        end;
    end;

    local procedure XMLParseErrorCode(var XMLBuffer: Record "XML Buffer"; var SIIHistory: Record "SII History")
    begin
        XMLBuffer.SetFilter(Name, 'faultcode');
        if XMLBuffer.FindFirst() then
            if StrPos(XMLBuffer.Value, 'Server') > 0 then
                // error is probably on the SII website side
                SIIHistory.Status := SIIHistory.Status::Failed
            else
                // error is probably on our side (XML schema incorrect...)
                SIIHistory.Status := SIIHistory.Status::Incorrect
        else
            // couldn't find the faultcode in the response, assume error on our side
            SIIHistory.Status := SIIHistory.Status::Failed;

        XMLBuffer.SetFilter(Name, 'faultstring');
        if XMLBuffer.FindFirst() then
            SIIHistory."Error Message" := CopyStr(XMLBuffer.Value, 1, MaxStrLen(SIIHistory."Error Message"))
    end;

    local procedure FindXMLBufferByParentEntryAndName(var XMLBuffer: Record "XML Buffer"; ParentEntryNo: Integer; NodeName: Text): Boolean
    begin
        XMLBuffer.SetRange("Parent Entry No.", ParentEntryNo);
        XMLBuffer.SetRange(Name, NodeName);
        exit(XMLBuffer.FindFirst());
    end;

    local procedure GetAndCheckSetup(): Boolean
    begin
        SIISetup.Get();
        exit(SIISetup.Enabled);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Isolated Certificate", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDeleteCertificate(var Rec: Record "Isolated Certificate"; RunTrigger: Boolean)
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not SIISetup.Get() then
            exit;

        if SIISetup."Certificate Code" = '' then
            exit;

        if Rec.Code = SIISetup."Certificate Code" then begin
            if not ConfirmManagement.GetResponseOrDefault(CertificateUsedInSIISetupQst, false) then
                Error('');
            SIISetup.Validate("Certificate Code", '');
            SIISetup.Modify(true);
        end;
    end;

    [NonDebuggable]
    procedure AddCertificateToHttpClient(var HttpClient: HttpClient)
    var
        IsolatedCertificate: Record "Isolated Certificate";
        CertificateManagement: Codeunit "Certificate Management";
    begin
        GetAndCheckSetup();
        if not IsolatedCertificate.Get(SIISetup."Certificate Code") then
            exit;
        HttpClient.AddCertificate(
            CertificateManagement.GetCertAsBase64String(IsolatedCertificate),
            CertificateManagement.GetPasswordAsSecret(IsolatedCertificate));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDocStateFilters(var SIIDocUploadState: Record "SII Doc. Upload State")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterExecutePendingRequestsPerDocument(var SIIDocUploadState: Record "SII Doc. Upload State"; var TempSIIHistoryBuffer: Record "SII History" temporary; var XMLDoc: DotNet XmlDocument; var IsInvokeSoapRequest: Boolean; SIISessionId: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExecutePendingRequestsPerDocument(var SIIDocUploadState: Record "SII Doc. Upload State"; var TempSIIHistoryBuffer: Record "SII History" temporary; var XMLDoc: DotNet XmlDocument; var IsInvokeSoapRequest: Boolean; SIISessionId: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeXMLParseDocumentResponse(var XMLBuffer: Record "XML Buffer"; var SIIHistory: Record "SII History"; ParentEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTryGenerateXml(var SIIDocUploadState: Record "SII Doc. Upload State"; SIIHistory: Record "SII History")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInvokeBatchSoapRequestOnBeforeStoreRequestXML(var RequestText: Text; RequestType: Option InvoiceIssuedRegistration,InvoiceReceivedRegistration,PaymentSentRegistration,PaymentReceivedRegistration,CollectionInCashRegistration; var WebServiceUrl: Text);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostExecutePendingRequests(var SIIDocUploadState: Record "SII Doc. Upload State"; var TempSIIHistoryBuffer: Record "SII History" temporary; SIISession: Record "SII Session"; RequestText: Text; IsInvokeSoapRequest: Boolean; SkipPrePost: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInvokeBatchSoapRequestOnBeforeStoreResponseXML(var ResponseText: Text);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInvokeBatchSoapRequestOnAfterStoreResponseXML(var ResponseText: Text);
    begin
    end;
}

