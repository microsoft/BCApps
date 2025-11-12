// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

report 5621 "Insurance - List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssets/Insurance/InsuranceList.rdlc';
    ApplicationArea = FixedAssets;
    Caption = 'Fixed Asset Insurance List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Insurance; Insurance)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Insurance_TABLECAPTION___________InsuranceFilter; TableCaption + ': ' + InsuranceFilter)
            {
            }
            column(InsuranceFilter; InsuranceFilter)
            {
            }
            column(Insurance__No__; "No.")
            {
            }
            column(Insurance_Description; Description)
            {
            }
            column(Insurance__Effective_Date_; Format("Effective Date"))
            {
            }
            column(Insurance__Policy_No__; "Policy No.")
            {
            }
            column(Insurance__Annual_Premium_; "Annual Premium")
            {
            }
            column(Insurance__Policy_Coverage_; "Policy Coverage")
            {
            }
            column(Insurance__Insurance_Type_; "Insurance Type")
            {
            }
            column(Insurance__Insurance_Vendor_No__; "Insurance Vendor No.")
            {
            }
            column(Insurance___ListCaption; Insurance___ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Insurance__No__Caption; FieldCaption("No."))
            {
            }
            column(Insurance_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Insurance__Effective_Date_Caption; Insurance__Effective_Date_CaptionLbl)
            {
            }
            column(Insurance__Policy_No__Caption; FieldCaption("Policy No."))
            {
            }
            column(Insurance__Annual_Premium_Caption; FieldCaption("Annual Premium"))
            {
            }
            column(Insurance__Policy_Coverage_Caption; FieldCaption("Policy Coverage"))
            {
            }
            column(Insurance__Insurance_Type_Caption; FieldCaption("Insurance Type"))
            {
            }
            column(Insurance__Insurance_Vendor_No__Caption; FieldCaption("Insurance Vendor No."))
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
        InsuranceFilter := Insurance.GetFilters();
    end;

    var
        InsuranceFilter: Text;
        Insurance___ListCaptionLbl: Label 'Insurance - List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Insurance__Effective_Date_CaptionLbl: Label 'Effective Date';
}

