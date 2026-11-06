// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QRGeneration;

using System.Text;
using System.Utilities;

codeunit 18650 "QR Generator"
{
    [TryFunction]
    procedure GenerateQRCodeImage(SourceText: Text; var TempBlob: Codeunit "Temp Blob")
    var
        TempBarcodeEncodeSettings2D: Record "Barcode Encode Settings 2D";
        QRCodeImageTempBlob: Codeunit "Temp Blob";
        BarcodeImageProvider2D: Interface "Barcode Image Provider 2D";
        OutStream: OutStream;
        InStream: InStream;
    begin
        TempBlob.CreateOutStream(OutStream);

        // Preserve the rendering defaults of the original QRCodeProvider overload.
        TempBarcodeEncodeSettings2D.Init();
        TempBarcodeEncodeSettings2D."Error Correction Level" := TempBarcodeEncodeSettings2D."Error Correction Level"::Low;
        TempBarcodeEncodeSettings2D."Module Size" := 3;
        TempBarcodeEncodeSettings2D."Quite Zone Width" := 4;
        TempBarcodeEncodeSettings2D."Code Page" := 28591;

        BarcodeImageProvider2D := Enum::"Barcode Image Provider 2D"::Dynamics2D;
        QRCodeImageTempBlob := BarcodeImageProvider2D.EncodeImage(
            SourceText, Enum::"Barcode Symbology 2D"::"QR-Code", TempBarcodeEncodeSettings2D);
        QRCodeImageTempBlob.CreateInStream(InStream);
        CopyStream(OutStream, InStream);
    end;
}
