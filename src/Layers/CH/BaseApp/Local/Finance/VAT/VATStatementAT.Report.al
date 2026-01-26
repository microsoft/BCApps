// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Company;
using System.Globalization;
using System.IO;
using System.Utilities;

report 11110 "VAT Statement AT"
{
    Caption = 'VAT Statement Austria';
    ProcessingOnly = true;
    Permissions = tabledata "Language Selection" = r;

    dataset
    {
        dataitem("VAT Statement Name"; "VAT Statement Name")
        {
            DataItemTableView = sorting("Statement Template Name", Name);
            RequestFilterFields = "Statement Template Name", Name;
            dataitem("VAT Statement Line"; "VAT Statement Line")
            {
                DataItemLink = "Statement Template Name" = field("Statement Template Name"), "Statement Name" = field(Name);
                DataItemTableView = sorting("Statement Template Name", "Statement Name", "Line No.");

                trigger OnAfterGetRecord()
                begin
                    if "VAT Statement Line".Print then
                        CalcLineTotal("VAT Statement Line", TotalAmount, 0);
                end;

                trigger OnPostDataItem()
                begin
                    for i := 1 to 99 do begin
                        if i in [22, 29, 6, 37, 52, 7] then
                            if Position[i] < 0 then begin
                                Position[1000] := Position[1000] - Position[i];
                                Position[i] := 0;
                                Position[1090] := Position[1090] + Position[i + 1000];
                                Position[i + 1000] := 0;
                            end;
                        if i in [72, 73, 8, 88] then
                            if Position[i] < 0 then begin
                                Position[70] := Position[70] - Position[i];
                                Position[1090] := Position[1090] + Position[i + 1000];
                                Position[i] := 0;
                                Position[i + 1000] := 0;
                            end;
                    end;
                    if Position[70] < 0 then
                        Position[70] := 0;
                    if Position[71] < 0 then
                        Position[71] := 0;

                    for i := 1000 to 1099 do begin
                        if i in [1011, 1012, 1015, 1016, 1017, 1018, 1019, 1020, 1021] then
                            if Position[i] < 0 then begin
                                Position[1000] := Position[1000] - Position[i];
                                Position[i] := 0;
                            end;
                        if i in [1060, 1061, 1083, 1065, 1066, 1082, 1087, 1089, 1064, 1062, 1063] then
                            if Position[i] < 0 then begin
                                Position[1067] := Position[1067] - Position[i];
                                Position[i] := 0;
                            end;
                        if i in [1048, 1057, 1056, 1044, 1032] then
                            if Position[i] < 0 then begin
                                Position[1090] := Position[1090] + Position[i];
                                Position[i] := 0;
                            end;
                    end;

                    if CheckPositions then
                        CheckPositionnumbers();
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Date Filter", Startingdate, Endingdate);
                    if GetRangeMin("Date Filter") = 0D then
                        FieldError("Date Filter");

                    if "Date Filter" = 0D then
                        "Date Filter" := WorkDate();
                    case PeriodType of
                        PeriodType::quarter:
                            begin
                                FromDate := GetRangeMin("Date Filter");
                                FromDate := CalcDate('<-CQ>', FromDate);
                                ToDate := CalcDate('<+CQ>', FromDate);
                            end;
                        PeriodType::month:
                            begin
                                FromDate := GetRangeMin("Date Filter");
                                FromDate := CalcDate('<-CM>', FromDate);
                                ToDate := CalcDate('<+CM>', FromDate);
                            end;
                        PeriodType::"defined period":
                            begin
                                FromDate := GetRangeMin("Date Filter");
                                ToDate := GetRangeMax("Date Filter");
                            end;
                    end;
                    "VAT Statement Line".SetRange("Date Filter", FromDate, ToDate);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                loop := loop + 1;
            end;

            trigger OnPostDataItem()
            begin
                CreateFDFFile();
                CreateXMLFile();
                if loop > 1 then
                    Message(ImproperFilterMsg);
            end;

            trigger OnPreDataItem()
            begin
                loop := 0;
                ReportLanguage := CurrReport.Language();
                ReportFormatRegion := CopyStr(CurrReport.FormatRegion(), 1, StrLen(ReportFormatRegion));
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; Startingdate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';

                        trigger OnValidate()
                        var
                            RefDate: Date;
                        begin
                            Clear(RefDate);
                            if Startingdate <> 0D then
                                RefDate := Startingdate
                            else
                                if Endingdate <> 0D then
                                    RefDate := Endingdate;
                            if RefDate <> 0D then
                                if PeriodType = PeriodType::quarter then begin
                                    Startingdate := CalcDate('<-CQ>', RefDate);
                                    Endingdate := CalcDate('<+CQ>', RefDate);
                                end else
                                    if PeriodType = PeriodType::month then begin
                                        Startingdate := CalcDate('<-CM>', RefDate);
                                        Endingdate := CalcDate('<+CM>', RefDate);
                                    end else begin
                                        if Endingdate = 0D then
                                            Endingdate := RefDate;
                                        if Startingdate = 0D then
                                            Startingdate := RefDate;
                                    end;
                        end;
                    }
                    field(EndingDate; Endingdate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date that the report includes data for.';

                        trigger OnValidate()
                        var
                            RefDate: Date;
                        begin
                            Clear(RefDate);
                            if Endingdate <> 0D then
                                RefDate := Endingdate
                            else
                                if Startingdate <> 0D then
                                    RefDate := Startingdate;
                            if RefDate <> 0D then
                                if PeriodType = PeriodType::quarter then begin
                                    Startingdate := CalcDate('<-CQ>', RefDate);
                                    Endingdate := CalcDate('<+CQ>', RefDate);
                                end else
                                    if PeriodType = PeriodType::month then begin
                                        Startingdate := CalcDate('<-CM>', RefDate);
                                        Endingdate := CalcDate('<+CM>', RefDate);
                                    end else begin
                                        if Startingdate = 0D then
                                            Startingdate := RefDate;
                                        if Endingdate = 0D then
                                            Endingdate := RefDate;
                                    end;
                        end;
                    }
                    field(IncludeVATEntries; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT Entries';
                        ToolTip = 'Specifies if you want to include VAT entries from before the specified time period in the report.';
                    }
                    field(PeriodSelection; PeriodSelection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT Entries';
                        ToolTip = 'Specifies if you want to include VAT entries from before the specified time period in the report.';
                    }
                    field(ReportingType; PeriodType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Reporting Type';
                        OptionCaption = 'Quarter,Month,Defined period';
                        ToolTip = 'Specifies if this VAT statement is the quarterly report, monthly report, or if it applies to another period.';

                        trigger OnValidate()
                        begin
                            if PeriodType = PeriodType::month then
                                monthPeriodTypeOnValidate();
                            if PeriodType = PeriodType::quarter then
                                quarterPeriodTypeOnValidate();
                        end;
                    }
                    field(CheckPositions; CheckPositions)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Check Positions';
                        ToolTip = 'Specifies that you want to verify the positions of the VAT statement during the export.';
                    }
                    field(RoundToWholeNumbers; PrintInWholeNumbers)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Round to Whole Numbers';
                        ToolTip = 'Specifies if you want the amounts in the report to be rounded to whole numbers.';
                    }
                    field(SurplusUsedToPayDues; UseARE)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Surplus Used to Pay Dues';
                        ToolTip = 'Specifies if you want to use a potential surplus to cover other charges.';
                    }
                    field(AdditionalInvoicesSentViaMail; UseREPO)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Additional Invoices sent via Mail';
                        ToolTip = 'Specifies if you want to send additional information.';
                    }
                    field(NumberPar6Abs1; NumberPar6Abs1)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Number Art. 6 Abs. 1';
                        MaxValue = 99;
                        MinValue = 0;
                        ToolTip = 'Specifies the number according to article 6 section 1 if you want to claim tax-free revenues without input tax reduction.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            Clear(NumberPar6Abs1);

            if (Startingdate <> 0D) and (Endingdate <> 0D) then begin
                if (Startingdate = CalcDate('<-CQ>', Startingdate)) and (Endingdate = CalcDate('<+CQ>', Startingdate)) then
                    PeriodType := PeriodType::quarter
                else
                    if (Startingdate = CalcDate('<-CM>', Startingdate)) and (Endingdate = CalcDate('<+CM>', Startingdate)) then
                        PeriodType := PeriodType::month
                    else
                        PeriodType := PeriodType::"defined period";
            end else
                PeriodType := PeriodType::"defined period";
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        DataCompression: Codeunit "Data Compression";
        FDFFileTempBlob: Codeunit "Temp Blob";
        XMLFileTempBlob: Codeunit "Temp Blob";
        PDFFileTempBlob: Codeunit "Temp Blob";
        ZipTempBlob: Codeunit "Temp Blob";
        FDFFileInStream: InStream;
        XMLFileInStream: InStream;
        PDFFileInStream: InStream;
        ZipInStream: InStream;
        ZipOutStream: OutStream;
        ToFile: Text;
        PdfFileName: Text;
    begin
        if TestFdfFileName = '' then begin
            PdfFileName := FileManagement.ServerTempFileName('pdf');
            if not Upload('', '', PDFFormatTxt, '', PdfFileName) then
                Error('');

            DataCompression.CreateZipArchive();
            FileManagement.BLOBImportFromServerFile(FDFFileTempBlob, FDFFileName);
            FDFFileTempBlob.CreateInStream(FDFFileInStream);
            FileManagement.BLOBImportFromServerFile(XMLFileTempBlob, XMLFileName);
            XMLFileTempBlob.CreateInStream(XMLFileInStream);
            FileManagement.BLOBImportFromServerFile(PDFFileTempBlob, PdfFileName);
            PDFFileTempBlob.CreateInStream(PDFFileInStream);
            DataCompression.AddEntry(FDFFileInStream, FdfZipFileName);
            DataCompression.AddEntry(XMLFileInStream, XmlZipFileName);
            DataCompression.AddEntry(PDFFileInStream, PdfZipFileName);
            ZipTempBlob.CreateOutStream(ZipOutStream);
            DataCompression.SaveZipArchive(ZipOutStream);
            DataCompression.CloseZipArchive();
            ZipTempBlob.CreateInStream(ZipInStream);
            ToFile := VATStatementTxt + '.zip';
            DownloadFromStream(ZipInStream, '', '', '', ToFile);
        end else begin
            FileManagement.CopyServerFile(FDFFileName, TestFdfFileName, true);
            FileManagement.CopyServerFile(XMLFileName, TestXmlFileName, true);
        end;
    end;

    trigger OnPreReport()
    begin
        Companyinfo.Get();
        FDFFileName := FileManagement.ServerTempFileName('fdf');
        XMLFileName := FileManagement.ServerTempFileName('xml');

        FdfZipFileName := VATStatementTxt + '.fdf';
        XmlZipFileName := VATStatementTxt + '.xml';
        PdfZipFileName := VATStatementTxt + '.pdf';
    end;

    var
        Companyinfo: Record "Company Information";
        GLAcc: Record "G/L Account";
        VATEntries: Record "VAT Entry";
        FileManagement: Codeunit "File Management";
        XMLFile: File;
        FDFFile: File;
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        PeriodType: Option quarter,month,"defined period";
        PrintInWholeNumbers: Boolean;
        Amount: Decimal;
        TotalAmount: Decimal;
        Position: array[2000] of Decimal;
        RowNo: array[6] of Code[10];
        ErrorText: Text[80];
        i: Integer;
        ArrayIndex: Integer;
        loop: Integer;
        FromDate: Date;
        ToDate: Date;
        Startingdate: Date;
        Endingdate: Date;
        XMLFileName: Text;
        FDFFileName: Text;
        XmlZipFileName: Text;
        PdfZipFileName: Text;
        FdfZipFileName: Text;
        TestFdfFileName: Text;
        TestXmlFileName: Text;
        UseARE: Boolean;
        UseREPO: Boolean;
        ReportLanguage: Integer;
        ReportFormatRegion: Text[80];
        TaxRevMustBeEnteredErr: Label 'A taxable revenue (KZ 000) must be entered. The value Zero is not allowed.\KZ 000 must exist.';
        TaxFreeBiggerErr: Label 'The total of taxfree revenues is bigger than the total of taxable revenues.\KZ 011+012+015+016+017+018+019+020 > KZ 000+001-021.';
        TotalTaxedRevDiffersErr: Label 'The total of taxable revenues reduced by the total of taxfree revenues differs from the total of to be taxed revenues.\KZ 022+006+029+037+007+052 <> (KZ 000+001-021) - (KZ 011+012+015+016+017+018+019+020).';
        CheckPositions: Boolean;
        InputTaxErr: Label 'Input tax from EC revenues and/or taxfree EC revenues reg. Art. 6 Abs. 2 only can be taken, if taxable EC revenues exist.\KZ 065 and KZ 71 only together with KZ 070.';
        TaxFreeECBiggerErr: Label 'The taxfree EC revenues reg. Art. 6 Abs. 2 are bigger than the taxable EC revenues.\KZ 071 > KZ 070.';
        TaxableRevDiffersErr: Label 'The taxable EC revenues reduced with the taxfree EC revenues reg. Art. 6 Abs. 2 differ from the total of declarable EC revenues.\KZ 072 + 073 + 008 + 088 <> KZ 070 - 071.';
        InputTaxClaimedErr: Label 'Input taxes reg. tax due reg. Art. 19 Abs. 1, Art. 19 Abs. 1 and Art. 25 Abs. 5 only can be claimed if tax due reg. Art. 19 Abs. 1,  Art. 19 Abs. 1 and Art. 25 Abs. 5 exist.\KZ 066 only together with KZ 057.';
        NumberPar6Abs1: Integer;
        ClaimTaxfreeRevErr: Label 'In order to claim taxfree revenues without input tax reduction (position 020) the necessary number of Art. 6 Abs. 1 has to be specified.\KZ 020 only together with "Number of Art. 6 Abs. 1".';
        PDFFormatTxt: Label 'Portable Document Format File|*.pdf|All Files|*.*';
        SetStartEndDateQst: Label 'Would you like to set the Starting and Ending Date according to the selected Reporting Type?';
        ImproperFilterMsg: Label 'Due to improper filter settings on the fields Statement Template Name and/or Name, your VAT Statement might contain incorrect values. Please check.';
        VATStatementTxt: Label 'VAT Statement', Comment = 'Must be a valid filename';

    local procedure CalcLineTotal(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal; Level: Integer): Boolean
    begin
        if Level = 0 then begin
            TotalAmount := 0;
            Amount := 0;
        end;
        case VATStmtLine2.Type of
            VATStmtLine2.Type::"Account Totaling":
                begin
                    GLAcc.SetFilter("No.", VATStmtLine2."Account Totaling");
                    "VAT Statement Line".CopyFilter("Date Filter", GLAcc."Date Filter");
                    Amount := 0;
                    if GLAcc.FindSet() and (VATStmtLine2."Account Totaling" <> '') then
                        repeat
                            GLAcc.CalcFields("Net Change", "Additional-Currency Net Change");
                            Amount := Amount + GLAcc."Net Change";
                        until GLAcc.Next() = 0;
                    CalcTotalAmount(VATStmtLine2, TotalAmount);
                end;
            VATStmtLine2.Type::"VAT Entry Totaling":
                begin
                    Amount := 0;
                    VATEntries.Reset();
                    VATEntries.SetCurrentKey(Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Tax Jurisdiction Code", "Use Tax", "VAT Reporting Date");
                    VATEntries.SetRange(Type, VATStmtLine2."Gen. Posting Type");
                    VATEntries.SetRange("VAT Bus. Posting Group", VATStmtLine2."VAT Bus. Posting Group");
                    VATEntries.SetRange("VAT Prod. Posting Group", VATStmtLine2."VAT Prod. Posting Group");
                    VATEntries.SetRange("Tax Jurisdiction Code", VATStmtLine2."Tax Jurisdiction Code");
                    VATEntries.SetRange("Use Tax", VATStmtLine2."Use Tax");
                    if "VAT Statement Line".GetFilter("Date Filter") <> '' then
                        if PeriodSelection = PeriodSelection::"Before and Within Period" then
                            VATEntries.SetRange("VAT Reporting Date", 0D, "VAT Statement Line".GetRangeMax("Date Filter"))
                        else
                            "VAT Statement Line".CopyFilter("Date Filter", VATEntries."VAT Reporting Date");

                    case Selection of
                        Selection::Open:
                            VATEntries.SetRange(Closed, false);
                        Selection::Closed:
                            VATEntries.SetRange(Closed, true);
                    end;
                    case VATStmtLine2."Amount Type" of
                        VATStmtLine2."Amount Type"::Amount:
                            begin
                                VATEntries.CalcSums(Amount, "Additional-Currency Amount");
                                Amount := Amount + VATEntries.Amount;
                            end;
                        VATStmtLine2."Amount Type"::Base:
                            begin
                                VATEntries.CalcSums(Base, "Additional-Currency Base");
                                Amount := Amount + VATEntries.Base;
                            end;
                        VATStmtLine2."Amount Type"::"Unrealized Amount":
                            begin
                                VATEntries.CalcSums("Unrealized Amount", "Add.-Currency Unrealized Amt.");
                                Amount := Amount + VATEntries."Unrealized Amount";
                            end;
                        VATStmtLine2."Amount Type"::"Unrealized Base":
                            begin
                                VATEntries.CalcSums("Unrealized Base", "Add.-Currency Unrealized Base");
                                Amount := Amount + VATEntries."Unrealized Base";
                            end;
                    end;
                    CalcTotalAmount(VATStmtLine2, TotalAmount);
                end;
            VATStmtLine2.Type::"Row Totaling":
                begin
                    if Level >= ArrayLen(RowNo) then
                        exit(false);
                    Level := Level + 1;
                    RowNo[Level] := VATStmtLine2."Row No.";

                    if VATStmtLine2."Row Totaling" = '' then
                        exit(true);
                    VATStmtLine2.SetRange("Statement Template Name", VATStmtLine2."Statement Template Name");
                    VATStmtLine2.SetRange("Statement Name", VATStmtLine2."Statement Name");
                    VATStmtLine2.SetFilter("Row No.", VATStmtLine2."Row Totaling");
                    if VATStmtLine2.FindSet() then
                        repeat
                            if not CalcLineTotal(VATStmtLine2, TotalAmount, Level) then begin
                                if Level > 1 then
                                    exit(false);
                                for i := 1 to ArrayLen(RowNo) do
                                    ErrorText := ErrorText + RowNo[i] + ' => ';
                                ErrorText := ErrorText + '...';
                                VATStmtLine2.FieldError("Row No.", ErrorText);
                            end;
                        until VATStmtLine2.Next() = 0;
                end;
            VATStmtLine2.Type::Description:
                ;
        end;

        exit(true);
    end;

    local procedure CalcTotalAmount(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal)
    begin
        if VATStmtLine2."Calculate with" = 1 then
            Amount := -Amount;
        if PrintInWholeNumbers then
            Amount := Round(Amount, 1, '<');
        TotalAmount := TotalAmount + Amount;

        CalcPosition("VAT Statement Line"."Row No.");
    end;

    [Scope('OnPrem')]
    procedure CalcPosition(Index: Code[10])
    begin
        if Evaluate(ArrayIndex, Index) then
            if (ArrayIndex > 0) and (ArrayIndex <= ArrayLen(Position)) then
                Position[ArrayIndex] := Position[ArrayIndex] + Amount;
    end;

    [Scope('OnPrem')]
    procedure FormatDecimal(InputDecimal: Decimal): Text[30]
    begin
        exit(ConvertStr(Format(InputDecimal, 0, '<Sign><integer><decimals,3>'), ',', '.'));
    end;

    [Scope('OnPrem')]
    procedure CheckPositionnumbers()
    begin
        if Position[1000] < 0 then
            Error(TaxRevMustBeEnteredErr);

        if Position[1011] + Position[1012] + Position[1015] + Position[1017] +
           Position[1018] + Position[1019] + Position[1016] + Position[1020] >
           Position[1000] + Position[1001] + Position[1021]
        then
            Error(TaxFreeBiggerErr);

        if (Position[22] + Position[29] + Position[6] + Position[37] + Position[52] + Position[7]) <>
           (Position[1000] + Position[1001] - Position[1021]) -
           (Position[1011] + Position[1012] + Position[1015] + Position[1017] +
            Position[1018] + Position[1019] + Position[1016] + Position[1020])
        then
            Error(TotalTaxedRevDiffersErr);

        if (Position[1065] + Position[71] <> 0) and (Position[70] = 0) then
            Error(InputTaxErr);

        if Position[71] > Position[70] then
            Error(TaxFreeECBiggerErr);

        if Position[70] - Position[71] <> Position[72] + Position[73] + Position[8] + Position[88] then
            Error(TaxableRevDiffersErr);

        if ((Position[1057] = 0) and (Position[1066] <> 0)) or ((Position[1057] <> 0) and (Position[1066] = 0)) then
            Error(InputTaxClaimedErr);

        if (Position[1020] <> 0) and (NumberPar6Abs1 > 0) then
            Error(ClaimTaxfreeRevErr);
    end;

    local procedure CreateFDFFile()
    var
        LanguageSelection: Record "Language Selection";
    begin
        if CurrReport.Language <> 3079 then begin
            CurrReport.Language := 3079;
            LanguageSelection.SetRange("Language ID", 3079);
            if LanguageSelection.FindFirst() then
                CurrReport.FormatRegion := LanguageSelection."Language Tag";
        end;

        FDFFile.TextMode(true);
        FDFFile.Create(FDFFileName, TEXTENCODING::Windows);
        FDFFile.Write('%FDF-1.2');
        FDFFile.Write('1 0 obj <<');
        FDFFile.Write('/FDF << /Fields [');
        AddFDFDataHeader();
        AddFDFData();
        AddFDFDataFooter();
        FDFFile.Write(']/F (' + PdfZipFileName + ')>>');
        FDFFile.Write('>>');
        FDFFile.Write('endobj');
        FDFFile.Write('trailer');
        FDFFile.Write('<< /Root 1 0 R>>');
        FDFFile.Write('%%EOF');
        FDFFile.Close();

        CurrReport.Language := ReportLanguage;
        if ReportFormatRegion <> '' then
            CurrReport.FormatRegion := ReportFormatRegion;
    end;

    local procedure AddFDFDataHeader()
    var
        CompanyAddressText: Text;
        CompanyNameText: Text;
        RegNoSplitPos: Integer;
    begin
        FDFFile.Write('<< /V (' +
          DelChr(Companyinfo."Tax Office Name", '<>', ' ') + '\n' +
          DelChr(Companyinfo."Tax Office Address", '<>', ' ') + '\n' +
          DelChr(Companyinfo."Tax Office Post Code", '<>', ' ') + ' ' +
          DelChr(Companyinfo."Tax Office City", '<>', ' ') +
          ')/T (Text01)>>');

        RegNoSplitPos := StrPos(DelChr(Companyinfo."Registration No.", '<>', ' '), '/');
        if RegNoSplitPos <> 0 then begin
            FDFFile.Write('<< /V (' +
              CopyStr(DelChr(Companyinfo."Tax Office Number", '<>', ' '), 1, 2) +
              ')/T (Zahl03)>>');
            FDFFile.Write('<< /V (' +
              CopyStr(DelChr(Companyinfo."Registration No.", '<>', ' '), 1, RegNoSplitPos - 1) +
              ')/T (Zahl02_1)>>');
            FDFFile.Write('<< /V (' +
              CopyStr(DelChr(Companyinfo."Registration No.", '<>', ' '), RegNoSplitPos + 1, 4) +
              ')/T (Zahl02_2)>>');
        end else
            FDFFile.Write('<< /V(1)/T (Checkbox01)>>');

        case PeriodType of
            PeriodType::quarter:
                begin
                    FDFFile.Write('<< /V (' + Format(Startingdate, 0, '<Month,2>') + ')/T (Text01_f)>>');
                    FDFFile.Write('<< /V (' + Format(Endingdate, 0, '<Month,2>') + ')/T (Text01_t)>>');
                end;
            PeriodType::month:
                FDFFile.Write('<< /V (' + Format(Startingdate, 0, '<Month,2>') + ')/T (Text01_m)>>');
        end;

        if Companyinfo.Name <> '' then
            CompanyNameText := CompanyNameText + DelChr(Companyinfo.Name, '<>', ' ');

        if Companyinfo."Name 2" <> '' then
            CompanyNameText := CompanyNameText + ', ' + DelChr(Companyinfo."Name 2", '<>', ' ');

        FDFFile.Write('<< /V (' + CompanyNameText + ')/T (Text03)>>');

        if Companyinfo.Address <> '' then
            CompanyAddressText :=
              CompanyAddressText + DelChr(Companyinfo.Address, '<>', ' ');

        if Companyinfo."Address 2" <> '' then
            CompanyAddressText :=
              CompanyAddressText + ', ' + DelChr(Companyinfo."Address 2", '<>', ' ');

        FDFFile.Write('<< /V (' + CompanyAddressText + ')/T (Text05)>>');
        FDFFile.Write('<< /V (' + DelChr(Companyinfo."Country/Region Code", '<>', ' ') + ')/T (Text07b)>>');
        FDFFile.Write('<< /V (' + DelChr(Companyinfo."Phone No.", '<>', ' ') + ')/T (Text07c)>>');
        FDFFile.Write('<< /V (' + DelChr(Companyinfo."Post Code", '<>', ' ') + ')/T (Text07d)>>');
        FDFFile.Write('<< /V (' + DelChr(Companyinfo.City, '<>', ' ') + ')/T (Text07e)>>');
    end;

    local procedure AddFDFData()
    begin
        WriteFDFDataForPosition(1000, 'Zahl101');
        WriteFDFDataForPosition(1001, 'Zahl102');
        WriteFDFDataForPosition(1021, 'Zahl103');
        FDFFile.Write('<< /V (0)/T (Zahl104)>>');
        WriteFDFDataForPosition(1011, 'Zahl105');
        WriteFDFDataForPosition(1012, 'Zahl106');
        WriteFDFDataForPosition(1015, 'Zahl107');
        WriteFDFDataForPosition(1017, 'Zahl108');
        WriteFDFDataForPosition(1018, 'Zahl109');
        WriteFDFDataForPosition(1019, 'Zahl110');
        WriteFDFDataForPosition(1016, 'Zahl111');
        if NumberPar6Abs1 > 0 then
            FDFFile.Write('<< /V (' + Format(NumberPar6Abs1) + ')/T (Zahl112)>>');
        WriteFDFDataForPosition(1020, 'Zahl113');
        WriteFDFDataForPosition(22, 'Zahl115a');
        WriteFDFDataForPosition(29, 'Zahl116a');
        WriteFDFDataForPosition(6, 'Zahl117a');
        WriteFDFDataForPosition(37, 'Zahl118a');
        WriteFDFDataForPosition(52, 'Zahl119a');
        WriteFDFDataForPosition(7, 'Zahl120a');
        WriteFDFDataForPosition(1056, 'Zahl123');
        WriteFDFDataForPosition(1057, 'Zahl124');
        WriteFDFDataForPosition(1048, 'Zahl125');
        WriteFDFDataForPosition(1032, 'Zahl125b');
        WriteFDFDataForPosition(1044, 'Zahl125a');
        WriteFDFDataForPosition(70, 'Zahl126');
        WriteFDFDataForPosition(71, 'Zahl127');
        WriteFDFDataForPosition(72, 'Zahl128a');
        WriteFDFDataForPosition(73, 'Zahl129a');
        WriteFDFDataForPosition(8, 'Zahl129a_1');
        WriteFDFDataForPosition(88, 'Zahl130a');
        WriteFDFDataForPosition(76, 'Zahl131');
        WriteFDFDataForPosition(77, 'Zahl132');
        WriteFDFDataForPosition(1060, 'Zahl133');
        WriteFDFDataForPosition(1061, 'Zahl134');
        WriteFDFDataForPosition(1083, 'Zahl134a');
        WriteFDFDataForPosition(1065, 'Zahl135');
        WriteFDFDataForPosition(1066, 'Zahl136');
        WriteFDFDataForPosition(1082, 'Zahl136a');
        WriteFDFDataForPosition(1089, 'Zahl137a');
        WriteFDFDataForPosition(1087, 'Zahl137');
        WriteFDFDataForPosition(1064, 'Zahl138');
        WriteFDFDataForPosition(1062, 'Zahl139');
        if Position[1063] <> 0 then begin
            if Position[1063] < 0 then
                FDFFile.Write('<< /V (-)/T (DD140)>>');
            FDFFile.Write('<< /V (' + Format(Abs(Position[1063]), 0, 1) + ')/T (Zahl140)>>');
        end;
        if Position[1067] <> 0 then begin
            if Position[1067] < 0 then
                FDFFile.Write('<< /V (-)/T (DD141)>>');
            FDFFile.Write('<< /V (' + Format(Abs(Position[1067]), 0, 1) + ')/T (Zahl141)>>');
        end;
        if Position[1090] <> 0 then begin
            if Position[1090] < 0 then
                FDFFile.Write('<< /V (-)/T (DD143)>>');
            FDFFile.Write('<< /V (' + Format(Abs(Position[1090]), 0, 1) + ')/T (Zahl143)>>');
        end;
    end;

    local procedure AddFDFDataFooter()
    begin
        if UseARE then
            FDFFile.Write('<< /V (1)/T (Checkbox100X)>>');
        if UseREPO then
            FDFFile.Write('<< /V (1)/T (Checkbox100Xx)>>');
        FDFFile.Write('<< /V (' + Format(Today, 10, '<Day,2>.<Month,2>.<Year4>') + ')/T (Tagesdatum2)>>');
    end;

    local procedure WriteFDFDataForPosition(Index: Integer; FieldCode: Text)
    begin
        if Position[Index] > 0 then
            FDFFile.Write('<< /V (' + Format(Position[Index], 0, 1) + ')/T (' + FieldCode + ')>>');
    end;

    local procedure CreateXMLFile()
    begin
        XMLFile.TextMode(true);
        XMLFile.Create(XMLFileName);

        XMLFile.Write('<?xml version="1.0" encoding="iso-8859-1"?>');
        XMLFile.Write('<ERKLAERUNGS_UEBERMITTLUNG>');

        WriteXMLInfoData();

        XMLFile.Write('<ERKLAERUNG art="U30">');
        XMLFile.Write('<SATZNR>1</SATZNR>');

        WriteXMLCommonData();
        WriteXMLSuppliesServices();
        WriteXMLIntraCommunity();
        WriteXMLInputVAT();

        XMLFile.Write('</ERKLAERUNG>');
        XMLFile.Write('</ERKLAERUNGS_UEBERMITTLUNG>');
        XMLFile.Close();
    end;

    local procedure WriteXMLInfoData()
    var
        IdentificationKeyTextL: Text;
    begin
        XMLFile.Write('<INFO_DATEN>');
        XMLFile.Write('<ART_IDENTIFIKATIONSBEGRIFF>FASTNR</ART_IDENTIFIKATIONSBEGRIFF>');
        IdentificationKeyTextL := StrSubstNo('<IDENTIFIKATIONSBEGRIFF>%1%2</IDENTIFIKATIONSBEGRIFF>',
                   Companyinfo."Tax Office Number", DelChr(Companyinfo."Registration No.", '=', '-/ '));
        OnWriteXMLInfoDataOnBeforeWriteIdentificationKey(CompanyInfo, IdentificationKeyTextL);
        XMLFile.Write(IdentificationKeyTextL);
        XMLFile.Write('<PAKET_NR>999999999</PAKET_NR>');
        XMLFile.Write(StrSubstNo('<DATUM_ERSTELLUNG type="datum">%1</DATUM_ERSTELLUNG>',
            Format(Today, 10, '<YEAR4>-<MONTH,2>-<DAY,2>')));
        XMLFile.Write(StrSubstNo('<UHRZEIT_ERSTELLUNG type="uhrzeit">%1</UHRZEIT_ERSTELLUNG>',
            Format(Time, 8, '<HOURS24,2><Filler Character,0>:<Minutes,2>:<seconds,2>')));
        XMLFile.Write('<ANZAHL_ERKLAERUNGEN>1</ANZAHL_ERKLAERUNGEN>');
        XMLFile.Write('</INFO_DATEN>');
    end;

    local procedure WriteXMLCommonData()
    begin
        XMLFile.Write('<ALLGEMEINE_DATEN>');
        XMLFile.Write('<ANBRINGEN>U30</ANBRINGEN>');
        XMLFile.Write(StrSubstNo('<ZRVON type="jahrmonat">%1</ZRVON>', Format(FromDate, 7, '<YEAR4>-<MONTH,2>')));
        XMLFile.Write(StrSubstNo('<ZRBIS type="jahrmonat">%1</ZRBIS>', Format(ToDate, 7, '<YEAR4>-<MONTH,2>')));
        XMLFile.Write(
          StrSubstNo('<FASTNR>%1%2</FASTNR>', Companyinfo."Tax Office Number", DelChr(Companyinfo."Registration No.", '=', '-/ ')));
        XMLFile.Write('</ALLGEMEINE_DATEN>');
    end;

    local procedure WriteXMLSuppliesServices()
    begin
        XMLFile.Write('<LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH>');
        XMLFile.Write(StrSubstNo('<KZ000 type="kz">%1</KZ000>', FormatDecimal(Position[1000])));
        WriteXMLNodeForPosition(1001, 'KZ001');
        WriteXMLNodeForPosition(1021, 'KZ021');

        XMLFile.Write('<STEUERFREI>');
        WriteXMLNodeForPosition(1011, 'KZ011');
        WriteXMLNodeForPosition(1012, 'KZ012');
        WriteXMLNodeForPosition(1015, 'KZ015');
        WriteXMLNodeForPosition(1017, 'KZ017');
        WriteXMLNodeForPosition(1018, 'KZ018');
        WriteXMLNodeForPosition(1019, 'KZ019');
        WriteXMLNodeForPosition(1016, 'KZ016');
        if Position[1020] <> 0 then begin
            XMLFile.Write('<VST>' + Format(NumberPar6Abs1) + '</VST>');
            XMLFile.Write(StrSubstNo('<KZ020 type="kz">%1</KZ020>', FormatDecimal(Position[1020])));
        end;
        XMLFile.Write('</STEUERFREI>');

        XMLFile.Write('<VERSTEUERT>');
        WriteXMLNodeForPosition(22, 'KZ022');
        WriteXMLNodeForPosition(29, 'KZ029');
        WriteXMLNodeForPosition(6, 'KZ006');
        WriteXMLNodeForPosition(37, 'KZ037');
        WriteXMLNodeForPosition(52, 'KZ052');
        WriteXMLNodeForPosition(7, 'KZ007');
        WriteXMLNodeForPosition(1056, 'KZ056');
        WriteXMLNodeForPosition(1057, 'KZ057');
        WriteXMLNodeForPosition(1048, 'KZ048');
        WriteXMLNodeForPosition(1044, 'KZ044');
        WriteXMLNodeForPosition(1032, 'KZ032');
        XMLFile.Write('</VERSTEUERT>');
        XMLFile.Write('</LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH>');
    end;

    local procedure WriteXMLIntraCommunity()
    begin
        XMLFile.Write('<INNERGEMEINSCHAFTLICHE_ERWERBE>');
        WriteXMLNodeForPosition(70, 'KZ070');
        WriteXMLNodeForPosition(71, 'KZ071');

        XMLFile.Write('<VERSTEUERT_IGE>');
        WriteXMLNodeForPosition(72, 'KZ072');
        WriteXMLNodeForPosition(73, 'KZ073');
        WriteXMLNodeForPosition(8, 'KZ008');
        WriteXMLNodeForPosition(88, 'KZ088');
        WriteXMLNodeForPosition(76, 'KZ076');
        WriteXMLNodeForPosition(77, 'KZ077');
        XMLFile.Write('</VERSTEUERT_IGE>');

        XMLFile.Write('</INNERGEMEINSCHAFTLICHE_ERWERBE>');
    end;

    local procedure WriteXMLInputVAT()
    begin
        XMLFile.Write('<VORSTEUER>');

        WriteXMLNodeForPosition(1060, 'KZ060');
        WriteXMLNodeForPosition(1061, 'KZ061');
        WriteXMLNodeForPosition(1083, 'KZ083');
        WriteXMLNodeForPosition(1065, 'KZ065');
        WriteXMLNodeForPosition(1066, 'KZ066');
        WriteXMLNodeForPosition(1082, 'KZ082');
        WriteXMLNodeForPosition(1087, 'KZ087');
        WriteXMLNodeForPosition(1089, 'KZ089');
        WriteXMLNodeForPosition(1064, 'KZ064');
        WriteXMLNodeForPosition(1062, 'KZ062');
        WriteXMLNodeForPosition(1063, 'KZ063');
        WriteXMLNodeForPosition(1067, 'KZ067');
        WriteXMLNodeForPosition(1090, 'KZ090');

        if UseARE then
            XMLFile.Write('<ARE>J</ARE>');
        if UseREPO then
            XMLFile.Write('<REPO>J</REPO>');
        XMLFile.Write('</VORSTEUER>');
    end;

    local procedure WriteXMLNodeForPosition(Index: Integer; NodeName: Text)
    begin
        if Position[Index] <> 0 then
            XMLFile.Write('<' + NodeName + ' type="kz">' + FormatDecimal(Position[Index]) + '</' + NodeName + '>');
    end;

    local procedure quarterPeriodTypeOnValidate()
    begin
        if Startingdate <> 0D then
            if (Startingdate <> CalcDate('<-CQ>', Startingdate)) or (Endingdate <> CalcDate('<+CQ>', Startingdate)) then
                if Confirm(SetStartEndDateQst, true) then begin
                    Startingdate := CalcDate('<-CQ>', Startingdate);
                    Endingdate := CalcDate('<+CQ>', Startingdate);
                end else
                    Error('');
    end;

    local procedure monthPeriodTypeOnValidate()
    begin
        if Startingdate <> 0D then
            if (Startingdate <> CalcDate('<-CM>', Startingdate)) or (Endingdate <> CalcDate('<+CM>', Startingdate)) then
                if Confirm(SetStartEndDateQst, true) then begin
                    Startingdate := CalcDate('<-CM>', Startingdate);
                    Endingdate := CalcDate('<+CM>', Startingdate);
                end else
                    Error('');
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewTestFdfFileName: Text; NewTestXmlFileName: Text)
    begin
        TestFdfFileName := NewTestFdfFileName;
        TestXmlFileName := NewTestXmlFileName;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWriteXMLInfoDataOnBeforeWriteIdentificationKey(CompanyInfo: Record "Company Information"; var IdentificationKeyTextL: Text)
    begin
    end;
}

