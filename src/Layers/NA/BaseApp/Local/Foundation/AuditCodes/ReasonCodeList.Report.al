// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.AuditCodes;

using Microsoft.Foundation.Company;

report 10312 "Reason Code List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Foundation/AuditCodes/ReasonCodeList.rdlc';
    Caption = 'Reason Code List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Reason Code"; "Reason Code")
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
            column(Reason_Code__TABLECAPTION__________ReasonFilter; "Reason Code".TableCaption + ': ' + ReasonFilter)
            {
            }
            column(ReasonFilter; ReasonFilter)
            {
            }
            column(Reason_Code_Code; Code)
            {
            }
            column(Reason_Code_Description; Description)
            {
            }
            column(Reason_Code_ListCaption; Reason_Code_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Reason_Code_CodeCaption; FieldCaption(Code))
            {
            }
            column(Reason_Code_DescriptionCaption; FieldCaption(Description))
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
        ReasonFilter := "Reason Code".GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        ReasonFilter: Text;
        Reason_Code_ListCaptionLbl: Label 'Reason Code List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
}

