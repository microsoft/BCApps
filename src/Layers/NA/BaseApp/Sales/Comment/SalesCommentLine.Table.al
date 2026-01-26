// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Comment;

using Microsoft.Sales.Document;

table 44 "Sales Comment Line"
{
    Caption = 'Sales Comment Line';
    DrillDownPageID = "Sales Comment List";
    LookupPageID = "Sales Comment List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Sales Comment Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
            ToolTip = 'Specifies the date the comment was created.';
        }
        field(5; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for the comment.';
        }
        field(6; Comment; Text[80])
        {
            Caption = 'Comment';
            ToolTip = 'Specifies the comment itself.';
        }
        field(7; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(10000; "Print On Quote"; Boolean)
        {
            Caption = 'Print On Quote';
        }
        field(10001; "Print On Pick Ticket"; Boolean)
        {
            Caption = 'Print On Pick Ticket';
        }
        field(10002; "Print On Order Confirmation"; Boolean)
        {
            Caption = 'Print On Order Confirmation';
        }
        field(10003; "Print On Shipment"; Boolean)
        {
            Caption = 'Print On Shipment';
        }
        field(10004; "Print On Invoice"; Boolean)
        {
            Caption = 'Print On Invoice';
        }
        field(10005; "Print On Credit Memo"; Boolean)
        {
            Caption = 'Print On Credit Memo';
        }
        field(10006; "Print On Return Authorization"; Boolean)
        {
            Caption = 'Print On Return Authorization';
        }
        field(10007; "Print On Return Receipt"; Boolean)
        {
            Caption = 'Print On Return Receipt';
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
        SalesCommentLine: Record "Sales Comment Line";
    begin
        OnBeforeSetUpNewLine(Rec, SalesCommentLine);

        SalesCommentLine.SetRange("Document Type", "Document Type");
        SalesCommentLine.SetRange("No.", "No.");
        SalesCommentLine.SetRange("Document Line No.", "Document Line No.");
        SalesCommentLine.SetRange(Date, WorkDate());
        if not SalesCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, SalesCommentLine);
    end;

    procedure CopyComments(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesCommentLine2: Record "Sales Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyComments(SalesCommentLine, ToDocumentType, IsHandled, FromDocumentType, FromNumber, ToNumber);
        if IsHandled then
            exit;

        SalesCommentLine.SetRange("Document Type", FromDocumentType);
        SalesCommentLine.SetRange("No.", FromNumber);
        if SalesCommentLine.FindSet() then
            repeat
                SalesCommentLine2 := SalesCommentLine;
                SalesCommentLine2."Document Type" := Enum::"Sales Comment Document Type".FromInteger(ToDocumentType);
                SalesCommentLine2."No." := ToNumber;
                OnBeforeCopyCommentsOnBeforeInsert(SalesCommentLine2, SalesCommentLine);
                SalesCommentLine2.Insert();
            until SalesCommentLine.Next() = 0;
    end;

    procedure CopyLineComments(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20]; FromDocumentLineNo: Integer; ToDocumentLineNo: Integer)
    var
        SalesCommentLineSource: Record "Sales Comment Line";
        SalesCommentLineTarget: Record "Sales Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyLineComments(
          SalesCommentLineTarget, IsHandled, FromDocumentType, ToDocumentType, FromNumber, ToNumber, FromDocumentLineNo, ToDocumentLineNo);
        if IsHandled then
            exit;

        SalesCommentLineSource.SetRange("Document Type", FromDocumentType);
        SalesCommentLineSource.SetRange("No.", FromNumber);
        SalesCommentLineSource.SetRange("Document Line No.", FromDocumentLineNo);
        if SalesCommentLineSource.FindSet() then
            repeat
                SalesCommentLineTarget := SalesCommentLineSource;
                SalesCommentLineTarget."Document Type" := Enum::"Sales Comment Document Type".FromInteger(ToDocumentType);
                SalesCommentLineTarget."No." := ToNumber;
                SalesCommentLineTarget."Document Line No." := ToDocumentLineNo;
                SalesCommentLineTarget.Insert();
            until SalesCommentLineSource.Next() = 0;
    end;

    procedure CopyLineCommentsFromSalesLines(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20]; var TempSalesLineSource: Record "Sales Line" temporary)
    var
        SalesCommentLineSource: Record "Sales Comment Line";
        SalesCommentLineTarget: Record "Sales Comment Line";
        IsHandled: Boolean;
        NextLineNo: Integer;
    begin
        IsHandled := false;
        OnBeforeCopyLineCommentsFromSalesLines(
          SalesCommentLineTarget, IsHandled, FromDocumentType, ToDocumentType, FromNumber, ToNumber, TempSalesLineSource);
        if IsHandled then
            exit;

        SalesCommentLineTarget.SetRange("Document Type", ToDocumentType);
        SalesCommentLineTarget.SetRange("No.", ToNumber);
        SalesCommentLineTarget.SetRange("Document Line No.", 0);
        if SalesCommentLineTarget.FindLast() then;
        NextLineNo := SalesCommentLineTarget."Line No." + 10000;
        SalesCommentLineTarget.Reset();

        SalesCommentLineSource.SetRange("Document Type", FromDocumentType);
        SalesCommentLineSource.SetRange("No.", FromNumber);
        if TempSalesLineSource.FindSet() then
            repeat
                SalesCommentLineSource.SetRange("Document Line No.", TempSalesLineSource."Line No.");
                if SalesCommentLineSource.FindSet() then
                    repeat
                        SalesCommentLineTarget := SalesCommentLineSource;
                        SalesCommentLineTarget."Document Type" := Enum::"Sales Comment Document Type".FromInteger(ToDocumentType);
                        SalesCommentLineTarget."No." := ToNumber;
                        SalesCommentLineTarget."Document Line No." := 0;
                        SalesCommentLineTarget."Line No." := NextLineNo;
                        SalesCommentLineTarget.Insert();
                        NextLineNo += 10000;
                    until SalesCommentLineSource.Next() = 0;
            until TempSalesLineSource.Next() = 0;
    end;

    procedure CopyHeaderComments(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    var
        SalesCommentLineSource: Record "Sales Comment Line";
        SalesCommentLineTarget: Record "Sales Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyHeaderComments(SalesCommentLineTarget, IsHandled, FromDocumentType, ToDocumentType, FromNumber, ToNumber);
        if IsHandled then
            exit;

        SalesCommentLineSource.SetRange("Document Type", FromDocumentType);
        SalesCommentLineSource.SetRange("No.", FromNumber);
        SalesCommentLineSource.SetRange("Document Line No.", 0);
        if SalesCommentLineSource.FindSet() then
            repeat
                SalesCommentLineTarget := SalesCommentLineSource;
                SalesCommentLineTarget."Document Type" := Enum::"Sales Comment Document Type".FromInteger(ToDocumentType);
                SalesCommentLineTarget."No." := ToNumber;
                SalesCommentLineTarget.Insert();
            until SalesCommentLineSource.Next() = 0;
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
        SalesCommentSheet: Page "Sales Comment Sheet";
    begin
        SetRange("Document Type", DocType);
        SetRange("No.", DocNo);
        SetRange("Document Line No.", DocLineNo);
        Clear(SalesCommentSheet);
        SalesCommentSheet.SetTableView(Rec);
        SalesCommentSheet.RunModal();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var SalesCommentLineRec: Record "Sales Comment Line"; var SalesCommentLineFilter: Record "Sales Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyComments(var SalesCommentLine: Record "Sales Comment Line"; ToDocumentType: Integer; var IsHandled: Boolean; FromDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyLineComments(var SalesCommentLine: Record "Sales Comment Line"; var IsHandled: Boolean; FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20]; FromDocumentLineNo: Integer; ToDocumentLine: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyLineCommentsFromSalesLines(var SalesCommentLine: Record "Sales Comment Line"; var IsHandled: Boolean; FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20]; var TempSalesLineSource: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyHeaderComments(var SalesCommentLine: Record "Sales Comment Line"; var IsHandled: Boolean; FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyCommentsOnBeforeInsert(var NewSalesCommentLine: Record "Sales Comment Line"; OldSalesCommentLine: Record "Sales Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetUpNewLine(var SalesCommentLineRec: Record "Sales Comment Line"; var SalesCommentLineFilter: Record "Sales Comment Line")
    begin
    end;
}

