// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 714 "Inventory - Vendor Purchases"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory - Vendor Purchases';
    DefaultRenderingLayout = Word;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(ReportHeader; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(0));
            column(ItemFilter; ItemFilter)
            {
            }
            column(ItemLedgEntryFilter; ItemLedgEntryFilter)
            {
            }
#if not CLEAN28
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(PeriodText; PeriodText)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
#endif
        }
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "No. 2", "Search Description", "Assembly BOM", "Inventory Posting Group";
            column(No_Item; "No.")
            {
            }
            column(Desc_Item; Description)
            {
            }
            column(BaseUOM_Item; "Base Unit of Measure")
            {
                IncludeCaption = true;
            }
            dataitem("Value Entry"; "Value Entry")
            {
                DataItemLink = "Item No." = field("No."), "Variant Code" = field("Variant Filter"), "Location Code" = field("Location Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Source Type", "Source No.", "Item No.") where("Source Type" = const(Vendor), "Expected Cost" = const(false));
                RequestFilterFields = "Posting Date", "Source No.", "Source Posting Group";

                trigger OnAfterGetRecord()
                begin
                    FillTempValueEntry("Value Entry");

                    CurrReport.Skip();
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(> 0));
                column(SourceNo_ValueEntry; TempValueEntry."Source No.")
                {
                }
                column(VendName; Vendor.Name)
                {
                    IncludeCaption = true;
                }
                column(InvQty_ValueEntry; TempValueEntry."Invoiced Quantity")
                {
                    IncludeCaption = true;
                }
                column(CostAmtAct_ValueEntry; TempValueEntry."Cost Amount (Actual)")
                {
                    IncludeCaption = true;
                }
                column(DiscAmt_ValueEntry; TempValueEntry."Discount Amount")
                {
                    IncludeCaption = true;
                }

                trigger OnAfterGetRecord()
                begin
                    TempValueEntry.SetRange("Source No.");

                    if Number = 1 then
                        TempValueEntry.FindSet()
                    else
                        if TempValueEntry.Next() = 0 then
                            CurrReport.Break();

                    if not Vendor.Get(TempValueEntry."Source No.") then
                        Clear(Vendor);

                    SubtotalsInvoicedQuantity += TempValueEntry."Invoiced Quantity";
                    SubtotalsCostAmount += TempValueEntry."Cost Amount (Actual)";
                    SubtotalsDiscountAmount += TempValueEntry."Discount Amount";

                    TotalsCostAmount += TempValueEntry."Cost Amount (Actual)";
                    TotalsDiscountAmount += TempValueEntry."Discount Amount";
                end;

                trigger OnPreDataItem()
                begin
                    if TempValueEntry.IsEmpty() then
                        CurrReport.Break();
                end;
            }
            dataitem(Subtotals; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                column(Subtotals_InvoicedQuantity; SubtotalsInvoicedQuantity)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(Subtotals_CostAmount; SubtotalsCostAmount)
                {
                    AutoFormatType = 1;
                }
                column(Subtotals_DiscountAmount; SubtotalsDiscountAmount)
                {
                    AutoFormatType = 1;
                }

                trigger OnPreDataItem()
                begin
                    if TempValueEntry.IsEmpty() then
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TempValueEntry.DeleteAll();

                Clear(SubtotalsInvoicedQuantity);
                Clear(SubtotalsCostAmount);
                Clear(SubtotalsDiscountAmount);
            end;
        }
        dataitem(Totals; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(Totals_CostAmount; TotalsCostAmount)
            {
                AutoFormatType = 1;
            }
            column(Totals_DiscountAmount; TotalsDiscountAmount)
            {
                AutoFormatType = 1;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Inventory - Vendor Purchases';
        AboutText = 'Analyse your vendor purchases per item to manage inventory procurement and improve supply chain processes. Assess the relationship between discounts, cost amount with volume of item purchases for each vendor/item combination in the given period.';

        layout
        {
            area(Content)
            {
                // Used to set report headers across multiple languages
                field(RequestItemFilter; ItemFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies the Item Filters applied to this report.';
                    Visible = false;
                }
                field(RequestItemLedgEntryFilter; ItemLedgEntryFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Item Ledger Entry Filter';
                    ToolTip = 'Specifies the Item Ledger Entry Filters applied to this report.';
                    Visible = false;
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
            Caption = 'Inventory - Vendor Purchases Excel';
            Type = Excel;
            LayoutFile = './Inventory/Reports/InventoryVendorPurchases.xlsx';
            Summary = 'Built in layout for the Inventory - Vendor Purchases Excel report.';
        }
        layout(Word)
        {
            Caption = 'Inventory - Vendor Purchases Word';
            Type = Word;
            LayoutFile = './Inventory/Reports/InventoryVendorPurchases.docx';
            Summary = 'Built in layout for the Inventory - Vendor Purchases Word report.';
        }
#if not CLEAN28
        layout(RDLC)
        {
            Caption = 'Inventory - Vendor Purchases RDLC (Obsolete)';
            Type = RDLC;
            LayoutFile = './Inventory/Reports/InventoryVendorPurchases.rdlc';
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by an Excel layout and will be removed in a future release.';
            ObsoleteTag = '28.0';
            Summary = 'Built in layout for the Inventory - Vendor Purchases RDLC (Obsolete) report.';
        }
#endif
    }

    labels
    {
#if not CLEAN28
        PageCaption = 'Page';
        ReportTitle = 'Inventory - Vendor Purchases';
        VendorNoCaption = 'Vendor No.';
        NameCaption = 'Name';
        TotalCaption = 'Total';
#endif
        InvVendorPurchLbl = 'Inventory - Vendor Purchases';
        InvVendorPurchPrintLbl = 'Inv. - Vend. Purch. (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        InvVendorPurchAnalysisLbl = 'Inv. - Vend. Purch. (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        DataRetrievedLbl = 'Data retrieved:';
        TotalLbl = 'Total';
        VendorNoLbl = 'Vendor No.';
        ItemNoLbl = 'Item No.';
        DescriptionLbl = 'Description';
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
        Vendor: Record Vendor;
        TempValueEntry: Record "Value Entry" temporary;
        SubtotalsInvoicedQuantity: Decimal;
        SubtotalsCostAmount: Decimal;
        SubtotalsDiscountAmount: Decimal;
        TotalsCostAmount: Decimal;
        TotalsDiscountAmount: Decimal;
#if not CLEAN28
        PeriodText: Text;
        PeriodInfoTxt: Label 'Period: %1', Comment = '%1 - period name';
#endif
        ItemFilter: Text;
        ItemLedgEntryFilter: Text;

        TableFiltersTxt: Label '%1: %2', Locked = true;

    local procedure FillTempValueEntry(ValueEntry: Record "Value Entry")
    begin
        TempValueEntry.SetRange("Source No.", ValueEntry."Source No.");
        if not TempValueEntry.FindSet() then begin
            TempValueEntry.Init();
            TempValueEntry := "Value Entry";
            TempValueEntry.Insert();
        end else begin
            TempValueEntry."Cost Amount (Actual)" := TempValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Actual)";
            TempValueEntry."Invoiced Quantity" := TempValueEntry."Invoiced Quantity" + ValueEntry."Invoiced Quantity";
            TempValueEntry."Discount Amount" := TempValueEntry."Discount Amount" + ValueEntry."Discount Amount";
            TempValueEntry.Modify();
        end;
    end;

    local procedure GetTableFilters(TableName: Text; Filters: Text): Text
    begin
        if Filters <> '' then
            exit(StrSubstNo(TableFiltersTxt, TableName, Filters));
        exit('');
    end;

    // Ensures Layout Filter Headings are up to date
    local procedure UpdateRequestPageFilterValues()
    begin
        ItemFilter := GetTableFilters(Item.TableCaption(), Item.GetFilters);
        ItemLedgEntryFilter := GetTableFilters("Value Entry".TableCaption(), "Value Entry".GetFilters);
#if not CLEAN28
        PeriodText := StrSubstNo(PeriodInfoTxt, "Value Entry".GetFilter("Posting Date"));
#endif
    end;
}