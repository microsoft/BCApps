codeunit 163539 "Create Cash Desk Event CZP"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax" then
            exit;

        InsertData(XEET, XSalesWithRegistrationToEET, CashDocumentType::Receipt, AccountType::"G/L Account", '602110', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.BaseVATServiceCode(), true);
        InsertData(XEETCORR, XCorrectionEET, CashDocumentType::Withdrawal, AccountType::"G/L Account", '602110', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.BaseVATServiceCode(), true);
    end;

    var
        XEET: Label 'EET';
        XEETCORR: Label 'EET-CORR';
        XFUEL: Label 'FUEL';
        XTRVLCOSTS: Label 'TRVLCOSTS', Comment = 'Travel costs';
        XSUBSIDY: Label 'SUBSIDY';
        XCASHPMTINV: Label 'CASHPMTINV';
        XCASHPMTCM: Label 'CASHPMTCM';
        XTRANSFER: Label 'TRANSFER';
        XOFFSUPP: Label 'OFFSUP', Comment = 'Office supplies';
        XREPCOSTS: Label 'REPCOSTS', Comment = 'Representation costs';
        XREPAIRS: Label 'REPAIRS';
        XMATPAID: Label 'MATPAID', Comment = 'Material paid by cash';
        XSalesWithRegistrationToEET: Label 'Sales with registration to EET';
        XCorrectionEET: Label 'Correction EET';
        XFuelpurchase: Label 'Fuel purchase';
        XTravelcosts: Label 'Travel costs';
        XCashreceiptfromthebank: Label 'Cash receipt from the bank';
        XCashpaymentoftheinvoice: Label 'Cash payment of the invoice';
        XCashpaymentofcreditmemo: Label 'Cash payment of credit memo';
        XCashdeposittothebank: Label 'Cash deposit to the bank';
        XOfficesupplies: Label 'Office supplies';
        XRepresentationcosts: Label 'Representation costs';
        XRepairandmaintenance: Label 'Repair and maintenance';
        XMaterialpaidbycash: Label 'Material paid by cash';
        CashDeskEventCZP: Record "Cash Desk Event CZP";
        DemoDataSetup: Record "Demo Data Setup";
        CashDocumentType: Enum "Cash Document Type CZP";
        AccountType: Enum "Cash Document Account Type CZP";

    procedure InsertData(CashDeskEventCode: Code[10]; Description: Text[50]; CashDocumentType: Enum "Cash Document Type CZP";
                        AccountType: Enum "Cash Document Account Type CZP"; AccountNo: Code[20];
                        GenPostingType: Option; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; EETTransaction: Boolean)
    begin
        CashDeskEventCZP.Init();
        CashDeskEventCZP.Code := CashDeskEventCode;
        CashDeskEventCZP.Description := Description;
        CashDeskEventCZP."Document Type" := CashDocumentType;
        CashDeskEventCZP."Account Type" := AccountType;
        CashDeskEventCZP."Account No." := AccountNo;
        CashDeskEventCZP."Gen. Posting Type" := GenPostingType;
        CashDeskEventCZP."VAT Bus. Posting Group" := VATBusPostingGroup;
        CashDeskEventCZP."VAT Prod. Posting Group" := VATProdPostingGroup;
        case CashDeskEventCode of
            XCASHPMTINV:
                CashDeskEventCZP."Gen. Document Type" := CashDeskEventCZP."Gen. Document Type"::Payment;
            XCASHPMTCM:
                CashDeskEventCZP."Gen. Document Type" := CashDeskEventCZP."Gen. Document Type"::Refund;
        end;
        CashDeskEventCZP."EET Transaction" := EETTransaction;
        CashDeskEventCZP.Insert();
    end;

    procedure CreateEvaluationData()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax" then
            exit;

        InsertData(XEET, XSalesWithRegistrationToEET, CashDocumentType::Receipt, AccountType::"G/L Account", '602110', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.BaseVATServiceCode(), true);
        InsertData(XEETCORR, XCorrectionEET, CashDocumentType::Withdrawal, AccountType::"G/L Account", '602110', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.BaseVATServiceCode(), true);
        InsertData(XFUEL, XFuelpurchase, CashDocumentType::Withdrawal, AccountType::"G/L Account", '501200', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.BaseVATItemCode(), false);
        InsertData(XTRVLCOSTS, XTravelcosts, CashDocumentType::Withdrawal, AccountType::"G/L Account", '512100', 0, '', '', false);
        InsertData(XSUBSIDY, XCashreceiptfromthebank, CashDocumentType::Receipt, AccountType::"G/L Account", '261100', 0, '', '', false);
        InsertData(XCASHPMTINV, XCashpaymentoftheinvoice, CashDocumentType::Receipt, AccountType::Customer, '', 0, '', '', true);
        InsertData(XCASHPMTCM, XCashpaymentofcreditmemo, CashDocumentType::Withdrawal, AccountType::Customer, '', 0, '', '', true);
        InsertData(XTRANSFER, XCashdeposittothebank, CashDocumentType::Withdrawal, AccountType::"G/L Account", '261100', 0, '', '', false);
        InsertData(XOFFSUPP, XOfficesupplies, CashDocumentType::Withdrawal, AccountType::"G/L Account", '501100', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.BaseVATItemCode(), false);
        InsertData(XREPCOSTS, XRepresentationcosts, CashDocumentType::Withdrawal, AccountType::"G/L Account", '513100', 0, '', '', false);
        InsertData(XREPAIRS, XRepairandmaintenance, CashDocumentType::Withdrawal, AccountType::"G/L Account", '511100', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.BaseVATServiceCode(), false);
        InsertData(XMATPAID, XMaterialpaidbycash, CashDocumentType::Withdrawal, AccountType::"G/L Account", '501100', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.BaseVATItemCode(), false);
    end;

    procedure GetEETCode(): Code[10]
    begin
        exit(XEET);
    end;

    procedure GetEETCorrectionCode(): Code[10]
    begin
        exit(XEETCORR);
    end;

    procedure GetFuelCode(): Code[10]
    begin
        exit(XFUEL);
    end;

    procedure GetTravelCostsCode(): Code[10]
    begin
        exit(XTRVLCOSTS);
    end;

    procedure GetSubsidyCode(): Code[10]
    begin
        exit(XSUBSIDY);
    end;

    procedure GetCashPaymentInvoiceCode(): Code[10]
    begin
        exit(XCASHPMTINV);
    end;

    procedure GetCashPaymentCreditMemoCode(): Code[10]
    begin
        exit(XCASHPMTCM);
    end;

    procedure GetTransferCode(): Code[10]
    begin
        exit(XTRANSFER);
    end;

    procedure GetOfficeSuppliesCode(): Code[10]
    begin
        exit(XOFFSUPP);
    end;

    procedure GetRepresenatationCostsCode(): Code[10]
    begin
        exit(XREPCOSTS);
    end;

    procedure GetRepairsCode(): Code[10]
    begin
        exit(XREPAIRS);
    end;

    procedure GetMaterialPaidCode(): Code[10]
    begin
        exit(XMATPAID);
    end;
}

