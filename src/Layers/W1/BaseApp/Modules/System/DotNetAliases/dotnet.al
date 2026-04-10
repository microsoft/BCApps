#pragma warning disable AA0247
dotnet
{
    assembly("Microsoft.Dynamics.Nav.Ncl")
    {
        Culture = 'neutral';
        PublicKeyToken = '31bf3856ad364e35';

        type("Microsoft.Dynamics.Nav.Runtime.AL.ALCloudMigration"; "ALCloudMigration")
        {
        }

        type("Microsoft.Dynamics.Nav.Runtime.LastError"; "LastError")
        {
        }
    }
    assembly(Microsoft.Dynamics.Nav.MX)
    {
        type(Microsoft.Dynamics.QRCode.ErrorCorrectionLevel; "QRCode Error Correction Level") { }
        type(Microsoft.Dynamics.Nav.MX.BarcodeProviders.IBarcodeProvider; "IBarcode Provider") { }
        type(Microsoft.Dynamics.Nav.MX.BarcodeProviders.QRCodeProvider; "QRCode Provider") { }
    }
    assembly(Microsoft.AspNetCore.StaticFiles)
    {
        type(Microsoft.AspNetCore.StaticFiles.FileExtensionContentTypeProvider; FileExtensionContentTypeProvider) { }
    }
}
