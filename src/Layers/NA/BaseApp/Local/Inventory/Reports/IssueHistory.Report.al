// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;

report 10140 "Issue History"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/IssueHistory.rdlc';
    Caption = 'Issue History';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", "Search Description", "Global Dimension 1 Filter", "Global Dimension 2 Filter", "Location Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(OnlyItemsWithIssues; OnlyItemsWithIssues)
            {
            }
            column(Item_TABLECAPTION__________ItemFilter; Item.TableCaption + ': ' + ItemFilter)
            {
            }
            column(STRSUBSTNO_Text000_DateRange_1__DateRange_2__1_; StrSubstNo(Text000, DateRange[1], DateRange[2] - 1))
            {
            }
            column(STRSUBSTNO_Text000_DateRange_2__DateRange_3__1_; StrSubstNo(Text000, DateRange[2], DateRange[3] - 1))
            {
            }
            column(STRSUBSTNO_Text000_DateRange_3__DateRange_4__1_; StrSubstNo(Text000, DateRange[3], DateRange[4] - 1))
            {
            }
            column(STRSUBSTNO_Text000_DateRange_4__DateRange_5__1_; StrSubstNo(Text000, DateRange[4], DateRange[5] - 1))
            {
            }
            column(STRSUBSTNO_Text000_DateRange_5__DateRange_6__1_; StrSubstNo(Text000, DateRange[5], DateRange[6] - 1))
            {
            }
            column(STRSUBSTNO_Text000_DateRange_6__DateRange_7__1_; StrSubstNo(Text000, DateRange[6], DateRange[7] - 1))
            {
            }
            column(Item__No__; "No.")
            {
            }
            column(Item_Description; Description)
            {
            }
            column(Item__Base_Unit_of_Measure_; "Base Unit of Measure")
            {
            }
            column(QuantityIssued_1_; QuantityIssued[1])
            {
                DecimalPlaces = 2 : 5;
            }
            column(QuantityIssued_2_; QuantityIssued[2])
            {
                DecimalPlaces = 2 : 5;
            }
            column(QuantityIssued_3_; QuantityIssued[3])
            {
                DecimalPlaces = 2 : 5;
            }
            column(QuantityIssued_4_; QuantityIssued[4])
            {
                DecimalPlaces = 2 : 5;
            }
            column(QuantityIssued_5_; QuantityIssued[5])
            {
                DecimalPlaces = 2 : 5;
            }
            column(QuantityIssued_6_; QuantityIssued[6])
            {
                DecimalPlaces = 2 : 5;
            }
            column(QuantityIssuedPRYR_1_; QuantityIssuedPRYR[1])
            {
                DecimalPlaces = 2 : 5;
            }
            column(QuantityIssuedPRYR_2_; QuantityIssuedPRYR[2])
            {
                DecimalPlaces = 2 : 5;
            }
            column(QuantityIssuedPRYR_3_; QuantityIssuedPRYR[3])
            {
                DecimalPlaces = 2 : 5;
            }
            column(QuantityIssuedPRYR_4_; QuantityIssuedPRYR[4])
            {
                DecimalPlaces = 2 : 5;
            }
            column(QuantityIssuedPRYR_5_; QuantityIssuedPRYR[5])
            {
                DecimalPlaces = 2 : 5;
            }
            column(QuantityIssuedPRYR_6_; QuantityIssuedPRYR[6])
            {
                DecimalPlaces = 2 : 5;
            }
            column(Issue_HistoryCaption; Issue_HistoryCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Only_items_with_issues_are_included_Caption; Only_items_with_issues_are_included_CaptionLbl)
            {
            }
            column(Item__No__Caption; FieldCaption("No."))
            {
            }
            column(Item_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Item__Base_Unit_of_Measure_Caption; FieldCaption("Base Unit of Measure"))
            {
            }
            column(Issued_Prior_Year_Caption; Issued_Prior_Year_CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                PrintLine := false;
                Clear(QuantityIssued);
                Clear(QuantityIssuedPRYR);
                for i := 1 to 6 do begin
                    SetRange("Date Filter", DateRange[i], DateRange[i + 1] - 1);
                    CalcFields("Negative Adjmt. (Qty.)", "Consumptions (Qty.)");
                    if ("Negative Adjmt. (Qty.)" <> 0) and ("Consumptions (Qty.)" <> 0) then begin
                        QuantityIssued[i] := "Negative Adjmt. (Qty.)" + "Consumptions (Qty.)";
                        PrintLine := true;
                        PriorYRMin := CalcDate('<-1Y>', DateRange[i]);
                        PriorYRMax := CalcDate('<-1Y>', DateRange[i + 1]);
                        SetRange("Date Filter", PriorYRMin, PriorYRMax - 1);
                        CalcFields("Negative Adjmt. (Qty.)", "Consumptions (Qty.)");
                        QuantityIssuedPRYR[i] := "Negative Adjmt. (Qty.)" + "Consumptions (Qty.)";
                    end;
                end;

                if not PrintLine and OnlyItemsWithIssues then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                for i := 2 to 7 do
                    DateRange[i] := CalcDate(TimeDivision, DateRange[i - 1]);
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
                    field("DateRange[1]"; DateRange[1])
                    {
                        Caption = 'Starting Date';
                    }
                    field(TimeDivision; TimeDivision)
                    {
                        Caption = 'Length of Period (1M,2W,29D)';
                        MultiLine = true;
                        ToolTip = 'Specifies the length of the each history period. For example, enter 30D to base history on 30-day intervals.';
                    }
                    field(OnlyItemsWithIssues; OnlyItemsWithIssues)
                    {
                        Caption = 'Only Items with Issues';
                        ToolTip = 'Specifies that you only want to see items having issues in the six calculated periods. If you leave this field blank, all items in inventory will be listed even if no issues have occurred.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if DateRange[1] = 0D then
                DateRange[1] := WorkDate();
            if Format(TimeDivision) = '' then
                Evaluate(TimeDivision, '<1M>');
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        ItemFilter := Item.GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        TimeDivision: DateFormula;
        DateRange: array[7] of Date;
        ItemFilter: Text;
        PriorYRMin: Date;
        PriorYRMax: Date;
        QuantityIssued: array[6] of Decimal;
        QuantityIssuedPRYR: array[6] of Decimal;
        i: Integer;
        OnlyItemsWithIssues: Boolean;
        PrintLine: Boolean;
        Text000: Label '%1 thru %2';
        Issue_HistoryCaptionLbl: Label 'Issue History';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Only_items_with_issues_are_included_CaptionLbl: Label 'Only items with issues are included.';
        Issued_Prior_Year_CaptionLbl: Label 'Issued Prior Year:';
}

