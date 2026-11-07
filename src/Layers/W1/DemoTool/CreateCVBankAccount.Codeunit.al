codeunit 101287 "Create C/V Bank Account"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(
          '', '', XTHO, XThompsonsBank, XRussellHunter, XEllesboroughRoad47, CreatePostCode.Convert('GB-B27 4KT'), XGB, XGBP, XENG,
          X44296696298, X44296696504, X1000, X1000100000, '', '');
        InsertData(
          '', '', XPAR, XParkHouseBankingGroup, XScottMacDonald, XWickRoad56, CreatePostCode.Convert('GB-B27 4KT'), XGB, XGBP, XENG,
          X44296311044, X44296704144, X1100, X1100100000, '', '');
        InsertData(
          '', '20000', XECA, XECABank, XSheelaWord, XAnchorHouse43, CreatePostCode.Convert('GB-B27 4KT'), XGB, XGBP, XENG,
          X44296196933, X44296151727, X1200, X1200100000,
          XGB54BARC20992012345678, XGB29NWBK60161331926819);
        InsertData(
          '', '', XANT, XAntwerp, XDavidJaffe, XFrankrijklei10, 'BE-2050', XBE, XEUR, XNLB,
          X3232322093, X3232339287, X2000, X2000200000, '', '');
        InsertData(
          '', '', XUTR, XUtrecht, XDavidDollas, XBernadottelaan31, 'NL-6827 BP', XNL, XEUR, XNLD,
          X3130947091, X3130917917, X3000, X3000300000, '', '');
        InsertData(
          '', '', XSPA, XSparbanken, XJohnFrum, XVollsveien31, 'NO-1324', XNO, XNOK, XNOR,
          X4721250314, X4725309137, X4000, X4000400000, '', '');
        InsertData(
          '', '', XHAN, XHandelsbanken, XBjornRettig, XEngelbrektsgatan71, 'SE-114 32', XSE, XSEK, XSVE,
          X4640523788, X4640176743, X5000, X5000500000, '', '');
        InsertData(
          '', '', XCOM, XCommerzBank, XYvonneSchleger, XEickelscheidt67, 'DE-40593', XDE, XEUR, XDEU,
          X49210267511, X49210368024, X6000, X6000600000, '', '');

        PostInsertData();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Customer: Record Customer;
        "Customer Bank Account": Record "Customer Bank Account";
        Vendor: Record Vendor;
        "Vendor Bank Account": Record "Vendor Bank Account";
        CreatePostCode: Codeunit "Create Post Code";
        XTHO: Label 'THO';
        XThompsonsBank: Label 'Thompsons Bank';
        XRussellHunter: Label 'Russell Hunter';
        XEllesboroughRoad47: Label 'Ellesborough Road 47';
        XGB: Label 'GB';
        XGBP: Label 'GBP';
        XENG: Label 'ENG';
        X44296696298: Label '+44 296 696298';
        X44296696504: Label '+44 296 696504';
        XPAR: Label 'PAR';
        XParkHouseBankingGroup: Label 'Park House Banking Group';
        XScottMacDonald: Label 'Scott MacDonald';
        XWickRoad56: Label 'Wick Road 56';
        X44296311044: Label '+44 296 311044';
        X44296704144: Label '+44 296 704144';
        XECA: Label 'ECA';
        XECABank: Label 'ECA Bank';
        XSheelaWord: Label 'Sheela Word';
        XAnchorHouse43: Label 'Anchor House 43';
        X44296196933: Label '+44 296 196933';
        X44296151727: Label '+44 296 151727';
        XGB54BARC20992012345678: Label 'GB 54 BARC 20992012345678';
        XGB29NWBK60161331926819: Label 'GB 29 NWBK 60161331926819';
        XANT: Label 'ANT';
        XAntwerp: Label 'Antwerp';
        XDavidJaffe: Label 'David Jaffe';
        XFrankrijklei10: Label 'Frankrijklei 10';
        XBE: Label 'BE';
        XEUR: Label 'EUR';
        XNLB: Label 'NLB';
        X3232322093: Label '+32 3 232 20 93';
        X3232339287: Label '+32 3 233 92 87';
        XUTR: Label 'UTR';
        XUtrecht: Label 'Utrecht';
        XDavidDollas: Label 'David Dollas';
        XBernadottelaan31: Label 'Bernadottelaan 31';
        XNL: Label 'NL';
        XNLD: Label 'NLD';
        X3130947091: Label '+31 30 947091';
        X3130917917: Label '+31 30 917917';
        XSPA: Label 'SPA';
        XSparbanken: Label 'Sparbanken';
        XJohnFrum: Label 'John Frum';
        XVollsveien31: Label 'Vollsveien 31';
        XNO: Label 'NO';
        XNOK: Label 'NOK';
        XNOR: Label 'NOR';
        X4721250314: Label '+47 21 25 03 14';
        X4725309137: Label '+47 25 30 91 37';
        XHAN: Label 'HAN';
        XHandelsbanken: Label 'Handelsbanken';
        XBjornRettig: Label 'Bjorn Rettig';
        XEngelbrektsgatan71: Label 'Engelbrektsgatan 71';
        XSE: Label 'SE';
        XSEK: Label 'SEK';
        XSVE: Label 'SVE';
        X4640523788: Label '+46 40 523788';
        X4640176743: Label '+46 40 176743';
        XCOM: Label 'COM';
        XCommerzBank: Label 'Commerz Bank';
        XYvonneSchleger: Label 'Yvonne Schleger';
        XEickelscheidt67: Label 'Eickelscheidt 67';
        XDE: Label 'DE';
        XDEU: Label 'DEU';
        X49210267511: Label '+49 2102 67511';
        X49210368024: Label '+49 2103 68024';
        X1000: Label '1000';
        X1000100000: Label '1000 100000';
        X1100: Label '1100';
        X1100100000: Label '1100 100000';
        X1200: Label '1200';
        X1200100000: Label '1200 100000';
        X2000: Label '2000';
        X2000200000: Label '2000 200000';
        X3000: Label '3000';
        X3000300000: Label '3000 300000';
        X4000: Label '4000';
        X4000400000: Label '4000 400000';
        X5000: Label '5000';
        X5000500000: Label '5000 500000';
        X6000: Label '6000';
        X6000600000: Label '6000 600000';
        Vend33299199Txt: Label '33299199', Locked = true;
        IBANFR1420041010050500013M02606Txt: Label 'FR1420041010050500013M02606', Locked = true;
        Vend31580305Txt: Label '31580305', Locked = true;
        IBANNL91ABNA0417164300Txt: Label 'NL91ABNA0417164300', Locked = true;
        Vend32554455Txt: Label '32554455', Locked = true;
        IBANBE68539007547034Txt: Label 'BE68 5390 0754 7034', Locked = true;
        Vend34280789Txt: Label '34280789', Locked = true;
        IBANES9121000418450200051332Txt: Label 'ES9121000418450200051332', Locked = true;
        Vend49454647Txt: Label '49454647', Locked = true;
        IBANDE89370400440532013000Txt: Label 'DE89370400440532013000', Locked = true;
        Vend38458653Txt: Label '38458653', Locked = true;
        IBANSI56191000000123438Txt: Label 'SI56191000000123438', Locked = true;

    procedure CreateEvaluationData()
    begin
        DemoDataSetup.Get();
        InsertData(
          '', '20000', XECA, XECABank, XSheelaWord, XAnchorHouse43, CreatePostCode.Convert('GB-B27 4KT'), XGB, XGBP, XENG,
          X44296196933, X44296151727, X1200, X1200100000,
          XGB54BARC20992012345678, XGB29NWBK60161331926819);
    end;

    local procedure PostInsertData()
    begin
        UpdateData(Vend33299199Txt, XUTR, IBANFR1420041010050500013M02606Txt);
        UpdateData(Vend31580305Txt, XCOM, IBANNL91ABNA0417164300Txt);
        UpdateData(Vend32554455Txt, XANT, IBANBE68539007547034Txt);
        UpdateData(Vend34280789Txt, XUTR, IBANES9121000418450200051332Txt);
        UpdateData(Vend49454647Txt, XCOM, IBANDE89370400440532013000Txt);
        UpdateData(Vend38458653Txt, XCOM, IBANSI56191000000123438Txt);
    end;

    local procedure UpdateData(VendorNo: Code[20]; BankAccCode: Code[10]; NewIBAN: Code[50])
    var
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
    begin
        VendorBankAccount.Get(VendorNo, BankAccCode);
        VendorBankAccount.Validate(IBAN, NewIBAN);
        VendorBankAccount.Modify(true);

        Vendor.Get(VendorNo);
        Vendor.Validate("Preferred Bank Account Code", BankAccCode);
        Vendor.Modify(true);
    end;

    procedure InsertData("From Account No.": Code[20]; "To Account No.": Code[20]; "Code": Code[20]; Name: Text[30]; Contact: Text[30]; Address: Text[30]; "Post Code": Text[30]; "Country Code": Code[10]; "Currency Code": Code[10]; "Language Code": Text[30]; "Phone No.": Text[30]; "Fax No.": Text[30]; "Bank Branch No.": Text[30]; "Bank Account No.": Text[30]; IBAN1: Code[50]; IBAN2: Code[50])
    var
        CodeSort: Record "Code Sort" temporary;
    begin
        if "Country Code" = DemoDataSetup."Country/Region Code" then
            "Country Code" := '';
        if "Currency Code" = DemoDataSetup."Currency Code" then
            "Currency Code" := '';
        if "Language Code" = DemoDataSetup."Language Code" then
            "Language Code" := '';
        Customer.Reset();
        if "To Account No." <> '' then
            Customer.SetRange("No.", "From Account No.", "To Account No.");
        Customer.SetRange("Currency Code", "Currency Code");
        if Customer.Find('-') then
            repeat
                CodeSort.InsertRecord(Customer."No.");
            until Customer.Next() = 0;

        CodeSort.SetCurrentKey("Name (Index)");
        if CodeSort.Find('-') then
            repeat
                Customer.Get(CodeSort.Name);
                "Bank Account No." := IncStr("Bank Account No.");
                "Customer Bank Account".Init();
                "Customer Bank Account".Validate("Customer No.", Customer."No.");
                "Customer Bank Account".Validate(Code, Code);
                "Customer Bank Account".Validate(Name, Name);
                "Customer Bank Account".Validate(Contact, Contact);
                "Customer Bank Account".Validate(Address, Address);
                if "Country Code" <> '' then
                    "Customer Bank Account".Validate("Country/Region Code", "Country Code");
                "Customer Bank Account"."Post Code" := CreatePostCode.FindPostCode("Post Code");
                "Customer Bank Account".City := CreatePostCode.FindCity("Post Code");
                if "Currency Code" <> '' then
                    "Customer Bank Account".Validate("Currency Code", "Currency Code");
                if "Language Code" <> '' then
                    "Customer Bank Account".Validate("Language Code", "Language Code");
                "Customer Bank Account".Validate("Phone No.", "Phone No.");
                "Customer Bank Account".Validate("Fax No.", "Fax No.");
                "Customer Bank Account"."Bank Branch No." := "Bank Branch No.";
                "Customer Bank Account"."Bank Account No." := "Bank Account No.";
                if "Customer Bank Account"."Customer No." = '10000' then
                    "Customer Bank Account".Validate(IBAN, IBAN1);
                "Customer Bank Account".Insert(true);
            until CodeSort.Next() = 0;

        Vendor.Reset();
        if "To Account No." <> '' then
            Vendor.SetRange("No.", "From Account No.", "To Account No.");
        Vendor.SetRange("Currency Code", "Currency Code");

        Clear(CodeSort);
        CodeSort.DeleteAll();
        if Vendor.Find('-') then
            repeat
                CodeSort.InsertRecord(Vendor."No.");
            until Vendor.Next() = 0;

        CodeSort.SetCurrentKey("Name (Index)");
        if CodeSort.Find('-') then
            repeat
                Vendor.Get(CodeSort.Name);
                "Bank Account No." := IncStr("Bank Account No.");
                "Vendor Bank Account".Init();
                "Vendor Bank Account".Validate("Vendor No.", Vendor."No.");
                "Vendor Bank Account".Validate(Code, Code);
                "Vendor Bank Account".Validate(Name, Name);
                "Vendor Bank Account".Validate(Contact, Contact);
                "Vendor Bank Account".Validate(Address, Address);
                if "Country Code" <> '' then
                    "Vendor Bank Account".Validate("Country/Region Code", "Country Code");
                "Vendor Bank Account"."Post Code" := CreatePostCode.FindPostCode("Post Code");
                "Vendor Bank Account".City := CreatePostCode.FindCity("Post Code");
                if "Currency Code" <> '' then
                    "Vendor Bank Account".Validate("Currency Code", "Currency Code");
                if "Language Code" <> '' then
                    "Vendor Bank Account".Validate("Language Code", "Language Code");
                "Vendor Bank Account".Validate("Phone No.", "Phone No.");
                "Vendor Bank Account".Validate("Fax No.", "Fax No.");
                "Vendor Bank Account"."Bank Branch No." := "Bank Branch No.";
                "Vendor Bank Account"."Bank Account No." := "Bank Account No.";
                if "Vendor Bank Account"."Vendor No." = '10000' then
                    "Vendor Bank Account".Validate(IBAN, IBAN2);
                "Vendor Bank Account".Insert(true);
            until CodeSort.Next() = 0;
    end;
}

