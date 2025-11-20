// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

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
                    ToolTip = 'Specifies a table ID for the account type if you are specifying default dimensions for an entire account type.';

                    trigger OnValidate()
                    begin
                        TableIDOnAfterValidate();
                    end;
                }
                field("Table Caption"; Rec."Table Caption")
                {
                    ApplicationArea = Dimensions;
                    DrillDown = false;
                    ToolTip = 'Specifies the table name for the account type you wish to define a default dimension for.';
                }
                field("Dimension Value Code"; Rec."Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value code to suggest as the default dimension.';
                }
                field("Value Posting"; Rec."Value Posting")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies how default dimensions and their values must be used.';
                }
                field(AllowedValues; Rec."Allowed Values Filter")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension values that can be used for the selected account.';

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

