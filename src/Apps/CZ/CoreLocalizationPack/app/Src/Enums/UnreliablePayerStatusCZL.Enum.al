// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

enum 11706 "Unreliable Payer Status CZL"
{
    Caption = 'Unreliable Payer Status';
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; NO)
    {
        Caption = 'NO';
    }
    value(2; YES)
    {
        Caption = 'YES';
    }
    value(3; NOTFOUND)
    {
        Caption = 'NOTFOUND';
    }
}