codeunit 144206 "Self-Billing Documents"
{
    Subtype = Test;
    Permissions = tabledata "VAT Entry" = im;

    trigger OnRun()
    begin
        // [FEATURE] [FatturaPA] [Self-Billing] [Reverse Charge VAT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;
        UnexpectedElementNameErr: Label 'Unexpected element name. Expected element name: %1. Actual element name: %2.', Comment = '%1=Expetced XML Element Name;%2=Actual XML Element Name;';
        UnexpectedElementValueErr: Label 'Unexpected element value for element %1. Expected element value: %2. Actual element value: %3.', Comment = '%1=XML Element Name;%2=Expected XML Element Value;%3=Actual XML element Value;';
        MissingFatturaSetupQst: Label 'You must enter information on the Fattura Setup page before you can use the Fattura Electronic Document functionality.\\Do you want to open the page now?';
        MissingFatturaSetupErr: Label 'Required setup information is missing on the Fattura Setup page.';
        ReverseChargeVATDescrLbl: Label 'Reverse Charge VAT %1', Comment = '%1 = VAT percent';
        MultipleEntriesQst: Label 'There are multiple VAT entries for the selected document. Do you want to export all?';

    [Test]
    [Scope('OnPrem')]
    procedure UI_FatturaSetupFieldsVisible()
    var
        FatturaSetup: TestPage "Fattura Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 303491] A fields on Fattura Setup page are visible

        Initialize();
        LibraryApplicationArea.EnableBasicSetup();
        LibraryLowerPermissions.SetLocal();
        FatturaSetup.OpenEdit();
        Assert.IsTrue(FatturaSetup."Self-Billing VAT Bus. Group".Visible(), '');
        Assert.IsTrue(FatturaSetup."Company PA Code".Visible(), '');
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_FatturaDocTypeVisibleInSelfBillingDocumentsPage()
    var
        SelfBillingDocuments: TestPage "Self-Billing Documents";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 373967] "Fattura Document Type" field is visible in the "Self-Billing Documents" page

        Initialize();
        LibraryApplicationArea.EnableBasicSetup();
        LibraryLowerPermissions.SetLocal();
        LibraryLowerPermissions.AddeRead();
        SelfBillingDocuments.OpenEdit();
        Assert.IsTrue(SelfBillingDocuments."Fattura Document Type".Visible(), '');
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UI_ExportSelfBillingDocumentWithoutFatturaSetupThrowsConfirmation()
    var
        FatturaSetup: Record "Fattura Setup";
        SelfBillingDocuments: TestPage "Self-Billing Documents";
    begin
        // [FEAUTURE] [UI]
        // [SCENARIO 303491] Stan shows confirmation to update Fattura Setup if it is missing when export Self-Billing Document

        Initialize();

        // [GIVEN] Fattura Setup does not exist
        FatturaSetup.Get();
        FatturaSetup.Delete();
        LibraryVariableStorage.Enqueue(MissingFatturaSetupQst); // text of confirmation
        LibraryVariableStorage.Enqueue(false); // Reply confirmation
        LibraryLowerPermissions.SetLocal();

        // [GIVEN] Opened "Self-Billing Documents" page
        // [WHEN] Say no for confirmation "You need to provide information in Fattura Setup page to support Fattura electronic document functionality. Do you want to update it now?" which opends Fattura Setup page
        asserterror SelfBillingDocuments.OpenEdit();

        // [THEN] An error message "The needed information to support Fattura electronic document functionality is not provided in Fattura Setup page." thrown
        Assert.ExpectedError(MissingFatturaSetupErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,DoNotUpdateFatturaSetupWhenOpenModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_ExportSelfBillingDocumentWithoutFatturaSetupFailsIfNotSetup()
    var
        FatturaSetup: Record "Fattura Setup";
        SelfBillingDocuments: TestPage "Self-Billing Documents";
    begin
        // [FEAUTURE] [UI]
        // [SCENARIO 303491] Stan gets error message if he does not update Fattura Setup when export Self-Billing Document

        Initialize();

        // [GIVEN] Fattura Setup does not exist
        FatturaSetup.Get();
        FatturaSetup.Delete();
        LibraryVariableStorage.Enqueue(MissingFatturaSetupQst); // text of confirmation
        LibraryVariableStorage.Enqueue(true); // Reply confirmation
        LibraryLowerPermissions.SetLocal();

        // [GIVEN] Opened "Self-Billing Documents" page
        // [GIVEN] Say yes for confirmation "You need to provide information in Fattura Setup page to support Fattura electronic document functionality. Do you want to update it now?" which opends Fattura Setup page
        // [WHEN] Do nothing on Fattura Setup page, just close it
        asserterror SelfBillingDocuments.OpenEdit();

        // [THEN] An error message "The needed information to support Fattura electronic document functionality is not provided in Fattura Setup page." thrown
        Assert.ExpectedError(MissingFatturaSetupErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,UpdateFatturaSetupWhenOpenModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_SingleEntryOnSelfBillingDocumentPage()
    var
        FatturaSetup: Record "Fattura Setup";
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        SelfBillingDocuments: TestPage "Self-Billing Documents";
    begin
        // [FEAUTURE] [UI]
        // [SCENARIO 303491] Stan can see a Sales VAT Entry on Self-Billing Documents page posted from Purchase Document with Reverse Charge VAT

        Initialize();

        // [GIVEN] Posted Purchase Document with "Document No." = "X", "Reverse Charge VAT" and Amount = 100
        // [GIVEN] An additional Sales VAT Entry with "Document No." = "Y" was created
        CreatePurchDocument(PurchaseHeader);
        FindSalesVATEntryAdjacentToPurchase(VATEntry, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [GIVEN] Fattura Setup does not exist
        FatturaSetup.Get();
        FatturaSetup.Delete();
        LibraryVariableStorage.Enqueue(MissingFatturaSetupQst); // text of confirmation
        LibraryVariableStorage.Enqueue(true); // Reply confirmation
        LibraryVariableStorage.Enqueue(PurchaseHeader."VAT Bus. Posting Group");
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateRandomText(MaxStrLen(FatturaSetup."Company PA Code")));
        LibraryLowerPermissions.SetAccountPayables();
        LibraryLowerPermissions.AddLocal();

        // [GIVEN] Opened "Self-Billing Documents" page
        // [GIVEN] Say yes for confirmation "You need to provide information in Fattura Setup page to support Fattura electronic document functionality. Do you want to update it now?" which opends Fattura Setup page
        // [GIVEN] All required information updated through Fattura Setup page
        SelfBillingDocuments.OpenEdit();
        SelfBillingDocuments.DateFilter.SetValue(PurchaseHeader."Posting Date");

        // [WHEN] Set filter on "Document No." = "Y"
        SelfBillingDocuments.FILTER.SetFilter("Document No.", VATEntry."Document No.");

        // [THEN] A Sales VAT Entry exists on Self-Billing Documents page with Amount = 100
        SelfBillingDocuments.Amount.AssertEquals(VATEntry.Amount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,UpdateFatturaSetupWhenOpenModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleEntriesOnSelfBillingDocumentPage()
    var
        FatturaSetup: Record "Fattura Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        SelfBillingDocuments: TestPage "Self-Billing Documents";
    begin
        // [FEAUTURE] [UI]
        // [SCENARIO 303491] Stan can see multiple Sales VAT Entries on Self-Billing Documents page posted from Purchase Document with Reverse Charge VAT and different VAT Posting Groups

        Initialize();

        // [GIVEN] Posted Purchase Document with "Document No." = "X", "Reverse Charge VAT" with different VAT Groups and Amouns = 100 and 200 accordingly
        // [GIVEN] A two additional Sales VAT Entries with "Document No." = "Y" and Amount = 100 and 200 were created
        CreatePurchDocument(PurchaseHeader);
        CreateVATPostingSetup(VATPostingSetup);
        CreatePurchDocLine(PurchaseLine, PurchaseHeader, VATPostingSetup);
        FindSalesVATEntryAdjacentToPurchase(VATEntry, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [GIVEN] Fattura Setup does not exist
        FatturaSetup.Get();
        FatturaSetup.Delete();
        LibraryVariableStorage.Enqueue(MissingFatturaSetupQst); // text of confirmation
        LibraryVariableStorage.Enqueue(true); // Reply confirmation
        LibraryVariableStorage.Enqueue(PurchaseHeader."VAT Bus. Posting Group");
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateRandomText(MaxStrLen(FatturaSetup."Company PA Code")));
        LibraryLowerPermissions.SetAccountPayables();
        LibraryLowerPermissions.AddLocal();

        // [GIVEN] Opened "Self-Billing Documents" page
        // [GIVEN] Say yes for confirmation "You need to provide information in Fattura Setup page to support Fattura electronic document functionality. Do you want to update it now?" which opends Fattura Setup page
        // [GIVEN] All required information updated through Fattura Setup page
        SelfBillingDocuments.OpenEdit();
        SelfBillingDocuments.DateFilter.SetValue(PurchaseHeader."Posting Date");

        // [WHEN] Set filter on "Document No." = "Y"
        SelfBillingDocuments.FILTER.SetFilter("Document No.", VATEntry."Document No.");

        // [THEN] A Sales VAT Entry exists on Self-Billing Documents page with Amount = 100
        // [THEN] A Sales VAT Entry exists on Self-Billing Documents page with Amount = 100
        repeat
            SelfBillingDocuments.Amount.AssertEquals(VATEntry.Amount);
            SelfBillingDocuments.Next();
        until VATEntry.Next() = 0;

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSingleSelfBillingDocument()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Record "No. Series";
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        NoSeriesCodeunit: Codeunit "No. Series";
        ExportSelfBillingDocuments: Codeunit "Export Self-Billing Documents";
        ProgressiveNo: Code[20];
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [SCENARIO 303491] Stan can export a single Self-Billing Document

        Initialize();

        SalesReceivablesSetup.Get();
        NoSeries.Get(SalesReceivablesSetup."Fattura PA Nos.");
        ProgressiveNo := NoSeriesCodeunit.PeekNextNo(NoSeries.Code, Today());

        // [GIVEN] Posted Self-Billing Document
        CreatePurchDocument(PurchaseHeader);
        FindSalesVATEntryAdjacentToPurchase(VATEntry, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        LibraryLowerPermissions.SetAccountPayables();
        LibraryLowerPermissions.AddLocal();

        // [WHEN] Export posted Self-Billing Document to XML
        ExportSelfBillingDocuments.RunWithStreamSave(TempBlob, ClientFileName, VATEntry, VATEntry);

        // [THEN] The structure of single XML document for Self-Billing Document is correct
        // [THEN] (325589) Value for the ImportoTotaleDocumento tag is equal to sum VatEntry.Base and VatEntry.Amount without negative sign.
        // [THEN] (409700) Value for the DatiFattureCollegate tag is taken from the "External Document No." field of the purchase document
        VerifySingleSelfBillingDocument(TempBlob, ProgressiveNo, VATEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ExportSingleSelfBillingDocumentOfMultipleVATEntries()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Record "No. Series";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        TempSelectedVATEntry: Record "VAT Entry" temporary;
        TempAllVATEntry: Record "VAT Entry" temporary;
        ExportSelfBillingDocuments: Codeunit "Export Self-Billing Documents";
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        NoSeriesCodeunit: Codeunit "No. Series";
        ProgressiveNo: Code[20];
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [SCENARIO 303491] Stan can export a single Self-Billing Document contains multiple VAT Entries

        Initialize();

        SalesReceivablesSetup.Get();
        NoSeries.Get(SalesReceivablesSetup."Fattura PA Nos.");
        ProgressiveNo := NoSeriesCodeunit.PeekNextNo(NoSeries.Code, Today());

        // [GIVEN] Posted Self-Billing Document with two VAT Posting Groups which results in two created VAT Entries
        CreatePurchDocument(PurchaseHeader);
        CreateVATPostingSetup(VATPostingSetup);
        CreatePurchDocLine(PurchaseLine, PurchaseHeader, VATPostingSetup);

        FindSalesVATEntryAdjacentToPurchase(VATEntry, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        CopyVATEntryToTemp(TempSelectedVATEntry, VATEntry);
        FatturaDocHelper.BuildVATEntryBufferWithLinks(TempAllVATEntry, VATEntry);
        LibraryVariableStorage.Enqueue(MultipleEntriesQst);
        LibraryVariableStorage.Enqueue(true);
        LibraryLowerPermissions.SetAccountPayables();
        LibraryLowerPermissions.AddLocal();

        // [WHEN] Export posted Self-Billing Document to XML
        ExportSelfBillingDocuments.RunWithStreamSave(
          TempBlob, ClientFileName, TempSelectedVATEntry, TempAllVATEntry);

        // [THEN] The structure of XML document for single Self-Billing Document with two VAT entries is correct
        VerifySingleSelfBillingDocumentOfMultipleVATEntries(TempAllVATEntry, TempBlob, ProgressiveNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMultipleSelfBillingDocuments()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Record "No. Series";
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        TempVATEntry: Record "VAT Entry" temporary;
        ExportSelfBillingDocuments: Codeunit "Export Self-Billing Documents";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        ProgressiveNo: array[2] of Code[20];
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
        i: Integer;
    begin
        // [SCENARIO 303491] Stan can export multiple Self-Billing Documents

        Initialize();

        SalesReceivablesSetup.Get();
        NoSeries.Get(SalesReceivablesSetup."Fattura PA Nos.");

        // [GIVEN] Multiple Posted Self-Billing Documents
        for i := 1 to ArrayLen(ProgressiveNo) do begin
            CreatePurchDocument(PurchaseHeader);
            FindSalesVATEntryAdjacentToPurchase(VATEntry, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
            CopyVATEntryToTemp(TempVATEntry, VATEntry);
            VATEntry.Reset();
            ProgressiveNo[i] := NoSeriesBatch.GetNextNo(NoSeries.Code, Today());
        end;
        LibraryLowerPermissions.SetAccountPayables();
        LibraryLowerPermissions.AddLocal();

        // [WHEN] Export posted Self-Billing Documents to XML in one row
        ExportSelfBillingDocuments.RunWithStreamSave(
          TempBlob, ClientFileName, TempVATEntry, TempVATEntry);

        // [THEN] The zip archive contains two XML files, the structure of both is fine
        VerifyMultipleSelfBillingDocuments(TempVATEntry, TempBlob, ProgressiveNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSingleSelfBillingDocumentWithFatturaDocTypeFromVATEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ExportSelfBillingDocuments: Codeunit "Export Self-Billing Documents";
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [SCENARIO 373967] Stan can export a single Self-Billing Document with "Fattura Document Type" taken from VAT Entry

        Initialize();

        // [GIVEN] Posted Self-Billing Document with VAT Entry with "Fattura Document Type" = "X"
        // [GIVEN] Associated VAT Posting Setup has "Fattura Document Type" = "Y"
        CreatePurchDocument(PurchaseHeader);
        FindSalesVATEntryAdjacentToPurchase(VATEntry, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
        VATPostingSetup.Validate("Fattura Document Type", LibraryITLocalization.GetRandomFatturaDocType(''));
        VATPostingSetup.Modify(true);
        VATEntry."Fattura Document Type" := LibraryITLocalization.GetRandomFatturaDocType(VATPostingSetup."Fattura Document Type");
        VATEntry.Modify();
        LibraryLowerPermissions.SetAccountPayables();
        LibraryLowerPermissions.AddLocal();

        // [WHEN] Export posted Self-Billing Document to XML
        ExportSelfBillingDocuments.RunWithStreamSave(TempBlob, ClientFileName, VATEntry, VATEntry);

        // [THEN] TipoDocumento has value "X"
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiGeneraliDocumento');
        AssertElementValue(TempXMLBuffer, 'TipoDocumento', VATEntry."Fattura Document Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSingleSelfBillingDocumentWithFatturaDocTypeFromVATPostingSetup()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ExportSelfBillingDocuments: Codeunit "Export Self-Billing Documents";
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [SCENARIO 373967] Stan can export a single Self-Billing Document with "Fattura Document Type" taken from VAT Posting Setup

        Initialize();

        // [GIVEN] Posted Self-Billing Document with VAT Entry with blank "Fattura Document Type"
        // [GIVEN] Associated VAT Posting Setup has "Fattura Document Type" = "X"
        CreatePurchDocument(PurchaseHeader);
        FindSalesVATEntryAdjacentToPurchase(VATEntry, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
        VATPostingSetup.Validate("Fattura Document Type", LibraryITLocalization.GetRandomFatturaDocType(''));
        VATPostingSetup.Modify(true);
        LibraryLowerPermissions.SetAccountPayables();
        LibraryLowerPermissions.AddLocal();

        // [WHEN] Export posted Self-Billing Document to XML
        ExportSelfBillingDocuments.RunWithStreamSave(TempBlob, ClientFileName, VATEntry, VATEntry);

        // [THEN] TipoDocumento has value "X"
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiGeneraliDocumento');
        AssertElementValue(TempXMLBuffer, 'TipoDocumento', VATPostingSetup."Fattura Document Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSingleSelfBillingDocumentWithDefaultFatturaDocType()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ExportSelfBillingDocuments: Codeunit "Export Self-Billing Documents";
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [SCENARIO 373967] Stan can export a single Self-Billing Document with default "Fattura Document Type"

        Initialize();

        // [GIVEN] Posted Self-Billing Document with VAT Entry with blank "Fattura Document Type"
        // [GIVEN] Associated VAT Posting Setup has blank "Fattura Document Type"
        CreatePurchDocument(PurchaseHeader);
        FindSalesVATEntryAdjacentToPurchase(VATEntry, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        LibraryLowerPermissions.SetAccountPayables();
        LibraryLowerPermissions.AddLocal();

        // [WHEN] Export posted Self-Billing Document to XML
        ExportSelfBillingDocuments.RunWithStreamSave(TempBlob, ClientFileName, VATEntry, VATEntry);

        // [THEN] TipoDocumento has value "TD01"
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiGeneraliDocumento');
        AssertElementValue(TempXMLBuffer, 'TipoDocumento', FatturaDocHelper.GetDefaultFatturaDocType());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_UpdateSelfBillingDocumentFatturaDocTypeFromPage()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        SelfBillingDocuments: TestPage "Self-Billing Documents";
        FatturaDocType: Code[20];
    begin
        // [SCENARIO 373967] Stan can update the value of the "Fattura Document Type" in the "Self-Billing Documents" page

        Initialize();

        // [GIVEN] Posted Self-Billing Document with VAT Entry with blank "Fattura Document Type"
        CreatePurchDocument(PurchaseHeader);
        FindSalesVATEntryAdjacentToPurchase(VATEntry, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        LibraryApplicationArea.EnableBasicSetup();
        LibraryLowerPermissions.SetLocal();
        LibraryLowerPermissions.AddO365Setup();

        // [GIVEN] Opened Self-Billing Documents page filtered by posted VAT entry
        FatturaDocType := LibraryITLocalization.GetRandomFatturaDocType('');
        SelfBillingDocuments.OpenEdit();
        SelfBillingDocuments.FILTER.SetFilter("Bill-to/Pay-to No.", VATEntry."Bill-to/Pay-to No.");

        // [WHEN] Change "Fattura Document Type" to "X"
        SelfBillingDocuments."Fattura Document Type".SetValue(FatturaDocType);

        // [THEN] "Fattura Document Type" is "X" in the posted VAT Entry
        VATEntry.Find();
        VATEntry.TestField("Fattura Document Type", FatturaDocType);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetFatturaVendorNoInSelfBillingDocumentsPage()
    var
        VATEntry: Record "VAT Entry";
        SelfBillingDocuments: TestPage "Self-Billing Documents";
        VendNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 416695] Stan can set "Fattura Vendor No." in "Self-Billing Documents" page

        Initialize();
        MockSimpleVATEntryForSelfBillingDoc(VATEntry);

        LibraryApplicationArea.EnableBasicSetup();
        LibraryLowerPermissions.SetLocal();
        LibraryLowerPermissions.AddO365Setup();

        SelfBillingDocuments.OpenEdit();
        SelfBillingDocuments.GotoRecord(VATEntry);
        VendNo := LibraryPurchase.CreateVendorNo();
        SelfBillingDocuments."Fattura Vendor No.".SetValue(VendNo);
        SelfBillingDocuments.Close();
        VATEntry.Find();
        VATEntry.TestField("Fattura Vendor No.", VendNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSingleSelfBillingDocumentWithFatturaVendNo()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        Vendor: Record Vendor;
        ExportSelfBillingDocuments: Codeunit "Export Self-Billing Documents";
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [SCENARIO 303491] Stan can export a single Self-Billing Document with "Fattura Vendor No." setup

        Initialize();

        // [GIVEN] Vendor X
        MockFatturaVendor(Vendor);

        // [GIVEN] Posted Self-Billing Document
        CreatePurchDocument(PurchaseHeader);

        // [GIVEN] Set "Fattura Vendor No." equals "X" in VAT entry associated with the Self-Billing Document
        FindSalesVATEntryAdjacentToPurchase(VATEntry, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        VATEntry."Fattura Vendor No." := Vendor."No.";
        VATEntry.Modify();

        LibraryLowerPermissions.SetAccountPayables();
        LibraryLowerPermissions.AddLocal();

        // [WHEN] Export posted Self-Billing Document to XML
        ExportSelfBillingDocuments.RunWithStreamSave(TempBlob, ClientFileName, VATEntry, VATEntry);

        // [THEN] The structure of a single XML document with "Fattura Vendor No." for Self-Billing Document is correct
        VerifyFatturaVendorNoInformation(TempBlob, Vendor);
    end;

    [Test]
    procedure ExportSelfBillingDocumentWithCorrectCedentePrestatoreAndCessionarioCommittente()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        Vendor: Record Vendor;
        ExportSelfBillingDocuments: Codeunit "Export Self-Billing Documents";
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [SCENARIO 603844] Self-Billing Document export shows correct CedentePrestatore (vendor) and CessionarioCommittente (company) information.
        Initialize();

        // [GIVEN] Create new Fattura Vendor.
        MockFatturaVendor(Vendor);

        // [GIVEN] Create Purchase Document with Reverse Charge VAT and post it.
        CreatePurchDocument(PurchaseHeader);
        FindSalesVATEntryAdjacentToPurchase(VATEntry, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        VATEntry.Validate("Fattura Vendor No.", Vendor."No.");
        VATEntry.Modify(true);

        // [GIVEN] Set All necessary permisitions to export Self-Billing Document.
        LibraryLowerPermissions.SetAccountPayables();
        LibraryLowerPermissions.AddLocal();

        // [WHEN] Export posted Self-Billing Document to XML
        ExportSelfBillingDocuments.RunWithStreamSave(TempBlob, ClientFileName, VATEntry, VATEntry);

        // [THEN] CedentePrestatore contains vendor information and CessionarioCommittente contains company information
        VerifyCorrectCedenteAndCessionarioInformation(TempBlob, Vendor);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryITLocalization.SetupFatturaPA();
        InitFatturaSetup();
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Fattura Setup");
        IsInitialized := true;
    end;

    local procedure CreatePurchDocument(var PurchaseHeader: Record "Purchase Header")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
    begin
        CreateVATPostingSetup(VATPostingSetup);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        CreatePurchDocLine(PurchaseLine, PurchaseHeader, VATPostingSetup);
    end;

    local procedure CreatePurchDocLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        FatturaSetup: Record "Fattura Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATIdentifier: Record "VAT Identifier";
    begin
        FatturaSetup.Get();
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, FatturaSetup."Self-Billing VAT Bus. Group", VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(20));
        LibraryERM.CreateVATIdentifier(VATIdentifier);
        VATPostingSetup."VAT Identifier" := VATIdentifier.Code;
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure InitFatturaSetup()
    var
        FatturaSetup: Record "Fattura Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        FatturaSetup.Init();
        FatturaSetup."Self-Billing VAT Bus. Group" := VATBusinessPostingGroup.Code;
        FatturaSetup."Company PA Code" :=
          CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(FatturaSetup."Company PA Code")), 1, MaxStrLen(FatturaSetup."Company PA Code"));
        FatturaSetup.Insert();
    end;

    local procedure FindSalesVATEntryAdjacentToPurchase(var VATEntry: Record "VAT Entry"; DocNo: Code[20])
    begin
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.SetRange("VAT Calculation Type", VATEntry."VAT Calculation Type"::"Reverse Charge VAT");
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.FindFirst();
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        VATEntry.SetRange("Document No.");
        VATEntry.SetRange("Transaction No.", VATEntry."Transaction No.");
        VATEntry.FindSet();
    end;

    local procedure CopyVATEntryToTemp(var TempVATEntry: Record "VAT Entry" temporary; VATEntry: Record "VAT Entry")
    begin
        TempVATEntry := VATEntry;
        TempVATEntry.Insert();
    end;

    local procedure MockSimpleVATEntryForSelfBillingDoc(var VATEntry: Record "VAT Entry")
    var
        FatturaSetup: Record "Fattura Setup";
    begin
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry."Posting Date" := WorkDate();
        FatturaSetup.Get();
        VATEntry."VAT Bus. Posting Group" := FatturaSetup."Self-Billing VAT Bus. Group";
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."VAT Calculation Type" := VATEntry."VAT Calculation Type"::"Reverse Charge VAT";
        VATEntry."Document Type" := VATEntry."Document Type"::Invoice;
        VATEntry.Insert();
    end;

    local procedure MockFatturaVendor(var Vendor: Record Vendor)
    var
        CountryRegion: Record "Country/Region";
        PostCode: Record "Post Code";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Vendor."Country/Region Code" := CountryRegion.Code;
        Vendor."VAT Registration No." := LibraryUtility.GenerateGUID();
        Vendor.Address := LibraryUtility.GenerateGUID();
        LibraryERM.CreatePostCode(PostCode);
        Vendor."Post Code" := PostCode.Code;
        Vendor.City := PostCode.City;
        Vendor.Modify();
    end;

    local procedure FormatAmount(Amount: Decimal): Text[250]
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(Format(Amount, 0, TypeHelper.GetXMLAmountFormatWithTwoDecimalPlaces()));
    end;

    local procedure FormatDate(DateToFormat: Date): Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(Format(DateToFormat, 0, TypeHelper.GetXMLDateFormat()));
    end;

    local procedure AssertElementValue(var TempXMLBuffer: Record "XML Buffer" temporary; ElementName: Text; ElementValue: Text)
    begin
        FindNextElement(TempXMLBuffer);
        Assert.AreEqual(ElementName, TempXMLBuffer.GetElementName(),
          StrSubstNo(UnexpectedElementNameErr, ElementName, TempXMLBuffer.GetElementName()));
        Assert.AreEqual(ElementValue, TempXMLBuffer.Value,
          StrSubstNo(UnexpectedElementValueErr, ElementName, ElementValue, TempXMLBuffer.Value));
    end;

    local procedure FindNextElement(var TempXMLBuffer: Record "XML Buffer" temporary)
    begin
        if TempXMLBuffer.HasChildNodes() then
            TempXMLBuffer.FindChildElements(TempXMLBuffer)
        else
            if not (TempXMLBuffer.Next() > 0) then begin
                TempXMLBuffer.GetParent();
                TempXMLBuffer.SetRange("Parent Entry No.", TempXMLBuffer."Parent Entry No.");
                if not (TempXMLBuffer.Next() > 0) then
                    repeat
                        TempXMLBuffer.GetParent();
                        TempXMLBuffer.SetRange("Parent Entry No.", TempXMLBuffer."Parent Entry No.");
                    until (TempXMLBuffer.Next() > 0);
            end;
    end;

    local procedure VerifySingleSelfBillingDocument(TempBlob: Codeunit "Temp Blob"; ProgressiveNo: Code[20]; VATEntry: Record "VAT Entry")
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        VerifyHeader(TempXMLBuffer, ProgressiveNo);
        VATEntry.TestField(Amount);
        VATEntry.TestField(Base);
        VerifyDocHeader(TempXMLBuffer, VATEntry, Abs(VATEntry.Amount) + Abs(VATEntry.Base));
        VerifyDocLine(TempXMLBuffer, VATEntry, 1);
    end;

    local procedure VerifySingleSelfBillingDocumentFromStream(DocumentStream: InStream; ProgressiveNo: Code[20]; VATEntry: Record 254);
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempXMLBuffer.Load(DocumentStream);
        VerifyHeader(TempXMLBuffer, ProgressiveNo);
        VATEntry.TestField(Amount);
        VATEntry.TestField(Base);
        VerifyDocHeader(TempXMLBuffer, VATEntry, Abs(VATEntry.Amount) + Abs(VATEntry.Base));
        VerifyDocLine(TempXMLBuffer, VATEntry, 1);
    end;

    local procedure VerifySingleSelfBillingDocumentOfMultipleVATEntries(var TempVATEntry: Record "VAT Entry" temporary; TempBlob: Codeunit "Temp Blob"; ProgressiveNo: Code[20])
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        i: Integer;
    begin
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        VerifyHeader(TempXMLBuffer, ProgressiveNo);
        TempVATEntry.Reset();
        TempVATEntry.CalcSums(Amount, Base);
        TempVATEntry.TestField(Amount);
        TempVATEntry.TestField(Base);
        VerifyDocHeader(
          TempXMLBuffer, TempVATEntry, Abs(TempVATEntry.Amount) + Abs(TempVATEntry.Base));
        TempVATEntry.SetCurrentKey(
          "Document No.", Type, "VAT Bus. Posting Group", "VAT Prod. Posting Group",
          "VAT %", "Deductible %", "VAT Identifier", "Transaction No.", "Unrealized VAT Entry No.");
        TempVATEntry.FindSet();
        repeat
            i += 1;
            VerifyDocLine(TempXMLBuffer, TempVATEntry, i);
        until TempVATEntry.Next() = 0;
    end;

    local procedure VerifyMultipleSelfBillingDocuments(var TempVATEntry: Record "VAT Entry" temporary; TempBlob: Codeunit "Temp Blob"; ProgressiveNo: array[2] of Code[20])
    var
        FileManagement: Codeunit "File Management";
        DataCompression: Codeunit "Data Compression";
        ZipTempBlob: Codeunit "Temp Blob";
        EntryList: List of [Text];
        FirstFileInStream: InStream;
        SecondFileInStream: InStream;
        FirstFileOutStream: OutStream;
        SecondFileOutStream: OutStream;
    begin
        DataCompression.OpenZipArchive(TempBlob, false);
        DataCompression.GetEntryList(EntryList);

        // verify first file
        VerifyFileName(FileManagement.GetFileNameWithoutExtension(EntryList.Get(1)));
        ZipTempBlob.CreateOutStream(FirstFileOutStream);
        DataCompression.ExtractEntry(EntryList.Get(1), FirstFileOutStream);
        ZipTempBlob.CreateInStream(FirstFileInStream);
        TempVATEntry.Reset();
        TempVATEntry.FindSet();
        VerifySingleSelfBillingDocumentFromStream(FirstFileInStream, ProgressiveNo[1], TempVATEntry);

        // verify second file
        clear(ZipTempBlob);
        VerifyFileName(FileManagement.GetFileNameWithoutExtension(EntryList.Get(2)));
        ZipTempBlob.CreateOutStream(SecondFileOutStream);
        DataCompression.ExtractEntry(EntryList.Get(2), SecondFileOutStream);
        ZipTempBlob.CreateInStream(SecondFileInStream);
        TempVATEntry.Next();
        VerifySingleSelfBillingDocumentFromStream(SecondFileInStream, ProgressiveNo[2], TempVATEntry);

        DataCompression.CloseZipArchive();
    end;

    local procedure VerifyHeader(var TempXMLBuffer: Record "XML Buffer" temporary; ProgressiveNo: Code[20])
    var
        CompanyInformation: Record "Company Information";
        FatturaSetup: Record "Fattura Setup";
    begin
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaHeader/DatiTrasmissione/IdTrasmittente');
        CompanyInformation.Get();
        AssertElementValue(TempXMLBuffer, 'IdPaese', CompanyInformation."Country/Region Code");
        AssertElementValue(TempXMLBuffer, 'IdCodice', CompanyInformation."Fiscal Code");
        TempXMLBuffer.Reset();
        AssertElementValue(TempXMLBuffer, 'ProgressivoInvio', ProgressiveNo);
        AssertElementValue(TempXMLBuffer, 'FormatoTrasmissione', 'FPR12');
        FatturaSetup.Get();
        AssertElementValue(TempXMLBuffer, 'CodiceDestinatario', FatturaSetup."Company PA Code");

        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaHeader/CedentePrestatore/DatiAnagrafici/IdFiscaleIVA');
        AssertElementValue(TempXMLBuffer, 'IdPaese', CompanyInformation."Country/Region Code");
        AssertElementValue(TempXMLBuffer, 'IdCodice', CompanyInformation."VAT Registration No.");
        TempXMLBuffer.Reset();
        AssertElementValue(TempXMLBuffer, 'CodiceFiscale', CompanyInformation."Fiscal Code");
        TempXMLBuffer.Next();
        AssertElementValue(TempXMLBuffer, 'Denominazione', CompanyInformation.Name);
        AssertElementValue(TempXMLBuffer, 'RegimeFiscale', 'RF' + CompanyInformation."Company Type");

        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaHeader/CedentePrestatore/Sede');
        VerifyCompanyAddressInformation(TempXMLBuffer, CompanyInformation);

        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaHeader/CedentePrestatore/IscrizioneREA');
        AssertElementValue(TempXMLBuffer, 'Ufficio', CompanyInformation."Registry Office Province");
        AssertElementValue(TempXMLBuffer, 'NumeroREA', CompanyInformation."REA No.");
        AssertElementValue(TempXMLBuffer, 'CapitaleSociale', FormatAmount(CompanyInformation."Paid-In Capital"));
        AssertElementValue(TempXMLBuffer, 'SocioUnico', 'SM');
        AssertElementValue(TempXMLBuffer, 'StatoLiquidazione', 'LS');

        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaHeader/CedentePrestatore/Contatti');
        AssertElementValue(TempXMLBuffer, 'Telefono', DelChr(CompanyInformation."Phone No.", '=', '-'));
        AssertElementValue(TempXMLBuffer, 'Fax', DelChr(CompanyInformation."Fax No.", '=', '-'));
        AssertElementValue(TempXMLBuffer, 'Email', CompanyInformation."E-Mail");

        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaHeader/CessionarioCommittente/DatiAnagrafici/IdFiscaleIVA');
        AssertElementValue(TempXMLBuffer, 'IdPaese', CompanyInformation."Country/Region Code");
        AssertElementValue(TempXMLBuffer, 'IdCodice', CompanyInformation."VAT Registration No.");
        TempXMLBuffer.Reset();
        TempXMLBuffer.Next(); // skip CodiceFiscale
        TempXMLBuffer.Next(); // skip DatiAnagrafici
        AssertElementValue(TempXMLBuffer, 'Denominazione', CompanyInformation.Name);

        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaHeader/CedentePrestatore/Sede');
        VerifyCompanyAddressInformation(TempXMLBuffer, CompanyInformation);
    end;

    local procedure VerifyDocHeader(var TempXMLBuffer: Record "XML Buffer" temporary; VATEntry: Record "VAT Entry"; TotalAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiGeneraliDocumento');
        AssertElementValue(TempXMLBuffer, 'TipoDocumento', 'TD01');
        GeneralLedgerSetup.Get();
        AssertElementValue(TempXMLBuffer, 'Divisa', GeneralLedgerSetup."LCY Code");
        AssertElementValue(TempXMLBuffer, 'Data', FormatDate(VATEntry."Posting Date"));
        AssertElementValue(TempXMLBuffer, 'Numero', VATEntry."Document No.");
        AssertElementValue(TempXMLBuffer, 'ImportoTotaleDocumento', FormatAmount(TotalAmount));
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiFattureCollegate');
        AssertElementValue(TempXMLBuffer, 'IdDocumento', VATEntry."External Document No.");
    end;

    local procedure VerifyDocLine(var TempXMLBuffer: Record "XML Buffer" temporary; VATEntry: Record "VAT Entry"; LineNo: Integer)
    begin
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee');
        TempXMLBuffer.Next(LineNo - 1);
        AssertElementValue(TempXMLBuffer, 'NumeroLinea', Format(LineNo));
        AssertElementValue(TempXMLBuffer, 'Descrizione', StrSubstNo(ReverseChargeVATDescrLbl, VATEntry."VAT %"));
        AssertElementValue(TempXMLBuffer, 'Quantita', FormatAmount(1));
        AssertElementValue(TempXMLBuffer, 'PrezzoUnitario', FormatAmount(-VATEntry.Base));
        AssertElementValue(TempXMLBuffer, 'PrezzoTotale', FormatAmount(-VATEntry.Base));
        AssertElementValue(TempXMLBuffer, 'AliquotaIVA', FormatAmount(VATEntry."VAT %"));

        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DatiRiepilogo');
        TempXMLBuffer.Next(LineNo - 1);
        AssertElementValue(TempXMLBuffer, 'AliquotaIVA', FormatAmount(VATEntry."VAT %"));
        AssertElementValue(TempXMLBuffer, 'ImponibileImporto', FormatAmount(-VATEntry.Base));
        AssertElementValue(TempXMLBuffer, 'Imposta', FormatAmount(-VATEntry.Amount));
        AssertElementValue(TempXMLBuffer, 'EsigibilitaIVA', 'I');
    end;

    local procedure VerifyCompanyAddressInformation(var TempXMLBuffer: Record "XML Buffer" temporary; CompanyInformation: Record "Company Information")
    begin
        AssertElementValue(TempXMLBuffer, 'Indirizzo', CompanyInformation.Address);
        AssertElementValue(TempXMLBuffer, 'CAP', CompanyInformation."Post Code");
        AssertElementValue(TempXMLBuffer, 'Comune', CompanyInformation.City);
        AssertElementValue(TempXMLBuffer, 'Provincia', CompanyInformation.County);
        AssertElementValue(TempXMLBuffer, 'Nazione', CompanyInformation."Country/Region Code");
    end;

    local procedure VerifyFileName(ActualFileName: Text)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        // - country code + the transmitter's unique identity code + unique progressive number of the file
        Assert.IsTrue(StrPos(ActualFileName, (CompanyInformation."Country/Region Code" +
                                             CompanyInformation."Fiscal Code" + '_')) = 1, '');
    end;

    local procedure VerifyFatturaVendorNoInformation(TempBlob: Codeunit "Temp Blob"; Vendor: Record Vendor)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaHeader/CedentePrestatore');
        TempXMLBuffer.Reset();
        TempXMLBuffer.Next(); // <DatiAnagrafici
        TempXMLBuffer.Next(); // IdFiscaleIVA
        AssertElementValue(TempXMLBuffer, 'IdPaese', Vendor."Country/Region Code");
        AssertElementValue(TempXMLBuffer, 'IdCodice', Vendor."VAT Registration No.");
        TempXMLBuffer.Reset();
        TempXMLBuffer.Next(); // Anagrafica
        AssertElementValue(TempXMLBuffer, 'Denominazione', Vendor.Name);
        TempXMLBuffer.Reset();
        TempXMLBuffer.Next(); // Sede
        AssertElementValue(TempXMLBuffer, 'Indirizzo', Vendor.Address);
        AssertElementValue(TempXMLBuffer, 'CAP', '00000');
        AssertElementValue(TempXMLBuffer, 'Comune', Vendor.City);
        AssertElementValue(TempXMLBuffer, 'Nazione', Vendor."Country/Region Code");
    end;

    local procedure VerifyCorrectCedenteAndCessionarioInformation(TempBlob: Codeunit "Temp Blob"; Vendor: Record Vendor)
    var
        CompanyInformation: Record "Company Information";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        CompanyInformation.Get();
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);

        // Verify CedentePrestatore contains vendor information
        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaHeader/CedentePrestatore/DatiAnagrafici/IdFiscaleIVA');
        AssertElementValue(TempXMLBuffer, 'IdPaese', Vendor."Country/Region Code");
        AssertElementValue(TempXMLBuffer, 'IdCodice', Vendor."VAT Registration No.");
        TempXMLBuffer.Reset();
        TempXMLBuffer.Next(); // Anagrafica
        AssertElementValue(TempXMLBuffer, 'Denominazione', Vendor.Name);

        // Verify CessionarioCommittente contains company information
        TempXMLBuffer.FindNodesByXPath(
            TempXMLBuffer, '/p:FatturaElettronica/CessionarioCommittente/DatiAnagrafici/Anagrafica');
        TempXMLBuffer.Reset();
        AssertElementValue(TempXMLBuffer, 'Denominazione', CompanyInformation.Name);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.AreEqual(Question, LibraryVariableStorage.DequeueText(), '');
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DoNotUpdateFatturaSetupWhenOpenModalPageHandler(var FatturaSetup: TestPage "Fattura Setup")
    begin
        FatturaSetup.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UpdateFatturaSetupWhenOpenModalPageHandler(var FatturaSetup: TestPage "Fattura Setup")
    begin
        FatturaSetup."Self-Billing VAT Bus. Group".SetValue(LibraryVariableStorage.DequeueText());
        FatturaSetup."Company PA Code".SetValue(LibraryVariableStorage.DequeueText());
        FatturaSetup.OK().Invoke();
    end;
}

