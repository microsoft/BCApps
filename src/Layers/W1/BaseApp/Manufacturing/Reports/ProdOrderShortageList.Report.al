// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;

report 99000788 "Prod. Order - Shortage List"
{
    DefaultRenderingLayout = Word;
    ApplicationArea = Manufacturing;
    Caption = 'Prod. Order - Shortage List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Production Order"; "Production Order")
        {
            DataItemTableView = sorting(Status, "No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = Status, "No.", "Date Filter";
            column(Status_ProdOrder; Status)
            {
                IncludeCaption = false;
            }
            column(No_ProdOrder; "No.")
            {
                IncludeCaption = true;
            }
            column(Desc_ProdOrder; Description)
            {
                IncludeCaption = true;
            }
            column(DueDate_ProdOrder; Format("Due Date"))
            {
            }
#if not CLEAN27
            column(TodayFormatted; Format(Today, 0, 4))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(ShortageListCaption; ShortageListCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(DueDateCaption; DueDateCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(NeededQtyCaption; NeededQtyCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(CompItemScheduledNeedQtyCaption; CompItemScheduledNeedQtyCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(CompItemInventoryCaption; CompItemInventoryCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(RemainingQtyBaseCaption; RemainingQtyBaseCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(RemQtyBaseCaption; RemQtyBaseCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(ReceiptQtyCaption; ReceiptQtyCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(QtyonPurchOrderCaption; QtyonPurchOrderCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(QtyonSalesOrderCaption; QtyonSalesOrderCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
#endif
            dataitem("Prod. Order Line"; "Prod. Order Line")
            {
                DataItemLink = Status = field(Status), "Prod. Order No." = field("No.");
                DataItemTableView = sorting(Status, "Prod. Order No.", "Line No.");
                PrintOnlyIfDetail = true;
                column(LineNo_ProdOrderLine; "Line No.")
                {
                    IncludeCaption = true;
                }
                dataitem("Prod. Order Component"; "Prod. Order Component")
                {
                    DataItemLink = Status = field(Status), "Prod. Order No." = field("Prod. Order No."), "Prod. Order Line No." = field("Line No.");
                    DataItemTableView = sorting(Status, "Item No.", "Variant Code", "Location Code", "Due Date");
                    column(CompItemInventory; CompItem.Inventory)
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(CompItemSchdldNeedQty; CompItem."Qty. on Component Lines")
                    {
                        DecimalPlaces = 0 : 5;
                        IncludeCaption = true;
                    }
                    column(NeededQuantity; NeededQty)
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(ItemNo_ProdOrderComp; "Item No.")
                    {
                        IncludeCaption = true;
                    }
                    column(CompItemInvRemQtyBase; QtyOnHandAfterProd)
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(Desc_ProdOrderComp; Description)
                    {
                        IncludeCaption = true;
                    }
                    column(CompItemSchdldRcptQty; CompItem."Scheduled Receipt (Qty.)")
                    {
                        DecimalPlaces = 0 : 5;
                        IncludeCaption = true;
                    }
                    column(CompItemQtyonPurchOrder; CompItem."Qty. on Purch. Order")
                    {
                        DecimalPlaces = 0 : 5;
                        IncludeCaption = true;
                    }
                    column(CompItemQtyonSalesOrder; CompItem."Qty. on Sales Order")
                    {
                        DecimalPlaces = 0 : 5;
                        IncludeCaption = true;
                    }
                    column(RemQtyBase_ProdOrderComp; RemainingQty)
                    {
                        DecimalPlaces = 0 : 5;
                    }

                    trigger OnAfterGetRecord()
                    var
                        TempProdOrderLine: Record "Prod. Order Line" temporary;
                        TempProdOrderComp: Record "Prod. Order Component" temporary;
                    begin
                        SetRange("Item No.", "Item No.");
                        SetRange("Variant Code", "Variant Code");
                        SetRange("Location Code", "Location Code");
                        FindLast();
                        SetRange("Item No.");
                        SetRange("Variant Code");
                        SetRange("Location Code");

                        CompItem.Get("Item No.");
                        if CompItem.IsNonInventoriableType() then
                            CurrReport.Skip();

                        CompItem.SetRange("Variant Filter", "Variant Code");
                        CompItem.SetRange("Location Filter", "Location Code");
                        CompItem.SetRange(
                          "Date Filter", 0D, "Due Date" - 1);

                        CompItem.CalcFields(
                          Inventory, "Reserved Qty. on Inventory",
                          "Scheduled Receipt (Qty.)", "Reserved Qty. on Prod. Order",
                          "Qty. on Component Lines", "Res. Qty. on Prod. Order Comp.");
                        CompItem.Inventory :=
                          CompItem.Inventory -
                          CompItem."Reserved Qty. on Inventory";
                        CompItem."Scheduled Receipt (Qty.)" :=
                          CompItem."Scheduled Receipt (Qty.)" -
                          CompItem."Reserved Qty. on Prod. Order";
                        CompItem."Qty. on Component Lines" :=
                          CompItem."Qty. on Component Lines" -
                          CompItem."Res. Qty. on Prod. Order Comp.";

                        CompItem.SetRange(
                          "Date Filter", 0D, "Due Date");
                        CompItem.CalcFields(
                          "Qty. on Sales Order", "Reserved Qty. on Sales Orders",
                          "Qty. on Purch. Order", "Reserved Qty. on Purch. Orders");
                        CompItem."Qty. on Sales Order" :=
                          CompItem."Qty. on Sales Order" -
                          CompItem."Reserved Qty. on Sales Orders";
                        CompItem."Qty. on Purch. Order" :=
                          CompItem."Qty. on Purch. Order" -
                          CompItem."Reserved Qty. on Purch. Orders";

                        TempProdOrderLine.SetCurrentKey(
                          "Item No.", "Variant Code", "Location Code", Status, "Ending Date");

                        TempProdOrderLine.SetRange(Status, TempProdOrderLine.Status::Planned, Status.AsInteger() - 1);
                        TempProdOrderLine.SetRange("Item No.", "Item No.");
                        TempProdOrderLine.SetRange("Variant Code", "Variant Code");
                        TempProdOrderLine.SetRange("Location Code", "Location Code");
                        TempProdOrderLine.SetRange("Due Date", "Due Date");
                        CalcProdOrderLineFields(TempProdOrderLine);
                        CompItem."Scheduled Receipt (Qty.)" :=
                          CompItem."Scheduled Receipt (Qty.)" +
                          TempProdOrderLine."Remaining Qty. (Base)" -
                          TempProdOrderLine."Reserved Qty. (Base)";

                        TempProdOrderLine.SetRange(Status, Status);
                        TempProdOrderLine.SetRange("Prod. Order No.", "Prod. Order No.");
                        CalcProdOrderLineFields(TempProdOrderLine);
                        CompItem."Scheduled Receipt (Qty.)" :=
                          CompItem."Scheduled Receipt (Qty.)" +
                          TempProdOrderLine."Remaining Qty. (Base)" -
                          TempProdOrderLine."Reserved Qty. (Base)";

                        TempProdOrderComp.SetCurrentKey(
                          "Item No.", "Variant Code", "Location Code", Status, "Due Date");

                        TempProdOrderComp.SetRange(Status, TempProdOrderComp.Status::Planned, Status.AsInteger() - 1);
                        TempProdOrderComp.SetRange("Item No.", "Item No.");
                        TempProdOrderComp.SetRange("Variant Code", "Variant Code");
                        TempProdOrderComp.SetRange("Location Code", "Location Code");
                        TempProdOrderComp.SetRange("Due Date", "Due Date");
                        CalcProdOrderCompFields(TempProdOrderComp);
                        CompItem."Qty. on Component Lines" :=
                          CompItem."Qty. on Component Lines" +
                          TempProdOrderComp."Remaining Qty. (Base)" -
                          TempProdOrderComp."Reserved Qty. (Base)";

                        TempProdOrderComp.SetRange(Status, Status);
                        TempProdOrderComp.SetFilter("Prod. Order No.", '<%1', "Prod. Order No.");
                        CalcProdOrderCompFields(TempProdOrderComp);
                        CompItem."Qty. on Component Lines" :=
                          CompItem."Qty. on Component Lines" +
                          TempProdOrderComp."Remaining Qty. (Base)" -
                          TempProdOrderComp."Reserved Qty. (Base)";

                        TempProdOrderComp.SetRange("Prod. Order No.", "Prod. Order No.");
                        TempProdOrderComp.SetRange("Prod. Order Line No.", 0, "Prod. Order Line No." - 1);
                        CalcProdOrderCompFields(TempProdOrderComp);
                        CompItem."Qty. on Component Lines" :=
                          CompItem."Qty. on Component Lines" +
                          TempProdOrderComp."Remaining Qty. (Base)" -
                          TempProdOrderComp."Reserved Qty. (Base)";

                        TempProdOrderComp.SetRange("Prod. Order Line No.", "Prod. Order Line No.");
                        TempProdOrderComp.SetRange("Item No.", "Item No.");
                        TempProdOrderComp.SetRange("Variant Code", "Variant Code");
                        TempProdOrderComp.SetRange("Location Code", "Location Code");
                        CalcProdOrderCompFields(TempProdOrderComp);
                        CompItem."Qty. on Component Lines" :=
                          CompItem."Qty. on Component Lines" +
                          TempProdOrderComp."Remaining Qty. (Base)" -
                          TempProdOrderComp."Reserved Qty. (Base)";

                        RemainingQty :=
                          TempProdOrderComp."Remaining Qty. (Base)" -
                          TempProdOrderComp."Reserved Qty. (Base)";

                        QtyOnHandAfterProd :=
                          CompItem.Inventory -
                          TempProdOrderComp."Remaining Qty. (Base)" +
                          TempProdOrderComp."Reserved Qty. (Base)";

                        NeededQty :=
                          CompItem."Qty. on Component Lines" +
                          CompItem."Qty. on Sales Order" -
                          CompItem."Qty. on Purch. Order" -
                          CompItem."Scheduled Receipt (Qty.)" -
                          CompItem.Inventory;

                        if NeededQty < 0 then
                            NeededQty := 0;

                        if (NeededQty = 0) and (QtyOnHandAfterProd >= 0) or
                           (RemainingQty = 0)
                        then
                            CurrReport.Skip();
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Due Date", "Production Order".GetFilter("Date Filter"));
                        SetFilter("Remaining Qty. (Base)", '>0');
                    end;
                }
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Prod. Order - Shortage List';
        AboutText = 'Details out your component requirements and whether there will be any stock shortages at the time of consumption. Use it to review potential stock shortages & plan accordingly to prevent any delays in production.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Visible = false;
                    Caption = 'Options';
                    field(PostingDateFilter; PostingDateFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date Filter';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            PostingDateFilter := "Production Order".GetFilter("Date Filter");
        end;
    }

    rendering
    {
        layout(Word)
        {
            Caption = 'Prod. Order - Shortage List Word';
            Type = Word;
            LayoutFile = './Manufacturing/Reports/ProdOrderShortageList.docx';
        }
        layout(Excel)
        {
            Caption = 'Prod. Order - Shortage List Excel';
            Type = Excel;
            LayoutFile = './Manufacturing/Reports/ProdOrderShortageList.xlsx';
        }
#if not CLEAN27
        layout(RDLC)
        {
            Caption = 'Prod. Order - Shortage List RDLC';
            Type = RDLC;
            LayoutFile = './Manufacturing/Reports/ProdOrderShortageList.rdlc';
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by the Excel layout and will be removed in a future release.';
            ObsoleteTag = '27.0';
        }
#endif
    }

    labels
    {
        DataRetrieved = 'Data retrieved:';
        ProdShtgList = 'Shortage List';
        ProdShtgListPrint = 'Prod. Shtg. List (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        ProdShtgListAnalysis = 'Prod. Shtg. List (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        PostingDateFilterLabel = 'Posting Date Filter:';
        // About the report labels
        AboutTheReportLabel = 'About the report', MaxLength = 31, Comment = 'Excel worksheet name.';
        EnvironmentLabel = 'Environment';
        CompanyLabel = 'Company';
        UserLabel = 'User';
        RunOnLabel = 'Run on';
        ReportNameLabel = 'Report name';
        DocumentationLabel = 'Documentation';
        Status_ProdOrderCaption = 'Status';
        StatusCaptionLbl = 'Status';
        NoCaptionLbl = 'Production Order No.';
        DescCaptionLbl = 'Description';
        ItemNoCaptionLbl = 'Item No.';
        ItemDescCaptionLbl = 'Item Description';
        LineNoCaptionLbl = 'Line No.';
        PageNoCaptionLbl = 'Page';
        DueDateCaptionLbl = 'Due Date';
        NeededQtyCaptionLbl = 'Needed Quantity';
        CompItemScheduledNeedQtyCaptionLbl = 'Scheduled Need';
        CompItemInventoryCaptionLbl = 'Quantity on Hand';
        RemainingQtyBaseCaptionLbl = 'Qty. on Hand after Production';
        RemQtyBaseCaptionLbl = 'Remaining Qty. (Base)';
        ReceiptQtyCaptionLbl = 'Scheduled Receipt';
        QtyonPurchOrderCaptionLbl = 'Qty. on Purch. Order';
        QtyonSalesOrderCaptionLbl = 'Qty. on Sales Order';
    }

    var
        CompItem: Record Item;
        RemainingQty: Decimal;
        NeededQty: Decimal;
        QtyOnHandAfterProd: Decimal;
        PostingDateFilter: Text;
#if not CLEAN27
        ShortageListCaptionLbl: Label 'Shortage List';
        PageNoCaptionLbl: Label 'Page';
        DueDateCaptionLbl: Label 'Due Date';
        NeededQtyCaptionLbl: Label 'Needed Quantity';
        CompItemScheduledNeedQtyCaptionLbl: Label 'Scheduled Need';
        CompItemInventoryCaptionLbl: Label 'Quantity on Hand';
        RemainingQtyBaseCaptionLbl: Label 'Qty. on Hand after Production';
        RemQtyBaseCaptionLbl: Label 'Remaining Qty. (Base)';
        ReceiptQtyCaptionLbl: Label 'Scheduled Receipt';
        QtyonPurchOrderCaptionLbl: Label 'Qty. on Purch. Order';
        QtyonSalesOrderCaptionLbl: Label 'Qty. on Sales Order';
#endif

    local procedure CalcProdOrderLineFields(var ProdOrderLineFields: Record "Prod. Order Line")
    var
        ProdOrderLine: Record "Prod. Order Line";
        RemainingQtyBase: Decimal;
        ReservedQtyBase: Decimal;
    begin
        ProdOrderLine.Copy(ProdOrderLineFields);

        if ProdOrderLine.FindSet() then
            repeat
                ProdOrderLine.CalcFields("Reserved Qty. (Base)");
                RemainingQtyBase += ProdOrderLine."Remaining Qty. (Base)";
                ReservedQtyBase += ProdOrderLine."Reserved Qty. (Base)";
            until ProdOrderLine.Next() = 0;

        ProdOrderLineFields."Remaining Qty. (Base)" := RemainingQtyBase;
        ProdOrderLineFields."Reserved Qty. (Base)" := ReservedQtyBase;
    end;

    local procedure CalcProdOrderCompFields(var ProdOrderCompFields: Record "Prod. Order Component")
    var
        ProdOrderComp: Record "Prod. Order Component";
        RemainingQtyBase: Decimal;
        ReservedQtyBase: Decimal;
    begin
        ProdOrderComp.Copy(ProdOrderCompFields);

        if ProdOrderComp.FindSet() then
            repeat
                ProdOrderComp.CalcFields("Reserved Qty. (Base)");
                RemainingQtyBase += ProdOrderComp."Remaining Qty. (Base)";
                ReservedQtyBase += ProdOrderComp."Reserved Qty. (Base)";
            until ProdOrderComp.Next() = 0;

        ProdOrderCompFields."Remaining Qty. (Base)" := RemainingQtyBase;
        ProdOrderCompFields."Reserved Qty. (Base)" := ReservedQtyBase;
    end;
}

