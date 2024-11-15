// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Integration.Graph;


codeunit 9358 "Graph Optional Parameters Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    #region Headers
    procedure SetRequestHeader(GraphRequestHeader: Enum "Graph Request Header"; HeaderValue: Text)
    begin
        SetRequestHeader(Format(GraphRequestHeader), HeaderValue);
    end;

    local procedure SetRequestHeader(Header: Text; HeaderValue: Text)
    begin
        RequestHeaders.Remove(Header);
        RequestHeaders.Add(Header, HeaderValue);
    end;

    internal procedure GetRequestHeaders(): Dictionary of [Text, Text]
    begin
        exit(RequestHeaders);
    end;

    #endregion

    #region Parameters

    procedure SetMicrosftGraphConflictBehavior(GraphConflictBehavior: Enum "Graph ConflictBehavior")
    begin
        SetQueryParameter('@microsoft.graph.conflictBehavior', Format(GraphConflictBehavior));
    end;


    local procedure SetQueryParameter(Header: Text; HeaderValue: Text)
    begin
        QueryParameters.Remove(Header);
        QueryParameters.Add(Header, HeaderValue);
    end;

    procedure GetQueryParameters(): Dictionary of [Text, Text]
    begin
        exit(QueryParameters);
    end;
    #endregion

    #region ODataQueryParameters

    procedure SetODataQueryParameter(GraphODataQueryParameter: Enum "Graph OData Query Parameter"; ODataQueryParameterValue: Text)
    begin
        SetODataQueryParameter(Format(GraphODataQueryParameter), ODataQueryParameterValue);
    end;

    local procedure SetODataQueryParameter(ODataQueryParameterKey: Text; ODataQueryParameterValue: Text)
    begin
        ODataQueryParameters.Remove(ODataQueryParameterKey);
        ODataQueryParameters.Add(ODataQueryParameterKey, ODataQueryParameterValue);
    end;

    procedure GetODataQueryParameters(): Dictionary of [Text, Text]
    begin
        exit(ODataQueryParameters);
    end;

    #endregion

    var
        QueryParameters: Dictionary of [Text, Text];
        ODataQueryParameters: Dictionary of [Text, Text];
        RequestHeaders: Dictionary of [Text, Text];
}