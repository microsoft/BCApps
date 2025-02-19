// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Azure.KeyVault;

using System.Security.Encryption;
using System.Environment;

/// <summary>
///
/// </summary>
codeunit 2202 "Azure Key Vault Impl."
{
    Access = Internal;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        [NonDebuggable]
        NavAzureKeyVaultClient: DotNet AzureKeyVaultClientHelper;
        [NonDebuggable]
        AzureKeyVaultSecretProvider: DotNet IAzureKeyVaultSecretProvider;
        [NonDebuggable]
        CachedSecretsDictionary: Dictionary of [Text, Text];
        [NonDebuggable]
        CachedCertificatesDictionary: Dictionary of [Text, Text];
        IsKeyVaultClientInitialized: Boolean;
        AzureKeyVaultTxt: Label 'Azure Key Vault', Locked = true;
        CertificateInfoTxt: Label 'Successfully constructed certificate from secret %1. Certificate thumbprint %2', Locked = true;
        MissingSecretErr: Label 'The secret %1 is either missing or empty.', Comment = '%1 = Secret Name.';

    [NonDebuggable]
    procedure GetAzureKeyVaultSecret(SecretName: Text; var Secret: Text)
    begin
        // Gets the secret as a Text from the key vault, given a SecretName.
        Secret := GetSecretFromClient(SecretName);

        if Secret.Trim() = '' then
            Error(MissingSecretErr, SecretName);
    end;

    [NonDebuggable]
    procedure GetAzureKeyVaultSecret(SecretName: Text; var Secret: SecretText)
    begin
        Secret := GetSecretFromClient(SecretName);

        if Secret.IsEmpty() then
            Error(MissingSecretErr, SecretName);
    end;

    [NonDebuggable]
    procedure GetAzureKeyVaultCertificate(CertificateName: Text; var Certificate: Text)
    begin
        // Gets the certificate as a base 64 encoded string from the key vault, given a CertificateName.

        Certificate := GetCertificateFromClient(CertificateName);
    end;

    [NonDebuggable]
    procedure GetAzureKeyVaultCertificate(CertificateName: Text; var Certificate: SecretText)
    begin
        // Gets the certificate as a base 64 encoded string from the key vault, given a CertificateName.

        Certificate := GetCertificateFromClient(CertificateName);
    end;

    [NonDebuggable]
    procedure SetAzureKeyVaultSecretProvider(NewAzureKeyVaultSecretProvider: DotNet IAzureKeyVaultSecretProvider)
    begin
        // Sets the secret provider to simulate the vault. Used for testing.

        ClearSecrets();
        AzureKeyVaultSecretProvider := NewAzureKeyVaultSecretProvider;
    end;

    [NonDebuggable]
    procedure ClearSecrets()
    begin
        Clear(NavAzureKeyVaultClient);
        Clear(AzureKeyVaultSecretProvider);
        Clear(CachedSecretsDictionary);
        Clear(CachedCertificatesDictionary);
        IsKeyVaultClientInitialized := false;
    end;

    [NonDebuggable]
    local procedure GetSecretFromClient(SecretName: Text) Secret: Text
    begin
        if CachedSecretsDictionary.ContainsKey(SecretName) then begin
            Secret := CachedSecretsDictionary.Get(SecretName);
            exit;
        end;

        if not IsKeyVaultClientInitialized then begin
            NavAzureKeyVaultClient := NavAzureKeyVaultClient.AzureKeyVaultClientHelper();
            NavAzureKeyVaultClient.SetAzureKeyVaultProvider(AzureKeyVaultSecretProvider);
            IsKeyVaultClientInitialized := true;
        end;
        Secret := NavAzureKeyVaultClient.GetAzureKeyVaultSecret(SecretName);

        CachedSecretsDictionary.Add(SecretName, Secret);
    end;

    [NonDebuggable]
    local procedure GetCertificateFromClient(CertificateName: Text) Certificate: Text
    var
        X509Certificate2: Codeunit X509Certificate2;
        EnvironmentInformation: Codeunit "Environment Information";
        CertificateThumbprint: Text;
        EmptySecretText: SecretText;
    begin
        if CachedCertificatesDictionary.ContainsKey(CertificateName) then begin
            Certificate := CachedCertificatesDictionary.Get(CertificateName);
            exit;
        end;

        if not IsKeyVaultClientInitialized then begin
            NavAzureKeyVaultClient := NavAzureKeyVaultClient.AzureKeyVaultClientHelper();
            NavAzureKeyVaultClient.SetAzureKeyVaultProvider(AzureKeyVaultSecretProvider);
            IsKeyVaultClientInitialized := true;
        end;
        Certificate := NavAzureKeyVaultClient.GetAzureKeyVaultCertificate(CertificateName);
        if EnvironmentInformation.IsSaaS() then begin
            X509Certificate2.GetCertificateThumbprint(Certificate, EmptySecretText, CertificateThumbprint);
            if CertificateThumbprint <> '' then
                Session.LogMessage('0000C17', StrSubstNo(CertificateInfoTxt, CertificateName, CertificateThumbprint), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureKeyVaultTxt);
        end;
        CachedCertificatesDictionary.Add(CertificateName, Certificate);
    end;
}

