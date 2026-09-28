// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.Sales.History;

codeunit 139787 "E-Doc. Item Chrg. Subscriber"
{
    EventSubscriberInstance = Manual;

    var
        StructureToReturn: Enum "Item Charge E-Doc. Structure";
        Invoked: Boolean;

    procedure SetStructure(NewStructure: Enum "Item Charge E-Doc. Structure")
    begin
        StructureToReturn := NewStructure;
    end;

    procedure WasInvoked(): Boolean
    begin
        exit(Invoked);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Item Charge Mapping", 'OnAfterGetItemChargeStructure', '', false, false)]
    local procedure OverrideStructureOnAfterGetItemChargeStructure(var Structure: Enum "Item Charge E-Doc. Structure"; var TargetSalesInvoiceLine: Record "Sales Invoice Line")
    begin
        Invoked := true;
        Structure := StructureToReturn;
        Clear(TargetSalesInvoiceLine);
    end;
}
