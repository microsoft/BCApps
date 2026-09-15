// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.DE;

using Microsoft.Peppol;

codeunit 37405 "PEPPOL30 DE Subscribers"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"PEPPOL 3.0 Setup", OnAfterInsertEvent, '', false, false)]
    local procedure OnAfterInsertPEPPOL30Setup(var Rec: Record "PEPPOL 3.0 Setup"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        Rec."PEPPOL 3.0 Sales Format" := Rec."PEPPOL 3.0 Sales Format"::"PEPPOL 3.0 - Sales DE";
        Rec."PEPPOL 3.0 Service Format" := Rec."PEPPOL 3.0 Service Format"::"PEPPOL 3.0 - Service DE";
        Rec.Modify();
    end;
}
