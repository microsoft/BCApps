codeunit 163414 "Create Tax Diff. Data"
{

    trigger OnRun()
    begin
    end;

    var
        GLAccount: Record "G/L Account";
        PostInventoryCostToGL: Report "Post Inventory Cost to G/L";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        FAJnlPostLine: Codeunit "FA Jnl.-Post Line";
        SalesPost: Codeunit "Sales-Post";
        PurchPost: Codeunit "Purch.-Post";
        InvtAdjmt: Codeunit "Inventory Adjustment";
        FA: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
        CorrespManagement: Codeunit "G/L Corresp. Management";
        XEX01: Label 'EX-01';
        XFUTEXNOINT: Label 'FUTEXNOINT';
        XReleasetoOperation: Label 'Release to Operation';
        XTAXACC: Label 'TAXACC';
        XOPERATION: Label 'OPERATION';
        XTELEPHONE: Label 'TELEPHONE';
        XFADisposal: Label 'FA Disposal';
        XFASales: Label 'FA Sales';
        XREPREXP: Label 'REPREXP';
        XONEYEAR: Label 'ONEYEAR';
        MakeAdjustments: Codeunit "Make Adjustments";
        XAdvertisingExpenses: Label 'Advertising Expenses';
        XAdvert: Label 'Advert-';
        XRESALE00: Label 'RESALE00';
        XRETAIL: Label 'RETAIL';
        XNOTAXACC: Label 'NOTAXACC';
        XNoTaxPosting: Label 'No Tax Posting';
        XFA02: Label 'FA-02';
        XFASoldwithloss: Label 'FA Sold with Loss';
        XFANotusedforprofit: Label 'FA Not Used for Profit';
        XFE01: Label 'FE-01';
        XFE02: Label 'FE-02';
        XEX02: Label 'EX-02';
        XEX03: Label 'EX-03';
        XFE031: Label 'FE-03-1';
        XFE032: Label 'FE-03-2';
        XVoluntarilyMedicalInsurance: Label 'Voluntarily Medical Insurance';
        XMonthlyDepreciation: Label 'Monthly Depreciation';
        X12Months: Label '12 Months';
        XFE06: Label 'FE-06';
        XFA05: Label 'FA-05';
        XDifferentDeprTaxAcc: Label 'Different Depr. for Tax Acc.';
        XFAReceivedfreeofcharge: Label 'FA Received free of charge';
        XEX06: Label 'EX-06';
        XACT: Label 'ACT';
        XDEPR: Label 'DEPR';
        XDepreciation: Label 'Depreciation';
        XDISP: Label 'DISP';
        XSALE: Label 'SALE';
        XFETAX: Label 'FETAX';

    procedure Example1()
    var
        FANo: Code[20];
    begin
        FANo := XFE01;
        DeleteFA(FANo);

        AcquisitionFA(FANo,
          XFANotusedforprofit, FA."FA Type"::"Future Expense",
          XFUTEXNOINT, '', '', 19030101D, '', 150000, XEX01);

        MakeFADeprBook(FANo, XFUTEXNOINT, 3 * 12, 19030201D, FADeprBook."Depreciation Method"::"Straight-Line");
    end;

    procedure Example2()
    var
        FANo: Code[20];
    begin
        FANo := XFA02;
        DeleteFA(FANo);

        AcquisitionFA(FANo, XFASoldwithloss, FA."FA Type"::"Fixed Assets",
          XOPERATION, XTELEPHONE, XTAXACC, 19021231D, MakeAdjustments.Convert('9901200'), 120000, '');

        DepreciationFA(FANo, XOPERATION, 19030131D, MakeAdjustments.Convert('9926420'), 60000);
        DepreciationFA(FANo, XTAXACC, 19030131D, '', 60000);

        DisposalFA(FANo, XOPERATION, 19030131D);
        DisposalFA(FANo, XTAXACC, 19030131D);

        SellFA(FANo, XOPERATION, 19030131D, MakeAdjustments.Convert('9976600'), 50000);

        FANo := XFE02;
        DeleteFA(FANo);

        AcquisitionFA(FANo,
          XFASoldwithloss, FA."FA Type"::"Future Expense",
          XFUTEXNOINT, '', XFETAX, 19030131D, '', 10000, XEX02);

        MakeFADeprBook(FANo, XFUTEXNOINT, 1, 19030131D, FADeprBook."Depreciation Method"::"Straight-Line");
        MakeFADeprBook(FANo, XFETAX, 2 * 12, 19030201D, FADeprBook."Depreciation Method"::"Straight-Line");
    end;

    procedure Example3()
    var
        FANo: Code[20];
    begin
        FANo := XFE031;
        DeleteFA(FANo);

        AcquisitionFA(FANo, XVoluntarilyMedicalInsurance, FA."FA Type"::"Future Expense",
          XFUTEXNOINT, '', XFETAX, 19031231D, '', 6000, XEX03);

        MakeFADeprBook(FANo, XFUTEXNOINT, 1, 19030101D, FADeprBook."Depreciation Method"::"Straight-Line");
        MakeTableFADeprBook(FANo, XFETAX, XFE031, X12Months,
          19030111D, 12, 20, 30);

        FANo := XFE032;
        DeleteFA(FANo);

        AcquisitionFA(FANo, XVoluntarilyMedicalInsurance, FA."FA Type"::"Future Expense",
          XFUTEXNOINT, '', XFETAX, 19031231D, '', 14000, XEX03);

        MakeFADeprBook(FANo, XFUTEXNOINT, 1, 19030101D, FADeprBook."Depreciation Method"::"Straight-Line");
        MakeTableFADeprBook(FANo, XFETAX, XONEYEAR, XMonthlyDepreciation,
          19030101D, 12, 30, 30);
    end;

    procedure Example4()
    var
        GLEntry: Record "G/L Entry";
        GLCorrespondenceEntry: Record "G/L Correspondence Entry";
        GenJnlLine: Record "Gen. Journal Line";
        AccountNo: Code[20];
        BalAccountNo: Code[20];
        PostingDate: Date;
        Amount: Decimal;
    begin
        GLEntry.SetFilter("Document No.", XAdvert + '04-0' + '*');
        GLEntry.DeleteAll();
        GLCorrespondenceEntry.SetFilter("Document No.", XAdvert + '04-0' + '*');
        GLCorrespondenceEntry.DeleteAll();

        GLEntry.Reset();
        GLEntry.SetCurrentKey("Transaction No.");
        GLCorrespondenceEntry.Reset();
        if GLCorrespondenceEntry.FindLast() then
            GLEntry.SetFilter("Transaction No.", '>%1', GLCorrespondenceEntry."Transaction No.");

        AccountNo := MakeAdjustments.Convert('9944832');
        BalAccountNo := MakeAdjustments.Convert('9950200');
        PostingDate := MakeAdjustments.AdjustDate(19030120D);
        Amount := 210000;

        GenJnlLine.Init();
        GenJnlLine."Document No." := XAdvert + '04-01';
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine.Validate("Account No.", AccountNo);
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
        GenJnlLine.Validate("Bal. Account No.", BalAccountNo);
        GenJnlLine.Description := XAdvertisingExpenses;
        GenJnlLine.Validate(Amount, Abs(Amount));

        GenJnlPostLine.Run(GenJnlLine);
        Clear(GenJnlPostLine);

        PostingDate := MakeAdjustments.AdjustDate(19030212D);
        Amount := 70000;

        GenJnlLine.Init();
        GenJnlLine."Document No." := XAdvert + '04-02';
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine.Validate("Account No.", AccountNo);
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
        GenJnlLine.Validate("Bal. Account No.", BalAccountNo);
        GenJnlLine.Description := XAdvertisingExpenses;
        GenJnlLine.Validate(Amount, Abs(Amount));

        GenJnlPostLine.Run(GenJnlLine);
        Clear(GenJnlPostLine);

        PostingDate := MakeAdjustments.AdjustDate(19030316D);
        Amount := 20000;

        GenJnlLine.Init();
        GenJnlLine."Document No." := XAdvert + '04-03';
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine.Validate("Account No.", AccountNo);
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
        GenJnlLine.Validate("Bal. Account No.", BalAccountNo);
        GenJnlLine.Description := XAdvertisingExpenses;
        GenJnlLine.Validate(Amount, Abs(Amount));

        GenJnlPostLine.Run(GenJnlLine);
        Clear(GenJnlPostLine);

        CorrespManagement.CreateCorrespEntries(GLEntry);
    end;

    procedure Example5()
    var
        FANo: Code[20];
    begin
        FANo := XFA05;
        DeleteFA(FANo);

        AcquisitionFA(FANo, XDifferentDeprTaxAcc, FA."FA Type"::"Fixed Assets",
          XOPERATION, XTELEPHONE, XTAXACC, 19031231D, MakeAdjustments.Convert('9901200'), 120000, '');

        MakeFADeprBook(FANo, XOPERATION, 12, 19030101D, FADeprBook."Depreciation Method"::"SL-RU");
        MakeFADeprBook(FANo, XTAXACC, 12, 19030101D, FADeprBook."Depreciation Method"::"DB/SL-RU");
    end;

    procedure Example6()
    var
        FANo: Code[20];
    begin
        FANo := XFE06;
        DeleteFA(FANo);

        AcquisitionFA(FANo, XFAReceivedfreeofcharge, FA."FA Type"::"Future Expense",
          XFUTEXNOINT, '', XFETAX, 19030101D, '', 120000, XEX06);

        MakeFADeprBook(FANo, XFUTEXNOINT, 1, 19030101D, FADeprBook."Depreciation Method"::"Straight-Line");
        MakeFADeprBook(FANo, XFETAX, 4 * 12, 19030201D, FADeprBook."Depreciation Method"::"Straight-Line");
    end;

    procedure Example7()
    var
        GLEntry: Record "G/L Entry";
        GLCorrespondenceEntry: Record "G/L Correspondence Entry";
        GenJnlLine: Record "Gen. Journal Line";
        AccountNo: Code[20];
        BalAccountNo: Code[20];
        PostingDate: Date;
        Amount: Decimal;
    begin
        GLEntry.SetFilter("Document No.", XREPREXP + '04-0' + '*');
        GLEntry.DeleteAll();
        GLCorrespondenceEntry.SetFilter("Document No.", XREPREXP + '04-0' + '*');
        GLCorrespondenceEntry.DeleteAll();

        GLEntry.Reset();
        GLEntry.SetCurrentKey("Transaction No.");
        GLCorrespondenceEntry.Reset();
        if GLCorrespondenceEntry.FindLast() then
            GLEntry.SetFilter("Transaction No.", '>%1', GLCorrespondenceEntry."Transaction No.");

        AccountNo := MakeAdjustments.Convert('9944820');
        BalAccountNo := MakeAdjustments.Convert('9950200');

        PostingDate := MakeAdjustments.AdjustDate(19030110D);
        Amount := 1900; // Norm 1945

        GenJnlLine.Init();
        GenJnlLine."Document No." := XREPREXP + '04-01';
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine.Validate("Account No.", AccountNo);
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
        GenJnlLine.Validate("Bal. Account No.", BalAccountNo);
        GenJnlLine.Description := XAdvertisingExpenses;
        GenJnlLine.Validate(Amount, Abs(Amount));

        GenJnlPostLine.Run(GenJnlLine);
        Clear(GenJnlPostLine);

        PostingDate := MakeAdjustments.AdjustDate(19030221D);
        Amount := 2100; // Norm 3945 - 1900 = 2045

        GenJnlLine.Init();
        GenJnlLine."Document No." := XREPREXP + '04-02';
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine.Validate("Account No.", AccountNo);
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
        GenJnlLine.Validate("Bal. Account No.", BalAccountNo);
        GenJnlLine.Description := XAdvertisingExpenses;
        GenJnlLine.Validate(Amount, Abs(Amount));

        GenJnlPostLine.Run(GenJnlLine);
        Clear(GenJnlPostLine);

        PostingDate := MakeAdjustments.AdjustDate(19030325D);
        Amount := 1945; // Norm 5945 - (1900 + 2100) = 1945

        GenJnlLine.Init();
        GenJnlLine."Document No." := XREPREXP + '04-03';
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine.Validate("Account No.", AccountNo);
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
        GenJnlLine.Validate("Bal. Account No.", BalAccountNo);
        GenJnlLine.Description := XAdvertisingExpenses;
        GenJnlLine.Validate(Amount, Abs(Amount));

        GenJnlPostLine.Run(GenJnlLine);
        Clear(GenJnlPostLine);

        CorrespManagement.CreateCorrespEntries(GLEntry);
    end;

    procedure DeleteFA(FANo: Code[20])
    var
        FixedAsset: Record "Fixed Asset";
        FALedgerEntry: Record "FA Ledger Entry";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        TaxDiffLedgEntry: Record "Tax Diff. Ledger Entry";
        TaxCalcSection: Record "Tax Calc. Section";
        TaxCalcFAEntry: Record "Tax Calc. FA Entry";
    begin
        TaxCalcFAEntry.SetRange("FA No.", FANo);
        if TaxCalcFAEntry.FindFirst() then
            TaxCalcSection.SectionReset();
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.DeleteAll();
        FADepreciationBook.SetRange("FA No.", FANo);
        FADepreciationBook.DeleteAll();
        FAJournalLine.SetRange("FA No.", FANo);
        FAJournalLine.DeleteAll();
        TaxDiffJnlLine.SetRange("Source No.", FANo);
        TaxDiffJnlLine.DeleteAll();
        TaxDiffLedgEntry.SetRange("Source No.", FANo);
        TaxDiffLedgEntry.DeleteAll();
        if FixedAsset.Get(FANo) then
            FixedAsset.Delete();
    end;

    procedure AcquisitionFA(FANo: Code[20]; FADescription: Text[30]; FAType: Integer; DeprCodeBase: Code[10]; FAPostingGroupBase: Code[10]; DeprCodeTax: Code[10]; PostingDate: Date; BalAccountNo: Code[20]; Amount: Decimal; TaxDiffCode: Code[10])
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJnlLine: Record "Gen. Journal Line";
        FAJnlLine: Record "FA Journal Line";
        DepreciationBook: Record "Depreciation Book";
    begin
        FixedAsset."No." := FANo;
        FixedAsset.Init();
        FixedAsset.Insert(true);
        FixedAsset.Validate(Description, FADescription);
        FixedAsset.Validate("FA Type", FAType);
        FixedAsset."Tax Difference Code" := TaxDiffCode;
        FixedAsset.Modify();

        FADepreciationBook.SetRange("FA No.", FANo);
        FADepreciationBook.DeleteAll();

        if DeprCodeTax <> '' then begin
            FADepreciationBook.Init();
            FADepreciationBook."FA No." := FANo;
            FADepreciationBook."Depreciation Book Code" := DeprCodeTax;
            FADepreciationBook.Insert(true);
        end;

        if DeprCodeBase <> '' then begin
            FADepreciationBook.Init();
            FADepreciationBook."FA No." := FixedAsset."No.";
            FADepreciationBook."Depreciation Book Code" := DeprCodeBase;
            FADepreciationBook.Insert(true);

            DepreciationBook.Get(DeprCodeBase);
            if DepreciationBook."G/L Integration - Acq. Cost" then begin
                FADepreciationBook."FA Posting Group" := FAPostingGroupBase;
                FADepreciationBook.Modify();
                GenJnlLine.Init();
                GenJnlLine."Document No." := XACT + FixedAsset."No.";
                GenJnlLine.Validate("Posting Date", MakeAdjustments.AdjustDate(PostingDate));
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Fixed Asset";
                GenJnlLine.Validate("Account No.", FixedAsset."No.");
                GenJnlLine.Description := StrSubstNo(XReleasetoOperation + ' %1', FixedAsset."FA Type");
                GenJnlLine.Validate("FA Posting Type", GenJnlLine."FA Posting Type"::"Acquisition Cost");
                GenJnlLine.Validate("Depreciation Book Code", DeprCodeBase);
                GenJnlLine.Validate(Amount, Abs(Amount));

                GenJnlPostLine.Run(GenJnlLine);

                GenJnlLine.Init();
                GenJnlLine."Document No." := XACT + FixedAsset."No.";
                GenJnlLine.Validate("Posting Date", MakeAdjustments.AdjustDate(PostingDate));
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                GenJnlLine.Validate("Account No.", BalAccountNo);
                GenJnlLine.Description := StrSubstNo(XReleasetoOperation + ' %1', FixedAsset."FA Type");
                GenJnlLine.Validate(Amount, -Abs(Amount));
                GenJnlLine."FA Reclassification Entry" := true;
                GenJnlLine."Gen. Prod. Posting Group" := '';
                GenJnlLine."VAT Prod. Posting Group" := '';

                GenJnlPostLine.Run(GenJnlLine);
                Clear(GenJnlPostLine);
            end else begin
                FAJnlLine.Init();
                FAJnlLine."Document No." := XACT + FixedAsset."No.";
                FAJnlLine.Validate("FA Posting Date", MakeAdjustments.AdjustDate(PostingDate));
                FAJnlLine.Validate("FA No.", FixedAsset."No.");
                FAJnlLine.Validate("Depreciation Book Code", DeprCodeBase);
                FAJnlLine.Validate("FA Posting Type", FAJnlLine."FA Posting Type"::"Acquisition Cost");
                FAJnlLine.Description := StrSubstNo(XReleasetoOperation + ' %1', FixedAsset."FA Type");
                FAJnlLine.Validate(Amount, Abs(Amount));
                FAJnlLine."FA Reclassification Entry" := true;

                FAJnlPostLine.FAJnlPostLine(FAJnlLine, true);
                Clear(FAJnlPostLine);
            end;
        end;

        if DeprCodeTax <> '' then begin
            FAJnlLine.Init();
            FAJnlLine."Document No." := XACT + FixedAsset."No.";
            FAJnlLine.Validate("FA Posting Date", MakeAdjustments.AdjustDate(PostingDate));
            FAJnlLine.Validate("FA No.", FixedAsset."No.");
            FAJnlLine.Validate("Depreciation Book Code", DeprCodeTax);
            FAJnlLine.Validate("FA Posting Type", FAJnlLine."FA Posting Type"::"Acquisition Cost");
            FAJnlLine.Description := StrSubstNo(XReleasetoOperation + ' %1', FixedAsset."FA Type");
            FAJnlLine.Validate(Amount, Abs(Amount));
            FAJnlLine."FA Reclassification Entry" := true;

            FAJnlPostLine.FAJnlPostLine(FAJnlLine, true);
            Clear(FAJnlPostLine);
        end;

        if FAType < FixedAsset."FA Type"::"Future Expense" then begin
            FixedAsset.Status := FixedAsset.Status::Montage;
            FixedAsset.Modify();
        end;
    end;

    procedure DepreciationFA(FANo: Code[20]; DeprCodeBase: Code[10]; PostingDate: Date; BalAccountNo: Code[20]; Amount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
        FAJnlLine: Record "FA Journal Line";
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
    begin
        FixedAsset.Get(FANo);
        DepreciationBook.Get(DeprCodeBase);
        if DepreciationBook."G/L Integration - Acq. Cost" then begin
            GenJnlLine.Init();
            GenJnlLine."Document No." := StrSubstNo(XDEPR + '-%1', FixedAsset."No.");
            GenJnlLine.Validate("Posting Date", MakeAdjustments.AdjustDate(PostingDate));
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Fixed Asset";
            GenJnlLine.Validate("Account No.", FANo);
            GenJnlLine.Description := StrSubstNo(XDepreciation + ' %1', FixedAsset."FA Type");
            GenJnlLine.Validate("FA Posting Type", GenJnlLine."FA Posting Type"::Depreciation);
            GenJnlLine.Validate("Depreciation Book Code", DepreciationBook.Code);
            GenJnlLine.Validate(Amount, -Abs(Amount));

            GenJnlPostLine.Run(GenJnlLine);

            GenJnlLine.Init();
            GenJnlLine."Document No." := StrSubstNo(XDEPR + '-%1', FixedAsset."No.");
            GenJnlLine.Validate("Posting Date", MakeAdjustments.AdjustDate(PostingDate));
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine.Validate("Account No.", BalAccountNo);
            GenJnlLine.Description := StrSubstNo(XDepreciation + ' %1', FixedAsset."FA Type");
            GenJnlLine.Validate(Amount, Abs(Amount));

            GenJnlPostLine.Run(GenJnlLine);
            Clear(GenJnlPostLine);
        end else begin
            FAJnlLine.Init();
            FAJnlLine."Document No." := StrSubstNo(XDEPR + '-%1', FixedAsset."No.");
            FAJnlLine.Validate("FA Posting Date", MakeAdjustments.AdjustDate(PostingDate));
            FAJnlLine.Validate("FA No.", FANo);
            FAJnlLine.Validate("Depreciation Book Code", DepreciationBook.Code);
            FAJnlLine.Validate("FA Posting Type", FAJnlLine."FA Posting Type"::Depreciation);
            FAJnlLine.Description := StrSubstNo(XDepreciation + ' %1', FixedAsset."FA Type");
            FAJnlLine.Validate(Amount, -Abs(Amount));

            FAJnlPostLine.FAJnlPostLine(FAJnlLine, true);
            Clear(FAJnlPostLine);
        end;
    end;

    procedure DisposalFA(FANo: Code[20]; DeprCodeBase: Code[10]; PostingDate: Date)
    var
        GenJnlLine: Record "Gen. Journal Line";
        FAJnlLine: Record "FA Journal Line";
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
    begin
        FixedAsset.Get(FANo);
        DepreciationBook.Get(DeprCodeBase);
        if DepreciationBook."G/L Integration - Acq. Cost" then begin
            GenJnlLine.Init();
            GenJnlLine."Document No." := StrSubstNo(XDISP + '-%1', FixedAsset."No.");
            GenJnlLine.Validate("Posting Date", MakeAdjustments.AdjustDate(PostingDate));
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Fixed Asset";
            GenJnlLine.Validate("Account No.", FANo);
            GenJnlLine.Description := StrSubstNo(XFADisposal + ' %1', FixedAsset."FA Type");
            GenJnlLine.Validate("FA Posting Type", GenJnlLine."FA Posting Type"::Disposal);
            GenJnlLine.Validate("Depreciation Book Code", DepreciationBook.Code);
            GenJnlLine.Validate(Amount, 0);

            GenJnlPostLine.Run(GenJnlLine);
            Clear(GenJnlPostLine);
        end else begin
            FAJnlLine.Init();
            FAJnlLine."Document No." := StrSubstNo(XDISP + '-%1', FixedAsset."No.");
            FAJnlLine.Validate("FA Posting Date", MakeAdjustments.AdjustDate(PostingDate));
            FAJnlLine.Validate("FA No.", FANo);
            FAJnlLine.Validate("Depreciation Book Code", DepreciationBook.Code);
            FAJnlLine.Validate("FA Posting Type", FAJnlLine."FA Posting Type"::Disposal);
            FAJnlLine.Description := StrSubstNo(XFADisposal + ' %1', FixedAsset."FA Type");
            FAJnlLine.Validate(Amount, 0);

            FAJnlPostLine.FAJnlPostLine(FAJnlLine, true);
            Clear(FAJnlPostLine);
        end;
    end;

    procedure SellFA(FANo: Code[20]; DeprCodeBase: Code[10]; PostingDate: Date; BalAccountNo: Code[20]; Amount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
    begin
        FixedAsset.Get(FANo);
        DepreciationBook.Get(DeprCodeBase);
        if DepreciationBook."G/L Integration - Acq. Cost" then begin
            GenJnlLine.Init();
            GenJnlLine."Document No." := StrSubstNo(XSALE + '-%1', FixedAsset."No.");
            GenJnlLine.Validate("Posting Date", MakeAdjustments.AdjustDate(PostingDate));
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Fixed Asset";
            GenJnlLine.Validate("Account No.", FANo);
            GenJnlLine.Description := StrSubstNo(XFASales + ' %1', FixedAsset."FA Type");
            GenJnlLine.Validate("FA Posting Type", GenJnlLine."FA Posting Type"::Disposal);
            GenJnlLine.Validate("Depreciation Book Code", DepreciationBook.Code);
            GenJnlLine.Validate(Amount, -Abs(Amount));

            GenJnlPostLine.Run(GenJnlLine);

            GenJnlLine.Init();
            GenJnlLine."Document No." := StrSubstNo(XSALE + '-%1', FixedAsset."No.");
            GenJnlLine.Validate("Posting Date", MakeAdjustments.AdjustDate(PostingDate));
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine.Validate("Account No.", BalAccountNo);
            GenJnlLine.Description := StrSubstNo(XFASales + ' %1', FixedAsset."FA Type");
            GenJnlLine.Validate(Amount, Abs(Amount));

            GenJnlPostLine.Run(GenJnlLine);
            Clear(GenJnlPostLine);
        end;
    end;

    procedure CreateGLacc(AccNo: Code[20]; AccName: Text[50])
    begin
        GLAccount.Init();
        GLAccount."No." := AccNo;
        if GLAccount.Insert(true) then
            GLAccount.Find()
        else
            GLAccount.Validate(Name, AccName);
        GLAccount."Direct Posting" := true;
        GLAccount.Modify(true);
    end;

    procedure MakeFADeprBook(FANo: Code[20]; DeprBookCode: Code[10]; LifeMonth: Integer; BeginDepr: Date; Type: Enum "FA Depreciation Method")
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        FADepreciationBook.Get(FANo, DeprBookCode);
        FADepreciationBook.Validate("Depreciation Method", Type);
        FADepreciationBook.Validate("Depreciation Starting Date", MakeAdjustments.AdjustDate(BeginDepr));
        FADepreciationBook.Validate("No. of Depreciation Months", LifeMonth);
        FADepreciationBook.Modify();
    end;

    procedure MakeTableFADeprBook(FANo: Code[20]; DeprBookCode: Code[10]; HeaderCode: Code[10]; HeaderDescription: Text[30]; BeginDepr: Date; NumberLine: Integer; UnitsInFirstLine: Decimal; UnitsInAllLine: Decimal)
    var
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationTableHeader: Record "Depreciation Table Header";
        DepreciationTableLine: Record "Depreciation Table Line";
        LineNo: Integer;
        UnitsInLastLine: Decimal;
    begin
        if DepreciationTableHeader.Get(HeaderCode) then
            DepreciationTableHeader.Delete(true);

        DepreciationTableHeader.Code := HeaderCode;
        DepreciationTableHeader.Description := HeaderDescription;
        DepreciationTableHeader."Period Length" := DepreciationTableHeader."Period Length"::Month;
        DepreciationTableHeader."Total No. of Units" := NumberLine * UnitsInAllLine;
        if UnitsInFirstLine = UnitsInAllLine then
            UnitsInLastLine := UnitsInAllLine
        else begin
            UnitsInLastLine := UnitsInAllLine - UnitsInFirstLine;
            NumberLine += 1;
        end;
        DepreciationTableHeader.Insert();

        DepreciationTableLine."Depreciation Table Code" := HeaderCode;
        for LineNo := 1 to NumberLine do begin
            DepreciationTableLine."Period No." := LineNo;
            case LineNo of
                1:
                    DepreciationTableLine.Validate("No. of Units in Period", UnitsInFirstLine);
                NumberLine:
                    DepreciationTableLine.Validate("No. of Units in Period", UnitsInLastLine);
                else
                    DepreciationTableLine.Validate("No. of Units in Period", UnitsInAllLine);
            end;
            DepreciationTableLine.Insert();
        end;

        FADepreciationBook.Get(FANo, DeprBookCode);
        FADepreciationBook.Validate("Depreciation Method", FADepreciationBook."Depreciation Method"::"User-Defined");
        FADepreciationBook.Validate("Depreciation Starting Date", MakeAdjustments.AdjustDate(BeginDepr));
        FADepreciationBook.Validate("First User-Defined Depr. Date", MakeAdjustments.AdjustDate(BeginDepr));
        FADepreciationBook.Validate("Depreciation Table Code", HeaderCode);
        FADepreciationBook.Modify();
    end;

    procedure Example8()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemCharge: Record "Item Charge";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        InventorySetup: Record "Inventory Setup";
        GenPostSetup: Record "General Posting Setup";
        AssignItemChargePurch: Codeunit "Item Charge Assgnt. (Purch.)";
        GLEntry: Record "G/L Entry";
        GLCorrespondenceEntry: Record "G/L Correspondence Entry";
    begin
        InventorySetup.Get();
        InventorySetup."Automatic Posting Date Adjmt." := 2;
        InventorySetup.Modify();

        if GenPostSetup.FindSet(true, false) then
            repeat
                GenPostSetup."Direct Cost Applied Account" := GenPostSetup."Inventory Adjmt. Account";
                GenPostSetup.Modify();
            until GenPostSetup.Next(1) = 0;

        ItemCharge."No." := XNOTAXACC;
        ItemCharge.Description := XNoTaxPosting;
        ItemCharge."Gen. Prod. Posting Group" := XRETAIL;
        ItemCharge."VAT Prod. Posting Group" := XRESALE00;
        ItemCharge."Exclude Cost for TA" := true;
        if not ItemCharge.Insert() then
            ItemCharge.Modify();

        if PurchRcptLine.Find('+') then;

        PurchHeader."Document Type" := PurchHeader."Document Type"::Invoice;
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;

        PurchHeader.Init();
        PurchHeader."No." := '';
        PurchHeader.Insert(true);
        PurchHeader.Validate("Buy-from Vendor No.", '10000');
        PurchHeader.Validate("Location Code", '');
        PurchHeader.Validate("Posting Date", MakeAdjustments.AdjustDate(19030113D));
        PurchHeader."Vendor Invoice No." := PurchHeader."No.";
        PurchHeader.Modify();

        PurchLine."Document Type" := PurchHeader."Document Type";
        PurchLine."Document No." := PurchHeader."No.";
        PurchLine."Line No." := 0;

        PurchLine.Init();
        PurchLine."Line No." += 10000;
        PurchLine.Insert(true);
        PurchLine.Validate(Type, PurchLine.Type::Item);
        PurchLine.Validate("No.", '80001');
        PurchLine.Validate(Quantity, 1);
        PurchLine.Validate("Direct Unit Cost", 4000);
        PurchLine.Modify();

        PurchLine.Init();
        PurchLine."Line No." += 10000;
        PurchLine.Insert(true);
        PurchLine.Validate(Type, PurchLine.Type::Item);
        PurchLine.Validate("No.", '80002');
        PurchLine.Validate(Quantity, 1);
        PurchLine.Validate("Direct Unit Cost", 4000);
        PurchLine.Modify();

        Clear(PurchPost);
        PurchPost.Run(PurchHeader);

        SalesHeader.Init();
        SalesHeader."No." := '';
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", '10000');
        SalesHeader.Validate("Location Code", '');
        SalesHeader.Validate("Posting Date", MakeAdjustments.AdjustDate(19030115D));
        SalesHeader.Modify();

        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 0;

        SalesLine.Init();
        SalesLine."Line No." += 10000;
        SalesLine.Insert(true);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", '80001');
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Unit Price", 200);
        SalesLine.Modify();

        Clear(SalesPost);
        SalesPost.Run(SalesHeader);

        PurchHeader.Init();
        PurchHeader."No." := '';
        PurchHeader.Insert(true);
        PurchHeader.Validate("Buy-from Vendor No.", '10000');
        PurchHeader.Validate("Location Code", '');
        PurchHeader.Validate("Posting Date", MakeAdjustments.AdjustDate(19030210D));
        PurchHeader."Vendor Invoice No." := PurchHeader."No.";
        PurchHeader.Modify();

        PurchLine."Document Type" := PurchHeader."Document Type";
        PurchLine."Document No." := PurchHeader."No.";
        PurchLine."Line No." := 0;

        PurchLine.Init();
        PurchLine."Line No." += 10000;
        PurchLine.Insert(true);
        PurchLine.Validate(Type, PurchLine.Type::Item);
        PurchLine.Validate("No.", '80002');
        PurchLine.Validate(Quantity, 1);
        PurchLine.Validate("Direct Unit Cost", 1000);
        PurchLine.Modify();

        PurchLine.Init();
        PurchLine."Line No." += 10000;
        PurchLine.Insert(true);
        PurchLine.Validate(Type, PurchLine.Type::Item);
        PurchLine.Validate("No.", '80003');
        PurchLine.Validate(Quantity, 1);
        PurchLine.Validate("Direct Unit Cost", 1000);
        PurchLine.Modify();

        Clear(PurchPost);
        PurchPost.Run(PurchHeader);

        SalesHeader.Init();
        SalesHeader."No." := '';
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", '10000');
        SalesHeader.Validate("Location Code", '');
        SalesHeader.Validate("Posting Date", MakeAdjustments.AdjustDate(19030202D));
        SalesHeader.Modify();

        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 0;

        SalesLine.Init();
        SalesLine."Line No." += 10000;
        SalesLine.Insert(true);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", '80002');
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Unit Price", 200);
        SalesLine.Modify();

        Clear(SalesPost);
        SalesPost.Run(SalesHeader);

        PurchHeader.Init();
        PurchHeader."No." := '';
        PurchHeader.Insert(true);
        PurchHeader.Validate("Buy-from Vendor No.", '10000');
        PurchHeader.Validate("Location Code", '');
        PurchHeader.Validate("Posting Date", MakeAdjustments.AdjustDate(19030320D));
        PurchHeader."Vendor Invoice No." := PurchHeader."No.";
        PurchHeader.Modify();

        PurchLine."Document Type" := PurchHeader."Document Type";
        PurchLine."Document No." := PurchHeader."No.";
        PurchLine."Line No." := 0;

        PurchLine.Init();
        PurchLine."Line No." += 10000;
        PurchLine.Insert(true);
        PurchLine.Validate(Type, PurchLine.Type::Item);
        PurchLine.Validate("No.", '80001');
        PurchLine.Validate(Quantity, 1);
        PurchLine.Validate("Direct Unit Cost", 5000);
        PurchLine.Modify();

        PurchLine.Init();
        PurchLine."Line No." += 10000;
        PurchLine.Insert(true);
        PurchLine.Validate(Type, PurchLine.Type::Item);
        PurchLine.Validate("No.", '80003');
        PurchLine.Validate(Quantity, 1);
        PurchLine.Validate("Direct Unit Cost", 5000);
        PurchLine.Modify();

        Clear(PurchPost);
        PurchPost.Run(PurchHeader);

        SalesHeader.Init();
        SalesHeader."No." := '';
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", '10000');
        SalesHeader.Validate("Location Code", '');
        SalesHeader.Validate("Posting Date", MakeAdjustments.AdjustDate(19030328D));
        SalesHeader.Modify();

        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 0;

        SalesLine.Init();
        SalesLine."Line No." += 10000;
        SalesLine.Insert(true);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", '80001');
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Unit Price", 200);
        SalesLine.Modify();

        SalesLine.Init();
        SalesLine."Line No." += 10000;
        SalesLine.Insert(true);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", '80002');
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Unit Price", 200);
        SalesLine.Modify();

        SalesLine.Init();
        SalesLine."Line No." += 10000;
        SalesLine.Insert(true);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", '80003');
        SalesLine.Validate(Quantity, 2);
        SalesLine.Validate("Unit Price", 200);
        SalesLine.Modify();

        Clear(SalesPost);
        SalesPost.Run(SalesHeader);

        PurchHeader.Init();
        PurchHeader."No." := '';
        PurchHeader.Insert(true);
        PurchHeader.Validate("Buy-from Vendor No.", '10000');
        PurchHeader.Validate("Location Code", '');
        PurchHeader.Validate("Posting Date", MakeAdjustments.AdjustDate(19030105D));
        PurchHeader."Vendor Invoice No." := PurchHeader."No.";
        PurchHeader.Modify();

        PurchLine."Document Type" := PurchHeader."Document Type";
        PurchLine."Document No." := PurchHeader."No.";
        PurchLine."Line No." := 0;

        PurchLine.Init();
        PurchLine."Line No." += 10000;
        PurchLine.Insert(true);
        PurchLine.Validate(Type, PurchLine.Type::"Charge (Item)");
        PurchLine.Validate("No.", ItemCharge."No.");
        PurchLine.Validate(Quantity, 1);
        PurchLine.Validate("Direct Unit Cost", 2000);
        PurchLine.Modify();

        Clear(ItemChargeAssgntPurch);
        ItemChargeAssgntPurch."Document Type" := PurchLine."Document Type";
        ItemChargeAssgntPurch."Document No." := PurchLine."Document No.";
        ItemChargeAssgntPurch."Document Line No." := PurchLine."Line No.";
        ItemChargeAssgntPurch."Item Charge No." := PurchLine."No.";

        while PurchRcptLine.Next(1) <> 0 do begin
            ItemChargeAssgntPurch."Unit Cost" := 2000;
            AssignItemChargePurch.CreateRcptChargeAssgnt(PurchRcptLine, ItemChargeAssgntPurch);
        end;

        AssignItemChargePurch.AssignItemCharges(PurchLine, 1, PurchLine."Line Amount", AssignItemChargePurch.AssignByAmountMenuText());

        Clear(PurchPost);
        PurchPost.Run(PurchHeader);

        Commit();
        InvtAdjmt.SetProperties(true, true);
        InvtAdjmt.MakeMultiLevelAdjmt();

        Commit();
        PostInventoryCostToGL.InitializeRequest(1, '', true);
        PostInventoryCostToGL.UseRequestPage(false);
        PostInventoryCostToGL.RunModal();

        GLEntry.Reset();
        GLEntry.SetCurrentKey("Transaction No.");
        GLCorrespondenceEntry.Reset();
        if GLCorrespondenceEntry.FindLast() then
            GLEntry.SetFilter("Transaction No.", '>%1', GLCorrespondenceEntry."Transaction No.");

        CorrespManagement.CreateCorrespEntries(GLEntry);
    end;
}

