// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

/// <summary>
/// Defines field types for VAT registration log detail tracking and validation comparison.
/// Used to identify which address components are being validated against external VAT services.
/// </summary>
enum 243 "VAT Reg. Log Details Field"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Company or entity name field validation.
    /// </summary>
    value(0; Name)
    {
        Caption = 'Name';
    }
    /// <summary>
    /// Full address field validation.
    /// </summary>
    value(1; Address)
    {
        Caption = 'Address';
    }
    /// <summary>
    /// Street address component field validation.
    /// </summary>
    value(2; Street)
    {
        Caption = 'Street';
    }
    /// <summary>
    /// Postal code field validation.
    /// </summary>
    value(3; "Post Code")
    {
        Caption = 'Post Code';
    }
    /// <summary>
    /// City field validation.
    /// </summary>
    value(4; City)
    {
        Caption = 'City';
    }
}
