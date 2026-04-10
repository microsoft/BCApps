// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

using Microsoft.Finance.GeneralLedger.Setup;

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

            CheckNewDeprBookCode(Rec);
        end;

        OnAfterOnRun(Rec);
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'must be the same in all journal lines';
#pragma warning restore AA0074
        GLSetup: Record "General Ledger Setup";
        DeprBookCode: Code[10];
        NewDeprBookCode: Code[10];
#pragma warning disable AA0074
        Text001: Label 'must be the same in all journal lines';
#pragma warning restore AA0074

    local procedure CheckNewDeprBookCode(FAReclassJnlLine: Record "FA Reclass. Journal Line")
    begin
        GLSetup.Get();
        if not GLSetup."Enable Russian Accounting" then
            exit;

        FAReclassJnlLine.TestField("New Depreciation Book Code");

        if NewDeprBookCode = '' then
            NewDeprBookCode := FAReclassJnlLine."New Depreciation Book Code";

        if FAReclassJnlLine."New Depreciation Book Code" <> NewDeprBookCode then
            FAReclassJnlLine.FieldError("New Depreciation Book Code", Text001);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var FAReclassJournalLine: Record "FA Reclass. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var FAReclassJournalLine: Record "FA Reclass. Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

