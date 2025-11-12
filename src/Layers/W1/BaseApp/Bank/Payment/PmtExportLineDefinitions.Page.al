// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using System.IO;

/// <summary>
/// Page 1227 "Pmt. Export Line Definitions" displays data exchange line definitions for payment export.
/// This page provides a read-only view of line definitions used in payment file export configurations.
/// </summary>
/// <remarks>
/// Source table: Data Exch. Line Def. Used for viewing payment export format configurations
/// and line definition structures in data exchange frameworks.
/// </remarks>
page 1227 "Pmt. Export Line Definitions"
{
    Caption = 'Pmt. Export Line Definitions';
    DelayedInsert = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Data Exch. Line Def";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line in the file.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the mapping setup.';
                }
            }
        }
    }

    actions
    {
    }
}

