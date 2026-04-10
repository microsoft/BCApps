// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

/// <summary>
/// Defines options for ship-to address alternative customer VAT registration number handling.
/// Supports extensible VAT registration strategies for different shipping scenarios and jurisdictions.
/// </summary>
enum 206 "Ship-To Alt. Cust. VAT Reg." implements "Ship-To Alt. Cust. VAT Reg."
{
    Extensible = true;
    DefaultImplementation = "Ship-To Alt. Cust. VAT Reg." = "Ship Alt. Cust. VAT Reg. Impl.";

    /// <summary>
    /// Default VAT registration handling using standard customer VAT registration number.
    /// </summary>
    value(0; Default)
    {
    }
}