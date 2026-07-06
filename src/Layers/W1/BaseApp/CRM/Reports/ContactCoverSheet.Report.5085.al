// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Reports;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using System.Email;

#pragma warning disable AA0215
report 5085 "Contact Cover Sheet"
#pragma warning restore AA0215
{
    RDLCLayout = './CRM/Reports/ContactCoverSheet.5085.rdlc';
    WordLayout = './CRM/Reports/ContactCoverSheet.docx';
    Caption = 'Contact Cover Sheet';
    DefaultLayout = Word;
    PreviewMode = PrintLayout;
    WordMergeDataItem = TempSegmentLine;

    dataset
    {
        dataitem("Segment Header"; "Segment Header")
        {
            RequestFilterFields = "No.";
            dataitem("Segment Line"; "Segment Line")
            {
                DataItemLink = "Segment No." = field("No.");
                DataItemTableView = sorting("Segment No.", "Campaign No.", Date);

                trigger OnAfterGetRecord()
                begin
                    TempSegmentLine.SetRange("Contact No.", "Contact No.");
                    if not TempSegmentLine.FindFirst() then begin
                        TempSegmentLine.Copy("Segment Line");
                        TempSegmentLine.Insert();
                    end;
                end;
            }

            trigger OnPreDataItem()
            begin
                if not RunFromSegment then
                    CurrReport.Break();
            end;
        }
        dataitem(Contact; Contact)
        {
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            var
                LastTempSegLine: Integer;
            begin
                TempSegmentLine.SetRange("Contact No.", "No.");
                if not TempSegmentLine.FindFirst() then begin
                    TempSegmentLine.Reset();
                    if TempSegmentLine.FindLast() then
                        LastTempSegLine := TempSegmentLine."Line No."
                    else
                        LastTempSegLine := 0;
                    TempSegmentLine.Init();
                    TempSegmentLine."Line No." := LastTempSegLine + 10000;
                    TempSegmentLine."Contact No." := "No.";
                    TempSegmentLine.Insert();
                end;
            end;

            trigger OnPreDataItem()
            begin
                if RunFromSegment then
                    CurrReport.Break();
            end;
        }
        dataitem(TempSegmentLine; "Segment Line")
        {
            DataItemTableView = sorting("Segment No.", "Line No.");
            UseTemporary = true;
            column(CompanyInformationPhoneNo; CompanyInformation."Phone No.")
            {
            }
            column(CompanyInformationFaxNo; CompanyInformation."Fax No.")
            {
            }
            column(CompanyInformationGiroNo; CompanyInformation."Giro No.")
            {
            }
            column(CompanyInformationVATRegNo; CompanyInformation."VAT Registration No.")
            {
            }
            column(CompanyInformationBankName; CompanyInformation."Bank Name")
            {
            }
            column(CompanyInformationBankAccountNo; CompanyInformation."Bank Account No.")
            {
            }
            column(Document_Date; Document_Date)
            {
            }
            column(ContactAddress1; ContactAddress[1])
            {
            }
            column(ContactAddress2; ContactAddress[2])
            {
            }
            column(ContactAddress3; ContactAddress[3])
            {
            }
            column(ContactAddress4; ContactAddress[4])
            {
            }
            column(ContactAddress5; ContactAddress[5])
            {
            }
            column(ContactAddress6; ContactAddress[6])
            {
            }
            column(ContactAddress7; ContactAddress[7])
            {
            }
            column(ContactAddress8; ContactAddress[8])
            {
            }
            column(CompanyAddress1; CompanyAddress[1])
            {
            }
            column(CompanyAddress2; CompanyAddress[2])
            {
            }
            column(CompanyAddress3; CompanyAddress[3])
            {
            }
            column(CompanyAddress4; CompanyAddress[4])
            {
            }
            column(CompanyAddress5; CompanyAddress[5])
            {
            }
            column(CompanyAddress6; CompanyAddress[6])
            {
            }
            column(CompanyAddress7; CompanyAddress[7])
            {
            }
            column(CompanyAddress8; CompanyAddress[8])
            {
            }
            column(CoverSheetTxt; CoverSheetLbl)
            {
            }
            column(PhoneNoTxt; PhoneNoLbl)
            {
            }
            column(FaxNoTxt; FaxNoLbl)
            {
            }
            column(VATRegNoTxt; VATRegNoLbl)
            {
            }
            column(GiroNoTxt; GiroNoLbl)
            {
            }
            column(BankTxt; BankLbl)
            {
            }
            column(BankAccountTxt; BankAccountLbl)
            {
            }
            column(BestRegardsTxt; BestRegardsLbl)
            {
            }

            trigger OnAfterGetRecord()
            var
                SegmentLineContact: Record Contact;
                SegManagement: Codeunit SegManagement;
            begin
                SegmentLineContact.Get("Contact No.");
                FormatAddress.ContactAddr(ContactAddress, SegmentLineContact);

                if LogInteraction then
                    if not IsReportInPreviewMode() then
                        SegManagement.LogDocument(
                          17, '', 0, 0, DATABASE::Contact, SegmentLineContact."No.", '', '', '', '');
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
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        Importance = Standard;
                        ToolTip = 'Specifies that interactions with the contact are logged.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        var
            SegManagement: Codeunit SegManagement;
        begin
            LogInteraction := SegManagement.FindInteractionTemplateCode(Enum::"Interaction Log Entry Document Type"::"Cover Sheet") <> '';
            LogInteractionEnable := LogInteraction;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CompanyInformation.Get();
        FormatAddress.Company(CompanyAddress, CompanyInformation);
        Document_Date := Format(WorkDate(), 0, 4);
    end;

    var
        CompanyInformation: Record "Company Information";
        FormatAddress: Codeunit "Format Address";
        CompanyAddress: array[8] of Text[100];
        Document_Date: Text;
        ContactAddress: array[8] of Text[100];
        CoverSheetLbl: Label 'Cover Sheet';
        PhoneNoLbl: Label 'Phone No.';
        FaxNoLbl: Label 'Fax No.';
        VATRegNoLbl: Label 'VAT Reg. No.';
        GiroNoLbl: Label 'Giro No.';
        BankLbl: Label 'Bank';
        BankAccountLbl: Label 'Bank Account';
        BestRegardsLbl: Label 'Best Regards,';
        LogInteraction: Boolean;
        LogInteractionEnable: Boolean;
        RunFromSegment: Boolean;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    procedure SetRunFromSegment()
    begin
        RunFromSegment := true;
    end;
}

