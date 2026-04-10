// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

using System.IO;

/// <summary>
/// Displays detailed information for bank statement lines in a read-only format.
/// Provides comprehensive view of transaction details including imported data fields.
/// </summary>
/// <remarks>
/// Source Table: Data Exch. Field (1221). Shows detailed field data from bank statement imports.
/// Read-only interface for viewing all imported transaction fields and their values.
/// Used for detailed analysis and troubleshooting of bank statement import data.
/// </remarks>
page 1221 "Bank Statement Line Details"
{
    Caption = 'Bank Statement Line Details';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    ShowFilter = false;
    SourceTable = "Data Exch. Field";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec.GetFieldName())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of a column in the imported bank statement file.';
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value in a column in the imported bank statement file, such as account number, posting date, and amount.';
                }
            }
        }
    }

    actions
    {
    }
}

