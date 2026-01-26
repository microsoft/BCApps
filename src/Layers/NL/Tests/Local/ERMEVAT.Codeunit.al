codeunit 144051 "ERM EVAT"
{
    // // [FEATURE] [VAT] [VAT Statement]
    // 
    // 1. Verify Total VAT Amount when Round To Whole Numbers is true on VAT Statement report.
    // 2. Verify Total VAT Amount when Round To Whole Numbers is False on VAT Statement report.
    // 3. Verify Row does not exist on VAT Statement report when Print is false on VAT Statement Line.
    // 4. Verify Elec. Tax Declaration Line with Sign Calculation on VAT Statement Line.
    // 5. Verify Elec. Tax Declaration Line with Opposite Sign Calculation on VAT Statement Line.
    // 6. Verify Electronic Tax ICP Declaration does not show line for Amount Zero and its parent and sibling elements.
    // 
    // Covers Test Cases for WI - 343458
    // ----------------------------------------------------------------------------------------
    // Test Function Name                                                             TFS ID
    // ----------------------------------------------------------------------------------------
    // VATStatementLinePrintTrueRoundTrue                        171676,171668,171648,171646
    // VATStatementLinePrintTrueRoundFalse                                            171655
    // VATStatementLinePrintFalseRoundTrue                                     171675,171647
    // 
    // Covers Test Cases for WI - 343619
    // ---------------------------------------------------------------------------------------
    // Test Function Name                                                               TFS ID
    // ---------------------------------------------------------------------------------------
    // ElectronicTaxDeclarationCalculateWithOppositeSign                         171645,171660
    // ElectronicTaxDeclarationCalculateWithSign                                 171651,203643
    // 
    // Covers Test Cases for SE Merge Bug 104802
    // ---------------------------------------------------------------------------------------
    // Test Function Name                                                               TFS ID
    // ---------------------------------------------------------------------------------------
    // ICPCreateElecTaxDeclAmountZero

    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        NameValueBuffer: Record "Name/Value Buffer";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryNLLocalization: Codeunit "Library - NL Localization";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        TotalAmountCap: Label 'TotalAmount';
        RowMustNotExistsMsg: Label 'Row must not exists for Row No %1';
        VatStmtLineRowNoCap: Label 'VatStmtLineRowNo';
        ICPCannotExportErr: Label 'You cannot export a Elec. Tax Declaration Header of Declaration Type ICP';
        StatusMustBeCreatedErr: Label 'Status must be equal to ''Created''';
        CannotDeleteSubmittedErr: Label 'You cannot delete a Elec. Tax Declaration Header if Status is Submitted';
        DigipoortError: Label 'Cannot find the X.509 certificate using the following search criteria: StoreName ''My'', StoreLocation ''LocalMachine'', F';
        LibraryPermissions: Codeunit "Library - Permissions";
        FileMgt: Codeunit "File Management";
        LibraryXMLRead: Codeunit "Library - XML Read";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        AgentConAddressErr: Label 'Agent Contact Address must have a value in Elec. Tax Declaration Setup';
        SuppliesAmountZeroErr: Label 'Element %1 with Data zero exsits';
        SubElementErr: Label 'Element bd-ob-tuple:IntraCommunitySupplies should have 3 subelements';
        ParentElementErr: Label 'Parent of element %1 is wrong';
        XbrliXbrlTok: Label 'xbrli:xbrl';
        AttrBdTTok: Label 'xmlns:bd-t';
        AttrBdITok: Label 'xmlns:bd-i';
        AttrBdObTok: Label 'xmlns:bd-ob';
        DownloadSubmissionMessageQst: Label 'Do you want to download the submission message?';
        NoSubmissionMessageAvailableErr: Label 'The submission message of the report is not available.';
        BDDataEndpointTxt: Label 'https://www.nltaxonomie.nl/nt19/bd/20241211/dictionary/bd-data', Locked = true;
        VATDeclarationSchemaEndpointTxt: Label 'http://www.nltaxonomie.nl/nt19/bd/20241211/entrypoints/bd-rpt-ob-aangifte-2025.xsd', Locked = true;
        BDTuplesEndpointTxt: Label 'https://www.nltaxonomie.nl/nt19/bd/20241211/dictionary/bd-tuples', Locked = true;
        ICPDeclarationSchemaEndpointTxt: Label 'http://www.nltaxonomie.nl/nt19/bd/20241211/entrypoints/bd-rpt-icp-opgaaf-2025.xsd', Locked = true;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler,VATStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATStatementLinePrintTrueRoundTrue()
    var
        RowNo: Code[10];
    begin
        // Verify Total VAT Amount when Round To Whole Numbers is true on VAT Statement report.

        // Setup & Exercise.
        Initialize();
        RowNo := CreateElecVATDeclAndRunVATStatementReport(true, true);  // True for 'Round To Whole Amount' on VAT Statement report and Print on VAT Statement Line.

        // Verify: Verify Total VAT Amount on VAT Statement report.
        FindRowOnVATStatementReport(RowNo);
        LibraryReportDataset.AssertCurrentRowValueEquals(TotalAmountCap, Round(CalculateVATAmount(), 1, '<'));  // Taken 1 for Precision and '<' for Direction.
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler,VATStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATStatementLinePrintTrueRoundFalse()
    var
        RowNo: Code[10];
    begin
        // Verify Total VAT Amount when Round To Whole Numbers is False on VAT Statement report.

        // Setup & Exercise.
        Initialize();
        RowNo := CreateElecVATDeclAndRunVATStatementReport(false, true);  // False for 'Round To Whole Amount' on VAT Statement report and True for Print on VAT Statement Line.

        // Verify: Verify Total VAT Amount on VAT Statement report.
        FindRowOnVATStatementReport(RowNo);
        LibraryReportDataset.AssertCurrentRowValueEquals(TotalAmountCap, CalculateVATAmount());
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler,VATStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATStatementLinePrintFalseRoundTrue()
    var
        RowNo: Code[10];
    begin
        // Verify Row does not exist on VAT Statement report when Print is false on VAT Statement Line.

        // Setup & Exercise.
        Initialize();
        RowNo := CreateElecVATDeclAndRunVATStatementReport(true, false);  // True for 'Round To Whole Amount' on VAT Statement report and false for Print on VAT Statement Line.

        // Verify: Verify Row does not exist on VAT Statement report.
        Assert.IsFalse(FindRowOnVATStatementReport(RowNo), StrSubstNo(RowMustNotExistsMsg, RowNo));
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ElectronicTaxDeclarationCalculateWithOppositeSign()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Verify Elec. Tax Declaration Line with Opposite Sign Calculation on VAT Statement Line.
        CreateElectronicTaxDeclarationWithVAT(VATStatementLine."Calculate with"::"Opposite Sign");
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ElectronicTaxDeclarationCalculateWithSign()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Verify Elec. Tax Declaration Line with Sign Calculation on VAT Statement Line.
        CreateElectronicTaxDeclarationWithVAT(VATStatementLine."Calculate with"::Sign);
    end;

    local procedure CreateElectronicTaxDeclarationWithVAT(CalculateWith: Option)
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        No: Code[20];
    begin
        // Setup: Create and Post General Journal Line. Create and modify Elec. Tax Declaration Header and VAT Statement Line.
        Initialize();
        VATStatementName.FindFirst();
        CreateAndPostGeneralJnlLine(GenJournalLine, GenJournalLine."Document Type"::" ", '<-3M>');
        CreateAndModifyVATStatementLineWithAccountTotaling(
          VATStatementName, LibraryUtility.GenerateGUID(), VATStatementLine.Type::"Account Totaling",
          GenJournalLine."Account No.", CalculateWith);

        // Enqueue for CreateElecVATDeclarationRequestPageHandler.
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        LibraryVariableStorage.Enqueue(VATStatementName.Name);

        // Exercise: Create Electronic Tax Declaration from Elec. Tax Declaration Page.
        No := CreateElectronicTaxDeclaration(ElecTaxDeclarationHeader."Declaration Type"::"VAT Declaration");

        // Verify: Verify values of Voorbelasting on Elec. Tax Declaration Line.
        VerifyElecTaxDeclarationLine(No, 'bd-i:ValueAddedTaxOnInput', Format(CalculateVATAmount() div 1));
    end;

    [Test]
    [HandlerFunctions('CreateElecICPDeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ICPSubmitSubmittedDeclError()
    var
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
    begin
        ICPSubmitDeclWrongStatusHelper(ElecTaxDeclHeader.Status::Submitted);
    end;

    [Test]
    [HandlerFunctions('CreateElecICPDeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ICPSubmitAcknowledgedDeclError()
    var
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
    begin
        ICPSubmitDeclWrongStatusHelper(ElecTaxDeclHeader.Status::Acknowledged);
    end;

    local procedure ICPSubmitDeclWrongStatusHelper(NewStatus: Option)
    var
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
        VATEntry: Record "VAT Entry";
        ElecTaxDeclCard: TestPage "Elec. Tax Declaration Card";
        No: Code[20];
    begin
        // Setup & Exercise.
        Initialize();
        InitializeElecTaxDeclSetup(true, false);
        CreateReverseChargeSalesInvoiceVATEntry(VATEntry, false, false);
        No := CreateElectronicTaxDeclaration(ElecTaxDeclHeader."Declaration Type"::"ICP Declaration");
        ElecTaxDeclHeader.Get(ElecTaxDeclHeader."Declaration Type"::"ICP Declaration", No);
        ElecTaxDeclHeader.Status := NewStatus;
        ElecTaxDeclHeader.Modify();

        // Exercise: Submit a declaration with NewStatus
        ElecTaxDeclCard.OpenEdit();
        ElecTaxDeclCard.FILTER.SetFilter("No.", No);
        asserterror ElecTaxDeclCard.SubmitElectronicTaxDeclaration.Invoke();
        ElecTaxDeclCard.Close();

        Assert.ExpectedError(StatusMustBeCreatedErr);
    end;

    [Test]
    [HandlerFunctions('CreateElecICPDeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ICPEmptyDeclError()
    var
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclLine: Record "Elec. Tax Declaration Line";
        ElecTaxDeclCard: TestPage "Elec. Tax Declaration Card";
        No: Code[20];
    begin
        // Setup & Exercise: Create ICP declaration and remove required elements to trigger error
        Initialize();
        InitializeElecTaxDeclSetup(true, false);
        No := CreateElectronicTaxDeclaration(ElecTaxDeclHeader."Declaration Type"::"ICP Declaration");
        ElecTaxDeclLine.SetRange("Declaration Type", ElecTaxDeclHeader."Declaration Type"::"ICP Declaration");
        ElecTaxDeclLine.SetRange("Declaration No.", No);
        ElecTaxDeclLine.SetRange("Line Type", ElecTaxDeclLine."Line Type"::Element);
        ElecTaxDeclLine.SetFilter(Name, '%1|%2|%3', 'bd-t:IntraCommunitySupplies', 'bd-t:IntraCommunityServices',
          'bd-t:IntraCommunityABCSupplies');

        if ElecTaxDeclLine.Find('-') then
            repeat
                ElecTaxDeclHeader.DeleteLine(ElecTaxDeclLine);
            until ElecTaxDeclLine.Next() = 0;

        // Exercise: Attempt to submit an empty report
        ElecTaxDeclCard.OpenEdit();
        ElecTaxDeclCard.FILTER.SetFilter("No.", No);
        asserterror ElecTaxDeclCard.SubmitElectronicTaxDeclaration.Invoke();
        ElecTaxDeclCard.Close();

        // Verify
        Assert.ExpectedError(ICPCannotExportErr);
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATSubmitSubmittedDeclError()
    var
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
    begin
        VATSubmitDeclWrongStatusHelper(ElecTaxDeclHeader.Status::Submitted);
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATSubmitAcknowledgedDeclError()
    var
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
    begin
        VATSubmitDeclWrongStatusHelper(ElecTaxDeclHeader.Status::Acknowledged);
    end;

    local procedure VATSubmitDeclWrongStatusHelper(NewStatus: Option)
    var
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
        VATStatementName: Record "VAT Statement Name";
        ElecTaxDeclCard: TestPage "Elec. Tax Declaration Card";
        No: Code[20];
    begin
        // Setup
        Initialize();

        // Enqueue for CreateElecVATDeclarationRequestPageHandler.
        VATStatementName.FindFirst();
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        LibraryVariableStorage.Enqueue(VATStatementName.Name);

        // Exercise.
        No := CreateElectronicTaxDeclaration(ElecTaxDeclHeader."Declaration Type"::"VAT Declaration");
        ElecTaxDeclHeader.Get(ElecTaxDeclHeader."Declaration Type"::"VAT Declaration", No);
        ElecTaxDeclHeader.Status := NewStatus;
        ElecTaxDeclHeader.Modify();

        // Exercise: Submit a declaration with status=NewStatus
        ElecTaxDeclCard.OpenEdit();
        ElecTaxDeclCard.FILTER.SetFilter("No.", No);
        asserterror ElecTaxDeclCard.SubmitElectronicTaxDeclaration.Invoke();
        ElecTaxDeclCard.Close();

        Assert.ExpectedError(StatusMustBeCreatedErr);
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VATDuplicateDeclForPeriodSubmitted()
    var
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
    begin
        VATDuplicateDeclForPeriodHelper(ElecTaxDeclHeader.Status::Submitted);
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VATDuplicateDeclForPeriodAcknowledged()
    var
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
    begin
        VATDuplicateDeclForPeriodHelper(ElecTaxDeclHeader.Status::Acknowledged);
    end;

    local procedure VATDuplicateDeclForPeriodHelper(NewStatus: Option)
    var
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
        VATStatementName: Record "VAT Statement Name";
        No: Code[20];
    begin
        // Setup
        Initialize();

        // Enqueue for CreateElecVATDeclarationRequestPageHandler.
        VATStatementName.FindFirst();
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        LibraryVariableStorage.Enqueue(VATStatementName.Name);

        // Exercise.
        No := CreateElectronicTaxDeclaration(ElecTaxDeclHeader."Declaration Type"::"VAT Declaration");
        ElecTaxDeclHeader.Get(ElecTaxDeclHeader."Declaration Type"::"VAT Declaration", No);
        ElecTaxDeclHeader.Status := NewStatus;
        ElecTaxDeclHeader.Modify();

        // Enqueue for CreateElecVATDeclarationRequestPageHandler.
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        LibraryVariableStorage.Enqueue(VATStatementName.Name);

        // Verify: A warning is shown when trying to create a duplicate declaration for a period
        asserterror CreateElectronicTaxDeclaration(ElecTaxDeclHeader."Declaration Type"::"VAT Declaration");
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATDeleteSubmitedError()
    var
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
        VATStatementName: Record "VAT Statement Name";
        No: Code[20];
    begin
        // Setup
        Initialize();

        // Enqueue for CreateElecVATDeclarationRequestPageHandler.
        VATStatementName.FindFirst();
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        LibraryVariableStorage.Enqueue(VATStatementName.Name);

        // Exercise: Create declaration, change status and try to delete
        No := CreateElectronicTaxDeclaration(ElecTaxDeclHeader."Declaration Type"::"VAT Declaration");
        ElecTaxDeclHeader.Get(ElecTaxDeclHeader."Declaration Type"::"VAT Declaration", No);
        ElecTaxDeclHeader.Status := ElecTaxDeclHeader.Status::Submitted;
        ElecTaxDeclHeader.Modify();
        asserterror ElecTaxDeclHeader.Delete(true);

        // Verify: Error is shown
        Assert.ExpectedError(CannotDeleteSubmittedErr);
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATAcknowledgedAfterNonErrResp()
    var
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclRespMsg: Record "Elec. Tax Decl. Response Msg.";
        VATStatementName: Record "VAT Statement Name";
        ElecTaxDeclRespMsgPage: TestPage "Elec. Tax Decl. Response Msgs.";
        No: Code[20];
        NextNo: Integer;
    begin
        // Setup
        Initialize();

        // Enqueue for CreateElecVATDeclarationRequestPageHandler.
        VATStatementName.FindFirst();
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        LibraryVariableStorage.Enqueue(VATStatementName.Name);

        No := CreateElectronicTaxDeclaration(ElecTaxDeclHeader."Declaration Type"::"VAT Declaration");
        ElecTaxDeclHeader.Get(ElecTaxDeclHeader."Declaration Type"::"VAT Declaration", No);
        ElecTaxDeclHeader.Status := ElecTaxDeclHeader.Status::Submitted;
        ElecTaxDeclHeader."Message ID" := LibraryUtility.GenerateGUID();
        ElecTaxDeclHeader.Modify();

        // Insert dummy response message into response table
        ElecTaxDeclRespMsg.Reset();
        ElecTaxDeclRespMsg."No." := 0;
        if not ElecTaxDeclRespMsg.FindLast() then;
        NextNo := ElecTaxDeclRespMsg."No." + 1;

        CreateResponseMessage(NextNo, '105', 'Aanleverproces gestart', ElecTaxDeclHeader);
        CreateResponseMessage(NextNo, '100', 'Aanleveren gelukt.', ElecTaxDeclHeader);

        // Exercise: Process "received" response messages
        ElecTaxDeclRespMsgPage.OpenEdit();
        ElecTaxDeclRespMsgPage.FILTER.SetFilter("Declaration Type", Format(ElecTaxDeclHeader."Declaration Type"));
        ElecTaxDeclRespMsgPage.FILTER.SetFilter("Declaration No.", Format(ElecTaxDeclHeader."No."));
        ElecTaxDeclRespMsgPage.ProcessResponseMessages.Invoke();
        ElecTaxDeclRespMsgPage.Close();

        // Verify: Status is changed to acknowledged
        ElecTaxDeclHeader.Get(ElecTaxDeclHeader."Declaration Type"::"VAT Declaration", No);
        Assert.AreEqual(Format(ElecTaxDeclHeader.Status::Acknowledged), Format(ElecTaxDeclHeader.Status), '');
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATErrorAfterErrResp()
    var
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclRespMsg: Record "Elec. Tax Decl. Response Msg.";
        VATStatementName: Record "VAT Statement Name";
        ElecTaxDeclErrorLog: Record "Elec. Tax Decl. Error Log";
        ElecTaxDeclRespMsgPage: TestPage "Elec. Tax Decl. Response Msgs.";
        No: Code[20];
        NextNo: Integer;
        MsgNo: Integer;
        XmlFile: Text;
    begin
        // Setup
        Initialize();

        // Enqueue for CreateElecVATDeclarationRequestPageHandler.
        VATStatementName.FindFirst();
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        LibraryVariableStorage.Enqueue(VATStatementName.Name);

        No := CreateElectronicTaxDeclaration(ElecTaxDeclHeader."Declaration Type"::"VAT Declaration");
        ElecTaxDeclHeader.Get(ElecTaxDeclHeader."Declaration Type"::"VAT Declaration", No);
        ElecTaxDeclHeader.Status := ElecTaxDeclHeader.Status::Submitted;
        ElecTaxDeclHeader."Message ID" := LibraryUtility.GenerateGUID();
        ElecTaxDeclHeader.Modify();

        // Insert dummy response message into response table
        ElecTaxDeclRespMsg.Reset();
        ElecTaxDeclRespMsg."No." := 0;
        if not ElecTaxDeclRespMsg.FindLast() then;
        NextNo := ElecTaxDeclRespMsg."No." + 1;

        CreateResponseMessage(NextNo, '105', 'Aanleverproces gestart', ElecTaxDeclHeader);
        CreateResponseMessage(NextNo, '100', 'Aanleveren gelukt.', ElecTaxDeclHeader);
        MsgNo := CreateResponseMessage(NextNo, '311', 'Aanleveren gelukt.', ElecTaxDeclHeader);

        XmlFile := BuildDigipoortErrorXml();
        ElecTaxDeclRespMsg.Get(MsgNo);
        ElecTaxDeclRespMsg.Message.Import(XmlFile);
        ElecTaxDeclRespMsg.Modify(true);

        ElecTaxDeclErrorLog.SetRange("Declaration Type", ElecTaxDeclHeader."Declaration Type");
        ElecTaxDeclErrorLog.SetRange("Declaration No.", ElecTaxDeclHeader."No.");
        Assert.AreEqual(0, ElecTaxDeclErrorLog.Count, '');

        // Exercise: Process "received" response messages
        ElecTaxDeclRespMsgPage.OpenEdit();
        ElecTaxDeclRespMsgPage.FILTER.SetFilter("Declaration Type", Format(ElecTaxDeclHeader."Declaration Type"));
        ElecTaxDeclRespMsgPage.FILTER.SetFilter("Declaration No.", Format(ElecTaxDeclHeader."No."));
        ElecTaxDeclRespMsgPage.ProcessResponseMessages.Invoke();
        ElecTaxDeclRespMsgPage.Close();

        // Verify: Status is changed to error and erros are added to error log
        ElecTaxDeclHeader.Get(ElecTaxDeclHeader."Declaration Type"::"VAT Declaration", No);
        Assert.AreEqual(Format(ElecTaxDeclHeader.Status::Error), Format(ElecTaxDeclHeader.Status), '');
        Assert.AreEqual(3, ElecTaxDeclErrorLog.Count, '');
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DigipoortWrongCertificates()
    var
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclSetup: Record "Elec. Tax Declaration Setup";
        VATStatementName: Record "VAT Statement Name";
        ElecTaxDeclCard: TestPage "Elec. Tax Declaration Card";
        No: Code[20];
    begin
        // Purpose: Verify an error is shown if no certificate name is supplied during setup
        Initialize();

        // Setup
        ElecTaxDeclSetup.Get();
        ElecTaxDeclSetup."Digipoort Client Cert. Name" := 'abcdefg';
        ElecTaxDeclSetup."Digipoort Service Cert. Name" := 'qwerty';
        ElecTaxDeclSetup."Digipoort Delivery URL" := 'http://testurl';
        ElecTaxDeclSetup."Digipoort Status URL" := 'http://testurl';
        ElecTaxDeclSetup.Modify();

        VATStatementName.FindFirst();
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        LibraryVariableStorage.Enqueue(VATStatementName.Name);
        No := CreateElectronicTaxDeclaration(ElecTaxDeclHeader."Declaration Type"::"VAT Declaration");

        // Exercise: Try to submit
        ElecTaxDeclCard.OpenEdit();
        ElecTaxDeclCard.FILTER.SetFilter("No.", No);
        asserterror ElecTaxDeclCard.SubmitElectronicTaxDeclaration.Invoke();
        ElecTaxDeclCard.Close();

        // Verify: An exception is thrown by Digipoort add-in
        Assert.ExpectedError(DigipoortError);
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATXBRLDocVerify()
    var
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
        VATStatementName: Record "VAT Statement Name";
        No: Code[20];
        TempFile: Text;
    begin
        // [SCENARIO] Verify XBLR document content for Tax Declaration with type "VAT Declaration"
        // [SCENARIO 261086] The attribute "xmlns:bd-ob" does not exist in XBLR document for Tax Declaration with type "VAT Declaration"

        Initialize();

        // [GIVEN] Electronic Tax Declaration with type = "VAT Declaration"
        InitializeElecTaxDeclSetup(false, false);
        // TFS ID 398781: Stan can submit electronic tax declaration with the "Use Certificate Setup" option enabled
        EnableUseCertificateSetupOption();

        VATStatementName.FindFirst();
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        LibraryVariableStorage.Enqueue(VATStatementName.Name);
        No := CreateElectronicTaxDeclaration(ElecTaxDeclHeader."Declaration Type"::"VAT Declaration");
        ElecTaxDeclHeader.Get(ElecTaxDeclHeader."Declaration Type"::"VAT Declaration", No);

        // [WHEN] Generate XBLR for Tax Declaration
        TempFile := BuildDeclarationDocumentPreview(ElecTaxDeclHeader);

        // [THEN] XBLR content generats correctly for Tax Declaration
        // [THEN] "xmlns:bd-ob" attribute does not exists in XBLR content
        // Work item id 503180: NT18 Changes
        // [THEN] Endpoints are of nt18 version
        VerifyVATXBLRDocContent(ElecTaxDeclHeader, TempFile);
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATXBRLDocVerifyAgent()
    var
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
        VATStatementName: Record "VAT Statement Name";
        No: Code[20];
        TempFile: Text;
    begin
        // Purpose: Verify XBLR document content
        Initialize();

        // Setup
        InitializeElecTaxDeclSetup(true, false);
        VATStatementName.FindFirst();
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        LibraryVariableStorage.Enqueue(VATStatementName.Name);
        No := CreateElectronicTaxDeclaration(ElecTaxDeclHeader."Declaration Type"::"VAT Declaration");
        ElecTaxDeclHeader.Get(ElecTaxDeclHeader."Declaration Type"::"VAT Declaration", No);

        // Exercise
        TempFile := BuildDeclarationDocumentPreview(ElecTaxDeclHeader);

        // Verify
        VerifyVATXBLRDocContent(ElecTaxDeclHeader, TempFile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATXBRLDocAgentMissData()
    var
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
        VATStatementName: Record "VAT Statement Name";
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // Purpose: Verify an error is shown if the agent information is not filled out correctly.
        Initialize();

        // Setup
        InitializeElecTaxDeclSetup(true, false);
        ElecTaxDeclarationSetup.Get();
        ElecTaxDeclarationSetup."Agent Contact Address" := '';
        ElecTaxDeclarationSetup.Modify();

        VATStatementName.FindFirst();
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        LibraryVariableStorage.Enqueue(VATStatementName.Name);
        asserterror CreateElectronicTaxDeclaration(ElecTaxDeclHeader."Declaration Type"::"VAT Declaration");

        // Verify
        Assert.ExpectedError(AgentConAddressErr);
    end;

    [Test]
    [HandlerFunctions('CreateElecICPDeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ICPXBRLDocVerify()
    var
        VATEntry: array[6] of Record "VAT Entry";
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
        No: Code[20];
        TempFile: Text;
    begin
        // [SCENARIO] XBLR content of the ICP declaration is correct
        Initialize();

        InitializeElecTaxDeclSetup(false, false);
        // [GIVEN] Grouping by VAT Reg No. and country region code
        CreateReverseChargeSalesInvoiceVATEntry(VATEntry[1], false, false);
        CreateReverseChargeSalesInvoiceVATEntry(VATEntry[2], false, false);
        VATEntry[2]."VAT Registration No." := VATEntry[1]."VAT Registration No.";
        VATEntry[2]."Country/Region Code" := VATEntry[1]."Country/Region Code";
        VATEntry[2].Modify();

        // [GIVEN] No grouping between EU Trade and service entries but same VAT reg no. and country code
        CreateReverseChargeSalesInvoiceVATEntry(VATEntry[3], true, false);
        VATEntry[3]."VAT Registration No." := VATEntry[1]."VAT Registration No.";
        VATEntry[3]."Country/Region Code" := VATEntry[1]."Country/Region Code";
        VATEntry[3].Modify();
        CreateReverseChargeSalesInvoiceVATEntry(VATEntry[4], true, false);

        CreateReverseChargeSalesInvoiceVATEntry(VATEntry[5], false, true);
        CreateReverseChargeSalesInvoiceVATEntry(VATEntry[6], true, true);

        No := CreateElectronicTaxDeclaration(ElecTaxDeclHeader."Declaration Type"::"ICP Declaration");
        ElecTaxDeclHeader.Get(ElecTaxDeclHeader."Declaration Type"::"ICP Declaration", No);

        // [WHEN] Generate ICP declaration
        TempFile := BuildDeclarationDocumentPreview(ElecTaxDeclHeader);

        // [THEN] The XBRL structure is correct
        // Work item id 503180: NT18 Changes
        // [THEN] Endpoints are of nt18 version
        VerifyICPXBLRDocContent(ElecTaxDeclHeader, TempFile);
        VATEntry[1].Base += VATEntry[2].Base;
        VerifyICPVATEntry(VATEntry[1]);
        VerifyICPVATEntry(VATEntry[3]);
        VerifyICPVATEntry(VATEntry[4]);
        VerifyICPVATEntry(VATEntry[5]);
        VerifyICPVATEntry(VATEntry[6]);
    end;

    [Test]
    [HandlerFunctions('CreateElecICPDeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ICPCreateElecTaxDeclAmountZero()
    var
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclLine: Record "Elec. Tax Declaration Line";
        ElecTaxDeclHeaderNo: Code[20];
    begin
        // Verify Electronic Tax ICP Declaration does not show line for Amount Zero and its parent and sibling elements.

        // Setup: Create a Reverse Charge Sales Invoice VAT Entry with base amount greater than 0 and less than 1.
        Initialize();
        CreateSalesInvoiceVATEntry();

        // Exercise: Create Electronic Tax ICP Declaration.
        ElecTaxDeclHeaderNo := CreateElectronicTaxDeclaration(ElecTaxDeclHeader."Declaration Type"::"ICP Declaration");

        // Verify: Element bd-ob:SuppliesAmount has no Data Zero.
        FilterOnElecTaxDeclLine(
          ElecTaxDeclLine, ElecTaxDeclLine."Declaration Type"::"ICP Declaration", ElecTaxDeclHeaderNo,
          ElecTaxDeclLine."Line Type"::Element, 'bd-ob:SuppliesAmount');
        VerifyNoZeroAmount(ElecTaxDeclLine);

        // Verify: Element bd-ob-tuple:IntraCommunitySupplies, bd-ob:CountryCodeISO-EC and bd-ob:VATIdentificationNumberNational
        // always appear together with element bd-ob:SuppliesAmount.
        VerifySubElementCount(ElecTaxDeclLine);
        VerifyParentElement(ElecTaxDeclLine, 'bd-ob:CountryCodeISO-EC');
        VerifyParentElement(ElecTaxDeclLine, 'bd-ob:SuppliesAmount');
        VerifyParentElement(ElecTaxDeclLine, 'bd-ob:VATIdentificationNumberNational');
    end;

    local procedure BuildDeclarationDocumentPreview(ElecTaxDeclheader: Record "Elec. Tax Declaration Header") TempFile: Text
    var
        SubmitReport: Report "Submit Elec. Tax Declaration";
    begin
        TempFile := FileMgt.ServerTempFileName('xbrl');
        ElecTaxDeclheader.SetRecFilter();
        SubmitReport.PreviewOnly(TempFile);
        SubmitReport.UseRequestPage := false;
        SubmitReport.SetTableView(ElecTaxDeclheader);
        SubmitReport.RunModal();
    end;

    local procedure VerifyVATXBLRDocContent(var ElecTaxDeclHeader: Record "Elec. Tax Declaration Header"; Filename: Text)
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        CompanyInfo: Record "Company Information";
        UseVATRegNo: Text[30];
        NodeList: List of [Text];
        Node: Text;
    begin
        ElecTaxDeclarationSetup.Get();
        CompanyInfo.Get();
        if ElecTaxDeclarationSetup."Part of Fiscal Entity" then
            UseVATRegNo := CompanyInfo."Fiscal Entity No."
        else
            UseVATRegNo := CompanyInfo."VAT Registration No.";
        if CopyStr(UpperCase(UseVATRegNo), 1, 2) = 'NL' then
            UseVATRegNo := DelStr(UseVATRegNo, 1, 2);

        LibraryXMLRead.Initialize(Filename);
        LibraryXMLRead.VerifyAttributeAbsence(XbrliXbrlTok, AttrBdObTok);
        LibraryXMLRead.VerifyAttributeValue(XbrliXbrlTok, AttrBdITok, BDDataEndpointTxt);
        LibraryXMLRead.VerifyAttributeValueInSubtree(
          XbrliXbrlTok, 'link:schemaRef', 'xlink:href', VATDeclarationSchemaEndpointTxt);
        LibraryXMLRead.VerifyNodeValueInSubtree('xbrli:context', 'xbrli:identifier', UseVATRegNo);
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'xbrli:period', 'xbrli:startDate', Format(ElecTaxDeclHeader."Declaration Period From Date", 0, '<Year4>-<Month,2>-<Day,2>'));
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'xbrli:period', 'xbrli:endDate', Format(ElecTaxDeclHeader."Declaration Period To Date", 0, '<Year4>-<Month,2>-<Day,2>'));

        case ElecTaxDeclarationSetup."VAT Contact Type" of
            ElecTaxDeclarationSetup."VAT Contact Type"::"Tax Payer":
                begin
                    LibraryXMLRead.VerifyNodeValueInSubtree(XbrliXbrlTok, 'bd-i:ContactType', 'BPL');
                    LibraryXMLRead.VerifyNodeValueInSubtree(XbrliXbrlTok, 'bd-i:ContactInitials', 'JHR');
                    LibraryXMLRead.VerifyNodeValueInSubtree(XbrliXbrlTok, 'bd-i:ContactPrefix', 'Joe');
                    LibraryXMLRead.VerifyNodeValueInSubtree(XbrliXbrlTok, 'bd-i:ContactSurname', 'Harris Roberts');
                    LibraryXMLRead.VerifyNodeValueInSubtree(XbrliXbrlTok, 'bd-i:ContactTelephoneNumber', '6549-3216-7415');
                end;
            ElecTaxDeclarationSetup."VAT Contact Type"::Agent:
                begin
                    LibraryXMLRead.VerifyNodeValueInSubtree(XbrliXbrlTok, 'bd-i:ContactType', 'INT');
                    LibraryXMLRead.VerifyNodeValueInSubtree(XbrliXbrlTok, 'bd-i:ContactInitials', 'JDS');
                    LibraryXMLRead.VerifyNodeValueInSubtree(XbrliXbrlTok, 'bd-i:ContactPrefix', 'John');
                    LibraryXMLRead.VerifyNodeValueInSubtree(XbrliXbrlTok, 'bd-i:ContactSurname', 'Doe Smith');
                    LibraryXMLRead.VerifyNodeValueInSubtree(XbrliXbrlTok, 'bd-i:ContactTelephoneNumber', '1972-3216-7415');
                    LibraryXMLRead.VerifyNodeValueInSubtree(XbrliXbrlTok, 'bd-i:TaxConsultantNumber', '123456789');
                end;
        end;

        NodeList.AddRange(
            'bd-i:InstallationDistanceSalesWithinTheEC',
            'bd-i:SuppliesServicesNotTaxed',
            'bd-i:SuppliesToCountriesOutsideTheEC',
            'bd-i:SuppliesToCountriesWithinTheEC',
            'bd-i:TaxedTurnoverPrivateUse',
            'bd-i:TaxedTurnoverSuppliesServicesGeneralTariff',
            'bd-i:TaxedTurnoverSuppliesServicesOtherRates',
            'bd-i:TaxedTurnoverSuppliesServicesReducedTariff',
            'bd-i:TurnoverFromTaxedSuppliesFromCountriesOutsideTheEC',
            'bd-i:TurnoverFromTaxedSuppliesFromCountriesWithinTheEC',
            'bd-i:TurnoverSuppliesServicesByWhichVATTaxationIsTransferred',
            'bd-i:ValueAddedTaxOnInput',
            'bd-i:ValueAddedTaxOnSuppliesFromCountriesOutsideTheEC',
            'bd-i:ValueAddedTaxOnSuppliesFromCountriesWithinTheEC',
            'bd-i:ValueAddedTaxOwed',
            'bd-i:ValueAddedTaxOwedToBePaidBack',
            'bd-i:ValueAddedTaxPrivateUse',
            'bd-i:ValueAddedTaxSuppliesServicesByWhichVATTaxationIsTransferred',
            'bd-i:ValueAddedTaxSuppliesServicesGeneralTariff',
            'bd-i:ValueAddedTaxSuppliesServicesOtherRates',
            'bd-i:ValueAddedTaxSuppliesServicesReducedTariff');

        foreach Node in NodeList do begin
            LibraryXMLRead.GetNodeValueInSubtree(XbrliXbrlTok, Node); // Don't care about value, just verify existence
            LibraryXMLRead.VerifyAttributeValueInSubtree(XbrliXbrlTok, Node, 'decimals', 'INF');
            LibraryXMLRead.VerifyAttributeValueInSubtree(XbrliXbrlTok, Node, 'contextRef', 'Msg');
            LibraryXMLRead.VerifyAttributeValueInSubtree(XbrliXbrlTok, Node, 'unitRef', 'EUR');
        end;

        LibraryXMLRead.VerifyXMLDeclaration('1.0', 'UTF-8', 'yes');
    end;

    local procedure VerifyICPXBLRDocContent(var ElecTaxDeclHeader: Record "Elec. Tax Declaration Header"; Filename: Text)
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        CompanyInfo: Record "Company Information";
        UseVATRegNo: Text[30];
    begin
        ElecTaxDeclarationSetup.Get();
        CompanyInfo.Get();
        if ElecTaxDeclarationSetup."Part of Fiscal Entity" then
            UseVATRegNo := CompanyInfo."Fiscal Entity No."
        else
            UseVATRegNo := CompanyInfo."VAT Registration No.";
        if CopyStr(UpperCase(UseVATRegNo), 1, 2) = 'NL' then
            UseVATRegNo := DelStr(UseVATRegNo, 1, 2);

        LibraryXMLRead.Initialize(Filename);
        LibraryXMLRead.VerifyAttributeValue(XbrliXbrlTok, AttrBdTTok, BDTuplesEndpointTxt);
        LibraryXMLRead.VerifyAttributeValue(XbrliXbrlTok, AttrBdITok, BDDataEndpointTxt);
        LibraryXMLRead.VerifyAttributeValueInSubtree(
          XbrliXbrlTok, 'link:schemaRef', 'xlink:href', ICPDeclarationSchemaEndpointTxt);
        LibraryXMLRead.VerifyNodeValueInSubtree('xbrli:context', 'xbrli:identifier', UseVATRegNo);
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'xbrli:period', 'xbrli:startDate', Format(ElecTaxDeclHeader."Declaration Period From Date", 0, '<Year4>-<Month,2>-<Day,2>'));
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'xbrli:period', 'xbrli:endDate', Format(ElecTaxDeclHeader."Declaration Period To Date", 0, '<Year4>-<Month,2>-<Day,2>'));

        case ElecTaxDeclarationSetup."ICP Contact Type" of
            ElecTaxDeclarationSetup."VAT Contact Type"::"Tax Payer":
                begin
                    LibraryXMLRead.VerifyNodeValueInSubtree(XbrliXbrlTok, 'bd-i:ContactInitials', 'JHR');
                    LibraryXMLRead.VerifyNodeValueInSubtree(XbrliXbrlTok, 'bd-i:ContactPrefix', 'Joe');
                    LibraryXMLRead.VerifyNodeValueInSubtree(XbrliXbrlTok, 'bd-i:ContactSurname', 'Harris Roberts');
                    LibraryXMLRead.VerifyNodeValueInSubtree(XbrliXbrlTok, 'bd-i:ContactTelephoneNumber', '6549-3216-7415');
                end;
            ElecTaxDeclarationSetup."VAT Contact Type"::Agent:
                begin
                    LibraryXMLRead.VerifyNodeValueInSubtree(XbrliXbrlTok, 'bd-i:ContactInitials', 'JDS');
                    LibraryXMLRead.VerifyNodeValueInSubtree(XbrliXbrlTok, 'bd-i:ContactPrefix', 'John');
                    LibraryXMLRead.VerifyNodeValueInSubtree(XbrliXbrlTok, 'bd-i:ContactSurname', 'Doe Smith');
                    LibraryXMLRead.VerifyNodeValueInSubtree(XbrliXbrlTok, 'bd-i:ContactTelephoneNumber', '1972-3216-7415');
                    LibraryXMLRead.VerifyNodeValueInSubtree(XbrliXbrlTok, 'bd-i:TaxConsultantNumber', '123456789');
                end;
        end;

        LibraryXMLRead.VerifyXMLDeclaration('1.0', 'UTF-8', 'yes');
    end;

    local procedure VerifyICPVATEntry(var VATEntry: Record "VAT Entry")
    var
        CountryRegion: Record "Country/Region";
        TagName: Text;
        ElementName: Text;
    begin
        if VATEntry."EU Service" then begin
            TagName := 'bd-t:IntraCommunityServices';
            ElementName := 'bd-i:ServicesAmount';
        end;
        if not VATEntry."EU 3-Party Trade" and not VATEntry."EU Service" then begin
            TagName := 'bd-t:IntraCommunitySupplies';
            ElementName := 'bd-i:SuppliesAmount';
        end;
        if VATEntry."EU 3-Party Trade" and not VATEntry."EU Service" then begin
            TagName := 'bd-t:IntraCommunityABCSupplies';
            ElementName := 'bd-i:SuppliesAmount';
        end;

        if CountryRegion.Get(VATEntry."Country/Region Code") then;
        LibraryXMLRead.VerifyNodeValueInSubtree(TagName, 'bd-i:CountryCodeISO-EC', CountryRegion."ISO Code");
        LibraryXMLRead.VerifyAttributeValueInSubtree(TagName, 'bd-i:CountryCodeISO-EC', 'contextRef', 'Msg');

        LibraryXMLRead.VerifyNodeValueInSubtree(TagName, ElementName, Format(-VATEntry.Base, 0, '<Sign><Integer>'));
        LibraryXMLRead.VerifyAttributeValueInSubtree(TagName, ElementName, 'contextRef', 'Msg');
        LibraryXMLRead.VerifyAttributeValueInSubtree(TagName, ElementName, 'unitRef', 'EUR');
        LibraryXMLRead.VerifyAttributeValueInSubtree(TagName, ElementName, 'decimals', 'INF');

        LibraryXMLRead.VerifyNodeValueInSubtree(TagName, 'bd-i:VATIdentificationNumberNational', VATEntry."VAT Registration No.");
        LibraryXMLRead.VerifyAttributeValueInSubtree(TagName, ElementName, 'contextRef', 'Msg');

        LibraryXMLRead.VerifyXMLDeclaration('1.0', 'UTF-8', 'yes');
    end;

    [Test]
    [HandlerFunctions('CreateElecICPDeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyCountryCodeISOECWhenNonEmptyEUCountryCode()
    var
        VATEntry: Record "VAT Entry";
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        CountryRegion: Record "Country/Region";
        No: Code[20];
    begin
        // [SCENARIO 271082] When Country/Region record has nonempty "EU Country/Region Code", bd-i:CountryCodeISO-EC and bd-i:VATIdentificationNumberNational values are set according to EU Country Code.
        Initialize();

        // [GIVEN] Country/Region record with "EU Country/Region Code" = "EL", it is different from Code = "GR".
        // [GIVEN] VAT Entry with "Country/Region Code" = "GR", "VAT Registration No." = "EL1234567". Posting Date must be less than TODAY.
        MockCountryRegionRecord(
          CountryRegion, LibraryUtility.GenerateGUID(),
          CopyStr(LibraryUtility.GenerateRandomXMLText(2), 1, 2),
          CopyStr(LibraryUtility.GenerateRandomXMLText(2), 1, 2));
        MockVATEntry(
          VATEntry, VATEntry."Document Type"::Invoice, VATEntry."VAT Calculation Type"::"Reverse Charge VAT",
          VATEntry.Type::Sale, -LibraryRandom.RandDec(100, 2), 0, CalcDate('<-3M>', Today), CountryRegion.Code,
          CountryRegion."EU Country/Region Code" + LibraryUtility.GenerateGUID());

        // [WHEN] Create Electronic Tax Declaration
        No := CreateElectronicTaxDeclaration(ElecTaxDeclarationHeader."Declaration Type"::"ICP Declaration");

        // [THEN] bd-i:CountryCodeISO-EC = "EL", bd-i:VATIdentificationNumberNational = "1234567".
        VerifyElecTaxDeclarationLine(No, 'bd-i:CountryCodeISO-EC', CountryRegion."EU Country/Region Code");
        VerifyElecTaxDeclarationLine(
          No, 'bd-i:VATIdentificationNumberNational',
          DelStr(VATEntry."VAT Registration No.", 1, StrLen(CountryRegion."EU Country/Region Code")));

        // Tear down
        CountryRegion.Delete();
        VATEntry.Delete();
    end;

    [Test]
    [HandlerFunctions('CancelSubmitElecTaxDeclarationReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SubmitElecTaxDeclarationReportDoesNotRequireUseCertificateSetupOption()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        SubmitElecTaxDeclaration: Report "Submit Elec. Tax Declaration";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 354933] Stan can run the "Submit Elec. Tax Declaration" report with option "Use Certificate Setup" disabled

        Initialize();
        LibraryPermissions.SetTestabilitySoftwareAsAService(true);
        ElecTaxDeclarationSetup.Get();
        ElecTaxDeclarationSetup.Validate("Client Certificate Code", MockIsolatedCertificate());
        ElecTaxDeclarationSetup.Validate("Service Certificate Code", MockIsolatedCertificate());
        ElecTaxDeclarationSetup.Validate("Use Certificate Setup", true);
        ElecTaxDeclarationSetup.Validate("Digipoort Delivery URL", LibraryUtility.GenerateGUID());
        ElecTaxDeclarationSetup.Validate("Digipoort Status URL", LibraryUtility.GenerateGUID());
        ElecTaxDeclarationSetup.Modify(true);
        Commit();
        // We do not actually run the report but only check the OnInitReport trigger, then cancel the report by CancelSubmitElecTaxDeclarationReportRequestPageHandler
        SubmitElecTaxDeclaration.Run();
        LibraryPermissions.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure NotPossibleToDownloadSubmissionMessageWithoutGeneration()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationCard: TestPage "Elec. Tax Declaration Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 367102] Stan cannot download the submission message without generation

        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Electronic Tax Declaration with type = "VAT Declaration"
        CreateElecTaxDeclarationWithLines(ElecTaxDeclarationHeader);
        ElecTaxDeclarationCard.OpenEdit();
        ElecTaxDeclarationCard.FILTER.SetFilter("No.", ElecTaxDeclarationHeader."No.");

        // [WHEN] Download submission message
        asserterror ElecTaxDeclarationCard.DownloadSubmissionMessage.Invoke();

        // [THEN] An error "The submission message of the report is not available." is shown
        Assert.ExpectedError(NoSubmissionMessageAvailableErr);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler,ConfirmHandlerWithVerification')]
    [Scope('OnPrem')]
    procedure SubmissionMessageContentDuringGenerateSubmissionMessage()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ERMEVAT: Codeunit "ERM EVAT";
        ElecTaxDeclarationCard: TestPage "Elec. Tax Declaration Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 367102] Stan can check the XBRL content without the actual submission to Digipoort during the generation of the submission message

        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        BindSubscription(ERMEVAT);

        // [GIVEN] Electronic Tax Declaration with type = "VAT Declaration"
        CreateElecTaxDeclarationWithLines(ElecTaxDeclarationHeader);
        LibraryVariableStorage.Enqueue(DownloadSubmissionMessageQst); // for ConfirmHandlerWithVerification
        LibraryVariableStorage.Enqueue(true); // Choose "Yes" for downloading the submission message
        ElecTaxDeclarationCard.OpenEdit();
        ElecTaxDeclarationCard.FILTER.SetFilter("No.", ElecTaxDeclarationHeader."No.");

        // [WHEN] Generate XBRL for Tax Declaration
        ElecTaxDeclarationCard.GenerateSubmissionMessage.Invoke();

        // [THEN] XBRL content has been generated
        VerifyVATDeclarationSubmissionMessageGenerated(ElecTaxDeclarationHeader);

        // [THEN] XBRL content was downloaded
        // Handle download by OnBeforeDownloadFromStreamHandler
        VerifyContentWasDownloaded();

        // Tear down
        ElecTaxDeclarationCard.Close();
        LibraryVariableStorage.AssertEmpty();
        UnbindSubscription(ERMEVAT);
        LibraryApplicationArea.DisableApplicationAreaSetup();
        NameValueBuffer.Delete();
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler,ConfirmHandlerWithVerification')]
    [Scope('OnPrem')]
    procedure DownloadSubmissionMessageContentAfterGenerateSubmissionMessage()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ERMEVAT: Codeunit "ERM EVAT";
        ElecTaxDeclarationCard: TestPage "Elec. Tax Declaration Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 367102] Stan can check the XBRL content without the actual submission to Digipoort after the generation of the submission message

        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        BindSubscription(ERMEVAT);

        // [GIVEN] Electronic Tax Declaration with type = "VAT Declaration"
        CreateElecTaxDeclarationWithLines(ElecTaxDeclarationHeader);
        LibraryVariableStorage.Enqueue(DownloadSubmissionMessageQst); // for ConfirmHandlerWithVerification
        LibraryVariableStorage.Enqueue(false); // Choose "no" for downloading the submission message.
        ElecTaxDeclarationCard.OpenEdit();
        ElecTaxDeclarationCard.FILTER.SetFilter("No.", ElecTaxDeclarationHeader."No.");

        // [GIVEN]  Generate XBRL for Tax Declaration
        ElecTaxDeclarationCard.GenerateSubmissionMessage.Invoke();

        // [WHEN] Download XBRL for Tax Declaration
        ElecTaxDeclarationCard.DownloadSubmissionMessage.Invoke();

        // [THEN] XBRL content was downloaded
        // Handle download by OnBeforeDownloadFromStreamHandler
        VerifyContentWasDownloaded();

        // Tear down
        ElecTaxDeclarationCard.Close();
        LibraryVariableStorage.AssertEmpty();
        UnbindSubscription(ERMEVAT);
        LibraryApplicationArea.DisableApplicationAreaSetup();
        NameValueBuffer.Delete();
    end;

    [Test]
    [HandlerFunctions('CreateElecICPDeclarationWithFilterRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ICPDeclarationDoesNotContainEntriesWithCountryOutsideEU()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationLine: Record "Elec. Tax Declaration Line";
        VATEntry: Record "VAT Entry";
        CountryRegion: Record "Country/Region";
        ElecTaxDeclHeaderNo: Code[20];
    begin
        // [SCENARIO 405527] ICP declaration does not contains VAT entries with country/region code outside EU

        Initialize();

        // [GIVEN] Country "X" with blank "EU Country/Region Code"
        LibraryERM.CreateCountryRegion(CountryRegion);

        // [GIVEN] VAT Entry with country "X"
        CreateReverseChargeSalesVATEntryWithCountryCode(VATEntry, CountryRegion.Code);
        LibraryVariableStorage.Enqueue(VATEntry."VAT Bus. Posting Group"); // for CreateElecICPDeclarationWithFilterRequestPageHandler to consider only this single VAT entry

        // [WHEN] Create ICP declaration for VAT entry
        ElecTaxDeclHeaderNo := CreateElectronicTaxDeclaration(ElecTaxDeclarationHeader."Declaration Type"::"ICP Declaration");

        // [THEN] No electronic tax declaration line has been generated with 'bd-i:SuppliesAmount' name
        FilterOnElecTaxDeclLine(
          ElecTaxDeclarationLine, ElecTaxDeclarationLine."Declaration Type"::"ICP Declaration", ElecTaxDeclHeaderNo,
          ElecTaxDeclarationLine."Line Type"::Element, 'bd-i:SuppliesAmount');
        Assert.IsTrue(ElecTaxDeclarationLine.IsEmpty(), 'Electronic tax declaration line has been generated');

        // [THEN] No electronic tax declaration line has been generated with 'bd-t:IntraCommunitySupplies' name
        // Bug id 420957: No electronic tax declaration line must be generated for non-EU country
        FilterOnElecTaxDeclLine(
          ElecTaxDeclarationLine, ElecTaxDeclarationLine."Declaration Type"::"ICP Declaration", ElecTaxDeclHeaderNo,
          ElecTaxDeclarationLine."Line Type"::Element, 'bd-t:IntraCommunitySupplies');
        Assert.IsTrue(ElecTaxDeclarationLine.IsEmpty(), 'Electronic tax declaration line has been generated');

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM EVAT");
        ElecTaxDeclarationHeader.DeleteAll();
        LibraryVariableStorage.Clear();
        NameValueBuffer.SetRange(Name, Format(CODEUNIT::"ERM EVAT"));
        NameValueBuffer.DeleteAll();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure InitializeElecTaxDeclSetup(VATUseAgent: Boolean; ICPUseAgent: Boolean)
    var
        ElecTaxDeclSetup: Record "Elec. Tax Declaration Setup";
        CompanyInfo: Record "Company Information";
    begin
        if not ElecTaxDeclSetup.Get() then begin
            ElecTaxDeclSetup.Init();
            ElecTaxDeclSetup.Insert();
        end;

        if VATUseAgent then
            ElecTaxDeclSetup."VAT Contact Type" := ElecTaxDeclSetup."VAT Contact Type"::Agent
        else
            ElecTaxDeclSetup."VAT Contact Type" := ElecTaxDeclSetup."VAT Contact Type"::"Tax Payer";

        if ICPUseAgent then
            ElecTaxDeclSetup."ICP Contact Type" := ElecTaxDeclSetup."ICP Contact Type"::Agent
        else
            ElecTaxDeclSetup."ICP Contact Type" := ElecTaxDeclSetup."ICP Contact Type"::"Tax Payer";

        if VATUseAgent or ICPUseAgent then begin
            ElecTaxDeclSetup."Agent Contact ID" := '123456789';
            ElecTaxDeclSetup."Agent Contact Name" := 'John Doe Smith';
            ElecTaxDeclSetup."Agent Contact Phone No." := '1972-3216-7415';
            ElecTaxDeclSetup."Agent Contact Address" := 'Some place 1';
            ElecTaxDeclSetup."Agent Contact Post Code" := '2900';
            ElecTaxDeclSetup."Agent Contact City" := 'Amsterdam';
        end;
        if not VATUseAgent or not ICPUseAgent then begin
            ElecTaxDeclSetup."Tax Payer Contact Name" := 'Joe Harris Roberts';
            ElecTaxDeclSetup."Tax Payer Contact Phone No." := '6549-3216-7415';
        end;
        ElecTaxDeclSetup."Digipoort Client Cert. Name" := 'abcde';
        ElecTaxDeclSetup."Digipoort Service Cert. Name" := 'abcde';
        ElecTaxDeclSetup."Digipoort Delivery URL" := 'http://url.com';
        ElecTaxDeclSetup."Digipoort Status URL" := 'http://url.com';
        ElecTaxDeclSetup.Modify(true);

        CompanyInfo.Get();
        CompanyInfo.Address := 'Microsoft Avenue 1234';
        CompanyInfo.City := 'Seattle';
        CompanyInfo."Post Code" := '5678';
        CompanyInfo.Modify(true);
    end;

    local procedure EnableUseCertificateSetupOption()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        ElecTaxDeclarationSetup.Get();
        ElecTaxDeclarationSetup."Use Certificate Setup" := true;
        ElecTaxDeclarationSetup."Client Certificate Code" := InsertIsolatedCertificate();
        ElecTaxDeclarationSetup."Service Certificate Code" := InsertIsolatedCertificate();
        ElecTaxDeclarationSetup.Modify();
    end;

    local procedure InsertIsolatedCertificate(): Code[20]
    var
        IsolatedCertificate: Record "Isolated Certificate";
    begin
        IsolatedCertificate.Init();
        IsolatedCertificate.Code :=
          LibraryUtility.GenerateRandomCode(IsolatedCertificate.FieldNo(Code), DATABASE::"Isolated Certificate");
        IsolatedCertificate.Insert();
        exit(IsolatedCertificate.Code);
    end;

    local procedure CalculateVATAmount() VATAmount: Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Posting Date", GetDeclarationQuarterStartingDate(), CalcDate('<+CQ>', GetDeclarationQuarterStartingDate()));
        VATEntry.FindSet();
        repeat
            VATAmount := VATAmount + VATEntry.Amount;
        until VATEntry.Next() = 0;
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateAndPostGeneralJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Account Type"; RelativeDate: Text)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::"G/L Account", CreateGLAccount(), LibraryRandom.RandDec(100, 2));  // Taken random Amount.
        GenJournalLine.Validate("Posting Date", CalcDate(RelativeDate, Today));  // Taken Posting Date as previous quarter.
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateSalesInvoiceVATEntry()
    var
        VATEntry: Record "VAT Entry";
        Base: Decimal;
    begin
        Base := LibraryRandom.RandInt(9) / LibraryRandom.RandIntInRange(10, 20);
        CreateReverseChargeSalesVATEntry(
          VATEntry, VATEntry."Document Type"::Invoice, Base,
          Base * (LibraryRandom.RandDecInRange(10, 30, 2) / 100), false, false);
    end;

    local procedure CreateAndModifyVATStatementLine(VATStatementName: Record "VAT Statement Name"; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; Type: Enum "VAT Statement Line Type"; RowNo: Code[20]; Print: Boolean)
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        CreateVATStatementLine(VATStatementLine, VATStatementName, RowNo, Type);
        VATStatementLine.Validate("Gen. Posting Type", VATStatementLine."Gen. Posting Type"::Purchase);
        VATStatementLine.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        VATStatementLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        VATStatementLine.Validate("Amount Type", VATStatementLine."Amount Type"::Amount);
        VATStatementLine.Validate(Print, Print);
        VATStatementLine.Modify(true);
    end;

    local procedure CreateAndModifyVATStatementLineWithAccountTotaling(VATStatementName: Record "VAT Statement Name"; RowNo: Code[20]; Type: Enum "VAT Statement Line Type"; AccountTotaling: Code[20]; CalculateWith: Option)
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        CreateVATStatementLine(VATStatementLine, VATStatementName, RowNo, Type);
        VATStatementLine.Validate("Account Totaling", AccountTotaling);
        VATStatementLine.Validate("Calculate with", CalculateWith);
        VATStatementLine.Modify(true);
    end;

    local procedure CreateAndModifyElecTaxDeclarationHeader(DeclarationType: Option): Code[20]
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        LibraryNLLocalization.CreateElecTaxDeclarationHeader(
          ElecTaxDeclarationHeader, DeclarationType);
        ElecTaxDeclarationHeader.Validate("Declaration Period", GetDeclarationPeriod());
        ElecTaxDeclarationHeader.Validate("Declaration Year", GetDeclarationYear());
        ElecTaxDeclarationHeader.Validate("Our Reference", 'OB-' +
          LibraryUtility.GenerateRandomXMLText(
            LibraryUtility.GetFieldLength(DATABASE::"Elec. Tax Declaration Header",
              ElecTaxDeclarationHeader.FieldNo("Our Reference")) - StrLen('OB-')));  // Our Reference must be of 20 digits.
        ElecTaxDeclarationHeader.Modify(true);
        exit(ElecTaxDeclarationHeader."No.");
    end;

    local procedure CreateElecVATDeclAndRunVATStatementReport(RoundToWholeNumbers: Boolean; Print: Boolean) RowNo: Code[10]
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementName: Record "VAT Statement Name";
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
    begin
        // Setup: Create VAT Statement Line, create and post Gen. Journal Line, create Electronic Tax Declaration.
        RowNo := LibraryUtility.GenerateGUID();
        VATStatementName.FindFirst();
        CreateAndPostGeneralJnlLine(GenJournalLine, GenJournalLine."Document Type"::" ", '<-3M>');
        CreateAndModifyVATStatementLine(
          VATStatementName, GenJournalLine."VAT Bus. Posting Group", GenJournalLine."VAT Prod. Posting Group",
          VATStatementLine.Type::"VAT Entry Totaling", RowNo, Print);

        // Enqueue for CreateElecVATDeclarationRequestPageHandler.
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        LibraryVariableStorage.Enqueue(VATStatementName.Name);

        CreateElectronicTaxDeclaration(ElecTaxDeclHeader."Declaration Type"::"VAT Declaration");
        LibraryVariableStorage.Enqueue(RoundToWholeNumbers);  // Enqueue for VATStatementRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"VAT Statement");
    end;

    local procedure CreateElectronicTaxDeclaration(DeclarationType: Option) No: Code[20]
    var
        ElecTaxDeclarationCard: TestPage "Elec. Tax Declaration Card";
    begin
        No := CreateAndModifyElecTaxDeclarationHeader(DeclarationType);
        ElecTaxDeclarationCard.OpenEdit();
        ElecTaxDeclarationCard.FILTER.SetFilter("No.", No);
        Commit();  // COMMIT required here.
        ElecTaxDeclarationCard.CreateElectronicTaxDeclaration.Invoke();
        ElecTaxDeclarationCard.Close();
    end;

    local procedure CreateVATStatementLine(var VATStatementLine: Record "VAT Statement Line"; VATStatementName: Record "VAT Statement Name"; RowNo: Code[20]; Type: Enum "VAT Statement Line Type")
    begin
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementName."Statement Template Name", VATStatementName.Name);
        VATStatementLine.Validate("Elec. Tax Decl. Category Code", '5G');  // Using Hard Code Value '5G' of Electronic Tax Declaraton VAT Category table for Calculation.
        VATStatementLine.Validate("Row No.", RowNo);
        VATStatementLine.Validate(Type, Type);
        VATStatementName.Modify(true);
    end;

    local procedure CreateReverseChargeSalesInvoiceVATEntry(var VATEntry: Record "VAT Entry"; EUTrade: Boolean; EUService: Boolean)
    begin
        CreateReverseChargeSalesVATEntry(
          VATEntry, VATEntry."Document Type"::Invoice, LibraryRandom.RandDec(1000, 2),
          LibraryRandom.RandDec(250, 2), EUTrade, EUService);
    end;

    local procedure CreateReverseChargeSalesVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; BaseValue: Decimal; AmountValue: Decimal; EUTrade: Boolean; EUService: Boolean)
    var
        NextEntryNo: Integer;
    begin
        NextEntryNo := 0;
        VATEntry.Reset();
        if VATEntry.FindLast() then
            NextEntryNo := VATEntry."Entry No.";
        NextEntryNo += 1;

        VATEntry.Init();
        VATEntry."Entry No." := NextEntryNo;
        VATEntry."VAT Calculation Type" := VATEntry."VAT Calculation Type"::"Reverse Charge VAT";
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."Document Type" := DocumentType;
        VATEntry.Base := BaseValue;
        VATEntry.Amount := AmountValue;
        VATEntry."Posting Date" := CalcDate('<-3M>', Today);
        VATEntry."VAT Registration No." :=
          LibraryUtility.GenerateRandomCode(VATEntry.FieldNo("VAT Registration No."), DATABASE::"VAT Entry");
        VATEntry."Country/Region Code" := GetRandomCountryCode(true);
        VATEntry."EU Service" := EUService;
        VATEntry."EU 3-Party Trade" := EUTrade;
        VATEntry.Insert();
    end;

    local procedure CreateReverseChargeSalesVATEntryWithCountryCode(var VATEntry: Record "VAT Entry"; CountryCode: Code[10])
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        CreateReverseChargeSalesVATEntry(VATEntry, VATEntry."Document Type"::Invoice, 1, 1, false, false);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VATEntry."VAT Bus. Posting Group" := VATBusinessPostingGroup.Code;
        VATEntry."Country/Region Code" := CountryCode;
        VATEntry.Modify();
    end;

    local procedure CreateElecTaxDeclarationWithLines(var ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header")
    var
        VATStatementName: Record "VAT Statement Name";
    begin
        InitializeElecTaxDeclSetup(false, false);
        VATStatementName.FindFirst();
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        LibraryVariableStorage.Enqueue(VATStatementName.Name);
        ElecTaxDeclarationHeader.Get(
          ElecTaxDeclarationHeader."Declaration Type"::"VAT Declaration",
          CreateElectronicTaxDeclaration(ElecTaxDeclarationHeader."Declaration Type"::"VAT Declaration"));
    end;

    local procedure MockVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; VATCalculationType: Enum "Tax Calculation Type"; GenPostingType: Enum "General Posting Type"; BaseValue: Decimal; AmountValue: Decimal; PostingDate: Date; CountryRegionCode: Code[10]; VATRegistrationNo: Text[20])
    begin
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry."Document Type" := DocumentType;
        VATEntry."VAT Calculation Type" := VATCalculationType;
        VATEntry.Type := GenPostingType;
        VATEntry.Base := BaseValue;
        VATEntry.Amount := AmountValue;
        VATEntry."Posting Date" := PostingDate;
        VATEntry."VAT Reporting Date" := PostingDate;
        VATEntry."Country/Region Code" := CountryRegionCode;
        VATEntry."VAT Registration No." := VATRegistrationNo;
        VATEntry.Insert();
    end;

    local procedure MockCountryRegionRecord(var CountryRegion: Record "Country/Region"; Name: Text[50]; CountryRegionCode: Code[10]; EUCountryRegionCode: Code[10])
    begin
        CountryRegion.Init();
        CountryRegion.Name := Name;
        CountryRegion.Code := CountryRegionCode;
        CountryRegion."EU Country/Region Code" := EUCountryRegionCode;
        CountryRegion.Insert();
    end;

    local procedure MockIsolatedCertificate(): Code[20]
    var
        IsolatedCertificate: Record "Isolated Certificate";
    begin
        IsolatedCertificate.Init();
        IsolatedCertificate.Code :=
          LibraryUtility.GenerateRandomCode20(IsolatedCertificate.FieldNo(Code), DATABASE::"Isolated Certificate");
        IsolatedCertificate.Insert();
        exit(IsolatedCertificate.Code);
    end;

    local procedure FindRowOnVATStatementReport(RowNo: Code[20]): Boolean
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(VatStmtLineRowNoCap, RowNo);
        exit(LibraryReportDataset.GetNextRow());
    end;

    local procedure FilterOnElecTaxDeclLine(var ElecTaxDeclLine: Record "Elec. Tax Declaration Line"; DeclarationType: Option; DeclarationNo: Code[20]; LineType: Option; ExpectedName: Text[80])
    begin
        ElecTaxDeclLine.SetRange("Declaration Type", DeclarationType);
        ElecTaxDeclLine.SetRange("Declaration No.", DeclarationNo);
        ElecTaxDeclLine.SetRange("Line Type", LineType);
        ElecTaxDeclLine.SetRange(Name, ExpectedName);
    end;

    local procedure GetDeclarationPeriod(): Enum "Elec. Tax Declaration Period"
    var
        CurrentMonth: Integer;
    begin
        CurrentMonth := Date2DMY(Today, 2);

        // Taken previous quarter.
        case CurrentMonth of
            1 .. 3:
                exit("Elec. Tax Declaration Period"::"Fourth Quarter");
            4 .. 6:
                exit("Elec. Tax Declaration Period"::"First Quarter");
            7 .. 9:
                exit("Elec. Tax Declaration Period"::"Second Quarter");
            10 .. 12:
                exit("Elec. Tax Declaration Period"::"Third Quarter");
        end;
    end;

    local procedure GetDeclarationYear(): Integer
    var
        CurrentMonth: Integer;
    begin
        CurrentMonth := Date2DMY(Today, 2);

        case CurrentMonth of
            1 .. 3:
                exit(Date2DMY(Today, 3) - 1);
            4 .. 12:
                exit(Date2DMY(Today, 3));
        end
    end;

    local procedure GetDeclarationQuarterStartingDate(): Date
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        ElecTaxDeclarationHeader."Declaration Period" := GetDeclarationPeriod();

        case ElecTaxDeclarationHeader."Declaration Period" of
            ElecTaxDeclarationHeader."Declaration Period"::"First Quarter":
                exit(DMY2Date(1, 1, GetDeclarationYear()));
            ElecTaxDeclarationHeader."Declaration Period"::"Second Quarter":
                exit(DMY2Date(1, 4, GetDeclarationYear()));
            ElecTaxDeclarationHeader."Declaration Period"::"Third Quarter":
                exit(DMY2Date(1, 7, GetDeclarationYear()));
            ElecTaxDeclarationHeader."Declaration Period"::"Fourth Quarter":
                exit(DMY2Date(1, 10, GetDeclarationYear()));
        end;
    end;

    local procedure GetRandomCountryCode(PartOfEU: Boolean): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Reset();
        if PartOfEU then
            CountryRegion.SetFilter("EU Country/Region Code", '<>%1', '');
        CountryRegion.Find('-');
        CountryRegion.Next(LibraryRandom.RandIntInRange(1, CountryRegion.Count));
        exit(CountryRegion.Code);
    end;

    local procedure VerifyElecTaxDeclarationLine(DeclarationNo: Code[20]; Name: Text[50]; Data: Text[250])
    var
        ElecTaxDeclarationLine: Record "Elec. Tax Declaration Line";
    begin
        ElecTaxDeclarationLine.SetRange("Declaration No.", DeclarationNo);
        ElecTaxDeclarationLine.SetRange(Name, Name);
        ElecTaxDeclarationLine.FindFirst();
        ElecTaxDeclarationLine.TestField(Data, Data);
    end;

    local procedure VerifyNoZeroAmount(var ElecTaxDeclLine: Record "Elec. Tax Declaration Line")
    begin
        ElecTaxDeclLine.SetRange(Data, '-0');
        Assert.IsTrue(ElecTaxDeclLine.IsEmpty, StrSubstNo(SuppliesAmountZeroErr, 'bd-ob:SuppliesAmount'));
        ElecTaxDeclLine.SetRange(Data);
    end;

    local procedure VerifySubElementCount(var ElecTaxDeclLine: Record "Elec. Tax Declaration Line")
    var
        ElecTaxDeclLine2: Record "Elec. Tax Declaration Line";
    begin
        ElecTaxDeclLine.SetRange(Name, 'bd-ob-tuple:IntraCommunitySupplies');
        if ElecTaxDeclLine.FindSet() then
            repeat
                ElecTaxDeclLine2.CopyFilters(ElecTaxDeclLine);
                ElecTaxDeclLine2.SetRange(Name);
                ElecTaxDeclLine2.SetRange("Parent Line No.", ElecTaxDeclLine."Line No.");
                Assert.AreEqual(3, ElecTaxDeclLine2.Count, SubElementErr);
            until ElecTaxDeclLine.Next() = 0;
        ElecTaxDeclLine.SetRange(Name);
    end;

    local procedure VerifyParentElement(var ElecTaxDeclLine: Record "Elec. Tax Declaration Line"; ElementName: Text[80])
    var
        ElecTaxDeclLine2: Record "Elec. Tax Declaration Line";
    begin
        ElecTaxDeclLine.SetRange(Name, ElementName);
        if ElecTaxDeclLine.FindSet() then
            repeat
                ElecTaxDeclLine2.Get(
                  ElecTaxDeclLine."Declaration Type", ElecTaxDeclLine."Declaration No.", ElecTaxDeclLine."Parent Line No.");
                Assert.IsTrue(
                  ElecTaxDeclLine2.Name in
                  ['bd-ob-tuple:IntraCommunitySupplies', 'bd-ob-tuple:IntraCommunityServices',
                   'bd-ob-tuple:IntraCommunityABCSupplies'],
                  StrSubstNo(ParentElementErr, ElementName));
            until ElecTaxDeclLine.Next() = 0;
        ElecTaxDeclLine.SetRange(Name);
    end;

    local procedure VerifyVATDeclarationSubmissionMessageGenerated(ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header")
    begin
        ElecTaxDeclarationHeader.CalcFields("Submission Message BLOB");
        Assert.IsTrue(ElecTaxDeclarationHeader."Submission Message BLOB".HasValue, 'No submission message has been generated');
    end;

    local procedure VerifyContentWasDownloaded()
    begin
        NameValueBuffer.Reset();
        NameValueBuffer.SetRange(Name, Format(CODEUNIT::"ERM EVAT"));
        NameValueBuffer.FindFirst();
        NameValueBuffer.TestField(Value, 'Submission.zip');
    end;

    local procedure CreateResponseMessage(var NextNo: Integer; StatusCode: Text; Subject: Text; ElecTaxDeclHeader: Record "Elec. Tax Declaration Header"): Integer
    var
        ElecTaxDeclRespMsg: Record "Elec. Tax Decl. Response Msg.";
    begin
        ElecTaxDeclRespMsg.Init();
        ElecTaxDeclRespMsg."No." := NextNo;
        NextNo += 1;
        ElecTaxDeclRespMsg."Declaration Type" := ElecTaxDeclHeader."Declaration Type";
        ElecTaxDeclRespMsg."Declaration No." := ElecTaxDeclHeader."No.";
        ElecTaxDeclRespMsg."Status Code" := StatusCode;
        ElecTaxDeclRespMsg.Subject := Subject;
        ElecTaxDeclRespMsg.Status := ElecTaxDeclRespMsg.Status::Received;
        ElecTaxDeclRespMsg.Insert(true);
        exit(ElecTaxDeclRespMsg."No.");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateElecVATDeclarationRequestPageHandler(var CreateElecVATDeclaration: TestRequestPage "Create Elec. VAT Declaration")
    var
        VATTemplateName: Variant;
        VATStatementName: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATTemplateName);
        LibraryVariableStorage.Dequeue(VATStatementName);
        CreateElecVATDeclaration.VATTemplateName.SetValue(VATTemplateName);
        CreateElecVATDeclaration.VATStatementName.SetValue(VATStatementName);
        CreateElecVATDeclaration.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateElecICPDeclarationRequestPageHandler(var CreateElecICPDeclaration: TestRequestPage "Create Elec. ICP Declaration")
    begin
        CreateElecICPDeclaration.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateElecICPDeclarationWithFilterRequestPageHandler(var CreateElecICPDeclaration: TestRequestPage "Create Elec. ICP Declaration")
    begin
        CreateElecICPDeclaration."VAT Entry".SetFilter("VAT Bus. Posting Group", LibraryVariableStorage.DequeueText());
        CreateElecICPDeclaration.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStatementRequestPageHandler(var VATStatement: TestRequestPage "VAT Statement")
    var
        RoundToWholeNumbers: Variant;
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
    begin
        LibraryVariableStorage.Dequeue(RoundToWholeNumbers);
        VATStatement.StartingDate.SetValue(GetDeclarationQuarterStartingDate());
        VATStatement.EndingDate.SetValue(CalcDate('<+CQ>', GetDeclarationQuarterStartingDate()));
        VATStatement.Selection.SetValue(Selection::Open);
        VATStatement.PeriodSelection.SetValue(PeriodSelection::"Within Period");
        VATStatement.RoundToWholeNumbers.SetValue(RoundToWholeNumbers);
        VATStatement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := false; // DO not allow to create a duplicate declaration for a period to catch the error
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerWithVerification(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    local procedure BuildDigipoortErrorXml(): Text
    var
        File: File;
        XML: Text[1024];
        FileName: Text;
    begin
        FileName := FileMgt.ServerTempFileName('xml');
        File.Create(FileName);
        File.TextMode(true);

        XML += '<results xmlns="http://nlvalidatie.nl/batavia"><xbrl><messages';
        XML += '   xmlns-xlink="http://www.w3.org/1999/xlink"';
        XML += '   xmlns-link="http://www.xbrl.org/2003/linkbase"';
        XML += '   xmlns-bd-dim-dom="http://www.nltaxonomie.nl/7.0/basis/bd/domains/bd-domains"';
        XML += '   xmlns-xml="http://www.w3.org/XML/1998/namespace"';
        XML += '   xmlns-bd-ob-tuple="http://www.nltaxonomie.nl/7.0/domein/bd/tuples/bd-ob-tuples"';
        XML += '   xmlns-bd-alg-tuple="http://www.nltaxonomie.nl/7.0/domein/bd/tuples/bd-alg-tuples"';
        XML += '   xmlns-iso4217="http://www.xbrl.org/2003/iso4217"';
        XML += '   xmlns-bd-alg="http://www.nltaxonomie.nl/7.0/basis/bd/items/bd-algemeen"';
        XML += '   xmlns-xsi="http://www.w3.org/2001/XMLSchema-instance"';
        XML += '   xmlns-xbrli="http://www.xbrl.org/2003/instance"';
        XML += '   xmlns-bd-dim-dim="http://www.nltaxonomie.nl/7.0/domein/bd/axes/bd-axes"';
        XML += '   xmlns-xbrldi="http://xbrl.org/2006/xbrldi"';
        XML += '   xmlns-bd-ob="http://www.nltaxonomie.nl/7.0/basis/bd/items/bd-omzetbelasting">';
        File.Write(XML);

        XML := '   <msg';
        XML += '      line="1"';
        XML += '      col="1228"';
        XML += '      technicalRole="http://xbrl.org/2006/xbrldi"';
        XML += '      userRole="http://xbrl.org/2006/xbrldi"';
        XML += '      level="error"';
        XML += '      id="msg138b4a1t1a9v3i4a9x9b8r7l">For file: .';
        XML +=
          'xbrldie_ExplicitMemberUndefinedQNameError: The QName value of the xbrldi:explicitMember element bd-dim-dom:Declarant is not an element defined in the taxonomy schema.';
        XML += '      <origin';
        XML += '         file="">';
        XML += '         <xbrldi-explicitMember';
        XML += '            dimension="bd-dim-dim:PartyDimension">bd-dim-dom:Declarant</xbrldi-explicitMember>';
        XML += '      </origin></msg>';
        File.Write(XML);

        XML := '   <msg';
        XML += '      line="1"';
        XML += '      col="1602"';
        XML += '      technicalRole="http://www.xbrl.org/2003/instance"';
        XML += '      userRole="http://www.xbrl.org/2003/instance"';
        XML += '      level="error"';
        XML += '      id="msg138b4a1t1a9v3i4a9x9b9r2l">For file: .';
        XML += 'UnknownInstanceElement.validate.0: Batavia XBRL does not consider &apos;http://www.nltaxonomie.nl/7.0/domei&apos; to be a valid InstanceElement regarding the XBRL 2.1 specificatio';
        XML += '      <origin';
        XML += '         file="">';
        XML += '         <bd-alg-tuple-CorrespondentConsultantAdvisor>';
        XML += '            <bd-alg-NameContactSupplier';
        XML += '               contextRef="Msg">BCPP</bd-alg-NameContactSupplier>';
        XML += '            <bd-alg-TaxconsultantNumber';
        XML += '               contextRef="Msg">234564</bd-alg-TaxconsultantNumber>';
        XML += '            <bd-alg-TelephoneNumberContactSupplier';
        XML += '               contextRef="Msg">055-5287777</bd-alg-TelephoneNumberContactSupplier>';
        XML += '         </bd-alg-tuple-CorrespondentConsultantAdvisor>';
        XML += '      </origin></msg>';
        File.Write(XML);

        XML := '   <msg';
        XML += '      line="1"';
        XML += '      col="2177"';
        XML += '      technicalRole="http://www.xbrl.org/2003/instance"';
        XML += '      userRole="http://www.xbrl.org/2003/instance"';
        XML += '      level="error"';
        XML += '      id="msg138b4a1t1a9v3i4a9x9b9r5l">For file: .';
        XML += 'UnknownInstanceElement.validate.0: Batavia XBRL does not consider &apos;http://www.nltaxonomie.nl/7.0/basis/bd/&apos; to be a valid InstanceElement regarding the XBRL 2.1 specification. The doc';
        XML += '      <origin';
        XML += '         file="">';
        XML += '         <bd-alg-TelephoneNumberContactSupplier';
        XML += '            contextRef="Msg">06-15030777</bd-alg-TelephoneNumberContactSupplier>';
        XML += '      </origin></msg>';
        XML += '</messages></xbrl></results>';
        File.Write(XML);
        File.Close();

        exit(FileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CancelSubmitElecTaxDeclarationReportRequestPageHandler(var SubmitElecTaxDeclaration: TestRequestPage "Submit Elec. Tax Declaration")
    begin
        SubmitElecTaxDeclaration.Cancel().Invoke();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeDownloadFromStreamHandler', '', false, false)]
    local procedure OnBeforeDownloadFromStreamHandler(var ToFolder: Text; ToFileName: Text; FromInStream: InStream; var IsHandled: Boolean)
    begin
        if NameValueBuffer.FindLast() then;
        NameValueBuffer.ID += 1;
        NameValueBuffer.Name := Format(CODEUNIT::"ERM EVAT");
        NameValueBuffer.Value := CopyStr(ToFileName, 1, MaxStrLen(NameValueBuffer.Name));
        NameValueBuffer.Insert();
        IsHandled := true;
    end;
}

