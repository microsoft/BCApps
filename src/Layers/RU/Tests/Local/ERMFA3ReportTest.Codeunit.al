codeunit 144715 "ERM FA-3 Report Test"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;
    Permissions = tabledata "Default Signature Setup" = imd,
                  tabledata "Posted FA Doc. Header" = imd,
                  tabledata "Posted FA Doc. Line" = imd;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRUReports: Codeunit "Library RU Reports";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure FAMovementReport()
    var
        FADocHeader: Record "FA Document Header";
        FANo: array[2] of Code[20];
        i: Integer;
    begin
        Initialize();
        for i := 1 to ArrayLen(FANo) do
            FANo[i] := MockFixedAsset();
        MockFADocument(FADocHeader, FANo);
        RunFAMovementReport(FADocHeader);
        VerifyFAMovementReportValues(FADocHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedFAMovementReport()
    var
        PostedFADocHeader: Record "Posted FA Doc. Header";
        FANo: array[2] of Code[20];
        i: Integer;
    begin
        Initialize();
        for i := 1 to ArrayLen(FANo) do
            FANo[i] := MockFixedAsset();
        MockPostedFADocument(PostedFADocHeader, FANo);
        RunPostedFAMovementReport(PostedFADocHeader);
        VerifyPostedFAMovementReportValues(PostedFADocHeader);
    end;

    local procedure Initialize()
    begin
        Clear(LibraryReportValidation);

        if isInitialized then
            exit;

        RemoveMandatorySignSetup();

        isInitialized := true;
    end;

    local procedure MockFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.Init();
        FixedAsset."No." := LibraryUtility.GenerateGUID();
        FixedAsset.Insert();
        FixedAsset.Description := LibraryUtility.GenerateGUID();
        FixedAsset."Inventory Number" := LibraryUtility.GenerateGUID();
        FixedAsset."Passport No." := LibraryUtility.GenerateGUID();
        FixedAsset."Factory No." := LibraryUtility.GenerateGUID();
        FixedAsset.Modify();
        FixedAsset.InitFADeprBooks(FixedAsset."No.");
        exit(FixedAsset."No.");
    end;

    local procedure MockFADocument(var FADocHeader: Record "FA Document Header"; FANo: array[2] of Code[20])
    var
        i: Integer;
    begin
        MockFAHeader(FADocHeader);
        for i := 1 to ArrayLen(FANo) do
            MockFALine(FADocHeader, FANo[i]);
    end;

    local procedure MockFAHeader(var FADocHeader: Record "FA Document Header")
    begin
        FADocHeader.Init();
        FADocHeader."Document Type" := FADocHeader."Document Type"::Movement;
        FADocHeader."No." := LibraryUtility.GenerateGUID();
        FADocHeader.Insert();
        FADocHeader."Posting Date" := WorkDate();
        FADocHeader."FA Location Code" := LibraryRUReports.MockFALocation();
        FADocHeader."New FA Location Code" := LibraryRUReports.MockFALocation();
        FADocHeader.Modify();
    end;

    local procedure MockFALine(FADocHeader: Record "FA Document Header"; FANo: Code[20])
    var
        FADocLine: Record "FA Document Line";
        RecRef: RecordRef;
    begin
        FADocLine.Init();
        FADocLine."Document Type" := FADocHeader."Document Type";
        FADocLine."Document No." := FADocHeader."No.";
        RecRef.GetTable(FADocLine);
        FADocLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, FADocLine.FieldNo("Line No."));
        FADocLine.Insert();
        FADocLine.Description := LibraryUtility.GenerateGUID();
        FADocLine."FA No." := FANo;
        FADocLine."Depreciation Book Code" := LibraryRUReports.GetFirstFADeprBook(FADocLine."FA No.");
        FADocLine."FA Posting Group" := LibraryRUReports.MockFAPostingGroup();
        FADocLine.Amount := LibraryRandom.RandDec(100, 2);
        FADocLine.Modify();
    end;

    local procedure MockPostedFADocument(var PostedFADocHeader: Record "Posted FA Doc. Header"; FANo: array[2] of Code[20])
    var
        i: Integer;
    begin
        MockPostedFAHeader(PostedFADocHeader);
        for i := 1 to ArrayLen(FANo) do
            MockPostedFALine(PostedFADocHeader, FANo[i]);
    end;

    local procedure MockPostedFAHeader(var PostedFADocHeader: Record "Posted FA Doc. Header")
    begin
        PostedFADocHeader.Init();
        PostedFADocHeader."Document Type" := PostedFADocHeader."Document Type"::Movement;
        PostedFADocHeader."No." := LibraryUtility.GenerateGUID();
        PostedFADocHeader.Insert();
        PostedFADocHeader."Posting Date" := WorkDate();
        PostedFADocHeader."FA Location Code" := LibraryRUReports.MockFALocation();
        PostedFADocHeader."New FA Location Code" := LibraryRUReports.MockFALocation();
        PostedFADocHeader.Modify();
    end;

    local procedure MockPostedFALine(PostedFADocHeader: Record "Posted FA Doc. Header"; FANo: Code[20])
    var
        PostedFADocLine: Record "Posted FA Doc. Line";
        RecRef: RecordRef;
    begin
        PostedFADocLine.Init();
        PostedFADocLine."Document Type" := PostedFADocHeader."Document Type";
        PostedFADocLine."Document No." := PostedFADocHeader."No.";
        RecRef.GetTable(PostedFADocLine);
        PostedFADocLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, PostedFADocLine.FieldNo("Line No."));
        PostedFADocLine.Insert();
        PostedFADocLine."FA No." := FANo;
        PostedFADocLine."Depreciation Book Code" := LibraryRUReports.GetFirstFADeprBook(PostedFADocLine."FA No.");
        PostedFADocLine."FA Posting Group" := LibraryRUReports.MockFAPostingGroup();
        PostedFADocLine.Amount := LibraryRandom.RandDec(100, 2);
        PostedFADocLine.Modify();
    end;

    local procedure RunFAMovementReport(FADocHeader: Record "FA Document Header")
    var
        FAMovementRep: Report "FA Movement FA-3";
    begin
        LibraryReportValidation.SetFileName(FADocHeader."No.");
        FADocHeader.SetRecFilter();
        FAMovementRep.SetFileNameSilent(LibraryReportValidation.GetFileName());
        FAMovementRep.SetTableView(FADocHeader);
        FAMovementRep.UseRequestPage(false);
        FAMovementRep.Run();
    end;

    local procedure RunPostedFAMovementReport(PostedFADocHeader: Record "Posted FA Doc. Header")
    var
        PostedFAMovementRep: Report "FA Posted Movement FA-3";
    begin
        LibraryReportValidation.SetFileName(PostedFADocHeader."No.");
        PostedFADocHeader.SetRecFilter();
        PostedFAMovementRep.SetFileNameSilent(LibraryReportValidation.GetFileName());
        PostedFAMovementRep.SetTableView(PostedFADocHeader);
        PostedFAMovementRep.UseRequestPage(false);
        PostedFAMovementRep.Run();
    end;

    local procedure RemoveMandatorySignSetup()
    var
        DefaultSignSetup: Record "Default Signature Setup";
    begin
        DefaultSignSetup.SetFilter("Table ID", '%1|%2', DATABASE::"FA Document Header", DATABASE::"FA Document Line");
        DefaultSignSetup.SetRange(Mandatory, true);
        DefaultSignSetup.DeleteAll(true);
    end;

    local procedure VerifyFAMovementReportValues(FADocHeader: Record "FA Document Header")
    var
        FADocLine: Record "FA Document Line";
        RowShift: Integer;
    begin
        VerifyReportHeader(
          FADocHeader."FA Location Code", FADocHeader."New FA Location Code", FADocHeader."No.", FADocHeader."Posting Date");

        FADocLine.SetRange("Document Type", FADocHeader."Document Type");
        FADocLine.SetRange("Document No.", FADocHeader."No.");
        FADocLine.FindSet();
        RowShift := 0;
        repeat
            VerifyReportLineValues(RowShift, FADocLine.Description, FADocLine."FA No.", FADocLine.Amount);
            RowShift += 1;
        until FADocLine.Next() = 0;
    end;

    local procedure VerifyPostedFAMovementReportValues(PostedFADocHeader: Record "Posted FA Doc. Header")
    var
        PostedFADocLine: Record "Posted FA Doc. Line";
        RowShift: Integer;
    begin
        VerifyReportHeader(
          PostedFADocHeader."FA Location Code", PostedFADocHeader."New FA Location Code",
          PostedFADocHeader."No.", PostedFADocHeader."Posting Date");

        PostedFADocLine.SetRange("Document Type", PostedFADocHeader."Document Type");
        PostedFADocLine.SetRange("Document No.", PostedFADocHeader."No.");
        PostedFADocLine.FindSet();
        RowShift := 0;
        repeat
            VerifyReportLineValues(RowShift, PostedFADocLine.Description, PostedFADocLine."FA No.", PostedFADocLine.Amount);
            RowShift += 1;
        until PostedFADocLine.Next() = 0;
    end;

    local procedure VerifyReportHeader(FALocationCode: Code[10]; NewFALocationCode: Code[10]; DocNo: Code[20]; DocDate: Date)
    var
        FALocation: Record "FA Location";
    begin
        LibraryReportValidation.VerifyCellValue(8, 1, FALocation.GetName(NewFALocationCode));
        LibraryReportValidation.VerifyCellValue(10, 20, FALocation.GetName(FALocationCode));
        LibraryReportValidation.VerifyCellValue(15, 45, DocNo);
        LibraryReportValidation.VerifyCellValue(15, 65, Format(DocDate));
    end;

    local procedure VerifyReportLineValues(RowShift: Integer; Description: Text; FANo: Code[20]; ExpectedAmount: Decimal)
    var
        FixedAsset: Record "Fixed Asset";
        StdRepMgt: Codeunit "Local Report Management";
        LineRowId: Integer;
    begin
        FixedAsset.Get(FANo);
        LineRowId := 28 + RowShift;
        LibraryReportValidation.VerifyCellValue(LineRowId, 1, Format(RowShift + 1));
        LibraryReportValidation.VerifyCellValue(LineRowId, 11, Description);
        LibraryReportValidation.VerifyCellValue(LineRowId, 51, FixedAsset."Inventory Number");
        LibraryReportValidation.VerifyCellValue(LineRowId, 69, FixedAsset."Passport No.");
        LibraryReportValidation.VerifyCellValue(LineRowId, 89, FixedAsset."Factory No.");
        LibraryReportValidation.VerifyCellValue(LineRowId, 108, StdRepMgt.FormatReportValue(ExpectedAmount, 2));
    end;
}

