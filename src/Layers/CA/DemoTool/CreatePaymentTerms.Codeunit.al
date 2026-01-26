codeunit 101003 "Create Payment Terms"
{

    trigger OnRun()
    begin
        InsertData(XCM, '<CM>', '', 0, XCurrentMonth);
        InsertData(XCOD, '<0D>', '', 0, XCashOnDelivery);
        InsertData(X1M8D, '<1M>', '<8D>', 2, X1Month2PERCENT8days);
        InsertData(X14DAYS, '<14D>', '', 0, XNet14days);
        InsertData(X21DAYS, '<21D>', '', 0, XNet21days);
        InsertData(X7DAYS, '<7D>', '', 0, XNet7days);
        InsertData(X2DAYS, '<2D>', '', 0, XNet2days);
        InsertData(X10DAYS, '<10D>', '', 0, XNet10days);
        InsertData(X15DAYS, '<15D>', '', 0, XNet15days);
        InsertData(X30DAYS, '<30D>', '', 0, XNet30days);
        InsertData(X60DAYS, '<60D>', '', 0, XNet60days);
        InsertTranslations();
    end;

    var
        XCM: Label 'CM';
        XCurrentMonth: Label 'Current Month';
        XCOD: Label 'COD';
        XCashOnDelivery: Label 'Cash on delivery';
        X14DAYS: Label '14 DAYS';
        XNet14days: Label 'Net 14 days';
        X21DAYS: Label '21 DAYS';
        XNet21days: Label 'Net 21 days';
        X7DAYS: Label '7 DAYS';
        XNet7days: Label 'Net 7 days';
        X1Month2PERCENT8days: Label '1 Month/2% 8 days';
        X1M8D: Label '1M(8D)';
        FrenchCanadianLanguageCodeTxt: Label 'FRC', Locked = true;
        EnglishCanadianLanguageCodeTxt: Label 'ENC', Locked = true;
        EnglishUSLanguageCodeTxt: Label 'ENU', Locked = true;
        X60DAYS: Label '60 DAYS';
        XNet60days: Label 'Net 60 days';
        X30DAYS: Label '30 DAYS';
        XNet30days: Label 'Net 30 days';
        X15DAYS: Label '15 DAYS';
        XNet15days: Label 'Net 15 days';
        X10DAYS: Label '10 DAYS';
        XNet10days: Label 'Net 10 days';
        X2DAYS: Label '2 DAYS';
        XNet2days: Label 'Net 2 days';

    procedure InsertData("Code": Code[10]; "Due Date Calculation": Text[30]; "Discount Date Calculation": Text[30]; "Discount %": Decimal; Description: Text[50])
    var
        "Payment Terms": Record "Payment Terms";
    begin
        "Payment Terms".Init();
        "Payment Terms".Validate(Code, Code);

        Evaluate("Payment Terms"."Due Date Calculation", "Due Date Calculation");
        "Payment Terms".Validate("Due Date Calculation");

        Evaluate("Payment Terms"."Discount Date Calculation", "Discount Date Calculation");
        "Payment Terms".Validate("Discount Date Calculation");

        "Payment Terms".Validate("Discount %", "Discount %");
        "Payment Terms".Validate(Description, Description);
        "Payment Terms".Insert();
    end;

    procedure CashOnDeliveryCode(): Code[10]
    begin
        exit(XCOD);
    end;

    procedure OneMonthEightDaysCode(): Code[10]
    begin
        exit(X1M8D);
    end;

    procedure FourteenDaysCode(): Code[10]
    begin
        exit(X14DAYS);
    end;

    local procedure InsertTranslation(PaymentTermsCode: Code[10]; LanguageCode: Code[10]; DescriptionTranslation: Text[50])
    var
        PaymentTermTranslation: Record "Payment Term Translation";
    begin
        PaymentTermTranslation."Payment Term" := PaymentTermsCode;
        PaymentTermTranslation."Language Code" := LanguageCode;
        PaymentTermTranslation.Description := DescriptionTranslation;
        if PaymentTermTranslation.Insert() then;
    end;

    local procedure InsertTranslations()
    begin
        InsertTranslation(XCM, EnglishUSLanguageCodeTxt, XCurrentMonth);
        InsertTranslation(XCM, EnglishCanadianLanguageCodeTxt, XCurrentMonth);
        InsertTranslation(XCM, FrenchCanadianLanguageCodeTxt, 'Mois en cours');

        InsertTranslation(XCOD, EnglishUSLanguageCodeTxt, XCashOnDelivery);
        InsertTranslation(XCOD, EnglishCanadianLanguageCodeTxt, XCashOnDelivery);
        InsertTranslation(XCOD, FrenchCanadianLanguageCodeTxt, 'Paiement … la livraison');

        InsertTranslation(X1M8D, EnglishUSLanguageCodeTxt, X1Month2PERCENT8days);
        InsertTranslation(X1M8D, EnglishCanadianLanguageCodeTxt, X1Month2PERCENT8days);
        InsertTranslation(X1M8D, FrenchCanadianLanguageCodeTxt, '1 Mois/2% 8 jours');

        InsertTranslation(X14DAYS, EnglishUSLanguageCodeTxt, XNet14days);
        InsertTranslation(X14DAYS, EnglishCanadianLanguageCodeTxt, XNet14days);
        InsertTranslation(X14DAYS, FrenchCanadianLanguageCodeTxt, 'Net 14 jours');

        InsertTranslation(X21DAYS, EnglishUSLanguageCodeTxt, XNet21days);
        InsertTranslation(X21DAYS, EnglishCanadianLanguageCodeTxt, XNet21days);
        InsertTranslation(X21DAYS, FrenchCanadianLanguageCodeTxt, 'Net 21 jours');

        InsertTranslation(X7DAYS, EnglishUSLanguageCodeTxt, XNet7days);
        InsertTranslation(X7DAYS, EnglishCanadianLanguageCodeTxt, XNet7days);
        InsertTranslation(X7DAYS, FrenchCanadianLanguageCodeTxt, 'Net 7 jours');

        InsertTranslation(X2DAYS, EnglishUSLanguageCodeTxt, XNet2days);
        InsertTranslation(X2DAYS, EnglishCanadianLanguageCodeTxt, XNet2days);
        InsertTranslation(X2DAYS, FrenchCanadianLanguageCodeTxt, 'Net 2 jours');

        InsertTranslation(X10DAYS, EnglishUSLanguageCodeTxt, XNet10days);
        InsertTranslation(X10DAYS, EnglishCanadianLanguageCodeTxt, XNet10days);
        InsertTranslation(X10DAYS, FrenchCanadianLanguageCodeTxt, 'Net 10 jours');

        InsertTranslation(X15DAYS, EnglishUSLanguageCodeTxt, XNet15days);
        InsertTranslation(X15DAYS, EnglishCanadianLanguageCodeTxt, XNet15days);
        InsertTranslation(X15DAYS, FrenchCanadianLanguageCodeTxt, 'Net 15 jours');

        InsertTranslation(X30DAYS, EnglishUSLanguageCodeTxt, XNet30days);
        InsertTranslation(X30DAYS, EnglishCanadianLanguageCodeTxt, XNet30days);
        InsertTranslation(X30DAYS, FrenchCanadianLanguageCodeTxt, 'Net 30 jours');

        InsertTranslation(X60DAYS, EnglishUSLanguageCodeTxt, XNet60days);
        InsertTranslation(X60DAYS, EnglishCanadianLanguageCodeTxt, XNet60days);
        InsertTranslation(X60DAYS, FrenchCanadianLanguageCodeTxt, 'Net 60 jours');
    end;
}

