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

report 5064 "Segment - Cover Sheet"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CRM/Reports/SegmentCoverSheet.rdlc';
    Caption = 'Segment - Cover Sheet';
    WordMergeDataItem = "Segment Header";

    dataset
    {
        dataitem("Segment Header"; "Segment Header")
        {
            DataItemTableView = sorting("No.");
            dataitem("Segment Line"; "Segment Line")
            {
                DataItemLink = "Segment No." = field("No.");
                DataItemTableView = sorting("Segment No.", "Campaign No.", Date);
                dataitem(Contact; Contact)
                {
                    DataItemLink = "No." = field("Contact No.");
                    DataItemTableView = sorting("No.");
                    column(Addr_1_; Addr[1])
                    {
                    }
                    column(Addr_2_; Addr[2])
                    {
                    }
                    column(Addr_3_; Addr[3])
                    {
                    }
                    column(Addr_4_; Addr[4])
                    {
                    }
                    column(Addr_6_; Addr[6])
                    {
                    }
                    column(Addr_7_; Addr[7])
                    {
                    }
                    column(Addr_5_; Addr[5])
                    {
                    }
                    column(CompanyAddr_1_; CompanyAddr[1])
                    {
                    }
                    column(CompanyAddr_2_; CompanyAddr[2])
                    {
                    }
                    column(CompanyAddr_3_; CompanyAddr[3])
                    {
                    }
                    column(CompanyAddr_4_; CompanyAddr[4])
                    {
                    }
                    column(CompanyAddr_5_; CompanyAddr[5])
                    {
                    }
                    column(CompanyAddr_6_; CompanyAddr[6])
                    {
                    }
                    column(CompanyAddr_7_; CompanyAddr[7])
                    {
                    }
                    column(CompanyAddr_8_; CompanyAddr[8])
                    {
                    }
                    column(Addr_8_; Addr[8])
                    {
                    }
                    column(CompanyInfo__Phone_No__; CompanyInfo."Phone No.")
                    {
                    }
                    column(CompanyInfo__Fax_No__; CompanyInfo."Fax No.")
                    {
                    }
                    column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
                    {
                    }
                    column(CompanyInfo__Giro_No__; CompanyInfo."Giro No.")
                    {
                    }
                    column(CompanyInfo__Bank_Name_; CompanyInfo."Bank Name")
                    {
                    }
                    column(CompanyInfo__Bank_Account_No__; CompanyInfo."Bank Account No.")
                    {
                    }
                    column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                    {
                    }
                    column(Text_1_; Text[1])
                    {
                    }
                    column(Text_2_; Text[2])
                    {
                    }
                    column(Text_3_; Text[3])
                    {
                    }
                    column(Text_4_; Text[4])
                    {
                    }
                    column(Text_5_; Text[5])
                    {
                    }
                    column(Text_6_; Text[6])
                    {
                    }
                    column(MarksTxt_7_; MarksTxt[7])
                    {
                    }
                    column(MarksTxt_6_; MarksTxt[6])
                    {
                    }
                    column(MarksTxt_5_; MarksTxt[5])
                    {
                    }
                    column(MarksTxt_4_; MarksTxt[4])
                    {
                    }
                    column(MarksTxt_3_; MarksTxt[3])
                    {
                    }
                    column(MarksTxt_2_; MarksTxt[2])
                    {
                    }
                    column(MarksTxt_1_; MarksTxt[1])
                    {
                    }
                    column(Contact_No_; "No.")
                    {
                    }
                    column(Cover_SheetCaption; Cover_SheetCaptionLbl)
                    {
                    }
                    column(CompanyInfo__Phone_No__Caption; CompanyInfo__Phone_No__CaptionLbl)
                    {
                    }
                    column(CompanyInfo__Fax_No__Caption; CompanyInfo__Fax_No__CaptionLbl)
                    {
                    }
                    column(CompanyInfo__VAT_Registration_No__Caption; CompanyInfo__VAT_Registration_No__CaptionLbl)
                    {
                    }
                    column(CompanyInfo__Giro_No__Caption; CompanyInfo__Giro_No__CaptionLbl)
                    {
                    }
                    column(CompanyInfo__Bank_Name_Caption; CompanyInfo__Bank_Name_CaptionLbl)
                    {
                    }
                    column(CompanyInfo__Bank_Account_No__Caption; CompanyInfo__Bank_Account_No__CaptionLbl)
                    {
                    }
                    column(As_agreed_uponCaption; As_agreed_uponCaptionLbl)
                    {
                    }
                    column(For_your_informationCaption; For_your_informationCaptionLbl)
                    {
                    }
                    column(Your_comments_pleaseCaption; Your_comments_pleaseCaptionLbl)
                    {
                    }
                    column(For_your_approvalCaption; For_your_approvalCaptionLbl)
                    {
                    }
                    column(Please_callCaption; Please_callCaptionLbl)
                    {
                    }
                    column(Returned_after_useCaption; Returned_after_useCaptionLbl)
                    {
                    }
                    column(Best_regards_Caption; Best_regards_CaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        FormatAddr.ContactAddr(Addr, Contact);

                        if LogInteraction then
                            if not IsReportInPreviewMode() then
                                SegManagement.LogDocument(
                                  17, '', 0, 0, DATABASE::Contact, "No.", '', "Segment Header"."Campaign No.", '', '');
                    end;

                    trigger OnPreDataItem()
                    begin
                        CompanyInfo.Get();
                        FormatAddr.Company(CompanyAddr, CompanyInfo);
                    end;
                }
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Segment - Cover Sheet';
        AboutText = 'Get or print cover sheets for your segments.';
        SaveValues = false;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group(Text)
                    {
                        Caption = 'Text';
                        field("Text[1]"; Text[1])
                        {
                            ApplicationArea = RelationshipMgmt;
                            ShowCaption = false;
                            ToolTip = 'Specifies the text that you want to include on the cover sheet.';
                        }
                        field("Text[2]"; Text[2])
                        {
                            ApplicationArea = RelationshipMgmt;
                            Importance = Additional;
                            ShowCaption = false;
                            ToolTip = 'Specifies the text that you want to include on the cover sheet.';
                        }
                        field("Text[3]"; Text[3])
                        {
                            ApplicationArea = RelationshipMgmt;
                            Importance = Additional;
                            ShowCaption = false;
                            ToolTip = 'Specifies the text that you want to include on the cover sheet.';
                        }
                        field("Text[4]"; Text[4])
                        {
                            ApplicationArea = RelationshipMgmt;
                            Importance = Additional;
                            ShowCaption = false;
                            ToolTip = 'Specifies the text that you want to include on the cover sheet.';
                        }
                        field("Text[5]"; Text[5])
                        {
                            ApplicationArea = RelationshipMgmt;
                            Importance = Additional;
                            ShowCaption = false;
                            ToolTip = 'Specifies the text that you want to include on the cover sheet.';
                        }
                    }
                    group(Remarks)
                    {
                        Caption = 'Remarks';
                        field("Marks[1]"; Marks[1])
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'As agreed upon';
                            ToolTip = 'Specifies that the cover sheet is agreed with the contact.';

                            trigger OnValidate()
                            begin
                                Marks1OnAfterValidate();
                            end;
                        }
                        field("Marks[2]"; Marks[2])
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'For your information';
                            ToolTip = 'Specifies a standard remark on the cover sheet.';

                            trigger OnValidate()
                            begin
                                Marks2OnAfterValidate();
                            end;
                        }
                        field("Marks[3]"; Marks[3])
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Your comments please';
                            ToolTip = 'Specifies a standard remark on the cover sheet.';

                            trigger OnValidate()
                            begin
                                Marks3OnAfterValidate();
                            end;
                        }
                        field("Marks[4]"; Marks[4])
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'For your approval';
                            ToolTip = 'Specifies a standard remark on the cover sheet.';

                            trigger OnValidate()
                            begin
                                Marks4OnAfterValidate();
                            end;
                        }
                        field("Marks[5]"; Marks[5])
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Please call';
                            ToolTip = 'Specifies a standard remark on the cover sheet.';

                            trigger OnValidate()
                            begin
                                Marks5OnAfterValidate();
                            end;
                        }
                        field("Marks[6]"; Marks[6])
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Returned after use';
                            ToolTip = 'Specifies a standard remark on the cover sheet.';

                            trigger OnValidate()
                            begin
                                Marks6OnAfterValidate();
                            end;
                        }
                        field("Marks[7]"; Marks[7])
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Custom remark';
                            Importance = Additional;
                            ToolTip = 'Specifies if a custom remark is displayed on the cover sheet. You can also enter your own comment.';

                            trigger OnValidate()
                            begin
                                Marks7OnAfterValidate();
                            end;
                        }
                        field("Text[6]"; Text[6])
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Custom remark text';
                            Importance = Additional;
                            ToolTip = 'Specifies the custom remark.';
                        }
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        Importance = Additional;
                        ToolTip = 'Specifies that interactions with the contact are logged.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            LogInteraction := SegManagement.FindInteractionTemplateCode(Enum::"Interaction Log Entry Document Type"::"Cover Sheet") <> '';
            LogInteractionEnable := LogInteraction;
        end;
    }

    labels
    {
    }

    var
        CompanyInfo: Record "Company Information";
        FormatAddr: Codeunit "Format Address";
        SegManagement: Codeunit SegManagement;
        CompanyAddr: array[8] of Text[100];
        Addr: array[8] of Text[100];
        Text: array[6] of Text[100];
        Marks: array[7] of Boolean;
        MarksTxt: array[7] of Text[1];
        LogInteraction: Boolean;
        LogInteractionEnable: Boolean;

        MarkTxt: Label 'x', Locked = true;
        Cover_SheetCaptionLbl: Label 'Cover Sheet';
        CompanyInfo__Phone_No__CaptionLbl: Label 'Phone No.';
        CompanyInfo__Fax_No__CaptionLbl: Label 'Fax No.';
        CompanyInfo__VAT_Registration_No__CaptionLbl: Label 'VAT Reg. No.';
        CompanyInfo__Giro_No__CaptionLbl: Label 'Giro No.';
        CompanyInfo__Bank_Name_CaptionLbl: Label 'Bank';
        CompanyInfo__Bank_Account_No__CaptionLbl: Label 'Account No.';
        As_agreed_uponCaptionLbl: Label 'As agreed upon';
        For_your_informationCaptionLbl: Label 'For your information';
        Your_comments_pleaseCaptionLbl: Label 'Your comments please';
        For_your_approvalCaptionLbl: Label 'For your approval';
        Please_callCaptionLbl: Label 'Please call';
        Returned_after_useCaptionLbl: Label 'Returned after use';
        Best_regards_CaptionLbl: Label 'Best regards,';

    local procedure Marks1OnAfterValidate()
    begin
        if Marks[1] then
            MarksTxt[1] := MarkTxt
        else
            MarksTxt[1] := ''
    end;

    local procedure Marks2OnAfterValidate()
    begin
        if Marks[2] then
            MarksTxt[2] := MarkTxt
        else
            MarksTxt[2] := ''
    end;

    local procedure Marks3OnAfterValidate()
    begin
        if Marks[3] then
            MarksTxt[3] := MarkTxt
        else
            MarksTxt[3] := ''
    end;

    local procedure Marks4OnAfterValidate()
    begin
        if Marks[4] then
            MarksTxt[4] := MarkTxt
        else
            MarksTxt[4] := ''
    end;

    local procedure Marks5OnAfterValidate()
    begin
        if Marks[5] then
            MarksTxt[5] := MarkTxt
        else
            MarksTxt[5] := ''
    end;

    local procedure Marks6OnAfterValidate()
    begin
        if Marks[6] then
            MarksTxt[6] := MarkTxt
        else
            MarksTxt[6] := ''
    end;

    local procedure Marks7OnAfterValidate()
    begin
        if Marks[7] then
            MarksTxt[7] := MarkTxt
        else
            MarksTxt[7] := ''
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    procedure InitializeText(Text1From: Text[100]; Text2From: Text[100]; Text3From: Text[100]; Text4From: Text[100]; Text5From: Text[100])
    begin
        Text[1] := Text1From;
        Text[2] := Text2From;
        Text[3] := Text3From;
        Text[4] := Text4From;
        Text[5] := Text5From;
    end;

    procedure InitializeRemarks(AsAgreedUpon: Boolean; ForYourInformation: Boolean; YourCommentsPlease: Boolean; ForYourApproval: Boolean; PleaseCall: Boolean; ReturnedAfterUse: Boolean)
    begin
        Marks[1] := AsAgreedUpon;
        Marks[2] := ForYourInformation;
        Marks[3] := YourCommentsPlease;
        Marks[4] := ForYourApproval;
        Marks[5] := PleaseCall;
        Marks[6] := ReturnedAfterUse;
        Marks1OnAfterValidate();
        Marks2OnAfterValidate();
        Marks3OnAfterValidate();
        Marks4OnAfterValidate();
        Marks5OnAfterValidate();
        Marks6OnAfterValidate();
    end;

    procedure InitializeCustomRemarks(CustomRemark: Boolean; CustomRemarkText: Text[100])
    begin
        Marks[7] := CustomRemark;
        Text[6] := CustomRemarkText;
        Marks7OnAfterValidate();
    end;
}

