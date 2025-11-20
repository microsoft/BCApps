// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Forecast;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Text;
using System.Utilities;

report 27 "Dimensions - Total"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/Dimension/DimensionsTotal.rdlc';
    AllowScheduling = false;
    ApplicationArea = Dimensions;
    Caption = 'Dimensions - Total';
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
            column(ColumnLayoutName; ColumnLayoutName)
            {
            }
            column(Analysis_View_Code; Code)
            {
            }
            column(DateFilter; DateFilter)
            {
            }
            column(USERID; UserId)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(HeaderText; HeaderText)
            {
            }
            column(LCYCode; LCYCode)
            {
            }
            column(AddRepCurr; AddRepCurr)
            {
            }
            column(DimFilterText; DimFilterText)
            {
            }
#if not CLEAN27
            column(Header_5_; Header30[5])
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'The text length limit will be removed in a future release.';
                ObsoleteTag = '27.0';
            }
            column(Header_4_; Header30[4])
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'The text length limit will be removed in a future release.';
                ObsoleteTag = '27.0';
            }
            column(Header_3_; Header30[3])
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'The text length limit will be removed in a future release.';
                ObsoleteTag = '27.0';
            }
            column(Header_2_; Header30[2])
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'The text length limit will be removed in a future release.';
                ObsoleteTag = '27.0';
            }
            column(Header_1_; Header30[1])
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'The text length limit will be removed in a future release.';
                ObsoleteTag = '27.0';
            }
#else
            column(Header_5_; Header[5])
            {
            }
            column(Header_4_; Header[4])
            {
            }
            column(Header_3_; Header[3])
            {
            }
            column(Header_2_; Header[2])
            {
            }
            column(Header_1_; Header[1])
            {
            }
