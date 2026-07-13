codeunit 163413 "Create Tax Diff. Setup"
{

    trigger OnRun()
    begin
        InitTaxDifferences();

        // Create tax difference template
        FE.Init();
        FE.Validate("No.", XFETEMPLATE + '1');
        FE."FA Type" := FE."FA Type"::"Future Expense";
        FE.Description := XFEforFAsoldwithloss;
        FE."Tax Difference Code" := XEX + '02';
        FE.Inactive := true;
        FE.Blocked := true;
        FE.Insert(true);

        FADeprBook.SetRange("FA No.", FE."No.");
        if FADeprBook.FindSet() then
            repeat
                FADeprBook.Validate("Depreciation Method", FADeprBook."Depreciation Method"::"Straight-Line");
                FADeprBook.Modify();
            until FADeprBook.Next() = 0;

        DemoSetup.Get();
        TaxCalcSection.ImportSettings('LocalFiles\' + DemoSetup."Language Code" + '_TaxDifferences.xml');

        TaxCalcSection.FindFirst();
        TaxCalcSection."Starting Date" := MakeAdjustments.AdjustDate(19020101D);
        TaxCalcSection."Ending Date" := MakeAdjustments.AdjustDate(19021231D);
        TaxCalcSection.Modify();
        // SKIP PostExpenses();
        // SKIP SalesFA();
        // SKIP  CreateFutureExpense();
        Commit();
    end;

    var
        GLAccount: Record "G/L Account";
        TaxDiffPostGroup: Record "Tax Diff. Posting Group";
        FAJnlTemplate: Record "FA Journal Template";
        FAJnlBatch: Record "FA Journal Batch";
        FADeprBook: Record "FA Depreciation Book";
        FAJnlSetup: Record "FA Journal Setup";
        TaxRegisterSetup: Record "Tax Register Setup";
        TaxDiffJnlTemplate: Record "Tax Diff. Journal Template";
        TaxDiffJnlBatch: Record "Tax Diff. Journal Batch";
        NormTemplateLine: Record "Tax Reg. Norm Template Line";
        NormTermName: Record "Tax Reg. Norm Term";
        TaxRegisterTermName: Record "Tax Register Term";
        TaxRegisterTemplate: Record "Tax Register Template";
        TaxCalcSection: Record "Tax Calc. Section";
        TaxTemplateTermName: Record "Tax Calc. Term";
        TaxTemplateLine: Record "Tax Calc. Line";
        SourceCode: Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
        FE: Record "Fixed Asset";
        DemoSetup: Record "Demo Data Setup";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        FAJnlPostLine: Codeunit "FA Jnl.-Post Line";
        XTAXDIFF: Label 'TAXDIFF';
        XTaxDifferenceAccounting: Label 'Tax Difference Accounting';
        XFUTEXP: Label 'FUTEXP';
        XFE00001: Label 'FE00001';
        XFA: Label 'FA';
        XFutureExpensesJournal: Label 'Future Expenses Journal';
        XDEFAULT: Label 'DEFAULT';
        XDefaultJournal: Label 'Default Journal';
        MakeAdjustments: Codeunit "Make Adjustments";
        XGENERAL: Label 'GENERAL';
        XNORMS: Label 'NORMS';
        XACT00001: Label 'ACT00001';
        XReleasetoOperation: Label 'Release to Operation';
        XFADepreciationFeb: Label 'FA Depreciation, February';
        XACT00002: Label 'ACT00002';
        XACT00003: Label 'ACT00003';
        XACT00004: Label 'ACT00004';
        XTAXDIFFJNL: Label 'TAXDIFFJNL';
        XTaxDifferenceJournal: Label 'Tax Difference Journal';
        XGeneralJournal: Label 'General Journal';
        XItem1: Label 'Item 1';
        XTAXACC: Label 'TAXACC';
        XAQUISITION: Label 'AQUISITION';
        XOPERATION: Label 'OPERATION';
        XTELEPHONE: Label 'TELEPHONE';
        XFixedAssetSales: Label 'Fixed Asset Sales';
        XREPREXP: Label 'REPREXP';
        XRepresentativeExpenses: Label 'Representative Expenses';
        XFutureExpense1: Label 'Future Expense 1';
        XFE0001: Label 'FE0001';
        XFutureExpensePosting: Label 'Future Expense Posting';
        XFEDepreciationJan: Label 'FE Depreciation, January';
        XEX: Label 'EX-';
        XEXFA: Label 'EX-FA';
        XFAfornotforprofitbusiness: Label 'FA for not-for-profit business';
        XFADisposalwithLoss: Label 'FA Disposal with Loss';
        XVoluntaryMedicalInsurance: Label 'Voluntary Medical Insurance';
        XAdvertisingExpenses: Label 'Advertising Expenses';
        XInventoryCost: Label 'Inventory Cost';
        XPTRATE: Label 'PTRATE';
        XMEDINS: Label 'MEDINS';
        XFADISPOSAL: Label 'FADISPOSAL';
        XPositiveCurAdj: Label 'Different gains for currency (Accounting) and amount (TA) differences';
        XNegativeCurAdj: Label 'Different losses for currency (Accounting) and amount (TA) differences';
        XPositiveCurAdjPrepayment: Label 'Prepayment differences gains for currency prepayment  adjustment';
        XNegativeCurAdjPrepayment: Label 'Prepayment differences losses for currency prepayment  adjustment';
        XDifferentRevenuePD: Label 'Different Revenue in Accounting and TA with currency prepayment  adjustment';
        XDifferentChargesPD: Label 'Different Charges in Accounting and TA with currency prepayment  adjustment';
        XOtherDifferencesCTA: Label 'Other Differences, CTA should be calculated';
        XOtherDifferencesCTL: Label 'Other Differences, CTL should be calculated';
        XFETAX: Label 'FETAX';
        XFETEMPLATE: Label 'FE TEMPLATE';
        XFEforFAsoldwithloss: Label 'FE for FA sold with loss';
        XTD_FADefault: Label 'Tax difference for FA by default';
        XTD_FADeprBonus: Label 'Tax difference for FA -  Depr. Bonus';
        XTD_FADepr: Label 'Tax difference for FA - Depreciation';
        XTD_FAAquis: Label 'Tax difference for Acquisition Cost FA';
        XTD_FADeprBonusRecov: Label 'Tax difference for Recovery Depr.Bonus';
        XTD_FADisposal: Label 'Tax Difference for disposal FA';
        "Create No. Series": Codeunit "Create No. Series";
        XTDBatchFA: Label 'Tax Difference Calculation for FA';
        XTD_FA: Label 'Tax difference for FA';
        XJNL: Label 'JNL';
        XFAReal: Label 'FA realization by TA';

    procedure CreateTaxDifferences()
    begin
        InsertTaxDiff(XEX + '01', XFAfornotforprofitbusiness, 0, 0, XNORMS, XPTRATE, XTAXDIFF, 0, 0, '', '', false, false);
        InsertTaxDiff(XEX + '02', XFADisposalwithLoss, 0, 1, XNORMS, XPTRATE, XTAXDIFF, 0, 0, '', '', true, false);
        InsertTaxDiff(XEX + '03', XVoluntaryMedicalInsurance, 0, 1, XNORMS, XPTRATE, XTAXDIFF, 0, 1, XNORMS, XMEDINS, false, false);
        InsertTaxDiff(XEX + '04', XAdvertisingExpenses, 0, 1, XNORMS, XPTRATE, XTAXDIFF, 1, 1, '', '', false, false);
        InsertTaxDiff(XEX + '07', XRepresentativeExpenses, 0, 1, XNORMS, XPTRATE, XTAXDIFF, 1, 1, '', '', false, false);
        InsertTaxDiff(XEX + '08', XInventoryCost, 0, 0, XNORMS, XPTRATE, XTAXDIFF, 0, 0, '', '', false, false);

        InsertTaxDiff(XEX + '09', XPositiveCurAdj, 1, 0, XNORMS, XPTRATE, XTAXDIFF, 0, 0, '', '', false, false);
        InsertTaxDiff(XEX + '10', XNegativeCurAdj, 0, 0, XNORMS, XPTRATE, XTAXDIFF, 0, 0, '', '', false, false);
        InsertTaxDiff(XEX + '11', XPositiveCurAdjPrepayment, 1, 0, XNORMS, XPTRATE, XTAXDIFF, 0, 0, '', '', false, false);
        InsertTaxDiff(XEX + '12', XNegativeCurAdjPrepayment, 0, 0, XNORMS, XPTRATE, XTAXDIFF, 0, 0, '', '', false, false);
        InsertTaxDiff(XEX + '13', XDifferentRevenuePD, 1, 0, XNORMS, XPTRATE, XTAXDIFF, 0, 0, '', '', false, false);
        InsertTaxDiff(XEX + '14', XDifferentChargesPD, 0, 0, XNORMS, XPTRATE, XTAXDIFF, 0, 0, '', '', false, false);
        InsertTaxDiff(XEX + '15', XOtherDifferencesCTA, 0, 0, XNORMS, XPTRATE, XTAXDIFF, 0, 0, '', '', false, false);
        InsertTaxDiff(XEX + '16', XOtherDifferencesCTL, 1, 0, XNORMS, XPTRATE, XTAXDIFF, 0, 0, '', '', false, false);

        InsertTaxDiff(XEXFA + '1', XTD_FADefault, 0, 1, XNORMS, XPTRATE, XTAXDIFF, 0, 0, '', '', true, false);
        InsertTaxDiff(XEXFA + '2', XTD_FADeprBonus, 0, 1, XNORMS, XPTRATE, XTAXDIFF, 0, 0, '', '', true, true);
        InsertTaxDiff(XEXFA + '3', XTD_FADepr, 0, 1, XNORMS, XPTRATE, XTAXDIFF, 0, 0, '', '', true, false);
        InsertTaxDiff(XEXFA + '4', XTD_FAAquis, 0, 0, XNORMS, XPTRATE, XTAXDIFF, 0, 0, '', '', true, false);
        InsertTaxDiff(XEXFA + '40', XTD_FAAquis, 0, 1, XNORMS, XPTRATE, XTAXDIFF, 0, 0, '', '', true, false);
        InsertTaxDiff(XEXFA + '5', XTD_FADeprBonusRecov, 1, 0, XNORMS, XPTRATE, XTAXDIFF, 0, 0, '', '', true, false);
        InsertTaxDiff(XEXFA + '6', XTD_FADisposal, 0, 0, XNORMS, XPTRATE, XTAXDIFF, 0, 0, '', '', true, false);
    end;

    procedure CreateGLacc(AccNo: Code[20]; AccName: Text[50])
    begin
        GLAccount.Init();
        GLAccount."No." := AccNo;
        GLAccount."Direct Posting" := true;
        if GLAccount.Insert(true) then;
        GLAccount.Validate(Name, AccName);
        GLAccount.Modify(true);
    end;

    procedure SalesFA()
    var
        GenJnlLine: Record "Gen. Journal Line";
        FAJnlLine: Record "FA Journal Line";
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        DepreciationBook.Get(XTAXACC);

        FixedAsset."No." := '';
        FixedAsset.Init();
        FixedAsset.Insert(true);
        FixedAsset.Validate(Description, XItem1);
        FixedAsset."FA Type" := FixedAsset."FA Type"::"Fixed Assets";
        FixedAsset.Modify();

        FixedAsset.Status := FixedAsset.Status::Inventory;
        FixedAsset.Modify();

        if FADepreciationBook.Get(FixedAsset."No.", XAQUISITION) then
            FADepreciationBook.Delete(true);

        FADepreciationBook.Get(FixedAsset."No.", XOPERATION);
        FADepreciationBook."FA Posting Group" := XTELEPHONE;
        FADepreciationBook.Modify();

        FADepreciationBook.Init();
        FADepreciationBook."FA No." := FixedAsset."No.";
        FADepreciationBook."Depreciation Book Code" := DepreciationBook.Code;
        if FADepreciationBook.Insert(true) then;

        DepreciationBook.Get(XOPERATION);

        GenJnlLine.Init();
        GenJnlLine."Document No." := XACT00001;
        GenJnlLine.Validate("Posting Date", MakeAdjustments.AdjustDate(19030101D));
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Fixed Asset";
        GenJnlLine.Validate("Account No.", FixedAsset."No.");
        GenJnlLine.Description := XReleasetoOperation;
        GenJnlLine.Validate("FA Posting Type", GenJnlLine."FA Posting Type"::"Acquisition Cost");
        GenJnlLine.Validate("Depreciation Book Code", DepreciationBook.Code);
        GenJnlLine.Validate(Amount, 120000);

        GenJnlPostLine.Run(GenJnlLine);

        GenJnlLine.Init();
        GenJnlLine."Document No." := XACT00001;
        GenJnlLine.Validate("Posting Date", MakeAdjustments.AdjustDate(19030101D));
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine.Validate("Account No.", MakeAdjustments.Convert('9976600'));
        GenJnlLine.Description := XReleasetoOperation;
        GenJnlLine.Validate(Amount, -120000);
        GenJnlLine."FA Reclassification Entry" := true;

        GenJnlPostLine.Run(GenJnlLine);
        Clear(GenJnlPostLine);

        FAJnlLine.Init();
        FAJnlLine."Document No." := XACT00001;
        FAJnlLine.Validate("FA Posting Date", MakeAdjustments.AdjustDate(19030101D));
        FAJnlLine.Validate("FA No.", FixedAsset."No.");
        FAJnlLine.Validate("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
        FAJnlLine.Validate("FA Posting Type", FAJnlLine."FA Posting Type"::"Acquisition Cost");
        FAJnlLine.Description := XReleasetoOperation;
        FAJnlLine.Validate(Amount, 120000);
        FAJnlLine."FA Reclassification Entry" := true;

        FAJnlPostLine.FAJnlPostLine(FAJnlLine, true);
        Clear(FAJnlPostLine);

        GenJnlLine.Init();
        GenJnlLine."Document No." := XACT00002;
        GenJnlLine.Validate("Posting Date", MakeAdjustments.AdjustDate(19030228D));
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Fixed Asset";
        GenJnlLine.Validate("Account No.", FixedAsset."No.");
        GenJnlLine.Description := XFADepreciationFeb;
        GenJnlLine.Validate("FA Posting Type", GenJnlLine."FA Posting Type"::Depreciation);
        GenJnlLine.Validate("Depreciation Book Code", DepreciationBook.Code);
        GenJnlLine.Validate(Amount, -80000);

        GenJnlPostLine.Run(GenJnlLine);

        GenJnlLine.Init();
        GenJnlLine."Document No." := XACT00002;
        GenJnlLine.Validate("Posting Date", MakeAdjustments.AdjustDate(19030228D));
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine.Validate("Account No.", MakeAdjustments.Convert('9920420'));
        GenJnlLine.Description := XFADepreciationFeb;
        GenJnlLine.Validate(Amount, 80000);

        GenJnlPostLine.Run(GenJnlLine);
        Clear(GenJnlPostLine);

        FAJnlLine.Init();
        FAJnlLine."Document No." := XACT00002;
        FAJnlLine.Validate("FA Posting Date", MakeAdjustments.AdjustDate(19030228D));
        FAJnlLine.Validate("FA No.", FixedAsset."No.");
        FAJnlLine.Validate("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
        FAJnlLine.Validate("FA Posting Type", FAJnlLine."FA Posting Type"::Depreciation);
        FAJnlLine.Description := XFADepreciationFeb;
        FAJnlLine.Validate(Amount, -40000);

        FAJnlPostLine.FAJnlPostLine(FAJnlLine, true);
        Clear(FAJnlPostLine);

        GenJnlLine.Init();
        GenJnlLine."Document No." := XACT00003;
        GenJnlLine.Validate("Posting Date", MakeAdjustments.AdjustDate(19030301D));
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Fixed Asset";
        GenJnlLine.Validate("Account No.", FixedAsset."No.");
        GenJnlLine.Description := XFADISPOSAL;
        GenJnlLine.Validate("FA Posting Type", GenJnlLine."FA Posting Type"::Disposal);
        GenJnlLine.Validate("Depreciation Book Code", DepreciationBook.Code);
        GenJnlLine.Validate(Amount, 0);

        GenJnlPostLine.Run(GenJnlLine);
        Clear(GenJnlPostLine);

        FAJnlLine.Init();
        FAJnlLine."Document No." := XACT00003;
        FAJnlLine.Validate("FA Posting Date", MakeAdjustments.AdjustDate(19030301D));
        FAJnlLine.Validate("FA No.", FixedAsset."No.");
        FAJnlLine.Validate("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
        FAJnlLine.Validate("FA Posting Type", FAJnlLine."FA Posting Type"::Disposal);
        FAJnlLine.Description := XFADISPOSAL;
        FAJnlLine.Validate(Amount, 0);

        FAJnlPostLine.FAJnlPostLine(FAJnlLine, true);
        Clear(FAJnlPostLine);

        GenJnlLine.Init();
        GenJnlLine."Document No." := XFixedAssetSales;
        GenJnlLine.Validate("Posting Date", MakeAdjustments.AdjustDate(19030301D));
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Fixed Asset";
        GenJnlLine.Validate("Account No.", FixedAsset."No.");
        GenJnlLine.Description := XFixedAssetSales;
        GenJnlLine.Validate("FA Posting Type", GenJnlLine."FA Posting Type"::Disposal);
        GenJnlLine.Validate("Depreciation Book Code", DepreciationBook.Code);
        GenJnlLine.Validate(Amount, -25000);

        GenJnlPostLine.Run(GenJnlLine);

        GenJnlLine.Init();
        GenJnlLine."Document No." := XFixedAssetSales;
        GenJnlLine.Validate("Posting Date", MakeAdjustments.AdjustDate(19030301D));
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine.Validate("Account No.", MakeAdjustments.Convert('9976600'));
        GenJnlLine.Description := XFixedAssetSales;
        GenJnlLine.Validate(Amount, 25000);

        GenJnlPostLine.Run(GenJnlLine);
        Clear(GenJnlPostLine);
    end;

    procedure PostExpenses()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.Init();
        GenJnlLine."Document No." := XREPREXP;
        GenJnlLine.Validate("Posting Date", MakeAdjustments.AdjustDate(19030115D));
        GenJnlLine.Validate("Account No.", MakeAdjustments.Convert('9976600'));
        GenJnlLine.Validate("Bal. Account No.", MakeAdjustments.Convert('9950200'));
        GenJnlLine.Description := XRepresentativeExpenses;
        GenJnlLine.Validate(Amount, 2500);

        GenJnlPostLine.Run(GenJnlLine);
        Clear(GenJnlPostLine);
    end;

    procedure CreateFutureExpense()
    var
        FutureExpense: Record "Fixed Asset";
        FEDeprBook: Record "FA Depreciation Book";
        FAJnlLine: Record "FA Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        FutureExpense.Init();
        FutureExpense."No." := XFE00001;
        FutureExpense.Description := XFutureExpense1;
        FutureExpense."FA Type" := FutureExpense."FA Type"::"Future Expense";
        FutureExpense."Tax Difference Code" := XEX + '05';
        FutureExpense.Insert(true);
        FutureExpense."Last Date Modified" := MakeAdjustments.AdjustDate(19030101D);
        FutureExpense.Modify();

        // FEDeprBook.GET(FutureExpense."No.",XFUTEXNOINT);
        // FEDeprBook.VALIDATE("Depreciation Starting Date",MakeAdjustments.AdjustDate(01011903D));
        // FEDeprBook.VALIDATE("Depreciation Ending Date",MakeAdjustments.AdjustDate(31011903D));
        // FEDeprBook.Modify();

        FEDeprBook.Get(FutureExpense."No.", XFETAX);
        FEDeprBook.Validate("Depreciation Starting Date", MakeAdjustments.AdjustDate(19030101D));
        FEDeprBook.Validate("Depreciation Ending Date", MakeAdjustments.AdjustDate(19030630D));
        FEDeprBook.Modify();

        SourceCodeSetup.Get();

        FAJnlLine.Init();
        FAJnlLine."Document No." := XFE0001;
        FAJnlLine.Validate("FA Posting Date", MakeAdjustments.AdjustDate(19030101D));
        FAJnlLine.Validate("FA No.", FutureExpense."No.");
        FAJnlLine.Validate("Depreciation Book Code", XFETAX);
        FAJnlLine.Validate("FA Posting Type", FAJnlLine."FA Posting Type"::"Acquisition Cost");
        FAJnlLine.Description := XFutureExpensePosting;
        FAJnlLine."Source Code" := SourceCodeSetup."Tax Difference Journal";
        FAJnlLine.Validate(Amount, 25000);
        FAJnlPostLine.FAJnlPostLine(FAJnlLine, true);
        Clear(FAJnlPostLine);

        // depreciation for January 2004
        // FAJnlLine.Init();
        // FAJnlLine."Document No." := XACT00004;
        // FAJnlLine.VALIDATE("FA Posting Date",MakeAdjustments.AdjustDate(31011903D));
        // FAJnlLine.VALIDATE("FA No.",FutureExpense."No.");
        // FAJnlLine.VALIDATE("Depreciation Book Code",XFUTEXNOINT);
        // FAJnlLine.VALIDATE("FA Posting Type",FAJnlLine."FA Posting Type"::Depreciation);
        // FAJnlLine.Description := XFEDepreciationJan;
        // FAJnlLine."Source Code" := SourceCodeSetup."Tax Difference Journal";
        // FAJnlLine.VALIDATE(Amount,-25000);
        // FAJnlPostLine.FAJnlPostLine(FAJnlLine,TRUE,TempJnlLineDim);
        // CLEAR(FAJnlPostLine);

        FAJnlLine.Init();
        FAJnlLine."Document No." := XACT00004;
        FAJnlLine.Validate("FA Posting Date", MakeAdjustments.AdjustDate(19030131D));
        FAJnlLine.Validate("FA No.", FutureExpense."No.");
        FAJnlLine.Validate("Depreciation Book Code", XFETAX);
        FAJnlLine.Validate("FA Posting Type", FAJnlLine."FA Posting Type"::Depreciation);
        FAJnlLine.Description := XFEDepreciationJan;
        FAJnlLine."Source Code" := SourceCodeSetup."Tax Difference Journal";
        FAJnlLine.Validate(Amount, -4166.67);
        FAJnlPostLine.FAJnlPostLine(FAJnlLine, true);
        Clear(FAJnlPostLine);
    end;

    procedure InitTaxDifferences()
    begin
        NormTemplateLine.GenerateProfile();
        NormTermName.GenerateProfile();
        TaxRegisterTemplate.GenerateProfile();
        TaxRegisterTermName.GenerateProfile();
        TaxTemplateLine.GenerateProfile();
        TaxTemplateTermName.GenerateProfile();

        TaxDiffPostGroup.Init();
        TaxDiffPostGroup.Code := XTAXDIFF;
        TaxDiffPostGroup.Description := XTaxDifferenceAccounting;
        TaxDiffPostGroup."CTA Tax Account" := '68-3120';
        TaxDiffPostGroup."CTL Tax Account" := '68-3120';
        TaxDiffPostGroup."DTA Tax Account" := '68-3130';
        TaxDiffPostGroup."DTL Tax Account" := '68-3140';
        TaxDiffPostGroup."CTA Account" := '99-0420';
        TaxDiffPostGroup."CTL Account" := '99-0425';
        TaxDiffPostGroup."DTA Account" := '09-1000';
        TaxDiffPostGroup."DTL Account" := '77-1000';
        TaxDiffPostGroup."DTA Disposal Account" := '99-0510';
        TaxDiffPostGroup."DTL Disposal Account" := '99-0520';
        TaxDiffPostGroup."DTA Transfer Bal. Account" := '68-3130';
        TaxDiffPostGroup."DTL Transfer Bal. Account" := '68-3140';
        TaxDiffPostGroup."CTA Transfer Tax Account" := '99-0420';
        TaxDiffPostGroup."CTL Transfer Tax Account" := '99-0425';
        if not TaxDiffPostGroup.Insert() then
            TaxDiffPostGroup.Modify();

        SourceCode.Init();
        SourceCode.Code := XTAXDIFFJNL;
        SourceCode.Description := XTaxDifferenceJournal;
        if not SourceCode.Insert() then
            SourceCode.Modify();

        SourceCodeSetup.Get();
        SourceCodeSetup."Tax Difference Journal" := SourceCode.Code;
        SourceCodeSetup.Modify();

        FAJnlTemplate.Init();
        FAJnlTemplate.Name := XFUTEXP;
        FAJnlTemplate.Description := XFutureExpensesJournal;
        FAJnlTemplate.Validate(Type, FAJnlTemplate.Type::"Future Expenses");
        if not FAJnlTemplate.Insert() then
            FAJnlTemplate.Modify();

        FAJnlBatch.Init();
        FAJnlBatch."Journal Template Name" := FAJnlTemplate.Name;
        FAJnlBatch.Name := XDEFAULT;
        FAJnlBatch.Description := XDefaultJournal;
        if FAJnlBatch.Insert() then;

        FAJnlSetup.Init();
        FAJnlSetup."Depreciation Book Code" := XFETAX;
        FAJnlSetup."FA Jnl. Template Name" := FAJnlTemplate.Name;
        FAJnlSetup."FA Jnl. Batch Name" := FAJnlBatch.Name;
        if not FAJnlSetup.Insert() then
            FAJnlSetup.Modify();

        TaxRegisterSetup.Get();
        TaxRegisterSetup."Future Exp. Depreciation Book" := XFETAX;
        TaxRegisterSetup.Modify();

        TaxDiffJnlTemplate.Init();
        TaxDiffJnlTemplate.Name := XGENERAL;
        TaxDiffJnlTemplate.Description := XGeneralJournal;
        if not TaxDiffJnlTemplate.Insert(true) then begin
            TaxDiffJnlTemplate.Delete();
            TaxDiffJnlTemplate.Insert(true);
        end;

        TaxDiffJnlBatch.Init();
        TaxDiffJnlBatch."Journal Template Name" := TaxDiffJnlTemplate.Name;
        TaxDiffJnlBatch.Name := XDEFAULT;
        TaxDiffJnlBatch.Description := XDefaultJournal;
        if TaxDiffJnlBatch.Insert() then;

        TaxDiffJnlBatch.Init();
        TaxDiffJnlBatch."Journal Template Name" := TaxDiffJnlTemplate.Name;
        TaxDiffJnlBatch.Name := XFA;
        TaxDiffJnlBatch.Description := XTDBatchFA;
        "Create No. Series".InitBaseSeries(TaxDiffJnlBatch."No. Series", XJNL + '-31', XTD_FA, 'G31001', 'G32000', 'G31001', '', 1);
        if TaxDiffJnlBatch.Insert() then;
    end;

    procedure InsertTaxDiff("Code": Code[10]; Description: Text[80]; Category: Integer; Type: Integer; NormJurisdictionCode: Code[10]; NormCode: Code[10]; PostingGroup: Code[20]; TaxPeriodLimited: Integer; CalculationMode: Integer; CalcNormJurisdictionCode: Code[10]; CalcNormCode: Code[10]; SourceCodeMandatory: Boolean; DeprBonus: Boolean)
    var
        TaxDiff: Record "Tax Difference";
    begin
        TaxDiff.Init();
        TaxDiff.Code := Code;
        TaxDiff.Description := Description;
        TaxDiff.Category := Category;
        TaxDiff.Type := Type;
        TaxDiff."Norm Jurisdiction Code" := NormJurisdictionCode;
        TaxDiff."Norm Code" := NormCode;
        TaxDiff."Posting Group" := PostingGroup;
        TaxDiff."Tax Period Limited" := TaxPeriodLimited;
        TaxDiff."Calculation Mode" := CalculationMode;
        TaxDiff."Calc. Norm Jurisdiction Code" := CalcNormJurisdictionCode;
        TaxDiff."Calc. Norm Code" := CalcNormCode;
        TaxDiff."Source Code Mandatory" := SourceCodeMandatory;
        TaxDiff."Depreciation Bonus" := DeprBonus;
        TaxDiff.Insert();
    end;

    procedure PostFAJournals()
    var
        FAJnlLine: Record "FA Journal Line";
    begin
        TaxRegisterSetup.Get();

        FAJnlLine.Init();
        FAJnlLine."Document No." := XTAXACC + '-09-001';
        FAJnlLine.Validate("FA Posting Date", MakeAdjustments.AdjustDate(19021231D));
        FAJnlLine.Validate("FA No.", XFA + '017');
        FAJnlLine.Validate("Depreciation Book Code", TaxRegisterSetup."Tax Depreciation Book");
        FAJnlLine.Validate("FA Posting Type", FAJnlLine."FA Posting Type"::Disposal);
        FAJnlLine.Description := XFAReal;
        FAJnlLine."Depr. until FA Posting Date" := false;
        FAJnlLine.Validate(Amount, -26000);

        FAJnlPostLine.FAJnlPostLine(FAJnlLine, true);
        Clear(FAJnlPostLine);

        FAJnlLine.Init();
        FAJnlLine."Document No." := XTAXACC + '-09-001';
        FAJnlLine.Validate("FA Posting Date", MakeAdjustments.AdjustDate(19021231D));
        FAJnlLine.Validate("FA No.", XFA + '018');
        FAJnlLine.Validate("Depreciation Book Code", TaxRegisterSetup."Tax Depreciation Book");
        FAJnlLine.Validate("FA Posting Type", FAJnlLine."FA Posting Type"::Disposal);
        FAJnlLine.Description := XFAReal;
        FAJnlLine."Depr. until FA Posting Date" := false;
        FAJnlLine.Validate(Amount, -26000);

        FAJnlPostLine.FAJnlPostLine(FAJnlLine, true);
        Clear(FAJnlPostLine);

        FAJnlLine.Init();
        FAJnlLine."Document No." := XTAXACC + '-09-001';
        FAJnlLine.Validate("FA Posting Date", MakeAdjustments.AdjustDate(19021231D));
        FAJnlLine.Validate("FA No.", XFA + '019');
        FAJnlLine.Validate("Depreciation Book Code", TaxRegisterSetup."Tax Depreciation Book");
        FAJnlLine.Validate("FA Posting Type", FAJnlLine."FA Posting Type"::Disposal);
        FAJnlLine.Description := XFAReal;
        FAJnlLine."Depr. until FA Posting Date" := false;
        FAJnlLine.Validate(Amount, -26000);

        FAJnlPostLine.FAJnlPostLine(FAJnlLine, true);
        Clear(FAJnlPostLine);

        FAJnlLine.Init();
        FAJnlLine."Document No." := XTAXACC + '-09-001';
        FAJnlLine.Validate("FA Posting Date", MakeAdjustments.AdjustDate(19021231D));
        FAJnlLine.Validate("FA No.", XFA + '020');
        FAJnlLine.Validate("Depreciation Book Code", TaxRegisterSetup."Tax Depreciation Book");
        FAJnlLine.Validate("FA Posting Type", FAJnlLine."FA Posting Type"::Disposal);
        FAJnlLine.Description := XFAReal;
        FAJnlLine."Depr. until FA Posting Date" := false;
        FAJnlLine.Validate(Amount, -26000);

        FAJnlPostLine.FAJnlPostLine(FAJnlLine, true);
        Clear(FAJnlPostLine);
    end;
}

