// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Document;

/// <summary>
/// The test status is what state the test itself is in.
/// </summary>
enum 20422 "Qlty. Inspection Test Status"
{
    Caption = 'Quality Inspection Test Status', Locked = true;
    AssignmentCompatibility = true;
    Extensible = false;

    value(0; Open)
    {
        Caption = 'Open';
    }
    value(1; Finished)
    {
        Caption = 'Finished';
    }
}
