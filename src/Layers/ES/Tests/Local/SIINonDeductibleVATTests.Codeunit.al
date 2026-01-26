codeunit 147545 "SII Non-Deductible VAT Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Non-Deductible VAT]
    end;

    var
        LibraryNonDedVAT: Codeunit "Library - NonDeductible VAT";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibrarySII: Codeunit "Library - SII";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        UploadType: Option Regular,Intracommunity,RetryAccepted;
        XPathPurchBaseImponibleTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida/sii:DesgloseFactura/sii:DesgloseIVA/sii:DetalleIVA';
        IncorrectXMLDocErr: Label 'The XML document was not generated properly.';

    [Test]
    procedure PurchInvWithNonDedVAT()
    var
        PurchaseLine: Record "Purchase Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 483627] SII functionality considers Non-Deductible VAT for Purchase invoices

        Initialize();
        // [GIVEN] Posted purchase invoice with Non-Deductible VAT = 30%. Amount = 1000, VAT % = 25"
        // [GIVEN] VAT Entry has Base = 700, Non-Deductible VAT Base = 300, Amount = 175, Non-Deductible VAT Amount = 75
        LibraryERM.FindVendorLedgerEntry(
          VendLedgEntry, VendLedgEntry."Document Type"::Invoice,
          PostPurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice, 0));

        // [WHEN] Create xml for the document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendLedgEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:BaseImponible node for the Full VAT base = 1000
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, '/sii:BaseImponible', SIIXMLCreator.FormatNumber(PurchaseLine."VAT Base Amount"));

        // [THEN] XML file has sii:CuotaSoportada node for the Full VAT Amount = 250
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, '/sii:CuotaSoportada', SIIXMLCreator.FormatNumber(PurchaseLine."Amount Including VAT" - PurchaseLine.Amount));
    end;

    [Test]
    procedure PurchCrMemoWithNonDedVAT()
    var
        PurchaseLine: Record "Purchase Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 483627] SII functionality considers Non-Deductible VAT for Purchase credit memos

        Initialize();
        // [GIVEN] Posted credit memo invoice with Non-Deductible VAT = 30%. Amount = 1000, VAT % = 25"
        // [GIVEN] VAT Entry has Base = 700, Non-Deductible VAT Base = 300, Amount = 175, Non-Deductible VAT Amount = 75
        LibraryERM.FindVendorLedgerEntry(
          VendLedgEntry, VendLedgEntry."Document Type"::"Credit Memo",
          PostPurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", 0));

        // [WHEN] Create xml for the document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendLedgEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:BaseImponible node for the Full VAT base = -1000
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, '/sii:BaseImponible', SIIXMLCreator.FormatNumber(-PurchaseLine."VAT Base Amount"));

        // [THEN] XML file has sii:CuotaSoportada node for the Full VAT Amount = -250
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, '/sii:CuotaSoportada', SIIXMLCreator.FormatNumber(-PurchaseLine."Amount Including VAT" + PurchaseLine.Amount));
    end;

    [Test]
    procedure PurchReplacementCrMemoWithNonDedVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 483627] SII functionality considers Non-Deductible VAT for Purchase replacement credit memos

        Initialize();
        // [GIVEN] Posted replacement credit memo invoice with Non-Deductible VAT = 30%. Amount = 1000, VAT % = 25"
        // [GIVEN] VAT Entry has Base = 700, Non-Deductible VAT Base = 300, Amount = 175, Non-Deductible VAT Amount = 75
        LibraryERM.FindVendorLedgerEntry(
          VendLedgEntry, VendLedgEntry."Document Type"::"Credit Memo",
          PostPurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Replacement));

        // [WHEN] Create xml for the document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendLedgEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:BaseImponible node for the Full VAT base = -1000
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, '/sii:BaseImponible', SIIXMLCreator.FormatNumber(-PurchaseLine."VAT Base Amount"));

        // [THEN] XML file has sii:CuotaSoportada node for the Full VAT Amount = -250
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, '/sii:CuotaSoportada', SIIXMLCreator.FormatNumber(-PurchaseLine."Amount Including VAT" + PurchaseLine.Amount));
    end;

    local procedure Initialize()
    var
        VATSetup: Record "VAT Setup";
    begin
        LibrarySetupStorage.Restore();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SII Non-Deductible VAT Tests");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SII Non-Deductible VAT Tests");
        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue();
        VATSetup."Enable Non-Deductible VAT" := true;
        VATSetup.Modify();
        LibrarySetupStorage.Save(Database::"VAT Setup");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SII Non-Deductible VAT Tests");
    end;

    local procedure PostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; CorrType: Option): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryNonDedVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, DocType, LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Correction Type", CorrType);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;
}

