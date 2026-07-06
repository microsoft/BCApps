// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Reports;

using Microsoft.CRM.Opportunity;

report 5061 "Opportunity - List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CRM/Reports/OpportunityList.rdlc';
    AdditionalSearchTerms = 'prospects';
    ApplicationArea = RelationshipMgmt;
    Caption = 'Opportunity - List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Opportunity; Opportunity)
        {
            //The property 'DataItemTableView' shouldn't have an empty value.
            //DataItemTableView = '';
            RequestFilterFields = "No.", "Salesperson Code", "Campaign No.", "Contact No.", "Sales Cycle Code", "Creation Date", Closed;
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(Opportunity_TABLECAPTION__________OpportunityFilter; TableCaption + ': ' + OpportunityFilter)
            {
            }
            column(OpportunityFilter; OpportunityFilter)
            {
            }
            column(Opportunity__No__; "No.")
            {
            }
            column(Opportunity_Description; Description)
            {
            }
            column(Opportunity__Sales_Cycle_Code_; "Sales Cycle Code")
            {
            }
            column(Opportunity__Current_Sales_Cycle_Stage_; "Current Sales Cycle Stage")
            {
            }
            column(Opportunity__Salesperson_Code_; "Salesperson Code")
            {
            }
            column(Opportunity__Campaign_No__; "Campaign No.")
            {
            }
            column(Opportunity__Contact_No__; "Contact No.")
            {
            }
            column(Opportunity__Probability___; "Probability %")
            {
            }
            column(Opportunity__Completed___; "Completed %")
            {
            }
            column(Opportunity_Status; Status)
            {
            }
            column(Opportunity___ListCaption; Opportunity___ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Opportunity__No__Caption; FieldCaption("No."))
            {
            }
            column(Opportunity_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Opportunity__Sales_Cycle_Code_Caption; FieldCaption("Sales Cycle Code"))
            {
            }
            column(Opportunity__Current_Sales_Cycle_Stage_Caption; FieldCaption("Current Sales Cycle Stage"))
            {
            }
            column(Opportunity__Salesperson_Code_Caption; FieldCaption("Salesperson Code"))
            {
            }
            column(Opportunity__Campaign_No__Caption; FieldCaption("Campaign No."))
            {
            }
            column(Opportunity__Contact_No__Caption; FieldCaption("Contact No."))
            {
            }
            column(Opportunity__Probability___Caption; FieldCaption("Probability %"))
            {
            }
            column(Opportunity__Completed___Caption; FieldCaption("Completed %"))
            {
            }
            column(Opportunity_StatusCaption; FieldCaption(Status))
            {
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Opportunity - List';
        AboutText = 'Get a list of all your opportunities, including information about the sales cycle of the opportunity and related contacts and campaigns.';

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
        OpportunityFilter := Opportunity.GetFilters();
    end;

    var
        OpportunityFilter: Text;
        Opportunity___ListCaptionLbl: Label 'Opportunity - List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
}

