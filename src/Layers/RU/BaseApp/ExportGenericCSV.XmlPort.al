// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.IO;

xmlport 1230 "Export Generic CSV"
{
    Caption = 'Export Generic CSV';
    Direction = Export;
    Format = VariableText;
    TextEncoding = WINDOWS;
    UseRequestPage = false;

    schema
    {
        textelement(root)
        {
            MinOccurs = Zero;
            tableelement("Data Exch. Field"; "Data Exch. Field")
            {
                XmlName = 'DataExchField';
                textelement(ColumnX)
                {
                    MinOccurs = Zero;
                    Unbound = true;

                    trigger OnBeforePassVariable()
                    begin
                        if QuitLoop then
                            currXMLport.BreakUnbound();

                        if ColumnsAsRows then begin
                            QuitLoop := true;
                            case "Data Exch. Field"."Column Type" of
                                "Data Exch. Field"."Column Type"::Header,
                              "Data Exch. Field"."Column Type"::Footer:
                                    if ("Data Exch. Field"."Column Name" <> "Data Exch. Field".Value) and
                                       ("Data Exch. Field"."Column Name" <> '')
                                    then
                                        ColumnX := "Data Exch. Field"."Column Name" + '=' + "Data Exch. Field".Value
                                    else
                                        ColumnX := "Data Exch. Field".Value;
                                else
                                    ColumnX := "Data Exch. Field"."Column Name" + '=' + "Data Exch. Field".Value;
                            end;
                        end else begin
                            if "Data Exch. Field"."Line No." <> LastLineNo then begin
                                if "Data Exch. Field"."Line No." <> LastLineNo + 1 then
                                    ErrorText += LinesNotSequentialErr
                                else begin
                                    LastLineNo := "Data Exch. Field"."Line No.";
                                    PrevColumnNo := 0;
                                    "Data Exch. Field".Next(-1);
                                    Window.Update(1, LastLineNo);
                                end;
                                currXMLport.BreakUnbound();
                            end;

                            CheckColumnSequence();
                            ColumnX := "Data Exch. Field".Value;

                            if "Data Exch. Field".Next() = 0 then
                                QuitLoop := true;
                        end;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if ColumnsAsRows then begin
                        QuitLoop := false;
                        if SkipHeaderFooterExport("Data Exch. Field") then
                            currXMLport.Skip();
                    end;
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

    trigger OnInitXmlPort()
    begin
        Window.Open(ProgressMsg);
    end;

    trigger OnPostXmlPort()
    begin
        if ErrorText <> '' then
            Error(ErrorText);

        Window.Close();

        if DataExch.Get(DataExchEntryNo) then
            if DataExchDef.Get(DataExch."Data Exch. Def Code") then
                currXMLport.Filename := DataExchDef.Name + '.csv';
    end;

    trigger OnPreXmlPort()
    begin
        InitializeGlobals();
    end;

    var
        DataExchDef: Record "Data Exch. Def";
        DataExch: Record "Data Exch.";
        Window: Dialog;
        ErrorText: Text;
        DataExchEntryNo: Integer;
        LastLineNo: Integer;
        PrevColumnNo: Integer;
        QuitLoop: Boolean;
        ColumnsNotSequentialErr: Label 'The data to be exported is not structured correctly. The columns in the dataset must be sequential.';
        LinesNotSequentialErr: Label 'The data to be exported is not structured correctly. The lines in the dataset must be sequential.';
#pragma warning disable AA0470
        ProgressMsg: Label 'Exporting line no. #1######';
#pragma warning restore AA0470
        ColumnsAsRows: Boolean;

    local procedure InitializeGlobals()
    begin
        DataExchEntryNo := "Data Exch. Field".GetRangeMin("Data Exch. No.");
        LastLineNo := 1;
        PrevColumnNo := 0;
        QuitLoop := false;

        if DataExch.Get(DataExchEntryNo) then
            if DataExchDef.Get(DataExch."Data Exch. Def Code") then begin
                ColumnsAsRows := DataExchDef."Columns as Rows";
                if ColumnsAsRows then
                    currXMLport.FieldDelimiter := '';
            end;

        OnAfterInitializeGlobals(DataExchEntryNo);
    end;

    procedure CheckColumnSequence()
    begin
        if "Data Exch. Field"."Column No." <> PrevColumnNo + 1 then begin
            ErrorText += ColumnsNotSequentialErr;
            currXMLport.BreakUnbound();
        end;

        PrevColumnNo := "Data Exch. Field"."Column No.";
    end;

    local procedure SkipHeaderFooterExport(DataExchFieldHeaderFooter: Record "Data Exch. Field"): Boolean
    var
        DataExchField: Record "Data Exch. Field";
    begin
        if DataExchFieldHeaderFooter."Column Type" = DataExchFieldHeaderFooter."Column Type"::" " then
            exit(false);

        DataExchField.SetRange("Data Exch. No.", DataExchFieldHeaderFooter."Data Exch. No.");
        DataExchField.SetRange("Column No.", DataExchFieldHeaderFooter."Column No.");
        case DataExchFieldHeaderFooter."Column Type" of
            DataExchFieldHeaderFooter."Column Type"::Header:
                begin
                    if (DataExchFieldHeaderFooter."Column Name" = DataExchDef."Document Start Tag") and
                       (DataExchDef."Document Start Tag" <> '')
                    then
                        exit(false);
                    DataExchField.SetFilter("Line No.", '<%1', DataExchFieldHeaderFooter."Line No.");
                end;
            DataExchFieldHeaderFooter."Column Type"::Footer:
                begin
                    if (DataExchFieldHeaderFooter."Column Name" = DataExchDef."Document End Tag") and
                       (DataExchDef."Document End Tag" <> '')
                    then
                        exit(false);
                    DataExchField.SetFilter("Line No.", '>%1', DataExchFieldHeaderFooter."Line No.");
                end;
        end;
        exit(not DataExchField.IsEmpty);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitializeGlobals(DataExchEntryNo: Integer)
    begin
    end;
}

