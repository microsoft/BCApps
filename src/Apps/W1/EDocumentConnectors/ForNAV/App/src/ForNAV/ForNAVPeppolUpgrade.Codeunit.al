namespace Microsoft.EServices.EDocumentConnector.ForNAV;
codeunit 6413 "ForNAV Peppol Upgrade"
{
    Subtype = Upgrade;
    Access = Internal;

    trigger OnUpgradePerCompany()
    var
        PeppolOauth: Codeunit "ForNAV Peppol Oauth";
    begin
        PeppolOauth.ValidateEndpoint(PeppolOauth.GetDefaultEndpoint(), true);
    end;
}