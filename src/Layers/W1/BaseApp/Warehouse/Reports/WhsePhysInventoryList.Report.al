// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Reports;

using Microsoft.Warehouse.Journal;
using System.Utilities;

report 7307 "Whse. Phys. Inventory List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Warehouse/Reports/WhsePhysInventoryList.rdlc';
    AdditionalSearchTerms = 'physical count';
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Physical Inventory List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(PageLoop; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CaptionWhseJnlBatFilter; "Warehouse Journal Batch".TableCaption + ': ' + WhseJnlBatchFilter)
            {
            }
            column(WhseJnlBatchFilter; WhseJnlBatchFilter)
            {
            }
            column(CaptionWhseJnlLineFilter; "Warehouse Journal Line".TableCaption + ': ' + WhseJnlLineFilter)
            {
            }
            column(WhseJnlLineFilter; WhseJnlLineFilter)
            {
            }
            column(WhsePhysInvListCaption; WhsePhysInvListCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(WarehuseJnlLinRegDtCapt; WarehuseJnlLinRegDtCaptLbl)
            {
            }
            column(QtyPhysInventoryCaption; QtyPhysInventoryCaptionLbl)
            {
            }
            column(WhseDocNo_WhseJnlLineCaption; "Warehouse Journal Line".FieldCaption("Whse. Document No."))
            {
            }
            column(ItemNo_WarehouseJournlLinCaption; "Warehouse Journal Line".FieldCaption("Item No."))
            {
            }
            column(Desc_WarehouseJnlLineCaption; "Warehouse Journal Line".FieldCaption(Description))
            {
            }
            column(LocCode_WarehouseJnlLineCaption; "Warehouse Journal Line".FieldCaption("Location Code"))
            {
            }
            column(QtyCalculated_WhseJnlLineCaption; "Warehouse Journal Line".FieldCaption("Qty. (Calculated)"))
            {
            }
            column(ZoneCode_WarehouseJnlLineCaption; "Warehouse Journal Line".FieldCaption("Zone Code"))
            {
            }
            column(BinCode_WarehouseJnlLineCaption; "Warehouse Journal Line".FieldCaption("Bin Code"))
            {
            }
            dataitem("Warehouse Journal Batch"; "Warehouse Journal Batch")
            {
                PrintOnlyIfDetail = true;
                RequestFilterFields = "Journal Template Name", Name, "Location Code";
                dataitem("Warehouse Journal Line"; "Warehouse Journal Line")
                {
                    DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name), "Location Code" = field("Location Code");
                    RequestFilterFields = "Zone Code", "Bin Code";
                    column(RegDt_WarehouseJnlLine; Format("Registering Date"))
                    {
                    }
                    column(WhseDocNo_WhseJnlLine; "Whse. Document No.")
                    {
                    }
                    column(ItemNo_WarehouseJournlLin; "Item No.")
                    {
                    }
                    column(Desc_WarehouseJnlLine; Description)
                    {
                    }
                    column(LocCode_WarehouseJnlLine; "Location Code")
                    {
                    }
                    column(EmptyString; '')
                    {
                    }
                    column(QtyCalculated_WhseJnlLine; "Qty. (Calculated)")
                    {
                    }
                    column(ZoneCode_WarehouseJnlLine; "Zone Code")
                    {
                    }
                    column(BinCode_WarehouseJnlLine; "Bin Code")
                    {
                    }
                    column(LotNo_WarehuseJournalLine; "Lot No.")
                    {
                    }
                    column(SerialNo_WarehouseJnlLine; "Serial No.")
                    {
                    }
                    column(ShowLotSN; ShowLotSN)
                    {
                    }
                    column(ShowQtyCalculated; ShowQtyCalculated)
                    {
                    }
                    column(LotNo_WarehuseJournalLineCaption; FieldCaption("Lot No."))
                    {
                    }
                    column(SerialNo_WarehouseJnlLineCaption; FieldCaption("Serial No."))
                    {
                    }
                }
            }
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShowCalculatedQty; ShowQtyCalculated)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Show Qty. (Calculated)';
                        ToolTip = 'Specifies if you want the report to show the calculated quantity of the items.';
                    }
                    field(ShowSerialLotNumber; ShowLotSN)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Show Serial/Lot Number';
                        ToolTip = 'Specifies the lot or serial numbers that are stored in each bin, if the item is set up for warehouse-specific item tracking.';
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

    trigger OnPreReport()
    begin
        WhseJnlLineFilter := "Warehouse Journal Line".GetFilters();
        WhseJnlBatchFilter := "Warehouse Journal Batch".GetFilters();
    end;

    var
        WhseJnlLineFilter: Text;
        WhseJnlBatchFilter: Text;
        ShowQtyCalculated: Boolean;
        ShowLotSN: Boolean;
        WhsePhysInvListCaptionLbl: Label 'Warehouse Physical Inventory List';
        CurrReportPageNoCaptionLbl: Label 'Page';
        WarehuseJnlLinRegDtCaptLbl: Label 'Registering Date';
        QtyPhysInventoryCaptionLbl: Label 'Quantity (Physical Inventory)';

    procedure Initialize(ShowQtyCalculated2: Boolean)
    begin
        ShowQtyCalculated := ShowQtyCalculated2;
    end;
}

