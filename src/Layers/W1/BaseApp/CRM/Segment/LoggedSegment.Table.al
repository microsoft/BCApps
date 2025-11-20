// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Interaction;
using System.Security.AccessControl;

table 5075 "Logged Segment"
{
    Caption = 'Logged Segment';
    DataClassification = CustomerContent;
    LookupPageID = "Logged Segments";
    ReplicateData = true;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Segment No."; Code[20])
        {
            Caption = 'Segment No.';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "No. of Interactions"; Integer)
        {
            CalcFormula = count("Interaction Log Entry" where("Logged Segment Entry No." = field("Entry No."),
                                                               Canceled = field(Canceled)));
            Caption = 'No. of Interactions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "No. of Campaign Entries"; Integer)
        {
            CalcFormula = count("Campaign Entry" where("Register No." = field("Entry No."),
                                                        Canceled = field(Canceled)));
            Caption = 'No. of Campaign Entries';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
        }
        field(7; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(8; Canceled; Boolean)
        {
            Caption = 'Canceled';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Segment No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description, "Segment No.", "Creation Date")
        {
        }
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 %2 is marked %3.\Do you wish to remove the checkmark?';
        Text002: Label 'Do you wish to mark %1 %2 as %3?';
        Text005: Label 'Do you wish to remove the checkmark from the selected %1 lines?';
        Text006: Label 'Do you wish to mark the selected %1 lines as %2? ';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure ToggleCanceledCheckmark()
    var
        MasterCanceledCheckmark: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeToggleCanceledCheckmark(Rec, IsHandled);
        if IsHandled then
            exit;

        if Find('-') then
            if ConfirmToggleCanceledCheckmark(Count) then begin
                MasterCanceledCheckmark := not Canceled;
                repeat
                    SetCanceledCheckmark(MasterCanceledCheckmark);
                until Next() = 0
            end;
    end;

    procedure SetCanceledCheckmark(CanceledCheckmark: Boolean)
    var
        InteractLogEntry: Record "Interaction Log Entry";
        CampaignEntry: Record "Campaign Entry";
    begin
        Canceled := CanceledCheckmark;
        Modify();

        CampaignEntry.SetCurrentKey("Register No.");
        CampaignEntry.SetRange("Register No.", "Entry No.");
        CampaignEntry.ModifyAll(Canceled, Canceled);

        InteractLogEntry.SetCurrentKey("Logged Segment Entry No.");
        InteractLogEntry.SetRange("Logged Segment Entry No.", "Entry No.");
        InteractLogEntry.ModifyAll(Canceled, Canceled);
    end;

    local procedure ConfirmToggleCanceledCheckmark(NumberOfSelectedLines: Integer): Boolean
    begin
        if NumberOfSelectedLines = 1 then begin
            if Canceled then
                exit(Confirm(Text000, true, TableCaption(), "Entry No.", FieldCaption(Canceled)));

            exit(Confirm(Text002, true, TableCaption(), "Entry No.", FieldCaption(Canceled)));
        end;

        if Canceled then
            exit(Confirm(Text005, true, TableCaption));

        exit(Confirm(Text006, true, TableCaption(), FieldCaption(Canceled)));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeToggleCanceledCheckmark(var LoggedSegment: Record "Logged Segment"; var IsHandled: Boolean)
    begin
    end;
}

