// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Device;

/// <summary>
/// The failure for the barcode scanner.
/// </summary>
enum 8761 BarcodeFailure
{
    /// <summary>
    /// The barcode scanning action was canceled.
    /// </summary>
    value(0; Cancel) { }

    /// <summary>
    /// No barcode was found.
    /// </summary>
    value(1; NoBarcode) { }

    /// <summary>
    /// An error occurred while scanning the barcode.
    /// </summary>
    value(2; Error) { }
}