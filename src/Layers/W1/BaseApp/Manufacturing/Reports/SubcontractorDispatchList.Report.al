// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

report 99000789 "Subcontractor - Dispatch List"
{
    DefaultRenderingLayout = WordLayout;
    ApplicationArea = Manufacturing;
    Caption = 'Subcontractor - Dispatch List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(No_Vendor; "No.")
            {
            }
            // RDLC Only
            column(Name_VendorCaption; FieldCaption(Name))
            {
            }
            // RDLC Only
            column(No_VendorCaption; FieldCaption("No."))
            {
            }
            column(Name_Vendor; Name)
            {
            }
            // RDLC Only
            column(OprtnNo_ProdOrderRtngLineCaption; "Prod. Order Routing Line".FieldCaption("Operation No."))
            {
            }
            // RDLC Only
            column(PONo_ProdOrderRtngLineCaption; "Prod. Order Routing Line".FieldCaption("Prod. Order No."))
            {
            }
            // RDLC Only
            column(Desc_ProdOrderRtngLineCaption; "Prod. Order Routing Line".FieldCaption(Description))
            {
            }
            // RDLC Only
            column(RemaingQty_ProdOrderLineCaption; "Prod. Order Line".FieldCaption("Remaining Quantity"))
            {
            }
            // RDLC Only
            column(UOMCode_ProdOrderLineCaption; "Prod. Order Line".FieldCaption("Unit of Measure Code"))
            {
            }
            // RDLC Only
            column(SubcntrctrDispatchistCapt; SubcntrctrDispatchistCaptLbl)
            {
            }
            // RDLC Only
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            // RDLC Only
            column(ProdOrdRtngLnStrtDtCapt; ProdOrdRtngLnStrtDtCaptLbl)
            {
            }
            // RDLC Only
            column(ProdOrdRtngLnEndDtCapt; ProdOrdRtngLnEndDtCaptLbl)
            {
            }
            // RDLC Only
            column(PurchLineDocNoCaption; PurchLineDocNoCaptionLbl)
            {
            }
            // RDLC Only
            column(PurchLineOutstandgQtyCapt; PurchLineOutstandgQtyCaptLbl)
            {
            }
            dataitem("Work Center"; "Work Center")
            {
                DataItemLink = "Subcontractor No." = field("No.");
                DataItemTableView = sorting("Subcontractor No.");
                PrintOnlyIfDetail = true;
                RequestFilterFields = "No.";
                column(No_WorkCenter; "No.")
                {
                }
                column(Name_WorkCenter; Name)
                {
                }
                // RDLC Only
                column(No_WorkCenterCaption; FieldCaption("No."))
                {
                }
                // RDLC Only
                column(Name_WorkCenterCaption; FieldCaption(Name))
                {
                }
                dataitem("Prod. Order Routing Line"; "Prod. Order Routing Line")
                {
                    DataItemLink = "Work Center No." = field("No.");
                    DataItemTableView = sorting(Status, "Work Center No.") where(Status = const(Released));
                    PrintOnlyIfDetail = true;
                    RequestFilterFields = "Prod. Order No.", "Starting Date", "Ending Date";
                    column(OprtnNo_ProdOrderRtngLine; "Operation No.")
                    {
                    }
                    column(PONo_ProdOrderRtngLine; "Prod. Order No.")
                    {
                    }
                    column(Desc_ProdOrderRtngLine; Description)
                    {
                    }
                    column(StrtDt_ProdOrderRtngLine; Format("Starting Date"))
                    {
                    }
                    column(EndDate_ProdOrderRtngLine; Format("Ending Date"))
                    {
                    }
                    dataitem("Prod. Order Line"; "Prod. Order Line")
                    {
                        DataItemLink = Status = field(Status), "Prod. Order No." = field("Prod. Order No."), "Routing No." = field("Routing No.");
                        DataItemTableView = sorting(Status, "Prod. Order No.", "Routing No.");
                        column(ItemNo_ProdOrderLine; "Item No.")
                        {
                        }
                        column(UOMCode_ProdOrderLine; "Unit of Measure Code")
                        {
                        }
                        column(RemaingQty_ProdOrderLine; "Remaining Quantity")
                        {
                        }
                        column(Desc_ProdOrderLine; Description)
                        {
                        }
                        column(PurchLineDocNo; PurchLine."Document No.")
                        {
                        }
                        column(PurchLineOutstandingQty; PurchLine."Outstanding Quantity")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        dataitem("Prod. Order Component"; "Prod. Order Component")
                        {
                            DataItemLink = Status = field(Status), "Prod. Order No." = field("Prod. Order No."), "Prod. Order Line No." = field("Line No.");
                            DataItemTableView = sorting(Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.");
                            column(ItemNo_ProdOrderComp; "Item No.")
                            {
                            }
                            column(Desc_ProdOrderComp; Description)
                            {
                            }
                            column(RemaingQty_ProdOrderComp; "Remaining Quantity")
                            {
                            }
                            column(UOMCode_ProdOrderComp; "Unit of Measure Code")
                            {
                            }
                            column(PONo_ProdOrderComp; "Prod. Order No.")
                            {
                            }
                            // RDLC Only
                            column(ComponentsneededCaption; ComponentsneededCaptionLbl)
                            {
                            }
                            trigger OnPreDataItem()
                            begin
                                if "Prod. Order Routing Line"."Previous Operation No." <> '' then begin
                                    if "Prod. Order Routing Line"."Routing Link Code" = '' then
                                        CurrReport.Break();

                                    SetRange("Routing Link Code", "Prod. Order Routing Line"."Routing Link Code");
                                end else
                                    SetFilter("Routing Link Code", '%1|%2', '', "Prod. Order Routing Line"."Routing Link Code");

                                SetFilter("Remaining Quantity", '<>0');
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            PurchLine.SetCurrentKey(
                              "Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
                            PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
                            PurchLine.SetRange("Prod. Order No.", "Prod. Order No.");
                            PurchLine.SetRange(Type, PurchLine.Type::Item);
                            PurchLine.SetRange("No.", "Item No.");
                            PurchLine.SetRange("Routing No.", "Prod. Order Routing Line"."Routing No.");
                            PurchLine.SetRange("Operation No.", "Prod. Order Routing Line"."Operation No.");
                            if not PurchLine.FindFirst() then
                                Clear(PurchLine);
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetFilter("Remaining Quantity", '<>0');
                        end;
                    }
                }
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Subcontractor - Dispatch List';
        AboutText = 'Helps you manage and track subcontracting activities efficiently.';
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    Visible = false;
                    // Used to set the date filter on the report header across multiple languages
                    field(RequestDateFilter; DateFilter)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Date Filter';
                        ToolTip = 'Specifies the Date Filter applied to the Subcontractor - Dispatch List Report.';
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
            DateFilter := "Prod. Order Routing Line".GetFilter("Starting Date") + '..' + "Prod. Order Routing Line".GetFilter("Ending Date");
            if DateFilter = '..' then
                DateFilter := '';
        end;
    }

    rendering
    {
        layout(WordLayout)
        {
            Type = Word;
            LayoutFile = './Manufacturing/Reports/SubcontractorDispatchList.docx';
        }
        layout(ExcelLayout)
        {
            Type = Excel;
            LayoutFile = './Manufacturing/Reports/SubcontractorDispatchList.xlsx';
        }
#if not CLEAN27
        layout(RDLCLayout)
        {
            Type = RDLC;
            LayoutFile = './Manufacturing/Reports/SubcontractorDispatchList.rdlc';
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by the Excel layout and will be removed in a future release.';
            ObsoleteTag = '27.0';
        }
#endif
    }

    labels
    {
        SubDispatchList = 'Subcontractor Dispatch List';
        SubDispatchListPrint = 'Subc. Dispatch List (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        SubDispatchListAnalysis = 'Subc. Dispatch List (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        PeriodLabel = 'Period:';
        // Excel/Word layout field captions. To be replaced with the IncludeCaption property in a future release along with RDLC layout removal.
        No_VendorLbl = 'No.';
        Name_VendorLbl = 'Name';
        No_WorkCenterLbl = 'No.';
        Name_WorkCenterLbl = 'Name';
        PONo_ProdOrderRtngLineLbl = 'Prod. Order No.';
        OprtnNo_ProdOrderRtngLineLbl = 'Operation No.';
        Desc_ProdOrderRtngLineLbl = 'Description';
        StrtDt_ProdOrderRtngLineLbl = 'Starting Date';
        EndDate_ProdOrderRtngLineLbl = 'Ending Date';
        ItemNo_ProdOrderLineLbl = 'Item No.';
        Desc_ProdOrderLineLbl = 'Description';
        RemaingQty_ProdOrderLineLbl = 'Remaining Quantity';
        PurchLineDocNoLbl = 'Purch. Order No.';
        PurchLineOutstandingQtyLbl = 'Qty. on Purch. Order';
        UOMCode_ProdOrderLineLbl = 'Unit of Measure Code';
        ItemNo_ProdOrderCompLbl = 'Component Item No.';
        Desc_ProdOrderCompLbl = 'Component Item Description';
        PONo_ProdOrderCompLbl = 'Component Purch. Order No.';
        RemaingQty_ProdOrderCompLbl = 'Component Remaining Quantity';
        UOMCode_ProdOrderCompLbl = 'Component Unit of Measure Code';
        DataRetrieved = 'Data retrieved:';
        // About the report labels
        AboutTheReportLabel = 'About the report', MaxLength = 31, Comment = 'Excel worksheet name.';
        EnvironmentLabel = 'Environment';
        CompanyLabel = 'Company';
        UserLabel = 'User';
        RunOnLabel = 'Run on';
        ReportNameLabel = 'Report name';
        DocumentationLabel = 'Documentation';
    }

    var
        PurchLine: Record "Purchase Line";
        DateFilter: Text;
        SubcntrctrDispatchistCaptLbl: Label 'Subcontractor Dispatch List';
        CurrReportPageNoCaptionLbl: Label 'Page';
        ProdOrdRtngLnStrtDtCaptLbl: Label 'Starting Date';
        ProdOrdRtngLnEndDtCaptLbl: Label 'Ending Date';
        PurchLineDocNoCaptionLbl: Label 'Purch. Order No.';
        PurchLineOutstandgQtyCaptLbl: Label 'Qty. on Purch. Order';
        ComponentsneededCaptionLbl: Label 'Components needed';
}