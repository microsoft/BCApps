// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Comment;

using Microsoft.Sales.Document;

/// <summary>
/// Stores comment lines associated with sales documents and posted sales documents.
/// </summary>
table 44 "Sales Comment Line"
{
    Caption = 'Sales Comment Line';
    DrillDownPageID = "Sales Comment List";
    LookupPageID = "Sales Comment List";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the type of sales document this comment is associated with.
        /// </summary>
        field(1; "Document Type"; Enum "Sales Comment Document Type")
        {
            Caption = 'Document Type';
        }
        /// <summary>
        /// Specifies the document number that this comment belongs to.
        /// </summary>
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
        /// <summary>
        /// Specifies the unique sequence number for this comment line within the document.
        /// </summary>
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Specifies the date when the comment was created.
        /// </summary>
        field(4; Date; Date)
        {
            Caption = 'Date';
            ToolTip = 'Specifies the date the comment was created.';
        }
        /// <summary>
        /// Specifies a code to categorize or classify the comment.
        /// </summary>
        field(5; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for the comment.';
        }
        /// <summary>
        /// Contains the actual text of the comment.
        /// </summary>
        field(6; Comment; Text[80])
        {
            Caption = 'Comment';
            ToolTip = 'Specifies the comment itself.';
        }
        /// <summary>
        /// Specifies the line number of the sales document line this comment is attached to. A value of zero indicates a header-level comment.
        /// </summary>
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

    /// <summary>
    /// Initializes default values for a new sales comment line, setting the date to work date if no other comment exists for the current date.
    /// </summary>
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

    /// <summary>
    /// Copies all comment lines from one sales document to another.
    /// </summary>
    /// <param name="FromDocumentType">Specifies the source document type.</param>
    /// <param name="ToDocumentType">Specifies the target document type.</param>
    /// <param name="FromNumber">Specifies the source document number.</param>
    /// <param name="ToNumber">Specifies the target document number.</param>
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

    /// <summary>
    /// Copies comment lines associated with a specific document line to another document line.
    /// </summary>
    /// <param name="FromDocumentType">Specifies the source document type.</param>
    /// <param name="ToDocumentType">Specifies the target document type.</param>
    /// <param name="FromNumber">Specifies the source document number.</param>
    /// <param name="ToNumber">Specifies the target document number.</param>
    /// <param name="FromDocumentLineNo">Specifies the source document line number.</param>
    /// <param name="ToDocumentLineNo">Specifies the target document line number.</param>
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

    /// <summary>
    /// Copies line-level comments from multiple sales lines to header-level comments on the target document.
    /// </summary>
    /// <param name="FromDocumentType">Specifies the source document type.</param>
    /// <param name="ToDocumentType">Specifies the target document type.</param>
    /// <param name="FromNumber">Specifies the source document number.</param>
    /// <param name="ToNumber">Specifies the target document number.</param>
    /// <param name="TempSalesLineSource">Specifies the temporary sales lines whose comments should be copied.</param>
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

    /// <summary>
    /// Copies header-level comments from one sales document to another.
    /// </summary>
    /// <param name="FromDocumentType">Specifies the source document type.</param>
    /// <param name="ToDocumentType">Specifies the target document type.</param>
    /// <param name="FromNumber">Specifies the source document number.</param>
    /// <param name="ToNumber">Specifies the target document number.</param>
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

    /// <summary>
    /// Deletes all comment lines associated with the specified sales document.
    /// </summary>
    /// <param name="DocType">Specifies the document type of the comments to delete.</param>
    /// <param name="DocNo">Specifies the document number of the comments to delete.</param>
    procedure DeleteComments(DocType: Option; DocNo: Code[20])
    begin
        SetRange("Document Type", DocType);
        SetRange("No.", DocNo);
        if not IsEmpty() then
            DeleteAll();
    end;

    /// <summary>
    /// Opens the Sales Comment Sheet page to display comments for the specified document or document line.
    /// </summary>
    /// <param name="DocType">Specifies the document type to filter comments.</param>
    /// <param name="DocNo">Specifies the document number to filter comments.</param>
    /// <param name="DocLineNo">Specifies the document line number to filter comments. Use zero for header-level comments.</param>
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

    /// <summary>
    /// Raises an event after initializing default values for a new sales comment line.
    /// </summary>
    /// <param name="SalesCommentLineRec">Specifies the sales comment line record being initialized.</param>
    /// <param name="SalesCommentLineFilter">Specifies the sales comment line record used for filtering.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var SalesCommentLineRec: Record "Sales Comment Line"; var SalesCommentLineFilter: Record "Sales Comment Line")
    begin
    end;

    /// <summary>
    /// Raises an event before copying comment lines from one document to another.
    /// </summary>
    /// <param name="SalesCommentLine">Specifies the sales comment line record.</param>
    /// <param name="ToDocumentType">Specifies the target document type.</param>
    /// <param name="IsHandled">Set to true to skip the default copying logic.</param>
    /// <param name="FromDocumentType">Specifies the source document type.</param>
    /// <param name="FromNumber">Specifies the source document number.</param>
    /// <param name="ToNumber">Specifies the target document number.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyComments(var SalesCommentLine: Record "Sales Comment Line"; ToDocumentType: Integer; var IsHandled: Boolean; FromDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    begin
    end;

    /// <summary>
    /// Raises an event before copying line-specific comment lines from one document line to another.
    /// </summary>
    /// <param name="SalesCommentLine">Specifies the target sales comment line record.</param>
    /// <param name="IsHandled">Set to true to skip the default copying logic.</param>
    /// <param name="FromDocumentType">Specifies the source document type.</param>
    /// <param name="ToDocumentType">Specifies the target document type.</param>
    /// <param name="FromNumber">Specifies the source document number.</param>
    /// <param name="ToNumber">Specifies the target document number.</param>
    /// <param name="FromDocumentLineNo">Specifies the source document line number.</param>
    /// <param name="ToDocumentLine">Specifies the target document line number.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyLineComments(var SalesCommentLine: Record "Sales Comment Line"; var IsHandled: Boolean; FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20]; FromDocumentLineNo: Integer; ToDocumentLine: Integer)
    begin
    end;

    /// <summary>
    /// Raises an event before copying line-level comments from sales lines to header-level comments on the target document.
    /// </summary>
    /// <param name="SalesCommentLine">Specifies the target sales comment line record.</param>
    /// <param name="IsHandled">Set to true to skip the default copying logic.</param>
    /// <param name="FromDocumentType">Specifies the source document type.</param>
    /// <param name="ToDocumentType">Specifies the target document type.</param>
    /// <param name="FromNumber">Specifies the source document number.</param>
    /// <param name="ToNumber">Specifies the target document number.</param>
    /// <param name="TempSalesLineSource">Specifies the temporary sales lines whose comments should be copied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyLineCommentsFromSalesLines(var SalesCommentLine: Record "Sales Comment Line"; var IsHandled: Boolean; FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20]; var TempSalesLineSource: Record "Sales Line" temporary)
    begin
    end;

    /// <summary>
    /// Raises an event before copying header-level comments from one document to another.
    /// </summary>
    /// <param name="SalesCommentLine">Specifies the target sales comment line record.</param>
    /// <param name="IsHandled">Set to true to skip the default copying logic.</param>
    /// <param name="FromDocumentType">Specifies the source document type.</param>
    /// <param name="ToDocumentType">Specifies the target document type.</param>
    /// <param name="FromNumber">Specifies the source document number.</param>
    /// <param name="ToNumber">Specifies the target document number.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyHeaderComments(var SalesCommentLine: Record "Sales Comment Line"; var IsHandled: Boolean; FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    begin
    end;

    /// <summary>
    /// Raises an event before inserting a copied comment line, allowing modification of the new comment before insertion.
    /// </summary>
    /// <param name="NewSalesCommentLine">Specifies the new sales comment line to be inserted.</param>
    /// <param name="OldSalesCommentLine">Specifies the original sales comment line being copied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyCommentsOnBeforeInsert(var NewSalesCommentLine: Record "Sales Comment Line"; OldSalesCommentLine: Record "Sales Comment Line")
    begin
    end;

    /// <summary>
    /// Raises an event before initializing default values for a new sales comment line.
    /// </summary>
    /// <param name="SalesCommentLineRec">Specifies the sales comment line record being initialized.</param>
    /// <param name="SalesCommentLineFilter">Specifies the sales comment line record used for filtering.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetUpNewLine(var SalesCommentLineRec: Record "Sales Comment Line"; var SalesCommentLineFilter: Record "Sales Comment Line")
    begin
    end;
}

