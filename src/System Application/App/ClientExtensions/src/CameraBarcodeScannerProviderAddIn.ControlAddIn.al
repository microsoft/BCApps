namespace System.ClientExtensions;

// The control add-in for the camera barcode scanner provider.
controladdin CameraBarcodeScannerProviderAddIn
{
    Scripts = 'script.js';

    /*
    * This method is used to request the camera barcode scanner.
    **/
    procedure RequestBarcodeAsync();

    /*
    * This method is used to request the camera barcode scanner.
    * ShowFlipCameraButton: Indicates whether the flip camera button should be shown.
    * ShowTorchButton: Indicates whether the torch button should be shown.
    * ResultDisplayDuration: The duration in milliseconds for which the barcode result should be displayed.
    **/
    procedure RequestBarcodeAsync(ShowFlipCameraButton: Boolean; ShowTorchButton: Boolean; ResultDisplayDuration: Integer);

    /*
    * This event is raised when the control is ready.
    * IsSupported: Whether the camera barcode scanner is supported on the device.
    **/
    event ControlAddInReady(IsSupported: Boolean);

    /*
    * This event is raised when the barcode is available.
    * Barcode: The barcode value
    * Format: The barcode format
    **/
    event BarcodeAvailable(Barcode: Text; Format: Text)

    /**
    * This event is raised when the barcode scanner had a failure.
    * Reason: The failure reason
    **/
    event BarcodeFailure(Reason: Enum "BarcodeFailureReason")
}

