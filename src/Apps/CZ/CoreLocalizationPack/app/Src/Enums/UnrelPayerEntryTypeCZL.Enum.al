// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

enum 11705 "Unrel. Payer Entry Type CZL"
{
    Caption = 'Unreliable Payer Entry Type';
    Extensible = false;

    value(0; Payer)
    {
        Caption = 'Payer';
    }
    value(1; "Bank Account")
    {
        Caption = 'Bank Account';
    }
}
