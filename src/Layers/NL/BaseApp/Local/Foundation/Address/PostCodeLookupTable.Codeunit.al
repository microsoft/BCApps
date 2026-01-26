// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

codeunit 11402 "Post Code Lookup - Table"
{
    Permissions = tabledata "Post Code Range" = R;

    trigger OnRun()
    begin
    end;

    var
        PostCodeRange: Record "Post Code Range";

    procedure FindStreetNameFromAddress(var StreetName: Text[50]; HouseNo: Text[50]; var PostCode: Code[20]; var City: Text[50]; var PhoneNo: Text[30]; var FaxNo: Text[30]): Boolean
    var
        ForcePopup: Boolean;
    begin
        PostCode := StrSubstNo('%1 %2', CopyStr(PostCode, 1, 4), CopyStr(PostCode, 5, 2));

        PostCodeRange.Reset();
        PostCodeRange.SetRange("Post Code", PostCode);

        if HouseNo <> '' then begin
            Evaluate(PostCodeRange."From No.", HouseNo);

            case PostCodeRange."From No." mod 2 of
                0:
                    PostCodeRange.SetRange(Type, PostCodeRange.Type::Even);
                1:
                    PostCodeRange.SetRange(Type, PostCodeRange.Type::Odd);
            end;

            PostCodeRange.SetFilter("From No.", '..%1', PostCodeRange."From No.");
            PostCodeRange.SetFilter("To No.", '%1..', PostCodeRange."From No.");
        end;

        if PostCodeRange.IsEmpty() then
            if HouseNo <> '' then begin
                PostCodeRange.SetRange(Type);
                PostCodeRange.SetRange("From No.");
                PostCodeRange.SetRange("To No.");
                ForcePopup := true;
            end;

        OnFindStreetNameFromAddressOnBeforeSelectPostCodeRange(PostCodeRange, ForcePopup);

        if not SelectPostCodeRange(PostCodeRange, ForcePopup) then
            exit(false);

        StreetName := PostCodeRange."Street Name";
        City := PostCodeRange.City;

        exit(true);
    end;

    local procedure SelectPostCodeRange(var PostCodeRange: Record "Post Code Range"; ForcePopup: Boolean) Result: Boolean
    var
        PostCodeRange2: Record "Post Code Range";
        IsHandled: Boolean;
    begin
        if PostCodeRange.IsEmpty() then
            exit(false);

        PostCodeRange.Find('-');

        if not ForcePopup then begin
            PostCodeRange2.Copy(PostCodeRange);
            PostCodeRange2.SetFilter("Street Name", '<>%1', PostCodeRange."Street Name");
            if PostCodeRange2.IsEmpty() then
                exit(true);
        end;

        IsHandled := false;
        OnSelectPostCodeRangeOnBeforeRunPage(PostCodeRange, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(PAGE.RunModal(0, PostCodeRange) = ACTION::LookupOK);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindStreetNameFromAddressOnBeforeSelectPostCodeRange(var PostCodeRange: Record "Post Code Range"; var ForcePopup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectPostCodeRangeOnBeforeRunPage(var PostCodeRange: Record "Post Code Range"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

