codeunit 134304 "Workflow Event Arguments Test"
{
    // ACTUAL FILTERS ARE SPECIFIED:
    // 
    // <?xml version="1.0" standalone="yes"?>
    // <ReportParameters name="Create Purchase Invoice Step" id="50000">
    //   <Options>
    //     <Field name="&quot;Purchase Header&quot;.&quot;Due Date&quot;">2014-12-04</Field>
    //     <Field name="&quot;Purchase Header&quot;.&quot;Currency Code&quot;">DKK</Field>
    //     <Field name="&quot;Purchase Line&quot;.Description">Hello, World!</Field>
    //     <Field name="&quot;Purchase Line&quot;.Quantity">100</Field>
    //   </Options>
    //   <DataItems>
    //     <DataItem name="Purchase Header">VERSION(1) SORTING(Document Type,No.) WHERE(Buy-from Vendor No.=FILTER(10000),Document Date=FILTER(28-01-16),Amount=FILTER(&gt;1.000))</DataItem>
    //     <DataItem name="Purchase Line">VERSION(1) SORTING(Document Type,Document No.,Line No.) WHERE(Type=FILTER(Item),No.=FILTER(1000),Unit Cost=FILTER(&gt;500))</DataItem>
    //   </DataItems>
    // </ReportParameters>
    // 
    // ____________________________________________________________________
    // NO FILTERS ARE SPECIFIED:
    // 
    // <?xml version="1.0" standalone="yes"?>
    // <ReportParameters name="Create Purchase Invoice Step" id="50000">
    //   <Options>
    //     <Field name="&quot;Purchase Header&quot;.&quot;Due Date&quot;" />
    //     <Field name="&quot;Purchase Header&quot;.&quot;Currency Code&quot;" />
    //     <Field name="&quot;Purchase Line&quot;.Description" />
    //     <Field name="&quot;Purchase Line&quot;.Quantity">0</Field>
    //   </Options>
    //   <DataItems>
    //     <DataItem name="Purchase Header">VERSION(1) SORTING(Document Type,No.)</DataItem>
    //     <DataItem name="Purchase Line">VERSION(1) SORTING(Document Type,Document No.,Line No.)</DataItem>
    //   </DataItems>
    // </ReportParameters>
    // 
    // ____________________________________________________________________
    // EXTRA FILTERS ARE SPECIFIED:
    // 
    // <?xml version="1.0" standalone="yes"?>
    // <ReportParameters name="Purch. Header Line Vendor" id="50000">
    //   <DataItems>
    //     <DataItem name="Purchase Header">VERSION(1) SORTING(Document Type,No.) WHERE(Buy-from Vendor No.=(10000),Document Date=(26-01-17),Amount=(&gt;1.000))</DataItem>
    //     <DataItem name="Purchase Line">VERSION(1) SORTING(Document Type,Document No.,Line No.) WHERE(Type=FILTER(Item),No.=FILTER(1000),Unit Cost=(&gt;500))</DataItem>
    //     <DataItem name="Vendor">VERSION(1) SORTING(No.) WHERE(Vendor Posting Group=(DOMESTIC),VAT Bus. Posting Group=(NATIONAL))</DataItem>
    //   </DataItems>
    // </ReportParameters>

    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Event] [Argument]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        BlankParametersTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Create Purchase Invoice Step" id="50000"><Options><Field name="&quot;Purchase Header&quot;.&quot;Due Date&quot;" /><Field name="&quot;Purchase Header&quot;.&quot;Currency Code&quot;" /><Field name="&quot;Purchase Line&quot;.Description" /><Field name="&quot;Purchase Line&quot;.Quantity">0</Field></Options><DataItems><DataItem name="Table38">SORTING(Document Type,No.)</DataItem><DataItem name="Table39">SORTING(Document Type,Document No.,Line No.)</DataItem></DataItems></ReportParameters>', Locked = true;
        CannotEditEnabledWorkflowErr: Label 'Enabled workflows cannot be edited.';
        DataItemPathTxt: Label '/ReportParameters/DataItems/DataItem', Locked = true;
        DynamicRequestPageBlankParametersTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Table38">VERSION(1) SORTING(Field1,Field3)</DataItem><DataItem name="Table39">VERSION(1) SORTING(Field1,Field3,Field4)</DataItem></DataItems></ReportParameters>', Locked = true;
        DynamicRequestPageFiltersNotSetErr: Label 'The filters were not set on the dynamic request page.';
        DynamicRequestPageNotPreparedErr: Label 'The dynamic request page was not prepared for the %1 table.';
        DynamicRequestPageParametersTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Table38">VERSION(1) SORTING(Field1,Field3) WHERE(Field2=1(%1),Field24=1(%2),Field60=1(&gt;%3))</DataItem><DataItem name="Table39">VERSION(1) SORTING(Field1,Field3,Field4) WHERE(Field5=1(2),Field6=1(%4),Field22=1(&gt;%5))</DataItem></DataItems></ReportParameters>', Locked = true;
        DynamicRequestPageWasPreparedErr: Label 'The dynamic request page was prepared for table %1.';
        FilterMismatchErr: Label 'Filters are not the same.';
        FilterNotBlankErr: Label 'Filters are applied to record %1.';
        NullArgumentErr: Label 'The workflow step should have a null workflow step argument.';
        ParametersTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Create Purchase Invoice Step" id="50000"><Options><Field name="&quot;Purchase Header&quot;.&quot;Due Date&quot;">2014-12-04</Field><Field name="&quot;Purchase Header&quot;.&quot;Currency Code&quot;">DKK</Field><Field name="&quot;Purchase Line&quot;.Description">Hello, World!</Field><Field name="&quot;Purchase Line&quot;.Quantity">100</Field></Options><DataItems><DataItem name="Table38">SORTING(Document Type,No.) WHERE(Buy-from Vendor No.=FILTER(10000),Document Date=FILTER(%1),Amount=FILTER(&gt;%2))</DataItem><DataItem name="Table39">SORTING(Document Type,Document No.,Line No.) WHERE(Type=FILTER(Item),No.=FILTER(1000),Unit Cost=FILTER(&gt;500))</DataItem></DataItems></ReportParameters>', Locked = true;
        SalesParametersTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Create Sales Invoice Step" id="50000"><Options><Field name="&quot;Sales Header&quot;.&quot;Due Date&quot;">2014-12-04</Field><Field name="&quot;Sales Header&quot;.&quot;Currency Code&quot;">DKK</Field><Field name="&quot;Sales Line&quot;.Description">Hello, World!</Field><Field name="&quot;Sales Line&quot;.Quantity">100</Field></Options><DataItems><DataItem name="Header">SORTING(Document Type,No.) WHERE(Document Date=FILTER(%1),Amount=FILTER(&gt;%2))</DataItem><DataItem name="Table37">SORTING(Document Type,Document No.,Line No.) WHERE(Type=FILTER(Item),No.=FILTER(1000),Unit Cost=FILTER(&gt;500))</DataItem></DataItems></ReportParameters>', Locked = true;
        IncomingDocumentTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Incoming Document">VERSION(1) SORTING(Field1) WHERE(Field18=1(6))</DataItem><DataItem name="Incoming Document Attachment">VERSION(1) SORTING(Field1,Field2)</DataItem></DataItems></ReportParameters>', Locked = true;
        ParametersWithoutDataItemsTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Create Purchase Invoice Step" id="50000"><Options><Field name="&quot;Purchase Header&quot;.&quot;Due Date&quot;">2014-12-04</Field><Field name="&quot;Purchase Header&quot;.&quot;Currency Code&quot;">DKK</Field><Field name="&quot;Purchase Line&quot;.Description">Hello, World!</Field><Field name="&quot;Purchase Line&quot;.Quantity">100</Field></Options></ReportParameters>', Locked = true;
        PurchaseHeaderBlankParametersTxt: Label 'VERSION(1) SORTING(Document Type,No.)', Locked = true;
        PurchaseHeaderParametersTxt: Label 'VERSION(1) SORTING(Document Type,No.) WHERE(Buy-from Vendor No.=FILTER(10000),Document Date=FILTER(%1),Amount=FILTER(>%2))', Locked = true;
        PurchaseLineParametersTxt: Label 'VERSION(1) SORTING(Document Type,Document No.,Line No.) WHERE(Type=FILTER(Item),No.=FILTER(1000),Unit Cost=FILTER(>500))', Locked = true;
        PurchaseLineBlankParametersTxt: Label 'VERSION(1) SORTING(Document Type,Document No.,Line No.)', Locked = true;
        RecordNotCreatedErr: Label 'The record %1 was not created.';
        RecordNotDeletedErr: Label 'The record %1 was not deleted';
        UserClickedCancelMsg: Label 'User clicked the Cancel button.';
        UserClickedOkayMsg: Label 'User clicked the OK button.';
        WorkflowStepArgumentErr: Label 'Workflow step %1 of workflow %2 has an argument.';
        WrongFieldFilterErr: Label 'Filter on field %1 of record %2 is not set properly.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWorkflow: Codeunit "Library - Workflow";
        XmlNodesNotFoundErr: Label 'The XML Nodes at %1 cannot be found in the XML Document %2.';

    [Test]
    [Scope('OnPrem')]
    procedure ConvertBlankParametersToFilters()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        PurchaseHeaderRecRef: RecordRef;
        PurchaseLineRecRef: RecordRef;
    begin
        Initialize();

        // Setup
        CreateWorkflowWithStepAndArgument(WorkflowStep, WorkflowStepArgument);
        WorkflowStepArgument.SetEventFilters(BlankParametersTxt);

        // Exercise
        PurchaseHeaderRecRef.Open(DATABASE::"Purchase Header");
        PurchaseLineRecRef.Open(DATABASE::"Purchase Line");
        WorkflowStep.ConvertEventConditionsToFilters(PurchaseHeaderRecRef);
        WorkflowStep.ConvertEventConditionsToFilters(PurchaseLineRecRef);

        // Verify
        Assert.AreEqual('', PurchaseHeaderRecRef.GetFilters, StrSubstNo(FilterNotBlankErr, PurchaseHeader.TableCaption()));
        Assert.AreEqual('', PurchaseLineRecRef.GetFilters, StrSubstNo(FilterNotBlankErr, PurchaseLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConvertParametersToFilters()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        PurchaseHeaderRecRef: RecordRef;
        PurchaseLineRecRef: RecordRef;
    begin
        Initialize();

        // Setup
        // <DataItem name="Purchase Header">VERSION(1) SORTING(Document Type,No.) WHERE(Buy-from Vendor No.=FILTER(10000),Document Date=FILTER(28-01-16),Amount=FILTER(&gt;1.000))</DataItem>
        PurchaseHeader.SetRange("Buy-from Vendor No.", '10000');
        PurchaseHeader.SetRange("Document Date", WorkDate());
        PurchaseHeader.SetFilter(Amount, '>%1', 1000);
        // <DataItem name="Purchase Line">VERSION(1) SORTING(Document Type,Document No.,Line No.) WHERE(Type=FILTER(Item),No.=FILTER(1000),Unit Cost=FILTER(&gt;500))</DataItem>
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", '1000');
        PurchaseLine.SetFilter("Unit Cost", '>%1', 500);

        CreateWorkflowWithStepAndArgument(WorkflowStep, WorkflowStepArgument);
        WorkflowStepArgument.SetEventFilters(StrSubstNo(ParametersTxt, WorkDate(), 1000));

        // Exercise
        PurchaseHeaderRecRef.Open(DATABASE::"Purchase Header");
        PurchaseLineRecRef.Open(DATABASE::"Purchase Line");
        WorkflowStep.ConvertEventConditionsToFilters(PurchaseHeaderRecRef);
        WorkflowStep.ConvertEventConditionsToFilters(PurchaseLineRecRef);

        // Verify
        Assert.AreEqual(PurchaseHeader.GetFilters, PurchaseHeaderRecRef.GetFilters, FilterMismatchErr);
        Assert.AreEqual(PurchaseLine.GetFilters, PurchaseLineRecRef.GetFilters, FilterMismatchErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConvertParamsToFiltersNonStandartDataItemName()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        SalesHeaderRecRef: RecordRef;
        SalesLineRecRef: RecordRef;
    begin
        Initialize();

        // Setup
        // <DataItem name="Header">SORTING(Document Type,No.) WHERE(Document Date=FILTER(%1),Amount=FILTER(&gt;%2))</DataItem>
        SalesHeader.SetRange("Document Date", WorkDate());
        SalesHeader.SetFilter(Amount, '>%1', 1000);
        // <DataItem name="Table37">SORTING(Document Type,Document No.,Line No.) WHERE(Type=FILTER(Item),No.=FILTER(1000),Unit Cost=FILTER(&gt;500))</DataItem>
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", '1000');
        SalesLine.SetFilter("Unit Cost", '>%1', 500);

        CreateWorkflowWithStepAndArgument(WorkflowStep, WorkflowStepArgument);
        WorkflowStepArgument.SetEventFilters(StrSubstNo(SalesParametersTxt, WorkDate(), 1000));

        // Exercise
        SalesHeaderRecRef.Open(DATABASE::"Sales Header");
        SalesLineRecRef.Open(DATABASE::"Sales Line");
        WorkflowStep.ConvertEventConditionsToFilters(SalesHeaderRecRef);
        WorkflowStep.ConvertEventConditionsToFilters(SalesLineRecRef);

        // Verify
        Assert.AreEqual(SalesHeader.GetFilters, SalesHeaderRecRef.GetFilters, FilterMismatchErr);
        Assert.AreEqual(SalesLine.GetFilters, SalesLineRecRef.GetFilters, FilterMismatchErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConvertParamsToFiltersTablesSubstringsOfOtherTables()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        IncomingDocumentRecRef: RecordRef;
        IncomingDocumentAttachmentRecRef: RecordRef;
    begin
        // Bug 373821. Verify that the filters will be applied to the correct table when the table name
        // is a substring of other table name and they are both part of report parameters.
        Initialize();

        // Setup
        // <DataItem name="Incoming Document">VERSION(1) SORTING(Field1) WHERE(Field18=1(6))</DataItem>
        IncomingDocument.SetRange(Status, IncomingDocument.Status::"Pending Approval");

        // <DataItem name="Incoming Document Attachment">VERSION(1) SORTING(Field1,Field2)</DataItem>
        // no need to set filters on IncomingDocumentAttachment, as the xml only describes sorting on the primary key

        CreateWorkflowWithStepAndArgument(WorkflowStep, WorkflowStepArgument);
        WorkflowStepArgument.SetEventFilters(StrSubstNo(IncomingDocumentTxt, WorkDate(), 1000));

        // Exercise
        IncomingDocumentRecRef.Open(DATABASE::"Incoming Document");
        IncomingDocumentAttachmentRecRef.Open(DATABASE::"Incoming Document Attachment");
        WorkflowStep.ConvertEventConditionsToFilters(IncomingDocumentRecRef);
        WorkflowStep.ConvertEventConditionsToFilters(IncomingDocumentAttachmentRecRef);

        // Verify
        Assert.AreEqual(IncomingDocument.GetFilters, IncomingDocumentRecRef.GetFilters, FilterMismatchErr);
        Assert.AreEqual(IncomingDocumentAttachment.GetFilters, IncomingDocumentAttachmentRecRef.GetFilters, FilterMismatchErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CollectParametersMissingFunctionName()
    var
        WorkflowStep: Record "Workflow Step";
        ZeroGUID: Guid;
        WorkflowCode: Code[20];
    begin
        Initialize();

        // Setup
        WorkflowCode := CreateWorkflow();
        CreateWorkflowStep(WorkflowStep, WorkflowCode, ZeroGUID);
        WorkflowStep."Function Name" := '';
        WorkflowStep.Modify();

        // Exercise
        asserterror WorkflowStep.OpenEventConditions();

        // Verify
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CollectParametersMissingRequestPageID()
    var
        WorkflowStep: Record "Workflow Step";
    begin
        Initialize();

        // Setup
        CreateWorkflowWithStepAndDummyEvent(WorkflowStep);

        // Exercise
        WorkflowStep.OpenEventConditions();

        // Verify
        Assert.IsTrue(IsNullGuid(WorkflowStep.Argument),
          StrSubstNo(WorkflowStepArgumentErr, WorkflowStep.ID, WorkflowStep."Workflow Code"));
    end;

    [Test]
    [HandlerFunctions('CancelWorkflowEventSimpleArgumentsRequestPage')]
    [Scope('OnPrem')]
    procedure CollectParametersClickCancelOnRequestPage()
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        Initialize();

        // Setup
        CreateWorkflowWithStepAndAnyEvent(WorkflowStep);
        Commit();

        // Exercise
        WorkflowStep.OpenEventConditions();

        // Verify
        Assert.IsFalse(WorkflowStepArgument.Get(WorkflowStep.Argument), UserClickedOkayMsg);
    end;

    [Test]
    [HandlerFunctions('OkayWorkflowEventSimpleArgumentsRequestPage')]
    [Scope('OnPrem')]
    procedure CollectParametersClickOkayOnRequestPage()
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        Initialize();

        // Setup
        CreateWorkflowWithStepAndAnyEvent(WorkflowStep);
        Commit();

        // Exercise
        WorkflowStep.OpenEventConditions();

        // Verify
        WorkflowStepArgument.Get(WorkflowStep.Argument);
        Assert.IsTrue(WorkflowStepArgument."Event Conditions".HasValue, UserClickedCancelMsg);
    end;

    [Test]
    [HandlerFunctions('WorkflowEventSimpleArgumentsRequestPage')]
    [Scope('OnPrem')]
    procedure CollectSimpleParameters()
    var
        UnitOfMeasure: Record "Unit of Measure";
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        CreateWorkflowWithStepAndAnyEvent(WorkflowStep);

        // Exercise
        SetupEventConditions(WorkflowStep, Amount, UnitOfMeasure.Code, LibraryPurchase.CreateVendorNo());

        // Verify
        WorkflowStepArgument.Get(WorkflowStep.Argument);
        Assert.IsTrue(WorkflowStepArgument."Event Conditions".HasValue, UserClickedCancelMsg);

        VerifyPurchaseHeaderFilters(WorkflowStep);
        VerifyPurchaseLineFilters(WorkflowStep, Amount, UnitOfMeasure.Code);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WorkflowEventAdvancedArgumentsRequestPage')]
    [Scope('OnPrem')]
    procedure CollectAdvancedParameters()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        UnitOfMeasure: Record "Unit of Measure";
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        ZeroGUID: Guid;
        Amount: Decimal;
        CurrencyCode: Code[10];
        CurrencyCodeLength: Integer;
        Description: Text[100];
        DescriptionLength: Integer;
        DueDate: Date;
        Quantity: Decimal;
        WorkflowCode: Code[20];
    begin
        Initialize();

        // Setup
        DueDate := LibraryUtility.GenerateRandomDate(WorkDate() - 30, WorkDate() + 30);
        CurrencyCodeLength := LibraryUtility.GetFieldLength(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Currency Code"));
        CurrencyCode := CopyStr(LibraryUtility.GenerateRandomText(CurrencyCodeLength), 1, CurrencyCodeLength);
        DescriptionLength := LibraryUtility.GetFieldLength(DATABASE::"Purchase Line", PurchaseLine.FieldNo(Description));
        Description := CopyStr(LibraryUtility.GenerateRandomText(DescriptionLength), 1, DescriptionLength);
        Quantity := LibraryRandom.RandDec(100, 2);
        Amount := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        WorkflowCode := CreateWorkflow();
        CreateWorkflowStep(WorkflowStep, WorkflowCode, ZeroGUID);
        CreateDummyWorkflowEventWithTableAndPageID(WorkflowStep."Function Name", DATABASE::"Purchase Header",
          REPORT::"Workflow Event Advanced Args");

        // Exercise
        LibraryVariableStorage.Enqueue(DueDate);
        LibraryVariableStorage.Enqueue(CurrencyCode);
        LibraryVariableStorage.Enqueue(Description);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(Amount);
        LibraryVariableStorage.Enqueue(UnitOfMeasure.Code);
        LibraryVariableStorage.Enqueue(LibraryPurchase.CreateVendorNo());
        Commit();

        // Exercise
        WorkflowStep.OpenEventConditions();

        // Verify
        WorkflowStepArgument.Get(WorkflowStep.Argument);
        Assert.IsTrue(WorkflowStepArgument."Event Conditions".HasValue, UserClickedCancelMsg);

        VerifyPurchaseHeaderFilters(WorkflowStep);
        VerifyPurchaseLineFilters(WorkflowStep, Amount, UnitOfMeasure.Code);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteParameters()
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        Initialize();

        // PSetup
        CreateWorkflowWithStepAndArgument(WorkflowStep, WorkflowStepArgument);
        WorkflowStepArgument.SetEventFilters(LibraryUtility.GenerateRandomXMLText(1024));

        Assert.IsFalse(IsNullGuid(WorkflowStep.Argument), StrSubstNo(RecordNotCreatedErr, WorkflowStepArgument.TableCaption()));

        // Exercise
        WorkflowStep.DeleteEventConditions();

        // Verify
        Assert.IsTrue(IsNullGuid(WorkflowStep.Argument), StrSubstNo(RecordNotDeletedErr, WorkflowStepArgument.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteParametersUsingWorkflowBuffer()
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStepBuffer: Record "Workflow Step Buffer";
    begin
        Initialize();

        // Setup
        CreateWorkflowWithStepAndArgument(WorkflowStep, WorkflowStepArgument);
        WorkflowStepArgument.SetEventFilters(StrSubstNo(ParametersTxt, WorkDate(), 1000));
        Assert.IsFalse(IsNullGuid(WorkflowStep.Argument), StrSubstNo(RecordNotCreatedErr, WorkflowStepArgument.TableCaption()));
        WorkflowStepBuffer.PopulateTable(WorkflowStep."Workflow Code");
        WorkflowStepBuffer.FindFirst();

        // Exercise
        WorkflowStepBuffer.DeleteEventConditions();

        // Verify
        WorkflowStep.Find();
        Assert.IsTrue(IsNullGuid(WorkflowStep.Argument), StrSubstNo(RecordNotDeletedErr, WorkflowStepArgument.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FailToFindDataItems()
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        XMLDOMManagement: Codeunit "XML DOM Management";
        RecRef: RecordRef;
        ParametersXmlDoc: DotNet XmlDocument;
        RootXmlNode: DotNet XmlNode;
    begin
        Initialize();

        // Setup
        CreateWorkflowWithStepAndArgument(WorkflowStep, WorkflowStepArgument);
        WorkflowStepArgument.SetEventFilters(ParametersWithoutDataItemsTxt);
        RecRef.Open(DATABASE::"Purchase Header");

        // Exercise
        asserterror WorkflowStep.ConvertEventConditionsToFilters(RecRef);

        // Verify
        XMLDOMManagement.LoadXMLNodeFromText(ParametersWithoutDataItemsTxt, RootXmlNode);
        ParametersXmlDoc := RootXmlNode.OwnerDocument;

        Assert.ExpectedError(StrSubstNo(XmlNodesNotFoundErr, DataItemPathTxt, ParametersXmlDoc.DocumentElement.InnerXml));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotEditArgumentIfWorkflowIsEnabled()
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        Initialize();

        // Setup
        CreateWorkflowWithStepAndArgument(WorkflowStep, WorkflowStepArgument);
        EnableWorkflow(WorkflowStep."Workflow Code");

        // Excercise
        asserterror WorkflowStepArgument.SetEventFilters(BlankParametersTxt);

        // Verify
        Assert.ExpectedError(CannotEditEnabledWorkflowErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetEventFilterSavesValueCorrectly()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        LongText: Text;
        ShortText: Text;
        Content: Text;
    begin
        Initialize();

        // Setup
        CreateWorkflowStepEventArgument(WorkflowStepArgument);
        LongText := LibraryUtility.GenerateRandomText(100);
        ShortText := LibraryUtility.GenerateRandomText(50);

        // Excercise
        WorkflowStepArgument.SetEventFilters(LongText);
        WorkflowStepArgument.SetEventFilters(ShortText);

        // Verify
        TempBlob.FromRecord(WorkflowStepArgument, WorkflowStepArgument.FieldNo("Event Conditions"));
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        InStream.Read(Content);
        Assert.AreEqual(ShortText, Content, 'Blob should be truncated to the size of ShortText');
    end;

    [Test]
    [HandlerFunctions('CancelWorkflowEventSimpleArgumentsRequestPage')]
    [Scope('OnPrem')]
    procedure ShowMissingEventConditionsIfWorkflowIsEnabled()
    var
        WorkflowStep: Record "Workflow Step";
    begin
        Initialize();

        // Setup
        CreateWorkflowWithStepAndAnyEvent(WorkflowStep);
        EnableWorkflow(WorkflowStep."Workflow Code");
        Commit();

        // Exercise
        WorkflowStep.OpenEventConditions();

        // Verify
        WorkflowStep.Find();
        Assert.IsTrue(IsNullGuid(WorkflowStep.Argument), NullArgumentErr);
    end;

    [Test]
    [HandlerFunctions('DisplayWorkflowEventSimpleArgumentsRequestPage')]
    [Scope('OnPrem')]
    procedure EditingEventConditionsIfWorkflowIsEnabled()
    var
        UnitOfMeasure: Record "Unit of Measure";
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        Workflow: Record Workflow;
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        CreateWorkflowWithStepAndAnyEvent(WorkflowStep);
        CreateWorkflowStepEventArgument(WorkflowStepArgument);
        WorkflowStep.Argument := WorkflowStepArgument.ID;
        WorkflowStep.Modify();
        Workflow.Get(WorkflowStep."Workflow Code");
        LibraryWorkflow.EnableWorkflow(Workflow);

        // Exercise
        LibraryVariableStorage.Enqueue(Amount);
        LibraryVariableStorage.Enqueue(UnitOfMeasure.Code);
        LibraryVariableStorage.Enqueue(LibraryPurchase.CreateVendorNo());
        Commit();

        asserterror WorkflowStep.OpenEventConditions();

        // Verify
        Assert.ExpectedError(CannotEditEnabledWorkflowErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuildDynamicRequestPage()
    var
        PurchaseHeader: Record "Purchase Header";
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FilterPageBuilder: FilterPageBuilder;
        EntityName: Code[20];
        Result: Boolean;
    begin
        Initialize();

        // Setup
        EntityName := CreatePurchaseInvoiceEntity();
        CreatePurchaseInvoiceTableRelations();
        SpecifyPurchaseInvoiceFilteringFields();

        // Exercise
        Result := RequestPageParametersHelper.BuildDynamicRequestPage(FilterPageBuilder, EntityName, DATABASE::"Purchase Header");

        // Verify
        Assert.IsTrue(Result, StrSubstNo(DynamicRequestPageNotPreparedErr, PurchaseHeader.TableCaption()));
        VerifyDynamicRequestPageBlankParametersForPurchaseInvoice(FilterPageBuilder, EntityName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuildDynamicRequestPageForTableMissingRelations()
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FilterPageBuilder: FilterPageBuilder;
        Result: Boolean;
    begin
        Initialize();

        // Setup
        DeleteTableRelations(DATABASE::"Purchase Header");
        SpecifyPurchaseInvoiceFilteringFields();

        // Exercise
        Result := RequestPageParametersHelper.BuildDynamicRequestPage(FilterPageBuilder, '', DATABASE::"Purchase Header");

        // Verify
        Assert.IsTrue(Result, StrSubstNo(DynamicRequestPageNotPreparedErr, 0));
        VerifyDynamicRequestPageBlankParametersForPurchaseHeader(FilterPageBuilder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuildDynamicRequestPageForNonExistingTable()
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FilterPageBuilder: FilterPageBuilder;
        Result: Boolean;
    begin
        // Setup
        Initialize();

        // Exercise
        Result := RequestPageParametersHelper.BuildDynamicRequestPage(FilterPageBuilder, '', 0);

        // Verify
        Assert.IsFalse(Result, StrSubstNo(DynamicRequestPageWasPreparedErr, 0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetViewFromDynamicRequestPageUsingBlankParameters()
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FilterPageBuilder: FilterPageBuilder;
        EntityName: Code[20];
        Result: Boolean;
    begin
        Initialize();

        // Setup
        EntityName := CreatePurchaseInvoiceEntity();
        CreatePurchaseInvoiceTableRelations();
        SpecifyPurchaseInvoiceFilteringFields();
        RequestPageParametersHelper.BuildDynamicRequestPage(FilterPageBuilder, EntityName, DATABASE::"Purchase Header");

        // Exercise
        Result :=
          RequestPageParametersHelper.SetViewOnDynamicRequestPage(
            FilterPageBuilder, BlankParametersTxt, EntityName, DATABASE::"Purchase Header");

        // Verify
        Assert.IsTrue(Result, DynamicRequestPageFiltersNotSetErr);
        VerifyDynamicRequestPageBlankParametersForPurchaseInvoice(FilterPageBuilder, EntityName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetViewFromDynamicRequestPageUsingCustomParameters()
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FilterPageBuilder: FilterPageBuilder;
        EntityName: Code[20];
        Result: Boolean;
    begin
        Initialize();

        // Setup
        EntityName := CreatePurchaseInvoiceEntity();
        CreatePurchaseInvoiceTableRelations();
        SpecifyPurchaseInvoiceFilteringFields();
        RequestPageParametersHelper.BuildDynamicRequestPage(FilterPageBuilder, EntityName, DATABASE::"Purchase Header");

        // Exercise
        Result :=
          RequestPageParametersHelper.SetViewOnDynamicRequestPage(FilterPageBuilder,
            StrSubstNo(ParametersTxt, WorkDate(), 100), EntityName, DATABASE::"Purchase Header");

        // Verify
        Assert.IsTrue(Result, DynamicRequestPageFiltersNotSetErr);
        VerifyDynamicRequestPageParametersForPurchaseInvoice(FilterPageBuilder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetViewFromDynamicRequestPage()
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FilterPageBuilder: FilterPageBuilder;
        Amount: Decimal;
        DirectUnitCost: Decimal;
        EntityName: Code[20];
        Filters: Text;
        ItemNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();

        // Setup
        VendorNo := LibraryPurchase.CreateVendorNo();
        Amount := LibraryRandom.RandIntInRange(1000, 2000);
        ItemNo := LibraryInventory.CreateItemNo();
        DirectUnitCost := LibraryRandom.RandIntInRange(250, 500);

        EntityName := CreatePurchaseInvoiceEntity();
        CreatePurchaseInvoiceTableRelations();
        SpecifyPurchaseInvoiceFilteringFields();
        CreatePurchaseHeaderDataItem(FilterPageBuilder, VendorNo, Amount);
        CreatePurchaseLineDataItem(FilterPageBuilder, ItemNo, DirectUnitCost);

        // Exercise
        Filters := RequestPageParametersHelper.GetViewFromDynamicRequestPage(FilterPageBuilder, EntityName, DATABASE::"Purchase Header");

        // Verify
        Assert.AreEqual(
          StrSubstNo(DynamicRequestPageParametersTxt, VendorNo, Format(WorkDate(), 0, 9), Format(Amount, 0, 9), ItemNo,
            Format(DirectUnitCost, 0, 9)), Filters, FilterMismatchErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetViewFromDynamicRequestPageExtraTableIsAdded()
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FilterPageBuilder: FilterPageBuilder;
        Amount: Decimal;
        DirectUnitCost: Decimal;
        EntityName: Code[20];
        Filters: Text;
        ItemNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();

        // Setup
        VendorNo := LibraryPurchase.CreateVendorNo();
        Amount := LibraryRandom.RandIntInRange(1000, 2000);
        ItemNo := LibraryInventory.CreateItemNo();
        DirectUnitCost := LibraryRandom.RandIntInRange(250, 500);

        EntityName := CreatePurchaseInvoiceEntity();
        CreatePurchaseInvoiceTableRelations();
        SpecifyPurchaseInvoiceFilteringFields();
        CreatePurchaseHeaderDataItem(FilterPageBuilder, VendorNo, Amount);
        CreatePurchaseLineDataItem(FilterPageBuilder, ItemNo, DirectUnitCost);

        // Exercise
        CreateExtraTableRelation();
        Filters := RequestPageParametersHelper.GetViewFromDynamicRequestPage(FilterPageBuilder, EntityName, DATABASE::"Purchase Header");

        // Verify
        Assert.AreEqual(
          StrSubstNo(DynamicRequestPageParametersTxt, VendorNo, Format(WorkDate(), 0, 9), Format(Amount, 0, 9), ItemNo,
            Format(DirectUnitCost, 0, 9)), Filters, FilterMismatchErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetViewFromDynamicRequestPageExistingTableIsRemoved()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FilterPageBuilder: FilterPageBuilder;
        Amount: Decimal;
        DirectUnitCost: Decimal;
        EntityName: Code[20];
        Filters: Text;
        ItemNo: Code[20];
        VendorNo: Code[20];
        VendorPostingGroup: Code[20];
    begin
        Initialize();

        // Setup
        VendorNo := LibraryPurchase.CreateVendorNo();
        Amount := LibraryRandom.RandIntInRange(1000, 2000);
        ItemNo := LibraryInventory.CreateItemNo();
        DirectUnitCost := LibraryRandom.RandIntInRange(250, 500);
        VendorPostingGroup := LibraryPurchase.FindVendorPostingGroup();
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);

        EntityName := CreatePurchaseInvoiceEntity();
        CreatePurchaseInvoiceTableRelations();
        CreateVendorTableRelation();
        SpecifyPurchaseInvoiceFilteringFields();
        CreatePurchaseHeaderDataItem(FilterPageBuilder, VendorNo, Amount);
        CreatePurchaseLineDataItem(FilterPageBuilder, ItemNo, DirectUnitCost);
        CreateVendorDataItem(FilterPageBuilder, VendorPostingGroup, VATBusinessPostingGroup.Code);

        // Exercise
        DeleteVendorTableRelation();
        Filters := RequestPageParametersHelper.GetViewFromDynamicRequestPage(FilterPageBuilder, EntityName, DATABASE::"Purchase Header");

        // Verify
        Assert.AreEqual(
          StrSubstNo(DynamicRequestPageParametersTxt, VendorNo, Format(WorkDate(), 0, 9), Format(Amount, 0, 9), ItemNo,
            Format(DirectUnitCost, 0, 9)), Filters, FilterMismatchErr);
    end;

    [Test]
    [HandlerFunctions('WorkflowEventSimpleArgumentsRequestPage')]
    [Scope('OnPrem')]
    procedure WorkflowSaveLoadWithLongEventCondition()
    var
        UnitOfMeasure: Record "Unit of Measure";
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        Amount: Decimal;
    begin
        // [SCENARIO 212485] User can load workflow with long condition exceeds 1024 character length when converted to BASE64
        Initialize();

        Amount := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        CreateWorkflowWithStepAndAnyEvent(WorkflowStep);

        // [GIVEN] Workflow with event condition = filter by 21 vendors
        SetupEventConditions(WorkflowStep, Amount, UnitOfMeasure.Code, GenerateVendorLongFilter());

        WorkflowStepArgument.Get(WorkflowStep.Argument);
        Assert.IsTrue(WorkflowStepArgument."Event Conditions".HasValue, UserClickedCancelMsg);

        // [GIVEN] "F" saved to file "A"
        // [GIVEN] "F" deleted (to allow load again)

        // [WHEN] User loads "A"
        SaveAndLoadWorkflow(WorkflowStep);

        // [THEN] Workflow "F" created and event condition = filter by 21 vendors
        WorkflowStepArgument.Get(WorkflowStep.Argument);
        Assert.IsTrue(WorkflowStepArgument."Event Conditions".HasValue, UserClickedCancelMsg);

        VerifyPurchaseHeaderFilters(WorkflowStep);
        VerifyPurchaseLineFilters(WorkflowStep, Amount, UnitOfMeasure.Code);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateWorkflowWithStepAndArgument(var WorkflowStep: Record "Workflow Step"; var WorkflowStepArgument: Record "Workflow Step Argument")
    begin
        CreateWorkflowStepEventArgument(WorkflowStepArgument);
        CreateWorkflowStep(WorkflowStep, CreateWorkflow(), WorkflowStepArgument.ID);
    end;

    local procedure CreateWorkflowWithStepAndDummyEvent(var WorkflowStep: Record "Workflow Step")
    var
        ZeroGUID: Guid;
    begin
        CreateWorkflowStep(WorkflowStep, CreateWorkflow(), ZeroGUID);
        CreateDummyWorkflowEventWithTableAndPageID(WorkflowStep."Function Name", DATABASE::"Purchase Header", 0);
    end;

    local procedure CreateWorkflowWithStepAndAnyEvent(var WorkflowStep: Record "Workflow Step")
    var
        ZeroGUID: Guid;
    begin
        CreateWorkflowStep(WorkflowStep, CreateWorkflow(), ZeroGUID);
        CreateDummyWorkflowEventWithTableAndPageID(
          WorkflowStep."Function Name", DATABASE::"Purchase Header", REPORT::"Workflow Event Simple Args");
    end;

    local procedure CreateWorkflow(): Code[20]
    var
        Workflow: Record Workflow;
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);
        exit(Workflow.Code);
    end;

    local procedure CreateWorkflowStep(var WorkflowStep: Record "Workflow Step"; WorkflowCode: Code[20]; ActivityArgument: Guid)
    begin
        WorkflowStep.Init();
        WorkflowStep."Workflow Code" := WorkflowCode;
        WorkflowStep.Type := WorkflowStep.Type::"Event";
        WorkflowStep."Function Name" :=
          LibraryUtility.GenerateRandomCode(WorkflowStep.FieldNo("Function Name"), DATABASE::"Workflow Step");
        WorkflowStep.Argument := ActivityArgument;
        WorkflowStep.Insert();
    end;

    local procedure CreateWorkflowStepEventArgument(var WorkflowStepArgument: Record "Workflow Step Argument")
    begin
        WorkflowStepArgument.Init();
        WorkflowStepArgument.Type := WorkflowStepArgument.Type::"Event";
        WorkflowStepArgument.Insert(true);
    end;

    local procedure CreateDummyWorkflowEvent(FunctionName: Code[128])
    var
        WorkflowEvent: Record "Workflow Event";
    begin
        WorkflowEvent.Init();
        WorkflowEvent."Function Name" := FunctionName;
        WorkflowEvent.Insert();
    end;

    local procedure CreateDummyWorkflowEventWithTableAndPageID(FunctionName: Code[128]; TableID: Integer; RequestPageID: Integer)
    var
        WorkflowEvent: Record "Workflow Event";
    begin
        CreateDummyWorkflowEvent(FunctionName);
        WorkflowEvent.Get(FunctionName);
        WorkflowEvent."Table ID" := TableID;
        WorkflowEvent."Request Page ID" := RequestPageID;
        WorkflowEvent.Modify();
    end;

    local procedure VerifyPurchaseHeaderFilters(WorkflowStep: Record "Workflow Step")
    var
        PurchaseHeader: Record "Purchase Header";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(PurchaseHeader);
        WorkflowStep.ConvertEventConditionsToFilters(RecRef);
        RecRef.SetTable(PurchaseHeader);

        Assert.AreEqual(Format(PurchaseHeader."Document Type"::Invoice), PurchaseHeader.GetFilter("Document Type"),
          StrSubstNo(WrongFieldFilterErr, PurchaseHeader.FieldCaption("Document Type"), PurchaseHeader.TableCaption()));
        Assert.AreNotEqual('', PurchaseHeader.GetFilter("Buy-from Vendor No."),
          StrSubstNo(WrongFieldFilterErr, PurchaseHeader.FieldCaption("Buy-from Vendor No."), PurchaseHeader.TableCaption()));
    end;

    local procedure VerifyPurchaseLineFilters(WorkflowStep: Record "Workflow Step"; Amount: Decimal; UnitOfMeasure: Text[10])
    var
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(PurchaseLine1);
        WorkflowStep.ConvertEventConditionsToFilters(RecRef);
        RecRef.SetTable(PurchaseLine1);

        PurchaseLine2.SetFilter(Amount, '>%1', Amount);
        PurchaseLine2.SetRange("Unit of Measure", UnitOfMeasure);

        Assert.AreEqual(PurchaseLine2.GetFilter(Amount), PurchaseLine1.GetFilter(Amount),
          StrSubstNo(WrongFieldFilterErr, PurchaseLine1.FieldCaption(Amount), PurchaseLine1.TableCaption()));
        Assert.AreEqual(PurchaseLine2.GetFilter("Unit of Measure"), PurchaseLine1.GetFilter("Unit of Measure"),
          StrSubstNo(WrongFieldFilterErr, PurchaseLine1.FieldCaption("Unit of Measure"), PurchaseLine1.TableCaption()));
    end;

    local procedure DeletePurhcaseHeaderRelatedEntities()
    var
        DynamicRequestPageEntity: Record "Dynamic Request Page Entity";
    begin
        DynamicRequestPageEntity.SetRange("Table ID", DATABASE::"Purchase Header");
        DynamicRequestPageEntity.DeleteAll(true);
    end;

    local procedure CreatePurchaseInvoiceEntity() EntityName: Code[20]
    begin
        DeletePurhcaseHeaderRelatedEntities();

        EntityName := LibraryUtility.GenerateGUID();

        LibraryWorkflow.CreateDynamicRequestPageEntity(EntityName, DATABASE::"Purchase Header", DATABASE::"Purchase Line");
        // LibraryWorkflow.CreateDynamicRequestPageEntity(EntityName,DATABASE::"Purchase Header",DATABASE::Vendor);
    end;

    local procedure DeleteTableRelations(TableID: Integer)
    var
        WorkflowTableRelation: Record "Workflow - Table Relation";
    begin
        WorkflowTableRelation.SetRange("Table ID", TableID);
        WorkflowTableRelation.DeleteAll(true);
    end;

    local procedure CreatePurchaseInvoiceTableRelations()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        WorkflowTableRelation: Record "Workflow - Table Relation";
    begin
        DeleteTableRelations(DATABASE::"Purchase Header");

        LibraryWorkflow.CreateWorkflowTableRelation(WorkflowTableRelation,
          DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Document Type"),
          DATABASE::"Purchase Line", PurchaseLine.FieldNo("Document Type"));

        LibraryWorkflow.CreateWorkflowTableRelation(WorkflowTableRelation,
          DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No."),
          DATABASE::"Purchase Line", PurchaseLine.FieldNo("Document No."));

        LibraryWorkflow.CreateWorkflowTableRelation(WorkflowTableRelation,
          DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."),
          DATABASE::"Purchase Line", PurchaseLine.FieldNo("Buy-from Vendor No."));

        LibraryWorkflow.CreateWorkflowTableRelation(WorkflowTableRelation,
          DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No."),
          DATABASE::"Purch. Inv. Header", PurchInvHeader.FieldNo("Pre-Assigned No."));

        LibraryWorkflow.CreateWorkflowTableRelation(WorkflowTableRelation,
          DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."),
          DATABASE::"Purch. Inv. Header", PurchInvHeader.FieldNo("Buy-from Vendor No."));
    end;

    local procedure CreateExtraTableRelation()
    var
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
        WorkflowTableRelation: Record "Workflow - Table Relation";
    begin
        LibraryWorkflow.CreateWorkflowTableRelation(WorkflowTableRelation,
          DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Payment Terms Code"),
          DATABASE::"Payment Terms", PaymentTerms.FieldNo(Code));
    end;

    local procedure CreateVendorTableRelation()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        WorkflowTableRelation: Record "Workflow - Table Relation";
    begin
        LibraryWorkflow.CreateWorkflowTableRelation(WorkflowTableRelation,
          DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."),
          DATABASE::Vendor, Vendor.FieldNo("No."));
    end;

    local procedure DeleteVendorTableRelation()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        WorkflowTableRelation: Record "Workflow - Table Relation";
    begin
        WorkflowTableRelation.Get(
          DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."),
          DATABASE::Vendor, Vendor.FieldNo("No."));
        WorkflowTableRelation.Delete(true);
    end;

    local procedure SpecifyPurchaseInvoiceFilteringFields()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryWorkflow.DeleteDynamicRequestPageFields(DATABASE::"Purchase Header");
        LibraryWorkflow.DeleteDynamicRequestPageFields(DATABASE::"Purchase Line");

        LibraryWorkflow.CreateDynamicRequestPageField(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        LibraryWorkflow.CreateDynamicRequestPageField(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Document Date"));
        LibraryWorkflow.CreateDynamicRequestPageField(DATABASE::"Purchase Header", PurchaseHeader.FieldNo(Amount));

        LibraryWorkflow.CreateDynamicRequestPageField(DATABASE::"Purchase Line", PurchaseLine.FieldNo(Type));
        LibraryWorkflow.CreateDynamicRequestPageField(DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."));
        LibraryWorkflow.CreateDynamicRequestPageField(DATABASE::"Purchase Line", PurchaseLine.FieldNo("Direct Unit Cost"));
    end;

    local procedure CreatePurchaseHeaderDataItem(var FilterPageBuilder: FilterPageBuilder; VendorNo: Code[20]; Amount: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderDataItem: Text;
    begin
        // <DataItem name="Purchase Header">VERSION(1) SORTING(Document Type,No.) WHERE(Buy-from Vendor No.=FILTER(10000),Document Date=FILTER(28-01-16),Amount=FILTER(&gt;1.000))</DataItem>
        PurchaseHeaderDataItem := FilterPageBuilder.AddTable(PurchaseHeader.TableCaption(), DATABASE::"Purchase Header");
        FilterPageBuilder.ADdField(PurchaseHeaderDataItem, PurchaseHeader."Buy-from Vendor No.", VendorNo);
        FilterPageBuilder.ADdField(PurchaseHeaderDataItem, PurchaseHeader."Due Date", Format(WorkDate()));
        FilterPageBuilder.ADdField(PurchaseHeaderDataItem, PurchaseHeader.Amount, StrSubstNo('>%1', Amount));
    end;

    local procedure CreatePurchaseLineDataItem(var FilterPageBuilder: FilterPageBuilder; ItemNo: Code[20]; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLineDataItem: Text;
    begin
        // <DataItem name="Purchase Line">VERSION(1) SORTING(Document Type,Document No.,Line No.) WHERE(Type=FILTER(Item),No.=FILTER(1000),Unit Cost=FILTER(&gt;500))</DataItem>
        PurchaseLineDataItem := FilterPageBuilder.AddTable(PurchaseLine.TableCaption(), DATABASE::"Purchase Line");
        FilterPageBuilder.ADdField(PurchaseLineDataItem, PurchaseLine.Type, Format(PurchaseLine.Type::Item));
        FilterPageBuilder.ADdField(PurchaseLineDataItem, PurchaseLine."No.", ItemNo);
        FilterPageBuilder.ADdField(PurchaseLineDataItem, PurchaseLine."Direct Unit Cost", StrSubstNo('>%1', DirectUnitCost));
    end;

    local procedure CreateVendorDataItem(var FilterPageBuilder: FilterPageBuilder; VendorPostingGroup: Code[20]; VATBusPostingGroup: Code[20])
    var
        Vendor: Record Vendor;
        VendorDataItem: Text;
    begin
        // <DataItem name="Vendor">VERSION(1) SORTING(No.) WHERE(Vendor Posting Group=(DOMESTIC),VAT Bus. Posting Group=(NATIONAL))</DataItem>
        VendorDataItem := FilterPageBuilder.AddTable(Vendor.TableCaption(), DATABASE::Vendor);
        FilterPageBuilder.ADdField(VendorDataItem, Vendor."Vendor Posting Group", VendorPostingGroup);
        FilterPageBuilder.ADdField(VendorDataItem, Vendor."VAT Bus. Posting Group", VATBusPostingGroup);
    end;

    local procedure GenerateVendorLongFilter(): Text
    var
        Result: Text;
        Index: Integer;
    begin
        Result := LibraryPurchase.CreateVendorNo();
        for Index := 1 to 20 do
            Result += '|' + LibraryPurchase.CreateVendorNo();

        exit(Result);
    end;

    local procedure SaveAndLoadWorkflow(var WorkflowStep: Record "Workflow Step")
    var
        Workflow: Record Workflow;
        TempBlob: Codeunit "Temp Blob";
    begin
        Workflow.Get(WorkflowStep."Workflow Code");
        Workflow.Validate(Enabled, false);
        Workflow.Modify(true);
        Workflow.SetRecFilter();
        Workflow.ExportToBlob(TempBlob);

        Workflow.Delete(true);
        Workflow.ImportFromBlob(TempBlob);

        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.FindFirst();
    end;

    local procedure SetupEventConditions(var WorkflowStep: Record "Workflow Step"; Amount: Decimal; UnitOfMeasureCode: Code[10]; VendorFilter: Text)
    begin
        LibraryVariableStorage.Enqueue(Amount);
        LibraryVariableStorage.Enqueue(UnitOfMeasureCode);
        LibraryVariableStorage.Enqueue(VendorFilter);
        Commit();
        WorkflowStep.OpenEventConditions();
    end;

    local procedure VerifyDynamicRequestPageBlankParametersForPurchaseHeader(FilterPageBuilder: FilterPageBuilder)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Assert.AreEqual(Format(PurchaseHeaderBlankParametersTxt),
          FilterPageBuilder.GetView(PurchaseHeader.TableCaption()), StrSubstNo(FilterNotBlankErr, PurchaseHeader.TableCaption()));
        Assert.AreEqual('', FilterPageBuilder.GetView(PurchaseLine.TableCaption()),
          StrSubstNo(FilterNotBlankErr, PurchaseHeader.TableCaption()));
    end;

    local procedure VerifyDynamicRequestPageBlankParametersForPurchaseInvoice(FilterPageBuilder: FilterPageBuilder; EntityName: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        Assert.AreEqual(Format(PurchaseHeaderBlankParametersTxt),
          FilterPageBuilder.GetView(PurchaseHeader.TableCaption()), StrSubstNo(FilterNotBlankErr, PurchaseHeader.TableCaption()));
        Assert.AreEqual(Format(PurchaseLineBlankParametersTxt),
          FilterPageBuilder.GetView(PurchaseLine.TableCaption()), StrSubstNo(FilterNotBlankErr, PurchaseHeader.TableCaption()));
        Assert.AreEqual(Format(DynamicRequestPageBlankParametersTxt),
          RequestPageParametersHelper.GetViewFromDynamicRequestPage(FilterPageBuilder, EntityName, DATABASE::"Purchase Header"),
          StrSubstNo(FilterNotBlankErr, PurchaseHeader.TableCaption()));
    end;

    local procedure VerifyDynamicRequestPageParametersForPurchaseInvoice(FilterPageBuilder: FilterPageBuilder)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Assert.AreEqual(
          StrSubstNo(PurchaseHeaderParametersTxt, Format(WorkDate(), 0, 9), 100),
          FilterPageBuilder.GetView(PurchaseHeader.TableCaption()), FilterMismatchErr);
        Assert.AreEqual(
          Format(PurchaseLineParametersTxt), FilterPageBuilder.GetView(PurchaseLine.TableCaption()), FilterMismatchErr);
    end;

    local procedure EnableWorkflow("Code": Code[20])
    var
        Workflow: Record Workflow;
    begin
        Workflow.Get(Code);
        Workflow.Enabled := true;
        Workflow.Modify(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CancelWorkflowEventSimpleArgumentsRequestPage(var WorkflowEventSimpleArgs: TestRequestPage "Workflow Event Simple Args")
    begin
        WorkflowEventSimpleArgs.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OkayWorkflowEventSimpleArgumentsRequestPage(var WorkflowEventSimpleArgs: TestRequestPage "Workflow Event Simple Args")
    begin
        WorkflowEventSimpleArgs.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WorkflowEventSimpleArgumentsRequestPage(var WorkflowEventSimpleArgs: TestRequestPage "Workflow Event Simple Args")
    var
        PurchaseHeader: Record "Purchase Header";
        Amount: Variant;
        UnitOfMeasure: Variant;
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(Amount);
        LibraryVariableStorage.Dequeue(UnitOfMeasure);
        LibraryVariableStorage.Dequeue(VendorNo);

        WorkflowEventSimpleArgs."Purchase Header".SetFilter("Document Type", Format(PurchaseHeader."Document Type"::Invoice));
        WorkflowEventSimpleArgs."Purchase Header".SetFilter("Buy-from Vendor No.", VendorNo);
        WorkflowEventSimpleArgs."Purchase Line".SetFilter(Amount, StrSubstNo('>%1', Amount));
        WorkflowEventSimpleArgs."Purchase Line".SetFilter("Unit of Measure", UnitOfMeasure);

        WorkflowEventSimpleArgs.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WorkflowEventAdvancedArgumentsRequestPage(var WorkflowEventAdvancedArgs: TestRequestPage "Workflow Event Advanced Args")
    var
        PurchaseHeader: Record "Purchase Header";
        Amount: Variant;
        CurrencyCode: Variant;
        Description: Variant;
        DueDate: Variant;
        Quantity: Variant;
        UnitOfMeasure: Variant;
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DueDate);
        LibraryVariableStorage.Dequeue(CurrencyCode);
        LibraryVariableStorage.Dequeue(Description);
        LibraryVariableStorage.Dequeue(Quantity);

        WorkflowEventAdvancedArgs.DueDate.SetValue(DueDate);
        WorkflowEventAdvancedArgs.CurrencyCode.SetValue(CurrencyCode);
        WorkflowEventAdvancedArgs.Description.SetValue(Description);
        WorkflowEventAdvancedArgs.Quantity.SetValue(Quantity);

        LibraryVariableStorage.Dequeue(Amount);
        LibraryVariableStorage.Dequeue(UnitOfMeasure);
        LibraryVariableStorage.Dequeue(VendorNo);

        WorkflowEventAdvancedArgs."Purchase Header".SetFilter("Document Type", Format(PurchaseHeader."Document Type"::Invoice));
        WorkflowEventAdvancedArgs."Purchase Header".SetFilter("Buy-from Vendor No.", VendorNo);
        WorkflowEventAdvancedArgs."Purchase Line".SetFilter(Amount, StrSubstNo('>%1', Amount));
        WorkflowEventAdvancedArgs."Purchase Line".SetFilter("Unit of Measure", UnitOfMeasure);

        WorkflowEventAdvancedArgs.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DisplayWorkflowEventSimpleArgumentsRequestPage(var WorkflowEventSimpleArgs: TestRequestPage "Workflow Event Simple Args")
    var
        PurchaseHeader: Record "Purchase Header";
        Amount: Variant;
        UnitOfMeasure: Variant;
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(Amount);
        LibraryVariableStorage.Dequeue(UnitOfMeasure);
        LibraryVariableStorage.Dequeue(VendorNo);

        WorkflowEventSimpleArgs."Purchase Header".SetFilter("Document Type", Format(PurchaseHeader."Document Type"::Invoice));
        WorkflowEventSimpleArgs."Purchase Header".SetFilter("Buy-from Vendor No.", VendorNo);
        WorkflowEventSimpleArgs."Purchase Line".SetFilter(Amount, StrSubstNo('>%1', Amount));
        WorkflowEventSimpleArgs."Purchase Line".SetFilter("Unit of Measure", UnitOfMeasure);

        WorkflowEventSimpleArgs.OK().Invoke();
    end;
}

