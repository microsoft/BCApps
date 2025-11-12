// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Outbox;

using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.Setup;

xmlport 12 "IC Outbox Imp/Exp"
{
    Caption = 'IC Outbox Imp/Exp';
    FormatEvaluate = Xml;

    schema
    {
        textelement(ICTransactions)
        {
            tableelement(icoutboxtrans; "IC Outbox Transaction")
            {
                XmlName = 'ICOutboxTrans';
                UseTemporary = true;
                fieldattribute(TransNo; ICOutboxTrans."Transaction No.")
                {
                }
                fieldattribute(ToICPartnerCode; ICOutboxTrans."IC Partner Code")
                {

                    trigger OnAfterAssignField()
                    begin
                        ToICPartnerCode2 := ICOutboxTrans."IC Partner Code";
                    end;
                }
                textattribute(FromICPartnerCode)
                {

                    trigger OnBeforePassVariable()
                    begin
                        FromICPartnerCode := ICSetup."IC Partner Code";
                    end;
                }
                fieldattribute(SourceType; ICOutboxTrans."IC Source Type")
                {
                }
                fieldattribute(DocType; ICOutboxTrans."Document Type")
                {
                }
                fieldattribute(DocNo; ICOutboxTrans."Document No.")
                {
                }
                fieldattribute(PostingDate; ICOutboxTrans."Posting Date")
                {
                }
                fieldattribute(TransSource; ICOutboxTrans."Transaction Source")
                {
                }
                fieldattribute(DocDate; ICOutboxTrans."Document Date")
                {
                }
                fieldattribute(TransICAccountType; ICOutboxTrans."IC Account Type")
                {
                }
                fieldattribute(TransICAccountNo; ICOutboxTrans."IC Account No.")
                {
                }
                textelement(ICOutBoxJnlLines)
                {
                    MinOccurs = Zero;
                    tableelement(icoutboxjnlline; "IC Outbox Jnl. Line")
                    {
                        LinkFields = "Transaction No." = field("Transaction No.");
                        LinkTable = ICOutboxTrans;
                        MinOccurs = Zero;
                        XmlName = 'ICOutBoxJnlLine';
                        UseTemporary = true;
                        fieldattribute(LineNo; ICOutBoxJnlLine."Line No.")
                        {
                        }
                        fieldattribute(AccType; ICOutBoxJnlLine."Account Type")
                        {
                        }
                        fieldattribute(AccNo; ICOutBoxJnlLine."Account No.")
                        {
                        }
                        fieldattribute(Amount; ICOutBoxJnlLine.Amount)
                        {
                        }
                        fieldattribute(Description; ICOutBoxJnlLine.Description)
                        {
                        }
                        fieldattribute(VATAmount; ICOutBoxJnlLine."VAT Amount")
                        {
                        }
                        fieldattribute(CurrencyCode; ICOutBoxJnlLine."Currency Code")
                        {
                        }
                        fieldattribute(DueDate; ICOutBoxJnlLine."Due Date")
                        {
                        }
                        fieldattribute(PmtDiscPct; ICOutBoxJnlLine."Payment Discount %")
                        {
                        }
                        fieldattribute(PmtDiscDate; ICOutBoxJnlLine."Payment Discount Date")
                        {
                        }
                        fieldattribute(Quantity; ICOutBoxJnlLine.Quantity)
                        {
                        }
                        fieldattribute(TransSource; ICOutBoxJnlLine."Transaction Source")
                        {
                        }
                        fieldattribute(ICPartnerCode; ICOutBoxJnlLine."IC Partner Code")
                        {
                        }
                        fieldattribute(ICTransNo; ICOutBoxJnlLine."Transaction No.")
                        {
                        }
                        fieldattribute(DocumentNo; ICOutBoxJnlLine."Document No.")
                        {
                        }
                        textelement(ICIOBoxJnlDims)
                        {
                            tableelement(icioboxjnldim; "IC Inbox/Outbox Jnl. Line Dim.")
                            {
                                LinkFields = "IC Partner Code" = field("IC Partner Code"), "Transaction No." = field("Transaction No."), "Transaction Source" = field("Transaction Source"), "Line No." = field("Line No.");
                                LinkTable = ICOutBoxJnlLine;
                                MinOccurs = Zero;
                                XmlName = 'ICIOBoxJnlDim';
                                SourceTableView = where("Table ID" = const(415));
                                UseTemporary = true;
                                fieldattribute(TableID; ICIOBoxJnlDim."Table ID")
                                {
                                }
                                fieldattribute(TransSource; ICIOBoxJnlDim."Transaction Source")
                                {
                                }
                                fieldattribute(ICPartnerCode; ICIOBoxJnlDim."IC Partner Code")
                                {
                                }
                                fieldattribute(ICTransNo; ICIOBoxJnlDim."Transaction No.")
                                {
                                }
                                fieldattribute(LineNo; ICIOBoxJnlDim."Line No.")
                                {
                                }
                                fieldattribute(DimCode; ICIOBoxJnlDim."Dimension Code")
                                {
                                }
                                fieldattribute(DimValCode; ICIOBoxJnlDim."Dimension Value Code")
                                {
                                }
                            }
                        }
                    }
                }
                textelement(ICOutBoxSalesHeaders)
                {
                    MinOccurs = Zero;
                    tableelement(icoutboxsaleshdr; "IC Outbox Sales Header")
                    {
                        LinkFields = "IC Transaction No." = field("Transaction No."), "IC Partner Code" = field("IC Partner Code"), "Transaction Source" = field("Transaction Source");
                        LinkTable = ICOutboxTrans;
                        MinOccurs = Zero;
                        XmlName = 'ICOutBoxSalesHdr';
                        UseTemporary = true;
                        fieldattribute(DocType; ICOutBoxSalesHdr."Document Type")
                        {
                        }
                        fieldattribute(SellToCustNo; ICOutBoxSalesHdr."Sell-to Customer No.")
                        {
                        }
                        fieldattribute(DocNo; ICOutBoxSalesHdr."No.")
                        {
                        }
                        fieldattribute(BillToCustNo; ICOutBoxSalesHdr."Bill-to Customer No.")
                        {
                        }
                        fieldattribute(ShipToName; ICOutBoxSalesHdr."Ship-to Name")
                        {
                        }
                        fieldattribute(ShipToAddress; ICOutBoxSalesHdr."Ship-to Address")
                        {
                        }
                        fieldattribute(ShipToCity; ICOutBoxSalesHdr."Ship-to City")
                        {
                        }
                        fieldattribute(PostingDate; ICOutBoxSalesHdr."Posting Date")
                        {
                        }
                        fieldattribute(DueDate; ICOutBoxSalesHdr."Due Date")
                        {
                        }
                        fieldattribute(PmtDiscPct; ICOutBoxSalesHdr."Payment Discount %")
                        {
                        }
                        fieldattribute(PmtDiscDate; ICOutBoxSalesHdr."Pmt. Discount Date")
                        {
                        }
                        fieldattribute(CurrencyCode; ICOutBoxSalesHdr."Currency Code")
                        {
                        }
                        fieldattribute(PricesInclVAT; ICOutBoxSalesHdr."Prices Including VAT")
                        {
                        }
                        fieldattribute(DocDate; ICOutBoxSalesHdr."Document Date")
                        {
                        }
                        fieldattribute(ExtDocNo; ICOutBoxSalesHdr."External Document No.")
                        {
                        }
                        fieldattribute(ICPartnerCode; ICOutBoxSalesHdr."IC Partner Code")
                        {
                        }
                        fieldattribute(ICTransNo; ICOutBoxSalesHdr."IC Transaction No.")
                        {
                        }
                        fieldattribute(TransSource; ICOutBoxSalesHdr."Transaction Source")
                        {
                        }
                        fieldattribute(ReqDelivDate; ICOutBoxSalesHdr."Requested Delivery Date")
                        {
                        }
                        fieldattribute(PromDelivDate; ICOutBoxSalesHdr."Promised Delivery Date")
                        {
                        }
                        fieldattribute(OrderNo; ICOutBoxSalesHdr."Order No.")
                        {
                        }
                        textelement(ICDocDimensions)
                        {
                            tableelement(icsalesdocdim; "IC Document Dimension")
                            {
                                LinkFields = "Transaction No." = field("IC Transaction No."), "IC Partner Code" = field("IC Partner Code"), "Transaction Source" = field("Transaction Source");
                                LinkTable = ICOutBoxSalesHdr;
                                MinOccurs = Zero;
                                XmlName = 'ICSalesDocDim';
                                SourceTableView = where("Table ID" = const(426), "Line No." = const(0));
                                UseTemporary = true;
                                fieldattribute(TableID; ICSalesDocDim."Table ID")
                                {
                                }
                                fieldattribute(TransNo; ICSalesDocDim."Transaction No.")
                                {
                                }
                                fieldattribute(ICPartnerCode; ICSalesDocDim."IC Partner Code")
                                {
                                }
                                fieldattribute(TransSource; ICSalesDocDim."Transaction Source")
                                {
                                }
                                fieldattribute(LineNo; ICSalesDocDim."Line No.")
                                {
                                }
                                fieldattribute(DimCode; ICSalesDocDim."Dimension Code")
                                {
                                }
                                fieldattribute(DimValCode; ICSalesDocDim."Dimension Value Code")
                                {
                                }
                            }
                        }
                        textelement(ICOutBoxSalesLines)
                        {
                            tableelement(icoutboxsalesline; "IC Outbox Sales Line")
                            {
                                LinkFields = "Document No." = field("No."), "IC Transaction No." = field("IC Transaction No."), "IC Partner Code" = field("IC Partner Code"), "Transaction Source" = field("Transaction Source");
                                LinkTable = ICOutBoxSalesHdr;
                                MinOccurs = Zero;
                                XmlName = 'ICOutBoxSalesLine';
                                UseTemporary = true;
                                fieldattribute(DocType; ICOutBoxSalesLine."Document Type")
                                {
                                }
                                fieldattribute(DocNo; ICOutBoxSalesLine."Document No.")
                                {
                                }
                                fieldattribute(LineNo; ICOutBoxSalesLine."Line No.")
                                {
                                }
                                fieldattribute(Description; ICOutBoxSalesLine.Description)
                                {
                                }
                                fieldattribute(Quantity; ICOutBoxSalesLine.Quantity)
                                {
                                }
                                fieldattribute(UnitPrice; ICOutBoxSalesLine."Unit Price")
                                {
                                }
                                fieldattribute(LineDiscAmount; ICOutBoxSalesLine."Line Discount Amount")
                                {
                                }
                                fieldattribute(AmountInclVAT; ICOutBoxSalesLine."Amount Including VAT")
                                {
                                }
                                fieldattribute(JobNo; ICOutBoxSalesLine."Job No.")
                                {
                                }
                                fieldattribute(DropShipment; ICOutBoxSalesLine."Drop Shipment")
                                {
                                }
                                fieldattribute(CurrencyCode; ICOutBoxSalesLine."Currency Code")
                                {
                                }
                                fieldattribute(VATBaseAmount; ICOutBoxSalesLine."VAT Base Amount")
                                {
                                }
                                fieldattribute(LineAmount; ICOutBoxSalesLine."Line Amount")
                                {
                                }
                                fieldattribute(ICPartnerRefType; ICOutBoxSalesLine."IC Partner Ref. Type")
                                {
                                }
                                fieldattribute(ICPartnerRef; ICOutBoxSalesLine."IC Partner Reference")
                                {
                                }
                                fieldattribute(ICItemRefNo; ICOutBoxSalesLine."IC Item Reference No.")
                                {
                                }
                                fieldattribute(TransSource; ICOutBoxSalesLine."Transaction Source")
                                {
                                }
                                fieldattribute(UnitOfMeasureCode; ICOutBoxSalesLine."Unit of Measure Code")
                                {
                                }
                                fieldattribute(TransNo; ICOutBoxSalesLine."IC Transaction No.")
                                {
                                }
                                fieldattribute(ReqDelivDate; ICOutBoxSalesLine."Requested Delivery Date")
                                {
                                }
                                fieldattribute(PromDelivDate; ICOutBoxSalesLine."Promised Delivery Date")
                                {
                                }
                                fieldattribute(ShipmentNo; ICOutBoxSalesLine."Shipment No.")
                                {
                                }
                                fieldattribute(ShipmentLineNo; ICOutBoxSalesLine."Shipment Line No.")
                                {
                                }
                                textelement(LineDimensions)
                                {
                                    tableelement(icsalesdoclinedim; "IC Document Dimension")
                                    {
                                        LinkFields = "Transaction No." = field("IC Transaction No."), "IC Partner Code" = field("IC Partner Code"), "Transaction Source" = field("Transaction Source"), "Line No." = field("Line No.");
                                        LinkTable = ICOutBoxSalesLine;
                                        MinOccurs = Zero;
                                        XmlName = 'ICSalesDocLineDim';
                                        SourceTableView = where("Table ID" = const(427));
                                        UseTemporary = true;
                                        fieldattribute(TableID; ICSalesDocLineDim."Table ID")
                                        {
                                        }
                                        fieldattribute(TransNo; ICSalesDocLineDim."Transaction No.")
                                        {
                                        }
                                        fieldattribute(ICPartnerCode; ICSalesDocLineDim."IC Partner Code")
                                        {
                                        }
                                        fieldattribute(TransSource; ICSalesDocLineDim."Transaction Source")
                                        {
                                        }
                                        fieldattribute(LineNo; ICSalesDocLineDim."Line No.")
                                        {
                                        }
                                        fieldattribute(DimCode; ICSalesDocLineDim."Dimension Code")
                                        {
                                        }
                                        fieldattribute(DimValCode; ICSalesDocLineDim."Dimension Value Code")
                                        {
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                textelement(ICOutBoxPurchHeaders)
                {
                    MinOccurs = Zero;
                    tableelement(icoutboxpurchhdr; "IC Outbox Purchase Header")
                    {
                        LinkFields = "IC Transaction No." = field("Transaction No."), "IC Partner Code" = field("IC Partner Code"), "Transaction Source" = field("Transaction Source");
                        LinkTable = ICOutboxTrans;
                        MinOccurs = Zero;
                        XmlName = 'ICOutBoxPurchHdr';
                        UseTemporary = true;
                        fieldattribute(DocType; ICOutBoxPurchHdr."Document Type")
                        {
                        }
                        fieldattribute(BuyFromVendNo; ICOutBoxPurchHdr."Buy-from Vendor No.")
                        {
                        }
                        fieldattribute(DocNo; ICOutBoxPurchHdr."No.")
                        {
                        }
                        fieldattribute(PayToVendNo; ICOutBoxPurchHdr."Pay-to Vendor No.")
                        {
                        }
                        fieldattribute(YourRef; ICOutBoxPurchHdr."Your Reference")
                        {
                        }
                        fieldattribute(ShipToName; ICOutBoxPurchHdr."Ship-to Name")
                        {
                        }
                        fieldattribute(ShipToAddress; ICOutBoxPurchHdr."Ship-to Address")
                        {
                        }
                        fieldattribute(ShipToCity; ICOutBoxPurchHdr."Ship-to City")
                        {
                        }
                        fieldattribute(PostingDate; ICOutBoxPurchHdr."Posting Date")
                        {
                        }
                        fieldattribute(ExpRecDate; ICOutBoxPurchHdr."Expected Receipt Date")
                        {
                        }
                        fieldattribute(DueDate; ICOutBoxPurchHdr."Due Date")
                        {
                        }
                        fieldattribute(PmtDiscPct; ICOutBoxPurchHdr."Payment Discount %")
                        {
                        }
                        fieldattribute(PmtDiscDate; ICOutBoxPurchHdr."Pmt. Discount Date")
                        {
                        }
                        fieldattribute(CurrencyCode; ICOutBoxPurchHdr."Currency Code")
                        {
                        }
                        fieldattribute(PricesInclVAT; ICOutBoxPurchHdr."Prices Including VAT")
                        {
                        }
                        fieldattribute(VendInvNo; ICOutBoxPurchHdr."Vendor Invoice No.")
                        {
                        }
                        fieldattribute(VendCrMemoNo; ICOutBoxPurchHdr."Vendor Cr. Memo No.")
                        {
                        }
                        fieldattribute(SellToCustNo; ICOutBoxPurchHdr."Sell-to Customer No.")
                        {
                        }
                        fieldattribute(DocDate; ICOutBoxPurchHdr."Document Date")
                        {
                        }
                        fieldattribute(ICPartnerCode; ICOutBoxPurchHdr."IC Partner Code")
                        {
                        }
                        fieldattribute(ICTransNo; ICOutBoxPurchHdr."IC Transaction No.")
                        {
                        }
                        fieldattribute(TransSource; ICOutBoxPurchHdr."Transaction Source")
                        {
                        }
                        fieldattribute(ReqRecDate; ICOutBoxPurchHdr."Requested Receipt Date")
                        {
                        }
                        fieldattribute(PromRecDate; ICOutBoxPurchHdr."Promised Receipt Date")
                        {
                        }
                        textelement(ICPurDocDimensions)
                        {
                            tableelement(icpurdocdim; "IC Document Dimension")
                            {
                                LinkFields = "Transaction No." = field("IC Transaction No."), "IC Partner Code" = field("IC Partner Code"), "Transaction Source" = field("Transaction Source");
                                LinkTable = ICOutBoxPurchHdr;
                                MinOccurs = Zero;
                                XmlName = 'ICPurDocDim';
                                SourceTableView = where("Table ID" = const(428), "Line No." = const(0));
                                UseTemporary = true;
                                fieldattribute(TableID; ICPurDocDim."Table ID")
                                {
                                }
                                fieldattribute(TransNo; ICPurDocDim."Transaction No.")
                                {
                                }
                                fieldattribute(ICPartnerCode; ICPurDocDim."IC Partner Code")
                                {
                                }
                                fieldattribute(TransSource; ICPurDocDim."Transaction Source")
                                {
                                }
                                fieldattribute(LineNo; ICPurDocDim."Line No.")
                                {
                                }
                                fieldattribute(DimCode; ICPurDocDim."Dimension Code")
                                {
                                }
                                fieldattribute(DimValCode; ICPurDocDim."Dimension Value Code")
                                {
                                }
                            }
                        }
                        textelement(ICOutBoxPurchLines)
                        {
                            tableelement(icoutboxpurchline; "IC Outbox Purchase Line")
                            {
                                LinkFields = "Document No." = field("No."), "IC Transaction No." = field("IC Transaction No."), "IC Partner Code" = field("IC Partner Code"), "Transaction Source" = field("Transaction Source");
                                LinkTable = ICOutBoxPurchHdr;
                                MinOccurs = Zero;
                                XmlName = 'ICOutBoxPurchLine';
                                UseTemporary = true;
                                fieldattribute(DocType; ICOutBoxPurchLine."Document Type")
                                {
                                }
                                fieldattribute(DocNo; ICOutBoxPurchLine."Document No.")
                                {
                                }
                                fieldattribute(LineNo; ICOutBoxPurchLine."Line No.")
                                {
                                }
                                fieldattribute(Description; ICOutBoxPurchLine.Description)
                                {
                                }
                                fieldattribute(Quantity; ICOutBoxPurchLine.Quantity)
                                {
                                }
                                fieldattribute(DirUnitCost; ICOutBoxPurchLine."Direct Unit Cost")
                                {
                                }
                                fieldattribute(LineDiscAmount; ICOutBoxPurchLine."Line Discount Amount")
                                {
                                }
                                fieldattribute(AmountInclVAT; ICOutBoxPurchLine."Amount Including VAT")
                                {
                                }
                                fieldattribute(JobNo; ICOutBoxPurchLine."Job No.")
                                {
                                }
                                fieldattribute(IndCostPct; ICOutBoxPurchLine."Indirect Cost %")
                                {
                                }
                                fieldattribute(DropShipment; ICOutBoxPurchLine."Drop Shipment")
                                {
                                }
                                fieldattribute(CurrencyCode; ICOutBoxPurchLine."Currency Code")
                                {
                                }
                                fieldattribute(VATBaseAmount; ICOutBoxPurchLine."VAT Base Amount")
                                {
                                }
                                fieldattribute(UnitCost; ICOutBoxPurchLine."Unit Cost")
                                {
                                }
                                fieldattribute(LineAmount; ICOutBoxPurchLine."Line Amount")
                                {
                                }
                                fieldattribute(ICPartnerRefType; ICOutBoxPurchLine."IC Partner Ref. Type")
                                {
                                }
                                fieldattribute(ICPartnerRef; ICOutBoxPurchLine."IC Partner Reference")
                                {
                                }
                                fieldattribute(ICItemRefNo; ICOutBoxPurchLine."IC Item Reference No.")
                                {
                                }
                                fieldattribute(TransSource; ICOutBoxPurchLine."Transaction Source")
                                {
                                }
                                fieldattribute(UnitOfMeasureCode; ICOutBoxPurchLine."Unit of Measure Code")
                                {
                                }
                                fieldattribute(TransNo; ICOutBoxPurchLine."IC Transaction No.")
                                {
                                }
                                fieldattribute(ReqRecDate; ICOutBoxPurchLine."Requested Receipt Date")
                                {
                                }
                                fieldattribute(PromRecDate; ICOutBoxPurchLine."Promised Receipt Date")
                                {
                                }
                                textelement(PurLineDimensions)
                                {
                                    tableelement(icpurdoclinedim; "IC Document Dimension")
                                    {
                                        LinkFields = "Transaction No." = field("IC Transaction No."), "IC Partner Code" = field("IC Partner Code"), "Transaction Source" = field("Transaction Source"), "Line No." = field("Line No.");
                                        LinkTable = ICOutBoxPurchLine;
                                        MinOccurs = Zero;
                                        XmlName = 'ICPurDocLineDim';
                                        SourceTableView = where("Table ID" = const(429));
                                        UseTemporary = true;
                                        fieldattribute(TableID; ICPurDocLineDim."Table ID")
                                        {
                                        }
                                        fieldattribute(TransNo; ICPurDocLineDim."Transaction No.")
                                        {
                                        }
                                        fieldattribute(ICPartnerCode; ICPurDocLineDim."IC Partner Code")
                                        {
                                        }
                                        fieldattribute(TransSource; ICPurDocLineDim."Transaction Source")
                                        {
                                        }
                                        fieldattribute(LineNo; ICPurDocLineDim."Line No.")
                                        {
                                        }
                                        fieldattribute(DimCode; ICPurDocLineDim."Dimension Code")
                                        {
                                        }
                                        fieldattribute(DimValCode; ICPurDocLineDim."Dimension Value Code")
                                        {
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    trigger OnPreXmlPort()
    begin
        ICSetup.Get();
        ICSetup.TestField("IC Partner Code");
    end;

    var
        ICSetup: Record "IC Setup";
        ToICPartnerCode2: Code[20];

    procedure SetICOutboxTrans(var NewICOutboxTrans: Record "IC Outbox Transaction")
    var
        NewICOutBoxJnlLine: Record "IC Outbox Jnl. Line";
        NewICIOBoxJnlDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
        NewICOutBoxSalesHdr: Record "IC Outbox Sales Header";
        NewICOutBoxSalesLine: Record "IC Outbox Sales Line";
        NewICOutBoxPurchHdr: Record "IC Outbox Purchase Header";
        NewICOutBoxPurchLine: Record "IC Outbox Purchase Line";
        NewICDocDim: Record "IC Document Dimension";
    begin
        ICOutboxTrans.DeleteAll();
        ICOutBoxJnlLine.DeleteAll();
        ICIOBoxJnlDim.DeleteAll();
        ICOutBoxSalesHdr.DeleteAll();
        ICOutBoxSalesLine.DeleteAll();
        ICOutBoxPurchHdr.DeleteAll();
        ICOutBoxPurchLine.DeleteAll();
        ICSalesDocDim.DeleteAll();
        ICSalesDocLineDim.DeleteAll();
        ICPurDocDim.DeleteAll();
        ICPurDocLineDim.DeleteAll();

        if NewICOutboxTrans.Find('-') then
            repeat
                ICOutboxTrans := NewICOutboxTrans;
                ICOutboxTrans.Insert();

                NewICOutBoxJnlLine.SetRange("Transaction No.", NewICOutboxTrans."Transaction No.");
                NewICOutBoxJnlLine.SetRange("IC Partner Code", NewICOutboxTrans."IC Partner Code");
                NewICOutBoxJnlLine.SetRange("Transaction Source", NewICOutboxTrans."Transaction Source");
                if NewICOutBoxJnlLine.Find('-') then
                    repeat
                        ICOutBoxJnlLine := NewICOutBoxJnlLine;
                        ICOutBoxJnlLine.Insert();
                    until NewICOutBoxJnlLine.Next() = 0;

                NewICIOBoxJnlDim.SetRange("Table ID", DATABASE::"IC Outbox Jnl. Line");
                NewICIOBoxJnlDim.SetRange("Transaction No.", NewICOutboxTrans."Transaction No.");
                NewICIOBoxJnlDim.SetRange("IC Partner Code", NewICOutboxTrans."IC Partner Code");
                NewICIOBoxJnlDim.SetRange("Transaction Source", NewICOutboxTrans."Transaction Source");
                if NewICIOBoxJnlDim.Find('-') then
                    repeat
                        ICIOBoxJnlDim := NewICIOBoxJnlDim;
                        ICIOBoxJnlDim.Insert();
                    until NewICIOBoxJnlDim.Next() = 0;

                NewICOutBoxSalesHdr.SetRange("IC Transaction No.", NewICOutboxTrans."Transaction No.");
                NewICOutBoxSalesHdr.SetRange("IC Partner Code", NewICOutboxTrans."IC Partner Code");
                NewICOutBoxSalesHdr.SetRange("Transaction Source", NewICOutboxTrans."Transaction Source");
                if NewICOutBoxSalesHdr.Find('-') then
                    repeat
                        ICOutBoxSalesHdr := NewICOutBoxSalesHdr;
                        ICOutBoxSalesHdr.Insert();
                    until NewICOutBoxSalesHdr.Next() = 0;

                NewICOutBoxSalesLine.SetRange("IC Transaction No.", NewICOutboxTrans."Transaction No.");
                NewICOutBoxSalesLine.SetRange("IC Partner Code", NewICOutboxTrans."IC Partner Code");
                NewICOutBoxSalesLine.SetRange("Transaction Source", NewICOutboxTrans."Transaction Source");
                if NewICOutBoxSalesLine.Find('-') then
                    repeat
                        ICOutBoxSalesLine := NewICOutBoxSalesLine;
                        ICOutBoxSalesLine.Insert();
                    until NewICOutBoxSalesLine.Next() = 0;

                NewICOutBoxPurchHdr.SetRange("IC Transaction No.", NewICOutboxTrans."Transaction No.");
                NewICOutBoxPurchHdr.SetRange("IC Partner Code", NewICOutboxTrans."IC Partner Code");
                NewICOutBoxPurchHdr.SetRange("Transaction Source", NewICOutboxTrans."Transaction Source");
                if NewICOutBoxPurchHdr.Find('-') then
                    repeat
                        ICOutBoxPurchHdr := NewICOutBoxPurchHdr;
                        ICOutBoxPurchHdr.Insert();
                    until NewICOutBoxPurchHdr.Next() = 0;

                NewICOutBoxPurchLine.SetRange("IC Transaction No.", NewICOutboxTrans."Transaction No.");
                NewICOutBoxPurchLine.SetRange("IC Partner Code", NewICOutboxTrans."IC Partner Code");
                NewICOutBoxPurchLine.SetRange("Transaction Source", NewICOutboxTrans."Transaction Source");
                if NewICOutBoxPurchLine.Find('-') then
                    repeat
                        ICOutBoxPurchLine := NewICOutBoxPurchLine;
                        ICOutBoxPurchLine.Insert();
                    until NewICOutBoxPurchLine.Next() = 0;

                NewICDocDim.SetRange("Transaction No.", NewICOutboxTrans."Transaction No.");
                NewICDocDim.SetRange("IC Partner Code", NewICOutboxTrans."IC Partner Code");
                NewICDocDim.SetRange("Transaction Source", NewICOutboxTrans."Transaction Source");

                NewICDocDim.SetRange("Table ID", DATABASE::"IC Outbox Sales Header");
                NewICDocDim.SetRange("Line No.", 0);
                SetICDocDim(NewICDocDim, ICSalesDocDim);

                NewICDocDim.SetRange("Table ID", DATABASE::"IC Outbox Sales Line");
                NewICDocDim.SetRange("Line No.");
                SetICDocDim(NewICDocDim, ICSalesDocLineDim);

                NewICDocDim.SetRange("Table ID", DATABASE::"IC Outbox Purchase Header");
                NewICDocDim.SetRange("Line No.", 0);
                SetICDocDim(NewICDocDim, ICPurDocDim);

                NewICDocDim.SetRange("Table ID", DATABASE::"IC Outbox Purchase Line");
                NewICDocDim.SetRange("Line No.");
                SetICDocDim(NewICDocDim, ICPurDocLineDim);
            until NewICOutboxTrans.Next() = 0;
    end;

    local procedure SetICDocDim(var NewICDocDim: Record "IC Document Dimension"; var DestDocDim: Record "IC Document Dimension")
    begin
        if NewICDocDim.Find('-') then
            repeat
                DestDocDim := NewICDocDim;
                DestDocDim.Insert();
            until NewICDocDim.Next() = 0;
    end;

    procedure GetICOutboxTrans(var NewICOutboxTrans: Record "IC Outbox Transaction")
    begin
        ICOutboxTrans.Reset();
        if ICOutboxTrans.Find('-') then
            repeat
                NewICOutboxTrans := ICOutboxTrans;
                NewICOutboxTrans.Insert();
            until ICOutboxTrans.Next() = 0;
    end;

    procedure GetICOutBoxJnlLine(var NewICOutBoxJnlLine: Record "IC Outbox Jnl. Line")
    begin
        ICOutBoxJnlLine.Reset();
        if ICOutBoxJnlLine.Find('-') then
            repeat
                NewICOutBoxJnlLine := ICOutBoxJnlLine;
                NewICOutBoxJnlLine.Insert();
            until ICOutBoxJnlLine.Next() = 0;
    end;

    procedure GetICIOBoxJnlDim(var NewICIOBoxJnlDim: Record "IC Inbox/Outbox Jnl. Line Dim.")
    begin
        ICIOBoxJnlDim.Reset();
        if ICIOBoxJnlDim.Find('-') then
            repeat
                NewICIOBoxJnlDim := ICIOBoxJnlDim;
                NewICIOBoxJnlDim.Insert();
            until ICIOBoxJnlDim.Next() = 0;
    end;

    procedure GetICOutBoxSalesHdr(var NewICOutBoxSalesHdr: Record "IC Outbox Sales Header")
    begin
        ICOutBoxSalesHdr.Reset();
        if ICOutBoxSalesHdr.Find('-') then
            repeat
                NewICOutBoxSalesHdr := ICOutBoxSalesHdr;
                NewICOutBoxSalesHdr.Insert();
            until ICOutBoxSalesHdr.Next() = 0;
    end;

    procedure GetICOutBoxSalesLine(var NewICOutBoxSalesLine: Record "IC Outbox Sales Line")
    begin
        ICOutBoxSalesLine.Reset();
        if ICOutBoxSalesLine.Find('-') then
            repeat
                NewICOutBoxSalesLine := ICOutBoxSalesLine;
                NewICOutBoxSalesLine.Insert();
            until ICOutBoxSalesLine.Next() = 0;
    end;

    procedure GetICOutBoxPurchHdr(var NewICOutBoxPurchHdr: Record "IC Outbox Purchase Header")
    begin
        ICOutBoxPurchHdr.Reset();
        if ICOutBoxPurchHdr.Find('-') then
            repeat
                NewICOutBoxPurchHdr := ICOutBoxPurchHdr;
                NewICOutBoxPurchHdr.Insert();
            until ICOutBoxPurchHdr.Next() = 0;
    end;

    procedure GetICOutBoxPurchLine(var NewICOutBoxPurchLine: Record "IC Outbox Purchase Line")
    begin
        ICOutBoxPurchLine.Reset();
        if ICOutBoxPurchLine.Find('-') then
            repeat
                NewICOutBoxPurchLine := ICOutBoxPurchLine;
                NewICOutBoxPurchLine.Insert();
            until ICOutBoxPurchLine.Next() = 0;
    end;

    procedure GetICSalesDocDim(var NewICDocDim: Record "IC Document Dimension")
    begin
        ICSalesDocDim.Reset();
        SetICDocDim(ICSalesDocDim, NewICDocDim);
    end;

    procedure GetICSalesDocLineDim(var NewICDocDim: Record "IC Document Dimension")
    begin
        ICSalesDocLineDim.Reset();
        SetICDocDim(ICSalesDocLineDim, NewICDocDim);
    end;

    procedure GetICPurchDocDim(var NewICDocDim: Record "IC Document Dimension")
    begin
        ICPurDocDim.Reset();
        SetICDocDim(ICPurDocDim, NewICDocDim);
    end;

    procedure GetICPurchDocLineDim(var NewICDocDim: Record "IC Document Dimension")
    begin
        ICPurDocLineDim.Reset();
        SetICDocDim(ICPurDocLineDim, NewICDocDim);
    end;

    procedure GetFromICPartnerCode(): Code[20]
    begin
        exit(FromICPartnerCode);
    end;

    procedure GetToICPartnerCode(): Code[20]
    begin
        exit(ToICPartnerCode2);
    end;
}

