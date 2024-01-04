// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Integration.Graph.Authorization;

using System.RestClient;

/// <summary>
/// Common interface for different authorization options.
/// </summary>
interface "Graph Authorization"
{
    /// <summary>
    /// Returns an Http Authentication Instance
    /// </summary> 
    procedure GetHttpAuthorization(): Interface "Http Authentication"
}