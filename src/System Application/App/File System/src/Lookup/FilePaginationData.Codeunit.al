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
        FilePaginationDataImpl: Codeunit "File Pagination Data Impl.";

    /// <summary>
    /// Sets a marker if files and directories can be getted in batches.
    /// </summary>
    /// <param name="NewMarker">Marker value to set.</param>
    procedure SetMarker(NewMarker: Text)
    begin
        FilePaginationDataImpl.SetMarker(NewMarker);
    end;

    /// <summary>
    /// Gets the current marker value.
    /// </summary>
    /// <returns>Current marker value.</returns>
    procedure GetMarker(): Text
    begin
        exit(FilePaginationDataImpl.GetMarker());
    end;

    /// <summary>
    /// Set this value to true, if all files or directoreis have beend read a from the File System.
    /// </summary>
    /// <param name="NewEndOfListing">End of listing reached.</param>
    procedure SetEndOfListing(NewEndOfListing: Boolean)
    begin
        FilePaginationDataImpl.SetEndOfListing(NewEndOfListing);
    end;

    /// <summary>
    /// Defines if all batches of directory or file listing has beend received.
    /// </summary>
    /// <returns>End of listing reached.</returns>
    procedure IsEndOfListing(): Boolean
    begin
        exit(FilePaginationDataImpl.IsEndOfListing());
    end;
}
