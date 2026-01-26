// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using System.Reflection;

page 11026 "Data Export Table Keys"
{
    Caption = 'Data Export Table Keys';
    DataCaptionFields = TableNo;
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Key";

    layout
    {
        area(content)
        {
            repeater(Control1101100000)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'No.';
                    ToolTip = 'Specifies the number of the key.';
                }
                field("Key"; Rec.Key)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Key';
                    ToolTip = 'Specifies the key.';
                }
                field(SumIndexFields; Rec.SumIndexFields)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SumIndexFields';
                }
                field(SQLIndex; Rec.SQLIndex)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SQLIndex';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enabled';
                    ToolTip = 'Specifies that the key is enabled for export of data from a table to improve performance. For example, to increase performance for exporting data from the G/L Entry table, you can specify the G/L Account No.,Posting Date key.';
                }
                field(MaintainSQLIndex; Rec.MaintainSQLIndex)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'MaintainSQLIndex';
                }
                field(MaintainSIFTIndex; Rec.MaintainSIFTIndex)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'MaintainSIFTIndex';
                }
                field(Clustered; Rec.Clustered)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Clustered';
                    ToolTip = 'Specifies if the table data is clustered.';
                }
            }
        }
    }

    actions
    {
    }
}