#endif
            column(RoundingHeader_5_; RoundingHeader[5])
            {
                AutoCalcField = false;
            }
            column(RoundingHeader_4_; RoundingHeader[4])
            {
                AutoCalcField = false;
            }
            column(RoundingHeader_3_; RoundingHeader[3])
            {
                AutoCalcField = false;
            }
            column(RoundingHeader_2_; RoundingHeader[2])
            {
                AutoCalcField = false;
            }
            column(RoundingHeader_1_; RoundingHeader[1])
            {
                AutoCalcField = false;
            }
            column(ColumnLayoutNameCaption; ColumnLayoutNameCaptionLbl)
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
            column(Dimensions___TotalCaption; Dimensions___TotalCaptionLbl)
            {
            }
            column(FiltersCaption; FiltersCaptionLbl)
            {
            }
            column(Dimension_ValueCaption; Dimension_ValueCaptionLbl)
            {
            }
            column(DimensionCaption; DimensionCaptionLbl)
            {
            }
            dataitem(Level1; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(ColumnValuesAsText_5_1_; ColumnValuesAsText[5, 1])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_4_1_; ColumnValuesAsText[4, 1])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_3_1_; ColumnValuesAsText[3, 1])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_2_1_; ColumnValuesAsText[2, 1])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_1_1_; ColumnValuesAsText[1, 1])
                {
                    AutoCalcField = false;
                }
                column(DimValCode_1_; DimValCode[1])
                {
                }
                column(DimCode_1_; DimCode[1])
                {
                }
                column(PADSTR____DimValNameIndent_1____2____DimValName_1_; PadStr('', DimValNameIndent[1] * 2) + DimValName[1])
                {
                }
                column(ColumnValuesAsText_5_1__Control51; ColumnValuesAsText[5, 1])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_4_1__Control52; ColumnValuesAsText[4, 1])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_3_1__Control53; ColumnValuesAsText[3, 1])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_2_1__Control58; ColumnValuesAsText[2, 1])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_1_1__Control99; ColumnValuesAsText[1, 1])
                {
                    AutoCalcField = false;
                }
                column(PADSTR____DimValNameIndent_1____2____DimValName_1__Control100; PadStr('', DimValNameIndent[1] * 2) + DimValName[1])
                {
                }
                column(DimValCode_1__Control101; DimValCode[1])
                {
                }
                column(DimCode_1__Control102; DimCode[1])
                {
                }
                column(DimValCode_1__Control48; DimValCode[1])
                {
                }
                column(DimCode_1__Control10; DimCode[1])
                {
                }
                column(PADSTR____DimValNameIndent_1____2____DimValName_1__Control72; PadStr('', DimValNameIndent[1] * 2) + DimValName[1])
                {
                }
                column(Level1_Number; Number)
                {
                }
                dataitem(Level2; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(ColumnValuesAsText_5_2_; ColumnValuesAsText[5, 2])
                    {
                        AutoCalcField = false;
                    }
                    column(ColumnValuesAsText_4_2_; ColumnValuesAsText[4, 2])
                    {
                        AutoCalcField = false;
                    }
                    column(ColumnValuesAsText_3_2_; ColumnValuesAsText[3, 2])
                    {
                        AutoCalcField = false;
                    }
                    column(ColumnValuesAsText_2_2_; ColumnValuesAsText[2, 2])
                    {
                        AutoCalcField = false;
                    }
                    column(ColumnValuesAsText_1_2_; ColumnValuesAsText[1, 2])
                    {
                        AutoCalcField = false;
                    }
                    column(DimValCode_2_; DimValCode[2])
                    {
                    }
                    column(DimCode_2_; DimCode[2])
                    {
                    }
                    column(PADSTR____DimValNameIndent_2____2____DimValName_2_; PadStr('', DimValNameIndent[2] * 2) + DimValName[2])
                    {
                    }
                    column(ColumnValuesAsText_5_2__Control103; ColumnValuesAsText[5, 2])
                    {
                        AutoCalcField = false;
                    }
                    column(ColumnValuesAsText_4_2__Control104; ColumnValuesAsText[4, 2])
                    {
                        AutoCalcField = false;
                    }
                    column(ColumnValuesAsText_3_2__Control106; ColumnValuesAsText[3, 2])
                    {
                        AutoCalcField = false;
                    }
                    column(ColumnValuesAsText_2_2__Control107; ColumnValuesAsText[2, 2])
                    {
                        AutoCalcField = false;
                    }
                    column(ColumnValuesAsText_1_2__Control108; ColumnValuesAsText[1, 2])
                    {
                        AutoCalcField = false;
                    }
                    column(PADSTR____DimValNameIndent_2____2____DimValName_2__Control109; PadStr('', DimValNameIndent[2] * 2) + DimValName[2])
                    {
                    }
                    column(DimValCode_2__Control116; DimValCode[2])
                    {
                    }
                    column(DimCode_2__Control117; DimCode[2])
                    {
                    }
                    column(DimValCode_2__Control59; DimValCode[2])
                    {
                    }
                    column(DimCode_2__Control17; DimCode[2])
                    {
                    }
                    column(PADSTR____DimValNameIndent_2____2____DimValName_2__Control74; PadStr('', DimValNameIndent[2] * 2) + DimValName[2])
                    {
                    }
                    column(Level2_Number; Number)
                    {
                    }
                    dataitem(Level3; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(ColumnValuesAsText_5_3_; ColumnValuesAsText[5, 3])
                        {
                            AutoCalcField = false;
                        }
                        column(ColumnValuesAsText_4_3_; ColumnValuesAsText[4, 3])
                        {
                            AutoCalcField = false;
                        }
                        column(ColumnValuesAsText_3_3_; ColumnValuesAsText[3, 3])
                        {
                            AutoCalcField = false;
                        }
                        column(ColumnValuesAsText_2_3_; ColumnValuesAsText[2, 3])
                        {
                            AutoCalcField = false;
                        }
                        column(ColumnValuesAsText_1_3_; ColumnValuesAsText[1, 3])
                        {
                            AutoCalcField = false;
                        }
                        column(DimValCode_3_; DimValCode[3])
                        {
                        }
                        column(DimCode_3_; DimCode[3])
                        {
                        }
                        column(PADSTR____DimValNameIndent_3____2____DimValName_3_; PadStr('', DimValNameIndent[3] * 2) + DimValName[3])
                        {
                        }
                        column(DimCode_3__Control118; DimCode[3])
                        {
                        }
                        column(DimValCode_3__Control119; DimValCode[3])
                        {
                        }
                        column(PADSTR____DimValNameIndent_3____2____DimValName_3__Control120; PadStr('', DimValNameIndent[3] * 2) + DimValName[3])
                        {
                        }
                        column(ColumnValuesAsText_1_3__Control121; ColumnValuesAsText[1, 3])
                        {
                            AutoCalcField = false;
                        }
                        column(ColumnValuesAsText_2_3__Control122; ColumnValuesAsText[2, 3])
                        {
                            AutoCalcField = false;
                        }
                        column(ColumnValuesAsText_3_3__Control123; ColumnValuesAsText[3, 3])
                        {
                            AutoCalcField = false;
                        }
                        column(ColumnValuesAsText_4_3__Control124; ColumnValuesAsText[4, 3])
                        {
                            AutoCalcField = false;
                        }
                        column(ColumnValuesAsText_5_3__Control125; ColumnValuesAsText[5, 3])
                        {
                            AutoCalcField = false;
                        }
                        column(DimValCode_3__Control22; DimValCode[3])
                        {
                        }
                        column(DimCode_3__Control18; DimCode[3])
                        {
                        }
                        column(PADSTR____DimValNameIndent_3____2____DimValName_3__Control76; PadStr('', DimValNameIndent[3] * 2) + DimValName[3])
                        {
                        }
                        column(Level3_Number; Number)
                        {
                        }
                        dataitem(Level4; "Integer")
                        {
                            DataItemTableView = sorting(Number);
                            column(DimCode_4_; DimCode[4])
                            {
                            }
                            column(DimValCode_4_; DimValCode[4])
                            {
                            }
                            column(PADSTR____DimValNameIndent_4____2____DimValName_4_; PadStr('', DimValNameIndent[4] * 2) + DimValName[4])
                            {
                            }
                            column(ColumnValuesAsText_1_4_; ColumnValuesAsText[1, 4])
                            {
                                AutoCalcField = false;
                            }
                            column(ColumnValuesAsText_2_4_; ColumnValuesAsText[2, 4])
                            {
                                AutoCalcField = false;
                            }
                            column(ColumnValuesAsText_3_4_; ColumnValuesAsText[3, 4])
                            {
                                AutoCalcField = false;
                            }
                            column(ColumnValuesAsText_4_4_; ColumnValuesAsText[4, 4])
                            {
                                AutoCalcField = false;
                            }
                            column(ColumnValuesAsText_5_4_; ColumnValuesAsText[5, 4])
                            {
                                AutoCalcField = false;
                            }
                            column(ColumnValuesAsText_5_4__Control35; ColumnValuesAsText[5, 4])
                            {
                                AutoCalcField = false;
                            }
                            column(ColumnValuesAsText_4_4__Control36; ColumnValuesAsText[4, 4])
                            {
                                AutoCalcField = false;
                            }
                            column(ColumnValuesAsText_3_4__Control37; ColumnValuesAsText[3, 4])
                            {
                                AutoCalcField = false;
                            }
                            column(ColumnValuesAsText_2_4__Control38; ColumnValuesAsText[2, 4])
                            {
                                AutoCalcField = false;
                            }
                            column(ColumnValuesAsText_1_4__Control39; ColumnValuesAsText[1, 4])
                            {
                                AutoCalcField = false;
                            }
                            column(DimValCode_4__Control40; DimValCode[4])
                            {
                            }
                            column(DimCode_4__Control19; DimCode[4])
                            {
                            }
                            column(PADSTR____DimValNameIndent_4____2____DimValName_4__Control77; PadStr('', DimValNameIndent[4] * 2) + DimValName[4])
                            {
                            }
                            column(Level4_Number; Number)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if not CalcLine(4) and not PrintEmptyLines then
                                    CurrReport.Skip();
                            end;

                            trigger OnPreDataItem()
                            begin
                                if DimCode[4] = '' then
                                    CurrReport.Break();
                                FindFirstDim[4] := true;
                            end;
                        }
                        dataitem(Level3e; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = const(1));
                            column(PADSTR____DimValNameIndent_3____2____DimValName_3__Control78; PadStr('', DimValNameIndent[3] * 2) + DimValName[3])
                            {
                            }
                            column(DimValCode_3__Control79; DimValCode[3])
                            {
                            }
                            column(ColumnValuesAsText_1_3__Control84; ColumnValuesAsText[1, 3])
                            {
                                AutoCalcField = false;
                            }
                            column(ColumnValuesAsText_2_3__Control85; ColumnValuesAsText[2, 3])
                            {
                                AutoCalcField = false;
                            }
                            column(ColumnValuesAsText_3_3__Control86; ColumnValuesAsText[3, 3])
                            {
                                AutoCalcField = false;
                            }
                            column(ColumnValuesAsText_4_3__Control87; ColumnValuesAsText[4, 3])
                            {
                                AutoCalcField = false;
                            }
                            column(ColumnValuesAsText_5_3__Control88; ColumnValuesAsText[5, 3])
                            {
                                AutoCalcField = false;
                            }
                            column(DimCode_3__Control24; DimCode[3])
                            {
                            }
                            column(Level3e_Number; Number)
                            {
                            }
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if not CalcLine(3) and not PrintEmptyLines then
                                CurrReport.Skip();
                        end;

                        trigger OnPreDataItem()
                        begin
                            if DimCode[3] = '' then
                                CurrReport.Break();
                            FindFirstDim[3] := true;
                        end;
                    }
                    dataitem(Level2e; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(PADSTR____DimValNameIndent_2____2____DimValName_2__Control80; PadStr('', DimValNameIndent[2] * 2) + DimValName[2])
                        {
                        }
                        column(DimValCode_2__Control82; DimValCode[2])
                        {
                        }
                        column(ColumnValuesAsText_1_2__Control89; ColumnValuesAsText[1, 2])
                        {
                            AutoCalcField = false;
                        }
                        column(ColumnValuesAsText_2_2__Control90; ColumnValuesAsText[2, 2])
                        {
                            AutoCalcField = false;
                        }
                        column(ColumnValuesAsText_3_2__Control91; ColumnValuesAsText[3, 2])
                        {
                            AutoCalcField = false;
                        }
                        column(ColumnValuesAsText_4_2__Control92; ColumnValuesAsText[4, 2])
                        {
                            AutoCalcField = false;
                        }
                        column(ColumnValuesAsText_5_2__Control93; ColumnValuesAsText[5, 2])
                        {
                            AutoCalcField = false;
                        }
                        column(DimCode_2__Control23; DimCode[2])
                        {
                        }
                        column(Level2e_Number; Number)
                        {
                        }
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if not CalcLine(2) and not PrintEmptyLines then
                            CurrReport.Skip();
                    end;

                    trigger OnPreDataItem()
                    begin
                        if DimCode[2] = '' then
                            CurrReport.Break();
                        FindFirstDim[2] := true;
                    end;
                }
                dataitem(Level1e; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(PADSTR____DimValNameIndent_1____2____DimValName_1__Control81; PadStr('', DimValNameIndent[1] * 2) + DimValName[1])
                    {
                    }
                    column(DimValCode_1__Control83; DimValCode[1])
                    {
                    }
                    column(ColumnValuesAsText_1_1__Control94; ColumnValuesAsText[1, 1])
                    {
                        AutoCalcField = false;
                    }
                    column(ColumnValuesAsText_2_1__Control95; ColumnValuesAsText[2, 1])
                    {
                        AutoCalcField = false;
                    }
                    column(ColumnValuesAsText_3_1__Control96; ColumnValuesAsText[3, 1])
                    {
                        AutoCalcField = false;
                    }
                    column(ColumnValuesAsText_4_1__Control97; ColumnValuesAsText[4, 1])
                    {
                        AutoCalcField = false;
                    }
                    column(ColumnValuesAsText_5_1__Control98; ColumnValuesAsText[5, 1])
                    {
                        AutoCalcField = false;
                    }
                    column(DimCode_1__Control12; DimCode[1])
                    {
                    }
                    column(Level1e_Number; Number)
                    {
                    }
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
                end;
            }

            trigger OnAfterGetRecord()
            var
                i: Integer;
                ThisFilter: Text[250];
            begin
                if "Last Date Updated" <> 0D then
                    ViewLastUpdatedText :=
                      StrSubstNo('%1', "Last Date Updated")
                else
                    ViewLastUpdatedText := Text005;

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
                        SetAccSchedLineFilter(TempSelectedDim."Dimension Code", TempSelectedDim."Dimension Value Filter", true, '');
                    until TempSelectedDim.Next() = 0;

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

                MaxColumnsDisplayed := ArrayLen(ColumnValuesDisplayed);
                NoOfCols := 0;
                AccSchedManagement.CopyColumnsToTemp(ColumnLayoutName, TempColumnLayout);
                i := 0;
                if TempColumnLayout.Find('-') then begin
                    repeat
                        if TempColumnLayout.Show <> TempColumnLayout.Show::Never then begin
                            i := i + 1;
                            if i <= MaxColumnsDisplayed then begin
                                Header[i] := AccSchedManagement.CalcColumnHeader(AccSchedLine, TempColumnLayout);
#if not CLEAN27
                                Header30[i] := CopyStr(Header[i], 1, MaxStrLen(Header30[i]));
#endif
                                RoundingHeader[i] := '';
                                if TempColumnLayout."Rounding Factor" in [TempColumnLayout."Rounding Factor"::"1000", TempColumnLayout."Rounding Factor"::"1000000"] then
                                    case TempColumnLayout."Rounding Factor" of
                                        TempColumnLayout."Rounding Factor"::"1000":
                                            RoundingHeader[i] := Text006;
                                        TempColumnLayout."Rounding Factor"::"1000000":
                                            RoundingHeader[i] := Text007;
                                    end;
                            end;
                        end;
                        NoOfCols := NoOfCols + 1;
                    until (i >= MaxColumnsDisplayed) or (TempColumnLayout.Next() = 0);
                    MaxColumnsDisplayed := i;
                end;

                if UseAmtsInAddCurr then
                    HeaderText := StrSubstNo(Text008, GLSetup."Additional Reporting Currency")
                else
                    if GLSetup."LCY Code" <> '' then
                        HeaderText := StrSubstNo(Text008, GLSetup."LCY Code")
                    else
                        HeaderText := '';
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Code, AnalysisViewCode);
                GLSetup.Get();
                LCYCode := GLSetup."LCY Code";
                AddRepCurr := GLSetup."Additional Reporting Currency";
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        AboutTitle = 'About Dimensions - Total';
        AboutText = 'Build a group of dimensions for combinations of dimension values. Define a hierarchy of dimension levels from an analysis view, and list all G/L entries for each group. Compare G/L actual vs. budget total, or cash flow actual vs. forecast total.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AnalysisViewCode; AnalysisViewCode)
                    {
                        ApplicationArea = Suite;
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
                            GetAccountSource();
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
                        ToolTip = 'Specifies a field that is automatically filled in, when you select the Analysis View Code field.';

                        trigger OnAssistEdit()
                        begin
                            CalledGetAccountSource := false;
                            GetAccountSource();
                            if AccountSource = AccountSource::"G/L Account" then
                                DimSelectionBuf.SetDimSelectionLevelGLAcc(3, REPORT::"Dimensions - Total", AnalysisViewCode, ColumnDim)
                            else
                                if AccountSource = AccountSource::"Cash Flow Account" then
                                    DimSelectionBuf.SetDimSelectionLevelCFAcc(3, REPORT::"Dimensions - Total", AnalysisViewCode, ColumnDim);
                        end;
                    }
                    field(ColumnLayoutName; ColumnLayoutName)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Column Layout Name';
                        Lookup = true;
                        TableRelation = "Column Layout Name".Name;
                        ToolTip = 'Specifies the name of the column layout that you want to use in the window.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            exit(AccSchedManagement.LookupColumnName(ColumnLayoutName, Text));
                        end;

                        trigger OnValidate()
                        begin
                            if ColumnLayoutName <> '' then
                                AccSchedManagement.CheckColumnName(ColumnLayoutName);
                        end;
                    }
                    field(DtFilter; DateFilter)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Date Filter';
                        ShowMandatory = true;
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
                    field(GLBudgetName; GLBudgetName)
                    {
                        ApplicationArea = Suite;
                        Caption = 'G/L Budget Name';
                        Lookup = true;
                        TableRelation = "G/L Budget Name";
                        ToolTip = 'Specifies the budget that the report is based on. This field is used if you have specified a column layout in the Column Layout Name field that includes budget figures.';
                    }
                    field(CashFlowForecastNo; CashFlowForecastNo)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Cash Flow Forecast No.';
                        Editable = CashFlowEditable;
                        TableRelation = "Cash Flow Forecast";
                        ToolTip = 'Specifies the cash flow forecast number that the report is based on, when you have entered the Analysis View Code for cash flow. ';
                    }
                    field(PrintEmptyLines; PrintEmptyLines)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Print Empty Lines';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want the report to include dimensions and dimension values that have a balance equal to zero.';
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

            TransferValues();
            UpdateColumnDim();
            GetAccountSource();
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            if CloseAction <> Action::Cancel then
                if DateFilter = '' then
                    Error(Text002);
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        AccSchedName: Record "Acc. Schedule Name";
        SelectedDim: Record "Selected Dimension";
        AnalysisView: Record "Analysis View";
    begin
        if AnalysisViewCode = '' then
            Error(Text000);

        AnalysisView.Get(AnalysisViewCode);
        CODEUNIT.Run(CODEUNIT::"Update Analysis View", AnalysisView);

        GetAccountSource();

        if ColumnLayoutName = '' then
            Error(Text001);

        if DateFilter = '' then
            Error(Text002);

        DimSelectionBuf.CompareDimText(
          3, REPORT::"Dimensions - Total", AnalysisViewCode, ColumnDim, Text003);

        SelectedDim.GetSelectedDim(UserId, 3, REPORT::"Dimensions - Total", AnalysisViewCode, TempSelectedDim);

        if AccountSource = AccountSource::"G/L Account" then
            FillTempGLAccount()
        else
            if AccountSource = AccountSource::"Cash Flow Account" then
                FillTempCFAccount();

        TempSelectedDim.Reset();
        TempSelectedDim.SetCurrentKey("User ID", "Object Type", "Object ID", "Analysis View Code", Level);
        TempSelectedDim.SetFilter(Level, '<>%1', TempSelectedDim.Level::" ");
        if TempSelectedDim.FindSet() then
            repeat
                TempDimVal.Init();
                TempDimVal.Code := '';
                TempDimVal."Dimension Code" := TempSelectedDim."Dimension Code";
                TempDimVal.Name := Text004;
                TempDimVal.Insert();
                DimVal.SetRange("Dimension Code", TempSelectedDim."Dimension Code");
                if TempSelectedDim."Dimension Value Filter" <> '' then
                    DimVal.SetFilter(Code, TempSelectedDim."Dimension Value Filter")
                else
                    DimVal.SetRange(Code);
                OnPreReportOnAfterDimValSetFilters(DimVal);
                if DimVal.FindSet() then
                    repeat
                        TempDimVal.Init();
                        TempDimVal := DimVal;
                        TempDimVal.Insert();
                    until DimVal.Next() = 0;
            until TempSelectedDim.Next() = 0;

        // Commit added to free resources and allowing the report to use the read only replica
        Commit();
        AccSchedName."Analysis View Name" := AnalysisViewCode;
        AccSchedManagement.SetAccSchedName(AccSchedName);
        InitAccSchedLine();
    end;

    var
        AccSchedLine: Record "Acc. Schedule Line";
        TempSelectedDim: Record "Selected Dimension" temporary;
        BusUnit: Record "Business Unit";
        DimVal: Record "Dimension Value";
        TempGLAcc: Record "G/L Account" temporary;
        TempBusUnit: Record "Business Unit" temporary;
        TempDimVal: Record "Dimension Value" temporary;
        TempColumnLayout: Record "Column Layout" temporary;
        DimSelectionBuf: Record "Dimension Selection Buffer";
        GLSetup: Record "General Ledger Setup";
        TempCFAccount: Record "Cash Flow Account" temporary;
        TempCashFlowForecast: Record "Cash Flow Forecast" temporary;
        CFAccount: Record "Cash Flow Account";
        CashFlowForecast: Record "Cash Flow Forecast";
        AccSchedManagement: Codeunit AccSchedManagement;
        ColumnLayoutName: Code[10];
        GLBudgetName: Code[10];
        PrintEmptyLines: Boolean;
        GLAccRange: Code[42];
        ColumnValuesDisplayed: array[5] of Decimal;
        ColumnValuesAsText: array[5, 4] of Text[30];
        Header: array[5] of Text;
