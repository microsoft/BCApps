// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Integration.Graph;

/// <summary>
/// Holder for pagination data when working with Microsoft Graph API responses.
/// </summary>
codeunit 9360 "Graph Pagination Data"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        GraphPaginationDataImpl: Codeunit "Graph Pagination Data Impl.";

    /// <summary>
    /// Sets the next link URL for retrieving the next page of results.
    /// </summary>
    /// <param name="NewNextLink">The @odata.nextLink value from the Graph response.</param>
    procedure SetNextLink(NewNextLink: Text)
    begin
        GraphPaginationDataImpl.SetNextLink(NewNextLink);
    end;

    /// <summary>
    /// Gets the current next link URL.
    /// </summary>
    /// <returns>The URL to retrieve the next page of results.</returns>
    procedure GetNextLink(): Text
    begin
        exit(GraphPaginationDataImpl.GetNextLink());
    end;

    /// <summary>
    /// Checks if there are more pages available.
    /// </summary>
    /// <returns>True if more pages are available; otherwise false.</returns>
    procedure HasMorePages(): Boolean
    begin
        exit(GraphPaginationDataImpl.HasMorePages());
    end;

    /// <summary>
    /// Sets the page size for pagination requests.
    /// </summary>
    /// <param name="NewPageSize">The number of items to retrieve per page (max 999).</param>
    procedure SetPageSize(NewPageSize: Integer)
    begin
        GraphPaginationDataImpl.SetPageSize(NewPageSize);
    end;

    /// <summary>
    /// Gets the current page size.
    /// </summary>
    /// <returns>The number of items per page.</returns>
    procedure GetPageSize(): Integer
    begin
        exit(GraphPaginationDataImpl.GetPageSize());
    end;

    /// <summary>
    /// Gets the default page size.
    /// </summary>
    /// <returns>The default number of items per page.</returns>
    procedure GetDefaultPageSize(): Integer
    begin
        exit(GraphPaginationDataImpl.GetDefaultPageSize());
    end;

    /// <summary>
    /// Resets the pagination data to initial state.
    /// </summary>
    procedure Reset()
    begin
        GraphPaginationDataImpl.Reset();
    end;
}