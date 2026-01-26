// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.CRM.Contact;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Address;
using Microsoft.Sales.Customer;
using System.Security.User;
using System.Utilities;

report 123 "Finance Charge Memo - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/FinanceCharge/FinanceChargeMemoTest.rdlc';
    Caption = 'Finance Charge Memo - Test';
    WordMergeDataItem = "Finance Charge Memo Header";

    dataset
    {
        dataitem("Finance Charge Memo Header"; "Finance Charge Memo Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Finance Charge Memo';
            column(ContactPhoneNoLbl; ContactPhoneNoLbl)
            {
            }
            column(ContactMobilePhoneNoLbl; ContactMobilePhoneNoLbl)
            {
            }
            column(ContactEmailLbl; ContactEmailLbl)
            {
            }
            column(ContactPhoneNo; PrimaryContact."Phone No.")
            {
            }
            column(ContactMobilePhoneNo; PrimaryContact."Mobile Phone No.")
            {
            }
            column(ContactEmail; PrimaryContact."E-mail")
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(TODAY; Today)
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(PageCaption; StrSubstNo(Text007, ' '))
                {
                }
                column(Fin_Charge_Memo_Header___No__; "Finance Charge Memo Header"."No.")
                {
                }
                column(STRSUBSTNO_Text008_FinChrgMemoHeaderFilter_; StrSubstNo(Text008, FinChrgMemoHeaderFilter))
                {
                }
                column(FinChrgMemoHeaderFilter; FinChrgMemoHeaderFilter)
                {
                }
                column(STRSUBSTNO___1__2___Finance_Charge_Memo_Header___No___Cust_Name_; StrSubstNo('%1 %2', "Finance Charge Memo Header"."No.", Cust.Name))
                {
                }
                column(CustAddr_8_; CustAddr[8])
                {
                }
                column(CustAddr_7_; CustAddr[7])
                {
                }
                column(CustAddr_6_; CustAddr[6])
                {
                }
                column(CustAddr_5_; CustAddr[5])
                {
                }
                column(CustAddr_4_; CustAddr[4])
                {
                }
                column(CustAddr_3_; CustAddr[3])
                {
                }
                column(CustAddr_2_; CustAddr[2])
                {
                }
                column(CustAddr_1_; CustAddr[1])
                {
                }
                column(Finance_Charge_Memo_Header___Customer_No__; "Finance Charge Memo Header"."Customer No.")
                {
                }
                column(Finance_Charge_Memo_Header___Document_Date_; Format("Finance Charge Memo Header"."Document Date"))
                {
                }
                column(Finance_Charge_Memo_Header___Posting_Date_; Format("Finance Charge Memo Header"."Posting Date"))
                {
                }
                column(Finance_Charge_Memo_Header___VAT_Registration_No__; "Finance Charge Memo Header"."VAT Registration No.")
                {
                }
                column(Finance_Charge_Memo_Header___Your_Reference_; "Finance Charge Memo Header"."Your Reference")
                {
                }
                column(Finance_Charge_Memo_Header___Due_Date_; Format("Finance Charge Memo Header"."Due Date"))
                {
                }
                column(Finance_Charge_Memo_Header___Post_Additional_Fee_; Format("Finance Charge Memo Header"."Post Additional Fee"))
                {
                }
                column(Finance_Charge_Memo_Header___Post_Interest_; Format("Finance Charge Memo Header"."Post Interest"))
                {
                }
                column(Finance_Charge_Memo_Header___Fin__Charge_Terms_Code_; "Finance Charge Memo Header"."Fin. Charge Terms Code")
                {
                }
                column(ReferenceText; ReferenceText)
                {
                }
                column(VATNoText; VATNoText)
                {
                }
                column(FORMAT_Cust__Tax_Identification_Type__; Format(Cust."Tax Identification Type"))
                {
                }
                column(Finance_Charge_Memo___TestCaption; Finance_Charge_Memo___TestCaptionLbl)
                {
                }
                column(Finance_Charge_Memo_Header___Customer_No__Caption; "Finance Charge Memo Header".FieldCaption("Customer No."))
                {
                }
                column(Finance_Charge_Memo_Header___Document_Date_Caption; Finance_Charge_Memo_Header___Document_Date_CaptionLbl)
                {
                }
                column(Finance_Charge_Memo_Header___Posting_Date_Caption; Finance_Charge_Memo_Header___Posting_Date_CaptionLbl)
                {
                }
                column(Finance_Charge_Memo_Header___Due_Date_Caption; Finance_Charge_Memo_Header___Due_Date_CaptionLbl)
                {
                }
                column(Finance_Charge_Memo_Header___Post_Additional_Fee_Caption; CaptionClassTranslate("Finance Charge Memo Header".FieldCaption("Post Additional Fee")))
                {
                }
                column(Finance_Charge_Memo_Header___Post_Interest_Caption; CaptionClassTranslate("Finance Charge Memo Header".FieldCaption("Post Interest")))
                {
                }
                column(Finance_Charge_Memo_Header___Fin__Charge_Terms_Code_Caption; "Finance Charge Memo Header".FieldCaption("Fin. Charge Terms Code"))
                {
                }
                column(Tax_Ident__TypeCaption; Tax_Ident__TypeCaptionLbl)
                {
                }
                dataitem(DimensionLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(DimText; DimText)
                    {
                    }
                    column(DimensionLoop_Number; Number)
                    {
                    }
                    column(Header_DimensionsCaption; Header_DimensionsCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            if not DimSetEntry.FindSet() then
                                CurrReport.Break();
                        end else
                            if not Continue then
                                CurrReport.Break();

                        Clear(DimText);
                        repeat
                            OldDimText := DimText;
                            if DimText = '' then
                                DimText := StrSubstNo('%1 - %2', DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code")
                            else
                                DimText :=
                                  StrSubstNo(
                                    '%1; %2 - %3', DimText, DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
                            if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                DimText := OldDimText;
                                exit;
                            end;
                        until DimSetEntry.Next() = 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not ShowDim then
                            CurrReport.Break();
                        DimSetEntry.SetRange("Dimension Set ID", "Finance Charge Memo Header"."Dimension Set ID");
                    end;
                }
                dataitem(HeaderErrorCounter; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(ErrorText_Number_; ErrorText[Number])
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
                dataitem(BeginningText; "Finance Charge Memo Line")
                {
                    DataItemLink = "Finance Charge Memo No." = field("No.");
                    DataItemLinkReference = "Finance Charge Memo Header";
                    DataItemTableView = sorting("Finance Charge Memo No.", "Line No.");
                    column(BeginningText_Description; Description)
                    {
                    }
                    column(StartLineNo; StartLineNo)
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        if Find('-') then begin
                            StartLineNo := 0;
                            repeat
                                Continue := Type = Type::" ";
                                if Continue and (Description <> '') then
                                    StartLineNo := "Line No.";
                            until (Next() = 0) or not Continue;
                        end;
                        SetRange("Line No.", 0, StartLineNo);
                    end;
                }
                dataitem("Finance Charge Memo Line"; "Finance Charge Memo Line")
                {
                    DataItemLink = "Finance Charge Memo No." = field("No.");
                    DataItemLinkReference = "Finance Charge Memo Header";
                    DataItemTableView = sorting("Finance Charge Memo No.", "Line No.");
                    column(ShowFinChMemoLine1; ("Line No." > StartLineNo) and (Type = Type::"Customer Ledger Entry"))
                    {
                    }
                    column(ShowFinChMemoLine2; ("Line No." > StartLineNo) and (Type <> Type::"Customer Ledger Entry"))
                    {
                    }
                    column(TotalVatAmount; TotalVatAmount)
                    {
                    }
                    column(TotalAmount; TotalAmount)
                    {
                    }
                    column(Finance_Charge_Memo_Line__Document_No__; "Document No.")
                    {
                    }
                    column(Finance_Charge_Memo_Line_Description; Description)
                    {
                    }
                    column(Finance_Charge_Memo_Line__Original_Amount_; "Original Amount")
                    {
                    }
                    column(Finance_Charge_Memo_Line__Remaining_Amount_; "Remaining Amount")
                    {
                    }
                    column(Finance_Charge_Memo_Line__Document_Date_; Format("Document Date"))
                    {
                    }
                    column(Finance_Charge_Memo_Line_Amount; Amount)
                    {
                        AutoFormatExpression = GetCurrencyCode();
                        AutoFormatType = 1;
                    }
                    column(Finance_Charge_Memo_Line__Due_Date_; Format("Due Date"))
                    {
                    }
                    column(Finance_Charge_Memo_Line__Document_Type_; "Document Type")
                    {
                    }
                    column(Finance_Charge_Memo_Line_Amount_Control61; Amount)
                    {
                        AutoFormatExpression = GetCurrencyCode();
                        AutoFormatType = 1;
                    }
                    column(FinChMemo_Line___Line_No__; "Line No.")
                    {
                    }
                    column(Finance_Charge_Memo_Line_Amount_Control29; Amount)
                    {
                        AutoFormatExpression = GetCurrencyCode();
                        AutoFormatType = 1;
                    }
                    column(TotalText; TotalText)
                    {
                    }
                    column(Finance_Charge_Memo_Line__VAT_Amount_; "VAT Amount")
                    {
                        AutoFormatExpression = GetCurrencyCode();
                        AutoFormatType = 1;
                    }
                    column(TotalInclVATText; TotalInclVATText)
                    {
                    }
                    column(Amount____VAT_Amount_; Amount + "VAT Amount")
                    {
                        AutoFormatExpression = GetCurrencyCode();
                        AutoFormatType = 1;
                    }
                    column(Finance_Charge_Memo_Line_DescriptionCaption; FieldCaption(Description))
                    {
                    }
                    column(Finance_Charge_Memo_Line__Original_Amount_Caption; FieldCaption("Original Amount"))
                    {
                    }
                    column(Finance_Charge_Memo_Line__Remaining_Amount_Caption; FieldCaption("Remaining Amount"))
                    {
                    }
                    column(Finance_Charge_Memo_Line__Document_No__Caption; FieldCaption("Document No."))
                    {
                    }
                    column(Finance_Charge_Memo_Line__Document_Date_Caption; Finance_Charge_Memo_Line__Document_Date_CaptionLbl)
                    {
                    }
                    column(Finance_Charge_Memo_Line_AmountCaption; FieldCaption(Amount))
                    {
                    }
                    column(Finance_Charge_Memo_Line__Due_Date_Caption; Finance_Charge_Memo_Line__Due_Date_CaptionLbl)
                    {
                    }
                    column(Finance_Charge_Memo_Line__Document_Type_Caption; FieldCaption("Document Type"))
                    {
                    }
                    column(Finance_Charge_Memo_Line__VAT_Amount_Caption; FieldCaption("VAT Amount"))
                    {
                    }
                    column(MulIntRateEntry_FinChrgMemoLine; "Detailed Interest Rates Entry")
                    {
                    }
                    column(ShowMIRLines; ShowMIRLines)
                    {
                    }
                    dataitem(LineErrorCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(ErrorText_Number__Control97; ErrorText[Number])
                        {
                        }
                        column(ErrorText_Number__Control97Caption; ErrorText_Number__Control97CaptionLbl)
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
                    begin
                        if not "Detailed Interest Rates Entry" then begin
                            TempVATAmountLine.Init();
                            TempVATAmountLine."VAT Identifier" := "VAT Identifier";
                            TempVATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                            TempVATAmountLine."Tax Group Code" := "Tax Group Code";
                            TempVATAmountLine."VAT %" := "VAT %";
                            TempVATAmountLine."VAT Base" := Amount;
                            TempVATAmountLine."VAT Amount" := "VAT Amount";
                            TempVATAmountLine."Amount Including VAT" := Amount + "VAT Amount";
                            TempVATAmountLine.InsertLine();

                            case Type of
                                Type::"Customer Ledger Entry":
                                    if Amount < 0 then
                                        AddError(
                                            StrSubstNo(
                                            Text009,
                                            FieldCaption(Amount)));
                            end;

                            TotalAmount += Amount;
                            TotalVatAmount += "VAT Amount";
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if Find('+') then begin
                            EndLineNo := "Line No." + 1;
                            repeat
                                Continue := Type = Type::" ";
                                if Continue and (Description <> '') then
                                    EndLineNo := "Line No.";
                            until (Next(-1) = 0) or not Continue;
                        end;
                        SetRange("Line No.", StartLineNo + 1, EndLineNo - 1);
                        TempVATAmountLine.DeleteAll();

                        TotalAmount := 0;
                        TotalVatAmount := 0;
                    end;
                }
                dataitem(ReminderLine2; "Finance Charge Memo Line")
                {
                    DataItemLink = "Finance Charge Memo No." = field("No.");
                    DataItemLinkReference = "Finance Charge Memo Header";
                    DataItemTableView = sorting("Finance Charge Memo No.", "Line No.");
                    column(ReminderLine2_Description; Description)
                    {
                    }
                    column(ReminderLine2__Line_No__; "Line No.")
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Line No.", '>=%1', EndLineNo);
                    end;
                }
                dataitem(VATCounter; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(VATAmountLine__VAT_Amount_; TempVATAmountLine."VAT Amount")
                    {
                        AutoFormatExpression = "Finance Charge Memo Line".GetCurrencyCode();
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT_Base_; TempVATAmountLine."VAT Base")
                    {
                        AutoFormatExpression = "Finance Charge Memo Line".GetCurrencyCode();
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__Amount_Including_VAT_; TempVATAmountLine."Amount Including VAT")
                    {
                        AutoFormatExpression = "Finance Charge Memo Line".GetCurrencyCode();
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT_Amount__Control55; TempVATAmountLine."VAT Amount")
                    {
                        AutoFormatExpression = "Finance Charge Memo Line".GetCurrencyCode();
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT_Base__Control56; TempVATAmountLine."VAT Base")
                    {
                        AutoFormatExpression = "Finance Charge Memo Line".GetCurrencyCode();
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT___; TempVATAmountLine."VAT %")
                    {
                    }
                    column(VATAmountLine__Amount_Including_VAT__Control73; TempVATAmountLine."Amount Including VAT")
                    {
                        AutoFormatExpression = "Finance Charge Memo Line".GetCurrencyCode();
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT_Amount__Control45; TempVATAmountLine."VAT Amount")
                    {
                        AutoFormatExpression = "Finance Charge Memo Line".GetCurrencyCode();
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT_Base__Control49; TempVATAmountLine."VAT Base")
                    {
                        AutoFormatExpression = "Finance Charge Memo Line".GetCurrencyCode();
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__Amount_Including_VAT__Control80; TempVATAmountLine."Amount Including VAT")
                    {
                        AutoFormatExpression = "Finance Charge Memo Line".GetCurrencyCode();
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT_Amount__Control55Caption; VATAmountLine__VAT_Amount__Control55CaptionLbl)
                    {
                    }
                    column(VATAmountLine__VAT_Base__Control56Caption; VATAmountLine__VAT_Base__Control56CaptionLbl)
                    {
                    }
                    column(VAT_Amount_SpecificationCaption; VAT_Amount_SpecificationCaptionLbl)
                    {
                    }
                    column(VATAmountLine__VAT___Caption; VATAmountLine__VAT___CaptionLbl)
                    {
                    }
                    column(VATAmountLine__Amount_Including_VAT__Control73Caption; VATAmountLine__Amount_Including_VAT__Control73CaptionLbl)
                    {
                    }
                    column(VATAmountLine__VAT_Base__Control49Caption; VATAmountLine__VAT_Base__Control49CaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        TempVATAmountLine.GetLine(Number);
                    end;

                    trigger OnPreDataItem()
                    begin
                        if TotalVatAmount = 0 then
                            CurrReport.Break();
                        SetRange(Number, 1, TempVATAmountLine.Count);
                    end;
                }
                dataitem(VATCounterLCY; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(VALExchRate; VALExchRate)
                    {
                    }
                    column(VALSpecLCYHeader; VALSpecLCYHeader)
                    {
                    }
                    column(VALVATAmountLCY; VALVATAmountLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VALVATBaseLCY; VALVATBaseLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VALVATAmountLCY_Control92; VALVATAmountLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VALVATBaseLCY_Control93; VALVATBaseLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT____Control94; TempVATAmountLine."VAT %")
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(VALVATAmountLCY_Control101; VALVATAmountLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VALVATBaseLCY_Control102; VALVATBaseLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VALVATAmountLCY_Control92Caption; VALVATAmountLCY_Control92CaptionLbl)
                    {
                    }
                    column(VALVATBaseLCY_Control93Caption; VALVATBaseLCY_Control93CaptionLbl)
                    {
                    }
                    column(VATAmountLine__VAT____Control94Caption; VATAmountLine__VAT____Control94CaptionLbl)
                    {
                    }
                    column(VALVATBaseLCY_Control102Caption; VALVATBaseLCY_Control102CaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        TempVATAmountLine.GetLine(Number);

                        VALVATBaseLCY := Round(CurrExchRate.ExchangeAmtFCYToLCY(
                              "Finance Charge Memo Header"."Posting Date", "Finance Charge Memo Header"."Currency Code",
                              TempVATAmountLine."VAT Base", CurrFactor));
                        VALVATAmountLCY := Round(CurrExchRate.ExchangeAmtFCYToLCY(
                              "Finance Charge Memo Header"."Posting Date", "Finance Charge Memo Header"."Currency Code",
                              TempVATAmountLine."VAT Amount", CurrFactor));
                    end;

                    trigger OnPreDataItem()
                    begin
                        if (not GLSetup."Print VAT specification in LCY") or
                           ("Finance Charge Memo Header"."Currency Code" = '') or
                           (TempVATAmountLine.GetTotalVATAmount() = 0)
                        then
                            CurrReport.Break();

                        SetRange(Number, 1, TempVATAmountLine.Count);
                        Clear(VALVATBaseLCY);
                        Clear(VALVATAmountLCY);

                        if GLSetup."LCY Code" = '' then
                            VALSpecLCYHeader := Text011 + Text012
                        else
                            VALSpecLCYHeader := Text011 + Format(GLSetup."LCY Code");

                        CurrExchRate.FindCurrency("Finance Charge Memo Header"."Posting Date", "Finance Charge Memo Header"."Currency Code", 1);
                        VALExchRate := StrSubstNo(Text013, CurrExchRate."Relational Exch. Rate Amount", CurrExchRate."Exchange Rate Amount");
                        CurrFactor := CurrExchRate.ExchangeRate("Finance Charge Memo Header"."Posting Date",
                            "Finance Charge Memo Header"."Currency Code");
                    end;
                }
            }

            trigger OnAfterGetRecord()
            var
                UserSetupManagement: Codeunit "User Setup Management";
                TempErrorText: Text[250];
            begin
                CalcFields("Remaining Amount");
                if "Customer No." = '' then
                    AddError(StrSubstNo(Text000, FieldCaption("Customer No.")))
                else
                    if Cust.Get("Customer No.") then begin
                        if Cust."Privacy Blocked" then
                            AddError(Cust.GetPrivacyBlockedGenericErrorText(Cust));
                        if Cust.Blocked = Cust.Blocked::All then
                            AddError(
                              StrSubstNo(
                                Text010,
                                Cust.FieldCaption(Blocked), Cust.Blocked, Cust.TableCaption(), "Customer No."));
                        if Cust."Currency Code" <> "Currency Code" then
                            if Cust."Currency Code" <> '' then
                                AddError(
                                  StrSubstNo(
                                    Text002,
                                    FieldCaption("Currency Code"), Cust."Currency Code"))
                            else
                                AddError(
                                  StrSubstNo(
                                    Text002,
                                    FieldCaption("Currency Code"), GLSetup."LCY Code"));
                    end else
                        AddError(
                          StrSubstNo(
                            Text003,
                            Cust.TableCaption(), "Customer No."));

                GLSetup.Get();

                if "Posting Date" = 0D then
                    AddError(StrSubstNo(Text000, FieldCaption("Posting Date")))
                else
                    if not UserSetupManagement.TestAllowedPostingDate("Posting Date", TempErrorText) then
                        AddError(TempErrorText);

                if "Document Date" = 0D then
                    AddError(StrSubstNo(Text000, FieldCaption("Document Date")));
                if "Due Date" = 0D then
                    AddError(StrSubstNo(Text000, FieldCaption("Due Date")));
                if "Customer Posting Group" = '' then
                    AddError(StrSubstNo(Text000, FieldCaption("Customer Posting Group")));
                if "Currency Code" = '' then begin
                    GLSetup.TestField("LCY Code");
                    TotalText := StrSubstNo(Text005, GLSetup."LCY Code");
                    TotalInclVATText := StrSubstNo(Text006, GLSetup."LCY Code");
                end else begin
                    TotalText := StrSubstNo(Text005, "Currency Code");
                    TotalInclVATText := StrSubstNo(Text006, "Currency Code");
                end;
                FormatAddr.FinanceChargeMemo(CustAddr, "Finance Charge Memo Header");
                if "Your Reference" = '' then
                    ReferenceText := ''
                else
                    ReferenceText := FieldCaption("Your Reference");
                if "VAT Registration No." = '' then
                    VATNoText := ''
                else
                    VATNoText := FieldCaption("VAT Registration No.");
                if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                    AddError(DimMgt.GetDimCombErr());
                Cust.GetPrimaryContact("Customer No.", PrimaryContact);

                TableID[1] := DATABASE::Customer;
                No[1] := "Customer No.";
                if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                    AddError(DimMgt.GetDimValuePostingErr());
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShowDimensions; ShowDim)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Show Dimensions';
                        ToolTip = 'Specifies if you want dimensions information for the journal lines to be included in the report.';
                    }
                    field(ShowMIR; ShowMIRLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show MIR Details';
                        ToolTip = 'Specifies if you want multiple interest rate details for the journal lines to be included in the report.';
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

    trigger OnInitReport()
    begin
        GLSetup.Get();
    end;

    trigger OnPreReport()
    begin
        FinChrgMemoHeaderFilter := "Finance Charge Memo Header".GetFilters();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        PrimaryContact: Record Contact;
        Cust: Record Customer;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        CurrExchRate: Record "Currency Exchange Rate";
        DimMgt: Codeunit DimensionManagement;
        FormatAddr: Codeunit "Format Address";
        CustAddr: array[8] of Text[100];
        FinChrgMemoHeaderFilter: Text;
        StartLineNo: Integer;
        EndLineNo: Integer;
        Continue: Boolean;
        VATNoText: Text[80];
        ReferenceText: Text[80];
        TotalText: Text[50];
        TotalInclVATText: Text[50];
        ErrorCounter: Integer;
        ErrorText: array[99] of Text[250];
        DimText: Text[120];
        OldDimText: Text[75];
        ShowDim: Boolean;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text010: Label '%1 must not be %2 for %3 %4.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        VALVATBaseLCY: Decimal;
        VALVATAmountLCY: Decimal;
        VALSpecLCYHeader: Text[80];
        VALExchRate: Text[50];

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 must be specified.';
        Text002: Label '%1 must be %2.';
        Text003: Label '%1 %2 does not exist.';
        Text005: Label 'Total %1';
        Text006: Label 'Total %1 Incl. VAT';
        Text007: Label 'Page %1';
        Text008: Label 'Finance Charge Memo: %1';
        Text009: Label '%1 must be positive or 0.';
#pragma warning restore AA0470
        Text011: Label 'VAT Amount Specification in ';
        Text012: Label 'Local Currency';
#pragma warning disable AA0470
        Text013: Label 'Exchange rate: %1/%2';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CurrFactor: Decimal;
        TotalAmount: Decimal;
        TotalVatAmount: Decimal;
        Finance_Charge_Memo___TestCaptionLbl: Label 'Finance Charge Memo - Test';
        Finance_Charge_Memo_Header___Document_Date_CaptionLbl: Label 'Document Date';
        Finance_Charge_Memo_Header___Posting_Date_CaptionLbl: Label 'Posting Date';
        Finance_Charge_Memo_Header___Due_Date_CaptionLbl: Label 'Due Date';
        Tax_Ident__TypeCaptionLbl: Label 'Tax Ident. Type';
        Header_DimensionsCaptionLbl: Label 'Header Dimensions';
        ErrorText_Number_CaptionLbl: Label 'Warning!';
        Finance_Charge_Memo_Line__Document_Date_CaptionLbl: Label 'Document Date';
        Finance_Charge_Memo_Line__Due_Date_CaptionLbl: Label 'Due Date';
        ErrorText_Number__Control97CaptionLbl: Label 'Warning!';
        VATAmountLine__VAT_Amount__Control55CaptionLbl: Label 'VAT Amount';
        VATAmountLine__VAT_Base__Control56CaptionLbl: Label 'VAT Base';
        VAT_Amount_SpecificationCaptionLbl: Label 'VAT Amount Specification';
        VATAmountLine__VAT___CaptionLbl: Label 'VAT %';
        VATAmountLine__Amount_Including_VAT__Control73CaptionLbl: Label 'Amount Including VAT';
        VATAmountLine__VAT_Base__Control49CaptionLbl: Label 'Total';
        VALVATAmountLCY_Control92CaptionLbl: Label 'VAT Amount';
        VALVATBaseLCY_Control93CaptionLbl: Label 'VAT Base';
        VATAmountLine__VAT____Control94CaptionLbl: Label 'VAT %';
        VALVATBaseLCY_Control102CaptionLbl: Label 'Total';
        ContactPhoneNoLbl: Label 'Contact Phone No.';
        ContactMobilePhoneNoLbl: Label 'Contact Mobile Phone No.';
        ContactEmailLbl: Label 'Contact E-Mail';
        ShowMIRLines: Boolean;

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    procedure InitializeRequest(NewShowDim: Boolean)
    begin
        ShowDim := NewShowDim;
    end;
}

