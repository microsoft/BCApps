// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Apps.ExtensionGeneration;

codeunit 2507 "Dataverse Table Builder"
{
    Access = Public;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        DataverseTableBuilderImpl: Codeunit "Dataverse Table Builder Impl.";

    procedure BeginGeneration(OverwriteExisting: Boolean): Boolean
    begin
        exit(DataverseTableBuilderImpl.StartGeneration(OverwriteExisting));
    end;

    procedure UpdateExistingTable(TableId: Integer; FieldsToAdd: List of [Text]; DataverseSchema: Text): Boolean
    begin
        exit(DataverseTableBuilderImpl.UpdateExistingTable(TableId, FieldsToAdd, DataverseSchema));
    end;

    procedure CommitGeneration(): Boolean
    begin
        exit(DataverseTableBuilderImpl.CommitGeneration());
    end;
}