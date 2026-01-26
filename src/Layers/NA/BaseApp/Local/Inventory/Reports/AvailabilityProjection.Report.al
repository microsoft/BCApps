// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

report 10130 "Availability Projection"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/AvailabilityProjection.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Availability Projection';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", "Search Description", "Inventory Posting Group", "Vendor No.", "Location Filter";
            column(Title; Title)
            {
            }
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
            column(STRSUBSTNO_Text007_IncludeMfg_; StrSubstNo(Text007, IncludeMfg))
            {
            }
            column(IncludeMfg; IncludeMfg)
            {
            }
            column(Item_TABLECAPTION__________ItemFilter; Item.TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(FORMAT_PeriodStartingDate_2___________Text005_________FORMAT_PeriodStartingDate_3__1_; Format(PeriodStartingDate[2], 0, '<Month,2>/<Day,2>/<Year4>') + ' ' + Text005 + ' ' + Format(PeriodStartingDate[3] - 1, 0, '<Month,2>/<Day,2>/<Year4>'))
            {
            }
            column(FORMAT_PeriodStartingDate_3___________Text005_________FORMAT_PeriodStartingDate_4__1_; Format(PeriodStartingDate[3], 0, '<Month,2>/<Day,2>/<Year4>') + ' ' + Text005 + ' ' + Format(PeriodStartingDate[4] - 1, 0, '<Month,2>/<Day,2>/<Year4>'))
            {
            }
            column(FORMAT_PeriodStartingDate_4___________Text005_________FORMAT_PeriodStartingDate_5__1_; Format(PeriodStartingDate[4], 0, '<Month,2>/<Day,2>/<Year4>') + ' ' + Text005 + ' ' + Format(PeriodStartingDate[5] - 1, 0, '<Month,2>/<Day,2>/<Year4>'))
            {
            }
            column(FORMAT_PeriodStartingDate_5___________Text005_________FORMAT_PeriodStartingDate_6__1_; Format(PeriodStartingDate[5], 0, '<Month,2>/<Day,2>/<Year4>') + ' ' + Text005 + ' ' + Format(PeriodStartingDate[6] - 1, 0, '<Month,2>/<Day,2>/<Year4>'))
            {
            }
            column(FORMAT_PeriodStartingDate_6___________Text005_________FORMAT_PeriodStartingDate_7__1_; Format(PeriodStartingDate[6], 0, '<Month,2>/<Day,2>/<Year4>') + ' ' + Text005 + ' ' + Format(PeriodStartingDate[7] - 1, 0, '<Month,2>/<Day,2>/<Year4>'))
            {
            }
            column(Text003_________FORMAT_PeriodStartingDate_2__; Text003 + ' ' + Format(PeriodStartingDate[2], 0, '<Month,2>/<Day,2>/<Year4>'))
            {
            }
            column(Text004_________FORMAT_PeriodStartingDate_7__1_; Text004 + ' ' + Format(PeriodStartingDate[7] - 1, 0, '<Month,2>/<Day,2>/<Year4>'))
            {
            }
            column(Item__No__; "No.")
            {
            }
            column(Item_Description; Description)
            {
            }
            column(Item__Lead_Time_Calculation_; "Lead Time Calculation")
            {
            }
            column(OnHand_1_; OnHand[1])
            {
                DecimalPlaces = 0 : 5;
            }
            column(OnHand_2_; OnHand[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(OnHand_3_; OnHand[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(OnHand_4_; OnHand[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(OnHand_5_; OnHand[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(OnHand_6_; OnHand[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(OnHand_7_; OnHand[7])
            {
                DecimalPlaces = 0 : 5;
            }
            column(NoVariant; NoVariant)
            {
            }
            column(QtySold_2_; -QtySold[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtySold_3_; -QtySold[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtySold_4_; -QtySold[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtySold_5_; -QtySold[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtySold_6_; -QtySold[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtySold_7_; -QtySold[7])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PrintSales; PrintSales)
            {
            }
            column(QtyPurchased_2_; QtyPurchased[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyPurchased_3_; QtyPurchased[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyPurchased_4_; QtyPurchased[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyPurchased_5_; QtyPurchased[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyPurchased_6_; QtyPurchased[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyPurchased_7_; QtyPurchased[7])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PrintPurch; PrintPurch)
            {
            }
            column(QtyAdjusted_2_; QtyAdjusted[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyAdjusted_3_; QtyAdjusted[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyAdjusted_4_; QtyAdjusted[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyAdjusted_5_; QtyAdjusted[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyAdjusted_6_; QtyAdjusted[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyAdjusted_7_; QtyAdjusted[7])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PrintAdj; PrintAdj)
            {
            }
            column(QtyTransferred_2_; QtyTransferred[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyTransferred_3_; QtyTransferred[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyTransferred_4_; QtyTransferred[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyTransferred_5_; QtyTransferred[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyTransferred_6_; QtyTransferred[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyTransferred_7_; QtyTransferred[7])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PrintTrans; PrintTrans)
            {
            }
            column(QtyOutput_2_; QtyOutput[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOutput_3_; QtyOutput[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOutput_4_; QtyOutput[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOutput_5_; QtyOutput[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOutput_6_; QtyOutput[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOutput_7_; QtyOutput[7])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PrintOutput; PrintOutput)
            {
            }
            column(QtyConsumed_2_; -QtyConsumed[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyConsumed_3_; -QtyConsumed[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyConsumed_4_; -QtyConsumed[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyConsumed_5_; -QtyConsumed[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyConsumed_6_; -QtyConsumed[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyConsumed_7_; -QtyConsumed[7])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PrintCons; PrintCons)
            {
            }
            column(QtySchedOutput_2_; QtySchedOutput[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtySchedOutput_3_; QtySchedOutput[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtySchedOutput_4_; QtySchedOutput[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtySchedOutput_5_; QtySchedOutput[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtySchedOutput_6_; QtySchedOutput[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtySchedOutput_7_; QtySchedOutput[7])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtySchedOutput_1_; QtySchedOutput[1])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PrintSchedOutput; PrintSchedOutput)
            {
            }
            column(QtySchedConsumption_2_; -QtySchedConsumption[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtySchedConsumption_3_; -QtySchedConsumption[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtySchedConsumption_4_; -QtySchedConsumption[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtySchedConsumption_5_; -QtySchedConsumption[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtySchedConsumption_6_; -QtySchedConsumption[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtySchedConsumption_7_; -QtySchedConsumption[7])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtySchedConsumption_1_; -QtySchedConsumption[1])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PrintSchedCons; PrintSchedCons)
            {
            }
            column(QtyOnSalesOrders_1_; -QtyOnSalesOrders[1])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnSalesOrders_2_; -QtyOnSalesOrders[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnSalesOrders_3_; -QtyOnSalesOrders[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnSalesOrders_4_; -QtyOnSalesOrders[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnSalesOrders_5_; -QtyOnSalesOrders[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnSalesOrders_6_; -QtyOnSalesOrders[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnSalesOrders_7_; -QtyOnSalesOrders[7])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnPurchOrders_1_; QtyOnPurchOrders[1])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnPurchOrders_2_; QtyOnPurchOrders[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnPurchOrders_3_; QtyOnPurchOrders[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnPurchOrders_4_; QtyOnPurchOrders[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnPurchOrders_5_; QtyOnPurchOrders[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnPurchOrders_6_; QtyOnPurchOrders[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnPurchOrders_7_; QtyOnPurchOrders[7])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyAvailable_1_; QtyAvailable[1])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyAvailable_2_; QtyAvailable[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyAvailable_3_; QtyAvailable[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyAvailable_4_; QtyAvailable[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyAvailable_5_; QtyAvailable[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyAvailable_6_; QtyAvailable[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyAvailable_7_; QtyAvailable[7])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnServiceOrders_1_; -QtyOnServiceOrders[1])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnServiceOrders_2_; -QtyOnServiceOrders[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnServiceOrders_3_; -QtyOnServiceOrders[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnServiceOrders_4_; -QtyOnServiceOrders[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnServiceOrders_5_; -QtyOnServiceOrders[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnServiceOrders_6_; -QtyOnServiceOrders[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnServiceOrders_7_; -QtyOnServiceOrders[7])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PrintFooter; PrintFooter)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Item__No__Caption; FieldCaption("No."))
            {
            }
            column(Item_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Item__Lead_Time_Calculation_Caption; FieldCaption("Lead Time Calculation"))
            {
            }
            column(Quantity_on_HandCaption; Quantity_on_HandCaptionLbl)
            {
            }
            column(Quantity_ShippedCaption; Quantity_ShippedCaptionLbl)
            {
            }
            column(Quantity_ReceivedCaption; Quantity_ReceivedCaptionLbl)
            {
            }
            column(Quantity_AdjustedCaption; Quantity_AdjustedCaptionLbl)
            {
            }
            column(Quantity_TransferredCaption; Quantity_TransferredCaptionLbl)
            {
            }
            column(Quantity_OutputCaption; Quantity_OutputCaptionLbl)
            {
            }
            column(Quantity_ConsumedCaption; Quantity_ConsumedCaptionLbl)
            {
            }
            column(Scheduled_Production_OutputCaption; Scheduled_Production_OutputCaptionLbl)
            {
            }
            column(Scheduled_Production_NeedsCaption; Scheduled_Production_NeedsCaptionLbl)
            {
            }
            column(Quantity_on_Sales_OrdersCaption; Quantity_on_Sales_OrdersCaptionLbl)
            {
            }
            column(Quantity_on_Purchase_OrdersCaption; Quantity_on_Purchase_OrdersCaptionLbl)
            {
            }
            column(Quantity_AvailableCaption; Quantity_AvailableCaptionLbl)
            {
            }
            column(Quantity_on_Service_OrdersCaption; Quantity_on_Service_OrdersCaptionLbl)
            {
            }
            column(There_are_actual_quantities_sold_or_purchased_on_this_page__which_should_not_normally_happen_in_a_projection_Caption; There_are_actual_quantities_sold_or_purchased_on_this_page__which_should_not_normally_happen_in_a_projection_CaptionLbl)
            {
            }
            dataitem("Item Variant"; "Item Variant")
            {
                DataItemLink = "Item No." = field("No.");
                DataItemTableView = sorting("Item No.", Code);
                column(OnHand_7__Control1; TOnHand[7])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(OnHand_6__Control2; TOnHand[6])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(OnHand_5__Control3; TOnHand[5])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(OnHand_4__Control4; TOnHand[4])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(OnHand_3__Control5; TOnHand[3])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(OnHand_2__Control6; TOnHand[2])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(OnHand_1__Control7; TOnHand[1])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(Item_Variant__Item_No__; "Item No.")
                {
                }
                column(Item_Description_Control17; Item.Description)
                {
                }
                column(Item__Lead_Time_Calculation__Control18; Item."Lead Time Calculation")
                {
                }
                column(Text006__________Code; Text006 + '  ' + Code)
                {
                }
                column(Item_Variant_Description; Description)
                {
                }
                column(QtySold_2__Control21; -TQtySold[2])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtySold_3__Control83; -TQtySold[3])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtySold_4__Control84; -TQtySold[4])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtySold_5__Control85; -TQtySold[5])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtySold_6__Control86; -TQtySold[6])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtySold_7__Control87; -TQtySold[7])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(TPrintSales; TPrintSales)
                {
                }
                column(QtyPurchased_2__Control89; TQtyPurchased[2])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyPurchased_3__Control90; TQtyPurchased[3])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyPurchased_4__Control91; TQtyPurchased[4])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyPurchased_5__Control92; TQtyPurchased[5])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyPurchased_6__Control93; TQtyPurchased[6])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyPurchased_7__Control94; TQtyPurchased[7])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(TPrintPurch; TPrintPurch)
                {
                }
                column(QtyAdjusted_2__Control96; TQtyAdjusted[2])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyAdjusted_3__Control97; TQtyAdjusted[3])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyAdjusted_4__Control98; TQtyAdjusted[4])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyAdjusted_5__Control99; TQtyAdjusted[5])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyAdjusted_6__Control100; TQtyAdjusted[6])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyAdjusted_7__Control101; TQtyAdjusted[7])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(TPrintAdj; TPrintAdj)
                {
                }
                column(QtyTransferred_2__Control214; TQtyTransferred[2])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyTransferred_3__Control215; TQtyTransferred[3])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyTransferred_4__Control216; TQtyTransferred[4])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyTransferred_5__Control217; TQtyTransferred[5])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyTransferred_6__Control218; TQtyTransferred[6])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyTransferred_7__Control219; TQtyTransferred[7])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(TPrintTrans; TPrintTrans)
                {
                }
                column(QtyOutput_2__Control207; TQtyOutput[2])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOutput_3__Control208; TQtyOutput[3])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOutput_4__Control209; TQtyOutput[4])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOutput_5__Control210; TQtyOutput[5])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOutput_6__Control211; TQtyOutput[6])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOutput_7__Control212; TQtyOutput[7])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(TPrintOutput; TPrintOutput)
                {
                }
                column(QtyConsumed_2__Control200; -TQtyConsumed[2])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyConsumed_3__Control201; -TQtyConsumed[3])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyConsumed_4__Control202; -TQtyConsumed[4])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyConsumed_5__Control203; -TQtyConsumed[5])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyConsumed_6__Control204; -TQtyConsumed[6])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyConsumed_7__Control205; -TQtyConsumed[7])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(TPrintCons; TPrintCons)
                {
                }
                column(QtySchedOutput_1__Control192; TQtySchedOutput[1])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtySchedOutput_2__Control193; TQtySchedOutput[2])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtySchedOutput_3__Control194; TQtySchedOutput[3])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtySchedOutput_4__Control195; TQtySchedOutput[4])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtySchedOutput_5__Control196; TQtySchedOutput[5])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtySchedOutput_6__Control197; TQtySchedOutput[6])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtySchedOutput_7__Control198; TQtySchedOutput[7])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(TPrintSchedOutput; TPrintSchedOutput)
                {
                }
                column(QtySchedConsumption_1__Control184; -TQtySchedConsumption[1])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtySchedConsumption_2__Control185; -TQtySchedConsumption[2])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtySchedConsumption_3__Control186; -TQtySchedConsumption[3])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtySchedConsumption_4__Control187; -TQtySchedConsumption[4])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtySchedConsumption_5__Control188; -TQtySchedConsumption[5])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtySchedConsumption_6__Control189; -TQtySchedConsumption[6])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtySchedConsumption_7__Control190; -TQtySchedConsumption[7])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(TPrintSchedCons; TPrintSchedCons)
                {
                }
                column(QtyOnSalesOrders_1__Control103; -TQtyOnSalesOrders[1])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOnSalesOrders_2__Control104; -TQtyOnSalesOrders[2])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOnSalesOrders_3__Control105; -TQtyOnSalesOrders[3])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOnPurchOrders_1__Control106; TQtyOnPurchOrders[1])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOnPurchOrders_2__Control107; TQtyOnPurchOrders[2])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOnPurchOrders_3__Control108; TQtyOnPurchOrders[3])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOnSalesOrders_4__Control110; -TQtyOnSalesOrders[4])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOnPurchOrders_4__Control111; TQtyOnPurchOrders[4])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOnSalesOrders_5__Control112; -TQtyOnSalesOrders[5])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOnPurchOrders_5__Control113; TQtyOnPurchOrders[5])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOnSalesOrders_6__Control114; -TQtyOnSalesOrders[6])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOnPurchOrders_6__Control115; TQtyOnPurchOrders[6])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOnSalesOrders_7__Control116; -TQtyOnSalesOrders[7])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOnPurchOrders_7__Control117; TQtyOnPurchOrders[7])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyAvailable_1__Control118; TQtyAvailable[1])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyAvailable_2__Control119; TQtyAvailable[2])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyAvailable_3__Control120; TQtyAvailable[3])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyAvailable_4__Control121; TQtyAvailable[4])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyAvailable_5__Control122; TQtyAvailable[5])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyAvailable_6__Control123; TQtyAvailable[6])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyAvailable_7__Control124; TQtyAvailable[7])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOnServiceOrders_1__Control176; -TQtyOnServiceOrders[1])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOnServiceOrders_2__Control177; -TQtyOnServiceOrders[2])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOnServiceOrders_3__Control178; -TQtyOnServiceOrders[3])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOnServiceOrders_4__Control179; -TQtyOnServiceOrders[4])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOnServiceOrders_5__Control180; -TQtyOnServiceOrders[5])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOnServiceOrders_6__Control181; -TQtyOnServiceOrders[6])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(QtyOnServiceOrders_7__Control182; -TQtyOnServiceOrders[7])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(Item_Variant_Code; Code)
                {
                }
                column(Quantity_on_HandCaption_Control14; Quantity_on_HandCaption_Control14Lbl)
                {
                }
                column(Item__Lead_Time_Calculation__Control18Caption; Item__Lead_Time_Calculation__Control18CaptionLbl)
                {
                }
                column(Quantity_ShippedCaption_Control20; Quantity_ShippedCaption_Control20Lbl)
                {
                }
                column(Quantity_ReceivedCaption_Control88; Quantity_ReceivedCaption_Control88Lbl)
                {
                }
                column(Quantity_AdjustedCaption_Control95; Quantity_AdjustedCaption_Control95Lbl)
                {
                }
                column(Quantity_TransferredCaption_Control213; Quantity_TransferredCaption_Control213Lbl)
                {
                }
                column(Quantity_OutputCaption_Control206; Quantity_OutputCaption_Control206Lbl)
                {
                }
                column(Quantity_ConsumedCaption_Control199; Quantity_ConsumedCaption_Control199Lbl)
                {
                }
                column(Scheduled_Production_OutputCaption_Control191; Scheduled_Production_OutputCaption_Control191Lbl)
                {
                }
                column(Scheduled_Production_NeedsCaption_Control183; Scheduled_Production_NeedsCaption_Control183Lbl)
                {
                }
                column(Quantity_on_Sales_OrdersCaption_Control102; Quantity_on_Sales_OrdersCaption_Control102Lbl)
                {
                }
                column(Quantity_on_Purchase_OrdersCaption_Control109; Quantity_on_Purchase_OrdersCaption_Control109Lbl)
                {
                }
                column(Quantity_AvailableCaption_Control125; Quantity_AvailableCaption_Control125Lbl)
                {
                }
                column(Quantity_on_Service_OrdersCaption_Control175; Quantity_on_Service_OrdersCaption_Control175Lbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    TPrintSales := false;
                    TPrintPurch := false;
                    TPrintAdj := false;
                    TPrintTrans := false;
                    TPrintOutput := false;
                    TPrintCons := false;
                    TPrintSchedOutput := false;
                    TPrintSchedCons := false;
                    Item.SetRange("Variant Filter", Code);
                    ItemLedgerEntry.Reset();
                    ItemLedgerEntry.SetCurrentKey("Item No.", "Entry Type", "Variant Code", "Drop Shipment",
                      "Location Code", "Posting Date");
                    for i := 1 to 7 do begin
                        if i = 1 then begin
                            ItemLedgerEntry.SetRange("Item No.", Item."No.");
                            ItemLedgerEntry.SetRange("Variant Code", Code);
                            Item.CopyFilter("Global Dimension 1 Filter", ItemLedgerEntry."Global Dimension 1 Code");
                            Item.CopyFilter("Global Dimension 2 Filter", ItemLedgerEntry."Global Dimension 2 Code");
                            Item.CopyFilter("Location Filter", ItemLedgerEntry."Location Code");
                            ItemLedgerEntry.SetRange("Posting Date", 0D, PeriodStartingDate[2] - 1);
                            ItemLedgerEntry.CalcSums(Quantity);
                            TOnHand[1] := ItemLedgerEntry.Quantity;
                        end else begin
                            ItemLedgerEntry.SetRange("Posting Date", PeriodStartingDate[i], PeriodStartingDate[i + 1] - 1);
                            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
                            ItemLedgerEntry.CalcSums(Quantity);
                            Item."Sales (Qty.)" := -ItemLedgerEntry.Quantity;
                            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
                            ItemLedgerEntry.CalcSums(Quantity);
                            Item."Purchases (Qty.)" := ItemLedgerEntry.Quantity;
                            TOnHand[i] := TQtyAvailable[i - 1];
                        end;
                        Item.SetRange("Date Filter", PeriodStartingDate[i], PeriodStartingDate[i + 1] - 1);
                        Item.CalcFields(
                          "Qty. on Sales Order", "Qty. on Purch. Order",
                          "Positive Adjmt. (Qty.)", "Negative Adjmt. (Qty.)",
                          "Transferred (Qty.)", "Consumptions (Qty.)", "Outputs (Qty.)",
                          "Rel. Scheduled Receipt (Qty.)", "Rel. Scheduled Need (Qty.)",
                          "Scheduled Receipt (Qty.)", "Qty. on Component Lines");
                        TQtyOnSalesOrders[i] := Item."Qty. on Sales Order";
                        TQtyOnPurchOrders[i] := Item."Qty. on Purch. Order";
                        TQtyOnServiceOrders[i] := Item.CalcQtyOnServiceOrder();
                        case IncludeMfg of
                            IncludeMfg::"Do not include":
                                begin
                                    TQtySchedOutput[i] := 0;
                                    TQtySchedConsumption[i] := 0;
                                end;
                            IncludeMfg::"Include released orders only":
                                begin
                                    TQtySchedOutput[i] := Item."Rel. Scheduled Receipt (Qty.)";
                                    TQtySchedConsumption[i] := Item."Rel. Scheduled Need (Qty.)";
                                end;
                            IncludeMfg::"Include planned and released orders":
                                begin
                                    TQtySchedOutput[i] := Item."Scheduled Receipt (Qty.)";
                                    TQtySchedConsumption[i] := Item."Qty. on Component Lines";
                                end;
                        end;
                        if i = 1 then begin
                            TQtySold[1] := 0;
                            TQtyPurchased[1] := 0;
                            TQtyAdjusted[1] := 0;
                            TQtyTransferred[1] := 0;
                            TQtyConsumed[1] := 0;
                            TQtyOutput[1] := 0;
                            TQtyAvailable[1] :=
                              TOnHand[1] + TQtyOnPurchOrders[1] - TQtyOnSalesOrders[1] - TQtyOnServiceOrders[i] +
                              TQtySchedOutput[i] - TQtySchedConsumption[i];
                        end else begin
                            TQtySold[i] := Item."Sales (Qty.)";
                            TQtyPurchased[i] := Item."Purchases (Qty.)";
                            TQtyAdjusted[i] := Item."Positive Adjmt. (Qty.)" - Item."Negative Adjmt. (Qty.)";
                            TQtyTransferred[i] := Item."Transferred (Qty.)";
                            TQtyConsumed[i] := Item."Consumptions (Qty.)";
                            TQtyOutput[i] := Item."Outputs (Qty.)";
                            TQtyAvailable[i] :=
                              TOnHand[i] + TQtyOnPurchOrders[i] - TQtyOnSalesOrders[i] - TQtyOnServiceOrders[i] +
                              TQtyPurchased[i] - TQtySold[i] + TQtyAdjusted[i] + TQtyTransferred[i] +
                              TQtyOutput[i] - TQtyConsumed[i] + TQtySchedOutput[i] - TQtySchedConsumption[i];
                            if TQtySold[i] <> 0 then begin
                                TPrintSales := true;
                                PrintFooter := true;
                            end;
                            if TQtyPurchased[i] <> 0 then begin
                                TPrintPurch := true;
                                PrintFooter := true;
                            end;
                            if TQtyAdjusted[i] <> 0 then begin
                                TPrintAdj := true;
                                PrintFooter := true;
                            end;
                            if TQtyTransferred[i] <> 0 then begin
                                TPrintTrans := true;
                                PrintFooter := true;
                            end;
                            if TQtyConsumed[i] <> 0 then begin
                                TPrintCons := true;
                                PrintFooter := true;
                            end;
                            if TQtyOutput[i] <> 0 then begin
                                TPrintOutput := true;
                                PrintFooter := true;
                            end;
                            if TQtySchedOutput[i] <> 0 then
                                TPrintSchedOutput := true;
                            if TQtySchedConsumption[i] <> 0 then
                                TPrintSchedCons := true;
                        end;
                    end;
                    Item.SetRange("Date Filter");
                end;

                trigger OnPreDataItem()
                begin
                    if not BreakdownByVariant then
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                PrintSales := false;
                PrintPurch := false;
                PrintAdj := false;
                PrintTrans := false;
                PrintOutput := false;
                PrintCons := false;
                PrintSchedOutput := false;
                PrintSchedCons := false;
                if BreakdownByVariant then begin
                    Item.SetRange("Variant Filter", '');
                    NoVariant := Text002;
                end;
                ItemLedgerEntry.Reset();
                ItemLedgerEntry.SetCurrentKey("Item No.", "Entry Type", "Variant Code", "Drop Shipment",
                  "Location Code", "Posting Date");
                for i := 1 to 7 do begin
                    if i = 1 then begin
                        ItemLedgerEntry.SetRange("Item No.", "No.");
                        if BreakdownByVariant then
                            ItemLedgerEntry.SetRange("Variant Code", '');
                        CopyFilter("Global Dimension 1 Filter", ItemLedgerEntry."Global Dimension 1 Code");
                        CopyFilter("Global Dimension 2 Filter", ItemLedgerEntry."Global Dimension 2 Code");
                        CopyFilter("Location Filter", ItemLedgerEntry."Location Code");
                        ItemLedgerEntry.SetRange("Posting Date", 0D, PeriodStartingDate[2] - 1);
                        ItemLedgerEntry.CalcSums(Quantity);
                        OnHand[1] := ItemLedgerEntry.Quantity;
                    end else begin
                        ItemLedgerEntry.SetRange("Posting Date", PeriodStartingDate[i], PeriodStartingDate[i + 1] - 1);
                        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
                        ItemLedgerEntry.CalcSums(Quantity);
                        "Sales (Qty.)" := -ItemLedgerEntry.Quantity;
                        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
                        ItemLedgerEntry.CalcSums(Quantity);
                        "Purchases (Qty.)" := ItemLedgerEntry.Quantity;
                        OnHand[i] := QtyAvailable[i - 1];
                    end;
                    SetRange("Date Filter", PeriodStartingDate[i], PeriodStartingDate[i + 1] - 1);
                    CalcFields(
                      "Qty. on Sales Order", "Qty. on Purch. Order",
                      "Positive Adjmt. (Qty.)", "Negative Adjmt. (Qty.)",
                      "Transferred (Qty.)", "Consumptions (Qty.)", "Outputs (Qty.)",
                      "Rel. Scheduled Receipt (Qty.)", "Rel. Scheduled Need (Qty.)",
                      "Scheduled Receipt (Qty.)", "Qty. on Component Lines");
                    QtyOnSalesOrders[i] := "Qty. on Sales Order";
                    QtyOnPurchOrders[i] := "Qty. on Purch. Order";
                    QtyOnServiceOrders[i] := CalcQtyOnServiceOrder();
                    case IncludeMfg of
                        IncludeMfg::"Do not include":
                            begin
                                QtySchedOutput[i] := 0;
                                QtySchedConsumption[i] := 0;
                            end;
                        IncludeMfg::"Include released orders only":
                            begin
                                QtySchedOutput[i] := "Rel. Scheduled Receipt (Qty.)";
                                QtySchedConsumption[i] := "Rel. Scheduled Need (Qty.)";
                            end;
                        IncludeMfg::"Include planned and released orders":
                            begin
                                QtySchedOutput[i] := "Scheduled Receipt (Qty.)";
                                QtySchedConsumption[i] := "Qty. on Component Lines";
                            end;
                    end;
                    if i = 1 then begin
                        QtySold[1] := 0;
                        QtyPurchased[1] := 0;
                        QtyAdjusted[1] := 0;
                        QtyTransferred[1] := 0;
                        QtyConsumed[1] := 0;
                        QtyOutput[1] := 0;
                        QtyAvailable[1] :=
                          OnHand[1] + QtyOnPurchOrders[1] - QtyOnSalesOrders[1] - QtyOnServiceOrders[i] +
                          QtySchedOutput[i] - QtySchedConsumption[i];
                    end else begin
                        QtySold[i] := "Sales (Qty.)";
                        QtyPurchased[i] := "Purchases (Qty.)";
                        QtyAdjusted[i] := "Positive Adjmt. (Qty.)" - "Negative Adjmt. (Qty.)";
                        QtyTransferred[i] := "Transferred (Qty.)";
                        QtyConsumed[i] := "Consumptions (Qty.)";
                        QtyOutput[i] := "Outputs (Qty.)";
                        QtyAvailable[i] :=
                          OnHand[i] + QtyOnPurchOrders[i] - QtyOnSalesOrders[i] - QtyOnServiceOrders[i] +
                          QtyPurchased[i] - QtySold[i] + QtyAdjusted[i] + QtyTransferred[i] +
                          QtyOutput[i] - QtyConsumed[i] + QtySchedOutput[i] - QtySchedConsumption[i];
                        if QtySold[i] <> 0 then begin
                            PrintSales := true;
                            PrintFooter := true;
                        end;
                        if QtyPurchased[i] <> 0 then begin
                            PrintPurch := true;
                            PrintFooter := true;
                        end;
                        if QtyAdjusted[i] <> 0 then begin
                            PrintAdj := true;
                            PrintFooter := true;
                        end;
                        if QtyTransferred[i] <> 0 then begin
                            PrintTrans := true;
                            PrintFooter := true;
                        end;
                        if QtyConsumed[i] <> 0 then begin
                            PrintCons := true;
                            PrintFooter := true;
                        end;
                        if QtyOutput[i] <> 0 then begin
                            PrintOutput := true;
                            PrintFooter := true;
                        end;
                        if QtySchedOutput[i] <> 0 then
                            PrintSchedOutput := true;
                        if QtySchedConsumption[i] <> 0 then
                            PrintSchedCons := true;
                    end;
                end;
                SetRange("Date Filter");
            end;

            trigger OnPreDataItem()
            begin
                PrintFooter := false;
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
                    field("PeriodStartingDate[2]"; PeriodStartingDate[2])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the start date for the projection.';
                    }
                    field(PeriodCalculation; PeriodCalculation)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Length of Period (1W,1M)';
                        ToolTip = 'Specifies the length of the each projection period. For example, enter 30D to base the projection on 30 day intervals. The default period is 1M, or one month.';
                    }
                    field(BreakdownByVariant; BreakdownByVariant)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Breakdown by Variant';
                        ToolTip = 'Specifies if you want a separate projection for each item variant. If you do not select this field, all variants will be combined into one projection for each item.';
                    }
                    field(IncludeMfg; IncludeMfg)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Manufacturing Projections';
                        OptionCaption = 'Do not include,Include released orders only,Include planned and released orders';
                        ToolTip = 'Specifies if you want to include released orders, include planned and released orders, or exclude projections from this report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if Format(PeriodCalculation) = '' then
                Evaluate(PeriodCalculation, '<1M>');
            if PeriodStartingDate[2] = 0D
            then
                PeriodStartingDate[2] := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        Title := Text000;
        if BreakdownByVariant then
            Title := Title + ' - ' + Text001;

        PeriodStartingDate[1] := 0D;
        for i := 2 to 6 do
            PeriodStartingDate[i + 1] := CalcDate(PeriodCalculation, PeriodStartingDate[i]);
        PeriodStartingDate[8] := 99991231D;
        CompanyInformation.Get();
        ItemFilter := Item.GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemFilter: Text;
        Title: Text[50];
        NoVariant: Text[30];
        IncludeMfg: Option "Do not include","Include released orders only","Include planned and released orders";
        PrintFooter: Boolean;
        PeriodStartingDate: array[8] of Date;
        BreakdownByVariant: Boolean;
        PrintSales: Boolean;
        PrintPurch: Boolean;
        PrintAdj: Boolean;
        PrintTrans: Boolean;
        PrintOutput: Boolean;
        PrintCons: Boolean;
        PrintSchedOutput: Boolean;
        PrintSchedCons: Boolean;
        OnHand: array[7] of Decimal;
        QtyAvailable: array[7] of Decimal;
        QtyOnPurchOrders: array[7] of Decimal;
        QtyOnSalesOrders: array[7] of Decimal;
        QtyOnServiceOrders: array[7] of Decimal;
        QtySold: array[7] of Decimal;
        QtyPurchased: array[7] of Decimal;
        QtyAdjusted: array[7] of Decimal;
        QtyTransferred: array[7] of Decimal;
        QtyConsumed: array[7] of Decimal;
        QtyOutput: array[7] of Decimal;
        QtySchedOutput: array[7] of Decimal;
        QtySchedConsumption: array[7] of Decimal;
        i: Integer;
        PeriodCalculation: DateFormula;
        Text000: Label 'Availability Projection';
        Text001: Label 'by Variant';
        Text002: Label 'Variant:  None';
        Text003: Label 'Before';
        Text004: Label 'After';
        Text005: Label 'thru';
        Text006: Label 'Variant:';
        Text007: Label 'Manufacturing Projections Included:  %1';
        TOnHand: array[7] of Decimal;
        TQtySold: array[7] of Decimal;
        TQtyPurchased: array[7] of Decimal;
        TQtyAdjusted: array[7] of Decimal;
        TQtyTransferred: array[7] of Decimal;
        TQtyConsumed: array[7] of Decimal;
        TQtyOutput: array[7] of Decimal;
        TQtySchedOutput: array[7] of Decimal;
        TQtySchedConsumption: array[7] of Decimal;
        TQtyAvailable: array[7] of Decimal;
        TQtyOnPurchOrders: array[7] of Decimal;
        TQtyOnSalesOrders: array[7] of Decimal;
        TQtyOnServiceOrders: array[7] of Decimal;
        TPrintSales: Boolean;
        TPrintPurch: Boolean;
        TPrintAdj: Boolean;
        TPrintTrans: Boolean;
        TPrintOutput: Boolean;
        TPrintCons: Boolean;
        TPrintSchedOutput: Boolean;
        TPrintSchedCons: Boolean;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Quantity_on_HandCaptionLbl: Label 'Quantity on Hand';
        Quantity_ShippedCaptionLbl: Label 'Quantity Shipped';
        Quantity_ReceivedCaptionLbl: Label 'Quantity Received';
        Quantity_AdjustedCaptionLbl: Label 'Quantity Adjusted';
        Quantity_TransferredCaptionLbl: Label 'Quantity Transferred';
        Quantity_OutputCaptionLbl: Label 'Quantity Output';
        Quantity_ConsumedCaptionLbl: Label 'Quantity Consumed';
        Scheduled_Production_OutputCaptionLbl: Label 'Scheduled Production Output';
        Scheduled_Production_NeedsCaptionLbl: Label 'Scheduled Production Needs';
        Quantity_on_Sales_OrdersCaptionLbl: Label 'Quantity on Sales Orders';
        Quantity_on_Purchase_OrdersCaptionLbl: Label 'Quantity on Purchase Orders';
        Quantity_AvailableCaptionLbl: Label 'Quantity Available';
        Quantity_on_Service_OrdersCaptionLbl: Label 'Quantity on Service Orders';
        There_are_actual_quantities_sold_or_purchased_on_this_page__which_should_not_normally_happen_in_a_projection_CaptionLbl: Label 'There are actual quantities sold or purchased on this page, which should not normally happen in a projection.';
        Quantity_on_HandCaption_Control14Lbl: Label 'Quantity on Hand';
        Item__Lead_Time_Calculation__Control18CaptionLbl: Label 'Lead Time Calculation';
        Quantity_ShippedCaption_Control20Lbl: Label 'Quantity Shipped';
        Quantity_ReceivedCaption_Control88Lbl: Label 'Quantity Received';
        Quantity_AdjustedCaption_Control95Lbl: Label 'Quantity Adjusted';
        Quantity_TransferredCaption_Control213Lbl: Label 'Quantity Transferred';
        Quantity_OutputCaption_Control206Lbl: Label 'Quantity Output';
        Quantity_ConsumedCaption_Control199Lbl: Label 'Quantity Consumed';
        Scheduled_Production_OutputCaption_Control191Lbl: Label 'Scheduled Production Output';
        Scheduled_Production_NeedsCaption_Control183Lbl: Label 'Scheduled Production Needs';
        Quantity_on_Sales_OrdersCaption_Control102Lbl: Label 'Quantity on Sales Orders';
        Quantity_on_Purchase_OrdersCaption_Control109Lbl: Label 'Quantity on Purchase Orders';
        Quantity_AvailableCaption_Control125Lbl: Label 'Quantity Available';
        Quantity_on_Service_OrdersCaption_Control175Lbl: Label 'Quantity on Service Orders';
}

