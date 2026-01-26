// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Foundation.Period;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using System.Utilities;

report 12136 "Ledger Entry Details"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/LedgerEntryDetails.rdlc';
    Caption = 'Ledger Entry Details';

    dataset
    {
        dataitem("Item Cost History"; "Item Cost History")
        {
            DataItemTableView = sorting("Item No.", "Competence Year");
            RequestFilterFields = "Competence Year";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(Item_Cost_History__Item_No__; "Item No.")
            {
            }
            column(Item_Cost_History_Description; Description)
            {
            }
            column(Item_Cost_History_Competence_Year; "Competence Year")
            {
            }
            column(Ledger_Entries_DetailCaption; Ledger_Entries_DetailCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Item_Cost_History__Item_No__Caption; FieldCaption("Item No."))
            {
            }
            dataitem(Purchases; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("Item No.");
                DataItemTableView = sorting("Item No.", "Posting Date") where("Entry Type" = filter(Purchase));
                column(Purchases__Document_No__; "Document No.")
                {
                }
                column(Purchases__Posting_Date_; Format("Posting Date"))
                {
                }
                column(Purchases_Quantity; Quantity)
                {
                }
                column(Purchases__Purchase_Amount__Actual__; "Cost Amount (Actual)")
                {
                }
                column(Purchases__Purchase_Amount__Expected__; "Cost Amount (Expected)")
                {
                }
                column(Purchases_Quantity_Control1130000; Quantity)
                {
                }
                column(Purchases__Purchase_Amount__Actual___Control1130007; "Cost Amount (Actual)")
                {
                }
                column(Purchases__Purchase_Amount__Expected___Control1130089; "Cost Amount (Expected)")
                {
                }
                column(Purchases_Entry_No_; "Entry No.")
                {
                }
                column(Purchases_Item_No_; "Item No.")
                {
                }
                column(Purchases__Document_No__Caption; FieldCaption("Document No."))
                {
                }
                column(Purchases__Posting_Date_Caption; Purchases__Posting_Date_CaptionLbl)
                {
                }
                column(Purchases_QuantityCaption; FieldCaption(Quantity))
                {
                }
                column(AmountCaption; AmountCaptionLbl)
                {
                }
                column(Expected_CostCaption; Expected_CostCaptionLbl)
                {
                }
                column(PurchasesCaption; PurchasesCaptionLbl)
                {
                }
                column(TotalsCaption; TotalsCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    SetRange("Posting Date", StartingDate, "Item Cost History"."Competence Year");
                end;
            }
            dataitem("Production Output"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("Item No.");
                DataItemTableView = sorting("Item No.", "Posting Date") where("Entry Type" = filter(Output));
                column(Production_Output__Prod__Order_No__; "Order No.")
                {
                }
                column(Production_Output__Document_No__; "Document No.")
                {
                }
                column(Production_Output__Posting_Date_; Format("Posting Date"))
                {
                }
                column(Production_Output_Quantity; Quantity)
                {
                }
                column(Production_Output_Quantity_Control1130032; Quantity)
                {
                }
                column(Production_Output_Entry_No_; "Entry No.")
                {
                }
                column(Production_Output_Item_No_; "Item No.")
                {
                }
                column(Production_OutputCaption; Production_OutputCaptionLbl)
                {
                }
                column(Production_Output__Prod__Order_No__Caption; FieldCaption("Order No."))
                {
                }
                column(Production_Output__Document_No__Caption; FieldCaption("Document No."))
                {
                }
                column(Production_Output__Posting_Date_Caption; Production_Output__Posting_Date_CaptionLbl)
                {
                }
                column(Output_QuantityCaption; Output_QuantityCaptionLbl)
                {
                }
                column(TotalsCaption_Control1130033; TotalsCaption_Control1130033Lbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    SetRange("Posting Date", StartingDate, "Item Cost History"."Competence Year");
                end;
            }
            dataitem("Production Output1"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("Item No.");
                DataItemTableView = sorting("Item No.", "Posting Date") where("Entry Type" = filter(Output));
                column(ConsumeQty; ConsumeQty)
                {
                }
                column(CompetenceQty; CompetenceQty)
                {
                }
                column(CompetenceQty_UnitCost; CompetenceQty * UnitCost)
                {
                }
                column(Production_Output1_Entry_No_; "Entry No.")
                {
                }
                column(Production_Output1_Item_No_; "Item No.")
                {
                }
                column(Production_Output1_Order_No_; "Order No.")
                {
                }
                column(Item_No_Caption; "Production Consumption".FieldCaption("Item No."))
                {
                }
                column(Document_No_Caption; "Production Consumption".FieldCaption("Document No."))
                {
                }
                column(Posting_DateCaption; Posting_DateCaptionLbl)
                {
                }
                column(QuantityCaption; QuantityCaptionLbl)
                {
                }
                column(Competence_QuantityCaption; Competence_QuantityCaptionLbl)
                {
                }
                column(Unit_CostCaption; Unit_CostCaptionLbl)
                {
                }
                column(Components_AmountCaption; Components_AmountCaptionLbl)
                {
                }
                column(Production_ConsumptionCaption; Production_ConsumptionCaptionLbl)
                {
                }
                column(Prod__Order_No_Caption; "Production Consumption".FieldCaption("Order No."))
                {
                }
                column(TotalsCaption_Control1130097; TotalsCaption_Control1130097Lbl)
                {
                }
                dataitem("Production Consumption"; "Item Ledger Entry")
                {
                    DataItemLink = "Source No." = field("Item No."), "Order No." = field("Order No.");
                    DataItemTableView = sorting("Item No.", "Posting Date") where("Entry Type" = filter(Consumption));
                    column(ConsumeQty_Control1130041; ConsumeQty)
                    {
                    }
                    column(Production_Consumption__Posting_Date_; Format("Posting Date"))
                    {
                    }
                    column(Production_Consumption__Document_No__; "Document No.")
                    {
                    }
                    column(Production_Consumption__Item_No__; "Item No.")
                    {
                    }
                    column(CompetenceQty_UnitCost_Control1130048; CompetenceQty * UnitCost)
                    {
                    }
                    column(Production_Consumption__Prod__Order_No__; "Order No.")
                    {
                    }
                    column(UnitCost; UnitCost)
                    {
                    }
                    column(CompetenceQty_Control1130044; CompetenceQty)
                    {
                    }
                    column(Production_Consumption_Entry_No_; "Entry No.")
                    {
                    }
                    column(Production_Consumption_Source_No_; "Source No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    var
                        YearProdOrdOutput: Decimal;
                    begin
                        YearProdOrdOutput := CalcProdOrderOutput("Order No.");
                        ConsumeQty := Abs(Quantity);
                        CompetenceQty := Abs(Quantity) * YearProdOrdOutput / ProdOrderLine."Finished Quantity";
                        if ItemCostHistory.Get("Item No.", "Item Cost History"."Competence Year") then
                            UnitCost := ItemCostHistory.GetCompCost("Item Cost History"."Components Valuation");
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not "Item Cost History"."Estimated WIP Consumption" then
                            SetRange("Posting Date", StartingDate, "Item Cost History"."Competence Year");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if PrevProdOrderNo = "Order No." then
                        CurrReport.Skip();
                    if DisplayEstimatedCosts("Order No.", "Order Line No.") then
                        CurrReport.Skip();
                    PrevProdOrderNo := "Order No.";
                end;

                trigger OnPreDataItem()
                begin
                    PrevProdOrderNo := '';
                    SetRange("Posting Date", StartingDate, "Item Cost History"."Competence Year");
                    Clear(CompetenceQty);
                    Clear(ConsumeQty);
                end;
            }
            dataitem("Production Output4"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("Item No.");
                DataItemTableView = sorting("Item No.", "Posting Date") where("Entry Type" = filter(Output));
                column(ComponentsAmt; ComponentsAmt)
                {
                }
                column(CompetenceAmt; CompetenceAmt)
                {
                }
                column(ExpectedQty; ExpectedQty)
                {
                }
                column(Production_Output4_Entry_No_; "Entry No.")
                {
                }
                column(Production_Output4_Item_No_; "Item No.")
                {
                }
                column(Production_Output4_Order_No_; "Order No.")
                {
                }
                column(Production_Output4_Order_Line_No_; "Order Line No.")
                {
                }
                column(Item_No_Caption_Control1130183; "Prod. Order Component".FieldCaption("Item No."))
                {
                }
                column(Quantity_PerCaption; "Prod. Order Component".FieldCaption("Quantity per"))
                {
                }
                column(Components_AmountCaption_Control1130191; Components_AmountCaption_Control1130191Lbl)
                {
                }
                column(Competence_AmountCaption; Competence_AmountCaptionLbl)
                {
                }
                column(Production_ConsumptionCaption_Control1130194; Production_ConsumptionCaption_Control1130194Lbl)
                {
                }
                column(Prod__Order_No_Caption_Control1130195; "Prod. Order Component".FieldCaption("Prod. Order No."))
                {
                }
                column(Expected_QuantityCaption; Expected_QuantityCaptionLbl)
                {
                }
                column(Prod__Order_Component__Unit_Cost_Caption; "Prod. Order Component".FieldCaption("Unit Cost"))
                {
                }
                column(TotalsCaption_Control1130199; TotalsCaption_Control1130199Lbl)
                {
                }
                dataitem("Prod. Order Component"; "Prod. Order Component")
                {
                    DataItemLink = "Prod. Order No." = field("Order No."), "Prod. Order Line No." = field("Order Line No.");
                    DataItemTableView = sorting(Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.");
                    column(Prod__Order_Component__Prod__Order_No__; "Prod. Order No.")
                    {
                    }
                    column(Prod__Order_Component__Item_No__; "Item No.")
                    {
                    }
                    column(Prod__Order_Component__Quantity_per_; "Quantity per")
                    {
                    }
                    column(ExpectedQty_Control1130202; ExpectedQty)
                    {
                    }
                    column(Prod__Order_Component__Unit_Cost_; "Unit Cost")
                    {
                    }
                    column(ComponentsAmt_Control1130185; ComponentsAmt)
                    {
                    }
                    column(CompetenceAmt_Control1130197; CompetenceAmt)
                    {
                    }
                    column(Prod__Order_Component_Status; Status)
                    {
                    }
                    column(Prod__Order_Component_Prod__Order_Line_No_; "Prod. Order Line No.")
                    {
                    }
                    column(Prod__Order_Component_Line_No_; "Line No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        CompetenceQty := 0;
                        CompetenceAmt := 0;
                        ComponentsAmt := 0;
                        ExpectedQty := 0;
                        ExpectedQty := "Expected Quantity";
                        ComponentsAmt := "Expected Quantity" * "Unit Cost";
                        CompetenceQty := ProdOrderLine."Finished Quantity" / ProdOrderLine.Quantity;
                        CompetenceAmt := CompetenceQty * ComponentsAmt;
                    end;

                    trigger OnPreDataItem()
                    begin
                        Clear(ComponentsAmt);
                        Clear(CompetenceAmt);
                        Clear(ExpectedQty);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if PrevProdOrderNo = "Order No." then
                        CurrReport.Skip();
                    if not DisplayEstimatedCosts("Order No.", "Order Line No.") then
                        CurrReport.Skip();
                    PrevProdOrderNo := "Order No.";
                end;

                trigger OnPreDataItem()
                begin
                    PrevProdOrderNo := '';
                    SetRange("Posting Date", StartingDate, "Item Cost History"."Competence Year");
                    Clear(ComponentsAmt);
                    Clear(CompetenceAmt);
                    Clear(ExpectedQty);
                end;
            }
            dataitem("Production Output2"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("Item No.");
                DataItemTableView = sorting("Item No.", "Posting Date") where("Entry Type" = filter(Output));
                column(RoutingQty; RoutingQty)
                {
                }
                column(CompetenceAmt_Control1130053; CompetenceAmt)
                {
                }
                column(CompetenceQty_Control1130160; CompetenceQty)
                {
                }
                column(SubconCompetenceAmt; SubconCompetenceAmt)
                {
                }
                column(Production_Output2_Entry_No_; "Entry No.")
                {
                }
                column(Production_Output2_Item_No_; "Item No.")
                {
                }
                column(Production_Output2_Order_No_; "Order No.")
                {
                }
                column(Competence_AmountCaption_Control1130152; Competence_AmountCaption_Control1130152Lbl)
                {
                }
                column(Unit_CostCaption_Control1130153; Unit_CostCaption_Control1130153Lbl)
                {
                }
                column(Production_RoutingCaption; Production_RoutingCaptionLbl)
                {
                }
                column(Competence_QuantityCaption_Control1130138; Competence_QuantityCaption_Control1130138Lbl)
                {
                }
                column(Production_Routing__Prod__Order_No__Caption; "Production Routing".FieldCaption("Order No."))
                {
                }
                column(Production_Routing_TypeCaption; "Production Routing".FieldCaption(Type))
                {
                }
                column(Production_Routing__No__Caption; "Production Routing".FieldCaption("No."))
                {
                }
                column(Production_Routing__Document_No__Caption; "Production Routing".FieldCaption("Document No."))
                {
                }
                column(Production_Routing__Posting_Date_Caption; Production_Routing__Posting_Date_CaptionLbl)
                {
                }
                column(Production_Routing__Operation_No__Caption; "Production Routing".FieldCaption("Operation No."))
                {
                }
                column(QuantityCaption_Control1130171; QuantityCaption_Control1130171Lbl)
                {
                }
                column(Subcontracting_Competence_AmountCaption; Subcontracting_Competence_AmountCaptionLbl)
                {
                }
                column(TotalsCaption_Control1130049; TotalsCaption_Control1130049Lbl)
                {
                }
                dataitem("Production Routing"; "Capacity Ledger Entry")
                {
                    DataItemLink = "Item No." = field("Item No."), "Order No." = field("Order No.");
                    DataItemTableView = sorting("Entry No.");
                    column(CompetenceAmt_Control1130060; CompetenceAmt)
                    {
                    }
                    column(UnitCost_Control1130105; UnitCost)
                    {
                    }
                    column(CompetenceQty_Control1130159; CompetenceQty)
                    {
                    }
                    column(Production_Routing__Prod__Order_No__; "Order No.")
                    {
                    }
                    column(Production_Routing_Type; Type)
                    {
                    }
                    column(Production_Routing__No__; "No.")
                    {
                    }
                    column(Production_Routing__Document_No__; "Document No.")
                    {
                    }
                    column(Production_Routing__Posting_Date_; Format("Posting Date"))
                    {
                    }
                    column(Production_Routing__Operation_No__; "Operation No.")
                    {
                    }
                    column(RoutingQty_Control1130170; RoutingQty)
                    {
                    }
                    column(SubconCompetenceAmt_Control1130172; SubconCompetenceAmt)
                    {
                    }
                    column(Production_Routing_Entry_No_; "Entry No.")
                    {
                    }
                    column(Production_Routing_Item_No_; "Item No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    var
                        PurchLine: Record "Purchase Line";
                        ProdOrdRoutingLine: Record "Prod. Order Routing Line";
                        YearProdOrdOutput: Decimal;
                    begin
                        RoutingQty := Quantity;
                        RoutingAmt := 0;
                        CompetenceQty := 0;
                        CompetenceAmt := 0;
                        SubconCompetenceAmt := 0;
                        if not DisplayEstimatedCosts("Order No.", "Order Line No.") then begin
                            CalcFields("Direct Cost");
                            CalcFields("Overhead Cost");
                            if "Direct Cost" <> 0 then
                                RoutingAmt += "Direct Cost"
                            else begin
                                PurchLine.Reset();
                                PurchLine.SetRange("Prod. Order No.", "Order No.");
                                PurchLine.SetRange("No.", "Item No.");
                                if PurchLine.FindFirst() then
                                    RoutingAmt += Quantity * PurchLine."Direct Unit Cost";
                            end;
                            RoutingAmt += "Overhead Cost";
                        end else begin
                            ProdOrdRoutingLine.Reset();
                            ProdOrdRoutingLine.SetRange(Status, ProdOrderLine.Status);
                            ProdOrdRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
                            ProdOrdRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Line No.");
                            ProdOrdRoutingLine.SetRange("No.", "No.");
                            if ProdOrdRoutingLine.FindSet() then
                                repeat
                                    RoutingAmt += ProdOrdRoutingLine."Expected Operation Cost Amt." + ProdOrdRoutingLine."Expected Capacity Ovhd. Cost";
                                until ProdOrdRoutingLine.Next() = 0;
                        end;
                        UnitCost := RoutingAmt / Quantity;
                        YearProdOrdOutput := CalcProdOrderOutput("Order No.");
                        CompetenceQty := Abs(Quantity) * YearProdOrdOutput / ProdOrderLine."Finished Quantity";
                        if not Subcontracting then
                            CompetenceAmt := CompetenceQty * UnitCost
                        else
                            SubconCompetenceAmt := CompetenceQty * UnitCost;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not "Item Cost History"."Estimated WIP Consumption" then
                            SetRange("Posting Date", StartingDate, "Item Cost History"."Competence Year");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if PrevProdOrderNo = "Order No." then
                        CurrReport.Skip();
                    if DisplayEstimatedCosts("Order No.", "Order Line No.") then
                        CurrReport.Skip();
                    PrevProdOrderNo := "Order No.";
                end;

                trigger OnPreDataItem()
                begin
                    PrevProdOrderNo := '';
                    SetRange("Posting Date", StartingDate, "Item Cost History"."Competence Year");
                end;
            }
            dataitem("Production Output3"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("Item No.");
                DataItemTableView = sorting("Item No.", "Posting Date") where("Entry Type" = filter(Output));
                column(SubconCompetenceAmt_Control1130186; SubconCompetenceAmt)
                {
                }
                column(CompetenceAmt_Control1130187; CompetenceAmt)
                {
                }
                column(ExpectedSubconAmt; ExpectedSubconAmt)
                {
                }
                column(ExpectedOpCostAmt; ExpectedOpCostAmt)
                {
                }
                column(Production_Output3_Entry_No_; "Entry No.")
                {
                }
                column(Production_Output3_Item_No_; "Item No.")
                {
                }
                column(Production_Output3_Order_No_; "Order No.")
                {
                }
                column(Production_Output3_Order_Line_No_; "Order Line No.")
                {
                }
                column(Prod__Order_Routing_Line__Prod__Order_No__Caption; "Prod. Order Routing Line".FieldCaption("Prod. Order No."))
                {
                }
                column(Prod__Order_Routing_Line_TypeCaption; "Prod. Order Routing Line".FieldCaption(Type))
                {
                }
                column(Prod__Order_Routing_Line__No__Caption; "Prod. Order Routing Line".FieldCaption("No."))
                {
                }
                column(Prod__Order_Routing_Line__Operation_No__Caption; "Prod. Order Routing Line".FieldCaption("Operation No."))
                {
                }
                column(Prod__Order_Routing_Line__Direct_Unit_Cost_Caption; "Prod. Order Routing Line".FieldCaption("Direct Unit Cost"))
                {
                }
                column(Expected_Operation_Cost_Amt_Caption; Expected_Operation_Cost_Amt_CaptionLbl)
                {
                }
                column(Expected_Subcontracting_AmountCaption; Expected_Subcontracting_AmountCaptionLbl)
                {
                }
                column(Competence_Operation_Cost_AmountCaption; Competence_Operation_Cost_AmountCaptionLbl)
                {
                }
                column(Competence_Subcontracting_AmountCaption; Competence_Subcontracting_AmountCaptionLbl)
                {
                }
                column(Production_RoutingCaption_Control1130182; Production_RoutingCaption_Control1130182Lbl)
                {
                }
                column(TotalsCaption_Control1130181; TotalsCaption_Control1130181Lbl)
                {
                }
                dataitem("Prod. Order Routing Line"; "Prod. Order Routing Line")
                {
                    DataItemLink = "Prod. Order No." = field("Order No."), "Routing Reference No." = field("Order Line No.");
                    DataItemTableView = sorting(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
                    column(Prod__Order_Routing_Line__Prod__Order_No__; "Prod. Order No.")
                    {
                    }
                    column(Prod__Order_Routing_Line_Type; Type)
                    {
                    }
                    column(Prod__Order_Routing_Line__No__; "No.")
                    {
                    }
                    column(Prod__Order_Routing_Line__Operation_No__; "Operation No.")
                    {
                    }
                    column(Prod__Order_Routing_Line__Direct_Unit_Cost_; "Direct Unit Cost")
                    {
                    }
                    column(ExpectedOpCostAmt_Control1130151; ExpectedOpCostAmt)
                    {
                    }
                    column(ExpectedSubconAmt_Control1130178; ExpectedSubconAmt)
                    {
                    }
                    column(CompetenceAmt_Control1130179; CompetenceAmt)
                    {
                    }
                    column(SubconCompetenceAmt_Control1130180; SubconCompetenceAmt)
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

                    trigger OnAfterGetRecord()
                    var
                        WorkCenter: Record "Work Center";
                    begin
                        ExpectedOpCostAmt := 0;
                        ExpectedSubconAmt := 0;
                        CompetenceAmt := 0;
                        SubconCompetenceAmt := 0;
                        CompetenceQty := 0;
                        CompetenceQty := ProdOrderLine."Finished Quantity" / ProdOrderLine.Quantity;
                        if Type = Type::"Work Center" then begin
                            WorkCenter.Get("Work Center No.");
                            if WorkCenter."Subcontractor No." = '' then begin
                                ExpectedOpCostAmt := "Expected Operation Cost Amt.";
                                CompetenceAmt := CompetenceQty * "Expected Operation Cost Amt.";
                            end else begin
                                ExpectedSubconAmt := "Expected Operation Cost Amt.";
                                SubconCompetenceAmt := CompetenceQty * "Expected Operation Cost Amt.";
                            end;
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        Clear(ExpectedOpCostAmt);
                        Clear(CompetenceAmt);
                        Clear(ExpectedSubconAmt);
                        Clear(SubconCompetenceAmt);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if PrevProdOrderNo = "Order No." then
                        CurrReport.Skip();
                    if not "Item Cost History"."Estimated WIP Consumption" then
                        CurrReport.Skip();
                    if not DisplayEstimatedCosts("Order No.", "Order Line No.") then
                        CurrReport.Skip();
                    PrevProdOrderNo := "Order No.";
                end;

                trigger OnPreDataItem()
                begin
                    PrevProdOrderNo := '';
                    SetRange("Posting Date", StartingDate, "Item Cost History"."Competence Year");
                end;
            }
            dataitem("LIFO Header"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(LIFO_Header_Number; Number)
                {
                }
                column(Expected_CostCaption_Control1130055; Expected_CostCaption_Control1130055Lbl)
                {
                }
                column(AmountCaption_Control1130057; AmountCaption_Control1130057Lbl)
                {
                }
                column(Competence_QuantityCaption_Control1130059; Competence_QuantityCaption_Control1130059Lbl)
                {
                }
                column(QuantityCaption_Control1130061; QuantityCaption_Control1130061Lbl)
                {
                }
                column(Posting_DateCaption_Control1130062; Posting_DateCaption_Control1130062Lbl)
                {
                }
                column(LIFOCaption; LIFOCaptionLbl)
                {
                }
                column(Document_No_Caption_Control1130118; Document_No_Caption_Control1130118Lbl)
                {
                }
            }
            dataitem("LIFOCost  BefStart"; "Before Start Item Cost")
            {
                DataItemLink = "Item No." = field("Item No.");
                DataItemTableView = sorting("Item No.", "Starting Date") order(ascending);
                column(LIFOCost__BefStart__Starting_Date_; Format("Starting Date"))
                {
                }
                column(Purchase_Quantity_____Production_Quantity_; "Purchase Quantity" + "Production Quantity")
                {
                }
                column(CompetenceQty_Control1130134; CompetenceQty)
                {
                }
                column(Before_Start_; Before_Start_Lbl)
                {
                }
                column(Amount; Amount)
                {
                }
                column(LIFOCost__BefStart_Item_No_; "Item No.")
                {
                }
                column(LIFOCost__BefStart_Starting_Date; "Starting Date")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if EndYearInv <= 0 then
                        CurrReport.Skip();
                    CompetenceQty := GetCompetenceQty("Purchase Quantity" + "Production Quantity");
                    Amount := ("Purchase Amount" + "Production Amount") * CompetenceQty / ("Purchase Quantity" + "Production Quantity");
                    TotalLIFOAmt += Amount;
                    EndYearInv -= "Production Quantity" + "Purchase Quantity";
                end;

                trigger OnPreDataItem()
                begin
                    if StartDateLIFO <> 0D then begin
                        StartDate := StartDateLIFO;
                        SetRange("Starting Date", StartDate, "Item Cost History"."Competence Year");
                    end else begin
                        StartDate := StartingDate;
                        SetRange("Starting Date", 0D, "Item Cost History"."Competence Year");
                    end;
                    EndYearInv := "Item Cost History"."End Year Inventory";
                end;
            }
            dataitem(LIFO; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("Item No.");
                DataItemTableView = sorting("Item No.", "Posting Date") order(ascending) where("Entry Type" = const(Output));
                column(LIFO__Document_No__; "Document No.")
                {
                }
                column(LIFO__Posting_Date_; Format("Posting Date"))
                {
                }
                column(LIFO_Quantity; Quantity)
                {
                }
                column(CompetenceQty_Control1130133; CompetenceQty)
                {
                }
                column(Amount_Control1130115; Amount)
                {
                }
                column(Showbody1; Item."Replenishment System" = Item."Replenishment System"::Purchase)
                {
                }
                column(LIFO_Entry_No_; "Entry No.")
                {
                }
                column(LIFO_Item_No_; "Item No.")
                {
                }

                trigger OnAfterGetRecord()
                var
                    CalcCostsRep: Report "Calculate End Year Costs";
                begin
                    if EndYearInv <= 0 then
                        CurrReport.Skip();
                    CompetenceQty := GetCompetenceQty(Quantity);
                    CalcCostsRep.SetStartDateAndRefDate("Item Cost History"."Competence Year");
                    Amount := CalcCostsRep.GetProdAmt(LIFO, false) * CompetenceQty / Quantity;
                    TotalLIFOAmt += Amount;
                    EndYearInv -= Quantity;
                end;

                trigger OnPreDataItem()
                begin
                    if Item."Replenishment System" = Item."Replenishment System"::Purchase then
                        CurrReport.Skip();
                    if StartDateLIFO <> 0D then
                        SetRange("Posting Date", StartDate, "Item Cost History"."Competence Year")
                    else
                        SetRange("Posting Date", 0D, "Item Cost History"."Competence Year");
                end;
            }
            dataitem("LIFO PURCH"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("Item No.");
                DataItemTableView = sorting("Item No.", "Posting Date") order(ascending) where("Entry Type" = const(Purchase));
                column(Amount_Control1130117; Amount)
                {
                }
                column(CompetenceQty_Control1130128; CompetenceQty)
                {
                }
                column(LIFO_PURCH_Quantity; Quantity)
                {
                }
                column(LIFO_PURCH__Posting_Date_; Format("Posting Date"))
                {
                }
                column(LIFO_PURCH__Document_No__; "Document No.")
                {
                }
                column(ExpLIFOAmt; ExpLIFOAmt)
                {
                }
                column(Showbody2; Item."Replenishment System" <> Item."Replenishment System"::Purchase)
                {
                }
                column(LIFO_PURCH_Entry_No_; "Entry No.")
                {
                }
                column(LIFO_PURCH_Item_No_; "Item No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Item."Replenishment System" <> Item."Replenishment System"::Purchase then
                        CurrReport.Skip();
                    if EndYearInv <= 0 then
                        CurrReport.Skip();
                    CompetenceQty := GetCompetenceQty(Quantity);

                    CalcFields("Purchase Amount (Actual)", "Purchase Amount (Expected)");
                    Amount := "Purchase Amount (Actual)" * CompetenceQty / Quantity;
                    TotalLIFOAmt += Amount;

                    ExpLIFOAmt := "Purchase Amount (Expected)" * CompetenceQty / Quantity;
                    TotalExpLIFOAmt += ExpLIFOAmt;

                    EndYearInv -= Quantity;
                end;

                trigger OnPreDataItem()
                begin
                    if Item."Replenishment System" <> Item."Replenishment System"::Purchase then
                        CurrReport.Skip();
                    if StartDateLIFO <> 0D then
                        SetRange("Posting Date", StartDateLIFO, "Item Cost History"."Competence Year")
                    else
                        SetRange("Posting Date", StartingDate, "Item Cost History"."Competence Year");
                    Clear(Amount);
                    Clear(ExpLIFOAmt);
                end;
            }
            dataitem("LIFO Footer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(Amount_Control1130204; TotalLIFOAmt)
                {
                }
                column(ExpLIFOAmt_Control1130208; TotalExpLIFOAmt)
                {
                }
                column(LIFO_Footer_Number; Number)
                {
                }
                column(TotalsCaption_Control1130205; TotalsCaption_Control1130205Lbl)
                {
                }
            }
            dataitem("FIFO Header"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(FIFO_Header_Number; Number)
                {
                }
                column(FIFOCaption; FIFOCaptionLbl)
                {
                }
                column(Document_No_Caption_Control1130095; Document_No_Caption_Control1130095Lbl)
                {
                }
                column(Posting_DateCaption_Control1130119; Posting_DateCaption_Control1130119Lbl)
                {
                }
                column(QuantityCaption_Control1130121; QuantityCaption_Control1130121Lbl)
                {
                }
                column(AmountCaption_Control1130123; AmountCaption_Control1130123Lbl)
                {
                }
                column(Expected_CostCaption_Control1130124; Expected_CostCaption_Control1130124Lbl)
                {
                }
                column(Competence_QuantityCaption_Control1130125; Competence_QuantityCaption_Control1130125Lbl)
                {
                }
            }
            dataitem(FIFO; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("Item No.");
                DataItemTableView = sorting("Item No.", "Posting Date") order(descending) where("Entry Type" = const(Output));
                column(FIFO__Document_No__; "Document No.")
                {
                }
                column(FIFO__Posting_Date_; Format("Posting Date"))
                {
                }
                column(FIFO_Quantity; Quantity)
                {
                }
                column(CompetenceQty_Control1130139; CompetenceQty)
                {
                }
                column(FIFOAmt; FIFOAmt)
                {
                }
                column(FIFO_Entry_No_; "Entry No.")
                {
                }
                column(FIFO_Item_No_; "Item No.")
                {
                }

                trigger OnAfterGetRecord()
                var
                    CalcCostsRep: Report "Calculate End Year Costs";
                begin
                    if EndYearInv <= 0 then
                        CurrReport.Skip();
                    CompetenceQty := GetCompetenceQty(Quantity);
                    CalcCostsRep.SetStartDateAndRefDate("Item Cost History"."Competence Year");
                    FIFOAmt := CalcCostsRep.GetProdAmt(FIFO, false) * CompetenceQty / Quantity;
                    TotalFIFOAmt += FIFOAmt;
                    EndYearInv -= Quantity;
                end;

                trigger OnPreDataItem()
                begin
                    if Item."Replenishment System" = Item."Replenishment System"::Purchase then
                        CurrReport.Skip();
                    SetRange("Posting Date", StartingDate, "Item Cost History"."Competence Year");
                    EndYearInv := "Item Cost History"."End Year Inventory";
                end;
            }
            dataitem("FIFO PURCH"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("Item No.");
                DataItemTableView = sorting("Item No.", "Posting Date") order(descending) where("Entry Type" = const(Purchase));
                column(FIFOAmt_Control1130141; FIFOAmt)
                {
                }
                column(CompetenceQty_Control1130142; CompetenceQty)
                {
                }
                column(FIFO_PURCH_Quantity; Quantity)
                {
                }
                column(FIFO_PURCH__Posting_Date_; Format("Posting Date"))
                {
                }
                column(FIFO_PURCH__Document_No__; "Document No.")
                {
                }
                column(ExpFIFOAmt; ExpFIFOAmt)
                {
                }
                column(FIFO_PURCH_Entry_No_; "Entry No.")
                {
                }
                column(FIFO_PURCH_Item_No_; "Item No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if EndYearInv <= 0 then
                        CurrReport.Skip();
                    CompetenceQty := GetCompetenceQty(Quantity);

                    CalcFields("Purchase Amount (Actual)", "Purchase Amount (Expected)");
                    FIFOAmt := "Purchase Amount (Actual)" * CompetenceQty / Quantity;
                    TotalFIFOAmt += FIFOAmt;

                    ExpFIFOAmt := "Purchase Amount (Expected)" * CompetenceQty / Quantity;
                    TotalExpFIFOAmt += ExpFIFOAmt;

                    EndYearInv -= Quantity;
                end;

                trigger OnPreDataItem()
                begin
                    if Item."Replenishment System" <> Item."Replenishment System"::Purchase then
                        CurrReport.Skip();
                    SetCurrentKey("Item No.", "Posting Date");
                    SetRange("Posting Date", StartingDate, "Item Cost History"."Competence Year");
                    EndYearInv := "Item Cost History"."End Year Inventory";
                end;
            }
            dataitem("FIFOCost BefStart"; "Before Start Item Cost")
            {
                DataItemLink = "Item No." = field("Item No.");
                DataItemTableView = sorting("Item No.", "Starting Date") order(descending);
                column(CompetenceQty_Control1130135; CompetenceQty)
                {
                }
                column(Purchase_Quantity_____Production_Quantity__Control1130136; "Purchase Quantity" + "Production Quantity")
                {
                }
                column(FIFOCost_BefStart__Starting_Date_; Format("Starting Date"))
                {
                }
                column(Before_Start__Control1130103; Before_Start_Lbl)
                {
                }
                column(FIFOAmt_Control1130114; FIFOAmt)
                {
                }
                column(FIFOCost_BefStart_Item_No_; "Item No.")
                {
                }
                column(FIFOCost_BefStart_Starting_Date; "Starting Date")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if EndYearInv <= 0 then
                        CurrReport.Skip();
                    CompetenceQty := GetCompetenceQty("Purchase Quantity" + "Production Quantity");
                    FIFOAmt := ("Purchase Amount" + "Production Amount") * CompetenceQty / ("Purchase Quantity" + "Production Quantity");
                    TotalFIFOAmt += FIFOAmt;
                    EndYearInv -= "Production Quantity" + "Purchase Quantity";
                end;
            }
            dataitem("FIFO Footer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(FIFOAmt_Control1130091; TotalFIFOAmt)
                {
                }
                column(ExpFIFOAmt_Control1130156; TotalExpFIFOAmt)
                {
                }
                column(FIFO_Footer_Number; Number)
                {
                }
                column(TotalsCaption_Control1130108; TotalsCaption_Control1130108Lbl)
                {
                }
            }
            dataitem(Summary; "Item Cost History")
            {
                DataItemLink = "Item No." = field("Item No."), "Competence Year" = field("Competence Year");
                DataItemTableView = sorting("Item No.", "Competence Year");
                column(Summary__Start_Year_Inventory_; "Start Year Inventory")
                {
                }
                column(Summary__End_Year_Inventory_; "End Year Inventory")
                {
                }
                column(Summary__Purchase_Quantity_; "Purchase Quantity")
                {
                }
                column(Summary__Purchase_Amount_; "Purchase Amount")
                {
                }
                column(Summary__Production_Quantity_; "Production Quantity")
                {
                }
                column(Summary__Production_Amount_; "Production Amount")
                {
                }
                column(FIFO_Cost____End_Year_Inventory_; "FIFO Cost" * "End Year Inventory")
                {
                }
                column(LIFO_Cost___End_Year_Inventory_; "LIFO Cost" * "End Year Inventory")
                {
                }
                column(ItemCostHistory__Weighted_Average_Cost___Start_Year_Inventory_; ItemCostHistory."Weighted Average Cost" * "Start Year Inventory")
                {
                }
                column(Summary_Item_No_; "Item No.")
                {
                }
                column(Summary_Competence_Year; "Competence Year")
                {
                }
                column(Summary__Start_Year_Inventory_Caption; FieldCaption("Start Year Inventory"))
                {
                }
                column(Summary__End_Year_Inventory_Caption; FieldCaption("End Year Inventory"))
                {
                }
                column(Summary__Purchase_Quantity_Caption; FieldCaption("Purchase Quantity"))
                {
                }
                column(Summary__Purchase_Amount_Caption; FieldCaption("Purchase Amount"))
                {
                }
                column(Summary__Production_Quantity_Caption; FieldCaption("Production Quantity"))
                {
                }
                column(Summary__Production_Amount_Caption; FieldCaption("Production Amount"))
                {
                }
                column(FIFO_AmountCaption; FIFO_AmountCaptionLbl)
                {
                }
                column(LIFO_AmountCaption; LIFO_AmountCaptionLbl)
                {
                }
                column(SummaryCaption; SummaryCaptionLbl)
                {
                }
                column(Start_Year_AmountCaption; Start_Year_AmountCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                var
                    AccountingPeriod: Record "Accounting Period";
                    LastFiscalYearEndDate: Date;
                begin
                    AccountingPeriod.Reset();
                    AccountingPeriod.SetRange("New Fiscal Year", true);
                    AccountingPeriod.SetFilter("Starting Date", '<=%1', "Item Cost History"."Competence Year");
                    if AccountingPeriod.FindLast() then
                        LastFiscalYearEndDate := AccountingPeriod."Starting Date" - 1;
                    if ItemCostHistory.Get("Item Cost History"."Item No.", LastFiscalYearEndDate) then;
                end;
            }
            dataitem(Summary1; "Item Cost History")
            {
                DataItemLink = "Item No." = field("Item No."), "Competence Year" = field("Competence Year");
                DataItemTableView = sorting("Item No.", "Competence Year");
                column(Summary1__FIFO_Cost_; "FIFO Cost")
                {
                }
                column(Summary1__LIFO_Cost_; "LIFO Cost")
                {
                }
                column(Summary1__Year_Average_Cost_; "Year Average Cost")
                {
                }
                column(Summary1__Weighted_Average_Cost_; "Weighted Average Cost")
                {
                }
                column(Summary1_Item_No_; "Item No.")
                {
                }
                column(Summary1_Competence_Year; "Competence Year")
                {
                }
                column(Summary1__FIFO_Cost_Caption; FieldCaption("FIFO Cost"))
                {
                }
                column(Summary1__LIFO_Cost_Caption; FieldCaption("LIFO Cost"))
                {
                }
                column(Summary1__Year_Average_Cost_Caption; FieldCaption("Year Average Cost"))
                {
                }
                column(Summary1__Weighted_Average_Cost_Caption; FieldCaption("Weighted Average Cost"))
                {
                }
            }

            trigger OnAfterGetRecord()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
                EndYearInv: Decimal;
            begin
                TotalLIFOAmt := 0;
                TotalExpLIFOAmt := 0;
                TotalFIFOAmt := 0;
                TotalExpFIFOAmt := 0;
                StartingDate := DMY2Date(1, 1, Date2DMY("Competence Year", 3));
                Item.Get("Item No.");
                ItemLedgEntry.Reset();
                ItemLedgEntry.SetCurrentKey("Item No.", "Posting Date");
                ItemLedgEntry.SetRange("Item No.", "Item No.");
                ItemLedgEntry.SetRange("Posting Date", 0D, "Competence Year");
                ItemLedgEntry.SetFilter("Entry Type", '<>%1', ItemLedgEntry."Entry Type"::Transfer);
                if ItemLedgEntry.FindSet() then
                    repeat
                        EndYearInv += ItemLedgEntry.Quantity;
                        if EndYearInv <= 0 then
                            StartDateLIFO := ItemLedgEntry."Posting Date";
                    until ItemLedgEntry.Next() = 0;
            end;
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
        ProdOrderLine: Record "Prod. Order Line";
        ItemCostHistory: Record "Item Cost History";
        PrevProdOrderNo: Code[20];
        StartingDate: Date;
        StartDateLIFO: Date;
        StartDate: Date;
        ConsumeQty: Decimal;
        RoutingQty: Decimal;
        FIFOAmt: Decimal;
        ExpLIFOAmt: Decimal;
        ExpFIFOAmt: Decimal;
        EndYearInv: Decimal;
        UnitCost: Decimal;
        CompetenceQty: Decimal;
        RoutingAmt: Decimal;
        Amount: Decimal;
        CompetenceAmt: Decimal;
        SubconCompetenceAmt: Decimal;
        ExpectedOpCostAmt: Decimal;
        ExpectedSubconAmt: Decimal;
        ComponentsAmt: Decimal;
        ExpectedQty: Decimal;
        TotalLIFOAmt: Decimal;
        TotalExpLIFOAmt: Decimal;
        TotalFIFOAmt: Decimal;
        TotalExpFIFOAmt: Decimal;
        Ledger_Entries_DetailCaptionLbl: Label 'Ledger Entries Detail';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Purchases__Posting_Date_CaptionLbl: Label 'Posting Date';
        AmountCaptionLbl: Label 'Amount';
        Expected_CostCaptionLbl: Label 'Expected Cost';
        PurchasesCaptionLbl: Label 'Purchases';
        TotalsCaptionLbl: Label 'Totals';
        Production_OutputCaptionLbl: Label 'Production Output';
        Production_Output__Posting_Date_CaptionLbl: Label 'Posting Date';
        Output_QuantityCaptionLbl: Label 'Output Quantity';
        TotalsCaption_Control1130033Lbl: Label 'Totals';
        Posting_DateCaptionLbl: Label 'Posting Date';
        QuantityCaptionLbl: Label 'Quantity';
        Competence_QuantityCaptionLbl: Label 'Competence Quantity';
        Unit_CostCaptionLbl: Label 'Unit Cost';
        Components_AmountCaptionLbl: Label 'Components Amount';
        Production_ConsumptionCaptionLbl: Label 'Production Consumption';
        TotalsCaption_Control1130097Lbl: Label 'Totals';
        Components_AmountCaption_Control1130191Lbl: Label 'Components Amount';
        Competence_AmountCaptionLbl: Label 'Competence Amount';
        Production_ConsumptionCaption_Control1130194Lbl: Label 'Production Consumption';
        Expected_QuantityCaptionLbl: Label 'Expected Quantity';
        TotalsCaption_Control1130199Lbl: Label 'Totals';
        Competence_AmountCaption_Control1130152Lbl: Label 'Competence Amount';
        Unit_CostCaption_Control1130153Lbl: Label 'Unit Cost';
        Production_RoutingCaptionLbl: Label 'Production Routing';
        Competence_QuantityCaption_Control1130138Lbl: Label 'Competence Quantity';
        Production_Routing__Posting_Date_CaptionLbl: Label 'Posting Date';
        QuantityCaption_Control1130171Lbl: Label 'Quantity';
        Subcontracting_Competence_AmountCaptionLbl: Label 'Subcontracting Competence Amount';
        TotalsCaption_Control1130049Lbl: Label 'Totals';
        Expected_Operation_Cost_Amt_CaptionLbl: Label 'Expected Operation Cost Amt.';
        Expected_Subcontracting_AmountCaptionLbl: Label 'Expected Subcontracting Amount';
        Competence_Operation_Cost_AmountCaptionLbl: Label 'Competence Operation Cost Amount';
        Competence_Subcontracting_AmountCaptionLbl: Label 'Competence Subcontracting Amount';
        Production_RoutingCaption_Control1130182Lbl: Label 'Production Routing';
        TotalsCaption_Control1130181Lbl: Label 'Totals';
        Expected_CostCaption_Control1130055Lbl: Label 'Expected Cost';
        AmountCaption_Control1130057Lbl: Label 'Amount';
        Competence_QuantityCaption_Control1130059Lbl: Label 'Competence Quantity';
        QuantityCaption_Control1130061Lbl: Label 'Quantity';
        Posting_DateCaption_Control1130062Lbl: Label 'Posting Date';
        LIFOCaptionLbl: Label 'LIFO', Comment = 'Short for Last In Last Out';
        Document_No_Caption_Control1130118Lbl: Label 'Document No.';
        Before_Start_Lbl: Label 'Before Start';
        TotalsCaption_Control1130205Lbl: Label 'Totals';
        FIFOCaptionLbl: Label 'FIFO', Comment = 'short for First In First Out';
        Document_No_Caption_Control1130095Lbl: Label 'Document No.';
        Posting_DateCaption_Control1130119Lbl: Label 'Posting Date';
        QuantityCaption_Control1130121Lbl: Label 'Quantity';
        AmountCaption_Control1130123Lbl: Label 'Amount';
        Expected_CostCaption_Control1130124Lbl: Label 'Expected Cost';
        Competence_QuantityCaption_Control1130125Lbl: Label 'Competence Quantity';
        TotalsCaption_Control1130108Lbl: Label 'Totals';
        FIFO_AmountCaptionLbl: Label 'FIFO Amount';
        LIFO_AmountCaptionLbl: Label 'LIFO Amount';
        SummaryCaptionLbl: Label 'Summary';
        Start_Year_AmountCaptionLbl: Label 'Start Year Amount';

    [Scope('OnPrem')]
    procedure DisplayEstimatedCosts(ProdOrderNo: Code[20]; ProdOrdLineNo: Integer): Boolean
    var
        ItemCostingSetup: Record "Item Costing Setup";
    begin
        ItemCostingSetup.Get();
        if ItemCostingSetup."Estimated WIP Consumption" then begin
            if ProdOrderLineExist(ProdOrderNo, ProdOrdLineNo) then begin
                if (ProdOrderLine.Status = ProdOrderLine.Status::Finished) or
                   (ProdOrderLine."Finished Quantity" >= ProdOrderLine.Quantity)
                then
                    exit(false);
                exit(true);
            end;
        end else begin
            if ProdOrderLineExist(ProdOrderNo, ProdOrdLineNo) then;
            exit(false);
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcProdOrderOutput(ProdOrderNo: Code[20]): Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Entry Type", "Order Type", "Order No.", "Posting Date");
        ItemLedgEntry.SetRange("Posting Date", StartingDate, "Item Cost History"."Competence Year");
        ItemLedgEntry.SetRange("Order No.", ProdOrderNo);
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Output);
        ItemLedgEntry.CalcSums(Quantity);
        exit(ItemLedgEntry.Quantity);
    end;

    [Scope('OnPrem')]
    procedure GetCompetenceQty(Quantity: Decimal): Decimal
    begin
        if EndYearInv > Quantity then
            exit(Quantity);
        exit(EndYearInv);
    end;

    [Scope('OnPrem')]
    procedure ProdOrderLineExist(ProdOrderNo: Code[20]; ProdOrderLineNo: Integer): Boolean
    begin
        ProdOrderLine.Reset();
        ProdOrderLine.SetCurrentKey("Prod. Order No.", "Line No.");
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.SetRange("Line No.", ProdOrderLineNo);
        exit(ProdOrderLine.FindFirst())
    end;
}

