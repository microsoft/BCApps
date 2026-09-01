// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using System;
codeunit 10174 "EInvoice OnPrem Communication" implements "EInvoice Communication V2"
{
    Access = Internal;

    var
        Parameters: DotNet GenericList1;


    [NonDebuggable]
    procedure InvokeMethodWithCertificate(Uri: Text; MethodName: Text; CertBase64: Text; CertPassword: SecretText) Response: Text;
    begin
        if not TryToInvokeMethodWithCertificate(Uri, MethodName, CertBase64, CertPassword, Response) then
            Error(GetLastErrorText());
    end;

    [NonDebuggable]
    procedure SignDataWithCertificate(OriginalString: Text; Cert: Text; CertPassword: SecretText) Response: Text;
    begin
        if not TryToSignDataWithCertificate(OriginalString, Cert, CertPassword, Response) then
            Error(GetLastErrorText());
    end;

    [NonDebuggable]
    [TryFunction]
    local procedure TryToInvokeMethodWithCertificate(Uri: Text; MethodName: Text; CertBase64: Text; CertPassword: SecretText; var Response: Text);
    var
        SOAPWebServiceInvoker: DotNet SOAPWebServiceInvoker;
    begin
        Response := SOAPWebServiceInvoker.InvokeMethodWithCertificate(Uri, MethodName, CertBase64, CertPassword.Unwrap(), Parameters);
    end;

    [NonDebuggable]
    [TryFunction]
    local procedure TryToSignDataWithCertificate(OriginalString: Text; Cert: Text; CertPassword: SecretText; var Response: Text);
    var
        CFDISignatureProvider: DotNet CFDISignatureProvider;
    begin
        Response := CFDISignatureProvider.SignDataWithCertificate(OriginalString, Cert, CertPassword.Unwrap());
    end;

    procedure AddParameters(Parameter: Variant)
    begin
        if IsNull(Parameters) then
            Parameters := Parameters.List();
        Parameters.Add(Parameter);
    end;
}