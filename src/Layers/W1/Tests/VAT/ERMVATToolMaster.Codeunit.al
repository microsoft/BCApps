codeunit 134050 "ERM VAT Tool - Master"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Rate Change]
        isInitialized := false;
    end;

    var
        VATRateChangeSetup2: Record "VAT Rate Change Setup";
        Assert: Codeunit Assert;
        ERMVATToolHelper: Codeunit "ERM VAT Tool - Helper";
        LibraryJob: Codeunit "Library - Job";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        isInitialized: Boolean;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        ERMVATToolHelper.ResetToolSetup();  // This resets the setup table for all test cases.

        if isInitialized then
            exit;

        LibraryFiscalYear.UpdateAllowGAccDeletionBeforeDateOnGLSetup(LibraryFiscalYear.GetPastNewYearDate(5));
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERM.SetBlockDeleteGLAccount(false);
        ERMVATToolHelper.SetupItemNos();
        ERMVATToolHelper.ResetToolSetup();  // This resets setup table for the first test case after database is restored.

        isInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolGLAccountVAT()
    begin
        VATToolGLAccount(VATRateChangeSetup2."Update G/L Accounts"::"VAT Prod. Posting Group", false, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolGLAccountGen()
    begin
        VATToolGLAccount(VATRateChangeSetup2."Update G/L Accounts"::"Gen. Prod. Posting Group", false, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolGLAccountBoth()
    begin
        VATToolGLAccount(VATRateChangeSetup2."Update G/L Accounts"::Both, false, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolGLAccountNo()
    begin
        asserterror VATToolGLAccount(VATRateChangeSetup2."Update G/L Accounts"::No, false, 1);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolGLAccountBothFilter()
    begin
        VATToolGLAccount(VATRateChangeSetup2."Update G/L Accounts"::Both, true, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolGLAccountRunTwice()
    var
        GLAccount: Record "G/L Account";
        OldWorkDate: Date;
    begin
        // Run VAT Rate Change with Perform Conversion = FALSE, expect no updates.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create data with groups to update.
        CreateGLAccount(GLAccount);

        // SETUP: Update VAT Change Tool Setup table.
        ERMVATToolHelper.SetupToolOption(
          VATRateChangeSetup2.FieldNo("Update G/L Accounts"), VATRateChangeSetup2."Update G/L Accounts"::Both);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Perform Conversion"), true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check that Converted Date is Equal to WORKDATE.
        VerifyConvertedDate(WorkDate());

        // SETUP: Change WORKDATE.
        OldWorkDate := WorkDate();
        WorkDate(CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', OldWorkDate));

        // SETUP: Update VAT Change Tool Setup table.
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Perform Conversion"), true);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("VAT Rate Change Tool Completed"), false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check that Converted Date is Equal to WORKDATE.
        VerifyConvertedDate(WorkDate());

        // Tier Down: Restore WORKDATE.
        WorkDate(OldWorkDate);

        // Tear Down
        ERMVATToolHelper.DeleteRecords(DATABASE::"G/L Account");
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolItemVAT()
    begin
        VATToolItem(VATRateChangeSetup2."Update Items"::"VAT Prod. Posting Group", false, false, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolItemGen()
    begin
        VATToolItem(VATRateChangeSetup2."Update Items"::"Gen. Prod. Posting Group", false, false, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolItemBoth()
    begin
        VATToolItem(VATRateChangeSetup2."Update Items"::Both, false, false, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolItemNo()
    begin
        asserterror VATToolItem(VATRateChangeSetup2."Update Items"::No, false, false, 1);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolItemAutoInsertSetup()
    begin
        VATToolItem(VATRateChangeSetup2."Update Items"::Both, false, true, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolItemBothFilter()
    begin
        VATToolItem(VATRateChangeSetup2."Update Items"::Both, true, false, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolItemChargeVAT()
    begin
        VATToolItemCharge(VATRateChangeSetup2."Update Item Charges"::"VAT Prod. Posting Group", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolItemChargeGen()
    begin
        VATToolItemCharge(VATRateChangeSetup2."Update Item Charges"::"Gen. Prod. Posting Group", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolItemChargeBoth()
    begin
        VATToolItemCharge(VATRateChangeSetup2."Update Item Charges"::Both, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolItemChargeNo()
    begin
        asserterror VATToolItemCharge(VATRateChangeSetup2."Update Item Charges"::No, 1);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolResourceVAT()
    begin
        VATToolResource(VATRateChangeSetup2."Update Resources"::"VAT Prod. Posting Group", false, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolResourceGen()
    begin
        VATToolResource(VATRateChangeSetup2."Update Resources"::"Gen. Prod. Posting Group", false, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolResourceBoth()
    begin
        VATToolResource(VATRateChangeSetup2."Update Resources"::Both, false, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolResourceNo()
    begin
        asserterror VATToolResource(VATRateChangeSetup2."Update Resources"::No, false, 1);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolResFilterBoth()
    begin
        VATToolResource(VATRateChangeSetup2."Update Resources"::Both, true, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolGenProdPostGrpVAT()
    begin
        VATToolGenProdPostGrp(VATRateChangeSetup2."Update Gen. Prod. Post. Groups"::"VAT Prod. Posting Group", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolGenProdPostGrpNo()
    begin
        asserterror VATToolGenProdPostGrp(VATRateChangeSetup2."Update Gen. Prod. Post. Groups"::No, 1);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATTooGenProdPostGrpAutoInsert()
    var
        TempRecRef: RecordRef;
    begin
        // Update Gen. Prod. Posting Group table with Auto Insert Default = TRUE. No Confirmations expected.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        CreateGenProdPostingGroups(TempRecRef, 1, true);

        // SETUP: Update VAT Change Tool Setup table.
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup2.FieldNo("Update Gen. Prod. Post. Groups"),
          VATRateChangeSetup2."Update Gen. Prod. Post. Groups"::"VAT Prod. Posting Group");
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Perform Conversion"), true);

        // Excercise & Verify no Confirmation Messages are shown: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Tear Down
        ERMVATToolHelper.DeleteRecords(TempRecRef.Number);
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServPriceAdjDetGen()
    begin
        VATToolServPriceAdjDt(VATRateChangeSetup2."Update Serv. Price Adj. Detail"::"Gen. Prod. Posting Group", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServPriceAdjDetNo()
    begin
        asserterror VATToolServPriceAdjDt(VATRateChangeSetup2."Update Serv. Price Adj. Detail"::No, 1);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolWorkCenterGen()
    begin
        VATToolWorkCenter(VATRateChangeSetup2."Update Work Centers"::"Gen. Prod. Posting Group", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolWorkCenterNo()
    begin
        asserterror VATToolWorkCenter(VATRateChangeSetup2."Update Work Centers"::No, 1);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolMachineCenterGen()
    begin
        VATToolMachineCenter(VATRateChangeSetup2."Update Machine Centers"::"Gen. Prod. Posting Group", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolMachineCenterNo()
    begin
        asserterror VATToolMachineCenter(VATRateChangeSetup2."Update Machine Centers"::No, 1);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolGenJnlLineVAT()
    begin
        VATToolGenJnlLine(VATRateChangeSetup2."Update Gen. Journal Lines"::"VAT Prod. Posting Group", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolGenJnlLineGen()
    begin
        VATToolGenJnlLine(VATRateChangeSetup2."Update Gen. Journal Lines"::"Gen. Prod. Posting Group", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolGenJnlLineBoth()
    begin
        VATToolGenJnlLine(VATRateChangeSetup2."Update Gen. Journal Lines"::Both, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolGenJnlLineNo()
    begin
        asserterror VATToolGenJnlLine(VATRateChangeSetup2."Update Gen. Journal Lines"::No, 1);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolGenJnlAllVAT()
    begin
        VATToolGenJnlAll(VATRateChangeSetup2."Update Gen. Journal Allocation"::"VAT Prod. Posting Group", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolGenJnlAllGen()
    begin
        VATToolGenJnlAll(VATRateChangeSetup2."Update Gen. Journal Allocation"::"Gen. Prod. Posting Group", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolGenJnlAllBoth()
    begin
        VATToolGenJnlAll(VATRateChangeSetup2."Update Gen. Journal Allocation"::Both, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolGenJnllAllNo()
    begin
        asserterror VATToolGenJnlAll(VATRateChangeSetup2."Update Gen. Journal Allocation"::No, 1);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolStdGenJnlLineVAT()
    begin
        VATToolStdGenJnlLine(VATRateChangeSetup2."Update Std. Gen. Jnl. Lines"::"VAT Prod. Posting Group", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolStdGenJnlLineGen()
    begin
        VATToolStdGenJnlLine(VATRateChangeSetup2."Update Std. Gen. Jnl. Lines"::"VAT Prod. Posting Group", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolStdGenJnlLineBoth()
    begin
        VATToolStdGenJnlLine(VATRateChangeSetup2."Update Std. Gen. Jnl. Lines"::"VAT Prod. Posting Group", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolStdGenJnlLineNo()
    begin
        asserterror VATToolStdGenJnlLine(VATRateChangeSetup2."Update Std. Gen. Jnl. Lines"::No, 1);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolResJnlLineGen()
    begin
        VATToolRscJnlLine(VATRateChangeSetup2."Update Res. Journal Lines"::"Gen. Prod. Posting Group", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolResJnlLineNo()
    begin
        asserterror VATToolRscJnlLine(VATRateChangeSetup2."Update Res. Journal Lines"::No, 1);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolJobJnlLineGen()
    begin
        VATToolJobJnlLine(VATRateChangeSetup2."Update Job Journal Lines"::"Gen. Prod. Posting Group", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolJobJnlLineNo()
    begin
        asserterror VATToolJobJnlLine(VATRateChangeSetup2."Update Job Journal Lines"::No, 1);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolStdItemJnlLineGen()
    begin
        VATToolStdItemJnlLine(VATRateChangeSetup2."Update Std. Item Jnl. Lines"::"Gen. Prod. Posting Group", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolStdItemJnlLineNo()
    begin
        asserterror VATToolStdItemJnlLine(VATRateChangeSetup2."Update Std. Item Jnl. Lines"::No, 1);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolReqLineGen()
    begin
        VATToolRqstnLine(VATRateChangeSetup2."Update Requisition Lines"::"Gen. Prod. Posting Group", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolReqLineNo()
    begin
        asserterror VATToolRqstnLine(VATRateChangeSetup2."Update Requisition Lines"::No, 1);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPricesInclVATFieldsExistOnTheVATRateChangeToolPage()
    var
        VATRateChangeSetup: TestPage "VAT Rate Change Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 361066] The fields related to the unit price including VAT are visible on the VAT Rate Change Tool page

        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        VATRateChangeSetup.OpenEdit();
        Assert.IsTrue(VATRateChangeSetup."Update G/L Accounts".Visible(), 'Update G/L Accounts field is not visible');
        Assert.IsTrue(VATRateChangeSetup."Upd. Unit Price For Item Chrg.".Visible(), 'Upd. Unit Price For Item Chrg. field is not visible');
        Assert.IsTrue(VATRateChangeSetup."Upd. Unit Price For FA".Visible(), 'Upd. Unit Price For FA field is not visible');
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    local procedure VATToolGLAccount(FieldOption: Option; "Filter": Boolean; "Count": Integer)
    var
        GLAccount: Record "G/L Account";
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        CreateGLAccounts(TempRecRef, Count);

        // SETUP: Create an additional data record to test filters usage.
        if Filter then
            CreateGLAccount(GLAccount);

        // SETUP: Update VAT Change Tool Setup table.
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup2.FieldNo("Update G/L Accounts"), FieldOption);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Perform Conversion"), true);
        ERMVATToolHelper.SetupToolString(VATRateChangeSetup2.FieldNo("Account Filter"), GetGLAccountFilter(TempRecRef));

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyLogEntries(TempRecRef);

        // Tear Down
        ERMVATToolHelper.DeleteRecords(TempRecRef.Number);
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolItem(FieldOption: Option; "Filter": Boolean; AutoInsertDefault: Boolean; "Count": Integer)
    var
        Item: Record Item;
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(AutoInsertDefault);

        // SETUP: Create and save data to update in a temporary table.
        CreateItems(TempRecRef, Count);

        // SETUP: Create an additional data record to test filters usage.
        if Filter then
            ERMVATToolHelper.CreateItem(Item);

        // SETUP: Update VAT Change Tool Setup table.
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup2.FieldNo("Update Items"), FieldOption);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Perform Conversion"), true);
        ERMVATToolHelper.SetupToolString(VATRateChangeSetup2.FieldNo("Item Filter"), GetItemFilter(TempRecRef));

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyLogEntries(TempRecRef);

        // Tear Down
        ERMVATToolHelper.DeleteRecords(TempRecRef.Number);
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolItemCharge(FieldOption: Option; "Count": Integer)
    var
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        CreateItemCharges(TempRecRef, Count);

        // SETUP: Update VAT Change Tool Setup table.
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup2.FieldNo("Update Item Charges"), FieldOption);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Perform Conversion"), true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyLogEntries(TempRecRef);

        // Tear Down
        ERMVATToolHelper.DeleteRecords(TempRecRef.Number);
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolResource(FieldOption: Option; "Filter": Boolean; "Count": Integer)
    var
        Resource: Record Resource;
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        CreateResources(TempRecRef, Count);

        // SETUP: Create an additional data record to test filters usage.
        if Filter then
            CreateResource(Resource);

        // SETUP: Update VAT Change Tool Setup table.
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup2.FieldNo("Update Resources"), FieldOption);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Perform Conversion"), true);
        ERMVATToolHelper.SetupToolString(VATRateChangeSetup2.FieldNo("Resource Filter"), GetResourceFilter(TempRecRef));

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyLogEntries(TempRecRef);

        // Tear Down
        ERMVATToolHelper.DeleteRecords(TempRecRef.Number);
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolGenProdPostGrp(FieldOption: Option; "Count": Integer)
    var
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        CreateGenProdPostingGroups(TempRecRef, Count, false);

        // SETUP: Update VAT Change Tool Setup table.
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup2.FieldNo("Update Gen. Prod. Post. Groups"), FieldOption);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Perform Conversion"), true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyLogEntries(TempRecRef);

        // Tear Down
        ERMVATToolHelper.DeleteRecords(TempRecRef.Number);
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolServPriceAdjDt(FieldOption: Option; "Count": Integer)
    var
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        CreateServPriceAdjDetails(TempRecRef, Count);

        // SETUP: Update VAT Change Tool Setup table.
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup2.FieldNo("Update Serv. Price Adj. Detail"), FieldOption);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Perform Conversion"), true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyLogEntries(TempRecRef);

        // Tear Down
        ERMVATToolHelper.DeleteRecords(TempRecRef.Number);
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolWorkCenter(FieldOption: Option; "Count": Integer)
    var
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        CreateWorkCenters(TempRecRef, Count);

        // SETUP: Update VAT Change Tool Setup table.
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup2.FieldNo("Update Work Centers"), FieldOption);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Perform Conversion"), true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyLogEntries(TempRecRef);

        // Tear Down
        ERMVATToolHelper.DeleteRecords(TempRecRef.Number);
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolMachineCenter(FieldOption: Option; "Count": Integer)
    var
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        CreateMachineCenters(TempRecRef, Count);

        // SETUP: Update VAT Change Tool Setup table.
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup2.FieldNo("Update Machine Centers"), FieldOption);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Perform Conversion"), true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyLogEntries(TempRecRef);

        // Tear Down
        ERMVATToolHelper.DeleteRecords(TempRecRef.Number);
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolGenJnlLine(FieldOption: Option; "Count": Integer)
    var
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        CreateGenJnlLines(TempRecRef, Count);

        // SETUP: Update VAT Change Tool Setup table.
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup2.FieldNo("Update Gen. Journal Lines"), FieldOption);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Perform Conversion"), true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyLogEntries(TempRecRef);

        // Tear Down
        ERMVATToolHelper.DeleteRecords(TempRecRef.Number);
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolGenJnlAll(FieldOption: Option; "Count": Integer)
    var
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        CreateGenJnlAll(TempRecRef, Count);

        // SETUP: Update VAT Change Tool Setup table.
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup2.FieldNo("Update Gen. Journal Allocation"), FieldOption);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Perform Conversion"), true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyLogEntries(TempRecRef);

        // Tear Down
        ERMVATToolHelper.DeleteRecords(TempRecRef.Number);
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolStdGenJnlLine(FieldOption: Option; "Count": Integer)
    var
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        CreateStdGenJnlLines(TempRecRef, Count);

        // SETUP: Update VAT Change Tool Setup table.
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup2.FieldNo("Update Std. Gen. Jnl. Lines"), FieldOption);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Perform Conversion"), true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyLogEntries(TempRecRef);

        // Tear Down
        ERMVATToolHelper.DeleteRecords(TempRecRef.Number);
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolRscJnlLine(FieldOption: Option; "Count": Integer)
    var
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        CreateRscJnlLines(TempRecRef, Count);

        // SETUP: Update VAT Change Tool Setup table.
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup2.FieldNo("Update Res. Journal Lines"), FieldOption);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Perform Conversion"), true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyLogEntries(TempRecRef);

        // Tear Down
        ERMVATToolHelper.DeleteRecords(TempRecRef.Number);
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolJobJnlLine(FieldOption: Option; "Count": Integer)
    var
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        CreateJobJnlLines(TempRecRef, Count);

        // SETUP: Update VAT Change Tool Setup table.
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup2.FieldNo("Update Job Journal Lines"), FieldOption);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Perform Conversion"), true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyLogEntries(TempRecRef);

        // Tear Down
        ERMVATToolHelper.DeleteRecords(TempRecRef.Number);
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolStdItemJnlLine(FieldOption: Option; "Count": Integer)
    var
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        CreateStdItemJnlLines(TempRecRef, Count);

        // SETUP: Update VAT Change Tool Setup table.
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup2.FieldNo("Update Std. Item Jnl. Lines"), FieldOption);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Perform Conversion"), true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyLogEntries(TempRecRef);

        // Tear Down
        ERMVATToolHelper.DeleteRecords(TempRecRef.Number);
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolRqstnLine(FieldOption: Option; "Count": Integer)
    var
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        CreateRqstnLines(TempRecRef, Count);

        // SETUP: Update VAT Change Tool Setup table.
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup2.FieldNo("Update Requisition Lines"), FieldOption);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup2.FieldNo("Perform Conversion"), true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyLogEntries(TempRecRef);

        // Tear Down
        ERMVATToolHelper.DeleteRecords(TempRecRef.Number);
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure CreateGenJnlAll(var TempRecRef: RecordRef; "Count": Integer)
    var
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        GenJnlLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        RecRef: RecordRef;
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
        I: Integer;
    begin
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        TempRecRef.Open(DATABASE::"Gen. Jnl. Allocation", true);

        LibraryERM.FindRecurringTemplateName(GenJournalTemplate);
        GenJournalBatch.SetRange(Recurring, true);
        if not GenJournalBatch.FindFirst() then
            LibraryERM.CreateRecurringBatchName(GenJournalBatch, GenJournalTemplate.Name);
        for I := 1 to Count do begin
            CreateGenJnlLine(GenJnlLine, GenJournalTemplate.Name, GenJournalBatch.Name);
            LibraryERM.CreateGenJnlAllocation(GenJnlAllocation, GenJnlLine."Journal Template Name",
              GenJnlLine."Journal Batch Name", GenJnlLine."Line No.");
            GenJnlAllocation.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
            GenJnlAllocation.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
            GenJnlAllocation.Modify(true);
            RecRef.GetTable(GenJnlAllocation);
            ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);
        end;
    end;

    local procedure CreateGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10])
    var
        RecRef: RecordRef;
    begin
        GenJnlLine.Init();
        GenJnlLine.Validate("Journal Template Name", GenJnlTemplateName);
        GenJnlLine.Validate("Journal Batch Name", GenJnlBatchName);
        RecRef.GetTable(GenJnlLine);
        GenJnlLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, GenJnlLine.FieldNo("Line No.")));
        GenJnlLine.Insert(true);
    end;

    local procedure CreateGenJnlLines(var TempRecRef: RecordRef; "Count": Integer)
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        RecRef: RecordRef;
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
        I: Integer;
    begin
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        TempRecRef.Open(DATABASE::"Gen. Journal Line", true);

        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        for I := 1 to Count do begin
            CreateGenJnlLine(GenJnlLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
            GenJnlLine.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
            GenJnlLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
            GenJnlLine.Modify(true);
            RecRef.GetTable(GenJnlLine);
            ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);
        end;
    end;

    local procedure CreateGenProdPostingGroups(var TempRecRef: RecordRef; "Count": Integer; AutoInsert: Boolean)
    var
        GenProdPostGroup: Record "Gen. Product Posting Group";
        RecRef: RecordRef;
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
        I: Integer;
    begin
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        TempRecRef.Open(DATABASE::"Gen. Product Posting Group", true);

        for I := 1 to Count do begin
            GenProdPostGroup.Init();
            GenProdPostGroup.Validate(Code, LibraryUtility.GenerateRandomCode
              (GenProdPostGroup.FieldNo(Code), DATABASE::"Gen. Product Posting Group"));
            GenProdPostGroup.Validate("Auto Insert Default", AutoInsert);
            GenProdPostGroup.Validate("Def. VAT Prod. Posting Group", VATProdPostingGroup);
            GenProdPostGroup.Insert(true);
            RecRef.GetTable(GenProdPostGroup);
            ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);
        end;
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    var
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
    begin
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);

        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
    end;

    local procedure CreateGLAccounts(var TempRecRef: RecordRef; "Count": Integer)
    var
        GLAccount: Record "G/L Account";
        RecRef: RecordRef;
        I: Integer;
    begin
        TempRecRef.Open(DATABASE::"G/L Account", true);

        for I := 1 to Count do begin
            CreateGLAccount(GLAccount);
            RecRef.GetTable(GLAccount);
            ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);
        end;
    end;

    local procedure CreateItems(var TempRecRef: RecordRef; "Count": Integer)
    var
        Item: Record Item;
        RecRef: RecordRef;
        I: Integer;
    begin
        TempRecRef.Open(DATABASE::Item, true);

        for I := 1 to Count do begin
            ERMVATToolHelper.CreateItem(Item);
            RecRef.GetTable(Item);
            ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);
        end;
    end;

    local procedure CreateItemCharges(var TempRecRef: RecordRef; "Count": Integer)
    var
        ItemCharge: Record "Item Charge";
        RecRef: RecordRef;
        I: Integer;
    begin
        TempRecRef.Open(DATABASE::"Item Charge", true);

        for I := 1 to Count do begin
            ERMVATToolHelper.CreateItemCharge(ItemCharge);
            RecRef.GetTable(ItemCharge);
            ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);
        end;
    end;

    local procedure CreateJobJnlLines(var TempRecRef: RecordRef; "Count": Integer)
    var
        JobJnlLine: Record "Job Journal Line";
        JobJnlBatch: Record "Job Journal Batch";
        JobJnlTemplate: Record "Job Journal Template";
        RecRef: RecordRef;
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
        I: Integer;
    begin
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        TempRecRef.Open(DATABASE::"Job Journal Line", true);

        if not JobJnlBatch.FindFirst() then begin
            LibraryJob.GetJobJournalTemplate(JobJnlTemplate);
            LibraryJob.CreateJobJournalBatch(JobJnlTemplate.Name, JobJnlBatch);
        end;
        for I := 1 to Count do begin
            JobJnlLine.Init();
            JobJnlLine.Validate("Journal Template Name", JobJnlBatch."Journal Template Name");
            JobJnlLine.Validate("Journal Batch Name", JobJnlBatch.Name);
            RecRef.GetTable(JobJnlLine);
            JobJnlLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, JobJnlLine.FieldNo("Line No.")));
            JobJnlLine.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
            JobJnlLine.Insert(true);
            RecRef.GetTable(JobJnlLine);
            ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);
        end;
    end;

    local procedure CreateMachineCenters(var TempRecRef: RecordRef; "Count": Integer)
    var
        MachineCenter: Record "Machine Center";
        RecRef: RecordRef;
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
        I: Integer;
    begin
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        TempRecRef.Open(DATABASE::"Machine Center", true);

        for I := 1 to Count do begin
            MachineCenter.Init();
            MachineCenter.Validate("No.", LibraryUtility.GenerateRandomCode(MachineCenter.FieldNo("No."),
                DATABASE::"Machine Center"));
            MachineCenter.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
            MachineCenter.Insert(true);
            RecRef.GetTable(MachineCenter);
            ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);
        end;
    end;

    local procedure CreateRqstnLine(var ReqLine: Record "Requisition Line"; ReqWkshName: Record "Requisition Wksh. Name")
    var
        RecRef: RecordRef;
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
    begin
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);

        ReqLine.Init();
        ReqLine.Validate("Worksheet Template Name", ReqWkshName."Worksheet Template Name");
        ReqLine.Validate("Journal Batch Name", ReqWkshName.Name);
        RecRef.GetTable(ReqLine);
        ReqLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, ReqLine.FieldNo("Line No.")));
        ReqLine.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        ReqLine.Insert(true);
    end;

    local procedure CreateRqstnLines(var TempRecRef: RecordRef; "Count": Integer)
    var
        ReqLine: Record "Requisition Line";
        ReqWkshName: Record "Requisition Wksh. Name";
        RecRef: RecordRef;
        I: Integer;
    begin
        TempRecRef.Open(DATABASE::"Requisition Line", true);

        FindRqstnWkshName(ReqWkshName);
        for I := 1 to Count do begin
            CreateRqstnLine(ReqLine, ReqWkshName);
            RecRef.GetTable(ReqLine);
            ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);
        end;
    end;

    local procedure CreateResource(var Resource: Record Resource)
    var
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
    begin
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);

        Resource.Init();
        Resource.Validate("No.", LibraryUtility.GenerateRandomCode(Resource.FieldNo("No."),
            DATABASE::Resource));
        Resource.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        Resource.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Resource.Insert(true);
    end;

    local procedure CreateResources(var TempRecRef: RecordRef; "Count": Integer)
    var
        Resource: Record Resource;
        RecRef: RecordRef;
        I: Integer;
    begin
        TempRecRef.Open(DATABASE::Resource, true);

        for I := 1 to Count do begin
            CreateResource(Resource);
            RecRef.GetTable(Resource);
            ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);
        end;
    end;

    local procedure CreateRscJnlLines(var TempRecRef: RecordRef; "Count": Integer)
    var
        ResJnlLine: Record "Res. Journal Line";
        ResJnlTemplate: Record "Res. Journal Template";
        ResJnlBatch: Record "Res. Journal Batch";
        RecRef: RecordRef;
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
        I: Integer;
    begin
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        TempRecRef.Open(DATABASE::"Res. Journal Line", true);

        ResJnlTemplate.SetRange(Recurring, false);
        LibraryResource.FindResJournalTemplate(ResJnlTemplate);
        LibraryResource.FindResJournalBatch(ResJnlBatch, ResJnlTemplate.Name);
        for I := 1 to Count do begin
            LibraryResource.CreateResJournalLine(ResJnlLine, ResJnlTemplate.Name, ResJnlBatch.Name);
            ResJnlLine.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
            ResJnlLine.Modify(true);
            RecRef.GetTable(ResJnlLine);
            ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);
        end;
    end;

    local procedure CreateServPriceAdjDetail(var ServPriceAdjustmentDetail: Record "Serv. Price Adjustment Detail")
    var
        ServPriceAdjustmentGroup: Record "Service Price Adjustment Group";
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
    begin
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        CreateServPriceAdjGroup(ServPriceAdjustmentGroup);
        ServPriceAdjustmentDetail.Init();
        ServPriceAdjustmentDetail.Validate("Serv. Price Adjmt. Gr. Code", ServPriceAdjustmentGroup.Code);
        ServPriceAdjustmentDetail.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        ServPriceAdjustmentDetail.Insert(true);
    end;

    local procedure CreateServPriceAdjDetails(var TempRecRef: RecordRef; "Count": Integer)
    var
        ServPriceAdjustmentDetail: Record "Serv. Price Adjustment Detail";
        RecRef: RecordRef;
        I: Integer;
    begin
        TempRecRef.Open(DATABASE::"Serv. Price Adjustment Detail", true);

        for I := 1 to Count do begin
            CreateServPriceAdjDetail(ServPriceAdjustmentDetail);
            RecRef.GetTable(ServPriceAdjustmentDetail);
            ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);
        end;
    end;

    local procedure CreateServPriceAdjGroup(var ServPriceAdjustmentGroup: Record "Service Price Adjustment Group")
    begin
        ServPriceAdjustmentGroup.Init();
        ServPriceAdjustmentGroup.Validate(Code, LibraryUtility.GenerateRandomCode(ServPriceAdjustmentGroup.FieldNo(Code),
            DATABASE::"Service Price Adjustment Group"));
        ServPriceAdjustmentGroup.Insert(true);
    end;

    local procedure CreateStdGenJnlLines(var TempRecRef: RecordRef; "Count": Integer)
    var
        StdGenJnlLine: Record "Standard General Journal Line";
        GenJnlTemplate: Record "Gen. Journal Template";
        StdGenJnl: Record "Standard General Journal";
        RecRef: RecordRef;
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
        I: Integer;
    begin
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        TempRecRef.Open(DATABASE::"Standard General Journal Line", true);

        if not StdGenJnl.FindFirst() then begin
            LibraryERM.FindGenJournalTemplate(GenJnlTemplate);
            LibraryERM.CreateStandardGeneralJournal(StdGenJnl, GenJnlTemplate.Name);
        end;
        for I := 1 to Count do begin
            StdGenJnlLine.Init();
            StdGenJnlLine.Validate("Journal Template Name", StdGenJnl."Journal Template Name");
            StdGenJnlLine.Validate("Standard Journal Code", StdGenJnl.Code);
            RecRef.GetTable(StdGenJnlLine);
            StdGenJnlLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, StdGenJnlLine.FieldNo("Line No.")));
            StdGenJnlLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
            StdGenJnlLine.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
            StdGenJnlLine.Insert(true);
            RecRef.GetTable(StdGenJnlLine);
            ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);
        end;
    end;

    local procedure CreateStdItemJnlLines(var TempRecRef: RecordRef; "Count": Integer)
    var
        StdItemJnlLine: Record "Standard Item Journal Line";
        StdItemJnl: Record "Standard Item Journal";
        RecRef: RecordRef;
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
        I: Integer;
    begin
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        TempRecRef.Open(DATABASE::"Standard Item Journal Line", true);

        FindStdItemJnl(StdItemJnl);
        for I := 1 to Count do begin
            StdItemJnlLine.Init();
            StdItemJnlLine.Validate("Journal Template Name", StdItemJnl."Journal Template Name");
            StdItemJnlLine.Validate("Standard Journal Code", StdItemJnl.Code);
            RecRef.GetTable(StdItemJnlLine);
            StdItemJnlLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, StdItemJnlLine.FieldNo("Line No.")));
            StdItemJnlLine.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
            StdItemJnlLine.Insert(true);
            RecRef.GetTable(StdItemJnlLine);
            ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);
        end;
    end;

    local procedure CreateWorkCenters(var TempRecRef: RecordRef; "Count": Integer)
    var
        WorkCenter: Record "Work Center";
        RecRef: RecordRef;
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
        I: Integer;
    begin
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        TempRecRef.Open(DATABASE::"Work Center", true);

        for I := 1 to Count do begin
            WorkCenter.Init();
            WorkCenter.Validate("No.", LibraryUtility.GenerateRandomCode(WorkCenter.FieldNo("No."),
                DATABASE::"Work Center"));
            WorkCenter.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
            WorkCenter.Insert(true);
            RecRef.GetTable(WorkCenter);
            ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);
        end;
    end;

    local procedure FindRqstnWkshName(var ReqWkshName: Record "Requisition Wksh. Name")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        if not ReqWkshName.FindFirst() then begin
            ReqWkshTemplate.FindFirst();
            LibraryPlanning.CreateRequisitionWkshName(ReqWkshName, ReqWkshTemplate.Name);
        end;
    end;

    local procedure FindStdItemJnl(var StdItemJnl: Record "Standard Item Journal")
    var
        ItemJnlTemplate: Record "Item Journal Template";
    begin
        if not StdItemJnl.FindFirst() then begin
            LibraryInventory.FindItemJournalTemplate(ItemJnlTemplate);
            StdItemJnl.Init();
            StdItemJnl.Validate("Journal Template Name", ItemJnlTemplate.Name);
            StdItemJnl.Validate(Code,
              LibraryUtility.GenerateRandomCode(StdItemJnl.FieldNo(Code), DATABASE::"Standard Item Journal"));
            StdItemJnl.Insert(true);
        end;
    end;

    local procedure GetGLAccountFilter(TempRecRef: RecordRef) SelectionFilter: Text[250]
    var
        GLAccount: Record "G/L Account";
    begin
        repeat
            TempRecRef.SetTable(GLAccount);
            if SelectionFilter <> '' then
                SelectionFilter := SelectionFilter + '|' + GLAccount."No."
            else
                SelectionFilter := GLAccount."No.";
        until TempRecRef.Next() = 0
    end;

    local procedure GetItemFilter(TempRecRef: RecordRef) SelectionFilter: Text[250]
    var
        Item: Record Item;
    begin
        repeat
            TempRecRef.SetTable(Item);
            if SelectionFilter <> '' then
                SelectionFilter := SelectionFilter + '|' + Item."No."
            else
                SelectionFilter := Item."No.";
        until TempRecRef.Next() = 0
    end;

    local procedure GetResourceFilter(TempRecRef: RecordRef) SelectionFilter: Text[250]
    var
        Resource: Record Resource;
    begin
        repeat
            TempRecRef.SetTable(Resource);
            if SelectionFilter <> '' then
                SelectionFilter := SelectionFilter + '|' + Resource."No."
            else
                SelectionFilter := Resource."No.";
        until TempRecRef.Next() = 0
    end;

    local procedure VerifyConvertedDate(ConvertedDate: Date)
    var
        VATRateChangeConv: Record "VAT Rate Change Conversion";
        GenProdPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        VATRateChangeConv.Get(VATRateChangeConv.Type::"VAT Prod. Posting Group", VATProdPostingGroup);
        VATRateChangeConv.TestField("Converted Date", ConvertedDate);
        VATRateChangeConv.Get(VATRateChangeConv.Type::"Gen. Prod. Posting Group", GenProdPostingGroup);
        VATRateChangeConv.TestField("Converted Date", ConvertedDate);
    end;
}
