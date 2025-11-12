// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Reports;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Segment;
using Microsoft.Foundation.Address;

report 5063 "Segment - Contacts"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CRM/Reports/SegmentContacts.rdlc';
    Caption = 'Segment - Contacts';
    WordMergeDataItem = "Segment Header";

    dataset
    {
        dataitem("Segment Header"; "Segment Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Campaign No.", "Salesperson Code";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(SegmentHeaderCaption; TableCaption + ': ' + SegmentFilter)
            {
            }
            column(SegmentFilter; SegmentFilter)
            {
            }
            column(ContactCaption; Contact.TableCaption + ': ' + ContFilter)
            {
            }
            column(ContFilter; ContFilter)
            {
            }
            column(No_SegmentHeader; "No.")
            {
            }
            column(Description_SegHeader; Description)
            {
            }
            column(GroupNo; GroupNo)
            {
            }
            column(SegmentContactsCaption; SegmentContactsCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            dataitem("Segment Line"; "Segment Line")
            {
                DataItemLink = "Segment No." = field("No.");
                DataItemTableView = sorting("Contact No.", "Segment No.");
                dataitem(Contact; Contact)
                {
                    DataItemLink = "No." = field("Contact No.");
                    DataItemTableView = sorting("No.");
                    RequestFilterFields = "No.", "Search Name", Type;
                    column(ContAddr7; ContAddr[7])
                    {
                    }
                    column(ContAddr6; ContAddr[6])
                    {
                    }
                    column(ContAddr5; ContAddr[5])
                    {
                    }
                    column(ContAddr4; ContAddr[4])
                    {
                    }
                    column(ContAddr3; ContAddr[3])
                    {
                    }
                    column(ContAddr2; ContAddr[2])
                    {
                    }
                    column(ContAddr1; ContAddr[1])
                    {
                    }
                    column(No_Contact; "No.")
                    {
                        IncludeCaption = true;
                    }
                    column(CurrencyCode_Cont; "Currency Code")
                    {
                        IncludeCaption = true;
                    }
                    column(SalespersonCode_Cont; "Salesperson Code")
                    {
                        IncludeCaption = true;
                    }
                    column(NoofInteractions_Cont; "No. of Interactions")
                    {
                        IncludeCaption = true;
                    }
                    column(CostLCY_Cont; "Cost (LCY)")
                    {
                        IncludeCaption = true;
                    }
                    column(NoofOpportunities_Cont; "No. of Opportunities")
                    {
                        IncludeCaption = true;
                    }
                    column(EstimatedValueLCY_Cont; "Estimated Value (LCY)")
                    {
                        IncludeCaption = true;
                    }
                    column(ContAddr8; ContAddr[8])
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        FormatAddr.ContactAddr(ContAddr, Contact);
                        if Counter = RecPerPageNum then begin
                            GroupNo := GroupNo + 1;
                            Counter := 0;
                        end;
                        Counter := Counter + 1;
                    end;
                }
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Segment - Contacts';
        AboutText = 'Review the distribution of contacts across segments.';
        SaveValues = true;

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
        ContFilter := Contact.GetFilters();
        SegmentFilter := "Segment Header".GetFilters();

        Counter := 0;
        GroupNo := 1;
        RecPerPageNum := 4;
    end;

    var
        FormatAddr: Codeunit "Format Address";
        ContFilter: Text;
        SegmentFilter: Text;
        ContAddr: array[8] of Text[100];
        GroupNo: Integer;
        Counter: Integer;
        RecPerPageNum: Integer;
        SegmentContactsCaptionLbl: Label 'Segment - Contacts';
        CurrReportPageNoCaptionLbl: Label 'Page';
}

