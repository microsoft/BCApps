// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

codeunit 130485 "Test Input Rollback Probe"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        ExistingPlaceholderName: Text;
        InsertedPlaceholderName: Text;
        DeletedPlaceholderName: Text;

    trigger OnRun()
    var
        DataTools: Codeunit "Test Input Data Tools";
        Value: Text;
        RollbackErr: Label 'Rolling back placeholder probe writes.';
    begin
        DataTools.SetPlaceholder(ExistingPlaceholderName, 'uncommitted');
        DataTools.SetPlaceholder(InsertedPlaceholderName, 'uncommitted');
        DataTools.DeletePlaceholder(DeletedPlaceholderName);

        // Exercise both successful and missing reads before their transaction is rolled back.
        DataTools.GetPlaceholder(ExistingPlaceholderName, Value);
        DataTools.GetPlaceholder(InsertedPlaceholderName, Value);
        DataTools.GetPlaceholder(DeletedPlaceholderName, Value);
        Error(RollbackErr);
    end;

    procedure Configure(ExistingName: Text; InsertedName: Text; DeletedName: Text)
    begin
        ExistingPlaceholderName := ExistingName;
        InsertedPlaceholderName := InsertedName;
        DeletedPlaceholderName := DeletedName;
    end;
}
