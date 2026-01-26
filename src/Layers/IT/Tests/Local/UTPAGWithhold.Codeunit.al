codeunit 144094 "UT PAG Withhold"
{
    // Test for feature - WITHHOLD - Withholding Tax.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        RecalculateMsg: Label 'Please recalculate %1 and %2 from the Withholding - INPS.';
        MessageMustSameMsg: Label 'Message must be same.';
        ValueMustExistMsg: Label '%1 must exist.';
        TestValidationErr: Label 'TestValidation';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAmountToPaySubformSentVendorBillLines()
    var
        SubformSentVendorBillLines: TestPage "Subform Sent Vendor Bill Lines";
    begin
        // Purpose of the test is to validate Amount to Pay - OnValidate of Page - 12102 Subform Sent Vendor Bill Lines.

        // Setup: Create Vendor Bill Line and open Page - Subform Sent Vendor Bill Lines.
        Initialize();
        SubformSentVendorBillLines.OpenEdit();
        SubformSentVendorBillLines.FILTER.SetFilter("Vendor No.", CreateVendorBillLine());

        // Exercise & Verify: Verify expected message in handler - MessageHandler.
        SubformSentVendorBillLines."Amount to Pay".SetValue(LibraryRandom.RandDec(10, 2));
        SubformSentVendorBillLines.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertRecordContributionCodeLines()
    var
        ContributionCodeLine: Record "Contribution Code Line";
        ContributionCode: TestPage "Contribution Codes-INPS";
        ContributionCodeLines: TestPage "Contribution Code Lines";
    begin
        // Purpose of the test is to validate OnInsertRecord Trigger of Page - 12107 Contribution Code Lines.

        // Setup: Open Page Contribution Code Lines from Page Contribution Code.
        Initialize();
        ContributionCode.OpenNew();
        ContributionCode.Code.SetValue(LibraryUTUtility.GetNewCode());
        ContributionCodeLines.Trap();
        ContributionCode."Soc. Sec. Code Lines".Invoke();

        // Exercise.
        ContributionCodeLines."Starting Date".SetValue(WorkDate());

        // Verify: Verify Table - Contribution Code Line exists.
        ContributionCodeLine.SetRange(Code, Format(ContributionCode.Code));
        ContributionCodeLines.Close();
        Assert.IsTrue(ContributionCodeLine.FindFirst(), StrSubstNo(ValueMustExistMsg, ContributionCodeLine.TableCaption()));
        ContributionCode.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NavigateWithholdingTaxCard()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxCard: TestPage "Withholding Tax Card";
        Navigate: TestPage Navigate;
    begin
        // Purpose of the test is to validate Navigate Action of Page - 12112 Withholding Tax Card.

        // Setup: Open Page Withholding Tax Card.
        Initialize();
        WithholdingTaxCard.OpenEdit();
        WithholdingTaxCard.FILTER.SetFilter("Document No.", CreateWithholdingTax());
        WithholdingTaxCard."Vendor No.".SetValue('');  // Blank value of Vendor.
        Navigate.Trap();

        // Exercise.
        WithholdingTaxCard.Navigate.Invoke();

        // Verify: Verify Withholding Tax - Table Name and Number of Records on page - Navigate.
        WithholdingTax.SetRange("Document No.", Format(WithholdingTaxCard."Document No."));
        VerifyTableNameAndNumberOfRecords(Navigate, WithholdingTax.TableCaption(), WithholdingTax.Count);
        WithholdingTaxCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NavigateWithholdingTaxList()
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxList: TestPage "Withholding Tax List";
        Navigate: TestPage Navigate;
    begin
        // Purpose of the test is to validate Navigate Action of Page - 12113 Withholding Tax List.

        // Setup: Open Page Withholding Tax List.
        Initialize();
        WithholdingTaxList.OpenEdit();
        WithholdingTaxList.FILTER.SetFilter("Document No.", CreateWithholdingTax());
        Navigate.Trap();

        // Exercise.
        WithholdingTaxList.Navigate.Invoke();

        // Verify: Verify Withholding Tax - Table Name and Number of Records on page - Navigate.
        WithholdingTax.SetRange("Document No.", Format(WithholdingTaxList."Document No."));
        VerifyTableNameAndNumberOfRecords(Navigate, WithholdingTax.TableCaption(), WithholdingTax.Count);
        WithholdingTaxList.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NavigateContributionCard()
    var
        Contributions: Record Contributions;
        ContributionCard: TestPage "Contribution Card";
        Navigate: TestPage Navigate;
    begin
        // Purpose of the test is to validate Navigate Action of Page - 12114 Contribution Card.

        // Setup: Open Page Contribution Card.
        Initialize();
        OpenContributionCard(ContributionCard);
        ContributionCard."Vendor No.".SetValue('');  // Blank value of Vendor.
        Navigate.Trap();

        // Exercise.
        ContributionCard.Navigate.Invoke();

        // Verify: Verify Contributions - Table Name and Number of Records on page - Navigate.
        Contributions.SetRange("Document No.", Format(ContributionCard."Document No."));
        VerifyTableNameAndNumberOfRecords(Navigate, Contributions.TableCaption(), Contributions.Count);
        ContributionCard.Close();
    end;

    [Test]
    [HandlerFunctions('ContributionListModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ListINPSContributionCard()
    var
        ContributionCard: TestPage "Contribution Card";
    begin
        // Purpose of the test is to validate ListINPS Action of Page - 12114 Contribution Card.

        // Setup: Open Page Contribution Card.
        OpenContributionCard(ContributionCard);
        EnqueueSocialSecurityCodeAndINAILCode(Format(ContributionCard."Social Security Code"), Format(ContributionCard."INAIL Code"));

        // Exercise & Verify: Verify Social Security Code and INAIL Code on handler - ContributionListModalPageHandler.
        ContributionCard.ListINPS.Invoke();
    end;

    [Test]
    [HandlerFunctions('ContributionListModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ListINAILContributionCard()
    var
        ContributionCard: TestPage "Contribution Card";
    begin
        // Purpose of the test is to validate ListINAIL Action of Page - 12114 Contribution Card.

        // Setup: Open Page Contribution Card.
        Initialize();
        OpenContributionCard(ContributionCard);
        EnqueueSocialSecurityCodeAndINAILCode(Format(ContributionCard."Social Security Code"), Format(ContributionCard."INAIL Code"));

        // Exercise & Verify: Verify Social Security Code and INAIL Code on handler - ContributionListModalPageHandler.
        ContributionCard.ListINAIL.Invoke();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NavigateContributionList()
    var
        Contributions: Record Contributions;
        ContributionList: TestPage "Contribution List";
        Navigate: TestPage Navigate;
    begin
        // Purpose of the test is to validate Navigate Action of Page - 12115 Contribution List.

        // Setup: Open Page Contribution List.
        ContributionList.OpenEdit();
        ContributionList.FILTER.SetFilter("Document No.", CreateContributions());
        Navigate.Trap();

        // Exercise.
        ContributionList.Navigate.Invoke();

        // Verify: Verify Contributions - Table Name and Number of Records on page - Navigate.
        Contributions.SetRange("Document No.", Format(ContributionList."Document No."));
        VerifyTableNameAndNumberOfRecords(Navigate, Contributions.TableCaption(), Contributions.Count);
        ContributionList.Close();
    end;

    [Test]
    [HandlerFunctions('INPSContributionListPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnOpenPageINPSContributionList()
    var
        Contributions: Record Contributions;
        INPSContributionList: Page "INPS Contribution List";
    begin
        // Purpose of the test is to validate Navigate Action of Page - 35492 INPS Contribution List.

        // Setup: Open Page INPS Contribution List.
        Initialize();
        FilterOnContributions(Contributions);
        INPSContributionList.SetTableView(Contributions);
        LibraryVariableStorage.Enqueue(Contributions."Social Security Code");
        LibraryVariableStorage.Enqueue(Contributions."INAIL Code");

        // Exercise & Verify: Verify Contributions - Social Security Code and INAIL Code on handler - INPSContributionListPageHandler.
        INPSContributionList.Run();
    end;

    [Test]
    [HandlerFunctions('INAILContributionListPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnOpenPageINAILContributionList()
    var
        Contributions: Record Contributions;
        INAILContributionList: Page "INAIL Contribution List";
    begin
        // Purpose of the test is to validate OnOpenPage Trigger of Page - 35493 INAIL Contribution List.

        // Setup: Open Page INAIL Contribution List.
        FilterOnContributions(Contributions);
        INAILContributionList.SetTableView(Contributions);
        LibraryVariableStorage.Enqueue(Contributions."Social Security Code");
        LibraryVariableStorage.Enqueue(Contributions."INAIL Code");

        // Exercise: Verify Contributions - Social Security Code and INAIL Code on handler - INAILContributionListPageHandler.
        INAILContributionList.Run();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateINAILNonTaxAmtWithhTaxesContributionCardError()
    var
        PurchWithhContribution: Record "Purch. Withh. Contribution";
        WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card";
    begin
        // Purpose of the test is to validate INAIL Non Taxable Amount - OnValidate trigger of Page ID - 12133  Withh. Taxes-Contribution Card.

        // Setup: Create Purchase with Contribution.
        Initialize();
        CreatePurchWithhContribution(PurchWithhContribution, CreatePurchaseHeader());
        WithhTaxesContributionCard.OpenEdit();
        WithhTaxesContributionCard.GotoRecord(PurchWithhContribution);
        WithhTaxesContributionCard."INAIL Contribution Base".SetValue(-LibraryRandom.RandDec(10, 2));

        // Exercise.
        asserterror WithhTaxesContributionCard."INAIL Non Taxable Amount".SetValue(LibraryRandom.RandDec(10, 2));

        // Verify: Verify Expected error Code, Actual error: INAIL Non Taxable Amount,  Message = 'INAIL Gross Amount must be greater than INAIL Non Taxable Amount.
        Assert.ExpectedErrorCode(TestValidationErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalculateWithhTaxesContributionCard()
    var
        PurchaseLine: Record "Purchase Line";
        PurchWithhContribution: Record "Purch. Withh. Contribution";
        WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card";
    begin
        // Purpose of the test is to validate Calculate - OnAction Trigger of Page ID - 12133  Withh. Taxes-Contribution Card.

        // Setup: Create Purchase With Contribution.
        Initialize();
        CreatePurchaseLine(PurchaseLine);
        CreatePurchWithhContribution(PurchWithhContribution, PurchaseLine."Document No.");
        CreateWithholdCodeLine(PurchWithhContribution."Withholding Tax Code");
        WithhTaxesContributionCard.OpenEdit();
        WithhTaxesContributionCard.GotoRecord(PurchWithhContribution);

        // Exercise.
        WithhTaxesContributionCard.Calculate.Invoke();

        // Verify: Verify Total Amount is updated as Purchase Line - Line Amount on Withh. Taxes-Contribution Card.
        WithhTaxesContributionCard.TotalAmount.AssertEquals(PurchaseLine."VAT Base Amount");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NavigateComputedContribution()
    var
        ComputedContribution: Record "Computed Contribution";
        ComputedContributionPage: TestPage "Computed Contribution";
        Navigate: TestPage Navigate;
        DocumentNo: Code[20];
    begin
        // Purpose of the test is to validate Navigate - OnAction Trigger of Page ID - 12136 Computed Contribution.

        // Setup: Open Page Computed Contribution.
        Initialize();
        DocumentNo := CreateComputedContribution();
        ComputedContributionPage.OpenEdit();
        ComputedContributionPage.FILTER.SetFilter("Document No.", DocumentNo);
        Navigate.Trap();

        // Exercise.
        ComputedContributionPage.Navigate.Invoke();

        // Verify: Verify Computed Contribution - Table Name and Number of Records on page - Navigate.
        ComputedContribution.SetRange("Document No.", DocumentNo);
        VerifyTableNameAndNumberOfRecords(Navigate, ComputedContribution.TableCaption(), ComputedContribution.Count);
        ComputedContributionPage.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NavigateComputedWithholdingTax()
    var
        ComputedWithholdingTax: Record "Computed Withholding Tax";
        ComputedWithholdingTaxPage: TestPage "Computed Withholding Tax";
        Navigate: TestPage Navigate;
        DocumentNo: Code[20];
    begin
        // Purpose of the test is to validate Navigate - OnAction Trigger of Page ID - 12135 Computed Withholding Tax.

        // Setup: Open Page Computed Withholding Tax.
        Initialize();
        DocumentNo := CreateComputedWithholdingTax();
        ComputedWithholdingTaxPage.OpenEdit();
        ComputedWithholdingTaxPage.FILTER.SetFilter("Document No.", DocumentNo);
        Navigate.Trap();

        // Exercise:
        ComputedWithholdingTaxPage.Navigate.Invoke();

        // Verify: Verify Computed Withholding Tax - Table Name and Number of Records on page - Navigate.
        ComputedWithholdingTax.SetRange("Document No.", DocumentNo);
        VerifyTableNameAndNumberOfRecords(Navigate, ComputedWithholdingTax.TableCaption(), ComputedWithholdingTax.Count);
        ComputedWithholdingTaxPage.Close();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreatePurchaseHeader(): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Buy-from Vendor No." := CreateVendor();
        PurchaseHeader.Insert();
        exit(PurchaseHeader."No.");
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Order;
        PurchaseLine."Document No." := CreatePurchaseHeader();
        PurchaseLine.Type := PurchaseLine.Type::"G/L Account";
        PurchaseLine."VAT Base Amount" := LibraryRandom.RandDec(10, 2);
        PurchaseLine.Insert();
    end;

    local procedure CreateContributions(): Code[20]
    var
        Contributions: Record Contributions;
        Contributions2: Record Contributions;
        ContributionCode: Record "Contribution Code";
    begin
        Contributions."Entry No." := 1;
        if Contributions2.FindLast() then
            Contributions."Entry No." := Contributions2."Entry No." + 1;
        Contributions."Social Security Code" := CreateContributionCode(ContributionCode."Contribution Type"::INPS);
        Contributions."INAIL Code" := CreateContributionCode(ContributionCode."Contribution Type"::INAIL);
        Contributions."Document No." := LibraryUTUtility.GetNewCode();
        Contributions."Posting Date" := WorkDate();
        Contributions.Insert();
        exit(Contributions."Document No.");
    end;

    local procedure CreateContributionCode(ContributionType: Option): Code[20]
    var
        ContributionCode: Record "Contribution Code";
    begin
        ContributionCode.Code := LibraryUTUtility.GetNewCode();
        ContributionCode."Contribution Type" := ContributionType;
        ContributionCode.Insert();
        exit(ContributionCode.Code);
    end;

    local procedure CreatePurchWithhContribution(var PurchWithhContribution: Record "Purch. Withh. Contribution"; No: Code[20])
    begin
        PurchWithhContribution."Document Type" := PurchWithhContribution."Document Type"::Order;
        PurchWithhContribution."No." := No;
        PurchWithhContribution."Withholding Tax Code" := LibraryUTUtility.GetNewCode();
        PurchWithhContribution.Insert();
    end;

    local procedure CreateWithholdCodeLine(WithholdCode: Code[20])
    var
        WithholdCodeLine: Record "Withhold Code Line";
    begin
        WithholdCodeLine."Withhold Code" := WithholdCode;
        WithholdCodeLine."Starting Date" := WorkDate();
        WithholdCodeLine.Insert();
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateVendorBillLine(): Code[20]
    var
        VendorBillLine: Record "Vendor Bill Line";
    begin
        VendorBillLine."Vendor Bill List No." := LibraryUTUtility.GetNewCode();
        VendorBillLine."Vendor No." := CreateVendor();
        VendorBillLine."Withholding Tax Amount" := LibraryRandom.RandDec(10, 2);
        VendorBillLine."Remaining Amount" := LibraryRandom.RandDecInRange(10, 50, 2); // Remaining Amount  should be greater than - Amount to Pay.
        VendorBillLine.Insert();
        exit(VendorBillLine."Vendor No.");
    end;

    local procedure CreateWithholdingTax(): Code[20]
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTax2: Record "Withholding Tax";
    begin
        WithholdingTax."Entry No." := 1;
        if WithholdingTax2.FindLast() then
            WithholdingTax."Entry No." := WithholdingTax2."Entry No." + 1;
        WithholdingTax."Document No." := LibraryUTUtility.GetNewCode();
        WithholdingTax."Posting Date" := WorkDate();
        WithholdingTax.Insert();
        exit(WithholdingTax."Document No.");
    end;

    local procedure CreateComputedWithholdingTax(): Code[20]
    var
        ComputedWithholdingTax: Record "Computed Withholding Tax";
    begin
        ComputedWithholdingTax."Vendor No." := LibraryUTUtility.GetNewCode();
        ComputedWithholdingTax."Document Date" := WorkDate();
        ComputedWithholdingTax."Document No." := LibraryUTUtility.GetNewCode();
        ComputedWithholdingTax."Posting Date" := WorkDate();
        ComputedWithholdingTax.Insert();
        exit(ComputedWithholdingTax."Document No.");
    end;

    local procedure CreateComputedContribution(): Code[20]
    var
        ComputedContribution: Record "Computed Contribution";
    begin
        ComputedContribution."Vendor No." := LibraryUTUtility.GetNewCode();
        ComputedContribution."Document Date" := WorkDate();
        ComputedContribution."Document No." := LibraryUTUtility.GetNewCode();
        ComputedContribution."Posting Date" := WorkDate();
        ComputedContribution.Insert();
        exit(ComputedContribution."Document No.");
    end;

    local procedure EnqueueSocialSecurityCodeAndINAILCode(SocialSecurityCode: Code[20]; INAILCode: Code[20])
    begin
        LibraryVariableStorage.Enqueue(SocialSecurityCode);
        LibraryVariableStorage.Enqueue(INAILCode);
    end;

    local procedure FilterOnContributions(var Contributions: Record Contributions)
    begin
        Contributions.SetRange("Document No.", CreateContributions());
        Contributions.SetFilter("Social Security Code", '<>%1', '');
        Contributions.SetFilter("INAIL Code", '<>%1', '');
        Contributions.FindFirst();
    end;

    local procedure OpenContributionCard(var ContributionCard: TestPage "Contribution Card")
    begin
        ContributionCard.OpenEdit();
        ContributionCard.FILTER.SetFilter("Document No.", CreateContributions());
    end;

    local procedure VerifyTableNameAndNumberOfRecords(Navigate: TestPage Navigate; TableName: Text[50]; NoOfRecords: Integer)
    begin
        Navigate."Table Name".AssertEquals(TableName);
        Navigate."No. of Records".AssertEquals(NoOfRecords);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContributionListModalPageHandler(var ContributionList: TestPage "Contribution List")
    var
        INAILCode: Variant;
        SocialSecurityCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(SocialSecurityCode);
        LibraryVariableStorage.Dequeue(INAILCode);
        ContributionList."Social Security Code".AssertEquals(SocialSecurityCode);
        ContributionList."INAIL Code".AssertEquals(INAILCode);
        ContributionList.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure INPSContributionListPageHandler(var INPSContributionList: TestPage "INPS Contribution List")
    var
        SocialSecurityCode: Variant;
        INAILCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(SocialSecurityCode);
        LibraryVariableStorage.Dequeue(INAILCode);
        INPSContributionList."Social Security Code".AssertEquals(SocialSecurityCode);
        INPSContributionList."INAIL Code".AssertEquals(INAILCode);
        INPSContributionList.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure INAILContributionListPageHandler(var INAILContributionList: TestPage "INAIL Contribution List")
    var
        SocialSecurityCode: Variant;
        INAILCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(SocialSecurityCode);
        LibraryVariableStorage.Dequeue(INAILCode);
        INAILContributionList."Social Security Code".AssertEquals(SocialSecurityCode);
        INAILContributionList."INAIL Code".AssertEquals(INAILCode);
        INAILContributionList.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        VendorBillLine: Record "Vendor Bill Line";
    begin
        Assert.AreEqual(
          Message, StrSubstNo(RecalculateMsg, VendorBillLine.FieldCaption("Withholding Tax Amount"),
            VendorBillLine.FieldCaption("Social Security Amount")), MessageMustSameMsg);
    end;
}

