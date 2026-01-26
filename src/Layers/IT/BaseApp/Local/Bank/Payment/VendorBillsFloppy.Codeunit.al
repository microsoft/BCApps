// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.DirectDebit;
using Microsoft.Finance.GeneralLedger.Journal;

codeunit 12175 "Vendor Bills Floppy"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        VendorBillHeader.SetRange("No.", Rec.GetFilter("Document No."));
        if VendorBillHeader.IsEmpty() then
            Error(ExportVendBillHdrErr);
        SEPADDExportMgt.DeleteExportErrors(Rec.GetFilter("Document No."), '');
        Commit();
        REPORT.Run(REPORT::"Vendor Bills Floppy", false, false, VendorBillHeader);
    end;

    var
        VendorBillHeader: Record "Vendor Bill Header";
        ExportVendBillHdrErr: Label 'Your export format is not set up to export vendor bills with this function. Use the function in the Vendor Bill List Sent Card window instead.';
        SEPADDExportMgt: Codeunit "SEPA - DD Export Mgt.";
}

