codeunit 134163 "Company Init Unit Test"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Company-Initialize] [UT]
    end;

    var
        Assert: Codeunit Assert;
        ValuesAreNotEqualErr: Label 'Values are not equal.';
        SalesCodeTxt: Label 'SALES', Comment = 'Sales';
        SalesValueTxt: Label 'Sales';
        PurchasesCodeTxt: Label 'PURCHASES', Comment = 'Purchases';
        PurchasesValueTxt: Label 'Purchases';
        DeleteCodeTxt: Label 'DELETE', Comment = 'Delete';
        DocumentCreatedToAvoidGapInNoSeriesTxt: Label 'Document created to avoid gap in No. Series';
        InvPCostCodeTxt: Label 'INVTPCOST', Comment = 'Post Inventory to G/L';
        InvPCostValueTxt: Label 'Post Inventory Cost to G/L';
        AdjExchRatesCodeTxt: Label 'EXCHRATADJ', Comment = 'Adjust Exchange Rates';
        AdjExchRatesValueTxt: Label 'Exchange Rates Adjustment';
        ClsIncStmtCodeTxt: Label 'CLSINCOME', Comment = 'Close Income Statement';
        ClsIncStmtValueTxt: Label 'Close Income Statement';
        ConsolidationCodeTxt: Label 'CONSOLID', Comment = 'Consolidation';
        ConsolidationValueTxt: Label 'Consolidation';
        GenJnlCodeTxt: Label 'GENJNL', Comment = 'General Journal';
        GenJnlValueTxt: Label 'General Journals';
        SalesJnlCodeTxt: Label 'SALESJNL', Comment = 'Sales Journal';
        SalesJnlValueTxt: Label 'Sales Journals';
        PurchaseJnlCodeTxt: Label 'PURCHJNL', Comment = 'Purchase Journal';
        PurchaseJnlValueTxt: Label 'Purchase Journals';
        CashRcpJnlCodeTxt: Label 'CASHRECJNL', Comment = 'Cash Receipt Journal';
        CashRcpJnlvalueTxt: Label 'Cash Receipt Journals';
        PmtJnlCodeTxt: Label 'PAYMENTJNL', Comment = 'Payment Journal';
        PmtJnlValueTxt: Label 'Payment Journals';
        PmtReconJnlCodeTxt: Label 'PAYMTRECON', Comment = 'Payment Reconciliation Journal';
        PmtReconJnlValueTxt: Label 'Payment Reconciliation Journal';
        ItemJnlCodeTxt: Label 'ITEMJNL', Comment = 'Item Journal';
        ItemJnlValueTxt: Label 'Item Journals';
        PhysInvJnlCodeTxt: Label 'PHYSINVJNL', Comment = 'Phsy Inv Journal';
        PhysInvJnlValueTxt: Label 'Physical Inventory Journals';
        ResJnlCodeTxt: Label 'RESJNL', Comment = 'Resource Journal';
        ResJnlValueTxt: Label 'Resource Journals';
        JobJnlCodeTxt: Label 'PROJJNL', Comment = 'Project Journal';
        JobJnlValueTxt: Label 'Project Journals';
        SalesAppCodeTxt: Label 'SALESAPPL', Comment = 'Sales Entry Application';
        SalesAppValueTxt: Label 'Sales Entry Application';
        PurchAppCodeTxt: Label 'PURCHAPPL', Comment = 'Purchase Entry Applicaiton';
        PurchAppValueTxt: Label 'Purchase Entry Application';
        VatSettleCodeTxt: Label 'VATSTMT', Comment = 'Calculate and Post VAT Settlement';
        VatSettleValueTxt: Label 'Calculate and Post VAT Settlement';
        DateCompressGLCodeTxt: Label 'COMPRGL', Comment = 'Date Compress General Ledger';
        DateCompressGLValueTxt: Label 'Date Compress General Ledger';
        DateCompressVatCodeTxt: Label 'COMPRVAT', Comment = 'Date Compress VAT Entries';
        DateCompressVatValueTxt: Label 'Date Compress VAT Entries';
        DateCompressCLCodeTxt: Label 'COMPRCUST', Comment = 'Data Compress Customer Ledger';
        DateCompressCLValueTxt: Label 'Date Compress Customer Ledger';
        DateCompressVLCodeTxt: Label 'COMPRVEND', Comment = 'Date Compress Vendor Ledger';
        DateCompressVLValueTxt: Label 'Date Compress Vendor Ledger';
        DateCompressRLCodeTxt: Label 'COMPRRES', Comment = 'Date Compress Resource Ledger';
        DateCompressRLValueTxt: Label 'Date Compress Resource Ledger';
        DateCompressJLCodeTxt: Label 'COMPRPROJ', Comment = 'Date Compress Project Ledger';
        DateCompressJLValueTxt: Label 'Date Compress Project Ledger';
        DateCompressBACodeTxt: Label 'COMPRBANK', Comment = 'Date Comrpess Bank Account Ledger';
        DateCompressBAValueTxt: Label 'Date Compress Bank Account Ledger';
        DeleteCheckLedgerEntriesCodeTxt: Label 'COMPRCHECK', Comment = 'Date Compress Check Ledger Entries';
        DeleteCheckLedgerEntriesValueTxt: Label 'Delete Check Ledger Entries';
        FinVoidCheckCodeTxt: Label 'FINVOIDCHK', Comment = 'Financially Voided Checks';
        FinVoidCheckValueTxt: Label 'Financially Voided Check';
        ReminderCodeTxt: Label 'REMINDER', Comment = 'Reminder';
        ReminderValueTxt: Label 'Reminder';
        FinChargeMemoCodeTxt: Label 'FINCHRG', Comment = 'Finance Charge Memo';
        FinChargeMemoValueTxt: Label 'Finance Charge Memo';
        FAstGLJnlCodeTxt: Label 'FAGLJNL', Comment = 'Fixed Asset G/L Journal';
        FAstGLJnlValueTxt: Label 'Fixed Asset G/L Journals';
        FAstJnlCodeTxt: Label 'FAJNL', Comment = 'Fixed Asset Journal';
        FAstJnlValueTxt: Label 'Fixed Asset Journals';
        InsJnlCodeTxt: Label 'INSJNL', Comment = 'Insurance journal';
        InsJnlValueTxt: Label 'Fixed Asset Insurance Journals';
        DateCompressFALedgerCodeTxt: Label 'COMPRFA', Comment = 'Date Compress FA Ledger';
        DateCompressFALedgerValueTxt: Label 'Date Compress FA Ledger';
        DateCompressMainLedgerCodeTxt: Label 'COMPRMAINT', Comment = 'Date Compress Maint. Ledger';
        DateCompressMainLedgerValueTxt: Label 'Date Compress Maint. Ledger';
        DateCompressInsLedgerCodeTxt: Label 'COMPRINS', Comment = 'Date Compress Insurance Ledger';
        DateCompressInsLedgerValueTxt: Label 'Date Compress Insurance Ledger';
        AdjRepCurrCodeTxt: Label 'ADJADDCURR', Comment = 'Adjust Add. Reporting Currenct6';
        AdjRepCurrValueTxt: Label 'Adjust Add. Reporting Currency';
        TransferCodeTxt: Label 'TRANSFER', Comment = 'Transfer';
        TransferValueTxt: Label 'Transfer';
        ItemReclassJnlCodeTxt: Label 'RECLASSJNL', Comment = 'Item Reclass jorunal';
        ItemReclassJnlValueTxt: Label 'Item Reclassification Journals';
        RevalJnlCodeTxt: Label 'REVALJNL', Comment = 'Revaluation Journal';
        RevalJnlValueTxt: Label 'Item Revaluation Journals';
        ConsJnlCodeTxt: Label 'CONSUMPJNL', Comment = 'Consumption Journal';
        ConsJnlValueTxt: Label 'Consumption Journals';
        AdjCostCodeTxt: Label 'INVTADJMT', Comment = 'Adjust Cost - Item Entries';
        AdjCostValueTxt: Label 'Adjust Cost - Item Entries';
        OutJnlCodeTxt: Label 'POINOUTJNL', Comment = 'Outpu Journal';
        OutJnlValueTxt: Label 'Output Journals';
        CapJnlCodeTxt: Label 'CAPACITJNL', Comment = 'Capacity Journal';
        CapJnlValueTxt: Label 'Capacity Journals';
        WhseItemJnlCodeTxt: Label 'WHITEM', Comment = 'Warehouse Item journal';
        WhseItemJnlValueTxt: Label 'Warehouse Item Journal';
        WhsePhysItemJnlCodeTxt: Label 'WHPHYSINVT', Comment = 'Warehouse Physical Inventory journal';
        WhsePhysItemJnlValueTxt: Label 'Warehouse Physical Inventory Journal';
        WhseReclassJnlCodeTxt: Label 'WHRCLSSJNL', Comment = 'Whse. Reclassification Journal';
        WhseReclassJnlValueTxt: Label 'Warehouse Reclassification Journals';
        ServiceMgtCodeTxt: Label 'SERVICE', Comment = 'Service Management';
        ServiceMgtValueTxt: Label 'Service Management';
        TransBankRecCodeTxt: Label 'BANKREC', Comment = 'Trans. Bank rec. to gen. jnml';
        TransBankRecValueTxt: Label 'Trans. Bank Rec. to Gen. Jnl.';
        WhsePutAwayCodeTxt: Label 'WHPUTAWAY', Comment = 'Whse. put away';
        WhsePutAwayValueTxt: Label 'Whse. Put-away';
        WhsePickCodeTxt: Label 'WHPICK', Comment = 'Whse pick';
        WhsePickValueTxt: Label 'Whse. Pick';
        WhseMoveCodeTxt: Label 'WHMOVEMENT', Comment = 'Whse. movement';
        WhseMoveValueTxt: Label 'Whse. Movement';
        CompressWhseCodeTxt: Label 'COMPRWHSE', Comment = 'Date Compress Whse. Entries';
        CompressWhseValueTxt: Label 'Date Compress Whse. Entries';
        IntercompCodeTxt: Label 'INTERCOMP', Comment = 'intercompany';
        IntercompValueTxt: Label 'Intercompany';
        USalesAppCodeTxt: Label 'UNAPPSALES', Comment = 'Unapplies sales entry application';
        USalesAppValueTxt: Label 'Unapplied Sales Entry Application';
        UPurchAppCodeTxt: Label 'UNAPPPURCH', Comment = 'Unapplied Purchase Entry Application';
        UPurchAppValueTxt: Label 'Unapplied Purchase Entry Application';
        ReversalCodeTxt: Label 'REVERSAL', Comment = 'Reversal';
        ReversalValueTxt: Label 'Reversal Entry ';
        ProdJnlCodeTxt: Label 'PRODORDER', Comment = 'Production Journal';
        ProdJnlValueTxt: Label 'Production Journal';
        FlushingCodeTxt: Label 'FLUSHING', Comment = 'Flushing';
        FlushingValueTxt: Label 'Flushing';
        JobGlJnlCodeTxt: Label 'PROJGLJNL', Comment = 'Project G/L Journal';
        JobGlJnlValueTxt: Label 'Project G/L Journals';
        WipECodeTxt: Label 'PROJGLWIP', Comment = 'WIP Entry';
        WipEValueTxt: Label 'WIP Entry';
        CompressItemBudgetCodeTxt: Label 'COMPRIBUDG', Locked = true;
        CompressItemBudgetValueTxt: Label 'Date Compr. Item Budget Entries';
        CashFlowWorkCodeTxt: Label 'CFWKSH', Comment = 'Uppercase of the translation of cash flow work sheet with a max of 10 char';
        CashFlowWorkValueTxt: Label 'Cash Flow Worksheet';
        AssemblyCodeTxt: Label 'ASSEMBLY', Comment = 'Uppercase of the translation of assembly with a max of 10 char';
        AssemblyValueTxt: Label 'Assembly';
        GLEntryCodeTxt: Label 'GL';
        GLEntryValueTxt: Label 'G/L Entry to Cost Accounting';
        CostJnlCodeTxt: Label 'CAJOUR', Comment = 'Uppercase of the translation of cost accounting journal with a max of 10 char';
        CostJnlValueTxt: Label 'Cost Journal';
        CostAllocCodeTxt: Label 'ALLOC', Comment = 'Uppercase of the translation of allocation with a max of 10 char';
        CostAllocValueTxt: Label 'Cost Allocation';
        TransfBudCodeTxt: Label 'TRABUD', Comment = 'Uppercase of the translation of Transfer Budget to Actual with a max of 10 char';
        TransfBudValueTxt: Label 'Transfer Budget to Actual';
        MonthlyDeprecCodeTxt: Label 'MD', Locked = true;
        MonthlyDeprecValueTxt: Label 'Monthly Depreciation';
        ShippingChargeCodeTxt: Label 'SC', Locked = true;
        ShippingChargeValueTxt: Label 'Shipping Charge';
        SaleUContractCodeTxt: Label 'SUC', Locked = true;
        SaleUContractValueTxt: Label 'Sale under Contract';
        TravelExpensesCodeTxt: Label 'TE', Locked = true;
        TravelExpensesValueTxt: Label 'Travel Expenses';
        SEPACTCodeTxt: Label 'SEPACT', Comment = 'No need to translate - but can be translated at will.';
        SEPACTNameTxt: Label 'SEPA Credit Transfer';
        SEPADDCodeTxt: Label 'SEPADD', Comment = 'No need to translate - but can be translated at will.';
        SEPADDNameTxt: Label 'SEPA Direct Debit';
        CompletedContractTxt: Label 'Completed Contract';
        CostOfSalesTxt: Label 'Cost of Sales';
        CostValueTxt: Label 'Cost Value';
        JobSalesValueTxt: Label 'Sales Value';
        PercentageOfCompletionTxt: Label 'Percentage of Completion';
        PercOfCompTxt: Label 'POC', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure TestCompanyInitialize()
    var
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Company Init Unit Test");

        BindSubscription(LibraryJobQueue);

        // Setup
        DeleteAllDataInSetupTables();
        DeleteAllDataInSourceCodeTable();
        DeleteAllStandardTexts();
        DeleteReportSelections();
        DeleteJobWIPMethods();
        DeleteBankExportImportSetup();
        DeleteBankClearingStandard();
        DeleteBankPmtApplRules();
        DeleteAndInitApplicationArea();

        // Exercise
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        CODEUNIT.Run(CODEUNIT::"Company-Initialize");
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // Verify
        CheckAllSetupTables();
        CheckSourceCodeTable();
        CheckStandardTexts();
        CheckReportSelections();
        CheckJobWIPMethods();
        CheckBankExportImportSetup();
        CheckVATRegNrValidation();
        CheckBankPmtApplRules();
        CheckApplicationAreaEntry();
    end;

    local procedure DeleteAllDataInSetupTables()
    var
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        InvtSetup: Record "Inventory Setup";
        ResourcesSetup: Record "Resources Setup";
        JobsSetup: Record "Jobs Setup";
        HumanResourcesSetup: Record "Human Resources Setup";
        MarketingSetup: Record "Marketing Setup";
        InteractionTemplateSetup: Record "Interaction Template Setup";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        NonstockItemSetup: Record "Nonstock Item Setup";
        FASetup: Record "FA Setup";
        CashFlowSetup: Record "Cash Flow Setup";
        CostAccSetup: Record "Cost Accounting Setup";
        WhseSetup: Record "Warehouse Setup";
        AssemblySetup: Record "Assembly Setup";
        VATReportSetup: Record "VAT Report Setup";
        ConfigSetup: Record "Config. Setup";
        CompanyInfo: Record "Company Information";
        MfgSetup: Record "Manufacturing Setup";
    begin
        GLSetup.DeleteAll();
        SalesSetup.DeleteAll();
        MarketingSetup.DeleteAll();
        InteractionTemplateSetup.DeleteAll();
        ServiceMgtSetup.DeleteAll();
        PurchSetup.DeleteAll();
        InvtSetup.DeleteAll();
        ResourcesSetup.DeleteAll();
        JobsSetup.DeleteAll();
        FASetup.DeleteAll();
        HumanResourcesSetup.DeleteAll();
        WhseSetup.DeleteAll();
        NonstockItemSetup.DeleteAll();
        CashFlowSetup.DeleteAll();
        CostAccSetup.DeleteAll();
        AssemblySetup.DeleteAll();
        VATReportSetup.DeleteAll();
        ConfigSetup.DeleteAll();
        CompanyInfo.DeleteAll();
        MfgSetup.DeleteAll();
    end;

    local procedure DeleteAllDataInSourceCodeTable()
    var
        SourceCode: Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCode.DeleteAll();
        SourceCodeSetup.DeleteAll();
    end;

    local procedure DeleteAllStandardTexts()
    var
        StandardText: Record "Standard Text";
    begin
        StandardText.DeleteAll();
    end;

    local procedure DeleteBankClearingStandard()
    var
        BankClearingStandard: Record "Bank Clearing Standard";
    begin
        BankClearingStandard.DeleteAll();
    end;

    local procedure DeleteBankExportImportSetup()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.DeleteAll();
    end;

    local procedure DeleteReportSelections()
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.DeleteAll();
    end;

    local procedure DeleteJobWIPMethods()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        JobWIPMethod.DeleteAll();
    end;

    local procedure DeleteBankPmtApplRules()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        BankPmtApplRule.DeleteAll();
    end;

    local procedure DeleteAndInitApplicationArea()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        ApplicationAreaSetup.DeleteAll();
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Basic));
    end;

    local procedure CheckAllSetupTables()
    var
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        InvtSetup: Record "Inventory Setup";
        ResourcesSetup: Record "Resources Setup";
        JobsSetup: Record "Jobs Setup";
        HumanResourcesSetup: Record "Human Resources Setup";
        MarketingSetup: Record "Marketing Setup";
        InteractionTemplateSetup: Record "Interaction Template Setup";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        NonstockItemSetup: Record "Nonstock Item Setup";
        FASetup: Record "FA Setup";
        CashFlowSetup: Record "Cash Flow Setup";
        CostAccSetup: Record "Cost Accounting Setup";
        WhseSetup: Record "Warehouse Setup";
        AssemblySetup: Record "Assembly Setup";
        VATReportSetup: Record "VAT Report Setup";
        ConfigSetup: Record "Config. Setup";
        CompanyInfo: Record "Company Information";
        MfgSetup: Record "Manufacturing Setup";
    begin
        GLSetup.FindFirst();
        SalesSetup.FindFirst();
        MarketingSetup.FindFirst();
        InteractionTemplateSetup.FindFirst();
        ServiceMgtSetup.FindFirst();
        PurchSetup.FindFirst();
        InvtSetup.FindFirst();
        ResourcesSetup.FindFirst();
        JobsSetup.FindFirst();
        FASetup.FindFirst();
        HumanResourcesSetup.FindFirst();
        WhseSetup.FindFirst();
        NonstockItemSetup.FindFirst();
        CashFlowSetup.FindFirst();
        CostAccSetup.FindFirst();
        AssemblySetup.FindFirst();
        VATReportSetup.FindFirst();
        ConfigSetup.FindFirst();
        CompanyInfo.FindFirst();
        MfgSetup.FindFirst();
    end;

    local procedure CheckSourceCodeTable()
    begin
        CheckSourceCodeEntry(SalesCodeTxt, SalesValueTxt);
        CheckSourceCodeEntry(PurchasesCodeTxt, PurchasesValueTxt);
        CheckSourceCodeEntry(DeleteCodeTxt, DocumentCreatedToAvoidGapInNoSeriesTxt);
        CheckSourceCodeEntry(InvPCostCodeTxt, InvPCostValueTxt);
        CheckSourceCodeEntry(AdjExchRatesCodeTxt, AdjExchRatesValueTxt);
        CheckSourceCodeEntry(ClsIncStmtCodeTxt, ClsIncStmtValueTxt);
        CheckSourceCodeEntry(ConsolidationCodeTxt, ConsolidationValueTxt);
        CheckSourceCodeEntry(GenJnlCodeTxt, GenJnlValueTxt);
        CheckSourceCodeEntry(SalesJnlCodeTxt, SalesJnlValueTxt);
        CheckSourceCodeEntry(PurchaseJnlCodeTxt, PurchaseJnlValueTxt);
        CheckSourceCodeEntry(CashRcpJnlCodeTxt, CashRcpJnlvalueTxt);
        CheckSourceCodeEntry(PmtJnlCodeTxt, PmtJnlValueTxt);
        CheckSourceCodeEntry(PmtReconJnlCodeTxt, PmtReconJnlValueTxt);
        CheckSourceCodeEntry(ItemJnlCodeTxt, ItemJnlValueTxt);
        CheckSourceCodeEntry(TransferCodeTxt, TransferValueTxt);
        CheckSourceCodeEntry(ItemReclassJnlCodeTxt, ItemReclassJnlValueTxt);
        CheckSourceCodeEntry(PhysInvJnlCodeTxt, PhysInvJnlValueTxt);
        CheckSourceCodeEntry(RevalJnlCodeTxt, RevalJnlValueTxt);
        CheckSourceCodeEntry(ConsJnlCodeTxt, ConsJnlValueTxt);
        CheckSourceCodeEntry(OutJnlCodeTxt, OutJnlValueTxt);
        CheckSourceCodeEntry(ProdJnlCodeTxt, ProdJnlValueTxt);
        CheckSourceCodeEntry(CapJnlCodeTxt, CapJnlValueTxt);
        CheckSourceCodeEntry(ResJnlCodeTxt, ResJnlValueTxt);
        CheckSourceCodeEntry(JobJnlCodeTxt, JobJnlValueTxt);
        CheckSourceCodeEntry(JobGlJnlCodeTxt, JobGlJnlValueTxt);
        CheckSourceCodeEntry(WipECodeTxt, WipEValueTxt);
        CheckSourceCodeEntry(SalesAppCodeTxt, SalesAppValueTxt);
        CheckSourceCodeEntry(USalesAppCodeTxt, USalesAppValueTxt);
        CheckSourceCodeEntry(UPurchAppCodeTxt, UPurchAppValueTxt);
        CheckSourceCodeEntry(ReversalCodeTxt, ReversalValueTxt);
        CheckSourceCodeEntry(PurchAppCodeTxt, PurchAppValueTxt);
        CheckSourceCodeEntry(VatSettleCodeTxt, VatSettleValueTxt);
        CheckSourceCodeEntry(DateCompressGLCodeTxt, DateCompressGLValueTxt);
        CheckSourceCodeEntry(DateCompressVatCodeTxt, DateCompressVatValueTxt);
        CheckSourceCodeEntry(DateCompressCLCodeTxt, DateCompressCLValueTxt);
        CheckSourceCodeEntry(DateCompressVLCodeTxt, DateCompressVLValueTxt);
        CheckSourceCodeEntry(DateCompressRLCodeTxt, DateCompressRLValueTxt);
        CheckSourceCodeEntry(DateCompressJLCodeTxt, DateCompressJLValueTxt);
        CheckSourceCodeEntry(DateCompressBACodeTxt, DateCompressBAValueTxt);
        CheckSourceCodeEntry(DeleteCheckLedgerEntriesCodeTxt, DeleteCheckLedgerEntriesValueTxt);
        CheckSourceCodeEntry(FinVoidCheckCodeTxt, FinVoidCheckValueTxt);
        CheckSourceCodeEntry(ReminderCodeTxt, ReminderValueTxt);
        CheckSourceCodeEntry(FinChargeMemoCodeTxt, FinChargeMemoValueTxt);
        CheckSourceCodeEntry(TransBankRecCodeTxt, TransBankRecValueTxt);
        CheckSourceCodeEntry(FAstGLJnlCodeTxt, FAstGLJnlValueTxt);
        CheckSourceCodeEntry(FAstJnlCodeTxt, FAstJnlValueTxt);
        CheckSourceCodeEntry(InsJnlCodeTxt, InsJnlValueTxt);
        CheckSourceCodeEntry(DateCompressFALedgerCodeTxt, DateCompressFALedgerValueTxt);
        CheckSourceCodeEntry(DateCompressMainLedgerCodeTxt, DateCompressMainLedgerValueTxt);
        CheckSourceCodeEntry(DateCompressInsLedgerCodeTxt, DateCompressInsLedgerValueTxt);
        CheckSourceCodeEntry(AdjRepCurrCodeTxt, AdjRepCurrValueTxt);
        CheckSourceCodeEntry(FlushingCodeTxt, FlushingValueTxt);
        CheckSourceCodeEntry(AdjCostCodeTxt, AdjCostValueTxt);
        CheckSourceCodeEntry(CompressItemBudgetCodeTxt, CompressItemBudgetValueTxt);
        CheckSourceCodeEntry(WhseItemJnlCodeTxt, WhseItemJnlValueTxt);
        CheckSourceCodeEntry(WhsePhysItemJnlCodeTxt, WhsePhysItemJnlValueTxt);
        CheckSourceCodeEntry(WhseReclassJnlCodeTxt, WhseReclassJnlValueTxt);
        CheckSourceCodeEntry(CompressWhseCodeTxt, CompressWhseValueTxt);
        CheckSourceCodeEntry(WhsePutAwayCodeTxt, WhsePutAwayValueTxt);
        CheckSourceCodeEntry(WhsePickCodeTxt, WhsePickValueTxt);
        CheckSourceCodeEntry(WhseMoveCodeTxt, WhseMoveValueTxt);
        CheckSourceCodeEntry(ServiceMgtCodeTxt, ServiceMgtValueTxt);
        CheckSourceCodeEntry(IntercompCodeTxt, IntercompValueTxt);
        CheckSourceCodeEntry(CashFlowWorkCodeTxt, CashFlowWorkValueTxt);
        CheckSourceCodeEntry(AssemblyCodeTxt, AssemblyValueTxt);
        CheckSourceCodeEntry(GLEntryCodeTxt, GLEntryValueTxt);
        CheckSourceCodeEntry(CostJnlCodeTxt, CostJnlValueTxt);
        CheckSourceCodeEntry(CostAllocCodeTxt, CostAllocValueTxt);
        CheckSourceCodeEntry(TransfBudCodeTxt, TransfBudValueTxt);
    end;

    local procedure CheckSourceCodeEntry(RecCode: Code[10]; Value: Text[100])
    var
        SourceCode: Record "Source Code";
    begin
        SourceCode.SetRange(Code, RecCode);
        SourceCode.FindFirst();
        Assert.AreEqual(Value, SourceCode.Description, ValuesAreNotEqualErr);
    end;

    local procedure CheckStandardTexts()
    begin
        CheckStandardTextEntry(MonthlyDeprecCodeTxt, MonthlyDeprecValueTxt);
        CheckStandardTextEntry(ShippingChargeCodeTxt, ShippingChargeValueTxt);
        CheckStandardTextEntry(SaleUContractCodeTxt, SaleUContractValueTxt);
        CheckStandardTextEntry(TravelExpensesCodeTxt, TravelExpensesValueTxt);
    end;

    local procedure CheckStandardTextEntry(RecCode: Code[20]; Value: Text[100])
    var
        StandardText: Record "Standard Text";
    begin
        StandardText.SetRange(Code, RecCode);
        StandardText.FindFirst();
        Assert.AreEqual(Value, StandardText.Description, ValuesAreNotEqualErr);
    end;

    local procedure CheckBankExportImportSetup()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        CheckBankExportImportSetupEntry(SEPACTCodeTxt, SEPACTNameTxt, BankExportImportSetup.Direction::Export,
          CODEUNIT::"SEPA CT-Export File", XMLPORT::"SEPA CT pain.001.001.03", CODEUNIT::"SEPA CT-Check Line");
        CheckBankExportImportSetupEntry(SEPADDCodeTxt, SEPADDNameTxt, BankExportImportSetup.Direction::Export,
          CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.02", CODEUNIT::"SEPA DD-Check Line");
    end;

    local procedure CheckBankExportImportSetupEntry(RecCode: Text[20]; Name: Text[100]; Direction: Option; CodeunitId: Integer; XMLPortId: Integer; CheckCodeunitId: Integer)
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.SetRange(Code, RecCode);
        BankExportImportSetup.FindFirst();
        Assert.AreEqual(Name, BankExportImportSetup.Name, ValuesAreNotEqualErr);
        Assert.AreEqual(Direction, BankExportImportSetup.Direction, ValuesAreNotEqualErr);
        Assert.AreEqual(CodeunitId, BankExportImportSetup."Processing Codeunit ID", ValuesAreNotEqualErr);
        Assert.AreEqual(XMLPortId, BankExportImportSetup."Processing XMLport ID", ValuesAreNotEqualErr);
        Assert.AreEqual(CheckCodeunitId, BankExportImportSetup."Check Export Codeunit", ValuesAreNotEqualErr);
        Assert.AreEqual(false, BankExportImportSetup."Preserve Non-Latin Characters", ValuesAreNotEqualErr);
    end;

    local procedure CheckReportSelections()
    var
        ReportSelections: Record "Report Selections";
    begin
        CheckReportSelectionEntry(ReportSelections.Usage::"S.Quote", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"S.Blanket", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"S.Order", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"S.Work Order", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"S.Invoice", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"S.Return", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"S.Cr.Memo", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"S.Shipment", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"S.Ret.Rcpt.", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"S.Test", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"P.Quote", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"P.Blanket", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"P.Order", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"P.Invoice", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"P.Return", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"P.Cr.Memo", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"P.Receipt", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"P.Ret.Shpt.", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"P.Test", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"B.Stmt", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"B.Recon.Test", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"B.Check", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::Reminder, '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"Fin.Charge", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"Rem.Test", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"F.C.Test", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::Inv1, '1');
        CheckReportSelectionEntry(ReportSelections.Usage::Inv2, '1');
        CheckReportSelectionEntry(ReportSelections.Usage::Inv3, '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"Invt.Period Test", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"Prod.Order", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::M1, '1');
        CheckReportSelectionEntry(ReportSelections.Usage::M2, '1');
        CheckReportSelectionEntry(ReportSelections.Usage::M3, '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"SM.Quote", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"SM.Order", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"SM.Invoice", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"SM.Credit Memo", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"SM.Shipment", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"SM.Contract Quote", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"SM.Contract", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"SM.Test", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"SM.Item Worksheet", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"Asm.Order", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"P.Asm.Order", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"S.Test Prepmt.", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"P.Test Prepmt.", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"S.Arch.Quote", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"S.Arch.Order", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"P.Arch.Quote", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"P.Arch.Order", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"P.Arch.Return", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"S.Arch.Return", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"S.Order Pick Instruction", '1');
        CheckReportSelectionEntry(ReportSelections.Usage::"C.Statement", '1');
    end;

    local procedure CheckReportSelectionEntry(RecUsage: Enum "Report Selection Usage"; Sequence: Text)
    var
        ReportSelections: Record "Report Selections";
        ReportId: Integer;
    begin
        ReportId := GetReportId(RecUsage, Sequence);
        ReportSelections.SetRange(Usage, RecUsage);
        ReportSelections.FindFirst();
        Assert.AreEqual(Sequence, ReportSelections.Sequence, ValuesAreNotEqualErr);
        Assert.AreEqual(ReportId, ReportSelections."Report ID", ValuesAreNotEqualErr);
    end;

    local procedure GetReportId(RecUsage: Enum "Report Selection Usage"; Sequence: Text) ReportId: Integer
    var
        LibraryReportSelection: Codeunit "Library - Report Selection";
    begin
        ReportId := LibraryReportSelection.GetReportId(RecUsage, Sequence);
    end;

    local procedure CheckJobWIPMethods()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        CheckJobWIPMethodEntry(CompletedContractTxt, CompletedContractTxt, JobWIPMethod."Recognized Costs"::"At Completion",
          JobWIPMethod."Recognized Sales"::"At Completion", 4);
        CheckJobWIPMethodEntry(CostOfSalesTxt, CostOfSalesTxt, JobWIPMethod."Recognized Costs"::"Cost of Sales",
          JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)", 2);
        CheckJobWIPMethodEntry(CostValueTxt, CostValueTxt, JobWIPMethod."Recognized Costs"::"Cost Value",
          JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)", 0);
        CheckJobWIPMethodEntry(JobSalesValueTxt, JobSalesValueTxt, JobWIPMethod."Recognized Costs"::"Usage (Total Cost)",
          JobWIPMethod."Recognized Sales"::"Sales Value", 1);
        CheckJobWIPMethodEntry(PercOfCompTxt, PercentageOfCompletionTxt, JobWIPMethod."Recognized Costs"::"Usage (Total Cost)",
          JobWIPMethod."Recognized Sales"::"Percentage of Completion", 3);
    end;

    local procedure CheckJobWIPMethodEntry(RecCode: Code[20]; Value: Text[100]; Costs: Enum "Job WIP Recognized Costs Type"; Sales: Enum "Job WIP Recognized Sales Type"; SystemIndex: Integer)
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        JobWIPMethod.SetRange(Code, RecCode);
        JobWIPMethod.FindFirst();
        Assert.AreEqual(Value, JobWIPMethod.Description, ValuesAreNotEqualErr);
        Assert.AreEqual(true, JobWIPMethod."WIP Cost", ValuesAreNotEqualErr);
        Assert.AreEqual(true, JobWIPMethod."WIP Sales", ValuesAreNotEqualErr);
        Assert.AreEqual(Costs, JobWIPMethod."Recognized Costs", ValuesAreNotEqualErr);
        Assert.AreEqual(Sales, JobWIPMethod."Recognized Sales", ValuesAreNotEqualErr);
        Assert.AreEqual(true, JobWIPMethod.Valid, ValuesAreNotEqualErr);
        Assert.AreEqual(true, JobWIPMethod."System Defined", ValuesAreNotEqualErr);
        Assert.AreEqual(SystemIndex, JobWIPMethod."System-Defined Index", ValuesAreNotEqualErr);
    end;

    local procedure CheckVATRegNrValidation()
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        VATRegNoSrvConfig.FindFirst();
        Assert.AreEqual('http://ec.europa.eu/taxation_customs/vies/services/checkVatService',
          VATRegNoSrvConfig."Service Endpoint", ValuesAreNotEqualErr);
    end;

    local procedure CheckBankPmtApplRules()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::High, 1,
          BankPmtApplRule."Related Party Matched"::"Not Considered",
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::Yes);

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::High, 2,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::High, 3,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::High, 4,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::High, 5,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::High, 6,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::High, 7,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::High, 8,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::High, 9,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::High, 10,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::High, 11,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::Medium, 1,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::Medium, 2,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::Medium, 3,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::Medium, 4,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::Medium, 5,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::Medium, 6,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::Medium, 7,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::Medium, 8,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::Medium, 9,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::Low, 1,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::Low, 2,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::Low, 3,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::Low, 4,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        CheckBankPmtApplRuleEntry(
          BankPmtApplRule."Match Confidence"::Low, 5,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");
    end;

    local procedure CheckBankPmtApplRuleEntry(MatchConfidence: Option; Prio: Integer; RelatedParty: Option; DocMatch: Option; AmountMatch: Option; DirectDebitCollectionMatch: Option)
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        BankPmtApplRule.SetRange("Match Confidence", MatchConfidence);
        BankPmtApplRule.SetRange(Priority, Prio);
        BankPmtApplRule.SetRange("Related Party Matched", RelatedParty);
        BankPmtApplRule.SetRange("Doc. No./Ext. Doc. No. Matched", DocMatch);
        BankPmtApplRule.SetRange("Amount Incl. Tolerance Matched", AmountMatch);
        BankPmtApplRule.SetRange("Direct Debit Collect. Matched", DirectDebitCollectionMatch);
        BankPmtApplRule.FindFirst();
    end;

    local procedure CheckApplicationAreaEntry()
    var
        TempApplicationAreaBuffer: Record "Application Area Buffer" temporary;
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        Assert: Codeunit Assert;
    begin
        ApplicationAreaMgmt.GetApplicationAreaBuffer(TempApplicationAreaBuffer);

        TempApplicationAreaBuffer.SetRange("Field No.", 1, 4999);
        TempApplicationAreaBuffer.SetRange(Selected, true);
        Assert.RecordCount(TempApplicationAreaBuffer, 5);

        TempApplicationAreaBuffer.SetRange(Selected, false);
        Assert.RecordCount(TempApplicationAreaBuffer, 31);
    end;
}

