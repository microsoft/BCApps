// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// Page for configuring default dimensions that apply to entire account types.
/// Enables setup of default dimension values and posting rules for account type categories rather than individual accounts.
/// </summary>
/// <remarks>
/// Used for setting up default dimensions that should apply to all accounts of a specific type.
/// Includes validation tools to check for conflicts between account-level and account-type-level dimension rules.
/// Integrates with dimension management and value posting validation processes.
/// </remarks>
page 541 "Account Type Default Dim."
{
    Caption = 'Account Type Default Dim.';
    DataCaptionFields = "Dimension Code";
    PageType = List;
    SourceTable = "Default Dimension";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Dimensions;

                    trigger OnValidate()
                    begin
                        TableIDOnAfterValidate();
                    end;
                }
                field("Table Caption"; Rec."Table Caption")
                {
                    ApplicationArea = Dimensions;
                    DrillDown = false;
                }
                field("Dimension Value Code"; Rec."Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Value Posting"; Rec."Value Posting")
                {
                    ApplicationArea = Dimensions;
                }
                field(AllowedValues; Rec."Allowed Values Filter")
                {
                    ApplicationArea = Dimensions;

                    trigger OnAssistEdit()
                    var
                        DimMgt: Codeunit DimensionManagement;
                    begin
                        Rec.TestField("Value Posting", Rec."Value Posting"::"Code Mandatory");
                        DimMgt.OpenAllowedDimValuesPerAccount(Rec);
                        CurrPage.Update();
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Check Value Posting")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Check Value Posting';
                    Ellipsis = true;
                    Image = "Report";
                    RunObject = Report "Check Value Posting";
                    ToolTip = 'Find out whether the value posting rules that are specified for individual default dimensions conflict with the rules specified for the account type default dimensions. For example, if you have set up a customer account with value posting No Code and then specify that all customer accounts should have a particular default dimension value code, this report will show that a conflict exists.';
                }
            }
        }
    }

    local procedure TableIDOnAfterValidate()
    begin
        Rec.CalcFields("Table Caption");
    end;
}

