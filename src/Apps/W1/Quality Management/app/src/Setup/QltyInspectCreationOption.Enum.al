// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup;

/// <summary>
/// This behavior controls how quality inspections should be created.
/// If extending this make sure to implement OnCustomCreateInspectionBehavior
/// </summary>
enum 20402 "Qlty. Inspect. Creation Option"
{
    Caption = 'Quality Inspection Creation Option';

    value(0; "Always create new inspection")
    {
        Caption = 'Always create a new inspection';
    }
    value(1; "Create re-inspection if matching inspection is finished")
    {
        Caption = 'Create a re-inspection if a matching inspection is finished';
    }
    value(2; "Always create re-inspection")
    {
        Caption = 'Always create a re-inspection';
    }
    value(3; "Use existing open inspection if available")
    {
        Caption = 'Use existing open inspection if available';
    }
    value(4; "Use any existing inspection if available")
    {
        Caption = 'Use any existing inspection if available';
    }
}
