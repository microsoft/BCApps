// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.IO;
using System.TestLibraries.Utilities;

codeunit 139897 "E-Doc Purch. VAT Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;

    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryEDoc: Codeunit "Library - E-Document";
        EDocImplState: Codeunit "E-Doc. Impl. State";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;

    [Test]
    procedure PreparingPurchaseDraftResolvesVATProductPostingGroupFromLineVATRate()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        Vendor2: Record Vendor;
        CompanyInformation: Record "Company Information";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        EDocumentProcessing: Codeunit "E-Document Processing";
        EDocImport: Codeunit "E-Doc. Import";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // [SCENARIO] When a draft line has a VAT Rate and a matching VAT Posting Setup exists, Prepare Draft resolves the VAT Prod. Posting Group
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        // [GIVEN] A vendor with a known VAT Bus. Posting Group
        CompanyInformation.GetRecordOnce();
        Vendor2."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor2."No." := 'EDOC001';
        Vendor2."VAT Registration No." := 'XXXXXXX001';
        Vendor2."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        Vendor2.Insert();

        // [GIVEN] A VAT Posting Setup with VAT % = 10 for the vendor's bus posting group
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup2."VAT Bus. Posting Group" := Vendor2."VAT Bus. Posting Group";
        VATPostingSetup2."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup2."VAT Calculation Type" := VATPostingSetup2."VAT Calculation Type"::"Normal VAT";
        VATPostingSetup2."VAT %" := 10;
        VATPostingSetup2."Sales VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2."Purchase VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2.Insert();

        // [GIVEN] E-Document purchase header and line with VAT Rate = 10
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."Vendor VAT Id" := Vendor2."VAT Registration No.";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine.Description := 'Test VAT resolution';
        EDocumentPurchaseLine."VAT Rate" := 10;
        EDocumentPurchaseLine.Insert();

        // [WHEN] Prepare Draft is run
        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::"Ready for draft");
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        // [THEN] The VAT Prod. Posting Group is resolved from the matching setup
        EDocumentPurchaseLine.SetRecFilter();
        EDocumentPurchaseLine.FindFirst();
        Assert.AreEqual(VATProductPostingGroup.Code, EDocumentPurchaseLine."[BC] VAT Prod. Posting Group", 'The VAT Prod. Posting Group should be resolved from the matching VAT Posting Setup.');
        Assert.IsFalse(EDocumentPurchaseLine."[BC] VAT Rate Mismatch", 'VAT Rate Mismatch should be false when resolution succeeds.');

        // Cleanup
        Vendor2.SetRecFilter();
        Vendor2.Delete();
        VATPostingSetup2.SetRecFilter();
        VATPostingSetup2.Delete();
        VATProductPostingGroup.SetRecFilter();
        VATProductPostingGroup.Delete();
    end;

    [Test]
    procedure PreparingPurchaseDraftSetsVATRateMismatchWhenNoMatchingVATSetup()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        Vendor2: Record Vendor;
        CompanyInformation: Record "Company Information";
        EDocumentProcessing: Codeunit "E-Document Processing";
        EDocImport: Codeunit "E-Doc. Import";
    begin
        // [SCENARIO] When a draft line has a VAT Rate but no matching VAT Posting Setup exists, Prepare Draft leaves the field blank and sets the mismatch flag
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        // [GIVEN] A vendor with a known VAT Bus. Posting Group
        CompanyInformation.GetRecordOnce();
        Vendor2."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor2."No." := 'EDOC001';
        Vendor2."VAT Registration No." := 'XXXXXXX001';
        Vendor2."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        Vendor2.Insert();

        // [GIVEN] E-Document purchase header and line with VAT Rate = 99 (no matching setup)
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."Vendor VAT Id" := Vendor2."VAT Registration No.";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine.Description := 'Test VAT mismatch';
        EDocumentPurchaseLine."VAT Rate" := 99;
        EDocumentPurchaseLine.Insert();

        // [WHEN] Prepare Draft is run
        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::"Ready for draft");
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        // [THEN] The VAT Prod. Posting Group is blank and mismatch flag is set
        EDocumentPurchaseLine.SetRecFilter();
        EDocumentPurchaseLine.FindFirst();
        Assert.AreEqual('', EDocumentPurchaseLine."[BC] VAT Prod. Posting Group", 'The VAT Prod. Posting Group should be blank when no matching VAT Posting Setup exists.');
        Assert.IsTrue(EDocumentPurchaseLine."[BC] VAT Rate Mismatch", 'VAT Rate Mismatch should be true when resolution fails.');

        // Cleanup
        Vendor2.SetRecFilter();
        Vendor2.Delete();
    end;

    [Test]
    procedure PreparingDraftIgnoresFullVATSetupWhenResolvingPostingGroup()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        Vendor2: Record Vendor;
        CompanyInformation: Record "Company Information";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        EDocumentProcessing: Codeunit "E-Document Processing";
        EDocImport: Codeunit "E-Doc. Import";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // [SCENARIO] Full VAT setups must not be matched during VAT Posting Group resolution
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        // [GIVEN] A vendor
        CompanyInformation.GetRecordOnce();
        Vendor2."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor2."No." := 'EDOC001';
        Vendor2."VAT Registration No." := 'XXXXXXX001';
        Vendor2."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        Vendor2.Insert();

        // [GIVEN] A Full VAT Posting Setup with VAT % = 10
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup2."VAT Bus. Posting Group" := Vendor2."VAT Bus. Posting Group";
        VATPostingSetup2."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup2."VAT Calculation Type" := VATPostingSetup2."VAT Calculation Type"::"Full VAT";
        VATPostingSetup2."VAT %" := 10;
        VATPostingSetup2."Sales VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2."Purchase VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2.Insert();

        // [GIVEN] E-Document line with VAT Rate = 10
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."Vendor VAT Id" := Vendor2."VAT Registration No.";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine.Description := 'Test Full VAT ignored';
        EDocumentPurchaseLine."VAT Rate" := 10;
        EDocumentPurchaseLine.Insert();

        // [WHEN] Prepare Draft is run
        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::"Ready for draft");
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        // [THEN] Full VAT setup is not matched
        EDocumentPurchaseLine.SetRecFilter();
        EDocumentPurchaseLine.FindFirst();
        Assert.AreEqual('', EDocumentPurchaseLine."[BC] VAT Prod. Posting Group", 'Full VAT setups must not be matched.');
        Assert.IsTrue(EDocumentPurchaseLine."[BC] VAT Rate Mismatch", 'VAT Rate Mismatch should be true when only Full VAT setups exist.');

        // Cleanup
        Vendor2.SetRecFilter();
        Vendor2.Delete();
        VATPostingSetup2.SetRecFilter();
        VATPostingSetup2.Delete();
        VATProductPostingGroup.SetRecFilter();
        VATProductPostingGroup.Delete();
    end;

    [Test]
    procedure PreparingDraftIgnoresSalesTaxSetupWhenResolvingPostingGroup()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        Vendor2: Record Vendor;
        CompanyInformation: Record "Company Information";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        EDocumentProcessing: Codeunit "E-Document Processing";
        EDocImport: Codeunit "E-Doc. Import";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // [SCENARIO] Sales Tax setups must not be matched during VAT Posting Group resolution
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        // [GIVEN] A vendor
        CompanyInformation.GetRecordOnce();
        Vendor2."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor2."No." := 'EDOC001';
        Vendor2."VAT Registration No." := 'XXXXXXX001';
        Vendor2."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        Vendor2.Insert();

        // [GIVEN] A Sales Tax Posting Setup with VAT % = 10
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup2."VAT Bus. Posting Group" := Vendor2."VAT Bus. Posting Group";
        VATPostingSetup2."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup2."VAT Calculation Type" := VATPostingSetup2."VAT Calculation Type"::"Sales Tax";
        VATPostingSetup2."VAT %" := 10;
        VATPostingSetup2."Sales VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2."Purchase VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2.Insert();

        // [GIVEN] E-Document line with VAT Rate = 10
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."Vendor VAT Id" := Vendor2."VAT Registration No.";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine.Description := 'Test Sales Tax ignored';
        EDocumentPurchaseLine."VAT Rate" := 10;
        EDocumentPurchaseLine.Insert();

        // [WHEN] Prepare Draft is run
        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::"Ready for draft");
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        // [THEN] Sales Tax setup is not matched
        EDocumentPurchaseLine.SetRecFilter();
        EDocumentPurchaseLine.FindFirst();
        Assert.AreEqual('', EDocumentPurchaseLine."[BC] VAT Prod. Posting Group", 'Sales Tax setups must not be matched.');
        Assert.IsTrue(EDocumentPurchaseLine."[BC] VAT Rate Mismatch", 'VAT Rate Mismatch should be true when only Sales Tax setups exist.');

        // Cleanup
        Vendor2.SetRecFilter();
        Vendor2.Delete();
        VATPostingSetup2.SetRecFilter();
        VATPostingSetup2.Delete();
        VATProductPostingGroup.SetRecFilter();
        VATProductPostingGroup.Delete();
    end;

    [Test]
    procedure PreparingDraftResolvesReverseChargeVATPostingGroup()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        Vendor2: Record Vendor;
        CompanyInformation: Record "Company Information";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        EDocumentProcessing: Codeunit "E-Document Processing";
        EDocImport: Codeunit "E-Doc. Import";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // [SCENARIO] Reverse Charge VAT setups should be matched during VAT Posting Group resolution
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        // [GIVEN] A vendor
        CompanyInformation.GetRecordOnce();
        Vendor2."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor2."No." := 'EDOC001';
        Vendor2."VAT Registration No." := 'XXXXXXX001';
        Vendor2."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        Vendor2.Insert();

        // [GIVEN] A Reverse Charge VAT Posting Setup with VAT % = 20
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup2."VAT Bus. Posting Group" := Vendor2."VAT Bus. Posting Group";
        VATPostingSetup2."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup2."VAT Calculation Type" := VATPostingSetup2."VAT Calculation Type"::"Reverse Charge VAT";
        VATPostingSetup2."VAT %" := 20;
        VATPostingSetup2."Sales VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2."Purchase VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2."Reverse Chrg. VAT Acc." := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2.Insert();

        // [GIVEN] E-Document line with VAT Rate = 20
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."Vendor VAT Id" := Vendor2."VAT Registration No.";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine.Description := 'Test Reverse Charge resolved';
        EDocumentPurchaseLine."VAT Rate" := 20;
        EDocumentPurchaseLine.Insert();

        // [WHEN] Prepare Draft is run
        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::"Ready for draft");
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        // [THEN] Reverse Charge VAT setup is matched
        EDocumentPurchaseLine.SetRecFilter();
        EDocumentPurchaseLine.FindFirst();
        Assert.AreEqual(VATProductPostingGroup.Code, EDocumentPurchaseLine."[BC] VAT Prod. Posting Group", 'Reverse Charge VAT setups should be matched.');
        Assert.IsFalse(EDocumentPurchaseLine."[BC] VAT Rate Mismatch", 'VAT Rate Mismatch should be false when Reverse Charge VAT matches.');

        // Cleanup
        Vendor2.SetRecFilter();
        Vendor2.Delete();
        VATPostingSetup2.SetRecFilter();
        VATPostingSetup2.Delete();
        VATProductPostingGroup.SetRecFilter();
        VATProductPostingGroup.Delete();
    end;

    [Test]
    procedure ValidatingVATProdPostingGroupClearsMismatchWhenRateMatches()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        Vendor2: Record Vendor;
        CompanyInformation: Record "Company Information";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // [SCENARIO] OnValidate clears mismatch when selected posting group's VAT % matches the line's VAT Rate
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        // [GIVEN] A vendor
        CompanyInformation.GetRecordOnce();
        Vendor2."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor2."No." := 'EDOC001';
        Vendor2."VAT Registration No." := 'XXXXXXX001';
        Vendor2."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        Vendor2.Insert();

        // [GIVEN] A Normal VAT setup with VAT % = 20
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup2."VAT Bus. Posting Group" := Vendor2."VAT Bus. Posting Group";
        VATPostingSetup2."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup2."VAT Calculation Type" := VATPostingSetup2."VAT Calculation Type"::"Normal VAT";
        VATPostingSetup2."VAT %" := 20;
        VATPostingSetup2."Sales VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2."Purchase VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2.Insert();

        // [GIVEN] A line with VAT Rate = 20 and mismatch = true
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor2."No.";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine."VAT Rate" := 20;
        EDocumentPurchaseLine."[BC] VAT Rate Mismatch" := true;
        EDocumentPurchaseLine.Insert();

        // [WHEN] User validates the posting group to the matching setup
        EDocumentPurchaseLine.Validate("[BC] VAT Prod. Posting Group", VATProductPostingGroup.Code);
        EDocumentPurchaseLine.Modify();

        // [THEN] Mismatch is cleared
        Assert.IsFalse(EDocumentPurchaseLine."[BC] VAT Rate Mismatch", 'Mismatch should be false when VAT % matches VAT Rate.');

        // Cleanup
        Vendor2.SetRecFilter();
        Vendor2.Delete();
        VATPostingSetup2.SetRecFilter();
        VATPostingSetup2.Delete();
        VATProductPostingGroup.SetRecFilter();
        VATProductPostingGroup.Delete();
    end;

    [Test]
    procedure ValidatingVATProdPostingGroupKeepsMismatchWhenRateDiffers()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        Vendor2: Record Vendor;
        CompanyInformation: Record "Company Information";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // [SCENARIO] OnValidate keeps mismatch when selected posting group's VAT % differs from VAT Rate
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        // [GIVEN] A vendor
        CompanyInformation.GetRecordOnce();
        Vendor2."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor2."No." := 'EDOC001';
        Vendor2."VAT Registration No." := 'XXXXXXX001';
        Vendor2."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        Vendor2.Insert();

        // [GIVEN] A Normal VAT setup with VAT % = 10 (different from line's 20)
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup2."VAT Bus. Posting Group" := Vendor2."VAT Bus. Posting Group";
        VATPostingSetup2."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup2."VAT Calculation Type" := VATPostingSetup2."VAT Calculation Type"::"Normal VAT";
        VATPostingSetup2."VAT %" := 10;
        VATPostingSetup2."Sales VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2."Purchase VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2.Insert();

        // [GIVEN] A line with VAT Rate = 20 and mismatch = true
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor2."No.";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine."VAT Rate" := 20;
        EDocumentPurchaseLine."[BC] VAT Rate Mismatch" := true;
        EDocumentPurchaseLine.Insert();

        // [WHEN] User validates the posting group to a non-matching setup
        EDocumentPurchaseLine.Validate("[BC] VAT Prod. Posting Group", VATProductPostingGroup.Code);
        EDocumentPurchaseLine.Modify();

        // [THEN] Mismatch remains true
        Assert.IsTrue(EDocumentPurchaseLine."[BC] VAT Rate Mismatch", 'Mismatch should remain true when VAT % does not match VAT Rate.');

        // Cleanup
        Vendor2.SetRecFilter();
        Vendor2.Delete();
        VATPostingSetup2.SetRecFilter();
        VATPostingSetup2.Delete();
        VATProductPostingGroup.SetRecFilter();
        VATProductPostingGroup.Delete();
    end;

    [Test]
    procedure ValidatingVATProdPostingGroupSetsMismatchWhenCleared()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        // [SCENARIO] OnValidate sets mismatch when posting group is cleared
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        // [GIVEN] A line with VAT Rate = 20, a posting group, and no mismatch
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine."VAT Rate" := 20;
        EDocumentPurchaseLine."[BC] VAT Prod. Posting Group" := 'STANDARD';
        EDocumentPurchaseLine."[BC] VAT Rate Mismatch" := false;
        EDocumentPurchaseLine.Insert();

        // [WHEN] User clears the posting group
        EDocumentPurchaseLine.Validate("[BC] VAT Prod. Posting Group", '');
        EDocumentPurchaseLine.Modify();

        // [THEN] Mismatch is set
        Assert.IsTrue(EDocumentPurchaseLine."[BC] VAT Rate Mismatch", 'Mismatch should be true when posting group is cleared.');
    end;

    [Test]
    procedure ValidatingVATProdPostingGroupSkipsMismatchForFullVAT()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        Vendor2: Record Vendor;
        CompanyInformation: Record "Company Information";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // [SCENARIO] OnValidate skips mismatch evaluation for Full VAT — flag stays unchanged
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        // [GIVEN] A vendor
        CompanyInformation.GetRecordOnce();
        Vendor2."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor2."No." := 'EDOC001';
        Vendor2."VAT Registration No." := 'XXXXXXX001';
        Vendor2."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        Vendor2.Insert();

        // [GIVEN] A Full VAT setup with VAT % = 0
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup2."VAT Bus. Posting Group" := Vendor2."VAT Bus. Posting Group";
        VATPostingSetup2."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup2."VAT Calculation Type" := VATPostingSetup2."VAT Calculation Type"::"Full VAT";
        VATPostingSetup2."VAT %" := 0;
        VATPostingSetup2."Sales VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2."Purchase VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2.Insert();

        // [GIVEN] A line with VAT Rate = 5 and mismatch = false
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor2."No.";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine."VAT Rate" := 5;
        EDocumentPurchaseLine."[BC] VAT Rate Mismatch" := false;
        EDocumentPurchaseLine.Insert();

        // [WHEN] User validates the posting group to the Full VAT setup
        EDocumentPurchaseLine.Validate("[BC] VAT Prod. Posting Group", VATProductPostingGroup.Code);
        EDocumentPurchaseLine.Modify();

        // [THEN] Mismatch flag is unchanged (still false) — Full VAT skips comparison
        Assert.IsFalse(EDocumentPurchaseLine."[BC] VAT Rate Mismatch", 'Mismatch should remain unchanged for Full VAT calculation type.');

        // Cleanup
        Vendor2.SetRecFilter();
        Vendor2.Delete();
        VATPostingSetup2.SetRecFilter();
        VATPostingSetup2.Delete();
        VATProductPostingGroup.SetRecFilter();
        VATProductPostingGroup.Delete();
    end;

    [Test]
    procedure ValidatingVATProdPostingGroupMatchesZeroRate()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        Vendor2: Record Vendor;
        CompanyInformation: Record "Company Information";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // [SCENARIO] OnValidate clears mismatch when both VAT Rate and VAT % are 0
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        // [GIVEN] A vendor
        CompanyInformation.GetRecordOnce();
        Vendor2."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor2."No." := 'EDOC001';
        Vendor2."VAT Registration No." := 'XXXXXXX001';
        Vendor2."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        Vendor2.Insert();

        // [GIVEN] A Normal VAT setup with VAT % = 0 (zero-rated)
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup2."VAT Bus. Posting Group" := Vendor2."VAT Bus. Posting Group";
        VATPostingSetup2."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup2."VAT Calculation Type" := VATPostingSetup2."VAT Calculation Type"::"Normal VAT";
        VATPostingSetup2."VAT %" := 0;
        VATPostingSetup2."Sales VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2."Purchase VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2.Insert();

        // [GIVEN] A line with VAT Rate = 0
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor2."No.";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine."VAT Rate" := 0;
        EDocumentPurchaseLine."[BC] VAT Rate Mismatch" := true;
        EDocumentPurchaseLine.Insert();

        // [WHEN] User validates the posting group to the zero-rated setup
        EDocumentPurchaseLine.Validate("[BC] VAT Prod. Posting Group", VATProductPostingGroup.Code);
        EDocumentPurchaseLine.Modify();

        // [THEN] Mismatch is cleared — both rates are 0
        Assert.IsFalse(EDocumentPurchaseLine."[BC] VAT Rate Mismatch", 'Mismatch should be false when both VAT Rate and VAT % are 0.');

        // Cleanup
        Vendor2.SetRecFilter();
        Vendor2.Delete();
        VATPostingSetup2.SetRecFilter();
        VATPostingSetup2.Delete();
        VATProductPostingGroup.SetRecFilter();
        VATProductPostingGroup.Delete();
    end;

    local procedure Initialize(Integration: Enum "Service Integration")
    var
        TransformationRule: Record "Transformation Rule";
        EDocument: Record "E-Document";
        EDocDataStorage: Record "E-Doc. Data Storage";
        EDocumentServiceStatus: Record "E-Document Service Status";
        EDocPurchLineFieldSetup: Record "ED Purchase Line Field Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryLowerPermission.SetOutsideO365Scope();
        LibraryVariableStorage.Clear();
        Clear(EDocImplState);
        EDocPurchLineFieldSetup.DeleteAll();

        PurchInvHeader.DeleteAll();
        VendorLedgerEntry.DeleteAll();

        if IsInitialized then
            exit;

        GLSetup.GetRecordOnce();
        GLSetup."VAT Reporting Date Usage" := GLSetup."VAT Reporting Date Usage"::Disabled;
        GLSetup.Modify();

        // Set a currency that can be used across all localizations
        Currency.Init();
        Currency.Validate(Code, 'XYZ');
        if Currency.Insert(true) then
            LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), 1.0, 1.0);

        EDocument.DeleteAll();
        EDocumentServiceStatus.DeleteAll();
        EDocumentService.DeleteAll();
        EDocDataStorage.DeleteAll();

        LibraryEDoc.SetupStandardVAT();
        LibraryEDoc.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::Mock, Integration);
        LibraryEDoc.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::Mock, Integration);
        EDocumentService."Import Process" := "E-Document Import Process"::"Version 2.0";
        EDocumentService."Read into Draft Impl." := "E-Doc. Read into Draft"::PEPPOL;
        EDocumentService.Modify();

        TransformationRule.DeleteAll();
        TransformationRule.CreateDefaultTransformations();

        IsInitialized := true;
    end;
}
