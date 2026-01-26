codeunit 163512 "Create Cash Document Hdr. CZP"
{

    trigger OnRun()
    begin
        InsertData('POK01', Enum::"Cash Document Type CZP"::Receipt, 19020101D, XReceivingCash);
        InsertData('POK01', Enum::"Cash Document Type CZP"::Receipt, 19020101D, XRepayAnAdvance);
        InsertData('POK01', Enum::"Cash Document Type CZP"::Receipt, 19030110D, XReceiptOfSaleFromServices);
        InsertData('POK01', Enum::"Cash Document Type CZP"::Receipt, 19030111D, XPaymentOfTheInvoice);
        InsertData('POK01', Enum::"Cash Document Type CZP"::Withdrawal, 19020101D, XTravelCost);
        InsertData('POK01', Enum::"Cash Document Type CZP"::Withdrawal, 19020101D, XTravelCost);
        InsertData('POK01', Enum::"Cash Document Type CZP"::Withdrawal, 19030110D, XCorrectionEET);
    end;

    var
        CashDocumentHeaderCZP: Record "Cash Document Header CZP";
        XCashdeposittothecashdesk: Label 'Cash deposit to the cash desk';
        XCashdepositfromtheaccount: Label 'Cash deposit from the account';
        XCashdeposittothebank: Label 'Cash deposit to the bank';
        XTravelcost: Label 'Travel cost';
        XFuelpurchase: Label 'Fuel purchase';
        XPurchaseofofficesupplies: Label 'Purchase of office supplies';
        XReceivingCash: Label 'Receiving cash';
        XRepayAnAdvance: Label 'Repay an advance';
        XReceiptOfSaleFromServices: Label 'Receipt of sale from services';
        XCorrectionEET: Label 'Correction EET';
        XPaymentOfTheInvoice: Label 'Payment of the invoice';
        CA: Codeunit "Make Adjustments";

    procedure InsertData(CashDeskNo: Code[20]; CashDocumentType: Enum "Cash Document Type CZP"; PostingDate: Date; PaymentPurpose: Text[100])
    begin
        CashDocumentHeaderCZP.Init();
        CashDocumentHeaderCZP."Document Type" := CashDocumentType;
        CashDocumentHeaderCZP."Cash Desk No." := CashDeskNo;
        CashDocumentHeaderCZP."No." := '';
        CashDocumentHeaderCZP.Insert(true);

        CashDocumentHeaderCZP.Validate("Posting Date", CA.AdjustDate(PostingDate));
        CashDocumentHeaderCZP."Payment Purpose" := PaymentPurpose;
        CashDocumentHeaderCZP.Modify(true);
    end;

    procedure CreateEvaluationData()
    begin
        InsertData('POK01', Enum::"Cash Document Type CZP"::Receipt, 19030129D, XCashdeposittothecashdesk);
        InsertData('POK01', Enum::"Cash Document Type CZP"::Receipt, 19030131D, XCashdepositfromtheaccount);
        InsertData('POK01', Enum::"Cash Document Type CZP"::Withdrawal, 19030129D, XFuelpurchase);
        InsertData('POK01', Enum::"Cash Document Type CZP"::Withdrawal, 19030129D, XCashdeposittothebank);
        InsertData('POK01', Enum::"Cash Document Type CZP"::Withdrawal, 19030131D, XPurchaseofofficesupplies);
    end;
}
