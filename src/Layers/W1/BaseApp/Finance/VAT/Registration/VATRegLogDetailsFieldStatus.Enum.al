// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

#pragma warning disable AL0659
/// <summary>
/// Defines validation status values for individual field comparisons in VAT registration log details.
/// Indicates the outcome of comparing system values against external VAT service responses.
/// </summary>
enum 244 "VAT Reg. Log Details Field Status"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Field validation failed - service response does not match system value.
    /// </summary>
    value(0; "Not Valid")
    {
        Caption = 'Not Valid';
    }
    /// <summary>
    /// Field validation succeeded - service response matches system value.
    /// </summary>
    value(1; Accepted)
    {
        Caption = 'Accepted';
    }
    /// <summary>
    /// Validated field value has been applied to update the system record.
    /// </summary>
    value(2; Applied)
    {
        Caption = 'Applied';
    }
    /// <summary>
    /// Field validation confirmed as valid by external service.
    /// </summary>
    value(3; Valid)
    {
        Caption = 'Valid';
    }
}
