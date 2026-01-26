codeunit 143000 "Library - LSV"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Scope('OnPrem')]
    procedure CreateESRSetup(var ESRSetup: Record "ESR Setup")
    var
        BankAcc: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAcc);

        ESRSetup.Init();
        ESRSetup."Bank Code" := BankAcc."No.";
        ESRSetup.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateLSVSetup(var LSVSetup: Record "LSV Setup"; ESRSetup: Record "ESR Setup"): Code[20]
    var
        BankAcc: Record "Bank Account";
        GLSetup: Record "General Ledger Setup";
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreateBankAccount(BankAcc);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        GLSetup.Get();

        LSVSetup.Init();
        LSVSetup."Bank Code" := BankAcc."No.";
        LSVSetup."LSV Customer ID" := Format(LibraryRandom.RandIntInRange(11111, 99999));
        LSVSetup."LSV Sender ID" := Format(LibraryRandom.RandIntInRange(11111, 99999));
        LSVSetup."LSV Sender Clearing" := Format(LibraryRandom.RandIntInRange(11111, 99999));
        LSVSetup."LSV Payment Method Code" := PaymentMethod.Code;
        LSVSetup."LSV Sender Name" := LibraryUtility.GenerateGUID();
        LSVSetup."LSV Sender City" := LibraryUtility.GenerateGUID();
        LSVSetup."LSV Currency Code" := GLSetup."LCY Code";
        LSVSetup."LSV Sender IBAN" := LibraryUtility.GenerateGUID();
        LSVSetup."ESR Bank Code" := ESRSetup."Bank Code";
        LSVSetup."LSV File Folder" := 'C:\Windows\Temp\' + TenantId() + Format(LibraryRandom.RandInt(10));
        // Cannot use TEMPORARYPATH due to field size.
        LSVSetup."LSV Filename" := LibraryUtility.GenerateGUID();
        LSVSetup."DebitDirect Customerno." := Format(LibraryRandom.RandIntInRange(111111, 999999));
        LSVSetup."DebitDirect Import Filename" := LibraryUtility.GenerateGUID();
        LSVSetup.Insert();

        exit(LSVSetup."Bank Code");
    end;

    [Scope('OnPrem')]
    procedure CreateLSVJournal(var LSVJnl: Record "LSV Journal"; LSVSetup: Record "LSV Setup")
    begin
        LSVJnl.Init();
        LSVJnl.Validate("LSV Bank Code", LSVSetup."Bank Code");
        LSVJnl.Validate("LSV Status", LSVJnl."LSV Status"::Edit);
        LSVJnl.Validate("Credit Date", WorkDate());
        LSVJnl.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateLSVCustomer(var Customer: Record Customer; PaymentMethodCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(City, LibraryUtility.GenerateGUID());
        Customer.Validate("Payment Method Code", PaymentMethodCode);
        Customer.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateLSVCustomerBankAccount(var Customer: Record Customer)
    var
        CustBankAcc: Record "Customer Bank Account";
    begin
        CustBankAcc."Customer No." := Customer."No.";
        CustBankAcc.Code := LibraryUtility.GenerateGUID();
        CustBankAcc."Bank Branch No." := Format(LibraryRandom.RandIntInRange(11111, 99999));
        CustBankAcc.IBAN := LibraryUtility.GenerateGUID();
        CustBankAcc."Giro Account No." := GetRandomGiroAccountNo();
        CustBankAcc.Insert();
    end;

    local procedure GetRandomGiroAccountNo() GiroAccNo: Code[11]
    begin
        GiroAccNo :=
          StrSubstNo('%1-%2-%3', LibraryRandom.RandIntInRange(11, 99),
            LibraryRandom.RandIntInRange(111111, 999999), LibraryRandom.RandIntInRange(1, 9));
    end;
}

