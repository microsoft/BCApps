// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

using System.Telemetry;

page 2670 "Allocation Account"
{
    PageType = ListPlus;
    SourceTable = "Allocation Account";
    Caption = 'Allocation Account';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'No.';
                    ToolTip = 'Specifies the allocation account number.';
                }

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    ToolTip = 'Specifies the allocation account name.';
                }

                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = All;
                    Caption = 'Account Type';
                    ToolTip = 'Specifies the account type for the distribution.';

                    trigger OnValidate()
                    begin
                        UpdateVisibility();
                    end;
                }

                field(DocumentLinesSplit; Rec."Document Lines Split")
                {
                    ApplicationArea = All;
                    Caption = 'Document Line Split';
                    ToolTip = 'Specifies the strategy for splitting the lines when used on the documents.';
                }

                group(DistributionAccountTypeGroup)
                {
                    ShowCaption = false;
                    Visible = VariableAccountVisible;
                }
            }

            part(VariableAccountDistribution; "Variable Account Distribution")
            {
                ApplicationArea = Dimensions;
                Caption = 'Variable Account Distribution';
                SubPageLink = "Allocation Account No." = field("No."), "Account Type" = const(Variable);
                Visible = VariableAccountVisible;
            }

            part(FixedAccountDistribution; "Fixed Account Distribution")
            {
                ApplicationArea = Dimensions;
                Caption = 'Fixed Account Distribution';
                SubPageLink = "Allocation Account No." = field("No."), "Account Type" = const(Fixed);
                Visible = not VariableAccountVisible;
            }
        }
    }

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        AllocAccTelemetry: Codeunit "Alloc. Acc. Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000KYA', AllocAccTelemetry.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Discovered);
        UpdateVisibility();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateVisibility();
    end;

    local procedure UpdateVisibility()
    begin
        VariableAccountVisible := Rec."Account Type" = Rec."Account Type"::Variable;
    end;

    var
        VariableAccountVisible: Boolean;
}
