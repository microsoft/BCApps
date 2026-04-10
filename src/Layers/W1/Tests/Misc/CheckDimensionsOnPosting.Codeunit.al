codeunit 134486 "Check Dimensions On Posting"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Dimensions] [Error Message]
    end;

    var
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryErrorMessage: Codeunit "Library - Error Message";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        DimCombBlockedErr: Label 'Dimensions %1 and %2 can''t be used concurrently.';
        DimCombLimitedErr: Label 'Dimension combinations %1 - %2 and %3 - %4 can''t be used concurrently.';
        DimensionBlockedErr: Label 'Dimension %1 is blocked.';
        DimensionMissingErr: Label 'Dimension %1 can''t be found.';
        DimValueBlockedErr: Label '%1 %2 - %3 is blocked.', Comment = '%1 = Dimension Value table caption, %2 = Dim Code, %3 = Dim Value';
        DimValueMissingErr: Label 'Dimension Value %1 - %2 is missing.', Comment = '%1 = Dim Code, %2 = Dim Value';
        DimValueNotAllowedErr: Label 'Dimension Value Type for Dimension Value %1 - %2 must not be %3.';
        DimValueSameOrNoCodeErr: Label 'The %1 must be %2 for %3 %4 for %5 %6. Currently it''s %7.', Comment = '%1 = "Dimension value code" caption, %2 = expected "Dimension value code" value, %3 = "Dimension code" caption, %4 = "Dimension Code" value, %5 = Table caption (Vendor), %6 = Table value (XYZ), %7 = current "Dimension value code" value';
        BlankLbl: Label 'blank';
        SameCodeMissingDimErr: Label 'The %1 %2 with %3 %4 is required.', Comment = '%1 = "Dimension code" caption, %2= "Dimension Code" value, %3 = "Dimension value code" caption, %4 = "Dimension value code" value';
        DimValueBlankSameCodeRecErr: Label '%1 %2 must be blank for %3 %4.';
        SelectDimValueForRecErr: Label 'Select a Dimension Value Code for the Dimension Code %1 for %2 %3.';
        DummyBlankRecID: RecordID;
        IsInitialized: Boolean;
        SelectDimValueErr: Label 'The %1 dimension is the default dimension, and it must have a value. You can set the value on the Default Dimensions page.', Comment = '%1 = the value of Dimension Code; %2 = page caption of Default Dimensions';
        OnAfterCheckDocErr: Label 'OnAfterCheckDoc';
        PostingDimensionErr: Label 'A dimension used in %1 %2, %3, %4 has caused an error. %5';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T090_SetSourceCode()
    var
        SourceCodeSetup: Record "Source Code Setup";
        DimMgt: Codeunit DimensionManagement;
    begin
        // [FEATURE] [UT] [Source Code]
        SourceCodeSetup.Get();
        SourceCodeSetup.Sales := LibraryUtility.GenerateGUID();
        SourceCodeSetup.Purchases := LibraryUtility.GenerateGUID();
        SourceCodeSetup.Modify();

        DimMgt.SetSourceCode(DATABASE::"Sales Header");
        Assert.AreEqual(SourceCodeSetup.Sales, DimMgt.GetSourceCode(), '36');
        DimMgt.SetSourceCode(DATABASE::"Sales Line");
        Assert.AreEqual(SourceCodeSetup.Sales, DimMgt.GetSourceCode(), '37');
        DimMgt.SetSourceCode(DATABASE::"Purchase Header");
        Assert.AreEqual(SourceCodeSetup.Purchases, DimMgt.GetSourceCode(), '38');
        DimMgt.SetSourceCode(DATABASE::"Purchase Line");
        Assert.AreEqual(SourceCodeSetup.Purchases, DimMgt.GetSourceCode(), '39');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T100_SalesHeaderWithBlockedDimensionValue()
    var
        SalesHeader: Record "Sales Header";
        DimensionValue: array[2] of Record "Dimension Value";
        ErrorMessagesPage: TestPage "Error Messages";
        SalesOrderPage: TestPage "Sales Order";
        CustomerNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
        ExpectedSupportURL: Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains one line for blocked dimension value.
        Initialize();
        // [GIVEN] Forward Link "Working With Dims" has Link 'X'
        ExpectedSupportURL := SetupSupportURL();
        // [GIVEN] Customer 'A'
        CustomerNo := LibrarySales.CreateCustomerNo();
        // [GIVEN] Dimension value 'Department','ADM' is blocked
        ExpectedErrorMessage[1] := CreateCustBlockedDimensionValue(DimensionValue[1], CustomerNo);
        // [GIVEN] Sales Order '1002', where "Sell-To Customer No." is 'A'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        // [WHEN] Post Sales Order '1002'
        PostSalesDocument(SalesHeader, CODEUNIT::"Sales-Post");

        // [THEN] Opened page "Error Messages" with one line, where "Error Message" is 'Dimension Department is blocked'
        // [THEN] "Context" is 'Sales Header: Order, 1002'; "Source" is 'Dimension Value: Department, ADM'; "Field Name" is 'Blocked';
        // [THEN] "Support URL" is 'X'
        VerifyHeaderDimError(
          SalesHeader.RecordId, DimensionValue[1].RecordId, DimensionValue[1].FieldNo(Blocked), ExpectedErrorMessage, ExpectedSupportURL);

        // [WHEN] Run action "Open Related Record"
        SalesOrderPage.Trap();
        LibraryErrorMessage.GetTestPage(ErrorMessagesPage);
        ErrorMessagesPage.First();
        ErrorMessagesPage.OpenRelatedRecord.Invoke();
        // [THEN] "Sales Order" page is open on Sales Order '1002'
        SalesOrderPage."No.".AssertEquals(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T101_SalesHeaderWithDeletedDimensionValue()
    var
        SalesHeader: Record "Sales Header";
        DimensionValue: Record "Dimension Value";
        CustomerNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
        ExpectedSupportURL: Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains one line for deleted dimension value.
        Initialize();
        // [GIVEN] Forward Link "Working With Dims" has Link 'X'
        ExpectedSupportURL := SetupSupportURL();
        // [GIVEN] Customer 'A', where dimension value 'Department','ADM' is default
        CustomerNo := CreateCustDefaultDimensionValue(DimensionValue);
        // [GIVEN] Sales Order '1002', where "Sell-To Customer No." is 'A'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        // [GIVEN] Dimension value 'Department','ADM' is deleted
        DimensionValue.Delete();
        ExpectedErrorMessage[1] := StrSubstNo(DimValueMissingErr, DimensionValue."Dimension Code", DimensionValue.Code);

        // [WHEN] Post Sales Order '1002'
        PostSalesDocument(SalesHeader, CODEUNIT::"Sales-Post");

        // [THEN] Opened page "Error Messages" with one line, where "Error Message" is 'Dimension values for Department is missing.'
        // [THEN] "Context" is 'Sales Header: Order, 1002'; "Source" is <blank>; "Support URL" is 'X';
        VerifyHeaderDimError(SalesHeader.RecordId, DummyBlankRecID, 0, ExpectedErrorMessage, ExpectedSupportURL);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T102_SalesHeaderWithNotAllowedDimensionValue()
    var
        SalesHeader: Record "Sales Header";
        DimensionValue: Record "Dimension Value";
        CustomerNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains one line for not allowed dimension value.
        Initialize();
        // [GIVEN] Customer 'A', where dimension value 'Department','ADM' is default
        CustomerNo := CreateCustDefaultDimensionValue(DimensionValue);
        // [GIVEN] Dimension value 'Department','ADM' is not allowed ("Dimension Value Type" = 'Heading')
        SetNotAllowedDimensionValueType(DimensionValue, ExpectedErrorMessage[1]);
        // [GIVEN] Sales Order '1002', where "Sell-To Customer No." is 'A'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        // [WHEN] Post Sales Order '1002'
        PostSalesDocument(SalesHeader, CODEUNIT::"Sales-Post");

        // [THEN] Opened page "Error Messages" with one line, where "Error Message" is 'Dimension Value Type must not be Heading'
        // [THEN] "Context" is 'Sales Header: Order, 1002'; "Source" is 'Dimension Value: Department, ADM'; "Field Name" is 'Dimension Value Type'
        VerifyHeaderDimError(
          SalesHeader.RecordId, DimensionValue.RecordId, DimensionValue.FieldNo("Dimension Value Type"), ExpectedErrorMessage, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T103_SalesHeaderWithBlockedDimension()
    var
        SalesHeader: Record "Sales Header";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        CustomerNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains one line for blocked dimension.
        Initialize();
        // [GIVEN] Customer 'A', where dimension value 'Department','ADM' is default
        CustomerNo := CreateCustDefaultDimensionValue(DimensionValue);
        // [GIVEN] Sales Order '1002', where "Sell-To Customer No." is 'A'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        // [GIVEN] Dimension 'Department' is blocked
        ExpectedErrorMessage[1] := SetDimensionBlocked(DimensionValue."Dimension Code", Dimension);

        // [WHEN] Post Sales Order '1002'
        PostSalesDocument(SalesHeader, CODEUNIT::"Sales-Post");

        // [THEN] Opened page "Error Messages" with one line, where "Error Message" is 'Dimension Department is blocked'
        // [THEN] "Context" is 'Sales Header: Order, 1002'; "Source" is 'Dimension: Department'; "Field Name" is 'Blocked'
        VerifyHeaderDimError(SalesHeader.RecordId, Dimension.RecordId, Dimension.FieldNo(Blocked), ExpectedErrorMessage, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T104_SalesHeaderWithDeletedDimension()
    var
        SalesHeader: Record "Sales Header";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        CustomerNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains one line for deleted dimension.
        Initialize();
        // [GIVEN] Customer 'A', where dimension value 'Department','ADM' is default
        CustomerNo := CreateCustDefaultDimensionValue(DimensionValue);
        // [GIVEN] Sales Order '1002', where "Sell-To Customer No." is 'A'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        // [GIVEN] Dimension 'Department' is deleted
        Dimension.Get(DimensionValue."Dimension Code");
        Dimension.Delete();
        ExpectedErrorMessage[1] := StrSubstNo(DimensionMissingErr, DimensionValue."Dimension Code");

        // [WHEN] Post Sales Order '1002'
        PostSalesDocument(SalesHeader, CODEUNIT::"Sales-Post");

        // [THEN]Opened page "Error Messages" with one line, where "Error Message" is 'Dimension Department cannot be found'
        // [THEN] "Context" is 'Sales Header: Order, 1002'; "Source" is <blank>
        VerifyHeaderDimError(SalesHeader.RecordId, DummyBlankRecID, 0, ExpectedErrorMessage, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T105_SalesHeaderWithBlockedDimensionAndDimValue()
    var
        SalesHeader: Record "Sales Header";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        ContextDimRecID: array[10] of RecordID;
        SourceDimRecID: array[10] of RecordID;
        SourceFieldNo: array[10] of Integer;
        CustomerNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains two lines: for blocked dimension and for blocked dimension value.
        Initialize();
        // [GIVEN] Customer 'A' with default dimensions: 'Department' and 'Project'.
        CustomerNo := CreateCustDefaultDimensionValue(DimensionValue);
        // [GIVEN] Dimension 'Department' is blocked
        ExpectedErrorMessage[1] := SetDimensionBlocked(DimensionValue."Dimension Code", Dimension);
        SourceDimRecID[1] := Dimension.RecordId;
        SourceFieldNo[1] := Dimension.FieldNo(Blocked);
        // [GIVEN] Dimension value 'Project','TOYOTA' is blocked
        ExpectedErrorMessage[2] := CreateCustBlockedDimensionValue(DimensionValue, CustomerNo);
        SourceDimRecID[2] := DimensionValue.RecordId;
        SourceFieldNo[2] := DimensionValue.FieldNo(Blocked);

        // [GIVEN] Sales Order '1002', where "Sell-To Customer No." is 'A'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SetArray(ContextDimRecID, 1, 3, SalesHeader.RecordId);
        ExpectedErrorMessage[3] := DocumentErrorsMgt.GetNothingToPostErrorMsg();

        // [WHEN] Post Sales Order '1002'
        PostSalesDocument(SalesHeader, CODEUNIT::"Sales-Post");

        // [THEN] Opened page "Error Messages" with two lines (the third is 'Nothing to post'):
        // [THEN]  1st Dimension Errors line, where "Error Message" is 'Dimension Department is blocked'
        // [THEN] "Context" is 'Sales Header: Order, 1002'; "Source" is 'Dimension: Department'
        // [THEN] 2nd Dimension Errors line, where "Error Message" is 'Dimension value: Project,TOYOTA is blocked'
        // [THEN] "Context" is 'Sales Header: Order, 1002'; "Source" is 'Dimension Value: Project,TOYOTA'
        VerifyHeaderDimErrors(ContextDimRecID, 3, ExpectedErrorMessage, SourceDimRecID, SourceFieldNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T106_SalesHeaderWithBlankMandatoryDimensions()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        DefaultDimension: array[3] of Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        ContextDimRecID: array[10] of RecordID;
        SourceDimRecID: array[10] of RecordID;
        SourceFieldNo: array[10] of Integer;
        CustomerNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains one line for blank mandatory dimension.
        Initialize();
        // [GIVEN] Mandatory Default Dimension 'Project' is <blank> for table 'Customer'
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension[1], '', DimensionValue."Dimension Code", '');
        DefaultDimension[1]."Value Posting" := DefaultDimension[1]."Value Posting"::"Code Mandatory";
        DefaultDimension[1].Modify();
        ExpectedErrorMessage[1] := StrSubstNo(SelectDimValueErr, DimensionValue."Dimension Code");
        SourceDimRecID[1] := DefaultDimension[1].RecordId;
        SourceFieldNo[1] := DefaultDimension[1].FieldNo("Value Posting");

        // [GIVEN] Customer 'A'
        CustomerNo := LibrarySales.CreateCustomerNo();
        // [GIVEN] Mandatory Default Dimension 'Department' is <blank> for Customer 'A'
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension[2], CustomerNo, DimensionValue."Dimension Code", '');
        DefaultDimension[2]."Value Posting" := DefaultDimension[2]."Value Posting"::"Code Mandatory";
        DefaultDimension[2].Modify();
        ExpectedErrorMessage[2] := StrSubstNo(SelectDimValueForRecErr, DimensionValue."Dimension Code", Customer.TableName, CustomerNo);
        SourceDimRecID[2] := DefaultDimension[2].RecordId;
        SourceFieldNo[2] := DefaultDimension[2].FieldNo("Value Posting");
        // [GIVEN] Mandatory Default Dimension 'Department' is <blank> for table 'Customer'
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension[3], '', DimensionValue."Dimension Code", '');

        // [GIVEN] Sales Order '1002', where "Sell-To Customer No." is 'A'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SetArray(ContextDimRecID, 1, 3, SalesHeader.RecordId);
        ExpectedErrorMessage[3] := DocumentErrorsMgt.GetNothingToPostErrorMsg();

        // [WHEN] Post Sales Order '1002'
        PostSalesDocument(SalesHeader, CODEUNIT::"Sales-Post");

        // [THEN] Opened page "Error Messages" with two lines (the third is 'Nothing to post'):
        // [THEN] 1st Dimension Errors line, where "Error Message" is 'Select Dimension Value code for Dimension Code Project'
        // [THEN] "Context" is 'Sales Header: Order, 1002'; "Source" is 'Default Dimension: 18, <>, Project'
        // [THEN] 2nd Dimension Errors line, where "Error Message" is 'Select Dimension Value code for Dimension Code Department for Customer A'
        // [THEN] "Context" is 'Sales Header: Order, 1002'; "Source" is 'Default Dimension: 18, A, Department'
        VerifyHeaderDimErrors(ContextDimRecID, 3, ExpectedErrorMessage, SourceDimRecID, SourceFieldNo);
        // TearDown
        DefaultDimension[1].Delete(); // remove mandatory dim set for all customers
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T107_SalesHeaderWithBlankMandatoryAndBlockedDimensions()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        DefaultDimension: array[3] of Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        ContextDimRecID: array[10] of RecordID;
        SourceDimRecID: array[10] of RecordID;
        SourceFieldNo: array[10] of Integer;
        CustomerNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains one line for blank mandatory dimension.
        Initialize();
        // [GIVEN] Customer 'A'
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] "No Code" Default Dimension 'Project' is filled for Customer 'A'
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension[2], CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension[2]."Value Posting" := DefaultDimension[2]."Value Posting"::"No Code";
        DefaultDimension[2].Modify();
        ExpectedErrorMessage[2] :=
          StrSubstNo(
            DimValueSameOrNoCodeErr,
            DefaultDimension[2].FieldCaption("Dimension Value Code"), BlankLbl,
            DefaultDimension[2].FieldCaption("Dimension Code"), DefaultDimension[2]."Dimension Code",
            Customer.TableCaption(), CustomerNo,
            DimensionValue.Code);
        SourceDimRecID[2] := DefaultDimension[2].RecordId;
        SourceFieldNo[2] := DefaultDimension[2].FieldNo("Value Posting");

        // [GIVEN] Dimension Value 'Department: ADM' is blocked
        ExpectedErrorMessage[1] := CreateCustBlockedDimensionValue(DimensionValue, CustomerNo);
        SourceDimRecID[1] := DimensionValue.RecordId;
        SourceFieldNo[1] := DimensionValue.FieldNo(Blocked);

        // [GIVEN] Sales Order '1002', where "Sell-To Customer No." is 'A'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SetArray(ContextDimRecID, 1, 3, SalesHeader.RecordId);
        ExpectedErrorMessage[3] := DocumentErrorsMgt.GetNothingToPostErrorMsg();

        // [WHEN] Post Sales Order '1002'
        PostSalesDocument(SalesHeader, CODEUNIT::"Sales-Post");

        // [THEN] Opened page "Error Messages" with two lines (the third is 'Nothing to post'):
        // [THEN]  1st Dimension Errors line, where "Error Message" is '(Error: Dimension Value Department - ADM is blocked.)'.
        // [THEN] "Context" is 'Sales Header: Order, 1002'; "Source" is 'Dimension Value: Department, ADM'
        // [THEN] 2nd Dimension Errors line, where "Error Message" is 'Select Dimension Value code for Dimension Code Department for Customer A'
        // [THEN] "Context" is 'Sales Header: Order, 1002'; "Source" is 'Default Dimension: 18, A, Department'
        VerifyHeaderDimErrors(ContextDimRecID, 3, ExpectedErrorMessage, SourceDimRecID, SourceFieldNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T108_SalesHeaderWithWrongSameCodeDimensions()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        DefaultDimension: array[3] of Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
        ContextDimRecID: array[10] of RecordID;
        SourceDimRecID: array[10] of RecordID;
        SourceFieldNo: array[10] of Integer;
        CustomerNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains one line for incorrect "Same Code" dimension.
        Initialize();
        // [GIVEN] Customer 'X'
        CustomerNo := LibrarySales.CreateCustomerNo();
        // [GIVEN] "Same Code" Default Dimension 'Project' is 'A' for table 'Customer'
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension[1], '', DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension[1]."Value Posting" := DefaultDimension[1]."Value Posting"::"Same Code";
        DefaultDimension[1].Modify();
        ExpectedErrorMessage[1] :=
          StrSubstNo(
            SameCodeMissingDimErr,
            DefaultDimension[1].FieldCaption("Dimension Code"), DefaultDimension[1]."Dimension Code",
            DefaultDimension[1].FieldCaption("Dimension Value Code"), DefaultDimension[1]."Dimension Value Code");
        SourceDimRecID[1] := DefaultDimension[1].RecordId;
        SourceFieldNo[1] := DefaultDimension[1].FieldNo("Value Posting");

        // [GIVEN] Mandatory Default Dimension 'Department' is '<blank>' for Customer 'X'
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension[2], CustomerNo, DimensionValue."Dimension Code", '');
        DefaultDimension[2]."Value Posting" := DefaultDimension[2]."Value Posting"::"Same Code";
        DefaultDimension[2].Modify();
        ExpectedErrorMessage[2] :=
          StrSubstNo(
            DimValueBlankSameCodeRecErr,
            DefaultDimension[2].FieldCaption("Dimension Code"), DefaultDimension[2]."Dimension Code",
            Customer.TableName, CustomerNo);
        SourceDimRecID[2] := DefaultDimension[2].RecordId;
        SourceFieldNo[2] := DefaultDimension[2].FieldNo("Value Posting");

        // [GIVEN] Sales Order '1002', where "Sell-To Customer No." is 'X'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SetArray(ContextDimRecID, 1, 3, SalesHeader.RecordId);
        ExpectedErrorMessage[3] := DocumentErrorsMgt.GetNothingToPostErrorMsg();
        // [GIVEN] Change dimensions on the header: 'Project' is 'B', 'Department' is <blank>
        DimMgt.GetDimensionSet(TempDimSetEntry, SalesHeader."Dimension Set ID");
        ChangeDimValueInSet(TempDimSetEntry, DefaultDimension[1]."Dimension Code", '');
        LibraryDimension.CreateDimensionValue(DimensionValue, DefaultDimension[2]."Dimension Code");
        AddDimValueInSet(TempDimSetEntry, DefaultDimension[2]."Dimension Code", DimensionValue.Code);
        SalesHeader.Validate("Dimension Set ID", DimMgt.GetDimensionSetID(TempDimSetEntry));
        SalesHeader.Modify();

        // [WHEN] Post Sales Order '1002'
        PostSalesDocument(SalesHeader, CODEUNIT::"Sales-Post");

        // [THEN] Opened page "Error Messages" with two lines (the third is 'Nothing to post'):
        // [THEN] 1st Dimension Errors line, where "Error Message" is 'Select Dimension Value Code A for Dimension Code Project'
        // [THEN] "Context" is 'Sales Header: Order, 1002'; "Source" is 'Default Dimension: 18, <>, Project'
        // [THEN] 2nd Dimension Errors line, where "Error Message" is 'Select Dimension Code Department must not be blank for Customer X'
        // [THEN] "Context" is 'Sales Header: Order, 1002'; "Source" is 'Default Dimension: 18, X, Department'
        VerifyHeaderDimErrors(ContextDimRecID, 3, ExpectedErrorMessage, SourceDimRecID, SourceFieldNo);
        // TearDown
        DefaultDimension[1].Delete(); // remove mandatory dim set for all customers
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T109_SalesHeaderWithBlockedDimComb()
    var
        SalesHeader: Record "Sales Header";
        DefaultDimension: array[3] of Record "Default Dimension";
        DimensionCombination: array[2] of Record "Dimension Combination";
        DimensionValue: Record "Dimension Value";
        DimensionValueCombination: Record "Dimension Value Combination";
        ContextDimRecID: array[10] of RecordID;
        SourceDimRecID: array[10] of RecordID;
        SourceFieldNo: array[10] of Integer;
        CustomerNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains one line for blocked dimension combination.
        Initialize();
        // [GIVEN] Customer 'X'
        CustomerNo := LibrarySales.CreateCustomerNo();
        // [GIVEN] Default Dimension 'Project' is 'A' for Customer 'X'
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension[1], CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);
        // [GIVEN] Default Dimension 'Department' is 'B' for Customer 'X'
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension[2], CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);
        // [GIVEN] Default Dimension 'Salesperson' is 'S' for Customer 'X'
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension[3], CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);

        ExpectedErrorMessage[1] :=
          StrSubstNo(DimCombBlockedErr, DefaultDimension[1]."Dimension Code", DefaultDimension[2]."Dimension Code");
        ExpectedErrorMessage[2] :=
          StrSubstNo(
            DimCombLimitedErr, DefaultDimension[1]."Dimension Code", DefaultDimension[1]."Dimension Value Code",
            DefaultDimension[3]."Dimension Code", DefaultDimension[3]."Dimension Value Code");

        // [GIVEN] Combination of dimension values 'Project' and 'Department' is blocked
        LibraryDimension.CreateDimensionCombination(
          DimensionCombination[1], DefaultDimension[1]."Dimension Code", DefaultDimension[2]."Dimension Code");
        DimensionCombination[1]."Combination Restriction" := DimensionCombination[1]."Combination Restriction"::Blocked;
        DimensionCombination[1].Modify();
        SourceDimRecID[1] := DimensionCombination[1].RecordId;
        SourceFieldNo[1] := DimensionCombination[1].FieldNo("Combination Restriction");
        // [GIVEN] Combination of dimension values 'Project' - 'A' and 'Salesperson' - 'S' is blocked
        LibraryDimension.CreateDimensionCombination(
          DimensionCombination[2], DefaultDimension[1]."Dimension Code", DefaultDimension[3]."Dimension Code");
        DimensionCombination[2]."Combination Restriction" := DimensionCombination[2]."Combination Restriction"::Limited;
        DimensionCombination[2].Modify();
        LibraryDimension.CreateDimValueCombination(
          DimensionValueCombination,
          DefaultDimension[1]."Dimension Code", DefaultDimension[3]."Dimension Code",
          DefaultDimension[1]."Dimension Value Code", DefaultDimension[3]."Dimension Value Code");
        SourceDimRecID[2] := DimensionValueCombination.RecordId;

        // [GIVEN] Sales Order '1002', where "Sell-To Customer No." is 'X'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SetArray(ContextDimRecID, 1, 3, SalesHeader.RecordId);
        ExpectedErrorMessage[3] := DocumentErrorsMgt.GetNothingToPostErrorMsg();

        // [WHEN] Post Sales Order '1002'
        PostSalesDocument(SalesHeader, CODEUNIT::"Sales-Post");

        // [THEN] Opened page "Error Messages" with two lines (the third is 'Nothing to post'):
        // [THEN] 1st Dimension Errors line, where "Error Message" is 'Select Dimension Value Code A for Dimension Code Project'
        // [THEN] "Context" is 'Sales Header: Order, 1002'; "Source" is 'Dimension Combination: Project, Salesperson'
        // [THEN] 2nd Dimension Errors line, where "Error Message" is 'Select Dimension Code Department must not be blank for Customer X'
        // [THEN] "Context" is 'Sales Header: Order, 1002'; "Source" is 'Dimension Value Combination: Project,A,Salesperson,S'
        VerifyHeaderDimErrors(ContextDimRecID, 3, ExpectedErrorMessage, SourceDimRecID, SourceFieldNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T120_SalesLineWithBlockedDimensionAndCombination()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Dimension: Record Dimension;
        DimensionCombination: Record "Dimension Combination";
        DimensionValue: array[3] of Record "Dimension Value";
        SourceDimRecID: array[10] of RecordID;
        LineRecID: array[10] of RecordID;
        CustomerNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
        ExpectedCallStack: array[10] of Text;
        DimSetID: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains two lines for blocked dimension and combination used in the document line.
        Initialize();
        // [GIVEN] Combination of 'Area' and 'Salesperson' dimensions is blocked
        LibraryDimension.CreateDimWithDimValue(DimensionValue[1]);
        LibraryDimension.CreateDimWithDimValue(DimensionValue[2]);
        LibraryDimension.CreateDimensionCombination(
          DimensionCombination, DimensionValue[1]."Dimension Code", DimensionValue[2]."Dimension Code");
        DimensionCombination."Combination Restriction" := DimensionCombination."Combination Restriction"::Blocked;
        DimensionCombination.Modify();
        ExpectedErrorMessage[1] :=
          StrSubstNo(DimCombBlockedErr, DimensionValue[1]."Dimension Code", DimensionValue[2]."Dimension Code");
        SourceDimRecID[1] := DimensionCombination.RecordId;
        ExpectedCallStack[1] := 'DimensionManagement(CodeUnit 408).CheckDimComb ';
        // [GIVEN] Dimension 'Department' is blocked
        LibraryDimension.CreateDimWithDimValue(DimensionValue[3]);
        ExpectedErrorMessage[2] := SetDimensionBlocked(DimensionValue[3]."Dimension Code", Dimension);
        SourceDimRecID[2] := Dimension.RecordId;
        DimSetID := GetDimensionSetID(DimensionValue);
        ExpectedCallStack[2] := 'DimensionManagement(CodeUnit 408).CheckDim ';

        // [GIVEN] Customer 'A'
        CustomerNo := LibrarySales.CreateCustomerNo();
        // [GIVEN] Sales Invoice '1004', where "Sell-To Customer No." is 'A'
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, CustomerNo);
        // [GIVEN] Dimensions 'Department', 'Area' and 'Salesperson' are set in the lines.
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.ModifyAll("Dimension Set ID", DimSetID);
        Commit();
        SalesLine.FindFirst();
        LineRecID[1] := SalesLine.RecordId;
        LineRecID[2] := SalesLine.RecordId;

        // [WHEN] Post Sales Invoice '1004'
        PostSalesDocument(SalesHeader, CODEUNIT::"Sales-Post");

        // [THEN] Error message is <blank>
        Assert.ExpectedError('');
        // [THEN] Opened page "Error Messages" with two lines:
        // [THEN] 1st line, where Error message is 'Dimensions Area and Salesperson cannot be used concurrently'
        // [THEN] 2nd line, where Error message is 'Dimension Department is blocked'
        // [THEN] "Source Record ID" in both lines is 'Sales Line: Order, 1004, 10000'
        VerifyLineDimErrors(LineRecID, 2, ExpectedErrorMessage, SourceDimRecID, ExpectedCallStack);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T121_SalesLinesWithBlockedDimensionAndCombination()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Dimension: Record Dimension;
        DimensionCombination: Record "Dimension Combination";
        DimensionValue: array[3] of Record "Dimension Value";
        CheckDimensionsOnPosting: Codeunit "Check Dimensions On Posting";
        SourceDimRecID: array[10] of RecordID;
        ContextRecID: array[10] of RecordID;
        CustomerNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
        ExpectedCallStack: array[10] of Text;
        DimSetID: array[2] of Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains two lines for blocked dimension and combination used in two document lines.
        Initialize();
        // [GIVEN] Combination of 'Area' and 'Salesperson' dimensions is blocked
        LibraryDimension.CreateDimWithDimValue(DimensionValue[1]);
        LibraryDimension.CreateDimWithDimValue(DimensionValue[2]);
        LibraryDimension.CreateDimensionCombination(
          DimensionCombination, DimensionValue[1]."Dimension Code", DimensionValue[2]."Dimension Code");
        DimensionCombination."Combination Restriction" := DimensionCombination."Combination Restriction"::Blocked;
        DimensionCombination.Modify();
        ExpectedErrorMessage[1] :=
          StrSubstNo(DimCombBlockedErr, DimensionValue[1]."Dimension Code", DimensionValue[2]."Dimension Code");
        SourceDimRecID[1] := DimensionCombination.RecordId;
        DimSetID[1] := GetDimensionSetID(DimensionValue);
        ExpectedCallStack[1] := 'DimensionManagement(CodeUnit 408).CheckDimComb ';
        // [GIVEN] Dimension 'Department' is blocked
        Clear(DimensionValue);
        LibraryDimension.CreateDimWithDimValue(DimensionValue[3]);
        ExpectedErrorMessage[2] := SetDimensionBlocked(DimensionValue[3]."Dimension Code", Dimension);
        SourceDimRecID[2] := Dimension.RecordId;
        DimSetID[2] := GetDimensionSetID(DimensionValue);
        ExpectedCallStack[2] := 'DimensionManagement(CodeUnit 408).CheckDim ';

        // [GIVEN] Customer 'A'
        CustomerNo := LibrarySales.CreateCustomerNo();
        // [GIVEN] Sales Invoice '1004', where "Sell-To Customer No." is 'A'
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, CustomerNo);
        // [GIVEN] Expected the thrid error on after document check
        BindSubscription(CheckDimensionsOnPosting); // to throw an error in OnAfterCheckSalesDoc
        ContextRecID[3] := SalesHeader.RecordId;
        Clear(SourceDimRecID[3]);
        ExpectedErrorMessage[3] := OnAfterCheckDocErr;
        ExpectedCallStack[3] := '"Sales-Post"(CodeUnit 80).OnAfterCheckSalesDoc(Event) ';
        // [GIVEN] Dimensions 'Area' and 'Salesperson' are set in the first line.
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Validate("Dimension Set ID", DimSetID[1]);
        SalesLine.Modify();
        ContextRecID[1] := SalesLine.RecordId;
        // [GIVEN] Dimensions 'Department' is set in the second line.
        SalesLine."Line No." += 10000;
        SalesLine.Validate("Dimension Set ID", DimSetID[2]);
        SalesLine.Insert();
        ContextRecID[2] := SalesLine.RecordId;
        Commit();

        // [WHEN] Post Sales Invoice '1004'
        PostSalesDocument(SalesHeader, CODEUNIT::"Sales-Post");

        // [THEN] Opened page "Error Messages" with three lines:
        // [THEN] 1st line: Error message is 'Dimensions Area and Salesperson cannot be used concurrently'; "Context" is 'Sales Line: Order, 1004, 10000'
        // [THEN] 2nd line: Error message is 'Dimension Department is blocked'; "Context" is 'Sales Line: Order, 1004, 20000'
        // [THEN] 3rd line: Error message is 'OnAfterCheckDoc'; "Context" is 'Sales Header: Order, 1004'
        VerifyLineDimErrors(ContextRecID, 3, ExpectedErrorMessage, SourceDimRecID, ExpectedCallStack);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T130_SalesHeaderPreviewWithBlockedDimensionAndDimValue()
    var
        SalesHeader: Record "Sales Header";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        ContextDimRecID: array[10] of RecordID;
        SourceDimRecID: array[10] of RecordID;
        SourceFieldNo: array[10] of Integer;
        CustomerNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Sales] [Preview]
        // [SCENARIO] Failed posting preview opens "Error Messages" page that contains two lines: for blocked dimension and for blocked dimension value.
        Initialize();
        // [GIVEN] Customer 'A' with default dimensions: 'Department' and 'Project'.
        CustomerNo := CreateCustDefaultDimensionValue(DimensionValue);
        // [GIVEN] Dimension 'Department' is blocked
        ExpectedErrorMessage[1] := SetDimensionBlocked(DimensionValue."Dimension Code", Dimension);
        SourceDimRecID[1] := Dimension.RecordId;
        SourceFieldNo[1] := Dimension.FieldNo(Blocked);
        // [GIVEN] Dimension value 'Project','TOYOTA' is blocked
        ExpectedErrorMessage[2] := CreateCustBlockedDimensionValue(DimensionValue, CustomerNo);
        SourceDimRecID[2] := DimensionValue.RecordId;
        SourceFieldNo[2] := DimensionValue.FieldNo(Blocked);

        // [GIVEN] Sales Order '1002', where "Sell-To Customer No." is 'A'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SetArray(ContextDimRecID, 1, 3, SalesHeader.RecordId);
        ExpectedErrorMessage[3] := DocumentErrorsMgt.GetNothingToPostErrorMsg();

        // [WHEN] Preview posting of Sales Order '1002'
        asserterror PreviewSalesDocument(SalesHeader);

        // [THEN] Error message is <blank>
        Assert.ExpectedError('');
        // [THEN] Opened page "Error Messages" with two lines (the third is 'Nothing to post'):
        // [THEN]  1st Dimension Errors line, where "Error Message" is 'Dimension Department is blocked'
        // [THEN] "Context" is 'Sales Header: Order, 1002'; "Source" is 'Dimension: Department'
        // [THEN] 2nd Dimension Errors line, where "Error Message" is 'Dimension value: Project,TOYOTA is blocked'
        // [THEN] "Context" is 'Sales Header: Order, 1002'; "Source" is 'Dimension Value: Project,TOYOTA'
        VerifyHeaderDimErrors(ContextDimRecID, 3, ExpectedErrorMessage, SourceDimRecID, SourceFieldNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T140_BatchPostingSalesHeadersWithTwoDimErrors()
    var
        SalesHeader: Record "Sales Header";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
        ContextDimRecID: array[10] of RecordID;
        SourceDimRecID: array[10] of RecordID;
        SourceFieldNo: array[10] of Integer;
        CustomerNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Sales] [Batch Posting]
        // [SCENARIO] Batch posting of two documents opens "Error Messages" page that contains three lines per document.
        Initialize();
        LibrarySales.SetPostWithJobQueue(false);
        // [GIVEN] Customer 'A' with default dimensions: 'Department' and 'Project'.
        CustomerNo := CreateCustDefaultDimensionValue(DimensionValue);
        // [GIVEN] Dimension 'Department' is blocked
        ExpectedErrorMessage[1] := SetDimensionBlocked(DimensionValue."Dimension Code", Dimension);
        ExpectedErrorMessage[4] := ExpectedErrorMessage[1];
        ExpectedErrorMessage[3] := DocumentErrorsMgt.GetNothingToPostErrorMsg();
        SourceDimRecID[1] := Dimension.RecordId;
        SourceFieldNo[1] := Dimension.FieldNo(Blocked);
        SourceDimRecID[4] := SourceDimRecID[1];
        SourceFieldNo[4] := SourceFieldNo[1];
        // [GIVEN] Dimension value 'Project','TOYOTA' is blocked
        ExpectedErrorMessage[2] := CreateCustBlockedDimensionValue(DimensionValue, CustomerNo);
        ExpectedErrorMessage[5] := ExpectedErrorMessage[2];
        ExpectedErrorMessage[6] := DocumentErrorsMgt.GetNothingToPostErrorMsg();
        SourceDimRecID[2] := DimensionValue.RecordId;
        SourceFieldNo[2] := DimensionValue.FieldNo(Blocked);
        SourceDimRecID[5] := SourceDimRecID[2];
        SourceFieldNo[5] := SourceFieldNo[2];

        // [GIVEN] Sales Order '1002', where "Sell-To Customer No." is 'A'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeaderToPost(SalesHeader);
        SetArray(ContextDimRecID, 1, 3, SalesHeader.RecordId);
        SourceDimRecID[3] := SalesHeader.RecordId;
        // [GIVEN] Sales Order '1003', where "Sell-To Customer No." is 'A'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeaderToPost(SalesHeader);
        SetArray(ContextDimRecID, 4, 6, SalesHeader.RecordId);
        SourceDimRecID[6] := SalesHeader.RecordId;

        // [WHEN] Post two Sales Orders '1002' and '1003' as a batch
        LibraryErrorMessage.TrapErrorMessages();
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesBatchPostMgt.RunWithUI(SalesHeader, 2, '');

        // [THEN] Opened page "Error Messages" with six lines, where 2 are 'Nothing to post.':
        // [THEN] 3 lines for 'Sales Header: Order, 1002' and 3 lines for 'Sales Header: Order, 1003'
        VerifyHeaderDimErrors(ContextDimRecID, 6, ExpectedErrorMessage, SourceDimRecID, SourceFieldNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T141_BatchPostingSalesHeadersWithTwoDimErrorsBackground()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        ErrorMessage: Record "Error Message";
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        SourceRecId: array[4] of RecordId;
        SourceDimRecID: array[2] of RecordID;
        SourceFieldNo: array[2] of Integer;
        CustomerNo: Code[20];
        ExpectedErrorMessage: array[2] of Text;
        InitialErrorMessageRecordCount: Integer;
        i: Integer;
    begin
        // [FEATURE] [Sales] [Batch Posting]
        // [SCENARIO] Batch posting (in background) of two documents opens "Error Messages" page that contains three lines per document.
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        InitialErrorMessageRecordCount := ErrorMessage.Count();
        // [GIVEN] Customer 'A' with default dimensions: 'Department' and 'Project'.
        CustomerNo := CreateCustDefaultDimensionValue(DimensionValue);

        // [GIVEN] Dimension 'Department' is blocked
        ExpectedErrorMessage[1] := SetDimensionBlocked(DimensionValue."Dimension Code", Dimension);
        SourceDimRecID[1] := Dimension.RecordId;
        SourceFieldNo[1] := Dimension.FieldNo(Blocked);

        // [GIVEN] Dimension value 'Project','TOYOTA' is blocked
        ExpectedErrorMessage[2] := CreateCustBlockedDimensionValue(DimensionValue, CustomerNo);
        SourceDimRecID[2] := DimensionValue.RecordId;
        SourceFieldNo[2] := DimensionValue.FieldNo(Blocked);

        // [GIVEN] Sales Order '1002', where "Sell-To Customer No." is 'A'
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader[1], CustomerNo);
        SalesLine.SetRange("document type", SalesHeader[1]."Document Type");
        SalesLine.SetRange("document no.", SalesHeader[1]."No.");
        SalesLine.FindFirst();
        SourceRecId[1] := SalesHeader[1].RecordId;
        SourceRecId[2] := SalesLine.RecordId;
        SalesHeaderToPost(SalesHeader[1]);
        // [GIVEN] Sales Order '1003', where "Sell-To Customer No." is 'A'
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader[2], CustomerNo);
        SalesLine.SetRange("document type", SalesHeader[2]."Document Type");
        SalesLine.SetRange("document no.", SalesHeader[2]."No.");
        SalesLine.FindFirst();
        SourceRecId[3] := SalesHeader[2].RecordId;
        SourceRecId[4] := SalesLine.RecordId;
        SalesHeaderToPost(SalesHeader[2]);

        // [WHEN] Post two Sales Orders '1002' and '1003' as a batch
        SalesHeader[3].SetRange("Sell-to Customer No.", CustomerNo);
        SalesBatchPostMgt.RunWithUI(SalesHeader[3], 2, '');
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SourceRecID[1], true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SourceRecID[3], true);

        // [THEN] "Error Messages" contains 8 lines:
        // [THEN] 1 for 'Sales Header: Order, 1002' and 1 for 'Sales Header: Order, 1003'
        Assert.RecordCount(ErrorMessage, InitialErrorMessageRecordCount + 2);
        for i := 1 to 4 do begin
            ErrorMessage.SetRange("Context Record ID", SourceRecId[i]);
            Assert.RecordCount(ErrorMessage, 0);
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T150_SalesHeaderPrepmtWithBlockedDimensionValue()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DimensionValue: array[2] of Record "Dimension Value";
        ContextDimRecID: array[10] of RecordID;
        SourceDimRecID: array[10] of RecordID;
        SourceFieldNo: array[10] of Integer;
        CustomerNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Sales] [Prepayment]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains two errors for blocked dimension value.
        Initialize();
        // [GIVEN] Customer 'A'
        LibrarySales.CreatePrepaymentVATSetup(GLAccount, GLAccount."Gen. Posting Type"::Sale);
        CustomerNo :=
          LibrarySales.CreateCustomerWithBusPostingGroups(
            GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        // [GIVEN] Dimension value 'Department','ADM' is blocked
        ExpectedErrorMessage[1] := CreateCustBlockedDimensionValue(DimensionValue[1], CustomerNo);
        SourceDimRecID[1] := DimensionValue[1].RecordId;
        SourceFieldNo[1] := DimensionValue[1].FieldNo(Blocked);
        ExpectedErrorMessage[2] := ExpectedErrorMessage[1];
        SourceDimRecID[2] := DimensionValue[1].RecordId;
        SourceFieldNo[2] := SourceFieldNo[1];
        // [GIVEN] Sales Order '1002', where "Sell-To Customer No." is 'A', "Prepayment %" is 100.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Prepayment %", 100);
        SalesLine.Modify(true);
        ContextDimRecID[1] := SalesHeader.RecordId;
        ContextDimRecID[2] := SalesLine.RecordId;

        // [WHEN] Post prepayment Invoice
        PostSalesPrepmtDocument(SalesHeader);

        // [THEN] Error message is <blank>
        Assert.ExpectedError('');
        // [THEN] Opened page "Error Messages" with two lines, where "Error Message" is 'Dimension Department is blocked'
        // [THEN] 1st line: "Context" is 'Sales Header: Order, 1002'; "Source" is 'Dimension Value: Department, ADM'
        // [THEN] 2nd line: "Context" is 'Sales Line: Order, 1002, 10000'; "Source" is 'Dimension Value: Department, ADM'
        VerifyHeaderDimErrors(ContextDimRecID, 2, ExpectedErrorMessage, SourceDimRecID, SourceFieldNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T151_SalesLinesPrepmtWithBlockedDimensionAndCombination()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Dimension: Record Dimension;
        DimensionCombination: Record "Dimension Combination";
        DimensionValue: array[3] of Record "Dimension Value";
        SourceDimRecID: array[10] of RecordID;
        LineRecID: array[10] of RecordID;
        CustomerNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
        ExpectedCallStack: array[10] of Text;
        DimSetID: array[2] of Integer;
    begin
        // [FEATURE] [Sales] [Prepayment]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains two lines for blocked dimension and combination used in two document lines.
        Initialize();
        // [GIVEN] Combination of 'Area' and 'Salesperson' dimensions is blocked
        LibraryDimension.CreateDimWithDimValue(DimensionValue[1]);
        LibraryDimension.CreateDimWithDimValue(DimensionValue[2]);
        LibraryDimension.CreateDimensionCombination(
          DimensionCombination, DimensionValue[1]."Dimension Code", DimensionValue[2]."Dimension Code");
        DimensionCombination."Combination Restriction" := DimensionCombination."Combination Restriction"::Blocked;
        DimensionCombination.Modify();
        ExpectedErrorMessage[1] :=
          StrSubstNo(DimCombBlockedErr, DimensionValue[1]."Dimension Code", DimensionValue[2]."Dimension Code");
        SourceDimRecID[1] := DimensionCombination.RecordId;
        DimSetID[1] := GetDimensionSetID(DimensionValue);
        ExpectedCallStack[1] := 'DimensionManagement(CodeUnit 408).CheckDimComb ';
        // [GIVEN] Dimension 'Department' is blocked
        Clear(DimensionValue);
        LibraryDimension.CreateDimWithDimValue(DimensionValue[3]);
        ExpectedErrorMessage[2] := SetDimensionBlocked(DimensionValue[3]."Dimension Code", Dimension);
        SourceDimRecID[2] := Dimension.RecordId;
        DimSetID[2] := GetDimensionSetID(DimensionValue);
        ExpectedCallStack[2] := 'DimensionManagement(CodeUnit 408).CheckDim ';

        // [GIVEN] Customer 'A'
        LibrarySales.CreatePrepaymentVATSetup(GLAccount, GLAccount."Gen. Posting Type"::Sale);
        CustomerNo :=
          LibrarySales.CreateCustomerWithBusPostingGroups(
            GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        // [GIVEN] Sales Order '1004', where "Sell-To Customer No." is 'A', "Prepayment %" is 100
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Prepayment %", 100);
        // [GIVEN] Dimensions 'Area' and 'Salesperson' are set in the first line.
        SalesLine.Validate("Dimension Set ID", DimSetID[1]);
        SalesLine.Modify();
        LineRecID[1] := SalesLine.RecordId;
        // [GIVEN] Dimensions 'Department' is set in the second line.
        SalesLine."Line No." += 10000;
        SalesLine.Validate("Dimension Set ID", DimSetID[2]);
        SalesLine.Insert();
        LineRecID[2] := SalesLine.RecordId;
        Commit();

        // [WHEN] Post prepayment Invoice
        PostSalesPrepmtDocument(SalesHeader);

        // [THEN] Error message is <blank>
        Assert.ExpectedError('');
        // [THEN] Opened page "Error Messages", where are two lines:
        // [THEN] 1st line: Error message is 'Dimensions Area and Salesperson cannot be used concurrently'; "Context" is 'Sales Line: Order, 1004, 10000'
        // [THEN] 2nd line: Error message is 'Dimension Department is blocked'; "Context" is 'Sales Line: Order, 1004, 20000'
        VerifyLineDimErrors(LineRecID, 2, ExpectedErrorMessage, SourceDimRecID, ExpectedCallStack);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T200_PurchHeaderWithBlockedDimensionValue()
    var
        PurchHeader: Record "Purchase Header";
        DimensionValue: array[2] of Record "Dimension Value";
        ErrorMessagesPage: TestPage "Error Messages";
        PurchOrderPage: TestPage "Purchase Order";
        VendorNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
        ExpectedSupportURL: Text;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains one line for blocked dimension value.
        Initialize();
        // [GIVEN] Forward Link "Working With Dims" has Link 'X'
        ExpectedSupportURL := SetupSupportURL();
        // [GIVEN] Vendor 'A'
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [GIVEN] Dimension value 'Department','ADM' is blocked
        ExpectedErrorMessage[1] := CreateVendBlockedDimensionValue(DimensionValue[1], VendorNo);
        // [GIVEN] Purchase Order '1002', where "Buy-from Vendor No." is 'A'
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);

        // [WHEN] Post Purchase Order '1002'
        PostPurchDocument(PurchHeader, CODEUNIT::"Purch.-Post");

        // [THEN] Opened page "Error Messages" with one line, where "Error Message" is 'Dimension Department is blocked'
        // [THEN] "Context" is 'Purchase Header: Order, 1002'; "Source" is 'Dimension Value: Department, ADM'; "Field Name" is 'Blocked';
        // [THEN] "Support URL" is 'X'
        VerifyHeaderDimError(
          PurchHeader.RecordId, DimensionValue[1].RecordId, DimensionValue[1].FieldNo(Blocked), ExpectedErrorMessage, ExpectedSupportURL);

        // [WHEN] Run action "Open Related Record"
        PurchOrderPage.Trap();
        LibraryErrorMessage.GetTestPage(ErrorMessagesPage);
        ErrorMessagesPage.First();
        ErrorMessagesPage.OpenRelatedRecord.Invoke();
        // [THEN] "Purchase Order" page is open on Purchase Order '1002'
        PurchOrderPage."No.".AssertEquals(PurchHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T201_PurchHeaderWithDeletedDimensionValue()
    var
        PurchHeader: Record "Purchase Header";
        DimensionValue: Record "Dimension Value";
        VendorNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
        ExpectedSupportURL: Text;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains one line for deleted dimension value..
        Initialize();
        // [GIVEN] Forward Link "Working With Dims" has Link 'X'
        ExpectedSupportURL := SetupSupportURL();
        // [GIVEN] Vendor 'A', where dimension value 'Department','ADM' is default
        VendorNo := CreateVendDefaultDimensionValue(DimensionValue);
        // [GIVEN] Purchase Order '1002', where "Buy-from Vendor No." is 'A'
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        // [GIVEN] Dimension value 'Department','ADM' is deleted
        DimensionValue.Delete();
        ExpectedErrorMessage[1] := StrSubstNo(DimValueMissingErr, DimensionValue."Dimension Code", DimensionValue.Code);

        // [WHEN] Post Purchase Order '1002'
        PostPurchDocument(PurchHeader, CODEUNIT::"Purch.-Post");

        // [THEN] Opened page "Error Messages" with one line, where "Error Message" is 'Dimension values for Department is missing.'
        // [THEN] "Context" is 'Purchase Header: Order, 1002'
        // [THEN] "Source" is <blank>; "Support URL" is 'X'
        VerifyHeaderDimError(PurchHeader.RecordId, DummyBlankRecID, 0, ExpectedErrorMessage, ExpectedSupportURL);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T202_PurchHeaderWithNotAllowedDimensionValue()
    var
        PurchHeader: Record "Purchase Header";
        DimensionValue: Record "Dimension Value";
        VendorNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains one line for not allowed dimension value.
        Initialize();
        // [GIVEN] Vendor 'A', where dimension value 'Department','ADM' is default
        VendorNo := CreateVendDefaultDimensionValue(DimensionValue);
        // [GIVEN] Dimension value 'Department','ADM' is not allowed ("Dimension Value Type" = 'Heading')
        SetNotAllowedDimensionValueType(DimensionValue, ExpectedErrorMessage[1]);
        // [GIVEN] Purchase Order '1002', where "Buy-from Vendor No." is 'A'
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);

        // [WHEN] Post Purchase Order '1002'
        PostPurchDocument(PurchHeader, CODEUNIT::"Purch.-Post");

        // [THEN] Opened page "Error Messages" with one line, where "Error Message" is 'Dimension Value Type must not be Heading'
        // [THEN] "Context" is 'Purchase Header: Order, 1002'; "Source" is 'Dimension Value: Department, ADM'; "Field Name" is 'Dimension Value Type'
        VerifyHeaderDimError(
          PurchHeader.RecordId, DimensionValue.RecordId, DimensionValue.FieldNo("Dimension Value Type"), ExpectedErrorMessage, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T203_PurchHeaderWithBlockedDimension()
    var
        PurchHeader: Record "Purchase Header";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        VendorNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains one line for blocked dimension.
        Initialize();
        // [GIVEN] Vendor 'A', where dimension value 'Department','ADM' is default
        VendorNo := CreateVendDefaultDimensionValue(DimensionValue);
        // [GIVEN] Purchase Order '1002', where "Buy-from Vendor No." is 'A'
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        // [GIVEN] Dimension 'Department' is blocked
        ExpectedErrorMessage[1] := SetDimensionBlocked(DimensionValue."Dimension Code", Dimension);

        // [WHEN] Post Purchase Order '1002'
        PostPurchDocument(PurchHeader, CODEUNIT::"Purch.-Post");

        // [THEN] Opened page "Error Messages" with one line, where "Error Message" is 'Dimension Department is blocked'
        // [THEN] "Context" is 'Purchase Header: Order, 1002'; "Source" is 'Dimension Value: Department, ADM'; "Field Name" is 'Blocked'
        VerifyHeaderDimError(PurchHeader.RecordId, Dimension.RecordId, Dimension.FieldNo(Blocked), ExpectedErrorMessage, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T204_PurchHeaderWithDeletedDimension()
    var
        PurchHeader: Record "Purchase Header";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        VendorNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains one line for deleted dimension.
        Initialize();
        // [GIVEN] Vendor 'A', where dimension value 'Department','ADM' is default
        VendorNo := CreateVendDefaultDimensionValue(DimensionValue);
        // [GIVEN] Purchase Order '1002', where "Buy-from Vendor No." is 'A'
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        // [GIVEN] Dimension 'Department' is deleted
        Dimension.Get(DimensionValue."Dimension Code");
        Dimension.Delete();
        ExpectedErrorMessage[1] := StrSubstNo(DimensionMissingErr, DimensionValue."Dimension Code");

        // [WHEN] Post Purchase Order '1002'
        PostPurchDocument(PurchHeader, CODEUNIT::"Purch.-Post");

        // [THEN] Opened page "Error Messages" with one line, where "Error Message" is 'Dimension Department cannot be found'
        // [THEN] "Context" is 'Purchase Header: Order, 1002'; "Source" is <blank>
        VerifyHeaderDimError(PurchHeader.RecordId, DummyBlankRecID, 0, ExpectedErrorMessage, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T205_PurchHeaderWithBlockedDimensionAndDimValue()
    var
        PurchHeader: Record "Purchase Header";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        ContextDimRecID: array[10] of RecordID;
        SourceDimRecID: array[10] of RecordID;
        SourceFieldNo: array[10] of Integer;
        VendorNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains two lines: for blocked dimension and for blocked dimension value.
        Initialize();
        // [GIVEN] Vendor 'A' with default dimensions: 'Department' and 'Project'.
        VendorNo := CreateVendDefaultDimensionValue(DimensionValue);
        // [GIVEN] Dimension 'Department' is blocked
        ExpectedErrorMessage[1] := SetDimensionBlocked(DimensionValue."Dimension Code", Dimension);
        SourceDimRecID[1] := Dimension.RecordId;
        SourceFieldNo[1] := Dimension.FieldNo(Blocked);
        // [GIVEN] Dimension value 'Project','TOYOTA' is blocked
        ExpectedErrorMessage[2] := CreateVendBlockedDimensionValue(DimensionValue, VendorNo);
        SourceDimRecID[2] := DimensionValue.RecordId;
        SourceFieldNo[2] := DimensionValue.FieldNo(Blocked);

        // [GIVEN] Purchase Order '1002', where "Buy-from Vendor No." is 'A'
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        SetArray(ContextDimRecID, 1, 3, PurchHeader.RecordId);
        ExpectedErrorMessage[3] := DocumentErrorsMgt.GetNothingToPostErrorMsg();

        // [WHEN] Post Purchase Order '1002'
        PostPurchDocument(PurchHeader, CODEUNIT::"Purch.-Post");

        // [THEN] Opened page "Error Messages", where are two lines (the third is 'Nothing to post'):
        // [THEN]  1st Dimension Errors line, where "Error Message" is 'Dimension Department is blocked'
        // [THEN] "Context" is 'Purchase Header: Order, 1002'; "Source" is 'Dimension: Department'
        // [THEN] 2nd Dimension Errors line, where "Error Message" is 'Dimension value: Project,TOYOTA is blocked'
        // [THEN] "Context" is 'Purchase Header: Order, 1002'; "Source" is 'Dimension Value: Project,TOYOTA'
        VerifyHeaderDimErrors(ContextDimRecID, 3, ExpectedErrorMessage, SourceDimRecID, SourceFieldNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T206_PurchHeaderWithBlankMandatoryDimensions()
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
        DefaultDimension: array[3] of Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        ContextDimRecID: array[10] of RecordID;
        SourceDimRecID: array[10] of RecordID;
        SourceFieldNo: array[10] of Integer;
        VendorNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains one line for blank mandatory dimension.
        Initialize();
        // [GIVEN] Mandatory Default Dimension 'Project' is <blank> for table 'Vendor'
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension[1], '', DimensionValue."Dimension Code", '');
        DefaultDimension[1]."Value Posting" := DefaultDimension[1]."Value Posting"::"Code Mandatory";
        DefaultDimension[1].Modify();
        ExpectedErrorMessage[1] := StrSubstNo(SelectDimValueErr, DimensionValue."Dimension Code");
        SourceDimRecID[1] := DefaultDimension[1].RecordId;
        SourceFieldNo[1] := DefaultDimension[1].FieldNo("Value Posting");

        // [GIVEN] Vendor 'A'
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [GIVEN] Mandatory Default Dimension 'Department' is <blank> for Vendor 'A'
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension[2], VendorNo, DimensionValue."Dimension Code", '');
        DefaultDimension[2]."Value Posting" := DefaultDimension[2]."Value Posting"::"Code Mandatory";
        DefaultDimension[2].Modify();
        ExpectedErrorMessage[2] := StrSubstNo(SelectDimValueForRecErr, DimensionValue."Dimension Code", Vendor.TableName, VendorNo);
        SourceDimRecID[2] := DefaultDimension[2].RecordId;
        SourceFieldNo[2] := DefaultDimension[2].FieldNo("Value Posting");

        // [GIVEN] Mandatory Default Dimension 'Department' is <blank> for table 'Vendor'
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension[3], '', DimensionValue."Dimension Code", '');

        // [GIVEN] Purchase Order '1002', where "Buy-from Vendor No." is 'A'
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        SetArray(ContextDimRecID, 1, 3, PurchHeader.RecordId);
        ExpectedErrorMessage[3] := DocumentErrorsMgt.GetNothingToPostErrorMsg();

        // [WHEN] Post Purchase Order '1002'
        PostPurchDocument(PurchHeader, CODEUNIT::"Purch.-Post");

        // [THEN] Opened page "Error Messages", where are two lines (the third is 'Nothing to post'):
        // [THEN] 1st Dimension Errors line, where "Error Message" is 'Select Dimension Value code for Dimension Code Project'
        // [THEN] "Context" is 'Purchase Header: Order, 1002'; "Source" is 'Default Dimension: 18, <>, Project'
        // [THEN] 2nd Dimension Errors line, where "Error Message" is 'Select Dimension Value code for Dimension Code Department for Vendor A'
        // [THEN] "Context" is 'Purchase Header: Order, 1002'; "Source" is 'Default Dimension: 18, A, Department'
        VerifyHeaderDimErrors(ContextDimRecID, 3, ExpectedErrorMessage, SourceDimRecID, SourceFieldNo);
        // TearDown
        DefaultDimension[1].Delete(); // remove mandatory dim set for all customers
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T207_PurchHeaderWithBlankMandatoryAndBlockedDimensions()
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
        DefaultDimension: array[3] of Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        ContextDimRecID: array[10] of RecordID;
        SourceDimRecID: array[10] of RecordID;
        SourceFieldNo: array[10] of Integer;
        VendorNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains one line for blank mandatory dimension.
        Initialize();
        // [GIVEN] Vendor 'A'
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [GIVEN] "No Code" Default Dimension 'Project' is filled for Vendor 'A'
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension[2], VendorNo, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension[2]."Value Posting" := DefaultDimension[2]."Value Posting"::"No Code";
        DefaultDimension[2].Modify();
        ExpectedErrorMessage[2] :=
          StrSubstNo(
            DimValueSameOrNoCodeErr,
            DefaultDimension[2].FieldCaption("Dimension Value Code"), BlankLbl,
            DefaultDimension[2].FieldCaption("Dimension Code"), DefaultDimension[2]."Dimension Code",
            Vendor.TableCaption(), VendorNo,
            DimensionValue.Code);
        SourceDimRecID[2] := DefaultDimension[2].RecordId;
        SourceFieldNo[2] := DefaultDimension[2].FieldNo("Value Posting");

        // [GIVEN] Dimension Value 'Department: ADM' is blocked
        ExpectedErrorMessage[1] := CreateVendBlockedDimensionValue(DimensionValue, VendorNo);
        SourceDimRecID[1] := DimensionValue.RecordId;
        SourceFieldNo[1] := DimensionValue.FieldNo(Blocked);

        // [GIVEN] Purchase Order '1002', where "Buy-from Vendor No." is 'A'
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        SetArray(ContextDimRecID, 1, 3, PurchHeader.RecordId);
        ExpectedErrorMessage[3] := DocumentErrorsMgt.GetNothingToPostErrorMsg();

        // [WHEN] Post Purchase Order '1002'
        PostPurchDocument(PurchHeader, CODEUNIT::"Purch.-Post");

        // [THEN] Opened page "Error Messages", where are two lines (the third is 'Nothing to post'):
        // [THEN] 1st Dimension Errors line, where "Error Message" is '(Error: Dimension Value Department - ADM is blocked.)'.
        // [THEN] "Context" is 'Purchase Header: Order, 1002'; "Source" is 'Dimension Value: Department, ADM'
        // [THEN] 2nd Dimension Errors line, where "Error Message" is 'Select Dimension Value code for Dimension Code Department for Vendor A'
        // [THEN] "Context" is 'Purchase Header: Order, 1002'; "Source" is 'Default Dimension: 18, A, Department'
        VerifyHeaderDimErrors(ContextDimRecID, 3, ExpectedErrorMessage, SourceDimRecID, SourceFieldNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T208_PurchHeaderWithWrongSameCodeDimensions()
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
        DefaultDimension: array[3] of Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
        ContextDimRecID: array[10] of RecordID;
        SourceDimRecID: array[10] of RecordID;
        SourceFieldNo: array[10] of Integer;
        VendorNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains one line for incorrect "Same Code" dimension.
        Initialize();
        // [GIVEN] Vendor 'X'
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [GIVEN] "Same Code" Default Dimension 'Project' is 'A' for table 'Vendor'
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension[1], '', DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension[1]."Value Posting" := DefaultDimension[1]."Value Posting"::"Same Code";
        DefaultDimension[1].Modify();
        ExpectedErrorMessage[1] :=
          StrSubstNo(
            SameCodeMissingDimErr,
            DefaultDimension[1].FieldCaption("Dimension Code"), DefaultDimension[1]."Dimension Code",
            DefaultDimension[1].FieldCaption("Dimension Value Code"), DefaultDimension[1]."Dimension Value Code");
        SourceDimRecID[1] := DefaultDimension[1].RecordId;
        SourceFieldNo[1] := DefaultDimension[1].FieldNo("Value Posting");

        // [GIVEN] Mandatory Default Dimension 'Department' is '<blank>' for Vendor 'X'
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension[2], VendorNo, DimensionValue."Dimension Code", '');
        DefaultDimension[2]."Value Posting" := DefaultDimension[2]."Value Posting"::"Same Code";
        DefaultDimension[2].Modify();
        ExpectedErrorMessage[2] :=
          StrSubstNo(
            DimValueBlankSameCodeRecErr,
            DefaultDimension[2].FieldCaption("Dimension Code"), DefaultDimension[2]."Dimension Code",
            Vendor.TableName, VendorNo);
        SourceDimRecID[2] := DefaultDimension[2].RecordId;
        SourceFieldNo[2] := DefaultDimension[2].FieldNo("Value Posting");

        // [GIVEN] Purchase Order '1002', where "Buy-from Vendor No." is 'X'
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        SetArray(ContextDimRecID, 1, 3, PurchHeader.RecordId);
        ExpectedErrorMessage[3] := DocumentErrorsMgt.GetNothingToPostErrorMsg();
        // [GIVEN] Change dimensions on the header: 'Project' is 'B', 'Department' is <blank>
        DimMgt.GetDimensionSet(TempDimSetEntry, PurchHeader."Dimension Set ID");
        ChangeDimValueInSet(TempDimSetEntry, DefaultDimension[1]."Dimension Code", '');
        LibraryDimension.CreateDimensionValue(DimensionValue, DefaultDimension[2]."Dimension Code");
        AddDimValueInSet(TempDimSetEntry, DefaultDimension[2]."Dimension Code", DimensionValue.Code);
        PurchHeader.Validate("Dimension Set ID", DimMgt.GetDimensionSetID(TempDimSetEntry));
        PurchHeader.Modify();

        // [WHEN] Post Purchase Order '1002'
        PostPurchDocument(PurchHeader, CODEUNIT::"Purch.-Post");

        // [THEN] Opened page "Error Messages", where are two lines (the third is 'Nothing to post'):
        // [THEN] 1st Dimension Errors line, where "Error Message" is 'Select Dimension Value Code A for Dimension Code Project'
        // [THEN] "Context" is 'Purchase Header: Order, 1002'; "Source" is 'Default Dimension: 18, <>, Project'
        // [THEN] 2nd Dimension Errors line, where "Error Message" is 'Select Dimension Code Department must not be blank for Vendor X'
        // [THEN] "Context" is 'Purchase Header: Order, 1002'; "Source" is 'Default Dimension: 18, X, Department'
        VerifyHeaderDimErrors(ContextDimRecID, 3, ExpectedErrorMessage, SourceDimRecID, SourceFieldNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T209_PurchHeaderWithBlockedDimComb()
    var
        PurchHeader: Record "Purchase Header";
        DefaultDimension: array[3] of Record "Default Dimension";
        DimensionCombination: array[2] of Record "Dimension Combination";
        DimensionValue: Record "Dimension Value";
        DimensionValueCombination: Record "Dimension Value Combination";
        ContextDimRecID: array[10] of RecordID;
        SourceDimRecID: array[10] of RecordID;
        SourceFieldNo: array[10] of Integer;
        VendorNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains one line for blocked dimension combination.
        Initialize();
        // [GIVEN] Vendor 'X'
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [GIVEN] Default Dimension 'Project' is 'A' for Vendor 'X'
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension[1], VendorNo, DimensionValue."Dimension Code", DimensionValue.Code);
        // [GIVEN] Default Dimension 'Department' is 'B' for Vendor 'X'
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension[2], VendorNo, DimensionValue."Dimension Code", DimensionValue.Code);
        // [GIVEN] Default Dimension 'Salesperson' is 'S' for Vendor 'X'
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension[3], VendorNo, DimensionValue."Dimension Code", DimensionValue.Code);

        ExpectedErrorMessage[1] :=
          StrSubstNo(DimCombBlockedErr, DefaultDimension[1]."Dimension Code", DefaultDimension[2]."Dimension Code");
        ExpectedErrorMessage[2] :=
          StrSubstNo(
            DimCombLimitedErr, DefaultDimension[1]."Dimension Code", DefaultDimension[1]."Dimension Value Code",
            DefaultDimension[3]."Dimension Code", DefaultDimension[3]."Dimension Value Code");

        // [GIVEN] Combination of dimension values 'Project' and 'Department' is blocked
        LibraryDimension.CreateDimensionCombination(
          DimensionCombination[1], DefaultDimension[1]."Dimension Code", DefaultDimension[2]."Dimension Code");
        DimensionCombination[1]."Combination Restriction" := DimensionCombination[1]."Combination Restriction"::Blocked;
        DimensionCombination[1].Modify();
        SourceDimRecID[1] := DimensionCombination[1].RecordId;
        SourceFieldNo[1] := DimensionCombination[1].FieldNo("Combination Restriction");
        // [GIVEN] Combination of dimension values 'Project' - 'A' and 'Salesperson' - 'S' is blocked
        LibraryDimension.CreateDimensionCombination(
          DimensionCombination[2], DefaultDimension[1]."Dimension Code", DefaultDimension[3]."Dimension Code");
        DimensionCombination[2]."Combination Restriction" := DimensionCombination[2]."Combination Restriction"::Limited;
        DimensionCombination[2].Modify();
        LibraryDimension.CreateDimValueCombination(
          DimensionValueCombination,
          DefaultDimension[1]."Dimension Code", DefaultDimension[3]."Dimension Code",
          DefaultDimension[1]."Dimension Value Code", DefaultDimension[3]."Dimension Value Code");
        SourceDimRecID[2] := DimensionValueCombination.RecordId;

        // [GIVEN] Purchase Order '1002', where "Buy-from Vendor No." is 'X'
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        SetArray(ContextDimRecID, 1, 3, PurchHeader.RecordId);
        ExpectedErrorMessage[3] := DocumentErrorsMgt.GetNothingToPostErrorMsg();

        // [WHEN] Post Purchase Order '1002'
        PostPurchDocument(PurchHeader, CODEUNIT::"Purch.-Post");

        // [THEN] Opened page "Error Messages", where are two lines (the third is 'Nothing to post'):
        // [THEN] 1st Dimension Errors line, where "Error Message" is 'Select Dimension Value Code A for Dimension Code Project'
        // [THEN] "Context" is 'Purchase Header: Order, 1002'; "Source" is 'Dimension Combination: Project, Salesperson'
        // [THEN] 2nd Dimension Errors line, where "Error Message" is 'Select Dimension Code Department must not be blank for Vendor X'
        // [THEN] "Context" is 'Purchase Header: Order, 1002'; "Source" is 'Dimension Value Combination: Project,A,Salesperson,S'
        VerifyHeaderDimErrors(ContextDimRecID, 3, ExpectedErrorMessage, SourceDimRecID, SourceFieldNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T220_PurchLineWithBlockedDimensionAndCombination()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Dimension: Record Dimension;
        DimensionCombination: Record "Dimension Combination";
        DimensionValue: array[3] of Record "Dimension Value";
        SourceDimRecID: array[10] of RecordID;
        LineRecID: array[10] of RecordID;
        VendorNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
        ExpectedCallStack: array[10] of Text;
        DimSetID: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains two lines for blocked dimension and combination used in the document line.
        Initialize();
        // [GIVEN] Combination of 'Area' and 'Purchaseperson' dimensions is blocked
        LibraryDimension.CreateDimWithDimValue(DimensionValue[1]);
        LibraryDimension.CreateDimWithDimValue(DimensionValue[2]);
        LibraryDimension.CreateDimensionCombination(
          DimensionCombination, DimensionValue[1]."Dimension Code", DimensionValue[2]."Dimension Code");
        DimensionCombination."Combination Restriction" := DimensionCombination."Combination Restriction"::Blocked;
        DimensionCombination.Modify();
        ExpectedErrorMessage[1] :=
          StrSubstNo(DimCombBlockedErr, DimensionValue[1]."Dimension Code", DimensionValue[2]."Dimension Code");
        SourceDimRecID[1] := DimensionCombination.RecordId;
        ExpectedCallStack[1] := 'DimensionManagement(CodeUnit 408).CheckDimComb ';
        // [GIVEN] Dimension 'Department' is blocked
        LibraryDimension.CreateDimWithDimValue(DimensionValue[3]);
        ExpectedErrorMessage[2] := SetDimensionBlocked(DimensionValue[3]."Dimension Code", Dimension);
        SourceDimRecID[2] := Dimension.RecordId;
        DimSetID := GetDimensionSetID(DimensionValue);
        ExpectedCallStack[2] := 'DimensionManagement(CodeUnit 408).CheckDim ';

        // [GIVEN] Vendor 'A'
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [GIVEN] Purchase Invoice '1004', where "Sell-To Vendor No." is 'A'
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, VendorNo);
        // [GIVEN] Dimensions 'Department', 'Area' and 'Purchaseperson' are set in the lines.
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.ModifyAll("Dimension Set ID", DimSetID);
        Commit();
        PurchaseLine.FindFirst();
        LineRecID[1] := PurchaseLine.RecordId;
        LineRecID[2] := PurchaseLine.RecordId;

        // [WHEN] Post Purchase Invoice '1004'
        PostPurchDocument(PurchaseHeader, CODEUNIT::"Purch.-Post");

        // [THEN] Error message is <blank>
        Assert.ExpectedError('');
        // [THEN] Opened page "Error Messages", where are two lines:
        // [THEN] 1st line, where Error message is 'Dimensions Area and Purchaseperson cannot be used concurrently'
        // [THEN] 2nd line, where Error message is 'Dimension Department is blocked'
        // [THEN] "Source Record ID" in both lines is 'Purchase Line: Order, 1004, 10000'
        VerifyLineDimErrors(LineRecID, 2, ExpectedErrorMessage, SourceDimRecID, ExpectedCallStack);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T221_PurchLinesWithBlockedDimensionAndCombination()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Dimension: Record Dimension;
        DimensionCombination: Record "Dimension Combination";
        DimensionValue: array[3] of Record "Dimension Value";
        CheckDimensionsOnPosting: Codeunit "Check Dimensions On Posting";
        SourceDimRecID: array[10] of RecordID;
        ContextRecID: array[10] of RecordID;
        VendorNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
        ExpectedCallStack: array[10] of Text;
        DimSetID: array[2] of Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains two lines for blocked dimension and combination used in two document lines.
        Initialize();
        // [GIVEN] Combination of 'Area' and 'Purchaseperson' dimensions is blocked
        LibraryDimension.CreateDimWithDimValue(DimensionValue[1]);
        LibraryDimension.CreateDimWithDimValue(DimensionValue[2]);
        LibraryDimension.CreateDimensionCombination(
          DimensionCombination, DimensionValue[1]."Dimension Code", DimensionValue[2]."Dimension Code");
        DimensionCombination."Combination Restriction" := DimensionCombination."Combination Restriction"::Blocked;
        DimensionCombination.Modify();
        ExpectedErrorMessage[1] :=
          StrSubstNo(DimCombBlockedErr, DimensionValue[1]."Dimension Code", DimensionValue[2]."Dimension Code");
        SourceDimRecID[1] := DimensionCombination.RecordId;
        DimSetID[1] := GetDimensionSetID(DimensionValue);
        ExpectedCallStack[1] := 'DimensionManagement(CodeUnit 408).CheckDimComb ';
        // [GIVEN] Dimension 'Department' is blocked
        Clear(DimensionValue);
        LibraryDimension.CreateDimWithDimValue(DimensionValue[3]);
        ExpectedErrorMessage[2] := SetDimensionBlocked(DimensionValue[3]."Dimension Code", Dimension);
        SourceDimRecID[2] := Dimension.RecordId;
        DimSetID[2] := GetDimensionSetID(DimensionValue);
        ExpectedCallStack[2] := 'DimensionManagement(CodeUnit 408).CheckDim ';

        // [GIVEN] Vendor 'A'
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [GIVEN] Purchase Invoice '1004', where "Sell-To Vendor No." is 'A'
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, VendorNo);
        // [GIVEN] Expected the thrid error on after document check
        BindSubscription(CheckDimensionsOnPosting); // to throw an error in OnAfterCheckPurchDoc
        ContextRecID[3] := PurchaseHeader.RecordId;
        Clear(SourceDimRecID[3]);
        ExpectedErrorMessage[3] := OnAfterCheckDocErr;
        ExpectedCallStack[3] := '"Purch.-Post"(CodeUnit 90).OnAfterCheckPurchDoc(Event) ';
        // [GIVEN] Dimensions 'Area' and 'Purchaseperson' are set in the first line.
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Dimension Set ID", DimSetID[1]);
        PurchaseLine.Modify();
        ContextRecID[1] := PurchaseLine.RecordId;
        // [GIVEN] Dimensions 'Department' is set in the second line.
        PurchaseLine."Line No." += 10000;
        PurchaseLine.Validate("Dimension Set ID", DimSetID[2]);
        PurchaseLine.Insert();
        ContextRecID[2] := PurchaseLine.RecordId;
        Commit();

        // [WHEN] Post Purchase Invoice '1004'
        PostPurchDocument(PurchaseHeader, CODEUNIT::"Purch.-Post");

        // [THEN] Opened page "Error Messages", where are two lines:
        // [THEN] 1st line: Error message is 'Dimensions Area and Purchaseperson cannot be used concurrently'; "Context" is 'Purchase Line: Order, 1004, 10000'
        // [THEN] 2nd line: Error message is 'Dimension Department is blocked'; "Context" is 'Purchase Line: Order, 1004, 20000'
        // [THEN] 3rd line: Error message is 'OnAfterCheckDoc'; "Context" is 'Purchase Header: Order, 1004'
        VerifyLineDimErrors(ContextRecID, 3, ExpectedErrorMessage, SourceDimRecID, ExpectedCallStack);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T230_PurchHeaderPreviewWithBlockedDimensionAndDimValue()
    var
        PurchHeader: Record "Purchase Header";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        ContextDimRecID: array[10] of RecordID;
        SourceDimRecID: array[10] of RecordID;
        SourceFieldNo: array[10] of Integer;
        VendorNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Purchase] [Preview]
        // [SCENARIO] Failed posting preview opens "Error Messages" page that contains two lines: for blocked dimension and for blocked dimension value.
        Initialize();
        // [GIVEN] Vendor 'A' with default dimensions: 'Department' and 'Project'.
        VendorNo := CreateVendDefaultDimensionValue(DimensionValue);
        // [GIVEN] Dimension 'Department' is blocked
        ExpectedErrorMessage[1] := SetDimensionBlocked(DimensionValue."Dimension Code", Dimension);
        SourceDimRecID[1] := Dimension.RecordId;
        SourceFieldNo[1] := Dimension.FieldNo(Blocked);
        // [GIVEN] Dimension value 'Project','TOYOTA' is blocked
        ExpectedErrorMessage[2] := CreateVendBlockedDimensionValue(DimensionValue, VendorNo);
        SourceDimRecID[2] := DimensionValue.RecordId;
        SourceFieldNo[2] := DimensionValue.FieldNo(Blocked);

        // [GIVEN] Purchase Order '1002', where "Buy-from Vendor No." is 'A'
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        SetArray(ContextDimRecID, 1, 3, PurchHeader.RecordId);
        ExpectedErrorMessage[3] := DocumentErrorsMgt.GetNothingToPostErrorMsg();

        // [WHEN] Preview Posting of Purchase Order '1002'
        asserterror PreviewPurchDocument(PurchHeader);

        // [THEN] Error message is <blank>
        Assert.ExpectedError('');
        // [THEN] Opened page "Error Messages", where are two lines (the third is 'Nothing to post'):
        // [THEN]  1st Dimension Errors line, where "Error Message" is 'Dimension Department is blocked'
        // [THEN] "Context" is 'Purchase Header: Order, 1002'; "Source" is 'Dimension: Department'
        // [THEN] 2nd Dimension Errors line, where "Error Message" is 'Dimension value: Project,TOYOTA is blocked'
        // [THEN] "Context" is 'Purchase Header: Order, 1002'; "Source" is 'Dimension Value: Project,TOYOTA'
        VerifyHeaderDimErrors(ContextDimRecID, 3, ExpectedErrorMessage, SourceDimRecID, SourceFieldNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T240_BatchPostingPurchHeadersWithTwoDimErrors()
    var
        PurchHeader: Record "Purchase Header";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        PurchBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
        ContextDimRecID: array[10] of RecordID;
        SourceDimRecID: array[10] of RecordID;
        SourceFieldNo: array[10] of Integer;
        VendorNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Purchase] [Batch Posting]
        // [SCENARIO] Batch posting of two documents opens "Error Messages" page that contains three lines per document.
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(false);
        // [GIVEN] Vendor 'A' with default dimensions: 'Department' and 'Project'.
        VendorNo := CreateVendDefaultDimensionValue(DimensionValue);
        // [GIVEN] Dimension 'Department' is blocked
        ExpectedErrorMessage[1] := SetDimensionBlocked(DimensionValue."Dimension Code", Dimension);
        ExpectedErrorMessage[4] := ExpectedErrorMessage[1];
        ExpectedErrorMessage[3] := DocumentErrorsMgt.GetNothingToPostErrorMsg();
        SourceDimRecID[1] := Dimension.RecordId;
        SourceFieldNo[1] := Dimension.FieldNo(Blocked);
        SourceDimRecID[4] := SourceDimRecID[1];
        SourceFieldNo[4] := SourceFieldNo[1];
        // [GIVEN] Dimension value 'Project','TOYOTA' is blocked
        ExpectedErrorMessage[2] := CreateVendBlockedDimensionValue(DimensionValue, VendorNo);
        ExpectedErrorMessage[5] := ExpectedErrorMessage[2];
        ExpectedErrorMessage[6] := DocumentErrorsMgt.GetNothingToPostErrorMsg();
        SourceDimRecID[2] := DimensionValue.RecordId;
        SourceFieldNo[2] := DimensionValue.FieldNo(Blocked);
        SourceDimRecID[5] := SourceDimRecID[2];
        SourceFieldNo[5] := SourceFieldNo[2];

        // [GIVEN] Purchase Order '1002', where "Buy-from Vendor No." is 'A'
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        PurchHeaderToPost(PurchHeader);
        SetArray(ContextDimRecID, 1, 3, PurchHeader.RecordId);
        SourceDimRecID[3] := PurchHeader.RecordId;
        // [GIVEN] Purchase Order '1003', where "Buy-from Vendor No." is 'A'
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        PurchHeaderToPost(PurchHeader);
        SetArray(ContextDimRecID, 4, 6, PurchHeader.RecordId);
        SourceDimRecID[6] := PurchHeader.RecordId;

        // [WHEN] Post two Sales Orders '1002' and '1003' as a batch
        LibraryErrorMessage.TrapErrorMessages();
        PurchHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchBatchPostMgt.RunWithUI(PurchHeader, 2, '');

        // [THEN] Opened page "Error Messages" with six lines, where 2 are 'Nothing to post.':
        // [THEN] 3 lines for 'Purchase Header: Order, 1002' and 3 lines for 'Purchase Header: Order, 1003'
        VerifyHeaderDimErrors(ContextDimRecID, 6, ExpectedErrorMessage, SourceDimRecID, SourceFieldNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T241_BatchPostingPurchHeadersWithTwoDimErrorsBackground()
    var
        PurchHeader: array[3] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        ErrorMessage: Record "Error Message";
        PurchBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        SourceRecId: array[4] of RecordId;
        SourceDimRecID: array[2] of RecordID;
        SourceFieldNo: array[2] of Integer;
        VendorNo: Code[20];
        ExpectedErrorMessage: array[2] of Text;
        InitialErrorMessageRecordCount: Integer;
        i: Integer;
    begin
        // [FEATURE] [Purchase] [Batch Posting]
        // [SCENARIO] Batch posting (in background) of two documents opens "Error Messages" page that contains three lines per document.
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        InitialErrorMessageRecordCount := ErrorMessage.Count();
        // [GIVEN] Vendor 'A' with default dimensions: 'Department' and 'Project'.
        VendorNo := CreateVendDefaultDimensionValue(DimensionValue);
        // [GIVEN] Dimension 'Department' is blocked
        ExpectedErrorMessage[1] := SetDimensionBlocked(DimensionValue."Dimension Code", Dimension);
        SourceDimRecID[1] := Dimension.RecordId;
        SourceFieldNo[1] := Dimension.FieldNo(Blocked);
        // [GIVEN] Dimension value 'Project','TOYOTA' is blocked
        ExpectedErrorMessage[2] := CreateVendBlockedDimensionValue(DimensionValue, VendorNo);
        SourceDimRecID[2] := DimensionValue.RecordId;
        SourceFieldNo[2] := DimensionValue.FieldNo(Blocked);

        // [GIVEN] Purchase Order '1002', where "Buy-from Vendor No." is 'A'
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchHeader[1], VendorNo);
        PurchaseLine.SetRange("Document Type", PurchHeader[1]."Document Type");
        PurchaseLine.SetRange("Document No.", PurchHeader[1]."No.");
        PurchaseLine.FindFirst();
        SourceRecId[1] := PurchHeader[1].RecordId;
        SourceRecId[2] := PurchaseLine.RecordId;
        PurchHeaderToPost(PurchHeader[1]);

        // [GIVEN] Purchase Order '1003', where "Buy-from Vendor No." is 'A'
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchHeader[2], VendorNo);
        PurchaseLine.SetRange("Document Type", PurchHeader[2]."Document Type");
        PurchaseLine.SetRange("Document No.", PurchHeader[2]."No.");
        PurchaseLine.FindFirst();
        SourceRecId[3] := PurchHeader[2].RecordId;
        SourceRecId[4] := PurchaseLine.RecordId;
        PurchHeaderToPost(PurchHeader[2]);

        // [WHEN] Post two Sales Orders '1002' and '1003' as a batch
        PurchHeader[3].SetRange("Buy-from Vendor No.", VendorNo);
        PurchBatchPostMgt.RunWithUI(PurchHeader[3], 2, '');
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SourceRecID[1], true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SourceRecID[3], true);

        // [THEN] "Error Messages" contains 2 lines:
        // [THEN] 1 for 'Purchase Header: Order, 1002' and 1 line for 'Purchase Header: Order, 1003'
        Assert.RecordCount(ErrorMessage, InitialErrorMessageRecordCount + 2);
        for i := 1 to 4 do begin
            ErrorMessage.SetRange("Context Record ID", SourceRecId[i]);
            Assert.RecordCount(ErrorMessage, 0);
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T250_PurchHeaderPrepmtWithBlockedDimensionValue()
    var
        GLAccount: Record "G/L Account";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        DimensionValue: array[2] of Record "Dimension Value";
        ContextDimRecID: array[10] of RecordID;
        SourceDimRecID: array[10] of RecordID;
        SourceFieldNo: array[10] of Integer;
        VendorNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
    begin
        // [FEATURE] [Purchase] [Prepayment]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains two errors for blocked dimension value.
        Initialize();
        // [GIVEN] Vendor 'A'
        LibraryPurchase.CreatePrepaymentVATSetup(GLAccount, GLAccount."Gen. Posting Type"::Purchase);
        VendorNo :=
          LibraryPurchase.CreateVendorWithBusPostingGroups(
            GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        // [GIVEN] Dimension value 'Department','ADM' is blocked
        ExpectedErrorMessage[1] := CreateVendBlockedDimensionValue(DimensionValue[1], VendorNo);
        SourceDimRecID[1] := DimensionValue[1].RecordId;
        SourceFieldNo[1] := DimensionValue[1].FieldNo(Blocked);
        ExpectedErrorMessage[2] := ExpectedErrorMessage[1];
        SourceDimRecID[2] := DimensionValue[1].RecordId;
        SourceFieldNo[2] := SourceFieldNo[1];
        // [GIVEN] Purchase Order '1002', where "Buy-from Vendor No." is 'A', "Prepayment %" is 100
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Validate("Prepayment %", 100);
        PurchLine.Validate("Tax Area Code", '');
        PurchLine.Modify(true);
        ContextDimRecID[1] := PurchHeader.RecordId;
        ContextDimRecID[2] := PurchLine.RecordId;

        // [WHEN] Post prepayment Invoice
        PostPurchPrepmtDocument(PurchHeader);

        // [THEN] Error message is <blank>
        Assert.ExpectedError('');
        // [THEN] Opened page "Error Messages" with two lines, where "Error Message" is 'Dimension Department is blocked'
        // [THEN] 1st line: "Context" is 'Purchase Header: Order, 1002'; "Source" is 'Dimension Value: Department, ADM'
        // [THEN] 2nd line: "Context" is 'Purchase Line: Order, 1002, 10000'; "Source" is 'Dimension Value: Department, ADM'
        VerifyHeaderDimErrors(ContextDimRecID, 2, ExpectedErrorMessage, SourceDimRecID, SourceFieldNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T251_PurchLinesPrepmtWithBlockedDimensionAndCombination()
    var
        GLAccount: Record "G/L Account";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Dimension: Record Dimension;
        DimensionCombination: Record "Dimension Combination";
        DimensionValue: array[3] of Record "Dimension Value";
        SourceDimRecID: array[10] of RecordID;
        LineRecID: array[10] of RecordID;
        VendorNo: Code[20];
        ExpectedErrorMessage: array[10] of Text;
        ExpectedCallStack: array[10] of Text;
        DimSetID: array[2] of Integer;
    begin
        // [FEATURE] [Purchase] [Prepayment]
        // [SCENARIO] Failed posting opens "Error Messages" page that contains two lines for blocked dimension and combination used in two document lines.
        Initialize();
        // [GIVEN] Combination of 'Area' and 'Purchaseperson' dimensions is blocked
        LibraryDimension.CreateDimWithDimValue(DimensionValue[1]);
        LibraryDimension.CreateDimWithDimValue(DimensionValue[2]);
        LibraryDimension.CreateDimensionCombination(
          DimensionCombination, DimensionValue[1]."Dimension Code", DimensionValue[2]."Dimension Code");
        DimensionCombination."Combination Restriction" := DimensionCombination."Combination Restriction"::Blocked;
        DimensionCombination.Modify();
        ExpectedErrorMessage[1] :=
          StrSubstNo(DimCombBlockedErr, DimensionValue[1]."Dimension Code", DimensionValue[2]."Dimension Code");
        SourceDimRecID[1] := DimensionCombination.RecordId;
        DimSetID[1] := GetDimensionSetID(DimensionValue);
        ExpectedCallStack[1] := 'DimensionManagement(CodeUnit 408).CheckDimComb ';
        // [GIVEN] Dimension 'Department' is blocked
        Clear(DimensionValue);
        LibraryDimension.CreateDimWithDimValue(DimensionValue[3]);
        ExpectedErrorMessage[2] := SetDimensionBlocked(DimensionValue[3]."Dimension Code", Dimension);
        SourceDimRecID[2] := Dimension.RecordId;
        DimSetID[2] := GetDimensionSetID(DimensionValue);
        ExpectedCallStack[2] := 'DimensionManagement(CodeUnit 408).CheckDim ';

        // [GIVEN] Vendor 'A'
        LibraryPurchase.CreatePrepaymentVATSetup(GLAccount, GLAccount."Gen. Posting Type"::Purchase);
        VendorNo :=
          LibraryPurchase.CreateVendorWithBusPostingGroups(
            GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        // [GIVEN] Purchase Order '1004', where "Sell-To Vendor No." is 'A', "Prepayment %" is 100
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Validate("Prepayment %", 100);
        PurchLine.Validate("Tax Area Code", '');
        // [GIVEN] Dimensions 'Area' and 'Purchaseperson' are set in the first line.
        PurchLine.Validate("Dimension Set ID", DimSetID[1]);
        PurchLine.Modify(true);
        LineRecID[1] := PurchLine.RecordId;
        // [GIVEN] Dimensions 'Department' is set in the second line.
        PurchLine."Line No." += 10000;
        PurchLine.Validate("Dimension Set ID", DimSetID[2]);
        PurchLine.Insert();
        LineRecID[2] := PurchLine.RecordId;
        Commit();

        // [WHEN] Post prepayment Invoice
        PostPurchPrepmtDocument(PurchHeader);

        // [THEN] Error message is <blank>
        Assert.ExpectedError('');
        // [THEN] Opened page "Error Messages", where are two lines:
        // [THEN] 1st line: Error message is 'Dimensions Area and Purchaseperson cannot be used concurrently'; "Context" is 'Purchase Line: Order, 1004, 10000'
        // [THEN] 2nd line: Error message is 'Dimension Department is blocked'; "Context" is 'Purchase Line: Order, 1004, 20000'
        VerifyLineDimErrors(LineRecID, 2, ExpectedErrorMessage, SourceDimRecID, ExpectedCallStack);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T500_DimErrorsOpensDimValuesPageByDrilldown()
    var
        DimensionValue: Record "Dimension Value";
        TempErrorMessage: Record "Error Message" temporary;
        SalesHeader: Record "Sales Header";
        ErrorMessages: Page "Error Messages";
        ErrorMessagesPage: TestPage "Error Messages";
        DimensionValuesPage: TestPage "Dimension Values";
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO] Drilldown on "Source" opens "Dimension Values" page focused on the source record
        Initialize();
        // [GIVEN] Blocked Dimension Value 'Dimension Value: Department, ADM'
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.BlockDimensionValue(DimensionValue);
        // [GIVEN] Dim error, where "Source" = 'Dimension Value: Department, ADM'
        TempErrorMessage.Validate("Context Record ID", SalesHeader.RecordId);
        TempErrorMessage.Validate("Record ID", DimensionValue.RecordId);
        TempErrorMessage.Insert();

        // [GIVEN] Open ErrorMessages page
        ErrorMessages.SetRecords(TempErrorMessage);
        ErrorMessagesPage.Trap();
        ErrorMessages.Run();

        // [WHEN] Drill Down on "Source"
        DimensionValuesPage.Trap();
        ErrorMessagesPage.Source.DrillDown();
        // [THEN] "Dimension Values" page is open
        Assert.AreEqual(DimensionValue.Code, DimensionValuesPage.Code.Value, 'Dim Value Code');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T501_DimErrorsOpensDefaultDimsPageByDrilldown()
    var
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessages: Page "Error Messages";
        ErrorMessagesPage: TestPage "Error Messages";
        DefaultDimensionsPage: TestPage "Default Dimensions";
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO] Drilldown on "Source" opens "Default Dimensions" page focused on the source record
        Initialize();
        // [GIVEN] Default Dimension 'Default Dimension: Department, ADM'
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Customer, LibrarySales.CreateCustomerNo(), DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Dim error, where "Source" = 'Default Dimension: Department, ADM'
        TempErrorMessage.Validate("Record ID", DefaultDimension.RecordId);
        TempErrorMessage.Insert();

        // [GIVEN] Open ErrorMessages page
        ErrorMessages.SetRecords(TempErrorMessage);
        ErrorMessagesPage.Trap();
        ErrorMessages.Run();

        // [WHEN] Drill Down on "Source"
        DefaultDimensionsPage.Trap();
        ErrorMessagesPage.Source.DrillDown();

        // [THEN] "Default Dimensions" page is open, where "Dimension Code" = 'Department'
        Assert.AreEqual(DefaultDimension."Dimension Code", DefaultDimensionsPage."Dimension Code".Value, 'Default Dim Code');
        Assert.IsFalse(DefaultDimensionsPage.Next(), 'should be no second line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T502_DimErrorsOpensDimensionsPageByDrilldown()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessages: Page "Error Messages";
        ErrorMessagesPage: TestPage "Error Messages";
        DimensionsPage: TestPage Dimensions;
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO] Drilldown on "Source" opens "Dimensions" page focused on the source record
        Initialize();
        // [GIVEN] Dimension 'Dimension: Department'
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        Dimension.Get(DimensionValue."Dimension Code");

        // [GIVEN] Dim error, where "Source" = 'Dimension: Department'
        TempErrorMessage.Validate("Record ID", Dimension.RecordId);
        TempErrorMessage.Insert();

        // [GIVEN] Open ErrorMessages page
        ErrorMessages.SetRecords(TempErrorMessage);
        ErrorMessagesPage.Trap();
        ErrorMessages.Run();

        // [WHEN] Drill Down on "Source"
        DimensionsPage.Trap();
        ErrorMessagesPage.Source.DrillDown();

        // [THEN] "Dimensions" page is open, where "Dimension Code" = 'Department'
        Assert.AreEqual(Dimension.Code, DimensionsPage.Code.Value, 'Default Dim Code');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T503_DimErrorsOpensDimCombPageByDrilldown()
    var
        Dimension: Record Dimension;
        DimensionCombination: Record "Dimension Combination";
        DimensionValue: array[2] of Record "Dimension Value";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessages: Page "Error Messages";
        ErrorMessagesPage: TestPage "Error Messages";
        DimensionCombinations: TestPage "Dimension Combinations";
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO] Drilldown on "Source" opens "Dimension Combinations" page focused on the source record
        Initialize();
        // [GIVEN]  All dimension combinations with 'Department' are 'Limited'
        LibraryDimension.CreateDimWithDimValue(DimensionValue[1]);
        LibraryDimension.CreateDimWithDimValue(DimensionValue[2]);
        Dimension.SetFilter(Code, '<>%1', DimensionValue[1]."Dimension Code");
        Dimension.FindSet();
        repeat
            LibraryDimension.CreateDimensionCombination(DimensionCombination, DimensionValue[1]."Dimension Code", Dimension.Code);
        until Dimension.Next() = 0;
        // [GIVEN] 'Dimension Combination: Department, Project' is blocked.
        DimensionCombination.Get(DimensionValue[1]."Dimension Code", DimensionValue[2]."Dimension Code");
        DimensionCombination."Combination Restriction" := DimensionCombination."Combination Restriction"::Blocked;
        DimensionCombination.Modify();

        // [GIVEN] Dim error, where "Source" = 'Dimension Combination: Department, Project'
        TempErrorMessage.Validate("Record ID", DimensionCombination.RecordId);
        TempErrorMessage.Insert();

        // [GIVEN] Open ErrorMessages page
        ErrorMessages.SetRecords(TempErrorMessage);
        ErrorMessagesPage.Trap();
        ErrorMessages.Run();

        // [WHEN] Drill Down on "Source"
        DimensionCombinations.Trap();
        ErrorMessagesPage.Source.DrillDown();

        // [THEN] "Dimension Combinations" page is open, where "Code" = 'Department', Column1 is 'Blocked', Column2 is empty.
        DimensionCombinations.MatrixForm.First();
        Assert.AreEqual(
          DimensionValue[1]."Dimension Code", DimensionCombinations.MatrixForm.Code.Value, 'Combination Dim Code');
        Assert.AreEqual(
          Format(DimensionCombination."Combination Restriction"), DimensionCombinations.MatrixForm.Field1.Value, 'Column1');
        Assert.AreEqual('', DimensionCombinations.MatrixForm.Field2.Value, 'Column2');
        Assert.IsFalse(DimensionCombinations.MatrixForm.Next(), 'should be one record in matrix');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T504_DimErrorsOpensDimValueCombPageByDrilldown()
    var
        DimensionCombination: Record "Dimension Combination";
        DimensionValue: array[2] of Record "Dimension Value";
        DimensionValueCombination: Record "Dimension Value Combination";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessages: Page "Error Messages";
        ErrorMessagesPage: TestPage "Error Messages";
        MyDimValueCombinations: TestPage "MyDim Value Combinations";
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO] Drilldown on "Source" opens "Dimensions" page focused on the source record
        Initialize();
        // [GIVEN] Dimension Value Combination: Department,ADM,Project,TOYOTA
        LibraryDimension.CreateDimWithDimValue(DimensionValue[1]);
        LibraryDimension.CreateDimWithDimValue(DimensionValue[2]);
        LibraryDimension.CreateDimValueCombination(
          DimensionValueCombination,
          DimensionValue[1]."Dimension Code", DimensionValue[2]."Dimension Code",
          DimensionValue[1].Code, DimensionValue[2].Code);

        // [GIVEN] Dim error, where "Source" = 'Dimension Value Combination: Department,ADM,Project,TOYOTA'
        TempErrorMessage.Validate("Record ID", DimensionValueCombination.RecordId);
        TempErrorMessage.Insert();

        // [GIVEN] Open ErrorMessages page
        ErrorMessages.SetRecords(TempErrorMessage);
        ErrorMessagesPage.Trap();
        ErrorMessages.Run();

        // [WHEN] Drill Down on "Source"
        MyDimValueCombinations.Trap();
        ErrorMessagesPage.Source.DrillDown();

        // [THEN] "MyDim Value Combinations" page is open, where "Code" = 'ADM', Column1 is 'Blocked', Column2 is empty
        MyDimValueCombinations.MatrixForm.First();
        Assert.AreEqual(
          DimensionValue[1].Code, MyDimValueCombinations.MatrixForm.Code.Value, 'Dim Combination Value Code');
        DimensionCombination."Combination Restriction" := DimensionCombination."Combination Restriction"::Blocked;
        Assert.AreEqual(
          Format(DimensionCombination."Combination Restriction"), MyDimValueCombinations.MatrixForm.Field1.Value, 'Column1');
        Assert.AreEqual('', MyDimValueCombinations.MatrixForm.Field2.Value, 'Column2');
        Assert.IsFalse(MyDimValueCombinations.MatrixForm.Next(), 'should be one record in matrix');
    end;

    [Test]
    [HandlerFunctions('DocDimsModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T510_DimErrorsOpensSalesDocDimsPageByDrilldownIfDimRecBlank()
    var
        DimensionValue: Record "Dimension Value";
        TempErrorMessage: Record "Error Message" temporary;
        SalesHeader: Record "Sales Header";
        ErrorMessages: Page "Error Messages";
        ErrorMessagesPage: TestPage "Error Messages";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [UI] [Sales]
        // [SCENARIO] Drilldown on "Source" will open "Edit Dimension Set Entries" Page of the source document
        Initialize();
        // [GIVEN] Customer 'A', where dimension value 'Department','ADM' is default
        CustomerNo := CreateCustDefaultDimensionValue(DimensionValue);
        // [GIVEN] Sales Order '1002', where "Sell-To Customer No." is 'A'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        // [GIVEN] Dim error, where "Source Record ID" = 'Sales Header:Order,1002', "Source" is blank, "Table Number" is 349.
        TempErrorMessage.Validate("Context Record ID", SalesHeader.RecordId);
        TempErrorMessage.Validate("Record ID", DimensionValue.RecordId);
        Clear(TempErrorMessage."Record ID");
        TempErrorMessage.Insert();

        // [GIVEN] Open ErrorMessages page
        ErrorMessages.SetRecords(TempErrorMessage);
        ErrorMessagesPage.Trap();
        ErrorMessages.Run();

        // [WHEN] Drill Down on "Source"
        ErrorMessagesPage.Source.DrillDown();

        // [THEN] "Edit Dimension Set Entries" page is open, where "Dimension Code" = 'Department'
        Assert.AreEqual(DimensionValue."Dimension Code", LibraryVariableStorage.DequeueText(), 'Doc Dim Code'); // from DocDimsModalPageHandler
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DocDimsModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T511_DimErrorsOpensSalesDocDimsPageByDrilldown()
    var
        DimensionValue: Record "Dimension Value";
        TempErrorMessage: Record "Error Message" temporary;
        SalesHeader: Record "Sales Header";
        ErrorMessages: Page "Error Messages";
        ErrorMessagesPage: TestPage "Error Messages";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [UI] [Sales]
        // [SCENARIO] Drilldown on "Description" will open "Edit Dimension Set Entries" Page of the source document
        Initialize();
        // [GIVEN] Customer 'A', where dimension value 'Department','ADM' is default
        CustomerNo := CreateCustDefaultDimensionValue(DimensionValue);
        // [GIVEN] Sales Order '1002', where "Sell-To Customer No." is 'A'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        // [GIVEN] Dim error, where "Context Record ID" = 'Sales Header:Order,1002', "Table Number" := 351
        TempErrorMessage.Validate("Context Record ID", SalesHeader.RecordId);
        TempErrorMessage."Table Number" := DATABASE::"Dimension Value Combination";
        TempErrorMessage.Insert();

        // [GIVEN] Open ErrorMessages page
        ErrorMessages.SetRecords(TempErrorMessage);
        ErrorMessagesPage.Trap();
        ErrorMessages.Run();

        // [WHEN] Drill Down on "Context"
        ErrorMessagesPage.Context.DrillDown();
        // [THEN] "Edit Dimension Set Entries" page is open, where "Dimension Code" = 'Department'
        Assert.AreEqual(DimensionValue."Dimension Code", LibraryVariableStorage.DequeueText(), 'Doc Dim Code'); // from DocDimsModalPageHandler
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DocLineDimsModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T512_DimErrorsOpensSalesLineDimsPageByDrilldown()
    var
        DimensionValue: Record "Dimension Value";
        TempErrorMessage: Record "Error Message" temporary;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ErrorMessages: Page "Error Messages";
        ErrorMessagesPage: TestPage "Error Messages";
        CustomerNo: Code[20];
        DimSetID: Integer;
    begin
        // [FEATURE] [UI] [Sales]
        // [SCENARIO] Drilldown on "Description" will open "Edit Dimension Set Entries" Page of the source document line
        Initialize();
        // [GIVEN] Customer 'A', where dimension value 'Department','ADM' is default
        CustomerNo := CreateCustDefaultDimensionValue(DimensionValue);
        // [GIVEN] Sales Invoice '1002', where "Sell-To Customer No." is 'A'
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, CustomerNo);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        DimSetID := SalesLine."Dimension Set ID";
        // [GIVEN] Dim error, where "Context Record ID" = 'Sales Line:Invoice,1002,10000', "Table Number" := 352
        TempErrorMessage.Validate("Context Record ID", SalesLine.RecordId);
        TempErrorMessage."Table Number" := DATABASE::"Default Dimension";
        TempErrorMessage.Insert();

        // [GIVEN] Open ErrorMessages page
        ErrorMessages.SetRecords(TempErrorMessage);
        ErrorMessagesPage.Trap();
        ErrorMessages.Run();

        // [WHEN] Drill Down on "Context"
        ErrorMessagesPage.Context.DrillDown();
        // [THEN] "Edit Dimension Set Entries" page is open, where "Dimension Code" = 'Department'
        Assert.AreEqual(DimensionValue."Dimension Code", LibraryVariableStorage.DequeueText(), 'Doc Dim Code'); // from DocLineDimsModalPageHandler
        LibraryVariableStorage.AssertEmpty();
        // [THEN] Dimension Set is updated on the line
        SalesLine.Find();
        Assert.AreNotEqual(DimSetID, SalesLine."Dimension Set ID", 'Dim Set ID must be changed');
    end;

    [Test]
    [HandlerFunctions('DocDimsModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T520_DimErrorsOpensPurchDocDimsPageByDrilldownIfDimRecBlank()
    var
        DimensionValue: Record "Dimension Value";
        TempErrorMessage: Record "Error Message" temporary;
        PurchHeader: Record "Purchase Header";
        ErrorMessages: Page "Error Messages";
        ErrorMessagesPage: TestPage "Error Messages";
        VendorNo: Code[20];
    begin
        // [FEATURE] [UI] [Purchase]
        // [SCENARIO] Drilldown on "Source" will open "Edit Dimension Set Entries" Page of the source document
        Initialize();
        // [GIVEN] Vendor 'A', where dimension value 'Department','ADM' is default
        VendorNo := CreateVendDefaultDimensionValue(DimensionValue);
        // [GIVEN] Sales Order '1002', where "Sell-To Vendor No." is 'A'
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);

        // [GIVEN] Dim error, where "Context Record ID" = 'Purchase Header:Order,1002', "Source" is blank, "Table Number" is 349
        TempErrorMessage.Validate("Context Record ID", PurchHeader.RecordId);
        TempErrorMessage.Validate("Record ID", DimensionValue.RecordId);
        Clear(TempErrorMessage."Record ID");
        TempErrorMessage.Insert();

        // [GIVEN] Open ErrorMessages page
        ErrorMessages.SetRecords(TempErrorMessage);
        ErrorMessagesPage.Trap();
        ErrorMessages.Run();

        // [WHEN] Drill Down on "Source"
        ErrorMessagesPage.Source.DrillDown();
        // [THEN] "Edit Dimension Set Entries" page is open, where "Dimension Code" = 'Department'
        Assert.AreEqual(DimensionValue."Dimension Code", LibraryVariableStorage.DequeueText(), 'Doc Dim Code'); // from DocDimsModalPageHandler
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DocDimsModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T521_DimErrorsOpensPurchDocDimsPageByDrilldown()
    var
        DimensionValue: Record "Dimension Value";
        TempErrorMessage: Record "Error Message" temporary;
        PurchHeader: Record "Purchase Header";
        ErrorMessages: Page "Error Messages";
        ErrorMessagesPage: TestPage "Error Messages";
        VendorNo: Code[20];
    begin
        // [FEATURE] [UI] [Purchase]
        // [SCENARIO] Drilldown on "Description" will open "Edit Dimension Set Entries" Page of the source document
        Initialize();
        // [GIVEN] Vendor 'A', where dimension value 'Department','ADM' is default
        VendorNo := CreateVendDefaultDimensionValue(DimensionValue);
        // [GIVEN] Purchase Order '1002', where "Buy-from Vendor No." is 'A'
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);

        // [GIVEN] Dim error, where "Context Record ID" = 'Purchase Header:Order,1002', "Table Number" := 348
        TempErrorMessage.Validate("Context Record ID", PurchHeader.RecordId);
        TempErrorMessage."Table Number" := DATABASE::Dimension;
        TempErrorMessage.Insert();

        // [GIVEN] Open ErrorMessages page
        ErrorMessages.SetRecords(TempErrorMessage);
        ErrorMessagesPage.Trap();
        ErrorMessages.Run();

        // [WHEN] Drill Down on "Context"
        ErrorMessagesPage.Context.DrillDown();
        // [THEN] "Edit Dimension Set Entries" page is open, where "Dimension Code" = 'Department'
        Assert.AreEqual(DimensionValue."Dimension Code", LibraryVariableStorage.DequeueText(), 'Doc Dim Code'); // from DocDimsModalPageHandler
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DocLineDimsModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T522_DimErrorsOpensPurchLineDimsPageByDrilldown()
    var
        DimensionValue: Record "Dimension Value";
        TempErrorMessage: Record "Error Message" temporary;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ErrorMessages: Page "Error Messages";
        ErrorMessagesPage: TestPage "Error Messages";
        VendorNo: Code[20];
        DimSetID: Integer;
    begin
        // [FEATURE] [UI] [Purchase]
        // [SCENARIO] Drilldown on "Description" will open "Edit Dimension Set Entries" Page of the source document line
        Initialize();
        // [GIVEN] Vendor 'A', where dimension value 'Department','ADM' is default
        VendorNo := CreateVendDefaultDimensionValue(DimensionValue);
        // [GIVEN] Purchase Invoice '1002', where "Buy-from Vendor No." is 'A'
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchHeader, VendorNo);
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.FindFirst();
        DimSetID := PurchLine."Dimension Set ID";
        // [GIVEN] Dim error, where "Context Record ID" = 'Purchase Line:Invoice,1002,10000', "Table Number" := 350.
        TempErrorMessage.Validate("Context Record ID", PurchLine.RecordId);
        TempErrorMessage."Table Number" := DATABASE::"Dimension Combination";
        TempErrorMessage.Insert();

        // [GIVEN] Open ErrorMessages page
        ErrorMessages.SetRecords(TempErrorMessage);
        ErrorMessagesPage.Trap();
        ErrorMessages.Run();

        // [WHEN] Drill Down on "Context"
        ErrorMessagesPage.Context.DrillDown();
        // [THEN] "Edit Dimension Set Entries" page is open, where "Dimension Code" = 'Department'
        Assert.AreEqual(DimensionValue."Dimension Code", LibraryVariableStorage.DequeueText(), 'Doc Dim Code'); // from DocDimsModalPageHandler
        LibraryVariableStorage.AssertEmpty();
        // [THEN] Dimension Set is updated on the line
        PurchLine.Find();
        Assert.AreNotEqual(DimSetID, PurchLine."Dimension Set ID", 'Dim Set ID must be changed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingGenJournalLineWithConflictingDimensions()
    var
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GLAccNo: array[2] of Code[20];
        ExpectedErrorMessage: Text;
    begin
        // [SCENARIO 348697] It is not possible to post Gen. Journal Line with conflicting Default Dimensions.
        Initialize();

        // [GIVEN] G/L Account "GL1" with Default Dimension having "Value Posting" = "Code Mandatory", "Dimension Code" = "DC", "Dimension Value Code" = "DV".
        GLAccNo[1] := LibraryERM.CreateGLAccountNo();
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccNo[1], DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        // [GIVEN] G/L Account "GL2" with Default Dimension having "Value Posting" = "No Code", "Dimension Code" = "DC", blank "Dimension Value Code".
        GLAccNo[2] := LibraryERM.CreateGLAccountNo();
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccNo[2], DimensionValue."Dimension Code", '');
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"No Code");
        DefaultDimension.Modify(true);

        // [GIVEN] Gen. Journal Line with Account = "GL1", Bal. Account "GL2", Dimension "DC" with value "DV",
        // [GIVEN] Gen. Journal Template "GJT", Gen. Journal Batch "GJB", Line No. "1000".
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJnlLine, GenJnlTemplate.Name, GenJnlBatch.Name, GenJnlLine."Document Type"::" ", GenJnlLine."Account Type"::"G/L Account", GLAccNo[1],
            GenJnlLine."Bal. Account Type"::"G/L Account", GLAccNo[2], LibraryRandom.RandInt(100));

        // [WHEN] Gen. Journal Line is posted.
        asserterror LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [THEN] Error is thrown with text "A dimension used in Gen. Journal Line "GJT, "GJB", 10000 has caused an error.
        // [THEN] Dimension Code "DC" must not be mentioned for G/L Account "GL2"."
        ExpectedErrorMessage := GetDimNoCodeErrText(DimensionValue."Dimension Code", GLAccount.TableName, GLAccNo[2], DimensionValue.Code);
        ExpectedErrorMessage :=
          StrSubstNo(
            PostingDimensionErr, GenJnlLine.TableCaption(), GenJnlTemplate.Name, GenJnlBatch.Name, GenJnlLine."Line No.", ExpectedErrorMessage);
        Assert.ExpectedError(ExpectedErrorMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDimValuePostingNoTablePriorities()
    var
        Customer: Record Customer;
        DefaultDim: Record "Default Dimension";
        DimValue: Record "Dimension Value";
        GLAccount: Record "G/L Account";
        DimManagement: Codeunit DimensionManagement;
        ErrorMessageManagement: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        No: array[10] of Code[20];
        DimSetID: Integer;
        TableID: array[10] of Integer;
        Result: Boolean;
        ExpectedErrorMessage: array[2] of Text;
    begin
        // [FEATURE] [UT] [Priority]
        // [SCENARIO 348697] Function CheckDimValuePosting checks Default Dimension for both tables with no priority.
        Initialize();

        // [GIVEN] Customer with Default Dimension with Dimension Code = "D", Value Posting = "No Code", Dimension Value Code is blank.
        LibraryDimension.CreateDimWithDimValue(DimValue);
        LibrarySales.CreateCustomer(Customer);
        CreateDefaultDimensionWithValuePostingForCustomer(
          DefaultDim, DimValue."Dimension Code", '', Customer."No.", DefaultDim."Value Posting"::"No Code");

        // [GIVEN] G/L Account with Default Dimension with Dimension Code = "D", Value Posting = "Code Mandatory", Dimension Value Code = "V"
        LibraryERM.CreateGLAccount(GLAccount);
        CreateDefaultDimensionWithValuePostingForGLAcc(
          DefaultDim, DimValue."Dimension Code", '', GLAccount."No.", DefaultDim."Value Posting"::"No Code");

        // [GIVEN] Customer table and G/L Account table have no dimension priority.
        ClearDefaultDimensionPriorities('');

        // [GIVEN] Dimension Set with Dimension "D" and Dimension Value Code = "V".
        DimSetID := LibraryDimension.CreateDimSet(0, DimValue."Dimension Code", DimValue.Code);

        // [WHEN] CheckDimValuePosting is run on Customer, G/L Account and Dimension set.
        TableID[1] := DATABASE::Customer;
        TableID[2] := DATABASE::"G/L Account";
        No[1] := Customer."No.";
        No[2] := GLAccount."No.";
        ErrorMessageManagement.Activate(ErrorMessageHandler);
        DimManagement.SetCollectErrorsMode();
        Result := DimManagement.CheckDimValuePosting(TableID, No, DimSetID);

        // [THEN] CheckDimValuePosting returns False, two errors are:
        // [THEN] 1) "Dimension Code "D" must not be mentioned for G/L Account";
        // [THEN] 2) "Dimension Code "D" must not be mentioned for Customer".
        Assert.IsFalse(Result, '');
        ExpectedErrorMessage[1] := GetDimNoCodeErrText(DimValue."Dimension Code", GLAccount.TableName, GLAccount."No.", DimValue.Code);
        ExpectedErrorMessage[2] := GetDimNoCodeErrText(DimValue."Dimension Code", Customer.TableName, Customer."No.", DimValue.Code);
        VerifyDimErrors(2, ExpectedErrorMessage, ErrorMessageHandler);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDimValuePostingFirstTableWithPriority()
    var
        Customer: Record Customer;
        DefaultDim: Record "Default Dimension";
        DefaultDimPriority: Record "Default Dimension Priority";
        DimValue: Record "Dimension Value";
        GLAccount: Record "G/L Account";
        DimManagement: Codeunit DimensionManagement;
        ErrorMessageManagement: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        No: array[10] of Code[20];
        DimSetID: Integer;
        TableID: array[10] of Integer;
        Result: Boolean;
        ExpectedErrorMessage: array[2] of Text;
    begin
        // [FEATURE] [UT] [Priority]
        // [SCENARIO 348697] Function CheckDimValuePosting checks Default Dimension for first table with priority and ignores the same dimension for second table without priority.
        Initialize();

        // [GIVEN] Customer with Default Dimension with Dimension Code = "D", Value Posting = "No Code", Dimension Value Code is blank.
        LibraryDimension.CreateDimWithDimValue(DimValue);
        LibrarySales.CreateCustomer(Customer);
        CreateDefaultDimensionWithValuePostingForCustomer(
          DefaultDim, DimValue."Dimension Code", '', Customer."No.", DefaultDim."Value Posting"::"No Code");

        // [GIVEN] G/L Account with Default Dimension with Dimension Code = "D", Value Posting = "Code Mandatory", Dimension Value Code = "V"
        LibraryERM.CreateGLAccount(GLAccount);
        CreateDefaultDimensionWithValuePostingForGLAcc(
          DefaultDim, DimValue."Dimension Code", DimValue.Code, GLAccount."No.", DefaultDim."Value Posting"::"Code Mandatory");

        // [GIVEN] Customer table has dimension priority and G/L Account doesn't.
        ClearDefaultDimensionPriorities('');
        CreateDefaultDimPriority(DefaultDimPriority, DATABASE::Customer, LibraryRandom.RandInt(10));

        // [GIVEN] Dimension Set with Dimension "D" and Dimension Value Code = "V".
        DimSetID := LibraryDimension.CreateDimSet(0, DimValue."Dimension Code", DimValue.Code);

        // [WHEN] CheckDimValuePosting is run on Customer, G/L Account and Dimension set.
        TableID[1] := DATABASE::Customer;
        TableID[2] := DATABASE::"G/L Account";
        No[1] := Customer."No.";
        No[2] := GLAccount."No.";
        ErrorMessageManagement.Activate(ErrorMessageHandler);
        DimManagement.SetCollectErrorsMode();
        Result := DimManagement.CheckDimValuePosting(TableID, No, DimSetID);

        // [THEN] CheckDimValuePosting returns False, single error is "Dimension Code "D" must not be mentioned for Customer.".
        Assert.IsFalse(Result, '');
        ExpectedErrorMessage[1] := GetDimNoCodeErrText(DimValue."Dimension Code", Customer.TableName, Customer."No.", DimValue.Code);
        VerifyDimErrors(1, ExpectedErrorMessage, ErrorMessageHandler);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDimValuePostingSecondTableWithPriority()
    var
        Customer: Record Customer;
        DefaultDim: Record "Default Dimension";
        DefaultDimPriority: Record "Default Dimension Priority";
        DimValue: Record "Dimension Value";
        GLAccount: Record "G/L Account";
        DimManagement: Codeunit DimensionManagement;
        ErrorMessageManagement: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        No: array[10] of Code[20];
        DimSetID: Integer;
        TableID: array[10] of Integer;
        Result: Boolean;
        ExpectedErrorMessage: array[2] of Text;
    begin
        // [FEATURE] [UT] [Priority]
        // [SCENARIO 348697] Function CheckDimValuePosting ignores Default Dimension for first table without priority and checks the same dimension for second table with priority.
        Initialize();

        // [GIVEN] Customer with Default Dimension with Dimension Code = "D", Value Posting = "Code Mandatory", Dimension Value Code is blank.
        LibraryDimension.CreateDimWithDimValue(DimValue);
        LibrarySales.CreateCustomer(Customer);
        CreateDefaultDimensionWithValuePostingForCustomer(
          DefaultDim, DimValue."Dimension Code", DimValue.Code, Customer."No.", DefaultDim."Value Posting"::"Code Mandatory");

        // [GIVEN] G/L Account with Default Dimension with Dimension Code = "D", Value Posting = "No Code", Dimension Value Code = "V"
        LibraryERM.CreateGLAccount(GLAccount);
        CreateDefaultDimensionWithValuePostingForGLAcc(
          DefaultDim, DimValue."Dimension Code", '', GLAccount."No.", DefaultDim."Value Posting"::"No Code");

        // [GIVEN] Customer table hasn't dimension priority and G/L Account does.
        ClearDefaultDimensionPriorities('');
        CreateDefaultDimPriority(DefaultDimPriority, DATABASE::"G/L Account", LibraryRandom.RandInt(10));

        // [GIVEN] Dimension Set with Dimension "D" and Dimension Value Code = "V".
        DimSetID := LibraryDimension.CreateDimSet(0, DimValue."Dimension Code", DimValue.Code);

        // [WHEN] CheckDimValuePosting is run on Customer, G/L Account and Dimension set.
        TableID[1] := DATABASE::Customer;
        TableID[2] := DATABASE::"G/L Account";
        No[1] := Customer."No.";
        No[2] := GLAccount."No.";
        ErrorMessageManagement.Activate(ErrorMessageHandler);
        DimManagement.SetCollectErrorsMode();
        Result := DimManagement.CheckDimValuePosting(TableID, No, DimSetID);

        // [THEN] CheckDimValuePosting returns False, single error "Dimension Code "D" must not be mentioned for G/L Account.".
        Assert.IsFalse(Result, '');
        ExpectedErrorMessage[1] := GetDimNoCodeErrText(DimValue."Dimension Code", GLAccount.TableName, GLAccount."No.", DimValue.Code);
        VerifyDimErrors(1, ExpectedErrorMessage, ErrorMessageHandler);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDimValuePostingFirstTableWithLowerPriority()
    var
        Customer: Record Customer;
        DefaultDim: Record "Default Dimension";
        DefaultDimPriority: Record "Default Dimension Priority";
        DimValue: Record "Dimension Value";
        GLAccount: Record "G/L Account";
        DimManagement: Codeunit DimensionManagement;
        ErrorMessageManagement: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        No: array[10] of Code[20];
        DimSetID: Integer;
        TableID: array[10] of Integer;
        Result: Boolean;
        ExpectedErrorMessage: array[2] of Text;
    begin
        // [FEATURE] [UT] [Priority]
        // [SCENARIO 348697] Function CheckDimValuePosting ignores Default Dimension for first table with lower priority and checks the same dimension for second table with higher priority.
        Initialize();

        // [GIVEN] Customer with Default Dimension with Dimension Code = "D", Value Posting = "Code Mandatory", Dimension Value Code = "V".
        LibraryDimension.CreateDimWithDimValue(DimValue);
        LibrarySales.CreateCustomer(Customer);
        CreateDefaultDimensionWithValuePostingForCustomer(
          DefaultDim, DimValue."Dimension Code", DimValue.Code, Customer."No.", DefaultDim."Value Posting"::"Code Mandatory");

        // [GIVEN] G/L Account with Default Dimension with Dimension Code = "D", Value Posting = "No Code", Dimension Value Code is blank.
        LibraryERM.CreateGLAccount(GLAccount);
        CreateDefaultDimensionWithValuePostingForGLAcc(
          DefaultDim, DimValue."Dimension Code", '', GLAccount."No.", DefaultDim."Value Posting"::"No Code");

        // [GIVEN] Customer table has lower dimension priority than G/L Account.
        ClearDefaultDimensionPriorities('');
        CreateDefaultDimPriority(DefaultDimPriority, DATABASE::Customer, LibraryRandom.RandIntInRange(11, 20));
        CreateDefaultDimPriority(DefaultDimPriority, DATABASE::"G/L Account", LibraryRandom.RandInt(10));

        // [GIVEN] Dimension Set with Dimension "D" and Dimension Value Code = "V".
        DimSetID := LibraryDimension.CreateDimSet(0, DimValue."Dimension Code", DimValue.Code);

        // [WHEN] CheckDimValuePosting is run on Customer, G/L Account and Dimension set.
        TableID[1] := DATABASE::Customer;
        TableID[2] := DATABASE::"G/L Account";
        No[1] := Customer."No.";
        No[2] := GLAccount."No.";
        ErrorMessageManagement.Activate(ErrorMessageHandler);
        DimManagement.SetCollectErrorsMode();
        Result := DimManagement.CheckDimValuePosting(TableID, No, DimSetID);

        // [THEN] CheckDimValuePosting returns False, single error "Dimension Code "D" must not be mentioned for G/L Account.".
        Assert.IsFalse(Result, '');
        ExpectedErrorMessage[1] := GetDimNoCodeErrText(DimValue."Dimension Code", GLAccount.TableName, GLAccount."No.", DimValue.Code);
        VerifyDimErrors(1, ExpectedErrorMessage, ErrorMessageHandler);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDimValuePostingEqualTablePriorities()
    var
        Customer: Record Customer;
        DefaultDim: Record "Default Dimension";
        DefaultDimPriority: Record "Default Dimension Priority";
        DimValue: Record "Dimension Value";
        GLAccount: Record "G/L Account";
        DimManagement: Codeunit DimensionManagement;
        ErrorMessageManagement: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        No: array[10] of Code[20];
        DimSetID: Integer;
        TableID: array[10] of Integer;
        Result: Boolean;
        ExpectedErrorMessage: array[2] of Text;
    begin
        // [FEATURE] [UT] [Priority]
        // [SCENARIO 348697] Function CheckDimValuePosting checks Default Dimension for both tables with equal priority.
        Initialize();

        // [GIVEN] Customer with Default Dimension with Dimension Code = "D", Value Posting = "No Code", Dimension Value Code is blank.
        LibraryDimension.CreateDimWithDimValue(DimValue);
        LibrarySales.CreateCustomer(Customer);
        CreateDefaultDimensionWithValuePostingForCustomer(
          DefaultDim, DimValue."Dimension Code", '', Customer."No.", DefaultDim."Value Posting"::"No Code");

        // [GIVEN] G/L Account with Default Dimension with Dimension Code = "D", Value Posting = "Code Mandatory", Dimension Value Code = "V"
        LibraryERM.CreateGLAccount(GLAccount);
        CreateDefaultDimensionWithValuePostingForGLAcc(
          DefaultDim, DimValue."Dimension Code", '', GLAccount."No.", DefaultDim."Value Posting"::"No Code");

        // [GIVEN] Customer table and G/L Account table have the same dimension priority.
        ClearDefaultDimensionPriorities('');
        CreateDefaultDimPriority(DefaultDimPriority, DATABASE::Customer, LibraryRandom.RandInt(10));
        CreateDefaultDimPriority(DefaultDimPriority, DATABASE::"G/L Account", DefaultDimPriority.Priority);

        // [GIVEN] Dimension Set with Dimension "D" and Dimension Value Code = "V".
        DimSetID := LibraryDimension.CreateDimSet(0, DimValue."Dimension Code", DimValue.Code);

        // [WHEN] CheckDimValuePosting is run on Customer, G/L Account and Dimension set.
        TableID[1] := DATABASE::Customer;
        TableID[2] := DATABASE::"G/L Account";
        No[1] := Customer."No.";
        No[2] := GLAccount."No.";
        ErrorMessageManagement.Activate(ErrorMessageHandler);
        DimManagement.SetCollectErrorsMode();
        Result := DimManagement.CheckDimValuePosting(TableID, No, DimSetID);

        // [THEN] CheckDimValuePosting returns False, two errors are:
        // [THEN] 1) "Dimension Code "D" must not be mentioned for G/L Account";
        // [THEN] 2) "Dimension Code "D" must not be mentioned for Customer".
        Assert.IsFalse(Result, '');
        ExpectedErrorMessage[1] := GetDimNoCodeErrText(DimValue."Dimension Code", GLAccount.TableName, GLAccount."No.", DimValue.Code);
        ExpectedErrorMessage[2] := GetDimNoCodeErrText(DimValue."Dimension Code", Customer.TableName, Customer."No.", DimValue.Code);
        VerifyDimErrors(2, ExpectedErrorMessage, ErrorMessageHandler);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDimValuePostingFirstTableWithHigherPriority()
    var
        Customer: Record Customer;
        DefaultDim: Record "Default Dimension";
        DefaultDimPriority: Record "Default Dimension Priority";
        DimValue: Record "Dimension Value";
        GLAccount: Record "G/L Account";
        DimManagement: Codeunit DimensionManagement;
        ErrorMessageManagement: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        No: array[10] of Code[20];
        DimSetID: Integer;
        TableID: array[10] of Integer;
        Result: Boolean;
        ExpectedErrorMessage: array[2] of Text;
    begin
        // [FEATURE] [UT] [Priority]
        // [SCENARIO 348697] Function CheckDimValuePosting checks Default Dimension for first table with higher priority and ignores the same dimension for second table with lower priority.
        Initialize();

        // [GIVEN] Customer with Default Dimension with Dimension Code = "D", Value Posting = "No Code", Dimension Value Code is blank.
        LibraryDimension.CreateDimWithDimValue(DimValue);
        LibrarySales.CreateCustomer(Customer);
        CreateDefaultDimensionWithValuePostingForCustomer(
          DefaultDim, DimValue."Dimension Code", '', Customer."No.", DefaultDim."Value Posting"::"No Code");

        // [GIVEN] G/L Account with Default Dimension with Dimension Code = "D", Value Posting = "Code Mandatory", Dimension Value Code = "V"
        LibraryERM.CreateGLAccount(GLAccount);
        CreateDefaultDimensionWithValuePostingForGLAcc(
          DefaultDim, DimValue."Dimension Code", DimValue.Code, GLAccount."No.", DefaultDim."Value Posting"::"Code Mandatory");

        // [GIVEN] Customer table has higher dimension priority than G/L Account table.
        ClearDefaultDimensionPriorities('');
        CreateDefaultDimPriority(DefaultDimPriority, DATABASE::Customer, LibraryRandom.RandInt(10));
        CreateDefaultDimPriority(DefaultDimPriority, DATABASE::"G/L Account", LibraryRandom.RandIntInRange(11, 20));

        // [GIVEN] Dimension Set with Dimension "D" and Dimension Value Code = "V".
        DimSetID := LibraryDimension.CreateDimSet(0, DimValue."Dimension Code", DimValue.Code);

        // [WHEN] CheckDimValuePosting is run on Customer, G/L Account and Dimension set.
        TableID[1] := DATABASE::Customer;
        TableID[2] := DATABASE::"G/L Account";
        No[1] := Customer."No.";
        No[2] := GLAccount."No.";
        ErrorMessageManagement.Activate(ErrorMessageHandler);
        DimManagement.SetCollectErrorsMode();
        Result := DimManagement.CheckDimValuePosting(TableID, No, DimSetID);

        // [THEN] CheckDimValuePosting returns False, single error "Dimension Code "D" must not be mentioned for Customer".
        Assert.IsFalse(Result, '');
        ExpectedErrorMessage[1] := GetDimNoCodeErrText(DimValue."Dimension Code", Customer.TableName, Customer."No.", DimValue.Code);
        VerifyDimErrors(1, ExpectedErrorMessage, ErrorMessageHandler);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDimValuePostingIdenticalDefaultDimensions()
    var
        DefaultDim: Record "Default Dimension";
        DimValue: Record "Dimension Value";
        GLAccount: Record "G/L Account";
        DimManagement: Codeunit DimensionManagement;
        No: array[10] of Code[20];
        DimSetID: Integer;
        TableID: array[10] of Integer;
        Result: Boolean;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 348697] Function CheckDimValuePosting checks Default Dimension for two identical Default Dimensions inputs.
        Initialize();

        // [GIVEN] G/L Account with Default Dimension with Dimension Code, Value Posting, Dimension Value Code.
        LibraryDimension.CreateDimWithDimValue(DimValue);
        LibraryERM.CreateGLAccount(GLAccount);
        CreateDefaultDimensionWithValuePostingForGLAcc(
            DefaultDim, DimValue."Dimension Code", DimValue.Code, GLAccount."No.", DefaultDim."Value Posting"::"Code Mandatory");

        // [GIVEN] Dimension Set with Dimension and Dimension Value Code.
        DimSetID := LibraryDimension.CreateDimSet(0, DimValue."Dimension Code", DimValue.Code);

        // [WHEN] CheckDimValuePosting is run for the same G/L Accounts and Dimension set.
        TableID[1] := DATABASE::"G/L Account";
        TableID[2] := DATABASE::"G/L Account";
        No[1] := GLAccount."No.";
        No[2] := GLAccount."No.";
        Result := DimManagement.CheckDimValuePosting(TableID, No, DimSetID);

        // [THEN] CheckDimValuePosting returns True.
        Assert.IsTrue(Result, '');
    end;

    local procedure Initialize()
    var
        NamedForwardLink: Record "Named Forward Link";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Check Dimensions On Posting");
        LibraryErrorMessage.Clear();
        NamedForwardLink.DeleteAll();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Check Dimensions On Posting");
        LibraryApplicationArea.EnableEssentialSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePrepaymentAccounts();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Check Dimensions On Posting");
    end;

    local procedure AddDimValueInSet(var TempDimSetEntry: Record "Dimension Set Entry" temporary; DimCode: Code[20]; DimValue: Code[20])
    begin
        TempDimSetEntry.Reset();
        TempDimSetEntry.FindLast();
        TempDimSetEntry."Dimension Code" := DimCode;
        TempDimSetEntry."Dimension Value Code" := DimValue;
        TempDimSetEntry."Dimension Value ID" += 1;
        TempDimSetEntry.Insert();
    end;

    local procedure ChangeDimValueInSet(var TempDimSetEntry: Record "Dimension Set Entry" temporary; DimCode: Code[20]; DimValue: Code[20])
    begin
        TempDimSetEntry.Reset();
        TempDimSetEntry.SetRange("Dimension Code", DimCode);
        TempDimSetEntry.FindFirst();
        TempDimSetEntry."Dimension Value Code" := DimValue;
        TempDimSetEntry.Modify();
        TempDimSetEntry.Reset();
    end;

    local procedure ClearDefaultDimensionPriorities(SourceCode: Code[10])
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        DefaultDimensionPriority.SetRange("Source Code", SourceCode);
        DefaultDimensionPriority.DeleteAll(true);
    end;

    local procedure CreateCustBlockedDimensionValue(var DimensionValue: Record "Dimension Value"; CustomerNo: Code[20]) ExpectedErrorMessage: Text
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);
        LibraryDimension.BlockDimensionValue(DimensionValue);
        ExpectedErrorMessage :=
          StrSubstNo(DimValueBlockedErr, DimensionValue.TableCaption(), DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateCustDefaultDimensionValue(var DimensionValue: Record "Dimension Value") CustomerNo: Code[20]
    var
        DefaultDimension: Record "Default Dimension";
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateDefaultDimensionWithValuePostingForCustomer(var DefaultDimension: Record "Default Dimension"; DimensionCode: Code[20]; DimensionValueCode: Code[20]; CustomerNo: Code[20]; ValuePosting: Enum "Default Dimension value Posting Type")
    begin
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, CustomerNo, DimensionCode, DimensionValueCode);
        DefaultDimension.Validate("Value Posting", ValuePosting);
        DefaultDimension.Modify(true);
    end;

    local procedure CreateDefaultDimensionWithValuePostingForGLAcc(var DefaultDimension: Record "Default Dimension"; DimensionCode: Code[20]; DimensionValueCode: Code[20]; GLAccNo: Code[20]; ValuePosting: Enum "Default Dimension value Posting Type")
    begin
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccNo, DimensionCode, DimensionValueCode);
        DefaultDimension.Validate("Value Posting", ValuePosting);
        DefaultDimension.Modify(true);
    end;

    local procedure CreateDefaultDimPriority(var DefaultDimPriority: Record "Default Dimension Priority"; TableID: Integer; Priority: Integer)
    begin
        if (TableID = 0) or (Priority = 0) then
            exit;

        DefaultDimPriority.Validate("Table ID", TableID);
        DefaultDimPriority.Validate(Priority, Priority);
        DefaultDimPriority.Insert(true);
    end;

    local procedure CreateVendBlockedDimensionValue(var DimensionValue: Record "Dimension Value"; VendorNo: Code[20]) ExpectedErrorMessage: Text
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension, VendorNo, DimensionValue."Dimension Code", DimensionValue.Code);
        LibraryDimension.BlockDimensionValue(DimensionValue);
        ExpectedErrorMessage :=
          StrSubstNo(DimValueBlockedErr, DimensionValue.TableCaption(), DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateVendDefaultDimensionValue(var DimensionValue: Record "Dimension Value") VendorNo: Code[20]
    var
        DefaultDimension: Record "Default Dimension";
    begin
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension, VendorNo, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure GetDimensionSetID(DimensionValue: array[3] of Record "Dimension Value"): Integer
    var
        DimSetEntry: Record "Dimension Set Entry";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
        i: Integer;
        NextID: Integer;
    begin
        DimSetEntry.SetCurrentKey("Dimension Value ID");
        if DimSetEntry.FindLast() then
            NextID := DimSetEntry."Dimension Value ID";
        for i := 1 to 3 do
            if DimensionValue[i]."Dimension Code" <> '' then begin
                NextID += 1;
                TempDimSetEntry."Dimension Code" := DimensionValue[i]."Dimension Code";
                TempDimSetEntry."Dimension Value Code" := DimensionValue[i].Code;
                TempDimSetEntry."Dimension Value ID" := NextID;
                TempDimSetEntry.Insert();
            end;
        exit(DimMgt.GetDimensionSetID(TempDimSetEntry));
    end;

    local procedure GetDimNoCodeErrText(DimensionCode: Code[20]; TableName: Text; No: Code[20]; CurrentDimensionValueCode: Code[20]): Text
    var
        DefaultDim: Record "Default Dimension";
    begin
        exit(StrSubstNo(DimValueSameOrNoCodeErr, DefaultDim.FieldCaption("Dimension Value Code"), BlankLbl, DefaultDim.FieldCaption("Dimension Code"), DimensionCode, TableName, No, CurrentDimensionValueCode));
    end;

    local procedure PostPurchDocument(PurchHeader: Record "Purchase Header"; CodeunitID: Integer)
    begin
        PurchHeaderToPost(PurchHeader);
        LibraryErrorMessage.TrapErrorMessages();
        PurchHeader.SendToPosting(CodeunitID);
    end;

    local procedure PostPurchPrepmtDocument(PurchHeader: Record "Purchase Header")
    var
        PurchPostPrepmtYesNo: Codeunit "Purch.-Post Prepmt. (Yes/No)";
    begin
        PurchHeaderToPost(PurchHeader);
        LibraryErrorMessage.TrapErrorMessages();
        PurchPostPrepmtYesNo.PostPrepmtInvoiceYN(PurchHeader, false);
    end;

    local procedure PreviewPurchDocument(PurchHeader: Record "Purchase Header")
    var
        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
    begin
        PurchHeaderToPost(PurchHeader);
        LibraryErrorMessage.TrapErrorMessages();
        PurchPostYesNo.Preview(PurchHeader);
    end;

    local procedure PurchHeaderToPost(var PurchHeader: Record "Purchase Header")
    begin
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        PurchHeader.Modify();
        Commit();
    end;

    local procedure PostSalesDocument(SalesHeader: Record "Sales Header"; CodeunitID: Integer)
    begin
        SalesHeaderToPost(SalesHeader);
        LibraryErrorMessage.TrapErrorMessages();
        SalesHeader.SendToPosting(CodeunitID);
    end;

    local procedure PostSalesPrepmtDocument(SalesHeader: Record "Sales Header")
    var
        SalesPostPrepaymentYesNo: Codeunit "Sales-Post Prepayment (Yes/No)";
    begin
        SalesHeaderToPost(SalesHeader);
        LibraryErrorMessage.TrapErrorMessages();
        SalesPostPrepaymentYesNo.PostPrepmtInvoiceYN(SalesHeader, false);
    end;

    local procedure PreviewSalesDocument(SalesHeader: Record "Sales Header")
    var
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
    begin
        SalesHeaderToPost(SalesHeader);
        LibraryErrorMessage.TrapErrorMessages();
        SalesPostYesNo.Preview(SalesHeader);
    end;

    local procedure SalesHeaderToPost(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        SalesHeader.Modify();
        Commit();
    end;

    local procedure SetDimensionBlocked(DimCode: Code[20]; var Dimension: Record Dimension) ExpectedErrorMessage: Text
    begin
        Dimension.Get(DimCode);
        LibraryDimension.BlockDimension(Dimension);
        ExpectedErrorMessage := StrSubstNo(DimensionBlockedErr, DimCode);
    end;

    local procedure SetNotAllowedDimensionValueType(var DimensionValue: Record "Dimension Value"; var ExpectedErrorMessage: Text)
    begin
        DimensionValue."Dimension Value Type" := DimensionValue."Dimension Value Type"::Heading;
        DimensionValue.Modify();
        ExpectedErrorMessage :=
          StrSubstNo(DimValueNotAllowedErr, DimensionValue."Dimension Code", DimensionValue.Code, DimensionValue."Dimension Value Type");
    end;

    local procedure SetArray(var RecID: array[10] of RecordID; FromIndex: Integer; ToIndex: Integer; Value: RecordID)
    var
        i: Integer;
    begin
        for i := FromIndex to ToIndex do
            RecID[i] := Value;
    end;

    local procedure SetupSupportURL(): Text
    var
        NamedForwardLink: Record "Named Forward Link";
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
    begin
        NamedForwardLink.Init();
        NamedForwardLink.Name := ForwardLinkMgt.GetHelpCodeForWorkingWithDimensions();
        NamedForwardLink.Link := LibraryUtility.GenerateGUID();
        NamedForwardLink.Insert();
        exit(NamedForwardLink.Link);
    end;

    local procedure VerifyDimErrors(ErrorCount: Integer; ExpectedErrorMessage: array[2] of Text; ErrorMessageHandler: Codeunit "Error Message Handler")
    var
        TempErrorMessage: Record "Error Message" temporary;
        i: Integer;
    begin
        LibraryErrorMessage.TrapErrorMessages();
        ErrorMessageHandler.ShowErrors();
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, ErrorCount);
        i := 0;
        TempErrorMessage.FindSet();
        repeat
            i += 1;
            Assert.ExpectedMessage(ExpectedErrorMessage[i], TempErrorMessage."Message");
        until TempErrorMessage.Next() = 0;
    end;

    local procedure VerifyHeaderDimError(ContextRecID: RecordID; SourceRecID: RecordID; SourceFieldNo: Integer; ExpectedErrorMessage: array[10] of Text; ExpectedSupportURL: Text)
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 2);
        TempErrorMessage.FindFirst();
        TempErrorMessage.TestField("Message Type", TempErrorMessage."Message Type"::Error);
        TempErrorMessage.TestField("Message", ExpectedErrorMessage[1]);
        TempErrorMessage.TestField("Context Record ID", ContextRecID);
        TempErrorMessage.TestField("Record ID", SourceRecID);
        TempErrorMessage.TestField("Field Number", SourceFieldNo);
        TempErrorMessage.TestField("Support Url", ExpectedSupportURL);
        // the last error is "There is nothing to post."
        TempErrorMessage.FindLast();
        TempErrorMessage.TestField("Message", DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    local procedure VerifyHeaderDimErrors(RecID: array[10] of RecordID; ErrorCount: Integer; ExpectedErrorMessage: array[10] of Text; SourceDimRecID: array[10] of RecordID; SourceFieldNo: array[10] of Integer)
    var
        TempErrorMessage: Record "Error Message" temporary;
        i: Integer;
    begin
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, ErrorCount);
        i := 0;
        TempErrorMessage.FindSet();
        repeat
            i += 1;
            Assert.ExpectedMessage(ExpectedErrorMessage[i], TempErrorMessage."Message");
            Assert.AreEqual(RecID[i], TempErrorMessage."Context Record ID", 'Context Record ID' + Format(i));
            Assert.AreEqual(SourceDimRecID[i], TempErrorMessage."Record ID", 'Record ID' + Format(i));
            Assert.AreEqual(SourceFieldNo[i], TempErrorMessage."Field Number", 'Field Number' + Format(i));
        until TempErrorMessage.Next() = 0;
    end;

    local procedure VerifyLineDimErrors(LineRecID: array[10] of RecordID; ErrorCount: Integer; ExpectedErrorMessage: array[10] of Text; SourceDimRecID: array[10] of RecordID; ExpectedCallStack: array[10] of Text)
    var
        TempErrorMessage: Record "Error Message" temporary;
        i: Integer;
    begin
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, ErrorCount);
        i := 0;
        TempErrorMessage.FindSet();
        repeat
            i += 1;
            Assert.ExpectedMessage(ExpectedCallStack[i], TempErrorMessage.GetErrorCallStack());
            Assert.ExpectedMessage(ExpectedErrorMessage[i], TempErrorMessage."Message");
            Assert.AreEqual(LineRecID[i], TempErrorMessage."Context Record ID", 'Context Record ID' + Format(i));
            Assert.AreEqual(SourceDimRecID[i], TempErrorMessage."Record ID", 'Record ID' + Format(i));
        until (TempErrorMessage.Next() = 0) or (i = ErrorCount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DocDimsModalPageHandler(var EditDimensionSetEntriesPage: TestPage "Edit Dimension Set Entries")
    begin
        LibraryVariableStorage.Enqueue(EditDimensionSetEntriesPage."Dimension Code".Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DocLineDimsModalPageHandler(var EditDimensionSetEntriesPage: TestPage "Edit Dimension Set Entries")
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryVariableStorage.Enqueue(EditDimensionSetEntriesPage."Dimension Code".Value);
        // add another dimension with value to change the dimension set id.
        EditDimensionSetEntriesPage.New();
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        EditDimensionSetEntriesPage."Dimension Code".Value(DimensionValue."Dimension Code");
        EditDimensionSetEntriesPage.DimensionValueCode.Value(DimensionValue.Code);
        EditDimensionSetEntriesPage.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterCheckSalesDoc', '', false, false)]
    local procedure OnAfterCheckSalesDoc(var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; WhseShip: Boolean; WhseReceive: Boolean)
    begin
        Error(OnAfterCheckDocErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterCheckPurchDoc', '', false, false)]
    local procedure OnAfterCheckPurchDoc(var PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean; WhseShip: Boolean; WhseReceive: Boolean)
    begin
        Error(OnAfterCheckDocErr);
    end;
}

