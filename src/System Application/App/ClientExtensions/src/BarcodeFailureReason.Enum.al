namespace System.ClientExtensions;

/*
* The failure reason for the barcode scanner.
*/
enum 8761 BarcodeFailureReason
{
    /*
    * The barcode scanning action was canceled.
    */
    value(0; Cancel) { }

    /*
    * No barcode was found.
    */
    value(1; NoBarcode) { }

    /*
    * An error occurred while scanning the barcode.
    */
    value(2; Error) { }
}