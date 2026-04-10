// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Posting;

using Microsoft.Finance.ReceivablesPayables;

enum 817 "Service Invoice Posting" implements "Invoice Posting"
{
    Extensible = true;

    value(0; "Invoice Posting (Default)")
    {
        Caption = 'Invoice Posting (Default)';
        Implementation = "Invoice Posting" = "Undefined Post Invoice";
    }
    value(817; "Invoice Posting (v.19)")
    {
        Caption = 'Invoice Posting (v.19)';
        Implementation = "Invoice Posting" = "Service Post Invoice";
    }
}
