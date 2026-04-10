// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

/// <summary>
/// Stores tax group classifications for items and customers.
/// Groups items by tax treatment to determine applicable tax rates and exemptions.
/// </summary>
table 321 "Tax Group"
{
    Caption = 'Tax Group';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Tax Groups";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the tax group.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the code you want to assign to this tax group.';
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive name for the tax group classification.
        /// </summary>
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the tax group. For example, if the tax group code is ALCOHOL, you could enter the description Alcoholic beverages.';
        }
        /// <summary>
        /// Timestamp of the last modification to this tax group record.
        /// </summary>
        field(8005; "Last Modified DateTime"; DateTime)
        {
            Caption = 'Last Modified DateTime';
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

    trigger OnInsert()
    begin
        SetLastModifiedDateTime();
    end;

    trigger OnModify()
    begin
        SetLastModifiedDateTime();
    end;

    trigger OnRename()
    begin
        SetLastModifiedDateTime();
    end;

    /// <summary>
    /// Creates a new tax group with the specified code and default description.
    /// </summary>
    /// <param name="NewTaxGroupCode">Code for the new tax group</param>
    procedure CreateTaxGroup(NewTaxGroupCode: Code[20])
    begin
        Init();
        Code := NewTaxGroupCode;
        Description := NewTaxGroupCode;
        Insert();
    end;

    local procedure SetLastModifiedDateTime()
    begin
        "Last Modified DateTime" := CurrentDateTime;
    end;
}