#if not CLEAN27
        Header30: array[5] of Text[30];
#endif
        RoundingHeader: array[5] of Text[30];
        MaxColumnsDisplayed: Integer;
        NoOfCols: Integer;
        UseAmtsInAddCurr: Boolean;
        ViewLastUpdatedText: Text[30];
        ColumnDim: Text[250];
        AnalysisViewCode: Code[10];
        DateFilter: Text[250];
        FindFirstDim: array[4] of Boolean;
        DimCode: array[4] of Text[30];
        DimValCode: array[4] of Code[20];
        DimValName: array[4] of Text[100];
        DimValNameIndent: array[4] of Integer;
        LevelFilter: array[4] of Text[250];
        HeaderText: Text[100];
        DimFilterText: Text[250];
        PrintEndTotals: array[50] of Boolean;
        GLAccFilterSet: Boolean;
        LCYCode: Code[20];
        AddRepCurr: Code[20];
        CFAccRange: Code[42];
        CFAccFilterSet: Boolean;
        AccountSource: Option "G/L Account","Cash Flow Account";
        CalledGetAccountSource: Boolean;
        CashFlowForecastNo: Code[10];
        CashFlowEditable: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Enter an analysis view code.';
        Text001: Label 'Enter a column layout name.';
        Text002: Label 'Enter a date filter.';
        Text003: Label 'Include Dimensions';
        Text004: Label '(no dimension value)';
        Text005: Label 'Not updated';
        Text006: Label '(Thousands)';
        Text007: Label '(Millions)';
