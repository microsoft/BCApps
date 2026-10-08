// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Foundation.Company;

report 10325 "Sales Tax Jurisdiction List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/SalesTax/SalesTaxJurisdictionList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Sales Tax Jurisdiction List';
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
            column(JurisFilters; JurisFilters)
            {
            }
            column(GroupData; GroupData)
            {
            }
            column(FIELDCAPTION__Report_to_Jurisdiction_____________Report_to_Jurisdiction_; FieldCaption("Report-to Jurisdiction") + ': ' + "Report-to Jurisdiction")
            {
            }
            column(ReportTo_Description; ReportTo.Description)
            {
            }
            column(Tax_Jurisdiction_Code; Code)
            {
            }
            column(Tax_Jurisdiction_Description; Description)
            {
            }
            column(Tax_Jurisdiction__Report_to_Jurisdiction_; "Report-to Jurisdiction")
            {
            }
            column(Tax_Jurisdiction__Tax_Account__Sales__; "Tax Account (Sales)")
            {
            }
            column(Tax_Jurisdiction__Tax_Account__Purchases__; "Tax Account (Purchases)")
            {
            }
            column(Tax_Jurisdiction__Code; "Tax Jurisdiction".Code)
            {
            }
            column(Sales_Tax_Jurisdiction_ListCaption; Sales_Tax_Jurisdiction_ListCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(Tax_Jurisdiction_CodeCaption; FieldCaption(Code))
            {
            }
            column(Tax_Jurisdiction_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Tax_Jurisdiction__Report_to_Jurisdiction_Caption; FieldCaption("Report-to Jurisdiction"))
            {
            }
            column(Tax_Jurisdiction__Tax_Account__Sales__Caption; FieldCaption("Tax Account (Sales)"))
            {
            }
            column(Tax_Jurisdiction__Tax_Account__Purchases__Caption; FieldCaption("Tax Account (Purchases)"))
            {
            }

            trigger OnAfterGetRecord()
            begin
                if "Report-to Jurisdiction" <> ReportTo.Code then
                    if not ReportTo.Get("Report-to Jurisdiction") then
                        ReportTo.Init();
            end;

            trigger OnPreDataItem()
            begin
                if StrPos(CurrentKey, FieldCaption("Report-to Jurisdiction")) = 1 then
                    GroupData := true
                else
                    GroupData := false;
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
    end;

    var
        CompanyInformation: Record "Company Information";
        ReportTo: Record "Tax Jurisdiction";
        JurisFilters: Text;
        GroupData: Boolean;
        Sales_Tax_Jurisdiction_ListCaptionLbl: Label 'Sales Tax Jurisdiction List';
        PageCaptionLbl: Label 'Page';
}

