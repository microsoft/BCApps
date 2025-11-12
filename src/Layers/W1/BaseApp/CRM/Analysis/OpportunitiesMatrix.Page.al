// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Analysis;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Team;
using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using System.Utilities;

page 9257 "Opportunities Matrix"
{
    Caption = 'Opportunities Matrix';
    DataCaptionExpression = Format(OutPutOption);
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "RM Matrix Management";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Campaign: Record Campaign;
                        SalesPurchPerson: Record "Salesperson/Purchaser";
                        Contact: Record Contact;
                    begin
                        case TableType of
                            TableType::"Sales Person":
                                begin
                                    SalesPurchPerson.Get(Rec."No.");
                                    PAGE.RunModal(0, SalesPurchPerson);
                                end;
                            TableType::Campaign:
                                begin
                                    Campaign.Get(Rec."No.");
                                    PAGE.RunModal(0, Campaign);
                                end;
                            TableType::Contact:
                                begin
                                    Contact.Get(Rec."No.");
                                    PAGE.RunModal(0, Contact);
                                end;
                        end;
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = RelationshipMgmt;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the name of the opportunity.';
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[1];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field1Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(1);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[2];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field2Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(2);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[3];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field3Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(3);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[4];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field4Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(4);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[5];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field5Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(5);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[6];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field6Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(6);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[7];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field7Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(7);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[8];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field8Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(8);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[9];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field9Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(9);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[10];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field10Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(10);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[11];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field11Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(11);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[12];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field12Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(12);
                    end;
                }
                field(Field13; MATRIX_CellData[13])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[13];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field13Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(13);
                    end;
                }
                field(Field14; MATRIX_CellData[14])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[14];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field14Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(14);
                    end;
                }
                field(Field15; MATRIX_CellData[15])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[15];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field15Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(15);
                    end;
                }
                field(Field16; MATRIX_CellData[16])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[16];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field16Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(16);
                    end;
                }
                field(Field17; MATRIX_CellData[17])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[17];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field17Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(17);
                    end;
                }
                field(Field18; MATRIX_CellData[18])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[18];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field18Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(18);
                    end;
                }
                field(Field19; MATRIX_CellData[19])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[19];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field19Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(19);
                    end;
                }
                field(Field20; MATRIX_CellData[20])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[20];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field20Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(20);
                    end;
                }
                field(Field21; MATRIX_CellData[21])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[21];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field21Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(21);
                    end;
                }
                field(Field22; MATRIX_CellData[22])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[22];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field22Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(22);
                    end;
                }
                field(Field23; MATRIX_CellData[23])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[23];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field23Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(23);
                    end;
                }
                field(Field24; MATRIX_CellData[24])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[24];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field24Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(24);
                    end;
                }
                field(Field25; MATRIX_CellData[25])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[25];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field25Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(25);
                    end;
                }
                field(Field26; MATRIX_CellData[26])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[26];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field26Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(26);
                    end;
                }
                field(Field27; MATRIX_CellData[27])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[27];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field27Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(27);
                    end;
                }
                field(Field28; MATRIX_CellData[28])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[28];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field28Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(28);
                    end;
                }
                field(Field29; MATRIX_CellData[29])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[29];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field29Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(29);
                    end;
                }
                field(Field30; MATRIX_CellData[30])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[30];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field30Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(30);
                    end;
                }
                field(Field31; MATRIX_CellData[31])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[31];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field31Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(31);
                    end;
                }
                field(Field32; MATRIX_CellData[32])
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    CaptionClass = '3,' + MATRIX_CaptionSet[32];
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = Field32Visible;

                    trigger OnDrillDown()
                    begin
                        SetFilters();
                        MATRIX_OnDrillDown(32);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        MATRIX_CurrentColumnOrdinal: Integer;
    begin
        StyleIsStrong := Rec.Type = Rec.Type::Company;
        if (Rec.Type = Rec.Type::Person) and (TableType = TableType::Contact) then
            NameIndent := 1
        else
            NameIndent := 0;

        MATRIX_CurrentColumnOrdinal := 0;
        while MATRIX_CurrentColumnOrdinal < MATRIX_CurrentNoOfMatrixColumn do begin
            MATRIX_CurrentColumnOrdinal := MATRIX_CurrentColumnOrdinal + 1;
            MATRIX_OnAfterGetRecord(MATRIX_CurrentColumnOrdinal);
        end;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(FindRec(TableType, Rec, Which));
    end;

    trigger OnInit()
    begin
        Field32Visible := true;
        Field31Visible := true;
        Field30Visible := true;
        Field29Visible := true;
        Field28Visible := true;
        Field27Visible := true;
        Field26Visible := true;
        Field25Visible := true;
        Field24Visible := true;
        Field23Visible := true;
        Field22Visible := true;
        Field21Visible := true;
        Field20Visible := true;
        Field19Visible := true;
        Field18Visible := true;
        Field17Visible := true;
        Field16Visible := true;
        Field15Visible := true;
        Field14Visible := true;
        Field13Visible := true;
        Field12Visible := true;
        Field11Visible := true;
        Field10Visible := true;
        Field9Visible := true;
        Field8Visible := true;
        Field7Visible := true;
        Field6Visible := true;
        Field5Visible := true;
        Field4Visible := true;
        Field3Visible := true;
        Field2Visible := true;
        Field1Visible := true;
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(NextRec(TableType, Rec, Steps));
    end;

    trigger OnOpenPage()
    begin
        TestFilters();
        ValidateStatus();
        ValidateFilter();
        SetColumnVisibility();
    end;

    var
