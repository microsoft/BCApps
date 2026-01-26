// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using System.IO;
using System.Utilities;

report 10720 "Export Schedules to ASC format"
{
    Caption = 'Export Schedules to ASC format';
    ProcessingOnly = true;
    UseRequestPage = true;

    dataset
    {
        dataitem(CompanyData; "Integer")
        {
            DataItemTableView = sorting(Number) order(ascending) where(Number = const(1));

            trigger OnAfterGetRecord()
            begin
                if FormatType = FormatType::Euros then
                    FType := 1 * 100
                else
                    FType := 2 * 100;

                Clear(OutText);
                CompanyInfo.Name := ConvertStr(UpperCase(CompanyInfo.Name), 'ÁÀÉÈÍÌÓÒÚÙÑÜ()"&', Text1100001);
                CompanyInfo.Address := ConvertStr(UpperCase(CompanyInfo.Address), 'ÁÀÉÈÍÌÓÒÚÙÑÜ()"&', Text1100001);

                OutText := '1' + VATRegNo + Format(Date2DMY(FromDate, 3)) + PadStr('', 6, '0') + '02' + PadStr('', 8, ' ') + PadStr('', 8, ' ');

                if PostCode.Get(CompanyInfo."Post Code", CompanyInfo.City) then
                    CountyCode := PostCode."County Code";

                OutText := OutText + Format(CountyCode) + UpperCase(PadStr(CompanyInfo.Name, 50, ' ')) +
                  UpperCase(PadStr(CompanyInfo.Address, 40, ' ')) + UpperCase(PadStr(CompanyInfo.City, 30, ' '));

                PCode := CopyStr(Format(CompanyInfo."Post Code"), StrPos(Format(CompanyInfo."Post Code"), '-') + 1,
                    StrLen(Format(CompanyInfo."Post Code")));

                if CompanyInfo."Phone No." <> '' then begin
                    Prefix := CopyStr(Format(CompanyInfo."Phone No."), 1, StrPos(Format(CompanyInfo."Phone No."), '-') - 1);
                    PhoneNo := DelStr(Format(CompanyInfo."Phone No."), 1, StrPos(Format(CompanyInfo."Phone No."), '-'));
                end else begin
                    Prefix := PadStr(Format(CompanyInfo."Phone No."), 3, '0');
                    PhoneNo := PadStr(Format(CompanyInfo."Phone No."), 7, '0');
                end;

                OutText := OutText + (PadStr('', 5 - StrLen(PCode), '0') + PCode) + (PadStr('', 3 - StrLen(Prefix), '0') + Prefix) +
                  (PadStr('', 7 - StrLen(PhoneNo), '0') + PhoneNo) + PadStr('', 3, '0') + PadStr('', 3, '0');

                CompanyInfo."CNAE Description" := ConvertStr(UpperCase(CompanyInfo."CNAE Description"), 'ÁÀÉÈÍÌÓÒÚÙÑÜ()"&', Text1100001);

                OutText := OutText + PadStr(CompanyInfo."CNAE Description", 80, ' ') + PadStr('', 10, '0') + PadStr('', 5, '0');
                OutFile.Write(OutText);

                ClosDate := GetClosDate(ToDate);
                FixValue := '2' + VATRegNo + Format(Date2DMY(FromDate, 3));

                OutText := FixValue + Text1100004 + Text1100008 + PadStr('', 5, '0') + ClosDate + Text1100008 + PadStr('', 15, '0');
                OutFile.Write(OutText);

                OutText := FixValue + Text1100005 + Text1100008 + PadStr('', 13 - StrLen(CompanyInfo."Industrial Classification"), '0') +
                  Format(CompanyInfo."Industrial Classification") + '00' + Text1100008 + PadStr('', 15, '0');
                OutFile.Write(OutText);

                OutText := FixValue + Text1100006 + Text1100008 + PadStr('', 12, '0') + Format(FType) + Text1100008 + PadStr('', 15, '0');
                OutFile.Write(OutText);

                OutText := FixValue + Text1100007 + Text1100008 + PadStr('', 12, '0') + Format(FType) + Text1100008 + PadStr('', 15, '0');
                OutFile.Write(OutText);
            end;
        }
        dataitem(AccScheduleLineBalance; "Acc. Schedule Line")
        {
            DataItemTableView = sorting("Schedule Name", "Line No.") order(ascending) where(Show = const(Yes));

            trigger OnAfterGetRecord()
            begin
                ExportAccScheduleLine(AccScheduleLineBalance);
            end;

            trigger OnPreDataItem()
            begin
                if DepositType = DepositType::Normal then begin
                    SetFilter("Schedule Name", '%1', Text1100011);
                    SetRange(Show, 0);
                end else begin
                    SetFilter("Schedule Name", '%1', Text1100010);
                    SetRange(Show, 0);
                end;

                SetFilter("Date Filter", '%1..%2', FromDate, ToDate);
            end;
        }
        dataitem(AccScheduleLinePyg; "Acc. Schedule Line")
        {
            DataItemTableView = sorting("Schedule Name", "Line No.") order(ascending) where(Show = const(Yes));

            trigger OnAfterGetRecord()
            begin
                ExportAccScheduleLine(AccScheduleLinePyg);
            end;

            trigger OnPreDataItem()
            begin
                if DepositType = DepositType::Normal then begin
                    SetFilter("Schedule Name", '%1', Text1100013);
                    SetRange(Show, 0);
                end else begin
                    SetFilter("Schedule Name", '%1', Text1100012);
                    SetRange(Show, 0);
                end;

                SetFilter("Date Filter", '%1..%2', FromDate, ToDate);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DepositType; DepositType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Deposit Type';
                        Editable = true;
                        Enabled = true;
                        OptionCaption = 'Normal,Abbreviated';
                        ToolTip = 'Specifies the deposit type that you want to include in the export. You can include Normal and Abbreviated types.';
                    }
                    field(Euros; FormatType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Format';
                        Editable = true;
                        Enabled = true;
                        OptionCaption = 'Euros';
                        ToolTip = 'Specifies the format of the report.';
                    }
                    field(FromDate; FromDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'From Date';
                        ToolTip = 'Specifies the start date to include in the report or view.';
                    }
                    field(ToDate; ToDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'To Date';
                        ToolTip = 'Specifies the end date to include in the report.';
                    }
                }
            }
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
        CompanyInfo.Get();
        FileName := RBMgt.ServerTempFileName('asc');
        VATRegNo := CopyStr(DelChr(CompanyInfo."VAT Registration No.", '=', '.-/'), 1, 9);
    end;

    trigger OnPostReport()
    begin
        OutFile.Close();

        ToFile := Text1100003;
        if not Download(FileName, Text1100014, '', 'Asc Files|*.asc|All Files|*.*', ToFile) then
            exit;
    end;

    trigger OnPreReport()
    begin
        OutFile.TextMode := true;
        OutFile.WriteMode := true;
        OutFile.Create(FileName);
    end;

    var
        CompanyInfo: Record "Company Information";
        PostCode: Record "Post Code";
        ColumnLayout: Record "Column Layout";
        AccSchedManagement: Codeunit AccSchedManagement;
        OutFile: File;
        FileName: Text[1024];
        VATRegNo: Text[9];
        OutText: Text[300];
        CountyCode: Code[10];
        Text1100001: Label 'AAEEIIOOUUÐU    ';
        PhoneNo: Text[7];
        Prefix: Text[3];
        FromDate: Date;
        ToDate: Date;
        PCode: Text[5];
        Text1100003: Label 'C:\DATOS.ASC';
        Text1100004: Label '810190';
        Text1100005: Label '810010';
        Text1100006: Label '999024';
        Text1100007: Label '999114';
        Text1100008: Label '+';
        DepositType: Option Normal,Brief;
        Text1100010: Label 'BAL08-ABR';
        Text1100011: Label 'BAL08-NOR';
        Text1100012: Label 'PYG08-ABR';
        Text1100013: Label 'PYG08-NOR';
        FCode: Text[6];
        Str: Text[100];
        ColumnValue: Decimal;
        Saldo: array[2] of Text[100];
        NoZero: Boolean;
        ok: Boolean;
        b: Integer;
        Sign: Text[1];
        Signo: array[2] of Text[1];
        FormatType: Option Euros;
        FType: Integer;
        ClosDate: Text[30];
        FixValue: Text[14];
        RBMgt: Codeunit "File Management";
        ToFile: Text[1024];
        Text1100014: Label 'Path to export Schedules to ASC Format';

    [Scope('OnPrem')]
    procedure GetFieldCode(String: Text[100]; AccSchedLine: Record "Acc. Schedule Line") FCode: Text[5]
    var
        Position: Integer;
        String2: Text[100];
        Len: Integer;
        FieldCode: Text[5];
    begin
        FieldCode := '';

        while String <> '' do begin
            Position := StrPos(String, '.');
            if Position = 0 then begin
                String := String;
                String2 := DelStr(String, 1, StrLen(String));
            end else begin
                Str := String;
                String := CopyStr(String, 1, Position);
                String2 := DelStr(Str, 1, Position);
            end;

            case AccSchedLine."Schedule Name" of
                Text1100010, Text1100011:
                    FieldCode := FieldCode + CodeBAL(String, FieldCode);
                Text1100012:
                    FieldCode := FieldCode + CodePYGABR(String, AccSchedLine);
                Text1100013:
                    FieldCode := FieldCode + CodePYGNOR(String);
            end;

            String := String2;
        end;

        Len := StrLen(FieldCode);

        if Len < 5 then
            FieldCode := PadStr(FieldCode, 5, '0');

        if AccSchedLine."Schedule Name" = Text1100012 then
            CheckExceptionsPYG(FieldCode);

        if AccSchedLine."Schedule Name" = Text1100011 then
            CheckExceptionsBAL(FieldCode);

        exit(FieldCode);
    end;

    [Scope('OnPrem')]
    procedure CodeBAL(String: Text[100]; FCode: Text[5]) Result: Text[5]
    var
        FieldCode: Text[5];
    begin
        case String of
            'A', 'A.', 'I', 'I.':
                FieldCode := FieldCode + '1';
            'B', 'B.', 'II', 'II.':
                FieldCode := FieldCode + '2';
            'C', 'C.', 'III', 'III.':
                FieldCode := FieldCode + '3';
            'D', 'D.', 'IV', 'IV.':
                FieldCode := FieldCode + '4';
            'E', 'E.', 'V', 'V.':
                FieldCode := FieldCode + '5';
            'F', 'F.', 'VI', 'VI.':
                FieldCode := FieldCode + '6';
            'VII', 'VII.':
                FieldCode := FieldCode + '7';
            'VIII', 'VIII.':
                FieldCode := FieldCode + '8';
            '1':
                FieldCode := GetFieldCodeNumeric(FCode, '1', FieldCode);
            '2':
                FieldCode := GetFieldCodeNumeric(FCode, '2', FieldCode);
            '3':
                FieldCode := GetFieldCodeNumeric(FCode, '3', FieldCode);
            '4':
                FieldCode := GetFieldCodeNumeric(FCode, '4', FieldCode);
            '5':
                FieldCode := GetFieldCodeNumeric(FCode, '5', FieldCode);
            '6':
                FieldCode := GetFieldCodeNumeric(FCode, '6', FieldCode);
            '7':
                FieldCode := GetFieldCodeNumeric(FCode, '7', FieldCode);
            '8':
                FieldCode := GetFieldCodeNumeric(FCode, '8', FieldCode);
            '9':
                FieldCode := GetFieldCodeNumeric(FCode, '9', FieldCode);
        end;
        exit(FieldCode);
    end;

    [Scope('OnPrem')]
    procedure CodePYGABR(String: Text[100]; AccSchedLine: Record "Acc. Schedule Line") Result: Text[5]
    var
        FieldCode: Text[5];
    begin
        if AccSchedLine.Type = AccSchedLine.Type::Debit then
            case String of
                '1', '1.':
                    FieldCode := FieldCode + '01';
                '2', '2.':
                    FieldCode := FieldCode + '03';
                '3':
                    FieldCode := FieldCode + '04';
                '4':
                    FieldCode := FieldCode + '05';
                '5':
                    FieldCode := FieldCode + '06';
                '6', '6.':
                    FieldCode := FieldCode + '07';
                '7':
                    FieldCode := FieldCode + '08';
                '8':
                    FieldCode := FieldCode + '09';
                '9':
                    FieldCode := FieldCode + '10';
                '10':
                    FieldCode := FieldCode + '11';
                '11':
                    FieldCode := FieldCode + '12';
                '12':
                    FieldCode := FieldCode + '13';
                '13':
                    FieldCode := FieldCode + '14';
                '14':
                    FieldCode := FieldCode + '15';
                '15':
                    FieldCode := FieldCode + '16';
                'A':
                    FieldCode := FieldCode + '010';
                'B':
                    FieldCode := FieldCode + '020';
                'C':
                    FieldCode := FieldCode + '030';
                'D':
                    FieldCode := FieldCode + '040';
                'I':
                    FieldCode := FieldCode + '019';
                'II':
                    FieldCode := FieldCode + '029';
                'III':
                    FieldCode := FieldCode + '039';
                'IV':
                    FieldCode := FieldCode + '049';
                'V':
                    FieldCode := FieldCode + '059';
                'VI':
                    FieldCode := FieldCode + '069';
            end
        else
            case String of
                '1', '1.':
                    FieldCode := FieldCode + '01';
                '2', '2.':
                    FieldCode := FieldCode + '02';
                '3':
                    FieldCode := FieldCode + '08';
                '4':
                    FieldCode := FieldCode + '09';
                '5':
                    FieldCode := FieldCode + '10';
                '6':
                    FieldCode := FieldCode + '11';
                '7':
                    FieldCode := FieldCode + '12';
                '8':
                    FieldCode := FieldCode + '13';
                'A':
                    FieldCode := FieldCode + '019';
                'B':
                    FieldCode := FieldCode + '029';
                'C':
                    FieldCode := FieldCode + '039';
                'D':
                    FieldCode := FieldCode + '040';
                'I':
                    FieldCode := FieldCode + '019';
                'II':
                    FieldCode := FieldCode + '029';
                'III':
                    FieldCode := FieldCode + '039';
                'IV':
                    FieldCode := FieldCode + '049';
                'V':
                    FieldCode := FieldCode + '059';
                'VI':
                    FieldCode := FieldCode + '069';
            end;

        exit(FieldCode);
    end;

    [Scope('OnPrem')]
    procedure CodePYGNOR(String: Text[100]) Result: Text[5]
    var
        FieldCode: Text[5];
    begin
        case String of
            '1', '1.':
                FieldCode := FieldCode + '01';
            '2', '2.':
                FieldCode := FieldCode + '02';
            '3', '3.':
                FieldCode := FieldCode + '03';
            '4', '4.':
                FieldCode := FieldCode + '04';
            '5', '5.':
                FieldCode := FieldCode + '05';
            '6', '6.':
                FieldCode := FieldCode + '06';
            '7', '7.':
                FieldCode := FieldCode + '07';
            '8':
                FieldCode := FieldCode + '08';
            '9':
                FieldCode := FieldCode + '09';
            '10':
                FieldCode := FieldCode + '10';
            '11':
                FieldCode := FieldCode + '11';
            '12':
                FieldCode := FieldCode + '12';
            '13':
                FieldCode := FieldCode + '13';
            '14':
                FieldCode := FieldCode + '14';
            '15':
                FieldCode := FieldCode + '15';
            '16':
                FieldCode := FieldCode + '16';
            'A':
                FieldCode := FieldCode + '010';
            'B':
                FieldCode := FieldCode + '020';
            'C':
                FieldCode := FieldCode + '030';
            'D':
                FieldCode := FieldCode + '040';
            'I':
                FieldCode := FieldCode + '019';
            'II':
                FieldCode := FieldCode + '029';
            'III':
                FieldCode := FieldCode + '039';
            'IV':
                FieldCode := FieldCode + '049';
            'V':
                FieldCode := FieldCode + '059';
            'VI':
                FieldCode := FieldCode + '069';
        end;

        exit(FieldCode);
    end;

    [Scope('OnPrem')]
    procedure CheckExceptionsPYG(var FCode: Text[5])
    begin
        case FCode of
            '01000':
                FCode := '01009';
            '01019':
                FCode := '01000';
            '02000':
                FCode := '02009';
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckExceptionsBAL(var FCode: Text[5])
    begin
        case FCode of
            '24090':
                FCode := '24100';
            '20040':
                FCode := '20050';
            '44040':
                FCode := '44050';
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckSign(Value: Text[100]): Boolean
    var
        Sign: Boolean;
    begin
        if CopyStr(Value, 1, 1) = '-' then
            Sign := true
        else
            Sign := false;

        exit(Sign);
    end;

    [Scope('OnPrem')]
    procedure GetClosDate(ToDate: Date): Text[30]
    var
        CDate: Text[30];
        CDay: Text[2];
        CMonth: Text[2];
        CYear: Text[4];
    begin
        CDay := Format(Date2DMY(ToDate, 1));
        if StrLen(CDay) = 1 then
            CDay := '0' + CDay;
        CMonth := Format(Date2DMY(ToDate, 2));
        if StrLen(CMonth) = 1 then
            CMonth := '0' + CMonth;
        CYear := Format(Date2DMY(ToDate, 3));
        CDate := CYear + CMonth + CDay + '00';
        exit(CDate);
    end;

    [Scope('OnPrem')]
    procedure GetValues(ColValue: Decimal; var Saldo: array[2] of Text[100]; var Signo: array[2] of Text[1]; b: Integer): Boolean
    var
        Leng: Integer;
        ColumnValue2: Text[100];
        Times: Integer;
        I: Integer;
    begin
        ColumnValue2 := Format(ColValue);

        if CheckSign(ColumnValue2) = true then begin
            Sign := '-';
            ColumnValue2 := DelStr(ColumnValue2, 1, 1);
        end else
            Sign := '+';

        ColumnValue2 := DelChr(ColumnValue2, '=', '.');
        ColumnValue2 := DelChr(ColumnValue2, '=', ',');

        Leng := StrLen(ColumnValue2);
        Times := 15 - Leng;
        for I := 1 to Times do
            ColumnValue2 := '0' + ColumnValue2;

        Saldo[b] := ColumnValue2;
        Signo[b] := Sign;

        if ColValue <> 0 then
            exit(true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetFieldCodeNumeric(Fcode: Text[5]; Num: Text[1]; FieldCode: Text[5]): Text[5]
    begin
        if StrLen(Fcode) = 1 then
            FieldCode := FieldCode + '00' + Num
        else
            FieldCode := FieldCode + '0' + Num;
        exit(FieldCode);
    end;

    local procedure ExportAccScheduleLine(var AccScheduleLine: Record "Acc. Schedule Line")
    var
        AccScheduleName: Record "Acc. Schedule Name";
        FinancialReport: Record "Financial Report";
        CheckColumnLayout: Boolean;
    begin
        ok := false;
        if AccScheduleLine.Totaling = '' then
            ColumnValue := 0
        else begin
            b := 0;
            AccScheduleName.Get(AccScheduleLine."Schedule Name");
            CheckColumnLayout := true;
            if FinancialReport.Get(AccScheduleLine."Schedule Name") then
                ColumnLayout.SetRange("Column Layout Name", FinancialReport."Financial Report Column Group")
            else
                CheckColumnLayout := false;
            if CheckColumnLayout and ColumnLayout.Find('-') then
                repeat
                    b := b + 1;
                    ColumnValue := 100 * AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, false);
                    NoZero := GetValues(ColumnValue, Saldo, Signo, b);
                    if NoZero = true then
                        ok := NoZero;
                until ColumnLayout.Next() = 0;
            if ok then
                if (AccScheduleLine."Row No." <> '') or (AccScheduleLine.Totaling <> '') then begin
                    case AccScheduleLine.Type of
                        AccScheduleLine.Type::Debit:
                            FCode := '3';
                        AccScheduleLine.Type::Credit:
                            FCode := '4';
                        AccScheduleLine.Type::Assets:
                            FCode := '1';
                        AccScheduleLine.Type::Liabilities:
                            FCode := '2';
                    end;
                    Str := AccScheduleLine."Row No.";
                    Str := DelStr(Str, 1, StrPos(Str, '.'));
                    FCode := FCode + GetFieldCode(Str, AccScheduleLine);
                    OutText := StrSubstNo('%1%2%3%4%5%6', FixValue, FCode, Signo[1], Saldo[1], Signo[2], Saldo[2]);
                    OutFile.Write(OutText);
                end;
        end;
    end;
}

