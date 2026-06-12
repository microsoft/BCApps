// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GST.Base;

using Microsoft.Finance.TaxEngine.TaxTypeHandler;

table 18012 "Retrun & Reco. Components"
{
    fields
    {
        field(1; "Component ID"; Integer)
        {
            Caption = 'Component ID';
            DataClassification = CustomerContent;
            NotBlank = True;

            trigger OnLookup()
            var
                TaxComponent: Record "Tax Component";
                GSTSetup: Record "GST Setup";
            begin
                if not GSTSetup.Get() then
                    exit;

                GSTSetup.TestField("GST Tax Type");
                TaxComponent.SetRange("Tax Type", GSTSetup."GST Tax Type");
                if Page.RunModal(Page::"Tax Components", TaxComponent) = Action::LookupOK then begin
                    "Component ID" := TaxComponent.Id;
                    "Component Name" := TaxComponent.Name;
                end;
            end;

            trigger OnValidate()
            var
                TaxComponent: Record "Tax Component";
                GSTSetup: Record "GST Setup";
            begin
                if xRec."Component ID" <> Rec."Component ID" then begin
                    if not GSTSetup.Get() then
                        exit;

                    GSTSetup.TestField("GST Tax Type");
                    TaxComponent.SetRange("Tax Type", GSTSetup."GST Tax Type");
                    TaxComponent.SetRange(Id, "Component ID");
                    TaxComponent.FindFirst();
                    "Component Name" := TaxComponent.Name;
                end;
            end;
        }
        field(2; "Component Name"; Text[30])
        {
            Caption = 'Component Name';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(3; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
    }

    keys
    {
        key(PK; "Component ID")
        {
            Clustered = true;
        }
        key(Sequence; "Sequence No.")
        {
        }
    }

    trigger OnInsert()
    var
        RetrunRecoComponents: Record "Retrun & Reco. Components";
    begin
        if "Sequence No." = 0 then begin
            RetrunRecoComponents.Reset();
            RetrunRecoComponents.SetCurrentKey("Sequence No.");
            if RetrunRecoComponents.FindLast() then
                "Sequence No." := RetrunRecoComponents."Sequence No." + 1
            else
                "Sequence No." := 1;
        end;
    end;
}
