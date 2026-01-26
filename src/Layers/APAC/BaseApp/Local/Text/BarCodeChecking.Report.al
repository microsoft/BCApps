// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Text;

using Microsoft.Foundation.Address;

report 28000 "BarCode Checking"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Text/BarCodeChecking.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'BarCode Checking';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(PrintAddressID; "Address ID")
        {
            DataItemTableView = sorting("Table No.", "Table Key", "Address Type") order(ascending);
            column(USERID; UserId)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(PrintAddressID__Table_Key_; "Table Key")
            {
            }
            column(PrintAddressID__Address_Type_; "Address Type")
            {
            }
            column(PrintAddressID__Address_ID_; "Address ID")
            {
            }
            column(PrintAddressID__Address_Sort_Plan_; "Address Sort Plan")
            {
            }
            column(PrintAddressID__Error_Flag_No__; "Error Flag No.")
            {
            }
            column(RecTableName; RecTableName)
            {
            }
            column(RecCode; RecCode)
            {
            }
            column(RecName; RecName)
            {
            }
            column(PrintAddressID_Table_No_; "Table No.")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Bar_Code_CheckingCaption; Bar_Code_CheckingCaptionLbl)
            {
            }
            column(RecTableNameCaption; RecTableNameCaptionLbl)
            {
            }
            column(PrintAddressID__Table_Key_Caption; FieldCaption("Table Key"))
            {
            }
            column(PrintAddressID__Address_Type_Caption; FieldCaption("Address Type"))
            {
            }
            column(PrintAddressID__Address_ID_Caption; FieldCaption("Address ID"))
            {
            }
            column(PrintAddressID__Address_Sort_Plan_Caption; FieldCaption("Address Sort Plan"))
            {
            }
            column(PrintAddressID__Error_Flag_No__Caption; PrintAddressID__Error_Flag_No__CaptionLbl)
            {
            }
            column(RecCodeCaption; RecCodeCaptionLbl)
            {
            }
            column(RecNameCaption; RecNameCaptionLbl)
            {
            }
            column(Refer_to_the_documentation_of_the_AMAS_software_Caption; Refer_to_the_documentation_of_the_AMAS_software_CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if CurrentRec = 0 then begin
                    if not TempAddressID.Find('-') then
                        CurrReport.Break();
                end else
                    if TempAddressID.Next() = 0 then
                        CurrReport.Break();

                if (TempAddressID."Error Flag No." = '') and ShowErrorOnly then
                    CurrReport.Skip();

                RecCode := '';
                RecName := '';
                RecTableName := '';
                PrintAddressID := TempAddressID;
                CurrentRec := CurrentRec + 1;
                case TempAddressID."Table No." of
                    14:
                        GetPrimaryKey(14, TempAddressID."Table Key", 1, 2);
                    18:
                        GetPrimaryKey(18, TempAddressID."Table Key", 1, 2);
                    23:
                        GetPrimaryKey(23, TempAddressID."Table Key", 1, 2);
                    79:
                        GetPrimaryKey(79, TempAddressID."Table Key", 1, 2);
                    156:
                        GetPrimaryKey(156, TempAddressID."Table Key", 1, 3);
                    222:
                        GetPrimaryKey(222, TempAddressID."Table Key", 1, 3);
                    224:
                        GetPrimaryKey(224, TempAddressID."Table Key", 1, 3);
                    270:
                        GetPrimaryKey(270, TempAddressID."Table Key", 1, 2);
                    287:
                        GetPrimaryKey(287, TempAddressID."Table Key", 1, 3);
                    288:
                        GetPrimaryKey(288, TempAddressID."Table Key", 1, 3);
                    5200:
                        GetPrimaryKey(5200, TempAddressID."Table Key", 1, 4);
                    5201:
                        GetPrimaryKey(5201, TempAddressID."Table Key", 1, 3);
                    5209:
                        GetPrimaryKey(5209, TempAddressID."Table Key", 1, 2);
                    5714:
                        GetPrimaryKey(5714, TempAddressID."Table Key", 1, 2);
                    5050:
                        GetPrimaryKey(5050, TempAddressID."Table Key", 1, 2);
                    5051:
                        GetPrimaryKey(5051, TempAddressID."Table Key", 1, 3);
                end;
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(Text1500001);
                if CheckMasterCard then begin
                    GetAddressID(14);
                    GetAddressID(18);
                    GetAddressID(23);
                    GetAddressID(79);
                    GetAddressID(156);
                    GetAddressID(222);
                    GetAddressID(224);
                    GetAddressID(270);
                    GetAddressID(287);
                    GetAddressID(288);
                    GetAddressID(5200);
                    GetAddressID(5201);
                    GetAddressID(5209);
                    GetAddressID(5714);
                end;
                if CheckContactCard then begin
                    GetAddressID(5050);
                    GetAddressID(5051);
                end;
                CurrentRec := 0;

                Window.Close();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CheckMasterCard; CheckMasterCard)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Check Master Cards';
                        ToolTip = 'Specifies that you want to verify addresses for master data.';
                    }
                    field(CheckContactCard; CheckContactCard)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Check Contact Cards';
                        ToolTip = 'Specifies that you want to verify addresses for contacts.';
                    }
                    field(ShowErrorOnly; ShowErrorOnly)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Errors Only';
                        ToolTip = 'Specifies if the report must only show error information.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        AddressID: Record "Address ID";
        TempAddressID: Record "Address ID" temporary;
        CheckMasterCard: Boolean;
        CheckContactCard: Boolean;
        ShowErrorOnly: Boolean;
        Window: Dialog;
        CurrentRec: Integer;
        RecCode: Code[20];
        RecName: Text[90];
        RecTableName: Text[30];
        Text1500001: Label 'Retrieving Table No.    #1######\\@2@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Bar_Code_CheckingCaptionLbl: Label 'Bar Code Checking';
        RecTableNameCaptionLbl: Label 'Table Name';
        PrintAddressID__Error_Flag_No__CaptionLbl: Label 'Error Flag No. (*)';
        RecCodeCaptionLbl: Label 'Code';
        RecNameCaptionLbl: Label 'Name';
        Refer_to_the_documentation_of_the_AMAS_software_CaptionLbl: Label '(*) Refer to the documentation of the AMAS software.';

    local procedure GetPrimaryKey(TableNo: Integer; PrimaryKey: Text[1024]; CodeFieldNo: Integer; NameFieldNo: Integer)
    var
        RecordRef: RecordRef;
        CodeFieldRef: FieldRef;
        NameFieldRef: FieldRef;
    begin
        RecordRef.Open(TableNo);
        RecordRef.SetPosition(PrimaryKey);
        if RecordRef.Get(RecordRef.RecordId) then begin
            CodeFieldRef := RecordRef.Field(CodeFieldNo);
            NameFieldRef := RecordRef.Field(NameFieldNo);
            RecTableName := RecordRef.Caption;
            RecCode := CodeFieldRef.Value();
            RecName := NameFieldRef.Value();
        end;
        RecordRef.Close();
    end;

    local procedure GetAddressID(TableNo: Integer)
    var
        BarCodeManagement: Codeunit "BarCode Management";
        TotalRec: Integer;
        LocalCurrentRec: Integer;
    begin
        Window.Update(1, TableNo);
        AddressID.SetRange("Table No.", TableNo);
        TotalRec := AddressID.Count();
        LocalCurrentRec := 1;
        if AddressID.Find('-') then
            repeat
                Window.Update(2, Round((LocalCurrentRec / TotalRec) * 10000, 1));
                TempAddressID.Init();
                TempAddressID := AddressID;
                if AddressID."Bar Code System" = AddressID."Bar Code System"::"4-State Bar Code" then
                    BarCodeManagement.BuildBarCode(AddressID."Address ID", '', TempAddressID."Bar Code");
                TempAddressID.Insert();
                LocalCurrentRec := LocalCurrentRec + 1;
            until AddressID.Next() = 0;
    end;
}

