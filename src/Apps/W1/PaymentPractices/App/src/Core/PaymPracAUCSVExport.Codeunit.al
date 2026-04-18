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
        WriteDelimitedLine(OutStream, 'Total Number of Invoices,' + Format(PaymentPracticeHeader."Total Number of Payments"));
        WriteDelimitedLine(OutStream, 'Total Value of Invoices,' + Format(PaymentPracticeHeader."Total Amount of Payments"));
        WriteDelimitedLine(OutStream, 'Average Agreed Payment Period,' + Format(PaymentPracticeHeader."Average Agreed Payment Period"));
        WriteDelimitedLine(OutStream, 'Average Actual Payment Period,' + Format(PaymentPracticeHeader."Average Actual Payment Period"));
        WriteDelimitedLine(OutStream, 'Pct Paid on Time,' + Format(PaymentPracticeHeader."Pct Paid on Time"));

        // Period data with invoice counts
        WriteDelimitedLine(OutStream, 'Period,Invoice Count,Invoice Value,Pct Paid in Period,Pct Paid in Period (Amount)');
        PaymentPracticeLine.SetRange("Header No.", PaymentPracticeHeader."No.");
        if PaymentPracticeLine.FindSet() then
            repeat
                WriteDelimitedLine(OutStream, PaymentPracticeLine."Payment Period Description" + ',' +
                    Format(PaymentPracticeLine."Invoice Count") + ',' +
                    Format(PaymentPracticeLine."Invoice Value") + ',' +
                    Format(PaymentPracticeLine."Pct Paid in Period") + ',' +
                    Format(PaymentPracticeLine."Pct Paid in Period (Amount)"));
            until PaymentPracticeLine.Next() = 0;

        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        FileName := 'PaymentPractice_AU_' + Format(PaymentPracticeHeader."No.") + '.csv';
        DownloadFromStream(InStream, '', '', '', FileName);
    end;

    local procedure WriteDelimitedLine(var OutStream: OutStream; Line: Text)
    begin
        OutStream.WriteText(Line);
        OutStream.WriteText();
    end;
}
