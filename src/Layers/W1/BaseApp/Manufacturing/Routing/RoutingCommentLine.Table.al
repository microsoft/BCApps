// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;

table 99000775 "Routing Comment Line"
{
    Caption = 'Routing Comment Line';
    DrillDownPageID = "Routing Comment List";
    LookupPageID = "Routing Comment List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            NotBlank = true;
            TableRelation = "Routing Header";
        }
        field(2; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            NotBlank = true;
            TableRelation = "Routing Line"."Operation No." where("Routing No." = field("Routing No."),
                                                                  "Version Code" = field("Version Code"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Version Code"; Code[20])
        {
            Caption = 'Version Code';
            TableRelation = "Routing Version"."Version Code" where("Routing No." = field("Routing No."));
        }
        field(10; Date; Date)
        {
            Caption = 'Date';
        }
        field(12; Comment; Text[80])
        {
            Caption = 'Comment';
        }
        field(13; "Code"; Code[10])
        {
            Caption = 'Code';
        }
    }

    keys
    {
        key(Key1; "Routing No.", "Version Code", "Operation No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        RoutingCommentLine: Record "Routing Comment Line";
    begin
        RoutingCommentLine.SetRange("Routing No.", "Routing No.");
        RoutingCommentLine.SetRange("Version Code", "Version Code");
        RoutingCommentLine.SetRange("Operation No.", "Operation No.");
        RoutingCommentLine.SetRange(Date, WorkDate());
        if not RoutingCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, RoutingCommentLine);
    end;

    procedure Caption(): Text
    var
        RtngHeader: Record "Routing Header";
    begin
        if GetFilters = '' then
            exit('');

        if "Routing No." = '' then
            exit('');

        RtngHeader.Get("Routing No.");

        exit(
          StrSubstNo('%1 %2 %3',
            "Routing No.", RtngHeader.Description, "Operation No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var RoutingCommentLineRec: Record "Routing Comment Line"; var RoutingCommentLineFilter: Record "Routing Comment Line")
    begin
    end;
}

