// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Foundation.Attachment;
using Microsoft.Manufacturing.Comment;
using Microsoft.Utilities;

page 99000786 "Production BOM"
{
    Caption = 'Production BOM';
    PageType = ListPlus;
    SourceTable = "Production BOM Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description for the production BOM.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the manufacturing batch unit of measure.';
                    ShowMandatory = true;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the status of the production BOM.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                    Importance = Additional;
                }
                field("Version Nos."; Rec."Version Nos.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the version number series that the production BOM versions refer to.';
                }
                field(ActiveVersionCode; ActiveVersionCode)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Active Version';
                    Editable = false;
                    Style = Strong;
                    Enabled = ActiveVersionCode <> '';
                    ToolTip = 'Specifies which version of the production BOM is valid.';

                    trigger OnAssistEdit()
                    var
                        ProductionBOMVersion: Record "Production BOM Version";
                    begin
                        if ActiveVersionCode = '' then
                            exit;

                        ProductionBOMVersion.SetRange("Production BOM No.", Rec."No.");
                        ProductionBOMVersion.SetRange("Version Code", ActiveVersionCode);
                        Page.RunModal(Page::"Production BOM Version", ProductionBOMVersion);
                        RefreshActiveVersionCode();
                    end;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the last date that was modified.';
                }
            }
            part(ProdBOMLine; "Production BOM Lines")
            {
                ApplicationArea = Manufacturing;
                SubPageLink = "Production BOM No." = field("No."),
                              "Version Code" = const('');
                SubPageView = sorting("Production BOM No.", "Version Code", "Line No.");
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
                Visible = true;
            }
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"Production BOM Header"),
                              "No." = field("No.");
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
                    ToolTip = 'View any alternate versions of the production BOM.';

                    trigger OnAction()
                    var
                        ProductionBOMVersion: Record "Production BOM Version";
                    begin
                        ProductionBOMVersion.SetRange("Production BOM No.", Rec."No.");
                        Page.RunModal(0, ProductionBOMVersion);
                        RefreshActiveVersionCode();
                    end;
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
                        ProdBOMMatrixPerVersion: Page "Prod. BOM Matrix per Version";
                    begin
                        ProdBOMMatrixPerVersion.Set(Rec);
                        ProdBOMMatrixPerVersion.RunModal();
                        Clear(ProdBOMMatrixPerVersion);
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

                        ProdBOMVersionComparison.RunModal();
                    end;
                }
                action("Where-used")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Where-used';
                    Image = "Where-Used";
                    ToolTip = 'View a list of BOMs in which the item is used.';

                    trigger OnAction()
                    var
                        ProdBOMWhereUsed: Page "Prod. BOM Where-Used";
                    begin
                        ProdBOMWhereUsed.SetProdBOM(Rec, WorkDate());
                        ProdBOMWhereUsed.RunModal();
                        Clear(ProdBOMWhereUsed);
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
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Copy &BOM")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Copy &BOM';
                    Ellipsis = true;
                    Image = CopyBOM;
                    ToolTip = 'Copy an existing production BOM to quickly create a similar BOM.';

                    trigger OnAction()
                    var
                        ProductionBOMHeader: Record "Production BOM Header";
                        ProductionBOMCopy: Codeunit "Production BOM-Copy";
                    begin
                        Rec.TestField("No.");
                        OnCopyBOMOnBeforeLookup(Rec, ProductionBOMHeader);
                        if Page.RunModal(0, ProductionBOMHeader) = Action::LookupOK then
                            ProductionBOMCopy.CopyBOM(ProductionBOMHeader."No.", '', Rec, '');
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Copy &BOM_Promoted"; "Copy &BOM")
                {
                }
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
            group(Category_Category4)
            {
                Caption = 'Prod. BOM', Comment = 'Generated from the PromotedActionCategories property index 3.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        RefreshActiveVersionCode();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        if not CurrPage.Editable() then
            exit(true);

        if IsNullGuid(Rec.SystemId) then
            exit(true);

        if Rec.Status in [Rec.Status::Certified, Rec.Status::Closed] then
            exit(true);

        if Rec."Unit of Measure Code" = '' then
            exit(true);

        if not Rec.ProductionBOMLinesExist() then
            exit(true);

        if ShowNonCertifiedNotification() then
            if not InstructionMgt.ShowConfirmNonCertified() then
                exit(false);

        exit(true);
    end;

    var
        ActiveVersionCode: Code[20];

    local procedure RefreshActiveVersionCode()
    var
        VersionManagement: Codeunit VersionManagement;
    begin
        ActiveVersionCode := VersionManagement.GetBOMVersion(Rec."No.", WorkDate(), true);
    end;

    local procedure ShowNonCertifiedNotification(): Boolean
    begin
        if Rec.Status <> Rec.Status::Certified then
            exit(true)
        else
            exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyBOMOnBeforeLookup(var ToProductionBOMHeader: Record "Production BOM Header"; var FromProductionBOMHeader: Record "Production BOM Header")
    begin
    end;
}

