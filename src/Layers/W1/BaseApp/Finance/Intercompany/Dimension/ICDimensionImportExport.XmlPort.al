// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Dimension;

using Microsoft.Intercompany.GLAccount;
using System.Telemetry;

xmlport 11 "IC Dimension Import/Export"
{
    Caption = 'IC Dimension Import/Export';
    FormatEvaluate = Xml;

    schema
    {
        textelement(ICDimensions)
        {
            tableelement(icdim; "IC Dimension")
            {
                XmlName = 'ICDim';
                fieldattribute(Code; ICDim.Code)
                {
                }
                fieldattribute(Name; ICDim.Name)
                {
                }
                fieldattribute(Blocked; ICDim.Blocked)
                {
                }
                tableelement(icdimval; "IC Dimension Value")
                {
                    LinkFields = "Dimension Code" = field(Code);
                    LinkTable = ICDim;
                    XmlName = 'ICDimVal';
                    fieldattribute(DimCode; ICDimVal."Dimension Code")
                    {
                    }
                    fieldattribute(Code; ICDimVal.Code)
                    {
                    }
                    fieldattribute(Name; ICDimVal.Name)
                    {
                    }
                    fieldattribute(DimValType; ICDimVal."Dimension Value Type")
                    {
                    }
                    fieldattribute(Blocked; ICDimVal.Blocked)
                    {
                    }
                    fieldattribute(Indentation; ICDimVal.Indentation)
                    {
                    }

                    trigger OnBeforeInsertRecord()
                    var
                        OrgICDimVal: Record "IC Dimension Value";
                    begin
                        XMLInbound := true;

                        if TempICDimVal.Get(ICDimVal."Dimension Code", ICDimVal.Code) then begin
                            if (ICDimVal.Name <> TempICDimVal.Name) or
                               (ICDimVal."Dimension Value Type" <> TempICDimVal."Dimension Value Type") or
                               (ICDimVal.Blocked <> TempICDimVal.Blocked)
                            then
                                Modified[2] := Modified[2] + 1;
                            ICDimVal."Map-to Dimension Code" := TempICDimVal."Map-to Dimension Code";
                            ICDimVal."Map-to Dimension Value Code" := TempICDimVal."Map-to Dimension Value Code";
                            OrgICDimVal.Get(ICDimVal."Dimension Code", ICDimVal.Code);
                            OrgICDimVal.Delete();
                            TempICDimVal.Delete();
                        end else
                            Inserted[2] := Inserted[2] + 1;
                    end;
                }

                trigger OnBeforeInsertRecord()
                var
                    OrgICDim: Record "IC Dimension";
                begin
                    XMLInbound := true;

                    if TempICDim.Get(ICDim.Code) then begin
                        if (ICDim.Name <> TempICDim.Name) or (ICDim.Blocked <> TempICDim.Blocked) then
                            Modified[1] := Modified[1] + 1;
                        ICDim."Map-to Dimension Code" := TempICDim."Map-to Dimension Code";
                        OrgICDim.Get(ICDim.Code);
                        OrgICDim.Delete();
                        TempICDim.Delete();
                    end else
                        Inserted[1] := Inserted[1] + 1;
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    trigger OnPostXmlPort()
    var
        OrgICDim: Record "IC Dimension";
        OrgICDimVal: Record "IC Dimension Value";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        MsgTxt: Text[1024];
    begin
        FeatureTelemetry.LogUptake('0000IKO', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
        FeatureTelemetry.LogUsage('0000IKP', ICMapping.GetFeatureTelemetryName(), 'IC Dimensions Import/Export');

        if XMLInbound then begin
            if TempICDimVal.Find('-') then
                repeat
                    Deleted[2] := Deleted[2] + 1;
                    OrgICDimVal.Get(TempICDimVal."Dimension Code", TempICDimVal.Code);
                    OrgICDimVal.Delete();
                until TempICDimVal.Next() = 0;
            if TempICDim.Find('-') then
                repeat
                    Deleted[1] := Deleted[1] + 1;
                    OrgICDim.Get(TempICDim.Code);
                    OrgICDim.Delete();
                until TempICDim.Next() = 0;

            Inserted[1] := Inserted[1] + Inserted[2];
            Modified[1] := Modified[1] + Modified[2];
            Deleted[1] := Deleted[1] + Deleted[2];

            if Inserted[1] > 0 then
                if Inserted[1] = 1 then
                    MsgTxt := StrSubstNo(Text001, Inserted[1])
                else
                    MsgTxt := StrSubstNo(Text002, Inserted[1]);

            if Modified[1] > 0 then begin
                if MsgTxt <> '' then
                    MsgTxt := MsgTxt + '\';
                if Modified[1] = 1 then
                    MsgTxt := MsgTxt + StrSubstNo(Text003, Modified[1])
                else
                    MsgTxt := MsgTxt + StrSubstNo(Text004, Modified[1]);
            end;

            if Deleted[1] > 0 then begin
                if MsgTxt <> '' then
                    MsgTxt := MsgTxt + '\';
                if Deleted[1] = 1 then
                    MsgTxt := MsgTxt + StrSubstNo(Text005, Deleted[1])
                else
                    MsgTxt := MsgTxt + StrSubstNo(Text006, Deleted[1]);
            end;

            if Inserted[1] + Deleted[1] + Modified[1] = 0 then
                MsgTxt := Text000;

            Message(MsgTxt);
        end;
    end;

    trigger OnPreXmlPort()
    var
        ICDim2: Record "IC Dimension";
        ICDimVal2: Record "IC Dimension Value";
    begin
        TempICDim.DeleteAll();
        TempICDimVal.DeleteAll();

        if ICDim2.Find('-') then
            repeat
                TempICDim := ICDim2;
                TempICDim.Insert();
            until ICDim2.Next() = 0;

        if ICDimVal2.Find('-') then
            repeat
                TempICDimVal := ICDimVal2;
                TempICDimVal.Insert();
            until ICDimVal2.Next() = 0;
    end;

    var
        TempICDim: Record "IC Dimension" temporary;
        TempICDimVal: Record "IC Dimension Value" temporary;
        XMLInbound: Boolean;
        Inserted: array[2] of Integer;
        Deleted: array[2] of Integer;
        Modified: array[2] of Integer;
#pragma warning disable AA0074
        Text000: Label 'There were no changes.';
#pragma warning disable AA0470
        Text001: Label '%1 record was added.';
        Text002: Label '%1 records were added.';
        Text003: Label '%1 record was updated.';
        Text004: Label '%1 records were updated.';
        Text005: Label '%1 record was deleted.';
        Text006: Label '%1 records were deleted.';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

