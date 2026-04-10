// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

page 180 "Additional Cust. Terms Setup"
{
    Caption = 'Additional Customer Terms Setup Card';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "License Agreement";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Accepted; Rec.Accepted)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if the license agreement was accepted.';
                }
                field("Accepted By"; Rec."Accepted By")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the person that accepted the license agreement.';
                }
                field("Accepted On"; Rec."Accepted On")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date the license agreement is accepted.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Activate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Activate';
                Enabled = not Active;
                Image = Agreement;
                ToolTip = 'Activate the current customer terms setup.';

                trigger OnAction()
                begin
                    Rec.Validate("Effective Date", Today);
                    Rec.Modify();
                end;
            }
            action(Deactivate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Deactivate';
                Enabled = Active;
                Image = Stop;
                ToolTip = 'Deactivate the current customer terms setup.';

                trigger OnAction()
                begin
                    Rec.Validate("Effective Date", 0D);
                    Rec.Modify();
                end;
            }
            action(Reset)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reset';
                Enabled = Active;
                Image = ResetStatus;
                ToolTip = 'Reset the current customer terms setup.';

                trigger OnAction()
                begin
                    Rec.Validate(Accepted, false);
                    Rec.Modify();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Activate_Promoted; Activate)
                {
                }
                actionref(Deactivate_Promoted; Deactivate)
                {
                }
                actionref(Reset_Promoted; Reset)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Active := Rec.GetActive();
    end;

    trigger OnOpenPage()
    begin
        if not Rec.Get() then
            Rec.Insert();
    end;

    var
        Active: Boolean;
}

