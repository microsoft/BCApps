codeunit 136580 "Email Address Selection"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Email]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CustomerEmailTok: Label 'Customer@consoto.com';
        SalesHeaderEmailTok: Label 'SalesHeader@consoto.com';

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNoEmail()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ReportSelections: Record "Report Selections";
        TempBlob: Codeunit "Temp Blob";
        SendToEmail: Text[250];
    begin
        // [GIVEN] A newly setup Customer with No email
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer."E-Mail" := '';
        Customer.Modify();

        // [WHEN] An Order is created
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        ReportSelections.GetEmailBodyTextForCust(
            TempBlob, "Report Selection Usage".FromInteger(GetOrderConfirmationId()), SalesHeader, Customer."No.", SendToEmail, '');
        // [THEN] No email should be found for this document
        Assert.IsTrue(SendToEmail = '', 'Send to ' + SendToEmail + 'Expected no email');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyEmailFromOnSalesHeaderFromCustomer()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ReportSelections: Record "Report Selections";
        TempBlob: Codeunit "Temp Blob";
        SendToEmail: Text[250];
    begin
        // [GIVEN] A newly setup Customer with email
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer."E-Mail" := CustomerEmailTok;
        Customer.Modify();

        // [WHEN] A sales order is created
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [THEN] The document should be send to the email from the contact
        ReportSelections.GetEmailBodyTextForCust(
            TempBlob, "Report Selection Usage".FromInteger(GetOrderConfirmationId()), SalesHeader, Customer."No.", SendToEmail, '');
        Assert.IsTrue(SendToEmail = CustomerEmailTok, 'Send to ' + SendToEmail + 'Expected ' + CustomerEmailTok);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyEmailFromOnSalesHeaderFromSalesHeader()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ReportSelections: Record "Report Selections";
        TempBlob: Codeunit "Temp Blob";
        SendToEmail: Text[250];
    begin
        // [GIVEN] A newly setup Customer with email and sales header specific email address
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] The Email Logging Setup Wizard is run to the end but not finished
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader."Sell-to E-Mail" := SalesHeaderEmailTok;
        SalesHeader.Modify();
        ReportSelections.GetEmailBodyTextForCust(
            TempBlob, "REport Selection Usage".FromInteger(GetOrderConfirmationId()), SalesHeader, Customer."No.", SendToEmail, '');
        SalesHeader."Sell-to E-Mail" := SalesHeaderEmailTok;
        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsTrue(SendToEmail = SalesHeaderEmailTok, 'Send to ' + SendToEmail + ' Expected ' + SalesHeaderEmailTok);
    end;

    local procedure Initialize();
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Email Address Selection");
    end;

    local procedure GetOrderConfirmationId(): Integer
    begin
        exit(REPORT::"Standard Sales - Order Conf.");
    end;
}

