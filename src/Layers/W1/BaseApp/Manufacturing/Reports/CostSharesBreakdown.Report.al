// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using System.Utilities;

report 5848 "Cost Shares Breakdown"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Manufacturing/Reports/CostSharesBreakdown.rdlc';
    ApplicationArea = Manufacturing;
    Caption = 'Cost Shares Breakdown';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = where(Type = const(Inventory));
            RequestFilterFields = "No.", "Inventory Posting Group";
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("No.");
                DataItemTableView = sorting("Item No.");

                trigger OnAfterGetRecord()
                begin
                    CalcRemainingQty("Item Ledger Entry");
                    if RemainingQty = 0 then
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    if EndDate <> 0D then begin
                        SetRange("Posting Date", 0D, EndDate);
                        SetRange("Drop Shipment", false);
                    end;

                    if Find('-') then begin
                        SetRange("Posting Date");
                        SetRange("Drop Shipment");
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Costing Method" = "Costing Method"::Average then
                    CurrReport.Skip();
            end;
        }
        dataitem("Production Order"; "Production Order")
        {
            DataItemTableView = where(Status = filter(Released ..));
            dataitem("Capacity Ledger Entry"; "Capacity Ledger Entry")
            {
                DataItemLink = "Order No." = field("No.");
                DataItemTableView = sorting("Order Type", "Order No.", "Order Line No.") where("Order Type" = const(Production));

                trigger OnAfterGetRecord()
                begin
                    InsertCapLedgEntryCostShare("Capacity Ledger Entry");
                end;

                trigger OnPreDataItem()
                begin
                    if EndDate <> 0D then
                        SetRange("Posting Date", StartDate, EndDate)
                    else
                        SetFilter("Posting Date", '>=%1', StartDate);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if CostSharePrint <> CostSharePrint::"WIP Inventory" then
                    CurrReport.Break();
            end;
        }
        dataitem(PrintHeader; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            PrintOnlyIfDetail = true;
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CostSharePrint; CostSharePrint)
            {
                OptionCaption = 'Sales,Inventory,WIP Inventory';
                OptionMembers = Sales,Inventory,"WIP Inventory";
            }
            column(TableCaptionItemFilter; Item.TableCaption + ': ' + ItemFilter)
            {
            }
            column(TableCaptionProdOrderFilter; "Production Order".TableCaption + ': ' + ProdOrderFilter)
            {
            }
            column(ProdOrderFilter; ProdOrderFilter)
            {
            }
            column(Number_PrintHeader; Number)
            {
            }
            column(FdCaptSubcontracted; TempCostShareBuffer.FieldCaption(Subcontracted))
            {
            }
            column(CostShareBufNewMaterial; TempCostShareBuffer."New Material")
            {
            }
            column(CostShareBufNewCapacity; TempCostShareBuffer."New Capacity")
            {
            }
            column(CostShareBufNewCapOverhd; TempCostShareBuffer."New Capacity Overhead")
            {
            }
            column(CostShareBufNewMatrlOverhd; TempCostShareBuffer."New Material Overhead")
            {
            }
            column(Subcontracted; TempCostShareBuffer."New Subcontracted")
            {
            }
            column(CostShareBufNewVar; TempCostShareBuffer."New Variance")
            {
            }
            column(CostShareBufNewRevaluation; TempCostShareBuffer."New Revaluation")
            {
            }
            column(CostShareBufNewRounding; TempCostShareBuffer."New Rounding")
            {
            }
            column(Total; TempCostShareBuffer."New Direct Cost" + TempCostShareBuffer."New Indirect Cost" + TempCostShareBuffer."New Revaluation" + TempCostShareBuffer."New Rounding" + TempCostShareBuffer."New Variance")
            {
            }
            column(CostShareBufNewPurchaseVar; TempCostShareBuffer."New Purchase Variance")
            {
            }
            column(CostShareBufNewMaterialVar; TempCostShareBuffer."New Material Variance")
            {
            }
            column(CostShareBufNewCpctyVar; TempCostShareBuffer."New Capacity Variance")
            {
            }
            column(CostShareBufNewCapOverHdVar; TempCostShareBuffer."New Capacity Overhead Variance")
            {
            }
            column(CostShareBufNewMfgOverheadVar; TempCostShareBuffer."New Mfg. Overhead Variance")
            {
            }
            column(NewSubcontracted; TempCostShareBuffer."New Subcontracted Variance")
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(CostShareBufDocumentNoCaption; CostShareBufDocumentNoCaptionLbl)
            {
            }
            column(CostShareBufDescriptionCaption; CostShareBufDescriptionCaptionLbl)
            {
            }
            column(CostShareBufNewQuantityCaption; CostShareBufNewQuantityCaptionLbl)
            {
            }
            column(CostShareBufNewMatrlCaption; CostShareBufNewMatrlCaptionLbl)
            {
            }
            column(CapacityDirCostAppCaption; CapacityDirCostAppCaptionLbl)
            {
            }
            column(CapacityOverheadCaption; CapacityOverheadCaptionLbl)
            {
            }
            column(MaterialOverheadCaption; MaterialOverheadCaptionLbl)
            {
            }
            column(VarianceCaption; VarianceCaptionLbl)
            {
            }
            column(RevaluationCaption; RevaluationCaptionLbl)
            {
            }
            column(RoundingCaption; RoundingCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(VarBreakdownCaption; VarBreakdownCaptionLbl)
            {
            }
            dataitem(PrintInvtCostShareBuf; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(CostShareBufDescription; TempCostShareBuffer.Description)
                {
                }
                column(CostShareBufItemNo; TempCostShareBuffer."Item No.")
                {
                }
                column(Number_PrntInvtCostSharBufNo; Number)
                {
                }
                column(ShowDetails; ShowDetails)
                {
                }
                column(TotalPrintInvtCostShareBuf; TempCostShareBuffer."New Direct Cost" + TempCostShareBuffer."New Indirect Cost" + TempCostShareBuffer."New Revaluation" + TempCostShareBuffer."New Rounding" + TempCostShareBuffer."New Variance")
                {
                }
                column(CostShareBufDocumentNo; TempCostShareBuffer."Document No.")
                {
                }
                column(NewMatrl_PrintInvCstShrBuf; TempCostShareBuffer."New Material")
                {
                }
                column(NewCap_PrintInvCstShrBuf; TempCostShareBuffer."New Capacity")
                {
                }
                column(NewCapOvrHd_PrintInvCstShrBuf; TempCostShareBuffer."New Capacity Overhead")
                {
                }
                column(NewMatOvrHd_PrintInvCstShrBuf; TempCostShareBuffer."New Material Overhead")
                {
                }
                column(Subcontrt_PrintInvCstShrBuf; TempCostShareBuffer."New Subcontracted")
                {
                }
                column(NewVar_PrintInvCstShrBuf; TempCostShareBuffer."New Variance")
                {
                }
                column(NewReval_PrintInvCstShrBuf; TempCostShareBuffer."New Revaluation")
                {
                }
                column(NewRounding_PrintInvCstShrBuf; TempCostShareBuffer."New Rounding")
                {
                }
                column(CostShareBufNewQuantity; TempCostShareBuffer."New Quantity")
                {
                    DecimalPlaces = 0 : 5;
                }
                column(NewPurchVar_PrintInvCstShrBuf; TempCostShareBuffer."New Purchase Variance")
                {
                }
                column(NewMatrlVar_PrintInvCstShrBuf; TempCostShareBuffer."New Material Variance")
                {
                }
                column(NewCapVar_PrintInvCstShrBuf; TempCostShareBuffer."New Capacity Variance")
                {
                }
                column(NwCapOvHdVar_PrintInvCstShrBuf; TempCostShareBuffer."New Capacity Overhead Variance")
                {
                }
                column(NwMfgOvrhdVar_PrintInvCstShrBuf; TempCostShareBuffer."New Mfg. Overhead Variance")
                {
                }
                column(CostShareBufNewSubcontractedVar; TempCostShareBuffer."New Subcontracted Variance")
                {
                }
                column(TotalCostVariance; TempCostShareBuffer."New Purchase Variance" + TempCostShareBuffer."New Material Variance" + TempCostShareBuffer."New Capacity Variance" + TempCostShareBuffer."New Capacity Overhead Variance" + TempCostShareBuffer."New Mfg. Overhead Variance" + TempCostShareBuffer."New Subcontracted Variance")
                {
                }
                column(TotalCost; TempCostShareBuffer."New Direct Cost" + TempCostShareBuffer."New Indirect Cost" + TempCostShareBuffer."New Revaluation" + TempCostShareBuffer."New Rounding" + TempCostShareBuffer."New Variance")
                {
                }
                column(SrvTrPrintInvtCostShareBufFtr4; SrvTrPrintInvtCostShareBufFtr4())
                {
                }
                column(SrvTrPrintInvtCostShareBufFtr5; SrvTrPrintInvtCostShareBufFtr5())
                {
                }

                trigger OnAfterGetRecord()
                var
                    TempItem: Record Item temporary;
                    InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
                begin
                    if Number = 1 then begin
                        if not TempCostShareBuffer.Find('-') then
                            CurrReport.Break();
                    end else
                        if TempCostShareBuffer.Next() = 0 then
                            CurrReport.Break();

                    if TempCostShareBuffer."Posting Date" > EndDate then
                        CurrReport.Skip();

                    case CostSharePrint of
                        CostSharePrint::Sales:
                            begin
                                TempCostShareBuffer."New Revaluation" := TempCostShareBuffer."New Revaluation" - TempCostShareBuffer.Revaluation;
                                TempCostShareBuffer."New Quantity" := TempCostShareBuffer.Quantity;
                            end;
                        CostSharePrint::Inventory:
                            if TempCostShareBuffer."New Quantity" = 0 then
                                CurrReport.Skip();
                        CostSharePrint::"WIP Inventory":
                            begin
                                if InvtAdjmtEntryOrder.Get(TempCostShareBuffer."Order Type", TempCostShareBuffer."Order No.", TempCostShareBuffer."Order Line No.") then begin
                                    Item.Get(InvtAdjmtEntryOrder."Item No.");
                                    TempItem := Item;
                                    TempItem.Insert();
                                    TempItem.CopyFilters(Item);
                                    if TempItem.IsEmpty() then
                                        CurrReport.Skip();
                                end;

                                if TempCostShareBuffer."Entry Type" = TempCostShareBuffer."Entry Type"::" " then begin
                                    TempCostShareBuffer."New Direct Cost" := -TempCostShareBuffer."New Direct Cost";
                                    TempCostShareBuffer."New Indirect Cost" := -TempCostShareBuffer."New Indirect Cost";
                                    TempCostShareBuffer."New Revaluation" := -TempCostShareBuffer."New Revaluation";
                                    TempCostShareBuffer."New Rounding" := -TempCostShareBuffer."New Rounding";
                                    TempCostShareBuffer."New Variance" := -TempCostShareBuffer."New Variance";
                                    TempCostShareBuffer."New Purchase Variance" := -TempCostShareBuffer."New Purchase Variance";
                                    TempCostShareBuffer."New Material Variance" := -TempCostShareBuffer."New Material Variance";
                                    TempCostShareBuffer."New Capacity Variance" := -TempCostShareBuffer."New Capacity Variance";
                                    TempCostShareBuffer."New Capacity Overhead Variance" := -TempCostShareBuffer."New Capacity Overhead Variance";
                                    TempCostShareBuffer."New Mfg. Overhead Variance" := -TempCostShareBuffer."New Mfg. Overhead Variance";
                                    TempCostShareBuffer."New Subcontracted Variance" := -TempCostShareBuffer."New Subcontracted Variance";
                                    TempCostShareBuffer."New Material" := -TempCostShareBuffer."New Material";
                                    TempCostShareBuffer."New Capacity" := -TempCostShareBuffer."New Capacity";
                                    TempCostShareBuffer."New Capacity Overhead" := -TempCostShareBuffer."New Capacity Overhead";
                                    TempCostShareBuffer."New Material Overhead" := -TempCostShareBuffer."New Material Overhead";
                                    TempCostShareBuffer."New Subcontracted" := -TempCostShareBuffer."New Subcontracted";
                                end;
                                TempCostShareBuffer."New Variance" := TempCostShareBuffer."New Variance" - TempCostShareBuffer.Variance;
                                TempCostShareBuffer."New Purchase Variance" := TempCostShareBuffer."New Purchase Variance" - TempCostShareBuffer."Purchase Variance";
                                TempCostShareBuffer."New Material Variance" := TempCostShareBuffer."New Material Variance" - TempCostShareBuffer."Material Variance";
                                TempCostShareBuffer."New Capacity Variance" := TempCostShareBuffer."New Capacity Variance" - TempCostShareBuffer."Capacity Variance";
                                TempCostShareBuffer."New Capacity Overhead Variance" :=
                                  TempCostShareBuffer."New Capacity Overhead Variance" - TempCostShareBuffer."Capacity Overhead Variance";
                                TempCostShareBuffer."New Mfg. Overhead Variance" := TempCostShareBuffer."New Mfg. Overhead Variance" -
                                  TempCostShareBuffer."Mfg. Overhead Variance";
                                TempCostShareBuffer."New Subcontracted Variance" := TempCostShareBuffer."New Subcontracted Variance" -
                                  TempCostShareBuffer."Subcontracted Variance";
                            end;
                    end;

                    if Number = 1 then
                        if CostSharePrint in [CostSharePrint::Sales, CostSharePrint::Inventory] then begin
                            if ItemPrint.Get(TempCostShareBuffer."Item No.") then begin
                                TempCostShareBuffer."Item No." := ItemPrint."No.";
                                TempCostShareBuffer.Description := ItemPrint.Description;
                            end;
                        end else
                            if (TempCostShareBuffer."Order Type" = TempCostShareBuffer."Order Type"::Production) and
                               (ProdOrderPrint.Get(ProdOrderPrint.Status::Finished, TempCostShareBuffer."Order No.") or
                                ProdOrderPrint.Get(ProdOrderPrint.Status::Released, TempCostShareBuffer."Order No."))
                            then begin
                                TempCostShareBuffer."Item No." := ProdOrderPrint."No.";
                                TempCostShareBuffer.Description := ProdOrderPrint.Description;
                                TempCostShareBuffer."New Quantity" := ProdOrderPrint.Quantity;
                            end;
                end;

                trigger OnPreDataItem()
                begin
                    if CostSharePrint in [CostSharePrint::Sales, CostSharePrint::Inventory] then begin
                        TempCostShareBuffer.SetCurrentKey("Item No.");
                        TempCostShareBuffer.SetRange("Item No.", ItemPrint."No.");
                        if CostSharePrint = CostSharePrint::Sales then begin
                            TempCostShareBuffer.SetRange("Entry Type", TempCostShareBuffer."Entry Type"::Sale);
                            if EndDate = 0D then
                                EndDate := DMY2Date(31, 12, 9998);
                            TempCostShareBuffer.SetRange("Posting Date", StartDate, EndDate)
                        end;
                    end else begin
                        TempCostShareBuffer.SetCurrentKey("Order Type", "Order No.");
                        TempCostShareBuffer.SetRange("Order Type", TempCostShareBuffer."Order Type"::Production);
                        TempCostShareBuffer.SetRange("Order No.", ProdOrderPrint."No.");
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                case CostSharePrint of
                    CostSharePrint::Sales, CostSharePrint::Inventory:
                        if Number = 1 then begin
                            if not ItemPrint.Find('-') then
                                CurrReport.Break();
                        end else
                            if ItemPrint.Next() = 0 then
                                CurrReport.Break();
                    CostSharePrint::"WIP Inventory":
                        if Number = 1 then begin
                            if not ProdOrderPrint.Find('-') then
                                CurrReport.Break();
                        end else
                            if ProdOrderPrint.Next() = 0 then
                                CurrReport.Break();
                end;

                TempCostShareBuffer.Reset();
                if not TempCostShareBuffer.Find('-') then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                if CostSharePrint in [CostSharePrint::Sales, CostSharePrint::Inventory] then begin
                    ItemPrint.CopyFilters(Item);
                    ItemPrint.SetCurrentKey("Inventory Posting Group");
                end else
                    ProdOrderPrint.CopyFilters("Production Order");
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
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the first date from which you want the information in the report to be taken. If you leave this field blank, the program includes all information up to the ending date that you specify in the Ending Date field.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date from which you want the information in the report to be taken. If left blank, the program includes all information from the starting date to the present time.';
                    }
                    field(CostSharePrint; CostSharePrint)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Print Cost Share ';
                        OptionCaption = 'Sales,Inventory,WIP Inventory';
                        ToolTip = 'Specifies that cost share information is included on printouts of the report. ';
                    }
                    field(ShowDetails; ShowDetails)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Show Details';
                        ToolTip = 'Specifies if you want to see a detailed breakdown of where the cost comes from for each item.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if (StartDate = 0D) and (EndDate = 0D) then
                EndDate := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if (StartDate = 0D) and (EndDate = 0D) then
            EndDate := WorkDate();

        case true of
            (StartDate <> 0D) and (EndDate <> 0D):
                Item.SetRange("Date Filter", StartDate, EndDate);
            (StartDate <> 0D):
                Item.SetFilter("Date Filter", '%1..', StartDate);
            else
                Item.SetRange("Date Filter", 0D, EndDate);
        end;

        ItemFilter := Item.GetFilters();
        ProdOrderFilter := "Production Order".GetFilters();

        TempCostShareBuffer.Reset();
        TempCostShareBuffer.DeleteAll();
    end;

    var
        ItemPrint: Record Item;
        ProdOrderPrint: Record "Production Order";
        TempCostShareBuffer: Record "Cost Share Buffer" temporary;
        ItemFilter: Text;
        ProdOrderFilter: Text;
        RemainingQty: Decimal;
        CostSharePrint: Option Sales,Inventory,"WIP Inventory";
        StartDate: Date;
        EndDate: Date;
        ShowDetails: Boolean;
        CurrReportPageNoCaptionLbl: Label 'Page';
        CostShareBufDocumentNoCaptionLbl: Label 'No.';
        CostShareBufDescriptionCaptionLbl: Label 'Description';
        CostShareBufNewQuantityCaptionLbl: Label 'Quantity';
        CostShareBufNewMatrlCaptionLbl: Label 'Material Direct Cost Applied';
        CapacityDirCostAppCaptionLbl: Label 'Capacity Direct Cost Applied';
        CapacityOverheadCaptionLbl: Label 'Capacity Overhead';
        MaterialOverheadCaptionLbl: Label 'Material Overhead';
        VarianceCaptionLbl: Label 'Variance';
        RevaluationCaptionLbl: Label 'Revaluation';
        RoundingCaptionLbl: Label 'Rounding';
        TotalCaptionLbl: Label 'Total';
        VarBreakdownCaptionLbl: Label 'Variance Breakdown';

    local procedure CalcRemainingQty(FromItemLedgEntry: Record "Item Ledger Entry")
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        RemainingQty := FromItemLedgEntry.Quantity;

        if FromItemLedgEntry.Positive then begin
            if TempCostShareBuffer.Get(FromItemLedgEntry."Entry No.") then
                exit;
            if not ItemApplnEntry.AppliedFromEntryExists(FromItemLedgEntry."Entry No.") then
                if ForwardToAppliedOutbndEntry(FromItemLedgEntry."Entry No.") then
                    exit;
        end;

        if (FromItemLedgEntry."Posting Date" > EndDate) and (EndDate <> 0D) then
            exit;

        if not TempCostShareBuffer.Get(FromItemLedgEntry."Entry No.") then
            InsertItemLedgEntryCostShare(FromItemLedgEntry);
    end;

    local procedure ForwardToAppliedOutbndEntry(EntryNo: Integer): Boolean
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        if ItemApplnEntry.AppliedOutbndEntryExists(EntryNo, true, false) then begin
            ForwardItemLedgEntryCostShare(ItemApplnEntry, EntryNo, false);
            exit(true);
        end;
        exit(false);
    end;

    local procedure ForwardToAppliedInbndEntry(EntryNo: Integer)
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        if ItemApplnEntry.AppliedInbndEntryExists(EntryNo, true) then
            ForwardItemLedgEntryCostShare(ItemApplnEntry, EntryNo, true);
    end;

    local procedure ForwardToInbndTranEntry(EntryNo: Integer): Boolean
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        if ItemApplnEntry.AppliedInbndTransEntryExists(EntryNo, true) then begin
            ForwardItemLedgEntryCostShare(ItemApplnEntry, EntryNo, true);
            exit(true);
        end;
        exit(false);
    end;

    local procedure ForwardItemLedgEntryCostShare(var ItemApplnEntry: Record "Item Application Entry"; EntryNo: Integer; IsInBound: Boolean)
    var
        FromItemLedgEntry: Record "Item Ledger Entry";
        ToItemLedgEntry: Record "Item Ledger Entry";
        FromCostShareBuffer: Record "Cost Share Buffer";
        ToCostShareBuffer: Record "Cost Share Buffer";
        ToEntryNo: Integer;
        CostShare: Decimal;
        AppliedQty: Decimal;
    begin
        repeat
            if not TempCostShareBuffer.Get(EntryNo) then begin
                FromItemLedgEntry.Get(EntryNo);
                if FromItemLedgEntry."Posting Date" > EndDate then
                    exit;
                InsertItemLedgEntryCostShare(FromItemLedgEntry);
            end;
            FromCostShareBuffer := TempCostShareBuffer;
            if IsInBound then
                ToEntryNo := ItemApplnEntry."Inbound Item Entry No."
            else
                ToEntryNo := ItemApplnEntry."Outbound Item Entry No.";

            ToItemLedgEntry.Get(ToEntryNo);
            if not TempCostShareBuffer.Get(ToEntryNo) then
                InsertItemLedgEntryCostShare(ToItemLedgEntry);

            ToCostShareBuffer := TempCostShareBuffer;
            if (ToCostShareBuffer."Posting Date" <= EndDate) or (EndDate = 0D) then begin
                if (EndDate = 0D) or (ToItemLedgEntry."Posting Date" <= EndDate) and
                   (FromCostShareBuffer.Quantity * ItemApplnEntry.Quantity < 0)
                then
                    AppliedQty := AppliedQty + ItemApplnEntry.Quantity;

                if ToCostShareBuffer.Quantity < 0 then
                    ToCostShareBuffer."New Quantity" := ToCostShareBuffer."New Quantity" - ItemApplnEntry.Quantity;

                CostShare := ItemApplnEntry.Quantity / FromCostShareBuffer.Quantity;
                UpdateCosts(FromCostShareBuffer, ToCostShareBuffer, CostShare, true);

                TempCostShareBuffer := ToCostShareBuffer;
                TempCostShareBuffer.Modify();

                ForwardToAppliedOutbndEntry(ToCostShareBuffer."Item Ledger Entry No.");
                if ToCostShareBuffer."New Quantity" - ToItemLedgEntry."Remaining Quantity" = 0 then
                    ForwardToAppliedInbndEntry(ToCostShareBuffer."Item Ledger Entry No.");

                if (ToCostShareBuffer.Quantity < 0) and
                   (CostSharePrint in [CostSharePrint::Inventory, CostSharePrint::"WIP Inventory"])
                then begin
                    TempCostShareBuffer.Find();
                    ToCostShareBuffer := TempCostShareBuffer;
                    CostShare := -CostShare;
                    UpdateCosts(FromCostShareBuffer, ToCostShareBuffer, CostShare, false);
                    TempCostShareBuffer := ToCostShareBuffer;
                    TempCostShareBuffer.Modify();
                end;
            end;
        until ItemApplnEntry.Next() = 0;

        if ToItemLedgEntry."Entry Type" = ToItemLedgEntry."Entry Type"::Transfer then
            if not ToItemLedgEntry.Positive then begin
                if EndDate in [0D .. ToItemLedgEntry."Posting Date"] then
                    ForwardToInbndTranEntry(EntryNo)
            end else
                exit;

        if (CostSharePrint = CostSharePrint::Inventory) and (FromCostShareBuffer.Quantity > 0) then begin
            FromCostShareBuffer."New Quantity" := FromCostShareBuffer."New Quantity" + AppliedQty;
            CostShare := AppliedQty / FromCostShareBuffer.Quantity;
            UpdateCosts(FromCostShareBuffer, FromCostShareBuffer, CostShare, false);
        end;
        TempCostShareBuffer := FromCostShareBuffer;
        TempCostShareBuffer.Modify();
    end;

    local procedure UpdateCosts(FromCostShareBuffer: Record "Cost Share Buffer"; var ToCostShareBuffer: Record "Cost Share Buffer"; CostShare: Decimal; DirCostIsDiff: Boolean)
    begin
        ToCostShareBuffer."New Indirect Cost" := ToCostShareBuffer."New Indirect Cost" + CostShare * FromCostShareBuffer."New Indirect Cost";
        if CostSharePrint = CostSharePrint::Sales then
            ToCostShareBuffer."New Revaluation" := ToCostShareBuffer."New Revaluation" + CostShare * FromCostShareBuffer."New Revaluation";
        ToCostShareBuffer."New Rounding" := ToCostShareBuffer."New Rounding" + CostShare * FromCostShareBuffer."New Rounding";
        ToCostShareBuffer."New Variance" := ToCostShareBuffer."New Variance" + CostShare * FromCostShareBuffer."New Variance";
        ToCostShareBuffer."New Purchase Variance" := ToCostShareBuffer."New Purchase Variance" + CostShare * FromCostShareBuffer."New Purchase Variance";
        ToCostShareBuffer."New Material Variance" := ToCostShareBuffer."New Material Variance" + CostShare * FromCostShareBuffer."New Material Variance";
        ToCostShareBuffer."New Capacity Variance" := ToCostShareBuffer."New Capacity Variance" + CostShare * FromCostShareBuffer."New Capacity Variance";
        ToCostShareBuffer."New Capacity Overhead Variance" :=
          ToCostShareBuffer."New Capacity Overhead Variance" + CostShare * FromCostShareBuffer."New Capacity Overhead Variance";
        ToCostShareBuffer."New Mfg. Overhead Variance" :=
          ToCostShareBuffer."New Mfg. Overhead Variance" + CostShare * FromCostShareBuffer."New Mfg. Overhead Variance";
        ToCostShareBuffer."New Subcontracted Variance" :=
          ToCostShareBuffer."New Subcontracted Variance" + CostShare * FromCostShareBuffer."New Subcontracted Variance";
        if DirCostIsDiff then
            ToCostShareBuffer."New Direct Cost" := ToCostShareBuffer."New Direct Cost" - CostShare *
              (FromCostShareBuffer."New Indirect Cost" +
               FromCostShareBuffer."New Revaluation" +
               FromCostShareBuffer."New Variance" +
               FromCostShareBuffer."New Rounding")
        else
            ToCostShareBuffer."New Direct Cost" := ToCostShareBuffer."New Direct Cost" + CostShare * FromCostShareBuffer."New Direct Cost";
        ToCostShareBuffer."New Capacity" := ToCostShareBuffer."New Capacity" + CostShare * FromCostShareBuffer."New Capacity";
        ToCostShareBuffer."New Capacity Overhead" := ToCostShareBuffer."New Capacity Overhead" + CostShare * FromCostShareBuffer."New Capacity Overhead";
        ToCostShareBuffer."New Material Overhead" := ToCostShareBuffer."New Material Overhead" + CostShare * FromCostShareBuffer."New Material Overhead";
        ToCostShareBuffer."New Subcontracted" := ToCostShareBuffer."New Subcontracted" + CostShare * FromCostShareBuffer."New Subcontracted";
        ToCostShareBuffer."New Material" := ToCostShareBuffer."New Direct Cost" - (ToCostShareBuffer."New Capacity" + ToCostShareBuffer."New Capacity Overhead" + ToCostShareBuffer."New Subcontracted");
    end;

    local procedure InsertItemLedgEntryCostShare(ItemLedgEntry: Record "Item Ledger Entry")
    var
        ValueEntry: Record "Value Entry";
        CostInPeriod: Decimal;
        TotalCost: Decimal;
        DirectCostInPeriod: Decimal;
        TotalDirectCost: Decimal;
    begin
        TempCostShareBuffer.Init();
        TempCostShareBuffer."Item Ledger Entry No." := ItemLedgEntry."Entry No.";
        TempCostShareBuffer."Item No." := ItemLedgEntry."Item No.";
        TempCostShareBuffer.Quantity := ItemLedgEntry.Quantity;
        TempCostShareBuffer."Entry Type" := ItemLedgEntry."Entry Type";
        TempCostShareBuffer."Location Code" := ItemLedgEntry."Location Code";
        TempCostShareBuffer."Variant Code" := ItemLedgEntry."Variant Code";
        TempCostShareBuffer."Order Type" := ItemLedgEntry."Order Type";
        TempCostShareBuffer."Order No." := ItemLedgEntry."Order No.";
        TempCostShareBuffer."Order Line No." := ItemLedgEntry."Order Line No.";
        TempCostShareBuffer."Document No." := ItemLedgEntry."Document No.";
        TempCostShareBuffer.Description := ItemLedgEntry.Description;
        TempCostShareBuffer."Posting Date" := ItemLedgEntry."Posting Date";

        TotalCost := 0;
        CostInPeriod := 0;
        DirectCostInPeriod := 0;
        TotalDirectCost := 0;
        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
        if EndDate <> 0D then
            ValueEntry.SetRange("Posting Date", 0D, EndDate);
        if ValueEntry.Find('-') then
            repeat
                GetValueEntryCostAmts(TempCostShareBuffer, ValueEntry);

                if IsInCostingPeriod(ValueEntry."Posting Date") then begin
                    CostInPeriod := CostInPeriod + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                    if ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost" then
                        DirectCostInPeriod := DirectCostInPeriod + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                end;
                TotalCost := TotalCost + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                if ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost" then
                    TotalDirectCost := TotalDirectCost + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
            until ValueEntry.Next() = 0;

        if ItemLedgEntry."Entry Type" in [ItemLedgEntry."Entry Type"::Output,
                                          ItemLedgEntry."Entry Type"::"Assembly Output"]
        then
            UpdateCostShareBufFromInvAdjmtEntryOrder(ItemLedgEntry, TempCostShareBuffer)
        else
            TempCostShareBuffer."Material Overhead" := TempCostShareBuffer."Indirect Cost";

        TempCostShareBuffer.Material := TempCostShareBuffer."Direct Cost" - (TempCostShareBuffer.Capacity + TempCostShareBuffer."Capacity Overhead" + TempCostShareBuffer.Subcontracted);

        if TotalCost <> 0 then
            TempCostShareBuffer."Share of Cost in Period" := CostInPeriod / TotalCost;

        TempCostShareBuffer."New Quantity" := TempCostShareBuffer.Quantity;
        TempCostShareBuffer."New Direct Cost" := TempCostShareBuffer."Direct Cost";
        TempCostShareBuffer."New Indirect Cost" := TempCostShareBuffer."Indirect Cost";
        TempCostShareBuffer."New Revaluation" := TempCostShareBuffer.Revaluation;
        TempCostShareBuffer."New Variance" := TempCostShareBuffer.Variance;
        TempCostShareBuffer."New Rounding" := TempCostShareBuffer.Rounding;

        TempCostShareBuffer."New Purchase Variance" := TempCostShareBuffer."Purchase Variance";
        TempCostShareBuffer."New Material Variance" := TempCostShareBuffer."Material Variance";
        TempCostShareBuffer."New Capacity Variance" := TempCostShareBuffer."Capacity Variance";
        TempCostShareBuffer."New Capacity Overhead Variance" := TempCostShareBuffer."Capacity Overhead Variance";
        TempCostShareBuffer."New Mfg. Overhead Variance" := TempCostShareBuffer."Mfg. Overhead Variance";
        TempCostShareBuffer."New Subcontracted Variance" := TempCostShareBuffer."Subcontracted Variance";

        TempCostShareBuffer."New Material" := TempCostShareBuffer.Material;
        TempCostShareBuffer."New Capacity" := TempCostShareBuffer.Capacity;
        TempCostShareBuffer."New Capacity Overhead" := TempCostShareBuffer."Capacity Overhead";
        TempCostShareBuffer."New Material Overhead" := TempCostShareBuffer."Material Overhead";
        TempCostShareBuffer."New Subcontracted" := TempCostShareBuffer.Subcontracted;
        TempCostShareBuffer.Insert();
    end;

    local procedure UpdateCostShareBufFromInvAdjmtEntryOrder(ItemLedgEntry: Record "Item Ledger Entry"; var CostShareBuffer: Record "Cost Share Buffer")
    var
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        CalcInvtAdjmtOrder: Codeunit "Calc. Inventory Adjmt. - Order";
        ShareOfCost: Decimal;
        OutputQty: Decimal;
    begin
        if not InvtAdjmtEntryOrder.Get(ItemLedgEntry."Order Type", ItemLedgEntry."Order No.", ItemLedgEntry."Order Line No.") then
            exit;

        OutputQty := CalcInvtAdjmtOrder.CalcOutputQty(InvtAdjmtEntryOrder, false);
        CalcInvtAdjmtOrder.CalcActualUsageCosts(InvtAdjmtEntryOrder, OutputQty, InvtAdjmtEntryOrder);

        CostShareBuffer.Capacity += InvtAdjmtEntryOrder."Single-Level Capacity Cost";
        CostShareBuffer."Capacity Overhead" += InvtAdjmtEntryOrder."Single-Level Cap. Ovhd Cost";
        CostShareBuffer."Material Overhead" += InvtAdjmtEntryOrder."Single-Level Mfg. Ovhd Cost";
        CostShareBuffer.Subcontracted += InvtAdjmtEntryOrder."Single-Level Subcontrd. Cost";

        if OutputQty <> 0 then begin
            ShareOfCost := ItemLedgEntry.Quantity / OutputQty;
            CostShareBuffer.Capacity *= ShareOfCost;
            CostShareBuffer."Capacity Overhead" *= ShareOfCost;
            CostShareBuffer."Material Overhead" *= ShareOfCost;
            CostShareBuffer.Subcontracted *= ShareOfCost;
        end;
    end;

    local procedure InsertCapLedgEntryCostShare(CapLedgEntry: Record "Capacity Ledger Entry")
    var
        ValueEntry: Record "Value Entry";
        CostInPeriod: Decimal;
        TotalCost: Decimal;
    begin
        TempCostShareBuffer.Init();
        TempCostShareBuffer."Capacity Ledger Entry No." := CapLedgEntry."Entry No.";
        TempCostShareBuffer."Item No." := CapLedgEntry."Item No.";
        TempCostShareBuffer.Quantity := CapLedgEntry.Quantity;
        TempCostShareBuffer."Entry Type" := TempCostShareBuffer."Entry Type"::" ";
        TempCostShareBuffer."Order Type" := CapLedgEntry."Order Type";
        TempCostShareBuffer."Order No." := CapLedgEntry."Order No.";
        TempCostShareBuffer."Order Line No." := CapLedgEntry."Order Line No.";
        TempCostShareBuffer."Document No." := CapLedgEntry."Document No.";
        TempCostShareBuffer.Description := CapLedgEntry.Description;

        TotalCost := 0;
        CostInPeriod := 0;
        ValueEntry.SetCurrentKey("Capacity Ledger Entry No.", "Entry Type");
        ValueEntry.SetRange("Capacity Ledger Entry No.", CapLedgEntry."Entry No.");
        if EndDate <> 0D then
            ValueEntry.SetRange("Posting Date", 0D, EndDate);
        if ValueEntry.Find('-') then
            repeat
                GetValueEntryCostAmts(TempCostShareBuffer, ValueEntry);

                if IsInCostingPeriod(ValueEntry."Posting Date") then
                    CostInPeriod := CostInPeriod + ValueEntry."Cost Amount (Actual)";
                TotalCost := TotalCost + ValueEntry."Cost Amount (Actual)";
            until ValueEntry.Next() = 0;

        if TotalCost <> 0 then
            TempCostShareBuffer."Share of Cost in Period" := CostInPeriod / TotalCost;

        if CapLedgEntry.Subcontracting then
            TempCostShareBuffer.Subcontracted := TempCostShareBuffer."Direct Cost"
        else
            TempCostShareBuffer.Capacity := TempCostShareBuffer."Direct Cost";
        TempCostShareBuffer."Capacity Overhead" := TempCostShareBuffer."Indirect Cost";

        TempCostShareBuffer."New Quantity" := TempCostShareBuffer.Quantity;
        TempCostShareBuffer."New Direct Cost" := TempCostShareBuffer."Direct Cost";
        TempCostShareBuffer."New Indirect Cost" := TempCostShareBuffer."Indirect Cost";
        TempCostShareBuffer."New Revaluation" := TempCostShareBuffer.Revaluation;
        TempCostShareBuffer."New Variance" := TempCostShareBuffer.Variance;
        TempCostShareBuffer."New Rounding" := TempCostShareBuffer.Rounding;

        TempCostShareBuffer."New Purchase Variance" := TempCostShareBuffer."Purchase Variance";
        TempCostShareBuffer."New Material Variance" := TempCostShareBuffer."Material Variance";
        TempCostShareBuffer."New Capacity Variance" := TempCostShareBuffer."Capacity Variance";
        TempCostShareBuffer."New Capacity Overhead Variance" := TempCostShareBuffer."Capacity Overhead Variance";
        TempCostShareBuffer."New Mfg. Overhead Variance" := TempCostShareBuffer."Mfg. Overhead Variance";
        TempCostShareBuffer."New Subcontracted Variance" := TempCostShareBuffer."Subcontracted Variance";

        TempCostShareBuffer."New Material" := TempCostShareBuffer.Material;
        TempCostShareBuffer."New Capacity" := TempCostShareBuffer.Capacity;
        TempCostShareBuffer."New Capacity Overhead" := TempCostShareBuffer."Capacity Overhead";
        TempCostShareBuffer."New Material Overhead" := TempCostShareBuffer."Material Overhead";
        TempCostShareBuffer."New Subcontracted" := TempCostShareBuffer.Subcontracted;
        TempCostShareBuffer.Insert();
    end;

    local procedure GetValueEntryCostAmts(var CostShareBuf: Record "Cost Share Buffer"; ValueEntry: Record "Value Entry")
    begin
        case ValueEntry."Entry Type" of
            ValueEntry."Entry Type"::"Direct Cost":
                CostShareBuf."Direct Cost" := CostShareBuf."Direct Cost" + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
            ValueEntry."Entry Type"::"Indirect Cost":
                CostShareBuf."Indirect Cost" := CostShareBuf."Indirect Cost" + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
            ValueEntry."Entry Type"::Variance:
                begin
                    CostShareBuf.Variance := CostShareBuf.Variance + ValueEntry."Cost Amount (Actual)";
                    case ValueEntry."Variance Type" of
                        ValueEntry."Variance Type"::Purchase:
                            CostShareBuf."Purchase Variance" := CostShareBuf."Purchase Variance" + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                        ValueEntry."Variance Type"::Material:
                            CostShareBuf."Material Variance" := CostShareBuf."Material Variance" + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                        ValueEntry."Variance Type"::Capacity:
                            CostShareBuf."Capacity Variance" := CostShareBuf."Capacity Variance" + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                        ValueEntry."Variance Type"::"Capacity Overhead":
                            CostShareBuf."Capacity Overhead Variance" :=
                              CostShareBuf."Capacity Overhead Variance" + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                        ValueEntry."Variance Type"::"Manufacturing Overhead":
                            CostShareBuf."Mfg. Overhead Variance" :=
                              CostShareBuf."Mfg. Overhead Variance" + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                        ValueEntry."Variance Type"::Subcontracted:
                            CostShareBuf."Subcontracted Variance" :=
                              CostShareBuf."Subcontracted Variance" + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
                    end;
                end;
            ValueEntry."Entry Type"::Revaluation:
                CostShareBuf.Revaluation := CostShareBuf.Revaluation + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
            ValueEntry."Entry Type"::Rounding:
                CostShareBuf.Rounding := CostShareBuf.Rounding + ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
        end;
    end;

    local procedure IsInCostingPeriod(PostingDate: Date): Boolean
    begin
        if EndDate <> 0D then
            exit(PostingDate in [StartDate .. EndDate]);
        exit(PostingDate >= StartDate);
    end;

    local procedure SrvTrPrintInvtCostShareBufFtr4(): Boolean
    begin
        if CostSharePrint in [CostSharePrint::Sales, CostSharePrint::Inventory] then begin
            TempCostShareBuffer."Item No." := ItemPrint."No.";
            TempCostShareBuffer.Description := ItemPrint.Description;
        end else begin
            TempCostShareBuffer."Item No." := ProdOrderPrint."No.";
            TempCostShareBuffer.Description := ProdOrderPrint.Description;
            TempCostShareBuffer."New Quantity" := ProdOrderPrint.Quantity;
        end;
        exit(ShowDetails);
    end;

    local procedure SrvTrPrintInvtCostShareBufFtr5(): Boolean
    begin
        if CostSharePrint = CostSharePrint::"WIP Inventory" then begin
            TempCostShareBuffer."Item No." := ProdOrderPrint."No.";
            TempCostShareBuffer."New Quantity" := ProdOrderPrint.Quantity;
        end;
        exit(not ShowDetails);
    end;

    procedure InitializeRequest(NewStartDate: Date; NewEndDate: Date; NewPrintCostShare: Option; NewShowDetails: Boolean)
    begin
        StartDate := NewStartDate;
        EndDate := NewEndDate;
        CostSharePrint := NewPrintCostShare;
        ShowDetails := NewShowDetails;
    end;
}

