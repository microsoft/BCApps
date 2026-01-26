#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

report 12155 "Subcontr. Dispatching List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Manufacturing/Document/SubcontrDispatchingList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Subcontractor - Dispatch List IT';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.") where(Subcontractor = const(true));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(USERID; UserId)
            {
            }
            column(Vendor__No__; "No.")
            {
            }
            column(Vendor__No___Control1130512; "No.")
            {
            }
            column(Vendor_Name; Name)
            {
            }
            column(Vendor__Subcontracting_Location_Code_; "Subcontracting Location Code")
            {
            }
            column(Subcontractor_Dispatch_ListCaption; Subcontractor_Dispatch_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Vendor__No__Caption; Vendor__No__CaptionLbl)
            {
            }
            column(ContinuedCaption; ContinuedCaptionLbl)
            {
            }
            column(Vendor__No___Control1130512Caption; Vendor__No___Control1130512CaptionLbl)
            {
            }
            column(Vendor__Subcontracting_Location_Code_Caption; FieldCaption("Subcontracting Location Code"))
            {
            }
            dataitem("Purchase Header"; "Purchase Header")
            {
                DataItemLink = "Buy-from Vendor No." = field("No.");
                DataItemTableView = sorting("Document Type", "Buy-from Vendor No.", "No.") where("Subcontracting Order" = const(true));
                PrintOnlyIfDetail = true;
                RequestFilterFields = "No.", "Requested Receipt Date";
                column(Purchase_Header__No__; "No.")
                {
                }
                column(Purchase_Header__Order_Date_; Format("Order Date"))
                {
                }
                column(Purchase_Header_Document_Type; "Document Type")
                {
                }
                column(Purchase_Header_Buy_from_Vendor_No_; "Buy-from Vendor No.")
                {
                }
                column(Purchase_Header__No__Caption; Purchase_Header__No__CaptionLbl)
                {
                }
                column(Purchase_Header__Order_Date_Caption; Purchase_Header__Order_Date_CaptionLbl)
                {
                }
                column(Prod__Order_Line__QuantityCaption; Prod__Order_Line__QuantityCaptionLbl)
                {
                }
                column(Prod__Order_Line___Remaining_Quantity_Caption; Prod__Order_Line___Remaining_Quantity_CaptionLbl)
                {
                }
                dataitem("Purchase Line"; "Purchase Line")
                {
                    DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                    DataItemTableView = sorting("Document Type", "Document No.", "Line No.") where("Prod. Order No." = filter(<> ''));
                    RequestFilterFields = "Prod. Order No.", "Routing No.", "Operation No.", "Work Center No.";
                    column(Purchase_Line__Purchase_Line__Quantity; "Purchase Line".Quantity)
                    {
                    }
                    column(Purchase_Line__Purchase_Line___Unit_of_Measure_Code_; "Purchase Line"."Unit of Measure Code")
                    {
                    }
                    column(Purchase_Line__Purchase_Line___Outstanding_Quantity_; "Purchase Line"."Outstanding Quantity")
                    {
                    }
                    column(Purchase_Line__Requested_Receipt_Date_; Format("Requested Receipt Date"))
                    {
                    }
                    column(Purchase_Line_Description; Description)
                    {
                    }
                    column(Purchase_Line__No__; "No.")
                    {
                    }
                    column(Purchase_Line__Line_No__; "Line No.")
                    {
                    }
                    column(Purchase_Line_Document_Type; "Document Type")
                    {
                    }
                    column(Purchase_Line_Document_No_; "Document No.")
                    {
                    }
                    column(Purchase_Line_Prod__Order_No_; "Prod. Order No.")
                    {
                    }
                    column(Purchase_Line_Prod__Order_Line_No_; "Prod. Order Line No.")
                    {
                    }
                    column(Purchase_Line_Routing_No_; "Routing No.")
                    {
                    }
                    column(Purchase_Line_Routing_Reference_No_; "Routing Reference No.")
                    {
                    }
                    column(Purchase_Line_Operation_No_; "Operation No.")
                    {
                    }
                    column(Purchase_Line__Requested_Receipt_Date_Caption; Purchase_Line__Requested_Receipt_Date_CaptionLbl)
                    {
                    }
                    column(Purchase_Line__No__Caption; Purchase_Line__No__CaptionLbl)
                    {
                    }
                    column(Purchase_Line__Line_No__Caption; FieldCaption("Line No."))
                    {
                    }
                    dataitem("Prod. Order Line"; "Prod. Order Line")
                    {
                        DataItemLink = "Prod. Order No." = field("Prod. Order No."), "Line No." = field("Prod. Order Line No.");
                        DataItemTableView = sorting(Status, "Prod. Order No.", "Line No.") where(Status = const(Released));
                    }
                    dataitem("Prod. Order Routing Line"; "Prod. Order Routing Line")
                    {
                        DataItemLink = "Prod. Order No." = field("Prod. Order No."), "Routing No." = field("Routing No."), "Routing Reference No." = field("Routing Reference No."), "Operation No." = field("Operation No.");
                        DataItemTableView = sorting(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.") where(Status = const(Released));
                        column(Prod__Order_Routing_Line__Prod__Order_No__; "Prod. Order No.")
                        {
                        }
                        column(Prod__Order_Routing_Line__Operation_No__; "Operation No.")
                        {
                        }
                        column(Prod__Order_Line__Quantity; "Prod. Order Line".Quantity)
                        {
                        }
                        column(Prod__Order_Routing_Line_Description; Description)
                        {
                        }
                        column(Prod__Order_Line___Remaining_Quantity_; "Prod. Order Line"."Remaining Quantity")
                        {
                        }
                        column(Prod__Order_Line___Unit_of_Measure_Code_; "Prod. Order Line"."Unit of Measure Code")
                        {
                        }
                        column(Prod__Order_Routing_Line__Starting_Date_; Format("Starting Date"))
                        {
                        }
                        column(Prod__Order_Routing_Line__Ending_Date_; Format("Ending Date"))
                        {
                        }
                        column(Prod__Order_Line___Item_No__; "Prod. Order Line"."Item No.")
                        {
                        }
                        column(Prod__Order_Routing_Line_Description_Control1130538; Description)
                        {
                        }
                        column(Prod__Order_Line___Quantity__Base__; "Prod. Order Line"."Quantity (Base)")
                        {
                        }
                        column(Prod__Order_Line___Quantity__Base______Qty__WIP_on_Subcontractors_____Qty__WIP_on_Transfer_Order_; "Prod. Order Line"."Quantity (Base)" - "Qty. WIP on Subcontractors" - "Qty. WIP on Transfer Order")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(Prod__Order_Routing_Line__Qty__WIP_on_Subcontractors_; "Qty. WIP on Subcontractors")
                        {
                        }
                        column(Item__Base_Unit_of_Measure_; Item."Base Unit of Measure")
                        {
                        }
                        column(Prod__Order_Routing_Line__WIP_Item_; "WIP Item")
                        {
                        }
                        column(Prod__Order_Routing_Line__Qty__WIP_on_Transfer_Order_; "Qty. WIP on Transfer Order")
                        {
                        }
                        column(Prod__Order_Routing_Line_Status; Status)
                        {
                        }
                        column(Prod__Order_Routing_Line_Routing_Reference_No_; "Routing Reference No.")
                        {
                        }
                        column(Prod__Order_Routing_Line_Routing_No_; "Routing No.")
                        {
                        }
                        column(Prod__Order_Routing_Line_Routing_Link_Code; "Routing Link Code")
                        {
                        }
                        column(Prod__Order_Caption; Prod__Order_CaptionLbl)
                        {
                        }
                        column(Prod__Order_Routing_Line__Operation_No__Caption; FieldCaption("Operation No."))
                        {
                        }
                        column(Prod__Order_Routing_Line__Starting_Date_Caption; Prod__Order_Routing_Line__Starting_Date_CaptionLbl)
                        {
                        }
                        column(Prod__Order_Routing_Line__Ending_Date_Caption; Prod__Order_Routing_Line__Ending_Date_CaptionLbl)
                        {
                        }
                        column(UoMCaption; UoMCaptionLbl)
                        {
                        }
                        column(Prod__Order_Line___Quantity__Base______Qty__WIP_on_Subcontractors_____Qty__WIP_on_Transfer_Order_Caption; Prod__Order_Line___Quantity__Base______Qty__WIP_on_Subcontractors_____Qty__WIP_on_Transfer_Order_CaptionLbl)
                        {
                        }
                        column(Prod__Order_Line___Quantity__Base__Caption; Prod__Order_Line___Quantity__Base__CaptionLbl)
                        {
                        }
                        column(ItemCaption; ItemCaptionLbl)
                        {
                        }
                        column(WIP_Components_to_shipCaption; WIP_Components_to_shipCaptionLbl)
                        {
                        }
                        column(Prod__Order_Routing_Line__Qty__WIP_on_Subcontractors_Caption; FieldCaption("Qty. WIP on Subcontractors"))
                        {
                        }
                        dataitem("Prod. Order Component"; "Prod. Order Component")
                        {
                            DataItemLink = Status = field(Status), "Prod. Order No." = field("Prod. Order No."), "Prod. Order Line No." = field("Routing Reference No."), "Routing Link Code" = field("Routing Link Code");
                            DataItemTableView = sorting(Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.");
                            column(Prod__Order_Component__Item_No__; "Item No.")
                            {
                            }
                            column(Prod__Order_Component_Description; Description)
                            {
                            }
                            column(Expected_Qty___Base______Qty__transf__to_Subcontractor______Qty__in_Transit__Base__; "Expected Qty. (Base)" - "Qty. transf. to Subcontractor" - "Qty. in Transit (Base)")
                            {
                                DecimalPlaces = 0 : 5;
                            }
                            column(Prod__Order_Component__Qty__transf__to_Subcontractor_; "Qty. transf. to Subcontractor")
                            {
                            }
                            column(Item__Base_Unit_of_Measure__Control1130552; Item."Base Unit of Measure")
                            {
                            }
                            column(Prod__Order_Component__Qty__in_Transit__Base__; "Qty. in Transit (Base)")
                            {
                            }
                            column(Prod__Order_Component__Expected_Qty___Base__; "Expected Qty. (Base)")
                            {
                            }
                            column(Prod__Order_Component_Status; Status)
                            {
                            }
                            column(Prod__Order_Component_Prod__Order_No_; "Prod. Order No.")
                            {
                            }
                            column(Prod__Order_Component_Prod__Order_Line_No_; "Prod. Order Line No.")
                            {
                            }
                            column(Prod__Order_Component_Line_No_; "Line No.")
                            {
                            }
                            column(Prod__Order_Component_Routing_Link_Code; "Routing Link Code")
                            {
                            }
                            column(Components_to_shipCaption; Components_to_shipCaptionLbl)
                            {
                            }
                            column(ItemCaption_Control1130541; ItemCaption_Control1130541Lbl)
                            {
                            }
                            column(Expected_Qty___Base______Qty__transf__to_Subcontractor______Qty__in_Transit__Base__Caption; Expected_Qty___Base______Qty__transf__to_Subcontractor______Qty__in_Transit__Base__CaptionLbl)
                            {
                            }
                            column(Prod__Order_Component__Qty__transf__to_Subcontractor_Caption; FieldCaption("Qty. transf. to Subcontractor"))
                            {
                            }
                            column(UoMCaption_Control1130544; UoMCaption_Control1130544Lbl)
                            {
                            }
                            column(Prod__Order_Component__Qty__in_Transit__Base__Caption; FieldCaption("Qty. in Transit (Base)"))
                            {
                            }
                            column(Prod__Order_Component__Expected_Qty___Base__Caption; FieldCaption("Expected Qty. (Base)"))
                            {
                            }

                            trigger OnPreDataItem()
                            begin
                                SetRange("Purchase Order Filter", "Purchase Header"."No.");
                            end;
                        }
                    }
                }
            }
        }
    }

    requestpage
    {

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

    var
        Item: Record Item;
        Subcontractor_Dispatch_ListCaptionLbl: Label 'Subcontractor Dispatch List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Vendor__No__CaptionLbl: Label 'Subcontractor';
        ContinuedCaptionLbl: Label 'Continued';
        Vendor__No___Control1130512CaptionLbl: Label 'Subcontractor';
        Purchase_Header__No__CaptionLbl: Label 'Subc. Ord. No.';
        Purchase_Header__Order_Date_CaptionLbl: Label 'Order Date';
        Prod__Order_Line__QuantityCaptionLbl: Label 'Quantity';
        Prod__Order_Line___Remaining_Quantity_CaptionLbl: Label 'Remaining Qty';
        Purchase_Line__Requested_Receipt_Date_CaptionLbl: Label 'Requested Receipt Date';
        Purchase_Line__No__CaptionLbl: Label 'Item';
        Prod__Order_CaptionLbl: Label 'Prod. Order:';
        Prod__Order_Routing_Line__Starting_Date_CaptionLbl: Label 'Starting Date';
        Prod__Order_Routing_Line__Ending_Date_CaptionLbl: Label 'Ending Date';
        UoMCaptionLbl: Label 'UoM';
        Prod__Order_Line___Quantity__Base______Qty__WIP_on_Subcontractors_____Qty__WIP_on_Transfer_Order_CaptionLbl: Label 'Qty to ship';
        Prod__Order_Line___Quantity__Base__CaptionLbl: Label 'Quantity (Base)';
        ItemCaptionLbl: Label 'Item';
        WIP_Components_to_shipCaptionLbl: Label 'WIP Components to ship';
        Components_to_shipCaptionLbl: Label 'Components to ship';
        ItemCaption_Control1130541Lbl: Label 'Item';
        Expected_Qty___Base______Qty__transf__to_Subcontractor______Qty__in_Transit__Base__CaptionLbl: Label 'Qty to ship';
        UoMCaption_Control1130544Lbl: Label 'UoM';
}
#endif
