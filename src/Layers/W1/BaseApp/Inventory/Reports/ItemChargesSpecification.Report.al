// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

report 5806 "Item Charges - Specification"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/ItemChargesSpecification.rdlc';
    AdditionalSearchTerms = 'fee transportation freight handling landed cost specification';
    ApplicationArea = Basic, Suite;
    Caption = 'Item Charges - Specification';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Value Entry"; "Value Entry")
        {
            DataItemTableView = sorting("Item Charge No.", "Inventory Posting Group", "Item No.") where("Item Charge No." = filter(<> ''));
            RequestFilterFields = "Item No.", "Posting Date", "Inventory Posting Group";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(ReportTitle; ReportTitle)
            {
            }
            column(ValueEntryCaption; TableCaption + ': ' + ValueEntryFilter)
            {
            }
            column(SourceTypePurch; SourceTypePurch)
            {
            }
            column(ValueEntryPostingDate; ValueEntryPostingDate)
            {
            }
            column(ValueEntryDocNo; ValueEntryDocNo)
            {
            }
            column(ValueEntrySourceType; ValueEntrySourceType)
            {
            }
            column(ValueEntrySourceNo; ValueEntrySourceNo)
            {
            }
            column(ValueEntryQuantity; ValueEntryQuantity)
            {
            }
            column(ValueEntryItemNo; ValueEntryItemNo)
            {
            }
            column(ValueEntryFilter; ValueEntryFilter)
            {
            }
            column(ItemChargeNo_ValueEntry; "Item Charge No.")
            {
            }
            column(InventoryPostingGroup; Text004 + ': ' + "Inventory Posting Group")
            {
            }
            column(PostingDate_ValueEntry; Format("Posting Date"))
            {
            }
            column(DocumentNo_ValueEntry; "Document No.")
            {
            }
            column(SourceType_ValueEntry; "Source Type")
            {
            }
            column(SourceNo_ValueEntry; "Source No.")
            {
            }
            column(ValuedQuantity_ValueEntry; "Valued Quantity")
            {
            }
            column(CostAmtActual_ValueEntry; "Cost Amount (Actual)")
            {
            }
            column(ItemNo_ValueEntry; "Item No.")
            {
            }
            column(PrintDetails; PrintDetails)
            {
            }
            column(SalesAmtActual_ValueEntry; "Sales Amount (Actual)")
            {
            }
            column(GroupSubtotaItemNo; "Item No." + ' : ' + Text005)
            {
            }
            column(ValEntyCostAmtActSalesAct; "Cost Amount (Actual)" + "Sales Amount (Actual)")
            {
            }
            column(ItemDescription; ItemDescription)
            {
            }
            column(SubTotalInvPostingGroup; Text006 + ': ' + "Inventory Posting Group")
            {
            }
            column(GroupTotalItemChargeNo; Text007 + ': ' + "Item Charge No.")
            {
            }
            column(InvPostingGrp_ValueEntry; "Inventory Posting Group")
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(ValueEntryCostAmtActlCptn; ValueEntryCostAmtActlCptnLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if PrintDetails then begin
                    ValueEntryItemNo := FieldCaption("Item No.");
                    ValueEntryPostingDate := FieldCaption("Posting Date");
                    ValueEntryDocNo := FieldCaption("Document No.");
                    ValueEntrySourceType := FieldCaption("Source Type");
                    ValueEntrySourceNo := FieldCaption("Source No.");
                    ValueEntryQuantity := FieldCaption("Valued Quantity");
                end;
                if Item.Get("Item No.") then
                    ItemDescription := Item.Description;
            end;

            trigger OnPreDataItem()
            begin
                if SourceType = SourceType::Sale then begin
                    ReportTitle := ReportTitle + Text002;
                    SetRange("Item Ledger Entry Type", "Item Ledger Entry Type"::Sale);
                end else begin
                    ReportTitle := ReportTitle + Text003;
                    SetRange("Item Ledger Entry Type", "Item Ledger Entry Type"::Purchase);
                end;

                SourceTypePurch := SourceType = SourceType::Purchase;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Item Charges – Specification';
        AboutText = 'Analyse posted sales or purchase item charges to assess added costs, such as freight and physical handling. View a grouping per inventory posting group and item, with a calculated total per group.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrintDetails; PrintDetails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Details';
                        ToolTip = 'Specifies if you want to print a detailed list of each of the value entries that are related to each of the item charge numbers that you have set up in the Item Charge table. ';
                    }
                    field(SourceType; SourceType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Source Type';
                        OptionCaption = 'Sale,Purchase';
                        ToolTip = 'Specifies if you want to have the report show item charges assigned to sales documents or purchase documents.';
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
        ValueEntryFilter := "Value Entry".GetFilters();

        ReportTitle := Text000;
        if PrintDetails then
            ReportTitle := Text001;
    end;

    var
        Item: Record Item;
        PrintDetails: Boolean;
        ReportTitle: Text[100];
        ValueEntryFilter: Text;
        ValueEntryItemNo: Text[80];
        ValueEntryPostingDate: Text[80];
        ValueEntryDocNo: Text[80];
        ValueEntrySourceType: Text[80];
        ValueEntrySourceNo: Text[80];
        ValueEntryQuantity: Text[80];
        ItemDescription: Text[100];
        SourceType: Option Sale,Purchase;
        SourceTypePurch: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Item Charges - Overview';
        Text001: Label 'Item Charges - Specification';
        Text002: Label ' (Sales)';
        Text003: Label ' (Purchases)';
        Text004: Label 'Inventory Posting Group';
        Text005: Label 'Group Subtotal';
        Text006: Label 'Inventory Posting Group Subtotal';
        Text007: Label 'Group Total';
#pragma warning restore AA0074
        CurrReportPageNoCaptionLbl: Label 'Page';
        ValueEntryCostAmtActlCptnLbl: Label 'Amount';
        TotalCaptionLbl: Label 'Total';

    procedure InitializeRequest(NewPrintDetails: Boolean; NewSourceType: Option)
    begin
        PrintDetails := NewPrintDetails;
        SourceType := NewSourceType;
    end;
}

