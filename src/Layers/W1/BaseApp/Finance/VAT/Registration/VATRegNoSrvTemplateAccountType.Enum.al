// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

#pragma warning disable AL0659
/// <summary>
/// Defines account types for VAT registration service template configuration.
/// Controls which entity types can use specific validation templates for VAT number verification.
/// </summary>
enum 241 "VAT Reg. No. Srv. Template Account Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// No specific account type restriction - template applies to all account types.
    /// </summary>
    value(0; None)
    {
        Caption = ' ';
    }
    /// <summary>
    /// Template applies specifically to customer account VAT validation.
    /// </summary>
    value(1; Customer)
    {
        Caption = 'Customer';
    }
    /// <summary>
    /// Template applies specifically to vendor account VAT validation.
    /// </summary>
    value(2; Vendor)
    {
        Caption = 'Vendor';
    }
    /// <summary>
    /// Template applies specifically to contact VAT validation.
    /// </summary>
    value(3; Contact)
    {
        Caption = 'Contact';
    }
}
