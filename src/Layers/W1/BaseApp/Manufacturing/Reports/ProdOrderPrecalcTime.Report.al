// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.WorkCenter;

report 99000764 "Prod. Order - Precalc. Time"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Manufacturing/Reports/ProdOrderPrecalcTime.rdlc';
    ApplicationArea = Manufacturing;
    Caption = 'Prod. Order - Precalc. Time';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Production Order"; "Production Order")
        {
            DataItemTableView = sorting(Status, "No.");
            RequestFilterFields = Status, "No.", "Source No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Line; Line)
            {
            }
            column(Production_Order__TABLECAPTION_________ProdOrderFilter; TableCaption + ':' + ProdOrderFilter)
            {
            }
            column(ProdOrderFilter; ProdOrderFilter)
            {
            }
            column(Production_Order__No__; "No.")
            {
            }
            column(Production_Order_Description; Description)
            {
            }
            column(Production_Order__Source_No__; "Source No.")
            {
            }
            column(Production_Order__Starting_Date_; Format("Starting Date"))
            {
            }
            column(Production_Order__Ending_Date_; Format("Ending Date"))
            {
            }
            column(Production_Order__Due_Date_; Format("Due Date"))
            {
            }
            column(Production_Order_Quantity; Quantity)
            {
            }
            column(Production_Order_Status; Status)
            {
            }
            column(Prod__Order___Precalc__TimeCaption; Prod__Order___Precalc__TimeCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Production_Order__No__Caption; FieldCaption("No."))
            {
            }
            column(Production_Order_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Production_Order__Source_No__Caption; FieldCaption("Source No."))
            {
            }
            column(Production_Order__Starting_Date_Caption; Production_Order__Starting_Date_CaptionLbl)
            {
            }
            column(Production_Order__Ending_Date_Caption; Production_Order__Ending_Date_CaptionLbl)
            {
            }
            column(Production_Order__Due_Date_Caption; Production_Order__Due_Date_CaptionLbl)
            {
            }
            column(Production_Order_QuantityCaption; FieldCaption(Quantity))
            {
            }
            dataitem("Prod. Order Routing Line"; "Prod. Order Routing Line")
            {
                DataItemLink = Status = field(Status), "Prod. Order No." = field("No.");
                DataItemTableView = sorting(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
                column(Prod__Order_Routing_Line__Operation_No__; "Operation No.")
                {
                }
                column(Prod__Order_Routing_Line_Type; Type)
                {
                }
                column(Prod__Order_Routing_Line__No__; "No.")
                {
                }
                column(Prod__Order_Routing_Line_Description; Description)
                {
                }
                column(Prod__Order_Routing_Line__Starting_Time_; "Starting Time")
                {
                }
                column(Prod__Order_Routing_Line__Starting_Date_; Format("Starting Date"))
                {
                }
                column(Prod__Order_Routing_Line__Ending_Time_; "Ending Time")
                {
                }
                column(Prod__Order_Routing_Line__Ending_Date_; Format("Ending Date"))
                {
                }
                column(Prod__Order_Routing_Line__Input_Quantity_; "Input Quantity")
                {
                }
                column(Prod__Order_Routing_Line__Expected_Capacity_Need_; "Expected Capacity Need")
                {
                }
                column(Prod__Order_Routing_Line__Operation_No__Caption; FieldCaption("Operation No."))
                {
                }
                column(Prod__Order_Routing_Line_TypeCaption; FieldCaption(Type))
                {
                }
                column(Prod__Order_Routing_Line__No__Caption; FieldCaption("No."))
                {
                }
                column(Prod__Order_Routing_Line__Starting_Time_Caption; FieldCaption("Starting Time"))
                {
                }
                column(Prod__Order_Routing_Line__Starting_Date_Caption; Prod__Order_Routing_Line__Starting_Date_CaptionLbl)
                {
                }
                column(Prod__Order_Routing_Line__Ending_Time_Caption; FieldCaption("Ending Time"))
                {
                }
                column(Prod__Order_Routing_Line__Ending_Date_Caption; Prod__Order_Routing_Line__Ending_Date_CaptionLbl)
                {
                }
                column(Prod__Order_Routing_Line__Input_Quantity_Caption; FieldCaption("Input Quantity"))
                {
                }
                column(Prod__Order_Routing_Line__Expected_Capacity_Need_Caption; FieldCaption("Expected Capacity Need"))
                {
                }

                trigger OnAfterGetRecord()
                var
                    WorkCenter: Record "Work Center";
                    CalendarMgt: Codeunit "Shop Calendar Management";
                begin
                    Line := 1;
                    WorkCenter.Get("Work Center No.");
                    "Expected Capacity Need" := "Expected Capacity Need" / CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code");
                end;
            }
            dataitem("Prod. Order Component"; "Prod. Order Component")
            {
                DataItemLink = Status = field(Status), "Prod. Order No." = field("No.");
                DataItemTableView = sorting(Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.");
                column(Prod__Order_Component__Item_No__; "Item No.")
                {
                }
                column(Prod__Order_Component_Description; Description)
                {
                }
                column(Prod__Order_Component__Quantity_per_; "Quantity per")
                {
                }
                column(Prod__Order_Component__Scrap___; "Scrap %")
                {
                }
                column(Prod__Order_Component__Routing_Link_Code_; "Routing Link Code")
                {
                }
                column(Prod__Order_Component__Due_Date_; Format("Due Date"))
                {
                }
                column(Prod__Order_Component__Expected_Quantity_; "Expected Quantity")
                {
                }
                column(Prod__Order_Component__Item_No__Caption; FieldCaption("Item No."))
                {
                }
                column(Prod__Order_Component_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(Prod__Order_Component__Quantity_per_Caption; FieldCaption("Quantity per"))
                {
                }
                column(Prod__Order_Component__Scrap___Caption; FieldCaption("Scrap %"))
                {
                }
                column(Prod__Order_Component__Routing_Link_Code_Caption; FieldCaption("Routing Link Code"))
                {
                }
                column(Prod__Order_Component__Due_Date_Caption; Prod__Order_Component__Due_Date_CaptionLbl)
                {
                }
                column(Prod__Order_Component__Expected_Quantity_Caption; FieldCaption("Expected Quantity"))
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Line := 2;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Line := 0;
            end;

            trigger OnPreDataItem()
            begin
                ProdOrderFilter := GetFilters();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Prod. Order - Precalc. Time';
        AboutText = 'Helps you plan and schedule production activities by estimating the time needed to complete each production order based on factors such as work centers, machine centers, and routing information.';

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
        ProdOrderFilter: Text;
        Line: Integer;
        Prod__Order___Precalc__TimeCaptionLbl: Label 'Prod. Order - Precalc. Time';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Production_Order__Starting_Date_CaptionLbl: Label 'Starting Date';
        Production_Order__Ending_Date_CaptionLbl: Label 'Ending Date';
        Production_Order__Due_Date_CaptionLbl: Label 'Due Date';
        Prod__Order_Routing_Line__Starting_Date_CaptionLbl: Label 'Starting Date';
        Prod__Order_Routing_Line__Ending_Date_CaptionLbl: Label 'Ending Date';
        Prod__Order_Component__Due_Date_CaptionLbl: Label 'Due Date';
}

