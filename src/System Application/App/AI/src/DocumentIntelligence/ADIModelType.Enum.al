// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// The supported model types for Azure OpenAI.
/// </summary>
enum 7779 "ADI Model Type"
{
    Access = Public;
    Extensible = false;

    /// <summary>
    /// Invoice model type.
    /// </summary>
    value(0; Invoice)
    {
    }

    /// <summary>
    /// Recepit model type.
    /// </summary>
    value(1; Recepit)
    {
    }

}