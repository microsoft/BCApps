// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

codeunit 130485 "Test Input Rollback Probe"
{
    trigger OnRun()
    var
        DataTools: Codeunit "Test Input Data Tools";
        Value: Text;
        RollbackErr: Label 'Rolling back placeholder probe writes.';
    begin
        DataTools.SetPlaceholder('RollbackExisting', 'uncommitted');
        DataTools.SetPlaceholder('RollbackInserted', 'uncommitted');
        DataTools.DeletePlaceholder('RollbackDeleted');

        // Exercise both successful and missing reads before their transaction is rolled back.
        DataTools.GetPlaceholder('RollbackExisting', Value);
        DataTools.GetPlaceholder('RollbackInserted', Value);
        DataTools.GetPlaceholder('RollbackDeleted', Value);
        Error(RollbackErr);
    end;
}
