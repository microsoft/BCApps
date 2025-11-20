// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.CRM.Contact;
using Microsoft.Sales.Customer;
using System;
using System.Integration;
using System.Reflection;
using System.Utilities;
using System.Xml;

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

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterLookupVatRegistrationFromWebService(var VATRegistrationLog: Record "VAT Registration Log"; var RecVATRegistrationLog: Record "VAT Registration Log")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendRequestToVatRegistrationServiceOnBeforeSendRequestToWebService(var SOAPWebServiceRequestMgt: Codeunit "SOAP Web Service Request Mgt."; var TempBlobBody: Codeunit "Temp Blob")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendRequestToVATRegistrationServiceBeforeShowErrors(var VATRegistrationLog: Record "VAT Registration Log"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareSOAPRequestBodyOnBeforeSetAccountDetails(var RecordRef: RecordRef; var VATRegistrationLog: Record "VAT Registration Log"; var AccountName: Text; var AccountStreet: Text; var AccountCity: Text; var AccountPostCode: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupVatRegistrationFromWebServiceOnAfterResponseLogRecordingAndBeforeCommit(VATRegistrationLog: Record "VAT Registration Log"; ShowErrors: Boolean; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeLookupVatRegistrationFromWebService(var VATRegistrationLogRec: Record "VAT Registration Log"; var VATRegistrationLog: Record "VAT Registration Log"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareSOAPRequestBody(var TempBlob: Codeunit "Temp Blob"; VATRegistrationLog: Record "VAT Registration Log"; var IsHandled: Boolean)
    begin
    end;

}

