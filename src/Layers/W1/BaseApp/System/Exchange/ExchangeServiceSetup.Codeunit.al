namespace System.Integration;

using Microsoft.CRM.Outlook;

codeunit 5324 "Exchange Service Setup"
{

    trigger OnRun()
    begin
    end;

    procedure Store(ClientID: Guid; CertificateThumbprint: Text[40]; AuthenticationEndpoint: Text[250]; ExchangeEndpoint: Text[250]; ExchangeResourceUri: Text[250])
    var
        ExchangeServiceSetup: Record "Exchange Service Setup";
    begin
        ExchangeServiceSetup.Init();
        ExchangeServiceSetup."Azure AD App. ID" := ClientID;
        ExchangeServiceSetup."Azure AD App. Cert. Thumbprint" := CertificateThumbprint;
        ExchangeServiceSetup."Azure AD Auth. Endpoint" := AuthenticationEndpoint;
        ExchangeServiceSetup."Exchange Service Endpoint" := ExchangeEndpoint;
        ExchangeServiceSetup."Exchange Resource Uri" := ExchangeResourceUri;
        if not ExchangeServiceSetup.Insert() then
            ExchangeServiceSetup.Modify();
    end;
}

