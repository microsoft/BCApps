// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Foundation.Company;

report 10321 "Sales Tax Area List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/SalesTax/SalesTaxAreaList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Sales Tax Areas';
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
            column(AreaFilters; AreaFilters)
            {
            }
            column(TaxAreaCodePlusLabel; TableCaption + ' ' + FieldCaption(Code) + ': ' + Code)
            {
            }
            column(Tax_Area_Description; Description)
            {
            }
            column(Tax_Area_Country; "Country/Region")
            {
            }
            column(Tax_Area__Round_Tax_; "Round Tax")
            {
            }
            column(Tax_Area_Code; Code)
            {
            }
            column(Tax_Area_Description_Control4; Description)
            {
            }
            column(Tax_Area_Country_Control1480000; "Country/Region")
            {
            }
            column(Tax_Area__Round_Tax__Control1480008; "Round Tax")
            {
            }
            column(Sales_Tax_Area_ListCaption; Sales_Tax_Area_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Tax_Area_Line__Tax_Jurisdiction_Code_Caption; "Tax Area Line".FieldCaption("Tax Jurisdiction Code"))
            {
            }
            column(Tax_Area_Line__Jurisdiction_Description_Caption; "Tax Area Line".FieldCaption("Jurisdiction Description"))
            {
            }
            column(Tax_Area_Line__Calculation_Order_Caption; "Tax Area Line".FieldCaption("Calculation Order"))
            {
            }
            column(Tax_Area_CodeCaption; FieldCaption(Code))
            {
            }
            column(Tax_Area_Description_Control4Caption; FieldCaption(Description))
            {
            }
            column(Tax_Area_Country_Control1480000Caption; FieldCaption("Country/Region"))
            {
            }
            column(Tax_Area__Round_Tax__Control1480008Caption; FieldCaption("Round Tax"))
            {
            }
            column(Tax_Area_CountryCaption; FieldCaption("Country/Region"))
            {
            }
            column(Tax_Area__Round_Tax_Caption; FieldCaption("Round Tax"))
            {
            }
            dataitem("Tax Area Line"; "Tax Area Line")
            {
                DataItemLink = "Tax Area" = field(Code);
                DataItemTableView = sorting("Tax Area", "Tax Jurisdiction Code");
                column(Tax_Area_Line__Tax_Jurisdiction_Code_; "Tax Jurisdiction Code")
                {
                }
                column(Tax_Area_Line__Jurisdiction_Description_; "Jurisdiction Description")
                {
                }
                column(Tax_Area_Line__Calculation_Order_; "Calculation Order")
                {
                }
                column(ShowDetails; IncludeJurisdictions)
                {
                }
                column(Tax_Area_Line_Tax_Area; "Tax Area")
                {
                }

                trigger OnPreDataItem()
                begin
                    if not IncludeJurisdictions then
                        CurrReport.Break();
                end;
            }
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
                    field(IncludeJurisdictions; IncludeJurisdictions)
                    {
                        ApplicationArea = SalesTax;
                        Caption = 'Include Jurisdictions';
                        ToolTip = 'Specifies if values for each tax jurisdiction are included in the report.';
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
        AreaFilters := "Tax Area".GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        IncludeJurisdictions: Boolean;
        AreaFilters: Text;
        Sales_Tax_Area_ListCaptionLbl: Label 'Sales Tax Area List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
}

