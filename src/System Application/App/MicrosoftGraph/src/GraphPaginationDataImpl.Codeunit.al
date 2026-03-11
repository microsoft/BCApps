// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Integration.Graph;

codeunit 9361 "Graph Pagination Data Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        NextLink: Text;
        PageSize: Integer;
        DefaultPageSizeErr: Label 'Page size must be between 1 and 999.';

    procedure SetNextLink(NewNextLink: Text)
    begin
        NextLink := NewNextLink;
    end;

    procedure GetNextLink(): Text
    begin
        exit(NextLink);
    end;

    procedure HasMorePages(): Boolean
    begin
        exit(NextLink <> '');
    end;

    procedure SetPageSize(NewPageSize: Integer)
    begin
        if not (NewPageSize in [1 .. 999]) then
            Error(DefaultPageSizeErr);

        PageSize := NewPageSize;
    end;

    procedure GetPageSize(): Integer
    begin
        if PageSize = 0 then
            exit(GetDefaultPageSize());

        exit(PageSize);
    end;

    procedure Reset()
    begin
        Clear(NextLink);
        Clear(PageSize);
    end;

    procedure GetDefaultPageSize(): Integer
    begin
        exit(100);
    end;
}