// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Tracking;
using Microsoft.Utilities;
using System.Environment.Configuration;

page 139 "Posted Purch. Invoice Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Purch. Inv. Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Advanced;
                }
                field(FilteredTypeField; Rec.FormatType())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Type';
                    ToolTip = 'Specifies the type of transaction that was posted with the line.';
                    Visible = IsFoundation;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Item Reference No."; Rec."Item Reference No.")
                {
                    AccessByPermission = tabledata "Item Reference" = R;
                    ApplicationArea = Suite, ItemReferences;
                }
                field("IC Partner Code"; Rec."IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = false;
                }
                field("Return Reason Code"; Rec."Return Reason Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Indirect Cost %"; Rec."Indirect Cost %")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Unit Cost (LCY)"; Rec."Unit Cost (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Unit Price (LCY)"; Rec."Unit Price (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the price, in LCY, of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                }
                field("Matched Order Lines"; Rec."Matched Order Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Matched Order Lines';
                    ToolTip = 'Specifies the number of purchase order lines to which this posted purchase invoice line is matched.';

                    trigger OnDrillDown()
                    var
                        MatchedOrderLines: Page "Matched Order Lines";
                    begin
                        MatchedOrderLines.InitializePage("Matched Order Line Source"::"Posted Purchase Invoice", false, Rec.SystemId);
                        MatchedOrderLines.RunModal();
                    end;
                }
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = VAT;
                    Visible = false;
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = SalesTax;
                    Visible = false;
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                    Visible = false;
                }
                field("Tax Group Code"; Rec."Tax Group Code")
                {
                    ApplicationArea = SalesTax;
                }
                field("Use Tax"; Rec."Use Tax")
                {
                    ApplicationArea = SalesTax;
                    Visible = false;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the invoice line could have been included in an invoice discount calculation.';
                    Visible = false;
                }
                field(NonDeductibleVATBase; Rec."Non-Deductible VAT Base")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = ShowNonDedVATInLines;
                }
                field(NonDeductibleVATAmount; Rec."Non-Deductible VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = ShowNonDedVATInLines;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Insurance No."; Rec."Insurance No.")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Budgeted FA No."; Rec."Budgeted FA No.")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("FA Posting Type"; Rec."FA Posting Type")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Depr. until FA Posting Date"; Rec."Depr. until FA Posting Date")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Depreciation Book Code"; Rec."Depreciation Book Code")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Depr. Acquisition Cost"; Rec."Depr. Acquisition Cost")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Appl.-to Item Entry"; Rec."Appl.-to Item Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Deferral Code"; Rec."Deferral Code")
                {
                    ApplicationArea = Suite;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = DimVisible1;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = DimVisible2;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible3;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible4;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible5;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible6;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible7;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible8;
                }
                field("Gross Weight"; Rec."Gross Weight")
                {
                    Caption = 'Unit Gross Weight';
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Net Weight"; Rec."Net Weight")
                {
                    Caption = 'Unit Net Weight';
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Unit Volume"; Rec."Unit Volume")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Units per Parcel"; Rec."Units per Parcel")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
            }
            group(Control31)
            {
                ShowCaption = false;
                group(Control25)
                {
                    ShowCaption = false;
                    field("Invoice Discount Amount"; TotalPurchInvHeader."Invoice Discount Amount")
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = TotalPurchInvHeader."Currency Code";
                        AutoFormatType = 1;
                        CaptionClass = DocumentTotals.GetInvoiceDiscAmountWithVATCaption(TotalPurchInvHeader."Prices Including VAT");
                        Caption = 'Invoice Discount Amount';
                        Editable = false;
                        ToolTip = 'Specifies a discount amount that is deducted from the value of the Total Incl. VAT field, based on purchase lines where the Allow Invoice Disc. field is selected.';
                    }
                }
                group(Control7)
                {
                    ShowCaption = false;
                    field("Total Amount Excl. VAT"; TotalPurchInvHeader.Amount)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = TotalPurchInvHeader."Currency Code";
                        AutoFormatType = 1;
                        CaptionClass = DocumentTotals.GetTotalExclVATCaption(TotalPurchInvHeader."Currency Code");
                        Caption = 'Total Amount Excl. VAT';
                        DrillDown = false;
                        Editable = false;
                        ToolTip = 'Specifies the sum of the value in the Line Amount Excl. VAT field on all lines in the document minus any discount amount in the Invoice Discount Amount field.';
                    }
                    field("Total VAT Amount"; VATAmount)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = TotalPurchInvHeader."Currency Code";
                        AutoFormatType = 1;
                        CaptionClass = DocumentTotals.GetTotalVATCaption(TotalPurchInvHeader."Currency Code");
                        Caption = 'Total VAT';
                        Editable = false;
                        ToolTip = 'Specifies the sum of VAT amounts on all lines in the document.';
                    }
                    field("Total Amount Incl. VAT"; TotalPurchInvHeader."Amount Including VAT")
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = TotalPurchInvHeader."Currency Code";
                        AutoFormatType = 1;
                        CaptionClass = DocumentTotals.GetTotalInclVATCaption(TotalPurchInvHeader."Currency Code");
                        Caption = 'Total Amount Incl. VAT';
                        Editable = false;
                        Style = Strong;
                        StyleExpr = true;
                        ToolTip = 'Specifies the sum of the value in the Line Amount Incl. VAT field on all lines in the document minus any discount amount in the Invoice Discount Amount field.';
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
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
                action(Comments)
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';

                    trigger OnAction()
                    begin
                        Rec.ShowLineComments();
                    end;
                }
                action(ItemTrackingEntries)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Entries';
                    Image = ItemTrackingLedger;
                    ToolTip = 'View serial, lot or package numbers that are assigned to items.';

                    trigger OnAction()
                    begin
                        Rec.ShowItemTrackingLines();
                    end;
                }
                action(ItemReceiptLines)
                {
                    AccessByPermission = TableData "Purch. Rcpt. Header" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Receipt &Lines';
                    Image = ReceiptLines;
                    ToolTip = 'View posted receipts for the item.';

                    trigger OnAction()
                    begin
                        if not (Rec.Type in [Rec.Type::Item, Rec.Type::"Charge (Item)"]) then
                            Rec.TestField(Type);
                        Rec.ShowItemReceiptLines();
                    end;
                }
                action(DocumentLineTracking)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document &Line Tracking';
                    Image = Navigate;
                    ToolTip = 'View related open, posted, or archived documents or document lines.';

                    trigger OnAction()
                    begin
                        ShowDocumentLineTracking();
                    end;
                }
                action(DeferralSchedule)
                {
                    ApplicationArea = Suite;
                    Caption = 'Deferral Schedule';
                    Image = PaymentPeriod;
                    ToolTip = 'View the deferral schedule that governs how expenses paid with this purchase document were deferred to different accounting periods when the document was posted.';

                    trigger OnAction()
                    begin
                        Rec.ShowDeferrals();
                    end;
                }
                action(DocAttach)
                {
                    ApplicationArea = All;
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
                action(MatchedOrdLines)
                {
                    ApplicationArea = All;
                    Caption = 'Matched Order Lines';
                    Image = TransferToLines;
                    ToolTip = 'View order lines related to this posted purchase invoice line.';

                    trigger OnAction()
                    var
                        MatchedOrderLines: Page "Matched Order Lines";
                    begin
                        MatchedOrderLines.InitializePage("Matched Order Line Source"::"Posted Purchase Invoice", false, Rec.SystemId);
                        MatchedOrderLines.RunModal();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        DocumentTotals.CalculatePostedPurchInvoiceTotals(TotalPurchInvHeader, VATAmount, Rec);
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnInit()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        IsFoundation := ApplicationAreaMgmtFacade.IsFoundationEnabled();
    end;

    trigger OnOpenPage()
    var
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
    begin
        SetDimensionsVisibility();
        ShowNonDedVATInLines := NonDeductibleVAT.ShowNonDeductibleVATInLines();
    end;

    var
        DocumentTotals: Codeunit "Document Totals";
        IsFoundation: Boolean;
        VATAmount: Decimal;

    protected var
        TotalPurchInvHeader: Record "Purch. Inv. Header";
        ShortcutDimCode: array[8] of Code[20];
        DimVisible1: Boolean;
        DimVisible2: Boolean;
        DimVisible3: Boolean;
        DimVisible4: Boolean;
        DimVisible5: Boolean;
        DimVisible6: Boolean;
        DimVisible7: Boolean;
        DimVisible8: Boolean;
        ShowNonDedVATInLines: Boolean;

    procedure ShowDocumentLineTracking()
    var
        DocumentLineTrackingPage: Page "Document Line Tracking";
    begin
        Clear(DocumentLineTrackingPage);
        DocumentLineTrackingPage.SetSourceDoc(
            "Document Line Source Type"::"Purchase Invoice", Rec."Document No.", Rec."Line No.", Rec."Blanket Order No.", Rec."Blanket Order Line No.", Rec."Order No.", Rec."Order Line No.");
        DocumentLineTrackingPage.RunModal();
    end;

    local procedure SetDimensionsVisibility()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimVisible1 := false;
        DimVisible2 := false;
        DimVisible3 := false;
        DimVisible4 := false;
        DimVisible5 := false;
        DimVisible6 := false;
        DimVisible7 := false;
        DimVisible8 := false;

        DimMgt.UseShortcutDims(
          DimVisible1, DimVisible2, DimVisible3, DimVisible4, DimVisible5, DimVisible6, DimVisible7, DimVisible8);

        Clear(DimMgt);

        OnAfterSetDimensionsVisibility();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSetDimensionsVisibility()
    begin
    end;
}

