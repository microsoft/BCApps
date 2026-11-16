// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax.Employee;

using Microsoft.WithholdingTax;

table 6793 "Withholding Tax Group Line"
{
    Caption = 'Withholding Tax Group Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Group Code"; Code[20])
        {
            Caption = 'Group Code';
            TableRelation = "Withholding Tax Group";
            ToolTip = 'Specifies the withholding tax group code for this component.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the line number for this component.';
        }
        field(3; "Wthldg. Tax Prod. Post. Group"; Code[20])
        {
            Caption = 'Withholding Tax Prod. Post. Group';
            TableRelation = "Wthldg. Tax Prod. Post. Group";
            ToolTip = 'Specifies the withholding tax product posting group for this component.';
        }
        field(4; "Component Order"; Integer)
        {
            Caption = 'Component Order';
            MinValue = 1;
            ToolTip = 'Specifies the calculation order for compound withholding tax. Lower numbers are calculated first.';
        }
        field(5; "Compound Base Includes"; Text[250])
        {
            Caption = 'Compound Base Includes';
            ToolTip = 'Specifies comma-separated product posting group codes whose tax amounts are included in the base for this component when using compound calculation.';

            trigger OnValidate()
            begin
                ValidateCompoundBaseIncludes();
            end;

            trigger OnLookup()
            begin
                LookupCompoundBaseIncludes();
            end;
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description for this component.';
        }
    }

    keys
    {
        key(Key1; "Group Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Group Code", "Component Order")
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("Group Code");
    end;

    var
        InvalidProdPostGroupErr: Label 'The withholding tax product posting group %1 in %2 does not exist.', Comment = '%1 = product posting group code, %2 = Compound Base Includes field caption';
        DuplicateProdPostGroupErr: Label 'The withholding tax product posting group %1 is listed more than once in %2.', Comment = '%1 = product posting group code, %2 = Compound Base Includes field caption';

    procedure ValidateCompoundBaseIncludes()
    var
        WthldgTaxProdPostGroup: Record "Wthldg. Tax Prod. Post. Group";
        Tokens: List of [Text];
        NormalizedCodes: List of [Text];
        Token: Text;
        NormalizedToken: Code[20];
    begin
        if "Compound Base Includes" = '' then
            exit;

        Tokens := "Compound Base Includes".Split(',');
        foreach Token in Tokens do begin
            NormalizedToken := CopyStr(UpperCase(DelChr(Token, '<>', ' ')), 1, MaxStrLen(NormalizedToken));
            if NormalizedToken <> '' then begin
                if not WthldgTaxProdPostGroup.Get(NormalizedToken) then
                    Error(InvalidProdPostGroupErr, NormalizedToken, FieldCaption("Compound Base Includes"));
                if NormalizedCodes.Contains(NormalizedToken) then
                    Error(DuplicateProdPostGroupErr, NormalizedToken, FieldCaption("Compound Base Includes"));
                NormalizedCodes.Add(NormalizedToken);
            end;
        end;

        "Compound Base Includes" := CopyStr(JoinCodes(NormalizedCodes, ', '), 1, MaxStrLen("Compound Base Includes"));
    end;

    procedure LookupCompoundBaseIncludes()
    var
        WthldgTaxProdPostGroup: Record "Wthldg. Tax Prod. Post. Group";
        ProdPostGroupList: Page "Wthldg. Tax Prod. Post. Group";
        SelectedCodes: List of [Text];
    begin
        ProdPostGroupList.LookupMode(true);
        if ProdPostGroupList.RunModal() <> Action::LookupOK then
            exit;

        ProdPostGroupList.SetSelectionFilter(WthldgTaxProdPostGroup);
        if WthldgTaxProdPostGroup.FindSet() then
            repeat
                SelectedCodes.Add(WthldgTaxProdPostGroup.Code);
            until WthldgTaxProdPostGroup.Next() = 0;

        Validate("Compound Base Includes", CopyStr(JoinCodes(SelectedCodes, ', '), 1, MaxStrLen("Compound Base Includes")));
    end;

    procedure GetCompoundBaseIncludesList() NormalizedCodes: List of [Text]
    var
        Tokens: List of [Text];
        Token: Text;
        NormalizedToken: Text;
    begin
        if "Compound Base Includes" = '' then
            exit;

        Tokens := "Compound Base Includes".Split(',');
        foreach Token in Tokens do begin
            NormalizedToken := UpperCase(DelChr(Token, '<>', ' '));
            if (NormalizedToken <> '') and (not NormalizedCodes.Contains(NormalizedToken)) then
                NormalizedCodes.Add(NormalizedToken);
        end;
    end;

    procedure IncludesProdPostGroup(ProdPostGroupCode: Code[20]): Boolean
    begin
        exit(GetCompoundBaseIncludesList().Contains(UpperCase(ProdPostGroupCode)));
    end;

    procedure GetCompoundBaseIncludesFilter(): Text
    begin
        exit(JoinCodes(GetCompoundBaseIncludesList(), '|'));
    end;

    local procedure JoinCodes(Codes: List of [Text]; Separator: Text): Text
    var
        CodeItem: Text;
        Result: TextBuilder;
    begin
        foreach CodeItem in Codes do begin
            if Result.Length() > 0 then
                Result.Append(Separator);
            Result.Append(CodeItem);
        end;
        exit(Result.ToText());
    end;
}
