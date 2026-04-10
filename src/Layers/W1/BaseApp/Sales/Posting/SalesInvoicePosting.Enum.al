// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.Finance.ReceivablesPayables;

/// <summary>
/// Defines the available invoice posting implementations for sales documents.
/// </summary>
enum 815 "Sales Invoice Posting" implements "Invoice Posting"
{
    Extensible = true;

    /// <summary>
    /// Represents the default invoice posting implementation that is undefined and requires configuration.
    /// </summary>
    value(0; "Invoice Posting (Default)")
    {
        Caption = 'Invoice Posting (Default)';
        Implementation = "Invoice Posting" = "Undefined Post Invoice";
    }
    /// <summary>
    /// Represents the sales invoice posting implementation introduced in version 19.
    /// </summary>
    value(815; "Invoice Posting (v.19)")
    {
        Caption = 'Invoice Posting (v.19)';
        Implementation = "Invoice Posting" = "Sales Post Invoice";
    }
}
