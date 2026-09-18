codeunit 161391 "Create FatturaPA Codes"
{

    trigger OnRun()
    var
        CompanyTypes: Record "Company Types";
        FatturaCode: Record "Fattura Code";
    begin
        // Fattura Codes
        InsertCodeData(TP01Txt, TP01DescTxt, FatturaCode.Type::"Payment Terms");
        InsertCodeData(TP02Txt, TP02DescTxt, FatturaCode.Type::"Payment Terms");
        InsertCodeData(TP03Txt, TP03DescTxt, FatturaCode.Type::"Payment Terms");
        InsertCodeData(MP01Txt, MP01DescTxt, FatturaCode.Type::"Payment Method");
        InsertCodeData(MP02Txt, MP02DescTxt, FatturaCode.Type::"Payment Method");
        InsertCodeData(MP03Txt, MP03DescTxt, FatturaCode.Type::"Payment Method");
        InsertCodeData(MP04Txt, MP04DescTxt, FatturaCode.Type::"Payment Method");
        InsertCodeData(MP05Txt, MP05DescTxt, FatturaCode.Type::"Payment Method");
        InsertCodeData(MP06Txt, MP06DescTxt, FatturaCode.Type::"Payment Method");
        InsertCodeData(MP07Txt, MP07DescTxt, FatturaCode.Type::"Payment Method");
        InsertCodeData(MP08Txt, MP08DescTxt, FatturaCode.Type::"Payment Method");
        InsertCodeData(MP09Txt, MP09DescTxt, FatturaCode.Type::"Payment Method");
        InsertCodeData(MP10Txt, MP10DescTxt, FatturaCode.Type::"Payment Method");
        InsertCodeData(MP11Txt, MP11DescTxt, FatturaCode.Type::"Payment Method");
        InsertCodeData(MP12Txt, MP12DescTxt, FatturaCode.Type::"Payment Method");
        InsertCodeData(MP13Txt, MP13DescTxt, FatturaCode.Type::"Payment Method");
        InsertCodeData(MP14Txt, MP14DescTxt, FatturaCode.Type::"Payment Method");
        InsertCodeData(MP15Txt, MP15DescTxt, FatturaCode.Type::"Payment Method");
        InsertCodeData(MP16Txt, MP16DescTxt, FatturaCode.Type::"Payment Method");
        InsertCodeData(MP17Txt, MP17DescTxt, FatturaCode.Type::"Payment Method");
        InsertCodeData(MP18Txt, MP18DescTxt, FatturaCode.Type::"Payment Method");
        InsertCodeData(MP19Txt, MP19DescTxt, FatturaCode.Type::"Payment Method");
        InsertCodeData(MP20Txt, MP20DescTxt, FatturaCode.Type::"Payment Method");
        InsertCodeData(MP21Txt, MP21DescTxt, FatturaCode.Type::"Payment Method");
        InsertCodeData(MP22Txt, MP22DescTxt, FatturaCode.Type::"Payment Method");

        // FatturaPA Fiscal Regimes
        CompanyTypes.EnsureStandardFatturaPAFiscalRegimes();
    end;

    var
        TP01Txt: Label 'TP01', Locked = true;
        TP01DescTxt: Label 'Payment by instalments';
        TP02Txt: Label 'TP02', Locked = true;
        TP02DescTxt: Label 'Full payment';
        TP03Txt: Label 'TP03', Locked = true;
        TP03DescTxt: Label 'Advance payment';
        MP01Txt: Label 'MP01', Locked = true;
        MP01DescTxt: Label 'Cash';
        MP02Txt: Label 'MP02', Locked = true;
        MP02DescTxt: Label 'Cheque';
        MP03Txt: Label 'MP03', Locked = true;
        MP03DescTxt: Label 'Banker''s draft';
        MP04Txt: Label 'MP04', Locked = true;
        MP04DescTxt: Label 'Cash at Treasury';
        MP05Txt: Label 'MP05', Locked = true;
        MP05DescTxt: Label 'Bank transfer';
        MP06Txt: Label 'MP06', Locked = true;
        MP06DescTxt: Label 'Money order';
        MP07Txt: Label 'MP07', Locked = true;
        MP07DescTxt: Label 'Pre-compiled bank payment slip';
        MP08Txt: Label 'MP08', Locked = true;
        MP08DescTxt: Label 'Payment card';
        MP09Txt: Label 'MP09', Locked = true;
        MP09DescTxt: Label 'Direct debit';
        MP10Txt: Label 'MP10', Locked = true;
        MP10DescTxt: Label 'Utilities direct debit';
        MP11Txt: Label 'MP11', Locked = true;
        MP11DescTxt: Label 'Fast direct debit';
        MP12Txt: Label 'MP12', Locked = true;
        MP12DescTxt: Label 'Collection order';
        MP13Txt: Label 'MP13', Locked = true;
        MP13DescTxt: Label 'Payment by notice';
        MP14Txt: Label 'MP14', Locked = true;
        MP14DescTxt: Label 'Tax office quittance';
        MP15Txt: Label 'MP15', Locked = true;
        MP15DescTxt: Label 'Transfer on special accounting accounts';
        MP16Txt: Label 'MP16', Locked = true;
        MP16DescTxt: Label 'Order for direct payment from bank account';
        MP17Txt: Label 'MP17', Locked = true;
        MP17DescTxt: Label 'Order for direct payment from post office account';
        MP18Txt: Label 'MP18', Locked = true;
        MP18DescTxt: Label 'Bulletin postal account';
        MP19Txt: Label 'MP19', Locked = true;
        MP19DescTxt: Label 'SEPA Direct Debit';
        MP20Txt: Label 'MP20', Locked = true;
        MP20DescTxt: Label 'SEPA Direct Debit CORE';
        MP21Txt: Label 'MP21', Locked = true;
        MP21DescTxt: Label 'SEPA Direct Debit B2B';
        MP22Txt: Label 'MP22', Locked = true;
        MP22DescTxt: Label 'Withholding of sums already collected';

    procedure InsertCodeData(CodeValue: Code[4]; DescValue: Text[250]; TypeValue: Enum "Fattura Code Type")
    var
        FatturaCode: Record "Fattura Code";
    begin
        FatturaCode.Init();
        FatturaCode.Code := CodeValue;
        FatturaCode.Description := DescValue;
        FatturaCode.Type := TypeValue;
        if FatturaCode.Insert() then;
    end;

}

