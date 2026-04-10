codeunit 132531 "VAT Assisted Setup"
{
    Permissions = TableData "VAT Entry" = rimd;
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [VAT] [VAT Assisted Setup Tests]
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        EmptyGLAccountsMsg: Label 'You have not assigned general ledger accounts for sales and purchases for all VAT amounts. You won''t be able to calculate and post VAT for the missing accounts. If you''re skipping this step on purpose, you can manually assign accounts later in the VAT Posting Setup page.';
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";

    [Test]
    [HandlerFunctions('RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure AssistedVATCanNotSetupVATPostingGrpIfVATEntryExist()
    var
        VATEntry: Record "VAT Entry";
        VATSetupWizard: TestPage "VAT Setup Wizard";
    begin
        // [SCENARIO] User can not start the VAT assisted setup if there is a vat entry.
        // [GIVEN] There is a vat entry.
        VATEntry.Insert();
        InitTemplates();

        LibraryLowerPermissions.SetO365Setup();
        // [WHEN] open the page.
        VATSetupWizard.OpenNew();
        SetGLAccounts();

        // [THEN] Manual step necessary exit the page on finish.
        Assert.IsTrue(VATSetupWizard.ActionFinish.Enabled(), 'Expected that finish action is enabled.');
        VATSetupWizard.ActionFinish.Invoke();
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure AssistedVATCanNotSetupVATPostingGrpIfCusromerExist()
    var
        Customer: Record Customer;
        VATSetupWizard: TestPage "VAT Setup Wizard";
    begin
        // [SCENARIO] User can not start the VAT assisted setup if there is a customer with vat bus. posting group.
        // [GIVEN] There is a customer.
        LibrarySales.CreateCustomer(Customer);
        InitTemplates();

        LibraryLowerPermissions.SetO365Setup();
        // [WHEN] open the page.
        VATSetupWizard.OpenNew();
        SetGLAccounts();

        // [THEN] Manual step necessary exit the page on finish.
        Assert.IsTrue(VATSetupWizard.ActionFinish.Enabled(), 'Expected that finish action is enabled.');
        VATSetupWizard.ActionFinish.Invoke();
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure AssistedVATCanNotSetupVATPostingGrpIfVendorExist()
    var
        Vendor: Record Vendor;
        VATSetupWizard: TestPage "VAT Setup Wizard";
    begin
        // [SCENARIO] User can not start the VAT assisted setup if there is a vendor with vat bus posting setup.
        // [GIVEN] There is a Vendor.
        LibraryPurchase.CreateVendor(Vendor);
        InitTemplates();

        LibraryLowerPermissions.SetO365Setup();
        // [WHEN] open the page.
        VATSetupWizard.OpenNew();
        SetGLAccounts();

        // [THEN] Manual step necessary exit the page on finish.
        Assert.IsTrue(VATSetupWizard.ActionFinish.Enabled(), 'Expected that finish action is enabled.');
        VATSetupWizard.ActionFinish.Invoke();
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure AssistedVATCanNotSetupVATPostingGrpIfItemExist()
    var
        Item: Record Item;
        VATSetupWizard: TestPage "VAT Setup Wizard";
    begin
        // [SCENARIO] User can not start the VAT assisted setup if there is a Item with vat Prod posting setup.
        // [GIVEN] There is a Item.
        LibraryInventory.CreateItem(Item);
        InitTemplates();

        LibraryLowerPermissions.SetO365Setup();
        // [WHEN] open the page.
        VATSetupWizard.OpenNew();
        SetGLAccounts();

        // [THEN] Manual step necessary exit the page on finish.
        Assert.IsTrue(VATSetupWizard.ActionFinish.Enabled(), 'Expected that finish action is enabled.');
        VATSetupWizard.ActionFinish.Invoke();
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure AssistedVATCanNotDeleteUsedProdGrp()
    var
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        Item: Record Item;
        VATProductPostingGrpPart: TestPage "VAT Product Posting Grp Part";
    begin
        // [SCENARIO] User can finish the VAT assisted setup.
        // [GIVEN] G/L Accounts are set.
        // [GIVEN] Templates default values are set.
        // [GIVEN] VAT clause is set.
        // [WHEN] Navigate to finish and press finish button.
        // [THEN] VAT posting setup contains all the possible permutaions.
        LibraryVariableStorage.Clear();
        LibraryLowerPermissions.SetO365Setup();
        VATProductPostingGrpPart.OpenEdit();

        VATSetupPostingGroups.DeleteAll();
        InsertProdData(LibraryUtility.GenerateRandomCode(VATProductPostingGroup.FieldNo(Code), DATABASE::"VAT Product Posting Group"),
          CopyStr(LibraryUtility.GenerateRandomText(50), 1, 50));
        VATProductPostingGroup.FindFirst();

        VATSetupPostingGroups.Init();
        VATSetupPostingGroups."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATSetupPostingGroups.Selected := true;
        VATSetupPostingGroups.Insert();

        LibraryInventory.CreateItemWithoutVAT(Item);
        Item.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        Item.Modify();

        VATProductPostingGrpPart.FILTER.SetFilter(Selected, Format(true));
        VATProductPostingGrpPart.First();

        LibraryVariableStorage.Enqueue(' delete or modify this VAT record because it is connected to existing item.');
        VATProductPostingGrpPart.Selected.SetValue(Format(false));
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssistedVATBusGrpCheckExistingCustomerVAT()
    var
        VATAssistedSetupBusGrp: Record "VAT Assisted Setup Bus. Grp.";
        Customer: Record Customer;
        ConfigTemplateHeader: Record "Config. Template Header";
        TempCode: Code[10];
    begin
        // [SCENARIO] Create bus VAT record and customer that uses it. Then the function should return true for VAT record is used
        // [GIVEN] VAT business record.
        LibraryLowerPermissions.SetO365Setup();
        VATAssistedSetupBusGrp.DeleteAll();
        TempCode := LibraryUtility.GenerateRandomCode(ConfigTemplateHeader.FieldNo(Code), DATABASE::"Config. Template Header");
        InsertBusPostingGrp(TempCode, CopyStr(LibraryUtility.GenerateRandomText(50), 1, 50));
        // [THEN] Check function should return false for no customer or vendor using VAT.
        Assert.IsFalse(VATAssistedSetupBusGrp.CheckExistingCustomersAndVendorsWithVAT(TempCode)
          , 'Check function should return false');

        // [WHEN] Create customer that uses VAT Bus record.
        CreateCustomer(Customer, TempCode);
        // [THEN] Check function should return true for customer using VAT.
        Assert.IsTrue(VATAssistedSetupBusGrp.CheckExistingCustomersAndVendorsWithVAT(TempCode)
          , 'Check function should return true');
        // Tear Down
        Customer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssistedVATBusGrpCheckExistingVendorVAT()
    var
        VATAssistedSetupBusGrp: Record "VAT Assisted Setup Bus. Grp.";
        Vendor: Record Vendor;
        ConfigTemplateHeader: Record "Config. Template Header";
        TempCode: Code[10];
    begin
        // [SCENARIO] Create bus VAT record and vendor that uses it. Then the function should return true for VAT record is used
        // [GIVEN] VAT business record.
        LibraryLowerPermissions.SetO365Setup();
        VATAssistedSetupBusGrp.DeleteAll();
        TempCode := LibraryUtility.GenerateRandomCode(ConfigTemplateHeader.FieldNo(Code), DATABASE::"Config. Template Header");
        InsertBusPostingGrp(TempCode, CopyStr(LibraryUtility.GenerateRandomText(50), 1, 50));

        VATAssistedSetupBusGrp.FindFirst();
        // [THEN] Check function should return false for no vendor using VAT.
        Assert.IsFalse(VATAssistedSetupBusGrp.CheckExistingCustomersAndVendorsWithVAT(TempCode)
          , 'Check function should return false');

        // [WHEN] Create vendor that uses VAT Bus record.
        CreateVendor(Vendor, TempCode);
        // [THEN] Check function should return true for vendor using VAT.
        Assert.IsTrue(VATAssistedSetupBusGrp.CheckExistingCustomersAndVendorsWithVAT(TempCode)
          , 'Check function should return true');
        // Tear Down
        Vendor.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssistedVATProductCheckExistingItems()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Item: Record Item;
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
        TempCode: Code[10];
    begin
        // [SCENARIO] Create product VAT record and item that uses it. Then the function should return true for VAT record is used
        // [GIVEN] VAT product record.
        LibraryLowerPermissions.SetO365Setup();
        VATSetupPostingGroups.DeleteAll();
        TempCode := LibraryUtility.GenerateRandomCode(ConfigTemplateHeader.FieldNo(Code), DATABASE::"Config. Template Header");
        InsertProdData(TempCode, CopyStr(LibraryUtility.GenerateRandomText(50), 1, 50));
        // [THEN] Check function should return false for no customer or vendor using VAT.
        Assert.IsFalse(VATSetupPostingGroups.CheckExistingItemAndServiceWithVAT(TempCode, false)
          , 'Check function should return false');

        // [WHEN] Create item that uses VAT product record.
        CreateItem(Item, TempCode);
        // [THEN] Check function should return true for customer using VAT.
        Assert.IsTrue(VATSetupPostingGroups.CheckExistingItemAndServiceWithVAT(TempCode, false)
          , 'Check function should return true');
        // Tear Down
        Item.Delete();
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure AssistedVATCanSetupVATPostingGrp()
    var
        VATEntry: Record "VAT Entry";
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
        VATAssistedSetupBusGrp: Record "VAT Assisted Setup Bus. Grp.";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Item: Record Item;
        VATSetupWizard: TestPage "VAT Setup Wizard";
    begin
        // [SCENARIO] User can finish the VAT assisted setup.
        // [GIVEN]
        InitTemplates();
        VATEntry.DeleteAll();
        Customer.DeleteAll();
        Vendor.DeleteAll();
        Item.DeleteAll();
        InitGenPostingGrpsWithRndValue();
        VATSetupWizard.OpenNew();
        SetGLAccounts();
        VATAssistedSetupBusGrp.FindFirst();
        VATSetupPostingGroups.FindFirst();
        SetBusGrpTemplatesDefaultValue(DATABASE::Customer, VATAssistedSetupBusGrp.Code);
        SetBusGrpTemplatesDefaultValue(DATABASE::Vendor, VATAssistedSetupBusGrp.Code);
        SetProdGrpTemplatesDefaultValue(VATSetupPostingGroups."VAT Prod. Posting Group");
        SetVATClause();

        LibraryLowerPermissions.SetO365Setup();
        // [WHEN] Navigate to finish and press finish button.
        NavigateToFinish(VATSetupWizard);
        VATSetupWizard.ActionFinish.Invoke();

        // [THEN] VAT posting setup contains all the possible permutaions.
        AssertVATPostingGroup();
        AssertTemplates();
        AssertGenProdBusGrpAreCleared();
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure AssistedVATSetupGetNotificationAndFix()
    var
        VATEntry: Record "VAT Entry";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Item: Record Item;
        VATSetupWizard: TestPage "VAT Setup Wizard";
    begin
        // [SCENARIO] User navigate fix the issues and finish the VAT assisted setup.
        // [WHEN] Navigate Get Validation notification and fix on Next Btn.
        // [WHEN] Navigate to finish and press finish button.
        // [THEN] VAT posting setup contains all the possible permutaions.
        LibraryVariableStorage.Clear();
        VATEntry.DeleteAll();
        Customer.DeleteAll();
        Vendor.DeleteAll();
        Item.DeleteAll();
        InitTemplates();

        LibraryLowerPermissions.SetO365Setup();
        VATSetupWizard.OpenNew();
        UnSelectBusProdPostigGrp();
        UnsetGLAccounts();
        NavigateNext(VATSetupWizard, 1);

        LibraryVariableStorage.Enqueue('You must select at least one VAT business posting group.');
        NavigateNext(VATSetupWizard, 1);// Empty Bus posting Grp notification
        SelectVATBusPostingGrp();
        NavigateNext(VATSetupWizard, 1);

        LibraryVariableStorage.Enqueue('You must select at least one item or service.');
        NavigateNext(VATSetupWizard, 1);// Empty Prod posting grp notification
        SelectVATProdPostingGrp();
        VATSetupWizard.VATProdPostGrpPart.Selected.Value(Format(false));
        SelectVATProdPostingGrp();
        NavigateNext(VATSetupWizard, 1);

        LibraryVariableStorage.Enqueue(EmptyGLAccountsMsg);
        NavigateNext(VATSetupWizard, 1);// GL Accounts are not set, warning notification showed for first time
        NavigateNext(VATSetupWizard, 1);// Second time notification is hidden and user can proceed

        NavigateBack(VATSetupWizard);
        SetGLAccounts();
        NavigateNext(VATSetupWizard, 2);// VAT Clause

        SetInvalidValuseForTemplates();
        LibraryVariableStorage.Enqueue(' is not valid VAT Business group.');
        NavigateNext(VATSetupWizard, 1);// InvalidTemplate values
        SetBusGrpTemplatesDefaultValue(DATABASE::Customer, '');
        NavigateNext(VATSetupWizard, 1);

        LibraryVariableStorage.Enqueue(' is not valid VAT Business group.');
        NavigateNext(VATSetupWizard, 1);// InvalidTemplate values
        SetBusGrpTemplatesDefaultValue(DATABASE::Vendor, '');
        NavigateNext(VATSetupWizard, 1);

        LibraryVariableStorage.Enqueue(' is not valid VAT product group.');
        NavigateNext(VATSetupWizard, 1);// InvalidTemplate values
        SetProdGrpTemplatesDefaultValue('');
        NavigateNext(VATSetupWizard, 1);

        Assert.IsTrue(VATSetupWizard.ActionFinish.Enabled(), 'Expected that Finish action is enabled');
        VATSetupWizard.ActionFinish.Invoke();

        AssertVATPostingGroup();
        AssertTemplates();
        AssertVATClause();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssistedVATBusGrpValidateVATbusGrp()
    var
        VATAssistedSetupBusGrp: Record "VAT Assisted Setup Bus. Grp.";
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        // [SCENARIO] Check validation function
        // [GIVEN] One unselected VAT business record.
        LibraryLowerPermissions.SetO365Setup();
        VATAssistedSetupBusGrp.DeleteAll();
        InsertBusPostingGrp(LibraryUtility.GenerateRandomCode(ConfigTemplateHeader.FieldNo(Code), DATABASE::"Config. Template Header")
          , CopyStr(LibraryUtility.GenerateRandomText(50), 1, 50));
        // [WHEN] There is 0 selected VAT business records.
        // [THEN] Validation function should return False
        Assert.IsFalse(VATAssistedSetupBusGrp.ValidateVATBusGrp(), 'Validation should return false');

        // [WHEN] There is at least 1 selected VAT business record
        VATAssistedSetupBusGrp.Reset();
        VATAssistedSetupBusGrp.FindFirst();
        VATAssistedSetupBusGrp.Validate(Selected, true);
        VATAssistedSetupBusGrp.Modify();

        // [THEN] Validation function should return True
        Assert.IsTrue(VATAssistedSetupBusGrp.ValidateVATBusGrp(), 'Validation should return True');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssistedVATProductValidateRates()
    var
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        // [SCENARIO] Check validation function
        // [GIVEN] One unselected VAT business record.
        LibraryLowerPermissions.SetO365Setup();
        VATSetupPostingGroups.DeleteAll();
        InsertProdData(LibraryUtility.GenerateRandomCode(ConfigTemplateHeader.FieldNo(Code), DATABASE::"Config. Template Header")
          , CopyStr(LibraryUtility.GenerateRandomText(50), 1, 50));
        // [WHEN] There is 0 selected VAT business records.
        // [THEN] Validation function should return False
        Assert.IsFalse(VATSetupPostingGroups.ValidateVATRates(), 'Validation should return false');

        // [WHEN] There is at least 1 selected VAT business record
        VATSetupPostingGroups.Reset();
        VATSetupPostingGroups.FindFirst();
        VATSetupPostingGroups.Validate(Selected, true);
        VATSetupPostingGroups.Modify();

        // [THEN] Validation function should return True
        Assert.IsTrue(VATSetupPostingGroups.ValidateVATRates(), 'Validation should return True');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssistedVATwizardWithNoExistingGLAccounts()
    var
        GLAccount: Record "G/L Account";
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
    begin
        // [SCENARIO] The VAT wizard should check if hard-coded GL accounts exist before adding them
        // [GIVEN] Empty GL account table
        LibraryLowerPermissions.SetO365Setup();
        GLAccount.DeleteAll();

        // [WHEN] VAT setup posting group populate function is called
        VATSetupPostingGroups.PopulateVATProdGroups();

        // [THEN] Validation function should return False
        VATSetupPostingGroups.SetFilter("Sales VAT Account", '<>''''');
        Assert.IsTrue(VATSetupPostingGroups.IsEmpty, 'There should be no record with GL accounts');
        VATSetupPostingGroups.Reset();

        VATSetupPostingGroups.SetFilter("Purchase VAT Account", '<>''''');
        Assert.IsTrue(VATSetupPostingGroups.IsEmpty, 'There should be no record with GL accounts');
    end;

    local procedure InitTemplates()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        ConfigTemplateLine.DeleteAll();
        ConfigTemplateHeader.DeleteAll();
        InsertTemplateHeader(DATABASE::Customer);
        InsertTemplateHeader(DATABASE::Vendor);
        InsertTemplateHeader(DATABASE::Item);
    end;

    local procedure SetBusGrpTemplatesDefaultValue(TableId: Integer; BusPostingGrp: Code[20])
    var
        VATAssistedSetupTemplates: Record "VAT Assisted Setup Templates";
    begin
        VATAssistedSetupTemplates.SetRange("Table ID", TableId);
        VATAssistedSetupTemplates.ModifyAll("Default VAT Bus. Posting Grp", BusPostingGrp);
    end;

    local procedure SetProdGrpTemplatesDefaultValue(ProdPostingGrp: Code[20])
    var
        VATAssistedSetupTemplates: Record "VAT Assisted Setup Templates";
    begin
        VATAssistedSetupTemplates.SetRange("Table ID", DATABASE::Item);
        VATAssistedSetupTemplates.ModifyAll("Default VAT Prod. Posting Grp", ProdPostingGrp);
    end;

    local procedure SetInvalidValuseForTemplates()
    var
        VATAssistedSetupTemplates: Record "VAT Assisted Setup Templates";
    begin
        SetBusGrpTemplatesDefaultValue(DATABASE::Customer,
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(VATAssistedSetupTemplates."Default VAT Bus. Posting Grp"))
            , 1, MaxStrLen(VATAssistedSetupTemplates."Default VAT Bus. Posting Grp")));

        SetBusGrpTemplatesDefaultValue(DATABASE::Vendor,
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(VATAssistedSetupTemplates."Default VAT Bus. Posting Grp"))
            , 1, MaxStrLen(VATAssistedSetupTemplates."Default VAT Bus. Posting Grp")));

        SetProdGrpTemplatesDefaultValue(
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(VATAssistedSetupTemplates."Default VAT Prod. Posting Grp"))
            , 1, MaxStrLen(VATAssistedSetupTemplates."Default VAT Prod. Posting Grp")));
    end;

    local procedure UnSelectBusProdPostigGrp()
    var
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
        VATAssistedSetupBusGrp: Record "VAT Assisted Setup Bus. Grp.";
    begin
        VATSetupPostingGroups.ModifyAll(Selected, false);
        VATAssistedSetupBusGrp.ModifyAll(Selected, false);
    end;

    local procedure SelectVATBusPostingGrp()
    var
        VATAssistedSetupBusGrp: Record "VAT Assisted Setup Bus. Grp.";
    begin
        VATAssistedSetupBusGrp.FindFirst();
        VATAssistedSetupBusGrp.Validate(Selected, true);
        VATAssistedSetupBusGrp.Modify();
    end;

    local procedure SelectVATProdPostingGrp()
    var
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
    begin
        VATSetupPostingGroups.FindFirst();
        VATSetupPostingGroups.Validate(Selected, true);
        VATSetupPostingGroups.Modify();
    end;

    local procedure UnsetGLAccounts()
    var
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
    begin
        VATSetupPostingGroups.ModifyAll("Sales VAT Account", '');
        VATSetupPostingGroups.ModifyAll("Purchase VAT Account", '');
    end;

    local procedure SetGLAccounts()
    var
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
        GLAccount: Record "G/L Account";
    begin
        GLAccount.FindFirst();
        VATSetupPostingGroups.ModifyAll("Sales VAT Account", GLAccount."No.");
        VATSetupPostingGroups.ModifyAll("Purchase VAT Account", GLAccount."No.");
    end;

    [Scope('OnPrem')]
    procedure InsertBusPostingGrp(GrpCode: Code[10]; GrpDesc: Text[50])
    var
        VATAssistedSetupBusGrp: Record "VAT Assisted Setup Bus. Grp.";
    begin
        VATAssistedSetupBusGrp.Init();
        VATAssistedSetupBusGrp.Code := GrpCode;
        VATAssistedSetupBusGrp.Description := GrpDesc;
        VATAssistedSetupBusGrp.Insert();
    end;

    local procedure InsertProdData("Code": Code[10]; Description: Text[50])
    var
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
    begin
        VATSetupPostingGroups.Init();
        VATSetupPostingGroups.Validate("VAT Prod. Posting Group", Code);
        VATSetupPostingGroups.Validate("VAT Prod. Posting Grp Desc.", Description);
        VATSetupPostingGroups.Insert();
    end;

    local procedure InsertTemplateHeader(TableId: Integer)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        LibraryRapidStart: Codeunit "Library - Rapid Start";
    begin
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        ConfigTemplateHeader.Validate("Table ID", TableId);
        ConfigTemplateHeader.Modify(true);
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    var
        Expected: Text;
        Actual: Text;
    begin
        if Notification.Message <> '' then begin
            Expected := LibraryVariableStorage.DequeueText();
            Actual := Notification.Message;
            Assert.IsTrue(StrPos(Actual, Expected) > 0, 'Expected a different notification.');
        end;
        exit(true);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    var
        Expected: Text;
        Actual: Text;
    begin
        if Notification.Message <> '' then begin
            Expected := LibraryVariableStorage.DequeueText();
            Actual := Notification.Message;
            Assert.IsTrue(StrPos(Actual, Expected) > 0, 'Expected a different notification.');
        end;
        exit(true);
    end;

    local procedure SetVATClause()
    var
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
    begin
        VATSetupPostingGroups.FindFirst();
        VATSetupPostingGroups."VAT Clause Desc" := CopyStr(LibraryUtility.GenerateRandomText(50), 1, 50);
        VATSetupPostingGroups.Modify();
    end;

    local procedure NavigateNext(var VATSetupWizard: TestPage "VAT Setup Wizard"; "Count": Integer)
    var
        I: Integer;
    begin
        // Welcome
        // VAT Bus posting Grp
        // VAT prod posting Grp - VAT Rates
        // VAT prod posting Grp - VAT Accounts
        // VAT prod posting Grp - VAT Clauses
        // Customer Template
        // Vendor Template
        // Item Template
        // Finish
        for I := 1 to Count do begin
            Assert.IsTrue(VATSetupWizard.ActionNext.Enabled(), 'Expected that actionNext is enabled');
            VATSetupWizard.ActionNext.Invoke();
        end;
    end;

    local procedure NavigateBack(var VATSetupWizard: TestPage "VAT Setup Wizard")
    begin
        VATSetupWizard.ActionBack.Invoke();
    end;

    local procedure NavigateToFinish(var VATSetupWizard: TestPage "VAT Setup Wizard")
    begin
        NavigateNext(VATSetupWizard, 8);
        Assert.IsTrue(VATSetupWizard.ActionFinish.Enabled(), 'Expected that finish action is enabled.');
    end;

    local procedure CreateCustomer(var Customer: Record Customer; "Code": Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."VAT Bus. Posting Group" := Code;
        Customer.Modify();
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; "Code": Code[10])
    var
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."VAT Bus. Posting Group" := Code;
        Vendor.Modify();
    end;

    local procedure CreateItem(var Item: Record Item; "Code": Code[10])
    var
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Item."VAT Prod. Posting Group" := Code;
        Item.Modify();
    end;

    local procedure InitGenPostingGrpsWithRndValue()
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        GenBusinessPostingGroup.ModifyAll("Def. VAT Bus. Posting Group",
          LibraryUtility.GenerateRandomCode(GenBusinessPostingGroup.FieldNo("Def. VAT Bus. Posting Group"),
            DATABASE::"Gen. Business Posting Group"));
        GenProductPostingGroup.ModifyAll("Def. VAT Prod. Posting Group",
          LibraryUtility.GenerateRandomCode(GenProductPostingGroup.FieldNo("Def. VAT Prod. Posting Group"),
            DATABASE::"Gen. Product Posting Group"));
    end;

    local procedure AssertVATPostingGroup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
        VATAssistedSetupBusGrp: Record "VAT Assisted Setup Bus. Grp.";
        CountBusPostingGrp: Integer;
        CountProdPostingGrp: Integer;
    begin
        VATAssistedSetupBusGrp.SetRange(Selected, true);
        VATAssistedSetupBusGrp.SetRange(Default, false);
        CountBusPostingGrp := VATAssistedSetupBusGrp.Count + 1;// we always create an empty Bus Grp

        VATSetupPostingGroups.SetRange(Selected, true);
        VATSetupPostingGroups.SetRange(Default, false);
        CountProdPostingGrp := VATSetupPostingGroups.Count();

        Assert.AreEqual(CountProdPostingGrp * CountBusPostingGrp, VATPostingSetup.Count,
          'Expected that we have all the possible combinations');
    end;

    local procedure AssertTemplates()
    var
        VATAssistedSetupTemplates: Record "VAT Assisted Setup Templates";
    begin
        if not VATAssistedSetupTemplates.FindSet() then
            exit;
        repeat
            AssertBusGrpTemplateLine(VATAssistedSetupTemplates);
            AssertProdGrpTemplateLine(VATAssistedSetupTemplates);
        until VATAssistedSetupTemplates.Next() = 0;
    end;

    local procedure AssertBusGrpTemplateLine(VATAssistedSetupTemplates: Record "VAT Assisted Setup Templates")
    var
        ConfigTemplateLine: Record "Config. Template Line";
        DummyCustomer: Record Customer;
    begin
        Assert.AreEqual(VATAssistedSetupTemplates."Default VAT Bus. Posting Grp" <> '',
          ConfigTemplateLine.GetLine(ConfigTemplateLine, VATAssistedSetupTemplates.Code, DummyCustomer.FieldNo("VAT Bus. Posting Group")),
          'Expected that there is a line if Bus grp is not empty.');
        Assert.AreEqual(VATAssistedSetupTemplates."Default VAT Bus. Posting Grp", ConfigTemplateLine."Default Value",
          'Expected that Bus grp and default value are equal');
    end;

    local procedure AssertProdGrpTemplateLine(VATAssistedSetupTemplates: Record "VAT Assisted Setup Templates")
    var
        ConfigTemplateLine: Record "Config. Template Line";
        DummyItem: Record Item;
    begin
        Assert.AreEqual(VATAssistedSetupTemplates."Default VAT Prod. Posting Grp" <> '',
          ConfigTemplateLine.GetLine(ConfigTemplateLine, VATAssistedSetupTemplates.Code, DummyItem.FieldNo("VAT Prod. Posting Group")),
          'Expected that there is a line if Prod grp is not empty.');
        Assert.AreEqual(VATAssistedSetupTemplates."Default VAT Prod. Posting Grp", ConfigTemplateLine."Default Value",
          'Expected that Bus grp and default value are equal');
    end;

    local procedure AssertVATClause()
    var
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
        VATClause: Record "VAT Clause";
    begin
        VATSetupPostingGroups.FindSet();
        repeat
            if VATSetupPostingGroups."VAT Clause Desc" <> '' then begin
                VATClause.Init();
                VATClause.Reset();
                VATClause.SetFilter(Description, VATSetupPostingGroups."VAT Clause Desc");
                Assert.IsTrue(VATClause.FindFirst(), 'Expected that there is vat clause')
            end;
        until VATSetupPostingGroups.Next() = 0;
    end;

    local procedure AssertGenProdBusGrpAreCleared()
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
    begin
        GenBusinessPostingGroup.SetFilter("Def. VAT Bus. Posting Group", '<>%1', '');
        Assert.RecordIsEmpty(GenBusinessPostingGroup);

        GenProductPostingGroup.SetFilter("Def. VAT Prod. Posting Group", '<>%1', '');
        Assert.RecordIsEmpty(GenProductPostingGroup);
    end;
}

