codeunit 147201 "ERM VAT Sales Ledger Corr."
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        VATLedgerLineCntErr: Label 'VAT Ledger lines count is incorrect';
        LibraryPurchase: Codeunit "Library - Purchase";
        UnitPrice: Decimal;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure SC1_InvCorrInv()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateInvoice(SalesHeader, CalcDate('<CQ-1D>', WorkDate()), CustNo);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2_InvCorrCrMemo()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<CQ-1D>', WorkDate()), CustNo);
        UpdateInclInPurchVATLedger(SalesHeader, true);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);

        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, CustNo, false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, CustNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3_InvCorrInvDiffPeriod()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateInvoice(SalesHeader, CalcDate('<CQ+1D>', WorkDate()), CustNo);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);

        StartDate := CalcDate('<-CQ>', CalcDate('<CQ+1D>', WorkDate()));
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC4_InvCorrCrMemoDiffPeriod()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<CQ+1D>', WorkDate()), CustNo);
        UpdateInclInPurchVATLedger(SalesHeader, true);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);

        StartDate := CalcDate('<-CQ>', CalcDate('<CQ+1D>', WorkDate()));
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, '', false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, CustNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC5_InvTwoCorrInv()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateInvoice(SalesHeader, CalcDate('<1D>', WorkDate()), CustNo);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateInvoice(SalesHeader, CalcDate('<10D>', WorkDate()), CustNo);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6_InvTwoCorrCrMemo()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<1D>', WorkDate()), CustNo);
        UpdateInclInPurchVATLedger(SalesHeader, true);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<10D>', WorkDate()), CustNo);
        UpdateInclInPurchVATLedger(SalesHeader, true);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::"Credit Memo", PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);

        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, '', false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, CustNo, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7_InvCorrInvCorrCrMemo()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateInvoice(SalesHeader, CalcDate('<1D>', WorkDate()), CustNo);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<10D>', WorkDate()), CustNo);
        UpdateInclInPurchVATLedger(SalesHeader, true);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 2);

        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, '', false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, CustNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC8_InvCorrInvCorrCrMemoDP()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateInvoice(SalesHeader, CalcDate('<1D>', WorkDate()), CustNo);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<CQ+1D>', WorkDate()), CustNo);
        UpdateInclInPurchVATLedger(SalesHeader, true);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 2);

        StartDate := CalcDate('<CQ+1D>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, '', false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, CustNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC9_InvCorrCrMemoCorrInvDP()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<1D>', WorkDate()), CustNo);
        UpdateInclInPurchVATLedger(SalesHeader, true);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateInvoice(SalesHeader, CalcDate('<CQ+1D>', WorkDate()), CustNo);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::"Credit Memo", PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);

        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, '', false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, CustNo, 1);

        StartDate := CalcDate('<CQ+1D>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC10_InvCorrCrMemoDP()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<CQ+1D>', WorkDate()), CustNo);
        UpdateAddVATLedgSheet(SalesHeader, true);
        UpdateCorrDocDate(SalesHeader, WorkDate());
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);

        LibrarySales.CreateSalesVATLedgerAddSheet(VATLedgerCode);
        VerifySalesVATLedgerAddLineCnt(VATLedgerCode, CustNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC11_InvRevCrMemoRevInvDP()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<CQ-1D>', WorkDate()), CustNo);
        UpdateRevisionInfo(SalesHeader, true, PostedDocNo, 'CrMemoRev1');
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice / 2);
        PostSalesDoc(SalesHeader);

        CreateInvoice(SalesHeader, CalcDate('<CQ+1D>', WorkDate()), CustNo);
        UpdateRevisionInfo(SalesHeader, true, PostedDocNo, 'InvRev1');
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice * 2);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 2);

        StartDate := CalcDate('<-CQ>', CalcDate('<CQ+1D>', WorkDate()));
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC12_InvRevCrMemoRevInvDPAddSh()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<CQ+1D>', WorkDate()), CustNo);
        UpdateAddVATLedgSheet(SalesHeader, true);
        UpdateCorrDocDate(SalesHeader, WorkDate());
        UpdateRevisionInfo(SalesHeader, true, PostedDocNo, 'CrMemoRev1');
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice / 2);
        PostSalesDoc(SalesHeader);

        CreateInvoice(SalesHeader, CalcDate('<CQ+2D>', WorkDate()), CustNo);
        UpdateRevisionInfo(SalesHeader, true, PostedDocNo, 'InvRev1');
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice * 2);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        LibrarySales.CreateSalesVATLedgerAddSheet(VATLedgerCode);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);
        VerifySalesVATLedgerAddLineCnt(VATLedgerCode, CustNo, 1);

        StartDate := CalcDate('<-CQ>', CalcDate('<CQ+1D>', WorkDate()));
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS_325343()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: array[4] of Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo[1] := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<CQ+1D>', WorkDate()), CustNo);
        UpdateInclInPurchVATLedger(SalesHeader, true);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo[1]);
        CreateSalesCorrLine(SalesHeader);
        PostedDocNo[2] := PostSalesDoc(SalesHeader);

        CreateInvoice(SalesHeader, CalcDate('<CQ+2D>', WorkDate()), CustNo);
        UpdateRevisionInfo(SalesHeader, false, PostedDocNo[2], 'Rev2');
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo[3] := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<CQ+3D>', WorkDate()), CustNo);
        UpdateInclInPurchVATLedger(SalesHeader, true);
        UpdateRevisionInfo(SalesHeader, false, PostedDocNo[2], 'Rev2');
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo[4] := PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', CalcDate('<CQ+1D>', WorkDate()));
        EndDate := CalcDate('<CQ>', StartDate);

        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, CustNo, false, true);
        VerifyCrMemoPurchVATLedgerLine(
          VATLedgerCode, CustNo,
          PostedDocNo[1], WorkDate(), PostedDocNo[2], CalcDate('<CQ+1D>', WorkDate()), '', 0D, '', 0D);
        VerifyCrMemoPurchVATLedgerLine(
          VATLedgerCode, CustNo,
          PostedDocNo[1], WorkDate(), PostedDocNo[2], CalcDate('<CQ+1D>', WorkDate()), '', 0D, 'Rev2', CalcDate('<CQ+3D>', WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInSamePeriod()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PrepmtInvDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        ReleaseInvoice(SalesHeader);
        CreatePostPrepmt(CalcDate('<CQ+10D>', WorkDate()), CustNo, SalesHeader."No.");
        PrepmtInvDocNo := GetLastPrepmtInvoice(CustNo);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ+1M>', StartDate);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifyPrepmtInvVATLedgerLine(
          VATLedgerCode, CustNo,
          PrepmtInvDocNo, CalcDate('<CQ+10D>', WorkDate()), '', 0D, '', 0D, '', 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInOtherPeriod()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PrepmtInvDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        ReleaseInvoice(SalesHeader);
        CreatePostPrepmt(CalcDate('<-1M>', WorkDate()), CustNo, SalesHeader."No.");
        PrepmtInvDocNo := GetLastPrepmtInvoice(CustNo);

        StartDate := CalcDate('<-CM-1M>', WorkDate());
        EndDate := CalcDate('<-CM-1D>', WorkDate());

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifyPrepmtInvVATLedgerLine(
          VATLedgerCode, CustNo,
          PrepmtInvDocNo, CalcDate('<-1M>', WorkDate()), '', 0D, '', 0D, '', 0D);
    end;

    local procedure UpdateCorrectionInfo(var SalesHeader: Record "Sales Header"; CorrDocType: Option; CorrDocNo: Code[20])
    begin
        SalesHeader.Validate("Corrective Document", true);
        SalesHeader.Validate("Corrective Doc. Type", SalesHeader."Corrective Doc. Type"::Correction);
        SalesHeader.Validate("Corrected Doc. Type", CorrDocType);
        SalesHeader.Validate("Corrected Doc. No.", CorrDocNo);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateRevisionInfo(var SalesHeader: Record "Sales Header"; IsCorrInvoice: Boolean; CorrDocNo: Code[20]; RevisionNo: Code[20])
    begin
        SalesHeader.Validate("Corrective Document", true);
        SalesHeader.Validate("Corrective Doc. Type", SalesHeader."Corrective Doc. Type"::Revision);
        if IsCorrInvoice then
            SalesHeader.Validate("Corrected Doc. Type", SalesHeader."Corrected Doc. Type"::Invoice)
        else
            SalesHeader.Validate("Corrected Doc. Type", SalesHeader."Corrected Doc. Type"::"Credit Memo");
        SalesHeader.Validate("Corrected Doc. No.", CorrDocNo);
        SalesHeader.Validate("Revision No.", RevisionNo);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateInclInPurchVATLedger(var SalesHeader: Record "Sales Header"; IsIncludeInSalesVATLedger: Boolean)
    begin
        SalesHeader.Validate("Include In Purch. VAT Ledger", IsIncludeInSalesVATLedger);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateAddVATLedgSheet(var SalesHeader: Record "Sales Header"; IsAddVATLedgetSheet: Boolean)
    begin
        SalesHeader.Validate("Additional VAT Ledger Sheet", IsAddVATLedgetSheet);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateCorrDocDate(var SalesHeader: Record "Sales Header"; CorrDocDate: Date)
    begin
        SalesHeader.Validate("Corrected Document Date", CorrDocDate);
        SalesHeader.Modify(true);
    end;

    local procedure PostSalesDoc(SalesHeader: Record "Sales Header"): Code[20]
    begin
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostPrepmt(PostingDate: Date; CustNo: Code[20]; PrepmtDocNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustNo, 0);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate(Prepayment, true);
        GenJournalLine."External Document No." := LibraryUtility.GenerateGUID();
        GenJournalLine.Validate("Prepayment Document No.", PrepmtDocNo);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateInvoice(var SalesHeader: Record "Sales Header"; PostingDate: Date; CustNo: Code[20])
    begin
        CreateSalesDoc(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          PostingDate, CustNo);
    end;

    local procedure CreateCrMemo(var SalesHeader: Record "Sales Header"; PostingDate: Date; CustNo: Code[20])
    begin
        CreateSalesDoc(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo",
          PostingDate, CustNo);
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; PostingDate: Date; CustNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustNo);
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; GLAccountNo: Code[20]; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, 1);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify();
    end;

    local procedure CreateSalesCorrLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        SalesInvLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        CorrDocMgt: Codeunit "Corrective Document Mgt.";
    begin
        case SalesHeader."Corrected Doc. Type" of
            SalesHeader."Corrected Doc. Type"::Invoice:
                begin
                    SalesInvLine.Reset();
                    SalesInvLine.SetRange("Document No.", SalesHeader."Corrected Doc. No.");
                    SalesInvLine.FindFirst();
                    CorrDocMgt.SetSalesHeader(SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
                    CorrDocMgt.SetCorrectionType(0);
                    CorrDocMgt.CreateSalesLinesFromPstdInv(SalesInvLine);
                end;
            SalesHeader."Corrected Doc. Type"::"Credit Memo":
                begin
                    SalesCrMemoLine.Reset();
                    SalesCrMemoLine.SetRange("Document No.", SalesHeader."Corrected Doc. No.");
                    SalesCrMemoLine.FindFirst();
                    CorrDocMgt.SetSalesHeader(SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
                    CorrDocMgt.SetCorrectionType(0);
                    CorrDocMgt.CreateSalesLinesFromPstdCrMemo(SalesCrMemoLine);
                end;
        end;
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Invoice:
                begin
                    SalesLine.Validate("Unit Price (After)", SalesLine."Unit Price (Before)" + 250);
                    SalesLine.Modify();
                end;
            SalesHeader."Document Type"::"Credit Memo":
                begin
                    SalesLine.Validate("Unit Price (After)", SalesLine."Unit Price (Before)" - 250);
                    SalesLine.Modify();
                end;
        end;
    end;

    local procedure ReleaseInvoice(var SalesHeader: Record "Sales Header")
    var
        ReleaseDoc: Codeunit "Release Sales Document";
    begin
        ReleaseDoc.PerformManualRelease(SalesHeader);
    end;

    local procedure GetLastPrepmtInvoice(CustNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Bill-to Customer No.", CustNo);
        SalesInvoiceHeader.SetRange("Prepayment Invoice", true);
        SalesInvoiceHeader.FindLast();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure VerifyPurchVATLedgerLineCnt(VATLedgerCode: Code[20]; CustNo: Code[20]; ExpectedCnt: Integer)
    var
        VATLedger: Record "VAT Ledger";
    begin
        VATLedger.Get(VATLedger.Type::Purchase, VATLedgerCode);
        VerifyVATLedgerLineCnt(false, VATLedger.Type, VATLedgerCode, CustNo, ExpectedCnt);
    end;

    local procedure VerifySalesVATLedgerLineCnt(VATLedgerCode: Code[20]; CustNo: Code[20]; ExpectedCnt: Integer)
    var
        VATLedger: Record "VAT Ledger";
    begin
        VATLedger.Get(VATLedger.Type::Sales, VATLedgerCode);
        VerifyVATLedgerLineCnt(false, VATLedger.Type, VATLedgerCode, CustNo, ExpectedCnt);
    end;

    local procedure VerifyPrepmtInvVATLedgerLine(VATLedgerCode: Code[20]; VendorNo: Code[20]; DocNo: Code[20]; DocDate: Date; CorrNo: Code[20]; CorrDate: Date; RevNo: Code[20]; RevDate: Date; RevOfCorrNo: Code[20]; RevOfCorrDate: Date)
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VerifyDocVATLedgerLine(
          false, VATLedgerLine.Type::Sales, VATLedgerCode, VendorNo,
          VATLedgerLine."Document Type"::Invoice, DocNo, DocDate, true,
          CorrNo, CorrDate, RevNo, RevDate, RevOfCorrNo, RevOfCorrDate);
    end;

    local procedure VerifySalesVATLedgerAddLineCnt(VATLedgerCode: Code[20]; CustNo: Code[20]; ExpectedCnt: Integer)
    var
        VATLedger: Record "VAT Ledger";
    begin
        VATLedger.Get(VATLedger.Type::Sales, VATLedgerCode);
        VerifyVATLedgerLineCnt(true, VATLedger.Type, VATLedgerCode, CustNo, ExpectedCnt);
    end;

    local procedure VerifyVATLedgerLineCnt(IsAddSheet: Boolean; VATLEdgerType: Option; VATLedgerCode: Code[20]; CVNo: Code[20]; ExpectedCnt: Integer)
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VATLedgerLine.SetRange(Type, VATLEdgerType);
        VATLedgerLine.SetRange("Additional Sheet", IsAddSheet);
        VATLedgerLine.SetRange(Code, VATLedgerCode);
        VATLedgerLine.SetRange("C/V No.", CVNo);
        Assert.AreEqual(ExpectedCnt, VATLedgerLine.Count, VATLedgerLineCntErr);
    end;

    local procedure VerifyCrMemoPurchVATLedgerLine(VATLedgerCode: Code[20]; VendorNo: Code[20]; DocNo: Code[20]; DocDate: Date; CorrNo: Code[20]; CorrDate: Date; RevNo: Code[20]; RevDate: Date; RevOfCorrNo: Code[20]; RevOfCorrDate: Date)
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VerifyDocVATLedgerLine(
          false, VATLedgerLine.Type::Purchase, VATLedgerCode, VendorNo,
          VATLedgerLine."Document Type"::"Credit Memo", DocNo, DocDate, false,
          CorrNo, CorrDate, RevNo, RevDate, RevOfCorrNo, RevOfCorrDate);
    end;

    local procedure VerifyDocVATLedgerLine(IsAddSheet: Boolean; VATLEdgerType: Option; VATLedgerCode: Code[20]; CVNo: Code[20]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; DocDate: Date; IsPrepmt: Boolean; CorrNo: Code[20]; CorrDate: Date; RevNo: Code[20]; RevDate: Date; RevOfCorrNo: Code[20]; RevOfCorrDate: Date)
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VATLedgerLine.SetRange(Type, VATLEdgerType);
        VATLedgerLine.SetRange("Additional Sheet", IsAddSheet);
        VATLedgerLine.SetRange(Code, VATLedgerCode);
        VATLedgerLine.SetRange("C/V No.", CVNo);
        VATLedgerLine.SetRange("Document Type", DocType);
        VATLedgerLine.SetRange("Document No.", DocNo);
        VATLedgerLine.SetRange("Document Date", DocDate);
        VATLedgerLine.SetRange(Prepayment, IsPrepmt);
        VATLedgerLine.SetRange("Correction No.", CorrNo);
        VATLedgerLine.SetRange("Correction Date", CorrDate);
        VATLedgerLine.SetRange("Revision No.", RevNo);
        VATLedgerLine.SetRange("Revision Date", RevDate);
        VATLedgerLine.SetRange("Revision of Corr. No.", RevOfCorrNo);
        VATLedgerLine.SetRange("Revision of Corr. Date", RevOfCorrDate);
        VATLedgerLine.FindFirst();
    end;

    local procedure CreateCustomerGLAccount(var CustomerNo: Code[20]; var GLAccountNo: Code[20])
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
    end;

    local procedure Initialize()
    var
        LibraryRandom: Codeunit "Library - Random";
    begin
        if IsInitialized then
            exit;

        UnitPrice := LibraryRandom.RandDec(10000, 2);

        IsInitialized := true;
    end;
}

