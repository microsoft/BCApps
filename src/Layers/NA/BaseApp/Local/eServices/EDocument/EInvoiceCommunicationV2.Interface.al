// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

interface "EInvoice Communication V2"
{
    /// <summary>
    /// Sends request to PAC service with a specific method.
    /// </summary>
    /// <param name="Uri">Uri of the service</param>
    /// <param name="MethodName">Method name</param>
    /// <param name="CertBase64">PAC certificate as base64</param>
    /// <param name="CertPassword">Certificate password</param>
    /// <returns>Response as a string.</returns>
    procedure InvokeMethodWithCertificate(Uri: Text; MethodName: Text; CertBase64: Text; CertPassword: SecretText): Text;

    /// <summary>
    /// Signs data before sending it to PAC service.
    /// </summary>
    /// <param name="OriginalString">String to sign</param>
    /// <param name="CertBase64">SAT certificate as base64</param>
    /// <param name="CertPassword">Certificate password</param>
    /// <returns>Signed data as a string.</returns>
    procedure SignDataWithCertificate(OriginalString: Text; CertBase64: Text; CertPassword: SecretText): Text;

    /// <summary>
    /// Adds a parameter to the request.
    /// </summary>
    /// <param name="Parameter">Parameter that accepts different data type like string, or boolean</param>
    procedure AddParameters(Parameter: Variant);
}
