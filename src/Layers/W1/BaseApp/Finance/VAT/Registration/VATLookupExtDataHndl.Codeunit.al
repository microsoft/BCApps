// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.CRM.Contact;
using Microsoft.Sales.Customer;
using System;
using System.Environment;
using System.Integration;
using System.Reflection;
using System.Telemetry;
using System.Utilities;
using System.Xml;

/// <summary>
/// Handles VAT registration number lookup and validation through external web services (VIES).
/// Manages web service communication, response processing, and result logging for VAT number verification.
/// </summary>
codeunit 248 "VAT Lookup Ext. Data Hndl"
{
    Permissions = TableData "VAT Registration Log" = rimd;
    TableNo = "VAT Registration Log";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        InitVATRegistrationLog(Rec);
        VATRegistrationLog := Rec;

        IsHandled := false;
        OnRunOnBeforeLookupVatRegistrationFromWebService(Rec, VATRegistrationLog, IsHandled);
        if not IsHandled then
            LookupVatRegistrationFromWebService(true);

        OnRunOnAfterLookupVatRegistrationFromWebService(VATRegistrationLog, Rec);

        Rec := VATRegistrationLog;
    end;

    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";

        NamespaceTxt: Label 'urn:ec.europa.eu:taxud:vies:services:checkVat:types', Locked = true;
        VatRegNrValidationWebServiceURLTxt: Label 'http://ec.europa.eu/taxation_customs/vies/services/checkVatService', Locked = true;
        NoVATNoToValidateErr: Label 'Specify the VAT registration number that you want to verify.';
        EUVATRegNoValidationServiceTok: Label 'EUVATRegNoValidationServiceTelemetryCategoryTok', Locked = true;
        ValidationSuccessfulMsg: Label 'The VAT reg. no. validation was successful', Locked = true;
        ValidationFailureMsg: Label 'The VAT reg. no. validation failed. Http request failure', Locked = true;
        ResponseTooLargeErr: Label 'The response from the EU VAT Registration No. validation service (VIES) exceeded the maximum allowed size and was rejected.';
        ResponseTooLargeMsg: Label 'The VAT reg. no. validation failed. The response exceeded the maximum allowed size.', Locked = true;
        ResponseIntegrityErr: Label 'The response from the EU VAT Registration No. validation service (VIES) did not match the requested identifiers and was rejected.';
        ResponseIntegrityMsg: Label 'The VAT reg. no. validation failed. The response identifiers did not match the request.', Locked = true;
        SecurityAuditResponseTooLargeTxt: Label 'The EU VAT Registration No. validation service (VIES) returned a response that exceeded the maximum allowed size.', Locked = true;
        SecurityAuditResponseIntegrityTxt: Label 'The EU VAT Registration No. validation service (VIES) returned a response that did not match the requested VAT registration number.', Locked = true;
        BlockedEndpointErr: Label 'The VAT registration service endpoint must be an external address. Internal, private, loopback, or link-local addresses are not allowed.';
        OpenVATRegServiceSetupTxt: Label 'Open the EU VAT Registration No. Validation Service Setup';
        BlockedEndpointMsg: Label 'The VAT reg. no. validation failed. The configured service endpoint targets an internal address and was rejected.', Locked = true;
        SecurityAuditBlockedEndpointTxt: Label 'The EU VAT Registration No. validation service (VIES) endpoint was rejected because it targets an internal address.', Locked = true;
        CountryCodePathTxt: Label 'descendant::vat:countryCode', Locked = true;
        VatNumberPathTxt: Label 'descendant::vat:vatNumber', Locked = true;
        VATRegistrationURL: Text;

    local procedure LookupVatRegistrationFromWebService(ShowErrors: Boolean)
    var
        TempBlobRequestBody: Codeunit "Temp Blob";
        SuppressCommit: Boolean;
    begin
        SendRequestToVatRegistrationService(TempBlobRequestBody, ShowErrors);

        InsertLogEntry(TempBlobRequestBody);

        SuppressCommit := false;
        OnLookupVatRegistrationFromWebServiceOnAfterResponseLogRecordingAndBeforeCommit(VATRegistrationLog, ShowErrors, SuppressCommit);
        if not SuppressCommit then
            Commit();
    end;

    local procedure SendRequestToVatRegistrationService(var TempBlobBody: Codeunit "Temp Blob"; ShowErrors: Boolean)
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        SOAPWebServiceRequestMgt: Codeunit "SOAP Web Service Request Mgt.";
        ResponseInStream: InStream;
        InStream: InStream;
        ResponseOutStream: OutStream;
        IsHandled: Boolean;
        BlankSecretText: SecretText;
    begin
        VATRegistrationURL := VATRegNoSrvConfig.GetVATRegNoURL();
        CheckServiceEndpointAllowed(VATRegistrationURL);

        if VATRegistrationLog."VAT Registration No." = '' then
            Error(NoVATNoToValidateErr);

        PrepareSOAPRequestBody(TempBlobBody);

        TempBlobBody.CreateInStream(InStream);
        SOAPWebServiceRequestMgt.SetGlobals(InStream, VATRegistrationURL, '', BlankSecretText);
        SOAPWebServiceRequestMgt.DisableHttpsCheck();
        SOAPWebServiceRequestMgt.SetTimeout(60000);
        SOAPWebServiceRequestMgt.SetContentType('text/xml;charset=utf-8');

        OnSendRequestToVatRegistrationServiceOnBeforeSendRequestToWebService(SOAPWebServiceRequestMgt, TempBlobBody);
        if SOAPWebServiceRequestMgt.SendRequestToWebService() then begin
            SOAPWebServiceRequestMgt.GetResponseContent(ResponseInStream);

            TempBlobBody.CreateOutStream(ResponseOutStream);
            CopyStream(ResponseOutStream, ResponseInStream);

            CheckResponseSize(TempBlobBody);

            Session.LogMessage('0000C3Q', ValidationSuccessfulMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EUVATRegNoValidationServiceTok);
        end else begin
            Session.LogMessage('0000C4S', ValidationFailureMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EUVATRegNoValidationServiceTok);
            IsHandled := false;
            OnSendRequestToVATRegistrationServiceBeforeShowErrors(VATRegistrationLog, IsHandled);
            if not IsHandled then
                if ShowErrors then
                    SOAPWebServiceRequestMgt.ProcessFaultResponse('');
        end;
    end;

    local procedure PrepareSOAPRequestBody(var TempBlob: Codeunit "Temp Blob")
    var
        Customer: Record Customer;
        VATRegNoSrvTemplate: Record "VAT Reg. No. Srv. Template";
        XMLDOMMgt: Codeunit "XML DOM Management";
        RecordRef: RecordRef;
        BodyContentInputStream: InStream;
        BodyContentOutputStream: OutStream;
        BodyContentXmlDoc: DotNet XmlDocument;
        EnvelopeXmlNode: DotNet XmlNode;
        CreatedXmlNode: DotNet XmlNode;
        AccountName: Text;
        AccountStreet: Text;
        AccountCity: Text;
        AccountPostCode: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrepareSOAPRequestBody(TempBlob, VATRegistrationLog, IsHandled);
        if IsHandled then
            exit;

        TempBlob.CreateInStream(BodyContentInputStream);
        BodyContentXmlDoc := BodyContentXmlDoc.XmlDocument();

        XMLDOMMgt.AddRootElementWithPrefix(BodyContentXmlDoc, 'checkVatApprox', '', NamespaceTxt, EnvelopeXmlNode);
        XMLDOMMgt.AddElement(EnvelopeXmlNode, 'countryCode', VATRegistrationLog.GetCountryCode(), NamespaceTxt, CreatedXmlNode);
        XMLDOMMgt.AddElement(EnvelopeXmlNode, 'vatNumber', VATRegistrationLog.GetVATRegNo(), NamespaceTxt, CreatedXmlNode);
        XMLDOMMgt.AddElement(
          EnvelopeXmlNode, 'requesterCountryCode', VATRegistrationLog.GetCountryCode(), NamespaceTxt, CreatedXmlNode);
        XMLDOMMgt.AddElement(
          EnvelopeXmlNode, 'requesterVatNumber', VATRegistrationLog.GetVATRegNo(), NamespaceTxt, CreatedXmlNode);

        InitializeVATRegistrationLog(VATRegistrationLog);

        if VATRegistrationLog.GetAccountRecordRef(RecordRef) then begin
            AccountName := GetField(RecordRef, Customer.FieldName(Name));
            AccountStreet := GetField(RecordRef, Customer.FieldName(Address));
            AccountPostCode := GetField(RecordRef, Customer.FieldName("Post Code"));
            AccountCity := GetField(RecordRef, Customer.FieldName(City));
            OnPrepareSOAPRequestBodyOnBeforeSetAccountDetails(RecordRef, VATRegistrationLog, AccountName, AccountStreet, AccountCity, AccountPostCode);
            VATRegistrationLog.SetAccountDetails(AccountName, AccountStreet, AccountCity, AccountPostCode);
        end;

        VATRegistrationLog.CheckGetTemplate(VATRegNoSrvTemplate);
        if VATRegNoSrvTemplate."Validate Name" then
            XMLDOMMgt.AddElement(EnvelopeXmlNode, 'traderName', AccountName, NamespaceTxt, CreatedXmlNode);
        if VATRegNoSrvTemplate."Validate Street" then
            XMLDOMMgt.AddElement(EnvelopeXmlNode, 'traderStreet', AccountStreet, NamespaceTxt, CreatedXmlNode);
        if VATRegNoSrvTemplate."Validate City" then
            XMLDOMMgt.AddElement(EnvelopeXmlNode, 'traderCity', AccountCity, NamespaceTxt, CreatedXmlNode);
        if VATRegNoSrvTemplate."Validate Post Code" then
            XMLDOMMgt.AddElement(EnvelopeXmlNode, 'traderPostcode', AccountPostCode, NamespaceTxt, CreatedXmlNode);

        Clear(TempBlob);
        TempBlob.CreateOutStream(BodyContentOutputStream);
        BodyContentXmlDoc.Save(BodyContentOutputStream);
    end;

    local procedure InitializeVATRegistrationLog(var VATRegistrationLog: Record "VAT Registration Log")
    begin
        VATRegistrationLog."Verified Name" := '';
        VATRegistrationLog."Verified City" := '';
        VATRegistrationLog."Verified Street" := '';
        VATRegistrationLog."Verified Postcode" := '';
        VATRegistrationLog."Verified Address" := '';
        VATRegistrationLog.Template := '';
        VATRegistrationLog."Details Status" := VATRegistrationLog."Details Status"::"Not Verified";
    end;

    local procedure InsertLogEntry(TempBlobRequestBody: Codeunit "Temp Blob")
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLDocOut: DotNet XmlDocument;
        InStream: InStream;
    begin
        TempBlobRequestBody.CreateInStream(InStream);
        XMLDOMManagement.LoadXMLDocumentFromInStream(InStream, XMLDocOut);

        ValidateResponseIntegrity(VATRegistrationLog, XMLDocOut, NamespaceTxt);

        VATRegistrationLogMgt.LogVerification(VATRegistrationLog, XMLDocOut, NamespaceTxt);
    end;

    /// <summary>
    /// Rejects VIES responses that exceed the maximum expected size, protecting downstream
    /// XML parsing from abnormally large or malicious payloads received over the unauthenticated service.
    /// </summary>
    /// <param name="TempBlob">Temp blob holding the raw response content received from the VIES service.</param>
    local procedure CheckResponseSize(var TempBlob: Codeunit "Temp Blob")
    var
        AuditLog: Codeunit "Audit Log";
    begin
        if TempBlob.Length() <= GetMaxResponseSize() then
            exit;

        AuditLog.LogAuditMessage(SecurityAuditResponseTooLargeTxt, SecurityOperationResult::Failure, AuditCategory::Authorization, 4, 0); // 4, 0 = AuditMessageOperation / AuditMessageOperationResult (standard security-audit codes; also routes the entry to Purview).
        Session.LogMessage('0000VEQ', ResponseTooLargeMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', EUVATRegNoValidationServiceTok);
        Clear(TempBlob);
        ThrowInternalError(ResponseTooLargeErr);
    end;

    /// <summary>
    /// Validates the integrity of a VIES response before its content is trusted.
    /// When the response echoes the country code or VAT registration number, the echoed value must match
    /// what was requested, so a swapped or unrelated response received over the unauthenticated service is rejected.
    /// Responses that do not echo an identifier are left to the existing verification logic and are not rejected here,
    /// so legitimate responses that simply omit those fields are never blocked.
    /// </summary>
    /// <param name="RecVATRegistrationLog">The VAT registration log entry containing the requested country code and VAT number.</param>
    /// <param name="XMLDoc">The parsed VIES response document.</param>
    /// <param name="Namespace">The VIES XML namespace used to resolve response nodes.</param>
    internal procedure ValidateResponseIntegrity(var RecVATRegistrationLog: Record "VAT Registration Log"; XMLDoc: DotNet XmlDocument; Namespace: Text)
    var
        AuditLog: Codeunit "Audit Log";
        ResponseCountryCode: Text;
        ResponseVATNumber: Text;
    begin
        if IsNull(XMLDoc) then
            exit;
        if IsNull(XMLDoc.DocumentElement) then
            exit;

        ResponseCountryCode := ExtractResponseValue(XMLDoc, CountryCodePathTxt, Namespace);
        ResponseVATNumber := ExtractResponseValue(XMLDoc, VatNumberPathTxt, Namespace);

        // Integrity (validate-if-present): only reject when an echoed identifier is present and contradicts the request.
        if ((ResponseCountryCode <> '') and (NormalizeIdentifier(ResponseCountryCode) <> NormalizeIdentifier(RecVATRegistrationLog.GetCountryCode()))) or
           ((ResponseVATNumber <> '') and (NormalizeIdentifier(ResponseVATNumber) <> NormalizeIdentifier(RecVATRegistrationLog.GetVATRegNo())))
        then begin
            AuditLog.LogAuditMessage(SecurityAuditResponseIntegrityTxt, SecurityOperationResult::Failure, AuditCategory::Authorization, 4, 0);
            Session.LogMessage('0000VES', ResponseIntegrityMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', EUVATRegNoValidationServiceTok);
            ThrowInternalError(ResponseIntegrityErr);
        end;
    end;

    local procedure ExtractResponseValue(XMLDoc: DotNet XmlDocument; Xpath: Text; Namespace: Text): Text
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        FoundXmlNode: DotNet XmlNode;
    begin
        if not XMLDOMMgt.FindNodeWithNamespace(XMLDoc.DocumentElement, Xpath, 'vat', Namespace, FoundXmlNode) then
            exit('');
        exit(FoundXmlNode.InnerText);
    end;

    local procedure NormalizeIdentifier(Value: Text): Text
    begin
        Value := UpperCase(Value);
        exit(DelChr(Value, '=', DelChr(Value, '=', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789')));
    end;

    local procedure GetMaxResponseSize(): Integer
    begin
        // A single checkVatApprox response is one company record (typically < 2 KB incl. SOAP envelope).
        // 64 KB leaves ample headroom for long trader details while still rejecting abnormally large payloads.
        exit(65536);
    end;

    local procedure ThrowInternalError(MessageText: Text)
    var
        ErrInfo: ErrorInfo;
    begin
        // The failure is a non-actionable, service-side condition from the unauthenticated VIES service; the specific
        // reason is already captured in telemetry and the security audit, so surface it as an internal error.
        ErrInfo.Message := MessageText;
        ErrInfo.DataClassification := DataClassification::SystemMetadata;
        ErrInfo.ErrorType := ErrorType::Internal;
        Error(ErrInfo);
    end;

    local procedure CheckServiceEndpointAllowed(ServiceUrl: Text)
    var
        EnvironmentInformation: Codeunit "Environment Information";
        AuditLog: Codeunit "Audit Log";
        Uri: Codeunit Uri;
        BlockedEndpointErrInfo: ErrorInfo;
        Host: Text;
    begin
        // SSRF mitigation: the service endpoint is an admin-configurable setup value. Online (SaaS), reject internal/
        // private/loopback targets so the setup cannot redirect this server-side call to an internal address. On-prem
        // admins control their own network egress (e.g. internal proxies), so no restriction is applied there. VIES is
        // http by design, so the scheme is not restricted.
        if not EnvironmentInformation.IsSaaS() then
            exit;
        if not TryInitUri(Uri, ServiceUrl) then
            exit; // a malformed URL is handled by the existing send/fault path
        Host := LowerCase(Uri.GetHost());
        if Host = '' then
            exit;
        if not IsInternalHost(Host) then
            exit;

        AuditLog.LogAuditMessage(SecurityAuditBlockedEndpointTxt, SecurityOperationResult::Failure, AuditCategory::Authorization, 4, 0);
        Session.LogMessage('0000VF3', BlockedEndpointMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', EUVATRegNoValidationServiceTok);
        // Rejecting the configured endpoint is a recoverable setup problem, so make the error navigate to the setup page.
        BlockedEndpointErrInfo.Message := BlockedEndpointErr;
        BlockedEndpointErrInfo.DataClassification := DataClassification::SystemMetadata;
        BlockedEndpointErrInfo.PageNo := Page::"VAT Registration Config";
        BlockedEndpointErrInfo.AddNavigationAction(OpenVATRegServiceSetupTxt);
        Error(BlockedEndpointErrInfo);
    end;

    [TryFunction]
    local procedure TryInitUri(var Uri: Codeunit Uri; Url: Text)
    begin
        Uri.Init(Url);
    end;

    local procedure IsInternalHost(Host: Text): Boolean
    begin
        // Strip IPv6 literal brackets so bracketed forms (e.g. [::ffff:127.0.0.1]) are checked the same as bare hosts.
        Host := DelChr(Host, '=', '[]');
        if Host in ['localhost', '127.0.0.1', '::1'] then
            exit(true);

        if Host.Contains(':') then begin
            // IPv4-mapped IPv6 literal (::ffff:127.0.0.1): re-check the embedded IPv4 address.
            if Host.StartsWith('::ffff:') then
                exit(IsInternalHost(CopyStr(Host, 8)));
            // IPv6 literal: unique-local (fc00::/7 -> fc/fd) and link-local (fe80::/10 -> fe8/fe9/fea/feb).
            if Host.StartsWith('fc') or Host.StartsWith('fd') then
                exit(true);
            if Host.StartsWith('fe8') or Host.StartsWith('fe9') or Host.StartsWith('fea') or Host.StartsWith('feb') then
                exit(true);
            exit(false);
        end;

        // IPv4 loopback (127.0.0.0/8), link-local incl. cloud IMDS (169.254.0.0/16), and RFC1918 private ranges.
        if Host.StartsWith('127.') then
            exit(true);
        if Host.StartsWith('169.254.') then
            exit(true);
        if Host.StartsWith('10.') then
            exit(true);
        if Host.StartsWith('192.168.') then
            exit(true);
        exit(IsPrivate172Range(Host));
    end;

    local procedure IsPrivate172Range(Host: Text): Boolean
    var
        Octets: List of [Text];
        SecondOctet: Integer;
    begin
        // Private range 172.16.0.0 - 172.31.255.255.
        if not Host.StartsWith('172.') then
            exit(false);
        Octets := Host.Split('.');
        if Octets.Count() < 2 then
            exit(false);
        if not Evaluate(SecondOctet, Octets.Get(2)) then
            exit(false);
        exit((SecondOctet >= 16) and (SecondOctet <= 31));
    end;

    /// <summary>
    /// Retrieves the default URL for the VAT registration number validation web service (VIES).
    /// </summary>
    /// <returns>Default web service URL for VAT number validation</returns>
    procedure GetVATRegNrValidationWebServiceURL(): Text[250]
    begin
        exit(VatRegNrValidationWebServiceURLTxt);
    end;

    local procedure GetField(var RecordRef: RecordRef; FieldName: Text) Result: Text;
    var
        DataTypeManagement: Codeunit "Data Type Management";
        FieldRef: FieldRef;
    begin
        if DataTypeManagement.FindFieldByName(RecordRef, FieldRef, FieldName) then
            Result := FieldRef.Value();
    end;

    local procedure InitVATRegistrationLog(var NewVATRegistrationLog: Record "VAT Registration Log")
    begin
        if NewVATRegistrationLog."Entry No." <> 0 then
            exit;

        InitForContactVATRegistrationLog(NewVATRegistrationLog);
    end;

    local procedure InitForContactVATRegistrationLog(var NewVATRegistrationLog: Record "VAT Registration Log")
    var
        Contact: Record Contact;
        AccountNoFilter: Text;
    begin
        if Format(NewVATRegistrationLog.GetFilter("Account Type")) <> Format(NewVATRegistrationLog."Account Type"::Contact) then
            exit;

        AccountNoFilter := NewVATRegistrationLog.GetFilter("Account No.");

        if Contact.Get(AccountNoFilter) then
            NewVATRegistrationLog.InitVATRegLog(
                NewVATRegistrationLog,
                Contact."Country/Region Code",
                NewVATRegistrationLog."Account Type"::Contact.AsInteger(),
                Contact."No.",
                Contact."VAT Registration No.");
    end;

    /// <summary>
    /// Integration event raised after completing VAT registration lookup from web service.
    /// Enables custom processing of validation results and log record finalization.
    /// </summary>
    /// <param name="VATRegistrationLog">VAT registration log with validation results from web service</param>
    /// <param name="RecVATRegistrationLog">Original VAT registration log record being processed</param>
    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterLookupVatRegistrationFromWebService(var VATRegistrationLog: Record "VAT Registration Log"; var RecVATRegistrationLog: Record "VAT Registration Log")
    begin
    end;

    /// <summary>
    /// Integration event raised before sending request to VAT registration web service.
    /// Enables custom modification of SOAP request configuration and body content.
    /// </summary>
    /// <param name="SOAPWebServiceRequestMgt">SOAP web service request management object for configuration</param>
    /// <param name="TempBlobBody">Request body content that will be sent to the web service</param>
    [IntegrationEvent(false, false)]
    local procedure OnSendRequestToVatRegistrationServiceOnBeforeSendRequestToWebService(var SOAPWebServiceRequestMgt: Codeunit "SOAP Web Service Request Mgt."; var TempBlobBody: Codeunit "Temp Blob")
    begin
    end;

    /// <summary>
    /// Integration event raised before displaying validation errors to allow custom error handling.
    /// Enables custom error processing and messaging when VAT registration service validation fails.
    /// </summary>
    /// <param name="VATRegistrationLog">VAT registration log entry with validation failure information</param>
    /// <param name="IsHandled">Set to true to skip standard error display processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnSendRequestToVATRegistrationServiceBeforeShowErrors(var VATRegistrationLog: Record "VAT Registration Log"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before setting account details in SOAP request body.
    /// Enables custom modification of account name, street, city, and post code values sent to VAT service.
    /// </summary>
    /// <param name="RecordRef">Record reference containing the account data being validated</param>
    /// <param name="VATRegistrationLog">VAT registration log entry being processed</param>
    /// <param name="AccountName">Account name value to be included in validation request</param>
    /// <param name="AccountStreet">Account street address to be included in validation request</param>
    /// <param name="AccountCity">Account city to be included in validation request</param>
    /// <param name="AccountPostCode">Account postal code to be included in validation request</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareSOAPRequestBodyOnBeforeSetAccountDetails(var RecordRef: RecordRef; var VATRegistrationLog: Record "VAT Registration Log"; var AccountName: Text; var AccountStreet: Text; var AccountCity: Text; var AccountPostCode: Text)
    begin
    end;

    /// <summary>
    /// Integration event raised after web service response logging and before database commit.
    /// Enables custom transaction control and additional processing before finalizing validation results.
    /// </summary>
    /// <param name="VATRegistrationLog">VAT registration log with validation results to be committed</param>
    /// <param name="ShowErrors">Indicates whether error messages should be displayed to user</param>
    /// <param name="SuppressCommit">Set to true to prevent automatic database commit</param>
    [IntegrationEvent(false, false)]
    local procedure OnLookupVatRegistrationFromWebServiceOnAfterResponseLogRecordingAndBeforeCommit(VATRegistrationLog: Record "VAT Registration Log"; ShowErrors: Boolean; var SuppressCommit: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before starting VAT registration lookup from web service.
    /// Enables custom pre-processing and validation logic before web service communication.
    /// </summary>
    /// <param name="VATRegistrationLogRec">Original VAT registration log record parameter</param>
    /// <param name="VATRegistrationLog">Working VAT registration log record for validation</param>
    /// <param name="IsHandled">Set to true to skip standard web service lookup processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeLookupVatRegistrationFromWebService(var VATRegistrationLogRec: Record "VAT Registration Log"; var VATRegistrationLog: Record "VAT Registration Log"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before preparing SOAP request body for VAT validation.
    /// Enables complete custom request body preparation and web service communication logic.
    /// </summary>
    /// <param name="TempBlob">Temporary blob for storing custom SOAP request body content</param>
    /// <param name="VATRegistrationLog">VAT registration log entry containing validation parameters</param>
    /// <param name="IsHandled">Set to true to skip standard SOAP request body preparation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareSOAPRequestBody(var TempBlob: Codeunit "Temp Blob"; VATRegistrationLog: Record "VAT Registration Log"; var IsHandled: Boolean)
    begin
    end;

}

