// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

enum 11707 "Unrel. Payer Bank Acc.Type CZL"
{
    Caption = 'Unreliable Payer Bank Account Type';
    Extensible = false;

#pragma warning disable AC0019
    value(0; Standard)
    {
        Caption = 'Standard';
    }
#pragma warning restore AC0019
    value(1; "Not Standard")
    {
        Caption = 'Nonstandard';
    }
}
