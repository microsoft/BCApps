// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.CRM.Team;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Costing;
using Microsoft.Sales.Receivables;

report 10059 "Salesperson Commissions"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/SalespersonCommissions.rdlc';
    ApplicationArea = Suite;
    Caption = 'Salesperson Commission';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Salesperson/Purchaser"; "Salesperson/Purchaser")
        {
            DataItemTableView = sorting(Code);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Code", "Date Filter";
            RequestFilterHeading = 'Salesperson';
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(PeriodText; PeriodText)
            {
            }
            column(CodeFilter; CodeFilter)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(Salesperson_Purchaser_Code; Code)
            {
            }
            column(Salesperson_Purchaser_Name; Name)
            {
            }
            column(Salesperson_Purchaser__Commission___; "Commission %")
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(OnlyOnePerPage; OnlyOnePerPage)
            {
            }
            column(Cust__Ledger_Entry___Sales__LCY__; "Cust. Ledger Entry"."Sales (LCY)")
            {
            }
            column(Cust__Ledger_Entry___Profit__LCY__; "Cust. Ledger Entry"."Profit (LCY)")
            {
            }
            column(SalesCommission; SalesCommission)
            {
            }
            column(ProfitCommission; ProfitCommission)
            {
            }
            column(Salesperson_Purchaser_Date_Filter; "Date Filter")
            {
            }
            column(Salesperson_CommissionsCaption; Salesperson_CommissionsCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(For_the_period_Caption; For_the_period_CaptionLbl)
            {
            }
            column(Salesperson_Purchaser_CodeCaption; Salesperson_Purchaser_CodeCaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Document_No__Caption; Cust__Ledger_Entry__Document_No__CaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Posting_Date_Caption; "Cust. Ledger Entry".FieldCaption("Posting Date"))
            {
            }
            column(Cust__Ledger_Entry__Customer_No__Caption; Cust__Ledger_Entry__Customer_No__CaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Sales__LCY__Caption; Cust__Ledger_Entry__Sales__LCY__CaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Profit__LCY__Caption; Cust__Ledger_Entry__Profit__LCY__CaptionLbl)
            {
            }
            column(SalesCommission_Control38Caption; SalesCommission_Control38CaptionLbl)
            {
            }
            column(ProfitCommission_Control39Caption; ProfitCommission_Control39CaptionLbl)
            {
            }
            column(Commission_Rate_Caption; Commission_Rate_CaptionLbl)
            {
            }
            column(EmptyStringCaption; EmptyStringCaptionLbl)
            {
            }
            column(Report_TotalCaption; Report_TotalCaptionLbl)
            {
            }
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                DataItemLink = "Salesperson Code" = field(Code), "Posting Date" = field("Date Filter");
                DataItemTableView = sorting("Salesperson Code", "Posting Date") where("Document Type" = filter(Invoice | "Credit Memo"));
                column(Cust__Ledger_Entry__Posting_Date_; "Posting Date")
                {
                }
                column(Cust__Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Cust__Ledger_Entry__Customer_No__; "Customer No.")
                {
                }
                column(Cust__Ledger_Entry__Sales__LCY__; "Sales (LCY)")
                {
                }
                column(Cust__Ledger_Entry__Profit__LCY__; "Profit (LCY)")
                {
                }
                column(SalesCommission_Control38; SalesCommission)
                {
                }
                column(ProfitCommission_Control39; ProfitCommission)
                {
                }
                column(Salesperson_Purchaser__Code; "Salesperson/Purchaser".Code)
                {
                }
                column(Cust__Ledger_Entry__Sales__LCY___Control41; "Sales (LCY)")
                {
                }
                column(Cust__Ledger_Entry__Profit__LCY___Control42; "Profit (LCY)")
                {
                }
                column(SalesCommission_Control43; SalesCommission)
                {
                }
                column(ProfitCommission_Control44; ProfitCommission)
                {
                }
                column(Cust__Ledger_Entry_Entry_No_; "Entry No.")
                {
                }
                column(Cust__Ledger_Entry_Salesperson_Code; "Salesperson Code")
                {
                }
                column(Salesperson_Total_Caption; Salesperson_Total_CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                var
                    CostCalcMgt: Codeunit "Cost Calculation Management";
                begin
                    SalesCommission := Round("Sales (LCY)" * "Salesperson/Purchaser"."Commission %" / 100);
                    "Profit (LCY)" += CostCalcMgt.CalcCustLedgAdjmtCostLCY("Cust. Ledger Entry");
                    ProfitCommission := Round("Profit (LCY)" * "Salesperson/Purchaser"."Commission %" / 100);
                end;

                trigger OnPreDataItem()
                begin
                    Clear(ProfitCommission);
                    Clear(SalesCommission);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if OnlyOnePerPage then
                    PageGroupNo := PageGroupNo + 1;
            end;

            trigger OnPreDataItem()
            begin
                Clear(ProfitCommission);
                Clear(SalesCommission);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NewPagePerSalesperson; OnlyOnePerPage)
                    {
                        ApplicationArea = Suite;
                        Caption = 'New Page per Salesperson';
                        MultiLine = true;
                        ToolTip = 'Specifies if each salesperson''s statistics begins on a new page.';
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
        CompanyInformation.Get();
        PeriodText := "Salesperson/Purchaser".GetFilter("Date Filter");
        "Salesperson/Purchaser".SetRange("Date Filter");
        FilterString := "Salesperson/Purchaser".GetFilters();

        PageGroupNo := 0;
        CodeFilter := CopyStr("Salesperson/Purchaser".GetFilter(Code), 1, MaxStrLen(CodeFilter));
    end;

    var
        FilterString: Text;
        PeriodText: Text;
        ProfitCommission: Decimal;
        SalesCommission: Decimal;
        OnlyOnePerPage: Boolean;
        CompanyInformation: Record "Company Information";
        PageGroupNo: Integer;
        CodeFilter: Text[30];
        Salesperson_CommissionsCaptionLbl: Label 'Salesperson Commissions';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        For_the_period_CaptionLbl: Label 'For the period:';
        Salesperson_Purchaser_CodeCaptionLbl: Label 'SalesPer';
        Cust__Ledger_Entry__Document_No__CaptionLbl: Label 'Invoice Number';
        Cust__Ledger_Entry__Customer_No__CaptionLbl: Label 'Customer';
        Cust__Ledger_Entry__Sales__LCY__CaptionLbl: Label 'Sales Amount';
        Cust__Ledger_Entry__Profit__LCY__CaptionLbl: Label 'Profit';
        SalesCommission_Control38CaptionLbl: Label 'Sales Commission';
        ProfitCommission_Control39CaptionLbl: Label 'Profit Commission';
        Commission_Rate_CaptionLbl: Label 'Commission Rate:';
        EmptyStringCaptionLbl: Label '%';
        Report_TotalCaptionLbl: Label 'Report Total';
        Salesperson_Total_CaptionLbl: Label 'Salesperson Total:';
}

