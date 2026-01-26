codeunit 101903 "Localized Create Demo Data"
{

    trigger OnRun()
    begin
    end;

    var
        CreateAccScheduleName: Codeunit "Create Acc. Schedule Name";
        CreateAccScheduleLine: Codeunit "Create Acc. Schedule Line";
        CreateCashDeskCZP: Codeunit "Create Cash Desk CZP";
        CreateCashDeskEventCZP: Codeunit "Create Cash Desk Event CZP";
        CreateCashDocumentHdrCZP: Codeunit "Create Cash Document Hdr. CZP";
        CreateCashDocumentLineCZP: Codeunit "Create Cash Document Line CZP";
        CreateColumnLayout: Codeunit "Create Column Layout";
        CreateColumnLayoutName: Codeunit "Create Column Layout Name";
        CreateFAExtPostingGrCZF: Codeunit "Create FA Ext. Posting Gr. CZF";
        CreateGeneralPostingSetup: Codeunit "Create General Posting Setup";
        CreateGenJournalBatch: Codeunit "Create Gen. Journal Batch";
        CreateGLAccount: Codeunit "Create G/L Account";
        CreateItemJournalBatch: Codeunit "Create Item Journal Batch";
        CreatePaymentOrderLineCZB: Codeunit "Create Payment Order Line CZB";
        CreateRoundingMethod: Codeunit "Create Rounding Method";
        CreateStatReportSetupCZL: Codeunit "Create Stat. Report. Setup CZL";

    procedure CreateDataBeforeActions()
    var
        DemoDataSetup: Record "Demo Data Setup";
        InterfaceCZData: Codeunit "Interface CZ Data";
    begin
        DemoDataSetup.Get();
        if DemoDataSetup.Financials then
            InterfaceCZData.Create();
    end;

    procedure CreateDataAfterActions()
    begin
        UpdateInventorySetup();
    end;

    procedure CreateEvaluationData()
    var
        CashDeskUserCZP: Record "Cash Desk User CZP";
        DemoDataSetup: Record "Demo Data Setup";
    begin
        DemoDataSetup.Get();

        Codeunit.Run(Codeunit::"Create WIP Accounts");
        Codeunit.Run(Codeunit::"Create Reason Code");
        Codeunit.Run(Codeunit::"Create Tax Depr. Group CZF");
        Codeunit.Run(Codeunit::"Create VAT Attribute Code CZL");
        Codeunit.Run(Codeunit::"Create Compensations Setup CZC");
        CreateRoundingMethod.InsertMiniAppData();
        CreateStatReportSetupCZL.InsertMiniAppData();
        Codeunit.Run(Codeunit::"Create Invt. Mvmt. Templ. CZL");
        CreateFAExtPostingGrCZF.CreateTrialData();
        CreateItemJournalBatch.InsertMiniAppData();
        Codeunit.Run(Codeunit::"Create AdvLetter Template CZZ");
        CreateColumnLayoutName.InsertMiniAppData();
        CreateColumnLayout.InsertMiniAppData();
        CreateAccScheduleName.InsertMiniAppData();
        CreateAccScheduleLine.InsertMiniAppData();
        Codeunit.Run(Codeunit::"Create Acc. Sch. File Map. CZL");
        Codeunit.Run(Codeunit::"Create Commodity CZL");
        codeunit.Run(codeunit::"Create Commodity Setup CZL");
        Codeunit.Run(Codeunit::"Create Curr. Nominal Value CZP");

        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Evaluation then begin
            Codeunit.Run(Codeunit::"Create Banking Setup CZB");
            Codeunit.Run(Codeunit::"Create Bank Statement Hdr. CZB");
            Codeunit.Run(Codeunit::"Create Bank Statement Line CZB");
            Codeunit.Run(Codeunit::"Create Payment Order Hdr. CZB");
            CreatePaymentOrderLineCZB.CreateEvaluationData();
            CreateCashDeskCZP.CreateEvaluationData();
            Codeunit.Run(Codeunit::"Create Cash Desk User CZP");
            CreateCashDeskEventCZP.CreateEvaluationData();
            CreateCashDocumentHdrCZP.CreateEvaluationData();
            CreateCashDocumentLineCZP.CreateEvaluationData();
#if not CLEAN28
            Codeunit.Run(Codeunit::"Create VAT Period CZL");
#endif            
            Codeunit.Run(Codeunit::"Create VAT Return Period CZL");
            Codeunit.Run(Codeunit::"Create Company Official CZL");
            Codeunit.Run(Codeunit::"Create P. AdvLetter Header CZZ");
            Codeunit.Run(Codeunit::"Create P. AdvLetter Line CZZ");
            Codeunit.Run(Codeunit::"Create P. AdvLetter Appl. CZZ");
            Codeunit.Run(Codeunit::"Create S. AdvLetter Header CZZ");
            Codeunit.Run(Codeunit::"Create S. AdvLetter Line CZZ");
            Codeunit.Run(Codeunit::"Create S. AdvLetter Appl. CZZ");
            Codeunit.Run(Codeunit::"Create EET Busin. Premises CZL");
            Codeunit.Run(Codeunit::"Create EET Cash Register CZL");
            CreateStatReportSetupCZL.CreateEvaluationData();
            Codeunit.Run(Codeunit::"Create Document Footer CZL");
            CreateGeneralPostingSetup.CreateEvaluationData();
            CreateGenJournalBatch.CreateEvaluationData();

            // Delete temporary user
            CashDeskUserCZP.SetRange("Cash Desk No.", 'POK01');
            CashDeskUserCZP.SetRange("User ID", UserId);
            CashDeskUserCZP.DeleteAll();
        end;

        CreateGLAccount.AddCategoriesToGLAccounts();
    end;

    procedure CreateExtendedData()
    begin
        CreateColumnLayoutName.InsertMiniAppData();
        CreateColumnLayout.InsertMiniAppData();
    end;

    local procedure UpdateInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup."Automatic Cost Posting" := true;
        InventorySetup.Modify();
    end;
}

