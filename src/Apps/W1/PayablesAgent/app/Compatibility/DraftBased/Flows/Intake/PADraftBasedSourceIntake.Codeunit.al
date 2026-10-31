// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;

// Starts V1 processing after the source exists. The import subscriber performs Agent Task admission.
codeunit 3333 "PA Draft Based Source Intake"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "E-Document" = RM;

    internal procedure ProcessIncomingSource(SourceId: Guid)
    var
        EDocument: Record "E-Document";
        EDocImport: Codeunit "E-Doc. Import";
        SourceNotFoundErr: Label 'The task source does not exist.';
    begin
        if not EDocument.GetBySystemId(SourceId) then
            Error(SourceNotFoundErr);
        EDocImport.ProcessAutomaticallyIncomingEDocument(EDocument);
    end;
}
