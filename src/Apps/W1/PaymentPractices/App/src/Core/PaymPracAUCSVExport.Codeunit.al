// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using System.Utilities;

codeunit 694 "Paym. Prac. AU CSV Export"
{
    Access = Internal;

    procedure Export(PaymentPracticeHeader: Record "Payment Practice Header")
    var
        PaymentPracticeLine: Record "Payment Practice Line";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        FileName: Text;
    begin
        PaymentPracticeHeader.TestField("Reporting Scheme", PaymentPracticeHeader."Reporting Scheme"::"Small Business");

        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);

        // Header totals
        WriteDelimitedLine(OutStream, StrSubstNo(TotalNumberOfInvoicesLbl, Format(PaymentPracticeHeader."Total Number of Payments")));
        WriteDelimitedLine(OutStream, StrSubstNo(TotalValueOfInvoicesLbl, Format(PaymentPracticeHeader."Total Amount of Payments")));
        WriteDelimitedLine(OutStream, StrSubstNo(AvgAgreedPaymentPeriodLbl, Format(PaymentPracticeHeader."Average Agreed Payment Period")));
        WriteDelimitedLine(OutStream, StrSubstNo(AvgActualPaymentPeriodLbl, Format(PaymentPracticeHeader."Average Actual Payment Period")));
        WriteDelimitedLine(OutStream, StrSubstNo(PctPaidOnTimeLbl, Format(PaymentPracticeHeader."Pct Paid on Time")));

        // Period data with invoice counts
        WriteDelimitedLine(OutStream, 'Period,Invoice Count,Invoice Value,Pct Paid in Period,Pct Paid in Period (Amount)');
        PaymentPracticeLine.SetRange("Header No.", PaymentPracticeHeader."No.");
        if PaymentPracticeLine.FindSet() then
            repeat
                WriteDelimitedLine(OutStream, StrSubstNo(PeriodDataLineLbl,
                    PaymentPracticeLine."Payment Period Description",
                    Format(PaymentPracticeLine."Invoice Count"),
                    Format(PaymentPracticeLine."Invoice Value"),
                    Format(PaymentPracticeLine."Pct Paid in Period"),
                    Format(PaymentPracticeLine."Pct Paid in Period (Amount)")));
            until PaymentPracticeLine.Next() = 0;

        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        FileName := StrSubstNo(FileNameLbl, Format(PaymentPracticeHeader."No."));
        DownloadFromStream(InStream, '', '', '', FileName);
    end;

    local procedure WriteDelimitedLine(var OutStream: OutStream; Line: Text)
    begin
        OutStream.WriteText(Line);
        OutStream.WriteText();
    end;

    var
        FileNameLbl: Label 'PaymentPractice_AU_%1.csv', Locked = true;
        TotalNumberOfInvoicesLbl: Label 'Total Number of Invoices,%1', Locked = true;
        TotalValueOfInvoicesLbl: Label 'Total Value of Invoices,%1', Locked = true;
        AvgAgreedPaymentPeriodLbl: Label 'Average Agreed Payment Period,%1', Locked = true;
        AvgActualPaymentPeriodLbl: Label 'Average Actual Payment Period,%1', Locked = true;
        PctPaidOnTimeLbl: Label 'Pct Paid on Time,%1', Locked = true;
        PeriodDataLineLbl: Label '%1,%2,%3,%4,%5', Locked = true;
}
