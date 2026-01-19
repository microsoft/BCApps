// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.GenerationRule;

/// <summary>
/// Generation Rule Activation Trigger.
/// </summary>
enum 20459 "Qlty. Gen. Rule Act. Trigger"
{
    Caption = 'Quality Inspection Generation Rule Activation Trigger';
    Extensible = false;

    value(0; "Manual or Automatic")
    {
        Caption = 'Manual or Automatic';
    }
    value(1; "Manual only")
    {
        Caption = 'Manual only';
    }
    value(2; "Automatic only")
    {
        Caption = 'Automatic only';
    }
    value(3; Disabled)
    {
        Caption = 'Disabled';
    }
}
