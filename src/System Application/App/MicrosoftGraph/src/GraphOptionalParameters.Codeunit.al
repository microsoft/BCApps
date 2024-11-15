// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Integration.Graph;

/// <summary>
/// Holder for the optional Microsoft Graph HTTP headers and URL parameters.
/// </summary>
codeunit 9353 "Graph Optional Parameters"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        GraphOptionalParametersImpl: Codeunit "Graph Optional Parameters Impl";

    #region Headers

    /// <summary>
    /// Sets the value for 'IF-Match' HttpHeader for a request.
    /// </summary>
    /// <param name="Value">Text value specifying the HttpHeader value</param>
    procedure SetIfMatch("Value": Text)
    begin
        SetRequestHeader(Enum::"Graph Request Header"::"If-Match", "Value");
    end;

    /// <summary>
    /// Sets the value for 'If-None-Match' HttpHeader for a request.
    /// </summary>
    /// <param name="Value">Text value specifying the HttpHeader value</param>
    procedure SetIfNoneMatchRequestHeader("Value": Text)
    begin
        SetRequestHeader(Enum::"Graph Request Header"::"If-None-Match", "Value");
    end;

    /// <summary>
    /// Sets the value for 'Prefer' HttpHeader for a request.
    /// </summary>
    /// <param name="Value">Text value specifying the HttpHeader value</param>
    procedure SetPreferRequestHeader("Value": Text)
    begin
        SetRequestHeader(Enum::"Graph Request Header"::Prefer, "Value");
    end;

    /// <summary>
    /// Sets the value for 'ConsistencyLevel' HttpHeader for a request.
    /// </summary>
    /// <param name="Value">Text value specifying the HttpHeader value</param>
    procedure SetConsistencyLevelRequestHeader("Value": Text)
    begin
        SetRequestHeader(Enum::"Graph Request Header"::ConsistencyLevel, "Value");
    end;

    /// <summary>
    /// Sets the value for a HttpHeader for a request.
    /// </summary>
    /// <param name="GraphRequestHeader">The Request Header</param>
    /// <param name="HeaderValue">Text value specifying the HttpHeader value</param>
    procedure SetRequestHeader(GraphRequestHeader: Enum "Graph Request Header"; HeaderValue: Text)
    begin
        GraphOptionalParametersImpl.SetRequestHeader(GraphRequestHeader, HeaderValue);
    end;

    internal procedure GetRequestHeaders(): Dictionary of [Text, Text]
    begin
        exit(GraphOptionalParametersImpl.GetRequestHeaders());
    end;

    #endregion

    #region Parameters

    /// <summary>
    /// Sets the value for '@microsoft.graph.conflictBehavior' HttpHeader for a request.
    /// </summary>
    /// <param name="GraphConflictBehavior">Enum "Graph ConflictBehavior" value specifying the HttpHeader value</param>
    procedure SetMicrosftGraphConflictBehavior(GraphConflictBehavior: Enum "Graph ConflictBehavior")
    begin
        GraphOptionalParametersImpl.SetMicrosftGraphConflictBehavior(GraphConflictBehavior);
    end;

    internal procedure GetQueryParameters(): Dictionary of [Text, Text]
    begin
        exit(GraphOptionalParametersImpl.GetQueryParameters());
    end;
    #endregion

    #region ODataQueryParameters


    /// <summary>
    /// Sets the value for an OData Query Parameter
    /// see: https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#odata-system-query-options
    /// </summary>
    /// <param name="GraphODataQueryParameter">The OData query parameter</param>
    /// <param name="ODataQueryParameterValue">Text value specifying the query parameter</param>
    procedure SetODataQueryParameter(GraphODataQueryParameter: Enum "Graph OData Query Parameter"; ODataQueryParameterValue: Text)
    begin
        GraphOptionalParametersImpl.SetODataQueryParameter(GraphODataQueryParameter, ODataQueryParameterValue);
    end;

    internal procedure GetODataQueryParameters(): Dictionary of [Text, Text]
    begin
        exit(GraphOptionalParametersImpl.GetODataQueryParameters());
    end;
    #endregion
}