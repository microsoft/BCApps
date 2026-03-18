codeunit 101328 "Create Curr for Fin Chrg Terms"
{

    trigger OnRun()
    begin
        InsertData(X2POINT0For, XDKK, 50);
        InsertData(X2POINT0For, XEUR, 4.5);
        InsertData(X2POINT0For, XUSD, 10);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        X2POINT0For: Label '2.0 For.';
        XDKK: Label 'DKK';
        XEUR: Label 'EUR';
        XUSD: Label 'USD';

    procedure InsertData(FinChargeTermsCode: Code[10]; CurrencyCode: Code[5]; AdditionalFee: Decimal)
    var
        CurrencyForFinChrgTerms: Record "Currency for Fin. Charge Terms";
    begin
        DemoDataSetup.Get();
        if CurrencyCode = DemoDataSetup."Currency Code" then
            exit;
        CurrencyForFinChrgTerms.Init();
        CurrencyForFinChrgTerms.Validate("Fin. Charge Terms Code", FinChargeTermsCode);
        CurrencyForFinChrgTerms.Validate("Currency Code", CurrencyCode);
        CurrencyForFinChrgTerms.Validate("Additional Fee", AdditionalFee);
        CurrencyForFinChrgTerms.Insert();
    end;
}

