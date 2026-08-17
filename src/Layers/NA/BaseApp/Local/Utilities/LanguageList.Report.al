// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Foundation.Company;
using System.Globalization;

report 10310 "Language List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Utilities/LanguageList.rdlc';
    Caption = 'Language List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(LanguageDataItem; Language)
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
            column(Language_TABLECAPTION__________LanguageFilter; LanguageDataItem.TableCaption + ': ' + LanguageFilter)
            {
            }
            column(LanguageFilter; LanguageFilter)
            {
            }
            column(Language_Code; Code)
            {
            }
            column(Language_Name; Name)
            {
            }
            column(Language__Windows_Language_ID_; "Windows Language ID")
            {
            }
            column(Language__Windows_Language_Name_; "Windows Language Name")
            {
            }
            column(Language_ListCaption; Language_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Language_CodeCaption; FieldCaption(Code))
            {
            }
            column(Language_NameCaption; FieldCaption(Name))
            {
            }
            column(Language__Windows_Language_ID_Caption; FieldCaption("Windows Language ID"))
            {
            }
            column(Language__Windows_Language_Name_Caption; FieldCaption("Windows Language Name"))
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields("Windows Language Name");
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
        LanguageFilter := LanguageDataItem.GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        LanguageFilter: Text;
        Language_ListCaptionLbl: Label 'Language List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
}

