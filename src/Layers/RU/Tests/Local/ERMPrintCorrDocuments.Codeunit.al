codeunit 144013 "ERM Print Corr. Documents"
{
    // This codeunit have UTs that checks whether correction document should print or not in the sequence of invoice/credit memos, corrections and revisions.
    // In each test case you could see the sequence of documents (Invoice, Credit Memo, Correction, Revision) and the actions applied (Release, Post).

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        RepNotOnPrintErr: Label 'The Corrective Document Report is not in the list.';
        RepOnPrintErr: Label 'The Corrective Document Report is in the list.';
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseRevInvoiceToSalesInv()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Invoice->Invoice (Rev.)->Release

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        CreateReleaseRevSalesInv(SalesInvHeader, SalesHeader, InvNo);
        VerifyCorrReportNotOnPrint(SalesInvHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseRevCrMemoToSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Cr.Memo->Cr.Memo (Rev.)->Release

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        CreateReleaseRevSalesCrMemo(SalesInvHeader, SalesHeader, InvNo);
        VerifyCorrReportNotOnPrint(SalesInvHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRevInvoiceToSalesInv()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Invoice->Invoice (Rev.)->Post

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        CreatePostRevisionSalesInvoice(SalesInvHeader, SalesHeader, InvNo);
        VerifyCorrReportNotOnPrint(SalesInvHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRevCrMemoToSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Cr.Memo->Cr.Memo (Rev.)->Post

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        CreatePostRevisionSalesCrMemo(SalesInvHeader, SalesHeader, InvNo);
        VerifyCorrReportNotOnPrint(SalesInvHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseCorrInvoiceToSalesInv()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Invoice->Invoice(Corr.)->Release

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        CreateReleaseCorrSalesInvoice(SalesInvHeader, SalesHeader, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseCorrInvoiceToSalesCrMem()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Cr.Memo->Cr.Memo(Corr.)->Release

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        CreateReleaseCorrSalesCrMemo(SalesInvHeader, SalesHeader, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostCorrInvoiceToSalesInv()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Invoice->Invoice(Corr.)->Post

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        CreatePostCorrSalesInvoice(SalesInvHeader, SalesHeader, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostCorrInvoiceToSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Cr.Memo->Cr.Memo(Corr.)->Post

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        CreatePostCorrSalesCrMemo(SalesInvHeader, SalesHeader, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseRevCorrSI()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Invoice->Invoice(Corr.)->Invoice(Rev.)->Release

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        InvNo := CreatePostCorrSalesInvoice(SalesInvHeader, SalesHeader, InvNo);
        CreateReleaseRevSalesInv(SalesInvHeader2, SalesInvHeader, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseRevCorrSCM()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Cr.Memo->Cr.Memo(Corr.)->Cr.Memo(Rev.)->Release

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        InvNo := CreatePostCorrSalesCrMemo(SalesInvHeader, SalesHeader, InvNo);
        CreateReleaseRevSalesCrMemo(SalesInvHeader2, SalesInvHeader, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRevCorrSI()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Invoice->Invoice(Corr.)->Invoice(Rev.)->Post

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        InvNo := CreatePostCorrSalesInvoice(SalesInvHeader, SalesHeader, InvNo);
        CreatePostRevisionSalesInvoice(SalesInvHeader2, SalesInvHeader, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRevCorrSCM()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Cr.Memo->Cr.Memo(Corr.)->Cr.Memo(Rev.)->Post

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        InvNo := CreatePostCorrSalesCrMemo(SalesInvHeader, SalesHeader, InvNo);
        CreatePostRevisionSalesCrMemo(SalesInvHeader2, SalesInvHeader, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseCorrRevSI()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Invoice->Invoice(Rev.)->Invoice(Corr.)->Release

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        InvNo := CreatePostRevisionSalesInvoice(SalesInvHeader, SalesHeader, InvNo);
        CreateReleaseCorrSalesInvoice(SalesInvHeader2, SalesInvHeader, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseCorrRevSCM()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Cr.Memo->Cr.Memo(Rev.)->Cr.Memo(Corr.)->Release

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        InvNo := CreatePostRevisionSalesCrMemo(SalesInvHeader, SalesHeader, InvNo);
        CreateReleaseCorrSalesCrMemo(SalesInvHeader2, SalesInvHeader, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostCorrRevSI()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Invoice->Invoice(Rev.)->Invoice(Corr.)->Post

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        InvNo := CreatePostRevisionSalesInvoice(SalesInvHeader, SalesHeader, InvNo);
        CreatePostCorrSalesInvoice(SalesInvHeader2, SalesInvHeader, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostCorrRevSCM()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Cr.Memo->Cr.Memo(Rev.)->Cr.Memo(Corr.)->Post

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        InvNo := CreatePostRevisionSalesCrMemo(SalesInvHeader, SalesHeader, InvNo);
        CreatePostCorrSalesCrMemo(SalesInvHeader2, SalesInvHeader, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseRevRevSI()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Invoice->Invoice(Rev.)->Invoice(Rev.)->Post

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        InvNo := CreatePostRevisionSalesInvoice(SalesInvHeader, SalesHeader, InvNo);
        CreateReleaseRevSalesInv(SalesInvHeader2, SalesInvHeader, InvNo);
        VerifyCorrReportNotOnPrint(SalesInvHeader2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseRevRevSCM()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Cr.Memo->Cr.Memo(Rev.)->Cr.Memo(Rev.)->Post

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        InvNo := CreatePostRevisionSalesCrMemo(SalesInvHeader, SalesHeader, InvNo);
        CreateReleaseRevSalesCrMemo(SalesInvHeader2, SalesInvHeader, InvNo);
        VerifyCorrReportNotOnPrint(SalesInvHeader2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRevRevSI()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Invoice->Invoice(Rev.)->Invoice(Rev.)->Post

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        InvNo := CreatePostRevisionSalesInvoice(SalesInvHeader, SalesHeader, InvNo);
        CreatePostRevisionSalesInvoice(SalesInvHeader2, SalesInvHeader, InvNo);
        VerifyCorrReportNotOnPrint(SalesInvHeader2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRevRevSCM()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Cr.Memo->Cr.Memo(Rev.)->Cr.Memo(Rev.)->Post

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        InvNo := CreatePostRevisionSalesCrMemo(SalesInvHeader, SalesHeader, InvNo);
        CreatePostRevisionSalesCrMemo(SalesInvHeader2, SalesInvHeader, InvNo);
        VerifyCorrReportNotOnPrint(SalesInvHeader2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseRevRevCorrSI()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        SalesInvHeader3: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Invoice->Invoice(Corr.)->Invoice(Rev.)->Invoice(Rev.)->Release

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        InvNo := CreatePostCorrSalesInvoice(SalesInvHeader, SalesHeader, InvNo);
        InvNo := CreatePostRevisionSalesInvoice(SalesInvHeader2, SalesInvHeader, InvNo);
        CreateReleaseRevSalesInv(SalesInvHeader3, SalesInvHeader2, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseRevRevCorrSCM()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        SalesInvHeader3: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Cr.Memo->Cr.Memo(Corr.)->Cr.Memo(Rev.)->Cr.Memo(Rev.)->Release

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        InvNo := CreatePostCorrSalesCrMemo(SalesInvHeader, SalesHeader, InvNo);
        InvNo := CreatePostRevisionSalesCrMemo(SalesInvHeader2, SalesInvHeader, InvNo);
        CreateReleaseRevSalesCrMemo(SalesInvHeader3, SalesInvHeader2, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRevRevCorrSI()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        SalesInvHeader3: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Invoice->Invoice(Corr.)->Invoice(Rev.)->Invoice(Rev.)->Post

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        InvNo := CreatePostCorrSalesInvoice(SalesInvHeader, SalesHeader, InvNo);
        InvNo := CreatePostRevisionSalesInvoice(SalesInvHeader2, SalesInvHeader, InvNo);
        CreatePostRevisionSalesInvoice(SalesInvHeader3, SalesInvHeader2, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRevRevCorrSCM()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        SalesInvHeader3: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Cr.Memo->Cr.Memo(Corr.)->Cr.Memo(Rev.)->Cr.Memo(Rev.)->Post

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        InvNo := CreatePostCorrSalesCrMemo(SalesInvHeader, SalesHeader, InvNo);
        InvNo := CreatePostRevisionSalesCrMemo(SalesInvHeader2, SalesInvHeader, InvNo);
        CreatePostRevisionSalesCrMemo(SalesInvHeader3, SalesInvHeader2, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseRevCorrCorrSI()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        SalesInvHeader3: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Invoice->Invoice(Corr.)->Invoice(Corr.)->Invoice(Rev.)->Release

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        InvNo := CreatePostCorrSalesInvoice(SalesInvHeader, SalesHeader, InvNo);
        InvNo := CreatePostCorrSalesInvoice(SalesInvHeader2, SalesInvHeader, InvNo);
        CreateReleaseRevSalesInv(SalesInvHeader3, SalesInvHeader2, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseRevCorrCorrSCM()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        SalesInvHeader3: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Cr.Memo->Cr.Memo(Corr.)->Cr.Memo(Corr.)->Cr.Memo(Rev.)->Release

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        InvNo := CreatePostCorrSalesCrMemo(SalesInvHeader, SalesHeader, InvNo);
        InvNo := CreatePostCorrSalesCrMemo(SalesInvHeader2, SalesInvHeader, InvNo);
        CreateReleaseRevSalesCrMemo(SalesInvHeader3, SalesInvHeader2, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRevCorrCorrSI()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        SalesInvHeader3: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Invoice->Invoice(Corr.)->Invoice(Corr.)->Invoice(Rev.)->Post

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        InvNo := CreatePostCorrSalesInvoice(SalesInvHeader, SalesHeader, InvNo);
        InvNo := CreatePostCorrSalesInvoice(SalesInvHeader2, SalesInvHeader, InvNo);
        CreatePostRevisionSalesInvoice(SalesInvHeader3, SalesInvHeader2, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRevCorrCorrSCM()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        SalesInvHeader3: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Cr.Memo->Cr.Memo(Corr.)->Cr.Memo(Corr.)->Cr.Memo(Rev.)->Post

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        InvNo := CreatePostCorrSalesCrMemo(SalesInvHeader, SalesHeader, InvNo);
        InvNo := CreatePostCorrSalesCrMemo(SalesInvHeader2, SalesInvHeader, InvNo);
        CreatePostRevisionSalesCrMemo(SalesInvHeader3, SalesInvHeader2, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostCorrRevRevSI()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        SalesInvHeader3: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Invoice->Invoice(Rev.)->Invoice(Rev.)->Invoice(Corr.)->Post

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        InvNo := CreatePostRevisionSalesInvoice(SalesInvHeader, SalesHeader, InvNo);
        InvNo := CreatePostRevisionSalesInvoice(SalesInvHeader2, SalesInvHeader, InvNo);
        CreatePostCorrSalesInvoice(SalesInvHeader3, SalesInvHeader2, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostCorrRevRevSCM()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        SalesInvHeader3: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Cr.Memo->Cr.Memo(Rev.)->Cr.Memo(Rev.)->Cr.Memo(Corr.)->Post

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        InvNo := CreatePostRevisionSalesCrMemo(SalesInvHeader, SalesHeader, InvNo);
        InvNo := CreatePostRevisionSalesCrMemo(SalesInvHeader2, SalesInvHeader, InvNo);
        CreatePostCorrSalesCrMemo(SalesInvHeader3, SalesInvHeader2, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseRevCorrRevRevSI()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        SalesInvHeader3: Record "Sales Header";
        SalesInvHeader4: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Invoice->Invoice(Rev.)->Invoice(Rev.)->Invoice(Corr.)->Invoice(Rev.)->Release

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        InvNo := CreatePostRevisionSalesInvoice(SalesInvHeader, SalesHeader, InvNo);
        InvNo := CreatePostRevisionSalesInvoice(SalesInvHeader2, SalesInvHeader, InvNo);
        InvNo := CreatePostCorrSalesInvoice(SalesInvHeader3, SalesInvHeader2, InvNo);
        CreateReleaseRevSalesInv(SalesInvHeader4, SalesInvHeader3, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseRevCorrRevRevSCM()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        SalesInvHeader3: Record "Sales Header";
        SalesInvHeader4: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Cr.Memo->Cr.Memo(Rev.)->Cr.Memo(Rev.)->Cr.Memo(Corr.)->Cr.Memo(Rev.)->Release

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        InvNo := CreatePostRevisionSalesCrMemo(SalesInvHeader, SalesHeader, InvNo);
        InvNo := CreatePostRevisionSalesCrMemo(SalesInvHeader2, SalesInvHeader, InvNo);
        InvNo := CreatePostCorrSalesCrMemo(SalesInvHeader3, SalesInvHeader2, InvNo);
        CreateReleaseRevSalesCrMemo(SalesInvHeader4, SalesInvHeader3, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRevCorrRevRevSI()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        SalesInvHeader3: Record "Sales Header";
        SalesInvHeader4: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Invoice->Invoice(Rev.)->Invoice(Rev.)->Invoice(Corr.)->Invoice(Rev.)->Post

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        InvNo := CreatePostRevisionSalesInvoice(SalesInvHeader, SalesHeader, InvNo);
        InvNo := CreatePostRevisionSalesInvoice(SalesInvHeader2, SalesInvHeader, InvNo);
        InvNo := CreatePostCorrSalesInvoice(SalesInvHeader3, SalesInvHeader2, InvNo);
        CreatePostRevisionSalesInvoice(SalesInvHeader4, SalesInvHeader3, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRevCorrRevRevSCM()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Header";
        SalesInvHeader2: Record "Sales Header";
        SalesInvHeader3: Record "Sales Header";
        SalesInvHeader4: Record "Sales Header";
        InvNo: Code[20];
    begin
        // Cr.Memo->Cr.Memo(Rev.)->Cr.Memo(Rev.)->Cr.Memo(Corr.)->Cr.Memo(Rev.)->Post

        Initialize();
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        InvNo := CreatePostRevisionSalesCrMemo(SalesInvHeader, SalesHeader, InvNo);
        InvNo := CreatePostRevisionSalesCrMemo(SalesInvHeader2, SalesInvHeader, InvNo);
        InvNo := CreatePostCorrSalesCrMemo(SalesInvHeader3, SalesInvHeader2, InvNo);
        CreatePostRevisionSalesCrMemo(SalesInvHeader4, SalesInvHeader3, InvNo);
        VerifyCorrReportOnPrint(SalesInvHeader4);
    end;

    [Test]
    [HandlerFunctions('SalesCorrFacturaInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCorrCrMemoPrintUsingCorrectReport()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderCorrCrMemo: Record "Sales Header";
        DocumentPrint: Codeunit "Document-Print";
        InvNo: Code[20];
    begin
        // [SCENARIO 357140] Printing "Corr. Sales Cr. Memo" run report "Sales Corr. Factura-Invoice"
        Initialize();

        // [WHEN] Create Corr. Sales Cr. Memo
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        CreateReleaseCorrSalesCrMemo(SalesHeaderCorrCrMemo, SalesHeader, InvNo);
        VerifyCorrReportOnPrint(SalesHeaderCorrCrMemo);
        Commit();

        // [WHEN] Print Corr. Sales Cr. Memo
        DocumentPrint.PrintSalesHeader(SalesHeaderCorrCrMemo)

        // [THEN] Report "Sales Corr. Factura-Invoice" run successfully
    end;

    [Test]
    [HandlerFunctions('SalesCorrFacturaInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCorrInvoicePrintUsingCorrectReport()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderCorrInvoice: Record "Sales Header";
        DocumentPrint: Codeunit "Document-Print";
        InvNo: Code[20];
    begin
        // [SCENARIO 360437] Printing "Corr. Sales Invoice" run report "Sales Corr. Factura-Invoice"
        Initialize();

        // [WHEN] Create Corr. Sales Invoice
        InvNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        CreateReleaseCorrSalesInvoice(SalesHeaderCorrInvoice, SalesHeader, InvNo);
        VerifyCorrReportOnPrint(SalesHeaderCorrInvoice);
        Commit();

        // [WHEN] Print Corr. Sales Invoice
        DocumentPrint.PrintSalesHeader(SalesHeaderCorrInvoice)

        // [THEN] Report "Sales Corr. Factura-Invoice" run successfully
    end;

    [Test]
    [HandlerFunctions('ReportSelectionPrintModalPageHandler,OrderProformaInvoiceARequestPageHandler,OrderFacturaInvoiceARequestPageHandler,OrderItemShipmentTORG12RequestPageHandler,OrderItemWaybill1TRequestPageHandler,SalesShipmentM15RequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoicePrintCorrectly()
    var
        SalesHeader: Record "Sales Header";
        DocumentPrint: Codeunit "Document-Print";
    begin
        // [SCENARIO 360437] Printing "Sales Invoice" run reports:
        // [SCENARIO 360437] 1. "Order Proforma-Invoice (A)"
        // [SCENARIO 360437] 2. "Order Factura-Invoice (A)"
        // [SCENARIO 360437] 3. "Order Item Shipment TORG-12"
        // [SCENARIO 360437] 4. "Order Item Waybill 1-T"
        // [SCENARIO 360437] 5. "Sales Shipment M-15"
        Initialize();

        // [WHEN] Create Sales Invoice
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        Commit();

        // [WHEN] Print Sales Invoice
        DocumentPrint.PrintSalesHeader(SalesHeader)

        // [THEN] All Reports run successfully
    end;

    [Test]
    [HandlerFunctions('OrderFacturaInvoiceARequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoPrintCorrectly()
    var
        SalesHeader: Record "Sales Header";
        DocumentPrint: Codeunit "Document-Print";
    begin
        // [SCENARIO 357140] Printing "Sales Cr. Memo" run report "Order Factura-Invoice (A)"
        Initialize();

        // [WHEN] Create Sales Cr. Memo
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        Commit();

        // [WHEN] Print Sales Cr. Memo
        DocumentPrint.PrintSalesHeader(SalesHeader)

        // [THEN] Report "Order Factura-Invoice (A)" run successfully
    end;

    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        UpdateSalesReceivablesSetup(
          SalesReceivablesSetup, SalesReceivablesSetup."Credit Warnings"::"No Warning", false);

        isInitialized := true;
        Commit();
    end;

    local procedure CreatePostSalesDoc(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"): Code[20]
    begin
        CreateSalesDocument(SalesHeader, DocType);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
        Cust: Record Customer;
    begin
        LibrarySales.CreateCustomer(Cust);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Cust."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(15, 50));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Modify(true);
    end;

    local procedure CreatePostRevisionSalesInvoice(var CorrSalesHeader: Record "Sales Header"; SalesHeader: Record "Sales Header"; InvNo: Code[20]): Code[20]
    begin
        LibrarySales.CreateCorrectiveSalesInvoice(
          CorrSalesHeader, SalesHeader."Bill-to Customer No.", InvNo,
          CorrSalesHeader."Corrective Doc. Type"::Revision, CalcDate('<1D>', SalesHeader."Posting Date"));
        exit(LibrarySales.PostSalesDocument(CorrSalesHeader, true, true));
    end;

    local procedure CreatePostRevisionSalesCrMemo(var CorrSalesHeader: Record "Sales Header"; SalesHeader: Record "Sales Header"; InvNo: Code[20]): Code[20]
    begin
        LibrarySales.CreateCorrectiveSalesCrMemo(
          CorrSalesHeader, SalesHeader."Bill-to Customer No.", InvNo,
          CorrSalesHeader."Corrective Doc. Type"::Revision, CalcDate('<1D>', SalesHeader."Posting Date"));
        exit(LibrarySales.PostSalesDocument(CorrSalesHeader, true, true));
    end;

    local procedure CreatePostCorrSalesInvoice(var CorrSalesHeader: Record "Sales Header"; SalesHeader: Record "Sales Header"; InvNo: Code[20]): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCorrectiveSalesInvoice(
          CorrSalesHeader, SalesHeader."Bill-to Customer No.", InvNo,
          CorrSalesHeader."Corrective Doc. Type"::Correction, CalcDate('<1D>', SalesHeader."Posting Date"));
        FindSalesLine(SalesLine, CorrSalesHeader);
        UpdateQuantityInSalesLine(SalesLine, LibraryRandom.RandIntInRange(3, 5));
        exit(LibrarySales.PostSalesDocument(CorrSalesHeader, true, true));
    end;

    local procedure CreatePostCorrSalesCrMemo(var CorrSalesHeader: Record "Sales Header"; SalesHeader: Record "Sales Header"; InvNo: Code[20]): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCorrectiveSalesCrMemo(
          CorrSalesHeader, SalesHeader."Bill-to Customer No.", InvNo,
          CorrSalesHeader."Corrective Doc. Type"::Correction, CalcDate('<1D>', SalesHeader."Posting Date"));
        FindSalesLine(SalesLine, CorrSalesHeader);
        UpdateQuantityInSalesLine(SalesLine, 1 / LibraryRandom.RandIntInRange(3, 5));
        exit(LibrarySales.PostSalesDocument(CorrSalesHeader, true, true));
    end;

    local procedure CreateReleaseRevSalesInv(var CorrSalesHeader: Record "Sales Header"; SalesHeader: Record "Sales Header"; InvNo: Code[20]): Code[20]
    begin
        LibrarySales.CreateCorrectiveSalesInvoice(
          CorrSalesHeader, SalesHeader."Bill-to Customer No.", InvNo,
          CorrSalesHeader."Corrective Doc. Type"::Revision, CalcDate('<1D>', SalesHeader."Posting Date"));
        LibrarySales.ReleaseSalesDocument(CorrSalesHeader);
        exit(CorrSalesHeader."No.");
    end;

    local procedure CreateReleaseRevSalesCrMemo(var CorrSalesHeader: Record "Sales Header"; SalesHeader: Record "Sales Header"; InvNo: Code[20]): Code[20]
    begin
        LibrarySales.CreateCorrectiveSalesCrMemo(
          CorrSalesHeader, SalesHeader."Bill-to Customer No.", InvNo,
          CorrSalesHeader."Corrective Doc. Type"::Revision, CalcDate('<1D>', SalesHeader."Posting Date"));
        LibrarySales.ReleaseSalesDocument(CorrSalesHeader);
        exit(CorrSalesHeader."No.");
    end;

    local procedure CreateReleaseCorrSalesInvoice(var CorrSalesHeader: Record "Sales Header"; SalesHeader: Record "Sales Header"; InvNo: Code[20]): Code[20]
    begin
        LibrarySales.CreateCorrectiveSalesInvoice(
          CorrSalesHeader, SalesHeader."Bill-to Customer No.", InvNo,
          CorrSalesHeader."Corrective Doc. Type"::Correction, CalcDate('<1D>', SalesHeader."Posting Date"));
        ReleaseSalesDocWithNewQuantity(CorrSalesHeader, LibraryRandom.RandIntInRange(3, 5));
        exit(CorrSalesHeader."No.");
    end;

    local procedure CreateReleaseCorrSalesCrMemo(var CorrSalesHeader: Record "Sales Header"; SalesHeader: Record "Sales Header"; InvNo: Code[20]): Code[20]
    begin
        LibrarySales.CreateCorrectiveSalesCrMemo(
          CorrSalesHeader, SalesHeader."Bill-to Customer No.", InvNo,
          CorrSalesHeader."Corrective Doc. Type"::Correction, CalcDate('<1D>', SalesHeader."Posting Date"));
        ReleaseSalesDocWithNewQuantity(CorrSalesHeader, 1 / LibraryRandom.RandIntInRange(3, 5));
        exit(CorrSalesHeader."No.");
    end;

    local procedure UpdateSalesReceivablesSetup(var OldSalesReceivablesSetup: Record "Sales & Receivables Setup"; CreditWarnings: Option; StockoutWarning: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldSalesReceivablesSetup := SalesReceivablesSetup;
        SalesReceivablesSetup.Validate("Credit Warnings", CreditWarnings);
        SalesReceivablesSetup.Validate("Stockout Warning", StockoutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure ReleaseSalesDocWithNewQuantity(SalesInvHeader: Record "Sales Header"; Multiplier: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesInvHeader);
        UpdateQuantityInSalesLine(SalesLine, Multiplier);
        LibrarySales.ReleaseSalesDocument(SalesInvHeader);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
    end;

    local procedure UpdateQuantityInSalesLine(var SalesLine: Record "Sales Line"; Multiplier: Decimal)
    begin
        SalesLine.Validate("Quantity (After)", Round(SalesLine."Quantity (After)" * Multiplier, 1));
        SalesLine.Modify(true);
    end;

    local procedure VerifyCorrReportOnPrint(CorrSalesHeader: Record "Sales Header")
    var
        CorrDocMgt: Codeunit "Corrective Document Mgt.";
    begin
        Assert.IsTrue(CorrDocMgt.IsCorrDocument(CorrSalesHeader), RepNotOnPrintErr);
    end;

    local procedure VerifyCorrReportNotOnPrint(CorrSalesHeader: Record "Sales Header")
    var
        CorrDocMgt: Codeunit "Corrective Document Mgt.";
    begin
        Assert.IsFalse(CorrDocMgt.IsCorrDocument(CorrSalesHeader), RepOnPrintErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesCorrFacturaInvoiceRequestPageHandler(var SalesCorrFacturaInvoice: TestRequestPage "Sales Corr. Factura-Invoice")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OrderFacturaInvoiceARequestPageHandler(var OrderFacturaInvoiceA: TestRequestPage "Order Factura-Invoice (A)")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OrderProformaInvoiceARequestPageHandler(var OrderProformaInvoiceA: TestRequestPage "Order Proforma-Invoice (A)")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OrderItemShipmentTORG12RequestPageHandler(var OrderItemShipmentTORG12: TestRequestPage "Order Item Shipment TORG-12")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OrderItemWaybill1TRequestPageHandler(var OrderItemWaybill1T: TestRequestPage "Order Item Waybill 1-T")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentM15RequestPageHandler(var SalesShipmentM15: TestRequestPage "Sales Shipment M-15")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReportSelectionPrintModalPageHandler(var ReportSelectionPrint: TestPage "Report Selection - Print")
    begin
        ReportSelectionPrint."Set All".Invoke();
        ReportSelectionPrint.OK().Invoke();
    end;
}