#pragma warning disable AA0074
        Text000: Label '<Sign><Integer>', Locked = true;
        Text001: Label '<Sign><Integer Thousand><Decimals,2>', Locked = true;
#pragma warning restore AA0074
        MatrixRecords: array[32] of Record Date;
        TempOpp: Record Opportunity temporary;
        OppEntry: Record "Opportunity Entry";
        Opp: Record Opportunity;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Cont: Record Contact;
        Campaign: Record Campaign;
        MatrixMgt: Codeunit "Matrix Management";
        OptionStatusFilter: Option "In Progress",Won,Lost;
        OutputOption: Enum "Opportunity Output";
        RoundingFactor: Enum "Analysis Rounding Factor";
        TableType: Enum "Opportunity Table Type";
        MATRIX_CurrentNoOfMatrixColumn: Integer;
        MATRIX_CellData: array[32] of Text[80];
        MATRIX_CaptionSet: array[32] of Text[80];
        EstimatedValueFilter: Text;
        SalesCycleStageFilter: Text;
        SuccessChanceFilter: Text;
        ProbabilityFilter: Text;
        CompletedFilter: Text;
        CalcdCurrentValueFilter: Text;
        SalesCycleFilter: Text;
        RoundingFactorFormatString: Text;
        StyleIsStrong: Boolean;
        NameIndent: Integer;
        Field1Visible: Boolean;
        Field2Visible: Boolean;
        Field3Visible: Boolean;
        Field4Visible: Boolean;
        Field5Visible: Boolean;
        Field6Visible: Boolean;
        Field7Visible: Boolean;
        Field8Visible: Boolean;
        Field9Visible: Boolean;
        Field10Visible: Boolean;
        Field11Visible: Boolean;
        Field12Visible: Boolean;
        Field13Visible: Boolean;
        Field14Visible: Boolean;
        Field15Visible: Boolean;
        Field16Visible: Boolean;
        Field17Visible: Boolean;
        Field18Visible: Boolean;
        Field19Visible: Boolean;
        Field20Visible: Boolean;
        Field21Visible: Boolean;
        Field22Visible: Boolean;
        Field23Visible: Boolean;
        Field24Visible: Boolean;
        Field25Visible: Boolean;
        Field26Visible: Boolean;
        Field27Visible: Boolean;
        Field28Visible: Boolean;
        Field29Visible: Boolean;
        Field30Visible: Boolean;
        Field31Visible: Boolean;
        Field32Visible: Boolean;

    local procedure SetFilters()
    begin
        case TableType of
            TableType::"Sales Person":
                Rec.SetRange("Salesperson Filter", Rec."No.");
            TableType::Campaign:
                Rec.SetRange("Campaign Filter", Rec."No.");
            TableType::Contact:
                if Rec.Type = Rec.Type::Company then begin
                    Rec.SetRange("Contact Filter");
                    Rec.SetRange("Contact Company Filter", Rec."Company No.");
                end else begin
                    Rec.SetRange("Contact Filter", Rec."No.");
                    Rec.SetRange("Contact Company Filter", Rec."Company No.");
                end;
        end;
    end;

    local procedure ReturnOutput(): Decimal
    begin
        case OutPutOption of
            OutPutOption::"No of Opportunities":
                exit(Rec."No. of Opportunities");
            OutPutOption::"Estimated Value (LCY)":
                exit(Rec."Estimated Value (LCY)");
            OutPutOption::"Calc. Current Value (LCY)":
                exit(Rec."Calcd. Current Value (LCY)");
            OutPutOption::"Avg. Estimated Value (LCY)":
                exit(Rec."Avg. Estimated Value (LCY)");
            OutPutOption::"Avg. Calc. Current Value (LCY)":
                exit(Rec."Avg.Calcd. Current Value (LCY)");
        end;
    end;

    local procedure FormatAmount(var Text: Text[250])
    var
        Amount: Decimal;
    begin
        if Text <> '' then begin
            Evaluate(Amount, Text);
            if OutPutOption = OutPutOption::"No of Opportunities" then
                Text := Format(Amount, 0, Text000);
            Amount := MatrixMgt.RoundAmount(Amount, RoundingFactor);
            if Amount = 0 then
                Text := ''
            else
                case RoundingFactor of
                    RoundingFactor::"1":
                        Text := Format(Amount);
                    RoundingFactor::"1000", RoundingFactor::"1000000":
                        Text := Format(Amount, 0, Text001);
                end;
        end;
    end;

    local procedure FindRec(TableType: Enum "Opportunity Table Type"; var RMMatrixMgt: Record "RM Matrix Management"; Which: Text[250]): Boolean
    var
        Found: Boolean;
    begin
        case TableType of
            TableType::"Sales Person":
                begin
                    RMMatrixMgt."No." := CopyStr(RMMatrixMgt."No.", 1, MaxStrLen(SalespersonPurchaser.Code));
                    SalespersonPurchaser.Code := CopyStr(RMMatrixMgt."No.", 1, MaxStrLen(SalespersonPurchaser.Code));
                    Found := SalespersonPurchaser.Find(Which);
                    if Found then
                        CopySalespersonToBuf(SalespersonPurchaser, RMMatrixMgt);
                end;
            TableType::Campaign:
                begin
                    Campaign."No." := RMMatrixMgt."No.";
                    Found := Campaign.Find(Which);
                    if Found then
                        CopyCampaignToBuf(Campaign, RMMatrixMgt);
                end;
            TableType::Contact:
                begin
                    Cont."Company Name" := RMMatrixMgt."Company Name";
                    Cont.Type := RMMatrixMgt.Type;
                    Cont.Name := RMMatrixMgt.Name;
                    Cont."No." := RMMatrixMgt."No.";
                    Cont."Company No." := RMMatrixMgt."Company No.";
                    Found := Cont.Find(Which);
                    if Found then
                        CopyContactToBuf(Cont, RMMatrixMgt);
                end;
        end;
        exit(Found);
    end;

    local procedure NextRec(TableType: Enum "Opportunity Table Type"; var RMMatrixMgt: Record "RM Matrix Management"; Steps: Integer): Integer
    var
        ResultSteps: Integer;
    begin
        case TableType of
            TableType::"Sales Person":
                begin
                    RMMatrixMgt."No." := CopyStr(RMMatrixMgt."No.", 1, MaxStrLen(SalespersonPurchaser.Code));
                    SalespersonPurchaser.Code := CopyStr(RMMatrixMgt."No.", 1, MaxStrLen(SalespersonPurchaser.Code));
                    ResultSteps := SalespersonPurchaser.Next(Steps);
                    if ResultSteps <> 0 then
                        CopySalespersonToBuf(SalespersonPurchaser, RMMatrixMgt);
                end;
            TableType::Campaign:
                begin
                    Campaign."No." := RMMatrixMgt."No.";
                    ResultSteps := Campaign.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyCampaignToBuf(Campaign, RMMatrixMgt);
                end;
            TableType::Contact:
                begin
                    Cont."Company Name" := RMMatrixMgt."Company Name";
                    Cont.Type := RMMatrixMgt.Type;
                    Cont.Name := RMMatrixMgt.Name;
                    Cont."No." := RMMatrixMgt."No.";
                    Cont."Company No." := RMMatrixMgt."Company No.";
                    ResultSteps := Cont.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyContactToBuf(Cont, RMMatrixMgt);
                end;
        end;
        exit(ResultSteps);
    end;

    local procedure CopySalespersonToBuf(var SalesPurchPerson: Record "Salesperson/Purchaser"; var RMMatrixMgt: Record "RM Matrix Management")
    begin
        RMMatrixMgt.Init();
        RMMatrixMgt."Company Name" := SalesPurchPerson.Code;
        RMMatrixMgt.Type := RMMatrixMgt.Type::Person;
        RMMatrixMgt.Name := SalesPurchPerson.Name;
        RMMatrixMgt."No." := SalesPurchPerson.Code;
        RMMatrixMgt."Company No." := '';
    end;

    local procedure CopyCampaignToBuf(var Campaign: Record Campaign; var RMMatrixMgt: Record "RM Matrix Management")
    begin
        RMMatrixMgt.Init();
        RMMatrixMgt."Company Name" := Campaign."No.";
        RMMatrixMgt.Type := RMMatrixMgt.Type::Person;
        RMMatrixMgt.Name := CopyStr(Campaign.Description, 1, MaxStrLen(RMMatrixMgt.Name));
        RMMatrixMgt."No." := Campaign."No.";
        RMMatrixMgt."Company No." := '';
    end;

    local procedure CopyContactToBuf(var Cont: Record Contact; var RMMatrixMgt: Record "RM Matrix Management")
    begin
        RMMatrixMgt.Init();
        RMMatrixMgt."Company Name" := CopyStr(Cont."Company Name", 1, MaxStrLen(RMMatrixMgt."Company Name"));
        RMMatrixMgt.Type := Cont.Type;
        RMMatrixMgt.Name := CopyStr(Cont.Name, 1, MaxStrLen(RMMatrixMgt.Name));
        RMMatrixMgt."No." := Cont."No.";
        RMMatrixMgt."Company No." := Cont."Company No.";
    end;

    local procedure ValidateStatus()
    begin
        case OptionStatusFilter of
            OptionStatusFilter::"In Progress":
                Rec.SetRange("Action Taken Filter", Rec."Action Taken Filter"::" ", Rec."Action Taken Filter"::Jumped);
            OptionStatusFilter::Won:
                Rec.SetRange("Action Taken Filter", Rec."Action Taken Filter"::Won);
            OptionStatusFilter::Lost:
                Rec.SetRange("Action Taken Filter", Rec."Action Taken Filter"::Lost);
        end;
    end;

    local procedure ValidateFilter()
    begin
        case TableType of
            TableType::"Sales Person":
                begin
                    Rec.SetRange("Campaign Filter");
                    Rec.SetRange("Contact Filter");
                    Rec.SetRange("Contact Company Filter");
                    UpdateSalespersonFilter();
                end;
            TableType::Campaign:
                begin
                    Rec.SetRange("Salesperson Filter");
                    Rec.SetRange("Contact Filter");
                    Rec.SetRange("Contact Company Filter");
                    UpdateCampaignFilter();
                end;
            TableType::Contact:
                begin
                    Rec.SetRange("Salesperson Filter");
                    Rec.SetRange("Campaign Filter");
                    UpdateContactFilter();
                end;
        end;
        CurrPage.Update(false);
    end;

    local procedure UpdateSalespersonFilter()
    begin
        SalespersonPurchaser.Reset();
        if Rec.GetFilter("Action Taken Filter") <> '' then
            SalespersonPurchaser.SetFilter("Action Taken Filter", Rec.GetFilter("Action Taken Filter"));
        if Rec.GetFilter("Sales Cycle Filter") <> '' then
            SalespersonPurchaser.SetFilter("Sales Cycle Filter", Rec.GetFilter("Sales Cycle Filter"));
        if Rec.GetFilter("Sales Cycle Stage Filter") <> '' then
            SalespersonPurchaser.SetFilter("Sales Cycle Stage Filter", Rec.GetFilter("Sales Cycle Stage Filter"));
        if Rec.GetFilter("Probability % Filter") <> '' then
            SalespersonPurchaser.SetFilter("Probability % Filter", Rec.GetFilter("Probability % Filter"));
        if Rec.GetFilter("Completed % Filter") <> '' then
            SalespersonPurchaser.SetFilter("Completed % Filter", Rec.GetFilter("Completed % Filter"));
        if Rec.GetFilter("Close Opportunity Filter") <> '' then
            SalespersonPurchaser.SetFilter("Close Opportunity Filter", Rec.GetFilter("Close Opportunity Filter"));
        if Rec.GetFilter("Contact Filter") <> '' then
            SalespersonPurchaser.SetFilter("Contact Filter", Rec.GetFilter("Contact Filter"));
        if Rec.GetFilter("Contact Company Filter") <> '' then
            SalespersonPurchaser.SetFilter("Contact Company Filter", Rec.GetFilter("Contact Company Filter"));
        if Rec.GetFilter("Campaign Filter") <> '' then
            SalespersonPurchaser.SetFilter("Campaign Filter", Rec.GetFilter("Campaign Filter"));
        if Rec.GetFilter("Estimated Value Filter") <> '' then
            SalespersonPurchaser.SetFilter("Estimated Value Filter", Rec.GetFilter("Estimated Value Filter"));
        if Rec.GetFilter("Calcd. Current Value Filter") <> '' then
            SalespersonPurchaser.SetFilter("Calcd. Current Value Filter", Rec.GetFilter("Calcd. Current Value Filter"));
        if Rec.GetFilter("Chances of Success % Filter") <> '' then
            SalespersonPurchaser.SetFilter("Chances of Success % Filter", Rec.GetFilter("Chances of Success % Filter"));
        SalespersonPurchaser.SetRange("Opportunity Entry Exists", true);
    end;

    local procedure UpdateCampaignFilter()
    begin
        Campaign.Reset();
        if Rec.GetFilter("Action Taken Filter") <> '' then
            Campaign.SetFilter("Action Taken Filter", Rec.GetFilter("Action Taken Filter"));
        if Rec.GetFilter("Sales Cycle Filter") <> '' then
            Campaign.SetFilter("Sales Cycle Filter", Rec.GetFilter("Sales Cycle Filter"));
        if Rec.GetFilter("Sales Cycle Stage Filter") <> '' then
            Campaign.SetFilter("Sales Cycle Stage Filter", Rec.GetFilter("Sales Cycle Stage Filter"));
        if Rec.GetFilter("Probability % Filter") <> '' then
            Campaign.SetFilter("Probability % Filter", Rec.GetFilter("Probability % Filter"));
        if Rec.GetFilter("Completed % Filter") <> '' then
            Campaign.SetFilter("Completed % Filter", Rec.GetFilter("Completed % Filter"));
        if Rec.GetFilter("Close Opportunity Filter") <> '' then
            Campaign.SetFilter("Close Opportunity Filter", Rec.GetFilter("Close Opportunity Filter"));
        if Rec.GetFilter("Contact Filter") <> '' then
            Campaign.SetFilter("Contact Filter", Rec.GetFilter("Contact Filter"));
        if Rec.GetFilter("Contact Company Filter") <> '' then
            Campaign.SetFilter("Contact Company Filter", Rec.GetFilter("Contact Company Filter"));
        if Rec.GetFilter("Estimated Value Filter") <> '' then
            Campaign.SetFilter("Estimated Value Filter", Rec.GetFilter("Estimated Value Filter"));
        if Rec.GetFilter("Salesperson Filter") <> '' then
            Campaign.SetFilter("Salesperson Filter", Rec.GetFilter("Salesperson Filter"));
        if Rec.GetFilter("Calcd. Current Value Filter") <> '' then
            Campaign.SetFilter("Calcd. Current Value Filter", Rec.GetFilter("Calcd. Current Value Filter"));
        if Rec.GetFilter("Chances of Success % Filter") <> '' then
            Campaign.SetFilter("Chances of Success % Filter", Rec.GetFilter("Chances of Success % Filter"));
        Campaign.SetRange("Opportunity Entry Exists", true);
    end;

    local procedure UpdateContactFilter()
    begin
        Cont.Reset();
        Cont.SetCurrentKey("Company Name", "Company No.", Type, Name);
        if Rec.GetFilter("Action Taken Filter") <> '' then
            Cont.SetFilter("Action Taken Filter", Rec.GetFilter("Action Taken Filter"));
        if Rec.GetFilter("Sales Cycle Filter") <> '' then
            Cont.SetFilter("Sales Cycle Filter", Rec.GetFilter("Sales Cycle Filter"));
        if Rec.GetFilter("Sales Cycle Stage Filter") <> '' then
            Cont.SetFilter("Sales Cycle Stage Filter", Rec.GetFilter("Sales Cycle Stage Filter"));
        if Rec.GetFilter("Probability % Filter") <> '' then
            Cont.SetFilter("Probability % Filter", Rec.GetFilter("Probability % Filter"));
        if Rec.GetFilter("Completed % Filter") <> '' then
            Cont.SetFilter("Completed % Filter", Rec.GetFilter("Completed % Filter"));
        if Rec.GetFilter("Close Opportunity Filter") <> '' then
            Cont.SetFilter("Close Opportunity Filter", Rec.GetFilter("Close Opportunity Filter"));
        if Rec.GetFilter("Estimated Value Filter") <> '' then
            Cont.SetFilter("Estimated Value Filter", Rec.GetFilter("Estimated Value Filter"));
        if Rec.GetFilter("Salesperson Filter") <> '' then
            Cont.SetFilter("Salesperson Filter", Rec.GetFilter("Salesperson Filter"));
        if Rec.GetFilter("Calcd. Current Value Filter") <> '' then
            Cont.SetFilter("Calcd. Current Value Filter", Rec.GetFilter("Calcd. Current Value Filter"));
        if Rec.GetFilter("Chances of Success % Filter") <> '' then
            Cont.SetFilter("Chances of Success % Filter", Rec.GetFilter("Chances of Success % Filter"));
        if Rec.GetFilter("Campaign Filter") <> '' then
            Cont.SetFilter("Campaign Filter", Rec.GetFilter("Campaign Filter"));
        Cont.SetRange("Opportunity Entry Exists", true);
    end;

    procedure LoadMatrix(NewMatrixColumns: array[32] of Text[1024]; var NewMatrixRecords: array[32] of Record Date; NewTableType: Enum "Opportunity Table Type"; NewOutput: Enum "Opportunity Output"; NewRoundingFactor: Enum "Analysis Rounding Factor"; NewOptionStatusFilter: Option "In Progress",Won,Lost; NewCloseOpportunityFilter: Text; NewSuccessChanceFilter: Text; NewProbabilityFilter: Text; NewCompletedFilter: Text; NewEstimatedValueFilter: Text; NewCalcdCurrentValueFilter: Text; NewSalesCycleFilter: Text; NewSalesCycleStageFilter: Text; NewNoOfColumns: Integer)
    begin
        CopyArray(MATRIX_CaptionSet, NewMatrixColumns, 1);
        CopyArray(MatrixRecords, NewMatrixRecords, 1);
        TableType := NewTableType;
        OutPutOption := NewOutput;
        RoundingFactor := NewRoundingFactor;
        OptionStatusFilter := NewOptionStatusFilter;
        Rec."Close Opportunity Filter" := NewCloseOpportunityFilter;
        SuccessChanceFilter := NewSuccessChanceFilter;
        ProbabilityFilter := NewProbabilityFilter;
        CompletedFilter := NewCompletedFilter;
        CalcdCurrentValueFilter := NewCalcdCurrentValueFilter;
        SalesCycleFilter := NewSalesCycleFilter;
        SalesCycleStageFilter := NewSalesCycleStageFilter;
        EstimatedValueFilter := NewEstimatedValueFilter;
        MATRIX_CurrentNoOfMatrixColumn := NewNoOfColumns;
        RoundingFactorFormatString := MatrixMgt.FormatRoundingFactor(RoundingFactor, false);
    end;

    local procedure MATRIX_OnDrillDown(MATRIX_ColumnOrdinal: Integer)
    begin
        TempOpp.DeleteAll();

        OppEntry.SetRange("Estimated Close Date", MatrixRecords[MATRIX_ColumnOrdinal]."Period Start",
          MatrixRecords[MATRIX_ColumnOrdinal]."Period End");

        OppEntry.SetRange(Active, true);

        case TableType of
            TableType::"Sales Person":
                OppEntry.SetFilter("Salesperson Code", Rec."No.");
            TableType::Campaign:
                OppEntry.SetFilter("Campaign No.", Rec."No.");
            TableType::Contact:
                OppEntry.SetFilter("Contact No.", Rec."No.");
        end;

        if Rec.GetFilter("Contact Company Filter") <> '' then
            OppEntry.SetFilter("Contact Company No.", Rec."Company No.");

        if Rec.GetFilter("Sales Cycle Filter") <> '' then
            OppEntry.SetFilter("Sales Cycle Code", Rec.GetFilter("Sales Cycle Filter"));

        if Rec.GetFilter("Sales Cycle Stage Filter") <> '' then
            OppEntry.SetFilter("Sales Cycle Stage", Rec.GetFilter("Sales Cycle Stage Filter"));

        if Rec.GetFilter("Action Taken Filter") <> '' then
            OppEntry.SetFilter("Action Taken", Rec.GetFilter("Action Taken Filter"));

        if Rec.GetFilter("Probability % Filter") <> '' then
            OppEntry.SetFilter("Probability %", Rec.GetFilter("Probability % Filter"));

        if Rec.GetFilter("Completed % Filter") <> '' then
            OppEntry.SetFilter("Completed %", Rec.GetFilter("Completed % Filter"));

        if Rec.GetFilter("Close Opportunity Filter") <> '' then
            OppEntry.SetFilter("Close Opportunity Code", Rec.GetFilter("Close Opportunity Filter"));

        if Rec.GetFilter("Chances of Success % Filter") <> '' then
            OppEntry.SetFilter("Chances of Success %", Rec.GetFilter("Chances of Success % Filter"));

        if Rec.GetFilter("Estimated Value Filter") <> '' then
            OppEntry.SetFilter("Estimated Value (LCY)", Rec.GetFilter("Estimated Value Filter"));

        if Rec.GetFilter("Calcd. Current Value Filter") <> '' then
            OppEntry.SetFilter("Calcd. Current Value (LCY)", Rec.GetFilter("Calcd. Current Value Filter"));

        if OppEntry.Find('-') then
            repeat
                Opp.Get(OppEntry."Opportunity No.");
                TempOpp := Opp;
                TempOpp.Insert();
            until OppEntry.Next() = 0;

        PAGE.Run(PAGE::"Active Opportunity List", TempOpp);
    end;

    local procedure MATRIX_OnAfterGetRecord(MATRIX_ColumnOrdinal: Integer)
    var
        TestAmount: Text[80];
    begin
        SetFilters();
        Rec.SetRange("Date Filter", MatrixRecords[MATRIX_ColumnOrdinal]."Period Start", MatrixRecords[MATRIX_ColumnOrdinal]."Period End");

        case OutPutOption of
            OutPutOption::"No of Opportunities":
                Rec.CalcFields("No. of Opportunities");
            OutPutOption::"Estimated Value (LCY)":
                Rec.CalcFields("Estimated Value (LCY)");
            OutPutOption::"Calc. Current Value (LCY)":
                Rec.CalcFields("Calcd. Current Value (LCY)");
            OutPutOption::"Avg. Estimated Value (LCY)":
                Rec.CalcFields("Avg. Estimated Value (LCY)");
            OutPutOption::"Avg. Calc. Current Value (LCY)":
                Rec.CalcFields("Avg.Calcd. Current Value (LCY)");
        end;
        if ReturnOutput() = 0 then
            MATRIX_CellData[MATRIX_ColumnOrdinal] := ''
        else begin
            TestAmount := Format(ReturnOutput(), 0, 0);
            FormatAmount(TestAmount);
            MATRIX_CellData[MATRIX_ColumnOrdinal] := TestAmount;
        end;
    end;

    local procedure TestFilters()
    begin
        if EstimatedValueFilter <> '' then
            Rec.SetFilter("Estimated Value Filter", EstimatedValueFilter)
        else
            Rec.SetRange("Estimated Value Filter");

        if SalesCycleStageFilter <> '' then
            Rec.SetFilter("Sales Cycle Stage Filter", SalesCycleStageFilter)
        else
            Rec.SetRange("Sales Cycle Stage Filter");

        if SuccessChanceFilter <> '' then
            Rec.SetFilter("Chances of Success % Filter", SuccessChanceFilter)
        else
            Rec.SetRange("Chances of Success % Filter");

        if ProbabilityFilter <> '' then
            Rec.SetFilter("Probability % Filter", ProbabilityFilter)
        else
            Rec.SetRange("Probability % Filter");

        if CompletedFilter <> '' then
            Rec.SetFilter("Completed % Filter", CompletedFilter)
        else
            Rec.SetRange("Completed % Filter");

        if CalcdCurrentValueFilter <> '' then
            Rec.SetFilter("Calcd. Current Value Filter", CalcdCurrentValueFilter)
        else
            Rec.SetRange("Calcd. Current Value Filter");

        if SalesCycleFilter <> '' then
            Rec.SetFilter("Sales Cycle Filter", SalesCycleFilter)
        else
            Rec.SetRange("Sales Cycle Filter");
    end;

    procedure SetColumnVisibility()
    begin
        Field1Visible := MATRIX_CurrentNoOfMatrixColumn >= 1;
        Field2Visible := MATRIX_CurrentNoOfMatrixColumn >= 2;
        Field3Visible := MATRIX_CurrentNoOfMatrixColumn >= 3;
        Field4Visible := MATRIX_CurrentNoOfMatrixColumn >= 4;
        Field5Visible := MATRIX_CurrentNoOfMatrixColumn >= 5;
        Field6Visible := MATRIX_CurrentNoOfMatrixColumn >= 6;
        Field7Visible := MATRIX_CurrentNoOfMatrixColumn >= 7;
        Field8Visible := MATRIX_CurrentNoOfMatrixColumn >= 8;
        Field9Visible := MATRIX_CurrentNoOfMatrixColumn >= 9;
        Field10Visible := MATRIX_CurrentNoOfMatrixColumn >= 10;
        Field11Visible := MATRIX_CurrentNoOfMatrixColumn >= 11;
        Field12Visible := MATRIX_CurrentNoOfMatrixColumn >= 12;
        Field13Visible := MATRIX_CurrentNoOfMatrixColumn >= 13;
        Field14Visible := MATRIX_CurrentNoOfMatrixColumn >= 14;
        Field15Visible := MATRIX_CurrentNoOfMatrixColumn >= 15;
        Field16Visible := MATRIX_CurrentNoOfMatrixColumn >= 16;
        Field17Visible := MATRIX_CurrentNoOfMatrixColumn >= 17;
        Field18Visible := MATRIX_CurrentNoOfMatrixColumn >= 18;
        Field19Visible := MATRIX_CurrentNoOfMatrixColumn >= 19;
        Field20Visible := MATRIX_CurrentNoOfMatrixColumn >= 20;
        Field21Visible := MATRIX_CurrentNoOfMatrixColumn >= 21;
        Field22Visible := MATRIX_CurrentNoOfMatrixColumn >= 22;
        Field23Visible := MATRIX_CurrentNoOfMatrixColumn >= 23;
        Field24Visible := MATRIX_CurrentNoOfMatrixColumn >= 24;
        Field25Visible := MATRIX_CurrentNoOfMatrixColumn >= 25;
        Field26Visible := MATRIX_CurrentNoOfMatrixColumn >= 26;
        Field27Visible := MATRIX_CurrentNoOfMatrixColumn >= 27;
        Field28Visible := MATRIX_CurrentNoOfMatrixColumn >= 28;
        Field29Visible := MATRIX_CurrentNoOfMatrixColumn >= 29;
        Field30Visible := MATRIX_CurrentNoOfMatrixColumn >= 30;
        Field31Visible := MATRIX_CurrentNoOfMatrixColumn >= 31;
        Field32Visible := MATRIX_CurrentNoOfMatrixColumn >= 32;
    end;

    local procedure FormatStr(): Text
    begin
        exit(RoundingFactorFormatString);
    end;
}

