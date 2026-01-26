// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Vendor;
using System.Security.User;
using System.Utilities;

report 5005272 "Delivery Reminder - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Document/DeliveryReminderTest.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Delivery Reminder - Test';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Delivery Reminder Header"; "Delivery Reminder Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Delivery Reminder';
            column(Delivery_Reminder_Header_No_; "No.")
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
                column(USERID; UserId)
                {
                }
                column(Text1140006___ReminderHeaderFilter; Text1140006 + ReminderHeaderFilter)
                {
                }
                column(ReminderHeaderFilter; ReminderHeaderFilter)
                {
                }
                column(Delivery_Reminder_Header___No___________Vend_Name; "Delivery Reminder Header"."No." + ' ' + Vend.Name)
                {
                }
                column(VendAddr_8_; VendAddr[8])
                {
                }
                column(VendAddr_7_; VendAddr[7])
                {
                }
                column(VendAddr_6_; VendAddr[6])
                {
                }
                column(VendAddr_5_; VendAddr[5])
                {
                }
                column(VendAddr_4_; VendAddr[4])
                {
                }
                column(VendAddr_3_; VendAddr[3])
                {
                }
                column(VendAddr_2_; VendAddr[2])
                {
                }
                column(VendAddr_1_; VendAddr[1])
                {
                }
                column(Delivery_Reminder_Header___Reminder_Terms_Code_; "Delivery Reminder Header"."Reminder Terms Code")
                {
                }
                column(Delivery_Reminder_Header___Reminder_Level_; "Delivery Reminder Header"."Reminder Level")
                {
                }
                column(Delivery_Reminder_Header___Document_Date_; Format("Delivery Reminder Header"."Document Date"))
                {
                }
                column(Delivery_Reminder_Header___Posting_Date_; Format("Delivery Reminder Header"."Posting Date"))
                {
                }
                column(Delivery_Reminder_Header___Your_Reference_; "Delivery Reminder Header"."Your Reference")
                {
                }
                column(Delivery_Reminder_Header___Vendor_No__; "Delivery Reminder Header"."Vendor No.")
                {
                }
                column(ReferenceText; ReferenceText)
                {
                }
                column(PageCounter_Number; Number)
                {
                }
                column(Delivery_Reminder___TestCaption; Delivery_Reminder___TestCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Delivery_Reminder_Header___Reminder_Terms_Code_Caption; "Delivery Reminder Header".FieldCaption("Reminder Terms Code"))
                {
                }
                column(Delivery_Reminder_Header___Reminder_Level_Caption; "Delivery Reminder Header".FieldCaption("Reminder Level"))
                {
                }
                column(Delivery_Reminder_Header___Document_Date_Caption; Delivery_Reminder_Header___Document_Date_CaptionLbl)
                {
                }
                column(Delivery_Reminder_Header___Posting_Date_Caption; Delivery_Reminder_Header___Posting_Date_CaptionLbl)
                {
                }
                column(Delivery_Reminder_Header___Vendor_No__Caption; "Delivery Reminder Header".FieldCaption("Vendor No."))
                {
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
                dataitem("Delivery Reminder Line"; "Delivery Reminder Line")
                {
                    DataItemLink = "Document No." = field("No.");
                    DataItemLinkReference = "Delivery Reminder Header";
                    DataItemTableView = sorting("Document No.", "Line No.");
                    column(Delivery_Reminder_Line_Description; Description)
                    {
                    }
                    column(Delivery_Reminder_Line__Expected_Receipt_Date_; Format("Expected Receipt Date"))
                    {
                    }
                    column(Delivery_Reminder_Line__Remaining_Quantity_; "Remaining Quantity")
                    {
                    }
                    column(Delivery_Reminder_Line_Quantity; Quantity)
                    {
                    }
                    column(Delivery_Reminder_Line__Order_No__; "Order No.")
                    {
                    }
                    column(Delivery_Reminder_Line_Description_Control38; Description)
                    {
                    }
                    column(Delivery_Reminder_Line__No__; "No.")
                    {
                    }
                    column(StartLineNo; StartLineNo)
                    {
                    }
                    column(TypeInt; TypeInt)
                    {
                    }
                    column(Delivery_Reminder_Line_Description_Control98; Description)
                    {
                    }
                    column(Delivery_Reminder_Line_Document_No_; "Document No.")
                    {
                    }
                    column(Delivery_Reminder_Line_Line_No_; "Line No.")
                    {
                    }
                    column(Delivery_Reminder_Line__Remaining_Quantity_Caption; Delivery_Reminder_Line__Remaining_Quantity_CaptionLbl)
                    {
                    }
                    column(Delivery_Reminder_Line_QuantityCaption; Delivery_Reminder_Line_QuantityCaptionLbl)
                    {
                    }
                    column(Delivery_Reminder_Line_Description_Control38Caption; FieldCaption(Description))
                    {
                    }
                    column(Delivery_Reminder_Line__Expected_Receipt_Date_Caption; Delivery_Reminder_Line__Expected_Receipt_Date_CaptionLbl)
                    {
                    }
                    column(Delivery_Reminder_Line__Order_No__Caption; FieldCaption("Order No."))
                    {
                    }
                    column(Delivery_Reminder_Line__No__Caption; FieldCaption("No."))
                    {
                    }
                    dataitem(LineErrorCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(ErrorText_Number__Control97; ErrorText[Number])
                        {
                        }
                        column(LineErrorCounter_Number; Number)
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
                        TypeInt := Type;
                        if Type = Type::" " then begin
                            if Quantity <> 0 then
                                AddError(StrSubstNo(Text1140007, FieldCaption(Quantity)));
                        end else
                            if not PurchLine.Get(PurchLine."Document Type"::Order, "Order No.", "Order Line No.") then
                                AddError(Text1140008);
                    end;

                    trigger OnPreDataItem()
                    begin
                        if Find('-') then begin
                            StartLineNo := 0;
                            repeat
                                Continue := Type = Type::" ";
                                StartLineNo := "Line No.";
                            until (Next() = 0) or not Continue;
                        end;
                        if Find('+') then begin
                            EndLineNo := "Line No." + 1;
                            repeat
                                Continue := Type = Type::" ";
                                if Continue or (Description = '') then
                                    EndLineNo := "Line No.";
                            until (Next(-1) = 0) or not Continue;
                        end;
                        SetFilter("Line No.", '<%1', EndLineNo);
                    end;
                }
                dataitem(DeliveryReminderLine2; "Delivery Reminder Line")
                {
                    DataItemLink = "Document No." = field("No.");
                    DataItemLinkReference = "Delivery Reminder Header";
                    DataItemTableView = sorting("Document No.", "Line No.");
                    column(DeliveryReminderLine2_Description; Description)
                    {
                    }
                    column(DeliveryReminderLine2_Document_No_; "Document No.")
                    {
                    }
                    column(DeliveryReminderLine2_Line_No_; "Line No.")
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Line No.", '>=%1', EndLineNo);
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                if "Vendor No." = '' then
                    AddError(StrSubstNo(Text1140000, FieldCaption("Vendor No.")))
                else
                    if Vend.Get("Vendor No.") then begin
                        if Vend."Currency Code" <> "Currency Code" then
                            AddError(
                              StrSubstNo(
                                Text1140002,
                                FieldCaption("Currency Code"), Vend."Currency Code"));
                    end else
                        AddError(
                          StrSubstNo(
                            Text1140003,
                            Vend.TableCaption(), "Vendor No."));

                GLSetup.Get();

                if "Posting Date" = 0D then
                    AddError(StrSubstNo(Text1140000, FieldCaption("Posting Date")))
                else begin
                    if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
                        if UserId <> '' then
                            if UserSetup.Get(UserId) then begin
                                AllowPostingFrom := UserSetup."Allow Posting From";
                                AllowPostingTo := UserSetup."Allow Posting To";
                            end;
                        if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
                            AllowPostingFrom := GLSetup."Allow Posting From";
                            AllowPostingTo := GLSetup."Allow Posting To";
                        end;
                        if AllowPostingTo = 0D then
                            AllowPostingTo := 99991231D;
                    end;
                    if ("Posting Date" < AllowPostingFrom) or ("Posting Date" > AllowPostingTo) then
                        AddError(
                          StrSubstNo(
                            Text1140004, FieldCaption("Posting Date")));
                end;
                if "Document Date" = 0D then
                    AddError(StrSubstNo(Text1140000, FieldCaption("Document Date")));

                FormatAdrProfessional.DelifRemindVend(VendAddr, "Delivery Reminder Header");

                if "Your Reference" = '' then
                    ReferenceText := ''
                else
                    ReferenceText := FieldCaption("Your Reference");
            end;
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

    labels
    {
    }

    trigger OnPreReport()
    begin
        ReminderHeaderFilter := "Delivery Reminder Header".GetFilters();
    end;

    var
        Text1140000: Label '%1 must be specified.';
        Text1140002: Label '%1 must be %2.';
        Text1140003: Label '%1 %2 does not exist.';
        Text1140004: Label '%1 is not within your allowed range of posting dates.';
        Text1140006: Label 'Reminder: ';
        Text1140007: Label '%1 has to be 0.';
        Text1140008: Label 'Delivery Remainder Line has no valid Purch. Order Line';
        GLSetup: Record "General Ledger Setup";
        UserSetup: Record "User Setup";
        Vend: Record Vendor;
        PurchLine: Record "Purchase Line";
        FormatAdrProfessional: Codeunit "Format Adress Comfort";
        VendAddr: array[8] of Text[80];
        ReminderHeaderFilter: Text[250];
        ReferenceText: Text[35];
        ErrorText: array[99] of Text[250];
        AllowPostingFrom: Date;
        AllowPostingTo: Date;
        StartLineNo: Integer;
        EndLineNo: Integer;
        ErrorCounter: Integer;
        Continue: Boolean;
        TypeInt: Integer;
        Delivery_Reminder___TestCaptionLbl: Label 'Delivery Reminder - Test';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Delivery_Reminder_Header___Document_Date_CaptionLbl: Label 'Document Date';
        Delivery_Reminder_Header___Posting_Date_CaptionLbl: Label 'Posting Date';
        ErrorText_Number_CaptionLbl: Label 'Warning!';
        Delivery_Reminder_Line__Remaining_Quantity_CaptionLbl: Label 'Outstanding Qty.';
        Delivery_Reminder_Line_QuantityCaptionLbl: Label 'Quantity Reminded';
        Delivery_Reminder_Line__Expected_Receipt_Date_CaptionLbl: Label 'Expected Receipt Date';
        ErrorText_Number__Control97CaptionLbl: Label 'Warning!';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;
}

