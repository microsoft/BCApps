codeunit 144026 "SE Customer Reports"
{
    // 1. Check Total equal to Customer Balance(LCY) exist on Customer Statement Report.
    // 2. Check G/L Account value does not exist on Balance Sheet Report.
    // 3. Check G/L Account value does exists on Balance Sheet Report when ShowAll is set to true
    // 4. Check G/L Account value does not exist on Income Statement Report.
    // 
    //  Bug = 305521
    //  Covers Test cases:
    //  ----------------------------------------------------------------
    //  Test Function Name                                       TFS ID
    //  ----------------------------------------------------------------
    //  CheckTotalOnCustomerStatementReport                      303235
    // 
    //  Bug = 46296
    //  Covers Test cases:
    //   ----------------------------------------------------------------
    //  Test Function Name                                       TFS ID
    //  ----------------------------------------------------------------
    //  CheckValueOnBalanceSheetReport
    //  CheckValueOnIncomeStatementReport
    // 
    //  Bug = 71047
    //  Covers Test cases:
    //   ----------------------------------------------------------------
    //  Test Function Name                                       TFS ID
    //  ----------------------------------------------------------------
    //  CheckValueOnBalanceSheetReportPrintAll

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        BalanceReportErr: Label 'Balance(LCY) %1 must exist in the Report', Comment = '.';

    [Test]
    [Scope('OnPrem')]
    procedure CheckTotalOnCustomerStatementReport()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        "Count": Integer;
    begin
        // Check Total equal to Customer Balance(LCY) exist on Customer Statement Report.

        // Setup: Create and Post Sales Orders for same Customer.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        for Count := 1 to LibraryRandom.RandIntInRange(2, 4) do
            CreateAndPostSalesOrder(SalesHeader, Customer."No.");

        // Exercise: Save Customer Statement Report.
        SaveCustomerStatement(Customer."No.");

        // Verify: Verify Customer.Balance(LCY) exists in Report.
        Customer.CalcFields("Balance (LCY)");
        LibraryReportValidation.OpenFile();
        Assert.IsTrue(
          LibraryReportValidation.CheckIfDecimalValueExists(Customer."Balance (LCY)"),
          StrSubstNo(BalanceReportErr, Customer."Balance (LCY)"));
    end;

    [Test]
    [HandlerFunctions('ReminderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReminderReportCompanyInfoVATRegistrationNoCaption()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [RDLC] [Reminder] [Report Layout]
        // [SCENARIO 337358] Report Reminder prints VAT Registration No. caption for company information section
        Initialize();

        // [GIVEN] Issued reminder 
        MockIssuedReminder(IssuedReminderHeader);

        // [WHEN] Reminder is being printed
        IssuedReminderHeader.SetRecFilter();
        Commit();
        REPORT.Run(REPORT::Reminder, true, false, IssuedReminderHeader);

        // [THEN] VAT Registration No. caption is printed in company information section
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CompanyVATRegistrationNoCaption', CompanyInformation.GetVATRegistrationNumberLbl());
    end;

    local procedure Initialize()
    var
        FeatureKey: Record "Feature Key";
        FeatureKeyUpdateStatus: Record "Feature Data Update Status";
    begin
        if FeatureKey.Get('ReminderTermsCommunicationTexts') then begin
            FeatureKey.Enabled := FeatureKey.Enabled::None;
            FeatureKey.Modify();
        end;
        if FeatureKeyUpdateStatus.Get('ReminderTermsCommunicationTexts', CompanyName()) then begin
            FeatureKeyUpdateStatus."Feature Status" := FeatureKeyUpdateStatus."Feature Status"::Disabled;
            FeatureKeyUpdateStatus.Modify();
        end;
        Clear(LibraryReportValidation);
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;

    local procedure MockIssuedReminder(var IssuedReminderHeader: Record "Issued Reminder Header")
    var
        IssuedReminderLine: Record "Issued Reminder Line";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        IssuedReminderHeader.Init();
        IssuedReminderHeader."No." :=
          LibraryUtility.GenerateRandomCode(IssuedReminderHeader.FieldNo("No."), DATABASE::"Issued Reminder Header");
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup."Additional Fee Account" := '';
        CustomerPostingGroup.Modify();
        IssuedReminderHeader."Customer Posting Group" := CustomerPostingGroup.Code;
        IssuedReminderHeader."Due Date" := LibraryRandom.RandDate(LibraryRandom.RandIntInRange(10, 100));
        IssuedReminderHeader.Insert();
        IssuedReminderLine.Init();
        IssuedReminderLine."Line No." := LibraryUtility.GetNewRecNo(IssuedReminderLine, IssuedReminderLine.FieldNo("Line No."));
        IssuedReminderLine."Line Type" := IssuedReminderLine."Line Type"::"Reminder Line";
        IssuedReminderLine."Reminder No." := IssuedReminderHeader."No.";
        IssuedReminderLine."Due Date" := IssuedReminderHeader."Due Date";
        IssuedReminderLine."Remaining Amount" := LibraryRandom.RandIntInRange(10, 100);
        IssuedReminderLine.Amount := IssuedReminderLine."Remaining Amount";
        IssuedReminderLine.Type := IssuedReminderLine.Type::"G/L Account";
        IssuedReminderLine.Insert();
    end;

    local procedure CreateAndPostSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure SaveCustomerStatement(CustomerNo: Code[20])
    var
        Customer: Record Customer;
        Statement: Report Statement;
        DateChoice: Option "Due Date","Posting Date";
    begin
        Clear(Statement);
        Customer.SetRange("No.", CustomerNo);
        Customer.SetRange("Date Filter", WorkDate());
        Statement.SetTableView(Customer);
        LibraryReportValidation.SetFileName(Customer.TableCaption + Format(CustomerNo));
        Statement.InitializeRequest(false, false, true, false, false, false, '1M+CM', DateChoice::"Due Date", true, WorkDate(), WorkDate());
        Statement.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderRequestPageHandler(var Reminder: TestRequestPage Reminder)
    begin
        Reminder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

