// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Device;

/// <summary>
/// The failure reason for the barcode scanner.
/// </summary>
controladdin BarcodeScannerProviderAddIn
{
    Scripts = 'Resources\emptyScript.js';

    /// <summary>
    /// This method is used to request the barcode scanner.
    /// </summary>
    procedure RequestBarcodeScannerAsync();

    /// <summary>
    /// This method is used to request the barcode scanner.
    /// </summary>
    /// <param name="IntentAction">The intent action to which the barcode scanner receiver is registered.</param>
    /// <param name="IntentCategory">The intent category to which the barcode scanner receiver is registered.</param>
    /// <param name="DataString">The intent data string key to which the barcode data is added.</param>
    /// <param name="DataFormat">The intent data format key to which the barcode format is added.</param>
    procedure RequestBarcodeScannerAsync(IntentAction: Text; IntentCategory: Text; DataString: Text; DataFormat: Text);

    /// <summary>
    /// This event is raised when the control is ready.
    /// </summary>
    /// <param name="IsSupported">Whether the barcode scanner is supported on the device.</param>
    event ControlAddInReady(IsSupported: Boolean);

    /// <summary>
    /// This event is raised when the barcode is received.
    /// </summary>
    /// <param name="Barcode">The barcode value.</param>
    /// <param name="Format">The barcode format.</param>
    event BarcodeReceived(Barcode: Text; Format: Text)
}