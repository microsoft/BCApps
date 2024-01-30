namespace System.ClientExtensions;


// The control add-in for the barcode scanner provider.
controladdin BarcodeScannerProviderAddIn
{
    Scripts = 'script.js';

    /*
    * This method is used to request the camera barcode scanner.
    **/
    procedure RequestBarcodeScannerAsync();

    /*
    * This method is used to request the camera barcode scanner.
    * IntentAction:  The intent action to which the barcode scanner receiver is registered.
    * IntentCategory: TThe intent category to which the barcode scanner receiver is registered.
    * DataString: The intent data string key to which the barcode data is added.
    * DataFormat: The intent data format key to which the barcode format is added.
    **/
    procedure RequestBarcodeScannerAsync(IntentAction: Text; IntentCategory: Text; DataString: Text; DataFormat: Text);

    /*
    * This event is raised when the control is ready.
    * IsSupported: Whether the barcode scanner is supported on the device.
    **/
    event ControlAddInReady(IsSupported: Boolean);

    /*
    * This event is raised when the barcode is received.
    * Barcode: The barcode value
    * Format: The barcode format
    **/
    event BarcodeReceived(Barcode: Text; Format: Text)
}