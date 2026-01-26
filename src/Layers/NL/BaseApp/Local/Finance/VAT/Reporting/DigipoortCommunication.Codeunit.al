// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System;
using System.Environment;
using System.Security.Encryption;

codeunit 11000054 "Digipoort Communication"
{
    var
        DigiPoortCommunication: Interface "DigiPoort Communication";
        Initialized: Boolean;

    /// <summary>
    /// Delivers request to DigiPoort Service.
    /// </summary>
    /// <param name="Request">Request to send to the service</param>
    /// <param name="Response">Response received from the service</param>
    /// <param name="RequestUrl">Request endpoint</param>
    /// <param name="ClientCertificateBase64">Client certificate as base64</param>
    /// <param name="DotNetSecureString">Client certificate password as securestring</param>
    /// <param name="ServiceCertificateBase64">Server Certificate as base64</param>
    /// <param name="Timeout">Request timeout</param>
    /// <param name="UseCertificateSetup">Whether to use certificate setup or local certificate store</param>
    [NonDebuggable]
    procedure Deliver(Request: DotNet aanleverRequest; var Response: DotNet aanleverResponse; RequestUrl: Text; ClientCertificateBase64: Text; DotNetSecureString: Codeunit DotNet_SecureString; ServiceCertificateBase64: Text; Timeout: Integer; UseCertificateSetup: boolean)
    begin
        Init();
        DigiPoortCommunication.Deliver(Request, Response, RequestUrl, ClientCertificateBase64,
            DotNetSecureString, ServiceCertificateBase64, Timeout, UseCertificateSetup);
    end;

    /// <summary>
    /// Gets status from DigiPoort Service.
    /// </summary>
    /// <param name="Request">Request to send to the service</param>
    /// <param name="StatusResultatQueue">Response received from the service</param>
    /// <param name="ResponseUrl">Response endpoint</param>
    /// <param name="ClientCertificateBase64">Client certificate as base64</param>
    /// <param name="DotNetSecureString">Client certificate password as securestring</param>
    /// <param name="ServiceCertificateBase64">Server Certificate as base64</param>
    /// <param name="Timeout">Request timeout</param>
    /// <param name="UseCertificateSetup">Whether to use certificate setup or local certificate store</param>
    [NonDebuggable]
    procedure GetStatus(Request: DotNet getStatussenProcesRequest; var StatusResultatQueue: DotNet Queue; ResponseUrl: Text; ClientCertificateBase64: Text; DotNetSecureString: Codeunit DotNet_SecureString; ServiceCertificateBase64: Text; Timeout: Integer; UseCertificateSetup: boolean);
    begin
        Init();
        DigiPoortCommunication.GetStatus(Request, StatusResultatQueue, ResponseUrl, ClientCertificateBase64,
            DotNetSecureString, ServiceCertificateBase64, Timeout, UseCertificateSetup);
    end;

    local procedure Init()
    var
        DigipoortOnpremCommunication: Codeunit "Digipoort Onprem Communication";
        DigipoortSaaSCommunication: Codeunit "Digipoort SaaS Communication";
        EnvironmentInformation: Codeunit "Environment Information";
        IsHandled: Boolean;
    begin
        if Initialized then
            exit;

        IsHandled := false;
        OnBeforeInit(DigiPoortCommunication, IsHandled);
        if IsHandled then
            exit;

        if EnvironmentInformation.IsSaaS() then
            DigiPoortCommunication := DigipoortSaaSCommunication
        else
            DigiPoortCommunication := DigipoortOnpremCommunication;

        Initialized := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInit(var DigiPoortCommunication: Interface "DigiPoort Communication"; var IsHandled: Boolean)
    begin
    end;
}
