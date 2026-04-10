// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Ledger;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Navigate;
using Microsoft.Projects.Project.Analysis;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using System.Security.User;

page 92 "Job Ledger Entries"
{
    AdditionalSearchTerms = 'Job Ledger Entries';
    ApplicationArea = Jobs;
    Caption = 'Project Ledger Entries';
    DataCaptionFields = "Job No.";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Project Ledger Entries';
    AboutText = 'Review all financial and usage entries posted to projects, including details on costs, prices, quantities, and dimensions, to track project progress and analyze performance. View links to project planning lines and monitor adjustments for accurate project accounting.';
    SourceTable = "Job Ledger Entry";
    SourceTableView = sorting("Job No.", "Posting Date")
                      order(descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Jobs;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Jobs;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Job Posting Group"; Rec."Job Posting Group")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Jobs;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Jobs;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Jobs;
                }
                field("Direct Unit Cost (LCY)"; Rec."Direct Unit Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the cost, in the local currency, of one unit of the selected item or resource.';
                    Visible = false;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                }
                field("Unit Cost (LCY)"; Rec."Unit Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                }
                field("Total Cost"; Rec."Total Cost")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                }
                field("Total Cost (LCY)"; Rec."Total Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total cost of the posted entry in local currency. If you update the project ledger costs for item ledger cost adjustments, this field will be adjusted to include the item cost adjustments.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Jobs;
                }
                field("Unit Price (LCY)"; Rec."Unit Price (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the price, in LCY, of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                    Visible = false;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Jobs;
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Jobs;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Jobs;
                }
                field("Total Price"; Rec."Total Price")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    Visible = false;
                }
                field("Total Price (LCY)"; Rec."Total Price (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total price (in local currency) of the posted entry.';
                    Visible = false;
                }
                field("Line Amount (LCY)"; Rec."Line Amount (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the value in the local currency of products on the entry.';
                    Visible = false;
                }
                field("Amt. to Post to G/L"; Rec."Amt. to Post to G/L")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Amt. Posted to G/L"; Rec."Amt. Posted to G/L")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Original Unit Cost"; Rec."Original Unit Cost")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Original Unit Cost (LCY)"; Rec."Original Unit Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the unit cost of the posted entry in local currency at the time the entry was posted. It does not include any item cost adjustments.';
                    Visible = false;
                }
                field("Original Total Cost"; Rec."Original Total Cost")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Original Total Cost (LCY)"; Rec."Original Total Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total cost of the posted entry in local currency at the time the entry was posted. It does not include any item cost adjustments.';
                    Visible = false;
                }
                field("Original Total Cost (ACY)"; Rec."Original Total Cost (ACY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total cost of the posted entry in the additional reporting currency at the time of posting. No item cost adjustments are included.';
                    Visible = false;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    Visible = false;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Visible = false;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    Visible = false;
                }
                field("Ledger Entry Type"; Rec."Ledger Entry Type")
                {
                    ApplicationArea = Jobs;
                }
                field("Ledger Entry No."; Rec."Ledger Entry No.")
                {
                    ApplicationArea = Jobs;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                }
                field(Adjusted; Rec.Adjusted)
                {
                    ApplicationArea = Jobs;
                }
                field("DateTime Adjusted"; Rec."DateTime Adjusted")
                {
                    ApplicationArea = Jobs;
                }
                field("Dimension Set ID"; Rec."Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
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
                        xRec.ShowDimensions();
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
                action("<Action28>")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Show Linked Project Planning Lines';
                    Image = JobLines;
                    ToolTip = 'View the planning lines that are associated with project journal entries that have been posted to the project ledger. This requires that the Apply Usage Link check box has been selected for the project, or is the default setting for all projects in your organization.';

                    trigger OnAction()
                    var
                        JobUsageLink: Record "Job Usage Link";
                        JobPlanningLine: Record "Job Planning Line";
                    begin
                        JobUsageLink.SetRange("Entry No.", Rec."Entry No.");

                        if JobUsageLink.FindSet() then
                            repeat
                                JobPlanningLine.Get(JobUsageLink."Job No.", JobUsageLink."Job Task No.", JobUsageLink."Line No.");
                                JobPlanningLine.Mark := true;
                            until JobUsageLink.Next() = 0;

                        JobPlanningLine.MarkedOnly(true);
                        PAGE.Run(PAGE::"Job Planning Lines", JobPlanningLine);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Transfer To Planning Lines")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Transfer To Planning Lines';
                    Ellipsis = true;
                    Image = TransferToLines;
                    ToolTip = 'Create planning lines from posted project ledger entries. This is useful if you forgot to specify the planning lines that should be created when you posted the project journal lines.';

                    trigger OnAction()
                    var
                        JobLedgEntry: Record "Job Ledger Entry";
                        JobTransferToPlanningLine: Report "Job Transfer To Planning Lines";
                    begin
                        JobLedgEntry.Copy(Rec);
                        CurrPage.SetSelectionFilter(JobLedgEntry);
                        Clear(JobTransferToPlanningLine);
                        JobTransferToPlanningLine.GetJobLedgEntry(JobLedgEntry);
                        JobTransferToPlanningLine.RunModal();
                        Clear(JobTransferToPlanningLine);
                    end;
                }
            }
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
        area(Reporting)
        {
            action(ProjectsAnalysis)
            {
                ApplicationArea = Jobs;
                Caption = 'Analyze Projects';
                Image = Job;
                RunObject = Query ProjectsAnalysis;
                ToolTip = 'Analyze (group, summarize, pivot) your Project Ledger Entries with related Project master data such as Project Task, Resource, Item, and G/L Account.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref("Transfer To Planning Lines_Promoted"; "Transfer To Planning Lines")
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
                }
                actionref("<Action28>_Promoted"; "<Action28>")
                {
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

