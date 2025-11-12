// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.CRM.Team;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Utilities;
using System.Globalization;

report 30 "Check Value Posting"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/Dimension/CheckValuePosting.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Dimension Check Value Posting';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            PrintOnlyIfDetail = true;
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(ValuePosting_DefaultDim1Caption; DefaultDim1.FieldCaption("Value Posting"))
            {
            }
            column(DimValueCode_DefaultDim1Caption; DefaultDim1.FieldCaption("Dimension Value Code"))
            {
            }
            column(DimensionCode_DefaultDim1Caption; DefaultDim1.FieldCaption("Dimension Code"))
            {
            }
            column(TableName_DefaultDim1Caption; DefaultDim1.FieldCaption("Table Caption"))
            {
            }
            column(TableID_DefaultDim1Caption; DefaultDim1.FieldCaption("Table ID"))
            {
            }
            column(AccountNoCaption; AccountNoCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(CheckValuePostingCaption; CheckValuePostingCaptionLbl)
            {
            }
            dataitem(DefaultDim1; "Default Dimension")
            {
                DataItemTableView = sorting("Table ID", "No.", "Dimension Code") where("No." = filter(''));
                PrintOnlyIfDetail = true;
                RequestFilterFields = "Dimension Code";
                column(DimensionCode_DefaultDim1; "Dimension Code")
                {
                }
                column(DimValueCode_DefaultDim1; "Dimension Value Code")
                {
                }
                column(ValuePosting_DefaultDim1; "Value Posting")
                {
                }
                column(TableName_DefaultDim1; "Table Caption")
                {
                }
                column(TableID_DefaultDim1; "Table ID")
                {
                }
                dataitem(DefaultDim2; "Default Dimension")
                {
                    DataItemLink = "Table ID" = field("Table ID"), "Dimension Code" = field("Dimension Code");
                    DataItemLinkReference = DefaultDim1;
                    DataItemTableView = sorting("Table ID", "No.", "Dimension Code") where("No." = filter(<> ''));
                    column(ValuePosting_DefaultDim2; "Value Posting")
                    {
                    }
                    column(DimValueCode_DefaultDim2; "Dimension Value Code")
                    {
                    }
                    column(DimensionCode_DefaultDim2; "Dimension Code")
                    {
                    }
                    column(No_DefaultDim2; "No.")
                    {
                    }
                    column(ErrorMessage_DefaultDim2; ErrorMessage)
                    {
                    }
                    column(ErrorCaption; ErrorCaptionLbl)
                    {
                    }
                    dataitem(DefaultDim3; "Default Dimension")
                    {
                        DataItemLink = "Dimension Code" = field("Dimension Code");
                        DataItemLinkReference = DefaultDim1;
                        DataItemTableView = sorting("Table ID", "No.", "Dimension Code");
                        column(ErrorMessage_DefaultDim3; ErrorMessage)
                        {
                        }
                        column(DimensionCode_DefaultDim3; "Dimension Code")
                        {
                        }
                        column(ValuePosting_DefaultDim3; "Value Posting")
                        {
                        }
                        column(DimValueCode_DefaultDim3; "Dimension Value Code")
                        {
                        }
                        column(TableID_DefaultDim3; "Table ID")
                        {
                        }
                        column(ErrorCaptionDefaultDim3; ErrorCaptionDefaultDim3Lbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            ErrorMessage := '';

                            CheckAndMakeErrorMessage(DefaultDim1, DefaultDim3);

                            if ErrorMessage = '' then
                                CurrReport.Skip();
                        end;

                        trigger OnPreDataItem()
                        begin
                            "Table Caption" := ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, "Table ID");
                            if DefaultDim1."Table ID" = Database::Customer then
                                if Customer.Get(DefaultDim2."No.") then begin
                                    SetRange("Table ID", Database::"Salesperson/Purchaser");
                                    SetRange("No.", Customer."Salesperson Code");
                                end;

                            if DefaultDim1."Table ID" = Database::Vendor then
                                if Vendor.Get(DefaultDim2."No.") then begin
                                    SetRange("Table ID", Database::"Salesperson/Purchaser");
                                    SetRange("No.", Vendor."Purchaser Code");
                                end;

                            if (DefaultDim1."Table ID" <> Database::Customer) and
                               (DefaultDim1."Table ID" <> Database::Vendor)
                            then
                                CurrReport.Break();
                        end;
                    }
                    dataitem(DefaultDim4; "Default Dimension")
                    {
                        DataItemLink = "Dimension Code" = field("Dimension Code");
                        DataItemLinkReference = DefaultDim1;
                        DataItemTableView = sorting("Table ID", "No.", "Dimension Code");
                        column(ErrorMessage_DefaultDim4; ErrorMessage)
                        {
                        }
                        column(TableName_DefaultDim4; "Table Caption")
                        {
                        }
                        column(DimensionCode_DefaultDim4; "Dimension Code")
                        {
                        }
                        column(DimValueCode_DefaultDim4; "Dimension Value Code")
                        {
                        }
                        column(ValuePosting_DefaultDim4; "Value Posting")
                        {
                        }
                        column(ErrorCaptionDefaultDim4; ErrorCaptionDefaultDim4Lbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            ErrorMessage := '';

                            CheckAndMakeErrorMessage(DefaultDim1, DefaultDim4);

                            if ErrorMessage = '' then
                                CurrReport.Skip();
                        end;

                        trigger OnPreDataItem()
                        begin
                            "Table Caption" := ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, "Table ID");
                            if DefaultDim1."Table ID" = Database::Customer then
                                if Customer.Get(DefaultDim2."No.") then begin
                                    SetRange("Table ID", Database::"Responsibility Center");
                                    SetRange("No.", Customer."Responsibility Center");
                                end;

                            if DefaultDim1."Table ID" = Database::Vendor then
                                if Vendor.Get(DefaultDim2."No.") then begin
                                    SetRange("Table ID", Database::"Responsibility Center");
                                    SetRange("No.", Vendor."Responsibility Center");
                                end;

                            if (DefaultDim1."Table ID" <> Database::Customer) and
                               (DefaultDim1."Table ID" <> Database::Vendor)
                            then
                                CurrReport.Break();
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        "Table Caption" := ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, "Table ID");
                        ErrorMessage := '';

                        CheckAndMakeErrorMessage(DefaultDim1, DefaultDim2);

                        if ErrorMessage = '' then
                            CurrReport.Skip();
                    end;

                    trigger OnPostDataItem()
                    begin
                        CurrReport.Break();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    "Table Caption" := ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, "Table ID");

                    TempDefaultDimension."Table ID" := "Table ID";
                    if not TempDefaultDimension.Find() then
                        TempDefaultDimension := DefaultDim1;
                end;

                trigger OnPostDataItem()
                begin
                    CurrReport.Break();
                end;
            }
            dataitem(DefaultDim5; "Default Dimension")
            {
                DataItemTableView = sorting("Table ID", "No.", "Dimension Code") where("Table ID" = filter(18 .. 23), "No." = filter(<> ''));
                PrintOnlyIfDetail = true;
                column(No_DefaultDim5; "No.")
                {
                }
                column(DimensionCode_DefaultDim5; "Dimension Code")
                {
                }
                column(DimValueCode_DefaultDim5; "Dimension Value Code")
                {
                }
                column(ValuePosting_DefaultDim5; "Value Posting")
                {
                }
                dataitem(DefaultDim6; "Default Dimension")
                {
                    DataItemLink = "Dimension Code" = field("Dimension Code");
                    DataItemLinkReference = DefaultDim5;
                    DataItemTableView = sorting("Table ID", "No.", "Dimension Code");
                    column(ErrorMessage_DefaultDim6; ErrorMessage)
                    {
                    }
                    column(TableName_DefaultDim6; "Table Caption")
                    {
                    }
                    column(DimensionCode_DefaultDim6; "Dimension Code")
                    {
                    }
                    column(DimValueCode_DefaultDim6; "Dimension Value Code")
                    {
                    }
                    column(ValuePosting_DefaultDim6; "Value Posting")
                    {
                    }
                    column(ErrorCaptionDefaultDim6; ErrorCaptionDefaultDim6Lbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        ErrorMessage := '';

                        CheckAndMakeErrorMessage(DefaultDim5, DefaultDim6);

                        if ErrorMessage = '' then
                            CurrReport.Skip();
                    end;

                    trigger OnPreDataItem()
                    begin
                        "Table Caption" := ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, "Table ID");
                        if DefaultDim5."Table ID" = Database::Customer then
                            if Customer.Get(DefaultDim5."No.") then begin
                                SetRange("Table ID", Database::"Salesperson/Purchaser");
                                SetRange("No.", Customer."Salesperson Code");
                            end;

                        if DefaultDim5."Table ID" = Database::Vendor then
                            if Vendor.Get(DefaultDim5."No.") then begin
                                SetRange("Table ID", Database::"Salesperson/Purchaser");
                                SetRange("No.", Vendor."Purchaser Code");
                            end;
                    end;
                }
                dataitem(DefaultDim7; "Default Dimension")
                {
                    DataItemLink = "Dimension Code" = field("Dimension Code");
                    DataItemLinkReference = DefaultDim5;
                    DataItemTableView = sorting("Table ID", "No.", "Dimension Code");
                    column(ErrorMessage_DefaultDim7; ErrorMessage)
                    {
                    }
                    column(TableName_DefaultDim7; "Table Caption")
                    {
                    }
                    column(DimensionCode_DefaultDim7; "Dimension Code")
                    {
                    }
                    column(DimValueCode_DefaultDim7; "Dimension Value Code")
                    {
                    }
                    column(ValuePosting_DefaultDim7; "Value Posting")
                    {
                    }
                    column(ErrorCaptionDefaultDim7; ErrorCaptionDefaultDim7Lbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        ErrorMessage := '';

                        CheckAndMakeErrorMessage(DefaultDim5, DefaultDim7);

                        if ErrorMessage = '' then
                            CurrReport.Skip();
                    end;

                    trigger OnPreDataItem()
                    begin
                        "Table Caption" := ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, "Table ID");
                        if DefaultDim5."Table ID" = Database::Customer then
                            if Customer.Get(DefaultDim5."No.") then begin
                                SetRange("Table ID", Database::"Responsibility Center");
                                SetRange("No.", Customer."Responsibility Center");
                            end;

                        if DefaultDim5."Table ID" = Database::Vendor then
                            if Vendor.Get(DefaultDim5."No.") then begin
                                SetRange("Table ID", Database::"Responsibility Center");
                                SetRange("No.", Vendor."Responsibility Center");
                            end;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    "Table Caption" := ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, "Table ID");

                    TempDefaultDimension."Table ID" := "Table ID";
                    if TempDefaultDimension.Find() then
                        CurrReport.Skip();
                end;

                trigger OnPostDataItem()
                begin
                    CurrReport.Break();
                end;
            }
            dataitem(DefaultDim8; "Default Dimension")
            {
                DataItemTableView = sorting("Table ID", "No.", "Dimension Code") where("Value Posting" = filter("No Code"));
                column(ErrorMessage_DefaultDim8; ErrorMessage)
                {
                }
                column(ValuePosting_DefaultDim8; "Value Posting")
                {
                }
                column(DimValueCode_DefaultDim8; "Dimension Value Code")
                {
                }
                column(DimensionCode_DefaultDim8; "Dimension Code")
                {
                }
                column(No_DefaultDim8; "No.")
                {
                }
                column(TableID_DefaultDim8; "Table ID")
                {
                }
                column(TableName_DefaultDim8; "Table Caption")
                {
                }
                column(ErrorCaptionDefaultDim8; ErrorCaptionDefaultDim8Lbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    "Table Caption" := ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, "Table ID");
                    ErrorMessage := '';

                    if "Dimension Value Code" <> '' then
                        ErrorMessage :=
                          StrSubstNo(
                            Text000,
                            "Dimension Value Code",
                            FieldCaption("Dimension Value Code"),
                            FieldCaption("Value Posting"),
                            "Value Posting")
                    else
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    DefaultDim1.CopyFilter("Table ID", "Table ID");
                    DefaultDim1.CopyFilter("Dimension Code", "Dimension Code");
                end;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Check Value Posting';
        AboutText = 'The **Check Value Posting** report verifies whether value entries, such as inventory or cost postings, are correctly posted to the general ledger. Use it for validating document posting behavior during implementation or troubleshooting to ensure financial values flow accurately into the general ledger.';

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        TempDefaultDimension: Record "Default Dimension" temporary;
        ObjectTranslation: Record "Object Translation";
        ErrorMessage: Text[250];

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You must not use a "%1" %2 when %3 is "%4".';
        Text001: Label '%1 must be %2.';
        Text002: Label '%1 %2 is mandatory.';
        Text003: Label '%1 %2 must not be mentioned.';
        Text004: Label '%1 %2 must be %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        AccountNoCaptionLbl: Label 'Account No.';
        CurrReportPageNoCaptionLbl: Label 'Page';
        CheckValuePostingCaptionLbl: Label 'Check Value Posting';
        ErrorCaptionLbl: Label 'Error';
        ErrorCaptionDefaultDim3Lbl: Label 'Error';
        ErrorCaptionDefaultDim4Lbl: Label 'Error';
        ErrorCaptionDefaultDim6Lbl: Label 'Error';
        ErrorCaptionDefaultDim7Lbl: Label 'Error';
        ErrorCaptionDefaultDim8Lbl: Label 'Error';

    local procedure CheckAndMakeErrorMessage(DefaultDimension1: Record "Default Dimension"; DefaultDimension2: Record "Default Dimension")
    begin
        case DefaultDimension1."Value Posting" of
            DefaultDimension1."Value Posting"::" ":
                if (((DefaultDimension2."Value Posting" = DefaultDimension2."Value Posting"::"Same Code") and
                     (DefaultDimension2."Dimension Value Code" = '')) or
                    (DefaultDimension2."Value Posting" = DefaultDimension2."Value Posting"::"No Code")) and
                   (DefaultDimension2."Dimension Value Code" <> '')
                then
                    ErrorMessage :=
                      StrSubstNo(
                        Text001,
                        DefaultDimension2.FieldCaption("Dimension Value Code"), DefaultDimension1."Dimension Value Code");
            DefaultDimension1."Value Posting"::"Code Mandatory":
                if (DefaultDimension2."Value Posting" = DefaultDimension2."Value Posting"::"No Code") or
                   ((DefaultDimension2."Value Posting" = DefaultDimension2."Value Posting"::"Same Code") and
                    (DefaultDimension2."Dimension Value Code" = ''))
                then
                    ErrorMessage :=
                      StrSubstNo(
                        Text002,
                        DefaultDimension1.FieldCaption("Dimension Code"), DefaultDimension1."Dimension Code");
            DefaultDimension1."Value Posting"::"Same Code":
                case DefaultDimension2."Value Posting" of
                    DefaultDimension2."Value Posting"::"Code Mandatory":
                        if DefaultDimension1."Dimension Value Code" = '' then
                            ErrorMessage :=
                              StrSubstNo(
                                Text003,
                                DefaultDimension1.FieldCaption("Dimension Code"), DefaultDimension1."Dimension Code")
                        else
                            if (DefaultDimension2."Dimension Value Code" <> '') and
                               (DefaultDimension1."Dimension Value Code" <> DefaultDimension2."Dimension Value Code")
                            then
                                ErrorMessage :=
                                  StrSubstNo(
                                    Text004,
                                    DefaultDimension2.FieldCaption("Dimension Value Code"), DefaultDimension2."Dimension Value Code",
                                    DefaultDimension1."Dimension Value Code");
                    DefaultDimension2."Value Posting"::"No Code":
                        if DefaultDimension1."Dimension Value Code" <> '' then
                            ErrorMessage :=
                              StrSubstNo(
                                Text001,
                                DefaultDimension1.FieldCaption("Dimension Value Code"), DefaultDimension1."Dimension Value Code");
                    DefaultDimension2."Value Posting"::"Same Code", DefaultDimension2."Value Posting"::" ":
                        if DefaultDimension1."Dimension Value Code" <> DefaultDimension2."Dimension Value Code" then
                            if DefaultDimension1."Dimension Value Code" = '' then
                                ErrorMessage :=
                                  StrSubstNo(
                                    Text003,
                                    DefaultDimension1.FieldCaption("Dimension Code"), DefaultDimension1."Dimension Code")
                            else
                                ErrorMessage :=
                                  StrSubstNo(
                                    Text004,
                                    DefaultDimension2.FieldCaption("Dimension Value Code"),
                                    DefaultDimension2."Dimension Value Code", DefaultDimension1."Dimension Value Code");
                end;
            DefaultDimension1."Value Posting"::"No Code":
                if DefaultDimension2."Dimension Value Code" <> '' then
                    ErrorMessage :=
                      StrSubstNo(
                        Text003,
                        DefaultDimension1.FieldCaption("Dimension Code"), DefaultDimension1."Dimension Code");
        end;
    end;
}

