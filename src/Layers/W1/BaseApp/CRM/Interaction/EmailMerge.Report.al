// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Company;
using System.Utilities;

report 5084 "Email Merge"
{
    DefaultRenderingLayout = "EmailMerge.rdlc";
    //DefaultHeaderFooterPart = None;
    //DefaultThemePart = "BC Default";
    Caption = 'Email Merge';

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(Company_Information_Picture; CompanyInformation.Picture)
            {
            }
            column(Company_Information_Name; CompanyInformation.Name)
            {
            }
            column(Company_Information_Address; CompanyInformation.Address)
            {
            }
            column(Company_Information_Address_2; CompanyInformation."Address 2")
            {
            }
            column(Company_Information_Post_Code; CompanyInformation."Post Code")
            {
            }
            column(Company_Information_City; CompanyInformation.City)
            {
            }
            column(SalespersonPurchaser_Name; SalespersonPurchaser.Name)
            {
            }
            column(SalespersonPurchaser_Job_Title; SalespersonPurchaser."Job Title")
            {
            }
            column(Content; Content)
            {
            }
            column(Contact_Mail_Address; Contact_Mail_Address)
            {
            }
            column(Formal_Salutation; Formal_Salutation)
            {
            }
            column(Informal_Salutation; Informal_Salutation)
            {
            }
            column(Document_Date; Document_Date)
            {
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

    rendering
    {
        layout("EmailMerge.rdlc")
        {
            Type = RDLC;
            LayoutFile = './CRM/Interaction/EmailMerge.rdlc';
            Caption = 'EMail Merge (RDLC)';
            Summary = 'The EMail Merge (RDLC) provides a detailed layout.';
        }
        layout("DefaultEmailMergeDoc.docx")
        {
            Type = Word;
            LayoutFile = './CRM/DefaultEmailMergeDoc.docx';
            Caption = 'EMail Merge (Word)';
            Summary = 'The EMail Merge (Word) provides a basic layout.';
            ObsoleteState = Pending;
            ObsoleteReason = 'This Word layout will be replaced by the new Report Layout Experience. Use the corresponding composite (body) layout instead. It will be removed in a future release.';
            ObsoleteTag = '30.0';
        }
        layout("DefaultEmailMergeDocBody.docx")
        {
            Type = Word;
            //Subtype = Body;
            LayoutFile = './CRM/Interaction/DefaultEmailMergeDocBody.docx';
            Caption = 'Body-only: EMail Merge (Word)';
            Summary = 'Portrait orientated. Shows a salutation, free-text body content, and a closing signature with the salesperson''s name and job title. Use it for mail merge letters to contacts.';
        }
    }

    labels
    {
    }

    protected var
        CompanyInformation: Record "Company Information";
        Contact: Record Contact;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SegmentLine: Record "Segment Line";
        Content: Text;
        Contact_Mail_Address: Text;
        Formal_Salutation: Text;
        Informal_Salutation: Text;
        Document_Date: Text;

    procedure InitializeRequest(InSegmentLine: Record "Segment Line"; InContent: Text)
    begin
        SegmentLine := InSegmentLine;
        Content := InContent;

        CompanyInformation.Get();
        CompanyInformation.CalcFields(Picture);

        if Contact.Get(SegmentLine."Contact No.") then begin
            Formal_Salutation := Contact.GetSalutation("Salutation Formula Salutation Type"::Formal, SegmentLine."Language Code");
            Informal_Salutation := Contact.GetSalutation("Salutation Formula Salutation Type"::Informal, SegmentLine."Language Code");
        end;

        if SalespersonPurchaser.Get(InSegmentLine."Salesperson Code") then;

        Contact_Mail_Address := '';
        Document_Date := Format(SegmentLine.Date, 0, 4);

        OnAfterInitializeRequest();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitializeRequest()
    begin
    end;
}

