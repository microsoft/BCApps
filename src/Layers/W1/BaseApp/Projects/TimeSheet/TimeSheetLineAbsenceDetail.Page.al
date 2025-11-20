// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

page 969 "Time Sheet Line Absence Detail"
{
    Caption = 'Time Sheet Line Absence Detail';
    PageType = StandardDialog;
    SourceTable = "Time Sheet Line";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Cause of Absence Code"; Rec."Cause of Absence Code")
                {
                    ApplicationArea = Jobs, BasicHR;
                    Editable = AllowEdit;
                    ToolTip = 'Specifies a list of standard absence codes, from which you may select one.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    Editable = AllowEdit;
                    ToolTip = 'Specifies a description of the time sheet line.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        AllowEdit := Rec.GetAllowEdit(0, ManagerRole);
    end;

    protected var
        ManagerRole: Boolean;
        AllowEdit: Boolean;

    procedure SetParameters(TimeSheetLine: Record "Time Sheet Line"; NewManagerRole: Boolean)
    begin
        Rec := TimeSheetLine;
        Rec.Insert();
        ManagerRole := NewManagerRole;
    end;
}

