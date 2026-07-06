// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Foundation.Company;

report 10323 "Sales Tax Detail List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/SalesTax/SalesTaxDetailList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Sales Tax Detail List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Tax Jurisdiction"; "Tax Jurisdiction")
        {
            RequestFilterFields = "Code", "Report-to Jurisdiction", "Tax Account (Sales)", "Tax Account (Purchases)";
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
            column(Tax_Jurisdiction__TABLECAPTION__________JurisFilters; "Tax Jurisdiction".TableCaption + ': ' + JurisFilters)
            {
            }
            column(Tax_Detail__TABLECAPTION__________DetailFilters; "Tax Detail".TableCaption + ': ' + DetailFilters)
            {
            }
            column(JurisdictionFilters; JurisFilters)
            {
            }
            column(DetailFilters; DetailFilters)
            {
            }
            column(ReportToJurisdictionPlusLabel; FieldCaption("Report-to Jurisdiction") + ': ' + "Report-to Jurisdiction")
            {
            }
            column(ReportTo_Description; ReportTo.Description)
            {
            }
            column(TaxJurisdictionCodePlusLabel; TableCaption + ' ' + FieldCaption(Code) + ': ' + Code)
            {
            }
            column(Tax_Jurisdiction_Description; Description)
            {
            }
            column(Tax_Jurisdiction_Code; Code)
            {
            }
            column(Tax_Jurisdiction_Report_to_Jurisdiction; "Report-to Jurisdiction")
            {
            }
            column(Sales_Tax_Detail_ListCaption; Sales_Tax_Detail_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Tax_Detail__Tax_Group_Code_Caption; "Tax Detail".FieldCaption("Tax Group Code"))
            {
            }
            column(TaxGroup_DescriptionCaption; TaxGroup_DescriptionCaptionLbl)
            {
            }
            column(Tax_Detail__Tax_Type_Caption; "Tax Detail".FieldCaption("Tax Type"))
            {
            }
            column(Tax_Detail__Effective_Date_Caption; "Tax Detail".FieldCaption("Effective Date"))
            {
            }
            column(Tax_Detail__Tax_Below_Maximum_Caption; "Tax Detail".FieldCaption("Tax Below Maximum"))
            {
            }
            column(Tax_Detail__Maximum_Amount_Qty__Caption; "Tax Detail".FieldCaption("Maximum Amount/Qty."))
            {
            }
            column(Tax_Detail__Tax_Above_Maximum_Caption; "Tax Detail".FieldCaption("Tax Above Maximum"))
            {
            }
            column(FORMAT__Calculate_Tax_on_Tax__Caption; FORMAT__Calculate_Tax_on_Tax__CaptionLbl)
            {
            }
            column(FORMAT__Expense_Capitalize__Caption; FORMAT__Expense_Capitalize__CaptionLbl)
            {
            }
            dataitem("Tax Detail"; "Tax Detail")
            {
                DataItemLink = "Tax Jurisdiction Code" = field(Code);
                DataItemTableView = sorting("Tax Jurisdiction Code", "Tax Group Code", "Tax Type", "Effective Date");
                RequestFilterFields = "Tax Group Code", "Tax Type", "Effective Date";
                column(Tax_Detail__Tax_Group_Code_; "Tax Group Code")
                {
                }
                column(TaxGroup_Description; TaxGroup.Description)
                {
                }
                column(Tax_Detail__Tax_Type_; "Tax Type")
                {
                }
                column(Tax_Detail__Effective_Date_; "Effective Date")
                {
                }
                column(Tax_Detail__Tax_Below_Maximum_; "Tax Below Maximum")
                {
                }
                column(Tax_Detail__Maximum_Amount_Qty__; "Maximum Amount/Qty.")
                {
                }
                column(Tax_Detail__Tax_Above_Maximum_; "Tax Above Maximum")
                {
                }
                column(FORMAT__Calculate_Tax_on_Tax__; Format("Calculate Tax on Tax"))
                {
                }
                column(FORMAT__Expense_Capitalize__; Format("Expense/Capitalize"))
                {
                }
                column(Tax_Detail_Tax_Jurisdiction_Code; "Tax Jurisdiction Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not TaxGroup.Get("Tax Group Code") then
                        TaxGroup.Init();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if ReportTo."Report-to Jurisdiction" <> "Report-to Jurisdiction" then
                    if not ReportTo.Get("Report-to Jurisdiction") then
                        ReportTo.Init();
            end;

            trigger OnPreDataItem()
            begin
                SetCurrentKey("Report-to Jurisdiction");
            end;
        }
    }

    requestpage
    {

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

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        JurisFilters := "Tax Jurisdiction".GetFilters();
        DetailFilters := "Tax Detail".GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        ReportTo: Record "Tax Jurisdiction";
        TaxGroup: Record "Tax Group";
        JurisFilters: Text;
        DetailFilters: Text;
        Sales_Tax_Detail_ListCaptionLbl: Label 'Sales Tax Detail List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        TaxGroup_DescriptionCaptionLbl: Label 'Tax Group Description';
        FORMAT__Calculate_Tax_on_Tax__CaptionLbl: Label 'Calculate Tax on Tax';
        FORMAT__Expense_Capitalize__CaptionLbl: Label 'Expense/Capitalize';
}

