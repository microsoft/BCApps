codeunit 134093 "ERM G/L Account Where-Used"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Account Where-Used]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryService: Codeunit "Library - Service";
        Assert: Codeunit Assert;
        CalcGLAccWhereUsed: Codeunit "Calc. G/L Acc. Where-Used";
        isInitialized: Boolean;
        InvalidTableCaptionErr: Label 'Invalid table caption.';
        InvalidFieldCaptionErr: Label 'Invalid field caption.';
        InvalidLineValueErr: Label 'Invalid Line value.';

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckCustPostingGroup()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Initialize();
        // [GIVEN] Customer Posting Group with "Invoice Rounding Account" = "G"
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup.Validate("Invoice Rounding Account", LibraryERM.CreateGLAccountWithSalesSetup());
        CustomerPostingGroup.Modify();

        // [WHEN] Run Where-Used function for G/L Accoun "G"
        CalcGLAccWhereUsed.CheckGLAcc(CustomerPostingGroup."Invoice Rounding Account");

        // [THEN] G/L Account "G" is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          CustomerPostingGroup.TableCaption(),
          CustomerPostingGroup.FieldCaption("Invoice Rounding Account"),
          StrSubstNo('%1=%2', CustomerPostingGroup.FieldCaption(Code), CustomerPostingGroup.Code));
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckVendPostingGroup()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Initialize();
        // [GIVEN] Vendor Posting Group with "Invoice Rounding Account" = "G"
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        VendorPostingGroup.Validate("Invoice Rounding Account", LibraryERM.CreateGLAccountWithPurchSetup());
        VendorPostingGroup.Modify();

        // [WHEN] Run Where-Used function for G/L Accoun "G"
        CalcGLAccWhereUsed.CheckGLAcc(VendorPostingGroup."Invoice Rounding Account");

        // [THEN] G/L Account "G" is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          VendorPostingGroup.TableCaption(),
          VendorPostingGroup.FieldCaption("Invoice Rounding Account"),
          StrSubstNo('%1=%2', VendorPostingGroup.FieldCaption(Code), VendorPostingGroup.Code));
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckJobPostingGroup()
    var
        GLAccount: Record "G/L Account";
        JobPostingGroup: Record "Job Posting Group";
    begin
        // [SCENARIO 263861] Job Posted Group should be shown on Where-Used page
        Initialize();

        // [GIVEN] Job Posting Group with G/L Account "G"
        LibraryERM.CreateGLAccount(GLAccount);
        JobPostingGroup.Init();
        JobPostingGroup.Code := LibraryUtility.GenerateGUID();
        JobPostingGroup."WIP Costs Account" := GLAccount."No.";
        JobPostingGroup.Insert();

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] Employee Posting Group is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          JobPostingGroup.TableCaption(),
          JobPostingGroup.FieldCaption("WIP Costs Account"),
          StrSubstNo('%1=%2', JobPostingGroup.FieldCaption(Code), JobPostingGroup.Code));
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckInvtPostingSetup()
    var
        Location: Record Location;
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        Initialize();
        // [GIVEN] Inventory Posting Setup with "Inventory Account" = "G"
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        InventoryPostingSetup.SetRange("Location Code", Location.Code);
        InventoryPostingSetup.FindFirst();

        // [WHEN] Run Where-Used function for G/L Accoun "G"
        CalcGLAccWhereUsed.CheckGLAcc(InventoryPostingSetup."Inventory Account");

        // [THEN] G/L Account "G" is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          InventoryPostingSetup.TableCaption(),
          InventoryPostingSetup.FieldCaption("Inventory Account"),
          StrSubstNo(
            '%1=%2, %3=%4',
            InventoryPostingSetup.FieldCaption("Location Code"),
            InventoryPostingSetup."Location Code",
            InventoryPostingSetup.FieldCaption("Invt. Posting Group Code"),
            InventoryPostingSetup."Invt. Posting Group Code"));
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckSalesSetupFreightGLAccNo()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        // [SCENARIO 212385] "Freight G/L Acc. No." from Sales & Receivables Setup should be shown on Where-Used page
        Initialize();

        // [GIVEN] Sales & Receivables Setup has "Freight G/L Acc. No." = "F"
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);

        SalesReceivablesSetup.Get();
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Modify(true);

        SalesReceivablesSetup.Validate("Freight G/L Acc. No.", GLAccount."No.");
        SalesReceivablesSetup.Modify(true);
        LibraryVariableStorage.Enqueue(SalesReceivablesSetup.FieldCaption("Freight G/L Acc. No."));

        // [WHEN] Run Where-Used function for Freight G/L Account "F"
        CalcGLAccWhereUsed.CheckGLAcc(SalesReceivablesSetup."Freight G/L Acc. No.");

        // [THEN] G/L Account "F" is shown on "G/L Account Where-Used List"
        // Verify in WhereUsedHandler
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckEmployeePostingGroup()
    var
        GLAccount: Record "G/L Account";
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        // [SCENARIO 259180] Employee Posted Group should be shown on Where-Used page
        Initialize();

        // [GIVEN] Employee Posting Group with G/L Account "G"
        LibraryERM.CreateGLAccount(GLAccount);
        EmployeePostingGroup.Init();
        EmployeePostingGroup.Code := LibraryUtility.GenerateGUID();
        EmployeePostingGroup."Payables Account" := GLAccount."No.";
        EmployeePostingGroup.Insert();

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] Employee Posting Group is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          EmployeePostingGroup.TableCaption(),
          EmployeePostingGroup.FieldCaption("Payables Account"),
          StrSubstNo('%1=%2', EmployeePostingGroup.FieldCaption(Code), EmployeePostingGroup.Code));
    end;

    [Test]
    [HandlerFunctions('WhereUsedTwoLinesHandler')]
    [Scope('OnPrem')]
    procedure CheckGLAccountForTwoTables()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        VendorPostingGroup: Record "Vendor Posting Group";
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 261566] Where-Used for G/L Account added to different setup tables
        Initialize();

        // [GIVEN] G/L Account "G" is assigned to Customer and Vendor Posting Group as Receivables and Payable Account
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup.Validate("Receivables Account", GLAccountNo);
        CustomerPostingGroup.Modify(true);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        VendorPostingGroup.Validate("Payables Account", GLAccountNo);
        VendorPostingGroup.Modify(true);

        LibraryVariableStorage.Enqueue(CustomerPostingGroup.FieldCaption("Receivables Account"));
        LibraryVariableStorage.Enqueue(VendorPostingGroup.FieldCaption("Payables Account"));

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccountNo);

        // [THEN] G/L Account "G" is shown in two lines as Receivables and Payable Account
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckGenJnlTemplate()
    var
        GLAccount: Record "G/L Account";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // [SCENARIO 263861] Gen. Journal Template should be shown on Where-Used page
        Initialize();

        // [GIVEN] Gen. Journal Template with Bal. Account "G"
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalTemplate.Modify();

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] Gen. Journal Template is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          GenJournalTemplate.TableCaption(),
          GenJournalTemplate.FieldCaption("Bal. Account No."),
          StrSubstNo('%1=%2', GenJournalTemplate.FieldCaption(Name), GenJournalTemplate.Name));
    end;

    [Test]
    [HandlerFunctions('WhereUsedCheckNoRecordsHandler')]
    [Scope('OnPrem')]
    procedure CheckGenJnlTemplateWithBalAccTypeBank()
    var
        GLAccount: Record "G/L Account";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // [SCENARIO 263861] Gen. Journal Template with Bal. Account Type <> G/L Acount, but Bal. Account No. = G/L Account No. should not be shown on Where-Used page
        Initialize();

        // [GIVEN] Gen. Journal Template with Bal. Account "G", but Bal. Account Type = "Bank Account"
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate("Bal. Account Type", GenJournalTemplate."Bal. Account Type"::"Bank Account");
        GenJournalTemplate."Bal. Account No." := GLAccount."No.";
        GenJournalTemplate.Modify();

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] Gen. Journal Template is not shown on "G/L Account Where-Used List"
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'There must not be records.');
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckGenJnlBatch()
    var
        GLAccount: Record "G/L Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [SCENARIO 263861] Gen. Journal Batch should be shown on Where-Used page
        Initialize();

        // [GIVEN] Gen. Journal Batch with Bal. Account "G"
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalBatch.Modify();

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] Gen. Journal Batch is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          GenJournalBatch.TableCaption(),
          GenJournalBatch.FieldCaption("Bal. Account No."),
          StrSubstNo(
            '%1=%2, %3=%4',
            GenJournalBatch.FieldCaption("Journal Template Name"),
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.FieldCaption(Name),
            GenJournalBatch.Name));
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckGenJnlAllocation()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [SCENARIO 263861] Gen. Jnl. Allocation should be shown on Where-Used page
        Initialize();

        // [GIVEN] Gen. Jnl. Allocation with Account No. "G"
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, "Gen. Journal document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), 100);

        LibraryERM.CreateGenJnlAllocation(
          GenJnlAllocation,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          GenJournalLine."Line No.");
        GenJnlAllocation.Validate("Account No.", GLAccount."No.");
        GenJnlAllocation.Modify();

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] Gen. Jnl. Allocation is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          GenJnlAllocation.TableCaption(),
          GenJnlAllocation.FieldCaption("Account No."),
          StrSubstNo(
            '%1=%2, %3=%4, %5=%6, %7=%8',
            GenJnlAllocation.FieldCaption("Journal Template Name"),
            GenJnlAllocation."Journal Template Name",
            GenJnlAllocation.FieldCaption("Journal Batch Name"),
            GenJnlAllocation."Journal Batch Name",
            GenJnlAllocation.FieldCaption("Journal Line No."),
            GenJnlAllocation."Journal Line No.",
            GenJnlAllocation.FieldCaption("Line No."),
            GenJnlAllocation."Line No."));
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckGLPostingSetup()
    var
        GLAccount: Record "G/L Account";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [SCENARIO 263861] General Posting Setup should be shown on Where-Used page
        Initialize();

        // [GIVEN] General Posting Setup with Bal. Account "G"
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
        GeneralPostingSetup.Validate("Sales Account", GLAccount."No.");
        GeneralPostingSetup.Modify();

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] General Posting Setup is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          GeneralPostingSetup.TableCaption(),
          GeneralPostingSetup.FieldCaption("Sales Account"),
          StrSubstNo(
            '%1=%2, %3=%4',
            GeneralPostingSetup.FieldCaption("Gen. Bus. Posting Group"),
            GeneralPostingSetup."Gen. Bus. Posting Group",
            GeneralPostingSetup.FieldCaption("Gen. Prod. Posting Group"),
            GeneralPostingSetup."Gen. Prod. Posting Group"));
    end;

    [Test]
    [HandlerFunctions('MultilineGLAccountWhereUsedListModalPageHandler')]
    [Scope('OnPrem')]
    procedure CheckBankAccountPostingGroup()
    var
        GLAccount: Record "G/L Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        // [SCENARIO 263861] Bank Account Posted Group should be shown on Where-Used page
        Initialize();

        // [GIVEN] Bank Account Posting Group with G/L Account "G"
        LibraryERM.CreateGLAccount(GLAccount);
        BankAccountPostingGroup.Init();
        BankAccountPostingGroup.Code := LibraryUtility.GenerateGUID();
        BankAccountPostingGroup."G/L Account No." := GLAccount."No.";
        BankAccountPostingGroup.Insert();

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] Bank Account Posting Group is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          BankAccountPostingGroup.TableCaption(),
          BankAccountPostingGroup.FieldCaption("G/L Account No."),
          StrSubstNo('%1=%2', BankAccountPostingGroup.FieldCaption(Code), BankAccountPostingGroup.Code));
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckVATPostingSetup()
    var
        GLAccount: Record "G/L Account";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 263861] VAT Posting Setup should be shown on Where-Used page
        Initialize();

        // [GIVEN] VAT Posting Setup with Bal. Account "G"
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
        VATPostingSetup.Modify();

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] VAT Posting Setup is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          VATPostingSetup.TableCaption(),
          VATPostingSetup.FieldCaption("Sales VAT Account"),
          StrSubstNo(
            '%1=%2, %3=%4',
            VATPostingSetup.FieldCaption("VAT Bus. Posting Group"),
            VATPostingSetup."VAT Bus. Posting Group",
            VATPostingSetup.FieldCaption("VAT Prod. Posting Group"),
            VATPostingSetup."VAT Prod. Posting Group"));
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckFAPostingGroup()
    var
        GLAccount: Record "G/L Account";
        FAPostingGroup: Record "FA Posting Group";
    begin
        // [SCENARIO 263861] FA Posted Group should be shown on Where-Used page
        Initialize();

        // [GIVEN] FA Posting Group with G/L Account "G"
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        FAPostingGroup.Validate("Acquisition Cost Account", GLAccount."No.");
        FAPostingGroup.Modify();

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] FA Posting Group is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          FAPostingGroup.TableCaption(),
          FAPostingGroup.FieldCaption("Acquisition Cost Account"),
          StrSubstNo('%1=%2', FAPostingGroup.FieldCaption(Code), FAPostingGroup.Code));
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckFAAllocation()
    var
        GLAccount: Record "G/L Account";
        FAAllocation: Record "FA Allocation";
        FAPostingGroup: Record "FA Posting Group";
    begin
        // [SCENARIO 263861] FA Allocation should be shown on Where-Used page
        Initialize();

        // [GIVEN] FA Allocation with Account No. "G"
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAAllocation(FAAllocation, FAPostingGroup.Code, FAAllocation."Allocation Type"::Acquisition);
        FAAllocation.Validate("Account No.", GLAccount."No.");
        FAAllocation.Modify();

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] FA Allocation is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          FAAllocation.TableCaption(),
          FAAllocation.FieldCaption("Account No."),
          StrSubstNo(
            '%1=%2, %3=%4, %5=%6',
            FAAllocation.FieldCaption(Code),
            FAAllocation.Code,
            FAAllocation.FieldCaption("Allocation Type"),
            FAAllocation."Allocation Type",
            FAAllocation.FieldCaption("Line No."),
            FAAllocation."Line No."));
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckInventoryPostingSetup()
    var
        GLAccount: Record "G/L Account";
        Location: Record Location;
        InventoryPostingGroup: Record "Inventory Posting Group";
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        // [SCENARIO 263861] Inventory Posting Setup should be shown on Where-Used page
        Initialize();

        // [GIVEN] Inventory Posting Setup with Bal. Account "G"
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, Location.Code, InventoryPostingGroup.Code);
        InventoryPostingSetup.Validate("Inventory Account", GLAccount."No.");
        InventoryPostingSetup.Modify();

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] Inventory Posting Setup is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          InventoryPostingSetup.TableCaption(),
          InventoryPostingSetup.FieldCaption("Inventory Account"),
          StrSubstNo(
            '%1=%2, %3=%4',
            InventoryPostingSetup.FieldCaption("Location Code"),
            InventoryPostingSetup."Location Code",
            InventoryPostingSetup.FieldCaption("Invt. Posting Group Code"),
            InventoryPostingSetup."Invt. Posting Group Code"));
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckServiceContractAccountGroup()
    var
        GLAccount: Record "G/L Account";
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        // [SCENARIO 263861] Service Contract Account Group should be shown on Where-Used page
        Initialize();

        // [GIVEN] Service Contract Account Group with G/L Account "G"
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);
        ServiceContractAccountGroup.Validate("Non-Prepaid Contract Acc.", GLAccount."No.");
        ServiceContractAccountGroup.Modify();

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] Service Contract Account Group is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          ServiceContractAccountGroup.TableCaption(),
          ServiceContractAccountGroup.FieldCaption("Non-Prepaid Contract Acc."),
          StrSubstNo('%1=%2', ServiceContractAccountGroup.FieldCaption(Code), ServiceContractAccountGroup.Code));
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckICPartner()
    var
        GLAccount: Record "G/L Account";
        ICPartner: Record "IC Partner";
    begin
        // [SCENARIO 263861] IC Partner should be shown on Where-Used page
        Initialize();

        // [GIVEN] IC Partner with G/L Account "G"
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateICPartner(ICPartner);
        ICPartner.Validate("Receivables Account", GLAccount."No.");
        ICPartner.Modify();

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] IC Partner is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          ICPartner.TableCaption(),
          ICPartner.FieldCaption("Receivables Account"),
          StrSubstNo('%1=%2', ICPartner.FieldCaption(Code), ICPartner.Code));
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckPaymentMethod()
    var
        GLAccount: Record "G/L Account";
        PaymentMethod: Record "Payment Method";
    begin
        // [SCENARIO 263861] Payment Method should be shown on Where-Used page
        Initialize();

        // [GIVEN] Payment Method with G/L Account "G"
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bal. Account No.", GLAccount."No.");
        PaymentMethod.Modify();

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] Payment Method is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          PaymentMethod.TableCaption(),
          PaymentMethod.FieldCaption("Bal. Account No."),
          StrSubstNo('%1=%2', PaymentMethod.FieldCaption(Code), PaymentMethod.Code));
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckSalesSetup()
    var
        GLAccount: Record "G/L Account";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        // [SCENARIO 263861] Sales & Receivables Setup should be shown on Where-Used page
        Initialize();

        // [GIVEN] Sales & Receivables Setup with G/L Account "G"
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        UpdateSalesSetupFreightGLAcc(GLAccount."No.");

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] Sales & Receivables Setup is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          SalesSetup.TableCaption(),
          SalesSetup.FieldCaption("Freight G/L Acc. No."),
          StrSubstNo('%1=%2', SalesSetup.FieldCaption("Primary Key"), SalesSetup."Primary Key"));
    end;

    [Test]
    [HandlerFunctions('WhereUsedShowDetailsHandler')]
    [Scope('OnPrem')]
    procedure ShowDetailsWhereUsedSalesSetup()
    var
        GLAccount: Record "G/L Account";
        SalesReceivablesSetupPage: TestPage "Sales & Receivables Setup";
    begin
        // [SCENARIO 263861] Sales & Receivables Setup page should be open on Show Details action from Where-Used page
        Initialize();

        // [GIVEN] Sales & Receivables Setup with G/L Account "G"
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        UpdateSalesSetupFreightGLAcc(GLAccount."No.");

        // [WHEN] Run Where-Used function for G/L Account "G"
        SalesReceivablesSetupPage.Trap();
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] Sales & Receivables Setup page opened
        SalesReceivablesSetupPage."Freight G/L Acc. No.".AssertEquals(GLAccount."No.");
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckPurchSetup()
    var
        GLAccount: Record "G/L Account";
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        // [SCENARIO 263861] Purchases & Payables Setup should be shown on Where-Used page
        Initialize();

        // [GIVEN] Purchases & Payables Setup with "Debit Acc. for Non-Item Lines" = "G"
        GLAccount.Get(LibraryERM.CreateGLAccountNo());
        UpdatPurchSetupDebitAccforNonItemLines(GLAccount."No.");

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] Purchases & Payables Setup is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          PurchSetup.TableCaption(),
          PurchSetup.FieldCaption("Debit Acc. for Non-Item Lines"),
          StrSubstNo('%1=%2', PurchSetup.FieldCaption("Primary Key"), PurchSetup."Primary Key"));
    end;

    [Test]
    [HandlerFunctions('WhereUsedShowDetailsHandler')]
    [Scope('OnPrem')]
    procedure ShowDetailsWhereUsedPurchSetup()
    var
        GLAccount: Record "G/L Account";
        PurchasesPayablesSetupPage: TestPage "Purchases & Payables Setup";
    begin
        // [SCENARIO 263861] Purchases & Payables Setup page should be open on Show Details action from Where-Used page
        Initialize();

        // [GIVEN] Purchases & Payables Setup with G/L Account "G"
        GLAccount.Get(LibraryERM.CreateGLAccountNo());
        UpdatPurchSetupDebitAccforNonItemLines(GLAccount."No.");

        // [WHEN] Run Where-Used function for G/L Account "G"
        PurchasesPayablesSetupPage.Trap();
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] Purchases & Payables Setup page opened
        PurchasesPayablesSetupPage."Debit Acc. for Non-Item Lines".AssertEquals(GLAccount."No.");
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckBusinessUnit()
    var
        GLAccount: Record "G/L Account";
        BusinessUnit: Record "Business Unit";
    begin
        // [SCENARIO 263861] Business Unit should be shown on Where-Used page
        Initialize();

        // [GIVEN] Business Unit with G/L Account "G"
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateBusinessUnit(BusinessUnit);
        BusinessUnit.Validate("Exch. Rate Losses Acc.", GLAccount."No.");
        BusinessUnit.Modify();

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] Business Unit is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          BusinessUnit.TableCaption(),
          BusinessUnit.FieldCaption("Exch. Rate Losses Acc."),
          StrSubstNo('%1=%2', BusinessUnit.FieldCaption(Code), BusinessUnit.Code));
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckCashFlowSetup()
    var
        GLAccount: Record "G/L Account";
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        // [SCENARIO 263861] Cash Flow Setup should be shown on Where-Used page
        Initialize();

        // [GIVEN] Cash Flow Setup with G/L Account "G"
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        CashFlowSetup.Get();
        CashFlowSetup.Validate("Tax Bal. Account Type", CashFlowSetup."Tax Bal. Account Type"::"G/L Account");
        CashFlowSetup.Validate("Tax Bal. Account No.", GLAccount."No.");
        CashFlowSetup.Modify();

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] Cash Flow Setup is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          CashFlowSetup.TableCaption(),
          CashFlowSetup.FieldCaption("Tax Bal. Account No."),
          StrSubstNo('%1=%2', CashFlowSetup.FieldCaption("Primary Key"), CashFlowSetup."Primary Key"));
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckWhereUsedForExtension()
    var
        TableWithLinkToGLAccount: Record "Table With Link To G/L Account";
        ERMGLAccountWhereUsed: Codeunit "ERM G/L Account Where-Used";
    begin
        // [SCENARIO 263861] Where-Used function can be used by extensions
        Initialize();
        BindSubscription(ERMGLAccountWhereUsed);

        // [GIVEN] Some extension table "Table With Link to G/L Account" with link to G/L Account "G"
        TableWithLinkToGLAccount.Init();
        TableWithLinkToGLAccount.Code := LibraryUtility.GenerateGUID();
        TableWithLinkToGLAccount."Account No." := LibraryERM.CreateGLAccountNo();
        TableWithLinkToGLAccount.Insert();

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(TableWithLinkToGLAccount."Account No.");

        // [THEN] Table With Link to G/L Account is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          TableWithLinkToGLAccount.TableCaption(),
          TableWithLinkToGLAccount.FieldCaption("Account No."),
          StrSubstNo('%1=%2', TableWithLinkToGLAccount.FieldCaption(Code), TableWithLinkToGLAccount.Code));
    end;

    [Test]
    [HandlerFunctions('WhereUsedShowDetailsHandler')]
    [Scope('OnPrem')]
    procedure ShowDetailsWhereUsedForExtension()
    var
        TableWithLinkToGLAccount: Record "Table With Link To G/L Account";
        ERMGLAccountWhereUsed: Codeunit "ERM G/L Account Where-Used";
        TableWithLinkToGLAccountPage: TestPage "Table With Link To G/L Account";
    begin
        // [SCENARIO 263861] Show Details action from Where-Used page can be used by extension
        Initialize();
        BindSubscription(ERMGLAccountWhereUsed);

        // [GIVEN] Some extension table "Table With Link to G/L Account" with link to G/L Account "G"
        TableWithLinkToGLAccount.Init();
        TableWithLinkToGLAccount.Code := LibraryUtility.GenerateGUID();
        TableWithLinkToGLAccount."Account No." := LibraryERM.CreateGLAccountNo();
        TableWithLinkToGLAccount.Insert();

        // [WHEN] Run Where-Used function for G/L Account "G"
        TableWithLinkToGLAccountPage.Trap();
        CalcGLAccWhereUsed.CheckGLAcc(TableWithLinkToGLAccount."Account No.");

        // [THEN] "Table With Link to G/L Account" page opened
        TableWithLinkToGLAccountPage."Account No.".AssertEquals(TableWithLinkToGLAccount."Account No.");
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Cash Flow Setup");
        isInitialized := true;
    end;

    local procedure UpdateSalesSetupFreightGLAcc(AccountNo: Code[20])
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.Validate("Freight G/L Acc. No.", AccountNo);
        SalesSetup.Modify();
    end;

    local procedure UpdatPurchSetupDebitAccforNonItemLines(AccountNo: Code[20])
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        PurchSetup.Validate("Debit Acc. for Non-Item Lines", AccountNo);
        PurchSetup.Modify();
    end;

    local procedure ValidateWhereUsedRecord(ExpectedTableCaption: Text; ExpectedFieldCaption: Text; ExpectedLineValue: Text)
    begin
        Assert.AreEqual(ExpectedTableCaption, LibraryVariableStorage.DequeueText(), InvalidTableCaptionErr);
        Assert.AreEqual(ExpectedFieldCaption, LibraryVariableStorage.DequeueText(), InvalidFieldCaptionErr);
        Assert.AreEqual(ExpectedLineValue, LibraryVariableStorage.DequeueText(), InvalidLineValueErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhereUsedHandler(var GLAccountWhereUsedList: TestPage "G/L Account Where-Used List")
    begin
        GLAccountWhereUsedList.First();
        LibraryVariableStorage.Enqueue(GLAccountWhereUsedList."Table Name".Value);
        LibraryVariableStorage.Enqueue(GLAccountWhereUsedList."Field Name".Value);
        LibraryVariableStorage.Enqueue(GLAccountWhereUsedList.Line.Value);
        GLAccountWhereUsedList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MultilineGLAccountWhereUsedListModalPageHandler(var GLAccountWhereUsedList: TestPage "G/L Account Where-Used List")
    begin
        GLAccountWhereUsedList.First();
        repeat
            LibraryVariableStorage.Enqueue(GLAccountWhereUsedList."Table Name".Value);
            LibraryVariableStorage.Enqueue(GLAccountWhereUsedList."Field Name".Value);
            LibraryVariableStorage.Enqueue(GLAccountWhereUsedList.Line.Value);
        until (not GLAccountWhereUsedList.Next());

        GLAccountWhereUsedList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhereUsedCheckNoRecordsHandler(var GLAccountWhereUsedList: TestPage "G/L Account Where-Used List")
    begin
        LibraryVariableStorage.Enqueue(GLAccountWhereUsedList.First());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhereUsedTwoLinesHandler(var GLAccountWhereUsedList: TestPage "G/L Account Where-Used List")
    begin
        GLAccountWhereUsedList.First();
        GLAccountWhereUsedList."Field Name".AssertEquals(LibraryVariableStorage.DequeueText());
        GLAccountWhereUsedList.Next();
        GLAccountWhereUsedList."Field Name".AssertEquals(LibraryVariableStorage.DequeueText());
        GLAccountWhereUsedList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhereUsedShowDetailsHandler(var GLAccountWhereUsedList: TestPage "G/L Account Where-Used List")
    begin
        GLAccountWhereUsedList.First();
        GLAccountWhereUsedList.ShowDetails.Invoke();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. G/L Acc. Where-Used", 'OnAfterFillTableBuffer', '', false, false)]
    local procedure OnAfterFillTableBuffer(var TableBuffer: Record "Integer")
    begin
        TableBuffer.Number := DATABASE::"Table With Link To G/L Account";
        TableBuffer.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. G/L Acc. Where-Used", 'OnShowExtensionPage', '', false, false)]
    local procedure OnShowExtensionPage(GLAccountWhereUsed: Record "G/L Account Where-Used")
    var
        TableWithLinkToGLAccount: Record "Table With Link To G/L Account";
    begin
        case GLAccountWhereUsed."Table ID" of
            DATABASE::"Table With Link To G/L Account":
                begin
                    TableWithLinkToGLAccount.Code := CopyStr(GLAccountWhereUsed."Key 1", 1, MaxStrLen(TableWithLinkToGLAccount.Code));
                    PAGE.Run(0, TableWithLinkToGLAccount);
                end;
        end;
    end;
}

