// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Setup;

report 5184 "Apply Mailing Group"
{
    Caption = 'Apply Mailing Group';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Contact Mailing Group"; "Contact Mailing Group")
        {
            DataItemTableView = sorting("Mailing Group Code");

            trigger OnAfterGetRecord()
            begin
                Delete();
            end;

            trigger OnPreDataItem()
            begin
                if not DeleteOld then
                    CurrReport.Break();

                SetRange("Mailing Group Code", MailingGroupCode);
            end;
        }
        dataitem("Segment Header"; "Segment Header")
        {
            DataItemTableView = sorting("No.");
            dataitem("Segment Line"; "Segment Line")
            {
                DataItemLink = "Segment No." = field("No.");
                DataItemTableView = sorting("Segment No.", "Line No.");
                dataitem("Mailing Group"; "Mailing Group")
                {
                    DataItemTableView = sorting(Code);
                    RequestFilterFields = "Code";

                    trigger OnAfterGetRecord()
                    begin
                        Clear("Contact Mailing Group");
                        "Contact Mailing Group"."Contact No." := "Segment Line"."Contact No.";
                        "Contact Mailing Group"."Mailing Group Code" := Code;
                        OnBeforeContactMailingGroupInsert("Contact Mailing Group", "Segment Header", "Segment Line");
                        if "Contact Mailing Group".Insert() then;
                    end;
                }
            }
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DeleteOld; DeleteOld)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Delete Old Assignments';
                        ToolTip = 'Specifies if the previous contacts that were assigned to the mailing group are removed.';
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

    trigger OnPostReport()
    begin
        Message(
          Text001,
          "Mailing Group".TableCaption(), MailingGroupCode, "Segment Header"."No.");
    end;

    trigger OnPreReport()
    begin
        MailingGroupCode := "Mailing Group".GetFilter(Code);
        if not "Mailing Group".Get(MailingGroupCode) then
            Error(Text000);
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Specify a Mailing Group Code.';
#pragma warning disable AA0470
        Text001: Label '%1 %2 is now applied to Segment %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        DeleteOld: Boolean;
        MailingGroupCode: Code[10];

    [IntegrationEvent(false, false)]
    local procedure OnBeforeContactMailingGroupInsert(var ContactMailingGroup: Record "Contact Mailing Group"; SegmentHeader: Record "Segment Header"; SegmentLine: Record "Segment Line")
    begin
    end;
}

