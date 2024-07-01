// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Utilities;

using System;

codeunit 5054 "Check Phone No."
{
    var
        PhoneNoCannotContainLettersErr: Label 'must not contain letters';

    procedure ValidateIfPhoneNoContainsCharacters(PhoneNo: Text[30]; SourceRecordId: RecordId; SourceFieldId: Integer)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        Char: DotNet Char;
        i: Integer;
    begin
        for i := 1 to StrLen(PhoneNo) do
            if Char.IsLetter(PhoneNo[i]) then begin
                RecRef.Get(SourceRecordId);
                FieldRef := RecRef.Field(SourceFieldId);
                FieldRef.FieldError(PhoneNoCannotContainLettersErr);
            end;
    end;
}