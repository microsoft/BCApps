// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.GeneralLedger.Journal;

codeunit 7000060 "PO - Export N34.1"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        PaymentOrder: Record "Payment Order";
    begin
        PaymentOrder.SetRange("No.", Rec.GetFilter("Document No."));
        if PaymentOrder.IsEmpty() then
            Error(ExportPaymentErr);
        Commit();
        REPORT.Run(REPORT::"PO - Export N34.1", true, false, PaymentOrder);
    end;

    var
        ExportPaymentErr: Label 'You cannot export payments from Payment Journal with the selected Payment Export Format in Bal. Account No.';
}

