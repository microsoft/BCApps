// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Address;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Project.Job;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Utilities;

report 212 "Sales Prepmt. Document Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/Reports/SalesPrepmtDocumentTest.rdlc';
    Caption = 'Sales Prepmt. Document Test';

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = where("Document Type" = const(Order));
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Prepayment Sales Document';
            column(DocType_SalesHeader; "Document Type")
            {
            }
            column(No_SalesHeader; "No.")
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(CompanyName; COMPANYPROPERTY.DisplayName())
                {
                }
                column(TodayFormatted; Format(Today, 0, 4))
                {
                }
                column(SalesHeaderSalesDocFilter; StrSubstNo(Text001, SalesHeaderFilter))
                {
                }
                column(SalesHeaderFilter; SalesHeaderFilter)
                {
                }
                column(PrepmtDocText; PrepmtDocText)
                {
                }
                column(SalesHdrDocTypeSalesHdrNo; Format("Sales Header"."Document Type") + ' ' + "Sales Header"."No.")
                {
                }
                column(SelltoCustNo_SalesHeader; "Sales Header"."Sell-to Customer No.")
                {
                }
                column(SellToAddr1; SellToAddr[1])
                {
                }
                column(SellToAddr2; SellToAddr[2])
                {
                }
                column(SellToAddr3; SellToAddr[3])
                {
                }
                column(SellToAddr4; SellToAddr[4])
                {
                }
                column(SellToAddr5; SellToAddr[5])
                {
                }
                column(ShipToAddr5; ShipToAddr[5])
                {
                }
                column(ShipToAddr4; ShipToAddr[4])
                {
                }
                column(ShipToAddr3; ShipToAddr[3])
                {
                }
                column(ShipToAddr2; ShipToAddr[2])
                {
                }
                column(ShipToAddr1; ShipToAddr[1])
                {
                }
                column(ShipToAddr6; ShipToAddr[6])
                {
                }
                column(SellToAddr6; SellToAddr[6])
                {
                }
                column(ShipToAddr7; ShipToAddr[7])
                {
                }
                column(SellToAddr7; SellToAddr[7])
                {
                }
                column(ShipToAddr8; ShipToAddr[8])
                {
                }
                column(SellToAddr8; SellToAddr[8])
                {
                }
                column(ShiptoCode_SalesHeader; "Sales Header"."Ship-to Code")
                {
                }
                column(ShowDim; ShowDim)
                {
                }
                column(DocumentType; DocumentType)
                {
                }
                column(BillToAddr8; BillToAddr[8])
                {
                }
                column(BillToAddr7; BillToAddr[7])
                {
                }
                column(BillToAddr6; BillToAddr[6])
                {
                }
                column(BillToAddr5; BillToAddr[5])
                {
                }
                column(BillToAddr4; BillToAddr[4])
                {
                }
                column(BillToAddr3; BillToAddr[3])
                {
                }
                column(BillToAddr2; BillToAddr[2])
                {
                }
                column(BillToAddr1; BillToAddr[1])
                {
                }
                column(BilltoCustNo_SalesHeader; "Sales Header"."Bill-to Customer No.")
                {
                }
                column(SalespersonCode_SalesHeader; "Sales Header"."Salesperson Code")
                {
                }
                column(YourRef_SalesHeader; "Sales Header"."Your Reference")
                {
                }
                column(PricesIncludVAT_SalesHeader; "Sales Header"."Prices Including VAT")
                {
                }
                column(PostDate_SalesHeader; Format("Sales Header"."Posting Date"))
                {
                }
                column(DocDate_SalesHeader; Format("Sales Header"."Document Date"))
                {
                }
                column(ShipmentDate_SalesHeader; Format("Sales Header"."Shipment Date"))
                {
                }
                column(OrderDate_SalesHeader; Format("Sales Header"."Order Date"))
                {
                }
                column(PrepmtPmtTermsCode_SalesHeader; "Sales Header"."Prepmt. Payment Terms Code")
                {
                }
                column(ShipmentMethodCode_SalesHeader; "Sales Header"."Shipment Method Code")
                {
                }
                column(PmtMethodCode_SalesHeader; "Sales Header"."Payment Method Code")
                {
                }
                column(PrepmtDueDate_SalesHeader; Format("Sales Header"."Prepayment Due Date"))
                {
                }
                column(PrepmtPmtDiscDate_SalesHeader; Format("Sales Header"."Prepmt. Pmt. Discount Date"))
                {
                }
                column(PrepmtPmtDisc_SalesHeader; "Sales Header"."Prepmt. Payment Discount %")
                {
                }
                column(CustPostGroup_SalesHeader; "Sales Header"."Customer Posting Group")
                {
                }
                column(SalesHdrPricesIncludingVATFmt; Format("Sales Header"."Prices Including VAT"))
                {
                }
                column(SalesPrepmtDocTestCaption; SalesPrepmtDocTestCaptionLbl)
                {
                }
                column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
                {
                }
                column(SelltoCustNo_SalesHeaderCaption; "Sales Header".FieldCaption("Sell-to Customer No."))
                {
                }
                column(SelltoCaption; SelltoCaptionLbl)
                {
                }
                column(ShiptoCaption; ShiptoCaptionLbl)
                {
                }
                column(ShiptoCode_SalesHeaderCaption; "Sales Header".FieldCaption("Ship-to Code"))
                {
                }
                column(BilltoCaption; BilltoCaptionLbl)
                {
                }
                column(BilltoCustNo_SalesHeaderCaption; "Sales Header".FieldCaption("Bill-to Customer No."))
                {
                }
                column(SalespersonCode_SalesHeaderCaption; "Sales Header".FieldCaption("Salesperson Code"))
                {
                }
                column(YourRef_SalesHeaderCaption; "Sales Header".FieldCaption("Your Reference"))
                {
                }
                column(PricesIncludVAT_SalesHeaderCaption; "Sales Header".FieldCaption("Prices Including VAT"))
                {
                }
                column(PostDate_SalesHeaderCaption; PostDateSalesHeaderCaptionLbl)
                {
                }
                column(DocDate_SalesHeaderCaption; DocDateSalesHeaderCaptionLbl)
                {
                }
                column(ShipmentDate_SalesHeaderCaption; ShipmentDateSalesHeaderCaptionLbl)
                {
                }
                column(OrderDate_SalesHeaderCaption; OrderDateSalesHeaderCaptionLbl)
                {
                }
                column(PrepmtPmtTermsCode_SalesHeaderCaption; "Sales Header".FieldCaption("Prepmt. Payment Terms Code"))
                {
                }
                column(PrepmtPmtDisc_SalesHeaderCaption; "Sales Header".FieldCaption("Prepmt. Payment Discount %"))
                {
                }
                column(PrepmtDueDate_SalesHeaderCaption; PrepmtDueDateSalesHeaderCaptionLbl)
                {
                }
                column(PrepmtPmtDiscDate_SalesHeaderCaption; PrepmtPmtDiscDateSalesHeaderCaptionLbl)
                {
                }
                column(ShipmentMethodCode_SalesHeaderCaption; "Sales Header".FieldCaption("Shipment Method Code"))
                {
                }
                column(PmtMethodCode_SalesHeaderCaption; "Sales Header".FieldCaption("Payment Method Code"))
                {
                }
                column(CustPostGroup_SalesHeaderCaption; "Sales Header".FieldCaption("Customer Posting Group"))
                {
                }
                dataitem(HeaderDimLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(DimText; DimText)
                    {
                    }
                    column(HeaderDimLoop_Number; Number)
                    {
                    }
                    column(Header_DimensionsCaption; HeaderDimensionsCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            if not DimSetEntry.Find('-') then
                                CurrReport.Break();
                        end else
                            if not Continue then
                                CurrReport.Break();

                        DimText := '';

                        Continue := false;

                        repeat
                            Continue := MergeText(DimSetEntry);
                            if Continue then
                                exit;
                        until DimSetEntry.Next() = 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not ShowDim then
                            CurrReport.Break();
                    end;
                }
                dataitem(HeaderErrorCounter; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(ErrorText_HeaderErrorCounter; ErrorText[Number])
                    {
                    }
                    column(ErrorText_HeaderErrorCounterCaption; ErrorTextHeaderErrorCounterCaptionLbl)
                    {
                    }

                    trigger OnPostDataItem()
                    begin
                        ErrorCounter := 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, ErrorCounter);
                    end;
                }
                dataitem(CopyLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    dataitem("Sales Line"; "Sales Line")
                    {
                        DataItemTableView = sorting("Document Type", "Document No.", "Line No.");

                        trigger OnPreDataItem()
                        begin
                            CurrReport.Break();
                        end;
                    }
                    dataitem(SalesLineLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(PrepmtAmtInv_SalesLine; "Sales Line"."Prepmt. Amt. Inv.")
                        {
                        }
                        column(PrepmtLineAmt_SalesLine; "Sales Line"."Prepmt. Line Amount")
                        {
                        }
                        column(Prepayment_SalesLine; "Sales Line"."Prepayment %")
                        {
                        }
                        column(LineAmt_SalesLine; "Sales Line"."Line Amount")
                        {
                        }
                        column(Quantity_SalesLine; "Sales Line".Quantity)
                        {
                        }
                        column(Desc_SalesLine; "Sales Line".Description)
                        {
                        }
                        column(No_SalesLine; "Sales Line"."No.")
                        {
                        }
                        column(Type_SalesLine; Format("Sales Line".Type))
                        {
                        }
                        column(LineNo_SalesLine; "Sales Line"."Line No.")
                        {
                        }
                        column(PrepmtAmtInv_SalesLineCaption; "Sales Line".FieldCaption("Prepmt. Amt. Inv."))
                        {
                        }
                        column(PrepmtLineAmt_SalesLineCaption; "Sales Line".FieldCaption("Prepmt. Line Amount"))
                        {
                        }
                        column(Prepayment_SalesLineCaption; "Sales Line".FieldCaption("Prepayment %"))
                        {
                        }
                        column(LineAmt_SalesLineCaption; "Sales Line".FieldCaption("Line Amount"))
                        {
                        }
                        column(Quantity_SalesLineCaption; "Sales Line".FieldCaption(Quantity))
                        {
                        }
                        column(Desc_SalesLineCaption; "Sales Line".FieldCaption(Description))
                        {
                        }
                        column(No_SalesLineCaption; "Sales Line".FieldCaption("No."))
                        {
                        }
                        column(Type_SalesLineCaption; "Sales Line".FieldCaption(Type))
                        {
                        }
                        dataitem(LineErrorCounter; "Integer")
                        {
                            DataItemTableView = sorting(Number);
                            column(ErrorText_LineErrorCounter; ErrorText[Number])
                            {
                            }

                            trigger OnPostDataItem()
                            begin
                                ErrorCounter := 0;
                            end;

                            trigger OnPreDataItem()
                            begin
                                SetRange(Number, 1, ErrorCounter);
                            end;
                        }

                        trigger OnAfterGetRecord()
                        var
                            GLAcc: Record "G/L Account";
                            CurrentErrorCount: Integer;
                        begin
                            if Number = 1 then begin
                                if not TempSalesLine.Find('-') then
                                    CurrReport.Break();
                            end else
                                if TempSalesLine.Next() = 0 then
                                    CurrReport.Break();
                            "Sales Line" := TempSalesLine;

                            CurrentErrorCount := ErrorCounter;

                            if ("Sales Line"."Gen. Bus. Posting Group" <> GenPostingSetup."Gen. Bus. Posting Group") or
                               ("Sales Line"."Gen. Prod. Posting Group" <> GenPostingSetup."Gen. Prod. Posting Group")
                            then
                                if not GenPostingSetup.Get(
                                     "Sales Line"."Gen. Bus. Posting Group", "Sales Line"."Gen. Prod. Posting Group")
                                then
                                    AddError(
                                      StrSubstNo(
                                        Text006,
                                        GenPostingSetup.TableCaption(),
                                        "Sales Line"."Gen. Bus. Posting Group", "Sales Line"."Gen. Prod. Posting Group"));

                            if GenPostingSetup."Sales Prepayments Account" = '' then
                                AddError(StrSubstNo(Text005, GenPostingSetup.FieldCaption("Sales Prepayments Account")))
                            else
                                if GLAcc.Get(GenPostingSetup."Sales Prepayments Account") then begin
                                    if GLAcc.Blocked then
                                        AddError(
                                          StrSubstNo(
                                            Text008, GLAcc.FieldCaption(Blocked), false, GLAcc.TableCaption(), "Sales Line"."No."));
                                end else
                                    AddError(StrSubstNo(Text007, GLAcc.TableCaption(), GenPostingSetup."Sales Prepayments Account"));

                            if ErrorCounter = CurrentErrorCount then
                                if SalesPostPrepmt.PrepmtAmount("Sales Line", DocumentType) <> 0 then begin
                                    SalesPostPrepmt.FillInvLineBuffer("Sales Header", "Sales Line", TempPrepmtInvLineBuf2);
                                    TempPrepmtInvLineBuf.InsertInvLineBuffer(TempPrepmtInvLineBuf2);
                                end;
                        end;
                    }

                    trigger OnPreDataItem()
                    var
                        TempSalesLineToDeduct: Record "Sales Line" temporary;
                    begin
                        TempSalesLine.Reset();
                        TempSalesLine.DeleteAll();

                        Clear(SalesPostPrepmt);
                        TempVATAmountLine.DeleteAll();
                        SalesPostPrepmt.GetSalesLines("Sales Header", DocumentType, TempSalesLine);
                        if DocumentType = DocumentType::Invoice then begin
                            SalesPostPrepmt.GetSalesLinesToDeduct("Sales Header", TempSalesLineToDeduct);
                            if not TempSalesLineToDeduct.IsEmpty() then
                                SalesPostPrepmt.CalcVATAmountLines(
                                  "Sales Header", TempSalesLineToDeduct, TempVATAmountLineDeduct, DocumentType::"Credit Memo");
                        end;
                        SalesPostPrepmt.CalcVATAmountLines("Sales Header", TempSalesLine, TempVATAmountLine, DocumentType);
                        TempVATAmountLine.DeductVATAmountLine(TempVATAmountLineDeduct);
                        SalesPostPrepmt.UpdateVATOnLines("Sales Header", TempSalesLine, TempVATAmountLine, DocumentType);
                        VATAmount := TempVATAmountLine.GetTotalVATAmount();
                        VATBaseAmount := TempVATAmountLine.GetTotalVATBase();
                    end;
                }
                dataitem(Blank; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                }
                dataitem(PrepmtLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(PrepmtInvLineBuffGLAccNo; "Prepayment Inv. Line Buffer"."G/L Account No.")
                    {
                    }
                    column(PrepmtInvLineBuffAmt; "Prepayment Inv. Line Buffer".Amount)
                    {
                    }
                    column(PrepmtInvLineBuffDesc; "Prepayment Inv. Line Buffer".Description)
                    {
                    }
                    column(PrepmtInvLineBuffVATAmt; "Prepayment Inv. Line Buffer"."VAT Amount")
                    {
                    }
                    column(PrepmtInvLineBuffVAT; "Prepayment Inv. Line Buffer"."VAT %")
                    {
                    }
                    column(PrepmtInvLineBuffVATIdentifier; "Prepayment Inv. Line Buffer"."VAT Identifier")
                    {
                    }
                    column(PrepmtLoopNumber; Number)
                    {
                    }
                    column(TotalText; TotalText)
                    {
                    }
                    column(SalesHeaderCurrCode; "Prepayment Inv. Line Buffer".Amount)
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(TotalExclVATText; TotalExclVATText)
                    {
                    }
                    column(VATAmtLineVATAmtText; TempVATAmountLine.VATAmountText())
                    {
                    }
                    column(TotalInclVATText; TotalInclVATText)
                    {
                    }
                    column(VATAmount; VATAmount)
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(PrepmtInvLineBuffAmtVATAmt; "Prepayment Inv. Line Buffer".Amount + VATAmount)
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(SumPrepaymInvLineBufferAmount; SumPrepaymInvLineBufferAmount)
                    {
                    }
                    column(VATBaseAmtVATAmt; VATBaseAmount + VATAmount)
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATBaseAmount; VATBaseAmount)
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(PrepmtInvLineBuffGLAccNoCaption; "Prepayment Inv. Line Buffer".FieldCaption("G/L Account No."))
                    {
                    }
                    column(PrepmtInvLineBuffAmtCaption; "Prepayment Inv. Line Buffer".FieldCaption(Amount))
                    {
                    }
                    column(PrepmtInvLineBuffDescCaption; "Prepayment Inv. Line Buffer".FieldCaption(Description))
                    {
                    }
                    column(PrepmtInvLineBuffVATAmtCaption; "Prepayment Inv. Line Buffer".FieldCaption("VAT Amount"))
                    {
                    }
                    column(PrepmtInvLineBuffVATCaption; "Prepayment Inv. Line Buffer".FieldCaption("VAT %"))
                    {
                    }
                    column(PrepmtInvLineBuffVATIdentifierCaption; "Prepayment Inv. Line Buffer".FieldCaption("VAT Identifier"))
                    {
                    }
                    dataitem("Prepayment Inv. Line Buffer"; "Prepayment Inv. Line Buffer")
                    {
                        DataItemTableView = sorting("G/L Account No.", "Dimension Set ID", "Job No.", "Tax Area Code", "Tax Liable", "Tax Group Code", "Invoice Rounding", Adjustment, "Line No.");

                        trigger OnPreDataItem()
                        begin
                            CurrReport.Break();
                        end;
                    }
                    dataitem(LineDimLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(DimText_LineDimLoop; DimText)
                        {
                        }
                        column(LineDimLoop_Number; Number)
                        {
                        }
                        column(Line_DimensionsCaption; LineDimensionsCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not LineDimSetEntry.FindSet() then
                                    CurrReport.Break();
                            end else
                                if not Continue then
                                    CurrReport.Break();

                            DimText := '';

                            Continue := false;

                            repeat
                                Continue := MergeText(LineDimSetEntry);
                                if Continue then
                                    exit;
                            until LineDimSetEntry.Next() = 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowDim then
                                CurrReport.Break();
                        end;
                    }
                    dataitem(PrepmtErrorCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(ErrorText_PrepmtErrorCounter; ErrorText[Number])
                        {
                        }

                        trigger OnPostDataItem()
                        begin
                            ErrorCounter := 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, ErrorCounter);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    var
                        TableID: array[10] of Integer;
                        No: array[10] of Code[20];
                    begin
                        if Number = 1 then begin
                            if not TempPrepmtInvLineBuf.Find('-') then
                                CurrReport.Break();
                        end else
                            if TempPrepmtInvLineBuf.Next() = 0 then
                                CurrReport.Break();

                        LineDimSetEntry.SetRange("Dimension Set ID", TempPrepmtInvLineBuf."Dimension Set ID");
                        "Prepayment Inv. Line Buffer" := TempPrepmtInvLineBuf;

                        if not DimMgt.CheckDimIDComb(TempPrepmtInvLineBuf."Dimension Set ID") then
                            AddError(DimMgt.GetDimCombErr());
                        TableID[1] := DimMgt.SalesLineTypeToTableID(TempSalesLine.Type::"G/L Account");
                        No[1] := "Prepayment Inv. Line Buffer"."G/L Account No.";
                        TableID[2] := Database::Job;
                        No[2] := "Prepayment Inv. Line Buffer"."Job No.";
                        if not DimMgt.CheckDimValuePosting(TableID, No, TempPrepmtInvLineBuf."Dimension Set ID") then
                            AddError(DimMgt.GetDimValuePostingErr());
                        SumPrepaymInvLineBufferAmount := SumPrepaymInvLineBufferAmount + "Prepayment Inv. Line Buffer".Amount;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SumPrepaymInvLineBufferAmount := 0;
                    end;
                }
                dataitem(VATCounter; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(VATAmtLineVATAmt; TempVATAmountLine."VAT Amount")
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVATBase; TempVATAmountLine."VAT Base")
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineLineAmt; TempVATAmountLine."Line Amount")
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVAT; TempVATAmountLine."VAT %")
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(VATAmtLineVATIdentifier; TempVATAmountLine."VAT Identifier")
                    {
                    }
                    column(VATAmtLineVATAmtCaption; VATAmtLineVATAmtCaptionLbl)
                    {
                    }
                    column(VATAmtLineVATBaseCaption; VATAmtLineVATBaseCaptionLbl)
                    {
                    }
                    column(VATAmtLineLineAmtCaption; VATAmtLineLineAmtCaptionLbl)
                    {
                    }
                    column(VATAmtLineVATCaption; VATAmtLineVATCaptionLbl)
                    {
                    }
                    column(VATAmtLineVATIdentifierCaption; VATAmtLineVATIdentifierCaptionLbl)
                    {
                    }
                    column(VATAmtSpecificationCaption; VATAmtSpecificationCaptionLbl)
                    {
                    }
                    column(TotalCaption; TotalCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        TempVATAmountLine.GetLine(Number);
                    end;

                    trigger OnPreDataItem()
                    begin
                        if VATAmount = 0 then
                            CurrReport.Break();
                        SetRange(Number, 1, TempVATAmountLine.Count);
                    end;
                }
            }

            trigger OnAfterGetRecord()
            var
                FormatAddr: Codeunit "Format Address";
                TableID: array[10] of Integer;
                No: array[10] of Code[20];
            begin
                FormatAddr.SalesHeaderSellTo(SellToAddr, "Sales Header");
                FormatAddr.SalesHeaderBillTo(BillToAddr, "Sales Header");
                FormatAddr.SalesHeaderShipTo(ShipToAddr, ShipToAddr, "Sales Header");
                if "Currency Code" = '' then begin
                    GLSetup.TestField("LCY Code");
                    TotalText := StrSubstNo(Text002, GLSetup."LCY Code");
                    TotalExclVATText := StrSubstNo(Text003, GLSetup."LCY Code");
                    TotalInclVATText := StrSubstNo(Text004, GLSetup."LCY Code");
                end else begin
                    TotalText := StrSubstNo(Text002, "Currency Code");
                    TotalExclVATText := StrSubstNo(Text003, "Currency Code");
                    TotalInclVATText := StrSubstNo(Text004, "Currency Code");
                end;

                if "Document Type" <> "Document Type"::Order then
                    AddError(StrSubstNo(Text000, FieldCaption("Document Type")));

                if not SalesPostPrepmt.CheckOpenPrepaymentLines("Sales Header", DocumentType) then
                    AddError(DocumentErrorsMgt.GetNothingToPostErrorMsg());

                case DocumentType of
                    DocumentType::Invoice:
                        begin
                            if "Prepayment Due Date" = 0D then
                                AddError(StrSubstNo(Text005, FieldCaption("Prepayment Due Date")));
                            if ("Prepayment No." = '') and ("Prepayment No. Series" = '') then
                                AddError(StrSubstNo(Text005, FieldCaption("Posting No. Series")));
                        end;
                    DocumentType::"Credit Memo":
                        if ("Prepmt. Cr. Memo No." = '') and ("Prepmt. Cr. Memo No. Series" = '') then
                            AddError(StrSubstNo(Text012, FieldCaption("Prepmt. Cr. Memo No.")));
                end;
                if SalesSetup."Ext. Doc. No. Mandatory" and ("External Document No." = '') then
                    AddError(StrSubstNo(Text005, FieldCaption("External Document No.")));

                CheckCust("Sell-to Customer No.", FieldCaption("Sell-to Customer No."));
                CheckCust("Bill-to Customer No.", FieldCaption("Bill-to Customer No."));

                CheckPostingDate("Sales Header");

                DimSetEntry.SetRange("Dimension Set ID", "Dimension Set ID");
                if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                    AddError(DimMgt.GetDimCombErr());

                TableID[1] := Database::Customer;
                No[1] := "Bill-to Customer No.";
                TableID[2] := Database::Job;
                // No[2] := "Job No.";
                TableID[3] := Database::"Salesperson/Purchaser";
                No[3] := "Salesperson Code";
                TableID[4] := Database::Campaign;
                No[4] := "Campaign No.";
                TableID[5] := Database::"Responsibility Center";
                No[5] := "Responsibility Center";
                if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                    AddError(DimMgt.GetDimValuePostingErr());
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrepaymentDocumentType; DocumentType)
                    {
                        ApplicationArea = Prepayments;
                        Caption = 'Prepayment Document Type';
                        OptionCaption = 'Invoice,Credit Memo';
                        ToolTip = 'Specifies whether you want to see test documents for prepayment credit memos or prepayment invoices.';
                    }
                    field(ShowDimensions; ShowDim)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Show Dimensions';
                        ToolTip = 'Specifies if you want dimensions information for the journal lines that you want to include in the report.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        SalesHeaderFilter := "Sales Header".GetFilters();

        GLSetup.Get();
        SalesSetup.Get();

        if DocumentType = DocumentType::Invoice then
            PrepmtDocText := Text013
        else
            PrepmtDocText := Text014;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        GenPostingSetup: Record "General Posting Setup";
        TempSalesLine: Record "Sales Line" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineDeduct: Record "VAT Amount Line" temporary;
        TempPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary;
        TempPrepmtInvLineBuf2: Record "Prepayment Inv. Line Buffer" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        LineDimSetEntry: Record "Dimension Set Entry";
        SalesPostPrepmt: Codeunit "Sales-Post Prepayments";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        DimMgt: Codeunit DimensionManagement;
        SalesHeaderFilter: Text;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 must be Order.';
        Text001: Label 'Sales Document: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        SellToAddr: array[8] of Text[100];
        BillToAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        PrepmtDocText: Text[50];
        TotalText: Text[50];
        TotalExclVATText: Text[50];
        TotalInclVATText: Text[50];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'Total %1';
        Text003: Label 'Total %1 Excl. VAT';
        Text004: Label 'Total %1 Incl. VAT';
