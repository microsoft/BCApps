codeunit 147200 "ERM VAT Purchase Ledger Corr."
{
    // // [FEATURE] [VAT Purchase Ledger]
    TestPermissions = NonRestrictive;
    Subtype = Test;
    Permissions = tabledata "VAT Entry Type" = imd,
                  tabledata "Cust. Ledger Entry" = imd,
                  tabledata "Vendor Ledger Entry" = imd;

    var
        Assert: Codeunit Assert;
        LibraryPurch: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        VATLedgerLineCntErr: Label 'VAT Ledger lines count is incorrect';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        UnitPrice: Decimal;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure SC1_InvCorrInv()
    var
        PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateVendorGLAccount(VendorNo, GLAccountNo);

        CreateInvoice(
          PurchHeader, WorkDate(), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::" ", '', '');
        PostedDocNo := PostPurchDoc(PurchHeader);

        CreateInvoice(
          PurchHeader, CalcDate('<CQ-1D>', WorkDate()), VendorNo, GLAccountNo, UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice,
          PostedDocNo, '');
        PostPurchDoc(PurchHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);

        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, VendorNo, false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, VendorNo, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2_InvCorrCrMemo()
    var
        PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateVendorGLAccount(VendorNo, GLAccountNo);

        CreateInvoice(
          PurchHeader, WorkDate(), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::" ", '', '');
        PostedDocNo := PostPurchDoc(PurchHeader);

        CreateCrMemo(
          PurchHeader, CalcDate('<CQ-1D>', WorkDate()), VendorNo, GLAccountNo, UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice,
          PostedDocNo, '');
        UpdateInclInSalesVATLedger(PurchHeader, true);
        PostPurchDoc(PurchHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);

        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, VendorNo, false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, VendorNo, 1);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, '');
        VerifySalesVATLedgerLineCnt(VATLedgerCode, VendorNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3_InvCorrInvDiffPeriod()
    var
        PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateVendorGLAccount(VendorNo, GLAccountNo);

        CreateInvoice(
          PurchHeader, WorkDate(), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::" ", '', '');
        PostedDocNo := PostPurchDoc(PurchHeader);

        CreateInvoice(
          PurchHeader, CalcDate('<CQ+1D>', WorkDate()), VendorNo, GLAccountNo, UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice,
          PostedDocNo, '');
        PostPurchDoc(PurchHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, VendorNo, false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, VendorNo, 1);

        StartDate := CalcDate('<CQ+1D>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, VendorNo, false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, VendorNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC4_InvCorrCrMemoDiffPeriod()
    var
        PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateVendorGLAccount(VendorNo, GLAccountNo);

        CreateInvoice(
          PurchHeader, WorkDate(), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::" ", '', '');
        PostedDocNo := PostPurchDoc(PurchHeader);

        CreateCrMemo(
          PurchHeader, CalcDate('<CQ+1D>', WorkDate()), VendorNo, GLAccountNo, UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice,
          PostedDocNo, '');
        UpdateInclInSalesVATLedger(PurchHeader, true);
        PostPurchDoc(PurchHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, VendorNo, false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, VendorNo, 1);

        StartDate := CalcDate('<CQ+1D>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, '');
        VerifySalesVATLedgerLineCnt(VATLedgerCode, VendorNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC5_InvTwoCorrInv()
    var
        PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateVendorGLAccount(VendorNo, GLAccountNo);

        CreateInvoice(
          PurchHeader, WorkDate(), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::" ", '', '');
        PostedDocNo := PostPurchDoc(PurchHeader);

        CreateInvoice(
          PurchHeader, CalcDate('<1D>', WorkDate()), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice, PostedDocNo, '');
        PostedDocNo := PostPurchDoc(PurchHeader);

        CreateInvoice(
          PurchHeader, CalcDate('<3D>', WorkDate()), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice, PostedDocNo, '');
        PostPurchDoc(PurchHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, VendorNo, false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, VendorNo, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6_InvTwoCorrCrMemo()
    var
        PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateVendorGLAccount(VendorNo, GLAccountNo);

        CreateInvoice(
          PurchHeader, WorkDate(), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::" ", '', '');
        PostedDocNo := PostPurchDoc(PurchHeader);

        CreateCrMemo(
          PurchHeader, CalcDate('<1D>', WorkDate()), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice, PostedDocNo, '');
        UpdateInclInSalesVATLedger(PurchHeader, true);
        PostedDocNo := PostPurchDoc(PurchHeader);

        CreateCrMemo(
          PurchHeader, CalcDate('<3D>', WorkDate()), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::"Credit Memo", PostedDocNo, '');
        UpdateInclInSalesVATLedger(PurchHeader, true);
        PostPurchDoc(PurchHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);

        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, VendorNo, false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, VendorNo, 1);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, '');
        VerifySalesVATLedgerLineCnt(VATLedgerCode, VendorNo, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7_InvCorrInvCorrCrMemo()
    var
        PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateVendorGLAccount(VendorNo, GLAccountNo);

        CreateInvoice(
          PurchHeader, WorkDate(), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::" ", '', '');
        PostedDocNo := PostPurchDoc(PurchHeader);

        CreateInvoice(
          PurchHeader, CalcDate('<1D>', WorkDate()), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice, PostedDocNo, '');
        PostedDocNo := PostPurchDoc(PurchHeader);

        CreateCrMemo(
          PurchHeader, CalcDate('<3D>', WorkDate()), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice, PostedDocNo, '');
        UpdateInclInSalesVATLedger(PurchHeader, true);
        PostPurchDoc(PurchHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);

        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, VendorNo, false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, VendorNo, 2);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, '');
        VerifySalesVATLedgerLineCnt(VATLedgerCode, VendorNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC8_InvCorrInvCorrCrMemoDP()
    var
        PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateVendorGLAccount(VendorNo, GLAccountNo);

        CreateInvoice(
          PurchHeader, WorkDate(), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::" ", '', '');
        PostedDocNo := PostPurchDoc(PurchHeader);

        CreateInvoice(
          PurchHeader, CalcDate('<1D>', WorkDate()), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice, PostedDocNo, '');
        PostedDocNo := PostPurchDoc(PurchHeader);

        CreateCrMemo(
          PurchHeader, CalcDate('<CQ+1D>', WorkDate()), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice, PostedDocNo, '');
        UpdateInclInSalesVATLedger(PurchHeader, true);
        PostPurchDoc(PurchHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, VendorNo, false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, VendorNo, 2);

        StartDate := CalcDate('<CQ+1D>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, '');
        VerifySalesVATLedgerLineCnt(VATLedgerCode, VendorNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC9_InvCorrCrMemoCorrInvDP()
    var
        PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateVendorGLAccount(VendorNo, GLAccountNo);

        CreateInvoice(
          PurchHeader, WorkDate(), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::" ", '', '');
        PostedDocNo := PostPurchDoc(PurchHeader);

        CreateCrMemo(
          PurchHeader, CalcDate('<1D>', WorkDate()), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice, PostedDocNo, '');
        UpdateInclInSalesVATLedger(PurchHeader, true);
        PostedDocNo := PostPurchDoc(PurchHeader);

        CreateInvoice(
          PurchHeader, CalcDate('<CQ+1D>', WorkDate()), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::"Credit Memo", PostedDocNo, '');
        PostPurchDoc(PurchHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);

        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, VendorNo, false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, VendorNo, 1);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, '');
        VerifySalesVATLedgerLineCnt(VATLedgerCode, VendorNo, 1);

        StartDate := CalcDate('<CQ+1D>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, VendorNo, false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, VendorNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC10_InvCorrCrMemoDP()
    var
        PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateVendorGLAccount(VendorNo, GLAccountNo);

        CreateInvoice(
          PurchHeader, WorkDate(), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::" ", '', '');
        PostedDocNo := PostPurchDoc(PurchHeader);

        CreateCrMemo(
          PurchHeader, CalcDate('<CQ+1D>', WorkDate()), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice, PostedDocNo, '');
        UpdateAddVATLedgSheet(PurchHeader, true);
        UpdateCorrDocDate(PurchHeader, WorkDate());
        PostPurchDoc(PurchHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);

        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, VendorNo, false, true);
        // VerifyPurchVATLedgerLineCnt(VATLedgerCode,VendorNo,1);

        LibraryPurchase.CreatePurchaseVATLedgerAddSheet(VATLedgerCode, 2);
        // VerifyPurchVATLedgerAddLineCnt(VATLedgerCode,VendorNo,1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC11_InvRevCrMemoRevInvDP()
    var
        PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateVendorGLAccount(VendorNo, GLAccountNo);

        CreateInvoice(
          PurchHeader, WorkDate(), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::" ", '', '');
        PostedDocNo := PostPurchDoc(PurchHeader);

        CreateCrMemo(
          PurchHeader, CalcDate('<CQ>', WorkDate()), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice, PostedDocNo, 'CrMemoRev1');
        PostPurchDoc(PurchHeader);

        CreateInvoice(
          PurchHeader, CalcDate('<CQ+1D>', WorkDate()), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice, PostedDocNo, 'InvRev1');
        PostPurchDoc(PurchHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, VendorNo, false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, VendorNo, 2);

        StartDate := CalcDate('<CQ+1D>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, VendorNo, false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, VendorNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC12_InvRevCrMemoRevInvDPAddSh()
    var
        PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateVendorGLAccount(VendorNo, GLAccountNo);

        CreateInvoice(
          PurchHeader, WorkDate(), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::" ", '', '');
        PostedDocNo := PostPurchDoc(PurchHeader);

        CreateCrMemo(
          PurchHeader, CalcDate('<CQ+1D>', WorkDate()), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice, PostedDocNo, 'CrMemoRev1');
        UpdateAddVATLedgSheet(PurchHeader, true);
        UpdateCorrDocDate(PurchHeader, WorkDate());
        PostPurchDoc(PurchHeader);

        CreateInvoice(
          PurchHeader, CalcDate('<CQ+2D>', WorkDate()), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice, PostedDocNo, 'InvRev1');
        PostPurchDoc(PurchHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, VendorNo, false, true);
        LibraryPurchase.CreatePurchaseVATLedgerAddSheet(VATLedgerCode, 0);
        // VerifyPurchVATLedgerLineCnt(VATLedgerCode,VendorNo,1);
        // VerifyPurchVATLedgerAddLineCnt(VATLedgerCode,VendorNo,1);

        StartDate := CalcDate('<-CQ>', CalcDate('<CQ+1D>', WorkDate()));
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, VendorNo, false, true);
        // VerifyPurchVATLedgerLineCnt(VATLedgerCode,VendorNo,1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS_339772()
    var
        PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateVendorGLAccount(VendorNo, GLAccountNo);

        CreateInvoice(
          PurchHeader, WorkDate(), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::" ", '', '');
        PostPurchDoc(PurchHeader);

        CreateCrMemo(
          PurchHeader, WorkDate(), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::" ", '', '');
        PostPurchDoc(PurchHeader);

        CreateInvoice(
          PurchHeader, WorkDate(), VendorNo, GLAccountNo,
          UnitPrice * 2, PurchHeader."Corrected Doc. Type"::" ", '', '');
        UpdateVATInvoiceInfo(PurchHeader, Format(WorkDate()), WorkDate(), WorkDate());
        PostPurchDoc(PurchHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, VendorNo, true, true);

        VerifyPurchVATLedgerLineCnt(VATLedgerCode, VendorNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS_339699()
    var
        PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateVendorGLAccount(VendorNo, GLAccountNo);

        CreateInvoice(
          PurchHeader, WorkDate(), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::" ", '', '');
        UpdateVATInvoiceInfo(PurchHeader, Format(WorkDate()), WorkDate(), WorkDate());
        PostedDocNo := PostPurchDoc(PurchHeader);

        CreateCrMemo(
          PurchHeader, CalcDate('<1D>', WorkDate()), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::" ", '', '');
        UpdateVATInvoiceInfo(PurchHeader, Format(WorkDate()), CalcDate('<1D>', WorkDate()), CalcDate('<1D>', WorkDate()));
        PostPurchDoc(PurchHeader);

        CreateInvoice(
          PurchHeader, CalcDate('<1D>', WorkDate()), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice, PostedDocNo, '1');
        UpdateVATInvoiceInfo(PurchHeader, Format(WorkDate()), CalcDate('<1D>', WorkDate()), CalcDate('<1D>', WorkDate()));
        PostPurchDoc(PurchHeader);

        StartDate := CalcDate('<-CM>', WorkDate());
        EndDate := CalcDate('<CM>', StartDate);
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, VendorNo, true, true);

        VerifyInvPurchVATLedgerLine(
          VATLedgerCode, VendorNo,
          Format(WorkDate()), WorkDate(), '', 0D, '', 0D, '', 0D);
        VerifyCrMemoPurchVATLedgerLine(
          VATLedgerCode, VendorNo,
          Format(WorkDate()), CalcDate('<1D>', WorkDate()), '', 0D, '', 0D, '', 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS_339700()
    var
        PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
        NewDate: Date;
    begin
        Initialize();
        CreateVendorGLAccount(VendorNo, GLAccountNo);

        CreateInvoice(
          PurchHeader, WorkDate(), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::" ", '', '');
        UpdateVATInvoiceInfo(PurchHeader, Format(WorkDate()), WorkDate(), WorkDate());
        PostedDocNo := PostPurchDoc(PurchHeader);

        NewDate := CalcDate('<1D>', WorkDate());
        CreateInvoice(
          PurchHeader, NewDate, VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice, PostedDocNo, '');
        UpdateVATInvoiceInfo(PurchHeader, Format(NewDate), NewDate, NewDate);
        PostPurchDoc(PurchHeader);

        StartDate := CalcDate('<-CM>', WorkDate());
        EndDate := CalcDate('<CM>', StartDate);
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, VendorNo, true, true);

        VerifyInvPurchVATLedgerLine(
          VATLedgerCode, VendorNo,
          Format(WorkDate()), WorkDate(), '', 0D, '', 0D, '', 0D);
        VerifyInvPurchVATLedgerLine(
          VATLedgerCode, VendorNo,
          Format(WorkDate()), WorkDate(), Format(NewDate), NewDate, '', 0D, '', 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS_339701()
    var
        PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
        NewDate: Date;
    begin
        Initialize();
        CreateVendorGLAccount(VendorNo, GLAccountNo);

        CreateInvoice(
          PurchHeader, WorkDate(), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::" ", '', '');
        UpdateVATInvoiceInfo(PurchHeader, Format(WorkDate()), WorkDate(), WorkDate());
        PostedDocNo := PostPurchDoc(PurchHeader);

        NewDate := CalcDate('<1M>', WorkDate());
        CreateInvoice(
          PurchHeader, NewDate, VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice, PostedDocNo, '');
        UpdateVATInvoiceInfo(PurchHeader, Format(NewDate), NewDate, NewDate);
        UpdateCorrDocDate(PurchHeader, WorkDate());
        UpdateAddVATLedgSheet(PurchHeader, true);
        PostPurchDoc(PurchHeader);

        StartDate := CalcDate('<-CM>', WorkDate());
        EndDate := CalcDate('<CM>', StartDate);

        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, VendorNo, true, true);
        LibraryPurchase.CreatePurchaseVATLedgerAddSheet(VATLedgerCode, 0);

        VerifyInvPurchVATLedgerLine(
          VATLedgerCode, VendorNo,
          Format(WorkDate()), WorkDate(), '', 0D, '', 0D, '', 0D);
        VerifyInvPurchVATLedgerAddLine(
          VATLedgerCode, VendorNo,
          Format(WorkDate()), WorkDate(), Format(NewDate), NewDate, '', 0D, '', 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS_339703()
    var
        PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
        NewDate: Date;
    begin
        Initialize();
        CreateVendorGLAccount(VendorNo, GLAccountNo);

        CreateInvoice(
          PurchHeader, WorkDate(), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::" ", '', '');
        UpdateVATInvoiceInfo(PurchHeader, Format(WorkDate()), WorkDate(), WorkDate());
        PostedDocNo := PostPurchDoc(PurchHeader);

        NewDate := CalcDate('<1D>', WorkDate());
        CreateCrMemo(
          PurchHeader, NewDate, VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice, PostedDocNo, '');
        UpdateVATInvoiceInfo(PurchHeader, Format(NewDate), NewDate, NewDate);
        UpdateInclInSalesVATLedger(PurchHeader, true);
        PostPurchDoc(PurchHeader);

        StartDate := CalcDate('<-CM>', WorkDate());
        EndDate := CalcDate('<CM>', StartDate);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, '');
        VerifyCrMemoSalesVATLedgerLine(
          VATLedgerCode, VendorNo,
          Format(WorkDate()), WorkDate(), Format(NewDate), NewDate, '', 0D, '', 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS_339705()
    var
        PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
        NewDate: Date;
    begin
        Initialize();
        CreateVendorGLAccount(VendorNo, GLAccountNo);

        CreateInvoice(
          PurchHeader, WorkDate(), VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::" ", '', '');
        UpdateVATInvoiceInfo(PurchHeader, Format(WorkDate()), WorkDate(), WorkDate());
        PostedDocNo := PostPurchDoc(PurchHeader);

        NewDate := CalcDate('<1M>', WorkDate());
        CreateCrMemo(
          PurchHeader, NewDate, VendorNo, GLAccountNo,
          UnitPrice, PurchHeader."Corrected Doc. Type"::Invoice, PostedDocNo, '');
        UpdateVATInvoiceInfo(PurchHeader, Format(NewDate), NewDate, NewDate);
        UpdateInclInSalesVATLedger(PurchHeader, true);
        PostPurchDoc(PurchHeader);

        StartDate := CalcDate('<-CM>', NewDate);
        EndDate := CalcDate('<CM>', StartDate);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, '');
        VerifyCrMemoSalesVATLedgerLine(
          VATLedgerCode, VendorNo,
          Format(WorkDate()), WorkDate(), Format(NewDate), NewDate, '', 0D, '', 0D);
    end;

    [Test]
    [HandlerFunctions('VATEntryTypeHandler')]
    [Scope('OnPrem')]
    procedure TestVATEntryTypeSelection()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PurchaseOrderPage: TestPage "Purchase Order";
        SelectedVATEntryType: Variant;
    begin
        // Verify correctness of selection made on VAT Entry Type page
        Initialize();

        CreateVATEntryType(LibraryRandom.RandIntInRange(5, 10));
        LibraryPurch.CreateVendor(Vendor);
        LibraryPurch.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        PurchaseOrderPage.OpenEdit();
        PurchaseOrderPage.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrderPage."VAT Entry Type".Lookup();
        LibraryVariableStorage.Dequeue(SelectedVATEntryType);
        PurchaseOrderPage."VAT Entry Type".AssertEquals(Format(SelectedVATEntryType));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ChangeOpenCustLedgEntryVATEntryTypeUT()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VATEntryTypeCodeX: Code[2];
        VATEntryTypeCodeY: Code[2];
    begin
        // [FEATURE] [VAT Entry Type]
        // [SCENARIO 363180] Change VAT Entry Type in opened posted Customer Ledger Entry
        Initialize();
        // [GIVEN] Two VAT Entry Type - "X" and "Y"
        VATEntryTypeCodeX := CreateVATEntryTypeNo();
        VATEntryTypeCodeY := CreateVATEntryTypeNo();
        // [GIVEN] "Cust. Ledger Entry" with "VAT Entry Type" = "X" and "Open" = TRUE
        MockCustLedgEntry(CustLedgEntry, VATEntryTypeCodeX, true);
        // [WHEN] Execute "Cust. Entry-Edit" to set "VAT Entry Type" = "Y"
        CustLedgEntry."VAT Entry Type" := VATEntryTypeCodeY;
        CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry);
        // [THEN] "Cust. Ledger Entry"."VAT Entry Type" = "Y"
        CustLedgEntry.Get(CustLedgEntry."Entry No.");
        Assert.AreEqual(VATEntryTypeCodeY, CustLedgEntry."VAT Entry Type", CustLedgEntry.FieldCaption("VAT Entry Type"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ChangeOpenVendLedgEntryVATEntryTypeUT()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VATEntryTypeCodeX: Code[2];
        VATEntryTypeCodeY: Code[2];
    begin
        // [FEATURE] [VAT Entry Type]
        // [SCENARIO 363180] Change VAT Entry Type in opened posted Vendor Ledger Entry
        Initialize();
        // [GIVEN] Two VAT Entry Type - "X" and "Y"
        VATEntryTypeCodeX := CreateVATEntryTypeNo();
        VATEntryTypeCodeY := CreateVATEntryTypeNo();
        // [GIVEN] "Vendor Ledger Entry" with "VAT Entry Type" = "X" and "Open" = TRUE
        MockVendLedgEntry(VendLedgEntry, VATEntryTypeCodeX, true);
        // [WHEN] Execute "Vend. Entry-Edit" to set "VAT Entry Type" = "Y"
        VendLedgEntry."VAT Entry Type" := VATEntryTypeCodeY;
        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
        // [THEN] "Cust. Ledger Entry"."VAT Entry Type" = "Y"
        VendLedgEntry.Get(VendLedgEntry."Entry No.");
        Assert.AreEqual(VATEntryTypeCodeY, VendLedgEntry."VAT Entry Type", VendLedgEntry.FieldCaption("VAT Entry Type"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ChangeClosedCustLedgEntryVATEntryTypeUT()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VATEntryTypeCodeX: Code[2];
        VATEntryTypeCodeY: Code[2];
    begin
        // [FEATURE] [VAT Entry Type]
        // [SCENARIO 363458] Change VAT Entry Type in closed posted Customer Ledger Entry
        Initialize();
        // [GIVEN] Two VAT Entry Type - "X" and "Y"
        VATEntryTypeCodeX := CreateVATEntryTypeNo();
        VATEntryTypeCodeY := CreateVATEntryTypeNo();
        // [GIVEN] "Cust. Ledger Entry" with "VAT Entry Type" = "X" and "Open" = FALSE
        MockCustLedgEntry(CustLedgEntry, VATEntryTypeCodeX, false);
        // [WHEN] Execute "Cust. Entry-Edit" to set "VAT Entry Type" = "Y"
        CustLedgEntry."VAT Entry Type" := VATEntryTypeCodeY;
        CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry);
        // [THEN] "Cust. Ledger Entry"."VAT Entry Type" = "Y"
        CustLedgEntry.Get(CustLedgEntry."Entry No.");
        Assert.AreEqual(VATEntryTypeCodeY, CustLedgEntry."VAT Entry Type", CustLedgEntry.FieldCaption("VAT Entry Type"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ChangeClosedVendLedgEntryVATEntryTypeUT()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VATEntryTypeCodeX: Code[2];
        VATEntryTypeCodeY: Code[2];
    begin
        // [FEATURE] [VAT Entry Type]
        // [SCENARIO 363458] Change VAT Entry Type in closed posted Vendor Ledger Entry
        Initialize();
        // [GIVEN] Two VAT Entry Type - "X" and "Y"
        VATEntryTypeCodeX := CreateVATEntryTypeNo();
        VATEntryTypeCodeY := CreateVATEntryTypeNo();
        // [GIVEN] "Vendor Ledger Entry" with "VAT Entry Type" = "X" and "Open" = FALSE
        MockVendLedgEntry(VendLedgEntry, VATEntryTypeCodeX, false);
        // [WHEN] Execute "Vend. Entry-Edit" to set "VAT Entry Type" = "Y"
        VendLedgEntry."VAT Entry Type" := VATEntryTypeCodeY;
        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
        // [THEN] "Cust. Ledger Entry"."VAT Entry Type" = "Y"
        VendLedgEntry.Get(VendLedgEntry."Entry No.");
        Assert.AreEqual(VATEntryTypeCodeY, VendLedgEntry."VAT Entry Type", VendLedgEntry.FieldCaption("VAT Entry Type"));
    end;

    local procedure UpdateVATInvoiceInfo(var PurchHeader: Record "Purchase Header"; VATInvNo: Code[20]; VATInvDate: Date; VATInvRcvdDate: Date)
    begin
        PurchHeader.Validate("Vendor VAT Invoice No.", VATInvNo);
        PurchHeader.Validate("Vendor VAT Invoice Date", VATInvDate);
        PurchHeader.Validate("Vendor VAT Invoice Rcvd Date", VATInvRcvdDate);
        PurchHeader.Modify(true);
    end;

    local procedure UpdateCorrectionInfo(var PurchHeader: Record "Purchase Header"; CorrDocType: Option; CorrDocNo: Code[20]; RevisionNo: Code[20])
    begin
        if CorrDocNo = '' then
            exit;
        PurchHeader.Validate("Corrective Document", true);
        PurchHeader.Validate("Corrective Doc. Type", PurchHeader."Corrective Doc. Type"::Correction);
        PurchHeader.Validate("Corrected Doc. Type", CorrDocType);
        PurchHeader.Validate("Corrected Doc. No.", CorrDocNo);
        if RevisionNo <> '' then
            PurchHeader.Validate("Revision No.", RevisionNo);
        PurchHeader.Modify(true);
    end;

    local procedure UpdateInclInSalesVATLedger(var PurchHeader: Record "Purchase Header"; IsIncludeInSalesVATLedger: Boolean)
    begin
        PurchHeader.Validate("Include In Sales VAT Ledger", IsIncludeInSalesVATLedger);
        PurchHeader.Modify(true);
    end;

    local procedure UpdateAddVATLedgSheet(var PurchHeader: Record "Purchase Header"; IsAddVATLedgetSheet: Boolean)
    begin
        PurchHeader.Validate("Additional VAT Ledger Sheet", IsAddVATLedgetSheet);
        PurchHeader.Modify(true);
    end;

    local procedure UpdateCorrDocDate(var PurchHeader: Record "Purchase Header"; CorrDocDate: Date)
    begin
        PurchHeader.Validate("Corrected Document Date", CorrDocDate);
        PurchHeader.Modify(true);
    end;

    local procedure PostPurchDoc(PurchHeader: Record "Purchase Header"): Code[20]
    begin
        exit(LibraryPurch.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CreateInvoice(var PurchHeader: Record "Purchase Header"; PostingDate: Date; VendorNo: Code[20]; GLAccountNo: Code[20]; DirectUnitCost: Decimal; CorrDocType: Option; CorrDocNo: Code[20]; RevisionNo: Code[20])
    begin
        CreatePurchDoc(
          PurchHeader, PurchHeader."Document Type"::Invoice,
          PostingDate, VendorNo);
        UpdateCorrectionInfo(PurchHeader, CorrDocType, CorrDocNo, RevisionNo);
        CreatePurchLine(PurchHeader, GLAccountNo, DirectUnitCost);
    end;

    local procedure CreateCrMemo(var PurchHeader: Record "Purchase Header"; PostingDate: Date; VendorNo: Code[20]; GLAccountNo: Code[20]; DirectUnitCost: Decimal; CorrDocType: Option; CorrDocNo: Code[20]; RevisionNo: Code[20])
    begin
        CreatePurchDoc(
          PurchHeader, PurchHeader."Document Type"::"Credit Memo",
          PostingDate, VendorNo);
        UpdateCorrectionInfo(PurchHeader, CorrDocType, CorrDocNo, RevisionNo);
        CreatePurchLine(PurchHeader, GLAccountNo, DirectUnitCost);
    end;

    local procedure CreatePurchDoc(var PurchHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type"; PostingDate: Date; VendorNo: Code[20])
    begin
        LibraryPurch.CreatePurchHeader(PurchHeader, DocType, VendorNo);
        PurchHeader.SetHideValidationDialog(true);
        PurchHeader.Validate("Posting Date", PostingDate);
        PurchHeader.Validate("Prices Including VAT", true);
        if DocType = PurchHeader."Document Type"::Invoice then
            PurchHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID())
        else
            PurchHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchHeader.Modify(true);
    end;

    local procedure CreatePurchLine(PurchHeader: Record "Purchase Header"; GLAccountNo: Code[20]; DirectUnitCost: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurch.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccountNo, 1);
        PurchLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchLine.Modify();
    end;

    local procedure CreateVATEntryTypeNo(): Code[2]
    var
        VATEntryType: Record "VAT Entry Type";
    begin
        VATEntryType.Init();
        VATEntryType.Code := CopyStr(LibraryUtility.GenerateRandomCode(VATEntryType.FieldNo(Code), DATABASE::"VAT Entry Type"), 1, 2);
        VATEntryType.Insert(true);
        exit(VATEntryType.Code);
    end;

    local procedure MockCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; VATEntryTypeCode: Code[2]; IsOpen: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CustLedgEntry);
        CustLedgEntry.Init();
        CustLedgEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, CustLedgEntry.FieldNo("Entry No."));
        CustLedgEntry."VAT Entry Type" := VATEntryTypeCode;
        CustLedgEntry.Open := IsOpen;
        CustLedgEntry.Insert(true);
    end;

    local procedure MockVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; VATEntryTypeCode: Code[2]; IsOpen: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(VendLedgEntry);
        VendLedgEntry.Init();
        VendLedgEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, VendLedgEntry.FieldNo("Entry No."));
        VendLedgEntry."VAT Entry Type" := VATEntryTypeCode;
        VendLedgEntry.Open := IsOpen;
        VendLedgEntry.Insert(true);
    end;

    local procedure VerifyPurchVATLedgerLineCnt(VATLedgerCode: Code[20]; VendorNo: Code[20]; ExpectedCnt: Integer)
    var
        VATLedger: Record "VAT Ledger";
    begin
        VATLedger.Get(VATLedger.Type::Purchase, VATLedgerCode);
        VerifyVATLedgerLineCnt(false, VATLedger.Type, VATLedgerCode, VendorNo, ExpectedCnt);
    end;

    local procedure VerifySalesVATLedgerLineCnt(VATLedgerCode: Code[20]; CustNo: Code[20]; ExpectedCnt: Integer)
    var
        VATLedger: Record "VAT Ledger";
    begin
        VATLedger.Get(VATLedger.Type::Sales, VATLedgerCode);
        VerifyVATLedgerLineCnt(false, VATLedger.Type, VATLedgerCode, CustNo, ExpectedCnt);
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

    local procedure VerifyInvPurchVATLedgerLine(VATLedgerCode: Code[20]; VendorNo: Code[20]; DocNo: Code[20]; DocDate: Date; CorrNo: Code[20]; CorrDate: Date; RevNo: Code[20]; RevDate: Date; RevOfCorrNo: Code[20]; RevOfCorrDate: Date)
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VerifyDocVATLedgerLine(
          false, VATLedgerLine.Type::Purchase, VATLedgerCode, VendorNo,
          VATLedgerLine."Document Type"::Invoice, DocNo, DocDate,
          CorrNo, CorrDate, RevNo, RevDate, RevOfCorrNo, RevOfCorrDate);
    end;

    local procedure VerifyInvPurchVATLedgerAddLine(VATLedgerCode: Code[20]; VendorNo: Code[20]; DocNo: Code[20]; DocDate: Date; CorrNo: Code[20]; CorrDate: Date; RevNo: Code[20]; RevDate: Date; RevOfCorrNo: Code[20]; RevOfCorrDate: Date)
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VerifyDocVATLedgerLine(
          true, VATLedgerLine.Type::Purchase, VATLedgerCode, VendorNo,
          VATLedgerLine."Document Type"::Invoice, DocNo, DocDate,
          CorrNo, CorrDate, RevNo, RevDate, RevOfCorrNo, RevOfCorrDate);
    end;

    local procedure VerifyCrMemoPurchVATLedgerLine(VATLedgerCode: Code[20]; VendorNo: Code[20]; DocNo: Code[20]; DocDate: Date; CorrNo: Code[20]; CorrDate: Date; RevNo: Code[20]; RevDate: Date; RevOfCorrNo: Code[20]; RevOfCorrDate: Date)
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VerifyDocVATLedgerLine(
          false, VATLedgerLine.Type::Purchase, VATLedgerCode, VendorNo,
          VATLedgerLine."Document Type"::"Credit Memo", DocNo, DocDate,
          CorrNo, CorrDate, RevNo, RevDate, RevOfCorrNo, RevOfCorrDate);
    end;

    local procedure VerifyCrMemoSalesVATLedgerLine(VATLedgerCode: Code[20]; CustNo: Code[20]; DocNo: Code[20]; DocDate: Date; CorrNo: Code[20]; CorrDate: Date; RevNo: Code[20]; RevDate: Date; RevOfCorrNo: Code[20]; RevOfCorrDate: Date)
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VerifyDocVATLedgerLine(
          false, VATLedgerLine.Type::Sales, VATLedgerCode, CustNo,
          VATLedgerLine."Document Type"::"Credit Memo", DocNo, DocDate,
          CorrNo, CorrDate, RevNo, RevDate, RevOfCorrNo, RevOfCorrDate);
    end;

    local procedure VerifyDocVATLedgerLine(IsAddSheet: Boolean; VATLEdgerType: Option; VATLedgerCode: Code[20]; CVNo: Code[20]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; DocDate: Date; CorrNo: Code[20]; CorrDate: Date; RevNo: Code[20]; RevDate: Date; RevOfCorrNo: Code[20]; RevOfCorrDate: Date)
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
        VATLedgerLine.SetRange("Correction No.", CorrNo);
        VATLedgerLine.SetRange("Correction Date", CorrDate);
        VATLedgerLine.SetRange("Revision No.", RevNo);
        VATLedgerLine.SetRange("Revision Date", RevDate);
        VATLedgerLine.SetRange("Revision of Corr. No.", RevOfCorrNo);
        VATLedgerLine.SetRange("Revision of Corr. Date", RevOfCorrDate);
        VATLedgerLine.FindFirst();
    end;

    local procedure CreateVendorGLAccount(var VendorNo: Code[20]; var GLAccountNo: Code[20])
    begin
        VendorNo := LibraryPurch.CreateVendorNo();
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();
    end;

    local procedure CreateVATEntryType(VATEntryCount: Integer)
    var
        VATEntryType: Record "VAT Entry Type";
        LibraryUtility: Codeunit "Library - Utility";
        Counter: Integer;
    begin
        for Counter := 1 to VATEntryCount do begin
            VATEntryType.Code :=
              LibraryUtility.GenerateRandomCode(VATEntryType.FieldNo(Code), DATABASE::"VAT Entry Type");
            VATEntryType.Insert(true);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATEntryTypeHandler(var VATEntryTypePage: TestPage "VAT Entry Types")
    var
        Counter: Integer;
        MaxCount: Integer;
    begin
        MaxCount := LibraryRandom.RandInt(5);
        for Counter := 1 to MaxCount do
            VATEntryTypePage.Next();
        LibraryVariableStorage.Enqueue(VATEntryTypePage.Code.Value);
        VATEntryTypePage.OK().Invoke();
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        UnitPrice := LibraryRandom.RandDec(10000, 2);

        IsInitialized := true;
    end;
}

