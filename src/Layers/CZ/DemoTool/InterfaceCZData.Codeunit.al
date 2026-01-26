Codeunit 163502 "Interface CZ Data"
{

    trigger OnRun()
    begin
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Window: Dialog;
        Steps: Integer;
        MaxSteps: Integer;

    procedure Create()
    begin
        DemoDataSetup.Get();
        Window.Open(DemoDataSetup."Progress Window Design");
        Window.Update(3, 'CZ Data');

        Steps := 0;
        MaxSteps := 35; // Number of calls to RunCodeunit
        RunCodeunit(Codeunit::"Create Banking Setup CZB");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(Codeunit::"Create Payment Order Hdr. CZB");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(Codeunit::"Create Payment Order Line CZB");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(Codeunit::"Create Bank Statement Hdr. CZB");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(Codeunit::"Create Bank Statement Line CZB");
        RunCodeunit(Codeunit::"Create Cash Desk CZP");
        RunCodeunit(Codeunit::"Create Cash Desk User CZP");
        RunCodeunit(Codeunit::"Create Cash Desk Event CZP");
        RunCodeunit(Codeunit::"Create EET Busin. Premises CZL");
        RunCodeunit(Codeunit::"Create EET Cash Register CZL");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(Codeunit::"Create Cash Document Hdr. CZP");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(Codeunit::"Create Cash Document Line CZP");
        RunCodeunit(Codeunit::"Create AdvLetter Template CZZ");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(Codeunit::"Create P. AdvLetter Header CZZ");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(Codeunit::"Create P. AdvLetter Line CZZ");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(Codeunit::"Create P. AdvLetter Appl. CZZ");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(Codeunit::"Create S. AdvLetter Header CZZ");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(Codeunit::"Create S. AdvLetter Line CZZ");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(Codeunit::"Create S. AdvLetter Appl. CZZ");
        RunCodeunit(Codeunit::"Create Compensations Setup CZC");
#if not CLEAN28        
        RunCodeunit(Codeunit::"Create VAT Period CZL");
#endif        
        RunCodeunit(Codeunit::"Create Reason Code");
        RunCodeunit(Codeunit::"Create Tax Depr. Group CZF");
        RunCodeunit(Codeunit::"Create FA Ext. Posting Gr. CZF");
        RunCodeunit(Codeunit::"Create Stat. Report. Setup CZL");
        RunCodeunit(Codeunit::"Create Company Official CZL");
        RunCodeunit(Codeunit::"Create VAT Attribute Code CZL");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(Codeunit::"Create VAT Ctrl. Rep. Hdr. CZL");
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(Codeunit::"Create VIES Decl. Header CZL");
        RunCodeunit(Codeunit::"Create Invt. Mvmt. Templ. CZL");
        RunCodeunit(Codeunit::"Create Stockk. Unit Templ. CZL");
        RunCodeunit(Codeunit::"Create Document Footer CZL");
        RunCodeunit(Codeunit::"Create Acc. Sch. File Map. CZL");

        UpdateCostTypes();

        Window.Close();
    end;

    procedure "Before Posting"()
    var
        UnrelPayerServiceSetupCZL: Record "Unrel. Payer Service Setup CZL";
    begin
        // Disable Unreliable Payer check
        UnrelPayerServiceSetupCZL.DeleteAll();

        // Payment Order
        IssuePaymentOrder('BPRI0001');

        // Bank Statement
        IssueBankStatement('BVYP0001');

        // Cash Documentreate ba
        ReleaseCashDocumentCZP('POK01', 'PPD0001');
        ReleaseCashDocumentCZP('POK01', 'VPD0001');
        ReleaseCashDocumentCZP('POK01', 'PPD0002');
        ReleaseCashDocumentCZP('POK01', 'VPD0002');
        PostCashDocumentCZP('POK01', 'PPD0002');
        PostCashDocumentCZP('POK01', 'VPD0002');

        // Purchase Advance
        ReleasePurchAdvanceLetterCZZ('NZ01220001');
        ReleasePurchAdvanceLetterCZZ('NZ01220002');
        ReleasePurchAdvanceLetterCZZ('NZ01220003');
        PostAdvancePaymentCZZ("Gen. Journal Account Type"::Vendor, '10000', 'A00001', 1210.00, 'NZ01220002');
        PostAdvancePaymentCZZ("Gen. Journal Account Type"::Vendor, '10000', 'A00002', 1210.00, 'NZ01220003');

        // Sales Advance
        ReleaseSalesAdvanceLetterCZZ('PZ01220001');
        ReleaseSalesAdvanceLetterCZZ('PZ01220002');
        ReleaseSalesAdvanceLetterCZZ('PZ01220003');
        PostAdvancePaymentCZZ("Gen. Journal Account Type"::Customer, '10000', 'A00003', -1210.00, 'PZ01220002');
        PostAdvancePaymentCZZ("Gen. Journal Account Type"::Customer, '10000', 'A00004', -1210.00, 'PZ01220003');
    end;

    procedure PostAdvancePaymentCZZ(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentNo: Code[20]; Amount: Decimal; AdvanceLetterNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        CreateBankAccount: Codeunit "Create Bank Account";
    begin
        GenJournalLine.Init();
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Account Type", AccountType);
        GenJournalLine.Validate("Account No.", AccountNo);
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account";
        GenJournalLine."Bal. Account No." := CreateBankAccount.GetBankAccountCode('XNBL');
        GenJournalLine.Validate("Advance Letter No. CZZ", AdvanceLetterNo);

        Codeunit.Run(Codeunit::"Gen. Jnl.-Post Line", GenJournalLine);
    end;

    procedure Post(PostingDate: Date)
    begin
    end;

    procedure "After Posting"()
    var
        CashDeskUser: Record "Cash Desk User CZP";
        UnrelPayerServiceSetupCZL: Record "Unrel. Payer Service Setup CZL";
    begin
        // Delete temporary user
        CashDeskUser.SetRange("Cash Desk No.", 'POK01');
        CashDeskUser.SetRange("User ID", UserId);
        CashDeskUser.DeleteAll();

        Codeunit.Run(Codeunit::"Create Compensation Header CZC");
        Codeunit.Run(Codeunit::"Create Compensation Line CZC");

        ReleaseCompensationtHeader('ZAP0001', 2);
        ReleaseCompensationtHeader('ZAP0002', 2);
        PostCompensationHeader('ZAP0002', 2);

        // VAT Control
        SuggestVATControls();

        // VIES
        SuggestVIESDEclarations();

        // insert unreliable payer setup again
        if not UnrelPayerServiceSetupCZL.Get() then begin
            UnrelPayerServiceSetupCZL.Init();
            UnrelPayerServiceSetupCZL.Insert();
        end;
    end;

    procedure RunCodeunit(CodeunitID: Integer)
    var
        AllObj: Record AllObj;
    begin
        AllObj.Get(AllObj."Object Type"::Codeunit, CodeunitID);
        Window.Update(1, StrSubstNo('%1 %2', AllObj."Object ID", AllObj."Object Name"));
        Steps := Steps + 1;
        Window.Update(2, Round(Steps / MaxSteps * 10000, 1));
        Codeunit.Run(CodeunitID);
    end;

    procedure IssuePaymentOrder(PaymentOrderNo: Code[20])
    var
        PaymentOrderHeaderCZB: Record "Payment Order Header CZB";
        IssuePaymentOrderCZB: Codeunit "Issue Payment Order CZB";
    begin
        PaymentOrderHeaderCZB.Get(PaymentOrderNo);
        IssuePaymentOrderCZB.Run(PaymentOrderHeaderCZB);
    end;

    procedure IssueBankStatement(BankStatementNo: Code[20])
    var
        BankStatementHeaderCZB: Record "Bank Statement Header CZB";
        IssueBankStatementCZB: Codeunit "Issue Bank Statement CZB";
    begin
        BankStatementHeaderCZB.Get(BankStatementNo);
        IssueBankStatementCZB.Run(BankStatementHeaderCZB);
    end;

    procedure ReleaseCashDocumentCZP(CashDeskNo: Code[20]; CashDocumentNo: Code[20])
    var
        CashDocumentHeaderCZP: Record "Cash Document Header CZP";
        CashDocumentReleaseCZP: Codeunit "Cash Document-Release CZP";
    begin
        CashDocumentHeaderCZP.Get(CashDeskNo, CashDocumentNo);
        CashDocumentReleaseCZP.Run(CashDocumentHeaderCZP);
    end;

    procedure PostCashDocumentCZP(CashDeskNo: Code[20]; CashDocumentNo: Code[20])
    var
        CashDocumentHeaderCZP: Record "Cash Document Header CZP";
        CashDocumentPostCZP: Codeunit "Cash Document-Post CZP";
    begin
        CashDocumentHeaderCZP.Get(CashDeskNo, CashDocumentNo);
        CashDocumentPostCZP.Run(CashDocumentHeaderCZP);
    end;

    procedure ReleaseSalesAdvanceLetterCZZ(LetterNo: Code[20])
    var
        SalesAdvLetterHeaderCZZ: Record "Sales Adv. Letter Header CZZ";
    begin
        SalesAdvLetterHeaderCZZ.Get(LetterNo);
        Codeunit.Run(Codeunit::"Rel. Sales Adv.Letter Doc. CZZ", SalesAdvLetterHeaderCZZ);
    end;

    procedure ReleasePurchAdvanceLetterCZZ(LetterNo: Code[20])
    var
        PurchAdvLetterHeaderCZZ: Record "Purch. Adv. Letter Header CZZ";
    begin
        PurchAdvLetterHeaderCZZ.Get(LetterNo);
        Codeunit.Run(Codeunit::"Rel. Purch.Adv.Letter Doc. CZZ", PurchAdvLetterHeaderCZZ);
    end;

    procedure PostGenJournalLine(JournalTemplateName: Code[10]; JournalBatchName: Code[10]; LineNo: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.Get(JournalTemplateName, JournalBatchName, LineNo);
        Codeunit.Run(Codeunit::"Gen. Jnl.-Post Line", GenJournalLine);
        GenJournalLine.Delete();
    end;

    procedure ReleaseCompensationtHeader(CompensationNo: Code[20]; RequiredLinesCount: Integer)
    var
        CompensationLineCZC: Record "Compensation Line CZC";
        CompensationHeaderCZC: Record "Compensation Header CZC";
        ReleaseCompensDocumentCZC: Codeunit "Release Compens. Document CZC";
    begin
        CompensationLineCZC.SetRange("Compensation No.", CompensationNo);
        if CompensationLineCZC.Count = RequiredLinesCount then begin
            CompensationHeaderCZC.Get(CompensationNo);
            ReleaseCompensDocumentCZC.Run(CompensationHeaderCZC);
        end;
    end;

    procedure PostCompensationHeader(CompensationNo: Code[20]; RequiredLinesCount: Integer)
    var
        CompensationLineCZC: Record "Compensation Line CZC";
        CompensationHeaderCZC: Record "Compensation Header CZC";
        CompensationPostCZC: Codeunit "Compensation - Post CZC";
    begin
        CompensationLineCZC.SetRange("Compensation No.", CompensationNo);
        if CompensationLineCZC.Count = RequiredLinesCount then begin
            CompensationHeaderCZC.Get(CompensationNo);
            CompensationPostCZC.Run(CompensationHeaderCZC);
        end;
    end;

    local procedure UpdateCostTypes()
    var
        CostType: Record "Cost Type";
    begin
        CostType.SetFilter("No.", '680000|601020|..499999');
        CostType.DeleteAll();
    end;

    procedure SuggestVATControls()
    var
        VATCtrlReportHeaderCZL: Record "VAT Ctrl. Report Header CZL";
        VATCtrlReportHeaderCZL2: Record "VAT Ctrl. Report Header CZL";
        VATCtrlReportGetEntCZL: Report "VAT Ctrl. Report Get Ent. CZL";
    begin
        if VATCtrlReportHeaderCZL.FindSet() then
            repeat
                VATCtrlReportHeaderCZL2 := VATCtrlReportHeaderCZL;
                VATCtrlReportHeaderCZL2.SetRecFilter();
                VATCtrlReportGetEntCZL.UseRequestPage(false);
                VATCtrlReportGetEntCZL.SetTableView(VATCtrlReportHeaderCZL2);
                VATCtrlReportGetEntCZL.SetVATCtrlReportHeader(VATCtrlReportHeaderCZL2);
                VATCtrlReportGetEntCZL.Run();
            until VATCtrlReportHeaderCZL.Next() = 0;
    end;

    procedure SuggestVIESDEclarations()
    var
        VIESDeclarationHeaderCZL: Record "VIES Declaration Header CZL";
        VIESDeclarationHeaderCZL2: Record "VIES Declaration Header CZL";
        SuggestVIESDeclarationCZL: Report "Suggest VIES Declaration CZL";
    begin
        if VIESDeclarationHeaderCZL.FindSet() then
            repeat
                VIESDeclarationHeaderCZL2 := VIESDeclarationHeaderCZL;
                VIESDeclarationHeaderCZL2.SetRecFilter();
                SuggestVIESDeclarationCZL.UseRequestPage(false);
                SuggestVIESDeclarationCZL.SetTableView(VIESDeclarationHeaderCZL2);
                SuggestVIESDeclarationCZL.Run();
            until VIESDeclarationHeaderCZL.Next() = 0;
    end;
}

