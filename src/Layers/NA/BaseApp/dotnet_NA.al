#pragma warning disable AA0247
dotnet
{
    assembly("Microsoft.Dynamics.Nav.MX")
    {
        Culture = 'neutral';
        PublicKeyToken = '31bf3856ad364e35';

        type("Microsoft.Dynamics.Nav.MX.SignatureProviders.CFDISignatureProvider"; "CFDISignatureProvider")
        {
        }
        type("Microsoft.Dynamics.Nav.MX.WebServiceInvokers.SOAPWebServiceInvoker"; "SOAPWebServiceInvoker")
        {
        }
    }
}
