// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Purchases.Document;

pageextension 99001523 "Subc. Purch. Order" extends "Purchase Order"
{
    layout
    {
        addafter(Status)
        {
            field("Subc. Order"; Rec."Subc. Order")
            {
                ApplicationArea = Subcontracting;
            }
            field("Subc. Location Code"; Rec."Subc. Location Code")
            {
                ApplicationArea = Subcontracting;
                Editable = false;
            }
        }
        addafter(WorkflowStatus)
        {
            part(" Sub Purchase Line Factbox"; "Subc. Purchase Line Factbox")
            {
                ApplicationArea = Subcontracting;
                Provider = PurchLines;
                SubPageLink = "Document Type" = field("Document Type"), "Document No." = field("Document No."), "Line No." = field("Line No.");
                Visible = HasSubcontractingContext;
            }
        }
    }
    actions
    {
        addafter(IncomingDocument)
        {
            group(Subcontracting)
            {
                Caption = 'Subcontracting';
                Visible = HasSubcontractingContext;
                action(CreateTransfOrdToSubcontractor)
                {
                    ApplicationArea = Subcontracting;
                    Caption = 'Create Transf. Ord. to Subcontractor';
                    Image = NewDocument;
                    ToolTip = 'Create a transfer order to send to the subcontractor.';

                    trigger OnAction()
                    var
                        PurchaseHeader: Record "Purchase Header";
                    begin
                        PurchaseHeader := Rec;
                        PurchaseHeader.SetRecFilter();
                        Report.Run(Report::"Subc. Create Transf. Order", false, false, PurchaseHeader);
                    end;
                }
                action(CreateReturnFromSubcontractor)
                {
                    ApplicationArea = Subcontracting;
                    Caption = 'Create Return from Subcontractor';
                    Image = ReturnRelated;
                    ToolTip = 'Create a return document from the subcontractor.';

                    trigger OnAction()
                    var
                        PurchaseHeader: Record "Purchase Header";
                    begin
                        PurchaseHeader := Rec;
                        PurchaseHeader.SetRecFilter();
                        Report.Run(Report::"Subc. Create SubCReturnOrder", false, false, PurchaseHeader);
                    end;
                }
                action(PrintSubcDispatchingList)
                {
                    ApplicationArea = Subcontracting;
                    Caption = 'Print Subcontractor Dispatching List';
                    Image = Print;
                    ToolTip = 'Print the dispatching list for the subcontractor.';

                    trigger OnAction()
                    var
                        PurchaseHeader: Record "Purchase Header";
                    begin
                        PurchaseHeader := Rec;
                        PurchaseHeader.SetRecFilter();
                        Report.Run(Report::"Subc. Dispatching List", true, false, PurchaseHeader);
                    end;
                }
            }
        }
    }
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
#if not CLEAN29
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
        SubcontractingEnabled: Boolean;
#endif
        HasSubcontractingContext: Boolean;

    trigger OnOpenPage()
    begin
#if not CLEAN29
#pragma warning disable AL0432
        SubcontractingEnabled := SubcFeatureFlagHandler.IsSubcontractingEnabled();
#pragma warning restore AL0432
        if not SubcontractingEnabled then
            exit;
#endif
        HasSubcontractingContext := SubcontractingManagement.IsSubcontractingPurchaseDocument(Rec);
        CurrPage.PurchLines.Page.SetIsSubcontracting(HasSubcontractingContext);
    end;

    trigger OnAfterGetCurrRecord()
    begin
#if not CLEAN29
        if not SubcontractingEnabled then
            exit;

#endif
        HasSubcontractingContext := SubcontractingManagement.IsSubcontractingPurchaseDocument(Rec);
        CurrPage.PurchLines.Page.SetIsSubcontracting(HasSubcontractingContext);
    end;
}