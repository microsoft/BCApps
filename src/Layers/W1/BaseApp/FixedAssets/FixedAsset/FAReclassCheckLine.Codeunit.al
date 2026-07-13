// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

codeunit 5641 "FA Reclass. Check Line"
{
    TableNo = "FA Reclass. Journal Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if not IsHandled then begin
            if (Rec."FA No." = '') and (Rec."New FA No." = '') then
                exit;
            if (Rec."FA No." = '') and (Rec."New FA No." <> '') then
                Rec.TestField("FA No.");
            if (Rec."FA No." <> '') and (Rec."New FA No." = '') then
                Rec.TestField("New FA No.");
            Rec.TestField("FA Posting Date");
            Rec.TestField("FA No.");
            Rec.TestField("New FA No.");
            Rec.TestField("Depreciation Book Code");
            if DeprBookCode = '' then
                DeprBookCode := Rec."Depreciation Book Code";

            if Rec."Depreciation Book Code" <> DeprBookCode then
                Rec.FieldError("Depreciation Book Code", Text000);
        end;
        OnAfterOnRun(Rec);
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'must be the same in all journal lines';
#pragma warning restore AA0074
        DeprBookCode: Code[10];

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var FAReclassJournalLine: Record "FA Reclass. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var FAReclassJournalLine: Record "FA Reclass. Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

