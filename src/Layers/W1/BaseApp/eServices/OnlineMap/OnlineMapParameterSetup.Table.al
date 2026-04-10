// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.OnlineMap;

using System.Utilities;

table 801 "Online Map Parameter Setup"
{
    Caption = 'Online Map Parameter Setup';
    LookupPageID = "Online Map Parameter Setup";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a descriptive code for the map that you set up, for example, BING.';
            NotBlank = true;
        }
        field(2; Name; Text[30])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the country/region. If you have selected the country/region code, the name is automatically inserted into this field.';
        }
        field(3; "Map Service"; Text[250])
        {
            Caption = 'Map Service';
            ToolTip = 'Specifies the URL for the online map.';
        }
        field(4; "Directions Service"; Text[250])
        {
            Caption = 'Directions Service';
            ToolTip = 'Specifies the URL for directions an on online map.';

            trigger OnValidate()
            var
                i: Integer;
                ParmPos: Integer;
                RemainingURL: Text[250];
            begin
                for i := 1 to 6 do begin
                    ParmPos := StrPos("Directions Service", StrSubstNo('{%1}', i));
                    if ParmPos > 1 then begin
                        RemainingURL := CopyStr("Directions Service", ParmPos + 3);
                        ParmPos := StrPos(RemainingURL, StrSubstNo('{%1}', i));
                        if not (ParmPos > 1) then
                            Error(AddressParametersDuplicateErr, i);
                        RemainingURL := CopyStr(RemainingURL, ParmPos + 3);
                        if StrPos(RemainingURL, StrSubstNo('{%1}', i)) > 1 then
                            Error(AddressParametersDuplicateErr, i);
                    end;
                end;
            end;
        }
        field(5; Comment; Text[250])
        {
            Caption = 'Comment';
            ToolTip = 'Specifies a comment. The field is optional, and you can enter a maximum of 30 characters, both numbers and letters.';
        }
        field(6; "URL Encode Non-ASCII Chars"; Boolean)
        {
            Caption = 'URL Encode Non-ASCII Chars';
            ToolTip = 'Specifies whether the URL is Non-ASCII encoded.';
        }
        field(7; "Miles/Kilometers Option List"; Text[250])
        {
            Caption = 'Miles/Kilometers Option List';
            ToolTip = 'Specifies the options that measure the route distance.';
        }
        field(8; "Quickest/Shortest Option List"; Text[250])
        {
            Caption = 'Quickest/Shortest Option List';
            ToolTip = 'Specifies the option for calculating the quickest or the shortest route.';
        }
        field(9; "Directions from Location Serv."; Text[250])
        {
            Caption = 'Directions from Location Serv.';
            ToolTip = 'Specifies the URL for directions from your location an on online map.';
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
        fieldgroup(DropDown; "Code", Name)
        {
        }
    }

    trigger OnInsert()
    begin
        TestField(Code);
    end;

    var
        ConfirmDefaultInsertQst: Label 'Inserting default values will delete your current setup.\Do you wish to continue?';
#pragma warning disable AA0470
        AddressParametersDuplicateErr: Label 'Address parameters must only occur twice in the Directions URL. Validate the use of {%1}.';
#pragma warning restore AA0470

    procedure InsertDefaults()
    var
        OnlineMapParameterSetup: Record "Online Map Parameter Setup";
        OnlineMapMgt: Codeunit "Online Map Management";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not OnlineMapParameterSetup.IsEmpty() then
            if not ConfirmManagement.GetResponseOrDefault(ConfirmDefaultInsertQst, false) then
                exit;
        OnlineMapMgt.SetupDefault();
    end;
}

