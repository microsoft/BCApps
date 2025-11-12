codeunit 134299 "Test Partner Integration Event"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Integration Event] [UT]
    end;

    var
        BankAccount: Record "Bank Account";
        Assert: Codeunit Assert;
        ErrorEventSuscriptionErr: Label 'There are %1 events with error:%2.';
        InactiveEventSuscriptionErr: Label 'There are %1 inactive events:%2.';
        OnAfterCheckGenJnlLineTxt: Label 'OnAfterCheckGenJnlLine';
        OnBeforePostGenJnlLineTxt: Label 'OnBeforePostGenJnlLine';
        OnAfterInitGLRegisterTxt: Label 'OnAfterInitGLRegister';
        OnAfterInsertGlobalGLEntryTxt: Label 'OnAfterInsertGlobalGLEntry';
        OnBeforeInsertGLEntryBufferTxt: Label 'OnBeforeInsertGLEntryBuffer';
        LibraryJournals: Codeunit "Library - Journals";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryResource: Codeunit "Library - Resource";
        LibraryRandom: Codeunit "Library - Random";
        OnAfterCopyGLEntryFromGenJnlLineTxt: Label 'OnAfterCpyGLEntryFrmGenJnlLine';
        OnAfterCopyCustLedgerEntryFromGenJnlLineTxt: Label 'OnAfterCpyCustLedEntGenJnlLine';
        OnAfterCopyVendLedgerEntryFromGenJnlLineTxt: Label 'OnAfterCpyVendLedEntGenJnlLine';
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        OnAfterCheckItemJnlLineTxt: Label 'OnAfterCheckItemJnlLine';
        OnBeforeReleaseSalesDocTxt: Label 'OnBeforeReleaseSalesDoc';
        OnAfterReleaseSalesDocTxt: Label 'OnAfterReleaseSalesDoc';
        OnBeforeReopenSalesDocTxt: Label 'OnBeforeReopenSalesDoc';
        OnAfterReopenSalesDocTxt: Label 'OnAfterReopenSalesDoc';
        OnBeforeReleasePurchaseDocTxt: Label 'OnBeforeReleasePurchaseDoc';
        OnAfterReleasePurchaseDocTxt: Label 'OnAfterReleasePurchaseDoc';
        OnBeforeReopenPurchaseDocTxt: Label 'OnBeforeReopenPurchaseDoc';
        OnAfterReopenPurchaseDocTxt: Label 'OnAfterReopenPurchaseDoc';
        OnBeforeManualReleaseSalesDocTxt: Label 'OnBeforeManualReleaseSalesDoc';
        OnAfterManualReleaseSalesDocTxt: Label 'OnAfterManualReleaseSalesDoc';
        OnBeforeManualReopenSalesDocTxt: Label 'OnBeforeManualReopenSalesDoc';
        OnAfterManualReopenSalesDocTxt: Label 'OnAfterManualReopenSalesDoc';
        OnBeforeManualReleasePurchaseDocTxt: Label 'OnBeforeManualReleasePurchaseDoc';
        OnAfterManualReleasePurchaseDocTxt: Label 'OnAfterManualReleasePurchaseDoc';
        OnBeforeManualReopenPurchaseDocTxt: Label 'OnBeforeManualReopenPurchaseDoc';
        OnAfterManualReopenPurchaseDocTxt: Label 'OnAfterManualReopenPurchaseDoc';
        OnBeforePostSalesDocTxt: Label 'OnBeforePostSalesDoc';
        OnBeforePostCommitSalesDocTxt: Label 'OnBeforePostCommitSalesDoc';
        OnAfterPostSalesDocTxt: Label 'OnAfterPostSalesDoc';
        OnBeforePostPurchaseDocTxt: Label 'OnBeforePostPurchaseDoc';
        OnBeforePostCommitPurchaseDocTxt: Label 'OnBeforePostCommitPurchaseDoc';
        OnAfterPostPurchaseDocTxt: Label 'OnAfterPostPurchaseDoc';
        OnBeforeCalcSalesDiscountTxt: Label 'OnBeforeCalcSalesDiscount';
        OnAfterCalcSalesDiscountTxt: Label 'OnAfterCalcSalesDiscount';
        OnBeforeCalcPurchaseDiscountTxt: Label 'OnBeforeCalcPurchaseDiscount';
        OnAfterCalcPurchaseDiscountTxt: Label 'OnAfterCalcPurchaseDiscount';
        OnBeforeInsertTransferEntryTxt: Label 'OnBeforeInsertTransferEntry';
        OnAfterInitItemLedgEntryTxt: Label 'OnAfterInitItemLedgEntry';
        OnAfterInsertItemLedgEntryTxt: Label 'OnAfterInsertItemLedgEntry';
        OnBeforeInsertValueEntryTxt: Label 'OnBeforeInsertValueEntry';
        OnAfterInsertValueEntryTxt: Label 'OnAfterInsertValueEntry';
        OnBeforeInsertCorrItemLedgEntryTxt: Label 'OnBeforeInsertCorrItemLedgEntr';
        OnAfterInsertCorrItemLedgEntryTxt: Label 'OnAfterInsertCorrItemLedgEntry';
        OnBeforeInsertCorrValueEntryTxt: Label 'OnBeforeInsertCorrValueEntry';
        OnAfterInsertCorrValueEntryTxt: Label 'OnAfterInsertCorrValueEntry';
        OnBeforePostItemJnlLineTxt: Label 'OnBeforePostItemJnlLine';
        OnAfterPostItemJnlLineTxt: Label 'OnAfterPostItemJnlLine';
        OnAfterNavigateFindRecordsTxt: Label 'OnAfterNavigateFindRecords';
#if not CLEAN25
        OnAfterNavigateShowRecordsTxt: Label 'OnAfterNavigateShowRecords';
