// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Comment;

using Microsoft.Purchases.Document;

table 43 "Purch. Comment Line"
{
    Caption = 'Purch. Comment Line';
    DrillDownPageID = "Purch. Comment List";
    LookupPageID = "Purch. Comment List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Purchase Comment Document Type")
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
        field(7; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
    }

    keys
    {
        key(Key1; "Document Type", "No.", "Document Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        PurchCommentLine.SetRange("Document Type", "Document Type");
        PurchCommentLine.SetRange("No.", "No.");
        PurchCommentLine.SetRange("Document Line No.", "Document Line No.");
        PurchCommentLine.SetRange(Date, WorkDate());
        OnSetUpNewLineOnAfterSetFilter(Rec, PurchCommentLine);
        if not PurchCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, PurchCommentLine);
    end;

    procedure CopyComments(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    var
        PurchCommentLine: Record "Purch. Comment Line";
        PurchCommentLine2: Record "Purch. Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyComments(PurchCommentLine, ToDocumentType, IsHandled, FromDocumentType, FromNumber, ToNumber);
        if IsHandled then
            exit;

        PurchCommentLine.SetRange("Document Type", FromDocumentType);
        PurchCommentLine.SetRange("No.", FromNumber);
        if PurchCommentLine.FindSet() then
            repeat
                PurchCommentLine2 := PurchCommentLine;
                PurchCommentLine2."Document Type" := Enum::"Purchase Comment Document Type".FromInteger(ToDocumentType);
                PurchCommentLine2."No." := ToNumber;
                OnBeforeCopyCommentsOnBeforeInsert(PurchCommentLine2, PurchCommentLine);
                PurchCommentLine2.Insert();
            until PurchCommentLine.Next() = 0;
    end;

    procedure CopyLineComments(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20]; FromDocumentLineNo: Integer; ToDocumentLineNo: Integer)
    var
        PurchCommentLineSource: Record "Purch. Comment Line";
        PurchCommentLineTarget: Record "Purch. Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyLineComments(
          PurchCommentLineTarget, IsHandled, FromDocumentType, ToDocumentType, FromNumber, ToNumber, FromDocumentLineNo, ToDocumentLineNo);
        if IsHandled then
            exit;

        PurchCommentLineSource.SetRange("Document Type", FromDocumentType);
        PurchCommentLineSource.SetRange("No.", FromNumber);
        PurchCommentLineSource.SetRange("Document Line No.", FromDocumentLineNo);
        if PurchCommentLineSource.FindSet() then
            repeat
                PurchCommentLineTarget := PurchCommentLineSource;
                PurchCommentLineTarget."Document Type" := Enum::"Purchase Comment Document Type".FromInteger(ToDocumentType);
                PurchCommentLineTarget."No." := ToNumber;
                PurchCommentLineTarget."Document Line No." := ToDocumentLineNo;
                PurchCommentLineTarget.Insert();
            until PurchCommentLineSource.Next() = 0;
    end;

    procedure CopyLineCommentsFromPurchaseLines(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20]; var TempPurchaseLineSource: Record "Purchase Line" temporary)
    var
        PurchCommentLineSource: Record "Purch. Comment Line";
        PurchCommentLineTarget: Record "Purch. Comment Line";
        IsHandled: Boolean;
        NextLineNo: Integer;
    begin
        IsHandled := false;
        OnBeforeCopyLineCommentsFromPurchaseLines(
          PurchCommentLineTarget, IsHandled, FromDocumentType, ToDocumentType, FromNumber, ToNumber, TempPurchaseLineSource);
        if IsHandled then
            exit;

        PurchCommentLineTarget.SetRange("Document Type", ToDocumentType);
        PurchCommentLineTarget.SetRange("No.", ToNumber);
        PurchCommentLineTarget.SetRange("Document Line No.", 0);
        if PurchCommentLineTarget.FindLast() then;
        NextLineNo := PurchCommentLineTarget."Line No." + 10000;
        PurchCommentLineTarget.Reset();

        PurchCommentLineSource.SetRange("Document Type", FromDocumentType);
        PurchCommentLineSource.SetRange("No.", FromNumber);
        if TempPurchaseLineSource.FindSet() then
            repeat
                PurchCommentLineSource.SetRange("Document Line No.", TempPurchaseLineSource."Line No.");
                if PurchCommentLineSource.FindSet() then
                    repeat
                        PurchCommentLineTarget := PurchCommentLineSource;
                        PurchCommentLineTarget."Document Type" := Enum::"Purchase Comment Document Type".FromInteger(ToDocumentType);
                        PurchCommentLineTarget."No." := ToNumber;
                        PurchCommentLineTarget."Document Line No." := 0;
                        PurchCommentLineTarget."Line No." := NextLineNo;
                        PurchCommentLineTarget.Insert();
                        NextLineNo += 10000;
                    until PurchCommentLineSource.Next() = 0;
            until TempPurchaseLineSource.Next() = 0;
    end;

    procedure CopyHeaderComments(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    var
        PurchCommentLineSource: Record "Purch. Comment Line";
        PurchCommentLineTarget: Record "Purch. Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyHeaderComments(PurchCommentLineTarget, IsHandled, FromDocumentType, ToDocumentType, FromNumber, ToNumber);
        if IsHandled then
            exit;

        PurchCommentLineSource.SetRange("Document Type", FromDocumentType);
        PurchCommentLineSource.SetRange("No.", FromNumber);
        PurchCommentLineSource.SetRange("Document Line No.", 0);
        if PurchCommentLineSource.FindSet() then
            repeat
                PurchCommentLineTarget := PurchCommentLineSource;
                PurchCommentLineTarget."Document Type" := Enum::"Purchase Comment Document Type".FromInteger(ToDocumentType);
                PurchCommentLineTarget."No." := ToNumber;
                PurchCommentLineTarget.Insert();
            until PurchCommentLineSource.Next() = 0;
    end;

    procedure DeleteComments(DocType: Option; DocNo: Code[20])
    begin
        SetRange("Document Type", DocType);
        SetRange("No.", DocNo);
        if not IsEmpty() then
            DeleteAll();
    end;

    procedure ShowComments(DocType: Option; DocNo: Code[20]; DocLineNo: Integer)
    var
        PurchCommentSheet: Page "Purch. Comment Sheet";
    begin
        SetRange("Document Type", DocType);
        SetRange("No.", DocNo);
        SetRange("Document Line No.", DocLineNo);
        Clear(PurchCommentSheet);
        PurchCommentSheet.SetTableView(Rec);
        PurchCommentSheet.RunModal();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var PurchCommentLineRec: Record "Purch. Comment Line"; var PurchCommentLineFilter: Record "Purch. Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyComments(var PurchCommentLine: Record "Purch. Comment Line"; ToDocumentType: Integer; var IsHandled: Boolean; FromDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyLineComments(var PurchCommentLine: Record "Purch. Comment Line"; var IsHandled: Boolean; FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20]; FromDocumentLineNo: Integer; ToDocumentLine: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyLineCommentsFromPurchaseLines(var PurchCommentLine: Record "Purch. Comment Line"; var IsHandled: Boolean; FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20]; var TempPurchaseLineSource: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyHeaderComments(var PurchCommentLine: Record "Purch. Comment Line"; var IsHandled: Boolean; FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyCommentsOnBeforeInsert(var NewPurchCommentLine: Record "Purch. Comment Line"; OldPurchCommentLine: Record "Purch. Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUpNewLineOnAfterSetFilter(var PurchCommentLineRec: Record "Purch. Comment Line"; var PurchCommentLineFilter: Record "Purch. Comment Line")
    begin
    end;
}

