// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using System.Utilities;

#pragma warning disable AS0106 // Protected variable Adv was removed before AS0106 was introduced.
/// <summary>
/// Copies VAT posting setup configuration from one setup combination to multiple target combinations.
/// Enables bulk configuration of VAT posting setups with consistent settings across multiple business/product posting groups.
/// </summary>
/// <remarks>
/// Key functionality: Copies VAT percentages, account assignments, and calculation settings between VAT posting setups.
/// Usage scenarios: Initial VAT setup, mass updates to VAT configuration, standardizing VAT settings.
/// Extensibility: Integration events for custom copy logic and validation rules.
/// </remarks>
report 85 "Copy - VAT Posting Setup"
#pragma warning restore AS0106
{
    Caption = 'Copy - VAT Posting Setup';
    ProcessingOnly = true;

    dataset
    {
        dataitem("VAT Posting Setup"; "VAT Posting Setup")
        {
            DataItemTableView = sorting("VAT Bus. Posting Group", "VAT Prod. Posting Group");

            trigger OnAfterGetRecord()
            var
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled: Boolean;
            begin
                VATPostingSetup.Find();
                if VATSetup then begin
                    "VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                    IsHandled := false;
                    OnBeforeSetVatPercent("VAT Posting Setup", IsHandled);
                    if not IsHandled then
                        "VAT %" := VATPostingSetup."VAT %";
                    "Unrealized VAT Type" := VATPostingSetup."Unrealized VAT Type";
                    "Adjust for Payment Discount" := VATPostingSetup."Adjust for Payment Discount";
                    "VAT Identifier" := VATPostingSetup."VAT Identifier";
                end;

                if Sales then begin
                    "Sales VAT Account" := VATPostingSetup."Sales VAT Account";
                    "Sales VAT Unreal. Account" := VATPostingSetup."Sales VAT Unreal. Account";
                end;

                if Purch then begin
                    "Purchase VAT Account" := VATPostingSetup."Purchase VAT Account";
                    "Purch. VAT Unreal. Account" := VATPostingSetup."Purch. VAT Unreal. Account";
                    "Reverse Chrg. VAT Acc." := VATPostingSetup."Reverse Chrg. VAT Acc.";
                    "Reverse Chrg. VAT Unreal. Acc." := VATPostingSetup."Reverse Chrg. VAT Unreal. Acc.";
                end;

                OnAfterCopyVATPostingSetup("VAT Posting Setup", VATPostingSetup, Sales, Purch, VATSetup);

                if ConfirmManagement.GetResponseOrDefault(Text000, true) then begin
                    OnBeforeModifyVatPostingSetup(VATPostingSetup, UseVATPostingSetup, VATSetup);
                    Modify();
                end;
            end;

            trigger OnPreDataItem()
            begin
                SetRange("VAT Bus. Posting Group", UseVATPostingSetup."VAT Bus. Posting Group");
                SetRange("VAT Prod. Posting Group", UseVATPostingSetup."VAT Prod. Posting Group");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(VATBusPostingGroup; VATPostingSetup."VAT Bus. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Bus. Posting Group';
                        TableRelation = "VAT Business Posting Group";
                        ToolTip = 'Specifies the VAT business posting group to copy from.';
                    }
                    field(VATProdPostingGroup; VATPostingSetup."VAT Prod. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Prod. Posting Group';
                        TableRelation = "VAT Product Posting Group";
                        ToolTip = 'Specifies the VAT product posting group to copy from.';
                    }
                    field(Copy; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Copy';
                        OptionCaption = 'All fields,Selected fields';
                        ToolTip = 'Specifies if all fields or only selected fields are copied.';

                        trigger OnValidate()
                        begin
                            if Selection = Selection::"All fields" then
                                AllfieldsSelectionOnValidate();
                        end;
                    }
                    field(VATetc; VATSetup)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT % etc.';
                        ToolTip = 'Specifies if you want to copy the VAT rate.';

                        trigger OnValidate()
                        begin
                            Selection := Selection::"Selected fields";
                        end;
                    }
                    field(SalesAccounts; Sales)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Accounts';
                        ToolTip = 'Specifies if you want to copy the sales VAT accounts.';

                        trigger OnValidate()
                        begin
                            Selection := Selection::"Selected fields";
                        end;
                    }
                    field(PurchaseAccounts; Purch)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Accounts';
                        ToolTip = 'Specifies if you want to copy the purchase VAT accounts.';

                        trigger OnValidate()
                        begin
                            Selection := Selection::"Selected fields";
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if Selection = Selection::"All fields" then begin
                VATSetup := true;
                Sales := true;
                Purch := true;
            end;
        end;
    }

    labels
    {
    }

    var
#pragma warning disable AA0074
        Text000: Label 'Copy VAT Posting Setup?';
#pragma warning restore AA0074

    protected var
        UseVATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATSetup: Boolean;
        Sales: Boolean;
        Purch: Boolean;
        Selection: Option "All fields","Selected fields";

    /// <summary>
    /// Sets the source VAT posting setup record to copy settings from during the copy operation.
    /// </summary>
    /// <param name="VATPostingSetup2">Source VAT posting setup record containing settings to copy</param>
    procedure SetVATSetup(VATPostingSetup2: Record "VAT Posting Setup")
    begin
        UseVATPostingSetup := VATPostingSetup2;
    end;

    local procedure AllfieldsSelectionOnPush()
    begin
        VATSetup := true;
        Sales := true;
        Purch := true;
    end;

    local procedure AllfieldsSelectionOnValidate()
    begin
        AllfieldsSelectionOnPush();
    end;

    /// <summary>
    /// Integration event raised after copying VAT posting setup to allow custom field updates and validation.
    /// Enables extensions to copy additional fields or perform post-copy processing logic.
    /// </summary>
    /// <param name="VATPostingSetup">Target VAT posting setup record after copy operation</param>
    /// <param name="FromVATPostingSetup">Source VAT posting setup record that was copied from</param>
    /// <param name="Sales">Whether sales VAT settings were copied</param>
    /// <param name="Purch">Whether purchase VAT settings were copied</param>
    /// <param name="VATSetup">Whether VAT calculation settings were copied</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; FromVATPostingSetup: Record "VAT Posting Setup"; Sales: Boolean; Purch: Boolean; VATSetup: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before setting VAT percentage to allow custom VAT percentage logic.
    /// Enables extensions to override standard VAT percentage assignment during copy operations.
    /// </summary>
    /// <param name="VATPostingSetup">VAT posting setup record being updated</param>
    /// <param name="IsHandled">Set to true to skip standard VAT percentage assignment</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetVatPercent(var VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before modifying VAT posting setup to allow custom validation and preprocessing.
    /// Enables extensions to validate changes or modify fields before the record is updated.
    /// </summary>
    /// <param name="VATPostingSetup">VAT posting setup record being modified</param>
    /// <param name="UseVATPostingSetup">Source VAT posting setup with values being copied</param>
    /// <param name="VATSetup">Whether VAT calculation settings are being copied</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyVatPostingSetup(VATPostingSetup: Record "VAT Posting Setup"; UseVATPostingSetup: Record "VAT Posting Setup"; VATSetup: boolean)
    begin
    end;
}

