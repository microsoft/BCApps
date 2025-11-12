// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Utilities;

page 5850 "Posted Sales Document Lines"
{
    Caption = 'Posted Sales Document Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ListPlus;
    SaveValues = true;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(ShowRevLine; ShowRevLinesOnly)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Reversible Lines Only';
                    Enabled = ShowRevLineEnable;
                    ToolTip = 'Specifies if only lines with quantities that are available to be reversed are shown. For example, on a posted sales invoice with an original quantity of 20, and 15 of the items have already been returned, the quantity that is available to be reversed on the posted sales invoice is 5.';

                    trigger OnValidate()
                    begin
                        case CurrentMenuType of
                            0:
                                CurrPage.PostedShpts.PAGE.Initialize(
                                  ShowRevLinesOnly,
                                  CopyDocMgt.IsSalesFillExactCostRevLink(
                                    ToSalesHeader, CurrentMenuType, ToSalesHeader."Currency Code"), true);
                            1:
                                CurrPage.PostedInvoices.PAGE.Initialize(
                                  ToSalesHeader, ShowRevLinesOnly,
                                  CopyDocMgt.IsSalesFillExactCostRevLink(
                                    ToSalesHeader, CurrentMenuType, ToSalesHeader."Currency Code"), true);
                        end;
                        ShowRevLinesOnlyOnAfterValidat();
                    end;
                }
                field(OriginalQuantity; OriginalQuantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Return Original Quantity';
                    ToolTip = 'Specifies whether to use the original quantity to receive quantities associated with specific shipments. For example, on a posted sales invoice with an original quantity of 20, you can match the 20 items with a specific shipment.';
                }
            }
            group(Control19)
            {
                ShowCaption = false;
                group(Control9)
                {
                    ShowCaption = false;
                    field(PostedShipmentsBtn; CurrentMenuTypeOpt)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = OptionCaptionServiceTier();
                        OptionCaption = 'Posted Shipments,Posted Invoices,Posted Return Receipts,Posted Cr. Memos';

                        trigger OnValidate()
                        begin
                            if CurrentMenuTypeOpt = CurrentMenuTypeOpt::x3 then
                                x3CurrentMenuTypeOptOnValidate();
                            if CurrentMenuTypeOpt = CurrentMenuTypeOpt::x2 then
                                x2CurrentMenuTypeOptOnValidate();
                            if CurrentMenuTypeOpt = CurrentMenuTypeOpt::x1 then
                                x1CurrentMenuTypeOptOnValidate();
                            if CurrentMenuTypeOpt = CurrentMenuTypeOpt::x0 then
                                x0CurrentMenuTypeOptOnValidate();
                        end;
                    }
#pragma warning disable AA0100
                    field("STRSUBSTNO('(%1)',""No. of Pstd. Shipments"")"; StrSubstNo('(%1)', Rec."No. of Pstd. Shipments"))
#pragma warning restore AA0100
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '&Posted Shipments';
                        Editable = false;
                        ToolTip = 'Specifies the lines that represent posted shipments.';
                    }
                    field(NoOfPostedInvoices; StrSubstNo('(%1)', Rec."No. of Pstd. Invoices" - NoOfPostedPrepmtInvoices()))
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted I&nvoices';
                        Editable = false;
                        ToolTip = 'Specifies the lines that represent posted invoices.';
                    }
#pragma warning disable AA0100
                    field("STRSUBSTNO('(%1)',""No. of Pstd. Return Receipts"")"; StrSubstNo('(%1)', Rec."No. of Pstd. Return Receipts"))
