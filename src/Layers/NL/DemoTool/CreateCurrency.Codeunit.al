codeunit 101004 "Create Currency"
{
    // // To change or update exchange rates, please change the values in the CurrencyData.txt file
    // //in the pictures folder.

    TableNo = "Temporary Currency Data";

    trigger OnRun()
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

        if not Skip then begin
            DemoDataSetup.TestField("Currency Code");
            TempCurrencyData.Get(DemoDataSetup."Currency Code");
            DemoDataSetup.Validate("Local Precision Factor", TempCurrencyData."Local Precision Factor");
            DemoDataSetup."Local Currency Factor" :=
              Round(TempCurrencyData."Exchange Rate Amount" / TempCurrencyData."Relational Exch. Rate Amount", 0.0001);
            DemoDataSetup.Modify();

            "Create Currency Exchange Rate".LocalizeExchangeRates();

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
        XEuroTxt: Label 'Euro', MaxLength = 30;
        XAustraliandollarTxt: Label 'Australian dollar', MaxLength = 30;
        XBulgarianlevaTxt: Label 'Bulgarian leva', MaxLength = 30;
        XBruneiDarussalemdollarTxt: Label 'Brunei Darussalam dollar', MaxLength = 30;
        XBrazilianrealTxt: Label 'Brazilian real', MaxLength = 30;
        XCanadiandollarTxt: Label 'Canadian dollar', MaxLength = 30;
        XCroatianKunaTxt: Label 'Croatian Kuna', MaxLength = 30;
        XSwissfrancTxt: Label 'Swiss franc', MaxLength = 30;
        XCzechkorunaTxt: Label 'Czech koruna', MaxLength = 30;
        XDanishkroneTxt: Label 'Danish krone', MaxLength = 30;
        XEstoniankroonTxt: Label 'Estonian kroon', MaxLength = 30;
        XFijidollarTxt: Label 'Fiji dollar', MaxLength = 30;
        XBritishpoundTxt: Label 'Pound Sterling', MaxLength = 30;
        XHongKongdollarTxt: Label 'Hong Kong dollar', MaxLength = 30;
        XIndonesianrupiahTxt: Label 'Indonesian rupiah', MaxLength = 30;
        XJapaneseyenTxt: Label 'Japanese yen', MaxLength = 30;
        XIndianrupeeTxt: Label 'Indian rupee', MaxLength = 30;
        XIcelandickronaTxt: Label 'Icelandic krona', MaxLength = 30;
        XMalaysianringgitTxt: Label 'Malaysian ringgit', MaxLength = 30;
        XMexicanpesoTxt: Label 'Mexican peso', MaxLength = 30;
        XNorwegiankroneTxt: Label 'Norwegian krone', MaxLength = 30;
        XNewZealanddollarTxt: Label 'New Zealand dollar', MaxLength = 30;
        XPhilippinespesoTxt: Label 'Philippines peso', MaxLength = 30;
        XPolishzlotyTxt: Label 'Polish zloty', MaxLength = 30;
        XRussianrubleTxt: Label 'Russian ruble', MaxLength = 30;
        XSwedishkronaTxt: Label 'Swedish krona', MaxLength = 30;
        XSingaporedollarTxt: Label 'Singapore dollar', MaxLength = 30;
        XSloveniantolarTxt: Label 'Slovenian tolar', MaxLength = 30;
        XSaudiArabianryialTxt: Label 'Saudi Arabian ryial', MaxLength = 30;
        XSolomonIslandsdollarTxt: Label 'Solomon Islands dollar', MaxLength = 30;
        XThaibahtTxt: Label 'Thai baht', MaxLength = 30;
        XUSdollarTxt: Label 'US dollar', MaxLength = 30;
        XVanuatuvatuTxt: Label 'Vanuatu vatu', MaxLength = 30;
        XWesternSamoantalaTxt: Label 'Western Samoan tala', MaxLength = 30;
        XSouthAfricanrandTxt: Label 'South African rand', MaxLength = 30;
        XUnitedArabEmiratesdirhamTxt: Label 'United Arab Emirates dirham', MaxLength = 30;
        XAlgeriandinarTxt: Label 'Algerian dinar', MaxLength = 30;
        XHungarianforintTxt: Label 'Hungarian forint', MaxLength = 30;
        XKenyanShillingTxt: Label 'Kenyan Shilling', MaxLength = 30;
        XMoroccandirhamTxt: Label 'Moroccan dirham', MaxLength = 30;
        XMozambiquemeticalTxt: Label 'Mozambique metical', MaxLength = 30;
        XNigeriannairaTxt: Label 'Nigerian naira', MaxLength = 30;
        XRomanianleuTxt: Label 'Romanian leu', MaxLength = 30;
        XSwazilandlilangeniTxt: Label 'Swaziland lilangeni', MaxLength = 30;
        XSlovakKorunaTxt: Label 'Slovak Koruna', MaxLength = 30;
        XSerbianDinarTxt: Label 'Serbian Dinar', MaxLength = 30;
        XTunisiandinarTxt: Label 'Tunisian dinar', MaxLength = 30;
        XUgandanShillingTxt: Label 'Ugandan Shilling', MaxLength = 30;
        XMacedonianDenarTxt: Label 'Macedonian Denar', MaxLength = 30;
        XChineseYuanTxt: Label 'Chinese Yuan', MaxLength = 30;
        XAfghaniTxt: Label 'Afghani', MaxLength = 30;
        XArgentinePesoTxt: Label 'Argentine Peso', MaxLength = 30;
        XArmenianDramTxt: Label 'Armenian Dram', MaxLength = 30;
        XArubanFlorinTxt: Label 'Aruban Florin', MaxLength = 30;
        XAzerbaijanManatTxt: Label 'Azerbaijan Manat', MaxLength = 30;
        XBahamianDollarTxt: Label 'Bahamian Dollar', MaxLength = 30;
        XBahrainiDinarTxt: Label 'Bahraini Dinar', MaxLength = 30;
        XBalboaTxt: Label 'Balboa', MaxLength = 30;
        XBarbadosDollarTxt: Label 'Barbados Dollar', MaxLength = 30;
        XBelarusianRubleTxt: Label 'Belarusian Ruble', MaxLength = 30;
        XBelizeDollarTxt: Label 'Belize Dollar', MaxLength = 30;
        XBermudianDollarTxt: Label 'Bermudian Dollar', MaxLength = 30;
        XBolivarSoberanoTxt: Label 'Bolivar Soberano', MaxLength = 30;
        XBolivianoTxt: Label 'Boliviano', MaxLength = 30;
        XBurundiFrancTxt: Label 'Burundi Franc', MaxLength = 30;
        XCaboVerdeEscudoTxt: Label 'Cabo Verde Escudo', MaxLength = 30;
        XCaribbeanGuilderTxt: Label 'Caribbean Guilder', MaxLength = 30;
        XCaymanIslandsDollarTxt: Label 'Cayman Islands Dollar', MaxLength = 30;
        XCfaFrancBceaoTxt: Label 'Cfa Franc Bceao', MaxLength = 30;
        XChileanPesoTxt: Label 'Chilean Peso', MaxLength = 30;
        XColombianPesoTxt: Label 'Colombian Peso', MaxLength = 30;
        XComorianFrancTxt: Label 'Comorian Franc', MaxLength = 30;
        XCongoleseFrancTxt: Label 'Congolese Franc', MaxLength = 30;
        XConvertibleMarkTxt: Label 'Convertible Mark', MaxLength = 30;
        XCordobaOroTxt: Label 'Cordoba Oro', MaxLength = 30;
        XCostaRicanColonTxt: Label 'Costa Rican Colon', MaxLength = 30;
        XCubanPesoTxt: Label 'Cuban Peso', MaxLength = 30;
        XDalasiTxt: Label 'Dalasi', MaxLength = 30;
        XDjiboutiFrancTxt: Label 'Djibouti Franc', MaxLength = 30;
        XDobraTxt: Label 'Dobra', MaxLength = 30;
        XDominicanPesoTxt: Label 'Dominican Peso', MaxLength = 30;
        XDongTxt: Label 'Dong', MaxLength = 30;
        XCentralAfricaFrancTxt: Label 'Central African CFA Franc', MaxLength = 30;
        XEastCaribbeanDollarTxt: Label 'East Caribbean Dollar', MaxLength = 30;
        XEgyptianPoundTxt: Label 'Egyptian Pound', MaxLength = 30;
        XElSalvadorColonTxt: Label 'El Salvador Colon', MaxLength = 30;
        XEthiopianBirrTxt: Label 'Ethiopian Birr', MaxLength = 30;
        XFalklandIslandsPoundTxt: Label 'Falkland Islands Pound', MaxLength = 30;
        XGhanaCediTxt: Label 'Ghana Cedi', MaxLength = 30;
        XGibraltarPoundTxt: Label 'Gibraltar Pound', MaxLength = 30;
        XGourdeTxt: Label 'Gourde', MaxLength = 30;
        XGuaraniTxt: Label 'Guarani', MaxLength = 30;
        XGuineanFrancTxt: Label 'Guinean Franc', MaxLength = 30;
        XGuyanaDollarTxt: Label 'Guyana Dollar', MaxLength = 30;
        XHryvniaTxt: Label 'Hryvnia', MaxLength = 30;
        XIranianRialTxt: Label 'Iranian Rial', MaxLength = 30;
        XIraqiDinarTxt: Label 'Iraqi Dinar', MaxLength = 30;
        XJamaicanDollarTxt: Label 'Jamaican Dollar', MaxLength = 30;
        XJordanianDinarTxt: Label 'Jordanian Dinar', MaxLength = 30;
        XKinaTxt: Label 'Kina', MaxLength = 30;
        XKuwaitiDinarTxt: Label 'Kuwaiti Dinar', MaxLength = 30;
        XKwanzaTxt: Label 'Kwanza', MaxLength = 30;
        XKyatTxt: Label 'Kyat', MaxLength = 30;
        XLaoKipTxt: Label 'Lao Kip', MaxLength = 30;
        XLariTxt: Label 'Lari', MaxLength = 30;
        XLebanesePoundTxt: Label 'Lebanese Pound', MaxLength = 30;
        XLekTxt: Label 'Lek', MaxLength = 30;
        XLempiraTxt: Label 'Lempira', MaxLength = 30;
        XLeoneTxt: Label 'Leone', MaxLength = 30;
        XLiberianDollarTxt: Label 'Liberian Dollar', MaxLength = 30;
        XLibyanDinarTxt: Label 'Libyan Dinar', MaxLength = 30;
        XLotiTxt: Label 'Loti', MaxLength = 30;
        XMalagasyAriaryTxt: Label 'Malagasy Ariary', MaxLength = 30;
        XMalawiKwachaTxt: Label 'Malawi Kwacha', MaxLength = 30;
        XMauritiusRupeeTxt: Label 'Mauritius Rupee', MaxLength = 30;
        XMoldovanLeuTxt: Label 'Moldovan Leu', MaxLength = 30;
        XMvdolTxt: Label 'Mvdol', MaxLength = 30;
        XNakfaTxt: Label 'Nakfa', MaxLength = 30;
        XNamibiaDollarTxt: Label 'Namibia Dollar', MaxLength = 30;
        XNepaleseRupeeTxt: Label 'Nepalese Rupee', MaxLength = 30;
        XNewIsraeliSheqelTxt: Label 'New Israeli Sheqel', MaxLength = 30;
        XNewTaiwanDollarTxt: Label 'New Taiwan Dollar', MaxLength = 30;
        XNgultrumTxt: Label 'Ngultrum', MaxLength = 30;
        XNorthKoreanWonTxt: Label 'North Korean Won', MaxLength = 30;
        XOuguiyaTxt: Label 'Ouguiya', MaxLength = 30;
        XPakistanRupeeTxt: Label 'Pakistan Rupee', MaxLength = 30;
        XPatacaTxt: Label 'Pataca', MaxLength = 30;
        XPesoUruguayoTxt: Label 'Peso Uruguayo', MaxLength = 30;
        XPlatinumTxt: Label 'Platinum', MaxLength = 30;
        XPulaTxt: Label 'Pula', MaxLength = 30;
        XQatariRialTxt: Label 'Qatari Rial', MaxLength = 30;
        XQuetzalTxt: Label 'Quetzal', MaxLength = 30;
        XRialOmaniTxt: Label 'Rial Omani', MaxLength = 30;
        XRielTxt: Label 'Riel', MaxLength = 30;
        XRufiyaaTxt: Label 'Rufiyaa', MaxLength = 30;
        XRwandaFrancTxt: Label 'Rwanda Franc', MaxLength = 30;
        XSaintHelenaPoundTxt: Label 'Saint Helena Pound', MaxLength = 30;
        XSeychellesRupeeTxt: Label 'Seychelles Rupee', MaxLength = 30;
        XSolTxt: Label 'Sol', MaxLength = 30;
        XSomTxt: Label 'Som', MaxLength = 30;
        XSomaliShillingTxt: Label 'Somali Shilling', MaxLength = 30;
        XSomoniTxt: Label 'Somoni', MaxLength = 30;
        XSouthSudanesePoundTxt: Label 'South Sudanese Pound', MaxLength = 30;
        XSriLankaRupeeTxt: Label 'Sri Lanka Rupee', MaxLength = 30;
        XSudanesePoundTxt: Label 'Sudanese Pound', MaxLength = 30;
        XSurinamDollarTxt: Label 'Surinam Dollar', MaxLength = 30;
        XSyrianPoundTxt: Label 'Syrian Pound', MaxLength = 30;
        XTakaTxt: Label 'Taka', MaxLength = 30;
        XTanzanianShillingTxt: Label 'Tanzanian Shilling', MaxLength = 30;
        XTengeTxt: Label 'Tenge', MaxLength = 30;
        XTrinidadAndTobagoDollarTxt: Label 'Trinidad And Tobago Dollar', MaxLength = 30;
        XTugrikTxt: Label 'Tugrik', MaxLength = 30;
        XTurkmenistanNewManatTxt: Label 'Turkmenistan New Manat', MaxLength = 30;
        XUnidadDeFomentoTxt: Label 'Unidad De Fomento', MaxLength = 30;
        XUnidadDeValorRealTxt: Label 'Unidad De Valor Real', MaxLength = 30;
        XUnidadPrevisionalTxt: Label 'Unidad Previsional', MaxLength = 30;
        XUzbekistanSumTxt: Label 'Uzbekistan Sum', MaxLength = 30;
        XWonTxt: Label 'Won', MaxLength = 30;
        XYemeniRialTxt: Label 'Yemeni Rial', MaxLength = 30;
        XZambianKwachaTxt: Label 'Zambian Kwacha', MaxLength = 30;
        XZimbabweGoldTxt: Label 'Zimbabwe Gold', MaxLength = 30;
        NoCurrencyFoundErr: Label 'No currency was found, can not continue.';
        XNewTurkishliraTxt: Label 'New Turkish lira', MaxLength = 30;
        XTonganPaangaTxt: Label 'Tongan Pa anga', MaxLength = 30;
        XFrenchPacificFrancTxt: Label 'French Pacific Franc', MaxLength = 30;

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
        Currency.Insert(true);
    end;
    
    procedure InsertExchRateData(TemporaryCurrencyData: Record "Temporary Currency Data")
    begin
        if Skip then
            exit;
    
        "Create Currency Exchange Rate".InsertData(
              TemporaryCurrencyData."Currency Code", CalcDate('<CY-2Y+1D>', WorkDate()), TemporaryCurrencyData."Exchange Rate Amount", TemporaryCurrencyData."Exchange Rate Amount",
              '', TemporaryCurrencyData."Relational Exch. Rate Amount", 0, TemporaryCurrencyData."Relational Exch. Rate Amount");
    end;
    
    procedure GetBusPostingGroup("Country Code": Code[10]): Code[10]
    begin
        if DemoDataSetup."Country/Region Code" = '' then
            DemoDataSetup.Get();
    
        case "Country Code" of
            '', DemoDataSetup."Country/Region Code":
                exit(DemoDataSetup.DomesticCode());
            'AT', 'BE', 'BG', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR', 'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL',
          'PL', 'PT', 'RO', 'SK', 'SI', 'ES', 'SE', 'GB':
                exit(DemoDataSetup.EUCode());
            else
                exit(DemoDataSetup.ExportCode());
        end;
    end;
    
    procedure GetPostingGroup("Country Code": Code[10]): Code[10]
    begin
        if DemoDataSetup."Country/Region Code" = '' then
            DemoDataSetup.Get();
    
        case "Country Code" of
            '', DemoDataSetup."Country/Region Code":
                exit(DemoDataSetup.DomesticCode());
            'AT', 'BE', 'BG', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR', 'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL',
          'PL', 'PT', 'RO', 'SK', 'SI', 'ES', 'SE', 'GB':
                exit(DemoDataSetup.EUCode());
            else
                exit(DemoDataSetup.ForeignCode());
        end;
    end;
    
    procedure ModifyData()
    var
        "G/L Account": Record "G/L Account";
    begin
        DemoDataSetup.Get();
        Currency.Reset();
        if Currency.Find('-') then
            repeat
                if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then begin
                    Currency.Validate("Unrealized Gains Acc.", CA.Convert('999310'));
                    Currency.Validate("Unrealized Losses Acc.", CA.Convert('999320'));
                    Currency.Validate("Realized Gains Acc.", CA.Convert('999330'));
                    Currency.Validate("Realized Losses Acc.", CA.Convert('999340'));
                    if DemoDataSetup."Additional Currency Code" = Currency.Code then begin
                        Currency.Validate("Realized G/L Gains Account", CA.Convert('999330'));
                        Currency.Validate("Realized G/L Losses Account", CA.Convert('999340'));
                        Currency.Validate("Residual Gains Account", CA.Convert('999350'));
                        Currency.Validate("Residual Losses Account", CA.Convert('999360'));
                        "G/L Account".SetFilter("No.", '%1|%2|%3|%4|%5|%6|%7|%8',
                          CA.Convert('992310'), CA.Convert('992320'), CA.Convert('995410'), CA.Convert('995420'),
                          CA.Convert('999310'), CA.Convert('999320'), CA.Convert('999330'), CA.Convert('999340'));
                        "G/L Account".ModifyAll("Exchange Rate Adjustment", 2);
                    end;
                end;
                Currency.Modify();
            until Currency.Next() = 0;
    end;
    
    procedure SkipDemoDataSetup(NewSkip: Boolean)
    begin
        Skip := NewSkip;
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
                exit(XTunisiandinarTxt);
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
            'XAF':
                exit(XCentralAfricaFrancTxt);
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
    