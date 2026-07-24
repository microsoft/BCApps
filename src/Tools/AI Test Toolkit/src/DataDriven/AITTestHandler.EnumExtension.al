// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Testability;

/// <summary>
/// Registers the AI Test Toolkit's <see cref="AIT Test Handler"/> under the platform <c>TestHandler</c> enum so that
/// migrated language-first eval codeunits can subscribe to it via <c>TestHandlers = "AIT Test Handler"</c>.
/// </summary>
enumextension 149035 "AIT Test Handler Ext" extends TestHandler
{
    value(149035; "AIT Test Handler")
    {
        Implementation = ITestHandler = "AIT Test Handler";
    }
}
