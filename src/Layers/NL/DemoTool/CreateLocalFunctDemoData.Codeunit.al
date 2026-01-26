codeunit 160000 "Create Local Funct. Demo Data"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();

        UpdateGLSetup();
        CreatePostCodeRanges();
        if DemoDataSetup."Data Type" <> DemoDataSetup."Data Type"::Standard then begin
            CreateBankAcctPostingGrps();
            CreateBankAccounts();
            CreateTransactionModes();
            CreateExportProtocols();
            CreateImportProtocols();
            CreateCustomerBanks();
            CreateVendorBanks();
            CreateGenJnlTemplates();
            UpdateCustomers();
            UpdateVendors();
            UpdateBanks();
        end;
        CreateFreelyTransfMaximums();
    end;

    var
        XRABOBBV: Label 'RABO-BBV';
        XPaymentVendor: Label 'Payment Vendor';
        XABNUSD: Label 'ABN-USD';
        XIDENTIFIC: Label 'IDENTIFIC';
        XTelebankIdentification: Label 'Telebanking Identification';
        XRUNNO: Label 'RUNNO';
        XTelebankRunNos: Label 'Telebanking Run Nos.';
        XPAYMTPROC: Label 'PAYMTPROC';
        XPaymentsInProcess: Label 'Payments in Process';
        XPaymtsReceiptsInProcess: Label 'Paymts./Recpts. in Process';
        XABN: Label 'ABN';
        XBBV: Label 'BBV';
        XABNBTL: Label 'ABN-BTL';
        XCollectionCustomers: Label 'Collection Customers';
        XBTL91: Label 'BTL91';
        XRECPTPROC: Label 'RECPTSPROC';
        XReceiptsInProcess: Label 'Receipts in Process';
        XRABOMUTASC: Label 'RABO MUT.ASC';
        XRABOLEEN: Label 'RABO-LEEN';
        DemoDataSetup: Record "Demo Data Setup";
        CreateNoSeries: Codeunit "Create No. Series";
        CreateGLAccount: Codeunit "Create G/L Account";
        XCollectionInProcess: Label 'Collection in Process';
        XABNAMROForeignPaymts: Label 'ABN-AMRO Foreign Payments';
        XRABOForeignPaymts: Label 'RABO Foreign Payments';
        XPAYMUL: Label 'PAYMUL';
        XRABOTelebankingDomestic: Label 'RABO Telebanking (Domestic)';
        XRABOTelebankingForeign: Label 'RABO Telebanking (Foreign)';
        XRABOVVMUTASC: Label 'RABO VVMUT.ASC';
        XPOSTBANK: Label 'POSTBANK';
        XXDU: Label 'XDU';
        XBLG: Label 'BLG';
        XCASH: Label 'CASH';
        XCashJournal: Label 'Cash Journal';
        XCASHJNL: Label 'CASHJNL';
        XCASH0001: Label 'CASH0001';
        X1000: Label '1000';
        XABNBankJournal: Label 'ABN Bank Journal';
        XABNBANKJNL: Label 'ABNBANKJNL';
        XABNBANK0001: Label 'ABNBANK0001';
        XGiroJournal: Label 'Giro Journal';
        XGIROJNL: Label 'GIROJNL';
        XGIRO0001: Label 'GIRO0001';
        CreateBankAcct: Codeunit "Create Bank Account";
        CreateBankAcctPostGrp: Codeunit "Create Bank Acc. Posting Group";
        LastNoSeries: Code[20];
        XDamrak1: Label 'Damrak 1';
        X1012LX: Label '1012 LX';
        XGerardZalm: Label 'Gerard Zalm';
        XUSD: Label 'USD';
        XABNAMRO: Label 'ABN-AMRO';
        XRaadhuisplein10: Label 'Raadhuisplein 10';
        X2131HD: Label '2131 HD';
        XDikBijlmers: Label 'Dik Bijlmers';
        XRABOUSD: Label 'RABO-USD';
        XDeBrug12: Label 'De Brug 12';
        XMargrietKanters: Label 'Margriet Kanters';
        XSEPACAMT: Label 'SEPA CAMT';
        XSEPACAMTDesc: Label 'SEPA CAMT Bank Statements';
        XGenericSEPATxt: Label 'Generic SEPA';
        XGenericSEPADescTxt: Label 'Generic Payment File';
        XGenericSEPA09Txt: Label 'Generic SEPA09';
        XGenericSEPADesc09Txt: Label 'SEPA CT pain.001.001.09', Locked = true;

    procedure CreatePostCodeRanges()
    var
        PostCodeRange: Record "Post Code Range";
    begin
        CreatePostCodeRange('1012 LX', 'Rotterdam', PostCodeRange.Type::Odd, 1, 31, 'Damrak');
        CreatePostCodeRange('1017 PT', 'Amsterdam', PostCodeRange.Type::Even, 2, 78, 'Geinplantsoen');
        CreatePostCodeRange('1025 EW', 'Amsterdam', PostCodeRange.Type::Even, 2, 312, 'Kinkerstraat');
        CreatePostCodeRange('1066 PQ', 'Rotterdam', PostCodeRange.Type::Even, 2, 64, 'Hogestraat');
        CreatePostCodeRange('1068 TC', 'Amsterdam', PostCodeRange.Type::" ", 0, 0, 'Ringweg');
        CreatePostCodeRange('1111 DA', 'Amsterdam', PostCodeRange.Type::Odd, 1, 99, 'De Ring');
        CreatePostCodeRange('1211 EC', 'Hilversum', PostCodeRange.Type::Even, 2, 98, 'Vallei');
        CreatePostCodeRange('1313 KT', 'Rotterdam', PostCodeRange.Type::Odd, 1, 51, 'Zwartekruisweg');
        CreatePostCodeRange('1313 KT', 'Rotterdam', PostCodeRange.Type::Odd, 53, 103, 'Fluitekruidstraat');
        CreatePostCodeRange('1435 CS', 'Rijsenhout', PostCodeRange.Type::Even, 2, 20, 'Raadhuisstraat');
        CreatePostCodeRange('1506 XE', 'Zaandam', PostCodeRange.Type::Odd, 1, 51, 'Binkkampen');
        CreatePostCodeRange('1507 ZZ', 'Jaarsveld', PostCodeRange.Type::Odd, 1, 27, 'Eenheid');
        CreatePostCodeRange('1530 JM', 'Zaandam', PostCodeRange.Type::Even, 2, 100, 'Havenweg');
        CreatePostCodeRange('1797 FM', 'Den Hoorn', PostCodeRange.Type::Even, 2, 10, 'Pier');
        CreatePostCodeRange('2131 HD', 'Rotterdam', PostCodeRange.Type::Even, 2, 28, 'Raadhuisplein');
        CreatePostCodeRange('2521 BR', 's-Gravenhage', PostCodeRange.Type::Even, 2, 56, 'Kunststraat');
        CreatePostCodeRange('3056 DH', 'Zoetermeer', PostCodeRange.Type::Even, 2, 100, 'Groene Berm');
        CreatePostCodeRange('3421 AR', 'Oudewater', PostCodeRange.Type::Odd, 1, 39, 'Daalmeerstraat');
        CreatePostCodeRange('3437 GY', 'Nieuwegein', PostCodeRange.Type::Even, 2, 322, 'Chapel Lane Sands');
        CreatePostCodeRange('3512 GC', 'Utrecht', PostCodeRange.Type::Odd, 1, 57, 'Bernadottelaan');
        CreatePostCodeRange('3512 ZD', 'Utrecht', PostCodeRange.Type::Even, 2, 22, 'Parkweg');
        CreatePostCodeRange('3701 GH', 'Zeist', PostCodeRange.Type::Even, 2, 222, 'Clarenburg');
        CreatePostCodeRange('3770 AA', 'Barneveld', PostCodeRange.Type::Even, 2, 102, 'Steengroeve');
        CreatePostCodeRange('3781 EN', 'Voorthuizen', PostCodeRange.Type::Odd, 1, 79, 'Fregellaan');
        CreatePostCodeRange('3811 LB', 'Amersfoort', PostCodeRange.Type::Even, 2, 98, 'Donkerstraat');
        CreatePostCodeRange('4814 AD', 'Breda', PostCodeRange.Type::Odd, 1, 553, 'Meubelweg');
        CreatePostCodeRange('4826 VB', 'Breda', PostCodeRange.Type::Odd, 1, 15, 'Buitenplein');
        CreatePostCodeRange('5132 EE', 'Waalwijk', PostCodeRange.Type::Odd, 1, 115, 'Looiersdreef');
        CreatePostCodeRange('5141 GP', 'Waalwijk', PostCodeRange.Type::Odd, 1, 61, 'Nummer');
        CreatePostCodeRange('5301 BA', 'Zaltbommel', PostCodeRange.Type::Even, 2, 14, 'Industrieweg');
        CreatePostCodeRange('6371 GN', 'Landgraaf', PostCodeRange.Type::Odd, 1, 211, 'Hoogstraat');
        CreatePostCodeRange('6432 RT', 'Leimuiden', PostCodeRange.Type::Even, 2, 26, 'Hoofdstraat');
        CreatePostCodeRange('6713 AL', 'Ede', PostCodeRange.Type::Even, 2, 104, 'Flevolaan');
        CreatePostCodeRange('6811 GV', 'Arnhem', PostCodeRange.Type::Even, 2, 44, 'Piet Heijnstraat');
        CreatePostCodeRange('6827 BP', 'Arnhem', PostCodeRange.Type::Even, 2, 36, 'Beekstraat');
        CreatePostCodeRange('7201 HW', 'Zutphen', PostCodeRange.Type::Odd, 1, 33, 'Leeghwaterlaan');
        CreatePostCodeRange('7311 KA', 'Apeldoorn', PostCodeRange.Type::Even, 2, 16, 'Noordzeeweg');
        CreatePostCodeRange('7321 HE', 'Apeldoorn', PostCodeRange.Type::Even, 2, 64, 'Mergelland');
        CreatePostCodeRange('7325 AL', 'Apeldoorn', PostCodeRange.Type::Odd, 1, 205, 'Stationsplein');
        CreatePostCodeRange('7413 WG', 'Deventer', PostCodeRange.Type::Even, 2, 98, 'Sperwerweg');
        CreatePostCodeRange('8032 ZP', 'Zwolle', PostCodeRange.Type::Even, 2, 20, 'Sidney Boulevard');
        CreatePostCodeRange('8071 BX', 'Nunspeet', PostCodeRange.Type::Odd, 1, 201, 'Stevinstraat');
        CreatePostCodeRange('8224 JC', 'Lelystad', PostCodeRange.Type::Even, 2, 112, 'Westermate');
        CreatePostCodeRange('8441 HA', 'Heerenveen', PostCodeRange.Type::Odd, 5, 13, 'Korenmarkt');
        CreatePostCodeRange('9417 AB', 'Spier', PostCodeRange.Type::Odd, 1, 21, 'Sportweg');
        CreatePostCodeRange('9418 HH', 'Oranje', PostCodeRange.Type::Odd, 1, 35, 'Ringweg Koppel');
        CreatePostCodeRange('9671 EV', 'Winschoten', PostCodeRange.Type::Odd, 1, 27, 'Torenvalk');
        CreatePostCodeRange('9745 AD', 'Groesbeek', PostCodeRange.Type::Odd, 1, 13, 'Kortestraat');
        CreatePostCodeRange('8426 PQ', 'Hoensbroek', PostCodeRange.Type::Even, 2, 22, 'Manor Road');
        CreatePostCodeRange('2587 JJ', 'Den Haag', PostCodeRange.Type::Even, 2, 48, 'Woolpack Lane');
        CreatePostCodeRange('8022 AA', 'Zwolle', PostCodeRange.Type::Even, 2, 44, 'Kennedystraat');
        CreatePostCodeRange('7064 KH', 'Silvolde', PostCodeRange.Type::Odd, 1, 31, 'Old Leeds Road');
        CreatePostCodeRange('1827 MK', 'Alkmaar', PostCodeRange.Type::" ", 0, 0, 'Sevenoaks Kent');
        CreatePostCodeRange('6278 KL', 'Beutenaken', PostCodeRange.Type::Odd, 1, 1033, 'Rozengracht');
        CreatePostCodeRange('3526 XG', 'Utrecht', PostCodeRange.Type::Odd, 1, 23, 'Energielaan');
        CreatePostCodeRange('9743 CL', 'Groningen', PostCodeRange.Type::Even, 1, 402, 'Goudlaan');
        CreatePostCodeRange('3421 AC', 'Oudewater', PostCodeRange.Type::Even, 1, 14, 'Hoofdstraat');
        CreatePostCodeRange('8022 AA', 'Zwolle', PostCodeRange.Type::Even, 1, 22, 'Kennedystraat');
    end;

    procedure CreatePostCodeRange(PostCode: Code[20]; City: Text[30]; Type: Integer; FromNo: Integer; ToNo: Integer; StreetName: Text[30])
    var
        PostCodeRange: Record "Post Code Range";
    begin
        PostCodeRange."Post Code" := PostCode;
        PostCodeRange.City := City;
        PostCodeRange.Type := Type;
        PostCodeRange."From No." := FromNo;
        PostCodeRange."To No." := ToNo;
        PostCodeRange."Street Name" := StreetName;
        PostCodeRange.Insert(true);
    end;

    procedure CreateBankAcctPostingGrps()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then begin
            CreateBankAcctPostGrp.InsertData(XABN, '992920');
            CreateBankAcctPostGrp.InsertData(XPOSTBANK, '992940');
            CreateBankAcctPostGrp.InsertData(XABNUSD, '992930');
            CreateBankAcctPostGrp.InsertData(XRABOLEEN, '995310');
            CreateBankAcctPostGrp.InsertData(XRABOUSD, '981012');
        end else begin
            CreateBankAcctPostGrp.InsertData(XABN, CreateGLAccount.BusinessaccountOperatingDomestic());
            CreateBankAcctPostGrp.InsertData(XPOSTBANK, CreateGLAccount.BusinessaccountOperatingForeign());
            CreateBankAcctPostGrp.InsertData(XABNUSD, CreateGLAccount.PettyCash());
            CreateBankAcctPostGrp.InsertData(XRABOLEEN, CreateGLAccount.PettyCash());
            CreateBankAcctPostGrp.InsertData(XRABOUSD, CreateGLAccount.PettyCash());
        end;
    end;

    procedure CreateBankAccounts()
    begin
        CreateBankAcct.InsertData(
          XABNUSD, XABNUSD, XDamrak1, X1012LX,
          XGerardZalm, XUSD, XABNUSD, '112-2233-33', 'BG99999', 'NL28 ABNA 0112 2233 33');
        CreateBankAcct.InsertData(
          XABN, XABNAMRO, XRaadhuisplein10, X2131HD,
          XDikBijlmers, '', XABN, '30-60-01-241', '43.12.90.456', 'NL69 ABNA 0306 0012 41');
        CreateBankAcct.InsertData(
          XRABOLEEN, XRABOLEEN, XDamrak1, X1012LX,
          XGerardZalm, '', XRABOLEEN, '30-33-55-328', 'BG99999', 'NL38 RABO 0303 3553 28');
        CreateBankAcct.InsertData(
          XRABOUSD, XRABOUSD, XDamrak1, X1012LX,
          XGerardZalm, XUSD, XRABOUSD, '0000 1111 20', 'BG99999', 'NL00 RABO 0000 1111 20');
        CreateBankAcct.InsertData(
          XPOSTBANK, XPOSTBANK, XDeBrug12, X2131HD,
          XMargrietKanters, '', XPOSTBANK, 'P1234567', 'GO284033', 'NL69 PSTB 0001 2345 67');
    end;

    procedure CreateTransactionModes()
    var
        TransactionMode: Record "Transaction Mode";
    begin
        CreateTransactionMode(
            XRABOBBV,
            TransactionMode."Account Type"::Vendor,
            XPaymentVendor,
            XABNUSD,
            XIDENTIFIC,
            XTelebankIdentification,
            XRUNNO,
            XTelebankRunNos,
            XPAYMTPROC,
            XPaymentsInProcess,
            XPAYMTPROC,
            XPaymentsInProcess,
            '1612', XPaymentsInProcess,
            '1180', XPaymtsReceiptsInProcess,
            XBBV);

        CreateTransactionMode(
          XPOSTBANK,
          TransactionMode."Account Type"::Vendor,
          XPaymentVendor,
          XPOSTBANK,
          XIDENTIFIC,
          XTelebankIdentification,
          XRUNNO,
          XTelebankRunNos,
          XPAYMTPROC,
          XPaymentsInProcess,
          XPAYMTPROC,
          XPaymentsInProcess,
          '1612', XPaymentsInProcess,
          '1180', XPaymtsReceiptsInProcess,
          XBTL91);

        CreateTransactionMode(
          XABN,
          TransactionMode."Account Type"::Vendor,
          XPaymentVendor,
          XABN,
          XIDENTIFIC,
          XTelebankIdentification,
          XRUNNO,
          XTelebankRunNos,
          XPAYMTPROC,
          XPaymentsInProcess,
          XPAYMTPROC,
          XPaymentsInProcess,
          '1612', XPaymentsInProcess,
          '1180', XPaymtsReceiptsInProcess,
          XBTL91);

        CreateTransactionMode(
          XABNBTL,
          TransactionMode."Account Type"::Vendor,
          XPaymentVendor,
          XABN,
          XIDENTIFIC,
          XTelebankIdentification,
          XRUNNO,
          XTelebankRunNos,
          XPAYMTPROC,
          XPaymentsInProcess,
          XPAYMTPROC,
          XPaymentsInProcess,
          '1612', XPaymentsInProcess,
          '1180', XPaymtsReceiptsInProcess,
          XBTL91);

        CreateTransactionMode(
          XABN,
          TransactionMode."Account Type"::Customer,
          XCollectionCustomers,
          XABN,
          XIDENTIFIC,
          XTelebankIdentification,
          XRUNNO,
          XTelebankRunNos,
          XRECPTPROC,
          XReceiptsInProcess,
          XRECPTPROC,
          XReceiptsInProcess,
          '1312', XCollectionInProcess,
          '1180', XPaymtsReceiptsInProcess,
          XBTL91);
    end;

    procedure CreateTransactionMode("Code": Code[10]; AcctType: Option Klant,Leverancier; Omschrijving: Text[30]; Bank: Code[10]; KenmerkReeks: Code[10]; KenmerkReeksOmschrijving: Text[30]; Runnummerreeks: Code[10]; RunnummerreeksOmschrijving: Text[30]; StuknrReeks: Code[10]; StuknrReeksOmschrijving: Text[30]; Broncode: Code[20]; BroncodeOmschrijving: Text[30]; RekBetOdw: Code[20]; RekBetOdwTekst: Text[30]; RekBetOdwTegen: Code[10]; RekBetOdwTegenTekst: Text[30]; VerzProtocol: Code[20])
    var
        TransactionMode: Record "Transaction Mode";
        BrnCode: Record "Source Code";
        Bnk: Record "Bank Account";
        Bankboekingsgrp: Record "Bank Account Posting Group";
        GrootboekrekeningRec: Record "G/L Account";
        NrReeks: Record "No. Series";
    begin
        if TransactionMode.Get(AcctType, Code) then
            TransactionMode.Delete(true);
        Clear(TransactionMode);

        TransactionMode.Validate("Account Type", AcctType);
        TransactionMode.Code := Code;
        TransactionMode.Insert(true);

        TransactionMode.Description := Omschrijving;

        if NrReeks.Get(KenmerkReeks) then
            NrReeks.Delete(true);
        CreateNoSeries.InitBaseSeries(KenmerkReeks, KenmerkReeks, KenmerkReeksOmschrijving, '1', '', '', '', 1);
        TransactionMode."Identification No. Series" := KenmerkReeks;

        if NrReeks.Get(Runnummerreeks) then
            NrReeks.Delete(true);
        CreateNoSeries.InitBaseSeries(Runnummerreeks, Runnummerreeks, RunnummerreeksOmschrijving, '1', '', '', '', 1);
        TransactionMode."Run No. Series" := Runnummerreeks;

        if NrReeks.Get(StuknrReeks) then
            NrReeks.Delete(true);
        CreateNoSeries.InitBaseSeries(StuknrReeks, StuknrReeks, StuknrReeksOmschrijving, StuknrReeks + '1', '', '', '', 1);
        TransactionMode."Posting No. Series" := StuknrReeks;
        TransactionMode."Correction Posting No. Series" := StuknrReeks;

        if not BrnCode.Get(Broncode) then begin
            BrnCode.Code := Broncode;
            BrnCode.Description := BroncodeOmschrijving;
            BrnCode.Insert(true);
        end;
        TransactionMode."Source Code" := BrnCode.Code;
        TransactionMode."Correction Source Code" := BrnCode.Code;

        if not GrootboekrekeningRec.Get(RekBetOdw) then begin
            GrootboekrekeningRec."No." := RekBetOdw;
            GrootboekrekeningRec.Name := RekBetOdwTekst;
            GrootboekrekeningRec."Direct Posting" := false;
            GrootboekrekeningRec."Income/Balance" := GrootboekrekeningRec."Income/Balance"::"Balance Sheet";
            GrootboekrekeningRec.Insert(true);
        end;
        TransactionMode."Acc. No. Pmt./Rcpt. in Process" := GrootboekrekeningRec."No.";

        if not GrootboekrekeningRec.Get(RekBetOdwTegen) then begin
            GrootboekrekeningRec."No." := RekBetOdwTegen;
            GrootboekrekeningRec.Name := RekBetOdwTegenTekst;
            GrootboekrekeningRec."Direct Posting" := false;
            GrootboekrekeningRec."Income/Balance" := GrootboekrekeningRec."Income/Balance"::"Balance Sheet";
            GrootboekrekeningRec.Insert(true);
        end;

        Bnk.Get(Bank);
        Bankboekingsgrp.Get(Bnk."Bank Acc. Posting Group");
        if Bankboekingsgrp."Acc.No. Pmt./Rcpt. in Process" <> RekBetOdwTegen then begin
            Bankboekingsgrp."Acc.No. Pmt./Rcpt. in Process" := RekBetOdwTegen;
            Bankboekingsgrp.Modify(true);
        end;
        TransactionMode."Our Bank" := Bnk."No.";
        TransactionMode."Export Protocol" := VerzProtocol;
        TransactionMode.Modify(true);
    end;

    procedure CreateExportProtocols()
    begin
        CreateExportProtocol(XBTL91, XABNAMROForeignPaymts, 11000007, 11000004, 11000007, 'c:\temp\btl%1.txt');
        CreateExportProtocol(XBBV, XRABOForeignPaymts, 11000008, 11000004, 11000008, 'c:\temp\bbv%1.txt');
        CreateExportProtocol(XPAYMUL, XPAYMUL, 11000009, 11000004, 11000009, '');
        CreateExportProtocol(XGenericSEPATxt, XGenericSEPADescTxt, Codeunit::"Check BTL91", Report::Docket, Report::"SEPA ISO20022 Pain 01.01.03", '');
        CreateExportProtocol(XGenericSEPA09Txt, XGenericSEPADesc09Txt, Codeunit::"Check BTL91", Report::Docket, Report::"SEPA ISO20022 Pain 01.01.09", '');
    end;

    procedure CreateExportProtocol("Code": Code[20]; Description: Text[30]; CheckID: Integer; DocketID: Integer; ExportID: Integer; FileNames: Text[80])
    var
        ExportProtocol: Record "Export Protocol";
    begin
        ExportProtocol.Init();
        ExportProtocol.Validate(Code, Code);
        ExportProtocol.Validate(Description, Description);
        ExportProtocol.Validate("Check ID", CheckID);
        ExportProtocol.Validate("Export ID", ExportID);
        ExportProtocol.Validate("Docket ID", DocketID);
        ExportProtocol.Validate("Default File Names", FileNames);

        if not ExportProtocol.Insert() then
            ExportProtocol.Modify();
    end;

    procedure CreateImportProtocols()
    begin
        CreateImportProtocol(XRABOMUTASC, 3, 11000021, XRABOTelebankingDomestic);
        CreateImportProtocol(XRABOVVMUTASC, 3, 11000022, XRABOTelebankingForeign);
        CreateImportProtocol(XSEPACAMT, 5, 11404, XSEPACAMTDesc);
    end;

    procedure CreateImportProtocol("Code": Code[20]; ImportType: Integer; ImportID: Integer; Description: Text[80])
    var
        ImportprotocolRec: Record "Import Protocol";
    begin
        ImportprotocolRec.Code := Code;
        ImportprotocolRec."Import Type" := ImportType;
        ImportprotocolRec."Import ID" := ImportID;
        ImportprotocolRec.Description := Description;
        if not ImportprotocolRec.Insert() then
            ImportprotocolRec.Modify();
    end;

    procedure UpdateBanks()
    begin
        UpdateBank(XABN, '30.60.01.241');
        UpdateBank(XPOSTBANK, 'P 98 76 543');
        UpdateBank(XRABOLEEN, '30.33.55.328');
        UpdateBank(XABNUSD, '30.60.01.244');
    end;

    procedure UpdateBank(BankCode: Code[20]; RekeningNrCode: Code[20])
    var
        BankRek: Record "Bank Account";
        BedrijfsGeg: Record "Company Information";
    begin
        BankRek.Get(BankCode);
        BedrijfsGeg.Get();
        BankRek."Account Holder Name" := BedrijfsGeg.Name;
        BankRek."Account Holder Address" := BedrijfsGeg.Address;
        BankRek."Account Holder Post Code" := BedrijfsGeg."Post Code";
        BankRek."Account Holder City" := BedrijfsGeg.City;
        BankRek."Bank Account No." := RekeningNrCode;
        BankRek.Modify();
    end;

    procedure CreateCustomerBanks()
    begin
        CreateCustomerBank('10000', XPOSTBANK, 'P1234567');
        CreateCustomerBank('20000', XPOSTBANK, 'P2234567');
        CreateCustomerBank('30000', XPOSTBANK, 'P3234567');
        CreateCustomerBank('40000', XPOSTBANK, 'P4234567');
    end;

    procedure CreateCustomerBank(KlantNr: Code[20]; CodeRek: Code[20]; RekNr: Code[20])
    var
        Bankklt: Record "Customer Bank Account";
    begin
        if Bankklt.Get(KlantNr, CodeRek) then;
        Bankklt."Customer No." := KlantNr;
        Bankklt.Code := CodeRek;
        Bankklt.Validate("Bank Account No.", RekNr);
        if not Bankklt.Insert(true) then
            Bankklt.Modify();
    end;

    procedure CreateVendorBanks()
    begin
        CreateVendorBank('10000', XPOSTBANK, 'P5234567', '');
        CreateVendorBank('20000', XPOSTBANK, 'P6234567', '');
        CreateVendorBank('30000', XPOSTBANK, 'P7234567', '');
        CreateVendorBank('40000', XPOSTBANK, 'P8234567', '');
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then begin
            CreateVendorBank('49989898', XRABOLEEN, '303355328', '');
            CreateVendorBank('01863656', XXDU, '12 12426 35355', 'ES');
            CreateVendorBank('32554455', XBLG, '861281876', 'BE');
            CreateVendorBank('32665544', XBLG, '657412356', 'BE');
        end;
    end;

    procedure CreateVendorBank(LevNr: Code[20]; CodeRek: Code[20]; RekNr: Code[20]; Landcode: Code[10])
    var
        BankLev: Record "Vendor Bank Account";
    begin
        if BankLev.Get(LevNr, CodeRek) then;
        BankLev."Vendor No." := LevNr;
        BankLev.Code := CodeRek;
        BankLev."Country/Region Code" := Landcode;
        BankLev.Validate("Bank Account No.", RekNr);
        if not BankLev.Insert(true) then
            BankLev.Modify();
    end;

    procedure UpdateCustomers()
    begin
        UpdateCustomer('10000', XABN, XPOSTBANK);
        UpdateCustomer('20000', XABN, XPOSTBANK);
        UpdateCustomer('30000', XABN, XPOSTBANK);
        UpdateCustomer('40000', XABN, XPOSTBANK);
    end;

    procedure UpdateCustomer(CustNo: Code[20]; TransactionMode: Code[20]; BankAcct: Code[10])
    var
        Cust: Record Customer;
    begin
        Cust.Get(CustNo);
        Cust."Transaction Mode Code" := TransactionMode;
        Cust."Preferred Bank Account Code" := BankAcct;
        Cust.Modify();
    end;

    procedure UpdateVendors()
    begin
        UpdateVendor('10000', XPOSTBANK, XPOSTBANK);
        UpdateVendor('20000', XPOSTBANK, XPOSTBANK);
        UpdateVendor('30000', XPOSTBANK, XPOSTBANK);
        UpdateVendor('40000', XPOSTBANK, XPOSTBANK);
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then begin
            UpdateVendor('49989898', XRABOBBV, XRABOLEEN);
            UpdateVendor('01863656', XABNBTL, XXDU);
            UpdateVendor('32554455', XABNBTL, XBLG);
            UpdateVendor('32665544', XRABOBBV, XBLG);
        end;
    end;

    procedure UpdateVendor(VendNo: Code[20]; TransactionMode: Code[20]; BankAcct: Code[20])
    var
        Vend: Record Vendor;
    begin
        Vend.Get(VendNo);
        Vend."Transaction Mode Code" := TransactionMode;
        Vend."Preferred Bank Account Code" := BankAcct;
        Vend.Modify();
    end;

    procedure UpdateGLSetup()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        if GLSetup."LCY Code" = 'EUR' then
            GLSetup."Local Currency" := GLSetup."Local Currency"::Euro
        else
            if GLSetup."Local Currency" = GLSetup."Local Currency"::Euro then
                GLSetup."LCY Code" := 'EUR';
        GLSetup.Modify();
    end;

    procedure CreateFreelyTransfMaximums()
    begin
        CreateFreelyTransfMaximum('BE', 'EUR', 9000);
        CreateFreelyTransfMaximum('DK', 'DKK', 21500);
        CreateFreelyTransfMaximum('DE', 'EUR', 12500);
        CreateFreelyTransfMaximum('FI', 'EUR', 2900);
        CreateFreelyTransfMaximum('FR', 'EUR', 12500);
        CreateFreelyTransfMaximum('EL', 'EUR', 2900);
        CreateFreelyTransfMaximum('GB', 'GBP', 8000);
        CreateFreelyTransfMaximum('IE', 'EUR', 2900);
        CreateFreelyTransfMaximum('IS', 'ISK', 208000);
        CreateFreelyTransfMaximum('IT', 'EUR', 2900);
        CreateFreelyTransfMaximum('LU', 'EUR', 2900);
        CreateFreelyTransfMaximum('NO', 'NOK', 23300);
        CreateFreelyTransfMaximum('AT', 'EUR', 12500);
        CreateFreelyTransfMaximum('PT', 'EUR', 2900);
        CreateFreelyTransfMaximum('ES', 'EUR', 12500);
        CreateFreelyTransfMaximum('SE', 'SEK', 24300);
        CreateFreelyTransfMaximum('CH', 'CHF', 18000);
    end;

    procedure CreateFreelyTransfMaximum(CountryCode: Code[10]; CurrencyCode: Code[10]; Amount: Decimal)
    var
        FreelyTransfMax: Record "Freely Transferable Maximum";
    begin
        if CurrencyCode = DemoDataSetup."Currency Code" then
            CurrencyCode := '';

        FreelyTransfMax.Init();
        FreelyTransfMax.Validate("Country/Region Code", CountryCode);
        FreelyTransfMax.Validate("Currency Code", CurrencyCode);
        FreelyTransfMax.Validate(Amount, Amount);
        FreelyTransfMax.Insert();
    end;

    procedure CreateGenJnlTemplates()
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        DemoDataSetup.Get();

        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then
            CreateGenJnlTemplate(XCASH, XCashJournal, GenJnlTemplate.Type::Cash, XCASHJNL, XCASH, XCashJournal, XCASH0001, '', GenJnlTemplate."Bal. Account Type"::"G/L Account", X1000)
        else
            CreateGenJnlTemplate(XCASH, XCashJournal, GenJnlTemplate.Type::Cash, XCASHJNL, XCASH, XCashJournal, XCASH0001, '', GenJnlTemplate."Bal. Account Type"::"G/L Account", CreateGLAccount.PettyCash());

        CreateGenJnlTemplate(
          XABN,
          XABNBankJournal,
          GenJnlTemplate.Type::Bank,
          XABNBANKJNL,
          XABNBANKJNL,
          XABNBankJournal,
          XABNBANK0001,
          '',
          GenJnlTemplate."Bal. Account Type"::"Bank Account",
          XABN);
        CreateGenJnlTemplate(
          XPOSTBANK,
          XGiroJournal,
          GenJnlTemplate.Type::Bank,
          XGIROJNL,
          XGIROJNL,
          XGiroJournal,
          XGIRO0001,
          '',
          GenJnlTemplate."Bal. Account Type"::"Bank Account",
          XPOSTBANK);
    end;

    procedure CreateGenJnlTemplate(Name: Code[10]; Description: Text[80]; Type: Enum "Gen. Journal Template Type"; SourceCode2: Code[10]; NoSeries: Code[20]; NoSeriesDesc: Text[30]; NoSeriesStartNo: Code[20]; NoSeriesEndNo: Code[20]; BalAcctType: Enum "Gen. Journal Account Type"; BalAcctNo: Code[20])
    var
        SourceCode: Record "Source Code";
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        if (NoSeries <> '') and (NoSeries <> LastNoSeries) then
            CreateNoSeries.InitBaseSeries(NoSeries, NoSeries, NoSeriesDesc, NoSeriesStartNo, NoSeriesEndNo, '', '', 1);
        LastNoSeries := NoSeries;

        GenJnlTemplate.Init();
        GenJnlTemplate.Validate(Name, Name);
        GenJnlTemplate.Validate(Description, Description);
        GenJnlTemplate.Insert(true);
        GenJnlTemplate.Validate(Type, Type);
        GenJnlTemplate.Validate("No. Series", NoSeries);

        if SourceCode2 <> '' then begin
            SourceCode.Code := SourceCode2;
            SourceCode.Description := Description;
            if not SourceCode.Insert() then
                SourceCode.Modify();
            GenJnlTemplate.Validate("Source Code", SourceCode2);
        end;

        GenJnlTemplate.Validate("Bal. Account Type", BalAcctType);
        GenJnlTemplate.Validate("Bal. Account No.", BalAcctNo);
        GenJnlTemplate.Modify();
    end;
}

