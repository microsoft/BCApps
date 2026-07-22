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

permissionsetextension 7000101 "CRT LOCAL READ" extends "LOCAL READ"
{
    Permissions = tabledata "BG/PO Comment Line" = R,
                  tabledata "BG/PO Post. Buffer" = R,
                  tabledata "Bill Group" = R,
                  tabledata "Cartera Doc." = R,
                  tabledata "Cartera Report Selections" = R,
                  tabledata "Cartera Setup" = R,
                  tabledata "Closed Bill Group" = R,
                  tabledata "Closed Cartera Doc." = R,
                  tabledata "Closed Payment Order" = R,
                  tabledata "Customer Rating" = R,
                  tabledata "Doc. Post. Buffer" = R,
                  tabledata "Fee Range" = R,
                  tabledata Installment = R,
                  tabledata "Non-Payment Period" = R,
                  tabledata "Operation Fee" = R,
                  tabledata "Payment Day" = R,
                  tabledata "Payment Order" = R,
                  tabledata "Posted Bill Group" = R,
                  tabledata "Posted Cartera Doc." = R,
                  tabledata "Posted Payment Order" = R,
                  tabledata Suffix = R;
}
