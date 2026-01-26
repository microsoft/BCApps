codeunit 141039 "UT PAG Electronic Payment"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Electronic Payment] [UI]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        Assert: Codeunit Assert;
        ControlEnabledMsg: Label 'Control must be enabled';
        ControlDisabledMsg: Label 'Control must be disabled';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateExportFormatUSBankAccountCard()
    var
        BankAccount: Record "Bank Account";
        BankAccountCard: TestPage "Bank Account Card";
        BankAccountNo: Code[20];
    begin
        // Purpose of the test is to validate Export Format - OnValidate Trigger of Page ID - 370 Bank Account Card.
        // Setup.
        BankAccountNo := CreateBankAccount();

        // Exercise.
        ExportFormatBankAccountCard(BankAccountCard, BankAccountNo, BankAccount."Export Format"::US);

        // Verify: Verify various fields are Enabled or Disabled with respect to Export Format US on Bank Account Card.
        Assert.IsTrue(BankAccountCard."SWIFT Code".Enabled(), ControlEnabledMsg);
        Assert.IsTrue(BankAccountCard.IBAN.Enabled(), ControlEnabledMsg);
        Assert.IsFalse(BankAccountCard."Client No.".Enabled(), ControlDisabledMsg);
        Assert.IsFalse(BankAccountCard."Client Name".Enabled(), ControlDisabledMsg);
        BankAccountCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateExportFormatMXBankAccountCard()
    var
        BankAccount: Record "Bank Account";
        BankAccountCard: TestPage "Bank Account Card";
        BankAccountNo: Code[20];
    begin
        // Purpose of the test is to validate Export Format - OnValidate Trigger of Page ID - 370 Bank Account Card.
        // Setup.
        BankAccountNo := CreateBankAccount();

        // Exercise.
        ExportFormatBankAccountCard(BankAccountCard, BankAccountNo, BankAccount."Export Format"::MX);

        // Verify: Verify various fields are Enabled or Disabled with respect to Export Format MX on Bank Account Card.
        Assert.IsTrue(BankAccountCard."SWIFT Code".Enabled(), ControlEnabledMsg);
        Assert.IsTrue(BankAccountCard.IBAN.Enabled(), ControlEnabledMsg);
        Assert.IsFalse(BankAccountCard."Client No.".Enabled(), ControlDisabledMsg);
        Assert.IsFalse(BankAccountCard."Client Name".Enabled(), ControlDisabledMsg);
        BankAccountCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateExportFormatCABankAccountCard()
    var
        BankAccount: Record "Bank Account";
        BankAccountCard: TestPage "Bank Account Card";
        BankAccountNo: Code[20];
    begin
        // Purpose of the test is to validate Export Format - OnValidate Trigger of Page ID - 370 Bank Account Card.
        // Setup.
        BankAccountNo := CreateBankAccount();

        // Exercise.
        ExportFormatBankAccountCard(BankAccountCard, BankAccountNo, BankAccount."Export Format"::CA);

        // Verify: Verify various fields are Enabled or Disabled with respect to Export Format CA on Bank Account Card.
        Assert.IsTrue(BankAccountCard."SWIFT Code".Enabled(), ControlEnabledMsg);
        Assert.IsTrue(BankAccountCard.IBAN.Enabled(), ControlEnabledMsg);
        Assert.IsTrue(BankAccountCard."Client No.".Enabled(), ControlDisabledMsg);
        Assert.IsTrue(BankAccountCard."Client Name".Enabled(), ControlDisabledMsg);
        BankAccountCard.Close();
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure ExportFormatBankAccountCard(BankAccountCard: TestPage "Bank Account Card"; No: Code[20]; ExportFormat: Option)
    begin
        BankAccountCard.OpenEdit();
        BankAccountCard.FILTER.SetFilter("No.", No);
        BankAccountCard."Export Format".SetValue(ExportFormat);
    end;
}

