// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Projects.Resources.Resource;

report 5956 "Service Load Level"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ServiceLoadLevel.rdlc';
    ApplicationArea = Service;
    Caption = 'Service Load Level';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Resource; Resource)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Resource Group No.", "Date Filter", "Unit of Measure Filter", "Chargeable Filter", "Service Zone Filter";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(SelctnFrmtSTRQtyCostPrice; Text001 + ' ' + Format(SelectStr(Selection + 1, Text002)))
            {
            }
            column(ResTblCptnResourceFilter; TableCaption + ': ' + ResourceFilter)
            {
            }
            column(ResourceFilter; ResourceFilter)
            {
            }
            column(Selection; Selection)
            {
            }
            column(Values1; Values[1])
            {
                DecimalPlaces = 0 : 5;
            }
            column(Values2; Values[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(Values3; Values[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(Values4; Values[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(Values5; Values[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(No_Resource; "No.")
            {
                IncludeCaption = true;
            }
            column(Name_Resource; Name)
            {
                IncludeCaption = true;
            }
            column(Values6; Values[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(ServiceLoadLevelCaption; ServiceLoadLevelCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(UnusedCaption; UnusedCaptionLbl)
            {
            }
            column(UnusedCaption1; UnusedCaption1Lbl)
            {
            }
            column(UsageCaption; UsageCaptionLbl)
            {
            }
            column(CapacityCaption; CapacityCaptionLbl)
            {
            }
            column(SalesCaption; SalesCaptionLbl)
            {
            }
            column(SalesCaption1; SalesCaption1Lbl)
            {
            }
            column(QTYCaption; QTYCaptionLbl)
            {
            }
            column(CostCaption; CostCaptionLbl)
            {
            }
            column(PriceCaption; PriceCaptionLbl)
            {
            }
            column(ReporttotalCaption; ReporttotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                case Selection of
                    Selection::Quantity:
                        begin
                            CalcFields(Capacity, "Usage (Qty.)", "Sales (Qty.)");
                            Values[1] := Capacity;
                            Values[2] := "Usage (Qty.)";
                            Values[3] := Capacity - "Usage (Qty.)";
                            Values[5] := "Sales (Qty.)";
                        end;
                    Selection::Cost:
                        begin
                            CalcFields(Capacity, "Usage (Cost)", "Sales (Cost)");
                            Values[1] := Capacity * "Unit Cost";
                            Values[2] := "Usage (Cost)";
                            Values[3] := Values[1] - "Usage (Cost)";
                            Values[5] := "Sales (Cost)";
                        end;
                    Selection::Price:
                        begin
                            CalcFields(Capacity, "Usage (Price)", "Sales (Price)");
                            Values[1] := Capacity * "Unit Price";
                            Values[2] := "Usage (Price)";
                            Values[3] := Values[1] - "Usage (Price)";
                            Values[5] := "Sales (Price)";
                        end;
                end;

                if Values[1] <> 0 then
                    Values[4] := Values[3] / Values[1] * 100
                else
                    Values[4] := 0;

                if Values[2] <> 0 then
                    Values[6] := Values[5] / Values[2] * 100
                else
                    Values[6] := 0;
            end;

            trigger OnPreDataItem()
            begin
                Clear(Values[1]);
                Clear(Values[2]);
                Clear(Values[3]);
                Clear(Values[5]);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Service Load Level';
        AboutText = 'Get an overview of the service load on your resources.';
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Selection; Selection)
                    {
                        ApplicationArea = Service;
                        Caption = 'Selection';
                        OptionCaption = 'Quantity,Cost,Price';
                        ToolTip = 'Specifies whether you want a report for quantity, costs, or prices.';
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
        ResourceFilter := Resource.GetFilters();
    end;

    var
        ResourceFilter: Text;
        Selection: Option Quantity,Cost,Price;
        Values: array[6] of Decimal;
#pragma warning disable AA0074
        Text001: Label 'Selection :';
        Text002: Label 'Quantity,Cost,Price';
#pragma warning restore AA0074
        ServiceLoadLevelCaptionLbl: Label 'Service Load Level';
        CurrReportPageNoCaptionLbl: Label 'Page';
        UnusedCaptionLbl: Label 'Unused';
        UnusedCaption1Lbl: Label 'Unused %';
        UsageCaptionLbl: Label 'Usage';
        CapacityCaptionLbl: Label 'Capacity';
        SalesCaptionLbl: Label 'Sales';
        SalesCaption1Lbl: Label 'Sales %';
        QTYCaptionLbl: Label '(QTY)';
        CostCaptionLbl: Label '(Cost)';
        PriceCaptionLbl: Label '(Price)';
        ReporttotalCaptionLbl: Label 'Report total';

    procedure InitializeRequest(NewSelection: Option)
    begin
        Selection := NewSelection;
    end;
}

