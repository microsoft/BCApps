codeunit 101004 "Create Currency"
{
    // // To change or update exchange rates, please change the values in the CurrencyData.txt file
    // //in the pictures folder.

    TableNo = "Temporary Currency Data";

    trigger OnRun()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        InterfaceBasisData: Codeunit "Interface Basis Data";
    begin
        DemoDataSetup.Get();
        Reset();
        if FindSet() then
            repeat
                InsertData(Rec);
                InsertExchRateData(Rec);
            until Next() = 0
        else
            Error(NoCurrencyFoundErr);

        CurrencyExchangeRate.SetFilter("Currency Code", 'USD|EUR|CAD|GBP|CHF|DKK|SEK|NOK');
        CurrencyExchangeRate.DeleteAll();
        Commit();
        InterfaceBasisData.ImportDataByXMLPort(XMLPORT::"Currency Exchange Rates", 'RUS_ExchRates.xml');

        if not Skip then begin
            DemoDataSetup.TestField("Currency Code");
            TempCurrencyData.Get(DemoDataSetup."Currency Code");
            DemoDataSetup.Validate("Local Precision Factor", TempCurrencyData."Local Precision Factor");
            DemoDataSetup."Local Currency Factor" :=
              Round(TempCurrencyData."Exchange Rate Amount" / TempCurrencyData."Relational Exch. Rate Amount", 0.0001);
            DemoDataSetup.Modify();

            SetLCYinGLSetup(DemoDataSetup."Currency Code");
        end;
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Currency: Record Currency;
        CA: Codeunit "Make Adjustments";
        "Create Currency Exchange Rate": Codeunit "Create Currency Exchange Rate";
        Skip: Boolean;
        XEuro: Label 'Euro';
        XAustraliandollar: Label 'Australian dollar';
        XBulgarianleva: Label 'Bulgarian leva';
        XBruneiDarussalemdollar: Label 'Brunei Darussalem dollar';
        XBrazilianreal: Label 'Brazilian real';
        XCanadiandollar: Label 'Canadian dollar';
        XCroatianKuna: Label 'Croatian Kuna';
        XSwissfranc: Label 'Swiss franc';
        XCzechkoruna: Label 'Czech koruna';
        XDanishkrone: Label 'Danish krone';
        XEstoniankroon: Label 'Estonian kroon';
        XFijidollar: Label 'Fiji dollar';
        XBritishpound: Label 'Pound Sterling';
        XHongKongdollar: Label 'Hong Kong dollar';
        XIndonesianrupiah: Label 'Indonesian rupiah';
        XJapaneseyen: Label 'Japanese yen';
        XIndianrupee: Label 'Indian rupee';
        XIcelandickrona: Label 'Icelandic krona';
        XMalaysianringgit: Label 'Malaysian ringgit';
        XMexicanpeso: Label 'Mexican peso';
        XNorwegiankrone: Label 'Norwegian krone';
        XNewZealanddollar: Label 'New Zealand dollar';
        XPhilippinespeso: Label 'Philippines peso';
        XPolishzloty: Label 'Polish zloty';
        XRussianruble: Label 'Russian ruble';
        XSwedishkrona: Label 'Swedish krona';
        XSingaporedollar: Label 'Singapore dollar';
        XSloveniantolar: Label 'Slovenian tolar';
        XSaudiArabianryial: Label 'Saudi Arabian ryial';
        XSolomonIslandsdollar: Label 'Solomon Islands dollar';
        XThaibaht: Label 'Thai baht';
        XUSdollar: Label 'US dollar';
        XVanuatuvatu: Label 'Vanuatu vatu';
        XWesternSamoantala: Label 'Western Samoan tala';
        XSouthAfricanrand: Label 'South African rand';
        XUnitedArabEmiratesdirham: Label 'United Arab Emirates dirham';
        XAlgeriandinar: Label 'Algerian dinar';
        XHungarianforint: Label 'Hungarian forint';
        XKenyanShilling: Label 'Kenyan Shilling';
        XMoroccandirham: Label 'Moroccan dirham';
        XMozambiquemetical: Label 'Mozambique metical';
        XNigeriannaira: Label 'Nigerian naira';
        XRomanianleu: Label 'Romanian leu';
        XSwazilandlilangeni: Label 'Swaziland lilangeni';
        XSlovakKoruna: Label 'Slovak Koruna';
        XSerbianDinar: Label 'Serbian Dinar';
        XTunesiandinar: Label 'Tunesian dinar';
        XUgandanShilling: Label 'Ugandan Shilling';
        XMacedonianDenarTxt: Label 'Macedonian Denar';
        XChineseYuanTxt: Label 'Chinese Yuan';
        TempCurrencyData: Record "Temporary Currency Data";
        NoCurrencyFoundErr: Label 'No currency was found, can not continue.';
        XNewTurkishlira: Label 'New Turkish lira';
        CountryCodeDoesNotExistErr: Label 'Currency code does not exist, can not continue.';
        XTonganPaanga: Label 'Tongan Pa anga';
        XFrenchPacificFranc: Label 'French Pacific Franc';
        XBUSINESS: Label 'BUSINESS';
        XEurocent1: Label 'eurocent';
        XEurocent2: Label 'eurocents';
        XEurocent5: Label 'eurocents';
        XDollar1: Label 'dollar';
        XDollar2: Label 'dollars';
        XDollar5: Label 'dollars';
        XCent1: Label 'cent';
        XCent2: Label 'cents';
        XCent5: Label 'cents';

    procedure InsertData(CurrencyData: Record "Temporary Currency Data")
    begin
        Currency.Init();
        Currency.Validate(Code, CurrencyData."Currency Code");
        Currency.Validate("ISO Code", CopyStr(Currency.Code, 1, 3));
        Currency.Validate("ISO Numeric Code", CurrencyData."ISO Numeric Code");
        Currency.Validate(Description, GetCurrencyDescription(CurrencyData."Currency Code"));
        Currency.Validate("Amount Rounding Precision", CurrencyData."Amount Rounding Precision");
        Currency.Validate("Unit-Amount Rounding Precision", CurrencyData."Unit-Amount Rounding Precision");
        Currency.Validate("Invoice Rounding Precision", CurrencyData."Invoice Rounding Precision");
        Currency.Validate("Invoice Rounding Type", CurrencyData."Invoice Rounding Type");
        Currency.Validate("EMU Currency", CurrencyData."EMU Currency");
        Currency.Validate("Amount Decimal Places", CurrencyData."Amount Decimal Places");
        Currency.Validate("Unit-Amount Decimal Places", CurrencyData."Unit-Amount Decimal Places");
        Currency.Validate(Symbol, Currency.ResolveCurrencySymbol(Currency.Code));
        Currency.Validate("RU Bank Code", Currency.Code);
        Currency.Insert(true);
    end;

    procedure InsertExchRateData(TemporaryCurrencyData: Record "Temporary Currency Data")
    var
        Rate: array[2] of Decimal;
    begin
        if Skip then
            exit;

        "Create Currency Exchange Rate".InsertData(
            TemporaryCurrencyData."Currency Code", CalcDate('<CY-2Y+1D>', WorkDate()), TemporaryCurrencyData."Exchange Rate Amount", TemporaryCurrencyData."Exchange Rate Amount",
            '', TemporaryCurrencyData."Relational Exch. Rate Amount", 0, TemporaryCurrencyData."Relational Exch. Rate Amount");

        if DemoDataSetup."Data Type" <> DemoDataSetup."Data Type"::Extended then
            if TemporaryCurrencyData."Currency Code" in ['EUR', 'GBP', 'SEK', 'USD'] then begin
                case TemporaryCurrencyData."Currency Code" of
                    'USD':
                        begin
                            Rate[1] := 562.52;
                            Rate[2] := 580.59;
                        end;
                    'SEK':
                        begin
                            Rate[1] := 87.05;
                            Rate[2] := 89.7;
                        end;
                    'GBP':
                        begin
                            Rate[1] := 916.49;
                            Rate[2] := 880.25;
                        end;
                    'EUR':
                        begin
                            Rate[1] := 746.02;
                            Rate[2] := 745.48;
                        end;
                end;
                "Create Currency Exchange Rate".InsertData(
                  TemporaryCurrencyData."Currency Code", DMY2Date(2, 1, 2013), 100, 100, '', Rate[1], 0, Rate[1]);
                "Create Currency Exchange Rate".InsertData(
                  TemporaryCurrencyData."Currency Code", DMY2Date(2, 4, 2013), 100, 100, '', Rate[2], 0, Rate[2]);
            end;
    end;

    procedure ModifyData()
    begin
        DemoDataSetup.Get();
        Currency.Reset();
        if Currency.Find('-') then
            repeat
                if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then begin
                    Currency.Validate("Unrealized Gains Acc.", CA.Convert('91-1310'));
                    Currency.Validate("Unrealized Losses Acc.", CA.Convert('91-2310'));
                    Currency.Validate("Realized Gains Acc.", CA.Convert('91-1310'));
                    Currency.Validate("Realized Losses Acc.", CA.Convert('91-2310'));
                    if DemoDataSetup."Additional Currency Code" = Currency.Code then begin
                        Currency.Validate("Realized G/L Gains Account", CA.Convert('91-2330'));
                        Currency.Validate("Realized G/L Losses Account", CA.Convert('91-2340'));
                        Currency.Validate("Residual Gains Account", CA.Convert('91-2330'));
                        Currency.Validate("Residual Losses Account", CA.Convert('91-2340'));
                        Currency.Validate("Sales PD Gains Acc. (TA)", CA.Convert('99-5010'));
                        Currency.Validate("Sales PD Losses Acc. (TA)", CA.Convert('99-5030'));
                        Currency.Validate("Purch. PD Gains Acc. (TA)", CA.Convert('99-5020'));
                        Currency.Validate("Purch. PD Losses Acc. (TA)", CA.Convert('99-5040'));
                        Currency.Validate("PD Bal. Gain/Loss Acc. (TA)", CA.Convert('99-5090'));
                    end;
                end else begin
                    Currency.Validate("Realized Gains Acc.", CA.Convert('40500'));
                    Currency.Validate("Realized Losses Acc.", CA.Convert('40500'));
                end;
                Currency.Modify();
            until Currency.Next() = 0;

        if Currency.Get('EUR') then begin
            Currency."Unit Kind" := Currency."Unit Kind"::Neuter;
            Currency."Unit Name 1" := XEuro;
            Currency."Unit Name 2" := XEuro;
            Currency."Unit Name 5" := XEuro;
            Currency."Hundred Kind" := Currency."Hundred Kind"::Male;
            Currency."Hundred Name 1" := XEurocent1;
            Currency."Hundred Name 2" := XEurocent2;
            Currency."Hundred Name 5" := XEurocent5;
            Currency.Modify();
        end;

        if Currency.Get('USD') then begin
            Currency."Unit Kind" := Currency."Unit Kind"::Male;
            Currency."Unit Name 1" := XDollar1;
            Currency."Unit Name 2" := XDollar2;
            Currency."Unit Name 5" := XDollar5;
            Currency."Hundred Kind" := Currency."Hundred Kind"::Male;
            Currency."Hundred Name 1" := XCent1;
            Currency."Hundred Name 2" := XCent2;
            Currency."Hundred Name 5" := XCent5;
            Currency.Modify();
        end;
    end;

    procedure SkipDemoDataSetup(NewSkip: Boolean)
    begin
        Skip := NewSkip;
    end;

    procedure GetCustBusPostingGroup(): Code[20]
    begin
        exit(XBUSINESS);
    end;

    procedure GetVendBusPostingGroup(): Code[20]
    begin
        exit(XBUSINESS);
    end;

    procedure GetCustPostingGroup("Country Code": Code[10]): Code[10]
    begin
        DemoDataSetup.Get();
        case "Country Code" of
            '', DemoDataSetup."Country/Region Code":
                exit('62-1010');
            else
                exit('62-1110');
        end;
    end;

    procedure GetVendPostingGroup("Country Code": Code[10]): Code[10]
    begin
        DemoDataSetup.Get();
        case "Country Code" of
            '', DemoDataSetup."Country/Region Code":
                exit('60-1010');
            else
                exit('60-1110');
        end;
    end;

    procedure GetCurrencyDescription(CurrencyCode: Code[10]): Text[30]
    begin
        DemoDataSetup.Get();
        case CurrencyCode of
            'AED':
                exit(XUnitedArabEmiratesdirham);
            'AUD':
                exit(XAustraliandollar);
            'BGN':
                exit(XBulgarianleva);
            'BND':
                exit(XBruneiDarussalemdollar);
            'BRL':
                exit(XBrazilianreal);
            'CAD':
                exit(XCanadiandollar);
            'CHF':
                exit(XSwissfranc);
            'CNY':
                exit(XChineseYuanTxt);
            'CZK':
                exit(XCzechkoruna);
            'DKK':
                exit(XDanishkrone);
            'DZD':
                exit(XAlgeriandinar);
            'EEK':
                exit(XEstoniankroon);
            'EUR':
                exit(XEuro);
            'FJD':
                exit(XFijidollar);
            'GBP':
                exit(XBritishpound);
            'HKD':
                exit(XHongKongdollar);
            'HRK':
                exit(XCroatianKuna);
            'HUF':
                exit(XHungarianforint);
            'IDR':
                exit(XIndonesianrupiah);
            'INR':
                exit(XIndianrupee);
            'ISK':
                exit(XIcelandickrona);
            'JPY':
                exit(XJapaneseyen);
            'KES':
                exit(XKenyanShilling);
            'MAD':
                exit(XMoroccandirham);
            'MKD':
                exit(XMacedonianDenarTxt);
            'MXN':
                exit(XMexicanpeso);
            'MYR':
                exit(XMalaysianringgit);
            'MZN':
                exit(XMozambiquemetical);
            'NGN':
                exit(XNigeriannaira);
            'NOK':
                exit(XNorwegiankrone);
            'NZD':
                exit(XNewZealanddollar);
            'PHP':
                exit(XPhilippinespeso);
            'PLN':
                exit(XPolishzloty);
            'RON':
                exit(XRomanianleu);
            'RSD':
                exit(XSerbianDinar);
            'RUB':
                exit(XRussianruble);
            'SAR':
                exit(XSaudiArabianryial);
            'SBD':
                exit(XSolomonIslandsdollar);
            'SEK':
                exit(XSwedishkrona);
            'SGD':
                exit(XSingaporedollar);
            'SIT':
                exit(XSloveniantolar);
            'SKK':
                exit(XSlovakKoruna);
            'SZL':
                exit(XSwazilandlilangeni);
            'THB':
                exit(XThaibaht);
            'TND':
                exit(XTunesiandinar);
            'TOP':
                exit(XTonganPaanga);
            'TRY':
                exit(XNewTurkishlira);
            'UGX':
                exit(XUgandanShilling);
            'USD':
                exit(XUSdollar);
            'VUV':
                exit(XVanuatuvatu);
            'WST':
                exit(XWesternSamoantala);
            'XPF':
                exit(XFrenchPacificFranc);
            'ZAR':
                exit(XSouthAfricanrand);
            '':
                exit('');
            else
                Error(CountryCodeDoesNotExistErr);
        end;
    end;

    local procedure SetLCYinGLSetup(LCYCurrencyCode: Code[10])
    var
        GLSetup: Record "General Ledger Setup";
    begin
        Currency.Get(LCYCurrencyCode);
        GLSetup.Get();
        GLSetup."LCY Code" := '';   // to avoid error on updating LCY Code
        GLSetup.Validate("LCY Code", Currency.Code);
        GLSetup.Validate("Local Currency Description", GetCurrencyDescription(LCYCurrencyCode));
        GLSetup."Inv. Rounding Precision (LCY)" := Currency."Invoice Rounding Precision";
        GLSetup."Amount Rounding Precision" := Currency."Amount Rounding Precision";
        GLSetup."Unit-Amount Rounding Precision" := Currency."Unit-Amount Rounding Precision";
        GLSetup.Modify();
    end;
}

