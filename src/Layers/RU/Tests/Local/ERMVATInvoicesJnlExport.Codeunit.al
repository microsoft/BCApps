codeunit 147135 "ERM VAT Invoices Jnl. Export"
{
    // // [FEATURE] [VAT Invoice Journal]

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LocalReportManagement: Codeunit "Local Report Management";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        CompoundExprErr: Label 'Compound function expression is wrong';

    [Test]
    [Scope('OnPrem')]
    procedure VATInvJnExportSalesBookBasic()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
        PostingDate: Date;
    begin
        // [SCENARIO ID.2] Factura Journal Basic (Sale)
        Initialize();

        // [GIVEN] Create and post sales invoice
        PostingDate := CalcDate('<1M>', WorkDate());
        InvNo := CreatePostSalesInvoice(SalesHeader, PostingDate);

        // [WHEN] VAT invoice journal exported
        VATInvoicesJournalExport(PostingDate);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount
        // exported to the  proper Excel cells
        VerifyExportedJournalBasic(InvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATInvJnExportSalesBookCorrection()
    var
        SalesHeader: Record "Sales Header";
        CorSalesHeader: Record "Sales Header";
        InvNo: Code[20];
        CorInvNo: Code[20];
        PostingDate: Date;
    begin
        // [SCENARIO ID.6] Sales Book with Correction
        Initialize();

        // [GIVEN] Create and post sales invoice, then create corrective invoice
        PostingDate := CalcDate('<2M>', WorkDate());
        InvNo := CreatePostSalesInvoice(SalesHeader, PostingDate);
        CorInvNo := CreatePostCorrSalesInvoice(CorSalesHeader, SalesHeader, InvNo);

        // [WHEN] VAT invoice journal exported
        VATInvoicesJournalExport(PostingDate);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount
        // exported to the  proper Excel cells
        VerifyExportedJournalCorrection(InvNo, CorInvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATInvJnExportSalesBookRevision()
    var
        SalesHeader: Record "Sales Header";
        RevSalesHeader: Record "Sales Header";
        InvNo: Code[20];
        RevInvNo: Code[20];
        PostingDate: Date;
    begin
        // [SCENARIO ID.7] Sales Book Revision
        Initialize();

        // [GIVEN] Create and post sales invoice, then create revision invoice
        PostingDate := CalcDate('<3M>', WorkDate());
        InvNo := CreatePostSalesInvoice(SalesHeader, PostingDate);
        RevInvNo := CreatePostRevisionSalesInvoice(RevSalesHeader, SalesHeader, InvNo);

        // [WHEN] VAT invoice journal exported
        VATInvoicesJournalExport(PostingDate);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount
        // exported to the  proper Excel cells
        VerifyExportedJournalRevision(InvNo, RevInvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATInvJnExportSalesBookRevOfCorrection()
    var
        SalesHeader: Record "Sales Header";
        CorSalesHeader: Record "Sales Header";
        RevSalesHeader: Record "Sales Header";
        InvNo: Code[20];
        CorInvNo: Code[20];
        RevInvNo: Code[20];
        PostingDate: Date;
    begin
        // [SCENARIO ID.8] Sales Book with Correction
        Initialize();

        // [GIVEN] Create and post sales invoice, then create corrective invoice,
        // then create revision invoice for correction
        PostingDate := CalcDate('<4M>', WorkDate());
        InvNo := CreatePostSalesInvoice(SalesHeader, PostingDate);
        CorInvNo := CreatePostCorrSalesInvoice(CorSalesHeader, SalesHeader, InvNo);
        RevInvNo := CreatePostRevisionSalesInvoice(RevSalesHeader, CorSalesHeader, CorInvNo);

        // [WHEN] VAT invoice journal exported
        VATInvoicesJournalExport(PostingDate);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount
        // exported to the  proper Excel cells
        VerifyExportedJournalRevCorr(InvNo, CorInvNo, RevInvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATInvJnExportPurchBookRevision()
    var
        InvNo: Code[20];
        RevInvNo: Code[20];
        PostingDate: Date;
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO 362385] Purchase Book Revision
        Initialize();

        // [GIVEN] Posted Sales invoice
        PostingDate := CalcDate('<5M>', WorkDate());
        InvNo := CreatePostPurchInvoice(VendorNo, GLAccountNo, PostingDate, Amount);
        // [GIVEN] Posted Credit Memo invoice
        CreatePostPurchCrMemoInvoice(VendorNo, GLAccountNo, PostingDate, Amount);
        // [GIVEN] Posted Revision invoice
        RevInvNo := CreatePostRevisionPurchInvoice(InvNo, PostingDate, VendorNo);

        // [WHEN] VAT invoice journal exported
        VATInvoicesJournalExport(PostingDate);

        // [THEN] VAT Invoice Journal shows 2 lines: original facture and revision facture
        VerifyExportedJnlPurchRevision(InvNo, RevInvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFormatCompoundExprCase1()
    var
        Text1: Text;
        Text2: Text;
        Expr: Text;
    begin
        // Unit test checks function FormatCompoundExpr from Codeunit Local Report Managment
        // Case1: Text1 and Text2 are not empty.
        Text1 := LibraryUtility.GenerateRandomText(5);
        Text2 := Text1;
        Expr := LocalReportManagement.FormatCompoundExpr(Text1, Text2);
        Assert.AreEqual(Text1 + '; ' + Text2, Expr, CompoundExprErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFormatCompoundExprCase2()
    var
        Text1: Text;
        Text2: Text;
        Expr: Text;
    begin
        // Unit test checks function FormatCompoundExpr from Codeunit Local Report Managment
        // Case2: Text1 is not empty, Text2 is empty.
        Text1 := LibraryUtility.GenerateRandomText(5);
        Text2 := '';
        Expr := LocalReportManagement.FormatCompoundExpr(Text1, Text2);
        Assert.AreEqual(Text1, Expr, CompoundExprErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFormatCompoundExprCase3()
    var
        Text1: Text;
        Text2: Text;
        Expr: Text;
    begin
        // Unit test checks function FormatCompoundExpr from Codeunit Local Report Managment
        // Case3: Text1 is empty, Text2 is not empty.
        Text1 := '';
        Text2 := LibraryUtility.GenerateRandomText(5);
        Expr := LocalReportManagement.FormatCompoundExpr(Text1, Text2);
        Assert.AreEqual(Text2, Expr, CompoundExprErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFormatCompoundExprCase4()
    var
        Text1: Text;
        Text2: Text;
        Expr: Text;
    begin
        // Unit test checks function FormatCompoundExpr from Codeunit Local Report Managment
        // Case4: Text1 and Text2 are empty.
        Text1 := '';
        Text2 := '';
        Expr := LocalReportManagement.FormatCompoundExpr(Text1, Text2);
        Assert.AreEqual('', Expr, CompoundExprErr);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        UpdateSalesRecSetupCreditWarnings;
        IsInitialized := true;
    end;

    local procedure CreatePostSalesInvoice(var SalesHeader: Record "Sales Header"; PostingDate: Date): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesInvoiceWithGLAcc(SalesHeader, SalesLine, '', '');
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Shipment Date", PostingDate);
        SalesHeader.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostPurchInvoice(var VendorNo: Code[20]; var GLAccountNo: Code[20]; PostingDate: Date; var Amount: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseInvoiceWithGLAcc(PurchaseHeader, PurchaseLine, '', '');
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        UpdateVATInvoiceInfo(PurchaseHeader, Format(PostingDate), PostingDate);
        PurchaseHeader.Modify(true);
        VendorNo := PurchaseHeader."Buy-from Vendor No.";
        GLAccountNo := PurchaseLine."No.";
        Amount := PurchaseLine.Amount;
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePostPurchCrMemoInvoice(VendorNo: Code[20]; GLAccountNo: Code[20]; PostingDate: Date; Amount: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseCrMemoWithGLAcc(PurchaseHeader, PurchaseLine, VendorNo, GLAccountNo);
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePurchDoc(var PurchHeader: Record "Purchase Header"; DocType: Option; PostingDate: Date; VendorNo: Code[20])
    begin
        with PurchHeader do begin
            LibraryPurchase.CreatePurchHeader(PurchHeader, DocType, VendorNo);
            UpdateVATInvoiceInfo(PurchHeader, Format(PostingDate), PostingDate);
            SetHideValidationDialog(true);
            Validate("Posting Date", PostingDate);
            Modify(true);
        end;
    end;

    local procedure CreatePostCorrSalesInvoice(var CorrSalesHeader: Record "Sales Header"; SalesHeader: Record "Sales Header"; InvNo: Code[20]): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCorrectiveSalesInvoice(
          CorrSalesHeader, SalesHeader."Bill-to Customer No.", InvNo,
          CorrSalesHeader."Corrective Doc. Type"::Correction, SalesHeader."Posting Date");
        FindSalesLine(SalesLine, CorrSalesHeader);
        UpdateQuantityInSalesLine(SalesLine, LibraryRandom.RandIntInRange(3, 5));
        exit(LibrarySales.PostSalesDocument(CorrSalesHeader, true, true));
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        with SalesLine do begin
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            FindFirst();
        end;
    end;

    local procedure CopyDocument(PurchHeader: Record "Purchase Header"; DocNo: Code[20])
    var
        CopyPurchDocument: Report "Copy Purchase Document";
        DocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Receipt","Posted Invoice","Posted Return Shipment","Posted Credit Memo";
    begin
        CopyPurchDocument.SetPurchHeader(PurchHeader);
        CopyPurchDocument.InitializeRequest(DocType::"Posted Invoice", DocNo, false, false);
        CopyPurchDocument.UseRequestPage(false);
        CopyPurchDocument.Run();
    end;

    local procedure UpdateQuantityInSalesLine(var SalesLine: Record "Sales Line"; Multiplier: Decimal)
    begin
        with SalesLine do begin
            Validate("Quantity (After)", Round("Quantity (After)" * Multiplier, 1));
            Modify(true);
        end;
    end;

    local procedure UpdateSalesRecSetupCreditWarnings()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        with SalesReceivablesSetup do begin
            Get();
            Validate("Credit Warnings", "Credit Warnings"::"No Warning");
            Modify(true);
        end;
    end;

    local procedure UpdateRevisionInfo(var PurchHeader: Record "Purchase Header"; CorrDocType: Option; CorrDocNo: Code[20])
    begin
        with PurchHeader do begin
            UpdateCorrectionInfo(PurchHeader, "Corrective Doc. Type"::Revision, CorrDocType, CorrDocNo);
            Validate("Revision No.", LibraryUtility.GenerateGUID());
            Modify(true);
        end;
    end;

    local procedure UpdateCorrectionInfo(var PurchHeader: Record "Purchase Header"; CorrType: Option; CorrDocType: Option; CorrDocNo: Code[20])
    begin
        with PurchHeader do begin
            Validate("Corrective Document", true);
            Validate("Corrective Doc. Type", CorrType);
            Validate("Corrected Doc. Type", CorrDocType);
            Validate("Corrected Doc. No.", CorrDocNo);
            Modify(true);
        end;
    end;

    local procedure UpdateVATInvoiceInfo(var PurchHeader: Record "Purchase Header"; VendVATInvNo: Code[30]; VendorVATInvDate: Date)
    begin
        with PurchHeader do begin
            Validate("Vendor VAT Invoice No.", VendVATInvNo);
            Validate("Vendor VAT Invoice Date", VendorVATInvDate);
            Validate("Vendor VAT Invoice Rcvd Date", VendorVATInvDate);
            Modify(true);
        end;
    end;

    local procedure CreatePostRevisionSalesInvoice(var CorrSalesHeader: Record "Sales Header"; SalesHeader: Record "Sales Header"; InvNo: Code[20]): Code[20]
    begin
        LibrarySales.CreateCorrectiveSalesInvoice(
          CorrSalesHeader, SalesHeader."Bill-to Customer No.", InvNo,
          CorrSalesHeader."Corrective Doc. Type"::Revision, CalcDate('<1D>', SalesHeader."Posting Date"));
        exit(LibrarySales.PostSalesDocument(CorrSalesHeader, true, true));
    end;

    local procedure CreatePostRevisionPurchInvoice(DocNo: Code[20]; PostingDate: Date; VendorNo: Code[20]): Code[20]
    var
        PurchHeader: Record "Purchase Header";
    begin
        CreatePurchDoc(
          PurchHeader, PurchHeader."Document Type"::Invoice, PostingDate, VendorNo);
        UpdateRevisionInfo(PurchHeader, PurchHeader."Corrected Doc. Type"::Invoice, DocNo);
        CopyDocument(PurchHeader, DocNo);
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure VATInvoicesJournalExport(PostingDate: Date)
    var
        VATInvoicesJournal: Report "VAT Invoices Journal";
    begin
        VATInvoicesJournal.InitializeRequest(
          Date2DMY(PostingDate, 3), 1, PostingDate, CalcDate('<1M>', PostingDate), false);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        VATInvoicesJournal.SetFileNameSilent(LibraryReportValidation.GetFileName());
        VATInvoicesJournal.UseRequestPage(false);
        VATInvoicesJournal.Run();
    end;

    local procedure GetSalesInvHeader(InvNo: Code[20]; var SalesInvHeader: Record "Sales Invoice Header")
    begin
        SalesInvHeader.Get(InvNo);
        SalesInvHeader.CalcFields(Amount, "Amount Including VAT");
    end;

    local procedure GetPurchInvHeader(InvNo: Code[20]; var PurchInvHeader: Record "Purch. Inv. Header")
    begin
        PurchInvHeader.Get(InvNo);
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
    end;

    local procedure VerifyExportedJournalBasic(InvNo: Code[20])
    var
        SalesInvHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        RowNo: Integer;
    begin
        RowNo := 21;
        GetSalesInvHeader(InvNo, SalesInvHeader);
        with SalesInvHeader do begin
            LibraryReportValidation.VerifyCellValue(RowNo, 5, Format("Document Date")); // Column 2
            LibraryReportValidation.VerifyCellValue(
              RowNo, 18, "No." + '; ' + Format("Document Date")); // Column 4
            Customer.Get("Sell-to Customer No.");
            LibraryReportValidation.VerifyCellValue(RowNo, 50, Customer.Name); // Column 9
            LibraryReportValidation.VerifyCellValue(RowNo, 117, Format("Amount Including VAT")); // Column 14
            LibraryReportValidation.VerifyCellValue(RowNo, 131, Format("Amount Including VAT" - Amount)); // Column 15
        end;
    end;

    local procedure VerifyExportedJournalCorrection(InvNo: Code[20]; CorInvNo: Code[20])
    var
        SalesInvHeader: Record "Sales Invoice Header";
        CorSalesInvHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        RowNo: Integer;
    begin
        RowNo := 22;
        GetSalesInvHeader(InvNo, SalesInvHeader);
        GetSalesInvHeader(CorInvNo, CorSalesInvHeader);
        with CorSalesInvHeader do begin
            LibraryReportValidation.VerifyCellValue(RowNo, 5, Format("Document Date")); // Column 2
            LibraryReportValidation.VerifyCellValue(
              RowNo, 18, SalesInvHeader."No." + '; ' + Format(SalesInvHeader."Document Date")); // Column 4
            LibraryReportValidation.VerifyCellValue(
              RowNo, 34, "No." + '; ' + Format("Posting Date")); // Column 6
            Customer.Get("Sell-to Customer No.");
            LibraryReportValidation.VerifyCellValue(RowNo, 50, Customer.Name); // Column 9
            LibraryReportValidation.VerifyCellValue(
              RowNo, 147, Format("Amount Including VAT")); // Column 16
            LibraryReportValidation.VerifyCellValue(
              RowNo, 161, Format("Amount Including VAT" - Amount)); // Column 17
        end;
    end;

    local procedure VerifyExportedJournalRevision(InvNo: Code[20]; RevInvNo: Code[20])
    var
        SalesInvHeader: Record "Sales Invoice Header";
        RevSalesInvHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        RowNo: Integer;
    begin
        RowNo := 22;
        GetSalesInvHeader(InvNo, SalesInvHeader);
        GetSalesInvHeader(RevInvNo, RevSalesInvHeader);
        with RevSalesInvHeader do begin
            LibraryReportValidation.VerifyCellValue(RowNo, 5, Format("Document Date")); // Column 2
            LibraryReportValidation.VerifyCellValue(
              RowNo, 18, SalesInvHeader."No." + '; ' + Format(SalesInvHeader."Document Date")); // Column 4
            LibraryReportValidation.VerifyCellValue(
              RowNo, 26, "Revision No." + '; ' + Format("Posting Date")); // Column 6
            Customer.Get("Sell-to Customer No.");
            LibraryReportValidation.VerifyCellValue(RowNo, 50, Customer.Name); // Column 9
            LibraryReportValidation.VerifyCellValue(
              RowNo, 117, Format("Amount Including VAT")); // Column 14
            LibraryReportValidation.VerifyCellValue(
              RowNo, 131, Format("Amount Including VAT" - Amount)); // Column 15
        end;
    end;

    local procedure VerifyExportedJournalRevCorr(InvNo: Code[20]; CorInvNo: Code[20]; RevInvNo: Code[20])
    var
        SalesInvHeader: Record "Sales Invoice Header";
        CorSalesInvHeader: Record "Sales Invoice Header";
        RevSalesInvHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        RowNo: Integer;
    begin
        RowNo := 23;
        GetSalesInvHeader(InvNo, SalesInvHeader);
        GetSalesInvHeader(CorInvNo, CorSalesInvHeader);
        GetSalesInvHeader(RevInvNo, RevSalesInvHeader);

        with RevSalesInvHeader do begin
            LibraryReportValidation.VerifyCellValue(RowNo, 5, Format("Document Date")); // Column 2
            LibraryReportValidation.VerifyCellValue(
              RowNo, 18, SalesInvHeader."No." + '; ' + Format(SalesInvHeader."Document Date")); // Column 4
            LibraryReportValidation.VerifyCellValue(
              RowNo, 34, CorSalesInvHeader."No." + '; ' + Format(CorSalesInvHeader."Posting Date")); // Column 6
            LibraryReportValidation.VerifyCellValue(
              RowNo, 42, "Revision No." + '; ' + Format("Posting Date")); // Column 7
            Customer.Get("Sell-to Customer No.");
            LibraryReportValidation.VerifyCellValue(RowNo, 50, Customer.Name); // Column 9
            LibraryReportValidation.VerifyCellValue(
              RowNo, 117, Format("Amount Including VAT")); // Column 14
            LibraryReportValidation.VerifyCellValue(
              RowNo, 131, Format("Amount Including VAT" - Amount)); // Column 15
        end;
    end;

    local procedure VerifyExportedJnlPurchRevision(InvNo: Code[20]; RevInvNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        RevPurchInvHeader: Record "Purch. Inv. Header";
        Vendor: Record Vendor;
        RowNo: Integer;
    begin
        RowNo := 31;
        GetPurchInvHeader(InvNo, PurchInvHeader);
        GetPurchInvHeader(RevInvNo, RevPurchInvHeader);
        with RevPurchInvHeader do begin
            LibraryReportValidation.VerifyCellValue(RowNo, 5, Format("Document Date")); // Column 2
            Vendor.Get("Buy-from Vendor No.");
            LibraryReportValidation.VerifyCellValue(RowNo, 50, Vendor.Name); // Column 8
            LibraryReportValidation.VerifyCellValue(
              RowNo, 116, Format("Amount Including VAT")); // Column 14
            LibraryReportValidation.VerifyCellValue(
              RowNo, 131, Format("Amount Including VAT" - Amount)); // Column 15
            RowNo += 1;
            LibraryReportValidation.VerifyCellValue(RowNo, 5, Format("Document Date")); // Column 2
            LibraryReportValidation.VerifyCellValue(
              RowNo, 26, "Revision No." + '; ' + Format("Posting Date")); // Column 5
            Vendor.Get("Buy-from Vendor No.");
            LibraryReportValidation.VerifyCellValue(RowNo, 50, Vendor.Name); // Column 8
            LibraryReportValidation.VerifyCellValue(
              RowNo, 116, Format("Amount Including VAT")); // Column 14
            LibraryReportValidation.VerifyCellValue(
              RowNo, 131, Format("Amount Including VAT" - Amount)); // Column 15
        end;
    end;
}

