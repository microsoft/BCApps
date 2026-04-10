// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using System.Utilities;

report 704 "Inventory - Transaction Detail"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory - Transaction Detail';
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = Excel;

    dataset
    {
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", Description, "Assembly BOM", "Inventory Posting Group", "Shelf No.", "Statistics Group", "Date Filter";
            column(No_Item; "No.")
            {
            }
#if not CLEAN28
            column(PeriodItemDateFilter; StrSubstNo(PeriodInfoTxt, ItemDateFilter))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(TableCaptionItemFilter; StrSubstNo(TableFiltersTxt, TableCaption(), ItemFilter))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ItemFilter; ItemFilter)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(InventoryTransDetailCaption; InventoryTransDetailCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ItemLedgEntryPostDateCaption; ItemLedgEntryPostDateCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ItemLedgEntryEntryTypCaption; ItemLedgEntryEntryTypCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(IncreasesQtyCaption; IncreasesQtyCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(DecreasesQtyCaption; DecreasesQtyCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ItemOnHandCaption; ItemOnHandCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
#endif
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(Description_Item; Item.Description)
                {
                }
#if not CLEAN28
                column(StartOnHand; StartOnHand)
                {
                    DecimalPlaces = 0 : 5;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                    ObsoleteTag = '28.0';
                }
                column(RecordNo; RecordNo)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                    ObsoleteTag = '28.0';
                }
#endif
                dataitem("Item Ledger Entry"; "Item Ledger Entry")
                {
                    DataItemLink = "Item No." = field("No."), "Variant Code" = field("Variant Filter"), "Posting Date" = field("Date Filter"), "Location Code" = field("Location Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                    DataItemLinkReference = Item;
                    DataItemTableView = sorting("Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date", "Entry No.");
                    column(PostingDate_ItemLedgEntry; Format("Posting Date"))
                    {
                    }
                    column(EntryType_ItemLedgEntry; "Entry Type")
                    {
                    }
                    column(DocumentNo_PItemLedgEntry; "Document No.")
                    {
                        IncludeCaption = true;
                    }
                    column(Description_ItemLedgEntry; Description)
                    {
                        IncludeCaption = true;
                    }
                    column(IncreasesQty; IncreasesQty)
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(DecreasesQty; DecreasesQty)
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(ItemOnHand; ItemOnHand)
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(EntryNo_ItemLedgerEntry; "Entry No.")
                    {
                        IncludeCaption = true;
                    }
                    column(TotalIncreasesQty; TotalIncreasesQty)
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(TotalDecreasesQty; TotalDecreasesQty)
                    {
                        DecimalPlaces = 0 : 5;
                    }
#if not CLEAN28
                    column(StartOnHandQuantity; StartOnHand + Quantity)
                    {
                        DecimalPlaces = 0 : 5;
                        ObsoleteState = Pending;
                        ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                        ObsoleteTag = '28.0';
                    }
                    column(Quantity_ItemLedgerEntry; Quantity)
                    {
                        ObsoleteState = Pending;
                        ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                        ObsoleteTag = '28.0';
                    }
                    column(ItemDescriptionControl32; Item.Description)
                    {
                        ObsoleteState = Pending;
                        ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                        ObsoleteTag = '28.0';
                    }
                    column(ContinuedCaption; ContinuedCaptionLbl)
                    {
                        ObsoleteState = Pending;
                        ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                        ObsoleteTag = '28.0';
                    }
#endif

                    trigger OnAfterGetRecord()
                    begin
                        ItemOnHand := ItemOnHand + Quantity;
                        Clear(IncreasesQty);
                        Clear(DecreasesQty);
                        if Quantity > 0 then
                            IncreasesQty := Quantity
                        else
                            DecreasesQty := Abs(Quantity);

                        TotalIncreasesQty += IncreasesQty;
                        TotalDecreasesQty += DecreasesQty;
                    end;

                    trigger OnPreDataItem()
                    begin
                        Clear(Quantity);
                        Clear(IncreasesQty);
                        Clear(DecreasesQty);
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                StartOnHand := 0;
                if ItemDateFilter <> '' then
                    if GetRangeMin("Date Filter") > 00000101D then begin
                        SetRange("Date Filter", 0D, GetRangeMin("Date Filter") - 1);
                        OnItemOnAfterGetRecordOnBeforeCalcNetChange(Item);
                        CalcFields("Net Change");
                        StartOnHand := "Net Change";
                        SetFilter("Date Filter", ItemDateFilter);
                    end;
                ItemOnHand := StartOnHand;

                if PrintOnlyOnePerPageReq then
                    RecordNo := RecordNo + 1;

                Clear(TotalIncreasesQty);
                Clear(TotalDecreasesQty);
            end;

            trigger OnPreDataItem()
            begin
                RecordNo := 1;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Inventory - Transaction Detail';
        AboutText = 'View a history of inventory transaction details with a running total of inventory during a period defined in the Date Filter.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
#if not CLEAN28
                    field(PrintOnlyOnePerPage; PrintOnlyOnePerPageReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Item';
                        ToolTip = 'Specifies if you want each item transaction detail to be printed on a separate page.';
                    }
#endif
                    // Used to set a report header across multiple languages
                    field(RequestItemFilterHeading; ItemFilterHeading)
                    {
                        ApplicationArea = All;
                        Caption = 'Item Filter';
                        ToolTip = 'Specifies the Item filters applied to this report.';
                        Visible = false;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnClosePage()
        begin
            UpdateRequestPageFilterValues();
        end;
    }

    rendering
    {
        layout(Excel)
        {
            Caption = 'Inventory - Transaction Detail Excel';
            Type = Excel;
            LayoutFile = './Inventory/Reports/InventoryTransactionDetail.xlsx';
            Summary = 'Built in layout for the Inventory - Transaction Detail Excel report.';
        }
#if not CLEAN28
        layout(RDLC)
        {
            Caption = 'Inventory - Transaction Detail RDLC (Obsolete)';
            Type = RDLC;
            LayoutFile = './Inventory/Reports/InventoryTransactionDetail.rdlc';
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by the Excel layout and will be removed in a future release.';
            ObsoleteTag = '28.0';
            Summary = 'Built in layout for the Inventory - Transaction Detail RDLC (Obsolete) report.';
        }
#endif
    }

    labels
    {
        InventoryTransactionDetailLbl = 'Inventory - Transaction Detail';
        InventoryTransDetailPrintLbl = 'Inventory Trans. Detail (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        InvTransDetailAnalysisLbl = 'Inv. Trans. Detail (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        DataRetrievedLbl = 'Data retrieved:';
        ItemNoLbl = 'Item No.';
        ItemDescLbl = 'Item Description';
        PostingDateLbl = 'Posting Date';
        EntryTypeLbl = 'Entry Type';
        DocumentNoLbl = 'Document No.';
        DescriptionLbl = 'Description';
        IncreasesLbl = 'Increases';
        DecreasesLbl = 'Decreases';
        InventoryLbl = 'Inventory';
        EntryNoLbl = 'Entry No.';
        TotalIncreasesLbl = 'Total Increases';
        TotalDecreasesLbl = 'Total Decreases';
        // About the report labels
        AboutTheReportLbl = 'About the report';
        EnvironmentLbl = 'Environment';
        CompanyLbl = 'Company';
        UserLbl = 'User';
        RunOnLbl = 'Run on';
        ReportNameLbl = 'Report name';
        DocumentationLbl = 'Documentation';
    }

    trigger OnPreReport()
    begin
        UpdateRequestPageFilterValues();
    end;

    var
        ItemFilter: Text;
        ItemDateFilter: Text;
        ItemFilterHeading: Text;
        ItemOnHand: Decimal;
        StartOnHand: Decimal;
        IncreasesQty: Decimal;
        DecreasesQty: Decimal;
        TotalIncreasesQty: Decimal;
        TotalDecreasesQty: Decimal;
        PrintOnlyOnePerPageReq: Boolean;
        RecordNo: Integer;
#if not CLEAN28
        PeriodInfoTxt: Label 'Period: %1', Comment = '%1 - period name';
        TableFiltersTxt: Label '%1: %2', Locked = true;
        InventoryTransDetailCaptionLbl: Label 'Inventory - Transaction Detail';
        CurrReportPageNoCaptionLbl: Label 'Page';
        ItemLedgEntryPostDateCaptionLbl: Label 'Posting Date';
        ItemLedgEntryEntryTypCaptionLbl: Label 'Entry Type';
        IncreasesQtyCaptionLbl: Label 'Increases';
        DecreasesQtyCaptionLbl: Label 'Decreases';
        ItemOnHandCaptionLbl: Label 'Inventory';
        ContinuedCaptionLbl: Label 'Continued';
#endif

    procedure InitializeRequest(NewPrintOnlyOnePerPage: Boolean)
    begin
        PrintOnlyOnePerPageReq := NewPrintOnlyOnePerPage;
    end;

    // Ensures Layout Filter Headings are up to date
    local procedure UpdateRequestPageFilterValues()
    begin
        ItemFilter := Item.GetFilters();
        ItemDateFilter := Item.GetFilter("Date Filter");

        ItemFilterHeading := '';
        if ItemFilter <> '' then
            ItemFilterHeading := Item.TableCaption + ': ' + ItemFilter;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemOnAfterGetRecordOnBeforeCalcNetChange(var Item: Record Item)
    begin
    end;
}