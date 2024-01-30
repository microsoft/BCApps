// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security;

/// <summary>
/// Abstraction for secret providers.
/// </summary>
interface "Secret Provider v2"
{
    /// <summary>
    /// Retrieves a secret value.
    /// </summary>
    /// <param name="SecretName">The name of the secret to retrieve.</param>
    /// <param name="SecretValue">The value of the secret, or the empty string if the value could not be retrieved.</param>
    /// <returns>True if the secret value could be retrieved; false otherwise.</returns>
    procedure GetSecret(SecretName: Text; var SecretValue: Text): Boolean

    /// <summary>
    /// Retrieves a secret value.
    /// </summary>
    /// <param name="SecretName">The name of the secret to retrieve.</param>
    /// <param name="SecretValue">SecretText containing the value of the secret, or the empty string if the value could not be retrieved.</param>
    /// <returns>True if the secret value could be retrieved; false otherwise.</returns>
    procedure GetSecret(SecretName: Text; var SecretValue: SecretText): Boolean
}
