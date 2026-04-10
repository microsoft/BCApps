#pragma warning disable AA0247
codeunit 12472 "Copy FA Document Mgt."
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Please enter a Document No.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 %2 cannot be copied onto itself.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'The existing lines for %1 %2 will be deleted.\\';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text003: Label 'Do you want to continue?';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text004: Label 'The document line(s) with a G/L account where direct posting is not allowed have not been copied to the new document by the Copy Document batch job.';
#pragma warning restore AA0074
        FADocType: Option Writeoff,Release,Disposal,"Posted Writeoff","Posted Release","Posted Disposal";
        IncludeHeader: Boolean;
        CreateToHeader: Boolean;

    [Scope('OnPrem')]
    procedure SetProperties(NewIncludeHeader: Boolean; NewCreateToHeader: Boolean)
    begin
        IncludeHeader := NewIncludeHeader;
        CreateToHeader := NewCreateToHeader;
    end;

    [Scope('OnPrem')]
    procedure FADocHeaderDocType(DocType: Option): Integer
    var
        FADocHeader: Record "FA Document Header";
    begin
        case DocType of
            FADocType::Writeoff:
                exit(FADocHeader."Document Type"::Writeoff);
            FADocType::Release:
                exit(FADocHeader."Document Type"::Release);
            FADocType::Disposal:
                exit(FADocHeader."Document Type"::Movement);
        end;
    end;

    [Scope('OnPrem')]
    procedure CopyFADoc(FromDocType: Option; FromDocNo: Code[20]; var ToFADocHeader: Record "FA Document Header")
    var
        FASetup: Record "Sales & Receivables Setup";
        ToFADocLine: Record "FA Document Line";
        OldFADocHeader: Record "FA Document Header";
        FromFADocHeader: Record "FA Document Header";
        FromFADocLine: Record "FA Document Line";
        FromPostedFADocHeader: Record "Posted FA Doc. Header";
        FromPostedFADocLine: Record "Posted FA Doc. Line";
        NextLineNo: Integer;
        LinesNotCopied: Integer;
    begin
        if not CreateToHeader then begin
            if FromDocNo = '' then
                Error(Text000);
            ToFADocHeader.Find();
        end;
        case FromDocType of
            FADocType::Writeoff,
            FADocType::Release,
            FADocType::Disposal:
                begin
                    FromFADocHeader.Get(FADocHeaderDocType(FromDocType), FromDocNo);
                    if (FromFADocHeader."Document Type" = ToFADocHeader."Document Type") and
                       (FromFADocHeader."No." = ToFADocHeader."No.")
                    then
                        Error(
                          Text001,
                          ToFADocHeader."Document Type", ToFADocHeader."No.");
                end;
            FADocType::"Posted Writeoff",
          FADocType::"Posted Release",
          FADocType::"Posted Disposal":
                FromPostedFADocHeader.Get(FADocHeaderDocType(FromDocType - 3), FromDocNo);
        end;

        ToFADocLine.LockTable();

        if CreateToHeader then begin
            ToFADocHeader.Insert(true);
            ToFADocLine.SetRange("Document Type", ToFADocHeader."Document Type");
            ToFADocLine.SetRange("Document No.", ToFADocHeader."No.");
        end else begin
            ToFADocLine.SetRange("Document Type", ToFADocHeader."Document Type");
            ToFADocLine.SetRange("Document No.", ToFADocHeader."No.");
            if IncludeHeader then
                if not ToFADocLine.IsEmpty() then begin
                    Commit();
                    if not
                       Confirm(
                         Text002 +
                         Text003, true,
                         ToFADocHeader."Document Type", ToFADocHeader."No.")
                    then
                        exit;
                    ToFADocLine.DeleteAll(true);
                end;
        end;

        if ToFADocLine.FindLast() then
            NextLineNo := ToFADocLine."Line No."
        else
            NextLineNo := 0;

        if IncludeHeader then begin
            OldFADocHeader := ToFADocHeader;
            case FromDocType of
                FADocType::Writeoff,
                FADocType::Release,
                FADocType::Disposal:
                    begin
                        ToFADocHeader.TransferFields(FromFADocHeader, false);
                        ToFADocHeader."Posting Date" := OldFADocHeader."Posting Date";
                    end;
                FADocType::"Posted Writeoff",
              FADocType::"Posted Release",
              FADocType::"Posted Disposal":
                    ToFADocHeader.TransferFields(FromPostedFADocHeader, false);
            end;
            ToFADocHeader."No. Series" := OldFADocHeader."No. Series";
            ToFADocHeader."Posting Description" := OldFADocHeader."Posting Description";
            ToFADocHeader."Posting No." := OldFADocHeader."Posting No.";
            ToFADocHeader."Posting No. Series" := OldFADocHeader."Posting No. Series";
            ToFADocHeader."No. Printed" := 0;
        end;

        LinesNotCopied := 0;
        case FromDocType of
            FADocType::Writeoff,
            FADocType::Release,
            FADocType::Disposal:
                begin
                    FromFADocLine.Reset();
                    FromFADocLine.SetRange("Document Type", FromFADocHeader."Document Type");
                    FromFADocLine.SetRange("Document No.", FromFADocHeader."No.");
                    if FromFADocLine.FindSet() then
                        repeat
                            CopyFADocLine(ToFADocHeader, ToFADocLine, FromFADocLine, NextLineNo, LinesNotCopied);
                        until FromFADocLine.Next() = 0;
                end;
            FADocType::"Posted Writeoff",
            FADocType::"Posted Release",
            FADocType::"Posted Disposal":
                begin
                    FASetup.Get();
                    FromFADocHeader.TransferFields(FromPostedFADocHeader);
                    FromPostedFADocLine.Reset();
                    FromPostedFADocLine.SetRange("Document No.", FromPostedFADocHeader."No.");
                    if FromPostedFADocLine.FindSet() then
                        repeat
                            FromFADocLine.TransferFields(FromPostedFADocLine);
                            CopyFADocLine(
                              ToFADocHeader, ToFADocLine, FromFADocLine,
                              NextLineNo, LinesNotCopied);
                        until FromPostedFADocLine.Next() = 0;
                end;
        end;

        if LinesNotCopied > 0 then
            Message(Text004);
    end;

    [Scope('OnPrem')]
    procedure ShowFADoc(ToFADocHeader: Record "FA Document Header")
    begin
        case ToFADocHeader."Document Type" of
            ToFADocHeader."Document Type"::Writeoff:
                PAGE.Run(PAGE::"FA Writeoff Act", ToFADocHeader);
            ToFADocHeader."Document Type"::Release:
                PAGE.Run(PAGE::"FA Release Act", ToFADocHeader);
            ToFADocHeader."Document Type"::Movement:
                PAGE.Run(PAGE::"FA Movement Act", ToFADocHeader);
        end;
    end;

    local procedure CopyFADocLine(var ToFADocHeader: Record "FA Document Header"; var ToFADocLine: Record "FA Document Line"; var FromFADocLine: Record "FA Document Line"; var NextLineNo: Integer; var LinesNotCopied: Integer)
    var
        CopyThisLine: Boolean;
    begin
        CopyThisLine := true;
        ToFADocLine := FromFADocLine;
        NextLineNo := NextLineNo + 10000;
        ToFADocLine."Document Type" := ToFADocHeader."Document Type";
        ToFADocLine."Document No." := ToFADocHeader."No.";
        ToFADocLine."Line No." := NextLineNo;
        if CopyThisLine then
            ToFADocLine.Insert()
        else
            LinesNotCopied := LinesNotCopied + 1;
    end;
}

