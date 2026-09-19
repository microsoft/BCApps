// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.History;
using System.TestLibraries.Upgrade;
using System.TestLibraries.Utilities;
using System.Upgrade;
using System.Utilities;

codeunit 139898 "E-Doc. Serv. Supp. Type Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryEDoc: Codeunit "Library - E-Document";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        DocumentTypeNotSupportedForExportErr: Label 'Document type %1 is explicitly restricted from the Outgoing direction on E-Document Service %2.', Comment = '%1 - E-Document Type, %2 - E-Document Service Code';
        OutgoingRowAssertionLbl: Label 'Seeded row should be Outgoing.';
        PeppolInvoiceSampleFileTxt: Label 'peppol/peppol-invoice-0.xml', Locked = true;

    #region Tests
    [Test]
    [HandlerFunctions('SupportedTypesPageHandler')]
    procedure SupportedTypesActionSeedsDefaultsBeforeNewServiceCloses()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceCode: Code[20];
        EDocumentServicePage: TestPage "E-Document Service";
    begin
        // [SCENARIO] Opening supported types from a new service seeds defaults before the card closes.

        // [GIVEN] A random service code exists.
        EDocServiceCode := this.LibraryUtility.GenerateRandomCode20(EDocumentService.FieldNo(Code), Database::"E-Document Service");
        // [GIVEN] The page handler expects the new service code and 4 seeded rows.
        this.EnqueueSupportedTypesPageHandlerExpectations(EDocServiceCode, 4);

        // [WHEN] A new service card is created and the Supported Doc. Types action is invoked.
        this.OpenNewServiceAndInvokeSupportedDocTypes(EDocServiceCode, EDocumentServicePage);

        // [THEN] 4 supported document types are seeded for the service.
        this.AssertSupportedTypeCountAndCloseServiceCard(EDocServiceCode, 4, EDocumentServicePage);
        // [THEN] No unexpected page-handler interactions remain queued.
        this.LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ExportBlockedWhenDirectionIsIncomingOnly()
    var
        EDocumentService: Record "E-Document Service";
        EDocExport: Codeunit "E-Doc. Export";
        IsSupported: Boolean;
        ExportBlockedForIncomingOnlyLbl: Label 'Export should be blocked for Incoming-only direction.';
    begin
        // [SCENARIO] Export must be blocked when a document type is configured for Incoming only.

        // [GIVEN] Service exists with no supported document types configured.
        this.Initialize(EDocumentService);
        // [GIVEN] Sales Invoice is configured for Incoming only.
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Invoice", Enum::"E-Doc. Supp. Type Direction"::Incoming);

        // [WHEN] Checking whether Sales Invoice is supported for export.
        IsSupported := EDocExport.IsDocumentTypeSupported(EDocumentService, Enum::"E-Document Type"::"Sales Invoice");

        // [THEN] Export is blocked for Incoming-only direction.
        Assert.IsFalse(IsSupported, ExportBlockedForIncomingOnlyLbl);
    end;

    [Test]
    procedure ExportAllowedWhenDirectionIsOutgoingOrBoth()
    var
        EDocumentService: Record "E-Document Service";
        EDocExport: Codeunit "E-Doc. Export";
        OutgoingExportAllowedLbl: Label 'Export should be allowed for Outgoing.';
        ExportAllowedForBothLbl: Label 'Export should be allowed for Both.';
        IsOutgoingSupported, IsBothSupported : Boolean;
    begin
        // [SCENARIO] Export is allowed for Outgoing and for Both.

        // [GIVEN] Service exists with no supported document types configured.
        this.Initialize(EDocumentService);
        // [GIVEN] Sales Invoice is configured for Outgoing.
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Invoice", Enum::"E-Doc. Supp. Type Direction"::Outgoing);
        // [GIVEN] Sales Credit Memo is configured for Both.
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Credit Memo", Enum::"E-Doc. Supp. Type Direction"::Both);

        // [WHEN] Checking whether Sales Invoice is supported for export.
        IsOutgoingSupported := EDocExport.IsDocumentTypeSupported(EDocumentService, Enum::"E-Document Type"::"Sales Invoice");
        // [WHEN] Checking whether Sales Credit Memo is supported for export.
        IsBothSupported := EDocExport.IsDocumentTypeSupported(EDocumentService, Enum::"E-Document Type"::"Sales Credit Memo");

        // [THEN] Export is allowed for Outgoing.
        Assert.IsTrue(IsOutgoingSupported, OutgoingExportAllowedLbl);
        // [THEN] Export is allowed for Both.
        Assert.IsTrue(IsBothSupported, ExportAllowedForBothLbl);
    end;

    [Test]
    procedure RecreateLogsExportErrorWhenDirectionChangedToIncoming()
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocumentServiceStatus: Record "E-Document Service Status";
        EDocExport: Codeunit "E-Doc. Export";
        ExportErrorLbl: Label 'Recreate should set Export Error.';
        OutgoingDirectionRestrictionLogLbl: Label 'Recreate should log the Outgoing-direction restriction.';
    begin
        // [SCENARIO] Recreate rechecks the current Outgoing permission before exporting.

        // [GIVEN] Service exists with no supported document types configured.
        this.Initialize(EDocumentService);
        // [GIVEN] Sales Invoice is configured for Incoming only.
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Invoice", Enum::"E-Doc. Supp. Type Direction"::Incoming);
        // [GIVEN] An inbound Sales Invoice document exists for the service.
        this.CreateInboundEDocumentWithType(EDocument, EDocumentService, Enum::"E-Document Type"::"Sales Invoice");

        // [WHEN] The document is recreated for export.
        EDocExport.Recreate(EDocument, EDocumentService);

        // [THEN] The Outgoing-direction restriction is logged as an error.
        Assert.IsTrue(this.HasDocumentTypeNotSupportedForExportError(EDocument, EDocumentService), OutgoingDirectionRestrictionLogLbl);
        // [THEN] The E-Document Service Status is set to Export Error.
        EDocumentServiceStatus.Get(EDocument."Entry No", EDocumentService.Code);
        Assert.AreEqual(Enum::"E-Document Service Status"::"Export Error", EDocumentServiceStatus.Status, ExportErrorLbl);
    end;

    [Test]
    procedure MixedBatchExportBlocksOnlyUnsupportedDocument()
    var
        EDocument: Record "E-Document";
        SupportedEDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempEDocMappingLog: Record "E-Doc. Mapping Log" temporary;
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
        TempBlob: Codeunit "Temp Blob";
        OutgoingDirectionRestrictionLbl: Label 'The unsupported document should receive the Outgoing-direction restriction.';
        UnsupportedDocumentImpactLbl: Label 'The supported document should not be affected by the unsupported document in the same batch.';
        SupportedDocumentBatchPayloadLbl: Label 'The supported document should still produce a batch payload.';
        EDocumentsErrorCount: Dictionary of [Integer, Integer];
        UnsupportedEntryNo, SupportedEntryNo, UnsupportedErrorCountBefore, SupportedErrorCountBefore : Integer;
    begin
        // [SCENARIO] A mixed batch only blocks the document with the unsupported type; the supported document is still exported.

        // [GIVEN] Service exists with Sales Invoice restricted to Incoming and Sales Credit Memo allowed Outgoing.
        this.CreateServiceForMixedBatchExport(EDocumentService);
        // [GIVEN] Unsupported document exists with document type Sales Invoice.
        UnsupportedEntryNo := this.CreateUnsupportedInboundEDocument(EDocument, EDocumentService);
        // [GIVEN] Sales Credit Memo with a line exists to be mapped during export.
        this.CreateSalesCrMemoWithLine(SalesCrMemoHeader);
        // [GIVEN] Supported document exists linking to the Sales Credit Memo.
        SupportedEntryNo := this.CreateSupportedInboundEDocument(SupportedEDocument, EDocumentService, SalesCrMemoHeader);
        // [GIVEN] The batch is filtered to only the unsupported and supported documents.
        EDocument.SetFilter("Entry No", '%1|%2', UnsupportedEntryNo, SupportedEntryNo);

        // [WHEN] The mixed batch is exported.
        this.RunBatchExportAndReload(EDocument, EDocumentService, TempEDocMappingLog, TempBlob, EDocumentsErrorCount, SupportedEDocument, UnsupportedEntryNo, SupportedEntryNo, UnsupportedErrorCountBefore, SupportedErrorCountBefore);

        // [THEN] The unsupported document receives the Outgoing-direction restriction error.
        Assert.IsTrue(EDocumentErrorHelper.ErrorMessageCount(EDocument) > UnsupportedErrorCountBefore, OutgoingDirectionRestrictionLbl);
        // [THEN] The supported document is unaffected by the unsupported document in the same batch.
        Assert.AreEqual(SupportedErrorCountBefore, EDocumentErrorHelper.ErrorMessageCount(SupportedEDocument), UnsupportedDocumentImpactLbl);
        // [THEN] The supported document still produces a batch payload.
        Assert.IsTrue(TempBlob.Length() > 0, SupportedDocumentBatchPayloadLbl);
        // [THEN] The supported document does not receive the unsupported-type error.
        this.AssertNoUnsupportedTypeErrorLogged(SupportedEDocument, EDocumentService);
    end;

    [Test]
    procedure ImportBlockedWhenDirectionIsOutgoingOnly()
    var
        EDocumentService: Record "E-Document Service";
        EDocExport: Codeunit "E-Doc. Export";
        IsSupported: Boolean;
        OutgoingOnlyImportBlockLbl: Label 'Import should be blocked for Outgoing-only direction.';
    begin
        // [SCENARIO] Import must be blocked when a document type is configured for Outgoing only.

        // [GIVEN] Service exists with no supported document types configured.
        this.Initialize(EDocumentService);
        // [GIVEN] Purchase Invoice is configured for Outgoing only.
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice", Enum::"E-Doc. Supp. Type Direction"::Outgoing);

        // [WHEN] Checking whether Purchase Invoice is supported for import.
        IsSupported := EDocExport.IsDocumentTypeSupportedForImport(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice");

        // [THEN] Import is blocked for Outgoing-only direction.
        Assert.IsFalse(IsSupported, OutgoingOnlyImportBlockLbl);
    end;

    [Test]
    [HandlerFunctions('SupportedTypesPageHandler')]
    procedure IntentionallyEmptySupportedTypesRemainEmpty()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceCode: Code[20];
        EDocumentServicePage: TestPage "E-Document Service";
    begin
        // [SCENARIO] Defaults are initialized only once, so deleting every row remains intentional.

        // [GIVEN] A random service code exists.
        EDocServiceCode := this.LibraryUtility.GenerateRandomCode20(EDocumentService.FieldNo(Code), Database::"E-Document Service");
        // [GIVEN] The page handler expects seeded defaults on first open and none on the second.
        this.EnqueueEmptySupportedTypesScenarioExpectations(EDocServiceCode, 4, 0);
        // [GIVEN] A new service card seeds its defaults and every row is then deleted.
        this.CreateNewServiceCardAndClearSupportedTypes(EDocServiceCode, EDocumentServicePage);

        // [WHEN] The Supported Doc. Types action is invoked again on the now-empty service.
        EDocumentServicePage.SupportedDocTypes.Invoke();

        // [THEN] No supported document types are re-seeded.
        this.AssertSupportedTypesEmptyAndCloseServiceCard(EDocServiceCode, EDocumentServicePage);
        // [THEN] No unexpected page-handler interactions remain queued.
        this.LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure V1ImportLogsErrorWhenDocumentTypeIsNotConfigured()
    var
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        Vendor: Record Vendor;
        IncomingDirectionErrorLbl: Label 'The missing Incoming-direction configuration should be logged as an error.';
    begin
        // [SCENARIO] A V1 import logs an error when its document type is not configured for the service.

        // [GIVEN] A standard V1 purchase scenario exists with no supported document types configured.
        this.CreateStandardV1PurchaseScenarioWithNoSupportedTypes(Vendor, EDocumentService);
        // [GIVEN] The import is set to run the Finish draft step.
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Finish draft";

        // [WHEN] A PEPPOL purchase invoice is imported to that state.
        this.LibraryEDoc.CreateInboundPEPPOLDocumentToState(EDocument, EDocumentService, this.PeppolInvoiceSampleFileTxt, TempEDocImportParameters);

        // [THEN] The missing Incoming-direction configuration is logged as an error.
        Assert.IsTrue(this.HasDocumentTypeNotSupportedForImportError(EDocument, EDocumentService, Enum::"E-Document Type"::"Purchase Invoice"), IncomingDirectionErrorLbl);
    end;

    [Test]
    procedure V2PrepareDraftLogsErrorWhenDirectionIsOutgoingOnly()
    var
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        ImportSucceeded: Boolean;
        DraftPreparationFailureLbl: Label 'Prepare draft should fail when Purchase Invoice is restricted to Outgoing.';
        IncomingDocumentErrorLbl: Label 'An error should be logged for an Incoming document restricted to Outgoing.';
    begin
        // [SCENARIO] A V2 Prepare draft step logs an error when its resolved type is restricted to Outgoing.

        // [GIVEN] A V2 PEPPOL service exists with Purchase Invoice restricted to Outgoing.
        this.CreateV2PEPPOLServiceWithOutgoingOnlyPurchaseInvoice(EDocumentService);
        // [GIVEN] The import is set to run the Prepare draft step.
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";

        // [WHEN] A PEPPOL purchase invoice is imported to that state.
        ImportSucceeded := this.LibraryEDoc.CreateInboundPEPPOLDocumentToState(EDocument, EDocumentService, this.PeppolInvoiceSampleFileTxt, TempEDocImportParameters);

        // [THEN] Prepare draft fails for the restricted document type.
        Assert.IsFalse(ImportSucceeded, DraftPreparationFailureLbl);
        // [THEN] An error is logged explaining the Incoming-direction restriction.
        Assert.IsTrue(this.HasDocumentTypeNotSupportedForImportError(EDocument, EDocumentService, Enum::"E-Document Type"::"Purchase Invoice"), IncomingDocumentErrorLbl);
    end;

    [Test]
    procedure UpgradeSupportedTypeDirectionSetsLegacyRowsToBoth()
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocumentService: Record "E-Document Service";
        EDocumentUpgrade: Codeunit "E-Document Upgrade";
        UpgradeTag: Codeunit "Upgrade Tag";
        HistoricalInboundOnlyPermissionLbl: Label 'A previously unconfigured type should preserve historical inbound-only permission.';
        LabelIncomingTypeUpgradeLbl: Label 'An existing Incoming type should be upgraded to Both.';
        MigrationOverwriteWarningLbl: Label 'A completed migration must not overwrite later direction changes.';
        OutgoingTypeUpgradeLbl: Label 'An existing Outgoing type should be upgraded to Both.';
        SupportedTypeDirectionUpgradeTagLbl: Label 'The supported type direction upgrade tag should be set.';
        UnsupportedDocumentTypeLbl: Label 'None should not be inserted as a supported document type.';
    begin
        // [SCENARIO] The upgrade preserves existing supported types by setting their direction to Both.

        // [GIVEN] The supported type direction upgrade tag is not yet set.
        this.DeleteSupportedTypeDirectionUpgradeTag();
        // [GIVEN] Service exists with no supported document types configured.
        this.Initialize(EDocumentService);
        // [GIVEN] Sales Invoice is configured for Outgoing.
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Invoice", Enum::"E-Doc. Supp. Type Direction"::Outgoing);
        // [GIVEN] Purchase Invoice is configured for Incoming.
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice", Enum::"E-Doc. Supp. Type Direction"::Incoming);

        // [WHEN] The supported type direction upgrade runs.
        EDocumentUpgrade.UpgradeSupportedTypeDirection();

        // [THEN] The existing Outgoing type is upgraded to Both.
        Assert.AreEqual(Enum::"E-Doc. Supp. Type Direction"::Both, this.GetSupportedTypeDirection(EDocumentService.Code, Enum::"E-Document Type"::"Sales Invoice"), OutgoingTypeUpgradeLbl);
        // [THEN] The existing Incoming type is upgraded to Both.
        Assert.AreEqual(Enum::"E-Doc. Supp. Type Direction"::Both, this.GetSupportedTypeDirection(EDocumentService.Code, Enum::"E-Document Type"::"Purchase Invoice"), LabelIncomingTypeUpgradeLbl);
        // [THEN] A previously unconfigured type preserves its historical inbound-only permission.
        Assert.AreEqual(Enum::"E-Doc. Supp. Type Direction"::Incoming, this.GetSupportedTypeDirection(EDocumentService.Code, Enum::"E-Document Type"::"Remittance Advice"), HistoricalInboundOnlyPermissionLbl);
        // [THEN] None is not inserted as a supported document type.
        Assert.IsFalse(EDocServiceSupportedType.Get(EDocumentService.Code, Enum::"E-Document Type"::None), UnsupportedDocumentTypeLbl);
        // [THEN] The supported type direction upgrade tag is set.
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(EDocumentUpgrade.GetUpgradeSupportedTypeDirectionTag()), SupportedTypeDirectionUpgradeTagLbl);

        // [GIVEN] Sales Invoice direction is manually changed to Incoming after the migration completed.
        this.SetSupportedTypeDirection(EDocumentService.Code, Enum::"E-Document Type"::"Sales Invoice", Enum::"E-Doc. Supp. Type Direction"::Incoming);

        // [WHEN] The supported type direction upgrade runs again.
        EDocumentUpgrade.UpgradeSupportedTypeDirection();

        // [THEN] A completed migration does not overwrite the later manual direction change.
        Assert.AreEqual(Enum::"E-Doc. Supp. Type Direction"::Incoming, this.GetSupportedTypeDirection(EDocumentService.Code, Enum::"E-Document Type"::"Sales Invoice"), MigrationOverwriteWarningLbl);
    end;

    [Test]
    procedure ImportUsesFallbackPairDirection()
    var
        EDocumentService: Record "E-Document Service";
        EDocExport: Codeunit "E-Doc. Export";
        PurchaseOrderInheritanceLbl: Label 'Purchase Order should inherit Incoming from the Purchase Invoice fallback row.';
        InvalidExportPurchaseOrderLbl: Label 'Purchase Order should not be supported for export via an Incoming-only fallback row.';
        IsImportSupported, IsExportSupported : Boolean;
    begin
        // [SCENARIO] The Purchase Order/Purchase Invoice fallback pair applies Direction from whichever row matched.

        // [GIVEN] Service exists with no supported document types configured.
        this.Initialize(EDocumentService);
        // [GIVEN] Purchase Invoice is configured for Incoming.
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice", Enum::"E-Doc. Supp. Type Direction"::Incoming);

        // [WHEN] Checking whether Purchase Order is supported for import.
        IsImportSupported := EDocExport.IsDocumentTypeSupportedForImport(EDocumentService, Enum::"E-Document Type"::"Purchase Order");
        // [WHEN] Checking whether Purchase Order is supported for export.
        IsExportSupported := EDocExport.IsDocumentTypeSupported(EDocumentService, Enum::"E-Document Type"::"Purchase Order");

        // [THEN] Purchase Order inherits Incoming from the Purchase Invoice fallback row.
        Assert.IsTrue(IsImportSupported, PurchaseOrderInheritanceLbl);
        // [THEN] Purchase Order is not supported for export via an Incoming-only fallback row.
        Assert.IsFalse(IsExportSupported, InvalidExportPurchaseOrderLbl);
    end;

    [Test]
    procedure FallbackPartnerDoesNotOverrideExplicitOwnRowDirection()
    var
        EDocumentService: Record "E-Document Service";
        EDocExport: Codeunit "E-Doc. Export";
        PurchaseOrderOutgoingRowOverrideLbl: Label 'Purchase Order''s own Outgoing-only row must not be overridden by the Purchase Invoice fallback partner.';
        ExportablePurchaseOrderLbl: Label 'Purchase Order should still be exportable via its own explicit Outgoing row.';
        IsImportSupported, IsExportSupported : Boolean;
    begin
        // [SCENARIO] Purchase Order has its own explicit row (Outgoing only). Purchase Invoice, its fallback partner,
        // is configured Incoming. The fallback must never override an explicit row on the type actually being
        // queried: Purchase Order stays export-only, even though its partner would otherwise allow import.

        // [GIVEN] Service exists with no supported document types configured.
        this.Initialize(EDocumentService);
        // [GIVEN] Purchase Order is configured for Outgoing.
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Purchase Order", Enum::"E-Doc. Supp. Type Direction"::Outgoing);
        // [GIVEN] Purchase Invoice is configured for Incoming.
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice", Enum::"E-Doc. Supp. Type Direction"::Incoming);

        // [WHEN] Checking whether Purchase Order is supported for import.
        IsImportSupported := EDocExport.IsDocumentTypeSupportedForImport(EDocumentService, Enum::"E-Document Type"::"Purchase Order");
        // [WHEN] Checking whether Purchase Order is supported for export.
        IsExportSupported := EDocExport.IsDocumentTypeSupported(EDocumentService, Enum::"E-Document Type"::"Purchase Order");

        // [THEN] Purchase Order's own Outgoing-only row is not overridden by the Purchase Invoice fallback partner.
        Assert.IsFalse(IsImportSupported, PurchaseOrderOutgoingRowOverrideLbl);
        // [THEN] Purchase Order is still exportable via its own explicit Outgoing row.
        Assert.IsTrue(IsExportSupported, ExportablePurchaseOrderLbl);
    end;

    [Test]
    procedure ImportBlockedWhenDocumentTypeNotConfigured()
    var
        EDocumentService: Record "E-Document Service";
        EDocExport: Codeunit "E-Doc. Export";
        ImportBlockedLbl: Label 'Import must be blocked when no row is configured.';
        ExportRowRequirementLbl: Label 'Export must still require an explicit row, unchanged from pre-Direction behavior.';
        IsImportSupported, IsExportSupported : Boolean;
    begin
        // [SCENARIO] Import requires an explicit supported-type row for the Incoming direction.

        // [GIVEN] Service exists with no supported document types configured.
        this.Initialize(EDocumentService);

        // [WHEN] Checking whether Purchase Invoice is supported for import.
        IsImportSupported := EDocExport.IsDocumentTypeSupportedForImport(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice");
        // [WHEN] Checking whether Purchase Invoice is supported for export.
        IsExportSupported := EDocExport.IsDocumentTypeSupported(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice");

        // [THEN] Import is blocked when no row is configured.
        Assert.IsFalse(IsImportSupported, ImportBlockedLbl);
        // [THEN] Export still requires an explicit row, unchanged from pre-Direction behavior.
        Assert.IsFalse(IsExportSupported, ExportRowRequirementLbl);
    end;

    [Test]
    procedure ClosingNewServiceSeedsDefaultsForDefaultFormat()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceCode: Code[20];
        PreconditionLbl: Label 'Precondition: format must still be the untouched default.';
        RowCountAssertionLbl: Label 'Precondition: 4 rows should be seeded.';
        EDocumentServicePage: TestPage "E-Document Service";
    begin
        // [SCENARIO] Closing a new service with the default Data Exchange format seeds its defaults.

        // [GIVEN] A random service code exists.
        EDocServiceCode := this.LibraryUtility.GenerateRandomCode20(EDocumentService.FieldNo(Code), Database::"E-Document Service");

        // [WHEN] A new service card is created and closed without changing the format.
        this.CreateAndCloseNewServiceCard(EDocServiceCode, EDocumentServicePage);

        // [THEN] The format is still the untouched Data Exchange default.
        Assert.AreEqual(Enum::"E-Document Format"::"Data Exchange", this.GetDocumentFormat(EDocServiceCode), PreconditionLbl);
        // [THEN] 4 supported document types are seeded for the service.
        Assert.AreEqual(4, this.CountSupportedTypes(EDocServiceCode), RowCountAssertionLbl);
        // [THEN] Sales Invoice is seeded as Outgoing.
        Assert.AreEqual(Enum::"E-Doc. Supp. Type Direction"::Outgoing, this.GetSupportedTypeDirection(EDocServiceCode, Enum::"E-Document Type"::"Sales Invoice"), OutgoingRowAssertionLbl);
    end;

    [Test]
    procedure PEPPOLBIS30SeedingSetsOutgoingDirectionIncludingRemittanceAdvice()
    var
        EDocumentService: Record "E-Document Service";
        RemittanceAdviceErrorLbl: Label 'Remittance Advice should be seeded for PEPPOL BIS 3.0.';
    begin
        // [SCENARIO] Creating a service with PEPPOL BIS 3.0 format seeds direction-aware default rows, including Remittance Advice.

        // [GIVEN] A new service exists with no format validated yet.
        this.CreateBlankService(EDocumentService);

        // [WHEN] The Document Format is validated to PEPPOL BIS 3.0.
        this.ValidateDocumentFormat(EDocumentService, Enum::"E-Document Format"::"PEPPOL BIS 3.0");

        // [THEN] All seeded rows, including Remittance Advice, are Outgoing.
        Assert.IsTrue(this.AllSupportedTypesHaveDirection(EDocumentService.Code, Enum::"E-Doc. Supp. Type Direction"::Outgoing), OutgoingRowAssertionLbl);
        // [THEN] Remittance Advice is seeded for PEPPOL BIS 3.0.
        Assert.IsTrue(this.IsSupportedTypeConfigured(EDocumentService.Code, Enum::"E-Document Type"::"Remittance Advice"), RemittanceAdviceErrorLbl);
    end;

    [Test]
    procedure DataExchangeSeedingSetsOutgoingDirection()
    var
        EDocumentService: Record "E-Document Service";
    begin
        // [SCENARIO] Creating a service with Data Exchange format seeds direction-aware default rows.

        // [GIVEN] A new service exists with no format validated yet.
        this.CreateBlankService(EDocumentService);

        // [WHEN] The Document Format is validated to Data Exchange.
        this.ValidateDocumentFormat(EDocumentService, Enum::"E-Document Format"::"Data Exchange");

        // [THEN] All seeded rows are Outgoing.
        Assert.IsTrue(this.AllSupportedTypesHaveDirection(EDocumentService.Code, Enum::"E-Doc. Supp. Type Direction"::Outgoing), OutgoingRowAssertionLbl);
    end;

    [Test]
    procedure DataExchangeSeedingDoesNotWidenPartialConfiguration()
    var
        EDocumentService: Record "E-Document Service";
        PreExistingRowAssertionLbl: Label 'Only the pre-existing row should remain.';
        SalesCreditMemoNotConfiguredLbl: Label 'Sales Credit Memo should not be added to an already configured service.';
    begin
        // [SCENARIO] Revalidating Data Exchange on a partially configured service must not add missing defaults.

        // [GIVEN] A new service exists with no format validated yet.
        this.CreateBlankService(EDocumentService);
        // [GIVEN] Sales Invoice is already configured for Outgoing.
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Invoice", Enum::"E-Doc. Supp. Type Direction"::Outgoing);

        // [WHEN] The Document Format is validated to Data Exchange.
        this.ValidateDocumentFormat(EDocumentService, Enum::"E-Document Format"::"Data Exchange");

        // [THEN] Only the single already-configured row remains.
        Assert.AreEqual(1, this.CountSupportedTypes(EDocumentService.Code), PreExistingRowAssertionLbl);
        // [THEN] Sales Credit Memo is not added to the already configured service.
        Assert.IsFalse(this.IsSupportedTypeConfigured(EDocumentService.Code, Enum::"E-Document Type"::"Sales Credit Memo"), SalesCreditMemoNotConfiguredLbl);
    end;

    [Test]
    procedure ChangingFreshServiceToCustomFormatRemovesGeneratedDefaults()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceCode: Code[20];
        NoSupportedTypesLbl: Label 'No supported types should be seeded for a custom format.';
        EDocumentServicePage: TestPage "E-Document Service";
    begin
        // [SCENARIO] Creating a service with a custom format does not seed Data Exchange defaults.

        // [GIVEN] A random service code exists.
        EDocServiceCode := this.LibraryUtility.GenerateRandomCode20(EDocumentService.FieldNo(Code), Database::"E-Document Service");

        // [WHEN] A new service card is created with the Mock export format and closed.
        this.CreateAndCloseNewServiceCardWithFormat(EDocServiceCode, Enum::"E-Document Format"::Mock, EDocumentServicePage);

        // [THEN] No supported document types are seeded.
        Assert.AreEqual(0, this.CountSupportedTypes(EDocServiceCode), NoSupportedTypesLbl);
    end;

    [Test]
    procedure CreatingPEPPOLBIS30ServiceFromCardSeedsPEPPOLDefaults()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceCode: Code[20];
        ExpectedSupportedTypesLbl: Label 'PEPPOL BIS 3.0 should seed 5 supported types.';
        RemittanceAdviceOutgoingLbl: Label 'Remittance Advice should be seeded as Outgoing.';
        EDocumentServicePage: TestPage "E-Document Service";
    begin
        // [SCENARIO] Creating a PEPPOL service from the card seeds PEPPOL defaults directly.

        // [GIVEN] A random service code exists.
        EDocServiceCode := this.LibraryUtility.GenerateRandomCode20(EDocumentService.FieldNo(Code), Database::"E-Document Service");

        // [WHEN] A new service card is created with the PEPPOL BIS 3.0 export format and closed.
        this.CreateAndCloseNewServiceCardWithFormat(EDocServiceCode, Enum::"E-Document Format"::"PEPPOL BIS 3.0", EDocumentServicePage);

        // [THEN] 5 supported document types are seeded for the service.
        Assert.AreEqual(5, this.CountSupportedTypes(EDocServiceCode), ExpectedSupportedTypesLbl);
        // [THEN] Remittance Advice is seeded as Outgoing.
        Assert.AreEqual(Enum::"E-Doc. Supp. Type Direction"::Outgoing, this.GetSupportedTypeDirection(EDocServiceCode, Enum::"E-Document Type"::"Remittance Advice"), RemittanceAdviceOutgoingLbl);
    end;
    #endregion Tests

    #region Initialize
    local procedure Initialize(var EDocumentService: Record "E-Document Service")
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocServiceCode: Code[20];
    begin
        EDocServiceCode := this.LibraryEDoc.CreateService(Enum::"Service Integration"::"No Integration");
        EDocumentService.Get(EDocServiceCode);
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);
    end;
    #endregion Initialize

    #region Given
    local procedure CreateBlankService(var EDocumentService: Record "E-Document Service")
    begin
        EDocumentService.Init();
        EDocumentService.Code := this.LibraryUtility.GenerateRandomCode20(EDocumentService.FieldNo(Code), Database::"E-Document Service");
        EDocumentService.Insert();
    end;

    local procedure CreateInboundEDocumentWithType(var EDocument: Record "E-Document"; EDocumentService: Record "E-Document Service"; DocumentType: Enum "E-Document Type")
    begin
        this.LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);
        EDocument."Document Type" := DocumentType;
        EDocument.Modify();
    end;

    local procedure SetSupportedTypeDirection(EDocServiceCode: Code[20]; DocumentType: Enum "E-Document Type"; Direction: Enum "E-Doc. Supp. Type Direction")
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        EDocServiceSupportedType.Get(EDocServiceCode, DocumentType);
        EDocServiceSupportedType.Direction := Direction;
        EDocServiceSupportedType.Modify();
    end;

    local procedure CreateServiceForMixedBatchExport(var EDocumentService: Record "E-Document Service")
    begin
        this.Initialize(EDocumentService);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Invoice", Enum::"E-Doc. Supp. Type Direction"::Incoming);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Credit Memo", Enum::"E-Doc. Supp. Type Direction"::Outgoing);
    end;

    local procedure CreateUnsupportedInboundEDocument(var EDocument: Record "E-Document"; EDocumentService: Record "E-Document Service"): Integer
    begin
        this.CreateInboundEDocumentWithType(EDocument, EDocumentService, Enum::"E-Document Type"::"Sales Invoice");
        exit(EDocument."Entry No");
    end;

    local procedure CreateSalesCrMemoWithLine(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        // The export path needs a real header/line pair to map, so GetLines finds at least one Sales Cr.Memo Line.
        SalesCrMemoHeader."No." := this.LibraryUtility.GenerateRandomCode20(SalesCrMemoHeader.FieldNo("No."), Database::"Sales Cr.Memo Header");
        SalesCrMemoHeader.Insert();
        SalesCrMemoLine."Document No." := SalesCrMemoHeader."No.";
        SalesCrMemoLine."Line No." := 10000;
        SalesCrMemoLine.Insert();
    end;

    local procedure CreateSupportedInboundEDocument(var SupportedEDocument: Record "E-Document"; EDocumentService: Record "E-Document Service"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Integer
    begin
        this.LibraryEDoc.CreateInboundEDocument(SupportedEDocument, EDocumentService);
        SupportedEDocument."Document Type" := Enum::"E-Document Type"::"Sales Credit Memo";
        SupportedEDocument."Document No." := SalesCrMemoHeader."No.";
        SupportedEDocument."Document Record ID" := SalesCrMemoHeader.RecordId();
        SupportedEDocument.Modify();
        exit(SupportedEDocument."Entry No");
    end;

    local procedure EnqueueSupportedTypesPageHandlerExpectations(EDocServiceCode: Code[20]; ExpectedCount: Integer)
    begin
        this.LibraryVariableStorage.Clear();
        this.LibraryVariableStorage.Enqueue(EDocServiceCode);
        this.LibraryVariableStorage.Enqueue(ExpectedCount);
    end;

    local procedure EnqueueEmptySupportedTypesScenarioExpectations(EDocServiceCode: Code[20]; SeededCount: Integer; ClearedCount: Integer)
    begin
        this.LibraryVariableStorage.Clear();
        this.LibraryVariableStorage.Enqueue(EDocServiceCode);
        this.LibraryVariableStorage.Enqueue(SeededCount);
        this.LibraryVariableStorage.Enqueue(EDocServiceCode);
        this.LibraryVariableStorage.Enqueue(ClearedCount);
    end;

    local procedure CreateNewServiceCardAndClearSupportedTypes(EDocServiceCode: Code[20]; var EDocumentServicePage: TestPage "E-Document Service")
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        EDocumentServicePage.OpenNew();
        EDocumentServicePage.Code.SetValue(EDocServiceCode);
        EDocumentServicePage.SupportedDocTypes.Invoke();
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);
    end;

    local procedure CreateStandardV1PurchaseScenarioWithNoSupportedTypes(var Vendor: Record Vendor; var EDocumentService: Record "E-Document Service")
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        this.LibraryEDoc.Initialize();
        this.LibraryEDoc.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::"PEPPOL BIS 3.0", Enum::"Service Integration"::"No Integration", Enum::"E-Document Import Process"::"Version 1.0");
        EDocumentService."Validate Receiving Company" := false;
        EDocumentService.Modify();
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocumentService.Code);
        EDocServiceSupportedType.DeleteAll(false);
    end;

    local procedure CreateV2PEPPOLServiceWithOutgoingOnlyPurchaseInvoice(var EDocumentService: Record "E-Document Service")
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocServiceCode: Code[20];
    begin
        EDocServiceCode := this.LibraryEDoc.CreateService(Enum::"E-Document Format"::"PEPPOL BIS 3.0", Enum::"Service Integration"::"No Integration");
        EDocumentService.Get(EDocServiceCode);
        EDocumentService."Import Process" := "E-Document Import Process"::"Version 2.0";
        EDocumentService."Read into Draft Impl." := "E-Doc. Read into Draft"::PEPPOL;
        EDocumentService.Modify();
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice", Enum::"E-Doc. Supp. Type Direction"::Outgoing);
    end;

    local procedure DeleteSupportedTypeDirectionUpgradeTag()
    var
        EDocumentUpgrade: Codeunit "E-Document Upgrade";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
    begin
        UpgradeTagLibrary.DeleteUpgradeTag(EDocumentUpgrade.GetUpgradeSupportedTypeDirectionTag(), CopyStr(CompanyName(), 1, 30));
    end;
    #endregion Given

    #region When
    local procedure OpenNewServiceAndInvokeSupportedDocTypes(EDocServiceCode: Code[20]; var EDocumentServicePage: TestPage "E-Document Service")
    begin
        EDocumentServicePage.OpenNew();
        EDocumentServicePage.Code.SetValue(EDocServiceCode);
        EDocumentServicePage.SupportedDocTypes.Invoke();
    end;

    local procedure ValidateDocumentFormat(var EDocumentService: Record "E-Document Service"; DocumentFormat: Enum "E-Document Format")
    begin
        EDocumentService.Validate("Document Format", DocumentFormat);
        EDocumentService.Modify();
    end;

    local procedure CreateAndCloseNewServiceCard(EDocServiceCode: Code[20]; var EDocumentServicePage: TestPage "E-Document Service")
    begin
        EDocumentServicePage.OpenNew();
        EDocumentServicePage.Code.SetValue(EDocServiceCode);
        EDocumentServicePage.Close();
    end;

    local procedure CreateAndCloseNewServiceCardWithFormat(EDocServiceCode: Code[20]; ExportFormat: Enum "E-Document Format"; var EDocumentServicePage: TestPage "E-Document Service")
    begin
        EDocumentServicePage.OpenNew();
        EDocumentServicePage.Code.SetValue(EDocServiceCode);
        EDocumentServicePage."Export Format".SetValue(ExportFormat);
        EDocumentServicePage.Close();
    end;

    local procedure RunBatchExportAndReload(var EDocument: Record "E-Document"; EDocumentService: Record "E-Document Service"; var TempEDocMappingLog: Record "E-Doc. Mapping Log" temporary; var TempBlob: Codeunit "Temp Blob"; var EDocumentsErrorCount: Dictionary of [Integer, Integer]; var SupportedEDocument: Record "E-Document"; UnsupportedEntryNo: Integer; SupportedEntryNo: Integer; var UnsupportedErrorCountBefore: Integer; var SupportedErrorCountBefore: Integer)
    var
        EDocExport: Codeunit "E-Doc. Export";
        EDocImplState: Codeunit "E-Doc. Impl. State";
    begin
        EDocImplState.SetVariableStorage(this.LibraryVariableStorage);
        BindSubscription(EDocImplState);
        EDocExport.ExportEDocumentBatch(EDocument, EDocumentService, TempEDocMappingLog, TempBlob, EDocumentsErrorCount);
        UnbindSubscription(EDocImplState);
        this.LibraryVariableStorage.DequeueInteger(); // Mock document format enqueues the created batch payload length

        EDocumentsErrorCount.Get(UnsupportedEntryNo, UnsupportedErrorCountBefore);
        EDocumentsErrorCount.Get(SupportedEntryNo, SupportedErrorCountBefore);

        EDocument.Get(UnsupportedEntryNo);
        SupportedEDocument.Get(SupportedEntryNo);
    end;
    #endregion When

    #region Then
    local procedure CountSupportedTypes(EDocServiceCode: Code[20]) Count: Integer
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        Count := EDocServiceSupportedType.Count();
    end;

    local procedure IsSupportedTypeConfigured(EDocServiceCode: Code[20]; DocumentType: Enum "E-Document Type") Configured: Boolean
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        Configured := EDocServiceSupportedType.Get(EDocServiceCode, DocumentType);
    end;

    local procedure GetSupportedTypeDirection(EDocServiceCode: Code[20]; DocumentType: Enum "E-Document Type") Direction: Enum "E-Doc. Supp. Type Direction"
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        EDocServiceSupportedType.Get(EDocServiceCode, DocumentType);
        Direction := EDocServiceSupportedType.Direction;
    end;

    local procedure AllSupportedTypesHaveDirection(EDocServiceCode: Code[20]; Direction: Enum "E-Doc. Supp. Type Direction") AllMatch: Boolean
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.SetFilter(Direction, '<>%1', Direction);
        AllMatch := EDocServiceSupportedType.IsEmpty();
    end;

    local procedure GetDocumentFormat(EDocServiceCode: Code[20]) Format: Enum "E-Document Format"
    var
        EDocumentService: Record "E-Document Service";
    begin
        EDocumentService.Get(EDocServiceCode);
        Format := EDocumentService."Document Format";
    end;

    local procedure HasDocumentTypeNotSupportedForExportError(EDocument: Record "E-Document"; EDocumentService: Record "E-Document Service") Found: Boolean
    var
        ErrorMessage: Record "Error Message";
    begin
        ErrorMessage.SetRange("Context Record ID", EDocument.RecordId());
        ErrorMessage.SetRange(Message, StrSubstNo(DocumentTypeNotSupportedForExportErr, EDocument."Document Type", EDocumentService.Code));
        Found := not ErrorMessage.IsEmpty();
    end;

    local procedure HasDocumentTypeNotSupportedForImportError(EDocument: Record "E-Document"; EDocumentService: Record "E-Document Service"; DocumentType: Enum "E-Document Type") Found: Boolean
    var
        ErrorMessage: Record "Error Message";
        DocumentTypeNotSupportedForImportErr: Label 'Document type %1 is not permitted for the Incoming direction on E-Document Service %2.', Comment = '%1 - E-Document Type, %2 - E-Document Service Code';
    begin
        ErrorMessage.SetRange("Context Record ID", EDocument.RecordId());
        ErrorMessage.SetRange("Message Type", ErrorMessage."Message Type"::Error);
        ErrorMessage.SetRange(Message, StrSubstNo(DocumentTypeNotSupportedForImportErr, DocumentType, EDocumentService.Code));
        Found := not ErrorMessage.IsEmpty();
    end;

    local procedure AssertSupportedTypeCountAndCloseServiceCard(EDocServiceCode: Code[20]; ExpectedCount: Integer; var EDocumentServicePage: TestPage "E-Document Service")
    var
        UnexpectedSupportedTypesCountLbl: Label 'Unexpected number of seeded supported types.';
    begin
        Assert.AreEqual(ExpectedCount, this.CountSupportedTypes(EDocServiceCode), UnexpectedSupportedTypesCountLbl);
        EDocumentServicePage.Close();
    end;

    local procedure AssertSupportedTypesEmptyAndCloseServiceCard(EDocServiceCode: Code[20]; var EDocumentServicePage: TestPage "E-Document Service")
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        Assert.RecordIsEmpty(EDocServiceSupportedType);
        EDocumentServicePage.Close();
    end;

    local procedure AssertNoUnsupportedTypeErrorLogged(SupportedEDocument: Record "E-Document"; EDocumentService: Record "E-Document Service")
    var
        ErrorMessage: Record "Error Message";
        UnsupportedDocumentTypeErrorLbl: Label 'The supported document should not receive the unsupported-type error.';
    begin
        ErrorMessage.SetRange("Context Record ID", SupportedEDocument.RecordId());
        ErrorMessage.SetRange(Message, StrSubstNo(DocumentTypeNotSupportedForExportErr, SupportedEDocument."Document Type", EDocumentService.Code));
        Assert.IsTrue(ErrorMessage.IsEmpty(), UnsupportedDocumentTypeErrorLbl);
    end;
    #endregion Then

    #region Page Handlers
    [PageHandler]
    procedure SupportedTypesPageHandler(var SupportedTypesPage: TestPage "E-Doc Service Supported Types")
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocumentService: Record "E-Document Service";
        EInvoiceServiceSaveLbl: Label 'The E-Document Service must be saved before supported types are opened.';
        ExpectedServiceCodeVariant, ExpectedCountVariant : Variant;
        ExpectedServiceCode: Code[20];
        ExpectedCount: Integer;
    begin
        this.LibraryVariableStorage.Dequeue(ExpectedServiceCodeVariant);
        this.LibraryVariableStorage.Dequeue(ExpectedCountVariant);
        ExpectedServiceCode := ExpectedServiceCodeVariant;
        ExpectedCount := ExpectedCountVariant;
        Assert.IsTrue(EDocumentService.Get(ExpectedServiceCode), EInvoiceServiceSaveLbl);
        EDocServiceSupportedType.SetRange("E-Document Service Code", ExpectedServiceCode);
        Assert.RecordCount(EDocServiceSupportedType, ExpectedCount);
        SupportedTypesPage.Close();
    end;
    #endregion Page Handlers
}