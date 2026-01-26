codeunit 144003 "Library - CFDI"
{
    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";

    procedure CreatePACService() PACWebServiceCode: Code[10]
    var
        PACWebService: Record "PAC Web Service";
        PACWebServiceDetail: Record "PAC Web Service Detail";
    begin
        PACWebService.Init();
        PACWebService.Validate(Code, LibraryUtility.GenerateRandomCode(PACWebService.FieldNo(Code), DATABASE::"PAC Web Service"));
        PACWebService.Validate(Name, PACWebService.Code);
        PACWebService.Certificate := CreateIsolatedCertificate();
        PACWebService.Insert(true);

        PACWebServiceDetail.Init();
        PACWebServiceDetail.Validate("PAC Code", PACWebService.Code);
        PACWebServiceDetail.Validate(Environment, PACWebServiceDetail.Environment::Test);

        PACWebServiceDetail.Validate("Method Name", LibraryUtility.GenerateRandomCode(PACWebServiceDetail.FieldNo("Method Name"), DATABASE::"PAC Web Service Detail"));
        PACWebServiceDetail.Validate(Address, LibraryUtility.GenerateRandomCode(PACWebServiceDetail.FieldNo(Address), DATABASE::"PAC Web Service Detail"));

        PACWebServiceDetail.Validate(Type, PACWebServiceDetail.Type::"Request Stamp");
        PACWebServiceDetail.Insert(true);

        PACWebServiceDetail.Validate(Type, PACWebServiceDetail.Type::Cancel);
        PACWebServiceDetail.Insert(true);

        PACWebServiceCode := PACWebService.Code;
    end;

    local procedure CreateIsolatedCertificate(): Code[20]
    var
        IsolatedCertificate: Record "Isolated Certificate";
    begin
        IsolatedCertificate.Code := LibraryUtility.GenerateGUID();
        IsolatedCertificate.Name := LibraryUtility.GenerateGUID();
        IsolatedCertificate.ThumbPrint := IsolatedCertificate.Code;
        IsolatedCertificate.Insert();
        exit(IsolatedCertificate.Code);
    end;

    local procedure CreateReportSelection(UsageOption: Enum "Report Selection Usage"; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, UsageOption);
        ReportSelections.DeleteAll(true);
        ReportSelections.Init();
        ReportSelections.Validate(Usage, UsageOption);
        ReportSelections.Validate(Sequence, '1');
        ReportSelections.Validate("Report ID", ReportID);
        ReportSelections.Validate("Use for Email Attachment", true);
        ReportSelections.Insert(true);
    end;

    procedure CreateCFDIExportCode(): Code[10]
    var
        CFDIExportCode: Record "CFDI Export Code";
    begin
        CFDIExportCode.Code := '01';
        if CFDIExportCode.Insert() then;
        exit(CFDIExportCode.Code);
    end;

    procedure CreateCFDIPurpose(): Code[10]
    var
        SATUseCode: Record "SAT Use Code";
    begin
        SATUseCode.Init();
        SATUseCode."SAT Use Code" := LibraryUtility.GenerateRandomCode(SATUseCode.FieldNo("SAT Use Code"), DATABASE::"SAT Use Code");
        SATUseCode.Insert();
        exit(SATUseCode."SAT Use Code");
    end;

    procedure CreateCFDIRelation(): Code[10]
    var
        SATRelationshipType: Record "SAT Relationship Type";
    begin
        SATRelationshipType.Init();
        SATRelationshipType."SAT Relationship Type" :=
            LibraryUtility.GenerateRandomCode(SATRelationshipType.FieldNo("SAT Relationship Type"), DATABASE::"SAT Relationship Type");
        SATRelationshipType.Insert();
        exit(SATRelationshipType."SAT Relationship Type");
    end;

    procedure CreatePaymentMethodForSAT(): Code[10]
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

    procedure CreatePaymentTermsForSAT(): Code[10]
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

    procedure GetRFCNo(): Text[12]
    begin
        exit('AA' + LibraryUtility.GenerateGUID());
    end;

    procedure InitGLSetup(PACWebServiceCode: Code[10])
    var
        GLSetup: Record "General Ledger Setup";
        PACWebServiceDetail: Record "PAC Web Service Detail";
    begin
        GLSetup.Get();
        GLSetup.Validate("PAC Code", PACWebServiceCode);
        GLSetup.Validate("PAC Environment", PACWebServiceDetail.Environment::Test);
        GLSetup.Validate("Sim. Signature", true);
        GLSetup.Validate("Sim. Send", true);
        GLSetup.Validate("Sim. Request Stamp", true);
        GLSetup.Validate("Send PDF Report", true);
        GLSetup."SAT Certificate" := CreateIsolatedCertificate();
        GLSetup."CFDI Enabled" := true;
        GLSetup.Modify(true);
    end;

    procedure PopulateSATInformation()
    var
        SATPaymentMethod: Record "SAT Payment Method";
        SATClassification: Record "SAT Classification";
        SATRelationshipType: Record "SAT Relationship Type";
        SATUseCode: Record "SAT Use Code";
        SATUnitOfMeasure: Record "SAT Unit of Measure";
        SATCountryCode: Record "SAT Country Code";
        SATTaxScheme: Record "SAT Tax Scheme";
        SATPaymentTerm: Record "SAT Payment Term";
        CFDICancellationReason: Record "CFDI Cancellation Reason";
        CFDIExportCode: Record "CFDI Export Code";
        CFDISubjectToTax: Record "CFDI Subject to Tax";
        SATInternationalTradeTerm: Record "SAT International Trade Term";
        SATCustomsUnit: Record "SAT Customs Unit";
        SATTransferReason: Record "SAT Transfer Reason";
        SATClassificationPort: XMLport "SAT Classification";
        SATRelationshipTypePort: XMLport "SAT Relationship Type";
        SATUseCodePort: XMLport "SAT Use Code";
        SATUnitOfMeasurePort: XMLport "SAT Unit of Measure";
        SATCountryCodePort: XMLport "SAT Country Code";
        SATPaymentMethodPort: XMLport "SAT Payment Method";
        SATTaxSchemePort: XMLport "SAT Tax Scheme";
        SATPaymentTermPort: XMLport "SAT Payment Term";
        CFDICancellationReasonPort: XMLport "CFDI Cancellation Reason";
        CFDIExportCodePort: XMLport "CFDI Export Code";
        CFDISubjectToTaxPort: XMLport "CFDI Subject to Tax";
        SATInternationalTradeTermPort: XMLport "SAT International Trade Term";
        SATCustomsUnitPort: XMLport "SAT Customs Unit";
        SATTransferReasonPort: XMLport "SAT Transfer Reason";
        ResourceStream: InStream;
    begin
        if SATClassification.IsEmpty() then begin
            NavApp.GetResource('SATClassifications.xml', ResourceStream);
            SATClassificationPort.TextEncoding(TextEncoding::UTF16);
            SATClassificationPort.SetSource(ResourceStream);
            SATClassificationPort.Import();
        end;

        if SATCountryCode.IsEmpty() then begin
            NavApp.GetResource('SATCountry_Codes.xml', ResourceStream);
            SATCountryCodePort.TextEncoding(TextEncoding::UTF16);
            SATCountryCodePort.SetSource(ResourceStream);
            SATCountryCodePort.Import();
        end;

        if SATPaymentTerm.IsEmpty() then begin
            NavApp.GetResource('SATPayment_Terms.xml', ResourceStream);
            SATPaymentTermPort.TextEncoding(TextEncoding::UTF16);
            SATPaymentTermPort.SetSource(ResourceStream);
            SATPaymentTermPort.Import();
        end;

        if SATRelationshipType.IsEmpty() then begin
            NavApp.GetResource('SATRelationship_Types.xml', ResourceStream);
            SATRelationshipTypePort.TextEncoding(TextEncoding::UTF16);
            SATRelationshipTypePort.SetSource(ResourceStream);
            SATRelationshipTypePort.Import();
        end;

        if SATTaxScheme.IsEmpty() then begin
            NavApp.GetResource('SATTax_Schemes.xml', ResourceStream);
            SATTaxSchemePort.TextEncoding(TextEncoding::UTF16);
            SATTaxSchemePort.SetSource(ResourceStream);
            SATTaxSchemePort.Import();
        end;

        if SATUnitOfMeasure.IsEmpty() then begin
            NavApp.GetResource('SATU_of_M.xml', ResourceStream);
            SATUnitOfMeasurePort.TextEncoding(TextEncoding::UTF16);
            SATUnitOfMeasurePort.SetSource(ResourceStream);
            SATUnitOfMeasurePort.Import();
        end;

        if SATUseCode.IsEmpty() then begin
            NavApp.GetResource('SATUse_Codes.xml', ResourceStream);
            SATUseCodePort.TextEncoding(TextEncoding::UTF16);
            SATUseCodePort.SetSource(ResourceStream);
            SATUseCodePort.Import();
        end;

        if SATPaymentMethod.IsEmpty() then begin
            NavApp.GetResource('SATPayment_Methods.xml', ResourceStream);
            SATPaymentMethodPort.TextEncoding(TextEncoding::UTF16);
            SATPaymentMethodPort.SetSource(ResourceStream);
            SATPaymentMethodPort.Import();
        end;

        if CFDICancellationReason.IsEmpty() then begin
            NavApp.GetResource('CFDICancellationReasons.xml', ResourceStream);
            CFDICancellationReasonPort.TextEncoding(TextEncoding::UTF8);
            CFDICancellationReasonPort.SetSource(ResourceStream);
            CFDICancellationReasonPort.Import();
        end;

        if CFDIExportCode.IsEmpty() then begin
            NavApp.GetResource('CFDIExportCodes.xml', ResourceStream);
            CFDIExportCodePort.TextEncoding(TextEncoding::UTF8);
            CFDIExportCodePort.SetSource(ResourceStream);
            CFDIExportCodePort.Import();
        end;

        if CFDISubjectToTax.IsEmpty() then begin
            NavApp.GetResource('CFDISubjectsToTax.xml', ResourceStream);
            CFDISubjectToTaxPort.TextEncoding(TextEncoding::UTF8);
            CFDISubjectToTaxPort.SetSource(ResourceStream);
            CFDISubjectToTaxPort.Import();
        end;

        if SATInternationalTradeTerm.IsEmpty() then begin
            NavApp.GetResource('SATIncoterms.xml', ResourceStream);
            SATInternationalTradeTermPort.TextEncoding(TextEncoding::UTF8);
            SATInternationalTradeTermPort.SetSource(ResourceStream);
            SATInternationalTradeTermPort.Import();
        end;

        if SATCustomsUnit.IsEmpty() then begin
            NavApp.GetResource('SATCustomUnits.xml', ResourceStream);
            SATCustomsUnitPort.TextEncoding(TextEncoding::UTF8);
            SATCustomsUnitPort.SetSource(ResourceStream);
            SATCustomsUnitPort.Import();
        end;

        if SATTransferReason.IsEmpty() then begin
            NavApp.GetResource('SATTransferReasons.xml', ResourceStream);
            SATTransferReasonPort.TextEncoding(TextEncoding::UTF8);
            SATTransferReasonPort.SetSource(ResourceStream);
            SATTransferReasonPort.Import();
        end;

        PopulateCartaPorteSATCatalogs();
    end;

    local procedure PopulateCartaPorteSATCatalogs()
    var
        SATFederalMotorTransport: Record "SAT Federal Motor Transport";
        SATTrailerType: Record "SAT Trailer Type";
        SATPermissionType: Record "SAT Permission Type";
        SATHazardousMaterial: Record "SAT Hazardous Material";
        SATPackagingType: Record "SAT Packaging Type";
        SATState: Record "SAT State";
        SATMunicipality: Record "SAT Municipality";
        SATLocality: Record "SAT Locality";
        SATSuburb: Record "SAT Suburb";
        SATWeightUnitOfMeasure: Record "SAT Weight Unit of Measure";
        SATMaterialType: Record "SAT Material Type";
        SATCustomsRegime: Record "SAT Customs Regime";
        SATCustomsDocument: Record "SAT Customs Document Type";
        SATFederalMotorTransportPort: XMLport "SAT Federal Motor Transport";
        SATTrailerTypePort: XMLport "SAT Trailer Type";
        SATPermissionTypePort: XMLport "SAT Permission Type";
        SATHazardousMaterialPort: XMLport "SAT Hazardous Material";
        SATPackagingTypePort: XMLport "SAT Packaging Type";
        SATStatePort: XMLport "SAT State";
        SATMunicipalityPort: XMLport "SAT Municipality";
        SATLocalityPort: XMLport "SAT Locality";
        SATSuburbPort: XMLport "SAT Suburb";
        SATWeightUnitOfMeasurePort: XMLport "SAT Weight Unit of Measure";
        SATMaterialTypePort: XMLport "SAT Material Type";
        SATCustomsRegimePort: XMLport "SAT Customs Regime";
        SATCustomsDocumentPort: XMLport "SAT Customs Document Type";
        ResourceStream: InStream;
    begin
        if SATFederalMotorTransport.IsEmpty() then begin
            NavApp.GetResource('SATFederalMotorTransport.xml', ResourceStream);
            SATFederalMotorTransportPort.TextEncoding(TextEncoding::UTF8);
            SATFederalMotorTransportPort.SetSource(ResourceStream);
            SATFederalMotorTransportPort.Import();
        end;

        if SATTrailerType.IsEmpty() then begin
            NavApp.GetResource('SATTrailerTypes.xml', ResourceStream);
            SATTrailerTypePort.TextEncoding(TextEncoding::UTF8);
            SATTrailerTypePort.SetSource(ResourceStream);
            SATTrailerTypePort.Import();
        end;

        if SATPermissionType.IsEmpty() then begin
            NavApp.GetResource('SATPermissionTypes.xml', ResourceStream);
            SATPermissionTypePort.TextEncoding(TextEncoding::UTF8);
            SATPermissionTypePort.SetSource(ResourceStream);
            SATPermissionTypePort.Import();
        end;

        if SATHazardousMaterial.IsEmpty() then begin
            NavApp.GetResource('SATHazardousMaterials.xml', ResourceStream);
            SATHazardousMaterialPort.TextEncoding(TextEncoding::UTF8);
            SATHazardousMaterialPort.SetSource(ResourceStream);
            SATHazardousMaterialPort.Import();
        end;

        if SATPackagingType.IsEmpty() then begin
            NavApp.GetResource('SATPackagingTypes.xml', ResourceStream);
            SATPackagingTypePort.TextEncoding(TextEncoding::UTF8);
            SATPackagingTypePort.SetSource(ResourceStream);
            SATPackagingTypePort.Import();
        end;

        if SATState.IsEmpty() then begin
            NavApp.GetResource('SATStates.xml', ResourceStream);
            SATStatePort.TextEncoding(TextEncoding::UTF8);
            SATStatePort.SetSource(ResourceStream);
            SATStatePort.Import();
        end;

        if SATMunicipality.IsEmpty() then begin
            NavApp.GetResource('SATMunicipalities.xml', ResourceStream);
            SATMunicipalityPort.TextEncoding(TextEncoding::UTF8);
            SATMunicipalityPort.SetSource(ResourceStream);
            SATMunicipalityPort.Import();
        end;

        if SATLocality.IsEmpty() then begin
            NavApp.GetResource('SATLocalities.xml', ResourceStream);
            SATLocalityPort.TextEncoding(TextEncoding::UTF8);
            SATLocalityPort.SetSource(ResourceStream);
            SATLocalityPort.Import();
        end;

        if SATSuburb.IsEmpty() then begin
            NavApp.GetResource('SATSuburb.xml', ResourceStream);
            SATSuburbPort.TextEncoding(TextEncoding::UTF8);
            SATSuburbPort.SetSource(ResourceStream);
            SATSuburbPort.Import();
        end;

        if SATWeightUnitOfMeasure.IsEmpty() then begin
            NavApp.GetResource('SATWeightUnitsOfMeasure.xml', ResourceStream);
            SATWeightUnitOfMeasurePort.TextEncoding(TextEncoding::UTF8);
            SATWeightUnitOfMeasurePort.SetSource(ResourceStream);
            SATWeightUnitOfMeasurePort.Import();
        end;

        if SATMaterialType.IsEmpty() then begin
            NavApp.GetResource('SATMaterialTypes.xml', ResourceStream);
            SATMaterialTypePort.TextEncoding(TextEncoding::UTF8);
            SATMaterialTypePort.SetSource(ResourceStream);
            SATMaterialTypePort.Import();
        end;

        if SATCustomsRegime.IsEmpty() then begin
            NavApp.GetResource('SATCustomsRegimes.xml', ResourceStream);
            SATCustomsRegimePort.TextEncoding(TextEncoding::UTF8);
            SATCustomsRegimePort.SetSource(ResourceStream);
            SATCustomsRegimePort.Import();
        end;

        if SATCustomsDocument.IsEmpty() then begin
            NavApp.GetResource('SATCustomsDocuments.xml', ResourceStream);
            SATCustomsDocumentPort.TextEncoding(TextEncoding::UTF8);
            SATCustomsDocumentPort.SetSource(ResourceStream);
            SATCustomsDocumentPort.Import();
        end;
    end;

    procedure SetupReportSelection()
    var
        ReportSelections: Record "Report Selections";
    begin
        CreateReportSelection(ReportSelections.Usage::"S.Invoice", 10477);
        CreateReportSelection(ReportSelections.Usage::"S.Cr.Memo", 10476);
        CreateReportSelection(ReportSelections.Usage::"SM.Invoice", 10479);
        CreateReportSelection(ReportSelections.Usage::"SM.Credit Memo", 10478);
    end;

    procedure SetupCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
        PostCode: Record "Post Code";
    begin
        PostCode.SetFilter(City, '<>%1', '');
        PostCode.SetFilter("Country/Region Code", '<>%1', '');
        PostCode.FindFirst();

        CompanyInformation.Get();
        CompanyInformation.Validate("RFC Number", GetRFCNo());
        CompanyInformation.Validate("Country/Region Code", PostCode."Country/Region Code");
        CompanyInformation.Validate(City, PostCode.City);
        CompanyInformation.Validate("Post Code", PostCode.Code);
        CompanyInformation.Validate("SAT Postal Code", Format(LibraryRandom.RandIntInRange(10000, 99999)));
        CompanyInformation.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        CompanyInformation.Validate("Tax Scheme", LibraryUtility.GenerateGUID());
        CompanyInformation."SAT Tax Regime Classification" :=
            LibraryUtility.GenerateRandomCode(CompanyInformation.FieldNo("SAT Tax Regime Classification"), DATABASE::"Company Information");
        CompanyInformation.Modify(true);
    end;
}