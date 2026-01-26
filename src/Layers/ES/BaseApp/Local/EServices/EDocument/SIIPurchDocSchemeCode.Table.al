// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

table 10756 "SII Purch. Doc. Scheme Code"
{
    DrillDownPageID = "SII Purch. Doc. Scheme Codes";
    LookupPageID = "SII Purch. Doc. Scheme Codes";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionMembers = " ","Order",Invoice,"Credit Memo","Posted Invoice","Posted Credit Memo";
            OptionCaption = ' ,Order,Invoice,Credit Memo,Posted Invoice,Posted Credit Memo';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(3; "Special Scheme Code"; Option)
        {
            Caption = 'Special Scheme Code';
            OptionMembers = " ","01 General","02 Special System Activities","03 Special System","04 Gold","05 Travel Agencies","06 Groups of Entities","07 Special Cash","08  IPSI / IGIC","09 Intra-Community Acquisition","12 Business Premises Leasing Operations","13 Import (Without DUA)","14 First Half 2017";
            OptionCaption = ' ,01 General,02 Special System Activities,03 Special System,04 Gold,05 Travel Agencies,06 Groups of Entities,07 Special Cash,08  IPSI / IGIC,09 Intra-Community Acquisition,12 Business Premises Leasing Operations,13 Import (Without DUA),14 First Half 2017';
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Special Scheme Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
        SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
    begin
        SIIPurchDocSchemeCode.SetRange("Document Type", "Document Type");
        SIIPurchDocSchemeCode.SetRange("Document No.", "Document No.");
        if SIIPurchDocSchemeCode.Count() = SIISchemeCodeMgt.GetMaxNumberOfRegimeCodes() then
            Error(CannotInsertMoreThanThreeCodesErr);
    end;

    var
        CannotInsertMoreThanThreeCodesErr: Label 'You cannot specify more than three special scheme codes for each document.';
}

