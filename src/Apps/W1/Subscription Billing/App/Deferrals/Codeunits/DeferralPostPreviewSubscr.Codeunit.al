namespace Microsoft.SubscriptionBilling;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Foundation.Navigate;

codeunit 8078 "Deferral Post. Preview Subscr."
{
    var
        TempCustSubContractDeferral: Record "Cust. Sub. Contract Deferral" temporary;
        TempVendSubContractDeferral: Record "Vend. Sub. Contract Deferral" temporary;
        PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", OnGetEntries, '', false, false)]
    local procedure GetEntriesOnGetEntries(TableNo: Integer; var RecRef: RecordRef)
    begin
        GetAllTables();
        case TableNo of
            Database::"Cust. Sub. Contract Deferral":
                RecRef.GetTable(TempCustSubContractDeferral);
            Database::"Vend. Sub. Contract Deferral":
                RecRef.GetTable(TempVendSubContractDeferral);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", OnAfterShowEntries, '', false, false)]
    local procedure ShowEntriesOnAfterShowEntries(TableNo: Integer)
    begin
        GetAllTables();
        case TableNo of
            Database::"Cust. Sub. Contract Deferral":
                Page.Run(Page::"Customer Contract Deferrals", TempCustSubContractDeferral);
            Database::"Vend. Sub. Contract Deferral":
                Page.Run(Page::"Vendor Contract Deferrals", TempVendSubContractDeferral);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", OnAfterFillDocumentEntry, '', false, false)]
    local procedure FillDocumentEntryOnAfterFillDocumentEntry(var DocumentEntry: Record "Document Entry")
    begin
        GetAllTables();
        PostingPreviewEventHandler.InsertDocumentEntry(TempCustSubContractDeferral, DocumentEntry);
        PostingPreviewEventHandler.InsertDocumentEntry(TempVendSubContractDeferral, DocumentEntry);
    end;

    local procedure GetAllTables()
    var
        DeferralPostingPreviewHandler: Codeunit "Deferral Post. Preview Handler";
    begin
        DeferralPostingPreviewHandler.GetTempCustContractDeferral(TempCustSubContractDeferral);
        DeferralPostingPreviewHandler.GetTempVendContractDeferral(TempVendSubContractDeferral);
    end;
}
