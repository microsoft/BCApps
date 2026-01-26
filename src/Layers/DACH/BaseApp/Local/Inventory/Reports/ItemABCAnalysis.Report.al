// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;

report 11503 "Item ABC Analysis"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/ItemABCAnalysis.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Item ABC Analysis';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", "Inventory Posting Group", "Gen. Prod. Posting Group", "Date Filter", "Location Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(GetFilters; Text010 + GetFilters)
            {
            }
            column(ApctBpctCpctFormatted; Format(Apct) + ' / ' + Format(Bpct) + ' / ' + Format(Cpct))
            {
            }
            column(Col1Txt; Col1Txt)
            {
            }
            column(Col2Txt; Col2Txt)
            {
            }
            column(No_Item; "No.")
            {
            }
            column(Description_Item; Description)
            {
            }
            column(InvntPostingGroup_Item; "Inventory Posting Group")
            {
            }
            column(ABC; ABC)
            {
            }
            column(Pct; Pct)
            {
            }
            column(Col1Value; Col1Value)
            {
            }
            column(Col2Value; Col2Value)
            {
            }
            column(CumulatedCol2; Col2TotalStatistic)
            {
            }
            column(CumulatedPCT; PCTTotalStatistic)
            {
            }
            column(CumulatedCol1; Col1TotalStatistic)
            {
            }
            column(Col1TotalAllRec; Col1TotalAllRec)
            {
            }
            column(NoANoBNoC; NoA + NoB + NoC)
            {
            }
            column(V00; 0.0)
            {
            }
            column(NoC; NoC)
            {
            }
            column(ApctBpctCpct; Apct + Bpct + Cpct)
            {
            }
            column(Cpct; Cpct)
            {
            }
            column(BClimit; BClimit)
            {
            }
            column(BminAmt; BminAmt)
            {
            }
            column(NoB; NoB)
            {
            }
            column(Bpct; Bpct)
            {
            }
            column(ABlimit; ABlimit)
            {
            }
            column(AminAmt; AminAmt)
            {
            }
            column(NoA; NoA)
            {
            }
            column(Apct; Apct)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(ItemABCAnalysisCaption; ItemABCAnalysisCaptionLbl)
            {
            }
            column(ItemDescriptionCaption; FieldCaption(Description))
            {
            }
            column(ItemNoCaption; FieldCaption("No."))
            {
            }
            column(ABCCaption; ABCCaptionLbl)
            {
            }
            column(PercentageABCCaption; PercentageABCCaptionLbl)
            {
            }
            column(PctCaption; PctCaptionLbl)
            {
            }
            column(ItemInvntPostGroupCaption; ItemInvntPostGroupCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(BCaption; BCaptionLbl)
            {
            }
            column(CCaption; CCaptionLbl)
            {
            }
            column(ACaption; ACaptionLbl)
            {
            }
            column(fromCumValueCaption; fromCumValueCaptionLbl)
            {
            }
            column(fromSingleValueCaption; fromSingleValueCaptionLbl)
            {
            }
            column(NoCaption; NoCaptionLbl)
            {
            }
            column(ShareCaption; ShareCaptionLbl)
            {
            }
            column(StructureCaption; StructureCaptionLbl)
            {
            }
            column(RangeCaption; RangeCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                Buffer.SetRange("Item No.", "No.");
                Buffer.FindFirst();

                if (PrintZero = false) and (Buffer.Amount = 0) and (Buffer."Amount 2" = 0) then
                    CurrReport.Skip();

                Col1Value := Buffer.Amount;
                Col2Value := Buffer."Amount 2";

                case true of
                    Col1Value >= AminAmt:
                        begin
                            ABC := 'A';
                            NoA := NoA + 1;
                        end;
                    Col1Value >= BminAmt:
                        begin
                            ABC := 'B';
                            NoB := NoB + 1;
                        end;
                    else begin
                        ABC := 'C';
                        NoC := NoC + 1;
                    end;
                end;

                if not Aprint and (ABC = 'A') then
                    CurrReport.Skip();
                if not Bprint and (ABC = 'B') then
                    CurrReport.Skip();
                if not Cprint and (ABC = 'C') then
                    CurrReport.Skip();

                Col1TotalStatistic := Col1TotalStatistic + Col1Value;
                Col2TotalStatistic := Col2TotalStatistic + Col2Value;

                NoOfRecs := NoOfRecs + 1;
                if Col1TotalAllRec <> 0 then
                    Pct := Col1Value / Col1TotalAllRec * 100;

                PCTTotalStatistic := PCTTotalStatistic + Pct;
                OnAfterItemOnAfterGetRecord(Item, ABC);
            end;

            trigger OnPostDataItem()
            begin
                d.Close();
            end;

            trigger OnPreDataItem()
            begin
                d.Open(
                  Text003 +
                  Text004 +
                  Text005 +
                  Text006);
                d.Update(1, Format(Count));

                if FindSet() then
                    repeat
                        for i := 1 to 2 do
                            case Column[i] of
                                Column[i] ::Stock:
                                    begin
                                        CalcFields(Inventory);
                                        TmpAmt[i] := Inventory;
                                    end;
                                Column[i] ::Movement:
                                    begin
                                        CalcFields("Net Change");
                                        TmpAmt[i] := "Net Change";
                                    end;
                                Column[i] ::"Sale Qty":
                                    begin
                                        CalcFields("Sales (Qty.)");
                                        TmpAmt[i] := "Sales (Qty.)";
                                    end;
                                Column[i] ::"Purch. Qty":
                                    begin
                                        CalcFields("Purchases (Qty.)");
                                        TmpAmt[i] := "Purchases (Qty.)";
                                    end;
                                Column[i] ::"Qty in Purch":
                                    begin
                                        CalcFields("Qty. on Purch. Order");
                                        TmpAmt[i] := "Qty. on Purch. Order";
                                    end;
                                Column[i] ::"Qty in Sale":
                                    begin
                                        CalcFields("Qty. on Sales Order");
                                        TmpAmt[i] := "Qty. on Sales Order";
                                    end;
                                Column[i] ::"Max Order":
                                    TmpAmt[i] := "Maximum Inventory";
                                Column[i] ::"Min Order":
                                    TmpAmt[i] := "Reorder Point";
                                Column[i] ::"Sale LCY":
                                    begin
                                        CalcFields("Sales (LCY)");
                                        TmpAmt[i] := "Sales (LCY)";
                                    end;
                                Column[i] ::"Purch LCY":
                                    begin
                                        CalcFields("Purchases (LCY)");
                                        TmpAmt[i] := "Purchases (LCY)";
                                    end;
                                Column[i] ::"Sale Price":
                                    TmpAmt[i] := "Unit Price";
                                Column[i] ::Cost:
                                    TmpAmt[i] := "Unit Cost";
                                Column[i] ::"Purch Price":
                                    TmpAmt[i] := "Last Direct Cost";
                                Column[i] ::"Profit %":
                                    TmpAmt[i] := "Profit %";
                                Column[i] ::Weight:
                                    TmpAmt[i] := "Net Weight";
                                Column[i] ::"Bud Qty":
                                    TmpAmt[i] := "Budget Quantity";
                                Column[i] ::"Bud Amt.":
                                    TmpAmt[i] := "Budgeted Amount";
                            end;

                        Buffer.Init();
                        Buffer.Amount := TmpAmt[1];
                        Buffer."Amount 2" := TmpAmt[2];
                        Buffer."Item No." := "No.";
                        Buffer.Insert();

                        Col1TotalAllRec := Col1TotalAllRec + TmpAmt[1];
                        Col2TotalAllRecs := Col2TotalAllRecs + TmpAmt[2];

                        NoCalculated := NoCalculated + 1;
                        d.Update(2, Format(NoCalculated));
                        d.Update(3, Format("No."));
                    until Next() = 0;
                FindFirst();

                ABlimit := Col1TotalAllRec / 100 * (Bpct + Cpct);
                BClimit := Col1TotalAllRec / 100 * Cpct;

                if Buffer.FindSet() then
                    repeat
                        CumAmt := CumAmt + Buffer.Amount;
                        if (CumAmt > BClimit) and (BminAmt = 0) then
                            BminAmt := Buffer.Amount;
                        if (CumAmt > ABlimit) and (AminAmt = 0) then
                            AminAmt := Buffer.Amount;
                    until Buffer.Next() = 0;
                Clear(Col1Value);
                Clear(Col2Value);
                Clear(Pct);
                NoOfRecs := 0;
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
                    field(ValueInColumn1; Column[1])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Value in Column 1';
                        OptionCaption = 'Stock,Movement,Sale Qty,Purch. Qty,Qty in Purch,Qty in Sale,Max Order,Min Order,Sale LCY,Purch LCY,Sale Price,Cost,Purch Price,Profit %,Weight,Bud Qty,Bud Amt.,<blank>';
                        ToolTip = 'Specifies the key figure displayed in the main column. This is the basis for the ABC analysis.';
                    }
                    field("Column[2]"; Column[2])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Value in Column 2';
                        OptionCaption = 'Stock,Movement,Sale Qty,Purch. Qty,Qty in Purch,Qty in Sale,Max Order,Min Order,Sale LCY,Purch LCY,Sale Price,Cost,Purch Price,Profit %,Weight,Bud Qty,Bud Amt.,<blank>';
                        ToolTip = 'Specifies the key figure displayed in an additional column. Select <blank> if only one column is relevant. The second column is not sorted and serves as additional information.';
                    }
                    group("Ratio Cat. A/B/C")
                    {
                        Caption = 'Ratio Cat. A/B/C';
                        field(RatioCatA; Apct)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'A';
                            DecimalPlaces = 0 : 0;
                            MaxValue = 100;
                            MinValue = 0;
                            ToolTip = 'Specifies items with small volume and high value.';

                            trigger OnValidate()
                            begin
                                Cpct := 100 - Apct - Bpct;
                            end;
                        }
                        field(Bpct; Bpct)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'B';
                            DecimalPlaces = 0 : 0;
                            MaxValue = 100;
                            MinValue = 0;
                            ToolTip = 'Specifies items with the medium volume and medium value.';

                            trigger OnValidate()
                            begin
                                Cpct := 100 - Apct - Bpct;
                            end;
                        }
                        field(Cpct; Cpct)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'C';
                            DecimalPlaces = 0 : 0;
                            MaxValue = 100;
                            MinValue = 0;
                            ToolTip = 'Specifies items with high volume and small value.';

                            trigger OnValidate()
                            begin
                                Bpct := 100 - Apct - Cpct;
                            end;
                        }
                    }
                    field(ShowCategoryA; Aprint)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Category A';
                        ToolTip = 'Specifies that this category of items are shown. ';
                    }
                    field(Bprint; Bprint)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Category B';
                        ToolTip = 'Specifies that this category of items are shown. ';
                    }
                    field(Cprint; Cprint)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Category C';
                        ToolTip = 'Specifies that this category of items are shown. ';
                    }
                    field(PrintZero; PrintZero)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Lines with 0';
                        ToolTip = 'Specifies that lines with no valuation are included. These lines are often excluded from the analysis.';
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
        if Column[1] = Column[2] then
            Column[2] := Column[2] ::"<blank>";

        if Apct = 0 then begin
            Apct := 20;
            Bpct := 30;
            Cpct := 50;
            Aprint := true;
            Bprint := true;
            Cprint := true;
        end;
    end;

    trigger OnPreReport()
    begin
        Buffer.DeleteAll();

        if Column[1] = Column[2] then
            Error(SameColumnValuesErr);

        if Column[1] = Column[1] ::"<blank>" then
            Error(Text002);

        Col1Txt := SelectStr(Column[1] + 1, Text011);

        if Column[2] <> Column[2] ::"<blank>" then
            Col2Txt := SelectStr(Column[2] + 1, Text011);
    end;

    var
        SameColumnValuesErr: Label 'Column 1 and 2 must show different values. Select the option <blank> if only 1 column should be displayed.';
        Text002: Label 'Column 1 must no be empty because this is the base for the ranking.';
        Text003: Label 'Preparing Analysis\';
        Text004: Label 'Total in Analysis #1#########\';
        Text005: Label 'Calculated        #2#########\';
        Text006: Label 'Act. No.          #3#########';
        Text010: Label 'Filter: ';
        d: Dialog;
        i: Integer;
        Buffer: Record "Item Amount" temporary;
        NoOfRecs: Integer;
        NoCalculated: Integer;
        Apct: Decimal;
        Bpct: Decimal;
        Cpct: Decimal;
        ABlimit: Decimal;
        BClimit: Decimal;
        AminAmt: Decimal;
        BminAmt: Decimal;
        CumAmt: Decimal;
        Aprint: Boolean;
        Bprint: Boolean;
        Cprint: Boolean;
        NoA: Integer;
        NoB: Integer;
        NoC: Integer;
        PrintZero: Boolean;
        Column: array[2] of Option Stock,Movement,"Sale Qty","Purch. Qty","Qty in Purch","Qty in Sale","Max Order","Min Order","Sale LCY","Purch LCY","Sale Price",Cost,"Purch Price","Profit %",Weight,"Bud Qty","Bud Amt.","<blank>";
        TmpAmt: array[2] of Decimal;
        Col1Txt: Text[30];
        Col2Txt: Text[30];
        Col1TotalAllRec: Decimal;
        Col2TotalAllRecs: Decimal;
        Col1TotalStatistic: Decimal;
        Col2TotalStatistic: Decimal;
        Col1Value: Decimal;
        Col2Value: Decimal;
        Pct: Decimal;
        Text011: Label 'Stock,Movement,Sale Qty,Purch. Qty,Qty in Purch,Qty in Sale,Max Order,Min Order,Sale LCY,Purch LCY,Sale Price,Cost,Purch Price,Profit %,Weight,Bud Qty,Bud Amt.,<blank>';
        PCTTotalStatistic: Decimal;
        PageNoCaptionLbl: Label 'Page';
        ItemABCAnalysisCaptionLbl: Label 'Item ABC Analysis';
        ABCCaptionLbl: Label 'A/B/C';
        PercentageABCCaptionLbl: Label 'Percentage A/B/C';
        PctCaptionLbl: Label '%';
        ItemInvntPostGroupCaptionLbl: Label 'Post Gr.';
        TotalCaptionLbl: Label 'Total';
        BCaptionLbl: Label 'B';
        CCaptionLbl: Label 'C';
        ACaptionLbl: Label 'A';
        fromCumValueCaptionLbl: Label 'From Cum. Value', Comment = 'From Cumulative Value.';
        fromSingleValueCaptionLbl: Label 'From Single Value';
        NoCaptionLbl: Label 'No';
        ShareCaptionLbl: Label 'Share';
        StructureCaptionLbl: Label 'Structure';
        RangeCaptionLbl: Label 'Range';

    protected var
        ABC: Text[1];

    [IntegrationEvent(true, false)]
    local procedure OnAfterItemOnAfterGetRecord(var Item: Record Item; ABC: Text[1])
    begin
    end;
}

