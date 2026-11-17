// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

using System.Testability;

enumextension 130453 "Test Environment Handler" extends DefaultTestHandler
{
    value(130453; "Test Environment")
    {
        Implementation = ITestHandler = "ALTestRunner Reset Environment";
    }
}
