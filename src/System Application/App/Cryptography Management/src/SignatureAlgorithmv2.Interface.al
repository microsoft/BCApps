// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.Encryption;

using System;

interface "Signature Algorithm v2"
{
    procedure GetInstance(var DotNetAsymmetricAlgorithm: DotNet AsymmetricAlgorithm);
    procedure FromSecretXmlString(XmlString: SecretText);
    procedure SignData(DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; SignatureOutStream: OutStream);
    procedure ToSecretXmlString(IncludePrivateParameters: Boolean): SecretText;
    procedure VerifyData(DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; SignatureInStream: InStream): Boolean;
}