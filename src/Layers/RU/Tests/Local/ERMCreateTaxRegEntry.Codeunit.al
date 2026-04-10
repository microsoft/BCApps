codeunit 144516 "ERM Create Tax Reg. Entry"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;
    Permissions = tabledata "FA Ledger Entry" = imd;

    var
        Assert: Codeunit Assert;
        LibraryTaxAcc: Codeunit "Library - Tax Accounting";
        TaxRegAccumErr: Label 'Wrong Tax Register Accumulation amount.';
        TaxRegEntryErr: Label 'Wrong %1 number of entries.';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TaxRegisterFAEntry()
    begin
        // test run Create Tax Register FA Entry report,
        // checks for Tax Register Accumulation amounts and Tax Register FA Entry entries
        CheckTaxRegisterFAEntry();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TaxRegisterFEEntry()
    begin
        // test run Create Tax Register FE Entry report,
        // checks for Tax Register Accumulation amounts and Tax Register FE Entry entries
        CheckTaxRegisterFEEntry();
    end;

    local procedure CheckTaxRegisterFAEntry()
    var
        TaxRegTemplate: Record "Tax Register Template";
        SumFieldNoArray: array[10] of Integer;
        I: Integer;
    begin
        CreateFASumFieldNoArray(SumFieldNoArray);
        for I := 1 to ArrayLen(SumFieldNoArray) do begin
            UpdateTaxRegSetupFA();
            SetupTaxRegisterFA(TaxRegTemplate, SumFieldNoArray[I]);

            CreateTaxRegisterFAEntry(TaxRegTemplate."Section Code", WorkDate());

            VerifyTaxRegisterFAEntry(TaxRegTemplate);
        end;
    end;

    local procedure CheckTaxRegisterFEEntry()
    var
        TaxRegTemplate: Record "Tax Register Template";
        SumFieldNoArray: array[3] of Integer;
        I: Integer;
    begin
        CreateFESumFieldNoArray(SumFieldNoArray);
        for I := 1 to ArrayLen(SumFieldNoArray) do begin
            UpdateTaxRegSetupFE();
            SetupTaxRegisterFE(TaxRegTemplate, SumFieldNoArray[I]);

            CreateTaxRegisterFEEntry(TaxRegTemplate."Section Code", WorkDate());

            VerifyTaxRegisterFEEntry(TaxRegTemplate);
        end;
    end;

    local procedure CreateFALedgerEntryFA(FANo: Code[20]; DeprBookCode: Code[10]; PostingDate: Date; SumFieldNo: Integer)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        LibraryTaxAcc.CreateFALedgerEntry(FALedgerEntry, FANo, DeprBookCode, PostingDate);
        FALedgerEntry."Belonging to Manufacturing" := FALedgerEntry."Belonging to Manufacturing"::Production;
        FALedgerEntry."FA Type" := FALedgerEntry."FA Type"::"Fixed Assets";
        FALedgerEntry.Amount := SumFieldNo;
        case SumFieldNo of
            61:
                FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::"Acquisition Cost";
            62:
                FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::"Write-Down";
            72:
                begin
                    FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::Depreciation;
                    FALedgerEntry."Depr. Bonus" := false;
                end;
            86:
                begin
                    FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::"Gain/Loss";
                    FALedgerEntry."Depr. Group Elimination" := false;
                end;
            85:
                FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::"Proceeds on Disposal";
            91:
                begin
                    FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::"Gain/Loss";
                    FALedgerEntry."Depr. Group Elimination" := true;
                end;
            92:
                begin
                    FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::Depreciation;
                    FALedgerEntry."Depr. Bonus" := true;
                    FALedgerEntry."Depr. Bonus %" := SumFieldNo;
                end;
            93:
                begin
                    FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::Depreciation;
                    FALedgerEntry."Depr. Bonus" := true;
                    FALedgerEntry."Depr. Bonus Recovery Date" := PostingDate;
                end;
            94:
                begin
                    FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::"Gain/Loss";
                    FALedgerEntry."Result on Disposal" := FALedgerEntry."Result on Disposal"::Gain;
                    FALedgerEntry."Sales Gain Amount" := SumFieldNo;
                end;
            95:
                begin
                    FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::"Acquisition Cost";
                    FALedgerEntry."Reclassification Entry" := true;
                    FALedgerEntry.Quantity := 1;
                end;
        end;
        FALedgerEntry.Modify();
    end;

    local procedure CreateFALedgerEntryFE(FANo: Code[20]; DeprBookCode: Code[10]; PostingDate: Date; SumFieldNo: Integer)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        LibraryTaxAcc.CreateFALedgerEntry(FALedgerEntry, FANo, DeprBookCode, PostingDate);
        FALedgerEntry.Amount := SumFieldNo;
        case SumFieldNo of
            61:
                FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::"Acquisition Cost";
            62:
                FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::"Write-Down";
            72:
                FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::Depreciation;
        end;
        FALedgerEntry.Modify();
    end;

    local procedure CreateFASumFieldNoArray(var SumFieldNoArray: array[10] of Integer)
    begin
        SumFieldNoArray[1] := 61;
        SumFieldNoArray[2] := 62;
        SumFieldNoArray[3] := 72;
        SumFieldNoArray[4] := 86;
        SumFieldNoArray[5] := 85;
        SumFieldNoArray[6] := 91;
        SumFieldNoArray[7] := 92;
        SumFieldNoArray[8] := 93;
        SumFieldNoArray[9] := 94;
        SumFieldNoArray[10] := 95;
    end;

    local procedure CreateFESumFieldNoArray(var SumFieldNoArray: array[3] of Integer)
    begin
        SumFieldNoArray[1] := 61;
        SumFieldNoArray[2] := 62;
        SumFieldNoArray[3] := 72;
    end;

    local procedure CreateTaxRegisterFAEntry(TaxRegSectionCode: Code[10]; TaxRegDate: Date)
    var
        CreateTaxRegisterFAEntry: Codeunit "Create Tax Register FA Entry";
    begin
        CreateTaxRegisterFAEntry.CreateRegister(
          TaxRegSectionCode, CalcDate('<-CM>', TaxRegDate), CalcDate('<CM>', TaxRegDate));
    end;

    local procedure CreateTaxRegisterFEEntry(TaxRegSectionCode: Code[10]; TaxRegDate: Date)
    var
        CreateTaxRegisterFEEntry: Codeunit "Create Tax Register FE Entry";
    begin
        CreateTaxRegisterFEEntry.CreateRegister(
          TaxRegSectionCode, CalcDate('<-CM>', TaxRegDate), CalcDate('<CM>', TaxRegDate));
    end;

    local procedure GetTaxRegAccum(var TaxRegAccum: Record "Tax Register Accumulation"; var TaxRegTemplate: Record "Tax Register Template")
    begin
        TaxRegAccum.SetRange("Section Code", TaxRegTemplate."Section Code");
        TaxRegAccum.SetRange("Tax Register No.", TaxRegTemplate.Code);
        TaxRegAccum.SetRange("Template Line Code", TaxRegTemplate."Line Code");
        TaxRegAccum.FindFirst();
    end;

    local procedure SetupTaxRegister(var TaxRegTemplate: Record "Tax Register Template"; TableId: Integer)
    var
        TaxReg: Record "Tax Register";
        TaxRegSection: Record "Tax Register Section";
    begin
        LibraryTaxAcc.CreateTaxRegSection(TaxRegSection);
        LibraryTaxAcc.CreateTaxReg(TaxReg, TaxRegSection.Code, TableId, TaxReg."Storing Method"::"Build Entry");
        LibraryTaxAcc.CreateTaxRegTemplate(TaxRegTemplate, TaxRegSection.Code, TaxReg."No.");
    end;

    local procedure SetupTaxRegisterFA(var TaxRegTemplate: Record "Tax Register Template"; SumFieldNo: Integer)
    var
        TaxRegSetup: Record "Tax Register Setup";
    begin
        TaxRegSetup.Get();
        SetupTaxRegister(TaxRegTemplate, DATABASE::"Tax Register FA Entry");
        UpdateTaxRegTemplateFA(TaxRegTemplate, SumFieldNo, TaxRegSetup."Tax Depreciation Book");
        CreateFALedgerEntryFA(
          LibraryTaxAcc.CreateFAWithTaxFADeprBook(), TaxRegSetup."Tax Depreciation Book", WorkDate(), SumFieldNo);
    end;

    local procedure SetupTaxRegisterFE(var TaxRegTemplate: Record "Tax Register Template"; SumFieldNo: Integer)
    var
        TaxRegSetup: Record "Tax Register Setup";
    begin
        TaxRegSetup.Get();
        SetupTaxRegister(TaxRegTemplate, DATABASE::"Tax Register FE Entry");
        UpdateTaxRegTemplateFE(TaxRegTemplate, SumFieldNo, TaxRegSetup."Future Exp. Depreciation Book");
        CreateFALedgerEntryFE(
          LibraryTaxAcc.CreateFEWithTaxFADeprBook(), TaxRegSetup."Future Exp. Depreciation Book", WorkDate(), SumFieldNo);
    end;

    local procedure UpdateTaxRegSetupFA()
    var
        DeprBook: Record "Depreciation Book";
        TaxRegSetup: Record "Tax Register Setup";
    begin
        LibraryTaxAcc.CreateTaxAccDeprBook(DeprBook);
        TaxRegSetup.Get();
        TaxRegSetup.Validate("Tax Depreciation Book", DeprBook.Code);
        TaxRegSetup.Validate("Create Data for Printing Forms", true);
        TaxRegSetup.Modify(true);
    end;

    local procedure UpdateTaxRegSetupFE()
    var
        DeprBook: Record "Depreciation Book";
        TaxRegSetup: Record "Tax Register Setup";
    begin
        LibraryTaxAcc.CreateTaxAccDeprBook(DeprBook);
        TaxRegSetup.Get();
        TaxRegSetup.Validate("Future Exp. Depreciation Book", DeprBook.Code);
        TaxRegSetup.Modify(true);
    end;

    local procedure UpdateTaxRegTemplateFA(var TaxRegTemplate: Record "Tax Register Template"; SumFieldNo: Integer; DeprBookCode: Code[10])
    begin
        TaxRegTemplate.Validate("Expression Type", TaxRegTemplate."Expression Type"::SumField);
        TaxRegTemplate.Validate("Belonging to Manufacturing", TaxRegTemplate."Belonging to Manufacturing"::Production);
        TaxRegTemplate.Validate("FA Type", TaxRegTemplate."FA Type"::"Fixed Assets");
        TaxRegTemplate.Validate("Depr. Book Filter", DeprBookCode);
        TaxRegTemplate.Validate(Period, 'CP..ED');
        TaxRegTemplate.Validate("Sum Field No.", SumFieldNo);
        TaxRegTemplate.Expression := Format(SumFieldNo);
        case SumFieldNo of
            92:
                TaxRegTemplate.Validate("Depr. Bonus % Filter", Format(SumFieldNo));
            94:
                TaxRegTemplate.Validate("Result on Disposal", TaxRegTemplate."Result on Disposal"::Gain);
        end;
        TaxRegTemplate.Modify(true);
    end;

    local procedure UpdateTaxRegTemplateFE(var TaxRegTemplate: Record "Tax Register Template"; SumFieldNo: Integer; DeprBookCode: Code[10])
    begin
        TaxRegTemplate.Validate("Expression Type", TaxRegTemplate."Expression Type"::SumField);
        TaxRegTemplate.Validate("Depr. Book Filter", DeprBookCode);
        TaxRegTemplate.Validate(Period, 'CP..ED');
        TaxRegTemplate.Validate("Sum Field No.", SumFieldNo);
        TaxRegTemplate.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure VerifyTaxRegisterFAEntry(var TaxRegTemplate: Record "Tax Register Template")
    var
        TaxRegAccum: Record "Tax Register Accumulation";
        TaxRegFAEntry: Record "Tax Register FA Entry";
    begin
        GetTaxRegAccum(TaxRegAccum, TaxRegTemplate);
        if TaxRegTemplate."Sum Field No." = 94 then
            Assert.AreEqual(1, Abs(TaxRegAccum.Amount), TaxRegAccumErr)
        else
            Assert.AreEqual(TaxRegTemplate."Sum Field No.", Abs(TaxRegAccum.Amount), TaxRegAccumErr);

        TaxRegFAEntry.SetRange("Section Code", TaxRegTemplate."Section Code");
        Assert.AreEqual(1, TaxRegFAEntry.Count, StrSubstNo(TaxRegEntryErr, TaxRegFAEntry.TableCaption()));
    end;

    local procedure VerifyTaxRegisterFEEntry(var TaxRegTemplate: Record "Tax Register Template")
    var
        TaxRegAccum: Record "Tax Register Accumulation";
        TaxRegFEEntry: Record "Tax Register FE Entry";
    begin
        GetTaxRegAccum(TaxRegAccum, TaxRegTemplate);
        Assert.AreEqual(TaxRegTemplate."Sum Field No.", Abs(TaxRegAccum.Amount), TaxRegAccumErr);

        TaxRegFEEntry.SetRange("Section Code", TaxRegTemplate."Section Code");
        Assert.AreEqual(1, TaxRegFEEntry.Count, StrSubstNo(TaxRegEntryErr, TaxRegFEEntry.TableCaption()));
    end;
}

