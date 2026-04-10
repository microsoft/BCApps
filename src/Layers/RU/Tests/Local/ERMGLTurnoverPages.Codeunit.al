codeunit 144104 "ERM G/L Turnover Pages"
{
    // // [FEATURE] [G/L Turnover]
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRUReports: Codeunit "Library RU Reports";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('GLAccountTurnoverPageHandler,GLEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure GLAccountTurnoverPage()
    var
        GLAccount: Record "G/L Account";
        GenJnlLine: Record "Gen. Journal Line";
        GLAccountTurnover: Page "G/L Account Turnover";
        DebitGLAccNo: Code[20];
        DebitAmount: Decimal;
        CreditAmount: Decimal;
    begin
        Initialize();

        CreateGLAccountWithBalance(DebitGLAccNo, DebitAmount);
        CreditAmount := CreatePostGenJnlLine(GenJnlLine."Account Type"::"G/L Account", DebitGLAccNo, '', -1);
        LibraryVariableStorage.Enqueue(DebitAmount);
        LibraryVariableStorage.Enqueue(CreditAmount);

        SetGLAccountFilters(GLAccount, DebitGLAccNo);

        Clear(GLAccountTurnover);
        GLAccountTurnover.SetTableView(GLAccount);
        GLAccountTurnover.Run();
    end;

    [Test]
    [HandlerFunctions('CustomerTurnoverPageHandler,GLEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerGLTurnoverPage()
    var
        Customer: Record Customer;
        GenJnlLine: Record "Gen. Journal Line";
        CustomerGLTurnover: Page "Customer G/L Turnover";
        Amount: Decimal;
    begin
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        Amount := CreatePostGenJnlLine(GenJnlLine."Account Type"::Customer, Customer."No.", '', 1);
        LibraryVariableStorage.Enqueue(Amount);

        Customer.SetFilter("Date Filter", Format(WorkDate()));
        Customer.SetRecFilter();

        Clear(CustomerGLTurnover);
        CustomerGLTurnover.SetTableView(Customer);
        CustomerGLTurnover.Run();
    end;

    [Test]
    [HandlerFunctions('VendorTurnoverPageHandler,GLEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure VendorGLTurnoverPage()
    var
        Vendor: Record Vendor;
        GenJnlLine: Record "Gen. Journal Line";
        VendorGLTurnover: Page "Vendor G/L Turnover";
        Amount: Decimal;
    begin
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        Amount := CreatePostGenJnlLine(GenJnlLine."Account Type"::Vendor, Vendor."No.", '', 1);
        LibraryVariableStorage.Enqueue(Amount);

        Vendor.SetFilter("Date Filter", Format(WorkDate()));
        Vendor.SetRecFilter();

        Clear(VendorGLTurnover);
        VendorGLTurnover.SetTableView(Vendor);
        VendorGLTurnover.Run();
    end;

    [Test]
    [HandlerFunctions('CustomerTurnoverByAgrPageHandler,GLEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerGLTurnoverByAgrPage()
    var
        Customer: Record Customer;
        CustomerAgreement: Record "Customer Agreement";
        GenJnlLine: Record "Gen. Journal Line";
        CustomerGLTurnoverAgr: Page "Customer G/L Turnover Agr.";
        Amount: Decimal;
    begin
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        Customer."Agreement Posting" := Customer."Agreement Posting"::Mandatory;
        Customer.Modify(true);
        CreateCustomerAgreement(CustomerAgreement, Customer."No.", true);
        Amount := CreatePostGenJnlLine(GenJnlLine."Account Type"::Customer, Customer."No.", CustomerAgreement."No.", 1);
        LibraryVariableStorage.Enqueue(Amount);

        CustomerAgreement.SetFilter("Date Filter", Format(WorkDate()));
        CustomerAgreement.SetRecFilter();

        Clear(CustomerGLTurnoverAgr);
        CustomerGLTurnoverAgr.SetTableView(CustomerAgreement);
        CustomerGLTurnoverAgr.Run();
    end;

    [Test]
    [HandlerFunctions('VendorTurnoverByAgrPageHandler,GLEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure VendorGLTurnoverByAgrPage()
    var
        Vendor: Record Vendor;
        VendorAgreement: Record "Vendor Agreement";
        GenJnlLine: Record "Gen. Journal Line";
        VendorGLTurnoverAgr: Page "Vendor G/L Turnover Agr.";
        Amount: Decimal;
    begin
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Agreement Posting" := Vendor."Agreement Posting"::Mandatory;
        Vendor.Modify(true);
        CreateVendorAgreement(VendorAgreement, Vendor."No.", true);
        Amount := CreatePostGenJnlLine(GenJnlLine."Account Type"::Vendor, Vendor."No.", VendorAgreement."No.", 1);
        LibraryVariableStorage.Enqueue(Amount);

        VendorAgreement.SetFilter("Date Filter", Format(WorkDate()));
        VendorAgreement.SetRecFilter();

        Clear(VendorGLTurnoverAgr);
        VendorGLTurnoverAgr.SetTableView(VendorAgreement);
        VendorGLTurnoverAgr.Run();
    end;

    [Test]
    [HandlerFunctions('FATurnoverPageHandler,GLEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure FAGLTurnoverPage()
    var
        FixedAsset: Record "Fixed Asset";
        GenJnlLine: Record "Gen. Journal Line";
        FAGLTurnover: Page "FA G/L Turnover";
        Amount: Decimal;
    begin
        Initialize();

        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset);
        Amount := CreatePostGenJnlLine(GenJnlLine."Account Type"::"Fixed Asset", FixedAsset."No.", '', 1);
        LibraryVariableStorage.Enqueue(Amount);

        FixedAsset.SetFilter("Date Filter", Format(WorkDate()));
        FixedAsset.SetRecFilter();

        Clear(FAGLTurnover);
        FAGLTurnover.SetTableView(FixedAsset);
        FAGLTurnover.Run();
    end;

    [Test]
    [HandlerFunctions('ItemTurnoverPageHandler,ValueEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTurnoverPage()
    var
        Item: Record Item;
        ItemGLTurnover: Page "Item G/L Turnover";
        Qty: Decimal;
    begin
        Initialize();
        LibraryInventory.CreateItem(Item);
        Qty := LibraryRandom.RandDecInRange(10, 20, 2);
        LibraryRUReports.CreateAndPostItemJournalLine('', Item."No.", Qty, false);
        LibraryVariableStorage.Enqueue(Qty);

        Item.SetFilter("Date Filter", Format(WorkDate()));
        Item.SetRecFilter();
        Clear(ItemGLTurnover);
        ItemGLTurnover.SetTableView(Item);
        ItemGLTurnover.Run();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnOpenGLAccountTurnoverPageFiltersSourceTypeAndNo()
    var
        GLAccountTurnover: TestPage "G/L Account Turnover";
        GLAccountNo: Code[20];
        CustomerNo: array[2] of Code[20];
        VendorNo: array[2] of Code[20];
        CreditAmount: array[2] of Decimal;
        DebitAmount: array[2] of Decimal;
        SourceType: Option " ",Customer,Vendor,"Bank Account","Fixed Asset";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 253909] Page 12405 "G/L Account Turnover" filters the result by SourceType, SourceNo when it is reopened after filter set
        Initialize();

        // [GIVEN] G/L Account "A"
        // [GIVEN] Posted customer "C1" journal with balance G/L Account "A" and Amount = 100
        // [GIVEN] Posted customer "C2" journal with balance G/L Account "A" and Amount = 200
        // [GIVEN] Posted vendor "V1" journal with balance G/L Account "A" and Amount = 300
        // [GIVEN] Posted vendor "V2" journal with balance G/L Account "A" and Amount = 400
        PreparetCustomerVendorGLAccountBalance(GLAccountNo, VendorNo, CustomerNo, DebitAmount, CreditAmount);

        // [GIVEN] Open Page 12405 "G/L Account Turnover"
        // [GIVEN] Filter "G/L Account Filter" = "A"
        // [GIVEN] "Debit Amount" = 700, "Credit Amount" = 300, "Balance at End Period" = 400
        OpenGLAccountTurnoverPage(GLAccountTurnover, GLAccountNo, SourceType::" ", '');
        VerifyGLAccountTurnoverPageValues(
          GLAccountTurnover, DebitAmount[1] + DebitAmount[2], CreditAmount[1] + CreditAmount[2],
          DebitAmount[1] + DebitAmount[2] - (CreditAmount[1] + CreditAmount[2]));

        // [GIVEN] Filter "Source Type" = "Customer"
        // [GIVEN] Filter "Source No" = "C1"
        // [GIVEN] "Debit Amount" = 0, "Credit Amount" = 100, "Balance at End Period" = -100
        GLAccountTurnover.SourceType.SetValue(SourceType::Customer);
        GLAccountTurnover.SourceNo.SetValue(CustomerNo[1]);
        VerifyGLAccountTurnoverPageValues(GLAccountTurnover, 0, CreditAmount[1], -CreditAmount[1]);
        // [GIVEN] Close the page
        GLAccountTurnover.Close();

        // [WHEN] Open Page 12405 "G/L Account Turnover" again
        GLAccountTurnover.OpenEdit();

        // [THEN] "Debit Amount" = 0, "Credit Amount" = 100, "Balance at End Period" = -100
        VerifyGLAccountTurnoverPageValues(GLAccountTurnover, 0, CreditAmount[1], -CreditAmount[1]);
        GLAccountTurnover.Close();
    end;

    [Test]
    [HandlerFunctions('GLAccountEntriesAnalysisRPH')]
    [Scope('OnPrem')]
    procedure GLAccountEntriesAnalysis_BlankedSourceTypeAndNoFilters()
    var
        GLAccountTurnover: TestPage "G/L Account Turnover";
        SourceType: Option " ",Customer,Vendor,"Bank Account","Fixed Asset";
        GLAccountNo: Code[20];
        CustomerNo: array[2] of Code[20];
        VendorNo: array[2] of Code[20];
        CreditAmount: array[2] of Decimal;
        DebitAmount: array[2] of Decimal;
    begin
        // [FEATURE] [UI] [Report] [G/L Account Entries Analysis]
        // [SCENARIO 253908] Run REP 12438 "G/L Account Entries Analysis" from the G/L Account Turnover page with blanked Source Type\No filters
        Initialize();

        // [GIVEN] G/L Account "A"
        // [GIVEN] Posted customer "C1" journal with balance G/L Account "A" and Amount = 100
        // [GIVEN] Posted customer "C2" journal with balance G/L Account "A" and Amount = 200
        // [GIVEN] Posted vendor "V1" journal with balance G/L Account "A" and Amount = 300
        // [GIVEN] Posted vendor "V2" journal with balance G/L Account "A" and Amount = 400
        PreparetCustomerVendorGLAccountBalance(GLAccountNo, VendorNo, CustomerNo, DebitAmount, CreditAmount);

        // [GIVEN] Open Page 12405 "G/L Account Turnover"
        // [GIVEN] Filter "G/L Account Filter" = "A"
        OpenGLAccountTurnoverPage(GLAccountTurnover, GLAccountNo, SourceType::" ", '');

        // [WHEN] Run REP 12438 "G/L Account Entries Analysis" from the G/L Account Turnover page
        GLAccountTurnover.GLAccountEntries.Invoke();
        GLAccountTurnover.Close();

        // [THEN] The report prints:
        // [THEN] Net Change Debit = 700
        // [THEN] Net Change Credit = 300
        // [THEN] Balance Ending = 400
        VerifyGLAccountEntriesAnalysisReportValues(DebitAmount[1] + DebitAmount[2], CreditAmount[1] + CreditAmount[2]);
    end;

    [Test]
    [HandlerFunctions('GLAccountEntriesAnalysisRPH')]
    [Scope('OnPrem')]
    procedure GLAccountEntriesAnalysis_SourceType_Customer()
    var
        GLAccountTurnover: TestPage "G/L Account Turnover";
        SourceType: Option " ",Customer,Vendor,"Bank Account","Fixed Asset";
        GLAccountNo: Code[20];
        CustomerNo: array[2] of Code[20];
        VendorNo: array[2] of Code[20];
        CreditAmount: array[2] of Decimal;
        DebitAmount: array[2] of Decimal;
    begin
        // [FEATURE] [UI] [Report] [G/L Account Entries Analysis]
        // [SCENARIO 253908] Run REP 12438 "G/L Account Entries Analysis" from the G/L Account Turnover page with Source Type filter = "Customer", Source No = ""
        Initialize();

        // [GIVEN] G/L Account "A"
        // [GIVEN] Posted customer "C1" journal with balance G/L Account "A" and Amount = 100
        // [GIVEN] Posted customer "C2" journal with balance G/L Account "A" and Amount = 200
        // [GIVEN] Posted vendor "V1" journal with balance G/L Account "A" and Amount = 300
        // [GIVEN] Posted vendor "V2" journal with balance G/L Account "A" and Amount = 400
        PreparetCustomerVendorGLAccountBalance(GLAccountNo, VendorNo, CustomerNo, DebitAmount, CreditAmount);

        // [GIVEN] Open Page 12405 "G/L Account Turnover"
        // [GIVEN] Filter "G/L Account Filter" = "A"
        // [GIVEN] Filter "Source Type" = "Customer"
        OpenGLAccountTurnoverPage(GLAccountTurnover, GLAccountNo, SourceType::Customer, '');

        // [WHEN] Run REP 12438 "G/L Account Entries Analysis" from the G/L Account Turnover page
        GLAccountTurnover.GLAccountEntries.Invoke();
        GLAccountTurnover.Close();

        // [THEN] The report prints:
        // [THEN] Net Change Debit = 0
        // [THEN] Net Change Credit = 300
        // [THEN] Balance Ending = 300
        VerifyGLAccountEntriesAnalysisReportValues(0, CreditAmount[1] + CreditAmount[2]);
    end;

    [Test]
    [HandlerFunctions('GLAccountEntriesAnalysisRPH')]
    [Scope('OnPrem')]
    procedure GLAccountEntriesAnalysis_SourceType_Vendor()
    var
        GLAccountTurnover: TestPage "G/L Account Turnover";
        SourceType: Option " ",Customer,Vendor,"Bank Account","Fixed Asset";
        GLAccountNo: Code[20];
        CustomerNo: array[2] of Code[20];
        VendorNo: array[2] of Code[20];
        CreditAmount: array[2] of Decimal;
        DebitAmount: array[2] of Decimal;
    begin
        // [FEATURE] [UI] [Report] [G/L Account Entries Analysis]
        // [SCENARIO 253908] Run REP 12438 "G/L Account Entries Analysis" from the G/L Account Turnover page with Source Type filter = "Vendor", Source No = ""
        Initialize();

        // [GIVEN] G/L Account "A"
        // [GIVEN] Posted customer "C1" journal with balance G/L Account "A" and Amount = 100
        // [GIVEN] Posted customer "C2" journal with balance G/L Account "A" and Amount = 200
        // [GIVEN] Posted vendor "V1" journal with balance G/L Account "A" and Amount = 300
        // [GIVEN] Posted vendor "V2" journal with balance G/L Account "A" and Amount = 400
        PreparetCustomerVendorGLAccountBalance(GLAccountNo, VendorNo, CustomerNo, DebitAmount, CreditAmount);

        // [GIVEN] Open Page 12405 "G/L Account Turnover"
        // [GIVEN] Filter "G/L Account Filter" = "A"
        // [GIVEN] Filter "Source Type" = "Vendor"
        OpenGLAccountTurnoverPage(GLAccountTurnover, GLAccountNo, SourceType::Vendor, '');

        // [WHEN] Run REP 12438 "G/L Account Entries Analysis" from the G/L Account Turnover page
        GLAccountTurnover.GLAccountEntries.Invoke();
        GLAccountTurnover.Close();

        // [THEN] The report prints:
        // [THEN] Net Change Debit = 700
        // [THEN] Net Change Credit = 0
        // [THEN] Balance Ending = 700
        VerifyGLAccountEntriesAnalysisReportValues(DebitAmount[1] + DebitAmount[2], 0);
    end;

    [Test]
    [HandlerFunctions('GLAccountEntriesAnalysisRPH')]
    [Scope('OnPrem')]
    procedure GLAccountEntriesAnalysis_SourceNo_Customer()
    var
        GLAccountTurnover: TestPage "G/L Account Turnover";
        SourceType: Option " ",Customer,Vendor,"Bank Account","Fixed Asset";
        GLAccountNo: Code[20];
        CustomerNo: array[2] of Code[20];
        VendorNo: array[2] of Code[20];
        CreditAmount: array[2] of Decimal;
        DebitAmount: array[2] of Decimal;
    begin
        // [FEATURE] [UI] [Report] [G/L Account Entries Analysis]
        // [SCENARIO 253908] Run REP 12438 "G/L Account Entries Analysis" from the G/L Account Turnover page with Source Type filter = "", Source No = 10000 (customer)
        Initialize();

        // [GIVEN] G/L Account "A"
        // [GIVEN] Posted customer "C1" journal with balance G/L Account "A" and Amount = 100
        // [GIVEN] Posted customer "C2" journal with balance G/L Account "A" and Amount = 200
        // [GIVEN] Posted vendor "V1" journal with balance G/L Account "A" and Amount = 300
        // [GIVEN] Posted vendor "V2" journal with balance G/L Account "A" and Amount = 400
        PreparetCustomerVendorGLAccountBalance(GLAccountNo, VendorNo, CustomerNo, DebitAmount, CreditAmount);

        // [GIVEN] Open Page 12405 "G/L Account Turnover"
        // [GIVEN] Filter "G/L Account Filter" = "A"
        // [GIVEN] Filter "Source Type" = "", Source No = "C2"
        OpenGLAccountTurnoverPage(GLAccountTurnover, GLAccountNo, SourceType::" ", CustomerNo[2]);

        // [WHEN] Run REP 12438 "G/L Account Entries Analysis" from the G/L Account Turnover page
        GLAccountTurnover.GLAccountEntries.Invoke();
        GLAccountTurnover.Close();

        // [THEN] The report prints:
        // [THEN] Net Change Debit = 0
        // [THEN] Net Change Credit = 200
        // [THEN] Balance Ending = 200
        VerifyGLAccountEntriesAnalysisReportValues(0, CreditAmount[2]);
    end;

    [Test]
    [HandlerFunctions('GLAccountEntriesAnalysisRPH')]
    [Scope('OnPrem')]
    procedure GLAccountEntriesAnalysis_SourceNo_Vendor()
    var
        GLAccountTurnover: TestPage "G/L Account Turnover";
        SourceType: Option " ",Customer,Vendor,"Bank Account","Fixed Asset";
        GLAccountNo: Code[20];
        CustomerNo: array[2] of Code[20];
        VendorNo: array[2] of Code[20];
        CreditAmount: array[2] of Decimal;
        DebitAmount: array[2] of Decimal;
    begin
        // [FEATURE] [UI] [Report] [G/L Account Entries Analysis]
        // [SCENARIO 253908] Run REP 12438 "G/L Account Entries Analysis" from the G/L Account Turnover page with Source Type filter = "", Source No = 10000 (vendor)
        Initialize();

        // [GIVEN] G/L Account "A"
        // [GIVEN] Posted customer "C1" journal with balance G/L Account "A" and Amount = 100
        // [GIVEN] Posted customer "C2" journal with balance G/L Account "A" and Amount = 200
        // [GIVEN] Posted vendor "V1" journal with balance G/L Account "A" and Amount = 300
        // [GIVEN] Posted vendor "V2" journal with balance G/L Account "A" and Amount = 400
        PreparetCustomerVendorGLAccountBalance(GLAccountNo, VendorNo, CustomerNo, DebitAmount, CreditAmount);

        // [GIVEN] Open Page 12405 "G/L Account Turnover"
        // [GIVEN] Filter "G/L Account Filter" = "A"
        // [GIVEN] Filter "Source Type" = "", Source No = "V2"
        OpenGLAccountTurnoverPage(GLAccountTurnover, GLAccountNo, SourceType::" ", VendorNo[2]);

        // [WHEN] Run REP 12438 "G/L Account Entries Analysis" from the G/L Account Turnover page
        GLAccountTurnover.GLAccountEntries.Invoke();
        GLAccountTurnover.Close();

        // [THEN] The report prints:
        // [THEN] Net Change Debit = 400
        // [THEN] Net Change Credit = 0
        // [THEN] Balance Ending = 400
        VerifyGLAccountEntriesAnalysisReportValues(DebitAmount[2], 0);
    end;

    [Test]
    [HandlerFunctions('GLAccountEntriesAnalysisRPH')]
    [Scope('OnPrem')]
    procedure GLAccountEntriesAnalysis_SourceTypeAndNo_Customer()
    var
        GLAccountTurnover: TestPage "G/L Account Turnover";
        SourceType: Option " ",Customer,Vendor,"Bank Account","Fixed Asset";
        GLAccountNo: Code[20];
        CustomerNo: array[2] of Code[20];
        VendorNo: array[2] of Code[20];
        CreditAmount: array[2] of Decimal;
        DebitAmount: array[2] of Decimal;
    begin
        // [FEATURE] [UI] [Report] [G/L Account Entries Analysis]
        // [SCENARIO 253908] Run REP 12438 "G/L Account Entries Analysis" from the G/L Account Turnover page with Source Type filter = "Customer", Source No = 10000
        Initialize();

        // [GIVEN] G/L Account "A"
        // [GIVEN] Posted customer "C1" journal with balance G/L Account "A" and Amount = 100
        // [GIVEN] Posted customer "C2" journal with balance G/L Account "A" and Amount = 200
        // [GIVEN] Posted vendor "V1" journal with balance G/L Account "A" and Amount = 300
        // [GIVEN] Posted vendor "V2" journal with balance G/L Account "A" and Amount = 400
        PreparetCustomerVendorGLAccountBalance(GLAccountNo, VendorNo, CustomerNo, DebitAmount, CreditAmount);

        // [GIVEN] Open Page 12405 "G/L Account Turnover"
        // [GIVEN] Filter "G/L Account Filter" = "A"
        // [GIVEN] Filter "Source Type" = "Customer", Source No = "C1"
        OpenGLAccountTurnoverPage(GLAccountTurnover, GLAccountNo, SourceType::Customer, CustomerNo[1]);

        // [WHEN] Run REP 12438 "G/L Account Entries Analysis" from the G/L Account Turnover page
        GLAccountTurnover.GLAccountEntries.Invoke();
        GLAccountTurnover.Close();

        // [THEN] The report prints:
        // [THEN] Net Change Debit = 0
        // [THEN] Net Change Credit = 100
        // [THEN] Balance Ending = 100
        VerifyGLAccountEntriesAnalysisReportValues(0, CreditAmount[1]);
    end;

    [Test]
    [HandlerFunctions('GLAccountEntriesAnalysisRPH')]
    [Scope('OnPrem')]
    procedure GLAccountEntriesAnalysis_SourceTypeAndNo_Vendor()
    var
        GLAccountTurnover: TestPage "G/L Account Turnover";
        SourceType: Option " ",Customer,Vendor,"Bank Account","Fixed Asset";
        GLAccountNo: Code[20];
        CustomerNo: array[2] of Code[20];
        VendorNo: array[2] of Code[20];
        CreditAmount: array[2] of Decimal;
        DebitAmount: array[2] of Decimal;
    begin
        // [FEATURE] [UI] [Report] [G/L Account Entries Analysis]
        // [SCENARIO 253908] Run REP 12438 "G/L Account Entries Analysis" from the G/L Account Turnover page with Source Type filter = "Vendor", Source No = 10000
        Initialize();

        // [GIVEN] G/L Account "A"
        // [GIVEN] Posted customer "C1" journal with balance G/L Account "A" and Amount = 100
        // [GIVEN] Posted customer "C2" journal with balance G/L Account "A" and Amount = 200
        // [GIVEN] Posted vendor "V1" journal with balance G/L Account "A" and Amount = 300
        // [GIVEN] Posted vendor "V2" journal with balance G/L Account "A" and Amount = 400
        PreparetCustomerVendorGLAccountBalance(GLAccountNo, VendorNo, CustomerNo, DebitAmount, CreditAmount);

        // [GIVEN] Open Page 12405 "G/L Account Turnover"
        // [GIVEN] Filter "G/L Account Filter" = "A"
        // [GIVEN] Filter "Source Type" = "Vendor", Source No = "V1"
        OpenGLAccountTurnoverPage(GLAccountTurnover, GLAccountNo, SourceType::Vendor, VendorNo[1]);

        // [WHEN] Run REP 12438 "G/L Account Entries Analysis" from the G/L Account Turnover page
        GLAccountTurnover.GLAccountEntries.Invoke();
        GLAccountTurnover.Close();

        // [THEN] The report prints:
        // [THEN] Net Change Debit = 300
        // [THEN] Net Change Credit = 0
        // [THEN] Balance Ending = 300
        VerifyGLAccountEntriesAnalysisReportValues(DebitAmount[1], 0);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
    end;

    local procedure PreparetCustomerVendorGLAccountBalance(var GLAccountNo: Code[20]; var VendorNo: array[2] of Code[20]; var CustomerNo: array[2] of Code[20]; var DebitAmount: array[2] of Decimal; var CreditAmount: array[2] of Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        i: Integer;
    begin
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        for i := 1 to ArrayLen(CustomerNo) do begin
            VendorNo[i] := LibraryPurchase.CreateVendorNo();
            DebitAmount[i] :=
              CreatePostGenJnlLineWithGivenBalanceGLAccount(GenJournalLine."Account Type"::Vendor, VendorNo[i], '', -1, GLAccountNo);

            CustomerNo[i] := LibrarySales.CreateCustomerNo();
            CreditAmount[i] :=
              CreatePostGenJnlLineWithGivenBalanceGLAccount(GenJournalLine."Account Type"::Customer, CustomerNo[i], '', 1, GLAccountNo);
        end;
    end;

    local procedure CreateGLAccountWithBalance(var GLAccountNo: Code[20]; var Amount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        Amount := CreatePostGenJnlLine(GenJnlLine."Account Type"::"G/L Account", GLAccountNo, '', 1);
    end;

    local procedure CreateCustomerAgreement(var CustomerAgreement: Record "Customer Agreement"; CustomerNo: Code[20]; IsActive: Boolean)
    begin
        CustomerAgreement.Init();
        CustomerAgreement."Customer No." := CustomerNo;
        CustomerAgreement.Active := IsActive;
        CustomerAgreement."Expire Date" := CalcDate('<1M>', WorkDate());
        CustomerAgreement.Insert(true);
    end;

    local procedure CreateVendorAgreement(var VendorAgreement: Record "Vendor Agreement"; VendorNo: Code[20]; IsActive: Boolean)
    begin
        VendorAgreement.Init();
        VendorAgreement."Vendor No." := VendorNo;
        VendorAgreement.Active := IsActive;
        VendorAgreement."Expire Date" := CalcDate('<1M>', WorkDate());
        VendorAgreement.Insert(true);
    end;

    local procedure CreatePostGenJnlLine(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; AgrNo: Code[20]; Sign: Integer): Decimal
    begin
        exit(CreatePostGenJnlLineWithGivenBalanceGLAccount(AccType, AccNo, AgrNo, Sign, LibraryERM.CreateGLAccountNo()));
    end;

    local procedure CreatePostGenJnlLineWithGivenBalanceGLAccount(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; AgrNo: Code[20]; Sign: Integer; BalanceGLAccNo: Code[20]): Decimal
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
    begin
        Amount := LibraryRandom.RandDecInRange(100, 200, 2);
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJnlLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          "Gen. Journal Account Type"::"G/L Account", AccType, AccNo,
          GenJnlLine."Bal. Account Type"::"G/L Account", BalanceGLAccNo, Amount * Sign);
        UpdateFAPostingType(GenJnlLine);
        if AgrNo <> '' then begin
            GenJnlLine.Validate("Agreement No.", AgrNo);
            GenJnlLine.Modify(true);
        end;
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        exit(GenJnlLine.Amount * Sign);
    end;

    local procedure SetGLAccountFilters(var GLAccount: Record "G/L Account"; GLAccNo: Code[20])
    begin
        GLAccount.Get(GLAccNo);
        GLAccount.SetFilter("Date Filter", Format(WorkDate()));
        GLAccount.SetRecFilter();
    end;

    local procedure UpdateFAPostingType(var GenJnlLine: Record "Gen. Journal Line")
    begin
        if GenJnlLine."Account Type" <> GenJnlLine."Account Type"::"Fixed Asset" then
            exit;

        GenJnlLine.Validate("FA Posting Type", GenJnlLine."FA Posting Type"::"Acquisition Cost");
        GenJnlLine.Modify(true);
    end;

    local procedure OpenGLAccountTurnoverPage(var GLAccountTurnover: TestPage "G/L Account Turnover"; GLAccountNo: Code[20]; SourceType: Option; SourceNo: Code[20])
    begin
        GLAccountTurnover.OpenEdit();
        GLAccountTurnover."G/L Account Filter".SetValue(GLAccountNo);
        GLAccountTurnover.SourceType.SetValue(SourceType);
        GLAccountTurnover.SourceNo.SetValue(SourceNo);
    end;

    local procedure FormatDecimal(DecimalValue: Decimal): Text
    begin
        exit(Format(DecimalValue, 0, '<Sign><Integer Thousand><Decimals,3>'));
    end;

    local procedure VerifyGLAccountTurnoverPageValues(var GLAccountTurnover: TestPage "G/L Account Turnover"; ExpectedDebit: Decimal; ExpectedCredit: Decimal; ExpectedBalance: Decimal)
    begin
        GLAccountTurnover."Debit Amount".AssertEquals(ExpectedDebit);
        GLAccountTurnover."Credit Amount".AssertEquals(ExpectedCredit);
        GLAccountTurnover."Balance at End Period".AssertEquals(ExpectedBalance);
    end;

    local procedure VerifyGLAccountEntriesAnalysisReportValues(Debit: Decimal; Credit: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.MoveToRow(1);
        LibraryReportDataset.AssertCurrentRowValueEquals('DebitAmountText', FormatDecimal(Debit));
        LibraryReportDataset.AssertCurrentRowValueEquals('CreditAmountText', '');
        LibraryReportDataset.AssertCurrentRowValueEquals('NetChangeDebitGLAcc', Debit);
        LibraryReportDataset.AssertCurrentRowValueEquals('NetChangeCreditGLAcc', Credit);

        LibraryReportDataset.MoveToRow(2);
        LibraryReportDataset.AssertCurrentRowValueEquals('DebitAmountText', '');
        LibraryReportDataset.AssertCurrentRowValueEquals('CreditAmountText', FormatDecimal(Credit));
        LibraryReportDataset.AssertCurrentRowValueEquals('NetChangeDebitGLAcc', Debit);
        LibraryReportDataset.AssertCurrentRowValueEquals('NetChangeCreditGLAcc', Credit);

        LibraryReportDataset.GetLastRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('BalanceEnding', Abs(Debit - Credit));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLAccountTurnoverPageHandler(var GLAccountTurnover: TestPage "G/L Account Turnover")
    var
        DebitAmount: Variant;
        CreditAmount: Variant;
    begin
        GLAccountTurnover.PeriodType.SetValue(0);
        GLAccountTurnover.First();
        LibraryVariableStorage.Dequeue(DebitAmount);
        Assert.AreEqual(DebitAmount, GLAccountTurnover."Debit Amount".AsDecimal(), 'incorrect debit amount');
        GLAccountTurnover."Debit Amount".DrillDown();
        LibraryVariableStorage.Dequeue(CreditAmount);
        Assert.AreEqual(CreditAmount, GLAccountTurnover."Credit Amount".AsDecimal(), 'incorrect credit amount');
        GLAccountTurnover."Credit Amount".DrillDown();
        GLAccountTurnover.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerTurnoverPageHandler(var CustomerGLTurnover: TestPage "Customer G/L Turnover")
    var
        Amount: Variant;
    begin
        CustomerGLTurnover.PeriodType.SetValue(0);
        CustomerGLTurnover.First();
        LibraryVariableStorage.Dequeue(Amount);
        Assert.AreEqual(Amount, CustomerGLTurnover."G/L Debit Amount".AsDecimal(), 'incorrect amount');
        CustomerGLTurnover."G/L Debit Amount".DrillDown();
        CustomerGLTurnover.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure VendorTurnoverPageHandler(var VendorGLTurnover: TestPage "Vendor G/L Turnover")
    var
        Amount: Variant;
    begin
        VendorGLTurnover.PeriodType.SetValue(0);
        VendorGLTurnover.First();
        LibraryVariableStorage.Dequeue(Amount);
        Assert.AreEqual(Amount, VendorGLTurnover."G/L Debit Amount".AsDecimal(), 'incorrect amount');
        VendorGLTurnover."G/L Debit Amount".DrillDown();
        VendorGLTurnover.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure FATurnoverPageHandler(var FAGLTurnover: TestPage "FA G/L Turnover")
    var
        Amount: Variant;
    begin
        FAGLTurnover.PeriodType.SetValue(0);
        FAGLTurnover.First();
        LibraryVariableStorage.Dequeue(Amount);
        Assert.AreEqual(Amount, FAGLTurnover."G/L Debit Amount".AsDecimal(), 'incorrect amount');
        FAGLTurnover."G/L Debit Amount".DrillDown();
        FAGLTurnover.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ItemTurnoverPageHandler(var ItemGLTurnover: TestPage "Item G/L Turnover")
    begin
        ItemGLTurnover.PeriodType.SetValue(0);
        ItemGLTurnover.First();
        ItemGLTurnover.DebitQuantity.DrillDown();
        ItemGLTurnover.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerTurnoverByAgrPageHandler(var CustomerGLTurnoverAgr: TestPage "Customer G/L Turnover Agr.")
    var
        Amount: Variant;
    begin
        CustomerGLTurnoverAgr.PeriodType.SetValue(0);
        CustomerGLTurnoverAgr.First();
        LibraryVariableStorage.Dequeue(Amount);
        Assert.AreEqual(Amount, CustomerGLTurnoverAgr."G/L Debit Amount".AsDecimal(), 'incorrect amount');
        CustomerGLTurnoverAgr."G/L Debit Amount".DrillDown();
        CustomerGLTurnoverAgr.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure VendorTurnoverByAgrPageHandler(var VendorGLTurnoverAgr: TestPage "Vendor G/L Turnover Agr.")
    var
        Amount: Variant;
    begin
        VendorGLTurnoverAgr.PeriodType.SetValue(0);
        VendorGLTurnoverAgr.First();
        LibraryVariableStorage.Dequeue(Amount);
        Assert.AreEqual(Amount, VendorGLTurnoverAgr."G/L Debit Amount".AsDecimal(), 'incorrect amount');
        VendorGLTurnoverAgr."G/L Debit Amount".DrillDown();
        VendorGLTurnoverAgr.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLEntriesPageHandler(var GeneralLedgerEntries: TestPage "General Ledger Entries")
    begin
        GeneralLedgerEntries.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ValueEntriesPageHandler(var ValueEntries: TestPage "Value Entries")
    begin
        ValueEntries.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLAccountEntriesAnalysisRPH(var GLAccountEntriesAnalysis: TestRequestPage "G/L Account Entries Analysis")
    begin
        GLAccountEntriesAnalysis.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

