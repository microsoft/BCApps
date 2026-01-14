// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Inventory.Journal;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Journal;

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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Page Management", 'OnGetItemJournalTemplatePageID', '', false, false)]
    local procedure OnGetItemJournalTemplatePageID(ItemJournalTemplate: Record "Item Journal Template"; RecordRef: RecordRef; var CardPageID: Integer);
    begin
        case ItemJournalTemplate.Type of
            ItemJournalTemplate.Type::Capacity:
                CardPageID := Page::"Capacity Journal";
            ItemJournalTemplate.Type::Consumption:
                CardPageID := Page::"Consumption Journal";
            ItemJournalTemplate.Type::Output:
                CardPageID := Page::"Output Journal";
            ItemJournalTemplate.Type::"Prod. Order":
                CardPageID := Page::"Production Journal";
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
