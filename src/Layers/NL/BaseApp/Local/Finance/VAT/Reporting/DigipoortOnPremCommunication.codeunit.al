// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System;
using System.Security.Encryption;

codeunit 11000052 "Digipoort Onprem Communication" implements "DigiPoort Communication"
{
    Access = Internal;

    [NonDebuggable]
    procedure Deliver(Request: DotNet aanleverRequest; var Response: DotNet aanleverResponse; RequestUrl: Text; ClientCertificateBase64: Text; DotNetSecureString: Codeunit DotNet_SecureString; ServiceCertificateBase64: Text; Timeout: Integer; UseCertificateSetup: boolean)
    begin
        if not TryToDeliver(Request, Response, RequestUrl, ClientCertificateBase64, DotNetSecureString, ServiceCertificateBase64, Timeout, UseCertificateSetup) then
            Error(GetLastErrorText());
    end;

    [NonDebuggable]
    procedure GetStatus(Request: DotNet getStatussenProcesRequest; var StatusResultatQueue: DotNet Queue; ResponseUrl: Text; ClientCertificateBase64: Text; DotNetSecureString: Codeunit DotNet_SecureString; ServiceCertificateBase64: Text; Timeout: Integer; UseCertificateSetup: boolean)

    begin
        if not TryToGetStatus(Request, StatusResultatQueue, ResponseUrl, ClientCertificateBase64, DotNetSecureString, ServiceCertificateBase64, Timeout, UseCertificateSetup) then
            Error(GetLastErrorText());
    end;

    [NonDebuggable]
    [TryFunction]
    local procedure TryToDeliver(Request: DotNet aanleverRequest; var Response: DotNet aanleverResponse; RequestUrl: Text; ClientCertificateBase64: Text; DotNetSecureString: Codeunit DotNet_SecureString; ServiceCertificateBase64: Text; Timeout: Integer; UseCertificateSetup: boolean)
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        DigipoortServices: DotNet DigipoortServices;
        SecureString: DotNet SecureString;
    begin
        if UseCertificateSetup then begin
            DotNetSecureString.GetSecureString(SecureString);
            Response := DigipoortServices.Deliver(Request,
                            RequestUrl,
                            ClientCertificateBase64,
                            SecureString,
                            ServiceCertificateBase64,
                            Timeout);
        end else begin
            ElecTaxDeclarationSetup.Get();
            Response := DigipoortServices.Deliver(Request,
                RequestUrl,
                ElecTaxDeclarationSetup."Digipoort Client Cert. Name",
                ElecTaxDeclarationSetup."Digipoort Service Cert. Name",
                Timeout);
        end;
    end;

    [NonDebuggable]
    [TryFunction]
    local procedure TryToGetStatus(Request: DotNet getStatussenProcesRequest; var StatusResultatQueue: DotNet Queue; ResponseUrl: Text; ClientCertificateBase64: Text; DotNetSecureString: Codeunit DotNet_SecureString; ServiceCertificateBase64: Text; Timeout: Integer; UseCertificateSetup: boolean)
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        DigipoortServices: DotNet DigipoortServices;
        SecureString: DotNet SecureString;
    begin
        if UseCertificateSetup then begin
            DotNetSecureString.GetSecureString(SecureString);
            StatusResultatQueue := DigipoortServices.GetStatus(Request,
                            ResponseUrl,
                            ClientCertificateBase64,
                            SecureString,
                            ServiceCertificateBase64,
                            Timeout);
        end else begin
            ElecTaxDeclarationSetup.Get();
            StatusResultatQueue := DigipoortServices.GetStatus(Request,
                ResponseUrl,
                ElecTaxDeclarationSetup."Digipoort Client Cert. Name",
                ElecTaxDeclarationSetup."Digipoort Service Cert. Name",
                Timeout);
        end;
    end;
}
