// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

permissionset 149031 "BC Copilot Test Toolkit - Obj"
{
    Assignable = false;
    Access = Public;

    Permissions = table "BCCT Header" = X,
        table "BCCT Line" = X,
        table "BCCT Log Entry" = X,
        table "BCCT Dataset" = X,
        table "BCCT Dataset Line" = X,
        codeunit "BCCT Header" = X,
        codeunit "BCCT Install" = X,
        codeunit "BCCT Line" = X,
        codeunit "AIT Test Runner" = X,
        codeunit "BCCT Start Tests" = X,
        codeunit "BCCT Test Context" = X,
        codeunit "BCCT Test Suite" = X,
        xmlport "BCCT Import/Export" = X,
        xmlport "BCCT Log Entries" = X,
        page "BCCT CommandLine Card" = X,
        page "BCCT Lines" = X,
        page "BCCT Lines Compare" = X,
        page "BCCT Log Entries" = X,
        page "BCCT Log Entry API" = X,
        page "BCCT Setup Card" = X,
        page "BCCT Setup List" = X,
        page "BCCT Suite API" = X,
        page "BCCT Suite Line API" = X;
}