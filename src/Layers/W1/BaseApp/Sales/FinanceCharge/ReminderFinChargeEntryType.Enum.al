// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

enum 302 "Reminder/Fin.ChargeEntry Type"
{
    Extensible = true;

    value(0; Reminder)
    {
        Caption = 'Reminder';
    }
    value(1; "Finance Charge Memo")
    {
        Caption = 'Finance Charge Memo';
    }
}