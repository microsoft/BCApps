// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

page 965 "Time Sheet Line Res. Detail"
{
    Caption = 'Time Sheet Line Res. Detail';
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
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    Editable = AllowEdit;
                    ToolTip = 'Specifies a description of the time sheet line.';
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Jobs;
                    Editable = WorkTypeCodeAllowEdit;
                    ToolTip = 'Specifies which work type the resource applies to. Prices are updated based on this entry.';
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
        WorkTypeCodeAllowEdit := Rec.GetAllowEdit(Rec.FieldNo("Work Type Code"), ManagerRole);
    end;

    protected var
        ManagerRole: Boolean;
        AllowEdit: Boolean;
        WorkTypeCodeAllowEdit: Boolean;

    procedure SetParameters(TimeSheetLine: Record "Time Sheet Line"; NewManagerRole: Boolean)
    begin
        Rec := TimeSheetLine;
        Rec.Insert();
        ManagerRole := NewManagerRole;
    end;
}

