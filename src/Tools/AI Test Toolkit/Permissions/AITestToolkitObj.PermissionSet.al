// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

permissionset 149031 "AI Test Toolkit - Obj"
{
    Assignable = false;
    Access = Public;

    Permissions = table "AIT Run History" = X,
        table "AIT Test Suite" = X,
        table "AIT Test Method Line" = X,
        table "AIT Log Entry" = X,
        codeunit "AIT AL Test Suite Mgt" = X,
        codeunit "AIT Install" = X,
        codeunit "AIT Log Entry" = X,
        codeunit "AIT Test Data" = X,
        codeunit "AIT Test Suite Mgt." = X,
        codeunit "AIT Test Run Iteration" = X,
        codeunit "AIT Test Context" = X,
        codeunit "AIT Test Context Impl." = X,
        codeunit "AIT Run History" = X,
        xmlport "AIT Test Suite Import/Export" = X,
        page "AIT CommandLine Card" = X,
        page "AIT Test Data" = X,
        page "AIT Test Data Compare" = X,
        page "AIT Batch Run Dialog" = X,
        page "AIT Test Method Lines" = X,
        page "AIT Test Method Lines Lookup" = X,
        page "AIT Log Entries" = X,
        page "AIT Log Entry API" = X,
        page "AIT Test Suite" = X,
        page "AIT Test Suite List" = X,
        page "AIT Run History" = X;
}