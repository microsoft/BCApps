// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

using Microsoft.CRM.Setup;
using System.Integration.Word;

codeunit 5070 "Custom Word Template Fields"
{
    Access = internal;

    var
        FormalSalutationTxt: Label 'Formal Salutation', Locked = true;
        InformalSalutationTxt: Label 'Informal Salutation', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Word Template", 'OnGetCustomFieldNames', '', false, false)]
    local procedure OnGetCustomFieldNames(WordTemplateCustomField: Codeunit "Word Template Custom Field")
    begin
        if WordTemplateCustomField.GetTableID() = Database::Contact then begin
            WordTemplateCustomField.AddField(FormalSalutationTxt);
            WordTemplateCustomField.AddField(InformalSalutationTxt);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Word Template", 'OnGetCustomRecordValues', '', false, false)]
    local procedure OnGetCustomRecordValues(WordTemplateFieldValue: Codeunit "Word Template Field Value")
    var
        Contact: Record Contact;
        RecordRef: RecordRef;
        Salutation: Text[260];
    begin
        RecordRef := WordTemplateFieldValue.GetRecord();
        if RecordRef.Number = Database::Contact then begin
            RecordRef.SetTable(Contact);

            if TryGetSalutation("Salutation Formula Salutation Type"::Formal, Contact, Salutation) then
                WordTemplateFieldValue.AddFieldValue(FormalSalutationTxt, Salutation);
            if TryGetSalutation("Salutation Formula Salutation Type"::Informal, Contact, Salutation) then
                WordTemplateFieldValue.AddFieldValue(InformalSalutationTxt, Salutation);
        end;
    end;

    [TryFunction]
    local procedure TryGetSalutation(SalutationFormulaSalutationType: Enum "Salutation Formula Salutation Type"; Contact: Record Contact; var Salutation: Text[260])
    var
        SalutationFormula: Record "Salutation Formula";
    begin
        if SalutationFormula.Get(Contact."Salutation Code", Contact."Language Code", SalutationFormulaSalutationType) then
            Salutation := Contact.GetSalutation(SalutationFormulaSalutationType, Contact."Language Code")
        else
            Salutation := Contact.GetSalutation(SalutationFormulaSalutationType, ''); // Fall back to the default language code

    end;
}
