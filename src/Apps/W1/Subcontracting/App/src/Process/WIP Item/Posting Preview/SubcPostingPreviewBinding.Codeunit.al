// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Finance.GeneralLedger.Preview;

codeunit 99001565 "Subc. Posting Preview Binding"
{
#if not CLEAN29
    var
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", OnAfterBindSubscription, '', true, false)]
    local procedure BindPostPrevEventHandlerOnAfterBindSubscription()
    begin
        TryBindPostingPreviewHandler();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", OnAfterUnbindSubscription, '', true, false)]
    local procedure UnbindPostPrecEventHandlerOnAfterUnbindSubscription()
    begin
        TryUnbindPostingPreviewHandler();
    end;

    local procedure TryBindPostingPreviewHandler(): Boolean
    var
        SubcPostingPreviewHandler: Codeunit "Subc. Pst. Prev. Event Handler";
    begin
#if not CLEAN29
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
            exit;
#endif
        SubcPostingPreviewHandler.DeleteAll();
        exit(BindSubscription(SubcPostingPreviewHandler));
    end;

    local procedure TryUnbindPostingPreviewHandler(): Boolean
    var
        SubcPostingPreviewHandler: Codeunit "Subc. Pst. Prev. Event Handler";
    begin
#if not CLEAN29
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
            exit;
#endif
        exit(UnbindSubscription(SubcPostingPreviewHandler));
    end;
}
