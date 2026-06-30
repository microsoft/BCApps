using Microsoft.Finance.VAT.Ledger;

codeunit 134241 "GL VAT Recon. Adjust Subs."
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"VAT Entry", OnBeforeSetGLAccountNo, '', false, false)]
    local procedure PreApproveAdjustmentOnBeforeSetGLAccountNo(var VATEntry: Record "VAT Entry"; var IsHandled: Boolean; var Response: Boolean)
    begin
        // Pre-approve the adjustment via the event so the confirm dialog is skipped and processing continues.
        // IsHandled is intentionally left false so the standard G/L Account No. adjustment logic still runs.
        Response := true;
    end;
}
