// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Azure.KeyVault;
using System.Utilities;

codeunit 7228 EACorpCardApiSourceProv
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        ApiEndpointMissingErr: Label 'API endpoint is required for provider %1.', Comment = '%1 = Provider code';
        SecretRefMissingErr: Label 'Secret reference is required for provider %1 when authentication type is %2.', Comment = '%1 = Provider code, %2 = Auth Type';
        SecretNotFoundErr: Label 'Secret %1 could not be resolved from Azure Key Vault for provider %2.', Comment = '%1 = secret name, %2 = Provider code';
        ApiTransportFailedErr: Label 'API source download failed for provider %1. The request could not be completed.', Comment = '%1 = Provider code';
        ApiHttpFailedErr: Label 'API source download failed for provider %1. HTTP %2 %3.', Comment = '%1 = Provider code, %2 = status code, %3 = reason phrase';
        ApiContentEmptyErr: Label 'API source download returned no content for provider %1.', Comment = '%1 = Provider code';
        AuthTypeNotSupportedErr: Label 'Authentication type %1 is not supported for provider %2.', Comment = '%1 = auth type, %2 = provider code';
        DefaultXmlFileNameTok: Label 'CorpCardApiPayload.xml', Locked = true;
        DefaultCsvFileNameTok: Label 'CorpCardApiPayload.csv', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EACorpCardDataExchProv, 'OnProvideSourceContent', '', false, false)]
    local procedure OnProvideSourceContent(CorpCardProvider: Record EACorpCardProvider; CorpCardBatch: Record EACorpCardBatch; var TempBlob: Codeunit "Temp Blob"; var SourceFileName: Text[250]; var Handled: Boolean)
    var
        OutStr: OutStream;
        SourceContent: Text;
        ContentType: Text;
    begin
        if Handled then
            exit;

        if CorpCardProvider."Feed Type" <> CorpCardProvider."Feed Type"::API then
            exit;

        CorpCardProvider.TestField(Enabled, true);
        if CorpCardProvider."API Endpoint" = '' then
            Error(ApiEndpointMissingErr, CorpCardProvider.Code);

        SourceContent := DownloadSourceContent(CorpCardProvider, ContentType);
        if SourceContent = '' then
            Error(ApiContentEmptyErr, CorpCardProvider.Code);

        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(SourceContent);

        SourceFileName := ResolveSourceFileName(CorpCardProvider, ContentType);
        Handled := true;
    end;

    local procedure DownloadSourceContent(CorpCardProvider: Record EACorpCardProvider; var ContentType: Text) Result: Text
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
    begin
        RequestMessage.Method := 'GET';
        RequestMessage.SetRequestUri(CorpCardProvider."API Endpoint");

        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Accept', 'application/xml, text/xml, text/csv, application/json');
        AddAuthHeaders(RequestHeaders, CorpCardProvider);

        if not Client.Send(RequestMessage, ResponseMessage) then
            Error(ApiTransportFailedErr, CorpCardProvider.Code);

        if not ResponseMessage.IsSuccessStatusCode() then
            Error(ApiHttpFailedErr, CorpCardProvider.Code, ResponseMessage.HttpStatusCode(), ResponseMessage.ReasonPhrase());

        ResponseMessage.Content.ReadAs(Result);
        ContentType := '';
    end;

    local procedure AddAuthHeaders(var Headers: HttpHeaders; CorpCardProvider: Record EACorpCardProvider)
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        SecretValue: SecretText;
    begin
        if CorpCardProvider."Auth Type" = CorpCardProvider."Auth Type"::None then
            exit;

        if CorpCardProvider."Secret Ref" = '' then
            Error(SecretRefMissingErr, CorpCardProvider.Code, CorpCardProvider."Auth Type");

        if not AzureKeyVault.GetAzureKeyVaultSecret(CorpCardProvider."Secret Ref", SecretValue) then
            Error(SecretNotFoundErr, CorpCardProvider."Secret Ref", CorpCardProvider.Code);

        case CorpCardProvider."Auth Type" of
            CorpCardProvider."Auth Type"::ApiKey:
                Headers.Add('x-api-key', SecretValue);
            CorpCardProvider."Auth Type"::OAuth2:
                Headers.Add('Authorization', SecretStrSubstNo('Bearer %1', SecretValue));
            CorpCardProvider."Auth Type"::Basic:
                Headers.Add('Authorization', SecretStrSubstNo('Basic %1', SecretValue));
            CorpCardProvider."Auth Type"::Cert:
                Error(AuthTypeNotSupportedErr, CorpCardProvider."Auth Type", CorpCardProvider.Code);
        end;
    end;

    local procedure ResolveSourceFileName(CorpCardProvider: Record EACorpCardProvider; ContentType: Text): Text[250]
    var
        EndpointLower: Text;
        ContentTypeLower: Text;
    begin
        if CorpCardProvider."Source File Name" <> '' then
            exit(CopyStr(CorpCardProvider."Source File Name", 1, 250));

        EndpointLower := LowerCase(CorpCardProvider."API Endpoint");
        ContentTypeLower := LowerCase(ContentType);

        if (StrPos(EndpointLower, '.csv') > 0) or (StrPos(ContentTypeLower, 'csv') > 0) then
            exit(CopyStr(DefaultCsvFileNameTok, 1, 250));

        exit(CopyStr(DefaultXmlFileNameTok, 1, 250));
    end;
}
