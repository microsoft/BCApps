// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Integration;

page 132548 "Page Summary Test Card"
{
    PageType = Card;
    SourceTable = "Page Provider Summary Test";
    Caption = 'Page summary';
    CardPageId = "Page Summary Empty Page";

    layout
    {
        area(Content)
        {
            field(TestBigInteger; Rec.TestBigInteger)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a test field BigInteger';
            }
#pragma warning disable AW0004
            field(TestBlob; Rec.TestBlob)
#pragma warning restore AW0004
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a test field Blob';
            }
            field(TestBoolean; Rec.TestBoolean)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a test field Boolean';
            }
            field(TestCode; Rec.TestCode)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a test field Code';
            }
            field(TestDate; Rec.TestDate)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a test field Date';
            }
            field(TestDateFormula; Rec.TestDateFormula)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a test field DateFormula';
            }
            field(TestDateTime; Rec.TestDateTime)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a test field DateTime';
            }
            field(TestDecimal; Rec.TestDecimal)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a test field Decimal';
            }
            field(TestTime; Rec.TestTime)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a test field Time';
            }
            field(TestText; Rec.TestText)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a test field Text';
            }
            field(TestTableFilter; Rec.TestTableFilter)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a test field TableFilter';
            }
            field(TestRecordId; Rec.TestRecordId)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a test field RecordID';
            }
            field(TestOption; Rec.TestOption)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a test field Option';
            }
            field(TestMediaSet; Rec.TestMediaSet)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a test field MediaSet';
            }
            field(TestMedia; Rec.TestMedia)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a test field Media';
            }
            field(TestInteger; Rec.TestInteger)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a test field Integer';
            }
            field(TestGuid; Rec.TestGuid)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a test field GUID';
            }
            field(TestEnum; Rec.TestEnum)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a test field Option';
            }
            field(TestDuration; Rec.TestDuration)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a test field Duration';
            }
        }
    }

}

