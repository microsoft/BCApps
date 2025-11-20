// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Foundation.Attachment;
using Microsoft.Manufacturing.Comment;
using Microsoft.Manufacturing.Reports;

page 99000787 "Production BOM List"
{
    AdditionalSearchTerms = 'bill of materials';
    ApplicationArea = Manufacturing;
    Caption = 'Production BOMs';
    CardPageID = "Production BOM";
    DataCaptionFields = "No.";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Production BOMs';
    AboutText = 'Manage and track production Bills of Materials, including creating, editing, and versioning BOMs with multiple components to support manufacturing processes and product changes.';
    SourceTable = "Production BOM Header";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description for the production BOM.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies an extended description for the BOM if there is not enough space in the Description field.';
                    Visible = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the status of the production BOM.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the manufacturing batch unit of measure.';
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                    Visible = false;
                }
                field("Version Nos."; Rec."Version Nos.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the version number series that the production BOM versions refer to.';
                    Visible = false;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the last date that was modified.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"Production BOM Header"),
                              "No." = field("No.");
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Prod. BOM")
            {
                Caption = '&Prod. BOM';
                Image = BOM;
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Manufacturing Comment Sheet";
                    RunPageLink = "Table Name" = const("Production BOM Header"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Versions)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Versions';
                    Image = BOMVersions;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    RunObject = Page "Prod. BOM Version List";
                    RunPageLink = "Production BOM No." = field("No.");
                    ToolTip = 'View any alternate versions of the production BOM.';
                }
#if not CLEAN26
                action("Ma&trix per Version")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ma&trix per Version';
                    Image = ProdBOMMatrixPerVersion;
                    ObsoleteReason = 'Replaced by "Prod. BOM Version Comparison"';
                    ObsoleteState = Pending;
                    ObsoleteTag = '26.0';
                    Visible = false;
                    ToolTip = 'View a list of all versions and items and the used quantity per item of a production BOM. You can use the matrix to compare different production BOM versions concerning the used items per version.';

                    trigger OnAction()
                    var
                        BOMMatrixForm: Page "Prod. BOM Matrix per Version";
                    begin
                        BOMMatrixForm.Set(Rec);

                        BOMMatrixForm.Run();
                    end;
                }
#endif
                action("Prod. BOM Version Comparison")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Production BOM Version Comparison';
                    Image = ProdBOMMatrixPerVersion;
                    ToolTip = 'View a list of all versions and items and the used quantity per item of a production BOM. You can use the matrix to compare different production BOM versions concerning the used items per version.';

                    trigger OnAction()
                    var
                        ProdBOMVersionComparison: Page "Prod. BOM Version Comparison";
                    begin
                        ProdBOMVersionComparison.Set(Rec);

                        ProdBOMVersionComparison.Run();
                    end;
                }
                action("Where-used")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Where-used';
                    Image = "Where-Used";
                    ToolTip = 'View a list of BOMs in which the item is used.';

                    trigger OnAction()
                    begin
                        ProdBOMWhereUsed.SetProdBOM(Rec, WorkDate());

                        ProdBOMWhereUsed.Run();
                    end;
                }
                action(DocAttach)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Attachments';
                    Image = Attach;
                    ToolTip = 'Add a file as an attachment. You can attach images as well as documents.';

                    trigger OnAction()
                    var
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        DocumentAttachmentDetails.RunModal();
                    end;
                }
            }
        }
        area(processing)
        {
            action("Exchange Production BOM Item")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Exchange Production BOM Item';
                Image = ExchProdBOMItem;
                RunObject = Report "Exchange Production BOM Item";
                ToolTip = 'Replace items that are no longer used in production BOMs. You can exchange an item, for example, with a new item or a new production BOM. You can create new versions while exchanging an item in the production BOMs.';
            }
            action("Delete Expired Components")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Delete Expired Components';
                Image = DeleteExpiredComponents;
                RunObject = Report "Delete Expired Components";
                ToolTip = 'Remove BOM lines that have expired ending dates. The BOM header will not be changed.';
            }
            action("Calculate Low-Level Code")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Calculate Low-Level Code';
                Image = CalculateHierarchy;
                RunObject = Report "Calculate Low Level Code";
                ToolTip = 'Calculate the low-level codes for items in production BOMs. Low-level codes determine the sequence in which materials are planned during MRP runs. Top level items have code 0.';
            }
        }
        area(reporting)
        {
            action("Where-Used (Top Level)")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Where-Used (Top Level)';
                Image = "Report";
                RunObject = Report "Where-Used (Top Level)";
                ToolTip = 'View where and in what quantities the item is used in the product structure. The report only shows information for the top-level item. For example, if item "A" is used to produce item "B", and item "B" is used to produce item "C", the report will show item B if you run this report for item A. If you run this report for item B, then item C will be shown as where-used.';
            }
            action("Quantity Explosion of BOM")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Quantity Explosion of BOM';
                Image = "Report";
                RunObject = Report "Quantity Explosion of BOM";
                ToolTip = 'View an indented BOM listing for the item or items that you specify in the filters. The production BOM is completely exploded for all levels.';
            }
#if not CLEAN27
            action("Compare List")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Compare List (Obsolete)';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Compare List";
                ToolTip = 'View a comparison of components for two items. The printout compares the components, their unit cost, cost share and cost per component.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report has been replaced by the "Compare Production Cost Shares" report and will be removed in a future release.';
                ObsoleteTag = '27.0';
            }
#endif
            action("Compare Production Cost Shares")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Compare Production Cost Shares';
                Image = "Report";
                RunObject = Report "Compare Production Cost Shares";
                ToolTip = 'View a comparison of components for two items. The printout compares the components, their unit cost, cost share and cost per component.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Exchange Production BOM Item_Promoted"; "Exchange Production BOM Item")
                {
                }
                actionref("Delete Expired Components_Promoted"; "Delete Expired Components")
                {
                }
            }
            group("Category_Prod. BOM")
            {
                Caption = 'Prod. BOM';

#if not CLEAN26
                actionref("Ma&trix per Version_Promoted"; "Ma&trix per Version")
                {
                    ObsoleteReason = 'Replaced by "Prod. BOM Version Comparison"';
                    ObsoleteState = Pending;
                    ObsoleteTag = '26.0';
                    Visible = false;
                }
#endif
                actionref("Prod. BOM Version Comparison_Promoted"; "Prod. BOM Version Comparison")
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref(Versions_Promoted; Versions)
                {
                }
                actionref("Where-used_Promoted"; "Where-used")
                {
                }
                actionref(DocAttach_Promoted; DocAttach)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Where-Used (Top Level)_Promoted"; "Where-Used (Top Level)")
                {
                }
                actionref("Quantity Explosion of BOM_Promoted"; "Quantity Explosion of BOM")
                {
                }
            }
        }
    }

    var
        ProdBOMWhereUsed: Page "Prod. BOM Where-Used";
}

