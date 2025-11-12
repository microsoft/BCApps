// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using System.Text;
using System.Utilities;

report 28 "Dimensions - Detail"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/Dimension/DimensionsDetail.rdlc';
    ApplicationArea = Dimensions;
    Caption = 'Dimensions - Detail';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Analysis View"; "Analysis View")
        {
            DataItemTableView = sorting(Code);
            column(ViewLastUpdatedText; ViewLastUpdatedText)
            {
            }
            column(Analysis_View_Name; Name)
            {
            }
            column(Analysis_View_Code; Code)
            {
            }
            column(DateFilter; DateFilter)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(DimFilterText; DimFilterText)
            {
            }
            column(DateFilterCaption; DateFilterCaptionLbl)
            {
            }
            column(Analysis_View_CodeCaption; Analysis_View_CodeCaptionLbl)
            {
            }
            column(ViewLastUpdatedTextCaption; ViewLastUpdatedTextCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Dimensions___DetailCaption; Dimensions___DetailCaptionLbl)
            {
            }
            column(FiltersCaption; FiltersCaptionLbl)
            {
            }
            column(Credit_AmountCaption; Credit_AmountCaptionLbl)
            {
            }
            column(Debit_AmountCaption; Debit_AmountCaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(Document_No_Caption; Document_No_CaptionLbl)
            {
            }
            column(Posting_DateCaption; Posting_DateCaptionLbl)
            {
            }
            column(G_L_Account_No_Caption; G_L_Account_No_CaptionLbl)
            {
            }
            column(Entry_No_Caption; Entry_No_CaptionLbl)
            {
            }
            dataitem(Level1; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(DimValCode_1_; DimValCode[1])
                {
                }
                column(DimCode_1_; DimCode[1])
                {
                }
                column(DimValName_1_; DimValName[1])
                {
                }
                column(UseAmtsInAddCurr; UseAmtsInAddCurr)
                {
                }
                column(Text015; Text015Lbl)
                {
                }
                column(AddRepCurrency; AddRepCurrency)
                {
                }
                column(LCYCODE; LCYCODE)
                {
                }
                dataitem(Level2; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(DimValCode_2_; DimValCode[2])
                    {
                    }
                    column(DimCode_2_; DimCode[2])
                    {
                    }
                    column(DimValName_2_; DimValName[2])
                    {
                    }
                    column(TempGLEntry__G_L_Account_No__; TempGLEntry."G/L Account No.")
                    {
                    }
                    column(TempGLEntry__Posting_Date_; Format(TempGLEntry."Posting Date"))
                    {
                    }
                    column(TempGLEntry__Document_No__; TempGLEntry."Document No.")
                    {
                    }
                    column(TempGLEntry_Description; TempGLEntry.Description)
                    {
                    }
                    column(TempGLEntry__Debit_Amount_; TempGLEntry."Debit Amount")
                    {
                    }
                    column(TempGLEntry__Credit_Amount_; TempGLEntry."Credit Amount")
                    {
                    }
                    column(TempGLEntry__Entry_No__; TempGLEntry."Entry No.")
                    {
                    }
                    dataitem(Level3; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(DimValCode_3_; DimValCode[3])
                        {
                        }
                        column(DimCode_3_; DimCode[3])
                        {
                        }
                        column(DimValName_3_; DimValName[3])
                        {
                        }
                        column(TempGLEntry__Debit_Amount__Control25; TempGLEntry."Debit Amount")
                        {
                        }
                        column(TempGLEntry__Credit_Amount__Control26; TempGLEntry."Credit Amount")
                        {
                        }
                        column(TempGLEntry__Entry_No___Control86; TempGLEntry."Entry No.")
                        {
                        }
                        dataitem(Level4; "Integer")
                        {
                            DataItemTableView = sorting(Number);
                            column(DimValCode_4_; DimValCode[4])
                            {
                            }
                            column(DimCode_4_; DimCode[4])
                            {
                            }
                            column(DimValName_4_; DimValName[4])
                            {
                            }
                            column(TempGLEntry__Debit_Amount__Control36; TempGLEntry."Debit Amount")
                            {
                            }
                            column(TempGLEntry__Credit_Amount__Control37; TempGLEntry."Credit Amount")
                            {
                            }
                            column(TempGLEntry__Entry_No___Control87; TempGLEntry."Entry No.")
                            {
                            }
                            dataitem(Level5; "Integer")
                            {
                                DataItemTableView = sorting(Number);
                                column(TempGLEntry__Credit_Amount__Control52; TempGLEntry."Credit Amount")
                                {
                                }
                                column(TempGLEntry__Debit_Amount__Control53; TempGLEntry."Debit Amount")
                                {
                                }
                                column(TempGLEntry__Entry_No___Control88; TempGLEntry."Entry No.")
                                {
                                }

                                trigger OnAfterGetRecord()
                                begin
                                    if not PrintDetail(5) then
                                        CurrReport.Break();
                                end;

                                trigger OnPreDataItem()
                                begin
                                    if DimCode[4] = '' then
                                        CurrReport.Break();
                                    FindFirstGLEntry[5] := true;
                                end;
                            }
                            dataitem(Level4e; "Integer")
                            {
                                DataItemTableView = sorting(Number) where(Number = const(1));
                                column(DebitTotal_4_; DebitTotal[4])
                                {
                                    AutoFormatType = 1;
                                }
                                column(CreditTotal_4_; CreditTotal[4])
                                {
                                    AutoFormatType = 1;
                                }

                                trigger OnPostDataItem()
                                begin
                                    DebitTotal[4] := 0;
                                    CreditTotal[4] := 0;
                                end;
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if DimCode[4] <> '' then begin
                                    if not CalcLine(4) and not PrintEmptyLines then
                                        CurrReport.Skip();
                                end else
                                    if not PrintDetail(4) then
                                        CurrReport.Break();
                            end;

                            trigger OnPreDataItem()
                            begin
                                if DimCode[3] = '' then
                                    CurrReport.Break();
                                FindFirstDim[4] := true;
                                FindFirstGLEntry[4] := true;
                            end;
                        }
                        dataitem(Level3e; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = const(1));
                            column(DebitTotal_3_; DebitTotal[3])
                            {
                                AutoFormatType = 1;
                            }
                            column(CreditTotal_3_; CreditTotal[3])
                            {
                                AutoFormatType = 1;
                            }

                            trigger OnPostDataItem()
                            begin
                                DebitTotal[3] := 0;
                                CreditTotal[3] := 0;
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if DimCode[3] <> '' then begin
                                if not CalcLine(3) and not PrintEmptyLines then
                                    CurrReport.Skip();
                            end else
                                if not PrintDetail(3) then
                                    CurrReport.Break();
                        end;

                        trigger OnPreDataItem()
                        begin
                            if DimCode[2] = '' then
                                CurrReport.Break();
                            FindFirstDim[3] := true;
                            FindFirstGLEntry[3] := true;
                        end;
                    }
                    dataitem(Level2e; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(DebitTotal_2_; DebitTotal[2])
                        {
                            AutoFormatType = 1;
                        }
                        column(CreditTotal_2_; CreditTotal[2])
                        {
                            AutoFormatType = 1;
                        }

                        trigger OnPostDataItem()
                        begin
                            DebitTotal[2] := 0;
                            CreditTotal[2] := 0;
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if DimCode[2] <> '' then begin
                            if not CalcLine(2) and not PrintEmptyLines then
                                CurrReport.Skip();
                        end else
                            if not PrintDetail(2) then
                                CurrReport.Break();
                    end;

                    trigger OnPreDataItem()
                    begin
                        if DimCode[1] = '' then
                            CurrReport.Break();
                        FindFirstDim[2] := true;
                        FindFirstGLEntry[2] := true;
                    end;
                }
                dataitem(Level1e; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CreditTotal_1_; CreditTotal[1])
                    {
                        AutoFormatType = 1;
                    }
                    column(DebitTotal_1_; DebitTotal[1])
                    {
                        AutoFormatType = 1;
                    }

                    trigger OnPostDataItem()
                    begin
                        DebitTotal[1] := 0;
                        CreditTotal[1] := 0;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if not CalcLine(1) and not PrintEmptyLines then
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    if DimCode[1] = '' then
                        CurrReport.Break();
                    FindFirstDim[1] := true;
                    FindFirstGLEntry[1] := true;
                end;
            }

            trigger OnAfterGetRecord()
            var
                AccountingPeriod: Record "Accounting Period";
                i: Integer;
                StartDate: Date;
                EndDate: Date;
                ThisFilter: Text[250];
            begin
                if "Last Date Updated" <> 0D then
                    ViewLastUpdatedText :=
                      StrSubstNo('%1', "Last Date Updated")
                else
                    ViewLastUpdatedText := Text004;

                AnalysisViewEntry.Reset();
                AnalysisViewEntry.SetRange("Analysis View Code", Code);
                AnalysisViewEntry.SetFilter("Posting Date", DateFilter);
                StartDate := AnalysisViewEntry.GetRangeMin("Posting Date");
                EndDate := AnalysisViewEntry.GetRangeMax("Posting Date");
                case "Date Compression" of
                    "Date Compression"::Week:
                        begin
                            StartDate := CalcDate('<CW+1D-1W>', StartDate);
                            EndDate := ClosingDate(CalcDate('<CW>', EndDate));
                        end;
                    "Date Compression"::Month:
                        begin
                            StartDate := CalcDate('<CM+1D-1M>', StartDate);
                            EndDate := ClosingDate(CalcDate('<CM>', EndDate));
                        end;
                    "Date Compression"::Quarter:
                        begin
                            StartDate := CalcDate('<CQ+1D-1Q>', StartDate);
                            EndDate := ClosingDate(CalcDate('<CQ>', EndDate));
                        end;
                    "Date Compression"::Year:
                        begin
                            StartDate := CalcDate('<CY+1D-1Y>', StartDate);
                            EndDate := ClosingDate(CalcDate('<CY>', EndDate));
                        end;
                    "Date Compression"::Period:
                        begin
                            AccountingPeriod.SetRange("Starting Date", 0D, StartDate);
                            if AccountingPeriod.Find('+') then
                                StartDate := AccountingPeriod."Starting Date";
                            AccountingPeriod.SetRange("Starting Date", EndDate, DMY2Date(31, 12, 9999));
                            if AccountingPeriod.Find('-') then
                                if AccountingPeriod.Next() <> 0 then
                                    EndDate := ClosingDate(AccountingPeriod."Starting Date" - 1);
                        end;
                end;
                AnalysisViewEntry.SetRange("Posting Date", StartDate, EndDate);

                OnAfterGetRecordAnalysisViewOnBeforeSetEntryFilterGroup(AnalysisViewEntry, "Analysis View");

                AnalysisViewEntry.FilterGroup(2);
                TempSelectedDim.Reset();
                TempSelectedDim.SetCurrentKey("User ID", "Object Type", "Object ID", "Analysis View Code", Level);
                TempSelectedDim.SetFilter("Dimension Value Filter", '<>%1', '');
                DimFilterText := '';
                if TempSelectedDim.Find('-') then
                    repeat
                        ThisFilter := '';
                        if DimFilterText <> '' then
                            ThisFilter := ', ';
                        ThisFilter :=
                          ThisFilter + TempSelectedDim."Dimension Code" + ': ' + TempSelectedDim."Dimension Value Filter";
                        if StrLen(DimFilterText) + StrLen(ThisFilter) <= 250 then
                            DimFilterText := DimFilterText + ThisFilter;
                        SetAnaViewEntryFilter(
                          TempSelectedDim."Dimension Code", TempSelectedDim."Dimension Value Filter");
                    until TempSelectedDim.Next() = 0;
                AnalysisViewEntry.FilterGroup(0);

                TempSelectedDim.Reset();
                TempSelectedDim.SetCurrentKey("User ID", "Object Type", "Object ID", "Analysis View Code", Level);
                TempSelectedDim.SetFilter(Level, '<>%1', TempSelectedDim.Level::" ");
                i := 1;
                if TempSelectedDim.Find('-') then
                    repeat
                        DimCode[i] := TempSelectedDim."Dimension Code";
                        LevelFilter[i] := TempSelectedDim."Dimension Value Filter";
                        i := i + 1;
                    until (TempSelectedDim.Next() = 0) or (i > 4);
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Code, AnalysisViewCode);
                GLSetup.Get();
                LCYCODE := GLSetup."LCY Code";
                AddRepCurrency := GLSetup."Additional Reporting Currency";
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        AboutTitle = 'About Dimensions - Detail';
        AboutText = 'Build a group of dimensions for combinations of dimension values. Define a hierarchy of dimension levels from an analysis view, and list all G/L entries for each group.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AnalysisViewCode; AnalysisViewCode)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Analysis View Code';
                        Lookup = true;
                        TableRelation = "Analysis View".Code;
                        ToolTip = 'Specifies the code for the analysis view that the filter belongs to.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            AnalysisView: Record "Analysis View";
                        begin
                            if PAGE.RunModal(PAGE::"Analysis View List", AnalysisView) = ACTION::LookupOK then begin
                                AnalysisViewCode := AnalysisView.Code;
                                UpdateColumnDim();
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            UpdateColumnDim();
                        end;
                    }
                    field(IncludeDimensions; ColumnDim)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Include Dimensions';
                        Editable = false;
                        ToolTip = 'Specifies the dimensions that you want to include in the report. You can only select dimensions included in the analysis view that you select in the Analysis View Code field.';

                        trigger OnAssistEdit()
                        begin
                            DimSelectionBuf.SetDimSelectionLevelGLAcc(3, REPORT::"Dimensions - Detail", AnalysisViewCode, ColumnDim);
                        end;
                    }
                    field(DtFilter; DateFilter)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Date Filter';
                        ToolTip = 'Specifies a filter, that will filter entries by date. You can enter a particular date or a time interval.';

                        trigger OnValidate()
                        var
                            FilterTokens: Codeunit "Filter Tokens";
                        begin
                            FilterTokens.MakeDateFilter(DateFilter);
                            TempGLAcc.SetFilter("Date Filter", DateFilter);
                            DateFilter := TempGLAcc.GetFilter("Date Filter");
                        end;
                    }
                    field(PrintEmptyLines; PrintEmptyLines)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Print Empty Lines';
                        MultiLine = true;
                        ToolTip = 'Specifies if you do not want the report to include dimensions and dimension values that have a balance of zero.';
                    }
                    field(ShowAmountsInAddRepCurrency; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if the reported amounts are shown in the additional reporting currency.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            GLSetup.Get();
            if GLSetup."Additional Reporting Currency" = '' then
                UseAmtsInAddCurr := false;
            UpdateColumnDim();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        SelectedDim: Record "Selected Dimension";
    begin
        if AnalysisViewCode = '' then
            Error(Text000);

        if DateFilter = '' then
            Error(Text001);

        DimSelectionBuf.CompareDimText(
          3, REPORT::"Dimensions - Detail", AnalysisViewCode, ColumnDim, Text002);

        TempSelectedDim.Reset();
        TempSelectedDim.SetFilter("Dimension Value Filter", '<>%1', '');
        TempSelectedDim.SetFilter("Dimension Code", TempGLAcc.TableCaption());
        if TempSelectedDim.Find('-') then
            GLAcc.SetFilter("No.", TempSelectedDim."Dimension Value Filter");
        GLAcc.SetRange("Account Type", GLAcc."Account Type"::Posting);
        if GLAcc.Find('-') then
            repeat
                TempGLAcc.Init();
                TempGLAcc := GLAcc;
                TempGLAcc.Insert();
            until GLAcc.Next() = 0;

        TempBusUnit.Init();
        TempBusUnit.Insert();
        TempSelectedDim.SetFilter("Dimension Code", BusUnit.TableCaption());
        if TempSelectedDim.Find('-') then
            BusUnit.SetFilter(Code, TempSelectedDim."Dimension Value Filter");
        if BusUnit.Find('-') then
            repeat
                TempBusUnit.Init();
                TempBusUnit := BusUnit;
                TempBusUnit.Insert();
            until BusUnit.Next() = 0;

        SelectedDim.GetSelectedDim(UserId, 3, REPORT::"Dimensions - Detail", AnalysisViewCode, TempSelectedDim);
        TempSelectedDim.Reset();
        TempSelectedDim.SetCurrentKey("User ID", "Object Type", "Object ID", "Analysis View Code", Level);
        TempSelectedDim.SetFilter(Level, '<>%1', TempSelectedDim.Level::" ");
        DimVal.SetFilter(
          "Dimension Value Type", '%1|%2', DimVal."Dimension Value Type"::Standard, DimVal."Dimension Value Type"::"Begin-Total");
        if TempSelectedDim.Find('-') then
            repeat
                TempDimVal.Init();
                TempDimVal.Code := '';
                TempDimVal."Dimension Code" := TempSelectedDim."Dimension Code";
                TempDimVal.Name := Text003;
                TempDimVal.Insert();
                DimVal.SetRange("Dimension Code", TempSelectedDim."Dimension Code");
                if TempSelectedDim."Dimension Value Filter" <> '' then
                    DimVal.SetFilter(Code, TempSelectedDim."Dimension Value Filter")
                else
                    DimVal.SetRange(Code);
                OnPreReportOnAfterDimValSetFilters(DimVal);
                if DimVal.Find('-') then
                    repeat
                        TempDimVal.Init();
                        TempDimVal := DimVal;
                        TempDimVal.Insert();
                    until DimVal.Next() = 0;
            until TempSelectedDim.Next() = 0;
    end;

    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        AnalysisViewEntry: Record "Analysis View Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        BusUnit: Record "Business Unit";
        [SecurityFiltering(SecurityFilter::Filtered)]
        DimVal: Record "Dimension Value";
        TempGLEntry: Record "G/L Entry" temporary;
        TempGLAcc: Record "G/L Account" temporary;
        TempBusUnit: Record "Business Unit" temporary;
        TempDimVal: Record "Dimension Value" temporary;
        TempSelectedDim: Record "Selected Dimension" temporary;
        DimSelectionBuf: Record "Dimension Selection Buffer";
        GLSetup: Record "General Ledger Setup";
        PrintEmptyLines: Boolean;
        UseAmtsInAddCurr: Boolean;
        ViewLastUpdatedText: Text[30];
        ColumnDim: Text[250];
        AnalysisViewCode: Code[10];
        DateFilter: Text[250];
        FindFirstDim: array[4] of Boolean;
        FindFirstGLEntry: array[5] of Boolean;
        DimCode: array[4] of Text[30];
        DimValCode: array[4] of Code[20];
        DimValName: array[4] of Text[100];
        LevelFilter: array[4] of Text[250];
        AddRepCurrency: Text[50];
        LCYCODE: Text[50];
        DebitTotal: array[4] of Decimal;
        CreditTotal: array[4] of Decimal;
        DimFilterText: Text[250];

#pragma warning disable AA0074
        Text000: Label 'Enter an analysis view code.';
        Text001: Label 'Enter a date filter.';
        Text002: Label 'Include Dimensions';
        Text003: Label '(no dimension value)';
        Text004: Label 'Not updated';
        Text014: Label '(no business unit)';
#pragma warning restore AA0074
        DateFilterCaptionLbl: Label 'Period';
        Analysis_View_CodeCaptionLbl: Label 'Analysis View';
        ViewLastUpdatedTextCaptionLbl: Label 'Last Date Updated';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Dimensions___DetailCaptionLbl: Label 'Dimensions - Detail';
        FiltersCaptionLbl: Label 'Filters';
        Credit_AmountCaptionLbl: Label 'Credit Amount';
        Debit_AmountCaptionLbl: Label 'Debit Amount';
        DescriptionCaptionLbl: Label 'Description';
        Document_No_CaptionLbl: Label 'Document No.';
        Posting_DateCaptionLbl: Label 'Posting Date';
        G_L_Account_No_CaptionLbl: Label 'G/L Account No.';
        Entry_No_CaptionLbl: Label 'Entry No.';
        Text015Lbl: Label 'All amounts are in ';

    protected var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GLAcc: Record "G/L Account";

    local procedure CalcLine(Level: Integer): Boolean
    var
        HasEntries: Boolean;
        i: Integer;
    begin
        if Level < 4 then
            for i := Level + 1 to 4 do
                SetAnaViewEntryFilter(DimCode[i], '*');
        if Iteration(
             FindFirstDim[Level], DimCode[Level], DimValCode[Level], DimValName[Level], LevelFilter[Level])
        then begin
            SetAnaViewEntryFilter(DimCode[Level], DimValCode[Level]);
            HasEntries := AnalysisViewEntry.Find('-');
        end else
            CurrReport.Break();
        exit(HasEntries);
    end;

    local procedure PrintDetail(Level: Integer): Boolean
    var
        AnalysisViewEntryToGLEntries: Codeunit AnalysisViewEntryToGLEntries;
    begin
        if FindFirstGLEntry[Level] then begin
            FindFirstGLEntry[Level] := false;
            TempGLEntry.Reset();
            TempGLEntry.DeleteAll();
            if AnalysisViewEntry.Find('-') then
                repeat
                    AnalysisViewEntryToGLEntries.GetGLEntries(AnalysisViewEntry, TempGLEntry);
                until AnalysisViewEntry.Next() = 0;
            TempGLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
            TempGLEntry.SetFilter("Posting Date", DateFilter);
            OnPrintDetailOnAfterTempGLEntrySetFilters(TempGLEntry);
            if not TempGLEntry.Find('-') then
                exit(false);
        end else
            if TempGLEntry.Next() = 0 then
                exit(false);
        if Level > 1 then
            CalcTotalAmounts(Level - 1);
        exit(true);
    end;

    local procedure CalcTotalAmounts(Level: Integer)
    var
        i: Integer;
    begin
        for i := 1 to Level do begin
            if UseAmtsInAddCurr then begin
                TempGLEntry."Debit Amount" := TempGLEntry."Add.-Currency Debit Amount";
                TempGLEntry."Credit Amount" := TempGLEntry."Add.-Currency Credit Amount";
            end;
            DebitTotal[i] := DebitTotal[i] + TempGLEntry."Debit Amount";
            CreditTotal[i] := CreditTotal[i] + TempGLEntry."Credit Amount";
        end;
    end;

    local procedure UpdateColumnDim()
    var
        SelectedDim: Record "Selected Dimension";
        TempDimSelectionBuf: Record "Dimension Selection Buffer" temporary;
        AnalysisView: Record "Analysis View";
    begin
        AnalysisView.CopyAnalysisViewFilters(3, REPORT::"Dimensions - Detail", AnalysisViewCode);
        ColumnDim := '';
        SelectedDim.SetRange("User ID", UserId);
        SelectedDim.SetRange("Object Type", 3);
        SelectedDim.SetRange("Object ID", REPORT::"Dimensions - Detail");
        SelectedDim.SetRange("Analysis View Code", AnalysisViewCode);
        if SelectedDim.Find('-') then begin
            repeat
                TempDimSelectionBuf.Init();
                TempDimSelectionBuf.Code := SelectedDim."Dimension Code";
                TempDimSelectionBuf.Selected := true;
                TempDimSelectionBuf."Dimension Value Filter" := SelectedDim."Dimension Value Filter";
                TempDimSelectionBuf.Level := SelectedDim.Level;
                TempDimSelectionBuf.Insert();
            until SelectedDim.Next() = 0;
            TempDimSelectionBuf.SetDimSelection(
              3, REPORT::"Dimensions - Detail", AnalysisViewCode, ColumnDim, TempDimSelectionBuf);
        end;
    end;

    local procedure Iteration(var FindFirstRec: Boolean; IterationDimCode: Text[30]; var IterationDimValCode: Code[20]; var IterationDimValName: Text[100]; IterationFilter: Text[250]): Boolean
    var
        SearchResult: Boolean;
    begin
        case IterationDimCode of
            TempGLAcc.TableCaption:
                begin
                    TempGLAcc.Reset();
                    TempGLAcc.SetFilter("No.", IterationFilter);
                    if FindFirstRec then
                        SearchResult := TempGLAcc.Find('-')
                    else
                        if TempGLAcc.Get(IterationDimValCode) then
                            SearchResult := (TempGLAcc.Next() <> 0);
                    if SearchResult then begin
                        IterationDimValCode := TempGLAcc."No.";
                        IterationDimValName := TempGLAcc.Name;
                    end;
                end;
            TempBusUnit.TableCaption:
                begin
                    TempBusUnit.Reset();
                    TempBusUnit.SetFilter(Code, IterationFilter);
                    if FindFirstRec then
                        SearchResult := TempBusUnit.Find('-')
                    else
                        if TempBusUnit.Get(IterationDimValCode) then
                            SearchResult := (TempBusUnit.Next() <> 0);
                    if SearchResult then begin
                        IterationDimValCode := TempBusUnit.Code;
                        if TempBusUnit.Code <> '' then
                            IterationDimValName := TempBusUnit.Name
                        else
                            IterationDimValName := Text014;
                    end;
                end;
            else begin
                TempDimVal.Reset();
                TempDimVal.SetRange("Dimension Code", IterationDimCode);
                TempDimVal.SetFilter(Code, IterationFilter);
                if FindFirstRec then
                    SearchResult := TempDimVal.Find('-')
                else
                    if TempDimVal.Get(IterationDimCode, IterationDimValCode) then
                        SearchResult := (TempDimVal.Next() <> 0);
                if SearchResult then begin
                    IterationDimValCode := TempDimVal.Code;
                    IterationDimValName := TempDimVal.Name;
                end;
            end;
        end;
        if not SearchResult then begin
            IterationDimValCode := '';
            IterationDimValName := '';
        end;
        FindFirstRec := false;
        exit(SearchResult);
    end;

    local procedure SetAnaViewEntryFilter(AnalysisViewDimCode: Text[30]; AnalysisViewFilter: Text[250])
    begin
        if AnalysisViewFilter = '' then
            AnalysisViewFilter := '''''';
        case AnalysisViewDimCode of
            TempGLAcc.TableCaption:
                if AnalysisViewFilter = '*' then
                    AnalysisViewEntry.SetRange("Account No.")
                else
                    AnalysisViewEntry.SetFilter("Account No.", AnalysisViewFilter);
            TempBusUnit.TableCaption:
                if AnalysisViewFilter = '*' then
                    AnalysisViewEntry.SetRange("Business Unit Code")
                else
                    AnalysisViewEntry.SetFilter("Business Unit Code", AnalysisViewFilter);
            "Analysis View"."Dimension 1 Code":
                if AnalysisViewFilter = '*' then
                    AnalysisViewEntry.SetRange("Dimension 1 Value Code")
                else
                    AnalysisViewEntry.SetFilter("Dimension 1 Value Code", AnalysisViewFilter);
            "Analysis View"."Dimension 2 Code":
                if AnalysisViewFilter = '*' then
                    AnalysisViewEntry.SetRange("Dimension 2 Value Code")
                else
                    AnalysisViewEntry.SetFilter("Dimension 2 Value Code", AnalysisViewFilter);
            "Analysis View"."Dimension 3 Code":
                if AnalysisViewFilter = '*' then
                    AnalysisViewEntry.SetRange("Dimension 3 Value Code")
                else
                    AnalysisViewEntry.SetFilter("Dimension 3 Value Code", AnalysisViewFilter);
            "Analysis View"."Dimension 4 Code":
                if AnalysisViewFilter = '*' then
                    AnalysisViewEntry.SetRange("Dimension 4 Value Code")
                else
                    AnalysisViewEntry.SetFilter("Dimension 4 Value Code", AnalysisViewFilter);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordAnalysisViewOnBeforeSetEntryFilterGroup(var AnalysisViewEntry: Record "Analysis View Entry"; AnalysisView: Record "Analysis View")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrintDetailOnAfterTempGLEntrySetFilters(var TempGLEntry: Record "G/L Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnAfterDimValSetFilters(var DimensionValue: Record "Dimension Value")
    begin
    end;
}

