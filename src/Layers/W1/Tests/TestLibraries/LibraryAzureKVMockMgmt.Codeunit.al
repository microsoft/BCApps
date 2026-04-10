codeunit 131021 "Library - Azure KV Mock Mgmt."
{

    trigger OnRun()
    begin
    end;

    var
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        MockAzureKeyvaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;

    [Scope('OnPrem')]
    procedure InitMockAzureKeyvaultSecretProvider()
    begin
        MockAzureKeyvaultSecretProvider :=
          MockAzureKeyvaultSecretProvider.MockAzureKeyVaultSecretProvider();
    end;

    [Scope('OnPrem')]
    procedure AddMockAzureKeyvaultSecretProviderMappingFromFile(SecretName: Text; FilePath: Text)
    begin
        MockAzureKeyvaultSecretProvider.AddSecretMappingFromFile(SecretName, FilePath);
    end;

    [Scope('OnPrem')]
    procedure AddMockAzureKeyvaultSecretProviderMapping(SecretName: Text; SecretValue: Text)
    begin
        MockAzureKeyvaultSecretProvider.AddSecretMapping(SecretName, SecretValue);
    end;

    [Scope('OnPrem')]
    procedure UseAzureKeyvaultSecretProvider()
    begin
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyvaultSecretProvider);
    end;

    [Scope('OnPrem')]
    procedure EnsureSecretNameIsAllowed(SecretName: Text)
    var
        SecretNames: Text;
    begin
        SecretNames := MockAzureKeyvaultSecretProvider.GetSecret('AllowedApplicationSecrets');
        MockAzureKeyvaultSecretProvider.AddSecretMapping('AllowedApplicationSecrets', StrSubstNo('%1,%2', SecretNames, SecretName));
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyvaultSecretProvider);
    end;
}

