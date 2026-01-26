// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System;
using System.Azure.Functions;
using System.Azure.KeyVault;
using System.Environment;
using System.Security.Encryption;
using System.Utilities;

codeunit 11000053 "Digipoort SaaS Communication" implements "DigiPoort Communication"
{
    Access = Internal;

    var
        ClientIDLbl: label 'AppNetProxyFnClientID', Locked = true;
        EndpointLbl: Label 'AppNetProxyFnEndpoint', Locked = true;
        AuthURlLbl: Label 'AppNetProxyFnAuthUrl', Locked = true;
        ScopeLbl: Label 'AppNetProxyFnScope', Locked = true;
        FunctionSecretErr: Label 'There was an error connecting to the service.';
        DigipoortTok: Label 'DigipoortTelemetryCategoryTok', Locked = true;
        ResponseErr: Label 'There was an error while connecting to the service. Error message: %1', Comment = '%1=Error message';
        RequestSuccessfulMsg: label 'Digiport request was submitted successfully using certificate authorized Azure Function', Locked = true;
        RequestFailedMsg: label 'Digiport request failed with reason: %1, and error message: %2', Locked = true;
        SecretsMissingMsg: label 'Digiport Az Function secrets are  missing', Locked = true;
        ElectronicInvoicingCertificateNameLbl: Label 'ElectronicInvoicingCertificateName', Locked = true;
        MissingCertificateErr: Label 'The certificate can not be retrieved.', Locked = true;

    [NonDebuggable]
    procedure Deliver(Request: DotNet aanleverRequest; var Response: DotNet aanleverResponse; RequestUrl: Text; ClientCertificateBase64: Text; DotNetSecureString: Codeunit DotNet_SecureString; ServiceCertificateBase64: Text; Timeout: Integer; UseCertificateSetup: boolean)
    var
        DigipoortServices: DotNet DigipoortServices;
        RequestBody, TxtResponse : Text;
    begin
        RequestBody := DigipoortServices.SerializeDeliverRequest(Request,
            RequestUrl,
            ClientCertificateBase64,
            DotNetSecureString.GetPlainText(),
            ServiceCertificateBase64,
            Timeout);

        TxtResponse := CommunicateWithAzureFunction('api/Deliver', RequestBody);
        Response := DigipoortServices.DeserializeDeliverResponse(TxtResponse);
    end;

    [NonDebuggable]
    procedure GetStatus(Request: DotNet getStatussenProcesRequest; var StatusResultatQueue: DotNet Queue; ResponseUrl: Text; ClientCertificateBase64: Text; DotNetSecureString: Codeunit DotNet_SecureString; ServiceCertificateBase64: Text; Timeout: Integer; UseCertificateSetup: boolean)
    var
        DigipoortServices: DotNet DigipoortServices;
        RequestBody, TxtResponse : Text;
    begin
        RequestBody := DigipoortServices.SerializeGetStatusRequest(Request,
            ResponseUrl,
            ClientCertificateBase64,
            DotNetSecureString.GetPlainText(),
            ServiceCertificateBase64,
            Timeout);

        TxtResponse := CommunicateWithAzureFunction('api/GetStatus', RequestBody);
        StatusResultatQueue := DigipoortServices.DeserializeGetStatusResponse(TxtResponse);
    end;

    [NonDebuggable]
    local procedure CommunicateWithAzureFunction(Path: Text; Body: Text): Text
    var
        AzureFunctions: Codeunit "Azure Functions";
        AzureFunctionsAuthentication: Codeunit "Azure Functions Authentication";
        AzureFunctionsResponse: Codeunit "Azure Functions Response";
        IAzurefunctionAuthentication: Interface "Azure Functions Authentication";
        Response, ErrorMsg : Text;
        ClientID, Scope, Endpoint, AuthUrl : Text;
        Certificate: SecretText;
    begin
        GetAzFunctionSecrets(ClientID, Certificate, Scope, Endpoint, AuthUrl);
        IAzurefunctionAuthentication := AzureFunctionsAuthentication.CreateOAuth2WithCert(GetEndpoint(Endpoint, Path), '', ClientID, Certificate, AuthUrl, '', Scope);

        AzureFunctionsResponse := AzureFunctions.SendPostRequest(IAzurefunctionAuthentication, Body, 'application/json');

        if AzureFunctionsResponse.IsSuccessful() then begin
            AzureFunctionsResponse.GetResultAsText(Response);
            Session.LogMessage('0000JP0', RequestSuccessfulMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DigipoortTok);
            exit(Response)
        end else begin
            AzureFunctionsResponse.GetError(ErrorMsg);
            Session.LogMessage('0000JP1', StrSubstNo(RequestFailedMsg, AzureFunctionsResponse.GetError(), ErrorMsg), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DigipoortTok);
            Error(ResponseErr, AzureFunctionsResponse.GetError());
        end;
    end;

    [NonDebuggable]
    local procedure GetAzFunctionSecrets(var ClientID: Text; var Certificate: SecretText; var Scope: Text; var Endpoint: Text; var AuthUrl: Text)
    var
        EnvironmentInformation: Codeunit "Environment Information";
        AzureKeyVault: Codeunit "Azure Key Vault";
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            Error('');

        if not (AzureKeyVault.GetAzureKeyVaultSecret(ClientIDLbl, ClientID)
                and AzureKeyVault.GetAzureKeyVaultSecret(ScopeLbl, Scope)
                and AzureKeyVault.GetAzureKeyVaultSecret(AuthURlLbl, AuthUrl)
                and GetCertificate(Certificate)
                and AzureKeyVault.GetAzureKeyVaultSecret(EndpointLbl, Endpoint)) then begin
            Session.LogMessage('0000JP2', SecretsMissingMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DigipoortTok);
            Error(FunctionSecretErr);
        end;
    end;

    [NonDebuggable]
    local procedure GetCertificate(var Certificate: SecretText): Boolean;
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        CertificateName: Text;
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(ElectronicInvoicingCertificateNameLbl, CertificateName) then begin
            Session.LogMessage('0000MZN', MissingCertificateErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DigipoortTok);
            exit(false);
        end;

        if not AzureKeyVault.GetAzureKeyVaultCertificate(CertificateName, Certificate) then begin
            Session.LogMessage('0000MZO', MissingCertificateErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DigipoortTok);
            exit(false);
        end;

        exit(true);
    end;

    local procedure GetEndpoint(Host: Text; Path: Text): text
    var
        URIBuilder: Codeunit "Uri Builder";
        URI: Codeunit URI;
    begin
        URIBuilder.Init(Host);
        URIBuilder.SetPath(Path);
        URIBuilder.GetUri(URI);
        exit(URI.GetAbsoluteUri());
    end;
}
