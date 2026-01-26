codeunit 161391 "Create FatturaPA Codes"
{

    trigger OnRun()
    var
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

        // Company Types
        InsertCompanyType(CT01Txt, CT01DescTxt);
        InsertCompanyType(CT02Txt, CT02DescTxt);
        InsertCompanyType(CT03Txt, CT03DescTxt);
        InsertCompanyType(CT04Txt, CT04DescTxt);
        InsertCompanyType(CT05Txt, CT05DescTxt);
        InsertCompanyType(CT06Txt, CT06DescTxt);
        InsertCompanyType(CT07Txt, CT07DescTxt);
        InsertCompanyType(CT08Txt, CT08DescTxt);
        InsertCompanyType(CT09Txt, CT09DescTxt);
        InsertCompanyType(CT10Txt, CT10DescTxt);
        InsertCompanyType(CT11Txt, CT11DescTxt);
        InsertCompanyType(CT12Txt, CT12DescTxt);
        InsertCompanyType(CT13Txt, CT13DescTxt);
        InsertCompanyType(CT14Txt, CT14DescTxt);
        InsertCompanyType(CT15Txt, CT15DescTxt);
        InsertCompanyType(CT16Txt, CT16DescTxt);
        InsertCompanyType(CT17Txt, CT17DescTxt);
        InsertCompanyType(CT18Txt, CT18DescTxt);
        InsertCompanyType(CT19Txt, CT19DescTxt);
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
        CT01Txt: Label '01';
        CT01DescTxt: Label 'Ordinary';
        CT02Txt: Label '02';
        CT02DescTxt: Label 'Minimum taxpayers';
        CT03Txt: Label '03';
        CT03DescTxt: Label 'New production initiatives';
        CT04Txt: Label '04';
        CT04DescTxt: Label 'Agriculture and fishing';
        CT05Txt: Label '05';
        CT05DescTxt: Label 'Sale of salts and tobaccos';
        CT06Txt: Label '06';
        CT06DescTxt: Label 'Match sales';
        CT07Txt: Label '07';
        CT07DescTxt: Label 'Publishing';
        CT08Txt: Label '08';
        CT08DescTxt: Label 'Management of phone services';
        CT09Txt: Label '09';
        CT09DescTxt: Label 'Resale of public transport';
        CT10Txt: Label '10';
        CT10DescTxt: Label 'Entertainment and gaming';
        CT11Txt: Label '11';
        CT11DescTxt: Label 'Travel and tourism agencies';
        CT12Txt: Label '12';
        CT12DescTxt: Label 'Farmhouse accommodation';
        CT13Txt: Label '13';
        CT13DescTxt: Label 'Door to door sales';
        CT14Txt: Label '14';
        CT14DescTxt: Label 'Resale of used goods,artworks';
        CT15Txt: Label '15';
        CT15DescTxt: Label 'Artwork and antiques ';
        CT16Txt: Label '16';
        CT16DescTxt: Label 'VAT paid in cash by P.A.';
        CT17Txt: Label '17';
        CT17DescTxt: Label 'VAT paid below Euro 200,000';
        CT18Txt: Label '18';
        CT18DescTxt: Label 'Other';
        CT19Txt: Label '19';
        CT19DescTxt: Label 'Flat rate';

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

    procedure InsertCompanyType(CodeValue: Code[2]; DescValue: Text[250])
    var
        CompanyTypes: Record "Company Types";
    begin
        CompanyTypes.Init();
        CompanyTypes.Code := CodeValue;
        CompanyTypes.Description := CopyStr(DescValue, 1, 30);
        CompanyTypes.Insert();
    end;
}

