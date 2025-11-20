// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;
using System.Utilities;

page 99000809 "Production BOM Version"
{
    Caption = 'Production BOM Version';
    DataCaptionExpression = Rec.Caption();
    PageType = ListPlus;
    SourceTable = "Production BOM Version";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Version Code"; Rec."Version Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the version code of the production BOM.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description for the production BOM version.';
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
                    ToolTip = 'Specifies the status of this production BOM version.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the starting date for this production BOM version.';
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies when the production BOM version card was last modified.';
                }
            }
            part(ProdBOMLine; "Production BOM Version Lines")
            {
                ApplicationArea = Manufacturing;
                SubPageLink = "Production BOM No." = field("Production BOM No."),
                              "Version Code" = field("Version Code");
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
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ve&rsion")
            {
                Caption = 'Ve&rsion';
                Image = Versions;
                action("Where-Used")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Where-Used';
                    Image = "Where-Used";
                    ToolTip = 'View a list of BOMs in which the item is used.';

                    trigger OnAction()
                    var
                        ProductionBOMHeader: Record "Production BOM Header";
                        ProdBOMWhereUsed: Page "Prod. BOM Where-Used";
                    begin
                        ProductionBOMHeader.Get(Rec."Production BOM No.");
                        ProdBOMWhereUsed.SetProdBOM(ProductionBOMHeader, Rec."Starting Date");
                        ProdBOMWhereUsed.Run();
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
                action(CopyBOM)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Copy &BOM';
                    Image = CopyBOMHeader;
                    ToolTip = 'Copy an existing production BOM to quickly create a similar BOM.';

                    trigger OnAction()
                    var
                        ProductionBOMHeader: Record "Production BOM Header";
                        ProductionBOMCopy: Codeunit "Production BOM-Copy";
                    begin
                        if not Confirm(CopyFromProductionBOMQst, false) then
                            exit;

                        ProductionBOMHeader.Get(Rec."Production BOM No.");
                        ProductionBOMCopy.CopyBOM(Rec."Production BOM No.", '', ProductionBOMHeader, Rec."Version Code");
                    end;
                }
                action("Copy BOM &Version")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Copy BOM &Version';
                    Ellipsis = true;
                    Image = CopyBOMVersion;
                    ToolTip = 'Copy an existing production BOM version to quickly create a similar BOM.';

                    trigger OnAction()
                    var
                        ProductionBOMCopy: Codeunit "Production BOM-Copy";
                    begin
                        ProductionBOMCopy.CopyFromVersion(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CopyBOM_Promoted; CopyBOM)
                {
                }
                actionref("Copy BOM &Version_Promoted"; "Copy BOM &Version")
                {
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
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

        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(CertifyQst, CurrPage.Caption), false) then
            exit(false);

        exit(true);
    end;

    var
        CopyFromProductionBOMQst: Label 'Copy from Production BOM?';
        CertifyQst: Label 'The %1 has not been certified. Are you sure you want to exit?', Comment = '%1 = page caption (Production BOM)';
}

