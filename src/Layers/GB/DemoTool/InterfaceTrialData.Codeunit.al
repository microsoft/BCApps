codeunit 122000 "Interface Trial Data"
{

    trigger OnRun()
    begin
        CreateSetupData();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Currency: Record Currency;
        CreateCurrency: Codeunit "Create Currency";
        CreateFinanceChargeTerms: Codeunit "Create Finance Charge Terms";
        CreateGeneralLedgerSetup: Codeunit "Create General Ledger Setup";
        CreateSalesReceivablesS: Codeunit "Create Sales & Receivables S.";
        CreatePurchasesPayablesS: Codeunit "Create Purchases & Payables S.";
        CreateInventorySetup: Codeunit "Create Inventory Setup";
        CreateGeneralPostingSetup: Codeunit "Create General Posting Setup";
        CreateGenProdPostingGr: Codeunit "Create Gen. Prod. Posting Gr.";
        CreateGLAccount: Codeunit "Create G/L Account";
        CreatePaymentMethod: Codeunit "Create Payment Method";
        CreateInventoryPostingSetup: Codeunit "Create Inventory Posting Setup";
        CreateItemPostingGroup: Codeunit "Create Item Posting Group";
        XMiniAppDataMsg: Label 'Create trial demo data';
        CreateGenJournalTemplate: Codeunit "Create Gen. Journal Template";
        CreateGenJournalBatch: Codeunit "Create Gen. Journal Batch";
        CreateFAPostingGroup: Codeunit "Create FA Posting Group";
        CreateFALocation: Codeunit "Create FA Location";
        Window: Dialog;

    procedure CreateSetupData()
    var
        CreateInteractionGroup: Codeunit "Create Interaction Group";
        CreateInteractionTemplate: Codeunit "Create Interaction Template";
        CreateInteractTemplSetup: Codeunit "Create Interact. Templ. Setup";
        CreateBusinessRelation: Codeunit "Create Business Relation";
        CreateMarketingSetup: Codeunit "Create Marketing Setup";
        CreateSalesCycle: Codeunit "Create Sales Cycle";
        CreateSalesCycleStage: Codeunit "Create Sales Cycle Stage";
        CreateProfileQuestHeader: Codeunit "Create Profile Quest. Header";
        CreateProfileQuestLine: Codeunit "Create Profile Quest. Line";
        CreateItemJournalTemplate: Codeunit "Create Item Journal Template";
        CreateIncomingDocument: Codeunit "Create Incoming Document";
        CreateTextToAccountMapping: Codeunit "Create Text To Account Mapping";
        CreateICPartner: Codeunit "Create IC Partner";
    begin
        DemoDataSetup.Get();
        Window.Open(XMiniAppDataMsg);

        RunCodeunit(CODEUNIT::"Create Source Code");
        RunCodeunit(CODEUNIT::"Create Payment Terms");
        RunCodeunit(CODEUNIT::"Create Shipping Agent");
        RunCodeunit(CODEUNIT::"Create Shipping Agent Service");
        RunCodeunit(CODEUNIT::"Create Currency");
        CreateFinanceChargeTerms.InsertMiniAppData();
        RunCodeunit(CODEUNIT::"Create Reminder Terms");
        RunCodeunit(CODEUNIT::"Create Reminder Level");
        RunCodeunit(CODEUNIT::"Create Reminder Text");
        RunCodeunit(CODEUNIT::"Create Language");
        RunCodeunit(CODEUNIT::"Create Country/Region");
        RunCodeunit(CODEUNIT::"Create Post Code");
        RunCodeunit(CODEUNIT::"Create Unit of Measure");
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then begin
            RunCodeunit(CODEUNIT::"Create VAT Bus. Posting Gr.");
            RunCodeunit(CODEUNIT::"Create VAT Prod. Posting Gr.");
            RunCodeunit(CODEUNIT::"Create VAT Statement Template");
            RunCodeunit(CODEUNIT::"Create VAT Statement Name");
            RunCodeunit(CODEUNIT::"Create VAT Statement Line");
            RunCodeunit(CODEUNIT::"Create VAT Report Configs");
        end;
        CreateGeneralLedgerSetup.InsertMiniAppData();
        CreatePurchasesPayablesS.InsertMiniAppData();
        CreateInventorySetup.InsertMiniAppData();
        RunCodeunit(CODEUNIT::"Create Jobs Setup");
        RunCodeunit(CODEUNIT::"Create Resources Setup");
        CreateSalesReceivablesS.InsertMiniAppData();
        RunCodeunit(CODEUNIT::"Create Gen. Bus. Posting Gr.");
        CreateGenProdPostingGr.InsertMiniAppData();
        CreateGLAccount.InsertMiniAppData();
        RunCodeunit(CODEUNIT::"Create Jobs Setup");
        CreateCurrency.ModifyData();
        RunCodeunit(CODEUNIT::"Create VAT Posting Setup");
        RunCodeunit(CODEUNIT::"Create VAT Assisted Setup");
        RunCodeunit(CODEUNIT::"Create VAT Clause");
        CreateGeneralPostingSetup.InsertMiniAppData();
        RunCodeunit(CODEUNIT::"Create Cust. Posting Group");
        RunCodeunit(CODEUNIT::"Create Vendor Posting Group");
        RunCodeunit(CODEUNIT::"Create Data Exch. Column Def");
        CreatePaymentMethod.InsertMiniAppData();
        RunCodeunit(CODEUNIT::"Create Unit of Measure Trans.");
        CreateItemPostingGroup.InsertMiniAppData();
        CreateInventoryPostingSetup.InsertMiniAppData();
        RunCodeunit(CODEUNIT::"Create Bank Acc. Posting Group");
        RunCodeunit(CODEUNIT::"Create PowerBI Data");
        RunCodeunit(CODEUNIT::"Create Media Repository");
        RunCodeunit(CODEUNIT::"Create Activity");
        RunCodeunit(CODEUNIT::"Create Activity Step");
        RunCodeunit(Codeunit::"Create Job Queue Setup");
        CreateSalesCycle.InsertMiniAppData();
        CreateSalesCycleStage.InsertMiniAppData();
        CreateInteractionGroup.InsertMiniAppData();
        CreateInteractionTemplate.InsertMiniAppData();
        CreateInteractTemplSetup.InsertMiniAppData();
        CreateBusinessRelation.InsertMiniAppData();
        CreateMarketingSetup.InsertMiniAppData();
        CreateProfileQuestHeader.InsertEvaluationData();
        CreateProfileQuestLine.InsertEvaluationData();
        CreateIncomingDocument.CreateIncomingDocSetup();
        CreateTextToAccountMapping.CreateEvaluationData();
        RunCodeunit(CODEUNIT::"Create Price Calculation Setup");
        RunCodeunit(Codeunit::"Create Assembly Setup");
        RunCodeunit(CODEUNIT::"Create Req. Wksh. Template");
        RunCodeunit(CODEUNIT::"Create Requisition Wksh. Name");
        RunCodeunit(Codeunit::"Create Order Promising Setup");

        // human resources
        RunCodeunit(CODEUNIT::"Create Human Resources Uom");
        RunCodeunit(CODEUNIT::"Create Human Resources Setup");

        // fixed assets
        RunCodeunit(CODEUNIT::"Create FA Setup");
        RunCodeunit(CODEUNIT::"Create FA Jnl. Template");
        RunCodeunit(CODEUNIT::"Create FA Jnl. Batch");
        RunCodeunit(CODEUNIT::"Create FA Recl. Jnl. Template");
        RunCodeunit(CODEUNIT::"Create FA Recl. Jnl. Batch");
        RunCodeunit(CODEUNIT::"Create FA Ins. Jnl. Template");
        RunCodeunit(CODEUNIT::"Create FA Ins. Jnl. Batch");

        CreateFAPostingGroup.CreateTrialData();
        RunCodeunit(CODEUNIT::"Create Depreciation Book");
        RunCodeunit(CODEUNIT::"Create FA Insurance Type");
        RunCodeunit(CODEUNIT::"Create FA Journal Setup");
        CreateFALocation.CreateTrialData();

        CreateGenJournalTemplate.InsertMiniAppData();
        CreateGenJournalBatch.InsertMiniAppData();
        RunCodeunit(CODEUNIT::"Create Chart Definitions");
        InsertOnlineMapSetup();
        if Currency.Get(DemoDataSetup."Currency Code") then
            Currency.Delete(true);
        RunCodeunit(CODEUNIT::"Create Custom Report Layout");
        RunCodeunit(CODEUNIT::"Create Cue Setup");
        RunCodeunit(CODEUNIT::"Create O365 HTML Templates");
        RunCodeunit(CODEUNIT::"Create Tariff Number");
        RunCodeunit(CODEUNIT::"Create Transaction Type");
        CreateItemJournalTemplate.InsertMiniAppData();
        RunCodeunit(CODEUNIT::"Create Excel Templates");
        RunCodeunit(Codeunit::"Create Word Templates");
        RunCodeunit(CODEUNIT::"Create Miniform Header");
        RunCodeunit(CODEUNIT::"Create Miniform Line");
        RunCodeunit(CODEUNIT::"Create Miniform Function Group");
        RunCodeunit(CODEUNIT::"Create Miniform Function");
        RunCodeunit(CODEUNIT::"Create Named Forward Links");
        CreateICPartner.CreateICSetup();
        RunCodeunit(Codeunit::"Create IC G/L Account");
        RunCodeunit(CODEUNIT::"Create Reminder Communication");
        FinalizeSetup();

        Window.Close();
    end;

    local procedure RunCodeunit(CodeunitID: Integer)
    begin
        CODEUNIT.Run(CodeunitID);
    end;

    local procedure FinalizeSetup()
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        // Required to cleanup any data that might have been added by company initialize or other "automated" triggers
        if CostAccountingSetup.Get() then
            CostAccountingSetup.Delete(true);
    end;

    local procedure InsertOnlineMapSetup()
    var
        OnlineMapMgt: Codeunit "Online Map Management";
    begin
        OnlineMapMgt.SetupDefault();
    end;
}

