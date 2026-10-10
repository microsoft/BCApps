// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

/// <summary>
/// Optional metadata capability for binding an operation to a configured storage destination.
/// </summary>
interface "External File Storage Context"
{
    /// <summary>
    /// Gets a versioned, secret-free descriptor of every setting affecting destination resolution.
    /// This method must not transfer files, authenticate, or make network requests.
    /// </summary>
    /// <param name="AccountId">The account whose destination is described.</param>
    /// <param name="LockAccount">Acquire update isolation until the caller's transaction ends. Never use around a network request.</param>
    /// <param name="DestinationDescriptor">Unambiguous, consistently serialized configuration, excluding credentials and secret contents.</param>
    /// <param name="ChangeGeneration">Persistent generation changing on every account update, including changes away and back.</param>
    /// <returns>False if the account is missing, disabled, or cannot provide a binding.</returns>
    procedure GetDestinationContext(AccountId: Guid; LockAccount: Boolean; var DestinationDescriptor: Text; var ChangeGeneration: BigInteger): Boolean;
}
