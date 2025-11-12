// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using System.Utilities;

#pragma warning disable AS0106 // Protected variable Adv was removed before AS0106 was introduced.
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; FromVATPostingSetup: Record "VAT Posting Setup"; Sales: Boolean; Purch: Boolean; VATSetup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetVatPercent(var VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyVatPostingSetup(VATPostingSetup: Record "VAT Posting Setup"; UseVATPostingSetup: Record "VAT Posting Setup"; VATSetup: boolean)
    begin
    end;
}

