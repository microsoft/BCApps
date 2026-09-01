// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

codeunit 8944 "Email Address Lookup Impl"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    procedure GetSelectedSuggestionsAsText(var EmailAddressLookup: Record "Email Address Lookup"): Text
    var
        Recipients: Text;
    begin
        if EmailAddressLookup.FindSet() then
            repeat
                Recipients += EmailAddressLookup."E-Mail Address" + ';';
            until EmailAddressLookup.Next() = 0;
        exit(Recipients);
    end;

    procedure LookupEmailAddress(Entity: Enum "Email Address Entity"; var EmailAddressLookupRec: Record "Email Address Lookup"): Boolean
    var
        TempEmailAddressLookupSuggestions: Record "Email Address Lookup";
        EmailAddressLookup: Codeunit "Email Address Lookup";
        IsHandled: Boolean;
    begin
        EmailAddressLookup.OnLookupAddressFromEntity(Entity, TempEmailAddressLookupSuggestions, IsHandled);
        if not TempEmailAddressLookupSuggestions.FindSet() then
            exit(false);

        if IsHandled then begin
            repeat
                if StrLen(TempEmailAddressLookupSuggestions."E-Mail Address") = 0 then
                    Message(StrSubstNo(NoEmailAddressMsg, TempEmailAddressLookupSuggestions.Name))
                else
                    if EmailAddressLookupRec.Get(TempEmailAddressLookupSuggestions."E-Mail Address", TempEmailAddressLookupSuggestions."Entity type") then
                        Message(StrSubstNo(EmailAddressDuplicateMsg, TempEmailAddressLookupSuggestions."E-Mail Address"))
                    else begin
                        EmailAddressLookupRec.TransferFields(TempEmailAddressLookupSuggestions);
                        EmailAddressLookupRec.Insert();
                    end;
            until TempEmailAddressLookupSuggestions.Next() = 0;
            exit(IsHandled);
        end;
    end;

    var
        NoEmailAddressMsg: Label '%1 has no email address stored', Comment = '%1 suggested address';
        EmailAddressDuplicateMsg: Label 'Email address %1 already added', Comment = '%1 email address';
}