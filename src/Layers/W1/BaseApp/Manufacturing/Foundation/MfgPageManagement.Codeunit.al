// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Manufacturing.Document;

codeunit 99000791 "Mfg. Page Management"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Page Management", 'OnConditionalCardPageIDNotFound', '', false, false)]
    local procedure OnConditionalCardPageIDNotFound(RecordRef: RecordRef; var CardPageID: Integer);
    begin
        case RecordRef.Number of
            Database::"Production Order":
                CardPageID := GetProductionOrderPageID(RecordRef);
        end;
    end;

    local procedure GetProductionOrderPageID(RecRef: RecordRef): Integer
    var
        ProductionOrder: Record "Production Order";
    begin
        RecRef.SetTable(ProductionOrder);
        case ProductionOrder.Status of
            ProductionOrder.Status::Simulated:
                exit(PAGE::"Simulated Production Order");
            ProductionOrder.Status::Planned:
                exit(PAGE::"Planned Production Order");
            ProductionOrder.Status::"Firm Planned":
                exit(PAGE::"Firm Planned Prod. Order");
            ProductionOrder.Status::Released:
                exit(PAGE::"Released Production Order");
            ProductionOrder.Status::Finished:
                exit(PAGE::"Finished Production Order");
        end;
    end;

#if not CLEAN27
    [Obsolete('This event added by mistake to Mfg part, use correct event in ServPageManagement codeunit', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetServiceHeaderPageID(RecRef: RecordRef; ServiceHeader: Record Microsoft.Service.Document."Service Header"; var Result: Integer)
    begin
    end;
#endif
}
