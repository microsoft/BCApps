// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.FileSystem;

codeunit 9456 "File Pagination Data"
{
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        Marker: Text;
        EndOfListing: Boolean;

    procedure SetMarker(NewMarker: Text)
    begin
        Marker := NewMarker;
    end;

    procedure GetMarker(): Text
    begin
        exit(Marker);
    end;

    procedure SetEndOfListing(NewEndOfListing: Boolean)
    begin
        EndOfListing := NewEndOfListing;
    end;

    procedure IsEndOfListing(): Boolean
    begin
        exit(EndOfListing);
    end;
}
