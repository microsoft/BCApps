// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using System.Utilities;

codeunit 8494 "IC Bank Acc. Recon. Line"
{
    var
        ICPartnerAccountTypeQst: Label 'The resulting entry will be of type IC Transaction, but no Intercompany Outbox transaction will be created. \\Do you want to use the IC Partner account type anyway?';

    [EventSubscriber(ObjectType::Table, Database::"Bank Acc. Reconciliation Line", 'OnValidateAccountTypeOnCheckICPartner', '', true, false)]
    local procedure OnValidateAccountTypeOnCheckICPartner(var Rec: Record "Bank Acc. Reconciliation Line"; var xRec: Record "Bank Acc. Reconciliation Line"; var IsHandled: Boolean)
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if Rec."Account Type" = Rec."Account Type"::"IC Partner" then
            if not ConfirmManagement.GetResponse(ICPartnerAccountTypeQst, false) then begin
                Rec."Account Type" := xRec."Account Type";
                IsHandled := true;
            end;
    end;
}
