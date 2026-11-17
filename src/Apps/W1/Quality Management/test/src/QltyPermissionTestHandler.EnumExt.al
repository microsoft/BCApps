// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using System.Testability;

enumextension 139979 "Qlty. Permission Test Handler" extends TestHandler
{
    value(139979; "Qlty. Permission Fixture")
    {
        Implementation = ITestHandler = "Qlty. Permission Test Fixture";
    }
    value(139978; "Qlty. Fixture Cleanup")
    {
        Implementation = ITestHandler = "Qlty. Fixture Test Handler";
    }
}
