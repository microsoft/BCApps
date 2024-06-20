// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Device;

/// <summary>
/// The control add-in for the camera barcode scanner provider.
/// </summary>
controladdin CameraBarcodeScannerProviderAddIn
{
    Scripts = 'Resources\emptyScript.js';

    /// <summary>
    /// This method is used to request the camera barcode scanner.
    /// </summary>
    procedure RequestBarcodeAsync();

    /// <summary>
    /// This method is used to request the camera barcode scanner.
    /// </summary>
    /// <param name="ShowFlipCameraButton">Indicates whether the flip camera button should be shown.</param>
    /// <param name="ShowTorchButton">Indicates whether the torch button should be shown.</param>
    /// <param name="ResultDisplayDuration">The duration in milliseconds for which the barcode result should be displayed.</param>
    procedure RequestBarcodeAsync(ShowFlipCameraButton: Boolean; ShowTorchButton: Boolean; ResultDisplayDuration: Integer);

    /// <summary>
    /// This event is raised when the control is ready.
    /// </summary>
    /// <param name="IsSupported">Whether the camera barcode scanner is supported on the device.</param>
    event ControlAddInReady(IsSupported: Boolean);

    /// <summary>
    /// This event is raised when the barcode is available.
    /// </summary>
    /// <param name="Barcode">The barcode value.</param>
    /// <param name="Format">The barcode format.</param>
    event BarcodeAvailable(Barcode: Text; Format: Text)

    /// <summary>
    /// This event is raised when the barcode scanner had a failure.
    /// </summary>
    /// <param name="Failure">The barcode failure.</param>
    event BarcodeFailure(Failure: Enum "BarcodeFailure")
}

