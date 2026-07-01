// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Finance.ReceivablesPayables;

codeunit 384 "Upd. Pending Prepmt. Purchase"
{

    trigger OnRun()
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
    begin
        PrepaymentMgt.UpdatePendingPrepaymentPurchase();
    end;
}

