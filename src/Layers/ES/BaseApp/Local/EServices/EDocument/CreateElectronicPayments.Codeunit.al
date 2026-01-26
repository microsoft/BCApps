// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Journal;
using System.IO;
using System.Utilities;

codeunit 10721 "Create Electronic Payments"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        GenJnlLine: Record "Gen. Journal Line";
        ExportElectronicPayments: Report "Export Electronic Payments";
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        InStream: InStream;
    begin
        GenJnlLine.CopyFilters(Rec);
        GenJnlLine.LockTable();
        if GenJnlLine.IsEmpty() then
            Error(ExportPaymentErr);
        Commit();

        ExportElectronicPayments.UseRequestPage(true);
        ExportElectronicPayments.SetTableView(GenJnlLine);
        ExportElectronicPayments.RunModal();

        ExportElectronicPayments.GetEPayFileContent(TempBlob);
        if TempBlob.HasValue() then
            if Confirm(DownloadEPayFileQst) then begin
                TempBlob.CreateInStream(InStream);
                FileMgt.DownloadFromStreamHandler(InStream, '', '', '', ExportElectronicPayments.GetEPayFileName());
            end;
    end;

    var
        ExportPaymentErr: Label 'You cannot export the payment order with the selected Bank Export Format in Bank Account No.';
        DownloadEPayFileQst: Label 'Do you also want to download the E-Pay export file?';
}

