// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Utilities;

report 111 "Customer - Top 10 List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/Reports/CustomerTop10List.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer - Top 10 List';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Customer Posting Group", "Currency Code", "Date Filter";

            trigger OnAfterGetRecord()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeCustomerOnAfterGetRecord(Window, Customer, TempCustomerAmount, ShowType, NoOfRecordsToPrint, TotalSales, TotalBalance, ChartTypeNo, ShowTypeNo, IsHandled);
                if IsHandled then
                    CurrReport.Skip();

                Window.Update(1, "No.");
                CalcFields("Sales (LCY)", "Balance (LCY)");
                if ("Sales (LCY)" = 0) and ("Balance (LCY)" = 0) then
                    CurrReport.Skip();
                TempCustomerAmount.Init();
                TempCustomerAmount."Customer No." := "No.";
                if ShowType = ShowType::"Sales (LCY)" then begin
                    TempCustomerAmount."Amount (LCY)" := -"Sales (LCY)";
                    TempCustomerAmount."Amount 2 (LCY)" := -"Balance (LCY)";
                end else begin
                    TempCustomerAmount."Amount (LCY)" := -"Balance (LCY)";
                    TempCustomerAmount."Amount 2 (LCY)" := -"Sales (LCY)";
                end;
                TempCustomerAmount.Insert();
                if (NoOfRecordsToPrint = 0) or (i < NoOfRecordsToPrint) then
                    i := i + 1
                else begin
                    TempCustomerAmount.Find('+');
                    TempCustomerAmount.Delete();
                end;

                TotalSales += "Sales (LCY)";
                TotalBalance += "Balance (LCY)";
                ChartTypeNo := ChartType;
                ShowTypeNo := ShowType;
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(Text000);
                i := 0;
                TempCustomerAmount.DeleteAll();
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(SortingCustomersCustDateFilter; StrSubstNo(Text001, CustDateFilter))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(RankedAccordingShowType; StrSubstNo(Text002, SelectStr(ShowType + 1, Text004)))
            {
            }
            column(ShowTypeNo; ShowTypeNo)
            {
            }
            column(ChartTypeNo; ChartTypeNo)
            {
            }
            column(CustFilter_Customer; Customer.TableCaption + ': ' + CustFilter)
            {
            }
            column(CustFilter; CustFilter)
            {
            }
            column(No_Customer; Customer."No.")
            {
                IncludeCaption = true;
            }
            column(Name_Customer; Customer.Name)
            {
                IncludeCaption = true;
            }
            column(SalesLCY_Customer; Customer."Sales (LCY)")
            {
                IncludeCaption = true;
            }
            column(BalanceLCY_Customer; Customer."Balance (LCY)")
            {
                IncludeCaption = true;
            }
            column(TotalSales; TotalSales)
            {
            }
            column(TotalBalance; TotalBalance)
            {
            }
            column(CustomerTop10ListCaption; CustomerTop10ListCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(TotalSalesCaption; TotalSalesCaptionLbl)
            {
            }
            column(PercentofTotalSalesCaption; PercentofTotalSalesCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if not TempCustomerAmount.Find('-') then
                        CurrReport.Break();
                end else
                    if TempCustomerAmount.Next() = 0 then
                        CurrReport.Break();
                TempCustomerAmount."Amount (LCY)" := -TempCustomerAmount."Amount (LCY)";
                Customer.Get(TempCustomerAmount."Customer No.");
                Customer.CalcFields("Sales (LCY)", "Balance (LCY)");
                if MaxAmount = 0 then
                    MaxAmount := TempCustomerAmount."Amount (LCY)";
                TempCustomerAmount."Amount (LCY)" := -TempCustomerAmount."Amount (LCY)";

                OnAfterIntegerOnAfterGetRecord(TempCustomerAmount);
            end;

            trigger OnPreDataItem()
            begin
                Window.Close();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Customer - Top 10 List';
        AboutText = 'Review a summary of customers with the most transactions within a selected period to identify sales trends, upcoming collectable debts, and major revenue sources in the company.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Show; ShowType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show';
                        OptionCaption = 'Sales (LCY),Balance (LCY)';
                        ToolTip = 'Specifies how the report will sort the customers: Sales, to sort by purchase volume; or Balance, to sort by balance. In either case, the customers with the largest amounts will be shown first.';
                    }
                    field(NoOfRecordsToPrint; NoOfRecordsToPrint)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Number of Customers';
                        ToolTip = 'Specifies the number of customers that will be included in the report.';

                        trigger OnValidate()
                        begin
                            if NoOfRecordsToPrint <= 0 then
                                Error(NoOfRecordsToPrintErrMsg);
                        end;
                    }
                    field(ChartType; ChartType)
                    {
                        ApplicationArea = All;
                        Caption = 'Chart Type';
                        OptionCaption = 'Bar chart,Pie chart';
                        ToolTip = 'Specifies the chart type.';
                        Visible = ChartTypeVisible;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            ChartTypeVisible := true;
        end;

        trigger OnOpenPage()
        begin
            if NoOfRecordsToPrint = 0 then
                NoOfRecordsToPrint := 10;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        FormatDocument: Codeunit "Format Document";
    begin
        CustFilter := FormatDocument.GetRecordFiltersWithCaptions(Customer);
        CustDateFilter := Customer.GetFilter("Date Filter");
    end;

    var
        TempCustomerAmount: Record "Customer Amount" temporary;
        Window: Dialog;
        CustFilter: Text;
        CustDateFilter: Text;
        ShowType: Option "Sales (LCY)","Balance (LCY)";
        NoOfRecordsToPrint: Integer;
        MaxAmount: Decimal;
        i: Integer;
        TotalSales: Decimal;
        TotalBalance: Decimal;
        ChartType: Option "Bar chart","Pie chart";
        ChartTypeNo: Integer;
        ShowTypeNo: Integer;
        ChartTypeVisible: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Sorting customers    #1##########';
        Text001: Label 'Period: %1';
        Text002: Label 'Ranked according to %1';
#pragma warning restore AA0470
        Text004: Label 'Sales (LCY),Balance (LCY)';
#pragma warning restore AA0074
        CustomerTop10ListCaptionLbl: Label 'Customer - Top 10 List';
        CurrReportPageNoCaptionLbl: Label 'Page';
        TotalCaptionLbl: Label 'Total';
        TotalSalesCaptionLbl: Label 'Total Sales';
        PercentofTotalSalesCaptionLbl: Label '% of Total Sales';
        NoOfRecordsToPrintErrMsg: Label 'The value must be a positive number.';

    procedure InitializeRequest(SetChartType: Option; SetShowType: Option; NoOfRecords: Integer)
    begin
        ChartType := SetChartType;
        ShowType := SetShowType;
        NoOfRecordsToPrint := NoOfRecords;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustomerOnAfterGetRecord(var Window: Dialog; var Customer: Record Customer; var TempCustomerAmount: Record "Customer Amount" temporary; var ShowType: Option; var NoOfRecordsToPrint: Integer; var TotalSales: Decimal; var TotalBalance: Decimal; var ChartTypeNo: Integer; var ShowTypeNo: Integer; var SkipDataItem: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIntegerOnAfterGetRecord(var TempCustomerAmount: Record "Customer Amount" temporary)
    begin
    end;
}

