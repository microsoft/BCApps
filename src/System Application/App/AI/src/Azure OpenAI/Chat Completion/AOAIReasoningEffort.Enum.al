// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// Specifies the reasoning effort for Azure OpenAI reasoning models.
/// Controls how much internal reasoning the model performs before generating a response.
/// </summary>
enum 7780 "AOAI Reasoning Effort"
{
    Extensible = false;

    /// <summary>
    /// Low reasoning effort. Fastest response with less in-depth reasoning.
    /// </summary>
    value(1; Low)
    {
        Caption = 'low', Locked = true;
    }

    /// <summary>
    /// Medium reasoning effort. Balances response speed and reasoning depth.
    /// </summary>
    value(2; Medium)
    {
        Caption = 'medium', Locked = true;
    }

    /// <summary>
    /// High reasoning effort. Slowest response with the most in-depth reasoning.
    /// </summary>
    value(3; High)
    {
        Caption = 'high', Locked = true;
    }
}
