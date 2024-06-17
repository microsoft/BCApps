// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// The supported utilization models for Azure OpenAI resources.
/// </summary>
enum 7771 "AOAI Resource Utilization"
{
    Access = Internal;
    Extensible = false;

    /// <summary>
    /// The first party utilization (only available for Microsoft first party apps).
    /// </summary>
    value(0; "First Party")
    {
    }

    /// <summary>
    /// The Microsoft managed utilization (the resource used for the LLM call is provided and managed by Microsoft).
    /// </summary>
    /// <remarks>A valid resource is still required to validate that the developer has access to Azure OpenAI.</remarks>
    value(1; "Microsoft Managed")
    {
    }

    /// <summary>
    /// The Self-managed utilization (the resource used for the LLM call is the one provided by the developer).
    /// </summary>
    value(2; "Self-Managed")
    {
    }
}