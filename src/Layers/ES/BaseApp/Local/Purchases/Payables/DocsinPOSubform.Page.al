// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.ReceivablesPayables;

page 7000075 "Docs. in PO Subform"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    Permissions = TableData "Cartera Doc." = m;
    SourceTable = "Cartera Doc.";
    SourceTableView = where(Type = const(Payable),
                            "Bill Gr./Pmt. Order No." = filter(<> ''));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the when the creation of this document was posted.';
                    Visible = false;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document in question.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the due date of this document.';
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the payment method code defined for the document number.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the document used to generate this document.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the number associated with a specific bill.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description associated with this document.';
                }
                field("Original Amount"; Rec."Original Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the initial amount of this document.';
                    Visible = false;
                }
                field("Original Amount (LCY)"; Rec."Original Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the initial amount of this document, in LCY.';
                    Visible = false;
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the pending payment amount for the document to be settled in full.';
                }
                field("Remaining Amt. (LCY)"; Rec."Remaining Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the pending amount, in order for the document to be settled in full.';
                    Visible = false;
                }
                field(Place; Rec.Place)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if the company bank and customer bank are in the same area.';
                    Visible = false;
                }
                field("Category Code"; Rec."Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a category code for this document.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the account number of the customer/vendor associated with this document.';
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the ledger entry number associated with the posting of this document.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Docs.")
            {
                Caption = '&Docs.';
                action(Insert)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insert';
                    Ellipsis = true;
                    ToolTip = 'Insert a bill group or payment order.';

                    trigger OnAction()
                    begin
                        AddPayableDocs(Rec."Bill Gr./Pmt. Order No.");
                    end;
                }
                action(Remove)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remove';
                    Image = Cancel;
                    ToolTip = 'Remove the selected documents.';

                    trigger OnAction()
                    begin
                        RemoveDocs(Rec."Bill Gr./Pmt. Order No.");
                    end;
                }
                action("Dime&nsions")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dime&nsions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action(Categorize)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Categorize';
                    Ellipsis = true;
                    Enabled = true;
                    Image = Category;
                    ToolTip = 'Insert categories on one or more Cartera documents to facilitate analysis. For example, to count or add only some documents, to analyze their due dates, to simulate scenarios for creating bill groups, to mark documents with your initials to indicate to other accountants that you are managing them personally.';

                    trigger OnAction()
                    begin
                        CategorizeDocs();
                    end;
                }
                action(Decategorize)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Decategorize';
                    Enabled = true;
                    Image = UndoCategory;
                    ToolTip = 'Remove categories applied to one or more Cartera documents to facilitate analysis.';

                    trigger OnAction()
                    begin
                        DecategorizeDocs();
                    end;
                }
                action(Navigate)
                {
                    ApplicationArea = Basic, Suite;
                    Image = Navigate;

                    trigger OnAction()
                    begin
                        NavigateDoc();
                    end;
                }
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    begin
        CODEUNIT.Run(CODEUNIT::"Document-Edit", Rec);
        exit(false);
    end;

    var
        Doc: Record "Cartera Doc.";
        CarteraManagement: Codeunit CarteraManagement;

    [Scope('OnPrem')]
    procedure CategorizeDocs()
    begin
        CurrPage.SetSelectionFilter(Doc);
        CarteraManagement.CategorizeDocs(Doc);
    end;

    [Scope('OnPrem')]
    procedure DecategorizeDocs()
    begin
        CurrPage.SetSelectionFilter(Doc);
        CarteraManagement.DecategorizeDocs(Doc);
    end;

    [Scope('OnPrem')]
    procedure AddPayableDocs(BGPONo: Code[20])
    var
        PaymentOrder: Record "Payment Order";
    begin
        Doc.Copy(Rec);
        if PaymentOrder.Get(BGPONo) then
            PaymentOrder.TestField("Elect. Pmts Exported", false);
        CarteraManagement.InsertPayableDocs(Doc);
    end;

    [Scope('OnPrem')]
    procedure RemoveDocs(BGPONo: Code[20])
    var
        PaymentOrder: Record "Payment Order";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRemoveDocs(Rec, BGPONo, Doc, CarteraManagement, IsHandled);
        if IsHandled then
            exit;

        Doc.Copy(Rec);
        CurrPage.SetSelectionFilter(Doc);
        if PaymentOrder.Get(BGPONo) then
            PaymentOrder.TestField("Elect. Pmts Exported", false);
        CarteraManagement.RemovePayableDocs(Doc);
    end;

    [Scope('OnPrem')]
    procedure NavigateDoc()
    begin
        CarteraManagement.NavigateDoc(Rec);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeRemoveDocs(var Rec: Record "Cartera Doc."; var BGPONo: Code[20]; var Doc: Record "Cartera Doc."; var CarteraManagement: Codeunit CarteraManagement; var IsHandled: Boolean)
    begin
    end;
}

