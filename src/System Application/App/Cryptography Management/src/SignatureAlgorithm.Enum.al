// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.Encryption;

/// <summary>
/// Specifies the types of asymmetric algorithms.
/// </summary>
#if not CLEAN24
#pragma warning disable AL0432
enum 1446 SignatureAlgorithm implements SignatureAlgorithm, "Signature Algorithm v2"
#pragma warning restore AL0432
#else
enum 1446 SignatureAlgorithm implements "Signature Algorithm v2"
#endif
{
    Extensible = false;

    /// <summary>
    /// Specifies the RSA algorithm implemented by RSACryptoServiceProvider
    /// </summary>
    value(0; RSA)
    {
#if not CLEAN24
        Implementation = SignatureAlgorithm = "RSACryptoServiceProvider Impl.",
                            "Signature Algorithm v2" = "RSACryptoServiceProvider Impl.";
#else
        Implementation = "Signature Algorithm v2" = "RSACryptoServiceProvider Impl.";
#endif
    }

    /// <summary>
    /// Specifies the DSA algorithm implemented by DSACryptoServiceProvider
    /// </summary>
    value(1; DSA)
    {

#if not CLEAN24
        Implementation = SignatureAlgorithm = "DSACryptoServiceProvider Impl.",
                            "Signature Algorithm v2" = "DSACryptoServiceProvider Impl.";
#else
        Implementation = "Signature Algorithm v2" = "DSACryptoServiceProvider Impl.";
#endif
    }
    /// <summary>
    /// Specifies the RSASSA-PSS algorithm implemented by RSA
    /// </summary>
    value(2; "RSASSA-PSS")
    {
#if not CLEAN24
        Implementation = SignatureAlgorithm = "RSA Impl.",
                            "Signature Algorithm v2" = "RSA Impl.";
#else
        Implementation = "Signature Algorithm v2" = "RSA Impl.";
#endif
    }
}