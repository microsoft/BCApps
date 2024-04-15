// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration;

/// <summary>
/// The result of the sharing operation.
/// </summary>
enum 9563 "Document Sharing State"
{
    Extensible = false;

    /// <summary>
    /// Operation completed successfully.
    /// </summary>
    value(0; Success)
    {
        Caption = 'Success';
    }

    /// <summary>
    /// Operation cancelled.
    /// </summary>
    value(1; Cancelled)
    {
        Caption = 'Cancelled';
    }
}