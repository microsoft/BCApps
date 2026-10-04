// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Posting;
using Microsoft.QualityManagement.Integration.Receiving;

/// <summary>
/// Manually-bound subscriber that records the tracking buffers seen during purchase receipt posting,
/// so tests can verify that each purchase inspection attempt receives a single tracking record and
/// that posting gets its own tracking buffer back without the receiving integration's filters.
/// </summary>
codeunit 139974 "Qlty. Receiving Buffer Subscr."
{
    EventSubscriberInstance = Manual;

    var
        AttemptTrackingBufferCounts: List of [Integer];
        AttemptLotNos: List of [Code[50]];
        QtyHandledFilterOnInsertTrackingSpecification: Text;
        InsertTrackingSpecificationRaised: Boolean;

    procedure GetAttemptTrackingBufferCounts(): List of [Integer]
    begin
        exit(AttemptTrackingBufferCounts);
    end;

    procedure GetAttemptLotNos(): List of [Code[50]]
    begin
        exit(AttemptLotNos);
    end;

    procedure WasInsertTrackingSpecificationRaised(): Boolean
    begin
        exit(InsertTrackingSpecificationRaised);
    end;

    procedure GetQtyHandledFilterOnInsertTrackingSpecification(): Text
    begin
        exit(QtyHandledFilterOnInsertTrackingSpecification);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Qlty. Receiving Integration", 'OnBeforePurchaseAttemptCreateInspectionWithPurchaseLine', '', false, false)]
    local procedure RecordTrackingBufferOnBeforePurchaseAttemptCreateInspectionWithPurchaseLine(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
        AttemptTrackingBufferCounts.Add(TempTrackingSpecification.Count());
        AttemptLotNos.Add(TempTrackingSpecification."Lot No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforeInsertTrackingSpecification', '', false, false)]
    local procedure RecordFiltersOnBeforeInsertTrackingSpecification(PurchHeader: Record "Purchase Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
        InsertTrackingSpecificationRaised := true;
        QtyHandledFilterOnInsertTrackingSpecification := TempTrackingSpecification.GetFilter("Quantity Handled (Base)");
    end;
}
