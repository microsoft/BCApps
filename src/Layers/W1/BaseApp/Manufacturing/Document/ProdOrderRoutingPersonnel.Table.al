// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Manufacturing.Routing;

table 5412 "Prod. Order Routing Personnel"
{
    Caption = 'Prod. Order Routing Personnel';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            NotBlank = true;
            TableRelation = "Routing Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(21; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            NotBlank = true;
            TableRelation = "Prod. Order Routing Line"."Operation No." where(Status = field(Status),
                                                                              "Prod. Order No." = field("Prod. Order No."),
                                                                              "Routing No." = field("Routing No."));
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
}

