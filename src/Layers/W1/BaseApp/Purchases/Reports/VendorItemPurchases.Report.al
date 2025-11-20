// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;

report 313 "Vendor/Item Purchases"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Reports/VendorItemPurchases.rdlc';
    AdditionalSearchTerms = 'vendor priority';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor/Item Purchases';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", "Vendor Posting Group";
            column(STRSUBSTNO_Text000_PeriodText_; StrSubstNo(PeriodTxt, PeriodText))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(STRSUBSTNO___1___2__Vendor_TABLECAPTION_VendFilter_; StrSubstNo(TableFilterTxt, TableCaption(), VendFilter))
            {
            }
            column(VendFilter; VendFilter)
            {
            }
            column(STRSUBSTNO___1___2___Value_Entry__TABLECAPTION_ItemLedgEntryFilter_; StrSubstNo(TableFilterTxt, "Value Entry".TableCaption(), ItemLedgEntryFilter))
            {
            }
            column(ItemLedgEntryFilter; ItemLedgEntryFilter)
            {
            }
            column(Vendor__No__; "No.")
            {
            }
            column(Vendor_Name; Name)
            {
            }
            column(Vendor__Phone_No__; "Phone No.")
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(Value_Entry__Item_No__Caption; "Value Entry".FieldCaption("Item No."))
            {
            }
            column(Value_Entry__Invoiced_Quantity_Caption; "Value Entry".FieldCaption("Invoiced Quantity"))
            {
            }
            column(Value_Entry__Cost_Amount__Actual__Caption; "Value Entry".FieldCaption("Cost Amount (Actual)"))
            {
            }
            column(Value_Entry__Discount_Amount_Caption; "Value Entry".FieldCaption("Discount Amount"))
            {
            }
            column(Vendor__Phone_No__Caption; FieldCaption("Phone No."))
            {
            }
            dataitem("Value Entry"; "Value Entry")
            {
                DataItemLink = "Source No." = field("No."), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Source Type", "Source No.", "Item No.", "Posting Date") where("Source Type" = const(Vendor), "Expected Cost" = const(false));
                RequestFilterFields = "Posting Date", "Item No.", "Inventory Posting Group";
                column(Value_Entry__Item_No__; "Item No.")
                {
                }
                column(Item_Description; Item.Description)
                {
                }
                column(Value_Entry__Invoiced_Quantity_; InvoicedQuantity)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(Item__Base_Unit_of_Measure_; Item."Base Unit of Measure")
                {
                }
                column(Value_Entry___Cost_Amount__Actual__; CostAmountActual)
                {
                }
                column(Value_Entry___Discount_Amount_; DiscountAmount)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not Item.Get("Item No.") then
                        Item.Init();

                    if ResetItemTotal then begin
                        ResetItemTotal := false;
                        InvoicedQuantity := "Invoiced Quantity";
                        CostAmountActual := "Cost Amount (Actual)";
                        DiscountAmount := "Discount Amount";
                    end else begin
                        InvoicedQuantity += "Invoiced Quantity";
                        CostAmountActual += "Cost Amount (Actual)";
                        DiscountAmount += "Discount Amount";
                    end;

                    if not (ValueEntry.Next() = 0) then begin
                        if ValueEntry."Item No." = "Item No." then
                            CurrReport.Skip();
                        ResetItemTotal := true
                    end
                end;

                trigger OnPreDataItem()
                begin
                    ResetItemTotal := true;
                    ValueEntry.SetCurrentKey("Source Type", "Source No.", "Item No.", "Posting Date");
                    ValueEntry.CopyFilters("Value Entry");
                    if ValueEntry.FindSet() then;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if PrintOnlyOnePerPageReq then
                    PageGroupNo := PageGroupNo + 1;
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Vendor/Item Purchases';
        AboutText = 'Analyse your item purchases per vendor to manage inventory procurement and improve supply chain processes. Assess the relationship between discounts, cost amount with volume of item purchases for each vendor/item combination in the given period.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrintOnlyOnePerPage; PrintOnlyOnePerPageReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Vendor';
                        ToolTip = 'Specifies if each vendor''s information is printed on a new page if you have chosen two or more vendors to be included in the report.';
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
        ReportNameLabel = 'Vendor/Item Purchases';
        PageLabel = 'Page';
        AllAmountsinLCYLabel = 'All amounts are in LCY';
        DescriptionLabel = 'Description';
        UnitOfMeasureLabel = 'Unit of Measure';
        TotalLabel = 'Total';
    }

    trigger OnPreReport()
    var
        FormatDocument: Codeunit "Format Document";
    begin
        VendFilter := FormatDocument.GetRecordFiltersWithCaptions(Vendor);
        ItemLedgEntryFilter := "Value Entry".GetFilters();
        PeriodText := "Value Entry".GetFilter("Posting Date");
    end;

    var
        Item: Record Item;
        ValueEntry: Record "Value Entry";
        VendFilter: Text;
        ItemLedgEntryFilter: Text;
        PeriodText: Text;
        PrintOnlyOnePerPageReq: Boolean;
        PageGroupNo: Integer;
        InvoicedQuantity: Decimal;
        CostAmountActual: Decimal;
        DiscountAmount: Decimal;

        PeriodTxt: Label 'Period: %1', Comment = '%1 - period text';
        TableFilterTxt: Label '%1: %2', Locked = true;

    protected var
        ResetItemTotal: Boolean;

    procedure InitializeRequest(NewPrintOnlyOnePerPage: Boolean)
    begin
        PrintOnlyOnePerPageReq := NewPrintOnlyOnePerPage;
    end;
}

