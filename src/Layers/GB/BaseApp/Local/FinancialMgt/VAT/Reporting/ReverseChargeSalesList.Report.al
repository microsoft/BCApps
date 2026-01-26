#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Period;
using Microsoft.Sales.Setup;
using System.IO;
using System.Utilities;

report 10529 "Reverse Charge Sales List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/VAT/Reporting/ReverseChargeSalesList.rdlc';
    Caption = 'Reverse Charge Sales List';
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Reverse Charge VAT GB app';
    ObsoleteTag = '27.0';

    dataset
    {
        dataitem("Country/Region"; "Country/Region")
        {
            DataItemTableView = sorting("EU Country/Region Code") order(ascending) where("EU Country/Region Code" = filter(<> ''));
            column(CompanyAddr_1_; CompanyAddr[1])
            {
            }
            column(CompanyAddr_2_; CompanyAddr[2])
            {
            }
            column(CompanyAddr_3_; CompanyAddr[3])
            {
            }
            column(CompanyAddr_4_; CompanyAddr[4])
            {
            }
            column(CompanyAddr_5_; CompanyAddr[5])
            {
            }
            column(CompanyAddr_6_; CompanyAddr[6])
            {
            }
            column(CompanyInfo__Phone_No__; CompanyInfo."Phone No.")
            {
            }
            column(CompanyInfo__Fax_No__; CompanyInfo."Fax No.")
            {
            }
            column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
            {
            }
            column(VATEntryFilter; VATEntryFilter)
            {
            }
            column(STRSUBSTNO_Text001; StrSubstNo(Text001))
            {
            }
            column(STRSUBSTNO_Text000_GLSetup__LCY_Code__; StrSubstNo(Text000, GLSetup."LCY Code"))
            {
            }
            column(VAT_Entry__TABLECAPTION__________VATEntryFilter; "VAT Entry".TableCaption + ': ' + VATEntryFilter)
            {
            }
            column(STRSUBSTNO___1__2__Header_1_1__Header_1_2__; StrSubstNo('%1 %2', Header[1, 1], Header[1, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_2_1__Header_2_2__; StrSubstNo('%1 %2', Header[2, 1], Header[2, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_3_1__Header_3_2__; StrSubstNo('%1 %2', Header[3, 1], Header[3, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_4_1__Header_4_2__; StrSubstNo('%1 %2', Header[4, 1], Header[4, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_5_1__Header_5_2__; StrSubstNo('%1 %2', Header[5, 1], Header[5, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_6_1__Header_6_2__; StrSubstNo('%1 %2', Header[6, 1], Header[6, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_7_1__Header_7_2__; StrSubstNo('%1 %2', Header[7, 1], Header[7, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_8_1__Header_8_2__; StrSubstNo('%1 %2', Header[8, 1], Header[8, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_9_1__Header_9_2__; StrSubstNo('%1 %2', Header[9, 1], Header[9, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_10_1__Header_10_2__; StrSubstNo('%1 %2', Header[10, 1], Header[10, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_11_1__Header_11_2__; StrSubstNo('%1 %2', Header[11, 1], Header[11, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_12_1__Header_12_2__; StrSubstNo('%1 %2', Header[12, 1], Header[12, 2]))
            {
            }
            column(TotalColumnValuesAsText_1_; TotalColumnValuesAsText[1])
            {
                AutoCalcField = false;
            }
            column(TotalColumnValuesAsText_2_; TotalColumnValuesAsText[2])
            {
                AutoCalcField = false;
            }
            column(TotalColumnValuesAsText_3_; TotalColumnValuesAsText[3])
            {
                AutoCalcField = false;
            }
            column(TotalColumnValuesAsText_4_; TotalColumnValuesAsText[4])
            {
                AutoCalcField = false;
            }
            column(TotalColumnValuesAsText_5_; TotalColumnValuesAsText[5])
            {
                AutoCalcField = false;
            }
            column(TotalColumnValuesAsText_6_; TotalColumnValuesAsText[6])
            {
            }
            column(TotalColumnValuesAsText_7_; TotalColumnValuesAsText[7])
            {
                AutoCalcField = false;
            }
            column(TotalColumnValuesAsText_8_; TotalColumnValuesAsText[8])
            {
                AutoCalcField = false;
            }
            column(TotalColumnValuesAsText_9_; TotalColumnValuesAsText[9])
            {
                AutoCalcField = false;
            }
            column(TotalColumnValuesAsText_10_; TotalColumnValuesAsText[10])
            {
                AutoCalcField = false;
            }
            column(TotalColumnValuesAsText_11_; TotalColumnValuesAsText[11])
            {
                AutoCalcField = false;
            }
            column(TotalColumnValuesAsText_12_; TotalColumnValuesAsText[12])
            {
                AutoCalcField = false;
            }
            column(LineCountCurrentPage; LineCountCurrentPage)
            {
            }
            column(LineCountAllPages; LineCountAllPages)
            {
            }
            column(Country_Region_Code; Code)
            {
            }
            column(Reverse_Charge_Sales_ListCaption; Reverse_Charge_Sales_ListCaptionLbl)
            {
            }
            column(CompanyInfo__Phone_No__Caption; CompanyInfo__Phone_No__CaptionLbl)
            {
            }
            column(CompanyInfo__Fax_No__Caption; CompanyInfo__Fax_No__CaptionLbl)
            {
            }
            column(CompanyInfo__VAT_Registration_No__Caption; CompanyInfo__VAT_Registration_No__CaptionLbl)
            {
            }
            column(Total_Value_of_SuppliesCaption; Total_Value_of_SuppliesCaptionLbl)
            {
            }
            column(VAT_Registration_NoCaption; VAT_Registration_NoCaptionLbl)
            {
            }
            column(EU_Country_Region_CodeCaption; EU_Country_Region_CodeCaptionLbl)
            {
            }
            column(Number_of_lines__This_page_Caption; Number_of_lines__This_page_CaptionLbl)
            {
            }
            column(Number_of_lines__All_pages_Caption; Number_of_lines__All_pages_CaptionLbl)
            {
            }
            dataitem("VAT Entry"; "VAT Entry")
            {
                DataItemLink = "Country/Region Code" = field(Code);
                DataItemTableView = sorting(Type, "Country/Region Code", "VAT Registration No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date") where(Type = const(Sale), "Country/Region Code" = filter(<> ''));
                RequestFilterFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date";
                column(VAT_Entry__VAT_Registration_No__; "VAT Registration No.")
                {
                }
                column(Country_Region___EU_Country_Region_Code_; "Country/Region"."EU Country/Region Code")
                {
                }
                column(ColumnValuesAsText_1_; ColumnValuesAsText[1])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_4_; ColumnValuesAsText[4])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_3_; ColumnValuesAsText[3])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_2_; ColumnValuesAsText[2])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_10_; ColumnValuesAsText[10])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_9_; ColumnValuesAsText[9])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_8_; ColumnValuesAsText[8])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_7_; ColumnValuesAsText[7])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_6_; ColumnValuesAsText[6])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_5_; ColumnValuesAsText[5])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_11_; ColumnValuesAsText[11])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_12_; ColumnValuesAsText[12])
                {
                    AutoCalcField = false;
                }
                column(VATBase; VATBase)
                {
                }
                column(LineCountCurrentPage_Control46; LineCountCurrentPage)
                {
                }
                column(VAT_Entry_Entry_No_; "Entry No.")
                {
                }
                column(VAT_Entry_Country_Region_Code; "Country/Region Code")
                {
                }
                column(Number_of_lines__This_page_Caption_Control12; Number_of_lines__This_page_Caption_Control12Lbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if VATRegistrationNo <> "VAT Registration No." then begin
                        VATRegistrationNo := "VAT Registration No.";
                        Clear(ColumnValuesAsText);

                        VATEntry2 := "VAT Entry";
                        for i := 1 to MaxCount do begin
                            VATEntry2.SetCurrentKey(Type, "Country/Region Code");
                            VATEntry2.SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
                            VATEntry2.SetRange("Posting Date", StartDate[i], EndDate[i]);
                            VATEntry2.SetRange("VAT Registration No.", "VAT Registration No.");
                            VATEntry2.CalcSums(Base);
                            ColumnValues[i] := VATEntry2.Base;
                            ColumnValuesAsText[i] := FormatAmt(VATEntry2.Base);
                            VATBase := VATBase + VATEntry2.Base;
                            TotalColumnValues[i] := TotalColumnValues[i] + VATEntry2.Base;
                            TotalColumnValuesAsText[i] := FormatAmt(TotalColumnValues[i]);
                        end;

                        if ExportSubmissionFile and (VATBase <> 0) then
                            CreateSubmissionLine();
                        if VATBase <> 0 then
                            IncrLineCount();
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    SalesSetup.Get();
#if not CLEAN27
                    "VAT Entry".SetRange("VAT Bus. Posting Group", SalesSetup."Reverse Charge VAT Posting Gr.");
#endif
                end;
            }

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                FormatAddr.Company(CompanyAddr, CompanyInfo);
                Clear(VATBase);
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
                    field(ExportSubmissionFile; ExportSubmissionFile)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create Submission File';
                        ToolTip = 'Specifies that you wish to create a Comma Separated Variable (CSV) file of the Reverse Charge Sales List for submission.';
                    }
                    field(CalendarSource; CalendarSource)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calendar Source';
                        ToolTip = 'Specifies the type of calendar that you want to use when viewing work center information. If System Calendar is selected, the system calendar will be used. If Acc. Period Calendar is selected, the accounting calendar will be used.';
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

    trigger OnPostReport()
    begin
        if ExportSubmissionFile then
            SaveFile();
    end;

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        FormatAddr.Company(CompanyAddr, CompanyInfo);

        VATEntryFilter := "VAT Entry".GetFilters();
        PeriodStart := "VAT Entry".GetRangeMin("Posting Date");

        if CalendarSource = CalendarSource::AccPeriod then begin
            StartDate[1] := PeriodStart;
            EndDate[1] := AccPeriodEndDate(StartDate[1]);
            Header[1, 1] := Format(StartDate[1]);
            Header[1, 2] := Format(EndDate[1]);
            AccountingPeriod.SetRange("Starting Date", PeriodStart, "VAT Entry".GetRangeMax("Posting Date"));
            MaxCount := AccountingPeriod.Count();
            if MaxCount > 12 then
                MaxCount := 12;
            AccountingPeriod.FindSet();
            for i := 2 to MaxCount do begin
                AccountingPeriod.Next();
                StartDate[i] := AccountingPeriod."Starting Date";
                EndDate[i] := AccPeriodEndDate(StartDate[i]);
                Header[i, 1] := Format(StartDate[i]);
                Header[i, 2] := Format(EndDate[i]);
            end;
        end else begin
            StartDate[1] := PeriodStart;
            EndDate[1] := ClosingDate(CalcDate('<CM>', PeriodStart));
            Header[1, 1] := Format(StartDate[1]);
            Header[1, 2] := Format(EndDate[1]);
            Calendar.SetRange("Period Type", Calendar."Period Type"::Month);
            Calendar.SetRange("Period Start", PeriodStart, "VAT Entry".GetRangeMax("Posting Date"));
            MaxCount := Calendar.Count();
            if MaxCount > 12 then
                MaxCount := 12;
            Calendar.FindSet();
            for i := 2 to MaxCount do begin
                Calendar.Next();
                StartDate[i] := Calendar."Period Start";
                EndDate[i] := Calendar."Period End";
                Header[i, 1] := Format(StartDate[i]);
                Header[i, 2] := Format(EndDate[i]);
            end;
        end;
        GLSetup.Get();

        if ExportSubmissionFile then
            CreateSubmissionFile();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        SalesSetup: Record "Sales & Receivables Setup";
        AccountingPeriod: Record "Accounting Period";
        VATEntry2: Record "VAT Entry";
        Calendar: Record Date;
        FormatAddr: Codeunit "Format Address";
        SubmissionFile: File;
        VATEntryFilter: Text;
        CompanyAddr: array[8] of Text;
        VATBase: Decimal;
        Text000: Label 'All amounts are in whole %1.';
        LineCountCurrentPage: Integer;
        LineCountAllPages: Integer;
        Text001: Label 'Page %1';
        SubmissionFilePath: Text;
        ExportSubmissionFile: Boolean;
        Text1041000: Label 'TXT Files (*.txt)|*.csv|All Files (*.*)|*.*';
        PeriodStart: Date;
        StartDate: array[20] of Date;
        EndDate: array[20] of Date;
        ColumnValues: array[13] of Decimal;
        ColumnValuesAsText: array[13] of Text;
        Header: array[13, 2] of Text;
        MaxCount: Integer;
        i: Integer;
        TotalColumnValues: array[13] of Decimal;
        TotalColumnValuesAsText: array[13] of Text;
        LineText: Text;
        Text1041001: Label 'Export to csv File';
        Text1041002: Label 'Submission file successfully created.';
        CalendarSource: Option System,AccPeriod;
        VATRegistrationNo: Text;
        ToFile: Text;
        Text1041003: Label 'Default';
        Reverse_Charge_Sales_ListCaptionLbl: Label 'Reverse Charge Sales List';
        CompanyInfo__Phone_No__CaptionLbl: Label 'Phone No.';
        CompanyInfo__Fax_No__CaptionLbl: Label 'Fax No.';
        CompanyInfo__VAT_Registration_No__CaptionLbl: Label 'VAT Reg. No.';
        Total_Value_of_SuppliesCaptionLbl: Label 'Total Value\of Supplies';
        VAT_Registration_NoCaptionLbl: Label 'VAT Registration No';
        EU_Country_Region_CodeCaptionLbl: Label 'EU Country/Region Code';
        Number_of_lines__This_page_CaptionLbl: Label 'Number of lines (This page)';
        Number_of_lines__All_pages_CaptionLbl: Label 'Number of lines (All pages)';
        Number_of_lines__This_page_Caption_Control12Lbl: Label 'Number of lines (This page)';

    local procedure FormatAmt(AmountToPrint: Decimal): Text
    var
        TextAmt: Text;
    begin
        TextAmt := Format(Round(-AmountToPrint, 1), 0, '<Integer Thousand><Decimals>');
        if AmountToPrint > 0 then
            TextAmt := '(' + TextAmt + ')';
        exit(TextAmt);
    end;

    [Scope('OnPrem')]
    procedure IncrLineCount()
    begin
        LineCountCurrentPage := LineCountCurrentPage + 1;
        LineCountAllPages := LineCountAllPages + 1;
    end;

    [Scope('OnPrem')]
    procedure CreateSubmissionFile()
    var
        RBMgt: Codeunit "File Management";
    begin
        SubmissionFilePath := RBMgt.ServerTempFileName('csv');
        SubmissionFile.TextMode(true);
        SubmissionFile.WriteMode(true);
        SubmissionFile.Create(SubmissionFilePath);
        // SubmissionFile.TEXTMODE(TRUE);
        SubmissionFile.Write('HMRC_VAT_RCSL_BULK_SUBMISSION_FILE');
        SubmissionFile.Write(CompanyInfo."VAT Registration No." + ',' + FormatDate(StartDate[1]) + ',' + FormatDate(EndDate[MaxCount]));
    end;

    [Scope('OnPrem')]
    procedure CreateSubmissionLine()
    begin
        LineText := "VAT Entry"."VAT Registration No.";
        for i := 1 to MaxCount do
            LineText := LineText + ',' + Format(-Round(ColumnValues[i], 1), 0, 2);
        SubmissionFile.Write(LineText);
    end;

    [Scope('OnPrem')]
    procedure SaveFile()
    begin
        SubmissionFile.Close();
        ToFile := Text1041003 + '.csv';
        if not Download(SubmissionFilePath, Text1041001, '', Text1041000, ToFile) then
            exit;
        Message(Text1041002);
    end;

    local procedure AccPeriodEndDate(UseStartDate: Date): Date
    var
        AccountingPeriod2: Record "Accounting Period";
    begin
        AccountingPeriod2."Starting Date" := UseStartDate;
        if AccountingPeriod2.Find('>') then
            exit(AccountingPeriod2."Starting Date" - 1);
        exit(DMY2Date(31, 12, 9999));
    end;

    [Scope('OnPrem')]
    procedure FormatDate(dat: Date): Text
    begin
        exit(Format(dat, 0, '<Day,2><Month,2><Year4>'));
    end;
}
#endif

