// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// Interface for providing naming information for a given AI service.
/// </summary>
interface "AI Service Name"
{

    /// <summary>
    /// Get the name of the service.
    /// </summary>
    /// <returns>The name of the service.</returns>
    procedure GetServiceName(): Text[250];

    /// <summary>
    /// Get the id of the service. Will often be the service name in Code form.
    /// </summary>
    /// <returns>The id of the service.</returns>
    procedure GetServiceId(): Code[50];

}