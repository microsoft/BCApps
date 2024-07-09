// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved. 
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Integration.Graph;

/// <summary>
/// A Microsoft Graph API operation might support one or more of the following OData system query options.
/// These query options are compatible with the OData V4 query language and are supported only in GET operations.
/// See: hhttps://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#odata-system-query-options
/// </summary>
enum 9352 "Graph OData Query Parameter"
{
    Access = Public;
    Extensible = false;

    /// <summary>
    /// Query Parameter '$count'.
    /// see: https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#count-parameter
    /// </summary>
    value(0; count)
    {
        Caption = '$count', Locked = true;
    }

    /// <summary>
    /// OData Query Parameter '$expand'.
    /// see: https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#expand-parameter
    /// </summary>
    value(10; expand)
    {
        Caption = '$expand', Locked = true;
    }


    /// <summary>
    /// OData Query Parameter '$filter'.
    /// see: https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#filter-parameter
    /// </summary>
    value(20; filter)
    {
        Caption = '$filter', Locked = true;
    }

    /// <summary>
    /// OData Query Parameter '$format'.
    /// see: https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#format-parameter
    /// </summary>
    value(30; format)
    {
        Caption = '$format', Locked = true;
    }
    /// <summary>
    /// OData Query Parameter '$orderBy'.
    /// see: https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#orderby-parameter
    /// </summary>
    value(40; orderby)
    {
        Caption = '$orderby', Locked = true;
    }

    /// <summary>
    /// OData Query Parameter '$search'.
    /// see: https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#search-parameter
    /// </summary>
    value(50; search)
    {
        Caption = '$search', Locked = true;
    }

    /// <summary>
    /// OData Query Parameter '$select'.
    /// see: https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#select-parameter
    /// </summary>
    value(60; select)
    {
        Caption = '$select', Locked = true;
    }

    /// <summary>
    /// OData Query Parameter '$skip'.
    /// see: https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#skip-parameter
    /// </summary>
    value(70; skip)
    {
        Caption = '$skip', Locked = true;
    }

    /// <summary>
    /// OData Query Parameter '$skipToken'.
    /// see: https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#skiptoken-parameter
    /// </summary>
    value(80; skiptoken)
    {
        Caption = '$skiptoken', Locked = true;
    }

    /// <summary>
    /// OData Query Parameter '$top'.
    /// see: https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#top-parameter
    /// </summary>
    value(90; top)
    {
        Caption = '$top', Locked = true;
    }
}