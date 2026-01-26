codeunit 144070 Digipoort
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Digipoort]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        DigipoortDeliveryURLSetupErr: Label 'Digipoort Delivery URL must have a value in Elec. Tax Declaration Setup: ';
        DigipoortStatusURLSetupErr: Label 'Digipoort Status URL must have a value in Elec. Tax Declaration Setup: ';
        DigipoortClientCertNameSetupErr: Label 'Digipoort Client Cert. Name must have a value in Elec. Tax Declaration Setup';
        DigipoortServiceCertNameSetupErr: Label 'Digipoort Service Cert. Name must have a value in Elec. Tax Declaration Setup';
        InvalidDeliverUriFormatErr: Label 'Invalid URI: The format of the URI could not be determined.';
        InvalidGetStatusUriFormatErr: Label 'Invalid URI: The format of the URI could not be determined.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_ElecTaxDeclarationSetupSaaS()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // [SCENARIO 262526] The only "Digipoort Delivery URL" and "Digipoort Status URL" fields are mandatory in SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        asserterror ElecTaxDeclarationSetup.CheckDigipoortSetup();
        Assert.ExpectedError(DigipoortDeliveryURLSetupErr);

        ElecTaxDeclarationSetup."Digipoort Delivery URL" := LibraryUtility.GenerateGUID();

        asserterror ElecTaxDeclarationSetup.CheckDigipoortSetup();
        Assert.ExpectedError(DigipoortStatusURLSetupErr);

        ElecTaxDeclarationSetup."Digipoort Status URL" := LibraryUtility.GenerateGUID();

        ElecTaxDeclarationSetup.CheckDigipoortSetup();

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_ElecTaxDeclarationSetupOnPrem()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        // [SCENARIO 262526] Fields "Digipoort Client Cert. Name", "Digipoort Service Cert. Name", "Digipoort Delivery URL", "Digipoort Status URL" are mandatory in On-Premise
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        asserterror ElecTaxDeclarationSetup.CheckDigipoortSetup();
        Assert.ExpectedError(DigipoortClientCertNameSetupErr);

        ElecTaxDeclarationSetup."Digipoort Client Cert. Name" := LibraryUtility.GenerateGUID();

        asserterror ElecTaxDeclarationSetup.CheckDigipoortSetup();
        Assert.ExpectedError(DigipoortServiceCertNameSetupErr);

        ElecTaxDeclarationSetup."Digipoort Service Cert. Name" := LibraryUtility.GenerateGUID();

        asserterror ElecTaxDeclarationSetup.CheckDigipoortSetup();
        Assert.ExpectedError(DigipoortDeliveryURLSetupErr);

        ElecTaxDeclarationSetup."Digipoort Delivery URL" := LibraryUtility.GenerateGUID();

        asserterror ElecTaxDeclarationSetup.CheckDigipoortSetup();
        Assert.ExpectedError(DigipoortStatusURLSetupErr);

        ElecTaxDeclarationSetup."Digipoort Status URL" := LibraryUtility.GenerateGUID();

        ElecTaxDeclarationSetup.CheckDigipoortSetup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PageElecTaxDeclarationSetupSaaS()
    var
        ElecTaxDeclarationSetup: TestPage "Elec. Tax Declaration Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 262526] The only "Digipoort Delivery URL" and "Digipoort Status URL" fields must be visible on "Elec. Tax Declaration Setup" page in SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        ElecTaxDeclarationSetup.OpenView();
        Assert.IsFalse(ElecTaxDeclarationSetup."Digipoort Client Cert. Name".Visible(), 'Digipoort Client Cert. Name must be hidden');
        Assert.IsFalse(ElecTaxDeclarationSetup."Digipoort Service Cert. Name".Visible(), 'Digipoort Service Cert. Name must be hidden');
        Assert.IsTrue(ElecTaxDeclarationSetup."Digipoort Delivery URL".Visible(), 'Digipoort Delivery URL must be visible');
        Assert.IsTrue(ElecTaxDeclarationSetup."Digipoort Status URL".Visible(), 'Digipoort Status URL must be visible');
        ElecTaxDeclarationSetup.Close();

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PageElecTaxDeclarationSetupOnPrem()
    var
        ElecTaxDeclarationSetup: TestPage "Elec. Tax Declaration Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 262526] Fields "Digipoort Client Cert. Name", "Digipoort Service Cert. Name", "Digipoort Delivery URL", "Digipoort Status URL"
        // [SCENARIO 262526] must be visible on "Elec. Tax Declaration Setup" page in On-Premise
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        ElecTaxDeclarationSetup.OpenView();
        Assert.IsTrue(ElecTaxDeclarationSetup."Digipoort Client Cert. Name".Visible(), 'Digipoort Client Cert. Name must be visible');
        Assert.IsTrue(ElecTaxDeclarationSetup."Digipoort Service Cert. Name".Visible(), 'Digipoort Service Cert. Name must be visible');
        Assert.IsTrue(ElecTaxDeclarationSetup."Digipoort Delivery URL".Visible(), 'Digipoort Delivery URL must be visible');
        Assert.IsTrue(ElecTaxDeclarationSetup."Digipoort Status URL".Visible(), 'Digipoort Status URL must be visible');
        ElecTaxDeclarationSetup.Close();
    end;

    [Test]
    [HandlerFunctions('SubmitElecTaxDeclarationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CallSubmitElecTaxDeclarationRequestSaaS()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationCard: TestPage "Elec. Tax Declaration Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 262523] The only "Digipoort Delivery URL" and "Digipoort Status URL" fields must be visible on "Elec. Tax Declaration Setup" page in SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        MockElecTaxDeclarationSetupSaaS();
        MockElecTaxDeclarationHeader(ElecTaxDeclarationHeader);

        ElecTaxDeclarationCard.OpenEdit();
        ElecTaxDeclarationCard.GotoRecord(ElecTaxDeclarationHeader);
        ElecTaxDeclarationCard.SubmitElectronicTaxDeclaration.Invoke();

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CallSubmitElecTaxDeclarationRequestOnPrem()
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationCard: TestPage "Elec. Tax Declaration Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 262523] The only "Digipoort Delivery URL" and "Digipoort Status URL" fields must be visible on "Elec. Tax Declaration Setup" page in On-Premise
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        MockElecTaxDeclarationSetupOnPrem();
        MockElecTaxDeclarationHeader(ElecTaxDeclarationHeader);

        ElecTaxDeclarationCard.OpenEdit();
        ElecTaxDeclarationCard.GotoRecord(ElecTaxDeclarationHeader);
        asserterror ElecTaxDeclarationCard.SubmitElectronicTaxDeclaration.Invoke();
        Assert.ExpectedError(InvalidDeliverUriFormatErr);
    end;

    [Test]
    [HandlerFunctions('ReceiveResponseMessagesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CallReceiveResponseMessagestSaaS()
    var
        ElecTaxDeclResponseMsg: Record "Elec. Tax Decl. Response Msg.";
        ElecTaxDeclResponseMsgs: TestPage "Elec. Tax Decl. Response Msgs.";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 262523] The only "Digipoort Delivery URL" and "Digipoort Status URL" fields must be visible on "Elec. Tax Declaration Setup" page in SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        MockElecTaxDeclarationSetupSaaS();
        MockElecTaxDeclResponseMsg(ElecTaxDeclResponseMsg);

        ElecTaxDeclResponseMsgs.OpenEdit();
        ElecTaxDeclResponseMsgs.GotoRecord(ElecTaxDeclResponseMsg);
        ElecTaxDeclResponseMsgs.ReceiveResponseMessages.Invoke();

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CallReceiveResponseMessagestOnPrem()
    var
        ElecTaxDeclResponseMsg: Record "Elec. Tax Decl. Response Msg.";
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclResponseMsgs: TestPage "Elec. Tax Decl. Response Msgs.";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 262523] "Process Response Messages" action on page "Elec. Tax Decl. Response Msgs."
        // [SCENARIO 262523] calls report "Receive Response Messages" without request page in On-Premise mode
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        MockElecTaxDeclarationSetupOnPrem();
        MockElecTaxDeclarationHeader(ElecTaxDeclarationHeader);
        ElecTaxDeclarationHeader."Message ID" := LibraryUtility.GenerateGUID();
        ElecTaxDeclarationHeader.Modify();
        MockElecTaxDeclResponseMsg(ElecTaxDeclResponseMsg);

        ElecTaxDeclResponseMsgs.OpenEdit();
        ElecTaxDeclResponseMsgs.GotoRecord(ElecTaxDeclResponseMsg);
        asserterror ElecTaxDeclResponseMsgs.ReceiveResponseMessages.Invoke();
        Assert.ExpectedError(InvalidGetStatusUriFormatErr);
    end;

    local procedure MockElecTaxDeclarationSetupSaaS()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        ElecTaxDeclarationSetup.Get();
        ElecTaxDeclarationSetup."Digipoort Delivery URL" := LibraryUtility.GenerateGUID();
        ElecTaxDeclarationSetup."Digipoort Status URL" := LibraryUtility.GenerateGUID();
        ElecTaxDeclarationSetup.Modify();
    end;

    local procedure MockElecTaxDeclarationSetupOnPrem()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        ElecTaxDeclarationSetup.Get();
        ElecTaxDeclarationSetup."Digipoort Client Cert. Name" := LibraryUtility.GenerateGUID();
        ElecTaxDeclarationSetup."Digipoort Service Cert. Name" := LibraryUtility.GenerateGUID();
        ElecTaxDeclarationSetup."Digipoort Delivery URL" := LibraryUtility.GenerateGUID();
        ElecTaxDeclarationSetup."Digipoort Status URL" := LibraryUtility.GenerateGUID();
        ElecTaxDeclarationSetup.Modify();
    end;

    local procedure MockElecTaxDeclarationHeader(var ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header")
    begin
        ElecTaxDeclarationHeader.Init();
        ElecTaxDeclarationHeader."Declaration Type" := ElecTaxDeclarationHeader."Declaration Type"::"VAT Declaration";
        ElecTaxDeclarationHeader."No." := LibraryUtility.GenerateGUID();
        ElecTaxDeclarationHeader.Status := ElecTaxDeclarationHeader.Status::Created;
        ElecTaxDeclarationHeader.Insert();
    end;

    local procedure MockElecTaxDeclResponseMsg(var ElecTaxDeclResponseMsg: Record "Elec. Tax Decl. Response Msg.")
    begin
        ElecTaxDeclResponseMsg.Init();
        ElecTaxDeclResponseMsg."No." := LibraryUtility.GetNewRecNo(ElecTaxDeclResponseMsg, ElecTaxDeclResponseMsg.FieldNo("No."));
        ElecTaxDeclResponseMsg.Insert();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SubmitElecTaxDeclarationRequestPageHandler(var SubmitElecTaxDeclaration: TestRequestPage "Submit Elec. Tax Declaration")
    begin
        SubmitElecTaxDeclaration.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReceiveResponseMessagesRequestPageHandler(var ReceiveResponseMessages: TestRequestPage "Receive Response Messages")
    begin
        ReceiveResponseMessages.Cancel().Invoke();
    end;
}

