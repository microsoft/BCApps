// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

report 99000763 "Prod. Order - List"
{
    DefaultRenderingLayout = ProdOrderListExcel;
    ApplicationArea = Manufacturing;
    Caption = 'Production Order - List';
    UsageCategory = ReportsAndAnalysis;
    AdditionalSearchTerms = 'Prod. Order - List';

    dataset
    {
        dataitem("Production Order"; "Production Order")
        {
            DataItemTableView = sorting(Status, "No.");
            RequestFilterFields = "No.", Status, "Source No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Production_Order__TABLECAPTION_________ProdOrderFilter; TableCaption + ': ' + ProdOrderFilter)
            {
            }
            column(ProdOrderFilter; ProdOrderFilter)
            {
            }
            column(Production_Order__No__; "No.")
            {
                IncludeCaption = true;
            }
            column(Production_Order_Description; Description)
            {
                IncludeCaption = true;
            }
            column(Production_Order__Source_No__; "Source No.")
            {
                IncludeCaption = true;
            }
            column(Production_Order__Routing_No__; "Routing No.")
            {
                IncludeCaption = true;
            }
            column(Production_Order__Starting_Date_; "Starting Date")
            {
                IncludeCaption = true;
            }
            column(Production_Order__Ending_Date_; "Ending Date")
            {
                IncludeCaption = true;
            }
            column(Production_Order__Due_Date_; "Due Date")
            {
                IncludeCaption = true;
            }
            column(Production_Order_Status; Status)
            {
                IncludeCaption = true;
            }
            column(Production_Order_Quantity; Quantity)
            {
                IncludeCaption = true;
            }
            // RDLC Only
            column(Production_Order_Status_Control8; Status)
            {
            }
            // RDLC Only
            column(Prod__Order___ListCaption; Prod__Order___ListCaptionLbl)
            {
            }
            // RDLC Only
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            // RDLC Only
            column(Production_Order__No__Caption; FieldCaption("No."))
            {
            }
            // RDLC Only
            column(Production_Order_DescriptionCaption; FieldCaption(Description))
            {
            }
            // RDLC Only
            column(Production_Order__Source_No__Caption; FieldCaption("Source No."))
            {
            }
            // RDLC Only
            column(Production_Order__Routing_No__Caption; FieldCaption("Routing No."))
            {
            }
            // RDLC Only
            column(Production_Order__Starting_Date_Caption; Production_Order__Starting_Date_CaptionLbl)
            {
            }
            // RDLC Only
            column(Production_Order__Ending_Date_Caption; Production_Order__Ending_Date_CaptionLbl)
            {
            }
            // RDLC Only
            column(Production_Order__Due_Date_Caption; Production_Order__Due_Date_CaptionLbl)
            {
            }
            // RDLC Only
            column(Production_Order_StatusCaption; FieldCaption(Status))
            {
            }
            // RDLC Only
            column(Production_Order_QuantityCaption; FieldCaption(Quantity))
            {
            }
            column(Production_Order__Location_Code; "Location Code")
            {
                IncludeCaption = true;
            }

            trigger OnPreDataItem()
            begin
                ProdOrderFilter := GetFilters();
            end;
        }
        dataitem("Prod. Order Line"; "Prod. Order Line")
        {
            DataItemTableView = sorting(Status, "Prod. Order No.", "Line No.");
            RequestFilterFields = "Prod. Order No.", Status, "Item No.";
            column(ProdOrderLineTableCaptFilter; TableCaption + ': ' + ProdOrderLineFilter)
            {
            }
            column(ProdOrderLineFilter; ProdOrderLineFilter)
            {
            }
            column(ProdOrderLineStatus; "Prod. Order Line".Status)
            {
                IncludeCaption = true;
            }
            column(ProdOrderLineProdOrderNo; "Prod. Order Line"."Prod. Order No.")
            {
                IncludeCaption = true;
            }
            column(ProdOrderLineLineNo; "Prod. Order Line"."Line No.")
            {
                IncludeCaption = true;
            }
            column(ProdOrderLineItemNo; "Prod. Order Line"."Item No.")
            {
                IncludeCaption = true;
            }
            column(ProdOrderLineDescription; "Prod. Order Line".Description)
            {
                IncludeCaption = true;
            }
            column(ProdOrderLineProdBOMNo; "Prod. Order Line"."Production BOM No.")
            {
                IncludeCaption = true;
            }
            column(ProdOrderLineRoutingNo; "Prod. Order Line"."Routing No.")
            {
                IncludeCaption = true;
            }
            column(ProdOrderLineStartingDate; "Prod. Order Line"."Starting Date")
            {
                IncludeCaption = true;
            }
            column(ProdOrderLineEndingDate; "Prod. Order Line"."Ending Date")
            {
                IncludeCaption = true;
            }
            column(ProdOrderLineDueDate; "Prod. Order Line"."Due Date")
            {
                IncludeCaption = true;
            }
            column(ProdOrderLineQuantity; "Prod. Order Line".Quantity)
            {
                IncludeCaption = true;
            }
            column(ProdOrderLineUOMCode; "Prod. Order Line"."Unit of Measure Code")
            {
                IncludeCaption = true;
            }
            column(ProdOrderLineUnitCost; "Prod. Order Line"."Unit Cost")
            {
                IncludeCaption = true;
            }
            column(ProdOrderLineCostAmount; "Prod. Order Line"."Cost Amount")
            {
                IncludeCaption = true;
            }
            column(ProdOrderLineLocationCode; "Prod. Order Line"."Location Code")
            {
                IncludeCaption = true;
            }
            column(ProdOrderLineFinishedQuantity; "Prod. Order Line"."Finished Quantity")
            {
                IncludeCaption = true;
            }
            column(ProdOrderLineRemainingQuantity; "Prod. Order Line"."Remaining Quantity")
            {
                IncludeCaption = true;
            }

            trigger OnPreDataItem()
            begin
                ProdOrderLineFilter := "Prod. Order Line".GetFilters();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Production Order - List';
        AboutText = 'View a list of the production orders contained in the system. Information such as order number, number of the item to be produced, starting/ending date and other data are shown or printed.';

        layout
        {
        }

        actions
        {
        }
    }

    rendering
    {
        layout(ProdOrderListRDLC)
        {
            Type = RDLC;
            LayoutFile = './Manufacturing/Document/ProdOrderList.rdlc';
            Caption = 'Production Order - List (RDLC)';
        }
        layout(ProdOrderListExcel)
        {
            Type = Excel;
            LayoutFile = './Manufacturing/Document/ProdOrderList.xlsx';
            Caption = 'Production Order - List (Excel)';
            ExcelLayoutMultipleDataSheets = true;
        }
    }

    labels
    {
        ProdOrderList = 'Prod. Order - List';
        ProdOrderListPrint = 'Prod. Order - List (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        ProdOrderListAnalysis = 'Prod. Order - List (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        ProdOrderLineList = 'Prod. Order Line - List';
        ProdOrderLineListPrint = 'Prod. Order Line - List (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        ProdOrderLineListAnalysis = 'Prod. Order Line (Analysis)', MaxLength = 31, Comment = 'Max length: 31. Excel worksheet name.';
        DataRetrieved = 'Data retrieved:';
        // About the report labels
        AboutTheReportLabel = 'About the report';
        EnvironmentLabel = 'Environment';
        CompanyLabel = 'Company';
        UserLabel = 'User';
        RunOnLabel = 'Run on';
        ReportNameLabel = 'Report name';
        DocumentationLabel = 'Documentation';
    }

    var
        ProdOrderFilter: Text;
        ProdOrderLineFilter: Text;
        Prod__Order___ListCaptionLbl: Label 'Prod. Order - List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Production_Order__Starting_Date_CaptionLbl: Label 'Starting Date';
        Production_Order__Ending_Date_CaptionLbl: Label 'Ending Date';
        Production_Order__Due_Date_CaptionLbl: Label 'Due Date';
}

