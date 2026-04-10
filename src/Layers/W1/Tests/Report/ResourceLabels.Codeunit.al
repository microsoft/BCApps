codeunit 136904 "Resource - Labels"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reports] [Labels]
    end;

    var
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryMarketing: Codeunit "Library - Marketing";
        isInitialized: Boolean;
        EmployeeAddrCap: Label 'EmployeeAddr_%1__%2_', Locked = true;
        ContactLabelAddrCap: Label 'ContAddr_%1__%2_', Locked = true;
        SegmentLabelAddrCap: Label 'ContAddr%1%2', Locked = true;
        ServiceitemLabelAddrCap: Label 'Addr%1%2', Locked = true;

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Resource - Labels");
        LibraryApplicationArea.EnableFoundationSetup();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Resource - Labels");

        LibraryService.SetupServiceMgtNoSeries();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Resource - Labels");
    end;

    [Test]
    [HandlerFunctions('ContactLabelsReportsHandler')]
    [Scope('OnPrem')]
    procedure ContactLabels36x70mm3Columns()
    var
        LabelFormatFrom: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
    begin
        // Test that the Contact - Labels report is generated properly in 36 x 70 mm (3 columns) format.

        ContactLabelsReport(LabelFormatFrom::"36 x 70 mm (3 columns)");
    end;

    [Test]
    [HandlerFunctions('ContactLabelsReportsHandler')]
    [Scope('OnPrem')]
    procedure ContactLabels37x70mm3Columns()
    var
        LabelFormatFrom: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
    begin
        // Test that the Contact - Labels report is generated properly in 37 x 70 mm (3 columns) format.

        ContactLabelsReport(LabelFormatFrom::"37 x 70 mm (3 columns)");
    end;

    [Test]
    [HandlerFunctions('ContactLabelsReportsHandler')]
    [Scope('OnPrem')]
    procedure ContactLabels36x105mm2Columns()
    var
        LabelFormatFrom: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
    begin
        // Test that the Contact - Labels report is generated properly in 36 x 105 mm (2 columns) format.

        ContactLabelsReport(LabelFormatFrom::"36 x 105 mm (2 columns)");
    end;

    [Test]
    [HandlerFunctions('ContactLabelsReportsHandler')]
    [Scope('OnPrem')]
    procedure ContactLabels37x105mm2Columns()
    var
        LabelFormatFrom: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
    begin
        // Test that the Contact - Labels report is generated properly in 37 x 105 mm (2 columns) format.

        ContactLabelsReport(LabelFormatFrom::"37 x 105 mm (2 columns)");
    end;

    local procedure ContactLabelsReport(LabelFormatFrom: Option)
    var
        Contact: Record Contact;
        Contact2: Record Contact;
        Contact3: Record Contact;
        FilterExpression: Text[250];
    begin
        // 1. Setup: Create three new Contacts.
        Initialize();
        CreateContactWithAddress(Contact);
        CreateContactWithAddress(Contact2);
        CreateContactWithAddress(Contact3);

        // 2. Exercise: Generate the Contact - Labels report.
        FilterExpression := Contact."No." + '|' + Contact2."No." + '|' + Contact3."No.";
        RunContactLabelsReport(FilterExpression, LabelFormatFrom);

        // 3. Verify: Check that the report is generated properly.
        LibraryReportDataset.LoadDataSetFile();
        VerifyContactLabels(Contact, ContactLabelAddrCap);
        VerifyContactLabels(Contact2, ContactLabelAddrCap);
        VerifyContactLabels(Contact3, ContactLabelAddrCap);
    end;

    [Test]
    [HandlerFunctions('SegmentLabelReportsHandler')]
    [Scope('OnPrem')]
    procedure SegmentLabels36x70mm3Columns()
    var
        LabelFormatFrom: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
    begin
        // Test that the Segment - Labels report is generated properly in 36 x 70 mm (3 columns) format.

        SegmentLabelsReport(LabelFormatFrom::"36 x 70 mm (3 columns)");
    end;

    [Test]
    [HandlerFunctions('SegmentLabelReportsHandler')]
    [Scope('OnPrem')]
    procedure SegmentLabels37x70mm3Columns()
    var
        LabelFormatFrom: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
    begin
        // Test that the Segment - Labels report is generated properly in 37 x 70 mm (3 columns) format.

        SegmentLabelsReport(LabelFormatFrom::"37 x 70 mm (3 columns)");
    end;

    [Test]
    [HandlerFunctions('SegmentLabelReportsHandler')]
    [Scope('OnPrem')]
    procedure SegmentLabels36x105mm2Columns()
    var
        LabelFormatFrom: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
    begin
        // Test that the Segment - Labels report is generated properly in 36 x 105 mm (2 columns) format.

        SegmentLabelsReport(LabelFormatFrom::"36 x 105 mm (2 columns)");
    end;

    [Test]
    [HandlerFunctions('SegmentLabelReportsHandler')]
    [Scope('OnPrem')]
    procedure SegmentLabels37x105mm2Columns()
    var
        LabelFormatFrom: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
    begin
        // Test that the Segment - Labels report is generated properly in 37 x 105 mm (2 columns) format.

        SegmentLabelsReport(LabelFormatFrom::"37 x 105 mm (2 columns)");
    end;

    local procedure SegmentLabelsReport(LabelFormatFrom: Option)
    var
        SegmentHeader: Record "Segment Header";
        Contact: Record Contact;
        SegmentHeader2: Record "Segment Header";
        Contact2: Record Contact;
        SegmentHeader3: Record "Segment Header";
        Contact3: Record Contact;
        LibraryMarketing: Codeunit "Library - Marketing";
        FilterExpression: Text[250];
    begin
        // 1. Setup: Create three new Contacts and Segment Headers. Add Contacts to Segments by running Add Contacts.
        Initialize();
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        CreateContactWithAddress(Contact);
        AddContactsToSegment(Contact, SegmentHeader);

        LibraryMarketing.CreateSegmentHeader(SegmentHeader2);
        CreateContactWithAddress(Contact2);
        AddContactsToSegment(Contact2, SegmentHeader2);

        LibraryMarketing.CreateSegmentHeader(SegmentHeader3);
        CreateContactWithAddress(Contact3);
        AddContactsToSegment(Contact3, SegmentHeader3);

        // 2. Exercise: Generate the Segment - Labels report.
        FilterExpression := SegmentHeader."No." + '|' + SegmentHeader2."No." + '|' + SegmentHeader3."No.";
        RunSegmentLabelsReport(FilterExpression, LabelFormatFrom);

        // 3. Verify: Check that the report is generated properly.
        LibraryReportDataset.LoadDataSetFile();
        VerifyContactLabels(Contact, SegmentLabelAddrCap);
        VerifyContactLabels(Contact2, SegmentLabelAddrCap);
        VerifyContactLabels(Contact3, SegmentLabelAddrCap);
    end;

    [Test]
    [HandlerFunctions('SerivceItemLabelsReportsHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemLineLabelsReport()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceItemLineLabels: Report "Service Item Line Labels";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // Test that the Service Item Line Labels report is generated properly.

        // 1. Setup: Create Service Header, Service Item, Service Item Line.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // 2. Exercise: Generate the Service Item Line Labels report.
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        Clear(ServiceItemLineLabels);
        ServiceItemLineLabels.SetTableView(ServiceItemLine);
        Commit();
        ServiceItemLineLabels.Run();

        // 3. Verify: Check that the report is generated properly.
        LibraryReportDataset.LoadDataSetFile();
        VerifyServiceItemLineLabels(ServiceItemLine);
    end;

    [Test]
    [HandlerFunctions('EmployeeLablesReportsHandler')]
    [Scope('OnPrem')]
    procedure EmployeeLabels36x70mm3Columns()
    var
        AddrFormatFrom: Option "Home Address","Current Alternative Address";
        LabelFormatFrom: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
    begin
        // Test that the Employee - Labels report is generated properly in 36 x 70 mm (3 columns) format.

        EmployeeLabelsReport(AddrFormatFrom::"Home Address", LabelFormatFrom::"36 x 70 mm (3 columns)");
    end;

    [Test]
    [HandlerFunctions('EmployeeLablesReportsHandler')]
    [Scope('OnPrem')]
    procedure EmployeeLabels37x70mm3Columns()
    var
        AddrFormatFrom: Option "Home Address","Current Alternative Address";
        LabelFormatFrom: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
    begin
        // Test that the Employee - Labels report is generated properly in 37 x 70 mm (3 columns) format.

        EmployeeLabelsReport(AddrFormatFrom::"Home Address", LabelFormatFrom::"37 x 70 mm (3 columns)");
    end;

    [Test]
    [HandlerFunctions('EmployeeLablesReportsHandler')]
    [Scope('OnPrem')]
    procedure EmployeeLabels36x105mm2Columns()
    var
        AddrFormatFrom: Option "Home Address","Current Alternative Address";
        LabelFormatFrom: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
    begin
        // Test that the Employee - Labels report is generated properly in 36 x 105 mm (2 columns) format.

        EmployeeLabelsReport(AddrFormatFrom::"Home Address", LabelFormatFrom::"36 x 105 mm (2 columns)");
    end;

    [Test]
    [HandlerFunctions('EmployeeLablesReportsHandler')]
    [Scope('OnPrem')]
    procedure EmployeeLabels37x105mm2Columns()
    var
        AddrFormatFrom: Option "Home Address","Current Alternative Address";
        LabelFormatFrom: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
    begin
        // Test that the Employee - Labels report is generated properly in 37 x 105 mm (2 columns) format.

        EmployeeLabelsReport(AddrFormatFrom::"Home Address", LabelFormatFrom::"37 x 105 mm (2 columns)");
    end;

    local procedure EmployeeLabelsReport(AddrFormatFrom: Option; LabelFormatFrom: Option)
    var
        Employee: Record Employee;
        Employee2: Record Employee;
        Employee3: Record Employee;
        FilterExpression: Text[250];
    begin
        // 1. Setup: Create three new Employee.
        Initialize();
        CreateEmployeeWithAddress(Employee);
        CreateEmployeeWithAddress(Employee2);
        CreateEmployeeWithAddress(Employee3);

        // 2. Exercise: Generate the Employee - Labels report.
        FilterExpression := Employee."No." + '|' + Employee2."No." + '|' + Employee3."No.";
        RunEmployeeLabelsReport(FilterExpression, AddrFormatFrom, LabelFormatFrom);

        // 3. Verify: Check that the report is generated properly.
        LibraryReportDataset.LoadDataSetFile();
        VerifyEmployeeLabels(Employee);
        VerifyEmployeeLabels(Employee2);
        VerifyEmployeeLabels(Employee3);
    end;

    [Test]
    [HandlerFunctions('EmployeeLablesReportsHandler')]
    [Scope('OnPrem')]
    procedure EmployeeAlternate36x703Column()
    var
        AddrFormatFrom: Option "Home Address","Current Alternative Address";
        LabelFormatFrom: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
    begin
        // Test that the Employee - Labels report is generated properly in 36 x 70 mm (3 columns) format.

        EmployeeAlternateLabelsReport(AddrFormatFrom::"Current Alternative Address", LabelFormatFrom::"36 x 70 mm (3 columns)");
    end;

    [Test]
    [HandlerFunctions('EmployeeLablesReportsHandler')]
    [Scope('OnPrem')]
    procedure EmployeeAlternate37x703Column()
    var
        AddrFormatFrom: Option "Home Address","Current Alternative Address";
        LabelFormatFrom: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
    begin
        // Test that the Employee - Labels report is generated properly in 37 x 70 mm (3 columns) format.

        EmployeeAlternateLabelsReport(AddrFormatFrom::"Current Alternative Address", LabelFormatFrom::"37 x 70 mm (3 columns)");
    end;

    [Test]
    [HandlerFunctions('EmployeeLablesReportsHandler')]
    [Scope('OnPrem')]
    procedure EmployeeAlternate36x1052Column()
    var
        AddrFormatFrom: Option "Home Address","Current Alternative Address";
        LabelFormatFrom: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
    begin
        // Test that the Employee - Labels report is generated properly in 36 x 105 mm (2 columns) format.

        EmployeeAlternateLabelsReport(AddrFormatFrom::"Current Alternative Address", LabelFormatFrom::"36 x 105 mm (2 columns)");
    end;

    [Test]
    [HandlerFunctions('EmployeeLablesReportsHandler')]
    [Scope('OnPrem')]
    procedure EmployeeAlternate37x1052Column()
    var
        AddrFormatFrom: Option "Home Address","Current Alternative Address";
        LabelFormatFrom: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
    begin
        // Test that the Employee - Labels report is generated properly in 37 x 105 mm (2 columns) format.

        EmployeeAlternateLabelsReport(AddrFormatFrom::"Current Alternative Address", LabelFormatFrom::"37 x 105 mm (2 columns)");
    end;

    local procedure EmployeeAlternateLabelsReport(AddrFormatFrom: Option; LabelFormatFrom: Option)
    var
        Employee: Record Employee;
        Employee2: Record Employee;
        Employee3: Record Employee;
        AlternativeAddress: Record "Alternative Address";
        AlternativeAddress2: Record "Alternative Address";
        AlternativeAddress3: Record "Alternative Address";
        FilterExpression: Text[250];
    begin
        // 1. Setup: Create three new Employee and their Alternative Address.
        Initialize();
        CreateEmployeeWithAddress(Employee);
        CreateAlternativeAddress(AlternativeAddress, Employee."No.");
        AttachAlternativeAddress(Employee, AlternativeAddress.Code);

        CreateEmployeeWithAddress(Employee2);
        CreateAlternativeAddress(AlternativeAddress2, Employee2."No.");
        AttachAlternativeAddress(Employee2, AlternativeAddress2.Code);

        CreateEmployeeWithAddress(Employee3);
        CreateAlternativeAddress(AlternativeAddress3, Employee3."No.");
        AttachAlternativeAddress(Employee3, AlternativeAddress3.Code);

        // 2. Exercise: Generate the Employee - Labels report.
        FilterExpression := Employee."No." + '|' + Employee2."No." + '|' + Employee3."No.";
        RunEmployeeLabelsReport(FilterExpression, AddrFormatFrom, LabelFormatFrom);

        // 3. Verify: Check that the report is generated properly.
        LibraryReportDataset.LoadDataSetFile();
        VerifyAlternativeAddress(AlternativeAddress);
        VerifyAlternativeAddress(AlternativeAddress2);
        VerifyAlternativeAddress(AlternativeAddress3);
    end;

    local procedure AddContactsToSegment(Contact: Record Contact; SegmentHeader: Record "Segment Header")
    var
        LibraryVariableStorageVariant: Codeunit "Library - Variable Storage";
    begin
        Contact.SetRange("No.", Contact."No.");
        SegmentHeader.SetRange("No.", SegmentHeader."No.");

        LibraryVariableStorageVariant.Enqueue(Contact);
        LibraryVariableStorageVariant.Enqueue(SegmentHeader);

        LibraryMarketing.RunAddContactsReport(LibraryVariableStorageVariant, false);
    end;

    local procedure AttachAlternativeAddress(Employee: Record Employee; AltAddressCode: Code[10])
    begin
        // Use TODAY instead of WORKDATE because original code uses TODAY.
        Employee.Validate("Alt. Address Code", AltAddressCode);
        Employee.Validate("Alt. Address Start Date", CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'D>', Today));
        Employee.Validate("Alt. Address End Date", CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', Today));
        Employee.Modify(true);
    end;

    local procedure CreateAlternativeAddress(var AlternativeAddress: Record "Alternative Address"; EmployeeNo: Code[20])
    var
        PostCode: Record "Post Code";
        LibraryHumanResource: Codeunit "Library - Human Resource";
    begin
        CreatePostCode(PostCode);

        LibraryHumanResource.CreateAlternativeAddress(AlternativeAddress, EmployeeNo);
        AlternativeAddress.Validate(
          Address,
          CopyStr(
            LibraryUtility.GenerateRandomCode(AlternativeAddress.FieldNo(Address), DATABASE::"Alternative Address"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Alternative Address", AlternativeAddress.FieldNo(Address))));
        AlternativeAddress.Validate(
          "Address 2",
          CopyStr(
            LibraryUtility.GenerateRandomCode(AlternativeAddress.FieldNo("Address 2"), DATABASE::"Alternative Address"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Alternative Address", AlternativeAddress.FieldNo("Address 2"))));
        AlternativeAddress.Validate("Country/Region Code", PostCode."Country/Region Code");
        AlternativeAddress.Validate("Post Code", PostCode.Code);
        AlternativeAddress.Modify(true);
    end;

    local procedure CreateContactWithAddress(var Contact: Record Contact)
    var
        PostCode: Record "Post Code";
        LibraryMarketing: Codeunit "Library - Marketing";
    begin
        CreatePostCode(PostCode);

        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate(
          Address,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Contact.FieldNo(Address), DATABASE::Contact),
            1,
            LibraryUtility.GetFieldLength(DATABASE::Contact, Contact.FieldNo(Address))));
        Contact.Validate(
          "Address 2",
          CopyStr(
            LibraryUtility.GenerateRandomCode(Contact.FieldNo("Address 2"), DATABASE::Contact),
            1,
            LibraryUtility.GetFieldLength(DATABASE::Contact, Contact.FieldNo("Address 2"))));
        Contact.Validate("Country/Region Code", PostCode."Country/Region Code");
        Contact.Validate("Post Code", PostCode.Code);
        Contact.Modify(true);
    end;

    local procedure CreateEmployeeWithAddress(var Employee: Record Employee)
    var
        PostCode: Record "Post Code";
        LibraryHumanResource: Codeunit "Library - Human Resource";
    begin
        CreatePostCode(PostCode);

        LibraryHumanResource.CreateEmployee(Employee);
        Employee.Validate(
          Address,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Employee.FieldNo(Address), DATABASE::Employee),
            1,
            LibraryUtility.GetFieldLength(DATABASE::Employee, Employee.FieldNo(Address))));
        Employee.Validate(
          "Address 2",
          CopyStr(
            LibraryUtility.GenerateRandomCode(Employee.FieldNo("Address 2"), DATABASE::Employee),
            1,
            LibraryUtility.GetFieldLength(DATABASE::Employee, Employee.FieldNo("Address 2"))));
        Employee.Validate("Country/Region Code", PostCode."Country/Region Code");
        Employee.Validate("Post Code", PostCode.Code);
        Employee.Modify(true);
    end;

    local procedure CreatePostCode(var PostCode: Record "Post Code")
    var
        CountryRegion: Record "Country/Region";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreatePostCode(PostCode);  // Creation of Post Code is required to avoid special characters in existing ones.
        CountryRegion.SetRange("Address Format", CountryRegion."Address Format"::"Post Code+City");
        CountryRegion.Next(LibraryRandom.RandInt(CountryRegion.Count));
        PostCode.Validate("Country/Region Code", CountryRegion.Code);
        PostCode.Modify(true);
    end;

    local procedure RunContactLabelsReport(FilterExpression: Text[250]; LabelFormatFrom: Option)
    var
        Contact: Record Contact;
        ContactLabels: Report "Contact - Labels";
    begin
        Clear(ContactLabels);
        Contact.SetFilter("No.", FilterExpression);
        ContactLabels.InitializeRequest(LabelFormatFrom);
        ContactLabels.SetTableView(Contact);
        Commit();
        ContactLabels.Run();
    end;

    local procedure RunEmployeeLabelsReport(FilterExpression: Text[250]; AddrFormatFrom: Option; LabelFormatFrom: Option)
    var
        Employee: Record Employee;
        EmployeeLabels: Report "Employee - Labels";
    begin
        Clear(EmployeeLabels);
        Employee.SetFilter("No.", FilterExpression);
        EmployeeLabels.InitializeRequest(AddrFormatFrom, LabelFormatFrom);
        EmployeeLabels.SetTableView(Employee);
        Commit();
        EmployeeLabels.Run();
    end;

    local procedure RunSegmentLabelsReport(FilterExpression: Text[250]; LabelFormatFrom: Option)
    var
        SegmentHeader: Record "Segment Header";
        SegmentLabels: Report "Segment - Labels";
    begin
        Clear(SegmentLabels);
        SegmentHeader.SetFilter("No.", FilterExpression);
        SegmentLabels.InitializeRequest(LabelFormatFrom);
        SegmentLabels.SetTableView(SegmentHeader);
        Commit();
        SegmentLabels.Run();
    end;

    local procedure VerifyAlternativeAddress(AlternativeAddress: Record "Alternative Address")
    var
        CountryRegion: Record "Country/Region";
        FormatAddress: Codeunit "Format Address";
        PostCodeCity: Text[90];
        County: Text[50];
        Column: Integer;
        Row: Integer;
        XmlElementName: Text[250];
        Found: Boolean;
    begin
        Column := 0;
        Row := 1;
        Found := false;
        while (false = Found) and (Column <= 3) do begin
            Column += 1;
            XmlElementName := StrSubstNo(EmployeeAddrCap, Column, Row);
            LibraryReportDataset.SetRangeWithTrimmedValues(XmlElementName, AlternativeAddress."Employee No.", true);
            Found := LibraryReportDataset.GetNextRow();
        end;

        Assert.IsTrue(Found, AlternativeAddress."Employee No.");

        if Found then begin
            Row += 1;
            LibraryReportDataset.AssertCurrentRowValueEquals(StrSubstNo(EmployeeAddrCap, Column, Row),
              AlternativeAddress.Address);
            Row += 1;
            LibraryReportDataset.AssertCurrentRowValueEquals(StrSubstNo(EmployeeAddrCap, Column, Row),
              AlternativeAddress."Address 2");
            CountryRegion.Get(AlternativeAddress."Country/Region Code");
            FormatAddress.FormatPostCodeCity(PostCodeCity, County, AlternativeAddress.City,
              AlternativeAddress."Post Code", AlternativeAddress.County, CountryRegion.Code);
            Row += 1;
            LibraryReportDataset.AssertCurrentRowValueEquals(StrSubstNo(EmployeeAddrCap, Column, Row), PostCodeCity);
            if County <> '' then begin
                Row += 1;
                LibraryReportDataset.AssertCurrentRowValueEquals(StrSubstNo(EmployeeAddrCap, Column, Row), County);
            end;
            Row += 1;
            LibraryReportDataset.AssertCurrentRowValueEquals(StrSubstNo(EmployeeAddrCap, Column, Row), CountryRegion.Name);
        end;
    end;

    local procedure VerifyContactLabels(Contact: Record Contact; ElementCaption: Text[50])
    var
        CountryRegion: Record "Country/Region";
        FormatAddress: Codeunit "Format Address";
        PostCodeCity: Text[90];
        County: Text[50];
        Column: Integer;
        Row: Integer;
        XmlElementName: Text[250];
        Found: Boolean;
    begin
        Column := 0;
        Row := 1;
        Found := false;
        while (false = Found) and (Column <= 3) do begin
            Column += 1;
            XmlElementName := StrSubstNo(ElementCaption, Column, Row);
            LibraryReportDataset.SetRange(XmlElementName, Contact."No.");
            Found := LibraryReportDataset.GetNextRow();
        end;

        Assert.IsTrue(Found, Contact."No.");
        if Found then begin
            Row += 1;
            LibraryReportDataset.AssertCurrentRowValueEquals(StrSubstNo(ElementCaption, Column, Row),
              Contact.Address);
            Row += 1;
            LibraryReportDataset.AssertCurrentRowValueEquals(StrSubstNo(ElementCaption, Column, Row),
              Contact."Address 2");
            CountryRegion.Get(Contact."Country/Region Code");
            FormatAddress.FormatPostCodeCity(PostCodeCity, County, Contact.City,
              Contact."Post Code", Contact.County, CountryRegion.Code);
            Row += 1;
            LibraryReportDataset.AssertCurrentRowValueEquals(StrSubstNo(ElementCaption, Column, Row), PostCodeCity);
            if County <> '' then begin
                Row += 1;
                LibraryReportDataset.AssertCurrentRowValueEquals(StrSubstNo(ElementCaption, Column, Row), County);
            end;
            Row += 1;
            LibraryReportDataset.AssertCurrentRowValueEquals(StrSubstNo(ElementCaption, Column, Row), CountryRegion.Name);
        end;
    end;

    local procedure VerifyEmployeeLabels(Employee: Record Employee)
    var
        CountryRegion: Record "Country/Region";
        FormatAddress: Codeunit "Format Address";
        PostCodeCity: Text[90];
        County: Text[50];
        Column: Integer;
        Row: Integer;
        XmlElementName: Text[250];
        Found: Boolean;
    begin
        Column := 0;
        Row := 1;
        Found := false;
        while (false = Found) and (Column <= 3) do begin
            Column += 1;
            XmlElementName := StrSubstNo(EmployeeAddrCap, Column, Row);
            LibraryReportDataset.SetRangeWithTrimmedValues(XmlElementName, Employee."No.", true);
            Found := LibraryReportDataset.GetNextRow();
        end;

        Assert.IsTrue(Found, Employee."No.");

        if Found then begin
            Row += 1;
            LibraryReportDataset.AssertCurrentRowValueEquals(StrSubstNo(EmployeeAddrCap, Column, Row),
              Employee.Address);
            Row += 1;
            LibraryReportDataset.AssertCurrentRowValueEquals(StrSubstNo(EmployeeAddrCap, Column, Row),
              Employee."Address 2");
            CountryRegion.Get(Employee."Country/Region Code");
            FormatAddress.FormatPostCodeCity(PostCodeCity, County, Employee.City,
              Employee."Post Code", Employee.County, CountryRegion.Code);
            Row += 1;
            LibraryReportDataset.AssertCurrentRowValueEquals(StrSubstNo(EmployeeAddrCap, Column, Row), PostCodeCity);
            if County <> '' then begin
                Row += 1;
                LibraryReportDataset.AssertCurrentRowValueEquals(StrSubstNo(EmployeeAddrCap, Column, Row), County);
            end;
            Row += 1;
            LibraryReportDataset.AssertCurrentRowValueEquals(StrSubstNo(EmployeeAddrCap, Column, Row), CountryRegion.Name);
        end;
    end;

    local procedure VerifyServiceItemLineLabels(ServiceItemLine: Record "Service Item Line")
    var
        Column: Integer;
        Row: Integer;
        XmlElementName: Text[250];
    begin
        Row := 0;
        Column := 1;

        Row += 1;
        XmlElementName := ServiceitemLabelAddrCap;
        LibraryReportDataset.SetRange(StrSubstNo(XmlElementName, Column, Row),
          ServiceItemLine.FieldCaption("Document No.") + ' ' + ServiceItemLine."Document No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), ServiceItemLine."Document No.");

        Row += 1;
        LibraryReportDataset.AssertCurrentRowValueEquals(StrSubstNo(XmlElementName, Column, Row),
          ServiceItemLine.FieldCaption("Service Item No.") + ' ' + ServiceItemLine."Service Item No.");

        Row += 2;
        LibraryReportDataset.AssertCurrentRowValueEquals(StrSubstNo(XmlElementName, Column, Row),
          ServiceItemLine.Description);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure EmployeeLablesReportsHandler(var EmployeeLabelsRequestPage: TestRequestPage "Employee - Labels")
    begin
        EmployeeLabelsRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ContactLabelsReportsHandler(var ContactLabelsRequestPage: TestRequestPage "Contact - Labels")
    begin
        ContactLabelsRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SegmentLabelReportsHandler(var SegmentLabelsRequestPage: TestRequestPage "Segment - Labels")
    begin
        SegmentLabelsRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SerivceItemLabelsReportsHandler(var ServiceItemlineLabelsRequestPage: TestRequestPage "Service Item Line Labels")
    begin
        ServiceItemlineLabelsRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

