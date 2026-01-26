codeunit 144048 "UT PAG EVAT"
{
    // 1. Purpose of the test is to validate error on GetCATaxAuthCertificates  - OnAction of Page - 11410 (Elec. Tax Declaration Setup) with Invalid Password on Get Certificates Report.
    // 2. Purpose of the test is to validate error on GetCATaxAuthCertificates  - OnAction of Page - 11410 (Elec. Tax Declaration Setup) with Status as Submitted on Elec. Tax Declaration Header.
    // 3. Purpose of the test is to verify Sign Method - OnValidate of Page - 11410 (Elec. Tax Declaration Setup) with PIN Sign Method.
    // 4. Purpose of this test is to validate Category on page 11414(Elec. Tax Decl. VAT Categ.).
    // 5. Purpose of the test is to verify OnAfterGetRecord of Page - 11411 (Elec. Tax Declaration Card).
    // 6. Purpose of the test is to verify ReceiveResponseMessages - OnAction of Page - 11416 (Elec. Tax Decl. Response Msgs).
    // 7. Purpose of the test is to verify ProcessResponseMessages - OnAction of Page - 11416 (Elec. Tax Decl. Response Msgs).
    // 8. Purpose of the test is to verify RequestUserCertificates - OnAction of Page - 11417 (User Certificate List).
    // 9. Purpose of the test is to verify ImportUserCertificate - OnAction of Page - 11417 (User Certificate List).
    // 
    // Covers Test Cases for WI - 343288
    // ----------------------------------------------------------------------------
    // Test Function Name                                                    TFS ID
    // ----------------------------------------------------------------------------
    // OnValidateSignMethodElecTaxDeclarationSetup                           171574
    // 
    // Covers Test Cases for WI - 343295
    // ----------------------------------------------------------------------------
    // Test Function Name                                                    TFS ID
    // ----------------------------------------------------------------------------
    // OnValidateCategoryElecTaxDeclarationVATCategory                       171549
    // 
    // Covers Test Cases for WI - 343619
    // ----------------------------------------------------------------------------
    // Test Function Name                                                    TFS ID
    // ----------------------------------------------------------------------------
    // OnAfterGetRecordElecTaxDeclarationCard                         171654,171665
    // 
    // Covers Test Cases for WI - 343950
    // ----------------------------------------------------------------------------
    // Test Function Name                                                    TFS ID
    // ----------------------------------------------------------------------------
    // OnActionReceiveElecTaxDeclResponseMsgsError
    // OnActionProcessElecTaxDeclResponseMsgs
    // OnActionRequestUserCertificatesList
    // OnActionImportUserCertificateList

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUTUtility: Codeunit "Library UT Utility";
        FieldEnabledMsg: Label '%1 must not be enabled';
        FieldEditableMsg: Label '%1 must be editable';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        ValueEqualMsg: Label 'Value must be equal.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCategoryElecTaxDeclarationVATCategory()
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
        ElecTaxDeclVATCateg: TestPage "Elec. Tax Decl. VAT Categ.";
    begin
        // Purpose of this test is to validate Category on page 11414(Elec. Tax Decl. VAT Categ.).

        // Setup.
        Initialize();
        ElecTaxDeclVATCateg.OpenEdit();

        // Exercise.
        ElecTaxDeclVATCateg.Category.SetValue(ElecTaxDeclVATCategory.Category::"5. Calculation");

        // Verify: Verify the Editable property of Calculation when the Category is set to "5. Calculation".
        Assert.IsTrue(ElecTaxDeclVATCateg.Calculation.Editable(), StrSubstNo(FieldEditableMsg, ElecTaxDeclVATCateg.Calculation.Caption));
        ElecTaxDeclVATCateg.Close();
    end;

    [Test]
    [HandlerFunctions('CreateElecVATDeclarationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordElecTaxDeclarationCard()
    var
        VATStatementName: Record "VAT Statement Name";
        ElecTaxDeclarationCard: TestPage "Elec. Tax Declaration Card";
        No: Code[20];
    begin
        // Purpose of the test is to verify OnAfterGetRecord of Page - 11411 (Elec. Tax Declaration Card).
        // Setup.
        Initialize();
        VATStatementName.FindFirst();
        No := CreateElectronicTaxDeclarationHeader();
        CreateVATStatementLine(VATStatementName);
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");  // Enqueue value for CreateElecVATDeclarationRequestPageHandler.
        LibraryVariableStorage.Enqueue(VATStatementName.Name);  // Enqueue value for CreateElecVATDeclarationRequestPageHandler.
        ElecTaxDeclarationCard.OpenEdit();
        ElecTaxDeclarationCard.FILTER.SetFilter("No.", No);

        // Exercise.
        ElecTaxDeclarationCard.CreateElectronicTaxDeclaration.Invoke();

        // Verify: Verify Our Reference, Declaration Period and Declaration Year is not enable and Status is Created on Elec. Tax Declaration Card.
        ElecTaxDeclarationCard.Status.AssertEquals(ElecTaxDeclarationCard.Status.GetOption(2));  // 2 is for Option String Created.
        Assert.IsFalse(
          ElecTaxDeclarationCard."Our Reference".Editable(), StrSubstNo(FieldEnabledMsg, ElecTaxDeclarationCard."Our Reference".Caption));
        Assert.IsFalse(
          ElecTaxDeclarationCard."Declaration Period".Editable(),
          StrSubstNo(FieldEnabledMsg, ElecTaxDeclarationCard."Declaration Period".Caption));
        Assert.IsFalse(
          ElecTaxDeclarationCard."Declaration Year".Editable(), StrSubstNo(FieldEnabledMsg, ElecTaxDeclarationCard."Declaration Year".Caption));
        ElecTaxDeclarationCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionReceiveElecTaxDeclResponseMsgsError()
    var
        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclRespMsg: Record "Elec. Tax Decl. Response Msg.";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        ElecTaxDeclResponseMsgs: TestPage "Elec. Tax Decl. Response Msgs.";
    begin
        // Purpose of the test is to verify ReceiveResponseMessages - OnAction of Page - 11416 (Elec. Tax Decl. Response Msgs).
        // Setup.
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        ElecTaxDeclHeader.DeleteAll(); // Ensure no declarations are processed
        ElecTaxDeclRespMsg.DeleteAll();
        ElecTaxDeclResponseMsgs.OpenEdit();

        // Exercise.
        ElecTaxDeclResponseMsgs.ReceiveResponseMessages.Invoke();  // Opens ReceiveResponseMessagesRequestPageHandler.

        // Verify: No response lines are fetched
        Assert.AreEqual(0, ElecTaxDeclRespMsg.Count, ValueEqualMsg);
        ElecTaxDeclResponseMsgs.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionProcessElecTaxDeclResponseMsgs()
    var
        ElecTaxDeclResponseMsgs: TestPage "Elec. Tax Decl. Response Msgs.";
    begin
        // Purpose of the test is to verify ProcessResponseMessages - OnAction of Page - 11416 (Elec. Tax Decl. Response Msgs).
        // Setup.
        Initialize();
        ElecTaxDeclResponseMsgs.OpenEdit();

        // Exercise.
        ElecTaxDeclResponseMsgs.ProcessResponseMessages.Invoke();  // Opens ProcessResponseMessagesReportHandler.

        // Verify: Verify report Process Response Messages run successfully and handled in ProcessResponseMessagesReportHandler.
        ElecTaxDeclResponseMsgs.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnPageOpenShowElementOnly()
    var
        ElecTaxDeclLine: Record "Elec. Tax Declaration Line";
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationCard: TestPage "Elec. Tax Declaration Card";
        No: Code[20];
    begin
        // Purpose is to verify only elements of the XML declaration are shown (attributes are hidden when filter is enabled)

        // Setup
        Initialize();
        No := CreateElectronicTaxDeclarationHeader();
        ElecTaxDeclarationHeader.Get(ElecTaxDeclarationHeader."Declaration Type"::"VAT Declaration", No);
        CreateDeclarationLine(No, 'lineA', ElecTaxDeclLine."Line Type"::Element, 0);
        CreateDeclarationLine(No, 'lineB', ElecTaxDeclLine."Line Type"::Attribute, 1);
        CreateDeclarationLine(No, 'lineC', ElecTaxDeclLine."Line Type"::Element, 1);
        CreateDeclarationLine(No, 'lineD', ElecTaxDeclLine."Line Type"::Attribute, 2);

        // Exercise: Open page
        ElecTaxDeclLine.Reset();
        ElecTaxDeclarationCard.OpenEdit();
        ElecTaxDeclarationCard.GotoRecord(ElecTaxDeclarationHeader);

        // Verify: Check filter only shows elements
        Assert.AreEqual('0', ElecTaxDeclarationCard.Control1000017.FILTER.GetFilter("Line Type"), ValueEqualMsg);
        Assert.AreEqual(2, CountDeclLinesPageRows(ElecTaxDeclarationCard), ValueEqualMsg);

        ElecTaxDeclarationCard.Control1000017.FILTER.SetFilter("Line Type", '');
        Assert.AreEqual(4, CountDeclLinesPageRows(ElecTaxDeclarationCard), ValueEqualMsg);
        ElecTaxDeclarationCard.Close();
    end;

    local procedure Initialize()
    var
        ElecTaxDeclSetup: Record "Elec. Tax Declaration Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT PAG EVAT");
        LibraryVariableStorage.Clear();

        if not ElecTaxDeclSetup.Get() then begin
            ElecTaxDeclSetup.Init();
            ElecTaxDeclSetup.Insert(true);
        end;

        ElecTaxDeclSetup."Digipoort Client Cert. Name" := 'abcde';
        ElecTaxDeclSetup."Digipoort Service Cert. Name" := 'fghij';
        ElecTaxDeclSetup."Digipoort Delivery URL" := 'http://url.com';
        ElecTaxDeclSetup."Digipoort Status URL" := 'http://url.com';
        ElecTaxDeclSetup.Modify(true);
    end;

    local procedure CreateElectronicTaxDeclarationHeader(): Code[20]
    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
    begin
        ElecTaxDeclarationHeader."Declaration Type" := ElecTaxDeclarationHeader."Declaration Type"::"VAT Declaration";
        ElecTaxDeclarationHeader."No." := LibraryUTUtility.GetNewCode10();
        ElecTaxDeclarationHeader."Declaration Period" := ElecTaxDeclarationHeader."Declaration Period"::Year;
        ElecTaxDeclarationHeader."Declaration Year" := LibraryRandom.RandInt(10);
        ElecTaxDeclarationHeader."Our Reference" := LibraryUTUtility.GetNewCode10();
        ElecTaxDeclarationHeader.Insert();
        exit(ElecTaxDeclarationHeader."No.");
    end;

    local procedure CreateVATStatementLine(VATStatementName: Record "VAT Statement Name")
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        VATStatementLine."Statement Template Name" := VATStatementName."Statement Template Name";
        VATStatementLine."Statement Name" := VATStatementName.Name;
        VATStatementLine."Line No." := LibraryRandom.RandInt(10);
        VATStatementLine."Elec. Tax Decl. Category Code" := '5g';  // Using Hard Code Value '5G' of Electronic Tax Declaraton VAT Category table for Calculation.
        VATStatementLine.Insert();
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

    local procedure CreateDeclarationLine(DeclarationNo: Code[20]; Data: Text; LineType: Option; Identation: Integer)
    var
        ElecTaxDeclLine: Record "Elec. Tax Declaration Line";
    begin
        ElecTaxDeclLine.Init();
        ElecTaxDeclLine."Declaration Type" := ElecTaxDeclLine."Declaration Type"::"VAT Declaration";
        ElecTaxDeclLine."Declaration No." := DeclarationNo;
        ElecTaxDeclLine.Data := CopyStr(Data, 1, MaxStrLen(ElecTaxDeclLine.Data));
        ElecTaxDeclLine."Indentation Level" := Identation;
        ElecTaxDeclLine."Line Type" := LineType;
        ElecTaxDeclLine.Name := LibraryUTUtility.GetNewCode10();
        ElecTaxDeclLine.Insert(true);
    end;

    local procedure CountDeclLinesPageRows(var CardPage: TestPage "Elec. Tax Declaration Card"): Integer
    var
        "Count": Integer;
    begin
        Count := 0;
        if CardPage.Control1000017.First() then begin
            Count += 1;
            while CardPage.Control1000017.Next() do
                Count += 1;
        end;
        exit(Count);
    end;
}

