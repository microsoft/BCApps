// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Foundation.Company;
using System.IO;
using System.Utilities;

codeunit 684 "Paym. Prac. GB CSV Export"
{
    Access = Internal;

    procedure Export(PaymentPracticeHeader: Record "Payment Practice Header")
    var
        FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        FileName: Text;
        HeaderRow: Text;
        DataRow: Text;
    begin
        PaymentPracticeHeader.TestField("Reporting Scheme", PaymentPracticeHeader."Reporting Scheme"::"Dispute & Retention");

        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);

        HeaderRow := BuildHeaderRow();
        OutStream.WriteText(HeaderRow);
        OutStream.WriteText();

        DataRow := BuildDataRow(PaymentPracticeHeader);
        OutStream.WriteText(DataRow);
        OutStream.WriteText();

        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        FileName := 'PaymentPractice_GB_' + Format(PaymentPracticeHeader."No.") + '.csv';
        FileMgt.DownloadFromStreamHandler(InStream, '', '', '', FileName);
    end;

    internal procedure BuildHeaderRow(): Text
    begin
        exit(
            'Report Id,' +
            'Policy Regime,' +
            'Financial period start date,' +
            'Start date,' +
            'End date,' +
            'Filing date,' +
            'Company,' +
            'Company number,' +
            'Qualifying contracts in reporting period,' +
            'Payments made in reporting period,' +
            'Qualifying construction contracts in reporting period,' +
            'Construction contracts have retention clauses,' +
            'Average time to pay,' +
            'Total value invoices paid within 30 days,' +
            'Total value invoices paid between 31 and 60 days,' +
            'Total value invoices paid later than 60 days,' +
            '% Invoices paid within 30 days,' +
            '% Invoices paid between 31 and 60 days,' +
            '% Invoices paid later than 60 days,' +
            'Total value invoices paid later than agreed terms,' +
            '% Invoices not paid within agreed terms,' +
            '% Invoices not paid due to dispute,' +
            'Shortest (or only) standard payment period,' +
            'Longest standard payment period,' +
            'Standard payment terms,' +
            'Payment terms have changed,' +
            'Suppliers notified of changes,' +
            'Maximum contractual payment period,' +
            'Maximum contractual payment period information,' +
            'Other information payment terms,' +
            'Retention clauses included in all construction contracts,' +
            'Retention clauses included in standard payment terms,' +
            'Retention clauses are used in specific circumstances,' +
            'Description of specific circumstances for retention clauses,' +
            'Retention clauses used above a specific sum,' +
            'Value above which retention clauses are used,' +
            'Retention clauses are at a standard rate,' +
            'Retention clauses standard rate percentage,' +
            'Retention clauses have parity with client,' +
            'Description of parity policy,' +
            'Retention clause money release description,' +
            'Retention clause money release is staged,' +
            'Description of stages for money release,' +
            'Retention value compared to client retentions as %,' +
            'Retention value compared to total payments as %,' +
            'Dispute resolution process,' +
            'Participates in payment codes,' +
            'E-Invoicing offered,' +
            'Supply-chain financing offered,' +
            'Policy covers charges for remaining on supplier list,' +
            'Charges have been made for remaining on supplier list,' +
            'URL');
    end;

    internal procedure BuildDataRow(PaymentPracticeHeader: Record "Payment Practice Header"): Text
    var
        CompanyInformation: Record "Company Information";
        DisputeRetData: Record "Paym. Prac. Dispute Ret. Data";
        Cols: List of [Text];
        PctWithin30: Decimal;
        Pct31to60: Decimal;
        PctOver60: Decimal;
        ValWithin30: Decimal;
        Val31to60: Decimal;
        ValOver60: Decimal;
        HasValues: Boolean;
        FilingDate: Date;
    begin
        CompanyInformation.Get();
        DisputeRetData.Get(PaymentPracticeHeader."No.");

        GetPeriodPercentages(
            PaymentPracticeHeader, PctWithin30, Pct31to60, PctOver60,
            ValWithin30, Val31to60, ValOver60, HasValues);

        // 1: Report Id
        Cols.Add(Format(PaymentPracticeHeader."No."));
        // 2: Policy Regime
        Cols.Add('Regime-1');
        // 3: Financial period start date
        Cols.Add('None');
        // 4: Start date
        Cols.Add(FormatDateGov(PaymentPracticeHeader."Starting Date"));
        // 5: End date
        Cols.Add(FormatDateGov(PaymentPracticeHeader."Ending Date"));
        // 6: Filing date
        if PaymentPracticeHeader."Generated On" <> 0DT then
            FilingDate := DT2Date(PaymentPracticeHeader."Generated On")
        else
            FilingDate := Today();
        Cols.Add(FormatDateGov(FilingDate));
        // 7: Company
        Cols.Add(EscapeCSVField(CompanyInformation.Name));
        // 8: Company number
        Cols.Add(EscapeCSVField(CompanyInformation."Registration No."));
        // 9: Qualifying contracts in reporting period
        Cols.Add(FormatBoolTrueFalse(DisputeRetData."Qualifying Contracts in Period"));
        // 10: Payments made in reporting period
        Cols.Add(FormatBoolTrueFalse(DisputeRetData."Payments Made in Period"));
        // 11: Qualifying construction contracts in reporting period
        Cols.Add(FormatBoolTrueFalse(DisputeRetData."Qual. Constr. Contr. in Period"));
        // 12: Construction contracts have retention clauses
        Cols.Add(FormatBoolTrueFalse(DisputeRetData."Has Constr. Contract Retention"));
        // 13: Average time to pay
        Cols.Add(Format(PaymentPracticeHeader."Average Actual Payment Period"));
        // 14-16: Total value invoices paid within 30 / 31-60 / later than 60 days
        if HasValues then begin
            Cols.Add(Format(ValWithin30, 0, '<Precision,2:2><Standard Format,9>'));
            Cols.Add(Format(Val31to60, 0, '<Precision,2:2><Standard Format,9>'));
            Cols.Add(Format(ValOver60, 0, '<Precision,2:2><Standard Format,9>'));
        end else begin
            Cols.Add('');
            Cols.Add('');
            Cols.Add('');
        end;
        // 17-19: % Invoices paid within 30 / 31-60 / later than 60 days
        Cols.Add(Format(PctWithin30, 0, '<Precision,2:2><Standard Format,9>'));
        Cols.Add(Format(Pct31to60, 0, '<Precision,2:2><Standard Format,9>'));
        Cols.Add(Format(PctOver60, 0, '<Precision,2:2><Standard Format,9>'));
        // 20: Total value invoices paid later than agreed terms
        Cols.Add(Format(PaymentPracticeHeader."Total Amt. of Overdue Payments", 0, '<Precision,2:2><Standard Format,9>'));
        // 21: % Invoices not paid within agreed terms
        Cols.Add(Format(100 - PaymentPracticeHeader."Pct Paid on Time", 0, '<Precision,2:2><Standard Format,9>'));
        // 22: % Invoices not paid due to dispute
        Cols.Add(Format(PaymentPracticeHeader."Pct Overdue Due to Dispute", 0, '<Precision,2:2><Standard Format,9>'));
        // 23: Shortest (or only) standard payment period
        Cols.Add(Format(DisputeRetData."Shortest Standard Pmt. Period"));
        // 24: Longest standard payment period
        Cols.Add(Format(DisputeRetData."Longest Standard Pmt. Period"));
        // 25: Standard payment terms
        Cols.Add(EscapeCSVField(DisputeRetData."Standard Payment Terms Desc."));
        // 26: Payment terms have changed
        Cols.Add(FormatBoolTrueFalse(DisputeRetData."Payment Terms Have Changed"));
        // 27: Suppliers notified of changes
        Cols.Add(FormatBoolTrueFalse(DisputeRetData."Suppliers Notified of Changes"));
        // 28: Maximum contractual payment period
        Cols.Add(Format(DisputeRetData."Max Contractual Pmt. Period"));
        // 29: Maximum contractual payment period information
        Cols.Add(EscapeCSVField(DisputeRetData."Max Contr. Pmt. Period Info"));
        // 30: Other information payment terms
        Cols.Add(EscapeCSVField(DisputeRetData."Other Pmt. Terms Information"));

        // 31-45: Retention columns (empty when gate is false)
        if DisputeRetData."Has Constr. Contract Retention" then begin
            // 31: Retention clauses included in all construction contracts
            Cols.Add(FormatBoolTrueFalse(DisputeRetData."Ret. Clause Used in Contracts"));
            // 32: Retention clauses included in standard payment terms
            Cols.Add(FormatBoolTrueFalse(DisputeRetData."Retention in Std Pmt. Terms"));
            // 33: Retention clauses are used in specific circumstances
            Cols.Add(FormatBoolTrueFalse(DisputeRetData."Retention in Specific Circs."));
            // 34: Description of specific circumstances for retention clauses
            Cols.Add(EscapeCSVField(DisputeRetData."Retention Circs. Desc."));
            // 35: Retention clauses used above a specific sum
            Cols.Add(FormatBoolTrueFalse(DisputeRetData."Retent. Above Specific Sum"));
            // 36: Value above which retention clauses are used
            Cols.Add(Format(DisputeRetData."Contract Sum Threshold", 0, '<Precision,2:2><Standard Format,9>'));
            // 37: Retention clauses are at a standard rate
            Cols.Add(FormatBoolTrueFalse(DisputeRetData."Std Retention Pct Used"));
            // 38: Retention clauses standard rate percentage
            Cols.Add(Format(DisputeRetData."Standard Retention Pct", 0, '<Precision,2:2><Standard Format,9>'));
            // 39: Retention clauses have parity with client
            Cols.Add(FormatBoolTrueFalse(DisputeRetData."Terms Fairness Practice"));
            // 40: Description of parity policy
            Cols.Add(EscapeCSVField(DisputeRetData."Terms Fairness Desc."));
            // 41: Retention clause money release description
            Cols.Add(EscapeCSVField(DisputeRetData."Release Mechanism Desc."));
            // 42: Retention clause money release is staged
            Cols.Add(FormatBoolTrueFalse(DisputeRetData."Release Within Prescribed Days"));
            // 43: Description of stages for money release
            Cols.Add(EscapeCSVField(DisputeRetData."Prescribed Days Desc."));
            // 44: Retention value compared to client retentions as %
            Cols.Add(Format(DisputeRetData."Pct Retention vs Client Ret.", 0, '<Precision,2:2><Standard Format,9>'));
            // 45: Retention value compared to total payments as %
            Cols.Add(Format(DisputeRetData."Pct Retent. vs Gross Payments", 0, '<Precision,2:2><Standard Format,9>'));
        end else begin
            Cols.Add('');
            Cols.Add('');
            Cols.Add('');
            Cols.Add('');
            Cols.Add('');
            Cols.Add('');
            Cols.Add('');
            Cols.Add('');
            Cols.Add('');
            Cols.Add('');
            Cols.Add('');
            Cols.Add('');
            Cols.Add('');
            Cols.Add('');
            Cols.Add('');
        end;

        // 46: Dispute resolution process
        Cols.Add(EscapeCSVField(DisputeRetData."Dispute Resolution Process"));
        // 47: Participates in payment codes
        Cols.Add(FormatBoolYesNo(DisputeRetData."Is Payment Code Member"));
        // 48: E-Invoicing offered
        Cols.Add(FormatBoolYesNo(DisputeRetData."Offers E-Invoicing"));
        // 49: Supply-chain financing offered
        Cols.Add(FormatBoolYesNo(DisputeRetData."Offers Supply Chain Finance"));
        // 50: Policy covers charges for remaining on supplier list
        Cols.Add(FormatBoolYesNo(DisputeRetData."Policy Covers Deduct. Charges"));
        // 51: Charges have been made for remaining on supplier list
        Cols.Add(FormatBoolYesNo(DisputeRetData."Has Deducted Charges in Period"));
        // 52: URL
        Cols.Add('');

        exit(JoinCols(Cols));
    end;

    local procedure GetPeriodPercentages(PaymentPracticeHeader: Record "Payment Practice Header"; var PctWithin30: Decimal; var Pct31to60: Decimal; var PctOver60: Decimal; var ValWithin30: Decimal; var Val31to60: Decimal; var ValOver60: Decimal; var HasValues: Boolean)
    var
        PaymentPracticeLine: Record "Payment Practice Line";
        PaymentPeriodLine: Record "Payment Period Line";
    begin
        PctWithin30 := 0;
        Pct31to60 := 0;
        PctOver60 := 0;
        ValWithin30 := 0;
        Val31to60 := 0;
        ValOver60 := 0;
        HasValues := false;

        PaymentPracticeLine.SetRange("Header No.", PaymentPracticeHeader."No.");
        if not PaymentPracticeLine.FindSet() then
            exit;

        repeat
            // Resolve the period line to get Days From
            PaymentPeriodLine.SetRange("Period Header Code", PaymentPracticeLine."Payment Period Code");
            PaymentPeriodLine.SetRange(Description, PaymentPracticeLine."Payment Period Description");
            if PaymentPeriodLine.FindFirst() then begin
                if PaymentPeriodLine."Days From" <= 30 then begin
                    PctWithin30 += PaymentPracticeLine."Pct Paid in Period";
                    ValWithin30 += PaymentPracticeLine."Pct Paid in Period (Amount)";
                end else
                    if PaymentPeriodLine."Days From" <= 60 then begin
                        Pct31to60 += PaymentPracticeLine."Pct Paid in Period";
                        Val31to60 += PaymentPracticeLine."Pct Paid in Period (Amount)";
                    end else begin
                        PctOver60 += PaymentPracticeLine."Pct Paid in Period";
                        ValOver60 += PaymentPracticeLine."Pct Paid in Period (Amount)";
                    end;

                if PaymentPracticeLine."Pct Paid in Period (Amount)" <> 0 then
                    HasValues := true;
            end;
        until PaymentPracticeLine.Next() = 0;
    end;

    local procedure JoinCols(Cols: List of [Text]): Text
    var
        Result: TextBuilder;
        ColValue: Text;
        IsFirst: Boolean;
    begin
        IsFirst := true;
        foreach ColValue in Cols do begin
            if not IsFirst then
                Result.Append(',');
            Result.Append(ColValue);
            IsFirst := false;
        end;
        exit(Result.ToText());
    end;

    local procedure FormatBoolTrueFalse(Value: Boolean): Text
    begin
        if Value then
            exit('TRUE');
        exit('FALSE');
    end;

    local procedure FormatBoolYesNo(Value: Boolean): Text
    begin
        if Value then
            exit('Yes');
        exit('No');
    end;

    internal procedure FormatDateGov(Value: Date): Text
    begin
        exit(Format(Date2DMY(Value, 2)) + '/' + Format(Date2DMY(Value, 1)) + '/' + Format(Date2DMY(Value, 3)));
    end;

    internal procedure EscapeCSVField(Value: Text): Text
    var
        NeedsQuoting: Boolean;
        CR: Text[1];
        LF: Text[1];
    begin
        if Value = '' then
            exit('');

        CR[1] := 13;
        LF[1] := 10;

        NeedsQuoting := (StrPos(Value, ',') > 0) or (StrPos(Value, '"') > 0) or (StrPos(Value, CR) > 0) or (StrPos(Value, LF) > 0);
        if NeedsQuoting then
            exit('"' + Value.Replace('"', '""') + '"');

        exit(Value);
    end;
}