#pragma warning restore AA0470
#pragma warning restore AA0074
        DimText: Text[120];
        ErrorText: array[99] of Text[250];
        DocumentType: Option Invoice,"Credit Memo",Statistic;
        VATAmount: Decimal;
        VATBaseAmount: Decimal;
        ErrorCounter: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text005: Label '%1 must be specified.';
        Text006: Label '%1 %2 %3 does not exist.';
        Text007: Label '%1 %2 does not exist.';
        Text008: Label '%1 must not be %2 for %3 %4.';
        Text009: Label '%1 must not be a closing date.';
        Text010: Label '%1 is not within your allowed range of posting dates.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ShowDim: Boolean;
        Continue: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text012: Label '%1 must be entered.';
#pragma warning restore AA0470
        Text013: Label 'Prepayment Invoice';
        Text014: Label 'Prepayment Credit Memo';
#pragma warning restore AA0074
        SumPrepaymInvLineBufferAmount: Decimal;
        SalesPrepmtDocTestCaptionLbl: Label 'Sales Prepayment Document - Test';
        CurrReportPageNoCaptionLbl: Label 'Page';
        SelltoCaptionLbl: Label 'Sell-to';
        ShiptoCaptionLbl: Label 'Ship-to';
        BilltoCaptionLbl: Label 'Bill-to';
        PostDateSalesHeaderCaptionLbl: Label 'Posting Date';
        DocDateSalesHeaderCaptionLbl: Label 'Document Date';
        ShipmentDateSalesHeaderCaptionLbl: Label 'Shipment Date';
        OrderDateSalesHeaderCaptionLbl: Label 'Order Date';
        PrepmtDueDateSalesHeaderCaptionLbl: Label 'Prepayment Due Date';
        PrepmtPmtDiscDateSalesHeaderCaptionLbl: Label 'Prepmt. Pmt. Discount Date';
        HeaderDimensionsCaptionLbl: Label 'Header Dimensions';
        ErrorTextHeaderErrorCounterCaptionLbl: Label 'Warning!';
        LineDimensionsCaptionLbl: Label 'Line Dimensions';
        VATAmtLineVATAmtCaptionLbl: Label 'VAT Amount';
        VATAmtLineVATBaseCaptionLbl: Label 'VAT Base';
        VATAmtLineLineAmtCaptionLbl: Label 'Line Amount';
        VATAmtLineVATCaptionLbl: Label 'VAT %';
        VATAmtLineVATIdentifierCaptionLbl: Label 'VAT Identifier';
        VATAmtSpecificationCaptionLbl: Label 'VAT Amount Specification';
        TotalCaptionLbl: Label 'Total';

    local procedure AddError(Text: Text)
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := CopyStr(Text, 1, MaxStrLen(ErrorText[ErrorCounter]));
    end;

    local procedure CheckCust(CustNo: Code[20]; FieldCaption: Text[30])
    var
        Cust: Record Customer;
    begin
        if CustNo = '' then begin
            AddError(StrSubstNo(Text005, FieldCaption));
            exit;
        end;
        if not Cust.Get(CustNo) then begin
            AddError(StrSubstNo(Text007, Cust.TableCaption(), CustNo));
            exit;
        end;
        if Cust."Privacy Blocked" then
            AddError(Cust.GetPrivacyBlockedGenericErrorText(Cust));
        if Cust.Blocked in [Cust.Blocked::All, Cust.Blocked::Invoice] then
            AddError(
              StrSubstNo(Text008, Cust.FieldCaption(Blocked), Cust.Blocked, Cust.TableCaption(), CustNo));
    end;

    local procedure CheckPostingDate(SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
        PostingDateError: Text[250];
    begin
        IsHandled := false;
        OnBeforeCheckPostingDate(SalesHeader, PostingDateError, IsHandled);
        if IsHandled then begin
            AddError(PostingDateError);
            exit;
        end;

        case true of
            SalesHeader."Posting Date" = 0D:
                AddError(StrSubstNo(Text005, SalesHeader.FieldCaption("Posting Date")));
            SalesHeader."Posting Date" <> NormalDate(SalesHeader."Posting Date"):
                AddError(StrSubstNo(Text009, SalesHeader.FieldCaption("Posting Date")));
            GenJnlCheckLine.DateNotAllowed(SalesHeader."Posting Date", SalesHeader."Journal Templ. Name"):
                AddError(StrSubstNo(Text010, SalesHeader.FieldCaption("Posting Date")));
        end;
    end;

    local procedure MergeText(DimSetEntry: Record "Dimension Set Entry"): Boolean
    begin
        if StrLen(DimText) + StrLen(StrSubstNo('%1 - %2', DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code")) + 2 >
           MaxStrLen(DimText)
        then
            exit(true);

        if DimText = '' then
            DimText := StrSubstNo('%1 - %2', DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code")
        else
            DimText :=
              StrSubstNo('%1; %2', DimText, StrSubstNo('%1 - %2', DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code"));

        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPostingDate(var SalesHeader: Record "Sales Header"; var PostingDateError: Text[250]; var IsHandled: Boolean)
    begin
    end;
}

