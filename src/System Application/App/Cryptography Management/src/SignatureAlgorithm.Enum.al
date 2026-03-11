// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.Encryption;

/// <summary>
/// Specifies the types of asymmetric algorithms.
/// </summary>
enum 1446 SignatureAlgorithm implements "Signature Algorithm v2"
{
    Extensible = false;

    /// <summary>
    /// Specifies the RSA algorithm implemented by RSACryptoServiceProvider
    /// </summary>
    value(0; RSA)
    {
        Implementation = "Signature Algorithm v2" = "RSACryptoServiceProvider Impl.";
    }

    /// <summary>
    /// Specifies the DSA algorithm implemented by DSACryptoServiceProvider
    /// </summary>
    value(1; DSA)
    {

        Implementation = "Signature Algorithm v2" = "DSACryptoServiceProvider Impl.";
    }
    /// <summary>
    /// Specifies the RSASSA-PSS algorithm implemented by RSA
    /// </summary>
    value(2; "RSASSA-PSS")
    {
        Implementation = "Signature Algorithm v2" = "RSA Impl.";
    }
}