// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Foundation.Company;

report 10322 "Sales Tax Detail by Area"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/SalesTax/SalesTaxDetailbyArea.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Sales Tax Detail by Area';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Tax Area"; "Tax Area")
        {
            DataItemTableView = sorting(Code);
            RequestFilterFields = "Code";
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
            column(Tax_Area__TABLECAPTION__________AreaFilters; "Tax Area".TableCaption + ': ' + AreaFilters)
            {
            }
            column(Tax_Detail__TABLECAPTION__________DetailFilters; "Tax Detail".TableCaption + ': ' + DetailFilters)
            {
            }
            column(AreaFilters; AreaFilters)
            {
            }
            column(DetailsFilters; DetailFilters)
            {
            }
            column(TaxAreaCodePlusLabel; TableCaption + ' ' + FieldCaption(Code) + ': ' + Code)
            {
            }
            column(Tax_Area_Description; Description)
            {
            }
            column(Tax_Area_Code; Code)
            {
            }
            column(Sales_Tax_Detail_List_by_Sales_Tax_AreaCaption; Sales_Tax_Detail_List_by_Sales_Tax_AreaCaptionLbl)
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
            dataitem("Tax Area Line"; "Tax Area Line")
            {
                DataItemLink = "Tax Area" = field(Code);
                DataItemTableView = sorting("Tax Area", "Tax Jurisdiction Code");
                column(Tax_Area_Line_Tax_Area; "Tax Area")
                {
                }
                column(Tax_Area_Line_Tax_Jurisdiction_Code; "Tax Jurisdiction Code")
                {
                }
                dataitem("Tax Jurisdiction"; "Tax Jurisdiction")
                {
                    DataItemLink = Code = field("Tax Jurisdiction Code");
                    DataItemTableView = sorting(Code);
                    column(TaxJursidictionCodePlusLabel; TableCaption + ' ' + FieldCaption(Code) + ': ' + Code)
                    {
                    }
                    column(Tax_Jurisdiction_Description; Description)
                    {
                    }
                    column(Tax_Jurisdiction_Code; Code)
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
                }
            }
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
        AreaFilters := "Tax Area".GetFilters();
        DetailFilters := "Tax Detail".GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        TaxGroup: Record "Tax Group";
        AreaFilters: Text;
        DetailFilters: Text;
        Sales_Tax_Detail_List_by_Sales_Tax_AreaCaptionLbl: Label 'Sales Tax Detail List by Sales Tax Area';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        TaxGroup_DescriptionCaptionLbl: Label 'Tax Group Description';
        FORMAT__Calculate_Tax_on_Tax__CaptionLbl: Label 'Calculate Tax on Tax';
        FORMAT__Expense_Capitalize__CaptionLbl: Label 'Expense/Capitalize';
}

