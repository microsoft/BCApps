codeunit 132523 "Discount Setup Notifications"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Discount] [Notification]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        MissingDiscountAccountMsg: Label 'G/L accounts for discounts are missing on one or more lines on the General Posting Setup page.';

    [Test]
    [HandlerFunctions('SendNotificationActionHandler')]
    [Scope('OnPrem')]
    procedure T100_NotifyAboutMissingSalesSetupOnDiscountPostingValidation()
    var
        GeneralPostingSetup: array[2] of Record "General Posting Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetupPage: TestPage "General Posting Setup";
    begin
        // [FEATURE] [Sales] [Setup] [UI]
        // [SCENARIO] Notification is shown about gen. posting setup where discount accounts are missed If "Discount Posting" changed to not "All Discounts"
        Initialize();
        // [GIVEN] Gen. Posting Setup 'A' where "Sales Inv. Disc. Account" is blank
        // [GIVEN] Gen. Posting Setup 'B' where "Sales Line Disc. Account" is blank
        CreateGeneralPostingSetups(
          GeneralPostingSetup,
          GeneralPostingSetup[1].FieldNo("Sales Inv. Disc. Account"),
          GeneralPostingSetup[1].FieldNo("Sales Line Disc. Account"));
        // [GIVEN] Admin user changes "Discount Posting" from "No Discounts" to 'All Discounts'
        GeneralPostingSetupPage.Trap();
        LibrarySales.SetDiscountPosting(SalesSetup."Discount Posting"::"All Discounts");

        // [WHEN] Notification: "G/L accounts for discounts are missing... | Open page |" and user click on 'Open page'
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'sent notification message');

        // [THEN] Gen. Posting Setup page is open, where are 2 records: A' and 'B'.
        Assert.IsTrue(GeneralPostingSetupPage.First(), 'missing the 1st line');
        GeneralPostingSetupPage."Gen. Bus. Posting Group".AssertEquals(GeneralPostingSetup[1]."Gen. Bus. Posting Group");
        GeneralPostingSetupPage."Gen. Prod. Posting Group".AssertEquals(GeneralPostingSetup[1]."Gen. Prod. Posting Group");
        Assert.IsTrue(GeneralPostingSetupPage.Next(), 'missing the 2nd line');
        GeneralPostingSetupPage."Gen. Bus. Posting Group".AssertEquals(GeneralPostingSetup[2]."Gen. Bus. Posting Group");
        GeneralPostingSetupPage."Gen. Prod. Posting Group".AssertEquals(GeneralPostingSetup[2]."Gen. Prod. Posting Group");
        Assert.IsTrue(GeneralPostingSetupPage.Next(), 'not expected the 3rd line');
        GeneralPostingSetupPage.Close();

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationSimpleHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T101_RecallNotificationOnChangingSalesDiscountPosting()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Sales] [Setup]
        // [SCENARIO] Notification is recalled and shown again if "Discount Posting" is changed so there are missing accounts
        Initialize();
        // [GIVEN] Shown the notification due to missing "Purch. Inv. Disc. Account"
        ShowSalesNotificationForDiscountPosting(SalesSetup."Discount Posting"::"Invoice Discounts");
        // [GIVEN] Gen. Posting Setup 'B' where "Sales Line Disc. Account" is blank
        CreateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup.FieldNo("Sales Line Disc. Account"));

        // [WHEN] Admin user changes "Discount Posting" from "Invoice Discounts" to 'Line Discounts'
        LibrarySales.SetDiscountPosting(SalesSetup."Discount Posting"::"Line Discounts");

        // [THEN] Notification is recalled and
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'recall #1 notification message');
        // [THEN] Notification: "G/L accounts for discounts are missing... | Open page |"
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'notification #2 message');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'recall #2 notification message');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationSimpleHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T102_RecallNotificationOnChangingSalesDiscountPostingNoMissingAcc()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Sales] [Setup]
        // [SCENARIO] Notification is recalled if "Discount Posting" is changed so there are no missing accounts
        Initialize();
        // [GIVEN] Shown the notification due to missing "Purch. Inv. Disc. Account"
        ShowSalesNotificationForDiscountPosting(SalesSetup."Discount Posting"::"Invoice Discounts");

        // [WHEN] Admin user changes "Discount Posting" from "Invoice Discounts" to 'Line Discounts'
        LibrarySales.SetDiscountPosting(SalesSetup."Discount Posting"::"Line Discounts");

        // [THEN] Notification is recalled and no new notification shown
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'recall #1 notification message');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationSimpleHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T103_RecallNotificationOnChangingSalesDiscountPostingToNoDiscount()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Sales] [Setup]
        // [SCENARIO] Notification is recalled if "Discount Posting" is changed to "No Discounts"
        Initialize();
        // [GIVEN] Shown the notification due to missing "Purch. Inv. Disc. Account"
        ShowSalesNotificationForDiscountPosting(SalesSetup."Discount Posting"::"Invoice Discounts");

        // [WHEN] Admin user changes "Discount Posting" from "Invoice Discounts" to 'No Discounts'
        LibrarySales.SetDiscountPosting(SalesSetup."Discount Posting"::"No Discounts");

        // [THEN] Notification is recalled and no new notification shown
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'recall #1 notification message');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationActionHandler')]
    [Scope('OnPrem')]
    procedure T110_NotifyAboutMissingSalesLineSetupOnDiscountPostingValidation()
    var
        GeneralPostingSetup: array[2] of Record "General Posting Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetupPage: TestPage "General Posting Setup";
    begin
        // [FEATURE] [Sales] [Setup] [UI]
        // [SCENARIO] Notification is shown about gen. posting setup where line discount accounts are missed If "Discount Posting" changed to "Line Discounts"
        Initialize();
        // [GIVEN] Gen. Posting Setup 'A' where "Sales Inv. Disc. Account" is blank
        // [GIVEN] Gen. Posting Setup 'B' where "Sales Line Disc. Account" is blank
        CreateGeneralPostingSetups(
          GeneralPostingSetup,
          GeneralPostingSetup[1].FieldNo("Sales Inv. Disc. Account"),
          GeneralPostingSetup[2].FieldNo("Sales Line Disc. Account"));
        // [GIVEN] Admin user changes "Discount Posting" from "No Discounts" to 'Line Discounts'
        GeneralPostingSetupPage.Trap();
        LibrarySales.SetDiscountPosting(SalesSetup."Discount Posting"::"Line Discounts");

        // [WHEN] Notification: "G/L accounts for discounts are missing... | Open page |" and user click on 'Open page'
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'sent notification message');

        // [THEN] Gen. Posting Setup page is open, where is one record 'B'.
        VerifyGenPostingSetupInPage(GeneralPostingSetupPage, GeneralPostingSetup[2]);

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationActionHandler')]
    [Scope('OnPrem')]
    procedure T111_NotifyAboutMissingSalesInvSetupOnDiscountPostingValidation()
    var
        GeneralPostingSetup: array[2] of Record "General Posting Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetupPage: TestPage "General Posting Setup";
    begin
        // [FEATURE] [Sales] [Setup] [UI]
        // [SCENARIO] Notification is shown about gen. posting setup where invoice discount accounts are missed If "Discount Posting" changed to "Invoice Discounts"
        Initialize();
        // [GIVEN] Gen. Posting Setup 'A' where "Sales Inv. Disc. Account" is blank
        // [GIVEN] Gen. Posting Setup 'B' where "Sales Line Disc. Account" is blank
        CreateGeneralPostingSetups(
          GeneralPostingSetup,
          GeneralPostingSetup[1].FieldNo("Sales Inv. Disc. Account"),
          GeneralPostingSetup[2].FieldNo("Sales Line Disc. Account"));
        // [GIVEN] Admin user changes "Discount Posting" from "No Discounts" to 'Invoice Discounts'
        GeneralPostingSetupPage.Trap();
        LibrarySales.SetDiscountPosting(SalesSetup."Discount Posting"::"Invoice Discounts");

        // [WHEN] Notification: "G/L accounts for discounts are missing... | Open page |" and user click on 'Open page'
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'sent notification message');

        // [THEN] Gen. Posting Setup page is open, where is one record 'A'.
        VerifyGenPostingSetupInPage(GeneralPostingSetupPage, GeneralPostingSetup[1]);

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationActionHandler')]
    [Scope('OnPrem')]
    procedure T120_NotifyAboutMissingSalesSetupOnLineDiscountValidation()
    var
        GeneralPostingSetup: array[2] of Record "General Posting Setup";
        SalesLine: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetupPage: TestPage "General Posting Setup";
        SalesInvoicePage: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UI]
        // [SCENARIO] User enters a line discount while there is the posting setup, where line discount account is blank
        Initialize();
        // [GIVEN] Sales Setup, where "Discount Posting" is 'Line Discounts'
        DefineAllDiscountAccounts();
        LibrarySales.SetDiscountPosting(SalesSetup."Discount Posting"::"Line Discounts");
        // [GIVEN] Created the Order and one item line, where the posting setup is 'A'
        CreateSalesInvoiceWithOneLine(SalesLine);
        // [GIVEN] Gen. Posting Setup record 'A', where "Sales Line Disc. Account" is blank, "Gen. Bus. Posting Group" is 'X'
        BlankSalesDiscAccount(GeneralPostingSetup[1], SalesLine, GeneralPostingSetup[1].FieldNo("Sales Line Disc. Account"));
        // [GIVEN] Gen. Posting Setup record 'B', where "Sales Line Disc. Account" is blank, "Gen. Bus. Posting Group" is 'Y'
        GeneralPostingSetup[2] := GeneralPostingSetup[1];
        GeneralPostingSetup[2]."Gen. Bus. Posting Group" := LibraryUtility.GenerateGUID();
        GeneralPostingSetup[2].Insert();
        // [GIVEN] Entered new "Line Discount %" = 10
        GeneralPostingSetupPage.Trap();
        SalesInvoicePage.OpenEdit();
        SalesInvoicePage.FILTER.SetFilter("No.", SalesLine."Document No.");
        SalesInvoicePage.SalesLines."Line Discount %".Value('10');

        // [WHEN] Notification: "G/L accounts for discounts are missing... | Open page |" and user click on 'Open page'
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'sent notification message');

        // [THEN] Gen. Posting Setup page is open, where is one record 'A'.
        VerifyGenPostingSetupInPage(GeneralPostingSetupPage, GeneralPostingSetup[1]);
        // [THEN] "Line Discount %" is 10
        SalesInvoicePage.SalesLines."Line Discount %".AssertEquals('10');

        GeneralPostingSetup[2].Delete();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationSimpleHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T121_RecallNotificationOnSalesLineDiscountPctValidation()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesLine: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";
        SalesInvoicePage: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UI]
        // [SCENARIO] User enters the blank "Line Discount %" while the notification is shown
        Initialize();
        // [GIVEN] Sales Setup, where "Discount Posting" is 'Line Discounts'
        DefineAllDiscountAccounts();
        LibrarySales.SetDiscountPosting(SalesSetup."Discount Posting"::"Line Discounts");
        // [GIVEN] Created the Order and one item line, where the posting setup is 'A'.
        CreateSalesInvoiceWithOneLine(SalesLine);
        // [GIVEN] Gen. Posting Setup record 'A', where "Sales Line Disc. Account" is blank.
        BlankSalesDiscAccount(GeneralPostingSetup, SalesLine, GeneralPostingSetup.FieldNo("Sales Line Disc. Account"));
        // [GIVEN] Entered new "Line Discount %" = 10
        SalesInvoicePage.OpenEdit();
        SalesInvoicePage.FILTER.SetFilter("No.", SalesLine."Document No.");
        SalesInvoicePage.SalesLines."Line Discount %".Value('10');
        // [GIVEN] Notification: "G/L accounts for discounts are missing... | Open page |"
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'sent notification message');

        // [WHEN] Entered new "Line Discount %" = 0
        SalesInvoicePage.SalesLines."Line Discount %".Value('0');

        // [THEN] Notification is recalled, no new notification shown.
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'recall notification message');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationSimpleHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T122_RecallNotificationOnSalesLineDiscountAmtValidation()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesLine: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";
        SalesInvoicePage: TestPage "Sales Invoice";
        LineAmt: Decimal;
    begin
        // [FEATURE] [Sales] [Invoice] [UI]
        // [SCENARIO] User restores the "Line Amount" that caused the line discount, while the notification is shown
        Initialize();
        // [GIVEN] Sales Setup, where "Discount Posting" is 'Line Discounts'
        DefineAllDiscountAccounts();
        LibrarySales.SetDiscountPosting(SalesSetup."Discount Posting"::"Line Discounts");
        // [GIVEN] Created the Order and one item line, where the posting setup is 'A'.
        CreateSalesInvoiceWithOneLine(SalesLine);
        // [GIVEN] Gen. Posting Setup record 'A', where "Sales Line Disc. Account" is blank.
        BlankSalesDiscAccount(GeneralPostingSetup, SalesLine, GeneralPostingSetup.FieldNo("Sales Line Disc. Account"));
        // [GIVEN] Entered new "Line Discount Amount" = 1
        SalesInvoicePage.OpenEdit();
        SalesInvoicePage.FILTER.SetFilter("No.", SalesLine."Document No.");
        LineAmt := SalesInvoicePage.SalesLines."Line Amount".AsDecimal();
        SalesInvoicePage.SalesLines."Line Amount".Value(Format(LineAmt - 1));
        // [GIVEN] Notification: "G/L accounts for discounts are missing... | Open page |"
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'sent notification message');

        // [WHEN] Entered new "Line Discount Amount" = 0
        SalesInvoicePage.SalesLines."Line Amount".Value(Format(LineAmt));

        // [THEN] Notification is recalled, no new notification shown.
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'recall notification message');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationSimpleHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T123_RecallNotificationOnSalesLineDiscountAmtValidationIfNoDiscounts()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesLine: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";
        SalesInvoicePage: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UI]
        // [SCENARIO] User enters new "Line Discount %" while the "Discount Posting" is "No Discounts"
        Initialize();
        // [GIVEN] Sales Setup, where "Discount Posting" is 'Line Discounts'
        DefineAllDiscountAccounts();
        LibrarySales.SetDiscountPosting(SalesSetup."Discount Posting"::"Line Discounts");
        // [GIVEN] Created the Order and one item line, where the posting setup is 'A'.
        CreateSalesInvoiceWithOneLine(SalesLine);
        // [GIVEN] Gen. Posting Setup record 'A', where "Sales Line Disc. Account" is blank.
        BlankSalesDiscAccount(GeneralPostingSetup, SalesLine, GeneralPostingSetup.FieldNo("Sales Line Disc. Account"));
        // [GIVEN] Entered new "Line Discount %" = 10
        SalesInvoicePage.OpenEdit();
        SalesInvoicePage.FILTER.SetFilter("No.", SalesLine."Document No.");
        SalesInvoicePage.SalesLines."Line Discount %".Value('10');
        // [GIVEN] Notification: "G/L accounts for discounts are missing... | Open page |"
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'sent notification message');
        // [GIVEN] Sales Setup, where "Discount Posting" is 'No Discounts'
        SalesSetup.Get();
        SalesSetup."Discount Posting" := SalesSetup."Discount Posting"::"No Discounts";
        SalesSetup.Modify();

        // [WHEN] Entered new "Line Discount %" = 20
        SalesInvoicePage.SalesLines."Line Discount %".Value('20');

        // [THEN] Notification is recalled, no new notification shown.
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'recall notification message');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T124_DontNotifyAboutMissingSalesSetupOnLineDiscValidationInTrigger()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesLine: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO] Notification is not shown if "Line Discount %" validated through code, not on the page.
        Initialize();
        // [GIVEN] Sales Setup, where "Discount Posting" is 'Line Discounts'
        DefineAllDiscountAccounts();
        LibrarySales.SetDiscountPosting(SalesSetup."Discount Posting"::"Line Discounts");
        // [GIVEN] Created the Order and one item line, where the posting setup is 'A'.
        CreateSalesInvoiceWithOneLine(SalesLine);
        // [GIVEN] Gen. Posting Setup record 'A', where "Sales Line Disc. Account" is blank.
        BlankSalesDiscAccount(GeneralPostingSetup, SalesLine, GeneralPostingSetup.FieldNo("Sales Line Disc. Account"));

        // [WHEN] Validate "Line Discount %" = 10
        SalesLine.Validate("Line Discount %", 10);
        SalesLine.Modify();

        // [THEN] "Line Discount %" is 10
        SalesLine.TestField("Line Discount %", 10);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationActionHandler')]
    [Scope('OnPrem')]
    procedure T130_NotifyAboutMissingSalesSetupOnInvDiscountValidation()
    var
        GeneralPostingSetup: array[2] of Record "General Posting Setup";
        SalesLine: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetupPage: TestPage "General Posting Setup";
        SalesInvoicePage: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UI]
        // [SCENARIO] User enters a invoice discount for the posting setup where invoice discount account is blank
        Initialize();
        // [GIVEN] Sales Setup, where "Discount Posting" is 'Invoice Discounts'
        DefineAllDiscountAccounts();
        LibrarySales.SetDiscountPosting(SalesSetup."Discount Posting"::"Invoice Discounts");
        // [GIVEN] Created the Order and one item line, where the posting setup is 'A'.
        CreateSalesInvoiceWithOneLine(SalesLine);
        // [GIVEN] Gen. Posting Setup record 'A', where "Sales Inv. Disc. Account" is blank, "Gen. Bus. Posting Group" is 'X'
        BlankSalesDiscAccount(GeneralPostingSetup[1], SalesLine, GeneralPostingSetup[1].FieldNo("Sales Inv. Disc. Account"));
        // [GIVEN] Gen. Posting Setup record 'B', where "Sales Inv. Disc. Account" is blank, "Gen. Bus. Posting Group" is 'Y'
        GeneralPostingSetup[2] := GeneralPostingSetup[1];
        GeneralPostingSetup[2]."Gen. Bus. Posting Group" := LibraryUtility.GenerateGUID();
        GeneralPostingSetup[2].Insert();
        // [GIVEN] Entered new "Invoice Discount Amount" = '10'
        GeneralPostingSetupPage.Trap();
        SalesInvoicePage.OpenEdit();
        SalesInvoicePage.FILTER.SetFilter("No.", SalesLine."Document No.");
        SalesInvoicePage.SalesLines."Invoice Discount Amount".Value(Format(10));

        // [WHEN] Notification: "G/L accounts for discounts are missing... | Open page |" and user click on 'Open page'
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'sent notification message');

        // [THEN] Gen. Posting Setup page is open, where is one record 'A'.
        VerifyGenPostingSetupInPage(GeneralPostingSetupPage, GeneralPostingSetup[1]);
        // [THEN] "Invoice Discount Amount" is 10
        Assert.AreEqual(10, SalesInvoicePage.SalesLines."Invoice Discount Amount".AsDecimal(), 'Invoice Discount Amount');

        GeneralPostingSetup[2].Delete();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationActionHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T131_NotifyAboutMissingSalesSetupOnCalcInvDiscountAction()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesLine: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetupPage: TestPage "General Posting Setup";
        SalesInvoicePage: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UI]
        // [SCENARIO] User runs 'Calculate Invoice Discount' action the posting setup where invoice discount account is blank
        Initialize();
        // [GIVEN] Sales Setup, where "Discount Posting" is 'Invoice Discounts'
        DefineAllDiscountAccounts();
        LibrarySales.SetDiscountPosting(SalesSetup."Discount Posting"::"Invoice Discounts");
        // [GIVEN] Created the Order and one item line, where the posting setup is 'A'.
        CreateSalesInvoiceWithOneLine(SalesLine);
        // [GIVEN] Gen. Posting Setup record 'A', where "Sales Inv Disc. Account" is blank.
        BlankSalesDiscAccount(GeneralPostingSetup, SalesLine, GeneralPostingSetup.FieldNo("Sales Inv. Disc. Account"));
        // [GIVEN] Run "Calculate Invoice Discount" action
        GeneralPostingSetupPage.Trap();
        SalesInvoicePage.OpenEdit();
        SalesInvoicePage.FILTER.SetFilter("No.", SalesLine."Document No.");
        SalesInvoicePage.CalculateInvoiceDiscount.Invoke();

        // [WHEN] Notification: "G/L accounts for discounts are missing... | Open page |" and user click on 'Open page'
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'sent notification message');

        // [THEN] Gen. Posting Setup page is open, where is one record 'A'.
        VerifyGenPostingSetupInPage(GeneralPostingSetupPage, GeneralPostingSetup);
        // [THEN] "Invoice Discount Amount" is not 0
        Assert.AreNotEqual(0, SalesInvoicePage.SalesLines."Invoice Discount Amount".AsDecimal(), 'Invoice Discount Amount');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T180_FindSalesSetupMissingAllDiscAccounts()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        FieldNumber: Integer;
    begin
        // [FEATURE] [Sales] [Setup] [UT]
        // [GIVEN] 2 GeneralPostingSetup records have all blank discount accounts
        DefineAllDiscountAccounts();
        GeneralPostingSetup."Gen. Bus. Posting Group" := LibraryUtility.GenerateGUID();
        GeneralPostingSetup.Insert();
        GeneralPostingSetup."Gen. Bus. Posting Group" := LibraryUtility.GenerateGUID();
        GeneralPostingSetup.Insert();
        // [WHEN] run FindSetupMissingSalesDiscountAccount("All Discounts")
        Assert.IsTrue(
          GeneralPostingSetup.FindSetupMissingSalesDiscountAccount(SalesSetup."Discount Posting"::"All Discounts", FieldNumber),
          'not found posting setup');
        // [THEN] Found 2 records
        Assert.RecordCount(GeneralPostingSetup, 2);
        // [THEN] FieldNumber is "Sales Line Disc. Account"
        Assert.AreEqual(GeneralPostingSetup.FieldNo("Sales Line Disc. Account"), FieldNumber, 'wrong FieldNumer');
        GeneralPostingSetup.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T181_FindSalesSetupMissingNoneDiscAccounts()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        FieldNumber: Integer;
    begin
        // [FEATURE] [Sales] [Setup] [UT]
        // [GIVEN] All GeneralPostingSetup records have discount acocunts defined
        DefineAllDiscountAccounts();

        // [WHEN] run FindSetupMissingSalesDiscountAccount("All Discounts")
        Assert.IsFalse(
          GeneralPostingSetup.FindSetupMissingSalesDiscountAccount(SalesSetup."Discount Posting"::"All Discounts", FieldNumber),
          'found posting setup');
        // [THEN] Found 0 records
        Assert.RecordCount(GeneralPostingSetup, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T182_FindSalesSetupMissingInvDiscAccount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        ExpectedRecID: Text;
        FieldNumber: Integer;
    begin
        // [FEATURE] [Sales] [Setup] [UT]
        // [GIVEN] All GeneralPostingSetup records have discount acocunts defined
        DefineAllDiscountAccounts();
        // [GIVEN] Gen. Posting Setup 'A' where "Sales Inv. Disc. Account" is blank
        ExpectedRecID := CreateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup.FieldNo("Sales Inv. Disc. Account"));
        // [GIVEN] Gen. Posting Setup 'B' where "Purch. Inv. Disc. Account" is blank
        CreateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup.FieldNo("Purch. Inv. Disc. Account"));

        // [WHEN] run FindSetupMissingPurchDiscountAccount("Invoice Discounts")
        Assert.IsTrue(
          GeneralPostingSetup.FindSetupMissingSalesDiscountAccount(SalesSetup."Discount Posting"::"Invoice Discounts", FieldNumber),
          'not found posting setup');
        // [THEN] Found Gen. Posting Setup 'A'
        Assert.RecordCount(GeneralPostingSetup, 1);
        Assert.AreEqual(ExpectedRecID, Format(GeneralPostingSetup.RecordId), 'wrong record found');
        // [THEN] FieldNumber is "Sales Inv Disc. Account"
        Assert.AreEqual(GeneralPostingSetup.FieldNo("Sales Inv. Disc. Account"), FieldNumber, 'wrong FieldNumer');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T183_FindSalesSetupMissingLineDiscAccount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        ExpectedRecID: Text;
        FieldNumber: Integer;
    begin
        // [FEATURE] [Sales] [Setup] [UT]
        // [GIVEN] All GeneralPostingSetup records have discount acocunts defined
        DefineAllDiscountAccounts();
        // [GIVEN] Gen. Posting Setup 'A' where "Sales Line Disc. Account" is blank
        ExpectedRecID := CreateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup.FieldNo("Sales Line Disc. Account"));
        // [GIVEN] Gen. Posting Setup 'B' where "Purch. Line Disc. Account" is blank
        CreateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup.FieldNo("Purch. Line Disc. Account"));

        // [WHEN] run FindSetupMissingSalesDiscountAccount("Line Discounts")
        Assert.IsTrue(
          GeneralPostingSetup.FindSetupMissingSalesDiscountAccount(SalesSetup."Discount Posting"::"Line Discounts", FieldNumber),
          'not found posting setup');
        // [THEN] Found Gen. Posting Setup 'A'
        Assert.RecordCount(GeneralPostingSetup, 1);
        Assert.AreEqual(ExpectedRecID, Format(GeneralPostingSetup.RecordId), 'wrong record found');
        // [THEN] FieldNumber is "Sales Line Disc. Account"
        Assert.AreEqual(GeneralPostingSetup.FieldNo("Sales Line Disc. Account"), FieldNumber, 'wrong FieldNumer');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T184_FindSalesSetupMissingLineOrInvDiscAccount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        ExpectedRecID: array[2] of Text;
        FieldNumber: Integer;
    begin
        // [FEATURE] [Sales] [Setup] [UT]
        // [GIVEN] All GeneralPostingSetup records have discount acocunts defined
        DefineAllDiscountAccounts();
        // [GIVEN] Gen. Posting Setup 'A' where "Sales Inv. Disc. Account" is blank
        ExpectedRecID[1] := CreateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup.FieldNo("Sales Inv. Disc. Account"));
        // [GIVEN] Gen. Posting Setup 'B' where "Sales Line Disc. Account" is blank
        ExpectedRecID[2] := CreateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup.FieldNo("Sales Line Disc. Account"));

        // [WHEN] run FindSetupMissingSalesDiscountAccount("All Discounts")
        Assert.IsTrue(
          GeneralPostingSetup.FindSetupMissingSalesDiscountAccount(SalesSetup."Discount Posting"::"All Discounts", FieldNumber),
          'not found posting setup');
        // [THEN] Found both Gen. Posting Setup 'A' and 'B'
        Assert.RecordCount(GeneralPostingSetup, 2);
        Assert.AreEqual(ExpectedRecID[1], Format(GeneralPostingSetup.RecordId), 'wrong record #1 found');
        GeneralPostingSetup.Next();
        Assert.AreEqual(ExpectedRecID[2], Format(GeneralPostingSetup.RecordId), 'wrong record #2 found');
        // [THEN] FieldNumber is "Sales Inv. Disc. Account"
        Assert.AreEqual(GeneralPostingSetup.FieldNo("Sales Inv. Disc. Account"), FieldNumber, 'wrong FieldNumer');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T185_FindSalesSetupMissingBothDiscountAccounts()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        ExpectedRecID: Text;
        FieldNumber: Integer;
    begin
        // [FEATURE] [Sales] [Setup] [UT]
        // [GIVEN] All GeneralPostingSetup records have discount acocunts defined
        DefineAllDiscountAccounts();
        // [GIVEN] Gen. Posting Setup 'A' where "Sales Line Disc. Account" is blank
        CreateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup.FieldNo("Sales Line Disc. Account"));
        // [GIVEN] Gen. Posting Setup 'B' where "Sales Inv. Disc. Account" is blank
        CreateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup.FieldNo("Sales Inv. Disc. Account"));
        // [GIVEN] Gen. Posting Setup 'C' where both "Sales Inv. Disc. Account" and "Sales Line Disc. Account" are blank
        ExpectedRecID := CreateGeneralPostingSetup(GeneralPostingSetup, -1);

        // [WHEN] run FindSetupMissingSalesDiscountAccount("No Discounts")
        Assert.IsTrue(
          GeneralPostingSetup.FindSetupMissingSalesDiscountAccount(SalesSetup."Discount Posting"::"No Discounts", FieldNumber),
          'not found posting setup');
        // [THEN] Found Gen. Posting Setup 'C'
        Assert.RecordCount(GeneralPostingSetup, 1);
        Assert.AreEqual(ExpectedRecID, Format(GeneralPostingSetup.RecordId), 'wrong record found');
        // [THEN] FieldNumber is "Sales Line Disc. Account"
        Assert.AreEqual(GeneralPostingSetup.FieldNo("Sales Line Disc. Account"), FieldNumber, 'wrong FieldNumer');
    end;

    [Test]
    [HandlerFunctions('SendNotificationActionHandler')]
    [Scope('OnPrem')]
    procedure T200_NotifyAboutMissingPurchSetupOnDiscountPostingValidation()
    var
        GeneralPostingSetup: array[2] of Record "General Posting Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetupPage: TestPage "General Posting Setup";
    begin
        // [FEATURE] [Purchase] [Setup] [UI]
        // [SCENARIO] Notification is shown about gen. posting setup where discount accounts are missed If "Discount Posting" changed to not "All Discounts"
        Initialize();
        // [GIVEN] Gen. Posting Setup 'A', where "Purch. Inv. Disc. Account" is blank
        // [GIVEN] Gen. Posting Setup 'B', where "Purch. Line Disc. Account" is blank
        CreateGeneralPostingSetups(
          GeneralPostingSetup,
          GeneralPostingSetup[1].FieldNo("Purch. Inv. Disc. Account"),
          GeneralPostingSetup[1].FieldNo("Purch. Line Disc. Account"));
        // [GIVEN] Admin user changes "Discount Posting" from "No Discounts" to 'All Discounts'
        GeneralPostingSetupPage.Trap();
        LibraryPurchase.SetDiscountPosting(PurchSetup."Discount Posting"::"All Discounts");

        // [WHEN] Notification: "G/L accounts for discounts are missing... | Open page |" and user click on 'Open page'
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'notification message');

        // [THEN] Gen. Posting Setup page is open, where are 2 records: A' and 'B'.
        Assert.IsTrue(GeneralPostingSetupPage.First(), 'missing the 1st line');
        GeneralPostingSetupPage."Gen. Bus. Posting Group".AssertEquals(GeneralPostingSetup[1]."Gen. Bus. Posting Group");
        GeneralPostingSetupPage."Gen. Prod. Posting Group".AssertEquals(GeneralPostingSetup[1]."Gen. Prod. Posting Group");
        Assert.IsTrue(GeneralPostingSetupPage.Next(), 'missing the 2nd line');
        GeneralPostingSetupPage."Gen. Bus. Posting Group".AssertEquals(GeneralPostingSetup[2]."Gen. Bus. Posting Group");
        GeneralPostingSetupPage."Gen. Prod. Posting Group".AssertEquals(GeneralPostingSetup[2]."Gen. Prod. Posting Group");
        Assert.IsTrue(GeneralPostingSetupPage.Next(), 'not expected the 3rd line');
        GeneralPostingSetupPage.Close();

        LibraryNotificationMgt.RecallNotificationsForRecord(PurchSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationSimpleHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T201_RecallNotificationOnChangingPurchDiscountPosting()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [Purchase] [Setup]
        // [SCENARIO] Notification is recalled if "Discount Posting" is changed
        Initialize();
        // [GIVEN] Shown the notification due to missing "Purch. Inv. Disc. Account"
        ShowPurchNotificationForDiscountPosting(PurchSetup."Discount Posting"::"Invoice Discounts");
        // [GIVEN] Gen. Posting Setup 'B' where "Purch. Line Disc. Account" is blank
        CreateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup.FieldNo("Purch. Line Disc. Account"));

        // [WHEN] Admin user changes "Discount Posting" from "Invoice Discounts" to 'Line Discounts'
        LibraryPurchase.SetDiscountPosting(PurchSetup."Discount Posting"::"Line Discounts");

        // [THEN] Notification is recalled and
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'recall #1 notification message');
        // [THEN] Notification: "G/L accounts for discounts are missing... | Open page |"
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'notification #2 message');

        LibraryNotificationMgt.RecallNotificationsForRecord(PurchSetup);
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'recall #2 notification message');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationSimpleHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T202_RecallNotificationOnChangingPurchDiscountPostingNoMissingAcc()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [Purchase] [Setup]
        // [SCENARIO] Notification is recalled if "Discount Posting" is changed so there are no missing accounts
        Initialize();
        // [GIVEN] Shown the notification due to missing "Purch. Inv. Disc. Account"
        ShowPurchNotificationForDiscountPosting(PurchSetup."Discount Posting"::"Invoice Discounts");

        // [WHEN] Admin user changes "Discount Posting" from "Invoice Discounts" to 'Line Discounts'
        LibraryPurchase.SetDiscountPosting(PurchSetup."Discount Posting"::"Line Discounts");

        // [THEN] Notification is recalled and no new notification shown
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'recall #1 notification message');

        LibraryNotificationMgt.RecallNotificationsForRecord(PurchSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationSimpleHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T203_RecallNotificationOnChangingPurchDiscountPostingToNoDiscount()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [Purchase] [Setup]
        // [SCENARIO] Notification is recalled if "Discount Posting" is changed to "No Discounts"
        Initialize();
        // [GIVEN] Shown the notification due to missing "Purch. Inv. Disc. Account"
        ShowPurchNotificationForDiscountPosting(PurchSetup."Discount Posting"::"Invoice Discounts");

        // [WHEN] Admin user changes "Discount Posting" from "Invoice Discounts" to 'No Discounts'
        LibraryPurchase.SetDiscountPosting(PurchSetup."Discount Posting"::"No Discounts");

        // [THEN] Notification is recalled and no new notification shown
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'recall #1 notification message');

        LibraryNotificationMgt.RecallNotificationsForRecord(PurchSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationActionHandler')]
    [Scope('OnPrem')]
    procedure T210_NotifyAboutMissingPurchLineSetupOnDiscountPostingValidation()
    var
        GeneralPostingSetup: array[2] of Record "General Posting Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetupPage: TestPage "General Posting Setup";
    begin
        // [FEATURE] [Purchase] [Setup] [UI]
        // [SCENARIO] Notification is shown about gen. posting setup where line discount accounts are missed If "Discount Posting" changed to "Line Discounts"
        Initialize();
        // [GIVEN] Gen. Posting Setup 'A', where "Purch. Inv. Disc. Account" is blank
        // [GIVEN] Gen. Posting Setup 'B', where "Purch. Line Disc. Account" is blank
        CreateGeneralPostingSetups(
          GeneralPostingSetup,
          GeneralPostingSetup[1].FieldNo("Purch. Inv. Disc. Account"),
          GeneralPostingSetup[2].FieldNo("Purch. Line Disc. Account"));
        // [GIVEN] Admin user changes "Discount Posting" from "No Discounts" to 'Line Discounts'
        GeneralPostingSetupPage.Trap();
        LibraryPurchase.SetDiscountPosting(PurchSetup."Discount Posting"::"Line Discounts");

        // [WHEN] Notification: "G/L accounts for discounts are missing... | Open page |" and user click on 'Open page'
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'notification message');

        // [THEN] Gen. Posting Setup page is open, where is one record 'B'.
        VerifyGenPostingSetupInPage(GeneralPostingSetupPage, GeneralPostingSetup[2]);

        LibraryNotificationMgt.RecallNotificationsForRecord(PurchSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationActionHandler')]
    [Scope('OnPrem')]
    procedure T211_NotifyAboutMissingPurchInvSetupOnDiscountPostingValidation()
    var
        GeneralPostingSetup: array[2] of Record "General Posting Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetupPage: TestPage "General Posting Setup";
    begin
        // [FEATURE] [Purchase] [Setup] [UI]
        // [SCENARIO] Notification is shown about gen. posting setup where invoice discount accounts are missed If "Discount Posting" changed to "Invoice Discounts"
        Initialize();
        // [GIVEN] Gen. Posting Setup 'A', where "Purch. Inv. Disc. Account" is blank
        // [GIVEN] Gen. Posting Setup 'B', where "Purch. Line Disc. Account" is blank
        CreateGeneralPostingSetups(
          GeneralPostingSetup,
          GeneralPostingSetup[1].FieldNo("Purch. Inv. Disc. Account"),
          GeneralPostingSetup[2].FieldNo("Purch. Line Disc. Account"));
        // [GIVEN] Admin user changes "Discount Posting" from "No Discounts" to 'Invoice Discounts'
        GeneralPostingSetupPage.Trap();
        LibraryPurchase.SetDiscountPosting(PurchSetup."Discount Posting"::"Invoice Discounts");

        // [WHEN] Notification: "G/L accounts for discounts are missing... | Open page |" and user click on 'Open page'
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'notification message');

        // [THEN] Gen. Posting Setup page is open, where is one record 'A'.
        VerifyGenPostingSetupInPage(GeneralPostingSetupPage, GeneralPostingSetup[1]);

        LibraryNotificationMgt.RecallNotificationsForRecord(PurchSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationActionHandler')]
    [Scope('OnPrem')]
    procedure T220_NotifyAboutMissingPurchSetupOnLineDiscountValidation()
    var
        GeneralPostingSetup: array[2] of Record "General Posting Setup";
        PurchLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetupPage: TestPage "General Posting Setup";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UI]
        // [SCENARIO] User enters a line discount for the posting setup where line discount account is blank
        Initialize();
        // [GIVEN] Purch Setup, where "Discount Posting" is 'Line Discounts'
        DefineAllDiscountAccounts();
        LibraryPurchase.SetDiscountPosting(PurchSetup."Discount Posting"::"Line Discounts");
        // [GIVEN] Created the Order and one item line, where the posting setup is 'A'.
        CreatePurchInvoiceWithOneLine(PurchLine);
        // [GIVEN] Gen. Posting Setup record 'A', where "Purch. Line Disc. Account" is blank, "Gen. Bus. Posting Group" is 'X'
        BlankPurchDiscAccount(GeneralPostingSetup[1], PurchLine, GeneralPostingSetup[1].FieldNo("Purch. Line Disc. Account"));
        // [GIVEN] Gen. Posting Setup record 'B', where "Sales Line Disc. Account" is blank, "Gen. Bus. Posting Group" is 'Y'
        GeneralPostingSetup[2] := GeneralPostingSetup[1];
        GeneralPostingSetup[2]."Gen. Bus. Posting Group" := LibraryUtility.GenerateGUID();
        GeneralPostingSetup[2].Insert();
        // [GIVEN] Entered new "Line Discount %" = 10
        GeneralPostingSetupPage.Trap();
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.FILTER.SetFilter("No.", PurchLine."Document No.");
        PurchaseInvoicePage.PurchLines."Line Discount %".Value('10');

        // [WHEN] Notification: "G/L accounts for discounts are missing... | Open page |" and user click on 'Open page'
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'sent notification message');

        // [THEN] Gen. Posting Setup page is open, where is one record 'A'.
        VerifyGenPostingSetupInPage(GeneralPostingSetupPage, GeneralPostingSetup[1]);
        // [THEN] "Line Discount %" is 10
        PurchaseInvoicePage.PurchLines."Line Discount %".AssertEquals('10');

        GeneralPostingSetup[2].Delete();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationSimpleHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T221_RecallNotificationOnPurchLineDiscountPctValidation()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UI]
        // [SCENARIO] User enters the blank "Line Discount %" while the notification is shown
        Initialize();
        // [GIVEN] Purch Setup, where "Discount Posting" is 'Line Discounts'
        DefineAllDiscountAccounts();
        LibraryPurchase.SetDiscountPosting(PurchSetup."Discount Posting"::"Line Discounts");
        // [GIVEN] Created the Order and one item line, where the posting setup is 'A'.
        CreatePurchInvoiceWithOneLine(PurchLine);
        // [GIVEN] Gen. Posting Setup record 'A', where "Purch. Line Disc. Account" is blank.
        BlankPurchDiscAccount(GeneralPostingSetup, PurchLine, GeneralPostingSetup.FieldNo("Purch. Line Disc. Account"));
        // [GIVEN] Entered new "Line Discount %" = 10
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.FILTER.SetFilter("No.", PurchLine."Document No.");
        PurchaseInvoicePage.PurchLines."Line Discount %".Value('10');
        // [GIVEN] Notification: "G/L accounts for discounts are missing... | Open page |"
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'sent notification message');

        // [WHEN] Entered new "Line Discount %" = 0
        PurchaseInvoicePage.PurchLines."Line Discount %".Value('0');

        // [THEN] Notification is recalled, no new notification shown.
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'recall notification message');

        LibraryNotificationMgt.RecallNotificationsForRecord(PurchSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationSimpleHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T222_RecallNotificationOnPurchLineDiscountAmtValidation()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        LineAmt: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice] [UI]
        // [SCENARIO] User restores the "Line Amount" that caused the line discount, while the notification is shown
        Initialize();
        // [GIVEN] Purch Setup, where "Discount Posting" is 'Line Discounts'
        DefineAllDiscountAccounts();
        LibraryPurchase.SetDiscountPosting(PurchSetup."Discount Posting"::"Line Discounts");
        // [GIVEN] Created the Order and one item line, where the posting setup is 'A'.
        CreatePurchInvoiceWithOneLine(PurchLine);
        // [GIVEN] Gen. Posting Setup record 'A', where "Purch. Line Disc. Account" is blank.
        BlankPurchDiscAccount(GeneralPostingSetup, PurchLine, GeneralPostingSetup.FieldNo("Purch. Line Disc. Account"));
        // [GIVEN] Entered new "Line Discount Amount" = 1
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.FILTER.SetFilter("No.", PurchLine."Document No.");
        LineAmt := PurchaseInvoicePage.PurchLines."Line Amount".AsDecimal();
        PurchaseInvoicePage.PurchLines."Line Amount".Value(Format(LineAmt - 1));
        // [GIVEN] Notification: "G/L accounts for discounts are missing... | Open page |"
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'sent notification message');

        // [WHEN] Entered new "Line Discount Amount" = 0
        PurchaseInvoicePage.PurchLines."Line Amount".Value(Format(LineAmt));

        // [THEN] Notification is recalled, no new notification shown.
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'recall notification message');

        LibraryNotificationMgt.RecallNotificationsForRecord(PurchSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationSimpleHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T223_RecallNotificationOnPurchLineDiscountAmtValidationIfNoDiscounts()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UI]
        // [SCENARIO] User enters new "Line Discount %" while the "Discount Posting" is "No Discounts"
        Initialize();
        // [GIVEN] Purch Setup, where "Discount Posting" is 'Line Discounts'
        DefineAllDiscountAccounts();
        LibraryPurchase.SetDiscountPosting(PurchSetup."Discount Posting"::"Line Discounts");
        // [GIVEN] Created the Order and one item line, where the posting setup is 'A'.
        CreatePurchInvoiceWithOneLine(PurchLine);
        // [GIVEN] Gen. Posting Setup record 'A', where "Purch. Line Disc. Account" is blank.
        BlankPurchDiscAccount(GeneralPostingSetup, PurchLine, GeneralPostingSetup.FieldNo("Purch. Line Disc. Account"));
        // [GIVEN] Entered new "Line Discount %" = 10
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.FILTER.SetFilter("No.", PurchLine."Document No.");
        PurchaseInvoicePage.PurchLines."Line Discount %".Value('10');
        // [GIVEN] Notification: "G/L accounts for discounts are missing... | Open page |"
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'sent notification message');
        // [GIVEN] Purch Setup, where "Discount Posting" is 'No Discounts'
        PurchSetup.Get();
        PurchSetup."Discount Posting" := PurchSetup."Discount Posting"::"No Discounts";
        PurchSetup.Modify();

        // [WHEN] Entered new "Line Discount %" = 20
        PurchaseInvoicePage.PurchLines."Line Discount %".Value('20');

        // [THEN] Notification is recalled, no new notification shown.
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'recall notification message');

        LibraryNotificationMgt.RecallNotificationsForRecord(PurchSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T224_DontNotifyAboutMissingPurchSetupOnLineDiscValidationInTrigger()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO] Notification is not shown if "Line Discount %" validated through code, not on the page.
        Initialize();
        // [GIVEN] Purch Setup, where "Discount Posting" is 'Line Discounts'
        DefineAllDiscountAccounts();
        LibraryPurchase.SetDiscountPosting(PurchSetup."Discount Posting"::"Line Discounts");
        // [GIVEN] Created the Order and one item line, where the posting setup is 'A'.
        CreatePurchInvoiceWithOneLine(PurchLine);
        // [GIVEN] Gen. Posting Setup record 'A', where "Purch. Line Disc. Account" is blank.
        BlankPurchDiscAccount(GeneralPostingSetup, PurchLine, GeneralPostingSetup.FieldNo("Purch. Line Disc. Account"));

        // [WHEN] Validate "Line Discount %" = 10
        PurchLine.Validate("Line Discount %", 10);
        PurchLine.Modify();

        // [THEN] "Line Discount %" is 10
        PurchLine.TestField("Line Discount %", 10);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationActionHandler')]
    [Scope('OnPrem')]
    procedure T230_NotifyAboutMissingPurchSetupOnInvDiscountValidation()
    var
        GeneralPostingSetup: array[2] of Record "General Posting Setup";
        PurchLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetupPage: TestPage "General Posting Setup";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UI]
        // [SCENARIO] User enters a invoice discount for the posting setup where invoice discount account is blank
        Initialize();
        // [GIVEN] Purch Setup, where "Discount Posting" is 'Invoice Discounts'
        DefineAllDiscountAccounts();
        LibraryPurchase.SetDiscountPosting(PurchSetup."Discount Posting"::"Invoice Discounts");
        // [GIVEN] Created the Order and one item line, where the posting setup is 'A'.
        CreatePurchInvoiceWithOneLine(PurchLine);
        // [GIVEN] Gen. Posting Setup record 'A', where "Purch. Inv. Disc. Account" is blank, "Gen. Bus. Posting Group" is 'X'
        BlankPurchDiscAccount(GeneralPostingSetup[1], PurchLine, GeneralPostingSetup[1].FieldNo("Purch. Inv. Disc. Account"));
        // [GIVEN] Gen. Posting Setup record 'B', where "Sales Line Disc. Account" is blank, "Gen. Bus. Posting Group" is 'Y'
        GeneralPostingSetup[2] := GeneralPostingSetup[1];
        GeneralPostingSetup[2]."Gen. Bus. Posting Group" := LibraryUtility.GenerateGUID();
        GeneralPostingSetup[2].Insert();
        // [GIVEN] Entered new "Inv. Discount Amount" = 10
        GeneralPostingSetupPage.Trap();
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.FILTER.SetFilter("No.", PurchLine."Document No.");
        PurchaseInvoicePage.PurchLines.InvoiceDiscountAmount.Value('10');

        // [WHEN] Notification: "G/L accounts for discounts are missing... | Open page |" and user click on 'Open page'
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'sent notification message');

        // [THEN] Gen. Posting Setup page is open, where is one record 'A'.
        VerifyGenPostingSetupInPage(GeneralPostingSetupPage, GeneralPostingSetup[1]);
        // [THEN] "Inv. Discount Amount" is 10
        Assert.AreEqual(10, PurchaseInvoicePage.PurchLines.InvoiceDiscountAmount.AsDecimal(), 'InvoiceDiscountAmount subpage');

        GeneralPostingSetup[2].Delete();
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationActionHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T231_NotifyAboutMissingPurchSetupOnCalcInvDiscountAction()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetupPage: TestPage "General Posting Setup";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UI]
        // [SCENARIO] User runs 'Calculate Invoice Discount' action the posting setup where invoice discount account is blank
        Initialize();
        // [GIVEN] Purch Setup, where "Discount Posting" is 'Invoice Discounts'
        DefineAllDiscountAccounts();
        LibraryPurchase.SetDiscountPosting(PurchSetup."Discount Posting"::"Invoice Discounts");
        // [GIVEN] Created the Order and one item line, where the posting setup is 'A'.
        CreatePurchInvoiceWithOneLine(PurchLine);
        // [GIVEN] Gen. Posting Setup record 'A', where "Purch. Inv. Disc. Account" is blank.
        BlankPurchDiscAccount(GeneralPostingSetup, PurchLine, GeneralPostingSetup.FieldNo("Purch. Inv. Disc. Account"));
        // [GIVEN] Run "Calculate Invoice Discount" action
        GeneralPostingSetupPage.Trap();
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.FILTER.SetFilter("No.", PurchLine."Document No.");
        PurchaseInvoicePage.CalculateInvoiceDiscount.Invoke();

        // [WHEN] Notification: "G/L accounts for discounts are missing... | Open page |" and user click on 'Open page'
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'sent notification message');

        // [THEN] Gen. Posting Setup page is open, where is one record 'A'.
        VerifyGenPostingSetupInPage(GeneralPostingSetupPage, GeneralPostingSetup);
        // [THEN] "Invoice Discount Amount" is not 0
        Assert.AreNotEqual(0, PurchaseInvoicePage.PurchLines.InvoiceDiscountAmount.AsDecimal(), 'InvoiceDiscountAmount subpage');
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T280_FindPurchSetupMissingAllDiscAccounts()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        FieldNumber: Integer;
    begin
        // [FEATURE] [Purchase] [Setup] [UT]
        // [GIVEN] 2 GeneralPostingSetup records have all blank discount accounts
        DefineAllDiscountAccounts();
        GeneralPostingSetup."Gen. Bus. Posting Group" := LibraryUtility.GenerateGUID();
        GeneralPostingSetup.Insert();
        GeneralPostingSetup."Gen. Bus. Posting Group" := LibraryUtility.GenerateGUID();
        GeneralPostingSetup.Insert();
        // [WHEN] run FindSetupMissingPurchDiscountAccount("All Discounts")
        Assert.IsTrue(
          GeneralPostingSetup.FindSetupMissingPurchDiscountAccount(PurchSetup."Discount Posting"::"All Discounts", FieldNumber),
          'not found posting setup');
        // [THEN] Found 2 records
        Assert.RecordCount(GeneralPostingSetup, 2);
        // [THEN] FieldNumber is "Purch. Line Disc. Account"
        Assert.AreEqual(GeneralPostingSetup.FieldNo("Purch. Line Disc. Account"), FieldNumber, 'wrong FieldNumer');
        GeneralPostingSetup.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T281_FindPurchSetupMissingNoneDiscAccounts()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        FieldNumber: Integer;
    begin
        // [FEATURE] [Purchase] [Setup] [UT]
        // [GIVEN] All GeneralPostingSetup records have discount acocunts defined
        DefineAllDiscountAccounts();

        // [WHEN] run FindSetupMissingPurchDiscountAccount("All Discounts")
        Assert.IsFalse(
          GeneralPostingSetup.FindSetupMissingPurchDiscountAccount(PurchSetup."Discount Posting"::"All Discounts", FieldNumber),
          'found posting setup');
        // [THEN] Found 0 records
        Assert.RecordCount(GeneralPostingSetup, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T282_FindPurchSetupMissingInvDiscAccount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        ExpectedRecID: Text;
        FieldNumber: Integer;
    begin
        // [FEATURE] [Purchase] [Setup] [UT]
        // [GIVEN] All GeneralPostingSetup records have discount acocunts defined
        DefineAllDiscountAccounts();
        // [GIVEN] Gen. Posting Setup 'A' where "Purch. Inv. Disc. Account" is blank
        ExpectedRecID := CreateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup.FieldNo("Purch. Inv. Disc. Account"));
        // [GIVEN] Gen. Posting Setup 'B' where "Sales Inv. Disc. Account" is blank
        CreateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup.FieldNo("Sales Inv. Disc. Account"));

        // [WHEN] run FindSetupMissingPurchDiscountAccount("Invoice Discounts")
        Assert.IsTrue(
          GeneralPostingSetup.FindSetupMissingPurchDiscountAccount(PurchSetup."Discount Posting"::"Invoice Discounts", FieldNumber),
          'not found posting setup');
        // [THEN] Found Gen. Posting Setup 'A'
        Assert.RecordCount(GeneralPostingSetup, 1);
        Assert.AreEqual(ExpectedRecID, Format(GeneralPostingSetup.RecordId), 'wrong record found');
        // [THEN] FieldNumber is "Purch. Inv. Disc. Account"
        Assert.AreEqual(GeneralPostingSetup.FieldNo("Purch. Inv. Disc. Account"), FieldNumber, 'wrong FieldNumer');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T283_FindPurchSetupMissingLineDiscAccount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        ExpectedRecID: Text;
        FieldNumber: Integer;
    begin
        // [FEATURE] [Purchase] [Setup] [UT]
        // [GIVEN] All GeneralPostingSetup records have discount acocunts defined
        DefineAllDiscountAccounts();
        // [GIVEN] Gen. Posting Setup 'A' where "Purch. Line Disc. Account" is blank
        ExpectedRecID := CreateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup.FieldNo("Purch. Line Disc. Account"));
        // [GIVEN] Gen. Posting Setup 'B' where "Sales Line Disc. Account" is blank
        CreateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup.FieldNo("Sales Line Disc. Account"));

        // [WHEN] run FindSetupMissingPurchDiscountAccount("Line Discounts")
        Assert.IsTrue(
          GeneralPostingSetup.FindSetupMissingPurchDiscountAccount(PurchSetup."Discount Posting"::"Line Discounts", FieldNumber),
          'not found posting setup');
        // [THEN] Found Gen. Posting Setup 'A'
        Assert.RecordCount(GeneralPostingSetup, 1);
        Assert.AreEqual(ExpectedRecID, Format(GeneralPostingSetup.RecordId), 'wrong record found');
        // [THEN] FieldNumber is "Purch. Line Disc. Account"
        Assert.AreEqual(GeneralPostingSetup.FieldNo("Purch. Line Disc. Account"), FieldNumber, 'wrong FieldNumer');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T284_FindPurchSetupMissingLineOrInvDiscAccount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        ExpectedRecID: array[2] of Text;
        FieldNumber: Integer;
    begin
        // [FEATURE] [Purchase] [Setup] [UT]
        // [GIVEN] All GeneralPostingSetup records have discount acocunts defined
        DefineAllDiscountAccounts();
        // [GIVEN] Gen. Posting Setup 'A' where "Purch. Inv. Disc. Account" is blank
        ExpectedRecID[1] := CreateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup.FieldNo("Purch. Inv. Disc. Account"));
        // [GIVEN] Gen. Posting Setup 'B' where "Purch. Line Disc. Account" is blank
        ExpectedRecID[2] := CreateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup.FieldNo("Purch. Line Disc. Account"));

        // [WHEN] run FindSetupMissingPurchDiscountAccount("All Discounts")
        Assert.IsTrue(
          GeneralPostingSetup.FindSetupMissingPurchDiscountAccount(PurchSetup."Discount Posting"::"All Discounts", FieldNumber),
          'not found posting setup');
        // [THEN] Found both Gen. Posting Setup 'A' and 'B'
        Assert.RecordCount(GeneralPostingSetup, 2);
        Assert.AreEqual(ExpectedRecID[1], Format(GeneralPostingSetup.RecordId), 'wrong record #1 found');
        GeneralPostingSetup.Next();
        Assert.AreEqual(ExpectedRecID[2], Format(GeneralPostingSetup.RecordId), 'wrong record #2 found');
        // [THEN] FieldNumber is "Purch. Inv. Disc. Account"
        Assert.AreEqual(GeneralPostingSetup.FieldNo("Purch. Inv. Disc. Account"), FieldNumber, 'wrong FieldNumer');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T285_FindPurchSetupMissingBothDiscountAccounts()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        ExpectedRecID: Text;
        FieldNumber: Integer;
    begin
        // [FEATURE] [Purchase] [Setup] [UT]
        // [GIVEN] All GeneralPostingSetup records have discount acocunts defined
        DefineAllDiscountAccounts();
        // [GIVEN] Gen. Posting Setup 'A' where "Purch. Line Disc. Account" is blank
        CreateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup.FieldNo("Purch. Line Disc. Account"));
        // [GIVEN] Gen. Posting Setup 'B' where "Purch. Inv. Disc. Account" is blank
        CreateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup.FieldNo("Purch. Inv. Disc. Account"));
        // [GIVEN] Gen. Posting Setup 'C' where both "Purch. Inv. Disc. Account" and "Purch. Line Disc. Account" are blank
        ExpectedRecID := CreateGeneralPostingSetup(GeneralPostingSetup, -1);

        // [WHEN] run FindSetupMissingPurchDiscountAccount("No Discounts")
        Assert.IsTrue(
          GeneralPostingSetup.FindSetupMissingPurchDiscountAccount(PurchSetup."Discount Posting"::"No Discounts", FieldNumber),
          'not found posting setup');
        // [THEN] Found Gen. Posting Setup 'C'
        Assert.RecordCount(GeneralPostingSetup, 1);
        Assert.AreEqual(ExpectedRecID, Format(GeneralPostingSetup.RecordId), 'wrong record found');
        // [THEN] FieldNumber is "Purch. Line Disc. Account"
        Assert.AreEqual(GeneralPostingSetup.FieldNo("Purch. Line Disc. Account"), FieldNumber, 'wrong FieldNumer');
    end;

    [Test]
    [HandlerFunctions('SendNotificationActionHandler')]
    [Scope('OnPrem')]
    procedure T320_NotifyAboutMissingSalesSetupOnServiceLineDiscountValidation()
    var
        GeneralPostingSetup: array[2] of Record "General Posting Setup";
        ServiceLine: Record "Service Line";
        SalesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetupPage: TestPage "General Posting Setup";
        ServiceInvoicePage: TestPage "Service Invoice";
    begin
        // [FEATURE] [Service] [Invoice] [UI]
        // [SCENARIO] User enters a line discount while there is the posting setup, where line discount account is blank
        Initialize();
        // [GIVEN] Sales Setup, where "Discount Posting" is 'Line Discounts'
        DefineAllDiscountAccounts();
        LibrarySales.SetDiscountPosting(SalesSetup."Discount Posting"::"Line Discounts");
        // [GIVEN] Created the Invoice and one item line, where the posting setup is 'A'
        CreateServiceInvoiceWithOneLine(ServiceLine);
        // [GIVEN] Gen. Posting Setup record 'A', where "Sales Line Disc. Account" is blank, "Gen. Bus. Posting Group" is 'X'
        BlankServiceDiscAccount(GeneralPostingSetup[1], ServiceLine, GeneralPostingSetup[1].FieldNo("Sales Line Disc. Account"));
        // [GIVEN] Gen. Posting Setup record 'B', where "Sales Line Disc. Account" is blank, "Gen. Bus. Posting Group" is 'Y'
        GeneralPostingSetup[2] := GeneralPostingSetup[1];
        GeneralPostingSetup[2]."Gen. Bus. Posting Group" := LibraryUtility.GenerateGUID();
        GeneralPostingSetup[2].Insert();
        // [GIVEN] Entered new "Line Discount %" = 10
        GeneralPostingSetupPage.Trap();
        ServiceInvoicePage.OpenEdit();
        ServiceInvoicePage.FILTER.SetFilter("No.", ServiceLine."Document No.");
        ServiceInvoicePage.ServLines."Line Discount %".Value('10');

        // [WHEN] Notification: "G/L accounts for discounts are missing... | Open page |" and user click on 'Open page'
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'sent notification message');

        // [THEN] Gen. Posting Setup page is open, where is one record 'A'.
        VerifyGenPostingSetupInPage(GeneralPostingSetupPage, GeneralPostingSetup[1]);
        // [THEN] "Line Discount %" is 10
        ServiceInvoicePage.ServLines."Line Discount %".AssertEquals('10');

        GeneralPostingSetup[2].Delete();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationSimpleHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T322_RecallNotificationOnServiceLineDiscountAmtValidation()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        ServiceLine: Record "Service Line";
        SalesSetup: Record "Sales & Receivables Setup";
        ServiceInvoicePage: TestPage "Service Invoice";
        LineAmt: Decimal;
    begin
        // [FEATURE] [Service] [Invoice] [UI]
        // [SCENARIO] User restores the "Line Amount" that caused the line discount, while the notification is shown
        Initialize();
        // [GIVEN] Sales Setup, where "Discount Posting" is 'Line Discounts'
        DefineAllDiscountAccounts();
        LibrarySales.SetDiscountPosting(SalesSetup."Discount Posting"::"Line Discounts");
        // [GIVEN] Created the Invoice and one item line, where the posting setup is 'A'.
        CreateServiceInvoiceWithOneLine(ServiceLine);
        // [GIVEN] Gen. Posting Setup record 'A', where "Sales Line Disc. Account" is blank.
        BlankServiceDiscAccount(GeneralPostingSetup, ServiceLine, GeneralPostingSetup.FieldNo("Sales Line Disc. Account"));
        // [GIVEN] Entered new "Line Discount Amount" = 1
        ServiceInvoicePage.OpenEdit();
        ServiceInvoicePage.FILTER.SetFilter("No.", ServiceLine."Document No.");
        LineAmt := ServiceInvoicePage.ServLines."Line Amount".AsDecimal();
        ServiceInvoicePage.ServLines."Line Amount".Value(Format(LineAmt - 1));
        // [GIVEN] Notification: "G/L accounts for discounts are missing... | Open page |"
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'sent notification message');

        // [WHEN] Entered new "Line Discount Amount" = 0
        ServiceInvoicePage.ServLines."Line Amount".Value(Format(LineAmt));

        // [THEN] Notification is recalled, no new notification shown.
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'recall notification message');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationActionHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T331_NotifyAboutMissingSalesSetupOnServiceCalcInvDiscountAction()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        ServiceLine: Record "Service Line";
        SalesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetupPage: TestPage "General Posting Setup";
        ServiceInvoicePage: TestPage "Service Invoice";
    begin
        // [FEATURE] [Service] [Invoice] [UI]
        // [SCENARIO] User runs 'Calculate Invoice Discount' action the posting setup where invoice discount account is blank
        Initialize();
        // [GIVEN] Sales Setup, where "Discount Posting" is 'Invoice Discounts'
        DefineAllDiscountAccounts();
        LibrarySales.SetDiscountPosting(SalesSetup."Discount Posting"::"Invoice Discounts");
        // [GIVEN] Created the Invoice and one item line, where the posting setup is 'A'.
        CreateServiceInvoiceWithOneLine(ServiceLine);
        // [GIVEN] Gen. Posting Setup record 'A', where "Sales Inv Disc. Account" is blank.
        BlankServiceDiscAccount(GeneralPostingSetup, ServiceLine, GeneralPostingSetup.FieldNo("Sales Inv. Disc. Account"));
        // [GIVEN] Run "Calculate Invoice Discount" action
        GeneralPostingSetupPage.Trap();
        ServiceInvoicePage.OpenEdit();
        ServiceInvoicePage.FILTER.SetFilter("No.", ServiceLine."Document No.");
        ServiceInvoicePage."Calculate Invoice Discount".Invoke();

        // [WHEN] Notification: "G/L accounts for discounts are missing... | Open page |" and user click on 'Open page'
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'sent notification message');

        // [THEN] Gen. Posting Setup page is open, where is one record 'A'.
        VerifyGenPostingSetupInPage(GeneralPostingSetupPage, GeneralPostingSetup);
        // [THEN] "Invoice Discount Amount" is not 0
        ServiceLine.Find();
        Assert.AreNotEqual(0, ServiceLine."Inv. Discount Amount", 'Invoice Discount Amount');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationActionHandler')]
    [Scope('OnPrem')]
    procedure NotifyAboutMissingSalesSetupRespectsProductPostingGroup()
    var
        GeneralPostingSetup: array[2] of Record "General Posting Setup";
        SalesLine: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetupPage: TestPage "General Posting Setup";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 343954] User enters a line discount while there another posting setups, where line discount account is blank.
        Initialize();
        // [GIVEN] Sales Setup, where "Discount Posting" is 'Line Discounts'
        LibrarySales.SetDiscountPosting(SalesSetup."Discount Posting"::"Line Discounts");
        // [GIVEN] Gen. Posting Setups 'A' and 'B' where "Gen. Bus. Posting Group" is the same and "Sales Line Disc. Account" is blank.
        CreateGeneralPostingSetups(
          GeneralPostingSetup,
          GeneralPostingSetup[1].FieldNo("Sales Line Disc. Account"),
          GeneralPostingSetup[1].FieldNo("Sales Line Disc. Account"));
        GeneralPostingSetup[2].Validate("Gen. Bus. Posting Group", GeneralPostingSetup[1]."Gen. Bus. Posting Group");
        GeneralPostingSetup[2].Insert(true);
        // [GIVEN] Sales Order with Gen. Posting Setups 'A'.
        CreateSalesOrderWithOneLine(SalesLine, GeneralPostingSetup[1]."Gen. Bus. Posting Group", GeneralPostingSetup[1]."Gen. Prod. Posting Group");
        // [GIVEN] Entered new "Line Discount %" = 10.
        GeneralPostingSetupPage.Trap();
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesLine."Document No.");
        SalesOrder.SalesLines."Line Discount %".SetValue(LibraryRandom.RandInt(10));

        // [WHEN] Notification: "G/L accounts for discounts are missing... | Open page |" and user click on 'Open page'.
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'sent notification message');

        // [THEN] Gen. Posting Setup page is open, where is one record 'A'.
        VerifyGenPostingSetupInPage(GeneralPostingSetupPage, GeneralPostingSetup[1]);

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationActionHandler')]
    [Scope('OnPrem')]
    procedure NotifyAboutMissingPurchaseSetupRespectsProductPostingGroup()
    var
        GeneralPostingSetup: array[2] of Record "General Posting Setup";
        PurchLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetupPage: TestPage "General Posting Setup";
        PurchOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 343954] User enters a line discount while there are multiple posting setups, where line discount account is blank.
        Initialize();
        // [GIVEN] Purch Setup, where "Discount Posting" is 'Line Discounts'
        LibraryPurchase.SetDiscountPosting(PurchSetup."Discount Posting"::"Line Discounts");
        // [GIVEN] Gen. Posting Setups 'A' and 'B' where "Gen. Bus. Posting Group" is the same and "Purchase Line Disc. Account" is blank.
        CreateGeneralPostingSetups(
          GeneralPostingSetup,
          GeneralPostingSetup[1].FieldNo("Purch. Line Disc. Account"),
          GeneralPostingSetup[1].FieldNo("Purch. Line Disc. Account"));
        GeneralPostingSetup[2].Validate("Gen. Bus. Posting Group", GeneralPostingSetup[1]."Gen. Bus. Posting Group");
        GeneralPostingSetup[2].Insert(true);
        // [GIVEN] Purhcase Order with Gen. Posting Setups 'A'.
        CreatePurchOrderWithOneLine(PurchLine, GeneralPostingSetup[1]."Gen. Bus. Posting Group", GeneralPostingSetup[1]."Gen. Prod. Posting Group");
        // [GIVEN] Entered new "Qty. to Invoice = 1.
        GeneralPostingSetupPage.Trap();
        PurchOrder.OpenEdit();
        PurchOrder.Filter.SetFilter("No.", PurchLine."Document No.");
        PurchOrder.PurchLines."Qty. to Invoice".SetValue(PurchLine.Quantity - 1);

        // [WHEN] Notification: "G/L accounts for discounts are missing... | Open page |" and user click on 'Open page'.
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'sent notification message');

        // [THEN] Gen. Posting Setup page is open, where is one record 'A'.
        VerifyGenPostingSetupInPage(GeneralPostingSetupPage, GeneralPostingSetup[1]);

        LibraryNotificationMgt.RecallNotificationsForRecord(PurchSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationActionHandler')]
    [Scope('OnPrem')]
    procedure NotifyAboutMissingSalesSetupRespectsProductPostingGroupOnServiceLine()
    var
        GeneralPostingSetup: array[2] of Record "General Posting Setup";
        ServiceLine: Record "Service Line";
        SalesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetupPage: TestPage "General Posting Setup";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // [FEATURE] [Service] [UI]
        // [SCENARIO 343954] User enters a line discount while there another posting setups, where line discount account is blank.
        Initialize();
        // [GIVEN] Sales Setup, where "Discount Posting" is 'Line Discounts'
        LibrarySales.SetDiscountPosting(SalesSetup."Discount Posting"::"Line Discounts");
        // [GIVEN] Gen. Posting Setups 'A' and 'B' where "Gen. Bus. Posting Group" is the same and "Sales Line Disc. Account" is blank.
        CreateGeneralPostingSetups(
          GeneralPostingSetup,
          GeneralPostingSetup[1].FieldNo("Sales Line Disc. Account"),
          GeneralPostingSetup[1].FieldNo("Sales Line Disc. Account"));
        GeneralPostingSetup[2].Validate("Gen. Bus. Posting Group", GeneralPostingSetup[1]."Gen. Bus. Posting Group");
        GeneralPostingSetup[2].Insert(true);
        // [GIVEN] Service Invoice with Gen. Posting Setups 'A'.
        CreateServiceInvoiceWithOneLine(ServiceLine, GeneralPostingSetup[1]."Gen. Bus. Posting Group", GeneralPostingSetup[1]."Gen. Prod. Posting Group");
        // [GIVEN] Entered new "Line Discount %" = 10.
        GeneralPostingSetupPage.Trap();
        ServiceInvoice.OpenEdit();
        ServiceInvoice.Filter.SetFilter("No.", ServiceLine."Document No.");
        ServiceInvoice.ServLines."Line Discount %".SetValue(LibraryRandom.RandInt(10));

        // [WHEN] Notification: "G/L accounts for discounts are missing... | Open page |" and user click on 'Open page'.
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'sent notification message');

        // [THEN] Gen. Posting Setup page is open, where is one record 'A'.
        VerifyGenPostingSetupInPage(GeneralPostingSetupPage, GeneralPostingSetup[1]);

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Discount Setup Notifications");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Discount Setup Notifications");

        LibraryERM.SetEnableDataCheck(false);
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Discount Setup Notifications");
    end;

    local procedure AdjustGenPostingSetupOnGLAcc(AccNo: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GLAccount.Get(AccNo);
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        GLAccount."Gen. Bus. Posting Group" := GeneralPostingSetup."Gen. Bus. Posting Group";
        GLAccount."Gen. Prod. Posting Group" := GeneralPostingSetup."Gen. Prod. Posting Group";
        GLAccount.Modify();
        exit(AccNo);
    end;

    local procedure BlankPurchDiscAccount(var GeneralPostingSetup: Record "General Posting Setup"; PurchLine: Record "Purchase Line"; FieldNumber: Integer)
    begin
        GeneralPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        case FieldNumber of
            GeneralPostingSetup.FieldNo("Purch. Line Disc. Account"):
                GeneralPostingSetup."Purch. Line Disc. Account" := '';
            GeneralPostingSetup.FieldNo("Purch. Inv. Disc. Account"):
                GeneralPostingSetup."Purch. Inv. Disc. Account" := '';
        end;
        GeneralPostingSetup.Modify();
    end;

    local procedure BlankSalesDiscAccount(var GeneralPostingSetup: Record "General Posting Setup"; SalesLine: Record "Sales Line"; FieldNumber: Integer)
    begin
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        case FieldNumber of
            GeneralPostingSetup.FieldNo("Sales Line Disc. Account"):
                GeneralPostingSetup."Sales Line Disc. Account" := '';
            GeneralPostingSetup.FieldNo("Sales Inv. Disc. Account"):
                GeneralPostingSetup."Sales Inv. Disc. Account" := '';
        end;
        GeneralPostingSetup.Modify();
    end;

    local procedure BlankServiceDiscAccount(var GeneralPostingSetup: Record "General Posting Setup"; ServiceLine: Record "Service Line"; FieldNumber: Integer)
    begin
        GeneralPostingSetup.Get(ServiceLine."Gen. Bus. Posting Group", ServiceLine."Gen. Prod. Posting Group");
        case FieldNumber of
            GeneralPostingSetup.FieldNo("Sales Line Disc. Account"):
                GeneralPostingSetup."Sales Line Disc. Account" := '';
            GeneralPostingSetup.FieldNo("Sales Inv. Disc. Account"):
                GeneralPostingSetup."Sales Inv. Disc. Account" := '';
        end;
        GeneralPostingSetup.Modify();
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup"; BlankAccFieldNo: Integer): Text
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GLAccNo: Code[20];
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
        if BlankAccFieldNo > -1 then begin
            GLAccNo := LibraryERM.CreateGLAccountNo();
            if BlankAccFieldNo <> GeneralPostingSetup.FieldNo("Sales Inv. Disc. Account") then
                GeneralPostingSetup."Sales Inv. Disc. Account" := GLAccNo;
            if BlankAccFieldNo <> GeneralPostingSetup.FieldNo("Sales Line Disc. Account") then
                GeneralPostingSetup."Sales Line Disc. Account" := GLAccNo;
            if BlankAccFieldNo <> GeneralPostingSetup.FieldNo("Purch. Inv. Disc. Account") then
                GeneralPostingSetup."Purch. Inv. Disc. Account" := GLAccNo;
            if BlankAccFieldNo <> GeneralPostingSetup.FieldNo("Purch. Line Disc. Account") then
                GeneralPostingSetup."Purch. Line Disc. Account" := GLAccNo;
            GeneralPostingSetup.Modify();
        end;
        exit(Format(GeneralPostingSetup.RecordId));
    end;

    local procedure CreateGeneralPostingSetups(var GeneralPostingSetup: array[2] of Record "General Posting Setup"; BlankAccFieldNo1: Integer; BlankAccFieldNo2: Integer)
    begin
        DefineAllDiscountAccounts();
        CreateGeneralPostingSetup(GeneralPostingSetup[1], BlankAccFieldNo1);
        CreateGeneralPostingSetup(GeneralPostingSetup[2], BlankAccFieldNo2);
    end;

    local procedure CreatePurchInvoiceWithOneLine(var PurchLine: Record "Purchase Line")
    var
        PurchHeader: Record "Purchase Header";
        VendInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchHeader, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account",
          AdjustGenPostingSetupOnGLAcc(LibraryERM.CreateGLAccountWithPurchSetup()), 1);
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2) + 10);
        PurchLine."Allow Invoice Disc." := true;
        PurchLine.Modify();

        LibraryERM.CreateInvDiscForVendor(VendInvoiceDisc, PurchLine."Buy-from Vendor No.", '', 0);
        VendInvoiceDisc."Discount %" := 3 + LibraryRandom.RandInt(10);
        VendInvoiceDisc.Modify();
    end;

    local procedure CreatePurchOrderWithOneLine(var PurchLine: Record "Purchase Line"; GenBusPstGrp: Code[20]; GenProdPstGrpNo: Code[20])
    var
        Vendor: Record Vendor;
        GenProdPstGrp: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
        PurchHeader: Record "Purchase Header";
    begin
        GenProdPstGrp.Get(GenProdPstGrpNo);
        GenProdPstGrp.Validate("Auto Insert Default", false);
        GenProdPstGrp.Modify(true);
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPstGrpNo);
        GLAccount.Modify(true);
        Vendor.Get(LibraryPurchase.CreateVendorWithBusPostingGroups(GenBusPstGrp, GLAccount."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandInt(10));
        PurchLine.Validate("Unit Cost", LibraryRandom.RandInt(100));
        PurchLine.Modify(true);
    end;

    local procedure CreateSalesInvoiceWithOneLine(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          AdjustGenPostingSetupOnGLAcc(LibraryERM.CreateGLAccountWithSalesSetup()), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2) + 10);
        SalesLine."Allow Line Disc." := true;
        SalesLine."Allow Invoice Disc." := true;
        SalesLine.Modify();

        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, SalesLine."Sell-to Customer No.", '', 0);
        CustInvoiceDisc."Discount %" := 3 + LibraryRandom.RandInt(10);
        CustInvoiceDisc.Modify();
    end;

    local procedure CreateSalesOrderWithOneLine(var SalesLine: Record "Sales Line"; GenBusPstGrp: Code[20]; GenProdPstGrpNo: Code[20])
    var
        Customer: Record Customer;
        GenProdPstGrp: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
    begin
        GenProdPstGrp.Get(GenProdPstGrpNo);
        GenProdPstGrp.Validate("Auto Insert Default", false);
        GenProdPstGrp.Modify(true);
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPstGrpNo);
        GLAccount.Modify(true);
        Customer.Get(LibrarySales.CreateCustomerWithBusPostingGroups(GenBusPstGrp, GLAccount."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Modify(true);
    end;

    local procedure CreateServiceInvoiceWithOneLine(var ServiceLine: Record "Service Line"; GenBusPstGrp: Code[20]; GenProdPstGrpNo: Code[20])
    var
        Customer: Record Customer;
        GenProdPstGrp: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
        ServiceHeader: Record "Service Header";
    begin
        GenProdPstGrp.Get(GenProdPstGrpNo);
        GenProdPstGrp.Validate("Auto Insert Default", false);
        GenProdPstGrp.Modify(true);
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPstGrpNo);
        GLAccount.Modify(true);
        Customer.Get(LibrarySales.CreateCustomerWithBusPostingGroups(GenBusPstGrp, GLAccount."VAT Bus. Posting Group"));
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandInt(10));
        ServiceLine."Unit Price" := LibraryRandom.RandInt(100);
        ServiceLine."Allow Line Disc." := true;
        ServiceLine."Allow Invoice Disc." := true;
        ServiceLine.Modify();
    end;


    local procedure CreateServiceInvoiceWithOneLine(var ServiceLine: Record "Service Line")
    var
        ServiceHeader: Record "Service Header";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account",
          AdjustGenPostingSetupOnGLAcc(LibraryERM.CreateGLAccountWithSalesSetup()), 1);
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2) + 10);
        ServiceLine."Allow Line Disc." := true;
        ServiceLine."Allow Invoice Disc." := true;
        ServiceLine.Modify();

        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, ServiceHeader."Customer No.", '', 0);
        CustInvoiceDisc."Discount %" := 3 + LibraryRandom.RandInt(10);
        CustInvoiceDisc.Modify();
    end;

    local procedure DefineAllDiscountAccounts()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccNo: Code[20];
    begin
        Assert.RecordIsNotEmpty(GeneralPostingSetup);
        GLAccNo := LibraryERM.CreateGLAccountNo();
        GeneralPostingSetup.ModifyAll("Sales Inv. Disc. Account", GLAccNo);
        GeneralPostingSetup.ModifyAll("Sales Line Disc. Account", GLAccNo);
        GeneralPostingSetup.ModifyAll("Purch. Inv. Disc. Account", GLAccNo);
        GeneralPostingSetup.ModifyAll("Purch. Line Disc. Account", GLAccNo);
    end;

    local procedure ShowSalesNotificationForDiscountPosting(DiscountPosting: Option)
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        DefineAllDiscountAccounts();
        CreateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup.FieldNo("Sales Inv. Disc. Account"));
        LibrarySales.SetDiscountPosting(DiscountPosting); // Notification is shown
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'notification #1 message');
    end;

    local procedure ShowPurchNotificationForDiscountPosting(DiscountPosting: Option)
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        DefineAllDiscountAccounts();
        CreateGeneralPostingSetup(GeneralPostingSetup, GeneralPostingSetup.FieldNo("Purch. Inv. Disc. Account"));
        LibraryPurchase.SetDiscountPosting(DiscountPosting); // Notification is shown
        Assert.AreEqual(MissingDiscountAccountMsg, LibraryVariableStorage.DequeueText(), 'notification #1 message');
    end;

    local procedure VerifyGenPostingSetupInPage(GeneralPostingSetupPage: TestPage "General Posting Setup"; GeneralPostingSetup: Record "General Posting Setup")
    begin
        Assert.IsTrue(GeneralPostingSetupPage.First(), 'missing the 1st line');
        GeneralPostingSetupPage."Gen. Bus. Posting Group".AssertEquals(GeneralPostingSetup."Gen. Bus. Posting Group");
        GeneralPostingSetupPage."Gen. Prod. Posting Group".AssertEquals(GeneralPostingSetup."Gen. Prod. Posting Group");
        Assert.IsTrue(GeneralPostingSetupPage.Last(), 'missing the last line');
        GeneralPostingSetupPage."Gen. Bus. Posting Group".AssertEquals(GeneralPostingSetup."Gen. Bus. Posting Group");
        GeneralPostingSetupPage."Gen. Prod. Posting Group".AssertEquals(GeneralPostingSetup."Gen. Prod. Posting Group");
        GeneralPostingSetupPage.Close();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationActionHandler(var Notification: Notification): Boolean
    var
        DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
        DiscountNotificationMgt.ShowGenPostingSetupMissingDiscountAccounts(Notification); // simulate running Details action
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationSimpleHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

