// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Reports;

using Microsoft.CostAccounting.Account;

report 1127 "Cost Acctg. Analysis"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CostAccounting/Reports/CostAcctgAnalysis.rdlc';
    ApplicationArea = CostAccounting;
    Caption = 'Cost Acctg. Analysis';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Cost Type"; "Cost Type")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Cost Classification", Type, "Date Filter";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FilterTxt; FilterTxt)
            {
            }
            column(Head7; Head[7])
            {
            }
            column(Head6; Head[6])
            {
            }
            column(Head5; Head[5])
            {
            }
            column(Head4; Head[4])
            {
            }
            column(Head3; Head[3])
            {
            }
            column(Head2; Head[2])
            {
            }
            column(Head1; Head[1])
            {
            }
            column(No_CostType; "No.")
            {
                IncludeCaption = true;
            }
            column(Name_CostType; PadStr('', Indentation * 2) + Name)
            {
            }
            column(Col1; Col[1])
            {
            }
            column(Col2; Col[2])
            {
            }
            column(Col4; Col[4])
            {
            }
            column(Col3; Col[3])
            {
            }
            column(Col7; Col[7])
            {
            }
            column(Col6; Col[6])
            {
            }
            column(Col5; Col[5])
            {
            }
            column(LineType; LineTypeInt)
            {
            }
            column(BlankLine; "Blank Line")
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(CAAnalysisCaption; CAAnalysisCaptionLbl)
            {
            }
            column(CostTypeCaption; CostTypeCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                AmtExists := false;

                for i := 1 to 10 do begin
                    SetFilter("Cost Center Filter", '%1', CostCenter[i].Code);
                    SetFilter("Cost Object Filter", '%1', CostObject[i].Code);
                    CalcFields("Net Change");
                    Col[i] := "Net Change";
                    if "Net Change" <> 0 then
                        AmtExists := true;
                end;

                if (Type = Type::"Cost Type") and SuppressWoAmt and (not AmtExists) then
                    CurrReport.Skip();

                if NewPage then begin
                    PageGroupNo := PageGroupNo + 1;
                    NewPage := false;
                end;
                NewPage := "New Page";

                LineTypeInt := Type.AsInteger();
            end;

            trigger OnPreDataItem()
            begin
                for i := 1 to 10 do
                    Head[i] := CostCenter[i].Code + CostObject[i].Code;

                PageGroupNo := 1;
                NewPage := false;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Cost Acctg. Analysis';
        AboutText = 'The **Cost Acctg. Analysis** report compares actual costs to budgeted or expected values to identify variances. Use it for analyzing cost performance by highlighting where actual spending deviates from budgeted figures, helping improve forecasting and financial control.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Column 1")
                    {
                        Caption = 'Column 1';
                        field(CostCenter1; CostCenter[1].Code)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Center';
                            TableRelation = "Cost Center";
                            ToolTip = 'Specifies the cost center to be included in the cost accounting analysis.';

                            trigger OnValidate()
                            begin
                                CostCenterTest(1);
                            end;
                        }
                        field(CostObject1; CostObject[1].Code)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Object';
                            TableRelation = "Cost Object";
                            ToolTip = 'Specifies the cost object relating to the applicable cost center.';

                            trigger OnValidate()
                            begin
                                CostObjectTest(1);
                            end;
                        }
                    }
                    group("Column 2")
                    {
                        Caption = 'Column 2';
                        field(CostCenter2; CostCenter[2].Code)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Center';
                            TableRelation = "Cost Center";
                            ToolTip = 'Specifies the cost center to be included in the cost accounting analysis.';

                            trigger OnValidate()
                            begin
                                CostCenterTest(2);
                            end;
                        }
                        field(CostObject2; CostObject[2].Code)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Object';
                            TableRelation = "Cost Object";
                            ToolTip = 'Specifies the cost object relating to the applicable cost center.';

                            trigger OnValidate()
                            begin
                                CostObjectTest(2);
                            end;
                        }
                    }
                    group("Column 3")
                    {
                        Caption = 'Column 3';
                        field(CostCenter3; CostCenter[3].Code)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Center';
                            TableRelation = "Cost Center";
                            ToolTip = 'Specifies the cost center to be included in the cost accounting analysis.';

                            trigger OnValidate()
                            begin
                                CostCenterTest(3);
                            end;
                        }
                        field(CostObject3; CostObject[3].Code)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Object';
                            TableRelation = "Cost Object";
                            ToolTip = 'Specifies the cost object relating to the applicable cost center.';

                            trigger OnValidate()
                            begin
                                CostObjectTest(3);
                            end;
                        }
                    }
                    group("Column 4")
                    {
                        Caption = 'Column 4';
                        field(CostCenter4; CostCenter[4].Code)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Center';
                            TableRelation = "Cost Center";
                            ToolTip = 'Specifies the cost center to be included in the cost accounting analysis.';

                            trigger OnValidate()
                            begin
                                CostCenterTest(4);
                            end;
                        }
                        field(CostObject4; CostObject[4].Code)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Object';
                            TableRelation = "Cost Object";
                            ToolTip = 'Specifies the cost object relating to the applicable cost center.';

                            trigger OnValidate()
                            begin
                                CostObjectTest(4);
                            end;
                        }
                    }
                    group("Column 5")
                    {
                        Caption = 'Column 5';
                        field(CostCenter5; CostCenter[5].Code)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Center';
                            TableRelation = "Cost Center";
                            ToolTip = 'Specifies the cost center to be included in the cost accounting analysis.';

                            trigger OnValidate()
                            begin
                                CostCenterTest(5);
                            end;
                        }
                        field(CostObject5; CostObject[5].Code)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Object';
                            TableRelation = "Cost Object";
                            ToolTip = 'Specifies the cost object relating to the applicable cost center.';

                            trigger OnValidate()
                            begin
                                CostObjectTest(5);
                            end;
                        }
                    }
                    group("Column 6")
                    {
                        Caption = 'Column 6';
                        field(CostCenter6; CostCenter[6].Code)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Center';
                            TableRelation = "Cost Center";
                            ToolTip = 'Specifies the cost center to be included in the cost accounting analysis.';

                            trigger OnValidate()
                            begin
                                CostCenterTest(6);
                            end;
                        }
                        field(CostObject6; CostObject[6].Code)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Object';
                            TableRelation = "Cost Object";
                            ToolTip = 'Specifies the cost object relating to the applicable cost center.';

                            trigger OnValidate()
                            begin
                                CostObjectTest(6);
                            end;
                        }
                    }
                    group("Column 7")
                    {
                        Caption = 'Column 7';
                        field(CostCenter7; CostCenter[7].Code)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Center';
                            TableRelation = "Cost Center";
                            ToolTip = 'Specifies the cost center to be included in the cost accounting analysis.';

                            trigger OnValidate()
                            begin
                                CostCenterTest(7);
                            end;
                        }
                        field(CostObject7; CostObject[7].Code)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Object';
                            TableRelation = "Cost Object";
                            ToolTip = 'Specifies the cost object relating to the applicable cost center.';

                            trigger OnValidate()
                            begin
                                CostObjectTest(7);
                            end;
                        }
                    }
                    field(SuppressCostTypesWithoutAmount; SuppressWoAmt)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Suppress cost types without amount';
                        ToolTip = 'Specifies that accounts that do not have an amount will not be printed.';
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
        for i := 1 to 10 do begin
            CostCenter[i].Init();
            CostObject[i].Init();
        end;
    end;

    trigger OnPreReport()
    begin
        if "Cost Type".GetFilters <> '' then
            FilterTxt := Text000 + ' ' + "Cost Type".GetFilters();
    end;

    var
        CostCenter: array[10] of Record "Cost Center";
        CostObject: array[10] of Record "Cost Object";
        FilterTxt: Text;
        Head: array[10] of Text[50];
        Col: array[10] of Decimal;
        i: Integer;
        AmtExists: Boolean;
        SuppressWoAmt: Boolean;
        PageGroupNo: Integer;
        NewPage: Boolean;
        LineTypeInt: Integer;

#pragma warning disable AA0074
        Text000: Label 'Filter:';
#pragma warning restore AA0074
        CAAnalysisCaptionLbl: Label 'Cost Acctg. Analysis';
        CostTypeCaptionLbl: Label 'Cost Type';
        PageCaptionLbl: Label 'Page';

    local procedure CostCenterTest(Col: Integer)
    begin
        if CostCenter[Col].Code <> '' then
            CostObject[Col].Code := '';
    end;

    local procedure CostObjectTest(Col: Integer)
    begin
        if CostObject[Col].Code <> '' then
            CostCenter[Col].Code := '';
    end;
}

