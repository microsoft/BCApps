codeunit 138041 "O365 Company Information"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Company Information] [Bank Account] [SMB]
    end;

    var
        CompanyBankAccountTxt: Label 'CompanyBankAccount';
        XPAYMENTTxt: Label 'PAYMENT', Comment = 'Payment';
        XPmtRegTxt: Label 'PMT REG', Comment = 'Payment Registration';
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountCreatedAfterClosingPage()
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        CompanyInformation: Record "Company Information";
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        BankAccPostingGroup: Record "Bank Account Posting Group";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        CompanyInformationPage: TestPage "Company Information";
    begin
        LibraryApplicationArea.EnableFoundationSetup();

        // delete company bank account
        if BankAccount.Get(CompanyBankAccountTxt) then
            BankAccount.Delete();

        if GenJournalBatch.Get(XPAYMENTTxt, XPmtRegTxt) then begin
            GenJournalBatch."Bal. Account No." := '';
            GenJournalBatch.Modify();
        end;

        // fill out bank account information in Company Information page
        BankAccPostingGroup.FindLast();

        CompanyInformationPage.OpenEdit();
        CompanyInformationPage."Bank Name".SetValue('Stans Bank');
        CompanyInformationPage."CCC Bank No.".SetValue('1111');
        CompanyInformationPage."CCC Bank Branch No.".SetValue('2222');
        CompanyInformationPage."CCC Control Digits".SetValue('33');
        CompanyInformationPage."CCC Bank Account No.".SetValue('1234567890');
        CompanyInformationPage."CCC No.".SetValue('11112222331234567890');
        CompanyInformationPage.BankAccountPostingGroup.SetValue(BankAccPostingGroup.Code);
        CompanyInformationPage.OK().Invoke();

        // verify that a bank account has been created
        CompanyInformation.Get();
        Assert.IsTrue(BankAccount.Get(CompanyBankAccountTxt), 'Bank account ' + CompanyBankAccountTxt + ' not generated.');

        BankAccount.TestField(Name, CompanyInformation."Bank Name");
        BankAccount.TestField("CCC Bank Account No.", CompanyInformation."CCC Bank Account No.");
        BankAccount.TestField("CCC Bank Branch No.", CompanyInformation."CCC Bank Branch No.");
        BankAccount.TestField("CCC Control Digits", CompanyInformation."CCC Control Digits");
        BankAccount.TestField("CCC Bank No.", CompanyInformation."CCC Bank No.");
        BankAccount.TestField("CCC No.", CompanyInformation."CCC No.");
        BankAccount.TestField("Bank Acc. Posting Group", BankAccPostingGroup.Code);

        // verify that payment registration General Journal Batch points to the company bank account
        if GenJournalBatch.Get(XPAYMENTTxt, XPmtRegTxt) then
            GenJournalBatch.TestField("Bal. Account No.", BankAccount."No.");

        // verify that payment registration setup points to to the company bank account
        if PaymentRegistrationSetup.Get(UserId) then begin
            PaymentRegistrationSetup.TestField("Journal Template Name", XPAYMENTTxt);
            PaymentRegistrationSetup.TestField("Journal Batch Name", XPmtRegTxt);
            PaymentRegistrationSetup.TestField("Bal. Account Type", PaymentRegistrationSetup."Bal. Account Type"::"Bank Account");
            PaymentRegistrationSetup.TestField("Bal. Account No.", BankAccount."No.");
        end;
        // Modify bank name
        CompanyInformationPage.OpenEdit();
        CompanyInformationPage."Bank Name".SetValue(CompanyInformationPage."Bank Name".Value + CompanyInformationPage."Bank Name".Value);
        CompanyInformationPage.OK().Invoke();

        // Verify that company bank account has been updated
        BankAccount.TestField(Name, CompanyInformation."Bank Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NameChangeInCompInfChangesCompanyDisplayName()
    var
        Company: Record Company;
        CompanyInformation: TestPage "Company Information";
        NewCompanyName: Code[10];
    begin
        // Validate that changing company name in the company information table changes the company display name

        CompanyInformation.OpenEdit();

        NewCompanyName := LibraryUtility.GenerateGUID();
        CompanyInformation.Name.SetValue(NewCompanyName);
        CompanyInformation.Close();

        Company.Get(CompanyName);
        Company.TestField("Display Name", NewCompanyName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountPostingGroupSaveOnPageAfterReopenCompanyInvormationPage()
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        CompanyInformation: TestPage "Company Information";
    begin
        // [SCENARIO 373047] "Bank Account Posting Group" do not reset to blank after reopen "Company Information" page
        // [GIVEN] Create Bank Account Posting Group
        LibraryERM.CreateBankAccountPostingGroup(BankAccountPostingGroup);

        // [GIVEN] Opened "Company Information" page and change "Bank Account Posting Group"
        CompanyInformation.OpenEdit();
        CompanyInformation.BankAccountPostingGroup.SetValue(BankAccountPostingGroup.Code);

        // [WHEN] Reopen "Company Information" page
        CompanyInformation.Close();
        CompanyInformation.OpenEdit();

        // [THEN] BankAccountPostingGroup is populated
        CompanyInformation.BankAccountPostingGroup.AssertEquals(BankAccountPostingGroup.Code);
        CompanyInformation.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyRegistrationNoIsEditable()
    var
        CompanyInformation: Record "Company Information";
        CompanyInformationPage: TestPage "Company Information";
        RegistrationNo: Text[50];
    begin
        // [SCENARIO 359959] Registration No. field is editable on the Company Information page
        CompanyInformationPage.OpenEdit();

        RegistrationNo := LibraryUtility.GenerateGUID();
        CompanyInformationPage."Registration No.".SetValue(RegistrationNo);
        CompanyInformationPage.Close();

        CompanyInformation.Get();
        CompanyInformation.TestField("Registration No.", RegistrationNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DescriptionsSupportMultilineText()
    var
        CompanyInformation: Record "Company Information";
        EnvironmentInformation: Codeunit "Environment Information";
        CompanyDescription: Text;
        EnvironmentDescription: Text;
    begin
        // [SCENARIO] Company and environment descriptions support multiline Unicode text.
        CompanyDescription := CreateMultilineDescription('Company');
        EnvironmentDescription := CreateMultilineDescription('Environment');

        // [GIVEN] Multiline descriptions are saved.
        CompanyInformation.Get();
        CompanyInformation.SetCompanyDescription(CompanyDescription);
        EnvironmentInformation.SetEnvironmentDescription(EnvironmentDescription);

        // [THEN] The complete descriptions can be read.
        CompanyInformation.Get();
        Assert.AreEqual(CompanyDescription, CompanyInformation.GetCompanyDescription(), 'The company description is incorrect.');
        Assert.AreEqual(EnvironmentDescription, EnvironmentInformation.GetEnvironmentDescription(), 'The environment description is incorrect.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DescriptionsAreEditableOnCompanyInformationPage()
    var
        CompanyInformation: Record "Company Information";
        EnvironmentInformation: Codeunit "Environment Information";
        CompanyInformationPage: TestPage "Company Information";
        CompanyDescription: Text;
        EnvironmentDescription: Text;
    begin
        // [SCENARIO] Company and environment descriptions can be edited on the Company Information page.
        CompanyDescription := CreateMultilineDescription('Company page');
        EnvironmentDescription := CreateMultilineDescription('Environment page');

        // [WHEN] The descriptions are entered on the Company Information page.
        CompanyInformationPage.OpenEdit();
        CompanyInformationPage.CompanyDescription.SetValue(CompanyDescription);
        CompanyInformationPage.EnvironmentDescription.SetValue(EnvironmentDescription);
        CompanyInformationPage.Close();

        // [THEN] Both descriptions are saved to their respective scopes.
        CompanyInformation.Get();
        Assert.AreEqual(CompanyDescription, CompanyInformation.GetCompanyDescription(), 'The company description was not saved.');
        Assert.AreEqual(EnvironmentDescription, EnvironmentInformation.GetEnvironmentDescription(), 'The environment description was not saved.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClosingCompanyInformationPageDoesNotOverwriteDescriptions()
    var
        CompanyInformation: Record "Company Information";
        EnvironmentInformation: Codeunit "Environment Information";
        CompanyInformationPage: TestPage "Company Information";
        CompanyDescription: Text;
        EnvironmentDescription: Text;
    begin
        // [SCENARIO] Closing the Company Information page does not overwrite descriptions changed after the page was opened.
        CompanyDescription := CreateMultilineDescription('Updated company');
        EnvironmentDescription := CreateMultilineDescription('Updated environment');

        // [GIVEN] The Company Information page is open with the current descriptions.
        CompanyInformationPage.OpenEdit();

        // [WHEN] The descriptions are changed without editing their fields on the open page.
        CompanyInformation.Get();
        CompanyInformation.SetCompanyDescription(CompanyDescription);
        EnvironmentInformation.SetEnvironmentDescription(EnvironmentDescription);
        CompanyInformationPage.Close();

        // [THEN] Closing the page preserves the updated descriptions.
        CompanyInformation.Get();
        Assert.AreEqual(CompanyDescription, CompanyInformation.GetCompanyDescription(), 'The company description was overwritten.');
        Assert.AreEqual(EnvironmentDescription, EnvironmentInformation.GetEnvironmentDescription(), 'The environment description was overwritten.');
    end;
    local procedure CreateMultilineDescription(DescriptionType: Text): Text
    var
        DescriptionBuilder: TextBuilder;
    begin
        DescriptionBuilder.AppendLine(DescriptionType + ' description first line');
        DescriptionBuilder.AppendLine(DescriptionType + ' description second line with Unicode: ÆØÅ');
        exit(DescriptionBuilder.ToText());
    end;
}
