// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Reports;

/// <summary>
/// Used for report selections.
/// </summary>
enum 20426 "Qlty. Report Selection Usage"
{
    Extensible = true;
    AssignmentCompatibility = true;

    Caption = 'Quality Report Selection Usage';

    value(0; "Certificate of Analysis")
    {
        Caption = 'Certificate of Analysis';
    }
    value(1; "Non-Conformance")
    {
        Caption = 'Non-Conformance';
    }
    value(2; "General Purpose Inspection")
    {
        Caption = 'General Purpose Inspection';
    }
}
