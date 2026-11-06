using System.Environment;

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
        CompanyInformationPage."Bank Branch No.".SetValue('0235');
        CompanyInformationPage."Bank Account No.".SetValue('3276392693');
        CompanyInformationPage."SWIFT Code".SetValue('DABASTAN');
        CompanyInformationPage.IBAN.SetValue('GB 80 RBOS 161732 41116737');
        CompanyInformationPage.BankAccountPostingGroup.SetValue(BankAccPostingGroup.Code);
        CompanyInformationPage.OK().Invoke();

        // verify that a bank account has been created
        CompanyInformation.Get();
        Assert.IsTrue(BankAccount.Get(CompanyBankAccountTxt), 'Bank account ' + CompanyBankAccountTxt + ' not generated.');

        BankAccount.TestField(Name, CompanyInformation."Bank Name");
        BankAccount.TestField("Bank Account No.", CompanyInformation."Bank Account No.");
        BankAccount.TestField("Bank Branch No.", CompanyInformation."Bank Branch No.");
        BankAccount.TestField("SWIFT Code", CompanyInformation."SWIFT Code");
        BankAccount.TestField(IBAN, CompanyInformation.IBAN);
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

    [Test]
    [Scope('OnPrem')]
    procedure PlatformReceivesRequestedCompanyDescription()
    var
        Company: Record Company;
        CompanyInformation: Record "Company Information";
        OtherCompanyInformation: Record "Company Information";
        SystemActionTriggers: Codeunit "System Action Triggers";
        CurrentCompanyName: Text;
        CurrentCompanyDescription: Text;
        ExpectedDescription: Text;
        Description: Text;
    begin
        // [SCENARIO] The platform receives the requested company's description without changing the session's company.
        CurrentCompanyName := CompanyName();
        CurrentCompanyDescription := CreateMultilineDescription('Current company');
        ExpectedDescription := CreateMultilineDescription('Other company');

        // [GIVEN] The current company and another company have different descriptions.
        CompanyInformation.Get();
        CompanyInformation.SetCompanyDescription(CurrentCompanyDescription);
        Company.Name := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(Company.Name));
        Company.Insert();
        OtherCompanyInformation.ChangeCompany(Company.Name);
        OtherCompanyInformation.Insert();
        OtherCompanyInformation.SetCompanyDescription(ExpectedDescription);

        // [WHEN] The platform requests the other company's description.
        SystemActionTriggers.GetCompanyDescription(Company.Name, Description);

        // [THEN] The requested description is returned and the current company is unchanged.
        Assert.AreEqual(ExpectedDescription, Description, 'The platform should receive the requested company description.');
        Assert.AreEqual(CurrentCompanyName, CompanyName(), 'Requesting a description should not change the session company.');
        CompanyInformation.Get();
        Assert.AreEqual(CurrentCompanyDescription, CompanyInformation.GetCompanyDescription(), 'The current company description should not change.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlatformReceivesEmptyDescriptionWithoutCompanyInformation()
    var
        Company: Record Company;
        CompanyInformation: Record "Company Information";
        SystemActionTriggers: Codeunit "System Action Triggers";
        Description: Text;
    begin
        // [SCENARIO] A company without company information does not inherit another company's description.
        CompanyInformation.Get();
        CompanyInformation.SetCompanyDescription(CreateMultilineDescription('Current company'));
        Company.Name := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(Company.Name));
        Company.Insert();
        Description := 'Previous description';

        // [WHEN] The platform requests the new company's description.
        SystemActionTriggers.GetCompanyDescription(Company.Name, Description);

        // [THEN] No stale or current-company description is returned.
        Assert.AreEqual('', Description, 'The platform should receive an empty description when company information is missing.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlatformReceivesEmptyDescriptionForUnknownCompany()
    var
        CompanyInformation: Record "Company Information";
        SystemActionTriggers: Codeunit "System Action Triggers";
        Description: Text;
    begin
        // [SCENARIO] A company that does not exist gets an empty description instead of an error or the current company's description.
        CompanyInformation.Get();
        CompanyInformation.SetCompanyDescription(CreateMultilineDescription('Current company'));
        Description := 'Previous description';

        // [WHEN] The platform requests the description of a company that does not exist.
        SystemActionTriggers.GetCompanyDescription(LibraryUtility.GenerateGUID(), Description);

        // [THEN] An empty description is returned.
        Assert.AreEqual('', Description, 'The platform should receive an empty description for a company that does not exist.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlatformReceivesEmptyCompanyDescription()
    var
        CompanyInformation: Record "Company Information";
        SystemActionTriggers: Codeunit "System Action Triggers";
        Description: Text;
    begin
        // [SCENARIO] An empty company description clears a previously returned value.
        CompanyInformation.Get();
        CompanyInformation.SetCompanyDescription('');
        Description := 'Previous description';

        // [WHEN] The platform requests the current company's description.
        SystemActionTriggers.GetCompanyDescription(CompanyName(), Description);

        // [THEN] The configured empty description is returned.
        Assert.AreEqual('', Description, 'The platform should receive the configured empty company description.');
    end;

    local procedure CreateMultilineDescription(DescriptionType: Text): Text
    var
        DescriptionBuilder: TextBuilder;
    begin
        DescriptionBuilder.AppendLine(DescriptionType + ' description first line');
        DescriptionBuilder.Append(DescriptionType + ' description second line with Unicode: ÆØÅ');
        exit(DescriptionBuilder.ToText());
    end;
}
