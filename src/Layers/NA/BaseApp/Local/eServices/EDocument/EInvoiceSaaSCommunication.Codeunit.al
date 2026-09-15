// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using System;
using System.Azure.Functions;
using System.Azure.KeyVault;
using System.Environment;
using System.Utilities;

codeunit 10175 "EInvoice SaaS Communication" implements "EInvoice Communication V2"
{
    Access = Internal;

    var
        Parameters: JsonArray;
        ClientIDLbl: label 'AppNetProxyFnClientID', Locked = true;
        EndpointLbl: Label 'AppNetProxyFnEndpoint', Locked = true;
        AuthURlLbl: Label 'AppNetProxyFnAuthUrl', Locked = true;
        ScopeLbl: Label 'AppNetProxyFnScope', Locked = true;
        FunctionSecretErr: Label 'There was an error connecting to the service.';
        MXElectronicInvoicingTok: Label 'MXElectronicInvoicingTelemetryCategoryTok', Locked = true;
        ResponseErr: Label 'There was an error while connecting to the service. Error message: %1', Comment = '%1=Error message';
        RequestSuccessfulMsg: label 'CFDI request was submitted successfully using certificate authorized Azure Function', Locked = true;
        RequestFailedMsg: label 'CFDI request failed with reason: %1, and error message: %2', Locked = true;
        SecretsMissingMsg: label 'CFDI Az Function secrets are  missing', Locked = true;
        ElectronicInvoicingCertificateNameLbl: Label 'ElectronicInvoicingCertificateName', Locked = true;
        MissingCertificateErr: Label 'The certificate can not be retrieved.', Locked = true;
        PlaceholderTok: Label 'Placeholder', Locked = true;

    procedure InvokeMethodWithCertificate(Uri: Text; MethodName: Text; CertBase64: Text; CertPassword: SecretText): Text
    var
        JsonObj: JsonObject;
        JValue: JsonValue;
        Body: SecretText;
        Response: Text;
    begin
        JsonObj.Add('url', Uri);
        JsonObj.Add('methodName', MethodName);
        JsonObj.Add('parameters', Parameters);
        CheckToDownloadSaaSRequest(JsonObj);

        JsonObj.Add('certificateString', CertBase64);
        JsonObj.Add('certificatePassword', PlaceholderTok);
        JsonObj.WriteWithSecretsTo('$.certificatePassword', CertPassword, Body);

        Response := CommunicateWithAzureFunction('api/InvokeMethodWithCertificate', Body);
        JValue.ReadFrom(Response);
        exit(JValue.AsText());
    end;

    procedure SignDataWithCertificate(OriginalString: Text; Cert: Text; CertPassword: SecretText): Text
    var
        JValue: JsonValue;
        JsonObj: JsonObject;
        Body: SecretText;
        Response: Text;
    begin
        ExportCertAsPFX(Cert, CertPassword);

        JsonObj.Add('data', OriginalString);
        JsonObj.Add('certificateString', Cert);
        JsonObj.Add('certificatePassword', PlaceholderTok);
        JsonObj.WriteWithSecretsTo('$.certificatePassword', CertPassword, Body);

        Response := CommunicateWithAzureFunction('api/SignDataWithCertificate', Body);
        if JValue.ReadFrom(Response) then
            exit(JValue.AsText())
        else
            exit(Response);
    end;

    procedure AddParameters(Parameter: Variant)
    var
        BooleanParameter: Boolean;
    begin
        if Parameter.IsBoolean then begin
            BooleanParameter := Parameter;
            Parameters.Add(BooleanParameter);
        end else
            Parameters.Add(Format(Parameter, 0, 9));
    end;

    [NonDebuggable]
    local procedure CommunicateWithAzureFunction(Path: Text; Body: SecretText): Text
    var
        AzureFunctions: Codeunit "Azure Functions";
        AzureFunctionsAuthentication: Codeunit "Azure Functions Authentication";
        AzureFunctionsResponse: Codeunit "Azure Functions Response";
        IAzurefunctionsAuthentication: Interface "Azure Functions Authentication";
        Response, ErrorMsg : Text;
        ClientID, AuthUrl, Endpoint, Scope : Text;
        Certificate: SecretText;
    begin
        GetAzFunctionSecrets(ClientID, Certificate, Scope, Endpoint, AuthUrl);
        IAzurefunctionsAuthentication := AzureFunctionsAuthentication.CreateOAuth2WithCert(GetEndpoint(Endpoint, Path), '', ClientID, Certificate, AuthUrl, '', Scope);

        AzureFunctionsResponse := AzureFunctions.SendPostRequest(IAzurefunctionsAuthentication, Body.Unwrap(), 'application/json');

        if AzureFunctionsResponse.IsSuccessful() then begin
            AzureFunctionsResponse.GetResultAsText(Response);
            Session.LogMessage('0000JOX', RequestSuccessfulMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
            exit(Response);
        end else begin
            AzureFunctionsResponse.GetError(ErrorMsg);
            Session.LogMessage('0000JOY', StrSubstNo(RequestFailedMsg, AzureFunctionsResponse.GetError(), ErrorMsg), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
            Error(ResponseErr, AzureFunctionsResponse.GetError());
        end;
    end;

    [NonDebuggable]
    local procedure GetAzFunctionSecrets(var ClientID: Text; var Certificate: SecretText; var Scope: Text; var Endpoint: Text; var AuthUrl: Text)
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            Error('');

        if not (AzureKeyVault.GetAzureKeyVaultSecret(ClientIDLbl, ClientID)
                and AzureKeyVault.GetAzureKeyVaultSecret(ScopeLbl, Scope)
                and AzureKeyVault.GetAzureKeyVaultSecret(AuthURlLbl, AuthUrl)
                and AzureKeyVault.GetAzureKeyVaultSecret(EndpointLbl, Endpoint))
                and GetCertificate(Certificate) then begin
            Session.LogMessage('0000JOZ', SecretsMissingMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
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
            Session.LogMessage('0000MZN', MissingCertificateErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
            exit(false);
        end;

        if not AzureKeyVault.GetAzureKeyVaultCertificate(CertificateName, Certificate) then begin
            Session.LogMessage('0000MZO', MissingCertificateErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MXElectronicInvoicingTok);
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

    [NonDebuggable]
    local procedure ExportCertAsPFX(var CertBase64: Text; CertPassword: SecretText)
    var
        X509Certificate2: DotNet X509Certificate2;
        X509Content: DotNet X509ContentType;
        X509KeyFlags: DotNet X509KeyStorageFlags;
        Convert: DotNet Convert;
    begin
        X509Certificate2 := X509Certificate2.X509Certificate2(Convert.FromBase64String(CertBase64), CertPassword.Unwrap(), X509KeyFlags.Exportable);
        CertBase64 := Convert.ToBase64String(X509Certificate2.Export(X509Content.Pfx, CertPassword.Unwrap()));
    end;

    [NonDebuggable]

    local procedure CheckToDownloadSaaSRequest(JsonObj: JsonObject)
    var
        MXElectronicInvoicingSetup: Record "MX Electronic Invoicing Setup";
        TempBlob: Codeunit "Temp Blob";
        SerializedText: Text;
        DocOutStream: OutStream;
        DocInStream: InStream;
        DocFileName: text;
    begin
        JsonObj.WriteTo(SerializedText);

        if MXElectronicInvoicingSetup.Get() then
            if MXElectronicInvoicingSetup."Download SaaS Request" then begin
                TempBlob.CreateOutStream(DocOutStream);
                DocOutStream.WriteText(SerializedText);
                TempBlob.CreateInStream(DocInStream);

                DocFileName := 'ElectronicInvoiceRequest.txt';
                DownloadFromStream(DocInStream, '', '', '', DocFileName);
            end;
    end;
}