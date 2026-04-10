// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI.DocumentIntelligence;

/// <summary>
/// The supported model types for Azure Document Intelligence.
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
    /// Receipt model type.
    /// </summary>
    value(1; Receipt)
    {
    }

}