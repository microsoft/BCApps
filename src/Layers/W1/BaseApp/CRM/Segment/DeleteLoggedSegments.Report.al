// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Interaction;

report 5191 "Delete Logged Segments"
{
    Caption = 'Delete Logged Segments';
    ProcessingOnly = true;
    Permissions = TableData "Logged Segment" = d;

    dataset
    {
        dataitem("Logged Segment"; "Logged Segment")
        {
            DataItemTableView = sorting("Entry No.") where(Canceled = const(true));
            RequestFilterFields = "Entry No.", "Segment No.";

            trigger OnAfterGetRecord()
            var
                InteractionLogEntry: Record "Interaction Log Entry";
                CampaignEntry: Record "Campaign Entry";
            begin
                InteractionLogEntry.SetCurrentKey("Logged Segment Entry No.");
                InteractionLogEntry.SetRange("Logged Segment Entry No.", "Entry No.");
                InteractionLogEntry.ModifyAll("Logged Segment Entry No.", 0, true);
                CampaignEntry.SetCurrentKey("Register No.");
                CampaignEntry.SetRange("Register No.", "Entry No.");
                CampaignEntry.ModifyAll("Register No.", 0, true);
                NoOfSegments := NoOfSegments + 1;
                Delete(true);
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

    trigger OnPostReport()
    begin
        Message(Text000, NoOfSegments, "Logged Segment".TableCaption());
    end;

    var
        NoOfSegments: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 %2 has been deleted.';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

