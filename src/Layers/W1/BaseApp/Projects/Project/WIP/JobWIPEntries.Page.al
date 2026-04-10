// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.WIP;

using Microsoft.Finance.Dimension;

page 1008 "Job WIP Entries"
{
    AdditionalSearchTerms = 'Job WIP Entries';
    ApplicationArea = Jobs;
    Caption = 'Project WIP Entries';
    DataCaptionFields = "Job No.";
    Editable = false;
    PageType = List;
    SourceTable = "Job WIP Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("WIP Posting Date"; Rec."WIP Posting Date")
                {
                    ApplicationArea = Jobs;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Jobs;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                }
                field("Job Complete"; Rec."Job Complete")
                {
                    ApplicationArea = Jobs;
                }
                field("Job WIP Total Entry No."; Rec."Job WIP Total Entry No.")
                {
                    ApplicationArea = Jobs;
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ApplicationArea = Jobs;
                }
                field("G/L Bal. Account No."; Rec."G/L Bal. Account No.")
                {
                    ApplicationArea = Jobs;
                }
                field("WIP Method Used"; Rec."WIP Method Used")
                {
                    ApplicationArea = Jobs;
                }
                field("WIP Posting Method Used"; Rec."WIP Posting Method Used")
                {
                    ApplicationArea = Jobs;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Jobs;
                }
                field("WIP Entry Amount"; Rec."WIP Entry Amount")
                {
                    ApplicationArea = Jobs;
                }
                field("Job Posting Group"; Rec."Job Posting Group")
                {
                    ApplicationArea = Jobs;
                }
                field(Reverse; Rec.Reverse)
                {
                    ApplicationArea = Jobs;
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = Dim1Visible;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = Dim2Visible;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Jobs;
                }
                field("Dimension Set ID"; Rec."Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Shortcut Dimension 3 Code"; Rec."Shortcut Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim3Visible;
                }
                field("Shortcut Dimension 4 Code"; Rec."Shortcut Dimension 4 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim4Visible;
                }
                field("Shortcut Dimension 5 Code"; Rec."Shortcut Dimension 5 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim5Visible;
                }
                field("Shortcut Dimension 6 Code"; Rec."Shortcut Dimension 6 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim6Visible;
                }
                field("Shortcut Dimension 7 Code"; Rec."Shortcut Dimension 7 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim7Visible;
                }
                field("Shortcut Dimension 8 Code"; Rec."Shortcut Dimension 8 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim8Visible;
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
        area(navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action("<Action57>")
                {
                    ApplicationArea = Jobs;
                    Caption = 'WIP Totals';
                    Image = EntriesList;
                    RunObject = Page "Job WIP Totals";
                    RunPageLink = "Entry No." = field("Job WIP Total Entry No.");
                    ToolTip = 'View the project''s WIP totals.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action(SetDimensionFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Set Dimension Filter';
                    Ellipsis = true;
                    Image = "Filter";
                    ToolTip = 'Limit the entries according to the dimension filters that you specify. NOTE: If you use a high number of dimension combinations, this function may not work and can result in a message that the SQL server only supports a maximum of 2100 parameters.';

                    trigger OnAction()
                    begin
                        Rec.SetFilter("Dimension Set ID", DimensionSetIDFilter.LookupFilter());
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(SetDimensionFilter_Promoted; SetDimensionFilter)
                {
                }
                actionref("<Action57>_Promoted"; "<Action57>")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetDimVisibility();
    end;

    var
        DimensionSetIDFilter: Page "Dimension Set ID Filter";

    protected var
        Dim1Visible: Boolean;
        Dim2Visible: Boolean;
        Dim3Visible: Boolean;
        Dim4Visible: Boolean;
        Dim5Visible: Boolean;
        Dim6Visible: Boolean;
        Dim7Visible: Boolean;
        Dim8Visible: Boolean;

    local procedure SetDimVisibility()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.UseShortcutDims(Dim1Visible, Dim2Visible, Dim3Visible, Dim4Visible, Dim5Visible, Dim6Visible, Dim7Visible, Dim8Visible);
    end;
}

