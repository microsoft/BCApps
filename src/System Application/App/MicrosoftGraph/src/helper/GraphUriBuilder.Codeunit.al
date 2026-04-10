// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Integration.Graph;

using System.Utilities;

codeunit 9352 "Graph Uri Builder"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        Uri: Codeunit Uri;
        GraphAPIVersion: Enum "Graph API Version";
        MicrosoftGraphDefaultBaseUrlTxt: Label 'https://graph.microsoft.com', Locked = true;


    procedure Initialize(MicrosoftGraphBaseUrl: Text; NewGraphAPIVersion: Enum "Graph API Version"; RelativeUriToResource: Text)
    var
        QueryParameters: Dictionary of [Text, Text];
        ODataQueryParameters: Dictionary of [Text, Text];
    begin
        Initialize(MicrosoftGraphBaseUrl, NewGraphAPIVersion, RelativeUriToResource, QueryParameters, ODataQueryParameters);
    end;

    procedure Initialize(MicrosoftGraphBaseUrl: Text; NewGraphAPIVersion: Enum "Graph API Version"; RelativeUriToResource: Text; QueryParameters: Dictionary of [Text, Text]; ODataQueryParameters: Dictionary of [Text, Text])
    var
        UriBuilder: Codeunit "Uri Builder";
        BaseUri: Text;
        CombinedUri: Text;
        QueryParameterKey: Text;
    begin
        if MicrosoftGraphBaseUrl = '' then
            MicrosoftGraphBaseUrl := MicrosoftGraphDefaultBaseUrlTxt;
        GraphAPIVersion := NewGraphAPIVersion;

        BaseUri := CombineUri(MicrosoftGraphBaseUrl, Format(GraphAPIVersion));
        CombinedUri := CombineUri(BaseUri, RelativeUriToResource);
        Uri.Init(CombinedUri);
        UriBuilder.Init(Uri.GetAbsoluteUri());
        foreach QueryParameterKey in QueryParameters.Keys() do
            UriBuilder.AddQueryParameter(QueryParameterKey, QueryParameters.Get(QueryParameterKey));
        foreach QueryParameterKey in ODataQueryParameters.Keys() do
            UriBuilder.AddODataQueryParameter(QueryParameterKey, ODataQueryParameters.Get(QueryParameterKey));
        UriBuilder.GetUri(Uri);
    end;

    procedure GetUri(): Text
    begin
        exit(Uri.GetAbsoluteUri())
    end;

    local procedure CombineUri(BaseUri: Text; RelativeUriToResource: Text) CombinedUrl: Text
    var
        UrlCombineTxt: Label '%1/%2', Comment = '%1 = BaseUrl, %2 = relative url to resource', Locked = true;
    begin
        BaseUri := BaseUri.TrimEnd('/');
        RelativeUriToResource := RelativeUriToResource.TrimStart('/');
        CombinedUrl := StrSubstNo(UrlCombineTxt, BaseUri, RelativeUriToResource);
    end;
}