#pragma warning restore AA0100
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Ret&urn Receipts';
                        Editable = false;
                        ToolTip = 'Specifies the lines that represent posted return receipts.';
                    }
                    field(NoOfPostedCrMemos; StrSubstNo('(%1)', Rec."No. of Pstd. Credit Memos" - NoOfPostedPrepmtCrMemos()))
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Cr. &Memos';
                        Editable = false;
                        ToolTip = 'Specifies the lines that represent posted sales credit memos.';
                    }
                    field(CurrentMenuTypeValue; CurrentMenuType)
                    {
                        ApplicationArea = Basic, Suite;
                        Visible = false;
                    }
                }
            }
            group(Control18)
            {
                ShowCaption = false;
                part(PostedInvoices; "Get Post.Doc - S.InvLn Subform")
                {
                    ApplicationArea = All;
                    SubPageLink = "Sell-to Customer No." = field("No.");
                    SubPageView = sorting("Sell-to Customer No.");
                    Visible = PostedInvoicesVisible;
                }
                part(PostedShpts; "Get Post.Doc - S.ShptLn Sbfrm")
                {
                    ApplicationArea = All;
                    SubPageLink = "Sell-to Customer No." = field("No.");
                    SubPageView = sorting("Sell-to Customer No.");
                    Visible = PostedShptsVisible;
                }
                part(PostedCrMemos; "Get Post.Doc-S.Cr.MemoLn Sbfrm")
                {
                    ApplicationArea = All;
                    SubPageLink = "Sell-to Customer No." = field("No.");
                    SubPageView = sorting("Sell-to Customer No.");
                    Visible = PostedCrMemosVisible;
                }
                part(PostedReturnRcpts; "Get Pst.Doc-RtrnRcptLn Subform")
                {
                    ApplicationArea = All;
                    SubPageLink = "Sell-to Customer No." = field("No.");
                    SubPageView = sorting("Sell-to Customer No.");
                    Visible = PostedReturnRcptsVisible;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields(
          "No. of Pstd. Shipments", "No. of Pstd. Invoices",
          "No. of Pstd. Return Receipts", "No. of Pstd. Credit Memos");
        CurrentMenuTypeOpt := CurrentMenuType;
    end;

    trigger OnInit()
    begin
        ShowRevLineEnable := true;
    end;

    trigger OnOpenPage()
    begin
        CurrentMenuType := 1;
        OnOpenPageOnAfterSetCurrentMenuType(Rec, CurrentMenuType);

        ChangeSubMenu(CurrentMenuType);
        Rec.SetRange("No.", Rec."No.");
    end;

    var
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        OldMenuType: Integer;
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
#pragma warning disable AA0074
        Text000: Label 'The document lines that have a G/L account that does not allow direct posting have not been copied to the new document.';
#pragma warning restore AA0074
        OriginalQuantity: Boolean;
#pragma warning disable AA0074
        Text002: Label 'Document Type Filter';
#pragma warning restore AA0074
        CurrentMenuTypeOpt: Option x0,x1,x2,x3;

    protected var
        ToSalesHeader: Record "Sales Header";
        PostedShptsVisible: Boolean;
        PostedInvoicesVisible: Boolean;
        PostedReturnRcptsVisible: Boolean;
        PostedCrMemosVisible: Boolean;
        ShowRevLineEnable: Boolean;
        ShowRevLinesOnly: Boolean;
        CurrentMenuType: Integer;

    procedure CopyLineToDoc()
    var
        FromSalesShptLine: Record "Sales Shipment Line";
        FromSalesInvLine: Record "Sales Invoice Line";
        FromSalesCrMemoLine: Record "Sales Cr.Memo Line";
        FromReturnRcptLine: Record "Return Receipt Line";
        IsHandled: Boolean;
    begin
        OnBeforeCopyLineToDoc(CopyDocMgt, CurrentMenuType);

        ToSalesHeader.TestField(Status, ToSalesHeader.Status::Open);
        LinesNotCopied := 0;

        case CurrentMenuType of
            0:
                begin
                    CurrPage.PostedShpts.PAGE.GetSelectedLine(FromSalesShptLine);
                    CopyDocMgt.SetProperties(false, false, false, false, true, true, OriginalQuantity);
                    CopyDocMgt.CopySalesLinesToDoc(
                      Enum::"Sales Document Type From"::"Posted Shipment".AsInteger(), ToSalesHeader,
                      FromSalesShptLine, FromSalesInvLine, FromReturnRcptLine, FromSalesCrMemoLine, LinesNotCopied, MissingExCostRevLink);
                end;
            1:
                begin
                    CurrPage.PostedInvoices.PAGE.GetSelectedLine(FromSalesInvLine);
                    CopyDocMgt.SetProperties(false, false, false, false, true, true, OriginalQuantity);
                    CopyDocMgt.CopySalesLinesToDoc(
                      Enum::"Sales Document Type From"::"Posted Invoice".AsInteger(), ToSalesHeader,
                      FromSalesShptLine, FromSalesInvLine, FromReturnRcptLine, FromSalesCrMemoLine, LinesNotCopied, MissingExCostRevLink);
                end;
            2:
                begin
                    CurrPage.PostedReturnRcpts.PAGE.GetSelectedLine(FromReturnRcptLine);
                    CopyDocMgt.SetProperties(false, false, false, false, true, true, OriginalQuantity);
                    CopyDocMgt.CopySalesLinesToDoc(
                      Enum::"Sales Document Type From"::"Posted Return Receipt".AsInteger(), ToSalesHeader,
                      FromSalesShptLine, FromSalesInvLine, FromReturnRcptLine, FromSalesCrMemoLine, LinesNotCopied, MissingExCostRevLink);
                end;
            3:
                begin
                    CurrPage.PostedCrMemos.PAGE.GetSelectedLine(FromSalesCrMemoLine);
                    CopyDocMgt.SetProperties(false, false, false, false, true, true, OriginalQuantity);
                    CopyDocMgt.CopySalesLinesToDoc(
                      Enum::"Sales Document Type From"::"Posted Credit Memo".AsInteger(), ToSalesHeader,
                      FromSalesShptLine, FromSalesInvLine, FromReturnRcptLine, FromSalesCrMemoLine, LinesNotCopied, MissingExCostRevLink);
                end;
        end;
        Clear(CopyDocMgt);

        IsHandled := false;
        OnCopyLineToDocOnBeforeMessage(ToSalesHeader, IsHandled);
        if not IsHandled then
            if LinesNotCopied <> 0 then
                Message(Text000);
    end;

    procedure ChangeSubMenu(NewMenuType: Integer)
    begin
        if OldMenuType <> NewMenuType then
            SetSubMenu(OldMenuType, false);
        SetSubMenu(NewMenuType, true);
        OldMenuType := NewMenuType;
        CurrentMenuType := NewMenuType;
    end;

    procedure GetCurrentMenuType(): Integer
    begin
        exit(CurrentMenuType);
    end;

    local procedure SetSubMenu(MenuType: Integer; Visible: Boolean)
    begin
        if ShowRevLinesOnly and (MenuType in [0, 1]) then
            ShowRevLinesOnly :=
              CopyDocMgt.IsSalesFillExactCostRevLink(ToSalesHeader, MenuType, ToSalesHeader."Currency Code");
        ShowRevLineEnable := MenuType in [0, 1];
        case MenuType of
            0:
                begin
                    PostedShptsVisible := Visible;
                    CurrPage.PostedShpts.PAGE.Initialize(
                      ShowRevLinesOnly,
                      CopyDocMgt.IsSalesFillExactCostRevLink(
                        ToSalesHeader, MenuType, ToSalesHeader."Currency Code"), Visible);
                end;
            1:
                begin
                    PostedInvoicesVisible := Visible;
                    CurrPage.PostedInvoices.PAGE.Initialize(
                      ToSalesHeader, ShowRevLinesOnly,
                      CopyDocMgt.IsSalesFillExactCostRevLink(
                        ToSalesHeader, MenuType, ToSalesHeader."Currency Code"), Visible);
                end;
            2:
                PostedReturnRcptsVisible := Visible;
            3:
                PostedCrMemosVisible := Visible;
        end;
    end;

    procedure SetToSalesHeader(NewToSalesHeader: Record "Sales Header")
    begin
        ToSalesHeader := NewToSalesHeader;
    end;

    local procedure OptionCaptionServiceTier(): Text[70]
    begin
        exit(Text002);
    end;

    local procedure ShowRevLinesOnlyOnAfterValidat()
    begin
        CurrPage.Update(true);
    end;

    local procedure x0CurrentMenuTypeOptOnPush()
    begin
        ChangeSubMenu(0);
    end;

    local procedure x0CurrentMenuTypeOptOnValidate()
    begin
        x0CurrentMenuTypeOptOnPush();
    end;

    local procedure x1CurrentMenuTypeOptOnPush()
    begin
        ChangeSubMenu(1);
    end;

    local procedure x1CurrentMenuTypeOptOnValidate()
    begin
        x1CurrentMenuTypeOptOnPush();
    end;

    local procedure x2CurrentMenuTypeOptOnPush()
    begin
        ChangeSubMenu(2);
    end;

    local procedure x2CurrentMenuTypeOptOnValidate()
    begin
        x2CurrentMenuTypeOptOnPush();
    end;

    local procedure x3CurrentMenuTypeOptOnPush()
    begin
        ChangeSubMenu(3);
    end;

    local procedure x3CurrentMenuTypeOptOnValidate()
    begin
        x3CurrentMenuTypeOptOnPush();
    end;

    local procedure NoOfPostedPrepmtInvoices(): Integer
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        SalesInvHeader.SetRange("Sell-to Customer No.", Rec."No.");
        SalesInvHeader.SetRange("Prepayment Invoice", true);
        exit(SalesInvHeader.Count);
    end;

    local procedure NoOfPostedPrepmtCrMemos(): Integer
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", Rec."No.");
        SalesCrMemoHeader.SetRange("Prepayment Credit Memo", true);
        exit(SalesCrMemoHeader.Count);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyLineToDoc(var CopyDocumentMgt: Codeunit "Copy Document Mgt."; CurrentMenuType: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyLineToDocOnBeforeMessage(ToSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnAfterSetCurrentMenuType(var Customer: Record Customer; var CurrentMenuType: Integer)
    begin
    end;
}

