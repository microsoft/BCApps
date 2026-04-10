// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

/// <summary>
/// Defines document types for alternative customer VAT registration processing.
/// Supports extensible document handling strategies for different VAT registration scenarios.
/// </summary>
enum 205 "Alt. Cust VAT Reg. Doc." implements "Alt. Cust. VAT Reg. Doc."
{
    Extensible = true;
    DefaultImplementation = "Alt. Cust. VAT Reg. Doc." = "Alt. Cust. VAT Reg. Doc. Impl.";

    /// <summary>
    /// Default document processing for alternative customer VAT registration.
    /// </summary>
    value(0; Default)
    {
    }
}