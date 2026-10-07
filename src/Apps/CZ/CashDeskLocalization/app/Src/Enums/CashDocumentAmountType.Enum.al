// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.CashDesk;

enum 11737 "Cash Document Amount Type CZP"
{
    Extensible = true;

    value(0; " ")
    {
    }
    value(1; Charging)
    {
        Caption = 'Charging';
    }
    value(2; Drawing)
    {
        Caption = 'Drawing';
    }
}