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
        RegisterAndCheckVIESCallQuota();

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
        DailyQuotaExceededErr: Label 'VAT registration number validation against the EU VIES service has reached the daily limit for this environment. Try again tomorrow, and avoid verifying VAT registration numbers in bulk.';
        DailyQuotaReachedMsg: Label 'The daily EU VAT reg. no. validation limit was reached for this environment.', Locked = true;
        SecurityAuditDailyQuotaExceededTxt: Label 'An EU VAT Registration No. validation service (VIES) lookup was blocked because the environment reached its daily lookup limit.', Locked = true;
        VIESCallQuotaKeyTok: Label 'VATRegNoLookupDailyCallQuota', Locked = true;
        ResponseTooLargeErr: Label 'The response from the EU VAT Registration No. validation service (VIES) exceeded the maximum allowed size and was rejected.';
        ResponseTooLargeMsg: Label 'The VAT reg. no. validation failed. The response exceeded the maximum allowed size.', Locked = true;
        SecurityAuditResponseTooLargeTxt: Label 'The EU VAT Registration No. validation service (VIES) returned a response that exceeded the maximum allowed size.', Locked = true;
        VATRegistrationURL: Text;
        QuotaTestOverride: Boolean;
        QuotaTestEnforced: Boolean;
        QuotaTestMaxDailyCallCount: Integer;

    local procedure RegisterAndCheckVIESCallQuota()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        AuditLog: Codeunit "Audit Log";
        WindowDate: Date;
        CallCount: Integer;
    begin
        // The unauthenticated EU VIES service deny-lists the shared outbound IP address of a cloud app service
        // when it receives high-volume validation, which then affects every co-located tenant on that address.
        // Cap the number of VIES lookups per tenant per day so a single tenant cannot flood VIES - from any
        // session type (interactive, background or API) and from either the Base Application or a per-tenant
        // extension that reuses this codeunit - and get the shared address deny-listed. Because the counter is
        // read/written here (Base Application code), it lives in the Base Application's Isolated Storage, so all
        // callers share one tenant-wide counter that no extension can read or reset. Enforced online (SaaS) only;
        // on-prem tenants own their own outbound address and only affect themselves.
        if not EnvironmentInformation.IsSaaS() then
            exit;

        ReadVIESCallQuota(WindowDate, CallCount);

        // Reset the counter at the start of a new (UTC) day.
        if WindowDate <> Today() then begin
            WindowDate := Today();
            CallCount := 0;
        end;

        // Block once the daily limit is reached. Blocked calls are not counted (they never reach the service).
        if CallCount >= GetMaxDailyCallCount() then
            if IsDailyQuotaEnforced() then begin
                // 4, 0 = AuditMessageOperation / AuditMessageOperationResult (standard security-audit codes; also routes the entry to Purview).
                AuditLog.LogAuditMessage(SecurityAuditDailyQuotaExceededTxt, SecurityOperationResult::Failure, AuditCategory::Authorization, 4, 0);
                Error(DailyQuotaExceededErr);
            end;

        CallCount += 1;

        // Emit one telemetry signal per environment per day, on the call that reaches the limit.
        if CallCount = GetMaxDailyCallCount() then
            Session.LogMessage('0000VL7', DailyQuotaReachedMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', EUVATRegNoValidationServiceTok);

        // Persist and commit the count before the outbound request, so it is durable regardless of the outer
        // transaction outcome and so no database lock is held while waiting for the (potentially slow) response.
        WriteVIESCallQuota(WindowDate, CallCount);
        Commit();
    end;

    local procedure ReadVIESCallQuota(var WindowDate: Date; var CallCount: Integer)
    var
        StoredValue: Text;
        ValueParts: List of [Text];
    begin
        WindowDate := 0D;
        CallCount := 0;
        if not IsolatedStorage.Get(VIESCallQuotaKeyTok, DataScope::Module, StoredValue) then
            exit;
        ValueParts := StoredValue.Split('|');
        if ValueParts.Count() < 2 then
            exit;
        Evaluate(WindowDate, ValueParts.Get(1), 9); // 9 = XML/culture-invariant format
        Evaluate(CallCount, ValueParts.Get(2));
    end;

    local procedure WriteVIESCallQuota(WindowDate: Date; CallCount: Integer)
    begin
        // Stored as "<yyyy-MM-dd>|<count>" in the Base Application's module-scoped Isolated Storage (tenant-wide,
        // not accessible to other extensions). Module scope is intentional: the daily cap is per environment,
        // aggregated across companies, because the shared outbound address is per environment.
        IsolatedStorage.Set(VIESCallQuotaKeyTok, Format(WindowDate, 0, 9) + '|' + Format(CallCount), DataScope::Module);
    end;

    local procedure GetMaxDailyCallCount(): Integer
    begin
        if QuotaTestOverride then
            exit(QuotaTestMaxDailyCallCount);
        // Legitimate use is < ~200 lookups per tenant per day (99th percentile). 2000 leaves generous headroom
        // while staying roughly 10x below the daily volume at which VIES deny-lists a shared outbound address.
        exit(2000);
    end;

    local procedure IsDailyQuotaEnforced(): Boolean
    begin
        if QuotaTestOverride then
            exit(QuotaTestEnforced);
        // Log-only during initial rollout: telemetry is emitted when the limit is reached, but lookups are not
        // blocked yet. Set to true to enforce the cap once telemetry confirms no legitimate tenant reaches it.
        exit(false);
    end;

    // The following members exist only so the automated tests can exercise the daily-quota decision logic
    // without calling the external VIES service. They are internal, so the Base Application test libraries can
    // reach them but per-tenant extensions cannot influence or bypass the quota.
    internal procedure SetVIESCallQuotaTestState(EnforceQuota: Boolean; MaxDailyCallCount: Integer)
    begin
        QuotaTestOverride := true;
        QuotaTestEnforced := EnforceQuota;
        QuotaTestMaxDailyCallCount := MaxDailyCallCount;
    end;

    internal procedure InvokeVIESCallQuotaForTest()
    begin
        RegisterAndCheckVIESCallQuota();
    end;

    internal procedure SeedVIESCallQuotaForTest(WindowDate: Date; CallCount: Integer)
    begin
        WriteVIESCallQuota(WindowDate, CallCount);
    end;

    internal procedure GetVIESCallCountForTest() CallCount: Integer
    var
        WindowDate: Date;
    begin
        ReadVIESCallQuota(WindowDate, CallCount);
        if WindowDate <> Today() then
            exit(0);
    end;

    internal procedure ClearVIESCallQuotaForTest()
    begin
        if IsolatedStorage.Contains(VIESCallQuotaKeyTok, DataScope::Module) then
            IsolatedStorage.Delete(VIESCallQuotaKeyTok, DataScope::Module);
    end;

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

        VATRegistrationLogMgt.LogVerification(VATRegistrationLog, XMLDocOut, NamespaceTxt);
    end;

    /// <summary>
    /// Rejects VIES responses that exceed the maximum expected size, protecting downstream
    /// XML parsing from abnormally large or malicious payloads received over the unauthenticated service.
    /// </summary>
    /// <param name="TempBlob">Temp blob holding the raw response content received from the VIES service.</param>
    internal procedure CheckResponseSize(var TempBlob: Codeunit "Temp Blob")
    var
        AuditLog: Codeunit "Audit Log";
    begin
        if TempBlob.Length() <= GetMaxResponseSize() then
            exit;

        AuditLog.LogAuditMessage(SecurityAuditResponseTooLargeTxt, SecurityOperationResult::Failure, AuditCategory::Authorization, 4, 0); // 4, 0 = AuditMessageOperation / AuditMessageOperationResult (standard security-audit codes; also routes the entry to Purview).
        Session.LogMessage('0000VEQ', ResponseTooLargeMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', EUVATRegNoValidationServiceTok);
        Clear(TempBlob);
        Error(ResponseTooLargeErr);
    end;

    local procedure GetMaxResponseSize(): Integer
    begin
        // A single checkVatApprox response is one company record (typically < 2 KB incl. SOAP envelope).
        // 64 KB leaves ample headroom for long trader details while still rejecting abnormally large payloads.
        exit(65536);
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

