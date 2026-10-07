// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.ExternalFileStorage;

using System.ExternalFileStorage;
using System.TestLibraries.Utilities;

codeunit 144583 "Ext. SP Account Table Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DestinationContextBindsNamespaceAndGeneration()
    var
        Account: Record "Ext. SharePoint Account";
        TempFileAccount: Record "File Account" temporary;
        Storage: Codeunit "External File Storage";
        Fingerprint: Text[64];
        ChangedFingerprint: Text[64];
        Generation: BigInteger;
        ChangedGeneration: BigInteger;
    begin
        Account.Id := CreateGuid();
        Account."SharePoint Url" := 'https://example.sharepoint.com/sites/test';
        Account."Base Relative Folder Path" := '/sites/test/Shared Documents';
        Account.Insert();
        TempFileAccount."Account Id" := Account.Id;
        TempFileAccount.Connector := Enum::"Ext. File Storage Connector"::SharePoint;
        Assert.IsTrue(Storage.GetDestinationContext(TempFileAccount, false, Fingerprint, Generation), 'Context should be metadata-only and need no authentication');
        Account."Base Relative Folder Path" := '/sites/test/Changed';
        Account.Modify();
        Assert.IsTrue(Storage.GetDestinationContext(TempFileAccount, false, ChangedFingerprint, ChangedGeneration), 'Changed context should be readable');
        Assert.AreNotEqual(Fingerprint, ChangedFingerprint, 'Base path must affect stable destination identity');
        Account."Base Relative Folder Path" := '/sites/test/Shared Documents';
        Account.Modify();
        Assert.IsTrue(Storage.GetDestinationContext(TempFileAccount, false, ChangedFingerprint, ChangedGeneration), 'Restored context should be readable');
        Assert.AreEqual(Fingerprint, ChangedFingerprint, 'Restored destination has the same stable identity');
        Assert.AreNotEqual(Generation, ChangedGeneration, 'Change-away-and-back must change the generation');
        Account."Use legacy REST API" := true;
        Account.Modify();
        Assert.IsTrue(Storage.GetDestinationContext(TempFileAccount, false, ChangedFingerprint, ChangedGeneration), 'REST context should be readable');
        Assert.AreNotEqual(Fingerprint, ChangedFingerprint, 'API/base-path interpretation must affect identity');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DestinationDescriptorExcludesCredentialsAndBlocksDisabledAccount()
    var
        Account: Record "Ext. SharePoint Account";
        Connector: Codeunit "Ext. SharePoint Connector Impl";
        Provider: Interface "External File Storage Context";
        Descriptor: Text;
        Generation: BigInteger;
    begin
        Account.Id := CreateGuid();
        Account."SharePoint Url" := 'https://example.sharepoint.com/sites/test';
        Account.Insert();
        Account.SetClientSecret(SecretStrSubstNo('test-credential-must-not-be-described'));
        Account.Modify();
        Provider := Connector;
        Assert.IsTrue(Provider.GetDestinationContext(Account.Id, false, Descriptor, Generation), 'Account should provide a descriptor');
        Assert.IsFalse(Descriptor.Contains('test-credential-must-not-be-described'), 'Descriptor must not expose credentials');
        Account.Disabled := true;
        Account.Modify();
        Assert.IsFalse(Provider.GetDestinationContext(Account.Id, false, Descriptor, Generation), 'Disabled account must not authorize cleanup');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestDefaultRestBaseFolderPathFormatIsUrl()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        Account.Init();
        Account.Id := CreateGuid();
        Account.Insert();

        Assert.AreEqual(
            Enum::"Ext. SharePoint Path Format"::URL, Account."REST Base Folder Path Format",
            'New and upgraded accounts must default to the existing URL interpretation');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestDefaultAuthTypeIsClientSecret()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN] A new account record is inserted
        Account.Init();
        Account.Id := CreateGuid();
        Account.Insert();

        // [THEN] Authentication Type defaults to Client Secret
        Assert.AreEqual(
            Enum::"Ext. SharePoint Auth Type"::"Client Secret",
            Account."Authentication Type",
            'Default authentication type should be Client Secret');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestDefaultUseLegacyRestAPIIsFalse()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN] A new account record is inserted
        Account.Init();
        Account.Id := CreateGuid();
        Account.Insert();

        // [THEN] Use legacy REST API defaults to false (Graph is the new default)
        Assert.IsFalse(Account."Use legacy REST API", 'Use legacy REST API should default to false');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestSetClientSecretClearsCertificateKeys()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN] An account with a certificate and certificate password already set
        Account.Init();
        Account.Id := CreateGuid();
        Account.Insert();
        Account.SetCertificate(SecretStrSubstNo('cert-data'));
        Account.SetCertificatePassword(SecretStrSubstNo('cert-password'));

        Assert.IsFalse(IsNullGuid(Account."Certificate Key"), 'Certificate Key should be set after SetCertificate');
        Assert.IsFalse(IsNullGuid(Account."Certificate Password Key"), 'Certificate Password Key should be set after SetCertificatePassword');

        // [WHEN] SetClientSecret is called
        Account.SetClientSecret(SecretStrSubstNo('secret-value'));

        // [THEN] Both certificate keys are cleared — only one authentication method can be active
        Assert.IsTrue(IsNullGuid(Account."Certificate Key"), 'Certificate Key should be cleared after SetClientSecret');
        Assert.IsTrue(IsNullGuid(Account."Certificate Password Key"), 'Certificate Password Key should be cleared after SetClientSecret');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestSetCertificateClearsClientSecretKey()
    var
        Account: Record "Ext. SharePoint Account";
    begin
        // [GIVEN] An account with a client secret already set
        Account.Init();
        Account.Id := CreateGuid();
        Account.Insert();
        Account.SetClientSecret(SecretStrSubstNo('secret-value'));

        Assert.IsFalse(IsNullGuid(Account."Client Secret Key"), 'Client Secret Key should be set after SetClientSecret');

        // [WHEN] SetCertificate is called
        Account.SetCertificate(SecretStrSubstNo('cert-data'));

        // [THEN] The client secret key is cleared
        Assert.IsTrue(IsNullGuid(Account."Client Secret Key"), 'Client Secret Key should be cleared after SetCertificate');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestClientSecretRoundTrip()
    var
        Account: Record "Ext. SharePoint Account";
        Retrieved: SecretText;
        ExpectedTxt: Text;
    begin
        // [GIVEN] An account
        Account.Init();
        Account.Id := CreateGuid();
        Account.Insert();

        // [WHEN] A client secret is stored and retrieved
        ExpectedTxt := 'my-secret-value';
        Account.SetClientSecret(SecretStrSubstNo(ExpectedTxt));
        Retrieved := Account.GetClientSecret(Account."Client Secret Key");

        // [THEN] The retrieved value matches
#pragma warning disable AL0796
        Assert.AreEqual(ExpectedTxt, Retrieved.Unwrap(), 'Retrieved client secret should match stored value');
#pragma warning restore AL0796
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestCertificateRoundTrip()
    var
        Account: Record "Ext. SharePoint Account";
        Retrieved: SecretText;
        ExpectedTxt: Text;
    begin
        // [GIVEN] An account
        Account.Init();
        Account.Id := CreateGuid();
        Account.Insert();

        // [WHEN] A certificate is stored and retrieved
        ExpectedTxt := 'base64-cert-data';
        Account.SetCertificate(SecretStrSubstNo(ExpectedTxt));
        Retrieved := Account.GetCertificate(Account."Certificate Key");

        // [THEN] The retrieved value matches
#pragma warning disable AL0796
        Assert.AreEqual(ExpectedTxt, Retrieved.Unwrap(), 'Retrieved certificate should match stored value');
#pragma warning restore AL0796
    end;
}
