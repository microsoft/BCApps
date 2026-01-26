// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

table 10755 "SII Sales Document Scheme Code"
{
    DrillDownPageID = "SII Sales Doc. Scheme Codes";
    LookupPageID = "SII Sales Doc. Scheme Codes";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionMembers = " ",Sales,Service;
            OptionCaption = ' ,Sales,Service';
        }
        field(2; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionMembers = " ","Order",Invoice,"Credit Memo","Posted Invoice","Posted Credit Memo";
            OptionCaption = ' ,Order,Invoice,Credit Memo,Posted Invoice,Posted Credit Memo';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Special Scheme Code"; Option)
        {
            Caption = 'Special Scheme Code';
            OptionMembers = " ","01 General","02 Export","03 Special System","04 Gold","05 Travel Agencies","06 Groups of Entities","07 Special Cash","08  IPSI / IGIC","09 Travel Agency Services","10 Third Party","11 Business Withholding","12 Business not Withholding","13 Business Withholding and not Withholding","14 Invoice Work Certification","15 Invoice of Consecutive Nature","16 First Half 2017";
            OptionCaption = ' ,01 General,02 Export,03 Special System,04 Gold,05 Travel Agencies,06 Groups of Entities,07 Special Cash,08  IPSI / IGIC,09 Travel Agency Services,10 Third Party,11 Business Withholding,12 Business not Withholding,13 Business Withholding and not Withholding,14 Invoice Work Certification,15 Invoice of Consecutive Nature,16 First Half 2017';
        }
    }

    keys
    {
        key(Key1; "Entry Type", "Document Type", "Document No.", "Special Scheme Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
    begin
        SIISalesDocumentSchemeCode.SetRange("Document Type", "Document Type");
        SIISalesDocumentSchemeCode.SetRange("Document No.", "Document No.");
        if SIISalesDocumentSchemeCode.Count() = SIISchemeCodeMgt.GetMaxNumberOfRegimeCodes() then
            Error(CannotInsertMoreThanThreeCodesErr);
    end;

    var
        CannotInsertMoreThanThreeCodesErr: Label 'You cannot specify more than three special scheme codes for each document.';
}

