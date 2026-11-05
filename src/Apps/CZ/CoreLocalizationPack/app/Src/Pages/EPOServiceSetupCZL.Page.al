// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Utilities;

#pragma implicitwith disable
page 11705 "EPO Service Setup CZL"
{
    ApplicationArea = Basic, Suite;
    Caption = 'EPO Service Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "EPO Service Setup CZL";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Open Form Endpoint"; Rec."Open Form Endpoint")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    ToolTip = 'Specifies the source address of the service.';
                }
                field("Limit Response Time"; Rec."Limit Response Time")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    Importance = Additional;
                    ToolTip = 'Specifies the response time limit (in milliseconds), after which goes into offline mode.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the service is enabled.';

                    trigger OnValidate()
                    begin
                        UpdateBasedOnEnable();
                        CurrPage.Update();
                    end;
                }
                field(ShowEnableWarning; ShowEnableWarning)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the display of a warning message.';
                    ShowCaption = false;
                    AssistEdit = false;
                    Editable = false;
                    Enabled = not EditableByNotEnabled;

                    trigger OnDrillDown()
                    begin
                        DrilldownShowEnableWarning();
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetURLToDefault)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set URL to Default';
                Enabled = not Rec.Enabled;
                Image = Restore;
                ToolTip = 'Change the Service URL to its default value. You cannot cancel this action to revert back to the current value.';

                trigger OnAction()
                begin
                    Rec.SetURLToDefault();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(SetURLToDefault_Promoted; SetURLToDefault)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateBasedOnEnable();
    end;

    trigger OnOpenPage()
    begin
        Rec.GetOrInit();
        UpdateBasedOnEnable();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not Rec.Enabled then
            exit(ConfirmManagement.GetResponse(StrSubstNo(EnableServiceQst, CurrPage.Caption), true))
    end;

    var
        ConfirmManagement: Codeunit "Confirm Management";
        ShowEnableWarning: Text;
        EditableByNotEnabled: Boolean;
        EnableServiceQst: Label 'The %1 is not enabled. Are you sure you want to exit?', Comment = '%1 = pagecaption';
        EnabledWarningTxt: Label 'You must disable the service before you can make changes.';
        DisableEnableQst: Label 'Do you want to disable the EPO service?';

    local procedure UpdateBasedOnEnable()
    begin
        EditableByNotEnabled := not Rec.Enabled;
        ShowEnableWarning := '';
        if CurrPage.Editable and Rec.Enabled then
            ShowEnableWarning := EnabledWarningTxt;
    end;

    local procedure DrilldownShowEnableWarning()
    begin
        if ConfirmManagement.GetResponse(DisableEnableQst, true) then begin
            Rec.Enabled := false;
            UpdateBasedOnEnable();
            CurrPage.Update();
        end;
    end;
}
