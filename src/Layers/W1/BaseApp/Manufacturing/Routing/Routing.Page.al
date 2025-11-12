// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;

using Microsoft.Foundation.Attachment;
using Microsoft.Manufacturing.Comment;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Reports;
using Microsoft.Utilities;

page 99000766 Routing
{
    Caption = 'Routing';
    PageType = ListPlus;
    SourceTable = "Routing Header";

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
                    ToolTip = 'Specifies a description for the routing header.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies in which order operations in the routing are performed.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the status of this routing.';
                }
                field("Search Description"; Rec."Search Description")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a search description.';
                }
                field("Version Nos."; Rec."Version Nos.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number series you want to use to create a new version of this routing.';
                }
                field(ActiveVersionCode; ActiveVersionCode)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Active Version';
                    Editable = false;
                    Style = Strong;
                    Enabled = ActiveVersionCode <> '';
                    ToolTip = 'Specifies if the routing version is currently being used.';

                    trigger OnAssistEdit()
                    var
                        RoutingVersion: Record "Routing Version";
                    begin
                        if ActiveVersionCode = '' then
                            exit;

                        RoutingVersion.SetRange("Routing No.", Rec."No.");
                        RoutingVersion.SetRange("Version Code", ActiveVersionCode);
                        Page.RunModal(Page::"Routing Version", RoutingVersion);
                        RefreshActiveVersionCode();
                    end;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies when the routing card was last modified.';

                    trigger OnValidate()
                    begin
                        LastDateModifiedOnAfterValidate();
                    end;
                }
            }
            part(RoutingLine; "Routing Lines")
            {
                ApplicationArea = Manufacturing;
                SubPageLink = "Routing No." = field("No."),
                              "Version Code" = const('');
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
                SubPageLink = "Table ID" = const(Database::"Routing Header"),
                              "No." = field("No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Routing")
            {
                Caption = '&Routing';
                Image = Route;
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Manufacturing Comment Sheet";
                    RunPageLink = "Table Name" = const("Routing Header"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("&Versions")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Versions';
                    Image = RoutingVersions;
                    ToolTip = 'View or edit other versions of the routing, typically with other operations data.';

                    trigger OnAction()
                    var
                        RoutingVersion: Record "Routing Version";
                    begin
                        RoutingVersion.SetRange("Routing No.", Rec."No.");
                        Page.RunModal(0, RoutingVersion);
                        RefreshActiveVersionCode();
                    end;
                }
                action("Where-used")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Where-used';
                    Image = "Where-Used";
                    RunObject = Page "Where-Used Item List";
                    RunPageLink = "Routing No." = field("No.");
                    RunPageView = sorting("Routing No.");
                    ToolTip = 'View a list of BOMs in which the item is used.';
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
                action("Copy &Routing")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Copy &Routing';
                    Ellipsis = true;
                    Image = CopyDocument;
                    ToolTip = 'Copy an existing routing to quickly create a similar BOM.';

                    trigger OnAction()
                    var
                        FromRoutingHeader: Record "Routing Header";
                        RoutingLineCopyLines: Codeunit "Routing Line-Copy Lines";
                    begin
                        Rec.TestField("No.");
                        if Page.RunModal(0, FromRoutingHeader) = Action::LookupOK then
                            RoutingLineCopyLines.CopyRouting(FromRoutingHeader."No.", '', Rec, '');
                    end;
                }
            }
        }
        area(reporting)
        {
            action("Routing Sheet")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Routing Sheet';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Routing Sheet";
                ToolTip = 'View basic information for routings, such as send-ahead quantity, setup time, run time and time unit. This report shows you the operations to be performed in this routing, the work or machine centers to be used, the personnel, the tools, and the description of each operation.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Copy &Routing_Promoted"; "Copy &Routing")
                {
                }
                actionref("&Versions_Promoted"; "&Versions")
                {
                }
                actionref("Where-used_Promoted"; "Where-used")
                {
                }
                actionref(DocAttach_Promoted; DocAttach)
                {
                }
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
        Result: Boolean;
        IsHandled: Boolean;
    begin
        Result := false;
        IsHandled := false;
        OnBeforeOnQueryClosePage(Rec, xRec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not CurrPage.Editable() then
            exit(true);

        if IsNullGuid(Rec.SystemId) then
            exit(true);

        if Rec.Status in [Rec.Status::Certified, Rec.Status::Closed] then
            exit(true);

        if not Rec.RoutingLinesExist() then
            exit(true);

        if ShowNonCertifiedNotification() then
            if not InstructionMgt.ShowConfirmNonCertified() then
                exit(false);

        exit(true);
    end;

    var
        ActiveVersionCode: Code[20];

    local procedure LastDateModifiedOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure RefreshActiveVersionCode()
    var
        VersionManagement: Codeunit VersionManagement;
    begin
        ActiveVersionCode := VersionManagement.GetRtngVersion(Rec."No.", WorkDate(), true);
    end;

    local procedure ShowNonCertifiedNotification(): Boolean
    begin
        if Rec.Status <> Rec.Status::Certified then
            exit(true)
        else
            exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnQueryClosePage(var RoutingHeader: Record "Routing Header"; var xRoutingHeader: Record "Routing Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

