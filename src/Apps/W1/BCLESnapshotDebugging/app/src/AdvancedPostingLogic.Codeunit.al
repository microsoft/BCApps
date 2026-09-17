namespace Microsoft.Samples.BCLESnapshotDebugging;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.Posting;

codeunit 99999 "Advanced Posting Logic"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
    procedure AdvancedChecksOnBeforePostPurchaseDoc(var PurchaseHeader: Record "Purchase Header")
    begin
        if (PurchaseHeader."Payment Terms Code" = '') or (PurchaseHeader."Payment Method Code" = '') or (PurchaseHeader."Payment Reference" = '') then
            Error('Advanced checks failed');
    end;
}