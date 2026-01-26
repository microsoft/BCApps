codeunit 161553 "Create Demodata DTA"
{

    trigger OnRun()
    var
        NoOfRecsRead: Integer;
        NoOfRecsWritten: Integer;
    begin
        Vendor.SetRange("No.", '100000', '100100');
        if not Vendor.IsEmpty() then
            Error(Text11507);

        DemoDataSetup.Get();
        BankDirectory.ImportBankDirectoryDirect('localfiles\des_bcbankenstamm.txt', NoOfRecsRead, NoOfRecsWritten);

        Commit();

        // Get Jour Template
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Purchases);
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.FindFirst();

        // DTA Rechnungsjournal Name
        ReasonCode.Init();
        ReasonCode.Code := Text11510;
        ReasonCode.Description := Text11511;
        ReasonCode.Insert();

        GenJournalBatch.Init();
        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Name := Text11512;
        GenJournalBatch.Description := Text11513;
        GenJournalBatch."Reason Code" := Text11510;
        if not GenJournalBatch.Insert() then
            GenJournalBatch.Modify();

        GenJournalLine.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalLine.SetRange("Journal Batch Name", Text11512);
        GenJournalLine.DeleteAll();

        Window.Open(Text11516 +
          '#1#############################');

        WorkDate2 := WorkDate();  // speichern

        Window.Update(1, Text11517);

        UpdateDTASetup();
        CreateVendors();

        Window.Close();
        WorkDate(WorkDate2);
    end;

    var
        Text11507: Label 'There are already vendors in the number range 100000 - 100100. The demo data cannot be generated.';
        Text11510: Label 'DTA RG';
        Text11511: Label 'DTA Invoices';
        Text11512: Label 'DTA RGS';
        Text11513: Label 'Recording DTA Invoices';
        Text11516: Label 'Generate DTA demo data\\';
        Text11517: Label 'DTA Master Data';
        Text11522: Label 'Zug';
        Text11523: Label 'Zuger Kantonalbank';
        Text11528: Label 'ZKB';
        Text11531: Label 'CRON1';
        Text11532: Label 'Bahnhofstrasse 1';
        Text11533: Label 'CS';
        Text11536: Label 'Telekurs Payserv AG';
        Text11537: Label 'Computer Bureau';
        Text11538: Label 'Parcel Post Box';
        Text11539: Label 'Zürich 1';
        Text11540: Label 'Credit Suisse';
        Text11541: Label 'Bahnhofstrasse 17';
        Text11544: Label 'EZAG';
        Text11547: Label 'Sägewerk Mathis';
        Text11548: Label 'Waldeck';
        Text11549: Label 'Buchrain';
        Text11550: Label 'Domestic';
        Text11551: Label 'NATIONAL';
        Text11552: Label '14 Days';
        XSwisscom: Label 'Swisscom';
        Text11555: Label 'Tribschenstrasse';
        Text11556: Label 'Luzern';
        Text11558: Label 'Ehrli Beschläge AG';
        Text11559: Label 'Moosstrasse 15';
        Text11560: Label 'Winterthur';
        Text11565: Label 'BA Druck AG';
        Text11566: Label 'Industrie Ost';
        Text11567: Label 'Erstfeld';
        Text11570: Label 'Federal Express';
        Text11571: Label 'Zollstrasse 53';
        Text11572: Label 'Basel';
        Text11575: Label 'ARA Holz AG';
        Text11576: Label 'Wilderswilerweg 3';
        Text11577: Label 'Thun';
        Text11579: Label 'Papeterie Schmid';
        Text11580: Label 'Zulgweg 5';
        xPOST: Label 'Post';
        Text11586: Label 'Restaurant Hohle Gasse';
        Text11587: Label 'Rigistrasse';
        Text11588: Label '1M(8D)';
        xBANK: Label 'Bank';
        Text11594: Label 'Margo Werbeteam';
        Text11595: Label 'Seeweg';
        Text11598: Label 'Screws And Things';
        Text11599: Label 'World Park Road';
        Text11600: Label 'Hillerod';
        Text11601: Label 'Foreign';
        Text11602: Label 'EXPORT';
        Text11603: Label 'EU';
        Text11607: Label 'Windsor Ltd.';
        Text11608: Label 'Industrial Estate';
        Text11609: Label 'US-45700';
        Text11610: Label 'Boston';
        XEXPORT: Label 'EXPORT';
        Text11618: Label 'Great Stelle Enterprises Ltd.';
        Text11619: Label 'Wild Wild Rink 55';
        Text11620: Label 'US-45201';
        Text11621: Label 'Highwield';
        Text11625: Label 'Harry Erdinger';
        Text11626: Label 'Ostweg 3';
        Text11627: Label 'D-45201';
        Text11628: Label 'Westheim';
        Text11632: Label 'Vendor';
        xCASHOUT: Label 'CASHOUT';
        xPABROAD: Label 'PABROAD';
        xSWIFT: Label 'SWIFT';
        xCASHOUTABR: Label 'CASHOUTABR';
        DTASetup: Record "DTA Setup";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        ReasonCode: Record "Reason Code";
        BankDirectory: Record "Bank Directory";
        DemoDataSetup: Record "Demo Data Setup";
        CompanyInfo: Record "Company Information";
        Window: Dialog;
        WorkDate2: Date;
        NextLineNo: Integer;
        xDK21004: Label 'DK-21004';

    procedure UpdateDTASetup()
    begin
        CompanyInfo.Get();
        DTASetup.DeleteAll();
        // DTA Bank ZKB
        DTASetup.Init();
        DTASetup."Bank Code" := Text11528;
        DTASetup."DTA/EZAG" := 0;
        DTASetup."DTA File Folder" := 'a:\';
        DTASetup."DTA Filename" := 'dtalsv';
        DTASetup.Validate("DTA Customer ID", Text11531);
        DTASetup.Validate("DTA Sender ID", Text11531);
        DTASetup.Validate("DTA Sender Clearing", '787');
        DTASetup."DTA Debit Acc. No." := '01-30-130264-05';
        DTASetup."DTA Sender Name" := Format(CompanyInfo.Name, -24);
        DTASetup."DTA Sender Address" := Format(CompanyInfo.Address, -24);
        DTASetup."DTA Sender Post Code" := CopyStr(CompanyInfo."Post Code", 1, MaxStrLen(DTASetup."DTA Sender Post Code"));
        DTASetup."DTA Sender City" := Format(CompanyInfo.City, -24);

        DTASetup."DTA Currency Code" := 'EUR';
        DTASetup."Bal. Account No." := '1026';
        DTASetup."Credit Limit" := 200000;

        DTASetup."DTA Bank Name" := Text11523;
        DTASetup."DTA Bank Name 2" := '';
        DTASetup."DTA Bank Address" := Text11532;
        DTASetup."DTA Bank Post Code" := '6301';
        DTASetup."DTA Bank City" := Text11522;
        DTASetup."DTA Bank E-Mail" := '';
        DTASetup."DTA Bank Home Page" := '';
        if not DTASetup.Insert() then
            DTASetup.Modify();
        // DTA Bank CS
        DTASetup.Init();
        DTASetup."Bank Code" := Text11533;
        DTASetup."DTA/EZAG" := DTASetup."DTA/EZAG"::DTA;
        DTASetup."DTA Main Bank" := true;
        DTASetup."DTA File Folder" := 'c:\paycom\to_sign1\';
        DTASetup."DTA Filename" := 'dtalsv';
        DTASetup.Validate("DTA Customer ID", Text11531);
        DTASetup.Validate("DTA Sender ID", Text11531);
        DTASetup.Validate("DTA Sender Clearing", '4823');
        DTASetup."DTA Debit Acc. No." := '275.588-3';
        DTASetup."DTA Sender Name" := Format(CompanyInfo.Name, -24);
        DTASetup."DTA Sender Address" := Format(CompanyInfo.Address, -24);
        DTASetup."DTA Sender Post Code" := CopyStr(CompanyInfo."Post Code", 1, MaxStrLen(DTASetup."DTA Sender Post Code"));
        DTASetup."DTA Sender City" := Format(CompanyInfo.City, -24);
        DTASetup."Credit Limit" := 300000;
        DTASetup."Bal. Account No." := '1020';

        DTASetup."Computer Bureau Name" := Text11536;
        DTASetup."Computer Bureau Name 2" := Text11537;
        DTASetup."Computer Bureau Address" := Text11538;
        DTASetup."Computer Bureau Post Code" := '8021';
        DTASetup."Computer Bureau City" := Text11539;
        DTASetup."Computer Bureau E-Mail" := '';
        DTASetup."Computer Bureau Home Page" := '';

        DTASetup."DTA Bank Name" := Text11540;
        DTASetup."DTA Bank Name 2" := '';
        DTASetup."DTA Bank Address" := Text11541;
        DTASetup."DTA Bank Post Code" := '6301';
        DTASetup."DTA Bank City" := Text11522;
        DTASetup."DTA Bank E-Mail" := '';
        DTASetup."DTA Bank Home Page" := '';

        if not DTASetup.Insert(true) then
            DTASetup.Modify();
        // EZAG Post
        DTASetup.Init();
        DTASetup."Bank Code" := Text11544;
        DTASetup."DTA/EZAG" := 1;
        DTASetup."EZAG File Folder" := 'a:\';
        DTASetup."EZAG Filename" := 'pttcria';
        DTASetup.Validate("EZAG Debit Account No.", '30-200017-6');
        DTASetup.Validate("EZAG Charges Account No.", '30-200017-6');
        DTASetup.Validate("Last EZAG Order No.", '00');
        DTASetup.Validate("Bal. Account No.", '1010');
        DTASetup."Credit Limit" := 0;

        DTASetup."EZAG Media ID" := '3572670';
        DTASetup."Yellownet E-Mail" := '';
        DTASetup."Yellownet Home Page" := 'www.yellownet.ch';

        if not DTASetup.Insert() then
            DTASetup.Modify();

        DTASetup.Modify();
    end;

    procedure CreateVendors()
    var
        VendorNo: Code[20];
        StandardBank: Code[10];
    begin
        // 100000, ESR 5/15 und CS
        VendorNo := '100000';
        StandardBank := 'ESR5/15';
        CreateVendor(VendorNo, Text11547, Text11548, '6033', Text11549, Text11550, Text11551, Text11551, Text11552, StandardBank, '', '');
        CreateVendorBank(VendorNo, StandardBank, VendorBankAccount."Payment Form"::ESR,
          VendorBankAccount."ESR Type"::"5/15", '70622', 10, 5, '4000', '', '', '');
        CreateVendorBank(VendorNo, Text11533, VendorBankAccount."Payment Form"::"Bank Payment Domestic",
          VendorBankAccount."ESR Type"::" ", '', 0, 0, '', '4003', '12-5123.701', '');

        // Rechnung 5/15
        InitGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("ESR/ISR Coding Line", '<020001000061970> 700675176944991+ 70622>');
        GenJournalLine.Validate("Document No.", StandardBank);
        InsertGenJnlLine(GenJournalLine);

        // 100001, ESR 9/16
        VendorNo := '100001';
        StandardBank := 'ESR9/16';
        CreateVendor(VendorNo, XSwisscom, Text11555, '6002', Text11556, Text11550, Text11551, Text11551, Text11552, StandardBank, '', '');
        CreateVendorBank(VendorNo, StandardBank, VendorBankAccount."Payment Form"::ESR,
          VendorBankAccount."ESR Type"::"9/16", '01-11543-2', 11, 5, '6200', '', '', '');

        // Rechnung 9/16
        InitGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("ESR/ISR Coding Line", '0100000086004>4097160015679962+ 010115432>');
        GenJournalLine.Validate("Document No.", StandardBank);
        InsertGenJnlLine(GenJournalLine);

        // 100002, ESR 9/27
        VendorNo := '100002';
        StandardBank := 'ESR9/27';
        CreateVendor(VendorNo, Text11558, Text11559, '8400', Text11560, Text11550, Text11551, Text11551, Text11552, StandardBank, '', '');
        CreateVendorBank(VendorNo, StandardBank, VendorBankAccount."Payment Form"::ESR,
          VendorBankAccount."ESR Type"::"9/27", '01-9083-5', 23, 5, '4000', '', '', '');

        // Rechnung ESR 9/27
        InitGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("ESR/ISR Coding Line", '0100002251358> 330002000000000097010075184+ 010090835>');
        GenJournalLine.Validate("Document No.", StandardBank + 'a');
        InsertGenJnlLine(GenJournalLine);

        // Rechnung ESR 9/27
        InitGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("ESR/ISR Coding Line", '0100000098804> 001220033796403785179012967+ 010090835>');
        GenJournalLine.Validate("Document No.", StandardBank + 'b');
        InsertGenJnlLine(GenJournalLine);

        // Rechnung ESR 9/27
        InitGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("ESR/ISR Coding Line", '0100002299002> 330002000000000097010075418+ 010090835>');
        GenJournalLine.Validate("Document No.", StandardBank + 'c');
        InsertGenJnlLine(GenJournalLine);

        // 100003, ESR+ 5/15
        VendorNo := '100003';
        StandardBank := 'ESR+ 5/15';
        CreateVendor(VendorNo, Text11565, Text11566, '6472', Text11567, Text11550, Text11551, Text11551, Text11552, StandardBank, '', '');
        CreateVendorBank(VendorNo, StandardBank, VendorBankAccount."Payment Form"::"ESR+",
          VendorBankAccount."ESR Type"::"5/15", '10304', 8, 7, '4000', '', '', '');

        // Rechnung ESR+ 5/15
        InitGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("ESR/ISR Coding Line", '110112111111000+ 10304>');
        GenJournalLine.Validate(Amount, -36.0);
        GenJournalLine.Validate("Document No.", StandardBank);
        InsertGenJnlLine(GenJournalLine);

        // 100004, ESR+ 9/16
        VendorNo := '100004';
        StandardBank := 'ESR+ 9/16';
        CreateVendor(VendorNo, Text11570, Text11571, '4002', Text11572, Text11550, Text11551, Text11551, Text11552, StandardBank, '', '');
        CreateVendorBank(VendorNo, StandardBank, VendorBankAccount."Payment Form"::"ESR+",
          VendorBankAccount."ESR Type"::"9/16", '01-18200-4', 8, 7, '6512', '', '', '');

        // Rechnung ESR+ 9/16
        InitGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("ESR/ISR Coding Line", '042>0066682402012046+ 010182004>');
        GenJournalLine.Validate(Amount, -136.0);
        GenJournalLine.Validate("Document No.", StandardBank);
        InsertGenJnlLine(GenJournalLine);

        // 100005, ESR+ 9/27
        VendorNo := '100005';
        StandardBank := 'ESR+ 9/27';
        CreateVendor(VendorNo, Text11575, Text11576, '3600', Text11577, Text11550, Text11551, Text11551, Text11552, StandardBank, '', '');
        CreateVendorBank(VendorNo, StandardBank, VendorBankAccount."Payment Form"::"ESR+",
          VendorBankAccount."ESR Type"::"9/27", '01-1760-2', 20, 5, '4002', '', '', '');

        // Rechnung ESR+ 9/27
        InitGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("ESR/ISR Coding Line", '042>040471000000000000000020074+ 010017602>');
        GenJournalLine.Validate(Amount, -1036.0);
        GenJournalLine.Validate("Document No.", StandardBank);
        InsertGenJnlLine(GenJournalLine);

        // 100010, EZ Post
        VendorNo := '100010';
        StandardBank := xPOST;
        CreateVendor(VendorNo, Text11579, Text11580, '6301', Text11522, Text11550, Text11551, Text11551, Text11552, StandardBank, '', '');
        CreateVendorBank(VendorNo, StandardBank, VendorBankAccount."Payment Form"::"Post Payment Domestic",
          VendorBankAccount."ESR Type"::" ", '', 0, 0, '4200', '', '', '60-9-9');

        // 1. Rechnung Post
        InitGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("Document No.", 'RG1a');
        GenJournalLine."External Document No." := 'E-' + GenJournalLine."Document No.";
        GenJournalLine.Validate(Amount, -1000.0);
        InsertGenJnlLine(GenJournalLine);

        // 2. Rechnung Post
        InitGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("Document No.", 'RG1b');
        GenJournalLine."External Document No." := 'E-' + GenJournalLine."Document No.";
        GenJournalLine.Validate(Amount, -2000.0);
        InsertGenJnlLine(GenJournalLine);

        // 3. Rechnung Post
        InitGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("Document No.", 'RG1c');
        GenJournalLine."External Document No." := 'E-' + GenJournalLine."Document No.";
        GenJournalLine.Validate(Amount, -2000.0);
        InsertGenJnlLine(GenJournalLine);

        // 100011, EZ Bank
        VendorNo := '100011';
        StandardBank := xBANK;
        CreateVendor(VendorNo, Text11586, Text11587, '6300', Text11522, Text11550, Text11551, Text11551, Text11588, StandardBank, '', '');
        CreateVendorBank(VendorNo, StandardBank, VendorBankAccount."Payment Form"::"Bank Payment Domestic",
          VendorBankAccount."ESR Type"::" ", '', 0, 0, '4000', '4020', '107188-41', '');

        // 1. Rechnung EZ Bank, Skonto
        InitGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("Document No.", 'RG2a');
        GenJournalLine."External Document No." := 'E-' + GenJournalLine."Document No.";
        GenJournalLine.Validate(Amount, -2100.0);
        InsertGenJnlLine(GenJournalLine);

        // 2. Rechnung EZ Bank, Skonto, Buchungsdatum + 3 Tage
        InitGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Posting Date", CalcDate('<3D>', WorkDate()));
        GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("Document No.", 'RG2b');
        GenJournalLine."External Document No." := 'E-' + GenJournalLine."Document No.";
        GenJournalLine.Validate(Amount, -2200.0);
        InsertGenJnlLine(GenJournalLine);

        // 3. Rechnung EZ Bank, Skonto
        InitGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("Document No.", 'RG2c');
        GenJournalLine."External Document No." := 'E-' + GenJournalLine."Document No.";
        GenJournalLine.Validate(Amount, -2300.0);
        InsertGenJnlLine(GenJournalLine);

        // 100012, ZA Inland
        VendorNo := '100012';
        StandardBank := xCASHOUT;
        CreateVendor(VendorNo, Text11594, Text11595, '6300', Text11522, Text11550, Text11551, Text11551, Text11552, StandardBank, '', '');
        CreateVendorBank(VendorNo, StandardBank, VendorBankAccount."Payment Form"::"Cash Outpayment Order Domestic",
          VendorBankAccount."ESR Type"::" ", '', 0, 0, '4200', '', '', '');

        // Rechnung ZA Inland
        InitGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("Document No.", 'RG3');
        GenJournalLine."External Document No." := 'E-' + GenJournalLine."Document No.";
        GenJournalLine.Validate(Amount, -3000.0);
        InsertGenJnlLine(GenJournalLine);

        // 100020,  PC Ausland
        VendorNo := '100020';
        StandardBank := xPABROAD;
        CreateVendor(VendorNo, Text11598, Text11599, xDK21004, Text11600, Text11601, Text11602, Text11603, Text11552, StandardBank, 'DKK', 'DK');
        CreateVendorBank(VendorNo, StandardBank, VendorBankAccount."Payment Form"::"Post Payment Abroad",
          VendorBankAccount."ESR Type"::" ", '', 0, 0, '4000', '', '07817584', '');

        // Rechnung PC Ausland
        InitGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("Document No.", 'RG-A1');
        GenJournalLine."External Document No." := 'E-' + GenJournalLine."Document No.";
        GenJournalLine.Validate(Amount, -1000.0);
        InsertGenJnlLine(GenJournalLine);

        // 100021, Bank Ausland
        VendorNo := '100021';
        StandardBank := xBANK;
        CreateVendor(VendorNo, Text11607, Text11608, Text11609, Text11610, Text11601, Text11602, XEXPORT, Text11552, StandardBank, 'USD', 'US');
        CreateVendorBank(VendorNo, StandardBank, VendorBankAccount."Payment Form"::"Bank Payment Abroad",
          VendorBankAccount."ESR Type"::" ", '', 0, 0, '4000', '', '33-555-0.3', '');

        // 1. Rechnung Bank Ausland
        InitGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("Document No.", 'RG-A2a');
        GenJournalLine."External Document No." := 'E-' + GenJournalLine."Document No.";
        GenJournalLine.Validate(Amount, -1111.0);
        InsertGenJnlLine(GenJournalLine);

        // 2. Rechnung Bank Ausland
        InitGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("Document No.", 'RG-A2b');
        GenJournalLine."External Document No." := 'E-' + GenJournalLine."Document No.";
        GenJournalLine.Validate(Amount, -2222.0);
        InsertGenJnlLine(GenJournalLine);

        // // 100022, Swift Ausland
        VendorNo := '100022';
        StandardBank := xSWIFT;
        CreateVendor(VendorNo, Text11618, Text11619, Text11620, Text11621, Text11601, Text11602, XEXPORT, Text11552, StandardBank, 'USD', 'US');
        CreateVendorBank(VendorNo, StandardBank, VendorBankAccount."Payment Form"::"SWIFT Payment Abroad",
          VendorBankAccount."ESR Type"::" ", '', 0, 0, '4000', '', '33-555-0.3', '');

        // Rechnung Swift Ausland
        InitGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("Document No.", 'RG-A3');
        GenJournalLine."External Document No." := 'E-' + GenJournalLine."Document No.";
        GenJournalLine.Validate(Amount, -3000.0);
        InsertGenJnlLine(GenJournalLine);

        // // 100023, ZA Ausland
        VendorNo := '100023';
        StandardBank := xCASHOUTABR;
        CreateVendor(VendorNo, Text11625, Text11626, Text11627, Text11628, Text11601, Text11602, Text11603, Text11552, StandardBank, 'EUR', 'DE');
        CreateVendorBank(VendorNo, StandardBank, VendorBankAccount."Payment Form"::"Cash Outpayment Order Abroad",
          VendorBankAccount."ESR Type"::" ", '', 0, 0, '4000', '', '', '');

        // Rechnung Postanweisung Ausland
        InitGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("Document No.", 'RG-A4');
        GenJournalLine."External Document No." := 'E-' + GenJournalLine."Document No.";
        GenJournalLine.Validate(Amount, -4000.0);
        InsertGenJnlLine(GenJournalLine);
    end;

    procedure InitGenJnlLine(var GenJournalLine2: Record "Gen. Journal Line")
    begin
        GenJournalLine2.Init();
        GenJournalLine2."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalLine2."Journal Batch Name" := Text11512;
        NextLineNo := NextLineNo + 10001;
        GenJournalLine2."Line No." := NextLineNo;
        GenJournalLine2."Account Type" := GenJournalLine2."Account Type"::Vendor;
        GenJournalLine2."Document Type" := GenJournalLine2."Document Type"::Invoice;
        GenJournalLine2."Posting Date" := WorkDate();
    end;

    procedure InsertGenJnlLine(var GenJournalLine2: Record "Gen. Journal Line")
    begin
        GenJournalLine2.Insert();

        Window.Update(1, Text11632 + GenJournalLine2."Account No.");
    end;

    procedure CreateVendor(CNo: Code[20]; CName: Text[30]; CAddress: Text[30]; CPostCode: Code[20]; CCity: Text[30]; CVendorPostingGroup: Code[20]; CVATBusPostingGroup: Code[20]; CGenBusPostingGroup: Code[20]; CPaymentTermsCode: Code[10]; CStandardBank: Code[10]; CCurrency: Code[10]; CCountry: Code[10])
    begin
        Vendor.Init();
        Vendor."No." := CNo;
        Vendor.Name := CName;
        Vendor.Address := CAddress;
        Vendor."Post Code" := CPostCode;
        Vendor.City := CCity;
        Vendor."Vendor Posting Group" := CVendorPostingGroup;
        Vendor."VAT Bus. Posting Group" := CVATBusPostingGroup;
        Vendor."Gen. Bus. Posting Group" := CGenBusPostingGroup;
        Vendor."Payment Terms Code" := CPaymentTermsCode;
        Vendor."Preferred Bank Account Code" := CStandardBank;
        Vendor."Currency Code" := CCurrency;
        Vendor."Country/Region Code" := CCountry;

        Vendor.Insert(true);
    end;

    procedure CreateVendorBank(CNo: Code[20]; CCode: Code[10]; CPaymentForm: Option ESR,"ESR+","Post Payment Domestic","Bank Payment Domestic","Cash Outpayment Order Domestic","Post Payment Abroad","Bank Payment Abroad","SWIFT Payment Abroad","Cash Outpayment Order Abroad"; CEsrType: Option " ","5/15","9/27","9/16"; CEsrAccountNo: Code[11]; CStart: Integer; CLength: Integer; CBalanceAcc: Code[20]; CClearing: Code[10]; CBankAcc: Code[20]; CGiroAcc: Code[11])
    begin
        VendorBankAccount.Init();
        VendorBankAccount."Vendor No." := CNo;
        VendorBankAccount.Code := CCode;
        VendorBankAccount."Payment Form" := CPaymentForm;
        VendorBankAccount."ESR Type" := CEsrType;
        VendorBankAccount.Validate("ESR Account No.", CEsrAccountNo);
        VendorBankAccount."Invoice No. Startposition" := CStart;
        VendorBankAccount."Invoice No. Length" := CLength;
        VendorBankAccount.Validate("Balance Account No.", CBalanceAcc);
        VendorBankAccount.Validate("Clearing No.", CClearing);
        VendorBankAccount."Bank Account No." := CBankAcc;
        VendorBankAccount.Validate("Giro Account No.", CGiroAcc);

        case CNo of
            '100021':
                begin
                    VendorBankAccount.Name := 'Bank of Boston';
                    VendorBankAccount.Address := 'Mid River Square';
                    VendorBankAccount.City := 'Boston / MA';
                end;
            '100022':
                VendorBankAccount."SWIFT Code" := 'HIGHROOMBNK';
        end;
        VendorBankAccount.Insert();
    end;
}

