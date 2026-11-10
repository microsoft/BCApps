// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Registration;

using System.RestClient;
using System.Telemetry;
using System.Utilities;

codeunit 11754 "Reg. Lookup Ext. Data CZL"
{
    TableNo = "Registration Log CZL";

    trigger OnRun()
    begin
        RegistrationLogCZL := Rec;
        LookupRegistrationFromService();
        Rec := RegistrationLogCZL;
    end;

    var
        RegistrationLogCZL: Record "Registration Log CZL";
        RegistrationLogMgtCZL: Codeunit "Registration Log Mgt. CZL";
        ResponseTooLargeErr: Label 'The response from the ARES registration number validation service exceeded the maximum allowed size and was rejected.';
        InvalidResponseErr: Label 'The response from the ARES registration number validation service is not valid JSON.';
        ResponseTooLargeTxt: Label 'The registration no. validation failed. The ARES response exceeded the maximum allowed size.', Locked = true;
        SecurityAuditResponseTooLargeTxt: Label 'The ARES registration number validation service returned a response that exceeded the maximum allowed size.', Locked = true;
        AresTelemetryCategoryTok: Label 'ARES Registration No. Validation', Locked = true;

    procedure LookupRegistrationFromService()
    begin
        InsertLogEntry(SendRequest());
        Commit();
    end;

    local procedure SendRequest() HttpResponseMessage: Codeunit "Http Response Message"
    var
        RegNoServiceConfigCZL: Record "Reg. No. Service Config CZL";
        RestClient: Codeunit "Rest Client";
        RequestURL: Text;
        RegNoTok: Label '%1/%2', Locked = true, Comment = '%1 = Registration No. service URL, %2 = Registraton No.';
    begin
        RequestURL := StrSubstNo(RegNoTok, RegNoServiceConfigCZL.GetRegNoURL(), RegistrationLogCZL."Registration No.");
        RestClient.Initialize();
        HttpResponseMessage := RestClient.Get(RequestURL);
    end;

    local procedure InsertLogEntry(HttpResponseMessage: Codeunit "Http Response Message")
    var
        ResponseTempBlob: Codeunit "Temp Blob";
        ResponseInStream: InStream;
        ResponseJsonObject: JsonObject;
    begin
        // Read the body once and reject an oversized response from the unauthenticated ARES service before parsing it.
        ResponseTempBlob := HttpResponseMessage.GetContent().AsBlob();
        CheckResponseSize(ResponseTempBlob);
        ResponseTempBlob.CreateInStream(ResponseInStream, TextEncoding::UTF8);
        if not ResponseJsonObject.ReadFrom(ResponseInStream) then
            Error(InvalidResponseErr);
        if HttpResponseMessage.GetIsSuccessStatusCode() then
            RegistrationLogMgtCZL.LogVerification(RegistrationLogCZL, ResponseJsonObject)
        else
            RegistrationLogMgtCZL.LogError(RegistrationLogCZL, ResponseJsonObject);
    end;

    internal procedure CheckResponseSize(var ResponseTempBlob: Codeunit "Temp Blob")
    var
        AuditLog: Codeunit "Audit Log";
    begin
        // Measure the raw bytes, not decoded characters: Czech diacritics take more than one byte in UTF-8.
        if ResponseTempBlob.Length() <= GetMaxResponseSize() then
            exit;

        // 4, 0 = AuditMessageOperation / AuditMessageOperationResult (standard security-audit codes; also routes the entry to Purview).
        AuditLog.LogAuditMessage(SecurityAuditResponseTooLargeTxt, SecurityOperationResult::Failure, AuditCategory::Authorization, 4, 0);
        Session.LogMessage('0000W6Z', ResponseTooLargeTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', AresTelemetryCategoryTok);
        Error(ResponseTooLargeErr);
    end;

    local procedure GetMaxResponseSize(): Integer
    begin
        // A lookup returns a single company record by IČO. Its only collections are bounded by external
        // classifications (NACE activity codes, source registries), not by the company's data: the largest
        // Czech entities return under 6 KB. 64 KB leaves ample headroom while rejecting abnormal payloads.
        exit(65536); // bytes
    end;

    procedure GetRegistrationNoValidationWebServiceURL(): Text[250]
    var
        RegNoValidationWebServiceURLTok: Label 'https://ares.gov.cz/ekonomicke-subjekty-v-be/rest/ekonomicke-subjekty', Locked = true;
    begin
        exit(RegNoValidationWebServiceURLTok);
    end;

    procedure SetRegistrationLog(RegistrationLogCZL: Record "Registration Log CZL")
    begin
        RegistrationLogCZL := RegistrationLogCZL;
    end;
}
