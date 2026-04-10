// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.Integration.Graph;

using System.Integration.Graph;
using System.TestLibraries.Utilities;

codeunit 135143 "Graph Pagination Data Test"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure InitialStateTest()
    var
        GraphPaginationData: Codeunit "Graph Pagination Data";
    begin
        // [WHEN] GraphPaginationData is initialized
        // [THEN] Should have no next link and default page size
        LibraryAssert.AreEqual('', GraphPaginationData.GetNextLink(), 'Initial next link should be empty');
        LibraryAssert.IsFalse(GraphPaginationData.HasMorePages(), 'Should not have more pages initially');
        LibraryAssert.AreEqual(100, GraphPaginationData.GetPageSize(), 'Default page size should be 100');
    end;

    [Test]
    procedure SetNextLinkTest()
    var
        GraphPaginationData: Codeunit "Graph Pagination Data";
        NextLink: Text;
    begin
        // [GIVEN] A next link URL
        NextLink := 'https://graph.microsoft.com/v1.0/users?$skiptoken=X%274453707402000100000017';

        // [WHEN] SetNextLink is called
        GraphPaginationData.SetNextLink(NextLink);

        // [THEN] Should store and return the next link
        LibraryAssert.AreEqual(NextLink, GraphPaginationData.GetNextLink(), 'Should return the set next link');
        LibraryAssert.IsTrue(GraphPaginationData.HasMorePages(), 'Should have more pages when next link is set');
    end;

    [Test]
    procedure ClearNextLinkTest()
    var
        GraphPaginationData: Codeunit "Graph Pagination Data";
    begin
        // [GIVEN] A next link is set
        GraphPaginationData.SetNextLink('https://graph.microsoft.com/v1.0/users?$skiptoken=123');

        // [WHEN] Empty next link is set
        GraphPaginationData.SetNextLink('');

        // [THEN] Should have no more pages
        LibraryAssert.AreEqual('', GraphPaginationData.GetNextLink(), 'Next link should be empty');
        LibraryAssert.IsFalse(GraphPaginationData.HasMorePages(), 'Should not have more pages');
    end;

    [Test]
    procedure SetPageSizeValidTest()
    var
        GraphPaginationData: Codeunit "Graph Pagination Data";
    begin
        // [WHEN] Valid page sizes are set
        GraphPaginationData.SetPageSize(1);
        LibraryAssert.AreEqual(1, GraphPaginationData.GetPageSize(), 'Should accept minimum page size of 1');

        GraphPaginationData.SetPageSize(50);
        LibraryAssert.AreEqual(50, GraphPaginationData.GetPageSize(), 'Should accept page size of 50');

        GraphPaginationData.SetPageSize(999);
        LibraryAssert.AreEqual(999, GraphPaginationData.GetPageSize(), 'Should accept maximum page size of 999');
    end;

    [Test]
    procedure SetPageSizeInvalidTest()
    var
        GraphPaginationData: Codeunit "Graph Pagination Data";
    begin
        // [WHEN] Invalid page size is set (0)
        asserterror GraphPaginationData.SetPageSize(0);
        LibraryAssert.ExpectedError('Page size must be between 1 and 999.');

        // [WHEN] Invalid page size is set (negative)
        asserterror GraphPaginationData.SetPageSize(-1);
        LibraryAssert.ExpectedError('Page size must be between 1 and 999.');

        // [WHEN] Invalid page size is set (too large)
        asserterror GraphPaginationData.SetPageSize(1000);
        LibraryAssert.ExpectedError('Page size must be between 1 and 999.');
    end;

    [Test]
    procedure GetDefaultPageSizeTest()
    var
        GraphPaginationData: Codeunit "Graph Pagination Data";
    begin
        // [WHEN] GetDefaultPageSize is called
        // [THEN] Should return 100
        LibraryAssert.AreEqual(100, GraphPaginationData.GetDefaultPageSize(), 'Default page size should be 100');
    end;

    [Test]
    procedure ResetTest()
    var
        GraphPaginationData: Codeunit "Graph Pagination Data";
    begin
        // [GIVEN] GraphPaginationData with values set
        GraphPaginationData.SetNextLink('https://graph.microsoft.com/v1.0/users?$skiptoken=123');
        GraphPaginationData.SetPageSize(50);

        // [WHEN] Reset is called
        GraphPaginationData.Reset();

        // [THEN] Should reset to initial state
        LibraryAssert.AreEqual('', GraphPaginationData.GetNextLink(), 'Next link should be empty after reset');
        LibraryAssert.IsFalse(GraphPaginationData.HasMorePages(), 'Should not have more pages after reset');
        LibraryAssert.AreEqual(100, GraphPaginationData.GetPageSize(), 'Should return default page size after reset');
    end;

    [Test]
    procedure PageSizeZeroReturnsDefaultTest()
    var
        GraphPaginationData: Codeunit "Graph Pagination Data";
    begin
        // [GIVEN] Page size is set to a valid value
        GraphPaginationData.SetPageSize(50);
        LibraryAssert.AreEqual(50, GraphPaginationData.GetPageSize(), 'Should return set page size');

        // [WHEN] Reset is called (which clears page size to 0)
        GraphPaginationData.Reset();

        // [THEN] GetPageSize should return default value
        LibraryAssert.AreEqual(100, GraphPaginationData.GetPageSize(), 'Should return default page size when internal value is 0');
    end;
}