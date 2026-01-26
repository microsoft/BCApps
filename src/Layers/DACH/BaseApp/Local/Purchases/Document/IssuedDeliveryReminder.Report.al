// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using System.Utilities;

report 5005273 "Issued Delivery Reminder"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Document/IssuedDeliveryReminder.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Delivery Reminder';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Issued Deliv. Reminder Header"; "Issued Deliv. Reminder Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Delivery Reminder';
            column(Issued_Deliv__Reminder_Header_No_; "No.")
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(Issued_Deliv__Reminder_Header___Posting_Date_; Format("Issued Deliv. Reminder Header"."Posting Date"))
                {
                }
                column(Issued_Deliv__Reminder_Header___No__; "Issued Deliv. Reminder Header"."No.")
                {
                }
                column(Issued_Deliv__Reminder_Header___Your_Reference_; "Issued Deliv. Reminder Header"."Your Reference")
                {
                }
                column(ReferenceText; ReferenceText)
                {
                }
                column(Issued_Deliv__Reminder_Header___Document_Date_; "Issued Deliv. Reminder Header"."Document Date")
                {
                }
                column(Issued_Deliv__Reminder_Header___Vendor_No__; "Issued Deliv. Reminder Header"."Vendor No.")
                {
                }
                column(CompanyInfo__Bank_Account_No__; CompanyInfo."Bank Account No.")
                {
                }
                column(CompanyInfo__Bank_Name_; CompanyInfo."Bank Name")
                {
                }
                column(CompanyInfo__Giro_No__; CompanyInfo."Giro No.")
                {
                }
                column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
                {
                }
                column(CompanyInfo__Fax_No__; CompanyInfo."Fax No.")
                {
                }
                column(VendAddr_8_; VendAddr[8])
                {
                }
                column(CompanyInfo__Phone_No__; CompanyInfo."Phone No.")
                {
                }
                column(VendAddr_7_; VendAddr[7])
                {
                }
                column(VendAddr_6_; VendAddr[6])
                {
                }
                column(CompanyAddr_6_; CompanyAddr[6])
                {
                }
                column(VendAddr_5_; VendAddr[5])
                {
                }
                column(CompanyAddr_5_; CompanyAddr[5])
                {
                }
                column(VendAddr_4_; VendAddr[4])
                {
                }
                column(CompanyAddr_4_; CompanyAddr[4])
                {
                }
                column(VendAddr_3_; VendAddr[3])
                {
                }
                column(CompanyAddr_3_; CompanyAddr[3])
                {
                }
                column(VendAddr_2_; VendAddr[2])
                {
                }
                column(CompanyAddr_2_; CompanyAddr[2])
                {
                }
                column(VendAddr_1_; VendAddr[1])
                {
                }
                column(CompanyAddr_1_; CompanyAddr[1])
                {
                }
                column(Integer_Number; Number)
                {
                }
                column(Issued_Deliv__Reminder_Header___Posting_Date_Caption; Issued_Deliv__Reminder_Header___Posting_Date_CaptionLbl)
                {
                }
                column(Issued_Deliv__Reminder_Header___No__Caption; Issued_Deliv__Reminder_Header___No__CaptionLbl)
                {
                }
                column(Vendor_No__Caption; Vendor_No__CaptionLbl)
                {
                }
                column(CompanyInfo__Bank_Account_No__Caption; CompanyInfo__Bank_Account_No__CaptionLbl)
                {
                }
                column(CompanyInfo__Bank_Name_Caption; CompanyInfo__Bank_Name_CaptionLbl)
                {
                }
                column(CompanyInfo__Giro_No__Caption; CompanyInfo__Giro_No__CaptionLbl)
                {
                }
                column(CompanyInfo__VAT_Registration_No__Caption; CompanyInfo__VAT_Registration_No__CaptionLbl)
                {
                }
                column(CompanyInfo__Fax_No__Caption; CompanyInfo__Fax_No__CaptionLbl)
                {
                }
                column(CompanyInfo__Phone_No__Caption; CompanyInfo__Phone_No__CaptionLbl)
                {
                }
                column(Delivery_ReminderCaption; Delivery_ReminderCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                dataitem("Issued Deliv. Reminder Line"; "Issued Deliv. Reminder Line")
                {
                    DataItemLink = "Document No." = field("No.");
                    DataItemLinkReference = "Issued Deliv. Reminder Header";
                    DataItemTableView = sorting("Document No.", "Line No.");
                    column(Issued_Deliv__Reminder_Line_Description; Description)
                    {
                    }
                    column(StartLineNo; StartLineNo)
                    {
                    }
                    column(Issued_Deliv__Reminder_Line__Order_No__; "Order No.")
                    {
                    }
                    column(Issued_Deliv__Reminder_Line__No__; "No.")
                    {
                    }
                    column(Issued_Deliv__Reminder_Line__Expected_Receipt_Date_; Format("Expected Receipt Date"))
                    {
                    }
                    column(Outstanding_Purch__Quantity; "Remaining Quantity")
                    {
                    }
                    column(Issued_Deliv__Reminder_Line__Reorder_Quantity_; "Reorder Quantity")
                    {
                    }
                    column(Issued_Deliv__Reminder_Line_Quantity; Quantity)
                    {
                    }
                    column(Issued_Deliv__Reminder_Line_Description_Control34; Description)
                    {
                    }
                    column(Issued_Deliv__Reminder_Line_Description_Control31; Description)
                    {
                    }
                    column(LineNo; "Line No.")
                    {
                    }
                    column(TypeInt; TypeInt)
                    {
                    }
                    column(Issued_Deliv__Reminder_Line_Document_No_; "Document No.")
                    {
                    }
                    column(Issued_Deliv__Reminder_Line__Order_No__Caption; FieldCaption("Order No."))
                    {
                    }
                    column(Issued_Deliv__Reminder_Line__No__Caption; FieldCaption("No."))
                    {
                    }
                    column(Issued_Deliv__Reminder_Line__Expected_Receipt_Date_Caption; Issued_Deliv__Reminder_Line__Expected_Receipt_Date_CaptionLbl)
                    {
                    }
                    column(Outstanding_Purch__QuantityCaption; Outstanding_Purch__QuantityCaptionLbl)
                    {
                    }
                    column(Purch__Order_QuantityCaption; Purch__Order_QuantityCaptionLbl)
                    {
                    }
                    column(Issued_Deliv__Reminder_Line_QuantityCaption; Issued_Deliv__Reminder_Line_QuantityCaptionLbl)
                    {
                    }
                    column(Issued_Deliv__Reminder_Line_Description_Control34Caption; Issued_Deliv__Reminder_Line_Description_Control34CaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        TypeInt := Type;
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
                dataitem(IssuedDelivRemindLine2; "Issued Deliv. Reminder Line")
                {
                    DataItemLink = "Document No." = field("No.");
                    DataItemLinkReference = "Issued Deliv. Reminder Header";
                    DataItemTableView = sorting("Document No.", "Line No.");
                    column(IssuedDelivRemindLine2_Description; Description)
                    {
                    }
                    column(IssuedDelivRemindLine2_Document_No_; "Document No.")
                    {
                    }
                    column(IssuedDelivRemindLine2_Line_No_; "Line No.")
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
                FormatAdrProfessional.IssDelivRemindVend(VendAddr, "Issued Deliv. Reminder Header");

                if "Your Reference" = '' then
                    ReferenceText := ''
                else
                    ReferenceText := FieldCaption("Your Reference");

                if not CurrReport.Preview then
                    IssuedDelivRemindPrintCounter.Run("Issued Deliv. Reminder Header");
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                FormatAddr.Company(CompanyAddr, CompanyInfo);
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

    var
        CompanyInfo: Record "Company Information";
        IssuedDelivRemindPrintCounter: Codeunit "Iss. Delivery Remind. printed";
        FormatAddr: Codeunit "Format Address";
        FormatAdrProfessional: Codeunit "Format Adress Comfort";
        VendAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        ReferenceText: Text[35];
        StartLineNo: Integer;
        EndLineNo: Integer;
        Continue: Boolean;
        TypeInt: Integer;
        Issued_Deliv__Reminder_Header___Posting_Date_CaptionLbl: Label 'Posting Date';
        Issued_Deliv__Reminder_Header___No__CaptionLbl: Label 'Reminder No.';
        Vendor_No__CaptionLbl: Label 'Vendor No.:';
        CompanyInfo__Bank_Account_No__CaptionLbl: Label 'Account No.';
        CompanyInfo__Bank_Name_CaptionLbl: Label 'Bank';
        CompanyInfo__Giro_No__CaptionLbl: Label 'Giro No.';
        CompanyInfo__VAT_Registration_No__CaptionLbl: Label 'VAT Reg. No.';
        CompanyInfo__Fax_No__CaptionLbl: Label 'Fax No.';
        CompanyInfo__Phone_No__CaptionLbl: Label 'Phone No.';
        Delivery_ReminderCaptionLbl: Label 'Delivery Reminder';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Issued_Deliv__Reminder_Line__Expected_Receipt_Date_CaptionLbl: Label 'Purch. Expected Receipt Date';
        Outstanding_Purch__QuantityCaptionLbl: Label 'Outstanding Purch. Quantity';
        Purch__Order_QuantityCaptionLbl: Label 'Purch. Order Quantity';
        Issued_Deliv__Reminder_Line_QuantityCaptionLbl: Label 'Quantity Reminded';
        Issued_Deliv__Reminder_Line_Description_Control34CaptionLbl: Label 'Description';
}

