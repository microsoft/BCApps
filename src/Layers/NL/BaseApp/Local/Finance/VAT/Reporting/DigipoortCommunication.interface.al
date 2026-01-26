// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System;
using System.Security.Encryption;

interface "DigiPoort Communication"
{
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
    procedure Deliver(Request: DotNet aanleverRequest; var Response: DotNet aanleverResponse; RequestUrl: Text; ClientCertificateBase64: Text; DotNet_SecureString: Codeunit DotNet_SecureString; ServiceCertificateBase64: Text; Timeout: Integer; UseCertificateSetup: boolean);

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
    procedure GetStatus(Request: DotNet getStatussenProcesRequest; var StatusResultatQueue: DotNet Queue; ResponseUrl: Text; ClientCertificateBase64: Text; DotNet_SecureString: Codeunit DotNet_SecureString; ServiceCertificateBase64: Text; Timeout: Integer; UseCertificateSetup: boolean);
}
