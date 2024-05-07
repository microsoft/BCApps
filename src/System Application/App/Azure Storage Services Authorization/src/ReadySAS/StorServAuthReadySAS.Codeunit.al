// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Azure.Storage;

using System.Utilities;

codeunit 9088 "Stor. Serv. Auth. Ready SAS" implements "Storage Service Authorization"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    [NonDebuggable]
    procedure Authorize(var HttpRequestMessage: HttpRequestMessage; StorageAccount: Text)
    var
        Uri: Codeunit Uri;
        UriBuilder: Codeunit "Uri Builder";
        UriText, QueryText : Text;
    begin
        UriText := HttpRequestMessage.GetRequestUri();

        UriBuilder.Init(UriText);
        QueryText := UriBuilder.GetQuery();

        QueryText := DelChr(QueryText, '<', '?'); // remove ? from the query

        if QueryText <> '' then
            QueryText += '&';
        QueryText += GetSharedAccessSignature().Unwrap();
        UriBuilder.SetQuery(QueryText);

        UriBuilder.GetUri(Uri);

        HttpRequestMessage.SetSecretRequestUri(Uri.GetAbsoluteUri());
    end;

    procedure GetSharedAccessSignature(): SecretText
    begin
        exit(SharedAccessSignature);
    end;

    [NonDebuggable]
    procedure SetSharedAccessSignature(NewSharedAccessSignature: Text)
    begin
        SetSharedAccessSignature(NewSharedAccessSignature);
    end;

    [NonDebuggable]
    procedure SetSharedAccessSignature(NewSharedAccessSignature: SecretText)
    var
        UnsecureSharedAccessSignature: Text;
    begin
        UnsecureSharedAccessSignature := NewSharedAccessSignature.Unwrap();
        if UnsecureSharedAccessSignature.StartsWith('?') then
            UnsecureSharedAccessSignature := DelChr(UnsecureSharedAccessSignature, '<', '?');
        SharedAccessSignature := UnsecureSharedAccessSignature;
    end;

    var
        SharedAccessSignature: SecretText;
}