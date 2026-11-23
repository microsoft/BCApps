// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7142 "Exp. Report Change Log API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Report Change Log Entry';
    EntitySetCaption = 'Expense Report Change Log Entries';
    EntityName = 'expenseReportChangeLogEntry';
    EntitySetName = 'expenseReportChangeLogEntries';
    PageType = API;
    DelayedInsert = true;
    SourceTable = "Exp. Report Change Log Entry";
    ODataKeyFields = SystemId;
    DataAccessIntent = ReadOnly;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Provides the history of changes made to an expense report after it was submitted, including the old value, the new value, and the user who made each change. Use sourceTableId to distinguish expense report entries from posted expense report entries.';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'ID';
                }
                field(entryNumber; Rec."Entry No.")
                {
                    Caption = 'Entry Number';
                }
                field(sourceTableId; Rec."Source Table ID")
                {
                    Caption = 'Source Table ID';
                }
                field(sourceId; Rec."Source Record System ID")
                {
                    Caption = 'Source ID';
                }
                field(documentNumber; Rec."Document No.")
                {
                    Caption = 'Document Number';
                }
                field(documentLineNumber; Rec."Document Line No.")
                {
                    Caption = 'Document Line Number';
                }
                field(expenseNumber; Rec."Expense No.")
                {
                    Caption = 'Expense Number';
                }
                field(tableId; Rec."Table ID")
                {
                    Caption = 'Table ID';
                }
                field(fieldNumber; Rec."Field No.")
                {
                    Caption = 'Field Number';
                }
                field(fieldCaption; Rec."Field Caption")
                {
                    Caption = 'Field Caption';
                }
                field(oldValue; Rec."Old Value")
                {
                    Caption = 'Old Value';
                }
                field(newValue; Rec."New Value")
                {
                    Caption = 'New Value';
                }
                field(changedBy; Rec."User ID")
                {
                    Caption = 'Changed By';
                }
                field(changedAt; Rec."Changed At")
                {
                    Caption = 'Changed At';
                }
            }
        }
    }

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;
}