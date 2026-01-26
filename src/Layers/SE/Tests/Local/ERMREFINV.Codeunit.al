codeunit 144018 "ERM REFINV"
{
    // 1. Verify Program create a correct Source Inv No. on Sales Credit Memo Header created from Copy Sales Document.
    // 2. Verify Program create a correct Source Inv No. on Sales Credit Memo Header created from Copy Sales Document with one Sales Credit Memo Line.
    // 3. Verify Program create a correct Source Inv No. on Sales Credit Memo Header created from Copy Sales Document with Multiple Sales Credit Memo Line.
    // 4. Verify if new mandatory info is posted when running - Batch Post (2 Sales Invoices and 2 Credit Memos).
    // 5. Verify Program create a correct Source Inv No. on Sales Credit Memo Header created from Copy Sales Document with G/L Account.
    // 6. Verify Program create Sales Credit Memo without Source Inv No. on Header created from Copy Sales Document.
    // 7. Verify Program create and post Sales Credit Memo without Source Inv No. on Header created from Copy Sales Document.
    //
    // Covers Test Cases for WI - 350544.
    // ---------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                  TFS ID
    // ---------------------------------------------------------------------------------------------------------------
    // SalesCreditMemoWithSourceInvNo,PostSalesCreditMemoWithOneLine                                       153959
    // PostSalesCreditMemoWithMultipleLine                                                                 153960
    // RunBatchPostSalesCrMemos                                                                            153961
    // PostSalesCreditMemoWithGLAccount                                                                    153962
    // SalesCreditMemoWithoutSourceInvNo, PostSalesCreditMemoWithoutSourceInvNo                            153963

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        UnexpectedErr: Label 'Expected value is different from Actual value.';
        PostSaleslCreditMemoCap: Label 'Post Sales Credit Memo %1.';
        JobQueueEntryErr: Label 'The Job Queue Entry for Sales Credit Memo as result of batch posting has not been created.';
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [HandlerFunctions('CopySalesDocumentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithSourceInvNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify Program create a correct Source Inv No. on Sales Credit Memo Header created from Copy Sales Document.
        // Setup.
        Initialize();
        DocumentNo := CreateAndPostSalesInvoice(SalesLine);

        // Exercise.
        CreateSalesCreditMemoFromPage(SalesHeader, DocumentNo, SalesLine."Sell-to Customer No.");

        // Verify.
        VerifySalesCreditMemo(SalesHeader, DocumentNo);
    end;

    [Test]
    [HandlerFunctions('CopySalesDocumentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesCreditMemoWithOneLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        PostedCreditMemoNo: Code[20];
        VATAmount: Decimal;
    begin
        // Verify Program create a correct Source Inv No. on Sales Credit Memo Header created from Copy Sales Document with one Sales Credit Memo Line.
        // Setup.
        Initialize();
        DocumentNo := CreateAndPostSalesInvoice(SalesLine);
        CreateSalesCreditMemoFromPage(SalesHeader, DocumentNo, SalesLine."Sell-to Customer No.");
        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", SalesHeader."No.");
        DeleteSalesLine(SalesHeader."No.", SalesLine."No.");
        SalesHeader.CalcFields(Amount);
        VATAmount := (SalesHeader.Amount * SalesLine."VAT %") / 100;

        // Exercise.
        PostedCreditMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify.
        VerifyCustomerLedgerEntry(PostedCreditMemoNo, -(SalesHeader.Amount + VATAmount));
        VerifyGLEntry(PostedCreditMemoNo, SalesHeader.Amount + VATAmount);
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesCrMemosRequestPageHandler,MessageHandler,CopySalesDocumentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RunBatchPostSalesCrMemos()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // Verify if new mandatory info is posted when running - Batch Post (2 Sales Invoices and 2 Credit Memos)
        // Setup.
        Initialize();
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        LibrarySales.SetPostWithJobQueue(true);
        DocumentNo := CreateAndPostSalesInvoice(SalesLine);
        DocumentNo2 := CreateAndPostSalesInvoice(SalesLine2);
        CreateSalesCreditMemoFromPage(SalesHeader, DocumentNo, SalesLine."Sell-to Customer No.");
        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", SalesHeader."No.");
        SalesHeader.CalcFields(Amount);
        CreateSalesCreditMemoFromPage(SalesHeader2, DocumentNo2, SalesLine2."Sell-to Customer No.");
        SalesHeader2.Get(SalesHeader2."Document Type"::"Credit Memo", SalesHeader2."No.");
        SalesHeader2.CalcFields(Amount);

        // Exercise.
        RunBatchPostSales(SalesHeader."No." + '|' + SalesHeader2."No.");
        Commit();

        // Verify.
        VerifySalesCreditMemoJobQueueEntry(SalesHeader."No.");
        VerifySalesCreditMemoJobQueueEntry(SalesHeader2."No.");
    end;

    [Test]
    [HandlerFunctions('CopySalesDocumentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesCreditMemoWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        PostedCreditMemoNo: Code[20];
        VATAmount: Decimal;
    begin
        // Verify Program create a correct Source Inv No. on Sales Credit Memo Header created from Copy Sales Document with G/L Account.
        // Setup.
        Initialize();
        DocumentNo := CreateAndPostSalesInvoiceWithGLAccount(SalesLine);
        CreateSalesCreditMemoFromPage(SalesHeader, DocumentNo, SalesLine."Sell-to Customer No.");
        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", SalesHeader."No.");
        UpdateQuantityOnSalesLine(
          SalesHeader."No.", SalesLine."No.", SalesLine.Quantity / 2, SalesLine.Amount - LibraryERM.GetAmountRoundingPrecision());  // Using Random Value.
        SalesHeader.CalcFields(Amount);
        VATAmount := Round(SalesHeader.Amount * SalesLine."VAT %" / 100, LibraryERM.GetAmountRoundingPrecision());

        // Exercise.
        PostedCreditMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify.
        VerifyCustomerLedgerEntry(PostedCreditMemoNo, -(SalesHeader.Amount + VATAmount));
        VerifyGLEntry(PostedCreditMemoNo, SalesHeader.Amount + VATAmount);
    end;

    [Test]
    [HandlerFunctions('CopySalesDocumentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithoutSourceInvNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify Program create Sales Credit Memo without Source Inv No. on Header created from Copy Sales Document.
        // Setup.
        Initialize();
        DocumentNo := CreateAndPostSalesInvoice(SalesLine);

        // Exercise.
        CreateSalesCreditMemoFromPage(SalesHeader, DocumentNo, SalesLine."Sell-to Customer No.");

        // Verify.
        VerifySalesCreditMemo(SalesHeader, DocumentNo);  // Blank for Source Inv. No.
    end;

    [Test]
    [HandlerFunctions('CopySalesDocumentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesCreditMemoWithoutSourceInvNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        PostedCreditMemoNo: Code[20];
        VATAmount: Decimal;
    begin
        // Verify Program create and post Sales Credit Memo without Source Inv No. on Header created from Copy Sales Document.
        // Setup.
        Initialize();
        DocumentNo := CreateAndPostSalesInvoice(SalesLine);
        CreateSalesCreditMemoFromPage(SalesHeader, DocumentNo, SalesLine."Sell-to Customer No.");
        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", SalesHeader."No.");
        SalesHeader.CalcFields(Amount);
        VATAmount := (SalesHeader.Amount * SalesLine."VAT %") / 100;

        // Exercise.
        PostedCreditMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify.
        VerifyCustomerLedgerEntry(PostedCreditMemoNo, -(SalesHeader.Amount + VATAmount));
        VerifyGLEntry(PostedCreditMemoNo, SalesHeader.Amount + VATAmount);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibraryERM.SetEnableDataCheck(false);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesLine: Record "Sales Line"): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesInvoice(SalesLine, SalesLine.Type::Item, LibraryInventory.CreateItem(Item));
        SalesHeader.Get(SalesLine."Document Type"::Invoice, SalesLine."Document No.");
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));  // Post as Ship and Invoice.
    end;

    local procedure CreateAndPostSalesInvoiceWithGLAccount(var SalesLine: Record "Sales Line"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesInvoice(SalesLine, SalesLine.Type::"G/L Account", CreateGLAccount());
        SalesHeader.Get(SalesLine."Document Type"::Invoice, SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));  // Post as Ship and Invoice.
    end;

    local procedure CreateSalesCreditMemoFromPage(var SalesHeader: Record "Sales Header"; DocumentNo: Code[20]; SellToCustomerNo: Code[20])
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SellToCustomerNo);
        EnqueueValueForCopySalesDocument(DocumentNo, SalesHeader."Sell-to Customer No.");  // Enqueue value for CopySalesDocumentRequestPageHandler
        Commit();  // Commit is required.
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesCreditMemo.CopyDocument.Invoke();
    end;

    local procedure CreateSalesInvoice(var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; No: Code[20])
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        CreateSalesLine(SalesLine, SalesHeader, Type, No);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, LibraryRandom.RandDec(10, 2));  // Using Random Value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 500, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure DeleteSalesLine(DocumentNo: Code[20]; No: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("No.", No);
        SalesLine.FindFirst();
        SalesLine.Delete(true);
    end;

    local procedure EnqueueValueForCopySalesDocument(DocumentNo: Text; SellToCustomerNo: Text)
    begin
        // Enqueue value for CopySalesDocumentRequestPageHandler.
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(SellToCustomerNo);
    end;

    local procedure UpdateQuantityOnSalesLine(DocumentNo: Code[20]; No: Code[20]; Quantity: Decimal; LineAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("No.", No);
        SalesLine.FindFirst();
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Validate("Line Amount", Round(LineAmount / 2, LibraryERM.GetAmountRoundingPrecision()));
        SalesLine.Modify(true);
    end;

    local procedure RunBatchPostSales(DocumentNoFilter: Text)
    begin
        // Enqueue value for BatchPostSalesCrMemosRequestPageHandler.
        LibraryVariableStorage.Enqueue(DocumentNoFilter);
        Commit();  // Commit is required.
        REPORT.RunModal(REPORT::"Batch Post Sales Credit Memos", true, true);
    end;

    local procedure VerifyCustomerLedgerEntry(PostedCreditMemoNo: Code[20]; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", PostedCreditMemoNo);
        CustLedgerEntry.CalcFields(Amount);
        Assert.AreNearlyEqual(Amount, CustLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), UnexpectedErr);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        CreditAmount: Decimal;
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindSet();
        repeat
            CreditAmount += GLEntry."Credit Amount";
        until GLEntry.Next() = 0;
        Assert.AreNearlyEqual(CreditAmount, Amount, LibraryERM.GetAmountRoundingPrecision(), UnexpectedErr);
    end;

    local procedure VerifySalesCreditMemoJobQueueEntry(PreAssignedNo: Code[20])
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetFilter(Description, StrSubstNo(PostSaleslCreditMemoCap, FORMAT(PreAssignedNo)));
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Sales Post via Job Queue");

        Assert.IsTrue(JobQueueEntry.FindFirst(), JobQueueEntryErr);
    end;

    local procedure VerifySalesCreditMemo(SalesHeader: Record "Sales Header"; AppliesToDocNo: Code[20])
    begin
        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", SalesHeader."No.");
        SalesHeader.TestField("Applies-to Doc. Type", SalesHeader."Applies-to Doc. Type"::Invoice);
        SalesHeader.TestField("Applies-to Doc. No.", AppliesToDocNo);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopySalesDocumentRequestPageHandler(var CopySalesDocument: TestRequestPage "Copy Sales Document")
    var
        DocumentNo: Variant;
        SellToCustNo: Variant;
        DocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo","Arch. Quote","Arch. Order","Arch. Blanket Order","Arch. Return Order";
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        LibraryVariableStorage.Dequeue(SellToCustNo);
        CopySalesDocument.DocumentType.SetValue(Format(DocType::"Posted Invoice"));
        CopySalesDocument.DocumentNo.SetValue(DocumentNo);
        CopySalesDocument.SellToCustNo.SetValue(SellToCustNo);
        CopySalesDocument.RecalculateLines.SetValue(false);
        CopySalesDocument.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostSalesCrMemosRequestPageHandler(var BatchPostSalesCreditMemos: TestRequestPage "Batch Post Sales Credit Memos")
    var
        SalesHeader: Record "Sales Header";
        DocumentNoFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        BatchPostSalesCreditMemos."Sales Header".SetFilter("No.", DocumentNoFilter);
        BatchPostSalesCreditMemos."Sales Header".SetFilter("Document Type", Format(SalesHeader."Document Type"::"Credit Memo"));
        BatchPostSalesCreditMemos.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;
}
