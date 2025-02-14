// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;
using System.AI.DocumentIntelligence;

/// <summary>
/// The supported service types for Azure AI.
/// </summary>
enum 7778 "Azure AI Service Type" implements "AI Service Name"
{
    Access = Public;
    Extensible = false;

    /// <summary>
    /// Azure OpenAI service type.
    /// </summary>
    value(0; "Azure OpenAI")
    {
        Caption = 'Azure OpenAI';
        Implementation = "AI Service Name" = "Azure OpenAI Impl";
    }

    /// <summary>
    /// Azure Document Intelligence service type.
    /// </summary>
    value(1; "Azure Document Intelligence")
    {
        Caption = 'Azure Document Intelligence';
        Implementation = "AI Service Name" = "Azure DI Impl.";
    }
}