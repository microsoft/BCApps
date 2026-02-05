// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

using System.Utilities;

page 7413 "Excise Tax Entry Permissions"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Excise Tax Entry Permission";
    DataCaptionExpression = GetCaption();
    Caption = 'Excise Tax Entry Permissions';

    layout
    {
        area(Content)
        {
            repeater(Permissions)
            {
                field("Excise Tax Type Code"; Rec."Excise Tax Type Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the excise tax type code.';
                    Visible = false;
                    Editable = false;
                }
                field("Excise Entry Type"; Rec."Excise Entry Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry type (Purchase, Sale, etc.).';
                }
                field(Allowed; Rec.Allowed)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if this entry type is allowed for the tax type.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Setup Default Permissions")
            {
                ApplicationArea = All;
                Caption = 'Setup Default Permissions';
                ToolTip = 'Create default permissions for all entry types.';
                Image = Setup;

                trigger OnAction()
                var
                    ExciseTaxEntryPermission: Record "Excise Tax Entry Permission";
                begin
                    IsSetupDefaultPermissions := ConfirmManagement.GetResponseOrDefault(StrSubstNo(ConfirmForInsertMsg, Rec."Excise Tax Type Code"), false);
                    if not IsSetupDefaultPermissions then
                        exit;

                    ExciseTaxEntryPermission.SetDefaultPermissions(Rec."Excise Tax Type Code");
                    Message(DefaultPermissionsCreatedMsg);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsSetupDefaultPermissions: Boolean;
        ConfirmForInsertMsg: Label 'Are you sure you want to Setup all default permissions for tax type %1?', Comment = '%1 = Excise Tax Type Code';
        DefaultPermissionsCreatedMsg: Label 'Default permissions have been created for this tax type.';
        EntryPermissionsCaptionLbl: Label '%1 for Tax Type: %2', Comment = '%1=Current Rec TableCaption, %2=Excise Tax Type Code';

    local procedure GetCaption(): Text[100]
    begin
        exit(StrSubstNo(EntryPermissionsCaptionLbl, Rec.TableCaption, Rec."Excise Tax Type Code"));
    end;
}