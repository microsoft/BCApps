// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

permissionset 149031 "AI Test Toolkit - Obj"
{
    Assignable = false;
    Access = Public;

    Permissions = table "AIT Header" = X,
        table "AIT Line" = X,
        table "AIT Log Entry" = X,
        codeunit "AIT Header" = X,
        codeunit "AIT Install" = X,
        codeunit "AIT Line" = X,
        codeunit "AIT Test Runner" = X,
        codeunit "AIT Start Tests" = X,
        codeunit "AIT Test Context" = X,
        codeunit "AIT Test Suite" = X,
        xmlport "AIT Import/Export" = X,
        xmlport "AIT Log Entries" = X,
        page "AIT CommandLine Card" = X,
        page "AIT Lines" = X,
        page "AIT Lines Compare" = X,
        page "AIT Log Entries" = X,
        page "AIT Log Entry API" = X,
        page "AIT Setup Card" = X,
        page "AIT Setup List" = X,
        page "AIT Suite API" = X,
        page "AIT Suite Line API" = X;
}