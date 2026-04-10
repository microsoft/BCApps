// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

/// <summary>
/// Defines consistency validation strategies for alternative customer VAT registrations.
/// Provides extensible framework for implementing custom validation rules and business logic.
/// </summary>
enum 204 "Alt. Cust. VAT Reg. Consist." implements "Alt. Cust. VAT Reg. Consist."
{
    Extensible = true;
    DefaultImplementation = "Alt. Cust. VAT Reg. Consist." = "Alt. Cust. VAT Reg. Cons.Impl.";

    /// <summary>
    /// Default consistency validation using standard Business Central validation rules.
    /// </summary>
    value(0; Default)
    {
    }
}