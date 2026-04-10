// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Setup;

using Microsoft.CRM.Contact;

table 5066 "Job Responsibility"
{
    Caption = 'Job Responsibility';
    DataCaptionFields = "Code", Description;
    DataClassification = CustomerContent;
    LookupPageID = "Job Responsibilities";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the code for the job responsibility.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the job responsibility.';
        }
        field(3; "No. of Contacts"; Integer)
        {
            CalcFormula = count("Contact Job Responsibility" where("Job Responsibility Code" = field(Code)));
            Caption = 'No. of Contacts';
            ToolTip = 'Specifies the number of contacts that have been assigned the job responsibility.';
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
}

