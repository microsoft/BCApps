// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Campaign;

using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Team;
using System.Security.AccessControl;

table 5072 "Campaign Entry"
{
    Caption = 'Campaign Entry';
    DataCaptionFields = "Campaign No.";
    DataClassification = CustomerContent;
    DrillDownPageID = "Campaign Entries";
    LookupPageID = "Campaign Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
        }
        field(5; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(6; "Segment No."; Code[20])
        {
            Caption = 'Segment No.';
            TableRelation = "Segment Header";
        }
        field(7; Canceled; Boolean)
        {
            BlankZero = true;
            Caption = 'Canceled';
        }
        field(8; "No. of Interactions"; Integer)
        {
            CalcFormula = count("Interaction Log Entry" where("Campaign No." = field("Campaign No."),
                                                               "Campaign Entry No." = field("Entry No."),
                                                               Canceled = field(Canceled)));
            Caption = 'No. of Interactions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Cost (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Interaction Log Entry"."Cost (LCY)" where("Campaign No." = field("Campaign No."),
                                                                          "Campaign Entry No." = field("Entry No."),
                                                                          Canceled = field(Canceled)));
            Caption = 'Cost (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "Duration (Min.)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Interaction Log Entry"."Duration (Min.)" where("Campaign No." = field("Campaign No."),
                                                                               "Campaign Entry No." = field("Entry No."),
                                                                               Canceled = field(Canceled)));
            Caption = 'Duration (Min.)';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(13; "Register No."; Integer)
        {
            Caption = 'Register No.';
            TableRelation = "Logged Segment";
        }
        field(14; "Document Type"; Enum "Interaction Log Entry Document Type")
        {
            Caption = 'Document Type';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Campaign No.", Date, "Document Type")
        {
        }
        key(Key3; "Register No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Campaign No.", Description, Date, "Document Type")
        {
        }
    }

    trigger OnDelete()
    var
        InteractLogEntry: Record "Interaction Log Entry";
    begin
        InteractLogEntry.SetCurrentKey("Campaign No.", "Campaign Entry No.");
        InteractLogEntry.SetRange("Campaign No.", "Campaign No.");
        InteractLogEntry.SetRange("Campaign Entry No.", "Entry No.");
        InteractLogEntry.DeleteAll();
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 %2 is marked %3.\Do you wish to remove the checkmark?';
        Text002: Label 'Do you wish to mark %1 %2 as %3?';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure CopyFromSegment(SegLine: Record "Segment Line")
    begin
        "Campaign No." := SegLine."Campaign No.";
        Date := SegLine.Date;
        "Segment No." := SegLine."Segment No.";
        "Salesperson Code" := SegLine."Salesperson Code";
        "User ID" := UserId();
        "Document Type" := SegLine."Document Type";
    end;

    procedure ToggleCanceledCheckmark()
    var
        MasterCanceledCheckmark: Boolean;
    begin
        if ConfirmToggleCanceledCheckmark() then begin
            MasterCanceledCheckmark := not Canceled;
            SetCanceledCheckmark(MasterCanceledCheckmark);
        end;
    end;

    procedure SetCanceledCheckmark(CanceledCheckmark: Boolean)
    var
        InteractLogEntry: Record "Interaction Log Entry";
    begin
        Canceled := CanceledCheckmark;
        Modify();

        InteractLogEntry.SetCurrentKey("Campaign No.", "Campaign Entry No.");
        InteractLogEntry.SetRange("Campaign No.", "Campaign No.");
        InteractLogEntry.SetRange("Campaign Entry No.", "Entry No.");
        InteractLogEntry.ModifyAll(Canceled, Canceled);
    end;

    local procedure ConfirmToggleCanceledCheckmark(): Boolean
    begin
        if Canceled then
            exit(Confirm(Text000, true, TableCaption(), "Entry No.", FieldCaption(Canceled)));

        exit(Confirm(Text002, true, TableCaption(), "Entry No.", FieldCaption(Canceled)));
    end;
}
