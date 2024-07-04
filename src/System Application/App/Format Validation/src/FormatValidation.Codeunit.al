// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Utilities;

/// <summary>
/// Codeunit that exposes format validation functionality.
/// </summary>
codeunit 5070 "Format Validation"
{
    Access = Public;

    /// <summary>
    /// Validates if a phone no. contains characters.
    /// </summary>
    /// <param name="PhoneNo">The phone no. to validate</param>
    procedure ValidateIfPhoneNoContainsCharacters(PhoneNo: Text[30]): Boolean
    var
        FormatValidationImpl: Codeunit "Format Validation Impl.";
    begin
        exit(FormatValidationImpl.ValidateIfPhoneNoContainsCharacters(PhoneNo));
    end;

    /// <summary>
    /// Validates and throws an error if a phone no. contains characters.
    /// </summary>
    /// <param name="PhoneNo">The phone no. to validate</param>
    /// <param name="SourceRecordId">The error message is a fielderror which needs the source record.</param>
    /// <param name="SourceFieldId">The error message is a fielderror which needs the source field.</param>
    procedure ThrowErrorIfPhoneNoContainsCharacters(PhoneNo: Text[30]; SourceRecordId: RecordId; SourceFieldId: Integer)
    var
        FormatValidationImpl: Codeunit "Format Validation Impl.";
    begin
        FormatValidationImpl.ThrowErrorIfPhoneNoContainsCharacters(PhoneNo, SourceRecordId, SourceFieldId);
    end;
}