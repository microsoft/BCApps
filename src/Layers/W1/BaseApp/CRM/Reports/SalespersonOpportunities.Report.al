// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Reports;

using Microsoft.CRM.Opportunity;

report 5058 "Salesperson - Opportunities"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CRM/Reports/SalespersonOpportunities.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Salesperson Opportunities';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Opportunity; Opportunity)
        {
            DataItemTableView = sorting("Salesperson Code", Closed);
            RequestFilterFields = "Salesperson Code", "No.", "Campaign No.", "Contact No.", "Creation Date", Closed, "Date Closed";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Opportunity_TABLECAPTION__________OpportunityFilter; TableCaption + ': ' + OpportunityFilter)
            {
            }
            column(OpportunityFilter; OpportunityFilter)
            {
            }
            column(Opportunity__Salesperson_Name_; "Salesperson Name")
            {
            }
            column(Opportunity__Salesperson_Code_; "Salesperson Code")
            {
            }
            column(Opportunity__No__; "No.")
            {
            }
            column(Opportunity__Contact_No__; "Contact No.")
            {
            }
            column(Opportunity__Creation_Date_; Format("Creation Date"))
            {
            }
            column(Opportunity_Status; Status)
            {
            }
            column(Opportunity_Priority; Priority)
            {
            }
            column(Opportunity__Probability___; "Probability %")
            {
            }
            column(Opportunity__Chances_of_Success___; "Chances of Success %")
            {
            }
            column(Opportunity__Completed___; "Completed %")
            {
            }
            column(Opportunity__Campaign_No__; "Campaign No.")
            {
            }
            column(Opportunity__Date_Closed_; Format("Date Closed"))
            {
            }
            column(Opportunity_Description; Description)
            {
            }
            column(FooterPrinted; FooterPrinted)
            {
            }
            column(Salesperson___OpportunityCaption; Salesperson___OpportunityCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Opportunity__No__Caption; FieldCaption("No."))
            {
            }
            column(Opportunity__Contact_No__Caption; FieldCaption("Contact No."))
            {
            }
            column(Opportunity__Creation_Date_Caption; Opportunity__Creation_Date_CaptionLbl)
            {
            }
            column(Opportunity_StatusCaption; FieldCaption(Status))
            {
            }
            column(Opportunity_PriorityCaption; FieldCaption(Priority))
            {
            }
            column(Opportunity__Probability___Caption; FieldCaption("Probability %"))
            {
            }
            column(Opportunity__Chances_of_Success___Caption; FieldCaption("Chances of Success %"))
            {
            }
            column(Opportunity__Completed___Caption; FieldCaption("Completed %"))
            {
            }
            column(Opportunity__Campaign_No__Caption; FieldCaption("Campaign No."))
            {
            }
            column(Opportunity__Date_Closed_Caption; Opportunity__Date_Closed_CaptionLbl)
            {
            }
            column(Opportunity_DescriptionCaption; FieldCaption(Description))
            {
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Salesperson Opportunities';
        AboutText = 'Review which salespeople handle which opportunities.';

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
        FooterPrinted: Boolean;
        OpportunityFilter: Text;
        Salesperson___OpportunityCaptionLbl: Label 'Salesperson - Opportunity';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Opportunity__Creation_Date_CaptionLbl: Label 'Creation Date';
        Opportunity__Date_Closed_CaptionLbl: Label 'Date Closed';
}

