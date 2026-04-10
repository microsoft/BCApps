// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Profiling;
using Microsoft.Inventory.Ledger;

report 5196 "Remove Contacts - Refine"
{
    Caption = 'Remove Contacts - Refine';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Segment Header"; "Segment Header")
        {
            DataItemTableView = sorting("No.");

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
        dataitem(Contact; Contact)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Search Name", Type, "Salesperson Code", "Post Code", "Country/Region Code", "Territory Code";

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
        dataitem("Contact Profile Answer"; "Contact Profile Answer")
        {
            DataItemTableView = sorting("Contact No.", "Profile Questionnaire Code", "Line No.");
            RequestFilterFields = "Profile Questionnaire Code", "Line No.";
            RequestFilterHeading = 'Profile';

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
        dataitem("Contact Mailing Group"; "Contact Mailing Group")
        {
            DataItemTableView = sorting("Contact No.", "Mailing Group Code");
            RequestFilterFields = "Mailing Group Code";

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
        dataitem("Interaction Log Entry"; "Interaction Log Entry")
        {
            DataItemTableView = sorting("Entry No.");
            RequestFilterFields = Date, "Segment No.", "Campaign No.", Evaluation, "Interaction Template Code", "Salesperson Code";

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
        dataitem("Contact Job Responsibility"; "Contact Job Responsibility")
        {
            DataItemTableView = sorting("Contact No.", "Job Responsibility Code");
            RequestFilterFields = "Job Responsibility Code";

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
        dataitem("Contact Industry Group"; "Contact Industry Group")
        {
            DataItemTableView = sorting("Contact No.", "Industry Group Code");
            RequestFilterFields = "Industry Group Code";

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
        dataitem("Contact Business Relation"; "Contact Business Relation")
        {
            DataItemTableView = sorting("Contact No.", "Business Relation Code");
            RequestFilterFields = "Business Relation Code";

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
        dataitem("Value Entry"; "Value Entry")
        {
            DataItemTableView = sorting("Source Type", "Source No.", "Item No.", "Posting Date");
            RequestFilterFields = "Item No.", "Variant Code", "Posting Date", "Inventory Posting Group";

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
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
                    field(EntireCompanies; EntireCompanies)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Entire Companies';
                        ToolTip = 'Specifies if you want to remove all the person contacts employed in the company that you remove from the segment.';
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
        SetSegmentView();
    end;

    protected var
        ReduceRefineSegment: Report "Remove Contacts";
        EntireCompanies: Boolean;

    local procedure SetSegmentView()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSegmentView(ReduceRefineSegment, IsHandled);
        if IsHandled then
            exit;

        Clear(ReduceRefineSegment);
        ReduceRefineSegment.SetTableView("Segment Header");
        ReduceRefineSegment.SetTableView(Contact);
        ReduceRefineSegment.SetTableView("Contact Profile Answer");
        ReduceRefineSegment.SetTableView("Contact Mailing Group");
        ReduceRefineSegment.SetTableView("Interaction Log Entry");
        ReduceRefineSegment.SetTableView("Contact Job Responsibility");
        ReduceRefineSegment.SetTableView("Contact Industry Group");
        ReduceRefineSegment.SetTableView("Contact Business Relation");
        ReduceRefineSegment.SetTableView("Value Entry");
        ReduceRefineSegment.SetOptions(REPORT::"Remove Contacts - Refine", EntireCompanies);
        IsHandled := false;
        OnPreReportOnBeforeRunReduceRefineSegment(IsHandled);
        if not IsHandled then
            ReduceRefineSegment.RunModal();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSegmentView(var RemoveContacts: Report "Remove Contacts"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnBeforeRunReduceRefineSegment(var IsHandled: Boolean)
    begin
    end;
}

