// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Foundation.Company;

report 10324 "Sales Tax Group List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/SalesTax/SalesTaxGroupList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Sales Tax Group List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Tax Group"; "Tax Group")
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
            column(Tax_Group__TABLECAPTION__________TaxGroupFilters; "Tax Group".TableCaption + ': ' + TaxGroupFilters)
            {
            }
            column(TaxGroupFilters; TaxGroupFilters)
            {
            }
            column(Tax_Group_Code; Code)
            {
            }
            column(Tax_Group_Description; Description)
            {
            }
            column(Sales_Tax_Group_ListCaption; Sales_Tax_Group_ListCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(Tax_Group_CodeCaption; FieldCaption(Code))
            {
            }
            column(Tax_Group_DescriptionCaption; FieldCaption(Description))
            {
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
        TaxGroupFilters := "Tax Group".GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        TaxGroupFilters: Text;
        Sales_Tax_Group_ListCaptionLbl: Label 'Sales Tax Group List';
        PageCaptionLbl: Label 'Page';
}

