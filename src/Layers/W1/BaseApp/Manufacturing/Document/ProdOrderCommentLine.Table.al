// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

table 5414 "Prod. Order Comment Line"
{
    Caption = 'Prod. Order Comment Line';
    DrillDownPageID = "Prod. Order Comment List";
    LookupPageID = "Prod. Order Comment List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Status; Enum "Production Order Status")
        {
            Caption = 'Status';
        }
        field(2; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            NotBlank = true;
            TableRelation = "Production Order"."No." where(Status = field(Status));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
        }
        field(5; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(6; Comment; Text[80])
        {
            Caption = 'Comment';
        }
    }

    keys
    {
        key(Key1; Status, "Prod. Order No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CheckFinishedOrder();
    end;

    trigger OnInsert()
    begin
        CheckFinishedOrder();
    end;

    trigger OnModify()
    begin
        CheckFinishedOrder();
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'A %1 %2 cannot be inserted, modified, or deleted.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure SetupNewLine()
    var
        ProdOrderCommentLine: Record "Prod. Order Comment Line";
    begin
        ProdOrderCommentLine.SetRange(Status, Status);
        ProdOrderCommentLine.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderCommentLine.SetRange(Date, WorkDate());
        if not ProdOrderCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, ProdOrderCommentLine);
    end;

    local procedure CheckFinishedOrder()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckFinishedOrder(Rec, IsHandled);
        if not IsHandled then
            if Status = Status::Finished then
                Error(Text000, Status, TableCaption);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var ProdOrderCommentLineRec: Record "Prod. Order Comment Line"; var ProdOrderCommentLineFilter: Record "Prod. Order Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckFinishedOrder(ProdOrderCommentLine: Record "Prod. Order Comment Line"; var IsHandled: Boolean)
    begin
    end;
}

