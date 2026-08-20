// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Service.Participant;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

codeunit 139799 "E-Doc. Helper Test"
{
    Subtype = Test;
    Access = Internal;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryEDoc: Codeunit "Library - E-Document";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        LibraryPurchase: Codeunit "Library - Purchase";
        MultipleVendorsWithRegistrationNoErr: Label 'Multiple vendors match the registration number on the electronic document.';

    trigger OnRun()
    begin
        // [FEATURE] [E-Document]
    end;

    [Test]
    procedure ValidateLineDiscountTest()
    var
        EDocument: Record "E-Document";
        TempPurchaseLine: Record "Purchase Line" temporary;
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        RecordRef: RecordRef;
    begin
        TempPurchaseLine."Direct Unit Cost" := 0.99;
        TempPurchaseLine.Amount := 0.88 * 5;
        TempPurchaseLine.Quantity := 5;

        RecordRef.GetTable(TempPurchaseLine);
        EDocumentImportHelper.ValidateLineDiscount(EDocument, RecordRef);
        RecordRef.SetTable(TempPurchaseLine);
        Assert.AreEqual(TempPurchaseLine."Line Discount Amount", 0.55, 'Line Discount Amount does not equal');
    end;


    [Test]
    procedure ValidateDonotFindVendor()
    var
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        VendorNo: Code[20];
    begin
        VendorNo := EDocumentImportHelper.FindVendor('', '', '');
        Assert.IsTrue(VendorNo = '', 'Vendor No. should be empty');
    end;

    [Test]
    procedure FindVendorByRegistrationNo()
    var
        Vendor: Record Vendor;
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        LibraryUtility: Codeunit "Library - Utility";
        RegistrationNo: Text[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 646793] A vendor can be resolved by Registration No. when other identifiers are unavailable.
        RegistrationNo := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(RegistrationNo));
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Use Reg. No. in E-Document" := true;
        Vendor."Registration Number" := RegistrationNo;
        Vendor.Modify();

        Assert.AreEqual(Vendor."No.", EDocumentImportHelper.FindVendor('', '', '', RegistrationNo), 'Vendor should be matched by Registration No.');
    end;

    [Test]
    procedure DoesNotFindVendorByRegistrationNoWithoutSetup()
    var
        Vendor: Record Vendor;
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        LibraryUtility: Codeunit "Library - Utility";
        RegistrationNo: Text[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 646793] Registration No. matching requires explicit vendor setup.
        RegistrationNo := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(RegistrationNo));
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Registration Number" := RegistrationNo;
        Vendor.Modify();

        Assert.AreEqual('', EDocumentImportHelper.FindVendor('', '', '', RegistrationNo), 'Vendor should not be matched by Registration No. without setup.');
    end;

    [Test]
    procedure ErrorsWhenMultipleVendorsMatchByRegistrationNo()
    var
        Vendor: array[2] of Record Vendor;
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        LibraryUtility: Codeunit "Library - Utility";
        RegistrationNo: Text[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 646793] Vendor matching fails when a registration number identifies multiple vendors.
        RegistrationNo := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(RegistrationNo));
        LibraryPurchase.CreateVendor(Vendor[1]);
        Vendor[1]."Use Reg. No. in E-Document" := true;
        Vendor[1]."Registration Number" := RegistrationNo;
        Vendor[1].Modify();
        LibraryPurchase.CreateVendor(Vendor[2]);
        Vendor[2]."Use Reg. No. in E-Document" := true;
        Vendor[2]."Registration Number" := RegistrationNo;
        Vendor[2].Modify();

        asserterror EDocumentImportHelper.FindVendor('', '', '', RegistrationNo);

        Assert.ExpectedError(MultipleVendorsWithRegistrationNoErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ValidateReceivingCompanyInfoWithMatchingServiceParticipant()
    var
        EDocument: Record "E-Document";
        EDocService: Record "E-Document Service";
        ServiceParticipant: Record "Service Participant";
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        EDocErrorHelper: Codeunit "E-Document Error Helper";
        TestParticipantId: Text[200];
    begin
        LibraryLowerPermission.SetOutsideO365Scope();
        // [SCENARIO] Validation should succeed when a matching Company Service Participant exists
        // [GIVEN] An E-Document with a Receiving Company Id
        TestParticipantId := '0208:1234567890';
        EDocument.Init();
        EDocument."Entry No" := 0;
        EDocument."Receiving Company Id" := TestParticipantId;
        EDocument."Receiving Company GLN" := '';
        EDocument."Receiving Company VAT Reg. No." := '';
        EDocument.Insert(true);

        // [GIVEN] An E-Document Service
        LibraryEDoc.CreateTestReceiveServiceForEDoc(EDocService, Enum::"Service Integration"::"Mock");

        // [GIVEN] A matching Company Service Participant
        ServiceParticipant.Init();
        ServiceParticipant.Service := EDocService.Code;
        ServiceParticipant."Participant Type" := ServiceParticipant."Participant Type"::Company;
        ServiceParticipant.Participant := '';
        ServiceParticipant."Participant Identifier" := TestParticipantId;
        ServiceParticipant.Insert(true);

        // [WHEN] Validating receiving company info
        EDocumentImportHelper.ValidateReceivingCompanyInfo(EDocument, EDocService);

        // [THEN] No errors should be logged (validation should exit early due to Service Participant match)
        Assert.IsFalse(EDocErrorHelper.HasErrors(EDocument), 'No errors should be logged when Service Participant matches');

        // Cleanup
        ServiceParticipant.Delete();
        EDocument.Delete();
    end;

    [Test]
    procedure ValidateReceivingCompanyInfoFallsBackToVATWhenNoServiceParticipant()
    var
        EDocument: Record "E-Document";
        EDocService: Record "E-Document Service";
        CompanyInformation: Record "Company Information";
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        EDocErrorHelper: Codeunit "E-Document Error Helper";
    begin
        LibraryLowerPermission.SetOutsideO365Scope();
        // [SCENARIO] Validation should fall back to VAT/GLN matching when no Service Participant exists
        // [GIVEN] An E-Document with a Receiving Company Id that doesn't match any Service Participant
        // [GIVEN] But has matching VAT Registration No.
        CompanyInformation.Get();

        EDocument.Init();
        EDocument."Entry No" := 0;
        EDocument."Receiving Company Id" := '0208:NOMATCH';
        EDocument."Receiving Company VAT Reg. No." := CompanyInformation."VAT Registration No.";
        EDocument."Receiving Company GLN" := '';
        EDocument.Insert(true);

        // [GIVEN] An E-Document Service with no matching Company Service Participant
        LibraryEDoc.CreateTestReceiveServiceForEDoc(EDocService, Enum::"Service Integration"::"Mock");

        // [WHEN] Validating receiving company info
        EDocumentImportHelper.ValidateReceivingCompanyInfo(EDocument, EDocService);

        // [THEN] No errors should be logged (validation should succeed via VAT matching)
        Assert.IsFalse(EDocErrorHelper.HasErrors(EDocument), 'No errors should be logged when VAT Registration No. matches');

        // Cleanup
        EDocument.Delete();
    end;

}