#endif
        OnAfterCheckMandatoryFieldsTxt: Label 'OnAfterCheckMandatoryFields';
        OnAfterUpdatePostingNosTxt: Label 'OnAfterUpdatePostingNos';
        OnAfterSalesInvLineInsertTxt: Label 'OnAfterSalesInvLineInsert';
        OnAfterSalesCrMemoLineInsertTxt: Label 'OnAfterSalesCrMemoLineInsert';
        OnAfterPurchInvLineInsertTxt: Label 'OnAfterPurchInvLineInsert';
        OnAfterPurchCrMemoLineInsertTxt: Label 'OnAfterPurchCrMemoLineInsert';
        OnPostBalancingEntryOnBeforeGenJnlPostLineTxt: Label 'OnPostBalancingEntryOnBeforeGenJnlPostLine';
        OnPostLedgerEntryOnBeforeGenJnlPostLineTxt: Label 'OnPostLedgerEntryOnBeforeGenJnlPostLine';
        OnPostLinesOnBeforeGenJnlLinePostTxt: Label 'OnPostLinesOnBeforeGenJnlLinePost';
        OnBeforeSalesInvHeaderInsertTxt: Label 'OnBeforeSalesInvHeaderInsert';
        OnBeforeSalesInvLineInsertTxt: Label 'OnBeforeSalesInvLineInsert';
        OnBeforeSalesShptHeaderInsertTxt: Label 'OnBeforeSalesShptHeaderInsert';
        OnBeforeSalesShptLineInsertTxt: Label 'OnBeforeSalesShptLineInsert';
        OnBeforeSalesCrMemoHeaderInsertTxt: Label 'OnBeforeSalesCrMemoHeaderInsert';
        OnBeforeSalesCrMemoLineInsertTxt: Label 'OnBeforeSalesCrMemoLineInsert';
        OnBeforeReturnRcptHeaderInsertTxt: Label 'OnBeforeReturnRcptHeaderInsert';
        OnBeforeReturnRcptLineInsertTxt: Label 'OnBeforeReturnRcptLineInsert';
        OnBeforePurchInvHeaderInsertTxt: Label 'OnBeforePurchInvHeaderInsert';
        OnBeforePurchInvLineInsertTxt: Label 'OnBeforePurchInvLineInsert';
        OnBeforePurchRcptHeaderInsertTxt: Label 'OnBeforePurchShptHeaderInsert';
        OnBeforePurchRcptLineInsertTxt: Label 'OnBeforePurchShptLineInsert';
        OnBeforePurchCrMemoHeaderInsertTxt: Label 'OnBeforePurchCrMemoHeaderInsert';
        OnBeforePurchCrMemoLineInsertTxt: Label 'OnBeforePurchCrMemoLineInsert';
        OnBeforeReturnShptHeaderInsertTxt: Label 'OnBeforeReturnShptHeaderInsert';
        OnBeforeReturnShptLineInsertTxt: Label 'OnBeforeReturnShptLineInsert';
        OnAfterCopyGenJnlLineFromPrepmtInvBufferTxt: Label 'OnAfterCopyGenJnlLineFromPrepmtInvBuffer';
        OnAfterCopyGenJnlLineFromPurchHeaderTxt: Label 'OnAfterCopyGenJnlLineFromPurchHeader';
        OnAfterCopyGenJnlLineFromSalesHeaderTxt: Label 'OnAfterCopyGenJnlLineFromSalesHeader';
        OnAfterAccountNoOnValidateGetGLAccountTxt: Label 'OnAfterAccountNoOnValidateGetGLAccount';
        OnAfterAccountNoOnValidateGetBankAccountTxt: Label 'OnAfterAccountNoOnValidateGetBankAccount';
        OnAfterAccountNoOnValidateGetCustomerAccountTxt: Label 'OnAfterAccountNoOnValidateGetCustomerAccount';
        OnAfterAccountNoOnValidateGetVendorAccountTxt: Label 'OnAfterAccountNoOnValidateGetVendorAccount';
        OnAfterAccountNoOnValidateGetFAAccountTxt: Label 'OnAfterAccountNoOnValidateGetFAAccount';
        OnAfterAccountNoOnValidateGetGLBalAccountTxt: Label 'OnAfterAccountNoOnValidateGetGLBalAccount';
        OnAfterAccountNoOnValidateGetBankBalAccountTxt: Label 'OnAfterAccountNoOnValidateGetBankBalAccount';
        OnAfterAccountNoOnValidateGetCustomerBalAccountTxt: Label 'OnAfterAccountNoOnValidateGetCustomerBalAccount';
        OnAfterAccountNoOnValidateGetVendorBalAccountTxt: Label 'OnAfterAccountNoOnValidateGetVendorBalAccount';
        OnAfterAccountNoOnValidateGetFABalAccountTxt: Label 'OnAfterAccountNoOnValidateGetFABalAccount';
        OnAfterInitRecordTxt: Label 'OnAfterInitRecord';
        OnAfterInitNoSeriesTxt: Label 'OnAfterInitNoSeries';
        OnAfterTestNoSeriesTxt: Label 'OnAfterTestNoSeries';
        OnAfterUpdateShipToAddressTxt: Label 'OnAfterUpdateShipToAddress';
        OnAfterAssignHeaderValuesTxt: Label 'OnAfterAssignHeaderValues';
        OnAfterAssignStdTxtValuesTxt: Label 'OnAfterAssignStdTxtValues';
        OnAfterAssignGLAccountValuesTxt: Label 'OnAfterAssignGLAccountValues';
        OnAfterAssignItemValuesTxt: Label 'OnAfterAssignItemValues';
        OnAfterAssignItemChargeValuesTxt: Label 'OnAfterAssignItemChargeValues';
        OnAfterAssignFixedAssetValuesTxt: Label 'OnAfterAssignFixedAssetValues';
        OnAfterAssignResourceValuesTxt: Label 'OnAfterAssignResourceValues';
        OnAfterUpdateDirectUnitCostTxt: Label 'OnAfterUpdateDirectUnitCost';
        OnBeforeUpdateDirectUnitCostTxt: Label 'OnBeforeUpdateDirectUnitCost';
        OnAfterInitOutstandingAmountTxt: Label 'OnAfterInitOutstandingAmount';
        OnAfterInitQtyToInvoiceTxt: Label 'OnAfterInitQtyToInvoice';
        OnAfterInitQtyToShipTxt: Label 'OnAfterInitQtyToShip';
        OnAfterInitQtyToReceiveTxt: Label 'OnAfterInitQtyToReceive';
        OnAfterUpdateUnitCostTxt: Label 'OnAfterUpdateUnitCost';
        OnAfterUpdateJobPricesTxt: Label 'OnAfterUpdateJobPrices';
        OnAfterUpdateUnitPriceTxt: Label 'OnAfterUpdateUnitPrice';
        OnBeforeUpdateUnitPriceTxt: Label 'OnBeforeUpdateUnitPrice';
        OnSetBookingItemInvoicedTxt: Label 'OnSetBookingItemInvoiced';
        OnBeforeGetAttachmentFileNameTxt: Label 'OnBeforeGetAttachmentFileName';

    [Scope('OnPrem')]
    procedure Initialize()
    var
        DataTypeBuffer: Record "Data Type Buffer";
    begin
        DataTypeBuffer.DeleteAll(true);

        if IsInitialized then
            exit;

        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERMCountryData.InitializeCountry();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        IsInitialized := true;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAllSubscriptionsAreActive()
    var
        EventSubscription: Record "Event Subscription";
        InactiveSubscribers: Text;
        InactiveEventsCounter: Integer;
    begin
        // [SCENARIO] All existing event subscribtions should be Active, meaning all Publisher-Subscriber signatures are matched
        EventSubscription.SetRange(Active, false);
        InactiveEventsCounter := EventSubscription.Count;
        if EventSubscription.FindSet() then
            repeat
                InactiveSubscribers += StrSubstNo(' %1.%2', EventSubscription."Subscriber Codeunit ID", EventSubscription."Subscriber Function");
            until EventSubscription.Next() = 0;
        if InactiveEventsCounter > 0 then
            Error(InactiveEventSuscriptionErr, InactiveEventsCounter, InactiveSubscribers);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubscriptionTableHasNoErrors()
    var
        EventSubscription: Record "Event Subscription";
        SubscribersWithError: Text;
        ErrorEventsCounter: Integer;
    begin
        // [SCENARIO] All existing event subscribtions should have a blank "Error Information"
        EventSubscription.SetFilter("Error Information", '<>%1', '');
        ErrorEventsCounter := EventSubscription.Count;
        if EventSubscription.FindSet() then
            repeat
                SubscribersWithError += StrSubstNo(' %1.%2="%3"', EventSubscription."Subscriber Codeunit ID", EventSubscription."Subscriber Function", EventSubscription."Error Information");
            until EventSubscription.Next() = 0;
        if ErrorEventsCounter > 0 then
            Error(ErrorEventSuscriptionErr, ErrorEventsCounter, SubscribersWithError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterCheckGenJnlLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Gen. Jnl.-Check Line" will trigger the integration event OnAfterGenJournalCheckLine.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateGenJournalLineForBank(GenJournalLine);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Check Line", GenJournalLine);

        // Verify
        VerifyDataTypeBuffer(OnAfterCheckGenJnlLineTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforePostGenJnlLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Gen. Jnl.-Post Line" will trigger the integration event OnBeforeGenJournalLinePost.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateGenJournalLineForBank(GenJournalLine);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Line", GenJournalLine);

        // Verify
        VerifyDataTypeBuffer(OnBeforePostGenJnlLineTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnValidateGenJnlLineAccountNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Gen. Jnl.-Post Line" will trigger the integration event OnBeforeGenJournalLinePost.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);

        // G/L Account
        CreateGenJournalLineForGLAcc(GenJournalLine);
        VerifyDataTypeBuffer(OnAfterAccountNoOnValidateGetGLAccountTxt);

        // Bank Account
        CreateGenJournalLineForBank(GenJournalLine);
        VerifyDataTypeBuffer(OnAfterAccountNoOnValidateGetBankAccountTxt);

        // Customer
        CreateGenJournalLineForCustomer(GenJournalLine);
        VerifyDataTypeBuffer(OnAfterAccountNoOnValidateGetCustomerAccountTxt);

        // Customer
        CreateGenJournalLineForVendor(GenJournalLine);
        VerifyDataTypeBuffer(OnAfterAccountNoOnValidateGetVendorAccountTxt);

        // Fixed Asset
        CreateGenJournalLineForFA(GenJournalLine);
        VerifyDataTypeBuffer(OnAfterAccountNoOnValidateGetFAAccountTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnValidateGenJnlLineBalAccountNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FixedAsset: Record "Fixed Asset";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Gen. Jnl.-Post Line" will trigger the integration event OnBeforeGenJournalLinePost.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateGenJournalLineForGLAcc(GenJournalLine);

        // G/L Account
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        VerifyDataTypeBuffer(OnAfterAccountNoOnValidateGetGLBalAccountTxt);

        // Bank Account
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateBankAccountNo());
        VerifyDataTypeBuffer(OnAfterAccountNoOnValidateGetBankBalAccountTxt);

        // Customer
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::Customer);
        GenJournalLine.Validate("Bal. Account No.", LibrarySales.CreateCustomerNo());
        VerifyDataTypeBuffer(OnAfterAccountNoOnValidateGetCustomerBalAccountTxt);

        // Vendor
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::Vendor);
        GenJournalLine.Validate("Bal. Account No.", LibraryPurchase.CreateVendorNo());
        VerifyDataTypeBuffer(OnAfterAccountNoOnValidateGetVendorBalAccountTxt);

        // Fixed Asset
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Fixed Asset");
        GenJournalLine.Validate("Bal. Account No.", FixedAsset."No.");
        VerifyDataTypeBuffer(OnAfterAccountNoOnValidateGetFABalAccountTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterInitGLRegister()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Gen. Jnl.-Post Line" will trigger the integration event OnAfterGLRegisterInit.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateGenJournalLineForBank(GenJournalLine);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Line", GenJournalLine);

        // Verify
        VerifyDataTypeBuffer(OnAfterInitGLRegisterTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterInsertGlobalGLEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Gen. Jnl.-Post Line" will trigger the integration event OnAfterGlobalGLEntryInsert.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateGenJournalLineForBank(GenJournalLine);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Line", GenJournalLine);

        // Verify
        VerifyDataTypeBuffer(OnAfterInsertGlobalGLEntryTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforeInsertGLEntryBuffer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Gen. Jnl.-Post Line" will trigger the integration event OnBeforeGLEntryBufferInsert.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateGenJournalLineForBank(GenJournalLine);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Line", GenJournalLine);

        // Verify
        VerifyDataTypeBuffer(OnBeforeInsertGLEntryBufferTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterCopyGLEntryFromGenJnlLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Gen. Jnl.-Post Line" will trigger the integration event OnAfterCopyGLEntryFromGenJnlLine.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateGenJournalLineForBank(GenJournalLine);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Line", GenJournalLine);

        // Verify
        VerifyDataTypeBuffer(OnAfterCopyGLEntryFromGenJnlLineTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterCopyCustLedgerEntryFromGenJnlLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Gen. Jnl.-Post Line" will trigger the integration event OnAfterCopyCustLedgerEntryFromGenJnlLine.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateGenJournalLineForCustomer(GenJournalLine);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Line", GenJournalLine);

        // Verify
        VerifyDataTypeBuffer(OnAfterCopyCustLedgerEntryFromGenJnlLineTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterCopyVendLegderEntryFromGenJnlLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Gen. Jnl.-Post Line" will trigger the integration event OnAfterCopyVendLedgerEntryFromGenJnlLine.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateGenJournalLineForVendor(GenJournalLine);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Line", GenJournalLine);

        // Verify
        VerifyDataTypeBuffer(OnAfterCopyVendLedgerEntryFromGenJnlLineTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterCheckItemJnlLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Item Jnl.-Check Line" will trigger the integration event OnAfterItemJnlCheckLine.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Check Line", ItemJournalLine);

        // Verify
        VerifyDataTypeBuffer(OnAfterCheckItemJnlLineTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforeManualReleaseSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
    begin
        // [SCENARIO] Calling the codeunit "Release Sales Document" will trigger the integration event OnBeforeReleaseSalesDoc.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateSalesInvoice(SalesHeader);

        // Exercise
        ReleaseSalesDocument.PerformManualRelease(SalesHeader);

        // Verify
        VerifyDataTypeBuffer(OnBeforeManualReleaseSalesDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforeReleaseSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Release Sales Document" will trigger the integration event OnBeforeReleaseSalesDoc.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateSalesInvoice(SalesHeader);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Release Sales Document", SalesHeader);

        // Verify
        VerifyDataTypeBuffer(OnBeforeReleaseSalesDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterReleaseSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Release Sales Document" will trigger the integration event OnAfterReleaseSalesDoc.

        // Setup
        Initialize();

        BindSubscription(TestPartnerIntegrationEvent);
        CreateSalesInvoice(SalesHeader);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Release Sales Document", SalesHeader);

        // Verify
        VerifyDataTypeBuffer(OnAfterReleaseSalesDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterManualReleaseSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
    begin
        // [SCENARIO] Calling the codeunit "Release Sales Document" will trigger the integration event OnAfterReleaseSalesDoc.

        // Setup
        Initialize();

        BindSubscription(TestPartnerIntegrationEvent);
        CreateSalesInvoice(SalesHeader);

        // Exercise
        ReleaseSalesDocument.PerformManualRelease(SalesHeader);

        // Verify
        VerifyDataTypeBuffer(OnAfterManualReleaseSalesDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforeManualReopenSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the reopen function in the codeunit "Release Sales Document" will trigger the integration event OnBeforeReopenSalesDoc.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateSalesInvoice(SalesHeader);
        ReleaseSalesDocument.PerformManualRelease(SalesHeader);

        // Exercise
        ReleaseSalesDocument.PerformManualReopen(SalesHeader);

        // Verify
        VerifyDataTypeBuffer(OnBeforeManualReopenSalesDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforeReopenSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the reopen function in the codeunit "Release Sales Document" will trigger the integration event OnBeforeReopenSalesDoc.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateSalesInvoice(SalesHeader);
        ReleaseSalesDocument.PerformManualRelease(SalesHeader);

        // Exercise
        ReleaseSalesDocument.Reopen(SalesHeader);

        // Verify
        VerifyDataTypeBuffer(OnBeforeReopenSalesDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterReopenSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the reopen function in the codeunit "Release Sales Document" will trigger the integration event OnAfterReopenSalesDoc.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateSalesInvoice(SalesHeader);
        ReleaseSalesDocument.PerformManualRelease(SalesHeader);

        // Exercise
        ReleaseSalesDocument.Reopen(SalesHeader);

        // Verify
        VerifyDataTypeBuffer(OnAfterReopenSalesDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterManualReopenSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the reopen function in the codeunit "Release Sales Document" will trigger the integration event OnAfterReopenSalesDoc.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateSalesInvoice(SalesHeader);
        ReleaseSalesDocument.PerformManualRelease(SalesHeader);

        // Exercise
        ReleaseSalesDocument.PerformManualReopen(SalesHeader);

        // Verify
        VerifyDataTypeBuffer(OnAfterManualReopenSalesDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforeManualReleasePurchaseDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
    begin
        // [SCENARIO] Calling the codeunit "Release Purchase Document" will trigger the integration event OnBeforeReleasePurchaseDoc.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseInvoice(PurchaseHeader);

        // Exercise
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);

        // Verify
        VerifyDataTypeBuffer(OnBeforeManualReleasePurchaseDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforeReleasePurchaseDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Release Purchase Document" will trigger the integration event OnBeforeReleasePurchaseDoc.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseInvoice(PurchaseHeader);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Release Purchase Document", PurchaseHeader);

        // Verify
        VerifyDataTypeBuffer(OnBeforeReleasePurchaseDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterReleasePurchaseDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Release Purchase Document" will trigger the integration event OnAfterReleasePurchaseDoc.

        // Setup
        Initialize();

        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseInvoice(PurchaseHeader);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Release Purchase Document", PurchaseHeader);

        // Verify
        VerifyDataTypeBuffer(OnAfterReleasePurchaseDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterManualReleasePurchaseDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
    begin
        // [SCENARIO] Calling the codeunit "Release Purchase Document" will trigger the integration event OnAfterReleasePurchaseDoc.

        // Setup
        Initialize();

        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseInvoice(PurchaseHeader);

        // Exercise
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);

        // Verify
        VerifyDataTypeBuffer(OnAfterManualReleasePurchaseDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforeManualReopenPurchaseDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the reopen function in the codeunit "Release Purchase Document" will trigger the integration event OnBeforeReopenPurchaseDoc.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseInvoice(PurchaseHeader);
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);

        // Exercise
        ReleasePurchaseDocument.PerformManualReopen(PurchaseHeader);

        // Verify
        VerifyDataTypeBuffer(OnBeforeManualReopenPurchaseDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforeReopenPurchaseDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the reopen function in the codeunit "Release Purchase Document" will trigger the integration event OnBeforeReopenPurchaseDoc.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseInvoice(PurchaseHeader);
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);

        // Exercise
        ReleasePurchaseDocument.Reopen(PurchaseHeader);

        // Verify
        VerifyDataTypeBuffer(OnBeforeReopenPurchaseDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterReopenPurchaseDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the reopen function in the codeunit "Release Purchase Document" will trigger the integration event OnAfterReopenPurchaseDoc.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseInvoice(PurchaseHeader);
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);

        // Exercise
        ReleasePurchaseDocument.Reopen(PurchaseHeader);

        // Verify
        VerifyDataTypeBuffer(OnAfterReopenPurchaseDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterManualReopenPurchaseDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the reopen function in the codeunit "Release Purchase Document" will trigger the integration event OnAfterReopenPurchaseDoc.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseInvoice(PurchaseHeader);
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);

        // Exercise
        ReleasePurchaseDocument.PerformManualReopen(PurchaseHeader);

        // Verify
        VerifyDataTypeBuffer(OnAfterManualReopenPurchaseDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforePostSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Sales-Post" will trigger the integration event OnBeforeSalesDocPost.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateSalesInvoice(SalesHeader);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        // Verify
        VerifyDataTypeBuffer(OnBeforePostSalesDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforePostCommitSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Sales-Post" will trigger the integration event OnBeforeSalesDocPostCommit.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateSalesInvoice(SalesHeader);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        // Verify
        VerifyDataTypeBuffer(OnBeforePostCommitSalesDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterPostSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Sales-Post" will trigger the integration event OnAfterSalesDocPost.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateSalesInvoice(SalesHeader);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        // Verify
        VerifyDataTypeBuffer(OnAfterPostSalesDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterCheckMandatoryFieldsSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Sales-Post" will trigger the integration event OnAfterCheckMandatoryFieldsTxt.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateSalesInvoice(SalesHeader);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        // Verify
        VerifyDataTypeBuffer(OnAfterCheckMandatoryFieldsTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterUpdatePostingNosSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Sales-Post" will trigger the integration event OnAfterUpdatePostingNos.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateSalesInvoice(SalesHeader);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        // Verify
        VerifyDataTypeBuffer(OnAfterUpdatePostingNosTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforePostEntriesSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        PaymentMethod: Record "Payment Method";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Sales-Post" will trigger the integration events
        // OnBeforePostBalancingEntryTxt, OnPostLedgerEntryOnBeforeGenJnlPostLineTxt, OnBeforePostInvPostBufferTxt

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateSalesInvoice(SalesHeader);
        LibraryERM.CreatePaymentMethodWithBalAccount(PaymentMethod);
        SalesHeader.Validate("Payment Method Code", PaymentMethod.Code);
        SalesHeader.Modify();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        // Verify G/L posting events
        VerifyDataTypeBuffer(OnPostLedgerEntryOnBeforeGenJnlPostLineTxt);
        VerifyDataTypeBuffer(OnPostLinesOnBeforeGenJnlLinePostTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnInsertSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Sales-Post" will trigger the integration event OnBeforeSalesInvHeaderInsert.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateSalesInvoice(SalesHeader);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        // Verify
        VerifyDataTypeBuffer(OnBeforeSalesInvHeaderInsertTxt);
        VerifyDataTypeBuffer(OnBeforeSalesInvLineInsertTxt);
        VerifyDataTypeBuffer(OnAfterSalesInvLineInsertTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnInsertSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Sales-Post" will trigger the integration event OnBeforeSalesCrMemoHeaderInsert.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateSalesCrMemo(SalesHeader);

        // Exercise
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify
        VerifyDataTypeBuffer(OnBeforeSalesCrMemoHeaderInsertTxt);
        VerifyDataTypeBuffer(OnBeforeSalesCrMemoLineInsertTxt);
        VerifyDataTypeBuffer(OnAfterSalesCrMemoLineInsertTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnInsertSalesShipment()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Sales-Post" will trigger the integration event OnBeforeSalesShptHeaderInsert.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateSalesOrder(SalesHeader);

        // Exercise
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Verify
        VerifyDataTypeBuffer(OnBeforeSalesShptHeaderInsertTxt);
        VerifyDataTypeBuffer(OnBeforeSalesShptLineInsertTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnInsertSalesReturn()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Sales-Post" will trigger the integration event OnAfterUpdatePostingNos.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateSalesReturn(SalesHeader);

        // Exercise
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify
        VerifyDataTypeBuffer(OnAfterInitQtyToReceiveTxt);
        VerifyDataTypeBuffer(OnBeforeReturnRcptHeaderInsertTxt);
        VerifyDataTypeBuffer(OnBeforeReturnRcptLineInsertTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnCreateSalesDocument()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Create Sales Invoice will trigger the integration events in Sales Header/Line tables.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);

        // Exercise
        CreateSalesInvoice(SalesHeader);

        // Verify
        VerifyDataTypeBuffer(OnAfterInitRecordTxt);
        VerifyDataTypeBuffer(OnAfterTestNoSeriesTxt);
        VerifyDataTypeBuffer(OnAfterUpdateShipToAddressTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAssignSalesLineNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        StandardText: Record "Standard Text";
        FixedAsset: Record "Fixed Asset";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Assign field No. in Sales Line will trigger the integration events per line type.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);

        // Exercise
        CreateSalesHeaderAndLine(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesLine.Validate(Type, SalesLine.Type::" ");
        SalesLine.Validate("No.", LibrarySales.CreateStandardText(StandardText));
        SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
        SalesLine.Validate("No.", LibraryERM.CreateGLAccountWithSalesSetup());
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", LibraryInventory.CreateItemNo());
        SalesLine.Validate(Type, SalesLine.Type::"Charge (Item)");
        SalesLine.Validate("No.", LibraryInventory.CreateItemChargeNo());
        SalesLine.Validate(Type, SalesLine.Type::"Fixed Asset");
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        SalesLine.Validate("No.", FixedAsset."No.");
        SalesLine.Validate(Type, SalesLine.Type::Resource);
        SalesLine.Validate("No.", LibraryResource.CreateResourceNo());

        // Verify
        VerifyDataTypeBuffer(OnAfterAssignHeaderValuesTxt);
        VerifyDataTypeBuffer(OnAfterAssignStdTxtValuesTxt);
        VerifyDataTypeBuffer(OnAfterAssignGLAccountValuesTxt);
        VerifyDataTypeBuffer(OnAfterAssignItemValuesTxt);
        VerifyDataTypeBuffer(OnAfterAssignItemChargeValuesTxt);
        VerifyDataTypeBuffer(OnAfterAssignFixedAssetValuesTxt);
        VerifyDataTypeBuffer(OnAfterAssignResourceValuesTxt);

        VerifyDataTypeBuffer(OnAfterInitOutstandingAmountTxt);
        VerifyDataTypeBuffer(OnAfterInitQtyToInvoiceTxt);
        VerifyDataTypeBuffer(OnAfterInitQtyToShipTxt);

        VerifyDataTypeBuffer(OnBeforeUpdateUnitPriceTxt);
        VerifyDataTypeBuffer(OnAfterUpdateUnitPriceTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforePostPurchaseDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Purch.-Post" will trigger the integration event OnBeforePurchaseDocPost.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseInvoice(PurchaseHeader);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Purch.-Post", PurchaseHeader);

        // Verify
        VerifyDataTypeBuffer(OnBeforePostPurchaseDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforePostCommitPurchaseDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Purch.-Post" will trigger the integration event OnBeforePurchaseDocPostCommit.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseInvoice(PurchaseHeader);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Purch.-Post", PurchaseHeader);

        // Verify
        VerifyDataTypeBuffer(OnBeforePostCommitPurchaseDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterPostPurchaseDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Purch.-Post" will trigger the integration event OnAfterPurchaseDocPost.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseInvoice(PurchaseHeader);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Purch.-Post", PurchaseHeader);

        // Verify
        VerifyDataTypeBuffer(OnAfterPostPurchaseDocTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterCheckMandatoryFieldsPurchDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Purch.-Post" will trigger the integration event OnAfterCheckMandatoryFieldsTxt.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseInvoice(PurchaseHeader);

        // Exercise
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify
        VerifyDataTypeBuffer(OnAfterCheckMandatoryFieldsTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterUpdatePostingNosPurchDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Purch.-Post" will trigger the integration event OnAfterUpdatePostingNos.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseInvoice(PurchaseHeader);

        // Exercise
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify
        VerifyDataTypeBuffer(OnAfterUpdatePostingNosTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforePostEntriesPurchDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        PaymentMethod: Record "Payment Method";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Purch.-Post" will trigger the integration events
        // OnBeforePostBalancingEntryTxt, OnBeforePostCustomerEntryTxt, OnBeforePostInvPostBufferTxt

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseInvoice(PurchaseHeader);
        LibraryERM.CreatePaymentMethodWithBalAccount(PaymentMethod);
        PurchaseHeader.Validate("Payment Method Code", PaymentMethod.Code);
        PurchaseHeader.Modify();

        // Exercise
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify G/L posting events
        VerifyDataTypeBuffer(OnPostLedgerEntryOnBeforeGenJnlPostLinetxt);
        VerifyDataTypeBuffer(OnPostLinesOnBeforeGenJnlLinePostTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnInsertPurchInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Sales-Post" will trigger the integration event OnBeforeSalesInvHeaderInsert.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseInvoice(PurchaseHeader);

        // Exercise
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // Verify
        VerifyDataTypeBuffer(OnBeforePurchInvHeaderInsertTxt);
        VerifyDataTypeBuffer(OnBeforePurchInvLineInsertTxt);
        VerifyDataTypeBuffer(OnAfterPurchInvLineInsertTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnInsertPurchCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Purch.-Post" will trigger the integration event OnBeforeSalesCrMemoHeaderInsert.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseCrMemo(PurchaseHeader);

        // Exercise
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify
        VerifyDataTypeBuffer(OnBeforePurchCrMemoHeaderInsertTxt);
        VerifyDataTypeBuffer(OnBeforePurchCrMemoLineInsertTxt);
        VerifyDataTypeBuffer(OnAfterPurchCrMemoLineInsertTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnInsertPurchReceipt()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Purch.-Post" will trigger the integration event OnBeforeSalesShptHeaderInsert.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseOrder(PurchaseHeader);

        // Exercise
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Verify
        VerifyDataTypeBuffer(OnBeforePurchRcptHeaderInsertTxt);
        VerifyDataTypeBuffer(OnBeforePurchRcptLineInsertTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnInsertPurchReturn()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Sales-Post" will trigger the integration event OnAfterUpdatePostingNos.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseReturn(PurchaseHeader);

        // Exercise
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify
        VerifyDataTypeBuffer(OnAfterInitQtyToShipTxt);
        VerifyDataTypeBuffer(OnBeforeReturnShptHeaderInsertTxt);
        VerifyDataTypeBuffer(OnBeforeReturnShptLineInsertTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnCreatePurchDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Create Purchase Invoice will trigger the integration events in Sales Header/Line tables.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);

        // Exercise
        CreatePurchaseInvoice(PurchaseHeader);

        // Verify
        VerifyDataTypeBuffer(OnAfterInitRecordTxt);
        VerifyDataTypeBuffer(OnAfterTestNoSeriesTxt);
        VerifyDataTypeBuffer(OnAfterUpdateShipToAddressTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAssignPurchLineNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        StandardText: Record "Standard Text";
        FixedAsset: Record "Fixed Asset";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Assign field No. in Purchase Line will trigger the integration events per line type.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);

        // Exercise
        CreatePurchaseHeaderAndLine(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);
        PurchaseLine.Validate(Type, PurchaseLine.Type::" ");
        PurchaseLine.Validate("No.", LibrarySales.CreateStandardText(StandardText));
        PurchaseLine.Validate(Type, PurchaseLine.Type::"G/L Account");
        PurchaseLine.Validate("No.", LibraryERM.CreateGLAccountWithSalesSetup());
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        PurchaseLine.Validate("No.", LibraryInventory.CreateItemNo());
        PurchaseLine.Validate(Type, PurchaseLine.Type::"Charge (Item)");
        PurchaseLine.Validate("No.", LibraryInventory.CreateItemChargeNo());
        PurchaseLine.Validate(Type, PurchaseLine.Type::"Fixed Asset");
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        PurchaseLine.Validate("No.", FixedAsset."No.");

        // Verify
        VerifyDataTypeBuffer(OnAfterAssignHeaderValuesTxt);
        VerifyDataTypeBuffer(OnAfterAssignStdTxtValuesTxt);
        VerifyDataTypeBuffer(OnAfterAssignGLAccountValuesTxt);
        VerifyDataTypeBuffer(OnAfterAssignItemValuesTxt);
        VerifyDataTypeBuffer(OnAfterAssignItemChargeValuesTxt);
        VerifyDataTypeBuffer(OnAfterAssignFixedAssetValuesTxt);

        VerifyDataTypeBuffer(OnAfterInitOutstandingAmountTxt);
        VerifyDataTypeBuffer(OnAfterInitQtyToInvoiceTxt);
        VerifyDataTypeBuffer(OnAfterInitQtyToReceiveTxt);

        VerifyDataTypeBuffer(OnBeforeUpdateDirectUnitCostTxt);
        VerifyDataTypeBuffer(OnAfterUpdateDirectUnitCostTxt);
        VerifyDataTypeBuffer(OnAfterUpdateUnitCostTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforeCalcSalesDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Sales-Calc. Discount" will trigger the integration event OnBeforeSalesCalcDiscount.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateSalesHeaderAndLine(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);

        // Verify
        VerifyDataTypeBuffer(OnBeforeCalcSalesDiscountTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterCalcSalesDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Sales-Calc. Discount" will trigger the integration event OnAfterSalesCalcDiscount.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateSalesHeaderAndLine(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);

        // Verify
        VerifyDataTypeBuffer(OnAfterCalcSalesDiscountTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforeCalcPurchaseDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Purch.-Calc.Discount" will trigger the integration event OnBeforePurchaseCalcDiscount.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseHeaderAndLine(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchaseLine);

        // Verify
        VerifyDataTypeBuffer(OnBeforeCalcPurchaseDiscountTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterCalcPurchaseDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Purch.-Calc.Discount" will trigger the integration event OnAfterPurchaseCalcDiscount.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseHeaderAndLine(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchaseLine);

        // Verify
        VerifyDataTypeBuffer(OnAfterCalcPurchaseDiscountTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforePostItemJnlLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Item Jnl.-Post Line" will trigger the integration event OnBeforeItemJnlPostLine.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Line", ItemJournalLine);

        // Verify
        VerifyDataTypeBuffer(OnBeforePostItemJnlLineTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterPostItemJnlLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Item Jnl.-Post Line" will trigger the integration event OnAfterItemJnlPostLine.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Line", ItemJournalLine);

        // Verify
        VerifyDataTypeBuffer(OnAfterPostItemJnlLineTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforeInsertTransferEntry()
    var
        ItemJournalLine: Record "Item Journal Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Item Jnl.-Post Line" will trigger the integration event OnBeforeInsertTransferEntry.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.");
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Line", ItemJournalLine);
        CreateTransferItemJnlLine(ItemJournalLine, ItemJournalLine."Item No.");

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Line", ItemJournalLine);

        // Verify
        VerifyDataTypeBuffer(OnBeforeInsertTransferEntryTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterInitItemLedgEntry()
    var
        ItemJournalLine: Record "Item Journal Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Item Jnl.-Post Line" will trigger the integration event OnAfterInitItemLedgEntry.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Line", ItemJournalLine);

        // Verify
        VerifyDataTypeBuffer(OnAfterInitItemLedgEntryTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterInsertItemLedgEntry()
    var
        ItemJournalLine: Record "Item Journal Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Item Jnl.-Post Line" will trigger the integration event OnAfterInsertItemLedgEntry.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Line", ItemJournalLine);

        // Verify
        VerifyDataTypeBuffer(OnAfterInsertItemLedgEntryTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforeInsertValueEntry()
    var
        ItemJournalLine: Record "Item Journal Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Item Jnl.-Post Line" will trigger the integration event OnBeforeInsertValueEntry.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Line", ItemJournalLine);

        // Verify
        VerifyDataTypeBuffer(OnBeforeInsertValueEntryTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterInsertValueEntry()
    var
        ItemJournalLine: Record "Item Journal Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO] Calling the codeunit "Item Jnl.-Post Line" will trigger the integration event OnAfterInsertValueEntry.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Line", ItemJournalLine);

        // Verify
        VerifyDataTypeBuffer(OnAfterInsertValueEntryTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforeInsertCorrItemLedgEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
        PurchaseReceiptNo: Code[20];
    begin
        // [SCENARIO] Calling the codeunit "Item Jnl.-Post Line" will trigger the integration event OnBeforeInsertCorrItemLedgEntry.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseOrder(PurchaseHeader);
        PurchaseReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Exercise
        UndoPurchRcptLine(PurchaseReceiptNo, 10000);

        // Verify
        VerifyDataTypeBuffer(OnBeforeInsertCorrItemLedgEntryTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterInsertCorrItemLedgEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
        PurchaseReceiptNo: Code[20];
    begin
        // [SCENARIO] Calling the codeunit "Item Jnl.-Post Line" will trigger the integration event OnAfterInsertCorrItemLedgEntry.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseOrder(PurchaseHeader);
        PurchaseReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Exercise
        UndoPurchRcptLine(PurchaseReceiptNo, 10000);

        // Verify
        VerifyDataTypeBuffer(OnAfterInsertCorrItemLedgEntryTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforeInsertCorrValueEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
        PurchaseReceiptNo: Code[20];
    begin
        // [SCENARIO] Calling the codeunit "Item Jnl.-Post Line" will trigger the integration event OnBeforeInsertCorrValueEntry.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseOrder(PurchaseHeader);
        PurchaseReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Exercise
        UndoPurchRcptLine(PurchaseReceiptNo, 10000);
        // Verify
        VerifyDataTypeBuffer(OnBeforeInsertCorrValueEntryTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterInsertCorrValueEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
        PurchaseReceiptNo: Code[20];
    begin
        // [SCENARIO] Calling the codeunit "Item Jnl.-Post Line" will trigger the integration event OnAfterInsertCorrValueEntry.

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);
        CreatePurchaseOrder(PurchaseHeader);
        PurchaseReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Exercise
        UndoPurchRcptLine(PurchaseReceiptNo, 10000);
        // Verify
        VerifyDataTypeBuffer(OnAfterInsertCorrValueEntryTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterNavigateFindRecords()
    var
        GLEntry: Record "G/L Entry";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
        Navigate: TestPage Navigate;
    begin
        // [SCENARIO] When using the Navigate page for find records, events are raised to include Custom records.
        if not GLEntry.FindFirst() then
            exit; // Nothing to find

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);

        // Exercise
        Navigate.OpenEdit();
        Navigate.FindByDocument.Invoke();
        Navigate.DocNoFilter.SetValue(GLEntry."Document No.");
        Navigate.PostingDateFilter.SetValue(Format(GLEntry."Posting Date"));
        Navigate.Find.Invoke();

        // Verify
        VerifyDataTypeBuffer(OnAfterNavigateFindRecordsTxt);
    end;

#if not CLEAN25
    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterNavigateShowRecords()
    var
        GLEntry: Record "G/L Entry";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
        Navigate: TestPage Navigate;
        GeneralLedgerEntries: TestPage "General Ledger Entries";
    begin
        // [SCENARIO] When using the Navigate page for show records, events are raised to include Custom records.
        if not GLEntry.FindFirst() then
            exit; // Nothing to find

        // Setup
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);

        // Exercise
        Navigate.OpenEdit();
        Navigate.DocNoFilter.SetValue(GLEntry."Document No.");
        Navigate.PostingDateFilter.SetValue(Format(GLEntry."Posting Date"));
        Navigate.Find.Invoke();
        Navigate.First();
        GeneralLedgerEntries.Trap();
        Navigate.Show.Invoke();
        GeneralLedgerEntries.Close();

        // Verify
        VerifyDataTypeBuffer(OnAfterNavigateShowRecordsTxt);
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    procedure TestOnAfterCheckGenJnlLineWithOverrideDimErr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        // [SCENARIO 210929] Calling the codeunit "Gen. Jnl.-Check Line" will trigger the integration event OnAfterGenJournalCheckLine if OverrideDimErr = TRUE.
        Initialize();

        BindSubscription(TestPartnerIntegrationEvent);
        CreateGenJournalLineForBank(GenJournalLine);
        GenJnlCheckLine.SetOverDimErr();
        GenJnlCheckLine.RunCheck(GenJournalLine);
        VerifyDataTypeBuffer(OnAfterCheckGenJnlLineTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnCheckPostingCostToGL()
    var
        ItemJournalLine: Record "Item Journal Line";
        ValueEntry: Record "Value Entry";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [SCENARIO 230201] With integration event OnCheckPostingCostToGL in codeunit "Item Jnl.-Post Line" you can insert an additional condition to turning on/off automatic cost posting to G/L.
        Initialize();

        // [GIVEN] "Automatic Cost Posting" is set to TRUE in Inventory Setup.
        BindSubscription(TestPartnerIntegrationEvent);
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Item Journal line. Quantity = "Q", Unit Amount = "X".
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, LibraryInventory.CreateItemNo(), '', '', LibraryRandom.RandInt(10));
        ItemJournalLine.Validate("Unit Amount", LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Modify(true);

        // [THEN] Post the item journal line.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Amount "Q" * "X" is posted to value entry, but not to G/L entry.
        ValueEntry.SetRange("Item No.", ItemJournalLine."Item No.");
        ValueEntry.FindFirst();
        ValueEntry.TestField("Cost Amount (Actual)", ItemJournalLine.Quantity * ItemJournalLine."Unit Amount");
        ValueEntry.TestField("Cost Posted to G/L", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BookingHandleTempSalesHeader()
    var
        TempSalesHeader: Record "Sales Header" temporary;
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [FEATURE] [Booking] [Sales] [Invoice]
        // [SCENARIO 298582] Integration event OnSetBookingItemInvoiced in codeunit "Booking Manager" is not executed in case of temporary Sales Header

        Initialize();
        SetBookingMgrSetup();
        BindSubscription(TestPartnerIntegrationEvent);

        // [GIVEN] Temporary Sales Invoice "SI01"
        MockSalesInvoice(TempSalesHeader);

        // [GIVEN] Invoiced Booking Item for Sales Invoice "SI01"
        MockInvoicedBookingItem(TempSalesHeader."No.");

        // [WHEN] Modify Temporary Sales Invoice
        TempSalesHeader.Modify(true);

        // [THEN] OnSetBookingItemInvoiced event is not executed
        VerifyDataTypeBufferEmpty(OnSetBookingItemInvoicedTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BookingHandleTempSalesLine()
    var
        TempSalesHeader: Record "Sales Header" temporary;
        TempSalesLine: Record "Sales Line" temporary;
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [FEATURE] [Booking] [Sales] [Invoice]
        // [SCENARIO 298582] Integration event OnSetBookingItemInvoiced in codeunit "Booking Manager" is not executed in case of temporary Sales Line

        Initialize();
        SetBookingMgrSetup();
        BindSubscription(TestPartnerIntegrationEvent);

        // [GIVEN] Sales Invoice "SI01"
        MockSalesInvoice(TempSalesHeader);

        // [GIVEN] Temporary Sales Line 10000 for "SI01"
        MockSalesLine(TempSalesLine, TempSalesHeader);

        // [GIVEN] Invoiced Booking Item for Sales Invoice "SI01"
        MockInvoicedBookingItem(TempSalesHeader."No.");

        // [WHEN] Modify Temporary Sales Line
        TempSalesLine.Modify(true);

        // [THEN] OnSetBookingItemInvoiced event is not executed
        VerifyDataTypeBufferEmpty(OnSetBookingItemInvoicedTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BookingHandleSalesHeader()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [FEATURE] [Booking] [Sales] [Invoice]
        // [SCENARIO 298582] Integration event OnSetBookingItemInvoiced in codeunit "Booking Manager" is executed in case of non-temporary Sales Invoice

        Initialize();
        SetBookingMgrSetup();
        BindSubscription(TestPartnerIntegrationEvent);

        // [GIVEN] Sales Invoice "SI01"
        MockSalesInvoice(SalesHeader);

        // [GIVEN] Invoiced Booking Item for Sales Invoice "SI01"
        MockInvoicedBookingItem(SalesHeader."No.");

        // [WHEN] Modify Sales Invoice
        SalesHeader.Modify(true);

        // [THEN] OnSetBookingItemInvoiced event is executed
        VerifyDataTypeBuffer(OnSetBookingItemInvoicedTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BookingHandleSalesLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
    begin
        // [FEATURE] [Booking] [Sales] [Invoice]
        // [SCENARIO 298582] Integration event OnSetBookingItemInvoiced in codeunit "Booking Manager" is executed in case of non-temporary Sales Invoice Line

        Initialize();
        SetBookingMgrSetup();
        BindSubscription(TestPartnerIntegrationEvent);

        // [GIVEN] Sales Invoice "SI01"
        MockSalesInvoice(SalesHeader);

        // [GIVEN] Sales Line 10000 for "SI01"
        MockSalesLine(SalesLine, SalesHeader);

        // [GIVEN] Invoiced Booking Item for Sales Invoice "SI01"
        MockInvoicedBookingItem(SalesHeader."No.");

        // [WHEN] Modify Sales Line
        SalesLine.Modify(true);

        // [THEN] OnSetBookingItemInvoiced event is executed
        VerifyDataTypeBuffer(OnSetBookingItemInvoicedTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnBeforeGetAttachmentFileNameEventRaised()
    var
        DocumentMailing: Codeunit "Document-Mailing";
        TestPartnerIntegrationEvent: Codeunit "Test Partner Integration Event";
        AttachmentFileName: Text[250];
    begin
        // [SCENARIO] OnBeforeGetAttachmentFileName event is raised when GetAttachmentFileName is called
        Initialize();
        BindSubscription(TestPartnerIntegrationEvent);

        // [GIVEN] An attachment filename
        AttachmentFileName := 'Attachment';

        // [WHEN] The function GetAttachmentFileName is called
        DocumentMailing.GetAttachmentFileName(AttachmentFileName, '', '', 1);

        // [THEN] OnBeforeGetAttachmentFileName is executed
        VerifyDataTypeBuffer(OnBeforeGetAttachmentFileNameTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Check Line", 'OnAfterCheckGenJnlLine', '', false, false)]
    local procedure OnAfterCheckGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        InsertDataTypeBuffer(OnAfterCheckGenJnlLineTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforePostGenJnlLine', '', false, false)]
    local procedure OnBeforePostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        InsertDataTypeBuffer(OnBeforePostGenJnlLineTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterAccountNoOnValidateGetGLAccount', '', false, false)]
    local procedure OnAfterAccountNoOnValidateGetGLAccount(var GenJournalLine: Record "Gen. Journal Line"; var GLAccount: Record "G/L Account")
    begin
        InsertDataTypeBuffer(OnAfterAccountNoOnValidateGetGLAccountTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterAccountNoOnValidateGetGLBalAccount', '', false, false)]
    local procedure OnAfterAccountNoOnValidateGetGLBalAccount(var GenJournalLine: Record "Gen. Journal Line"; var GLAccount: Record "G/L Account")
    begin
        InsertDataTypeBuffer(OnAfterAccountNoOnValidateGetGLBalAccountTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterAccountNoOnValidateGetBankAccount', '', false, false)]
    local procedure OnAfterAccountNoOnValidateGetBankAccount(var GenJournalLine: Record "Gen. Journal Line"; var BankAccount: Record "Bank Account")
    begin
        InsertDataTypeBuffer(OnAfterAccountNoOnValidateGetBankAccountTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterAccountNoOnValidateGetBankBalAccount', '', false, false)]
    local procedure OnAfterAccountNoOnValidateGetBankBalAccount(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line"; var BankAccount: Record "Bank Account")
    begin
        InsertDataTypeBuffer(OnAfterAccountNoOnValidateGetBankBalAccountTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterAccountNoOnValidateGetCustomerAccount', '', false, false)]
    local procedure OnAfterAccountNoOnValidateGetCustomerAccount(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer)
    begin
        InsertDataTypeBuffer(OnAfterAccountNoOnValidateGetCustomerAccountTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterAccountNoOnValidateGetCustomerBalAccount', '', false, false)]
    local procedure OnAfterAccountNoOnValidateGetCustomerBalAccount(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer)
    begin
        InsertDataTypeBuffer(OnAfterAccountNoOnValidateGetCustomerBalAccountTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterAccountNoOnValidateGetVendorAccount', '', false, false)]
    local procedure OnAfterAccountNoOnValidateGetVendorAccount(var GenJournalLine: Record "Gen. Journal Line"; var Vendor: Record Vendor)
    begin
        InsertDataTypeBuffer(OnAfterAccountNoOnValidateGetVendorAccountTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterAccountNoOnValidateGetVendorBalAccount', '', false, false)]
    local procedure OnAfterAccountNoOnValidateGetVendorBalAccount(var GenJournalLine: Record "Gen. Journal Line"; var Vendor: Record Vendor)
    begin
        InsertDataTypeBuffer(OnAfterAccountNoOnValidateGetVendorBalAccountTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterAccountNoOnValidateGetFAAccount', '', false, false)]
    local procedure OnAfterAccountNoOnValidateGetFAAccount(var GenJournalLine: Record "Gen. Journal Line"; var FixedAsset: Record "Fixed Asset")
    begin
        InsertDataTypeBuffer(OnAfterAccountNoOnValidateGetFAAccountTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterAccountNoOnValidateGetFABalAccount', '', false, false)]
    local procedure OnAfterAccountNoOnValidateGetFABalAccount(var GenJournalLine: Record "Gen. Journal Line"; var FixedAsset: Record "Fixed Asset")
    begin
        InsertDataTypeBuffer(OnAfterAccountNoOnValidateGetFABalAccountTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromPrepmtInvBuffer', '', false, false)]
    local procedure OnAfterCopyGenJnlLineFromPrepmtInvBuffer(PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        InsertDataTypeBuffer(OnAfterCopyGenJnlLineFromPrepmtInvBufferTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromPurchHeader', '', false, false)]
    local procedure OnAfterCopyGenJnlLineFromPurchHeader(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        InsertDataTypeBuffer(OnAfterCopyGenJnlLineFromPurchHeaderTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromSalesHeader', '', false, false)]
    local procedure OnAfterCopyGenJnlLineFromSalesHeader(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        InsertDataTypeBuffer(OnAfterCopyGenJnlLineFromSalesHeaderTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterInitGLRegister', '', false, false)]
    local procedure OnAfterInitGLRegister(var GLRegister: Record "G/L Register"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        InsertDataTypeBuffer(OnAfterInitGLRegisterTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterInsertGlobalGLEntry', '', false, false)]
    local procedure OnAfterInsertGlobalGLEntry(var GLEntry: Record "G/L Entry")
    begin
        InsertDataTypeBuffer(OnAfterInsertGlobalGLEntryTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeInsertGLEntryBuffer', '', false, false)]
    local procedure OnBeforeInsertGLEntryBuffer(var TempGLEntryBuf: Record "G/L Entry" temporary; var GenJournalLine: Record "Gen. Journal Line")
    begin
        InsertDataTypeBuffer(OnBeforeInsertGLEntryBufferTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", 'OnAfterCopyGLEntryFromGenJnlLine', '', false, false)]
    local procedure OnAfterCopyGLEntryFromGenJnlLine(var GLEntry: Record "G/L Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        InsertDataTypeBuffer(OnAfterCopyGLEntryFromGenJnlLineTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", 'OnAfterCopyCustLedgerEntryFromGenJnlLine', '', false, false)]
    local procedure OnAfterCopyCustLedgerEntryFromGenJnlLine(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        InsertDataTypeBuffer(OnAfterCopyCustLedgerEntryFromGenJnlLineTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", 'OnAfterCopyVendLedgerEntryFromGenJnlLine', '', false, false)]
    local procedure OnAfterCopyVendLedgerEntryFromGenJnlLine(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        InsertDataTypeBuffer(OnAfterCopyVendLedgerEntryFromGenJnlLineTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Check Line", 'OnAfterCheckItemJnlLine', '', false, false)]
    local procedure OnAfterCheckItemJnlLine(var ItemJnlLine: Record "Item Journal Line")
    begin
        InsertDataTypeBuffer(OnAfterCheckItemJnlLineTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnBeforeManualReleaseSalesDoc', '', false, false)]
    local procedure OnBeforeManualReleaseSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnBeforeManualReleaseSalesDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnBeforeReleaseSalesDoc', '', false, false)]
    local procedure OnBeforeReleaseSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnBeforeReleaseSalesDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnAfterReleaseSalesDoc', '', false, false)]
    local procedure OnAfterReleaseSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnAfterReleaseSalesDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnAfterManualReleaseSalesDoc', '', false, false)]
    local procedure OnAfterManualReleaseSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnAfterManualReleaseSalesDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnBeforeManualReOpenSalesDoc', '', false, false)]
    local procedure OnBeforeManualReopenSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnBeforeManualReopenSalesDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnBeforeReopenSalesDoc', '', false, false)]
    local procedure OnBeforeReopenSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnBeforeReopenSalesDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnAfterReopenSalesDoc', '', false, false)]
    local procedure OnAfterReopenSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnAfterReopenSalesDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnAfterManualReOpenSalesDoc', '', false, false)]
    local procedure OnAfterManualReopenSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnAfterManualReopenSalesDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnBeforeManualReleasePurchaseDoc', '', false, false)]
    local procedure OnBeforeManualReleasePurchaseDoc(var PurchaseHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnBeforeManualReleasePurchaseDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnBeforeReleasePurchaseDoc', '', false, false)]
    local procedure OnBeforeReleasePurchaseDoc(var PurchaseHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnBeforeReleasePurchaseDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnAfterReleasePurchaseDoc', '', false, false)]
    local procedure OnAfterReleasePurchaseDoc(var PurchaseHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnAfterReleasePurchaseDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnAfterManualReleasePurchaseDoc', '', false, false)]
    local procedure OnAfterManualReleasePurchaseDoc(var PurchaseHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnAfterManualReleasePurchaseDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnBeforeManualReopenPurchaseDoc', '', false, false)]
    local procedure OnBeforeManualReopenPurchaseDoc(var PurchaseHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnBeforeManualReopenPurchaseDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnBeforeReopenPurchaseDoc', '', false, false)]
    local procedure OnBeforeReopenPurchaseDoc(var PurchaseHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnBeforeReopenPurchaseDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnAfterReopenPurchaseDoc', '', false, false)]
    local procedure OnAfterReopenPurchaseDoc(var PurchaseHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnAfterReopenPurchaseDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnAfterManualReopenPurchaseDoc', '', false, false)]
    local procedure OnAfterManualReopenPurchaseDoc(var PurchaseHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnAfterManualReopenPurchaseDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure OnBeforePostSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnBeforePostSalesDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostCommitSalesDoc', '', false, false)]
    local procedure OnBeforePostCommitSalesDoc(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; ModifyHeader: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforePostCommitSalesDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure OnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20])
    begin
        InsertDataTypeBuffer(OnAfterPostSalesDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterCheckMandatoryFields', '', false, false)]
    local procedure OnAfterCheckMandatoryFieldsSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnAfterCheckMandatoryFieldsTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesInvLineInsert', '', false, false)]
    local procedure OnAfterSalesInvLineInsert(var SalesInvLine: Record "Sales Invoice Line"; SalesInvHeader: Record "Sales Invoice Header"; SalesLine: Record "Sales Line")
    begin
        InsertDataTypeBuffer(OnAfterSalesInvLineInsertTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesCrMemoLineInsert', '', false, false)]
    local procedure OnAfterSalesCrMemoLineInsert(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesLine: Record "Sales Line")
    begin
        InsertDataTypeBuffer(OnAfterSalesCrMemoLineInsertTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterUpdatePostingNos', '', false, false)]
    local procedure OnAfterUpdatePostingNosSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnAfterUpdatePostingNosTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice Events", 'OnPostBalancingEntryOnBeforeGenJnlPostLine', '', false, false)]
    local procedure OnPostBalancingEntryOnBeforeGenJnlPostLineSalesDoc(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line")
    begin
        InsertDataTypeBuffer(OnPostBalancingEntryOnBeforeGenJnlPostLineTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice Events", 'OnPostLedgerEntryOnBeforeGenJnlPostLine', '', false, false)]
    local procedure OnPostLedgerEntryOnBeforeGenJnlPostLineSalesDoc(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line")
    begin
        InsertDataTypeBuffer(OnPostLedgerEntryOnBeforeGenJnlPostLineTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice Events", 'OnPostLinesOnBeforeGenJnlLinePost', '', false, false)]
    local procedure OnPostLinesOnBeforeGenJnlLinePostSalesDoc(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnPostLinesOnBeforeGenJnlLinePostTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforeSalesShptHeaderInsert', '', false, false)]
    local procedure OnBeforeSalesShptHeaderInsert(var SalesShptHeader: Record "Sales Shipment Header"; SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnBeforeSalesShptHeaderInsertTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforeSalesShptLineInsert', '', false, false)]
    local procedure OnBeforeSalesShptLineInsert(var SalesShptLine: Record "Sales Shipment Line"; SalesShptHeader: Record "Sales Shipment Header"; SalesLine: Record "Sales Line")
    begin
        InsertDataTypeBuffer(OnBeforeSalesShptLineInsertTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforeSalesInvHeaderInsert', '', false, false)]
    local procedure OnBeforeSalesInvHeaderInsert(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnBeforeSalesInvHeaderInsertTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforeSalesInvLineInsert', '', false, false)]
    local procedure OnBeforeSalesInvLineInsert(var SalesInvLine: Record "Sales Invoice Line"; SalesInvHeader: Record "Sales Invoice Header"; SalesLine: Record "Sales Line")
    begin
        InsertDataTypeBuffer(OnBeforeSalesInvLineInsertTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforeSalesCrMemoHeaderInsert', '', false, false)]
    local procedure OnBeforeSalesCrMemoHeaderInsert(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnBeforeSalesCrMemoHeaderInsertTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforeSalesCrMemoLineInsert', '', false, false)]
    local procedure OnBeforeSalesCrMemoLineInsert(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesLine: Record "Sales Line")
    begin
        InsertDataTypeBuffer(OnBeforeSalesCrMemoLineInsertTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforeReturnRcptHeaderInsert', '', false, false)]
    local procedure OnBeforeReturnRcptHeaderInsert(var ReturnRcptHeader: Record "Return Receipt Header"; SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnBeforeReturnRcptHeaderInsertTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforeReturnRcptLineInsert', '', false, false)]
    local procedure OnBeforeReturnRcptLineInsert(var ReturnRcptLine: Record "Return Receipt Line"; ReturnRcptHeader: Record "Return Receipt Header"; SalesLine: Record "Sales Line")
    begin
        InsertDataTypeBuffer(OnBeforeReturnRcptLineInsertTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
    local procedure OnBeforePostPurchaseDoc(var PurchaseHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnBeforePostPurchaseDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostCommitPurchaseDoc', '', false, false)]
    local procedure OnBeforePostCommitPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; ModifyHeader: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforePostCommitPurchaseDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchaseDoc', '', false, false)]
    local procedure OnAfterPostPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PurchRcpHdrNo: Code[20]; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20])
    begin
        InsertDataTypeBuffer(OnAfterPostPurchaseDocTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterCheckMandatoryFields', '', false, false)]
    local procedure OnAfterCheckMandatoryFieldsPurchDoc(var PurchaseHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnAfterCheckMandatoryFieldsTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPurchInvLineInsert', '', false, false)]
    local procedure OnAfterPurchInvLineInsert(var PurchInvLine: Record "Purch. Inv. Line"; PurchInvHeader: Record "Purch. Inv. Header"; PurchLine: Record "Purchase Line")
    begin
        InsertDataTypeBuffer(OnAfterPurchInvLineInsertTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPurchCrMemoLineInsert', '', false, false)]
    local procedure OnAfterPurchCrMemoLineInsert(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchLine: Record "Purchase Line")
    begin
        InsertDataTypeBuffer(OnAfterPurchCrMemoLineInsertTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterUpdatePostingNos', '', false, false)]
    local procedure OnAfterUpdatePostingNosPurchDoc(var PurchaseHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnAfterUpdatePostingNosTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Post Invoice Events", 'OnPostBalancingEntryOnBeforeGenJnlPostLine', '', false, false)]
    local procedure OnPostBalancingEntryOnBeforeGenJnlPostLinePurchDoc(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line")
    begin
        InsertDataTypeBuffer(OnPostBalancingEntryOnBeforeGenJnlPostLineTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Post Invoice Events", 'OnPostLedgerEntryOnBeforeGenJnlPostLine', '', false, false)]
    local procedure OnBeforePostVendorEntryPurchDoc(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line")
    begin
        InsertDataTypeBuffer(OnPostLedgerEntryOnBeforeGenJnlPostLineTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Post Invoice Events", 'OnPostLedgerEntryOnBeforeGenJnlPostLine', '', false, false)]
    local procedure OnBeforePostInvPostBufferPurchDoc(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnPostLinesOnBeforeGenJnlLinePostTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePurchRcptHeaderInsert', '', false, false)]
    local procedure OnBeforePurchRcptHeaderInsert(var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchaseHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnBeforePurchRcptHeaderInsertTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePurchRcptLineInsert', '', false, false)]
    local procedure OnBeforePurchRcptLineInsert(var PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchLine: Record "Purchase Line")
    begin
        InsertDataTypeBuffer(OnBeforePurchRcptLineInsertTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePurchInvHeaderInsert', '', false, false)]
    local procedure OnBeforePurchInvHeaderInsert(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnBeforePurchInvHeaderInsertTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePurchInvLineInsert', '', false, false)]
    local procedure OnBeforePurchInvLineInsert(var PurchInvLine: Record "Purch. Inv. Line"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchaseLine: Record "Purchase Line")
    begin
        InsertDataTypeBuffer(OnBeforePurchInvLineInsertTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePurchCrMemoHeaderInsert', '', false, false)]
    local procedure OnBeforePurchCrMemoHeaderInsert(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnBeforePurchCrMemoHeaderInsertTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePurchCrMemoLineInsert', '', false, false)]
    local procedure OnBeforePurchCrMemoLineInsert(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchLine: Record "Purchase Line")
    begin
        InsertDataTypeBuffer(OnBeforePurchCrMemoLineInsertTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforeReturnShptHeaderInsert', '', false, false)]
    local procedure OnBeforeReturnShptHeaderInsert(var ReturnShptHeader: Record "Return Shipment Header"; var PurchHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnBeforeReturnShptHeaderInsertTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforeReturnShptLineInsert', '', false, false)]
    local procedure OnBeforeReturnShptLineInsert(var ReturnShptLine: Record "Return Shipment Line"; var ReturnShptHeader: Record "Return Shipment Header"; var PurchLine: Record "Purchase Line")
    begin
        InsertDataTypeBuffer(OnBeforeReturnShptLineInsertTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Calc. Discount", 'OnBeforeCalcSalesDiscount', '', false, false)]
    local procedure OnBeforeCalcSalesDiscount(var SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnBeforeCalcSalesDiscountTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Calc. Discount", 'OnAfterCalcSalesDiscount', '', false, false)]
    local procedure OnAfterCalcSalesDiscount(var SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnAfterCalcSalesDiscountTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Calc.Discount", 'OnBeforeCalcPurchaseDiscount', '', false, false)]
    local procedure OnBeforeCalcPurchaseDiscount(var PurchaseHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnBeforeCalcPurchaseDiscountTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Calc.Discount", 'OnAfterCalcPurchaseDiscount', '', false, false)]
    local procedure OnAfterCalcPurchaseDiscount(var PurchaseHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnAfterCalcPurchaseDiscountTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnBeforePostItemJnlLine', '', false, false)]
    local procedure OnBeforePostItemJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
        InsertDataTypeBuffer(OnBeforePostItemJnlLineTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterPostItemJnlLine', '', false, false)]
    local procedure OnAfterPostItemJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
        InsertDataTypeBuffer(OnAfterPostItemJnlLineTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnBeforeInsertTransferEntry', '', false, false)]
    local procedure OnBeforeInsertTransferEntry(var NewItemLedgerEntry: Record "Item Ledger Entry"; var OldItemLedgerEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
        InsertDataTypeBuffer(OnBeforeInsertTransferEntryTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInitItemLedgEntry', '', false, false)]
    local procedure OnAfterInitItemLedgEntry(var NewItemLedgEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        InsertDataTypeBuffer(OnAfterInitItemLedgEntryTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInsertItemLedgEntry', '', false, false)]
    local procedure OnAfterInsertItemLedgEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        InsertDataTypeBuffer(OnAfterInsertItemLedgEntryTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnBeforeInsertValueEntry', '', false, false)]
    local procedure OnBeforeInsertValueEntry(var ValueEntry: Record "Value Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        InsertDataTypeBuffer(OnBeforeInsertValueEntryTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInsertValueEntry', '', false, false)]
    local procedure OnAfterInsertValueEntry(var ValueEntry: Record "Value Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        InsertDataTypeBuffer(OnAfterInsertValueEntryTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnBeforeInsertCorrItemLedgEntry', '', false, false)]
    local procedure OnBeforeInsertCorrItemLedgEntry(var NewItemLedgerEntry: Record "Item Ledger Entry"; var OldItemLedgerEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
        InsertDataTypeBuffer(OnBeforeInsertCorrItemLedgEntryTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInsertCorrItemLedgEntry', '', false, false)]
    local procedure OnAfterInsertCorrItemLedgEntry(var NewItemLedgerEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
        InsertDataTypeBuffer(OnAfterInsertCorrItemLedgEntryTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnBeforeInsertCorrValueEntry', '', false, false)]
    local procedure OnBeforeInsertCorrValueEntry(var NewValueEntry: Record "Value Entry"; OldValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
        InsertDataTypeBuffer(OnBeforeInsertCorrValueEntryTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInsertCorrValueEntry', '', false, false)]
    local procedure OnAfterInsertCorrValueEntry(var NewValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
        InsertDataTypeBuffer(OnAfterInsertCorrValueEntryTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Navigate", 'OnAfterNavigateFindRecords', '', false, false)]
    local procedure OnAfterNavigateFindRecords(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        // Ensure there is one known entry so we can invoke Show and handle the page
        DocumentEntry.DeleteAll();
        DocumentEntry.InsertIntoDocEntry(DATABASE::"G/L Entry", 'G/L Entry', 1);
        InsertDataTypeBuffer(OnAfterNavigateFindRecordsTxt);
    end;

#if not CLEAN25
    [EventSubscriber(ObjectType::Page, Page::"Navigate", 'OnAfterNavigateShowRecords', '', false, false)]
    local procedure OnAfterNavigateShowRecords(TableID: Integer; DocNoFilter: Text; PostingDateFilter: Text; ItemTrackingSearch: Boolean)
    begin
        InsertDataTypeBuffer(OnAfterNavigateShowRecordsTxt);
    end;
#endif

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterInitRecord', '', false, false)]
    local procedure OnAfterSalesHeaderInitRecord(var SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnAfterInitRecordTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterInitNoSeries', '', false, false)]
    local procedure OnAfterSalesHeaderInitNoSeries(var SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnAfterInitNoSeriesTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterTestNoSeries', '', false, false)]
    local procedure OnAfterSalesHeaderTestNoSeries(var SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnAfterTestNoSeriesTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterUpdateShipToAddress', '', false, false)]
    local procedure OnAfterSalesHeaderUpdateShipToAddress(var SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnAfterUpdateShipToAddressTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterAssignHeaderValues', '', false, false)]
    local procedure OnAfterSalesLineAssignHeaderValues(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        InsertDataTypeBuffer(OnAfterAssignHeaderValuesTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterAssignStdTxtValues', '', false, false)]
    local procedure OnAfterSalesLineAssignStdTxtValues(var SalesLine: Record "Sales Line"; StandardText: Record "Standard Text")
    begin
        InsertDataTypeBuffer(OnAfterAssignStdTxtValuesTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterAssignGLAccountValues', '', false, false)]
    local procedure OnAfterSalesLineAssignGLAccountValues(var SalesLine: Record "Sales Line"; GLAccount: Record "G/L Account")
    begin
        InsertDataTypeBuffer(OnAfterAssignGLAccountValuesTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterAssignItemValues', '', false, false)]
    local procedure OnAfterSalesLineAssignItemValues(var SalesLine: Record "Sales Line"; Item: Record Item)
    begin
        InsertDataTypeBuffer(OnAfterAssignItemValuesTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterAssignItemChargeValues', '', false, false)]
    local procedure OnAfterSalesLineAssignItemChargeValues(var SalesLine: Record "Sales Line"; ItemCharge: Record "Item Charge")
    begin
        InsertDataTypeBuffer(OnAfterAssignItemChargeValuesTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterAssignFixedAssetValues', '', false, false)]
    local procedure OnAfterSalesLineAssignFixedAssetValues(var SalesLine: Record "Sales Line"; FixedAsset: Record "Fixed Asset")
    begin
        InsertDataTypeBuffer(OnAfterAssignFixedAssetValuesTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterAssignResourceValues', '', false, false)]
    local procedure OnAfterSalesLineAssignResourceValues(var SalesLine: Record "Sales Line"; Resource: Record Resource)
    begin
        InsertDataTypeBuffer(OnAfterAssignResourceValuesTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterUpdateUnitPrice', '', false, false)]
    local procedure OnAfterSalesLineUpdateUnitPrice(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer)
    begin
        InsertDataTypeBuffer(OnAfterUpdateUnitPriceTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnBeforeUpdateUnitPrice', '', false, false)]
    local procedure OnBeforeSalesLineUpdateUnitPrice(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer)
    begin
        InsertDataTypeBuffer(OnBeforeUpdateUnitPriceTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterInitOutstandingAmount', '', false, false)]
    local procedure OnAfterSalesLineInitOutstandingAmount(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Currency: Record Currency)
    begin
        InsertDataTypeBuffer(OnAfterInitOutstandingAmountTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterInitQtyToInvoice', '', false, false)]
    local procedure OnAfterSalesLineInitQtyToInvoice(var SalesLine: Record "Sales Line"; CurrFieldNo: Integer)
    begin
        InsertDataTypeBuffer(OnAfterInitQtyToInvoiceTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterInitQtyToReceive', '', false, false)]
    local procedure OnAfterSalesLineInitQtyToReceive(var SalesLine: Record "Sales Line"; CurrFieldNo: Integer)
    begin
        InsertDataTypeBuffer(OnAfterInitQtyToReceiveTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterInitQtyToShip', '', false, false)]
    local procedure OnAfterSalesLineInitQtyToShip(var SalesLine: Record "Sales Line"; CurrFieldNo: Integer)
    begin
        InsertDataTypeBuffer(OnAfterInitQtyToShipTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterInitRecord', '', false, false)]
    local procedure OnAfterPurchHeaderInitRecord(var PurchHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnAfterInitRecordTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterInitNoSeries', '', false, false)]
    local procedure OnAfterPurchHeaderInitNoSeries(var PurchHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnAfterInitNoSeriesTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterTestNoSeries', '', false, false)]
    local procedure OnAfterPurchHeaderTestNoSeries(var PurchHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnAfterTestNoSeriesTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterUpdateShipToAddress', '', false, false)]
    local procedure OnAfterPurchHeaderUpdateShipToAddress(var PurchHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnAfterUpdateShipToAddressTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterAssignHeaderValues', '', false, false)]
    local procedure OnAfterPurchLineAssignHeaderValues(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
        InsertDataTypeBuffer(OnAfterAssignHeaderValuesTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterAssignStdTxtValues', '', false, false)]
    local procedure OnAfterPurchLineAssignStdTxtValues(var PurchLine: Record "Purchase Line"; StandardText: Record "Standard Text")
    begin
        InsertDataTypeBuffer(OnAfterAssignStdTxtValuesTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterAssignGLAccountValues', '', false, false)]
    local procedure OnAfterPurchLineAssignGLAccountValues(var PurchLine: Record "Purchase Line"; GLAccount: Record "G/L Account")
    begin
        InsertDataTypeBuffer(OnAfterAssignGLAccountValuesTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterAssignItemValues', '', false, false)]
    local procedure OnAfterPurchLineAssignItemValues(var PurchLine: Record "Purchase Line"; Item: Record Item)
    begin
        InsertDataTypeBuffer(OnAfterAssignItemValuesTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterAssignItemChargeValues', '', false, false)]
    local procedure OnAfterPurchLineAssignItemChargeValues(var PurchLine: Record "Purchase Line"; ItemCharge: Record "Item Charge")
    begin
        InsertDataTypeBuffer(OnAfterAssignItemChargeValuesTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterAssignFixedAssetValues', '', false, false)]
    local procedure OnAfterPurchLineAssignFixedAssetValues(var PurchLine: Record "Purchase Line"; FixedAsset: Record "Fixed Asset")
    begin
        InsertDataTypeBuffer(OnAfterAssignFixedAssetValuesTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterUpdateDirectUnitCost', '', false, false)]
    local procedure OnAfterPurchLineUpdateDirectUnitCost(var PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer)
    begin
        InsertDataTypeBuffer(OnAfterUpdateDirectUnitCostTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnBeforeUpdateDirectUnitCost', '', false, false)]
    local procedure OnBeforePurchLineUpdateDirectUnitCost(var PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer)
    begin
        InsertDataTypeBuffer(OnBeforeUpdateDirectUnitCostTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterInitOutstandingAmount', '', false, false)]
    local procedure OnAfterPurchLineInitOutstandingAmount(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; Currency: Record Currency)
    begin
        InsertDataTypeBuffer(OnAfterInitOutstandingAmountTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterInitQtyToInvoice', '', false, false)]
    local procedure OnAfterPurchLineInitQtyToInvoice(var PurchLine: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        InsertDataTypeBuffer(OnAfterInitQtyToInvoiceTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterInitQtyToReceive', '', false, false)]
    local procedure OnAfterPurchLineInitQtyToReceive(var PurchLine: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        InsertDataTypeBuffer(OnAfterInitQtyToReceiveTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterInitQtyToShip', '', false, false)]
    local procedure OnAfterPurchLineInitQtyToShip(var PurchLine: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        InsertDataTypeBuffer(OnAfterInitQtyToShipTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterUpdateUnitCost', '', false, false)]
    local procedure OnAfterPurchLineUpdateUnitCost(var PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; Item: Record Item; StockkeepingUnit: Record "Stockkeeping Unit"; Currency: Record Currency; GLSetup: Record "General Ledger Setup")
    begin
        InsertDataTypeBuffer(OnAfterUpdateUnitCostTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterUpdateJobPrices', '', false, false)]
    local procedure OnAfterPurchLineUpdateJobPrices(var PurchLine: Record "Purchase Line"; JobJnlLine: Record "Job Journal Line"; PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
        InsertDataTypeBuffer(OnAfterUpdateJobPricesTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnCheckPostingCostToGL', '', false, false)]
    local procedure OnCheckPostingCostToGL(var PostCostToGL: Boolean)
    begin
        PostCostToGL := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Booking Manager", 'OnSetBookingItemInvoiced', '', false, false)]
    local procedure OnSetBookingItemInvoiced(var InvoicedBookingItem: Record "Invoiced Booking Item")
    begin
        InsertDataTypeBuffer(OnSetBookingItemInvoicedTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document-Mailing", 'OnBeforeGetAttachmentFileName', '', false, false)]
    local procedure OnBeforeGetAttachmentFileName(var AttachmentFileName: Text[250]; PostedDocNo: Code[20]; EmailDocumentName: Text[250]; ReportUsage: Integer)
    begin
        InsertDataTypeBuffer(OnBeforeGetAttachmentFileNameTxt);
    end;

    [Scope('OnPrem')]
    procedure InsertDataTypeBuffer(EventText: Text)
    var
        DataTypeBuffer: Record "Data Type Buffer";
    begin
        if DataTypeBuffer.FindLast() then;

        DataTypeBuffer.Init();
        DataTypeBuffer.ID += 1;
        DataTypeBuffer.Text := CopyStr(EventText, 1, MaxStrLen(DataTypeBuffer.Text));
        DataTypeBuffer.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure VerifyDataTypeBuffer(VerifyText: Text)
    var
        DataTypeBuffer: Record "Data Type Buffer";
    begin
        DataTypeBuffer.SetRange(Text, VerifyText);
        Assert.IsFalse(DataTypeBuffer.IsEmpty, StrSubstNo('The event %1 was not executed', VerifyText));
    end;

    [Scope('OnPrem')]
    procedure VerifyDataTypeBufferEmpty(VerifyText: Text)
    var
        DataTypeBuffer: Record "Data Type Buffer";
    begin
        DataTypeBuffer.SetRange(Text, VerifyText);
        Assert.IsTrue(DataTypeBuffer.IsEmpty, StrSubstNo('The event %1 was executed', VerifyText));
    end;

    local procedure CreateGenJournalLineForGLAcc(var GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateGenJournalLineForBank(var GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"Bank Account", BankAccount."No.", LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateGenJournalLineForCustomer(var GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateGenJournalLineForVendor(var GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), -LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateGenJournalLineForFA(var GenJournalLine: Record "Gen. Journal Line")
    var
        FixedAsset: Record "Fixed Asset";
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"Fixed Asset", FixedAsset."No.", LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ItemJnlLineEntryType: Enum "Item Ledger Entry Type")
    var
        ItemNo: Code[20];
    begin
        ItemNo := LibraryInventory.CreateItemNo();
        CreateItemJnlLineWithItemNo(ItemJournalLine, ItemJnlLineEntryType, ItemNo, LibraryRandom.RandDecInRange(11, 100, 2));
    end;

    local procedure CreateItemJnlLineWithItemNo(var ItemJournalLine: Record "Item Journal Line"; ItemJnlLineEntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJnlLineEntryType, ItemNo, Quantity);
    end;

    local procedure CreateTransferItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    var
        Location: Record Location;
    begin
        CreateItemJnlLineWithItemNo(ItemJournalLine, ItemJournalLine."Entry Type"::Transfer, ItemNo, LibraryRandom.RandDec(10, 2));
        Location.SetRange("Require Pick", false);
        Location.SetRange("Require Put-away", false);
        Location.SetRange("Require Receive", false);
        Location.SetRange("Require Shipment", false);
        Location.FindFirst();
        ItemJournalLine."New Location Code" := Location.Code;
        ItemJournalLine.Modify();
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeaderAndLine(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeaderAndLine(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
    end;

    local procedure CreateSalesCrMemo(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeaderAndLine(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo");
    end;

    local procedure CreateSalesReturn(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeaderAndLine(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order");
    end;

    local procedure CreateSalesHeaderAndLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeaderAndLine(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeaderAndLine(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice);
    end;

    local procedure CreatePurchaseCrMemo(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeaderAndLine(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo");
    end;

    local procedure CreatePurchaseReturn(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeaderAndLine(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order");
    end;

    local procedure CreatePurchaseHeaderAndLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandDec(100, 2));
    end;

    local procedure MockSalesInvoice(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."No." := LibraryUtility.GenerateGUID();
        SalesHeader.Insert();
    end;

    local procedure MockSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LibraryUtility.GetNewRecNo(SalesLine, SalesLine.FieldNo("Line No."));
        SalesLine.Insert();
    end;

    local procedure MockInvoicedBookingItem(DocumentNo: Code[20])
    var
        InvoicedBookingItem: Record "Invoiced Booking Item";
    begin
        InvoicedBookingItem.Init();
        InvoicedBookingItem."Booking Item ID" := CreateGuid();
        InvoicedBookingItem."Document No." := DocumentNo;
        InvoicedBookingItem.Insert();
    end;

    local procedure SetBookingMgrSetup()
    var
        BookingMgrSetup: Record "Booking Mgr. Setup";
    begin
        if not BookingMgrSetup.Get() then
            BookingMgrSetup.Insert();
        BookingMgrSetup."Booking Mgr. Codeunit" := CODEUNIT::"Test Partner Integration Event";
        BookingMgrSetup.Modify();
    end;

    local procedure UndoPurchRcptLine(PurchaseReceiptNo: Code[20]; LineNo: Integer)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        UndoPurchaseReceiptLine: Codeunit "Undo Purchase Receipt Line";
    begin
        PurchRcptLine.Get(PurchaseReceiptNo, LineNo);
        PurchRcptLine.SetRecFilter();
        UndoPurchaseReceiptLine.SetHideDialog(true);
        UndoPurchaseReceiptLine.Run(PurchRcptLine);
    end;
}

