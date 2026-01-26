// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;

report 10131 "Availability Status"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/AvailabilityStatus.rdlc';
    Caption = 'Availability Status';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", "Search Description", "Inventory Posting Group", "Vendor No.", "Location Filter";
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
            column(ItemFilter; ItemFilter)
            {
            }
            column(GroupKey; GroupKey)
            {
            }
            column(Item__Inventory_Posting_Group_; "Inventory Posting Group")
            {
            }
            column(Item_Item_Description; Item.Description)
            {
            }
            column(Item__No__; "No.")
            {
            }
            column(Item__Base_Unit_of_Measure_; "Base Unit of Measure")
            {
            }
            column(Item_Inventory; Inventory)
            {
                DecimalPlaces = 0 : 5;
            }
            column(Qty__on_Sales_Order_; -"Qty. on Sales Order")
            {
                DecimalPlaces = 0 : 5;
            }
            column(Item__Qty__on_Purch__Order_; "Qty. on Purch. Order")
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyAvailable; QtyAvailable)
            {
                DecimalPlaces = 0 : 5;
            }
            column(Item__Reorder_Point_; "Reorder Point")
            {
                DecimalPlaces = 0 : 5;
            }
            column(QuantityOnRelProdOrd; QuantityOnRelProdOrd)
            {
                DecimalPlaces = 0 : 5;
            }
            column(QuantityOnPlanProdOrd; QuantityOnPlanProdOrd)
            {
                DecimalPlaces = 0 : 5;
            }
            column(Qty__on_Service_Order_; -CalcQtyOnServiceOrder())
            {
                DecimalPlaces = 0 : 5;
            }
            column(Availability_StatusCaption; Availability_StatusCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Item__Base_Unit_of_Measure_Caption; FieldCaption("Base Unit of Measure"))
            {
            }
            column(Item_InventoryCaption; FieldCaption(Inventory))
            {
            }
            column(Qty__on_Sales_Order_Caption; Qty__on_Sales_Order_CaptionLbl)
            {
            }
            column(Item__Qty__on_Purch__Order_Caption; FieldCaption("Qty. on Purch. Order"))
            {
            }
            column(QtyAvailableCaption; QtyAvailableCaptionLbl)
            {
            }
            column(Item__Reorder_Point_Caption; FieldCaption("Reorder Point"))
            {
            }
            column(Item__No__Caption; FieldCaption("No."))
            {
            }
            column(QuantityOnRelProdOrdCaption; QuantityOnRelProdOrdCaptionLbl)
            {
            }
            column(QuantityOnPlanProdOrdCaption; QuantityOnPlanProdOrdCaptionLbl)
            {
            }
            column(Qty__on_Prod__Ord_Caption; Qty__on_Prod__Ord_CaptionLbl)
            {
            }
            column(Qty__on_Service_Order_Caption; Qty__on_Service_Order_CaptionLbl)
            {
            }
            column(Item__Inventory_Posting_Group_Caption; FieldCaption("Inventory Posting Group"))
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields(Inventory, "Qty. on Sales Order", "Qty. on Purch. Order",
                  "Scheduled Receipt (Qty.)", "Qty. on Component Lines",
                  "Rel. Scheduled Receipt (Qty.)", "Rel. Scheduled Need (Qty.)");
                QuantityOnRelProdOrd := "Rel. Scheduled Receipt (Qty.)" - "Rel. Scheduled Need (Qty.)";
                QuantityOnPlanProdOrd := "Scheduled Receipt (Qty.)" - "Qty. on Component Lines" - QuantityOnRelProdOrd;
                QtyAvailable := Inventory - "Qty. on Sales Order" + "Qty. on Purch. Order" -
                  CalcQtyOnServiceOrder() + QuantityOnRelProdOrd + QuantityOnPlanProdOrd;
            end;

            trigger OnPreDataItem()
            begin
                if StrPos(Item.CurrentKey, FieldCaption("Inventory Posting Group")) = 0 then
                    GroupKey := false
                else
                    GroupKey := true;
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
        ItemFilter := Item.GetFilters();
        CompanyInformation.Get();
    end;

    var
        CompanyInformation: Record "Company Information";
        ItemFilter: Text;
        QuantityOnRelProdOrd: Decimal;
        QuantityOnPlanProdOrd: Decimal;
        QtyAvailable: Decimal;
        GroupKey: Boolean;
        Availability_StatusCaptionLbl: Label 'Availability Status';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Qty__on_Sales_Order_CaptionLbl: Label 'Qty. on Sales Order';
        QtyAvailableCaptionLbl: Label 'Quantity Available';
        QuantityOnRelProdOrdCaptionLbl: Label 'Released';
        QuantityOnPlanProdOrdCaptionLbl: Label 'Planned';
        Qty__on_Prod__Ord_CaptionLbl: Label 'Qty. on Prod. Ord.';
        Qty__on_Service_Order_CaptionLbl: Label 'Qty. on Service Order';
}

