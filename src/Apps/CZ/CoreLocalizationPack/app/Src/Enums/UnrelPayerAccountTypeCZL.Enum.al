// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

enum 11708 "Unrel. Payer Account Type CZL" implements "Unreliable Account CZL"
{
    Caption = 'Unreliable Payer Account Type';
    Extensible = true;

    value(0; "Vendor")
    {
        Caption = 'Vendor';
        Implementation = "Unreliable Account CZL" = "Unrel. Account - Vendor CZL";
    }
    value(1; "Customer")
    {
        Caption = 'Customer';
        Implementation = "Unreliable Account CZL" = "Unrel. Account - Customer CZL";
    }
}