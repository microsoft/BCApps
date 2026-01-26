codeunit 161508 "Enhance CH Master Data"
{

    trigger OnRun()
    begin
        CompanyInformation.Get();
        CompanyInformation.Address := 'Ringstrasse 5';
        CompanyInformation."Address 2" := 'Postfach 123';
        CompanyInformation."Post Code" := '6300';
        CompanyInformation.City := 'Zug';
        CompanyInformation."Country/Region Code" := 'CH';

        CompanyInformation."Ship-to Address" := 'Ringstrasse 5';
        CompanyInformation."Ship-to Address 2" := 'Postfach 123';
        CompanyInformation."Ship-to Post Code" := '6300';
        CompanyInformation."Ship-to City" := 'Zug';
        CompanyInformation."Ship-to Country/Region Code" := 'CH';

        CompanyInformation."Bank Name" := 'Zuger Kantonalbank';
        CompanyInformation."Bank Branch No." := '3105';
        CompanyInformation."Bank Account No." := '118.521-9';
        CompanyInformation.IBAN := 'CH290029129181284840H';

        CompanyInformation."Phone No." := xPhone;
        CompanyInformation."Fax No." := xFax;
        CompanyInformation."Bank Branch No." := xBBranch;
        CompanyInformation."Bank Account No." := xBankAcc;
        CompanyInformation."Payment Routing No." := xPayRou;
        CompanyInformation."Giro No." := xGiro;
        CompanyInformation."E-Mail" := xEMail;
        CompanyInformation."Home Page" := xHomeP;
        CompanyInformation.Modify();

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Adjust for Payment Disc." := true;
        GeneralLedgerSetup."Inv. Rounding Precision (LCY)" := 0.05;
        GeneralLedgerSetup.Modify();

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Credit Warnings" := 3;  // Keine Warnung
        SalesReceivablesSetup."Discount Posting" := 0;  // Keine separate Buchung
        SalesReceivablesSetup.Modify();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Discount Posting" := 0;  // Keine Rabatte
        PurchasesPayablesSetup."Receipt on Invoice" := false;
        PurchasesPayablesSetup."Invoice Rounding" := false;
        PurchasesPayablesSetup.Modify();

        CustomerBankAccount.SetRange("Customer No.", '10000', '50000');
        CustomerBankAccount.ModifyAll("Phone No.", '');

        CustomerBankAccount.SetRange("Customer No.", '41000000', '41999999');
        CustomerBankAccount.ModifyAll("Phone No.", '');

        GenJournalBatch.Get(xGenJournAllge, xGenJournBar);
        GenJournalBatch."No. Series" := '';
        GenJournalBatch.Modify();
        GenJournalBatch.Get(xGenJournAllge, xGenJournStand);
        GenJournalBatch."No. Series" := '';
        GenJournalBatch.Modify();

        // Zahlungsart von ESR auf Bank Ausland korrigieren
        if VendorBankAccount.Find('-') then
            repeat
                VendorBankAccount."Payment Form" := VendorBankAccount."Payment Form"::"Bank Payment Abroad";
                VendorBankAccount.Modify();
            until VendorBankAccount.Next() = 0;

        // Lagerbuchungsgruppen Bezeichnungen anf´Š¢gen
        DemoDataSetup.Get();
        InventoryPostingGroup.Get(DemoDataSetup.ResaleCode());
        InventoryPostingGroup.Description := xInvWVDesc;
        InventoryPostingGroup.Modify();
        InventoryPostingGroup.Get(DemoDataSetup.FinishedCode());
        InventoryPostingGroup.Description := xInvFertigDesc;
        InventoryPostingGroup.Modify();
        InventoryPostingGroup.Get(DemoDataSetup.RawMatCode());
        InventoryPostingGroup.Description := xInvRohDesc;
        InventoryPostingGroup.Modify();

        // Language Code Mergefield
        MarketingSetup.Get();
        // MarkEinr.VALIDATE("Mergefield Language ID",2055);  // ORIG
        MarketingSetup.Validate("Mergefield Language ID", GlobalLanguage);  // Set it depending on Active Language
        MarketingSetup.Modify();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        CompanyInformation: Record "Company Information";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        MarketingSetup: Record "Marketing Setup";
        CustomerBankAccount: Record "Customer Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorBankAccount: Record "Vendor Bank Account";
        InventoryPostingGroup: Record "Inventory Posting Group";
        xPhone: Label '041 725 18 11';
        xFax: Label '041 725 18 18';
        xBBranch: Label '787';
        xBankAcc: Label '01-30-130264-05';
        xPayRou: Label '525';
        xGiro: Label '60-9-9';
        xEMail: Label 'verkauf@contoso.com';
        xHomeP: Label 'www.contoso.com';
        xInvWVDesc: Label 'Resale';
        xInvFertigDesc: Label 'Finished Prod.';
        xInvRohDesc: Label 'Raw Materials';
        xGenJournAllge: Label 'GENERAL';
        xGenJournBar: Label 'CASH';
        xGenJournStand: Label 'DEFAULT';

    procedure DimTranslation(_Code: Code[20]; _LanguageID: Integer; _Name: Text[30])
    var
        DimTrans: Record "Dimension Translation";
    begin
        DimTrans.Init();
        DimTrans.Validate(Code, _Code);
        DimTrans.Validate("Language ID", _LanguageID);
        DimTrans.Validate(Name, _Name);
        DimTrans.Insert();
    end;

    procedure VATReportSelection()
    var
        ReportSelection: Record "Report Selections";
    begin
        ReportSelection.Init();
        // XXXXXX ReportSelection.Usage := ReportSelection.Usage::"VAT Stmt";
        ReportSelection.Sequence := '1';
        ReportSelection."Report ID" := 12;
        if not ReportSelection.Insert() then
            ReportSelection.Modify();
    end;
}

