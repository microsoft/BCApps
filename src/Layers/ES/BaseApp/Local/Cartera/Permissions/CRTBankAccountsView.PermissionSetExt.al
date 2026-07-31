// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

permissionsetextension 7000103 "CRT Bank Accounts - View" extends "Bank Accounts - View"
{
    Permissions = tabledata "Bill Group" = R,
                  tabledata "Cartera Doc." = R,
                  tabledata "Closed Bill Group" = R,
                  tabledata "Closed Cartera Doc." = R,
                  tabledata "Closed Payment Order" = R,
                  tabledata "Payment Order" = R,
                  tabledata "Posted Bill Group" = R,
                  tabledata "Posted Cartera Doc." = R,
                  tabledata "Posted Payment Order" = R;
}
