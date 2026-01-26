// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.AuditFileExport;
using Microsoft.Foundation.Address;
using System.IO;

report 11008 "Export VIES Report"
{
    Caption = 'VAT- VIES Declaration (XML)';
    ProcessingOnly = true;

    dataset
    {
        dataitem("VAT Report Header"; "VAT Report Header")
        {
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            begin
                MakeHeaderRecord("VAT Report Header");

                VATReportLine.SetRange("VAT Report No.", "No.");
                VATReportLine.SetRange("Line Type", VATReportLine."Line Type"::New);
                if VATReportLine.FindSet() then
                    repeat
                        MakeLineRecord("VAT Report Header", VATReportLine);
                    until VATReportLine.Next() = 0;

                if VATReportSetup."Export Cancellation Lines" then
                    VATReportLine.SetFilter("Line Type", '<>%1', VATReportLine."Line Type"::New)
                else
                    VATReportLine.SetRange("Line Type", VATReportLine."Line Type"::Correction);

                if VATReportLine.FindSet() then
                    repeat
                        MakeLineRecord("VAT Report Header", VATReportLine);
                    until VATReportLine.Next() = 0;

                MakeTotalRecord("VAT Report Header");
            end;

            trigger OnPostDataItem()
            var
                ExportStream: OutStream;
            begin
                if TestMode then
                    exit;

                if TempDataExportBuffer.FindSet() then begin
                    ServerFileName := FileMgt.ServerTempFileName(StrSubstNo('eg%1', GetTestExport("Test Export")));
                    ExportFile.Create(ServerFileName, TEXTENCODING::Windows);
                    ExportFile.TextMode(false);
                    ExportFile.CreateOutStream(ExportStream);
                    repeat
                        ExportStream.WriteText(TempDataExportBuffer."Field Value", StrLen(TempDataExportBuffer."Field Value"));
                    until TempDataExportBuffer.Next() = 0;
                    ExportFile.Close();

                    ClientFileName := MakeFileName("VAT Report Header");
                    if IsSilentMode then
                        FileMgt.CopyServerFile(ServerFileName, TestFileName, true)
                    else
                        if FileMgt.DownloadHandler(ServerFileName, '', '', FileMgt.GetToFilterText('', ServerFileName), ClientFileName) then begin
                            Status := Status::Exported;
                            Modify();
                        end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                NextLineNo := 0;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        VATReportSetup.Get();
    end;

    var
        TempDataExportBuffer: Record "Data Export Buffer" temporary;
        VATReportLine: Record "VAT Report Line";
        VATReportSetup: Record "VAT Report Setup";
        FileMgt: Codeunit "File Management";
        ExportFile: File;
        ServerFileName: Text;
        ClientFileName: Text;
        NextLineNo: Integer;
        TestMode: Boolean;
        IsSilentMode: Boolean;
        TestFileName: Text;

    [Scope('OnPrem')]
    procedure GetBuffer(var TempDataExportBuffer2: Record "Data Export Buffer" temporary)
    begin
        TempDataExportBuffer2.DeleteAll();
        TempDataExportBuffer2.Reset();
        if TempDataExportBuffer.FindSet() then
            repeat
                TempDataExportBuffer2 := TempDataExportBuffer;
                TempDataExportBuffer2.Insert();
            until TempDataExportBuffer.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure MakeHeaderRecord(VATReportHeader: Record "VAT Report Header")
    begin
        TempDataExportBuffer."Entry No." := NextLineNo;
        TempDataExportBuffer."Field Value" :=
          GetRecordType('0') +
          PadStr(VATReportSetup."Registration ID", 6) +
          Format(VATReportHeader."Processing Date", 8, '<Year4><Month,2><Day,2>') +
          PadStr(VATReportHeader."Company Name", 45, ' ') +
          PadStr(VATReportHeader."Company Address", 25, ' ') +
          PadStr(VATReportHeader."Post Code", 5, ' ') +
          PadStr(VATReportHeader.City, 25, ' ') +
          PadStr('', 5);
        TempDataExportBuffer.Insert();
        NextLineNo := NextLineNo + 1;
    end;

    [Scope('OnPrem')]
    procedure MakeLineRecord(VATReportHeader: Record "VAT Report Header"; VATReportLine: Record "VAT Report Line")
    begin
        if (VATReportLine.Base = 0) and (VATReportLine."Line Type" <> VATReportLine."Line Type"::Correction) then
            exit;

        TempDataExportBuffer."Entry No." := NextLineNo;
        TempDataExportBuffer."Field Value" :=
          GetRecordType('1') +
          PadStr(VATReportHeader."VAT Registration No.", 11) +
          GetReportType(VATReportLine, VATReportHeader) +
          GetReportPeriod(VATReportHeader) +
          PadStr(GetVATRegNo(VATReportLine), 14) +
          FormatBaseForExport(VATReportLine, 12) +
          GetTurnoverType(VATReportLine) +
          GetNotice(VATReportHeader) +
          GetRevocation(VATReportHeader) +
          PadStr('', 71);
        TempDataExportBuffer.Insert();
        NextLineNo := NextLineNo + 1;
    end;

    [Scope('OnPrem')]
    procedure MakeTotalRecord(VATReportHeader: Record "VAT Report Header")
    begin
        TempDataExportBuffer."Entry No." := NextLineNo;
        VATReportHeader.CalcFields("Total Base", "Total Base", "Total Number of Lines");
        TempDataExportBuffer."Field Value" :=
          GetRecordType('2') +
          PadStr(VATReportHeader."VAT Registration No.", 11) +
          GetReportPeriod(VATReportHeader) +
          FormatAmountForExport(VATReportHeader."Total Base", 14) +
          FormatAmountForExport(
            VATReportHeader."Total Number of Lines" -
            GetZeroBaseNewLineCount(VATReportHeader."No.") +
            GetCancellationLineCountCorrection(VATReportHeader."No."), 5) +
          PadStr('', 85);
        TempDataExportBuffer.Insert();
        NextLineNo := NextLineNo + 1;
    end;

    [Scope('OnPrem')]
    procedure MakeFileName(VATReportHeader: Record "VAT Report Header"): Text[250]
    begin
        VATReportSetup.TestField("Source Identifier");
        VATReportSetup.TestField("Transmission Process ID");
        VATReportSetup.TestField("Supplier ID");

        exit(
          StrSubstNo('m5_zm_%1_%2%3_v01_z%4_%5_%6%7.eg%8',
            VATReportSetup."Source Identifier",
            VATReportSetup."Transmission Process ID",
            VATReportSetup."Supplier ID",
            FormatDate(VATReportHeader."Start Date"),
            FormatProcessingDate(VATReportHeader),
            GetCodepage(),
            GetFileOrderNo(),
            GetTestExport(VATReportHeader."Test Export")));
    end;

    [Scope('OnPrem')]
    procedure GetRecordType(RecordType: Text[1]): Text[1]
    begin
        exit(RecordType);
    end;

    [Scope('OnPrem')]
    procedure GetReportType(VATReportLine: Record "VAT Report Line"; VATReportHeader: Record "VAT Report Header"): Text[2]
    begin
        if VATReportHeader."VAT Report Type" = VATReportHeader."VAT Report Type"::Corrective then
            exit('11');

        case VATReportLine."Line Type" of
            VATReportLine."Line Type"::New:
                exit('10');
            VATReportLine."Line Type"::Cancellation,
          VATReportLine."Line Type"::Correction:
                exit('11');
        end;
    end;

    [Scope('OnPrem')]
    procedure GetReportPeriod(VATReportHeader: Record "VAT Report Header") ReportPeriod: Text[4]
    begin
        case VATReportHeader."Report Period Type" of
            VATReportHeader."Report Period Type"::Quarter:
                ReportPeriod := '0' + Format(VATReportHeader."Report Period No.");
            VATReportHeader."Report Period Type"::Month:
                ReportPeriod := Format(VATReportHeader."Report Period No." + 20);
            VATReportHeader."Report Period Type"::Year:
                ReportPeriod := '05';
            VATReportHeader."Report Period Type"::"Bi-Monthly":
                ReportPeriod := Format(VATReportHeader."Report Period No." + 10);
        end;
        ReportPeriod := ReportPeriod + Format(VATReportHeader."Report Year" - 2000);
    end;

    [Scope('OnPrem')]
    procedure GetTurnoverType(VATReportLine: Record "VAT Report Line"): Text[1]
    begin
        if VATReportLine."EU Service" then
            exit('S');

        if VATReportLine."EU 3-Party Trade" then
            exit('D');

        exit(' ');
    end;

    [Scope('OnPrem')]
    procedure GetNotice(VATReportHeader: Record "VAT Report Header"): Text[2]
    begin
        if VATReportHeader.Notice then
            exit('11');

        exit('10');
    end;

    [Scope('OnPrem')]
    procedure GetRevocation(VATReportHeader: Record "VAT Report Header"): Text[2]
    begin
        if VATReportHeader.Revocation then
            exit('11');

        exit('10');
    end;

    [Scope('OnPrem')]
    procedure GetCodepage(): Text[1]
    begin
        if VATReportSetup.Codepage = VATReportSetup.Codepage::"IBM-850" then
            exit('c');

        exit('e');
    end;

    [Scope('OnPrem')]
    procedure GetFileOrderNo(): Text[1]
    begin
        exit('a');
    end;

    [Scope('OnPrem')]
    procedure GetDateNumber(CurrDate: Date): Text[3]
    var
        DateNumber: Integer;
        FromDate: Date;
    begin
        FromDate := DMY2Date(1, 1, Date2DMY(CurrDate, 3));
        DateNumber := CurrDate - FromDate + 1;
        case true of
            (DateNumber > 0) and (DateNumber < 10):
                exit('00' + Format(DateNumber));
            (DateNumber >= 10) and (DateNumber < 100):
                exit('0' + Format(DateNumber));
            (DateNumber >= 100):
                exit(Format(DateNumber, 3));
        end;
    end;

    [Scope('OnPrem')]
    procedure GetTestExport(TestExport: Boolean): Text[1]
    begin
        if TestExport then
            exit('t');

        exit('p');
    end;

    local procedure GetZeroBaseNewLineCount(ReportNo: Code[20]): Integer
    var
        VATReportLine: Record "VAT Report Line";
    begin
        VATReportLine.SetRange("VAT Report No.", ReportNo);
        VATReportLine.SetRange(Base, 0);
        VATReportLine.SetFilter("Line Type", '<>%1', VATReportLine."Line Type"::Correction);
        exit(VATReportLine.Count);
    end;

    local procedure GetCancellationLineCountCorrection(ReportNo: Code[20]): Integer
    var
        VATReportLine: Record "VAT Report Line";
    begin
        if not VATReportSetup."Export Cancellation Lines" then
            exit(0);

        VATReportLine.SetRange("VAT Report No.", ReportNo);
        VATReportLine.SetRange("Line Type", VATReportLine."Line Type"::Cancellation);
        exit(VATReportLine.Count);
    end;

    local procedure GetVATRegNo(VATReportLine: Record "VAT Report Line"): Text[14]
    var
        CountryRegion: Record "Country/Region";
        VATRegNo: Text;
    begin
        VATRegNo := VATReportLine."VAT Registration No.";
        CountryRegion.Get(VATReportLine."Country/Region Code");
        if CopyStr(VATRegNo, 1, StrLen(CountryRegion."EU Country/Region Code")) = CountryRegion."EU Country/Region Code" then
            VATRegNo := CopyStr(VATRegNo, StrLen(CountryRegion."EU Country/Region Code") + 1);
        exit(
          CopyStr(Format(CountryRegion."EU Country/Region Code", 2) + VATRegNo, 1, 14));
    end;

    [Scope('OnPrem')]
    procedure FormatDate(Date: Date): Text[8]
    begin
        exit(Format(Date, 8, '<Year4><Month,2><Day,2>'));
    end;

    [Scope('OnPrem')]
    procedure FormatProcessingDate(VATReportHeader: Record "VAT Report Header"): Text[6]
    begin
        case VATReportHeader."Report Period Type" of
            VATReportHeader."Report Period Type"::Month:
                exit(StrSubstNo('m%1%2', CopyStr(Format(Date2DMY(VATReportHeader."Processing Date", 3), 4), 3, 2), GetDateNumber(VATReportHeader."Processing Date")));
            VATReportHeader."Report Period Type"::Quarter:
                exit(StrSubstNo('q%1%2', CopyStr(Format(Date2DMY(VATReportHeader."Processing Date", 3), 4), 3, 2), GetDateNumber(VATReportHeader."Processing Date")));
            VATReportHeader."Report Period Type"::Year:
                exit(StrSubstNo('y%1%2', CopyStr(Format(Date2DMY(VATReportHeader."Processing Date", 3), 4), 3, 2), GetDateNumber(VATReportHeader."Processing Date")));
        end;
    end;

    [Scope('OnPrem')]
    procedure SetTestMode(NewTestMode: Boolean)
    begin
        TestMode := NewTestMode;
    end;

    [Scope('OnPrem')]
    procedure SetTestExportMode(NewFileName: Text)
    begin
        IsSilentMode := true;
        TestFileName := NewFileName;
    end;

    [Scope('OnPrem')]
    procedure FormatAmountForExport(Amount: Decimal; Length: Integer) AmtText: Text[20]
    begin
        AmtText := Format(Round(Amount), 0, '<Integer><Sign>');
        AmtText := PadStr('', Length - StrLen(AmtText), '0') + AmtText;
    end;

    [Scope('OnPrem')]
    procedure FormatBaseForExport(VATReportLine: Record "VAT Report Line"; Length: Integer): Text[20]
    begin
        if VATReportLine."Line Type" = VATReportLine."Line Type"::Cancellation then
            exit(FormatAmountForExport(0, Length));

        exit(FormatAmountForExport(VATReportLine.Base, Length));
    end;
}

