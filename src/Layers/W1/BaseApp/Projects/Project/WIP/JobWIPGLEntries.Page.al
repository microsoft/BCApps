// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.WIP;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Navigate;

page 1009 "Job WIP G/L Entries"
{
    AdditionalSearchTerms = 'work in process to general ledger entries,work in progress to general ledger entries, Job WIP G/L Entries';
    ApplicationArea = Jobs;
    Caption = 'Project WIP G/L Entries';
    DataCaptionFields = "Job No.";
    Editable = false;
    PageType = List;
    SourceTable = "Job WIP G/L Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Reversed; Rec.Reversed)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether the entry has been reversed. If the check box is selected, the entry has been reversed from the G/L.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the posting date you entered in the Posting Date field, on the Options FastTab, in the Project Post WIP to G/L batch job.';
                }
                field("WIP Posting Date"; Rec."WIP Posting Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the posting date you entered in the Posting Date field, on the Options FastTab, in the Project Calculate WIP batch job.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the document number you entered in the Document No. field on the Options FastTab in the Project Post WIP to G/L batch job.';
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related project.';
                }
                field("Job Complete"; Rec."Job Complete")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether a project is complete. This check box is selected if the Project WIP G/L Entry was created for a Project with a Completed status.';
                }
                field("Job WIP Total Entry No."; Rec."Job WIP Total Entry No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the entry number from the associated project WIP total.';
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the general ledger account number to which the WIP, on this entry, is posted.';
                }
                field("G/L Bal. Account No."; Rec."G/L Bal. Account No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the general ledger balancing account number that WIP on this entry was posted to.';
                }
                field("Reverse Date"; Rec."Reverse Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the reverse date. If the WIP on this entry is reversed, you can see the date of the reversal in the Reverse Date field.';
                }
                field("WIP Method Used"; Rec."WIP Method Used")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the WIP method that was specified for the project when you ran the Project Calculate WIP batch job.';
                }
                field("WIP Posting Method Used"; Rec."WIP Posting Method Used")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the WIP posting method used in the context of the general ledger. The information in this field comes from the setting you have specified on the project card.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the WIP type for this entry.';
                }
                field("WIP Entry Amount"; Rec."WIP Entry Amount")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the WIP amount that was posted in the general ledger for this entry.';
                }
                field("Job Posting Group"; Rec."Job Posting Group")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the posting group related to this entry.';
                }
                field("WIP Transaction No."; Rec."WIP Transaction No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the transaction number assigned to all the entries involved in the same transaction.';
                }
                field(Reverse; Rec.Reverse)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether the entry has been part of a reverse transaction (correction) made by the reverse function.';
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = Dim1Visible;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = Dim2Visible;
                }
                field("G/L Entry No."; Rec."G/L Entry No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the G/L Entry No. to which this entry is linked.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Dimension Set ID"; Rec."Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
                    Visible = false;
                }
                field("Shortcut Dimension 3 Code"; Rec."Shortcut Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 3, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim3Visible;
                }
                field("Shortcut Dimension 4 Code"; Rec."Shortcut Dimension 4 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 4, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim4Visible;
                }
                field("Shortcut Dimension 5 Code"; Rec."Shortcut Dimension 5 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 5, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim5Visible;
                }
                field("Shortcut Dimension 6 Code"; Rec."Shortcut Dimension 6 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 6, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim6Visible;
                }
                field("Shortcut Dimension 7 Code"; Rec."Shortcut Dimension 7 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 7, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim7Visible;
                }
                field("Shortcut Dimension 8 Code"; Rec."Shortcut Dimension 8 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 8, which is one of dimension codes that you set up in the General Ledger Setup window.';
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
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Jobs;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Navigate.SetDoc(Rec."Posting Date", Rec."Document No.");
                    Navigate.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                group(Category_Category4)
                {
                    Caption = 'Entry', Comment = 'Generated from the PromotedActionCategories property index 3.';

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
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetDimVisibility();
    end;

    var
        Navigate: Page Navigate;
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