#pragma warning disable AA0470
        Text008: Label 'All amounts are in %1.';
#pragma warning restore AA0470
        Text009: Label '(no business unit)';
#pragma warning restore AA0074
        ColumnLayoutNameCaptionLbl: Label 'Column Layout';
        DateFilterCaptionLbl: Label 'Period';
        Analysis_View_CodeCaptionLbl: Label 'Analysis View';
        ViewLastUpdatedTextCaptionLbl: Label 'Last Date Updated';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Dimensions___TotalCaptionLbl: Label 'Dimensions - Total';
        FiltersCaptionLbl: Label 'Filters';
        Dimension_ValueCaptionLbl: Label 'Dimension Value';
        DimensionCaptionLbl: Label 'Dimension';

    protected var
        GLAcc: Record "G/L Account";

    local procedure CalcLine(Level: Integer): Boolean
    var
        i: Integer;
        Totaling: Text[250];
        Indentation: Integer;
        PostingType: Option Standard,Heading,Total,"Begin-Total","End-Total";
        LowestLevel: Boolean;
        ThisDimValCode: Code[20];
        ThisDimValName: Text[100];
        ThisTotaling: Text[250];
        ThisIndentation: Integer;
        ThisPostingType: Option Standard,Heading,Total,"Begin-Total","End-Total";
        LineNo: Integer;
        HasValue: Boolean;
        More: Boolean;
    begin
        if Iteration(
             FindFirstDim[Level], DimCode[Level], DimValCode[Level], DimValName[Level], LevelFilter[Level],
             Totaling, Indentation, PostingType)
        then begin
            if Level = 4 then
                LowestLevel := true
            else
                LowestLevel := DimCode[Level + 1] = '';

            if (not PrintEmptyLines) and (not LowestLevel) then begin
                SetAccSchedLineFilter(DimCode[Level], DimValCode[Level], true, Totaling);
                HasValue := TestCalcLine(Level + 1, true);
            end;

            if LowestLevel then
                DimValNameIndent[Level] := Indentation
            else begin
                DimValNameIndent[Level] := 0;
                Clear(PrintEndTotals);
                i := Level + 1;
                while i <= ArrayLen(DimCode) do begin
                    if DimCode[i] <> '' then
                        if LevelFilter[i] <> '' then
                            SetAccSchedLineFilter(DimCode[i], LevelFilter[i], true, '')
                        else
                            SetAccSchedLineFilter(DimCode[i], '', false, '');
                    i := i + 1;
                end;
            end;

            // Check if begin-total should be printed...
            if (not PrintEmptyLines) and LowestLevel and (PostingType = PostingType::"Begin-Total") then begin
                LineNo := AccSchedLine."Line No.";
                ThisDimValCode := DimValCode[Level];
                ThisTotaling := Totaling;
                ThisIndentation := 999999999;
                More := true;
                SetAccSchedLineFilter(DimCode[Level], ThisDimValCode, true, ThisTotaling);
                HasValue := CalcColumns(0);
                while More and (not HasValue) and (ThisIndentation > Indentation) do begin
                    More :=
                      Iteration(
                        FindFirstDim[Level], DimCode[Level], ThisDimValCode, ThisDimValName, LevelFilter[Level],
                        ThisTotaling, ThisIndentation, ThisPostingType);
                    if More then begin
                        SetAccSchedLineFilter(DimCode[Level], ThisDimValCode, true, ThisTotaling);
                        HasValue := CalcColumns(0);
                    end;
                end;
                AccSchedLine."Line No." := LineNo;
                PrintEndTotals[Indentation + 1] := HasValue;
            end;

            // Check if end-total should be printed...
            if (not PrintEmptyLines) and LowestLevel and (PostingType = PostingType::"End-Total") then begin
                HasValue := PrintEndTotals[Indentation + 1];
                PrintEndTotals[Indentation + 1] := false;
            end;

            SetAccSchedLineFilter(DimCode[Level], DimValCode[Level], true, Totaling);
            for i := 1 to MaxColumnsDisplayed do begin
                ColumnValuesDisplayed[i] := 0;
                ColumnValuesAsText[i, Level] := '';
            end;

            exit(HasValue or CalcColumns(Level));
        end;
        CurrReport.Break();
    end;

    local procedure TestCalcLine(Level: Integer; ThisFindFirstDim: Boolean): Boolean
    var
        Totaling: Text[250];
        LowestLevel: Boolean;
        ThisDimValName: Text[100];
        ThisIndentation: Integer;
        ThisPostingType: Option Standard,Heading,Total,"Begin-Total","End-Total";
        HasValue: Boolean;
        More: Boolean;
        TryNext: Boolean;
    begin
        FindFirstDim[Level] := ThisFindFirstDim;

        TryNext := true;
        while TryNext and not HasValue do begin
            TryNext := false;
            Clear(Totaling);
            Clear(LowestLevel);
            Clear(ThisDimValName);
            Clear(ThisIndentation);
            Clear(ThisPostingType);

            if Iteration(
                 FindFirstDim[Level], DimCode[Level], DimValCode[Level], ThisDimValName, LevelFilter[Level],
                 Totaling, ThisIndentation, ThisPostingType)
            then begin
                if Level = 4 then
                    LowestLevel := true
                else
                    LowestLevel := DimCode[Level + 1] = '';

                if LowestLevel then begin
                    More := true;
                    SetAccSchedLineFilter(DimCode[Level], DimValCode[Level], true, Totaling);
                    HasValue := CalcColumns(0);
                    while More and (not HasValue) do begin
                        More :=
                          Iteration(
                            FindFirstDim[Level], DimCode[Level], DimValCode[Level], ThisDimValName, LevelFilter[Level],
                            Totaling, ThisIndentation, ThisPostingType);
                        if More then begin
                            SetAccSchedLineFilter(DimCode[Level], DimValCode[Level], true, Totaling);
                            HasValue := CalcColumns(0);
                        end;
                    end;
                end else begin
                    HasValue := TestCalcLine(Level + 1, true);
                    TryNext := not HasValue;
                end;
            end else
                HasValue := false;
        end;
        exit(HasValue);
    end;

    local procedure CalcColumns(Level: Integer): Boolean
    var
        NonZero: Boolean;
        i: Integer;
    begin
        NonZero := false;
        if AccountSource = AccountSource::"G/L Account" then begin
            if not GLAccFilterSet then
                AccSchedLine.Totaling := GLAccRange;
        end else
            if AccountSource = AccountSource::"Cash Flow Account" then
                if not CFAccFilterSet then
                    AccSchedLine.Totaling := CFAccRange;
        TempColumnLayout.SetRange("Column Layout Name", ColumnLayoutName);
        i := 0;
        if TempColumnLayout.FindSet() then
            repeat
                if TempColumnLayout.Show <> TempColumnLayout.Show::Never then begin
                    i := i + 1;
                    AccSchedLine."Line No." := AccSchedLine."Line No." + 1;
                    ColumnValuesDisplayed[i] :=
                      AccSchedManagement.CalcCell(AccSchedLine, TempColumnLayout, UseAmtsInAddCurr);
                    NonZero :=
                      NonZero or (ColumnValuesDisplayed[i] <> 0) and
                      (TempColumnLayout."Column Type" <> TempColumnLayout."Column Type"::Formula);
                    if Level > 0 then
                        ColumnValuesAsText[i, Level] :=
                          AccSchedManagement.FormatCellAsText(TempColumnLayout, ColumnValuesDisplayed[i], UseAmtsInAddCurr);
                end;
            until (i >= MaxColumnsDisplayed) or (TempColumnLayout.Next() = 0);
        exit(NonZero);
    end;

    local procedure UpdateColumnDim()
    var
        SelectedDim: Record "Selected Dimension";
        TempDimSelectionBuf: Record "Dimension Selection Buffer" temporary;
        AnalysisView: Record "Analysis View";
    begin
        AnalysisView.CopyAnalysisViewFilters(3, REPORT::"Dimensions - Total", AnalysisViewCode);
        ColumnDim := '';
        SelectedDim.SetRange("User ID", UserId);
        SelectedDim.SetRange("Object Type", 3);
        SelectedDim.SetRange("Object ID", REPORT::"Dimensions - Total");
        SelectedDim.SetRange("Analysis View Code", AnalysisViewCode);
        if SelectedDim.FindSet() then begin
            repeat
                TempDimSelectionBuf.Init();
                TempDimSelectionBuf.Code := SelectedDim."Dimension Code";
                TempDimSelectionBuf.Selected := true;
                TempDimSelectionBuf."Dimension Value Filter" := SelectedDim."Dimension Value Filter";
                TempDimSelectionBuf.Level := SelectedDim.Level;
                TempDimSelectionBuf.Insert();
            until SelectedDim.Next() = 0;
            TempDimSelectionBuf.SetDimSelection(
              3, REPORT::"Dimensions - Total", AnalysisViewCode, ColumnDim, TempDimSelectionBuf);
        end;
    end;

    local procedure Iteration(var FindFirstRec: Boolean; IterationDimCode: Text[30]; var IterationDimValCode: Code[20]; var IterationDimValName: Text[100]; IterationFilter: Text[250]; var IterationTotaling: Text[250]; var IterationIndentation: Integer; var IterationPostingType: Option Standard,Heading,Total,"Begin-Total","End-Total"): Boolean
    var
        SearchResult: Boolean;
    begin
        case IterationDimCode of
            TempGLAcc.TableCaption:
                begin
                    TempGLAcc.Reset();
                    TempGLAcc.SetFilter("No.", IterationFilter);
                    if FindFirstRec then
                        SearchResult := TempGLAcc.FindSet()
                    else
                        if TempGLAcc.Get(IterationDimValCode) then
                            SearchResult := (TempGLAcc.Next() <> 0);
                    if SearchResult then begin
                        IterationDimValCode := TempGLAcc."No.";
                        IterationDimValName := TempGLAcc.Name;
                        IterationTotaling := TempGLAcc.Totaling;
                        IterationIndentation := TempGLAcc.Indentation;
                        IterationPostingType := TempGLAcc."Account Type".AsInteger();
                    end;
                end;
            TempBusUnit.TableCaption:
                begin
                    TempBusUnit.Reset();
                    TempBusUnit.SetFilter(Code, IterationFilter);
                    if FindFirstRec then
                        SearchResult := TempBusUnit.FindSet()
                    else
                        if TempBusUnit.Get(IterationDimValCode) then
                            SearchResult := (TempBusUnit.Next() <> 0);
                    if SearchResult then begin
                        IterationDimValCode := TempBusUnit.Code;
                        if TempBusUnit.Code <> '' then
                            IterationDimValName := TempBusUnit.Name
                        else
                            IterationDimValName := Text009;
                        IterationIndentation := 0;
                        IterationPostingType := 0;
                    end;
                end;
            TempCFAccount.TableCaption:
                begin
                    TempCFAccount.Reset();
                    TempCFAccount.SetFilter("No.", IterationFilter);
                    if FindFirstRec then
                        SearchResult := TempCFAccount.FindSet()
                    else
                        if TempCFAccount.Get(IterationDimValCode) then
                            SearchResult := (TempCFAccount.Next() <> 0);
                    if SearchResult then begin
                        IterationDimValCode := TempCFAccount."No.";
                        IterationDimValName := TempCFAccount.Name;
                        IterationTotaling := TempCFAccount.Totaling;
                        IterationIndentation := TempCFAccount.Indentation;
                        IterationPostingType := TempCFAccount."Account Type".AsInteger();
                    end;
                end;
            TempCashFlowForecast.TableCaption:
                begin
                    TempCashFlowForecast.Reset();
                    TempCashFlowForecast.SetFilter("No.", IterationFilter);
                    if FindFirstRec then
                        SearchResult := TempCashFlowForecast.FindSet()
                    else
                        if TempCashFlowForecast.Get(IterationDimValCode) then
                            SearchResult := (TempCashFlowForecast.Next() <> 0);
                    if SearchResult then begin
                        IterationDimValCode := TempCashFlowForecast."No.";
                        if TempCashFlowForecast."No." <> '' then
                            IterationDimValName := TempCashFlowForecast.Description
                        else
                            IterationDimValName := Text009;
                        IterationIndentation := 0;
                        IterationPostingType := 0;
                    end;
                end;
            else begin
                TempDimVal.Reset();
                TempDimVal.SetRange("Dimension Code", IterationDimCode);
                TempDimVal.SetFilter(Code, IterationFilter);
                if FindFirstRec then
                    SearchResult := TempDimVal.FindSet()
                else
                    if TempDimVal.Get(IterationDimCode, IterationDimValCode) then
                        SearchResult := (TempDimVal.Next() <> 0);
                if SearchResult then begin
                    IterationDimValCode := TempDimVal.Code;
                    IterationDimValName := TempDimVal.Name;
                    IterationTotaling := TempDimVal.Totaling;
                    IterationIndentation := TempDimVal.Indentation;
                    IterationPostingType := TempDimVal."Dimension Value Type";
                end;
            end;
        end;
        if not SearchResult then begin
            IterationDimValCode := '';
            IterationDimValName := '';
            IterationTotaling := '';
            IterationIndentation := 0;
            IterationPostingType := 0;
        end;
        FindFirstRec := false;
        exit(SearchResult);
    end;

    local procedure GetAccountSource()
    var
        AnalysisView: Record "Analysis View";
    begin
        if CalledGetAccountSource then
            exit;

        if AnalysisView.Get(AnalysisViewCode) then begin
            AccountSource := AnalysisView."Account Source".AsInteger();
            CalledGetAccountSource := true;
        end;
        if AccountSource = AccountSource::"Cash Flow Account" then
            CashFlowEditable := true
        else
            if AccountSource = AccountSource::"G/L Account" then
                CashFlowEditable := false;
    end;

    local procedure FillTempGLAccount()
    begin
        TempSelectedDim.Reset();
        TempSelectedDim.SetRange("Dimension Code", TempGLAcc.TableCaption());
        TempSelectedDim.SetFilter("Dimension Value Filter", '<>%1', '');
        if TempSelectedDim.FindFirst() then
            GLAcc.SetFilter("No.", TempSelectedDim."Dimension Value Filter");
        OnFillTempGLAccountOnBeforeGLAccFind(GLAcc);
        if GLAcc.FindSet() then begin
            GLAccRange := GLAcc."No.";
            repeat
                TempGLAcc.Init();
                TempGLAcc := GLAcc;
                TempGLAcc.Insert();
            until GLAcc.Next() = 0;
            GLAccRange := GLAccRange + '..' + GLAcc."No.";
        end;

        TempBusUnit.Init();
        TempBusUnit.Insert();
        TempSelectedDim.Reset();
        TempSelectedDim.SetFilter("Dimension Code", TempBusUnit.TableCaption());
        if TempSelectedDim.FindFirst() then
            TempBusUnit.SetFilter(Code, TempSelectedDim."Dimension Value Filter");
        if BusUnit.FindSet() then
            repeat
                TempBusUnit.Init();
                TempBusUnit := BusUnit;
                TempBusUnit.Insert();
            until BusUnit.Next() = 0;
    end;

    local procedure FillTempCFAccount()
    begin
        TempSelectedDim.Reset();
        TempSelectedDim.SetRange("Dimension Code", TempCFAccount.TableCaption());
        TempSelectedDim.SetFilter("Dimension Value Filter", '<>%1', '');
        if TempSelectedDim.FindFirst() then
            CFAccount.SetFilter("No.", TempSelectedDim."Dimension Value Filter");
        if CFAccount.FindSet() then begin
            CFAccRange := CFAccount."No.";
            repeat
                TempCFAccount.Init();
                TempCFAccount := CFAccount;
                TempCFAccount.Insert();
            until CFAccount.Next() = 0;
            CFAccRange := CFAccRange + '..' + CFAccount."No.";
        end;

        TempCashFlowForecast.Init();
        TempCashFlowForecast.Insert();
        TempSelectedDim.SetFilter("Dimension Code", TempCashFlowForecast.TableCaption());
        if TempSelectedDim.FindFirst() then
            TempCashFlowForecast.SetFilter("No.", TempSelectedDim."Dimension Value Filter");
        if CashFlowForecast.FindSet() then
            repeat
                TempCashFlowForecast.Init();
                TempCashFlowForecast := CashFlowForecast;
                TempCashFlowForecast.Insert();
            until CashFlowForecast.Next() = 0;
    end;

    local procedure SetAccSchedLineFilter(AnalysisViewDimCode: Text[30]; AnalysisViewFilter: Text[250]; SetFilter: Boolean; Totaling: Text[250])
    begin
        if Totaling <> '' then
            AnalysisViewFilter := Totaling;
        if SetFilter and (AnalysisViewFilter = '') then
            AnalysisViewFilter := '''''';
        case AnalysisViewDimCode of
            TempGLAcc.TableCaption:
                begin
                    GLAccFilterSet := SetFilter;
                    if SetFilter then
                        AccSchedLine.Totaling := AnalysisViewFilter
                    else
                        AccSchedLine.Totaling := GLAccRange;
                end;
            TempBusUnit.TableCaption:
                if SetFilter then
                    AccSchedLine.SetFilter("Business Unit Filter", AnalysisViewFilter)
                else
                    AccSchedLine.SetRange("Business Unit Filter");
            TempCFAccount.TableCaption:
                begin
                    CFAccFilterSet := SetFilter;
                    if SetFilter then
                        AccSchedLine.Totaling := AnalysisViewFilter
                    else
                        AccSchedLine.Totaling := CFAccRange;
                end;
            TempCashFlowForecast.TableCaption:
                if SetFilter then
                    AccSchedLine.SetFilter("Cash Flow Forecast Filter", AnalysisViewFilter)
                else
                    AccSchedLine.SetRange("Cash Flow Forecast Filter");
            "Analysis View"."Dimension 1 Code":
                if SetFilter then
                    AccSchedLine."Dimension 1 Totaling" := AnalysisViewFilter
                else
                    AccSchedLine."Dimension 1 Totaling" := '';
            "Analysis View"."Dimension 2 Code":
                if SetFilter then
                    AccSchedLine."Dimension 2 Totaling" := AnalysisViewFilter
                else
                    AccSchedLine."Dimension 2 Totaling" := '';
            "Analysis View"."Dimension 3 Code":
                if SetFilter then
                    AccSchedLine."Dimension 3 Totaling" := AnalysisViewFilter
                else
                    AccSchedLine."Dimension 3 Totaling" := '';
            "Analysis View"."Dimension 4 Code":
                if SetFilter then
                    AccSchedLine."Dimension 4 Totaling" := AnalysisViewFilter
                else
                    AccSchedLine."Dimension 4 Totaling" := '';
        end;
    end;

    local procedure InitAccSchedLine()
    begin
        AccSchedLine.SetFilter("Date Filter", DateFilter);
        case AccountSource of
            AccountSource::"G/L Account":
                begin
                    AccSchedLine."Totaling Type" := AccSchedLine."Totaling Type"::"Posting Accounts";
                    if GLBudgetName <> '' then
                        AccSchedLine.SetRange("G/L Budget Filter", GLBudgetName);
                end;
            AccountSource::"Cash Flow Account":
                begin
                    AccSchedLine."Totaling Type" := AccSchedLine."Totaling Type"::"Cash Flow Entry Accounts";
                    if CashFlowForecastNo <> '' then
                        AccSchedLine.SetRange("Cash Flow Forecast Filter", CashFlowForecastNo);
                end;
        end;
    end;

    local procedure TransferValues()
    var
        AnalysisView: Record "Analysis View";
        ColumnLayoutNameRec: Record "Column Layout Name";
    begin
        if AnalysisViewCode <> '' then
            if not AnalysisView.Get(AnalysisViewCode) then
                AnalysisViewCode := '';

        if AnalysisViewCode = '' then
            if AnalysisView.FindFirst() then
                AnalysisViewCode := AnalysisView.Code;

        AnalysisView.SetSkipConfirmationDialogue();
        if AnalysisViewCode <> '' then begin
            if AnalysisView."Dimension 1 Code" = '' then
                AnalysisView.Validate("Dimension 1 Code", GLSetup."Global Dimension 1 Code");
            if AnalysisView."Dimension 2 Code" = '' then
                AnalysisView.Validate("Dimension 2 Code", GLSetup."Global Dimension 2 Code");
            AnalysisView.Modify();

            GetAccountSource();
            if AccountSource = AccountSource::"G/L Account" then
                DimSelectionBuf.SetDimSelectionLevelGLAccAutoSet(3, REPORT::"Dimensions - Total", AnalysisViewCode, ColumnDim);
        end;

        if ColumnLayoutName <> '' then
            if not ColumnLayoutNameRec.Get(ColumnLayoutName) then
                ColumnLayoutName := '';

        if ColumnLayoutName = '' then
            if ColumnLayoutNameRec.FindFirst() then
                ColumnLayoutName := ColumnLayoutNameRec.Name;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillTempGLAccountOnBeforeGLAccFind(var GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnAfterDimValSetFilters(var DimensionValue: Record "Dimension Value")
    begin
    end;
}

