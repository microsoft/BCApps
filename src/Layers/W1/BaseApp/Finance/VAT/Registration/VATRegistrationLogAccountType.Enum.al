// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

#pragma warning disable AL0659
/// <summary>
/// Defines account types that can be validated through VAT registration number verification services.
/// Enables logging and tracking VAT validation results across different entity types.
/// </summary>
enum 240 "VAT Registration Log Account Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Customer account VAT registration validation.
    /// </summary>
    value(0; "Customer") { Caption = 'Customer'; }
    /// <summary>
    /// Vendor account VAT registration validation.
    /// </summary>
    value(1; "Vendor") { Caption = 'Vendor'; }
    /// <summary>
    /// Contact VAT registration validation.
    /// </summary>
    value(2; "Contact") { Caption = 'Contact'; }
    /// <summary>
    /// Company information VAT registration validation.
    /// </summary>
    value(3; "Company Information") { Caption = 'Company Information'; }
}
