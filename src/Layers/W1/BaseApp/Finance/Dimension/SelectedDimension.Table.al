// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.Analysis;
using System.Security.AccessControl;

table 369 "Selected Dimension"
{
    Caption = 'Selected Dimension';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(2; "Object Type"; Integer)
        {
            Caption = 'Object Type';
        }
        field(3; "Object ID"; Integer)
        {
            Caption = 'Object ID';
        }
        field(4; "Dimension Code"; Text[30])
        {
            Caption = 'Dimension Code';
        }
        field(5; "New Dimension Value Code"; Code[20])
        {
            Caption = 'New Dimension Value Code';
        }
        field(6; "Dimension Value Filter"; Code[250])
        {
            Caption = 'Dimension Value Filter';
        }
        field(7; Level; Option)
        {
            Caption = 'Level';
            OptionCaption = ' ,Level 1,Level 2,Level 3,Level 4';
            OptionMembers = " ","Level 1","Level 2","Level 3","Level 4";
        }
        field(8; "Analysis View Code"; Code[10])
        {
            Caption = 'Analysis View Code';
            TableRelation = "Analysis View";
        }
    }

    keys
    {
        key(Key1; "User ID", "Object Type", "Object ID", "Analysis View Code", "Dimension Code")
        {
            Clustered = true;
        }
        key(Key2; "User ID", "Object Type", "Object ID", "Analysis View Code", Level, "Dimension Code")
        {
        }
    }

    fieldgroups
    {
    }

    procedure GetSelectedDim(UserID2: Code[50]; ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10]; var TempSelectedDim: Record "Selected Dimension" temporary)
    begin
        SetRange("User ID", UserID2);
        SetRange("Object Type", ObjectType);
        SetRange("Object ID", ObjectID);
        SetRange("Analysis View Code", AnalysisViewCode);
        if Find('-') then
            repeat
                TempSelectedDim := Rec;
                TempSelectedDim.Insert();
            until Next() = 0;
    end;
}

