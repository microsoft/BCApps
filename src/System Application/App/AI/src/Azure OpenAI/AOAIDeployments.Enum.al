// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// The version of the Copilot Deployment.
/// </summary>
enum 7776 "AOAI Deployment Version"
{
    Access = Public;
    Extensible = false;

    /// <summary>
    /// GPT 3.5 Turbo latest version.
    /// </summary>
    value(0; "GPT 3.5 Turbo Latest v1")
    {
    }

    /// <summary>
    /// GPT 3.5 Turbo preview of newer model version.
    /// </summary>
    value(1; "GPT 3.5 Turbo Preview v1")
    {
    }

    /// <summary>
    /// GPT 4 latest version.
    /// </summary>
    value(2; "GPT 4 Latest v1")
    {
    }

    /// <summary>
    /// GPT 4 preview of newer model version.
    /// </summary>
    value(3; "GPT 4 Preview v1")
    {
    }
}