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
    procedure SetIfMatch("Value": Text)
    begin
        SetRequestHeader('IF-Match', "Value");
    end;

    procedure SetIfNoneMatchRequestHeader("Value": Text)
    begin
        SetRequestHeader('If-None-Match', "Value");
    end;

    procedure SetPreferRequestHeader("Value": Text)
    begin
        SetRequestHeader('Prefer', "Value");
    end;

    procedure SetConsistencyLevelRequestHeader("Value": Text)
    begin
        SetRequestHeader('ConsistencyLevel', "Value");
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

    procedure SetODataQueryParameterCount(RetrieveCount: Boolean)
    begin
        if RetrieveCount then
            SetODataQueryParameter('$count', 'true');
    end;

    procedure SetODataQueryParameterExpand("Value": Text)
    begin
        SetODataQueryParameter('$expand', "Value");
    end;

    procedure SetODataQueryParameterFilter("Value": Text)
    begin
        SetODataQueryParameter('$filter', "Value");
    end;

    procedure SetODataQueryParameterFormat("Value": Text)
    begin
        SetODataQueryParameter('$format', "Value");
    end;

    procedure SetODataQueryParameterOrderBy("Value": Text)
    begin
        SetODataQueryParameter('$orderby ', "Value");
    end;

    procedure SetODataQueryParameterSearch("Value": Text)
    begin
        SetODataQueryParameter('$search ', "Value");
    end;

    procedure SetODataQueryParameterSelect("Value": Text)
    begin
        SetODataQueryParameter('$select', "Value");
    end;

    procedure SetODataQueryParameterSkip("Value": Integer)
    begin
        SetODataQueryParameter('$skip', Format("Value", 0, 9));
    end;

    procedure SetODataQueryParameterSkipToken("Value": Text)
    begin
        SetODataQueryParameter('$skipToken', "Value");
    end;

    procedure SetODataQueryParameterTop("Value": Integer)
    begin
        SetODataQueryParameter('$top', Format("Value", 0, 9));
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