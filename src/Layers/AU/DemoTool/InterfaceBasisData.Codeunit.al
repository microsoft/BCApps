codeunit 110000 "Interface Basis Data"
{

    trigger OnRun()
    begin
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        Window: Dialog;
        Steps: Integer;
        MaxSteps: Integer;
        "Create Currency": Codeunit "Create Currency";
        CA: Codeunit "Make Adjustments";
        "Make Corrections": Codeunit "Make Corrections";
        "Run Post Inventory Cost to G/L": Codeunit "Run Post Inventory Cost to G/L";
        CalcQty: Codeunit "Create Item Ledger,Phys. Invt.";
        "Adjust Inventory Value": Codeunit "Adjust Inventory Value";
        "0DF": DateFormula;
        XBasisData: Label 'Basis Data';
        XCurrency: Label 'Currency';
        XWWBOPERATING: Label 'WWB-OPERATING';
        XNBL: Label 'NBL';
        XSTART: Label 'START';
        XNotallopnngentrieswrposted: Label 'Not all opening entries were posted.';
        BudgetMonth: Integer;
        GLAccountFilter: array[8] of Code[250];
        AccountGroupFactor: array[8] of Decimal;
        BudgetMthFactor: array[12] of Decimal;
        XTEN: Label 'TEN';
        XDEERFIELD8WP: Label 'DEERFIELD, 8 WP';
        XGUILDFORD10CR: Label 'GUILDFORD, 10 CR';
        JobTaskIndent: Codeunit "Job Task-Indent";
        JobNo: Code[20];

    procedure Create()
    begin
        DemoDataSetup.Get();
        Window.Open(DemoDataSetup."Progress Window Design");
        Window.Update(3, XBasisData);
        Steps := 0;
        MaxSteps := 202; // Number of calls to RunCodeunit
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
        RunCodeunit(CODEUNIT::"Create General Ledger Setup");
        RunCodeunit(CODEUNIT::"Create Sales & Receivables S.");
        RunCodeunit(CODEUNIT::"Create Purchases & Payables S.");
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
        RunCodeunit(CODEUNIT::"Create VAT Statement Template");
        RunCodeunit(CODEUNIT::"Create VAT Statement Name");
        RunCodeunit(CODEUNIT::"Create VAT Statement Line");
        RunCodeunit(CODEUNIT::"Create VAT Report Configs");
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
        RunCodeunit(CODEUNIT::"Create WHT Setup");
        RunCodeunit(CODEUNIT::"Create Payment Method");
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax" then begin
            RunCodeunit(CODEUNIT::"Create Tax Areas");
            RunCodeunit(CODEUNIT::"Create Tax Jurisdictions");
            RunCodeunit(CODEUNIT::"Create Tax Groups");
            RunCodeunit(CODEUNIT::"Create Tax Area Lines");
            RunCodeunit(CODEUNIT::"Create Tax Details");
        end;
        RunCodeunit(CODEUNIT::"Create Item Charges");
        RunCodeunit(CODEUNIT::"Create Return Reasons");

        Window.Update(1, XCurrency);
        "Create Currency".ModifyData();

        RunCodeunit(CODEUNIT::"Create Customer");
        RunCodeunit(CODEUNIT::"Create Ship-to Address");
        RunCodeunit(CODEUNIT::"Create Vendor");
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
        RunCodeunit(CODEUNIT::"Create Item Posting Group");
        RunCodeunit(CODEUNIT::"Create Inventory Posting Setup");
        RunCodeunit(CODEUNIT::"Create WIP Accounts");
        RunCodeunit(CODEUNIT::"Create Item Vendor");
        RunCodeunit(CODEUNIT::"Create Purchase Price");
        RunCodeunit(CODEUNIT::"Create Purch. Line Discount");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(CODEUNIT::"Create Sales Header");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(CODEUNIT::"Create Sales Line");
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
        RunCodeunit(CODEUNIT::"Create Employee Qualification");
        RunCodeunit(CODEUNIT::"Create Employee Relative");
        RunCodeunit(CODEUNIT::"Create Employee Absence");
        RunCodeunit(CODEUNIT::"Create Misc. Article Info");
        RunCodeunit(CODEUNIT::"Create Confidential Info.");
        RunCodeunit(CODEUNIT::"Create Alternative Address");
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
        RunCodeunit(CODEUNIT::"Create Fixed Asset");
        RunCodeunit(CODEUNIT::"Create Depreciation Book");
        RunCodeunit(CODEUNIT::"Create FA Depreciation Book");
        RunCodeunit(CODEUNIT::"Create FA Maint. Registration");
        RunCodeunit(CODEUNIT::"Create FA Insurance Type");
        RunCodeunit(CODEUNIT::"Create FA Insurance");
        RunCodeunit(CODEUNIT::"Create FA Main Asset Comp.");
        RunCodeunit(CODEUNIT::"Create FA Journal Setup");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(CODEUNIT::"Create Purchase Header");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(CODEUNIT::"Create Purchase Line");
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

        RunCodeunit(CODEUNIT::"Create Post Dated ChecK");

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
    begin
        DemoDataSetup.Get();

        PostItemJournalLines(PostingDate);
        PostResourceJournalLines(PostingDate);
        PostJobJournalLines(PostingDate);
        InvoicePurchases(PostingDate);
        ShipSales(PostingDate);
        InvoiceSales(PostingDate);

        PostGeneralJournalLines(NormalDate(PostingDate));
        PostGeneralJournalLines(ClosingDate(PostingDate));

        if (PostingDate = CA.AdjustDate(19020501D)) or
           (PostingDate = CA.AdjustDate(19020801D)) or
           (PostingDate = CA.AdjustDate(19021101D))
        then begin
            "Make Corrections".CalcAndPostVATSettle(PostingDate);
            PostGeneralJournalLines(NormalDate(PostingDate));
        end;

        if PostingDate = CA.AdjustDate(19021231D) then begin
            "Run Post Inventory Cost to G/L".Run();
            PostGeneralJournalLines(NormalDate(PostingDate));

            CalcQty.Run();
            PostItemJournalLines(PostingDate);
            "Run Post Inventory Cost to G/L".Run();
            PostGeneralJournalLines(NormalDate(PostingDate));

            "Adjust Inventory Value".Run();
            PostGeneralJournalLines(NormalDate(PostingDate));

            ProcessOpeningEntries(PostingDate);
            PostGeneralJournalLines(NormalDate(PostingDate));
        end;

        if PostingDate = CA.AdjustDate(19021231D) then begin
            InsertBankAccStmt(XWWBOPERATING, PostingDate);
            InsertBankAccStmt(XNBL, PostingDate);
        end;

        if PostingDate = CA.AdjustDate(19030115D) then
            InsertBankAccStmt(XWWBOPERATING, PostingDate);
    end;

    procedure AfterPosting()
    var
        AccountingPeriod: Record "Accounting Period";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
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

        GenJournalLine.Reset();
        GenJournalLine.SetRange("Journal Template Name", XSTART);
        if GenJournalLine.FindFirst() then
            Error(XNotallopnngentrieswrposted);

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
        Window.Update(1, StrSubstNo('%1 %2', AllObj."Object ID", AllObj."Object Name"));
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
                GenJnlPostLine.RunWithCheck(GenJournalLine);
            until GenJournalLine.Next() = 0;
            GenJournalLine.DeleteAll();
        end;
    end;

    local procedure ProcessOpeningEntries(Date: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Allocated2310: Decimal;
        Allocated2320: Decimal;
        Allocated5410: Decimal;
        Allocated5420: Decimal;
        Allocated2920: Decimal;
        Allocated5310: Decimal;
    begin
        GenJournalLine.Reset();
        GenJournalLine.SetRange("Posting Date", Date);
        GenJournalLine.SetFilter(Quantity, '<>0');
        if GenJournalLine.Find('-') then
            repeat
                case GenJournalLine."Account Type" of
                    GenJournalLine."Account Type"::Customer:
                        ProcessCustomerOpeningEntries(GenJournalLine, Allocated2310, Allocated2320);
                    GenJournalLine."Account Type"::Vendor:
                        ProcessVendorOpeningEntries(GenJournalLine, Allocated5410, Allocated5420);
                    GenJournalLine."Account Type"::"Bank Account":
                        ProcessBankAccountOpeningEntries(GenJournalLine, Allocated2920, Allocated5310);
                end;
            until GenJournalLine.Next() = 0;
    end;

    local procedure ProcessCustomerOpeningEntries(var GenJournalLine: Record "Gen. Journal Line"; var Allocated2310: Decimal; var Allocated2320: Decimal)
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        LineAmount: Decimal;
    begin
        Customer.Get(GenJournalLine."Account No.");
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        case true of
            CustomerPostingGroup."Receivables Account" = CA.Convert('992310'):
                LineAmount := CalcLineAmount(GenJournalLine.Quantity, CalcBalance(CA.Convert('992310')), Allocated2310);
            CustomerPostingGroup."Receivables Account" = CA.Convert('992320'):
                LineAmount := CalcLineAmount(GenJournalLine.Quantity, CalcBalance(CA.Convert('992320')), Allocated2320);
        end;
        UpdateGenJournalLine(GenJournalLine, LineAmount, CustomerPostingGroup."Receivables Account");
    end;

    local procedure ProcessVendorOpeningEntries(var GenJournalLine: Record "Gen. Journal Line"; var Allocated5410: Decimal; var Allocated5420: Decimal)
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        LineAmount: Decimal;
    begin
        Vendor.Get(GenJournalLine."Account No.");
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        case true of
            VendorPostingGroup."Payables Account" = CA.Convert('995410'):
                LineAmount := CalcLineAmount(GenJournalLine.Quantity, CalcBalance(CA.Convert('995410')), Allocated5410);
            VendorPostingGroup."Payables Account" = CA.Convert('995420'):
                LineAmount := CalcLineAmount(GenJournalLine.Quantity, CalcBalance(CA.Convert('995420')), Allocated5420);
        end;
        UpdateGenJournalLine(GenJournalLine, LineAmount, VendorPostingGroup."Payables Account");
    end;

    local procedure ProcessBankAccountOpeningEntries(var GenJournalLine: Record "Gen. Journal Line"; var Allocated2920: Decimal; var Allocated5310: Decimal)
    var
        BankAcc: Record "Bank Account";
        BankAccPostingGroup: Record "Bank Account Posting Group";
        LineAmount: Decimal;
    begin
        BankAcc.Get(GenJournalLine."Account No.");
        BankAccPostingGroup.Get(BankAcc."Bank Acc. Posting Group");
        case true of
            BankAccPostingGroup."G/L Account No." = CA.Convert('992920'):
                LineAmount := CalcLineAmount(GenJournalLine.Quantity, CalcBalance(CA.Convert('992920')), Allocated2920);
            BankAccPostingGroup."G/L Account No." = CA.Convert('995310'):
                LineAmount := CalcLineAmount(GenJournalLine.Quantity, CalcBalance(CA.Convert('995310')), Allocated5310);
        end;
        UpdateGenJournalLine(GenJournalLine, LineAmount, BankAccPostingGroup."G/L Account No.");
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

    local procedure UpdateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; LineAmount: Decimal; BalanceAccountNo: Code[20])
    var
        SaveDueDate: Date;
    begin
        GenJournalLine.Validate(
          Amount, Round(
            CurrencyExchangeRate.ExchangeAmtLCYToFCY(
              GenJournalLine."Posting Date", GenJournalLine."Currency Code",
              LineAmount, CurrencyExchangeRate.ExchangeRate(
                GenJournalLine."Posting Date", GenJournalLine."Currency Code"))));
        GenJournalLine."Sales/Purch. (LCY)" := LineAmount;
        SaveDueDate := GenJournalLine."Due Date"; // Backup Due Date
        GenJournalLine.Validate(Quantity, 0); // Clear Quantity
        GenJournalLine.Validate(
          "Bal. Account No.", BalanceAccountNo);
        GenJournalLine.Validate("Due Date", SaveDueDate); // Restore Due Date
        GenJournalLine.Modify();
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
        end else begin
            // Demo Company Data for Budgets
            InitBudgetData();
            BudgetMonth := 0;
            repeat
                BudgetMonth := BudgetMonth + 1;
                CopyYearBudget(BudgetMthFactor[BudgetMonth], DemoDataSetup."Starting Year");
            until BudgetMonth = 12;
            BudgetMonth := 1;
            CopyYearBudget(0.98, DemoDataSetup."Starting Year" + 1);
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

    local procedure CreateNewTemplates()
    begin
        RunCodeunit(Codeunit::"Create New Customer Template");
        RunCodeunit(Codeunit::"Create New Item Template");
        RunCodeunit(Codeunit::"Create New Vendor Template");
        RunCodeunit(Codeunit::"Create New Employee Template");
    end;
}

