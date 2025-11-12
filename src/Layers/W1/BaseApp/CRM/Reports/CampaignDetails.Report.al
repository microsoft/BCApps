// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Reports;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Segment;

report 5060 "Campaign - Details"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CRM/Reports/CampaignDetails.rdlc';
    ApplicationArea = RelationshipMgmt;
    Caption = 'Campaign - Details';
    UsageCategory = ReportsAndAnalysis;
    WordMergeDataItem = Campaign;

    dataset
    {
        dataitem(Campaign; Campaign)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Salesperson Code", "Starting Date", "Ending Date";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CampaignFilterCaption; TableCaption + ': ' + CampaignFilter)
            {
            }
            column(CampaignFilter; CampaignFilter)
            {
            }
            column(SegmentHeaderFilterCaption; "Segment Header".TableCaption + ': ' + SegmentHeaderFilter)
            {
            }
            column(SegmentHeaderFilter; SegmentHeaderFilter)
            {
            }
            column(CampaignEntryFilterCaption; "Campaign Entry".TableCaption + ': ' + CampaignEntryFilter)
            {
            }
            column(CampaignEntryFilter; CampaignEntryFilter)
            {
            }
            column(NoofOpportunities_Campaign; "No. of Opportunities")
            {
                IncludeCaption = true;
            }
            column(DurationMin_Campaign; "Duration (Min.)")
            {
                IncludeCaption = true;
            }
            column(CostLCY_Campaign; "Cost (LCY)")
            {
                IncludeCaption = true;
            }
            column(StatusCode_Campaign; "Status Code")
            {
                IncludeCaption = true;
            }
            column(SalespersonCode_Campaign; "Salesperson Code")
            {
                IncludeCaption = true;
            }
            column(EndingDate_Campaign; Format("Ending Date"))
            {
            }
            column(StartDate_Campaign; Format("Starting Date"))
            {
            }
            column(Description_Campaign; Description)
            {
            }
            column(No_Campaign; "No.")
            {
            }
            column(CalcCurrValueLCY_Campaign; "Calcd. Current Value (LCY)")
            {
                IncludeCaption = true;
            }
            column(EstimatedValue_Campaign; "Estimated Value (LCY)")
            {
                IncludeCaption = true;
            }
            column(CampaignDetailsCaption; CampaignDetailsCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(SegmentHdrDateCaption; SegmentHdrDateCaptionLbl)
            {
            }
            column(TypeCaption; TypeCaptionLbl)
            {
            }
            column(CampaignEndingDateCaption; CampaignEndingDateCaptionLbl)
            {
            }
            column(CampaignStartDateCaption; CampaignStartDateCaptionLbl)
            {
            }
            dataitem("Segment Header"; "Segment Header")
            {
                DataItemLink = "Campaign No." = field("No.");
                DataItemTableView = sorting("Campaign No.");
                column(Date_SegmentHdr; Format(Date))
                {
                }
                column(Desc_SegmentHdr; Description)
                {
                    IncludeCaption = true;
                }
                column(NoofLines_SegmentHdr; "No. of Lines")
                {
                    IncludeCaption = true;
                }
                column(CostLCY_SegmentHdr; "Cost (LCY)")
                {
                    IncludeCaption = true;
                }
                column(DurInMin_SegmentHdr; "Duration (Min.)")
                {
                    IncludeCaption = true;
                }
                column(SalespersonCode_SegmentHdr; "Salesperson Code")
                {
                    IncludeCaption = true;
                }
                column(No_SegmentHdr; "No.")
                {
                    IncludeCaption = true;
                }
                column(CampaignNo_SegmentHdr; "Campaign No.")
                {
                }
                column(SegCaption; SegCaptionLbl)
                {
                }
            }
            dataitem("Campaign Entry"; "Campaign Entry")
            {
                DataItemLink = "Campaign No." = field("No.");
                DataItemTableView = sorting("Campaign No.", Date);
                column(EntryNo_CampaignEntry; "Entry No.")
                {
                }
                column(Canceled_CampaignEntry; Canceled)
                {
                    IncludeCaption = false;
                }
                column(Date_Campaign; Format(Date))
                {
                }
                column(Desc_Campaign; Description)
                {
                }
                column(SalespersonCode_CampaignEntry; "Salesperson Code")
                {
                    IncludeCaption = false;
                }
                column(NoofInteractions_CampaignEntry; "No. of Interactions")
                {
                }
                column(CostLCY_CampaignEntry; "Cost (LCY)")
                {
                }
                column(DurationMin_CampaignEntry; "Duration (Min.)")
                {
                }
                column(FormatCanceled; Format(Canceled))
                {
                }
                column(CampaignNo_CampaignEntry; "Campaign No.")
                {
                }
                column(EntryCaption; EntryCaptionLbl)
                {
                }
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Campaign - Details';
        AboutText = 'Get an overview of the information related to a campaign.';

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
        CanceledCaption = 'Canceled';
    }

    trigger OnPreReport()
    begin
        CampaignFilter := Campaign.GetFilters();
        SegmentHeaderFilter := "Segment Header".GetFilters();
        CampaignEntryFilter := "Campaign Entry".GetFilters();
    end;

    var
        CampaignFilter: Text;
        SegmentHeaderFilter: Text;
        CampaignEntryFilter: Text;
        CampaignDetailsCaptionLbl: Label 'Campaign - Details';
        PageCaptionLbl: Label 'Page';
        SegmentHdrDateCaptionLbl: Label 'Date';
        TypeCaptionLbl: Label 'Type';
        CampaignEndingDateCaptionLbl: Label 'Ending Date';
        CampaignStartDateCaptionLbl: Label 'Starting Date';
        SegCaptionLbl: Label 'Seg.';
        EntryCaptionLbl: Label 'Entry';
}

