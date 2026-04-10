codeunit 144717 "ERM FA-4 Report Test"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;
    Permissions = tabledata "Default Signature Setup" = imd,
                  tabledata "Invt. Receipt Line" = imd,
                  tabledata "Posted FA Doc. Header" = imd,
                  tabledata "Posted FA Doc. Line" = imd;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRUReports: Codeunit "Library RU Reports";
        StdRepMgt: Codeunit "Local Report Management";
        isInitialized: Boolean;
        ValueNotExistErr: Label 'Value not exist in worksheet no. %1', Comment = '%1 - row % 2 - column';

    [Test]
    [Scope('OnPrem')]
    procedure SingleLineFAWriteOffFA4()
    begin
        FAWriteoffAct(Report::"FA Write-off Act FA-4", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleLineFAWriteOffFA4()
    begin
        FAWriteoffAct(Report::"FA Write-off Act FA-4", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleLineFAWriteOffFA4a()
    begin
        FAWriteoffAct(Report::"FA Writeoff Act FA-4a", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleLineFAWriteOffFA4a()
    begin
        FAWriteoffAct(Report::"FA Writeoff Act FA-4a", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleLinePostedFAWriteOffFA4a()
    begin
        FAPostedWriteoffAct(Report::"Posted FA Writeoff Act FA-4a", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleLinePostedFAWriteOffFA4a()
    begin
        FAPostedWriteoffAct(Report::"Posted FA Writeoff Act FA-4a", true);
    end;

    local procedure FAWriteoffAct(ReportID: Integer; MultipleLine: Boolean)
    var
        FADocHeader: Record "FA Document Header";
        FANo: array[2] of Code[20];
        ReceiptNo: Code[20];
        i: Integer;
    begin
        Initialize();
        for i := 1 to ArrayLen(FANo) do
            FANo[i] := MockFixedAsset();
        ReceiptNo := MockInvtDocumentLines();
        MockFADocument(FADocHeader, FANo, ReceiptNo, MultipleLine);
        RunReport(FADocHeader, ReportID);
        VerifyResults(FADocHeader, ReportID);
    end;

    local procedure FAPostedWriteoffAct(ReportID: Integer; MultipleLine: Boolean)
    var
        PostedFADocHeader: Record "Posted FA Doc. Header";
        FANo: array[2] of Code[20];
        ReceiptNo: Code[20];
        i: Integer;
    begin
        Initialize();
        for i := 1 to ArrayLen(FANo) do
            FANo[i] := MockFixedAsset();
        ReceiptNo := MockInvtRcptLines();
        MockPostedFADocument(PostedFADocHeader, FANo, ReceiptNo, MultipleLine);
        RunPostedReport(PostedFADocHeader, ReportID);
        VerifyPostedResults(PostedFADocHeader, ReportID);
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
        FADeprBook: Record "FA Depreciation Book";
        i: Integer;
    begin
        FixedAsset.Init();
        FixedAsset."No." := LibraryUtility.GenerateGUID();
        FixedAsset.Insert();
        FixedAsset.Description := LibraryUtility.GenerateGUID();
        FixedAsset."Description 2" := LibraryUtility.GenerateGUID();
        FixedAsset."Initial Release Date" := WorkDate();
        FixedAsset."FA Location Code" := LibraryRUReports.MockFALocation();
        FixedAsset."Depreciation Code" := LibraryRUReports.MockDepreciationCode();
        FixedAsset."Depreciation Group" := LibraryRUReports.MockDepreciationGroup();
        FixedAsset."Inventory Number" := LibraryUtility.GenerateGUID();
        FixedAsset."Factory No." := LibraryUtility.GenerateGUID();
        FixedAsset."Manufacturing Year" := Format(Date2DMY(WorkDate(), 3));
        FixedAsset."Vehicle Model" := LibraryUtility.GenerateGUID();
        FixedAsset."Vehicle Reg. No." := LibraryUtility.GenerateGUID();
        FixedAsset."Vehicle Engine No." := LibraryUtility.GenerateGUID();
        FixedAsset."Vehicle Chassis No." := LibraryUtility.GenerateGUID();
        FixedAsset."Is Vehicle" := true;
        FixedAsset."Vehicle Writeoff Date" := GetRandomDate();
        FixedAsset."Run after Release Date" := LibraryRandom.RandInt(100);
        FixedAsset."Run after Renovation Date" := LibraryRandom.RandInt(100);
        FixedAsset.Modify();

        FixedAsset.InitFADeprBooks(FixedAsset."No.");
        FADeprBook.SetRange("FA No.", FixedAsset."No.");
        FADeprBook.FindFirst();
        LibraryRUReports.MockFADepreciationBook(FADeprBook);

        for i := 1 to LibraryRandom.RandIntInRange(3, 5) do begin
            LibraryRUReports.MockMainAssetComponent(FixedAsset."No.");
            LibraryRUReports.MockItemFAPreciousMetal(FixedAsset."No.");
        end;

        exit(FixedAsset."No.");
    end;

    local procedure MockItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item.Init();
        Item."No." := LibraryUtility.GenerateGUID();
        Item.Insert();
        exit(Item."No.");
    end;

    local procedure MockFADocument(var FADocHeader: Record "FA Document Header"; FANo: array[2] of Code[20]; ReceiptNo: Code[20]; MultipleLine: Boolean)
    var
        "Count": Integer;
        i: Integer;
    begin
        MockFAHeader(FADocHeader);
        if MultipleLine then
            Count := ArrayLen(FANo)
        else
            Count := 1;
        for i := 1 to Count do
            MockFALine(FADocHeader, FANo[i], ReceiptNo);
    end;

    local procedure MockFAHeader(var FADocHeader: Record "FA Document Header")
    begin
        FADocHeader.Init();
        FADocHeader."Document Type" := FADocHeader."Document Type"::Writeoff;
        FADocHeader."No." := LibraryUtility.GenerateGUID();
        FADocHeader.Insert();
        FADocHeader."Posting Date" := WorkDate();
        FADocHeader.Modify();
    end;

    local procedure MockFALine(FADocHeader: Record "FA Document Header"; FANo: Code[20]; ReceiptNo: Code[20])
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
        FADocLine."FA No." := FANo;
        FADocLine."Depreciation Book Code" := LibraryRUReports.GetFirstFADeprBook(FADocLine."FA No.");
        FADocLine."FA Posting Group" := LibraryRUReports.MockFAPostingGroup();
        FADocLine."Item Receipt No." := ReceiptNo;
        FADocLine.Modify();
    end;

    local procedure MockPostedFADocument(var PostedFADocHeader: Record "Posted FA Doc. Header"; FANo: array[2] of Code[20]; ReceiptNo: Code[20]; MultipleLine: Boolean)
    var
        "Count": Integer;
        i: Integer;
    begin
        MockPostedFAHeader(PostedFADocHeader);
        if MultipleLine then
            Count := ArrayLen(FANo)
        else
            Count := 1;
        for i := 1 to Count do
            MockPostedFALine(PostedFADocHeader, FANo[i], ReceiptNo);
    end;

    local procedure MockPostedFAHeader(var PostedFADocHeader: Record "Posted FA Doc. Header")
    begin
        PostedFADocHeader.Init();
        PostedFADocHeader."Document Type" := PostedFADocHeader."Document Type"::Writeoff;
        PostedFADocHeader."No." := LibraryUtility.GenerateGUID();
        PostedFADocHeader.Insert();
        PostedFADocHeader."Posting Date" := WorkDate();
        PostedFADocHeader.Modify();
    end;

    local procedure MockPostedFALine(PostedFADocHeader: Record "Posted FA Doc. Header"; FANo: Code[20]; ReceiptNo: Code[20])
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
        PostedFADocLine."Item Receipt No." := ReceiptNo;
        PostedFADocLine.Modify();
    end;

    local procedure MockInvtDocumentLines(): Code[20]
    var
        InvtDocumentLine: Record "Invt. Document Line";
    begin
        InvtDocumentLine.Init();
        InvtDocumentLine."Document No." := LibraryUtility.GenerateGUID();
        InvtDocumentLine.Description := InvtDocumentLine."Document No.";
        InvtDocumentLine."Item No." := MockItem();
        InvtDocumentLine.Quantity := LibraryRandom.RandInt(100);
        InvtDocumentLine."Unit Amount" := LibraryRandom.RandDec(100, 2);
        InvtDocumentLine.Amount := LibraryRandom.RandDec(100, 2);
        InvtDocumentLine.Insert();
        exit(InvtDocumentLine."Document No.");
    end;

    local procedure MockInvtRcptLines(): Code[20]
    var
        InvtReceiptLine: Record "Invt. Receipt Line";
    begin
        InvtReceiptLine.Init();
        InvtReceiptLine."Document No." := LibraryUtility.GenerateGUID();
        InvtReceiptLine.Description := InvtReceiptLine."Document No.";
        InvtReceiptLine."Item No." := MockItem();
        InvtReceiptLine.Quantity := LibraryRandom.RandInt(100);
        InvtReceiptLine."Unit Amount" := LibraryRandom.RandDec(100, 2);
        InvtReceiptLine.Amount := LibraryRandom.RandDec(100, 2);
        InvtReceiptLine.Insert();
        exit(InvtReceiptLine."Document No.");
    end;

    local procedure RunReport(FADocHeader: Record "FA Document Header"; ReportID: Integer)
    begin
        case ReportID of
            Report::"FA Write-off Act FA-4":
                RunFAWriteOffFA4(FADocHeader);
            Report::"FA Writeoff Act FA-4a":
                RunFAWriteOffFA4a(FADocHeader);
        end;
    end;

    local procedure RunPostedReport(PostedFADocHeader: Record "Posted FA Doc. Header"; ReportID: Integer)
    begin
        case ReportID of
            Report::"FA Posted Writeoff Act FA-4":
                RunPostedFAWriteOffFA4(PostedFADocHeader);
            Report::"Posted FA Writeoff Act FA-4a":
                RunPostedFAWriteOffFA4a(PostedFADocHeader);
        end;
    end;

    local procedure RunFAWriteOffFA4(FADocHeader: Record "FA Document Header")
    var
        FAWriteoffActFA4: Report "FA Write-off Act FA-4";
    begin
        LibraryReportValidation.SetFileName(FADocHeader."No.");
        FADocHeader.SetRecFilter();
        FAWriteoffActFA4.SetFileNameSilent(LibraryReportValidation.GetFileName());
        FAWriteoffActFA4.SetTableView(FADocHeader);
        FAWriteoffActFA4.UseRequestPage(false);
        FAWriteoffActFA4.Run();
    end;

    local procedure RunPostedFAWriteOffFA4(PostedFADocHeader: Record "Posted FA Doc. Header")
    var
        PostedFAWriteoffActFA4: Report "FA Posted Writeoff Act FA-4";
    begin
        LibraryReportValidation.SetFileName(PostedFADocHeader."No.");
        PostedFADocHeader.SetRecFilter();
        PostedFAWriteoffActFA4.SetFileNameSilent(LibraryReportValidation.GetFileName());
        PostedFAWriteoffActFA4.SetTableView(PostedFADocHeader);
        PostedFAWriteoffActFA4.UseRequestPage(false);
        PostedFAWriteoffActFA4.Run();
    end;

    local procedure RunFAWriteOffFA4a(FADocHeader: Record "FA Document Header")
    var
        FAWriteoffActFA4a: Report "FA Writeoff Act FA-4a";
    begin
        LibraryReportValidation.SetFileName(FADocHeader."No.");
        FADocHeader.SetRecFilter();
        FAWriteoffActFA4a.SetFileNameSilent(LibraryReportValidation.GetFileName());
        FAWriteoffActFA4a.SetTableView(FADocHeader);
        FAWriteoffActFA4a.UseRequestPage(false);
        FAWriteoffActFA4a.Run();
    end;

    local procedure RunPostedFAWriteOffFA4a(PostedFADocHeader: Record "Posted FA Doc. Header")
    var
        PostedFAWriteoffActFA4a: Report "Posted FA Writeoff Act FA-4a";
    begin
        LibraryReportValidation.SetFileName(PostedFADocHeader."No.");
        PostedFADocHeader.SetRecFilter();
        PostedFAWriteoffActFA4a.SetFileNameSilent(LibraryReportValidation.GetFileName());
        PostedFAWriteoffActFA4a.SetTableView(PostedFADocHeader);
        PostedFAWriteoffActFA4a.UseRequestPage(false);
        PostedFAWriteoffActFA4a.Run();
    end;

    local procedure RemoveMandatorySignSetup()
    var
        DefaultSignSetup: Record "Default Signature Setup";
    begin
        DefaultSignSetup.SetFilter("Table ID", '%1|%2', DATABASE::"FA Document Header", DATABASE::"FA Document Line");
        DefaultSignSetup.SetRange(Mandatory, true);
        DefaultSignSetup.DeleteAll(true);
    end;

    local procedure GetRandomDate(): Date
    begin
        exit(CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));
    end;

    local procedure VerifyResults(FADocHeader: Record "FA Document Header"; ReportID: Integer)
    var
        FADocLine: Record "FA Document Line";
        RowShift: Integer;
    begin
        FADocLine.SetRange("Document Type", FADocHeader."Document Type");
        FADocLine.SetRange("Document No.", FADocHeader."No.");
        FADocLine.FindSet();
        RowShift := 0;
        repeat
            case ReportID of
                Report::"FA Write-off Act FA-4":
                    VerifyFAWriteoffFA4Results(
                      FADocLine."FA No.", FADocLine.Description, FADocLine."Depreciation Book Code", FADocLine."Item Receipt No.", ReportID, RowShift);
                Report::"FA Writeoff Act FA-4a":
                    VerifyFAWriteoffFA4aResults(
                      FADocLine."FA No.", FADocLine."Depreciation Book Code", FADocLine."Item Receipt No.", ReportID, RowShift);
            end;
            RowShift += 1;
        until FADocLine.Next() = 0;
    end;

    local procedure VerifyPostedResults(PostedFADocHeader: Record "Posted FA Doc. Header"; ReportID: Integer)
    var
        PostedFADocLine: Record "Posted FA Doc. Line";
        RowShift: Integer;
    begin
        PostedFADocLine.SetRange("Document Type", PostedFADocHeader."Document Type");
        PostedFADocLine.SetRange("Document No.", PostedFADocHeader."No.");
        PostedFADocLine.FindSet();
        RowShift := 0;
        repeat
            case ReportID of
                Report::"FA Posted Writeoff Act FA-4":
                    VerifyFAWriteoffFA4Results(
                      PostedFADocLine."FA No.", PostedFADocLine.Description, PostedFADocLine."Depreciation Book Code", PostedFADocLine."Item Receipt No.", ReportID, RowShift);
                Report::"Posted FA Writeoff Act FA-4a":
                    VerifyFAWriteoffFA4aResults(
                      PostedFADocLine."FA No.", PostedFADocLine."Depreciation Book Code", PostedFADocLine."Item Receipt No.", ReportID, RowShift);
            end;
            RowShift += 1;
        until PostedFADocLine.Next() = 0;
    end;

    local procedure VerifyFAWriteoffFA4Results(FANo: Code[20]; Description: Text; DeprBookCode: Code[10]; ReceiptNo: Code[20]; ReportID: Integer; RowShift: Integer)
    var
        FA: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        LineRowID: Integer;
    begin
        LineRowID := 38 + RowShift;
        FA.Get(FANo);
        FADepreciationBook.Get(FANo, DeprBookCode);
        FADepreciationBook.CalcFields("Acquisition Cost", Depreciation, "Book Value");
        LibraryReportValidation.VerifyCellValue(LineRowID, 1, Description);
        LibraryReportValidation.VerifyCellValue(LineRowID, 20, FA."Inventory Number");
        LibraryReportValidation.VerifyCellValue(LineRowID, 30, FA."Factory No.");
        LibraryReportValidation.VerifyCellValue(LineRowID, 40, FA."Manufacturing Year");
        LibraryReportValidation.VerifyCellValue(LineRowID, 50, Format(FA."Initial Release Date"));
        case ReportID of
            Report::"FA Write-off Act FA-4":
                begin
                    LibraryReportValidation.VerifyCellValue(LineRowID, 70, Format(FADepreciationBook."Acquisition Cost"));
                    LibraryReportValidation.VerifyCellValue(LineRowID, 80, Format(Abs(FADepreciationBook.Depreciation)));
                    LibraryReportValidation.VerifyCellValue(LineRowID, 90, Format(FADepreciationBook."Book Value"));
                    VerifyItemDocLine(ReceiptNo, 2);
                end;
            Report::"FA Posted Writeoff Act FA-4":
                begin
                    LibraryReportValidation.VerifyCellValue(LineRowID, 70, Format(Abs(FADepreciationBook."Acquisition Cost")));
                    LibraryReportValidation.VerifyCellValue(LineRowID, 80, Format(Abs(FADepreciationBook.Depreciation)));
                    LibraryReportValidation.VerifyCellValue(
                      LineRowID, 90, Format(FADepreciationBook."Acquisition Cost" + FADepreciationBook.Depreciation));
                    VerifyItemRcptLine(ReceiptNo, 2);
                end;
        end;

        VerifyMainAssetComponent(FANo);
        VerifyItemFAPreciousMetal(FANo);
    end;

    local procedure VerifyFAWriteoffFA4aResults(FANo: Code[20]; DeprBookCode: Code[10]; ReceiptNo: Code[20]; ReportID: Integer; RowShift: Integer)
    var
        FA: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        LineRowID: Integer;
    begin
        LineRowID := 40 + RowShift;
        FA.Get(FANo);
        FADepreciationBook.Get(FANo, DeprBookCode);
        FADepreciationBook.CalcFields("Acquisition Cost", Depreciation, "Book Value");
        LibraryReportValidation.VerifyCellValue(LineRowID, 1, FA."Manufacturing Year");
        LibraryReportValidation.VerifyCellValue(LineRowID, 10, Format(FADepreciationBook."Acquisition Date", 0, '<Month,2>.<Year4>'));
        LibraryReportValidation.VerifyCellValue(LineRowID, 20, Format(FADepreciationBook."G/L Acquisition Date"));
        LibraryReportValidation.VerifyCellValue(LineRowID, 30, Format(FA."Is Vehicle"));
        LibraryReportValidation.VerifyCellValue(LineRowID, 40, Format(FA."Vehicle Writeoff Date"));
        LibraryReportValidation.VerifyCellValue(LineRowID, 50, Format(FA."Run after Release Date"));
        LibraryReportValidation.VerifyCellValue(LineRowID, 60, Format(FA."Run after Renovation Date"));
        case ReportID of
            Report::"FA Write-off Act FA-4":
                begin
                    LibraryReportValidation.VerifyCellValue(LineRowID, 70, Format(Abs(FADepreciationBook."Initial Acquisition Cost")));
                    LibraryReportValidation.VerifyCellValue(LineRowID, 80, Format(Abs(FADepreciationBook.Depreciation)));
                    LibraryReportValidation.VerifyCellValue(LineRowID, 90, Format(FADepreciationBook."Book Value"));
                    VerifyItemDocLine(ReceiptNo, 3);
                end;
            Report::"FA Posted Writeoff Act FA-4":
                begin
                    LibraryReportValidation.VerifyCellValue(LineRowID, 70, Format(Abs(FADepreciationBook.Depreciation)));
                    LibraryReportValidation.VerifyCellValue(LineRowID, 80, Format(Abs(FADepreciationBook.Depreciation)));
                    LibraryReportValidation.VerifyCellValue(
                      LineRowID, 90, Format(FADepreciationBook."Acquisition Cost" + FADepreciationBook.Depreciation));
                    VerifyItemRcptLine(ReceiptNo, 3);
                end;
        end;

        VerifyFAChars(FANo);
        VerifyItemFAPreciousMetal(FANo);
    end;

    local procedure VerifyMainAssetComponent(FANo: Code[20])
    var
        MainAssetComponent: Record "Main Asset Component";
    begin
        MainAssetComponent.SetRange("Main Asset No.", FANo);
        MainAssetComponent.FindSet();
        repeat
            CheckIfValueExistsOnSpecificWorksheet(2, MainAssetComponent.Description);
            CheckIfValueExistsOnSpecificWorksheet(2, StdRepMgt.FormatReportValue(MainAssetComponent.Quantity, 2));
        until MainAssetComponent.Next() = 0;
    end;

    local procedure VerifyItemFAPreciousMetal(FANo: Code[20])
    var
        ItemFAPreciousMetal: Record "Item/FA Precious Metal";
    begin
        ItemFAPreciousMetal.SetRange("Item Type", ItemFAPreciousMetal."Item Type"::FA);
        ItemFAPreciousMetal.SetRange("No.", FANo);
        ItemFAPreciousMetal.FindSet();
        repeat
            ItemFAPreciousMetal.CalcFields(Name);
            CheckIfValueExistsOnSpecificWorksheet(2, ItemFAPreciousMetal.Name);
            CheckIfValueExistsOnSpecificWorksheet(2, ItemFAPreciousMetal."Precious Metals Code");
            CheckIfValueExistsOnSpecificWorksheet(2, StdRepMgt.FormatReportValue(ItemFAPreciousMetal.Quantity, 2));
            CheckIfValueExistsOnSpecificWorksheet(2, StdRepMgt.FormatReportValue(ItemFAPreciousMetal.Mass, 2));
        until ItemFAPreciousMetal.Next() = 0;
    end;

    local procedure VerifyFAChars(FANo: Code[20])
    var
        FA: Record "Fixed Asset";
    begin
        FA.Get(FANo);
        CheckIfValueExistsOnSpecificWorksheet(2, FA."Vehicle Reg. No.");
        CheckIfValueExistsOnSpecificWorksheet(2, FA."Vehicle Engine No.");
        CheckIfValueExistsOnSpecificWorksheet(2, FA."Vehicle Chassis No.");
        CheckIfValueExistsOnSpecificWorksheet(2, StdRepMgt.FormatReportValue(FA."Vehicle Capacity", 2));
        CheckIfValueExistsOnSpecificWorksheet(2, StdRepMgt.FormatReportValue(FA."Vehicle Passport Weight", 2));
    end;

    local procedure VerifyItemDocLine(ReceiptNo: Code[20]; WorksheetNo: Integer)
    var
        InvtDocumentLine: Record "Invt. Document Line";
    begin
        InvtDocumentLine.SetRange("Document No.", ReceiptNo);
        InvtDocumentLine.FindSet();
        repeat
            CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, InvtDocumentLine."Document No.");
            CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, InvtDocumentLine.Description);
            CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, InvtDocumentLine."Item No.");
            CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, StdRepMgt.FormatReportValue(InvtDocumentLine.Quantity, 2));
            CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, StdRepMgt.FormatReportValue(InvtDocumentLine."Unit Amount", 2));
            CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, StdRepMgt.FormatReportValue(InvtDocumentLine.Amount, 2));
        until InvtDocumentLine.Next() = 0;
    end;

    local procedure VerifyItemRcptLine(ReceiptNo: Code[20]; WorksheetNo: Integer)
    var
        InvtReceiptLine: Record "Invt. Receipt Line";
    begin
        InvtReceiptLine.SetRange("Document No.", ReceiptNo);
        InvtReceiptLine.FindSet();
        repeat
            CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, InvtReceiptLine."Document No.");
            CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, InvtReceiptLine.Description);
            CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, InvtReceiptLine."Item No.");
            CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, StdRepMgt.FormatReportValue(InvtReceiptLine.Quantity, 2));
            CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, StdRepMgt.FormatReportValue(InvtReceiptLine."Unit Amount", 2));
            CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, StdRepMgt.FormatReportValue(InvtReceiptLine.Amount, 2));
        until InvtReceiptLine.Next() = 0;
    end;

    local procedure CheckIfValueExistsOnSpecificWorksheet(WorksheetNo: Integer; Value: Text)
    begin
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(WorksheetNo, Value),
          StrSubstNo(ValueNotExistErr, WorksheetNo));
    end;
}

