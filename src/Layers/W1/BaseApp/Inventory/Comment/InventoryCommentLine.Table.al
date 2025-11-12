// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Comment;

table 5748 "Inventory Comment Line"
{
    Caption = 'Inventory Comment Line';
    LookupPageID = "Inventory Comment List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Inventory Comment Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
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
        key(Key1; "Document Type", "No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        InvtCommentLine: Record "Inventory Comment Line";
    begin
        InvtCommentLine.SetRange("Document Type", "Document Type");
        InvtCommentLine.SetRange("No.", "No.");
        InvtCommentLine.SetRange(Date, WorkDate());
        if not InvtCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, InvtCommentLine);
    end;

    procedure CopyCommentLines(FromDocumentType: Enum "Inventory Comment Document Type"; FromNumber: Code[20]; ToDocumentType: Enum "Inventory Comment Document Type"; ToNumber: Code[20])
    var
        InvtCommentLine: Record "Inventory Comment Line";
        InvtCommentLine2: Record "Inventory Comment Line";
    begin
        InvtCommentLine.SetRange("Document Type", FromDocumentType);
        InvtCommentLine.SetRange("No.", FromNumber);
        if InvtCommentLine.Find('-') then
            repeat
                InvtCommentLine2 := InvtCommentLine;
                InvtCommentLine2."Document Type" := ToDocumentType;
                InvtCommentLine2."No." := ToNumber;
                InvtCommentLine2.Insert();
            until InvtCommentLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var InventoryCommentLineRec: Record "Inventory Comment Line"; var InventoryCommentLineFilter: Record "Inventory Comment Line")
    begin
    end;
}

