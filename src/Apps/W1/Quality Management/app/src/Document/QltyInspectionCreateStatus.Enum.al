// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Document;

/// <summary>
/// Enum for tracking if an inspection could be created, could not be created, or intentionally skipped for scenarios when we need to know if it could be created but we intentionally chose not to.
/// </summary>
enum 20419 "Qlty. Inspection Create Status"
{
    Caption = 'Create Status';
    Extensible = true;

    value(0; Unknown)
    {
        Caption = 'Unknown';
    }
    value(1; "Unable to Create")
    {
        Caption = 'Unable to Create';
    }
    value(2; Created)
    {
        Caption = 'Created';
    }
    value(3; Skipped)
    {
        Caption = 'Skipped';
    }
}