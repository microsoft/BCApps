// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;

page 5855 "Posted Purchase Document Lines"
{
    Caption = 'Posted Purchase Document Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ListPlus;
    SaveValues = true;
    SourceTable = Vendor;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(ShowRevLine; ShowRevLinesOnly)
                {
                    ApplicationArea = Suite;
                    Caption = 'Show Reversible Lines Only';
                    Enabled = ShowRevLineEnable;
                    ToolTip = 'Specifies if only lines with quantities that are available to be reversed are shown. For example, on a posted purchase invoice with an original quantity of 20, and 15 of the items have already been sold, the quantity that is available to be reversed on the posted purchase invoice is 5.';

                    trigger OnValidate()
                    begin
                        case CurrentMenuType of
                            0:
                                CurrPage.PostedRcpts.PAGE.Initialize(
                                  ShowRevLinesOnly,
                                  CopyDocMgt.IsPurchFillExactCostRevLink(
                                    ToPurchHeader, CurrentMenuType, ToPurchHeader."Currency Code"), true);
                            1:
                                CurrPage.PostedInvoices.PAGE.Initialize(
                                  ToPurchHeader, ShowRevLinesOnly,
                                  CopyDocMgt.IsPurchFillExactCostRevLink(
                                    ToPurchHeader, CurrentMenuType, ToPurchHeader."Currency Code"), true);
                        end;
                        CurrPage.Update(true);
                    end;
                }
                field(OriginalQuantity; OriginalQuantity)
                {
                    ApplicationArea = Suite;
                    Caption = 'Return Original Quantity';
                    ToolTip = 'Specifies whether to use the original quantity to return quantities associated with specific receipts. For example, on a posted purchase invoice with an original quantity of 20, you can match this quantity with a specific shipment received even if some of the 20 items have been sold.';
                }
            }
            group(Control19)
            {
                ShowCaption = false;
                group(Control9)
                {
                    ShowCaption = false;
                    field(PostedReceiptsBtn; CurrentMenuTypeOpt)
                    {
                        ApplicationArea = Suite;
                        CaptionClass = OptionCaptionServiceTier();
                        OptionCaption = 'Posted Receipts,Posted Invoices,Posted Return Shipments,Posted Cr. Memos';

                        trigger OnValidate()
                        begin
                            if CurrentMenuTypeOpt = CurrentMenuTypeOpt::x3 then
                                ChangeSubMenu(3);
                            if CurrentMenuTypeOpt = CurrentMenuTypeOpt::x2 then
                                ChangeSubMenu(2);
                            if CurrentMenuTypeOpt = CurrentMenuTypeOpt::x1 then
                                ChangeSubMenu(1);
                            if CurrentMenuTypeOpt = CurrentMenuTypeOpt::x0 then
                                ChangeSubMenu(0);
                        end;
                    }
#pragma warning disable AA0100
                    field("STRSUBSTNO('(%1)',""No. of Pstd. Receipts"")"; StrSubstNo('(%1)', Rec."No. of Pstd. Receipts"))
#pragma warning restore AA0100
                    {
                        ApplicationArea = Suite;
                        Caption = '&Posted Receipts';
                        Editable = false;
                        ToolTip = 'Specifies the lines that represent posted receipts.';
                    }
                    field(NoOfPostedInvoices; StrSubstNo('(%1)', Rec."No. of Pstd. Invoices" - NoOfPostedPrepmtInvoices()))
                    {
                        ApplicationArea = Suite;
                        Caption = 'Posted I&nvoices';
                        Editable = false;
                        ToolTip = 'Specifies the lines that represent posted invoices.';
                    }
#pragma warning disable AA0100
                    field("STRSUBSTNO('(%1)',""No. of Pstd. Return Shipments"")"; StrSubstNo('(%1)', Rec."No. of Pstd. Return Shipments"))
#pragma warning restore AA0100
                    {
                        ApplicationArea = Suite;
                        Caption = 'Posted Ret&urn Shipments';
                        Editable = false;
                        ToolTip = 'Specifies the lines that represent posted return shipments.';
                    }
                    field(NoOfPostedCrMemos; StrSubstNo('(%1)', Rec."No. of Pstd. Credit Memos" - NoOfPostedPrepmtCrMemos()))
                    {
                        ApplicationArea = Suite;
                        Caption = 'Posted Cr. &Memos';
                        Editable = false;
                        ToolTip = 'Specifies the lines that represent posted purchase credit memos.';
                    }
                    field(CurrentMenuTypeValue; CurrentMenuType)
                    {
                        ApplicationArea = SalesReturnOrder;
                        Visible = false;
                    }
                }
            }
            group(Control18)
            {
                ShowCaption = false;
                part(PostedInvoices; "Get Post.Doc - P.InvLn Subform")
                {
                    ApplicationArea = All;
                    SubPageLink = "Buy-from Vendor No." = field("No.");
                    SubPageView = sorting("Buy-from Vendor No.");
                    Visible = PostedInvoicesVisible;
                }
                part(PostedRcpts; "Get Post.Doc - P.RcptLn Sbfrm")
                {
                    ApplicationArea = All;
                    SubPageLink = "Buy-from Vendor No." = field("No.");
                    SubPageView = sorting("Buy-from Vendor No.");
                    Visible = PostedRcptsVisible;
                }
                part(PostedCrMemos; "Get Post.Doc-P.Cr.MemoLn Sbfrm")
                {
                    ApplicationArea = All;
                    SubPageLink = "Buy-from Vendor No." = field("No.");
                    SubPageView = sorting("Buy-from Vendor No.");
                    Visible = PostedCrMemosVisible;
                }
                part(PostedReturnShpts; "Get Pst.Doc-RtrnShptLn Subform")
                {
                    ApplicationArea = All;
                    SubPageLink = "Buy-from Vendor No." = field("No.");
                    SubPageView = sorting("Buy-from Vendor No.");
                    Visible = PostedReturnShptsVisible;
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
          "No. of Pstd. Receipts", "No. of Pstd. Invoices",
          "No. of Pstd. Return Shipments", "No. of Pstd. Credit Memos");
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

        OriginalQuantity := false;
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
        PostedRcptsVisible: Boolean;
        PostedInvoicesVisible: Boolean;
        PostedReturnShptsVisible: Boolean;
        PostedCrMemosVisible: Boolean;
        CurrentMenuTypeOpt: Option x0,x1,x2,x3;

    protected var
        ToPurchHeader: Record "Purchase Header";
        ShowRevLineEnable: Boolean;
        ShowRevLinesOnly: Boolean;
        CurrentMenuType: Integer;

    [Scope('OnPrem')]
    procedure CopyLineToDoc()
    var
        FromPurchRcptLine: Record "Purch. Rcpt. Line";
        FromPurchInvLine: Record "Purch. Inv. Line";
        FromPurchCrMemoLine: Record "Purch. Cr. Memo Line";
        FromReturnShptLine: Record "Return Shipment Line";
    begin
        OnBeforeCopyLineToDoc(CopyDocMgt, CurrentMenuType);
        ToPurchHeader.TestField(Status, ToPurchHeader.Status::Open);
        LinesNotCopied := 0;
        case CurrentMenuType of
            0:
                begin
                    CurrPage.PostedRcpts.PAGE.GetSelectedLine(FromPurchRcptLine);
                    CopyDocMgt.SetProperties(false, false, false, false, true, true, OriginalQuantity);
                    CopyDocMgt.CopyPurchaseLinesToDoc(
                      Enum::"Purchase Document Type From"::"Posted Receipt".AsInteger(), ToPurchHeader,
                      FromPurchRcptLine, FromPurchInvLine, FromReturnShptLine, FromPurchCrMemoLine, LinesNotCopied, MissingExCostRevLink);
                end;
            1:
                begin
                    CurrPage.PostedInvoices.PAGE.GetSelectedLine(FromPurchInvLine);
                    CopyDocMgt.SetProperties(false, false, false, false, true, true, OriginalQuantity);
                    CopyDocMgt.CopyPurchaseLinesToDoc(
                      Enum::"Purchase Document Type From"::"Posted Invoice".AsInteger(), ToPurchHeader,
                      FromPurchRcptLine, FromPurchInvLine, FromReturnShptLine, FromPurchCrMemoLine, LinesNotCopied, MissingExCostRevLink);
                end;
            2:
                begin
                    CurrPage.PostedReturnShpts.PAGE.GetSelectedLine(FromReturnShptLine);
                    CopyDocMgt.SetProperties(false, false, false, false, true, true, OriginalQuantity);
                    CopyDocMgt.CopyPurchaseLinesToDoc(
                      Enum::"Purchase Document Type From"::"Posted Return Shipment".AsInteger(), ToPurchHeader,
                      FromPurchRcptLine, FromPurchInvLine, FromReturnShptLine, FromPurchCrMemoLine, LinesNotCopied, MissingExCostRevLink);
                end;
            3:
                begin
                    CurrPage.PostedCrMemos.PAGE.GetSelectedLine(FromPurchCrMemoLine);
                    CopyDocMgt.SetProperties(false, false, false, false, true, true, OriginalQuantity);
                    CopyDocMgt.CopyPurchaseLinesToDoc(
                      Enum::"Purchase Document Type From"::"Posted Credit Memo".AsInteger(), ToPurchHeader,
                      FromPurchRcptLine, FromPurchInvLine, FromReturnShptLine, FromPurchCrMemoLine, LinesNotCopied, MissingExCostRevLink);
                end;
        end;
        CopyDocMgt.ShowMessageReapply(OriginalQuantity);
        Clear(CopyDocMgt);

        OnAfterCopyLineToDoc(ToPurchHeader);

        ShowLinesNotCopiedMessage();
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
              CopyDocMgt.IsPurchFillExactCostRevLink(ToPurchHeader, MenuType, ToPurchHeader."Currency Code");
        ShowRevLineEnable := MenuType in [0, 1];
        case MenuType of
            0:
                begin
                    PostedRcptsVisible := Visible;
                    CurrPage.PostedRcpts.PAGE.Initialize(
                      ShowRevLinesOnly,
                      CopyDocMgt.IsPurchFillExactCostRevLink(
                        ToPurchHeader, MenuType, ToPurchHeader."Currency Code"), Visible);
                end;
            1:
                begin
                    PostedInvoicesVisible := Visible;
                    CurrPage.PostedInvoices.PAGE.Initialize(
                      ToPurchHeader, ShowRevLinesOnly,
                      CopyDocMgt.IsPurchFillExactCostRevLink(
                        ToPurchHeader, MenuType, ToPurchHeader."Currency Code"), Visible);
                end;
            2:
                PostedReturnShptsVisible := Visible;
            3:
                PostedCrMemosVisible := Visible;
        end;
    end;

    procedure SetToPurchHeader(NewToPurchHeader: Record "Purchase Header")
    begin
        ToPurchHeader := NewToPurchHeader;
    end;

    local procedure OptionCaptionServiceTier(): Text[70]
    begin
        exit(Text002);
    end;

    local procedure NoOfPostedPrepmtInvoices(): Integer
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", Rec."No.");
        PurchInvHeader.SetRange("Prepayment Invoice", true);
        exit(PurchInvHeader.Count);
    end;

    local procedure NoOfPostedPrepmtCrMemos(): Integer
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", Rec."No.");
        PurchCrMemoHdr.SetRange("Prepayment Credit Memo", true);
        exit(PurchCrMemoHdr.Count);
    end;

    local procedure ShowLinesNotCopiedMessage()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowLinesNotCopiedMessage(IsHandled);
        if not IsHandled then
            if LinesNotCopied <> 0 then
                Message(Text000);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyLineToDoc(var CopyDocumentMgt: Codeunit "Copy Document Mgt."; CurrentMenuType: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyLineToDoc(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowLinesNotCopiedMessage(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnAfterSetCurrentMenuType(var Vendor: Record Vendor; var CurrentMenuType: Integer)
    begin
    end;
}

