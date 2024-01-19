// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security;

/// <summary>
/// An in-memory secret provider that can be populated with secrets from any source.
/// </summary>
#if not CLEAN24
#pragma warning disable AL0432
codeunit 3802 "In Memory Secret Provider" implements "Secret Provider", "Secret Provider v2"
#pragma warning restore AL0432
#else
codeunit 3802 "In Memory Secret Provider" implements "Secret Provider v2"
#endif
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        [NonDebuggable]
        InMemorySecretProviderImpl: Codeunit "In Memory Secret Prov Impl.";

    /// <summary>
    /// Adds a secret to the secret provider. If the secret is already present in the secret provider, its value will be overwritten.
    /// </summary>
    /// <param name="SecretName">The name of the secret.</param>
    /// <param name="SecretValue">The value of the secret.</param>
    [NonDebuggable]
    procedure AddSecret(SecretName: Text; SecretValue: Text)
    begin
        InMemorySecretProviderImpl.AddSecret(SecretName, SecretValue);
    end;

    /// <summary>
    /// Retrieves a secret value from the secret provider.
    /// </summary>
    /// <param name="SecretName">The name of the secret to retrieve.</param>
    /// <param name="SecretValue">The value of the secret, or the empty string if the value could not be retrieved.</param>
    /// <returns>True if the secret value could be retrieved; false otherwise.</returns>
    [NonDebuggable]
    procedure GetSecret(SecretName: Text; var SecretValue: Text): Boolean
    begin
        exit(InMemorySecretProviderImpl.GetSecret(SecretName, SecretValue));
    end;

    /// <summary>
    /// Retrieves a secret value from the secret provider.
    /// </summary>
    /// <param name="SecretName">The name of the secret to retrieve.</param>
    /// <param name="SecretValue">SecretText containing the value of the secret, or the empty string if the value could not be retrieved.</param>
    /// <returns>True if the secret value could be retrieved; false otherwise.</returns>
    [NonDebuggable]
    procedure GetSecret(SecretName: Text; var SecretValue: SecretText): Boolean
    begin
        exit(InMemorySecretProviderImpl.GetSecret(SecretName, SecretValue));
    end;

}
