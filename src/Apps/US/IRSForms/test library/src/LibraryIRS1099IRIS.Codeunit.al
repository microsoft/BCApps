// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using System.Utilities;

codeunit 148023 "Library - IRS 1099 IRIS"
{
    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        SavedIRISUserIDKey: Guid;
        IRISUserIDSaved: Boolean;
        SavedAccessTokenKey: Guid;
        SavedAccessTokenExpiresAt: DateTime;
        OfflineAccessTokenKey: Guid;
        OfflineAccessTokenInitialized: Boolean;
        TINSequenceNameLbl: Label 'TestUniqueTIN', Locked = true;

    #region Company
    procedure InitializeCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
        PostCode: Record "Post Code";
    begin
        PostCode.Validate(Code, '60402');
        PostCode.Validate(City, 'Berwyn');
        PostCode.Validate(County, 'IL');
        PostCode.Validate("Country/Region Code", 'US');
        if not PostCode.Get(PostCode.Code, PostCode.City) then
            PostCode.Insert();
        CompanyInformation.Get();
        CompanyInformation.Name := LibraryUtility.GenerateGUID();
        CompanyInformation."Federal ID No." := GetUniqueTIN();
        CompanyInformation.Validate("Post Code", PostCode.Code);
        CompanyInformation.Address := '6201 Roosevelt Rd';
        CompanyInformation."Contact Person" := 'John Doe Jr.';
        CompanyInformation."Phone No." := LibraryUtility.GenerateRandomPhoneNo();
        CompanyInformation.Modify();
    end;

    procedure InitializeIRSFormsSetup()
    var
        CompanyInformation: Record "Company Information";
        IRSFormsSetup: Record "IRS Forms Setup";
    begin
        CompanyInformation.Get();
        IRSFormsSetup.InitSetup();
        IRSFormsSetup.Validate("Business Name Control", CopyStr(CompanyInformation.Name, 1, 4));
        IRSFormsSetup.Implementation := "IRS Forms Implementation"::Test;
        IRSFormsSetup.Modify(true);
    end;
    #endregion Company

    #region Transmission
    procedure ResolveSchemaVersion(PeriodNo: Code[20]; var Source: Text): Enum "XML Schema Version IRIS"
    var
        Helper: Codeunit "Helper IRIS";
    begin
        exit(Helper.GetXmlSchemaVersion(PeriodNo, Source));
    end;

    procedure ParseSchemaVersion(Version: Text): Enum "XML Schema Version IRIS"
    var
        Helper: Codeunit "Helper IRIS";
    begin
        exit(Helper.ParseSchemaVersion(Version));
    end;

    procedure ResolveSoftwareId(TaxYear: Text): Text
    var
        Helper: Codeunit "Helper IRIS";
    begin
        exit(Helper.GetSoftwareId(TaxYear));
    end;

    procedure ValidateTaxYear(TaxYear: Text)
    var
        Helper: Codeunit "Helper IRIS";
    begin
        Helper.ValidateTaxYear(TaxYear);
    end;

    procedure GetAmountXmlElements(TaxYear: Text): JsonObject
    var
        Helper: Codeunit "Helper IRIS";
    begin
        exit(Helper.GetAmtXmlElementsFileContent(TaxYear));
    end;

    procedure GetAuthEndpoint(): Text
    var
        KeyVaultClient: Codeunit "Key Vault Client IRIS";
    begin
        exit(KeyVaultClient.GetAuthURL());
    end;

    procedure GetSubmitEndpoint(): Text
    var
        KeyVaultClient: Codeunit "Key Vault Client IRIS";
    begin
        exit(KeyVaultClient.GetSubmitEndpointURL());
    end;

    procedure GetStatusEndpoint(): Text
    var
        KeyVaultClient: Codeunit "Key Vault Client IRIS";
    begin
        exit(KeyVaultClient.GetStatusEndpointURL());
    end;

    procedure CapturePayloadContext(var TransmissionLog: Record "Transmission Log IRIS"; var Payload: Codeunit "Temp Blob"; Source: Text)
    begin
        TransmissionLog.SetTransmissonContextInfo(Payload, Source);
    end;

    procedure SendOriginal(var Transmission: Record "Transmission IRIS")
    var
        ProcessTransmission: Codeunit "Process Transmission IRIS";
    begin
        ProcessTransmission.SendOriginal(Transmission);
    end;

    procedure SendReplacement(var Transmission: Record "Transmission IRIS")
    var
        ProcessTransmission: Codeunit "Process Transmission IRIS";
    begin
        ProcessTransmission.SendReplacement(Transmission);
    end;

    procedure SendCorrection(var Transmission: Record "Transmission IRIS"; CorrectionToZero: Boolean)
    var
        ProcessTransmission: Codeunit "Process Transmission IRIS";
    begin
        ProcessTransmission.SendCorrection(Transmission, CorrectionToZero);
    end;

    procedure RequestStatus(ReceiptID: Text[100]; UniqueTransmissionID: Text[100]; var StatusText: Text)
    var
        ProcessTransmission: Codeunit "Process Transmission IRIS";
    begin
        ProcessTransmission.RequestStatus(ReceiptID, UniqueTransmissionID, StatusText);
    end;

    [NonDebuggable]
    procedure InitializeOfflineAccessToken()
    var
        UserParams: Record "User Params IRIS";
        OAuthClient: Codeunit "OAuth Client IRIS";
        Token: SecretText;
        TokenText: Text;
    begin
        RestoreOfflineAccessToken();
        UserParams.GetRecord();
        SavedAccessTokenKey := UserParams."Access Token Key";
        SavedAccessTokenExpiresAt := UserParams."Access Token Expires At";
        TokenText := 'synthetic-offline-token';
        Token := TokenText;
        OAuthClient.SetToken(OfflineAccessTokenKey, Token);
        UserParams."Access Token Key" := OfflineAccessTokenKey;
        UserParams."Access Token Expires At" := CurrentDateTime() + 3600000;
        UserParams.Modify();
        OfflineAccessTokenInitialized := true;
    end;

    [NonDebuggable]
    procedure RestoreOfflineAccessToken()
    var
        UserParams: Record "User Params IRIS";
        OAuthClient: Codeunit "OAuth Client IRIS";
        EmptyToken: SecretText;
    begin
        if not OfflineAccessTokenInitialized then
            exit;
        UserParams.GetRecord();
        UserParams."Access Token Key" := SavedAccessTokenKey;
        UserParams."Access Token Expires At" := SavedAccessTokenExpiresAt;
        UserParams.Modify();
        OAuthClient.SetToken(OfflineAccessTokenKey, EmptyToken);
        OfflineAccessTokenInitialized := false;
    end;

    procedure CreateTransmission(var Transmission: Record "Transmission IRIS"; PeriodNo: Code[20])
    var
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        ReportingYear: Code[4];
    begin
        ReportingYear := CopyStr(PeriodNo, 1, 4);
        IRSFormsFacade.CreateTransmission(Transmission, ReportingYear);
        Transmission.SetRange("Period No.", ReportingYear);
        Transmission.FindFirst();
    end;

    procedure CreateTransmissionXmlContent(Transmission: Record "Transmission IRIS"; TransmissionType: Enum "Transmission Type IRIS"; IsTest: Boolean; var UniqueTransmissionId: Text[100]; var TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var TempBlob: Codeunit "Temp Blob")
    var
        IRSFormsFacade: Codeunit "IRS Forms Facade";
    begin
        IRSFormsFacade.CreateTransmissionXmlContent(Transmission, TransmissionType, IsTest, UniqueTransmissionId, TempIRS1099FormDocHeader, TempBlob);
    end;

    procedure DeleteAllTransmissions()
    var
        Transmission: Record "Transmission IRIS";
        TransmissionLog: Record "Transmission Log IRIS";
        TransmissionLogLine: Record "Transmission Log Line IRIS";
    begin
        TransmissionLogLine.DeleteAll(true);
        TransmissionLog.DeleteAll(true);
        Transmission.ModifyAll(Status, Enum::"Transmission Status IRIS"::None);
        Transmission.DeleteAll(true);
    end;
    #endregion Transmission

    #region Vendor
    procedure CreateUSVendor(var Vendor: Record Vendor)
    begin
        CreateVendor(Vendor, 'US', 'IL');
    end;

    procedure CreateUSVendorWithBankAccount(var Vendor: Record Vendor; BankAccountNo: Code[30])
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        CreateUSVendor(Vendor);
        CreateVendorBankAccount(VendorBankAccount, Vendor."No.", BankAccountNo);
    end;

    procedure CreateVendor(var Vendor: Record Vendor; CountryRegionCode: Code[10]; ProvinceOrStateName: Text[30])
    var
        PostCode: Record "Post Code";
        PaymentMethod: Record "Payment Method";
    begin
        PostCode.Validate(Code, CopyStr(LibraryUtility.GenerateRandomNumericText(5), 1, MaxStrLen(PostCode.Code)));
        PostCode.Validate(City, LibraryUtility.GenerateGUID());
        PostCode.Validate(County, ProvinceOrStateName);
        PostCode.Validate("Country/Region Code", CountryRegionCode);
        PostCode.Insert();

        LibraryERM.CreatePaymentMethodWithBalAccount(PaymentMethod);

        Vendor.SetLoadFields("Federal ID No.", "Post Code", "Address", "Payment Method Code");
        Vendor.Get(LibraryPurchase.CreateVendorNo());
        Vendor."Federal ID No." := GetUniqueTIN();
        Vendor.Validate("Post Code", PostCode.Code);
        Vendor.Validate(Address, LibraryUtility.GenerateGUID());
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);     // CASH payment method
        Vendor.Modify();
    end;

    procedure CreateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; VendorNo: Code[20]; BankAccountNo: Code[30])
    var
        Vendor: Record Vendor;
    begin
        VendorBankAccount.Init();
        VendorBankAccount.Validate("Vendor No.", VendorNo);
        VendorBankAccount.Validate(Code, LibraryUtility.GenerateGUID());
        VendorBankAccount.Validate("Bank Account No.", BankAccountNo);
        VendorBankAccount.Insert(true);

        Vendor.SetLoadFields("Preferred Bank Account Code");
        Vendor.Get(VendorNo);
        Vendor."Preferred Bank Account Code" := VendorBankAccount.Code;
        Vendor.Modify();
    end;
    #endregion Vendor

    procedure SaveIRISUserID()
    var
        UserParamsIRIS: Record "User Params IRIS";
    begin
        UserParamsIRIS.GetRecord();
        SavedIRISUserIDKey := UserParamsIRIS."IRIS User ID Key";
        IRISUserIDSaved := not IsNullGuid(SavedIRISUserIDKey);
    end;

    procedure RestoreIRISUserID()
    var
        UserParamsIRIS: Record "User Params IRIS";
    begin
        if not IRISUserIDSaved then
            exit;
        UserParamsIRIS.GetRecord();
        UserParamsIRIS."IRIS User ID Key" := SavedIRISUserIDKey;
        UserParamsIRIS.Modify();
    end;

    [NonDebuggable]
    procedure InitializeIRISUserID()
    var
        UserParamsIRIS: Record "User Params IRIS";
        OAuthClient: Codeunit "OAuth Client IRIS";
        NewTokenKey: Guid;
        IRISUserID: Text;
        IRISUserIDSecret: SecretText;
    begin
        IRISUserID := 'test-user-id';
        IRISUserIDSecret := IRISUserID;
        OAuthClient.SetToken(NewTokenKey, IRISUserIDSecret);
        UserParamsIRIS.GetRecord();
        UserParamsIRIS."IRIS User ID Key" := NewTokenKey;
        UserParamsIRIS.Modify();
    end;

    procedure GetUniqueTIN(): Text[30]
    var
        SeqNo: Integer;
        SeqNoText: Text;
    begin
        if not NumberSequence.Exists(TINSequenceNameLbl) then
            NumberSequence.Insert(TINSequenceNameLbl, 0, 1, true);
        SeqNo := NumberSequence.Next(TINSequenceNameLbl);
        SeqNoText := Format(SeqNo);
        exit('00-09' + PadStr('', 5 - StrLen(SeqNoText), '0') + SeqNoText);
    end;
}
