// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Setup;

table 5053 "Business Relation"
{
    Caption = 'Business Relation';
    DataCaptionFields = "Code", Description;
    DataClassification = CustomerContent;
    LookupPageID = "Business Relations";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "No. of Contacts"; Integer)
        {
            CalcFormula = count("Contact Business Relation" where("Business Relation Code" = field(Code)));
            Caption = 'No. of Contacts';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnRename()
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        case xRec.Code of
            MarketingSetup."Bus. Rel. Code for Bank Accs.":
                begin
                    MarketingSetup."Bus. Rel. Code for Bank Accs." := Rec.Code;
                    MarketingSetup.Modify(true);
                end;
            MarketingSetup."Bus. Rel. Code for Customers":
                begin
                    MarketingSetup."Bus. Rel. Code for Customers" := Rec.Code;
                    MarketingSetup.Modify(true);
                end;
            MarketingSetup."Bus. Rel. Code for Employees":
                begin
                    MarketingSetup."Bus. Rel. Code for Employees" := Rec.Code;
                    MarketingSetup.Modify(true);
                end;
            MarketingSetup."Bus. Rel. Code for Vendors":
                begin
                    MarketingSetup."Bus. Rel. Code for Vendors" := Rec.Code;
                    MarketingSetup.Modify(true);
                end;
        end;
    end;
}

