// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;

report 10146 "Item Turnover"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/ItemTurnover.rdlc';
    Caption = 'Item Turnover';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", "Search Description", "Location Filter", "Date Filter";
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
            column(Item_TABLECAPTION__________ItemFilter; Item.TableCaption + ': ' + ItemFilter)
            {
            }
            column(Item__No__; "No.")
            {
            }
            column(Item_Description; Description)
            {
            }
            column(EndingInventory; EndingInventory)
            {
                DecimalPlaces = 2 : 5;
            }
            column(AverageInventory; AverageInventory)
            {
                DecimalPlaces = 2 : 5;
            }
            column(Item__Sales__Qty___; "Sales (Qty.)")
            {
                DecimalPlaces = 2 : 5;
            }
            column(Item__Negative_Adjmt___Qty___; "Negative Adjmt. (Qty.)")
            {
                DecimalPlaces = 2 : 5;
            }
            column(NoOfTurns; NoOfTurns)
            {
                DecimalPlaces = 2 : 2;
            }
            column(EstAnnualTurns; EstAnnualTurns)
            {
                DecimalPlaces = 2 : 2;
            }
            column(Item_TurnoverCaption; Item_TurnoverCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(EndingInventoryCaption; EndingInventoryCaptionLbl)
            {
            }
            column(NoOfTurnsCaption; NoOfTurnsCaptionLbl)
            {
            }
            column(EstAnnualTurnsCaption; EstAnnualTurnsCaptionLbl)
            {
            }
            column(Item__No__Caption; FieldCaption("No."))
            {
            }
            column(Item_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(AverageInventoryCaption; AverageInventoryCaptionLbl)
            {
            }
            column(Item__Sales__Qty___Caption; FieldCaption("Sales (Qty.)"))
            {
            }
            column(Item__Negative_Adjmt___Qty___Caption; FieldCaption("Negative Adjmt. (Qty.)"))
            {
            }

            trigger OnAfterGetRecord()
            begin
                SetRange("Date Filter", BeginDate, EndDate);
                CalcFields(Inventory, "Sales (Qty.)", "Negative Adjmt. (Qty.)");
                /*Find Average Inventory amount*/
                DataPointDate := BeginDate - 1;
                SetRange("Date Filter", 0D, DataPointDate);
                CalcFields("Net Change");
                TotalInventory := "Net Change";
                NumDataPoints := 1;
                repeat
                    DataPointDate := CalcDate('<1W>', DataPointDate);
                    if DataPointDate > EndDate then
                        DataPointDate := EndDate;
                    SetRange("Date Filter", 0D, DataPointDate);
                    CalcFields("Net Change");
                    TotalInventory := TotalInventory + "Net Change";
                    NumDataPoints := NumDataPoints + 1;
                until DataPointDate = EndDate;
                /*Record Ending Inventory amount*/
                EndingInventory := "Net Change";

                AverageInventory := TotalInventory / NumDataPoints;
                if AverageInventory <> 0 then
                    NoOfTurns := ("Sales (Qty.)" + "Negative Adjmt. (Qty.)") / AverageInventory
                else
                    NoOfTurns := 0;

                EstAnnualTurns := NoOfTurns * (365.0 / (EndDate - BeginDate + 1));

            end;

            trigger OnPreDataItem()
            begin
                BeginDate := GetRangeMin("Date Filter");
                EndDate := GetRangeMax("Date Filter");
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

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        ItemFilter := Item.GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        BeginDate: Date;
        EndDate: Date;
        ItemFilter: Text;
        EndingInventory: Decimal;
        AverageInventory: Decimal;
        NoOfTurns: Decimal;
        EstAnnualTurns: Decimal;
        DataPointDate: Date;
        NumDataPoints: Integer;
        TotalInventory: Decimal;
        Item_TurnoverCaptionLbl: Label 'Item Turnover';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        EndingInventoryCaptionLbl: Label 'Quantity on Hand';
        NoOfTurnsCaptionLbl: Label 'Number of Turns';
        EstAnnualTurnsCaptionLbl: Label 'Estimated Annual Turns';
        AverageInventoryCaptionLbl: Label 'Average Inventory';
}

