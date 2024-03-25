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
        GraphOptionalParametersImpl.SetIfMatch("Value");
    end;

    /// <summary>
    /// Sets the value for 'If-None-Match' HttpHeader for a request.
    /// </summary>
    /// <param name="Value">Text value specifying the HttpHeader value</param>
    procedure SetIfNoneMatchRequestHeader("Value": Text)
    begin
        GraphOptionalParametersImpl.SetIfNoneMatchRequestHeader("Value");
    end;

    /// <summary>
    /// Sets the value for 'Prefer' HttpHeader for a request.
    /// </summary>
    /// <param name="Value">Text value specifying the HttpHeader value</param>
    procedure SetPreferRequestHeader("Value": Text)
    begin
        GraphOptionalParametersImpl.SetPreferRequestHeader("Value");
    end;

    /// <summary>
    /// Sets the value for 'ConsistencyLevel' HttpHeader for a request.
    /// </summary>
    /// <param name="Value">Text value specifying the HttpHeader value</param>
    procedure SetConsistencyLevelRequestHeader("Value": Text)
    begin
        GraphOptionalParametersImpl.SetConsistencyLevelRequestHeader("Value");
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

    procedure SetODataQueryParameterCount()
    begin
        GraphOptionalParametersImpl.SetODataQueryParameterCount(true);
    end;

    /// <summary>
    /// Sets the value for the OData Query Parameter '$expand'.
    /// </summary>
    /// <param name="Value">Text value specifying the query parameter</param>
    procedure SetODataQueryParameterExpand("Value": Text)
    begin
        GraphOptionalParametersImpl.SetODataQueryParameterExpand("Value");
    end;

    /// <summary>
    /// Sets the value for the OData Query Parameter '$filter'.
    /// </summary>
    /// <param name="Value">Text value specifying the query parameter</param>
    procedure SetODataQueryParameterFilter("Value": Text)
    begin
        GraphOptionalParametersImpl.SetODataQueryParameterFilter("Value");
    end;

    /// <summary>
    /// Sets the value for the OData Query Parameter '$format'.
    /// </summary>
    /// <param name="Value">Text value specifying the query parameter</param>
    procedure SetODataQueryParameterFormat("Value": Text)
    begin
        GraphOptionalParametersImpl.SetODataQueryParameterFormat("Value");
    end;

    /// <summary>
    /// Sets the value for the OData Query Parameter '$orderBy'.
    /// </summary>
    /// <param name="Value">Text value specifying the query parameter</param>
    procedure SetODataQueryParameterOrderBy("Value": Text)
    begin
        GraphOptionalParametersImpl.SetODataQueryParameterOrderBy("Value");
    end;

    /// <summary>
    /// Sets the value for the OData Query Parameter '$search'.
    /// </summary>
    /// <param name="Value">Text value specifying the query parameter</param>
    procedure SetODataQueryParameterSearch("Value": Text)
    begin
        GraphOptionalParametersImpl.SetODataQueryParameterSearch("Value");
    end;

    /// <summary>
    /// Sets the value for the OData Query Parameter '$select'.
    /// </summary>
    /// <param name="Value">Text value specifying the query parameter</param>
    procedure SetODataQueryParameterSelect("Value": Text)
    begin
        GraphOptionalParametersImpl.SetODataQueryParameterSelect("Value");
    end;

    /// <summary>
    /// Sets the value for the OData Query Parameter '$skip'.
    /// </summary>
    /// <param name="Value">Text value specifying the query parameter</param>
    procedure SetODataQueryParameterSkip("Value": Integer)
    begin
        GraphOptionalParametersImpl.SetODataQueryParameterSkip("Value");
    end;

    /// <summary>
    /// Sets the value for the OData Query Parameter '$skipToken'.
    /// </summary>
    /// <param name="Value">Text value specifying the query parameter</param>
    procedure SetODataQueryParameterSkipToken("Value": Text)
    begin
        GraphOptionalParametersImpl.SetODataQueryParameterSkipToken("Value");
    end;

    /// <summary>
    /// Sets the value for the OData Query Parameter '$top'.
    /// </summary>
    /// <param name="Value">Text value specifying the query parameter</param>
    procedure SetODataQueryParameterTop("Value": Integer)
    begin
        GraphOptionalParametersImpl.SetODataQueryParameterTop("Value");
    end;

    internal procedure GetODataQueryParameters(): Dictionary of [Text, Text]
    begin
        exit(GraphOptionalParametersImpl.GetODataQueryParameters());
    end;
    #endregion
}