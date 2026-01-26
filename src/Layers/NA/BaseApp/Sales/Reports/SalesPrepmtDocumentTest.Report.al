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
            column(Sales_Header_Document_Type; "Document Type")
            {
            }
            column(Sales_Header_No_; "No.")
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(USERID; UserId)
                {
                }
                column(STRSUBSTNO_Text001_SalesHeaderFilter_; StrSubstNo(Text001, SalesHeaderFilter))
                {
                }
                column(SalesHeaderFilter; SalesHeaderFilter)
                {
                }
                column(PrepmtDocText; PrepmtDocText)
                {
                }
                column(FORMAT__Sales_Header___Document_Type____________Sales_Header___No__; Format("Sales Header"."Document Type") + ' ' + "Sales Header"."No.")
                {
                }
                column(Sales_Header___Sell_to_Customer_No__; "Sales Header"."Sell-to Customer No.")
                {
                }
                column(SellToAddr_1_; SellToAddr[1])
                {
                }
                column(SellToAddr_2_; SellToAddr[2])
                {
                }
                column(SellToAddr_3_; SellToAddr[3])
                {
                }
                column(SellToAddr_4_; SellToAddr[4])
                {
                }
                column(SellToAddr_5_; SellToAddr[5])
                {
                }
                column(ShipToAddr_5_; ShipToAddr[5])
                {
                }
                column(ShipToAddr_4_; ShipToAddr[4])
                {
                }
                column(ShipToAddr_3_; ShipToAddr[3])
                {
                }
                column(ShipToAddr_2_; ShipToAddr[2])
                {
                }
                column(ShipToAddr_1_; ShipToAddr[1])
                {
                }
                column(ShipToAddr_6_; ShipToAddr[6])
                {
                }
                column(SellToAddr_6_; SellToAddr[6])
                {
                }
                column(ShipToAddr_7_; ShipToAddr[7])
                {
                }
                column(SellToAddr_7_; SellToAddr[7])
                {
                }
                column(ShipToAddr_8_; ShipToAddr[8])
                {
                }
                column(SellToAddr_8_; SellToAddr[8])
                {
                }
                column(Sales_Header___Ship_to_Code_; "Sales Header"."Ship-to Code")
                {
                }
                column(ShowDim; ShowDim)
                {
                }
                column(DocumentType; DocumentType)
                {
                }
                column(BillToAddr_8_; BillToAddr[8])
                {
                }
                column(BillToAddr_7_; BillToAddr[7])
                {
                }
                column(BillToAddr_6_; BillToAddr[6])
                {
                }
                column(BillToAddr_5_; BillToAddr[5])
                {
                }
                column(BillToAddr_4_; BillToAddr[4])
                {
                }
                column(BillToAddr_3_; BillToAddr[3])
                {
                }
                column(BillToAddr_2_; BillToAddr[2])
                {
                }
                column(BillToAddr_1_; BillToAddr[1])
                {
                }
                column(Sales_Header___Bill_to_Customer_No__; "Sales Header"."Bill-to Customer No.")
                {
                }
                column(Sales_Header___Salesperson_Code_; "Sales Header"."Salesperson Code")
                {
                }
                column(Sales_Header___Your_Reference_; "Sales Header"."Your Reference")
                {
                }
                column(Sales_Header___Prices_Including_VAT_; "Sales Header"."Prices Including VAT")
                {
                }
                column(Sales_Header___Posting_Date_; Format("Sales Header"."Posting Date"))
                {
                }
                column(Sales_Header___Document_Date_; Format("Sales Header"."Document Date"))
                {
                }
                column(Sales_Header___Shipment_Date_; Format("Sales Header"."Shipment Date"))
                {
                }
                column(Sales_Header___Order_Date_; Format("Sales Header"."Order Date"))
                {
                }
                column(Sales_Header___Prepmt__Payment_Terms_Code_; "Sales Header"."Prepmt. Payment Terms Code")
                {
                }
                column(Sales_Header___Shipment_Method_Code_; "Sales Header"."Shipment Method Code")
                {
                }
                column(Sales_Header___Payment_Method_Code_; "Sales Header"."Payment Method Code")
                {
                }
                column(Sales_Header___Prepayment_Due_Date_; Format("Sales Header"."Prepayment Due Date"))
                {
                }
                column(Sales_Header___Prepmt__Pmt__Discount_Date_; Format("Sales Header"."Prepmt. Pmt. Discount Date"))
                {
                }
                column(Sales_Header___Prepmt__Payment_Discount___; "Sales Header"."Prepmt. Payment Discount %")
                {
                }
                column(Sales_Header___Customer_Posting_Group_; "Sales Header"."Customer Posting Group")
                {
                }
                column(Sales_Header___Prepmt__Include_Tax_; Format("Sales Header"."Prepmt. Include Tax"))
                {
                }
                column(SalesHdrPricesIncludingVATFmt; Format("Sales Header"."Prices Including VAT"))
                {
                }
                column(PageCounter_Number; Number)
                {
                }
                column(Sales_Prepayment_Document___TestCaption; Sales_Prepayment_Document___TestCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Sales_Header___Sell_to_Customer_No__Caption; "Sales Header".FieldCaption("Sell-to Customer No."))
                {
                }
                column(Sell_toCaption; Sell_toCaptionLbl)
                {
                }
                column(Ship_toCaption; Ship_toCaptionLbl)
                {
                }
                column(Sales_Header___Ship_to_Code_Caption; "Sales Header".FieldCaption("Ship-to Code"))
                {
                }
                column(Bill_toCaption; Bill_toCaptionLbl)
                {
                }
                column(Sales_Header___Bill_to_Customer_No__Caption; "Sales Header".FieldCaption("Bill-to Customer No."))
                {
                }
                column(Sales_Header___Salesperson_Code_Caption; "Sales Header".FieldCaption("Salesperson Code"))
                {
                }
                column(Sales_Header___Your_Reference_Caption; "Sales Header".FieldCaption("Your Reference"))
                {
                }
                column(Sales_Header___Prices_Including_VAT_Caption; "Sales Header".FieldCaption("Prices Including VAT"))
                {
                }
                column(Sales_Header___Posting_Date_Caption; Sales_Header___Posting_Date_CaptionLbl)
                {
                }
                column(Sales_Header___Document_Date_Caption; Sales_Header___Document_Date_CaptionLbl)
                {
                }
                column(Sales_Header___Shipment_Date_Caption; Sales_Header___Shipment_Date_CaptionLbl)
                {
                }
                column(Sales_Header___Order_Date_Caption; Sales_Header___Order_Date_CaptionLbl)
                {
                }
                column(Sales_Header___Prepmt__Payment_Terms_Code_Caption; "Sales Header".FieldCaption("Prepmt. Payment Terms Code"))
                {
                }
                column(Sales_Header___Prepmt__Payment_Discount___Caption; "Sales Header".FieldCaption("Prepmt. Payment Discount %"))
                {
                }
                column(Sales_Header___Prepayment_Due_Date_Caption; Sales_Header___Prepayment_Due_Date_CaptionLbl)
                {
                }
                column(Sales_Header___Prepmt__Pmt__Discount_Date_Caption; Sales_Header___Prepmt__Pmt__Discount_Date_CaptionLbl)
                {
                }
                column(Sales_Header___Shipment_Method_Code_Caption; "Sales Header".FieldCaption("Shipment Method Code"))
                {
                }
                column(Sales_Header___Payment_Method_Code_Caption; "Sales Header".FieldCaption("Payment Method Code"))
                {
                }
                column(Sales_Header___Customer_Posting_Group_Caption; "Sales Header".FieldCaption("Customer Posting Group"))
                {
                }
                column(Sales_Header___Prepmt__Include_Tax_Caption; Sales_Header___Prepmt__Include_Tax_CaptionLbl)
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
                    column(DimText_Control75; DimText)
                    {
                    }
                    column(Header_DimensionsCaption; Header_DimensionsCaptionLbl)
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
                    column(ErrorText_Number_; ErrorText[Number])
                    {
                    }
                    column(HeaderErrorCounter_Number; Number)
                    {
                    }
                    column(ErrorText_Number_Caption; ErrorText_Number_CaptionLbl)
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
                        column(Sales_Line___Prepmt__Amt__Inv__; "Sales Line"."Prepmt. Amt. Inv.")
                        {
                        }
                        column(Sales_Line___Prepmt__Line_Amount_; "Sales Line"."Prepmt. Line Amount")
                        {
                        }
                        column(Sales_Line___Prepayment___; "Sales Line"."Prepayment %")
                        {
                        }
                        column(Sales_Line___Line_Amount_; "Sales Line"."Line Amount")
                        {
                        }
                        column(Sales_Line__Quantity; "Sales Line".Quantity)
                        {
                        }
                        column(Sales_Line__Description; "Sales Line".Description)
                        {
                        }
                        column(Sales_Line___No__; "Sales Line"."No.")
                        {
                        }
                        column(Sales_Line__Type; Format("Sales Line".Type))
                        {
                        }
                        column(Sales_Line___Line_No__; "Sales Line"."Line No.")
                        {
                        }
                        column(SalesLineLoop_Number; Number)
                        {
                        }
                        column(Sales_Line___Prepmt__Amt__Inv__Caption; "Sales Line".FieldCaption("Prepmt. Amt. Inv."))
                        {
                        }
                        column(Sales_Line___Prepmt__Line_Amount_Caption; "Sales Line".FieldCaption("Prepmt. Line Amount"))
                        {
                        }
                        column(Sales_Line___Prepayment___Caption; "Sales Line".FieldCaption("Prepayment %"))
                        {
                        }
                        column(Sales_Line___Line_Amount_Caption; "Sales Line".FieldCaption("Line Amount"))
                        {
                        }
                        column(Sales_Line__QuantityCaption; "Sales Line".FieldCaption(Quantity))
                        {
                        }
                        column(Sales_Line__DescriptionCaption; "Sales Line".FieldCaption(Description))
                        {
                        }
                        column(Sales_Line___No__Caption; "Sales Line".FieldCaption("No."))
                        {
                        }
                        column(Sales_Line__TypeCaption; "Sales Line".FieldCaption(Type))
                        {
                        }
                        dataitem(LineErrorCounter; "Integer")
                        {
                            DataItemTableView = sorting(Number);
                            column(ErrorText_Number__Control94; ErrorText[Number])
                            {
                            }
                            column(LineErrorCounter_Number; Number)
                            {
                            }
                            column(ErrorText_Number__Control94Caption; ErrorText_Number__Control94CaptionLbl)
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
                                if SalesPostPrepmt.PrepmtAmount("Sales Line", DocumentType, "Sales Header"."Prepmt. Include Tax") <> 0 then begin
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
                        if "Sales Header"."Tax Area Code" = '' then begin  // VAT
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
                        end else begin
                            SalesLine.SetSalesHeader("Sales Header");
                            SalesLine.CalcSalesTaxLines("Sales Header", SalesLine);
                            SalesPostPrepmt.UpdateSalesTaxOnLines(SalesLine, "Sales Header"."Prepmt. Include Tax", DocumentType);
                            if SalesLine.FindSet() then
                                repeat
                                    TempSalesLine := SalesLine;
                                    if DocumentType = DocumentType::"Credit Memo" then
                                        TempSalesLine."Prepmt. Amt. Inv." := TempSalesLine."Prepmt. Line Amount";
                                    TempSalesLine.Insert();
                                until SalesLine.Next() = 0;
                        end;
                    end;
                }
                dataitem(Blank; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                }
                dataitem(PrepmtLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(Prepayment_Inv__Line_Buffer___G_L_Account_No__; "Prepayment Inv. Line Buffer"."G/L Account No.")
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer__Amount; "Prepayment Inv. Line Buffer".Amount)
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer__Description; "Prepayment Inv. Line Buffer".Description)
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer___VAT_Amount_; "Prepayment Inv. Line Buffer"."VAT Amount")
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer___VAT___; "Prepayment Inv. Line Buffer"."VAT %")
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer___VAT_Identifier_; "Prepayment Inv. Line Buffer"."VAT Identifier")
                    {
                    }
                    column(PrepmtLoop_PrepmtLoop_Number; Number)
                    {
                    }
                    column(TotalText; TotalText)
                    {
                    }
                    column(Sales_Header___Currency_Code_; "Prepayment Inv. Line Buffer".Amount)
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(TotalExclVATText; TotalExclVATText)
                    {
                    }
                    column(VATAmountLine_VATAmountText; TempVATAmountLine.VATAmountText())
                    {
                    }
                    column(TotalInclVATText; TotalInclVATText)
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer__Amount_Control115; "Prepayment Inv. Line Buffer".Amount)
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmount; VATAmount)
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Prepayment_Inv__Line_Buffer__Amount___VATAmount; "Prepayment Inv. Line Buffer".Amount + VATAmount)
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(SumPrepaymInvLineBufferAmount; SumPrepaymInvLineBufferAmount)
                    {
                    }
                    column(TotalInclVATText_Control118; TotalInclVATText)
                    {
                    }
                    column(VATAmountLine_VATAmountText_Control119; TempVATAmountLine.VATAmountText())
                    {
                    }
                    column(TotalExclVATText_Control120; TotalExclVATText)
                    {
                    }
                    column(VATBaseAmount___VATAmount; VATBaseAmount + VATAmount)
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmount_Control122; VATAmount)
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATBaseAmount; VATBaseAmount)
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Prepayment_Inv__Line_Buffer___G_L_Account_No__Caption; "Prepayment Inv. Line Buffer".FieldCaption("G/L Account No."))
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer__AmountCaption; "Prepayment Inv. Line Buffer".FieldCaption(Amount))
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer__DescriptionCaption; "Prepayment Inv. Line Buffer".FieldCaption(Description))
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer___VAT_Amount_Caption; "Prepayment Inv. Line Buffer".FieldCaption("VAT Amount"))
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer___VAT___Caption; "Prepayment Inv. Line Buffer".FieldCaption("VAT %"))
                    {
                    }
                    column(Prepayment_Inv__Line_Buffer___VAT_Identifier_Caption; "Prepayment Inv. Line Buffer".FieldCaption("VAT Identifier"))
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
                        column(DimText_Control97; DimText)
                        {
                        }
                        column(LineDimLoop_Number; Number)
                        {
                        }
                        column(DimText_Control99; DimText)
                        {
                        }
                        column(Line_DimensionsCaption; Line_DimensionsCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not LineDimSetEntry.Find('-') then
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
                        column(ErrorText_Number__Control128; ErrorText[Number])
                        {
                        }
                        column(PrepmtErrorCounter_Number; Number)
                        {
                        }
                        column(ErrorText_Number__Control128Caption; ErrorText_Number__Control128CaptionLbl)
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
                    column(VATAmountLine__VAT_Amount_; TempVATAmountLine."VAT Amount")
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT_Base_; TempVATAmountLine."VAT Base")
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__Line_Amount_; TempVATAmountLine."Line Amount")
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT_Amount__Control134; TempVATAmountLine."VAT Amount")
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT_Base__Control135; TempVATAmountLine."VAT Base")
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__Line_Amount__Control138; TempVATAmountLine."Line Amount")
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT___; TempVATAmountLine."VAT %")
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(VATAmountLine__VAT_Identifier_; TempVATAmountLine."VAT Identifier")
                    {
                    }
                    column(VATAmountLine__VAT_Amount__Control147; TempVATAmountLine."VAT Amount")
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT_Base__Control148; TempVATAmountLine."VAT Base")
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__Line_Amount__Control151; TempVATAmountLine."Line Amount")
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT_Amount__Control153; TempVATAmountLine."VAT Amount")
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT_Base__Control154; TempVATAmountLine."VAT Base")
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__Line_Amount__Control157; TempVATAmountLine."Line Amount")
                    {
                        AutoFormatExpression = "Sales Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATCounter_Number; Number)
                    {
                    }
                    column(VATAmountLine__VAT_Amount__Control134Caption; VATAmountLine__VAT_Amount__Control134CaptionLbl)
                    {
                    }
                    column(VATAmountLine__VAT_Base__Control135Caption; VATAmountLine__VAT_Base__Control135CaptionLbl)
                    {
                    }
                    column(VATAmountLine__Line_Amount__Control138Caption; VATAmountLine__Line_Amount__Control138CaptionLbl)
                    {
                    }
                    column(VATAmountLine__VAT___Caption; VATAmountLine__VAT___CaptionLbl)
                    {
                    }
                    column(VATAmountLine__VAT_Identifier_Caption; VATAmountLine__VAT_Identifier_CaptionLbl)
                    {
                    }
                    column(VAT_Amount_SpecificationCaption; VAT_Amount_SpecificationCaptionLbl)
                    {
                    }
                    column(ContinuedCaption; ContinuedCaptionLbl)
                    {
                    }
                    column(ContinuedCaption_Control152; ContinuedCaption_Control152Lbl)
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
        SalesLine: Record "Sales Line";
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
        Sales_Prepayment_Document___TestCaptionLbl: Label 'Sales Prepayment Document - Test';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Sell_toCaptionLbl: Label 'Sell-to';
        Ship_toCaptionLbl: Label 'Ship-to';
        Bill_toCaptionLbl: Label 'Bill-to';
        Sales_Header___Posting_Date_CaptionLbl: Label 'Posting Date';
        Sales_Header___Document_Date_CaptionLbl: Label 'Document Date';
        Sales_Header___Shipment_Date_CaptionLbl: Label 'Shipment Date';
        Sales_Header___Order_Date_CaptionLbl: Label 'Order Date';
        Sales_Header___Prepayment_Due_Date_CaptionLbl: Label 'Prepayment Due Date';
        Sales_Header___Prepmt__Pmt__Discount_Date_CaptionLbl: Label 'Prepmt. Pmt. Discount Date';
        Sales_Header___Prepmt__Include_Tax_CaptionLbl: Label 'Prepmt. Include Tax';
        Header_DimensionsCaptionLbl: Label 'Header Dimensions';
        ErrorText_Number_CaptionLbl: Label 'Warning!';
        ErrorText_Number__Control94CaptionLbl: Label 'Warning!';
        Line_DimensionsCaptionLbl: Label 'Line Dimensions';
        ErrorText_Number__Control128CaptionLbl: Label 'Warning!';
        VATAmountLine__VAT_Amount__Control134CaptionLbl: Label 'VAT Amount';
        VATAmountLine__VAT_Base__Control135CaptionLbl: Label 'VAT Base';
        VATAmountLine__Line_Amount__Control138CaptionLbl: Label 'Line Amount';
        VATAmountLine__VAT___CaptionLbl: Label 'VAT %';
        VATAmountLine__VAT_Identifier_CaptionLbl: Label 'VAT Identifier';
        VAT_Amount_SpecificationCaptionLbl: Label 'VAT Amount Specification';
        ContinuedCaptionLbl: Label 'Continued';
        ContinuedCaption_Control152Lbl: Label 'Continued';
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

