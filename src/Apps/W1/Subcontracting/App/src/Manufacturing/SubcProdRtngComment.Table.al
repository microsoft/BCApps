namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;

table 20574 "Subc. Prod. Rtng. Comment"
{
    Caption = 'Subcontracting Production Order Routing Comment';
    DrillDownPageID = "Subc. Prod. Rtng. Comments";
    LookupPageID = "Subc. Prod. Rtng. Comments";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Status; Enum "Production Order Status")
        {
            Caption = 'Status';
            Editable = false;
            ToolTip = 'Specifies the status of the production order for the subcontracting comment.';
        }
        field(2; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            Editable = false;
            NotBlank = true;
            TableRelation = "Production Order"."No." where(Status = field(Status));
            ToolTip = 'Specifies the production order number for the subcontracting comment.';
        }
        field(4; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
            Editable = false;
            TableRelation = "Prod. Order Routing Line"."Routing Reference No." where(Status = field(Status),
                                                                                      "Prod. Order No." = field("Prod. Order No."),
                                                                                      "Routing No." = field("Routing No."),
                                                                                      "Operation No." = field("Operation No."));
            ValidateTableRelation = false;
            ToolTip = 'Specifies the routing reference number for the subcontracting comment.';
        }
        field(5; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            Editable = false;
            NotBlank = true;
            TableRelation = "Routing Header";
            ToolTip = 'Specifies the routing number for the subcontracting comment.';
        }
        field(6; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            Editable = false;
            NotBlank = true;
            TableRelation = "Prod. Order Routing Line"."Operation No." where(Status = field(Status),
                                                                               "Prod. Order No." = field("Prod. Order No."),
                                                                               "Routing No." = field("Routing No."));
            ToolTip = 'Specifies the operation number for the subcontracting comment.';
        }
        field(7; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
            ToolTip = 'Specifies the line number of the subcontracting comment.';
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the subcontracting comment.';
        }
        field(9; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies the description 2 of the subcontracting comment.';
        }
    }

    keys
    {
        key(PK; Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if Status = Status::Finished then
            Error(ModifyInsertOnFinishedErr, Status, TableCaption);
    end;

    trigger OnDelete()
    begin
        if Status = Status::Finished then
            Error(ModifyInsertOnFinishedErr, Status, TableCaption);
    end;

    trigger OnModify()
    begin
        if Status = Status::Finished then
            Error(ModifyInsertOnFinishedErr, Status, TableCaption);
    end;

    var
        ModifyInsertOnFinishedErr: Label 'A %1 %2 cannot be inserted, modified, or deleted.', Comment = '%1=Production Order Status, %2=TableCaption';
}