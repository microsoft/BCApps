// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Manufacturing.Document;
using System.Utilities;

report 99000761 "Prod. Order - Routing List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Manufacturing/Reports/ProdOrderRoutingList.rdlc';
    ApplicationArea = Manufacturing;
    Caption = 'Prod. Order - Routing List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Production Order"; "Production Order")
        {
            DataItemTableView = sorting(Status, "No.");
            RequestFilterFields = Status, "No.", "Source Type", "Source No.";
            column(Production_Order_Status; Status)
            {
            }
            column(Production_Order_No_; "No.")
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(Production_Order__TABLECAPTION__________ProdOrderFilter; "Production Order".TableCaption + ': ' + ProdOrderFilter)
                {
                }
                column(ProdOrderFilter; ProdOrderFilter)
                {
                }
                column(Production_Order___Source_No__; "Production Order"."Source No.")
                {
                }
                column(Production_Order__Description; "Production Order".Description)
                {
                }
                column(Production_Order___No__; "Production Order"."No.")
                {
                }
                column(Production_Order__Status; "Production Order".Status)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Prod__Order___Routing_ListCaption; Prod__Order___Routing_ListCaptionLbl)
                {
                }
                column(Production_Order___Source_No__Caption; "Production Order".FieldCaption("Source No."))
                {
                }
                column(Production_Order__DescriptionCaption; "Production Order".FieldCaption(Description))
                {
                }
                column(Production_Order___No__Caption; "Production Order".FieldCaption("No."))
                {
                }
                column(Production_Order__StatusCaption; "Production Order".FieldCaption(Status))
                {
                }
                column(Prod__Order_Routing_Line__Operation_No__Caption; "Prod. Order Routing Line".FieldCaption("Operation No."))
                {
                }
                column(Prod__Order_Routing_Line__Next_Operation_No__Caption; "Prod. Order Routing Line".FieldCaption("Next Operation No."))
                {
                }
                column(Prod__Order_Routing_Line__Previous_Operation_No__Caption; "Prod. Order Routing Line".FieldCaption("Previous Operation No."))
                {
                }
                column(Prod__Order_Routing_Line_TypeCaption; "Prod. Order Routing Line".FieldCaption(Type))
                {
                }
                column(Prod__Order_Routing_Line__No__Caption; "Prod. Order Routing Line".FieldCaption("No."))
                {
                }
                column(Prod__Order_Routing_Line_DescriptionCaption; "Prod. Order Routing Line".FieldCaption(Description))
                {
                }
                column(InputCaption; InputCaptionLbl)
                {
                }
                column(ScrapCaption; ScrapCaptionLbl)
                {
                }
                column(OutputCaption; OutputCaptionLbl)
                {
                }
            }
            dataitem("Prod. Order Routing Line"; "Prod. Order Routing Line")
            {
                DataItemLink = Status = field(Status), "Prod. Order No." = field("No.");
                DataItemTableView = sorting(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
                column(Prod__Order_Routing_Line__Operation_No__; "Operation No.")
                {
                }
                column(Prod__Order_Routing_Line__Next_Operation_No__; "Next Operation No.")
                {
                }
                column(Prod__Order_Routing_Line__Previous_Operation_No__; "Previous Operation No.")
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
                column(EmptyStringCaption; EmptyStringCaptionLbl)
                {
                }
                column(EmptyStringCaption_Control29; EmptyStringCaption_Control29Lbl)
                {
                }
                column(EmptyStringCaption_Control28; EmptyStringCaption_Control28Lbl)
                {
                }
            }

            trigger OnPreDataItem()
            begin
                ProdOrderFilter := GetFilters();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Prod. Order - Routing List';
        AboutText = 'This report gives an overview of the routing steps for a production order, helping you track each operation to ensure efficiency and accuracy.';

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
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Prod__Order___Routing_ListCaptionLbl: Label 'Prod. Order - Routing List';
        InputCaptionLbl: Label 'Input';
        ScrapCaptionLbl: Label 'Scrap';
        OutputCaptionLbl: Label 'Output';
        EmptyStringCaptionLbl: Label '_____________';
        EmptyStringCaption_Control29Lbl: Label '_____________';
        EmptyStringCaption_Control28Lbl: Label '_____________';
}

