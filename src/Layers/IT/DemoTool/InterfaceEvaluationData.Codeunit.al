codeunit 122001 "Interface Evaluation Data"
{

    trigger OnRun()
    begin
    end;

    var
        XEvalDataMsg: Label 'Create evaluation demo data';
        CreatePaymentTerms: Codeunit "Create Payment Terms";
        CreatePaymentMethod: Codeunit "Create Payment Method";
        MakeAdjustments: Codeunit "Make Adjustments";
        CreateLocation: Codeunit "Create Location";
        CreateGenJournalBatch: Codeunit "Create Gen. Journal Batch";
        Seed: Integer;
        FirstPostingDate: Date;
        LastPostingDate: Date;
        XMAIN: Label 'MAIN';
        XEAST: Label 'EAST';
        XWEST: Label 'WEST';
        PmtRecNoSeriesStartNoTok: Label 'PREC000', Locked = true;
        XStatementLineDescription1: Label 'Transfer to savings account';
        XStatementLineDescription2: Label 'Funds for Spring event';
        XStatementLineDescription3: Label 'Deposit to Account';

    procedure CreateSetupData()
    var
        CreateContact: Codeunit "Create Contact";
        CreateCustomer: Codeunit "Create Customer";
        CreateVendor: Codeunit "Create Vendor";
        CreateCVBankAccount: Codeunit "Create C/V Bank Account";
        CreateGeneralLedgerSetup: Codeunit "Create General Ledger Setup";
        CreateDimension: Codeunit "Create Dimension";
        CreateInteractionTemplate: Codeunit "Create Interaction Template";
        CreateInteractTemplLang: Codeunit "Create Interact. Templ. Lang.";
        CreateMarketingSetup: Codeunit "Create Marketing Setup";
        CreateSegmentHeader: Codeunit "Create Segment Header";
        CreateSegmentLine: Codeunit "Create Segment Line";
        CreateOpportunity: Codeunit "Create Opportunity";
        CreatePurchaseDocument: Codeunit "Create Purchase Document";
        CreateSalesDocument: Codeunit "Create Sales Document";
        CreateOpportunityEntry: Codeunit "Create Opportunity Entry";
        CreateShiptoAddress: Codeunit "Create Ship-to Address";
        CreateInventoryPostingSetup: Codeunit "Create Inventory Posting Setup";
        CreateEmployee: Codeunit "Create Employee";
        CreateTransferRoute: Codeunit "Create Transfer Route";
        CreateTransferOrder: Codeunit "Create Transfer Order";
        CreateDocSendingProfile: Codeunit "Create Doc. Sending Profile";
        UpdateInventoryPostingSetup: Codeunit "Update Inventory Posting Setup";
        CreateContactProfileAnswer: Codeunit "Create Contact Profile Answer";
        CreateCampaign: Codeunit "Create Campaign";
        CreateColumnLayoutName: Codeunit "Create Column Layout Name";
        CreateColumnLayout: Codeunit "Create Column Layout";
        CreateAccScheduleName: Codeunit "Create Acc. Schedule Name";
        CreateAccScheduleLine: Codeunit "Create Acc. Schedule Line";
        CreateBOMComponent: Codeunit "Create BOM Component";
        CreateAnalysisView: Codeunit "Create Analysis View";
        CreateIncomingDocument: Codeunit "Create Incoming Document";
        CreateJobResponsibility: Codeunit "Create Job Responsibility";
        CreateDefaultDimension: Codeunit "Create Default Dimension";
        CreateInteractionLogEntry: Codeunit "Create Interaction Log Entry";
        CreateICPartner: Codeunit "Create IC Partner";
        CreateGenlJournalLine: Codeunit "Create Gen. Journal Line";
        Window: Dialog;
    begin
        Window.Open(XEvalDataMsg);

        CreateDimension.InsertEvaluationData();
        CreateGeneralLedgerSetup.InsertEvaluationData();

        RunCodeunit(CODEUNIT::"Create Accounting Period");
        RunCodeunit(CODEUNIT::"Create Company Information");
        RunCodeunit(CODEUNIT::"Create Shipment Method");
        CreateLocation.CreateEvaluationData();
        CreateInventoryPostingSetup.CreateEvaluationData();
        RunCodeunit(CODEUNIT::"Create In-Transit Location");
        UpdateInventoryPostingSetup.CreateEvaluationData();
        RunCodeunit(CODEUNIT::"Create Salesperson/Purchaser");
        RunCodeunit(CODEUNIT::"Create Customer Disc. Group");
        RunCodeunit(CODEUNIT::"Create Territory");
        CreateDocSendingProfile.CreateEvaluationData();
        RunCodeunit(CODEUNIT::"Create Salutation");
        CreateMarketingSetup.CreateEvaluationData();
        CreateCustomer.CreateEvaluationData();
        CreateVendor.CreateEvaluationData();
        CreateDefaultDimension.CreateEvaluationData();
        CreateContact.CreateEvaluationData();
        RunCodeunit(CODEUNIT::"Create ABI/CAB Codes");
        CreateCVBankAccount.CreateEvaluationData();
        CreateShiptoAddress.CreateEvaluationData();
        RunCodeunit(CODEUNIT::"Create Bank Account");
        RunCodeunit(CODEUNIT::"Create Item");
        RunCodeunit(CODEUNIT::"Create Item Cross Reference");
        RunCodeunit(CODEUNIT::"Create Item Translation");
        RunCodeunit(CODEUNIT::"Create Item Substitution");
        RunCodeunit(CODEUNIT::"Create Catalog Item");
        CreateInteractTemplLang.CreateEvaluationData();
        CreateInteractionTemplate.CreateEvaluationData();
        RunCodeunit(CODEUNIT::"Create Salutation Formula");
        RunCodeunit(CODEUNIT::"Create Mailing Group");
        RunCodeunit(CODEUNIT::"Create Industry Group");
        RunCodeunit(CODEUNIT::"Create Web Source");
        RunCodeunit(CODEUNIT::"Create Tax Groups SaaS");
        RunCodeunit(CODEUNIT::"Create Job Journal Template");
        RunCodeunit(CODEUNIT::"Create No Series SaaS");
        RunCodeunit(CODEUNIT::"Create Jobs Setup");
        RunCodeunit(CODEUNIT::"Create Resources Setup");
        RunCodeunit(CODEUNIT::"Create Job G/L Accounts");
        RunCodeunit(CODEUNIT::"Create Job Posting Group");
        RunCodeunit(CODEUNIT::"Create Job Resources");
        RunCodeunit(CODEUNIT::"Create Job Responsibility");
        RunCodeunit(CODEUNIT::"Create Job Journal Batch");
        RunCodeunit(CODEUNIT::"Create Jobs For SaaS");
        RunCodeunit(CODEUNIT::"Create Job Task SaaS");
        RunCodeunit(CODEUNIT::"Create Job PlanLines SaaS");
        RunCodeunit(CODEUNIT::"Create Job Jrnl Line SaaS");
        RunCodeunit(CODEUNIT::"Create Organizational Level");
        RunCodeunit(CODEUNIT::"Create Team");
        RunCodeunit(CODEUNIT::"Create Team Salesperson");
        RunCodeunit(CODEUNIT::"Create Campaign Status");
        RunCodeunit(CODEUNIT::"Create Close Opportunity Code");
        RunCodeunit(CODEUNIT::"Create Duplicate Setup");
        RunCodeunit(CODEUNIT::"Create Item Charges");
        RunCodeunit(CODEUNIT::"Create Item Tracking Codes");

        CreateEmployee.CreateEvaluationData();
        RunCodeunit(Codeunit::"Create Causes of Absence");
        CreateContactProfileAnswer.InsertEvaluationData();
        CreateSegmentHeader.CreateEvaluationData();
        CreateSegmentLine.CreateEvaluationData();
        CreateOpportunity.CreateEvaluationData();
        CreateOpportunityEntry.CreateEvaluationData();
        CreateTransferRoute.CreateEvaluationData();
        CreateCampaign.CreateEvaluationData();
        CreateBOMComponent.CreateEvaluationData();
        CreateAnalysisView.CreateEvaluationData();
        Codeunit.Run(Codeunit::"Create Allocation Accounts");
        RunCodeunit(Codeunit::"Create Dispute Status");
        RunCodeunit(Codeunit::"Create Reminder Automation");

        CreateColumnLayoutName.Run();
        CreateColumnLayout.Run();
        CreateAccScheduleName.InsertEvaluationData();
        CreateAccScheduleLine.InsertEvaluationData();
        RunCodeunit(CODEUNIT::"Create Payment Reg. Setup");
        CreateICPartner.CreateICSetup('ICHQ');

        UpdateContactEmail();

        RunCodeunit(CODEUNIT::"Create Data Sensitivity");
        RunCodeunit(CODEUNIT::"Create Time Series Data");
        RunCodeunit(Codeunit::"Create Availability Setup");
        FirstPostingDate := 19030101D;
        LastPostingDate := 19030320D;

        CreatePurchaseDocument.CreateOpenPurchDocuments(
          MakeAdjustments.AdjustDate(GetCurrentDay()), GetOpenDocsMarker());
        CreateSalesDocument.CreateOpenSalesDocuments(
          MakeAdjustments.AdjustDate(GetCurrentDay()), GetOpenDocsMarker());
        CreatePurchaseDocument.CreatePurchaseOrders(
          MakeAdjustments.AdjustDate(GetCurrentDay()), GetOpenDocsMarker());

        // Generate Sales Invoices based on Jobs in system
        RunCodeunit(CODEUNIT::"Create Invoices for Jobs");

        CreatePurchaseDocument.RecreatePurchaseDocumentsByDateOrder();
        CreateSalesDocument.RecreateSalesDocumentsByDateOrder();

        ReleasePurchases();
        ReopenPurchases();
        ReleaseSales();
        ReopenSalesSkipOrder();

        UpdatePurchDocCheckTotal();

        CreateTransferOrder.CreateEvaluationData(GetOpenDocsMarker());

        CreateGenlJournalLine.InsertEvaluationData();
        CreateBankAccountReconciliation();
        CreatePaymentReconciliationJournal();

        CreateIncomingDocument.CreateEvaluationData();
        RunCodeunit(Codeunit::"Create Over-Receipt Code");
        CreateJobResponsibility.CreateEvaluationData();
        CreateNewTemplates();
        CreateInteractionLogEntry.CreateEvaluationData();

        RunCodeunit(Codeunit::"Create Notification Setup");

        Window.Close();
    end;

    procedure GetRandomVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Next(RandInt(FindVendors(Vendor)) - 1);
        exit(Vendor."No.");
    end;

    procedure GetRandomCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Next(RandInt(FindCustomers(Customer)) - 1);
        exit(Customer."No.");
    end;

    local procedure RunCodeunit(CodeunitID: Integer)
    begin
        CODEUNIT.Run(CodeunitID);
    end;

    procedure RunReport(ReportID: Integer)
    begin
        REPORT.Run(ReportID, false);
    end;

    procedure ReleasePurchases()
    var
        PurchaseHeader: Record "Purchase Header";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
    begin
        if PurchaseHeader.Find('-') then
            repeat
                ReleasePurchaseDocument.Run(PurchaseHeader);
                Clear(ReleasePurchaseDocument);
            until PurchaseHeader.Next() = 0;
    end;

    procedure ReleaseSales()
    var
        SalesHeader: Record "Sales Header";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
    begin
        if SalesHeader.Find('-') then
            repeat
                ReleaseSalesDocument.Run(SalesHeader);
                Clear(ReleaseSalesDocument);
            until SalesHeader.Next() = 0;
    end;

    procedure ReopenPurchases()
    var
        PurchaseHeader: Record "Purchase Header";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
    begin
        if PurchaseHeader.Find('-') then
            repeat
                ReleasePurchaseDocument.Reopen(PurchaseHeader);
                Clear(ReleasePurchaseDocument);
            until PurchaseHeader.Next() = 0;
    end;

    procedure ReopenSalesSkipOrder()
    var
        SalesHeader: Record "Sales Header";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
    begin
        SalesHeader.SetFilter("Document Type", '<> %1', SalesHeader."Document Type"::Order);
        if SalesHeader.Find('-') then
            repeat
                ReleaseSalesDocument.Reopen(SalesHeader);
                Clear(ReleaseSalesDocument);
            until SalesHeader.Next() = 0;
    end;

    local procedure CreateBankAccountReconciliation()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        DepositAmount: Decimal;
        Bank1Amount: Decimal;
        Bank2Amount: Decimal;
        TransactionDate: Date;
    begin
        BankAccReconciliation.Init();
        BankAccReconciliation."Statement Type" := BankAccReconciliation."Statement Type"::"Bank Reconciliation";
        BankAccReconciliation."Bank Account No." := GetCheckingBankAccount();
        BankAccount.Get(BankAccReconciliation."Bank Account No.");
        BankAccReconciliation."Statement No." := CopyStr(IncStr(BankAccount."Last Statement No."), 1, MaxStrLen(BankAccReconciliation."Statement No."));
        BankAccReconciliation.Validate("Statement Date", MakeAdjustments.AdjustDate(LastPostingDate + 1));
        BankAccReconciliation.Insert();
        BankAccount."Last Statement No." := BankAccReconciliation."Statement No.";
        BankAccount.Modify();
        GenJournalLine.SetRange("Journal Template Name", CreateGenJournalBatch.GetGeneralJournalTemplateName());
        GenJournalLine.SetRange("Journal Batch Name", CreateGenJournalBatch.GetDailyJournalBatchName());
        BankAccReconciliationLine."Statement Type" := BankAccReconciliation."Statement Type";
        BankAccReconciliationLine."Bank Account No." := BankAccReconciliation."Bank Account No.";
        BankAccReconciliationLine."Statement No." := BankAccReconciliation."Statement No.";
        GenJournalLine.SetFilter("Document No.", 'DEPOSIT*');
        if GenJournalLine.FindSet() then
            repeat
                DepositAmount -= GenJournalLine.Amount;
                TransactionDate := GenJournalLine."Posting Date";
            until GenJournalLine.Next() = 0;
        GenJournalLine.SetFilter("Document No.", 'BANK1*');
        if GenJournalLine.FindSet() then
            repeat
                Bank1Amount -= GenJournalLine.Amount;
                TransactionDate := GenJournalLine."Posting Date";
            until GenJournalLine.Next() = 0;

        GenJournalLine.SetFilter("Document No.", 'BANK2*');
        if GenJournalLine.FindSet() then
            repeat
                Bank2Amount -= GenJournalLine.Amount;
                TransactionDate := GenJournalLine."Posting Date";
            until GenJournalLine.Next() = 0;

        CreateBankReconciliationLine(BankAccReconciliationLine, XStatementLineDescription1, TransactionDate, Bank1Amount);
        CreateBankReconciliationLine(BankAccReconciliationLine, XStatementLineDescription2, CalcDate('<+3D>', TransactionDate), Bank2Amount);
        CreateBankReconciliationLine(BankAccReconciliationLine, XStatementLineDescription3 + ' ' + Format(TransactionDate), TransactionDate, DepositAmount);

        BankAccReconciliation."Statement Ending Balance" := Bank1Amount + Bank2Amount + DepositAmount;
        BankAccReconciliation."Statement Date" := CalcDate('<CM>', TransactionDate);
        BankAccReconciliation.Modify();
    end;

    local procedure CreatePaymentReconciliationJournal()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccount: Record "Bank Account";
    begin
        BankAccReconciliation.Init();
        BankAccReconciliation."Statement Type" :=
          BankAccReconciliation."Statement Type"::"Payment Application";
        BankAccReconciliation."Bank Account No." := GetCheckingBankAccount();
        BankAccReconciliation."Statement No." := PmtRecNoSeriesStartNoTok;
        BankAccReconciliation.Validate("Statement Date", MakeAdjustments.AdjustDate(LastPostingDate + 1));
        BankAccReconciliation."Statement Ending Balance" := 0;
        BankAccReconciliation.Insert();
        BankAccount.Get(GetCheckingBankAccount());
        BankAccount."Last Payment Statement No." := BankAccReconciliation."Statement No.";
        BankAccount.Modify();
        CreatePaymentReconciliationJournalLines(BankAccReconciliation);
    end;

    local procedure CreatePaymentReconciliationJournalLines(BankAccReconciliation: Record "Bank Acc. Reconciliation"): Decimal
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Balance: Decimal;
    begin
        BankAccReconciliationLine.Init();
        BankAccReconciliationLine."Statement Type" := BankAccReconciliation."Statement Type";
        BankAccReconciliationLine."Bank Account No." := BankAccReconciliation."Bank Account No.";
        BankAccReconciliationLine."Statement No." := BankAccReconciliation."Statement No.";
        Balance := CreatePurchReconcilationLines(BankAccReconciliationLine);
        Balance += CreateSalesReconcilationLines(BankAccReconciliationLine);
        exit(Balance);
    end;

    local procedure CreatePurchReconcilationLines(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"): Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        PmtCount: Integer;
        Balance: Decimal;
    begin
        PmtCount := 0;
        PurchaseHeader.Reset();
        PurchaseHeader.SetRange("Payment Method Code", '');
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.SetFilter("Your Reference", '<>%1', GetOpenDocsMarker());
        if PurchaseHeader.FindSet() then
            repeat
                PmtCount += 1;
                PurchaseHeader.CalcFields("Amount Including VAT");
                if PmtCount = 2 then // add line with low match confidence
                    CreateBankReconciliationLine(
                      BankAccReconciliationLine, PurchaseHeader."Pay-to Name",
                      PurchaseHeader."Posting Date", -PurchaseHeader."Amount Including VAT" div 2)
                else
                    CreateBankReconciliationLine(
                      BankAccReconciliationLine, PurchaseHeader."No.",
                      PurchaseHeader."Posting Date", -PurchaseHeader."Amount Including VAT");

                Balance += BankAccReconciliationLine."Statement Amount";
            until (PurchaseHeader.Next() = 0) or (PmtCount = 3);
        exit(Balance);
    end;

    local procedure CreateSalesReconcilationLines(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"): Decimal
    var
        SalesHeader: Record "Sales Header";
        PmtCount: Integer;
        Balance: Decimal;
    begin
        PmtCount := 0;
        SalesHeader.Reset();
        SalesHeader.SetRange("Payment Method Code", '');
        SalesHeader.SetFilter("Your Reference", '<>%1', GetOpenDocsMarker());
        if SalesHeader.FindSet() then
            repeat
                PmtCount += 1;
                SalesHeader.CalcFields("Amount Including VAT");
                if PmtCount = 2 then // add line with no match confidence
                    CreateBankReconciliationLine(
                      BankAccReconciliationLine, SalesHeader."Sell-to Customer Name",
                      SalesHeader."Posting Date" + 1, SalesHeader."Amount Including VAT" - 0.01)
                else
                    CreateBankReconciliationLine(
                      BankAccReconciliationLine, SalesHeader."No.",
                      SalesHeader."Posting Date", SalesHeader."Amount Including VAT");

                Balance += BankAccReconciliationLine."Statement Amount";
            until (SalesHeader.Next() = 0) or (PmtCount = 3);
        exit(Balance);
    end;

    local procedure CreateBankReconciliationLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Text: Text[100]; Date: Date; Amount: Decimal)
    begin
        BankAccReconciliationLine."Statement Line No." += 10000;
        BankAccReconciliationLine.Description := Text;
        BankAccReconciliationLine."Transaction Text" := Text;
        BankAccReconciliationLine."Transaction Date" := Date;
        BankAccReconciliationLine."Applied Amount" := 0;
        BankAccReconciliationLine."Statement Amount" := Amount;
        BankAccReconciliationLine.Difference := Amount;
        BankAccReconciliationLine.Insert();
    end;

    procedure AllocateQty(var TempInQuantityAllocationBuffer: Record "Quantity Allocation Buffer" temporary; var TempOutQuantityAllocationBuffer: Record "Quantity Allocation Buffer" temporary; MaxNumberOfInvoices: Integer)
    var
        Item: Record Item;
        LineCount: array[2] of Integer;
        LineNo: Integer;
        LineQty: array[2] of Integer;
        Quantity: array[2] of Integer;
        TotalLineQty: Integer;
    begin
        Item.Reset();
        Item.SetFilter("No.", '*-S');
        Item.FindSet();
        repeat
            TempInQuantityAllocationBuffer.Reset();
            TempInQuantityAllocationBuffer.SetRange("Item No.", Item."No.");

            if not TempInQuantityAllocationBuffer.IsEmpty() then begin
                // Purchases
                TempInQuantityAllocationBuffer.SetRange(Index, 1);
                TempInQuantityAllocationBuffer.FindFirst();
                Quantity[1] := TempInQuantityAllocationBuffer.Quantity;
                LineCount[1] := 1;
                // Sales
                TempInQuantityAllocationBuffer.SetRange(Index, 2);
                TempInQuantityAllocationBuffer.FindFirst();
                Quantity[2] := TempInQuantityAllocationBuffer.Quantity;
                LineCount[2] := RandInt(MaxNumberOfInvoices);

                LineNo := 0;
                TotalLineQty := 0;
                while (Quantity[1] > 0) or (Quantity[2] > 0) do begin
                    LineQty[2] := Round(Quantity[2] * RandRate(LineCount[2]), 1);
                    if LineQty[2] = 0 then
                        LineQty[2] := 1;
                    while (Quantity[1] > 0) and ((TotalLineQty - LineQty[2] < 0) or (Quantity[2] = 0)) do begin
                        LineQty[1] := Round(Quantity[1] * RandRate(LineCount[1]), 1);
                        if LineQty[1] = 0 then
                            LineQty[1] := 1;
                        TempOutQuantityAllocationBuffer.Init();
                        TempOutQuantityAllocationBuffer."Item No." := Item."No.";
                        LineNo += 1;
                        TempOutQuantityAllocationBuffer.Index := LineNo;
                        TempOutQuantityAllocationBuffer.Quantity := LineQty[1];
                        TempOutQuantityAllocationBuffer.Insert(true);
                        TotalLineQty += LineQty[1];
                        Quantity[1] -= LineQty[1];
                        LineCount[1] -= 1;
                    end;
                    if Quantity[2] > 0 then begin
                        TempOutQuantityAllocationBuffer.Init();
                        TempOutQuantityAllocationBuffer."Item No." := Item."No.";
                        LineNo += 1;
                        TempOutQuantityAllocationBuffer.Index := LineNo;
                        TempOutQuantityAllocationBuffer.Quantity := -LineQty[2];
                        TempOutQuantityAllocationBuffer.Insert(true);
                        TotalLineQty -= LineQty[2];
                        Quantity[2] -= LineQty[2];
                        LineCount[2] -= 1;
                    end;
                end;
            end;
        until Item.Next() = 0;
    end;

    procedure AllocateQtyToDocuments(var TempQuantityAllocationBuffer: Record "Quantity Allocation Buffer" temporary; var TempItemLineBuffer: Record "Item Line Buffer"; MergeDelta: Integer)
    var
        Item: Record Item;
        Customer: Record Customer;
        Vendor: Record Vendor;
        TotalPostingDays: Integer;
        MinDelta: Integer;
        MaxDelta: Integer;
        MaxIndex: Integer;
        DocIndex: Integer;
    begin
        TotalPostingDays := LastPostingDate - FirstPostingDate;
        DocIndex := 0;

        Item.Reset();
        Item.SetFilter("No.", '*-S');
        Item.FindSet();
        repeat
            MaxIndex := TempQuantityAllocationBuffer.MaxIndex(Item."No.");
            if MaxIndex > 0 then begin
                MaxDelta := Round(TotalPostingDays / MaxIndex, 1);
                MinDelta := 0;
                TempQuantityAllocationBuffer.Reset();
                TempQuantityAllocationBuffer.SetRange("Item No.", Item."No.");
                if TempQuantityAllocationBuffer.FindSet() then
                    repeat
                        DocIndex += 1;
                        TempItemLineBuffer.Init();
                        TempItemLineBuffer."Item No." := TempQuantityAllocationBuffer."Item No.";
                        TempItemLineBuffer.Index := TempQuantityAllocationBuffer.Index;
                        TempItemLineBuffer.Validate(Quantity, TempQuantityAllocationBuffer.Quantity);
                        TempItemLineBuffer."Customer/Vendor No." := PickCustVend(TempItemLineBuffer.Positive);
                        TempItemLineBuffer."Date Delta" := MinDelta + RandInt(MaxDelta);
                        TempItemLineBuffer."Document Date Delta" := TempItemLineBuffer."Date Delta";
                        TempItemLineBuffer."Document Index" := DocIndex;
                        TempItemLineBuffer.Insert();
                        MinDelta += MaxDelta;
                    until TempQuantityAllocationBuffer.Next() = 0;
            end;
        until Item.Next() = 0;

        TempItemLineBuffer.Reset();
        TempItemLineBuffer.SetCurrentKey("Document Date Delta");
        TempItemLineBuffer.SetRange(Positive, true);
        FindVendors(Vendor);
        repeat
            TempItemLineBuffer.SetRange("Customer/Vendor No.", Vendor."No.");
            MergeCloseDocuments(TempItemLineBuffer, MergeDelta);
        until Vendor.Next() = 0;

        TempItemLineBuffer.Reset();
        TempItemLineBuffer.SetCurrentKey("Document Date Delta");
        TempItemLineBuffer.SetRange(Positive, false);
        FindCustomers(Customer);
        repeat
            TempItemLineBuffer.SetRange("Customer/Vendor No.", Customer."No.");
            MergeCloseDocuments(TempItemLineBuffer, 2);
        until Customer.Next() = 0;
    end;

    procedure MergeCloseDocuments(var TempItemLineBuffer: Record "Item Line Buffer"; AllowedDelta: Integer)
    var
        LastItemLineBuffer: Record "Item Line Buffer";
        Positive: Boolean;
        Increment: Integer;
    begin
        TempItemLineBuffer.FindFirst();
        Positive := TempItemLineBuffer.Positive;
        Increment := 0;
        if Positive then begin
            if TempItemLineBuffer.FindSet() then
                Increment := 1
        end else begin
            if TempItemLineBuffer.FindLast() then
                Increment := -1;
            AllowedDelta := -AllowedDelta;
        end;
        if Increment <> 0 then begin
            LastItemLineBuffer."Document Date Delta" := TempItemLineBuffer."Document Date Delta" - AllowedDelta - Increment;
            repeat
                if Abs(TempItemLineBuffer."Document Date Delta" - LastItemLineBuffer."Document Date Delta") <= Abs(AllowedDelta) then begin
                    TempItemLineBuffer."Document Date Delta" := LastItemLineBuffer."Document Date Delta";
                    TempItemLineBuffer."Document Index" := LastItemLineBuffer."Document Index";
                    TempItemLineBuffer.Modify();
                end;
                LastItemLineBuffer := TempItemLineBuffer;
            until TempItemLineBuffer.Next(Increment) = 0;
        end;
    end;

    procedure CreatePurchSalesDocuments(var TempItemLineBuffer: Record "Item Line Buffer") DocCount: Integer
    var
        CreatePurchaseDocument: Codeunit "Create Purchase Document";
        CreateSalesDocument: Codeunit "Create Sales Document";
        DocumentIndex: Integer;
        TotalPostingDays: Integer;
        NotPaidDocumentsPeriod: Integer;
        PeriodWithIn90Days: Boolean;
        PeriodWithIn30Days: Boolean;
    begin
        TotalPostingDays := LastPostingDate - FirstPostingDate;
        DocumentIndex := 0;
        NotPaidDocumentsPeriod := 5;
        PeriodWithIn90Days := GetCurrentDay() - FirstPostingDate <= 90;
        PeriodWithIn30Days := GetCurrentDay() - FirstPostingDate <= 30;

        TempItemLineBuffer.Reset();
        TempItemLineBuffer.SetCurrentKey("Document Date Delta", "Document Index");
        TempItemLineBuffer.FindSet();
        repeat
            if TempItemLineBuffer."Document Index" <> DocumentIndex then begin
                DocumentIndex := TempItemLineBuffer."Document Index";
                DocCount += 1;
                if TempItemLineBuffer.Sign() = 1 then
                    CreatePurchDocumentHeader(CreatePurchaseDocument,
                      TempItemLineBuffer."Customer/Vendor No.",
                      MakeAdjustments.AdjustDate(FirstPostingDate + TempItemLineBuffer."Document Date Delta"), not PeriodWithIn30Days)
                else
                    CreateSalesDocumentHeader(CreateSalesDocument,
                      TempItemLineBuffer."Customer/Vendor No.",
                      MakeAdjustments.AdjustDate(FirstPostingDate + TempItemLineBuffer."Document Date Delta"),
                      (TempItemLineBuffer."Document Date Delta" <= TotalPostingDays - NotPaidDocumentsPeriod) or not PeriodWithIn90Days);
            end;
            if TempItemLineBuffer.Sign() = 1 then
                CreatePurchDocumentLine(CreatePurchaseDocument, TempItemLineBuffer."Item No.", TempItemLineBuffer.Quantity)
            else
                CreateSalesDocumentLine(CreateSalesDocument, TempItemLineBuffer."Item No.", -TempItemLineBuffer.Quantity);
        until TempItemLineBuffer.Next() = 0;
    end;

    local procedure CreatePurchDocument(PostingDate: Date; ItemNo: Code[20]; Quantity: Decimal)
    var
        CreatePurchaseDocument: Codeunit "Create Purchase Document";
    begin
        CreatePurchDocumentHeader(CreatePurchaseDocument, GetRandomVendor(), PostingDate, true);
        CreatePurchDocumentLine(CreatePurchaseDocument, ItemNo, Quantity);
    end;

    local procedure CreatePurchDocumentForLocation(PostingDate: Date; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        CreatePurchaseDocument: Codeunit "Create Purchase Document";
    begin
        CreatePurchDocumentHeader(CreatePurchaseDocument, GetRandomVendor(), PostingDate, true);
        CreatePurchaseDocument.AddLocation(LocationCode);
        CreatePurchDocumentLine(CreatePurchaseDocument, ItemNo, Quantity);
    end;

    local procedure CreatePurchDocumentHeader(var CreatePurchaseDocument: Codeunit "Create Purchase Document"; VendorNo: Code[20]; PostingDate: Date; AddPaymentCodes: Boolean)
    begin
        CreatePurchaseDocument.AddInvoiceHeader(VendorNo, PostingDate);
        if AddPaymentCodes then
            CreatePurchaseDocument.AddPaymentCodes(
              CreatePaymentTerms.CashOnDeliveryCode(), CreatePaymentMethod.GetCashCode());
    end;

    local procedure CreatePurchDocumentLine(var CreatePurchaseDocument: Codeunit "Create Purchase Document"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreatePurchaseDocument.AddLine(ItemNo, Quantity);
    end;

    local procedure CreateSalesDocumentHeader(var CreateSalesDocument: Codeunit "Create Sales Document"; CustomerNo: Code[20]; PostingDate: Date; AddPaymentCodes: Boolean)
    begin
        CreateSalesDocument.AddInvoiceHeader(CustomerNo, PostingDate);
        if AddPaymentCodes then
            CreateSalesDocument.AddPaymentCodes(
              CreatePaymentTerms.CashOnDeliveryCode(), CreatePaymentMethod.GetCashCode());
    end;

    local procedure CreateSalesDocumentLine(var CreateSalesDocument: Codeunit "Create Sales Document"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreateSalesDocument.AddLine(ItemNo, Quantity);
    end;

    local procedure GetCheckingBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.SetFilter("Min. Balance", '<0');
        BankAccount.FindFirst();
        exit(BankAccount."No.");
    end;

    local procedure FindVendors(var Vendor: Record Vendor): Integer
    begin
        Vendor.Reset();
        Vendor.SetFilter("No.", '10000|20000|30000|40000|50000');
        Vendor.FindSet();
        exit(Vendor.Count);
    end;

    local procedure FindCustomers(var Customer: Record Customer): Integer
    begin
        Customer.Reset();
        Customer.SetFilter("No.", '10000|20000|30000|40000|50000');
        Customer.FindSet();
        exit(Customer.Count);
    end;

    procedure PickCustVend(IsVendor: Boolean): Code[20]
    begin
        if IsVendor then
            exit(GetRandomVendor());
        exit(GetRandomCustomer());
    end;

    procedure CreateInventory(PostingDate: Date)
    begin
        CreatePurchDocument(PostingDate, '1896-S', 4);
        CreatePurchDocument(PostingDate, '1906-S', 5);
        CreatePurchDocument(PostingDate, '1908-S', 3);
        CreatePurchDocument(PostingDate, '1928-S', 8);
        CreatePurchDocument(PostingDate, '1936-S', 10);
        CreatePurchDocument(PostingDate, '1960-S', 2);
        CreatePurchDocument(PostingDate, '1964-S', 4);
        CreatePurchDocument(PostingDate, '2000-S', 10);

        CreatePurchDocumentForLocation(PostingDate, '1968-S', 2, XMAIN);
        CreatePurchDocumentForLocation(PostingDate, '1968-S', 3, XEAST);
        CreatePurchDocumentForLocation(PostingDate, '1968-S', 5, XWEST);

        CreatePurchDocument(CalcDate('<+10M>', PostingDate), '1996-S', 5);
        CreatePurchDocument(CalcDate('<+8M>', PostingDate), '1920-S', 10);
        CreatePurchDocument(CalcDate('<+11M>', PostingDate), '1936-S', 90);
        CreatePurchDocument(CalcDate('<+11M>', PostingDate), '2000-S', 28);
        CreatePurchDocument(CalcDate('<+11M>', PostingDate), '1996-S', 5);
    end;

    local procedure RandRate("Count": Integer): Decimal
    var
        Delta: Decimal;
        LowRate: Decimal;
        MaxRate: Decimal;
        MidRate: Decimal;
    begin
        if Count = 0 then
            exit(0);
        MidRate := 1 / Count * 100;
        if MidRate = 100 then
            exit(1);

        Delta := 0.67;
        LowRate := Round(MidRate * (1 - Delta), 1);
        MaxRate := Round(MidRate * (1 + Delta), 1);
        exit(RandDecInRange(LowRate, MaxRate, 2) / 100);
    end;

    procedure RandDec(Range: Integer; Decimals: Integer): Decimal
    begin
        exit(RandInt(Range * Power(10, Decimals)) / Power(10, Decimals));
    end;

    procedure RandDecInRange("Min": Integer; "Max": Integer; Decimals: Integer): Decimal
    begin
        // Returns a pseudo random decimal in the interval (Min,Max]
        exit(Min + RandDec(Max - Min, Decimals));
    end;

    procedure RandInt(Range: Integer): Integer
    begin
        // Returns a pseudo random integer in the interval [1,Range]
        if Range < 1 then
            exit(1);
        exit(1 + Round(Uniform() * (Range - 1), 1));
    end;

    procedure SetSeed(Val: Integer): Integer
    begin
        // Set the random seed to reproduce pseudo random sequence
        Seed := Val;
        Seed := Seed mod 10000;  // Overflow protection
        exit(Seed);
    end;

    procedure SetLastPostingDate(ValueDate: Date)
    begin
        LastPostingDate := ValueDate;
    end;

    procedure SetFirstPostingDate(ValueDate: Date)
    begin
        FirstPostingDate := ValueDate;
    end;

    procedure GetCurrentDay(): Date
    begin
        exit(19030401D);
    end;

    local procedure UpdateSeed()
    begin
        // Generates a new seed value and
        Seed := Seed + 3;
        Seed := Seed * 3;
        Seed := Seed * Seed;
        Seed := Seed mod 10000;  // Overflow protection
    end;

    local procedure Uniform(): Decimal
    begin
        // Generates a pseudo random uniform number
        UpdateSeed();

        exit((Seed mod 137) / 137);
    end;

    procedure GetOpenDocsMarker(): Text[10]
    begin
        exit('OPEN');
    end;

    procedure UpdateContactEmail()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        CreateContact: Codeunit "Create Contact";
    begin
        if Contact.FindSet() then
            repeat
                Contact.Validate("E-Mail", CreateContact.CreateContactEMail(Contact.Name, Contact."No."));
                Contact.Modify();
            until Contact.Next() = 0;

        if Customer.FindSet() then
            repeat
                if Contact.Get(Customer."Primary Contact No.") then begin
                    Customer.Validate("E-Mail", Contact."E-Mail");
                    Customer.Modify();
                end;
            until Customer.Next() = 0;

        if Vendor.FindSet() then
            repeat
                if Contact.Get(Vendor."Primary Contact No.") then begin
                    Vendor.Validate("E-Mail", Contact."E-Mail");
                    Vendor.Modify();
                end;
            until Vendor.Next() = 0;
    end;

    local procedure CreateNewTemplates()
    begin
        RunCodeunit(Codeunit::"Create New Customer Template");
        RunCodeunit(Codeunit::"Create New Item Template");
        RunCodeunit(Codeunit::"Create New Vendor Template");
        RunCodeunit(Codeunit::"Create New Employee Template");
    end;

    local procedure UpdatePurchDocCheckTotal()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if PurchaseHeader.FindSet() then
            repeat
                PurchaseHeader.CalcFields("Amount Including VAT");
                PurchaseHeader.Validate("Check Total", PurchaseHeader."Amount Including VAT");
                PurchaseHeader.Modify();
            until PurchaseHeader.Next() = 0;
    end;
}
