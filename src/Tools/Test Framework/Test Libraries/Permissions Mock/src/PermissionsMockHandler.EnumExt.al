// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Security.AccessControl;

using System.Testability;

enumextension 131006 "Permissions Mock Handler" extends DefaultTestHandler
{
    value(131006; "Permissions Mock")
    {
        Implementation = ITestHandler = "Permissions Mock";
    }
}
