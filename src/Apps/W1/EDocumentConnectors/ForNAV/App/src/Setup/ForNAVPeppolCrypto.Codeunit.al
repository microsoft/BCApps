// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using System.Security.Encryption;
codeunit 6421 "ForNAV Peppol Crypto"
{
    Access = Internal;

    internal procedure TestHash(NewHash: Text; InputString: Text; KeyValue: SecretText)
    var
        InvalidKeyErr: Label 'Invalid setup key. Contact your ForNAV partner.';
    begin
        if NewHash <> Hash(InputString, KeyValue) then
            Error(InvalidKeyErr);
    end;

    internal procedure Hash(InputString: Text; KeyValue: SecretText): Text
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        PeppolOauth: Codeunit "ForNAV Peppol Oauth";
    begin
        exit(CryptographyManagement.GenerateHash(InputString, SecretStrSubstNo('%1-%2', PeppolOauth.GetSetupKey(), KeyValue), 2));
    end;
}