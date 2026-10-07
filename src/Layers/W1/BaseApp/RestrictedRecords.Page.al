// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

page 1550 "Restricted Records"
{
    ApplicationArea = Suite;
    Caption = 'Restricted Records';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Restricted Record";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(ID; Rec.ID)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the record in the Restricted Record table.';
                    Visible = false;
                }
                field(RecordDetails; RecordDetails)
                {
                    ApplicationArea = Suite;
                    Caption = 'Record Details';
                    ToolTip = 'Specifies details about what imposed the restriction on the record.';
                }
                field(Details; Rec.Details)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies details about what imposed the restriction on the record.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Record")
            {
                ApplicationArea = Suite;
                Caption = 'Record';
                Image = Document;
                ShortCutKey = 'Return';
                ToolTip = 'Open the record that is restricted from certain usage, as defined by the workflow response.';

                trigger OnAction()
                begin
                    Rec.ShowRecord();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Record_Promoted; Record)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        RecordDetails := Format(Rec."Record ID", 0, 1);
    end;

    trigger OnAfterGetRecord()
    begin
        RecordDetails := Format(Rec."Record ID", 0, 1);
    end;

    var
        RecordDetails: Text;
}

