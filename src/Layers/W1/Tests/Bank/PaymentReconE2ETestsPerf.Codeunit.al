codeunit 134271 "Payment Recon. E2E Tests Perf."
{
    // // For inbound payments
    // 
    // Street,Amount,DocNo,VendName
    // Invoices = [Virum,20,Y,Anders Larsen]1
    //            [Virum,10,Z,Anders Larsen]4
    //            [Lyngby,10,X,'some text']3
    //            [Kbh,5,W,Anders Larsen]2
    //            [Kbh,5,V,Anders Larsen]
    // 
    // Payments =  [Virum,10,X,Anders Larsen]   [2,1]
    //             [Kbh,10,Z,Anders Larsen]     [4]
    //             ['',10,'',Anders Nielsen]    [2,3]
    //             [Virum,10,Z,Anders Larsen]   [2,1,3]
    // 
    // Invoices = [Virum,20,Y,Anders Larsen]
    //            [Virum,10,Z,Anders Larsen]
    //            [Lyngby,10,X,'some text']
    //            [Kbh,5,W,Anders Larsen]
    //            [Kbh,5,V,Anders Larsen]
    // 
    // Payments =  [Virum,10,X,Anders Larsen]
    //             [Kbh,10,Z,Anders Larsen]
    //             ['',10,'',Anders Nielsen]
    //             [Virum,10,Z,Anders Larsen]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Reconciliation] [Performance]
    end;

    var
        GlobalCustLedgEntry: Record "Cust. Ledger Entry";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        LibraryCAMTFileMgt: Codeunit "Library - CAMT File Mgt.";
        LibraryCalcComplexity: Codeunit "Library - Calc. Complexity";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        GlobalPmtReconJnl: TestPage "Payment Reconciliation Journal";
        Initialized: Boolean;
        OpenBankStatementPageQst: Label 'Do you want to open the bank account statement?';

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandler,PmtApplnToCustHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestXSalesOnePmtPeformance()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        N: array[4] of Integer;
        i: Integer;
        ToImport: array[4] of Integer;
        ToOpenPmtJnl: array[4] of Integer;
        ToAutoApply: array[4] of Integer;
        ToManuallyApply: array[4] of Integer;
        ToPost: array[4] of Integer;
    begin
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        CustLedgEntry.ModifyAll(Open, false);
        VendLedgEntry.ModifyAll(Open, false);

        // The size of the input data
        N[1] := 3;
        N[2] := 4;
        N[3] := 5;
        N[4] := 6;

        // Exercise
        for i := 1 to 4 do
            TestXSaleOnePmtPeformance(N[i], ToImport[i], ToOpenPmtJnl[i], ToAutoApply[i], ToManuallyApply[i], ToPost[i]);

        // Verify
        Assert.IsTrue(
          LibraryCalcComplexity.IsLinear(N[2], N[3], N[4], ToImport[2], ToImport[3], ToImport[4]),
          'Import Bank Stmt is linear');
        Assert.IsTrue(
          LibraryCalcComplexity.IsLinear(N[2], N[3], N[4], ToOpenPmtJnl[2], ToOpenPmtJnl[3], ToOpenPmtJnl[4]),
          'Open the Payment Reconciliation is linear');
        Assert.IsTrue(
          LibraryCalcComplexity.IsQuadratic(N[1], N[2], N[3], N[4], ToAutoApply[1], ToAutoApply[2], ToAutoApply[3], ToAutoApply[4]),
          'Automatic applying is quadratic');
        Assert.IsTrue(
          LibraryCalcComplexity.IsQuadratic(
            N[1], N[2], N[3], N[4], ToManuallyApply[1], ToManuallyApply[2], ToManuallyApply[3], ToManuallyApply[4]),
          'Manually applying all stmt lines is quadratic');
        Assert.IsTrue(
          LibraryCalcComplexity.IsNLogN(N[1], N[2], N[3], N[4], ToPost[1], ToPost[2], ToPost[3], ToPost[4]),
          'Posting is nLogn');
    end;

    local procedure TestXSaleOnePmtPeformance(NoOfSales: Integer; var ToImport: Integer; var ToOpenPmtJnl: Integer; var ToAutoApply: Integer; var ToManuallyApply: Integer; var ToPost: Integer)
    var
        CustLedgEntry: array[36] of Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        NoOfHits: Integer;
        i: Integer;
        j: Integer;
    begin
        Initialize();

        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        j := 0;
        for i := 1 to NoOfSales do begin
            TwoSaleOnePmt(CustLedgEntry, OutStream, j + 1, j + NoOfSales);
            j := i * NoOfSales;
        end;
        WriteCAMTFooter(OutStream);

        // Exercise
        CodeCoverageMgt.StartApplicationCoverage();

        // Measure Import
        NoOfHits := CodeCoverageMgt.ApplicationHits();
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8);
        ToImport := CodeCoverageMgt.ApplicationHits() - NoOfHits;

        // Measure Open Pmt Jnl
        NoOfHits := CodeCoverageMgt.ApplicationHits();
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ToOpenPmtJnl := CodeCoverageMgt.ApplicationHits() - NoOfHits;

        // Measure Apply Automatically
        NoOfHits := CodeCoverageMgt.ApplicationHits();
        ApplyAutomatically(PmtReconJnl);
        ToAutoApply := CodeCoverageMgt.ApplicationHits() - NoOfHits;

        // Measure Manual Apply
        NoOfHits := CodeCoverageMgt.ApplicationHits();
        ApplyManually(PmtReconJnl, CustLedgEntry, NoOfSales);
        ToManuallyApply := CodeCoverageMgt.ApplicationHits() - NoOfHits;

        VerifyPrePost(BankAccRecon, PmtReconJnl);

        // Measure Post
        NoOfHits := CodeCoverageMgt.ApplicationHits();
        PmtReconJnl.Post.Invoke();
        ToPost := CodeCoverageMgt.ApplicationHits() - NoOfHits;

        CodeCoverageMgt.StopApplicationCoverage();

        j := 0;
        for i := 1 to NoOfSales do begin
            VerifyCustLedgEntry(CustLedgEntry[j + 1]."Customer No.");
            j := i * NoOfSales;
        end;
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    local procedure CreateBankAcc(BankStmtFormat: Code[20]; var BankAcc: Record "Bank Account")
    begin
        LibraryERM.CreateBankAccount(BankAcc);
        BankAcc."Bank Account No." := 'TEST';
        BankAcc."Bank Statement Import Format" := BankStmtFormat;
        BankAcc.Modify(true);
    end;

    local procedure CreateBankAccReconAndImportStmt(var BankAccRecon: Record "Bank Acc. Reconciliation"; var TempBlobUTF8: Codeunit "Temp Blob")
    var
        BankAcc: Record "Bank Account";
        BankStmtFormat: Code[20];
    begin
        BankStmtFormat := 'SEPA CAMT';
        CreateBankAcc(BankStmtFormat, BankAcc);
        LibraryERM.CreateBankAccReconciliation(BankAccRecon, BankAcc."No.", BankAccRecon."Statement Type"::"Payment Application");
        SetupSourceMock(BankStmtFormat, TempBlobUTF8);
        BankAccRecon.ImportBankStatement();

        BankAccRecon.CalcFields("Total Transaction Amount");
        UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + BankAccRecon."Total Transaction Amount");
    end;

    local procedure OpenPmtReconJnl(BankAccRecon: Record "Bank Acc. Reconciliation"; var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    var
        PmtReconciliationJournals: TestPage "Pmt. Reconciliation Journals";
    begin
        PmtReconciliationJournals.OpenView();
        PmtReconciliationJournals.GotoRecord(BankAccRecon);
        PmtReconJnl.Trap();
        PmtReconciliationJournals.EditJournal.Invoke();
    end;

    local procedure ApplyAutomatically(var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    begin
        PmtReconJnl.ApplyAutomatically.Invoke();
        PmtReconJnl.First();
    end;

    local procedure ApplyManually(var PmtReconJnl: TestPage "Payment Reconciliation Journal"; var CustLedgEntry: array[36] of Record "Cust. Ledger Entry"; NoOfSales: Integer)
    var
        j: Integer;
    begin
        for j := 0 to NoOfSales - 1 do begin
            GlobalCustLedgEntry := CustLedgEntry[j * NoOfSales + 1];
            GlobalPmtReconJnl := PmtReconJnl;
            GlobalPmtReconJnl.ApplyEntries.Invoke();
            PmtReconJnl := GlobalPmtReconJnl;
            PmtReconJnl.Next();
        end;
    end;

    local procedure WriteCAMTHeader(var OutStream: OutStream; CurrTxt: Code[10]; BankAccNo: Code[20])
    begin
        LibraryCAMTFileMgt.WriteCAMTHeader(OutStream);
        LibraryCAMTFileMgt.WriteCAMTStmtHeader(OutStream, CurrTxt, BankAccNo);
    end;

    local procedure WriteCAMTStmtLine(var OutStream: OutStream; StmtDate: Date; StmtText: Text; StmtAmt: Decimal; StmtCurr: Code[10])
    begin
        LibraryCAMTFileMgt.WriteCAMTStmtLine(OutStream, StmtDate, StmtText, StmtAmt, StmtCurr, '');
    end;

    local procedure WriteCAMTFooter(var OutStream: OutStream)
    begin
        LibraryCAMTFileMgt.WriteCAMTStmtFooter(OutStream);
        LibraryCAMTFileMgt.WriteCAMTFooter(OutStream);
    end;

    local procedure SetupSourceMock(DataExchDefCode: Code[20]; var TempBlob: Codeunit "Temp Blob")
    begin
        LibraryCAMTFileMgt.SetupSourceMock(DataExchDefCode, TempBlob);
    end;

    local procedure TwoSaleOnePmt(var CustLedgEntry: array[36] of Record "Cust. Ledger Entry"; var OutStream: OutStream; FromPos: Integer; ToPos: Integer)
    var
        Cust: Record Customer;
        i: Integer;
        Total: Decimal;
        DocNo: Text[250];
    begin
        LibrarySales.CreateCustomer(Cust);

        for i := FromPos to ToPos do begin
            CreateSalesInvoiceAndPost(Cust, CustLedgEntry[i], '');
            Total += CustLedgEntry[i]."Remaining Amount" - CustLedgEntry[i]."Remaining Pmt. Disc. Possible";
            DocNo := StrSubstNo('%1;%2', DocNo, CustLedgEntry[i]."Document No.");
        end;

        WriteCAMTStmtLine(OutStream, CustLedgEntry[FromPos]."Posting Date", DocNo, Total, '');
    end;

    local procedure CreateSalesInvoiceAndPost(var Cust: Record Customer; var CustLedgEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Cust."No.");
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);

        CustLedgEntry.SetRange("Customer No.", Cust."No.");
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetRange("Document No.", LibrarySales.PostSalesDocument(SalesHeader, true, true));
        CustLedgEntry.FindFirst();

        CustLedgEntry.CalcFields("Remaining Amount");
    end;

    local procedure VerifyPrePost(BankAccRecon: Record "Bank Acc. Reconciliation"; var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        AppliedPmtEntry: Record "Applied Payment Entry";
    begin
        PmtReconJnl.First();
        repeat
            PmtReconJnl."Statement Amount".AssertEquals(PmtReconJnl."Applied Amount".AsDecimal());
            PmtReconJnl.Difference.AssertEquals(0);
        until not PmtReconJnl.Next();

        BankAccReconLine.LinesExist(BankAccRecon);
        repeat
            AppliedPmtEntry.FilterAppliedPmtEntry(BankAccReconLine);
            Assert.AreEqual(AppliedPmtEntry.Count, BankAccReconLine."Applied Entries", 'Checkiing the Applied Entries field on Tab273');
        until BankAccReconLine.Next() = 0;
    end;

    local procedure VerifyCustLedgEntry(CustNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetRange("Customer No.", CustNo);
        CustLedgEntry.SetRange(Open, true);
        Assert.IsTrue(CustLedgEntry.IsEmpty, 'All entries are closed')
    end;

    local procedure VerifyBankLedgEntry(BankAccNo: Code[20]; ExpAmt: Decimal)
    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        TotalAmt: Decimal;
    begin
        BankAccLedgEntry.SetRange("Bank Account No.", BankAccNo);
        BankAccLedgEntry.FindSet();
        repeat
            TotalAmt += BankAccLedgEntry.Amount;
        until BankAccLedgEntry.Next() = 0;

        Assert.AreEqual(ExpAmt, TotalAmt, '')
    end;

    local procedure UpdateCustPostingGrp()
    var
        CustPostingGroup: Record "Customer Posting Group";
        GLAcc: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAcc);
        if CustPostingGroup.FindSet() then
            repeat
                if CustPostingGroup."Payment Disc. Debit Acc." = '' then begin
                    CustPostingGroup.Validate("Payment Disc. Debit Acc.", GLAcc."No.");
                    CustPostingGroup.Modify(true);
                end;
                if CustPostingGroup."Payment Disc. Credit Acc." = '' then begin
                    CustPostingGroup.Validate("Payment Disc. Credit Acc.", GLAcc."No.");
                    CustPostingGroup.Modify(true);
                end;
            until CustPostingGroup.Next() = 0;
    end;

    local procedure UpdateBankAccRecStmEndingBalance(var BankAccRecon: Record "Bank Acc. Reconciliation"; NewStmEndingBalance: Decimal)
    begin
        BankAccRecon.Validate("Statement Ending Balance", NewStmEndingBalance);
        BankAccRecon.Modify();
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Payment Recon. E2E Tests Perf.");

        if Initialized then
            exit;
        Initialized := true;
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        UpdateCustPostingGrp();
        Commit();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(MsgTxt: Text)
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        if (Question.Contains(OpenBankStatementPageQst)) then
            Reply := false
        else
            Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PmtApplnToCustHandler(var PmtAppln: TestPage "Payment Application")
    begin
        // Remove Entry is not the same customer
        if PmtAppln.AppliedAmount.AsDecimal() <> 0 then
            if PmtAppln."Account No.".Value <> GlobalCustLedgEntry."Customer No." then begin
                PmtAppln.Applied.SetValue(false);
                PmtAppln.Next();
            end;
        // Go to the first and check that it is the customer and scroll down to find the entry
        if PmtAppln.Applied.AsBoolean() then begin
            PmtAppln.RelatedPartyOpenEntries.Invoke();
            while PmtAppln.Next() and (PmtAppln.TotalRemainingAmount.AsDecimal() <> 0) do begin
                PmtAppln.Applied.SetValue(true);
                PmtAppln.RemainingAmountAfterPosting.AssertEquals(0);
            end;
        end;

        PmtAppln.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndReconcilePageHandler(var PostPmtsAndRecBankAcc: TestPage "Post Pmts and Rec. Bank Acc.")
    begin
        PostPmtsAndRecBankAcc.OK().Invoke();
    end;
}

