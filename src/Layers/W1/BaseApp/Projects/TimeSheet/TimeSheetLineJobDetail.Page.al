// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

page 966 "Time Sheet Line Job Detail"
{
    Caption = 'Time Sheet Line Project Detail';
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
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    Editable = AllowEdit;
                    ToolTip = 'Specifies the number for the project associated with the time sheet line.';
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    Editable = AllowEdit;
                    ToolTip = 'Specifies the number for the project task associated with the time sheet line.';
                }
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
                field(Chargeable; Rec.Chargeable)
                {
                    ApplicationArea = Jobs;
                    Editable = ChargeableAllowEdit;
                    ToolTip = 'Specifies if the usage that you are posting is chargeable.';
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
        ChargeableAllowEdit := Rec.GetAllowEdit(Rec.FieldNo(Chargeable), ManagerRole);
    end;

    protected var
        ManagerRole: Boolean;
        AllowEdit: Boolean;
        WorkTypeCodeAllowEdit: Boolean;
        ChargeableAllowEdit: Boolean;

    procedure SetParameters(TimeSheetLine: Record "Time Sheet Line"; NewManagerRole: Boolean)
    begin
        Rec := TimeSheetLine;
        Rec.Insert();
        ManagerRole := NewManagerRole;
    end;
}

