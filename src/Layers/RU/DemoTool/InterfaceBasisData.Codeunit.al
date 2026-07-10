codeunit 110000 "Interface Basis Data"
{

    trigger OnRun()
    begin
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Currency: Record Currency;
        ExchRateAdjustment: Report "Exch. Rate Adjustment";
        CreateDepreciation: Report "Calculate Depreciation";
        PostInventoryCostToGL: Report "Post Inventory Cost to G/L";
        "Create Currency": Codeunit "Create Currency";
        CA: Codeunit "Make Adjustments";
        "Run Post Inventory Cost to G/L": Codeunit "Run Post Inventory Cost to G/L";
        CalcQty: Codeunit "Create Item Ledger,Phys. Invt.";
        "Adjust Inventory Value": Codeunit "Adjust Inventory Value";
        CreateTaxDiffSetup: Codeunit "Create Tax Diff. Setup";
        Window: Dialog;
        Steps: Integer;
        MaxSteps: Integer;
        "0DF": DateFormula;
        XBasisData: Label 'Basis Data';
        XCurrency: Label 'Currency';
        XSTART: Label 'START';
        BudgetMonth: Integer;
        GLAccountFilter: array[8] of Code[250];
        AccountGroupFactor: array[8] of Decimal;
        BudgetMthFactor: array[12] of Decimal;
        XTEN: Label 'TEN';
        XDEERFIELD8WP: Label 'DEERFIELD, 8 WP';
        XGUILDFORD10CR: Label 'GUILDFORD, 10 CR';
        JobTaskIndent: Codeunit "Job Task-Indent";
        JobNo: Code[20];
        XVATSET: Label 'VATSET';
        XExchRateAdjustment: Label 'Exch. Rate Adj. as of %1';
        XERA: Label 'ERA';
        XOPERATION: Label 'OPERATION';
        XTAXACC: Label 'TAXACC';
        XFEACC: Label 'FEACC';
        XFETAX: Label 'FETAX';
        XVLE: Label 'VLE';
        XRECURRING: Label 'RECURRING';
        XFA: Label 'FA';
        XDEFAULT: Label 'DEFAULT';
        XOF: Label 'OF';
        XEH: Label 'EH';
        LY: Code[2];
        CY: Code[2];
        GLSetupShortcutDimCode: array[8] of Code[20];
        HasGotGLSetup: Boolean;
        XPO: Label 'PO';
        XPADV: Label 'PADV';
        XPRC: Label 'PRC';
        Text12411: Label 'DP-';
        Text12410: Label ' FA Depreciation';

    procedure Create()
    var
        Employee: Record Employee;
    begin
        DemoDataSetup.Get();
        Window.Open(DemoDataSetup."Progress Window Design");
        Window.Update(3, XBasisData);
        Steps := 0;
        MaxSteps := 199; // Number of calls to RunCodeunit
        RunCodeunit(CODEUNIT::"Create Price Calculation Setup");
        RunCodeunit(CODEUNIT::"Create Getting Started Data");
        RunCodeunit(CODEUNIT::"Create Profiles");
        RunCodeunit(CODEUNIT::"Create Default Permissions");
        RunCodeunit(CODEUNIT::"Create Source Code");
        RunCodeunit(CODEUNIT::"Create Payment Terms");
        RunCodeunit(CODEUNIT::"Create Currency");
        RunCodeunit(Codeunit::"Create Dispute Status");
        RunCodeunit(CODEUNIT::"Create Finance Charge Terms");
        RunCodeunit(CODEUNIT::"Create Finance Charge Text");
        RunCodeunit(CODEUNIT::"Create Reminder Terms");
        RunCodeunit(CODEUNIT::"Create Reminder Level");
        RunCodeunit(CODEUNIT::"Create Reminder Text");
        RunCodeunit(Codeunit::"Create Reminder Automation");
        RunCodeunit(CODEUNIT::"Create Language");
        RunCodeunit(CODEUNIT::"Create Country/Region");
        RunCodeunit(CODEUNIT::"Create Post Code");
        RunCodeunit(CODEUNIT::"Create Territory");
        RunCodeunit(CODEUNIT::"Create Shipment Method");
        RunCodeunit(CODEUNIT::"Create Shipping Agent");
        RunCodeunit(CODEUNIT::"Create Dimension");
        RunCodeunit(CODEUNIT::"Create Dimension Combination");
        RunCodeunit(CODEUNIT::"Create Unit of Measure");
        RunCodeunit(CODEUNIT::"Create Work Type");
        RunCodeunit(CODEUNIT::"Create Customer Disc. Group");
        RunCodeunit(CODEUNIT::"Create Item Disc. Group");
        RunCodeunit(CODEUNIT::"Create Item Tracking Codes");
        RunCodeunit(CODEUNIT::"Create Salesperson/Purchaser");
        RunCodeunit(CODEUNIT::"Create Location");
        RunCodeunit(CODEUNIT::"Create Cust. Invoice Disc.");
        RunCodeunit(CODEUNIT::"Create Sales Discount");
        RunCodeunit(CODEUNIT::"Create Vendor Invoice Disc.");
        RunCodeunit(CODEUNIT::"Create Rounding Method");
        RunCodeunit(CODEUNIT::"Create Accounting Period");
        RunCodeunit(CODEUNIT::"Create Company Information");
        RunCodeunit(Codeunit::"Create Allocation Accounts");
        RunCodeunit(CODEUNIT::"Create Analysis View");
        RunCodeunit(CODEUNIT::"Create Acc. Schedule Name");
        RunCodeunit(CODEUNIT::"Create Acc. Schedule Line");
        RunCodeunit(CODEUNIT::"Create Column Layout Name");
        RunCodeunit(CODEUNIT::"Create Column Layout");
        RunCodeunit(CODEUNIT::"Create Sales & Receivables S.");
        RunCodeunit(CODEUNIT::"Create Purchases & Payables S.");
        RunCodeunit(CODEUNIT::"Create General Ledger Setup");
        RunCodeunit(CODEUNIT::"Create Inventory Setup");
        RunCodeunit(CODEUNIT::"Create Business Relation");
        RunCodeunit(CODEUNIT::"Create Salutation");
        RunCodeunit(CODEUNIT::"Create Marketing Setup");
        RunCodeunit(CODEUNIT::"Create Resources Setup");
        RunCodeunit(CODEUNIT::"Create Jobs Setup");
        RunCodeunit(CODEUNIT::"Create Human Resources Setup");
        RunCodeunit(CODEUNIT::"Create Cost Acct. Setup");
        RunCodeunit(CODEUNIT::"Create Human Resources Uom");
        RunCodeunit(CODEUNIT::"Create Req. Wksh. Template");
        RunCodeunit(CODEUNIT::"Create Requisition Wksh. Name");
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then begin
            RunCodeunit(CODEUNIT::"Create VAT Bus. Posting Gr.");
            RunCodeunit(CODEUNIT::"Create VAT Prod. Posting Gr.");
        end;
        RunCodeunit(CODEUNIT::"Create Gen. Bus. Posting Gr.");
        RunCodeunit(CODEUNIT::"Create Gen. Prod. Posting Gr.");
        RunCodeunit(CODEUNIT::"Create Transaction Type");
        RunCodeunit(CODEUNIT::"Create Transport Method");
        RunCodeunit(CODEUNIT::"Create Tariff Number");
        RunCodeunit(CODEUNIT::"Create G/L Account");
        RunCodeunit(CODEUNIT::"Create VAT Posting Setup");
        RunCodeunit(CODEUNIT::"Create VAT Assisted Setup");
        RunCodeunit(CODEUNIT::"Create General Posting Setup");
        RunCodeunit(CODEUNIT::"Create Cust. Posting Group");
        RunCodeunit(CODEUNIT::"Create Vendor Posting Group");
        RunCodeunit(CODEUNIT::"Create Job Posting Group");
        RunCodeunit(CODEUNIT::"Create Bank Acc. Posting Group");
        RunCodeunit(CODEUNIT::"Create Data Exch. Column Def");
        RunCodeunit(CODEUNIT::"Create Bank Account");
        RunCodeunit(CODEUNIT::"Create Payment Method");
        RunCodeunit(CODEUNIT::"Create Item Charges");
        RunCodeunit(CODEUNIT::"Create Return Reasons");
        if DemoDataSetup."Tax Accounting" then begin
            RunCodeunit(CODEUNIT::"Update Tax Register Setup");
            CreateTaxDiffSetup.CreateTaxDifferences();
        end;

        Window.Update(1, XCurrency);
        "Create Currency".ModifyData();

        if not DemoDataSetup."Skip creation of master data" then begin
            RunCodeunit(CODEUNIT::"Create Customer");
            RunCodeunit(CODEUNIT::"Create Ship-to Address");
        end;

        RunCodeunit(CODEUNIT::"Create Vendor");

        if not DemoDataSetup."Skip creation of master data" then begin
            RunCodeunit(CODEUNIT::"Create Order Address");
            RunCodeunit(CODEUNIT::"Create C/V Bank Account");
            RunCodeunit(CODEUNIT::"Create Item");
            RunCodeunit(CODEUNIT::"Create Item Translation");

            RunCodeunit(CODEUNIT::"Create Item Unit of Measure");
            RunCodeunit(CODEUNIT::"Create Unit of Measure Trans.");
            RunCodeunit(CODEUNIT::"Create Extended text");
            RunCodeunit(CODEUNIT::"Create Sales Price");
            RunCodeunit(CODEUNIT::"Create Resource");
            RunCodeunit(CODEUNIT::"Create Res. Unit of Measure");
            RunCodeunit(CODEUNIT::"Create Resource Capacity Entry");

            RunCodeunit(CODEUNIT::"Create Default Dimension");

            RunCodeunit(CODEUNIT::"Create Job");
            RunCodeunit(CODEUNIT::"Create Job G/L Prices");
            RunCodeunit(CODEUNIT::"Create Job Item Prices");
            RunCodeunit(CODEUNIT::"Create Job Resource Prices");
            RunCodeunit(CODEUNIT::"Create Job Task");

            if not DemoDataSetup."Skip sequence of actions" then
                RunCodeunit(CODEUNIT::"Create Job Planning Lines");

            Evaluate(JobNo, XGUILDFORD10CR);
            JobTaskIndent.Indent(JobNo);
            Evaluate(JobNo, XDEERFIELD8WP);
            JobTaskIndent.Indent(JobNo);

            RunCodeunit(CODEUNIT::"Create Comment Line");
            RunCodeunit(CODEUNIT::"Create BOM Component");
        end;
        RunCodeunit(CODEUNIT::"Create Item Posting Group");
        RunCodeunit(CODEUNIT::"Create Inventory Posting Setup");
        RunCodeunit(CODEUNIT::"Create WIP Accounts");
        if not DemoDataSetup."Skip creation of master data" then begin
            RunCodeunit(CODEUNIT::"Create Item Vendor");
            RunCodeunit(CODEUNIT::"Create Purchase Price");
            RunCodeunit(CODEUNIT::"Create Purch. Line Discount");
        end;
        RunCodeunit(CODEUNIT::"Create Relative");
        RunCodeunit(CODEUNIT::"Create Causes of Absence");
        RunCodeunit(CODEUNIT::"Create Confidential");
        RunCodeunit(CODEUNIT::"Create Union");
        RunCodeunit(CODEUNIT::"Create Cause of Inactivity");
        RunCodeunit(CODEUNIT::"Create Ground for Termination");
        RunCodeunit(CODEUNIT::"Create Employment Contract");
        RunCodeunit(CODEUNIT::"Create Employee Stat. Group");
        RunCodeunit(CODEUNIT::"Create Misc. Article");
        RunCodeunit(CODEUNIT::"Create Qualification");
        RunCodeunit(CODEUNIT::"Create Employee");
        if not DemoDataSetup."Skip creation of master data" then begin
            RunCodeunit(CODEUNIT::"Create Employee Qualification");
            RunCodeunit(CODEUNIT::"Create Employee Relative");
            RunCodeunit(CODEUNIT::"Create Employee Absence");
            RunCodeunit(CODEUNIT::"Create Misc. Article Info");
            RunCodeunit(CODEUNIT::"Create Confidential Info.");
            RunCodeunit(CODEUNIT::"Create Alternative Address");
        end else begin
            Employee.SetFilter("No.", '<>%1&<>%2', XOF, XEH);
            Employee.DeleteAll();
        end;
        RunCodeunit(CODEUNIT::"Create FA Setup");
        RunCodeunit(CODEUNIT::"Create FA Jnl. Template");
        RunCodeunit(CODEUNIT::"Create FA Jnl. Batch");
        RunCodeunit(CODEUNIT::"Create FA Recl. Jnl. Template");
        RunCodeunit(CODEUNIT::"Create FA Recl. Jnl. Batch");
        RunCodeunit(CODEUNIT::"Create FA Ins. Jnl. Template");
        RunCodeunit(CODEUNIT::"Create FA Ins. Jnl. Batch");
        RunCodeunit(CODEUNIT::"Create FA Posting Group");
        RunCodeunit(CODEUNIT::"Create FA Allocation");
        RunCodeunit(CODEUNIT::"Create FA Class");
        RunCodeunit(CODEUNIT::"Create FA Subclass");
        RunCodeunit(CODEUNIT::"Create FA Location");
        RunCodeunit(CODEUNIT::"Create FA Maintenance");
        RunCodeunit(CODEUNIT::"Create Depreciation Book");
        RunCodeunit(CODEUNIT::"Create FA Insurance Type");
        RunCodeunit(CODEUNIT::"Create FA Journal Setup");

        ImportDataByXMLPort(XMLPORT::OKATO, 'RUS_OKATO.xml');
        RunCodeunit(CODEUNIT::"Create Assessed Tax Allowance");
        RunCodeunit(CODEUNIT::"Create Assessed Tax Code");
        RunCodeunit(CODEUNIT::"Create Tax Authority");
        RunCodeunit(CODEUNIT::"Setup Assessed Tax");
        RunCodeunit(CODEUNIT::"Create FA Doc. Sign. Setup");

        if not DemoDataSetup."Skip creation of master data" then begin
            RunCodeunit(CODEUNIT::"Create Fixed Asset");
            RunCodeunit(CODEUNIT::"Create FA Depreciation Book");
            RunCodeunit(CODEUNIT::"Create FA Maint. Registration");
            RunCodeunit(CODEUNIT::"Create FA Insurance");
            RunCodeunit(CODEUNIT::"Create FA Main Asset Comp.");
            if not DemoDataSetup."Skip sequence of actions" then
                RunCodeunit(CODEUNIT::"Create Purchase Header");
            if not DemoDataSetup."Skip sequence of actions" then
                RunCodeunit(CODEUNIT::"Create Purchase Line");
            if not DemoDataSetup."Skip sequence of actions" then
                RunCodeunit(CODEUNIT::"Create Sales Header");
            if not DemoDataSetup."Skip sequence of actions" then
                RunCodeunit(CODEUNIT::"Create Sales Line");
        end;
        RunCodeunit(CODEUNIT::"Create Item Journal Template");
        RunCodeunit(CODEUNIT::"Create Item Journal Batch");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(CODEUNIT::"Create Item Journal Line");
        RunCodeunit(CODEUNIT::"Create Gen. Journal Template");
        RunCodeunit(CODEUNIT::"Create Gen. Journal Batch");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(CODEUNIT::"Create Gen. Journal Line");
        RunCodeunit(CODEUNIT::"Create Res. Journal Template");
        RunCodeunit(CODEUNIT::"Create Res. Journal Batch");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(CODEUNIT::"Create Resource Journal Line");
        RunCodeunit(CODEUNIT::"Create Job Journal Template");
        RunCodeunit(CODEUNIT::"Create Job Journal Batch");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(CODEUNIT::"Create Job Journal Line");
        RunCodeunit(CODEUNIT::"Create Curr for Fin Chrg Terms");
        RunCodeunit(CODEUNIT::"Create Curr for Reminder Level");
        if not DemoDataSetup."Skip creation of master data" then begin
            RunCodeunit(CODEUNIT::"Create G/L Budget Name");
            RunCodeunit(CODEUNIT::"Create G/L Budget Entry");
            RunCodeunit(CODEUNIT::"Create Std. Sales Code");
            RunCodeunit(CODEUNIT::"Create Std. Sales Line");
            RunCodeunit(CODEUNIT::"Create Std. Cust. Sales Code");
            RunCodeunit(CODEUNIT::"Create Std. Purchase Code");
            RunCodeunit(CODEUNIT::"Create Std. Purchase Line");
            RunCodeunit(CODEUNIT::"Create Std. Vend. Purch. Code");
            RunCodeunit(CODEUNIT::"Create Std. Gen. Journal");
            RunCodeunit(CODEUNIT::"Create Std. Gen. Journal Line");
            RunCodeunit(CODEUNIT::"Create Std. Item Journal");
            RunCodeunit(CODEUNIT::"Create Std. Item Journal Line");
        end;

        RunCodeunit(CODEUNIT::"Create Analysis Type");
        RunCodeunit(CODEUNIT::"Create Analysis Column Temp");
        RunCodeunit(CODEUNIT::"Create Analysis Column");
        RunCodeunit(CODEUNIT::"Create Item Budget Name");
        RunCodeunit(CODEUNIT::"Create Item Budget Entry");
        RunCodeunit(CODEUNIT::"Create Item Analysis View");
        RunCodeunit(CODEUNIT::"Create Analysis Line Templates");
        RunCodeunit(CODEUNIT::"Create Analysis Line");
        RunCodeunit(CODEUNIT::"Create Analysis Report Name");

        RunCodeunit(CODEUNIT::"Create Cost Center");
        RunCodeunit(CODEUNIT::"Create Cost Object");
        RunCodeunit(CODEUNIT::"Create Cost Types");
        RunCodeunit(CODEUNIT::"Create Cost Allocation Source");
        RunCodeunit(CODEUNIT::"Create Cost Allocation Target");
        RunCodeunit(CODEUNIT::"Create Cost Acct. Jnl Template");
        RunCodeunit(CODEUNIT::"Create Cost Acct. Jnl Batch");
        RunCodeunit(CODEUNIT::"Create Cost Acct. Jnl Line");
        RunCodeunit(CODEUNIT::"Create Cost Budget Name");
        RunCodeunit(CODEUNIT::"Create Cost Budget Lines");

        RunCodeunit(CODEUNIT::"Create Payment Reg. Setup");

        InsertOnlineMapSetup();

        RunCodeunit(CODEUNIT::"Create Chart Definitions");

        RunCodeunit(CODEUNIT::"Create Cue Setup");

        if Currency.Get(DemoDataSetup."Currency Code") then
            Currency.Delete(true);

        RunCodeunit(CODEUNIT::"Create Named Forward Links");

        RunCodeunit(CODEUNIT::"Create Web Services");
        RunCodeunit(CODEUNIT::"Create Custom Report Layout");
        RunCodeunit(CODEUNIT::"Create Media Repository");
        RunCodeunit(CODEUNIT::"Create Excel Templates");
        RunCodeunit(Codeunit::"Create Word Templates");
        RunCodeunit(CODEUNIT::"Create Incoming Document");
        RunCodeunit(CODEUNIT::"Create Text To Account Mapping");
        RunCodeunit(CODEUNIT::"Create Late Payment Model");
        RunCodeunit(Codeunit::"Create Over-Receipt Code");
        CreateNewTemplates();

        RunCodeunit(Codeunit::"Create Notification Setup");
        RunCodeunit(CODEUNIT::"Create Reminder Communication");

        Window.Close();
    end;

    procedure BeforePosting()
    begin
    end;

    procedure Post(PostingDate: Date)
    var
        SavedWorkdate: Date;
        XCLOSE: Label 'CLOSE';
    begin
        DemoDataSetup.Get();

        LY := CopyStr(Format(DemoDataSetup."Starting Year"), 3, 2);
        CY := IncStr(LY);

        PostItemJournalLines(PostingDate);
        PostResourceJournalLines(PostingDate);
        PostJobJournalLines(PostingDate);
        InvoicePurchases(PostingDate);
        ShipSales(PostingDate);
        InvoiceSales(PostingDate);

        PostGeneralJournalLines(NormalDate(PostingDate));
        PostGeneralJournalLines(ClosingDate(PostingDate));
        PostFADocs(PostingDate);
        PostInvtDocs(PostingDate);
        PostFAVATSettlement(PostingDate);

        if IsEndMonthDate(PostingDate) then begin
            // Post Inventory Cost
            Clear(PostInventoryCostToGL);
            PostInventoryCostToGL.InitializeRequest(1, '', true);
            PostInventoryCostToGL.UseRequestPage(false);
            //if DemoDataSetup."Path to Print Files (HTML)" = '' then
            //    PostInventoryCostToGL.RunModal
            //else
            PostInventoryCostToGL.SaveAsPdf(
              TemporaryPath + Format(CreateGuid()) + '.pdf');

            // Data Exchange Rate Adjustments
            Clear(ExchRateAdjustment);
            ExchRateAdjustment.InitializeRequest2(
                CalcDate('<-CM>', PostingDate), PostingDate, StrSubstNo(XExchRateAdjustment, PostingDate),
                PostingDate, XERA + CopyStr(Format(PostingDate), 3, 4), false, false);
            ExchRateAdjustment.UseRequestPage(false);
            ExchRateAdjustment.SetHideUI(true);
            ExchRateAdjustment.Run();

            // Calculate FA depreciation
            PostDepreciation(XOPERATION, PostingDate);
            PostDepreciation(XTAXACC, PostingDate);
            PostDepreciation(XFEACC, PostingDate);
            PostDepreciation(XFETAX, PostingDate);
            PostGeneralJournalLines(NormalDate(PostingDate));
            PostFAJournalLines(PostingDate);

            // Post Tax Accounting Disposal
            PostTaxAccountingDisposal(PostingDate);
        end;

        // IF IsEndYearDate(PostingDate) THEN BEGIN
        if PostingDate = CA.AdjustDate(19021031D) then begin
            // Make physical inventory
            CalcQty.Run();
            PostItemJournalLines(PostingDate);
            "Run Post Inventory Cost to G/L".Run();
            PostGeneralJournalLines(NormalDate(PostingDate));

            "Adjust Inventory Value".Run();
            PostGeneralJournalLines(NormalDate(PostingDate));
        end;

        Commit();

        if PostingDate = CA.AdjustDate(19021031D) then begin
            // Close month
            SavedWorkdate := WorkDate();
            WorkDate(PostingDate);
            PostRecurringGenJnlLines(NormalDate(PostingDate), XCLOSE + '_20');
            PostRecurringGenJnlLines(NormalDate(PostingDate), XCLOSE + '_26');
            PostRecurringGenJnlLines(NormalDate(PostingDate), XCLOSE + '_44');
            PostRecurringGenJnlLines(NormalDate(PostingDate), XCLOSE + '_9091');
            WorkDate(SavedWorkDate);
        end;

        if PostingDate = CA.AdjustDate(19021130D) then begin
            // Close month
            SavedWorkdate := WorkDate();
            WorkDate(PostingDate);
            PostRecurringGenJnlLines(NormalDate(PostingDate), XCLOSE + '_20');
            PostRecurringGenJnlLines(NormalDate(PostingDate), XCLOSE + '_26');
            PostRecurringGenJnlLines(NormalDate(PostingDate), XCLOSE + '_44');
            PostRecurringGenJnlLines(NormalDate(PostingDate), XCLOSE + '_9091');
            WorkDate(SavedWorkDate);
        end;

        if PostingDate = CA.AdjustDate(19021231D) then begin
            // Close month
            SavedWorkdate := WorkDate();
            WorkDate(PostingDate);
            PostRecurringGenJnlLines(NormalDate(PostingDate), XCLOSE + '_20');
            PostRecurringGenJnlLines(NormalDate(PostingDate), XCLOSE + '_26');
            PostRecurringGenJnlLines(NormalDate(PostingDate), XCLOSE + '_44');
            PostRecurringGenJnlLines(NormalDate(PostingDate), XCLOSE + '_9091');
            WorkDate(SavedWorkDate);
        end;

        if PostingDate = CA.AdjustDate(19030131D) then
            "Run Post Inventory Cost to G/L".Run();
    end;

    procedure AfterPosting()
    var
        AccountingPeriod: Record "Accounting Period";
        GenJournalTemplate: Record "Gen. Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        "Create Sales & Receivables S.": Codeunit "Create Sales & Receivables S.";
        "Create Purchases & Payables S.": Codeunit "Create Purchases & Payables S.";
        UpdateAnalysisView: Codeunit "Update Item Analysis View";
        "Create Item Journal Batch": Codeunit "Create Item Journal Batch";
        TransferGLEntriesToCA: Codeunit "Transfer GL Entries to CA";
    begin
        DemoDataSetup.Get();
        ModifyGeneralJournals();
        MakeBudget();
        AccountingPeriod.Reset();
        AccountingPeriod.SetFilter("Starting Date", '<%1', CA.AdjustDate(19020101D));
        AccountingPeriod.ModifyAll(Closed, true);
        AccountingPeriod.ModifyAll("Date Locked", true);

        GenJournalTemplate.Reset();
        GenJournalTemplate.Get(XSTART);
        GenJournalTemplate.Delete(true); // Deletes also the Gen. Journal Batch

        "Create Sales & Receivables S.".Finalize();
        "Create Purchases & Payables S.".Finalize();
        "Create Item Journal Batch".ModifyItemBatch();

        ItemJournalLine.Reset();
        ItemJournalLine.DeleteAll();

        UpdateAnalysisView.UpdateAll(2, false);
        CODEUNIT.Run(CODEUNIT::"Update Acc. Sched. KPI Data");
        TransferGLEntriesToCA.TransferGLtoCA();
    end;

    procedure RunCodeunit(CodeunitID: Integer)
    var
        AllObj: Record AllObj;
    begin
        AllObj.Get(AllObj."Object Type"::Codeunit, CodeunitID);
        Window.Update(1, StrSubstNo('%1 %2', AllObj."Object ID", AllObj.Name));
        Steps := Steps + 1;
        Window.Update(2, Round(Steps / MaxSteps * 10000, 1));
        CODEUNIT.Run(CodeunitID);
    end;

    procedure PostItemJournalLines(Date: Date)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        ItemJournalLine.SetRange("Posting Date", Date);
        if ItemJournalLine.Find('-') then begin
            repeat
                ItemJnlPostLine.RunWithCheck(ItemJournalLine);
            until ItemJournalLine.Next() = 0;
            ItemJournalLine.DeleteAll();
        end;
    end;

    procedure PostResourceJournalLines(Date: Date)
    var
        ResJournalLine: Record "Res. Journal Line";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
    begin
        ResJournalLine.SetRange("Posting Date", Date);
        if ResJournalLine.Find('-') then begin
            repeat
                ResJnlPostLine.RunWithCheck(ResJournalLine);
            until ResJournalLine.Next() = 0;
            ResJournalLine.DeleteAll();
        end;
    end;

    procedure PostJobJournalLines(Date: Date)
    var
        JobJournalLine: Record "Job Journal Line";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
    begin
        JobJournalLine.SetRange("Posting Date", Date);
        if JobJournalLine.Find('-') then begin
            repeat
                JobJnlPostLine.RunWithCheck(JobJournalLine);
            until JobJournalLine.Next() = 0;
            JobJournalLine.DeleteAll();
        end;
    end;

    procedure InvoicePurchases(Date: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
        FA: Record "Fixed Asset";
        PurchPost: Codeunit "Purch.-Post";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
    begin
        PurchaseHeader.SetRange("Posting Date", Date);
        if PurchaseHeader.Find('-') then
            repeat
                PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
                PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
                if PurchaseLine.FindFirst() then begin
                    PurchCalcDiscount.Run(PurchaseLine);
                    Clear(PurchCalcDiscount);
                    PurchaseHeader.Find();
                end;
                // Item Charge assignment
                if (PurchaseHeader."No." = XPO + '-' + LY + '-00021') or
                   (PurchaseHeader."No." = XPO + '-' + LY + '-00023')
                then begin
                    if PurchaseHeader."No." = XPO + '-' + LY + '-00021' then
                        PurchRcptHeader.Get(XPRC + '-' + LY + '-00029');
                    if PurchaseHeader."No." = XPO + '-' + LY + '-00023' then
                        PurchRcptHeader.Get(XPRC + '-' + LY + '-00031');
                    PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
                    PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
                    PurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
                    if PurchaseLine.Find('-') then
                        repeat
                            PurchRcptItemChargeAssgnt(PurchaseLine, PurchRcptHeader);
                        until PurchaseLine.Next() = 0;
                end;
                if PurchaseHeader."No." = XPO + '-' + LY + '-00028' then begin
                    PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
                    PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
                    PurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
                    if PurchaseLine.Find('-') then
                        repeat
                            PurchOrderItemChargeAssgnt(PurchaseLine, PurchaseHeader);
                        until PurchaseLine.Next() = 0;
                end;
                // Employee Purchase
                if PurchaseHeader."No." = XPADV + '-' + LY + '-00004' then begin
                    VendLedgEntry.Reset();
                    VendLedgEntry.SetRange("Vendor No.", XVLE + '014');
                    VendLedgEntry.SetRange("Posting Date", CA.AdjustDate(19021003D));
                    VendLedgEntry.FindFirst();
                    PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
                    PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
                    PurchaseLine.SetRange(Type, PurchaseLine.Type::"Empl. Purchase");
                    PurchaseLine.Validate("Empl. Purchase Entry No.", VendLedgEntry."Entry No.");
                    PurchaseLine.Modify();
                end;
                // FA in montage
                if PurchaseHeader."No." = XPO + '-' + LY + '-00029' then begin
                    FA.Get(XFA + '002');
                    FA.Status := FA.Status::Montage;
                    FA.Modify();
                end;

                if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then
                    PurchaseHeader.Ship := true;
                PurchaseHeader.Receive := true;
                PurchaseHeader.Invoice := true;
                PurchPost.Run(PurchaseHeader);
                Clear(PurchPost);
            until PurchaseHeader.Next() = 0;
    end;

    procedure ShipSales(Date: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesPost: Codeunit "Sales-Post";
        DateDisplacement: Text[1];
    begin
        SalesHeader.SetRange("Posting Date", Date);
        if SalesHeader.Find('-') then
            repeat
                if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then begin
                    DateDisplacement := CopyStr(SalesHeader."No.", StrLen(SalesHeader."No."), 1);
                    if DateDisplacement in ['1', '3', '5', '7', '9'] then begin // Partial Shipment
                        SalesLine.Reset();
                        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                        SalesLine.SetRange("Document No.", SalesHeader."No.");
                        SalesShipmentHeader.Reset();
                        SalesShipmentHeader.SetCurrentKey("Order No.", "No.");
                        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
                        if SalesLine.Find('-') and (SalesShipmentHeader.Count <= 1) then
                            repeat
                                if SalesLine."Qty. to Ship" > 1 then begin
                                    SalesLine.Validate("Qty. to Ship", SalesLine."Qty. to Ship" div 2);
                                    SalesLine.Validate("Qty. to Invoice", 0);
                                    SalesLine.Modify();
                                end;
                            until SalesLine.Next() = 0;
                    end;
                    SalesLine.Reset();
                    SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                    SalesLine.SetRange("Document No.", SalesHeader."No.");
                    SalesLine.SetFilter("Qty. to Ship", '<>0');
                    if SalesLine.Find('<>=') then begin
                        SalesHeader.Ship := true;
                        SalesHeader.Invoice := false;
                        SalesPost.Run(SalesHeader);
                        Clear(SalesPost);
                        if DateDisplacement = '0' then
                            DateDisplacement := '1';
                        SalesHeader."Posting Date" := CalcDate('<' + DateDisplacement + 'D>', SalesHeader."Posting Date");
                        SalesHeader.Modify();
                    end;
                end;
            until SalesHeader.Next() = 0;
    end;

    procedure InvoiceSales(Date: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPost: Codeunit "Sales-Post";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
    begin
        SalesHeader.SetRange("Posting Date", Date);
        if SalesHeader.Find('-') then
            repeat
                SalesLine.Reset();
                SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                SalesLine.SetRange("Document No.", SalesHeader."No.");
                SalesLine.SetFilter("Qty. to Invoice", '<>0');
                if SalesLine.Find('<>=') then begin
                    SalesLine.SetRange("Qty. to Invoice");
                    SalesCalcDiscount.Run(SalesLine);
                    Clear(SalesCalcDiscount);
                    SalesHeader.Find();
                    if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
                        SalesHeader.Receive := true;
                    SalesHeader.Ship := false;
                    SalesHeader.Invoice := true;
                    SalesPost.Run(SalesHeader);
                    Clear(SalesPost);
                end;
            until SalesHeader.Next() = 0;
    end;

    procedure PostGeneralJournalLines(Date: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        GenJournalLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date");
        GenJournalLine.SetRange("Posting Date", Date);
        GenJournalLine.SetRange(Quantity, 0);
        GenJournalLine.SetRange("Recurring Method", 0);
        if GenJournalLine.Find('-') then begin
            repeat
                if GenJournalLine."Applies-to Doc. No." <> '' then
                    case GenJournalLine."Account Type" of
                        GenJournalLine."Account Type"::Customer:
                            begin
                                CustLedgerEntry.Reset();
                                CustLedgerEntry.SetCurrentKey("Document No.");
                                CustLedgerEntry.SetRange("Document Type", GenJournalLine."Applies-to Doc. Type");
                                CustLedgerEntry.SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
                                CustLedgerEntry.FindFirst();
                                CustLedgerEntry.CalcFields("Remaining Amount");
                                GenJournalLine.Validate(Amount, -CustLedgerEntry."Remaining Amount");
                            end;
                        GenJournalLine."Account Type"::Vendor:
                            begin
                                VendorLedgerEntry.Reset();
                                VendorLedgerEntry.SetCurrentKey("Document No.");
                                VendorLedgerEntry.SetRange("Document Type", GenJournalLine."Applies-to Doc. Type");
                                VendorLedgerEntry.SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
                                VendorLedgerEntry.FindFirst();
                                VendorLedgerEntry.CalcFields("Remaining Amount");
                                GenJournalLine.Validate("Account No.", VendorLedgerEntry."Vendor No.");
                                GenJournalLine.Validate(Amount, -VendorLedgerEntry."Remaining Amount");
                            end;
                    end;
                if GenJournalLine."Journal Template Name" <> XVATSET then
                    GenJnlPostLine.RunWithCheck(GenJournalLine);
            until GenJournalLine.Next() = 0;
            GenJournalLine.SetFilter("Journal Template Name", '<>%1', XVATSET);
            GenJournalLine.DeleteAll();
        end;
    end;

    procedure CalcBalance(GLAccNo: Code[20]): Decimal
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccNo);
        GLAccount.CalcFields(Balance);
        exit(GLAccount.Balance);
    end;

    procedure CalcLineAmount(Quantity: Decimal; BalanceAmount: Decimal; var AllocatedAmount: Decimal) LineAmount: Decimal
    begin
        if Quantity > 0 then
            LineAmount := Round(BalanceAmount / 100 * Quantity)
        else
            LineAmount := BalanceAmount - AllocatedAmount;
        AllocatedAmount := AllocatedAmount + LineAmount;
    end;

    procedure InsertBankAccStmt("Bank Account No.": Code[20]; PostingDate: Date)
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        SuggestLines: Report "Suggest Bank Acc. Recon. Lines";
        PostBankAccRecon: Codeunit "Bank Acc. Reconciliation Post";
    begin
        BankAccRecon.Init();
        BankAccRecon.Validate("Bank Account No.", "Bank Account No.");
        BankAccRecon.Validate("Statement Date", PostingDate);
        BankAccRecon.Insert();

        SuggestLines.SetStmt(BankAccRecon);
        SuggestLines.InitializeRequest(0D, PostingDate, false);
        SuggestLines.UseRequestPage(false);
        SuggestLines.RunModal();

        BankAccReconLine.FilterBankRecLines(BankAccRecon);
        BankAccReconLine.CalcSums(BankAccReconLine."Statement Amount");

        BankAccRecon.Validate(
          "Statement Ending Balance",
          BankAccRecon."Balance Last Statement" + BankAccReconLine."Statement Amount");
        BankAccRecon.Modify();

        PostBankAccRecon.Run(BankAccRecon);
    end;

    procedure ModifyGeneralJournals()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        LastNo: Code[20];
        NewLastNo: Code[20];
    begin
        if GenJournalBatch.Find('-') then
            repeat
                GenJournalTemplate.Get(GenJournalBatch."Journal Template Name");
                if GenJournalBatch.Name <> 'BANK' then
                    GenJournalBatch."No. Series" := GenJournalTemplate."No. Series";
                GenJournalBatch."Posting No. Series" := GenJournalTemplate."Posting No. Series";
                GenJournalBatch.Modify();
            until GenJournalBatch.Next() = 0;

        while GenJournalLine.Find('>') do begin
            GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
            GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
            GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
            if GenJournalBatch."No. Series" = '' then
                GenJournalLine.Find('+')
            else begin
                LastNo := '';
                NewLastNo := '';
                repeat
                    if GenJournalLine."Document No." <> '' then begin
                        if GenJournalLine."Document No." <> LastNo then
                            NewLastNo := NoSeriesBatch.GetNextNo(GenJournalBatch."No. Series");
                        LastNo := GenJournalLine."Document No.";
                        GenJournalLine."Document No." := NewLastNo;
                        GenJournalLine.Modify();
                    end;
                until GenJournalLine.Next() = 0;
            end;
            GenJournalLine.SetRange("Journal Template Name");
            GenJournalLine.SetRange("Journal Batch Name");
        end;
    end;

    procedure MakeBudget()
    var
        Dim: Record Dimension;
        SelectedDim: Record "Selected Dimension";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        CopyGLBudget: Report "Copy G/L Budget";
        DateFilter: Text[30];
    begin
        if Dim.Find('-') then
            repeat
                SelectedDim."User ID" := UserId;
                SelectedDim."Object Type" := 3;
                SelectedDim."Object ID" := REPORT::"Copy G/L Budget";
                SelectedDim."Dimension Code" := Dim.Code;
                SelectedDim.Insert();
            until Dim.Next() = 0;

        if DemoDataSetup."Test Demonstration Company" = true then begin
            DateFilter :=
              Format(DMY2Date(1, 1, DemoDataSetup."Starting Year" + 1)) +
              '..' + Format(DMY2Date(31, 12, DemoDataSetup."Starting Year" + 1));
            CopyGLBudget.Initialize(
              0, '', '', DateFilter, Format(DemoDataSetup."Starting Year" + 1), '', '', 0.96, '', "0DF", true);

            CopyGLBudget.UseRequestPage(false);
            CopyGLBudget.Run();
            SelectedDim.DeleteAll();
        end;

        UpdateAnalysisView.UpdateAll(2, false);
    end;

    procedure CopyYearBudget(MonthAdjustmentFactor: Decimal; BudgetYear: Integer)
    var
        BudgetDateFilter: Text[30];
        CopyGLBudget: Report "Copy G/L Budget";
        AccountGroup: Integer;
    begin
        AccountGroup := 0;
        repeat
            case BudgetMonth of
                1, 3, 5, 7, 8, 10, 12:
                    BudgetDateFilter :=
                      Format(DMY2Date(1, BudgetMonth, BudgetYear)) +
                      '..' + Format(DMY2Date(31, BudgetMonth, BudgetYear));
                2:
                    begin
                        BudgetDateFilter :=
                          Format(DMY2Date(1, BudgetMonth, BudgetYear)) +
                          '..' + Format(DMY2Date(28, BudgetMonth, BudgetYear));
                        if Date2DMY(DMY2Date(28, BudgetMonth, BudgetYear) + 1, 1) <> 1 then
                            BudgetDateFilter :=
                              Format(DMY2Date(1, BudgetMonth, BudgetYear)) +
                              '..' + Format(DMY2Date(29, BudgetMonth, BudgetYear));
                    end;
                4, 6, 9, 11:
                    BudgetDateFilter :=
                      Format(DMY2Date(1, BudgetMonth, BudgetYear)) +
                      '..' + Format(DMY2Date(30, BudgetMonth, BudgetYear));
            end;
            AccountGroup := AccountGroup + 1;
            CopyGLBudget.Initialize(
              0, '', GLAccountFilter[AccountGroup], BudgetDateFilter, Format(BudgetYear), '', '',
              Round(AccountGroupFactor[AccountGroup] * MonthAdjustmentFactor, 0.01), XTEN, "0DF", true);
            CopyGLBudget.UseRequestPage(false);
            CopyGLBudget.Run();
            Clear(CopyGLBudget);
        until AccountGroup = 8;
    end;

    procedure InitBudgetData()
    begin
        // GL Account numbers with the same budget factor

        GLAccountFilter[1] := StrSubstNo(
            '%1|%2|%3|%4|%5|%6', CA.Convert('996110'), CA.Convert('996230'), CA.Convert('998130'),
            CA.Convert('998420'), CA.Convert('998640'), CA.Convert('998830'));
        GLAccountFilter[2] := StrSubstNo(
            '%1|%2|%3|%4|%5|%6', CA.Convert('996120'), CA.Convert('996210'), CA.Convert('998210'),
            CA.Convert('998430'), CA.Convert('998710'), CA.Convert('998910'));
        GLAccountFilter[3] := StrSubstNo(
            '%1|%2|%3|%4|%5|%6', CA.Convert('996130'), CA.Convert('996220'), CA.Convert('998230'),
            CA.Convert('998450'), CA.Convert('998720'), CA.Convert('999110'));
        GLAccountFilter[4] := StrSubstNo(
            '%1|%2|%3|%4|%5|%6', CA.Convert('997110'), CA.Convert('997230'), CA.Convert('998240'),
            CA.Convert('998510'), CA.Convert('998730'), CA.Convert('999210'));
        GLAccountFilter[5] := StrSubstNo(
            '%1|%2|%3|%4|%5|%6', CA.Convert('997120'), CA.Convert('997210'), CA.Convert('998310'),
            CA.Convert('998520'), CA.Convert('998620'), CA.Convert('999220'));
        GLAccountFilter[6] := StrSubstNo(
            '%1|%2|%3|%4|%5|%6', CA.Convert('997130'), CA.Convert('997220'), CA.Convert('998320'),
            CA.Convert('998530'), CA.Convert('998750'), CA.Convert('999230'));
        GLAccountFilter[7] := StrSubstNo(
            '%1|%2|%3|%4|%5|%6', CA.Convert('996710'), CA.Convert('998110'), CA.Convert('998330'),
            CA.Convert('998740'), CA.Convert('998810'), CA.Convert('998820'));
        GLAccountFilter[8] := StrSubstNo(
            '%1|%2|%3|%4|%5', CA.Convert('996810'), CA.Convert('998120'), CA.Convert('998410'),
            CA.Convert('998630'), CA.Convert('999510'));

        // Budget Change factor due to account number

        AccountGroupFactor[1] := 0.98;
        AccountGroupFactor[2] := 0.99;
        AccountGroupFactor[3] := 0.98;
        AccountGroupFactor[4] := 1.02;
        AccountGroupFactor[5] := 1.01;
        AccountGroupFactor[6] := 1.0;
        AccountGroupFactor[7] := 0.96;
        AccountGroupFactor[8] := 1.0;

        // Budget Change factor due to month change

        BudgetMthFactor[1] := 1.0;
        BudgetMthFactor[2] := 1.12;
        BudgetMthFactor[3] := 0.84;
        BudgetMthFactor[4] := 1.16;
        BudgetMthFactor[5] := 0.89;
        BudgetMthFactor[6] := 1.07;
        BudgetMthFactor[7] := 0.87;
        BudgetMthFactor[8] := 0.89;
        BudgetMthFactor[9] := 1.13;
        BudgetMthFactor[10] := 1.0;
        BudgetMthFactor[11] := 0.86;
        BudgetMthFactor[12] := 1.05;
    end;

    local procedure InsertOnlineMapSetup()
    var
        OnlineMapMgt: Codeunit "Online Map Management";
    begin
        OnlineMapMgt.SetupDefault();
    end;

    procedure PostRecurringGenJnlLines(Date: Date; BatchName: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        GenJournalLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date");
        GenJournalLine.SetRange("Journal Template Name", XRECURRING);
        GenJournalLine.SetRange("Journal Batch Name", BatchName);
        GenJournalLine.SetRange("Posting Date", Date);
        GenJournalLine.SetRange(Quantity, 0);
        GenJournalLine.SetFilter("Recurring Method", '<>%1', 0);
        if GenJournalLine.Find('-') then
            repeat
                GenJnlPostLine.RunWithCheck(GenJournalLine);
                Commit();
            until GenJournalLine.Next() = 0;
    end;

    procedure PostFAJournalLines(Date: Date)
    var
        FAJournalLine: Record "FA Journal Line";
        PostFAJournalLine: Codeunit "FA Jnl.-Post Line";
    begin
        FAJournalLine.Reset();
        FAJournalLine.SetRange("Posting Date", 0D, Date);
        if FAJournalLine.Find('-') then begin
            repeat
                PostFAJournalLine.FAJnlPostLine(FAJournalLine, true);
            until FAJournalLine.Next() = 0;
            FAJournalLine.DeleteAll();
        end;
    end;

    procedure PostFADocs(Date: Date)
    var
        FADocumentHeader: Record "FA Document Header";
        FADocumentPost: Codeunit "FA Document-Post";
    begin
        FADocumentHeader.Reset();
        FADocumentHeader.SetRange("Posting Date", Date);
        if FADocumentHeader.FindSet() then
            repeat
                FADocumentPost.Run(FADocumentHeader);
            until FADocumentHeader.Next() = 0;
    end;

    procedure PostInvtDocs(Date: Date)
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocPostReceipt: Codeunit "Invt. Doc.-Post Receipt";
        InvtDocPostShipment: Codeunit "Invt. Doc.-Post Shipment";
    begin
        InvtDocumentHeader.SetRange("Posting Date", Date);
        if InvtDocumentHeader.FindSet() then
            repeat
                case InvtDocumentHeader."Document Type" of
                    InvtDocumentHeader."Document Type"::Receipt:
                        InvtDocPostReceipt.Run(InvtDocumentHeader);
                    InvtDocumentHeader."Document Type"::Shipment:
                        InvtDocPostShipment.Run(InvtDocumentHeader);
                end;
            until InvtDocumentHeader.Next() = 0;
    end;

    procedure PurchRcptItemChargeAssgnt(PurchLine: Record "Purchase Line"; PurchRcptHeader: Record "Purch. Rcpt. Header")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssgntRec: Record "Item Charge Assignment (Purch)";
        PurchHeader: Record "Purchase Header";
        ItemChargeAssgnt: Codeunit "Item Charge Assgnt. (Purch.)";
        AssignableQty: Decimal;
    begin
        ItemChargeAssgntRec.Init();
        ItemChargeAssgntRec."Document Type" := PurchLine."Document Type";
        ItemChargeAssgntRec."Document No." := PurchLine."Document No.";
        ItemChargeAssgntRec."Document Line No." := PurchLine."Line No.";
        ItemChargeAssgntRec."Item Charge No." := PurchLine."No.";
        ItemChargeAssgntRec."Unit Cost" := PurchLine."Direct Unit Cost";

        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        if PurchRcptLine.FindSet() then
            repeat
                ItemChargeAssgnt.CreateRcptChargeAssgnt(PurchRcptLine, ItemChargeAssgntRec);
            until PurchRcptLine.Next() = 0;

        AssignableQty := PurchLine."Qty. to Invoice" + PurchLine."Quantity Invoiced" - PurchLine."Qty. Assigned";
        PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
        ItemChargeAssgnt.AssignItemCharges(
          PurchLine, AssignableQty,
          CalcAssignableAmount(PurchLine, PurchHeader."Prices Including VAT"), ItemChargeAssgnt.AssignByAmountMenuText());
    end;

    procedure PurchOrderItemChargeAssgnt(PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    var
        PurchOrderLine: Record "Purchase Line";
        ItemChargeAssgntRec: Record "Item Charge Assignment (Purch)";
        ItemChargeAssgnt: Codeunit "Item Charge Assgnt. (Purch.)";
        AssignableQty: Decimal;
    begin
        ItemChargeAssgntRec.Init();
        ItemChargeAssgntRec."Document Type" := PurchLine."Document Type";
        ItemChargeAssgntRec."Document No." := PurchLine."Document No.";
        ItemChargeAssgntRec."Document Line No." := PurchLine."Line No.";
        ItemChargeAssgntRec."Item Charge No." := PurchLine."No.";
        ItemChargeAssgntRec."Unit Cost" := PurchLine."Direct Unit Cost";

        PurchOrderLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchOrderLine.SetRange("Document No.", PurchHeader."No.");
        if PurchOrderLine.FindSet() then
            repeat
                ItemChargeAssgnt.CreateDocChargeAssgnt(ItemChargeAssgntRec, PurchOrderLine."Receipt No.");
            until PurchOrderLine.Next() = 0;

        AssignableQty := PurchLine."Qty. to Invoice" + PurchLine."Quantity Invoiced" - PurchLine."Qty. Assigned";
        ItemChargeAssgnt.AssignItemCharges(
          PurchLine, AssignableQty,
          CalcAssignableAmount(PurchLine, PurchHeader."Prices Including VAT"), ItemChargeAssgnt.AssignByAmountMenuText());
    end;

    procedure IsEndMonthDate(Date: Date): Boolean
    begin
        exit(Date = CalcDate('<CM>', Date));
    end;

    procedure IsEndYearDate(Date: Date): Boolean
    begin
        exit(Date = CalcDate('<CY>', Date));
    end;

    procedure PostDepreciation(DepreciationBook: Code[10]; PostingDate: Date)
    var
        PostingDescription: Text[50];
        DocumentNo: Code[20];
        StartDate: Date;
    begin
        Clear(CreateDepreciation);
        StartDate := CalcDate('<-CM>', PostingDate);
        PostingDescription := Format(StartDate, 0, '<Month Text> ') + Format(Date2DMY(StartDate, 3)) + Text12410;
        if Date2DMY(StartDate, 2) > 9 then
            DocumentNo := Text12411 + Format(StartDate, 0, '<Year>-<Month>')
        else
            DocumentNo := Text12411 + Format(StartDate, 2, '<Year>') + '-0' + Format(StartDate, 0, '<Month>');

        CreateDepreciation.InitializeRequest2(
          DepreciationBook, PostingDate, PostingDate, DocumentNo, PostingDescription, false, 0, false, false, false);
        CreateDepreciation.UseRequestPage(false);
        CreateDepreciation.RunModal();
    end;

    procedure PostFAVATSettlement(Date: Date)
    var
        VATEntry: Record "VAT Entry";
        GenJnlLine2: Record "Gen. Journal Line";
        FA: Record "Fixed Asset";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        NextLineNo: Integer;
    begin
        VATEntry.Reset();
        VATEntry.SetCurrentKey(Type);
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.SetRange("Posting Date", Date);
        VATEntry.SetRange("Object Type", VATEntry."Object Type"::"Fixed Asset");
        VATEntry.SetFilter("Unrealized Base", '<>%1', 0);
        NextLineNo := 0;
        if VATEntry.FindSet() then begin
            repeat
                if FA.Get(VATEntry."Object No.") then
                    if FA."Initial Release Date" <> 0D then begin
                        GenJnlLine2.Init();
                        GenJnlLine2.Validate("Journal Template Name", XVATSET);
                        GenJnlLine2.Validate("Journal Batch Name", XDEFAULT);
                        NextLineNo := NextLineNo + 10000;
                        GenJnlLine2."Line No." := NextLineNo;
                        GenJnlLine2.Validate("Unrealized VAT Entry No.", VATEntry."Entry No.");
                        GenJnlLine2.Validate(Amount, -GenJnlLine2."Paid Amount");
                        GenJnlLine2.Insert();
                    end;
            until VATEntry.Next() = 0;

            GenJnlLine2.SetRange("Journal Template Name", XVATSET);
            GenJnlLine2.SetRange("Journal Batch Name", XDEFAULT);
            if GenJnlLine2.FindFirst() then begin
                Clear(GenJnlPostBatch);
                GenJnlPostBatch.VATSettlement(GenJnlLine2);
            end;
        end;
    end;

    procedure PostTaxAccountingDisposal(Date: Date)
    var
        "Posted FA Doc. Header": Record "Posted FA Doc. Header";
        "Write-off for Tax Ledger": Report "Write-off for Tax Ledger";
    begin
        Clear("Write-off for Tax Ledger");
        "Write-off for Tax Ledger".InitializeRequest(true, Date, true);
        "Posted FA Doc. Header".Reset();
        "Posted FA Doc. Header".SetRange("Document Type", "Posted FA Doc. Header"."Document Type"::Writeoff);
        "Posted FA Doc. Header".SetRange("Posting Date", CalcDate('<-CM>', Date), Date);
        if "Posted FA Doc. Header".FindFirst() then begin
            "Write-off for Tax Ledger".SetTableView("Posted FA Doc. Header");
            "Write-off for Tax Ledger".UseRequestPage(false);
            "Write-off for Tax Ledger".RunModal();
        end;
    end;

    local procedure CalcAssignableAmount(PurchLine: Record "Purchase Line"; PricesInclVAT: Boolean): Decimal
    begin
        if (PurchLine."Inv. Discount Amount" = 0) and
            (PurchLine."Line Discount Amount" = 0) and
            (not PricesInclVAT)
        then
            exit(PurchLine."Line Amount");

        if PricesInclVAT then
            exit(
              Round((PurchLine."Line Amount" - PurchLine."Inv. Discount Amount") / (1 + PurchLine."VAT %" / 100),
                Currency."Amount Rounding Precision"));

        exit(PurchLine."Line Amount" - PurchLine."Inv. Discount Amount");
    end;

    procedure ImportDataByXMLPort(XMLPortID: Integer; FileName: Text)
    var
        ImportFile: File;
        FileInStream: InStream;
    begin
        DemoDataSetup.Get();
        ImportFile.Open(StrSubstNo('LocalFiles\%1', FileName));
        ImportFile.CreateInStream(FileInStream);
        XMLPORT.Import(XMLPortID, FileInStream);
        ImportFile.Close();
    end;

    local procedure GetGLSetup()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if not HasGotGLSetup then begin
            GLSetup.Get();
            GLSetupShortcutDimCode[1] := GLSetup."Shortcut Dimension 1 Code";
            GLSetupShortcutDimCode[2] := GLSetup."Shortcut Dimension 2 Code";
            GLSetupShortcutDimCode[3] := GLSetup."Shortcut Dimension 3 Code";
            GLSetupShortcutDimCode[4] := GLSetup."Shortcut Dimension 4 Code";
            GLSetupShortcutDimCode[5] := GLSetup."Shortcut Dimension 5 Code";
            GLSetupShortcutDimCode[6] := GLSetup."Shortcut Dimension 6 Code";
            GLSetupShortcutDimCode[7] := GLSetup."Shortcut Dimension 7 Code";
            GLSetupShortcutDimCode[8] := GLSetup."Shortcut Dimension 8 Code";
            HasGotGLSetup := true;
        end;
    end;

    procedure AddDocDimValue(var DimSetID: Integer; DimNo: Integer; DimValueCode: Code[20])
    var
        DimValue: Record "Dimension Value";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
    begin
        if DimValueCode = '' then
            exit;

        GetGLSetup();
        if DimSetID <> 0 then
            DimMgt.GetDimensionSet(TempDimSetEntry, DimSetID);
        TempDimSetEntry."Dimension Code" := GLSetupShortcutDimCode[DimNo];
        TempDimSetEntry."Dimension Value Code" := DimValueCode;
        if not TempDimSetEntry.Find() then begin
            DimValue.Get(
              TempDimSetEntry."Dimension Code", TempDimSetEntry."Dimension Value Code");
            TempDimSetEntry."Dimension Value ID" :=
              DimValue."Dimension Value ID";
            TempDimSetEntry.Insert();
        end;

        DimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry);
    end;

    local procedure CreateNewTemplates()
    begin
        RunCodeunit(Codeunit::"Create New Customer Template");
        RunCodeunit(Codeunit::"Create New Item Template");
        RunCodeunit(Codeunit::"Create New Vendor Template");
        RunCodeunit(Codeunit::"Create New Employee Template");
    end;
}

