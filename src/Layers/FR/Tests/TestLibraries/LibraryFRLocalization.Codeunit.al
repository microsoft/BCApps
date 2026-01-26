codeunit 143000 "Library - FR Localization"
{
    // Library containing functions specific to FR Localization objects, hence meant to be kept at FR Branch Only.


    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";

    [Scope('OnPrem')]
    procedure CreateCustomerBankAccount(var CustomerBankAccount: Record "Customer Bank Account"; CustomerNo: Code[20])
    begin
        CustomerBankAccount.Init();
        CustomerBankAccount.Validate("Customer No.", CustomerNo);
        CustomerBankAccount.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo(Code), DATABASE::"Customer Bank Account"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Customer Bank Account", CustomerBankAccount.FieldNo(Code))));
        CustomerBankAccount.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePaymentClass(var PaymentClass: Record "Payment Class")
    begin
        PaymentClass.Init();
        PaymentClass.Validate(Code, LibraryUtility.GenerateRandomCode(PaymentClass.FieldNo(Code), DATABASE::"Payment Class"));
        PaymentClass.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePaymentHeader(var PaymentHeader: Record "Payment Header")
    begin
        PaymentHeader.Init();
        PaymentHeader.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePaymentLine(var PaymentLine: Record "Payment Line"; No: Code[20])
    var
        RecRef: RecordRef;
    begin
        PaymentLine.Init();
        PaymentLine.Validate("No.", No);
        RecRef.GetTable(PaymentLine);
        PaymentLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, PaymentLine.FieldNo("Line No.")));
        PaymentLine.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePaymentStatus(var PaymentStatus: Record "Payment Status"; PaymentClass: Text[30])
    var
        RecRef: RecordRef;
    begin
        PaymentStatus.Init();
        PaymentStatus.Validate("Payment Class", PaymentClass);
        RecRef.GetTable(PaymentStatus);
        PaymentStatus.Validate(Line, LibraryUtility.GetNewLineNo(RecRef, PaymentStatus.FieldNo(Line)));
        PaymentStatus.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePaymentStep(var PaymentStep: Record "Payment Step"; PaymentClass: Text[30])
    var
        RecRef: RecordRef;
    begin
        PaymentStep.Init();
        PaymentStep.Validate("Payment Class", PaymentClass);
        RecRef.GetTable(PaymentStep);
        PaymentStep.Validate(Line, LibraryUtility.GetNewLineNo(RecRef, PaymentStep.FieldNo(Line)));
        PaymentStep.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePaymentStepLedger(var PaymentStepLedger: Record "Payment Step Ledger"; PaymentClass: Text[30]; Sign: Option; Line: Integer)
    begin
        PaymentStepLedger.Init();
        PaymentStepLedger.Validate("Payment Class", PaymentClass);
        PaymentStepLedger.Validate(Sign, Sign);
        PaymentStepLedger.Validate(Line, Line);
        PaymentStepLedger.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePaymentSlip()
    begin
        CODEUNIT.Run(CODEUNIT::"Payment Management");
    end;
}

