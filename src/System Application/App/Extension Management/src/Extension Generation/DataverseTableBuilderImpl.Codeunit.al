// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Apps.ExtensionGeneration;

using System;

codeunit 2508 "Dataverse Table Builder Impl."
{
    Access = Internal;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        NavDesignerALFunctions: DotNet NavDesignerALFunctions;
        GenerationInProgress: Boolean;
        GenerationNotStartedErr: Label 'Generation has not been started. Start generation first.';

    internal procedure StartGeneration(OverwriteExisting: Boolean): Boolean
    begin
        if OverwriteExisting then
            NavDesignerALFunctions.Clear();

        GenerationInProgress := NavDesignerALFunctions.StartCRMDesigner();
        exit(GenerationInProgress);
    end;

    internal procedure UpdateExistingTable(TableId: Integer; FieldsToAdd: List of [Text]; DataverseSchema: Text): Boolean
    begin
        if not GenerationInProgress then
            Error(GenerationNotStartedErr);

        exit(NavDesignerALFunctions.AddCRMTableFields(TableId, FieldsToAdd, DataverseSchema));
    end;

    internal procedure CommitGeneration(): Boolean
    begin
        if not GenerationInProgress then
            Error(GenerationNotStartedErr);

        GenerationInProgress := not NavDesignerALFunctions.SaveCRMDesigner();
        exit(not GenerationInProgress);
    end;
}
