// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.AuditCodes;

codeunit 12105 "Business Activity Validator IT" implements "Business Activity Validator"
{
    procedure Validate(Code: Code[10])
    begin
        if StrLen(Code) > 6 then
            Error(InvalidBusinessActivityCodeLengthErr, Code);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Business Activity Code Mgt.", OnGetValidator, '', false, false)]
    local procedure SetItalianValidator(CountryRegionCode: Code[10]; var BusinessActivityValidator: Interface "Business Activity Validator"; var IsHandled: Boolean)
    begin
        if not (CountryRegionCode in ['', 'IT']) then
            exit;

        BusinessActivityValidator := this;
        IsHandled := true;
    end;

    var
        InvalidBusinessActivityCodeLengthErr: Label 'The business activity code %1 cannot be longer than 6 characters in Italy.', Comment = '%1 = Business activity code';
}