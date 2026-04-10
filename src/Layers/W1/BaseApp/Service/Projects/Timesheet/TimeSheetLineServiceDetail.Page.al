// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

page 967 "Time Sheet Line Service Detail"
{
    Caption = 'Time Sheet Line Service Detail';
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
                field("Service Order No."; Rec."Service Order No.")
                {
                    ApplicationArea = Jobs;
                    Editable = AllowEdit;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    Editable = AllowEdit;
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Jobs;
                    Editable = WorkTypeCodeAllowEdit;
                }
                field(Chargeable; Rec.Chargeable)
                {
                    ApplicationArea = Jobs;
                    Editable = ChargeableAllowEdit;
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

