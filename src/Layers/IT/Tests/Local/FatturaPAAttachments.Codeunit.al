codeunit 144205 "FatturaPA Attachments"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [FatturaPA] [Export] [Attachments]
    end;

    var
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        FatturaPA_ElectronicFormatTxt: Label 'FatturaPA';
        UnexpectedElementValueErr: Label 'Unexpected element value for element %1. Expected element value: %2. Actual element value: %3.', Comment = '%1=XML Element Name;%2=Expected XML Element Value;%3=Actual XML element Value;';
        UnexpectedElementNameErr: Label 'Unexpected element name. Expected element name: %1. Actual element name: %2.', Comment = '%1=Expetced XML Element Name;%2=Actual XML Element Name;';

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithoutAttachment()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        RecRef: RecordRef;
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 302532] Posted sales invoice without attachment
        Initialize();

        // [GIVEN] Posted sales invoice (without any attachment)
        CreatePostSalesInvoice(RecRef);

        // [WHEN] Export Fattura PA for the posted document
        ExportFaturaPA(RecRef, TempBlob);

        // [THEN] Exported XML doesn't have "FatturaElettronicaBody\Allegati" node
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        Assert.IsFalse(
          TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, 'FatturaElettronicaBody/Allegati'),
          'Unexpected Attachment node in the exported Fatttura PA XML');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceSingleAttachment()
    var
        RecRef: RecordRef;
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
        Extension: Text;
        Base64String: Text;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 302532] Posted sales invoice with a single attachment
        Initialize();

        // [GIVEN] Posted sales invoice
        CreatePostSalesInvoice(RecRef);

        // [GIVEN] Insert attachment for the posted document using file "PATH\FILE.EXT" with plain text = "TEXT"
        MockAttachment(RecRef, FileName, Extension, Base64String, LibraryRandom.RandIntInRange(100, 200));

        // [WHEN] Export Fattura PA for the posted document
        ExportFaturaPA(RecRef, TempBlob);

        // [THEN] Exported XML has "FatturaElettronicaBody\Allegati" node with the following values:
        // [THEN] "NomeAttachment" = "FILE", "FormatoAttachment" = "EXT", "Attachment" = "X", where "X" = base64Encoding("TEXT")
        VerifySingleAttachment(TempBlob, FileName, Extension, Base64String);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceSingleBigAttachment()
    var
        RecRef: RecordRef;
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
        Extension: Text;
        Base64String: Text;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 302532] Posted sales invoice with a single attachment having > 1000 text chars length
        Initialize();

        // [GIVEN] Posted sales invoice
        CreatePostSalesInvoice(RecRef);

        // [GIVEN] Insert attachment for the posted document using file "PATH\FILE.EXT" with plain text = "TEXT.." with > 1000 char length
        MockAttachment(RecRef, FileName, Extension, Base64String, LibraryRandom.RandIntInRange(1000, 2000));

        // [WHEN] Export Fattura PA for the posted document
        ExportFaturaPA(RecRef, TempBlob);

        // [THEN] Exported XML has "FatturaElettronicaBody\Allegati" node with the following values:
        // [THEN] "NomeAttachment" = "FILE", "FormatoAttachment" = "EXT", "Attachment" = "X", where "X" = base64Encoding("TEXT..")
        VerifySingleAttachment(TempBlob, FileName, Extension, Base64String);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceTwoAttachments()
    var
        RecRef: RecordRef;
        TempBlob: Codeunit "Temp Blob";
        FileName: array[2] of Text;
        Extension: array[2] of Text;
        Base64String: array[2] of Text;
        i: Integer;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 302532] Posted sales invoice with two attachments
        Initialize();

        // [GIVEN] Posted sales invoice
        CreatePostSalesInvoice(RecRef);

        // [GIVEN] Insert 1st attachment for the posted document using file "PATH\FILE1.EXT1" with plain text = "TEXT1"
        // [GIVEN] Insert 2nd attachment for the posted document using file "PATH\FILE2.EXT2" with plain text = "TEXT2"
        for i := 1 to ArrayLen(FileName) do
            MockAttachment(RecRef, FileName[i], Extension[i], Base64String[i], LibraryRandom.RandIntInRange(10, 20));

        // [WHEN] Export Fattura PA for the posted document
        ExportFaturaPA(RecRef, TempBlob);

        // [THEN] Exported XML has two "FatturaElettronicaBody\Allegati" nodes with the following values:
        // [THEN] 1st: "NomeAttachment" = "FILE1", "FormatoAttachment" = "EXT1", "Attachment" = "X1", where "X1" = base64Encoding("TEXT1")
        // [THEN] 2nd: "NomeAttachment" = "FILE2", "FormatoAttachment" = "EXT2", "Attachment" = "X2", where "X2" = base64Encoding("TEXT2")
        VerifyTwoAttachments(TempBlob, FileName, Extension, Base64String);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoSingleAttachment()
    var
        RecRef: RecordRef;
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
        Extension: Text;
        Base64String: Text;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 302532] Posted sales credit memo with a single attachment
        Initialize();

        // [GIVEN] Posted sales credit memo
        CreatePostSalesCrMemo(RecRef);

        // [GIVEN] Insert attachment for the posted document using file "PATH\FILE.EXT" with plain text = "TEXT"
        MockAttachment(RecRef, FileName, Extension, Base64String, LibraryRandom.RandIntInRange(100, 200));

        // [WHEN] Export Fattura PA for the posted document
        ExportFaturaPA(RecRef, TempBlob);

        // [THEN] Exported XML has "FatturaElettronicaBody\Allegati" node with the following values:
        // [THEN] "NomeAttachment" = "FILE", "FormatoAttachment" = "EXT", "Attachment" = "X", where "X" = base64Encoding("TEXT")
        VerifySingleAttachment(TempBlob, FileName, Extension, Base64String);
    end;

    [Test]
    [HandlerFunctions('ErrorMessagesPageHandlerWithoutVerification')]
    [Scope('OnPrem')]
    procedure SalesDocNoPmtTermsSingleAttachment()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        RecRef: RecordRef;
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
        Extension: Text;
        Base64String: Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 394076] Allegati xml node exports under the FatturaElettronicaBody if document does not have payment terms code

        Initialize();

        // [GIVEN] Posted sales invoice with no payment terms code
        SalesInvoiceHeader.Get(
          CreatePostSalesDocWithPmtData(SalesHeader."Document Type"::Invoice, CreatePaymentTerms(), ''));
        RecRef.Get(SalesInvoiceHeader.RecordId);
        RecRef.SetRecFilter();

        // [GIVEN] Insert attachment for the posted document using file "PATH\FILE.EXT" with plain text = "TEXT"
        MockAttachment(RecRef, FileName, Extension, Base64String, LibraryRandom.RandIntInRange(100, 200));

        // [WHEN] Export Fattura PA for the posted document
        ExportFaturaPA(RecRef, TempBlob);

        // [THEN] Exported XML has "FatturaElettronicaBody\Allegati" node with the following values:
        // [THEN] "NomeAttachment" = "FILE", "FormatoAttachment" = "EXT", "Attachent" = "X", where "X" = base64Encoding("TEXT")
        VerifySingleAttachment(TempBlob, FileName, Extension, Base64String);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibraryITLocalization.SetupFatturaPA();
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        IsInitialized := true;
    end;

    local procedure ExportFaturaPA(Document: Variant; var TempBlob: Codeunit "Temp Blob")
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ClientFileName: Text[250];
    begin
        ElectronicDocumentFormat.SendElectronically(
          TempBlob, ClientFileName, Document, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));
    end;

    local procedure MockAttachment(RecRef: RecordRef; var FileNameWithoutExtension: Text; var FileNameExtension: Text; var Base64String: Text; TextLength: Integer)
    var
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        OutStream: OutStream;
        FullFileName: Text;
        OriginalPlainText: Text;
    begin
        FileNameWithoutExtension := LibraryUtility.GenerateGUID();
        FileNameExtension := LibraryUtility.GenerateGUID();
        OriginalPlainText := LibraryUtility.GenerateRandomXMLText(TextLength);
        Base64String := Base64Convert.ToBase64(OriginalPlainText);
        FullFileName := LibraryUtility.GenerateGUID() + '\' + FileNameWithoutExtension + '.' + FileNameExtension;

        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(OriginalPlainText);
        DocumentAttachment.SaveAttachment(RecRef, FullFileName, TempBlob);
    end;

    local procedure CreatePostSalesInvoice(var RecRef: RecordRef)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(CreatePostSalesDoc("Sales Document Type"::Invoice));
        RecRef.Get(SalesInvoiceHeader.RecordId);
        RecRef.SetRecFilter();
    end;

    local procedure CreatePostSalesCrMemo(var RecRef: RecordRef)
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.Get(CreatePostSalesDoc("Sales Document Type"::"Credit Memo"));
        RecRef.Get(SalesCrMemoHeader.RecordId);
        RecRef.SetRecFilter();
    end;

    local procedure CreatePostSalesDoc(DocumentType: Enum "Sales Document Type"): Code[20]
    begin
        exit(CreatePostSalesDocWithPmtData(DocumentType, CreatePaymentTerms(), CreatePaymentMethod()));
    end;

    local procedure CreatePostSalesDocWithPmtData(DocumentType: Enum "Sales Document Type"; PmtTermsCode: Code[10]; PmtMethodCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        SalesHeader.Validate("Payment Terms Code", PmtTermsCode);
        SalesHeader.Validate("Payment Method Code", PmtMethodCode);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        exit(
          LibraryITLocalization.CreateFatturaCustomerNo(
            CopyStr(LibraryUtility.GenerateRandomCode(Customer.FieldNo("PA Code"), DATABASE::Customer), 1, 6)));
    end;

    local procedure CreatePaymentMethod(): Code[10]
    begin
        exit(LibraryITLocalization.CreateFatturaPaymentMethodCode());
    end;

    local procedure CreatePaymentTerms(): Code[10]
    begin
        exit(LibraryITLocalization.CreateFatturaPaymentTermsCode());
    end;

    local procedure VerifySingleAttachment(TempBlob: Codeunit "Temp Blob"; Name: Text; Format: Text; Attachment: Text)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/Allegati');
        Assert.RecordCount(TempXMLBuffer, 1);
        VerifyAttachmentDetails(TempXMLBuffer, Name, Format, Attachment);
    end;

    local procedure VerifyTwoAttachments(TempBlob: Codeunit "Temp Blob"; Name: array[2] of Text; Format: array[2] of Text; Attachment: array[2] of Text)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        i: Integer;
    begin
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/Allegati');
        Assert.RecordCount(TempXMLBuffer, 2);
        for i := 1 to ArrayLen(Name) do begin
            VerifyAttachmentDetails(TempXMLBuffer, Name[i], Format[i], Attachment[i]);
            TempXMLBuffer.Next();
        end;
    end;

    local procedure VerifyAttachmentDetails(var XMLBuffer: Record "XML Buffer"; Name: Text; Format: Text; Attachment: Text)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        XMLBuffer.FindChildElements(TempXMLBuffer);
        AssertCurrentElementAndStepNext(TempXMLBuffer, 'NomeAttachment', Name);
        AssertCurrentElementAndStepNext(TempXMLBuffer, 'FormatoAttachment', Format);
        AssertCurrentElementAndStepNext(TempXMLBuffer, 'Attachment', Attachment);
    end;

    local procedure AssertCurrentElementAndStepNext(var XMLBuffer: Record "XML Buffer"; ExpectedName: Text; ExpectedValue: Text)
    var
        ActualValue: Text;
    begin
        Assert.AreEqual(
          ExpectedName, XMLBuffer.Name, StrSubstNo(UnexpectedElementNameErr, ExpectedName, XMLBuffer.GetElementName()));
        if StrLen(ExpectedValue) > MaxStrLen(XMLBuffer.Value) then
            ActualValue := XMLBuffer.GetValue()
        else
            ActualValue := XMLBuffer.Value;
        Assert.AreEqual(
          ExpectedValue, ActualValue, StrSubstNo(UnexpectedElementValueErr, ExpectedName, ExpectedValue, ActualValue));
        XMLBuffer.Next();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ErrorMessagesPageHandlerWithoutVerification(var ErrorMessages: TestPage "Error Messages")
    begin
        ErrorMessages.Close();
    end;
}

