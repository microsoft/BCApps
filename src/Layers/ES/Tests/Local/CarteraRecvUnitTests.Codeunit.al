codeunit 147542 "Cartera Recv. Unit Tests"
{
    // // [FEATURE] [UT] [Cartera] [Receivables]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryCarteraReceivables: Codeunit "Library - Cartera Receivables";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryERM: Codeunit "Library - ERM";
        LocalTxt: Label 'LOCAL', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure CreateBillGroupWithCustomNo()
    var
        BillGroup: Record "Bill Group";
        CarteraSetup: Record "Cartera Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        BillGroupNo: Code[20];
        OldBillGroupNoSeries: Code[20];
    begin
        Initialize();

        // Pre-Setup
        LibraryUtility.CreateNoSeries(NoSeries, false, true, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');

        // Setup
        CarteraSetup.Get();
        OldBillGroupNoSeries := CarteraSetup."Bill Group Nos.";
        CarteraSetup.Validate("Bill Group Nos.", NoSeries.Code);
        CarteraSetup.Modify(true);

        // Pre-Exercise
        BillGroupNo := LibraryUtility.GenerateRandomCode(BillGroup.FieldNo("No."), DATABASE::"Bill Group");

        // Exercise
        BillGroup.Init();
        BillGroup.Validate("No.", BillGroupNo);
        BillGroup.Insert(true);

        // Verify
        Assert.AreEqual(0, BillGroup."No. Printed", '');
        Assert.AreEqual(BillGroup.TableCaption + ' ' + BillGroupNo, BillGroup."Posting Description", '');

        // Teadown
        CarteraSetup.Get();
        CarteraSetup.Validate("Bill Group Nos.", OldBillGroupNoSeries);
        CarteraSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('BGCommentSheetPageHandler')]
    [Scope('OnPrem')]
    procedure CreateBillGroupWithComments()
    var
        BillGroup: Record "Bill Group";
        BGCommentLine: Record "BG/PO Comment Line";
        Comment: Variant;
    begin
        Initialize();

        // Pre-Setup
        CreateBillGroupWithBankAccount(BillGroup);

        // Exercise
        AddCommentLineFromList(BillGroup."No.");

        // Post-Exercise
        Commit();

        // Pre-Verify
        LibraryVariableStorage.Dequeue(Comment);

        // Verify
        BGCommentLine.SetRange("BG/PO No.", BillGroup."No.");
        BGCommentLine.SetRange(Type, BGCommentLine.Type::Receivable);
        BGCommentLine.SetRange(Comment, Comment);
        Assert.IsFalse(BGCommentLine.IsEmpty, '');

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('BGCommentSheetPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteBillGroup()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        BGCommentLine: Record "BG/PO Comment Line";
        BillGroupNo: Code[20];
    begin
        Initialize();

        // Pre-Setup
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, '');

        // Setup
        BillGroupNo := LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection);
        AddCommentLineFromCard(BillGroupNo);

        // Exercise
        BillGroup.Get(BillGroupNo);
        BillGroup.Delete(true);

        // Verify
        Assert.IsFalse(BillGroup.Get(BillGroupNo), '');
        BGCommentLine.SetRange("BG/PO No.", BillGroupNo);
        Assert.IsTrue(BGCommentLine.IsEmpty, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunBillGroupsMaturityGeneralActionForSelectedBillGroup()
    var
        BillGroup: array[2] of Record "Bill Group";
        BillGroupsList: TestPage "Bill Groups List";
        BillGroupsMaturity: TestPage "Bill Groups Maturity";
    begin
        // [FEATURE] [Bill Group] [UI]
        // [SCENARIO 363721] Action "Bill Groups Maturity" on "Bill Groups List" with multiple lines should open page for selected Bill Group
        Initialize();

        // [GIVEN] Two Bill Groups in "Bill Groups List" page: "BG1" and "BG2"
        CreateBillGroupWithBankAccount(BillGroup[1]);
        CreateBillGroupWithBankAccount(BillGroup[2]);

        // [GIVEN] Select Bill Group "BG2" from "Bill Groups List" page
        BillGroupsList.OpenView();
        BillGroupsList.GotoRecord(BillGroup[2]);

        // [WHEN] Run General Action "Bill Groups Maturity"
        BillGroupsMaturity.Trap();
        BillGroupsList.GeneralBillGroupsMaturity.Invoke();

        // [THEN] "Bill Groups Maturity" page is opened for Bill Group "BG2"
        Assert.AreEqual(BillGroup[2]."No.", BillGroupsMaturity.FILTER.GetFilter("No."), BillGroup[2].FieldCaption("No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenDocumentsMaturityFromReceivablesCarteraDocs()
    var
        CarteraDoc: Record "Cartera Doc.";
        ReceivablesCarteraDocs: TestPage "Receivables Cartera Docs";
        DocumentsMaturity: TestPage "Documents Maturity";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 381041] Action "Documents Maturity" should open a page for the Receivables type.
        Initialize();

        // [GIVEN] Cartera Document
        MockReceivableCarteraDoc(CarteraDoc);

        // [GIVEN] Open Page for Receivables Cartera Docs
        ReceivablesCarteraDocs.OpenView();

        // [WHEN] Run Action "Documents Maturity"
        DocumentsMaturity.Trap();
        ReceivablesCarteraDocs."Documents Maturity".Invoke();

        // [THEN] A filter for the field "Type" is transfered to the Documents Maturity Page.
        Assert.AreEqual(
          Format(CarteraDoc.Type),
          DocumentsMaturity.FILTER.GetFilter(Type),
          Format(CarteraDoc.Type::Receivable));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenBillGroupsMaturityFromBillGroupCard()
    var
        BillGroup: array[2] of Record "Bill Group";
        BillGroups: TestPage "Bill Groups";
        BillGroupsMaturity: TestPage "Bill Groups Maturity";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 381041] Action "Bill Groups Maturity" should open a page for the selected Bill Group.
        Initialize();

        // [GIVEN] Two Bill Group documents created "BG1" and "BG2"
        CreateBillGroupWithBankAccount(BillGroup[1]);
        CreateBillGroupWithBankAccount(BillGroup[2]);

        // [GIVEN] Open a Bill Groups Page for the "BG2"
        BillGroups.OpenView();
        BillGroups.GotoRecord(BillGroup[2]);

        // [WHEN] Run Action "Bill Groups Maturity"
        BillGroupsMaturity.Trap();
        BillGroups.BillGroupsMaturity.Invoke();

        // [THEN] "Bill Groups Maturity" page is opened for "BG2"
        Assert.AreEqual(
          BillGroup[2]."No.",
          BillGroupsMaturity.FILTER.GetFilter("No."),
          BillGroup[2].FieldCaption("No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenPostedBillGroupsMaturityFromPostedBillGroupCard()
    var
        PostedBillGroup: array[2] of Record "Posted Bill Group";
        PostedBillGroups: TestPage "Posted Bill Groups";
        PostedBillGroupsMaturity: TestPage "Posted Bill Groups Maturity";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 381041] Action "Posted Bill Groups Maturity" should open a page for the selected Posted Bill Group from Card Page.
        Initialize();

        // [GIVEN] Two Posted Bill Group documents created "BG1" and "BG2"
        MockPostedBillGroup(PostedBillGroup[1]);
        MockPostedBillGroup(PostedBillGroup[2]);

        // [GIVEN] Open a Posted Bill Groups Page for the "BG2"
        PostedBillGroups.OpenView();
        PostedBillGroups.GotoRecord(PostedBillGroup[2]);

        // [WHEN] Run Action "Posted Bill Groups Maturity"
        PostedBillGroupsMaturity.Trap();
        PostedBillGroups."Posted Bill Groups Maturity".Invoke();

        // [THEN] "Posted Bill Groups Maturity" page is opened for "BG2"
        Assert.AreEqual(
          PostedBillGroup[2]."No.",
          PostedBillGroupsMaturity.FILTER.GetFilter("No."),
          PostedBillGroup[2].FieldCaption("No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenPostedBillGroupsMaturityFromPostedBillGroupList()
    var
        PostedBillGroup: array[2] of Record "Posted Bill Group";
        PostedBillGroupsList: TestPage "Posted Bill Groups List";
        PostedBillGroupsMaturity: TestPage "Posted Bill Groups Maturity";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 381041] Action "Posted Bill Groups Maturity" should open a page for the selected Posted Bill Group from List Page.
        Initialize();

        // [GIVEN] Two Posted Bill Group documents created "BG1" and "BG2"
        MockPostedBillGroup(PostedBillGroup[1]);
        MockPostedBillGroup(PostedBillGroup[2]);

        // [GIVEN] Open a Posted Bill Groups Page for the "BG2"
        PostedBillGroupsList.OpenView();
        PostedBillGroupsList.GotoRecord(PostedBillGroup[2]);

        // [WHEN] Run Action "Posted Bill Groups Maturity"
        PostedBillGroupsMaturity.Trap();
        PostedBillGroupsList."Posted Bill Groups Maturity".Invoke();

        // [THEN] "Posted Bill Groups Maturity" page is opened for "BG2"
        Assert.AreEqual(
          PostedBillGroup[2]."No.",
          PostedBillGroupsMaturity.FILTER.GetFilter("No."),
          PostedBillGroup[2].FieldCaption("No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenPostedBillGroupsMaturityFromPostedBillGroupSelect()
    var
        PostedBillGroup: array[2] of Record "Posted Bill Group";
        PostedBillGroupSelect: TestPage "Posted Bill Group Select.";
        PostedBillGroupsMaturity: TestPage "Posted Bill Groups Maturity";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 381041] Action "Posted Bill Groups Maturity" should open a page for the selected Posted Bill Group from Select Page.
        Initialize();

        // [GIVEN] Two Posted Bill Group documents created "BG1" and "BG2"
        MockPostedBillGroup(PostedBillGroup[1]);
        MockPostedBillGroup(PostedBillGroup[2]);

        // [GIVEN] Open a Posted Bill Groups Select Page for the "BG2"
        PostedBillGroupSelect.OpenView();
        PostedBillGroupSelect.GotoRecord(PostedBillGroup[2]);

        // [WHEN] Run Action "Posted Bill Groups Maturity"
        PostedBillGroupsMaturity.Trap();
        PostedBillGroupSelect."Posted Bill Groups Maturity".Invoke();

        // [THEN] "Posted Bill Groups Maturity" page is opened for "BG2"
        Assert.AreEqual(
          PostedBillGroup[2]."No.",
          PostedBillGroupsMaturity.FILTER.GetFilter("No."),
          PostedBillGroup[2].FieldCaption("No."));
    end;

    [TestPermissions(TestPermissions::Restrictive)]
    [Scope('OnPrem')]
    procedure IndirectCarteraDocPermissionFromCustomerLedgerEntry()
    var
        CarteraDoc: Record "Cartera Doc.";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentMethod: Record "Payment Method";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        // [FEATURE] [Permission] [UI]
        // [SCENARIO 257878] Customer Ledger Entry's "Payment Method Code" can be modified (including linked "Cartera Doc." update) via indirect customer license
        Initialize();
        // TODO: Uncomment LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        MockReceivableCarteraDoc(CarteraDoc);
        MockCustomerLedgerEntry(CustLedgerEntry, CarteraDoc);
        ModifyPermissionData(LocalTxt, DATABASE::"Cartera Doc.", 2, 0, 2, 0);
        Commit();

        // [GIVEN] Customer license with indirect permissions (RxMx) to "Cartera Doc."
        // TODO: Uncomment LibraryLowerPermissions.SetCustomerView(); // includes "LOCAL" role with changed permissions to "Cartera Doc."
        // [GIVEN] "Cartera Doc." can not be read or modified directly due to indirect permissions
        asserterror CarteraDoc.Find();
        Assert.ExpectedErrorCode('DB:ClientReadDenied');
        Assert.ExpectedError(CarteraDoc.TableName);
        asserterror CarteraDoc.Modify();
        Assert.ExpectedErrorCode('DB:ClientModifyDenied');
        Assert.ExpectedError(CarteraDoc.TableName);

        // [GIVEN] Customer Ledger Entry page
        // [WHEN] Modify "Payment Method Code"
        // [THEN] "Payment Method Code" has been validated and linked "Cartera Doc." record has been updated
        CustomerLedgerEntries.OpenEdit();
        CustomerLedgerEntries.GotoRecord(CustLedgerEntry);
        CustomerLedgerEntries."Payment Method Code".SetValue(PaymentMethod.Code);
        CustomerLedgerEntries.Close();

        // TODO: Uncomment LibraryLowerPermissions.SetOutsideO365Scope();
        CarteraDoc.Find();
        CarteraDoc.TestField("Payment Method Code", PaymentMethod.Code);
    end;

    [Test]
    [TestPermissions(TestPermissions::Restrictive)]
    procedure OpenBillGroupCanBeDeletedDirectlyUnderLocalPermissions()
    var
        BillGroup: Record "Bill Group";
    begin
        // [FEATURE] [Permissions]
        // [SCENARIO 404664] Open Bill Group can be directly deleted
        BillGroup.Init();
        BillGroup.Insert(true);

        LibraryLowerPermissions.SetLocal();
        BillGroup.Delete(true);
    end;

    [Test]
    [TestPermissions(TestPermissions::Restrictive)]
    procedure OpenPaymentOrderCanBeDeletedDirectlyUnderLocalPermissions()
    var
        PaymentOrder: Record "Payment Order";
    begin
        // [FEATURE] [Permissions]
        // [SCENARIO 404664] Open Payment Order can be directly deleted
        PaymentOrder.Init();
        PaymentOrder.Insert(true);

        LibraryLowerPermissions.SetLocal();
        PaymentOrder.Delete(true);
    end;

    [Test]
    procedure ReceivablesFactBoxShowingCorrValues()
    var
        ReceivablesCarteraDocs: TestPage "Receivables Cartera Docs";
        NoofDocuments: Integer;
        TotalAmount: Decimal;
        TotalAmountLCY: Decimal;
    begin
        // [SCENARIO 561864] Receivables cartera doc factbox are showing correct values of total number of documents and the total amount
        Initialize();

        // [GIVEN] Calculate NoofDocuments,TotalAmount,TotalAmountLCY from Receivables Doc Analysis Fact Box. 
        CalculateDocAnalysisFactBox(NoofDocuments, TotalAmount, TotalAmountLCY);

        // [WHEN] Open Page for Receivables Cartera Docs.
        ReceivablesCarteraDocs.OpenView();
        ReceivablesCarteraDocs.First();

        // [THEN] Verify BillCount,Total,TotalLCY from Receivables Cartera Doc Analysis Fact Box.
        ReceivablesCarteraDocs.Control1901421107.BillCount.AssertEquals(NoofDocuments);
        ReceivablesCarteraDocs.Control1901421107.Total.AssertEquals(TotalAmount);
        ReceivablesCarteraDocs.Control1901421107.TotalLCY.AssertEquals(TotalAmountLCY);
        ReceivablesCarteraDocs.Close();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateBillGroupWithBankAccount(var BillGroup: Record "Bill Group")
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, '');
        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection);
    end;

    local procedure MockCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CarteraDoc: Record "Cartera Doc.")
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry.Open := true;
        CustLedgerEntry."Document No." := CarteraDoc."Document No.";
        CustLedgerEntry."Customer No." := CarteraDoc."Account No.";
        CustLedgerEntry."Bill No." := CarteraDoc."No.";
        CustLedgerEntry.Insert();
    end;

    local procedure ModifyPermissionData(RoleID: Code[20]; ObjectID: Integer; NewReadPermission: Integer; NewInsertPermission: Integer; NewModifyPermission: Integer; NewDeletePermission: Integer)
    var
        Permission: Record Permission;
    begin
        Permission.Get(RoleID, Permission."Object Type"::"Table Data", ObjectID);
        Permission."Read Permission" := NewReadPermission;
        Permission."Insert Permission" := NewInsertPermission;
        Permission."Modify Permission" := NewModifyPermission;
        Permission."Delete Permission" := NewDeletePermission;
        Permission."Execute Permission" := Permission."Execute Permission"::" ";
        Permission.Modify();
    end;

    local procedure AddCommentLineFromList(BillGroupNo: Code[20])
    var
        BillGroupsList: TestPage "Bill Groups List";
    begin
        BillGroupsList.OpenEdit();
        BillGroupsList.GotoKey(BillGroupNo);
        BillGroupsList.Comments.Invoke();
    end;

    local procedure AddCommentLineFromCard(BillGroupNo: Code[20])
    var
        BillGroups: TestPage "Bill Groups";
    begin
        BillGroups.OpenEdit();
        BillGroups.GotoKey(BillGroupNo);
        BillGroups.Comments.Invoke();
    end;

    local procedure MockReceivableCarteraDoc(var CarteraDoc: Record "Cartera Doc.")
    begin
        CarteraDoc.Init();
        CarteraDoc.Type := CarteraDoc.Type::Receivable;
        CarteraDoc."Entry No." := LibraryUtility.GetNewRecNo(CarteraDoc, CarteraDoc.FieldNo("Entry No."));
        CarteraDoc."Document Type" := CarteraDoc."Document Type"::Bill;
        CarteraDoc."Document No." := LibraryUtility.GenerateGUID();
        CarteraDoc."Account No." := LibraryUtility.GenerateGUID();
        CarteraDoc."No." := LibraryUtility.GenerateGUID();
        CarteraDoc.Insert();
    end;

    local procedure MockPostedBillGroup(var PostedBillGroup: Record "Posted Bill Group")
    begin
        PostedBillGroup.Init();
        PostedBillGroup."No." :=
          LibraryUtility.GenerateRandomCode(PostedBillGroup.FieldNo("No."), DATABASE::"Posted Bill Group");
        PostedBillGroup.Insert();
    end;

    local procedure CalculateDocAnalysisFactBox(var NoofDocuments: Integer; var TotalAmount: Decimal; var TotalAmountLCY: Decimal)
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        NoofDocuments := CarteraDoc.Count;
        CarteraDoc.CalcSums("Remaining Amount", "Remaining Amt. (LCY)");
        TotalAmount := CarteraDoc."Remaining Amount";
        TotalAmountLCY := CarteraDoc."Remaining Amt. (LCY)";
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BGCommentSheetPageHandler(var BGCommentSheet: TestPage "BG/PO Comment Sheet")
    var
        Comment: Text[80];
    begin
        Comment := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(Comment);

        BGCommentSheet.New();
        BGCommentSheet.Date.SetValue(WorkDate());
        BGCommentSheet.Comment.SetValue(Comment);
        BGCommentSheet.OK().Invoke();
    end;
}

