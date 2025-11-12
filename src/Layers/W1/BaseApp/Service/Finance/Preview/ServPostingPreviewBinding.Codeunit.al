// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Preview;

codeunit 6496 "Serv. Posting Preview Binding"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnAfterBindSubscription', '', false, false)]
    local procedure BindPostPrevEventHandlerOnAfterBindSubscription()
    begin
        TryBindPostingPreviewHandler();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnAfterUnbindSubscription', '', false, false)]
    local procedure UnbindPostPrecEventHandlerOnAfterUnbindSubscription()
    begin
        TryUnbindPostingPreviewHandler();
    end;

    local procedure TryBindPostingPreviewHandler(): Boolean
    var
        ServPostingPreviewHandler: Codeunit "Serv. Posting Preview Handler";
    begin
        ServPostingPreviewHandler.DeleteAll();
        exit(BindSubscription(ServPostingPreviewHandler));
    end;

    local procedure TryUnbindPostingPreviewHandler(): Boolean
    var
        ServPostingPreviewHandler: Codeunit "Serv. Posting Preview Handler";
    begin
        exit(UnbindSubscription(ServPostingPreviewHandler));
    end;
}
