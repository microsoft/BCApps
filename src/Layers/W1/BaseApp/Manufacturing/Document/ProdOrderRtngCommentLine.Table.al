// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Manufacturing.Routing;

table 5415 "Prod. Order Rtng Comment Line"
{
    Caption = 'Prod. Order Rtng Comment Line';
    DrillDownPageID = "Prod. Order Rtng. Cmt. List";
    LookupPageID = "Prod. Order Rtng. Cmt. List";
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
            TableRelation = "Prod. Order Routing Line"."Operation No." where(Status = field(Status),
                                                                              "Prod. Order No." = field("Prod. Order No."),
                                                                              "Routing No." = field("Routing No."));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
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
        field(22; Status; Enum "Production Order Status")
        {
            Caption = 'Status';
        }
        field(23; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            NotBlank = true;
            TableRelation = "Production Order"."No." where(Status = field(Status));
        }
        field(24; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
            TableRelation = "Prod. Order Routing Line"."Routing Reference No." where("Routing No." = field("Routing No."),
                                                                                      "Operation No." = field("Operation No."),
                                                                                      "Prod. Order No." = field("Prod. Order No."),
                                                                                      Status = field(Status));
            ValidateTableRelation = false;
        }
    }

    keys
    {
        key(Key1; Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if Status = Status::Finished then
            Error(Text000, Status, TableCaption);
    end;

    trigger OnInsert()
    begin
        if Status = Status::Finished then
            Error(Text000, Status, TableCaption);
    end;

    trigger OnModify()
    begin
        if Status = Status::Finished then
            Error(Text000, Status, TableCaption);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'A %1 %2 cannot be inserted, modified, or deleted.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure SetupNewLine()
    var
        ProdOrderRtngComment: Record "Prod. Order Rtng Comment Line";
    begin
        ProdOrderRtngComment.SetRange(Status, Status);
        ProdOrderRtngComment.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderRtngComment.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderRtngComment.SetRange("Routing No.", "Routing No.");
        ProdOrderRtngComment.SetRange("Operation No.", "Operation No.");
        ProdOrderRtngComment.SetRange(Date, WorkDate());
        if not ProdOrderRtngComment.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, ProdOrderRtngComment);
    end;

    procedure Caption(): Text
    var
        ProdOrder: Record "Production Order";
    begin
        if GetFilters = '' then
            exit('');

        if not ProdOrder.Get(Status, "Prod. Order No.") then
            exit('');

        exit(
          StrSubstNo('%1 %2 %3 %4',
            "Prod. Order No.", ProdOrder.Description, "Routing No.", "Operation No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var ProdOrderRtngCommentLineRec: Record "Prod. Order Rtng Comment Line"; var ProdOrderRtngCommentLineFilter: Record "Prod. Order Rtng Comment Line")
    begin
    end;
}

