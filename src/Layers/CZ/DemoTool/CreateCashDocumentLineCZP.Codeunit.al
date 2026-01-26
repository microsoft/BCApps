codeunit 163513 "Create Cash Document Line CZP"
{

    trigger OnRun()
    begin
        InsertData('POK01', 'PPD0001', Enum::"Cash Document Account Type CZP"::"G/L Account", '648100', 1000.00, 0, '', XReceivingCash);
        InsertData('POK01', 'PPD0002', Enum::"Cash Document Account Type CZP"::"G/L Account", '518100', 250.00, 0, '', XRepayAnAdvance);
        InsertDataAndUpdateCashDeskEvent('POK01', 'PPD0003', CreateCashDeskEventCZP.GetEETCode(), 1210.00, XReceiptOfSaleFromServices);
        InsertData('POK01', 'PPD0004', Enum::"Cash Document Account Type CZP"::Customer, '10000', 125.00, 2, '103015', XPaymentOfTheInvoice);

        InsertData('POK01', 'VPD0001', Enum::"Cash Document Account Type CZP"::"G/L Account", '512100', 253.00, 0, '', XTravelCost);
        InsertData('POK01', 'VPD0002', Enum::"Cash Document Account Type CZP"::"G/L Account", '512100', 452.00, 0, '', XTravelCost);
        InsertDataAndUpdateCashDeskEvent('POK01', 'VPD0003', CreateCashDeskEventCZP.GetEETCorrectionCode(), 500.00, XCorrectionEET);
    end;

    var
        CashDocumentLineCZP: Record "Cash Document Line CZP";
        CreateCashDeskEventCZP: Codeunit "Create Cash Desk Event CZP";
        LineNo: Integer;
        PreviousDocumentNo: Code[20];
        XReceivingCash: Label 'receiving cash';
        XRepayAnAdvance: Label 'repay an advance';
        XTravelCost: Label 'travel cost';
        XReceiptOfSaleFromServices: Label 'receipt of sale from services';
        XCorrectionEET: Label 'correction EET';
        XPaymentOfTheInvoice: Label 'payment of the invoice';
        XCashdeposittothecashdesk: Label 'Cash deposit to the cash desk';
        XCashtranfer: Label 'Cash tranfer';
        XFuel: Label 'Fuel';
        XOfficesupplies: Label 'Office supplies';

    procedure InsertData(CashDeskNo: Code[20]; CashDocumentNo: Code[20]; AccountType: Enum "Cash Document Account Type CZP"; AccountNo: Code[20];
                        Amount: Decimal; AppliesToDocType: Option; AppliesToDocNo: Code[20]; Description: Text[100])
    begin
        CashDocumentLineCZP.Init();
        CashDocumentLineCZP."Cash Desk No." := CashDeskNo;
        CashDocumentLineCZP."Cash Document No." := CashDocumentNo;
        if PreviousDocumentNo <> CashDocumentNo then begin
            LineNo := 0;
            PreviousDocumentNo := CashDocumentNo;
        end;
        LineNo += 10000;
        CashDocumentLineCZP.Validate("Line No.", LineNo);
        CashDocumentLineCZP.Insert(true);
        if AccountNo <> '' then begin
            CashDocumentLineCZP.Validate("Account Type", AccountType);
            CashDocumentLineCZP.Validate("Account No.", AccountNo);
            CashDocumentLineCZP.Validate(Amount, Amount);
        end;
        CashDocumentLineCZP.Validate("Applies-To Doc. Type", AppliesToDocType);
        CashDocumentLineCZP.Validate("Applies-To Doc. No.", AppliesToDocNo);
        CashDocumentLineCZP.Description := Description;
        CashDocumentLineCZP.Modify(true);
    end;

    procedure InsertDataAndUpdateCashDeskEvent(CashDeskNo: Code[20]; CashDocumentNo: Code[20]; CashDeskEvent: Code[10]; Amount: Decimal; Description: Text[100])
    begin
        InsertData(CashDeskNo, CashDocumentNo, Enum::"Cash Document Account Type CZP"::" ", '', Amount, 0, '', '');
        CashDocumentLineCZP.Validate("Cash Desk Event", CashDeskEvent);
        CashDocumentLineCZP.Validate(Description, Description);
        CashDocumentLineCZP.Validate(Amount, Amount);
        CashDocumentLineCZP.Modify(true);
    end;

    procedure CreateEvaluationData()
    begin
        InsertDataAndUpdateCashDeskEvent('POK01', 'PPD0001', CreateCashDeskEventCZP.GetSubsidyCode(), 10000.00, XCashdeposittothecashdesk);
        InsertDataAndUpdateCashDeskEvent('POK01', 'PPD0002', CreateCashDeskEventCZP.GetSubsidyCode(), 15000.00, XCashtranfer);
        InsertDataAndUpdateCashDeskEvent('POK01', 'VPD0001', CreateCashDeskEventCZP.GetFuelCode(), 2000.00, XFuel);
        InsertDataAndUpdateCashDeskEvent('POK01', 'VPD0002', CreateCashDeskEventCZP.GetTransferCode(), 5000.00, XCashtranfer);
        InsertDataAndUpdateCashDeskEvent('POK01', 'VPD0003', CreateCashDeskEventCZP.GetOfficeSuppliesCode(), 350.00, XOfficesupplies);
    end;
}
