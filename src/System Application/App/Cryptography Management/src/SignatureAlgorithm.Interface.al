#if not CLEAN24
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.Encryption;

using System;

interface SignatureAlgorithm
{
    ObsoleteReason = 'Replaced by Signature Algorithm v2 with SecretText support for XmlString.';
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';

    procedure GetInstance(var DotNetAsymmetricAlgorithm: DotNet AsymmetricAlgorithm);
    procedure FromXmlString(XmlString: Text);
    procedure SignData(DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; SignatureOutStream: OutStream);
    procedure ToXmlString(IncludePrivateParameters: Boolean): Text;
    procedure VerifyData(DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; SignatureInStream: InStream): Boolean;
}
#endif