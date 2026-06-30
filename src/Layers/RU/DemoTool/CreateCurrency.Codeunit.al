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
        TempCurrencyData: Record "Temporary Currency Data";
        DemoDataSetup: Record "Demo Data Setup";
        Currency: Record Currency;
        CA: Codeunit "Make Adjustments";
        "Create Currency Exchange Rate": Codeunit "Create Currency Exchange Rate";
        Skip: Boolean;
        XEuroTxt: Label 'Euro';
        XAustraliandollarTxt: Label 'Australian dollar';
        XBulgarianlevaTxt: Label 'Bulgarian leva';
        XBruneiDarussalemdollarTxt: Label 'Brunei Darussalem dollar';
        XBrazilianrealTxt: Label 'Brazilian real';
        XCanadiandollarTxt: Label 'Canadian dollar';
        XCroatianKunaTxt: Label 'Croatian Kuna';
        XSwissfrancTxt: Label 'Swiss franc';
        XCzechkorunaTxt: Label 'Czech koruna';
        XDanishkroneTxt: Label 'Danish krone';
        XEstoniankroonTxt: Label 'Estonian kroon';
        XFijidollarTxt: Label 'Fiji dollar';
        XBritishpoundTxt: Label 'Pound Sterling';
        XHongKongdollarTxt: Label 'Hong Kong dollar';
        XIndonesianrupiahTxt: Label 'Indonesian rupiah';
        XJapaneseyenTxt: Label 'Japanese yen';
        XIndianrupeeTxt: Label 'Indian rupee';
        XIcelandickronaTxt: Label 'Icelandic krona';
        XMalaysianringgitTxt: Label 'Malaysian ringgit';
        XMexicanpesoTxt: Label 'Mexican peso';
        XNorwegiankroneTxt: Label 'Norwegian krone';
        XNewZealanddollarTxt: Label 'New Zealand dollar';
        XPhilippinespesoTxt: Label 'Philippines peso';
        XPolishzlotyTxt: Label 'Polish zloty';
        XRussianrubleTxt: Label 'Russian ruble';
        XSwedishkronaTxt: Label 'Swedish krona';
        XSingaporedollarTxt: Label 'Singapore dollar';
        XSloveniantolarTxt: Label 'Slovenian tolar';
        XSaudiArabianryialTxt: Label 'Saudi Arabian ryial';
        XSolomonIslandsdollarTxt: Label 'Solomon Islands dollar';
        XThaibahtTxt: Label 'Thai baht';
        XUSdollarTxt: Label 'US dollar';
        XVanuatuvatuTxt: Label 'Vanuatu vatu';
        XWesternSamoantalaTxt: Label 'Western Samoan tala';
        XSouthAfricanrandTxt: Label 'South African rand';
        XUnitedArabEmiratesdirhamTxt: Label 'United Arab Emirates dirham';
        XAlgeriandinarTxt: Label 'Algerian dinar';
        XHungarianforintTxt: Label 'Hungarian forint';
        XKenyanShillingTxt: Label 'Kenyan Shilling';
        XMoroccandirhamTxt: Label 'Moroccan dirham';
        XMozambiquemeticalTxt: Label 'Mozambique metical';
        XNigeriannairaTxt: Label 'Nigerian naira';
        XRomanianleuTxt: Label 'Romanian leu';
        XSwazilandlilangeniTxt: Label 'Swaziland lilangeni';
        XSlovakKorunaTxt: Label 'Slovak Koruna';
        XSerbianDinarTxt: Label 'Serbian Dinar';
        XTunesiandinarTxt: Label 'Tunesian dinar';
        XUgandanShillingTxt: Label 'Ugandan Shilling';
        XMacedonianDenarTxt: Label 'Macedonian Denar';
        XChineseYuanTxt: Label 'Chinese Yuan';
        XAfghaniTxt: Label 'Afghani';
        XArgentinePesoTxt: Label 'Argentine Peso';
        XArmenianDramTxt: Label 'Armenian Dram';
        XArubanFlorinTxt: Label 'Aruban Florin';
        XAzerbaijanManatTxt: Label 'Azerbaijan Manat';
        XBahamianDollarTxt: Label 'Bahamian Dollar';
        XBahrainiDinarTxt: Label 'Bahraini Dinar';
        XBalboaTxt: Label 'Balboa';
        XBarbadosDollarTxt: Label 'Barbados Dollar';
        XBelarusianRubleTxt: Label 'Belarusian Ruble';
        XBelizeDollarTxt: Label 'Belize Dollar';
        XBermudianDollarTxt: Label 'Bermudian Dollar';
        XBolivarSoberanoTxt: Label 'Bolivar Soberano';
        XBolivianoTxt: Label 'Boliviano';
        XBurundiFrancTxt: Label 'Burundi Franc';
        XCaboVerdeEscudoTxt: Label 'Cabo Verde Escudo';
        XCaribbeanGuilderTxt: Label 'Caribbean Guilder';
        XCaymanIslandsDollarTxt: Label 'Cayman Islands Dollar';
        XCfaFrancBceaoTxt: Label 'Cfa Franc Bceao';
        XChileanPesoTxt: Label 'Chilean Peso';
        XColombianPesoTxt: Label 'Colombian Peso';
        XComorianFrancTxt: Label 'Comorian Franc';
        XCongoleseFrancTxt: Label 'Congolese Franc';
        XConvertibleMarkTxt: Label 'Convertible Mark';
        XCordobaOroTxt: Label 'Cordoba Oro';
        XCostaRicanColonTxt: Label 'Costa Rican Colon';
        XCubanPesoTxt: Label 'Cuban Peso';
        XDalasiTxt: Label 'Dalasi';
        XDjiboutiFrancTxt: Label 'Djibouti Franc';
        XDobraTxt: Label 'Dobra';
        XDominicanPesoTxt: Label 'Dominican Peso';
        XDongTxt: Label 'Dong';
        XEastCaribbeanDollarTxt: Label 'East Caribbean Dollar';
        XEgyptianPoundTxt: Label 'Egyptian Pound';
        XElSalvadorColonTxt: Label 'El Salvador Colon';
        XEthiopianBirrTxt: Label 'Ethiopian Birr';
        XFalklandIslandsPoundTxt: Label 'Falkland Islands Pound';
        XGhanaCediTxt: Label 'Ghana Cedi';
        XGibraltarPoundTxt: Label 'Gibraltar Pound';
        XGourdeTxt: Label 'Gourde';
        XGuaraniTxt: Label 'Guarani';
        XGuineanFrancTxt: Label 'Guinean Franc';
        XGuyanaDollarTxt: Label 'Guyana Dollar';
        XHryvniaTxt: Label 'Hryvnia';
        XIranianRialTxt: Label 'Iranian Rial';
        XIraqiDinarTxt: Label 'Iraqi Dinar';
        XJamaicanDollarTxt: Label 'Jamaican Dollar';
        XJordanianDinarTxt: Label 'Jordanian Dinar';
        XKinaTxt: Label 'Kina';
        XKuwaitiDinarTxt: Label 'Kuwaiti Dinar';
        XKwanzaTxt: Label 'Kwanza';
        XKyatTxt: Label 'Kyat';
        XLaoKipTxt: Label 'Lao Kip';
        XLariTxt: Label 'Lari';
        XLebanesePoundTxt: Label 'Lebanese Pound';
        XLekTxt: Label 'Lek';
        XLempiraTxt: Label 'Lempira';
        XLeoneTxt: Label 'Leone';
        XLiberianDollarTxt: Label 'Liberian Dollar';
        XLibyanDinarTxt: Label 'Libyan Dinar';
        XLotiTxt: Label 'Loti';
        XMalagasyAriaryTxt: Label 'Malagasy Ariary';
        XMalawiKwachaTxt: Label 'Malawi Kwacha';
        XMauritiusRupeeTxt: Label 'Mauritius Rupee';
        XMoldovanLeuTxt: Label 'Moldovan Leu';
        XMvdolTxt: Label 'Mvdol';
        XNakfaTxt: Label 'Nakfa';
        XNamibiaDollarTxt: Label 'Namibia Dollar';
        XNepaleseRupeeTxt: Label 'Nepalese Rupee';
        XNewIsraeliSheqelTxt: Label 'New Israeli Sheqel';
        XNewTaiwanDollarTxt: Label 'New Taiwan Dollar';
        XNgultrumTxt: Label 'Ngultrum';
        XNorthKoreanWonTxt: Label 'North Korean Won';
        XOuguiyaTxt: Label 'Ouguiya';
        XPakistanRupeeTxt: Label 'Pakistan Rupee';
        XPatacaTxt: Label 'Pataca';
        XPesoUruguayoTxt: Label 'Peso Uruguayo';
        XPlatinumTxt: Label 'Platinum';
        XPulaTxt: Label 'Pula';
        XQatariRialTxt: Label 'Qatari Rial';
        XQuetzalTxt: Label 'Quetzal';
        XRialOmaniTxt: Label 'Rial Omani';
        XRielTxt: Label 'Riel';
        XRufiyaaTxt: Label 'Rufiyaa';
        XRwandaFrancTxt: Label 'Rwanda Franc';
        XSaintHelenaPoundTxt: Label 'Saint Helena Pound';
        XSeychellesRupeeTxt: Label 'Seychelles Rupee';
        XSolTxt: Label 'Sol';
        XSomTxt: Label 'Som';
        XSomaliShillingTxt: Label 'Somali Shilling';
        XSomoniTxt: Label 'Somoni';
        XSouthSudanesePoundTxt: Label 'South Sudanese Pound';
        XSriLankaRupeeTxt: Label 'Sri Lanka Rupee';
        XSudanesePoundTxt: Label 'Sudanese Pound';
        XSurinamDollarTxt: Label 'Surinam Dollar';
        XSyrianPoundTxt: Label 'Syrian Pound';
        XTakaTxt: Label 'Taka';
        XTanzanianShillingTxt: Label 'Tanzanian Shilling';
        XTengeTxt: Label 'Tenge';
        XTrinidadAndTobagoDollarTxt: Label 'Trinidad And Tobago Dollar';
        XTugrikTxt: Label 'Tugrik';
        XTurkmenistanNewManatTxt: Label 'Turkmenistan New Manat';
        XUnidadDeFomentoTxt: Label 'Unidad De Fomento';
        XUnidadDeValorRealTxt: Label 'Unidad De Valor Real';
        XUnidadPrevisionalTxt: Label 'Unidad Previsional';
        XUzbekistanSumTxt: Label 'Uzbekistan Sum';
        XWonTxt: Label 'Won';
        XYemeniRialTxt: Label 'Yemeni Rial';
        XZambianKwachaTxt: Label 'Zambian Kwacha';
        XZimbabweGoldTxt: Label 'Zimbabwe Gold';
        NoCurrencyFoundErr: Label 'No currency was found, can not continue.';
        XNewTurkishliraTxt: Label 'New Turkish lira';
        XTonganPaangaTxt: Label 'Tongan Pa anga';
        XFrenchPacificFrancTxt: Label 'French Pacific Franc';
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
            Currency."Unit Name 1" := XEuroTxt;
            Currency."Unit Name 2" := XEuroTxt;
            Currency."Unit Name 5" := XEuroTxt;
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
                exit(XUnitedArabEmiratesdirhamTxt);
            'AUD':
                exit(XAustraliandollarTxt);
            'BGN':
                exit(XBulgarianlevaTxt);
            'BND':
                exit(XBruneiDarussalemdollarTxt);
            'BRL':
                exit(XBrazilianrealTxt);
            'CAD':
                exit(XCanadiandollarTxt);
            'CHF':
                exit(XSwissfrancTxt);
            'CNY':
                exit(XChineseYuanTxt);
            'CZK':
                exit(XCzechkorunaTxt);
            'DKK':
                exit(XDanishkroneTxt);
            'DZD':
                exit(XAlgeriandinarTxt);
            'EEK':
                exit(XEstoniankroonTxt);
            'EUR':
                exit(XEuroTxt);
            'FJD':
                exit(XFijidollarTxt);
            'GBP':
                exit(XBritishpoundTxt);
            'HKD':
                exit(XHongKongdollarTxt);
            'HRK':
                exit(XCroatianKunaTxt);
            'HUF':
                exit(XHungarianforintTxt);
            'IDR':
                exit(XIndonesianrupiahTxt);
            'INR':
                exit(XIndianrupeeTxt);
            'ISK':
                exit(XIcelandickronaTxt);
            'JPY':
                exit(XJapaneseyenTxt);
            'KES':
                exit(XKenyanShillingTxt);
            'MAD':
                exit(XMoroccandirhamTxt);
            'MKD':
                exit(XMacedonianDenarTxt);
            'MXN':
                exit(XMexicanpesoTxt);
            'MYR':
                exit(XMalaysianringgitTxt);
            'MZN':
                exit(XMozambiquemeticalTxt);
            'NGN':
                exit(XNigeriannairaTxt);
            'NOK':
                exit(XNorwegiankroneTxt);
            'NZD':
                exit(XNewZealanddollarTxt);
            'PHP':
                exit(XPhilippinespesoTxt);
            'PLN':
                exit(XPolishzlotyTxt);
            'RON':
                exit(XRomanianleuTxt);
            'RSD':
                exit(XSerbianDinarTxt);
            'RUB':
                exit(XRussianrubleTxt);
            'SAR':
                exit(XSaudiArabianryialTxt);
            'SBD':
                exit(XSolomonIslandsdollarTxt);
            'SEK':
                exit(XSwedishkronaTxt);
            'SGD':
                exit(XSingaporedollarTxt);
            'SIT':
                exit(XSloveniantolarTxt);
            'SKK':
                exit(XSlovakKorunaTxt);
            'SZL':
                exit(XSwazilandlilangeniTxt);
            'THB':
                exit(XThaibahtTxt);
            'TND':
                exit(XTunesiandinarTxt);
            'TOP':
                exit(XTonganPaangaTxt);
            'TRY':
                exit(XNewTurkishliraTxt);
            'UGX':
                exit(XUgandanShillingTxt);
            'USD':
                exit(XUSdollarTxt);
            'VUV':
                exit(XVanuatuvatuTxt);
            'WST':
                exit(XWesternSamoantalaTxt);
            'XPF':
                exit(XFrenchPacificFrancTxt);
            'ZAR':
                exit(XSouthAfricanrandTxt);
            'AFN':
                exit(XAfghaniTxt);
            'ALL':
                exit(XLekTxt);
            'AMD':
                exit(XArmenianDramTxt);
            'AOA':
                exit(XKwanzaTxt);
            'ARS':
                exit(XArgentinePesoTxt);
            'AWG':
                exit(XArubanFlorinTxt);
            'AZN':
                exit(XAzerbaijanManatTxt);
            'BAM':
                exit(XConvertibleMarkTxt);
            'BBD':
                exit(XBarbadosDollarTxt);
            'BDT':
                exit(XTakaTxt);
            'BHD':
                exit(XBahrainiDinarTxt);
            'BIF':
                exit(XBurundiFrancTxt);
            'BMD':
                exit(XBermudianDollarTxt);
            'BOB':
                exit(XBolivianoTxt);
            'BOV':
                exit(XMvdolTxt);
            'BSD':
                exit(XBahamianDollarTxt);
            'BTN':
                exit(XNgultrumTxt);
            'BWP':
                exit(XPulaTxt);
            'BYN':
                exit(XBelarusianRubleTxt);
            'BZD':
                exit(XBelizeDollarTxt);
            'CDF':
                exit(XCongoleseFrancTxt);
            'CLF':
                exit(XUnidadDeFomentoTxt);
            'CLP':
                exit(XChileanPesoTxt);
            'COP':
                exit(XColombianPesoTxt);
            'COU':
                exit(XUnidadDeValorRealTxt);
            'CRC':
                exit(XCostaRicanColonTxt);
            'CUP':
                exit(XCubanPesoTxt);
            'CVE':
                exit(XCaboVerdeEscudoTxt);
            'DJF':
                exit(XDjiboutiFrancTxt);
            'DOP':
                exit(XDominicanPesoTxt);
            'EGP':
                exit(XEgyptianPoundTxt);
            'ERN':
                exit(XNakfaTxt);
            'ETB':
                exit(XEthiopianBirrTxt);
            'FKP':
                exit(XFalklandIslandsPoundTxt);
            'GEL':
                exit(XLariTxt);
            'GHS':
                exit(XGhanaCediTxt);
            'GIP':
                exit(XGibraltarPoundTxt);
            'GMD':
                exit(XDalasiTxt);
            'GNF':
                exit(XGuineanFrancTxt);
            'GTQ':
                exit(XQuetzalTxt);
            'GYD':
                exit(XGuyanaDollarTxt);
            'HNL':
                exit(XLempiraTxt);
            'HTG':
                exit(XGourdeTxt);
            'ILS':
                exit(XNewIsraeliSheqelTxt);
            'IQD':
                exit(XIraqiDinarTxt);
            'IRR':
                exit(XIranianRialTxt);
            'JMD':
                exit(XJamaicanDollarTxt);
            'JOD':
                exit(XJordanianDinarTxt);
            'KGS':
                exit(XSomTxt);
            'KHR':
                exit(XRielTxt);
            'KMF':
                exit(XComorianFrancTxt);
            'KPW':
                exit(XNorthKoreanWonTxt);
            'KRW':
                exit(XWonTxt);
            'KWD':
                exit(XKuwaitiDinarTxt);
            'KYD':
                exit(XCaymanIslandsDollarTxt);
            'KZT':
                exit(XTengeTxt);
            'LAK':
                exit(XLaoKipTxt);
            'LBP':
                exit(XLebanesePoundTxt);
            'LKR':
                exit(XSriLankaRupeeTxt);
            'LRD':
                exit(XLiberianDollarTxt);
            'LSL':
                exit(XLotiTxt);
            'LYD':
                exit(XLibyanDinarTxt);
            'MDL':
                exit(XMoldovanLeuTxt);
            'MGA':
                exit(XMalagasyAriaryTxt);
            'MMK':
                exit(XKyatTxt);
            'MNT':
                exit(XTugrikTxt);
            'MOP':
                exit(XPatacaTxt);
            'MRU':
                exit(XOuguiyaTxt);
            'MUR':
                exit(XMauritiusRupeeTxt);
            'MVR':
                exit(XRufiyaaTxt);
            'MWK':
                exit(XMalawiKwachaTxt);
            'NAD':
                exit(XNamibiaDollarTxt);
            'NIO':
                exit(XCordobaOroTxt);
            'NPR':
                exit(XNepaleseRupeeTxt);
            'OMR':
                exit(XRialOmaniTxt);
            'PAB':
                exit(XBalboaTxt);
            'PEN':
                exit(XSolTxt);
            'PGK':
                exit(XKinaTxt);
            'PKR':
                exit(XPakistanRupeeTxt);
            'PYG':
                exit(XGuaraniTxt);
            'QAR':
                exit(XQatariRialTxt);
            'RWF':
                exit(XRwandaFrancTxt);
            'SCR':
                exit(XSeychellesRupeeTxt);
            'SDG':
                exit(XSudanesePoundTxt);
            'SHP':
                exit(XSaintHelenaPoundTxt);
            'SLE':
                exit(XLeoneTxt);
            'SOS':
                exit(XSomaliShillingTxt);
            'SRD':
                exit(XSurinamDollarTxt);
            'SSP':
                exit(XSouthSudanesePoundTxt);
            'STN':
                exit(XDobraTxt);
            'SVC':
                exit(XElSalvadorColonTxt);
            'SYP':
                exit(XSyrianPoundTxt);
            'TJS':
                exit(XSomoniTxt);
            'TMT':
                exit(XTurkmenistanNewManatTxt);
            'TTD':
                exit(XTrinidadAndTobagoDollarTxt);
            'TWD':
                exit(XNewTaiwanDollarTxt);
            'TZS':
                exit(XTanzanianShillingTxt);
            'UAH':
                exit(XHryvniaTxt);
            'UYU':
                exit(XPesoUruguayoTxt);
            'UYW':
                exit(XUnidadPrevisionalTxt);
            'UZS':
                exit(XUzbekistanSumTxt);
            'VED':
                exit(XBolivarSoberanoTxt);
            'VES':
                exit(XBolivarSoberanoTxt);
            'VND':
                exit(XDongTxt);
            'XCD':
                exit(XEastCaribbeanDollarTxt);
            'XCG':
                exit(XCaribbeanGuilderTxt);
            'XOF':
                exit(XCfaFrancBceaoTxt);
            'XPT':
                exit(XPlatinumTxt);
            'YER':
                exit(XYemeniRialTxt);
            'ZMW':
                exit(XZambianKwachaTxt);
            'ZWG':
                exit(XZimbabweGoldTxt);
            '':
                exit('');
            else
                exit(CurrencyCode);
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


