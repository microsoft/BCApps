// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

using Microsoft.Foundation.Navigate;

page 2845 "Data Upgrade Overview"
{
    Caption = 'Data Update Overview';
    Editable = false;
    PageType = List;
    SourceTable = "Document Entry";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control16)
            {
                ShowCaption = false;
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the table ID.';
                    Visible = false;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Related Entries';
                    ToolTip = 'Specifies the name of the table.';
                }
                field("No. of Records"; Rec."No. of Records")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of Records';
                    ToolTip = 'Specifies the number of records in the table for upgrade.';
                }
            }
        }
    }

    actions
    {
    }

    procedure Set(var TempDocumentEntry: Record "Document Entry" temporary)
    begin
        if TempDocumentEntry.FindSet() then
            repeat
                Rec := TempDocumentEntry;
                Rec.Insert();
            until TempDocumentEntry.Next() = 0;
    end;
}

