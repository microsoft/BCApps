// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

/// <summary>
/// Defines overall validation status for VAT registration log detail records.
/// Indicates the aggregate result of field-by-field validation against external VAT services.
/// </summary>
enum 242 "VAT Reg. Log Details Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Details validation has not been performed or initiated.
    /// </summary>
    value(0; "Not Verified")
    {
        Caption = 'Not Verified';
    }
    /// <summary>
    /// All detail fields validated successfully against the external service.
    /// </summary>
    value(1; Valid)
    {
        Caption = 'Valid';
    }
    /// <summary>
    /// One or more detail fields failed validation against the external service.
    /// </summary>
    value(2; "Not Valid")
    {
        Caption = 'Not Valid';
    }
    /// <summary>
    /// Some detail fields validated successfully, others failed or could not be verified.
    /// </summary>
    value(3; "Partially Valid")
    {
        Caption = 'Partially Valid';
    }
    /// <summary>
    /// Detail validation was skipped or ignored for this record.
    /// </summary>
    value(4; Ignored)
    {
        Caption = 'Ignored';
    }
}
