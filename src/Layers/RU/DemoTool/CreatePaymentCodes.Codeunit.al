codeunit 163424 "Create Payment Codes"
{

    trigger OnRun()
    begin
        InsertData(0, '0', XNocode, '', 0); // option 1
        InsertData(0, XTP, XPaymentsofcurrentperiod, '0', 0);
        InsertData(0, XZD, XVoluntaryoffsetofdebt, '0', 0);
        InsertData(0, XTR, XOffsetofdebtbydemand, '', 1);
        InsertData(0, XRS, XOffsetofinstallmentdebt, '', 2);
        InsertData(0, XOT, XOffsetofdeffereddebt, '', 3);
        InsertData(0, XVU, XOffsetofdeffereddebtinconn, '', 4);
        InsertData(0, XPR, XOffsetofdebtsuspended, '', 5);
        InsertData(0, XAP, XOffsetofdebtviaauditact, '', 6);
        InsertData(0, XAR, XOffsetofdebtviaexecact, '', 7);
        InsertData(0, XBF, '', '', 0);
        InsertData(0, XRT, '', '', 0);
        InsertData(0, XCD, XCustomsDeclaration, '', 0);
        InsertData(0, XCR, XCustomsReceipt, '', 0);
        InsertData(0, XAF, XAffirmativeReceipt, '', 0);

        InsertData(1, '0', XNocode, '', 0); // option 1
        InsertData(1, XNS, XDischargeoftaxorcharge, '', 0);
        InsertData(1, XAV, XAdvancepaymentorprepayment, '', 0);
        InsertData(1, XPE, XPenaltyfeespayment, '', 0);
        InsertData(1, XPC, XInterestspayment, '', 0);
        InsertData(1, XSA, XTaxsanctions, '', 0);
        InsertData(1, XASH, XAdministrativepenalties, '', 0);
        InsertData(1, XISH, XOtherpenalties, '', 0);
        InsertData(1, XPL, '', '', 0);
        InsertData(1, XGR, '', '', 0);
        InsertData(1, XVZ, '', '', 0);
        InsertData(1, XFI, XPaymentoffine, '', 0);
        InsertData(1, XOD, XOffsetofdebt, '', 0);
        InsertData(1, XPF, XPaymentofpenaltyfee, '', 0);
    end;

    var
        PaymentOrderCode: Record "Payment Order Code";
        XTP: Label 'TP';
        XZD: Label 'ZD';
        XTR: Label 'TR';
        XRS: Label 'RS';
        XOT: Label 'OT';
        XVU: Label 'VU';
        XPR: Label 'PR';
        XAP: Label 'AP';
        XAR: Label 'AR';
        XBF: Label 'BF';
        XRT: Label 'RT';
        XNS: Label 'NS';
        XAV: Label 'AV';
        XPE: Label 'PE';
        XPC: Label 'PC';
        XSA: Label 'SA';
        XASH: Label 'ASH';
        XISH: Label 'ISH';
        XPL: Label 'PL';
        XGR: Label 'GR';
        XVZ: Label 'VZ';
        XNocode: Label 'No code';
        XPaymentsofcurrentperiod: Label 'Payments of current period';
        XVoluntaryoffsetofdebt: Label 'Voluntary offset of debt for the pass tax period';
        XOffsetofdebtbydemand: Label 'Offset of debt by demand of tax authorities about tax payments';
        XOffsetofinstallmentdebt: Label 'Offset of installment debt';
        XOffsetofdeffereddebt: Label 'Offset of deferred debt';
        XOffsetofdeffereddebtinconn: Label 'Offset of deferred debt in connection with implementation of external management';
        XOffsetofdebtsuspended: Label 'Offset of debt suspended for penalty';
        XOffsetofdebtviaauditact: Label 'Offset of debt via audit act';
        XOffsetofdebtviaexecact: Label 'Offset of debt via executive act';
        XDischargeoftaxorcharge: Label 'Discharge of tax or charge';
        XAdvancepaymentorprepayment: Label 'Advance payment or prepayment';
        XPenaltyfeespayment: Label 'Penalty fees payment';
        XInterestspayment: Label 'Interests payment';
        XTaxsanctions: Label 'Tax sanctions according Tax Code RF';
        XAdministrativepenalties: Label 'Administrative penalties';
        XOtherpenalties: Label 'Other penalties';
        XCD: Label 'CD';
        XCR: Label 'CR';
        XAF: Label 'AF';
        XCustomsDeclaration: Label 'Customs declaration';
        XCustomsReceipt: Label 'Customs receipt';
        XAffirmativeReceipt: Label 'Affirmative receipt in case of a fine';
        XFI: Label 'FI';
        XOD: Label 'OD';
        XPF: Label 'PF';
        XPaymentoffine: Label 'Payment of fine';
        XOffsetofdebt: Label 'Offset of debt';
        XPaymentofpenaltyfee: Label 'Payment of penalty fee';

    procedure InsertData(Type: Option; "Code": Code[10]; Description: Text[100]; "Reason Document No.": Code[10]; "Reason Document Type": Option)
    begin
        PaymentOrderCode.Init();
        PaymentOrderCode.Type := Type;
        PaymentOrderCode.Code := Code;
        PaymentOrderCode.Description := Description;
        PaymentOrderCode."Reason Document No." := "Reason Document No.";
        PaymentOrderCode."Reason Document Type" := "Reason Document Type";
        PaymentOrderCode.Insert();
    end;
}

