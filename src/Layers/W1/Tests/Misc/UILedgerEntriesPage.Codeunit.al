codeunit 134343 "UI Ledger Entries Page"
{
    Permissions = TableData "G/L Entry" = i,
                  TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = i,
                  TableData "Change Log Entry" = i,
                  TableData "Issued Reminder Header" = i,
                  TableData "Issued Fin. Charge Memo Header" = i;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [UI]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";

        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        ExportedToPaymentFileEditableErr: Label 'Exported to Payment File field must be editable.';
        DescriptionEditableErr: Label 'Description field must be editable.';
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        ExportToPaymentFileConfirmTxt: Label 'Editing the Exported to Payment File field will change the payment suggestions in the Payment Journal. Edit this field only if you must correct a mistake.\Do you want to continue?';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeExportedToPaymentLineOnCustLedgEntriesPage()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        EntryNo: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 273543] Stan can change value of "Exported to Payment File" on Customer Ledger Entries page

        // [GIVEN] Customer Ledger Entry
        EntryNo := MockCustLedgEntry();

        // [GIVEN] Opened Customer Ledger Entries page
        CustomerLedgerEntries.OpenEdit();
        CustomerLedgerEntries.FILTER.SetFilter("Entry No.", Format(EntryNo));
        Assert.IsTrue(CustomerLedgerEntries."Exported to Payment File".Editable(), ExportedToPaymentFileEditableErr);

        // [WHEN] Mark "Exported to Payment File" on Customer Ledger Entries page
        LibraryVariableStorage.Enqueue(true);
        CustomerLedgerEntries."Exported to Payment File".SetValue(true);
        CustomerLedgerEntries.Close();

        // [THEN] "Exported to Payment File" is true in Customer Ledger Entry
        Assert.AreEqual(ExportToPaymentFileConfirmTxt, LibraryVariableStorage.DequeueText(), '');
        CustLedgerEntry.Get(EntryNo);
        CustLedgerEntry.TestField("Exported to Payment File");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeExportedToPaymentLineOnVendLedgEntriesPage()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        EntryNo: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 273543] Stan can change value of "Exported to Payment File" on Vendor Ledger Entries page

        // [GIVEN] Vendor Ledger Entry
        EntryNo := MockVendLedgEntry();

        // [GIVEN] Opened Vendor Ledger Entries page
        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.FILTER.SetFilter("Entry No.", Format(EntryNo));
        Assert.IsTrue(VendorLedgerEntries."Exported to Payment File".Editable(), ExportedToPaymentFileEditableErr);

        // [WHEN] Mark "Exported to Payment File" on Vendor Ledger Entries page
        LibraryVariableStorage.Enqueue(true);
        VendorLedgerEntries."Exported to Payment File".SetValue(true);
        VendorLedgerEntries.Close();

        // [THEN] "Exported to Payment File" is true in Vendor Ledger Entry
        Assert.AreEqual(ExportToPaymentFileConfirmTxt, LibraryVariableStorage.DequeueText(), '');
        VendorLedgerEntry.Get(EntryNo);
        VendorLedgerEntry.TestField("Exported to Payment File");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditGLEntryDescription()
    var
        GLEntry: Record "G/L Entry";
        ChangeLogEntry: Record "Change Log Entry";
        GeneralLedgerEntries: TestPage "General Ledger Entries";
        EntryNo: Integer;
        OldDesctiption: Text;
        NewDesctiption: Text;
    begin
        // [FEATURE] [General Ledger]
        // [SCENARIO 286946] Stan is able to change description of G/L entry

        // [GIVEN] General Ledger Entry with Descirption = "Old Description"
        OldDesctiption := LibraryUtility.GenerateRandomText(MaxStrLen(GLEntry.Description));
        EntryNo := MockGLEntryWithDescription(OldDesctiption);

        // [GIVEN] Opened General Ledger Entries page
        GeneralLedgerEntries.OpenEdit();
        GeneralLedgerEntries.FILTER.SetFilter("Entry No.", Format(EntryNo));
        Assert.IsTrue(GeneralLedgerEntries.Description.Editable(), DescriptionEditableErr);

        // [WHEN] Description is being changed to "New Description"
        NewDesctiption := LibraryUtility.GenerateRandomText(MaxStrLen(GLEntry.Description));
        GeneralLedgerEntries.Description.SetValue(
          CopyStr(NewDesctiption, 1, MaxStrLen(GLEntry.Description)));
        GeneralLedgerEntries.Close();

        // [THEN] Desctiption is "New Description" in General Ledger Entry
        GLEntry.Get(EntryNo);
        GLEntry.TestField(Description, NewDesctiption);

        // [THEN] Change log entry created with "Protected" = "Yes"
        FindChangeLogEntry(ChangeLogEntry, EntryNo, GLEntry.FieldNo(Description));
        ChangeLogEntry.TestField(Protected, true);
        VerifyChangeLogEntry(ChangeLogEntry, OldDesctiption, NewDesctiption);
    end;

    [Test]
    [HandlerFunctions('ChangeLogEntriesMPH')]
    [Scope('OnPrem')]
    procedure GLEntryShowChangeHistory()
    var
        GLEntry: Record "G/L Entry";
        GeneralLedgerEntries: TestPage "General Ledger Entries";
        EntryNo: Integer;
        OldDesctiption: Text;
        NewDesctiption: Text;
    begin
        // [FEATURE] [General Ledger]
        // [SCENARIO 306088] User can open the history of G/L Entry Descripton update
        Initialize();

        // [GIVEN] General Ledger Entry "123" with Descirption = "Old Description"
        OldDesctiption := LibraryUtility.GenerateRandomText(MaxStrLen(GLEntry.Description));
        EntryNo := MockGLEntryWithDescription(OldDesctiption);

        // [GIVEN] Opened General Ledger Entries page
        GeneralLedgerEntries.OpenEdit();
        GeneralLedgerEntries.FILTER.SetFilter("Entry No.", Format(EntryNo));

        // [GIVEN] Description is being changed to "New Description"
        NewDesctiption := LibraryUtility.GenerateRandomText(MaxStrLen(GLEntry.Description));
        GeneralLedgerEntries.Description.SetValue(
          CopyStr(NewDesctiption, 1, MaxStrLen(GLEntry.Description)));
        GeneralLedgerEntries.OK().Invoke();

        // [WHEN] Action "Show change history" is being selected
        GeneralLedgerEntries.OpenEdit();
        GeneralLedgerEntries.FILTER.SetFilter("Entry No.", Format(EntryNo));
        GeneralLedgerEntries.ShowChangeHistory.Invoke();

        // [THEN] Change log entries page opened filtered by "Table No." = "17" and "Entry No." = "123"
        Assert.AreEqual(Format(DATABASE::"G/L Entry"), LibraryVariableStorage.DequeueText(), 'Invalid filter by Table No.');
        Assert.AreEqual(Format(EntryNo), LibraryVariableStorage.DequeueText(), 'Invalid filter by Entry No.');

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectShowDocumentForFinanceChargeMemoInCustomerLE()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        IssuedFinanceChargeMemo: TestPage "Issued Finance Charge Memo";
    begin
        // [FEATURE] [Finance Charge Memo]
        // [SCENARIO 337539] Run "Show Document" from Customer Ledger Entries page for Finance Charge Memo

        // [GIVEN] Created Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Created Issued Finance Charge Memo "IFCM"
        CreateIssuedFinChargeMemoHeader(IssuedFinChargeMemoHeader, Customer."No.");

        // [GIVEN] Issued Finance Charge Memo has related Customer Ledger Entry
        MockCustomerLedgerEntryWithDocNo(
          CustLedgerEntry, Customer."No.", CustLedgerEntry."Document Type"::"Finance Charge Memo", IssuedFinChargeMemoHeader."No.");

        // [WHEN] Run "Show Document" function
        IssuedFinanceChargeMemo.Trap();
        CustLedgerEntry.ShowDoc();

        // [THEN] Page Issued Finance Charge Memo with "IFCM" is opened
        IssuedFinanceChargeMemo."No.".AssertEquals(IssuedFinChargeMemoHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectShowDocumentForReminderInCustomerLE()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminder: TestPage "Issued Reminder";
    begin
        // [FEATURE] [Reminder]
        // [SCENARIO 337539] Run "Show Document" from Customer Ledger Entries page for Reminder

        // [GIVEN] Created Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Created Issued Reminder Header "R"
        CreateIssuedReminderHeader(IssuedReminderHeader, Customer."No.");

        // [GIVEN] Issued Reminder has related Customer Ledger Entry
        MockCustomerLedgerEntryWithDocNo(
          CustLedgerEntry, Customer."No.", CustLedgerEntry."Document Type"::Reminder, IssuedReminderHeader."No.");

        // [WHEN] Run "Show Document" function
        IssuedReminder.Trap();
        CustLedgerEntry.ShowDoc();

        // [THEN] Page Issued Reminder with "R" is opened
        IssuedReminder."No.".AssertEquals(IssuedReminderHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeRecipientBankAccountOnCustLedgEntriesPage()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        CustomerCard: TestPage "Customer Card";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 364554] Stan can change the recipient bank account value on the customer ledger entries page

        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Customer with two bank accounts: "A" and "B"
        LibrarySales.CreateCustomer(Customer);
        MockCustomerLedgerEntryWithDocNo(CustLedgerEntry, Customer."No.", "Gen. Journal Document Type"::" ", '');
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount[1], Customer."No.");
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount[2], Customer."No.");

        // [GIVEN] Customer Ledger Entry with "Recipient Bank Account No." = "A"
        CustLedgerEntry.Validate("Recipient Bank Account", CustomerBankAccount[1].Code);
        CustLedgerEntry.Modify(true);

        // [GIVEN] Opened Customer Ledger Entries page
        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", Customer."No.");
        CustomerLedgerEntries.Trap();
        CustomerCard."Ledger E&ntries".Invoke();

        // [WHEN] Set "B" to "Recepient Bank Account No." on Customer Ledger Entries page
        CustomerLedgerEntries.RecipientBankAccount.SetValue(CustomerBankAccount[2].Code);
        CustomerLedgerEntries.Close();
        CustomerCard.Close();

        // [THEN] "Recepient Bank Account No." is "B" in Customer Ledger Entry table
        CustLedgerEntry.Find();
        CustLedgerEntry.TestField("Recipient Bank Account", CustomerBankAccount[2].Code);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeRecipientBankAccountOnVendLedgEntriesPage()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorBankAccount: array[2] of Record "Vendor Bank Account";
        VendorCard: TestPage "Vendor Card";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 364554] Stan can change the recipient bank account value on the vendor ledger entries page

        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Vendor with two bank accounts: "A" and "B"
        LibraryPurchase.CreateVendor(Vendor);
        MockVendLedgEntryWithVendNo(VendorLedgerEntry, Vendor."No.");
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount[1], Vendor."No.");
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount[2], Vendor."No.");

        // [GIVEN] Vendor Ledger Entry with "Recipient Bank Account No." = "A"
        VendorLedgerEntry.Validate("Recipient Bank Account", VendorBankAccount[1].Code);
        VendorLedgerEntry.Modify(true);

        // [GIVEN] Opened Vendor Ledger Entries page
        VendorCard.OpenEdit();
        VendorCard.FILTER.SetFilter("No.", Vendor."No.");
        VendorLedgerEntries.Trap();
        VendorCard."Ledger E&ntries".Invoke();

        // [WHEN] Set "B" to "Recepient Bank Account No." on Vendor Ledger Entries page
        VendorLedgerEntries.RecipientBankAcc.SetValue(VendorBankAccount[2].Code);
        VendorLedgerEntries.Close();
        VendorCard.Close();

        // [THEN] "Recepient Bank Account No." is "B" in Vendor Ledger Entry table
        VendorLedgerEntry.Find();
        VendorLedgerEntry.TestField("Recipient Bank Account", VendorBankAccount[2].Code);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VendorLedgerEntriesControlExportedToPaymentFileDenyConfirm()
    var
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        VendorLedgerEntryEntryNo: Integer;
    begin
        // [FEATURE] [Purchase] [Vendor Ledger Entry] [UT]
        // [SCENARIO 366886] Control "Exported to Payment File" is not updated when reply to confirm is false.
        Initialize();

        VendorLedgerEntryEntryNo := MockVendLedgEntry();
        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.FILTER.SetFilter("Entry No.", Format(VendorLedgerEntryEntryNo));

        LibraryVariableStorage.Enqueue(false);
        VendorLedgerEntries."Exported to Payment File".SetValue(true);

        Assert.AreEqual(ExportToPaymentFileConfirmTxt, LibraryVariableStorage.DequeueText(), '');
        VendorLedgerEntries."Exported to Payment File".AssertEquals(false);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntriesControlExportedToPaymentFileDenyConfirm()
    var
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        CustomerLedgerEntryEntryNo: Integer;
    begin
        // [FEATURE] [Purchase] [Customer Ledger Entry] [UT]
        // [SCENARIO 366886] Control "Exported to Payment File" is not updated when reply to confirm is false.
        Initialize();

        CustomerLedgerEntryEntryNo := MockCustLedgEntry();
        CustomerLedgerEntries.OpenEdit();
        CustomerLedgerEntries.FILTER.SetFilter("Entry No.", Format(CustomerLedgerEntryEntryNo));

        LibraryVariableStorage.Enqueue(false);
        CustomerLedgerEntries."Exported to Payment File".SetValue(true);

        Assert.AreEqual(ExportToPaymentFileConfirmTxt, LibraryVariableStorage.DequeueText(), '');
        CustomerLedgerEntries."Exported to Payment File".AssertEquals(false);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure FindChangeLogEntry(var ChangeLogEntry: Record "Change Log Entry"; EntryNo: Integer; FieldNo: Integer)
    begin
        ChangeLogEntry.SetRange("Table No.", DATABASE::"G/L Entry");
        ChangeLogEntry.SetRange("Primary Key Field 1 Value", Format(EntryNo, 0, 9));
        ChangeLogEntry.SetRange("Field No.", FieldNo);
        ChangeLogEntry.FindFirst();
    end;

    local procedure MockCustLedgEntry(): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry.Insert();
        exit(CustLedgerEntry."Entry No.");
    end;

    local procedure MockVendLedgEntry(): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry.Insert();
        exit(VendorLedgerEntry."Entry No.");
    end;

    local procedure MockVendLedgEntryWithVendNo(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendNo: Code[20])
    begin
        VendorLedgerEntry.Get(MockVendLedgEntry());
        VendorLedgerEntry.Validate("Vendor No.", VendNo);
        VendorLedgerEntry.Validate(Open, true);
        VendorLedgerEntry.Modify(true);
    end;

    local procedure MockGLEntryWithDescription(Descirption: Text): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FieldNo("Entry No."));
        GLEntry.Description := CopyStr(Descirption, 1, MaxStrLen(GLEntry.Description));
        GLEntry.Insert();
        exit(GLEntry."Entry No.");
    end;

    local procedure VerifyChangeLogEntry(ChangeLogEntry: Record "Change Log Entry"; OldDescription: Text; NewDescription: Text)
    begin
        ChangeLogEntry.TestField("Type of Change", ChangeLogEntry."Type of Change"::Modification);
        ChangeLogEntry.TestField("Old Value", OldDescription);
        ChangeLogEntry.TestField("New Value", NewDescription);
    end;

    local procedure MockCustomerLedgerEntryWithDocNo(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        CustLedgerEntry.Get(MockCustLedgEntry());
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Document Type" := DocumentType;
        CustLedgerEntry."Document No." := DocumentNo;
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Modify();
    end;

    local procedure CreateIssuedFinChargeMemoHeader(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; CustomerNo: Code[20]): Code[20]
    begin
        IssuedFinChargeMemoHeader.Init();
        IssuedFinChargeMemoHeader."No." := LibraryUtility.GenerateRandomCode(IssuedFinChargeMemoHeader.FieldNo("No."), DATABASE::"Issued Fin. Charge Memo Header");
        IssuedFinChargeMemoHeader."Customer No." := CustomerNo;
        IssuedFinChargeMemoHeader.Insert();
        exit(IssuedFinChargeMemoHeader."No.");
    end;

    local procedure CreateIssuedReminderHeader(var IssuedReminderHeader: Record "Issued Reminder Header"; CustomerNo: Code[20]): Code[20]
    begin
        IssuedReminderHeader.Init();
        IssuedReminderHeader."No." := LibraryUtility.GenerateRandomCode(IssuedReminderHeader.FieldNo("No."), DATABASE::"Issued Reminder Header");
        IssuedReminderHeader."Customer No." := CustomerNo;
        IssuedReminderHeader.Insert();
        exit(IssuedReminderHeader."No.");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Message: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ErrorMessagesMPH(var ErrorMessages: TestPage "Error Messages")
    begin
        ErrorMessages.FILTER.SetFilter(Description, LibraryVariableStorage.DequeueText());
        Assert.IsTrue(ErrorMessages.First(), 'Error not found');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChangeLogEntriesMPH(var ChangeLogEntries: TestPage "Change Log Entries")
    begin
        LibraryVariableStorage.Enqueue(ChangeLogEntries.FILTER.GetFilter("Table No."));
        LibraryVariableStorage.Enqueue(ChangeLogEntries.FILTER.GetFilter("Primary Key Field 1 Value"));
        ChangeLogEntries.OK().Invoke();
    end;
}
