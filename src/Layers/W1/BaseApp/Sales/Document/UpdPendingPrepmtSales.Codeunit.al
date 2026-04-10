// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.ReceivablesPayables;

/// <summary>
/// Updates the pending prepayment status for sales documents based on payment activity.
/// </summary>
codeunit 383 "Upd. Pending Prepmt. Sales"
{

    trigger OnRun()
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
    begin
        PrepaymentMgt.UpdatePendingPrepaymentSales();
    end;
}

