// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

/// <summary>
/// Table that contains the available No. Series and their properties.
/// </summary>
table 308 "No. Series"
{
    Caption = 'No. Series';
    DataCaptionFields = "Code", Description;
    DataClassification = CustomerContent;
    DrillDownPageId = "No. Series";
    LookupPageId = "No. Series";
    MovedFrom = '437dbf0e-84ff-417a-965d-ed2bb9650972';
    InherentEntitlements = rX;
    InherentPermissions = rX;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Default Nos."; Boolean)
        {
            Caption = 'Default Nos.';

            trigger OnValidate()
            var
                NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
            begin
                NoSeriesSetupImpl.ValidateDefaultNos(Rec, xRec);
            end;
        }
        field(4; "Manual Nos."; Boolean)
        {
            Caption = 'Manual Nos.';

            trigger OnValidate()
            var
                NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
            begin
                NoSeriesSetupImpl.ValidateManualNos(Rec, xRec);
            end;
        }
        field(5; "Date Order"; Boolean)
        {
            Caption = 'Date Order';
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
        fieldgroup(DropDown; Code, Description)
        {
        }
    }

    trigger OnDelete()
    var
        NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
    begin
        NoSeriesSetupImpl.DeleteNoSeries(Rec);
    end;
}
