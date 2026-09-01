namespace Microsoft.SubscriptionBilling;

using Microsoft.Finance.GeneralLedger.Preview;

codeunit 8076 "Deferral Post. Preview Binding"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", OnAfterBindSubscription, '', false, false)]
    local procedure BindDeferralPreviewHandlerOnAfterBindSubscription()
    begin
        TryBindPostingPreviewHandler();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", OnAfterUnbindSubscription, '', false, false)]
    local procedure UnbindDeferralPreviewHandlerOnAfterUnbindSubscription()
    begin
        TryUnbindPostingPreviewHandler();
    end;

    local procedure TryBindPostingPreviewHandler(): Boolean
    var
        DeferralPostingPreviewHandler: Codeunit "Deferral Post. Preview Handler";
    begin
        DeferralPostingPreviewHandler.DeleteAll();
        exit(BindSubscription(DeferralPostingPreviewHandler));
    end;

    local procedure TryUnbindPostingPreviewHandler(): Boolean
    var
        DeferralPostingPreviewHandler: Codeunit "Deferral Post. Preview Handler";
    begin
        exit(UnbindSubscription(DeferralPostingPreviewHandler));
    end;
}
