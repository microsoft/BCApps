#pragma warning disable AA0247
codeunit 12471 "FA Document-Post"
{
    Permissions = TableData "FA Ledger Entry" = rimd,
                  TableData "Posted FA Doc. Header" = rimd,
                  TableData "Posted FA Doc. Line" = rimd;
    TableNo = "FA Document Header";

    trigger OnRun()
    var
        NoSeries: Codeunit "No. Series";
    begin
        FADocHeader.Copy(Rec);

        FASetup.Get();
        GLSetup.Get();
        TaxRegisterSetup.Get();

        CheckDim();

        // Header
        PostedFADocHeader.Init();
        PostedFADocHeader.TransferFields(FADocHeader);

        if FADocHeader."Posting No." <> '' then
            PostedFADocHeader."No." := FADocHeader."Posting No."
        else
            if FADocHeader."No. Series" = FADocHeader."Posting No. Series" then
                PostedFADocHeader."No." := FADocHeader."No."
            else
                PostedFADocHeader."No." := NoSeries.GetNextNo(FADocHeader."Posting No. Series", Rec."Posting Date");

        DocSignMgt.CheckDocSignatures(DATABASE::"FA Document Header", Rec."Document Type", Rec."No.");

        DocSignMgt.MoveDocSignToPostedDocSign(
          DocSign, DATABASE::"FA Document Header",
          FADocHeader."Document Type", FADocHeader."No.",
          DATABASE::"Posted FA Doc. Header", PostedFADocHeader."No.");

        CopyCommentLines(
          FADocHeader."Document Type", FADocHeader."No.", PostedFADocHeader."No.");

        PostedFADocHeader."User ID" := UserId;
        PostedFADocHeader."Creation Date" := WorkDate();
        PostedFADocHeader.Insert();

        // Lines
        FADocLine.Reset();
        FADocLine.SetRange("Document Type", FADocHeader."Document Type");
        FADocLine.SetRange("Document No.", FADocHeader."No.");
        if FADocLine.FindSet() then
            repeat
                if FoundLateEntries(
                     FADocLine."FA No.",
                     FADocLine."Depreciation Book Code",
                     FADocLine."Posting Date")
                then
                    Error(Text001, Rec."Document Type");

                FADocLine.TestField("Depreciation Book Code");
                FA.Get(FADocLine."FA No.");

                case Rec."Document Type" of
                    Rec."Document Type"::Writeoff:
                        PostFAWriteOff();
                    Rec."Document Type"::Release,
                  Rec."Document Type"::Movement:
                        PostFAReleaseMovement(Rec."Document Type");
                end;

                InsertFADocLine(FADocLine, PostedFADocHeader."No.");

                Clear(GenJnlPostLine);
                Clear(FAJnlPostLine);
            until FADocLine.Next() = 0;

        if PreviewMode then
            Error('');

        FADocHeader.Delete(true);
        Rec := FADocHeader;
    end;

    var
        FADocHeader: Record "FA Document Header";
        FADocLine: Record "FA Document Line";
        PostedFADocHeader: Record "Posted FA Doc. Header";
        PostedFADocLine: Record "Posted FA Doc. Line";
        FASetup: Record "FA Setup";
        FAJnlLine: Record "FA Journal Line";
        GenJnlLine: Record "Gen. Journal Line";
        FALedgEntry: Record "FA Ledger Entry";
        FAReclassJnlLine: Record "FA Reclass. Journal Line";
        FAJnlSetup: Record "FA Journal Setup";
        FADeprBook: Record "FA Depreciation Book";
        FADeprBook2: Record "FA Depreciation Book";
        DepreciationBook: Record "Depreciation Book";
        FA: Record "Fixed Asset";
        FAComment: Record "FA Comment";
        PostedFAComment: Record "Posted FA Comment";
        InvtDocHeader: Record "Invt. Document Header";
        TaxRegisterSetup: Record "Tax Register Setup";
        DocSign: Record "Document Signature";
        GLSetup: Record "General Ledger Setup";
        FAJnlPostLine: Codeunit "FA Jnl.-Post Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        FAReclassTransferLine: Codeunit "FA Reclass. Transfer Line";
        FAReclassCheckLine: Codeunit "FA Reclass. Check Line";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 must be last Operation.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        DocSignMgt: Codeunit "Doc. Signature Management";
        InvtRcptPost: Codeunit "Invt. Doc.-Post Receipt";
        ReclassDone: Boolean;
        PreviewMode: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text005: Label 'The combination of dimensions used in %1 %2 is blocked. %3';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text006: Label 'The combination of dimensions used in %1 %2 is blocked. %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text007: Label 'The dimensions used in %1 %2, line no. %3 are invalid. %4';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure InsertFADocLine(FADocLine: Record "FA Document Line"; PostedDocNo: Code[20])
    begin
        PostedFADocLine.Init();
        PostedFADocLine.TransferFields(FADocLine);
        PostedFADocLine."Document No." := PostedDocNo;
        PostedFADocLine.Insert();
    end;

    local procedure CopyCommentLines(DocType: Integer; DocNo: Code[20]; ToDocNo: Code[20])
    begin
        FAComment.SetRange("Document Type", DocType);
        FAComment.SetRange("Document No.", DocNo);
        if FAComment.FindSet() then
            repeat
                PostedFAComment.TransferFields(FAComment);
                PostedFAComment."Document No." := ToDocNo;
                PostedFAComment.Insert();
            until FAComment.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure FoundLateEntries(FANo: Code[20]; FADeprBookCode: Code[10]; PostingDate: Date): Boolean
    var
        FALedgEntry: Record "FA Ledger Entry";
    begin
        FALedgEntry.Reset();
        FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
        FALedgEntry.SetRange("FA No.", FANo);
        FALedgEntry.SetRange("Depreciation Book Code", FADeprBookCode);
        FALedgEntry.SetRange(Reversed, false);
        FALedgEntry.SetFilter("FA Posting Date", '>%1', PostingDate);
        if FALedgEntry.FindSet() then
            repeat
                if FALedgEntry."Canceled from FA No." = '' then
                    exit(true);
            until FALedgEntry.Next() = 0;
        exit(false);
    end;

    local procedure CheckDim()
    begin
        FADocLine."Line No." := 0;
        CheckDimComb(FADocHeader, FADocLine);
        CheckDimValuePosting(FADocHeader, FADocLine);

        FADocLine.SetRange("Document Type", FADocHeader."Document Type");
        FADocLine.SetRange("Document No.", FADocHeader."No.");
        if FADocLine.FindFirst() then begin
            CheckDimComb(FADocHeader, FADocLine);
            CheckDimValuePosting(FADocHeader, FADocLine);
        end;
    end;

    local procedure CheckDimComb(FADocHeader: Record "FA Document Header"; FADocLine: Record "FA Document Line")
    begin
        if FADocLine."Line No." = 0 then
            if not DimMgt.CheckDimIDComb(FADocHeader."Dimension Set ID") then
                Error(
                  Text005,
                  FADocHeader."No.", DimMgt.GetDimCombErr());
        if FADocLine."Line No." <> 0 then
            if not DimMgt.CheckDimIDComb(FADocLine."Dimension Set ID") then
                Error(
                  Text006,
                  FADocHeader."No.", FADocLine."Line No.", DimMgt.GetDimCombErr());
    end;

    local procedure CheckDimValuePosting(FADocHeader: Record "FA Document Header"; FADocLine: Record "FA Document Line")
    var
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        TableIDArr[1] := DATABASE::"Fixed Asset";
        NumberArr[1] := FADocLine."FA No.";
        if FADocLine."Line No." = 0 then
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, FADocHeader."Dimension Set ID") then
                Error(
                  Text007,
                  FADocHeader."No.", FADocLine."Line No.", DimMgt.GetDimValuePostingErr());

        if FADocLine."Line No." <> 0 then
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, FADocLine."Dimension Set ID") then
                Error(
                  Text007,
                  FADocHeader."No.", FADocLine."Line No.", DimMgt.GetDimValuePostingErr());
    end;

    [Scope('OnPrem')]
    procedure FAPostTransfer(FADocLine: Record "FA Document Line"; CheckLine: Boolean)
    var
        FADepreciationBook: Record "FA Depreciation Book";
        MakeFALedgEntry: Codeunit "Make FA Ledger Entry";
        i: Integer;
        Rate: Integer;
    begin
        if FADocLine."FA No." = '' then
            exit;
        if FADocLine."Posting Date" = 0D then
            FADocLine."Posting Date" := FADocLine."FA Posting Date";

        FA.LockTable();
        DepreciationBook.Get(FADocLine."Depreciation Book Code");
        FA.Get(FADocLine."FA No.");
        FA.TestField(Blocked, false);
        FA.TestField(Inactive, false);
        FADepreciationBook.Get(FADocLine."FA No.", FADocLine."Depreciation Book Code");
        FADepreciationBook.SetFilter("FA Posting Date Filter", '..%1', FADocLine."FA Posting Date");
        FADepreciationBook.CalcFields(
          "Acquisition Cost", Depreciation, "Proceeds on Disposal", "Gain/Loss",
          "Write-Down", Appreciation, "Custom 1", "Custom 2", "Salvage Value",
          "Book Value on Disposal");

        Rate := -1;
        for i := 0 to 1 do begin
            if i = 1 then
                Rate := 1;

            MakeFALedgEntry.CopyFromFADocLine(FALedgEntry, FADocLine);
            if i = 0 then begin
                FALedgEntry."FA Location Code" := '';
                FALedgEntry."Employee No." := '';
            end;
            MakeFALedgEntry.CopyFromFACard(FALedgEntry, FA, FADepreciationBook);
            FALedgEntry."Document No." := PostedFADocHeader."No.";

            if FADepreciationBook."Acquisition Cost" <> 0 then begin
                FALedgEntry."FA Posting Category" := FALedgEntry."FA Posting Category"::" ";
                FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::"Acquisition Cost";
                FALedgEntry.Amount := Rate * FADepreciationBook."Acquisition Cost";
                FALedgEntry.Quantity := Rate * FADocLine.Quantity;
                InsertTransferFALedgEntry(FALedgEntry, Rate);
            end;
            FALedgEntry.Quantity := 0;

            if FADepreciationBook.Depreciation <> 0 then begin
                FALedgEntry."FA Posting Category" := FALedgEntry."FA Posting Category"::" ";
                FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::Depreciation;
                FALedgEntry.Amount := Rate * FADepreciationBook.Depreciation;
                InsertTransferFALedgEntry(FALedgEntry, Rate);
            end;
            if FADepreciationBook."Proceeds on Disposal" <> 0 then begin
                FALedgEntry."FA Posting Category" := FALedgEntry."FA Posting Category"::" ";
                FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::"Proceeds on Disposal";
                FALedgEntry.Amount := Rate * FADepreciationBook."Proceeds on Disposal";
                InsertTransferFALedgEntry(FALedgEntry, Rate);
            end;
            if FADepreciationBook."Gain/Loss" <> 0 then begin
                FALedgEntry."FA Posting Category" := FALedgEntry."FA Posting Category"::" ";
                FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::"Gain/Loss";
                FALedgEntry.Amount := Rate * FADepreciationBook."Gain/Loss";
                InsertTransferFALedgEntry(FALedgEntry, Rate);
            end;
            if FADepreciationBook."Write-Down" <> 0 then begin
                FALedgEntry."FA Posting Category" := FALedgEntry."FA Posting Category"::" ";
                FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::"Write-Down";
                FALedgEntry.Amount := Rate * FADepreciationBook."Write-Down";
                InsertTransferFALedgEntry(FALedgEntry, Rate);
            end;
            if FADepreciationBook.Appreciation <> 0 then begin
                FALedgEntry."FA Posting Category" := FALedgEntry."FA Posting Category"::" ";
                FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::Appreciation;
                FALedgEntry.Amount := Rate * FADepreciationBook.Appreciation;
                InsertTransferFALedgEntry(FALedgEntry, Rate);
            end;
            if FADepreciationBook."Custom 1" <> 0 then begin
                FALedgEntry."FA Posting Category" := FALedgEntry."FA Posting Category"::" ";
                FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::"Custom 1";
                FALedgEntry.Amount := Rate * FADepreciationBook."Custom 1";
                InsertTransferFALedgEntry(FALedgEntry, Rate);
            end;
            if FADepreciationBook."Custom 2" <> 0 then begin
                FALedgEntry."FA Posting Category" := FALedgEntry."FA Posting Category"::" ";
                FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::"Custom 2";
                FALedgEntry.Amount := Rate * FADepreciationBook."Custom 2";
                InsertTransferFALedgEntry(FALedgEntry, Rate);
            end;
            if FADepreciationBook."Salvage Value" <> 0 then begin
                FALedgEntry."FA Posting Category" := FALedgEntry."FA Posting Category"::" ";
                FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::"Salvage Value";
                FALedgEntry.Amount := Rate * FADepreciationBook."Salvage Value";
                InsertTransferFALedgEntry(FALedgEntry, Rate);
            end;
            if FADepreciationBook."Book Value on Disposal" <> 0 then begin
                FALedgEntry."FA Posting Category" := FALedgEntry."FA Posting Category"::Disposal;
                FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::"Book Value on Disposal";
                FALedgEntry.Amount := Rate * FADepreciationBook."Book Value on Disposal";
                InsertTransferFALedgEntry(FALedgEntry, Rate);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetJnlName(var GenJnlLine2: Record "Gen. Journal Line"; BudgetedAsset: Boolean)
    var
        FAGetJnl: Codeunit "FA Get Journal";
        TemplateName: Code[10];
        BatchName: Code[10];
        GLIntegration: Boolean;
    begin
        FAGetJnl.JnlName(
          GenJnlLine2."Depreciation Book Code", BudgetedAsset,
          "FA Journal Line FA Posting Type".FromInteger(GenJnlLine2."FA Posting Type".AsInteger() - 1),
          GLIntegration, TemplateName, BatchName);

        GenJnlLine2."Journal Template Name" := TemplateName;
        GenJnlLine2."Journal Batch Name" := BatchName;
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    local procedure GetFADefaultDim(FANo: Code[20]; var GlobalDimCode1: Code[20]; var GlobalDimCode2: Code[20]; var DimSetID: Integer; SourceCode: Code[20])
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::"Fixed Asset", FANo);
        GlobalDimCode1 := '';
        GlobalDimCode2 := '';
        DimSetID := DimMgt.GetDefaultDimID(DefaultDimSource, SourceCode, GlobalDimCode1, GlobalDimCode2, 0, 0);
    end;

    local procedure InsertTransferFALedgEntry(var FALedgEntry: Record "FA Ledger Entry"; Rate: Integer)
    var
        FAInsertLedgEntry: Codeunit "FA Insert Ledger Entry";
    begin
        if Rate = -1 then
            GetFADefaultDim(
              FALedgEntry."FA No.",
              FALedgEntry."Global Dimension 1 Code",
              FALedgEntry."Global Dimension 2 Code",
              FALedgEntry."Dimension Set ID",
              FALedgEntry."Source Code");
        FAInsertLedgEntry.InsertTransfer(FALedgEntry)
    end;

    local procedure PostFAWriteOff()
    begin
        GenJnlLine.Init();
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Fixed Asset";
        GenJnlLine."Account No." := FADocLine."FA No.";
        GenJnlLine."Posting Date" := FADocLine."Posting Date";
        GenJnlLine."Document No." := PostedFADocHeader."No.";
        GenJnlLine.Description := FADocLine.Description;
        GenJnlLine."FA Posting Date" := FADocLine."FA Posting Date";
        GenJnlLine."FA Posting Type" := GenJnlLine."FA Posting Type"::Disposal;
        GenJnlLine."Depreciation Book Code" := FADocLine."Depreciation Book Code";
        GenJnlLine."FA Location Code" := FADocLine."FA Location Code";
        GenJnlLine."Employee No." := FADocLine."FA Employee No.";
        GenJnlLine."Depr. until FA Posting Date" := true;
        GenJnlLine."Shortcut Dimension 1 Code" := FADocLine."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := FADocLine."Shortcut Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := FADocLine."Dimension Set ID";
        GenJnlLine."Reason Code" := FADocLine."Reason Code";
        GetJnlName(GenJnlLine, FA."Budgeted Asset");

        GenJnlPostLine.SetPreviewMode(PreviewMode);
        GenJnlPostLine.RunWithCheck(GenJnlLine);

        FA.Status := FA.Status::WrittenOff;
        FA."Status Date" := PostedFADocHeader."FA Posting Date";
        FA."Status Document No." := PostedFADocHeader."No.";
        FA."Vehicle Writeoff Date" := PostedFADocHeader."FA Posting Date";
        FA.Modify();

        if FADocLine."Item Receipt No." <> '' then begin
            InvtDocHeader.Get(InvtDocHeader."Document Type"::Receipt, FADocLine."Item Receipt No.");
            Clear(InvtRcptPost);
            InvtRcptPost.SetHideValidationDialog(true);
            InvtRcptPost.Run(InvtDocHeader);
            FADocLine."Item Receipt No." := InvtRcptPost.GetPostedItemReceipt();
        end;
    end;

    local procedure PostFAReleaseMovement(DocType: Option)
    var
        FADocHeader: Record "FA Document Header";
    begin
        if (DocType = FADocHeader."Document Type"::Release) or
           (FADocLine."FA No." <> FADocLine."New FA No.") or
           (FADocLine."Depreciation Book Code" <> FADocLine."New Depreciation Book Code") // reclassification
        then begin
            FADeprBook.Get(FADocLine."FA No.", FADocLine."Depreciation Book Code");
            FADeprBook2.Get(FADocLine."New FA No.", FADocLine."New Depreciation Book Code");
            if DocType = FADocHeader."Document Type"::Release then begin
                FADeprBook2."Depreciation Starting Date" := CalcDate('<CM+1D>', FADocLine."FA Posting Date");
                if FADeprBook."No. of Depreciation Years" > 0 then
                    FADeprBook2.Validate("No. of Depreciation Years", FADeprBook."No. of Depreciation Years")
                else
                    FADeprBook2.Validate("No. of Depreciation Years");
            end;
            FADeprBook2.Modify();

            FAReclassJnlLine.Init();
            FAReclassJnlLine.Validate("FA No.", FADocLine."FA No.");
            if FADocLine."New FA No." <> '' then
                FAReclassJnlLine.Validate("New FA No.", FADocLine."New FA No.")
            else
                FAReclassJnlLine.Validate("New FA No.", FADocLine."FA No.");
            FAReclassJnlLine."FA Posting Date" := FADocLine."FA Posting Date";
            FAReclassJnlLine."Posting Date" := FADocLine."Posting Date";
            FAReclassJnlLine."Depreciation Book Code" := FADocLine."Depreciation Book Code";
            FAReclassJnlLine."New Depreciation Book Code" := FADocLine."New Depreciation Book Code";
            FAReclassJnlLine.Description := FADocLine.Description;
            FAReclassJnlLine."Document No." := PostedFADocHeader."No.";
            FAReclassJnlLine."FA Location Code" := FADocLine."FA Location Code";
            FAReclassJnlLine."Employee No." := FADocLine."FA Employee No.";
            FAReclassJnlLine."FA Posting Group" := FADocLine."FA Posting Group";
            FAReclassJnlLine."New FA Posting Group" := FADocLine."New FA Posting Group";
            FAReclassJnlLine.Validate(Quantity, FADocLine.Quantity);
            FAReclassJnlLine."Reclassify Acquisition Cost" := true;
            FAReclassJnlLine."Reclassify Write-Down" := true;
            FAReclassJnlLine."Reclassify Appreciation" := true;
            FAReclassJnlLine."Reclassify Depreciation" := DocType = FADocHeader."Document Type"::Movement;
            FAReclassCheckLine.Run(FAReclassJnlLine);
            FAReclassTransferLine.FAReclassLine(FAReclassJnlLine, ReclassDone);

            // Post G/L or FA Journal Lines
            Clear(FAJnlSetup);
            if not FAJnlSetup.Get(FADocLine."Depreciation Book Code", UserId) then
                FAJnlSetup.Get(FADocLine."Depreciation Book Code", '');

            GenJnlLine.SetRange("Document No.", PostedFADocHeader."No.");
            GenJnlLine.SetRange("Object Type", GenJnlLine."Account Type"::"Fixed Asset");
            GenJnlLine.SetRange("Object No.", FADocLine."FA No.");
            if GenJnlLine.FindSet() then begin
                repeat
                    GenJnlLine."Shortcut Dimension 1 Code" := FADocLine."Shortcut Dimension 1 Code";
                    GenJnlLine."Shortcut Dimension 2 Code" := FADocLine."Shortcut Dimension 2 Code";
                    GenJnlLine."Dimension Set ID" := FADocLine."Dimension Set ID";
                    GenJnlLine."Reason Code" := FADocLine."Reason Code";
                    GenJnlLine."Tax Difference Code" := TaxRegisterSetup."Default FA TD Code";
                    if GenJnlLine.Quantity < 1 then
                        GetFADefaultDim(
                          FA."No.",
                          GenJnlLine."Shortcut Dimension 1 Code",
                          GenJnlLine."Shortcut Dimension 2 Code",
                          GenJnlLine."Dimension Set ID",
                          FADocLine."Source Code");

                    GenJnlPostLine.SetPreviewMode(PreviewMode);
                    GenJnlPostLine.RunWithCheck(GenJnlLine);
                until GenJnlLine.Next() = 0;
                GenJnlLine.DeleteAll(true);
            end;

            FAJnlLine.SetRange("Document No.", PostedFADocHeader."No.");
            FAJnlLine.SetRange("FA No.", FADocLine."FA No.");
            if FAJnlLine.FindSet() then begin
                repeat
                    FAJnlLine."Shortcut Dimension 1 Code" := FADocLine."Shortcut Dimension 1 Code";
                    FAJnlLine."Shortcut Dimension 2 Code" := FADocLine."Shortcut Dimension 2 Code";
                    FAJnlLine."Dimension Set ID" := FADocLine."Dimension Set ID";
                    FAJnlPostLine.FAJnlPostLine(FAJnlLine, true);
                until FAJnlLine.Next() = 0;
                FAJnlLine.DeleteAll(true);
            end;
        end else // Just FA Entry posting
            FAPostTransfer(FADocLine, true);
        FA.Get(FADocLine."FA No.");
        FA.Validate("Global Dimension 1 Code", FADocLine."Shortcut Dimension 1 Code");
        FA.Validate("Global Dimension 2 Code", FADocLine."Shortcut Dimension 2 Code");
        if DocType = FADocHeader."Document Type"::Release then begin
            FA.Status := FA.Status::Operation;
            FA."Initial Release Date" := PostedFADocHeader."FA Posting Date";
        end;
        if DocType = FADocHeader."Document Type"::Movement then begin
            FA.Status := FADocLine.Status;
            FA."Status Date" := PostedFADocHeader."FA Posting Date";
        end;
        FA."Status Document No." := PostedFADocHeader."No.";
        FA.Modify();
    end;
}

