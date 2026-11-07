codeunit 101008 "Create Language"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('BGR', XBulgarian);
        InsertData('CHS', XSimplifiedChinese);
        InsertData('CSY', XCzech);
        InsertData('DAN', XDanish);
        InsertData('DEA', XGermanAustrian);
        InsertData('DES', XGermanSwiss);
        InsertData('DEU', XGerman);
        InsertData('ENA', XEnglishAustralian);
        InsertData('ENC', XEnglishCanadian);
        InsertData('ENG', XEnglishUnitedKingdom);
        InsertData('ENI', XEnglishIreland);
        InsertData('ENU', XEnglish);
        InsertData('ENZ', XEnglishNewZealand);
        InsertData('ESM', XSpanishMexican);
        InsertData('ENP', XEnglishPhilippines);
        InsertData('ESP', XSpanish);
        InsertData('ESN', XSpanishInternational);
        InsertData('ESO', XSpanishColombian);
        InsertData('ESR', XSpanishPeruvian);
        InsertData('ESS', XSpanishArgentine);
        InsertData('ELL', XGreek);
        InsertData('ETI', XEstonian);
        InsertData('FIN', XFinnish);
        InsertData('FRA', XFrench);
        InsertData('FRB', XFrenchBelgian);
        InsertData('FRC', XFrenchCanadian);
        InsertData('FRS', XFrenchSwiss);
        InsertData('HRV', XCroatian);
        InsertData('HUN', XHungarian);
        InsertData('IND', XIndonesian);
        InsertData('ISL', XIcelandic);
        InsertData('ITA', XItalian);
        InsertData('ITS', XItalianSwiss);
        InsertData('JPN', XJapanese);
        InsertData('KOR', XKorean);
        InsertData('LTH', XLithuanian);
        InsertData('LVI', XLatvian);
        InsertData('MSL', XMalaysian);
        InsertData('NLD', XDutch);
        InsertData('NLB', XDutchBelgian);
        InsertData('NON', XNorwegianNynorsk);
        InsertData('NOR', XNorwegian);
        InsertData('PLK', XPolish);
        InsertData('PTG', XPortuguese);
        InsertData('PTB', XPortugueseBrazilian);
        InsertData('ROM', XRomanian);
        InsertData('RUS', XRussian);
        InsertData('SRP', XSerbian);
        InsertData('SKY', XSlovak);
        InsertData('SLV', XSlovene);
        InsertData('SVE', XSwedish);
        InsertData('THA', XThai);
        InsertData('TRK', XTurkish);
        InsertData('UKR', XUkrainian);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Language: Record Language;
        XBulgarian: Label 'Bulgarian';
        XCzech: Label 'Czech';
        XDanish: Label 'Danish';
        XGermanAustrian: Label 'German (Austrian)';
        XGermanSwiss: Label 'German (Swiss)';
        XGerman: Label 'German';
        XGreek: Label 'Greek';
        XEnglishAustralian: Label 'English (Australian)';
        XEnglishCanadian: Label 'English (Canadian)';
        XEnglishUnitedKingdom: Label 'English (United Kingdom)';
        XEnglishIreland: Label 'English (Ireland)';
        XEnglishPhilippines: Label 'English (Philippines)';
        XEnglish: Label 'English';
        XEnglishNewZealand: Label 'English (New Zealand)';
        XSpanishMexican: Label 'Spanish (Mexico)';
        XSpanish: Label 'Spanish';
        XSpanishInternational: Label 'Spanish (Spain)';
        XSpanishArgentine: Label 'Spanish (Argentine)';
        XSpanishColombian: Label 'Spanish (Colombia)';
        XSpanishPeruvian: Label 'Spanish (Peru)';
        XEstonian: Label 'Estonian';
        XFinnish: Label 'Finnish';
        XFrench: Label 'French';
        XFrenchBelgian: Label 'French (Belgian)';
        XFrenchCanadian: Label 'French (Canadian)';
        XFrenchSwiss: Label 'French (Swiss)';
        XCroatian: Label 'Croatian';
        XHungarian: Label 'Hungarian';
        XIndonesian: Label 'Indonesian';
        XIcelandic: Label 'Icelandic';
        XItalian: Label 'Italian';
        XItalianSwiss: Label 'Italian (Swiss)';
        XJapanese: Label 'Japanese';
        XKorean: Label 'Korean';
        XLithuanian: Label 'Lithuanian';
        XLatvian: Label 'Latvian';
        XMalaysian: Label 'Malaysian';
        XDutch: Label 'Dutch';
        XDutchBelgian: Label 'Dutch (Belgian)';
        XNorwegianNynorsk: Label 'Norwegian (Nynorsk)';
        XNorwegian: Label 'Norwegian';
        XPolish: Label 'Polish';
        XPortuguese: Label 'Portuguese';
        XPortugueseBrazilian: Label 'Portuguese (Brazil)';
        XRomanian: Label 'Romanian';
        XRussian: Label 'Russian';
        XSerbian: Label 'Serbian';
        XSimplifiedChinese: Label 'Simplified Chinese';
        XSlovak: Label 'Slovak';
        XSlovene: Label 'Slovene';
        XSwedish: Label 'Swedish';
        XThai: Label 'Thai';
        XTurkish: Label 'Turkish';
        XUkrainian: Label 'Ukrainian';
        WindowsLang: Record "Windows Language";

    procedure GetLanguageCode("Country Code": Code[10]): Code[10]
    var
        "Language Code": Code[10];
    begin
        DemoDataSetup.Get();
        case "Country Code" of
            'AT':
                "Language Code" := 'DEA';
            'AU':
                "Language Code" := 'ENA';
            'BE':
                "Language Code" := 'NLB';
            'BG':
                "Language Code" := 'BGR';
            'BR':
                "Language Code" := 'PTB';
            'CA':
                "Language Code" := 'ENC';
            'CH':
                "Language Code" := 'DES';
            'CO':
                "Language Code" := 'ESO';
            'CZ':
                "Language Code" := 'CSY';
            'DE':
                "Language Code" := 'DEU';
            'DK':
                "Language Code" := 'DAN';
            'ES':
                "Language Code" := 'ESP';
            'ET':
                "Language Code" := 'ETI';
            'FI':
                "Language Code" := 'FIN';
            'FR':
                "Language Code" := 'FRA';
            'GB':
                "Language Code" := 'ENG';
            'GR':
                "Language Code" := 'ELL';
            'HR':
                "Language Code" := 'HRV';
            'HU':
                "Language Code" := 'HUN';
            'ID':
                "Language Code" := 'IND';
            'IE':
                "Language Code" := 'ENI';
            'IN':
                "Language Code" := 'ENG';
            'IS':
                "Language Code" := 'ISL';
            'IT':
                "Language Code" := 'ITA';
            'LT':
                "Language Code" := 'LTH';
            'LV':
                "Language Code" := 'LVI';
            'MX':
                "Language Code" := 'ESM';
            'MY', 'SG', 'US', 'ZA':
                "Language Code" := 'ENU';
            'NL':
                "Language Code" := 'NLD';
            'NO':
                "Language Code" := 'NOR';
            'NZ':
                "Language Code" := 'ENZ';
            'PE':
                "Language Code" := 'ESR';
            'PL':
                "Language Code" := 'PLK';
            'PT':
                "Language Code" := 'PTG';
            'RO':
                "Language Code" := 'ROM';
            'RS':
                "Language Code" := 'SRP';
            'RU':
                "Language Code" := 'RUS';
            'SE':
                "Language Code" := 'SVE';
            'SI':
                "Language Code" := 'SLV';
            'SK':
                "Language Code" := 'SKY';
            'TH':
                "Language Code" := 'THA';
            'TR':
                "Language Code" := 'TRK';
            'UA':
                "Language Code" := 'UKR';
            'ZH':
                "Language Code" := 'CHS';
        end;
        exit("Language Code");
    end;

    procedure InsertData("Code": Code[10]; Name: Text[50])
    var
        WindLangID: Integer;
    begin
        Language.Init();
        Language.Validate(Code, Code);
        Language.Validate(Name, Name);
        WindowsLang.Reset();
        WindowsLang.SetCurrentKey("Abbreviated Name");
        WindowsLang.SetFilter("Abbreviated Name", Code);
        WindowsLang.FindFirst();

        WindLangID := WindowsLang."Language ID";
        Language.Validate("Windows Language ID", WindLangID);
        Language.Insert(true);
        WindowsLang.Reset();
    end;
}

