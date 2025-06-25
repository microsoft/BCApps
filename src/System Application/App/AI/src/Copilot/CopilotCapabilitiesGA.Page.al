// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// Page for listing the Copilot Capabilities which are Generally Available.
/// </summary>
page 7774 "Copilot Capabilities GA"
{
    PageType = ListPart;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    Extensible = false;
    SourceTable = "Copilot Settings";
    SourceTableView = where(Availability = const("Generally Available"), "Service Type" = const("Azure AI Service Type"::"Azure OpenAI"));
    Permissions = tabledata "Copilot Settings" = rm;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(Capabilities)
            {
                field(Capability; Rec.Capability)
                {
                    ApplicationArea = All;
                    Caption = 'Capability';
                    ToolTip = 'Specifies the Copilot capability''s name.';
                    Editable = false;
                    Width = 30;
                }
                field(Status; Rec.EvaluateStatus())
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    ToolTip = 'Specifies if the Copilot is active and can be used in this environment.';
                    StyleExpr = StatusStyleExpr;
                    Visible = DataMovementEnabled;

                    trigger OnValidate()
                    begin
                        SetStatusStyle();
                    end;
                }
                field(Publisher; Rec.Publisher)
                {
                    ApplicationArea = All;
                    Caption = 'Publisher';
                    ToolTip = 'Specifies the publisher of this Copilot.';
                    Editable = false;
                }
                field("Learn More"; LearnMore)
                {
                    ApplicationArea = All;
                    Caption = ' ';
#pragma warning disable AA0219
                    ToolTip = 'Opens the Copilot''s url to learn more about the capability.';
#pragma warning restore AA0219
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        if Rec."Learn More Url" <> '' then
                            Hyperlink(Rec."Learn More Url");
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Activate)
            {
                Caption = 'Activate';
                ToolTip = 'Activates the selected Copilot Capability.';
                Image = Start;
                Enabled = ActionsEnabled and not CapabilityEnabled;
                Visible = ActionsEnabled and not CapabilityEnabled;
                Scope = Repeater;

                trigger OnAction()
                begin
                    if not Rec.EnsurePrivacyNoticesApproved() then
                        exit;

                    Rec.Status := Rec.Status::Active;
                    Rec.Modify(true);

                    CopilotCapabilityImpl.SendActivateTelemetry(Rec.Capability, Rec."App Id");
                    Session.LogAuditMessage(StrSubstNo(CopilotFeatureActivatedLbl, Rec.Capability, Rec."App Id", UserSecurityId()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 4, 0);
                end;
            }
            action(Deactivate)
            {
                Caption = 'Deactivate';
                ToolTip = 'Deactivates the selected Copilot Capability.';
                Image = Stop;
                Enabled = ActionsEnabled and CapabilityEnabled;
                Visible = ActionsEnabled and CapabilityEnabled;
                Scope = Repeater;

                trigger OnAction()
                begin
                    CopilotCapabilityImpl.DeactivateCapability(Rec);
                end;
            }
#if not CLEAN26
            action(SupplementalTerms)
            {
                Caption = 'Supplemental Terms of Use';
                ToolTip = 'Opens the supplemental terms of use for generally available capabilities.';
                Image = Info;
                Visible = false;
                trigger OnAction()
                begin
                    Hyperlink(SupplementalTermsLinkTxt);
                end;
            }
#endif
        }
    }

    trigger OnOpenPage()
    begin
        SetActionsEnabled();
    end;

    trigger OnAfterGetRecord()
    begin
        if Rec."Learn More Url" <> '' then
            LearnMore := LearnMoreLbl
        else
            LearnMore := '';

        SetStatusStyle();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetStatusStyle();
        SetActionsEnabled();
    end;

    var
        CopilotCapabilityImpl: Codeunit "Copilot Capability Impl";
        StatusStyleExpr: Text;
        LearnMore: Text;
        LearnMoreLbl: Label 'Learn More';
        ActionsEnabled: Boolean;
        CapabilityEnabled: Boolean;
        DataMovementEnabled: Boolean;
#if not CLEAN26
        SupplementalTermsLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2236010', Locked = true;
#endif
        CopilotFeatureActivatedLbl: Label 'The copilot/AI capability %1, App Id %2 has been activated by UserSecurityId %3.', Locked = true;

    internal procedure SetDataMovement(Value: Boolean)
    begin
        DataMovementEnabled := Value;
        SetActionsEnabled();
        CurrPage.Update(false);
    end;

    local procedure SetStatusStyle()
    begin
        if (Rec.EvaluateStatus() = Rec.Status::Active) then
            StatusStyleExpr := 'Favorable'
        else
            StatusStyleExpr := '';
    end;

    local procedure SetActionsEnabled()
    var
        CopilotCapability: Codeunit "Copilot Capability";
    begin
        if CopilotCapabilityImpl.IsAdmin() then begin
            ActionsEnabled := (Rec.Capability.AsInteger() <> 0) and DataMovementEnabled;
            CapabilityEnabled := CopilotCapability.IsCapabilityActive(Rec.Capability, Rec."App Id");
        end
        else begin
            ActionsEnabled := false;
            CapabilityEnabled := false;
        end;
    end;
}