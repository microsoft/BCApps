// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Duplicates;

page 704 "Merge Duplicate Conflicts"
{
    Caption = 'Merge Duplicate Conflicts';
    Editable = false;
    PageType = List;
    ShowFilter = false;
    SourceTable = "Merge Duplicates Conflict";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Current; GetPK(Rec.Current))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Current';
                    ToolTip = 'Specifies values of the fields in the primary key of the current record.';
                }
                field(Duplicate; GetPK(Rec.Duplicate))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Duplicate';
                    ToolTip = 'Specifies values of the fields in the primary key of the current record.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ViewConflictRecords)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View Details';
                Image = ViewDetails;
                ToolTip = 'View the details of conflicting records, rename or remove the duplicate record.';

                trigger OnAction()
                begin
                    if Rec.Merge() then
                        Rec.Delete();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ViewConflictRecords_Promoted; ViewConflictRecords)
                {
                }
            }
        }
    }

    procedure Set(var TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary)
    begin
        Rec.Copy(TempMergeDuplicatesConflict, true);
    end;

    local procedure GetPK(RecordID: RecordID) PrimaryKey: Text
    begin
        PrimaryKey := Format(RecordID);
        PrimaryKey := CopyStr(PrimaryKey, StrPos(PrimaryKey, ': ') + 2);
    end;
}

