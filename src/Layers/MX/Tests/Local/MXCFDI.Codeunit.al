codeunit 144001 "MX CFDI"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CFDI]
    end;

    var
        GLSetup: Record "General Ledger Setup";
        NameValueBuffer: Record "Name/Value Buffer";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryCFDI: Codeunit "Library - CFDI";
        SATUtilities: Codeunit "SAT Utilities";
        MXCFDI: Codeunit "MX CFDI";
        isInitialized: Boolean;
        ValueErr: Label 'Value in %1 field is incorrect.';
        ActionOption: Option "Request Stamp",Send,"Request Stamp and Send",Cancel;
        ResponseOption: Option Success,Error;
        DateTimeStampedTxt: Label '2011-11-08T07:45:56';
        FiscalInvoiceNumberPACTxt: Label '9CDBDABD-9399-4DA1-8409-D1B70C5BA4DD';
        OptionNotSupportedErr: Label 'Option not supported by test function.';
        ErrorCodeTxt: Label '302';
        ErrorDescriptionTxt: Label 'Sello del Emisor No Valido';
        StatusOption: Option " ","Stamp Received",Sent,Canceled,"Stamp Request Error","Cancel Error","Cancel In Progress";
        DigitalStampTxt: Label 'WDTveFcG+ANYGdjrNrDcpYGdz4p0XsH5C0UTsqcMM/dSe4MGGnsacrJ75DAT5B5KqZWSefkGeg/sG7i6K3+lZTEuxje+rBDAp/4fMfYeL2TTMLpkU6Oy1zl/N6ywt38Z2+WTwcBIuIkEY54e+mW+zkyJLAxkeDGJHAwEBdf2nu0=';
        MissingSalesPaymentMethodCodeExceptionErr: Label 'Payment Method Code must have a value in Sales Header';
        MissingServicePaymentMethodCodeExceptionErr: Label 'Payment Method Code must have a value in Service Header';
        MissingServiceUnitOfMeasureExcErr: Label 'Unit of Measure Code must have a value in Service Line';
        IncorrectSchemaVersionErr: Label 'Incorrect schema version in the original string %1.';
        IncorrectOriginalStrValueErr: Label 'Incorrect %1 in the original string %2.';
        ConceptoUnidadFieldTxt: Label 'ConceptoUnidad';
        MetodoDePagoFieldTxt: Label 'MetodoDePago';
        FormaDePagoFieldTxt: Label 'FormaDePago';
        RegimenFieldTxt: Label 'Regimen';
        RFCNoFieldTxt: Label 'RFC No.';
        CFDIPurposeFieldTxt: Label 'CFDI Purpose';
        CFDIRelationFieldTxt: Label 'CFDI Relation';
        IfEmptyErr: Label '''%1'' in ''%2'' must not be blank.', Comment = '%1=caption of a field, %2=key of record';
        PACDetailDoesNotExistErr: Label 'Record %1 does not exist for %2, %3, %4.';
        NoElectronicStampErr: Label 'There is no electronic stamp';
        NoElectronicDocumentSentErr: Label 'There is no electronic Document sent yet';
        NamespaceCFD4Txt: Label 'http://www.sat.gob.mx/cfd/4';
        SchemaLocationCFD4Txt: Label 'http://www.sat.gob.mx/sitio_internet/cfd/4/cfdv40.xsd';
        CertificateNotExistErr: Label 'The Isolated Certificate does not exist. Identification fields and values: Code=''%1''', Comment = '%1 - Isolated Certificate code';
        CancelOption: Option ,CancelRequest,GetResponse,MarkAsCanceled,ResetCancelRequest;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceRequestStamp()
    begin
        RequestStampTest(DATABASE::"Sales Invoice Header", ResponseOption::Success, ActionOption::"Request Stamp");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoRequestStamp()
    begin
        RequestStampTest(DATABASE::"Sales Cr.Memo Header", ResponseOption::Success, ActionOption::"Request Stamp");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceRequestStamp()
    begin
        RequestStampTest(DATABASE::"Service Invoice Header", ResponseOption::Success, ActionOption::"Request Stamp");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoRequestStamp()
    begin
        RequestStampTest(DATABASE::"Service Cr.Memo Header", ResponseOption::Success, ActionOption::"Request Stamp");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceRequestStampError()
    begin
        RequestStampTest(DATABASE::"Sales Invoice Header", ResponseOption::Error, ActionOption::"Request Stamp");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoRequestStampError()
    begin
        RequestStampTest(DATABASE::"Sales Cr.Memo Header", ResponseOption::Error, ActionOption::"Request Stamp");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceRequestStampErro()
    begin
        RequestStampTest(DATABASE::"Service Invoice Header", ResponseOption::Error, ActionOption::"Request Stamp");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoRequestStampError()
    begin
        RequestStampTest(DATABASE::"Service Cr.Memo Header", ResponseOption::Error, ActionOption::"Request Stamp");
    end;

    local procedure RequestStampTest(TableNo: Integer; Response: Option; "Action": Option)
    var
        PostedDocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        PostedDocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT());

        // Exercise
        RequestStamp(TableNo, PostedDocumentNo, Response, Action);

        // Verify
        if Response = ResponseOption::Success then
            Verify(TableNo, PostedDocumentNo, StatusOption::"Stamp Received", 0)
        else
            Verify(TableNo, PostedDocumentNo, StatusOption::"Stamp Request Error", 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceSend()
    begin
        SendTest(DATABASE::"Sales Invoice Header");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoSend()
    begin
        SendTest(DATABASE::"Sales Cr.Memo Header");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceSend()
    begin
        SendTest(DATABASE::"Service Invoice Header");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoSend()
    begin
        SendTest(DATABASE::"Service Cr.Memo Header");
    end;

    local procedure SendTest(TableNo: Integer)
    var
        PostedDocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        PostedDocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT());

        // Exercise
        RequestStamp(TableNo, PostedDocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        RequestStamp(TableNo, PostedDocumentNo, ResponseOption::Success, ActionOption::Send);

        // Verify
        Verify(TableNo, PostedDocumentNo, StatusOption::Sent, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceSignAndSend()
    begin
        SignAndSendTest(DATABASE::"Sales Invoice Header", ResponseOption::Success);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoSignAndSend()
    begin
        SignAndSendTest(DATABASE::"Sales Cr.Memo Header", ResponseOption::Success);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceSignAndSend()
    begin
        SignAndSendTest(DATABASE::"Service Invoice Header", ResponseOption::Success);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoSignAndSend()
    begin
        SignAndSendTest(DATABASE::"Service Cr.Memo Header", ResponseOption::Success);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceSignAndSendError()
    begin
        SignAndSendTest(DATABASE::"Sales Invoice Header", ResponseOption::Error);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoSignAndSendError()
    begin
        SignAndSendTest(DATABASE::"Sales Cr.Memo Header", ResponseOption::Error);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceSignAndSendError()
    begin
        SignAndSendTest(DATABASE::"Service Invoice Header", ResponseOption::Error);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoSignAndSendError()
    begin
        SignAndSendTest(DATABASE::"Service Cr.Memo Header", ResponseOption::Error);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceBlankPaymentMethodCodeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        PostSalesDocBlankPaymentMethodCode(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCreditMemoBlankPaymentMethodCodeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        PostSalesDocBlankPaymentMethodCode(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceBlankPaymentMethodCodeError()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        PostServiceDocBlankPaymentMethodCode(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceCreditMemoBlankPaymentMethodCodeError()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        PostServiceDocBlankPaymentMethodCode(ServiceHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceBlankUnitOfMeasureCodeError()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        PostServiceDocBlankUnitOfMeasureCode(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceCreditMemoBlankUnitOfMeasureCodeError()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        PostServiceDocBlankPaymentMethodCode(ServiceHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendStampSalesCreditMemoRequestBlankTaxSchemeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        SendSalesStampRequestBlankTaxSchemeError(SalesHeader."Document Type"::"Credit Memo", DATABASE::"Sales Cr.Memo Header")
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendStampSalesInvoiceRequestBlankTaxSchemeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        SendSalesStampRequestBlankTaxSchemeError(SalesHeader."Document Type"::Invoice, DATABASE::"Sales Invoice Header")
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendStampServiceCreditMemoRequestBlankTaxSchemeError()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        SendServiceStampRequestBlankTaxSchemeError(ServiceHeader."Document Type"::"Credit Memo", DATABASE::"Service Cr.Memo Header")
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendStampServiceInvoiceRequestBlankTaxSchemeError()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        SendServiceStampRequestBlankTaxSchemeError(ServiceHeader."Document Type"::Invoice, DATABASE::"Service Invoice Header")
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendStampSalesCreditMemoRequestBlankCountryCodeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        SendSalesStampRequestBlankCountryCodeError(SalesHeader."Document Type"::"Credit Memo", DATABASE::"Sales Cr.Memo Header")
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendStampSalesInvoiceRequestBlankCountryCodeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        SendSalesStampRequestBlankCountryCodeError(SalesHeader."Document Type"::Invoice, DATABASE::"Sales Invoice Header")
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendStampServiceCreditMemoRequestBlankCountryCodeError()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        SendServiceStampRequestBlankCountryCodeError(ServiceHeader."Document Type"::"Credit Memo", DATABASE::"Service Cr.Memo Header")
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendStampServiceInvoiceRequestBlankCountryCodeError()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        SendServiceStampRequestBlankCountryCodeError(ServiceHeader."Document Type"::Invoice, DATABASE::"Service Invoice Header")
    end;

    local procedure SignAndSendTest(TableNo: Integer; Response: Option)
    var
        PostedDocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        PostedDocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT());

        // Exercise
        if Response = ResponseOption::Success then
            RequestStamp(TableNo, PostedDocumentNo, Response, ActionOption::"Request Stamp and Send")
        else
            asserterror RequestStamp(TableNo, PostedDocumentNo, Response, ActionOption::"Request Stamp and Send");

        // Verify
        if Response = ResponseOption::Success then
            Verify(TableNo, PostedDocumentNo, StatusOption::Sent, 0)
        else
            Verify(TableNo, PostedDocumentNo, StatusOption::"Stamp Request Error", 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceResend()
    begin
        ResendTest(DATABASE::"Sales Invoice Header");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoResend()
    begin
        ResendTest(DATABASE::"Sales Cr.Memo Header");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceResend()
    begin
        ResendTest(DATABASE::"Service Invoice Header");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoResend()
    begin
        ResendTest(DATABASE::"Service Cr.Memo Header");
    end;

    local procedure ResendTest(TableNo: Integer)
    var
        PostedDocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        PostedDocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT());

        // Exercise
        RequestStamp(TableNo, PostedDocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        RequestStamp(TableNo, PostedDocumentNo, ResponseOption::Success, ActionOption::Send);
        LibraryVariableStorage.Enqueue(true);
        RequestStamp(TableNo, PostedDocumentNo, ResponseOption::Success, ActionOption::Send);

        // Verify
        Verify(TableNo, PostedDocumentNo, StatusOption::Sent, 1)
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceCancel()
    begin
        // [SCENARIO 422335] Cancel Sales Invoice
        CancelTest(DATABASE::"Sales Invoice Header", ResponseOption::Success);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoCancel()
    begin
        // [SCENARIO 422335] Cancel Sales Credit Memo
        CancelTest(DATABASE::"Sales Cr.Memo Header", ResponseOption::Success);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceCancel()
    begin
        // [SCENARIO 422335] Cancel Service Invoice
        CancelTest(DATABASE::"Service Invoice Header", ResponseOption::Success);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoCancel()
    begin
        // [SCENARIO 422335] Cancel Service Credit Memo
        CancelTest(DATABASE::"Service Cr.Memo Header", ResponseOption::Success);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesShipmentCancel()
    begin
        // [SCENARIO 422335] Cancel Sales Shipment
        CancelTest(DATABASE::"Sales Shipment Header", ResponseOption::Success);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TransferShipmentCancel()
    begin
        // [SCENARIO 422335] Cancel Transfer Shipment
        CancelTest(DATABASE::"Transfer Shipment Header", ResponseOption::Success);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CustomerPaymentCancel()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentNo: Code[20];
    begin
        // [SCENARIO 422335] Cancel customer payment
        Initialize();

        // [GIVEN] Payment with 'Stamp Received' status
        PaymentNo := CreatePostPayment(CreateCustomer(), '', -LibraryRandom.RandIntInRange(1000, 2000), '');
        UpdateDocumentFieldValue(
          DATABASE::"Cust. Ledger Entry", CustLedgerEntry.FieldNo("Document No."), PaymentNo,
          CustLedgerEntry.FieldNo("Electronic Document Status"), CustLedgerEntry."Electronic Document Status"::"Stamp Received");

        // [WHEN] Cancel customer payment
        Cancel(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success);

        // [THEN] Payment has been canceled with MotivoCancelacion
        Verify(DATABASE::"Cust. Ledger Entry", PaymentNo, StatusOption::"Cancel In Progress", 0);

        CancelTearDown(DATABASE::"Cust. Ledger Entry", PaymentNo);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceCancelError()
    begin
        CancelTest(DATABASE::"Sales Invoice Header", ResponseOption::Error);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoCancelError()
    begin
        CancelTest(DATABASE::"Sales Cr.Memo Header", ResponseOption::Error);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceCancelError()
    begin
        CancelTest(DATABASE::"Service Invoice Header", ResponseOption::Error);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoCancelError()
    begin
        CancelTest(DATABASE::"Service Cr.Memo Header", ResponseOption::Error);
    end;

    local procedure CancelTest(TableNo: Integer; Response: Option)
    var
        PostedDocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        PostedDocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT());

        // Exercise
        RequestStamp(TableNo, PostedDocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        Cancel(TableNo, PostedDocumentNo, Response);

        // Verify
        if Response = ResponseOption::Success then
            Verify(TableNo, PostedDocumentNo, StatusOption::"Cancel In Progress", 0)
        else
            Verify(TableNo, PostedDocumentNo, StatusOption::"Cancel Error", 0);

        CancelTearDown(TableNo, PostedDocumentNo);
    end;

    [Test]
    [HandlerFunctions('CancelRequestMenuHandler')]
    [Scope('OnPrem')]
    procedure CancelGetResponseInProgress()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
    begin
        // [FEATURE] [Cancel]
        // [SCENARIO 430138] Process response 'EnProceso' during the cancellation request
        Initialize();

        // [GIVEN] Sales Invoice with Cancel In Progress status
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT()));
        UpdateSalesInvoiceCancellation(SalesInvoiceHeader);

        // [WHEN] Request returns status 'EnProceso'
        MockCancelResponseInProgress(TempBlob);
        RecordRef.GetTable(SalesInvoiceHeader);
        TempBlob.ToRecordRef(RecordRef, SalesInvoiceHeader.FieldNo("Signed Document XML"));
        RecordRef.SetTable(SalesInvoiceHeader);
        SalesInvoiceHeader.Modify(true);
        LibraryVariableStorage.Enqueue(CancelOption::GetResponse);
        SalesInvoiceHeader.CancelEDocument();

        // [THEN] 'Electronic Document Status' set to "Cancel In Progress"
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.TestField("Electronic Document Status", SalesInvoiceHeader."Electronic Document Status"::"Cancel In Progress");
        SalesInvoiceHeader.TestField("Error Description");
        SalesInvoiceHeader.TestField("Date/Time Canceled", ''); // (TFS 498662)

        CancelTearDown(DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('CancelRequestMenuHandler')]
    [Scope('OnPrem')]
    procedure CancelGetResponseRejected()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
    begin
        // [FEATURE] [Cancel]
        // [SCENARIO 430138] Process response 'Rechazado' during the cancellation request
        Initialize();

        // [GIVEN] Sales Invoice with Cancel In Progress status
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT()));
        UpdateSalesInvoiceCancellation(SalesInvoiceHeader);

        // [WHEN] Request returns status 'Rechazado'
        MockCancelResponseRejected(TempBlob);
        RecordRef.GetTable(SalesInvoiceHeader);
        TempBlob.ToRecordRef(RecordRef, SalesInvoiceHeader.FieldNo("Signed Document XML"));
        RecordRef.SetTable(SalesInvoiceHeader);
        SalesInvoiceHeader.Modify(true);
        LibraryVariableStorage.Enqueue(CancelOption::GetResponse);
        SalesInvoiceHeader.CancelEDocument();

        // [THEN] 'Electronic Document Status' set to "Cancel Error"
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.TestField("Electronic Document Status", SalesInvoiceHeader."Electronic Document Status"::"Cancel Error");
        SalesInvoiceHeader.TestField("Error Description");
        SalesInvoiceHeader.TestField("Date/Time Canceled", ''); // (TFS 498662)

        CancelTearDown(DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('CancelRequestMenuHandler')]
    [Scope('OnPrem')]
    procedure CancelGetResponseCancelled()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
    begin
        // [FEATURE] [Cancel]
        // [SCENARIO 430138] Process response 'Cancelado' during the cancellation request
        Initialize();

        // [GIVEN] Sales Invoice with Cancel In Progress status
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT()));
        UpdateSalesInvoiceCancellation(SalesInvoiceHeader);

        // [WHEN] Request returns status 'Cancelado'
        MockCancelResponseCanceled(TempBlob);
        RecordRef.GetTable(SalesInvoiceHeader);
        TempBlob.ToRecordRef(RecordRef, SalesInvoiceHeader.FieldNo("Signed Document XML"));
        RecordRef.SetTable(SalesInvoiceHeader);
        SalesInvoiceHeader.Modify(true);
        LibraryVariableStorage.Enqueue(CancelOption::GetResponse);
        SalesInvoiceHeader.CancelEDocument();

        // [THEN] 'Electronic Document Status' set to "Cancel Error", 'Error Description' = '', "Date/Time Canceled" is updated
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.TestField("Electronic Document Status", SalesInvoiceHeader."Electronic Document Status"::Canceled);
        SalesInvoiceHeader.TestField("Error Description", '');
        SalesInvoiceHeader.TestField("Date/Time Canceled"); // The value assigned from xml. (TFS 498662)
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CancelRequestMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CancelDocumentManual()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Cancel]
        // [SCENARIO 430138] Cancel invoice manually
        Initialize();

        // [GIVEN] Sales Invoice with Cancel In Progress status
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT()));
        UpdateSalesInvoiceCancellation(SalesInvoiceHeader);

        // [WHEN] Run Cancel document with Mark as Canceled option
        LibraryVariableStorage.Enqueue(CancelOption::MarkAsCanceled);
        LibraryVariableStorage.Enqueue(true);
        SalesInvoiceHeader.CancelEDocument();

        // [THEN] 'Electronic Document Status' set to "Cancel Error", 'Date/Time Canceled' is assigned, 'Marked as Canceled' = 'Yes'
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.TestField("Electronic Document Status", SalesInvoiceHeader."Electronic Document Status"::Canceled);
        SalesInvoiceHeader.TestField("Date/Time Canceled");
        SalesInvoiceHeader.TestField("Marked as Canceled", true);
    end;

    [Test]
    [HandlerFunctions('CancelRequestMenuHandler,ConfirmHandler')]
    procedure CancelPaymentManually()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentNo: Code[20];
    begin
        // [SCENARIO 573377] Cancel customer payment manually
        Initialize();
        // [GIVEN] Sales Invoice
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT()));
        SalesInvoiceHeader.CalcFields("Amount Including VAT");

        // [GIVEN] A payment for this sales invoice
        PaymentNo := CreatePostPayment(SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -SalesInvoiceHeader."Amount Including VAT", '');
        UpdateDocumentFieldValue(
          DATABASE::"Cust. Ledger Entry", CustLedgerEntry.FieldNo("Document No."), PaymentNo,
          CustLedgerEntry.FieldNo("Electronic Document Status"), CustLedgerEntry."Electronic Document Status"::"Cancel In Progress");

        // [WHEN] Runing Cancel document with Cancel Request option
        LibraryVariableStorage.Enqueue(CancelOption::MarkAsCanceled);
        LibraryVariableStorage.Enqueue(true);
        Cancel(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success);

        // [THEN] 'Electronic Document Status' set to "Canceled"
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        Assert.AreEqual(CustLedgerEntry."Electronic Document Status", CustLedgerEntry."Electronic Document Status"::Canceled, 'Status should be Canceled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelRequestStatusBatch()
    var
        SalesInvoiceHeader1: Record "Sales Invoice Header";
        SalesInvoiceHeader2: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
    begin
        // [FEATURE] [Cancel]
        // [SCENARIO 430138] Run request cancellation batch for two invoices
        Initialize();

        SalesInvoiceHeader1.SetFilter("CFDI Cancellation ID", '<>%1', '');
        SalesInvoiceHeader1.ModifyAll("Electronic Document Status", SalesInvoiceHeader1."Electronic Document Status"::Canceled);
        SalesInvoiceHeader1.SetRange("CFDI Cancellation ID");

        // [GIVEN] Two sales invoices with Cancel In Progress status
        SalesInvoiceHeader1.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT()));
        UpdateSalesInvoiceCancellation(SalesInvoiceHeader1);
        MockCancelResponseCanceled(TempBlob);
        RecordRef.GetTable(SalesInvoiceHeader1);
        TempBlob.ToRecordRef(RecordRef, SalesInvoiceHeader1.FieldNo("Signed Document XML"));
        RecordRef.SetTable(SalesInvoiceHeader1);
        SalesInvoiceHeader1.Modify(true);

        SalesInvoiceHeader2.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT()));
        UpdateSalesInvoiceCancellation(SalesInvoiceHeader2);
        Clear(TempBlob);
        MockCancelResponseCanceled(TempBlob);
        RecordRef.GetTable(SalesInvoiceHeader2);
        TempBlob.ToRecordRef(RecordRef, SalesInvoiceHeader2.FieldNo("Signed Document XML"));
        RecordRef.SetTable(SalesInvoiceHeader2);
        SalesInvoiceHeader2.Modify(true);

        // [WHEN] Run codeunit for cancel request batch processing
        CODEUNIT.Run(CODEUNIT::"E-Invoice Cancel Request Batch");

        // [THEN] 'Electronic Document Status' set to "Canceled" for both invoices
        SalesInvoiceHeader1.Find();
        SalesInvoiceHeader1.TestField("Electronic Document Status", SalesInvoiceHeader1."Electronic Document Status"::Canceled);
        SalesInvoiceHeader1.TestField("Error Description", '');
        SalesInvoiceHeader1.TestField("Date/Time Canceled");
        SalesInvoiceHeader2.Find();
        SalesInvoiceHeader2.TestField("Electronic Document Status", SalesInvoiceHeader2."Electronic Document Status"::Canceled);
        SalesInvoiceHeader2.TestField("Error Description", '');
        SalesInvoiceHeader2.TestField("Date/Time Canceled");
    end;

    [Test]
    [HandlerFunctions('CancelRequestMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CancelDocumentWithTimeExpiration()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Cancel]
        // [SCENARIO 470702] Cancel invoice with time expiration
        Initialize();
        UpdateGLSetupTimeExpiration();

        // [GIVEN] Sales Invoice has "Stamp Received" status and a stamp received 12 hours ago
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT()));
        SalesInvoiceHeader."Electronic Document Status" := SalesInvoiceHeader."Electronic Document Status"::"Stamp Received";
        SalesInvoiceHeader."Date/Time Stamp Received" := GetDateTimeInDaysAgo(0.5);
        SalesInvoiceHeader."CFDI Cancellation Reason Code" := FindCancellationReasonCode(false);
        SalesInvoiceHeader.Modify();
        // do not mock cancel request for the invoice

        // [WHEN] Run Cancel document
        LibraryVariableStorage.Enqueue(CancelOption::CancelRequest);
        LibraryVariableStorage.Enqueue(true);
        SalesInvoiceHeader.CancelEDocument();

        // [THEN] 'Electronic Document Status' set to "Canceled", 'Marked as Canceled' = 'false'
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.TestField("Electronic Document Status", SalesInvoiceHeader."Electronic Document Status"::Canceled);
        SalesInvoiceHeader.TestField("Marked as Canceled", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelRequestStatusBatchWithTimeExpiration()
    var
        SalesInvoiceHeader1: Record "Sales Invoice Header";
        SalesInvoiceHeader2: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
    begin
        // [FEATURE] [Cancel]
        // [SCENARIO 470702] Run request cancellation batch for two invoices with time expiration
        Initialize();
        UpdateGLSetupTimeExpiration();

        SalesInvoiceHeader1.SetFilter("CFDI Cancellation ID", '<>%1', '');
        SalesInvoiceHeader1.ModifyAll("Electronic Document Status", SalesInvoiceHeader1."Electronic Document Status"::Canceled);
        SalesInvoiceHeader1.SetRange("CFDI Cancellation ID");

        // [GIVEN] Two sales invoices with Cancel In Progress status, 4 days stamp and 2 days stamp
        SalesInvoiceHeader1.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT()));
        UpdateSalesInvoiceCancellation(SalesInvoiceHeader1);
        SalesInvoiceHeader1."Date/Time Cancel Sent" := GetDateTimeInDaysAgo(4);
        SalesInvoiceHeader1.Modify();
        // do not mock response for the invoice

        SalesInvoiceHeader2.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT()));
        UpdateSalesInvoiceCancellation(SalesInvoiceHeader2);
        SalesInvoiceHeader2."Date/Time Cancel Sent" := GetDateTimeInDaysAgo(2);
        SalesInvoiceHeader2.Modify();
        MockCancelResponseCanceled(TempBlob);
        RecordRef.GetTable(SalesInvoiceHeader2);
        TempBlob.ToRecordRef(RecordRef, SalesInvoiceHeader2.FieldNo("Signed Document XML"));
        RecordRef.SetTable(SalesInvoiceHeader2);
        SalesInvoiceHeader2.Modify(true);

        // [WHEN] Run codeunit for cancel request batch processing
        CODEUNIT.Run(CODEUNIT::"E-Invoice Cancel Request Batch");

        // [THEN] 'Electronic Document Status' set to "Canceled" for first invoice without sending request
        // [THEN] 'Electronic Document Status' set to "Canceled" for second invoice using request
        SalesInvoiceHeader1.Find();
        SalesInvoiceHeader1.TestField("Electronic Document Status", SalesInvoiceHeader1."Electronic Document Status"::Canceled);
        SalesInvoiceHeader1.TestField("Date/Time Canceled");
        SalesInvoiceHeader2.Find();
        SalesInvoiceHeader2.TestField("Electronic Document Status", SalesInvoiceHeader2."Electronic Document Status"::Canceled);
        SalesInvoiceHeader2.TestField("Date/Time Canceled");
    end;

    [Test]
    [HandlerFunctions('CancelRequestMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ResetCancellationRequest()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Cancel]
        // [SCENARIO 496166] Rest cancellation request
        Initialize();

        // [GIVEN] Sales Invoice with Cancel In Progress status
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT()));
        UpdateSalesInvoiceCancellation(SalesInvoiceHeader);

        // [WHEN] Run Cancel document with Reset Cancellation Request option
        LibraryVariableStorage.Enqueue(CancelOption::ResetCancelRequest);
        LibraryVariableStorage.Enqueue(true);
        SalesInvoiceHeader.CancelEDocument();

        // [THEN] 'Electronic Document Status' set to "Cancel Error"
        // [THEN] 'CFDI Cancellation ID', 'CFDI Cancellation Reason Code', 'Error Description' fields keep their values
        // [THEN] 'Date/Time Canceled', 'Date/Time Cancel Sent' fields are blank
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.TestField("Electronic Document Status", SalesInvoiceHeader."Electronic Document Status"::"Cancel Error");
        SalesInvoiceHeader.TestField("CFDI Cancellation ID");
        SalesInvoiceHeader.TestField("CFDI Cancellation Reason Code");
        SalesInvoiceHeader.TestField("Error Description");
        SalesInvoiceHeader.TestField("Date/Time Canceled", '');
        SalesInvoiceHeader.TestField("Date/Time Cancel Sent", 0DT);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoicePostAndPrint()
    begin
        PostAndPrintTest(DATABASE::"Sales Invoice Header");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesCrMemoReportHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoPostAndPrint()
    begin
        PostAndPrintTest(DATABASE::"Sales Cr.Memo Header");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ServiceInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoicePostAndPrint()
    begin
        PostAndPrintTest(DATABASE::"Service Invoice Header");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ServiceCrMemoReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoPostAndPrint()
    begin
        PostAndPrintTest(DATABASE::"Service Cr.Memo Header");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoicePostAndPrintCFDIDisabled()
    begin
        PostAndPrintCFDIDisabledTest(DATABASE::"Sales Invoice Header");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesCrMemoReportHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoPostAndPrintCFDIDisabled()
    begin
        PostAndPrintCFDIDisabledTest(DATABASE::"Sales Cr.Memo Header");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ServiceInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoicePostAndPrintCFDIDisabled()
    begin
        PostAndPrintCFDIDisabledTest(DATABASE::"Service Invoice Header");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ServiceCrMemoReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoPostAndPrintCFDIDisabled()
    begin
        PostAndPrintCFDIDisabledTest(DATABASE::"Service Cr.Memo Header");
    end;

    local procedure PostAndPrintTest(TableNo: Integer)
    var
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        DocumentNo := CreateDoc(TableNo, CreatePaymentMethodForSAT());

        // Exercise
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        PostAndPrint(TableNo, DocumentNo);

        // Verify - that the right number of confirm handlers was executed
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure PostAndPrintCFDIDisabledTest(TableNo: Integer)
    var
        GLSetup: Record "General Ledger Setup";
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        GLSetup.Get();
        GLSetup.Validate("PAC Environment", GLSetup."PAC Environment"::Disabled);
        GLSetup.Modify(true);
        DocumentNo := CreateDoc(TableNo, '');

        // Exercise
        LibraryVariableStorage.Enqueue(true);
        PostAndPrint(TableNo, DocumentNo);

        // Verify - that the right number of confirm handlers was executed
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvOriginalStrMandatoryFields()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        OriginalStringMandatoryFields(DATABASE::"Sales Invoice Header", DATABASE::"Sales Invoice Line",
          SalesInvoiceHeader.FieldNo("No."), SalesInvoiceHeader.FieldNo("Sell-to Customer No."),
          SalesInvoiceHeader.FieldNo("CFDI Purpose"), SalesInvoiceHeader.FieldNo("CFDI Relation"),
          SalesInvoiceHeader.FieldNo("Payment Method Code"), SalesInvoiceHeader.FieldNo("Payment Terms Code"),
          SalesInvoiceLine.FieldNo("Unit of Measure Code"), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoOriginalStrMandatoryFields()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        OriginalStringMandatoryFields(DATABASE::"Sales Cr.Memo Header", DATABASE::"Sales Cr.Memo Line",
          SalesCrMemoHeader.FieldNo("No."), SalesCrMemoHeader.FieldNo("Sell-to Customer No."),
          SalesCrMemoHeader.FieldNo("CFDI Purpose"), SalesCrMemoHeader.FieldNo("CFDI Relation"),
          SalesCrMemoHeader.FieldNo("Payment Method Code"), SalesCrMemoHeader.FieldNo("Payment Terms Code"),
          SalesCrMemoLine.FieldNo("Unit of Measure Code"), 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvOriginalStrMandatoryFields()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        OriginalStringMandatoryFields(DATABASE::"Service Invoice Header", DATABASE::"Service Invoice Line",
          ServiceInvoiceHeader.FieldNo("No."), ServiceInvoiceHeader.FieldNo("Customer No."),
          ServiceInvoiceHeader.FieldNo("CFDI Purpose"), ServiceInvoiceHeader.FieldNo("CFDI Relation"),
          ServiceInvoiceHeader.FieldNo("Payment Method Code"), ServiceInvoiceHeader.FieldNo("Payment Terms Code"),
          ServiceInvoiceLine.FieldNo("Unit of Measure Code"), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoOriginalStrMandatoryFields()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        OriginalStringMandatoryFields(DATABASE::"Service Cr.Memo Header", DATABASE::"Service Cr.Memo Line",
          ServiceCrMemoHeader.FieldNo("No."), ServiceCrMemoHeader.FieldNo("Customer No."),
          ServiceCrMemoHeader.FieldNo("CFDI Purpose"), ServiceCrMemoHeader.FieldNo("CFDI Relation"),
          ServiceCrMemoHeader.FieldNo("Payment Method Code"), ServiceCrMemoHeader.FieldNo("Payment Terms Code"),
          ServiceCrMemoLine.FieldNo("Unit of Measure Code"), 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvPaymentTermsNoDisc()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize();

        // Exercise
        CreateBasicSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerNoDiscount());

        // Verify
        SalesHeader.TestField("Payment Method Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoPaymentTermsNoDisc()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize();

        // Exercise
        CreateBasicSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomerNoDiscount());

        // Verify
        SalesHeader.TestField("Payment Method Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvPaymentTermsNoDisc()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup
        Initialize();

        // Exercise
        CreateBasicServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomerNoDiscount());

        // Verify
        ServiceHeader.TestField("Payment Method Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoPaymentTermsNoDisc()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup
        Initialize();

        // Exercise
        CreateBasicServiceDocument(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", CreateCustomerNoDiscount());

        // Verify
        ServiceHeader.TestField("Payment Method Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoPaymentTermsNoDiscError()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        // Setup
        CreateBasicSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomerNoDiscount());

        // Exercise
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption("Payment Method Code"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoPaymentTermsNoDiscError()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Setup
        CreateBasicServiceDocument(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", CreateCustomerNoDiscount());

        // Exercise
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Verify
        Assert.ExpectedTestFieldError(ServiceHeader.FieldCaption("Payment Method Code"), '');
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPayment()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        OriginalStr: Text;
        FileName: Text;
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 308161] Request stamp for full payment of sales invoice
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Amount Including VAT" = 1000 in local currency
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT()));
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        UpdateCustomerSATPaymentFields(SalesInvoiceHeader."Sell-to Customer No.");

        // [GIVEN] Payment with amount of 1000 is applied to the invoice, Payment Terms set to "PT", Payment Method with '03' SAT Code
        PaymentNo :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -SalesInvoiceHeader."Amount Including VAT", '');
        SalesInvoiceHeader."Payment Terms Code" := CreatePaymentTermsForSAT();
        SalesInvoiceHeader.Modify();
        // [GIVEN] Customer has Payment Method with '99' SAT Code
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        Customer.Validate("Payment Method Code", CreatePaymentMethodForSAT());
        Customer.Modify(true);

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] 'Complemento' node created with attribute 'MonedaP' = 'MXN'
        // [THEN] Invoice's amount is exported to attribute 'ImpSaldoAnt' = 1000
        InitXMLReaderForPagos20(FileName);
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago', 'MonedaP', 'MXN');
        // [THEN] 'Concepto' node has attributes 'ValorUnitario' = 0, 'Importe' = 0 (TFS 329513)
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Conceptos/cfdi:Concepto', 'ValorUnitario', '0');
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Conceptos/cfdi:Concepto', 'Importe', '0');
        // [THEN] 'DoctoRelacionado' node has attribute 'NumParcialidad' (partial payment number) = '1' (TFS 363806)
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:DoctoRelacionado', 'NumParcialidad', '1');
        // [THEN] 'Complemento' node has attribute 'FormaDePagoP' = '03' (TFS 375439)
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago', 'FormaDePagoP',
          SATUtilities.GetSATPaymentMethod(CustLedgerEntry."Payment Method Code"));
        // [THEN] 'Complemento' node has attribute 'FechaPago' = '2023-01-01T12:00:00' (TFS 472400)
        // LibraryXPathXMLReader.VerifyAttributeValue( (TFS 522707)
        //  'cfdi:Complemento/pago20:Pagos/pago20:Pago', 'FechaPago',
        //  FormatDateTime(CustLedgerEntry."Posting Date", 120000T));

        // [THEN] String for digital stamp has 'ValorUnitario' = 0, 'Importe' = 0  (TFS 329513)
        // [THEN] Original stamp string has NumParcialidad (partial payment number) = '1' (TFS 363806)
        // [THEN] String for digital stamp has 'FormaDePagoP' = '03' (TFS 375439)
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);
        Assert.AreEqual('0', SelectStr(23, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'ValorUnitario', OriginalStr));
        Assert.AreEqual('0', SelectStr(24, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Importe', OriginalStr));
        Assert.AreEqual('1', SelectStr(36, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'NumParcialidad', OriginalStr));
        Assert.AreEqual(
          SATUtilities.GetSATPaymentMethod(CustLedgerEntry."Payment Method Code"),
          SelectStr(29, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'FormaDePagoP', OriginalStr));
        // [THEN] String for digital stamp has 'FechaPago' = '2023-01-01T12:00:00' (TFS 472400)
        // Assert.AreEqual(
        //   FormatDateTime(CustLedgerEntry."Posting Date", 120000T),
        //  SelectStr(28, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'FechaPago', OriginalStr));

        // [THEN] "Date/Time First Req. Sent" is created in current time zone (TFS 323341) (TFS 522707)
        // VerifyIsNearlyEqualDateTime(
        //  ConvertTxtToDateTime(CustLedgerEntry."Date/Time First Req. Sent"),
        //  CreateDateTime(CustLedgerEntry."Document Date", Time));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPayment2Docs()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        FileName: Text;
        OriginalStr: Text;
        PaymentNo1: Code[20];
        PaymentNo2: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 308161] Request stamp for second payment of sales invoice
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Amount Including VAT" = 1000 in local currency
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT()));
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        UpdateCustomerSATPaymentFields(SalesInvoiceHeader."Sell-to Customer No.");

        // [GIVEN] Payment "Pmt1" with amount of 300 is applied to the invoice
        PaymentNo1 :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -SalesInvoiceHeader."Amount Including VAT" / 2, '');

        // [GIVEN] Stamp is requested for the payment "Pmt1"
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo1, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo1);

        // [GIVEN] Payment "Pmt2" with amount of 700 is applied to the invoice
        PaymentNo2 :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -SalesInvoiceHeader."Amount Including VAT" / 2, '');

        // [WHEN] Request stamp for the payment "Pmt2"
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo2, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo2);

        // [THEN] 'Complemento' node created with attribute 'MonedaP' = 'MXN'
        // [THEN] Invoice's amount is exported to attribute 'ImpSaldoAnt' = 700
        InitXMLReaderForPagos20(FileName);
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:DoctoRelacionado', 'ImpSaldoAnt',
          FormatDecimal(SalesInvoiceHeader."Amount Including VAT" - Round(SalesInvoiceHeader."Amount Including VAT" / 2), 2));
        // [THEN] 'DoctoRelacionado' node has attribute 'NumParcialidad' (partial payment number) = '2' (363806)
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:DoctoRelacionado', 'NumParcialidad', '2');

        // [THEN] Original stamp string has NumParcialidad (partial payment number) = '2' (363806)
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);
        Assert.AreEqual('2', SelectStr(36, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'NumParcialidad', OriginalStr));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentService()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OriginalStr: Text;
        FileName: Text;
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Service]
        // [SCENARIO 362812] Request stamp for payment of service invoice
        Initialize();

        // [GIVEN] Posted Service Invoice with "Amount Including VAT" = 1000 in local currency
        ServiceInvoiceHeader.Get(
          CreateAndPostServiceDoc(ServiceHeader."Document Type"::Invoice, CreatePaymentMethodForSAT()));
        ServiceInvoiceHeader.CalcFields("Amount Including VAT");
        UpdateCustomerSATPaymentFields(ServiceInvoiceHeader."Customer No.");

        // [GIVEN] Payment with amount of 1000 is applied to the invoice, Payment Terms set to "PT".
        PaymentNo :=
          CreatePostPayment(
            ServiceInvoiceHeader."Customer No.", ServiceInvoiceHeader."No.", -ServiceInvoiceHeader."Amount Including VAT", '');
        ServiceInvoiceHeader."Payment Terms Code" := CreatePaymentTermsForSAT();
        ServiceInvoiceHeader.Modify();

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] 'DoctoRelacionado' node has attribute 'NumParcialidad' (partial payment number) = '1' (TFS 363806)
        InitXMLReaderForPagos20(FileName);
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:DoctoRelacionado', 'NumParcialidad', '1');

        // [THEN] Original stamp string has NumParcialidad (partial payment number) = '1' (TFS 363806)
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);
        Assert.AreEqual('1', SelectStr(38, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'NumParcialidad', OriginalStr));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentLCYAppliedToInvoiceFCY()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        OriginalStr: Text;
        FileName: Text;
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 449448] Request stamp for LCY payment applied to FCY invoice
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Amount Including VAT" = 1000 in foreign currency "USD"
        Customer.Get(CreateCustomer());
        Customer.Validate("Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandIntInRange(10, 20)));
        Customer.Modify(true);
        UpdateCustomerSATPaymentFields(Customer."No.");
        SalesHeader.Get(
          SalesHeader."Document Type"::Invoice,
          CreateSalesDocForCustomerWithVAT(
            SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT(), 16, false, false));
        GetPostedSalesInvoice(SalesInvoiceHeader, LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Payment with amount of -12345.67 in local currency is applied to the invoice
        PaymentNo :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -SalesInvoiceHeader."Amount Including VAT", '');

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        GetPaymentApplicationAmount(DetailedCustLedgEntry, CustLedgerEntry."Entry No.");

        // [THEN] 'Pagos/Totales' node has attribute 'MontoTotalPagos' = 12345.67
        // [THEN] 'Pagos/Pago' node created with attribute 'MonedaP' = 'MXN', 'TipoCambioP' = 1
        // [THEN] 'Pagos/Pago/DoctoRelacionado' node has attributes 'Monto' = 1000.00, 'MonedaDR' = 'USD', 'EquivalenciaDR' = 12.345670
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        VerifyComplementoPagoAmountWithCurrency(
            OriginalStr,
            DetailedCustLedgEntry."Amount (LCY)", 'MXN', '1',
            DetailedCustLedgEntry.Amount, Customer."Currency Code",
            FormatDecimal(SalesInvoiceHeader."Amount Including VAT" / DetailedCustLedgEntry.Amount, 10),
            SalesInvoiceHeader."Amount Including VAT", 29);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentFCYAppliedToInvoiceFCY()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OriginalStr: Text;
        FileName: Text;
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 449448] Request stamp for FCY payment applied to FCY invoice
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Amount Including VAT" = 1000 in foreign currency "USD" with Exch. Rate = 20
        Customer.Get(CreateCustomer());
        Customer.Validate("Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandIntInRange(10, 20)));
        Customer.Modify(true);
        UpdateCustomerSATPaymentFields(Customer."No.");
        SalesHeader.Get(
          SalesHeader."Document Type"::Invoice,
          CreateSalesDocForCustomerWithVAT(
            SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT(), 16, false, false));
        GetPostedSalesInvoice(SalesInvoiceHeader, LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Payment with amount of -1000 in "USD" currency is applied to the invoice
        PaymentNo :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.",
            -SalesInvoiceHeader."Amount Including VAT", Customer."Currency Code");

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] 'Pagos/Totales' node has attribute 'MontoTotalPagos' = 20000.00
        // [THEN] 'Complemento' node created with attribute 'MonedaP' = 'USD', 'TipoCambioP' = 20.000000
        // [THEN] 'DoctoRelacionado' node has attribute 'Monto' = 1000.00 , 'MonedaDR' = 'USD', 'EquivalenciaDR' = 1 (TFS 503112)
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        VerifyComplementoPagoAmountWithCurrency(
            OriginalStr,
            CustLedgerEntry."Amount (LCY)", Customer."Currency Code",
            FormatDecimal(Round(1 / CustLedgerEntry."Original Currency Factor", 0.000001), 6),
            CustLedgerEntry.Amount, Customer."Currency Code", '1', CustLedgerEntry.Amount, 29);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentForMultipleInvoicesFullyApplied()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntryInv: array[3] of Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OriginalStr: Text;
        FileName: Text;
        CustomerNo: Code[20];
        PaymentNo: Code[20];
        InvAmount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 386332] Request stamp for payment of multiple invoices
        Initialize();

        // [GIVEN] Three posted Sales Invoices with "Amount Including VAT" = 100, 200, 300
        CustomerNo := CreateCustomer();
        UpdateCustomerSATPaymentFields(CustomerNo);
        for i := 1 to ArrayLen(CustLedgerEntryInv) do begin
            CreateAndPostSalesInvoice(CustLedgerEntryInv[i], CustomerNo);
            GetPostedSalesInvoice(SalesInvoiceHeader, CustLedgerEntryInv[i]."Document No.");
            InvAmount += CustLedgerEntryInv[i].Amount;
        end;

        // [GIVEN] Payment with amount of -600 is applied to all invoices
        PaymentNo :=
          CreatePostPayment(CustomerNo, '', -InvAmount, '');
        for i := 1 to ArrayLen(CustLedgerEntryInv) do
            LibraryERM.ApplyCustomerLedgerEntries(
              CustLedgerEntry."Document Type"::Payment, CustLedgerEntryInv[i]."Document Type"::Invoice,
              PaymentNo, CustLedgerEntryInv[i]."Document No.");

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] ImpSaldoAnt = 100, 200, 300,  for each invoice respectively, ImpSaldoInsoluto = 0.
        // [THEN] IdDocumento = "Fiscal Invoice Number PAC" for each invoice.
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        for i := 1 to ArrayLen(CustLedgerEntryInv) do begin
            SalesInvoiceHeader.Get(CustLedgerEntryInv[i]."Document No.");
            VerifyComplementoPago(
              OriginalStr,
              CustLedgerEntryInv[i].Amount, CustLedgerEntryInv[i].Amount, 0,
              SalesInvoiceHeader."Fiscal Invoice Number PAC", '1', i - 1);
        end;
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentForMultipleInvoicesWithRemAmtForPayment()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntryInv: array[3] of Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OriginalStr: Text;
        FileName: Text;
        CustomerNo: Code[20];
        PaymentNo: Code[20];
        InvAmount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 386332] Request stamp for payment of multiple invoices with remaining amount
        Initialize();

        // [GIVEN] Three posted Sales Invoices with "Amount Including VAT" = 100, 200, 300
        CustomerNo := CreateCustomer();
        UpdateCustomerSATPaymentFields(CustomerNo);
        for i := 1 to ArrayLen(CustLedgerEntryInv) do begin
            CreateAndPostSalesInvoice(CustLedgerEntryInv[i], CustomerNo);
            GetPostedSalesInvoice(SalesInvoiceHeader, CustLedgerEntryInv[i]."Document No.");
            InvAmount += CustLedgerEntryInv[i].Amount;
        end;

        // [GIVEN] Payment with amount of -450 is applied to all invoices
        PaymentNo :=
          CreatePostPayment(CustomerNo, '', -(InvAmount - CustLedgerEntryInv[i].Amount / 2), '');
        for i := 1 to ArrayLen(CustLedgerEntryInv) do
            LibraryERM.ApplyCustomerLedgerEntries(
              CustLedgerEntry."Document Type"::Payment, CustLedgerEntryInv[i]."Document Type"::Invoice,
              PaymentNo, CustLedgerEntryInv[i]."Document No.");

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] ImpSaldoAnt = 100, 200, 150, for each invoice respectively,
        // [THEN] ImpSaldoInsoluto = 0 for 1st and 2nd invoice, ImpSaldoInsoluto = 150 for 3rd invoice.
        // [THEN] IdDocumento = "Fiscal Invoice Number PAC" for each invoice.
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        for i := 1 to ArrayLen(CustLedgerEntryInv) - 1 do begin
            SalesInvoiceHeader.Get(CustLedgerEntryInv[i]."Document No.");
            VerifyComplementoPago(
              OriginalStr,
              CustLedgerEntryInv[i].Amount, CustLedgerEntryInv[i].Amount, 0,
              SalesInvoiceHeader."Fiscal Invoice Number PAC", '1', i - 1);
        end;

        SalesInvoiceHeader.Get(CustLedgerEntryInv[3]."Document No.");
        CustLedgerEntryInv[3].CalcFields("Remaining Amount");
        VerifyComplementoPago(
          OriginalStr,
          CustLedgerEntryInv[3].Amount, CustLedgerEntryInv[3].Amount - CustLedgerEntryInv[3]."Remaining Amount",
          CustLedgerEntryInv[3]."Remaining Amount",
          SalesInvoiceHeader."Fiscal Invoice Number PAC", '1', 2);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentForMultipleInvoicesWithRemAmtForInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntryInv: array[3] of Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OriginalStr: Text;
        FileName: Text;
        CustomerNo: Code[20];
        PaymentNo: Code[20];
        InvAmount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 386332] Request stamp for payment of multiple invoices with remaining amount
        Initialize();

        // [GIVEN] Three posted Sales Invoices with "Amount Including VAT" = 100, 200, 300
        CustomerNo := CreateCustomer();
        UpdateCustomerSATPaymentFields(CustomerNo);
        for i := 1 to ArrayLen(CustLedgerEntryInv) do begin
            CreateAndPostSalesInvoice(CustLedgerEntryInv[i], CustomerNo);
            GetPostedSalesInvoice(SalesInvoiceHeader, CustLedgerEntryInv[i]."Document No.");
            InvAmount += CustLedgerEntryInv[i].Amount;
        end;

        // [GIVEN] Payment with amount of -600 is applied to all invoices, 3rd invoice is applied partially.
        PaymentNo :=
          CreatePostPayment(CustomerNo, '', -InvAmount, '');
        for i := 1 to ArrayLen(CustLedgerEntryInv) - 1 do
            LibraryERM.ApplyCustomerLedgerEntries(
              CustLedgerEntry."Document Type"::Payment, CustLedgerEntryInv[i]."Document Type"::Invoice,
              PaymentNo, CustLedgerEntryInv[i]."Document No.");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntryInv[3]);
        CustLedgerEntryInv[3].CalcFields(Amount);
        CustLedgerEntryInv[3].Validate("Amount to Apply", CustLedgerEntryInv[3].Amount / 2);
        CustLedgerEntryInv[3].Modify(true);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] ImpSaldoAnt = 100, 200, 150, for each invoice respectively,
        // [THEN] ImpSaldoInsoluto = 0 for 1st and 2nd invoice, ImpSaldoInsoluto = 150 for 3rd invoice.
        // [THEN] IdDocumento = "Fiscal Invoice Number PAC" for each invoice.
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        for i := 1 to ArrayLen(CustLedgerEntryInv) - 1 do begin
            SalesInvoiceHeader.Get(CustLedgerEntryInv[i]."Document No.");
            VerifyComplementoPago(
              OriginalStr,
              CustLedgerEntryInv[i].Amount, CustLedgerEntryInv[i].Amount, 0,
              SalesInvoiceHeader."Fiscal Invoice Number PAC", '1', i - 1);
        end;

        SalesInvoiceHeader.Get(CustLedgerEntryInv[3]."Document No.");
        CustLedgerEntryInv[3].CalcFields("Remaining Amount");
        VerifyComplementoPago(
          OriginalStr,
          CustLedgerEntryInv[3].Amount, CustLedgerEntryInv[3].Amount - CustLedgerEntryInv[3]."Remaining Amount",
          CustLedgerEntryInv[3]."Remaining Amount",
          SalesInvoiceHeader."Fiscal Invoice Number PAC", '1', 2);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentForMultipleInvoicesWithRemAmtForFirstInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntryInv: array[3] of Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InvAppliedAmt: array[3] of Decimal;
        OriginalStr: Text;
        FileName: Text;
        CustomerNo: Code[20];
        PaymentNo: Code[20];
        PmtAmount: Decimal;
        PaidAmtTotal: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 386332] Request stamp for payment of multiple invoices with remaining amount for first and last invoice
        Initialize();

        // [GIVEN] Three posted Sales Invoices with "Amount Including VAT" = 100, 200, 300
        CustomerNo := CreateCustomer();
        UpdateCustomerSATPaymentFields(CustomerNo);
        for i := 1 to ArrayLen(CustLedgerEntryInv) do begin
            CreateAndPostSalesInvoice(CustLedgerEntryInv[i], CustomerNo);
            GetPostedSalesInvoice(SalesInvoiceHeader, CustLedgerEntryInv[i]."Document No.");
        end;
        InvAppliedAmt[1] := Round(CustLedgerEntryInv[1].Amount / 2) - 10;
        InvAppliedAmt[2] := Round(CustLedgerEntryInv[2].Amount);
        InvAppliedAmt[3] := Round(CustLedgerEntryInv[3].Amount / 2) - 10;
        PmtAmount := InvAppliedAmt[1] + InvAppliedAmt[2] + InvAppliedAmt[3];
        PaidAmtTotal := InvAppliedAmt[1] + PmtAmount;

        // [GIVEN] Payment "Pmt1" with amount of -40 is applied to first invoice
        PaymentNo := CreatePostPayment(CustomerNo, '', -InvAppliedAmt[1], '');
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        CustLedgerEntry."Date/Time Stamped" := Format(WorkDate());
        CustLedgerEntry."Fiscal Invoice Number PAC" := LibraryUtility.GenerateGUID();
        CustLedgerEntry.Modify();
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntryInv[1]."Document Type"::Invoice,
          PaymentNo, CustLedgerEntryInv[1]."Document No.");

        // [GIVEN] Payment "Pmt2" with amount = 380 is applied to all documents (40 + 200 + 140 respectively)
        PaymentNo := CreatePostPayment(CustomerNo, '', -PmtAmount, '');
        for i := 1 to ArrayLen(CustLedgerEntryInv) do
            LibraryERM.ApplyCustomerLedgerEntries(
              CustLedgerEntry."Document Type"::Payment, CustLedgerEntryInv[i]."Document Type"::Invoice,
              PaymentNo, CustLedgerEntryInv[i]."Document No.");

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] First invoice line has NumParcialidad='2' ImpSaldoAnt='60' ImpPagado='60' ImpSaldoInsoluto='0.00'
        // [THEN] Second invoice line has NumParcialidad='1' ImpSaldoAnt='200' ImpPagado='200' ImpSaldoInsoluto='0.00'
        // [THEN] Third invoice line has NumParcialidad='1' ImpSaldoAnt='300' ImpPagado='180' (100 + 200 + 300 - (40 + 380)) ImpSaldoInsoluto='120'
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        SalesInvoiceHeader.Get(CustLedgerEntryInv[1]."Document No.");
        VerifyComplementoPago(
          OriginalStr,
          CustLedgerEntryInv[1].Amount - InvAppliedAmt[1],
          CustLedgerEntryInv[1].Amount - InvAppliedAmt[1], 0,
          SalesInvoiceHeader."Fiscal Invoice Number PAC", '2', 0);

        SalesInvoiceHeader.Get(CustLedgerEntryInv[2]."Document No.");
        VerifyComplementoPago(
          OriginalStr,
          CustLedgerEntryInv[2].Amount, CustLedgerEntryInv[2].Amount, 0,
          SalesInvoiceHeader."Fiscal Invoice Number PAC", '1', 1);

        SalesInvoiceHeader.Get(CustLedgerEntryInv[3]."Document No.");
        CustLedgerEntryInv[3].CalcFields("Remaining Amount");
        VerifyComplementoPago(
          OriginalStr,
          CustLedgerEntryInv[3].Amount, PaidAmtTotal - CustLedgerEntryInv[1].Amount - CustLedgerEntryInv[2].Amount,
          CustLedgerEntryInv[3]."Remaining Amount", SalesInvoiceHeader."Fiscal Invoice Number PAC", '1', 2);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentWhenInvoiceAppliedToPayment()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntryInv: Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        FileName: Text;
        CustomerNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 425402] Request stamp for LCY payment when invoice applied to payment
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Amount Including VAT" = 1000
        CustomerNo := CreateCustomer();
        UpdateCustomerSATPaymentFields(CustomerNo);
        CreateAndPostSalesInvoice(CustLedgerEntryInv, CustomerNo);
        GetPostedSalesInvoice(SalesInvoiceHeader, CustLedgerEntryInv."Document No.");

        // [GIVEN] Payment with amount -1000
        PaymentNo :=
          CreatePostPayment(SalesInvoiceHeader."Sell-to Customer No.", '', -SalesInvoiceHeader."Amount Including VAT", '');
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [GIVEN] Invoice is applied to the payment
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Invoice, CustLedgerEntry."Document Type"::Payment,
          SalesInvoiceHeader."No.", PaymentNo);

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] XML document is created for LCY payment with UUID of related invoice
        InitXMLReaderForPagos20(FileName);
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago', 'MonedaP', 'MXN');
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:DoctoRelacionado', 'IdDocumento', SalesInvoiceHeader."Fiscal Invoice Number PAC");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendTwoFCYPaymentsForFCYInvoice()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OriginalStr: Text;
        PaymentNo1: Code[20];
        PaymentNo2: Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Payment] [Currency]
        // [SCENARIO 473884] Request stamp for 2 LCY payments applied to FCY invoice with higher amount
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Amount Including VAT" = 233,352.56 USD / 4,325,421.37 MXN with Exch. Rate = 18.6428
        Customer.Get(CreateCustomer());
        UpdateCustomerSATPaymentFields(Customer."No.");
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        SalesHeader.Validate("Posting Date", WorkDate() - 1);
        SalesHeader.Validate(
          "Currency Code", LibraryERM.CreateCurrencyWithExchangeRate(WorkDate() - 1, 1 / 18.1185, 1 / 18.1185));
        SalesHeader.Validate("Currency Factor", 1 / 18.6428);
        SalesHeader.Modify();
        SalesHeader.Modify(true);
        CreateSalesLineItem(SalesLine, SalesHeader, CreateItem(), 1, 0, 16, false, false);
        SalesLine.Validate("Unit Price", 201166.0);
        SalesLine.Modify(true);
        GetPostedSalesInvoice(SalesInvoiceHeader, LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Payment1 of 845949.70 MXN with Exch. Rate = 18.1185 is applied to the invoice with 46689.83 USD
        PaymentNo1 :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -845949.7, '');
        // [GIVEN] Payment2 of 422060.11 MXN with Exch. Rate = 18.6232 is applied to the invoice with 22663.14 USD
        LibraryERM.CreateExchangeRate(SalesHeader."Currency Code", WorkDate(), 1 / 18.6232, 1 / 18.6232);
        PaymentNo2 :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -422060.11, '');

        // [WHEN] Request stamp for the payments
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo1, ResponseOption::Success, ActionOption::"Request Stamp");
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo2, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] First payment has 'DoctoRelacionado' node with ImpSaldoAnt=233352.56 ImpPagado=46689.83 ImpSaldoInsoluto=186662.73
        // [THEN] Second invoice has 'DoctoRelacionado' node with ImpSaldoAnt=186662.73 ImpPagado=22663.14 ImpSaldoInsoluto=163999.59
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo1);
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        VerifyComplementoPago(
          OriginalStr, 233352.56, 46689.83, 186662.73, SalesInvoiceHeader."Fiscal Invoice Number PAC", '1', 0);

        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo2);
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        VerifyComplementoPago(
          OriginalStr, 186662.73, 22663.14, 163999.59, SalesInvoiceHeader."Fiscal Invoice Number PAC", '2', 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentForPartiallyShippedInvoice()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OriginalStr: Text;
        PaymentNo: Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Payment] [Shipment]
        // [SCENARIO 474755] Request stamp for payment applied to invoice with partial shipment
        Initialize();

        // [GIVEN] Posted Sales order with two lines, the second line has Qty. to Ship = 0
        Customer.Get(CreateCustomer());
        UpdateCustomerSATPaymentFields(Customer."No.");
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItem(SalesLine1, SalesHeader, CreateItem(), 1, 0, 16, false, false);
        CreateSalesLineItem(SalesLine2, SalesHeader, CreateItem(), 1, 0, 16, false, false);
        SalesLine2.Validate("Qty. to Ship", 0);
        SalesLine2.Modify(true);
        GetPostedSalesInvoice(SalesInvoiceHeader, LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Payment is fully applied to the invoice
        PaymentNo :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -SalesInvoiceHeader."Amount Including VAT", '');

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] 'Pagos/Totales' node has attribute 'MontoTotalPagos' with the amount for the payment
        // [THEN] One TrasladoP node has created with the amounts according to the invoice
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        VerifyComplementoPago(
          OriginalStr, SalesLine1."Amount Including VAT", SalesLine1."Amount Including VAT", 0, SalesInvoiceHeader."Fiscal Invoice Number PAC", '1', 0);
        VerifyComplementoPagoTrasladoP(OriginalStr, 49, SalesLine1.Amount, SalesLine1."Amount Including VAT" - SalesLine1.Amount, 0.16, 0);
        LibraryXPathXMLReader.VerifyNodeCountByXPath(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:ImpuestosP/pago20:TrasladosP/pago20:TrasladoP', 1);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentForInvoiceSameVATdifferentVATIdentifiers()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OriginalStr: Text;
        PaymentNo: Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Payment] [VAT]
        // [SCENARIO 474755] Request stamp for payment applied to invoice with same VAT line but different VAT identifiers
        Initialize();

        // [GIVEN] Posted Sales invoice with two lines of different VAT identifiers and VAT = 16%
        Customer.Get(CreateCustomer());
        UpdateCustomerSATPaymentFields(Customer."No.");
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItem(SalesLine1, SalesHeader, CreateItem(), 1, 0, 16, false, false);
        CreateSalesLineItemWithVATSetup(
          SalesLine2, SalesHeader, CreateItem(),
          CreateVATPostingSetup(SalesHeader."VAT Bus. Posting Group", 16, false, false), 1, LibraryRandom.RandIntInRange(100, 200), 0);
        GetPostedSalesInvoice(SalesInvoiceHeader, LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Payment is fully applied to the invoice
        PaymentNo :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -SalesInvoiceHeader."Amount Including VAT", '');

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] 'Pagos/Totales' node has attribute 'MontoTotalPagos' with the amount for the payment
        // [THEN] One TrasladoP node has created with the amounts according to the invoice
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        VerifyComplementoPago(
          OriginalStr, SalesInvoiceHeader."Amount Including VAT", SalesInvoiceHeader."Amount Including VAT", 0, SalesInvoiceHeader."Fiscal Invoice Number PAC", '1', 0);
        VerifyComplementoPagoTrasladoP(OriginalStr, 49, SalesInvoiceHeader.Amount, SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount, 0.16, 0);
        LibraryXPathXMLReader.VerifyNodeCountByXPath(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:ImpuestosP/pago20:TrasladosP/pago20:TrasladoP', 1);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentForInvoiceWithAppliedCreditMemo()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OriginalStr: Text;
        PaymentNo: Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Payment] [Credit Memo]
        // [SCENARIO 505171] Request stamp for LCY payment of the LCY invoice having credit memo applied to it
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Amount Including VAT" = 174.000 MXN (150k + 24k VAT)
        Customer.Get(CreateCustomer());
        UpdateCustomerSATPaymentFields(Customer."No.");
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItem(SalesLine, SalesHeader, CreateItem(), 1, 0, 16, false, false);
        GetPostedSalesInvoice(SalesInvoiceHeader, LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Posted Sales Credit Memo applied to the invoice with amount = 58.000 MXN (50k + 8k VAT)
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItem(SalesLine, SalesHeader, CreateItemWithPrice(SalesLine."Unit Price" / 2), 1, 0, 16, false, false);
        SalesHeader.Validate("Applies-to Doc. Type", SalesHeader."Applies-to Doc. Type"::Invoice);
        SalesHeader.Validate("Applies-to Doc. No.", SalesInvoiceHeader."No.");
        SalesHeader.Modify();
        GetPostedSalesCreditMemo(SalesCrMemoHeader, LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Payment of 116.000 MXN (100k + 16k VAT) is applied to the invoice
        PaymentNo :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -(SalesInvoiceHeader."Amount Including VAT" - SalesCrMemoHeader."Amount Including VAT"), '');

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Payment has 'DoctoRelacionado' node with ImpSaldoAnt=116000.00 ImpPagado=116000.00 ImpSaldoInsoluto=0.00
        // [THEN] 'TrasladoP' node has attributes BaseP = 100000.000000, ImporteP = 16000.000000
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        VerifyComplementoPago(
          OriginalStr, SalesInvoiceHeader."Amount Including VAT" - SalesCrMemoHeader."Amount Including VAT", SalesInvoiceHeader."Amount Including VAT" - SalesCrMemoHeader."Amount Including VAT",
          0.00, SalesInvoiceHeader."Fiscal Invoice Number PAC", '1', 0);
        VerifyComplementoPagoTrasladoP(
          OriginalStr, 49,
          SalesInvoiceHeader.Amount - SalesCrMemoHeader.Amount,
          SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount - (SalesCrMemoHeader."Amount Including VAT" - SalesCrMemoHeader.Amount), 0.16, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentForInvoiceWithCreditMemoAppliedUsingCLE()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OriginalStr: Text;
        PaymentNo: Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Payment] [Credit Memo]
        // [SCENARIO 505171] Request stamp for LCY payment of the LCY invoice applied to credit memo
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Amount Including VAT" = 174.000 MXN (150k + 24k VAT)
        Customer.Get(CreateCustomer());
        UpdateCustomerSATPaymentFields(Customer."No.");
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItem(SalesLine, SalesHeader, CreateItem(), 1, 0, 16, false, false);
        GetPostedSalesInvoice(SalesInvoiceHeader, LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Posted Sales Credit Memo with amount = 58.000 MXN (50k + 8k VAT)
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItem(SalesLine, SalesHeader, CreateItemWithPrice(SalesLine."Unit Price" / 2), 1, 0, 16, false, false);
        GetPostedSalesCreditMemo(SalesCrMemoHeader, LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Invoice is appied to the credit memo
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Invoice, CustLedgerEntry."Document Type"::"Credit Memo",
          SalesInvoiceHeader."No.", SalesCrMemoHeader."No.");

        // [GIVEN] Payment of 116.000 MXN (100k + 16k VAT) is applied to the invoice
        PaymentNo :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -(SalesInvoiceHeader."Amount Including VAT" - SalesCrMemoHeader."Amount Including VAT"), '');

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Payment has 'DoctoRelacionado' node with ImpSaldoAnt=116000.00 ImpPagado=116000.00 ImpSaldoInsoluto=0.00
        // [THEN] 'TrasladoP' node has attributes BaseP = 100000.000000, ImporteP = 16000.000000
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        VerifyComplementoPago(
          OriginalStr, SalesInvoiceHeader."Amount Including VAT" - SalesCrMemoHeader."Amount Including VAT", SalesInvoiceHeader."Amount Including VAT" - SalesCrMemoHeader."Amount Including VAT",
          0.00, SalesInvoiceHeader."Fiscal Invoice Number PAC", '1', 0);
        VerifyComplementoPagoTrasladoP(
          OriginalStr, 49,
          SalesInvoiceHeader.Amount - SalesCrMemoHeader.Amount,
          SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount - (SalesCrMemoHeader."Amount Including VAT" - SalesCrMemoHeader.Amount), 0.16, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentClosingPartiallyAppliedInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntryInv: array[2] of Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OriginalStr: Text;
        FileName: Text;
        CustomerNo: Code[20];
        PaymentNo1, PaymentNo2 : Code[20];
        i: Integer;
    begin
        // [FEATURE] [Sales] [Payment]
        // [SCENARIO 536623] Request stamp for payment that closes the invoice that is partially applied to a larger payment
        Initialize();

        // [GIVEN] Two posted Sales Invoices with "Amount Including VAT" = 100, 200
        CustomerNo := CreateCustomer();
        UpdateCustomerSATPaymentFields(CustomerNo);
        for i := 1 to ArrayLen(CustLedgerEntryInv) do begin
            CreateAndPostSalesInvoice(CustLedgerEntryInv[i], CustomerNo);
            GetPostedSalesInvoice(SalesInvoiceHeader, CustLedgerEntryInv[i]."Document No.");
        end;

        // [GIVEN] Payment "Pmt1" with amount of -150 (100/2 + 200)
        PaymentNo1 := CreatePostPayment(CustomerNo, '', -CustLedgerEntryInv[1].Amount / 2 - CustLedgerEntryInv[2].Amount, '');
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo1);

        // [GIVEN] Payment "Pmt1" is applied to the first invoice with amount of 50
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntryInv[1]);
        CustLedgerEntryInv[1].CalcFields(Amount);
        CustLedgerEntryInv[1].Validate("Amount to Apply", CustLedgerEntryInv[1].Amount / 2);
        CustLedgerEntryInv[1].Modify(true);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);

        // [GIVEN] Payment "Pmt1" is applied to the second invoice
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntryInv[2]."Document Type"::Invoice,
          PaymentNo1, CustLedgerEntryInv[2]."Document No.");

        // [GIVEN] Payment "Pmt2" with amount = -50 (100/2) is applied to the invoice 1
        PaymentNo2 := CreatePostPayment(CustomerNo, '', -CustLedgerEntryInv[1].Amount / 2, '');
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo2);
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntryInv[1]."Document Type"::Invoice,
          PaymentNo2, CustLedgerEntryInv[1]."Document No.");

        // [WHEN] Request stamp for the payments
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo1, ResponseOption::Success, ActionOption::"Request Stamp");
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo2, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] First payment has a line for first invoice with NumParcialidad='1' ImpSaldoAnt='100' ImpPagado='50' ImpSaldoInsoluto='50'
        // [THEN] First payment has a line for second invoice with NumParcialidad='1' ImpSaldoAnt='200' ImpPagado='200' ImpSaldoInsoluto='0'
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo1);
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        SalesInvoiceHeader.Get(CustLedgerEntryInv[1]."Document No.");
        VerifyComplementoPago(
          OriginalStr,
          CustLedgerEntryInv[1].Amount, CustLedgerEntryInv[1].Amount / 2, CustLedgerEntryInv[1].Amount / 2,
          SalesInvoiceHeader."Fiscal Invoice Number PAC", '1', 0);

        SalesInvoiceHeader.Get(CustLedgerEntryInv[2]."Document No.");
        VerifyComplementoPago(
          OriginalStr,
          CustLedgerEntryInv[2].Amount, CustLedgerEntryInv[2].Amount, 0,
          SalesInvoiceHeader."Fiscal Invoice Number PAC", '1', 1);

        // [THEN] Second payment has a line for first invoice with NumParcialidad='2' ImpSaldoAnt='50' ImpPagado='50' ImpSaldoInsoluto='0.00'
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo2);
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        SalesInvoiceHeader.Get(CustLedgerEntryInv[1]."Document No.");
        VerifyComplementoPago(
          OriginalStr,
          CustLedgerEntryInv[1].Amount / 2, CustLedgerEntryInv[1].Amount / 2, 0,
          SalesInvoiceHeader."Fiscal Invoice Number PAC", '2', 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentWithGainLosses()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OriginalStr: Text;
        PaymentNo: Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Payment] [Rounding] [Currency]
        // [SCENARIO 449448] Request stamp for FCY payment applied to FCY invoice
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Amount Including VAT" = 407.51 "USD" / 8150.20 MXN with Exch. Rate = 20
        Customer.Get(CreateCustomer());
        Customer.Validate("Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate() - 1, 1 / 20, 1 / 20));
        Customer.Modify(true);
        UpdateCustomerSATPaymentFields(Customer."No.");
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItem(SalesLine, SalesHeader, CreateItem(), 1, 0, 16, false, false);
        SalesLine.Validate("Unit Price", 351.3);
        SalesLine.Modify(true);
        GetPostedSalesInvoice(SalesInvoiceHeader, LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Payment with amount of -407.51 USD/ 8476.21 MXN with Exch. Rate = 20.8 is applied to the invoice
        LibraryERM.CreateExchangeRate(Customer."Currency Code", WorkDate(), 1 / 20.8, 1 / 20.8);
        PaymentNo :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.",
            -SalesInvoiceHeader."Amount Including VAT", Customer."Currency Code");

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] 'Pagos/Totales' node has attribute 'MontoTotalPagos' = 8150.20
        // [THEN] 'Complemento' node created with attribute 'MonedaP' = 'USD', 'TipoCambioP' = 20.800005
        // [THEN] 'DoctoRelacionado' node has attribute 'Monto' = 407.51 , 'MonedaDR' = 'USD', 'EquivalenciaDR' = 1 (TFS 503112)
        // [THEN] TrasladoP nose has attributes BaseP = 351.300000, ImporteP = 56.210000
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        VerifyComplementoPagoAmountWithCurrency(
          OriginalStr,
          8476.21, Customer."Currency Code", '20.800005',
          407.51, Customer."Currency Code", '1', 407.51, 29);
        VerifyComplementoPagoTrasladoP(OriginalStr, 49, 351.3, 56.21, 0.16, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentRoundingFCYPaymentToLCYInvoice()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OriginalStr: Text;
        PaymentNo: Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Payment] [Rounding] [Currency]
        // [SCENARIO 441226] Request stamp for payment FCY applied to the invoice with normal VAT and VAT exempt
        Initialize();

        // [GIVEN] Posted Sales Invoice in LCY has line 1 of Amount = 4000 and VAT Amount = 640 and line 2 of Amount = 900 with VAT exempt
        Customer.Get(CreateCustomer());
        UpdateCustomerSATPaymentFields(Customer."No.");
        CreateSalesHeaderForCustomer(
          SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItemWithPrice(4000), 1, 0, 16, false, false);
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItemWithPrice(900), 1, 0, 0, true, false);
        GetPostedSalesInvoice(SalesInvoiceHeader, LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Payment with 615.62 USD / 5540.00 MXN is applied to the invoice
        PaymentNo :=
          CreatePostPaymentFCY(
            SalesInvoiceHeader."Sell-to Customer No.", -615.62, -5540.0,
            LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1 / 8.999058, 1 / 8.999058));
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Invoice,
          PaymentNo, SalesInvoiceHeader."No.");

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        // [THEN] 'Pagos/Totales' node has attribute 'MontoTotalPagos' = 5540.00
        // [THEN] 'Complemento' node created with attribute 'MonedaP' = 'USD', 'TipoCambioP' = 8.999058
        // [THEN] 'DoctoRelacionado' node has attribute 'Monto' = 407.51 , 'MonedaDR' = 'MXN', 'EquivalenciaDR' = 8.9990578604
        // [THEN] TrasladoP nose has attributes BaseP = 444.490974, ImporteP = 71.118555
        VerifyComplementoPagoAmountWithCurrency(
          OriginalStr,
          5540.0, CustLedgerEntry."Currency Code", '8.999058',
          615.62, 'MXN', '8.9990578604', 5540.0, 30);
        VerifyComplementoPagoTrasladoP(OriginalStr, 56, 444.490974, 71.118555, 0.16, 1);
        VerifyComplementoPagoTrasladoPExempt(OriginalStr, 53, 100.010469, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentRoundingFCYPaymentToFCYInvoiceExchRate20()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OriginalStr: Text;
        PaymentNo: Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Payment] [Rounding] [Currency]
        // [SCENARIO 447293] Request stamp for FCY payment applied to FCY invoice
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Amount Including VAT" = 407.51 in foreign currency "USD" with Exch. Rate = 20
        Customer.Get(CreateCustomer());
        Customer.Validate("Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1 / 20, 1 / 20));
        Customer.Modify(true);
        UpdateCustomerSATPaymentFields(Customer."No.");
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItem(SalesLine, SalesHeader, CreateItem(), 1, 0, 16, false, false);
        SalesLine.Validate("Unit Price", 351.3);
        SalesLine.Modify(true);
        GetPostedSalesInvoice(SalesInvoiceHeader, LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Payment with amount of -407.51 in "USD" currency is applied to the invoice
        PaymentNo :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.",
            -SalesInvoiceHeader."Amount Including VAT", Customer."Currency Code");

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] 'Pagos/Totales' node has attribute 'MontoTotalPagos' = 8150.20
        // [THEN] 'Complemento' node created with attribute 'MonedaP' = 'USD', 'TipoCambioP' = 20.000000
        // [THEN] 'DoctoRelacionado' node has attribute 'Monto' = 407.51 , 'MonedaDR' = 'USD', 'EquivalenciaDR' = 1 (TFS 503112)
        // [THEN] TrasladoP nose has attributes BaseP = 351.300000, ImporteP = 56.210000
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        VerifyComplementoPagoAmountWithCurrency(
          OriginalStr,
          8150.2, Customer."Currency Code", '20.000000',
          407.51, Customer."Currency Code", '1', 407.51, 29);
        VerifyComplementoPagoTrasladoP(OriginalStr, 49, 351.3, 56.21, 0.16, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentRoundingFCYPaymentToFCYInvoiceExchRateWithDec()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OriginalStr: Text;
        PaymentNo: Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Payment] [Rounding] [Currency]
        // [SCENARIO 447293] Request stamp for FCY payment applied to FCY invoice wuth exchange rate having decimals
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Amount Including VAT" = 205.80 in USD / 1852.01 MXN with Exch. Rate = 20
        Customer.Get(CreateCustomer());
        Customer.Validate("Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1 / 8.999077, 1 / 8.999077));
        Customer.Modify(true);
        UpdateCustomerSATPaymentFields(Customer."No.");
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItem(SalesLine, SalesHeader, CreateItem(), 1, 0, 16, false, false);
        SalesLine.Validate("Unit Price", 177.41);
        SalesLine.Modify(true);
        GetPostedSalesInvoice(SalesInvoiceHeader, LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Payment with amount of -205.80 in "USD" currency is applied to the invoice
        PaymentNo :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.",
            -SalesInvoiceHeader."Amount Including VAT", Customer."Currency Code");

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] 'Pagos/Totales' node has attribute 'MontoTotalPagos' = 1852.01
        // [THEN] 'Complemento' node created with attribute 'MonedaP' = 'USD', 'TipoCambioP' = 8.999077
        // [THEN] 'DoctoRelacionado' node has attribute 'Monto' = 205.80 , 'MonedaDR' = 'USD', 'EquivalenciaDR' = 1 (TFS 503112)
        // [THEN] TrasladoP nose has attributes BaseP = 177.410000, ImporteP = 28.390000
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        VerifyComplementoPagoAmountWithCurrency(
          OriginalStr,
          1852.01, Customer."Currency Code", '8.999077',
          205.8, Customer."Currency Code", '1', 205.8, 29);
        VerifyComplementoPagoTrasladoP(OriginalStr, 49, 177.41, 28.39, 0.16, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentRoundingMultipleLCYInvoices()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATProdPostingGroup: Code[20];
        OriginalStr: Text;
        FileName: Text;
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Payment] [Rounding]
        // [SCENARIO 444797] Request stamp for payment of four invoices
        Initialize();

        // [GIVEN] Four posted Sales Invoices with "Amount Including VAT" = 14112.63, 48678.02, 11895.48, 125064.24, VAT% = 16
        Customer.Get(CreateCustomer());
        UpdateCustomerSATPaymentFields(Customer."No.");
        VATProdPostingGroup := CreateVATPostingSetup(Customer."VAT Bus. Posting Group", 16, false, false);

        PaymentNo := CreatePostPayment(Customer."No.", '', -199750.37, '');

        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItemWithVATSetup(SalesLine, SalesHeader, CreateItem(), VATProdPostingGroup, 1, 12166.06, 0);
        GetPostedSalesInvoice(SalesInvoiceHeader, LibrarySales.PostSalesDocument(SalesHeader, true, true));
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Invoice, PaymentNo, SalesInvoiceHeader."No.");

        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItemWithVATSetup(SalesLine, SalesHeader, CreateItem(), VATProdPostingGroup, 1, 41963.81, 0);
        GetPostedSalesInvoice(SalesInvoiceHeader, LibrarySales.PostSalesDocument(SalesHeader, true, true));
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Invoice, PaymentNo, SalesInvoiceHeader."No.");

        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItemWithVATSetup(SalesLine, SalesHeader, CreateItem(), VATProdPostingGroup, 1, 10254.72, 0);
        GetPostedSalesInvoice(SalesInvoiceHeader, LibrarySales.PostSalesDocument(SalesHeader, true, true));
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Invoice, PaymentNo, SalesInvoiceHeader."No.");

        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItemWithVATSetup(SalesLine, SalesHeader, CreateItem(), VATProdPostingGroup, 1, 107814.0, 0);
        GetPostedSalesInvoice(SalesInvoiceHeader, LibrarySales.PostSalesDocument(SalesHeader, true, true));
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Invoice, PaymentNo, SalesInvoiceHeader."No.");

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] MontoTotalPagos = 199750.37
        // [THEN] TrasladoP nose has attributes BaseP = 172198.590000, ImpuestoP = 27551.780000
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        // [THEN] EquivalenciaDR = 1.0000000000 (TFS 503112)
        VerifyComplementoPagoAmountWithCurrency(
          OriginalStr,
          199750.37, 'MXN', '1',
          199750.37, 'MXN', '1.0000000000', 14112.63, 29);
        VerifyComplementoPagoTrasladoP(OriginalStr, 91, 172198.59, 27551.78, 0.16, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentRoundingLCYPaymentToFCYInvoice()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OriginalStr: Text;
        PaymentNo: Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Payment] [Rounding] [Currency]
        // [SCENARIO 451338] Request stamp for LCY payment applied to FCY invoice
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Amount Including VAT" = 325.14 in foreign currency "USD"
        Customer.Get(CreateCustomer());
        UpdateCustomerSATPaymentFields(Customer."No.");
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        SalesHeader.Validate(
          "Currency Code", LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1 / 8.9991, 1 / 8.9991));
        SalesHeader.Modify(true);
        CreateSalesLineItem(SalesLine, SalesHeader, CreateItem(), 1, 0, 16, false, false);
        SalesLine.Validate("Unit Price", 280.288);
        SalesLine.Modify(true);
        GetPostedSalesInvoice(SalesInvoiceHeader, LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Payment with amount of -2925.97 in local currency is applied to the invoice
        PaymentNo :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", '', -2925.97, '');
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Invoice,
          PaymentNo, SalesInvoiceHeader."No.");

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] 'Pagos/Totales' node has attribute 'MontoTotalPagos' = 2925.97
        // [THEN] 'Pagos/Pago' node created with attribute 'MonedaP' = 'MXN', 'TipoCambioP' = 1
        // [THEN] 'Pagos/Pago/DoctoRelacionado' node has attributes 'Monto' = 2925.97, 'MonedaDR' = 'USD', 'EquivalenciaDR' = 0.1111221236
        // [THEN] TrasladoP nose has attributes BaseP = 2522.360002, ImpuestoP = 403.609997
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        VerifyComplementoPagoAmountWithCurrency(
          OriginalStr,
          2925.97, 'MXN', '1',
          2925.97, SalesInvoiceHeader."Currency Code", '0.1111221236', 325.14, 29);
        VerifyComplementoPagoTrasladoP(OriginalStr, 49, 2522.360002, 403.609997, 0.16, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentLCYToThreeFCYInvoicesEquivalenciaDRRecalc()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATProdPostingGroup: Code[20];
        OriginalStr: Text;
        PaymentNo: Code[20];
        FileName: Text;
        Invoice1: Code[20];
        Invoice2: Code[20];
        Invoice3: Code[20];
    begin
        // [FEATURE] [Payment] [Limits] [Currency]
        // [SCENARIO 456338] Request stamp for LCY payment applied to three FCY invoices
        Initialize();

        // [GIVEN] Three posted Sales Invoices in USD with "Amount Including VAT" = 1258.60, 2949.88, 3336.16, VAT% = 16
        Customer.Get(CreateCustomer());
        Customer.Validate("Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1 / 21.345, 1 / 21.345));
        Customer.Modify(true);
        UpdateCustomerSATPaymentFields(Customer."No.");
        VATProdPostingGroup := CreateVATPostingSetup(Customer."VAT Bus. Posting Group", 16, false, false);

        // [GIVEN] Sales Invoice 1 with Amount = 1085.00, Amount Incl VAT = 1258.60, Exch.Rate = 22.345
        Invoice1 := CreatePostSalesInvoiceWithCurrencyAmount(Customer."No.", VATProdPostingGroup, 1, 1085, 22.345);
        // [GIVEN] Sales Invoice 2 with Amount = 2543.00, Amount Incl VAT = 2949.88, Exch.Rate = 20.5231
        Invoice2 := CreatePostSalesInvoiceWithCurrencyAmount(Customer."No.", VATProdPostingGroup, 1, 2543, 20.5231);
        // [GIVEN] Sales Invoice 3 with Amount = 2876.00, Amount Incl VAT = 3336.16, Exch.Rate = 21.987
        Invoice3 := CreatePostSalesInvoiceWithCurrencyAmount(Customer."No.", VATProdPostingGroup, 1, 2876, 21.987);
        // [GIVEN] Payment in LCY with Amount = 161040.35 is applied to all invoices
        PaymentNo := CreatePostPayment(Customer."No.", '', -161040.35, '');

        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Invoice, PaymentNo, Invoice1);
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Invoice, PaymentNo, Invoice2);
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Invoice, PaymentNo, Invoice3);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] 'Pagos/Totales' node has attribute 'MontoTotalPagos' = 161040.35
        // [THEN] 'Pagos/Pago' node created with attribute 'MonedaP' = 'MXN', 'TipoCambioP' = 1
        // [THEN] 'Pagos/Pago/DoctoRelacionado' node has attributes 'Monto' = 161040.35, 'MonedaDR' = 'USD', 'EquivalenciaDR' = 0.0468493740
        // [THEN] TrasladoP nose has attributes BaseP = 138827.887926, ImpuestoP = 22212.462068
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        VerifyComplementoPagoAmountWithCurrency(
          OriginalStr,
          161040.35, 'MXN', '1',
          161040.35, Customer."Currency Code", '0.0468493740', 1258.6, 29);
        VerifyComplementoPagoTrasladoP(OriginalStr, 77, 138827.887926, 22212.462068, 0.16, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentFCYToSixFCYInvoicesWithCorrectionOfRemainingAmount()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATProdPostingGroup: Code[20];
        InvoiceNo: List of [Code[20]];
        PaymentNo: Code[20];
        OriginalStr: Text;
        FileName: Text;
    begin
        // [FEATURE] [Payment]
        // [SCENARIO 466899] Request stamp for FCY payment applied to six FCY invoices having 'correction of remaining amount' application entry
        Initialize();

        // [GIVEN] Six posted Sales Invoices in USD, VAT% = 16
        Customer.Get(CreateCustomer());
        Customer.Validate("Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1 / 19.489, 1 / 19.489));
        Customer.Modify(true);
        UpdateCustomerSATPaymentFields(Customer."No.");
        VATProdPostingGroup := CreateVATPostingSetup(Customer."VAT Bus. Posting Group", 16, false, false);
        // [GIVEN] Sales Invoice 1 with Amount = 864.00, Amount Incl VAT = 1002.24.60, Exch.Rate = 19.493
        InvoiceNo.Add(CreatePostSalesInvoiceWithCurrencyAmount(Customer."No.", VATProdPostingGroup, 1, 864, 19.493));
        // [GIVEN] Sales Invoice 2 with Amount = 3744.00, Amount Incl VAT = 4343.04, Exch.Rate = 19.493
        InvoiceNo.Add(CreatePostSalesInvoiceWithCurrencyAmount(Customer."No.", VATProdPostingGroup, 1, 3744, 19.493));
        // [GIVEN] Sales Invoice 3 with Amount = 3340.00, Amount Incl VAT = 3874.40, Exch.Rate = 19.493
        InvoiceNo.Add(CreatePostSalesInvoiceWithCurrencyAmount(Customer."No.", VATProdPostingGroup, 1, 3340, 19.493));
        // [GIVEN] Sales Invoice 4 with Amount = 3340.00, Amount Incl VAT = 3874.40, Exch.Rate = 19.493
        InvoiceNo.Add(CreatePostSalesInvoiceWithCurrencyAmount(Customer."No.", VATProdPostingGroup, 1, 3340, 19.493));
        // [GIVEN] Sales Invoice 5 with Amount = 12360.00, Amount Incl VAT = 14337.60, Exch.Rate = 19.4667
        InvoiceNo.Add(CreatePostSalesInvoiceWithCurrencyAmount(Customer."No.", VATProdPostingGroup, 1, 12360, 19.4667));
        // [GIVEN] Sales Invoice 6 with Amount = 6800.00, Amount Incl VAT = 7888.00, Exch.Rate = 19.4667
        InvoiceNo.Add(CreatePostSalesInvoiceWithCurrencyAmount(Customer."No.", VATProdPostingGroup, 1, 6800, 19.4667));

        // [GIVEN] The payment with Amount = -35319.68, Amount(LCY) = -688345.24 has been posted
        PaymentNo := CreatePostPayment(Customer."No.", '', -35319.68, Customer."Currency Code");

        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Invoice, PaymentNo, InvoiceNo.Get(1));
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Invoice, PaymentNo, InvoiceNo.Get(2));
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Invoice, PaymentNo, InvoiceNo.Get(3));
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Invoice, PaymentNo, InvoiceNo.Get(4));
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Invoice, PaymentNo, InvoiceNo.Get(5));
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Invoice, PaymentNo, InvoiceNo.Get(6));

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] 'Pagos/Totales' node has attribute 'MontoTotalPagos' = 688345.24
        // [THEN] 'Pagos/Pago' node created with attribute 'MonedaP' = 'USD', 'TipoCambioP' = 1
        // [THEN] 'Pagos/Pago/DoctoRelacionado' node has attributes 'Monto' = 35319.68, 'MonedaDR' = 'USD', 'EquivalenciaDR' = 1.0000000000 (TFS 503112)
        // [THEN] TrasladoP nose has attributes BaseP = 30448.000000, ImpuestoP = 4871.680000
        InitXMLReaderForPagos20(FileName);
        InitOriginalStringFromCustLedgerEntry(CustLedgerEntry, OriginalStr);

        VerifyComplementoPagoAmountWithCurrency(
          OriginalStr,
          688345.24, Customer."Currency Code", '19.489000',
          35319.68, Customer."Currency Code", '1.0000000000', 1002.24, 29);
        VerifyComplementoPagoTrasladoP(OriginalStr, 119, 30448.000000, 4871.680000, 0.16, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceRounding_LCYThreeLinesNoDiscount()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: array[3] of Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InStream: InStream;
        OriginalStr: Text;
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [Sales] [Rounding] [RoundingModel 1]
        // [SCENARIO 446557] Request Stamp for Sales Invoice with three lines
        Initialize();

        // [GIVEN] Posted Sales Invoice has 3 lines of Qty/Unit price:
        // [GIVEN] Line 1: 36/ 25.61, Line 2: 132/ 38.49, Line 3: 48/ 38.49
        Customer.Get(CreateCustomer());
        VATProdPostingGroup := CreateVATPostingSetup(Customer."VAT Bus. Posting Group", 16, false, false);
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItemWithVATSetup(SalesLine[1], SalesHeader, CreateItem(), VATProdPostingGroup, 36, 25.61, 0);
        CreateSalesLineItemWithVATSetup(SalesLine[2], SalesHeader, CreateItem(), VATProdPostingGroup, 132, 38.49, 0);
        CreateSalesLineItemWithVATSetup(SalesLine[3], SalesHeader, CreateItem(), VATProdPostingGroup, 48, 38.49, 0);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto' ValorUnitario, Importe, Descuento are exported
        VerifyLineAmountsByIndex(0, 921.96, 25.61, 147.5136, 921.96, 0);
        VerifyLineAmountsByIndex(0, 5080.68, 38.49, 812.9088, 5080.68, 1);
        VerifyLineAmountsByIndex(0, 1847.52, 38.49, 295.6032, 1847.52, 2);

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has VAT data for each line
        // [THEN] 1st line: 'Base' = 921.960000, 'Importe' = 147.513600.
        // [THEN] 2nd line: 'Base' = 5080.680000, 'Importe' = 812.908800.
        // [THEN] 3rd line: 'Base' = 1847.520000, 'Importe' = 295.603200.
        VerifyVATAmountLines(
          OriginalStr, 921.96, 147.5136, 16, '002', 0, 0);
        VerifyVATAmountLines(
          OriginalStr, 5080.68, 812.9088, 16, '002', 0, 1);
        VerifyVATAmountLines(
          OriginalStr, 1847.52, 295.6032, 16, '002', 0, 2);

        // [THEN] Total VAT line in 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has 'Importe' = 1256.03
        // [THEN] Total VAT Amount in 'cfdi:Impuestos/TotalImpuestosTrasladados' = 1256.03
        VerifyVATTotalLine(
          OriginalStr, 1256.03, 16, '002', 0, 3, 0);
        VerifyTotalImpuestos(
          OriginalStr, 'TotalImpuestosTrasladados', 1256.03, 72);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceRounding_LCYThreeLinesNoDiscountPricesInclVAT()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: array[3] of Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InStream: InStream;
        OriginalStr: Text;
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [Sales] [Rounding] [Prices Including VAT] [RoundingModel 1]
        // [SCENARIO 446557] Request Stamp for Sales Invoice with three lines and Prices Including VAT
        Initialize();

        // [GIVEN] Posted Sales Invoice with Prices Including VAT has 3 lines of Qty/Unit price:
        // [GIVEN] Line 1: 36/ 25.61, Line 2: 132/ 38.49, Line 3: 48/ 38.49
        Customer.Get(CreateCustomer());
        VATProdPostingGroup := CreateVATPostingSetup(Customer."VAT Bus. Posting Group", 16, false, false);
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);
        CreateSalesLineItemWithVATSetup(SalesLine[1], SalesHeader, CreateItem(), VATProdPostingGroup, 36, 25.61, 0);
        CreateSalesLineItemWithVATSetup(SalesLine[2], SalesHeader, CreateItem(), VATProdPostingGroup, 132, 38.49, 0);
        CreateSalesLineItemWithVATSetup(SalesLine[3], SalesHeader, CreateItem(), VATProdPostingGroup, 48, 38.49, 0);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto' ValorUnitario, Importe, Descuento are exported
        VerifyLineAmountsByIndex(0, 794.793103, 22.077586, 127.1664, 794.79, 0);
        VerifyLineAmountsByIndex(0, 4379.896552, 33.181034, 700.784, 4379.9, 1);
        VerifyLineAmountsByIndex(0, 1592.689655, 33.181034, 254.8304, 1592.69, 2);

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has VAT data for each line
        // [THEN] 1st line: 'Base' = 794.790000, 'Importe' = 127.166400.
        // [THEN] 2nd line: 'Base' = 4379.900000, 'Importe' = 700.784000.
        // [THEN] 3rd line: 'Base' = 1592.690000, 'Importe' = 254.830400.
        VerifyVATAmountLines(
          OriginalStr, 794.79, 127.1664, 16, '002', 0, 0);
        VerifyVATAmountLines(
          OriginalStr, 4379.9, 700.784, 16, '002', 0, 1);
        VerifyVATAmountLines(
          OriginalStr, 1592.69, 254.8304, 16, '002', 0, 2);

        // [THEN] Total VAT line in 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has 'Importe' = 1082.78
        // [THEN] Total VAT Amount in 'cfdi:Impuestos/TotalImpuestosTrasladados' = 1082.78
        VerifyVATTotalLine(
          OriginalStr, 1082.78, 16, '002', 0, 3, 0);
        VerifyTotalImpuestos(
          OriginalStr, 'TotalImpuestosTrasladados', 1082.78, 72);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceRounding_LCYThreeLinesDiscountInFirstLine()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: array[3] of Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InStream: InStream;
        OriginalStr: Text;
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [Sales] [Rounding] [RoundingModel 1]
        // [SCENARIO 446557] Request Stamp for Sales Invoice with three lines with discount in first line
        Initialize();

        // [GIVEN] Posted Sales Invoice has 3 lines of Qty/Unit price:
        // [GIVEN] Line 1: 36/ 25.61, Line Discount 10% Line 2: 132/ 38.49, Line 3: 48/ 38.49
        Customer.Get(CreateCustomer());
        VATProdPostingGroup := CreateVATPostingSetup(Customer."VAT Bus. Posting Group", 16, false, false);
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItemWithVATSetup(SalesLine[1], SalesHeader, CreateItem(), VATProdPostingGroup, 36, 25.61, 10);
        CreateSalesLineItemWithVATSetup(SalesLine[2], SalesHeader, CreateItem(), VATProdPostingGroup, 132, 38.49, 0);
        CreateSalesLineItemWithVATSetup(SalesLine[3], SalesHeader, CreateItem(), VATProdPostingGroup, 48, 38.49, 0);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto' ValorUnitario, Importe, Descuento are exported
        VerifyLineAmountsByIndex(92.2, 921.96, 25.61, 132.7616, 829.76, 0);
        VerifyLineAmountsByIndex(0, 5080.68, 38.49, 812.9088, 5080.68, 1);
        VerifyLineAmountsByIndex(0, 1847.52, 38.49, 295.6032, 1847.52, 2);

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has VAT data for each line
        // [THEN] 1st line: 'Base' = 829.760000, 'Importe' = 132.761600.
        // [THEN] 2nd line: 'Base' = 5080.680000, 'Importe' = 812.908800.
        // [THEN] 3rd line: 'Base' = 1847.520000, 'Importe' = 295.603200.
        VerifyVATAmountLines(
          OriginalStr, 829.76, 132.7616, 16, '002', 0, 0);
        VerifyVATAmountLines(
          OriginalStr, 5080.68, 812.9088, 16, '002', 0, 1);
        VerifyVATAmountLines(
          OriginalStr, 1847.52, 295.6032, 16, '002', 0, 2);

        // [THEN] Total VAT line in 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has 'Importe' = 1241.27
        // [THEN] Total VAT Amount in 'cfdi:Impuestos/TotalImpuestosTrasladados' = 1241.27
        VerifyVATTotalLine(
          OriginalStr, 1241.27, 16, '002', 0, 3, 0);
        VerifyTotalImpuestos(
          OriginalStr, 'TotalImpuestosTrasladados', 1241.27, 72);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceRounding_LCYThreeLinesDiscountInFirstLinePricesInclVAT()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: array[3] of Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InStream: InStream;
        OriginalStr: Text;
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [Sales] [Rounding] [RoundingModel 3]
        // [SCENARIO 446557] Request Stamp for Sales Invoice with three lines
        Initialize();

        // [GIVEN] Posted Sales Invoice with Prices Including VAT has 3 lines of Qty/Unit price:
        // [GIVEN] Line 1: 36/ 25.16, Line Discount 10%, Line 2: 132/ 38.39, Line 3: 48/ 38.39
        Customer.Get(CreateCustomer());
        VATProdPostingGroup := CreateVATPostingSetup(Customer."VAT Bus. Posting Group", 16, false, false);
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);
        CreateSalesLineItemWithVATSetup(SalesLine[1], SalesHeader, CreateItem(), VATProdPostingGroup, 36, 25.16, 10);
        CreateSalesLineItemWithVATSetup(SalesLine[2], SalesHeader, CreateItem(), VATProdPostingGroup, 132, 38.39, 0);
        CreateSalesLineItemWithVATSetup(SalesLine[3], SalesHeader, CreateItem(), VATProdPostingGroup, 48, 38.39, 0);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");

        InsertNameValueBufferRounding('2'); // RoundingModel::Model3-NoRecalculation

        // [WHEN] Request Stamp for the Sales Invoice
        BindSubscription(MXCFDI);
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        UnbindSubscription(MXCFDI);
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto' ValorUnitario, Importe, Descuento are exported
        VerifyLineAmountsByIndex(78.09, 780.83, 21.689655, 112.44, 702.74, 0);
        VerifyLineAmountsByIndex(0, 4368.52, 33.094828, 698.96, 4368.52, 1);
        VerifyLineAmountsByIndex(0, 1588.55, 33.094828, 254.17, 1588.55, 2);

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has VAT data for each line
        // [THEN] 1st line: 'Base' = 702.740000, 'Importe' = 112.440000.
        // [THEN] 2nd line: 'Base' = 4368.520000, 'Importe' = 698.960000.
        // [THEN] 3rd line: 'Base' = 1588.550000, 'Importe' = 254.170000.
        VerifyVATAmountLines(
          OriginalStr, 702.74, 112.44, 16, '002', 0, 0);
        VerifyVATAmountLines(
          OriginalStr, 4368.52, 698.96, 16, '002', 0, 1);
        VerifyVATAmountLines(
          OriginalStr, 1588.55, 254.17, 16, '002', 0, 2);

        // [THEN] Total VAT line in 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has 'Importe' = 1065.57
        // [THEN] Total VAT Amount in 'cfdi:Impuestos/TotalImpuestosTrasladados' = 1065.57
        VerifyVATTotalLine(
          OriginalStr, 1065.57, 16, '002', 0, 3, 0);
        VerifyTotalImpuestos(
          OriginalStr, 'TotalImpuestosTrasladados', 1065.57, 72);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceRounding_LCYTwoIdenticalLinesWithDiscount()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InStream: InStream;
        OriginalStr: Text;
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [Sales] [Rounding] [RoundingModel 1]
        // [SCENARIO 446557] Request Stamp for Sales Invoice with two identical lines with line discount
        Initialize();

        // [GIVEN] Posted Sales Invoice has 2 lines of Qty = 1, Unit price = 57061.35, Line Discount = 15%,
        Customer.Get(CreateCustomer());
        VATProdPostingGroup := CreateVATPostingSetup(Customer."VAT Bus. Posting Group", 16, false, false);
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItemWithVATSetup(SalesLine1, SalesHeader, CreateItem(), VATProdPostingGroup, 1, 57061.35, 15);
        CreateSalesLineItemWithVATSetup(SalesLine2, SalesHeader, CreateItem(), VATProdPostingGroup, 1, 57061.35, 15);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto' ValorUnitario, Importe, Descuento are exported
        VerifyLineAmountsByIndex(8559.2, 57061.35, 57061.35, 7760.344, 48502.15, 0);
        VerifyLineAmountsByIndex(8559.2, 57061.35, 57061.35, 7760.344, 48502.15, 1);

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has VAT data for each line
        // [THEN] 1st line: 'Base' = 48502.150000, 'Importe' = 7760.344000.
        // [THEN] 2nd line: 'Base' = 48502.150000, 'Importe' = 7760.344000.
        VerifyVATAmountLines(
          OriginalStr, 48502.15, 7760.344, 16, '002', 0, 0);
        VerifyVATAmountLines(
          OriginalStr, 48502.15, 7760.344, 16, '002', 0, 1);

        // [THEN] Total VAT line in 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has 'Importe' = 15520.69
        // [THEN] Total VAT Amount in 'cfdi:Impuestos/TotalImpuestosTrasladados' = 15520.69
        VerifyVATTotalLine(
          OriginalStr, 15520.69, 16, '002', 0, 2, 0);
        VerifyTotalImpuestos(
          OriginalStr, 'TotalImpuestosTrasladados', 15520.69, 57);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceRounding_LCYTwoIdenticalLinesWithDecimalDiscount()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InStream: InStream;
        OriginalStr: Text;
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [Sales] [Rounding] [RoundingModel 2]
        // [SCENARIO 446557] Request Stamp for Sales Invoice with two identical lines with decimal line discount
        Initialize();

        // [GIVEN] Posted Sales Invoice has 2 lines of Qty = 1.25, Unit price = 100696.50, Line Discount % = 2.10484
        Customer.Get(CreateCustomer());
        VATProdPostingGroup := CreateVATPostingSetup(Customer."VAT Bus. Posting Group", 16, false, false);
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItemWithVATSetup(SalesLine1, SalesHeader, CreateItem(), VATProdPostingGroup, 1.25, 100696.5, 2.10484);
        CreateSalesLineItemWithVATSetup(SalesLine2, SalesHeader, CreateItem(), VATProdPostingGroup, 1.25, 100696.5, 2.10484);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");

        InsertNameValueBufferRounding('1'); // RoundingModel::Model2-Recalc-NoDiscountRounding

        // [WHEN] Request Stamp for the Sales Invoice
        BindSubscription(MXCFDI);
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        UnbindSubscription(MXCFDI);
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto' ValorUnitario, Importe, Descuento are exported
        VerifyLineAmountsByIndex(2649.375263, 125870.625, 100696.5, 19715.4, 123221.25, 0);
        VerifyLineAmountsByIndex(2649.375263, 125870.625, 100696.5, 19715.4, 123221.25, 1);

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has VAT data for each line
        // [THEN] 1st line: 'Base' = 123221.250000, 'Importe' = 19715.400000.
        // [THEN] 2nd line: 'Base' = 123221.250000, 'Importe' = 19715.400000.
        VerifyVATAmountLines(
          OriginalStr, 123221.25, 19715.4, 16, '002', 0, 0);
        VerifyVATAmountLines(
          OriginalStr, 123221.25, 19715.4, 16, '002', 0, 1);

        // [THEN] Total VAT line in 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has 'Importe' = 39430.80
        // [THEN] Total VAT Amount in 'cfdi:Impuestos/TotalImpuestosTrasladados' = 39430.80
        VerifyVATTotalLine(
          OriginalStr, 39430.8, 16, '002', 0, 2, 0);
        VerifyTotalImpuestos(
          OriginalStr, 'TotalImpuestosTrasladados', 39430.8, 57);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceRounding_LCYTwoIdenticalLinesWithDecimalDiscountPricesInclVAT()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InStream: InStream;
        OriginalStr: Text;
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [Sales] [Rounding] [RoundingModel 2]
        // [SCENARIO 446557] Request Stamp for Sales Invoice with two identical lines with line discount
        Initialize();

        // [GIVEN] Posted Sales Invoice with Prices Including VAT
        // [GIVEN] 2 lines of Qty = 1.25, Unit price = 100696.50, Line Discount % = 2.10484
        Customer.Get(CreateCustomer());
        VATProdPostingGroup := CreateVATPostingSetup(Customer."VAT Bus. Posting Group", 16, false, false);
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);
        CreateSalesLineItemWithVATSetup(SalesLine1, SalesHeader, CreateItem(), VATProdPostingGroup, 1.25, 116807.94, 2.10484);
        CreateSalesLineItemWithVATSetup(SalesLine2, SalesHeader, CreateItem(), VATProdPostingGroup, 1.25, 116807.94, 2.10484);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");

        InsertNameValueBufferRounding('1'); // RoundingModel::Model2-Recalc-NoDiscountRounding

        // [WHEN] Request Stamp for the Sales Invoice
        BindSubscription(MXCFDI);
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        UnbindSubscription(MXCFDI);
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto' ValorUnitario, Importe, Descuento are exported
        VerifyLineAmountsByIndex(2649.375263, 125870.625, 100696.5, 19715.4, 123221.25, 0);
        VerifyLineAmountsByIndex(2649.375263, 125870.625, 100696.5, 19715.4, 123221.25, 1);

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has VAT data for each line
        // [THEN] 1st line: 'Base' = 123221.250000, 'Importe' = 19715.400000.
        // [THEN] 2nd line: 'Base' = 123221.250000, 'Importe' = 19715.400000.
        VerifyVATAmountLines(
          OriginalStr, 123221.25, 19715.4, 16, '002', 0, 0);
        VerifyVATAmountLines(
          OriginalStr, 123221.25, 19715.4, 16, '002', 0, 1);

        // [THEN] Total VAT line in 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has 'Importe' = 39430.80
        // [THEN] Total VAT Amount in 'cfdi:Impuestos/TotalImpuestosTrasladados' = 39430.80
        VerifyVATTotalLine(
          OriginalStr, 39430.8, 16, '002', 0, 2, 0);
        VerifyTotalImpuestos(
          OriginalStr, 'TotalImpuestosTrasladados', 39430.8, 57);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceRounding_FCYFourLinesNoDiscount()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: array[4] of Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InStream: InStream;
        OriginalStr: Text;
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [Sales] [Rounding] [RoundingModel 3]
        // [SCENARIO 446557] Request Stamp for Sales Invoice USD with four lines
        Initialize();

        // [GIVEN] Posted Sales Invoice USD has 4 lines of Qty/Unit price:
        // [GIVEN] Line 1: 1.25/ 3221.99, Line 2: 1/ 3221.99, Line 3: 1/ 3221.99, Line 4: 1.5/ 3221.99
        Customer.Get(CreateCustomer());
        Customer.Validate(
          "Currency Code", LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1 / 8.9991, 1 / 8.9991));
        Customer.Modify(true);
        VATProdPostingGroup := CreateVATPostingSetup(Customer."VAT Bus. Posting Group", 16, false, false);
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItemWithVATSetup(SalesLine[1], SalesHeader, CreateItem(), VATProdPostingGroup, 1.25, 3221.99, 0);
        CreateSalesLineItemWithVATSetup(SalesLine[2], SalesHeader, CreateItem(), VATProdPostingGroup, 1, 3221.99, 0);
        CreateSalesLineItemWithVATSetup(SalesLine[3], SalesHeader, CreateItem(), VATProdPostingGroup, 1, 3221.99, 0);
        CreateSalesLineItemWithVATSetup(SalesLine[4], SalesHeader, CreateItem(), VATProdPostingGroup, 1.5, 3221.99, 0);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");

        InsertNameValueBufferRounding('2'); // RoundingModel::Model3-NoRecalculation

        // [WHEN] Request Stamp for the Sales Invoice
        BindSubscription(MXCFDI);
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        UnbindSubscription(MXCFDI);
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto' ValorUnitario, Importe, Descuento are exported
        VerifyLineAmountsByIndex(0, 4027.49, 3221.99, 644.4, 4027.49, 0);
        VerifyLineAmountsByIndex(0, 3221.99, 3221.99, 515.52, 3221.99, 1);
        VerifyLineAmountsByIndex(0, 3221.99, 3221.99, 515.51, 3221.99, 2);
        VerifyLineAmountsByIndex(0, 4832.99, 3221.99, 773.28, 4832.99, 3);

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has VAT data for each line
        // [THEN] 1st line: 'Base' = 4027.490000, 'Importe' = 644.400000.
        // [THEN] 2nd line: 'Base' = 3221.990000, 'Importe' = 515.520000.
        // [THEN] 3rd line: 'Base' = 3221.990000, 'Importe' = 515.510000.
        // [THEN] 4th line: 'Base' = 4832.990000, 'Importe' = 773.280000.
        VerifyVATAmountLines(
          OriginalStr, 4027.49, 644.4, 16, '002', 1, 0);
        VerifyVATAmountLines(
          OriginalStr, 3221.99, 515.52, 16, '002', 1, 1);
        VerifyVATAmountLines(
          OriginalStr, 3221.99, 515.51, 16, '002', 1, 2);
        VerifyVATAmountLines(
          OriginalStr, 4832.99, 773.28, 16, '002', 1, 3);

        // [THEN] Total VAT line in 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has 'Importe' = 2448.71
        // [THEN] Total VAT Amount in 'cfdi:Impuestos/TotalImpuestosTrasladados' = 2448.71
        VerifyVATTotalLine(
          OriginalStr, 2448.71, 16, '002', 0, 4, 1);
        VerifyTotalImpuestos(
          OriginalStr, 'TotalImpuestosTrasladados', 2448.71, 88);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceRounding_FCYOneLineDecimalPrice()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InStream: InStream;
        OriginalStr: Text;
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [Sales] [Rounding] [RoundingModel 1]
        // [SCENARIO 446557] Request Stamp for Sales Invoice USD line having decimal price
        Initialize();

        // [GIVEN] Posted Sales Invoice USD Qty = 1, Unit price = 444.489
        Customer.Get(CreateCustomer());
        Customer.Validate(
          "Currency Code", LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1 / 8.9991, 1 / 8.9991));
        Customer.Modify(true);
        VATProdPostingGroup := CreateVATPostingSetup(Customer."VAT Bus. Posting Group", 16, false, false);
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItemWithVATSetup(SalesLine, SalesHeader, CreateItem(), VATProdPostingGroup, 1, 444.489, 0);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto' ValorUnitario, Importe, Descuento are exported
        VerifyLineAmountsByIndex(0, 444.489, 444.489, 71.1184, 444.49, 0);

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has VAT data for each line
        // [THEN] 'Base' = 444.490000, 'Importe' = 71.118400.
        VerifyVATAmountLines(
          OriginalStr, 444.49, 71.1184, 16, '002', 1, 0);

        // [THEN] Total VAT line in 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has 'Importe' = 71.12
        // [THEN] Total VAT Amount in 'cfdi:Impuestos/TotalImpuestosTrasladados' = 71.12
        VerifyVATTotalLine(
          OriginalStr, 71.12, 16, '002', 0, 1, 1);
        VerifyTotalImpuestos(
          OriginalStr, 'TotalImpuestosTrasladados', 71.12, 43);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceRounding_LCYFourLinesDecimalQuantityWithDiscount()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: array[4] of Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InStream: InStream;
        OriginalStr: Text;
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [Sales] [Rounding]
        // [SCENARIO 446557] Request Stamp for Sales Invoice with four lines and line discount
        Initialize();

        // [GIVEN] Posted Sales Invoice
        Customer.Get(CreateCustomer());
        VATProdPostingGroup := CreateVATPostingSetup(Customer."VAT Bus. Posting Group", 16, false, false);
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItemWithVATSetup(SalesLine[1], SalesHeader, CreateItem(), VATProdPostingGroup, 2, 99.0, 0);
        CreateSalesLineItemWithVATSetup(SalesLine[2], SalesHeader, CreateItem(), VATProdPostingGroup, 137.891, 9.95, 0);
        CreateSalesLineItemWithVATSetup(SalesLine[3], SalesHeader, CreateItem(), VATProdPostingGroup, 116.857, 7.3, 0);
        CreateSalesLineItemWithVATSetup(SalesLine[4], SalesHeader, CreateItem(), VATProdPostingGroup, 7, 1959.0, 10);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InsertNameValueBufferRounding('3'); // RoundingModel::Model4-DecimalBased

        // [WHEN] Request Stamp for the Sales Invoice
        BindSubscription(MXCFDI);
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        UnbindSubscription(MXCFDI);
        NameValueBuffer.Delete();
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", "Signed Document XML");

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto' ValorUnitario, Importe, Descuento are exported
        VerifyLineAmountsByIndex(0, 198.0, 99.0, 31.68, 198.0, 0);
        VerifyLineAmountsByIndex(0, 1372.02, 9.95, 219.5232, 1372.02, 1);
        VerifyLineAmountsByIndex(0, 853.056, 7.3, 136.48896, 853.056, 2);
        VerifyLineAmountsByIndex(1371.3, 13713.0, 1959.0, 1974.672, 12341.7, 3);

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has VAT data for each line
        // [THEN] 1st line: 'Base' = 198.000000, 'Importe' = 31.680000.
        // [THEN] 2nd line: 'Base' = 1372.020000, 'Importe' = 219.523200.
        // [THEN] 3rd line: 'Base' = 853.056000, 'Importe' = 136.488960.
        // [THEN] 4th line: 'Base' = 12341.700000, 'Importe' = 1974.672000.
        VerifyVATAmountLines(OriginalStr, 198.0, 31.68, 16, '002', 0, 0);
        VerifyVATAmountLines(OriginalStr, 1372.02, 219.5232, 16, '002', 0, 1);
        VerifyVATAmountLines(OriginalStr, 853.056, 136.48896, 16, '002', 0, 2);
        VerifyVATAmountLines(OriginalStr, 12341.7, 1974.672, 16, '002', 0, 3);

        // [THEN] Total VAT line in 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has 'Importe' = 2362.36
        // [THEN] Total VAT Amount in 'cfdi:Impuestos/TotalImpuestosTrasladados' = 2362.36
        VerifyVATTotalLine(
          OriginalStr, 2362.36, 16, '002', 0, 4, 0);
        VerifyTotalImpuestos(
          OriginalStr, 'TotalImpuestosTrasladados', 2362.36, 87);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceRounding_LCYTreeLinesDecimalQuantity()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: array[3] of Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InStream: InStream;
        OriginalStr: Text;
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [Sales] [Rounding]
        // [SCENARIO 472193] Request Stamp for Sales Invoice with three lines
        Initialize();

        // [GIVEN] Posted Sales Invoice with next Qty/Unit price.
        // [GIVEN] Line 1: 1796.256/ 7.44, Line 2: 771.12/ 5.70, Line 3: 680.4/ 4.35
        Customer.Get(CreateCustomer());
        VATProdPostingGroup := CreateVATPostingSetup(Customer."VAT Bus. Posting Group", 16, false, false);
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItemWithVATSetup(SalesLine[1], SalesHeader, CreateItem(), VATProdPostingGroup, 1796.256, 7.44, 0);
        CreateSalesLineItemWithVATSetup(SalesLine[2], SalesHeader, CreateItem(), VATProdPostingGroup, 771.12, 5.7, 0);
        CreateSalesLineItemWithVATSetup(SalesLine[3], SalesHeader, CreateItem(), VATProdPostingGroup, 680.4, 4.35, 0);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InsertNameValueBufferRounding('3'); // RoundingModel::Model4-DecimalBased

        // [WHEN] Request Stamp for the Sales Invoice
        BindSubscription(MXCFDI);
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        UnbindSubscription(MXCFDI);
        NameValueBuffer.Delete();
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", "Signed Document XML");

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto' ValorUnitario, Importe, Descuento are exported
        VerifyLineAmountsByIndex(0, 13364.144, 7.44, 2138.26304, 13364.144, 0);
        VerifyLineAmountsByIndex(0, 4395.38, 5.7, 703.2608, 4395.38, 1);
        VerifyLineAmountsByIndex(0, 2959.74, 4.35, 473.5584, 2959.74, 2);

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has VAT data for each line
        // [THEN] 1st line: 'Base' = 13364.144000, 'Importe' = 2138.263040.
        // [THEN] 2nd line: 'Base' = 4395.380000, 'Importe' = 703.260800.
        // [THEN] 3rd line: 'Base' = 2959.740000, 'Importe' = 473.558400.
        VerifyVATAmountLines(OriginalStr, 13364.144, 2138.26304, 16, '002', 0, 0);
        VerifyVATAmountLines(OriginalStr, 4395.38, 703.2608, 16, '002', 0, 1);
        VerifyVATAmountLines(OriginalStr, 2959.74, 473.5584, 16, '002', 0, 2);

        // [THEN] Total VAT line in 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has 'Importe' = 3315.08
        // [THEN] Total VAT Amount in 'cfdi:Impuestos/TotalImpuestosTrasladados' = 3315.08
        VerifyVATTotalLine(
          OriginalStr, 3315.08, 16, '002', 0, 3, 0);
        VerifyTotalImpuestos(
          OriginalStr, 'TotalImpuestosTrasladados', 3315.08, 72);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithRelationDocumentsRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesHeader: Record "Sales Header";
        CFDIRelationDocument: array[3] of Record "CFDI Relation Document";
        InStream: InStream;
        OriginalStr: Text;
        EncodedDescr: Text;
        i: Integer;
    begin
        // [FEATURE] [Sales] [CFDI Relation]
        // [SCENARIO 319131] Request Stamp for Sales Invoice with multiple CFDI Related Documents
        Initialize();

        // [GIVEN] Posted Sales Invoice where CFDI Relation Documents has Fiscal Invoice Numbers "UUID1", "UUID2", "UUID3" for CFDI Relation = '04'
        SalesInvoiceHeader.Get(
          CreateAndPostSalesDoc(SalesHeader."Document Type"::Invoice, CreatePaymentMethodForSAT()));

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.Description := '"Reparación de   lavadora"&''<> ';
        SalesInvoiceLine.Modify();
        EncodedDescr := '&quot;Reparaci&#243;n de lavadora&quot;&amp;&#39;&lt;&gt;';

        for i := 1 to ArrayLen(CFDIRelationDocument) do
            CreateCFDIRelationDocument(
              CFDIRelationDocument[i], DATABASE::"Sales Invoice Header", 0, SalesInvoiceHeader."No.",
              SalesInvoiceHeader."Bill-to Customer No.", LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", "Signed Document XML");

        // [THEN] XML Document has attribute 'TipoRelacion' = '04' under 'cfdi:CfdiRelacionados'
        // [THEN] XML Document has node 'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado' with attributes 'UUID' of "UUID1", "UUID2", "UUID3"
        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:CfdiRelacionados', 'TipoRelacion', SalesInvoiceHeader."CFDI Relation");
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
              'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', CFDIRelationDocument[i]."Fiscal Invoice Number PAC", i - 1);
        // [THEN] XML Document has node 'cfdi:Conceptos/cfdi:Concepto' with Descrition containing encoded special characters (TFS327477)
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Conceptos/cfdi:Concepto', 'Descripcion', EncodedDescr);

        // [THEN] String for digital stamp has CFDI Relation = '04' following by Fiscal Invoices Numbers "UUID1", "UUID2", "UUID3"
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        Assert.AreEqual(
          SalesInvoiceHeader."CFDI Relation", SelectStr(15, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, SalesInvoiceHeader.FieldCaption("CFDI Relation"), OriginalStr));
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            Assert.AreEqual(
              CFDIRelationDocument[i]."Fiscal Invoice Number PAC", SelectStr(15 + i, OriginalStr),
              StrSubstNo(IncorrectOriginalStrValueErr, CFDIRelationDocument[i]."Fiscal Invoice Number PAC", OriginalStr));
        // [THEN] String for digital stamp contains Descrition with encoded special characters (TFS327477)
        Assert.AreEqual(
          EncodedDescr, SelectStr(32, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, SalesInvoiceLine.FieldCaption(Description), OriginalStr));
        // [THEN] "Date/Time First Req. Sent" is created in current time zone (TFS 323341) (TFS 522707)
        // VerifyIsNearlyEqualDateTime(
        //  ConvertTxtToDateTime(SalesInvoiceHeader."Date/Time First Req. Sent"),
        //  CreateDateTime(SalesInvoiceHeader."Document Date", Time));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoAppliedToInvoiceRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [Sales] [CFDI Relation]
        // [SCENARIO 319131] Request Stamp for Sales Credit Memo applied to Sales Invoice
        Initialize();

        // [GIVEN] Posted and stamped Sales Invoice with Fiscal Invoice Number = "UUID-Inv"
        SalesInvoiceHeader.Get(
          CreateAndPostSalesDoc(SalesHeader."Document Type"::Invoice, CreatePaymentMethodForSAT()));
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();

        // [GIVEN] Posted Sales Credit Memo applied to the Sales Invoice
        SalesCrMemoHeader.Get(CreatePostApplySalesCrMemo(SalesInvoiceHeader."Bill-to Customer No.", SalesInvoiceHeader."No."));

        // [WHEN] Request Stamp for the Credit Memo
        RequestStamp(
          DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesCrMemoHeader.Find();
        SalesCrMemoHeader.CalcFields("Original String", "Original Document XML", "Signed Document XML");

        // [THEN] XML Document has attribute 'TipoRelacion' from CFDI Relation of Credit Memo under 'cfdi:CfdiRelacionados'
        // [THEN] XML Document has node 'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado' with attribute 'UUID' of "UUID-Inv"
        InitXMLReaderForSalesDocumentCFDI(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:CfdiRelacionados', 'TipoRelacion', SalesInvoiceHeader."CFDI Relation");
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', SalesInvoiceHeader."Fiscal Invoice Number PAC");

        // [THEN] String for digital stamp has CFDI Relation = from Credit Memo following by Fiscal Invoices Numbers "UUID-Inv"
        SalesCrMemoHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        Assert.AreEqual(
          SalesInvoiceHeader."CFDI Relation", SelectStr(15, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, SalesCrMemoHeader.FieldCaption("CFDI Relation"), OriginalStr));
        Assert.AreEqual(
          SalesInvoiceHeader."Fiscal Invoice Number PAC", SelectStr(16, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, SalesInvoiceHeader."Fiscal Invoice Number PAC", OriginalStr));
        // [THEN] "Date/Time First Req. Sent" is created in current time zone (TFS 323341) (TFS 522707)
        // VerifyIsNearlyEqualDateTime(
        //  ConvertTxtToDateTime(SalesCrMemoHeader."Date/Time First Req. Sent"),
        //  CreateDateTime(SalesCrMemoHeader."Document Date", Time));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemosWithRelationAppliedToInvoiceRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CFDIRelationDocument: array[3] of Record "CFDI Relation Document";
        InStream: InStream;
        OriginalStr: Text;
        i: Integer;
    begin
        // [FEATURE] [Sales] [CFDI Relation]
        // [SCENARIO 334952] Request Stamp for Sales Credit Memo applied to Sales Invoice with multiple CFDI Related Documents
        Initialize();

        // [GIVEN] Posted and stamped Sales Invoice with Fiscal Invoice Number = "UUID-Inv"
        SalesInvoiceHeader.Get(
          CreateAndPostSalesDoc(SalesHeader."Document Type"::Invoice, CreatePaymentMethodForSAT()));
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();

        // [GIVEN] Posted Sales Credit Memo applied to the Sales Invoice
        SalesCrMemoHeader.Get(
          CreatePostApplySalesCrMemo(SalesInvoiceHeader."Bill-to Customer No.", SalesInvoiceHeader."No."));

        // [GIVEN] CFDI Relation Documents has Fiscal Invoice Numbers "UUID1", "UUID2", "UUID3"
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            CreateCFDIRelationDocument(
              CFDIRelationDocument[i], DATABASE::"Sales Cr.Memo Header", 0, SalesCrMemoHeader."No.",
              SalesCrMemoHeader."Bill-to Customer No.", LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [WHEN] Request Stamp for the Credit Memo
        RequestStamp(
          DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesCrMemoHeader.Find();
        SalesCrMemoHeader.CalcFields("Original String", "Original Document XML", "Signed Document XML");

        // [THEN] XML Document has node 'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado' with 'UUID's of "UUID-Inv", "UUID1", "UUID2", "UUID3"
        InitXMLReaderForSalesDocumentCFDI(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', SalesInvoiceHeader."Fiscal Invoice Number PAC");
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
              'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', CFDIRelationDocument[i]."Fiscal Invoice Number PAC", i);

        // [THEN] String for digital stamp has Fiscal Invoices Numbers "UUID-Inv", "UUID1", "UUID2", "UUID3"
        SalesCrMemoHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        Assert.AreEqual(
          SalesInvoiceHeader."Fiscal Invoice Number PAC", SelectStr(16, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, SalesInvoiceHeader."Fiscal Invoice Number PAC", OriginalStr));
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            Assert.AreEqual(
              CFDIRelationDocument[i]."Fiscal Invoice Number PAC", SelectStr(17 + i, OriginalStr),
              StrSubstNo(IncorrectOriginalStrValueErr, CFDIRelationDocument[i]."Fiscal Invoice Number PAC", OriginalStr));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoAppliedToAnotherInvoiceRequestStamp()
    var
        SalesInvoiceHeader1: Record "Sales Invoice Header";
        SalesInvoiceHeader2: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 372201] Request Stamp for Sales Credit Memo applied to Sales Invoice not equal to Applied-to Doc No.
        Initialize();

        // [GIVEN] Posted and stamped two Sales Invoices with Fiscal Invoice Number = "UUID-Inv1", "UUID-Inv2"
        SalesInvoiceHeader1.Get(
          CreateAndPostSalesDoc(SalesHeader."Document Type"::Invoice, CreatePaymentMethodForSAT()));
        SalesHeader.Get(
          SalesHeader."Document Type"::Invoice,
          CreateSalesDocForCustomer(
            SalesHeader."Document Type"::Invoice, SalesInvoiceHeader1."Bill-to Customer No.", CreatePaymentMethodForSAT()));
        SalesInvoiceHeader2.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader2."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader2.Find();

        // [GIVEN] Posted Sales Credit Memo applied to the Sales Invoice 1, unapplied and applied to Sales Invoice 2
        SalesCrMemoHeader.Get(CreatePostApplySalesCrMemo(SalesInvoiceHeader1."Bill-to Customer No.", SalesInvoiceHeader1."No."));
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", SalesCrMemoHeader."No.");
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::"Credit Memo", CustLedgerEntry."Document Type"::Invoice,
          SalesCrMemoHeader."No.", SalesInvoiceHeader2."No.");

        // [WHEN] Request Stamp for the Credit Memo
        RequestStamp(
          DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesCrMemoHeader.Find();
        SalesCrMemoHeader.CalcFields("Original String", "Original Document XML");

        // [THEN] XML Document has node 'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado' with attribute 'UUID' of "UUID-Inv2"
        InitXMLReaderForSalesDocumentCFDI(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', SalesInvoiceHeader2."Fiscal Invoice Number PAC");

        // [THEN] String for digital stamp has Fiscal Invoice Numbers "UUID-Inv2" of Sales Invoice 2
        SalesCrMemoHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        Assert.AreEqual(
          SalesInvoiceHeader2."Fiscal Invoice Number PAC", SelectStr(16, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, SalesInvoiceHeader2."Fiscal Invoice Number PAC", OriginalStr));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithRelationsAppliedToInvoiceInRelationsRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CFDIRelationDocument: array[3] of Record "CFDI Relation Document";
        CFDIRelationDocumentInv: Record "CFDI Relation Document";
        InStream: InStream;
        OriginalStr: Text;
        i: Integer;
    begin
        // [FEATURE] [Sales] [CFDI Relation]
        // [SCENARIO 334952] Request Stamp for Sales Credit Memo applied to Sales Invoice with multiple CFDI Related Documents
        // [SCENARIO 334952] and the Invoice is included in Related Documents
        Initialize();

        // [GIVEN] Posted and stamped Sales Invoice with Fiscal Invoice Number = "UUID-Inv"
        SalesInvoiceHeader.Get(
          CreateAndPostSalesDoc(SalesHeader."Document Type"::Invoice, CreatePaymentMethodForSAT()));
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();

        // [GIVEN] Posted Sales Credit Memo applied to the Sales Invoice
        SalesCrMemoHeader.Get(
          CreatePostApplySalesCrMemo(SalesInvoiceHeader."Bill-to Customer No.", SalesInvoiceHeader."No."));

        // [GIVEN] CFDI Relation Documents has Fiscal Invoice Numbers "UUID1", "UUID2", "UUID3"
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            CreateCFDIRelationDocument(
              CFDIRelationDocument[i], DATABASE::"Sales Cr.Memo Header", 0, SalesCrMemoHeader."No.",
              SalesCrMemoHeader."Bill-to Customer No.", LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());
        // [GIVEN] CFDI Relation Documents has Sales Invoice with "UUID-Inv"
        CreateCFDIRelationDocument(
          CFDIRelationDocumentInv, DATABASE::"Sales Cr.Memo Header", 0, SalesCrMemoHeader."No.",
          SalesCrMemoHeader."Bill-to Customer No.", SalesInvoiceHeader."No.", SalesInvoiceHeader."Fiscal Invoice Number PAC");

        // [WHEN] Request Stamp for the Credit Memo
        RequestStamp(
          DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesCrMemoHeader.Find();
        SalesCrMemoHeader.CalcFields("Original String", "Original Document XML", "Signed Document XML");

        // [THEN] XML Document has node 'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado' with 'UUID's of "UUID-Inv", "UUID1", "UUID2", "UUID3"
        InitXMLReaderForSalesDocumentCFDI(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', SalesInvoiceHeader."Fiscal Invoice Number PAC");
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
              'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', CFDIRelationDocument[i]."Fiscal Invoice Number PAC", i);

        // [THEN] String for digital stamp has Fiscal Invoices Numbers "UUID-Inv", "UUID1", "UUID2", "UUID3"
        SalesCrMemoHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        Assert.AreEqual(
          SalesInvoiceHeader."Fiscal Invoice Number PAC", SelectStr(16, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, SalesInvoiceHeader."Fiscal Invoice Number PAC", OriginalStr));
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            Assert.AreEqual(
              CFDIRelationDocument[i]."Fiscal Invoice Number PAC", SelectStr(16 + i, OriginalStr),
              StrSubstNo(IncorrectOriginalStrValueErr, CFDIRelationDocument[i]."Fiscal Invoice Number PAC", OriginalStr));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemosWithRelationAppliedToInvoiceRequestStamp()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CFDIRelationDocument: array[3] of Record "CFDI Relation Document";
        InStream: InStream;
        OriginalStr: Text;
        i: Integer;
    begin
        // [FEATURE] [Service] [CFDI Relation]
        // [SCENARIO 334952] Request Stamp for Service Credit Memo applied to Service Invoice with multiple CFDI Related Documents
        Initialize();

        // [GIVEN] Posted and stamped Service Invoice with Fiscal Invoice Number = "UUID-Inv"
        ServiceInvoiceHeader.Get(
          CreateAndPostServiceDoc(ServiceHeader."Document Type"::Invoice, CreatePaymentMethodForSAT()));
        RequestStamp(
          DATABASE::"Service Invoice Header", ServiceInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        ServiceInvoiceHeader.Find();

        // [GIVEN] Posted Service Credit Memo applied to the Service Invoice
        ServiceCrMemoHeader.Get(
          CreatePostApplyServiceCrMemo(ServiceInvoiceHeader."Bill-to Customer No.", ServiceInvoiceHeader."No."));

        // [GIVEN] CFDI Relation Documents has Fiscal Invoice Numbers "UUID1", "UUID2", "UUID3"
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            CreateCFDIRelationDocument(
              CFDIRelationDocument[i], DATABASE::"Service Cr.Memo Header", 0, ServiceCrMemoHeader."No.",
              ServiceCrMemoHeader."Bill-to Customer No.", LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [WHEN] Request Stamp for the Credit Memo
        RequestStamp(
          DATABASE::"Service Cr.Memo Header", ServiceCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        ServiceCrMemoHeader.Find();
        ServiceCrMemoHeader.CalcFields("Original String", "Original Document XML", "Signed Document XML");

        // [THEN] XML Document has node 'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado' with 'UUID's of "UUID-Inv", "UUID1", "UUID2", "UUID3"
        InitXMLReaderForSalesDocumentCFDI(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("Original Document XML"));
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
              'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', CFDIRelationDocument[i]."Fiscal Invoice Number PAC", i);
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', ServiceInvoiceHeader."Fiscal Invoice Number PAC", 0);

        // [THEN] String for digital stamp has Fiscal Invoices Numbers "UUID-Inv", "UUID1", "UUID2", "UUID3"
        ServiceCrMemoHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            Assert.AreEqual(
              CFDIRelationDocument[i]."Fiscal Invoice Number PAC", SelectStr(17 + i, OriginalStr),
              StrSubstNo(IncorrectOriginalStrValueErr, CFDIRelationDocument[i]."Fiscal Invoice Number PAC", OriginalStr));
        Assert.AreEqual(
          ServiceInvoiceHeader."Fiscal Invoice Number PAC", SelectStr(16, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, ServiceInvoiceHeader."Fiscal Invoice Number PAC", OriginalStr));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoWithRelationsAppliedToInvoiceInRelationsRequestStamp()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CFDIRelationDocument: array[3] of Record "CFDI Relation Document";
        CFDIRelationDocumentInv: Record "CFDI Relation Document";
        InStream: InStream;
        OriginalStr: Text;
        i: Integer;
    begin
        // [FEATURE] [Service]
        // [SCENARIO 334952] Request Stamp for Service Credit Memo applied to Service Invoice with multiple CFDI Related Documents
        // [SCENARIO 334952] and the Invoice is included in Related Documents
        Initialize();

        // [GIVEN] Posted and stamped Service Invoice with Fiscal Invoice Number = "UUID-Inv"
        ServiceInvoiceHeader.Get(
          CreateAndPostServiceDoc(ServiceHeader."Document Type"::Invoice, CreatePaymentMethodForSAT()));
        RequestStamp(
          DATABASE::"Service Invoice Header", ServiceInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        ServiceInvoiceHeader.Find();

        // [GIVEN] Posted Service Credit Memo applied to the Service Invoice
        ServiceCrMemoHeader.Get(
          CreatePostApplyServiceCrMemo(ServiceInvoiceHeader."Bill-to Customer No.", ServiceInvoiceHeader."No."));

        // [GIVEN] CFDI Relation Documents has Fiscal Invoice Numbers "UUID1", "UUID2", "UUID3"
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            CreateCFDIRelationDocument(
              CFDIRelationDocument[i], DATABASE::"Service Cr.Memo Header", 0, ServiceCrMemoHeader."No.",
              ServiceCrMemoHeader."Bill-to Customer No.", LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());
        // [GIVEN] CFDI Relation Documents has Service Invoice with "UUID-Inv"
        CreateCFDIRelationDocument(
          CFDIRelationDocumentInv, DATABASE::"Service Cr.Memo Header", 0, ServiceCrMemoHeader."No.",
          ServiceCrMemoHeader."Bill-to Customer No.", ServiceInvoiceHeader."No.", ServiceInvoiceHeader."Fiscal Invoice Number PAC");

        // [WHEN] Request Stamp for the Credit Memo
        RequestStamp(
          DATABASE::"Service Cr.Memo Header", ServiceCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        ServiceCrMemoHeader.Find();
        ServiceCrMemoHeader.CalcFields("Original String", "Original Document XML", "Signed Document XML");

        // [THEN] XML Document has node 'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado' with 'UUID's of "UUID-Inv", "UUID1", "UUID2", "UUID3"
        InitXMLReaderForSalesDocumentCFDI(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("Original Document XML"));
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
              'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', CFDIRelationDocument[i]."Fiscal Invoice Number PAC", i - 1);
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', ServiceInvoiceHeader."Fiscal Invoice Number PAC", i);

        // [THEN] String for digital stamp has Fiscal Invoices Numbers "UUID-Inv", "UUID1", "UUID2", "UUID3"
        ServiceCrMemoHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            Assert.AreEqual(
              CFDIRelationDocument[i]."Fiscal Invoice Number PAC", SelectStr(15 + i, OriginalStr),
              StrSubstNo(IncorrectOriginalStrValueErr, CFDIRelationDocument[i]."Fiscal Invoice Number PAC", OriginalStr));
        Assert.AreEqual(
          ServiceInvoiceHeader."Fiscal Invoice Number PAC", SelectStr(16 + i, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, ServiceInvoiceHeader."Fiscal Invoice Number PAC", OriginalStr));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoAppliedToAnotherInvoiceRequestStamp()
    var
        ServiceInvoiceHeader1: Record "Service Invoice Header";
        ServiceInvoiceHeader2: Record "Service Invoice Header";
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [Service] [CFDI Relation]
        // [SCENARIO 372201] Request Stamp for Service Credit Memo applied to Service Invoice not equal to Applied-to Doc No.
        Initialize();

        // [GIVEN] Posted and stamped two Service Invoices with Fiscal Invoice Numbers = "UUID-Inv1", "UUID-Inv2"
        ServiceInvoiceHeader1.Get(
          CreateAndPostServiceDoc(ServiceHeader."Document Type"::Invoice, CreatePaymentMethodForSAT()));
        ServiceHeader.Get(
          ServiceHeader."Document Type"::Invoice,
          CreateServiceDocForCustomer(
            ServiceHeader."Document Type"::Invoice, ServiceInvoiceHeader1."Customer No.", CreatePaymentMethodForSAT()));
        ServiceInvoiceHeader2.Get(PostServiceDocument(ServiceHeader));
        RequestStamp(
          DATABASE::"Service Invoice Header", ServiceInvoiceHeader2."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        ServiceInvoiceHeader2.Find();

        // [GIVEN] Posted Service Credit Memo applied to the Service Invoice
        ServiceCrMemoHeader.Get(
          CreatePostApplyServiceCrMemo(ServiceInvoiceHeader2."Bill-to Customer No.", ServiceInvoiceHeader2."No."));
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", ServiceCrMemoHeader."No.");
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::"Credit Memo", CustLedgerEntry."Document Type"::Invoice,
          ServiceCrMemoHeader."No.", ServiceInvoiceHeader2."No.");

        // [WHEN] Request Stamp for the Credit Memo
        RequestStamp(
          DATABASE::"Service Cr.Memo Header", ServiceCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        ServiceCrMemoHeader.Find();
        ServiceCrMemoHeader.CalcFields("Original String", "Original Document XML", "Signed Document XML");

        // [THEN] XML Document has node 'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado' with 'UUID' = "UUID-Inv2"
        InitXMLReaderForSalesDocumentCFDI(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', ServiceInvoiceHeader2."Fiscal Invoice Number PAC");

        // [THEN] String for digital stamp has Fiscal Invoices Number = "UUID-Inv2" of Sales Invoice 2
        ServiceCrMemoHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        Assert.AreEqual(
          ServiceInvoiceHeader2."Fiscal Invoice Number PAC", SelectStr(16, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, ServiceInvoiceHeader2."Fiscal Invoice Number PAC", OriginalStr));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimeZoneRequestStampSalesInvoiceShipTo()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
        TableNo: Integer;
        TimeZoneID: Text[180];
        TimeZoneOffset: Duration;
        UserOffset: Duration;
    begin
        // [SCENARIO 540218] Request Stamp for Sales Invoice in Location Time Zone
        Initialize();
        TableNo := DATABASE::"Sales Invoice Header";

        // [GIVEN] Sales Invoice has Location with City and Post Code with Time Zone offset = 2h
        DocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT());
        FindTimeZone(TimeZoneID, TimeZoneOffset, UserOffset);
        UpdateDocumentWithTimeZone(
          TableNo, SalesInvoiceHeader.FieldNo("No."), DocumentNo,
          SalesInvoiceHeader.FieldNo("Location Code"), TimeZoneID);

        // [WHEN] Request stamp for the Sales Invoice
        RequestStamp(TableNo, DocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Sales Invoice has 'Date/Time First Req. Sent' with offset 2h from current time
        SalesInvoiceHeader.Get(DocumentNo);
        VerifyIsNearlyEqualDateTime(
          ConvertTxtToDateTime(SalesInvoiceHeader."Date/Time First Req. Sent"),
          CreateDateTime(SalesInvoiceHeader."Document Date", Time) + TimeZoneOffset - UserOffset);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimeZoneRequestStampSalesCreditMemoSellTo()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocumentNo: Code[20];
        TableNo: Integer;
        TimeZoneID: Text[180];
        TimeZoneOffset: Duration;
        UserOffset: Duration;
    begin
        // [SCENARIO 540218] Request Stamp for Sales Credit Memo in Location Time Zone
        Initialize();
        TableNo := DATABASE::"Sales Cr.Memo Header";

        // [GIVEN] Sales Credit memo has Location with City and Post Code with Time Zone offset = 2h
        DocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT());
        FindTimeZone(TimeZoneID, TimeZoneOffset, UserOffset);
        UpdateDocumentWithTimeZone(
          TableNo, SalesCrMemoHeader.FieldNo("No."), DocumentNo,
          SalesCrMemoHeader.FieldNo("Location Code"), TimeZoneID);

        // [WHEN] Request stamp for the Sales Credit Memo
        RequestStamp(TableNo, DocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Sales Credit Memo has 'Date/Time First Req. Sent' with offset 2h from current time
        SalesCrMemoHeader.Get(DocumentNo);
        VerifyIsNearlyEqualDateTime(
          ConvertTxtToDateTime(SalesCrMemoHeader."Date/Time First Req. Sent"),
          CreateDateTime(SalesCrMemoHeader."Document Date", Time) + TimeZoneOffset - UserOffset);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimeZoneRequestStampServiceInvoiceBillTo()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        DocumentNo: Code[20];
        TableNo: Integer;
        TimeZoneID: Text[180];
        TimeZoneOffset: Duration;
        UserOffset: Duration;
    begin
        // [SCENARIO 540218] Request Stamp for Service Invoice in Location Time Zone
        Initialize();
        TableNo := DATABASE::"Service Invoice Header";

        // [GIVEN] Service Invoice has Location with City and Post Code with Time Zone offset = 2h
        DocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT());
        FindTimeZone(TimeZoneID, TimeZoneOffset, UserOffset);
        UpdateDocumentWithTimeZone(
          TableNo, ServiceInvoiceHeader.FieldNo("No."), DocumentNo,
          ServiceInvoiceHeader.FieldNo("Location Code"), TimeZoneID);

        // [WHEN] Request stamp for the Service Invoice
        RequestStamp(TableNo, DocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Service Invoice has 'Date/Time First Req. Sent' with offset 2h from current time
        ServiceInvoiceHeader.Get(DocumentNo);
        VerifyIsNearlyEqualDateTime(
          ConvertTxtToDateTime(ServiceInvoiceHeader."Date/Time First Req. Sent"),
          CreateDateTime(ServiceInvoiceHeader."Document Date", Time) + TimeZoneOffset - UserOffset);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimeZoneRequestStampServiceCreditMemoCust()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        DocumentNo: Code[20];
        TableNo: Integer;
        TimeZoneID: Text[180];
        TimeZoneOffset: Duration;
        UserOffset: Duration;
    begin
        // [SCENARIO 540218] Request Stamp for Service Credit Memo for Location with defined Time Zone
        Initialize();
        TableNo := DATABASE::"Service Cr.Memo Header";

        // [GIVEN] Service Credit Memo  has Location with City and Post Code with Time Zone offset = 2h
        DocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT());
        FindTimeZone(TimeZoneID, TimeZoneOffset, UserOffset);
        UpdateDocumentWithTimeZone(
          TableNo, ServiceCrMemoHeader.FieldNo("No."), DocumentNo,
          ServiceCrMemoHeader.FieldNo("Location Code"), TimeZoneID);

        // [WHEN] Request stamp for the Service Credit Memo
        RequestStamp(TableNo, DocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Service Credit Memo has 'Date/Time First Req. Sent' with offset 2h from current time
        ServiceCrMemoHeader.Get(DocumentNo);
        VerifyIsNearlyEqualDateTime(
          ConvertTxtToDateTime(ServiceCrMemoHeader."Date/Time First Req. Sent"),
          CreateDateTime(ServiceCrMemoHeader."Document Date", Time) + TimeZoneOffset - UserOffset);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimeZoneRequestStampPayment()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostCode: Record "Post Code";
        PaymentNo: Code[20];
        TimeZoneID: Text[180];
        TimeZoneOffset: Duration;
        UserOffset: Duration;
    begin
        // [SCENARIO 323341] Request Stamp for payment for customer with defined Time Zone
        Initialize();

        // [GIVEN] Sales Invoice
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT()));
        SalesInvoiceHeader.CalcFields("Amount Including VAT");

        // [GIVEN] Applied Payment has Customer with Post Code of Time Zone offset = 2h
        PaymentNo :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -SalesInvoiceHeader."Amount Including VAT", '');
        FindTimeZone(TimeZoneID, TimeZoneOffset, UserOffset);
        CreatePostCode(PostCode, TimeZoneID);
        UpdateCustomerPostCode(SalesInvoiceHeader."Sell-to Customer No.", PostCode.City, PostCode.Code);

        // [WHEN] Request Stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Customer Ledger Entry has 'Date/Time First Req. Sent' with offset 2h from current time
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        VerifyIsNearlyEqualDateTime(
          ConvertTxtToDateTime(CustLedgerEntry."Date/Time First Req. Sent"),
          CreateDateTime(CustLedgerEntry."Document Date", Time) + TimeZoneOffset - UserOffset);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TimeZoneSendSalesInvoiceShipTo()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
        TableNo: Integer;
        TimeZoneID: Text[180];
        TimeZoneOffset: Duration;
        UserOffset: Duration;
    begin
        // [SCENARIO 540218] Send document for Sales Invoice in Location Time Zone
        Initialize();
        TableNo := DATABASE::"Sales Invoice Header";

        // [GIVEN] Stamped Sales Invoice has Location with City and Post Code with Time Zone offset = 2h
        DocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT());
        UpdateDocumentFieldValue(
          TableNo, SalesInvoiceHeader.FieldNo("No."), DocumentNo,
          SalesInvoiceHeader.FieldNo("Electronic Document Status"), SalesInvoiceHeader."Electronic Document Status"::"Stamp Received");
        FindTimeZone(TimeZoneID, TimeZoneOffset, UserOffset);
        UpdateDocumentWithTimeZone(
          TableNo, SalesInvoiceHeader.FieldNo("No."), DocumentNo,
          SalesInvoiceHeader.FieldNo("Location Code"), TimeZoneID);

        // [WHEN] Send Electronic Document for the Sales Invoice
        RequestStamp(TableNo, DocumentNo, ResponseOption::Success, ActionOption::Send);

        // [THEN] Sales Invoice has 'Date/Time Sent' with offset 2h from current time
        SalesInvoiceHeader.Get(DocumentNo);
        VerifyIsNearlyEqualDateTime(
          ConvertTxtToDateTime(SalesInvoiceHeader."Date/Time Sent"), GetCurrentDateTimeInUserTimeZone() + TimeZoneOffset - UserOffset);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TimeZoneSendPayment()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostCode: Record "Post Code";
        PaymentNo: Code[20];
        TimeZoneID: Text[180];
        TimeZoneOffset: Duration;
        UserOffset: Duration;
    begin
        // [SCENARIO 323341] Send document for payment for customer with defined Time Zone
        Initialize();

        // [GIVEN] Sales Invoice
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT()));
        SalesInvoiceHeader.CalcFields("Amount Including VAT");

        // [GIVEN] Applied and stamped Payment has Customer with Post Code of Time Zone offset = 2h
        PaymentNo :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -SalesInvoiceHeader."Amount Including VAT", '');
        FindTimeZone(TimeZoneID, TimeZoneOffset, UserOffset);
        CreatePostCode(PostCode, TimeZoneID);
        UpdateCustomerPostCode(SalesInvoiceHeader."Sell-to Customer No.", PostCode.City, PostCode.Code);
        UpdateDocumentFieldValue(
          DATABASE::"Cust. Ledger Entry", CustLedgerEntry.FieldNo("Document No."), PaymentNo,
          CustLedgerEntry.FieldNo("Electronic Document Status"), CustLedgerEntry."Electronic Document Status"::"Stamp Received");

        // [WHEN] Send Electronic Document for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::Send);

        // [THEN] Customer Ledger Entry has 'Date/Time Sent' with offset 2h from current time
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        VerifyIsNearlyEqualDateTime(
          ConvertTxtToDateTime(CustLedgerEntry."Date/Time Sent"),
          GetCurrentDateTimeInUserTimeZone() + TimeZoneOffset - UserOffset);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimeZoneCancelInvoiceShipTo()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
        TableNo: Integer;
        TimeZoneID: Text[180];
        TimeZoneOffset: Duration;
        UserOffset: Duration;
    begin
        // [SCENARIO 540218] Cancel Sales Invoice in Location Time Zone
        Initialize();
        TableNo := DATABASE::"Sales Invoice Header";

        // [GIVEN] Stamped Sales Invoice has Location with City and Post Code with Time Zone offset = 2h
        DocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT());
        UpdateDocumentFieldValue(
          TableNo, SalesInvoiceHeader.FieldNo("No."), DocumentNo,
          SalesInvoiceHeader.FieldNo("Electronic Document Status"), SalesInvoiceHeader."Electronic Document Status"::"Stamp Received");
        FindTimeZone(TimeZoneID, TimeZoneOffset, UserOffset);
        UpdateDocumentWithTimeZone(
          TableNo, SalesInvoiceHeader.FieldNo("No."), DocumentNo,
          SalesInvoiceHeader.FieldNo("Location Code"), TimeZoneID);

        // [WHEN] Cancel Sales Invoice
        Cancel(TableNo, DocumentNo, ResponseOption::Success);

        // [THEN] Sales Invoice has 'Date/Time Cancel Sent' with offset 2h from current time
        SalesInvoiceHeader.Get(DocumentNo);
        VerifyIsNearlyEqualDateTime(
          SalesInvoiceHeader."Date/Time Cancel Sent", (GetCurrentDateTimeInUserTimeZone() + TimeZoneOffset - UserOffset));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimeZoneCancelPayment()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostCode: Record "Post Code";
        PaymentNo: Code[20];
        TimeZoneID: Text[180];
        TimeZoneOffset: Duration;
        UserOffset: Duration;
    begin
        // [SCENARIO 323341] Cancel payment for customer with defined Time Zone
        Initialize();

        // [GIVEN] Sales Invoice
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT()));
        SalesInvoiceHeader.CalcFields("Amount Including VAT");

        // [GIVEN] Applied and stamped Payment has Customer with Post Code of Time Zone offset = 2h
        PaymentNo :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -SalesInvoiceHeader."Amount Including VAT", '');
        FindTimeZone(TimeZoneID, TimeZoneOffset, UserOffset);
        CreatePostCode(PostCode, TimeZoneID);
        UpdateCustomerPostCode(SalesInvoiceHeader."Sell-to Customer No.", PostCode.City, PostCode.Code);
        UpdateDocumentFieldValue(
          DATABASE::"Cust. Ledger Entry", CustLedgerEntry.FieldNo("Document No."), PaymentNo,
          CustLedgerEntry.FieldNo("Electronic Document Status"), CustLedgerEntry."Electronic Document Status"::"Stamp Received");

        // [WHEN] Cancel payment
        Cancel(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success);

        // [THEN] Customer Ledger Entry has 'Date/Time Cancel Sent' with offset 2h from current time
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        VerifyIsNearlyEqualDateTime(
          CustLedgerEntry."Date/Time Cancel Sent", GetCurrentDateTimeInUserTimeZone() + TimeZoneOffset - UserOffset);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorLogCheckDocumentGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ErrorMessages: TestPage "Error Messages";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Error Log]
        // [SCENARIO 323132]  Error Log for G/L Setup
        Initialize();

        // [GIVEN] G/L Setup has blank fields "PAC Code", "PAC Environment", "SAT Certificate"
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."PAC Code" := '';
        GeneralLedgerSetup."PAC Environment" := 0;
        GeneralLedgerSetup."SAT Certificate" := '';
        GeneralLedgerSetup.Modify();

        // [GIVEN] Posted Sales Invoice
        DocumentNo := CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT());

        // [WHEN] Request Stamp Sales Invoice
        ErrorMessages.Trap();
        asserterror
          RequestStamp(DATABASE::"Sales Invoice Header", DocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for "PAC Code", "PAC Environment", "SAT Certificate" fields
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, GeneralLedgerSetup.FieldCaption("SAT Certificate"), GeneralLedgerSetup.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, GeneralLedgerSetup.FieldCaption("PAC Code"), GeneralLedgerSetup.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, GeneralLedgerSetup.FieldCaption("PAC Environment"), GeneralLedgerSetup.RecordId));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorLogCheckDocumentCompanyInfo()
    var
        CompanyInformation: Record "Company Information";
        ErrorMessages: TestPage "Error Messages";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Error Log]
        // [SCENARIO 323132]  Error Log for Company Information
        Initialize();

        // [GIVEN] Company Information has blank fields Name, Address, E-Mail, "RFC Number", "SAT Tax Regime Classification", "SAT Postal Code"
        CompanyInformation.Get();
        CompanyInformation.Name := '';
        CompanyInformation.Address := '';
        CompanyInformation."E-Mail" := '';
        CompanyInformation."RFC Number" := '';
        CompanyInformation."SAT Tax Regime Classification" := '';
        CompanyInformation."SAT Postal Code" := '';
        CompanyInformation.Modify();

        // [GIVEN] Posted Sales Invoice
        DocumentNo := CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT());

        // [WHEN] Request Stamp Sales Invoice
        ErrorMessages.Trap();
        asserterror
          RequestStamp(DATABASE::"Sales Invoice Header", DocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for blank fields in Company Information
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInformation.FieldCaption(Name), CompanyInformation.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInformation.FieldCaption(Address), CompanyInformation.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInformation.FieldCaption("E-Mail"), CompanyInformation.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInformation.FieldCaption("RFC Number"), CompanyInformation.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInformation.FieldCaption("SAT Tax Regime Classification"), CompanyInformation.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInformation.FieldCaption("SAT Postal Code"), CompanyInformation.RecordId));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorLogCheckDocumentNoPACDetails()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PACWebService: Record "PAC Web Service";
        PACWebServiceDetail: Record "PAC Web Service Detail";
        ErrorMessages: TestPage "Error Messages";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Error Log]
        // [SCENARIO 323132]  Error Log when no PAC Details
        Initialize();

        // [GIVEN] PAC Web Service has details with blank address
        GeneralLedgerSetup.Get();

        PACWebService.Get(GeneralLedgerSetup."PAC Code");
        PACWebServiceDetail.SetRange("PAC Code", GeneralLedgerSetup."PAC Code");
        PACWebServiceDetail.DeleteAll();

        // [GIVEN] Posted Sales Invoice
        DocumentNo := CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT());

        // [WHEN] Request Stamp Sales Invoice
        ErrorMessages.Trap();
        asserterror
          RequestStamp(DATABASE::"Sales Invoice Header", DocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for missed Web Services PAC Details
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(
            PACDetailDoesNotExistErr, PACWebServiceDetail.TableCaption(),
            PACWebService.Code, GeneralLedgerSetup."PAC Environment", PACWebServiceDetail.Type::"Request Stamp"));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(
            PACDetailDoesNotExistErr, PACWebServiceDetail.TableCaption(),
            PACWebService.Code, GeneralLedgerSetup."PAC Environment", PACWebServiceDetail.Type::Cancel));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorLogCheckDocumentPACDetailsMissedAddress()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PACWebService: Record "PAC Web Service";
        PACWebServiceDetail: Record "PAC Web Service Detail";
        ErrorMessages: TestPage "Error Messages";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Error Log]
        // [SCENARIO 323132]  Error Log for PAC Details when no Address specified
        Initialize();

        // [GIVEN] PAC Web Service has details with blank address
        GeneralLedgerSetup.Get();

        PACWebService.Get(GeneralLedgerSetup."PAC Code");
        PACWebServiceDetail.SetRange("PAC Code", GeneralLedgerSetup."PAC Code");
        PACWebServiceDetail.ModifyAll(Address, '');

        // [GIVEN] Posted Sales Invoice
        DocumentNo := CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT());

        // [WHEN] Request Stamp Sales Invoice
        ErrorMessages.Trap();
        asserterror
          RequestStamp(DATABASE::"Sales Invoice Header", DocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for blank Address in Web Services PAC Details
        PACWebServiceDetail.FindFirst();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, PACWebServiceDetail.FieldCaption(Address), PACWebServiceDetail.RecordId));
        PACWebServiceDetail.FindLast();
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, PACWebServiceDetail.FieldCaption(Address), PACWebServiceDetail.RecordId));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorLogCheckCustomer()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Error Log]
        // [SCENARIO 323132]  Error Log for Customer
        Initialize();

        // [GIVEN] Posted Sales Invoice when Customer has blank values in "RFC No." and "Country/Region Code"
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT()));
        Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");
        Customer."RFC No." := '';
        Customer."Country/Region Code" := '';
        Customer.Modify();

        // [WHEN] Request Stamp Sales Invoice
        ErrorMessages.Trap();
        asserterror
          RequestStamp(
            DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for blank fields in Customer Table
        ErrorMessages.Description.AssertEquals(StrSubstNo(IfEmptyErr, Customer.FieldCaption("RFC No."), Customer.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(StrSubstNo(IfEmptyErr, Customer.FieldCaption("Country/Region Code"), Customer.RecordId));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorLogCheckDocumentHeader()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Error Log]
        // [SCENARIO 323132]  Error Log for Sales Invoice
        Initialize();

        // [GIVEN] Posted Sales Invoice with blank fields "Document Date", "Payment Terms Code", "Payment Method Code",
        // [GIVEN] "Bill-to Address", "Bill-to Post Code", "CFDI Purpose", "CFDI Relation"
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT()));
        SalesInvoiceHeader."Document Date" := 0D;
        SalesInvoiceHeader."Payment Terms Code" := '';
        SalesInvoiceHeader."Payment Method Code" := '';
        SalesInvoiceHeader."Bill-to Address" := '';
        SalesInvoiceHeader."Bill-to Post Code" := '';
        SalesInvoiceHeader."CFDI Purpose" := '';
        SalesInvoiceHeader."CFDI Relation" := '';
        SalesInvoiceHeader.Modify();

        // [WHEN] Request Stamp Sales Invoice
        ErrorMessages.Trap();
        asserterror
          RequestStamp(
            DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for blank fields in Customer Table
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceHeader.FieldCaption("Document Date"), SalesInvoiceHeader.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceHeader.FieldCaption("Payment Terms Code"), SalesInvoiceHeader.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceHeader.FieldCaption("Payment Method Code"), SalesInvoiceHeader.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceHeader.FieldCaption("Bill-to Address"), SalesInvoiceHeader.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceHeader.FieldCaption("Bill-to Post Code"), SalesInvoiceHeader.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceHeader.FieldCaption("CFDI Purpose"), SalesInvoiceHeader.RecordId));
        // [THEN] No error for CFDI Relation field
        ErrorMessages.FILTER.SetFilter("Table Number", Format(DATABASE::"Sales Invoice Header"));
        ErrorMessages.FILTER.SetFilter("Field Number", Format(SalesInvoiceHeader.FieldNo("CFDI Relation")));
        ErrorMessages.Description.AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorLogCheckDocumentHeaderSATMissed()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Error Log]
        // [SCENARIO 323132]  Error Log for Sales Invoice when SAT code is not specified
        Initialize();

        // [GIVEN] Posted Sales Invoice where SAT code is not specified for Payment Terms and Payment Methods
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT()));
        PaymentTerms.Get(SalesInvoiceHeader."Payment Terms Code");
        PaymentTerms."SAT Payment Term" := '';
        PaymentTerms.Modify();
        PaymentMethod.Get(SalesInvoiceHeader."Payment Method Code");
        PaymentMethod."SAT Method of Payment" := '';
        PaymentMethod.Modify();

        // [WHEN] Request Stamp Sales Invoice
        ErrorMessages.Trap();
        asserterror
          RequestStamp(
            DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for blank fields in Payment Terms and Payment Method tables
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, PaymentTerms.FieldCaption("SAT Payment Term"), PaymentTerms.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, PaymentMethod.FieldCaption("SAT Method of Payment"), PaymentMethod.RecordId));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorLogCheckDocumentLines()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Error Log]
        // [SCENARIO 323132]  Error Log for Sales Invoice Lines
        Initialize();

        // [GIVEN] Posted Sales Invoice has line with blank Description, "Unit Price", "Amount Including VAT", "Unit of Measure Code"
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT()));
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.Description := '';
        SalesInvoiceLine."Unit Price" := 0;
        SalesInvoiceLine."Amount Including VAT" := 0;
        SalesInvoiceLine."Unit of Measure Code" := '';
        SalesInvoiceLine.Modify();

        // [WHEN] Request Stamp Sales Invoice
        ErrorMessages.Trap();
        asserterror
          RequestStamp(
            DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for blank fields in Sales Line table
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceLine.FieldCaption(Description), SalesInvoiceLine.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceLine.FieldCaption("Unit Price"), SalesInvoiceLine.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceLine.FieldCaption("Amount Including VAT"), SalesInvoiceLine.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceLine.FieldCaption("Unit of Measure Code"), SalesInvoiceLine.RecordId));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorLogCheckDocumentLineTypes()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesInvoiceLineGL: Record "Sales Invoice Line";
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Error Log]
        // [SCENARIO 323132]  Error Log for Sales Invoice Lines of G/L Account Type
        Initialize();

        // [GIVEN] Posted Sales Invoice has lines with type G/L Account
        // [GIVEN] Item and Unit Of Measure with blank SAT codes
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT()));
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        Item.Get(SalesInvoiceLine."No.");
        Item."SAT Item Classification" := '';
        Item.Modify();
        UnitOfMeasure.Get(SalesInvoiceLine."Unit of Measure Code");
        UnitOfMeasure."SAT UofM Classification" := '';
        UnitOfMeasure.Modify();

        SalesInvoiceLineGL := SalesInvoiceLine;
        SalesInvoiceLineGL."Line No." := LibraryUtility.GetNewRecNo(SalesInvoiceLineGL, SalesInvoiceLineGL.FieldNo("Line No."));
        SalesInvoiceLineGL.Type := SalesInvoiceLineGL.Type::"G/L Account";
        SalesInvoiceLineGL."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceLineGL.Insert();

        // [WHEN] Request Stamp Sales Invoice
        ErrorMessages.Trap();
        asserterror
          RequestStamp(
            DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Item and Unit Of Measure are added with errors of blank fields
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, Item.FieldCaption("SAT Item Classification"), Item.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, UnitOfMeasure.FieldCaption("SAT UofM Classification"), UnitOfMeasure.RecordId));
        // [THEN] No error for Sales Line types
        ErrorMessages.FILTER.SetFilter("Table Number", Format(DATABASE::"Sales Invoice Line"));
        ErrorMessages.Description.AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorLogCheckDocumentLinesWithRetentions()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Error Log] [Retention]
        // [SCENARIO 389401] Error Log for Sales Invoice Lines with retentions
        Initialize();

        // [GIVEN] Posted Sales Invoice has tree lines
        // [GIVEN] Normal sales line
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(), CreatePaymentMethodForSAT());
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItemWithPrice(LibraryRandom.RandIntInRange(1000, 2000)),
          LibraryRandom.RandIntInRange(1, 10), 0, 0, false, false);
        SalesLine.Description := '';
        SalesLine.Modify();
        // [GIVEN] Sales line with negative quantity supposed to be retention line, 'Retention Attached to Line No.' is not assigned
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItemWithPrice(LibraryRandom.RandIntInRange(100, 200)),
          -LibraryRandom.RandIntInRange(1, 10), 0, 0, false, false);
        // [GIVEN] Retention Sales line with assigned 'Retention Attached to Line No.', 'Retention VAT %' is not assigned
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItemWithPrice(LibraryRandom.RandIntInRange(100, 200)),
          -LibraryRandom.RandIntInRange(1, 10), 0, 0, false, false);
        SalesLine."Retention Attached to Line No." := LibraryRandom.RandIntInRange(1000, 2000);
        SalesLine.Modify();
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindSet();

        // [WHEN] Request Stamp Sales Invoice
        ErrorMessages.Trap();
        asserterror
          RequestStamp(
            DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for blank fields in Sales Line table
        Assert.ExpectedMessage(
          StrSubstNo('''%1'' in ''%2: %3,%4'' must not be blank.',
            SalesInvoiceLine.FieldCaption(Description), SalesInvoiceLine.TableCaption(),
            SalesInvoiceLine."Document No.", SalesInvoiceLine."Line No."),
          ErrorMessages.Description.Value);
        // [THEN] Warning is registered for the line with negative Quantity and 'Retention Attached to Line No.' = 0
        ErrorMessages.Next();
        SalesInvoiceLine.Next();
        Assert.ExpectedMessage(
          StrSubstNo('''%1'' in ''Document Line: %2,%3'' must be greater than or equal to 0.',
            SalesInvoiceLine.FieldCaption(Quantity),
            SalesInvoiceLine."Document No.", SalesInvoiceLine."Line No."),
          ErrorMessages.Description.Value);
        // [THEN] Warning is registered for the line with line having 'Retention Attached to Line No.' and 'Retention VAT %' = 0
        ErrorMessages.Next();
        SalesInvoiceLine.Next();
        Assert.ExpectedMessage(
          StrSubstNo('''%1'' in ''Document Line: %2,%3'' must not be blank.',
            SalesInvoiceLine.FieldCaption("Retention VAT %"),
            SalesInvoiceLine."Document No.", SalesInvoiceLine."Line No."),
          ErrorMessages.Description.Value);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceNormalVATRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        InStream: InStream;
        OriginalStr: Text;
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 457742] Request Stamp for Sales Invoice with normal VAT that is 16% and 8%.
        Initialize();

        // [GIVEN] Posted Sales Invoice with line1: Amount = 1000, VAT % = 16, line2: Amount = 800, VAT % = 8.
        Customer.Get(CreateCustomer());
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        // [GIVEN] "Bill-to Post Code" is filled in with 12345
        SalesHeader."Bill-to Post Code" := Format(LibraryRandom.RandIntInRange(10000, 20000));
        SalesHeader.Modify();
        VATProdPostingGroup := CreateVATPostingSetup(SalesHeader."VAT Bus. Posting Group", 16, false, false);
        CreateSalesLineItemWithVATSetup(SalesLine1, SalesHeader, CreateItem(), VATProdPostingGroup, 1, LibraryRandom.RandIntInRange(1000, 2000), 0);
        VATProdPostingGroup := CreateVATPostingSetup(SalesHeader."VAT Bus. Posting Group", 8, false, false);
        CreateSalesLineItemWithVATSetup(SalesLine2, SalesHeader, CreateItem(), VATProdPostingGroup, 1, LibraryRandom.RandIntInRange(1000, 2000), 0);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] 'DomicilioFiscalReceptor' is exported from SalesInvoice."Post Code" = 12345 (TFS 547550)
        VerifyPartyInformation(
          OriginalStr, Customer."RFC No.", Customer."CFDI Customer Name",
          SalesInvoiceHeader."Bill-to Post Code", Customer."SAT Tax Regime Classification", 18, 21);
        // [THEN] XML Document has node 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' with VAT data for lines
        // [THEN] Line1 has attributes 'Importe' = 160, 'TipoFactor' = 'Tasa', 'Impuesto' = '002', 'Base' = 1000.
        // [THEN] Line2 has attributes 'Importe' = 64, 'TipoFactor' = 'Tasa', 'Impuesto' = '002', 'Base' = 800.
        VerifyVATAmountLines(
          OriginalStr, SalesLine1.Amount, SalesLine1."Amount Including VAT" - SalesLine1.Amount, SalesLine1."VAT %", '002', 0, 0);
        VerifyVATAmountLines(
          OriginalStr, SalesLine2.Amount, SalesLine2."Amount Including VAT" - SalesLine2.Amount, SalesLine2."VAT %", '002', 0, 1);
        // [THEN] XML Document has node 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' with 2 total VAT lines
        // [THEN] Line1: attributes 'Importe' = 160, 'TipoFactor' = 'Tasa', 'Impuesto' = '002'.
        // [THEN] Line2: attributes 'Importe' = 64, 'TipoFactor' = 'Tasa', 'Impuesto' = '002'.
        VerifyVATTotalLine(
          OriginalStr,
          SalesLine1."Amount Including VAT" - SalesLine1.Amount, SalesLine1."VAT %", '002', 0, 1, 15);
        VerifyVATTotalLine(
          OriginalStr,
          SalesLine2."Amount Including VAT" - SalesLine2.Amount, SalesLine2."VAT %", '002', 1, 1, 15);
        VerifyTotalImpuestos(
          OriginalStr, 'TotalImpuestosTrasladados', SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount, 63);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceZeroVATRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 338353] Request Stamp for Sales Invoice with normal zero VAT
        Initialize();

        // [GIVEN] Posted Sales Invoice with Amount = 100, VAT Amount = 0
        SalesHeader.Get(
          SalesHeader."Document Type"::Invoice,
          CreateSalesDocForCustomerWithVAT(
            SalesHeader."Document Type"::Invoice, CreateCustomer(), CreatePaymentMethodForSAT(), 0, false, false));
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount);

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] XML Document has node 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' with VAT data for the line
        // [THEN] and attributes 'Importe' = 0, 'TipoFactor' = 'Tasa', 'Impuesto' = '002', 'Base' = 100.
        VerifyVATAmountLines(
          OriginalStr, SalesInvoiceHeader.Amount, 0, 0, '002', 0, 0);

        // [THEN] Total VAT Amount is exported as attribute 'cfdi:Impuestos/TotalImpuestosTrasladados' = 10
        // [THEN] XML Document has node 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' with total VAT line
        // [THEN] and attributes 'Importe' = 0, 'TipoFactor' = 'Tasa', 'Impuesto' = '002'.
        VerifyVATTotalLine(
          OriginalStr, 0, 0, '002', 0, 1, 0);
        VerifyTotalImpuestos(
          OriginalStr, 'TotalImpuestosTrasladados', 0, 42);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceVATExemptRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 338353] Request Stamp for Sales Invoice with VAT exemption
        Initialize();

        // [GIVEN] Posted Sales Invoice with Amount = 100 and 'VAT Exemption' marked in VAT Posting Setup
        SalesHeader.Get(
          SalesHeader."Document Type"::Invoice,
          CreateSalesDocForCustomerWithVAT(
            SalesHeader."Document Type"::Invoice, CreateCustomer(), CreatePaymentMethodForSAT(), 0, true, false));
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount);

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] XML Document has node 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' with VAT data for the line
        // [THEN] and attributes 'TipoFactor' = 'Exento', 'Impuesto' = '002', 'Base' = 100.
        VerifyVATAmountLinesExempt(
          OriginalStr, SalesInvoiceHeader.Amount, '002');

        // [THEN] Total Impuestos:  'cfdi:Impuestos/TotalImpuestosTrasladados' = 0
        VerifyTotalImpuestos(OriginalStr, 'TotalImpuestosTrasladados', 0, 39);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceNoTaxableRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 338353] Request Stamp for Sales Invoice with No Taxable VAT
        Initialize();

        // [GIVEN] Posted Sales Invoice with Amount = 100 and 'No Taxable' marked in VAT Posting Setup
        SalesHeader.Get(
          SalesHeader."Document Type"::Invoice,
          CreateSalesDocForCustomerWithVAT(
            SalesHeader."Document Type"::Invoice, CreateCustomer(), CreatePaymentMethodForSAT(), 0, false, true));
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount);

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados node is not exported
        LibraryXPathXMLReader.VerifyNodeAbsence('cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados');

        // [THEN] 'cfdi:Comprobante/cfdi:Impuestos' node is not exported
        LibraryXPathXMLReader.VerifyNodeAbsence('cfdi:Comprobante/cfdi:Impuestos');
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceDiferentVATLinesStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 387092] Request Stamp for Sales Invoice with lines having different VAT
        Initialize();

        // [GIVEN] Posted Sales Invoice with two lines
        // [GIVEN] First line of Amount = 100, VAT Amount = 10, second line of Amount = 100, VAT Amount = 20
        CreateSalesHeaderForCustomer(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(), CreatePaymentMethodForSAT());
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItemWithPrice(LibraryRandom.RandIntInRange(100, 200)),
          1, 0, LibraryRandom.RandIntInRange(10, 15), false, false);
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItemWithPrice(LibraryRandom.RandIntInRange(100, 200)),
          1, 0, LibraryRandom.RandIntInRange(16, 20), false, false);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] XML Document has nodes 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' with VAT data for each line
        // [THEN] Attributes for first line 'Importe' = 10, 'TipoFactor' = 'Tasa', 'Impuesto' = '003', 'Base' = 100.
        // [THEN] Attributes for first line 'Importe' = 20, 'TipoFactor' = 'Tasa', 'Impuesto' = '003', 'Base' = 100.
        // [THEN] Total VAT Amount is exported as attribute 'cfdi:Impuestos/TotalImpuestosTrasladados' = 10
        // [THEN] XML Document has nodes 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' with total VAT lines
        // [THEN] Attributes for first line 'Importe' = 10, , TasaOCuota='0.100000', 'TipoFactor' = 'Tasa', 'Impuesto' = '003'.
        // [THEN] Attributes for first line 'Importe' = 20, , TasaOCuota='0.200000', 'TipoFactor' = 'Tasa', 'Impuesto' = '003'.
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        VerifyVATAmountLines(
          OriginalStr, SalesInvoiceLine.Amount, SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount,
          SalesInvoiceLine."VAT %", GetTaxCodeTraslado(SalesInvoiceLine."VAT %"), 0, 0);
        VerifyVATTotalLine(
          OriginalStr,
          SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount, SalesInvoiceLine."VAT %",
          GetTaxCodeTraslado(SalesInvoiceLine."VAT %"), 0, 2, 0);
        SalesInvoiceLine.FindLast();
        VerifyVATAmountLines(
          OriginalStr, SalesInvoiceLine.Amount, SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount,
          SalesInvoiceLine."VAT %", GetTaxCodeTraslado(SalesInvoiceLine."VAT %"), 0, 1);
        VerifyVATTotalLine(
          OriginalStr,
          SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount, SalesInvoiceLine."VAT %",
          GetTaxCodeTraslado(SalesInvoiceLine."VAT %"), 1, 2, 0);
        VerifyTotalImpuestos(
          OriginalStr, 'TotalImpuestosTrasladados', SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount, 63);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoicePricesInclVATRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineDisc: Record "Sales Line";
        Customer: Record Customer;
        Currency: Record Currency;
        InStream: InStream;
        OriginalStr: Text;
        UnitPrice: Decimal;
        LineDiscExclVAT: Decimal;
    begin
        // [FEATURE] [Sales] [VAT] [Prices Including VAT] [Line Discount]
        // [SCENARIO 352547] Request Stamp for Sales Invoice with Prices Including VAT and line discount
        Initialize();

        // [GIVEN] Posted Sales Invoice with VAT% = 15, Prices Including VAT = true
        // [GIVEN] Sales Line 1 has Quantity = 3, Unit Price 1150
        // [GIVEN] Sales Line 2 has Quantity = 2, Unit Price 1150, Line Discount % = 7, Line Discount Amount = 161 (2300 * 7%)
        // [GIVEN] Amount = 4860 (3000 + 2000 + 140 discount no VAT)
        // [GIVEN] Amount Including VAT = 5589 (3450 + 2300 - 161)
        Customer.Get(CreateCustomer());
        Customer.Validate("Prices Including VAT", true);
        Customer.Modify(true);
        SalesHeader.Get(
          SalesHeader."Document Type"::Invoice,
          CreateSalesDocForCustomerWithVAT(
            SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT(), 16, false, false));
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLineDisc := SalesLine;
        SalesLineDisc."Line No." := 0;
        SalesLineDisc.Validate(Quantity, 2);
        SalesLineDisc.Validate("Line Discount %", 5);
        SalesLineDisc.Insert(true);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] XML header has 'Total' = 5589, 'Descuento' = 140, 'SubTotal' = 5000 (4860 + 140)
        Currency.InitRoundingPrecision();
        UnitPrice := SalesLine."Unit Price" * 100 / (100 + SalesLine."VAT %");
        SalesLine."Amount Including VAT" := SalesLine.Amount * (1 + SalesLine."VAT %" / 100);
        SalesLineDisc."Amount Including VAT" := SalesLineDisc.Amount * (1 + SalesLineDisc."VAT %" / 100);
        LineDiscExclVAT :=
          Round(UnitPrice * SalesLineDisc.Quantity * SalesLineDisc."Line Discount %" / 100, Currency."Amount Rounding Precision");
        VerifyRootNodeTotals(
          OriginalStr,
          SalesInvoiceHeader."Amount Including VAT", SalesInvoiceHeader.Amount + LineDiscExclVAT,
          LineDiscExclVAT);

        // [THEN] 'Concepto' node for discount line has 'Descuento' = 140, Importe = 2000, 'ValorUnitario' = 1000
        // [THEN] 'Traslado' node for discount line has 'Importe' = 279 (2300 - 1860 -161), 'Base' = 1860 (2000 - 140)
        VerifyLineAmountsByIndex(
          LineDiscExclVAT, UnitPrice * SalesLineDisc.Quantity, UnitPrice,
          SalesLineDisc."Amount Including VAT" - SalesLineDisc.Amount,
          SalesLineDisc.Amount, 0);
        // [THEN] 'Concepto' node for normal line has 'Descuento' = 0, Importe = 3000, 'ValorUnitario' = 1000
        // [THEN] 'Traslado' node for normal line has 'Importe' = 450 (3450 - 3000), 'Base' = 3000        VerifyLineAmountsByIndex(
        VerifyLineAmountsByIndex(
          0, UnitPrice * SalesLine.Quantity, UnitPrice,
          SalesLine."Amount Including VAT" - SalesLine.Amount,
          SalesLine.Amount, 1);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoicePricesInclVATRequestStamp()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLineDisc: Record "Service Line";
        Customer: Record Customer;
        Currency: Record Currency;
        InStream: InStream;
        OriginalStr: Text;
        UnitPrice: Decimal;
        LineDiscExclVAT: Decimal;
    begin
        // [FEATURE] [Service] [VAT] [Prices Including VAT] [Line Discount]
        // [SCENARIO 352547] Request Stamp for Service Invoice with Prices Including VAT and line discount
        Initialize();

        // [GIVEN] Posted Service Invoice with VAT% = 15, Prices Including VAT = true
        // [GIVEN] Service Line 1 has Quantity = 3, Unit Price 1150
        // [GIVEN] Service Line 2 has Quantity = 2, Unit Price 1150, Line Discount % = 7, Line Discount Amount = 161 (2300 * 7%)
        // [GIVEN] Amount = 4860 (3000 + 2000 + 140 discount no VAT)
        // [GIVEN] Amount Including VAT = 5589 (3450 + 2300 - 161)
        Customer.Get(CreateCustomer());
        Customer.Validate("Prices Including VAT", true);
        Customer.Modify(true);
        ServiceHeader.Get(
          ServiceHeader."Document Type"::Invoice,
          CreateServiceDocForCustomer(ServiceHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT()));
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        ServiceLineDisc := ServiceLine;
        ServiceLineDisc."Line No." := 0;
        ServiceLineDisc.Validate(Quantity, LibraryRandom.RandIntInRange(3, 5));
        ServiceLineDisc.Validate("Line Discount %", LibraryRandom.RandIntInRange(5, 10));
        ServiceLineDisc.Insert(true);
        ServiceInvoiceHeader.Get(PostServiceDocument(ServiceHeader));

        // [WHEN] Request Stamp for the Service Invoice
        RequestStamp(
          DATABASE::"Service Invoice Header", ServiceInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        ServiceInvoiceHeader.Find();
        ServiceInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InitXMLReaderForSalesDocumentCFDI(ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("Original Document XML"));
        ServiceInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] XML header has 'Total' = 5589, 'Descuento' = 140, 'SubTotal' = 5000 (4860 + 140)
        Currency.InitRoundingPrecision();
        UnitPrice := ServiceLine."Unit Price" * 100 / (100 + ServiceLine."VAT %");
        ServiceLine."Amount Including VAT" := ServiceLine.Amount * (1 + ServiceLine."VAT %" / 100);
        ServiceLineDisc."Amount Including VAT" := ServiceLineDisc.Amount * (1 + ServiceLineDisc."VAT %" / 100);
        LineDiscExclVAT :=
          Round(UnitPrice * ServiceLineDisc.Quantity * ServiceLineDisc."Line Discount %" / 100, Currency."Amount Rounding Precision");
        VerifyRootNodeTotals(
          OriginalStr,
          ServiceInvoiceHeader."Amount Including VAT", ServiceInvoiceHeader.Amount + LineDiscExclVAT,
          LineDiscExclVAT);

        // [THEN] 'Concepto' node for discount line has 'Descuento' = 140, Importe = 2000, 'ValorUnitario' = 1000
        // [THEN] 'Traslado' node for discount line has 'Importe' = 279 (2300 - 1860 -161), 'Base' = 1860 (2000 - 140)
        VerifyLineAmountsByIndex(
          LineDiscExclVAT, UnitPrice * ServiceLineDisc.Quantity, UnitPrice,
          ServiceLineDisc."Amount Including VAT" - ServiceLineDisc.Amount,
          ServiceLineDisc.Amount, 0);
        // [THEN] 'Concepto' node for normal line has 'Descuento' = 0, Importe = 3000, 'ValorUnitario' = 1000
        // [THEN] 'Traslado' node for normal line has 'Importe' = 450 (3450 - 3000), 'Base' = 3000
        VerifyLineAmountsByIndex(
          0, UnitPrice * ServiceLine.Quantity, UnitPrice,
          ServiceLine."Amount Including VAT" - ServiceLine.Amount,
          UnitPrice * ServiceLine.Quantity, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceNoStampExportPDF()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 364057] Error when export electronic document as PDF for Sales Invoice without stamp
        Initialize();

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(
          CreateAndPostSalesDoc(SalesHeader."Document Type"::Invoice, CreatePaymentMethodForSAT()));

        // [WHEN] Export Electronic Document as PDF
        asserterror SalesInvoiceHeader.ExportEDocumentPDF();

        // [THEN] PDF file for the report is created
        Assert.ExpectedError(NoElectronicStampErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoNoStampExportPDF()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 364057] Error when export electronic document as PDF for Sales Credit Memo without stamp
        Initialize();

        // [GIVEN] Posted Sales Credit Memo
        SalesCrMemoHeader.Get(
          CreateAndPostSalesDoc(SalesHeader."Document Type"::"Credit Memo", CreatePaymentMethodForSAT()));

        // [WHEN] Export Electronic Document as PDF
        asserterror SalesCrMemoHeader.ExportEDocumentPDF();

        // [THEN] PDF file for the report is created
        Assert.ExpectedError(NoElectronicStampErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceNoStampExportPDF()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 364057] Error when export electronic document as PDF for Service Invoice without stamp
        Initialize();

        // [GIVEN] Posted Service Invoice
        ServiceInvoiceHeader.Get(
          CreateAndPostServiceDoc(ServiceHeader."Document Type"::Invoice, CreatePaymentMethodForSAT()));

        // [WHEN] Export Electronic Document as PDF
        asserterror ServiceInvoiceHeader.ExportEDocumentPDF();

        // [THEN] PDF file for the report is created
        Assert.ExpectedError(NoElectronicDocumentSentErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoNoStampExportPDF()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 364057] Error when export electronic document as PDF for Service Credit Memo without stamp
        Initialize();

        // [GIVEN] Posted Service Credit Memo
        ServiceCrMemoHeader.Get(
          CreateAndPostServiceDoc(ServiceHeader."Document Type"::"Credit Memo", CreatePaymentMethodForSAT()));

        // [WHEN] Export Electronic Document as PDF
        asserterror ServiceCrMemoHeader.ExportEDocumentPDF();

        // [THEN] PDF file for the report is created
        Assert.ExpectedError(NoElectronicStampErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithStampExportPDF()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [UI] [Export]
        // [SCENARIO 364057] Export electronic document as PDF for Sales Invoice with stamp
        Initialize();

        // [GIVEN] Posted and stamped Sales Invoice
        SalesInvoiceHeader.Get(
          CreateAndPostSalesDoc(SalesHeader."Document Type"::Invoice, CreatePaymentMethodForSAT()));
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();

        // [WHEN] Export Electronic Document as PDF
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.FILTER.SetFilter("No.", SalesInvoiceHeader."No.");
        BindSubscription(MXCFDI);
        PostedSalesInvoice.ExportEDocumentPDF.Invoke();
        UnbindSubscription(MXCFDI);

        // [THEN] PDF file for the report is created
        VerifyPDFFile();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithStampExportPDF()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [Sales] [UI] [Export]
        // [SCENARIO 364057] Export electronic document as PDF for Sales Credit Memo with stamp
        Initialize();

        // [GIVEN] Posted and stamped Sales Credit Memo
        SalesCrMemoHeader.Get(
          CreateAndPostSalesDoc(SalesHeader."Document Type"::"Credit Memo", CreatePaymentMethodForSAT()));
        RequestStamp(
          DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesCrMemoHeader.Find();

        // [WHEN] Export Electronic Document as PDF
        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.FILTER.SetFilter("No.", SalesCrMemoHeader."No.");
        BindSubscription(MXCFDI);
        PostedSalesCreditMemo.ExportEDocumentPDF.Invoke();
        UnbindSubscription(MXCFDI);

        // [THEN] PDF file for the report is created
        VerifyPDFFile();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceWithStampExportPDF()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceHeader: Record "Service Header";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
    begin
        // [FEATURE] [Service] [UI] [Export]
        // [SCENARIO 364057] Export electronic document as PDF for Service Invoice with stamp
        Initialize();

        // [GIVEN] Posted and stamped Service Invoice
        ServiceInvoiceHeader.Get(
          CreateAndPostServiceDoc(ServiceHeader."Document Type"::Invoice, CreatePaymentMethodForSAT()));
        RequestStamp(
          DATABASE::"Service Invoice Header", ServiceInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        ServiceInvoiceHeader.Find();

        // [WHEN] Export Electronic Document as PDF
        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.FILTER.SetFilter("No.", ServiceInvoiceHeader."No.");
        BindSubscription(MXCFDI);
        PostedServiceInvoice.ExportEDocumentPDF.Invoke();
        UnbindSubscription(MXCFDI);

        // [THEN] PDF file for the report is created
        VerifyPDFFile();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoWithStampExportPDF()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceHeader: Record "Service Header";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
    begin
        // [FEATURE] [Service] [UI] [Export]
        // [SCENARIO 364057] Export electronic document as PDF for Service credit Memo with stamp
        Initialize();

        // [GIVEN] Posted and stamped Service Credit Memo
        ServiceCrMemoHeader.Get(
          CreateAndPostServiceDoc(ServiceHeader."Document Type"::"Credit Memo", CreatePaymentMethodForSAT()));
        RequestStamp(
          DATABASE::"Service Cr.Memo Header", ServiceCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        ServiceCrMemoHeader.Find();

        // [WHEN] Export Electronic Document as PDF
        PostedServiceCreditMemo.OpenView();
        PostedServiceCreditMemo.FILTER.SetFilter("No.", ServiceCrMemoHeader."No.");
        BindSubscription(MXCFDI);
        PostedServiceCreditMemo.ExportEDocumentPDF.Invoke();
        UnbindSubscription(MXCFDI);

        // [THEN] PDF file for the report is created
        VerifyPDFFile();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithFixedAssetRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InStream: InStream;
        OriginalStr: Text;
        FANo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 364407] Request Stamp for Sales Invoice with fixed asset
        Initialize();

        // [GIVEN] Posted Sales Invoice with fixed asset "FA"
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(), CreatePaymentMethodForSAT());
        FANo := CreateSalesLineFixedAsset(SalesHeader, 0, false, false);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML");

        // [THEN] The stamp is received
        SalesInvoiceHeader.TestField("Electronic Document Status", SalesInvoiceHeader."Electronic Document Status"::"Stamp Received");
        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);

        // [THEN] 'Concepto' node has attributes 'ClaveProdServ' = SAT Classification Code of the Fixed Asset, 'NoIdentificacion' = "FA", 'ClaveUnidad' = 'H87'
        // [THEN] String for digital stamp has 'ClaveProdServ' = SAT Classification Code of the Fixed Asset, 'NoIdentificacion' = "FA", 'ClaveUnidad' = 'H87'
        VerifyCFDIConceptoFields(OriginalStr, FANo, SATUtilities.GetSATUnitOfMeasureFixedAsset(), SalesLine.Type::"Fixed Asset");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithFixedAssetRequestStamp()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InStream: InStream;
        OriginalStr: Text;
        FANo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 364407] Request Stamp for Sales Credit Memo with fixed asset
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with fixed asset "FA"
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomer(), CreatePaymentMethodForSAT());
        FANo := CreateSalesLineFixedAsset(SalesHeader, 0, false, false);
        MockFADisposalEntry(FANo);
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Credi Memo
        RequestStamp(
          DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesCrMemoHeader.Find();
        SalesCrMemoHeader.CalcFields("Original String", "Original Document XML");

        // [THEN] The stamp is received
        SalesCrMemoHeader.TestField("Electronic Document Status", SalesCrMemoHeader."Electronic Document Status"::"Stamp Received");
        InitXMLReaderForSalesDocumentCFDI(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Original Document XML"));
        SalesCrMemoHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);

        // [THEN] 'Concepto' node has attributes 'ClaveProdServ' = '01010101', 'NoIdentificacion' = "FA", 'ClaveUnidad' = 'H87'
        // [THEN] String for digital stamp has 'ClaveProdServ' = '01010101', 'NoIdentificacion' = "FA", 'ClaveUnidad' = 'H87'
        VerifyCFDIConceptoFields(OriginalStr, FANo, SATUtilities.GetSATUnitOfMeasureFixedAsset(), SalesLine.Type::"Fixed Asset");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithGLAccountLineRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 491617] Request Stamp for Sales Invoice with G/L Account line
        Initialize();

        // [GIVEN] Posted Sales Invoice with G/L Account line "GLAcc"
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(), CreatePaymentMethodForSAT());
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccount."SAT Classification Code" := LibraryUtility.GenerateRandomCode(GLAccount.FieldNo("SAT Classification Code"), DATABASE::"G/L Account");
        GLAccount.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML");

        // [THEN] The stamp is received
        SalesInvoiceHeader.TestField("Electronic Document Status", SalesInvoiceHeader."Electronic Document Status"::"Stamp Received");
        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);

        // [THEN] 'Concepto' node has attributes 'ClaveProdServ' = SAT Classification Code of the G/L Account, 'NoIdentificacion' = "GLAcc", 'ClaveUnidad' = 'E48'
        // [THEN] String for digital stamp has 'ClaveProdServ' = SAT Classification Code of theG/L Account, 'NoIdentificacion' = "GLAcc", 'ClaveUnidad' = 'E48'
        VerifyCFDIConceptoFields(OriginalStr, GLAccount."No.", SATUtilities.GetSATUnitOfMeasureGLAccount(), SalesLine.Type::"G/L Account");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithNumeroPedimentoSubscriptionRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [SCENARIO 366659] Request Stamp for Sales Invoice with 'NumeroPedimento' using event subscriber
        Initialize();

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(
          CreateAndPostSalesDoc(SalesHeader."Document Type"::Invoice, CreatePaymentMethodForSAT()));

        NameValueBuffer.Init();
        NameValueBuffer.ID := CODEUNIT::"MX CFDI";
        NameValueBuffer.Name := '20 16 1742 0001871'; // value for signed string is separated with 1 space
        NameValueBuffer.Value := '20  16  1742  0001871'; // formatted as 2/2/4/7 digits separated with 2 spaces
        NameValueBuffer.Insert();

        // [WHEN] Request Stamp for the Sales Invoice with NumeroPedimento
        BindSubscription(MXCFDI);
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        UnbindSubscription(MXCFDI);

        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", "Signed Document XML");

        // [THEN] XML Document has node 'cfdi:Conceptos/cfdi:Concepto/cfdi:InformacionAduanera' with attribute 'NumeroPedimento' in proper format
        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:InformacionAduanera', 'NumeroPedimento', NameValueBuffer.Value);

        // [THEN] String for digital stamp has NumeroPedimento exported in proper format
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        Assert.AreEqual(
          NameValueBuffer.Name, SelectStr(38, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'NumeroPedimento', OriginalStr));

        NameValueBuffer.Delete();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithNumeroPedimentoSalesInvLineRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InStream: InStream;
        OriginalStr: Text;
        NumeroPedimentoStr: Text[30];
        NumeroPedimentoXml: Text[30];
    begin
        // [SCENARIO 458414] Request Stamp for Sales Invoice with 'NumeroPedimento' from Sales Invoice Line
        Initialize();

        // [GIVEN] Posted Sales Invoice has line with 'Custom Transit Number' = '20 16 1742 0001871'
        NumeroPedimentoStr := '20 16 1742 0001871';
        NumeroPedimentoXml := '20  16  1742  0001871'; // specific set of numbers formatted as 2/2/4/7 digits
        CreateSalesHeaderForCustomer(
            SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(), CreatePaymentMethodForSAT());
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItemWithPrice(LibraryRandom.RandIntInRange(1000, 2000)),
          LibraryRandom.RandIntInRange(1, 10), 0, 0, false, false);
        SalesLine."Custom Transit Number" := NumeroPedimentoStr;
        SalesLine.Modify();
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", "Signed Document XML");

        // [THEN] XML Document has node 'cfdi:Conceptos/cfdi:Concepto/cfdi:InformacionAduanera' with attribute 'NumeroPedimento' in proper format
        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:InformacionAduanera', 'NumeroPedimento', NumeroPedimentoXml);

        // [THEN] String for digital stamp has NumeroPedimento exported in proper format
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        Assert.AreEqual(
          NumeroPedimentoStr, SelectStr(38, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'NumeroPedimento', OriginalStr));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceLCYRoundingRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        InStream: InStream;
        OriginalStr: Text;
        ItemNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Sales] [Line Discount] [Rounding]
        // [SCENARIO 368294] Request Stamp for LCY Sales Invoice with multiple lines and "Amount Decimal Places" = 5 in G/L Setup
        Initialize();
        UpdateGLSetupRounding(':5');

        // [GIVEN] G/L Setup has "Amount Rounding Precision" = 0.00001, "Amount Decimal Places" = 5
        // [GIVEN] Posted Sales Invoice with VAT % = 16
        // [GIVEN] 4 lines with Unit Price = 32462.00, Quantity = 1, Line Discount = 5, Amount (without VAT) = 30838.90
        ItemNo := CreateItemWithPrice(32462.0);
        CreateSalesHeaderForCustomer(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(), CreatePaymentMethodForSAT());
        for i := 1 to 4 do
            CreateSalesLineItem(SalesLine, SalesHeader, ItemNo, 1, 5, 16, false, false);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.ModifyAll("Amount Including VAT", 35773.124); // emulate posting with 0.00001 rounding precision

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML");

        // [THEN] XML Document has node 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' with VAT data for the line
        // [THEN] and attributes 'Importe' = 4934.22400, 'TipoFactor' = 'Tasa', 'Impuesto' = '002', 'Base' = 30838.90.
        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        LibraryXPathXMLReader.VerityAttributeFromRootNode('Moneda', 'MXN');
        VerifyVATAmountLines(OriginalStr, 30838.9, 4934.224, 16, '002', 0, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceFCYRoundingRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        InStream: InStream;
        OriginalStr: Text;
        ItemNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Sales] [Line Discount] [Rounding]
        // [SCENARIO 368294] Request Stamp for FCY Sales Invoice with multiple lines and "Amount Decimal Places" = 5 in currency setup
        Initialize();
        UpdateGLSetupRounding(':2');

        // [GIVEN] Customer with currency having "Amount Rounding Precision" = 0.00001, "Amount Decimal Places" = 5
        Customer.Get(CreateCustomer());
        Customer.Validate("Currency Code", LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1));
        Customer.Modify(true);
        UpdateCurrencyWithRounding(Customer."Currency Code", 0.00001, ':5');

        // [GIVEN] Posted FCY Sales Invoice with VAT % = 16
        // [GIVEN] 4 lines with Unit Price = 32462.00, Quantity = 1, Line Discount = 5, Amount (without VAT) = 30838.90
        ItemNo := CreateItemWithPrice(32462.0);
        CreateSalesHeaderForCustomer(
          SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        for i := 1 to 4 do
            CreateSalesLineItem(SalesLine, SalesHeader, ItemNo, 1, 5, 16, false, false);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML");

        // [THEN] XML Document has node 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' with VAT data for the line
        // [THEN] and attributes 'Importe' = 4934.22400, 'TipoFactor' = 'Tasa', 'Impuesto' = '002', 'Base' = 30838.90.
        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        LibraryXPathXMLReader.VerityAttributeFromRootNode('Moneda', Customer."Currency Code");
        VerifyVATAmountLines(OriginalStr, 30838.9, 4934.224, 16, '002', 1, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceRetentionRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineRetention: Record "Sales Line";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [Retention]
        // [SCENARIO 389401] Request Stamp for Sales Invoice with retention line
        Initialize();

        // [GIVEN] Posted Sales Invoice with Amount = 1000, VAT Amount = 0
        // [GIVEN] Retention Line with Amount = -100, Retention VAT % = 10
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(), CreatePaymentMethodForSAT());
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItem(), LibraryRandom.RandIntInRange(100, 200), 0, 0, false, false);
        CreateSalesLineItem(
          SalesLineRetention, SalesHeader, CreateItem(), -LibraryRandom.RandIntInRange(1, 10), 0, 0, false, false);
        SalesLineRetention."Retention Attached to Line No." := SalesLine."Line No.";
        SalesLineRetention."Retention VAT %" := LibraryRandom.RandIntInRange(10, 16);
        SalesLineRetention.Modify();
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML");

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] Subtotal = 1000, Total = 900
        VerifyRootNodeTotals(
          OriginalStr, SalesLine."Amount Including VAT" + SalesLineRetention."Amount Including VAT", SalesLine."Amount Including VAT", 0);

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado'
        // [THEN] has attributes 'Importe' = 0, 'TipoFactor' = 'Tasa', 'Impuesto' = '002', 'Base' = 1000.
        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion'
        // [THEN] has attributes 'Importe' = 100, 'TipoFactor' = 'Tasa', 'Impuesto' = '002', 'Base' = 1000.
        VerifyVATAmountLines(
          OriginalStr, SalesLine."Amount Including VAT", 0, 0, '002', 0, 0);
        VerifyRetentionAmountLine(
          OriginalStr,
          SalesLine."Amount Including VAT", SalesLineRetention."Amount Including VAT",
          SalesLineRetention."Retention VAT %", GetTaxCodeRetention(SalesLineRetention."Retention VAT %"), 42, 0);

        // [THEN] 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has attributes 'Importe' = 0, 'TipoFactor' = 'Tasa', 'Impuesto' = '002'.
        // [THEN] 'cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion' has attributes 'Importe' = 100, 'Impuesto' = '002'.
        VerifyVATTotalLine(OriginalStr, 0, 0, '002', 0, 1, 8);
        VerifyRetentionTotalLine(
          OriginalStr, -SalesLineRetention."Amount Including VAT", GetTaxCodeRetention(SalesLineRetention."Retention VAT %"), 43, 0);

        // [THEN] Total Impuestos:  'cfdi:Impuestos/TotalImpuestosTrasladados' = 0, 'cfdi:Impuestos/TotalImpuestosRetenidos' = 100
        VerifyTotalImpuestos(OriginalStr, 'TotalImpuestosTrasladados', 0, 50);
        VerifyTotalImpuestos(OriginalStr, 'TotalImpuestosRetenidos', -SalesLineRetention."Amount Including VAT", 45);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoRetentionRequestStamp()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineRetention: Record "Sales Line";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [Retention]
        // [SCENARIO 389401] Request Stamp for Sales Credit Memo with retention line
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with Amount = 1000, VAT Amount = 0
        // [GIVEN] Retention Line with Amount = -100, Retention VAT % = 10
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomer(), CreatePaymentMethodForSAT());
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItem(), LibraryRandom.RandIntInRange(100, 200), 0, 0, false, false);
        CreateSalesLineItem(
          SalesLineRetention, SalesHeader, CreateItem(), -LibraryRandom.RandIntInRange(1, 10), 0, 0, false, false);
        SalesLineRetention."Retention Attached to Line No." := SalesLine."Line No.";
        SalesLineRetention."Retention VAT %" := LibraryRandom.RandIntInRange(10, 16);
        SalesLineRetention.Modify();
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Credit Memo
        RequestStamp(
          DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesCrMemoHeader.Find();
        SalesCrMemoHeader.CalcFields("Original String", "Original Document XML");

        InitXMLReaderForSalesDocumentCFDI(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Original Document XML"));
        SalesCrMemoHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] Subtotal = 1000, Total = 900
        VerifyRootNodeTotals(
          OriginalStr, SalesLine."Amount Including VAT" + SalesLineRetention."Amount Including VAT", SalesLine."Amount Including VAT", 0);

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado'
        // [THEN] has attributes 'Importe' = 0, 'TipoFactor' = 'Tasa', 'Impuesto' = '002', 'Base' = 1000.
        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion'
        // [THEN] has attributes 'Importe' = 100, 'TipoFactor' = 'Tasa', 'Impuesto' = '002', 'Base' = 1000.
        VerifyVATAmountLines(
          OriginalStr, SalesLine."Amount Including VAT", 0, 0, '002', 0, 0);
        VerifyRetentionAmountLine(
          OriginalStr,
          SalesLine."Amount Including VAT", SalesLineRetention."Amount Including VAT",
          SalesLineRetention."Retention VAT %", GetTaxCodeRetention(SalesLineRetention."Retention VAT %"), 42, 0);

        // [THEN] 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has attributes 'Importe' = 0, 'TipoFactor' = 'Tasa', 'Impuesto' = '002'.
        // [THEN] 'cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion' has attributes 'Importe' = 100, 'Impuesto' = '002'.
        VerifyVATTotalLine(OriginalStr, 0, 0, '002', 0, 1, 8);
        VerifyRetentionTotalLine(
          OriginalStr, -SalesLineRetention."Amount Including VAT", GetTaxCodeRetention(SalesLineRetention."Retention VAT %"), 43, 0);

        // [THEN] Total Impuestos:  'cfdi:Impuestos/TotalImpuestosTrasladados' = 0, 'cfdi:Impuestos/TotalImpuestosRetenidos' = 100
        VerifyTotalImpuestos(OriginalStr, 'TotalImpuestosTrasladados', 0, 50);
        VerifyTotalImpuestos(OriginalStr, 'TotalImpuestosRetenidos', -SalesLineRetention."Amount Including VAT", 45);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceRetentionTwoLinesRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineRetention1: Record "Sales Line";
        SalesLineRetention2: Record "Sales Line";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [Retention]
        // [SCENARIO 389401] Request Stamp for Sales Invoice with two retention lines
        Initialize();

        // [GIVEN] Posted Sales Invoice with Amount = 78000, VAT Amount = 12480, VAT % = 16
        // [GIVEN] Retention Line 1 with Amount = -7800, Retention VAT % = 10
        // [GIVEN] Retention Line 2 with Amount = -8319.948, Retention VAT % = 10.6666
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(), CreatePaymentMethodForSAT());
        CreateSalesLineItem(SalesLine, SalesHeader, CreateItem(), 1, 0, 16, false, false);
        SalesLine.Validate("Unit Price", 78000);
        SalesLine.Modify(true);
        CreateRetentionSalesLine(
          SalesLineRetention1, SalesHeader, SalesLine."Line No.", -1, SalesLine.Amount, 10);
        CreateRetentionSalesLine(
          SalesLineRetention2, SalesHeader, SalesLine."Line No.", -1, SalesLine.Amount, 10.6666);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML");

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] Subtotal = 78000, Total = 74360.05 (78000 + 12480 - 7800 - 8319.948)
        VerifyRootNodeTotals(
          OriginalStr,
          SalesLine."Amount Including VAT" + SalesLineRetention1."Amount Including VAT" + SalesLineRetention2."Amount Including VAT",
          SalesLine.Amount, 0);

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado'
        // [THEN] has attributes 'Importe' = 12480, 'TipoFactor' = 'Tasa', 'Impuesto' = '002', 'Base' = 78000.
        // [THEN] Line 1 of 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion'
        // [THEN] has attributes 'Importe' = 7800, 'TipoFactor' = 'Tasa', 'Impuesto' = '001', 'Base' = 78000.
        // [THEN] Line 2 of 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion'
        // [THEN] has attributes 'Importe' = 8319.948, 'TipoFactor' = 'Tasa', 'Impuesto' = '002', 'Base' = 78000.
        VerifyVATAmountLines(
          OriginalStr,
          SalesLine.Amount, SalesLine."Amount Including VAT" - SalesLine.Amount, SalesLine."VAT %",
          GetTaxCodeTraslado(SalesLine."VAT %"), 0, 0);
        VerifyRetentionAmountLine(
          OriginalStr,
          SalesLine.Amount, SalesLineRetention1.Amount, SalesLineRetention1."Retention VAT %",
          GetTaxCodeRetention(SalesLineRetention1."Retention VAT %"), 42, 0);
        VerifyRetentionAmountLine(
          OriginalStr,
          SalesLine.Amount,
          SalesLineRetention2."Unit Price" * SalesLineRetention2.Quantity, SalesLineRetention2."Retention VAT %",
          GetTaxCodeRetention(SalesLineRetention2."Retention VAT %"), 47, 1);

        // [THEN] 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has attributes 'Importe' = 12480, 'TipoFactor' = 'Tasa', 'Impuesto' = '002'.
        // [THEN] Line 1 of 'cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion' has attributes 'Importe' = 7800, 'Impuesto' = '001'.
        // [THEN] Line 2 of 'cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion' has attributes 'Importe' = 8319.95, 'Impuesto' = '002'.
        VerifyVATTotalLine(
          OriginalStr, SalesLine."Amount Including VAT" - SalesLine.Amount, SalesLine."VAT %",
          GetTaxCodeTraslado(SalesLine."VAT %"), 0, 1, 15);
        VerifyRetentionTotalLine(OriginalStr, -SalesLineRetention1."Amount Including VAT",
          GetTaxCodeRetention(SalesLineRetention1."Retention VAT %"), 48, 0);
        VerifyRetentionTotalLine(OriginalStr, -SalesLineRetention2."Amount Including VAT",
          GetTaxCodeRetention(SalesLineRetention2."Retention VAT %"), 50, 1);

        // [THEN] Total Impuestos:  'cfdi:Impuestos/TotalImpuestosTrasladados' = 12480, 'cfdi:Impuestos/TotalImpuestosRetenidos' = 16119.95
        VerifyTotalImpuestos(OriginalStr, 'TotalImpuestosTrasladados', SalesLine."Amount Including VAT" - SalesLine.Amount, 57);
        VerifyTotalImpuestos(OriginalStr, 'TotalImpuestosRetenidos', SalesLineRetention1.Amount + SalesLineRetention2.Amount, 52);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithZeroQuantityLineRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [Sales] [Order]
        // [SCENARIO 458110] Request stamp for the sales invoice having line with Quantity = 0
        Initialize();

        // [GIVEN] Sales Order has two lines:
        // [GIVEN] First line has Amount = 500, VAT Amount = 80, Quantity = 1
        // [GIVEN] First line has Amount = 1000, VAT Amount = 160, Quantity = 0
        CreateSalesHeaderForCustomer(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(), CreatePaymentMethodForSAT());
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItemWithPrice(LibraryRandom.RandIntInRange(100, 200)), 1, 0, 16, false, false);
        SalesLine.Validate(Quantity, 0);
        SalesLine.Modify(true);
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItemWithPrice(LibraryRandom.RandIntInRange(100, 200)), 1, 0, 16, false, false);

        // [GIVEN] Posted sales invoice with the Quantity = 0 in the first line
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto' node has ValorUnitario = 1000.00, Importe = 1000.00, Descuento = 0 are exported
        // [THEN] 'Traslado' node has Importe = 640.00
        VerifyLineAmountsByIndex(
          0, SalesLine.Amount, SalesLine."Unit Price",
          SalesLine."Amount Including VAT" - SalesLine.Amount, SalesLine.Amount, 0);
        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has VAT data for each line
        // [THEN] 1st line: 'Base' = 1000.00, 'Importe' = 640.00.
        VerifyVATAmountLines(
          OriginalStr, SalesLine.Amount, SalesLine."Amount Including VAT" - SalesLine.Amount, SalesLine."VAT %", '002', 0, 0);
        VerifyVATTotalLine(
          OriginalStr,
          SalesLine."Amount Including VAT" - SalesLine.Amount, SalesLine."VAT %", '002', 0, 1, 0);
        // [THEN] Total VAT line in 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has 'Importe' = 1160.00
        // [THEN] Total VAT Amount in 'cfdi:Impuestos/TotalImpuestosTrasladados' = 1160.00
        VerifyTotalImpuestos(
          OriginalStr, 'TotalImpuestosTrasladados', SalesLine."Amount Including VAT" - SalesLine.Amount, 42);
        // [THEN] Only one node 'cfdi:Conceptos/cfdi:Concepto' is exported
        LibraryXPathXMLReader.VerifyNodeCountByXPath('cfdi:Conceptos/cfdi:Concepto', 1);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorLogSalesInvoiceForeignTrade()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Sales] [UI] [Comercio Exterior]
        // [SCENARIO 449449] Request stamp for foreign trade invoice when mandatory fields are empty
        Initialize();

        // [GIVEN] Posted Sales Invoice with Foreign Trade = True
        SalesInvoiceHeader.Get(CreateAndPostSalesDoc(SalesHeader."Document Type"::Invoice, CreatePaymentMethodForSAT()));
        SalesInvoiceHeader."Foreign Trade" := true;
        SalesInvoiceHeader."Exchange Rate USD" := 0;
        SalesInvoiceHeader.Modify();
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        Item.Get(SalesInvoiceLine."No.");
        Item."Tariff No." := '';
        Item.Modify();
        UnitOfMeasure.Get(SalesInvoiceLine."Unit of Measure");
        UnitOfMeasure."SAT Customs Unit" := '';
        UnitOfMeasure.Modify();

        // [WHEN] Request Stamp for the Sales Invoice
        ErrorMessages.Trap();
        asserterror
          RequestStamp(
            DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for missed values
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceHeader.FieldCaption("SAT Address ID"), SalesInvoiceHeader.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceHeader.FieldCaption("SAT International Trade Term"), SalesInvoiceHeader.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceHeader.FieldCaption("Exchange Rate USD"), SalesInvoiceHeader.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceHeader.FieldCaption("Location Code"), SalesInvoiceHeader.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, Item.FieldCaption("Tariff No."), Item.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, UnitOfMeasure.FieldCaption("SAT Customs Unit"), UnitOfMeasure.RecordId));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure RequestStampSalesInvoiceForeignTrade()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InStream: InStream;
        OriginalStr: Text;
        ExchRateAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Comercio Exterior]
        // [SCENARIO 449449] Request Stamp for foreign trade LCY invoice
        Initialize();

        // [GIVEN] USD currency has Exchange Rate = 20, Amount = 2000, Amount Including VAT = 3200
        ExchRateAmount := SetupUSDCurrencyGLSetup();
        // [GIVEN] Posted Sales Invoice for foreign trade with Quantity = 2, Unit Price = 1000, VAT % = 16
        Customer.Get(CreateCustomer());
        Customer."VAT Registration No." := LibraryUtility.GenerateGUID();
        Customer."RFC No." := GetForeignRFCNo();
        Customer.Modify();
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        UpdateSalesHeaderForeignTrade(SalesHeader);
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItemWithPrice(LibraryRandom.RandIntInRange(1000, 2000)), 2, 0, 16, false, false);
        UpdateSalesLineForeingTrade(SalesLine);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InitXMLReaderForSalesDocumentCCE(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] 'DomicilioFiscalReceptor' is exported from Bill-to Post Code (TFS 547550)
        VerifyPartyInformation(
          OriginalStr, Customer."RFC No.", Customer."CFDI Customer Name", SalesInvoiceHeader."Bill-to Post Code", Customer."SAT Tax Regime Classification", 18, 22);
        // [THEN] Comercio Exterior node has TipoCambioUSD = 20, TotalUSD = 100 (2000 / 20)
        VerifyComercioExteriorHeader(
          OriginalStr, SalesInvoiceHeader."SAT International Trade Term",
          SalesInvoiceHeader."Exchange Rate USD", SalesInvoiceHeader.Amount / SalesInvoiceHeader."Exchange Rate USD", 45);
        // [THEN] ComercioExterior/Mercancia has CantidadAduana = 2, ValorUnitarioAduana = 50 (1000 / 20), ValorDolares = 100 (2000 / 20) (TFS 472803)
        VerifyComercioExteriorLine(
          OriginalStr, SalesLine, SalesLine.Quantity,
          ROUND(SalesLine."Unit Price" / ExchRateAmount, 0.000001, '<'), SalesLine.Amount / ExchRateAmount, 66, 0);
        // [THEN] NumRegIdTrib contains "VAT Registration No." from Customer for foreign customer (TFS 471571)
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cce20:ComercioExterior/cce20:Receptor',
          'NumRegIdTrib', Customer."VAT Registration No.");
        Assert.AreEqual(
          Customer."VAT Registration No.",
          SELECTSTR(58, OriginalStr), STRSUBSTNO(IncorrectOriginalStrValueErr, 'NumRegIdTrib', OriginalStr));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure RequestStampSalesInvoiceFCY2LinesForeignTradeVAT0()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InStream: InStream;
        OriginalStr: Text;
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [Sales] [Comercio Exterior] [Rounding] [Currency]
        // [SCENARIO 474827] Request Stamp for foreign trade FCY invoice with 2 lines of VAT = 0
        Initialize();

        // [GIVEN] Posted sales invoice for foreign trade of Amount = 86 USD with Exchange Rate = 17.672300
        // [GIVEN] Line 1: item1/ qty = 2, price = 13, VAT = 0
        // [GIVEN] Line 2: item2/ qty = 4, price = 15, VAT = 0
        // [GIVEN] USD exchange rate = 17.825200
        Customer.Get(CreateCustomer());
        Customer.Validate("Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1 / 17.6723, 1 / 17.6723));
        Customer.Modify(true);
        CreateSalesHeaderForCustomer(
          SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        SalesHeader.Validate("Exchange Rate USD", 17.8252);
        SalesHeader.Modify(true);
        UpdateSalesHeaderForeignTrade(SalesHeader);

        VATProdPostingGroup := CreateVATPostingSetup(Customer."VAT Bus. Posting Group", 0, false, false);
        CreateSalesLineItemWithVATSetup(SalesLine1, SalesHeader, CreateItem(), VATProdPostingGroup, 2, 13, 0);
        UpdateSalesLineForeingTrade(SalesLine1);
        CreateSalesLineItemWithVATSetup(SalesLine2, SalesHeader, CreateItem(), VATProdPostingGroup, 4, 15, 0);
        UpdateSalesLineForeingTrade(SalesLine2);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InitXMLReaderForSalesDocumentCCE(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] Comercio Exterior node has TipoCambioUSD = 17.825200, TotalUSD = 85.26
        // [THEN] Line1 'cce20:Mercancia' node has CantidadAduana = 2, ValorUnitarioAduana = 12.888489, ValorDolares = 25.7770
        // [THEN] Line2 'cce20:Mercancia' node has CantidadAduana = 4, ValorUnitarioAduana = 14.871333, ValorDolares = 59.4853
        VerifyComercioExteriorHeader(
          OriginalStr, SalesInvoiceHeader."SAT International Trade Term",
          SalesInvoiceHeader."Exchange Rate USD", 85.26, 60);
        VerifyComercioExteriorLine(OriginalStr, SalesLine1, 2, 12.888489, 25.7770, 80, 0);
        VerifyComercioExteriorLine(OriginalStr, SalesLine2, 4, 14.871333, 59.4853, 86, 1);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure RequestStampSalesInvoiceFCY2LinesForeignTradeVAT16()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InStream: InStream;
        OriginalStr: Text;
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [Sales] [Comercio Exterior] [Rounding] [Currency]
        // [SCENARIO 474827] Request Stamp for foreign trade FCY invoice with 2 lines of VAT = 16
        Initialize();

        // [GIVEN] Posted sales invoice for foreign trade of Amount = 86 USD with Exchange Rate = 17.00
        // [GIVEN] Line 1: item1/ qty = 2, price = 13, VAT = 16
        // [GIVEN] Line 2: item2/ qty = 4, price = 15, VAT = 16
        // [GIVEN] USD exchange rate = 17.567300
        Customer.Get(CreateCustomer());
        Customer.Validate("Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1 / 17.0, 1 / 17.0));
        Customer.Modify(true);
        CreateSalesHeaderForCustomer(
          SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        SalesHeader.Validate("Exchange Rate USD", 17.5673);
        SalesHeader.Modify(true);
        UpdateSalesHeaderForeignTrade(SalesHeader);

        VATProdPostingGroup := CreateVATPostingSetup(Customer."VAT Bus. Posting Group", 0, false, false);
        CreateSalesLineItemWithVATSetup(SalesLine1, SalesHeader, CreateItem(), VATProdPostingGroup, 2, 13, 0);
        UpdateSalesLineForeingTrade(SalesLine1);
        CreateSalesLineItemWithVATSetup(SalesLine2, SalesHeader, CreateItem(), VATProdPostingGroup, 4, 15, 0);
        UpdateSalesLineForeingTrade(SalesLine2);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InitXMLReaderForSalesDocumentCCE(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] Comercio Exterior node has TipoCambioUSD = 17.567300, TotalUSD = 83.22
        // [THEN] Line1 'cce20:Mercancia' node has CantidadAduana = 2, ValorUnitarioAduana = 12.580191, ValorDolares = 25.1604
        // [THEN] Line2 'cce20:Mercancia' node has CantidadAduana = 4, ValorUnitarioAduana = 14.515605, ValorDolares = 58.0624
        VerifyComercioExteriorHeader(
          OriginalStr, SalesInvoiceHeader."SAT International Trade Term",
          SalesInvoiceHeader."Exchange Rate USD", 83.22, 60);
        VerifyComercioExteriorLine(OriginalStr, SalesLine1, 2, 12.580191, 25.1604, 80, 0);
        VerifyComercioExteriorLine(OriginalStr, SalesLine2, 4, 14.515605, 58.0624, 86, 1);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure RequestStampSalesInvoiceFCY2LinesForeignTradeVAT0HigherExchRate()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InStream: InStream;
        OriginalStr: Text;
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [Sales] [Comercio Exterior] [Rounding] [Currency]
        // [SCENARIO 474827] Request Stamp for foreign trade FCY invoice with 2 lines of VAT = 0 and exchange rate of invoice is high
        Initialize();

        // [GIVEN] Posted sales invoice for foreign trade of Amount = 86 USD with Exchange Rate = 20.00
        // [GIVEN] Line 1: item1/ qty = 2, price = 13, VAT = 0
        // [GIVEN] Line 2: item2/ qty = 4, price = 15, VAT = 0
        // [GIVEN] USD exchange rate = 17.567300
        Customer.Get(CreateCustomer());
        Customer.Validate("Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1 / 20.0, 1 / 20.0));
        Customer.Modify(true);
        CreateSalesHeaderForCustomer(
          SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        SalesHeader.Validate("Exchange Rate USD", 17.5673);
        SalesHeader.Modify(true);
        UpdateSalesHeaderForeignTrade(SalesHeader);

        VATProdPostingGroup := CreateVATPostingSetup(Customer."VAT Bus. Posting Group", 0, false, false);
        CreateSalesLineItemWithVATSetup(SalesLine1, SalesHeader, CreateItem(), VATProdPostingGroup, 2, 13, 0);
        UpdateSalesLineForeingTrade(SalesLine1);
        CreateSalesLineItemWithVATSetup(SalesLine2, SalesHeader, CreateItem(), VATProdPostingGroup, 4, 15, 0);
        UpdateSalesLineForeingTrade(SalesLine2);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InitXMLReaderForSalesDocumentCCE(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] Comercio Exterior node has TipoCambioUSD = 17.567300, TotalUSD = 97.91
        // [THEN] Line1 'cce20:Mercancia' node has CantidadAduana = 2, ValorUnitarioAduana = 14.800225, ValorDolares = 29.6005
        // [THEN] Line2 'cce20:Mercancia' node has CantidadAduana = 4, ValorUnitarioAduana = 17.077183, ValorDolares = 68.3087
        VerifyComercioExteriorHeader(
          OriginalStr, SalesInvoiceHeader."SAT International Trade Term",
          SalesInvoiceHeader."Exchange Rate USD", 97.91, 60);
        VerifyComercioExteriorLine(OriginalStr, SalesLine1, 2, 14.800225, 29.6005, 80, 0);
        VerifyComercioExteriorLine(OriginalStr, SalesLine2, 4, 17.077183, 68.3087, 86, 1);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure RequestStampSalesInvoiceFCY2LinesSameItemForeignTradeVAT0()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InStream: InStream;
        OriginalStr: Text;
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [Sales] [Comercio Exterior] [Rounding] [Currency]
        // [SCENARIO 474827] Request Stamp for foreign trade FCY invoice with 2 lines with same item of VAT = 0
        Initialize();

        // [GIVEN] Posted sales invoice for foreign trade of Amount = 86 USD with Exchange Rate = 18.623200
        // [GIVEN] Line 1: item/ qty = 2, price = 13, VAT = 0
        // [GIVEN] Line 2: item/ qty = 4, price = 15, VAT = 0
        // [GIVEN] USD exchange rate = 17.506300
        Customer.Get(CreateCustomer());
        Customer.Validate("Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1 / 18.6232, 1 / 18.6232));
        Customer.Modify(true);
        CreateSalesHeaderForCustomer(
          SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        SalesHeader.Validate("Exchange Rate USD", 17.5063);
        SalesHeader.Modify(true);
        UpdateSalesHeaderForeignTrade(SalesHeader);

        VATProdPostingGroup := CreateVATPostingSetup(Customer."VAT Bus. Posting Group", 0, false, false);
        CreateSalesLineItemWithVATSetup(SalesLine1, SalesHeader, CreateItem(), VATProdPostingGroup, 2, 13, 0);
        UpdateSalesLineForeingTrade(SalesLine1);
        CreateSalesLineItemWithVATSetup(SalesLine2, SalesHeader, SalesLine1."No.", VATProdPostingGroup, 4, 15, 0);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InitXMLReaderForSalesDocumentCCE(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] Comercio Exterior node has TipoCambioUSD = 17.506300, TotalUSD = 91.49
        // [THEN] One line 'cce20:Mercancia' node has CantidadAduana = 6, ValorUnitarioAduana = 15.247798, ValorDolares = 91.4868
        VerifyComercioExteriorHeader(
          OriginalStr, SalesInvoiceHeader."SAT International Trade Term",
          SalesInvoiceHeader."Exchange Rate USD", 91.49, 60);
        VerifyComercioExteriorLine(OriginalStr, SalesLine1, 6, 15.247798, 91.4868, 80, 0);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('cfdi:Complemento/cce20:ComercioExterior/cce20:Mercancias/cce20:Mercancia', 1);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure RequestStampSalesPrepaymentLCY()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InStream: InStream;
        OriginalStr: Text;
        BaseAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Prepayment] [Advance Payment]
        // [SCENARIO 523733] Request stamp for prepayment LCY invoice
        Initialize();

        // [GIVEN] Sales order with prepayment = 50%, Amount Including VAT = 4640, VAT = 16%
        Customer.Get(CreateCustomer());
        UpdateCustomerSATPaymentFields(Customer."No.");
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.", CreatePaymentMethodForSAT());
        SalesHeader.Validate(SalesHeader."Prepayment %", LibraryRandom.RandIntInRange(10, 50));
        SalesHeader.Modify(true);
        CreateSalesLineItem(SalesLine, SalesHeader, CreateItem(), LibraryRandom.RandIntInRange(2, 5), 0, 16, false, false);
        // [GIVEN] Posted prepayment invoice, Amount Including VAT = 2320, VAT = 16%
        SalesInvoiceHeader.Get(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader));

        // [WHEN] Request Stamp for the Sales Prepayment Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] Original string has 'Moneda' = MXN, no 'TipoCambio' attribute
        LibraryXPathXMLReader.VerityAttributeFromRootNode('Moneda', 'MXN');
        asserterror LibraryXPathXMLReader.VerityAttributeFromRootNode('TipoCambio', '1');
        Assert.AreEqual('MXN', SelectStr(8, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Moneda', OriginalStr));

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto' has attributes ClaveProdServ="84111506" Cantidad="1" ClaveUnidad="ACT" ValorUnitario="2000" Importe="2000"
        BaseAmount := SalesLine.Amount * SalesHeader."Prepayment %" / 100;
        VerifyConceptoNode(
          OriginalStr, '84111506', '1', 'ACT', 'Anticipo bien o servicio', FormatDecimal(BaseAmount, 2), FormatDecimal(BaseAmount, 2), 22);

        // [THEN] Total VAT line in 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has 'Base' = 2000, 'Importe' = 320
        // [THEN] Total VAT Amount in 'cfdi:Impuestos/TotalImpuestosTrasladados' =  320
        VATAmount := Round(SalesLine.Amount * SalesHeader."Prepayment %" / 100) * SalesLine."VAT %" / 100;
        VerifyVATAmountLines(OriginalStr, Round(BaseAmount), VATAmount, SalesLine."VAT %", '002', -4, 0);
        VerifyVATTotalLine(OriginalStr, VATAmount, 16, '002', 0, 1, -4);
        VerifyTotalImpuestos(OriginalStr, 'TotalImpuestosTrasladados', VATAmount, 38);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure RequestStampSalesPrepaymentFCY()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InStream: InStream;
        OriginalStr: Text;
        BaseAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Prepayment] [Advance Payment]
        // [SCENARIO 523733] Request stamp for prepayment invoice with foreign currency
        Initialize();

        // [GIVEN] Sales order in USD with prepayment = 50%, Amount Including VAT = 4640, VAT = 16%
        Customer.Get(CreateCustomer());
        Customer.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        Customer.Modify(true);
        UpdateCustomerSATPaymentFields(Customer."No.");
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.", CreatePaymentMethodForSAT());
        SalesHeader.Validate(SalesHeader."Prepayment %", LibraryRandom.RandIntInRange(10, 50));
        SalesHeader.Modify(true);
        CreateSalesLineItem(SalesLine, SalesHeader, CreateItem(), LibraryRandom.RandIntInRange(2, 5), 0, 16, false, false);

        // [GIVEN] Posted prepayment invoice, Amount Including VAT = 2320, VAT = 16%
        SalesInvoiceHeader.Get(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader));

        // [WHEN] Request Stamp for the Sales Prepayment Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        InitXMLReaderForSalesDocumentCFDI(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] Original string has 'Moneda' = USD, 'TipoCambio' attribute is exported
        LibraryXPathXMLReader.VerityAttributeFromRootNode('Moneda', SalesInvoiceHeader."Currency Code");
        LibraryXPathXMLReader.VerityAttributeFromRootNode('TipoCambio', FormatDecimal(1 / SalesInvoiceHeader."Currency Factor", 6));
        Assert.AreEqual(SalesInvoiceHeader."Currency Code", SelectStr(8, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Moneda', OriginalStr));
        Assert.AreEqual(FormatDecimal(1 / SalesInvoiceHeader."Currency Factor", 6), SelectStr(9, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'TipoCambio', OriginalStr));

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto' has attributes ClaveProdServ="84111506" Cantidad="1" ClaveUnidad="ACT" ValorUnitario="2000" Importe="2000"
        BaseAmount := SalesLine.Amount * SalesHeader."Prepayment %" / 100;
        VerifyConceptoNode(
          OriginalStr, '84111506', '1', 'ACT', 'Anticipo bien o servicio', FormatDecimal(BaseAmount, 2), FormatDecimal(BaseAmount, 2), 23);

        // [THEN] Total VAT line in 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has 'Base' = 2000, 'Importe' = 320
        // [THEN] Total VAT Amount in 'cfdi:Impuestos/TotalImpuestosTrasladados' =  320
        VATAmount := Round(SalesLine.Amount * SalesHeader."Prepayment %" / 100) * SalesLine."VAT %" / 100;
        VerifyVATAmountLines(OriginalStr, Round(BaseAmount), VATAmount, SalesLine."VAT %", '002', -3, 0);
        VerifyVATTotalLine(OriginalStr, VATAmount, 16, '002', 0, 1, -3);
        VerifyTotalImpuestos(OriginalStr, 'TotalImpuestosTrasladados', VATAmount, 39);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenRequestStampForSalesShipmentCartaPorte()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FixedAsset: Record "Fixed Asset";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Carta Porte] [Sales]
        // [SCENARIO 406136] Request Stamp for Sales Shipment Carta Porte complemento
        Initialize();

        // [GIVEN] Posted Sales Invoice
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(), CreatePaymentMethodForSAT());
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItem(), LibraryRandom.RandIntInRange(100, 200), 0, 0, false, false);

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesShipmentHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesShipmentHeader.FindFirst();
        // [GIVEN] Fixed Asset in Vehicle field has "SCT SCT Permission No." and "SCT Permission Type" blank
        FixedAsset.Get(CreateVehicle());
        FixedAsset."SCT Permission No." := '';
        FixedAsset."SCT Permission Type" := '';
        FixedAsset.Modify();
        SalesShipmentHeader."Vehicle Code" := FixedAsset."No.";
        SalesShipmentHeader.Modify();

        // [WHEN] Request Stamp for the Sales Shipment
        ErrorMessages.Trap();
        asserterror
          RequestStamp(
            DATABASE::"Sales Shipment Header", SalesShipmentHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for "PAC Code", "PAC Environment", "SAT Certificate" fields
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesShipmentHeader.FieldCaption("Transit-from Date/Time"), SalesShipmentHeader.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesShipmentHeader.FieldCaption("Transit Hours"), SalesShipmentHeader.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesShipmentHeader.FieldCaption("Transit Distance"), SalesShipmentHeader.RecordId));

        // [THEN] Error Messages page shows error for blank values in "SCT Permission Type" and "SCT Permission No." (TFS 449447)
        ErrorMessages.FILTER.SetFilter("Record ID", Format(FixedAsset.RecordId));
        ErrorMessages.First();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, FixedAsset.FieldCaption("SCT Permission Type"), FixedAsset.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, FixedAsset.FieldCaption("SCT Permission No."), FixedAsset.RecordId));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenRequestStampForSalesShipmentCartaPorteForeignTrade()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Carta Porte] [Sales] [Foreign Trade]
        // [SCENARIO 491440] Request Stamp for Sales Shipment Carta Porte complemento for foreign trade
        Initialize();

        // [GIVEN] Posted Sales Invoice with Foreign Trade = True
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(), CreatePaymentMethodForSAT());
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItem(), LibraryRandom.RandIntInRange(100, 200), 0, 0, false, false);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesShipmentHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesShipmentHeader.FindFirst();
        UpdateSalesShipmentForCartaPorte(SalesShipmentHeader);
        SalesShipmentHeader."Foreign Trade" := true;
        SalesShipmentHeader."Exchange Rate USD" := 0;
        SalesShipmentHeader.Modify();

        // [WHEN] Request Stamp for the Sales Shipment
        ErrorMessages.Trap();
        asserterror
          RequestStamp(
            DATABASE::"Sales Shipment Header", SalesShipmentHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for 'foreign trade' fields:
        // [THEN] "SAT International Trade Term", "SAT Customs Regime", "SAT Transfer Reason", "Exchange Rate USD"
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesShipmentHeader.FieldCaption("SAT International Trade Term"), SalesShipmentHeader.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesShipmentHeader.FieldCaption("SAT Customs Regime"), SalesShipmentHeader.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesShipmentHeader.FieldCaption("SAT Transfer Reason"), SalesShipmentHeader.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesShipmentHeader.FieldCaption("Exchange Rate USD"), SalesShipmentHeader.RecordId));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenRequestStampTransferShipmentCartaPorte()
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferLine: Record "Transfer Line";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Carta Porte] [Transfer]
        // [SCENARIO 406136] Request Stamp for Transfer Shipment Carta Porte complemento
        Initialize();

        // [GIVEN] Posted Transfer Shipment
        CreateTransferItem(LocationFrom, LocationTo, Item);
        CreateTransferShipment(TransferShipmentHeader, TransferLine, LocationFrom, LocationTo, Item."No.");

        // [WHEN] Request Stamp for the Transfer Shipment
        ErrorMessages.Trap();
        asserterror
          RequestStamp(
            DATABASE::"Transfer Shipment Header", TransferShipmentHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, TransferShipmentHeader.FieldCaption("Transit-from Date/Time"), TransferShipmentHeader.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, TransferShipmentHeader.FieldCaption("Transit Hours"), TransferShipmentHeader.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, TransferShipmentHeader.FieldCaption("Transit Distance"), TransferShipmentHeader.RecordId));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenRequestStampTransferShipmentCartaPorteForeignTrade()
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferLine: Record "Transfer Line";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Carta Porte] [Transfer]
        // [SCENARIO 491440] Request Stamp for Transfer Shipment Carta Porte complemento for foreign trade
        Initialize();

        // [GIVEN] Posted Transfer Shipment with foreign trade = true
        CreateTransferItem(LocationFrom, LocationTo, Item);
        CreateTransferShipment(TransferShipmentHeader, TransferLine, LocationFrom, LocationTo, Item."No.");
        UpdateTransferShipmentForCartaPorte(TransferShipmentHeader);
        TransferShipmentHeader."Foreign Trade" := true;
        TransferShipmentHeader."Exchange Rate USD" := 0;
        TransferShipmentHeader.Modify();

        // [WHEN] Request Stamp for the Transfer Shipment
        ErrorMessages.Trap();
        asserterror
          RequestStamp(
            DATABASE::"Transfer Shipment Header", TransferShipmentHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for 'foreign trade' fields:
        // [THEN] "SAT International Trade Term", "SAT Customs Regime", "SAT Transfer Reason", "Exchange Rate USD"
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, TransferShipmentHeader.FieldCaption("SAT International Trade Term"), TransferShipmentHeader.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, TransferShipmentHeader.FieldCaption("SAT Customs Regime"), TransferShipmentHeader.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, TransferShipmentHeader.FieldCaption("SAT Transfer Reason"), TransferShipmentHeader.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, TransferShipmentHeader.FieldCaption("Exchange Rate USD"), TransferShipmentHeader.RecordId));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesShipmentCartaPorteRequestStamp()
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: record Location;
        CompanyInformation: record "Company Information";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [Carta Porte] [Sales]
        // [SCENARIO 406136] Request Stamp for Sales Shipment Carta Porte complemento
        Initialize();

        // [GIVEN] Posted Sales Invoice
        Customer.get(CreateCustomer());
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItem(), LibraryRandom.RandIntInRange(100, 200), 0, 0, false, false);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesShipmentHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesShipmentHeader.FindFirst();
        UpdateSalesShipmentForCartaPorte(SalesShipmentHeader);
        Location.get(SalesShipmentHeader."Location Code");
        CompanyInformation.Get();

        // [WHEN] Request Stamp for the Sales Shipment
        RequestStamp(
          DATABASE::"Sales Shipment Header", SalesShipmentHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesShipmentHeader.Find();
        SalesShipmentHeader.CalcFields("Original String", "Original Document XML");

        InitXMLReaderForCartaPorte(SalesShipmentHeader, SalesShipmentHeader.FieldNo("Original Document XML"));
        SalesShipmentHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] Carta Porte XML is created for the document
        // [THEN] Receptor node has Rfc, Nombre, RegimenFiscalReceptor, DomicilioFiscalReceptor taken from Company Information (TFS 473426, 487886)
        VerifyPartyInformation(
          OriginalStr,
          CompanyInformation."RFC Number", CompanyInformation.Name, CompanyInformation."SAT Postal Code", CompanyInformation."SAT Tax Regime Classification", 15, 18);
        VerifyCartaPorteXMLValues(
            OriginalStr, SalesShipmentHeader."Identifier IdCCP",
            SalesShipmentHeader."Transit Distance", SalesShipmentHeader."Vehicle Code", SalesLine."Gross Weight" * SalesLine.Quantity, 29);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesShipmentCartaPorteRequestStampForeignTrade()
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: record Location;
        CompanyInformation: record "Company Information";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [Carta Porte] [Sales]
        // [SCENARIO 491440] Request Stamp for Sales Shipment Carta Porte complemento for foreign trade
        Initialize();

        // [GIVEN] Posted Sales Invoice with Foreign Trade = True
        Customer.get(CreateCustomer());
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItem(), LibraryRandom.RandIntInRange(100, 200), 0, 0, false, false);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesShipmentHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesShipmentHeader.FindFirst();
        UpdateSalesShipmentForCartaPorte(SalesShipmentHeader);
        UpdateSalesShipmentForCartaPorteForeignTrade(SalesShipmentHeader);
        Location.Get(SalesShipmentHeader."Location Code");
        CompanyInformation.Get();

        // [WHEN] Request Stamp for the Sales Shipment
        RequestStamp(
          DATABASE::"Sales Shipment Header", SalesShipmentHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesShipmentHeader.Find();
        SalesShipmentHeader.CalcFields("Original String", "Original Document XML");

        InitXMLReaderForCartaPorte(SalesShipmentHeader, SalesShipmentHeader.FieldNo("Original Document XML"));
        SalesShipmentHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] Carta Porte XML is created for the document with ComercioExterior complement and fields related to foreign trade
        VerifyPartyInformation(
          OriginalStr,
          CompanyInformation."RFC Number", CompanyInformation.Name, CompanyInformation."SAT Postal Code", CompanyInformation."SAT Tax Regime Classification", 15, 18);
        VerifyCartaPorteXMLValuesForeignTrade(
            OriginalStr,
            SalesShipmentHeader."Identifier IdCCP", SalesShipmentHeader."SAT Transfer Reason", SalesShipmentHeader."SAT International Trade Term",
            SalesShipmentHeader."Exchange Rate USD", SalesShipmentHeader."SAT Customs Regime", 29);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferShipmentCartaPorteRequestStamp()
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferLine: Record "Transfer Line";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        Location: Record Location;
        CompanyInformation: Record "Company Information";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [Carta Porte] [Transfer]
        // [SCENARIO 406136] Request Stamp for Transfer Shipment Carta Porte complemento
        Initialize();

        // [GIVEN] Posted Transfer Shipment
        CreateTransferItem(LocationFrom, LocationTo, Item);
        CreateTransferShipment(TransferShipmentHeader, TransferLine, LocationFrom, LocationTo, Item."No.");
        UpdateTransferShipmentForCartaPorte(TransferShipmentHeader);
        Location.get(TransferShipmentHeader."Transfer-to Code");
        CompanyInformation.Get();

        // [WHEN] Request Stamp for the Transfer Shipment
        RequestStamp(
          DATABASE::"Transfer Shipment Header", TransferShipmentHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        TransferShipmentHeader.Find();
        TransferShipmentHeader.CalcFields("Original String", "Original Document XML");

        InitXMLReaderForCartaPorte(TransferShipmentHeader, TransferShipmentHeader.FieldNo("Original Document XML"));
        TransferShipmentHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] Carta Porte XML is created for the document
        // [THEN] Receptor node has Rfc, Nombre, RegimenFiscalReceptor, DomicilioFiscalReceptor taken from Company Information (TFS 473426, 487886)
        VerifyPartyInformation(
          OriginalStr,
          CompanyInformation."RFC Number", CompanyInformation.Name, CompanyInformation."SAT Postal Code", CompanyInformation."SAT Tax Regime Classification", 15, 18);
        VerifyCartaPorteXMLValues(
          OriginalStr, TransferShipmentHeader."Identifier IdCCP",
          TransferShipmentHeader."Transit Distance", TransferShipmentHeader."Vehicle Code", TransferLine."Gross Weight" * TransferLine.Quantity, 29);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferShipmentCartaPorteRequestStampForeignTrade()
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferLine: Record "Transfer Line";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        Location: Record Location;
        CompanyInformation: Record "Company Information";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [Carta Porte] [Transfer]
        // [SCENARIO 491440] Request Stamp for Transfer Shipment Carta Porte complemento for foreign trade
        Initialize();

        // [GIVEN] Posted Transfer Shipment
        CreateTransferItem(LocationFrom, LocationTo, Item);
        CreateTransferShipment(TransferShipmentHeader, TransferLine, LocationFrom, LocationTo, Item."No.");
        UpdateTransferShipmentForCartaPorte(TransferShipmentHeader);
        UpdateTransferShipmentForCartaPorteForeignTrade(TransferShipmentHeader);
        Location.get(TransferShipmentHeader."Transfer-to Code");
        CompanyInformation.Get();

        // [WHEN] Request Stamp for the Transfer Shipment with Foreign Trade = true
        RequestStamp(
          DATABASE::"Transfer Shipment Header", TransferShipmentHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        TransferShipmentHeader.Find();
        TransferShipmentHeader.CalcFields("Original String", "Original Document XML");

        InitXMLReaderForCartaPorte(TransferShipmentHeader, TransferShipmentHeader.FieldNo("Original Document XML"));
        TransferShipmentHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] Carta Porte XML is created for the document with ComercioExterior complement and fields related to foreign trade
        VerifyPartyInformation(
          OriginalStr,
          CompanyInformation."RFC Number", CompanyInformation.Name, CompanyInformation."SAT Postal Code", CompanyInformation."SAT Tax Regime Classification", 15, 18);
        VerifyCartaPorteXMLValuesForeignTrade(
          OriginalStr, TransferShipmentHeader."Identifier IdCCP",
          TransferShipmentHeader."SAT Transfer Reason", TransferShipmentHeader."SAT International Trade Term",
          TransferShipmentHeader."Exchange Rate USD", TransferShipmentHeader."SAT Customs Regime", 29);
    end;

    [Test]
    [HandlerFunctions('CartaPorteReqPageHandler')]
    [Scope('OnPrem')]
    procedure SalesShipmentCartaPortePrint()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ElectronicCartaPorteMX: Report "Electronic Carta Porte MX";
    begin
        // [FEATURE] [Carta Porte] [Sales] [Report]
        // [SCENARIO 406136] Request Stamp for Sales Shipment Carta Porte complemento
        Initialize();

        // [GIVEN] Posted Sales Invoice
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(), CreatePaymentMethodForSAT());
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItem(), LibraryRandom.RandIntInRange(100, 200), 0, 0, false, false);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesShipmentHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesShipmentHeader.FindFirst();
        UpdateSalesShipmentForCartaPorte(SalesShipmentHeader);

        // [GIVEN] Request Stamp for the Sales Shipment
        RequestStamp(
          DATABASE::"Sales Shipment Header", SalesShipmentHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesShipmentHeader.Find();
        Commit();

        // [WHEN] Print Carta Porte for Sales Shipment
        ElectronicCartaPorteMX.SetRecord(SalesShipmentHeader);
        ElectronicCartaPorteMX.Run();

        // [THEN] Report is created with stamped data for the document
        VerfifyCartaPorteDataset(
          SalesShipmentHeader."No.",
          SalesShipmentHeader."Fiscal Invoice Number PAC", SalesShipmentHeader."Date/Time Stamped", SalesLine."No.");
    end;

    [Test]
    [HandlerFunctions('CartaPorteReqPageHandler')]
    [Scope('OnPrem')]
    procedure SalesShipmentCartaPorteForeignTradePrint()
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ElectronicCartaPorteMX: Report "Electronic Carta Porte MX";
    begin
        // [FEATURE] [Carta Porte] [Sales] [Report]
        // [SCENARIO 505081] Print Carta Porte report for  ales Shipment with foreign trade
        Initialize();

        // [GIVEN] Posted Sales Invoice with Foreign Trade = True
        Customer.get(CreateCustomer());
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItem(), LibraryRandom.RandIntInRange(100, 200), 0, 0, false, false);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesShipmentHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesShipmentHeader.FindFirst();
        UpdateSalesShipmentForCartaPorte(SalesShipmentHeader);
        UpdateSalesShipmentForCartaPorteForeignTrade(SalesShipmentHeader);

        // [WHEN] Request Stamp for the Sales Shipment
        RequestStamp(
          DATABASE::"Sales Shipment Header", SalesShipmentHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesShipmentHeader.Find();
        Commit();

        // [WHEN] Print Carta Porte for Sales Shipment
        ElectronicCartaPorteMX.SetRecord(SalesShipmentHeader);
        ElectronicCartaPorteMX.Run();

        // [THEN] Report is created with stamped data for the document
        VerfifyCartaPorteDataset(
          SalesShipmentHeader."No.",
          SalesShipmentHeader."Fiscal Invoice Number PAC", SalesShipmentHeader."Date/Time Stamped", SalesLine."No.");
    end;

    [Test]
    [HandlerFunctions('CartaPorteReqPageHandler')]
    [Scope('OnPrem')]
    procedure TransferShipmentCartaPortePrint()
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferLine: Record "Transfer Line";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ElectronicCartaPorteMX: Report "Electronic Carta Porte MX";
    begin
        // [FEATURE] [Carta Porte] [Transfer] [Report]
        // [SCENARIO 406136] Request Stamp for Transfer Shipment Carta Porte complemento
        Initialize();

        // [GIVEN] Posted Transfer Shipment
        CreateTransferItem(LocationFrom, LocationTo, Item);
        CreateTransferShipment(TransferShipmentHeader, TransferLine, LocationFrom, LocationTo, Item."No.");
        UpdateTransferShipmentForCartaPorte(TransferShipmentHeader);

        // [GIVEN] Request Stamp for the Transfer Shipment
        RequestStamp(
          DATABASE::"Transfer Shipment Header", TransferShipmentHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        TransferShipmentHeader.Find();
        Commit();

        // [WHEN] Print Carta Porte for Sales Shipment
        ElectronicCartaPorteMX.SetRecord(TransferShipmentHeader);
        ElectronicCartaPorteMX.Run();

        // [THEN] Report is created with stamped data for the document
        VerfifyCartaPorteDataset(
          TransferShipmentHeader."No.",
          TransferShipmentHeader."Fiscal Invoice Number PAC", TransferShipmentHeader."Date/Time Stamped", Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ElecSalesInvoiceReportPrint()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        XMLParameters: Text;
    begin
        // [SCENARIO 475593] Print totals in Elec. Sales Invoice Report
        Initialize();

        // [GIVEN] Posted sales invoice with Total Excl. VAT = 4500, Invoice Discount Amount = 500, VAT Amount = 720, Amount Inc. VAT = 5220.
        // [GIVEN] Line1: Amount = 3600, Invoice Discount Amount = 400, Amount Incl. VAT = 4176
        // [GIVEN] Line2: Amount = 900, Invoice Discount Amount = 100, Amount Incl. VAT = 1044
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(), CreatePaymentMethodForSAT());
        CreateSalesLineItem(SalesLine, SalesHeader, CreateItemWithPrice(LibraryRandom.RandIntInRange(1000, 2000)), 1, 0, 16, false, false);
        CreateSalesLineItem(SalesLine, SalesHeader, CreateItemWithPrice(LibraryRandom.RandIntInRange(1000, 2000)), 1, 0, 16, false, false);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(LibraryRandom.RandIntInRange(100, 200), SalesHeader);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.CalcSums(Amount, "Amount Including VAT", "Inv. Discount Amount");
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Print 'Elec. Sales Invoice MX' for the invoice
        SalesInvoiceHeader.SetRecFilter();
        LibraryReportDataset.RunReportAndLoad(REPORT::"Elec. Sales Invoice MX", SalesInvoiceHeader, XMLParameters);

        // [THEN] Subtotal ('SalesInvHeaderTotalAmountExclInvDiscount') = 5000, Invoice Discount ('SalesInvHeaderTotalInvDiscountAmount') = -500
        // [THEN] VAT Amount ('SalesInvHeaderTotalVATAmount') = 720 = (5000-500)*16% , Total ('SalesInvHeaderTotalAmountInclVAT') = 5220 = (5000-500+720)
        LibraryReportDataset.MoveToRow(1);
        LibraryReportDataset.AssertElementWithValueExists('SalesInvHeaderTotalAmountExclInvDiscount', SalesLine.Amount + SalesLine."Inv. Discount Amount");
        LibraryReportDataset.AssertElementWithValueExists('SalesInvHeaderTotalAmountInclVAT', SalesLine."Amount Including VAT");
        LibraryReportDataset.AssertElementWithValueExists('SalesInvHeaderTotalVATAmount', SalesLine."Amount Including VAT" - SalesLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('SalesInvHeaderTotalInvDiscountAmount', -SalesLine."Inv. Discount Amount");
    end;

    [Test]
    [HandlerFunctions('ChangeFiscalNumberPACInPostedSalesInvUpdatePage')]
    procedure ChangeFiscalInvoiceNumberPACInPostedSalesInvUpdateDocument()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoicePage: TestPage "Posted Sales Invoice";
        FiscalInvoiceNumberPAC: Text[50];
    begin
        // [FEATURE] [UX] [UT]
        // [SCENARIO 493274] Stan can change the "Fiscal Invoice Number PAC" in the Posted Sales Invoice Update Document page

        Initialize();
        // [GIVEN] Posted sales invoice with blank Fiscal Invoice Number PAC
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader.Insert();
        PostedSalesInvoicePage.OpenEdit();
        PostedSalesInvoicePage.Filter.SetFilter("No.", SalesInvoiceHeader."No.");
        FiscalInvoiceNumberPAC := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(FiscalInvoiceNumberPAC);
        // [GIVEN] Opened "Posted Sales Inv. - Update" page
        PostedSalesInvoicePage."Update Document".Invoke();
        // [WHEN] Stan sets the "Fiscal Invoice Number PAC" field to a value "X" and closes the page
        // Done in ChangeFiscalNumberPACInPostedSalesInvUpdatePage
        // [THEN] The value "X" is saved in the Fiscal Invoice Number PAC field of the posted sales invoice
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.TestField("Fiscal Invoice Number PAC", FiscalInvoiceNumberPAC);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SATCertOnPostedSalesInvoiceWhenLocationCertNotSet()
    var
        DummyGLSetup: Record "General Ledger Setup";
        Certificate: Record "Isolated Certificate";
        Location: Record Location;
        PostedSalesInvoiceCard: TestPage "Posted Sales Invoice";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Multiple SAT Certificates]
        // [SCENARIO 540218] "SAT Certificate Name" and "SAT Certificate Source" values on Posted Sales Invoice card when Multiple SAT Certificates are enabled and SAT Certificate is not set in Location.
        Initialize();

        // [GIVEN] Multiple SAT Certificates are enabled in General Ledger Setup.
        UpdateMultipleSATCertOnGLSetup(true);

        // [GIVEN] SAT Certificate with Name A is set in General Ledger Setup.
        CreateIsolatedCertificate(Certificate);
        UpdateSATCertificateOnGLSetup(Certificate.Code);

        // [GIVEN] Location L1 that does not have linked SAT Certificate.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        UpdateSATCertificateOnLocation(Location, '');

        // [GIVEN] Posted Sales Invoice with Location L1.
        PostedDocNo := CreateAndPostSalesDoc(Enum::"Sales Document Type"::Invoice, CreatePaymentMethodForSAT());
        UpdateLocationOnPostedSalesInvoice(PostedDocNo, Location.Code);

        // [WHEN] Posted Sales Invoice card is opened.
        PostedSalesInvoiceCard.OpenEdit();
        PostedSalesInvoiceCard.Filter.SetFilter("No.", PostedDocNo);

        // [THEN] "SAT Certificate Name" is A and "SAT Certificate Source" is 'General Ledger Setup'.
        Assert.AreEqual(Certificate.Name, PostedSalesInvoiceCard."SAT Certificate Name".Value, 'Incorrect SAT Certificate Name');
        Assert.AreEqual(DummyGLSetup.TableCaption, PostedSalesInvoiceCard."SAT Certificate Source".Value, 'Incorrect SAT Certificate Source');
        PostedSalesInvoiceCard.Close();
    end;

    [Test]
    procedure SATCertOnPostedTransferShipmentWhenLocationCertNotSet()
    var
        DummyGLSetup: Record "General Ledger Setup";
        Certificate: Record "Isolated Certificate";
        Location: Record Location;
        PostedTransferShipmentCard: TestPage "Posted Transfer Shipment";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Multiple SAT Certificates]
        // [SCENARIO 540218] "SAT Certificate Name" and "SAT Certificate Source" values on Posted Transfer Shipment card when Multiple SAT Certificates are enabled and SAT Certificate is not set in Location.
        Initialize();

        // [GIVEN] Multiple SAT Certificates are enabled in General Ledger Setup.
        UpdateMultipleSATCertOnGLSetup(true);

        // [GIVEN] SAT Certificate with Name A is set in General Ledger Setup.
        CreateIsolatedCertificate(Certificate);
        UpdateSATCertificateOnGLSetup(Certificate.Code);

        // [GIVEN] Location L1 that does not have linked SAT Certificate.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        UpdateSATCertificateOnLocation(Location, '');

        // [GIVEN] Transfer Order posted as Shipment with Transfer-from Code location that does not have linked SAT Certificate.
        PostedDocNo := CreateAndPostDoc(Database::"Transfer Shipment Header", CreatePaymentMethodForSAT());
        UpdateLocationFromOnTransferShipment(PostedDocNo, Location.Code);

        // [WHEN] Posted Transfer Shipment card is opened.
        PostedTransferShipmentCard.OpenEdit();
        PostedTransferShipmentCard.Filter.SetFilter("No.", PostedDocNo);

        // [THEN] "SAT Certificate Name" is A and "SAT Certificate Source" is 'General Ledger Setup'.
        Assert.AreEqual(Certificate.Name, PostedTransferShipmentCard."SAT Certificate Name".Value, 'Incorrect SAT Certificate Name');
        Assert.AreEqual(DummyGLSetup.TableCaption, PostedTransferShipmentCard."SAT Certificate Source".Value, 'Incorrect SAT Certificate Source');
        PostedTransferShipmentCard.Close();
    end;

    [Test]
    procedure SATCertOnPostedSalesInvoiceWhenLocationCertSet()
    var
        CertificateA: Record "Isolated Certificate";
        CertificateB: Record "Isolated Certificate";
        Location: Record Location;
        PostedSalesInvoiceCard: TestPage "Posted Sales Invoice";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Multiple SAT Certificates]
        // [SCENARIO 540218] "SAT Certificate Name" and "SAT Certificate Source" values on Posted Sales Invoice card when Multiple SAT Certificates are enabled and SAT Certificate is set in Location.
        Initialize();

        // [GIVEN] Multiple SAT Certificates are enabled in General Ledger Setup.
        UpdateMultipleSATCertOnGLSetup(true);

        // [GIVEN] SAT Certificate with Name A is set in General Ledger Setup.
        CreateIsolatedCertificate(CertificateA);
        UpdateSATCertificateOnGLSetup(CertificateA.Code);

        // [GIVEN] Location L1 with SAT Certificate with Name B.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateIsolatedCertificate(CertificateB);
        UpdateSATCertificateOnLocation(Location, CertificateB.Code);

        // [GIVEN] Posted Sales Invoice with Location L1.
        PostedDocNo := CreateAndPostSalesDoc(Enum::"Sales Document Type"::Invoice, CreatePaymentMethodForSAT());
        UpdateLocationOnPostedSalesInvoice(PostedDocNo, Location.Code);

        // [WHEN] Posted Sales Invoice card is opened.
        PostedSalesInvoiceCard.OpenEdit();
        PostedSalesInvoiceCard.Filter.SetFilter("No.", PostedDocNo);

        // [THEN] "SAT Certificate Name" is B and "SAT Certificate Source" is 'Location L1'.
        Assert.AreEqual(CertificateB.Name, PostedSalesInvoiceCard."SAT Certificate Name".Value, 'Incorrect SAT Certificate Name');
        Assert.AreEqual(StrSubstNo('%1 %2', Location.TableCaption, Location.Code), PostedSalesInvoiceCard."SAT Certificate Source".Value, 'Incorrect SAT Certificate Source');
        PostedSalesInvoiceCard.Close();
    end;

    [Test]
    procedure SATCertOnPostedTransferShipmentWhenLocationCertSet()
    var
        CertificateA: Record "Isolated Certificate";
        CertificateB: Record "Isolated Certificate";
        Location: Record Location;
        PostedTransferShipmentCard: TestPage "Posted Transfer Shipment";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Multiple SAT Certificates]
        // [SCENARIO 540218] "SAT Certificate Name" and "SAT Certificate Source" values on Posted Transfer Shipment card when Multiple SAT Certificates are enabled and SAT Certificate is set in Location.
        Initialize();

        // [GIVEN] Multiple SAT Certificates are enabled in General Ledger Setup.
        UpdateMultipleSATCertOnGLSetup(true);

        // [GIVEN] SAT Certificate with Name A is set in General Ledger Setup.
        CreateIsolatedCertificate(CertificateA);
        UpdateSATCertificateOnGLSetup(CertificateA.Code);

        // [GIVEN] Location L1 with SAT Certificate with Name B.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateIsolatedCertificate(CertificateB);
        UpdateSATCertificateOnLocation(Location, CertificateB.Code);

        // [GIVEN] Transfer Order posted as Shipment with Transfer-from Code L1.
        PostedDocNo := CreateAndPostDoc(Database::"Transfer Shipment Header", CreatePaymentMethodForSAT());
        UpdateLocationFromOnTransferShipment(PostedDocNo, Location.Code);

        // [WHEN] Posted Transfer Shipment card is opened.
        PostedTransferShipmentCard.OpenEdit();
        PostedTransferShipmentCard.Filter.SetFilter("No.", PostedDocNo);

        // [THEN] "SAT Certificate Name" is A and "SAT Certificate Source" is 'General Ledger Setup'.
        Assert.AreEqual(CertificateB.Name, PostedTransferShipmentCard."SAT Certificate Name".Value, 'Incorrect SAT Certificate Name');
        Assert.AreEqual(StrSubstNo('%1 %2', Location.TableCaption, Location.Code), PostedTransferShipmentCard."SAT Certificate Source".Value, 'Incorrect SAT Certificate Source');
        PostedTransferShipmentCard.Close();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure RequestStampSalesInvoiceWhenLocationCertificateNotSet()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Location: Record Location;
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
        SATCertificateCode: Code[20];
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Multiple SAT Certificates]
        // [SCENARIO 540218] Request Stamp on Posted Sales Invoice card when Multiple SAT Certificates are enabled and SAT Certificate is not set in Location.
        Initialize();
        UpdateSimulationModeOnGLSetup(false);

        // [GIVEN] Multiple SAT Certificates are enabled in General Ledger Setup.
        UpdateMultipleSATCertOnGLSetup(true);

        // [GIVEN] General Ledger Setup with SAT Certificate A. Isolated Certificate A does not exist.
        SATCertificateCode := LibraryUtility.GenerateGUID();
        UpdateSATCertificateOnGLSetup(SATCertificateCode);

        // [GIVEN] Location L1 that does not have linked SAT Certificate.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        UpdateSATCertificateOnLocation(Location, '');

        // [GIVEN] Posted Sales Invoice with Location L1.
        PostedDocNo := CreateAndPostSalesDoc(Enum::"Sales Document Type"::Invoice, CreatePaymentMethodForSAT());
        UpdateLocationOnPostedSalesInvoice(PostedDocNo, Location.Code);

        // [WHEN] Request Stamp for Posted Sales Invoice.
        LibraryVariableStorage.Enqueue(ActionOption::"Request Stamp");
        SalesInvoiceHeader.Get(PostedDocNo);
        RecRef.GetTable(SalesInvoiceHeader);
        asserterror EInvoiceMgt.RequestStampDocument(RecRef, false);

        // [THEN] Error message "The certificate A does not exist" is shown.
        Assert.ExpectedErrorCode('RecordNotFound');
        Assert.ExpectedError(StrSubstNo(CertificateNotExistErr, SATCertificateCode));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure RequestStampSalesInvoiceWhenLocationCertificateSet()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Location: Record Location;
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
        SATCertificateCodeA: Code[20];
        SATCertificateCodeB: Code[20];
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Multiple SAT Certificates]
        // [SCENARIO 540218] Request Stamp on Posted Sales Invoice card when Multiple SAT Certificates are enabled and SAT Certificate is set in Location.
        Initialize();
        UpdateSimulationModeOnGLSetup(false);

        // [GIVEN] Multiple SAT Certificates are enabled in General Ledger Setup.
        UpdateMultipleSATCertOnGLSetup(true);

        // [GIVEN] General Ledger Setup with SAT Certificate A. Isolated Certificate A does not exist.
        SATCertificateCodeA := LibraryUtility.GenerateGUID();
        UpdateSATCertificateOnGLSetup(SATCertificateCodeA);

        // [GIVEN] Location L1 with SAT Certificate B. Isolated Certificate B does not exist.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        SATCertificateCodeB := LibraryUtility.GenerateGUID();
        UpdateSATCertificateOnLocation(Location, SATCertificateCodeB);

        // [GIVEN] Posted Sales Invoice with Location L1.
        PostedDocNo := CreateAndPostSalesDoc(Enum::"Sales Document Type"::Invoice, CreatePaymentMethodForSAT());
        UpdateLocationOnPostedSalesInvoice(PostedDocNo, Location.Code);

        // [WHEN] Request Stamp for Posted Sales Invoice.
        LibraryVariableStorage.Enqueue(ActionOption::"Request Stamp");
        SalesInvoiceHeader.Get(PostedDocNo);
        RecRef.GetTable(SalesInvoiceHeader);
        asserterror EInvoiceMgt.RequestStampDocument(RecRef, false);

        // [THEN] Error message "The certificate B does not exist" is shown.
        Assert.ExpectedErrorCode('RecordNotFound');
        Assert.ExpectedError(StrSubstNo(CertificateNotExistErr, SATCertificateCodeB));
    end;

    local procedure Initialize()
    var
        PostCode: Record "Post Code";
    begin
        LibrarySetupStorage.Restore();
        SetupCFDI();
        LibraryVariableStorage.Clear();

        NameValueBuffer.SetRange(Name, Format(CODEUNIT::"MX CFDI"));
        NameValueBuffer.DeleteAll();
        if NameValueBuffer.Get(CODEUNIT::"MX CFDI") then
            NameValueBuffer.Delete();
        PostCode.ModifyAll("Time Zone", '');
        LibraryCFDI.SetupCompanyInformation();
        ClearLastError();

        if isInitialized then
            exit;

        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibraryCFDI.PopulateSATInformation();
        isInitialized := true;
        Commit();
    end;

    local procedure Cancel(TableNo: Integer; PostedDocumentNo: Code[20]; Response: Option)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesShipmentHeader: Record "Sales Shipment Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
    begin
        MockCancel(Response, TempBlob);
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(true);
        case TableNo of
            DATABASE::"Sales Invoice Header":
                begin
                    SalesInvoiceHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(SalesInvoiceHeader);
                    TempBlob.ToRecordRef(RecordRef, SalesInvoiceHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(SalesInvoiceHeader);
                    SalesInvoiceHeader."CFDI Cancellation Reason Code" := FindCancellationReasonCode(false);
                    SalesInvoiceHeader.Modify(true);
                    SalesInvoiceHeader.CancelEDocument();
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(SalesCrMemoHeader);
                    TempBlob.ToRecordRef(RecordRef, SalesCrMemoHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(SalesCrMemoHeader);
                    SalesCrMemoHeader."CFDI Cancellation Reason Code" := FindCancellationReasonCode(false);
                    SalesCrMemoHeader.Modify(true);
                    SalesCrMemoHeader.CancelEDocument();
                end;
            DATABASE::"Service Invoice Header":
                begin
                    ServiceInvoiceHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(ServiceInvoiceHeader);
                    TempBlob.ToRecordRef(RecordRef, ServiceInvoiceHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(ServiceInvoiceHeader);
                    ServiceInvoiceHeader."CFDI Cancellation Reason Code" := FindCancellationReasonCode(false);
                    ServiceInvoiceHeader.Modify(true);
                    ServiceInvoiceHeader.CancelEDocument();
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    ServiceCrMemoHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(ServiceCrMemoHeader);
                    TempBlob.ToRecordRef(RecordRef, ServiceCrMemoHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(ServiceCrMemoHeader);
                    ServiceCrMemoHeader."CFDI Cancellation Reason Code" := FindCancellationReasonCode(false);
                    ServiceCrMemoHeader.Modify(true);
                    ServiceCrMemoHeader.CancelEDocument();
                end;
            DATABASE::"Cust. Ledger Entry":
                begin
                    LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PostedDocumentNo);
                    RecordRef.GetTable(CustLedgerEntry);
                    TempBlob.ToRecordRef(RecordRef, CustLedgerEntry.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(CustLedgerEntry);
                    CustLedgerEntry."CFDI Cancellation Reason Code" := FindCancellationReasonCode(false);
                    CustLedgerEntry.Modify(true);
                    CustLedgerEntry.CancelEDocument();
                end;
            DATABASE::"Sales Shipment Header":
                begin
                    SalesShipmentHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(SalesShipmentHeader);
                    TempBlob.ToRecordRef(RecordRef, SalesShipmentHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(SalesShipmentHeader);
                    SalesShipmentHeader."CFDI Cancellation Reason Code" := FindCancellationReasonCode(false);
                    SalesShipmentHeader.Modify(true);
                    SalesShipmentHeader.CancelEDocument();
                end;
            DATABASE::"Transfer Shipment Header":
                begin
                    TransferShipmentHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(TransferShipmentHeader);
                    TempBlob.ToRecordRef(RecordRef, TransferShipmentHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(TransferShipmentHeader);
                    TransferShipmentHeader."CFDI Cancellation Reason Code" := FindCancellationReasonCode(false);
                    TransferShipmentHeader.Modify(true);
                    TransferShipmentHeader.CancelEDocument();
                end;
        end;
    end;

    local procedure CancelTearDown(TableNo: Integer; PostedDocumentNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesShipmentHeader: Record "Sales Shipment Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        case TableNo of
            DATABASE::"Sales Invoice Header":
                begin
                    SalesInvoiceHeader.Get(PostedDocumentNo);
                    SalesInvoiceHeader."Electronic Document Status" := SalesInvoiceHeader."Electronic Document Status"::" ";
                    SalesInvoiceHeader.Modify();
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoHeader.Get(PostedDocumentNo);
                    SalesCrMemoHeader."Electronic Document Status" := SalesCrMemoHeader."Electronic Document Status"::" ";
                    SalesCrMemoHeader.Modify();
                end;
            DATABASE::"Service Invoice Header":
                begin
                    ServiceInvoiceHeader.Get(PostedDocumentNo);
                    ServiceInvoiceHeader."Electronic Document Status" := ServiceInvoiceHeader."Electronic Document Status"::" ";
                    ServiceInvoiceHeader.Modify();
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    ServiceCrMemoHeader.Get(PostedDocumentNo);
                    ServiceCrMemoHeader."Electronic Document Status" := ServiceCrMemoHeader."Electronic Document Status"::" ";
                    ServiceCrMemoHeader.Modify();
                end;
            DATABASE::"Cust. Ledger Entry":
                begin
                    LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PostedDocumentNo);
                    CustLedgerEntry."Electronic Document Status" := CustLedgerEntry."Electronic Document Status"::" ";
                    CustLedgerEntry.Modify();
                end;
            DATABASE::"Sales Shipment Header":
                begin
                    SalesShipmentHeader.Get(PostedDocumentNo);
                    SalesShipmentHeader."Electronic Document Status" := SalesShipmentHeader."Electronic Document Status"::" ";
                    SalesShipmentHeader.Modify();
                end;
            DATABASE::"Transfer Shipment Header":
                begin
                    TransferShipmentHeader.Get(PostedDocumentNo);
                    TransferShipmentHeader."Electronic Document Status" := TransferShipmentHeader."Electronic Document Status"::" ";
                    TransferShipmentHeader.Modify();
                end;
        end;
    end;

    local procedure CreateDoc(TableNo: Integer; PaymentMethodCode: Code[10]) DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        ServiceHeader: Record "Service Header";
    begin
        case TableNo of
            DATABASE::"Sales Invoice Header":
                DocumentNo := CreateSalesDocWithPaymentMethodCode(SalesHeader."Document Type"::Invoice, PaymentMethodCode);
            DATABASE::"Sales Cr.Memo Header":
                DocumentNo := CreateSalesDocWithPaymentMethodCode(SalesHeader."Document Type"::"Credit Memo", PaymentMethodCode);
            DATABASE::"Service Invoice Header":
                DocumentNo := CreateServiceDocWithPaymentMethodCode(ServiceHeader."Document Type"::Invoice, PaymentMethodCode);
            DATABASE::"Service Cr.Memo Header":
                DocumentNo := CreateServiceDocWithPaymentMethodCode(ServiceHeader."Document Type"::"Credit Memo", PaymentMethodCode);
        end;
    end;

    local procedure CreateAndPostDoc(TableNo: Integer; PaymentMethodCode: Code[10]) PostedDocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        ServiceHeader: Record "Service Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferLine: Record "Transfer Line";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
    begin
        case TableNo of
            DATABASE::"Sales Invoice Header":
                PostedDocumentNo := CreateAndPostSalesDoc(SalesHeader."Document Type"::Invoice, PaymentMethodCode);
            DATABASE::"Sales Cr.Memo Header":
                PostedDocumentNo := CreateAndPostSalesDoc(SalesHeader."Document Type"::"Credit Memo", PaymentMethodCode);
            DATABASE::"Service Invoice Header":
                PostedDocumentNo := CreateAndPostServiceDoc(ServiceHeader."Document Type"::Invoice, PaymentMethodCode);
            DATABASE::"Service Cr.Memo Header":
                PostedDocumentNo := CreateAndPostServiceDoc(ServiceHeader."Document Type"::"Credit Memo", PaymentMethodCode);
            DATABASE::"Sales Shipment Header":
                begin
                    PostedDocumentNo := CreateAndPostSalesDoc(SalesHeader."Document Type"::Invoice, PaymentMethodCode);
                    CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(), CreatePaymentMethodForSAT());
                    CreateSalesLineItem(
                      SalesLine, SalesHeader, CreateItem(), LibraryRandom.RandIntInRange(100, 200), 0, 0, false, false);
                    LibrarySales.PostSalesDocument(SalesHeader, true, true);
                    SalesShipmentHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
                    SalesShipmentHeader.FindFirst();
                    UpdateSalesShipmentForCartaPorte(SalesShipmentHeader);
                    PostedDocumentNo := SalesShipmentHeader."No.";
                end;
            DATABASE::"Transfer Shipment Header":
                begin
                    CreateTransferItem(LocationFrom, LocationTo, Item);
                    CreateTransferShipment(TransferShipmentHeader, TransferLine, LocationFrom, LocationTo, Item."No.");
                    UpdateTransferShipmentForCartaPorte(TransferShipmentHeader);
                    PostedDocumentNo := TransferShipmentHeader."No.";
                end;
        end;
    end;

    local procedure CreateSalesDocWithPaymentMethodCode(DocumentType: Enum "Sales Document Type"; PaymentMethodCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        DocumentNo := CreateSalesDocForCustomer(DocumentType, CreateCustomer(), PaymentMethodCode);
        SalesHeader.Get(DocumentType, DocumentNo);
        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesDocForCustomer(DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; PaymentMethodCode: Code[10]): Code[20]
    begin
        exit(CreateSalesDocForCustomerWithVAT(DocumentType, CustomerNo, PaymentMethodCode, LibraryRandom.RandIntInRange(10, 20), false, false));
    end;

    local procedure CreateSalesDocForCustomerWithVAT(DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; PaymentMethodCode: Code[10]; VATPct: Decimal; IsVATExempt: Boolean; IsNoTaxable: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeaderForCustomer(SalesHeader, DocumentType, CustomerNo, PaymentMethodCode);
        CreateSalesLineItem(SalesLine, SalesHeader, CreateItem(), LibraryRandom.RandInt(10), 0, VATPct, IsVATExempt, IsNoTaxable);
        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesHeaderForCustomer(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; PaymentMethodCode: Code[10]): Code[20]
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Payment Terms Code", CreatePaymentTermsForSAT());
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Validate("Bill-to Address", SalesHeader."Sell-to Customer No.");
        SalesHeader.Validate("Bill-to Post Code", SalesHeader."Sell-to Customer No.");
        SalesHeader.Validate("CFDI Purpose", LibraryCFDI.CreateCFDIPurpose());
        SalesHeader.Validate("CFDI Relation", LibraryCFDI.CreateCFDIRelation());
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLineItem(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LineDiscountPct: Decimal; VATPct: Decimal; IsVATExempt: Boolean; IsNoTaxable: Boolean)
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate(
          "VAT Prod. Posting Group", CreateVATPostingSetup(SalesHeader."VAT Bus. Posting Group", VATPct, IsVATExempt, IsNoTaxable));
        SalesLine.Validate(Description, SalesLine."No.");
        SalesLine.Validate("Line Discount %", LineDiscountPct);
        SalesLine."SAT Customs Document Type" := '02';
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineItemWithVATSetup(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; VATProdPostingGroup: Code[20]; Quantity: Decimal; UnitPrice: Decimal; LineDiscountPct: Decimal)
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        SalesLine.Validate(Description, SalesLine."No.");
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Line Discount %", LineDiscountPct);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineFixedAsset(SalesHeader: Record "Sales Header"; VATPct: Decimal; IsVATExempt: Boolean; IsNoTaxable: Boolean): Code[20]
    var
        SalesLine: Record "Sales Line";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        CreateFixedAsset(FADepreciationBook);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Fixed Asset", FADepreciationBook."FA No.", 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Validate(
          "VAT Prod. Posting Group", CreateVATPostingSetup(SalesHeader."VAT Bus. Posting Group", VATPct, IsVATExempt, IsNoTaxable));
        SalesLine.Validate("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
        SalesLine.Validate(Description, SalesLine."No.");
        SalesLine.Modify(true);
        exit(FADepreciationBook."FA No.");
    end;

    local procedure CreateAndPostSalesDoc(DocumentType: Enum "Sales Document Type"; PaymentMethodCode: Code[10]) PostedDocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        DocumentNo := CreateSalesDocWithPaymentMethodCode(DocumentType, PaymentMethodCode);
        SalesHeader.Get(DocumentType, DocumentNo);
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostSalesInvoice(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        InvoiceNo: Code[20];
    begin
        SalesHeader.Get(
          SalesHeader."Document Type"::Invoice,
          CreateSalesDocForCustomerWithVAT(
            SalesHeader."Document Type"::Invoice, CustomerNo, CreatePaymentMethodForSAT(), 16, false, false));
        SalesHeader.Modify(true);
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        CustLedgerEntry.CalcFields(Amount);
    end;

    local procedure CreatePostSalesInvoiceWithCurrencyAmount(CustomerNo: Code[20]; VATProdPostingGroup: Code[20]; Quantity: Decimal; Amount: Decimal; ExchRate: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, CreatePaymentMethodForSAT());
        SalesHeader.Validate("Currency Factor", 1 / ExchRate);
        SalesHeader.Modify();
        CreateSalesLineItemWithVATSetup(SalesLine, SalesHeader, CreateItem(), VATProdPostingGroup, Quantity, Amount, 0);
        GetPostedSalesInvoice(SalesInvoiceHeader, LibrarySales.PostSalesDocument(SalesHeader, true, true));
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure CreateRetentionSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; LineNo: Integer; Quantity: Decimal; BaseAmount: Decimal; RetentionVATPct: Decimal)
    begin
        CreateSalesLineItem(SalesLine, SalesHeader, CreateItem(), Quantity, 0, 0, false, false);
        SalesLine.Validate("Retention Attached to Line No.", LineNo);
        SalesLine.Validate("Retention VAT %", RetentionVATPct);
        SalesLine.Validate("Unit Price", BaseAmount * RetentionVATPct / 100);
        SalesLine.Modify(true);
    end;

    local procedure CreatePostApplySalesCrMemo(CustomerNo: Code[20]; InvoiceNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(
          SalesHeader."Document Type"::"Credit Memo",
          CreateSalesDocForCustomer(SalesHeader."Document Type"::"Credit Memo", CustomerNo, CreatePaymentMethodForSAT()));
        SalesHeader.Validate("Applies-to Doc. Type", SalesHeader."Applies-to Doc. Type"::Invoice);
        SalesHeader.Validate("Applies-to Doc. No.", InvoiceNo);
        SalesHeader.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateServiceDocWithPaymentMethodCode(DocumentType: Enum "Service Document Type"; PaymentMethodCode: Code[10]): Code[20]
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(
          DocumentType, CreateServiceDocForCustomer(DocumentType, CreateCustomer(), PaymentMethodCode));
        exit(ServiceHeader."No.");
    end;

    local procedure CreateServiceDocForCustomer(DocumentType: Enum "Service Document Type"; CustomerNo: Code[20]; PaymentMethodCode: Code[10]): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        ServiceHeader.Validate("Payment Terms Code", CreatePaymentTermsForSAT());
        ServiceHeader.Validate("Bill-to Address", ServiceHeader."Customer No.");
        ServiceHeader.Validate("Bill-to Post Code", ServiceHeader."Customer No.");
        ServiceHeader.Validate("Payment Method Code", PaymentMethodCode);
        ServiceHeader.Validate("CFDI Purpose", LibraryCFDI.CreateCFDIPurpose());
        ServiceHeader.Validate("CFDI Relation", LibraryCFDI.CreateCFDIRelation());
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItem());
        ServiceLine.Validate(Description, ServiceLine."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Modify(true);
        exit(ServiceHeader."No.");
    end;

    local procedure CreateAndPostServiceDoc(DocumentType: Enum "Service Document Type"; PaymentMethodCode: Code[10]) PostedDocumentNo: Code[20]
    var
        ServiceHeader: Record "Service Header";
        NoSeries: Codeunit "No. Series";
    begin
        ServiceHeader.Get(DocumentType, CreateServiceDocWithPaymentMethodCode(DocumentType, PaymentMethodCode));
        PostedDocumentNo := NoSeries.PeekNextNo(ServiceHeader."Posting No. Series");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure CreatePostApplyServiceCrMemo(CustomerNo: Code[20]; InvoiceNo: Code[20]) PostedDocumentNo: Code[20]
    var
        ServiceHeader: Record "Service Header";
        NoSeries: Codeunit "No. Series";
    begin
        ServiceHeader.Get(
          ServiceHeader."Document Type"::"Credit Memo",
          CreateServiceDocForCustomer(ServiceHeader."Document Type"::"Credit Memo", CustomerNo, CreatePaymentMethodForSAT()));
        ServiceHeader.Validate("Applies-to Doc. Type", ServiceHeader."Applies-to Doc. Type"::Invoice);
        ServiceHeader.Validate("Applies-to Doc. No.", InvoiceNo);
        ServiceHeader.Modify(true);
        PostedDocumentNo := NoSeries.PeekNextNo(ServiceHeader."Posting No. Series");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        Customer.Validate("RFC No.", GenerateString(12));  // Valid RFC No.
        Customer.Validate("Country/Region Code", GetCountryRegion());
        Customer."SAT Tax Regime Classification" :=
          LibraryUtility.GenerateRandomCode(Customer.FieldNo("SAT Tax Regime Classification"), DATABASE::Customer);
        Customer.Validate("CFDI Export Code", LibraryCFDI.CreateCFDIExportCode());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure GetCountryRegion(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.FindFirst();
        CountryRegion."SAT Country Code" := CountryRegion.Code; // Foreign
        CountryRegion.Modify();
        exit(CountryRegion.Code);
    end;

    local procedure CreateItem(): Code[20]
    begin
        exit(
          CreateItemWithPrice(LibraryRandom.RandDec(1000, 2) * 2));
    end;

    local procedure CreateItemWithPrice(UnitPrice: Decimal): Code[20]
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        SATClassification: Record "SAT Classification";
        SATUnitOfMeasure: Record "SAT Unit of Measure";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", UnitPrice);
        Item.Validate("Gross Weight", LibraryRandom.RandIntInRange(5, 10));
        Item."SAT Item Classification" := LibraryUtility.GenerateRandomCode(Item.FieldNo("SAT Item Classification"), DATABASE::Item);
        Item."SAT Material Type" := '01';
        Item.Modify(true);
        SATClassification."SAT Classification" := Item."SAT Item Classification";
        SATClassification."Hazardous Material Mandatory" := true;
        SATClassification.Insert();
        UnitOfMeasure.Get(Item."Base Unit of Measure");
        SATUnitOfMeasure.Next(LibraryRandom.RandInt(SATUnitOfMeasure.Count));
        UnitOfMeasure."SAT UofM Classification" := SATUnitOfMeasure."SAT UofM Code";
        UnitOfMeasure."SAT Customs Unit" := SATUnitOfMeasure."SAT UofM Code";
        UnitOfMeasure.Modify();
        exit(Item."No.");
    end;

    local procedure CreateTransferItem(var LocationFrom: Record Location; var LocationTo: Record Location; var Item: Record Item)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        Item.Get(CreateItemWithPrice(LibraryRandom.RandIntInRange(10, 20)));
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(ItemLedgerEntry, ItemLedgerEntry.FieldNo("Entry No."));
        ItemLedgerEntry."Item No." := Item."No.";
        ItemLedgerEntry."Posting Date" := WorkDate();
        ItemLedgerEntry."Location Code" := LocationFrom.Code;
        ItemLedgerEntry.Quantity := LibraryRandom.RandIntInRange(100, 200);
        ItemLedgerEntry."Remaining Quantity" := ItemLedgerEntry.Quantity;
        ItemLedgerEntry.Positive := true;
        ItemLedgerEntry.Open := true;
        ItemLedgerEntry.Insert();
        ItemLedgerEntry.Validate("Cost Amount (Actual)", LibraryRandom.RandIntInRange(1000, 2000));
        ItemLedgerEntry.Modify(true);
    end;

    local procedure CreateTransferShipment(var TransferShipmentHeader: Record "Transfer Shipment Header"; var TransferLine: Record "Transfer Line"; LocationFrom: Record Location; LocationTo: Record Location; ItemNo: Code[20])
    var
        TransferHeader: Record "Transfer Header";
        LocationInTransit: Record Location;
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        LibraryWarehouse.CreateLocation(LocationInTransit);
        LocationInTransit.Validate("Use As In-Transit", true);
        LocationInTransit.Modify(true);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        TransferHeader."Transfer-to Address" := LibraryUtility.GenerateGUID();
        TransferHeader."Trsf.-to Country/Region Code" := 'TEST';
        TransferHeader.Validate("CFDI Export Code", LibraryCFDI.CreateCFDIExportCode());
        TransferHeader.Modify(true);
        LibraryInventory.CreateTransferLine(
          TransferHeader, TransferLine, ItemNo, LibraryRandom.RandIntInRange(1, 10));
        TransferLine."SAT Customs Document Type" := '02';
        TransferLine.Modify();
        LibraryInventory.CreateInventoryPostingSetup(
          InventoryPostingSetup, LocationInTransit.Code, TransferLine."Inventory Posting Group");
        InventoryPostingSetup.Validate("Inventory Account", LibraryERM.CreateGLAccountNo());
        InventoryPostingSetup.Modify(true);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);
        TransferShipmentHeader.SetRange("Transfer-from Code", LocationFrom.Code);
        TransferShipmentHeader.FindFirst();
    end;

    local procedure CreateFixedAsset(var FADepreciationBook: Record "FA Depreciation Book")
    var
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        DepreciationBook: Record "Depreciation Book";
        SATClassification: Record "SAT Classification";
    begin
        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Disposal", true);
        DepreciationBook.Validate("Allow Correction of Disposal", true);
        DepreciationBook.Modify(true);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup.Code);
        FADepreciationBook.Validate("Acquisition Date", WorkDate());
        FADepreciationBook.Modify(true);
        FixedAsset."SAT Classification Code" := LibraryUtility.GenerateRandomCode(FixedAsset.FieldNo("SAT Classification Code"), DATABASE::"Fixed Asset");
        FixedAsset.Modify(true);
        SATClassification."SAT Classification" := FixedAsset."SAT Classification Code";
        SATClassification.Insert();
    end;

    local procedure CreatePostPayment(CustomerNo: Code[20]; ApplToDocNo: Code[20]; Amount: Decimal; CurrencyCode: Code[10]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Document Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", ApplToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreatePostPaymentFCY(CustomerNo: Code[20]; Amount: Decimal; AmountLCY: Decimal; CurrencyCode: Code[10]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        if AmountLCY <> 0 then
            GenJournalLine.Validate("Amount (LCY)", AmountLCY);
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreatePaymentMethodForSAT(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
        SATPaymentMethod: Record "SAT Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod."SAT Method of Payment" := PaymentMethod.Code;
        PaymentMethod.Modify();
        SATPaymentMethod.Code := PaymentMethod."SAT Method of Payment";
        SATPaymentMethod.Insert();
        exit(PaymentMethod.Code);
    end;

    local procedure CreatePaymentTermsForSAT(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
        SATPaymentTerm: Record "SAT Payment Term";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PaymentTerms."SAT Payment Term" := PaymentTerms.Code;
        PaymentTerms.Modify();
        SATPaymentTerm.Code := PaymentTerms."SAT Payment Term";
        SATPaymentTerm.Insert();
        exit(PaymentTerms.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateCFDIRelationDocument(var CFDIRelationDocument: Record "CFDI Relation Document"; TableID: Integer; DocumentType: Integer; DocumentNo: Code[20]; CustomerNo: Code[20]; RelatedDocumentNo: Code[20]; FiscalInvoiceNumberPAC: Text[50])
    begin
        CFDIRelationDocument.Init();
        CFDIRelationDocument."Document Table ID" := TableID;
        CFDIRelationDocument."Document Type" := DocumentType;
        CFDIRelationDocument."Document No." := DocumentNo;
        CFDIRelationDocument."Customer No." := CustomerNo;
        CFDIRelationDocument."Related Doc. No." := RelatedDocumentNo;
        CFDIRelationDocument."Fiscal Invoice Number PAC" := FiscalInvoiceNumberPAC;
        CFDIRelationDocument.Insert();
    end;

    local procedure CreateIsolatedCertificate(var IsolatedCertificate: Record "Isolated Certificate")
    begin
        IsolatedCertificate.Code := LibraryUtility.GenerateGUID();
        IsolatedCertificate.Name := LibraryUtility.GenerateGUID();
        IsolatedCertificate.ThumbPrint := IsolatedCertificate.Code;
        IsolatedCertificate.Insert();
    end;

    local procedure CreatePostCode(var PostCode: Record "Post Code"; TimeZoneID: Text[180])
    begin
        LibraryERM.CreatePostCode(PostCode);
        PostCode."Time Zone" := TimeZoneID;
        PostCode.Modify();
    end;

    local procedure CreateSATAddress(): Integer
    var
        SATAddress: Record "SAT Address";
        SATState: Record "SAT State";
        SATLocality: Record "SAT Locality";
        SATMunicipality: Record "SAT Municipality";
        SATSuburb: Record "SAT Suburb";
    begin
        SATAddress.Init();
        SATState.Next(LibraryRandom.RandInt(SATState.Count()));
        SATMunicipality.Next(LibraryRandom.RandInt(SATMunicipality.Count()));
        SATLocality.Next(LibraryRandom.RandInt(SATLocality.Count()));
        SATSuburb.Next(LibraryRandom.RandInt(SATSuburb.Count()));
        SATAddress."SAT State Code" := SATState.Code;
        SATAddress."SAT Municipality Code" := SATMunicipality.Code;
        SATAddress."SAT Locality Code" := SATLocality.Code;
        SATAddress."SAT Suburb ID" := SATSuburb.ID;
        SATAddress."Country/Region Code" := 'TEST';
        SATAddress.Insert();
        exit(SATAddress.Id);
    end;

    local procedure CreateVATPostingSetup(VATBusPostingGroup: Code[20]; VATPct: Decimal; IsVATExempt: Boolean; IsNoTaxable: Boolean): Code[20]
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("VAT %", VATPct);
        VATPostingSetup.Validate("CFDI VAT Exemption", IsVATExempt);
        if IsVATExempt then
            VATPostingSetup."CFDI Subject to Tax" := '02';
        VATPostingSetup.Validate("CFDI Non-Taxable", IsNoTaxable);
        VATPostingSetup."VAT Identifier" := LibraryUtility.GenerateGUID();
        VATPostingSetup.Modify(true);
        exit(VATProductPostingGroup.Code);
    end;

    local procedure CreateTransportOperator(TableID: Integer; DocumentNo: Code[20])
    var
        CFDITransportOperator: Record "CFDI Transport Operator";
        Employee: Record Employee;
    begin
        Employee.Init();
        Employee."No." := LibraryUtility.GenerateGUID();
        Employee.Validate("First Name", LibraryUtility.GenerateGUID());
        Employee.Validate("RFC No.", 'HEGJ820506M10');
        Employee.Validate("License No.", LibraryUtility.GenerateGUID());
        Employee.Insert();
        CFDITransportOperator.Init();
        CFDITransportOperator."Document Table ID" := TableID;
        CFDITransportOperator."Document No." := DocumentNo;
        CFDITransportOperator."Operator Code" := Employee."No.";
        CFDITransportOperator.Insert();
    end;

    local procedure CreateTrailer(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        SATTrailerType: Record "SAT Trailer Type";
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        SATTrailerType.Next(LibraryRandom.RandInt(SATTrailerType.Count));
        FixedAsset."SAT Trailer Type" := SATTrailerType.Code;
        FixedAsset."Vehicle Licence Plate" := LibraryUtility.GenerateGUID();
        FixedAsset.Modify();
        exit(FixedAsset."No.");
    end;

    local procedure CreateVehicle(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        SATFederalMotorTransport: Record "SAT Federal Motor Transport";
        SATPermissionType: Record "SAT Permission Type";
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        SATFederalMotorTransport.Next(LibraryRandom.RandInt(SATFederalMotorTransport.Count));
        FixedAsset."SAT Federal Autotransport" := SATFederalMotorTransport.Code;
        FixedAsset."Vehicle Licence Plate" := LibraryUtility.GenerateGUID();
        FixedAsset."Vehicle Year" := LibraryRandom.RandIntInRange(1990, 2010);
        FixedAsset."SCT Permission No." := LibraryUtility.GenerateGUID();
        SATPermissionType.Next(LibraryRandom.RandInt(SATPermissionType.Count));
        FixedAsset."SCT Permission Type" := SATPermissionType.Code;
        FixedAsset."Vehicle Gross Weight" := LibraryRandom.RandIntInRange(10, 20);
        FixedAsset.Modify();
        exit(FixedAsset."No.");
    end;

    local procedure InsertNameValueBufferRounding(NewValue: Text[250])
    begin
        NameValueBuffer.ID := CODEUNIT::"MX CFDI";
        NameValueBuffer.Name := 'Rounding';
        NameValueBuffer.Value := NewValue;
        NameValueBuffer.Insert();
    end;

    local procedure GenerateString(Length: Integer) String: Text[30]
    var
        I: Integer;
        GUIDLength: Integer;
    begin
        String := LibraryUtility.GenerateGUID();
        GUIDLength := StrLen(String);
        for I := GUIDLength to Length do begin
            String := InsStr(String, Format(LibraryRandom.RandInt(9)), I);
            I += 1;
        end;
    end;

    local procedure PostSalesDocBlankPaymentMethodCode(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // Setup
        SetupPACEnvironment(GLSetup."PAC Environment"::Test);

        DocumentNo := CreateSalesDocWithPaymentMethodCode(DocumentType, '');
        SalesHeader.Get(DocumentType, DocumentNo);

        // Verify
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Assert.ExpectedError(MissingSalesPaymentMethodCodeExceptionErr);
    end;

    local procedure PostServiceDocBlankPaymentMethodCode(DocumentType: Enum "Service Document Type")
    var
        ServiceHeader: Record "Service Header";
        DocumentNo: Code[20];
    begin
        // Setup
        SetupPACEnvironment(GLSetup."PAC Environment"::Test);

        DocumentNo := CreateServiceDocWithPaymentMethodCode(DocumentType, '');
        ServiceHeader.Get(DocumentType, DocumentNo);

        // Verify
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        Assert.ExpectedError(MissingServicePaymentMethodCodeExceptionErr);
    end;

    local procedure PostServiceDocBlankUnitOfMeasureCode(DocumentType: Enum "Service Document Type")
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DocumentNo: Code[20];
    begin
        // Setup
        SetupPACEnvironment(GLSetup."PAC Environment"::Test);

        DocumentNo := CreateServiceDocWithPaymentMethodCode(DocumentType, CreatePaymentMethodForSAT());
        ServiceHeader.Get(DocumentType, DocumentNo);

        ServiceLine.SetRange("Document Type", DocumentType);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();

        // Verify
        asserterror ServiceLine.Validate("Unit of Measure Code", '');
        Assert.ExpectedError(MissingServiceUnitOfMeasureExcErr);
    end;

    local procedure PostServiceDocument(var ServiceHeader: Record "Service Header") PostedDocumentNo: Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        PostedDocumentNo := NoSeries.PeekNextNo(ServiceHeader."Posting No. Series");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure PostAndPrint(TableNo: Integer; DocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        ServiceHeader: Record "Service Header";
        SalesPostPrint: Codeunit "Sales-Post + Print";
        ServicePostPrint: Codeunit "Service-Post+Print";
    begin
        case TableNo of
            DATABASE::"Sales Invoice Header":
                begin
                    SalesHeader.Get(SalesHeader."Document Type"::Invoice, DocumentNo);
                    SalesPostPrint.Run(SalesHeader);
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", DocumentNo);
                    SalesPostPrint.Run(SalesHeader);
                end;
            DATABASE::"Service Invoice Header":
                begin
                    ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, DocumentNo);
                    ServicePostPrint.PostDocument(ServiceHeader);
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    ServiceHeader.Get(ServiceHeader."Document Type"::"Credit Memo", DocumentNo);
                    ServicePostPrint.PostDocument(ServiceHeader);
                end;
        end;
    end;

    local procedure RequestStamp(TableNo: Integer; PostedDocumentNo: Code[20]; Response: Option; "Action": Option)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
    begin
        MockRequestStamp(Response, TempBlob, NamespaceCFD4Txt, SchemaLocationCFD4Txt);
        if not (TableNo in [DATABASE::"Sales Shipment Header", DATABASE::"Transfer Shipment Header"]) then
            LibraryVariableStorage.Enqueue(Action);
        case TableNo of
            DATABASE::"Sales Invoice Header":
                begin
                    SalesInvoiceHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(SalesInvoiceHeader);
                    TempBlob.ToRecordRef(RecordRef, SalesInvoiceHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(SalesInvoiceHeader);
                    SalesInvoiceHeader.Modify(true);
                    SalesInvoiceHeader.RequestStampEDocument();
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(SalesCrMemoHeader);
                    TempBlob.ToRecordRef(RecordRef, SalesCrMemoHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(SalesCrMemoHeader);
                    SalesCrMemoHeader.Modify(true);
                    SalesCrMemoHeader.RequestStampEDocument();
                end;
            DATABASE::"Service Invoice Header":
                begin
                    ServiceInvoiceHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(ServiceInvoiceHeader);
                    TempBlob.ToRecordRef(RecordRef, ServiceInvoiceHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(ServiceInvoiceHeader);
                    ServiceInvoiceHeader.Modify(true);
                    ServiceInvoiceHeader.RequestStampEDocument();
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    ServiceCrMemoHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(ServiceCrMemoHeader);
                    TempBlob.ToRecordRef(RecordRef, ServiceCrMemoHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(ServiceCrMemoHeader);
                    ServiceCrMemoHeader.Modify(true);
                    ServiceCrMemoHeader.RequestStampEDocument();
                end;
            DATABASE::"Sales Shipment Header":
                begin
                    SalesShipmentHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(SalesShipmentHeader);
                    TempBlob.ToRecordRef(RecordRef, SalesShipmentHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(SalesShipmentHeader);
                    SalesShipmentHeader.Modify(true);
                    SalesShipmentHeader.RequestStampEDocument();
                end;
            DATABASE::"Transfer Shipment Header":
                begin
                    TransferShipmentHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(TransferShipmentHeader);
                    TempBlob.ToRecordRef(RecordRef, TransferShipmentHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(TransferShipmentHeader);
                    TransferShipmentHeader.Modify(true);
                    TransferShipmentHeader.RequestStampEDocument();
                end;
            DATABASE::"Cust. Ledger Entry":
                begin
                    LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PostedDocumentNo);
                    RecordRef.GetTable(CustLedgerEntry);
                    TempBlob.ToRecordRef(RecordRef, CustLedgerEntry.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(CustLedgerEntry);
                    CustLedgerEntry.Modify();
                    CustLedgerEntry.RequestStampEDocument();
                end;
        end;
    end;

    local procedure SendSalesStampRequestBlankTaxSchemeError(DocumentType: Enum "Sales Document Type"; TableNo: Integer)
    var
        CompanyInfo: Record "Company Information";
        ErrorMessages: TestPage "Error Messages";
        PostedDocumentNo: Code[20];
    begin
        // Setup
        SetupPACEnvironment(GLSetup."PAC Environment"::Test);

        CompanyInfo.Get();
        CompanyInfo.Validate("Tax Scheme", '');
        CompanyInfo.Modify(true);

        // Exercise
        PostedDocumentNo := CreateAndPostSalesDoc(DocumentType, CreatePaymentMethodForSAT());

        // Verify
        ErrorMessages.Trap();
        asserterror RequestStamp(TableNo, PostedDocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInfo.FieldCaption("Tax Scheme"), CompanyInfo.RecordId));
    end;

    local procedure SendServiceStampRequestBlankTaxSchemeError(DocumentType: Enum "Service Document Type"; TableNo: Integer)
    var
        CompanyInfo: Record "Company Information";
        ErrorMessages: TestPage "Error Messages";
        PostedDocumentNo: Code[20];
    begin
        // Setup
        SetupPACEnvironment(GLSetup."PAC Environment"::Test);

        CompanyInfo.Get();
        CompanyInfo.Validate("Tax Scheme", '');
        CompanyInfo.Modify(true);

        // Exercise
        PostedDocumentNo := CreateAndPostServiceDoc(DocumentType, CreatePaymentMethodForSAT());

        // Verify
        ErrorMessages.Trap();
        asserterror RequestStamp(TableNo, PostedDocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInfo.FieldCaption("Tax Scheme"), CompanyInfo.RecordId));
    end;

    local procedure SendSalesStampRequestBlankCountryCodeError(DocumentType: Enum "Sales Document Type"; TableNo: Integer)
    var
        CompanyInfo: Record "Company Information";
        ErrorMessages: TestPage "Error Messages";
        PostedDocumentNo: Code[20];
    begin
        // Setup
        SetupPACEnvironment(GLSetup."PAC Environment"::Test);

        CompanyInfo.Get();
        CompanyInfo.Validate("Country/Region Code", '');
        CompanyInfo.Modify();

        // Exercise
        PostedDocumentNo := CreateAndPostSalesDoc(DocumentType, CreatePaymentMethodForSAT());

        // Verify
        ErrorMessages.Trap();
        asserterror RequestStamp(TableNo, PostedDocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInfo.FieldCaption(City), CompanyInfo.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInfo.FieldCaption("Country/Region Code"), CompanyInfo.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInfo.FieldCaption("Post Code"), CompanyInfo.RecordId));
    end;

    local procedure SendServiceStampRequestBlankCountryCodeError(DocumentType: Enum "Service Document Type"; TableNo: Integer)
    var
        CompanyInfo: Record "Company Information";
        ErrorMessages: TestPage "Error Messages";
        PostedDocumentNo: Code[20];
    begin
        // Setup
        SetupPACEnvironment(GLSetup."PAC Environment"::Test);

        CompanyInfo.Get();
        CompanyInfo.Validate("Country/Region Code", '');
        CompanyInfo.Modify(true);

        // Exercise
        PostedDocumentNo := CreateAndPostServiceDoc(DocumentType, CreatePaymentMethodForSAT());

        // Verify
        ErrorMessages.Trap();
        asserterror RequestStamp(TableNo, PostedDocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInfo.FieldCaption(City), CompanyInfo.RecordId));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInfo.FieldCaption("Country/Region Code"), CompanyInfo.RecordId));
    end;

    local procedure SetupPACEnvironment(PACEnvironment: Option)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("PAC Environment", PACEnvironment);
        GLSetup."CFDI Enabled" := true;
        GLSetup.Modify(true)
    end;

    local procedure SetupCFDI()
    var
        PACWebServiceCode: Code[10];
    begin
        PACWebServiceCode := LibraryCFDI.CreatePACService();
        LibraryCFDI.InitGLSetup(PACWebServiceCode);
        LibraryCFDI.SetupReportSelection();
    end;

    local procedure Verify(TableNo: Integer; PostedDocumentNo: Code[20]; ExpectedStatus: Option; NoOfEmailsSent: Integer)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        DummyTempBlob: Codeunit "Temp Blob";
        ExpectedNoOfEmailsSent: Integer;
        ExpectedDateTimeCanceledEmpty: Boolean;
        ExpectedDateTimeSentEmpty: Boolean;
        ExpectedDateTimeStamped: Text[50];
        ExpectedPACCode: Code[10];
        ExpectedInvoiceNoPAC: Text[50];
        ExpectedErrorCode: Code[10];
        ExpectedErrorDesc: Text[250];
        ExpectedDigitalStamp: Text[250];
        ExpectedCancellationIDEmpty: Boolean;
    begin
        GLSetup.Get();
        ExpectedPACCode := GLSetup."PAC Code";
        ExpectedDateTimeStamped := DateTimeStampedTxt;
        ExpectedInvoiceNoPAC := FiscalInvoiceNumberPACTxt;
        ExpectedErrorCode := '';
        ExpectedErrorDesc := '';
        ExpectedNoOfEmailsSent := 0;
        ExpectedDateTimeSentEmpty := true;
        ExpectedDateTimeCanceledEmpty := true;
        ExpectedDigitalStamp := DigitalStampTxt;
        ExpectedCancellationIDEmpty := true;

        case ExpectedStatus of
            StatusOption::"Stamp Request Error":
                begin
                    ExpectedDateTimeStamped := '';
                    ExpectedInvoiceNoPAC := '';
                    ExpectedErrorCode := ErrorCodeTxt;
                    ExpectedErrorDesc := ErrorDescriptionTxt;
                    ExpectedDigitalStamp := '';
                end;
            StatusOption::Sent:
                begin
                    ExpectedNoOfEmailsSent := NoOfEmailsSent + 1;
                    ExpectedDateTimeSentEmpty := false;
                end;
            StatusOption::Canceled:
                begin
                    ExpectedDateTimeCanceledEmpty := false;
                    ExpectedCancellationIDEmpty := false;
                end;
            StatusOption::"Cancel Error":
                begin
                    ExpectedErrorCode := ErrorCodeTxt;
                    ExpectedErrorDesc := ErrorDescriptionTxt;
                end;
            StatusOption::"Cancel In Progress":
                begin
                    ExpectedDateTimeCanceledEmpty := true;
                    ExpectedCancellationIDEmpty := false;
                end;
        end;

        case TableNo of
            DATABASE::"Sales Invoice Header":
                begin
                    SalesInvoiceHeader.Get(PostedDocumentNo);
                    SalesInvoiceHeader.TestField("Electronic Document Status", ExpectedStatus);
                    SalesInvoiceHeader.TestField("No. of E-Documents Sent", ExpectedNoOfEmailsSent);
                    Assert.AreEqual(ExpectedDateTimeSentEmpty, SalesInvoiceHeader."Date/Time Sent" = '',
                      StrSubstNo(ValueErr, SalesInvoiceHeader.FieldName("Date/Time Sent")));
                    Assert.AreEqual(ExpectedDateTimeCanceledEmpty, SalesInvoiceHeader."Date/Time Canceled" = '',
                      StrSubstNo(ValueErr, SalesInvoiceHeader.FieldName("Date/Time Canceled")));
                    Assert.AreEqual(ExpectedCancellationIDEmpty, SalesInvoiceHeader."CFDI Cancellation ID" = '',
                      StrSubstNo(ValueErr, SalesInvoiceHeader.FieldName("CFDI Cancellation ID")));
                    SalesInvoiceHeader.TestField("Date/Time Stamped", ExpectedDateTimeStamped);
                    SalesInvoiceHeader.TestField("PAC Web Service Name", ExpectedPACCode);
                    SalesInvoiceHeader.TestField("Fiscal Invoice Number PAC", ExpectedInvoiceNoPAC);
                    SalesInvoiceHeader.TestField("Error Code", ExpectedErrorCode);
                    SalesInvoiceHeader.TestField("Error Description", ExpectedErrorDesc);
                    SalesInvoiceHeader.CalcFields("Digital Stamp PAC");
                    DummyTempBlob.FromRecord(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Digital Stamp PAC"));
                    VerifyDigitalStamp(DummyTempBlob, ExpectedDigitalStamp);
                    Clear(DummyTempBlob);
                    SalesInvoiceHeader.CalcFields("Original Document XML");
                    DummyTempBlob.FromRecord(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
                    VerifyCancelXML(
                      DummyTempBlob, SalesInvoiceHeader."Electronic Document Status" = SalesInvoiceHeader."Electronic Document Status"::Canceled,
                      SalesInvoiceHeader."CFDI Cancellation Reason Code", '');
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoHeader.Get(PostedDocumentNo);
                    SalesCrMemoHeader.TestField("Electronic Document Status", ExpectedStatus);
                    SalesCrMemoHeader.TestField("No. of E-Documents Sent", ExpectedNoOfEmailsSent);
                    Assert.AreEqual(ExpectedDateTimeSentEmpty, SalesCrMemoHeader."Date/Time Sent" = '',
                      StrSubstNo(ValueErr, SalesCrMemoHeader.FieldName("Date/Time Sent")));
                    Assert.AreEqual(ExpectedDateTimeCanceledEmpty, SalesCrMemoHeader."Date/Time Canceled" = '',
                      StrSubstNo(ValueErr, SalesCrMemoHeader.FieldName("Date/Time Canceled")));
                    SalesCrMemoHeader.TestField("Date/Time Stamped", ExpectedDateTimeStamped);
                    SalesCrMemoHeader.TestField("PAC Web Service Name", ExpectedPACCode);
                    SalesCrMemoHeader.TestField("Fiscal Invoice Number PAC", ExpectedInvoiceNoPAC);
                    SalesCrMemoHeader.TestField("Error Code", ExpectedErrorCode);
                    SalesCrMemoHeader.TestField("Error Description", ExpectedErrorDesc);
                    SalesCrMemoHeader.CalcFields("Digital Stamp PAC");
                    DummyTempBlob.FromRecord(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Digital Stamp PAC"));
                    VerifyDigitalStamp(DummyTempBlob, ExpectedDigitalStamp);
                    Clear(DummyTempBlob);
                    SalesCrMemoHeader.CalcFields("Original Document XML");
                    DummyTempBlob.FromRecord(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Original Document XML"));
                    VerifyCancelXML(
                      DummyTempBlob, SalesCrMemoHeader."Electronic Document Status" = SalesCrMemoHeader."Electronic Document Status"::Canceled,
                      SalesCrMemoHeader."CFDI Cancellation Reason Code", '');
                end;
            DATABASE::"Service Invoice Header":
                begin
                    ServiceInvoiceHeader.Get(PostedDocumentNo);
                    ServiceInvoiceHeader.TestField("Electronic Document Status", ExpectedStatus);
                    ServiceInvoiceHeader.TestField("No. of E-Documents Sent", ExpectedNoOfEmailsSent);
                    Assert.AreEqual(ExpectedDateTimeSentEmpty, ServiceInvoiceHeader."Date/Time Sent" = '',
                      StrSubstNo(ValueErr, ServiceInvoiceHeader.FieldName("Date/Time Sent")));
                    Assert.AreEqual(ExpectedDateTimeCanceledEmpty, ServiceInvoiceHeader."Date/Time Canceled" = '',
                      StrSubstNo(ValueErr, ServiceInvoiceHeader.FieldName("Date/Time Canceled")));
                    ServiceInvoiceHeader.TestField("Date/Time Stamped", ExpectedDateTimeStamped);
                    ServiceInvoiceHeader.TestField("PAC Web Service Name", ExpectedPACCode);
                    ServiceInvoiceHeader.TestField("Fiscal Invoice Number PAC", ExpectedInvoiceNoPAC);
                    ServiceInvoiceHeader.TestField("Error Code", ExpectedErrorCode);
                    ServiceInvoiceHeader.TestField("Error Description", ExpectedErrorDesc);
                    ServiceInvoiceHeader.CalcFields("Digital Stamp PAC");
                    DummyTempBlob.FromRecord(ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("Digital Stamp PAC"));
                    VerifyDigitalStamp(DummyTempBlob, ExpectedDigitalStamp);
                    Clear(DummyTempBlob);
                    ServiceInvoiceHeader.CalcFields("Original Document XML");
                    DummyTempBlob.FromRecord(ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("Original Document XML"));
                    VerifyCancelXML(
                      DummyTempBlob, ServiceInvoiceHeader."Electronic Document Status" = ServiceInvoiceHeader."Electronic Document Status"::Canceled,
                      ServiceInvoiceHeader."CFDI Cancellation Reason Code", '');
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    ServiceCrMemoHeader.Get(PostedDocumentNo);
                    ServiceCrMemoHeader.TestField("Electronic Document Status", ExpectedStatus);
                    ServiceCrMemoHeader.TestField("No. of E-Documents Sent", ExpectedNoOfEmailsSent);
                    Assert.AreEqual(ExpectedDateTimeSentEmpty, ServiceCrMemoHeader."Date/Time Sent" = '',
                      StrSubstNo(ValueErr, ServiceCrMemoHeader.FieldName("Date/Time Sent")));
                    Assert.AreEqual(ExpectedDateTimeCanceledEmpty, ServiceCrMemoHeader."Date/Time Canceled" = '',
                      StrSubstNo(ValueErr, ServiceCrMemoHeader.FieldName("Date/Time Canceled")));
                    ServiceCrMemoHeader.TestField("Date/Time Stamped", ExpectedDateTimeStamped);
                    ServiceCrMemoHeader.TestField("PAC Web Service Name", ExpectedPACCode);
                    ServiceCrMemoHeader.TestField("Fiscal Invoice Number PAC", ExpectedInvoiceNoPAC);
                    ServiceCrMemoHeader.TestField("Error Code", ExpectedErrorCode);
                    ServiceCrMemoHeader.TestField("Error Description", ExpectedErrorDesc);
                    ServiceCrMemoHeader.CalcFields("Digital Stamp PAC");
                    DummyTempBlob.FromRecord(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("Digital Stamp PAC"));
                    VerifyDigitalStamp(DummyTempBlob, ExpectedDigitalStamp);
                    Clear(DummyTempBlob);
                    ServiceCrMemoHeader.CalcFields("Original Document XML");
                    DummyTempBlob.FromRecord(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("Original Document XML"));
                    VerifyCancelXML(
                      DummyTempBlob, ServiceCrMemoHeader."Electronic Document Status" = ServiceCrMemoHeader."Electronic Document Status"::Canceled,
                      ServiceCrMemoHeader."CFDI Cancellation Reason Code", '');
                end;
            DATABASE::"Sales Shipment Header":
                begin
                    SalesShipmentHeader.Get(PostedDocumentNo);
                    SalesShipmentHeader.CalcFields("Original Document XML");
                    Assert.AreEqual(ExpectedDateTimeCanceledEmpty, SalesShipmentHeader."Date/Time Canceled" = '',
                        StrSubstNo(ValueErr, SalesShipmentHeader.FieldName("Date/Time Canceled")));
                    DummyTempBlob.FromRecord(SalesShipmentHeader, SalesShipmentHeader.FieldNo("Original Document XML"));
                    VerifyCancelXML(
                      DummyTempBlob,
                      SalesShipmentHeader."Electronic Document Status" = SalesShipmentHeader."Electronic Document Status"::Canceled,
                      SalesShipmentHeader."CFDI Cancellation Reason Code", '');
                end;
            DATABASE::"Transfer Shipment Header":
                begin
                    TransferShipmentHeader.Get(PostedDocumentNo);
                    TransferShipmentHeader.CalcFields("Original Document XML");
                    Assert.AreEqual(ExpectedDateTimeCanceledEmpty, TransferShipmentHeader."Date/Time Canceled" = '',
                        StrSubstNo(ValueErr, TransferShipmentHeader.FieldName("Date/Time Canceled")));
                    DummyTempBlob.FromRecord(TransferShipmentHeader, TransferShipmentHeader.FieldNo("Original Document XML"));
                    VerifyCancelXML(
                      DummyTempBlob,
                      TransferShipmentHeader."Electronic Document Status" = TransferShipmentHeader."Electronic Document Status"::Canceled,
                      TransferShipmentHeader."CFDI Cancellation Reason Code", '');
                end;
            DATABASE::"Cust. Ledger Entry":
                begin
                    LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PostedDocumentNo);
                    CustLedgerEntry.CalcFields("Original Document XML");
                    Assert.AreEqual(ExpectedDateTimeCanceledEmpty, CustLedgerEntry."Date/Time Canceled" = '',
                        StrSubstNo(ValueErr, CustLedgerEntry.FieldName("Date/Time Canceled")));
                    DummyTempBlob.FromRecord(CustLedgerEntry, CustLedgerEntry.FieldNo("Original Document XML"));
                    VerifyCancelXML(
                      DummyTempBlob,
                      CustLedgerEntry."Electronic Document Status" = CustLedgerEntry."Electronic Document Status"::Canceled,
                      CustLedgerEntry."CFDI Cancellation Reason Code", '');
                end;
        end;
    end;

    local procedure VerifyDigitalStamp(StampTempBlob: Codeunit "Temp Blob"; ExpectedStamp: Text[250])
    var
        InStream: InStream;
        Stamp: Text[250];
        StampBigText: Text;
    begin
        StampTempBlob.CreateInStream(InStream);
        InStream.Read(StampBigText);
        Stamp := CopyStr(StampBigText, 1, 250);
        Assert.AreEqual(ExpectedStamp, Stamp, '');
    end;

    local procedure MockCancel(Response: Option; var TempBlob: Codeunit "Temp Blob")
    begin
        if Response = ResponseOption::Success then
            MockCancelResponseCanceled(TempBlob)
        else
            MockFailure(TempBlob);
    end;

    local procedure MockRequestStamp(Response: Option; var TempBlob: Codeunit "Temp Blob"; NamespaceCFD: Text; SchemaLocationCFD: Text)
    begin
        if Response = ResponseOption::Success then
            MockSuccessRequestStamp(TempBlob, NamespaceCFD, SchemaLocationCFD)
        else
            MockFailure(TempBlob);
    end;

    local procedure MockFailure(var TempBlob: Codeunit "Temp Blob")
    var
        OutStream: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText('<Resultado Descripcion="Sello del Emisor No Valido" IdRespuesta="302" />');
    end;

    local procedure MockSuccessRequestStamp(var TempBlob: Codeunit "Temp Blob"; NamespaceCFD: Text; SchemaLocationCFD: Text)
    var
        OutStream: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText('<Resultado Descripcion="OK" IdRespuesta="1" >');
        OutStream.WriteText(
          CopyStr(
            StrSubstNo(
              '  <cfdi:Comprobante xsi:schemaLocation="%1 %2"', NamespaceCFD, SchemaLocationCFD), 1, 1024));
        OutStream.WriteText(' version="3.0" xmlns="" fecha="2011-11-08T09:02:03" formaDePago="Pago en una sola exhibici');
        OutStream.WriteText(
          'on" noCertificado="30001000000100000800" certificado="MIIE/TCCA+WgAwIBAgIUMzAwMDEwMDAwMDAxMDAwMDA4MDAwDQYJKoZIhvcNAQE');
        OutStream.WriteText('FBQAwggFvMRgwFgYDVQQDDA9BLkMuIGRlIHBydWViYXMxLzAtBgNVBAoMJlNlcnZpY2lvIGRlIEFkbWl');
        OutStream.WriteText('uaXN0cmFjacOzbiBUcmlidXRhcmlhMTgwNgYDVQQLDC9BZG1pbmlzdHJhY2nDs2');
        OutStream.WriteText(
          '4gZGUgU2VndXJpZGFkIGRlIGxhIEluZm9ybWFjacOzbjEpMCcGCSqGSIb3DQEJARYaYXNpc25ldEBwcnVlYmFzLnNhdC5nb2IubXgxJjAkBgNVBAkMHUF2');
        OutStream.WriteText('LiBIaWRhbGdvIDc3LCBDb2wuIEd1ZXJyZXJvMQ4wDAYDVQQRDAUwNjMwMDELMAkGA1UEBhMCTVgxGTA');
        OutStream.WriteText(
          'XBgNVBAgMEERpc3RyaXRvIEZlZGVyYWwxEjAQBgNVBAcMCUNveW9hY8OhbjEVMBMGA1UELRMMU0FUOTcwNzAxTk4zMTIwMAYJKoZIhvcNAQkCDCNSZXNwb2');
        OutStream.WriteText('5zYWJsZTogSMOpY3RvciBPcm5lbGFzIEFyY2lnYTAeFw0xMDA3MzAxNjU4NDBaFw0xMjA3MjkxNjU4');
        OutStream.WriteText(
          'NDBaMIGWMRIwEAYDVQQDDAlNYXRyaXogU0ExEjAQBgNVBCkMCU1hdHJpeiBTQTESMBAGA1UECgwJTWF0cml6IFNBMSUwIwYDVQQtExxBQUEwMTAxMDFBQUE');
        OutStream.WriteText('gLyBBQUFBMDEwMTAxQUFBMR4wHAYDVQQFExUgLyBBQUFBMDEwMTAxSERGUlhYMDExETAPBgNVBAsMC');
        OutStream.WriteText(
          'FVuaWRhZCAxMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDD0ltQNthUNUfzq0t1GpIyapjzOn1W5fGM5G/' +
          'pQyMluCzP9YlVAgBjGgzwYp9Z0J9gadg3y');
        OutStream.WriteText('2ZrYDwvv8b72goyRnhnv3bkjVRKlus6LDc00K7Jl23UYzNGlXn5+i0HxxuWonc2GYKFGsN4rFWKVy');
        OutStream.WriteText(
          '3Fnpv8Z2D7dNqsVyT5HapEqwIDAQABo4HqMIHnMAwGA1UdEwEB/wQCMAAwCwYDVR0PBA' +
          'QDAgbAMB0GA1UdDgQWBBSYodSwRczzj5H7mcO3+mAyXz+y0DAuBgN');
        OutStream.WriteText('VHR8EJzAlMCOgIaAfhh1odHRwOi8vcGtpLnNhdC5nb2IubXgvc2F0LmNybDAzBggrBgEFBQcBAQQ');
        OutStream.WriteText(
          'nMCUwIwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3NwLnNhdC5nb2IubXgvMB8GA1UdIwQYMBaAFOtZfQQimlONnnEaoFiWKfU54KDFMBAGA1UdIAQJMAc');
        OutStream.WriteText(
          'wBQYDKgMEMBMGA1UdJQQMMAoGCCsGAQUFBwMCMA0GCSqGSIb3DQEBBQUAA4IBAQArHQEorApwqumSn5EqDOAjbezi8fLco1cYES/' +
          'PD+LQRM1Vb1g7VLE3hR4S');
        OutStream.WriteText('5NNBv0bMwwWAr0WfL9lRRj0PMKLorO8y4TJjRU8MiYXfzSuKYL5Z16kW8zlVHw7CtmjhfjoIMwjQ');
        OutStream.WriteText(
          'o3prifWxFv7VpfIBstKKShU0qB6KzUUNwg2Ola4t4gg2JJcBmyIAIInHSGoeinR2V1tQ10aRqJdXkGin4WZ75yMbQH4L0NfotqY6bp');
        OutStream.WriteText(
          'F2CqIY3aogQyJGhUJji4gYnS2DvHcyoICwgawshjSaX8Y0Xlwnuh6EusqhqlhTgwPNAPrKIXCmOWtqjlDhho/lhkHJMzuTn8AoVapbBUnj"' +
          ' condicionesDe');
        OutStream.WriteText('Pago="30 DIAS" subTotal="250.000000" total="287.500000" metodoDePago="CHEQUE');
        OutStream.WriteText(
          '" tipoDeComprobante="ingreso" sello="UjFPBbIfOXXlMsVgqeayMUi4gbp291Nwd0vn1e4DRkzjz3Nw3ZXno1jJNXlTdR3P' +
          'OT5BqHM7NYILVFs+KaqnO');
        OutStream.WriteText('msM/05UsapfnTtneGIraoU/F2o4rQvg823nr/l61Cadl0nEm73btQiBhtq/4MrGLiUCGdAvcMiE');
        OutStream.WriteText(
          CopyStr(
            StrSubstNo(
              '4p4TcOf5qsE=" xmlns:cfdi="%1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">', NamespaceCFD), 1, 1024));
        OutStream.WriteText('    <cfdi:Emisor rfc="SWC920404DA3" nombre="CARGILL MEXICO">');
        OutStream.WriteText(
          '      <cfdi:DomicilioFiscal calle="AVE ROBLE 525" colonia="VALLE DEL CAMPESTRE" localidad="MONTERREY" ' +
          'municipio="VALLE DEL CAMPE');
        OutStream.WriteText('STRE" estado="NL" pais="MEXICO" codigoPostal="66230" />');
        OutStream.WriteText('      <cfdi:ExpedidoEn calle="AVE ROBLE 525" colonia="VALLE DEL CAMPESTRE" ' +
          'municipio="VALLE DEL CAMPESTRE" ');
        OutStream.WriteText('localidad="MONTERREY" estado="NL" pais="MEXICO" codigoPostal="66230" />');
        OutStream.WriteText('    </cfdi:Emisor>');
        OutStream.WriteText('    <cfdi:Receptor rfc="123456789123" nombre="AVE ROBLE">');
        OutStream.WriteText('      <cfdi:Domicilio calle="AVE ROBLE" colonia="VALLE DEL CAMPESTRE" ' +
          'municipio="VALLE DEL CAMPESTRE" ');
        OutStream.WriteText('localidad="SAN PEDRO" estado="NL" pais="MEXICO" codigoPostal="66230" />');
        OutStream.WriteText('    </cfdi:Receptor>');
        OutStream.WriteText('    <cfdi:Conceptos>');
        OutStream.WriteText('      <cfdi:Concepto cantidad="1.000000" ');
        OutStream.WriteText('descripcion="AP-BL-412 - CALCULADORA" valorUnitario="250.000000" importe="250.000000" />');
        OutStream.WriteText('    </cfdi:Conceptos>');
        OutStream.WriteText('    <cfdi:Impuestos totalImpuestosRetenidos="0.000000" totalImpuestosTrasladados="37.500000">');
        OutStream.WriteText('      <cfdi:Traslados>');
        OutStream.WriteText('        <cfdi:Traslado impuesto="IVA" tasa="15.000000" importe="37.500000" />');
        OutStream.WriteText('      </cfdi:Traslados>');
        OutStream.WriteText('    </cfdi:Impuestos>');
        OutStream.WriteText(
          CopyStr(
            StrSubstNo(
              '    <cfdi:Complemento xmlns:cfdi="%1" xmlns="">', NamespaceCFD), 1, 1024));
        OutStream.WriteText(
          '      <tfd:TimbreFiscalDigital version="1.0" UUID="9CDBDABD-9399-4DA1-8409-D1B70C5BA4DD" ' +
          'FechaTimbrado="2011-11-08T07:45:56" ');
        OutStream.WriteText('selloCFD="UjFPBbIfOXXlMsVgqeayMUi4gbp291Nwd0vn1e4DRkzjz3Nw3ZXno1jJNXlTdR3');
        OutStream.WriteText(
          'POT5BqHM7NYILVFs+KaqnOmsM/05UsapfnTtneGIraoU/F2o4rQvg823nr/l61Cadl0nEm73btQiBhtq/4MrGLiUCGdAvcMiE4p4TcOf5qsE=' +
          '" NoCertificadoSAT');
        OutStream.WriteText('="30001000000100000801" SelloSAT="WDTveFcG+ANYGdjrNrDcpYGdz4p0XsH5C0UTs');
        OutStream.WriteText(
          'qcMM/dSe4MGGnsacrJ75DAT5B5KqZWSefkGeg/sG7i6K3+lZTEuxje+rBDAp/4fMfYeL2TTMLpkU6Oy1zl/N6ywt38Z2+WTwcBIuIkEY54e' +
          '+mW+zkyJLAxkeDGJHAwEBd');
        OutStream.WriteText('f2nu0=" xsi:schemaLocation="http://www.sat.gob.mx/TimbreFiscalDigital');
        OutStream.WriteText(
          ' http://www.sat.gob.mx/TimbreFiscalDigital/TimbreFiscalDigital.xsd" ' +
          'xmlns:tfd="http://www.sat.gob.mx/TimbreFiscalDigital" />');
        OutStream.WriteText('    </cfdi:Complemento>');
        OutStream.WriteText('  </cfdi:Comprobante>');
        OutStream.WriteText('</Resultado>');
    end;

    local procedure MockCancelResponseCanceled(var TempBlob: Codeunit "Temp Blob")
    var
        OutStream: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText('<Resultado Descripcion="OK" IdRespuesta="1" ConsultaCancelacionId="a06554c8-6859-464c-aa65-5e540e970357" Estatus="Cancelado" Resultado="El documento ha sido cancelado satisfactoriamente.">');
        OutStream.WriteText('<Evento Acuse="&lt;?xml version=&quot;1.0&quot;?&gt;&#xD;&#xA;&lt;Acuse xmlns:xsd=&quot;http://www.w3.org/2001/XMLSchema&quot; xmlns:xsi=&quot;http://www.w3.org/2001/XMLSchema-instance&quot;&gt;&#xD;&#xA;  &lt;ExtensionData /&gt;&#xD;&#xA;  &lt;CodigoEstatus&gt;S - Comprobante obtenido satisfactoriamente.&lt;/CodigoEstatus&gt;&#xD;&#xA;  &lt;EsCancelable&gt;No Cancelable&lt;/EsCancelable&gt;&#xD;&#xA;  &lt;Estado&gt;Cancelado&lt;/Estado&gt;&#xD;&#xA;  &lt;EstatusCancelacion&gt;Cancelado sin aceptacin&lt;/EstatusCancelacion&gt;&#xD;&#xA;&lt;/Acuse&gt;" CodigoStatus="S - Comprobante obtenido satisfactoriamente." ConsultaId="a06554c8-6859-464c-aa65-5e540e970357" EsCancelable="No Cancelable" Estado="Cancelado" EstatusCancelacion="Cancelado sin aceptacin" Fecha="2024-03-04T09:09:22.273" FechaRegistro="2024-03-04T09:09:21.57" OperacionSolicitada="SolicitudCancelacion" Uuid="f9b01202-770b-42f8-82dd-79983e24fa71" />');
        OutStream.WriteText('<Evento ConsultaId="a06554c8-6859-464c-aa65-5e540e970357" EstatusCancelacion="En proceso" Fecha="2024-03-04T09:09:21.573" FechaRegistro="2024-03-04T09:09:21.57" OperacionSolicitada="SolicitudCancelacion" Uuid="f9b01202-770b-42f8-82dd-79983e24fa71" />');
        OutStream.WriteText('</Resultado>');
    end;

    local procedure MockCancelResponseRejected(var TempBlob: Codeunit "Temp Blob")
    var
        OutStream: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText('<Resultado Descripcion="OK" IdRespuesta="1" ConsultaCancelacionId="08fcbcd8-0493-46d5-946b-94ea0f6acd8b" ');
        OutStream.WriteText('Estatus="Rechazado" Resultado="El documento ha sido rechazado para su cancelacion"></Resultado>');
    end;

    local procedure MockCancelResponseInProgress(var TempBlob: Codeunit "Temp Blob")
    var
        OutStream: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText('<Resultado Descripcion="OK" IdRespuesta="1" ConsultaCancelacionId="08fcbcd8-0493-46d5-946b-94ea0f6acd8b" ');
        OutStream.WriteText('Estatus="EnProceso" Resultado="El documento aun esta en proceso de cancelacion"></Resultado>');
    end;

    local procedure MockFADisposalEntry(FANo: Code[20])
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        FADepreciationBook.SetRange("FA No.", FANo);
        FADepreciationBook.FindFirst();
        FALedgerEntry.Init();
        FALedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(FALedgerEntry, FALedgerEntry.FieldNo("Entry No."));
        FALedgerEntry."FA No." := FANo;
        FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::"Proceeds on Disposal";
        FALedgerEntry."Depreciation Book Code" := FADepreciationBook."Depreciation Book Code";
        FALedgerEntry.Amount := -LibraryRandom.RandDecInRange(1000, 2000, 2);
        FALedgerEntry.Insert();
    end;

    local procedure ConvertTxtToDateTime(InputTxt: Text): DateTime
    var
        InputTime: Time;
        Year: Integer;
        Month: Integer;
        Day: Integer;
    begin
        if InputTxt = '' then
            exit(0DT);
        // '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>'
        // 2021-01-29T16:32:10
        // YYYY-MM-DDThh:mm:ss
        Evaluate(Year, CopyStr(InputTxt, 1, 4));
        Evaluate(Month, CopyStr(InputTxt, 6, 2));
        Evaluate(Day, CopyStr(InputTxt, 9, 2));
        Evaluate(InputTime, CopyStr(InputTxt, 12, 8));
        exit(CreateDateTime(DMY2Date(Day, Month, Year), InputTime));
    end;

    local procedure CreateOriginalStringText(TableNo: Integer; DocumentNo: Code[20]) OriginalStringText: Text
    var
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
    begin
        GetOriginalString(TempBlob, TableNo, DocumentNo);
        TempBlob.CreateInStream(InStr);
        InStr.ReadText(OriginalStringText);
    end;

    local procedure ExportPaymentToServerFile(var CustLedgerEntry: Record "Cust. Ledger Entry"; var FileName: Text; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)", "Original Document XML");
        TempBlob.FromRecord(CustLedgerEntry, CustLedgerEntry.FieldNo("Original Document XML"));
        FileName := FileManagement.ServerTempFileName('.xml');
        FileManagement.BLOBExportToServerFile(TempBlob, FileName);
    end;

    local procedure FindCancellationReasonCode(SubstitutionRequired: Boolean): Code[10]
    var
        CFDICancellationReason: Record "CFDI Cancellation Reason";
    begin
        CFDICancellationReason.SetRange("Substitution Number Required", SubstitutionRequired);
        CFDICancellationReason.FindFirst();
        exit(CFDICancellationReason.Code);
    end;

    local procedure FindPostedHeader(var PostedHeaderRecRef: RecordRef; TableNo: Integer; FieldNo: Integer; DocumentNo: Code[20])
    var
        DocumentNoFieldRef: FieldRef;
    begin
        PostedHeaderRecRef.Open(TableNo);
        DocumentNoFieldRef := PostedHeaderRecRef.Field(FieldNo);
        DocumentNoFieldRef.SetRange(DocumentNo);
        PostedHeaderRecRef.FindLast();
    end;

    local procedure FindPostedLines(var PostedLineRecRef: RecordRef; TableNo: Integer; FieldNo: Integer; DocumentNo: Code[20])
    var
        DocumentNoFieldRef: FieldRef;
    begin
        PostedLineRecRef.Open(TableNo);
        DocumentNoFieldRef := PostedLineRecRef.Field(FieldNo);
        DocumentNoFieldRef.SetRange(DocumentNo);
        PostedLineRecRef.FindSet();
    end;

    local procedure FindTimeZone(var TimeZoneID: Text[180]; var TimeZoneOffset: Duration; var UserOffset: Duration)
    var
        TimeZone: Record "Time Zone";
        TypeHelper: Codeunit "Type Helper";
    begin
        TypeHelper.GetUserClientTypeOffset(UserOffset);
        TimeZone.SetFilter("Display Name", '*:00*');
        TimeZone.FindSet();
        TimeZone.Next(LibraryRandom.RandInt(TimeZone.Count));
        TimeZoneID := TimeZone.ID;
        TypeHelper.GetTimezoneOffset(TimeZoneOffset, TimeZone.ID);
    end;

    local procedure FormatDecimal(InAmount: Decimal; DecimalPlaces: Integer): Text
    begin
        exit(
          FormatDecimalRange(InAmount, DecimalPlaces, DecimalPlaces));
    end;

    local procedure FormatDecimalRange(InAmount: Decimal; DecimalPlacesFrom: Integer; DecimalPlacesTo: Integer): Text
    begin
        exit(
          Format(Abs(InAmount), 0, '<Precision,' + Format(DecimalPlacesFrom) + ':' + Format(DecimalPlacesTo) + '><Standard Format,1>'));
    end;

    local procedure FormatDateTime(DocDate: Date; DocTime: Time): Text[50]
    begin
        exit(
          Format(
            CreateDateTime(DocDate, DocTime), 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>'));
    end;

    local procedure GetCurrentDateTimeInUserTimeZone(): DateTime
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(TypeHelper.GetCurrentDateTimeInUserTimeZone());
    end;

    local procedure GetPaymentApplicationAmount(var DetailedCustLedgEntryPmt: Record "Detailed Cust. Ledg. Entry"; EntryNo: Integer)
    begin
        DetailedCustLedgEntryPmt.SetFilter(
            "Entry Type", '%1|%2|%3',
            DetailedCustLedgEntryPmt."Entry Type"::Application,
            DetailedCustLedgEntryPmt."Entry Type"::"Realized Gain",
            DetailedCustLedgEntryPmt."Entry Type"::"Realized Loss");
        DetailedCustLedgEntryPmt.SetRange("Cust. Ledger Entry No.", EntryNo);
        DetailedCustLedgEntryPmt.SetRange("Initial Document Type", DetailedCustLedgEntryPmt."Initial Document Type"::Payment);
        DetailedCustLedgEntryPmt.CalcSums(Amount);
        DetailedCustLedgEntryPmt.CalcSums("Amount (LCY)");
    end;

    local procedure GetPostedSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; DocumentNo: Code[20]);
    begin
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader."Fiscal Invoice Number PAC" := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader.Modify();
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
    end;

    local procedure GetPostedSalesCreditMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; DocumentNo: Code[20]);
    begin
        SalesCrMemoHeader.Get(DocumentNo);
        SalesCrMemoHeader."Fiscal Invoice Number PAC" := LibraryUtility.GenerateGUID();
        SalesCrMemoHeader.Modify();
        SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT");
    end;

    local procedure GetHeaderFieldValue(TableNo: Integer; DocumentNo: Code[20]; DocumentNoFieldNo: Integer; FieldNo: Integer): Code[10]
    var
        PostedHeaderRecRef: RecordRef;
        SelectedFieldRef: FieldRef;
    begin
        FindPostedHeader(PostedHeaderRecRef, TableNo, DocumentNoFieldNo, DocumentNo);
        SelectedFieldRef := PostedHeaderRecRef.Field(FieldNo);
        exit(SelectedFieldRef.Value);
    end;

    local procedure GetLineFieldValue(TableNo: Integer; DocumentNo: Code[20]; DocumentNoFieldNo: Integer; FieldNo: Integer): Text[10]
    var
        PostedLineRecRef: RecordRef;
        SelectedFieldRef: FieldRef;
    begin
        FindPostedLines(PostedLineRecRef, TableNo, DocumentNoFieldNo, DocumentNo);
        SelectedFieldRef := PostedLineRecRef.Field(FieldNo);
        exit(SelectedFieldRef.Value);
    end;

    local procedure GetOriginalString(var TempBlob: Codeunit "Temp Blob"; TableNo: Integer; DocumentNo: Code[20])
    var
        TempDocumentHeader: Record "Document Header" temporary;
        TempDocumentLine: Record "Document Line" temporary;
        TempDocumentLineRetention: Record "Document Line" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        SubTotal: Decimal;
        TotalTax: Decimal;
        TotalRetention: Decimal;
        TotalDiscount: Decimal;
    begin
        case TableNo of
            DATABASE::"Sales Invoice Header":
                begin
                    SalesInvoiceHeader.SetRange("No.", DocumentNo);
                    SalesInvoiceHeader.FindLast();
                    EInvoiceMgt.CreateTempDocument(
                        SalesInvoiceHeader, TempDocumentHeader, TempDocumentLine, TempDocumentLineRetention, TempVATAmountLine,
                        SubTotal, TotalTax, TotalRetention, TotalDiscount, false);
                    EInvoiceMgt.CreateOriginalStr33WithUUID(TempDocumentHeader, TempDocumentLine, '', 0, 0, false, TempBlob, '');
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoHeader.SetRange("No.", DocumentNo);
                    SalesCrMemoHeader.FindLast();
                    EInvoiceMgt.CreateTempDocument(
                        SalesCrMemoHeader, TempDocumentHeader, TempDocumentLine, TempDocumentLineRetention, TempVATAmountLine,
                        SubTotal, TotalTax, TotalRetention, TotalDiscount, false);
                    EInvoiceMgt.CreateOriginalStr33WithUUID(
                      TempDocumentHeader, TempDocumentLine, '', 0, 0, true, TempBlob, LibraryUtility.GenerateGUID());
                end;
            DATABASE::"Service Invoice Header":
                begin
                    ServiceInvoiceHeader.SetRange("No.", DocumentNo);
                    ServiceInvoiceHeader.FindLast();
                    EInvoiceMgt.CreateTempDocument(
                        ServiceInvoiceHeader, TempDocumentHeader, TempDocumentLine, TempDocumentLineRetention, TempVATAmountLine,
                        SubTotal, TotalTax, TotalRetention, TotalDiscount, false);
                    EInvoiceMgt.CreateOriginalStr33WithUUID(TempDocumentHeader, TempDocumentLine, '', 0, 0, false, TempBlob, '');
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    ServiceCrMemoHeader.SetRange("No.", DocumentNo);
                    ServiceCrMemoHeader.FindLast();
                    EInvoiceMgt.CreateTempDocument(
                        ServiceCrMemoHeader, TempDocumentHeader, TempDocumentLine, TempDocumentLineRetention, TempVATAmountLine,
                        SubTotal, TotalTax, TotalRetention, TotalDiscount, false);
                    EInvoiceMgt.CreateOriginalStr33WithUUID(
                      TempDocumentHeader, TempDocumentLine, '', 0, 0, true, TempBlob, LibraryUtility.GenerateGUID());
                end;
        end;
    end;

    local procedure GetForeignRFCNo(): Code[13]
    begin
        exit('XEXX010101000');
    end;

    local procedure GetTaxCodeTraslado(VATPct: Decimal): Text
    begin
        if VATPct in [0, 16] then
            exit('002');
        exit('003');
    end;

    local procedure GetTaxCodeRetention(VATPct: Decimal): Text
    begin
        if VATPct = 10 then
            exit('001');

        if VATPct in [10 .. 16] then
            exit('002');

        exit('001');
    end;

    local procedure GetDateTimeInDaysAgo(Days: Decimal): DateTime
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(
          TypeHelper.GetCurrentDateTimeInUserTimeZone() - Days * 24 * 3600 * 1000);
    end;

    local procedure GetSATInternationalTradeTerm(): Code[10]
    var
        SATInternationalTradeTerm: Record "SAT International Trade Term";
    begin
        SATInternationalTradeTerm.Next(LibraryRandom.RandInt(SATInternationalTradeTerm.Count));
        exit(SATInternationalTradeTerm.Code);
    end;

    local procedure GetSATCustomsRegime(): Code[10]
    var
        SATCustomsRegime: Record "SAT Customs Regime";
    begin
        SATCustomsRegime.Next(LibraryRandom.RandInt(SATCustomsRegime.Count));
        exit(SATCustomsRegime.Code);
    end;

    local procedure GetSATTransferReason(): Code[10]
    var
        SATTransferReason: Record "SAT Transfer Reason";
    begin
        SATTransferReason.Next(LibraryRandom.RandInt(SATTransferReason.Count));
        exit(SATTransferReason.Code);
    end;

    local procedure InitXMLReaderForPagos20(var FileName: Text)
    begin
        LibraryXPathXMLReader.Initialize(FileName, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/4');
        LibraryXPathXMLReader.AddAdditionalNamespace('pago20', 'http://www.sat.gob.mx/Pagos20');
    end;

    local procedure InitXMLReaderForSalesDocumentCFDI(RecordVariant: Variant; FieldNo: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        TempBlob.FromRecord(RecordVariant, FieldNo);
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/4');
    end;

    local procedure InitXMLReaderForSalesDocumentCCE(RecordVariant: Variant; FieldNo: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        TempBlob.FromRecord(RecordVariant, FieldNo);
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/4');
        LibraryXPathXMLReader.AddAdditionalNamespace('cce20', 'http://www.sat.gob.mx/ComercioExterior20');
    end;

    local procedure InitXMLReaderForCartaPorte(RecordVariant: Variant; FieldNo: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        TempBlob.FromRecord(RecordVariant, FieldNo);
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/4');
        LibraryXPathXMLReader.AddAdditionalNamespace('cartaporte31', 'http://www.sat.gob.mx/CartaPorte31');
        LibraryXPathXMLReader.AddAdditionalNamespace('cce20', 'http://www.sat.gob.mx/ComercioExterior20');
    end;

    local procedure InitOriginalStringFromCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; var OriginalStr: Text)
    var
        InStream: InStream;
    begin
        CustLedgerEntry.CalcFields("Original String");
        CustLedgerEntry."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
    end;

    local procedure OriginalStringMandatoryFields(HeaderTableNo: Integer; LineTableNo: Integer; DocumentNoFieldNo: Integer; CustomerFieldNo: Integer; CFDIPurposeFieldNo: Integer; CFDIRelationFieldNo: Integer; PaymentMethodCodeFieldNo: Integer; PaymentTermsCodeFieldNo: Integer; UnitOfMeasureCodeFieldNo: Integer; RelationIdx: Integer)
    var
        Customer: Record Customer;
        DocumentNo: Code[20];
        OriginalStringText: Text;
    begin
        Initialize();

        // Setup
        DocumentNo := CreateAndPostDoc(HeaderTableNo, CreatePaymentMethodForSAT());

        // Exercise
        OriginalStringText := CreateOriginalStringText(HeaderTableNo, DocumentNo);

        Customer.Get(
          GetHeaderFieldValue(HeaderTableNo, DocumentNo, DocumentNoFieldNo, CustomerFieldNo));

        // Verify
        VerifyOriginalStringFields(
          OriginalStringText,
          Customer."RFC No.",
          GetHeaderFieldValue(HeaderTableNo, DocumentNo, DocumentNoFieldNo, CFDIPurposeFieldNo),
          GetHeaderFieldValue(HeaderTableNo, DocumentNo, DocumentNoFieldNo, CFDIRelationFieldNo),
          SATUtilities.GetSATPaymentMethod(
            GetHeaderFieldValue(HeaderTableNo, DocumentNo, DocumentNoFieldNo, PaymentMethodCodeFieldNo)),
          SATUtilities.GetSATPaymentTerm(
            GetHeaderFieldValue(HeaderTableNo, DocumentNo, DocumentNoFieldNo, PaymentTermsCodeFieldNo)),
          SATUtilities.GetSATUnitofMeasure(
            GetLineFieldValue(LineTableNo, DocumentNo, DocumentNoFieldNo, UnitOfMeasureCodeFieldNo)),
          RelationIdx);
    end;

    local procedure SetupUSDCurrencyGLSetup() ExchRateAmount: Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        GeneralLedgerSetup.Get();
        LibraryERM.CreateCurrency(Currency);
        GeneralLedgerSetup.Validate("USD Currency Code", Currency.Code);
        GeneralLedgerSetup.Modify(true);
        ExchRateAmount := LibraryRandom.RandDecInRange(10, 20, 2);
        LibraryERM.CreateExchangeRate(
          GeneralLedgerSetup."USD Currency Code", WorkDate(), 1 / ExchRateAmount, 1 / ExchRateAmount);
    end;

    local procedure UpdateSalesHeaderForeignTrade(var SalesHeader: Record "Sales Header")
    var
        SATInternationalTradeTerm: Record "SAT International Trade Term";
        Location: Record Location;
    begin
        SATInternationalTradeTerm.Next(LibraryRandom.RandInt(SATInternationalTradeTerm.Count));
        SalesHeader.Validate("Foreign Trade", true);
        SalesHeader.Validate("SAT International Trade Term", SATInternationalTradeTerm.Code);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader."SAT Address ID" := CreateSATAddress();
        SalesHeader.Modify(true);
        UpdateLocationForCartaPorte(SalesHeader."Location Code");
    end;

    local procedure UpdateSalesLineForeingTrade(SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        SATCustomsUnit: Record "SAT Customs Unit";
    begin
        Item.Get(SalesLine."No.");
        Item."Tariff No." := LibraryUtility.GenerateGUID();
        Item.Modify();
        SATCustomsUnit.Next(LibraryRandom.RandInt(SATCustomsUnit.Count));
        UnitOfMeasure.Get(SalesLine."Unit of Measure Code");
        UnitOfMeasure."SAT Customs Unit" := SATCustomsUnit.Code;
        UnitOfMeasure.Modify();
    end;

    local procedure UpdateDocumentFieldValue(TableNo: Integer; FieldNo: Integer; DocumentNo: Code[20]; ChangeFieldNo: Integer; ChangeValue: Variant)
    var
        PostedHeaderRecRef: RecordRef;
        ChangeFieldRef: FieldRef;
    begin
        FindPostedHeader(PostedHeaderRecRef, TableNo, FieldNo, DocumentNo);
        ChangeFieldRef := PostedHeaderRecRef.Field(ChangeFieldNo);
        ChangeFieldRef.Value := ChangeValue;
        PostedHeaderRecRef.Modify();
    end;

    local procedure UpdateDocumentLocation(TableNo: Integer; FieldNoDocumentNo: Integer; DocumentNo: Code[20]; FieldNoLocation: Integer; LocationCode: Variant)
    var
        PostedHeaderRecRef: RecordRef;
        ChangeFieldRef: FieldRef;
    begin
        FindPostedHeader(PostedHeaderRecRef, TableNo, FieldNoDocumentNo, DocumentNo);
        ChangeFieldRef := PostedHeaderRecRef.Field(FieldNoLocation);
        ChangeFieldRef.Value := LocationCode;
        PostedHeaderRecRef.Modify();
    end;

    local procedure UpdateCustomerPostCode(CustomerNo: Code[20]; City: Variant; PostCode: Variant)
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.City := City;
        Customer."Post Code" := PostCode;
        Customer.Modify();
    end;

    local procedure UpdateCustomerSATPaymentFields(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer."Payment Method Code" := CreatePaymentMethodForSAT();
        Customer."Payment Terms Code" := CreatePaymentTermsForSAT();
        Customer.Modify();
    end;

    local procedure UpdateDocumentWithTimeZone(TableID: Integer; FieldNoDocumentNo: Integer; DocumentNo: Code[20]; FieldNoLocation: Integer; TimeZoneID: Text[180])
    var
        PostCode: Record "Post Code";
        Location: Record Location;
    begin
        CreatePostCode(PostCode, TimeZoneID);
        LibraryWarehouse.CreateLocation(Location);
        Location."Post Code" := PostCode.Code;
        Location.City := PostCode.City;
        Location.Modify();
        UpdateDocumentLocation(TableID, FieldNoDocumentNo, DocumentNo, FieldNoLocation, Location.Code);
    end;

    local procedure UpdateSalesInvoiceCancellation(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader."Fiscal Invoice Number PAC" := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader."Electronic Document Status" := SalesInvoiceHeader."Electronic Document Status"::"Cancel In Progress";
        SalesInvoiceHeader."CFDI Cancellation ID" := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader."CFDI Cancellation Reason Code" := FindCancellationReasonCode(false);
        SalesInvoiceHeader."Error Description" := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader."Date/Time Cancel Sent" := GetCurrentDateTimeInUserTimeZone();
        SalesInvoiceHeader."Date/Time Canceled" := FormatDateTime(WorkDate(), Time);
        SalesInvoiceHeader.Modify();
    end;

    local procedure UpdateSalesShipmentForCartaPorte(var SalesShipmentHeader: Record "Sales Shipment Header")
    var
        Location: Record Location;
    begin
        SalesShipmentHeader."Transit-from Date/Time" := GetCurrentDateTimeInUserTimeZone();
        SalesShipmentHeader."Transit Hours" := LibraryRandom.RandIntInRange(5, 10);
        SalesShipmentHeader."Transit Distance" := LibraryRandom.RandIntInRange(5, 10);
        SalesShipmentHeader."Insurer Name" := LibraryUtility.GenerateGUID();
        SalesShipmentHeader."Insurer Policy Number" := LibraryUtility.GenerateGUID();
        SalesShipmentHeader."Vehicle Code" := CreateVehicle();
        SalesShipmentHeader."Trailer 1" := CreateTrailer();
        SalesShipmentHeader."SAT Weight Unit Of Measure" := 'XAG';
        LibraryWarehouse.CreateLocationWithAddress(Location);
        SalesShipmentHeader."Location Code" := Location.Code;
        SalesShipmentHeader."SAT Address ID" := CreateSATAddress();
        SalesShipmentHeader.Modify();
        UpdateLocationForCartaPorte(SalesShipmentHeader."Location Code");
        CreateTransportOperator(DATABASE::"Sales Shipment Header", SalesShipmentHeader."No.");
    end;

    local procedure UpdateSalesShipmentForCartaPorteForeignTrade(var SalesShipmentHeader: Record "Sales Shipment Header")
    begin
        SalesShipmentHeader."SAT International Trade Term" := GetSATInternationalTradeTerm();
        SalesShipmentHeader."SAT Customs Regime" := GetSATCustomsRegime();
        SalesShipmentHeader."SAT Transfer Reason" := GetSATTransferReason();
        SalesShipmentHeader."Exchange Rate USD" := LibraryRandom.RandDecInRange(10, 20, 2);
        SalesShipmentHeader."Foreign Trade" := true;
        SalesShipmentHeader.Modify();
    end;

    local procedure UpdateTransferShipmentForCartaPorte(var TransferShipmentHeader: Record "Transfer Shipment Header")
    begin
        TransferShipmentHeader."Transit-from Date/Time" := GetCurrentDateTimeInUserTimeZone();
        TransferShipmentHeader."Transit Hours" := LibraryRandom.RandIntInRange(5, 10);
        TransferShipmentHeader."Transit Distance" := LibraryRandom.RandIntInRange(5, 10);
        TransferShipmentHeader."Insurer Name" := LibraryUtility.GenerateGUID();
        TransferShipmentHeader."Insurer Policy Number" := LibraryUtility.GenerateGUID();
        TransferShipmentHeader."Vehicle Code" := CreateVehicle();
        TransferShipmentHeader."Trailer 1" := CreateTrailer();
        TransferShipmentHeader."SAT Weight Unit Of Measure" := 'XAG';
        TransferShipmentHeader.Modify();
        UpdateLocationForCartaPorte(TransferShipmentHeader."Transfer-from Code");
        UpdateLocationForCartaPorte(TransferShipmentHeader."Transfer-to Code");
        CreateTransportOperator(DATABASE::"Transfer Shipment Header", TransferShipmentHeader."No.");
    end;

    local procedure UpdateTransferShipmentForCartaPorteForeignTrade(var TransferShipmentHeader: Record "Transfer Shipment Header")
    begin
        TransferShipmentHeader."SAT International Trade Term" := GetSATInternationalTradeTerm();
        TransferShipmentHeader."SAT Customs Regime" := GetSATCustomsRegime();
        TransferShipmentHeader."SAT Transfer Reason" := GetSATTransferReason();
        TransferShipmentHeader."Exchange Rate USD" := LibraryRandom.RandDecInRange(10, 20, 2);
        TransferShipmentHeader."Foreign Trade" := true;
        TransferShipmentHeader.Modify();
    end;

    local procedure UpdateLocationForCartaPorte(LocationCode: Code[20])
    var
        Location: Record Location;
    begin
        Location.Get(LocationCode);
        Location."SAT Address ID" := CreateSATAddress();
        Location.Address := LibraryUtility.GenerateGUID();
        Location."Country/Region Code" := 'TEST';
        Location.Modify();
    end;

    local procedure UpdateGLSetupTimeExpiration()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Cancel on time expiration" := true;
        GeneralLedgerSetup.Modify();
    end;

    local procedure UpdateGLSetupRounding(Decimals: Text[5])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Inv. Rounding Precision (LCY)" := GeneralLedgerSetup."Amount Rounding Precision";
        GeneralLedgerSetup."Amount Decimal Places" := Decimals;
        GeneralLedgerSetup.Modify();
    end;

    local procedure UpdateCurrencyWithRounding(CurrencyCode: Code[20]; RoundingPrecision: Decimal; Decimals: Text[5])
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        Currency."Amount Rounding Precision" := RoundingPrecision;
        Currency."Invoice Rounding Precision" := RoundingPrecision;
        Currency."Amount Decimal Places" := Decimals;
        Currency.Modify();
    end;

    local procedure UpdateSimulationModeOnGLSetup(Enabled: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Sim. Signature", Enabled);
        GeneralLedgerSetup.Validate("Sim. Send", Enabled);
        GeneralLedgerSetup.Validate("Sim. Request Stamp", Enabled);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateMultipleSATCertOnGLSetup(Enabled: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Multiple SAT Certificates" := Enabled;
        GeneralLedgerSetup.Modify();
    end;

    local procedure UpdateSATCertificateOnGLSetup(SATCertificateCode: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."SAT Certificate" := SATCertificateCode;
        GeneralLedgerSetup.Modify();
    end;

    local procedure UpdateSATCertificateOnLocation(var Location: Record Location; SATCertificateCode: Code[20])
    begin
        Location."SAT Certificate" := SATCertificateCode;
        Location.Modify();
    end;

    local procedure UpdateLocationOnPostedSalesInvoice(PostedDocNo: Code[20]; LocationCode: Code[10])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(PostedDocNo);
        SalesInvoiceHeader."Location Code" := LocationCode;
        SalesInvoiceHeader.Modify();
    end;

    local procedure UpdateLocationFromOnTransferShipment(PostedDocNo: Code[20]; LocationCode: Code[10])
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        TransferShipmentHeader.Get(PostedDocNo);
        TransferShipmentHeader."Transfer-from Code" := LocationCode;
        TransferShipmentHeader.Modify();
    end;

    local procedure VerifyMandatoryFields(OriginalString: Text; RFCNo: Code[13]; CFDIPurpose: Code[10]; CFDIRelation: Code[10]; PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; UnitOfMeasureCode: Text[10]; RelationIdx: Integer)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        Assert.AreEqual('4.0', SelectStr(3, OriginalString), StrSubstNo(IncorrectSchemaVersionErr, OriginalString));

        Assert.AreEqual(
          CompanyInformation."RFC Number",
          SelectStr(13 + RelationIdx, OriginalString),
          StrSubstNo(IncorrectOriginalStrValueErr, RFCNoFieldTxt, OriginalString));
        Assert.AreEqual(
          CompanyInformation."SAT Tax Regime Classification",
          SelectStr(15 + RelationIdx, OriginalString),
          StrSubstNo(IncorrectOriginalStrValueErr, RegimenFieldTxt, OriginalString));

        Assert.AreEqual(
          RFCNo,
          SelectStr(16 + RelationIdx, OriginalString),
          StrSubstNo(IncorrectOriginalStrValueErr, RFCNoFieldTxt, OriginalString));
        Assert.AreEqual(
          CFDIPurpose,
          SelectStr(20 + RelationIdx, OriginalString),
          StrSubstNo(IncorrectOriginalStrValueErr, CFDIPurposeFieldTxt, OriginalString));
        VerifyCFDIRelation(OriginalString, CFDIRelation, RelationIdx);

        Assert.AreEqual(
          PaymentMethodCode,
          SelectStr(5, OriginalString),
          StrSubstNo(IncorrectOriginalStrValueErr, FormaDePagoFieldTxt, OriginalString));
        Assert.AreEqual(
          PaymentTermsCode,
          SelectStr(11, OriginalString),
          StrSubstNo(IncorrectOriginalStrValueErr, MetodoDePagoFieldTxt, OriginalString));
        Assert.AreEqual(
          UpperCase(UnitOfMeasureCode),
          SelectStr(24 + RelationIdx, OriginalString),
          StrSubstNo(IncorrectOriginalStrValueErr, ConceptoUnidadFieldTxt, OriginalString));
    end;

    local procedure VerifyPartyInformation(OriginalStr: Text; RFCNumber: Text[30]; ReceptorName: Text[300]; SATPostalCode: Code[20]; SATTaxRegime: Text[10]; StartPosition1: Integer; StartPosition2: Integer)
    var
        CompanyInformation: Record "Company Information";
    begin
        // Enisor/RFC
        CompanyInformation.Get();
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Emisor', 'Rfc', CompanyInformation."RFC Number");
        Assert.AreEqual(CompanyInformation."RFC Number", SelectStr(StartPosition1 - 3, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Enisor/Rfc', OriginalStr));
        //  Enisor/RegimenFiscal
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Emisor', 'RegimenFiscal', CompanyInformation."SAT Tax Regime Classification");
        Assert.AreEqual(CompanyInformation."SAT Tax Regime Classification", SelectStr(StartPosition1 - 1, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Enisor/RegimenFiscal', OriginalStr));

        // Rfc
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Receptor', 'Rfc', RFCNumber);
        Assert.AreEqual(RFCNumber, SelectStr(StartPosition1, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Rfc', OriginalStr));
        // Nombre
        if ReceptorName <> '' then begin
            StartPosition1 += 1;
            LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Receptor', 'Nombre', ReceptorName);
            Assert.AreEqual(ReceptorName, SelectStr(StartPosition1, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Nombre', OriginalStr));
        end;
        // DomicilioFiscalReceptor
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Receptor', 'DomicilioFiscalReceptor', SATPostalCode);
        Assert.AreEqual(SATPostalCode, SelectStr(StartPosition1 + 1, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'DomicilioFiscalReceptor', OriginalStr));
        // ResidenciaFiscal
        // NumRegIDTrib
        // RegimenFiscalReceptor
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Receptor', 'RegimenFiscalReceptor', SATTaxRegime);
        Assert.AreEqual(SATTaxRegime, SelectStr(StartPosition2, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'RegimenFiscalReceptor', OriginalStr));
        // UsoCFDI
    end;

    local procedure VerifyCFDIRelation(OriginalString: Text; CFDIRelation: Code[10]; RelationIdx: Integer)
    begin
        if RelationIdx = 0 then
            exit;

        Assert.AreEqual(
          CFDIRelation,
          SelectStr(11 + RelationIdx, OriginalString),
          StrSubstNo(IncorrectOriginalStrValueErr, CFDIRelationFieldTxt, OriginalString));
    end;

    local procedure VerifyOriginalStringFields(OriginalString: Text; RFCNo: Code[13]; CFDIPurpose: Code[10]; CFDIRelation: Code[10]; PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; UnitOfMeasureCode: Text[10]; RelationIdx: Integer)
    var
        OriginalStrCSV: Text;
    begin
        OriginalStrCSV := ConvertStr(OriginalString, '|', ',');
        VerifyMandatoryFields(
          OriginalStrCSV, RFCNo, CFDIPurpose, CFDIRelation, PaymentMethodCode, PaymentTermsCode, UnitOfMeasureCode, RelationIdx);
    end;

    local procedure VerifyCFDIConceptoFields(OriginalStr: Text; NoIdentificacion: Code[20]; SATUnitOfMeasure: Code[10]; LineType: Enum "Sales Line Type")
    var
        StartPosition: Integer;
    begin
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        StartPosition := 23;
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Conceptos/cfdi:Concepto', 'ClaveProdServ', SATUtilities.GetSATClassification(LineType, NoIdentificacion));
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Conceptos/cfdi:Concepto', 'NoIdentificacion', NoIdentificacion);
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Conceptos/cfdi:Concepto', 'ClaveUnidad', SATUnitOfMeasure);

        Assert.AreEqual(
          SATUtilities.GetSATClassification(LineType, NoIdentificacion), SelectStr(StartPosition, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'SAT Item Classification', OriginalStr));
        Assert.AreEqual(
          NoIdentificacion, SelectStr(StartPosition + 1, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'NoIdentificacion', OriginalStr));
        Assert.AreEqual(
          SATUnitOfMeasure, SelectStr(StartPosition + 3, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'SAT Unit of Measure', OriginalStr));
    end;

    local procedure VerifyConceptoNode(OriginalStr: Text; ClaveProdServ: Text; Cantidad: Text; ClaveUnidad: Text; Descripcion: Text; ValorUnitario: Text; Importe: Text; StartPosition: Integer)
    begin
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Conceptos/cfdi:Concepto', 'ClaveProdServ', ClaveProdServ);  // required
        // NoIdentificacion // optional
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Conceptos/cfdi:Concepto', 'Cantidad', Cantidad); // required
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Conceptos/cfdi:Concepto', 'ClaveUnidad', ClaveUnidad);
        // Unidad // optional
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Conceptos/cfdi:Concepto', 'Descripcion', Descripcion); // required
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Conceptos/cfdi:Concepto', 'ValorUnitario', ValorUnitario); // required
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Conceptos/cfdi:Concepto', 'Importe', Importe); // required
        // Descuento // optional
        // ObjetoImp // required

        Assert.AreEqual(
          ClaveProdServ, SelectStr(StartPosition, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'ClaveProdServ', OriginalStr));
        Assert.AreEqual(
          Cantidad, SelectStr(StartPosition + 1, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Cantidad', OriginalStr));
        Assert.AreEqual(
          ClaveUnidad, SelectStr(StartPosition + 2, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'ClaveUnidad', OriginalStr));
        Assert.AreEqual(
          Descripcion, SelectStr(StartPosition + 3, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Descripcion', OriginalStr));
        Assert.AreEqual(
          ValorUnitario, SelectStr(StartPosition + 4, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'ValorUnitario', OriginalStr));
        Assert.AreEqual(
          Importe, SelectStr(StartPosition + 5, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Importe', OriginalStr));
    end;

    local procedure VerifyComercioExteriorHeader(OriginalStr: Text; SATInternationalTermsCode: Code[10]; ExchRateUSD: Decimal; TotalAmountUSD: Decimal; StartPosition: Integer)
    begin
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Complemento/cce20:ComercioExterior', 'Version', '2.0');
        Assert.AreEqual(
          '2.0', SelectStr(StartPosition, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Version', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Complemento/cce20:ComercioExterior', 'ClaveDePedimento', 'A1');
        Assert.AreEqual(
          'A1', SelectStr(StartPosition + 1, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'ClaveDePedimento', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Complemento/cce20:ComercioExterior', 'CertificadoOrigen', '0');
        Assert.AreEqual(
          '0', SelectStr(StartPosition + 2, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'CertificadoOrigen', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Complemento/cce20:ComercioExterior', 'Incoterm', SATInternationalTermsCode);
        Assert.AreEqual(
          SATInternationalTermsCode,
          SelectStr(StartPosition + 3, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Incoterm', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cce20:ComercioExterior', 'TipoCambioUSD', FormatDecimal(ExchRateUSD, 6));
        Assert.AreEqual(
          FormatDecimal(ExchRateUSD, 6),
          SelectStr(StartPosition + 4, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'TipoCambioUSD', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cce20:ComercioExterior', 'TotalUSD', FormatDecimal(TotalAmountUSD, 2));
        Assert.AreEqual(
          FormatDecimal(TotalAmountUSD, 2),
          SelectStr(StartPosition + 5, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'TotalUSD', OriginalStr));
    end;

    local procedure VerifyComercioExteriorLine(OriginalStr: Text; SalesLine: Record "Sales Line"; Quantity: Decimal; UnitPrice: Decimal; AmountUSD: Decimal; StartPosition: Integer; Index: Integer)
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
    begin
        Item.Get(SalesLine."No.");
        UnitOfMeasure.Get(SalesLine."Unit of Measure Code");
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/cce20:ComercioExterior/cce20:Mercancias/cce20:Mercancia',
          'NoIdentificacion', SalesLine."No.", Index);
        Assert.AreEqual(
          SalesLine."No.",
          SelectStr(StartPosition, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'NoIdentificacion', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/cce20:ComercioExterior/cce20:Mercancias/cce20:Mercancia', 'FraccionArancelaria', Item."Tariff No.", Index);
        Assert.AreEqual(
          Item."Tariff No.",
          SelectStr(StartPosition + 1, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'FraccionArancelaria', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/cce20:ComercioExterior/cce20:Mercancias/cce20:Mercancia', 'CantidadAduana', Format(Quantity), Index);
        Assert.AreEqual(
          Format(Quantity),
          SelectStr(StartPosition + 2, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'CantidadAduana', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/cce20:ComercioExterior/cce20:Mercancias/cce20:Mercancia', 'UnidadAduana',
          UnitOfMeasure."SAT Customs Unit", Index);
        Assert.AreEqual(
          UnitOfMeasure."SAT Customs Unit",
          SelectStr(StartPosition + 3, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'UnidadAduana', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/cce20:ComercioExterior/cce20:Mercancias/cce20:Mercancia', 'ValorUnitarioAduana',
          FormatDecimal(UnitPrice, 6), Index);
        Assert.AreEqual(
          FormatDecimal(UnitPrice, 6),
          SelectStr(StartPosition + 4, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'ValorUnitarioAduana', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/cce20:ComercioExterior/cce20:Mercancias/cce20:Mercancia', 'ValorDolares',
          FormatDecimal(AmountUSD, 4), Index);
        Assert.AreEqual(
          FormatDecimal(AmountUSD, 4),
          SelectStr(StartPosition + 5, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'ValorDolares', OriginalStr));
    end;

    local procedure VerifyComplementoPagoAmountWithCurrency(OriginalStr: Text; PaymentAmountLCY: Decimal; CurrencyPmt: Text; CurrencyFactorPmt: Text; PaymentAmountFCY: Decimal; CurrencyInv: Text; CurrencyFactorDR: Text; ImpPagado: Decimal; StartPosition: Integer)
    begin
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago20:Pagos/pago20:Totales', 'MontoTotalPagos', FormatDecimal(abs(PaymentAmountLCY), 2));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago', 'MonedaP', CurrencyPmt);
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago', 'TipoCambioP', CurrencyFactorPmt);
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago', 'Monto', FormatDecimal(abs(PaymentAmountFCY), 2));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:DoctoRelacionado', 'MonedaDR', CurrencyInv);
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:DoctoRelacionado', 'ImpPagado', FormatDecimal(Abs(ImpPagado), 2));

        Assert.AreEqual(
          FormatDecimal(PaymentAmountLCY, 2), SelectStr(StartPosition, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'MontoTotalPagos', OriginalStr));
        Assert.AreEqual(
          CurrencyPmt, SelectStr(StartPosition + 3, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'MonedaP', OriginalStr));
        Assert.AreEqual(
          CurrencyFactorPmt, SelectStr(StartPosition + 4, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'TipoCambioP', OriginalStr));
        Assert.AreEqual(
          FormatDecimal(PaymentAmountFCY, 2), SelectStr(StartPosition + 5, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Monto', OriginalStr));
        Assert.AreEqual(
          CurrencyInv, SelectStr(StartPosition + 8, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'MonedaDR', OriginalStr));
        Assert.AreEqual(
          CurrencyFactorDR, SelectStr(StartPosition + 9, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'EquivalenciaDR', OriginalStr));
        Assert.AreEqual(
          FormatDecimal(Abs(ImpPagado), 2), SelectStr(StartPosition + 12, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'ImpPagado', OriginalStr));
    end;

    local procedure VerifyComplementoPago(OriginalStr: Text; ImpSaldoAnt: Decimal; ImpPagado: Decimal; ImpSaldoInsoluto: Decimal; IdDocumento: Text; NumParcialidad: Text; Index: Integer)
    var
        StartPos: Integer;
    begin
        StartPos := 40;
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:DoctoRelacionado', 'ImpSaldoAnt',
          FormatDecimal(ImpSaldoAnt, 2), Index);
        Assert.AreEqual(
          FormatDecimal(ImpSaldoAnt, 2),
          SelectStr(StartPos + Index * 14, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'ImpSaldoAnt', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:DoctoRelacionado', 'ImpPagado',
          FormatDecimal(ImpPagado, 2), Index);
        Assert.AreEqual(
          FormatDecimal(ImpPagado, 2),
          SelectStr(StartPos + 1 + Index * 14, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'ImpPagado', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:DoctoRelacionado', 'ImpSaldoInsoluto',
          FormatDecimal(ImpSaldoInsoluto, 2), Index);
        Assert.AreEqual(
          FormatDecimal(ImpSaldoInsoluto, 2),
          SelectStr(StartPos + 2 + Index * 14, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'ImpSaldoInsoluto', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:DoctoRelacionado', 'IdDocumento',
          IdDocumento, Index);
        Assert.AreEqual(
          IdDocumento,
          SelectStr(StartPos - 5 + Index * 14, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'IdDocumento', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:DoctoRelacionado', 'NumParcialidad',
          NumParcialidad, Index);
        Assert.AreEqual(
          NumParcialidad,
          SelectStr(StartPos - 1 + Index * 14, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'NumParcialidad', OriginalStr));
    end;

    local procedure VerifyComplementoPagoTrasladoP(OriginalStr: Text; StartPosition: Integer; BaseP: Decimal; ImporteP: Decimal; TasaOCuotaP: Decimal; Index: Integer)
    begin
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:ImpuestosP/pago20:TrasladosP/pago20:TrasladoP', 'BaseP',
          FormatDecimal(BaseP, 6), Index);
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:ImpuestosP/pago20:TrasladosP/pago20:TrasladoP', 'TasaOCuotaP',
          FormatDecimal(TasaOCuotaP, 6), Index);
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:ImpuestosP/pago20:TrasladosP/pago20:TrasladoP', 'ImporteP',
          FormatDecimal(ImporteP, 6), Index);

        Assert.AreEqual(
          FormatDecimal(BaseP, 6),
          SelectStr(StartPosition, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'BaseP', OriginalStr));
        Assert.AreEqual(
          FormatDecimal(TasaOCuotaP, 6),
          SelectStr(StartPosition + 3, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'TasaOCuotaP', OriginalStr));
        Assert.AreEqual(
          FormatDecimal(ImporteP, 6),
          SelectStr(StartPosition + 4, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'ImporteP', OriginalStr));
    end;

    local procedure VerifyComplementoPagoTrasladoPExempt(OriginalStr: Text; StartPosition: Integer; BaseP: Decimal; Index: Integer)
    begin
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:ImpuestosP/pago20:TrasladosP/pago20:TrasladoP', 'BaseP',
          FormatDecimal(BaseP, 6), Index);
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:ImpuestosP/pago20:TrasladosP/pago20:TrasladoP', 'TipoFactorP',
          'Exento', Index);

        Assert.AreEqual(
          FormatDecimal(BaseP, 6),
          SelectStr(StartPosition, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Base', OriginalStr));
        Assert.AreEqual(
          'Exento',
          SelectStr(StartPosition + 2, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'TipoFactorP', OriginalStr));
    end;

    local procedure VerifyIsNearlyEqualDateTime(ActualDateTime: DateTime; ExpectedDateTime: DateTime)
    begin
        Assert.IsTrue(
          Abs(ActualDateTime - ExpectedDateTime) < 60 * 1000, StrSubstNo('%1 %2', ActualDateTime, ExpectedDateTime));
    end;

    local procedure VerifyRootNodeTotals(OriginalStr: Text; Total: Decimal; SubTotal: Decimal; Discount: Decimal)
    begin
        LibraryXPathXMLReader.VerityAttributeFromRootNode('SubTotal', FormatDecimal(SubTotal, 2));
        LibraryXPathXMLReader.VerityAttributeFromRootNode('Total', FormatDecimal(Total, 2));
        LibraryXPathXMLReader.VerityAttributeFromRootNode('Descuento', FormatDecimal(Discount, 2));
        Assert.AreEqual(
          FormatDecimal(SubTotal, 2), SelectStr(7, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'SubTotal', OriginalStr));
        Assert.AreEqual(
          FormatDecimal(Total, 2), SelectStr(10, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Total', OriginalStr));
        Assert.AreEqual(
          FormatDecimal(Discount, 2), SelectStr(8, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Descuento', OriginalStr));
    end;

    local procedure VerifyVATAmountLines(OriginalStr: Text; Amount: Decimal; VATAmount: Decimal; VATPct: Decimal; Impuesto: Text; Offset: Integer; index: Integer)
    var
        StartPosition: Integer;
    begin
        StartPosition := 33;
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'Importe', FormatDecimal(VATAmount, 6), index);
        Assert.AreEqual(
          FormatDecimal(VATAmount, 6), SelectStr(StartPosition + 4 + index * 15 + Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Importe', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'TasaOCuota', FormatDecimal(VATPct / 100, 6), index);
        Assert.AreEqual(
          FormatDecimal(VATPct / 100, 6), SelectStr(StartPosition + 3 + index * 15 + Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'TasaOCuota', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'TipoFactor', 'Tasa', index);
        Assert.AreEqual(
          'Tasa', SelectStr(StartPosition + 2 + index * 15 + Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Tasa', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'Impuesto', Impuesto, index);
        Assert.AreEqual(
          Impuesto, SelectStr(StartPosition + 1 + index * 15 + Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Impuesto', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'Base', FormatDecimal(Amount, 6), index);
        Assert.AreEqual(
          FormatDecimal(Amount, 6), SelectStr(StartPosition + index * 15 + Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Base', OriginalStr));
    end;

    local procedure VerifyVATAmountLinesExempt(OriginalStr: Text; Amount: Decimal; Impuesto: Text)
    var
        StartPosition: Integer;
    begin
        StartPosition := 33;
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'TipoFactor', 'Exento');
        Assert.AreEqual(
          'Exento', SelectStr(StartPosition + 2, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Exento', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'Impuesto', Impuesto);
        Assert.AreEqual(
          Impuesto, SelectStr(StartPosition + 1, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Impuesto', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'Base', FormatDecimal(Amount, 6));
        Assert.AreEqual(
          FormatDecimal(Amount, 6), SelectStr(StartPosition, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Base', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeAbsence(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'Importe');

        LibraryXPathXMLReader.VerifyAttributeAbsence(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'TasaOCuota');
    end;

    local procedure VerifyRetentionAmountLine(OriginalStr: Text; Amount: Decimal; VATAmount: Decimal; VATPct: Decimal; Impuesto: Text; Offset: Integer; index: Integer)
    begin
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion',
          'Importe', FormatDecimal(VATAmount, 6), index);
        Assert.AreEqual(
          FormatDecimal(VATAmount, 6), SelectStr(Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Importe', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion',
          'TasaOCuota', FormatDecimal(VATPct / 100, 6), index);
        Assert.AreEqual(
          FormatDecimal(VATPct / 100, 6), SelectStr(Offset - 1, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'TasaOCuota', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion',
          'TipoFactor', 'Tasa', index);
        Assert.AreEqual(
          'Tasa', SelectStr(Offset - 2, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Tasa', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion',
          'Impuesto', Impuesto, index);
        Assert.AreEqual(
          Impuesto, SelectStr(Offset - 3, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Impuesto', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion',
          'Base', FormatDecimal(Amount, 6), index);
        Assert.AreEqual(
          FormatDecimal(Amount, 6), SelectStr(Offset - 4, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Base', OriginalStr));
    end;

    local procedure VerifyVATTotalLine(OriginalStr: Text; VATAmount: Decimal; VATPct: Decimal; Impuesto: Text; index: Integer; LineQty: Integer; Offset: Integer)
    var
        StartPosition: Integer;
        TotalOffset: Integer;
    begin
        StartPosition := 39;
        TotalOffset := (LineQty - 1) * 15;

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado', 'Importe', FormatDecimal(VATAmount, 2), index);
        Assert.AreEqual(
          FormatDecimal(VATAmount, 2), SelectStr(StartPosition + 3 + TotalOffset + index * 5 + Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Importe', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado', 'TasaOCuota', FormatDecimal(VATPct / 100, 6), index);
        Assert.AreEqual(
          FormatDecimal(VATPct / 100, 6), SelectStr(StartPosition + 2 + TotalOffset + index * 5 + Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'TasaOCuota', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado', 'TipoFactor', 'Tasa', index);
        Assert.AreEqual(
          'Tasa', SelectStr(StartPosition + 1 + TotalOffset + index * 5 + Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'TipoFactor', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado', 'Impuesto', Impuesto, index);
        Assert.AreEqual(
          Impuesto, SelectStr(StartPosition + TotalOffset + index * 5 + Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Impuesto', OriginalStr));
    end;

    local procedure VerifyRetentionTotalLine(OriginalStr: Text; VATAmount: Decimal; Impuesto: Text; Offset: Integer; index: Integer)
    begin
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion', 'Importe', FormatDecimal(VATAmount, 2), index);
        Assert.AreEqual(
          FormatDecimal(VATAmount, 2), SelectStr(Offset + 1, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Importe', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion', 'Impuesto', Impuesto, index);
        Assert.AreEqual(
          Impuesto, SelectStr(Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Impuesto', OriginalStr));
    end;

    local procedure VerifyTotalImpuestos(OriginalStr: Text; TotalImpuestosNode: Text; TotalVATAmount: Decimal; Offset: Integer)
    begin
        // 'TotalImpuestosTrasladados' or 'TotalImpuestosRetenidos'
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Impuestos', TotalImpuestosNode, FormatDecimal(TotalVATAmount, 2));
        Assert.AreEqual(
          FormatDecimal(TotalVATAmount, 2), SelectStr(Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, TotalImpuestosNode, OriginalStr));
    end;

    local procedure VerifyLineAmountsByIndex(DiscountAmount: Decimal; LineAmount: Decimal; UnitPrice: Decimal; VATAmount: Decimal; VATBase: Decimal; Index: Integer)
    begin
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto', 'Descuento', FormatDecimal(DiscountAmount, 6), Index);
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto', 'Importe', FormatDecimal(LineAmount, 6), Index);
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto', 'ValorUnitario', FormatDecimal(UnitPrice, 6), Index);

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'Importe', FormatDecimal(VATAmount, 6), Index);
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'Base', FormatDecimal(VATBase, 6), Index);
    end;

    local procedure VerifyPDFFile()
    var
        FilePath: Text;
    begin
        NameValueBuffer.SetRange(Name, Format(CODEUNIT::"MX CFDI"));
        NameValueBuffer.FindFirst();
        FilePath := NameValueBuffer.Value;
        NameValueBuffer.DeleteAll();

        Assert.IsTrue(Exists(FilePath), '');
        Assert.AreEqual('.pdf', CopyStr(FilePath, StrLen(FilePath) - 3), '');
    end;

    local procedure VerifyCartaPorteXMLValues(OriginalStr: Text; IdCCP: Text; TransitDistance: Integer; VehicleNo: Code[20]; GrossWeight: Decimal; StartPosition: Integer)
    var
        CompanyInformation: Record "Company Information";
        FixedAsset: Record "Fixed Asset";
    begin
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Complemento/cartaporte31:CartaPorte', 'Version', '3.1'); // Version
        Assert.AreEqual('3.1', SelectStr(StartPosition, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Version', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Complemento/cartaporte31:CartaPorte', 'IdCCP', IdCCP); // IdCCP
        Assert.AreEqual(IdCCP, SelectStr(StartPosition + 1, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'IdCCP', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Complemento/cartaporte31:CartaPorte', 'TranspInternac', 'No'); // TranspInternac
        Assert.AreEqual('No', SelectStr(StartPosition + 2, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'TranspInternac', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cartaporte31:CartaPorte', 'TotalDistRec', FormatDecimal(TransitDistance, 6)); // TotalDistRec
        Assert.AreEqual(
          FormatDecimal(TransitDistance, 6), SelectStr(StartPosition + 3, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'TotalDistRec', OriginalStr));

        // Ubicaciones
        CompanyInformation.Get();
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cartaporte31:CartaPorte/cartaporte31:Ubicaciones/cartaporte31:Ubicacion',
          'RFCRemitenteDestinatario', CompanyInformation."RFC Number"); // RFCRemitenteDestinatario
        Assert.AreEqual(
          CompanyInformation."RFC Number", SelectStr(StartPosition + 5, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'RFCRemitenteDestinatario', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/cartaporte31:CartaPorte/cartaporte31:Ubicaciones/cartaporte31:Ubicacion',
          'DistanciaRecorrida', FormatDecimal(TransitDistance, 6), 1); // DistanciaRecorrida
        Assert.AreEqual(
          FormatDecimal(TransitDistance, 6), SelectStr(StartPosition + 17, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'DistanciaRecorrida', OriginalStr));

        // Mercancias
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cartaporte31:CartaPorte/cartaporte31:Mercancias', 'PesoBrutoTotal', FormatDecimal(GrossWeight, 3)); // PesoBrutoTotal
        Assert.AreEqual(
          FormatDecimal(GrossWeight, 3), SelectStr(StartPosition + 25, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'PesoBrutoTotal', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cartaporte31:CartaPorte/cartaporte31:Mercancias', 'UnidadPeso', 'XAG'); // UnidadPeso
        Assert.AreEqual('XAG', SelectStr(StartPosition + 26, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'UnidadPeso', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cartaporte31:CartaPorte/cartaporte31:Mercancias', 'NumTotalMercancias', '1'); // NumTotalMercancias
        Assert.AreEqual('1', SelectStr(StartPosition + 27, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'NumTotalMercancias', OriginalStr));

        // Mercancias/Mercancia
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cartaporte31:CartaPorte/cartaporte31:Mercancias/cartaporte31:Mercancia', 'MaterialPeligroso', 'No'); // MaterialPeligroso
        Assert.AreEqual('No', SelectStr(StartPosition + 32, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'MaterialPeligroso', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cartaporte31:CartaPorte/cartaporte31:Mercancias/cartaporte31:Mercancia',
          'PesoEnKg', FormatDecimal(GrossWeight, 3)); // PesoEnKg
        Assert.AreEqual(
          FormatDecimal(GrossWeight, 3), SelectStr(StartPosition + 33, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'PesoEnKg', OriginalStr));

        // Vehicle
        FixedAsset.Get(VehicleNo);
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cartaporte31:CartaPorte/cartaporte31:Mercancias/cartaporte31:Autotransporte',
          'PermSCT', FixedAsset."SCT Permission Type"); // PermSCT
        Assert.AreEqual(
          FixedAsset."SCT Permission Type", SelectStr(StartPosition + 36, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'PermSCT', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cartaporte31:CartaPorte/cartaporte31:Mercancias/cartaporte31:Autotransporte',
          'NumPermisoSCT', FixedAsset."SCT Permission No."); // NumPermisoSCT
        Assert.AreEqual(
          FixedAsset."SCT Permission No.", SelectStr(StartPosition + 37, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'NumPermisoSCT', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cartaporte31:CartaPorte/cartaporte31:Mercancias/cartaporte31:Autotransporte/cartaporte31:IdentificacionVehicular',
          'ConfigVehicular', FixedAsset."SAT Federal Autotransport"); // ConfigVehicular
        Assert.AreEqual(
          FixedAsset."SAT Federal Autotransport", SelectStr(StartPosition + 38, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'ConfigVehicular', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cartaporte31:CartaPorte/cartaporte31:Mercancias/cartaporte31:Autotransporte/cartaporte31:IdentificacionVehicular',
          'PesoBrutoVehicular', FormatDecimal(FixedAsset."Vehicle Gross Weight", 2)); // PesoBrutoVehicular
        Assert.AreEqual(
          FormatDecimal(FixedAsset."Vehicle Gross Weight", 2), SelectStr(StartPosition + 39, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'PesoBrutoVehicular', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cartaporte31:CartaPorte/cartaporte31:Mercancias/cartaporte31:Autotransporte/cartaporte31:IdentificacionVehicular',
          'PlacaVM', FixedAsset."Vehicle Licence Plate");
        Assert.AreEqual(
          FixedAsset."Vehicle Licence Plate", SelectStr(StartPosition + 40, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'PlacaVM', OriginalStr));

        // TiposFigura
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cartaporte31:CartaPorte/cartaporte31:FiguraTransporte/cartaporte31:TiposFigura', 'TipoFigura', '01');
        Assert.AreEqual('01', SelectStr(StartPosition + 46, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'TipoFigura', OriginalStr));
    end;

    local procedure VerifyCartaPorteXMLValuesForeignTrade(OriginalStr: Text; IdCCP: Text; SATTransferReason: Code[20]; SATInternationalTermsCode: Code[10]; ExchRateUSD: Decimal; SATCustomsRegime: Code[10]; StartPosition: Integer)
    var
        CompanyInformation: Record "Company Information";
        CCEOffset: Integer;
    begin
        CCEOffset := 26;
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Complemento/cartaporte31:CartaPorte', 'Version', '3.1'); // Version
        Assert.AreEqual('3.1', SelectStr(StartPosition + CCEOffset, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Version', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Complemento/cartaporte31:CartaPorte', 'IdCCP', IdCCP); // IdCCP
        Assert.AreEqual(IdCCP, SelectStr(StartPosition + CCEOffset + 1, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'IdCCP', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Complemento/cartaporte31:CartaPorte', 'TranspInternac', 'Sí'); // TranspInternac
        Assert.AreEqual('Sí', SelectStr(StartPosition + CCEOffset + 2, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'TranspInternac', OriginalStr));

        // CoercioExterior
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Complemento/cce20:ComercioExterior', 'Version', '2.0'); // Version
        Assert.AreEqual(
          '2.0', SelectStr(StartPosition, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Version', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Complemento/cce20:ComercioExterior', 'MotivoTraslado', SATTransferReason); // MotivoTraslado
        Assert.AreEqual(
          SATTransferReason, SelectStr(StartPosition + 1, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'MotivoTraslado', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Complemento/cce20:ComercioExterior', 'ClaveDePedimento', 'A1'); // ClaveDePedimento
        Assert.AreEqual(
          'A1', SelectStr(StartPosition + 2, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'ClaveDePedimento', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Complemento/cce20:ComercioExterior', 'CertificadoOrigen', '0');
        Assert.AreEqual(
          '0', SelectStr(StartPosition + 3, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'CertificadoOrigen', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Complemento/cce20:ComercioExterior', 'Incoterm', SATInternationalTermsCode); // Incoterm
        Assert.AreEqual(
          SATInternationalTermsCode,
          SelectStr(StartPosition + 4, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Incoterm', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cce20:ComercioExterior', 'TipoCambioUSD', FormatDecimal(ExchRateUSD, 6)); // TipoCambioUSD
        Assert.AreEqual(
          FormatDecimal(ExchRateUSD, 6),
          SelectStr(StartPosition + 5, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'TipoCambioUSD', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Complemento/cce20:ComercioExterior', 'TotalUSD', FormatDecimal(0, 2)); // TotalUSD
        Assert.AreEqual(
          FormatDecimal(0, 2), SelectStr(StartPosition + 6, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'TotalUSD', OriginalStr));

        // RegimenesAduaneros
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cartaporte31:CartaPorte/cartaporte31:RegimenesAduaneros/cartaporte31:RegimenAduaneroCCP', 'RegimenAduanero', SATCustomsRegime); // RegimenAduanero
        Assert.AreEqual(SATCustomsRegime, SelectStr(StartPosition + CCEOffset + 7, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'RegimenAduanero', OriginalStr));

        // Ubicaciones
        CompanyInformation.Get();
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cartaporte31:CartaPorte/cartaporte31:Ubicaciones/cartaporte31:Ubicacion',
          'RFCRemitenteDestinatario', CompanyInformation."RFC Number"); // RFCRemitenteDestinatario
        Assert.AreEqual(
          CompanyInformation."RFC Number", SelectStr(StartPosition + CCEOffset + 9, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'RFCRemitenteDestinatario', OriginalStr));

        // Mercancias
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cartaporte31:CartaPorte/cartaporte31:Mercancias', 'UnidadPeso', 'XAG'); // UnidadPeso
        Assert.AreEqual(
          'XAG', SelectStr(StartPosition + CCEOffset + 32, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'UnidadPeso', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cartaporte31:CartaPorte/cartaporte31:Mercancias', 'NumTotalMercancias', '1'); // NumTotalMercancias
        Assert.AreEqual(
          '1', SelectStr(StartPosition + CCEOffset + 33, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'NumTotalMercancias', OriginalStr));

        // Mercancias/Mercancia
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cartaporte31:CartaPorte/cartaporte31:Mercancias/cartaporte31:Mercancia', 'MaterialPeligroso', 'No'); // MaterialPeligroso
        Assert.AreEqual(
          'No', SelectStr(StartPosition + CCEOffset + 38, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'MaterialPeligroso', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cartaporte31:CartaPorte/cartaporte31:Mercancias/cartaporte31:Mercancia', 'TipoMateria', '01'); // TipoMateria
        Assert.AreEqual(
          '01', SelectStr(StartPosition + CCEOffset + 43, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'TipoMateria', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cartaporte31:CartaPorte/cartaporte31:Mercancias/cartaporte31:Mercancia/cartaporte31:DocumentacionAduanera',
          'TipoDocumento', '02'); // IdentDocAduanero
        Assert.AreEqual(
          '02', SelectStr(StartPosition + CCEOffset + 44, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'TipoDocumento', OriginalStr));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/cartaporte31:CartaPorte/cartaporte31:Mercancias/cartaporte31:Mercancia/cartaporte31:DocumentacionAduanera',
          'IdentDocAduanero', 'identifier'); // IdentDocAduanero
        Assert.AreEqual(
          'identifier', SelectStr(StartPosition + CCEOffset + 45, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'IdentDocAduanero', OriginalStr));
    end;

    local procedure VerfifyCartaPorteDataset(DocumentNo: Code[20]; FiscalInvoiceNumber: Text; DateTimeStamped: Text; ItemNo: Code[20])
    var
        RowValue: Variant;
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DocumentNo', DocumentNo);
        LibraryReportDataset.AssertElementWithValueExists('TransferRFCNo', 'XAXX010101000');
        LibraryReportDataset.AssertElementWithValueExists('FolioText', FiscalInvoiceNumber);
        LibraryReportDataset.AssertElementWithValueExists('DateTimeStamped', DateTimeStamped);
        LibraryReportDataset.AssertElementWithValueExists('DocumentLine_No', ItemNo);

        LibraryReportDataset.MoveToRow(1);
        LibraryReportDataset.GetElementValueInCurrentRow('OriginalStringBase64Text', RowValue);
        Assert.AreNotEqual('', RowValue, StrSubstNo(IfEmptyErr, 'OriginalStringBase64Text', DocumentNo));
        LibraryReportDataset.GetElementValueInCurrentRow('DigitalSignatureBase64Text', RowValue);
        Assert.AreNotEqual('', RowValue, StrSubstNo(IfEmptyErr, 'DigitalSignatureBase64Text', DocumentNo));
        LibraryReportDataset.GetElementValueInCurrentRow('DigitalSignaturePACBase64Text', RowValue);
        Assert.AreNotEqual('', RowValue, StrSubstNo(IfEmptyErr, 'DigitalSignaturePACBase64Text', DocumentNo));
        LibraryReportDataset.MoveToRow(3);
        LibraryReportDataset.GetElementValueInCurrentRow('QRCode', RowValue);
        Assert.AreNotEqual('', RowValue, StrSubstNo(IfEmptyErr, 'QRCode', DocumentNo));
    end;

    local procedure VerifyCancelXML(var TempBlob: Codeunit "Temp Blob"; IsCancelled: Boolean; MotivoCancelacion: Text; FolioSustitucion: Text)
    begin
        if not IsCancelled then
            exit;
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.VerifyAttributeValue('Cancelacion/Folios/Folio', 'MotivoCancelacion', MotivoCancelacion);
        if FolioSustitucion <> '' then
            LibraryXPathXMLReader.VerifyAttributeValue('Cancelacion/Folios/Folio', 'FolioSustitucion', FolioSustitucion);
    end;

    local procedure CreateBasicSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
    end;

    local procedure CreateBasicServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20])
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        LibraryInventory.CreateItem(Item);
        ServiceHeader.Init();
        ServiceHeader.Validate("Document Type", DocumentType);
        ServiceHeader.Validate("Customer No.", CustomerNo);
        ServiceHeader.Validate("Due Date", WorkDate());
        ServiceHeader.Insert(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        ServiceLine.Modify(true);
    end;

    local procedure CreateCustomerNoDiscount() CustomerNo: Code[20]
    var
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";

        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Validate("Payment Method Code", PaymentMethod.Code);
        Customer.Modify(true);
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        Value: Variant;
    begin
        LibraryVariableStorage.Dequeue(Value);
        Reply := Value;
    end;

    [StrMenuHandler]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    var
        Value: Variant;
        "Action": Option;
    begin
        LibraryVariableStorage.Dequeue(Value);
        Action := Value;
        case Action of
            ActionOption::"Request Stamp":
                Choice := 1;
            ActionOption::Send:
                Choice := 2;
            ActionOption::"Request Stamp and Send":
                Choice := 3;
            else
                Error(OptionNotSupportedErr);
        end;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CancelRequestMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    var
        Value: Variant;
        "Action": Option;
    begin
        LibraryVariableStorage.Dequeue(Value);
        Action := Value;
        case Action of
            CancelOption::CancelRequest:
                Choice := 1;
            CancelOption::GetResponse:
                Choice := 2;
            CancelOption::MarkAsCanceled:
                Choice := 3;
            CancelOption::ResetCancelRequest:
                Choice := 4;
            else
                Error(OptionNotSupportedErr);
        end;
    end;

    [ReportHandler]
    procedure SalesInvoiceReportHandler(var ElecSalesInvoiceMX: Report "Elec. Sales Invoice MX")
    begin
    end;

    [ReportHandler]
    procedure SalesCrMemoReportHandler(var ElecSalesCrMemoMX: Report "Elec. Sales Credit Memo MX")
    begin
    end;

    [ReportHandler]
    procedure ServiceInvoiceReportHandler(var ElecServiceInvoiceMX: Report "Elec. Service Invoice MX")
    begin
    end;

    [ReportHandler]
    procedure ServiceCrMemoReportHandler(var ElecServiceCrMemoMX: Report "Elec. Service Cr Memo MX")
    begin
    end;

    [MessageHandler]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;

    [RequestPageHandler]
    procedure CartaPorteReqPageHandler(var ElectronicCartaPorteMX: TestRequestPage "Electronic Carta Porte MX")
    begin
        ElectronicCartaPorteMX.SaveAsXML(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeDownloadHandler', '', false, false)]
    local procedure SetFilePathOnBeforeDownloadHandler(var ToFolder: Text; ToFileName: Text; FromFileName: Text; var IsHandled: Boolean)
    begin
        if NameValueBuffer.FindLast() then;
        NameValueBuffer.ID += 1;
        NameValueBuffer.Name := Format(CODEUNIT::"MX CFDI");
        NameValueBuffer.Value := FromFileName;
        NameValueBuffer.Insert();
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, 10145, 'OnBeforeGetNumeroPedimento', '', false, false)]
    local procedure SetNumeroPedimento(TempDocumentLine: Record "Document Line" temporary; var NumberPedimento: Text; var IsHandled: Boolean)
    begin
        if not NameValueBuffer.Get(CODEUNIT::"MX CFDI") then
            exit;
        if NameValueBuffer.Name = 'Rounding' then
            exit;
        NumberPedimento := NameValueBuffer.Value;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, 10145, 'OnAfterRequestStamp', '', false, false)]
    local procedure SetDocumentErrorCode(var DocumentHeaderRecordRef: RecordRef)
    var
        TempBlob: Codeunit "Temp Blob";
        FieldRef: FieldRef;
    begin
        if not NameValueBuffer.Get(CODEUNIT::"MX CFDI") then
            exit;
        if NameValueBuffer.Name <> 'Rounding' then
            exit;

        FieldRef := DocumentHeaderRecordRef.Field(10035);
        FieldRef.Value := 'CFDI40108';
        MockFailure(TempBlob);
        FieldRef := DocumentHeaderRecordRef.Field(10025);
        TempBlob.ToFieldRef(FieldRef);
        DocumentHeaderRecordRef.Modify();

        case NameValueBuffer.Value of
            '1':
                NameValueBuffer.Delete();
            '2':
                begin
                    NameValueBuffer.Value := '1';
                    NameValueBuffer.Modify();
                end;
        end;
    end;

    [ModalPageHandler]
    procedure ChangeFiscalNumberPACInPostedSalesInvUpdatePage(var PostedSalesInvUpdatePage: TestPage "Posted Sales Inv. - Update")
    begin
        PostedSalesInvUpdatePage."Fiscal Invoice Number PAC".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvUpdatePage.Ok().Invoke();
    end;
}
