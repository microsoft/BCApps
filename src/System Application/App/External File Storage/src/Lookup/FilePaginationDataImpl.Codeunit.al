// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

codeunit 9457 "File Pagination Data Impl."
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        EndOfListing: Boolean;
        Marker: Text;

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
