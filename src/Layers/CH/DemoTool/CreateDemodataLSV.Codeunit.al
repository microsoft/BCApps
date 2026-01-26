codeunit 161558 "Create Demodata LSV"
{

    trigger OnRun()
    begin
        d.Open(Text11509);

        ClearLSVJournal();

        WriteSetup();
        ChangeCustomerBank();
        ModifyPaymentType();
        d.Close();
    end;

    var
        Text11509: Label 'Generate LSV demo data.';
        XGIRO: Label 'GIRO';
        Text11512: Label 'CRON2';
        Text11516: Label 'Dear Sir or Madam';
        Text11517: Label 'Next year we would like to reduce the administrative costs for payments ';
        Text11518: Label 'for you and us.  We ask you to please return this form ';
        Text11519: Label 'with the required information included and signed.';
        Text11520: Label 'Telekurs Payserv AG';
        Text11521: Label 'Computer Bureau';
        Text11522: Label 'Parcel Post Box';
        Text11523: Label 'Zürich 1';
        Text11524: Label 'Credit Suisse';
        Text11525: Label 'Bahnhofstrasse 17';
        Text11526: Label 'Zug';
        Text11529: Label 'Raiffeisenbank Alpnach';
        Text11530: Label 'Alpnach Dorf';
        Text11531: Label 'Obwaldner Kantonalbank';
        Text11532: Label 'Brünigstrasse';
        Text11533: Label 'Migrosbank Luzern';
        Text11534: Label 'Stadthofstrasse';
        Text11535: Label 'Luzern';
        Text11536: Label 'Coop Bank';
        Text11537: Label 'Luzerner Kantonalbank';
        Text11538: Label 'Customer with LSV Collection';
        XNBL: Label 'NBL';
        LsvSetup: Record "LSV Setup";
        CustomerBankAccount: Record "Customer Bank Account";
        PaymentMethod: Record "Payment Method";
        Customer: Record Customer;
        LsvJournal: Record "LSV Journal";
        LSVJournalLine: Record "LSV Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        d: Dialog;
        XWWBEUR: Label 'WWB-EUR';

    procedure WriteSetup()
    begin
        LsvSetup.Init();
        LsvSetup."Bank Code" := XGIRO;
        LsvSetup."LSV Customer ID" := Text11512;
        LsvSetup."LSV Sender ID" := Text11512;
        LsvSetup."LSV Sender Clearing" := '4823';
        LsvSetup."LSV Payment Method Code" := 'LSV';
        LsvSetup."ESR Bank Code" := XGIRO;
        LsvSetup."LSV Currency Code" := 'CHF';
        LsvSetup."LSV Sender IBAN" := 'CH9300762011623852957';
        LsvSetup."LSV Customer Bank Code" := 'LSV';
        LsvSetup."DebitDirect Customerno." := '909700';

        LsvSetup."Bal. Account No." := '1020';
        LsvSetup."LSV File Folder" := 'c:\';
        LsvSetup."LSV Filename" := 'DTALSV';
        LsvSetup.Text := Text11516;
        LsvSetup."Text 2" :=
          Text11517 +
          Text11518 +
          Text11519;

        LsvSetup."Computer Bureau Name" := Text11520;
        LsvSetup."Computer Bureau Name 2" := Text11521;
        LsvSetup."Computer Bureau Address" := Text11522;
        LsvSetup."Computer Bureau Post Code" := '8021';
        LsvSetup."Computer Bureau City" := Text11523;
        LsvSetup."Computer Bureau E-Mail" := '';
        LsvSetup."Computer Bureau Home Page" := '';
        LsvSetup."LSV Bank Name" := Text11524;
        LsvSetup."LSV Bank Name 2" := '';
        LsvSetup."LSV Bank Address" := Text11525;
        LsvSetup."LSV Bank Post Code" := '6301';
        LsvSetup."LSV Bank City" := Text11526;
        LsvSetup."LSV Bank E-Mail" := '';
        LsvSetup."LSV Bank Home Page" := '';
        LsvSetup."LSV Bank Transfer Hyperlink" := 'https://gate.sic.ch';
        if not LsvSetup.Insert(true) then
            LsvSetup.Modify();

        LsvSetup.Init();
        LsvSetup."Bank Code" := XWWBEUR;
        LsvSetup."LSV Customer ID" := Text11512;
        LsvSetup."LSV Sender ID" := Text11512;
        LsvSetup."LSV Sender Clearing" := '423';
        LsvSetup."LSV Payment Method Code" := 'LSV';
        LsvSetup."ESR Bank Code" := XNBL;
        LsvSetup."LSV Currency Code" := 'EUR';
        LsvSetup."LSV Sender IBAN" := 'CH9300762011623852957';
        LsvSetup."LSV Customer Bank Code" := 'LSV';
        LsvSetup."DebitDirect Customerno." := '909700';

        LsvSetup."Bal. Account No." := '1020';
        LsvSetup."LSV File Folder" := 'c:\';
        LsvSetup."LSV Filename" := 'DTALSV';
        LsvSetup.Text := Text11516;
        LsvSetup."Text 2" :=
          Text11517 +
          Text11518 +
          Text11519;

        LsvSetup."Computer Bureau Name" := Text11520;
        LsvSetup."Computer Bureau Name 2" := Text11521;
        LsvSetup."Computer Bureau Address" := Text11522;
        LsvSetup."Computer Bureau Post Code" := '8021';
        LsvSetup."Computer Bureau City" := Text11523;
        LsvSetup."Computer Bureau E-Mail" := '';
        LsvSetup."Computer Bureau Home Page" := '';
        LsvSetup."LSV Bank Name" := Text11524;
        LsvSetup."LSV Bank Name 2" := '';
        LsvSetup."LSV Bank Address" := Text11525;
        LsvSetup."LSV Bank Post Code" := '6301';
        LsvSetup."LSV Bank City" := Text11526;
        LsvSetup."LSV Bank E-Mail" := '';
        LsvSetup."LSV Bank Home Page" := '';
        if not LsvSetup.Insert(true) then
            LsvSetup.Modify();
    end;

    procedure ChangeCustomerBank()
    var
        BankDirectory: Record "Bank Directory";
    begin
        if BankDirectory.IsEmpty() then
            CODEUNIT.Run(CODEUNIT::"Bank Directory");
        CustomerBankAccount.Init();
        CustomerBankAccount."Customer No." := '10000';
        CustomerBankAccount.Code := 'LSV';
        CustomerBankAccount.Name := Text11529;
        CustomerBankAccount.Address := '';
        CustomerBankAccount."Post Code" := '6055';
        CustomerBankAccount.City := Text11530;
        CustomerBankAccount.Validate("Bank Branch No.", '81232');
        CustomerBankAccount."Bank Account No." := '34124.24';
        CustomerBankAccount.Validate("Giro Account No.", '01-28302-7');
        if not CustomerBankAccount.Insert() then
            CustomerBankAccount.Modify();

        CustomerBankAccount.Init();
        CustomerBankAccount."Customer No." := '20000';
        CustomerBankAccount.Code := 'LSV';
        CustomerBankAccount.Name := Text11531;
        CustomerBankAccount.Address := Text11532;
        CustomerBankAccount."Post Code" := '6055';
        CustomerBankAccount.City := Text11530;
        CustomerBankAccount.Validate("Bank Branch No.", '780');
        CustomerBankAccount."Bank Account No." := '01-30-033237-00';
        CustomerBankAccount.Validate("Giro Account No.", '01-17601-2');
        if not CustomerBankAccount.Insert() then
            CustomerBankAccount.Modify();

        CustomerBankAccount.Init();
        CustomerBankAccount."Customer No." := '30000';
        CustomerBankAccount.Code := 'LSV';
        CustomerBankAccount.Name := Text11533;
        CustomerBankAccount.Address := Text11534;
        CustomerBankAccount."Post Code" := '6002';
        CustomerBankAccount.City := Text11535;
        CustomerBankAccount.Validate("Bank Branch No.", '8411');
        CustomerBankAccount."Bank Account No." := '421-740-018.10';
        CustomerBankAccount.Validate("Giro Account No.", '01-1760-2');
        if not CustomerBankAccount.Insert() then
            CustomerBankAccount.Modify();

        CustomerBankAccount.Init();
        CustomerBankAccount."Customer No." := '40000';
        CustomerBankAccount.Code := 'LSV';
        CustomerBankAccount.Name := Text11536;
        CustomerBankAccount.Address := '';
        CustomerBankAccount."Post Code" := '6002';
        CustomerBankAccount.City := Text11535;
        CustomerBankAccount.Validate("Bank Branch No.", '8450');
        CustomerBankAccount."Bank Account No." := '4178933000506';
        CustomerBankAccount.Validate("Giro Account No.", '10-1010-6');
        if not CustomerBankAccount.Insert() then
            CustomerBankAccount.Modify();

        CustomerBankAccount.Init();
        CustomerBankAccount."Customer No." := '50000';
        CustomerBankAccount.Code := 'LSV';
        CustomerBankAccount.Name := Text11537;
        CustomerBankAccount.Address := '';
        CustomerBankAccount."Post Code" := '6002';
        CustomerBankAccount.City := Text11535;
        CustomerBankAccount.Validate("Bank Branch No.", '778');
        CustomerBankAccount."Bank Account No." := '01-00-036430-00';
        CustomerBankAccount.Validate("Giro Account No.", '80-70-2');
        if not CustomerBankAccount.Insert() then
            CustomerBankAccount.Modify();
    end;

    procedure ModifyPaymentType()
    begin
        PaymentMethod.Init();
        PaymentMethod.Code := 'LSV';
        PaymentMethod.Description := Text11538;
        if not PaymentMethod.Insert() then
            PaymentMethod.Modify();

        Customer.SetRange("No.", '30000', '50000');
        Customer.ModifyAll("Payment Method Code", 'LSV');
    end;

    procedure ClearLSVJournal()
    begin
        LsvJournal.DeleteAll();
        LSVJournalLine.DeleteAll();
        CustLedgerEntry.SetCurrentKey("LSV No.");
        CustLedgerEntry.SetFilter("LSV No.", '>%1', 0);
        CustLedgerEntry.ModifyAll("On Hold", '');
        CustLedgerEntry.ModifyAll("LSV No.", 0);
    end;

    procedure FillJournal()
    begin
        LsvJournal.Init();
        LsvJournal.Validate("LSV Bank Code", XGIRO);
        LsvJournal.Insert(true);

        LsvJournal.Init();
        LsvJournal.Validate("LSV Bank Code", XGIRO + 'EUR');
        LsvJournal.Insert(true);
    end;
}

