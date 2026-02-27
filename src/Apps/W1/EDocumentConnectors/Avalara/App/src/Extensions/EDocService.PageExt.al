/// <summary>
/// Extends E-Document Service page with Avalara-specific configuration.
/// Adds mandate activation status monitoring and field configuration capabilities.
/// </summary>
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.eServices.EDocument;

pageextension 6370 "E-Doc. Service" extends "E-Document Service"
{
    layout
    {
        addafter(General)
        {
            group(AvalaraFields)
            {
                Caption = 'Avalara';
                Visible = Rec."Service Integration V2" = Rec."Service Integration V2"::Avalara;

                field("Avalara Mandate"; Rec."Avalara Mandate")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Avalara mandate for this E-Document service.';
                }
                field(ActivationStatus; ActivationStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Activation Status';
                    Editable = false;
                    ToolTip = 'Specifies whether the mandate is activated in Avalara.';
                }
                field(MandateBlocked; MandateBlocked)
                {
                    ApplicationArea = All;
                    Caption = 'Block Mandate Sending';
                    ToolTip = 'Specifies whether sending documents using this mandate is blocked.';

                    trigger OnValidate()
                    begin
                        UpdateMandateBlockStatus();
                    end;
                }

            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            group(AvalaraActions)
            {
                Caption = 'Avalara';
                action(ViewAvalaraMandateFields)
                {
                    ApplicationArea = All;
                    Caption = 'View Mandate Fields';
                    Enabled = Rec."Avalara Mandate" <> '';
                    Image = View;
                    ToolTip = 'Opens the input fields page to view and configure fields required for the selected Avalara mandate.';
                    Visible = Rec."Service Integration V2" = Rec."Service Integration V2"::Avalara;

                    trigger OnAction()
                    var
                        AvalaraInputFieldsPage: Page "Avalara Input Fields";
                    begin
                        AvalaraInputFieldsPage.SetFilterByMandate(Rec."Avalara Mandate", '');
                        AvalaraInputFieldsPage.RunModal();
                    end;
                }

                action(CreateBaseDefinitions)
                {
                    ApplicationArea = All;
                    Caption = 'Create Base Definitions for Mandate';
                    Image = Setup;
                    ToolTip = 'Creates the base data exchange definitions for the selected Avalara mandate.';
                    Visible = Rec."Service Integration V2" = Rec."Service Integration V2"::Avalara;

                    trigger OnAction()
                    var
                        AvalaraFunctions: Codeunit "Avalara Functions";
                    begin
                        AvalaraFunctions.CreateBoilerPlateDefs(Rec."Avalara Mandate");
                    end;
                }

                action(SetupJobQueue)
                {
                    ApplicationArea = All;
                    Caption = 'Setup Job Queue';
                    Image = CreateLinesFromJob;
                    ToolTip = 'Creates or ensures the maintenance job queue entry exists for automatic document downloads.';
                    Visible = Rec."Service Integration V2" = Rec."Service Integration V2"::Avalara;

                    trigger OnAction()
                    var
                        AvalaraFunctions: Codeunit "Avalara Functions";
                    begin
                        AvalaraFunctions.EnsureMaintenanceJobQueueEntry();
                    end;
                }
            }
        }

        addlast(Promoted)
        {
            group(AvalaraActions_Promoted)
            {
                Caption = 'Avalara';
                actionref(ViewAvalaraMandateFields_Promoted; ViewAvalaraMandateFields) { }
                actionref(CreateBaseDefinitions_Promoted; CreateBaseDefinitions) { }
                actionref(EnsureMaintenanceJob_Promoted; SetupJobQueue) { }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        RefreshActivationStatus();
    end;

    var
        ConnectionSetup: Record "Connection Setup";
        MandateBlocked: Boolean;
        ActivationCompleteTxt: Label 'Complete';
        BlockTxt: Label 'block', Locked = true;
        ConfirmBlockQst: Label 'This will %1 sending for mandate %2. Do you want to continue?', Comment = '%1 = block/unblock, %2 = mandate code';
        ConnectionNotConfiguredErr: Label 'Connection setup is not configured.';
        MandateNotFoundTxt: Label 'Mandate was not found in activations';
        UnblockTxt: Label 'unblock', Locked = true;
        ActivationStatus: Text;

    /// <summary>
    /// Refreshes the activation status and blocked state from Avalara activation data.
    /// </summary>
    local procedure RefreshActivationStatus()
    var
        AvalaraMandate: Record "Activation Mandate";
        Processing: Codeunit Processing;
        MandateType: Text;
    begin
        ClearActivationFields();

        if Rec."Avalara Mandate" = '' then
            exit;

        if not ConnectionSetup.Get() then
            exit;

        MandateType := Processing.GetMandateTypeFromName(Rec."Avalara Mandate");

        AvalaraMandate.SetRange("Company Id", ConnectionSetup."Company Id");
        AvalaraMandate.SetRange("Country Mandate", Rec."Avalara Mandate");
        AvalaraMandate.SetRange("Mandate Type", MandateType);

        if AvalaraMandate.FindFirst() then begin
            if AvalaraMandate.Activated then
                ActivationStatus := ActivationCompleteTxt;
            MandateBlocked := AvalaraMandate.Blocked;
        end else
            ActivationStatus := MandateNotFoundTxt;
    end;

    /// <summary>
    /// Updates the mandate blocked status with user confirmation.
    /// </summary>
    local procedure UpdateMandateBlockStatus()
    var
        AvalaraMandate: Record "Activation Mandate";
        ActionText: Text;
    begin
        if not ConnectionSetup.Get() then
            Error(ConnectionNotConfiguredErr);

        if MandateBlocked then
            ActionText := BlockTxt
        else
            ActionText := UnblockTxt;

        if not Confirm(ConfirmBlockQst, false, ActionText, Rec."Avalara Mandate") then
            Error('');

        AvalaraMandate.SetBlocked(ConnectionSetup, Rec."Avalara Mandate", MandateBlocked);
        RefreshActivationStatus();
    end;

    /// <summary>
    /// Clears the activation status fields.
    /// </summary>
    local procedure ClearActivationFields()
    begin
        ActivationStatus := '';
        MandateBlocked := false;
    end;
}