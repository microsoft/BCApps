// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.Encryption;

using System;
using System.Utilities;

codeunit 1473 "Signature Key Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TempBlob: Codeunit "Temp Blob";
        CertInitializeErr: Label 'Unable to initialize certificate!';

    procedure FromXmlString(XmlString: SecretText)
    begin
        WriteKeyValue(XmlString);
    end;

    procedure FromBase64String(CertBase64Value: Text; Password: SecretText; IncludePrivateParameters: Boolean)
    var
        X509Certificate2: DotNet X509Certificate2;
    begin
        if not TryInitializeCertificateFromBase64Format(CertBase64Value, Password, X509Certificate2) then
            Error(CertInitializeErr);
        FromXmlString(X509Certificate2.PrivateKey.ToXmlString(IncludePrivateParameters));
    end;

    internal procedure ToXmlString(): SecretText
    begin
        exit(ReadKeyValue());
    end;

    [NonDebuggable]
    [TryFunction]
    local procedure TryInitializeCertificateFromBase64Format(CertBase64Value: Text; Password: SecretText; var X509Certificate2: DotNet X509Certificate2)
    var
        X509KeyStorageFlags: DotNet X509KeyStorageFlags;
        Convert: DotNet Convert;
    begin
        X509Certificate2 := X509Certificate2.X509Certificate2(Convert.FromBase64String(CertBase64Value), Password.Unwrap(), X509KeyStorageFlags.Exportable);
    end;

    [NonDebuggable]
    local procedure WriteKeyValue(KeyValue: SecretText)
    var
        KeyValueOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(KeyValueOutStream, TextEncoding::UTF8);
        KeyValueOutStream.Write(KeyValue.Unwrap());
    end;

    [NonDebuggable]
    local procedure ReadKeyValue() SecretKeyValue: SecretText
    var
        KeyValueInStream: InStream;
        KeyValue: Text;
    begin
        TempBlob.CreateInStream(KeyValueInStream, TextEncoding::UTF8);
        KeyValueInStream.Read(KeyValue);
        SecretKeyValue := KeyValue;
    end;
}