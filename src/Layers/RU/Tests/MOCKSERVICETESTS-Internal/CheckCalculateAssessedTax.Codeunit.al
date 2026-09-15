codeunit 144525 "Check Calculate Assessed Tax"
{
    // // [FEATURE] [Calculate Assessed Tax] [Fixed Asset] [Report]

    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryTaxAcc: Codeunit "Library - Tax Accounting";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateAssessedTaxQuarter()
    begin
        Initialize();
        CheckCalculateAssessedTax(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateAssessedTaxYear()
    begin
        Initialize();
        CheckCalculateAssessedTax(3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateAssessedTaxWithRounding()
    var
        TaxAuthorityNo: Code[20];
        FixedAssetFilter: Text;
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 379004] Check Calculate Assessed Tax report with rounding result with two fixed assets
        Initialize();

        // [GIVEN] Create 2 Fixed assets with releases amount = "A" and assessed tax code = "T"
        // [GIVEN] Calculate depreciation amount = -"A1" for created fixed assets
        StartingDate := CalcDate('<-CQ>', WorkDate());
        EndingDate := CalcDate('<CQ>', WorkDate());
        SetupAssessedTaxWithRounding(TaxAuthorityNo, FixedAssetFilter, StartingDate);

        // [WHEN] Run Calculate Assessed Tax report
        RunCalculateAssessedTaxReport(TaxAuthorityNo, 0, StartingDate, EndingDate, 1, false, true);

        // [THEN] Verify Book Value Amount in the Calculate Assessed Tax report = 2*3752.5 - 2*62.54 with rounding correctly
        VerifyCalculateAssessedTaxBookValueAmount(FixedAssetFilter, EndingDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateAssessedTaxWithAllowance()
    var
        StartingDate: Date;
        EndingDate: Date;
        TaxAuthNo: Code[20];
        TaxAmountDec: array[2] of Decimal;
        FANo: array[2] of Code[20];
    begin
        // [SCENARIO 379275] Check Calculate Assessed Tax report with two fixed assets normal and allowance, Perod = Quarter.
        Initialize();

        // [GIVEN] Fixed asset "FA1", Assessed Tax Code 'ASSET' with "Exemption Tax Allowance Code" = '', Posted PI with Amount = 10000
        // [GIVEN] Fixed Asset "FA2", Assessed Tax Code 'EXEMPTION' with "Exemption Tax Allowance Code" = 'X' Posted PI with Amount = 2000
        StartingDate := CalcDate('<-CQ>', WorkDate());
        EndingDate := CalcDate('<CQ>', WorkDate());
        SetupAssessedTaxWithAllowance(TaxAuthNo, TaxAmountDec, FANo, StartingDate, true);

        // [WHEN] Run Calculate Assessed Tax report
        RunCalculateAssessedTaxReport(TaxAuthNo, 0, StartingDate, EndingDate, 1, false, true);

        // [THEN] Count of Sheets Is 5.
        // [THEN] Sheet '00002': Correct Amount in Row 030 Column 3 is 12000 (10000+2000)
        // [THEN] Correct amount in Row 030 Column 4 is 2000 (allowance only).
        VerifyTaxAmountWithAllowance(FANo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateAssessedTaxWithAllowanceDecimal()
    var
        StartingDate: Date;
        EndingDate: Date;
        TaxAuthNo: Code[20];
        TaxAmount: array[2] of Decimal;
        FANo: array[2] of Code[20];
    begin
        // [SCENARIO 379612] Check Calculate Assessed Tax report with Decimal values - two fixed assets normal and allowance, Period = Quarter.
        Initialize();

        // [GIVEN] Fixed asset "FA1", Assessed Tax Code 'ASSET' with "Exemption Tax Allowance Code" = '', Posted PI with Amount = 10000.50
        // [GIVEN] Fixed Asset "FA2", Assessed Tax Code 'EXEMPTION' with "Exemption Tax Allowance Code" = 'X' Posted PI with Amount = 200.45
        StartingDate := CalcDate('<-CQ>', WorkDate());
        EndingDate := CalcDate('<CQ>', WorkDate());
        SetupAssessedTaxWithAllowance(TaxAuthNo, TaxAmount, FANo, StartingDate, false);

        // [WHEN] Run Calculate Assessed Tax report
        RunCalculateAssessedTaxReport(TaxAuthNo, 0, StartingDate, EndingDate, 1, false, true);

        // [THEN] Count of Sheets Is 5.
        // [THEN] Sheet '00002': Correct Amount with rounding in Row 030 Column 3 is 10201 (10001+200)
        // [THEN] Correct amount in Row 030 Column 4 is 200 (allowance only).
        VerifyTaxAmountWithAllowance(FANo);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibrarySetupStorage.Save(DATABASE::"FA Setup");
        IsInitialized := true;
    end;

    local procedure CheckCalculateAssessedTax(ReportingPeriod: Integer)
    var
        TaxAuthNo: Code[20];
        StartingDate: Date;
        EndingDate: Date;
        ReportingType: Text;
        TaxAmount: array[3] of Integer;
    begin
        if ReportingPeriod = 3 then
            ReportingType := 'CY'
        else
            ReportingType := 'CQ';
        StartingDate := CalcDate('<-' + ReportingType + '>', WorkDate());
        EndingDate := CalcDate('<' + ReportingType + '>', WorkDate());

        SetupAssessedTax(TaxAuthNo, TaxAmount, StartingDate);

        RunCalculateAssessedTaxReport(TaxAuthNo, ReportingPeriod, StartingDate, EndingDate, 1, true, true);

        VerifyTaxAmount(ReportingPeriod, TaxAmount);
    end;

    local procedure CreateAssessedTaxAllowance(): Code[7]
    var
        AssessedTaxAllowance: Record "Assessed Tax Allowance";
    begin
        AssessedTaxAllowance.Init();
        AssessedTaxAllowance.Code := LibraryUtility.GenerateRandomCode(AssessedTaxAllowance.FieldNo(Code), DATABASE::"Assessed Tax Allowance");
        AssessedTaxAllowance.Name := AssessedTaxAllowance.Code;
        AssessedTaxAllowance.Insert();
        exit(AssessedTaxAllowance.Code);
    end;

    local procedure CreateAssessedTaxCode(var AssessedTaxCode: Record "Assessed Tax Code")
    begin
        AssessedTaxCode.Init();
        AssessedTaxCode.Code := LibraryUtility.GenerateRandomCode(AssessedTaxCode.FieldNo(Code), DATABASE::"Assessed Tax Code");
        AssessedTaxCode.Description := AssessedTaxCode.Code;
        AssessedTaxCode."Region Code" := Format(LibraryRandom.RandInt(99));
        AssessedTaxCode."Rate %" := LibraryRandom.RandInt(10);
        AssessedTaxCode."Decreasing Amount" := AssessedTaxCode."Rate %" / 10;
        AssessedTaxCode."Decreasing Amount Type" := AssessedTaxCode."Decreasing Amount Type"::Percent;
        AssessedTaxCode.Insert();
    end;

    local procedure CreateAssessedTaxCodeWithAllowance(var AssessedTaxCode: Record "Assessed Tax Code")
    begin
        CreateAssessedTaxCode(AssessedTaxCode);
        AssessedTaxCode."Dec. Rate Tax Allowance Code" := CreateAssessedTaxAllowance();
        AssessedTaxCode."Dec. Amount Tax Allowance Code" := CreateAssessedTaxAllowance();
        AssessedTaxCode.Modify();
    end;

    local procedure CreateExemptionAssessedTaxCode(var ExemptionAssessedTaxCode: Record "Assessed Tax Code"; ATCode: Code[20])
    var
        AssessedTaxCode: Record "Assessed Tax Code";
    begin
        AssessedTaxCode.Get(ATCode);
        ExemptionAssessedTaxCode.TransferFields(AssessedTaxCode);
        ExemptionAssessedTaxCode.Code := LibraryUtility.GenerateRandomCode(ExemptionAssessedTaxCode.FieldNo(Code), DATABASE::"Assessed Tax Code");
        ExemptionAssessedTaxCode."Exemption Tax Allowance Code" := CreateAssessedTaxAllowance();
        ExemptionAssessedTaxCode.Insert();
    end;

    local procedure CreateFALocation(var FALocation: Record "FA Location"; OKATOCode: Code[11])
    begin
        FALocation.Code := LibraryUtility.GenerateRandomCode(FALocation.FieldNo(Code), DATABASE::"FA Location");
        FALocation.Name := FALocation.Code;
        FALocation."OKATO Code" := OKATOCode;
        FALocation.Insert();
    end;

    local procedure CreateFALedgerEntry(var TaxAmount: Decimal; FANo: Code[20]; DeprBookCode: Code[10]; PostingDate: Date; FALocationCode: Code[10])
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // Create Acquisition Cost ledger entry
        LibraryTaxAcc.CreateFALedgerEntry(FALedgerEntry, FANo, DeprBookCode, PostingDate);
        UpdateFALedgerEntry(FALedgerEntry, FALedgerEntry."FA Posting Type"::"Acquisition Cost", FALocationCode);
        TaxAmount := FALedgerEntry.Amount;

        // Create Depreciation ledger entry
        LibraryTaxAcc.CreateFALedgerEntry(FALedgerEntry, FANo, DeprBookCode, PostingDate);
        UpdateFALedgerEntry(FALedgerEntry, FALedgerEntry."FA Posting Type"::Depreciation, FALocationCode);
        TaxAmount -= Abs(FALedgerEntry.Amount);
    end;

    local procedure CreateOKATO(var OKATO: Record OKATO; RegionCode: Code[2]; TaxAuthNo: Code[20])
    begin
        OKATO.Init();
        OKATO.Code := LibraryUtility.GenerateRandomCode(OKATO.FieldNo(Code), DATABASE::OKATO);
        OKATO.Name := OKATO.Code;
        OKATO."Region Code" := RegionCode;
        OKATO."Tax Authority No." := TaxAuthNo;
        OKATO.Insert();
    end;

    local procedure CreateTaxAuthority(var Vendor: Record Vendor)
    begin
        Vendor.Init();
        Vendor."No." := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("No."), DATABASE::Vendor);
        Vendor.Name := Vendor."No.";
        Vendor."Vendor Type" := Vendor."Vendor Type"::"Tax Authority";
        Vendor.Insert();
    end;

    local procedure CreateFixedAssetWithRounding(FALocationCode: Code[10]; AssessedTaxCode: Code[20]; OKATOCode: Code[11]; StartingDate: Date): Code[20]
    var
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FASetup.Get();
        FixedAsset.Get(LibraryTaxAcc.CreateFAWithAccFADeprBook());
        FixedAsset."FA Type" := FixedAsset."FA Type"::"Fixed Assets";
        FixedAsset."Property Type" := FixedAsset."Property Type"::"Other Property";
        FixedAsset."FA Location Code" := FALocationCode;
        FixedAsset."OKATO Code" := OKATOCode;
        FixedAsset."Assessed Tax Code" := AssessedTaxCode;
        FixedAsset.Modify();
        CreateFALedgerEntryWithRounding(
          FixedAsset."No.", FASetup."Release Depr. Book", FALocationCode, StartingDate, FALedgerEntry."FA Posting Type"::"Acquisition Cost");
        CreateFALedgerEntryWithRounding(
          FixedAsset."No.", FASetup."Release Depr. Book", FALocationCode, CalcDate('<CM+1M-1D>', StartingDate),
          FALedgerEntry."FA Posting Type"::Depreciation);
        exit(FixedAsset."No.");
    end;

    local procedure CreateFALedgerEntryWithRounding(FANo: Code[20]; DeprBookCode: Code[10]; FALocationCode: Code[10]; PostingDate: Date; FAPostingType: Enum "FA Ledger Entry FA Posting Type")
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        LibraryTaxAcc.CreateFALedgerEntry(FALedgerEntry, FANo, DeprBookCode, PostingDate);
        UpdateFALedgerEntry(FALedgerEntry, FAPostingType, FALocationCode);
        FALedgerEntry."Part of Book Value" := true;
        FALedgerEntry.Modify();
    end;

    local procedure CalcBookValue(QuarterDate: Date) BookValue: Integer
    var
        BookValueText: Text;
        FoundDash: Boolean;
        I: Integer;
        J: Integer;
    begin
        LibraryReportValidation.OpenFile();
        I := 24;
        J := 169 + 2 * Date2DMY(CalcDate('<CQ>', QuarterDate), 2);
        repeat
            BookValueText := BookValueText + LibraryReportValidation.GetValueAtFromWorksheet(J, I, '3');
            FoundDash := (LibraryReportValidation.GetValueAtFromWorksheet(J, I, '3') = '-');
            I := I + 1;
        until FoundDash;
        BookValueText := DelChr(BookValueText, '=', '-');
        Evaluate(BookValue, BookValueText);
        exit(BookValue);
    end;

    local procedure GetAssessedTaxCodeRate(ATCode: Code[20]): Integer
    var
        AssessedTaxCode: Record "Assessed Tax Code";
    begin
        AssessedTaxCode.Get(ATCode);
        exit(AssessedTaxCode."Rate %");
    end;

    local procedure GetFALedgEntryAmount(FANo: Text): Decimal
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FALedgerEntry.SetFilter("FA No.", FANo);
        FALedgerEntry.SetRange("Depreciation Book Code", FASetup."Release Depr. Book");
        FALedgerEntry.SetRange("Part of Book Value", true);
        FALedgerEntry.CalcSums(Amount);
        exit(FALedgerEntry.Amount);
    end;

    local procedure RunCalculateAssessedTaxReport(TaxAuthNo: Code[20]; ReportingPeriod: Integer; StartingDate: Date; EndingDate: Date; Submitted: Integer; Reorganization: Boolean; DetailedInfo: Boolean)
    var
        CalculateAssessedTaxReport: Report "Calculate Assessed Tax";
    begin
        CalculateAssessedTaxReport.InitializeRequest(
          TaxAuthNo, Date2DMY(StartingDate, 3), ReportingPeriod, StartingDate, EndingDate,
          Submitted, Reorganization, DetailedInfo);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        CalculateAssessedTaxReport.SetFileNameSilent(LibraryReportValidation.GetFileName());
        CalculateAssessedTaxReport.UseRequestPage(false);
        CalculateAssessedTaxReport.Run();
    end;

    local procedure SetupAssessedTax(var TaxAuthNo: Code[20]; var TaxAmount: array[3] of Integer; StartingDate: Date)
    var
        AssessedTaxCode: Record "Assessed Tax Code";
        ExemptionAssessedTaxCode: Record "Assessed Tax Code";
        FALocation: Record "FA Location";
        OKATO: Record OKATO;
        Vendor: Record Vendor;
    begin
        UpdateFASetup();
        CreateTaxAuthority(Vendor);
        TaxAuthNo := Vendor."No.";
        CreateAssessedTaxCodeWithAllowance(AssessedTaxCode);
        CreateExemptionAssessedTaxCode(ExemptionAssessedTaxCode, AssessedTaxCode.Code);
        CreateOKATO(OKATO, AssessedTaxCode."Region Code", TaxAuthNo);
        CreateFALocation(FALocation, OKATO.Code);
        SetupFixedAsset(TaxAmount, StartingDate, FALocation.Code, AssessedTaxCode.Code, OKATO.Code);
    end;

    local procedure SetupAssessedTaxWithRounding(var TaxAuthorityNo: Code[20]; var FixedAssetFilter: Text; StartingDate: Date)
    var
        Vendor: Record Vendor;
        AssessedTaxCode: Record "Assessed Tax Code";
        OKATO: Record OKATO;
        FALocation: Record "FA Location";
    begin
        UpdateFASetup();
        CreateTaxAuthority(Vendor);
        TaxAuthorityNo := Vendor."No.";
        CreateAssessedTaxCode(AssessedTaxCode);
        CreateOKATO(OKATO, AssessedTaxCode."Region Code", TaxAuthorityNo);
        CreateFALocation(FALocation, OKATO.Code);
        FixedAssetFilter :=
          StrSubstNo('%1|%2',
            CreateFixedAssetWithRounding(FALocation.Code, AssessedTaxCode.Code, OKATO.Code, StartingDate),
            CreateFixedAssetWithRounding(FALocation.Code, AssessedTaxCode.Code, OKATO.Code, StartingDate));
    end;

    local procedure SetupAssessedTaxWithAllowance(var TaxAuthNo: Code[20]; var TaxAmount: array[2] of Decimal; var FANo: array[2] of Code[20]; StartingDate: Date; Rounding: Boolean)
    var
        AssessedTaxCode: Record "Assessed Tax Code";
        ExemptionAssessedTaxCode: Record "Assessed Tax Code";
        FALocation: Record "FA Location";
        OKATO: Record OKATO;
        Vendor: Record Vendor;
    begin
        UpdateFASetup();
        CreateTaxAuthority(Vendor);
        TaxAuthNo := Vendor."No.";
        CreateAssessedTaxCodeWithAllowance(AssessedTaxCode);
        CreateExemptionAssessedTaxCode(ExemptionAssessedTaxCode, AssessedTaxCode.Code);
        CreateOKATO(OKATO, AssessedTaxCode."Region Code", TaxAuthNo);
        CreateFALocation(FALocation, OKATO.Code);
        SetupFixedAssetOtherProperty(
          TaxAmount[1], FANo[1], StartingDate, FALocation.Code, AssessedTaxCode.Code, OKATO.Code, Rounding);
        SetupFixedAssetOtherProperty(
          TaxAmount[2], FANo[2], StartingDate, FALocation.Code, ExemptionAssessedTaxCode.Code, OKATO.Code, Rounding);
    end;

    local procedure SetupFixedAsset(var TaxAmount: array[3] of Integer; StartingDate: Date; FALocationCode: Code[10]; AssessedTaxCode: Code[20]; OKATOCode: Code[11])
    var
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
        PostingDate: Date;
        TaxAmountDec: array[3] of Decimal;
        I: Integer;
    begin
        FASetup.Get();
        PostingDate := CalcDate('<-1D>', StartingDate);
        for I := 1 to 3 do begin
            CreateFixedAsset(FixedAsset, I);
            FixedAsset."FA Location Code" := FALocationCode;
            FixedAsset."Assessed Tax Code" := AssessedTaxCode;
            FixedAsset."OKATO Code" := OKATOCode;
            FixedAsset.Modify();
            CreateFALedgerEntry(TaxAmountDec[I], FixedAsset."No.", FASetup."Release Depr. Book", PostingDate, FALocationCode);
            TaxAmount[I] := Round(TaxAmountDec[I] / 100 * GetAssessedTaxCodeRate(AssessedTaxCode), 1);
        end;
    end;

    local procedure SetupFixedAssetOtherProperty(var TaxAmount: Decimal; var FANo: Code[20]; StartingDate: Date; FALocationCode: Code[10]; AssessedTaxCode: Code[20]; OKATOCode: Code[11]; Rounding: Boolean)
    var
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
        PostingDate: Date;
    begin
        FASetup.Get();
        PostingDate := CalcDate('<-1D>', StartingDate);
        CreateFixedAsset(FixedAsset, FixedAsset."Property Type"::"Other Property");
        FixedAsset."FA Location Code" := FALocationCode;
        FixedAsset."Assessed Tax Code" := AssessedTaxCode;
        FixedAsset."OKATO Code" := OKATOCode;
        FixedAsset.Modify();
        CreateFALedgerEntry(TaxAmount, FixedAsset."No.", FASetup."Release Depr. Book", PostingDate, FALocationCode);
        TaxAmount := TaxAmount / 100 * GetAssessedTaxCodeRate(AssessedTaxCode);
        if Rounding then
            TaxAmount := Round(TaxAmount, 1);
        FANo := FixedAsset."No.";
    end;

    local procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset"; PropertyType: Integer)
    begin
        FixedAsset.Get(LibraryTaxAcc.CreateFAWithAccFADeprBook());
        FixedAsset."FA Type" := FixedAsset."FA Type"::"Fixed Assets";
        FixedAsset."Property Type" := PropertyType;
        FixedAsset."Tax Amount Paid Abroad" := LibraryRandom.RandInt(10);
        FixedAsset."Book Value per Share" := 1;
        FixedAsset.Modify();
    end;

    local procedure UpdateFASetup()
    var
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
    begin
        LibraryTaxAcc.CreateAccDeprBook(DeprBook);

        FASetup.Get();
        FASetup.Validate("Release Depr. Book", DeprBook.Code);
        FASetup.Modify(true);
    end;

    local procedure UpdateFALedgerEntry(var FALedgerEntry: Record "FA Ledger Entry"; FAPostingType: Enum "FA Ledger Entry FA Posting Type"; FALocationCode: Code[10])
    begin
        FALedgerEntry."FA Posting Type" := FAPostingType;
        FALedgerEntry."FA Location Code" := FALocationCode;
        FALedgerEntry."Part of Book Value" := true;
        case FALedgerEntry."FA Posting Type" of
            FALedgerEntry."FA Posting Type"::"Acquisition Cost":
                begin
                    FALedgerEntry.Amount := LibraryRandom.RandDecInRange(100, 1000, 2);
                    FALedgerEntry."Debit Amount" := FALedgerEntry.Amount;
                end;
            FALedgerEntry."FA Posting Type"::Depreciation:
                begin
                    FALedgerEntry.Amount := LibraryRandom.RandDecInRange(1, 100, 2);
                    FALedgerEntry."Credit Amount" := FALedgerEntry.Amount;
                    FALedgerEntry.Amount := -FALedgerEntry.Amount;
                end;
        end;
        FALedgerEntry.Modify();
    end;

    local procedure VerifyTaxAmount(ReportingPeriod: Integer; TaxAmount: array[3] of Integer)
    var
        RowNo: Integer;
    begin
        if ReportingPeriod <> 3 then begin
            TaxAmount[1] := Round(TaxAmount[1] / 4, 1);
            RowNo := 210;
        end else
            RowNo := 211;
        VerifyExcelValue(TaxAmount[1], RowNo, 58);
    end;

    local procedure VerifyTaxAmountWithAllowance(FANo: array[2] of Code[20])
    var
        TaxAmount: array[2] of Integer;
    begin
        Assert.AreEqual(LibraryReportValidation.CountWorksheets(), 5, 'Count of Sheets Is incorrect');
        TaxAmount[1] := Round(GetFALedgEntryAmount(FANo[1]), 1);
        TaxAmount[2] := Round(GetFALedgEntryAmount(FANo[2]), 1);
        VerifyExcelValue(TaxAmount[1] + TaxAmount[2], 171, 24);
        VerifyExcelValue(TaxAmount[2], 171, 73);
    end;

    local procedure VerifyCalculateAssessedTaxBookValueAmount(FixedAssetFilter: Text; QuarterDate: Date)
    var
        FALedgEntryAmount: Decimal;
    begin
        FALedgEntryAmount := GetFALedgEntryAmount(FixedAssetFilter);
        Assert.AreEqual(CalcBookValue(QuarterDate), Round(FALedgEntryAmount, 1), 'Book Value Amount incorrect');
    end;

    local procedure VerifyExcelValue(Value: Integer; RowNo: Integer; StartColumnNo: Integer)
    var
        ValueText: Text;
        ColumnNo: Integer;
        I: Integer;
    begin
        ValueText := Format(Value);
        ColumnNo := StartColumnNo;
        for I := 1 to StrLen(ValueText) do begin
            LibraryReportValidation.VerifyCellValue(RowNo, ColumnNo, CopyStr(ValueText, I, 1));
            ColumnNo += 3;
        end;
        // validate that value in excel is integer - next symbol is fill character, not '.'.
        LibraryReportValidation.VerifyCellValue(RowNo, ColumnNo, '-');
    end;
}

